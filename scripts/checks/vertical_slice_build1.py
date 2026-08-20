#!/usr/bin/env python3
"""Integrated, socket-free acceptance check for vertical slice build 1."""
from __future__ import annotations

import sys
import subprocess
from dataclasses import replace
from pathlib import Path
from types import SimpleNamespace
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from hermes.app.routes import monitoring  # noqa: E402
from hermes.app.worker import PersistentPrologWorker  # noqa: E402
from hermes.mcp.server import HermesMCPServer  # noqa: E402
from scripts.research import extract_lesson_context  # noqa: E402


LESSON = "IM-G1-U3-L17"
TASK = "add-8-6"


class RouteProbe:
    def __init__(self, worker: PersistentPrologWorker, payload: dict[str, Any]) -> None:
        self.payload = payload
        self.repo_root = ROOT
        self.worker_request = worker.request
        self.services = SimpleNamespace()
        self.response: dict[str, Any] | None = None

    def _send_json(self, payload: dict[str, Any], *, status: int = 200) -> None:
        self.response = {"status": status, "payload": payload}


def protected_snapshot() -> dict[str, tuple[int, int]]:
    roots = [ROOT / "data", ROOT / "curriculum", ROOT / "hermes" / "app" / "runtime"]
    snapshot: dict[str, tuple[int, int]] = {}
    for root in roots:
        if not root.exists():
            continue
        for path in root.rglob("*"):
            if path.is_file():
                stat = path.stat()
                snapshot[str(path.relative_to(ROOT))] = (stat.st_size, stat.st_mtime_ns)
    return snapshot


def worker_result(worker: PersistentPrologWorker, answer: Any) -> dict[str, Any]:
    response = worker.raw_request({
        "id": f"fixture-{answer}",
        "op": "lesson_arithmetic_demonstration",
        "lesson": LESSON,
        "task_id": TASK,
        "observed_answer": answer,
        "work_transcription": "request-local fixture text",
    })
    assert response["ok"] is True, response
    return response["result"]


def check_worker_fixtures(worker: PersistentPrologWorker) -> None:
    productive = worker_result(worker, 14)
    assert productive["reading"]["status"] == "productive_trace"
    assert productive["productive_trace"]["result"] == 14

    misconception = worker_result(worker, 10)
    assert misconception["reading"]["status"] == "candidate_deformation"
    assert misconception["incorrect_trace"]["result"] == 10
    assert misconception["reading"]["human_endorsement_required"] is True

    nonsense = worker_result(worker, 999)
    assert nonsense["reading"]["status"] == "abstention"
    assert nonsense["reading"]["reason"] == "no_licensed_trace_matches"

    refused = worker_result(worker, "ten")
    assert refused["status"] == "refused"
    assert refused["reading"]["reason"] == "invalid_observed_answer"

    rung = worker.raw_request({
        "id": "fixture-rung",
        "op": "lesson_enactment_run",
        "lesson": LESSON,
    })
    assert rung["ok"] is False
    assert rung["error"]["type"] == "no_lesson_enactment"


def four_component_receipt(questions: list[dict[str, Any]]) -> int:
    purposes = {question.get("purpose") for question in questions}
    return 4 if {"assessing", "advancing"} <= purposes else 3


def check_guide_question_payload(worker: PersistentPrologWorker) -> None:
    response = worker.raw_request({
        "id": "fixture-guide-questions",
        "op": "monitoring_chart_export",
        "lesson_code": LESSON,
    })
    assert response["ok"] is True, response
    result = response["result"]
    questions = result.get("guide_questions", [])
    assert len(questions) == 4
    assert {question["purpose"] for question in questions} == {"assessing", "advancing"}
    assert "culled_by_reviewer" not in str(result)
    assert all(question["review_status"] == "approved" for question in questions)
    by_purpose = {
        purpose: [q for q in questions if q["purpose"] == purpose]
        for purpose in ("assessing", "advancing")
    }
    assert all(q["label_origin"] == "author_heading" for q in by_purpose["assessing"])
    assert all(
        q["label_origin"] == "human_classification"
        and (q.get("review_evidence") or {}).get("reviewer")
        for q in by_purpose["advancing"]
    )
    assert all("im_teacher_guides" in question["source_guide"] for question in questions)
    assert "pending_human_review" not in str(result)
    assert four_component_receipt(questions) == 4


def check_guide_question_source_contract() -> None:
    records = list(extract_lesson_context.validated_guide_questions())
    assert len(records) == 5
    advancing = [q for q in records if q.purpose == "advancing"]
    assert len(advancing) == 3
    assert all(q.review_status == "approved" and q.reviewer for q in advancing)
    culled = [q for q in records if q.review_status == "culled_by_reviewer"]
    assert len(culled) == 1
    assert culled[0].reviewer and "culled" in culled[0].reviewer

    cluster_source = replace(
        records[0],
        source="curriculum/im/generated/field_context_cache.json",
    )
    try:
        extract_lesson_context.validate_guide_question(cluster_source)
    except ValueError:
        pass
    else:
        raise AssertionError("research-cluster source was accepted as a guide source")

    false_heading = replace(records[0], author_heading="Assessing Student Thinking")
    try:
        extract_lesson_context.validate_guide_question(false_heading)
    except ValueError:
        pass
    else:
        raise AssertionError("absent author heading was accepted")

    synthetic = replace(
        advancing[0],
        review_status="approved",
        reviewer="synthetic acceptance fixture",
    )
    extract_lesson_context.validate_guide_question(synthetic)


def check_synthetic_approved_receipt() -> None:
    goal = (
        "use_module(im_lessons(lesson_monitoring)),"
        "assertz(compiled_lesson_context:compiled_lesson_guide_question("
        "'IM-G1-U3-L17',guide_question(advancing,\"Synthetic reviewed fixture\","
        "source_guide('curriculum/im_teacher_guides/grade1/unit3/lesson17.md'),"
        "source_span(249,253),activity_location(\"Synthetic fixture\"),"
        "label_origin(human_classification),review_status(approved),"
        "review_evidence(human_review(\"synthetic acceptance fixture\"))))),"
        "lesson_monitoring:lesson_guide_context_dict('IM-G1-U3-L17',D),"
        "get_dict(guide_questions,D,Qs),"
        "findall(P,(member(Q,Qs),get_dict(purpose,Q,P)),Ps),"
        "sort(Ps,[advancing,assessing])"
    )
    completed = subprocess.run(
        ["swipl", "-q", "-l", "paths.pl", "-g", goal, "-t", "halt"],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    assert completed.returncode == 0, completed.stderr or completed.stdout


def check_route_and_visuals(worker: PersistentPrologWorker) -> None:
    before = protected_snapshot()
    probe = RouteProbe(worker, {
        "lesson": LESSON,
        "task_id": TASK,
        "observed_answer": 10,
        "work_transcription": "I moved two to the eight and stopped.",
    })
    monitoring.lesson_arithmetic_demonstration(probe)
    after = protected_snapshot()
    assert before == after, "student-work request changed a protected repository file"
    assert probe.response is not None
    assert probe.response["status"] == 200
    envelope = probe.response["payload"]
    assert envelope["ok"] is True
    result = envelope["result"]
    assert "I moved two" not in str(result)
    visual = result["visual_pair"]
    assert visual["task_id"] == TASK
    assert visual["correct"]["request"]["a"] == 8
    assert visual["correct"]["request"]["b"] == 6
    assert len(visual["correct"]["doc"]["frames"]) == 3
    assert len(visual["incorrect"]["doc"]["frames"]) == 3
    assert visual["synchronization"] == {
        "mode": "shared_step_index",
        "correct_frame_count": 3,
        "incorrect_frame_count": 3,
        "shared_step_count": 3,
        "first_divergent_step": 3,
    }
    assert visual["proof"]["interpretive_residue"]["status"] == "human_endorsement_required"

    privacy = RouteProbe(worker, {
        "lesson": LESSON,
        "task_id": TASK,
        "observed_answer": 10,
        "student_name": "refused",
    })
    monitoring.lesson_arithmetic_demonstration(privacy)
    assert privacy.response is not None
    assert privacy.response["status"] == 400
    assert privacy.response["payload"]["error_type"] == "student_data_field_refused"


def check_mcp(worker: PersistentPrologWorker) -> None:
    server = HermesMCPServer("core", ROOT)
    server.worker = worker
    try:
        schema = next(
            tool for tool in server._public_tools
            if tool["name"] == "lesson_arithmetic_demonstration"
        )["inputSchema"]
        assert schema["required"] == ["lesson"]
        assert schema["properties"]["observed_answer"]["type"] == "integer"
        result = server.call("lesson_arithmetic_demonstration", {
            "lesson": LESSON,
            "task_id": TASK,
            "observed_answer": 10,
            "work_transcription": "request-local MCP fixture",
        })
        assert result["reading"]["status"] == "candidate_deformation"
        assert "request-local MCP fixture" not in str(result)
    finally:
        server.worker = None


def check_page_contract() -> None:
    page = (ROOT / "hermes" / "web" / "monitoring_chart.html").read_text(encoding="utf-8")
    drawer = (ROOT / "hermes" / "web" / "render" / "drawer.js").read_text(encoding="utf-8")
    required = (
        "id='lesson-arithmetic-demonstration'",
        "id='student-work-task'",
        "id='student-work-answer'",
        "id='student-work-transcription'",
        "/api/lesson_arithmetic_demonstration",
        "student-work-productive-stage",
        "student-work-incorrect-stage",
        "student-work-guide-questions",
        "renderGuideQuestionCards",
        "guide_questions",
        "setDemoStep",
        "questions.hidden = active",
        # The Tomorrow card carried the old chart.lesson_code guard; after its
        # removal (2026-08-19) the demonstration lesson's reviewed-guide-question
        # preference lives in the strategy-question renderer.
        "code !== DEMONSTRATION_LESSON || guideAssess.length",
    )
    for token in required:
        assert token in page, token
    for persistence_api in ("localStorage", "sessionStorage", "indexedDB"):
        assert persistence_api not in page
    assert "createDetached" in drawer
    assert "opts.isolated" in drawer
    demo_markup = page.split("id='lesson-arithmetic-demonstration'", 1)[1].split("</section>", 1)[0]
    assert "Guide questions for the trace comparison" in demo_markup
    assert "Trace-match status is reported separately" in demo_markup
    assert "not yet" not in demo_markup.casefold()
    result_renderer = page.split("function renderDemonstrationResult", 1)[1].split(
        "function populateDemonstrationTasks", 1
    )[0]
    assert "student-work-guide-questions" not in result_renderer


def main() -> int:
    worker = PersistentPrologWorker(umedcta_root=ROOT, timeout=120.0)
    try:
        check_worker_fixtures(worker)
        check_guide_question_payload(worker)
        check_route_and_visuals(worker)
        check_mcp(worker)
        check_guide_question_source_contract()
        check_synthetic_approved_receipt()
        check_page_contract()
    finally:
        worker.close()
    print("vertical slice build 1: approved guide questions carry the live 4/4 receipt PASS")
    print("vertical slice build 1: synthetic approved advancing fixture asserts the 4/4 receipt PASS")
    print("vertical slice build 1: worker fixtures, transient route, paired scenes, MCP, guide questions, and page contract PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
