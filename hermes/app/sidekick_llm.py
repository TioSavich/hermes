"""Local sidekick model client. Pure stdlib. One llama-server call per invocation.

This client speaks to a llama-server /v1/chat/completions endpoint on the
loopback interface. It is deliberately separate from hermes/app/llm.py: that
client carries the REALLMS response-channel contract (pinned by
scripts/checks/llm_client.py) and declares no tools; this one exists for the
sidekick lane's tool-calling turns against a local model.

Wire behavior mirrors what scripts/sidekick/measure_floors.py measured on
2026-08-12 (chat(), backend="llama", lines 231-277): the /v1 dialect returns
each tool call's arguments as a JSON string, and echoing an assistant turn
back onto the wire requires the arguments re-serialized to a JSON string
(assistant_echo, lines 306-316).
"""
from __future__ import annotations

import json
import os
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from typing import Any

DEFAULT_PORT = 8080
DEFAULT_MODEL = "sidekick"
OUTCOMES = {"ok", "transport_error", "http_error"}


def endpoint_base() -> str:
    port = os.environ.get("HERMES_SIDEKICK_PORT", "").strip() or str(DEFAULT_PORT)
    return f"http://127.0.0.1:{port}"


@dataclass(slots=True)
class ClientResult:
    """One completed local-model call, with branchable outcomes.

    `message` is the normalized assistant message: content text plus any
    tool_calls whose arguments have been parsed from the wire's JSON string
    into a dict. An unparsable arguments string is preserved as
    {"__unparsed__": raw} rather than dropped (measured behavior,
    measure_floors.py:269-277).
    """

    outcome: str
    message: dict[str, Any] = field(default_factory=dict)
    status_code: int | None = None
    error: str | None = None
    elapsed_s: float = 0.0

    def __post_init__(self) -> None:
        if self.outcome not in OUTCOMES:
            raise ValueError(f"unknown sidekick client outcome: {self.outcome}")

    @property
    def ok(self) -> bool:
        return self.outcome == "ok"

    def tool_calls(self) -> list[dict[str, Any]]:
        calls = self.message.get("tool_calls") or []
        return [call for call in calls if isinstance(call, dict)]

    def content(self) -> str:
        return str(self.message.get("content") or "")


def wrap_tool(tool: dict[str, Any]) -> dict[str, Any]:
    """Present one MCP tool the way the template reads a function declaration.

    Copied from scripts/sidekick/chat_format.py:163-174 (the app bundle does
    not ship scripts/sidekick/, so the twelve lines are carried here with this
    provenance note rather than imported across that boundary).
    """
    if tool.get("type") == "function" and "function" in tool:
        return tool
    return {
        "type": "function",
        "function": {
            "name": tool["name"],
            "description": tool["description"],
            "parameters": tool.get("inputSchema") or tool.get("parameters") or {},
        },
    }


def assistant_echo(message: dict[str, Any]) -> dict[str, Any]:
    """Return a wire-compatible assistant echo while retaining parsed call data.

    Mirrors scripts/sidekick/measure_floors.py:306-316: the /v1 dialect wants
    each echoed call's arguments as a JSON string, not a mapping.
    """
    echoed = json.loads(json.dumps(message, ensure_ascii=False))
    echoed["role"] = "assistant"
    echoed["content"] = echoed.get("content") or ""
    for emitted in echoed.get("tool_calls") or []:
        function = emitted.get("function") or {}
        arguments = function.get("arguments") or {}
        if not isinstance(arguments, str):
            function["arguments"] = json.dumps(arguments, ensure_ascii=False)
    return echoed


class SidekickClient:
    """Bounded chat completions against the local llama-server."""

    def __init__(self, model: str = DEFAULT_MODEL, timeout: float = 45.0) -> None:
        self.model = model
        self.timeout = timeout
        self.base = endpoint_base()

    def complete(
        self,
        messages: list[dict[str, Any]],
        tools: list[dict[str, Any]] | None,
        max_tokens: int,
    ) -> ClientResult:
        body: dict[str, Any] = {
            "model": self.model,
            "messages": messages,
            "stream": False,
            "temperature": 0.0,
            "max_tokens": max_tokens,
        }
        if tools:
            body["tools"] = [wrap_tool(tool) for tool in tools]
        request = urllib.request.Request(
            f"{self.base}/v1/chat/completions",
            data=json.dumps(body).encode("utf-8"),
            headers={"Content-Type": "application/json"},
        )
        import time

        started = time.time()
        try:
            with urllib.request.urlopen(request, timeout=self.timeout) as response:
                payload = json.loads(response.read())
        except urllib.error.HTTPError as exc:
            detail = ""
            try:
                detail = exc.read().decode("utf-8", "replace")[:400]
            except Exception:
                pass
            return ClientResult(
                outcome="http_error",
                status_code=exc.code,
                error=f"HTTP {exc.code}: {detail}",
                elapsed_s=time.time() - started,
            )
        except (urllib.error.URLError, TimeoutError, OSError, json.JSONDecodeError) as exc:
            return ClientResult(
                outcome="transport_error",
                error=f"{type(exc).__name__}: {exc}",
                elapsed_s=time.time() - started,
            )
        choices = payload.get("choices") or [{}]
        message = dict(choices[0].get("message") or {})
        # The OpenAI-shaped /v1 dialect carries tool-call arguments as a JSON
        # string (measured 2026-08-12, measure_floors.py:269-277).
        for call in message.get("tool_calls") or []:
            function = call.get("function") or {}
            if isinstance(function.get("arguments"), str):
                try:
                    function["arguments"] = json.loads(function["arguments"])
                except json.JSONDecodeError:
                    function["arguments"] = {"__unparsed__": function["arguments"]}
        return ClientResult(outcome="ok", message=message, elapsed_s=time.time() - started)

    def probe(self, timeout: float = 1.5) -> bool:
        """Return whether the local model endpoint answers. Never raises."""
        for path in ("/health", "/v1/models"):
            try:
                request = urllib.request.Request(f"{self.base}{path}")
                with urllib.request.urlopen(request, timeout=timeout) as response:
                    if 200 <= response.status < 300:
                        return True
            except urllib.error.HTTPError as exc:
                if exc.code == 404:
                    continue
                return False
            except (urllib.error.URLError, TimeoutError, OSError):
                return False
        return False
