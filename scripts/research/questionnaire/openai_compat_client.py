#!/usr/bin/env python3
"""Questionnaire transport for an OpenAI-compatible llama.cpp endpoint."""
from __future__ import annotations

import json
import urllib.request
from typing import Any, Callable

from ollama_client import OllamaQuestionnaireClient


DEFAULT_ENDPOINT = "http://127.0.0.1:8080/v1/chat/completions"
OpenAITransport = Callable[[dict[str, Any], float], dict[str, Any]]


def _as_ollama_response(value: dict[str, Any]) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ValueError("chat-completions response is not an object")
    if value.get("error"):
        return {"error": value["error"], "eval_count": 0}
    try:
        choice = value["choices"][0]
        content = choice["message"]["content"]
    except (KeyError, IndexError, TypeError) as exc:
        raise ValueError("chat-completions response has no first message") from exc
    usage = value.get("usage") or {}
    completion_tokens = usage.get("completion_tokens", 0)
    if isinstance(completion_tokens, bool) or not isinstance(completion_tokens, int):
        raise ValueError("chat-completions completion token count is invalid")
    finish = str(choice.get("finish_reason") or "stop").lower()
    if content is None:
        content = ""
    return {
        "response": content,
        "done": finish not in {"length", "max_tokens"},
        "done_reason": finish,
        "eval_count": completion_tokens,
    }


class OpenAICompatibleQuestionnaireClient(OllamaQuestionnaireClient):
    """Keep the shipped prompts and parser while changing only HTTP shape."""

    def __init__(
        self,
        *,
        model: str,
        endpoint: str = DEFAULT_ENDPOINT,
        timeout: float = 300.0,
        transport: OpenAITransport | None = None,
        contract: dict[str, Any] | None = None,
    ) -> None:
        self._openai_transport = transport
        self.usage = {
            "model_calls": 0,
            "prompt_tokens": 0,
            "completion_tokens": 0,
            "total_tokens": 0,
        }
        super().__init__(
            model=model,
            endpoint=endpoint,
            timeout=timeout,
            transport=self._translated_transport,
            contract=contract,
        )

    def _payload(self, prompt: str, request: dict[str, Any]) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "model": self.model,
            "messages": [{"role": "user", "content": prompt}],
            "temperature": request["temperature"],
            "max_tokens": request["num_predict"],
            "stream": False,
        }
        if request["stops"]:
            payload["stop"] = list(request["stops"])
        return payload

    def _translated_transport(
        self, payload: dict[str, Any], timeout: float,
    ) -> dict[str, Any]:
        self.usage["model_calls"] += 1
        if self._openai_transport is not None:
            value = self._openai_transport(payload, timeout)
        else:
            request = urllib.request.Request(
                self.endpoint,
                data=json.dumps(payload).encode("utf-8"),
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            with urllib.request.urlopen(request, timeout=timeout) as response:
                value = json.load(response)
        usage = value.get("usage") or {}
        for name in ("prompt_tokens", "completion_tokens", "total_tokens"):
            count = usage.get(name, 0)
            if isinstance(count, int) and not isinstance(count, bool) and count >= 0:
                self.usage[name] += count
        return _as_ollama_response(value)


__all__ = ["DEFAULT_ENDPOINT", "OpenAICompatibleQuestionnaireClient"]
