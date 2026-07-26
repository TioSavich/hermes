#!/usr/bin/env python3
"""Build the recognition benchmark from the repository's labelled phrase data."""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
PATHS_PL = ROOT / "paths.pl"
DRIVER = ROOT / "scripts/research/_recognition_benchmark_driver.pl"
DEFAULT_OUTPUT = ROOT / "data/research/recognition_benchmark.json"
AUTHORED_SOURCE = "knowledge/strategies/canonical_phrases.pl"
ATTESTED_SOURCE = "knowledge/strategies/attested_phrases.pl"
ARM_ORDER = ("literature", "student", "authored")


def normalized_text(text: str) -> str:
    return " ".join(re.findall(r"[a-z0-9]+(?:'[a-z0-9]+)?", text.lower()))


def arm_statistics(items: list[dict[str, Any]]) -> dict[str, int]:
    texts = {normalized_text(item["text"]) for item in items}
    machines_by_text: dict[str, set[tuple[str, str]]] = defaultdict(set)
    for item in items:
        gold = item["gold"]
        if set(gold) == {"family", "signature"}:
            machines_by_text[normalized_text(item["text"])].add(
                (gold["family"], gold["signature"])
            )
    return {
        "distinct_normalized_text_count": len(texts),
        "distinct_texts_with_multiple_machine_labels": sum(
            len(labels) > 1 for labels in machines_by_text.values()
        ),
    }


def load_source_rows() -> dict[str, list[dict[str, Any]]]:
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
        input=json.dumps({"mode": "sources"}),
        capture_output=True,
        text=True,
        timeout=300,
    )
    if completed.returncode != 0:
        raise RuntimeError(
            "source extraction failed:\n"
            f"{completed.stdout}\n{completed.stderr}".rstrip()
        )
    return json.loads(completed.stdout)


def build_benchmark() -> dict[str, Any]:
    rows = load_source_rows()
    kept: dict[str, list[dict[str, Any]]] = defaultdict(list)
    seen_in_arms: dict[str, set[str]] = defaultdict(set)
    overlap_pairs: dict[tuple[str, str], set[str]] = defaultdict(set)
    overlap_texts: set[str] = set()
    removed_by_arm: dict[str, int] = defaultdict(int)

    for arm in ARM_ORDER:
        for index, row in enumerate(rows[arm], start=1):
            norm = normalized_text(row["text"])
            earlier_arms = seen_in_arms[norm] - {arm}
            if earlier_arms:
                overlap_texts.add(norm)
                for earlier in earlier_arms:
                    overlap_pairs[(earlier, arm)].add(norm)
                removed_by_arm[arm] += 1
                seen_in_arms[norm].add(arm)
                continue

            item: dict[str, Any] = {
                "id": f"{arm}-{index:04d}",
                "arm": arm,
                "text": row["text"],
            }
            if arm == "authored":
                item.update(
                    {
                        "gold": {"action": row["action"]},
                        "citation": None,
                        "source": AUTHORED_SOURCE,
                    }
                )
            else:
                item.update(
                    {
                        "gold": {
                            "family": row["family"],
                            "signature": row["signature"],
                        },
                        "citation": row["citation"],
                        "source": ATTESTED_SOURCE,
                    }
                )
            kept[arm].append(item)
            seen_in_arms[norm].add(arm)

    pair_counts = {
        f"{left}:{right}": len(texts)
        for (left, right), texts in sorted(overlap_pairs.items())
    }
    for left_index, left in enumerate(ARM_ORDER):
        for right in ARM_ORDER[left_index + 1 :]:
            pair_counts.setdefault(f"{left}:{right}", 0)

    statistics = {
        arm: arm_statistics(kept[arm])
        for arm in ARM_ORDER
    }
    return {
        "schema_version": 1,
        "description": (
            "A fixed recognition benchmark built from labels already carried "
            "by the strategy corpus."
        ),
        "deduplication": {
            "rule": (
                "Normalized text is kept in the first arm in literature, "
                "student, authored order; repeated rows within one arm remain "
                "because they carry corpus bindings."
            ),
            "distinct_cross_arm_overlap_count": len(overlap_texts),
            "row_occurrences_removed": sum(removed_by_arm.values()),
            "removed_by_arm": {
                arm: removed_by_arm[arm] for arm in ARM_ORDER
            },
            "overlap_by_arm_pair": pair_counts,
        },
        "arms": {
            "literature": {
                "source": ATTESTED_SOURCE,
                "scoring_grain": "machine",
                "source_row_count": len(rows["literature"]),
                "item_count": len(kept["literature"]),
                **statistics["literature"],
                "items": kept["literature"],
            },
            "student": {
                "source": ATTESTED_SOURCE,
                "scoring_grain": "machine",
                "source_row_count": len(rows["student"]),
                "item_count": len(kept["student"]),
                **statistics["student"],
                "items": kept["student"],
            },
            "authored": {
                "source": AUTHORED_SOURCE,
                "scoring_grain": "action",
                "comparable_to_machine_arms": False,
                "source_row_count": len(rows["authored"]),
                "item_count": len(kept["authored"]),
                **statistics["authored"],
                "items": kept["authored"],
            },
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    try:
        benchmark = build_benchmark()
    except (OSError, RuntimeError, subprocess.TimeoutExpired, json.JSONDecodeError) as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1

    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(benchmark, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    counts = ", ".join(
        f"{arm}={benchmark['arms'][arm]['item_count']}" for arm in ARM_ORDER
    )
    overlap = benchmark["deduplication"]["distinct_cross_arm_overlap_count"]
    print(f"WROTE {output.relative_to(ROOT) if output.is_relative_to(ROOT) else output}")
    print(f"items: {counts}; cross-arm overlap={overlap}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
