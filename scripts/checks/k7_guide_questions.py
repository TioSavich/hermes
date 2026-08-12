#!/usr/bin/env python3
"""Check deterministic K-7 guide-question extraction and compilation."""

from __future__ import annotations

from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.curriculum import extract_docling_grade as extraction  # noqa: E402
from scripts.research import extract_lesson_context as context  # noqa: E402


GRADE_COUNTS = {
    "k": 139,
    "1": 148,
    "2": 150,
    "3": 143,
    "4": 151,
    "5": 148,
    "6": 152,
    "7": 143,
}
L17_REVIEWED_BLOCK_SHA256 = (
    "850eee0c8dc82c25f4f8da0c1cc51931b2de82db76cab02452d13077a41d89c4"
)


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


def load_grade_payloads(grade: str) -> list[dict]:
    docs = extraction.discover_question_guides(grade)
    assert len(docs) == GRADE_COUNTS[grade]
    assert len({doc.code for doc in docs}) == len(docs)
    checkpoint_dir = extraction.DEFAULT_QUESTION_CHECKPOINT_ROOT / f"grade-{grade}"
    payloads = []
    for doc in docs:
        checkpoint = extraction.checkpoint_path(checkpoint_dir, doc.code)
        payload = extraction.compatible_checkpoint(checkpoint, doc)
        assert payload is not None, f"missing or stale checkpoint: {doc.code}"
        payloads.append(payload)
    return payloads


def check_source_spans(payloads: list[dict]) -> None:
    for payload in payloads:
        assert payload["model_calls"] == []
        questions = [context.GuideQuestion(**row) for row in payload["guide_questions"]]
        assert Counter(question.purpose for question in questions) == {
            "assessing": 1,
            "advancing": 1,
        }
        assert payload.get("guide_question_absences", []) == []
        for question in questions:
            context.validate_guide_question(question)
            assert question.label_origin == "machine_classification"
            assert question.review_status == "pending_human_review"
            assert question.reviewer is None
            source_lines = (ROOT / question.source).read_text(encoding="utf-8").split("\n")
            cited_lines = source_lines[question.line_start - 1 : question.line_end]
            assert context.cited_span_contains(question.text, cited_lines), (
                question.code,
                question.purpose,
                question.source,
                question.line_start,
            )


def check_grade_output(grade: str, payloads: list[dict]) -> None:
    output = extraction.GENERATED / f"grade_{grade}_extracted_guide_questions.pl"
    rendered = extraction.render_questions(grade, payloads, context)
    assert output.read_text(encoding="utf-8") == rendered
    assert rendered == extraction.render_questions(grade, payloads, context)
    summary_path = (
        extraction.DEFAULT_QUESTION_CHECKPOINT_ROOT / f"grade-{grade}" / "summary.json"
    )
    summary = json.loads(summary_path.read_text(encoding="utf-8"))
    assert summary["lessons"] == GRADE_COUNTS[grade]
    assert summary["guide_questions"] == 2 * GRADE_COUNTS[grade]
    assert summary["question_counts"] == {
        "advancing": GRADE_COUNTS[grade],
        "assessing": GRADE_COUNTS[grade],
    }
    assert summary["question_absence_counts"] == {}
    assert summary["lessons_with_two_questions"] == GRADE_COUNTS[grade]
    assert summary["llm_calls"] == {"Big_Red": 0, "REALLMS": 0}


def check_named_absence_fixture() -> None:
    payload = {
        "guide_questions": [],
        "guide_question_absences": [
            {
                "code": "IM-GK-U99-L99",
                "purpose": "assessing",
                "source": "fixture.md",
                "reason": "fewer_than_two_exact_guide_questions",
            }
        ],
    }
    rendered = extraction.render_questions("k", [payload], context)
    assert "extracted_guide_question_absence(" in rendered
    assert "missing_assessing:1" in rendered


def check_compiled_context() -> None:
    output = context.OUTPUT
    text = output.read_text(encoding="utf-8")
    rendered, _contexts, _absences, question_absences, _failures, _count = (
        context.compile_cache()
    )
    assert text == rendered
    assert question_absences == ()
    reviewed_blocks = "".join(
        re.findall(
            r"compiled_lesson_guide_question\(\n    'IM-G1-U3-L17',\n.*?\n\n",
            text,
            re.DOTALL,
        )[:5]
    )
    assert reviewed_blocks.count("compiled_lesson_guide_question(") == 5
    assert hashlib.sha256(reviewed_blocks.encode()).hexdigest() == L17_REVIEWED_BLOCK_SHA256


def check_prolog_loads() -> None:
    for grade, lesson_count in GRADE_COUNTS.items():
        module = f"grade_{grade}_extracted_guide_questions"
        path = f"curriculum/im/generated/{module}"
        prolog(
            f"use_module({path},[]),"
            f"{module}:extracted_guide_question_summary({lesson_count},"
            f"counts{{advancing:{lesson_count},assessing:{lesson_count}}}),"
            f"aggregate_all(count,{module}:extracted_lesson_guide_question(_,_),"
            f"{lesson_count * 2}),"
            f"\\+ {module}:extracted_guide_question_absence(_,_,_)"
        )
    prolog(
        "use_module(curriculum/im/generated/compiled_lesson_context,[]),"
        "aggregate_all(count,compiled_lesson_context:"
        "compiled_lesson_guide_question(_,guide_question(_,_,_,_,_,"
        "label_origin(machine_classification),review_status(pending_human_review),"
        "review_evidence(none))),2616),"
        "aggregate_all(count,compiled_lesson_context:"
        "compiled_lesson_guide_question(_,guide_question(_,_,_,_,_,_,"
        "review_status(pending_human_review),_)),2616),"
        "\\+ compiled_lesson_context:compiled_lesson_guide_question_absent(_,_,_)"
    )


def main() -> int:
    all_payloads = []
    for grade in GRADE_COUNTS:
        payloads = load_grade_payloads(grade)
        check_source_spans(payloads)
        check_grade_output(grade, payloads)
        all_payloads.extend(payloads)
    assert len(all_payloads) == 1174
    assert sum(len(payload["guide_questions"]) for payload in all_payloads) == 2348
    check_named_absence_fixture()
    check_compiled_context()
    check_prolog_loads()
    print(
        "PASS K-7 guide questions: 1174 lessons, 2348 exact pending records, "
        "zero absences, zero model calls, L17 reviewed bytes unchanged"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
