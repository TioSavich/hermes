#!/usr/bin/env python3
"""Inventory evidence and recognizer coverage for every automaton signature."""
from __future__ import annotations

import argparse
import importlib.util
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
BUILDER = ROOT / "scripts" / "research" / "build_transition_tables.py"
TABLE_DIR = ROOT / "knowledge" / "strategies" / "transition_tables"


def load_builder() -> Any:
    spec = importlib.util.spec_from_file_location(
        "recognizer_transition_builder", BUILDER
    )
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import {BUILDER}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def observed_contract_signatures() -> set[tuple[str, str]]:
    found: set[tuple[str, str]] = set()
    marker = "provenance(observed(contract_example))"
    for path in sorted(TABLE_DIR.glob("*.pl")):
        for line in path.read_text(encoding="utf-8").splitlines():
            if marker not in line or not line.startswith("automaton_transition("):
                continue
            prefix = line.split("(", 1)[1].split(",", 2)
            if len(prefix) >= 2:
                found.add((prefix[0].strip(), prefix[1].strip()))
    return found


def evidence_class(
    key: tuple[str, str],
    observed_keys: set[tuple[str, str]],
    contract_keys: set[tuple[str, str]],
    table_keys: set[tuple[str, str]],
) -> str:
    if key in observed_keys:
        return "execution-observed"
    if key in contract_keys:
        return "contract-only"
    if key in table_keys:
        return "static-extraction-only"
    return "signature-only"


def recognizer_skip_reason(evidence: str) -> str | None:
    if evidence == "execution-observed":
        return None
    if evidence == "contract-only":
        return "input contract has no executed transition witness"
    if evidence == "static-extraction-only":
        return "static generator extraction is not transcript evidence"
    return "registry signature has no transition table or executed witness"


def inventory() -> dict[str, Any]:
    builder = load_builder()
    signatures = builder.SIGNATURE.findall(
        builder.REGISTRY.read_text(encoding="utf-8")
    )
    tables, skipped, _routes = builder.build()
    table_keys = {(table.operation, table.kind) for table in tables}
    contract_keys = {
        (contract.operation, contract.kind) for contract in builder.contracts()
    }
    observed_keys = observed_contract_signatures()
    extraction_skip_reasons = {
        (operation, kind): reason for operation, kind, reason in skipped
    }

    rows: list[dict[str, Any]] = []
    family_counts: dict[str, Counter[str]] = defaultdict(Counter)
    for operation, kind in signatures:
        key = (operation, kind)
        evidence = evidence_class(
            key, observed_keys, contract_keys, table_keys
        )
        covered = evidence == "execution-observed"
        status = "covered" if covered else "skipped"
        reason = recognizer_skip_reason(evidence)
        family_counts[operation]["signatures"] += 1
        family_counts[operation][status] += 1
        if evidence == "execution-observed":
            family_counts[operation]["execution_observed"] += 1
        rows.append(
            {
                "operation": operation,
                "kind": kind,
                "evidence_class": evidence,
                "has_static_table": key in table_keys,
                "has_input_contract": key in contract_keys,
                "has_observed_contract_trace": key in observed_keys,
                "transition_extraction_skip_reason":
                    extraction_skip_reasons.get(key),
                "recognizer_status": status,
                "recognizer_skip_reason": reason,
            }
        )

    evidence_counts = Counter(row["evidence_class"] for row in rows)
    coverage_counts = Counter(row["recognizer_status"] for row in rows)
    return {
        "schema": "hermes_automaton_recognizer_inventory_v2",
        "counts": {
            "signatures": len(signatures),
            "static_tables": len(table_keys),
            "input_contracts": len(contract_keys),
            "observed_contract_traces": len(observed_keys),
            **dict(sorted(evidence_counts.items())),
            "recognizer_covered": coverage_counts["covered"],
            "recognizer_skipped": coverage_counts["skipped"],
        },
        "family_coverage": [
            {
                "operation": operation,
                "signatures": counts["signatures"],
                "execution_observed": counts["execution_observed"],
                "covered": counts["covered"],
                "skipped": counts["skipped"],
            }
            for operation, counts in sorted(family_counts.items())
        ],
        "rows": rows,
    }


def verify(result: dict[str, Any]) -> None:
    counts = result["counts"]
    evidence_total = sum(
        counts.get(label, 0)
        for label in (
            "execution-observed",
            "contract-only",
            "static-extraction-only",
            "signature-only",
        )
    )
    if counts["signatures"] != evidence_total:
        raise RuntimeError("evidence classes do not partition the registry")
    if counts["recognizer_covered"] != counts["execution-observed"]:
        raise RuntimeError(
            "recognizer coverage must equal execution-observed coverage"
        )
    if counts["recognizer_covered"] != 69:
        raise RuntimeError(
            "expected 69 execution-observed recognizers, got "
            f"{counts['recognizer_covered']}"
        )
    if counts["recognizer_covered"] + counts["recognizer_skipped"] != (
        counts["signatures"]
    ):
        raise RuntimeError("recognizer states do not partition the registry")

    for row in result["rows"]:
        if row["recognizer_status"] == "covered":
            if row["evidence_class"] != "execution-observed":
                raise RuntimeError(
                    "recognizer is covered without executed evidence: "
                    + json.dumps(row, ensure_ascii=False)
                )
            if row["recognizer_skip_reason"] is not None:
                raise RuntimeError(
                    "covered recognizer has a skip reason: "
                    + json.dumps(row, ensure_ascii=False)
                )
        elif not row["recognizer_skip_reason"]:
            raise RuntimeError(
                "skipped recognizer lacks a reason: "
                + json.dumps(row, ensure_ascii=False)
            )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    result = inventory()
    if args.check:
        verify(result)
    text = json.dumps(result, indent=2, ensure_ascii=False) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text, encoding="utf-8")
    else:
        print(text, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
