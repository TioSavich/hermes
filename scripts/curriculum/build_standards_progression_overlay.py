#!/usr/bin/env python3
"""Build the lesson-mediated candidate standards progression overlay.

Each edge projects a distinct ``building_on`` code to an ``addressing`` code
through one or more Learning Commons spine lessons.  The projection records
curriculum evidence only.  Every emitted edge carries
``learner_reachability: false`` so downstream readers must retain the review
boundary.
"""

from __future__ import annotations

import argparse
from collections import defaultdict
import hashlib
import json
from pathlib import Path
import sys
from typing import Any, NoReturn


ROOT = Path(__file__).resolve().parents[2]
SPINE = ROOT / "data/learningcommons/derived/im_k8_spine.json"
OUTPUT = ROOT / "data/learningcommons/derived/im_standards_progression_overlay.json"
SCHEMA = "im_standards_progression_overlay_v1"

# Live-spine measurement pinned 2026-08-08.  Re-measure before changing these:
# 1,308 lessons yield 707 lesson-mediated evidence rows, 621 distinct pairs,
# and 390 pairs whose prefixes before the first period differ.
EXPECTED_LESSONS = 1_308
EXPECTED_EVIDENCE_ROWS = 707
EXPECTED_EDGES = 621
EXPECTED_CROSS_GRADE_EDGES = 390


def fail(message: str) -> NoReturn:
    raise SystemExit(f"build_standards_progression_overlay.py: {message}")


def load_spine(path: Path = SPINE) -> list[dict[str, Any]]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"cannot read {path}: {exc}")
    if not isinstance(value, list) or not all(isinstance(row, dict) for row in value):
        fail(f"expected a list of objects at {path}")
    return value


def grade_prefix(code: str) -> str:
    prefix, separator, _rest = code.partition(".")
    if not separator or not prefix:
        fail(f"standard code has no grade prefix: {code!r}")
    return prefix


def band_codes(row: dict[str, Any], band: str, row_number: int) -> list[str]:
    ccss = row.get("ccss", {})
    if not isinstance(ccss, dict):
        fail(f"spine row {row_number} has a non-object ccss field")
    values = ccss.get(band, [])
    if not isinstance(values, list) or not all(
        isinstance(code, str) and code for code in values
    ):
        fail(f"spine row {row_number} has an invalid {band} band")
    return sorted(set(values))


def lesson_reference(row: dict[str, Any], row_number: int) -> dict[str, Any]:
    required = ("repo_id", "kg_id", "grade", "unit", "lesson", "name")
    missing = [key for key in required if key not in row]
    if missing:
        fail(f"spine row {row_number} lacks {', '.join(missing)}")
    return {
        "repo_id": row["repo_id"],
        "kg_id": row["kg_id"],
        "grade": row["grade"],
        "unit": row["unit"],
        "lesson": row["lesson"],
        "name": row["name"],
    }


def build(spine_path: Path = SPINE) -> dict[str, Any]:
    spine = load_spine(spine_path)
    if len(spine) != EXPECTED_LESSONS:
        fail(f"expected {EXPECTED_LESSONS} spine lessons, found {len(spine)}")

    evidence: dict[tuple[str, str], list[dict[str, Any]]] = defaultdict(list)
    evidence_rows = 0
    for row_number, row in enumerate(spine, 1):
        building_on = band_codes(row, "building_on", row_number)
        addressing = band_codes(row, "addressing", row_number)
        for from_code in building_on:
            for to_code in addressing:
                if from_code == to_code:
                    continue
                evidence_rows += 1
                evidence[(from_code, to_code)].append(
                    {
                        "source_path": str(spine_path.relative_to(ROOT)),
                        "source_row": row_number,
                        "spine_row": row,
                    }
                )

    if evidence_rows != EXPECTED_EVIDENCE_ROWS:
        fail(
            f"expected {EXPECTED_EVIDENCE_ROWS} evidence rows, found {evidence_rows}"
        )
    if len(evidence) != EXPECTED_EDGES:
        fail(f"expected {EXPECTED_EDGES} distinct edges, found {len(evidence)}")

    edges: list[dict[str, Any]] = []
    for (from_code, to_code), provenance in sorted(evidence.items()):
        from_prefix = grade_prefix(from_code)
        to_prefix = grade_prefix(to_code)
        edges.append(
            {
                "from_code": from_code,
                "to_code": to_code,
                "mediating_lessons": [
                    lesson_reference(item["spine_row"], item["source_row"])
                    for item in provenance
                ],
                "from_grade_prefix": from_prefix,
                "to_grade_prefix": to_prefix,
                "cross_grade_prefix": from_prefix != to_prefix,
                "provenance": provenance,
                "learner_reachability": False,
            }
        )

    cross_grade_edges = sum(edge["cross_grade_prefix"] for edge in edges)
    if cross_grade_edges != EXPECTED_CROSS_GRADE_EDGES:
        fail(
            f"expected {EXPECTED_CROSS_GRADE_EDGES} cross-grade-prefix edges, "
            f"found {cross_grade_edges}"
        )

    source_bytes = spine_path.read_bytes()
    return {
        "schema": SCHEMA,
        "generated_by": "scripts/curriculum/build_standards_progression_overlay.py",
        "source": str(spine_path.relative_to(ROOT)),
        "source_sha256": hashlib.sha256(source_bytes).hexdigest(),
        "measured_on": "2026-08-08",
        "relation": "lesson_mediated_building_on_to_addressing_candidate",
        "learner_reachability": False,
        "promotion_requirement": (
            "A reviewed promotion with executable learner-path evidence is required."
        ),
        "lesson_count": len(spine),
        "evidence_row_count": evidence_rows,
        "edge_count": len(edges),
        "cross_grade_prefix_edge_count": cross_grade_edges,
        "within_grade_prefix_edge_count": len(edges) - cross_grade_edges,
        "edges": edges,
    }


def render(payload: dict[str, Any]) -> str:
    return json.dumps(payload, indent=1, ensure_ascii=False, sort_keys=True) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()
    output = args.output if args.output.is_absolute() else ROOT / args.output
    payload = build()
    rendered = render(payload)
    if args.check:
        current = output.read_text(encoding="utf-8") if output.exists() else ""
        if current != rendered:
            print("stale standards progression overlay", file=sys.stderr)
            return 1
        state = "current"
    else:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(rendered, encoding="utf-8")
        state = "written"
    print(
        f"standards progression overlay {state}: lessons={payload['lesson_count']} "
        f"evidence_rows={payload['evidence_row_count']} edges={payload['edge_count']} "
        f"cross_grade_prefix={payload['cross_grade_prefix_edge_count']} "
        f"learner_reachability=false"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
