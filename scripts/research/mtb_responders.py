#!/usr/bin/env python3
"""Responders for the MathTutorBench runner.

A responder takes the benchmark's rendered prompt and returns the string the
benchmark will parse. The `unassisted` responder reproduces the shipped
`OllamaAPI` path: one completion call, temperature 0, `num_predict` 2048, the
config's stop list, nothing else. It is the floor every assisted arm is
measured against.

Assisted responders register here too, so the runner never learns what any
particular arm does.
"""
from __future__ import annotations

import json
import time
import urllib.error
import urllib.request
from typing import Any, Callable, Protocol

DEFAULT_ENDPOINT = "http://localhost:11434/api/generate"
DEFAULT_TEMPERATURE = 0.0
DEFAULT_NUM_PREDICT = 2048


class Responder(Protocol):
    def __call__(self, *, prompt: str, stop: list[str] | None,
                 example: dict[str, Any], task_name: str) -> str: ...


def ollama_complete(prompt: str, *, model: str, stop: list[str] | None = None,
                    endpoint: str = DEFAULT_ENDPOINT,
                    temperature: float = DEFAULT_TEMPERATURE,
                    num_predict: int = DEFAULT_NUM_PREDICT,
                    attempts: int = 3, timeout: float = 600.0) -> str:
    """One raw completion call, shaped exactly like the benchmark's own."""
    payload = json.dumps({
        "model": model,
        "prompt": prompt,
        "options": {
            "temperature": temperature,
            "num_predict": num_predict,
            "stop": stop or [],
        },
        "stream": False,
    }).encode("utf-8")

    last_error: Exception | None = None
    for attempt in range(attempts):
        request = urllib.request.Request(
            endpoint, data=payload,
            headers={"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(request, timeout=timeout) as response:
                body = json.loads(response.read().decode("utf-8"))
            return body["response"].strip()
        except (urllib.error.URLError, TimeoutError, KeyError,
                json.JSONDecodeError, OSError) as exc:
            last_error = exc
            if attempt + 1 < attempts:
                time.sleep(2 ** attempt)
    raise RuntimeError(f"ollama call failed after {attempts} attempts: {last_error}")


def _unassisted(model: str, **options: str) -> Responder:
    endpoint = options.get("endpoint", DEFAULT_ENDPOINT)
    num_predict = int(options.get("num_predict", DEFAULT_NUM_PREDICT))

    def respond(*, prompt: str, stop: list[str] | None, example: dict[str, Any],
                task_name: str) -> str:
        return ollama_complete(prompt, model=model, stop=stop,
                               endpoint=endpoint, num_predict=num_predict)

    return respond


BUILDERS: dict[str, Callable[..., Responder]] = {
    "unassisted": _unassisted,
}


def register(name: str, builder: Callable[..., Responder]) -> None:
    BUILDERS[name] = builder


def build(name: str, *, model: str, **options: str) -> Responder:
    if name not in BUILDERS:
        raise SystemExit(
            f"unknown responder {name!r}; have: {', '.join(sorted(BUILDERS))}")
    return BUILDERS[name](model, **options)
