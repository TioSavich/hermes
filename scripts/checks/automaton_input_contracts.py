#!/usr/bin/env python3
"""Validate action-automaton input contracts and re-run their examples."""
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
REGISTRY = ROOT / "knowledge/strategies/math/action_automata_registry.pl"
CONTRACTS = ROOT / "knowledge/strategies/automaton_input_contracts.pl"

SIGNATURE = re.compile(
    r"action_automaton_signature\(\s*([a-z][a-z0-9_]*)\s*,\s*"
    r"([a-z][a-z0-9_]*)\s*,",
    re.MULTILINE,
)
CONTRACT = re.compile(
    r"automaton_input_contract\(\s*([a-z][a-z0-9_]*)\s*,\s*"
    r"([a-z][a-z0-9_]*)\s*,\s*'((?:\\.|[^'])*)'\s*,\s*"
    r"'((?:\\.|[^'])*)'\s*,\s*verified\(([^)]*)\)\)\.",
    re.MULTILINE,
)


def decode_json(raw: str, label: str) -> Any:
    try:
        return json.loads(raw.replace(r"\"", '"'))
    except json.JSONDecodeError as exc:
        raise ValueError(f"{label} is not valid JSON: {exc}") from exc


def contracts() -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for operation, kind, raw_shape, raw_example, verification in CONTRACT.findall(
        CONTRACTS.read_text(encoding="utf-8")
    ):
        label = f"{operation}/{kind}"
        rows.append(
            {
                "operation": operation,
                "kind": kind,
                "shape": decode_json(raw_shape, f"{label} shape"),
                "example": decode_json(raw_example, f"{label} example"),
                "verification": verification,
            }
        )
    return rows


def is_integer(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def shape_errors(shape: Any, example: Any, path: str = "$") -> list[str]:
    if isinstance(shape, dict):
        if not isinstance(example, dict):
            return [f"{path}: expected object"]
        errors: list[str] = []
        missing = sorted(set(shape) - set(example))
        extra = sorted(set(example) - set(shape))
        if missing:
            errors.append(f"{path}: missing keys {missing}")
        if extra:
            errors.append(f"{path}: undeclared keys {extra}")
        for key in shape.keys() & example.keys():
            errors.extend(shape_errors(shape[key], example[key], f"{path}.{key}"))
        return errors

    if isinstance(shape, list):
        if not isinstance(example, list):
            return [f"{path}: expected array"]
        if len(shape) != 1:
            return [f"{path}: array shape must contain one item schema"]
        errors = []
        for index, item in enumerate(example):
            errors.extend(shape_errors(shape[0], item, f"{path}[{index}]"))
        return errors

    if shape == "integer":
        return [] if is_integer(example) else [f"{path}: expected integer"]
    if shape == "positive_integer":
        return [] if is_integer(example) and example > 0 else [f"{path}: expected positive integer"]
    if shape == "number":
        return [] if isinstance(example, (int, float)) and not isinstance(example, bool) else [f"{path}: expected number"]
    if shape == "positive_number":
        return (
            []
            if isinstance(example, (int, float)) and not isinstance(example, bool) and example > 0
            else [f"{path}: expected positive number"]
        )
    if shape in {"atom", "string"}:
        return [] if isinstance(example, str) and bool(example) else [f"{path}: expected nonempty string"]
    return [] if example == shape else [f"{path}: expected literal {shape!r}"]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--trace-output",
        type=Path,
        help="write the live worker responses to this runtime evidence file",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    signatures = SIGNATURE.findall(REGISTRY.read_text(encoding="utf-8"))
    signature_set = set(signatures)
    rows = contracts()
    failures: list[str] = []

    signature_duplicates = sorted(
        pair for pair, count in Counter(signatures).items() if count > 1
    )
    contract_pairs = [(row["operation"], row["kind"]) for row in rows]
    contract_duplicates = sorted(
        pair for pair, count in Counter(contract_pairs).items() if count > 1
    )
    if signature_duplicates:
        failures.append(f"duplicate registry signatures: {signature_duplicates}")
    if contract_duplicates:
        failures.append(f"duplicate input contracts: {contract_duplicates}")

    for row in rows:
        pair = (row["operation"], row["kind"])
        label = f"{pair[0]}/{pair[1]}"
        if pair not in signature_set:
            failures.append(f"{label}: contract is not a registered signature")
        for error in shape_errors(row["shape"], row["example"]):
            failures.append(f"{label}: {error}")
        if row["verification"] != "strategy_trace_ok":
            failures.append(
                f"{label}: unsupported verification method {row['verification']!r}"
            )

    traces: list[dict[str, Any]] = []
    if not failures:
        sys.path.insert(0, str(ROOT))
        from hermes.mcp.server import HermesMCPServer

        server = HermesMCPServer("core", ROOT)
        try:
            for row in rows:
                label = f"{row['operation']}/{row['kind']}"
                try:
                    response = server._worker_request(
                        "strategy_trace",
                        strategy=row["kind"],
                        input=row["example"],
                    )
                except Exception as exc:
                    failures.append(f"{label}: live strategy_trace raised {exc}")
                    continue
                steps = response.get("steps") if isinstance(response, dict) else None
                if not isinstance(response, dict) or response.get("ok") is not True:
                    failures.append(f"{label}: live strategy_trace did not return ok:true")
                elif not isinstance(steps, list) or not steps:
                    failures.append(f"{label}: live strategy_trace returned no trace steps")
                traces.append(
                    {
                        "operation": row["operation"],
                        "kind": row["kind"],
                        "input": row["example"],
                        "response": response,
                    }
                )
        finally:
            server.close()

    if args.trace_output is not None:
        args.trace_output.parent.mkdir(parents=True, exist_ok=True)
        args.trace_output.write_text(
            json.dumps(
                {
                    "contracts": len(rows),
                    "registered_signatures": len(signature_set),
                    "remaining_gap": len(signature_set - set(contract_pairs)),
                    "traces": traces,
                },
                indent=2,
                sort_keys=True,
            )
            + "\n",
            encoding="utf-8",
        )

    print(
        "automaton-input-contracts: "
        f"contracts={len(rows)} "
        f"registered-signatures={len(signature_set)} "
        f"remaining-gap={len(signature_set - set(contract_pairs))} "
        f"verified-live={len(traces)}"
    )
    for failure in failures:
        print(f"FAIL: {failure}", file=sys.stderr)
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
