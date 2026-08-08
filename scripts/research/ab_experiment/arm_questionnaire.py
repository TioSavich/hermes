#!/usr/bin/env python3
"""Run the shipped questionnaire once per step excerpt and emit receipts."""
from __future__ import annotations

import argparse
import json
import sys
from fractions import Fraction
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[3]
QUESTIONNAIRE = ROOT / "scripts/research/questionnaire"
HERE = Path(__file__).resolve().parent
for path in (str(QUESTIONNAIRE), str(HERE)):
    if path not in sys.path:
        sys.path.insert(0, path)

from build_choice_sets import CompiledChoiceSets, compile_choice_sets  # noqa: E402
from openai_compat_client import OpenAICompatibleQuestionnaireClient  # noqa: E402
from runner import (  # noqa: E402
    QuestionnaireRunner,
    StdioHermesClient,
    harvest_numerals,
    operator_family,
)

from corpus import RunItem, load_corpus  # noqa: E402
from ledger import AppendLedger, SCHEMA  # noqa: E402


DEFAULT_MODEL = "gemma-4-E2B-it"
DEFAULT_ENDPOINT = "http://127.0.0.1:8080/v1/chat/completions"


def _usage_copy(client: OpenAICompatibleQuestionnaireClient) -> dict[str, int]:
    return dict(client.usage)


def _usage_delta(
    client: OpenAICompatibleQuestionnaireClient, earlier: dict[str, int],
) -> dict[str, int]:
    return {name: client.usage[name] - earlier[name] for name in earlier}


def _number(value: Any) -> Fraction | None:
    if isinstance(value, bool):
        return None
    text = str(value).strip().replace(",", "")
    try:
        return Fraction(text)
    except (ValueError, ZeroDivisionError):
        return None


def _same_result(got: Any, licensed: Any) -> bool | None:
    got_number = _number(got)
    licensed_number = _number(licensed)
    if got_number is not None and licensed_number is not None:
        return got_number == licensed_number
    return None


def _claim(result: Any, step: str) -> str:
    leaf_call = next(
        (event for event in result.ledger if event.get("kind") == "leaf_call"),
        {},
    )
    value = {
        "strategy": leaf_call.get("strategy"),
        "operator": operator_family(step)[0] or "unknown",
    }
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def _licensed_value(leaf: dict[str, Any]) -> tuple[Any | None, str | None]:
    expected = leaf.get("expected")
    if expected not in (None, ""):
        return expected, None
    result = leaf.get("result")
    if leaf.get("validity") == "correct" and result not in (None, ""):
        return result, None
    return None, "licensed_value_absent"


def _has_comparable_licensed_value(result: Any) -> bool:
    if (
        result.status != "leaf_computed"
        or not isinstance(result.leaf, dict)
        or result.leaf.get("ok") is not True
        or result.got is None
    ):
        return False
    licensed, reason = _licensed_value(result.leaf)
    return reason is None and _same_result(result.got, licensed) is not None


def _receipt(
    result: Any, step: str, step_number: int,
) -> tuple[dict[str, Any] | None, dict[str, Any] | None]:
    if result.status != "leaf_computed" or not isinstance(result.leaf, dict):
        return None, None
    if result.leaf.get("ok") is not True:
        return None, {
            "kind": "symbolic_abstention",
            "step": step_number,
            "reason": "leaf_not_successful",
        }
    licensed, reason = _licensed_value(result.leaf)
    if reason is not None or result.got is None:
        return None, {
            "kind": "symbolic_abstention",
            "step": step_number,
            "reason": reason or "got_absent",
        }
    comparison = _same_result(result.got, licensed)
    if comparison is None:
        return None, {
            "kind": "symbolic_abstention",
            "step": step_number,
            "reason": "licensed_value_non_numeric",
            "licensed_result": licensed,
        }
    if comparison:
        return None, None
    return {
        "step": step_number,
        "source_span": step,
        "tool": "strategy_trace",
        "verdict": "refuted",
        "normalized_claim": _claim(result, step),
        "call": next(
            (event for event in result.ledger if event.get("kind") == "leaf_call"),
            {},
        ),
        "licensed_result": licensed,
        "got": result.got,
        "accusation": True,
    }, None


def run_item(
    item: RunItem,
    *,
    client: OpenAICompatibleQuestionnaireClient,
    symbolic: Any,
    compiled: CompiledChoiceSets,
) -> dict[str, Any]:
    usage_before = _usage_copy(client)
    events: list[dict[str, Any]] = []
    receipts: list[dict[str, Any]] = []
    runner = QuestionnaireRunner(client, symbolic=symbolic, compiled=compiled)
    for step_number, step in enumerate(item.steps, 1):
        if not harvest_numerals(step):
            events.append({"kind": "l0_skip", "step": step_number, "reason": "no_numerals"})
            continue
        attempt_start = len(client.attempts)
        result = runner.run(step)
        attempts = [attempt.to_dict() for attempt in client.attempts[attempt_start:]]
        events.append({
            "kind": "step_result",
            "step": step_number,
            "result": result.to_dict(),
            "transport": attempts,
        })
        leaf_ran = bool(
            result.status == "leaf_computed"
            and isinstance(result.leaf, dict)
            and result.leaf.get("ok") is True
        )
        leaf_success = _has_comparable_licensed_value(result)
        events.append({
            "kind": "symbolic_leaf",
            "tool": "strategy_trace",
            "step": step_number,
            "ran": leaf_ran,
            "comparable_licensed_value": leaf_success,
            "success": leaf_success,
        })
        receipt, abstention = _receipt(result, step, step_number)
        if receipt is not None:
            receipts.append(receipt)
        if abstention is not None:
            events.append(abstention)
    return {
        "schema": SCHEMA,
        "arm": "questionnaire",
        "index": item.index,
        "side": item.side,
        "problem": item.problem,
        "steps": list(item.steps),
        "receipts": receipts,
        "events": events,
        "usage": _usage_delta(client, usage_before),
    }


def run_items(
    items: list[RunItem],
    ledger: AppendLedger,
    *,
    client: OpenAICompatibleQuestionnaireClient,
    symbolic: Any | None = None,
    compiled: CompiledChoiceSets | None = None,
) -> tuple[int, int]:
    appended = skipped = 0
    owned_symbolic = symbolic is None
    symbolic = symbolic if symbolic is not None else StdioHermesClient()
    compiled = compiled if compiled is not None else compile_choice_sets()
    try:
        for item in items:
            if ledger.has("questionnaire", item.index, item.side):
                skipped += 1
                continue
            row = run_item(item, client=client, symbolic=symbolic, compiled=compiled)
            appended += int(ledger.append(row))
    finally:
        if owned_symbolic:
            symbolic.close()
    return appended, skipped


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ledger", type=Path, required=True)
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--endpoint", default=DEFAULT_ENDPOINT)
    parser.add_argument("--timeout", type=float, default=300.0)
    args = parser.parse_args()
    client = OpenAICompatibleQuestionnaireClient(
        model=args.model, endpoint=args.endpoint, timeout=args.timeout,
    )
    ledger = AppendLedger(args.ledger)
    appended, skipped = run_items(load_corpus(), ledger, client=client)
    print(
        f"ARM QUESTIONNAIRE: COMPLETE appended={appended} resumed={skipped} "
        f"ledger={args.ledger}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
