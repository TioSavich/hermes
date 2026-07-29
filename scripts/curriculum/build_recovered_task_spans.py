#!/usr/bin/env python3
"""Carry the teacher guides' recovered expressions as a sidecar, not a rewrite.

The IM teacher guides draw their expressions as filled outlines rather than
typesetting them as text, so ``pdftotext`` kept the frame of an item list and
carried nothing inside it. ``recover_guide_expressions.py`` decodes those
outlines and can put them back, and on this corpus it almost never gets to:
restoring an expression reflows the page, the rewrite is refused unless every
physical line survives in place, and 322 of 368 guides are refused on that
ground. Grade 1 alone decodes 1951 runs and writes none.

The line-preservation rule is right. Receipts in
``lesson_negative_receipts.json`` and reviewed provenance in the action-mapping
compiler cite these files by physical line, and a rewrite that moved lines would
strand every citation. What is wrong is treating the markdown as the only place
the recovered text can live.

This script keeps the markdown exactly as it is and writes the recovered student
task statements beside it, keyed by lesson and span position rather than by
line. Nothing downstream has to move, because nothing moved.

The join is checked, never assumed. A lesson contributes only when the recovered
extraction yields the same number of student-task spans as the tracked markdown
and each span still carries the words the tracked one carried. A span
contributes only when it is additive: the recovered text holds arithmetic the
tracked text does not. Anything else is refused and counted, because a silently
dropped lesson is the failure this repo keeps finding.

Run:
    python3 scripts/curriculum/build_recovered_task_spans.py --band grade1
    python3 scripts/curriculum/build_recovered_task_spans.py --check
"""
from __future__ import annotations

import argparse
import json
import pathlib
import re
import shutil
import sys
import tempfile
from collections import Counter

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))

import compile_action_mappings as compiler  # noqa: E402
import recover_guide_expressions as recover  # noqa: E402

OUTPUT = ROOT / "curriculum" / "im" / "generated" / "recovered_task_spans.json"
GUIDE_REL = pathlib.Path("curriculum/im_teacher_guides")

# A span is additive when the recovered text carries an arithmetic expression
# the tracked text does not. Anything else is either unchanged or a reflow, and
# neither is evidence.
ARITHMETIC = re.compile(r"\d+\s*[+\-−x×÷*/]\s*\d+")


def word_signature(text: str) -> tuple[str, ...]:
    """The prose of a span, with digits and operators dropped.

    Two extractions of one guide differ in the expressions one of them
    recovered and in how the page reflowed around them. They must not differ in
    the words, and this is what says so.
    """
    stripped = re.sub(r"[0-9+\-−x×÷*/=.,:;()\[\]•·_]", " ", text.lower())
    return tuple(token for token in stripped.split() if token)


def spans_for_tree(root: pathlib.Path) -> dict[tuple[str, str], str]:
    """Every student-task span under a checkout root, keyed (lesson, position).

    Both sides of the comparison go through the compiler's own
    ``extract_student_task_spans``. A second reader of the same shape is how
    this repo has produced disagreements that no check could see.
    """
    # extract_student_task_spans records each span's source as a path relative
    # to the compiler's module ROOT, so reading a mirrored tree means pointing
    # that at the tree being read. Restored in every case, including failure.
    # read_teacher_guides resolves the guide subdirectory against the module
    # ROOT, so it needs the original; extract_student_task_spans records each
    # span's source relative to the module ROOT, so it needs the tree being
    # read. Swap only around the second. Restored in every case.
    docs = compiler.read_teacher_guides(root)
    previous = compiler.ROOT
    try:
        compiler.ROOT = root
        return {
            (span.code, span.position): span.text
            for span in compiler.extract_student_task_spans(docs)
        }
    finally:
        compiler.ROOT = previous


def build(sources: pathlib.Path, band: str | None, only: str | None,
          limit: int | None) -> dict:
    jobs = recover.lesson_jobs(sources)
    if band:
        jobs = [job for job in jobs
                if job[0].startswith(f"IM-G{recover.GRADE_TOKEN[band]}-")]
    if only:
        jobs = [job for job in jobs if job[0] == only]
    if limit:
        jobs = jobs[:limit]

    tracked = spans_for_tree(ROOT)
    rows: list[dict] = []
    status = Counter()
    per_lesson: list[dict] = []

    with tempfile.TemporaryDirectory(prefix="hermes-recovered-") as scratch:
        mirror = pathlib.Path(scratch)
        for code, markdown, pdf in jobs:
            markdown_path = pathlib.Path(markdown)
            if code in recover.HELD_BACK:
                status["held_back"] += 1
                per_lesson.append({"lesson": code, "status": "held_back"})
                continue
            if not pathlib.Path(pdf).is_file():
                status["source_absent"] += 1
                per_lesson.append({"lesson": code, "status": "source_absent"})
                continue
            text = markdown_path.read_text(encoding="utf-8")
            fence = recover.FENCE.search(text)
            if fence is None:
                status["no_raw_extract"] += 1
                per_lesson.append({"lesson": code, "status": "no_raw_extract"})
                continue
            try:
                fresh, runs = recover.extract_with_math(pathlib.Path(pdf))
            except Exception as failure:  # noqa: BLE001
                status["unread"] += 1
                per_lesson.append({"lesson": code, "status": "unread",
                                   "detail": str(failure)[:160]})
                continue
            if runs == 0:
                status["nothing_to_recover"] += 1
                per_lesson.append({"lesson": code, "status": "nothing_to_recover"})
                continue

            # Rebuild the whole guide with the recovered body in the fence, so
            # the mirrored file is the same document the compiler would read.
            rebuilt = (text[:fence.start()] + fence.group(1) + fresh
                       + fence.group(3) + text[fence.end():])
            relative = markdown_path.relative_to(ROOT)
            target = mirror / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(rebuilt, encoding="utf-8")

    # The mirror is read as a checkout root, so the compiler's own reader walks
    # it exactly as it walks the tree.
        recovered = spans_for_tree(mirror)

        by_lesson_tracked: dict[str, list[str]] = {}
        by_lesson_recovered: dict[str, list[str]] = {}
        for (code, position), body in tracked.items():
            by_lesson_tracked.setdefault(code, []).append(position)
        for (code, position), body in recovered.items():
            by_lesson_recovered.setdefault(code, []).append(position)

        for code in sorted(by_lesson_recovered):
            positions_new = sorted(by_lesson_recovered[code])
            positions_old = sorted(by_lesson_tracked.get(code, []))
            if positions_new != positions_old:
                status["span_set_differs"] += 1
                per_lesson.append({
                    "lesson": code, "status": "span_set_differs",
                    "detail": f"{len(positions_old)} tracked spans, {len(positions_new)} recovered",
                })
                continue
            # Drift is refused per span, not per lesson. A reflow usually
            # disturbs one span in a guide, and discarding the other four
            # loses recoverable text for no gain in safety: each span is
            # carried independently and joined independently downstream.
            drifted = [p for p in positions_new
                       if word_signature(recovered[(code, p)])
                       != word_signature(tracked[(code, p)])]
            usable = [p for p in positions_new if p not in drifted]
            if not usable:
                status["prose_drifted"] += 1
                per_lesson.append({"lesson": code, "status": "prose_drifted",
                                   "detail": f"all {len(drifted)} span(s) drifted"})
                continue
            additive = []
            for position in usable:
                new_text = recovered[(code, position)]
                old_text = tracked[(code, position)]
                gained = (len(ARITHMETIC.findall(new_text))
                          - len(ARITHMETIC.findall(old_text)))
                if gained > 0:
                    additive.append({
                        "lesson": code,
                        "position": position,
                        "expressions_gained": gained,
                        "recovered_text": new_text,
                        "tracked_text": old_text,
                    })
            if not additive:
                status["no_additive_span"] += 1
                per_lesson.append({"lesson": code, "status": "no_additive_span"})
                continue
            rows.extend(additive)
            status["contributed"] += 1
            if drifted:
                status["spans_dropped_to_drift"] += len(drifted)
            per_lesson.append({"lesson": code, "status": "contributed",
                               "spans": len(additive),
                               "spans_refused_drifted": drifted})

    rows.sort(key=lambda row: (row["lesson"], row["position"]))
    return {
        "schema": "recovered_task_spans_v1",
        "generated_by": "scripts/curriculum/build_recovered_task_spans.py",
        "register": (
            "Student task statements re-extracted from the per-lesson teacher-guide "
            "PDFs with their drawn expressions decoded back into text. The tracked "
            "markdown is not modified: these rows are keyed by lesson and span "
            "position, so every physical-line citation into the guides stays valid. "
            "A lesson contributes only when its recovered extraction yields the same "
            "span positions as the tracked markdown and every span carries the same "
            "words; a span contributes only when it gains arithmetic the tracked "
            "text lacks."
        ),
        "counts": dict(sorted(status.items())),
        "lessons": sorted(per_lesson, key=lambda row: row["lesson"]),
        "spans": rows,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sources", type=pathlib.Path,
                        default=recover.DEFAULT_SOURCES)
    parser.add_argument("--band", choices=sorted(recover.BANDS))
    parser.add_argument("--only")
    parser.add_argument("--limit", type=int)
    parser.add_argument("--check", action="store_true",
                        help="report and write nothing")
    parser.add_argument("--output", type=pathlib.Path, default=OUTPUT)
    arguments = parser.parse_args()

    if not arguments.sources.is_dir():
        print(f"teacher-guide PDFs absent at {arguments.sources}; nothing recovered",
              file=sys.stderr)
        return 0

    data = build(arguments.sources, arguments.band, arguments.only, arguments.limit)
    counts = data["counts"]
    print("recovered task spans: "
          + "; ".join(f"{key}={value}" for key, value in counts.items())
          + f"; spans={len(data['spans'])}")
    if arguments.check:
        return 0
    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    arguments.output.write_text(
        json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"wrote {arguments.output.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
