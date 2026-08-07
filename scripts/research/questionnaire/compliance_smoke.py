#!/usr/bin/env python3
"""Run the questionnaire's short Ollama and Hermes compliance smoke.

The default mode calls local Ollama and the real stdio MCP core.  ``--fixture``
uses injected transports and opens no network socket.
"""
from __future__ import annotations

import argparse
import json
import re
import socket
from dataclasses import replace
from pathlib import Path
from typing import Any
from unittest.mock import patch

from build_choice_sets import ABSTENTION_LETTER, CONTENT_LETTERS, Choice, conforms
from check_compliance_smoke import check_rows
from ollama_client import (
    DEFAULT_ENDPOINT,
    DEFAULT_MODEL,
    OllamaQuestionnaireClient,
    question_id,
)
from runner import (
    ModelOutcome,
    Question,
    QuestionnaireRunner,
    StdioHermesClient,
    TransportStatus,
    load_call_contract,
)


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
SMOKE_ITEMS = HERE / "smoke_items.json"
DEFAULT_OUTPUT = ROOT / "hermes/app/runtime/experiments/questionnaire/compliance_smoke.jsonl"
CHOICE_LINE = re.compile(r"^([A-GX]) — (.+)$", re.MULTILINE)


def choice_block(question: Question) -> str:
    return "\n".join(f"{choice.letter} — {choice.label}" for choice in question.choices)


def permute_question(question: Question, sequence: int) -> Question:
    content = [choice for choice in question.choices if choice.letter != ABSTENTION_LETTER]
    abstention = next(choice for choice in question.choices if choice.letter == ABSTENTION_LETTER)
    if len(content) > 1:
        shift = 1 + ((sequence - 1) % (len(content) - 1))
        content = content[shift:] + content[:shift]
    choices = tuple(
        Choice(CONTENT_LETTERS[index], choice.key, choice.label, choice.value)
        for index, choice in enumerate(content)
    ) + (Choice(ABSTENTION_LETTER, abstention.key, abstention.label, abstention.value),)
    return replace(question, choices=choices)


def prompt_with_question_choices(prompt: str, original: Question, changed: Question) -> str:
    old = choice_block(original)
    if prompt.count(old) != 1:
        raise ValueError("could not identify the questionnaire choice block")
    return prompt.replace(old, choice_block(changed), 1)


def selected_key(question: Question, outcome: ModelOutcome) -> str | None:
    if outcome.status is not TransportStatus.OK:
        return None
    return next(
        (choice.key for choice in question.choices if choice.letter == outcome.content),
        None,
    )


class PositionProbeClient:
    """Ask each question in its compiled and content-permuted order."""

    def __init__(self, client: OllamaQuestionnaireClient) -> None:
        self.client = client
        self.probes: list[dict[str, Any]] = []

    def complete(self, question: Question, prompt: str, request: dict[str, Any]) -> ModelOutcome:
        sequence = len(self.probes) + 1
        primary = replace(
            question,
            context={**question.context, "_smoke_ordering": "compiled", "_smoke_pair": sequence},
        )
        primary_outcome = self.client.complete(primary, prompt, request)

        permuted = permute_question(question, sequence)
        permuted = replace(
            permuted,
            context={**permuted.context, "_smoke_ordering": "permuted", "_smoke_pair": sequence},
        )
        permuted_prompt = prompt_with_question_choices(prompt, question, permuted)
        permuted_outcome = self.client.complete(permuted, permuted_prompt, request)

        primary_key = selected_key(primary, primary_outcome)
        permuted_key = selected_key(permuted, permuted_outcome)
        comparable = primary_key is not None and permuted_key is not None
        self.probes.append({
            "sequence": sequence,
            "question_id": question_id(question),
            "level": question.level,
            "page": question.page_index,
            "compiled_choices": [
                {"letter": choice.letter, "key": choice.key} for choice in primary.choices
            ],
            "permuted_choices": [
                {"letter": choice.letter, "key": choice.key} for choice in permuted.choices
            ],
            "compiled_status": primary_outcome.status.value,
            "compiled_letter": primary_outcome.content or None,
            "compiled_key": primary_key,
            "permuted_status": permuted_outcome.status.value,
            "permuted_letter": permuted_outcome.content or None,
            "permuted_key": permuted_key,
            "comparable": comparable,
            "flip": comparable and primary_key != permuted_key,
        })
        # The per-item budget covers every sampled token, including the paired
        # permutation probe, even though only the compiled-order answer routes.
        return replace(
            primary_outcome,
            eval_count=primary_outcome.eval_count + permuted_outcome.eval_count,
        )


class FixtureHermes:
    """Shape-checking symbolic fixture used only by ``--fixture``."""

    def __init__(self, compiled: Any) -> None:
        self.by_strategy = {
            schema.representative_kind: schema for schema in compiled.contracts
        }

    def call_tool(self, name: str, arguments: dict[str, Any]) -> Any:
        if name == "strategy_recognize":
            return []
        if name != "strategy_trace":
            raise AssertionError(f"unexpected fixture tool: {name}")
        schema = self.by_strategy[arguments["strategy"]]
        if not conforms(schema.template, arguments["input"]):
            raise AssertionError("fixture leaf input does not conform to its contract")
        return {
            "ok": True,
            "fixture": True,
            "tool": name,
            "strategy": arguments["strategy"],
            "input": arguments["input"],
        }

    def close(self) -> None:
        return None


class WorkedItemFixtureTransport:
    """Choose the authored worked item's semantic answer from each prompt."""

    @staticmethod
    def _family(prompt: str) -> str:
        if " times " in prompt:
            return "multiplication"
        if " 53 - 18 " in prompt:
            return "subtraction"
        if " 27 + 15 " in prompt:
            return "addition"
        raise AssertionError("unknown authored fixture excerpt")

    def __call__(self, payload: dict[str, Any], timeout: float) -> dict[str, Any]:
        del timeout
        prompt = payload["prompt"]
        choices = CHOICE_LINE.findall(prompt)
        if not choices:
            raise AssertionError("fixture prompt has no choices")
        family = self._family(prompt)
        if "What is the work mostly doing?" in prompt:
            wanted = "whole-number arithmetic"
        elif "Which Hermes family best matches the work?" in prompt:
            wanted = family
        elif "operand slot /a" in prompt:
            wanted = {"addition": "27", "subtraction": "53", "multiplication": "6"}[family]
        elif "operand slot /b" in prompt:
            wanted = {"addition": "15", "subtraction": "18", "multiplication": "7"}[family]
        elif "student's final answer" in prompt:
            wanted = {"addition": "42", "subtraction": "35", "multiplication": "42"}[family]
        else:
            raise AssertionError("fixture received an unexpected question")

        letter = next(
            (letter for letter, label in choices if label == wanted or label.startswith(wanted + " [")),
            None,
        )
        if letter is None:
            raise AssertionError(f"fixture answer {wanted!r} is absent from the choices")
        return {"response": letter, "done": True, "done_reason": "stop", "eval_count": 1}


def load_smoke_items(limit: int) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    data = json.loads(SMOKE_ITEMS.read_text(encoding="utf-8"))
    if data.get("schema") != 1 or "invented" not in data.get("authorship", ""):
        raise ValueError("smoke-item authorship or schema is missing")
    items = data.get("items", [])
    if not isinstance(items, list) or not items:
        raise ValueError("smoke set has no items")
    if limit < 1 or limit > len(items):
        raise ValueError(f"items must be between 1 and {len(items)}")
    return data, items[:limit]


def item_row(
    item: dict[str, Any],
    result: Any,
    attempts: list[dict[str, Any]],
    probes: list[dict[str, Any]],
) -> dict[str, Any]:
    leaf_calls = [event for event in result.ledger if event.get("kind") == "leaf_call"]
    return {
        "record_type": "item",
        "item_id": item["id"],
        "source": "authored_invented_smoke_item",
        "expected_family": item["family"],
        "result_status": result.status,
        "resolved_family": result.family,
        "excerpt_sha256": result.excerpt_sha256,
        "question_sequence": probes,
        "letters": [attempt["parsed_letter"] for attempt in attempts if attempt["parsed_letter"]],
        "abstentions": [attempt for attempt in attempts if attempt["abstention"]],
        "leaf_operation_invocations": leaf_calls,
        "latencies_ms": [attempt["latency_ms"] for attempt in attempts],
        "model_attempts": attempts,
        "runner": result.to_dict(),
    }


def summarize(
    *,
    mode: str,
    model: str,
    items_requested: int,
    item_rows: list[dict[str, Any]],
) -> dict[str, Any]:
    attempts = [attempt for row in item_rows for attempt in row["model_attempts"]]
    probes = [probe for row in item_rows for probe in row["question_sequence"]]
    total = len(attempts)
    exact = sum(attempt["raw_exact_one_letter"] is True for attempt in attempts)
    parsed = sum(attempt["parse_ok"] is True for attempt in attempts)
    stops_observed = [attempt for attempt in attempts if attempt["reply_stops_honored"] is not None]
    stops_honored = sum(attempt["reply_stops_honored"] is True for attempt in stops_observed)
    requests_exact = sum(attempt["request_contract_exact"] is True for attempt in attempts)
    within_latency = sum(attempt["latency_within_bound"] is True for attempt in attempts)
    non_ok_transport = sum(
        attempt["status"] in {"truncated", "empty_content", "error"}
        for attempt in attempts
    )
    parse_anomalies = sum(attempt["status"] == "invalid_content" for attempt in attempts)
    non_ok_content_parsed = sum(
        attempt["status"] != "ok" and attempt["parsed_letter"] is not None
        for attempt in attempts
    )
    flips = sum(probe["flip"] for probe in probes)
    uncomparable = sum(not probe["comparable"] for probe in probes)
    threshold = 0.90
    exact_rate = exact / total if total else 0.0
    parsed_rate = parsed / total if total else 0.0
    all_items_leaf = all(row["result_status"] == "leaf_computed" for row in item_rows)
    passed = (
        total > 0
        and exact_rate >= threshold
        and requests_exact == total
        and stops_honored == len(stops_observed)
        and within_latency == total
        and non_ok_content_parsed == 0
        and flips == 0
        and all_items_leaf
    )
    return {
        "record_type": "summary",
        "schema": "questionnaire_compliance_smoke_v1",
        "mode": mode,
        "model": model,
        "items_requested": items_requested,
        "items_completed": len(item_rows),
        "leaf_items": sum(row["result_status"] == "leaf_computed" for row in item_rows),
        "model_calls": total,
        "contract_compliance": {
            "valid_letter": {
                "count": exact,
                "total": total,
                "rate": exact_rate,
                "threshold": threshold,
                "definition": "raw output is exactly one listed letter",
            },
            "parsed_valid_letter": {
                "count": parsed,
                "total": total,
                "rate": parsed_rate,
            },
            "reply_stops_honored": {
                "count": stops_honored,
                "observed": len(stops_observed),
            },
            "request_contract_exact": {"count": requests_exact, "total": total},
            "non_ok_transport": {"count": non_ok_transport, "total": total},
            "parse_anomaly": {"count": parse_anomalies, "total": total},
            "latency_within_bound": {
                "count": within_latency,
                "total": total,
                "bound_ms": attempts[0]["latency_bound_ms"] if attempts else None,
            },
            "position_permutation": {
                "pairs": len(probes),
                "comparable": len(probes) - uncomparable,
                "uncomparable": uncomparable,
                "flips": flips,
            },
            "non_ok_content_parsed": non_ok_content_parsed,
        },
        "pass": passed,
    }


def write_rows(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(
        "".join(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n" for row in rows),
        encoding="utf-8",
    )
    temporary.replace(path)


def run(args: argparse.Namespace) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    metadata, items = load_smoke_items(args.items)
    del metadata
    base = OllamaQuestionnaireClient(
        model=args.model,
        endpoint=args.endpoint,
        timeout=args.timeout,
        transport=WorkedItemFixtureTransport() if args.fixture else None,
    )
    probing = PositionProbeClient(base)
    compiled = None
    symbolic: Any = None
    rows: list[dict[str, Any]] = []
    try:
        if args.fixture:
            from build_choice_sets import compile_choice_sets

            compiled = compile_choice_sets()
            symbolic = FixtureHermes(compiled)
        else:
            symbolic = StdioHermesClient()

        for item in items:
            attempt_start = len(base.attempts)
            probe_start = len(probing.probes)
            runner = QuestionnaireRunner(probing, symbolic=symbolic, compiled=compiled)
            result = runner.run(item["excerpt"])
            attempts = [attempt.to_dict() for attempt in base.attempts[attempt_start:]]
            probes = probing.probes[probe_start:]
            rows.append(item_row(item, result, attempts, probes))
    finally:
        if symbolic is not None:
            symbolic.close()

    summary = summarize(
        mode="fixture" if args.fixture else "live",
        model=args.model,
        items_requested=len(items),
        item_rows=rows,
    )
    return rows, summary


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fixture", action="store_true", help="use injected offline fixtures")
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--endpoint", default=DEFAULT_ENDPOINT)
    parser.add_argument("--timeout", type=float, default=300.0)
    parser.add_argument("--items", type=int, default=3)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    if args.fixture:
        socket_count = 0

        def forbidden_socket(*unused_args: Any, **unused_kwargs: Any) -> Any:
            nonlocal socket_count
            socket_count += 1
            raise AssertionError("fixture compliance smoke attempted to open a socket")

        with patch("socket.socket", forbidden_socket):
            rows, summary = run(args)
        if socket_count:
            raise AssertionError("fixture compliance smoke opened a socket")
    else:
        rows, summary = run(args)

    all_rows = [*rows, summary]
    write_rows(args.output, all_rows)
    check_rows(all_rows)
    print(
        "QUESTIONNAIRE COMPLIANCE SMOKE: PASS "
        f"mode={summary['mode']} items={summary['items_completed']} "
        f"calls={summary['model_calls']} "
        f"valid_letter_rate={summary['contract_compliance']['valid_letter']['rate']:.1%} "
        f"position_flips={summary['contract_compliance']['position_permutation']['flips']}"
    )
    print(f"ledger: {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
