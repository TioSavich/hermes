#!/usr/bin/env python3
"""Ask one vision model, in bulk, what vocabulary each student-work crop carries.

An earlier pass judged all 1,359 crops to be student work and then recorded no
representation language for 692 of them, no spatial element for 636, and neither
for 632. That pass saw a cropped PNG and no article, which is how a
candy-grouping figure came to be called base ten. Its script was never recorded,
so this one is written down.

What this module does, and only this:

  * joins each crop to its article and page through scripts/scene/figure_context
    (that join is not reimplemented here),
  * asks one vision model a forced-choice question over the two vocabularies the
    Prolog side already accepts,
  * rejects any answer outside those vocabularies rather than keeping it,
  * records model, prompt version, article path, figure key, page, and timestamp
    on every row it writes.

WHAT THE PASS MEASURED over those 632 crops, 2026-08-01, gemma-4-31B-it at
prompt version bulk-vocab-v1. Read this before trusting the yield:

  * The empty fields were mostly not an omission. 585 of the 632 carry no
    representation language because the eight-term vocabulary has no term for
    what they are: handwritten algebra, calculus, geometric constructions,
    coordinate graphs, classroom photographs, concept maps, children's drawings,
    tree diagrams, chat screenshots. Forty crops were read by hand first, twenty
    by even stride and twenty at random; one of the forty could take a
    representation language. The pass agreed at 5.7%.
  * Where the answer is "none", the pass is accurate and says almost nothing: a
    constant "none" scores 19 of 20 on the hand-read pilot, which is one below
    the model. Accuracy on this corpus is not evidence of capacity.
  * Where the pass departs from "none" is the only place it changes anything,
    and there it was wrong about one time in five. All 36 proposals were opened
    and judged; 7 were rejected and are named in figure_vocabulary_review.json.
    The errors concentrate in area_model (5 of 13 wrong) and fraction_bars (2 of
    4); set_grouping, number_line and place_value_chart held on every proposal.

The forced choice is load-bearing. Asked for a free string, this model answers
"English" for any value it was not given a menu for, so the menu goes in the
prompt text. The endpoint's json_schema response_format was tried first and does
not constrain the model: it returned an enum value while its own reasoning
recorded that no list had been supplied, and it prefixed the object with a stray
brace. The menu is therefore stated in the prompt and every answer is checked
against the vocabularies afterwards. Across 621 parsed replies no value fell
outside either vocabulary, so the menu-in-prompt holds; the residue is 11 replies
that would not parse at all and 52 transcriptions that failed their shape test.

Precedence. A deeper per-figure line is reading the same corpus and writes richer
rows. Every row here carries provenance{pass: "bulk_forced_choice", precedence:
"low"}, so a merge that meets both can drop this one whole.

Usage (from the repo root):

    python3 hermes/representation/bulk_figure_vocabulary.py --pilot 20
    python3 hermes/representation/bulk_figure_vocabulary.py --run
    python3 hermes/representation/bulk_figure_vocabulary.py --apply
"""

from __future__ import annotations

import argparse
import base64
import concurrent.futures
import datetime as _dt
import json
import os
import random
import re
import sys
import threading
import time
import urllib.error
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]

# The join lives in scripts/scene and is imported, never copied. A worktree
# carries no gitignored runtime data, so the crops and articles are read from
# the checkout that holds them; HERMES_SCENE_DIR overrides where the join is.
_SCENE = os.environ.get("HERMES_SCENE_DIR") or str(REPO / "scripts" / "scene")
if not (Path(_SCENE) / "figure_context.py").exists():
    marker = REPO / ".git"
    if marker.is_file():
        text = marker.read_text(encoding="utf-8").strip()
        if text.startswith("gitdir:"):
            main_checkout = Path(text.split(":", 1)[1].strip()).resolve().parents[2]
            _SCENE = str(main_checkout / "scripts" / "scene")
sys.path.insert(0, _SCENE)

from figure_context import (  # noqa: E402
    REPRESENTATION_LANGUAGES,
    SPATIAL_ELEMENTS,
    all_crops,
    figure_context,
)

CROP_ROOT = Path(_SCENE).resolve().parents[1]

PROMPT_VERSION = "bulk-vocab-v1"
INTERPRETED_JSON = REPO / "curriculum" / "im" / "docling_figures_interpreted.json"
BULK_OUT = REPO / "curriculum" / "im" / "figure_vocabulary_bulk.json"

# ---------------------------------------------------------------------------
# The forced choice
# ---------------------------------------------------------------------------

# One line per term, so the model is choosing against a criterion rather than
# against a word. The glosses restate what the Prolog vocabulary already means;
# they add no term to it.
REPRESENTATION_GLOSS = {
    "none": ("the figure carries no diagram from the list below: handwriting, "
             "symbolic algebra, prose, a table, a function graph, a geometric "
             "drawing, or a photograph all count as none"),
    "area_model": "a rectangle or region cut into parts to stand for a product or a fraction",
    "balance_scale": "a two-pan balance or a beam standing for an equation",
    "base_ten_blocks": "unit cubes, ten rods, or hundred flats standing for place value",
    "fraction_bars": "a bar or strip cut into equal parts to stand for a fraction",
    "number_line": "a line carrying a numeric scale with values placed along it",
    "place_value_chart": "a column chart with headed place columns such as ones, tens, hundreds",
    "set_grouping": ("discrete countable marks such as dots, tallies, circles, or "
                     "drawn objects, arranged or grouped to be counted"),
}

SPATIAL_GLOSS = {
    "partition": "a cut or line splitting a whole into parts",
    "equal_part": "parts drawn to the same size",
    "axis": "a marked scale line carrying numbers",
    "counter": "a discrete drawn mark, tally, dot, or token",
    "jump": "an arc or arrow standing for a hop along a line",
    "ten_rod": "a rod of ten units",
    "unit_cube": "a single small square or cube unit",
    "digit_column": "a vertical column of digits aligned by place",
    "ten_frame": "a five by two grid of cells",
    "hundred_flat": "a ten by ten square of units",
    "weight": "a mass or block resting on a balance pan",
    "pan": "a tray of a balance",
}

_PROMPT = """You classify one figure taken from a mathematics education research article.

ARTICLE: {title}
FIGURE: page {page}, figure {index} on that page
CAPTION: {caption}

PASSAGE AROUND THIS FIGURE:
{passage}

Answer with one JSON object and nothing else:

{{"representation_language": "<one value>", "spatial_elements": [<zero or more values>], "transcribed_math": "<expression or none>"}}

representation_language must be EXACTLY ONE of these eight strings:
{rep_menu}

Choose "none" unless the figure really carries one of the other seven. A page of
handwritten algebra is "none". A coordinate graph of a function is "none". A
table of numbers is "none". A geometric construction is "none".

spatial_elements is a list holding ZERO OR MORE of these twelve strings, only
the ones you can point at in this figure:
{spatial_menu}

Write [] when none of the twelve apply.

transcribed_math: copy the arithmetic or algebra written in the figure, symbols
only, for example "3/4 + 1/2 = 5/4". Write "none" if the figure carries no
written expression or you cannot read it. Copy; do not describe.

Use no string outside the two lists above."""


def build_prompt(ctx, title, passage) -> str:
    rep_menu = "\n".join(
        '  "%s" - %s' % (k, REPRESENTATION_GLOSS[k]) for k in REPRESENTATION_LANGUAGES)
    spatial_menu = "\n".join(
        '  "%s" - %s' % (k, SPATIAL_GLOSS[k]) for k in SPATIAL_ELEMENTS)
    return _PROMPT.format(
        title=title,
        page=ctx.page_no if ctx.page_no else "unknown",
        index=ctx.figure_index,
        caption=ctx.caption or "no caption recorded",
        passage=passage,
        rep_menu=rep_menu,
        spatial_menu=spatial_menu,
    )


# ---------------------------------------------------------------------------
# Article context
# ---------------------------------------------------------------------------

_PAGES_RE = re.compile(r"Pages converted: \d+-(\d+) of (\d+)")


def article_window(ctx, head_chars: int = 1100, window_chars: int = 2600) -> tuple[str, str]:
    """Return (title line, passage) for one figure.

    The head carries the title and the opening of the abstract, which is what
    tells the model the population and the domain. The passage is the text around
    the figure's caption when the caption can be located, and otherwise a slice
    of the article at the page's proportional position.
    """
    text = ctx.article_text
    if not text:
        return (ctx.bibtex_key, "no article text on this machine")

    lines = [ln for ln in text[:2000].splitlines() if ln.strip()]
    title = next((ln.lstrip("# ").strip() for ln in lines[1:]
                  if ln.startswith("##") and len(ln) > 12), ctx.bibtex_key)

    head = text[:head_chars]

    at = -1
    if ctx.caption:
        probe = ctx.caption.strip()[:60]
        at = text.find(probe)
        if at < 0 and len(probe) > 25:
            at = text.find(probe[:25])
    if at < 0:
        m = _PAGES_RE.search(text)
        total = int(m.group(2)) if m else 0
        page = ctx.page_no or 1
        if total > 0:
            at = int(len(text) * max(page - 1, 0) / total)
        else:
            at = 0

    lo = max(0, at - window_chars // 2)
    passage = text[lo:lo + window_chars]
    return (title, head + "\n[...]\n" + passage)


# ---------------------------------------------------------------------------
# The model call
# ---------------------------------------------------------------------------

def _env() -> dict:
    env = {}
    path = REPO / ".env"
    if not path.exists():
        marker = REPO / ".git"
        if marker.is_file():
            text = marker.read_text(encoding="utf-8").strip()
            if text.startswith("gitdir:"):
                path = (Path(text.split(":", 1)[1].strip()).resolve().parents[2]) / ".env"
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            env[k] = v
    return env


_ENV = None
_ENV_LOCK = threading.Lock()


def env() -> dict:
    global _ENV
    with _ENV_LOCK:
        if _ENV is None:
            _ENV = _env()
    return _ENV


def call_model(prompt: str, image: Path, max_tokens: int = 3000,
               timeout: int = 300) -> tuple[str, str]:
    """Return (raw content, model id). Raises on transport failure."""
    e = env()
    base = e["REALLMS_BASE_URL"].rstrip("/")
    model = e["REALLMS_MODEL"]
    b64 = base64.b64encode(image.read_bytes()).decode()
    body = {
        "model": model,
        # Below 2500 the content field comes back empty on this deployment.
        "max_tokens": max_tokens,
        "temperature": 0.0,
        "messages": [{"role": "user", "content": [
            {"type": "text", "text": prompt},
            {"type": "image_url", "image_url": {"url": "data:image/png;base64," + b64}},
        ]}],
    }
    req = urllib.request.Request(
        base + "/chat/completions", method="POST",
        data=json.dumps(body).encode("utf-8"),
        headers={"Authorization": "Bearer " + e["REALLMS_API_KEY"],
                 "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        payload = json.load(r)
    return payload["choices"][0]["message"].get("content") or "", model


# ---------------------------------------------------------------------------
# Validation: a value outside the vocabulary is a defect, not a judgement
# ---------------------------------------------------------------------------

_OBJ_RE = re.compile(r"\{.*\}", re.S)
# A LaTeX command inside a transcription is a symbol, not a word, so it is
# removed before the prose test and its backslash is escaped before the JSON
# parse. Three of the first twenty replies were lost to \sqrt, \div, and \ln
# alone: JSON rejects those escapes and the whole row went to waste.
_LATEX_CMD_RE = re.compile(r"\\[A-Za-z]+")
_BAD_ESCAPE_RE = re.compile(r'\\(?!["\\/bfnrtu])')
# A transcription carries symbols and short variable names. More than one word
# of four or more letters is prose, which means the model described the figure
# instead of copying what is written on it.
_PROSE_RE = re.compile(r"[A-Za-z]{4,}")


def parse_and_validate(raw: str) -> tuple[dict, list[str]]:
    """Return (fields, violations). A violated field is dropped, never coerced."""
    violations = []
    text = raw.strip()
    if text.startswith("{\"{"):
        # Observed artifact of the endpoint's response_format path.
        text = text.replace("{\"{", "{", 1)
    m = _OBJ_RE.search(text)
    if not m:
        return {}, ["unparseable:no_json_object"]
    candidates = [m.group(0), _BAD_ESCAPE_RE.sub(r"\\\\", m.group(0))]
    data = None
    for candidate in candidates:
        try:
            data = json.loads(candidate)
            break
        except ValueError:
            repaired = candidate.rstrip().rstrip(",")
            for tail in ("}", "]}", "\"}"):
                try:
                    data = json.loads(repaired + tail)
                    break
                except ValueError:
                    continue
            if data is not None:
                break
    if data is None:
        return {}, ["unparseable:bad_json"]
    if not isinstance(data, dict):
        return {}, ["unparseable:not_object"]

    out = {}

    rep = data.get("representation_language")
    if isinstance(rep, str) and rep.strip() in REPRESENTATION_LANGUAGES:
        out["representation_language"] = rep.strip()
    else:
        violations.append("representation_language:%s" % _short(rep))

    spatial = data.get("spatial_elements")
    if isinstance(spatial, list):
        kept, bad = [], []
        for item in spatial:
            if isinstance(item, str) and item.strip() in SPATIAL_ELEMENTS:
                if item.strip() not in kept:
                    kept.append(item.strip())
            else:
                bad.append(_short(item))
        out["spatial_elements"] = kept
        for b in bad:
            violations.append("spatial_elements:%s" % b)
    else:
        violations.append("spatial_elements:%s" % _short(spatial))

    tm = data.get("transcribed_math")
    if isinstance(tm, str):
        tm = tm.strip()
        if tm.lower() in ("none", "", "n/a"):
            out["transcribed_math"] = "none"
        elif len(tm) > 240:
            violations.append("transcribed_math:too_long")
        elif not any(ch.isdigit() for ch in tm):
            violations.append("transcribed_math:no_digit")
        elif len(_PROSE_RE.findall(_LATEX_CMD_RE.sub(" ", tm))) > 1:
            violations.append("transcribed_math:prose")
        else:
            out["transcribed_math"] = tm
    else:
        violations.append("transcribed_math:%s" % _short(tm))

    return out, violations


def _short(v) -> str:
    s = str(v)
    return s[:40].replace("\n", " ")


# ---------------------------------------------------------------------------
# Driving one figure
# ---------------------------------------------------------------------------

def _corpus_relative(path) -> str | None:
    """Name the article by its place in the literature corpus, not by this disk.

    An absolute path records which machine ran the pass, which is not what a
    reader of these rows needs to know.
    """
    if not path:
        return None
    parts = Path(path).parts
    if ".bigred-collected" in parts:
        return "/".join(parts[parts.index(".bigred-collected"):])
    return str(path)


def classify(rel: str) -> dict:
    """Classify one crop. Returns a row carrying its own provenance."""
    crop = CROP_ROOT / rel
    ctx = figure_context(crop)
    title, passage = article_window(ctx)
    prompt = build_prompt(ctx, title, passage)

    started = _dt.datetime.now(_dt.timezone.utc)
    raw, model = call_model(prompt, crop)
    if not raw.strip():
        # This model reasons before it answers, and a long enough deliberation
        # consumes the budget and returns an empty content field. One retry with
        # more room recovers most of those.
        raw, model = call_model(prompt, crop, max_tokens=6000)
    fields, violations = parse_and_validate(raw)

    return {
        "image": rel,
        "fields": fields,
        "violations": violations,
        "provenance": {
            "pass": "bulk_forced_choice",
            "precedence": "low",
            "model": model,
            "prompt_version": PROMPT_VERSION,
            "article_path": _corpus_relative(ctx.article_path),
            "figure_key": ctx.bibtex_key,
            "figure_id": ctx.figure_id,
            "page": ctx.page_no,
            "figure_index": ctx.figure_index,
            "join": ctx.join,
            "caption": ctx.caption,
            "timestamp": started.isoformat(timespec="seconds"),
        },
        "raw": raw[:600],
    }


def target_images(interpreted: Path = INTERPRETED_JSON) -> list[str]:
    """Crops carrying neither a representation language nor a spatial element."""
    rows = json.loads(interpreted.read_text(encoding="utf-8"))["rows"]
    out = []
    for r in rows:
        if r["representation_language"] == "none" and not r["spatial_elements"]:
            out.append(r["image"].replace("docs/research_assets", "data/research_assets", 1))
    on_disk = {str(c.relative_to(CROP_ROOT)) for c in all_crops()}
    return sorted(p for p in out if p in on_disk)


# ---------------------------------------------------------------------------
# Batch driving, with a checkpoint after every result
# ---------------------------------------------------------------------------

def run_batch(images: list[str], out_path: Path, workers: int = 4,
              pause: float = 0.4, retries: int = 2) -> dict:
    done = {}
    if out_path.exists():
        prior = json.loads(out_path.read_text(encoding="utf-8"))
        done = {r["image"]: r for r in prior.get("rows", [])}
    todo = [i for i in images if i not in done]
    print("images %d, already recorded %d, to call %d" % (len(images), len(done), len(todo)))

    lock = threading.Lock()
    counter = {"n": 0}

    def work(rel):
        for attempt in range(retries + 1):
            try:
                time.sleep(pause * random.random())
                return classify(rel)
            except (urllib.error.HTTPError, urllib.error.URLError, OSError,
                    KeyError, ValueError) as exc:
                if attempt == retries:
                    return {"image": rel, "fields": {},
                            "violations": ["transport:%s" % type(exc).__name__],
                            "provenance": {"pass": "bulk_forced_choice",
                                           "precedence": "low",
                                           "prompt_version": PROMPT_VERSION,
                                           "error": str(exc)[:200]},
                            "raw": ""}
                time.sleep(2.0 * (attempt + 1))

    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as pool:
        for row in pool.map(work, todo):
            with lock:
                done[row["image"]] = row
                counter["n"] += 1
                if counter["n"] % 10 == 0 or counter["n"] == len(todo):
                    _write(out_path, done)
                    print("  %d/%d" % (counter["n"], len(todo)), flush=True)
    _write(out_path, done)
    return done


def _write(path: Path, done: dict) -> None:
    payload = {
        "generator": "hermes/representation/bulk_figure_vocabulary.py",
        "note": ("Forced-choice vocabulary fill over the student-work crops that "
                 "carried neither a representation language nor a spatial "
                 "element. Every row records its own provenance; precedence is "
                 "low, so a deeper per-figure row supersedes it."),
        "prompt_version": PROMPT_VERSION,
        "count": len(done),
        "rows": [done[k] for k in sorted(done)],
    }
    tmp = path.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(payload, ensure_ascii=False, indent=1), encoding="utf-8")
    tmp.replace(path)


# ---------------------------------------------------------------------------
# Applying the fill to the interpreted surfaces
# ---------------------------------------------------------------------------

def apply_to_interpreted() -> dict:
    """Rewrite the two interpreted surfaces from the committed rows.

    The generator cannot run in this repo: its crop list and its research.db are
    both absent, so a regeneration would strip the domains and grade buckets the
    committed rows carry. This re-emits from those rows instead, and reuses the
    generator's own overlay merge and emitters so the two paths cannot drift.
    """
    sys.path.insert(0, str(HERE))
    from regenerate_docling_interpreted import (  # noqa: E402
        _short_key, apply_bulk_overlay, emit_json, emit_pl,
    )
    from build_asset_manifest import _classifications  # noqa: E402

    payload = json.loads(INTERPRETED_JSON.read_text(encoding="utf-8"))
    rows = payload["rows"]

    # description = what the crop shows; student_strategy = what the student did.
    classes = _classifications()
    redescribed = 0
    for r in rows:
        cls = classes.get(_short_key(r["image"]))
        if not cls:
            continue
        reason = (cls.get("reason") or "").strip()
        if reason and r["description"] != reason:
            r["description"] = reason
            redescribed += 1

    tally = apply_bulk_overlay(rows)
    tally["description_from_reason"] = redescribed
    tally["rows"] = len(rows)
    tally["still_identical_description_and_strategy"] = sum(
        1 for r in rows if r["description"] == r["student_strategy"])

    emit_pl(rows)
    emit_json(rows)
    return tally


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--pilot", type=int, default=0,
                    help="classify N figures drawn evenly across the target set")
    ap.add_argument("--run", action="store_true", help="classify the whole target set")
    ap.add_argument("--apply", action="store_true",
                    help="merge the recorded rows onto the interpreted surfaces")
    ap.add_argument("--out", default=str(BULK_OUT))
    ap.add_argument("--workers", type=int, default=4)
    args = ap.parse_args()

    out = Path(args.out)
    if args.pilot:
        images = target_images()
        step = max(1, len(images) // args.pilot)
        picked = images[::step][:args.pilot]
        run_batch(picked, out, workers=args.workers)
    elif args.run:
        run_batch(target_images(), out, workers=args.workers)
    elif args.apply:
        print(json.dumps(apply_to_interpreted(), indent=1))
    else:
        images = target_images()
        print("target images: %d" % len(images))


if __name__ == "__main__":
    main()
