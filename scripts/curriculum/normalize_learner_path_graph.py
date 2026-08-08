#!/usr/bin/env python3
"""Stage-2 helpers for candidate standards annotations on graph components.

The standards overlay may annotate normalized components.  It never merges
components and never contributes an edge to learner reachability.
"""

from __future__ import annotations

import argparse
from copy import deepcopy
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OVERLAY = (
    ROOT / "data/learningcommons/derived/im_standards_progression_overlay.json"
)
OVERLAY_SCHEMA = "im_standards_progression_overlay_v1"


def load_candidate_standards_overlay(
    path: Path = DEFAULT_OVERLAY,
) -> list[dict[str, Any]]:
    """Read candidate rows and enforce the learner-reachability boundary."""
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict) or payload.get("schema") != OVERLAY_SCHEMA:
        raise ValueError(f"unsupported standards overlay schema at {path}")
    if payload.get("learner_reachability") is not False:
        raise ValueError("standards overlay must set learner_reachability to false")
    edges = payload.get("edges")
    if not isinstance(edges, list):
        raise ValueError("standards overlay edges must be a list")
    required = {
        "from_code",
        "to_code",
        "mediating_lessons",
        "from_grade_prefix",
        "to_grade_prefix",
        "cross_grade_prefix",
        "provenance",
        "learner_reachability",
    }
    for index, edge in enumerate(edges, 1):
        if not isinstance(edge, dict) or not required.issubset(edge):
            raise ValueError(f"standards overlay edge {index} is incomplete")
        if edge["learner_reachability"] is not False:
            raise ValueError(
                f"standards overlay edge {index} must keep learner_reachability false"
            )
        expected_cross_grade = (
            edge["from_grade_prefix"] != edge["to_grade_prefix"]
        )
        if edge["cross_grade_prefix"] is not expected_cross_grade:
            raise ValueError(f"standards overlay edge {index} has inconsistent prefixes")
    return edges


def typed_primary_key(node: dict[str, Any]) -> tuple[str, str]:
    """Return the stage-2 node key without collapsing unlike node types."""
    node_type = node.get("node_type")
    node_id = node.get("node_id")
    if not isinstance(node_type, str) or not node_type:
        raise ValueError("normalized graph node requires node_type")
    if not isinstance(node_id, str) or not node_id:
        raise ValueError("normalized graph node requires node_id")
    return node_type, node_id


def normalize_nodes_by_typed_primary_key(
    nodes: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    """Collapse duplicate records while retaining every source record."""
    grouped: dict[tuple[str, str], list[dict[str, Any]]] = {}
    for node in nodes:
        grouped.setdefault(typed_primary_key(node), []).append(deepcopy(node))
    return [
        {
            "node_type": key[0],
            "node_id": key[1],
            "source_records": records,
        }
        for key, records in sorted(grouped.items())
    ]


def annotate_components_with_candidate_cross_grade_links(
    components: list[dict[str, Any]],
    overlay_edges: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    """Attach cross-grade candidates without changing component membership."""
    annotated = deepcopy(components)
    by_id: dict[str, dict[str, Any]] = {}
    code_components: dict[str, set[str]] = {}
    original_memberships: dict[str, Any] = {}
    for component in annotated:
        component_id = component.get("component_id")
        codes = component.get("standard_codes", [])
        if not isinstance(component_id, str) or not component_id:
            raise ValueError("component requires component_id")
        if component_id in by_id:
            raise ValueError(f"duplicate component_id: {component_id}")
        if not isinstance(codes, list) or not all(isinstance(code, str) for code in codes):
            raise ValueError(f"component {component_id} has invalid standard_codes")
        by_id[component_id] = component
        original_memberships[component_id] = deepcopy(component.get("nodes", []))
        component["candidate_cross_grade_links"] = []
        for code in codes:
            code_components.setdefault(code, set()).add(component_id)

    for edge in overlay_edges:
        if edge.get("learner_reachability") is not False:
            raise ValueError("component annotation received a licensed overlay edge")
        if edge.get("cross_grade_prefix") is not True:
            continue
        from_components = sorted(code_components.get(edge["from_code"], set()))
        to_components = sorted(code_components.get(edge["to_code"], set()))
        for component_id in from_components:
            by_id[component_id]["candidate_cross_grade_links"].append(
                {
                    "from_code": edge["from_code"],
                    "to_code": edge["to_code"],
                    "role": "from",
                    "counterpart_component_ids": to_components,
                    "mediating_lessons": deepcopy(edge["mediating_lessons"]),
                    "provenance": deepcopy(edge["provenance"]),
                    "learner_reachability": False,
                }
            )
        for component_id in to_components:
            by_id[component_id]["candidate_cross_grade_links"].append(
                {
                    "from_code": edge["from_code"],
                    "to_code": edge["to_code"],
                    "role": "to",
                    "counterpart_component_ids": from_components,
                    "mediating_lessons": deepcopy(edge["mediating_lessons"]),
                    "provenance": deepcopy(edge["provenance"]),
                    "learner_reachability": False,
                }
            )

    for component_id, members in original_memberships.items():
        if by_id[component_id].get("nodes", []) != members:
            raise AssertionError("candidate annotation changed component membership")
        by_id[component_id]["candidate_cross_grade_links"].sort(
            key=lambda row: (row["from_code"], row["to_code"], row["role"])
        )
    return annotated


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("components", type=Path)
    parser.add_argument("--overlay", type=Path, default=DEFAULT_OVERLAY)
    args = parser.parse_args()
    components = json.loads(args.components.read_text(encoding="utf-8"))
    if not isinstance(components, list):
        raise SystemExit("components input must be a JSON list")
    edges = load_candidate_standards_overlay(args.overlay)
    result = annotate_components_with_candidate_cross_grade_links(components, edges)
    print(json.dumps(result, indent=1, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
