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


def truncate_at_stop(text: str, stop: list[str] | None) -> str:
    """Cut a reply at the earliest stop string, the way decoding would."""
    if not stop:
        return text.strip()
    cut = len(text)
    for marker in stop:
        found = text.find(marker)
        if found != -1:
            cut = min(cut, found)
    return text[:cut].strip()


def ollama_complete(prompt: str, *, model: str, stop: list[str] | None = None,
                    endpoint: str = DEFAULT_ENDPOINT,
                    temperature: float = DEFAULT_TEMPERATURE,
                    num_predict: int = DEFAULT_NUM_PREDICT,
                    attempts: int = 3, timeout: float = 600.0,
                    stop_mode: str = "decode") -> str:
    """One completion call, shaped like the benchmark's own.

    `stop_mode` decides where the config's stop list is enforced.

    `decode` hands it to the sampler, which is what the shipped `OllamaAPI`
    does and what the published rows were produced under. Those rows come
    from checkpoints that answer immediately. This checkpoint reasons first,
    and the sampler sees that reasoning: on `mistake_location` the model
    restates the prompt's own words while thinking, matches the config's
    `Q:` stop within about two dozen tokens, and returns the empty string on
    9 items in 10. The benchmark then parses empty as an answer.

    `post` asks for the same completion without decode-time stops and cuts
    the reply at the first stop string instead. For a checkpoint that does
    not reason aloud the two modes agree; for one that does, `post` measures
    the answer the model actually reached rather than the point at which its
    reasoning tripped a guard meant for a different kind of model.

    Both modes are reported. Neither is a repair of the benchmark.
    """
    payload = json.dumps({
        "model": model,
        "prompt": prompt,
        "options": {
            "temperature": temperature,
            "num_predict": num_predict,
            "stop": (stop or []) if stop_mode == "decode" else [],
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
            text = body["response"]
            return (text.strip() if stop_mode == "decode"
                    else truncate_at_stop(text, stop))
        except (urllib.error.URLError, TimeoutError, KeyError,
                json.JSONDecodeError, OSError) as exc:
            last_error = exc
            if attempt + 1 < attempts:
                time.sleep(2 ** attempt)
    raise RuntimeError(f"ollama call failed after {attempts} attempts: {last_error}")


def _unassisted(model: str, **options: str) -> Responder:
    endpoint = options.get("endpoint", DEFAULT_ENDPOINT)
    num_predict = int(options.get("num_predict", DEFAULT_NUM_PREDICT))
    stop_mode = options.get("stop_mode", "decode")

    def respond(*, prompt: str, stop: list[str] | None, example: dict[str, Any],
                task_name: str) -> str:
        return ollama_complete(prompt, model=model, stop=stop,
                               endpoint=endpoint, num_predict=num_predict,
                               stop_mode=stop_mode)

    return respond


BUILDERS: dict[str, Callable[..., Responder]] = {
    "unassisted": _unassisted,
}


def register(name: str, builder: Callable[..., Responder]) -> None:
    BUILDERS[name] = builder


def build(name: str, *, model: str, **options: str) -> Responder:
    if name not in BUILDERS:
        # Assisted arms live in their own modules and register on import, so
        # this file never learns what any of them do.
        try:
            import mtb_hermes_responder  # noqa: F401
            import mtb_tutor_responder  # noqa: F401
        except ImportError:
            pass
    if name not in BUILDERS:
        raise SystemExit(
            f"unknown responder {name!r}; have: {', '.join(sorted(BUILDERS))}")
    return BUILDERS[name](model, **options)
