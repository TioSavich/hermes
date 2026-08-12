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
from typing import Literal, Sequence

from chat_format import GemmaChatFormat, Rendered

IGNORE = -100
MODEL_TURN_HEADER = "<|turn>model\n"
EOS_ID = 1
SequenceKind = Literal["call", "reply", "relay", "C"]


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


def build_sequence(
    chat: GemmaChatFormat, rendered: Rendered, kind: SequenceKind
) -> Supervision:
    """Build one wave-3 per-round mask without changing the legacy row mask."""
    ids = list(rendered.ids)
    if kind == "call":
        calls = rendered.spans(
            chat.marker_ids["<|tool_call>"], chat.marker_ids["<tool_call|>"]
        )
        if not calls:
            raise MaskViolation("a call sequence carries no tool-call span")
        start, close = calls[-1]
        if close != len(ids) - 3 or ids[-2:] != [
            chat.marker_ids["<|tool_response>"],
            EOS_ID,
        ]:
            raise MaskViolation(
                "a call sequence must end at its call close followed by token ids [50, 1]"
            )
        labels = [IGNORE] * start + ids[start:]
        return Supervision(ids=ids, labels=labels, turn_start=start)

    if kind in {"reply", "relay"}:
        responses = rendered.spans(
            chat.marker_ids["<|tool_response>"],
            chat.marker_ids["<tool_response|>"],
        )
        if not responses:
            raise MaskViolation(
                f"a {kind} sequence carries no closed tool-response span"
            )
        start = responses[-1][1] + 1
        labels = [IGNORE] * start + ids[start:]
        return Supervision(ids=ids, labels=labels, turn_start=start)

    if kind == "C":
        return build(chat, rendered)
    raise ValueError(f"unknown sequence kind: {kind}")


def _marker_spans(
    ids: Sequence[int], open_id: int, close_id: int, label: str
) -> tuple[list[tuple[int, int]], list[int]]:
    """Scan marker states independently and retain unmatched opening positions."""
    spans: list[tuple[int, int]] = []
    open_at: int | None = None
    for index, token in enumerate(ids):
        if token == open_id:
            if open_at is not None:
                raise MaskViolation(f"nested {label} opening at token {index}")
            open_at = index
        elif token == close_id:
            if open_at is None:
                raise MaskViolation(f"unmatched {label} close at token {index}")
            spans.append((open_at, index))
            open_at = None
    return spans, ([] if open_at is None else [open_at])


def check_sequence(
    chat: GemmaChatFormat,
    rendered: Rendered,
    supervision: Supervision,
    kind: SequenceKind,
) -> None:
    """Check the wave-3 mask as a token-state machine (gate G2)."""
    ids = list(rendered.ids)
    labels = list(supervision.labels)
    if supervision.ids != ids or len(labels) != len(ids):
        raise MaskViolation("supervision ids or label length disagree with the render")
    bad_labels = [
        index
        for index, (token, label) in enumerate(zip(ids, labels))
        if label not in {IGNORE, token}
    ]
    if bad_labels:
        raise MaskViolation(
            f"labels disagree with input ids at tokens {bad_labels[:5]}"
        )

    supervised = [index for index, label in enumerate(labels) if label != IGNORE]
    if not supervised:
        raise MaskViolation("no token in this sequence is supervised")
    if supervised != list(range(supervised[0], supervised[-1] + 1)):
        raise MaskViolation("the sequence supervises more than one disjoint span")

    open_response = chat.marker_ids["<|tool_response>"]
    close_response = chat.marker_ids["<tool_response|>"]
    open_call = chat.marker_ids["<|tool_call>"]
    close_call = chat.marker_ids["<tool_call|>"]
    response_spans, unmatched_responses = _marker_spans(
        ids, open_response, close_response, "tool-response"
    )
    call_spans, unmatched_calls = _marker_spans(ids, open_call, close_call, "tool-call")
    if unmatched_calls:
        raise MaskViolation(
            f"unmatched tool-call opening at token {unmatched_calls[0]}"
        )

    for start, end in response_spans:
        leaked = [index for index in range(start, end + 1) if labels[index] != IGNORE]
        if leaked:
            raise MaskViolation(
                f"{len(leaked)} supervised tokens fall inside a closed tool-response "
                f"span ({start}..{end})"
            )

    if unmatched_responses:
        terminal_50 = unmatched_responses[0]
        legal_terminal = (
            kind == "call"
            and terminal_50 == len(ids) - 2
            and terminal_50 > 0
            and ids[terminal_50 - 1] == close_call
            and ids[-1] == EOS_ID
            and labels[terminal_50 - 1 :] == ids[terminal_50 - 1 :]
        )
        if not legal_terminal:
            raise MaskViolation(
                "an unmatched token 50 is lawful only as a labeled penultimate token, "
                "immediately after a labeled call close and before one labeled final EOS"
            )
    elif kind == "call":
        raise MaskViolation("a call sequence has no terminal token-50 and EOS close")

    if kind == "call":
        target_start, target_close = call_spans[-1]
        if target_close != len(ids) - 3:
            raise MaskViolation(
                "the taught call is not immediately before terminal [50, 1]"
            )
        if supervised != list(range(target_start, len(ids))):
            raise MaskViolation(
                "a call sequence does not supervise exactly its last call and tail"
            )
        for start, end in call_spans[:-1]:
            if any(labels[index] != IGNORE for index in range(start, end + 1)):
                raise MaskViolation(
                    "a historical call span is supervised in a call sequence"
                )
        return

    if unmatched_responses:
        raise MaskViolation(f"a {kind} sequence carries an unclosed tool-response span")
    canonical_close = chat.encode("<turn|>\n")
    if ids[-len(canonical_close) :] != canonical_close:
        raise MaskViolation(
            f"a {kind} sequence does not end with the canonical turn close"
        )

    if kind in {"reply", "relay"}:
        expected_start = response_spans[-1][1] + 1
        if supervised != list(range(expected_start, len(ids))):
            raise MaskViolation(
                f"a {kind} sequence does not supervise exactly the reply after its last response"
            )
    else:
        header_end = _last_subsequence(ids, chat.encode(MODEL_TURN_HEADER))
        if header_end < 0 or supervised != list(range(header_end, len(ids))):
            raise MaskViolation("a C sequence changed its final-turn supervision")

    supervised_calls = [
        (start, end)
        for start, end in call_spans
        if any(labels[index] != IGNORE for index in range(start, end + 1))
    ]
    if supervised_calls:
        raise MaskViolation(f"a {kind} sequence supervises a historical tool call")


def check(
    chat: GemmaChatFormat,
    rendered: Rendered,
    supervision: Supervision,
    *,
    expects_call: bool,
) -> None:
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
        leaked = [
            index
            for index in range(start, end + 1)
            if supervision.labels[index] != IGNORE
        ]
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
        supervised = [
            index
            for index in range(start, end + 1)
            if supervision.labels[index] != IGNORE
        ]
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
        raise MaskViolation(
            "a row labelled as calling carries no tool-call marker in its own turn"
        )
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
                    {
                        "name": "list_strategies",
                        "arguments": {},
                        "response": {"count": 2},
                    },
                    {
                        "name": "strategy_trace",
                        "arguments": {
                            "strategy": "count_on_from_larger",
                            "input": {"a": 47, "b": 28},
                        },
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
    leaked = Supervision(
        ids=good.ids, labels=list(good.ids), turn_start=good.turn_start
    )
    for name, corrupted in (
        ("supervising everything", leaked),
        (
            "masking the call",
            Supervision(
                ids=good.ids,
                labels=[
                    IGNORE
                    if good.ids[index] == chat.marker_ids["<|tool_call>"]
                    else label
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

    # G2's five state-machine cases are token-level on purpose. They remain
    # independent of the sequence builder and of the template's message walk.
    reply_ids = [48, 201, 49, 50, 202, 51, 301, *chat.encode("<turn|>\n")]
    reply_rendered = Rendered(text="synthetic reply", ids=reply_ids)
    reply_good = Supervision(
        ids=reply_ids,
        labels=[IGNORE] * 6 + reply_ids[6:],
        turn_start=6,
    )
    check_sequence(chat, reply_rendered, reply_good, "reply")

    second_call_ids = [48, 201, 49, 50, 202, 51, 48, 203, 49, 50, 1]
    second_call_rendered = Rendered(text="synthetic second call", ids=second_call_ids)
    second_call_good = Supervision(
        ids=second_call_ids,
        labels=[IGNORE] * 6 + second_call_ids[6:],
        turn_start=6,
    )
    check_sequence(chat, second_call_rendered, second_call_good, "call")

    corruptions = []
    inside_response = list(reply_good.labels)
    inside_response[4] = reply_ids[4]
    corruptions.append(
        (
            "label inside a closed response",
            reply_rendered,
            Supervision(reply_ids, inside_response, reply_good.turn_start),
            "reply",
        )
    )
    continued_ids = second_call_ids + [302]
    corruptions.append(
        (
            "continuation after terminal 50 and EOS",
            Rendered(text="synthetic continued call", ids=continued_ids),
            Supervision(
                continued_ids,
                [IGNORE] * 6 + continued_ids[6:],
                second_call_good.turn_start,
            ),
            "call",
        )
    )
    eos_masked = list(second_call_good.labels)
    eos_masked[-1] = IGNORE
    corruptions.append(
        (
            "terminal 50 with an unlabeled EOS",
            second_call_rendered,
            Supervision(second_call_ids, eos_masked, second_call_good.turn_start),
            "call",
        )
    )
    for name, rendered_case, corrupted, kind in corruptions:
        try:
            check_sequence(chat, rendered_case, corrupted, kind)
        except MaskViolation as violation:
            print(f"caught    {name}: {violation}")
        else:
            raise AssertionError(f"the G2 check accepted {name}")

    print(
        "PASS sidekick mask: legacy masks hold; G2 admits closed historical spans "
        "and terminal [50, 1], and catches all three corruptions"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
