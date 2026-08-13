#!/usr/bin/env python3
"""Build and falsify the frozen Wave 5 row-to-machine map."""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
POOL = REPO_ROOT / "curriculum" / "im" / "generated" / "compiled_defragged_task_instances.pl"
OUTPUT = REPO_ROOT / "curriculum" / "im" / "generated" / "wave5_row_machine_map.jsonl"
REPORT = REPO_ROOT / "curriculum" / "im" / "generated" / "wave5_row_machine_map_report.json"
RUNNER = SCRIPT_DIR / "wave5_trace_runner.pl"
USABLE = {"already_complete", "recovered", "recovered_with_referent"}
POOL_TOTAL = 2659
USABLE_TOTAL = 2132
LEGACY_TOTAL = 1811
EXPECTED_LEGACY = Counter(correct=1782, magnitude_refused=28, execution_limit=1)
ORIGINAL_MAGNITUDE_OPERATIONS = {
    "productive-subtract(400000,99999)",
    "productive-subtract(423450,42345)",
    "productive-multiply(1500,30000)",
}
BUILDER_VERSION = "wave5-row-map-v4-sentence-bounded-source"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_pool_rows() -> list[dict[str, Any]]:
    goal = (
        "use_module(library(http/json)),"
        f"use_module('{POOL.as_posix()}'),"
        "forall(compiled_defragged_task_instances:defragged_task_instance(Id,Lesson,Op,D),"
        "(get_dict(status,D,Status),get_dict(complete_statement,D,Statement),"
        "get_dict(source_statement,D,SourceStatement),"
        "get_dict(statement_repair_class,D,StatementRepairClass),"
        "get_dict(referents,D,Referents),get_dict(visuals,D,Visuals),"
        "get_dict(evidence_sha256,D,Evidence),get_dict(source_evidence,D,SourceEvidence),"
        "SourceEvidence=..[_|EvidenceParts],"
        "(member(position(Position),EvidenceParts)->term_string(Position,PositionText,[quoted(true)]);PositionText=\"\"),"
        "(member(excerpt(Excerpt0),EvidenceParts)->"
        "(string(Excerpt0)->ExcerptText=Excerpt0;term_string(Excerpt0,ExcerptText,[quoted(true)]));ExcerptText=\"\"),"
        "term_string(Op,Operation,[quoted(true)]),"
        "json_write_dict(current_output,_{id:Id,lesson:Lesson,operation:Operation,"
        "status:Status,statement:Statement,referents:Referents,visuals:Visuals,"
        "evidence_sha256:Evidence,source_position:PositionText,"
        "source_excerpt:SourceStatement,source_excerpt_original:ExcerptText,"
        "statement_repair_class:StatementRepairClass},"
        "[width(0)]),nl)),halt"
    )
    completed = subprocess.run(
        ["swipl", "-q", "-g", goal], cwd=REPO_ROOT, text=True,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True,
    )
    return [json.loads(line) for line in completed.stdout.splitlines() if line.strip()]


def split_args(text: str) -> list[str]:
    parts: list[str] = []
    start = 0
    depth = 0
    for index, char in enumerate(text):
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
        elif char == "," and depth == 0:
            parts.append(text[start:index].strip())
            start = index + 1
    parts.append(text[start:].strip())
    return parts


def compound(text: str) -> tuple[str, list[str]]:
    text = text.strip()
    if "(" not in text or not text.endswith(")"):
        return text, []
    name, rest = text.split("(", 1)
    return name, split_args(rest[:-1])


def operation_body(operation: str) -> str:
    """Return the right side of the artifact's top-level disposition pair."""
    depth = 0
    split_at = -1
    for index, char in enumerate(operation):
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
        elif char == "-" and depth == 0:
            split_at = index
    return operation[split_at + 1:] if split_at >= 0 else operation


def number(text: str) -> int | float:
    return float(text) if "." in text else int(text)


def fraction_value(text: str) -> dict[str, int]:
    name, args = compound(text)
    if name == "frac":
        return {"n": int(args[0]), "d": int(args[1])}
    if name == "whole":
        return {"whole": int(args[0])}
    if name == "mixed":
        return {"whole": int(args[0]), "n": int(args[1]), "d": int(args[2])}
    raise ValueError(f"unsupported fraction term: {text}")


def mapping(operation: str) -> dict[str, Any]:
    inner = operation_body(operation)
    family, args = compound(inner)
    base: dict[str, Any] = {"family": family, "operand_terms": args}
    if family in {"add", "subtract", "multiply", "divide"}:
        a, b = map(number, args)
        machines = {
            "add": "column_addition_with_carrying",
            "subtract": "take_away_base_ones",
            "multiply": "multiplication_fact_retrieval",
            "divide": "long_division",
        }
        machine = machines[family]
        route = "single_machine"
        if family == "multiply" and a == 600 and b == 500:
            machine = "known_product_adjustment"
            route = "alternate_machine"
        return {**base, "machine": machine, "input": {"a": a, "b": b}, "route": route}
    if family in {"add_fractions", "subtract_fractions"}:
        left, right = map(fraction_value, args)
        if family == "add_fractions":
            machine, kind = "common_denominator_fraction_addition", "fraction_addend_pair"
        else:
            machine, kind = "common_denominator_fraction_subtraction", "fraction_minuend_subtrahend"
        return {**base, "machine": machine,
                "input": {"kind": kind, "left": left, "right": right},
                "route": "single_machine"}
    tail: dict[str, tuple[str, Any]] = {
        "compare_numerals_by_place_value": (
            "place_value_comparison",
            lambda a: {"kind": "count_pair", "left": int(a[0]), "right": int(a[1]), "base": int(a[2])}),
        "unit_cube_volume": (
            "rectangular_prism_volume_layer_iteration",
            lambda a: {"kind": "rectangular_prism", "length": int(a[0]), "width": int(a[1]), "height": int(a[2])}),
        "decimal_value": ("positional_decimal_reading", lambda a: {"a": int(a[0]), "b": int(a[1])}),
        "unit_fraction": ("recursive_partition", lambda a: {"a": int(a[0]), "b": int(a[1])}),
        "rectangle_perimeter": (
            "rectangle_perimeter_boundary_traversal",
            lambda a: {"kind": "rectangle_with_unit", "length": int(a[0]), "width": int(a[1]), "unit": a[2]}),
        "rectangle_missing_side_from_perimeter": (
            "rectangle_missing_side_from_perimeter",
            lambda a: {"kind": "perimeter_known_side", "perimeter": int(a[0]), "known_side": int(a[1])}),
        "rectangle_missing_side_from_area": (
            "rectangle_missing_side_from_area",
            lambda a: {"kind": "area_known_side", "area": int(a[0]), "known_side": int(a[1])}),
        "construct_rectangle_with_area": (
            "rectangle_factor_pair_search",
            lambda a: {"kind": "area_scope", "area": int(a[0]), "scope": "all"}),
        "rectangle_side_lengths_for_area": (
            "rectangle_factor_pair_search",
            lambda a: {"kind": "area_scope", "area": int(a[0]), "scope": "all"}),
        "decimal_add": (
            "decimal_addition_by_aligned_units",
            lambda a: {"kind": "decimal_pair", "left": {"numeral": int(a[0]), "scale": int(a[1])},
                       "right": {"numeral": int(a[2]), "scale": int(a[3])}}),
        "decimal_compare": (
            "decimal_comparison_by_aligned_units",
            lambda a: {"kind": "decimal_pair", "left": {"numeral": int(a[0]), "scale": int(a[1])},
                       "right": {"numeral": int(a[2]), "scale": int(a[3])}}),
        "convert_measurement": (
            "unit_conversion_by_iteration",
            lambda a: {"kind": "quantity_conversion", "count": int(a[0]), "from_unit": a[1],
                       "to_unit": a[2], "factor": int(a[3])}),
    }
    if family == "compare_rectangle_areas":
        return {**base, "machine": "rectangle_area_unit_iteration_composition",
                "input": {"rectangles": [{"length": int(args[0]), "width": int(args[1])},
                                            {"length": int(args[2]), "width": int(args[3])}]},
                "route": "composition"}
    if family in tail:
        machine, make_input = tail[family]
        return {**base, "machine": machine, "input": make_input(args), "route": "single_machine"}
    return {**base, "machine": None, "input": None, "route": "unmappable"}


class TraceRunner:
    def __init__(self) -> None:
        self.process = subprocess.Popen(
            ["swipl", "-q", "-f", str(RUNNER)], cwd=REPO_ROOT, text=True,
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            bufsize=1,
        )

    def run(self, machine: str, payload: dict[str, Any]) -> dict[str, Any]:
        assert self.process.stdin is not None and self.process.stdout is not None
        request = {"mode": "trace", "machine": machine, "input": payload}
        self.process.stdin.write(json.dumps(request, sort_keys=True) + "\n")
        self.process.stdin.flush()
        line = self.process.stdout.readline()
        if not line:
            stderr = self.process.stderr.read() if self.process.stderr else ""
            raise RuntimeError(f"trace runner stopped: {stderr}")
        return json.loads(line)

    def close(self) -> None:
        if self.process.stdin and self.process.poll() is None:
            self.process.stdin.write('{"mode":"stop"}\n')
            self.process.stdin.flush()
            self.process.stdin.close()
        self.process.wait(timeout=10)
        if self.process.returncode:
            stderr = self.process.stderr.read() if self.process.stderr else ""
            raise RuntimeError(f"trace runner failed: {stderr}")


def build() -> tuple[bytes, bytes, dict[str, Any]]:
    rows = load_pool_rows()
    statuses = Counter(row["status"] for row in rows)
    usable = [row for row in rows if row["status"] in USABLE]
    if len(rows) != POOL_TOTAL or len(usable) != USABLE_TOTAL:
        raise RuntimeError(
            f"BLOCK pool freeze mismatch: total={len(rows)} usable={len(usable)}; "
            f"expected {POOL_TOTAL}/{USABLE_TOTAL}"
        )
    mapped_rows: list[dict[str, Any]] = []
    runner = TraceRunner()
    try:
        for row in usable:
            route = mapping(row["operation"])
            record = {**row, **route, "grade": row["lesson"].split("-", 2)[1][1:]}
            if route["machine"]:
                record["execution"] = runner.run(route["machine"], route["input"])
            else:
                record["execution"] = {"ok": False, "outcome": "unmappable",
                                       "validity": "", "result_term": "", "note": ""}
            mapped_rows.append(record)
    finally:
        runner.close()

    legacy = [row for row in mapped_rows if row["grade"] != "8"]
    legacy_outcomes = Counter(row["execution"]["outcome"] for row in legacy)
    observed = Counter({key: legacy_outcomes[key] for key in EXPECTED_LEGACY})
    unexpected = sum(count for name, count in legacy_outcomes.items()
                     if name not in EXPECTED_LEGACY)
    if len(legacy) != LEGACY_TOTAL or observed != EXPECTED_LEGACY or unexpected:
        raise RuntimeError(
            "BLOCK legacy falsifier disagreement: "
            f"rows={len(legacy)} outcomes={dict(legacy_outcomes)}"
        )

    divergent_rows: list[dict[str, Any]] = []
    for row in legacy:
        outcome = row["execution"]["outcome"]
        is_original_magnitude = row["operation"] in ORIGINAL_MAGNITUDE_OPERATIONS
        if outcome == "magnitude_refused" and not is_original_magnitude:
            refusal = row["execution"].get("refusal", {})
            numeric_operands = [value for value in row["input"].values()
                                if isinstance(value, (int, float))]
            proof_ok = (
                refusal.get("kind") == "grounded_arithmetic_magnitude_bound"
                and refusal.get("bound") == 5000
                and any(abs(value) > 5000 for value in numeric_operands)
            )
            divergent_rows.append({
                "id": row["id"], "lesson": row["lesson"],
                "operation": row["operation"], "operands": row["input"],
                "refusal_kind": refusal.get("kind"),
                "bound": refusal.get("bound"), "proof_ok": proof_ok,
            })
        elif outcome == "execution_limit":
            refusal = row["execution"].get("refusal", {})
            proof_ok = (
                row["operation"] == "productive-multiply(600,500)"
                and row["machine"] == "known_product_adjustment"
                and refusal.get("kind") == "strategy_execution_time_bound"
                and refusal.get("bound_seconds") == 5
            )
            divergent_rows.append({
                "id": row["id"], "lesson": row["lesson"],
                "operation": row["operation"], "operands": row["input"],
                "refusal_kind": refusal.get("kind"),
                "bound_seconds": refusal.get("bound_seconds"), "proof_ok": proof_ok,
            })
    if len(divergent_rows) != 26 or not all(row["proof_ok"] for row in divergent_rows):
        raise RuntimeError(
            "BLOCK divergent-row guard proof failed: "
            f"rows={len(divergent_rows)} bad={[r for r in divergent_rows if not r['proof_ok']]}"
        )

    family_table: dict[str, dict[str, int]] = {}
    grouped: defaultdict[str, Counter[str]] = defaultdict(Counter)
    for row in legacy:
        grouped[row["family"]][row["execution"]["outcome"]] += 1
    for family in sorted(grouped):
        family_table[family] = dict(sorted(grouped[family].items()))
    g8_unmappable = Counter(row["family"] for row in mapped_rows
                            if row["grade"] == "8" and not row["machine"])
    report = {
        "builder_version": BUILDER_VERSION,
        "pool": str(POOL.relative_to(REPO_ROOT)),
        "pool_sha256": sha256(POOL),
        "pool_total": len(rows),
        "status_counts": dict(sorted(statuses.items())),
        "usable_total": len(usable),
        "legacy_falsifier": {
            "rows": len(legacy), "correct": legacy_outcomes["correct"],
            "magnitude_refused": legacy_outcomes["magnitude_refused"],
            "execution_limit": legacy_outcomes["execution_limit"],
            "post_guard_divergent_rows": divergent_rows,
            "per_family": family_table,
        },
        "g8": {
            "usable": sum(row["grade"] == "8" for row in mapped_rows),
            "mapped": sum(row["grade"] == "8" and bool(row["machine"]) for row in mapped_rows),
            "unmappable_by_family": dict(sorted(g8_unmappable.items())),
        },
    }
    map_bytes = b"".join(
        (json.dumps(row, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n").encode()
        for row in mapped_rows
    )
    report_bytes = (json.dumps(report, indent=2, sort_keys=True) + "\n").encode()
    return map_bytes, report_bytes, report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail if tracked outputs are stale")
    args = parser.parse_args()
    try:
        map_bytes, report_bytes, report = build()
    except (RuntimeError, subprocess.CalledProcessError) as error:
        print(str(error), file=sys.stderr)
        return 1
    if args.check:
        stale = [str(path) for path, data in ((OUTPUT, map_bytes), (REPORT, report_bytes))
                 if not path.is_file() or path.read_bytes() != data]
        if stale:
            print("stale Wave 5 row-map artifacts: " + ", ".join(stale), file=sys.stderr)
            return 1
        print(f"PASS Wave 5 row map is fresh: {report['usable_total']} usable rows")
        return 0
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_bytes(map_bytes)
    REPORT.write_bytes(report_bytes)
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
