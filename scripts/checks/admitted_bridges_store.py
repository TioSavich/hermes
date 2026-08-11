#!/usr/bin/env python3
"""Recompute band-1 bridge admission and check its tracked Prolog store."""

from __future__ import annotations

import argparse
import json
import math
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[2]
DOCKET = ROOT / "docs/research/internal/2026-08-10-r4-admission-docket.json"
STORE = ROOT / "scripts/bigred/loops/admitted_bridges.pl"
DOCKET_CITATION = "docs/research/internal/2026-08-10-r4-admission-docket.json"
COLLECTION_CITATION = ".bigred-collected/2026-08-10-loops-wave4-r4/rows"
RULING_CITATION = "plans/2026-08-11-r4-admission-band1-draft.md"
EXPECTED_GENERATED_FOR = "2026-08-10 R4 admission ceremony"

EXPECTED_PARTITION = {
    "admitted": 594,
    "held_thin": 507,
    "held_singleton": 152,
    "held_answer_degenerate": 9,
}
EXPECTED_ADAPTER_COUNTS = {
    "carry_measured_magnitude": 5,
    "integer_over_one_to_fraction_object": 9,
    "project_quotient": 92,
    "project_remainder": 116,
    "project_wrapped_magnitude": 234,
    "rename_decimal_to_decimal_object": 46,
    "rename_fraction_to_fraction_object": 91,
    "unit_relabel_with_scaling_witness": 1,
}
EXPECTED_CLASS_COUNTS = {"r": 146, "p": 442, "u": 6}
EXPECTED_SEAM_COUNTS = {"none": 507, "1": 24, "3": 7, "4": 46, "6": 10}
EXPECTED_SAME_FAMILY = 211

LICENSE_CLASS = {
    "rename_fraction_to_fraction_object": "r",
    "rename_decimal_to_decimal_object": "r",
    "integer_over_one_to_fraction_object": "r",
    "project_wrapped_magnitude": "p",
    "project_remainder": "p",
    "project_quotient": "p",
    "carry_measured_magnitude": "u",
    "unit_relabel_with_scaling_witness": "u",
}

# Ruling 4 names this class by adapter and both machine endpoints.  It cuts
# before either the singleton predicate or the evidence-strength predicate.
ANSWER_DEGENERATE = {
    (
        "project_wrapped_magnitude",
        "algebraic",
        "operational_equals_left_value",
        "algebraic",
        "equation_truth_by_substitution",
    ),
    (
        "project_remainder",
        "division",
        "measure_groups_of_size",
        "subtraction",
        "count_up_missing_addend",
    ),
    (
        "project_remainder",
        "division",
        "measure_groups_of_size",
        "subtraction",
        "take_away_base_ones",
    ),
    (
        "project_remainder",
        "division",
        "partial_quotient_chunking",
        "subtraction",
        "count_up_missing_addend",
    ),
    (
        "project_remainder",
        "division",
        "partial_quotient_chunking",
        "subtraction",
        "take_away_base_ones",
    ),
    (
        "project_quotient",
        "division",
        "stop_after_first_partial_quotient",
        "multiplication",
        "common_factor_intersection",
    ),
    (
        "project_remainder",
        "division",
        "stop_after_first_partial_quotient",
        "multiplication",
        "common_factor_intersection",
    ),
    (
        "project_wrapped_magnitude",
        "multiplication",
        "add_numbers_as_common_multiple",
        "algebraic",
        "balance_preserving_linear_solution",
    ),
    (
        "project_wrapped_magnitude",
        "geometry",
        "subtract_side_from_area",
        "geometry",
        "rectangle_missing_side_from_area",
    ),
}

COLLECTION_FIELDS = {
    "signed_number_list": "values",
    "numeric_data_with_unit": "values",
    "numeric_data_display": "values",
    "polygon_sides_with_unit": "sides",
}
TYPE_NAMES = {"integer", "positive_integer", "number", "positive_number", "atom"}
UNIT_SLOT_KEYS = {"unit", "from_unit"}
PATH_TOKEN = re.compile(r"\.([A-Za-z0-9_]+)|\[([0-9]+)\]")


class AdmissionError(RuntimeError):
    """The docket, ruling arithmetic, or tracked store disagrees."""


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AdmissionError(message)


def row_key(row: dict[str, Any]) -> tuple[str, str, str, str, str]:
    return (
        row["adapter"],
        row["source"]["family"],
        row["source"]["kind"],
        row["target"]["family"],
        row["target"]["kind"],
    )


def is_singleton_collection(row: dict[str, Any]) -> bool:
    """Apply Ruling 5 to every retained witness, without schema inference."""
    witnesses = row.get("sample_witnesses") or []
    if not witnesses:
        return False
    for witness in witnesses:
        adapted = witness.get("adapted_input")
        if not isinstance(adapted, dict):
            return False
        field = COLLECTION_FIELDS.get(adapted.get("kind"))
        if field is None:
            return False
        values = adapted.get(field)
        if not isinstance(values, list) or len(values) != 1:
            return False
    return True


def verify_warrant(row: dict[str, Any]) -> None:
    warrant = row.get("warrant") or {}
    require(
        warrant.get("obligations") == ["units", "roles", "boundary"],
        f"band-1 obligations drifted for {row_key(row)!r}",
    )
    require(
        warrant.get("own_warrant_refusals") == [],
        f"band-1 row has an own-warrant refusal: {row_key(row)!r}",
    )


def partition_rows(rows: list[dict[str, Any]]) -> dict[str, list[dict[str, Any]]]:
    """Apply answer degeneracy, singleton degeneracy, then evidence strength."""
    buckets: dict[str, list[dict[str, Any]]] = {
        name: [] for name in EXPECTED_PARTITION
    }
    observed_answer_degenerate: set[tuple[str, str, str, str, str]] = set()

    for row in rows:
        verify_warrant(row)
        key = row_key(row)
        if key in ANSWER_DEGENERATE:
            bucket = "held_answer_degenerate"
            observed_answer_degenerate.add(key)
        elif is_singleton_collection(row):
            bucket = "held_singleton"
        elif row.get("candidate_type") == "contract_bridge":
            bucket = "admitted"
        else:
            require(
                row.get("candidate_type") == "contract_bridge_thin_evidence",
                f"unruled band-1 candidate type for {key!r}: "
                f"{row.get('candidate_type')!r}",
            )
            bucket = "held_thin"
        buckets[bucket].append(row)

    require(
        observed_answer_degenerate == ANSWER_DEGENERATE,
        "the docket does not contain Ruling 4's nine named rows exactly",
    )
    actual_partition = {name: len(bucket) for name, bucket in buckets.items()}
    require(
        actual_partition == EXPECTED_PARTITION,
        f"partition mismatch: {actual_partition!r}",
    )
    require(sum(actual_partition.values()) == 1_262, "band-1 partition does not sum to 1,262")
    return buckets


def verify_admitted_arithmetic(rows: list[dict[str, Any]]) -> None:
    adapter_counts = Counter(row["adapter"] for row in rows)
    require(
        adapter_counts == Counter(EXPECTED_ADAPTER_COUNTS),
        f"admitted adapter counts mismatch: {dict(sorted(adapter_counts.items()))!r}",
    )
    class_counts = Counter(LICENSE_CLASS[row["adapter"]] for row in rows)
    require(
        class_counts == Counter(EXPECTED_CLASS_COUNTS),
        f"admitted class counts mismatch: {dict(sorted(class_counts.items()))!r}",
    )
    require(
        all(row.get("distinct_adapted_inputs") == 20 for row in rows),
        "an admitted row does not carry 20 distinct adapted inputs",
    )

    seam_counts: Counter[str] = Counter()
    for row in rows:
        flags = row.get("seam_relevant") or []
        if not flags:
            seam_counts["none"] += 1
        else:
            seam_counts.update(str(flag) for flag in flags)
    require(
        seam_counts == Counter(EXPECTED_SEAM_COUNTS),
        f"admitted seam counts mismatch: {dict(sorted(seam_counts.items()))!r}",
    )

    same_family = sum(bool(row.get("same_family")) for row in rows)
    require(
        same_family == EXPECTED_SAME_FAMILY,
        f"same-family count mismatch: {same_family}",
    )
    require(len(rows) - same_family == 383, "cross-family count mismatch")


def parse_path(path: str) -> tuple[str | int, ...]:
    if path == "root":
        return ()
    tokens: list[str | int] = []
    position = 0
    for match in PATH_TOKEN.finditer(path):
        require(match.start() == position, f"unsupported placement path: {path!r}")
        tokens.append(match.group(1) if match.group(1) is not None else int(match.group(2)))
        position = match.end()
    require(position == len(path), f"unsupported placement path: {path!r}")
    return tuple(tokens)


def format_path(path: tuple[str | int, ...]) -> str:
    if not path:
        return "root"
    return "".join(f".{part}" if isinstance(part, str) else f"[{part}]" for part in path)


def typed_paths(value: Any, prefix: tuple[str | int, ...] = ()) -> Iterable[tuple[str | int, ...]]:
    if isinstance(value, dict):
        for key, child in value.items():
            yield from typed_paths(child, prefix + (key,))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from typed_paths(child, prefix + (index,))
    elif value in TYPE_NAMES:
        yield prefix


def value_at(value: Any, path: tuple[str | int, ...]) -> Any:
    current = value
    for part in path:
        current = current[part]
    return current


def companion_values(row: dict[str, Any]) -> list[list[dict[str, Any]]]:
    """Record typed target slots threaded from each docket witness's grid input."""
    schema = json.loads(row["target_contract"]["schema"])
    placement = parse_path(row["placement_path"])
    candidates = [
        path
        for path in typed_paths(schema)
        if path[: len(placement)] != placement
    ]

    supplied_unit: tuple[str | int, ...] | None = None
    if row["adapter"] in {"carry_measured_magnitude", "unit_relabel_with_scaling_witness"}:
        supplied_unit = next(
            (path for path in candidates if path and path[-1] in UNIT_SLOT_KEYS),
            None,
        )

    samples: list[list[dict[str, Any]]] = []
    for witness in row["sample_witnesses"]:
        source_input = witness["input"]
        adapted_input = witness["adapted_input"]
        companions: list[dict[str, Any]] = []
        for path in candidates:
            if path == supplied_unit:
                continue
            try:
                source_value = value_at(source_input, path)
                adapted_value = value_at(adapted_input, path)
            except (KeyError, IndexError, TypeError):
                continue
            require(
                source_value == adapted_value,
                f"target companion was not threaded at {format_path(path)} for {row_key(row)!r}",
            )
            companions.append({"path": format_path(path), "value": adapted_value})
        samples.append(companions)
    return samples


def expected_fact(row: dict[str, Any], generated_for: str) -> dict[str, Any]:
    witnesses = row.get("sample_witnesses") or []
    require(witnesses, f"admitted row has no witness: {row_key(row)!r}")
    witness = witnesses[0]
    witness_fields = (
        "input",
        "carried_value_exact",
        "adapted_input",
        "source_result",
        "target_result",
        "transform",
    )
    require(
        all(witness.get(field) not in (None, "") for field in witness_fields),
        f"admitted row has an incomplete witness: {row_key(row)!r}",
    )
    fact = {
        "adapter": row["adapter"],
        "license_class": LICENSE_CLASS[row["adapter"]],
        "source": row["source"],
        "target": row["target"],
        "carried_role": witness["transform"],
        "candidate_strength": row["candidate_type"],
        "distinct_adapted_inputs": row["distinct_adapted_inputs"],
        "companion_values": companion_values(row),
        "witness": {field: witness[field] for field in witness_fields},
        "seam_flags": row.get("seam_relevant") or [],
        "provenance": {
            "docket": DOCKET_CITATION,
            "generated_for": generated_for,
            "collection_directory": COLLECTION_CITATION,
            "ruling": RULING_CITATION,
        },
    }
    if row["adapter"] == "unit_relabel_with_scaling_witness":
        all_equal = all(
            item["adapted_input"] == item["input"] for item in witnesses
        )
        require(
            all_equal,
            "unit_relabel retained witness no longer returns to its source input",
        )
        fact["adapted_input_equals_source_input_in_all_retained_witnesses"] = True
    return fact


def prolog_atom(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "''") + "'"


def prolog_key(value: str) -> str:
    if re.fullmatch(r"[a-z][A-Za-z0-9_]*", value):
        return value
    return prolog_atom(value)


def prolog_value(value: Any, *, tag: str = "json") -> str:
    if isinstance(value, dict):
        fields = ", ".join(
            f"{prolog_key(key)}:{prolog_value(item)}"
            for key, item in sorted(value.items())
        )
        return f"{tag}{{{fields}}}"
    if isinstance(value, list):
        return "[" + ", ".join(prolog_value(item) for item in value) + "]"
    if isinstance(value, str):
        return prolog_atom(value)
    if value is True:
        return "true"
    if value is False:
        return "false"
    if value is None:
        return "null"
    # Future bands must not render Python's inf/nan tokens as Prolog values.
    if isinstance(value, float):
        if not math.isfinite(value):
            raise TypeError(f"cannot render non-finite float {value!r}")
        return repr(value)
    if isinstance(value, int):
        return repr(value)
    raise TypeError(f"cannot render Prolog value {value!r}")


def render_fact(fact: dict[str, Any]) -> str:
    field_order = [
        "adapter",
        "license_class",
        "source",
        "target",
        "carried_role",
        "candidate_strength",
        "distinct_adapted_inputs",
        "companion_values",
        "witness",
        "seam_flags",
        "provenance",
    ]
    optional = "adapted_input_equals_source_input_in_all_retained_witnesses"
    if optional in fact:
        field_order.append(optional)
    fields = [
        f"        {key}:{prolog_value(fact[key])}"
        for key in field_order
    ]
    return "admitted_bridge(\n    bridge{\n" + ",\n".join(fields) + "\n    }\n).\n"


def render_store(facts: list[dict[str, Any]]) -> str:
    generated_for_values = {
        fact["provenance"]["generated_for"] for fact in facts
    }
    require(
        generated_for_values == {EXPECTED_GENERATED_FOR},
        f"unexpected generated_for values: {generated_for_values!r}",
    )
    generated_for = next(iter(generated_for_values))
    header = f"""/** <module> Ceremony-admitted typed contract bridges
 *
 * This store records 594 band-1 contract_bridge admissions.  Class P licenses
 * transport of the named role only.  It licenses neither equivalence between
 * the machines nor correctness of the transported value.
 *
 * The ruled partition is 594 admitted, 507 held because their evidence is
 * thin, 152 held because the carried value arrives as the sole element of a
 * collection, and 9 held because the target answer is degenerate.  The 507
 * thin rows wait on grid repairs and re-collection.  The 152 singleton rows
 * wait on a design change because no R4 evidence can thicken them.  Held rows
 * have no facts here.
 *
 * All 46 seam-4 admissions are decimal-to-decimal renames.  This wave does not
 * meet the seam's fraction-to-decimal request.
 * The ruling is {RULING_CITATION}.
 * contract_bridge remains distinct from crisis_release in admitted_edges.pl.
 *
 * Generated mechanically by scripts/checks/admitted_bridges_store.py from
 * {DOCKET_CITATION}
 * for {generated_for}.
 */

:- module(admitted_bridges,
          [ admitted_bridge/1
          ]).

"""
    blocks: list[str] = [header]
    prior_adapter: str | None = None
    for fact in facts:
        if fact["adapter"] != prior_adapter:
            if prior_adapter is not None:
                blocks.append("\n")
            blocks.append(f"% Adapter: {fact['adapter']}\n")
            prior_adapter = fact["adapter"]
        blocks.append(render_fact(fact))
    return "".join(blocks)


def verify_store_text() -> None:
    text = STORE.read_text(encoding="utf-8")
    require(
        text.count("admitted_bridge(") == 594,
        "tracked store does not contain exactly 594 admitted_bridge( occurrences",
    )
    # Count every directive, not only module directives: a non-module
    # directive after the header would execute at load time, and the
    # docket-free half must refuse it too.
    directives = re.findall(r"(?m)^[ \t]*:-", text)
    require(
        len(directives) == 1,
        f"tracked store has {len(directives)} directives; exactly one (module) is allowed",
    )
    module_directives = re.findall(r"(?m)^[ \t]*:-[ \t]*module[ \t]*\(", text)
    require(
        len(module_directives) == 1,
        f"tracked store has {len(module_directives)} module directives",
    )
    clause_heads = re.findall(
        r"(?m)^[ \t]*([a-z][A-Za-z0-9_]*)[ \t]*\(", text
    )
    require(
        Counter(clause_heads) == Counter({"admitted_bridge": 594}),
        f"tracked store has another clause head: {dict(Counter(clause_heads))!r}",
    )


def load_store() -> list[dict[str, Any]]:
    goal = (
        "use_module(library(http/json)),"
        "findall(D,admitted_bridges:admitted_bridge(D),Rows),"
        "(forall(member(D,Rows),is_dict(D,bridge))->Tags=true;Tags=false),"
        "json_write_dict(current_output,_{all_bridge_tags:Tags,rows:Rows},"
        "[width(0)]),nl"
    )
    completed = subprocess.run(
        ["swipl", "-q", "-s", str(STORE), "-g", goal, "-t", "halt"],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    require(completed.returncode == 0, f"SWI-Prolog load failed: {completed.stderr.strip()}")
    require(not completed.stderr.strip(), f"SWI-Prolog load emitted a warning: {completed.stderr.strip()}")
    try:
        payload = json.loads(completed.stdout)
    except json.JSONDecodeError as error:
        raise AdmissionError(f"store query did not return JSON: {error}") from error
    require(isinstance(payload, dict), "store query did not return an object")
    require(payload.get("all_bridge_tags") is True, "a store fact lacks the bridge dict tag")
    loaded = payload.get("rows")
    require(isinstance(loaded, list), "store query did not return a list")
    return loaded


def fact_identity(fact: dict[str, Any]) -> tuple[str, str, str, str]:
    return (
        fact["adapter"],
        fact["source"]["kind"],
        fact["target"]["kind"],
        fact["candidate_strength"],
    )


def check_tracked_store(actual: list[dict[str, Any]]) -> None:
    require(len(actual) == 594, f"store fact count mismatch: {len(actual)}")
    identities = [fact_identity(fact) for fact in actual]
    require(len(identities) == len(set(identities)), "store contains a duplicate admitted identity")

    adapter_counts = Counter(fact["adapter"] for fact in actual)
    class_counts = Counter(fact["license_class"] for fact in actual)
    require(adapter_counts == Counter(EXPECTED_ADAPTER_COUNTS), "store adapter counts mismatch")
    require(class_counts == Counter(EXPECTED_CLASS_COUNTS), "store class counts mismatch")

    for fact in actual:
        witness = fact.get("witness")
        provenance = fact.get("provenance")
        require(isinstance(witness, dict) and bool(witness), "store fact has no witness")
        require(
            all(witness.get(field) not in (None, "") for field in (
                "input",
                "carried_value_exact",
                "adapted_input",
                "source_result",
                "target_result",
                "transform",
            )),
            f"store fact has an incomplete witness: {fact_identity(fact)!r}",
        )
        require(isinstance(provenance, dict) and bool(provenance), "store fact has no provenance")
        require(
            all(provenance.get(field) for field in (
                "docket", "generated_for", "collection_directory", "ruling"
            )),
            f"store fact has incomplete provenance: {fact_identity(fact)!r}",
        )
    unit_relabels = [
        fact for fact in actual
        if fact.get("adapter") == "unit_relabel_with_scaling_witness"
    ]
    require(len(unit_relabels) == 1, "store does not contain one unit_relabel fact")
    require(
        unit_relabels[0].get(
            "adapted_input_equals_source_input_in_all_retained_witnesses"
        ) is True,
        "unit_relabel fact lacks its retained-witness input equality",
    )


def strict_differences(actual: Any, expected: Any, path: str = "$") -> list[str]:
    if type(actual) is not type(expected):
        return [
            f"{path}: type {type(actual).__name__} != {type(expected).__name__}"
        ]
    if isinstance(expected, dict):
        differences: list[str] = []
        actual_keys = set(actual)
        expected_keys = set(expected)
        for missing in sorted(expected_keys - actual_keys):
            differences.append(f"{path}.{missing}: missing")
        for extra in sorted(actual_keys - expected_keys):
            differences.append(f"{path}.{extra}: extra")
        for key in sorted(actual_keys & expected_keys):
            differences.extend(
                strict_differences(actual[key], expected[key], f"{path}.{key}")
            )
        return differences
    if isinstance(expected, list):
        differences = []
        if len(actual) != len(expected):
            differences.append(f"{path}: length {len(actual)} != {len(expected)}")
        for index, (actual_item, expected_item) in enumerate(zip(actual, expected)):
            differences.extend(
                strict_differences(actual_item, expected_item, f"{path}[{index}]")
            )
        return differences
    if actual != expected:
        return [f"{path}: {actual!r} != {expected!r}"]
    return []


def check_docket_match(actual: list[dict[str, Any]], expected: list[dict[str, Any]]) -> None:
    identities = [fact_identity(fact) for fact in actual]
    require(
        Counter(identities) == Counter(fact_identity(fact) for fact in expected),
        "store has an admitted identity mismatch",
    )
    differences = strict_differences(actual, expected)
    require(
        not differences,
        "store ceremony fields differ from the docket-derived facts: "
        + "; ".join(differences[:10]),
    )
    require(
        STORE.read_text(encoding="utf-8") == render_store(expected),
        "tracked store bytes differ from the docket-derived renderer",
    )


def build_expected() -> tuple[dict[str, list[dict[str, Any]]], list[dict[str, Any]]]:
    docket = json.loads(DOCKET.read_text(encoding="utf-8"))
    rows = docket.get("band_one_typed_converters")
    require(isinstance(rows, list) and len(rows) == 1_262, "docket band has changed size")
    generated_for = docket.get("generated_for")
    require(
        generated_for == EXPECTED_GENERATED_FOR,
        f"docket generated_for mismatch: {generated_for!r}",
    )
    buckets = partition_rows(rows)
    admitted = sorted(buckets["admitted"], key=row_key)
    verify_admitted_arithmetic(admitted)
    facts = [expected_fact(row, generated_for) for row in admitted]
    return buckets, facts


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--write",
        action="store_true",
        help="mechanically rewrite the tracked store after the ruled partition passes",
    )
    arguments = parser.parse_args()

    try:
        buckets = None
        expected = None
        if DOCKET.is_file():
            buckets, expected = build_expected()
            if arguments.write:
                STORE.write_text(render_store(expected), encoding="utf-8")
                print(f"WROTE {STORE.relative_to(ROOT)}: {len(expected)} facts")
        elif arguments.write:
            raise AdmissionError(
                "cannot regenerate admitted_bridges.pl without the local runtime "
                f"docket: {DOCKET_CITATION}"
            )

        verify_store_text()
        actual = load_store()
        check_tracked_store(actual)
        if expected is not None:
            check_docket_match(actual, expected)
    except (AdmissionError, KeyError, OSError, TypeError, ValueError) as error:
        print(f"FAIL admitted_bridges_store: {error}", file=sys.stderr)
        return 1

    if buckets is None:
        print(
            "SKIP admitted_bridges docket re-derivation: "
            f"{DOCKET_CITATION} is local runtime and is absent"
        )
        print(
            "PASS admitted_bridges_store tracked-store: store-facts=594 "
            "duplicate-identities=0 R=146 P=442 U=6 "
            "witness-provenance=complete"
        )
    else:
        print(
            "PASS admitted_bridges_store: "
            f"admitted={len(buckets['admitted'])} "
            f"held-thin={len(buckets['held_thin'])} "
            f"held-singleton={len(buckets['held_singleton'])} "
            f"held-answer-degenerate={len(buckets['held_answer_degenerate'])} "
            "store-facts=594 R=146 P=442 U=6"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
