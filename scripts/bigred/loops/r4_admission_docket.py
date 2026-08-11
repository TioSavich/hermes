#!/usr/bin/env python3
"""Build the R4 admission docket over the collected contract-bridge run.

The collected rows are read-only evidence. This tool writes two local,
gitignored ceremony artifacts under docs/research/internal. It proposes an
order for human review and records no verdict.

The order is the one ruled after wave 1. Typed converters read first, with
the bridges that touch a rung-map seam territory flagged inside that band.
The identity-adapter bridges read second: an identity bridge between two
machines that answer different questions carries a value across a question
the receiver was never asked, so that band is the pun-risk class. The docket
partitions it mechanically into same-family and cross-family rows and carries
both machines' contract rows, which is what the question-preservation test
needs. It applies no test.

Question preservation stays blank on every row. A bridge records that a
receiver accepted a carried value inside its declared types; acceptance is
not agreement about the question.

Evidence weight is distinct_adapted_inputs. Carrying one value into the
varied slot collapses twenty samples to as few as eight, so samples_bridged
overcounts a bridge's reach and the ceremony reads the distinct count.

Row files are matched by an anchored pattern. A sync copy named
"r4_rows_0003 2.jsonl" would double a shard's rows under a glob.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any, Callable

ROOT = Path(__file__).resolve().parents[3]
DEFAULT_ROWS = ROOT / ".bigred-collected/2026-08-10-loops-wave4-r4/rows"
DEFAULT_OUTPUT_DIR = ROOT / "docs/research/internal"
DOCKET_STEM = "2026-08-10-r4-admission-docket"

ROW_FILE_PATTERN = re.compile(r"^r4_rows_[0-9]{4}\.jsonl$")

# The census the controller recorded when the run was collected
# (memory r4-launch-and-sidekick-floors.md, 2026-08-10). A None means the
# note states no figure for that measure; the recomputation still prints.
COLLECTION_NOTE: dict[str, int | None] = {
    "row_files": 698,
    "rows_total": 9772,
    "ordered_pairs": 8268,
    "certified_candidates": 3207,
    "contract_bridge": 2231,
    "contract_bridge_thin_evidence": 976,
    "warrant_refused": 2271,
    "measured_incompatible": 301,
    "target_refused": 3560,
    "source_never_computed": 378,
    "adapters_with_a_certified_row": 10,
    "certified_identity": 1945,
    "certified_unit_relabel_with_scaling_witness": 1,
    "certified_integer_over_one_to_fraction_object": 9,
    "certified_project_wrapped_magnitude": None,
    "certified_project_remainder": None,
    "certified_project_quotient": None,
    "certified_rename_fraction_to_fraction_object": None,
    "certified_carry_measured_magnitude": None,
    "certified_project_rational_magnitude": None,
    "certified_rename_decimal_to_decimal_object": None,
    "certified_territory_fraction_division": 96,
    "certified_territory_subtraction_and_division_to_integer": 66,
    "certified_territory_counting_to_integer": 2,
}

COUNT_LABELS = {
    "row_files": "row files read (anchored pattern)",
    "rows_total": "rows on disk",
    "ordered_pairs": "distinct ordered machine pairs",
    "certified_candidates": "certified candidates",
    "contract_bridge": "contract_bridge (full strength)",
    "contract_bridge_thin_evidence": "contract_bridge_thin_evidence",
    "warrant_refused": "warrant_refused rows",
    "measured_incompatible": "measured_incompatible rows",
    "target_refused": "target_refused rows",
    "source_never_computed": "source_never_computed rows",
    "adapters_with_a_certified_row": "adapters with a certified row",
    "certified_identity": "certified identity-adapter rows",
    "certified_unit_relabel_with_scaling_witness":
        "certified unit_relabel_with_scaling_witness",
    "certified_integer_over_one_to_fraction_object":
        "certified integer_over_one_to_fraction_object",
    "certified_project_wrapped_magnitude":
        "certified project_wrapped_magnitude",
    "certified_project_remainder": "certified project_remainder",
    "certified_project_quotient": "certified project_quotient",
    "certified_rename_fraction_to_fraction_object":
        "certified rename_fraction_to_fraction_object",
    "certified_carry_measured_magnitude": "certified carry_measured_magnitude",
    "certified_project_rational_magnitude":
        "certified project_rational_magnitude",
    "certified_rename_decimal_to_decimal_object":
        "certified rename_decimal_to_decimal_object",
    "certified_territory_fraction_division":
        "certified rows in territory 1 (fraction and division)",
    "certified_territory_subtraction_and_division_to_integer":
        "certified rows in territories 2 and 3 (the signed seam)",
    "certified_territory_counting_to_integer":
        "certified rows in territory 5 (counting to integer)",
}

Machine = tuple[str, str]

# The eight seam territories, in the ruled order. A territory is a family
# predicate over a directed row; the rung-map seam numbers are the eight
# named seams of docs/research/internal/2026-08-08-learner-path-graph-design.md
# (lines 226-249), numbered as the R2 rung-map seam report numbers them.
# Endpoint meanings come from the rung table of
# docs/research/2026-08-06-learner-paths.md.
SEAM_TERRITORIES: list[dict[str, Any]] = [
    {
        "territory": 1,
        "label": "fraction and division, either direction",
        "family_predicate": "the two families are exactly fraction and division",
        "rung_map_seams": [2],
        "rung_map_seam_labels": ["Whole-number sharing to unit fractions"],
        "rung_table_endpoints": [
            "Whole-number sharing -> unit fractions "
            "(docs/research/2026-08-06-learner-paths.md:31)"
        ],
        "note": (
            "The seam's own source refusal, whole_number_non_integer_share, "
            "is not authored, so no row can sit on the seam itself. These "
            "rows sit in its territory."
        ),
    },
    {
        "territory": 2,
        "label": "subtraction to integer",
        "family_predicate": "source family subtraction, target family integer",
        "rung_map_seams": [],
        "rung_map_seam_labels": [],
        "rung_table_endpoints": [
            "Whole-number subtraction -> signed integers "
            "(docs/research/2026-08-06-learner-paths.md:30)"
        ],
        "note": (
            "This rung is walkable and is therefore not one of the eight "
            "named seams. Wave 1's Ruling 5 recorded that R2 never crossed "
            "its schema and named the crossing R4's job, which is why the "
            "territory is read with the seams."
        ),
    },
    {
        "territory": 3,
        "label": "division to integer",
        "family_predicate": "source family division, target family integer",
        "rung_map_seams": [],
        "rung_map_seam_labels": [],
        "rung_table_endpoints": [
            "Whole-number subtraction -> signed integers "
            "(docs/research/2026-08-06-learner-paths.md:30)"
        ],
        "note": (
            "The integer-line gate reached from division. Same rung as "
            "territory 2, different source practice."
        ),
    },
    {
        "territory": 4,
        "label": "decimal at either endpoint",
        "family_predicate": "the decimal family is the source or the target",
        "rung_map_seams": [3, 4],
        "rung_map_seam_labels": [
            "Fraction units to decimal place units",
            "Fraction or decimal quantity to ordered ratio",
        ],
        "rung_table_endpoints": [
            "Fraction units -> decimal place units "
            "(docs/research/2026-08-06-learner-paths.md:32)",
            "Fraction/decimal quantities -> ordered ratios "
            "(docs/research/2026-08-06-learner-paths.md:33)",
        ],
        "note": (
            "Seam 3 asks for a fraction-to-decimal contract bridge, which is "
            "the adapter class this run instantiates."
        ),
    },
    {
        "territory": 5,
        "label": "counting to integer",
        "family_predicate": "source family counting, target family integer",
        "rung_map_seams": [1],
        "rung_map_seam_labels": [
            "Counting one by one to recursive place value"
        ],
        "rung_table_endpoints": [
            "Counting one by one -> recursive place value "
            "(docs/research/2026-08-06-learner-paths.md:29)",
            "Whole-number subtraction -> signed integers "
            "(docs/research/2026-08-06-learner-paths.md:30)",
        ],
        "note": (
            "The counting end belongs to seam 1; the integer end is the "
            "signed rung's gate. The territory touches both and sits on "
            "neither."
        ),
    },
    {
        "territory": 6,
        "label": "geometry and measurement co-measurement",
        "family_predicate": (
            "both families are drawn from geometry and measurement"
        ),
        "rung_map_seams": [6],
        "rung_map_seam_labels": [
            "Rational co-measurement to real-number measurement"
        ],
        "rung_table_endpoints": [
            "Rational co-measurement -> real-number measurement "
            "(docs/research/2026-08-06-learner-paths.md:37)"
        ],
        "note": (
            "The real-line completion machine is unauthored, so the seam's "
            "target end is absent. These rows are co-measurement traffic "
            "below it."
        ),
    },
    {
        "territory": 7,
        "label": "statistics and calculus, either direction",
        "family_predicate": (
            "the two families are exactly statistics and calculus"
        ),
        "rung_map_seams": [7],
        "rung_map_seam_labels": ["Finite relative frequency to a limit"],
        "rung_table_endpoints": [
            "Finite relative frequency -> sequence convergence "
            "(docs/research/2026-08-06-learner-paths.md:38)"
        ],
        "note": (
            "Seam 7 asks for a frequency-to-sequence tail bridge. A row here "
            "is a contract crossing between the two families, not that "
            "bridge."
        ),
    },
    {
        "territory": 8,
        "label": "algebraic to calculus",
        "family_predicate": "source family algebraic, target family calculus",
        "rung_map_seams": [8],
        "rung_map_seam_labels": ["Algebraic evaluation to function limit"],
        "rung_table_endpoints": [
            "Algebraic evaluation -> function limit "
            "(docs/research/2026-08-06-learner-paths.md:39)",
            "Substitution at a removable singularity -> factor, cancel, "
            "substitute (docs/research/2026-08-06-learner-paths.md:40)",
        ],
        "note": (
            "Seam 8 asks for a function-approach contract bridge. The "
            "approach and its warrant are absent from the tree."
        ),
    },
]

TERRITORY_PREDICATES: dict[int, Callable[[str, str], bool]] = {
    1: lambda s, t: {s, t} == {"fraction", "division"},
    2: lambda s, t: (s, t) == ("subtraction", "integer"),
    3: lambda s, t: (s, t) == ("division", "integer"),
    4: lambda s, t: "decimal" in (s, t),
    5: lambda s, t: (s, t) == ("counting", "integer"),
    6: lambda s, t: (
        s in ("geometry", "measurement") and t in ("geometry", "measurement")
    ),
    7: lambda s, t: {s, t} == {"statistics", "calculus"},
    8: lambda s, t: (s, t) == ("algebraic", "calculus"),
}

# Canonical seams the ruled territory list does not reach, recorded so the
# absence is a finding rather than a silence.
UNFLAGGED_SEAM_PROBES: list[dict[str, Any]] = [
    {
        "rung_map_seam": 4,
        "label": "Fraction or decimal quantity to ordered ratio",
        "unreached_half": "fraction and ratio, either direction",
        "predicate": lambda s, t: {s, t} == {"fraction", "ratio"},
        "note": (
            "Territory 4 reaches this seam only through its decimal side. "
            "Fraction-to-ratio rows carry no territory flag."
        ),
    },
    {
        "rung_map_seam": 5,
        "label": "Proportional equation to covariational function",
        "unreached_half": "ratio and algebraic, either direction",
        "predicate": lambda s, t: {s, t} == {"ratio", "algebraic"},
        "note": (
            "No territory in the ruled list covers this seam. Its "
            "covariational target machine is absent from the tree."
        ),
    },
]

TERM_FUNCTOR = re.compile(r"^([a-z][A-Za-z0-9_]*)\(")
BARE_ATOM = re.compile(r"^[a-z][A-Za-z0-9_]*$")
NUMBER_LITERAL = re.compile(r"^-?\d+(\.\d+)?(r\d+)?$")


def read_rows(
    directory: Path,
) -> tuple[list[dict[str, Any]], list[str], int]:
    """Read anchored R4 row files and report skipped names and file count."""
    if not directory.is_dir():
        raise FileNotFoundError(f"row directory not found: {directory}")
    matched: list[Path] = []
    skipped: list[str] = []
    for path in sorted(directory.rglob("*.jsonl")):
        if ROW_FILE_PATTERN.fullmatch(path.name):
            matched.append(path)
        else:
            skipped.append(str(path.relative_to(directory)))
    rows: list[dict[str, Any]] = []
    for path in matched:
        with path.open(encoding="utf-8") as handle:
            for number, line in enumerate(handle, start=1):
                line = line.strip()
                if not line:
                    continue
                try:
                    row = json.loads(line)
                except json.JSONDecodeError as error:
                    raise ValueError(f"{path}:{number}: {error}") from error
                row["_collection_file"] = path.name
                row["_collection_line"] = number
                rows.append(row)
    return rows, skipped, len(matched)


def machine(row: dict[str, Any], side: str) -> Machine | None:
    value = row.get(side) or {}
    family = value.get("family")
    kind = value.get("kind")
    if not family or not kind:
        return None
    return str(family), str(kind)


def machine_name(value: Machine | dict[str, Any] | None) -> str:
    if value is None:
        return "absent"
    if isinstance(value, tuple):
        return f"{value[0]}/{value[1]}"
    return f"{value.get('family')}/{value.get('kind')}"


def split_arguments(body: str) -> list[str]:
    """Split a Prolog argument list on its top-level commas."""
    depth = 0
    parts: list[str] = []
    current = ""
    for character in body:
        if character in "([{":
            depth += 1
        elif character in ")]}":
            depth -= 1
        if character == "," and depth == 0:
            parts.append(current)
            current = ""
        else:
            current += character
    parts.append(current)
    return parts


def answer_sort(term: Any) -> str | None:
    """Name the sort of answer a recorded result term carries.

    A refusal is not an answer and returns None. The driver's result/3
    comparison term holds the machine's own answer in its first argument.
    Prose placeholders, such as the note written when a source computed on
    too few points, also return None.
    """
    if term is None:
        return None
    text = str(term).strip()
    if not text:
        return None
    if text.startswith("refused("):
        return None
    match = TERM_FUNCTOR.match(text)
    if match and text.endswith(")"):
        functor = match.group(1)
        if functor == "result":
            arguments = split_arguments(text[len("result(") : -1])
            return answer_sort(arguments[0]) if arguments else None
        return functor
    if NUMBER_LITERAL.match(text):
        return "number"
    if BARE_ATOM.match(text):
        return text
    return None


def refusal_reason(term: Any) -> str | None:
    if term is None:
        return None
    text = str(term).strip()
    if not text.startswith("refused("):
        return None
    return text[len("refused(") : -1] if text.endswith(")") else text


def build_machine_contracts(
    rows: list[dict[str, Any]],
) -> dict[str, dict[str, Any]]:
    """Index every machine's declared schema and its recorded answer sorts.

    The contract rows come from the run itself. A schema string is declared;
    an answer sort is observed over the probed grid, and the observation is
    bounded by that grid.

    A target machine's outcome counts as an answer only where an adapted
    input reached it. On a warrant-refused row the target_outcome field
    carries the refusal record, such as dropped(centimeter), and a refusal
    record is not an answer.
    """
    index: dict[Machine, dict[str, Any]] = {}

    def slot(identity: Machine) -> dict[str, Any]:
        return index.setdefault(
            identity,
            {
                "family": identity[0],
                "kind": identity[1],
                "schema_as_source": Counter(),
                "schema_as_target": Counter(),
                "answer_sorts_as_source": Counter(),
                "answer_sorts_as_target": Counter(),
                "refusal_reasons_as_target": Counter(),
                "rows_as_source": 0,
                "rows_as_target": 0,
            },
        )

    for row in rows:
        evidence = row.get("evidence") or {}
        samples = evidence.get("sample_records") or []
        target_ran = any(
            sample.get("status") == "bridged" for sample in samples
        )
        source = machine(row, "source")
        target = machine(row, "target")
        if source is not None:
            record = slot(source)
            record["rows_as_source"] += 1
            if evidence.get("source_schema"):
                record["schema_as_source"][str(evidence["source_schema"])] += 1
            sort = answer_sort(evidence.get("source_outcome"))
            if sort is not None:
                record["answer_sorts_as_source"][sort] += 1
        if target is not None:
            record = slot(target)
            record["rows_as_target"] += 1
            if evidence.get("target_schema"):
                record["schema_as_target"][str(evidence["target_schema"])] += 1
            if target_ran:
                sort = answer_sort(evidence.get("target_outcome"))
                if sort is not None:
                    record["answer_sorts_as_target"][sort] += 1
            reason = refusal_reason(evidence.get("target_outcome"))
            if reason is not None:
                record["refusal_reasons_as_target"][reason] += 1
        for sample in samples:
            if source is not None:
                sort = answer_sort(sample.get("source_result"))
                if sort is not None:
                    slot(source)["answer_sorts_as_source"][sort] += 1
            if target is not None and sample.get("status") == "bridged":
                sort = answer_sort(sample.get("target_result"))
                if sort is not None:
                    slot(target)["answer_sorts_as_target"][sort] += 1

    contracts: dict[str, dict[str, Any]] = {}
    for identity, record in index.items():
        contracts[machine_name(identity)] = {
            "family": record["family"],
            "kind": record["kind"],
            "schema_as_source": sorted(record["schema_as_source"]),
            "schema_as_target": sorted(record["schema_as_target"]),
            "answer_sorts_as_source": dict(
                sorted(record["answer_sorts_as_source"].most_common())
            ),
            "answer_sorts_as_target": dict(
                sorted(record["answer_sorts_as_target"].most_common())
            ),
            "refusal_reasons_as_target": dict(
                record["refusal_reasons_as_target"].most_common(5)
            ),
            "rows_as_source": record["rows_as_source"],
            "rows_as_target": record["rows_as_target"],
        }
    return contracts


def contract_summary(contract: dict[str, Any] | None, side: str) -> dict[str, Any]:
    """Reduce a machine contract to what a docket cell has to carry."""
    if contract is None:
        return {"schema": None, "answer_sorts": []}
    schema = contract["schema_as_source" if side == "source" else "schema_as_target"]
    sorts = contract[
        "answer_sorts_as_source" if side == "source" else "answer_sorts_as_target"
    ]
    return {
        "schema": schema[0] if len(schema) == 1 else schema,
        "answer_sorts": sorted(sorts),
    }


def territories_of(source: Machine, target: Machine) -> list[int]:
    return [
        number
        for number, predicate in sorted(TERRITORY_PREDICATES.items())
        if predicate(source[0], target[0])
    ]


def witness_sample(
    samples: list[dict[str, Any]], count: int
) -> list[dict[str, Any]]:
    """Keep the first, a middle, and the last bridged sample."""
    bridged = [
        sample for sample in samples if sample.get("status") == "bridged"
    ]
    if not bridged:
        return []
    if len(bridged) <= count:
        chosen = list(range(len(bridged)))
    elif count == 1:
        chosen = [0]
    else:
        chosen = sorted(
            {
                round(index * (len(bridged) - 1) / (count - 1))
                for index in range(count)
            }
        )
    return [
        {
            "input": bridged[index].get("input"),
            "adapted_input": bridged[index].get("adapted_input"),
            "carried_value_exact": bridged[index].get("carried_value_exact"),
            "source_result": bridged[index].get("source_result"),
            "target_result": bridged[index].get("target_result"),
            "units": bridged[index].get("units"),
            "roles": bridged[index].get("roles"),
            "boundary": bridged[index].get("boundary"),
            "transform": bridged[index].get("transform"),
            "exactness": bridged[index].get("exactness"),
        }
        for index in chosen
    ]


def obligation_notes(samples: list[dict[str, Any]]) -> dict[str, list[str]]:
    """Collect the distinct discharge notes each obligation carried."""
    notes: defaultdict[str, Counter] = defaultdict(Counter)
    for sample in samples:
        if sample.get("status") != "bridged":
            continue
        for field in ("units", "roles", "boundary", "transform", "exactness"):
            value = sample.get(field)
            if value:
                notes[field][str(value)] += 1
    return {
        field: [text for text, _ in counter.most_common(3)]
        for field, counter in sorted(notes.items())
    }


def pair_indexes(
    rows: list[dict[str, Any]],
) -> tuple[dict[tuple[str, str], list[dict[str, Any]]], dict[str, int]]:
    """Group rows by their ordered machine pair."""
    by_pair: defaultdict[tuple[str, str], list[dict[str, Any]]] = defaultdict(list)
    malformed = 0
    for row in rows:
        source = machine(row, "source")
        target = machine(row, "target")
        if source is None or target is None:
            malformed += 1
            continue
        by_pair[(machine_name(source), machine_name(target))].append(row)
    return dict(by_pair), {"malformed_rows": malformed}


def warrant_summary(
    row: dict[str, Any],
    by_pair: dict[tuple[str, str], list[dict[str, Any]]],
) -> dict[str, Any]:
    """State what the adapter discharged and what its siblings refused."""
    evidence = row.get("evidence") or {}
    source_name = machine_name(row.get("source"))
    target_name = machine_name(row.get("target"))
    samples = evidence.get("sample_records") or []

    siblings = [
        other
        for other in by_pair.get((source_name, target_name), [])
        if other.get("key") != row.get("key")
    ]
    reverse = by_pair.get((target_name, source_name), [])

    sibling_refusals: Counter = Counter()
    for other in siblings:
        for refusal in (other.get("evidence") or {}).get("warrant_refusals") or []:
            sibling_refusals[
                (
                    (other.get("evidence") or {}).get("adapter"),
                    refusal.get("obligation"),
                    refusal.get("reason"),
                )
            ] += int(refusal.get("samples") or 0)

    return {
        "adapter": evidence.get("adapter"),
        "adapter_signature": evidence.get("adapter_signature"),
        "obligations": list(evidence.get("adapter_obligations") or []),
        "obligations_discharged": obligation_notes(samples),
        "own_warrant_refusals": list(evidence.get("warrant_refusals") or []),
        "samples_warranted": int(evidence.get("samples_warranted") or 0),
        "samples_target_refused": int(evidence.get("samples_target_refused") or 0),
        "sibling_rows_same_pair": {
            "count": len(siblings),
            "by_candidate_type": dict(
                sorted(Counter(
                    str(other.get("candidate_type")) for other in siblings
                ).items())
            ),
            "adapters": {
                str((other.get("evidence") or {}).get("adapter")):
                    str(other.get("candidate_type"))
                for other in siblings
            },
        },
        "reverse_direction_rows": {
            "count": len(reverse),
            "by_candidate_type": dict(
                sorted(Counter(
                    str(other.get("candidate_type")) for other in reverse
                ).items())
            ),
        },
        "sibling_warrant_refusals": [
            {
                "adapter": adapter,
                "obligation": obligation,
                "reason": reason,
                "samples": count,
            }
            for (adapter, obligation, reason), count in sorted(
                sibling_refusals.items(), key=lambda item: (-item[1], str(item[0]))
            )
        ],
    }


def docket_sort_key(row: dict[str, Any]) -> tuple[Any, ...]:
    """The ruled key: distinct adapted inputs first, then names."""
    evidence = row.get("evidence") or {}
    return (
        -int(evidence.get("distinct_adapted_inputs") or 0),
        machine_name(row.get("source")),
        machine_name(row.get("target")),
        str(evidence.get("adapter")),
    )


def build_docket_row(
    row: dict[str, Any],
    rank: int,
    band: str,
    partition: str | None,
    contracts: dict[str, dict[str, Any]],
    by_pair: dict[tuple[str, str], list[dict[str, Any]]],
    witness_count: int,
) -> dict[str, Any]:
    evidence = row.get("evidence") or {}
    source = machine(row, "source")
    target = machine(row, "target")
    if source is None or target is None:
        raise ValueError("a certified R4 row lacks a source or target machine")
    source_contract = contracts.get(machine_name(source))
    target_contract = contracts.get(machine_name(target))
    source_sorts = set(
        (source_contract or {}).get("answer_sorts_as_source") or {}
    )
    target_sorts = set(
        (target_contract or {}).get("answer_sorts_as_target") or {}
    )
    territories = territories_of(source, target)
    samples = evidence.get("sample_records") or []
    return {
        "rank": rank,
        "band": band,
        "partition": partition,
        "source": row.get("source"),
        "target": row.get("target"),
        "adapter": evidence.get("adapter"),
        "adapter_signature": evidence.get("adapter_signature"),
        "candidate_type": row.get("candidate_type"),
        "evidence_strength": evidence.get("evidence_strength"),
        "distinct_adapted_inputs": int(
            evidence.get("distinct_adapted_inputs") or 0
        ),
        "distinct_inputs_required": int(
            evidence.get("distinct_inputs_required") or 0
        ),
        "samples_bridged": int(evidence.get("samples_bridged") or 0),
        "samples_available": int(evidence.get("samples_available") or 0),
        "grid_points_available": int(evidence.get("grid_points_available") or 0),
        "grid_points_probed": int(evidence.get("grid_points_probed") or 0),
        "placement_path": evidence.get("placement_path"),
        "placement_index": evidence.get("placement_index"),
        "placements_available": evidence.get("placements_available"),
        "same_family": source[0] == target[0],
        "seam_relevant": territories,
        "warrant": warrant_summary(row, by_pair),
        "source_contract": contract_summary(source_contract, "source"),
        "target_contract": contract_summary(target_contract, "target"),
        "observed_answer_sort_overlap": sorted(source_sorts & target_sorts),
        "sample_witnesses": witness_sample(samples, witness_count),
        "sample_records_available": len(samples),
        "question_preservation": "",
        "source_row": {
            "key": row.get("key"),
            "item_key": row.get("item_key"),
            "file": row.get("_collection_file"),
            "line": row.get("_collection_line"),
        },
    }


def build_bands(
    rows: list[dict[str, Any]],
    contracts: dict[str, dict[str, Any]],
    by_pair: dict[tuple[str, str], list[dict[str, Any]]],
    witness_count: int,
) -> dict[str, Any]:
    certified = [
        row for row in rows if row.get("outcome") == "certified_candidate"
    ]
    typed = sorted(
        (
            row for row in certified
            if (row.get("evidence") or {}).get("adapter") != "identity"
        ),
        key=docket_sort_key,
    )
    identity = sorted(
        (
            row for row in certified
            if (row.get("evidence") or {}).get("adapter") == "identity"
        ),
        key=docket_sort_key,
    )

    band_one = [
        build_docket_row(row, rank, "typed_converters", None, contracts,
                         by_pair, witness_count)
        for rank, row in enumerate(typed, start=1)
    ]

    same_family: list[dict[str, Any]] = []
    cross_family: list[dict[str, Any]] = []
    for row in identity:
        source = machine(row, "source")
        target = machine(row, "target")
        if source is None or target is None:
            raise ValueError("an identity-adapter row lacks a machine")
        bucket = same_family if source[0] == target[0] else cross_family
        bucket.append(row)
    band_two = {
        "same_family": [
            build_docket_row(row, rank, "identity_bridges", "same_family",
                             contracts, by_pair, witness_count)
            for rank, row in enumerate(same_family, start=1)
        ],
        "cross_family": [
            build_docket_row(row, rank, "identity_bridges", "cross_family",
                             contracts, by_pair, witness_count)
            for rank, row in enumerate(cross_family, start=1)
        ],
    }
    return {"band_one": band_one, "band_two": band_two}


def seam_census(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    certified = [
        row for row in rows if row.get("outcome") == "certified_candidate"
    ]
    census = []
    for entry in SEAM_TERRITORIES:
        predicate = TERRITORY_PREDICATES[entry["territory"]]

        def matches(pool: list[dict[str, Any]]) -> list[dict[str, Any]]:
            hits = []
            for row in pool:
                source = machine(row, "source")
                target = machine(row, "target")
                if source is None or target is None:
                    continue
                if predicate(source[0], target[0]):
                    hits.append(row)
            return hits

        certified_hits = matches(certified)
        record = dict(entry)
        record["rows_all"] = len(matches(rows))
        record["rows_certified"] = len(certified_hits)
        record["rows_certified_typed_adapter"] = sum(
            1 for row in certified_hits
            if (row.get("evidence") or {}).get("adapter") != "identity"
        )
        record["rows_certified_identity_adapter"] = sum(
            1 for row in certified_hits
            if (row.get("evidence") or {}).get("adapter") == "identity"
        )
        census.append(record)
    return census


def unflagged_seam_census(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    certified = [
        row for row in rows if row.get("outcome") == "certified_candidate"
    ]
    census = []
    for probe in UNFLAGGED_SEAM_PROBES:
        predicate = probe["predicate"]
        count = 0
        for row in certified:
            source = machine(row, "source")
            target = machine(row, "target")
            if source is None or target is None:
                continue
            if predicate(source[0], target[0]):
                count += 1
        census.append({
            "rung_map_seam": probe["rung_map_seam"],
            "label": probe["label"],
            "unreached_half": probe["unreached_half"],
            "certified_rows_carrying_no_territory_flag": count,
            "note": probe["note"],
        })
    return census


def recompute_counts(
    rows: list[dict[str, Any]], file_count: int
) -> dict[str, int]:
    certified = [
        row for row in rows if row.get("outcome") == "certified_candidate"
    ]
    types = Counter(str(row.get("candidate_type")) for row in rows)
    adapters = Counter(
        str((row.get("evidence") or {}).get("adapter")) for row in certified
    )
    pairs, _ = pair_indexes(rows)
    counts = {
        "row_files": file_count,
        "rows_total": len(rows),
        "ordered_pairs": len(pairs),
        "certified_candidates": len(certified),
        "contract_bridge": types["contract_bridge"],
        "contract_bridge_thin_evidence": types["contract_bridge_thin_evidence"],
        "warrant_refused": types["warrant_refused"],
        "measured_incompatible": types["measured_incompatible"],
        "target_refused": types["target_refused"],
        "source_never_computed": types["source_never_computed"],
        "adapters_with_a_certified_row": len(adapters),
        "certified_identity": adapters["identity"],
    }
    for adapter in (
        "unit_relabel_with_scaling_witness",
        "integer_over_one_to_fraction_object",
        "project_wrapped_magnitude",
        "project_remainder",
        "project_quotient",
        "rename_fraction_to_fraction_object",
        "carry_measured_magnitude",
        "project_rational_magnitude",
        "rename_decimal_to_decimal_object",
    ):
        counts[f"certified_{adapter}"] = adapters[adapter]

    census = {entry["territory"]: entry for entry in seam_census(rows)}
    counts["certified_territory_fraction_division"] = census[1]["rows_certified"]
    counts["certified_territory_subtraction_and_division_to_integer"] = (
        census[2]["rows_certified"] + census[3]["rows_certified"]
    )
    counts["certified_territory_counting_to_integer"] = census[5]["rows_certified"]
    return counts


def cross_check_table(counts: dict[str, int]) -> list[dict[str, Any]]:
    table = []
    for key, label in COUNT_LABELS.items():
        stated = COLLECTION_NOTE.get(key)
        recomputed = counts[key]
        if stated is None:
            status = "the collection note states no figure"
            delta = None
        elif stated == recomputed:
            status = "agreement"
            delta = 0
        else:
            status = "discrepancy"
            delta = recomputed - stated
        table.append({
            "measure": label,
            "collection_note_2026_08_10": stated,
            "recomputed": recomputed,
            "delta": delta,
            "status": status,
        })
    return table


def compact_json(value: Any) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"))


def markdown_cell(value: Any) -> str:
    text = value if isinstance(value, str) else compact_json(value)
    return text.replace("|", "\\|").replace("\n", " ")


def seam_cell(territories: list[int]) -> str:
    if not territories:
        return ""
    labels = []
    for number in territories:
        entry = next(
            item for item in SEAM_TERRITORIES if item["territory"] == number
        )
        seams = entry["rung_map_seams"]
        suffix = (
            " seam " + "/".join(str(value) for value in seams) if seams
            else " signed rung"
        )
        labels.append(f"T{number}{suffix}")
    return "; ".join(labels)


def docket_table_lines(rows: list[dict[str, Any]]) -> list[str]:
    lines = [
        "| Rank | Source to target | Adapter | Distinct adapted inputs | "
        "Samples bridged | Evidence strength | Seam territory | "
        "Warrant | Contracts | Sample witnesses | Question preservation |",
        "|---:|---|---|---:|---:|---|---|---|---|---|---|",
    ]
    for row in rows:
        warrant = {
            "obligations": row["warrant"]["obligations"],
            "discharged": row["warrant"]["obligations_discharged"],
            "siblings_same_pair": row["warrant"]["sibling_rows_same_pair"][
                "by_candidate_type"
            ],
            "sibling_warrant_refusals": [
                f"{item['adapter']}: {item['obligation']} "
                f"{item['reason']} ({item['samples']})"
                for item in row["warrant"]["sibling_warrant_refusals"]
            ],
            "reverse_direction_rows": row["warrant"]["reverse_direction_rows"][
                "by_candidate_type"
            ],
        }
        contracts = {
            "source": row["source_contract"],
            "target": row["target_contract"],
            "observed_answer_sort_overlap": row["observed_answer_sort_overlap"],
        }
        lines.append(
            f"| {row['rank']} | {machine_name(row['source'])} to "
            f"{machine_name(row['target'])} | {row['adapter']} | "
            f"{row['distinct_adapted_inputs']} | {row['samples_bridged']} | "
            f"{row['evidence_strength']} | {seam_cell(row['seam_relevant'])} | "
            f"{markdown_cell(warrant)} | {markdown_cell(contracts)} | "
            f"{markdown_cell(row['sample_witnesses'])} |  |"
        )
    return lines


def render_markdown(payload: dict[str, Any], identity_md_rows: int) -> str:
    band_one = payload["band_one_typed_converters"]
    band_two = payload["band_two_identity_bridges"]
    same_family = band_two["same_family"]
    cross_family = band_two["cross_family"]
    adapters = Counter(row["adapter"] for row in band_one)
    seam_rows = [row for row in band_one if row["seam_relevant"]]
    seam_rows_identity = [
        row for row in same_family + cross_family if row["seam_relevant"]
    ]

    lines = [
        "# R4 admission docket: 2026-08-10",
        "",
        "This docket orders the R4 contract-bridge candidates for human "
        "ceremony review. No row is an admission and no row is a rejection. "
        "Question preservation is blank on every row: a bridge records that "
        "a receiver accepted a carried value inside its declared types, and "
        "acceptance is not agreement about the question asked.",
        "",
        "Evidence weight is distinct_adapted_inputs. Carrying one value into "
        "the varied slot collapses twenty samples to as few as eight, so "
        "samples_bridged overcounts a bridge's reach. The ceremony reads the "
        "distinct count and nothing else for weight; the other columns say "
        "what the row is, not how much it carries.",
        "",
        "The order is the one ruled after wave 1. Band 1 holds the typed "
        "converters, with the rows that touch a rung-map seam territory "
        "flagged inside it. Band 2 holds the identity-adapter bridges, the "
        "pun-risk class, partitioned mechanically into same-family and "
        "cross-family rows. The partition is arithmetic over family labels. "
        "Wave 1 already found that family is not the question-preservation "
        "test, so the partition orders the reading and settles nothing.",
        "",
        "## Population and count cross-check",
        "",
        "Every figure below was recomputed from the collected rows, matched "
        "by the anchored pattern r4_rows_NNNN.jsonl. Discrepancies are "
        "reported and left standing.",
        "",
        "| Measure | Collection note 2026-08-10 | Recomputed | Delta | Status |",
        "|---|---:|---:|---:|---|",
    ]
    for row in payload["count_cross_check"]:
        stated = "" if row["collection_note_2026_08_10"] is None else str(
            row["collection_note_2026_08_10"]
        )
        delta = "" if row["delta"] is None else f"{row['delta']:+d}"
        lines.append(
            f"| {row['measure']} | {stated} | {row['recomputed']} | "
            f"{delta} | {row['status']} |"
        )

    skipped = payload["row_files_skipped"]
    lines.extend([
        "",
        f"Row files skipped by the anchored pattern: {len(skipped)}"
        + (". " + "; ".join(skipped[:8]) if skipped else "."),
        "",
        "## Seam territories",
        "",
        "A territory is a family predicate over a directed row. The eight "
        "named seams are numbered as the R2 rung-map seam report numbers "
        "them; endpoint meanings come from the rung table of "
        "docs/research/2026-08-06-learner-paths.md. Territories 2 and 3 sit "
        "on the one walkable gate-genesis rung rather than a named seam, and "
        "carry no seam number. A row in a territory is near a seam; the "
        "seam's own endpoint machines are mostly unauthored, so no row here "
        "sits on a seam.",
        "",
        "| Territory | Family predicate | Rung-map seam | Certified rows | "
        "Typed adapter | Identity adapter | All rows | Note |",
        "|---:|---|---|---:|---:|---:|---:|---|",
    ])
    for entry in payload["seam_territories"]:
        seams = (
            ", ".join(
                f"{number} ({label})"
                for number, label in zip(
                    entry["rung_map_seams"], entry["rung_map_seam_labels"]
                )
            )
            or "none; " + entry["rung_table_endpoints"][0]
        )
        lines.append(
            f"| {entry['territory']} | {entry['family_predicate']} | {seams} | "
            f"{entry['rows_certified']} | "
            f"{entry['rows_certified_typed_adapter']} | "
            f"{entry['rows_certified_identity_adapter']} | "
            f"{entry['rows_all']} | {entry['note']} |"
        )

    lines.extend([
        "",
        "Named seams the ruled territory list does not reach:",
        "",
    ])
    for probe in payload["unflagged_canonical_seams"]:
        lines.append(
            f"- Seam {probe['rung_map_seam']}, {probe['label']}. Unreached "
            f"half: {probe['unreached_half']}. Certified rows carrying no "
            f"territory flag: "
            f"{probe['certified_rows_carrying_no_territory_flag']}. "
            f"{probe['note']}"
        )

    lines.extend([
        "",
        "## Band 1 — typed converters and seam-relevant bridges",
        "",
        f"{len(band_one)} rows, every certified row whose adapter is not the "
        "identity. Ranked by distinct adapted inputs, then by source name, "
        "target name, and adapter, so the order is reproducible. "
        f"{len(seam_rows)} of them touch a seam territory.",
        "",
        "Adapters in this band: " + "; ".join(
            f"{name} {count}" for name, count in sorted(adapters.items())
        ) + ".",
        "",
    ])
    lines.extend(docket_table_lines(band_one))

    lines.extend([
        "",
        "### Seam-relevant rows of band 1, relisted in rank order",
        "",
        "The same rows, gathered so the seam reading needs no re-sorting.",
        "",
    ])
    lines.extend(docket_table_lines(seam_rows))

    lines.extend([
        "",
        "## Band 2 — identity-adapter bridges",
        "",
        f"{len(same_family) + len(cross_family)} rows: "
        f"{len(same_family)} same-family and {len(cross_family)} "
        "cross-family. This is the pun-risk class. An identity adapter "
        "carries a value unchanged, so a bridge here records only that the "
        "receiver's slot accepts the source's number. Whether the receiver "
        "was asked the source's question is what the ceremony decides, and "
        "the contract columns carry both machines' declared schemas and "
        "recorded answer sorts so it can. The overlap column reports where "
        "the two recorded sort sets intersect over the probed grid. It is an "
        f"observation, never a verdict. {len(seam_rows_identity)} rows in "
        "this band also touch a seam territory.",
        "",
        f"The Markdown renders the first {identity_md_rows} ranked rows of "
        "each partition. The JSON carries every row.",
        "",
        "### Same-family identity bridges",
        "",
    ])
    lines.extend(docket_table_lines(same_family[:identity_md_rows]))

    lines.extend([
        "",
        "### Cross-family identity bridges",
        "",
    ])
    lines.extend(docket_table_lines(cross_family[:identity_md_rows]))

    lines.extend([
        "",
        "## Limits carried into the ceremony",
        "",
        "- Question preservation is not inferred from a shared numeral, a "
        "shared family, or an accepted carry.",
        "- Answer sorts are observed over the probed grid, not declared. A "
        "machine that answers in two sorts on a wider grid would widen the "
        "recorded set.",
        "- Evidence strength `design` means twenty distinct adapted inputs "
        "were reached; `grid_limited` means the grid ran out first. Neither "
        "speaks about inputs outside the authored grid.",
        "- The JSON carries at most a few sample witnesses per row. The full "
        "sample records stay in the collected rows, addressed by the file "
        "and line each docket row names.",
        "- A territory is proximity to a seam. Most seam endpoint machines "
        "are unauthored, so no row on this docket walks a seam.",
        "- Sibling counts describe the other adapters tried on the same "
        "ordered pair. A sibling refusal is evidence about that adapter, not "
        "about this one.",
        "",
    ])
    return "\n".join(lines)


def print_cross_check(table: list[dict[str, Any]]) -> None:
    print("\n== count cross-check ==", flush=True)
    print(
        f"{'measure':58s} | {'note':>7s} | {'recomputed':>10s} | "
        f"{'delta':>6s} | status",
        flush=True,
    )
    for row in table:
        stated = "-" if row["collection_note_2026_08_10"] is None else str(
            row["collection_note_2026_08_10"]
        )
        delta = "-" if row["delta"] is None else f"{row['delta']:+d}"
        print(
            f"{row['measure']:58s} | {stated:>7s} | {row['recomputed']:>10d} | "
            f"{delta:>6s} | {row['status']}",
            flush=True,
        )


def print_seams(census: list[dict[str, Any]]) -> None:
    print("\n== seam territories ==", flush=True)
    for entry in census:
        seams = (
            "/".join(str(value) for value in entry["rung_map_seams"])
            or "signed rung"
        )
        print(
            f"T{entry['territory']} {entry['label']:44s} | seam {seams:12s} | "
            f"certified {entry['rows_certified']:4d} "
            f"(typed {entry['rows_certified_typed_adapter']:4d}, "
            f"identity {entry['rows_certified_identity_adapter']:4d}) | "
            f"all rows {entry['rows_all']:5d}",
            flush=True,
        )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rows", type=Path, default=DEFAULT_ROWS)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    parser.add_argument("--identity-md-rows", type=int, default=100)
    parser.add_argument("--witnesses", type=int, default=3)
    arguments = parser.parse_args()

    rows, skipped, file_count = read_rows(arguments.rows)
    print(f"row files read              : {file_count}", flush=True)
    print(f"row files skipped           : {len(skipped)}", flush=True)
    for name in skipped[:10]:
        print(f"  skipped {name}", flush=True)
    print(f"rows on disk                : {len(rows)}", flush=True)

    contracts = build_machine_contracts(rows)
    by_pair, pair_notes = pair_indexes(rows)
    if pair_notes["malformed_rows"]:
        print(
            f"rows lacking a machine      : {pair_notes['malformed_rows']}",
            flush=True,
        )

    bands = build_bands(rows, contracts, by_pair, arguments.witnesses)
    counts = recompute_counts(rows, file_count)
    table = cross_check_table(counts)
    census = seam_census(rows)
    unflagged = unflagged_seam_census(rows)

    print_cross_check(table)
    print_seams(census)

    band_one = bands["band_one"]
    band_two = bands["band_two"]
    payload = {
        "generated_for": "2026-08-10 R4 admission ceremony",
        "source_directory": str(arguments.rows),
        "row_file_pattern": ROW_FILE_PATTERN.pattern,
        "row_files_read": file_count,
        "row_files_skipped": skipped,
        "rows_lacking_a_machine": pair_notes["malformed_rows"],
        "ceremony_rules": {
            "automatic_admission": False,
            "automatic_rejection": False,
            "question_preservation_default": "",
            "evidence_weight": "distinct_adapted_inputs",
            "band_order": [
                "typed converters and seam-relevant bridges",
                "identity-adapter bridges, partitioned by family",
            ],
            "identity_band_partition": (
                "same-family against cross-family, arithmetic over family "
                "labels; wave 1 found family is not the question-preservation "
                "test"
            ),
        },
        "recomputed_counts": counts,
        "count_cross_check": table,
        "seam_territories": census,
        "unflagged_canonical_seams": unflagged,
        "band_one_typed_converters": band_one,
        "band_two_identity_bridges": band_two,
        "band_counts": {
            "typed_converters": len(band_one),
            "typed_converters_seam_relevant": sum(
                1 for row in band_one if row["seam_relevant"]
            ),
            "identity_same_family": len(band_two["same_family"]),
            "identity_cross_family": len(band_two["cross_family"]),
            "identity_seam_relevant": sum(
                1 for row in band_two["same_family"] + band_two["cross_family"]
                if row["seam_relevant"]
            ),
        },
        "machine_contracts": contracts,
    }

    arguments.output_dir.mkdir(parents=True, exist_ok=True)
    json_path = arguments.output_dir / f"{DOCKET_STEM}.json"
    markdown_path = arguments.output_dir / f"{DOCKET_STEM}.md"
    json_path.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    markdown_path.write_text(
        render_markdown(payload, arguments.identity_md_rows), encoding="utf-8"
    )

    print("\n== bands ==", flush=True)
    print(f"band 1 typed converters     : {len(band_one)}", flush=True)
    print(
        "  of them seam-relevant     : "
        f"{payload['band_counts']['typed_converters_seam_relevant']}",
        flush=True,
    )
    print(
        f"band 2 identity same-family : {len(band_two['same_family'])}",
        flush=True,
    )
    print(
        f"band 2 identity cross-family: {len(band_two['cross_family'])}",
        flush=True,
    )
    print(
        "  of them seam-relevant     : "
        f"{payload['band_counts']['identity_seam_relevant']}",
        flush=True,
    )
    print(f"machines with a contract row: {len(contracts)}", flush=True)
    print(f"\nMarkdown docket             : {markdown_path}", flush=True)
    print(f"JSON docket                 : {json_path}", flush=True)
    discrepancies = [row for row in table if row["status"] == "discrepancy"]
    print(f"cross-check discrepancies   : {len(discrepancies)}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
