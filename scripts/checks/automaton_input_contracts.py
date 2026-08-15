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
# 2026-08-15. The two checks below this line read the registry and enumerate
# outward from it, so they can only ever report a registered kind that lacks a
# contract. A machine that files no signature at all was outside what they
# could count: contracts and signatures were an exact bijection, and the gap
# they printed was the difference between two sets neither of which contained
# it. Thirty-eight grade 8 machines sat in that blind spot while running 144
# curriculum rows to a correct answer. These maps are the third set -- machines
# that HAVE run, recorded row by row -- and the diff against the registry now
# goes both ways.
MACHINE_MAPS = (
    ROOT / "curriculum/im/generated/wave5_row_machine_map.jsonl",
    ROOT / "curriculum/im/generated/wave5_g8_row_machine_map.jsonl",
)
# A row whose route names a composition ran more than one machine under one
# label, so the label is not itself an automaton and files no signature of its
# own. Named from the map's own `route` field, never from an allowlist here.
COMPOSED_ROUTES = {"composition"}

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


def executed_machines() -> dict[str, dict[str, Any]]:
    """Machines named by a recorded run, with how often and by which route.

    Each row of a machine map is one curriculum row that went to one machine
    and came back with an outcome.  The map is evidence that the machine runs;
    it says nothing about whether the registry knows the machine exists, which
    is the point of reading it here.
    """
    seen: dict[str, dict[str, Any]] = {}
    for path in MACHINE_MAPS:
        if not path.exists():
            continue
        for line in path.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            row = json.loads(line)
            machine = row.get("machine")
            if not machine:
                continue
            entry = seen.setdefault(
                machine, {"rows": 0, "routes": set(), "maps": set()}
            )
            entry["rows"] += 1
            entry["routes"].add(str(row.get("route", "")))
            entry["maps"].add(path.name)
    return seen


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
    if shape == "integer_or_unknown":
        # A count the task withholds.  The grade 8 two-way-table pilot reads the
        # string "?" as an unknown cell and sends anything else to the shared
        # quantity decoder (g8_two_way_table_association.pl:110), so the leaf is
        # an integer or that one mark, and nothing else.
        if is_integer(example) or example == "?":
            return []
        return [f"{path}: expected an integer or the unknown mark \"?\""]
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

    # The other direction. A machine that ran on curriculum rows and files no
    # signature cannot show up in remaining_gap, because that gap is computed
    # from the registry outward. Read the recorded runs and name it here.
    signature_kinds = {kind for _, kind in signatures}
    executed = executed_machines()
    unsigned: list[str] = []
    composed: list[str] = []
    for machine in sorted(executed):
        if machine in signature_kinds:
            continue
        entry = executed[machine]
        detail = (
            f"{machine}: ran on {entry['rows']} recorded curriculum row(s) "
            f"({', '.join(sorted(entry['maps']))}) and files no "
            f"action_automaton_signature/4"
        )
        if entry["routes"] & COMPOSED_ROUTES:
            composed.append(f"{machine} ({entry['rows']} rows)")
        else:
            unsigned.append(machine)
            failures.append(detail)

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
                    "executed_machines": len(executed),
                    "executed_without_signature": sorted(unsigned),
                    "executed_composed_routes": sorted(composed),
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
        f"verified-live={len(traces)} "
        f"executed-machines={len(executed)} "
        f"executed-unsigned={len(unsigned)} "
        f"executed-composed={len(composed)}"
    )
    for machine in composed:
        print(
            f"  composed route, no signature of its own: {machine}",
            file=sys.stderr,
        )
    for failure in failures:
        print(f"FAIL: {failure}", file=sys.stderr)
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
