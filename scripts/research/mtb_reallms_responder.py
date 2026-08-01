#!/usr/bin/env python3
"""A responder that reaches a checkpoint through REALLMS instead of the laptop.

The laptop's Ollama serves these calls close to serially, which puts a
thousand-item corpus at roughly five hours. REALLMS answers the same prompt
from a hosted checkpoint in a fraction of that, so a corpus-scale number is
affordable on the day it is asked for.

What it is not is the same measurement. The laptop arm and the nine published
MathTutorBench columns run `gemma4:e2b`; REALLMS serves a different and much
larger checkpoint. A number from here belongs beside a number from there only
as a second arm, never as the first one obtained faster, and the model id
travels in every summary this responder produces so the two cannot be
confused later.

Transport is the shared client in `hermes/app/llm.py` — the same key handling,
CA context, and retry behaviour every other REALLMS caller in this repository
uses. `--responder-arg pause=0.2` spaces the calls; with several workers the
pause is what keeps a batch from arriving as a burst.
"""
from __future__ import annotations

import importlib.util
import threading
import time
from pathlib import Path
from typing import Any

import mtb_responders

ROOT = Path(__file__).resolve().parents[2]
LLM_PATH = ROOT / "hermes/app/llm.py"


def load_llm_module() -> Any:
    """Load the shared Hermes REALLMS client without importing the app."""
    spec = importlib.util.spec_from_file_location("hermes_reallms", LLM_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import {LLM_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class ReallmsResponder:
    """One chat call per item, spaced by a shared minimum interval."""

    def __init__(self, model: str, **options: str) -> None:
        self.llm = load_llm_module()
        self.client = self.llm.make_client(ROOT)
        if model and model != "gemma4:e2b":
            self.client["model"] = model      # the Ollama default is not meant
        self.model = self.client["model"]     # for this route
        self.timeout = int(options.get("timeout", "600"))
        self.pause = float(options.get("pause", "0.2"))
        self._gate = threading.Lock()
        self._next_allowed = 0.0

    def _wait_turn(self) -> None:
        with self._gate:
            now = time.monotonic()
            wait = self._next_allowed - now
            self._next_allowed = max(now, self._next_allowed) + self.pause
        if wait > 0:
            time.sleep(wait)

    def respond(self, *, prompt: str, stop: list[str] | None,
                example: dict[str, Any], task_name: str) -> str:
        del stop, example, task_name
        self._wait_turn()
        return self.llm.call_api_messages(
            [{"role": "user", "content": prompt}],
            api_key=self.client["api_key"],
            api_url=self.client["api_url"],
            model=self.model,
            ssl_ctx=self.client["ssl_ctx"],
            retries=3,
            timeout=self.timeout,
            fail_on_error=False,
        )


def _build(model: str, **options: str) -> mtb_responders.Responder:
    return ReallmsResponder(model, **options).respond


mtb_responders.register("reallms", _build)
