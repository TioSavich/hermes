#!/usr/bin/env python3
"""Freeze MTB-mini and subset its two existing full-run floor artifacts."""
from __future__ import annotations

import argparse
import hashlib
import json
import random
import statistics
from pathlib import Path
from typing import Any

from build_wave5_f0 import FLOORS, REPO, compact_json, load_jsonl, sha256, write_json


BENCH = REPO / "hermes/app/runtime/experiments/gemma4_tutor"
DATASET = BENCH / "vendor/datasets/mathdial_bridge.json"
UNTUNED_DIR = BENCH / "runs/7772992"
SUITE_DIR = BENCH / "suite/e2b-full-v1"
MANIFEST_NAME = "wave5-mtb-mini-manifest.json"
FLOORS_NAME = "wave5-mtb-mini-floors.json"
BUILDER_VERSION = "wave5-mtb-mini-stratified-v1"
SEED = 20260812
FULL_SIZE = 360
MINI_SIZE = 60


def relative(path: Path) -> str:
    return str(path.relative_to(REPO))


def item_family(_: dict[str, Any]) -> str:
    # The frozen 360-item slice is one published benchmark task/config family.
    return "scaffolding_generation"


def item_id(index: int) -> str:
    return f"scaffolding_generation:{index:04d}"


def content_sha(item: dict[str, Any]) -> str:
    return hashlib.sha256(compact_json(item).encode("utf-8")).hexdigest()


def select_indexes(items: list[dict[str, Any]]) -> tuple[list[int], dict[str, int], dict[str, int]]:
    strata: dict[str, list[int]] = {}
    for index, item in enumerate(items):
        strata.setdefault(item_family(item), []).append(index)
    if len(items) != FULL_SIZE:
        raise ValueError(f"expected {FULL_SIZE} source items, found {len(items)}")
    allocations: dict[str, int] = {}
    remaining = MINI_SIZE
    families = sorted(strata)
    for position, family in enumerate(families):
        if position == len(families) - 1:
            allocation = remaining
        else:
            allocation = round(MINI_SIZE * len(strata[family]) / FULL_SIZE)
            remaining -= allocation
        allocations[family] = allocation
    rng = random.Random(SEED)
    selected = sorted(
        index
        for family in families
        for index in rng.sample(strata[family], allocations[family])
    )
    return selected, {family: len(indexes) for family, indexes in strata.items()}, allocations


def validate_result(index: int, result: dict[str, Any], reward: dict[str, Any],
                    dataset: list[dict[str, Any]], label: str) -> None:
    if int(result["source_index"]) != index:
        raise ValueError(f"{label} result index mismatch at {index}")
    problem = dataset[index]["problem"]
    if result.get("problem") != problem or reward.get("problem") != problem:
        raise ValueError(f"{label} problem mismatch at {index}")
    for field in ("generated_score", "ground_truth_score"):
        if not isinstance(reward.get(field), (int, float)):
            raise ValueError(f"{label} reward lacks numeric {field} at {index}")


def load_untuned(dataset: list[dict[str, Any]]) -> tuple[dict[int, dict[str, Any]], list[Path]]:
    results_path = UNTUNED_DIR / "results.jsonl"
    reward_path = UNTUNED_DIR / "reward-baseline.json"
    results = load_jsonl(results_path)
    rewards = json.loads(reward_path.read_text(encoding="utf-8"))
    if len(results) != FULL_SIZE or len(rewards) != FULL_SIZE:
        raise ValueError("untuned full-run artifacts do not each contain 360 records")
    by_index: dict[int, dict[str, Any]] = {}
    for result, reward in zip(results, rewards):
        index = int(result["source_index"])
        if index in by_index:
            raise ValueError(f"untuned duplicate source index {index}")
        validate_result(index, result, reward, dataset, "untuned")
        by_index[index] = reward
    if sorted(by_index) != list(range(FULL_SIZE)):
        raise ValueError("untuned source indexes are not exactly 0..359")
    return by_index, [results_path, reward_path]


def load_iterative(dataset: list[dict[str, Any]]) -> tuple[dict[int, dict[str, Any]], list[Path]]:
    chunks = sorted(marker.parent for marker in SUITE_DIR.glob("chunk-*/COMPLETE"))
    if not chunks:
        raise ValueError("iterative suite has no complete chunks")
    by_index: dict[int, dict[str, Any]] = {}
    sources: list[Path] = []
    for chunk in chunks:
        results_path = chunk / "results.jsonl"
        reward_path = chunk / "reward-iterative.json"
        results = load_jsonl(results_path)
        rewards = json.loads(reward_path.read_text(encoding="utf-8"))
        if len(results) != len(rewards):
            raise ValueError(f"iterative result/reward length mismatch in {chunk.name}")
        sources.extend([results_path, reward_path])
        for result, reward in zip(results, rewards):
            index = int(result["source_index"])
            if index in by_index:
                raise ValueError(f"iterative duplicate source index {index}")
            validate_result(index, result, reward, dataset, "iterative")
            by_index[index] = reward
    if sorted(by_index) != list(range(FULL_SIZE)):
        raise ValueError("iterative complete chunks do not cover exactly 0..359")
    return by_index, sources


def arm_metrics(rows: dict[int, dict[str, Any]], indexes: list[int]) -> dict[str, Any]:
    item_rows = []
    for index in indexes:
        row = rows[index]
        margin = float(row["generated_score"]) - float(row["ground_truth_score"])
        item_rows.append(
            {
                "item_id": item_id(index),
                "source_index": index,
                "generated_score": row["generated_score"],
                "ground_truth_score": row["ground_truth_score"],
                "margin": round(margin, 6),
                "win": margin > 0,
            }
        )
    margins = [row["margin"] for row in item_rows]
    wins = sum(bool(row["win"]) for row in item_rows)
    return {
        "n": len(item_rows),
        "wins": wins,
        "win_rate_over_ground_truth": round(wins / len(item_rows), 6),
        "mean_margin": round(statistics.fmean(margins), 6),
        "items": item_rows,
    }


def source_records(paths: list[Path]) -> list[dict[str, str]]:
    return [{"path": relative(path), "sha256": sha256(path)} for path in paths]


def build(output_dir: Path) -> tuple[dict[str, Any], dict[str, Any]]:
    dataset = json.loads(DATASET.read_text(encoding="utf-8"))[:FULL_SIZE]
    selected, distribution, mini_distribution = select_indexes(dataset)
    ids = [item_id(index) for index in selected]
    ids_sha = hashlib.sha256(("\n".join(ids) + "\n").encode("utf-8")).hexdigest()
    manifest = {
        "builder": BUILDER_VERSION,
        "name": "MTB-mini",
        "purpose": "scoring_only",
        "training_use": "forbidden",
        "source": relative(DATASET),
        "source_sha256": sha256(DATASET),
        "source_slice": {"start": 0, "stop_exclusive": FULL_SIZE},
        "seed": SEED,
        "sample_size": MINI_SIZE,
        "stratification_field": "benchmark_task_family",
        "family_distribution_360": dict(sorted(distribution.items())),
        "family_distribution_mini": dict(sorted(mini_distribution.items())),
        "item_ids_sha256": ids_sha,
        "items": [
            {
                "item_id": item_id(index),
                "source_index": index,
                "task_family": item_family(dataset[index]),
                "content_sha256": content_sha(dataset[index]),
            }
            for index in selected
        ],
    }

    untuned, untuned_sources = load_untuned(dataset)
    iterative, iterative_sources = load_iterative(dataset)
    untuned_full = arm_metrics(untuned, list(range(FULL_SIZE)))
    iterative_full = arm_metrics(iterative, list(range(FULL_SIZE)))
    if (untuned_full["wins"], iterative_full["wins"]) != (165, 282):
        raise ValueError(
            "full-run floor reproduction disagrees with 165/360 untuned or 282/360 iterative"
        )
    untuned_mini = arm_metrics(untuned, selected)
    iterative_mini = arm_metrics(iterative, selected)
    floors = {
        "builder": BUILDER_VERSION,
        "manifest": MANIFEST_NAME,
        "manifest_item_ids_sha256": ids_sha,
        "derivation_status": "subset_clean",
        "fallback_controller_run": [],
        "subset_checks": {
            "selected_ids_present_in_untuned": all(index in untuned for index in selected),
            "selected_ids_present_in_iterative": all(index in iterative for index in selected),
            "untuned_full_reproduced": {
                "wins": untuned_full["wins"],
                "n": untuned_full["n"],
                "win_rate_over_ground_truth": untuned_full["win_rate_over_ground_truth"],
            },
            "iterative_full_reproduced": {
                "wins": iterative_full["wins"],
                "n": iterative_full["n"],
                "win_rate_over_ground_truth": iterative_full["win_rate_over_ground_truth"],
            },
        },
        "floors": {
            "untuned_naked": {
                **untuned_mini,
                "full_run_sources": source_records(untuned_sources),
            },
            "iterative_harness": {
                **iterative_mini,
                "full_run_sources": source_records(iterative_sources),
            },
        },
        "scoring_rule": "generated_score greater than ground_truth_score is a win",
        "text_boundary": "No MathTutorBench text is stored in either output; ids, hashes, strata, and scores only.",
    }
    output_dir.mkdir(parents=True, exist_ok=True)
    write_json(output_dir / MANIFEST_NAME, manifest)
    write_json(output_dir / FLOORS_NAME, floors)
    return manifest, floors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path, default=FLOORS)
    args = parser.parse_args()
    manifest, floors = build(args.output_dir)
    print(
        compact_json(
            {
                "item_ids_sha256": manifest["item_ids_sha256"],
                "distribution_360": manifest["family_distribution_360"],
                "distribution_mini": manifest["family_distribution_mini"],
                "derivation_status": floors["derivation_status"],
                "untuned_mini": floors["floors"]["untuned_naked"]["win_rate_over_ground_truth"],
                "iterative_mini": floors["floors"]["iterative_harness"]["win_rate_over_ground_truth"],
            }
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
