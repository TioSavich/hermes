#!/usr/bin/env python3
"""Focused mock-transport contracts for the G5 two-round shadow scorer."""

from __future__ import annotations

import copy
import json
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
    context: str = "accumulating",
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
            context=context,
        )
    finally:
        shadow_scorer.chat = original_chat
    return attempt, calls


def dry_run_message_shapes() -> list[dict[str, Any]]:
    """Construct both E2 follow-up shapes for five frozen probe items."""
    rows = shadow_scorer.read_rows(shadow_scorer.DEFAULT_PROBE)[:5]
    assert len(rows) == 5
    evidence: list[dict[str, Any]] = []
    for row in rows:
        initial = [
            {"role": "system", "content": shadow_scorer.ARMS["offered"]},
            {"role": "user", "content": row.user_turn},
        ]
        expected_call = row.calls[0]
        settled_marker = f"SETTLED_ROUND_1_REPLY::{row.id}"
        first = {
            "content": settled_marker,
            "tool_calls": [emitted(expected_call.name, expected_call.arguments)],
        }
        tool_result = {
            "role": "tool",
            "name": expected_call.name,
            "content": json.dumps(
                expected_call.response, ensure_ascii=False, sort_keys=True
            ),
        }

        # This is the exact pre-E2 construction performed by execute_round.
        legacy = copy.deepcopy(initial)
        legacy.append(shadow_scorer.assistant_echo(first))
        legacy.append(tool_result)
        legacy_bytes = json.dumps(
            legacy, ensure_ascii=False, separators=(",", ":")
        ).encode("utf-8")

        accumulating = shadow_scorer.next_round_messages(
            initial, legacy, "accumulating"
        )
        accumulating_bytes = json.dumps(
            accumulating, ensure_ascii=False, separators=(",", ":")
        ).encode("utf-8")
        isolated = shadow_scorer.next_round_messages(initial, legacy, "isolated")
        isolated_text = json.dumps(isolated, ensure_ascii=False, sort_keys=True)
        accumulating_text = json.dumps(accumulating, ensure_ascii=False, sort_keys=True)

        record = {
            "item": row.id,
            "accumulating_roles": [message["role"] for message in accumulating],
            "isolated_roles": [message["role"] for message in isolated],
            "settled_reply_in_accumulating": settled_marker in accumulating_text,
            "settled_reply_in_isolated": settled_marker in isolated_text,
            "tool_result_in_isolated": tool_result in isolated,
            "accumulating_byte_identical": accumulating_bytes == legacy_bytes,
            "accumulating_same_list": accumulating is legacy,
        }
        assert record == {
            "item": row.id,
            "accumulating_roles": ["system", "user", "assistant", "tool"],
            "isolated_roles": ["system", "user", "tool"],
            "settled_reply_in_accumulating": True,
            "settled_reply_in_isolated": False,
            "tool_result_in_isolated": True,
            "accumulating_byte_identical": True,
            "accumulating_same_list": True,
        }
        evidence.append(record)
    return evidence


def no_network_request_boundary(
    row: Row, declarations: dict[str, Any]
) -> list[dict[str, Any]]:
    """Drive isolated mode to its second request without opening a socket."""
    requests: list[list[dict[str, Any]]] = []

    def boundary_chat(
        messages: list[dict[str, Any]],
        tools: list[dict[str, Any]],
        model: str,
        timeout: float,
        endpoint: str = shadow_scorer.ENDPOINT,
        backend: str = "ollama",
    ) -> tuple[dict[str, Any], float, str]:
        del tools, model, timeout, endpoint, backend
        requests.append(copy.deepcopy(messages))
        if len(requests) == 1:
            expected = row.calls[0]
            return (
                {
                    "content": f"SETTLED_ROUND_1_REPLY::{row.id}",
                    "tool_calls": [emitted(expected.name, expected.arguments)],
                },
                0.0,
                "ok",
            )
        return {}, 0.0, "request_boundary"

    server = FakeServer()
    original_chat = shadow_scorer.chat
    shadow_scorer.chat = boundary_chat
    try:
        attempt = shadow_scorer.run_item(
            row,
            "offered",
            server,  # type: ignore[arg-type]
            declarations,
            "test-model",
            1.0,
            backend="openai",
            context="isolated",
        )
    finally:
        shadow_scorer.chat = original_chat
    assert attempt.transport == "request_boundary"
    assert len(requests) == 2
    return requests[1]


def main() -> int:
    assert shadow_scorer.chat is measure_floors.chat
    assert shadow_scorer.execute is measure_floors.execute
    assert shadow_scorer.backend_fingerprint is measure_floors.backend_fingerprint
    assert shadow_scorer.read_rows is measure_floors.read_rows
    assert not hasattr(shadow_scorer, "THRESHOLDS")
    assert not hasattr(shadow_scorer, "judge")
    assert (
        shadow_scorer.parse_args(["--one-round-transcript", "frozen.jsonl"]).context
        == "accumulating"
    )
    assert (
        shadow_scorer.parse_args(
            ["--one-round-transcript", "frozen.jsonl", "--context", "isolated"]
        ).context
        == "isolated"
    )

    shapes = dry_run_message_shapes()
    for shape in shapes:
        print("DRY_RUN_MESSAGE_SHAPE " + json.dumps(shape, sort_keys=True))

    declarations = {
        name: tool(name)
        for name in (
            "requested_tool",
            "fallback_lookup",
            "list_strategies",
            "strategy_trace",
        )
    }

    boundary_row = shadow_scorer.read_rows(shadow_scorer.DEFAULT_PROBE)[0]
    boundary_declarations = {name: tool(name) for name in boundary_row.menu}
    boundary = no_network_request_boundary(boundary_row, boundary_declarations)
    assert [message["role"] for message in boundary] == ["system", "user", "tool"]
    assert "SETTLED_ROUND_1_REPLY" not in json.dumps(boundary)
    print(
        "NO_NETWORK_REQUEST_BOUNDARY "
        + json.dumps(
            {
                "item": boundary_row.id,
                "context": "isolated",
                "roles": [message["role"] for message in boundary],
                "settled_reply_absent": True,
            },
            sort_keys=True,
        )
    )

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
    assert arm_summary["context"] == "accumulating"
    assert "verdicts" not in arm_summary
    isolated_summary = shadow_scorer.summarize(attempts, "offered", "isolated")
    assert isolated_summary["context"] == "isolated"
    for cut in ("implicit", "limit"):
        assert set(arm_summary["cuts"][cut]) == set(isolated_summary["cuts"][cut])
        assert isolated_summary["cuts"][cut]["context"] == "isolated"
        assert isolated_summary["cuts"][cut]["cross_tab"]["context"] == "isolated"

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
