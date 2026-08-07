#!/usr/bin/env python3
"""Build deterministic quotient views of the shipped computational graph.

The family and ladder views bundle shared canonical action names. The action
view bundles machine co-occurrences. Every aggregate retains the source
machines, transition edges, stances, and projected validity modes underneath.
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
ACTION_OUTPUT = ROOT / "docs/research/assets/automata/canonical_action_graph.json"
LADDER_OUTPUT = ROOT / "docs/research/assets/automata/ladder_graph.json"
OUTPUTS = {
    "family": OUTPUT,
    "action": ACTION_OUTPUT,
    "ladder": LADDER_OUTPUT,
}
SOURCE_ARTIFACT = SOURCE.relative_to(ROOT).as_posix()
ASSERTION = (
    "A bundle records shared canonical action names only; it does not assert "
    "equivalence, prerequisite order, or a learner relation."
)
DOMAIN_ASSERTION = ASSERTION
ACTION_ASSERTION = (
    "An edge records that two distinct canonical action names occur in at least "
    "one machine; it does not assert adjacency, order, composition, or equivalence."
)
LADDER_ASSERTION = (
    "A bundle records shared canonical action names carried at two authored rungs; "
    "it does not assert reachability, prerequisite order, or a learner relation."
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


def generate_domain_graph(
    family: str, source_bytes: bytes | None = None
) -> dict[str, Any]:
    raw = _source_bytes() if source_bytes is None else source_bytes
    family_graph = generate_family_graph(raw)
    focal_id = f"family:{family}"
    focal = next((node for node in family_graph["nodes"] if node["id"] == focal_id), None)
    if focal is None:
        available = ", ".join(node["family"] for node in family_graph["nodes"])
        raise ValueError(f"unknown domain family {family!r}; choose one of: {available}")
    edges = [
        edge for edge in family_graph["edges"]
        if edge["from"] == focal_id or edge["to"] == focal_id
    ]
    members = [member for edge in edges for member in edge["members"]]
    stance_counts = Counter(member["stance"] for member in members)
    validity_counts = Counter(
        mode for member in members for mode in member["validity_modes"]
    )
    return {
        "schema": 1,
        "view": "domain",
        "source_artifact": SOURCE_ARTIFACT,
        "source_schema": family_graph["source_schema"],
        "source_sha256": family_graph["source_sha256"],
        "meta": {
            "scope": (
                f"Family bundles incident on the focal {family} family."
            ),
            "assertion": DOMAIN_ASSERTION,
            "focal_family": family,
            "local": {
                "machine_count": focal["machine_count"],
                "state_count": focal["state_count"],
                "transition_count": focal["transition_count"],
            },
            "layout": family_graph["meta"]["layout"],
            "counts": {
                "nodes": len(family_graph["nodes"]),
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
        "nodes": family_graph["nodes"],
        "edges": edges,
    }


def _validity_modes(edges: list[dict[str, Any]]) -> list[str]:
    return sorted({
        str(mode)
        for edge in edges
        if edge.get("stance") == "deforming"
        for mode in edge.get("validity_modes", [])
    })


def _action_evidence(canonical: str, edges: list[dict[str, Any]]) -> dict[str, Any]:
    ordered = sorted(edges, key=lambda edge: edge["id"])
    stances = {edge.get("stance") for edge in ordered}
    if len(stances) != 1 or None in stances:
        raise ValueError(
            f"canonical action {canonical!r} has inconsistent carrier stances: "
            f"{sorted(str(stance) for stance in stances)}"
        )
    stance = next(iter(stances))
    modes = _validity_modes(ordered)
    if stance != "deforming" and modes:
        raise ValueError(f"non-deforming action {canonical!r} acquired validity modes")
    return {
        "canonical_action": canonical,
        "stance": stance,
        "validity_modes": modes,
        "source_edge_ids": [str(edge["id"]) for edge in ordered],
    }


def generate_action_graph(source_bytes: bytes | None = None) -> dict[str, Any]:
    raw = _source_bytes() if source_bytes is None else source_bytes
    source = _load_source(raw)
    by_machine: dict[str, dict[str, list[dict[str, Any]]]] = defaultdict(
        lambda: defaultdict(list)
    )
    by_action: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for edge in source["edges"]:
        canonical = edge.get("canonical_action")
        machine = edge.get("machine")
        if canonical is None:
            continue
        if not isinstance(canonical, str) or not isinstance(machine, str):
            raise ValueError("source edge has an invalid action or machine reference")
        by_machine[machine][canonical].append(edge)
        by_action[canonical].append(edge)

    action_names = sorted(by_action)
    columns = 10
    rows = math.ceil(len(action_names) / columns)
    nodes: list[dict[str, Any]] = []
    for index, canonical in enumerate(action_names):
        evidence = _action_evidence(canonical, by_action[canonical])
        nodes.append({
            "id": f"action:{canonical}",
            "canonical_action": canonical,
            "stance": evidence["stance"],
            "validity_modes": evidence["validity_modes"],
            "carrier_machine_ids": sorted(
                machine for machine, actions in by_machine.items() if canonical in actions
            ),
            "source_edge_ids": evidence["source_edge_ids"],
            "position": {
                "x": round((index % columns - (columns - 1) / 2) * 5.25, 6),
                "y": round((index // columns - (rows - 1) / 2) * 5.25, 6),
                "z": 0,
            },
        })

    members_by_pair: dict[tuple[str, str], list[dict[str, Any]]] = defaultdict(list)
    for machine in sorted(by_machine):
        actions = sorted(by_machine[machine])
        for left_index, left in enumerate(actions):
            for right in actions[left_index + 1:]:
                action_rows = [
                    _action_evidence(left, by_machine[machine][left]),
                    _action_evidence(right, by_machine[machine][right]),
                ]
                stance_counts = Counter(row["stance"] for row in action_rows)
                members_by_pair[(left, right)].append({
                    "carrier_machine_id": machine,
                    "stances": sorted(stance_counts),
                    "stance_counts": {
                        stance: stance_counts[stance] for stance in sorted(stance_counts)
                    },
                    "actions": action_rows,
                })

    edges: list[dict[str, Any]] = []
    for left, right in sorted(members_by_pair):
        members = sorted(
            members_by_pair[(left, right)], key=lambda member: member["carrier_machine_id"]
        )
        stance_counts: Counter[str] = Counter(
            action["stance"] for member in members for action in member["actions"]
        )
        edges.append({
            "id": f"action-cooccurrence:{left}:{right}",
            "from": f"action:{left}",
            "to": f"action:{right}",
            "relation": "distinct_actions_in_same_machine",
            "stances": sorted(stance_counts),
            "stance_counts": {
                stance: stance_counts[stance] for stance in sorted(stance_counts)
            },
            "members": members,
        })

    support_count = sum(len(edge["members"]) for edge in edges)
    action_stance_counts: Counter[str] = Counter(node["stance"] for node in nodes)
    support_stance_counts: Counter[str] = Counter(
        stance
        for edge in edges
        for member in edge["members"]
        for stance in member["stances"]
    )
    validity_counts: Counter[str] = Counter(
        mode
        for edge in edges
        for member in edge["members"]
        for mode in {
            mode
            for action in member["actions"]
            for mode in action["validity_modes"]
        }
    )
    return {
        "schema": 1,
        "view": "action",
        "source_artifact": SOURCE_ARTIFACT,
        "source_schema": source["schema"],
        "source_sha256": hashlib.sha256(raw).hexdigest(),
        "meta": {
            "scope": "Distinct canonical action names that occur within the same machine.",
            "assertion": ACTION_ASSERTION,
            "layout": {
                "description": (
                    "Action nodes use a deterministic alphabetical grid. Its coordinates "
                    "are presentational and do not assign actions to authored rungs."
                ),
                "vertical_placement": "presentational",
            },
            "counts": {
                "nodes": len(nodes),
                "edges": len(edges),
                "members": support_count,
                "members_by_stance": {
                    stance: support_stance_counts.get(stance, 0)
                    for stance in ("conserving", "deforming", "neutral")
                },
                "member_validity_mode_occurrences": {
                    mode: validity_counts[mode] for mode in sorted(validity_counts)
                },
                "nodes_by_stance": {
                    stance: action_stance_counts.get(stance, 0)
                    for stance in ("conserving", "deforming", "neutral")
                },
                "mixed_stance_edges": sum(len(edge["stances"]) > 1 for edge in edges),
            },
        },
        "nodes": nodes,
        "edges": edges,
    }


def generate_ladder_graph(source_bytes: bytes | None = None) -> dict[str, Any]:
    raw = _source_bytes() if source_bytes is None else source_bytes
    source = _load_source(raw)
    machine_levels: dict[str, int] = {}
    for node in source["nodes"]:
        machine = f"{node['family']}/{node['kind']}"
        level = node.get("level")
        if not isinstance(level, int):
            raise ValueError(f"source node for {machine} has an invalid level")
        prior = machine_levels.setdefault(machine, level)
        if prior != level:
            raise ValueError(f"source graph assigns multiple levels to {machine}")
    source_edge_by_id = {edge["id"]: edge for edge in source["edges"]}

    accumulated: dict[
        tuple[int, int], dict[str, dict[str, set[str]]]
    ] = defaultdict(lambda: defaultdict(lambda: {"machines": set(), "edges": set()}))
    for borrow in source.get("borrows", []):
        canonical = borrow.get("canonical_action")
        if not isinstance(canonical, str):
            raise ValueError("source borrow has an invalid canonical action")
        for pair in borrow.get("pairs", []):
            machines = pair.get("machines", [])
            edge_groups = pair.get("edge_ids", [])
            if len(machines) != 2 or len(edge_groups) != 2:
                raise ValueError(f"source borrow pair for {canonical!r} is malformed")
            left_level, right_level = sorted(machine_levels[str(machine)] for machine in machines)
            row = accumulated[(left_level, right_level)][canonical]
            row["machines"].update(str(machine) for machine in machines)
            row["edges"].update(str(edge_id) for group in edge_groups for edge_id in group)

    edges: list[dict[str, Any]] = []
    for left_level, right_level in sorted(accumulated):
        members: list[dict[str, Any]] = []
        for canonical in sorted(accumulated[(left_level, right_level)]):
            row = accumulated[(left_level, right_level)][canonical]
            source_edges = sorted(
                (source_edge_by_id[edge_id] for edge_id in row["edges"]),
                key=lambda edge: edge["id"],
            )
            evidence = _action_evidence(canonical, source_edges)
            members.append({
                "canonical_action": canonical,
                "stance": evidence["stance"],
                "validity_modes": evidence["validity_modes"],
                "carrier_machine_ids": sorted(row["machines"]),
                "source_edge_ids": evidence["source_edge_ids"],
            })
        stance_counts: Counter[str] = Counter(member["stance"] for member in members)
        edges.append({
            "id": f"ladder-bundle:{left_level}:{right_level}",
            "from": f"level:{left_level}",
            "to": f"level:{right_level}",
            "relation": "authored_rung_shared_action",
            "stances": sorted(stance_counts),
            "stance_counts": {
                stance: stance_counts[stance] for stance in sorted(stance_counts)
            },
            "members": members,
        })

    ladder = source.get("meta", {}).get("level_ladder", [])
    nodes: list[dict[str, Any]] = []
    for row in ladder:
        level = row.get("level")
        families = row.get("families")
        if not isinstance(level, int) or not isinstance(families, list):
            raise ValueError("source graph has an invalid authored level ladder")
        angle = -math.pi / 2 + math.tau * level / max(1, len(ladder))
        nodes.append({
            "id": f"level:{level}",
            "level": level,
            "families": [str(family) for family in families],
            "position": {
                "x": round(9 * math.cos(angle), 6),
                "y": round(9 * math.sin(angle), 6),
                "z": level,
            },
        })

    members = [member for edge in edges for member in edge["members"]]
    stance_counts = Counter(member["stance"] for member in members)
    validity_counts = Counter(
        mode for member in members for mode in member["validity_modes"]
    )
    return {
        "schema": 1,
        "view": "ladder",
        "source_artifact": SOURCE_ARTIFACT,
        "source_schema": source["schema"],
        "source_sha256": hashlib.sha256(raw).hexdigest(),
        "meta": {
            "scope": "Shared canonical action names projected onto authored graph rungs.",
            "assertion": LADDER_ASSERTION,
            "layout": {
                "description": (
                    "Rung nodes use a deterministic ring; vertical placement follows "
                    "the authored level ladder in the full graph."
                ),
                "vertical_placement": "authored",
            },
            "level_ladder": ladder,
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
                "self_loop_edges": sum(edge["from"] == edge["to"] for edge in edges),
            },
        },
        "nodes": nodes,
        "edges": edges,
    }


GENERATORS = {
    "family": generate_family_graph,
    "action": generate_action_graph,
    "ladder": generate_ladder_graph,
}


def generate_json(
    source_bytes: bytes | None = None,
    view: str = "family",
    family: str | None = None,
) -> str:
    if view == "domain":
        if not family:
            raise ValueError("domain quotient requires a family")
        graph = generate_domain_graph(family, source_bytes)
    else:
        try:
            graph = GENERATORS[view](source_bytes)
        except KeyError as exc:
            raise ValueError(f"unknown quotient view: {view}") from exc
    return json.dumps(graph, indent=2, ensure_ascii=False) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--view", choices=(*OUTPUTS, "domain"))
    parser.add_argument("--family")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if args.output is not None and args.view is None:
        parser.error("--output requires --view")
    if args.view == "domain" and (not args.family or args.output is None):
        parser.error("--view domain requires --family and --output")
    if args.family is not None and args.view != "domain":
        parser.error("--family is accepted only with --view domain")
    views = [args.view] if args.view else list(OUTPUTS)
    source_bytes = _source_bytes()
    failed = False
    for view in views:
        output = args.output if args.output is not None else OUTPUTS[view]
        content = generate_json(source_bytes, view, args.family)
        if args.check:
            current = output.read_text(encoding="utf-8") if output.exists() else ""
            if current != content:
                print(f"stale {view} graph: {output.relative_to(ROOT)}", file=sys.stderr)
                failed = True
        else:
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_text(content, encoding="utf-8")
        counts = json.loads(content)["meta"]["counts"]
        print(
            f"{view} graph: {counts['nodes']} nodes, {counts['edges']} bundle edges, "
            f"{counts['members']} members"
        )
    if failed:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
