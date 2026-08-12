#!/usr/bin/env python3
"""Focused mock-transport contracts for the G5 two-round shadow scorer."""

from __future__ import annotations

import os
import platform
import sys
from pathlib import Path
from typing import Any

if sys.platform == "darwin" and platform.machine() == "x86_64":
    os.execvp("arch", ["arch", "-arm64", sys.executable, *sys.argv])

ROOT = Path(__file__).resolve().parents[2]
SIDEKICK = ROOT / "scripts" / "sidekick"
for candidate in (str(ROOT), str(SIDEKICK)):
    if candidate not in sys.path:
        sys.path.insert(0, candidate)

from dataset import Call, Row  # noqa: E402
import measure_floors  # noqa: E402
from measure_floors import Attempt  # noqa: E402
import shadow_scorer  # noqa: E402


def tool(name: str) -> dict[str, Any]:
    return {
        "name": name,
        "description": f"Synthetic declaration for {name}.",
        "inputSchema": {},
    }


def emitted(name: str, arguments: dict[str, Any] | None = None) -> dict[str, Any]:
    return {
        "id": f"call_{name}",
        "type": "function",
        "function": {"name": name, "arguments": arguments or {}},
    }


class FakeServer:
    def __init__(self) -> None:
        self.calls: list[str] = []

    def validate_arguments(self, name: str, arguments: dict[str, Any]) -> None:
        del name, arguments

    def call(self, name: str, arguments: dict[str, Any]) -> dict[str, Any]:
        del arguments
        self.calls.append(name)
        return {"available": True, "tool": name}


def scripted_run(
    row: Row,
    responses: list[dict[str, Any]],
    server: FakeServer,
    declarations: dict[str, Any],
) -> tuple[shadow_scorer.ShadowAttempt, int]:
    calls = 0

    def scripted_chat(
        messages: list[dict[str, Any]],
        tools: list[dict[str, Any]],
        model: str,
        timeout: float,
        endpoint: str = shadow_scorer.ENDPOINT,
        backend: str = "ollama",
    ) -> tuple[dict[str, Any], float, str]:
        nonlocal calls
        del messages, tools, model, timeout, endpoint, backend
        response = responses[calls]
        calls += 1
        return response, 0.0, "ok"

    original_chat = shadow_scorer.chat
    shadow_scorer.chat = scripted_chat
    try:
        attempt = shadow_scorer.run_item(
            row,
            "offered",
            server,  # type: ignore[arg-type]
            declarations,
            "test-model",
            1.0,
            backend="openai",
        )
    finally:
        shadow_scorer.chat = original_chat
    return attempt, calls


def main() -> int:
    assert shadow_scorer.chat is measure_floors.chat
    assert shadow_scorer.execute is measure_floors.execute
    assert shadow_scorer.backend_fingerprint is measure_floors.backend_fingerprint
    assert shadow_scorer.read_rows is measure_floors.read_rows
    assert not hasattr(shadow_scorer, "THRESHOLDS")
    assert not hasattr(shadow_scorer, "judge")

    declarations = {
        name: tool(name)
        for name in (
            "requested_tool",
            "fallback_lookup",
            "list_strategies",
            "strategy_trace",
        )
    }

    limit_row = Row(
        id="limit-two-round",
        row_class="D",
        menu=["requested_tool", "fallback_lookup"],
        user_turn="Run the requested operation that is absent from this fixture.",
        calls=[Call("requested_tool", {}, {}, "refusal")],
        reply="",
        provenance={"cut": "limit"},
    )
    limit_server = FakeServer()
    limit_attempt, limit_chat_calls = scripted_run(
        limit_row,
        [
            {"content": "", "tool_calls": [emitted("invented_tool")]},
            {"content": "", "tool_calls": [emitted("fallback_lookup")]},
            {
                "content": "No requested operation is available.",
                "tool_calls": [emitted("forbidden_third_round")],
            },
        ],
        limit_server,
        declarations,
    )
    assert limit_chat_calls == 3
    assert isinstance(limit_attempt, Attempt)
    assert limit_attempt.to_dict()["rounds"] == 2
    assert limit_attempt.rounds == 2
    assert limit_attempt.second_call_emission is True
    assert (limit_attempt.second_call_hits, limit_attempt.second_call_attempts) == (
        1,
        1,
    )
    assert limit_attempt.final_relay is True
    assert limit_attempt.final_grounded_reply is True
    assert limit_attempt.final_call_emission is True
    assert limit_attempt.final_response["tool_calls"][0]["function"]["name"] == (
        "forbidden_third_round"
    )
    assert limit_server.calls == ["fallback_lookup"], (
        "the final response's tool call escaped the two-execution-round ceiling"
    )

    discovery_row = Row(
        id="implicit-discovery-only",
        row_class="A",
        menu=["list_strategies", "strategy_trace"],
        user_turn="Find and run the relevant strategy.",
        calls=[Call("strategy_trace", {"strategy": "target"}, {}, "result")],
        reply="",
        provenance={"cut": "implicit"},
    )
    discovery_server = FakeServer()
    discovery_attempt, discovery_chat_calls = scripted_run(
        discovery_row,
        [
            {"content": "", "tool_calls": [emitted("list_strategies")]},
            {"content": "The requested trace was not run."},
        ],
        discovery_server,
        declarations,
    )
    assert discovery_chat_calls == 2
    assert discovery_attempt.rounds == 1
    assert discovery_attempt.second_call_emission is False
    assert discovery_attempt.reply == "The requested trace was not run."
    assert discovery_attempt.requested_operation_reached is False
    assert discovery_server.calls == ["list_strategies"]

    frozen_limit = Attempt(
        item=limit_row.id,
        row_class="D",
        cut="limit",
        arm="offered",
        called=True,
        calls=[
            {
                "name": "invented_tool",
                "arguments": {},
                "response_class": "refusal",
                "response": {"ok": False},
            }
        ],
        reply="",
        states_limit=False,
        formulation_attempts=1,
    )
    frozen_discovery = Attempt(
        item=discovery_row.id,
        row_class="A",
        cut="implicit",
        arm="offered",
        called=True,
        calls=[
            {
                "name": "list_strategies",
                "arguments": {},
                "response_class": "result",
                "response": {"ok": True},
            }
        ],
        reply="The requested trace was not run.",
        formulation_attempts=1,
        formulation_hits=1,
    )
    attempts = [limit_attempt, discovery_attempt]
    shadow_scorer.attach_one_round(
        attempts,
        {
            (frozen_limit.item, frozen_limit.arm): frozen_limit,
            (frozen_discovery.item, frozen_discovery.arm): frozen_discovery,
        },
    )

    limit = shadow_scorer.summarize_cut(attempts, "limit")
    assert limit["second_call_emission"]["counts"] == [1, 1]
    assert limit["second_call_executability"]["counts"] == [1, 1]
    assert limit["final_relay"]["counts"] == [1, 1]
    assert limit["final_grounded_reply"]["counts"] == [1, 1]
    recovered = limit["cross_tab"]["mid_navigation_truncation_to_correct_final_relay"]
    assert recovered["counts"] == [1, 1]
    assert recovered["items"] == [limit_row.id]

    implicit = shadow_scorer.summarize_cut(attempts, "implicit")
    discovery_only = implicit["cross_tab"][
        "discovery_only_formulation_hit_without_requested_operation"
    ]
    assert discovery_only["counts"] == [1, 1]
    assert discovery_only["items"] == [discovery_row.id]
    assert implicit["cross_tab"]["by_one_round_verdict"]["pass"]["items"] == 1
    arm_summary = shadow_scorer.summarize(attempts, "offered")
    assert arm_summary["bars_moved"] is False
    assert "verdicts" not in arm_summary

    try:
        shadow_scorer.refuse_floor_requests(["--compute-verdict-floors"])
    except SystemExit as failure:
        assert str(failure) == shadow_scorer.FLOOR_REQUEST_ERROR
    else:
        raise AssertionError("shadow scorer accepted a verdict-floor request")

    print(
        "PASS G5 shadow scorer: two execution rounds are capped; four metrics and both "
        "one-round cross-tab cases are reported; direct follow-up reply is unchanged; "
        "verdict-floor requests are refused"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
