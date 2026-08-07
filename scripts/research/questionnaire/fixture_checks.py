#!/usr/bin/env python3
"""Offline fixtures for the questionnaire Ollama client contract."""
from __future__ import annotations

import socket
import urllib.error
from typing import Any
from unittest.mock import patch

from build_choice_sets import Choice
from ollama_client import OllamaQuestionnaireClient
from runner import Question, TransportStatus, load_call_contract


QUESTION = Question(
    level="L1",
    text="Fixture question?",
    excerpt="Fixture work: 1 + 1 = 2",
    page_index=0,
    page_count=1,
    choices=(
        Choice("A", "first", "first", "first"),
        Choice("B", "second", "second", "second"),
        Choice("X", "abstain", "none of these / cannot tell", None),
    ),
)
PROMPT = "fixture prompt"


class OneReply:
    def __init__(self, value: Any) -> None:
        self.value = value
        self.payloads: list[dict[str, Any]] = []

    def __call__(self, payload: dict[str, Any], timeout: float) -> Any:
        assert timeout == 12.0
        self.payloads.append(payload)
        if isinstance(self.value, BaseException):
            raise self.value
        return self.value


def run_case(value: Any, *, request: dict[str, Any] | None = None) -> tuple[Any, OneReply, Any]:
    transport = OneReply(value)
    client = OllamaQuestionnaireClient(
        model="fixture-model",
        timeout=12.0,
        transport=transport,
    )
    outcome = client.complete(
        QUESTION,
        PROMPT,
        load_call_contract()["request"] if request is None else request,
    )
    assert len(client.attempts) == 1
    return outcome, transport, client.attempts[0]


def main() -> int:
    socket_count = 0

    def forbidden_socket(*unused_args: Any, **unused_kwargs: Any) -> Any:
        nonlocal socket_count
        socket_count += 1
        raise AssertionError("Ollama client fixture opened a socket")

    with patch("socket.socket", forbidden_socket):
        valid, transport, attempt = run_case(
            {"response": "A", "done": True, "done_reason": "stop", "eval_count": 1}
        )
        assert valid.status is TransportStatus.OK and valid.content == "A"
        assert valid.raw_exact_one_letter is True and attempt.parse_ok
        assert transport.payloads == [{
            "model": "fixture-model",
            "prompt": PROMPT,
            "stream": False,
            "think": False,
            "options": {"temperature": 0, "num_predict": 8},
        }]

        stopped, _, stopped_attempt = run_case(
            {"response": "B\nignored", "done": True, "eval_count": 2}
        )
        assert stopped.status is TransportStatus.OK and stopped.content == "B"
        assert stopped.raw_exact_one_letter is False
        assert stopped.reply_stops_honored is True and stopped_attempt.parse_ok

        abstained, _, abstained_attempt = run_case(
            {"response": "X", "done": True, "eval_count": 1}
        )
        assert abstained.status is TransportStatus.OK and abstained.content == "X"
        assert abstained_attempt.abstention

        malformed_values = [
            ({"response": "A because", "done": True, "eval_count": 1}, TransportStatus.INVALID_CONTENT),
            ({"response": "Q", "done": True, "eval_count": 1}, TransportStatus.INVALID_CONTENT),
            ({"response": "", "done": True, "eval_count": 0}, TransportStatus.EMPTY_CONTENT),
            ({"response": "A", "done": False, "eval_count": 8}, TransportStatus.TRUNCATED),
            ({"response": "A", "done": True, "done_reason": "length", "eval_count": 8}, TransportStatus.TRUNCATED),
            ({"error": "fixture", "eval_count": 0}, TransportStatus.ERROR),
            ({"response": ["A"], "done": True, "eval_count": 1}, TransportStatus.ERROR),
            ({"response": "A", "done": True, "eval_count": -1}, TransportStatus.ERROR),
            (["not", "an", "object"], TransportStatus.ERROR),
            (urllib.error.URLError("offline fixture"), TransportStatus.ERROR),
        ]
        for value, status in malformed_values:
            outcome, _, malformed_attempt = run_case(value)
            assert outcome.status is status, (value, outcome)
            assert outcome.content == ""
            assert malformed_attempt.parsed_letter is None
            assert malformed_attempt.abstention

        mismatch = dict(load_call_contract()["request"])
        mismatch["num_predict"] = 9
        outcome, mismatch_transport, mismatch_attempt = run_case(
            {"response": "A", "done": True, "eval_count": 1}, request=mismatch,
        )
        assert outcome.status is TransportStatus.ERROR and outcome.content == ""
        assert mismatch_transport.payloads == []
        assert mismatch_attempt.request_contract_exact is False

    assert socket_count == 0
    print(
        "QUESTIONNAIRE OLLAMA CLIENT FIXTURES: PASS "
        f"malformed={len(malformed_values)} request_contract=exact sockets=0"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

