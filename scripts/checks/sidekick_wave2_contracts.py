#!/usr/bin/env python3
"""Focused checks for the wave 2 exact-mix and assertion contracts."""
from __future__ import annotations

import os
import platform
import sys
import json
from pathlib import Path
from typing import Any

if sys.platform == "darwin" and platform.machine() == "x86_64":
    os.execvp("arch", ["arch", "-arm64", sys.executable, *sys.argv])

ROOT = Path(__file__).resolve().parents[2]
SIDEKICK = ROOT / "scripts" / "sidekick"
for candidate in (str(ROOT), str(SIDEKICK)):
    if candidate not in sys.path:
        sys.path.insert(0, candidate)

from build_dataset import (  # noqa: E402
    CLASS_C_ADMISSION_RATE_FLOOR,
    POST_GATE_REFILL_ITERATION_CAP,
    discounted_capacity,
    planned_framing_slots,
    refill_after_gates,
    require_capacity,
    require_exact,
    subjects_for_discounted_target,
)
from dataset import Row  # noqa: E402
import measure_floors  # noqa: E402


def synthetic_recognize(row_id: str) -> Row:
    return Row(
        id=row_id,
        row_class="A",
        menu=[],
        user_turn="synthetic recognize turn",
        calls=[],
        reply="synthetic reply",
        provenance={"source": "synthetic", "sub_kind": "recognize"},
    )


def main() -> int:
    turn = "one third plus one third as two sixths"
    reply = "1/3 + 1/3 can be restated as 2/6."
    unsupported, _ = measure_floors.score_reply(reply, turn, "C")
    assert unsupported == [], (
        "slash notation derived from the turn's spelled fractions was rejected: "
        f"{unsupported}"
    )

    unsupported, _ = measure_floors.score_reply(
        reply + " A different claim is 3/7 under invented_registry_name.", turn, "C"
    )
    assert unsupported == ["3/7", "invented_registry_name"], (
        "the fraction restatement allowance admitted an unsupported assertion: "
        f"{unsupported}"
    )

    for grade_turn, fraction in (
        ("one third grader", "1/3"),
        ("two fifth graders", "2/5"),
        ("two fifth\n graders", "2/5"),
    ):
        unsupported, _ = measure_floors.score_reply(fraction, grade_turn, "C")
        assert unsupported == [fraction], (
            f"ordinal grade wording synthesized {fraction}: {grade_turn!r}"
        )
    unsupported, _ = measure_floors.score_reply("1/3", "one third of the cake", "C")
    assert unsupported == [], "a non-grade ordinal fraction stopped synthesizing 1/3"

    first_message = {
        "content": None,
        "tool_calls": [
            {
                "id": "call_echo_shape",
                "type": "function",
                "function": {
                    "name": "not_declared",
                    "arguments": {"term": "one half", "language": "Español"},
                },
            }
        ],
    }
    chat_calls: list[list[dict[str, Any]]] = []

    def scripted_chat(
        messages: list[dict[str, Any]],
        tools: list[dict[str, Any]],
        model: str,
        timeout: float,
        endpoint: str = measure_floors.ENDPOINT,
        backend: str = "ollama",
    ) -> tuple[dict[str, Any], float, str]:
        del tools, model, timeout, endpoint, backend
        chat_calls.append(messages)
        if len(chat_calls) == 1:
            return first_message, 0.0, "ok"
        return {"content": "The requested tool is not available."}, 0.0, "ok"

    original_chat = measure_floors.chat
    measure_floors.chat = scripted_chat
    try:
        echo_attempt = measure_floors.run_item(
            Row(
                id="echo-shape",
                row_class="A",
                menu=[],
                user_turn="Check one half.",
                calls=[],
                reply="",
                provenance={"cut": "explicit"},
            ),
            "offered",
            object(),
            {},
            "test-model",
            1.0,
            backend="openai",
        )
    finally:
        measure_floors.chat = original_chat
    echoed_call = chat_calls[1][-2]["tool_calls"][0]
    assert echoed_call["id"] == "call_echo_shape"
    assert echoed_call["type"] == "function"
    echoed_arguments = echoed_call["function"]["arguments"]
    assert isinstance(echoed_arguments, str)
    assert json.loads(echoed_arguments) == first_message["tool_calls"][0]["function"]["arguments"]
    assert isinstance(first_message["tool_calls"][0]["function"]["arguments"], dict)
    assert echo_attempt.calls[0]["arguments"] == {"term": "one half", "language": "Español"}
    print(
        "PASS measure floors fixes: ordinal grade wording does not synthesize fractions; "
        "the assistant echo serializes arguments without mutating scored call data"
    )

    try:
        require_capacity("class D", 1200, 1199)
    except RuntimeError as failure:
        assert str(failure) == "class D: target 1200, available 1199"
    else:
        raise AssertionError("an exact-mix shortfall did not fail hard")

    try:
        require_exact("class C sub-kind C3 after gates", 960, 959)
    except RuntimeError as failure:
        assert str(failure) == "class C sub-kind C3 after gates: target 960, available 959"
    else:
        raise AssertionError("a post-gate sub-kind shortfall did not fail hard")

    assert CLASS_C_ADMISSION_RATE_FLOOR == 0.65
    assert POST_GATE_REFILL_ITERATION_CAP == 5
    assert discounted_capacity(615) == 399
    assert discounted_capacity(616) == 400
    assert subjects_for_discounted_target(400) == 154

    slot_units = [
        ("C:known_fact:0", [("cached-one", "", {})], "known_fact", 4),
        ("C:surface:0", [("cached-a", "", {}), ("cached-b", "", {})], "surface", 4),
        ("C:already_answered:0", [("uncached", "", {})], "already_answered", 4),
    ]
    slot_cache = {
        "framing:known_fact:cached-one": {"turns": ["first", "second"]},
        "framing:surface:cached-a|cached-b": {
            "subjects": {"cached-a": ["one"], "cached-b": ["one", "two", "three"]}
        },
    }
    slots, sources = planned_framing_slots(slot_units, slot_cache)
    assert slots == {"cached-one": 2, "cached-a": 1, "cached-b": 3, "uncached": 4}
    assert sources == {"cached": 6, "requested": 4}

    selected = synthetic_recognize("selected-gate-drop")
    replacement = synthetic_recognize("surplus-replacement")
    gated_ids: list[str] = []

    def synthetic_gate(additions: list[Row]) -> list[Row]:
        gated_ids.extend(row.id for row in additions)
        return [row for row in additions if row.id != selected.id]

    exact_trim = [selected]
    post_gate_kept = synthetic_gate(exact_trim)
    restored, restored_summary = refill_after_gates(
        post_gate_kept,
        [replacement],
        {"A:recognize": 1},
        lambda row: "A:recognize",
        synthetic_gate,
    )
    require_exact(
        "class A sub-kind recognize after gates",
        1,
        sum(row.provenance.get("sub_kind") == "recognize" for row in restored),
    )
    assert [row.id for row in restored] == ["surplus-replacement"]
    assert gated_ids == ["selected-gate-drop", "surplus-replacement"]
    assert restored_summary["short_after_refill"] == {}
    print(
        "PASS post-gate refill restores an exact recognize bucket from ordered surplus "
        "after the selected row is gate-dropped"
    )

    insufficient, insufficient_summary = refill_after_gates(
        post_gate_kept,
        [],
        {"A:recognize": 1},
        lambda row: "A:recognize",
        lambda additions: additions,
    )
    assert insufficient_summary["short_after_refill"] == {"A:recognize": 1}
    try:
        require_exact(
            "class A sub-kind recognize after gates",
            1,
            sum(row.provenance.get("sub_kind") == "recognize" for row in insufficient),
        )
    except RuntimeError as failure:
        assert str(failure) == (
            "class A sub-kind recognize after gates: target 1, available 0"
        )
        print(f"PASS insufficient post-gate surplus fails hard: {failure}")
    else:
        raise AssertionError("insufficient post-gate surplus did not fail hard")

    print(
        "PASS sidekick wave 2 contracts: spelled fractions support only their slash forms; "
        "unsupported assertions remain rejected; exact-mix shortfalls fail hard before and "
        "after gates; 616 raw slots clear a 400-row target only under the 0.65 admission floor; "
        "cached batches contribute their stored turns"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
