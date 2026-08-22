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
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(RESEARCH_SCRIPTS))

from build_graph_quotients import (  # noqa: E402
    ACTION_OUTPUT,
    LADDER_OUTPUT,
    OUTPUT,
    SOURCE,
    generate_json,
)
from scripts.counts_baseline_lib import baseline_value  # noqa: E402


EXPECTED_FAMILY_NODES = baseline_value("automata.quotient_family_nodes")


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


def action_evidence(edges: list[dict[str, Any]]) -> dict[str, Any]:
    ordered = sorted(edges, key=lambda edge: edge["id"])
    return {
        "stance": ordered[0]["stance"],
        "validity_modes": sorted({
            mode
            for edge in ordered
            if edge["stance"] == "deforming"
            for mode in edge.get("validity_modes", [])
        }),
        "source_edge_ids": [edge["id"] for edge in ordered],
    }


def action_projection(full: dict[str, Any]) -> dict[tuple[str, str], dict[str, dict[str, Any]]]:
    by_machine: dict[str, dict[str, list[dict[str, Any]]]] = defaultdict(
        lambda: defaultdict(list)
    )
    for edge in full["edges"]:
        canonical = edge.get("canonical_action")
        if canonical is not None:
            by_machine[edge["machine"]][canonical].append(edge)
    projection: dict[tuple[str, str], dict[str, dict[str, Any]]] = defaultdict(dict)
    for machine, actions in by_machine.items():
        names = sorted(actions)
        for index, left in enumerate(names):
            for right in names[index + 1:]:
                rows = []
                for canonical in (left, right):
                    evidence = action_evidence(actions[canonical])
                    rows.append({"canonical_action": canonical, **evidence})
                stance_counts = Counter(row["stance"] for row in rows)
                projection[(left, right)][machine] = {
                    "carrier_machine_id": machine,
                    "stances": sorted(stance_counts),
                    "stance_counts": {
                        stance: stance_counts[stance] for stance in sorted(stance_counts)
                    },
                    "actions": rows,
                }
    return projection


def ladder_projection(full: dict[str, Any]) -> dict[tuple[int, int], dict[str, dict[str, Any]]]:
    machine_levels: dict[str, int] = {}
    for node in full["nodes"]:
        machine_levels[f"{node['family']}/{node['kind']}"] = node["level"]
    source_edge_by_id = {edge["id"]: edge for edge in full["edges"]}
    accumulated: dict[tuple[int, int], dict[str, dict[str, set[str]]]] = defaultdict(
        lambda: defaultdict(lambda: {"machines": set(), "edges": set()})
    )
    for borrow in full["borrows"]:
        canonical = borrow["canonical_action"]
        for pair in borrow["pairs"]:
            levels = tuple(sorted(machine_levels[machine] for machine in pair["machines"]))
            row = accumulated[levels][canonical]
            row["machines"].update(pair["machines"])
            row["edges"].update(edge_id for group in pair["edge_ids"] for edge_id in group)
    projection: dict[tuple[int, int], dict[str, dict[str, Any]]] = defaultdict(dict)
    for levels, actions in accumulated.items():
        for canonical, row in actions.items():
            evidence = action_evidence([source_edge_by_id[edge_id] for edge_id in row["edges"]])
            projection[levels][canonical] = {
                "stance": evidence["stance"],
                "validity_modes": evidence["validity_modes"],
                "carrier_machine_ids": sorted(row["machines"]),
                "source_edge_ids": evidence["source_edge_ids"],
            }
    return projection


def check_artifact_bytes(
    view: str, output: Path, source_bytes: bytes, failures: list[str]
) -> dict[str, Any]:
    first = generate_json(source_bytes, view)
    second = generate_json(source_bytes, view)
    fail_if(first != second, f"{view} quotient rebuild is not deterministic", failures)
    if not output.exists():
        failures.append(f"missing generated artifact: {output.relative_to(ROOT)}")
    else:
        fail_if(
            output.read_text(encoding="utf-8") != first,
            f"stale generated artifact: {output.relative_to(ROOT)}",
            failures,
        )
    return json.loads(first)


def check_common(
    view: str,
    data: dict[str, Any],
    full: dict[str, Any],
    source_bytes: bytes,
    failures: list[str],
) -> None:
    nodes = data.get("nodes", [])
    edges = data.get("edges", [])
    fail_if(data.get("schema") != 1, f"{view} quotient schema is not 1", failures)
    fail_if(data.get("view") != view, f"{view} quotient has the wrong view", failures)
    fail_if(data.get("source_artifact") != SOURCE.relative_to(ROOT).as_posix(),
            f"{view} quotient source_artifact is wrong", failures)
    fail_if(data.get("source_schema") != full.get("schema"),
            f"{view} quotient source_schema disagrees with full graph", failures)
    fail_if(data.get("source_sha256") != hashlib.sha256(source_bytes).hexdigest(),
            f"{view} quotient source_sha256 disagrees with full graph bytes", failures)
    fail_if(len(nodes) != len({node.get("id") for node in nodes}),
            f"duplicate {view} node ids", failures)
    fail_if(len(edges) != len({edge.get("id") for edge in edges}),
            f"duplicate {view} edge ids", failures)
    node_ids = {node.get("id") for node in nodes}
    for edge in edges:
        fail_if(edge.get("from") not in node_ids or edge.get("to") not in node_ids,
                f"{view} edge {edge.get('id')} references a missing node", failures)
        member_stances: Counter[str] = Counter()
        for member in edge.get("members", []):
            if view == "action":
                for action in member.get("actions", []):
                    member_stances[str(action.get("stance"))] += 1
            else:
                member_stances[str(member.get("stance"))] += 1
        expected_stances = sorted(member_stances)
        expected_counts = {stance: member_stances[stance] for stance in expected_stances}
        fail_if(edge.get("stances") != expected_stances,
                f"{view} edge {edge.get('id')} stance union is wrong", failures)
        fail_if(edge.get("stance_counts") != expected_counts,
                f"{view} edge {edge.get('id')} stance counts are wrong", failures)


def check_action(data: dict[str, Any], full: dict[str, Any], failures: list[str]) -> None:
    nodes = data["nodes"]
    edges = data["edges"]
    expected = action_projection(full)
    expanded: dict[tuple[str, str], dict[str, dict[str, Any]]] = defaultdict(dict)
    source_edge_by_id = {edge["id"]: edge for edge in full["edges"]}
    for edge in edges:
        pair = tuple(sorted((edge["from"].removeprefix("action:"),
                             edge["to"].removeprefix("action:"))))
        fail_if(edge.get("relation") != "distinct_actions_in_same_machine",
                f"action edge {edge.get('id')} has a wrong relation", failures)
        machines = []
        for member in edge.get("members", []):
            machine = member.get("carrier_machine_id")
            machines.append(machine)
            actions = member.get("actions", [])
            fail_if([row.get("canonical_action") for row in actions] != list(pair),
                    f"action member {machine} has the wrong action pair", failures)
            for row in actions:
                canonical = row.get("canonical_action")
                source_ids = row.get("source_edge_ids", [])
                fail_if(any(source_edge_by_id.get(edge_id, {}).get("machine") != machine
                            for edge_id in source_ids),
                        f"action member {machine} names an edge from another machine", failures)
                fail_if(any(source_edge_by_id.get(edge_id, {}).get("canonical_action") != canonical
                            for edge_id in source_ids),
                        f"action member {machine} names an edge for another action", failures)
            expanded[pair][str(machine)] = member
        fail_if(machines != sorted(set(machines)),
                f"action edge {edge.get('id')} members are not sorted and unique", failures)
    fail_if(dict(expanded) != dict(expected),
            "expanding action edges does not reproduce machine action co-occurrence", failures)
    expected_actions = {edge["canonical_action"] for edge in full["edges"]
                        if edge.get("canonical_action") is not None}
    fail_if({node.get("canonical_action") for node in nodes} != expected_actions,
            "action nodes do not reproduce the full-graph action inventory", failures)
    by_action: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for source_edge in full["edges"]:
        canonical = source_edge.get("canonical_action")
        if canonical is not None:
            by_action[canonical].append(source_edge)
    for node in nodes:
        canonical = node.get("canonical_action")
        expected_evidence = action_evidence(by_action[str(canonical)])
        expected_machines = sorted({edge["machine"] for edge in by_action[str(canonical)]})
        fail_if(
            {
                "stance": node.get("stance"),
                "validity_modes": node.get("validity_modes"),
                "source_edge_ids": node.get("source_edge_ids"),
            } != expected_evidence,
            f"action node {canonical} does not retain exact ledger evidence",
            failures,
        )
        fail_if(node.get("carrier_machine_ids") != expected_machines,
                f"action node {canonical} has an incomplete carrier inventory", failures)
    fail_if(data["meta"]["counts"]["members"] != sum(len(rows) for rows in expected.values()),
            "action quotient support count is wrong", failures)


def check_ladder(data: dict[str, Any], full: dict[str, Any], failures: list[str]) -> None:
    expected = ladder_projection(full)
    expanded: dict[tuple[int, int], dict[str, dict[str, Any]]] = defaultdict(dict)
    for edge in data["edges"]:
        levels = tuple(sorted((int(edge["from"].removeprefix("level:")),
                               int(edge["to"].removeprefix("level:")))))
        fail_if(edge.get("relation") != "authored_rung_shared_action",
                f"ladder edge {edge.get('id')} has a wrong relation", failures)
        actions = []
        for member in edge.get("members", []):
            canonical = member.get("canonical_action")
            actions.append(canonical)
            expanded[levels][str(canonical)] = {
                "stance": member.get("stance"),
                "validity_modes": member.get("validity_modes"),
                "carrier_machine_ids": member.get("carrier_machine_ids"),
                "source_edge_ids": member.get("source_edge_ids"),
            }
        fail_if(actions != sorted(set(actions)),
                f"ladder edge {edge.get('id')} members are not sorted and unique", failures)
    fail_if(dict(expanded) != dict(expected),
            "expanding ladder bundles does not reproduce the borrow-level projection", failures)
    expected_ladder = full["meta"]["level_ladder"]
    fail_if(data["meta"].get("level_ladder") != expected_ladder,
            "ladder quotient does not retain the authored ladder", failures)
    fail_if([node.get("level") for node in data["nodes"]] !=
            [row["level"] for row in expected_ladder],
            "ladder nodes do not match the authored rung inventory", failures)


def check_domains(
    family_data: dict[str, Any],
    expected_family: dict[tuple[str, str], dict[str, dict[str, Any]]],
    full: dict[str, Any],
    source_bytes: bytes,
    failures: list[str],
) -> tuple[int, int]:
    families = sorted(node["family"] for node in family_data["nodes"])
    member_counts: list[int] = []
    for family in families:
        first = generate_json(source_bytes, "domain", family)
        second = generate_json(source_bytes, "domain", family)
        fail_if(first != second, f"domain ego {family} is not deterministic", failures)
        generated = json.loads(first)
        check_common("domain", generated, full, source_bytes, failures)
        incident = generated["edges"]
        expected_incident = [
            edge for edge in family_data["edges"]
            if edge["from"] == f"family:{family}" or edge["to"] == f"family:{family}"
        ]
        fail_if(generated["nodes"] != family_data["nodes"],
                f"domain ego {family} does not retain the family node inventory", failures)
        fail_if(incident != expected_incident,
                f"domain ego {family} differs from its family-artifact filter", failures)
        fail_if(generated["meta"].get("focal_family") != family,
                f"domain ego {family} lacks its focal-family tag", failures)
        expanded: dict[tuple[str, str], dict[str, dict[str, Any]]] = {}
        for edge in incident:
            pair = tuple(sorted((edge["from"].removeprefix("family:"),
                                 edge["to"].removeprefix("family:"))))
            expanded[pair] = {
                member["canonical_action"]: {
                    "stance": member["stance"],
                    "validity_modes": member["validity_modes"],
                    "carrier_machine_ids": member["carrier_machine_ids"],
                    "source_edge_ids": member["source_edge_ids"],
                }
                for member in edge["members"]
            }
        expected = {pair: members for pair, members in expected_family.items()
                    if family in pair}
        fail_if(expanded != expected,
                f"domain ego {family} does not reproduce its incident source projection", failures)
        fail_if(len(incident) != len(families) - 1,
                f"domain ego {family} does not have one edge per other family", failures)
        member_counts.append(sum(len(edge["members"]) for edge in incident))
    return min(member_counts), max(member_counts)


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
    action_data = check_artifact_bytes("action", ACTION_OUTPUT, source_bytes, failures)
    ladder_data = check_artifact_bytes("ladder", LADDER_OUTPUT, source_bytes, failures)
    check_common("action", action_data, full, source_bytes, failures)
    check_common("ladder", ladder_data, full, source_bytes, failures)
    check_action(action_data, full, failures)
    check_ladder(ladder_data, full, failures)
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
    fail_if(
        len(nodes) != EXPECTED_FAMILY_NODES,
        f"expected {EXPECTED_FAMILY_NODES} family nodes, got {len(nodes)}",
        failures,
    )
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
    domain_min_members, domain_max_members = check_domains(
        data, expected_projection, full, source_bytes, failures
    )

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
    print(
        f"PASS {EXPECTED_FAMILY_NODES} deterministic domain ego builder outputs "
        f"expand to incident family projections "
        f"({domain_min_members}..{domain_max_members} members)"
    )
    print(
        f"PASS action quotient: {len(action_data['nodes'])} nodes, "
        f"{len(action_data['edges'])} co-occurrence edges, "
        f"{action_data['meta']['counts']['members']} machine supports"
    )
    print("PASS every action edge expands to exact per-machine action and ledger evidence")
    print(
        f"PASS ladder quotient: {len(ladder_data['nodes'])} rungs, "
        f"{len(ladder_data['edges'])} bundles, "
        f"{ladder_data['meta']['counts']['members']} action members"
    )
    print("PASS every ladder bundle expands to the direct borrow-level projection")
    print("PASS action and ladder rebuilds are byte-identical and match the schema-2 source hash")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
