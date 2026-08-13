#!/usr/bin/env python3
"""Run the read-only G5 two-round shadow beside a frozen floors transcript.

This runner measures sequential navigation without changing the one-round
instrument or its bars. It executes calls from at most two assistant responses.
If either response is already a reply, that reply ends the item unchanged. If
the second response calls tools, those calls are executed and one final response
is requested; tool calls in that final response are recorded but never executed.

The summary cross-tabs item outcomes from an existing ``measure_floors.py``
transcript against the shadow trace. It intentionally has no threshold table,
judge, or floor-verdict path.
"""

from __future__ import annotations

import argparse
import copy
import json
import os
import platform
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Sequence

if sys.platform == "darwin" and platform.machine() == "x86_64":
    os.execvp("arch", ["arch", "-arm64", sys.executable, *sys.argv])

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
for candidate in (str(REPO_ROOT), str(SCRIPT_DIR)):
    if candidate not in sys.path:
        sys.path.insert(0, candidate)

# G5 requires these mechanics to stay identical to the frozen instrument. They
# are imported rather than copied so transport, assistant echo, worker execution,
# reply scoring, probe reading, and backend identity remain one contract.
from measure_floors import (  # noqa: E402
    ARMS,
    DEFAULT_PROBE,
    ENDPOINT,
    MODEL,
    Attempt,
    assistant_echo,
    backend_fingerprint,
    chat,
    execute,
    openai_tools,
    rate,
    read_rows,
    score_reply,
)
from dataset import Call, Row  # noqa: E402
from hermes.mcp.server import HermesMCPServer  # noqa: E402


FLOOR_REQUEST_ERROR = (
    "shadow_scorer.py is read-only: it does not compute verdict floors or move bars; "
    "run measure_floors.py for the frozen one-round verdict"
)
CONTEXT_MODES = ("accumulating", "isolated")


@dataclass
class ShadowAttempt(Attempt):
    """An Attempt-compatible transcript with bounded round evidence."""

    rounds: int = 0
    round_records: list[dict[str, Any]] = field(default_factory=list)
    second_call_emission: bool = False
    second_call_attempts: int = 0
    second_call_hits: int = 0
    final_relay: bool | None = None
    final_grounded_reply: bool = False
    requested_operation_reached: bool | None = None
    final_call_emission: bool = False
    final_response: dict[str, Any] = field(default_factory=dict)
    one_round_verdict: dict[str, Any] = field(default_factory=dict)
    context: str = "accumulating"


def refuse_floor_requests(argv: Sequence[str]) -> None:
    """Reject every option spelling that asks this diagnostic to judge floors."""
    for token in argv:
        option = token.split("=", 1)[0]
        if option.startswith("--") and (
            "floor" in option or option in {"--judge", "--threshold", "--thresholds"}
        ):
            raise SystemExit(FLOOR_REQUEST_ERROR)


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    supplied = list(sys.argv[1:] if argv is None else argv)
    refuse_floor_requests(supplied)
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--probe", type=Path, default=DEFAULT_PROBE)
    parser.add_argument(
        "--one-round-transcript",
        type=Path,
        required=True,
        help="frozen measure_floors.py JSONL whose item outcomes form the cross-tab",
    )
    parser.add_argument(
        "--output",
        type=Path,
        help="destination directory; defaults beside the one-round transcript",
    )
    parser.add_argument("--model", default=MODEL)
    parser.add_argument("--arms", nargs="+", default=list(ARMS), choices=tuple(ARMS))
    parser.add_argument(
        "--limit", type=int, default=0, help="items per arm; 0 runs the whole probe"
    )
    parser.add_argument("--timeout", type=float, default=300.0)
    parser.add_argument("--endpoint", default=ENDPOINT)
    parser.add_argument("--backend", choices=("ollama", "openai"), default="ollama")
    parser.add_argument(
        "--label", default="", help="names this shadow run in the output files"
    )
    parser.add_argument(
        "--context",
        choices=CONTEXT_MODES,
        default="accumulating",
        help=(
            "message history for follow-up requests; isolated retains only the "
            "system prompt, original user turn, and executed tool results"
        ),
    )
    return parser.parse_args(supplied)


def parsed_arguments(call: dict[str, Any]) -> tuple[str, dict[str, Any]]:
    function = call.get("function") or {}
    name = function.get("name", "")
    arguments = function.get("arguments") or {}
    if isinstance(arguments, str):
        try:
            arguments = json.loads(arguments)
        except json.JSONDecodeError:
            arguments = {"__unparsed__": arguments}
    if not isinstance(arguments, dict):
        arguments = {"__unparsed__": arguments}
    return name, arguments


def execute_round(
    message: dict[str, Any],
    messages: list[dict[str, Any]],
    support: list[str],
    attempt: ShadowAttempt,
    server: HermesMCPServer,
    declarations: dict[str, dict[str, Any]],
    round_number: int,
) -> list[dict[str, Any]]:
    """Execute one emitted call block with measure_floors' worker machinery."""
    emitted = message.get("tool_calls") or []
    if not emitted:
        return []
    messages.append(assistant_echo(message))
    round_calls: list[dict[str, Any]] = []
    for emitted_call in emitted:
        name, arguments = parsed_arguments(emitted_call)
        attempt.formulation_attempts += 1
        if name not in declarations:
            executed = {
                "ok": False,
                "error": {
                    "type": "unknown_tool",
                    "message": f"{name} is not on the declared surface",
                },
            }
            response_class = "refusal"
        else:
            executed, response_class = execute(
                server,
                Call(
                    name=name,
                    arguments=dict(arguments),
                    response={},
                    response_class="result",
                ),
            )
        if response_class == "result":
            attempt.formulation_hits += 1
        call_record = {
            "round": round_number,
            "name": name,
            "arguments": arguments,
            "response_class": response_class,
            "response": executed,
        }
        attempt.calls.append(call_record)
        round_calls.append(call_record)
        payload = json.dumps(executed, ensure_ascii=False, sort_keys=True)
        support.append(payload)
        messages.append({"role": "tool", "name": name, "content": payload})
    return round_calls


def next_round_messages(
    initial_messages: list[dict[str, Any]],
    accumulated_messages: list[dict[str, Any]],
    context: str,
) -> list[dict[str, Any]]:
    """Select the history presented to the next assistant response.

    Accumulating mode deliberately returns the existing list object. That is
    the pre-E2 path: the assistant echo and tool results appended by
    ``execute_round`` remain in place without reconstruction. Isolated mode
    starts again from the system prompt and original user turn, then carries
    forward only executed tool results.
    """
    if context == "accumulating":
        return accumulated_messages
    if context != "isolated":
        raise ValueError(f"unknown context mode: {context}")
    return [
        *(copy.deepcopy(message) for message in initial_messages),
        *(
            copy.deepcopy(message)
            for message in accumulated_messages
            if message.get("role") == "tool"
        ),
    ]


def finish_attempt(
    attempt: ShadowAttempt,
    row: Row,
    support: list[str],
    final_message: dict[str, Any],
) -> ShadowAttempt:
    attempt.final_response = copy.deepcopy(final_message)
    attempt.reply = final_message.get("content") or ""
    attempt.final_call_emission = bool(final_message.get("tool_calls"))
    attempt.unsupported, attempt.states_limit = score_reply(
        attempt.reply, " ".join(support), row.row_class
    )
    attempt.final_relay = (
        bool(attempt.states_limit and not attempt.unsupported)
        if row.row_class == "D"
        else None
    )
    attempt.final_grounded_reply = bool(
        attempt.reply.strip() and attempt.calls and not attempt.unsupported
    )
    if row.calls:
        expected = row.calls[0].name
        attempt.requested_operation_reached = any(
            call["name"] == expected for call in attempt.calls
        )
    else:
        attempt.requested_operation_reached = None
    return attempt


def run_item(
    row: Row,
    arm: str,
    server: HermesMCPServer,
    declarations: dict[str, dict[str, Any]],
    model: str,
    timeout: float,
    endpoint: str = ENDPOINT,
    backend: str = "ollama",
    context: str = "accumulating",
) -> ShadowAttempt:
    """Allow at most two call-execution rounds, followed by one final reply."""
    menu = openai_tools(declarations[name] for name in row.menu)
    messages: list[dict[str, Any]] = [
        {"role": "system", "content": ARMS[arm]},
        {"role": "user", "content": row.user_turn},
    ]
    initial_messages = copy.deepcopy(messages)
    attempt = ShadowAttempt(
        item=row.id,
        row_class=row.row_class,
        cut=str(row.provenance.get("cut", row.row_class)),
        arm=arm,
        called=False,
        expected_tool=row.calls[0].name if row.calls else "",
        context=context,
    )
    support = [row.user_turn]

    first, latency, transport = chat(messages, menu, model, timeout, endpoint, backend)
    attempt.latency_s += latency
    attempt.transport = transport
    if transport != "ok":
        return attempt
    attempt.called = bool(first.get("tool_calls"))
    if not attempt.called:
        return finish_attempt(attempt, row, support, first)

    attempt.rounds = 1
    first_calls = execute_round(
        first, messages, support, attempt, server, declarations, round_number=1
    )
    attempt.round_records.append(
        {"round": 1, "assistant": copy.deepcopy(first), "calls": first_calls}
    )

    messages = next_round_messages(initial_messages, messages, context)
    second, latency, transport = chat(messages, menu, model, timeout, endpoint, backend)
    attempt.latency_s += latency
    if transport != "ok":
        attempt.transport = transport
        return attempt
    second_emitted = second.get("tool_calls") or []
    if not second_emitted:
        return finish_attempt(attempt, row, support, second)

    attempt.rounds = 2
    attempt.second_call_emission = True
    second_calls = execute_round(
        second, messages, support, attempt, server, declarations, round_number=2
    )
    attempt.second_call_attempts = len(second_calls)
    attempt.second_call_hits = sum(
        call["response_class"] == "result" for call in second_calls
    )
    attempt.round_records.append(
        {"round": 2, "assistant": copy.deepcopy(second), "calls": second_calls}
    )

    messages = next_round_messages(initial_messages, messages, context)
    final, latency, transport = chat(messages, menu, model, timeout, endpoint, backend)
    attempt.latency_s += latency
    if transport != "ok":
        attempt.transport = transport
        return attempt
    # This is the hard G5 ceiling: a third call block is evidence, never a third
    # execution round.
    return finish_attempt(attempt, row, support, final)


def load_one_round(path: Path) -> dict[tuple[str, str], Attempt]:
    """Read frozen Attempt records without importing any verdict-floor logic."""
    records: dict[tuple[str, str], Attempt] = {}
    field_names = set(Attempt.__dataclass_fields__)
    for line_number, line in enumerate(
        path.read_text(encoding="utf-8").splitlines(), start=1
    ):
        if not line.strip():
            continue
        body = json.loads(line)
        attempt = Attempt(**{name: body[name] for name in field_names if name in body})
        key = (attempt.item, attempt.arm)
        if key in records:
            raise ValueError(
                f"duplicate one-round record at {path}:{line_number}: {key}"
            )
        records[key] = attempt
    return records


def one_round_item_verdict(attempt: Attempt) -> dict[str, Any]:
    """Project the frozen scorer's item event, never its aggregate floor bar."""
    if attempt.transport != "ok":
        return {"metric": "transport", "pass": None}
    if attempt.cut in {"explicit", "implicit"}:
        return {"metric": "formulation_hit", "pass": attempt.formulation_hits > 0}
    if attempt.cut == "limit":
        return {
            "metric": "refusal_relay",
            "pass": bool(attempt.states_limit and not attempt.unsupported),
        }
    if attempt.cut == "no_call":
        return {"metric": "no_spurious_call", "pass": not attempt.called}
    if attempt.cut == "heldout":
        executable = any(
            call.get("response_class") == "result" for call in attempt.calls
        )
        return {"metric": "executability", "pass": executable}
    return {"metric": "unclassified", "pass": None}


def attach_one_round(
    attempts: list[ShadowAttempt], records: dict[tuple[str, str], Attempt]
) -> None:
    missing: list[str] = []
    for attempt in attempts:
        frozen = records.get((attempt.item, attempt.arm))
        if frozen is None:
            missing.append(f"{attempt.arm}:{attempt.item}")
            continue
        if frozen.cut != attempt.cut or frozen.row_class != attempt.row_class:
            raise ValueError(
                f"one-round record shape differs for {attempt.arm}:{attempt.item}: "
                f"{frozen.cut}/{frozen.row_class} != {attempt.cut}/{attempt.row_class}"
            )
        attempt.one_round_verdict = one_round_item_verdict(frozen)
    if missing:
        examples = ", ".join(missing[:5])
        raise ValueError(
            f"one-round transcript lacks {len(missing)} shadow items: {examples}"
        )


def shadow_metrics(rows: list[ShadowAttempt]) -> dict[str, Any]:
    second_attempts = sum(row.second_call_attempts for row in rows)
    second_hits = sum(row.second_call_hits for row in rows)
    relay_rows = [row for row in rows if row.row_class == "D"]
    groundable_rows = [row for row in rows if row.expected_tool]
    return {
        "second_call_emission": {
            **rate(sum(row.second_call_emission for row in rows), len(rows)),
            "unit": "items",
        },
        "second_call_executability": {
            **rate(second_hits, second_attempts),
            "unit": "emitted second-round calls",
        },
        "final_relay": {
            **rate(sum(row.final_relay is True for row in relay_rows), len(relay_rows)),
            "unit": "limit items",
        },
        "final_grounded_reply": {
            **rate(
                sum(row.final_grounded_reply for row in groundable_rows),
                len(groundable_rows),
            ),
            "unit": "probe items with a requested operation",
        },
    }


def summarize_cut(
    rows: list[ShadowAttempt], cut: str, context: str = "accumulating"
) -> dict[str, Any]:
    selected = [row for row in rows if row.cut == cut and row.transport == "ok"]
    cells: dict[str, Any] = {}
    for label, outcome in (("pass", True), ("fail", False), ("unknown", None)):
        cell_rows = [
            row for row in selected if row.one_round_verdict.get("pass") is outcome
        ]
        cells[label] = {"items": len(cell_rows), **shadow_metrics(cell_rows)}

    one_round_misses = [
        row for row in selected if row.one_round_verdict.get("pass") is False
    ]
    one_round_hits = [
        row for row in selected if row.one_round_verdict.get("pass") is True
    ]
    mid_navigation = [
        row
        for row in one_round_misses
        if row.row_class == "D" and row.second_call_emission and row.final_relay is True
    ]
    discovery_only = [
        row
        for row in one_round_hits
        if cut in {"explicit", "implicit"} and row.requested_operation_reached is False
    ]
    metric_names = sorted(
        {row.one_round_verdict.get("metric", "unknown") for row in selected}
    )
    return {
        "cut": cut,
        "context": context,
        "items": len(selected),
        **shadow_metrics(selected),
        "cross_tab": {
            "context": context,
            "one_round_item_metric": metric_names[0]
            if len(metric_names) == 1
            else metric_names,
            "note": "item outcomes only; no floor threshold or aggregate verdict is computed",
            "by_one_round_verdict": cells,
            "mid_navigation_truncation_to_correct_final_relay": {
                **rate(len(mid_navigation), len(one_round_misses)),
                "unit": "one-round item misses",
                "items": [row.item for row in mid_navigation],
            },
            "discovery_only_formulation_hit_without_requested_operation": {
                **rate(len(discovery_only), len(one_round_hits)),
                "unit": "one-round item hits",
                "items": [row.item for row in discovery_only],
            },
        },
    }


def summarize(
    attempts: list[ShadowAttempt], arm: str, context: str = "accumulating"
) -> dict[str, Any]:
    rows = [attempt for attempt in attempts if attempt.arm == arm]
    return {
        "arm": arm,
        "context": context,
        "report_kind": "G5 two-round shadow; diagnostic only",
        "bars_moved": False,
        "items": sum(row.transport == "ok" for row in rows),
        "cuts": {
            cut: summarize_cut(rows, cut, context)
            for cut in sorted({attempt.cut for attempt in rows})
        },
        "transport_failures": sum(row.transport != "ok" for row in rows),
    }


def main(argv: Sequence[str] | None = None) -> int:
    arguments = parse_args(argv)
    rows = read_rows(arguments.probe)
    if arguments.limit:
        rows = rows[: arguments.limit]
    frozen = load_one_round(arguments.one_round_transcript)
    fingerprint = (
        backend_fingerprint(arguments.model)
        if arguments.backend == "ollama"
        else {
            "model": arguments.model,
            "endpoint": arguments.endpoint,
            "backend": "llama-server",
            "pinned": False,
            "note": "served from a local GGUF; the file path is the pin",
        }
    )
    print(json.dumps(fingerprint), flush=True)

    server = HermesMCPServer("core", REPO_ROOT)
    declarations = {tool["name"]: tool for tool in server._public_tools}
    attempts: list[ShadowAttempt] = []
    try:
        for arm in arguments.arms:
            started = time.time()
            for index, row in enumerate(rows, start=1):
                attempt = run_item(
                    row,
                    arm,
                    server,
                    declarations,
                    arguments.model,
                    arguments.timeout,
                    arguments.endpoint,
                    arguments.backend,
                    arguments.context,
                )
                attempts.append(attempt)
                print(
                    f"{arm:9s} {index:3d}/{len(rows)} {row.id:18s} "
                    f"cut={attempt.cut} rounds={attempt.rounds} "
                    f"second={attempt.second_call_emission} final={bool(attempt.reply.strip())} "
                    f"{attempt.latency_s:5.1f}s",
                    flush=True,
                )
            print(f"{arm} finished in {time.time() - started:.0f}s", flush=True)
    finally:
        server.close()

    attach_one_round(attempts, frozen)
    destination = arguments.output or arguments.one_round_transcript.parent
    destination.mkdir(parents=True, exist_ok=True)
    stamp = (arguments.label + "-" if arguments.label else "") + time.strftime(
        "%Y%m%dT%H%M%S"
    )
    transcript = destination / f"shadow-{stamp}.jsonl"
    with transcript.open("w", encoding="utf-8") as handle:
        for attempt in attempts:
            handle.write(json.dumps(attempt.to_dict(), ensure_ascii=False) + "\n")
    summary = {
        "report_kind": "G5 two-round shadow; diagnostic only",
        "bars_moved": False,
        "verdict_floors_computed": False,
        "model": arguments.model,
        "probe": str(arguments.probe),
        "one_round_transcript": str(arguments.one_round_transcript),
        "items_per_arm": len(rows),
        "transcript": str(transcript),
        "backend": fingerprint,
        "context": arguments.context,
        "arms": [summarize(attempts, arm, arguments.context) for arm in arguments.arms],
    }
    summary_path = destination / f"shadow-{stamp}.json"
    summary_path.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
