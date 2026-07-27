#!/usr/bin/env python3
"""Join MathTutorBench problem-solving rows to Prolog-arm failure records."""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
from decimal import Decimal, InvalidOperation
import json
from pathlib import Path
import sys
from typing import Any

ITEM_PREFIX = "MTB_PROLOG_ITEM "


def _index_records(
    rows: list[tuple[int, dict[str, Any]]], *, source: Path, required: set[str],
) -> dict[int, dict[str, Any]]:
    """Index decoded records by position and reject malformed duplicates."""
    records: dict[int, dict[str, Any]] = {}
    for line_number, record in rows:
        if not isinstance(record, dict) or not required <= record.keys():
            raise ValueError(f"{source}:{line_number}: missing {sorted(required)}")
        position = record["position"]
        if not isinstance(position, int) or position < 0:
            raise ValueError(f"{source}:{line_number}: invalid position")
        if position in records:
            raise ValueError(f"{source}:{line_number}: duplicate position {position}")
        records[position] = record
    return records


def _read_jsonl(path: Path, *, required: set[str]) -> dict[int, dict[str, Any]]:
    """Read position-keyed JSONL and reject malformed or duplicate records."""
    rows: list[tuple[int, dict[str, Any]]] = []
    with path.open(encoding="utf-8") as handle:
        for line_number, line in enumerate(handle, start=1):
            if not line.strip():
                continue
            try:
                record = json.loads(line)
            except json.JSONDecodeError as exc:
                raise ValueError(f"{path}:{line_number}: invalid JSON") from exc
            rows.append((line_number, record))
    return _index_records(rows, source=path, required=required)


def read_item_records(path: Path) -> dict[int, dict[str, Any]]:
    """Read only captured responder item lines, ignoring unrelated stderr."""
    selected: list[tuple[int, dict[str, Any]]] = []
    with path.open(encoding="utf-8") as handle:
        for line_number, line in enumerate(handle, start=1):
            if not line.startswith(ITEM_PREFIX):
                continue
            payload = line.removeprefix(ITEM_PREFIX)
            try:
                record = json.loads(payload)
            except json.JSONDecodeError as exc:
                raise ValueError(f"{path}:{line_number}: invalid MTB_PROLOG_ITEM") from exc
            selected.append((line_number, record))
    return _index_records(selected, source=path, required={"position", "outcome"})


def _is_correct(prediction: Any, target: Any) -> bool:
    """Use the benchmark's numeric tolerance for its parsed answer strings."""
    if prediction is None or target is None:
        return False
    try:
        return abs(Decimal(str(prediction)) - Decimal(str(target))) < Decimal("0.000001")
    except (InvalidOperation, ValueError):
        return False


def build_report(
    runner_rows: dict[int, dict[str, Any]], item_rows: dict[int, dict[str, Any]],
) -> dict[str, Any]:
    """Cross each responder outcome with correctness after a complete join."""
    runner_positions = set(runner_rows)
    item_positions = set(item_rows)
    if runner_positions != item_positions:
        raise ValueError(
            "position mismatch: "
            f"runner_only={sorted(runner_positions - item_positions)} "
            f"items_only={sorted(item_positions - runner_positions)}"
        )
    crossed: dict[str, Counter[str]] = defaultdict(Counter)
    for position in sorted(runner_positions):
        item = item_rows[position]
        runner = runner_rows[position]
        correctness = "correct" if _is_correct(runner["prediction"], runner["target"]) else "incorrect"
        crossed[str(item["outcome"])][correctness] += 1
    items = len(runner_positions)
    ran = sum(
        crossed[outcome]["correct"] + crossed[outcome]["incorrect"]
        for outcome in ("ran", "ran_grounded")
    )
    return {
        "items": items,
        "ran_rate": ran / items if items else 0.0,
        "outcomes": {
            outcome: {
                "correct": counts["correct"],
                "incorrect": counts["incorrect"],
            }
            for outcome, counts in sorted(crossed.items())
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out-dir", type=Path, required=True)
    parser.add_argument("--items", type=Path, required=True,
                        help="captured stderr containing MTB_PROLOG_ITEM lines")
    args = parser.parse_args()
    try:
        runner_rows = _read_jsonl(
            args.out_dir / "problem_solving.jsonl",
            required={"position", "prediction", "target"},
        )
        item_rows = read_item_records(args.items)
        report = build_report(runner_rows, item_rows)
    except (OSError, ValueError) as exc:
        print(f"prolog_arm_report.py: {exc}", file=sys.stderr)
        return 2
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
