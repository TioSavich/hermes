#!/usr/bin/env python3
"""Offline fixtures for the REALLMS response-channel contract."""
from __future__ import annotations

import io
import json
import sys
import urllib.error
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from hermes.app import llm  # noqa: E402


OK_FIXTURE = {
    "choices": [{
        "message": {
            "content": "The answer is one whole.",
            "reasoning_content": "We need answer the one-sentence fraction task.",
        },
        "finish_reason": "stop",
    }],
    "usage": {
        "completion_tokens": 351,
        "prompt_tokens": 22,
        "total_tokens": 373,
        "prompt_tokens_details": {"cached_tokens": 0},
        "ttft_s": 0.12,
        "tpot_s": 0.03,
        "latency_s": 10.4,
    },
}

EMPTY_FIXTURE = {
    "choices": [{
        "message": {"content": None, "reasoning_content": "diagnostic thinking"},
        "finish_reason": "stop",
    }],
    "usage": {"completion_tokens": 83, "prompt_tokens": 14, "total_tokens": 97},
}

STARVATION_FIXTURE = {
    "choices": [{
        "message": {
            "content": "We need answer carefully. First, inspect the fractions...",
            "reasoning_content": "",
        },
        "finish_reason": "length",
    }],
    "usage": {"completion_tokens": 100, "prompt_tokens": 18, "total_tokens": 118},
}


class FakeResponse:
    def __init__(self, payload: dict) -> None:
        self.payload = payload

    def __enter__(self) -> "FakeResponse":
        return self

    def __exit__(self, *_args: object) -> None:
        return None

    def read(self) -> bytes:
        return json.dumps(self.payload).encode("utf-8")


def call_kwargs() -> dict:
    return {
        "api_key": "fixture-key",
        "api_url": "https://fixture.invalid/v1/chat/completions",
        "model": "glm-5.2",
        "ssl_ctx": mock.sentinel.ssl_context,
        "retries": 1,
        "timeout": 1,
    }


def test_ok_keeps_channels_and_usage_separate() -> None:
    result = llm.parse_chat_completion(OK_FIXTURE)
    assert result.outcome == "ok"
    assert result.content == "The answer is one whole."
    assert result.reasoning_content.startswith("We need answer")
    assert result.finish_reason == "stop"
    assert result.usage == OK_FIXTURE["usage"]
    assert result.raw_response is OK_FIXTURE
    print("PASS ok preserves separate final, reasoning, finish, usage, and raw fields")


def test_empty_never_falls_back_to_reasoning() -> None:
    result = llm.parse_chat_completion(EMPTY_FIXTURE)
    assert result.outcome == "empty_content"
    assert result.content == ""
    assert result.reasoning_content == "diagnostic thinking"
    with mock.patch.object(llm.urllib.request, "urlopen", return_value=FakeResponse(EMPTY_FIXTURE)):
        reply = llm.call_api_messages([{"role": "user", "content": "fixture"}], **call_kwargs())
    assert reply == ""
    print("PASS empty final content stays empty; diagnostic reasoning is never the reply")


def test_starvation_leak_is_truncated_and_suppressed_by_string_wrapper() -> None:
    result = llm.parse_chat_completion(STARVATION_FIXTURE)
    assert result.outcome == "truncated"
    assert result.content.startswith("We need answer carefully")
    assert result.reasoning_content == ""
    with mock.patch.object(llm.urllib.request, "urlopen", return_value=FakeResponse(STARVATION_FIXTURE)):
        reply = llm.call_api_messages([{"role": "user", "content": "fixture"}], **call_kwargs())
    assert reply == ""
    print("PASS length-finished starvation leak remains diagnostic and never reaches string callers")


def test_budget_and_local_stops_touch_only_final_content() -> None:
    fixture = {
        "choices": [{
            "message": {
                "content": "usable final<END>discarded final suffix",
                "reasoning_content": "thinking contains <END> and remains intact",
            },
            "finish_reason": "stop",
        }],
        "usage": {},
    }
    captured: dict = {}

    def urlopen(request: object, **_kwargs: object) -> FakeResponse:
        captured.update(json.loads(request.data.decode("utf-8")))  # type: ignore[attr-defined]
        return FakeResponse(fixture)

    with mock.patch.object(llm.urllib.request, "urlopen", side_effect=urlopen):
        result = llm.call_api_messages_result(
            [{"role": "user", "content": "fixture"}],
            max_tokens=4096,
            final_stop_sequences=("<END>",),
            **call_kwargs(),
        )
    assert captured["max_tokens"] == 4096
    assert "stop" not in captured
    assert result.content == "usable final"
    assert result.reasoning_content == "thinking contains <END> and remains intact"
    assert result.raw_response["choices"][0]["message"]["content"].endswith("suffix")
    print("PASS max_tokens is explicit; local stops affect only isolated final content")


def test_http_and_transport_errors_are_branchable() -> None:
    http_error = urllib.error.HTTPError(
        call_kwargs()["api_url"],
        400,
        "Bad Request",
        {},
        io.BytesIO(b'{"error":{"message":"unknown model"}}'),
    )
    with mock.patch.object(llm.urllib.request, "urlopen", side_effect=http_error):
        http_result = llm.call_api_messages_result(
            [{"role": "user", "content": "fixture"}], **call_kwargs()
        )
    assert http_result.outcome == "http_error"
    assert http_result.status_code == 400
    assert http_result.raw_response["error"]["message"] == "unknown model"
    assert http_result.retryable is False

    with mock.patch.object(
        llm.urllib.request,
        "urlopen",
        side_effect=urllib.error.URLError("offline fixture"),
    ):
        transport_result = llm.call_api_messages_result(
            [{"role": "user", "content": "fixture"}], **call_kwargs()
        )
    assert transport_result.outcome == "transport_error"
    assert transport_result.status_code is None
    assert transport_result.retryable is True
    print("PASS HTTP and transport failures return distinct branchable outcomes")


def test_malformed_response_is_transport_error() -> None:
    result = llm.parse_chat_completion({"choices": []})
    assert result.outcome == "transport_error"
    assert "malformed chat-completion response" in (result.error or "")
    print("PASS malformed response shape is a transport error, not an answer")


def main() -> int:
    test_ok_keeps_channels_and_usage_separate()
    test_empty_never_falls_back_to_reasoning()
    test_starvation_leak_is_truncated_and_suppressed_by_string_wrapper()
    test_budget_and_local_stops_touch_only_final_content()
    test_http_and_transport_errors_are_branchable()
    test_malformed_response_is_transport_error()
    print("REALLMS response-channel checks PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
