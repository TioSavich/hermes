#!/usr/bin/env python3
"""Offline fixtures for the sidekick local-model client's wire contract.

Genre of scripts/checks/llm_client.py: urllib is mocked; no socket is bound.
The pinned behaviors are the ones scripts/sidekick/measure_floors.py measured
on 2026-08-12: /v1 tool-call arguments arrive as a JSON string, an unparsable
string is preserved rather than dropped, and an assistant echo re-serializes
arguments back to a JSON string for the wire.
"""
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

from hermes.app.sidekick_llm import SidekickClient, assistant_echo  # noqa: E402


TOOLCALL_FIXTURE = {
    "choices": [{
        "message": {
            "content": "",
            "tool_calls": [{
                "id": "call_0",
                "function": {
                    "name": "check_math_claim",
                    "arguments": "{\"term\": \"1/2 = 2/4\"}",
                },
            }],
        },
        "finish_reason": "tool_calls",
    }],
}

UNPARSABLE_FIXTURE = {
    "choices": [{
        "message": {
            "content": "",
            "tool_calls": [{
                "id": "call_0",
                "function": {"name": "check_math_claim", "arguments": "{not json"},
            }],
        },
        "finish_reason": "tool_calls",
    }],
}


class FakeResponse:
    def __init__(self, payload: dict) -> None:
        self._body = json.dumps(payload).encode("utf-8")
        self.status = 200

    def read(self) -> bytes:
        return self._body

    def __enter__(self) -> "FakeResponse":
        return self

    def __exit__(self, *args: object) -> None:
        return None


def check(name: str, condition: bool, detail: str = "") -> bool:
    if not condition:
        print(f"FAIL {name}: {detail}", file=sys.stderr)
    return condition


def main() -> int:
    client = SidekickClient()
    passes = []

    with mock.patch("urllib.request.urlopen", return_value=FakeResponse(TOOLCALL_FIXTURE)):
        result = client.complete([{"role": "user", "content": "x"}], None, 64)
    calls = result.tool_calls()
    passes.append(check(
        "string_arguments_parse",
        result.ok and calls and calls[0]["function"]["arguments"] == {"term": "1/2 = 2/4"},
        f"outcome={result.outcome} calls={calls}",
    ))

    with mock.patch("urllib.request.urlopen", return_value=FakeResponse(UNPARSABLE_FIXTURE)):
        result = client.complete([{"role": "user", "content": "x"}], None, 64)
    calls = result.tool_calls()
    passes.append(check(
        "unparsable_preserved",
        result.ok and calls
        and calls[0]["function"]["arguments"] == {"__unparsed__": "{not json"},
        f"calls={calls}",
    ))

    echoed = assistant_echo({
        "content": None,
        "tool_calls": [{"id": "call_0",
                        "function": {"name": "check_math_claim",
                                     "arguments": {"term": "1/2 = 2/4"}}}],
    })
    argument_text = echoed["tool_calls"][0]["function"]["arguments"]
    passes.append(check(
        "echo_reserializes",
        echoed["role"] == "assistant" and echoed["content"] == ""
        and isinstance(argument_text, str)
        and json.loads(argument_text) == {"term": "1/2 = 2/4"},
        f"echo={echoed}",
    ))

    http_error = urllib.error.HTTPError(
        "http://127.0.0.1:8080/v1/chat/completions", 400, "Bad Request", None,
        io.BytesIO(b"tool call arguments must be a string"),
    )
    with mock.patch("urllib.request.urlopen", side_effect=http_error):
        result = client.complete([{"role": "user", "content": "x"}], None, 64)
    passes.append(check(
        "http_error_branch",
        result.outcome == "http_error" and result.status_code == 400
        and "arguments must be a string" in (result.error or ""),
        f"outcome={result.outcome} error={result.error}",
    ))

    with mock.patch("urllib.request.urlopen",
                    side_effect=urllib.error.URLError("connection refused")):
        result = client.complete([{"role": "user", "content": "x"}], None, 64)
    passes.append(check(
        "transport_error_branch",
        result.outcome == "transport_error" and "connection refused" in (result.error or ""),
        f"outcome={result.outcome} error={result.error}",
    ))

    with mock.patch("urllib.request.urlopen",
                    side_effect=urllib.error.URLError("connection refused")):
        online = client.probe()
    passes.append(check("probe_offline_no_raise", online is False, f"online={online}"))

    if all(passes):
        print(f"PASS sidekick llm client: {len(passes)} wire-contract fixtures")
        return 0
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
