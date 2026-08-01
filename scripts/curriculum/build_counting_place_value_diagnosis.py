#!/usr/bin/env python3
"""Join the action-seam re-cut, the enactment rows, and the lane's refusals.

One row per lesson in task 209's `counting_place_value_or_comparison`
subclass, carrying the diagnosis this lane was asked for: whether the lesson
was misclassified, whether the automaton is narrower than its name, or whether
the join between lesson and automaton was missing. Every field is read from a
file the repository already produces, so no row rests on a reading nobody can
check.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import subprocess
import sys
from typing import NoReturn


ROOT = Path(__file__).resolve().parents[2]
RECUT = ROOT / "data/learningcommons/derived/im_action_seam_recut.json"
ENACTMENTS = ROOT / (
    "data/learningcommons/derived/lesson_enactments/"
    "counting_place_value_or_comparison.jsonl"
)
LANE_MODULE = ROOT / "curriculum/im/enactment/counting_place_value.pl"
# Beside the census rather than inside the emission directory.  The emission
# directory holds exactly the rows the enactors wrote, and the census check
# refuses anything there that no lane produced.
OUTPUT = ROOT / (
    "data/learningcommons/derived/im_counting_place_value_diagnosis.json"
)
SUBCLASS = "counting_place_value_or_comparison"
EXPECTED = 36

# The named commit this wave started from, not HEAD.  Reading HEAD makes the
# before/after columns collapse the moment the wave is committed: the baseline
# becomes the new re-cut, every lesson reads as unchanged, and the --check that
# guards this file then fails on every later run for a reason that has nothing
# to do with the machines.
BASELINE_COMMIT = "b9a851c"

REFUSAL = re.compile(
    r"enactment_refusal\(\s*'([^']+)'\s*,\s*\n?\s*\"((?:\\.|[^\"])*)\"\s*\)\.",
    re.MULTILINE,
)


def fail(message: str) -> NoReturn:
    raise SystemExit(f"build_counting_place_value_diagnosis.py: {message}")


def refusals() -> dict[str, str]:
    text = LANE_MODULE.read_text(encoding="utf-8")
    rows = {}
    for lesson, sentence in REFUSAL.findall(text):
        rows[lesson] = re.sub(r"\\\s*\n\s*", "", sentence)
    return rows


def enactment_rows() -> dict[str, list[dict]]:
    """Every emitted row, grouped by lesson.

    A list, not one row per lesson: two lessons carry two forms each, and
    keying by lesson alone would drop one of the two silently.
    """
    if not ENACTMENTS.exists():
        fail(f"missing enactment rows at {ENACTMENTS}")
    rows: dict[str, list[dict]] = {}
    for line in ENACTMENTS.read_text(encoding="utf-8").splitlines():
        if line.strip():
            row = json.loads(line)
            rows.setdefault(row["lesson"], []).append(row)
    return rows


def build() -> dict:
    recut = json.loads(RECUT.read_text(encoding="utf-8"))
    baseline_text = subprocess.run(
        ["git", "show", f"{BASELINE_COMMIT}:{RECUT.relative_to(ROOT)}"],
        cwd=ROOT, text=True, capture_output=True, check=False,
    )
    baseline = {}
    if baseline_text.returncode == 0:
        baseline = {
            row["lesson"]: row
            for row in json.loads(baseline_text.stdout)["lessons"]
        }

    enacted = enactment_rows()
    refused = refusals()
    rows = []
    for lesson_row in recut["lessons"]:
        if lesson_row["task_209_subclass"] != SUBCLASS:
            continue
        lesson = lesson_row["lesson"]
        was = baseline.get(lesson, {}).get("action_class")
        now = lesson_row["action_class"]
        attempts_before = len(baseline.get(lesson, {}).get("candidate_attempts", []))
        enactment = enacted.get(lesson) or None
        if enactment is not None:
            outcome = "enacted_by_a_new_form"
            diagnosis = "no_automaton_computes_this_doing"
        elif was != now and now == "enacted_with_lesson_inputs":
            outcome = "wired_to_a_registered_automaton"
            diagnosis = "missing_join"
        elif now == "enacted_with_lesson_inputs":
            outcome = "already_wired_before_this_wave"
            diagnosis = "join_present"
        elif lesson in refused:
            outcome = "refused"
            diagnosis = "no_reader_for_the_printed_figure_or_supplied_material"
        else:
            outcome = "untouched"
            diagnosis = "unclassified"
        rows.append(
            {
                "lesson": lesson,
                "grade": lesson_row["grade"],
                "action_class_before": was,
                "action_class_after": now,
                "candidate_attempts_before": attempts_before,
                "candidate_attempts_after": len(lesson_row["candidate_attempts"]),
                "outcome": outcome,
                "diagnosis": diagnosis,
                "enactment_forms": [row["form"] for row in (enactment or [])],
                "enactment_verdicts": [
                    row["verdict"] for row in (enactment or [])
                ],
                "wired_kind": (
                    "{operation}/{kind}".format(**lesson_row["enactment"])
                    if lesson_row.get("enactment") else None
                ),
                "machine_a_refusal_would_need": refused.get(lesson),
                "evidence_source": lesson_row["task_209_evidence"]["source"],
                "evidence_line": lesson_row["task_209_evidence"]["line"],
            }
        )
    if len(rows) != EXPECTED:
        fail(f"expected {EXPECTED} subclass rows, found {len(rows)}")
    counts: dict[str, int] = {}
    for row in rows:
        counts[row["outcome"]] = counts.get(row["outcome"], 0) + 1
    return {
        "schema": "counting_place_value_diagnosis_v1",
        "generated_by": "scripts/curriculum/build_counting_place_value_diagnosis.py",
        "subclass": SUBCLASS,
        "population": len(rows),
        "outcome_counts": dict(sorted(counts.items())),
        "reads": {
            "recut": str(RECUT.relative_to(ROOT)),
            "enactments": str(ENACTMENTS.relative_to(ROOT)),
            "lane_module": str(LANE_MODULE.relative_to(ROOT)),
            "baseline": (
                f"git show {BASELINE_COMMIT}:" + str(RECUT.relative_to(ROOT))
            ),
        },
        "lessons": sorted(rows, key=lambda row: row["lesson"]),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()
    payload = build()
    rendered = json.dumps(payload, indent=1, ensure_ascii=False, sort_keys=True) + "\n"
    if args.check:
        current = args.output.read_text(encoding="utf-8") if args.output.exists() else ""
        if current != rendered:
            print("stale counting/place-value diagnosis", file=sys.stderr)
            return 1
    else:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered, encoding="utf-8")
    print(
        "counting_place_value_diagnosis "
        + " ".join(f"{k}={v}" for k, v in payload["outcome_counts"].items())
        + f" total={payload['population']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
