#!/usr/bin/env python3
"""Focused source, checkpoint, schema, and load checks for Grade 8 extraction."""

from __future__ import annotations

from collections import Counter
import json
from pathlib import Path
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.curriculum import build_im_defragged_task_instances as defrag  # noqa: E402
from scripts.counts_baseline_lib import baseline_value  # noqa: E402
from scripts.curriculum import compile_action_mappings as compiler  # noqa: E402
from scripts.curriculum import extract_docling_grade as extraction  # noqa: E402
from scripts.curriculum import recover_docling_grade8 as recovery  # noqa: E402
from scripts.curriculum import vision_statement_contract  # noqa: E402
from scripts.research import extract_lesson_context as context  # noqa: E402


CHECKPOINT_DIR = recovery.DEFAULT_RECOVERY_DIR
TASK_OUTPUT = extraction.GENERATED / "grade_8_extracted_task_instances.pl"
QUESTION_OUTPUT = extraction.GENERATED / "grade_8_extracted_guide_questions.pl"
SUMMARY_OUTPUT = recovery.DEFAULT_RECOVERY_DIR / "summary.json"
VISION_DIR = recovery.DEFAULT_RECOVERY_DIR / "vision"
EXPECTED_LESSONS = baseline_value("grade8.lessons")
EXPECTED_TASKS = baseline_value("grade8.task_sections")
EXPECTED_QUESTIONS = baseline_value("grade8.guide_questions")


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


def check_rule_fixtures() -> None:
    for text in (
        "Describe how the graph of is the same as the graph of .",
        "Triangle and triangle are similar .",
        "Let represent the number of pages.",
    ):
        assert extraction._missing_expression(text), text
    for text in (
        "What do you notice? What do you wonder?",
        "Draw a graph and label both axes.",
        "Find the value of 2x + 3 when x is 4.",
    ):
        assert not extraction._missing_expression(text), text


def load_payloads(docs: list[object]) -> list[dict]:
    payloads = []
    for doc in docs:
        base_path = extraction.checkpoint_path(recovery.BASE_CHECKPOINT_DIR, doc.code)
        base = extraction.compatible_checkpoint(base_path, doc)
        assert base is not None, f"missing or stale base checkpoint: {doc.code}"
        path = recovery.recovery_checkpoint_path(CHECKPOINT_DIR, doc.code)
        payload = recovery.compatible_recovery_checkpoint(path, base)
        assert payload is not None, f"missing or stale checkpoint: {doc.code}"
        payloads.append(payload)
    return payloads


def check_source_mapping(docs: list[object], payloads: list[dict]) -> None:
    docs_by_code = {doc.code: doc for doc in docs}
    vision_records = defrag.vision_recovery_records()
    total = 0
    blocked = Counter()
    for payload in payloads:
        doc = docs_by_code[payload["lesson"]]
        spans, _reason, markers = compiler._segment_docling_task_regions(doc)
        spans_by_position = {span.position: span for span in spans}
        assert markers == len(payload["tasks"])
        for task in payload["tasks"]:
            total += 1
            span = spans_by_position.get(task["position"])
            if task["extraction_status"] == "recovered":
                assert task["blocker"] == "none"
                if "recovery" in task:
                    recovered = task["recovery"]
                    assert recovered["method"] == "docling_json"
                    source = ROOT / recovered["source"]
                    document = json.loads(source.read_text(encoding="utf-8"))
                    heading = recovery._resolve_ref(document, recovered["heading_ref"])
                    assert heading["text"] == recovered["heading_raw"]
                    assert recovered["normalized_statement"] == task["excerpt"]
                    for item in recovered["items"]:
                        referenced = recovery._resolve_ref(document, item["ref"])
                        assert referenced["text"] == item["raw"]
                        raw = source.read_bytes()[item["byte_start"] : item["byte_end"]]
                        assert json.loads(b'"' + raw + b'"') == item["raw"]
                        assert (
                            recovery.normalize_item(item["kind"], item["raw"])
                            == item["normalized"]
                        )
                        assert (
                            recovery.normalize_item(item["kind"], item["normalized"])
                            == item["normalized"]
                        )
                else:
                    vision = task["vision_recovery"]
                    assert vision["model"] == "gemma-4-31B-it"
                    provenance_class = (
                        vision_statement_contract.recovery_provenance_class(vision)
                    )
                    if (
                        provenance_class
                        == vision_statement_contract.WIDENED_CHECKPOINT_CLASS
                    ):
                        assert vision["call_id"].startswith("g8vw_")
                        record = vision_records[(payload["lesson"], task["position"])]
                        receipt = vision_statement_contract.widened_statement_receipt(
                            task["excerpt"], vision, record["checkpoints"]
                        )
                        assert receipt["prompt_version"] == vision["prompt_version"]
                    else:
                        assert (
                            provenance_class
                            == vision_statement_contract.NARROW_DESCRIPTION_CLASS
                        )
                        assert vision["call_id"].startswith("g8v_")
                continue
            if span is None:
                assert task["extraction_status"].startswith("blocked_")
                assert task["blocker"] != "none"
            else:
                assert defrag.norm(task["excerpt"]) == defrag.norm(span.text)
                mapping = defrag.map_guide_statement(
                    task["excerpt"], span, task["line_start"], task["line_end"]
                )
                assert mapping.statement == defrag.norm(task["excerpt"])
                assert mapping.tokens
            if task["extraction_status"] == "complete":
                assert task["blocker"] == "none"
                assert not extraction._missing_expression(task["excerpt"])
            else:
                blocked[task["blocker"]] += 1
                if task["extraction_status"] == "blocked_missing_visual":
                    assert task["visual_provenance"]
    assert total == EXPECTED_TASKS, total
    assert blocked == Counter(
        {
            "curriculum_text_absent_after_docling": 4,
            "expression_missing_from_markdown": 115,
            "expression_missing_without_visual": 70,
            "task_section_contains_no_curriculum_text": 3,
        }
    ), blocked


def check_questions(payloads: list[dict]) -> None:
    records = []
    for payload in payloads:
        questions = [context.GuideQuestion(**row) for row in payload["guide_questions"]]
        assert Counter(question.purpose for question in questions) == {
            "assessing": 1,
            "advancing": 1,
        }
        for question in questions:
            context.validate_guide_question(question)
            assert question.label_origin == "machine_classification"
            assert question.review_status == "pending_human_review"
            assert question.reviewer is None
        records.extend(questions)
    assert len(records) == EXPECTED_QUESTIONS


def check_generated_outputs(payloads: list[dict]) -> None:
    assert TASK_OUTPUT.read_text(encoding="utf-8") == extraction.render_tasks(
        8, payloads
    )
    assert QUESTION_OUTPUT.read_text(encoding="utf-8") == extraction.render_questions(
        8, payloads, context
    )
    summary = json.loads(SUMMARY_OUTPUT.read_text(encoding="utf-8"))
    assert summary["lessons"] == EXPECTED_LESSONS
    assert summary["tasks"] == EXPECTED_TASKS
    assert summary["after_status_counts"] == {
        "blocked_layout": 73,
        "blocked_missing_visual": 119,
        "complete": 287,
        "recovered": 34,
    }
    assert summary["provider_calls"] == {"REALLMS_gemma_4_31B_it": 3}


def check_vision_accounting(payloads: list[dict]) -> None:
    worklist = json.loads((VISION_DIR / "worklist.json").read_text(encoding="utf-8"))
    assert worklist["model"] == "gemma-4-31B-it"
    assert worklist["max_tokens"] >= 2500
    assert len(worklist["rows"]) == 1
    checkpoints = [
        json.loads(path.read_text(encoding="utf-8"))
        for path in sorted((VISION_DIR / "checkpoints").glob("*.json"))
    ]
    assert len(checkpoints) == 1
    checkpoint = checkpoints[0]
    assert checkpoint["attempts"] == 1
    assert checkpoint["outcome"] == "ok"
    assert checkpoint["accepted"] is True
    assert checkpoint["statement"], "accepted recovery must carry its statement"
    calls = [call for payload in payloads for call in payload.get("model_calls", [])]
    assert sum(call["attempts"] for call in calls) == 3 <= 300
    assert all(call["model"] == "gemma-4-31B-it" for call in calls)


def check_prolog_loads() -> None:
    prolog(
        "use_module(curriculum/im/generated/grade_8_extracted_task_instances,[]),"
        f"grade_8_extracted_task_instances:extracted_task_instance_summary({EXPECTED_LESSONS},"
        "counts{blocked_layout:73,blocked_missing_visual:119,complete:287,recovered:34}),"
        "aggregate_all(count,grade_8_extracted_task_instances:"
        f"extracted_lesson_task_instance(_,_,_),{EXPECTED_TASKS})"
    )
    prolog(
        "use_module(curriculum/im/generated/grade_8_extracted_guide_questions,[]),"
        f"grade_8_extracted_guide_questions:extracted_guide_question_summary({EXPECTED_LESSONS},"
        f"counts{{advancing:{EXPECTED_LESSONS},assessing:{EXPECTED_LESSONS}}}),"
        "aggregate_all(count,grade_8_extracted_guide_questions:"
        "extracted_lesson_guide_question(_,guide_question(_,_,_,_,_,"
        "label_origin(machine_classification),review_status(pending_human_review),"
        f"review_evidence(none))),{EXPECTED_QUESTIONS})"
    )
    prolog(
        "use_module(curriculum/im/generated/compiled_defragged_task_instances,[]),"
        f"compiled_defragged_task_instances:defragged_task_instance_summary("
        f"{baseline_value('defrag.rows')},"
        f"counts{{already_complete:3417,blocked_layout:385,"
        f"blocked_missing_visual:{baseline_value('defrag.visual_markers')},"
        "recovered:1295,recovered_with_referent:3}),"
        "aggregate_all(count,(compiled_defragged_task_instances:"
        "defragged_task_instance(_,L,curriculum_task(_),D),"
        f"sub_atom(L,0,5,_,'IM-G8'),get_dict(status,D,_)),{EXPECTED_TASKS})"
    )
    # The 268 G8 machine-classified rows admitted under printed_region when
    # the positional-serving ruling landed (2026-08-20); the source store
    # above is unchanged.
    prolog(
        "use_module(curriculum/im/generated/compiled_lesson_context,[]),"
        "aggregate_all(count,(compiled_lesson_context:compiled_lesson_guide_question(L,"
        "guide_question(_,_,_,_,_,label_origin(machine_classification),"
        "review_status(mechanically_admitted),_)),"
        f"sub_atom(L,0,5,_,'IM-G8')),{EXPECTED_QUESTIONS})"
    )
    prolog(
        "use_module(curriculum/im/generated/compiled_lesson_context,[]),"
        "aggregate_all(count,(compiled_lesson_context:compiled_lesson_guide_question(L,"
        "guide_question(_,_,_,_,_,_,review_status(pending_human_review),_)),"
        "sub_atom(L,0,5,_,'IM-G8')),0)"
    )
    prolog(
        "use_module(curriculum/im/generated/grade_8_extracted_task_instances,[]),"
        "use_module(im_lessons(lesson_monitoring),[]),"
        "setof(L,T^E^(grade_8_extracted_task_instances:"
        f"extracted_lesson_task_instance(L,T,E)),Ls),length(Ls,{EXPECTED_LESSONS}),"
        "forall(member(L,Ls),(lesson_monitoring:monitoring_chart(L,_),"
        "compiled_lesson_context:compiled_lesson_context(L,_,_,_),"
        "aggregate_all(count,compiled_lesson_context:"
        "compiled_lesson_guide_question(L,_),2)))"
    )


def main() -> int:
    check_rule_fixtures()
    docs = extraction.discover_docs(8, compiler)
    assert len(docs) == EXPECTED_LESSONS
    assert len({doc.code for doc in docs}) == EXPECTED_LESSONS
    payloads = load_payloads(docs)
    check_source_mapping(docs, payloads)
    check_questions(payloads)
    check_generated_outputs(payloads)
    check_vision_accounting(payloads)
    check_prolog_loads()
    print(
        f"PASS Grade 8 extraction recovery: {EXPECTED_LESSONS} lessons, "
        f"{EXPECTED_TASKS} task sections, "
        "11 JSON recoveries, 23 vision recoveries, 192 named blockers, "
        "clean Prolog loads"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
