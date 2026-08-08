#!/usr/bin/env python3
"""Score completed A-vs-Q ledgers without model or network access."""
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Any, Iterable, Mapping


HERE = Path(__file__).resolve().parent
ROOT = Path(__file__).resolve().parents[3]
RUNTIME_ROOT = ROOT / "hermes/app/runtime/experiments/ab_2026_08"
DEFAULT_RUN_ID = "ab_2026_08"
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))

from corpus import RunItem, load_corpus  # noqa: E402
from ledger import combined_rows, validate_row  # noqa: E402


TOOLS = frozenset({
    "quantity_claim:check_quantity_expression/3",
    "check_solution_steps",
    "strategy_trace",
    "strategy_recognize",
})
FALSIFIER_Q = (
    "zero licensed differentiating receipts from arm Q across all 60 pairs "
    "falsifies the questionnaire for this corpus shape."
)
FALSIFIER_BOTH = "Zero from both arms falsifies both candidates at the extraction seam (ceiling report:414-416)."


def _identity(arm: str, receipt: dict[str, Any]) -> tuple[str, str, str]:
    return arm, str(receipt.get("verdict")), str(receipt.get("normalized_claim"))


def _tool_licensed(receipt: dict[str, Any]) -> bool:
    tool = receipt.get("tool")
    if tool in TOOLS:
        return True
    return (
        tool == "prolog_query"
        and receipt.get("registered_call") == "misconception_registry:rule_builds/4"
    )


def _receipt_reason(row: dict[str, Any], receipt: Any) -> str | None:
    if not isinstance(receipt, dict):
        return "not_object"
    step = receipt.get("step")
    if isinstance(step, bool) or not isinstance(step, int) or not 1 <= step <= len(row["steps"]):
        return "invalid_step"
    span = receipt.get("source_span")
    if not isinstance(span, str) or not span or span not in row["steps"][step - 1]:
        return "non_verbatim_span"
    if not _tool_licensed(receipt):
        return "unregistered_tool"
    verdict = receipt.get("verdict")
    if not isinstance(verdict, str) or not verdict or verdict == "not_checked":
        return "not_checked_verdict"
    claim = receipt.get("normalized_claim")
    if not isinstance(claim, str) or not claim:
        return "missing_normalized_claim"
    return None


def _coverage(rows: list[dict[str, Any]], indexes: Iterable[int]) -> None:
    expected = {
        (arm, index, side)
        for arm in ("compiler", "questionnaire")
        for index in indexes
        for side in ("incorrect", "correct")
    }
    actual = {(row["arm"], row["index"], row["side"]) for row in rows}
    if actual != expected:
        missing = sorted(expected - actual)
        extra = sorted(actual - expected)
        raise ValueError(f"ledger coverage mismatch: missing={missing!r} extra={extra!r}")


def _cost(rows: list[dict[str, Any]], arm: str) -> dict[str, int]:
    names = ("model_calls", "prompt_tokens", "completion_tokens", "total_tokens")
    return {
        name: sum(row["usage"][name] for row in rows if row["arm"] == arm)
        for name in names
    }


def _lower_cost(left: dict[str, int], right: dict[str, int]) -> bool:
    return (
        left["model_calls"] <= right["model_calls"]
        and left["total_tokens"] <= right["total_tokens"]
        and (
            left["model_calls"] < right["model_calls"]
            or left["total_tokens"] < right["total_tokens"]
        )
    )


def _expected_steps(items: Iterable[RunItem]) -> dict[tuple[int, str], list[str]]:
    return {(item.index, item.side): list(item.steps) for item in items}


def _instrument_counts(rows: list[dict[str, Any]]) -> dict[str, int]:
    return {
        arm: sum(
            event.get("kind") == "symbolic_leaf" and event.get("success") is True
            for row in rows
            if row["arm"] == arm
            for event in row["events"]
            if isinstance(event, dict)
        )
        for arm in ("compiler", "questionnaire")
    }


def score_rows(
    rows: list[dict[str, Any]],
    *,
    indexes: Iterable[int],
    expected_steps: Mapping[tuple[int, str], list[str]],
    run_id: str = "fixture",
) -> tuple[dict[str, Any], list[str]]:
    for row in rows:
        validate_row(row)
        key = (row["index"], row["side"])
        expected = expected_steps.get(key)
        if expected is None:
            raise ValueError(
                f"scorer has no corpus-derived steps for index={row['index']} side={row['side']}"
            )
        if row["steps"] != expected:
            raise ValueError(
                "scorer step mismatch: "
                f"arm={row['arm']} index={row['index']} side={row['side']} "
                f"ledger={row['steps']!r} corpus={expected!r}"
            )
    _coverage(rows, indexes)
    by_key = {(row["arm"], row["index"], row["side"]): row for row in rows}
    licensed: dict[str, list[dict[str, Any]]] = {"compiler": [], "questionnaire": []}
    rejected: dict[str, Counter[str]] = {
        "compiler": Counter(),
        "questionnaire": Counter(),
    }
    for row in rows:
        if row["side"] != "incorrect":
            continue
        paired = by_key[(row["arm"], row["index"], "correct")]
        paired_identities = {
            _identity(row["arm"], receipt)
            for receipt in paired["receipts"]
            if isinstance(receipt, dict)
        }
        accused_steps: set[int] = set()
        for receipt in row["receipts"]:
            reason = _receipt_reason(row, receipt)
            if reason is None and _identity(row["arm"], receipt) in paired_identities:
                reason = "present_on_paired_correct"
            if reason is not None:
                rejected[row["arm"]][reason] += 1
                continue
            if (
                isinstance(receipt, dict)
                and receipt.get("accusation") is True
                and isinstance(receipt.get("step"), int)
            ):
                if receipt["step"] in accused_steps:
                    rejected[row["arm"]]["duplicate_accusation"] += 1
                    continue
                accused_steps.add(receipt["step"])
            licensed[row["arm"]].append({
                "index": row["index"],
                "step": receipt["step"],
                "identity": list(_identity(row["arm"], receipt)),
            })

    accusations = {
        arm: len({
            (row["index"], row["side"], receipt.get("step"))
            for row in rows
            if row["arm"] == arm and row["side"] == "correct"
            for receipt in row["receipts"]
            if isinstance(receipt, dict) and receipt.get("accusation") is True
        })
        for arm in ("compiler", "questionnaire")
    }
    receipt_counts = {arm: len(values) for arm, values in licensed.items()}
    costs = {arm: _cost(rows, arm) for arm in ("compiler", "questionnaire")}
    trace: list[str] = []
    selected: str | None = None
    tier = "tie"
    instrument_counts = _instrument_counts(rows)
    instrument_valid = {
        arm: count > 0 for arm, count in instrument_counts.items()
    }
    for arm in ("compiler", "questionnaire"):
        if not instrument_valid[arm]:
            trace.append(
                f"INSTRUMENT FAILURE: arm={arm} successful_symbolic_leaves=0"
            )
    if not all(instrument_valid.values()):
        tier = "instrument_failure"
        trace.append("DECISION: suppressed because an arm failed the instrument precondition")
    else:
        trace.append(
            "T1 correct-solution accusations: "
            f"compiler={accusations['compiler']} questionnaire={accusations['questionnaire']}"
        )
        if accusations["compiler"] != accusations["questionnaire"]:
            selected = min(accusations, key=accusations.get)  # type: ignore[arg-type]
            tier = "T1"
            trace.append(f"T1 decision: {selected}")
            trace.append("T2 decision: not reached")
            trace.append("T3 decision: not reached")
        else:
            trace.append("T1 decision: tied")
            trace.append(
                "T2 licensed differentiating receipts: "
                f"compiler={receipt_counts['compiler']} questionnaire={receipt_counts['questionnaire']}"
            )
            if receipt_counts["compiler"] != receipt_counts["questionnaire"]:
                selected = max(receipt_counts, key=receipt_counts.get)  # type: ignore[arg-type]
                tier = "T2"
                trace.append(f"T2 decision: {selected}")
                trace.append("T3 decision: not reached")
            else:
                trace.append("T2 decision: tied")
                trace.append(
                    "T3 model calls/tokens: "
                    f"compiler={costs['compiler']['model_calls']}/{costs['compiler']['total_tokens']} "
                    f"questionnaire={costs['questionnaire']['model_calls']}/{costs['questionnaire']['total_tokens']}"
                )
                if _lower_cost(costs["compiler"], costs["questionnaire"]):
                    selected, tier = "compiler", "T3"
                elif _lower_cost(costs["questionnaire"], costs["compiler"]):
                    selected, tier = "questionnaire", "T3"
                trace.append(f"T3 decision: {selected or 'tied'}")

    if instrument_valid["questionnaire"] and receipt_counts["questionnaire"] == 0:
        trace.append(FALSIFIER_Q)
    if (
        all(instrument_valid.values())
        and receipt_counts["questionnaire"] == 0
        and receipt_counts["compiler"] == 0
    ):
        trace.append(FALSIFIER_BOTH)
    summary = {
        "schema": "ab_experiment_summary_v1",
        "run_id": run_id,
        "decision": {"tier": tier, "selected_arm": selected},
        "instrument": {
            arm: {
                "valid": instrument_valid[arm],
                "successful_symbolic_leaves": instrument_counts[arm],
            }
            for arm in ("compiler", "questionnaire")
        },
        "correct_solution_accusations": accusations,
        "licensed_differentiating_receipts": receipt_counts,
        "rejected_receipts": {
            arm: dict(sorted(counts.items())) for arm, counts in rejected.items()
        },
        "usage": costs,
        "licensed_receipts": licensed,
        "decision_trace": trace,
    }
    return summary, trace


def write_summary(path: Path, summary: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(
        json.dumps(summary, ensure_ascii=False, sort_keys=True, indent=2) + "\n",
        encoding="utf-8",
    )
    temporary.replace(path)


def default_summary_path(run_id: str) -> Path:
    """Place the default summary under runtime with its run id in the name."""
    return RUNTIME_ROOT / f"summary-{run_id}.json"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--compiler-ledger", type=Path, required=True)
    parser.add_argument("--questionnaire-ledger", type=Path, required=True)
    parser.add_argument(
        "--run-id",
        default=DEFAULT_RUN_ID,
        help=f"safe run identifier used in the summary filename (default: {DEFAULT_RUN_ID})",
    )
    parser.add_argument("--summary", type=Path)
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9._-]+", args.run_id):
        raise SystemExit("run id may contain only letters, digits, dot, underscore, and hyphen")
    summary_path = args.summary or default_summary_path(args.run_id)
    if args.run_id not in summary_path.name:
        raise SystemExit("summary filename must contain the run id")
    if not summary_path.resolve().is_relative_to(RUNTIME_ROOT.resolve()):
        raise SystemExit(f"summary must be written under {RUNTIME_ROOT}")
    rows = combined_rows([args.compiler_ledger, args.questionnaire_ledger])
    items = load_corpus()
    summary, trace = score_rows(
        rows,
        indexes=[item.index for item in items if item.side == "incorrect"],
        expected_steps=_expected_steps(items),
        run_id=args.run_id,
    )
    for line in trace:
        print(line)
    write_summary(summary_path, summary)
    print(f"summary: {summary_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
