#!/usr/bin/env python3
"""Exercise a staged distribution tree the way a colleague's browser will.

The manifest (app_manifest.py) says what ships; this gate checks that what
ships actually runs. It works on a staged copy of the manifest — never the
repo checkout, whose untracked files hide under-shipping — and does three
things:

1. Static audit: every fetch/src/href target written into the shipped web
   pages must resolve — to a shipped file, to a known API route, or to a
   mount (docs/) that is allowed to be absent and degrades
   with a message rather than a broken surface.
2. Live probes: start the server from the staged tree and call the routes
   the console and its pages call — including the LLM-backed ones, which
   must come back as clean JSON errors when no key is set, never as a
   dropped connection.
3. The report chain, executed directly: load talkmoves_two_pass from the
   staged tree, load its scorer, read both pass prompts, and run
   blind -> number -> mask -> teacher_report on a toy transcript. This is
   the exact chain behind "Build the report", minus the two model calls.

Usage:
  python3 scripts/bundle/smoke_bundle.py                    # stage + smoke
  python3 scripts/bundle/smoke_bundle.py --tree DIR         # smoke a bundle
  ... [--python BIN] [--swipl BIN] [--static-only] [--keep]
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import socket
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "scripts" / "bundle"))
from app_manifest import build_manifest  # noqa: E402

MOUNTS = {"more-zeeman", "learner", "representation", "ASKTM_Data", "docs"}
# Research-data mounts the app degrades without (each surface names the
# absence); a missing target there is a note, not a failure.
OPTIONAL_PREFIXES = ("/docs/",)

# Routes from an older standalone server that shipped pages still probe
# inside a try/catch, falling back to local behavior (coordination.html runs
# its own simulation, the strategies index skips its gaps panel). Their
# absence is a designed fallback, not a broken surface.
LEGACY_FALLBACK_ROUTES = {"/api/cgi_dispatch",
                          "/api/action/topology/gaps"}
# Routes intentionally cordoned from the main server may be listed here.
RESEARCH_WING_ROUTES: set[str] = set()

SKIP_SCHEMES = ("http:", "https:", "mailto:", "data:", "javascript:",
                "tel:", "#", "about:")

TARGET_RE = re.compile(
    r"""(?:fetch\(\s*|(?<=\bsrc=)|(?<=\bhref=))["'`]([^"'`\s]+)["'`]"""
)
API_LITERAL_RE = re.compile(
    r"""["'`](/api/[A-Za-z0-9_./:-]+(?:\?[^"'`]*)?)["'`]"""
)

TOY_TRANSCRIPT = (
    "Ms. R: Who can say why one half equals two fourths?\n"
    "Sam: Because you double the top and the bottom.\n"
    "Lee: I got 2/4 by splitting each half into two pieces.\n"
)

# The workflow CLIs and /api/media_transcribe read these at request time; a
# staged tree without them fails on first use, not at startup — which is how
# the gap stayed quiet until a colleague hit it.
SYSTEM_PROMPTS = [
    "chat.md", "help.md", "pml_reader.md",
    "content_consolidate.md", "content_per_file.md", "draft.md",
    "grade.md", "parse.md", "profile.md", "score.md",
    "transcribe.md", "transcribe_timed.md",
]


def prompts_check(tree: Path, report: Report) -> None:
    missing = [name for name in SYSTEM_PROMPTS
               if not (tree / "hermes/app/system_prompts" / name).is_file()]
    if missing:
        report.add("FAIL", "workflow system prompts staged",
                   "missing: " + ", ".join(missing))
    else:
        report.add("PASS",
                   f"workflow system prompts staged ({len(SYSTEM_PROMPTS)} files)")


def muds_chain_check(tree: Path, report: Report) -> None:
    required = [
        "more-zeeman/mua_data.json",
        "scripts/research/export_mua_for_mud.py",
    ]
    missing = [rel for rel in required if not (tree / rel).is_file()]
    if missing:
        report.add("FAIL", "MUDs data chain staged",
                   "missing: " + ", ".join(missing))
    else:
        report.add("PASS", "MUDs data chain staged (snapshot + regenerator)")


class Report:
    def __init__(self) -> None:
        self.rows: list[tuple[str, str, str]] = []

    def add(self, status: str, name: str, detail: str = "") -> None:
        self.rows.append((status, name, detail))
        print(f"  {status:4} {name}" + (f" — {detail}" if detail else ""))

    def failed(self) -> bool:
        return any(s == "FAIL" for s, _, _ in self.rows)


# ---------------------------------------------------------------- staging

def stage_tree(dest: Path) -> None:
    files = build_manifest(with_figures=False)
    for rel in files:
        target = dest / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(REPO / rel, target)
    subprocess.run(
        [sys.executable, str(REPO / "scripts/bundle/prebake.py"),
         "--bundle", str(dest), "--prune-only"],
        check=True, capture_output=True,
    )


# ---------------------------------------------------------- static audit

def api_routes(tree: Path) -> set[str]:
    text = (tree / "hermes/app/server.py").read_text(encoding="utf-8")
    routes = set(re.findall(r'(?:self\.path|parsed\.path) == "(/api/[^"]+)"', text))
    routes |= set(re.findall(r'raw_path[^"\n]*"(/api/[^"]+)"', text))
    route_dir = tree / "hermes/app/routes"
    if route_dir.is_dir():
        route_text = "\n".join(
            path.read_text(encoding="utf-8") for path in route_dir.glob("*.py")
        )
        declared = set(re.findall(
            r'Route\(\s*"(?:GET|POST)"\s*,\s*"(/api/[^"]+)"', route_text
        ))
        declared |= set(re.findall(r'"(/api/[^"]+)"\s*[,|:]', route_text))
        routes |= {path for path in declared if "{" not in path}
    workflow = tree / "hermes/app/workflow"
    if workflow.is_dir():
        routes |= {f"/api/{p.stem}" for p in workflow.glob("*.py")
                   if p.stem not in ("__init__",)}
    return routes


def api_prefixes(tree: Path) -> list[str]:
    text = (tree / "hermes/app/server.py").read_text(encoding="utf-8")
    return re.findall(r'self\.path\.startswith\("(/api/[^"]+)"\)', text) + \
        re.findall(r'raw_path\.startswith\("(/api/[^"]+)"\)', text)


def url_to_file(tree: Path, url_path: str) -> Path:
    parts = url_path.lstrip("/").split("/", 1)
    if parts[0] in MOUNTS:
        return tree / url_path.lstrip("/")
    if url_path in ("", "/"):
        return tree / "hermes/app/web/console.html"
    return tree / "hermes/app/web" / url_path.lstrip("/")


def page_url_for(rel: str) -> str | None:
    if rel.startswith("hermes/app/web/"):
        return "/" + rel[len("hermes/app/web/"):]
    first = rel.split("/", 1)[0]
    if first in MOUNTS:
        return "/" + rel
    return None


def static_audit(tree: Path, report: Report) -> None:
    required = (
        "more-zeeman/atlas.html",
        "more-zeeman/witnesses.html",
        "hermes/capability_registry.pl",
        "scripts/extract_capability_registry.py",
    )
    missing_required = [rel for rel in required if not (tree / rel).is_file()]
    if missing_required:
        report.add("FAIL", "capability registry files staged",
                   "missing: " + ", ".join(missing_required))
    else:
        report.add("PASS", "capability registry files staged")
    page_assertions = {
        "more-zeeman/atlas.html": (
            "lazy_reachable", "Loaded on demand by", "Described on:",
        ),
        "more-zeeman/witnesses.html": (
            "strategies/render/rigid_motion_scene.pl", "geometry/geometry_bridge.pl",
            "rigid_motion_render", "crosswalk/merge_evidence.pl",
            "/api/witness/pml", "semantic_material_witness", "validate_reader_axioms",
            "formal/pml/mua_conjectures.pl", "misconceptions/pml_wire.pl",
            "/api/witness/grounding", "image_schema", "target_expressive_power_witness",
        ),
        "more-zeeman/bridge.html": (
            "formal/learner/activity_contract.pl", "formal/learner/reorg_domains/fraction.pl",
            "strategies/math_benchmark.pl",
        ),
        "more-zeeman/coordination.html": (
            "strategies/math/unit_coordination_viz.pl",
        ),
        "more-zeeman/index.html": (
            "ZEEMAN_BIFURCATION_VERDICT agreement", "more-zeeman/prolog/zeeman_machine.pl",
        ),
        "more-zeeman/monitoring_chart.html": (
            "lessons/im/im_glossary.pl", "lessons/im_harness.pl",
        ),
        "more-zeeman/visualizations.html": (
            "lessons/im/generated/compiled_task_instances.pl",
        ),
        "hermes/app/web/breaks.html": (
            "arche-trace/differance_juncture.pl", "formal/formalization/axioms_robinson.pl",
            "arche-trace/registry_incompatibility_adapter.pl",
        ),
        "hermes/app/web/no.html": (
            "misconceptions/literature_canonical_mappings.pl",
        ),
    }
    for rel, markers in page_assertions.items():
        source = (tree / rel).read_text(encoding="utf-8", errors="replace")
        missing = [marker for marker in markers if marker not in source]
        if missing:
            report.add("FAIL", f"static witness page {rel}",
                       "missing: " + ", ".join(missing))
        else:
            report.add("PASS", f"static witness page {rel}")
    routes = api_routes(tree)
    prefixes = api_prefixes(tree)
    pages = [p for p in tree.rglob("*.html")
             if page_url_for(str(p.relative_to(tree)))]
    pages += [p for p in tree.rglob("*.js")
              if page_url_for(str(p.relative_to(tree)))]
    dead: list[str] = []
    optional: set[str] = set()
    checked = 0
    for page in pages:
        rel = str(page.relative_to(tree))
        base = page_url_for(rel)
        text = page.read_text(encoding="utf-8", errors="replace")
        for m in TARGET_RE.finditer(text):
            raw = m.group(1)
            if not raw or raw.startswith(SKIP_SCHEMES) or raw.startswith("//"):
                continue
            target = urllib.parse.urljoin("http://x" + base, raw)
            path = urllib.parse.urlparse(target).path
            if "${" in raw or "{{" in raw:
                continue  # template — the live probes cover the real URLs
            if path.startswith("/api/"):
                if path in LEGACY_FALLBACK_ROUTES or path in RESEARCH_WING_ROUTES:
                    optional.add(path)
                elif path not in routes and \
                        not any(path.startswith(p) for p in prefixes):
                    dead.append(f"{rel}: {raw} (no such route)")
                checked += 1
                continue
            if path.startswith(OPTIONAL_PREFIXES):
                if not url_to_file(tree, path).is_file():
                    optional.add(path)
                checked += 1
                continue
            if not url_to_file(tree, path).is_file():
                dead.append(f"{rel}: {raw} -> {path}")
            checked += 1
        for raw in sorted(set(API_LITERAL_RE.findall(text))):
            if "${" in raw or "{{" in raw:
                continue  # template — the live probes cover the real URLs
            path = urllib.parse.urlparse(raw).path
            if path in LEGACY_FALLBACK_ROUTES or path in RESEARCH_WING_ROUTES:
                optional.add(path)
            elif path not in routes and \
                    not any(path.startswith(p) for p in prefixes):
                dead.append(f"{rel}: {raw} (no such route)")
            checked += 1
    if dead:
        report.add("FAIL", f"static targets ({checked} checked)",
                   "; ".join(sorted(set(dead))[:12]))
    else:
        report.add("PASS", f"static targets ({checked} checked)")
    if optional:
        report.add("NOTE", "absent by design (research mounts / legacy fallbacks)",
                   ", ".join(sorted(optional)[:6])
                   + (" …" if len(optional) > 6 else ""))


# ------------------------------------------------------------ live probes

def free_port() -> int:
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    port = s.getsockname()[1]
    s.close()
    return port


def call(base: str, path: str, payload: dict | None = None,
         timeout: float = 30.0) -> tuple[int, object]:
    url = base + path
    if payload is None:
        req = urllib.request.Request(url)
    else:
        req = urllib.request.Request(
            url, data=json.dumps(payload).encode(),
            headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            body = r.read()
            status = r.status
    except urllib.error.HTTPError as e:
        body = e.read()
        status = e.code
    ctype_json = body[:1] in (b"{", b"[")
    return status, (json.loads(body) if ctype_json else body)


def strict_prolog_preflight(tree: Path, swipl: str | None,
                            report: Report) -> bool:
    if not swipl:
        report.add("FAIL", "Prolog runtime loads strictly", "swipl not found")
        return False
    env = dict(os.environ)
    env["UMEDCTA_ROOT"] = str(tree)
    proc = subprocess.run(
        [swipl, "--on-error=status", "--on-warning=status", "-q",
         "-l", "hermes_worker.pl", "-g", "load_runtime, halt."],
        cwd=tree, env=env, capture_output=True, text=True, timeout=600,
    )
    if proc.returncode != 0:
        diagnostics = "".join((proc.stdout, proc.stderr)).rstrip()
        report.add("FAIL", "Prolog runtime loads strictly", diagnostics)
        return False
    report.add("PASS", "Prolog runtime loads strictly")
    return True


def staged_route_table(tree: Path, python: str) -> set[tuple[str, str]]:
    snippet = (
        "import json; "
        "from hermes.app.routes.registry import build_router; "
        "print(json.dumps([[r.method, r.path] for r in build_router().routes]))"
    )
    env = dict(os.environ)
    env.update(UMEDCTA_ROOT=str(tree), PYTHONPATH=str(tree))
    proc = subprocess.run(
        [python, "-c", snippet], cwd=tree, env=env,
        capture_output=True, text=True, timeout=30, check=True,
    )
    return {tuple(row) for row in json.loads(proc.stdout)}


def capability_page_file(tree: Path, page: str) -> Path:
    return tree / page.lstrip("/")


def live_probes(tree: Path, python: str, swipl: str | None,
                report: Report) -> None:
    env = dict(os.environ)
    env.update(UMEDCTA_ROOT=str(tree), PYTHONPATH=str(tree))
    # The no-key posture is what a colleague without credentials gets. An
    # explicit empty value beats pop(): load_dotenv only fills ABSENT vars,
    # and it walks parent directories — a .env above the tree (the repo's,
    # or the drive root's) would otherwise hand the probe a real key.
    env["REALLMS_API_KEY"] = ""
    if swipl:
        env["HERMES_SWIPL"] = swipl
        env["PATH"] = str(Path(swipl).parent) + os.pathsep + env.get("PATH", "")
    port = free_port()
    base = f"http://127.0.0.1:{port}"
    server = subprocess.Popen(
        [python, "-m", "hermes.app.server", "--host", "127.0.0.1",
         "--port", str(port)],
        cwd=tree, env=env,
        stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    try:
        for _ in range(60):
            try:
                status, _ = call(base, "/api/mode", timeout=2)
                if status == 200:
                    break
            except OSError:
                if server.poll() is not None:
                    report.add("FAIL", "server start",
                               server.stderr.read().decode()[-400:])
                    return
                time.sleep(0.5)
        else:
            report.add("FAIL", "server start", "no answer on /api/mode")
            return

        def probe(name: str, path: str, payload: dict | None = None,
                  want: range = range(200, 300), timeout: float = 30.0,
                  check=None, allow_raw_api: bool = False) -> None:
            try:
                status, body = call(base, path, payload, timeout=timeout)
            except Exception as exc:  # connection drop = the bug we hunt
                report.add("FAIL", name, f"connection failed: {exc}")
                return
            if status not in want:
                report.add("FAIL", name, f"HTTP {status}: {str(body)[:160]}")
                return
            if (isinstance(body, bytes) and path.startswith("/api/")
                    and not allow_raw_api):
                report.add("FAIL", name, "non-JSON API reply")
                return
            if check and not check(body):
                report.add("FAIL", name, f"unexpected shape: {str(body)[:160]}")
                return
            report.add("PASS", name)

        probe("GET / (console)", "/",
              check=lambda b: b"hermes-shell" in b or b"console" in b)
        probe("GET /api/mode", "/api/mode")
        probe("GET /api/quickstart", "/api/quickstart")
        probe("GET /api/sample", "/api/sample")
        probe("GET /api/inputs", "/api/inputs")

        try:
            capability_status, capability_body = call(
                base, "/api/capabilities", timeout=120.0
            )
        except Exception as exc:
            report.add("FAIL", "GET /api/capabilities", f"connection failed: {exc}")
        else:
            capability_text = json.dumps(capability_body).lower()
            entries = capability_body.get("capabilities", []) \
                if isinstance(capability_body, dict) else []
            if (capability_status != 200 or not isinstance(capability_body, dict)
                    or len(entries) <= 150
                    or not isinstance(capability_body.get("health"), dict)
                    or "traceback" in capability_text):
                report.add(
                    "FAIL", "GET /api/capabilities",
                    f"HTTP {capability_status}, entries={len(entries)}: {capability_text[:160]}",
                )
            else:
                report.add("PASS", "GET /api/capabilities",
                           f"{len(entries)} capability entries")
                counts = capability_body.get("counts") or {}
                report.add(
                    "NOTE", "capability dead ends",
                    f"unrouted={counts.get('unrouted', 0)}, "
                    f"lazy_reachable={counts.get('lazy_reachable', 0)}, "
                    "undescribed_orphans="
                    f"{sum(1 for entry in entries if entry.get('surface_status') == 'orphan_module' and not entry.get('pages'))}",
                )
                try:
                    live_routes = staged_route_table(tree, python)
                    sampled = [entry for entry in entries
                               if entry.get("surface_status") == "routed_paged"][:10]
                    claim_errors: list[str] = []
                    for entry in sampled:
                        claimed_routes = {
                            (route.get("method"), route.get("path"))
                            for route in (entry.get("route") or [])
                            if isinstance(route, dict)
                        }
                        absent_routes = claimed_routes - live_routes
                        if absent_routes:
                            claim_errors.append(
                                f"{entry.get('name')}: absent routes {sorted(absent_routes)}"
                            )
                        route_paths = {path for _method, path in claimed_routes}
                        for page in entry.get("pages") or []:
                            page_file = capability_page_file(tree, page)
                            if not page_file.is_file():
                                claim_errors.append(f"{entry.get('name')}: absent page {page}")
                                continue
                            page_text = page_file.read_text(encoding="utf-8", errors="replace")
                            if not any(path in page_text for path in route_paths):
                                claim_errors.append(
                                    f"{entry.get('name')}: {page} names none of {sorted(route_paths)}"
                                )
                    if claim_errors:
                        report.add("FAIL", "capability claims match staged routes and pages",
                                   "; ".join(claim_errors[:10]))
                    else:
                        report.add("PASS", "capability claims match staged routes and pages",
                                   f"{len(sampled)} routed_paged entries sampled")
                except Exception as exc:  # audit setup failure is itself a smoke failure
                    report.add("FAIL", "capability claims match staged routes and pages", str(exc))

        status, idx = call(base, "/generated/talkmoves_reports/index.json")
        if status != 200 or not isinstance(idx, list) or not idx:
            report.add("FAIL", "prepared report index",
                       f"HTTP {status}: {str(idx)[:120]}")
        else:
            report.add("PASS", f"prepared report index ({len(idx)} reports)")
            for entry in idx:
                rid = entry.get("id", "")
                probe(f"prepared report {rid}",
                      f"/generated/talkmoves_reports/{rid}.json",
                      check=lambda b: isinstance(b, dict) and "headline" in b)

        # every shipped page answers
        for page in sorted((tree / "hermes/app/web").glob("*.html")):
            probe(f"GET /{page.name}", f"/{page.name}")
        for page in sorted((tree / "more-zeeman").glob("*.html")):
            probe(f"GET /more-zeeman/{page.name}",
                  f"/more-zeeman/{page.name}")

        probe("POST /api/compute", "/api/compute",
              {"operation": "add", "a": 3, "b": 2, "limit": 20,
               "mode": "direct"}, timeout=120.0,
              check=lambda b: isinstance(b, dict) and b.get("success") is True
              and "tension_history" in b)
        probe("GET /api/knowledge", "/api/knowledge", timeout=120.0,
              check=lambda b: isinstance(b, list) and len(b) == 4)
        probe("GET /api/visualize/coordination",
              "/api/visualize/coordination?base=10&val_up=5&val_down=7%2F5",
              timeout=120.0, allow_raw_api=True,
              check=lambda b: isinstance(b, bytes) and b.lstrip().startswith(b"<svg"))
        probe("GET /api/unit_coordination.svg",
              "/api/unit_coordination.svg?base=10&value_up=5&numerator=7&denominator=5",
              timeout=120.0, allow_raw_api=True,
              check=lambda b: isinstance(b, bytes) and b.lstrip().startswith(b"<svg"))
        probe("GET /learner/reorg_demo.html", "/learner/reorg_demo.html",
              check=lambda b: isinstance(b, bytes) and b"reorganiz" in b.lower())
        probe("GET /api/reorganize",
              "/api/reorganize?domain=fraction_splitting&a=3&b=8&c=4&d=5",
              timeout=120.0,
              check=lambda b: isinstance(b, dict) and "question" in b
              and "result" in b)

        probe("POST /api/monitoring_visuals", "/api/monitoring_visuals",
              {"lesson_code": "IM-G1-U3-L17"}, timeout=300.0,
              check=lambda b: isinstance(b, dict) and b.get("ok") is True
              and isinstance(b.get("result"), dict)
              and bool(b["result"].get("visuals"))
              and len(json.dumps(b["result"])) > 200)
        probe(
            "GET shipped ASKTM PNG",
            "/ASKTM_Data/Grade%204_Fine-Grained%20Coding_Second%20Pass/"
            "converted/G4Q1_media/media/image1.png",
        )

        # the worker-backed offline path (starts the Prolog worker; slow once)
        probe("GET /api/base", "/api/base", timeout=120.0,
              check=lambda b: isinstance(b, dict)
              and isinstance(b.get("operative_base"), int))
        base_set_status = None
        base_set_body = None
        base_reset_status = None
        base_reset_body = None
        base_error = None
        try:
            base_set_status, base_set_body = call(
                base, "/api/base", {"base": 12}, timeout=120.0
            )
        except Exception as exc:
            base_error = f"set failed: {exc}"
        finally:
            try:
                base_reset_status, base_reset_body = call(
                    base, "/api/base", {"base": 10}, timeout=120.0
                )
            except Exception as exc:
                base_error = f"{base_error + '; ' if base_error else ''}reset failed: {exc}"
        base_set_value = (base_set_body or {}).get("result", {}).get("operative_base") \
            if isinstance(base_set_body, dict) else None
        base_reset_value = (base_reset_body or {}).get("result", {}).get("operative_base") \
            if isinstance(base_reset_body, dict) else None
        if (base_error or base_set_status != 200 or base_set_value != 12
                or base_reset_status != 200 or base_reset_value != 10):
            report.add(
                "FAIL", "POST /api/base set 12 then reset 10",
                base_error or (
                    f"set=HTTP {base_set_status}, value={base_set_value}; "
                    f"reset=HTTP {base_reset_status}, value={base_reset_value}"
                ),
            )
        else:
            report.add("PASS", "POST /api/base set 12 then reset 10")
        expected_pack_states = {
            "pack(robinson)": "enabled",
            "pack(number_theory)": "enabled",
            "pack(geometry)": "enabled",
            "pack(registry_incompatibility)": "disabled",
        }
        try:
            toggle_status, toggle_body = call(
                base, "/api/axiom_toggle", {"action": "list"}, timeout=120.0
            )
            toggle_rows = toggle_body.get("result", {}).get("toggles", []) \
                if isinstance(toggle_body, dict) else []
            pack_states = {
                row.get("axiom"): row.get("status")
                for row in toggle_rows
                if isinstance(row, dict) and row.get("axiom") in expected_pack_states
            }
        except Exception as exc:
            report.add("FAIL", "POST /api/axiom_toggle lists managed packs", str(exc))
        else:
            if toggle_status != 200 or pack_states != expected_pack_states:
                report.add(
                    "FAIL", "POST /api/axiom_toggle lists managed packs",
                    f"HTTP {toggle_status}, states={pack_states}",
                )
            else:
                report.add("PASS", "POST /api/axiom_toggle lists managed packs")
        toggle_disable_status = None
        toggle_disable_body = None
        toggle_enable_status = None
        toggle_enable_body = None
        toggle_round_trip_error = None
        try:
            toggle_disable_status, toggle_disable_body = call(
                base, "/api/axiom_toggle",
                {"action": "disable", "axiom": "pack(robinson)"},
                timeout=120.0,
            )
        except Exception as exc:
            toggle_round_trip_error = f"disable failed: {exc}"
        finally:
            try:
                toggle_enable_status, toggle_enable_body = call(
                    base, "/api/axiom_toggle",
                    {"action": "enable", "axiom": "pack(robinson)"},
                    timeout=120.0,
                )
            except Exception as exc:
                toggle_round_trip_error = (
                    f"{toggle_round_trip_error + '; ' if toggle_round_trip_error else ''}"
                    f"restore failed: {exc}"
                )
        disabled_rows = toggle_disable_body.get("result", {}).get("toggles", []) \
            if isinstance(toggle_disable_body, dict) else []
        enabled_rows = toggle_enable_body.get("result", {}).get("toggles", []) \
            if isinstance(toggle_enable_body, dict) else []
        if (toggle_round_trip_error or toggle_disable_status != 200
                or disabled_rows != [{"axiom": "pack(robinson)", "status": "disabled"}]
                or toggle_enable_status != 200
                or enabled_rows != [{"axiom": "pack(robinson)", "status": "enabled"}]):
            report.add(
                "FAIL", "axiom pack disable then restore",
                toggle_round_trip_error or (
                    f"disable=HTTP {toggle_disable_status}, rows={disabled_rows}; "
                    f"restore=HTTP {toggle_enable_status}, rows={enabled_rows}"
                ),
            )
        else:
            report.add("PASS", "axiom pack disable then restore")
        probe("POST /api/pml_score (offline clauses)", "/api/pml_score",
              {"clauses": ["reader_axiom(smoke, subjective, compression, 1)"]},
              timeout=300.0)
        probe("POST /api/render (number line)", "/api/render",
              {"op": "number_line_compare", "operation": "addition",
               "a": 8, "b": 7},
              timeout=120.0,
              check=lambda b: b.get("grounded_result") == 15)
        probe("POST /api/witness/crosswalk_claim", "/api/witness/crosswalk_claim",
              {"op": "algebra_claim_witness", "canonical": "smoke_absent",
               "source": "smoke_bundle"},
              want=range(200, 401), timeout=120.0)
        probe("POST /api/witness/geometry", "/api/witness/geometry",
              {"op": "geometry_van_hiele_marker_witness",
               "concept": "square_rectangle_classification", "level": 1},
              timeout=120.0,
              check=lambda b: b.get("ok") is True
              and b.get("result", {}).get("kind") == "geometry_van_hiele_marker")
        probe("POST /api/witness/standards", "/api/witness/standards",
              {"op": "standard_k_ns_1_count_by_ones_witness",
               "from": 1, "to": 10},
              timeout=120.0,
              check=lambda b: b.get("ok") is True
              and b.get("result", {}).get("kind") == "standard_k_ns_1_counting_trace")
        probe("POST /api/witness/formal", "/api/witness/formal",
              {"op": "axiom_hierarchy_witness", "kind": "domain_expansion(n_to_z)"},
              timeout=120.0, check=lambda b: b.get("ok") is True)
        probe("POST /api/witness/pml", "/api/witness/pml",
              {"op": "semantic_material_witness", "from": "[s(comp_nec(p))]",
               "to": "o(comp_nec(p))"}, timeout=120.0,
              check=lambda b: b.get("ok") is True)
        probe("POST /api/witness/grounding", "/api/witness/grounding",
              {"op": "image_schema", "practice": "p_count_on_from_larger"},
              timeout=120.0, check=lambda b: b.get("ok") is True)
        probe("POST /api/witness/misconception", "/api/witness/misconception",
              {"op": "misconception_incompatibility_witness",
               "move": "misconception(count_all_when_count_on_available)",
               "conflict": "strategy(addition,count_on_from_larger)"},
              timeout=120.0, check=lambda b: b.get("ok") is True)
        probe("POST /api/witness/misconception (PML map)",
              "/api/witness/misconception",
              {"op": "misconception_pml_map",
               "misconception": "addition_must_make_larger"},
              timeout=120.0,
              check=lambda b: b.get("ok") is True
              and b.get("result", {}).get("count") == 1
              and b.get("result", {}).get("pairs", [{}])[0].get("source_tag")
              == "db_row(193)")
        probe("POST /api/balance_solve", "/api/balance_solve",
              {"a": 2, "b": 3, "c": 11}, timeout=120.0,
              check=lambda b: b.get("ok") is True
              and "deformation_step" in json.dumps(b.get("result", {})))
        discourse_utterances = [
            {"id": "u1", "speaker": "S01", "text": "A square has four right angles."},
            {"id": "u2", "speaker": "S02", "text": "So it is a rectangle."},
        ]
        probe("POST /api/discourse_features", "/api/discourse_features",
              {"utterances": discourse_utterances}, timeout=120.0,
              check=lambda b: b.get("ok") is True)
        probe("POST /api/geometry", "/api/geometry",
              {"predicate": "pck_synthesis_for", "args": ["quadrilateral_hierarchy"]},
              timeout=120.0,
              check=lambda b: b.get("ok") is True
              and b.get("result", {}).get("kind") == "pck_synthesis")
        probe("POST /api/strategies", "/api/strategies", {},
              want=range(200, 500), timeout=120.0)
        # the per-strategy visualizer pages call this with display names
        probe("POST /api/strategy_trace (COBO)", "/api/strategy_trace",
              {"strategy": "COBO", "input": {"a": 8, "b": 5}},
              timeout=120.0,
              check=lambda b: b.get("ok") and b["result"].get("ok")
              and b["result"].get("jumps"))
        probe("POST /api/literature", "/api/literature", {"q": "fractions"},
              want=range(200, 500), timeout=120.0)

        # LLM-backed route without a key: a clean, named refusal — never a drop
        probe("POST /api/transcript_report (empty)", "/api/transcript_report",
              {}, want=range(400, 401))
        probe("POST /api/transcript_report (no key)", "/api/transcript_report",
              {"text": TOY_TRANSCRIPT}, want=range(503, 504),
              check=lambda b: b.get("error_type") == "no_key")
        probe("POST /api/help (no key)", "/api/help",
              {"question": "why is this page here", "page": "witnesses"},
              want=range(503, 504),
              check=lambda b: b.get("error_type") == "no_key"
              and "REALLMS API key" in b.get("error", ""))

        # Workflow CLI route: it may refuse (absent input, no key) but must
        # answer from its shipped files — a system_prompts miss is a
        # packaging bug, and it surfaces in the subprocess stderr the route
        # echoes back.
        def no_prompt_miss(b: object) -> bool:
            text = json.dumps(b) if not isinstance(b, (str, bytes)) else str(b)
            return ("system_prompts" not in text
                    and "FileNotFoundError" not in text)
        probe("POST /api/parse (shipped files only)", "/api/parse",
              {"input": "smoke_absent.txt"}, want=range(200, 504),
              timeout=120.0,
              check=lambda b: no_prompt_miss(b)
              and "traceback" not in json.dumps(b).lower())
        workflow_payloads = {
            "content": {"activity": "smoke_absent"},
            "profile": {},
            "draft": {"unit": "smoke_absent"},
            "grade": {},
            "score": {},
            "metrics": {},
        }
        for command, payload in workflow_payloads.items():
            probe(f"POST /api/{command} (shipped files only)",
                  f"/api/{command}", payload, want=range(200, 504),
                  timeout=120.0,
                  check=lambda b: no_prompt_miss(b)
                  and "traceback" not in json.dumps(b).lower())
    finally:
        server.terminate()
        try:
            server.wait(timeout=10)
        except subprocess.TimeoutExpired:
            server.kill()


# ------------------------------------------------------- report chain

CHAIN_SNIPPET = """
import importlib.util, json, sys
from pathlib import Path
tree = Path(sys.argv[1])
spec = importlib.util.spec_from_file_location(
    "talkmoves_two_pass", tree / "scripts/talkmoves_two_pass.py")
tp = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tp)
scorer = tp._load_scorer()
for p in (tp.PASS1_PROMPT_PATH, tp.PASS2_PROMPT_PATH):
    assert p.read_text(encoding="utf-8").strip(), p
blinded, aliases = tp.blind_transcript(sys.argv[2])
assert blinded.strip() and aliases
numbered, speakers = scorer.number_transcript(blinded)
count = len([l for l in numbered.splitlines() if l.strip()])
assert count > 0 and speakers
masked = tp.mask_transcript(numbered, [])
report = tp.teacher_report("smoke", [], [], numbered)
assert report.get("headline")
print(json.dumps({"utterances": count, "headline": report["headline"]}))
"""


def chain_check(tree: Path, python: str, report: Report) -> None:
    env = dict(os.environ)
    env.update(UMEDCTA_ROOT=str(tree), PYTHONPATH=str(tree))
    proc = subprocess.run(
        [python, "-c", CHAIN_SNIPPET, str(tree), TOY_TRANSCRIPT],
        cwd=tree, env=env, capture_output=True, text=True, timeout=120)
    if proc.returncode != 0:
        report.add("FAIL", "report chain (blind→number→mask→report)",
                   proc.stderr.strip()[-300:])
    else:
        report.add("PASS", "report chain (blind→number→mask→report)",
                   proc.stdout.strip())


# ------------------------------------------------------------------ main

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--tree", type=Path,
                    help="existing staged tree/bundle (default: stage fresh)")
    ap.add_argument("--python", default=sys.executable,
                    help="python to run the staged server with")
    ap.add_argument("--swipl", default=shutil.which("swipl"),
                    help="swipl for the worker (default: from PATH)")
    ap.add_argument("--static-only", action="store_true",
                    help="skip the live server probes")
    ap.add_argument("--keep", action="store_true",
                    help="keep the temporary staged tree")
    args = ap.parse_args()

    # The server and chain subprocesses run with cwd inside the tree; a
    # relative runtime path would resolve against that cwd and vanish.
    if args.python and Path(args.python).exists():
        args.python = str(Path(args.python).resolve())
    if args.swipl and Path(args.swipl).exists():
        args.swipl = str(Path(args.swipl).resolve())

    report = Report()
    tmp: tempfile.TemporaryDirectory | None = None
    if args.tree:
        tree = args.tree.resolve()
        print(f"smoking existing tree: {tree}")
    else:
        tmp = tempfile.TemporaryDirectory(prefix="hermes-smoke-")
        tree = Path(tmp.name) / "staged"
        print(f"staging manifest into {tree}")
        stage_tree(tree)

    print("— static audit —")
    static_audit(tree, report)
    prompts_check(tree, report)
    muds_chain_check(tree, report)
    if not args.static_only:
        print("— report chain —")
        chain_check(tree, args.python, report)
        print("— Prolog preflight —")
        if strict_prolog_preflight(tree, args.swipl, report):
            print("— live probes —")
            live_probes(tree, args.python, args.swipl, report)

    if tmp and args.keep:
        print(f"kept staging dir: {tree}")
        tmp._finalizer.detach()  # noqa: SLF001 — deliberate keep
    fails = [r for r in report.rows if r[0] == "FAIL"]
    print(f"\n{len([r for r in report.rows if r[0] == 'PASS'])} passed, "
          f"{len(fails)} failed")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
