#!/usr/bin/env python3
"""Integrated, socket-free acceptance check for vertical slice build 1."""
from __future__ import annotations

import sys
from pathlib import Path
from types import SimpleNamespace
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from hermes.app.routes import monitoring  # noqa: E402
from hermes.app.worker import PersistentPrologWorker  # noqa: E402
from hermes.mcp.server import HermesMCPServer  # noqa: E402


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
        "setDemoStep",
        "questions.hidden = active",
        "chart.lesson_code !== DEMONSTRATION_LESSON",
    )
    for token in required:
        assert token in page, token
    for persistence_api in ("localStorage", "sessionStorage", "indexedDB"):
        assert persistence_api not in page
    assert "createDetached" in drawer
    assert "opts.isolated" in drawer
    demo_markup = page.split("id='lesson-arithmetic-demonstration'", 1)[1].split("</section>", 1)[0]
    assert "question" not in demo_markup.casefold()
    assert "not yet" not in demo_markup.casefold()


def main() -> int:
    worker = PersistentPrologWorker(umedcta_root=ROOT, timeout=120.0)
    try:
        check_worker_fixtures(worker)
        check_route_and_visuals(worker)
        check_mcp(worker)
        check_page_contract()
    finally:
        worker.close()
    print("vertical slice build 1: worker fixtures, transient route, paired scenes, MCP, and page contract PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
