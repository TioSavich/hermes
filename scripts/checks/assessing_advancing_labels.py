#!/usr/bin/env python3
"""Check the assessing/advancing teacher-question label store.

Pins: the source row count, the per-label counts, the per-region_type
disposition census, the label_origin split within advancing (rule-licensed
machine_classification vs. the one author_heading region_type), that the
generated .pl is byte-identical to a fresh render (determinism), that it
loads clean in SWI-Prolog, and that every labeled row's span lies inside
its source file and reproduces its text -- reading the span as a UTF-8
character offset, not a raw byte offset (see the builder's docstring for
why).

Runs from scripts/checks/run_all.sh (an explicit list; a check absent from
it never runs).
"""
from __future__ import annotations

from collections import Counter
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.questions import build_assessing_advancing_labels as builder  # noqa: E402
from scripts.curriculum import structure_to_task_rows as anchoring  # noqa: E402

EXPECTED_TOTAL_ROWS = 11202
EXPECTED_LABELED = 9246
EXPECTED_ASSESSING = 2606
EXPECTED_ADVANCING = 6640
EXPECTED_EXCLUDED = 1956
EXPECTED_LESSONS_COVERED = 877
EXPECTED_REGION_TYPE_COUNT = 27

# Rule-licensed advancing rows (activity_synthesis + lesson_synthesis) vs.
# the one author-heading-origin region_type, kept separate so a check
# failure names which warrant moved.
EXPECTED_ADVANCING_MACHINE_CLASSIFICATION = 5542
EXPECTED_ADVANCING_AUTHOR_HEADING = 1098
assert (
    EXPECTED_ADVANCING_MACHINE_CLASSIFICATION + EXPECTED_ADVANCING_AUTHOR_HEADING
    == EXPECTED_ADVANCING
)

# region_type -> (disposition, count), pinned so a change in either input
# store shows up as a named diff instead of a moved aggregate.
EXPECTED_DISPOSITION = {
    "MLR2 Collect and Display": ("excluded", 2),
    "MLR7 Compare and Connect": ("excluded", 1),
    "MLR8 Discussion Supports": ("excluded", 6),
    "access_disabilities": ("excluded", 29),
    "access_english_language_learners": ("excluded", 1),
    "access_english_learners": ("excluded", 132),
    "access_for_english_language_learners": ("excluded", 2),
    "access_for_students_with_disabilities": ("excluded", 1),
    "activity": ("excluded", 1496),
    "activity_narrative": ("assessing", 40),
    "activity_steps": ("excluded", 77),
    "activity_synthesis": ("advancing", 4019),
    # Controller ruling 2026-08-18: advancing_student_thinking is IM's own
    # published section title naming the questions' function directly, not
    # a resemblance to another region_type's name. Moved from excluded to
    # advancing, label_origin(author_heading('Advancing Student Thinking'))
    # rather than machine_classification -- see AUTHOR_HEADING_OVERRIDES in
    # the builder.
    "advancing_student_thinking": ("advancing", 1098),
    "display": ("excluded", 1),
    "instructional_routines": ("excluded", 3),
    "launch": ("assessing", 2557),
    "lesson_narrative": ("excluded", 15),
    "lesson_synthesis": ("advancing", 1523),
    "lesson_timeline": ("excluded", 1),
    "math_community": ("assessing", 6),
    "next_day_supports": ("excluded", 11),
    "responding_to_student_thinking": ("assessing", 3),
    "student_response": ("excluded", 15),
    "student_task_statement": ("excluded", 18),
    "suggested_centers": ("excluded", 3),
    "teacher_reflection_questions": ("excluded", 107),
    "warm_up": ("excluded", 35),
}


def prolog(goal: str) -> None:
    result = subprocess.run(
        ["swipl", "-q", "-l", "paths.pl", "-g", goal, "-t", "halt"],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    assert result.returncode == 0, result.stderr or result.stdout


def check_rebuild_matches_disk() -> tuple[list[dict], dict[str, tuple[str, int]], str]:
    rows = builder.load_rows(builder.SOURCE)
    assert len(rows) == EXPECTED_TOTAL_ROWS, len(rows)
    labeled_rows, census = builder.classify(rows)
    source_sha = builder.file_sha256(builder.SOURCE)
    rendered = builder.render(labeled_rows, census, source_sha, len(rows))
    on_disk = builder.OUTPUT.read_text(encoding="utf-8")
    assert on_disk == rendered, "generated artifact is stale; rerun the builder"
    # Rendering twice from the same inputs must be byte-identical (idempotency).
    assert rendered == builder.render(labeled_rows, census, source_sha, len(rows))
    return labeled_rows, census, source_sha


def check_counts(labeled_rows: list[dict], census: dict[str, tuple[str, int]]) -> None:
    assert len(labeled_rows) == EXPECTED_LABELED, len(labeled_rows)
    by_label = Counter(row["label"] for row in labeled_rows)
    assert by_label["assessing"] == EXPECTED_ASSESSING, by_label
    assert by_label["advancing"] == EXPECTED_ADVANCING, by_label
    assert by_label["assessing"] + by_label["advancing"] == EXPECTED_LABELED
    assert EXPECTED_TOTAL_ROWS - EXPECTED_LABELED == EXPECTED_EXCLUDED
    assert len({row["lesson"] for row in labeled_rows}) == EXPECTED_LESSONS_COVERED

    assert len(census) == EXPECTED_REGION_TYPE_COUNT, sorted(census)
    mismatches = {
        region_type: (census.get(region_type), EXPECTED_DISPOSITION.get(region_type))
        for region_type in set(census) | set(EXPECTED_DISPOSITION)
        if census.get(region_type) != EXPECTED_DISPOSITION.get(region_type)
    }
    assert not mismatches, mismatches
    assert sum(count for _disposition, count in census.values()) == EXPECTED_TOTAL_ROWS

    by_origin = Counter(row["label_origin"][0] for row in labeled_rows)
    assert by_origin["author_heading"] == EXPECTED_ADVANCING_AUTHOR_HEADING, by_origin
    assert (
        by_origin["machine_classification"]
        == EXPECTED_LABELED - EXPECTED_ADVANCING_AUTHOR_HEADING
    ), by_origin
    author_heading_rows = [
        row for row in labeled_rows if row["label_origin"][0] == "author_heading"
    ]
    assert all(row["region_type"] == "advancing_student_thinking" for row in author_heading_rows)
    assert all(row["label"] == "advancing" for row in author_heading_rows)
    assert all(
        row["label_origin"] == ("author_heading", "Advancing Student Thinking")
        for row in author_heading_rows
    )
    assert len(author_heading_rows) == EXPECTED_ADVANCING_AUTHOR_HEADING


def check_spans_and_source_sha(labeled_rows: list[dict]) -> None:
    """Every span lies inside its file and reproduces the row's text.

    Re-runs the exact anchoring function that built
    curriculum/im/generated/structure_teacher_questions.jsonl
    (scripts/curriculum/structure_to_task_rows.py `find_verbatim`) against
    each row's source file and text, and asserts it lands on the same
    (byte_start, byte_end) the row carries. That function reads spans as
    Python string (character) offsets, not raw bytes -- reproducing its
    exact matching rule, rather than a bounds check alone, is what confirms
    a span actually points at its row's text and not just at some in-range
    pair of numbers.
    """
    text_cache: dict[str, str] = {}
    sha_cache: dict[str, str] = {}
    for row in labeled_rows:
        path = row["path"]
        if path not in text_cache:
            full_path = ROOT / path
            assert full_path.exists(), path
            text_cache[path] = full_path.read_text(encoding="utf-8", errors="replace")
            sha_cache[path] = builder.file_sha256(full_path)
        text = text_cache[path]
        assert sha_cache[path] == row["file_sha256"], (
            path,
            "source file changed since the store was built",
        )
        assert 0 <= row["byte_start"] <= row["byte_end"] <= len(text), (
            row["lesson"],
            row["path"],
            row["byte_start"],
            row["byte_end"],
            len(text),
        )
        span = anchoring.find_verbatim(text, row["text"])
        assert span == (row["byte_start"], row["byte_end"]), (
            row["lesson"],
            row["path"],
            row["byte_start"],
            row["byte_end"],
            span,
            row["text"][:80],
        )


def check_prolog_loads() -> None:
    prolog(
        "use_module(curriculum/im/generated/structure_teacher_question_labels,[]),"
        "aggregate_all(count,structure_teacher_question_labels:teacher_question_label(_,_),"
        f"{EXPECTED_LABELED}),"
        "aggregate_all(count,structure_teacher_question_labels:"
        "teacher_question_label(_,labeled_question(assessing,_,_,_,_,_,"
        "label_origin(machine_classification),review_status(pending_human_review))),"
        f"{EXPECTED_ASSESSING}),"
        "aggregate_all(count,structure_teacher_question_labels:"
        "teacher_question_label(_,labeled_question(advancing,_,_,_,_,_,"
        "label_origin(machine_classification),review_status(pending_human_review))),"
        f"{EXPECTED_ADVANCING_MACHINE_CLASSIFICATION}),"
        "aggregate_all(count,structure_teacher_question_labels:"
        "teacher_question_label(_,labeled_question(advancing,_,"
        "region_type(advancing_student_thinking),_,_,_,"
        "label_origin(author_heading('Advancing Student Thinking')),"
        "review_status(pending_human_review))),"
        f"{EXPECTED_ADVANCING_AUTHOR_HEADING}),"
        "aggregate_all(count,structure_teacher_question_labels:"
        "teacher_question_label(_,labeled_question(advancing,_,_,_,_,_,"
        "label_origin(author_heading(_)),review_status(pending_human_review))),"
        f"{EXPECTED_ADVANCING_AUTHOR_HEADING}),"
        "aggregate_all(count,structure_teacher_question_labels:"
        "teacher_question_region_type_disposition(_,_,_),"
        f"{EXPECTED_REGION_TYPE_COUNT}),"
        "structure_teacher_question_labels:teacher_question_region_type_disposition("
        f"advancing_student_thinking,advancing,{EXPECTED_ADVANCING_AUTHOR_HEADING}),"
        "structure_teacher_question_labels:teacher_question_label_summary(S),"
        f"get_dict(source_rows,S,{EXPECTED_TOTAL_ROWS}),"
        f"get_dict(labeled_rows,S,{EXPECTED_LABELED}),"
        f"get_dict(assessing,S,{EXPECTED_ASSESSING}),"
        f"get_dict(advancing,S,{EXPECTED_ADVANCING}),"
        f"get_dict(excluded_rows,S,{EXPECTED_EXCLUDED})"
    )


def main() -> int:
    labeled_rows, census, _source_sha = check_rebuild_matches_disk()
    check_counts(labeled_rows, census)
    check_spans_and_source_sha(labeled_rows)
    check_prolog_loads()
    print(
        "PASS assessing/advancing teacher-question labels: "
        f"{EXPECTED_TOTAL_ROWS} source rows, {EXPECTED_LABELED} labeled "
        f"({EXPECTED_ASSESSING} assessing, {EXPECTED_ADVANCING} advancing -- "
        f"{EXPECTED_ADVANCING_MACHINE_CLASSIFICATION} machine_classification + "
        f"{EXPECTED_ADVANCING_AUTHOR_HEADING} author_heading), "
        f"{EXPECTED_EXCLUDED} excluded across {EXPECTED_REGION_TYPE_COUNT} "
        "region_type values, every span verified against its source file"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
