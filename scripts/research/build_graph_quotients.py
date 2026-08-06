#!/usr/bin/env python3
"""Build deterministic quotient views of the shipped computational graph.

Slice 1 emits the cross-family shared-action quotient. A bundle records only
that its two families carry the same canonical action names. Its source
machines and transition edges remain available under each action member.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "docs/research/assets/automata/full_graph.json"
OUTPUT = ROOT / "docs/research/assets/automata/family_graph.json"
SOURCE_ARTIFACT = SOURCE.relative_to(ROOT).as_posix()
ASSERTION = (
    "A bundle records shared canonical action names only; it does not assert "
    "equivalence, prerequisite order, or a learner relation."
)


def _source_bytes(path: Path = SOURCE) -> bytes:
    try:
        return path.read_bytes()
    except OSError as exc:
        raise ValueError(f"cannot read source graph {path.relative_to(ROOT)}: {exc}") from exc


def _load_source(source_bytes: bytes) -> dict[str, Any]:
    try:
        source = json.loads(source_bytes)
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise ValueError(f"source graph is not valid UTF-8 JSON: {exc}") from exc
    if not isinstance(source, dict) or source.get("schema") != 2:
        raise ValueError("family quotient requires full graph schema 2")
    if not isinstance(source.get("nodes"), list) or not isinstance(source.get("edges"), list):
        raise ValueError("source graph lacks node or edge inventories")
    return source


def _family_nodes(source: dict[str, Any]) -> list[dict[str, Any]]:
    families: dict[str, dict[str, Any]] = {}
    machines: dict[str, set[str]] = defaultdict(set)
    state_counts: Counter[str] = Counter()
    transition_counts: Counter[str] = Counter()
    for node in source["nodes"]:
        family = node.get("family")
        level = node.get("level")
        machine = f"{family}/{node.get('kind')}"
        if not isinstance(family, str) or not isinstance(level, int):
            raise ValueError("source node has an invalid family or level")
        prior = families.setdefault(family, {"level": level})
        if prior["level"] != level:
            raise ValueError(f"source graph assigns multiple levels to {family}")
        machines[family].add(machine)
        state_counts[family] += 1
    for edge in source["edges"]:
        machine = edge.get("machine")
        if not isinstance(machine, str) or "/" not in machine:
            raise ValueError("source edge has an invalid machine id")
        transition_counts[machine.split("/", 1)[0]] += 1

    ordered = sorted(families, key=lambda family: (families[family]["level"], family))
    radius = 22.0
    nodes: list[dict[str, Any]] = []
    for index, family in enumerate(ordered):
        angle = -math.pi / 2 + math.tau * index / len(ordered)
        level = families[family]["level"]
        nodes.append({
            "id": f"family:{family}",
            "family": family,
            "level": level,
            "machine_count": len(machines[family]),
            "state_count": state_counts[family],
            "transition_count": transition_counts[family],
            "position": {
                "x": round(radius * math.cos(angle), 6),
                "y": round(radius * math.sin(angle), 6),
                "z": level,
            },
        })
    return nodes


def _family_edges(source: dict[str, Any]) -> list[dict[str, Any]]:
    by_action_family: dict[str, dict[str, list[dict[str, Any]]]] = defaultdict(
        lambda: defaultdict(list)
    )
    for edge in source["edges"]:
        canonical = edge.get("canonical_action")
        machine = edge.get("machine")
        edge_id = edge.get("id")
        if canonical is None:
            continue
        if not all(isinstance(value, str) for value in (canonical, machine, edge_id)):
            raise ValueError("source edge has an invalid canonical action reference")
        by_action_family[canonical][machine.split("/", 1)[0]].append(edge)

    members_by_pair: dict[tuple[str, str], list[dict[str, Any]]] = defaultdict(list)
    for canonical in sorted(by_action_family):
        family_edges = by_action_family[canonical]
        families = sorted(family_edges)
        for left_index, left in enumerate(families):
            for right in families[left_index + 1:]:
                carriers = sorted(family_edges[left] + family_edges[right], key=lambda edge: edge["id"])
                stances = {edge.get("stance") for edge in carriers}
                if len(stances) != 1 or None in stances:
                    raise ValueError(
                        f"canonical action {canonical!r} has inconsistent carrier stances: "
                        f"{sorted(str(stance) for stance in stances)}"
                    )
                stance = next(iter(stances))
                validity_modes = sorted({
                    str(mode)
                    for edge in carriers
                    if edge.get("stance") == "deforming"
                    for mode in edge.get("validity_modes", [])
                })
                if stance != "deforming" and validity_modes:
                    raise ValueError(f"non-deforming action {canonical!r} acquired validity modes")
                members_by_pair[(left, right)].append({
                    "canonical_action": canonical,
                    "stance": stance,
                    "validity_modes": validity_modes,
                    "carrier_machine_ids": sorted({str(edge["machine"]) for edge in carriers}),
                    "source_edge_ids": [str(edge["id"]) for edge in carriers],
                })

    edges: list[dict[str, Any]] = []
    for left, right in sorted(members_by_pair):
        members = sorted(
            members_by_pair[(left, right)], key=lambda member: member["canonical_action"]
        )
        stance_counts = Counter(str(member["stance"]) for member in members)
        edges.append({
            "id": f"family-bundle:{left}:{right}",
            "from": f"family:{left}",
            "to": f"family:{right}",
            "relation": "cross_family_shared_action",
            "stances": sorted(stance_counts),
            "stance_counts": {
                stance: stance_counts[stance] for stance in sorted(stance_counts)
            },
            "members": members,
        })
    return edges


def generate_family_graph(source_bytes: bytes | None = None) -> dict[str, Any]:
    raw = _source_bytes() if source_bytes is None else source_bytes
    source = _load_source(raw)
    nodes = _family_nodes(source)
    edges = _family_edges(source)
    members = [member for edge in edges for member in edge["members"]]
    stance_counts = Counter(str(member["stance"]) for member in members)
    validity_counts = Counter(
        str(mode) for member in members for mode in member["validity_modes"]
    )
    return {
        "schema": 1,
        "view": "family",
        "source_artifact": SOURCE_ARTIFACT,
        "source_schema": source["schema"],
        "source_sha256": hashlib.sha256(raw).hexdigest(),
        "meta": {
            "scope": "Cross-family bundles over canonical actions carried in both families.",
            "assertion": ASSERTION,
            "layout": {
                "description": (
                    "Family nodes use a deterministic ring; vertical placement follows "
                    "the authored family level in the full graph."
                ),
                "vertical_placement": "authored",
            },
            "counts": {
                "nodes": len(nodes),
                "edges": len(edges),
                "members": len(members),
                "members_by_stance": {
                    stance: stance_counts.get(stance, 0)
                    for stance in ("conserving", "deforming", "neutral")
                },
                "member_validity_mode_occurrences": {
                    mode: validity_counts[mode] for mode in sorted(validity_counts)
                },
                "mixed_stance_edges": sum(len(edge["stances"]) > 1 for edge in edges),
            },
        },
        "nodes": nodes,
        "edges": edges,
    }


def generate_json(source_bytes: bytes | None = None) -> str:
    return json.dumps(generate_family_graph(source_bytes), indent=2, ensure_ascii=False) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=OUTPUT)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    content = generate_json()
    if args.check:
        current = args.output.read_text(encoding="utf-8") if args.output.exists() else ""
        if current != content:
            print(f"stale family graph: {args.output.relative_to(ROOT)}", file=sys.stderr)
            return 1
    else:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(content, encoding="utf-8")
    counts = json.loads(content)["meta"]["counts"]
    print(
        f"family graph: {counts['nodes']} nodes, {counts['edges']} bundle edges, "
        f"{counts['members']} action members"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
