#!/usr/bin/env python3
"""Byte, schema, reference, and expansion gate for graph quotients."""
from __future__ import annotations

import hashlib
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
RESEARCH_SCRIPTS = ROOT / "scripts/research"
sys.path.insert(0, str(RESEARCH_SCRIPTS))

from build_graph_quotients import OUTPUT, SOURCE, generate_json  # noqa: E402


def fail_if(condition: bool, message: str, failures: list[str]) -> None:
    if condition:
        failures.append(message)


def source_projection(full: dict[str, Any]) -> dict[tuple[str, str], dict[str, dict[str, Any]]]:
    carriers: dict[str, dict[str, list[dict[str, Any]]]] = defaultdict(lambda: defaultdict(list))
    for edge in full["edges"]:
        canonical = edge.get("canonical_action")
        if canonical is None:
            continue
        family = edge["machine"].split("/", 1)[0]
        carriers[canonical][family].append(edge)
    projection: dict[tuple[str, str], dict[str, dict[str, Any]]] = defaultdict(dict)
    for canonical, family_edges in carriers.items():
        families = sorted(family_edges)
        for index, left in enumerate(families):
            for right in families[index + 1:]:
                edges = sorted(family_edges[left] + family_edges[right], key=lambda edge: edge["id"])
                projection[(left, right)][canonical] = {
                    "stance": edges[0]["stance"],
                    "validity_modes": sorted({
                        mode for edge in edges if edge["stance"] == "deforming"
                        for mode in edge.get("validity_modes", [])
                    }),
                    "carrier_machine_ids": sorted({edge["machine"] for edge in edges}),
                    "source_edge_ids": [edge["id"] for edge in edges],
                }
    return projection


def main() -> int:
    failures: list[str] = []
    source_bytes = SOURCE.read_bytes()
    first = generate_json(source_bytes)
    second = generate_json(source_bytes)
    fail_if(first != second, "family quotient rebuild is not deterministic", failures)
    if not OUTPUT.exists():
        failures.append(f"missing generated artifact: {OUTPUT.relative_to(ROOT)}")
    else:
        fail_if(OUTPUT.read_text(encoding="utf-8") != first,
                f"stale generated artifact: {OUTPUT.relative_to(ROOT)}", failures)

    full = json.loads(source_bytes)
    data = json.loads(first)
    nodes = data.get("nodes", [])
    edges = data.get("edges", [])
    counts = data.get("meta", {}).get("counts", {})
    node_ids = [node.get("id") for node in nodes]
    edge_ids = [edge.get("id") for edge in edges]
    source_edge_by_id = {edge["id"]: edge for edge in full["edges"]}
    source_machine_ids = {edge["machine"] for edge in full["edges"]}

    fail_if(data.get("schema") != 1, "family quotient schema is not 1", failures)
    fail_if(data.get("view") != "family", "family quotient view is not family", failures)
    fail_if(data.get("source_artifact") != SOURCE.relative_to(ROOT).as_posix(),
            "family quotient source_artifact is wrong", failures)
    fail_if(data.get("source_schema") != full.get("schema"),
            "family quotient source_schema disagrees with full graph", failures)
    fail_if(data.get("source_sha256") != hashlib.sha256(source_bytes).hexdigest(),
            "family quotient source_sha256 disagrees with full graph bytes", failures)
    fail_if(len(node_ids) != len(set(node_ids)), "duplicate family node ids", failures)
    fail_if(len(edge_ids) != len(set(edge_ids)), "duplicate family bundle ids", failures)
    fail_if(len(nodes) != len({node["family"] for node in full["nodes"]}),
            "family node count disagrees with full graph", failures)
    fail_if(len(nodes) != 15, f"expected 15 family nodes, got {len(nodes)}", failures)
    fail_if(len(edges) != len(nodes) * (len(nodes) - 1) // 2,
            "family quotient does not contain every cross-family pair", failures)

    expanded: dict[tuple[str, str], dict[str, dict[str, Any]]] = defaultdict(dict)
    member_count = 0
    overall_stances: Counter[str] = Counter()
    overall_modes: Counter[str] = Counter()
    node_id_set = set(node_ids)
    for edge in edges:
        source_id = edge.get("from")
        target_id = edge.get("to")
        fail_if(source_id not in node_id_set or target_id not in node_id_set,
                f"bundle {edge.get('id')} references a missing node", failures)
        fail_if(edge.get("relation") != "cross_family_shared_action",
                f"bundle {edge.get('id')} has a wrong relation", failures)
        pair = tuple(sorted((str(source_id).removeprefix("family:"),
                             str(target_id).removeprefix("family:"))))
        member_actions: list[str] = []
        member_stances: Counter[str] = Counter()
        for member in edge.get("members", []):
            member_count += 1
            canonical = member.get("canonical_action")
            stance = member.get("stance")
            member_actions.append(str(canonical))
            member_stances[str(stance)] += 1
            overall_stances[str(stance)] += 1
            for mode in member.get("validity_modes", []):
                overall_modes[str(mode)] += 1
            source_ids = member.get("source_edge_ids", [])
            machine_ids = member.get("carrier_machine_ids", [])
            fail_if(any(edge_id not in source_edge_by_id for edge_id in source_ids),
                    f"member {canonical} names a missing source edge", failures)
            fail_if(any(machine not in source_machine_ids for machine in machine_ids),
                    f"member {canonical} names a missing carrier machine", failures)
            fail_if(any(source_edge_by_id[edge_id].get("canonical_action") != canonical
                        for edge_id in source_ids if edge_id in source_edge_by_id),
                    f"member {canonical} source edge has a different action", failures)
            fail_if(any(source_edge_by_id[edge_id].get("machine") not in machine_ids
                        for edge_id in source_ids if edge_id in source_edge_by_id),
                    f"member {canonical} source machine index is incomplete", failures)
            if stance != "deforming":
                fail_if(member.get("validity_modes") != [],
                        f"non-deforming member {canonical} carries validity modes", failures)
            expanded[pair][str(canonical)] = {
                "stance": stance,
                "validity_modes": member.get("validity_modes"),
                "carrier_machine_ids": machine_ids,
                "source_edge_ids": source_ids,
            }
        fail_if(member_actions != sorted(set(member_actions)),
                f"bundle {edge.get('id')} member actions are not sorted and unique", failures)
        expected_stances = sorted(member_stances)
        expected_stance_counts = {stance: member_stances[stance] for stance in expected_stances}
        fail_if(edge.get("stances") != expected_stances,
                f"bundle {edge.get('id')} stance union is wrong", failures)
        fail_if(edge.get("stance_counts") != expected_stance_counts,
                f"bundle {edge.get('id')} stance counts are wrong", failures)

    expected_projection = source_projection(full)
    fail_if(dict(expanded) != dict(expected_projection),
            "expanding family bundles does not reproduce the full-graph projection", failures)
    expected_counts = {
        "nodes": len(nodes),
        "edges": len(edges),
        "members": member_count,
        "members_by_stance": {
            stance: overall_stances.get(stance, 0)
            for stance in ("conserving", "deforming", "neutral")
        },
        "member_validity_mode_occurrences": {
            mode: overall_modes[mode] for mode in sorted(overall_modes)
        },
        "mixed_stance_edges": sum(len(edge.get("stances", [])) > 1 for edge in edges),
    }
    fail_if(counts != expected_counts, "family quotient meta counts are wrong", failures)

    if failures:
        for failure in failures:
            print(f"FAIL {failure}", file=sys.stderr)
        return 1
    print(
        f"PASS family quotient: {len(nodes)} nodes, {len(edges)} bundle edges, "
        f"{member_count} action members"
    )
    print("PASS family quotient rebuild is byte-identical and matches its schema-2 source hash")
    print("PASS every bundle expands to the selected full-graph projection")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
