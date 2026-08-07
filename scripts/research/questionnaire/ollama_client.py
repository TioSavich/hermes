#!/usr/bin/env python3
"""Contract-bound Ollama client for the questionnaire runner.

Construction and import are inert.  The default transport reaches the local
Ollama generate endpoint only when ``complete`` is called.  A fixture transport
can be injected for tests without opening a socket.
"""
from __future__ import annotations

import json
import time
import urllib.error
import urllib.request
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Callable

from runner import (
    ModelOutcome,
    Question,
    TransportStatus,
    load_call_contract,
)


DEFAULT_ENDPOINT = "http://127.0.0.1:11434/api/generate"
DEFAULT_MODEL = "gemma4:e2b"
Transport = Callable[[dict[str, Any], float], dict[str, Any]]


@dataclass(frozen=True)
class ClientAttempt:
    sequence: int
    question_id: str
    ordering: str
    level: str
    page: int
    model: str
    status: str
    parsed_letter: str | None
    abstention: bool
    eval_count: int
    latency_ms: float
    latency_bound_ms: float
    latency_within_bound: bool
    raw_exact_one_letter: bool | None
    reply_stops_honored: bool | None
    request_contract_exact: bool
    parse_ok: bool
    detail: str

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


def question_id(question: Question) -> str:
    """Return an ordering-independent identity for one semantic question."""
    import hashlib

    material = {
        "level": question.level,
        "text": question.text,
        "excerpt": question.excerpt,
        "page_index": question.page_index,
        "page_count": question.page_count,
        "choice_keys": sorted(choice.key for choice in question.choices),
        "context": {
            key: value
            for key, value in question.context.items()
            if not key.startswith("_smoke_")
        },
    }
    encoded = json.dumps(material, ensure_ascii=False, sort_keys=True, default=str).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()[:20]


class OllamaQuestionnaireClient:
    """Implement the runner's injected-client protocol against Ollama."""

    def __init__(
        self,
        *,
        model: str = DEFAULT_MODEL,
        endpoint: str = DEFAULT_ENDPOINT,
        timeout: float = 300.0,
        transport: Transport | None = None,
        contract: dict[str, Any] | None = None,
    ) -> None:
        if timeout <= 0:
            raise ValueError("timeout must be positive")
        self.model = model
        self.endpoint = endpoint
        self.timeout = float(timeout)
        self.contract = contract if contract is not None else load_call_contract()
        self._transport = transport if transport is not None else self._http_transport
        self.attempts: list[ClientAttempt] = []

    def _http_transport(self, payload: dict[str, Any], timeout: float) -> dict[str, Any]:
        request = urllib.request.Request(
            self.endpoint,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(request, timeout=timeout) as response:
            value = json.load(response)
        if not isinstance(value, dict):
            raise ValueError("Ollama response is not a JSON object")
        return value

    def _payload(self, prompt: str) -> dict[str, Any]:
        request = self.contract["request"]
        options: dict[str, Any] = {
            "temperature": request["temperature"],
            "num_predict": request["num_predict"],
        }
        # The governing design sends no sampler-side stop for the shipped empty
        # list.  If a later contract names stops, they are passed without edits.
        if request["stops"]:
            options["stop"] = list(request["stops"])
        return {
            "model": self.model,
            "prompt": prompt,
            "stream": False,
            "think": request["think"],
            "options": options,
        }

    def _record(
        self,
        question: Question,
        outcome: ModelOutcome,
        *,
        request_contract_exact: bool,
    ) -> ModelOutcome:
        parsed_letter = outcome.content if outcome.status is TransportStatus.OK else None
        self.attempts.append(ClientAttempt(
            sequence=len(self.attempts) + 1,
            question_id=question_id(question),
            ordering=str(question.context.get("_smoke_ordering", "primary")),
            level=question.level,
            page=question.page_index,
            model=self.model,
            status=outcome.status.value,
            parsed_letter=parsed_letter,
            abstention=outcome.status is not TransportStatus.OK or parsed_letter == "X",
            eval_count=outcome.eval_count,
            latency_ms=float(outcome.latency_ms or 0.0),
            latency_bound_ms=self.timeout * 1000.0,
            latency_within_bound=float(outcome.latency_ms or 0.0) <= self.timeout * 1000.0,
            raw_exact_one_letter=outcome.raw_exact_one_letter,
            reply_stops_honored=outcome.reply_stops_honored,
            request_contract_exact=request_contract_exact,
            parse_ok=bool(outcome.parse_ok),
            detail=outcome.detail,
        ))
        return outcome

    def complete(self, question: Question, prompt: str, request: dict[str, Any]) -> ModelOutcome:
        expected = self.contract["request"]
        request_exact = request == expected
        if not request_exact:
            outcome = ModelOutcome(
                TransportStatus.ERROR,
                detail="request_contract_mismatch",
                latency_ms=0.0,
                request_contract_exact=False,
                parse_ok=False,
            )
            return self._record(question, outcome, request_contract_exact=False)

        started = time.perf_counter()
        try:
            payload = self._transport(self._payload(prompt), self.timeout)
        except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, OSError) as exc:
            latency = (time.perf_counter() - started) * 1000.0
            outcome = ModelOutcome(
                TransportStatus.ERROR,
                detail=f"transport_error:{type(exc).__name__}",
                latency_ms=latency,
                request_contract_exact=True,
                parse_ok=False,
            )
            return self._record(question, outcome, request_contract_exact=True)
        except (ValueError, TypeError, json.JSONDecodeError) as exc:
            latency = (time.perf_counter() - started) * 1000.0
            outcome = ModelOutcome(
                TransportStatus.ERROR,
                detail=f"response_error:{type(exc).__name__}",
                latency_ms=latency,
                request_contract_exact=True,
                parse_ok=False,
            )
            return self._record(question, outcome, request_contract_exact=True)

        latency = (time.perf_counter() - started) * 1000.0
        if not isinstance(payload, dict):
            outcome = ModelOutcome(
                TransportStatus.ERROR,
                detail="response_not_object",
                latency_ms=latency,
                request_contract_exact=True,
                parse_ok=False,
            )
            return self._record(question, outcome, request_contract_exact=True)

        eval_count = payload.get("eval_count", 0)
        if isinstance(eval_count, bool) or not isinstance(eval_count, int) or eval_count < 0:
            outcome = ModelOutcome(
                TransportStatus.ERROR,
                detail="invalid_eval_count",
                latency_ms=latency,
                request_contract_exact=True,
                parse_ok=False,
            )
            return self._record(question, outcome, request_contract_exact=True)

        if payload.get("error"):
            outcome = ModelOutcome(
                TransportStatus.ERROR,
                eval_count=eval_count,
                detail="ollama_error",
                latency_ms=latency,
                request_contract_exact=True,
                parse_ok=False,
            )
            return self._record(question, outcome, request_contract_exact=True)

        done_reason = str(payload.get("done_reason", "")).lower()
        if payload.get("done") is False or done_reason in {"length", "max_tokens"}:
            outcome = ModelOutcome(
                TransportStatus.TRUNCATED,
                eval_count=eval_count,
                detail="generation_truncated",
                latency_ms=latency,
                request_contract_exact=True,
                parse_ok=False,
            )
            return self._record(question, outcome, request_contract_exact=True)

        raw = payload.get("response")
        if not isinstance(raw, str):
            outcome = ModelOutcome(
                TransportStatus.ERROR,
                eval_count=eval_count,
                detail="response_content_not_string",
                latency_ms=latency,
                request_contract_exact=True,
                parse_ok=False,
            )
            return self._record(question, outcome, request_contract_exact=True)
        if raw == "":
            outcome = ModelOutcome(
                TransportStatus.EMPTY_CONTENT,
                eval_count=eval_count,
                detail="empty_response",
                latency_ms=latency,
                raw_exact_one_letter=False,
                reply_stops_honored=True,
                request_contract_exact=True,
                parse_ok=False,
            )
            return self._record(question, outcome, request_contract_exact=True)

        valid = {choice.letter for choice in question.choices}
        raw_exact = len(raw) == 1 and raw.upper() in valid
        stopped = raw
        for stop in self.contract["reply_stops"]:
            stopped = stopped.split(stop, 1)[0]
        normalized = stopped.strip().upper()
        parse_ok = len(normalized) == 1 and normalized in valid
        if not parse_ok:
            outcome = ModelOutcome(
                TransportStatus.INVALID_CONTENT,
                eval_count=eval_count,
                detail="one_letter_parse_failed",
                latency_ms=latency,
                raw_exact_one_letter=raw_exact,
                reply_stops_honored=True,
                request_contract_exact=True,
                parse_ok=False,
            )
            return self._record(question, outcome, request_contract_exact=True)

        outcome = ModelOutcome(
            TransportStatus.OK,
            content=normalized,
            eval_count=eval_count,
            latency_ms=latency,
            raw_exact_one_letter=raw_exact,
            reply_stops_honored=True,
            request_contract_exact=True,
            parse_ok=True,
        )
        return self._record(question, outcome, request_contract_exact=True)


__all__ = [
    "ClientAttempt",
    "DEFAULT_ENDPOINT",
    "DEFAULT_MODEL",
    "OllamaQuestionnaireClient",
    "question_id",
]
