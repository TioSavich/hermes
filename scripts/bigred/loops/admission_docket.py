#!/usr/bin/env python3
"""Build the R1/R2 admission docket and the R2 closure backfill manifests.

The collected rows are read-only evidence. This tool writes two local,
gitignored ceremony artifacts under docs/research/internal and uses the
authored step-0 sharding functions for the timeout backfill manifests.

Question preservation remains blank. A release shows that a receiver computes
where a source refuses; it does not establish that both machines answer the
same question from the same numerals.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

import step0_manifests as step0


ROOT = Path(__file__).resolve().parents[3]
DEFAULT_R1_ROWS = (
    ROOT / ".bigred-collected/2026-08-08-loops-wave1-r1/rows"
)
DEFAULT_R2_ROWS = (
    ROOT / ".bigred-collected/2026-08-08-loops-wave2-r2/rows"
)
DEFAULT_R2_BACKFILL_ROWS = (
    ROOT / ".bigred-collected/2026-08-10-loops-wave2-r2-backfill/rows"
)
DEFAULT_OUTPUT_DIR = ROOT / "docs/research/internal"
DEFAULT_BACKFILL_DIR = (
    ROOT / ".bigred-output/2026-08-09-loops-wave2-r2-backfill"
)
DOCKET_STEM = "2026-08-09-admission-docket"

TRANSIENT_COUNTS = {
    "r2_candidates": 1875,
    "l1_exclusive": 398,
    "l2_first": 246,
    "l3_not_l2": 1207,
    "r1_equalizers": 142,
    "r2_timeouts": 136,
}

Machine = tuple[str, str]
Pair = tuple[Machine, Machine]
Direction = tuple[str, str, str, str]


class AccountingError(RuntimeError):
    """The collected row population cannot be reconciled to expected items."""


def read_rows(directory: Path) -> list[dict[str, Any]]:
    """Read every JSONL row below a collection directory."""
    if not directory.is_dir():
        raise FileNotFoundError(f"row directory not found: {directory}")
    rows: list[dict[str, Any]] = []
    for path in sorted(directory.rglob("*.jsonl")):
        with path.open(encoding="utf-8") as handle:
            for number, line in enumerate(handle, start=1):
                line = line.strip()
                if not line:
                    continue
                try:
                    row = json.loads(line)
                except json.JSONDecodeError as error:
                    raise ValueError(f"{path}:{number}: {error}") from error
                row["_collection_file"] = str(path.relative_to(directory))
                row["_collection_line"] = number
                rows.append(row)
    return rows


def machine(row: dict[str, Any], side: str) -> Machine | None:
    value = row.get(side) or {}
    family = value.get("family")
    kind = value.get("kind")
    if not family or not kind:
        return None
    return str(family), str(kind)


def canonical_pair(left: Machine, right: Machine) -> Pair:
    return tuple(sorted((left, right)))  # type: ignore[return-value]


def direction_id(left: Machine, right: Machine) -> Direction:
    return left[0], left[1], right[0], right[1]


def machine_name(value: Machine | dict[str, Any]) -> str:
    if isinstance(value, tuple):
        return f"{value[0]}/{value[1]}"
    return f"{value.get('family')}/{value.get('kind')}"


def close_r2_accounting(
    r1_rows: list[dict[str, Any]], r2_rows: list[dict[str, Any]]
) -> dict[str, Any]:
    """Reconcile expected pair directions and singleton rows to disk."""
    expected_pair_orientations: dict[Pair, tuple[str, str, str, str]] = {}
    for row in r1_rows:
        left = machine(row, "source")
        right = machine(row, "target")
        if left is None or right is None:
            raise AccountingError("an R1 row lacks a source or target machine")
        pair = canonical_pair(left, right)
        orientation = (left[0], left[1], right[0], right[1])
        if pair in expected_pair_orientations:
            raise AccountingError(
                f"duplicate R1 unordered pair: {machine_name(left)} | "
                f"{machine_name(right)}"
            )
        expected_pair_orientations[pair] = orientation

    expected_directions: set[Direction] = set()
    for left, right in expected_pair_orientations:
        expected_directions.add(direction_id(left, right))
        expected_directions.add(direction_id(right, left))

    singleton_machines = set(step0.singleton_machines())
    expected_singletons = {tuple(value) for value in singleton_machines}

    observed_counts: Counter[tuple[Any, ...]] = Counter()
    observed_pair_rows: defaultdict[Pair, list[dict[str, Any]]] = defaultdict(list)
    malformed_rows = 0
    for row in r2_rows:
        left = machine(row, "source")
        right = machine(row, "target")
        if left is None:
            malformed_rows += 1
            continue
        if right is None:
            observed_counts[("singleton", *left)] += 1
            continue
        identity = ("direction", *direction_id(left, right))
        observed_counts[identity] += 1
        observed_pair_rows[canonical_pair(left, right)].append(row)

    expected_ids = {
        ("direction", *identity) for identity in expected_directions
    } | {("singleton", *identity) for identity in expected_singletons}
    observed_ids = set(observed_counts)
    duplicate_rows = sum(count - 1 for count in observed_counts.values())
    unexpected_ids = observed_ids - expected_ids
    unexpected_rows = sum(observed_counts[value] for value in unexpected_ids)
    missing_ids = expected_ids - observed_ids
    missing_directions = {
        value[1:] for value in missing_ids if value[0] == "direction"
    }
    missing_singletons = {
        value[1:] for value in missing_ids if value[0] == "singleton"
    }

    timeout_pairs: set[Pair] = set()
    for pair, rows in observed_pair_rows.items():
        if any(row.get("outcome") == "timeout" for row in rows):
            timeout_pairs.add(pair)
    missing_direction_pairs = {
        canonical_pair((value[0], value[1]), (value[2], value[3]))
        for value in missing_directions
    }
    backfill_pairs = sorted(timeout_pairs | missing_direction_pairs)

    expected_normal = len(expected_directions)
    expected_singleton_count = len(expected_singletons)
    expected_total = expected_normal + expected_singleton_count
    on_disk = len(r2_rows)
    explained_present = on_disk - duplicate_rows - unexpected_rows - malformed_rows
    reconciliation_sum = explained_present + len(missing_ids)
    unexplained = expected_total - reconciliation_sum

    accounting = {
        "expected_unordered_pairs": len(expected_pair_orientations),
        "expected_directed_rows": expected_normal,
        "expected_singleton_rows": expected_singleton_count,
        "expected_total_rows": expected_total,
        "on_disk_rows": on_disk,
        "present_expected_unique_rows": len(expected_ids & observed_ids),
        "missing_directed_rows": len(missing_directions),
        "missing_singleton_rows": len(missing_singletons),
        "timeout_rows": sum(row.get("outcome") == "timeout" for row in r2_rows),
        "duplicate_rows": duplicate_rows,
        "unexpected_rows": unexpected_rows,
        "malformed_rows": malformed_rows,
        "reconciliation_sum": reconciliation_sum,
        "unexplained_rows": unexplained,
        "backfill_pair_count": len(backfill_pairs),
        "backfill_pairs": [
            {
                "source": {"family": pair[0][0], "kind": pair[0][1]},
                "target": {"family": pair[1][0], "kind": pair[1][1]},
                "has_timeout": pair in timeout_pairs,
                "missing_directions": [
                    {
                        "source": {"family": value[0], "kind": value[1]},
                        "target": {"family": value[2], "kind": value[3]},
                    }
                    for value in sorted(missing_directions)
                    if canonical_pair(
                        (value[0], value[1]), (value[2], value[3])
                    ) == pair
                ],
            }
            for pair in backfill_pairs
        ],
        "_manifest_pairs": [expected_pair_orientations[pair] for pair in backfill_pairs],
    }

    if (
        unexplained != 0
        or duplicate_rows
        or unexpected_rows
        or malformed_rows
        or missing_singletons
    ):
        raise AccountingError(
            "R2 accounting did not close: "
            f"expected={expected_total}, on_disk={on_disk}, "
            f"missing={len(missing_ids)}, duplicates={duplicate_rows}, "
            f"unexpected={unexpected_rows}, malformed={malformed_rows}, "
            f"unexplained={unexplained}"
        )
    return accounting


def write_backfill_manifests(
    accounting: dict[str, Any], r1_directory: Path, output_dir: Path,
    pairs_per_task: int, pair_budget_s: float, input_timeout_s: float,
    max_witnesses: int,
) -> list[Path]:
    """Use step0's measured-cost interleaving and R2 row authoring."""
    pairs = accounting["_manifest_pairs"]
    costs = step0.measured_pair_cost(r1_directory)
    shards = step0.write_r2_shards(
        pairs,
        [],
        output_dir,
        pairs_per_task,
        pair_budget_s,
        input_timeout_s,
        max_witnesses,
        costs,
    )
    (output_dir / "rows").mkdir(parents=True, exist_ok=True)
    return shards


def r2_band(row: dict[str, Any]) -> str:
    flags = (row.get("evidence") or {}).get("lens_flags") or {}
    if flags.get("l2") is True:
        return "L2"
    if flags.get("l3") is True:
        return "L3-not-L2"
    if flags.get("l1") is True:
        return "L1-only"
    return "flagless"


def r2_sort_key(row: dict[str, Any]) -> tuple[Any, ...]:
    evidence = row.get("evidence") or {}
    flags = evidence.get("lens_flags") or {}
    band = r2_band(row)
    order = {"L2": 0, "L3-not-L2": 1, "L1-only": 2, "flagless": 3}
    if band == "L2":
        strength = int(flags.get("strong_released_points") or 0)
        has_out_witness = evidence.get("out_of_region_incorrect_witness") is not None
        rank = (-strength, -int(has_out_witness), -int(evidence.get("released_count") or 0))
    else:
        rank = (-int(evidence.get("released_count") or 0), 0, 0)
    return (
        order[band],
        *rank,
        machine_name(row.get("source") or {}),
        machine_name(row.get("target") or {}),
    )


def witness_sample(witnesses: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Keep first, last, and one middle witness without duplicates."""
    if not witnesses:
        return []
    indices = [0, len(witnesses) - 1, len(witnesses) // 2]
    result = []
    seen: set[int] = set()
    for index in indices:
        if index not in seen:
            result.append(witnesses[index])
            seen.add(index)
    return result


def license_index(r2_rows: list[dict[str, Any]]) -> dict[Machine, dict[str, Any]]:
    licenses: dict[Machine, dict[str, Any]] = {}
    for row in r2_rows:
        target = machine(row, "target")
        license_row = (row.get("evidence") or {}).get("license")
        if target is None or not isinstance(license_row, dict) or not license_row:
            continue
        previous = licenses.get(target)
        if previous is not None and previous != license_row:
            raise ValueError(f"conflicting contract rows for {machine_name(target)}")
        licenses[target] = license_row
    return licenses


def build_r2_docket(r2_rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    candidates = [
        row for row in r2_rows
        if row.get("outcome") == "certified_candidate"
        and row.get("candidate_type") == "crisis_release"
    ]
    candidates.sort(key=r2_sort_key)
    licenses = license_index(r2_rows)
    docket = []
    for rank, row in enumerate(candidates, start=1):
        source = machine(row, "source")
        target = machine(row, "target")
        if source is None or target is None:
            raise ValueError("an R2 candidate lacks a source or target machine")
        evidence = row.get("evidence") or {}
        witnesses = list(evidence.get("released_witnesses") or [])
        target_license = evidence.get("license") or licenses.get(target) or {}
        docket.append({
            "rank": rank,
            "band": r2_band(row),
            "source": row["source"],
            "target": row["target"],
            "source_outcome": evidence.get("source_outcome"),
            "target_outcome": evidence.get("target_outcome"),
            "released_count": int(evidence.get("released_count") or 0),
            "released_validity_counts": evidence.get("released_validity_counts") or {},
            "lens_flags": evidence.get("lens_flags") or {},
            "license_citation": target_license,
            "source_contract": licenses.get(source) or {},
            "target_contract": target_license,
            "sample_witnesses": witness_sample(witnesses),
            "released_witnesses": witnesses,
            "witnesses_truncated": bool(evidence.get("witnesses_truncated")),
            "out_of_region_incorrect_witness": evidence.get(
                "out_of_region_incorrect_witness"
            ),
            "question_preservation": "",
            "source_row": {
                "key": row.get("key"),
                "item_key": row.get("item_key"),
                "file": row.get("_collection_file"),
                "line": row.get("_collection_line"),
            },
        })
    return docket


def partial_direction(row: dict[str, Any]) -> dict[str, Any]:
    """Retain one directed row's measured partial-walk evidence."""
    evidence = row.get("evidence") or {}
    witnesses = list(evidence.get("released_witnesses") or [])
    return {
        "source": row.get("source"),
        "target": row.get("target"),
        "outcome": row.get("outcome"),
        "candidate_type": row.get("candidate_type"),
        "walk": evidence.get("walk"),
        "reason": evidence.get("reason"),
        "outcomes_so_far": {
            "source": evidence.get("source_outcome"),
            "target": evidence.get("target_outcome"),
            "released_validity_counts": (
                evidence.get("released_validity_counts") or {}
            ),
        },
        "released_count": int(evidence.get("released_count") or 0),
        "lens_flags": evidence.get("lens_flags") or {},
        "retained_point_outcomes": witnesses,
        "sample_point_outcomes": witness_sample(witnesses),
        "point_outcomes_truncated": bool(evidence.get("witnesses_truncated")),
        "source_row": {
            "key": row.get("key"),
            "item_key": row.get("item_key"),
            "file": row.get("_collection_file"),
            "line": row.get("_collection_line"),
        },
    }


def pair_grid_coverage(rows: list[dict[str, Any]]) -> dict[str, Any]:
    """Recover a pair's shared walk numerator and planned denominator."""
    walked_values = sorted({
        value
        for row in rows
        for value in [(row.get("evidence") or {}).get("walked_points")]
        if isinstance(value, int) and not isinstance(value, bool) and value >= 0
    })
    planned_values = sorted({
        value
        for row in rows
        for value in [(row.get("input") or {}).get("points")]
        if isinstance(value, int) and not isinstance(value, bool) and value > 0
    })
    limits: list[str] = []
    walked = walked_values[0] if len(walked_values) == 1 else None
    planned = planned_values[0] if len(planned_values) == 1 else None
    if not walked_values:
        limits.append("points walked are not recoverable from these rows")
    elif len(walked_values) > 1:
        limits.append(
            "directed rows carry different points-walked values; no shared "
            "numerator is reported"
        )
    if not planned_values:
        limits.append(
            "planned grid size is not recoverable from these rows; coverage "
            "ratio is unavailable"
        )
    elif len(planned_values) > 1:
        limits.append(
            "directed rows carry different planned grid sizes; no shared "
            "denominator is reported"
        )

    ratio = None
    percent = None
    if walked is not None and planned is not None:
        ratio = round(walked / planned, 6)
        percent = round(100 * walked / planned, 2)
    return {
        "points_walked": walked,
        "planned_grid_points": planned,
        "coverage_ratio": ratio,
        "coverage_percent": percent,
        "observed_points_walked_values": walked_values,
        "observed_planned_grid_values": planned_values,
        "limit": "; ".join(limits),
    }


def partial_coverage_band(coverage: dict[str, Any]) -> str:
    percent = coverage.get("coverage_percent")
    if percent is None:
        return "denominator_unavailable"
    if percent >= 100:
        return "complete"
    if percent >= 90:
        return "90_to_under_100_percent"
    if percent >= 50:
        return "50_to_under_90_percent"
    if percent > 0:
        return "over_0_to_under_50_percent"
    return "zero_percent"


def build_r2_partial_evidence(
    rows: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    """Group residual timeout evidence into one entry per unordered pair."""
    pairs: defaultdict[Pair, list[dict[str, Any]]] = defaultdict(list)
    for row in rows:
        source = machine(row, "source")
        target = machine(row, "target")
        if source is None or target is None:
            continue
        pairs[canonical_pair(source, target)].append(row)

    entries = []
    for pair, pair_rows in pairs.items():
        timeout_rows = [
            row for row in pair_rows if row.get("outcome") == "timeout"
        ]
        if not timeout_rows:
            continue
        directions = sorted(
            (partial_direction(row) for row in pair_rows),
            key=lambda row: (
                machine_name(row.get("source") or {}),
                machine_name(row.get("target") or {}),
            ),
        )
        coverage = pair_grid_coverage(pair_rows)
        l2_timeout_rows = sum(
            ((row.get("evidence") or {}).get("lens_flags") or {}).get("l2")
            is True
            for row in timeout_rows
        )
        entries.append({
            "rank": 0,
            "priority": "L2" if l2_timeout_rows else "other",
            "l2_flagged": bool(l2_timeout_rows),
            "l2_flagged_timeout_rows": l2_timeout_rows,
            "pair": {
                "first": {"family": pair[0][0], "kind": pair[0][1]},
                "second": {"family": pair[1][0], "kind": pair[1][1]},
            },
            "timeout_row_count": len(timeout_rows),
            "grid_coverage": coverage,
            "coverage_band": partial_coverage_band(coverage),
            "directions": directions,
            "question_preservation": "",
        })

    entries.sort(key=lambda entry: (
        not entry["l2_flagged"],
        -float(
            entry["grid_coverage"]["coverage_ratio"]
            if entry["grid_coverage"]["coverage_ratio"] is not None
            else -1
        ),
        machine_name(entry["pair"]["first"]),
        machine_name(entry["pair"]["second"]),
    ))
    for rank, entry in enumerate(entries, start=1):
        entry["rank"] = rank
    return entries


def partial_evidence_summary(
    entries: list[dict[str, Any]],
) -> dict[str, Any]:
    distribution = Counter(entry["coverage_band"] for entry in entries)
    return {
        "entry_count": len(entries),
        "timeout_row_count": sum(
            entry["timeout_row_count"] for entry in entries
        ),
        "l2_flagged_entry_count": sum(entry["l2_flagged"] for entry in entries),
        "l2_flagged_timeout_row_count": sum(
            entry["l2_flagged_timeout_rows"] for entry in entries
        ),
        "coverage_ratio_available_entries": sum(
            entry["grid_coverage"]["coverage_ratio"] is not None
            for entry in entries
        ),
        "coverage_distribution": {
            name: distribution[name]
            for name in (
                "complete",
                "90_to_under_100_percent",
                "50_to_under_90_percent",
                "over_0_to_under_50_percent",
                "zero_percent",
                "denominator_unavailable",
            )
        },
    }


def action_automaton_pairs() -> dict[str, list[dict[str, str]]]:
    """Read the live action_automaton_pair/4 registry through its Prolog API."""
    goal = (
        "use_module(strategies('math/action_automata_registry'), []), "
        "forall(action_automata_registry:action_automaton_pair(O,P,D,F), "
        "format('~w\\t~w\\t~w\\t~w~n', [O,P,D,F]))"
    )
    completed = subprocess.run(
        ["swipl", "-q", "-l", str(ROOT / "paths.pl"), "-g", goal, "-t", "halt"],
        cwd=str(ROOT),
        text=True,
        capture_output=True,
        timeout=300,
        check=False,
    )
    if completed.returncode:
        raise RuntimeError(
            "action_automaton_pair/4 query failed: "
            + completed.stderr.strip()[:800]
        )
    by_deformation: defaultdict[str, list[dict[str, str]]] = defaultdict(list)
    for line in completed.stdout.splitlines():
        fields = line.split("\t")
        if len(fields) != 4:
            continue
        operation, productive, deformation, family = fields
        by_deformation[deformation].append({
            "operation": operation,
            "productive": productive,
            "deformation": deformation,
            "family": family,
        })
    return dict(by_deformation)


def build_r1_docket(r1_rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    registry = action_automaton_pairs()
    equalizers = [
        row for row in r1_rows
        if row.get("outcome") == "certified_candidate"
        and row.get("candidate_type") == "behavioural_equivalence"
    ]
    equalizers.sort(
        key=lambda row: (
            machine_name(row.get("source") or {}),
            machine_name(row.get("target") or {}),
        )
    )
    docket = []
    for row in equalizers:
        source = machine(row, "source")
        target = machine(row, "target")
        if source is None or target is None:
            classification = "unclassified"
            basis = "source or target machine is absent"
            matches: list[dict[str, str]] = []
        elif source[0] == target[0]:
            classification = "same_operation_answer_equivalence"
            basis = "the two machines carry the same operation family"
            matches = []
        else:
            matches = [
                match for match in registry.get(source[1], [])
                if match["operation"] == target[0]
            ] + [
                match for match in registry.get(target[1], [])
                if match["operation"] == source[0]
            ]
            if matches:
                classification = "misconception_is_other_operation_identity"
                basis = (
                    "the cross-operation full-agreement pair contains a "
                    "registered deformation whose operation is the other "
                    "machine's family"
                )
            else:
                classification = "unforeseen"
                basis = (
                    "the pair is cross-operation and neither deformation "
                    "registry row names the other machine's family"
                )
        evidence = row.get("evidence") or {}
        docket.append({
            "source": row.get("source"),
            "target": row.get("target"),
            "class": classification,
            "classification_basis": basis,
            "action_automaton_pair_matches": matches,
            "joint_computed_points": int(evidence.get("ran") or 0),
            "joint_agreement_points": int(evidence.get("coincide") or 0),
            "joint_refusal_points": int(evidence.get("refused") or 0),
            "full_agreement": bool(evidence.get("full_agreement")),
            "source_row": {
                "key": row.get("key"),
                "file": row.get("_collection_file"),
                "line": row.get("_collection_line"),
            },
        })
    return docket


def directed_index(r2_rows: list[dict[str, Any]]) -> dict[Direction, dict[str, Any]]:
    index: dict[Direction, dict[str, Any]] = {}
    for row in r2_rows:
        source = machine(row, "source")
        target = machine(row, "target")
        if source is None or target is None:
            continue
        identity = direction_id(source, target)
        if identity in index:
            raise ValueError(f"duplicate R2 direction: {identity}")
        index[identity] = row
    return index


def build_vpv_prime(
    r1_rows: list[dict[str, Any]], r2_rows: list[dict[str, Any]]
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    """Compute the fully supportable conservative-extension proxy."""
    index = directed_index(r2_rows)
    candidates: list[dict[str, Any]] = []
    unsupported: list[dict[str, Any]] = []
    for r1_row in r1_rows:
        evidence = r1_row.get("evidence") or {}
        if not (
            r1_row.get("candidate_type") == "behavioural_equivalence"
            and r1_row.get("outcome") == "certified_candidate"
            and evidence.get("full_agreement") is True
        ):
            continue
        left = machine(r1_row, "source")
        right = machine(r1_row, "target")
        if left is None or right is None:
            continue
        for source, target in ((left, right), (right, left)):
            forward = index.get(direction_id(source, target))
            reverse = index.get(direction_id(target, source))
            if forward is None or reverse is None:
                unsupported.append({
                    "source": {"family": source[0], "kind": source[1]},
                    "target": {"family": target[0], "kind": target[1]},
                    "reason": "one or both R2 directed rows are absent",
                    "r1_key": r1_row.get("key"),
                })
                continue
            forward_evidence = forward.get("evidence") or {}
            reverse_evidence = reverse.get("evidence") or {}
            if (
                "released_count" not in forward_evidence
                or "released_count" not in reverse_evidence
            ):
                unsupported.append({
                    "source": {"family": source[0], "kind": source[1]},
                    "target": {"family": target[0], "kind": target[1]},
                    "reason": "an R2 row lacks per-direction released_count",
                    "r1_key": r1_row.get("key"),
                })
                continue

            released = int(forward_evidence.get("released_count") or 0)
            reverse_released = int(reverse_evidence.get("released_count") or 0)
            criterion_i = reverse_released == 0
            criterion_ii = (
                evidence.get("full_agreement") is True
                and int(evidence.get("coincide") or 0)
                == int(evidence.get("ran") or 0)
            )
            joint_region = int(evidence.get("ran") or 0)
            criterion_iii = joint_region >= 100
            criterion_iv = (
                released > 0
                and forward.get("candidate_type") == "crisis_release"
                and forward.get("outcome") == "certified_candidate"
            )
            if not (criterion_i and criterion_ii and criterion_iv):
                continue
            candidates.append({
                "source": {"family": source[0], "kind": source[1]},
                "target": {"family": target[0], "kind": target[1]},
                "criteria": {
                    "receiver_refuses_nowhere_source_computes": criterion_i,
                    "joint_computed_region_full_agreement": criterion_ii,
                    "joint_computed_region_at_least_100": criterion_iii,
                    "source_to_receiver_release_nonempty": criterion_iv,
                },
                "joint_computed_points": joint_region,
                "released_count": released,
                "reverse_released_count": reverse_released,
                "below_evidence_floor": not criterion_iii,
                "ceremony_status": "candidate_not_admitted",
                "r1_key": r1_row.get("key"),
                "r2_key": forward.get("key"),
                "reverse_r2_key": reverse.get("key"),
            })
    candidates.sort(
        key=lambda row: (
            row["below_evidence_floor"],
            -row["joint_computed_points"],
            -row["released_count"],
            machine_name(row["source"]),
            machine_name(row["target"]),
        )
    )
    return candidates, unsupported


def count_cross_check(
    r1_docket: list[dict[str, Any]], r2_docket: list[dict[str, Any]],
    r2_rows: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    bands = Counter(row["band"] for row in r2_docket)
    actual = {
        "r2_candidates": len(r2_docket),
        "l1_exclusive": bands["L1-only"],
        "l2_first": bands["L2"],
        "l3_not_l2": bands["L3-not-L2"],
        "r1_equalizers": len(r1_docket),
        "r2_timeouts": sum(row.get("outcome") == "timeout" for row in r2_rows),
    }
    labels = {
        "r2_candidates": "R2 crisis candidates",
        "l1_exclusive": "R2 L1-only band",
        "l2_first": "R2 L2-first band",
        "l3_not_l2": "R2 L3-not-L2 band",
        "r1_equalizers": "R1 equalizers",
        "r2_timeouts": "R2 timeout rows",
    }
    return [
        {
            "measure": labels[key],
            "transient_2026_08_08": TRANSIENT_COUNTS[key],
            "recomputed": actual[key],
            "delta": actual[key] - TRANSIENT_COUNTS[key],
            "status": (
                "agreement" if actual[key] == TRANSIENT_COUNTS[key]
                else "discrepancy"
            ),
        }
        for key in TRANSIENT_COUNTS
    ]


def compact_json(value: Any) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"))


def markdown_cell(value: Any) -> str:
    text = value if isinstance(value, str) else compact_json(value)
    return text.replace("|", "\\|").replace("\n", " ")


def render_markdown(payload: dict[str, Any]) -> str:
    accounting = payload["accounting"]
    cross_check = payload["count_cross_check"]
    r2_docket = payload["r2_docket"]
    partial_evidence = payload["r2_timeout_partial_evidence"]
    partial_summary = payload["r2_timeout_partial_evidence_summary"]
    r1_docket = payload["r1_docket"]
    vpv = payload["vpv_prime_candidates"]
    admitted_vpv = [row for row in vpv if not row["below_evidence_floor"]]
    below_floor = [row for row in vpv if row["below_evidence_floor"]]
    bands = Counter(row["band"] for row in r2_docket)
    class_names = (
        "same_operation_answer_equivalence",
        "misconception_is_other_operation_identity",
        "unforeseen",
        "unclassified",
    )
    measured_classes = Counter(row["class"] for row in r1_docket)
    classes = {name: measured_classes[name] for name in class_names}

    lines = [
        "# Admission docket: 2026-08-09",
        "",
        "This docket orders candidates for human ceremony review. No row is an "
        "admission. Question preservation is blank because release does not "
        "establish that two machines answer the same question from the same "
        "numerals. The ceremony judges units, roles, and warrant.",
        "",
        "VPV-prime rows are ceremony-adjudicated candidates, never automatic "
        "admissions. Meaning-use typing is analysis over admitted edges only.",
        "",
        "The collected row strings predate the kernel_dependency overlay and "
        "remain unchanged. The tracked overlay now exists. The bounded "
        "recompute in docs/research/internal/2026-08-11-r2-kernel-lens-"
        "recompute.json examines only the three counting rows and moves "
        "omit_highest_place_regrouping to recursive_place_value_inscription "
        "from L1-only to L3.",
        "",
        "## R2 closure accounting",
        "",
        "| Measure | Count |",
        "|---|---:|",
        f"| Expected unordered pairs | {accounting['expected_unordered_pairs']} |",
        f"| Expected directed rows | {accounting['expected_directed_rows']} |",
        f"| Expected singleton rows | {accounting['expected_singleton_rows']} |",
        f"| Expected total rows | {accounting['expected_total_rows']} |",
        f"| Rows on disk | {accounting['on_disk_rows']} |",
        f"| Missing directed rows | {accounting['missing_directed_rows']} |",
        f"| Timeout rows | {accounting['timeout_rows']} |",
        f"| Duplicate rows | {accounting['duplicate_rows']} |",
        f"| Unexpected rows | {accounting['unexpected_rows']} |",
        f"| Unexplained rows | {accounting['unexplained_rows']} |",
        "",
        f"Reconciliation: {accounting['on_disk_rows']} on-disk rows + "
        f"{accounting['missing_directed_rows']} missing directions = "
        f"{accounting['expected_total_rows']} expected rows. Unexplained: "
        f"{accounting['unexplained_rows']}.",
        "",
        f"Backfill pairs: {accounting['backfill_pair_count']}.",
        "",
    ]
    for item in accounting["backfill_pairs"]:
        lines.append(
            f"- {machine_name(item['source'])} | {machine_name(item['target'])}"
        )

    coverage_distribution = partial_summary["coverage_distribution"]
    lines.extend([
        "",
        "## R2 timeout partial evidence",
        "",
        f"Residual timeout pairs: {partial_summary['entry_count']}. "
        f"L2-flagged pair entries: "
        f"{partial_summary['l2_flagged_entry_count']}; L2-flagged timeout "
        f"rows: {partial_summary['l2_flagged_timeout_row_count']}. L2 entries "
        "come first. Question preservation remains blank.",
        "",
        "Grid coverage records the shared points walked over input.points "
        "when both values are recoverable. Coverage ratios are available for "
        f"{partial_summary['coverage_ratio_available_entries']} entries. "
        "Distribution: " + "; ".join(
            f"{name} {count}"
            for name, count in coverage_distribution.items()
            if count
        ) + ".",
        "",
        "Retained point outcomes are released-witness input/validity records. "
        "The JSON keeps every retained record; the Markdown samples at most "
        "three per direction. released_validity_counts carries the exact "
        "partial-walk aggregate even when witness retention is capped.",
        "",
        "| Rank | Priority | Pair | Grid coverage | Directional outcomes so "
        "far | Lens flags | Point-outcome samples | Question preservation |",
        "|---:|---|---|---|---|---|---|---|",
    ])
    for entry in partial_evidence:
        direction_outcomes = [
            {
                "source": direction["source"],
                "target": direction["target"],
                "outcome": direction["outcome"],
                "walk": direction["walk"],
                "outcomes_so_far": direction["outcomes_so_far"],
                "released_count": direction["released_count"],
            }
            for direction in entry["directions"]
        ]
        lens_flags = [
            {
                "source": direction["source"],
                "target": direction["target"],
                "lens_flags": direction["lens_flags"],
            }
            for direction in entry["directions"]
        ]
        point_samples = [
            {
                "source": direction["source"],
                "target": direction["target"],
                "sample": direction["sample_point_outcomes"],
                "truncated": direction["point_outcomes_truncated"],
            }
            for direction in entry["directions"]
        ]
        pair_name = (
            f"{machine_name(entry['pair']['first'])} and "
            f"{machine_name(entry['pair']['second'])}"
        )
        lines.append(
            f"| {entry['rank']} | {entry['priority']} | {pair_name} | "
            f"{markdown_cell(entry['grid_coverage'])} | "
            f"{markdown_cell(direction_outcomes)} | "
            f"{markdown_cell(lens_flags)} | "
            f"{markdown_cell(point_samples)} |  |"
        )

    lines.extend([
        "",
        "## Count cross-check",
        "",
        "The lens comparison treats the transient 398/246/1,207 figures as "
        "the exclusive L1/L2/L3 priority split. The recomputation also records "
        "40 flagless candidates, while the transient split leaves 24 unnamed.",
        "",
        "| Measure | 2026-08-08 transient | Recomputed | Delta | Status |",
        "|---|---:|---:|---:|---|",
    ])
    for row in cross_check:
        lines.append(
            f"| {row['measure']} | {row['transient_2026_08_08']} | "
            f"{row['recomputed']} | {row['delta']:+d} | {row['status']} |"
        )
    lines.extend([
        "",
        "Non-exclusive R2 lens combinations recomputed from lens_flags: "
        "L1-only 397; L2-and-L3 165; L2-only 80; L3-only 177; "
        "L1-and-L3 1,016; flagless 40.",
        "",
        "## R2 crisis-release docket",
        "",
        f"Ruled bands: L2 {bands['L2']}; L3-not-L2 {bands['L3-not-L2']}; "
        f"L1-only {bands['L1-only']}; flagless {bands['flagless']}. "
        "L2 is ranked by strong released points, then presence of an "
        "out-of-region incorrect witness, then released count. Other bands "
        "are ranked by released count.",
        "",
    ])
    for band in ("L2", "L3-not-L2", "L1-only", "flagless"):
        lines.extend([
            f"### {band}",
            "",
            "| Rank | Source to target | Outcomes | Released | Validities | "
            "Lens flags | Contracts and license citation | Sample witnesses | "
            "Question preservation |",
            "|---:|---|---|---:|---|---|---|---|---|",
        ])
        for row in (value for value in r2_docket if value["band"] == band):
            outcomes = {
                "source": row["source_outcome"],
                "target": row["target_outcome"],
            }
            contracts = {
                "source_contract": row["source_contract"],
                "target_contract": row["target_contract"],
                "license_citation": row["license_citation"],
            }
            lines.append(
                f"| {row['rank']} | {machine_name(row['source'])} to "
                f"{machine_name(row['target'])} | {markdown_cell(outcomes)} | "
                f"{row['released_count']} | "
                f"{markdown_cell(row['released_validity_counts'])} | "
                f"{markdown_cell(row['lens_flags'])} | "
                f"{markdown_cell(contracts)} | "
                f"{markdown_cell(row['sample_witnesses'])} |  |"
            )

    lines.extend([
        "",
        "## R1 equalizer docket",
        "",
        "The mechanical classification gives same-operation precedence. A "
        "cross-operation full-agreement pair enters the other-operation "
        "identity class when either machine is the deformation member of a "
        "live action_automaton_pair/4 row whose operation is the other "
        "machine's family. Remaining cross-operation pairs are unforeseen. "
        "Missing machine evidence would be unclassified.",
        "",
        "Class counts: " + "; ".join(
            f"{name} {count}" for name, count in classes.items()
        ) + ".",
        "",
        "| Source to target | Class | Basis | Joint computed | Refused | "
        "Registry matches |",
        "|---|---|---|---:|---:|---|",
    ])
    for row in r1_docket:
        lines.append(
            f"| {machine_name(row['source'])} to {machine_name(row['target'])} | "
            f"{row['class']} | {row['classification_basis']} | "
            f"{row['joint_computed_points']} | {row['joint_refusal_points']} | "
            f"{markdown_cell(row['action_automaton_pair_matches'])} |"
        )

    lines.extend([
        "",
        "## VPV-prime candidates",
        "",
        "Criterion (i) is supportable offline because the reverse R2 "
        "released_count measures inputs where the proposed receiver refuses "
        "and the source computes. Criterion (ii) uses R1 full_agreement over "
        "the joint computed region. Criterion (iii) uses R1 ran as that "
        "region's point count. Criterion (iv) uses the forward certified "
        "crisis_release row.",
        "",
        f"Ceremony docket candidates at or above the evidence floor: "
        f"{len(admitted_vpv)}. Recorded below the evidence floor in JSON and "
        f"excluded here: {len(below_floor)}. Unsupported directed joins: "
        f"{len(payload['vpv_prime_unsupported'])}.",
        "",
        "| Source to target | Joint computed | Released | Reverse released | "
        "Status |",
        "|---|---:|---:|---:|---|",
    ])
    for row in admitted_vpv:
        lines.append(
            f"| {machine_name(row['source'])} to {machine_name(row['target'])} | "
            f"{row['joint_computed_points']} | {row['released_count']} | "
            f"{row['reverse_released_count']} | candidate, not admitted |"
        )

    lines.extend([
        "",
        "## Limits carried into the ceremony",
        "",
        "- Question preservation is not inferred from shared numerals or a "
        "nonempty release.",
        "- The collected R2 witness lists are capped at 200. The JSON retains "
        "every collected witness; the Markdown shows at most three.",
        "- A timeout partial-evidence coverage ratio is omitted when the row "
        "does not retain a positive planned grid size. The entry names that "
        "limit and does not invent a denominator.",
        "- L3 records action-alphabet evidence only until the R3 overlay exists.",
        "- The finite grids support candidate review. They do not prove behavior "
        "outside the authored grids.",
        "",
    ])
    return "\n".join(lines)


def print_accounting(accounting: dict[str, Any]) -> None:
    print("== R2 closure accounting ==", flush=True)
    labels = (
        ("expected unordered pairs", "expected_unordered_pairs"),
        ("expected directed rows", "expected_directed_rows"),
        ("expected singleton rows", "expected_singleton_rows"),
        ("expected total rows", "expected_total_rows"),
        ("on-disk rows", "on_disk_rows"),
        ("missing directed rows", "missing_directed_rows"),
        ("timeout rows", "timeout_rows"),
        ("duplicate rows", "duplicate_rows"),
        ("unexpected rows", "unexpected_rows"),
        ("unexplained rows", "unexplained_rows"),
    )
    for label, key in labels:
        print(f"{label:28s}: {accounting[key]}", flush=True)
    print(
        f"reconciliation              : {accounting['on_disk_rows']} + "
        f"{accounting['missing_directed_rows']} = "
        f"{accounting['expected_total_rows']}; zero unexplained",
        flush=True,
    )
    print(
        f"backfill pairs              : {accounting['backfill_pair_count']}",
        flush=True,
    )
    for number, item in enumerate(accounting["backfill_pairs"], start=1):
        print(
            f"  {number:03d} {machine_name(item['source'])} | "
            f"{machine_name(item['target'])}",
            flush=True,
        )


def print_cross_check(rows: list[dict[str, Any]]) -> None:
    print("\n== count cross-check ==", flush=True)
    print("measure | transient | recomputed | delta | status", flush=True)
    for row in rows:
        print(
            f"{row['measure']} | {row['transient_2026_08_08']} | "
            f"{row['recomputed']} | {row['delta']:+d} | {row['status']}",
            flush=True,
        )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--r1-rows", type=Path, default=DEFAULT_R1_ROWS)
    parser.add_argument("--r2-rows", type=Path, default=DEFAULT_R2_ROWS)
    parser.add_argument(
        "--r2-backfill-rows", type=Path, default=DEFAULT_R2_BACKFILL_ROWS,
        help="R2 backfill rows that carry residual timeout partial walks",
    )
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    parser.add_argument(
        "--backfill-output-dir", type=Path, default=DEFAULT_BACKFILL_DIR
    )
    parser.add_argument("--pairs-per-task", type=int, default=12)
    parser.add_argument("--pair-budget-s", type=float, default=1200.0)
    parser.add_argument("--input-timeout-s", type=float, default=30.0)
    parser.add_argument("--max-witnesses", type=int, default=200)
    arguments = parser.parse_args()

    r1_rows = read_rows(arguments.r1_rows)
    r2_rows = read_rows(arguments.r2_rows)
    r2_backfill_rows = read_rows(arguments.r2_backfill_rows)
    try:
        accounting = close_r2_accounting(r1_rows, r2_rows)
    except AccountingError as error:
        print(f"BLOCKED: {error}", file=sys.stderr, flush=True)
        return 2
    print_accounting(accounting)

    shards = write_backfill_manifests(
        accounting,
        arguments.r1_rows,
        arguments.backfill_output_dir,
        arguments.pairs_per_task,
        arguments.pair_budget_s,
        arguments.input_timeout_s,
        arguments.max_witnesses,
    )
    last_shard = len(shards) - 1
    print(f"\nbackfill manifest directory : {arguments.backfill_output_dir}", flush=True)
    print(f"backfill shards             : {len(shards)}", flush=True)
    print(f"sbatch array range          : 0-{last_shard}", flush=True)
    print(f"pair budget                 : {arguments.pair_budget_s:g} s", flush=True)

    r2_docket = build_r2_docket(r2_rows)
    partial_evidence = build_r2_partial_evidence(r2_backfill_rows)
    partial_summary = partial_evidence_summary(partial_evidence)
    r1_docket = build_r1_docket(r1_rows)
    vpv_prime, unsupported = build_vpv_prime(r1_rows, r2_rows)
    cross_check = count_cross_check(r1_docket, r2_docket, r2_rows)
    print_cross_check(cross_check)

    class_names = (
        "same_operation_answer_equivalence",
        "misconception_is_other_operation_identity",
        "unforeseen",
        "unclassified",
    )
    measured_classes = Counter(row["class"] for row in r1_docket)
    payload = {
        "generated_for": "2026-08-09 admission ceremony",
        "source_directories": {
            "r1": str(arguments.r1_rows),
            "r2": str(arguments.r2_rows),
            "r2_backfill": str(arguments.r2_backfill_rows),
        },
        "ceremony_rules": {
            "automatic_admission": False,
            "question_preservation_default": "",
            "typing_scope": "analysis over admitted edges only",
            "l3_kernel_half": (
                "collected row strings predate the tracked overlay and remain "
                "unchanged; docs/research/internal/2026-08-11-r2-kernel-lens-"
                "recompute.json assigns only l3 and l3_kernel_half for the "
                "three counting rows and flips omit_highest_place_regrouping "
                "to recursive_place_value_inscription"
            ),
        },
        "accounting": {
            key: value for key, value in accounting.items()
            if not key.startswith("_")
        },
        "count_cross_check": cross_check,
        "r2_docket": r2_docket,
        "r2_timeout_partial_evidence_summary": partial_summary,
        "r2_timeout_partial_evidence": partial_evidence,
        "r1_class_counts": {
            name: measured_classes[name] for name in class_names
        },
        "r1_docket": r1_docket,
        "vpv_prime_candidates": vpv_prime,
        "vpv_prime_docket_count": sum(
            not row["below_evidence_floor"] for row in vpv_prime
        ),
        "vpv_prime_below_evidence_floor_count": sum(
            row["below_evidence_floor"] for row in vpv_prime
        ),
        "vpv_prime_unsupported": unsupported,
    }

    arguments.output_dir.mkdir(parents=True, exist_ok=True)
    json_path = arguments.output_dir / f"{DOCKET_STEM}.json"
    markdown_path = arguments.output_dir / f"{DOCKET_STEM}.md"
    json_path.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    markdown_path.write_text(render_markdown(payload), encoding="utf-8")

    print(f"\nR2 docket rows             : {len(r2_docket)}", flush=True)
    print(
        "R2 timeout partial pairs   : "
        f"{partial_summary['entry_count']}",
        flush=True,
    )
    print(
        "R2 timeout L2 rows/pairs   : "
        f"{partial_summary['l2_flagged_timeout_row_count']}/"
        f"{partial_summary['l2_flagged_entry_count']}",
        flush=True,
    )
    print(
        "R2 timeout coverage        : "
        f"{compact_json(partial_summary['coverage_distribution'])}",
        flush=True,
    )
    print(f"R1 equalizer rows          : {len(r1_docket)}", flush=True)
    print("\n== R1 class table ==", flush=True)
    print("class | count", flush=True)
    for name in class_names:
        print(f"{name} | {measured_classes[name]}", flush=True)
    print(
        f"VPV-prime ceremony rows    : {payload['vpv_prime_docket_count']}",
        flush=True,
    )
    print(
        "VPV-prime below floor     : "
        f"{payload['vpv_prime_below_evidence_floor_count']}",
        flush=True,
    )
    print(f"VPV-prime unsupported      : {len(unsupported)}", flush=True)
    print(f"Markdown docket            : {markdown_path}", flush=True)
    print(f"JSON docket                : {json_path}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
