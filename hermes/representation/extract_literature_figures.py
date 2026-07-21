#!/usr/bin/env python3
"""Render literature student-work figure pages across ALL domains.

Thin wrapper around research_corpus/scripts/find_student_work_figures.py. The
corpus script defaults to a single domain (fraction, capped at 40 articles); this
runs it across every domain in research.db that carries the
articles.has_student_work_figures flag, renders the candidate pages, and writes a
candidates JSON that hermes/representation/build_asset_manifest.py picks up.

Full-page renders only (no auto-crops): the auto-crops were rough, and the plan
is human cropping from the full page. Output goes to a dated all-domains asset
dir so it sits alongside the original fraction set without clobbering it.

Run from the repo root:
    python3 hermes/representation/extract_literature_figures.py            # figure pages
    python3 hermes/representation/extract_literature_figures.py --all      # + topic-only pages
    python3 hermes/representation/extract_literature_figures.py --dpi 120  # smaller files
"""

import argparse
import importlib.util
import sys
from pathlib import Path
from types import SimpleNamespace

REPO = Path(__file__).resolve().parents[2]
CORPUS_SCRIPT = REPO / "research_corpus" / "scripts" / "find_student_work_figures.py"
STAMP = "2026-06-18-all-domains"
ASSET_DIR = REPO / "data" / "research_assets" / "research" / "student_work_figures" / STAMP
JSON_OUT = (REPO / "data" / "research_assets" / "research"
            / f"{STAMP}-student-work-figure-candidates.json")


def load_corpus_module():
    spec = importlib.util.spec_from_file_location("fsw", CORPUS_SCRIPT)
    mod = importlib.util.module_from_spec(spec)
    sys.modules["fsw"] = mod          # dataclasses need the module registered
    spec.loader.exec_module(mod)
    return mod


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--all", action="store_true",
                    help="include topic-only pages, not just flagged figure pages")
    ap.add_argument("--dpi", type=int, default=150)
    ap.add_argument("--limit", type=int, default=0,
                    help="cap pages rendered (0 = no cap; for quick tests)")
    args = ap.parse_args()

    m = load_corpus_module()
    conn = m.connect(m.DB_PATH)
    try:
        candidates = m.build_candidates(conn, domain=None,
                                        max_articles=10000, max_pages=100000)
    finally:
        conn.close()

    selected = candidates if args.all else [c for c in candidates if c.figure_page]
    if args.limit:
        selected = selected[:args.limit]

    print(f"candidates: {len(candidates)} total, rendering {len(selected)} "
          f"({'all' if args.all else 'figure-flagged'}) at {args.dpi} dpi")
    print(f"asset dir: {ASSET_DIR.relative_to(REPO)}")

    m.render_candidates(selected, asset_dir=ASSET_DIR, dpi=args.dpi,
                        render_pages=True, extract_crops=False)

    # write_json needs an args-like object exposing .domain
    m.write_json(selected, JSON_OUT, SimpleNamespace(domain="all"))
    rendered = sum(1 for c in selected if getattr(c, "rendered_page_path", None))
    print(f"rendered {rendered} pages")
    print(f"wrote {JSON_OUT.relative_to(REPO)}")


if __name__ == "__main__":
    main()
