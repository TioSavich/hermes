#!/usr/bin/env python3
"""Targeting for the 2026-08-18 vision wave.

Builds the candidate pool per the ground-truth recipe (figure_sources.jsonl's
picture_routine + visual_general, union draw_task_map.jsonl's interpret_given,
minus the 117 g8_stripped rows a parallel lane handles, minus every record
already admitted in merged_admitted_ledger.jsonl or recovery_wave_ledger.jsonl),
then locates each candidate statement inside its lesson's document.md and
selects up to 3 nearby candidate images by POSITION -- the md's own header
structure is the map, not a learned or guessed layout.

Method, in order:
  1. Locate the statement inside document.md: an exact normalized-whitespace
     substring match if possible, else the longest common word-run anchor
     (borrowed word-anchor search, same family as vision_pass.py's
     locate_excerpt), else an ordered-record fallback (declared as such).
  2. Find the smallest enclosing header section (## / ### / #### ...). Take
     every image marker inside it, dropping images picture_descriptions.md
     independently marks as logo/heading/duration-icon/non-mathematical art
     (vision_pass.py's image_exclusion, reused unmodified).
  3. If the enclosing section holds no eligible image, widen to the nearest
     enclosing "##"-level section, then to a +/-40-line window around the
     anchor, then to the nearest eligible image anywhere in the document
     (distance-capped at 200 lines) -- each widening step is recorded.
  4. Rank surviving images by line-distance to the anchor; keep the nearest 3.
  5. Record, per row, whether document.md ALREADY carries a "### Description
     of the Image:" block for a selected image immediately following it --
     when it does, that text is curriculum-authored structure already on the
     page, not a caption to re-derive, and the vision-serving step reads it
     for free instead of spending a model call.

Output: hermes/app/runtime/experiments/coverage_grind/vision_targets.jsonl
(gitignored runtime data).
"""
from __future__ import annotations

import argparse
import bisect
import importlib.util
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
GRIND = REPO / "hermes" / "app" / "runtime" / "experiments" / "coverage_grind"
DOCLING_BASE = (REPO / "hermes" / "app" / "runtime" / "experiments" /
                 "gemma4_tutor" / "docling" / "full-output" / "TeacherLessonGuides")

# Reuse vision_pass.py's proven image-exclusion / description-index logic
# rather than re-deriving it -- same lesson corpus, same picture_descriptions.md
# shape, already validated against live captions.
sys.path.insert(0, str(REPO))
_vp_spec = importlib.util.spec_from_file_location(
    "vision_pass_reuse", REPO / "scripts" / "curriculum" / "vision_pass.py")
vision_pass = importlib.util.module_from_spec(_vp_spec)
sys.modules[_vp_spec.name] = vision_pass  # dataclass() needs sys.modules[__module__]
_vp_spec.loader.exec_module(vision_pass)

LESSON_RE = re.compile(r"IM-G(K|\d+)-U(\d+)-L(\d+)")
HEADER_RE = re.compile(r"^(#{1,6})\s+(.*)$")
IMAGE_MARKER_RE = re.compile(r"^\s*!\[[^\]]*\]\(([^)]+)\)\s*$")
DESCRIPTION_HEADER = "### Description of the Image:"
WIDEN_LINE_WINDOW = 40
FALLBACK_DISTANCE_CAP = 200
MAX_IMAGES_PER_STATEMENT = 3
RECURRING_TEMPLATE_LESSON_THRESHOLD = 10


def compute_recurring_template_digests(min_lessons: int = RECURRING_TEMPLATE_LESSON_THRESHOLD) -> set[str]:
    """Every image digest (content sha256, already embedded in the docling
    filename -- no re-hashing needed) that recurs across at least
    min_lessons DISTINCT lesson directories corpus-wide. 35,507 digests
    exist across 1,308 lessons and 32,069 of them (90%) are lesson-unique;
    the handful above this threshold are IM logos, routine-icon glyphs, and
    numbering markers, verified by inspection at counts 12-1220 (never a
    once-per-lesson content image at that frequency). Catches furniture
    picture_descriptions.md never captioned (hand verification,
    Kindergarten-3-2 image_000038: an undescribed decorative squiggle
    reused across many lessons' Bingo-center pages slipped past the
    caption-based FURNITURE_CLASSES filter, though that specific squiggle
    turned out lesson-unique -- this is the general defense for the ones
    that are NOT unique)."""
    digest_lessons: dict[str, set[str]] = {}
    for lesson_dir in DOCLING_BASE.glob("*/*-Lesson-teacher-guide-"):
        artifacts = lesson_dir / "document_artifacts"
        if not artifacts.is_dir():
            continue
        for name in artifacts.iterdir():
            m = vision_pass.IMAGE_DIGEST_RE.search(name.name)
            if m:
                digest_lessons.setdefault(m.group(1), set()).add(str(lesson_dir))
    return {d for d, lessons in digest_lessons.items() if len(lessons) >= min_lessons}


def load_jsonl(path: Path) -> list[dict]:
    return [json.loads(l) for l in open(path, encoding="utf-8") if l.strip()]


def lesson_document_path(lesson: str | None) -> Path | None:
    """document.md path for one lesson code -- same mapping build_recovery_wave
    _targets.py verified against all 1,308 docling directories, applied to
    document.md instead of picture_descriptions.md."""
    if not lesson:
        return None
    m = LESSON_RE.match(lesson)
    if not m:
        return None
    grade, unit, lnum = m.groups()
    grade_dir = "Kindergarten" if grade == "K" else f"Grade{grade}"
    subdir = f"{grade_dir}-{unit}-{lnum}-Lesson-teacher-guide-"
    return DOCLING_BASE / grade_dir / subdir / "document.md"


def normalize_ws(s: str) -> str:
    return re.sub(r"\s+", " ", s).strip().lower()


def normalized_line_index(lines: list[str]) -> tuple[str, list[int]]:
    joined = ""
    starts: list[int] = []
    for line in lines:
        starts.append(len(joined))
        joined += normalize_ws(line) + " "
    return joined, starts


# Section titles the IM guide format uses for facilitation/administrative
# prose that echoes task words without being the task -- an "Instructional
# Routines" bullet like "Which Three Go Together?" (a routine's NAME) or a
# "Launch" line quoting the prompt as a facilitation cue both real-word-match
# a statement's own words without sitting next to its illustration. Hand
# verification (record im_defrag_6160faec9c2f15ea25cb5c23_1, IM-G2-U2-L1)
# caught the single-distinctive-word tier anchoring on "together" inside the
# routine's NAME two headers early, missing the real Student Task Statement
# image entirely.
ADMIN_SECTION_TITLES = {
    "instructional routines", "standards", "narrative", "goals",
    "lesson purpose", "lesson timeline", "materials to gather",
    "required materials", "access for students with disabilities",
    "teacher reflection questions", "student facing learning goals",
}


def _all_hits(needle: str, joined: str) -> list[int]:
    hits = []
    pos = 0
    while True:
        offset = joined.find(needle, pos)
        if offset < 0:
            break
        hits.append(offset)
        pos = offset + 1
    return hits


def _hit_priority(offset: int, starts: list[int], sections) -> int:
    """2 = a canonical Student/Task Statement section (where the IM format
    actually places the task and its image); 1 = any other named section
    (Warm-up, Launch, Activity, Cool-down, Student Response, or no header
    yet); 0 = a known administrative/facilitation section. A "Launch"
    bullet re-quoting the prompt as a facilitation cue and the actual task
    text share the same words -- without this a tie between them can pick
    either at random (hand verification, IM-G4-U8-L11: a 2-hit median
    picked "Launch" over "Student Task Statement")."""
    line = bisect.bisect_right(starts, offset) - 1
    sec = enclosing_section(sections, line)
    if sec is None:
        return 1
    title = sec[3].strip().lower()
    if title in TASK_HEADER_TITLES:
        return 2
    if title in ADMIN_SECTION_TITLES:
        return 0
    return 1


def _prefer_hit(hits: list[int], starts: list[int], sections) -> int:
    """Among several byte offsets where a candidate matched, prefer the
    highest-priority section (see _hit_priority); break ties by median
    position among the preferred set."""
    if len(hits) == 1:
        return hits[0]
    best_priority = max(_hit_priority(h, starts, sections) for h in hits)
    pool = sorted(h for h in hits if _hit_priority(h, starts, sections) == best_priority)
    return pool[len(pool) // 2]


def locate_statement(statement: str, joined: str, starts: list[int], sections) -> tuple[int | None, str]:
    """(anchor_line, method). Longest common word-run anchor, same family as
    vision_pass.py's locate_excerpt, applied to a task statement instead of
    a harvested excerpt. Every tier collects ALL hits and prefers the one(s)
    outside an administrative section (see ADMIN_SECTION_TITLES) before
    taking a median -- a single first-match was verified to mislocate a
    statement whose words also appear in a routine name or facilitation cue."""
    norm = normalize_ws(statement)
    if not norm:
        return None, "empty_statement"
    hits = _all_hits(norm, joined)
    if hits:
        offset = _prefer_hit(hits, starts, sections)
        return bisect.bisect_right(starts, offset) - 1, "exact_substring"
    words = norm.split()
    for width in range(min(20, len(words)), 3, -1):
        hits = []
        for start in range(len(words) - width + 1):
            hits.extend(_all_hits(" ".join(words[start:start + width]), joined))
        if hits:
            offset = _prefer_hit(hits, starts, sections)
            return bisect.bisect_right(starts, offset) - 1, f"word_anchor_{width}"
    for word in words:
        if len(word) < 8:
            continue
        hits = _all_hits(word, joined)
        if hits:
            offset = _prefer_hit(hits, starts, sections)
            return bisect.bisect_right(starts, offset) - 1, "distinct_word_anchor"
    return None, "unresolved"


TASK_HEADER_TITLES = ("student task statement", "task statement")


def relocate_to_task_section_if_admin(anchor: int, method: str, sections):
    """Every candidate record in this pool is a task statement, and the IM
    guide format names that section explicitly. When the anchor a text
    search found sits inside an administrative section (or no anchor could
    be resolved at all) AND the document HAS a Student Task Statement
    header, retarget there instead of trusting a weak or misleading text
    match. Hand verification (im_defrag_6160faec9c2f15ea25cb5c23_1,
    IM-G2-U2-L1) found "Which 3 go together?" anchoring on a routine's NAME
    in "Instructional Routines" -- two headers before the actual task and
    its image -- because the word "together" never recurs near the task
    itself; this repairs that class of miss generally, not per-record."""
    sec = enclosing_section(sections, anchor)
    is_admin = sec is not None and sec[3].strip().lower() in ADMIN_SECTION_TITLES
    if method != "unresolved" and not is_admin:
        return anchor, method
    for start, end, level, title in sections:
        if title.strip().lower() in TASK_HEADER_TITLES:
            return start, f"{method}+task_statement_relocated"
    return anchor, method


def header_sections(lines: list[str]) -> list[tuple[int, int, int, str]]:
    """(start_line, end_line_exclusive, level, title) covering the whole
    document; the header line itself opens its section, so an image placed
    directly under a header (the IM curriculum's usual "## Warm-up" then
    stimulus-image pattern) counts as inside that section."""
    headers = []
    for i, line in enumerate(lines):
        m = HEADER_RE.match(line)
        if m:
            headers.append((i, len(m.group(1)), m.group(2).strip()))
    sections = []
    for idx, (line_no, level, title) in enumerate(headers):
        end = headers[idx + 1][0] if idx + 1 < len(headers) else len(lines)
        sections.append((line_no, end, level, title))
    return sections


def enclosing_section(sections: list[tuple[int, int, int, str]], anchor: int):
    for start, end, level, title in sections:
        if start <= anchor < end:
            return start, end, level, title
    return None


def enclosing_h2_section(sections, anchor: int):
    candidates = [s for s in sections if s[2] <= 2 and s[0] <= anchor]
    if not candidates:
        return None
    start, _, level, title = max(candidates, key=lambda s: s[0])
    ends = [s[1] for s in sections if s[0] > start]
    end = min(ends) if ends else len(sections)
    return start, end, level, title


def eligible_images(lines: list[str], exclusion_index: dict[str, str | None]) -> list[dict]:
    out = []
    for i, line in enumerate(lines):
        m = IMAGE_MARKER_RE.match(line)
        if not m:
            continue
        ref = m.group(1)
        out.append({"line": i, "ref": ref, "excluded_as": exclusion_index.get(ref)})
    return out


# vision_pass.py's image_exclusion() serves a DIFFERENT purpose (skip images
# unlikely to hold task-transcription text) and its "non_mathematical_art"
# class is too aggressive here: hand-verification (record
# im_defrag_a22fd87d007ac78a96387a73_1, IM-G1-U2-L3) found it dropping the
# one narrative illustration a numberless "notice/wonder" story problem
# actually needs, because docling's own caption says "no mathematical
# objects" about a scene that is exactly the task's content (two children,
# a book, an exchange -- discrete objects a vision pass should still count).
# "logo" / "heading" / "duration_icon" stay excluded: those really are
# furniture regardless of the task at hand.
FURNITURE_CLASSES = {"logo", "heading", "duration_icon"}


def build_exclusion_index(doc_path: Path, lines: list[str],
                           recurring_digests: set[str]) -> dict[str, str | None]:
    """ref -> exclusion class. Two independent signals, either sufficient:
    (a) vision_pass.py's description_index + image_exclusion against
    picture_descriptions.md's own digest-keyed captions, narrowed to
    FURNITURE_CLASSES; (b) the image's digest recurs across many lessons
    corpus-wide (compute_recurring_template_digests) -- catches template
    assets picture_descriptions.md never captioned. Images with neither
    signal are never excluded (absence of evidence is not evidence of
    furniture)."""
    idx: dict[str, str | None] = {}
    try:
        descriptions = vision_pass.description_index(doc_path)
    except ValueError:
        descriptions = {}
    for line in lines:
        m = IMAGE_MARKER_RE.match(line)
        if not m:
            continue
        ref = m.group(1)
        digest_match = vision_pass.IMAGE_DIGEST_RE.search(ref)
        digest = digest_match.group(1) if digest_match else None
        if digest and digest in recurring_digests:
            idx[ref] = "recurring_template_asset"
            continue
        description = descriptions.get(digest, "") if digest else ""
        cls = vision_pass.image_exclusion(description) if description else None
        idx[ref] = cls if cls in FURNITURE_CLASSES else None
    return idx


def inline_description(lines: list[str], image_line: int) -> str | None:
    """Text under a "### Description of the Image:" header that follows the
    image marker before any OTHER image marker or header interrupts --
    curriculum/docling structure already on the page (may be preceded by a
    short lead-in paragraph, as in the Grade4-4-20 Student Task Statement
    section), read for free rather than re-derived by a model call."""
    probe = image_line + 1
    while probe < len(lines):
        stripped = lines[probe].strip()
        if stripped == DESCRIPTION_HEADER:
            j = probe + 1
            out = []
            while j < len(lines) and not HEADER_RE.match(lines[j]):
                out.append(lines[j])
                j += 1
            text = "\n".join(out).strip()
            return text or None
        if IMAGE_MARKER_RE.match(lines[probe]) or HEADER_RE.match(lines[probe]):
            return None
        probe += 1
    return None


def select_candidate_images(lines: list[str], sections, anchor: int,
                             exclusion_index: dict[str, str | None]):
    """Returns (images_ranked, scope_used, widen_trace)."""
    all_images = eligible_images(lines, exclusion_index)
    eligible = [im for im in all_images if im["excluded_as"] is None]
    widen_trace = []

    def in_range(start, end):
        return [im for im in eligible if start <= im["line"] < end]

    sec = enclosing_section(sections, anchor)
    if sec is not None:
        start, end, level, title = sec
        pool = in_range(start, end)
        widen_trace.append(f"section[{title!r} L{level} lines {start}-{end}]: {len(pool)} eligible")
        if pool:
            return rank(pool, anchor), "enclosing_section", widen_trace, (start, end, title)

    h2 = enclosing_h2_section(sections, anchor)
    if h2 is not None:
        start, end, level, title = h2
        pool = in_range(start, end)
        widen_trace.append(f"h2_section[{title!r} lines {start}-{end}]: {len(pool)} eligible")
        if pool:
            return rank(pool, anchor), "enclosing_h2_section", widen_trace, (start, end, title)

    lo = max(0, anchor - WIDEN_LINE_WINDOW)
    hi = min(len(lines), anchor + WIDEN_LINE_WINDOW)
    pool = in_range(lo, hi)
    widen_trace.append(f"line_window[{lo}-{hi}]: {len(pool)} eligible")
    if pool:
        return rank(pool, anchor), "line_window_40", widen_trace, (lo, hi, None)

    pool = [im for im in eligible if abs(im["line"] - anchor) <= FALLBACK_DISTANCE_CAP]
    widen_trace.append(f"nearest_any[cap {FALLBACK_DISTANCE_CAP}]: {len(pool)} eligible")
    if pool:
        return rank(pool, anchor), "nearest_any_capped", widen_trace, (None, None, None)

    return [], "no_image_found", widen_trace, (None, None, None)


def rank(pool, anchor):
    ranked = sorted(pool, key=lambda im: (abs(im["line"] - anchor), im["line"]))
    return ranked[:MAX_IMAGES_PER_STATEMENT]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(GRIND / "vision_targets.jsonl"))
    args = ap.parse_args()

    figure_sources = load_jsonl(GRIND / "figure_sources.jsonl")
    draw_task_map = load_jsonl(GRIND / "draw_task_map.jsonl")
    merged = load_jsonl(GRIND / "merged_admitted_ledger.jsonl")
    recov = load_jsonl(GRIND / "recovery_wave_ledger.jsonl")
    uncovered = load_jsonl(GRIND / "uncovered_targets.jsonl")

    pr = {r["record_id"] for r in figure_sources if r["decline_class"] == "picture_routine"}
    vg = {r["record_id"] for r in figure_sources if r["decline_class"] == "visual_general"}
    ig = {r["record_id"] for r in draw_task_map if r["resolution"] == "interpret_given"}
    g8_excluded = {
        r["record_id"] for r in figure_sources
        if r["decline_class"] == "g8_stripped_figure_table"
        and r["specificity"] != "generic_docling_lesson_material"}
    assert len(g8_excluded) == 117, f"expected 117 g8_stripped exclusions, got {len(g8_excluded)}"

    pool = (pr | vg | ig) - g8_excluded
    admitted_ids = ({r["record_id"] for r in merged if r.get("gate") == "admitted"}
                     | {r["record_id"] for r in recov if r.get("gate") == "admitted"})
    pool -= admitted_ids

    targets_by_id = {r["record_id"]: r for r in uncovered}
    fig_by_id = {r["record_id"]: r for r in figure_sources}
    draw_by_id = {r["record_id"]: r for r in draw_task_map}

    recurring_digests = compute_recurring_template_digests()
    print(f"recurring template-asset digests (>= {RECURRING_TEMPLATE_LESSON_THRESHOLD} "
          f"distinct lessons): {len(recurring_digests)}")

    print(f"pool sizes: picture_routine={len(pr)} visual_general={len(vg)} "
          f"interpret_given={len(ig)} g8_excluded={len(g8_excluded)} "
          f"admitted_excluded={len(admitted_ids & (pr | vg | ig))} "
          f"final_pool={len(pool)}")

    doc_cache: dict[str, tuple[list[str], list[tuple], str, list[str], dict]] = {}
    rows_out = []
    scope_counts: dict[str, int] = {}
    no_target = 0

    for rid in sorted(pool):
        tgt = targets_by_id.get(rid)
        if tgt is None:
            no_target += 1
            continue
        lesson = tgt.get("lesson")
        doc_path = lesson_document_path(lesson)
        if doc_path is None or not doc_path.exists():
            rows_out.append({
                "record_id": rid, "lesson": lesson, "grade": tgt.get("grade"),
                "statement": tgt["statement"],
                "oracle_expected": tgt.get("oracle_expected"),
                "oracle_class": tgt.get("oracle_class"),
                "receipts": tgt.get("receipts"),
                "decline_class": (fig_by_id.get(rid) or {}).get("decline_class")
                    or ("interpret_given" if rid in ig else None),
                "targeting": {"scope": "no_document_md", "images": []},
                "images": [],
            })
            scope_counts["no_document_md"] = scope_counts.get("no_document_md", 0) + 1
            continue
        cache_key = str(doc_path)
        if cache_key not in doc_cache:
            raw = doc_path.read_text(encoding="utf-8", errors="ignore")
            lines = raw.splitlines()
            sections = header_sections(lines)
            joined, starts = normalized_line_index(lines)
            exclusion_index = build_exclusion_index(doc_path, lines, recurring_digests)
            doc_cache[cache_key] = (lines, sections, joined, starts, exclusion_index)
        lines, sections, joined, starts, exclusion_index = doc_cache[cache_key]

        anchor, method = locate_statement(tgt["statement"], joined, starts, sections)
        if anchor is None:
            anchor = len(lines) // 2
        anchor, method = relocate_to_task_section_if_admin(anchor, method, sections)
        images, scope, widen_trace, section_bounds = select_candidate_images(
            lines, sections, anchor, exclusion_index)
        scope_counts[scope] = scope_counts.get(scope, 0) + 1

        image_rows = []
        for im in images:
            desc = inline_description(lines, im["line"])
            image_rows.append({
                "path": str((doc_path.parent / im["ref"]).relative_to(REPO)),
                "source_ref": im["ref"],
                "doc_line": im["line"],
                "distance_from_anchor": abs(im["line"] - anchor),
                "inline_description": desc,
            })

        decline_class = (fig_by_id.get(rid) or {}).get("decline_class")
        if decline_class is None:
            decline_class = "interpret_given" if rid in ig else None
        reason = (fig_by_id.get(rid) or {}).get("reason")
        if reason is None:
            draw_row = draw_by_id.get(rid)
            reason = draw_row.get("missing_doing") if draw_row else None

        rows_out.append({
            "record_id": rid, "lesson": lesson, "grade": tgt.get("grade"),
            "statement": tgt["statement"],
            "oracle_expected": tgt.get("oracle_expected"),
            "oracle_class": tgt.get("oracle_class"),
            "receipts": tgt.get("receipts"),
            "decline_class": decline_class,
            "reason": reason,
            "targeting": {
                "anchor_line": anchor,
                "anchor_method": method,
                "scope": scope,
                "section_title": section_bounds[2],
                "widen_trace": widen_trace,
                "document_md": str(doc_path.relative_to(REPO)),
            },
            "images": image_rows,
        })

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        for r in rows_out:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")

    with_images = sum(1 for r in rows_out if r["images"])
    with_inline = sum(1 for r in rows_out
                       if any(im.get("inline_description") for im in r["images"]))
    print(f"wrote {len(rows_out)} rows -> {out_path}")
    print(f"scope distribution: {json.dumps(scope_counts, indent=1)}")
    print(f"rows with >=1 candidate image: {with_images}/{len(rows_out)}")
    print(f"rows with an inline 'Description of the Image' already on the page: {with_inline}")
    print(f"rows with no resolvable target statement: {no_target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
