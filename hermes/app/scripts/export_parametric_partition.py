#!/usr/bin/env python3
"""Export the parametric partition-rule transplant deformations as SVG filmstrips.

The Prolog layer knowledge/strategies/render/parametric_partition_deformation.pl decides
WHAT each deformation is (a foreign partition rule on an illicit host, parametric
over the fraction's denominator N) and emits drawer-compatible frame documents.
This script is the projection step: it runs swipl through paths.pl to get the
documents, then passes each through the shared rendering adapter and
hermes/web/render/drawer.js, writing per-frame SVGs and a four-up filmstrip.

The replication panel renders the SAME deformation for several denominators so
the eye confirms what the skeleton-diff test asserts: only the cut count changes.

Output lands under hermes/app/web/generated/parametric_partition/.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO_ROOT))
from hermes.app import rendering

DEFAULT_OUT = (
    rendering.gallery_output(REPO_ROOT / "hermes" / "app" / "web" / "generated" / "parametric_partition")
)

# The cases to render. Each is (host, transplant_rule, [denominators]).
# The headline case is vertical-strip-on-circle, the documented 1/4-on-circle
# error, replicated over 1/4, 1/5, 1/6, 1/8.
CASES = [
    ("circle", "vertical", [4, 5, 6, 8]),
    ("rectangle", "radial", [4, 6]),
    ("circle", "grid", [4, 6]),
    ("set", "radial", [3, 4]),
]
# The productive companion (the correct 1/N model in the host's own rule) for the
# headline host, so the chart can show licensed-vs-transplant side by side.
PRODUCTIVE = [("circle", [4, 6])]


def case_code(host: str, rule: str, n: int) -> str:
    return f"PARAM-transplant-{rule}-on-{host}-1over{n}"


def productive_code(host: str, n: int) -> str:
    return f"PARAM-productive-{host}-1over{n}"


# --- swipl bridge: get a drawer-ready document for one (host, rule, n) --------

SWIPL_DEFORMED = (
    "use_module(library(http/json)),"
    "use_module(render(parametric_partition_deformation)),"
    "deformed_partition_scene({host}, {n}, transplant({rule}), D),"
    "current_output(S),"
    "json_write_dict(S, D, [width(0)]),"
    "halt."
)
SWIPL_PRODUCTIVE = (
    "use_module(library(http/json)),"
    "use_module(render(parametric_partition_deformation)),"
    "productive_partition_scene({host}, {n}, D),"
    "current_output(S),"
    "json_write_dict(S, D, [width(0)]),"
    "halt."
)


def swipl_doc(goal: str) -> dict:
    proc = subprocess.run(
        ["swipl", "-q", "-l", "paths.pl", "-g", goal],
        cwd=REPO_ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if proc.returncode != 0:
        raise RuntimeError(f"swipl failed for goal:\n{goal}\n{proc.stderr}")
    out = proc.stdout.strip()
    # The goal may have written warnings before the JSON; take the last JSON line.
    brace = out.find("{")
    if brace < 0:
        raise RuntimeError(f"no JSON in swipl output:\n{out}\n{proc.stderr}")
    return json.loads(out[brace:])


def deformed_doc(host: str, rule: str, n: int) -> dict:
    return swipl_doc(SWIPL_DEFORMED.format(host=host, rule=rule, n=n))


def productive_doc(host: str, n: int) -> dict:
    return swipl_doc(SWIPL_PRODUCTIVE.format(host=host, n=n))


# --- shared drawer adapter ---------------------------------------------------


def export_frames(out_dir: Path, code: str, doc: dict) -> list[Path]:
    doc_path = out_dir / f"{code}-doc.json"
    doc_path.write_text(json.dumps(doc, indent=2), encoding="utf-8")
    return rendering.render_frames(doc, out_dir, code)


def export_replication_strip(
    out_dir: Path, host: str, rule: str, ns: list[int], docs: dict[int, dict]
) -> Path:
    out_file = out_dir / f"PARAM-replication-{rule}-on-{host}.svg"
    frames = []
    for n in ns:
        doc_path = out_dir / f"{case_code(host, rule, n)}-doc.json"
        doc_path.write_text(json.dumps(docs[n], indent=2), encoding="utf-8")
        frames.append(docs[n]["frames"][-1])
    title = (
        f"Same {rule}-rule transplant on a {host}, parametric over the fraction "
        f"(only the cut count changes)"
    )
    rendering.render_svg(
        {"frames": frames, "_bounds_documents": [docs[n] for n in ns]},
        "filmstrip", out_file,
        labels=[f"1/{n}" for n in ns], title=title,
        panelWidth=230, panelHeight=220, gap=16, headHeight=84, rootHeight=360,
        fullPanelHeight=True, yOffset=0, replicationLayout=True,
        perFrameBounds=True, omitCaptions=True, cleanFonts=True,
        ariaLabel=title,
    )
    return out_file


def build_index(manifest: dict) -> str:
    """Render index.html from the manifest this same run just wrote.

    Mirrors the section grouping and prose of export_parametric_deformations.py's
    build_index (the established pattern for this gallery family): replication
    strips first, then productive partitions, then one section per (rule, host)
    transplant family, sections and denominators sorted so the page order is
    stable across runs rather than tied to CASES declaration order.
    """
    svg_count = (
        sum(len(d["frames"]) for d in manifest["deformations"])
        + sum(len(p["frames"]) for p in manifest["productive"])
        + len(manifest["replication_strips"])
    )

    rows = []
    rows.append("<!doctype html><meta charset=utf-8>")
    rows.append("<title>Parametric partition gallery</title>")
    rows.append("<body style='font-family:system-ui;background:#f8f1df;color:#1b1810;"
                "max-width:1100px;margin:0 auto;padding:28px'>")
    rows.append("<h1 style=\"font-family:Georgia,'Times New Roman',serif\">"
                "Parametric partition gallery</h1>")
    rows.append(f"<p style='max-width:760px;line-height:1.45'>These {svg_count} SVGs "
                "record productive circle partitions, transplant deformations, and "
                "denominator replication strips. Each caption names the rule, host, "
                "fraction, and frame encoded in its filename.</p>")

    rows.append("<h2>Replication strips</h2>")
    for strip in sorted(manifest["replication_strips"], key=lambda s: (s["rule"], s["host"])):
        label = f"{strip['rule'].title()} on {strip['host']}"
        rows.append(f"<p><a href='{strip['file']}'>{label}</a> "
                    "— replication across denominators</p>")

    rows.append("<h2>Productive circle partitions</h2>")
    for p in sorted(manifest["productive"], key=lambda p: p["n"]):
        rows.append(f"<h3>{p['host'].title()}, 1/{p['n']}</h3>")
        for i, frame in enumerate(p["frames"], 1):
            rows.append(f"<p><a href='{frame}'>{p['host'].title()} 1/{p['n']}, "
                        f"frame {i}</a></p>")

    groups: dict[tuple[str, str], list[dict]] = {}
    for d in manifest["deformations"]:
        groups.setdefault((d["rule"], d["host"]), []).append(d)
    for (rule, host), entries in sorted(groups.items()):
        rows.append(f"<h2>{rule.title()} on {host} transplants</h2>")
        for d in sorted(entries, key=lambda d: d["n"]):
            rows.append(f"<h3>{host.title()}, 1/{d['n']}</h3>")
            for i, frame in enumerate(d["frames"], 1):
                rows.append(f"<p><a href='{frame}'>{rule.title()} on {host} "
                            f"1/{d['n']}, frame {i}</a></p>")

    rows.append("</body>")
    return "\n".join(rows)


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--out", type=Path, default=DEFAULT_OUT)
    return p.parse_args()


def main() -> int:
    args = parse_args()
    out_dir = args.out.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    written: list[Path] = []
    manifest: dict = {"deformations": [], "productive": [], "replication_strips": []}

    for host, rule, ns in CASES:
        docs = {n: deformed_doc(host, rule, n) for n in ns}
        for n in ns:
            code = case_code(host, rule, n)
            frame_files = export_frames(out_dir, code, docs[n])
            written.extend(frame_files)
            manifest["deformations"].append(
                {
                    "host": host,
                    "rule": rule,
                    "n": n,
                    "code": code,
                    "frame_count": len(docs[n].get("frames", [])),
                    "foreign_primitive": docs[n].get("foreignPrimitive", ""),
                    "illicit_host": docs[n].get("illicitHost", ""),
                    "violation": docs[n].get("violation", ""),
                    "frames": [p.name for p in frame_files],
                }
            )
        strip = export_replication_strip(out_dir, host, rule, ns, docs)
        written.append(strip)
        manifest["replication_strips"].append(
            {"host": host, "rule": rule, "denominators": ns, "file": strip.name}
        )

    for host, ns in PRODUCTIVE:
        for n in ns:
            doc = productive_doc(host, n)
            code = productive_code(host, n)
            frame_files = export_frames(out_dir, code, doc)
            written.extend(frame_files)
            manifest["productive"].append(
                {
                    "host": host,
                    "n": n,
                    "code": code,
                    "frame_count": len(doc.get("frames", [])),
                    "frames": [p.name for p in frame_files],
                }
            )

    (out_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2), encoding="utf-8"
    )

    index_path = out_dir / "index.html"
    index_path.write_text(build_index(manifest), encoding="utf-8")
    written.append(index_path)

    print(f"Wrote {len(written)} files to {out_dir}")
    for path in written:
        print(path)
    return 0


if __name__ == "__main__":
    if "--check" in sys.argv:
        raise SystemExit(rendering.check_exporter(Path(__file__), DEFAULT_OUT))
    raise SystemExit(main())
