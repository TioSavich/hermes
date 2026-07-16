#!/usr/bin/env python3
"""Build the self-contained Hermes app bundle (run-from-a-flash-drive).

Assembles a directory that runs the full application on a Mac with nothing
installed: the runtime manifest (scripts/bundle/app_manifest.txt rules, via
app_manifest.py), a vendored SWI-Prolog.app, a vendored relocatable Python,
a double-clickable START_HERMES.command, and a README. Gallery figure images
are included by default (drop with --no-figures).

The vendored runtimes are copied, never downloaded: SWI-Prolog from this
machine's /Applications, Python from a python-build-standalone install you
point at. Both are Apple Silicon builds — the bundle targets arm64 Macs and
says so in its README; on other machines the launcher falls back to whatever
`python3`/`swipl` the host has.

Usage — this command pastes into a shell as written; it vendors SWI-Prolog
from /Applications, relies on the host python3, smokes the result, and zips:

  python3 scripts/bundle/build_app_bundle.py \
      --out build/bundles/hermes-app --zip build/bundles/hermes-app.zip

To vendor a relocatable Python, add --python-dist pointing at ONE
python-build-standalone distribution — the directory that directly contains
bin/python3, not a folder of several distributions:

  --python-dist ~/Downloads/cpython-3.12.13-macos-aarch64-none

Other flags: --swipl-app APP for a different SWI-Prolog.app, --no-figures to
drop the ~190 MB gallery images, --skip-smoke to skip the end-to-end check.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "scripts" / "bundle"))
from app_manifest import KEEP_TREES_RATIONALE, build_manifest  # noqa: E402
from walk_closure import group_by_top  # noqa: E402

LAUNCHER = """\
#!/bin/bash
# Start the Hermes teaching console from this bundle. Double-click me.
cd "$(dirname "$0")"
ROOT="$PWD"

PY="$ROOT/vendor/python/bin/python3"
if ! "$PY" -c '' 2>/dev/null; then PY="$(command -v python3)"; fi
if [ -z "$PY" ]; then
  echo "No usable Python found (vendored copy did not run; none on PATH)."
  echo "The vendored runtime is built for Apple Silicon Macs."
  read -r -p "Press return to close."; exit 1
fi

SWIPL="$ROOT/vendor/SWI-Prolog.app/Contents/MacOS/swipl"
if ! "$SWIPL" --version >/dev/null 2>&1; then SWIPL="$(command -v swipl)"; fi
if [ -n "$SWIPL" ]; then
  export HERMES_SWIPL="$SWIPL"
  export PATH="$(dirname "$SWIPL"):$PATH"
else
  echo "SWI-Prolog not found; the console will run with the symbolic"
  echo "surfaces degraded (each names the missing worker when asked)."
fi

export UMEDCTA_ROOT="$ROOT" PYTHONPATH="$ROOT"

# Pick a free port: a stale server (or another app) squatting 8765 otherwise
# leaves the browser talking to the wrong thing while this launch dies.
PORT="${HERMES_PORT:-}"
if [ -z "$PORT" ]; then
  for CAND in 8765 8766 8767 8768 8769 8770; do
    if "$PY" -c "import socket;s=socket.socket();s.bind(('127.0.0.1',$CAND));s.close()" 2>/dev/null; then
      PORT="$CAND"; break
    fi
  done
fi
if [ -z "$PORT" ]; then
  echo "Ports 8765-8770 are all in use. Quit whatever is using them"
  echo "(or set HERMES_PORT to a free port) and double-click me again."
  read -r -p "Press return to close."; exit 1
fi
if [ "$PORT" != "8765" ]; then
  echo "Port 8765 is busy — another server is already there. Using $PORT."
fi
echo "Hermes: http://127.0.0.1:$PORT  (keep this window open; close it to stop)"

( sleep 2; open "http://127.0.0.1:$PORT" 2>/dev/null ) &
exec "$PY" -m hermes.app.server --host 127.0.0.1 --port "$PORT"
"""

README = """\
# Hermes — self-contained app bundle

The Hermes teaching console with its Prolog knowledge base, ready to run from
this folder (a flash drive works). Nothing needs to be installed.

**Start it:** double-click `START_HERMES.command`. A Terminal window opens,
the console appears in your browser (normally <http://127.0.0.1:8765>; if
that port is taken the Terminal names the one it used), and closing the
Terminal window stops it. If macOS balks at the first double-click,
right-click the file and choose Open. If the browser says it can't connect,
the Terminal window has the address and the reason.

What you can open right now, before starting anything: `index.html` in this
folder lists every shipped surface. The lesson monitoring chart and the
fraction-bars calculator draw from a direct open, using their embedded
sample data. The console, the student-work gallery, and the deontic
scoreboard fetch their data from the local server, so they need
`START_HERMES.command` running first.

What's inside:
- The Hermes console (Python, standard library only) and the SWI-Prolog
  knowledge base it reasons with — the runtime file set from the repository,
  without its test suites and research documents. `DIRECTORY_MAP.md` says
  what each directory carries.
- `vendor/` — a relocatable Python 3.12 and SWI-Prolog, both Apple Silicon
  builds. On a machine that has its own `python3`/`swipl`, the launcher uses
  those as a fallback.

Boundaries, named plainly:
- The LLM surfaces (drafting prose, the Gemma class workflow, building a NEW
  discussion report) need a REALLMS key, and REALLMS answers only from the
  IU network — on campus or on the IU VPN. Without that, each of those
  surfaces says so; the prepared discussion reports and every symbolic
  surface (strategy runs, misconception checks, fraction visualizers,
  the literature corpus) work offline.
- The PDF homework surface needs `pdftotext` (Poppler), which is not vendored.
- Student data never ships in this bundle. Anything you paste or drop stays
  in `hermes/app/runtime/` inside this folder.

Built from the repository by `scripts/bundle/build_app_bundle.py`; the file
list is `scripts/bundle/app_manifest.txt` in the repo.
"""

START_HERE = """\
HERMES — START HERE

1. Double-click START_HERMES.command.
   A Terminal window opens; the console appears in your browser at
   http://127.0.0.1:8765 (if that port is busy, the Terminal names the
   one it used). Keep the Terminal window open; closing it stops the
   console.

2. If macOS blocks the first double-click, right-click
   START_HERMES.command, choose Open, then Open again.

3. Two pages work without starting anything: the lesson monitoring chart
   and the fraction-bars calculator draw from embedded sample data.
   Open index.html in this folder for the full list of surfaces.

README.md has the details — what is inside, which surfaces need an IU
REALLMS key, and where anything you paste stays (hermes/app/runtime/,
inside this folder).
"""

# Launchpad surfaces. Every path must be a manifest member — the build
# asserts this, so a renamed surface fails the build instead of shipping a
# dead link. `link` is what the launchpad points at: the bundle-relative
# file itself for the no-server pages, the local server URL for the rest.
CONSOLE_URL = "http://127.0.0.1:8765"
SURFACES_OFFLINE = [
    ("Lesson monitoring chart", "more-zeeman/monitoring_chart.html",
     "The chart a teacher monitors an IM lesson with: the strategies the "
     "lesson calls for and the student work that signals each one. Draws "
     "from embedded sample data."),
    ("Fraction-bars calculator", "more-zeeman/fraction-bars/calculator.html",
     "Fraction arithmetic drawn as partitioned bars. The embedded samples "
     "draw immediately; the Calculate button needs the console running."),
]
SURFACES_SERVER = [
    ("Teaching console", "hermes/app/web/console.html",
     "Paste or drop student work, check strategy and misconception claims "
     "against the Prolog worker, and build discussion reports.",
     CONSOLE_URL + "/"),
    ("Student-work gallery", "more-zeeman/gallery.html",
     "Coded work samples from the research literature, organized by "
     "strategy. Fetches its catalog from the server.",
     CONSOLE_URL + "/more-zeeman/gallery.html"),
    ("Deontic scoreboard", "more-zeeman/scoreboard.html",
     "The monitoring chart's derived figures — strategy incompatibilities "
     "and expressive power — as the Prolog worker reports them. Asks the "
     "live worker first and names its data source on the page.",
     CONSOLE_URL + "/more-zeeman/scoreboard.html"),
]

LAUNCHPAD_TEMPLATE = """\
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Hermes bundle — surfaces</title>
<style>
  body {{ font: 16px/1.5 -apple-system, system-ui, sans-serif;
         max-width: 44rem; margin: 2rem auto; padding: 0 1rem; }}
  h1 {{ font-size: 1.4rem; }}
  h2 {{ font-size: 1.05rem; margin-top: 2rem; }}
  li {{ margin: 0.6rem 0; }}
  .path {{ font-family: ui-monospace, monospace; font-size: 0.85em;
          color: #555; }}
  footer {{ margin-top: 2.5rem; font-size: 0.9em; color: #555; }}
</style>
</head>
<body>
<h1>Hermes bundle — shipped surfaces</h1>
<h2>Opens directly from this folder (no server)</h2>
<ul>
{offline}
</ul>
<h2>Needs START_HERMES.command running</h2>
<p>Double-click <span class="path">START_HERMES.command</span> first; the
links below point at the local server it starts (normally port 8765 — the
Terminal window names the port it actually used).</p>
<ul>
{server}
</ul>
<footer>
<p>The console's LLM surfaces (drafting prose, building a new discussion
report) need an IU REALLMS key and answer only from the IU network or the
IU VPN. Every symbolic surface listed above works without one.</p>
<p>Details: README.md. Directory contents: DIRECTORY_MAP.md.</p>
</footer>
</body>
</html>
"""


def render_launchpad(manifest: set[str]) -> str:
    missing = [rel for _, rel, *_ in SURFACES_OFFLINE + SURFACES_SERVER
               if rel not in manifest]
    if missing:
        sys.exit(f"launchpad names surfaces the manifest does not ship: {missing}")
    offline = "\n".join(
        f'<li><a href="{rel}">{name}</a> '
        f'<span class="path">({rel})</span><br>{desc}</li>'
        for name, rel, desc in SURFACES_OFFLINE)
    server = "\n".join(
        f'<li><a href="{url}">{name}</a> '
        f'<span class="path">({rel})</span><br>{desc}</li>'
        for name, rel, desc, url in SURFACES_SERVER)
    return LAUNCHPAD_TEMPLATE.format(offline=offline, server=server)


def render_directory_map(manifest: list[str]) -> str:
    counts = dict(group_by_top(manifest))
    lines = [
        "# Directory map",
        "",
        "What each top-level directory in this bundle carries, and how many",
        "files it ships. Generated at build time from the manifest rules in",
        "`scripts/bundle/app_manifest.py`.",
        "",
        "| Directory | Files | Carries |",
        "|---|---:|---|",
    ]
    for tree, rationale in KEEP_TREES_RATIONALE:
        n = counts.get(tree + "/", 0)
        lines.append(f"| `{tree}/` | {n} | {rationale} |")
    kept_singletons = {
        "(root)": "the Prolog loader (paths.pl) and worker entry point",
        "docs/": "runtime prompts the report chain reads, plus the "
                 "gallery's literature figure images when bundled",
        "scripts/": "report-chain scripts and this bundle's own build tools",
        "tools/": "worker-loaded audit and strategy-carving modules",
    }
    listed = {tree + "/" for tree, _ in KEEP_TREES_RATIONALE}
    for top, n in sorted(counts.items()):
        if top not in listed:
            label = "`" + top + "`" if top != "(root)" else "repository root"
            why = kept_singletons.get(top, "individually kept runtime files")
            lines.append(f"| {label} | {n} | {why} |")
    lines += [
        "",
        "`vendor/` (added after this count) carries the relocatable Python "
        "and SWI-Prolog runtimes.",
        "",
    ]
    return "\n".join(lines)


def copy_manifest_tree(out: Path, with_figures: bool) -> list[str]:
    files = build_manifest(with_figures)
    for rel in files:
        dst = out / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(REPO / rel, dst)
    return files


def vendor_runtimes(out: Path, swipl_app: Path, python_dist: Path) -> None:
    vendor = out / "vendor"
    vendor.mkdir(exist_ok=True)
    if swipl_app:
        dst = vendor / "SWI-Prolog.app"
        print(f"vendoring {swipl_app} -> {dst}")
        shutil.copytree(swipl_app, dst, symlinks=True)
        probe = subprocess.run(
            [str(dst / "Contents/MacOS/swipl"), "-q", "-g", "halt"],
            capture_output=True,
        )
        if probe.returncode != 0:
            sys.exit(f"vendored swipl does not run: {probe.stderr.decode()[:400]}")
    if python_dist:
        dst = vendor / "python"
        print(f"vendoring {python_dist} -> {dst}")
        shutil.copytree(python_dist, dst, symlinks=True)
        probe = subprocess.run(
            [str(dst / "bin/python3"), "-c", "print('ok')"], capture_output=True
        )
        if probe.returncode != 0:
            sys.exit(f"vendored python does not run: {probe.stderr.decode()[:400]}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--out", type=Path, required=True, help="bundle directory")
    ap.add_argument("--swipl-app", type=Path,
                    default=Path("/Applications/SWI-Prolog.app"))
    ap.add_argument("--python-dist", type=Path,
                    help="relocatable python install to vendor (bin/python3)")
    ap.add_argument("--no-figures", action="store_true",
                    help="leave the gallery figure images out (~190 MB)")
    ap.add_argument("--zip", type=Path, help="also write a zip archive here")
    ap.add_argument("--skip-smoke", action="store_true",
                    help="skip the end-to-end smoke of the built bundle")
    args = ap.parse_args()

    # Validate the runtime arguments before the multi-thousand-file copy, so
    # a wrong path fails in a second instead of after the copy.
    swipl_app = args.swipl_app if args.swipl_app.is_dir() else None
    if swipl_app is None:
        print(f"note: {args.swipl_app} not found; bundle will rely on host swipl")
    python_dist = args.python_dist
    if python_dist is not None:
        # An explicit --python-dist that cannot vendor is an error, not a
        # silent host-python fallback: the caller asked for a vendored
        # runtime and would ship a bundle without one.
        if not python_dist.is_dir():
            sys.exit(f"--python-dist {python_dist} is not a directory")
        if not (python_dist / "bin/python3").exists():
            children = ", ".join(sorted(p.name for p in python_dist.iterdir())[:6])
            sys.exit(
                f"--python-dist {python_dist} has no bin/python3.\n"
                f"It contains: {children}\n"
                "Point at the single distribution directory that directly "
                "contains bin/python3 (e.g. one cpython-*-none folder), not "
                "a folder of distributions."
            )
    else:
        print("note: no --python-dist; bundle will rely on host python3")

    out: Path = args.out
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)

    files = copy_manifest_tree(out, with_figures=not args.no_figures)
    print(f"copied {len(files)} manifest files")

    # Prune/validate before vendoring: the vendored Python's own lib carries
    # deliberately malformed JSON test fixtures that must not fail the build.
    subprocess.run(
        [sys.executable, str(REPO / "scripts/bundle/prebake.py"),
         "--bundle", str(out), "--prune-only"],
        check=True,
    )

    vendor_runtimes(out, swipl_app, python_dist)

    launcher = out / "START_HERMES.command"
    launcher.write_text(LAUNCHER, encoding="utf-8")
    launcher.chmod(0o755)
    (out / "README.md").write_text(README, encoding="utf-8")
    (out / "START_HERE.txt").write_text(START_HERE, encoding="utf-8")
    (out / "index.html").write_text(render_launchpad(set(files)),
                                    encoding="utf-8")
    (out / "DIRECTORY_MAP.md").write_text(render_directory_map(files),
                                          encoding="utf-8")

    if not args.skip_smoke:
        # Smoke the tree that will actually ship, with the runtimes it
        # actually carries — the launcher's own resolution order.
        vend_py = (out / "vendor/python/bin/python3").resolve()
        vend_swipl = (out / "vendor/SWI-Prolog.app/Contents/MacOS/swipl").resolve()
        smoke = [sys.executable, str(REPO / "scripts/bundle/smoke_bundle.py"),
                 "--tree", str(out.resolve()),
                 "--python", str(vend_py) if vend_py.exists() else sys.executable]
        if vend_swipl.exists():
            smoke += ["--swipl", str(vend_swipl)]
        print("smoking the built bundle …")
        if subprocess.run(smoke).returncode != 0:
            sys.exit("bundle smoke FAILED — not zipping a broken bundle")

    if args.zip:
        args.zip.parent.mkdir(parents=True, exist_ok=True)
        if args.zip.exists():
            args.zip.unlink()
        # ditto preserves executable bits and symlinks (zip -ry equivalent,
        # but also resource-fork-safe for the vendored .app).
        subprocess.run(
            ["ditto", "-c", "-k", "--keepParent", str(out), str(args.zip)],
            check=True,
        )
        print(f"wrote {args.zip} "
              f"({args.zip.stat().st_size / 1048576:.0f} MB)")

    total = sum(f.stat().st_size for f in out.rglob("*") if f.is_file())
    print(f"bundle ready: {out} ({total / 1048576:.0f} MB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
