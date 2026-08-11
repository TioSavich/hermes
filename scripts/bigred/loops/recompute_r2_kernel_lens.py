#!/usr/bin/env python3
"""Recompute the bounded R2 L3 kernel half from the tracked overlay store."""

from __future__ import annotations

import argparse
import copy
import json
import sys
from pathlib import Path
from typing import Any

import build_kernel_dependency_overlay as overlay


ROOT = Path(__file__).resolve().parents[3]
DEFAULT_R2_ROW_DIRS = (
    ROOT / ".bigred-collected/2026-08-08-loops-wave2-r2/rows",
    ROOT / ".bigred-collected/2026-08-10-loops-wave2-r2-backfill/rows",
)
DEFAULT_OUTPUT = (
    ROOT / "docs/research/internal/2026-08-11-r2-kernel-lens-recompute.json"
)
EXPECTED_FLIP = (
    "counting/omit_highest_place_regrouping",
    "counting/recursive_place_value_inscription",
)


class RecomputeError(RuntimeError):
    """The bounded R2 recompute disagreed with its pre-registration."""


def read_rows(directories: list[Path]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for directory in directories:
        for path in sorted(directory.rglob("*.jsonl")):
            with path.open(encoding="utf-8") as handle:
                for number, line in enumerate(handle, start=1):
                    if not line.strip():
                        continue
                    row = json.loads(line)
                    row["_collection_directory"] = str(directory.relative_to(ROOT))
                    row["_collection_file"] = path.name
                    row["_collection_line"] = number
                    rows.append(row)
    return rows


def machine_name(machine: dict[str, Any]) -> str:
    return f"{machine.get('family')}/{machine.get('kind')}"


def is_r2_candidate_touching_counting(row: dict[str, Any]) -> bool:
    return (
        row.get("outcome") == "certified_candidate"
        and row.get("candidate_type") == "crisis_release"
        and "counting"
        in {
            (row.get("source") or {}).get("family"),
            (row.get("target") or {}).get("family"),
        }
    )


def dependency_index(
    dependencies: list[dict[str, Any]],
) -> dict[tuple[str, str], dict[str, Any]]:
    return {
        (row["machine"]["family"], row["machine"]["kind"]): row
        for row in dependencies
    }


def recompute(
    r2_rows: list[dict[str, Any]], dependencies: list[dict[str, Any]]
) -> dict[str, Any]:
    """Assign only the kernel-half status and L3 result from the overlay."""
    index = dependency_index(dependencies)
    touching = [row for row in r2_rows if is_r2_candidate_touching_counting(row)]
    results = []
    flips = []
    for row in touching:
        source = row["source"]
        target = row["target"]
        evidence = row.get("evidence") or {}
        before = copy.deepcopy(evidence.get("lens_flags") or {})
        after = copy.deepcopy(before)
        dependency = index.get((target["family"], target["kind"]))
        kernel_half = dependency is not None
        after["l3_kernel_half"] = (
            "satisfied by tracked kernel_dependency overlay"
            if kernel_half
            else "examined against tracked kernel_dependency overlay; not satisfied"
        )
        if kernel_half:
            after["l3"] = True

        changed_fields = [
            key
            for key in sorted(set(before) | set(after))
            if before.get(key) != after.get(key)
        ]
        changed_boolean_flags = [
            key
            for key in changed_fields
            if isinstance(before.get(key), bool) or isinstance(after.get(key), bool)
        ]
        old_band = "L1-only" if before.get("l1") and not before.get("l3") else row.get(
            "candidate_lens", "unlensed"
        )
        new_band = "L3" if after.get("l3") else old_band
        pair = (machine_name(source), machine_name(target))
        if before.get("l3") is not True and after.get("l3") is True:
            flips.append(pair)
        results.append(
            {
                "source": source,
                "target": target,
                "source_row": {
                    "key": row.get("key"),
                    "directory": row.get("_collection_directory"),
                    "file": row.get("_collection_file"),
                    "line": row.get("_collection_line"),
                },
                "kernel_half_satisfied": kernel_half,
                "matching_dependency": (
                    dependency["machine"] if dependency else None
                ),
                "band_before": old_band,
                "band_after": new_band,
                "flags_before": before,
                "flags_after": after,
                "changed_fields": changed_fields,
                "changed_boolean_flags": changed_boolean_flags,
            }
        )

    return {
        "schema": "hermes_r2_kernel_lens_recompute_v1",
        "overlay_store": "scripts/bigred/loops/kernel_dependency_overlay.pl",
        "counting_rows_examined": len(touching),
        "l3_flips": [
            {"source": source, "target": target} for source, target in flips
        ],
        "l3_flip_count": len(flips),
        "assignment_scope": ["l3", "l3_kernel_half"],
        "assignment_rule": (
            "the recompute assigns only the L3 Boolean and kernel-half status; "
            "all other collected fields are copied unchanged"
        ),
        "rows": results,
    }


def verify_pre_registration(result: dict[str, Any]) -> None:
    flips = [
        (row["source"], row["target"]) for row in result["l3_flips"]
    ]
    if result["counting_rows_examined"] != 3:
        raise RecomputeError(
            "bounded R2 population differs from pre-registration: "
            f"counting_rows={result['counting_rows_examined']} expected=3"
        )
    if flips != [EXPECTED_FLIP]:
        raise RecomputeError(
            f"L3 flips differ from pre-registration: {flips!r}"
        )
    indexed = {
        (machine_name(row["source"]), machine_name(row["target"])): row
        for row in result["rows"]
    }
    flip_row = indexed.get(EXPECTED_FLIP)
    if flip_row is None:
        raise RecomputeError("pre-registered flip row is absent from recompute")
    flip_flags = flip_row["flags_after"]
    if not (
        flip_row["kernel_half_satisfied"] is True
        and flip_flags.get("l1") is True
        and flip_flags.get("l2") is False
        and flip_flags.get("l3") is True
    ):
        raise RecomputeError(
            "pre-registered flip state differs: expected kernel half true, "
            "l1 true, l2 false, and l3 true"
        )
    negatives = [row for pair, row in indexed.items() if pair != EXPECTED_FLIP]
    if len(negatives) != 2 or any(
        row["kernel_half_satisfied"] is not False
        or row["flags_after"].get("l3") is not False
        for row in negatives
    ):
        raise RecomputeError(
            "negative counting-row state differs: expected two rows with "
            "kernel half false and l3 false"
        )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    parser.add_argument(
        "--r2-rows",
        type=Path,
        action="append",
        default=None,
        help=(
            "R2 row directory; repeat to supply the primary and backfill "
            "collections (defaults to both dated collections)"
        ),
    )
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    dependencies = overlay.read_store()
    row_directories = args.r2_rows or list(DEFAULT_R2_ROW_DIRS)
    missing = [directory for directory in row_directories if not directory.is_dir()]
    if missing:
        print(
            "PASS R2 kernel-lens recompute: SKIP R2 collection(s) absent="
            f"{','.join(str(path) for path in missing)}; "
            f"tracked overlay rows={len(dependencies)} checked"
        )
        return 0

    result = recompute(read_rows(row_directories), dependencies)
    result["source_directories"] = [
        str(directory.relative_to(ROOT)) for directory in row_directories
    ]
    verify_pre_registration(result)
    if not args.check:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(
            json.dumps(result, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
    flip = result["l3_flips"][0]
    print(
        "PASS R2 kernel-lens recompute: "
        f"counting_rows={result['counting_rows_examined']} "
        f"l3_flips={result['l3_flip_count']} "
        f"flip={flip['source']}->{flip['target']} "
        "assigned_fields=l3,l3_kernel_half "
        "pinned_states=two_negative_l3_false+flip_l1_true_l2_false_l3_true"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (RecomputeError, OSError, ValueError, json.JSONDecodeError) as error:
        print(f"BLOCKED R2 kernel-lens recompute: {error}", file=sys.stderr)
        raise SystemExit(2)
