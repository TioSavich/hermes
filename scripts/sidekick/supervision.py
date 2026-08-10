#!/usr/bin/env python3
"""Decide which tokens a sidekick row teaches, and prove the decision holds.

gemma-4 renders a tool response inside the model's own turn. A mask that
supervises everything after the turn header therefore teaches the model to
write tool output, which is the confabulation this program exists to prevent
and which would stay invisible until a teacher read an invented Hermes result.

So the mask is written against marker token ids and checked, not described.
Supervised: the tool-call spans, the closing assistant text, the turn close.
Masked: the opening token, the whole system turn with its declarations, every
user turn, and every tool-response span.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Sequence

from chat_format import GemmaChatFormat, Rendered

IGNORE = -100
MODEL_TURN_HEADER = "<|turn>model\n"


class MaskViolation(AssertionError):
    """A row whose supervised tokens would teach the wrong thing."""


@dataclass(frozen=True)
class Supervision:
    ids: list[int]
    labels: list[int]
    turn_start: int

    @property
    def supervised_count(self) -> int:
        return sum(1 for label in self.labels if label != IGNORE)


def _last_subsequence(ids: Sequence[int], needle: Sequence[int]) -> int:
    """End index (exclusive) of the last occurrence, or -1."""
    span = len(needle)
    for start in range(len(ids) - span, -1, -1):
        if list(ids[start : start + span]) == list(needle):
            return start + span
    return -1


def build(chat: GemmaChatFormat, rendered: Rendered) -> Supervision:
    ids = list(rendered.ids)
    header = chat.encode(MODEL_TURN_HEADER)
    header_end = _last_subsequence(ids, header)
    if header_end < 0:
        raise MaskViolation("no model turn to supervise in this rendering")
    labels = [IGNORE] * header_end + ids[header_end:]
    for start, end in rendered.spans(
        chat.marker_ids["<|tool_response>"], chat.marker_ids["<tool_response|>"]
    ):
        for index in range(start, end + 1):
            labels[index] = IGNORE
    return Supervision(ids=ids, labels=labels, turn_start=header_end)


def check(chat: GemmaChatFormat, rendered: Rendered, supervision: Supervision, *, expects_call: bool) -> None:
    """Assert what the mask must do, without reusing how it was made.

    The scan below walks the token stream itself rather than reading
    `supervision.turn_start`. A check that borrows the builder's own span
    arithmetic passes whenever that arithmetic is wrong in the same direction,
    which is the failure this specification cannot afford.
    """
    open_response = chat.marker_ids["<|tool_response>"]
    close_response = chat.marker_ids["<tool_response|>"]
    open_call = chat.marker_ids["<|tool_call>"]
    close_call = chat.marker_ids["<tool_call|>"]
    ids = rendered.ids

    depth = 0
    response_spans: list[tuple[int, int]] = []
    call_spans: list[tuple[int, int]] = []
    opened_at: dict[str, int] = {}
    for index, token in enumerate(ids):
        if token == open_response:
            opened_at["response"] = index
            depth += 1
        elif token == close_response and "response" in opened_at:
            response_spans.append((opened_at.pop("response"), index))
            depth -= 1
        elif token == open_call:
            opened_at["call"] = index
        elif token == close_call and "call" in opened_at:
            call_spans.append((opened_at.pop("call"), index))
    if "response" in opened_at:
        response_spans.append((opened_at["response"], len(ids) - 1))
    if "call" in opened_at:
        call_spans.append((opened_at["call"], len(ids) - 1))

    for start, end in response_spans:
        leaked = [index for index in range(start, end + 1) if supervision.labels[index] != IGNORE]
        if leaked:
            raise MaskViolation(
                f"{len(leaked)} supervised tokens fall inside a tool-response span "
                f"({start}..{end}); the row would teach the model to write tool output"
            )

    # The mask can also be too wide. A tool-call span that carries no
    # supervision teaches nothing about asking, and the row would sit in the
    # set looking like data while contributing none.
    header = chat.encode(MODEL_TURN_HEADER)
    turn_start = _last_subsequence(ids, header)
    if turn_start < 0:
        raise MaskViolation("no model turn to supervise in this rendering")
    for start, end in call_spans:
        if start < turn_start:
            continue
        supervised = [index for index in range(start, end + 1) if supervision.labels[index] != IGNORE]
        if len(supervised) != end - start + 1:
            raise MaskViolation(
                f"a tool-call span ({start}..{end}) is masked at "
                f"{end - start + 1 - len(supervised)} of its tokens; the row would "
                "teach nothing about asking"
            )

    # Only the turn being taught counts. A class-C row may carry an earlier
    # exchange whose call is already answered; what it must not do is call
    # again, so the marker is looked for in the supervised turn alone.
    has_call = any(start >= turn_start for start, _ in call_spans)
    if expects_call and not has_call:
        raise MaskViolation("a row labelled as calling carries no tool-call marker in its own turn")
    if not expects_call and has_call:
        raise MaskViolation("a row labelled as not calling calls in its own turn")
    if supervision.supervised_count == 0:
        raise MaskViolation("no token in this row is supervised")


def main() -> int:
    """Exercise the mask on a call row, a chain row, and an abstaining row.

    Registered in the gate chain. The checkpoint's template and vocabulary are
    local runtime and may be absent in a fresh clone, so their absence is a
    skip rather than a failure; nothing tracked may hard-require them.
    """
    import sys
    from pathlib import Path

    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
    from chat_format import AssetsMissing, asset_dir, conversation
    from hermes.mcp.server import HermesMCPServer

    try:
        chat = GemmaChatFormat()
    except AssetsMissing:
        print(
            "SKIP sidekick mask check: the gemma-4 template and vocabulary are "
            f"local runtime and are absent under {asset_dir()}"
        )
        return 0
    server = HermesMCPServer("core", Path(__file__).resolve().parents[2])
    tools = {tool["name"]: tool for tool in server._public_tools}
    cases = [
        (
            "one call",
            conversation(
                "A student counted up from 47 to 82. What is that strategy?",
                [
                    {
                        "name": "strategy_recognize",
                        "arguments": {"content": "I counted up from 47 to 82"},
                        "response": {"strategies": []},
                    }
                ],
                "Hermes declines to name a strategy from that sentence alone.",
            ),
            ["strategy_recognize"],
            True,
        ),
        (
            "two calls",
            conversation(
                "Which registered strategy does this trace belong to, and what does it do?",
                [
                    {"name": "list_strategies", "arguments": {}, "response": {"count": 2}},
                    {
                        "name": "strategy_trace",
                        "arguments": {"strategy": "count_on_from_larger", "input": {"a": 47, "b": 28}},
                        "response": {"result": 75},
                    },
                ],
                "Hermes runs count on from larger and reaches 75.",
            ),
            ["strategy_trace"],
            True,
        ),
        (
            "no call",
            conversation("What is 7 times 8?", [], "Fifty-six."),
            ["strategy_recognize"],
            False,
        ),
    ]
    for label, messages, menu, expects_call in cases:
        rendered = chat.render(messages, [tools[name] for name in menu])
        supervision = build(chat, rendered)
        check(chat, rendered, supervision, expects_call=expects_call)
        print(
            f"{label:9s} tokens={len(supervision.ids):5d} supervised={supervision.supervised_count:4d} "
            f"response_spans={len(rendered.spans(50, 51))}"
        )

    # Two deliberate corruptions. A check that only ever meets correct masks
    # reports its own silence as evidence.
    rendered = chat.render(cases[0][1], [tools[name] for name in cases[0][2]])
    good = build(chat, rendered)
    leaked = Supervision(ids=good.ids, labels=list(good.ids), turn_start=good.turn_start)
    for name, corrupted in (
        ("supervising everything", leaked),
        (
            "masking the call",
            Supervision(
                ids=good.ids,
                labels=[
                    IGNORE if good.ids[index] == chat.marker_ids["<|tool_call>"] else label
                    for index, label in enumerate(good.labels)
                ],
                turn_start=good.turn_start,
            ),
        ),
    ):
        try:
            check(chat, rendered, corrupted, expects_call=True)
        except MaskViolation as violation:
            print(f"caught    {name}: {violation}")
        else:
            raise AssertionError(f"the check accepted a mask that was {name}")

    print("PASS sidekick mask: tool responses masked, call spans supervised, no-call rows silent")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
