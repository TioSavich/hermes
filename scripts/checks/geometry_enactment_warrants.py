#!/usr/bin/env python3
"""Check the geometry enactment lane against the guides and the action seam.

Three things can drift apart here and each has drifted somewhere in this
repository before:

  1. A warrant can cite a guide file and line that no longer say what the row
     claims. Every warrant is re-read from the guide at its cited line.
  2. The lane can cover a different set of lessons than the subclass holds. The
     lesson set is compared against
     data/learningcommons/derived/im_action_seam_recut.json.
  3. The emitted records can fall behind the module. Their count, fields and
     verdict vocabulary are checked here. The records themselves are written by
     curriculum/im/lesson_enactment.pl, which writes every lane's rows in one
     shape; the freshness of that file against a live run is checked by
     scripts/curriculum/build_im_lesson_enactment_census.py --check.

Exits nonzero and names the first failure.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LANE = ROOT / "curriculum/im/enactment/geometry_construction.pl"
SEAM = ROOT / "data/learningcommons/derived/im_action_seam_recut.json"
RECORDS = ROOT / "data/learningcommons/derived/lesson_enactments/geometry_construction_or_measure.jsonl"
SUBCLASS = "geometry_construction_or_measure"

ROW_RE = re.compile(
    r"lesson_enactment_form\('([^']+)',\s*(\w+),\s*\n\s*evidence\('([^']+)',\s*(\d+),\s*\n\s*\"([^\"]*)\"\)\)\.",
    re.MULTILINE,
)
FORM_RE = re.compile(
    r"enactment_form\((\w+),\s*\n\s*'([^']*)',\s*\n\s*warrant\('([^']+)',\s*'([^']+)',\s*(\d+),\s*\n\s*\"([^\"]*)\"\)\)\.",
    re.MULTILINE,
)
MOVE_RE = re.compile(r"enactment_move\((\w+),\s*(\d+),\s*(\w+)\)\.")

STOPWORDS = {
    "the", "a", "an", "and", "or", "of", "to", "in", "is", "are", "your",
    "you", "each", "that", "this", "with", "for", "it", "be", "on", "how",
    "what", "then", "1", "2", "3", "4", "5", "do", "will", "can", "if",
}


def fail(message: str) -> None:
    print(f"FAIL {message}")
    sys.exit(1)


def words(text: str) -> set[str]:
    return {w for w in re.findall(r"[a-z0-9]+", text.lower()) if w not in STOPWORDS}


def main() -> None:
    text = LANE.read_text()
    rows = ROW_RE.findall(text)
    if not rows:
        fail(f"{LANE} yielded no lesson_enactment_form rows; the reader and the file disagree")

    lessons = [r[0] for r in rows]
    if len(set(lessons)) != len(lessons):
        duplicates = {code for code in lessons if lessons.count(code) > 1}
        fail(f"duplicate lesson rows: {sorted(duplicates)}")

    seam = json.loads(SEAM.read_text())
    population = {
        entry["lesson"]
        for entry in seam["lessons"]
        if entry.get("task_209_subclass") == SUBCLASS
    }
    missing = population - set(lessons)
    extra = set(lessons) - population
    if missing:
        fail(f"{len(missing)} subclass lessons have no row: {sorted(missing)[:5]}")
    if extra:
        fail(f"{len(extra)} rows name lessons outside the subclass: {sorted(extra)[:5]}")

    seam_evidence = {
        entry["lesson"]: entry["task_209_evidence"]
        for entry in seam["lessons"]
        if entry.get("task_209_subclass") == SUBCLASS
    }

    for lesson, _form, source, line_text, span in rows:
        line = int(line_text)
        guide = ROOT / source
        if not guide.exists():
            fail(f"{lesson} cites {source}, which is not in the tree")

        evidence = seam_evidence[lesson]
        if evidence["source"] != source:
            fail(f"{lesson} cites {source}; the action seam cites {evidence['source']}")
        # The seam's line is the span that filed the lesson under the subclass.
        # A warrant may cite a different activity in the same lesson, because
        # the form can be exhibited by a span the classifier did not pick. The
        # file must agree; the line need not.

        guide_lines = guide.read_text(errors="replace").splitlines()
        if line > len(guide_lines):
            fail(f"{lesson} cites line {line} of a {len(guide_lines)}-line file")

        window = " ".join(guide_lines[max(0, line - 3): line + 40])
        span_words = words(span)
        found = span_words & words(window)
        if not span_words:
            fail(f"{lesson} carries an empty warrant span")
        share = len(found) / len(span_words)
        if share < 0.5:
            fail(
                f"{lesson} warrant span matches only {share:.0%} of the guide text "
                f"at {source}:{line}"
            )

    print(f"PASS {len(rows)} warrants re-read from the guides at their cited lines")
    print(f"PASS lesson set equals the {len(population)} lessons the action seam files under {SUBCLASS}")

    forms = FORM_RE.findall(text)
    declared = {f[0] for f in forms}
    used = {r[1] for r in rows}
    if used - declared:
        fail(f"lesson rows name forms with no enactment_form/3 row: {sorted(used - declared)}")
    if declared - used:
        fail(f"forms declared with no lesson exhibiting them: {sorted(declared - used)}")

    for form, gloss, lesson, source, line_text, span in forms:
        if lesson not in population:
            fail(f"form {form} cites {lesson}, which is outside the subclass")
        if not gloss.strip():
            fail(f"form {form} carries an empty gloss")
        guide = ROOT / source
        if not guide.exists():
            fail(f"form {form} cites {source}, which is not in the tree")
        guide_lines = guide.read_text(errors="replace").splitlines()
        line = int(line_text)
        window = " ".join(guide_lines[max(0, line - 3): line + 40])
        span_words = words(span)
        share = len(span_words & words(window)) / max(1, len(span_words))
        if share < 0.5:
            fail(f"form {form} warrant matches only {share:.0%} of {source}:{line}")
    print(f"PASS {len(forms)} form warrants re-read from the guides")

    moves = MOVE_RE.findall(text)
    by_form: dict[str, list[int]] = {}
    for form, index, _verb in moves:
        by_form.setdefault(form, []).append(int(index))
    for form in declared:
        indices = sorted(by_form.get(form, []))
        if indices != list(range(1, len(indices) + 1)) or not indices:
            fail(f"form {form} has moves indexed {indices}; they must run 1..n")
    print(f"PASS {len(moves)} moves indexed contiguously across {len(declared)} forms")

    if not RECORDS.exists():
        fail(
            f"{RECORDS} is missing; run "
            "scripts/curriculum/build_im_lesson_enactment_census.py"
        )

    records = [json.loads(l) for l in RECORDS.read_text().splitlines() if l.strip()]
    if len(records) != len(rows):
        fail(f"{len(records)} emitted records against {len(rows)} lesson rows")

    required = {
        "lesson", "grade", "subclass", "form", "form_gloss", "warrant", "inputs",
        "input_provenance", "steps", "artifact", "verdict",
        "what_it_does_not_claim", "provenance",
    }
    for record in records:
        gap = required - set(record)
        if gap:
            fail(f"{record.get('lesson')} record is missing {sorted(gap)}")
        if record["input_provenance"] not in (
            "curriculum", "curriculum_sample", "machine_supplied"
        ):
            fail(f"{record['lesson']} carries input_provenance {record['input_provenance']!r}")
        if not record["what_it_does_not_claim"].strip():
            fail(f"{record['lesson']} carries an empty what_it_does_not_claim")
        verdict = record["verdict"]
        if verdict != "well_formed" and not verdict.startswith(("partial:", "refused:")):
            fail(f"{record['lesson']} carries verdict {verdict!r}")
        if not record["steps"]:
            fail(f"{record['lesson']} emitted no steps")

    declared_moves = {(form, int(index), verb) for form, index, verb in moves}
    checked = 0
    for record in records:
        for step in record["steps"]:
            key = (record["form"], step["index"], step["verb"])
            if key not in declared_moves:
                fail(
                    f"{record['lesson']} step {step['index']} runs {step['verb']!r}, "
                    f"which no enactment_move declares for {record['form']} at that index"
                )
            checked += 1
    print(f"PASS {checked} emitted step verbs are declared moves at their own index")

    supplied = sum(1 for r in records if r["input_provenance"] == "machine_supplied")
    printed = len(records) - supplied
    well_formed = sum(1 for r in records if r["verdict"] == "well_formed")
    print(
        f"PASS {len(records)} records: {printed} on inputs the guide prints, "
        f"{supplied} on inputs the machine supplies, {well_formed} well formed"
    )


if __name__ == "__main__":
    main()
