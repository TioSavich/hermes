#!/usr/bin/env python3
"""Curriculum separation coverage: where the numbers cannot tell two machines apart.

R1 (scripts/bigred/loops/) walks each compatible machine pair over its
authored grid and records the inputs on which the two machines SEPARATE — the
inputs where their results differ. Everywhere else on the grid the pair
coincides, and on a coinciding input no reading of the answer alone can say
which of the two a student did.

This script joins that measurement to the curriculum's own number choices. For
each lesson task instance in curriculum/im/generated/compiled_task_instances.pl,
it asks, of every machine pair whose grid covers that input: does the pair
separate here? A task whose numbers coincide for a pair is a task on which a
diagnosis between those two machines has to read the trace, because the answer
carries no information about which one ran.

The audit is a stub in one respect only: it is not yet wired into any page or
gate. It reads real rows and writes a real report, and it names the R1
collection it read.

  usage: python3 scripts/research/separation_coverage_audit.py \
             --collection .bigred-collected/2026-08-08-r1
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TASK_INSTANCES = ROOT / "curriculum/im/generated/compiled_task_instances.pl"
REPORT_DIR = ROOT / "docs/research/internal"

TASK_INSTANCE = re.compile(
    r"compiled_lesson_task_instance\('([^']+)',\s*([a-z_]+)-([a-z_]+)\(([^)]*)\)",
    re.MULTILINE,
)

# The integer-operand schema. Only pairs on this schema can be joined to the
# curriculum's whole-number task instances; every other schema is reported as
# out of the join's reach rather than silently dropped.
INTEGER_PAIR_SCHEMA = '{"a":"integer","b":"integer"}'

OPERATION_FAMILY = {
    "add": "addition",
    "subtract": "subtraction",
    "multiply": "multiplication",
    "divide": "division",
}


@dataclass(frozen=True)
class TaskInstance:
    lesson: str
    operation: str
    family: str
    left: int
    right: int


@dataclass(frozen=True)
class PairRow:
    source: str
    target: str
    schema: str
    separating: frozenset[tuple[int, int]]
    ran: int
    coincide: int
    outcome: str


def read_task_instances(path: Path) -> list[TaskInstance]:
    instances = []
    for lesson, _validity, operation, arguments in TASK_INSTANCE.findall(
        path.read_text(encoding="utf-8")
    ):
        parts = [part.strip() for part in arguments.split(",")]
        if len(parts) != 2 or not all(part.lstrip("-").isdigit() for part in parts):
            continue
        family = OPERATION_FAMILY.get(operation)
        if family is None:
            continue
        instances.append(
            TaskInstance(lesson, operation, family, int(parts[0]), int(parts[1]))
        )
    return instances


def read_pair_rows(collection: Path) -> list[PairRow]:
    if not collection.is_dir():
        raise FileNotFoundError(f"no R1 collection at {collection}")
    rows = []
    for path in sorted(collection.rglob("*.jsonl")):
        for number, line in enumerate(
            path.read_text(encoding="utf-8").splitlines(), 1
        ):
            line = line.strip()
            if not line:
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError as error:
                raise ValueError(f"{path}:{number}: {error}") from error
            if row.get("run") != "r1":
                continue
            evidence = row.get("evidence") or {}
            separating = set()
            for value in evidence.get("separating_inputs") or []:
                if isinstance(value, dict) and "a" in value and "b" in value:
                    separating.add((int(value["a"]), int(value["b"])))
            source = row.get("source") or {}
            target = row.get("target") or {}
            rows.append(
                PairRow(
                    source=f"{source.get('family')}/{source.get('kind')}",
                    target=f"{target.get('family')}/{target.get('kind')}",
                    schema=(row.get("input") or {}).get("schema") or "",
                    separating=frozenset(separating),
                    ran=int(evidence.get("ran") or 0),
                    coincide=int(evidence.get("coincide") or 0),
                    outcome=str(row.get("outcome") or ""),
                )
            )
    return rows


def audit(instances: list[TaskInstance], rows: list[PairRow]) -> dict:
    joinable = [row for row in rows if row.schema == INTEGER_PAIR_SCHEMA]
    unreachable = len(rows) - len(joinable)

    per_lesson: dict[str, dict[str, int]] = defaultdict(
        lambda: {"tasks": 0, "separated": 0, "coinciding": 0}
    )
    coinciding_examples: list[tuple[str, TaskInstance, str, str]] = []
    for instance in instances:
        relevant = [
            row for row in joinable
            if row.source.startswith(f"{instance.family}/")
            or row.target.startswith(f"{instance.family}/")
        ]
        if not relevant:
            continue
        bucket = per_lesson[instance.lesson]
        bucket["tasks"] += 1
        point = (instance.left, instance.right)
        separating_pairs = [row for row in relevant if point in row.separating]
        if separating_pairs:
            bucket["separated"] += 1
        else:
            bucket["coinciding"] += 1
            if len(coinciding_examples) < 40 and relevant:
                coinciding_examples.append(
                    (instance.lesson, instance, relevant[0].source,
                     relevant[0].target)
                )

    fully_coinciding = sorted(
        lesson for lesson, counts in per_lesson.items()
        if counts["tasks"] and counts["separated"] == 0
    )
    return {
        "pair_rows": len(rows),
        "joinable_rows": len(joinable),
        "rows_outside_the_join": unreachable,
        "task_instances": len(instances),
        "lessons_touched": len(per_lesson),
        "lessons_with_no_separating_task": fully_coinciding,
        "per_lesson": dict(per_lesson),
        "coinciding_examples": coinciding_examples,
    }


def render(result: dict, collection: Path) -> str:
    lines = [
        "# Curriculum separation coverage",
        "",
        f"R1 collection read: `{collection}`",
        "",
        "A task instance is SEPARATED when at least one measured machine pair",
        "gives different results on its numbers. A task instance is COINCIDING",
        "when every pair that covers it agrees there: the answer alone cannot",
        "say which machine ran, and a diagnosis has to read the trace.",
        "",
        "## What was joined",
        "",
        f"- R1 pair rows read: {result['pair_rows']}",
        f"- rows on the integer-operand schema (the joinable ones): "
        f"{result['joinable_rows']}",
        f"- rows on other schemas, outside this join's reach: "
        f"{result['rows_outside_the_join']}",
        f"- curriculum task instances read: {result['task_instances']}",
        f"- lessons touched: {result['lessons_touched']}",
        "",
        "## Lessons whose every task instance coincides",
        "",
    ]
    fully = result["lessons_with_no_separating_task"]
    if fully:
        lines.append(
            f"{len(fully)} lesson(s). On these lessons' numbers, no measured "
            "pair separates:"
        )
        lines.append("")
        for lesson in fully:
            counts = result["per_lesson"][lesson]
            lines.append(f"- `{lesson}` — {counts['tasks']} task instance(s)")
    else:
        lines.append("None: every lesson carries at least one task instance on "
                     "which some measured pair separates.")
    lines.extend(["", "## Sample coinciding task instances", ""])
    if result["coinciding_examples"]:
        lines.append("| lesson | task | one pair that cannot be told apart here |")
        lines.append("|---|---|---|")
        for lesson, instance, source, target in result["coinciding_examples"]:
            lines.append(
                f"| `{lesson}` | {instance.operation}({instance.left}, "
                f"{instance.right}) | `{source}` vs `{target}` |"
            )
    else:
        lines.append("None recorded.")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--collection", required=True, type=Path,
                        help="an R1 collection directory of JSONL rows")
    parser.add_argument("--task-instances", type=Path, default=TASK_INSTANCES)
    parser.add_argument("--report", type=Path,
                        default=REPORT_DIR / "2026-08-08-separation-coverage.md")
    parser.add_argument("--print-only", action="store_true",
                        help="write nothing; print the report to stdout")
    arguments = parser.parse_args()

    instances = read_task_instances(arguments.task_instances)
    rows = read_pair_rows(arguments.collection)
    result = audit(instances, rows)
    report = render(result, arguments.collection)

    if arguments.print_only:
        print(report)
        return 0

    arguments.report.parent.mkdir(parents=True, exist_ok=True)
    arguments.report.write_text(report, encoding="utf-8")
    print(f"wrote {arguments.report}", flush=True)
    print(f"  {result['joinable_rows']} joinable pair rows, "
          f"{result['task_instances']} task instances, "
          f"{len(result['lessons_with_no_separating_task'])} lessons with no "
          f"separating task", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
