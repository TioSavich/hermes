#!/usr/bin/env python3
"""Integrity and reproducibility check for the recognition benchmark."""
from __future__ import annotations

import json
import re
import sqlite3
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
BENCHMARK = ROOT / "data/research/recognition_benchmark.json"
BUILDER = ROOT / "scripts/research/build_recognition_benchmark.py"
SCORER = ROOT / "scripts/research/score_recognition_benchmark.py"
DB = ROOT / "data/research/research_shared.db"
TABLES = ROOT / "knowledge/strategies/transition_tables"
REPORT = ROOT / "docs/research/2026-07-25-recognition-benchmark.md"
TRANSITION_RE = re.compile(
    r"(?m)^automaton_transition\((\w+), (\w+), \w+, \w+, \w+,"
)
SUBSET_IDS = (
    "literature-0001",
    "literature-0002",
    "literature-0003",
    "student-0001",
    "student-0002",
    "student-0003",
    "authored-0001",
    "authored-0002",
    "authored-0003",
)


def run(command: list[str], timeout: int = 600) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=timeout,
    )


def normalized_text(text: str) -> str:
    return " ".join(re.findall(r"[a-z0-9]+(?:'[a-z0-9]+)?", text.lower()))


def all_items(benchmark: dict[str, Any]) -> list[dict[str, Any]]:
    return [
        item
        for arm in ("literature", "student", "authored")
        for item in benchmark["arms"][arm]["items"]
    ]


def main() -> int:
    required = (BENCHMARK, BUILDER, SCORER, DB, TABLES, REPORT)
    missing = [path for path in required if not path.exists()]
    if missing:
        for path in missing:
            print(f"FAIL: missing {path.relative_to(ROOT)}", file=sys.stderr)
        return 1

    errors: list[str] = []
    with tempfile.TemporaryDirectory(prefix="recognition-benchmark-") as temp:
        first = Path(temp) / "first.json"
        second = Path(temp) / "second.json"
        for target in (first, second):
            completed = run(
                [sys.executable, str(BUILDER), "--output", str(target)]
            )
            if completed.returncode != 0:
                errors.append(
                    f"builder failed for {target.name}: "
                    f"{completed.stderr.strip()[:400]}"
                )
                break
        else:
            if first.read_bytes() != second.read_bytes():
                errors.append("two benchmark regenerations differ")
            if first.read_bytes() != BENCHMARK.read_bytes():
                errors.append(
                    "benchmark regeneration differs from "
                    "data/research/recognition_benchmark.json"
                )

    try:
        benchmark = json.loads(BENCHMARK.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"FAIL: cannot read benchmark: {exc}", file=sys.stderr)
        return 1

    items = all_items(benchmark)
    ids = [item["id"] for item in items]
    if len(ids) != len(set(ids)):
        errors.append("benchmark item ids are not unique")

    text_arms: dict[str, set[str]] = {}
    for item in items:
        text_arms.setdefault(normalized_text(item["text"]), set()).add(item["arm"])
    cross_arm = {text: arms for text, arms in text_arms.items() if len(arms) > 1}
    recorded_overlap = benchmark["deduplication"][
        "distinct_cross_arm_overlap_count"
    ]
    if cross_arm:
        errors.append(
            f"{len(cross_arm)} normalized text(s) remain in more than one arm"
        )
    pair_overlap = sum(
        benchmark["deduplication"]["overlap_by_arm_pair"].values()
    )
    if recorded_overlap > pair_overlap:
        errors.append("recorded cross-arm overlap exceeds its pairwise counts")

    machines: set[tuple[str, str]] = set()
    for path in sorted(TABLES.glob("*.pl")):
        machines.update(
            TRANSITION_RE.findall(path.read_text(encoding="utf-8"))
        )
    for item in items:
        if item["arm"] == "authored":
            if set(item["gold"]) != {"action"}:
                errors.append(
                    f"{item['id']}: authored gold is not exactly one action"
                )
            if item["citation"] is not None:
                errors.append(
                    f"{item['id']}: authored control claims a citation"
                )
            continue
        gold = item["gold"]
        if (gold["family"], gold["signature"]) not in machines:
            errors.append(
                f"{item['id']}: no transition-table machine "
                f"{gold['family']}/{gold['signature']}"
            )

    connection = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
    try:
        article_keys = {
            row[0]
            for row in connection.execute(
                "select bibtex_key from articles where bibtex_key is not null"
            )
        }
    finally:
        connection.close()
    for item in items:
        if item["arm"] != "authored" and item["citation"] not in article_keys:
            errors.append(
                f"{item['id']}: citation {item['citation']!r} does not resolve "
                "in research_shared.db articles"
            )

    score_command = [
        sys.executable,
        str(SCORER),
        "--benchmark",
        str(BENCHMARK),
        "--format",
        "json",
    ]
    for item_id in SUBSET_IDS:
        score_command.extend(["--item-id", item_id])
    first_score = run(score_command)
    second_score = run(score_command)
    if first_score.returncode != 0:
        errors.append(f"subset scorer failed: {first_score.stderr.strip()[:400]}")
    elif second_score.returncode != 0:
        errors.append(
            f"second subset scorer failed: {second_score.stderr.strip()[:400]}"
        )
    elif first_score.stdout != second_score.stdout:
        errors.append("the fixed subset scorer did not reproduce its numbers")
    else:
        try:
            subset_scores = json.loads(first_score.stdout)
            authored = subset_scores["arms"]["authored"]
            if authored.get("comparable_to_machine_arms") is not False:
                errors.append("authored subset score is not marked non-comparable")
            if "recall_at_1" in authored:
                errors.append(
                    "authored subset score is presented as machine recall@1"
                )
        except (json.JSONDecodeError, KeyError) as exc:
            errors.append(f"subset score has an invalid schema: {exc}")

    report_text = REPORT.read_text(encoding="utf-8")
    if not re.search(
        r"not\s+comparable\s+to\s+the\s+machine-level\s+arms",
        report_text,
    ):
        errors.append("report does not state that the authored arm is not comparable")

    if errors:
        print(f"FAIL: {len(errors)} problem(s):", file=sys.stderr)
        for error in errors[:30]:
            print(f"  - {error}", file=sys.stderr)
        if len(errors) > 30:
            print(f"  ... and {len(errors) - 30} more", file=sys.stderr)
        return 1

    counts = {
        arm: benchmark["arms"][arm]["item_count"]
        for arm in ("literature", "student", "authored")
    }
    print(
        "PASS benchmark regenerates byte-identically twice and matches the "
        "committed artifact"
    )
    print(
        "PASS every machine label exists in the transition tables and every "
        "corpus citation resolves in research_shared.db articles"
    )
    print(
        "PASS the fixed nine-item subset reproduces its scores without a "
        "research-score threshold"
    )
    print(
        "PASS authored gold is action-only, scored separately, and marked "
        "non-comparable"
    )
    print(
        "items: "
        + ", ".join(f"{arm}={count}" for arm, count in counts.items())
        + f"; recorded cross-arm overlap={recorded_overlap}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
