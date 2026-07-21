#!/usr/bin/env python3
"""Extract student-work FIGURES from the literature with docling (not full pages).

For every article flagged with student-work figures (across all domains), run the
docling CLI, keep the real figure crops (drop the page text and the glyph-noise),
and join each figure to citation + page + the error/strategy topics on that page.
Figure crops are far smaller than full-page renders, so this both kills the git
bloat and removes the hand-cropping step.

Slow but resumable: it skips articles already recorded, so it can run for hours
in the background and be re-run to finish. Outputs:

  data/research_assets/research/student_work_figures/2026-06-18-docling-figures/<bibkey>/pNN_k.png
  data/research_assets/research/2026-06-18-docling-figures.jsonl   (one figure per line)

hermes/representation/build_asset_manifest.py reads the .jsonl when present.

Run from the repo root:
    python3 hermes/representation/extract_figures_docling.py
"""

import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
CORPUS_SCRIPT = REPO / "research_corpus" / "scripts" / "find_student_work_figures.py"
STAMP = "2026-06-18-docling-figures"
ASSET_DIR = REPO / "data" / "research_assets" / "research" / "student_work_figures" / STAMP
JSONL = REPO / "data" / "research_assets" / "research" / f"{STAMP}.jsonl"
LOG = Path(tempfile.gettempdir()) / "docling_pipeline.log"

MIN_KB = 10          # drop glyph-noise
MIN_DIM = 100        # drop tiny inline marks
HASH_RE = re.compile(r"image_\d+_([0-9a-f]{12,})\.png")


def log(msg):
    line = f"[{time.strftime('%H:%M:%S')}] {msg}"
    print(line, flush=True)
    with open(LOG, "a") as f:
        f.write(line + "\n")


def load_corpus_module():
    spec = importlib.util.spec_from_file_location("fsw", CORPUS_SCRIPT)
    mod = importlib.util.module_from_spec(spec)
    sys.modules["fsw"] = mod
    spec.loader.exec_module(mod)
    return mod


def group_by_article(m):
    """article_key -> {meta, pages: {pdf_index: {page_ref, error_topics, strategy_topics}},
                       all_error, all_strategy}."""
    import fitz
    conn = m.connect(m.DB_PATH)
    try:
        cands = m.build_candidates(conn, domain=None, max_articles=10000,
                                   max_pages=100000)
    finally:
        conn.close()
    arts = {}
    by_key = {}
    for c in cands:
        by_key.setdefault(c.bibtex_key, []).append(c)
    for key, cs in by_key.items():
        c0 = cs[0]
        pages = {}
        all_err, all_strat = set(), set()
        pdf = REPO / "research_corpus" / c0.local_pdf_path
        doc = None
        if pdf.exists():
            try:
                doc = fitz.open(pdf)
            except Exception:
                doc = None
        for c in cs:
            all_err.update(c.error_topics or [])
            all_strat.update(c.strategy_topics or [])
            idx = None
            if doc is not None:
                try:
                    idx, _, _ = m.resolve_pdf_page(doc, c.page_ref)
                except Exception:
                    idx = None
            if idx is not None:
                pages[idx] = {  # fitz 0-based index
                    "page_ref": c.page_ref,
                    "error_topics": c.error_topics or [],
                    "strategy_topics": c.strategy_topics or [],
                }
        if doc is not None:
            doc.close()
        arts[key] = {
            "bibtex_key": key,
            "citation": (c0.citation() if callable(getattr(c0, "citation", None))
                         else f"{c0.authors} ({c0.year})"),
            "authors": c0.authors, "year": c0.year, "title": c0.title,
            "journal": c0.journal, "local_pdf_path": c0.local_pdf_path,
            "pages": pages,
            "all_error_topics": sorted(all_err),
            "all_strategy_topics": sorted(all_strat),
        }
    return arts


def already_done():
    done = set()
    if JSONL.exists():
        for line in open(JSONL, encoding="utf-8"):
            try:
                done.add(json.loads(line)["bibtex_key"])
            except Exception:
                pass
    return done


def run_docling(pdf, workdir):
    cmd = ["docling", str(pdf), "--to", "json", "--image-export-mode",
           "referenced", "--no-ocr", "--output", str(workdir)]
    subprocess.run(cmd, check=True, capture_output=True, text=True, timeout=900)
    js = list(workdir.glob("*.json"))
    return js[0] if js else None


def keep_figures(doc_json, workdir):
    """Yield (page_no_1based, abs_png_path, w, h, caption) for real figures."""
    d = json.load(open(doc_json, encoding="utf-8"))
    seen = set()
    for p in d.get("pictures", []):
        img = p.get("image") or {}
        uri = img.get("uri")
        if not uri:
            continue
        fp = Path(uri) if os.path.isabs(uri) else (workdir / uri)
        if not fp.exists():
            continue
        h = HASH_RE.search(fp.name)
        sig = h.group(1) if h else fp.name
        if sig in seen:
            continue
        sz = img.get("size") or {}
        w, ht = int(sz.get("width", 0)), int(sz.get("height", 0))
        if fp.stat().st_size / 1024 < MIN_KB or w < MIN_DIM or ht < MIN_DIM:
            continue
        seen.add(sig)
        prov = p.get("prov") or [{}]
        page_no = prov[0].get("page_no")
        caps = p.get("captions") or []
        caption = caps[0].get("text") if caps and isinstance(caps[0], dict) else None
        yield page_no, fp, w, ht, caption


def process(art, idx_in, total):
    key = art["bibtex_key"]
    pdf = REPO / "research_corpus" / art["local_pdf_path"]
    if not pdf.exists():
        log(f"({idx_in}/{total}) SKIP no pdf: {key}")
        return 0
    workdir = Path(tempfile.mkdtemp(prefix="docling_"))
    records = []
    try:
        dj = run_docling(pdf, workdir)
        if not dj:
            log(f"({idx_in}/{total}) no json: {key}")
            return 0
        out_art = ASSET_DIR / key
        out_art.mkdir(parents=True, exist_ok=True)
        counters = {}
        for page_no, fp, w, ht, caption in keep_figures(dj, workdir):
            k = counters.get(page_no, 0) + 1
            counters[page_no] = k
            dest = out_art / f"p{page_no}_{k}.png"
            shutil.copyfile(fp, dest)
            # topic join: docling page_no is 1-based; candidate pages are fitz 0-based
            pg = art["pages"].get((page_no or 0) - 1)
            on_cand = pg is not None
            err = pg["error_topics"] if pg else art["all_error_topics"]
            strat = pg["strategy_topics"] if pg else art["all_strategy_topics"]
            records.append({
                "source": "literature",
                "id": f"docfig-{key}-p{page_no}-{k}",
                "bibtex_key": key,
                "citation": art["citation"],
                "authors": art["authors"], "year": art["year"],
                "title": art["title"], "journal": art["journal"],
                "page_no": page_no,
                "page_ref": pg["page_ref"] if pg else None,
                "on_candidate_page": on_cand,
                "image": ("docs/research_assets/" + str(
                    dest.relative_to(REPO / "data" / "research_assets")
                ).replace(os.sep, "/")),
                "width": w, "height": ht,
                "caption": caption,
                "error_topics": err[:6],
                "strategy_topics": strat[:6],
                "crop_status": "docling_auto",
            })
    finally:
        shutil.rmtree(workdir, ignore_errors=True)
    # append atomically-ish (one article's records as a block)
    with open(JSONL, "a", encoding="utf-8") as f:
        for r in records:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    log(f"({idx_in}/{total}) {key}: {len(records)} figures")
    return len(records)


def main():
    log(f"loading candidates from corpus DB...")
    m = load_corpus_module()
    arts = group_by_article(m)
    keys = sorted(arts)
    done = already_done()
    todo = [k for k in keys if k not in done]
    log(f"{len(keys)} figure-articles, {len(done)} already done, {len(todo)} to do")
    ASSET_DIR.mkdir(parents=True, exist_ok=True)
    total_figs = 0
    for i, key in enumerate(todo, 1):
        try:
            total_figs += process(arts[key], i, len(todo))
        except subprocess.TimeoutExpired:
            log(f"({i}/{len(todo)}) TIMEOUT: {key}")
        except subprocess.CalledProcessError as e:
            log(f"({i}/{len(todo)}) docling ERROR: {key}: {str(e.stderr)[:200]}")
        except Exception as e:
            log(f"({i}/{len(todo)}) FAIL: {key}: {e}")
    log(f"DONE. wrote {total_figs} new figures this run. jsonl: {JSONL}")


if __name__ == "__main__":
    main()
