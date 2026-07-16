#!/usr/bin/env python3
"""Post-copy fixups for a static bundle produced by walk_closure.py.

Three jobs, all confined to the bundle directory (the repository's own files
are never modified):

1. Prune the bundle's copy of representation/asset_manifest.json to the
   assets whose image file was actually bundled, and record the exclusion in
   the manifest's note field. ASKTM student-work images are local research
   data, untracked by design; without pruning, the gallery would render
   hundreds of image-less cards.
2. Parse every .json file in the bundle so a truncated or malformed data
   file fails the build here, not in a reader's browser.
3. Write the bundle's README.md: what the package is, how to open it, and
   which capabilities need the live application instead.

Usage:
  python3 scripts/bundle/prebake.py --bundle build/bundles/reviewer --name reviewer
"""

import argparse
import json
import os
import sys

MANIFEST_REL = os.path.join("representation", "asset_manifest.json")

READMES = {
    "reviewer": """\
# UMEDCTA public surfaces — reviewer bundle

Static package of the public Hermes pages reachable from the audience entry page.
Open it through a local file server: from this directory run `python3 -m http.server 8000`, then go to <http://localhost:8000/more-zeeman/audience-index.html>. A direct file:// open works only for the pages with embedded data (the monitoring chart, the fraction calculator); the gallery, scoreboard, and expressive-power pages fetch JSON and need the server.
The deontic scoreboard and the expressive-power comparison ask a live Hermes worker first, fall back to the saved data included here, and name their data source on the page; the drawing pages keep their embedded sample when no worker answers. For live numbers and interactive rendering, clone the full repository and run `bash hermes/app/launch.sh`.
ASKTM student-work images are local research data and are not distributed; the gallery's coded corpus here is the literature-figure set. The teaching console reads student work and is deliberately absent from every bundle.
""",
    "teacher": """\
# UMEDCTA teacher surfaces — static bundle

Static package of the teacher-facing pages: the student-work gallery, the fraction-bars calculator, and the lesson monitoring chart, plus the pages their shared navigation reaches. The Hermes teaching console itself is not here: it needs its Python server and Prolog worker, so it cannot ship as static files.
Open the bundle through a local file server: from this directory run `python3 -m http.server 8000`, then go to <http://localhost:8000/more-zeeman/gallery.html> (or `monitoring_chart.html`, or `fraction-bars/calculator.html`). The calculator and monitoring chart also draw from a direct file:// open, using their embedded sample data; the gallery needs the server.
The Calculate and live-refresh buttons need the live application (`bash hermes/app/launch.sh` in the full repository); without it, each drawing page keeps its embedded sample.
ASKTM student-work images are local research data and are not distributed; the gallery's coded corpus here is the literature-figure set.
""",
}


def prune_manifest(bundle):
    path = os.path.join(bundle, MANIFEST_REL)
    if not os.path.exists(path):
        print(f"prebake: no {MANIFEST_REL} in bundle; nothing to prune")
        return
    with open(path, encoding="utf-8") as f:
        m = json.load(f)
    assets = m.get("assets", [])
    kept, dropped_by_source = [], {}
    for a in assets:
        img = a.get("image", "")
        if img and os.path.exists(os.path.join(bundle, img)):
            kept.append(a)
        else:
            src = a.get("source", "unknown")
            dropped_by_source[src] = dropped_by_source.get(src, 0) + 1
    if not dropped_by_source:
        print(f"prebake: manifest intact ({len(kept)} assets, all images bundled)")
        return
    m["assets"] = kept
    counts = {}
    for a in kept:
        counts[a.get("source", "unknown")] = counts.get(a.get("source", "unknown"), 0) + 1
    counts["total"] = len(kept)
    for src in m.get("counts", {}):
        if src != "total":
            m["counts"][src] = counts.get(src, 0)
    m["counts"]["total"] = len(kept)
    drop_note = "; ".join(
        f"{n} {src} assets excluded (images are local data, not distributed)"
        for src, n in sorted(dropped_by_source.items())
    )
    m["note"] = (m.get("note", "") + " | Bundle copy: " + drop_note).strip(" |")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(m, f, indent=1)
    print(f"prebake: manifest pruned to {len(kept)} assets; {drop_note}")


def check_json(bundle):
    bad = []
    n = 0
    for dirpath, _dirnames, filenames in os.walk(bundle):
        for name in filenames:
            if not name.endswith(".json"):
                continue
            n += 1
            p = os.path.join(dirpath, name)
            try:
                with open(p, encoding="utf-8") as f:
                    json.load(f)
            except ValueError as e:
                bad.append((os.path.relpath(p, bundle), str(e)))
    if bad:
        for rel, err in bad:
            print(f"prebake: BAD JSON {rel}: {err}", file=sys.stderr)
        sys.exit(1)
    print(f"prebake: {n} JSON files parse")


def write_readme(bundle, name):
    text = READMES.get(name)
    if text is None:
        print(f"prebake: no README template for bundle name '{name}'", file=sys.stderr)
        sys.exit(2)
    path = os.path.join(bundle, "README.md")
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    print(f"prebake: wrote {os.path.relpath(path)}")


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--bundle", required=True, help="bundle directory to fix up")
    ap.add_argument("--name", choices=sorted(READMES),
                    help="bundle name; selects the README text")
    ap.add_argument("--prune-only", action="store_true",
                    help="prune the asset manifest and validate JSON; no README "
                         "(the app image and app bundle write their own)")
    args = ap.parse_args()
    if not os.path.isdir(args.bundle):
        print(f"prebake: bundle directory not found: {args.bundle}", file=sys.stderr)
        sys.exit(2)
    if not args.prune_only and args.name is None:
        ap.error("--name is required unless --prune-only is given")
    prune_manifest(args.bundle)
    check_json(args.bundle)
    if not args.prune_only:
        write_readme(args.bundle, args.name)


if __name__ == "__main__":
    main()
