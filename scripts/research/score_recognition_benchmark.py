#!/usr/bin/env python3
"""Score the strategy recognizer against the fixed recognition benchmark."""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any, Iterable

ROOT = Path(__file__).resolve().parents[2]
PATHS_PL = ROOT / "paths.pl"
DRIVER = ROOT / "scripts/research/_recognition_benchmark_driver.pl"
DEFAULT_BENCHMARK = ROOT / "data/research/recognition_benchmark.json"
MACHINE_ARMS = ("literature", "student")


def ratio(hits: int, total: int) -> dict[str, float | int]:
    return {"hits": hits, "rate": hits / total if total else 0.0}


def mean_candidates(counts: list[int]) -> float:
    firing = [count for count in counts if count]
    return sum(firing) / len(firing) if firing else 0.0


def select_items(
    benchmark: dict[str, Any], item_ids: set[str] | None
) -> list[dict[str, Any]]:
    items = [
        item
        for arm in benchmark["arms"].values()
        for item in arm["items"]
        if item_ids is None or item["id"] in item_ids
    ]
    if item_ids is not None:
        found = {item["id"] for item in items}
        missing = sorted(item_ids - found)
        if missing:
            raise ValueError(f"unknown benchmark item id(s): {', '.join(missing)}")
    if not items:
        raise ValueError("the selected benchmark subset is empty")
    return items


def run_recognizer(items: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    request_items = [{"id": item["id"], "text": item["text"]} for item in items]
    completed = subprocess.run(
        [
            "swipl",
            "-q",
            "--on-warning=status",
            "--on-error=status",
            "-l",
            str(PATHS_PL),
            "-s",
            str(DRIVER),
            "-g",
            "main",
            "-t",
            "halt",
        ],
        cwd=ROOT,
        input=json.dumps({"mode": "score", "items": request_items}),
        capture_output=True,
        text=True,
        timeout=1800,
    )
    if completed.returncode != 0:
        raise RuntimeError(
            "recognizer process failed:\n"
            f"{completed.stdout}\n{completed.stderr}".rstrip()
        )
    payload = json.loads(completed.stdout)
    return {row["id"]: row for row in payload["results"]}


def score_machine_arm(
    items: list[dict[str, Any]], results: dict[str, dict[str, Any]]
) -> dict[str, Any]:
    hits = {1: 0, 3: 0, 5: 0}
    family_hits = 0
    counts: list[int] = []
    abstentions = 0

    for item in items:
        result = results[item["id"]]
        candidates = result["candidates"]
        counts.append(result["candidate_count"])
        if not candidates:
            abstentions += 1
            continue
        gold = item["gold"]
        for k in hits:
            if any(
                candidate["family"] == gold["family"]
                and candidate["signature"] == gold["signature"]
                for candidate in candidates[:k]
            ):
                hits[k] += 1
        if candidates[0]["family"] == gold["family"]:
            family_hits += 1

    total = len(items)
    return {
        "scoring_grain": "machine",
        "total_items": total,
        "abstentions": abstentions,
        "abstention_rate": abstentions / total if total else 0.0,
        "recall_at_1": ratio(hits[1], total),
        "recall_at_3": ratio(hits[3], total),
        "recall_at_5": ratio(hits[5], total),
        "family_recall_at_1": ratio(family_hits, total),
        "mean_candidates_per_firing_item": mean_candidates(counts),
    }


def score_authored_arm(
    items: list[dict[str, Any]], results: dict[str, dict[str, Any]]
) -> dict[str, Any]:
    action_hits = 0
    abstentions = 0
    counts: list[int] = []

    for item in items:
        result = results[item["id"]]
        candidates = result["candidates"]
        counts.append(result["candidate_count"])
        if not candidates:
            abstentions += 1
            continue
        if item["gold"]["action"] in candidates[0]["recovered_canonical_actions"]:
            action_hits += 1

    total = len(items)
    return {
        "scoring_grain": "action",
        "comparable_to_machine_arms": False,
        "total_items": total,
        "abstentions": abstentions,
        "abstention_rate": abstentions / total if total else 0.0,
        "top_candidate_action_recall": ratio(action_hits, total),
        "mean_candidates_per_firing_item": mean_candidates(counts),
        "action_evidence": [
            "recovered_action_order",
            "matched_spans.action",
        ],
    }


def score(
    benchmark: dict[str, Any], items: list[dict[str, Any]]
) -> dict[str, Any]:
    results = run_recognizer(items)
    by_arm = {
        arm: [item for item in items if item["arm"] == arm]
        for arm in (*MACHINE_ARMS, "authored")
    }
    scores: dict[str, Any] = {}
    for arm in MACHINE_ARMS:
        if by_arm[arm]:
            scores[arm] = score_machine_arm(by_arm[arm], results)
    if by_arm["authored"]:
        scores["authored"] = score_authored_arm(by_arm["authored"], results)
    return {
        "benchmark_schema_version": benchmark["schema_version"],
        "selected_item_count": len(items),
        "arms": scores,
    }


def percent(value: float) -> str:
    return f"{100.0 * value:.1f}%"


def render_human(scores: dict[str, Any]) -> str:
    machine_scores = [arm for arm in MACHINE_ARMS if arm in scores["arms"]]
    lines: list[str] = []
    if machine_scores:
        lines.extend(
            [
                "Machine-level recognition",
                "",
                (
                    "arm         n    recall@1  recall@3  recall@5  "
                    "family@1  abstention  candidates/firing"
                ),
            ]
        )
    for arm in MACHINE_ARMS:
        if arm not in scores["arms"]:
            continue
        row = scores["arms"][arm]
        lines.append(
            f"{arm:<10} {row['total_items']:>4}  "
            f"{percent(row['recall_at_1']['rate']):>8}  "
            f"{percent(row['recall_at_3']['rate']):>8}  "
            f"{percent(row['recall_at_5']['rate']):>8}  "
            f"{percent(row['family_recall_at_1']['rate']):>8}  "
            f"{percent(row['abstention_rate']):>10}  "
            f"{row['mean_candidates_per_firing_item']:>17.2f}"
        )

    if "authored" in scores["arms"]:
        row = scores["arms"]["authored"]
        if lines:
            lines.append("")
        lines.extend(
            [
                "Authored contaminated control (action-level)",
                "",
                (
                    f"n={row['total_items']}; top-candidate action recovery="
                    f"{percent(row['top_candidate_action_recall']['rate'])}; "
                    f"abstention={percent(row['abstention_rate'])}; "
                    "candidates/firing="
                    f"{row['mean_candidates_per_firing_item']:.2f}"
                ),
                (
                    "This arm measures a different thing at a different grain "
                    "and is not comparable to the machine-level arms."
                ),
            ]
        )
    return "\n".join(lines)


def main(argv: Iterable[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--benchmark", type=Path, default=DEFAULT_BENCHMARK)
    parser.add_argument("--item-id", action="append", default=[])
    parser.add_argument("--format", choices=("human", "json"), default="human")
    args = parser.parse_args(argv)

    try:
        benchmark = json.loads(args.benchmark.read_text(encoding="utf-8"))
        selected = select_items(benchmark, set(args.item_id) or None)
        scores = score(benchmark, selected)
    except (
        OSError,
        ValueError,
        KeyError,
        RuntimeError,
        subprocess.TimeoutExpired,
        json.JSONDecodeError,
    ) as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1

    if args.format == "json":
        print(json.dumps(scores, indent=2, sort_keys=True))
    else:
        print(render_human(scores))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
