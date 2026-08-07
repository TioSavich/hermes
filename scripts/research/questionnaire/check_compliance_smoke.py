#!/usr/bin/env python3
"""Check a questionnaire compliance-smoke JSONL ledger."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Iterable


def load_rows(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip():
            continue
        value = json.loads(line)
        if not isinstance(value, dict):
            raise ValueError(f"ledger line {line_number} is not a JSON object")
        rows.append(value)
    return rows


def check_rows(rows: Iterable[dict[str, Any]]) -> dict[str, Any]:
    material = list(rows)
    summaries = [row for row in material if row.get("record_type") == "summary"]
    if len(summaries) != 1:
        raise AssertionError(f"expected one summary row, found {len(summaries)}")
    summary = summaries[0]
    items = [row for row in material if row.get("record_type") == "item"]
    if len(items) != summary.get("items_completed"):
        raise AssertionError("item-row count does not match the summary")

    attempts = [attempt for item in items for attempt in item.get("model_attempts", [])]
    if len(attempts) != summary.get("model_calls"):
        raise AssertionError("model-attempt count does not match the summary")
    for attempt in attempts:
        if attempt.get("status") != "ok" and attempt.get("parsed_letter") is not None:
            raise AssertionError("non-ok model content entered the parsed-letter lane")

    compliance = summary.get("contract_compliance", {})
    valid = compliance.get("valid_letter", {})
    exact_count = sum(attempt.get("raw_exact_one_letter") is True for attempt in attempts)
    exact_rate = exact_count / len(attempts) if attempts else 0.0
    if valid.get("count") != exact_count or valid.get("total") != len(attempts):
        raise AssertionError("valid-letter summary counts do not match the item records")
    if abs(float(valid.get("rate", -1.0)) - exact_rate) > 1e-12:
        raise AssertionError("valid-letter summary rate does not match the item records")
    if exact_rate < valid.get("threshold", 0.9):
        raise AssertionError("valid-letter rate is below the registered 90% gate")
    non_ok_content_parsed = sum(
        attempt.get("status") != "ok" and attempt.get("parsed_letter") is not None
        for attempt in attempts
    )
    if compliance.get("non_ok_content_parsed") != non_ok_content_parsed:
        raise AssertionError("non-ok parsed-content summary does not match the item records")
    if non_ok_content_parsed != 0:
        raise AssertionError("non-ok content was parsed")
    probes = [probe for item in items for probe in item.get("question_sequence", [])]
    flips = sum(probe.get("flip") is True for probe in probes)
    if compliance.get("position_permutation", {}).get("flips") != flips:
        raise AssertionError("position-flip summary does not match the item records")
    if flips != 0:
        raise AssertionError("a position permutation changed a semantic answer")
    if not summary.get("pass"):
        raise AssertionError("summary compliance gate is not passing")
    return summary


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ledger", type=Path)
    args = parser.parse_args()
    summary = check_rows(load_rows(args.ledger))
    print(
        "QUESTIONNAIRE COMPLIANCE LEDGER: PASS "
        f"items={summary['items_completed']} calls={summary['model_calls']} "
        f"valid_letter_rate={summary['contract_compliance']['valid_letter']['rate']:.1%}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
