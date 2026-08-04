#!/usr/bin/env python3
"""Build the shared 3D graph of the computational automata corpus.

The JSON is the primary artifact.  It records per-machine states and unique
transitions, the authored pedagogical level assigned to each family, a
deterministic ring-and-sector layout, and an index of canonical actions carried
by more than one machine.  It does not infer prerequisites or shared states.
"""
from __future__ import annotations

import argparse
import itertools
import json
import math
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

from build_machine_typology import ROOT, Machine, parse_transition_tables


OUTPUT = ROOT / "docs/research/assets/automata/full_graph.json"
ACTION_MAP = ROOT / "knowledge/strategies/action_vocabulary_map.pl"
ACTION_GRAMMAR = ROOT / "knowledge/strategies/action_grammar.pl"
ATOM = r"[a-z][a-z0-9_]*"
MAP_RE = re.compile(
    rf"^action_maps\(({ATOM}), ({ATOM}), ({ATOM}), ({ATOM}),", re.MULTILINE
)
REGISTER_RE = re.compile(
    rf"^action_register\(({ATOM}), genre\(({ATOM})\), register\(({ATOM})\), "
    rf"stance\(({ATOM})\)\)\.",
    re.MULTILINE,
)
GRAMMAR_RE = re.compile(
    rf"machine_grammar\(computational, ({ATOM}), ({ATOM}), arc\([^)]*\),\s*"
    r"phrases\(\[[^\]]*\]\),\s*stances\(\[([^\]]*)\]\)\)\.",
    re.MULTILINE,
)

LEVEL_LADDER = (
    (0, ("counting",)),
    (1, ("addition", "subtraction")),
    (2, ("multiplication", "division")),
    (3, ("measurement", "geometry")),
    (4, ("fraction", "decimal", "integer")),
    (5, ("ratio", "probability", "statistics")),
    (6, ("algebraic",)),
    (7, ("calculus",)),
)
LEVEL_BY_FAMILY = {
    family: level for level, families in LEVEL_LADDER for family in families
}
LEVEL_NOTE = (
    "The level ladder is an authored pedagogical ordering, not a relation "
    "derived from the transition tables."
)
LAYOUT = {
    "machine_cell": 6.4,
    "first_band_radius": 6.4,
    "sector_margin_single": 0.04,
    "sector_margin_multiple": 0.14,
    "state_arc_spacing": 0.92,
    "minimum_state_ring_radius": 1.25,
}


def machine_id(machine: Machine) -> str:
    return f"{machine.family}/{machine.kind}"


def node_id(family: str, kind: str, state: str) -> str:
    return f"n:{family}:{kind}:{state}"


def formal_states(machine: Machine) -> tuple[str, ...]:
    return (
        machine.start,
        *(state for state in machine.states if state != machine.start),
    )


def state_ring_radius(count: int) -> float:
    return max(
        LAYOUT["minimum_state_ring_radius"],
        count * LAYOUT["state_arc_spacing"] / math.tau,
    )


def family_centers(
    count: int, family_index: int, family_count: int
) -> list[tuple[float, float]]:
    """Place machine centers in radial bands inside one angular sector."""
    sector = math.tau / family_count
    margin = (
        LAYOUT["sector_margin_multiple"]
        if family_count > 1
        else LAYOUT["sector_margin_single"]
    )
    start = -math.pi / 2 + family_index * sector + margin
    width = sector - 2 * margin
    centers: list[tuple[float, float]] = []
    row = 0
    while len(centers) < count:
        radius = LAYOUT["first_band_radius"] + row * LAYOUT["machine_cell"]
        capacity = max(1, int(radius * width / LAYOUT["machine_cell"]))
        take = min(capacity, count - len(centers))
        for slot in range(take):
            angle = start + width * (slot + 0.5) / take
            centers.append(
                (radius * math.cos(angle), radius * math.sin(angle))
            )
        row += 1
    return centers


def read_action_sources() -> tuple[
    dict[tuple[str, str, str], str],
    dict[str, tuple[str, str, str]],
    dict[tuple[str, str], tuple[str, ...]],
    int,
]:
    map_text = ACTION_MAP.read_text(encoding="utf-8")
    map_rows = MAP_RE.findall(map_text)
    mappings: dict[tuple[str, str, str], str] = {}
    for family, kind, local, canonical in map_rows:
        key = (family, kind, local)
        if key in mappings:
            raise ValueError(f"duplicate action_maps/7 row for {key!r}")
        mappings[key] = canonical
    registers = {
        canonical: (genre, register, stance)
        for canonical, genre, register, stance in REGISTER_RE.findall(map_text)
    }
    grammar = {
        (family, kind): tuple(
            part.strip() for part in body.split(",") if part.strip()
        )
        for family, kind, body in GRAMMAR_RE.findall(
            ACTION_GRAMMAR.read_text(encoding="utf-8")
        )
    }
    if len(mappings) != len(map_rows):
        raise ValueError("action_maps/7 rows did not form a unique mapping")
    return mappings, registers, grammar, len(map_rows)


def validate_source_scope(
    machines: list[Machine],
    mappings: dict[tuple[str, str, str], str],
    registers: dict[str, tuple[str, str, str]],
    grammar: dict[tuple[str, str], tuple[str, ...]],
    map_row_count: int,
) -> None:
    keys = {(machine.family, machine.kind) for machine in machines}
    missing_levels = sorted({machine.family for machine in machines} - LEVEL_BY_FAMILY.keys())
    if missing_levels:
        raise ValueError(f"authored level ladder lacks families: {missing_levels}")
    expected = {
        "machines": (len(machines), 222),
        "action_maps rows": (map_row_count, 1081),
        "local action names": (len({key[2] for key in mappings}), 839),
        "canonical actions": (len(registers), 122),
        "computational canonical actions": (
            sum(genre == "computational" for genre, _register, _stance in registers.values()),
            90,
        ),
        "discursive canonical actions": (
            sum(genre == "discursive" for genre, _register, _stance in registers.values()),
            32,
        ),
        "computational grammar rows": (len(grammar), 222),
    }
    drift = [
        f"{label}: expected {wanted}, got {observed}"
        for label, (observed, wanted) in expected.items()
        if observed != wanted
    ]
    if drift:
        raise ValueError("full-graph source scope drift: " + "; ".join(drift))
    extra_map_machines = sorted({key[:2] for key in mappings} - keys)
    if extra_map_machines:
        raise ValueError(f"mapping rows outside computational scope: {extra_map_machines}")
    missing_grammar = sorted(keys - set(grammar))
    extra_grammar = sorted(set(grammar) - keys)
    if missing_grammar or extra_grammar:
        raise ValueError(
            f"computational grammar scope mismatch: missing={missing_grammar}, "
            f"extra={extra_grammar}"
        )
    invalid_stances = sorted(
        (canonical, stance)
        for canonical, (_genre, _register, stance) in registers.items()
        if stance not in {"conserving", "deforming", "neutral"}
    )
    if invalid_stances:
        raise ValueError(f"invalid action stances: {invalid_stances}")


def validate_machine_grammar(
    machine: Machine,
    mappings: dict[tuple[str, str, str], str],
    registers: dict[str, tuple[str, str, str]],
    grammar: dict[tuple[str, str], tuple[str, ...]],
) -> None:
    """Rebuild the deterministic stance word checked by action_grammar/6."""
    routes: dict[str, list[tuple[str, str]]] = defaultdict(list)
    for source, local, target in machine.unique_edges:
        canonical = mappings.get((machine.family, machine.kind, local))
        route_action = canonical or local
        if route_action not in [action for action, _target in routes[source]]:
            routes[source].append((route_action, target))
    observed: list[str] = []
    state = machine.start
    seen = {state}
    while len(routes.get(state, ())) == 1:
        action, target = routes[state][0]
        stance = registers.get(action, ("computational", "", "neutral"))[2]
        observed.append(stance)
        if target in seen:
            break
        seen.add(target)
        state = target
    expected = grammar[(machine.family, machine.kind)]
    if tuple(observed) != expected:
        raise ValueError(
            f"action-grammar stance drift for {machine_id(machine)}: "
            f"builder {tuple(observed)!r}, grammar {expected!r}"
        )


def build_nodes(
    machines: list[Machine],
) -> tuple[list[dict[str, object]], dict[tuple[str, str, str], dict[str, object]]]:
    grouped: dict[int, dict[str, list[Machine]]] = defaultdict(lambda: defaultdict(list))
    for machine in machines:
        grouped[LEVEL_BY_FAMILY[machine.family]][machine.family].append(machine)
    nodes: list[dict[str, object]] = []
    by_key: dict[tuple[str, str, str], dict[str, object]] = {}
    for level in sorted(grouped):
        families = sorted(grouped[level])
        for family_index, family in enumerate(families):
            rows = sorted(grouped[level][family], key=lambda row: row.kind)
            centers = family_centers(len(rows), family_index, len(families))
            for machine, (center_x, center_y) in zip(rows, centers):
                ordered = formal_states(machine)
                radius = state_ring_radius(len(ordered))
                for formal_index, state in enumerate(ordered):
                    angle = -math.pi / 2 + formal_index / len(ordered) * math.tau
                    record: dict[str, object] = {
                        "id": node_id(machine.family, machine.kind, state),
                        "family": machine.family,
                        "kind": machine.kind,
                        "state": state,
                        "formal_index": formal_index,
                        "start": state == machine.start,
                        "accepting": state in machine.accepting,
                        "level": level,
                        "position": {
                            "x": round(center_x + math.cos(angle) * radius, 6),
                            "y": round(center_y + math.sin(angle) * radius, 6),
                            "z": level,
                        },
                    }
                    key = (machine.family, machine.kind, state)
                    if key in by_key:
                        raise ValueError(f"duplicate graph node: {key!r}")
                    nodes.append(record)
                    by_key[key] = record
    nodes.sort(key=lambda row: str(row["id"]))
    return nodes, by_key


def build_edges(
    machines: list[Machine],
    node_by_key: dict[tuple[str, str, str], dict[str, object]],
    mappings: dict[tuple[str, str, str], str],
    registers: dict[str, tuple[str, str, str]],
) -> list[dict[str, object]]:
    edges: list[dict[str, object]] = []
    edge_number = 0
    for machine in machines:
        provenance: dict[tuple[str, str, str], set[str]] = defaultdict(set)
        for transition in machine.transitions:
            provenance[(transition.before, transition.action, transition.after)].add(
                transition.provenance_kind
            )
        for source, local, target in machine.unique_edges:
            canonical = mappings.get((machine.family, machine.kind, local))
            stance = registers.get(canonical, ("computational", "", "neutral"))[2]
            source_key = (machine.family, machine.kind, source)
            target_key = (machine.family, machine.kind, target)
            if source_key not in node_by_key or target_key not in node_by_key:
                raise ValueError(
                    f"edge names a missing node in {machine_id(machine)}: "
                    f"{source}/{local}/{target}"
                )
            edges.append(
                {
                    "id": f"e{edge_number:04d}",
                    "machine": machine_id(machine),
                    "from": node_by_key[source_key]["id"],
                    "to": node_by_key[target_key]["id"],
                    "local_action": local,
                    "canonical_action": canonical,
                    "stance": stance,
                    "provenance_kinds": sorted(provenance[(source, local, target)]),
                }
            )
            edge_number += 1
    return edges


def build_borrows(edges: list[dict[str, object]]) -> list[dict[str, object]]:
    by_action: dict[str, dict[str, list[str]]] = defaultdict(lambda: defaultdict(list))
    family_by_machine: dict[str, str] = {}
    for edge in edges:
        canonical = edge["canonical_action"]
        if canonical is None:
            continue
        machine = str(edge["machine"])
        family_by_machine[machine] = machine.split("/", 1)[0]
        by_action[str(canonical)][machine].append(str(edge["id"]))
    borrows = []
    for canonical in sorted(by_action):
        machine_edges = by_action[canonical]
        if len(machine_edges) < 2:
            continue
        pairs = []
        for left, right in itertools.combinations(sorted(machine_edges), 2):
            pairs.append(
                {
                    "machines": [left, right],
                    "edge_ids": [machine_edges[left], machine_edges[right]],
                    "cross_family": family_by_machine[left] != family_by_machine[right],
                }
            )
        borrows.append(
            {
                "canonical_action": canonical,
                "edge_ids": sorted(
                    edge_id
                    for ids in machine_edges.values()
                    for edge_id in ids
                ),
                "pairs": pairs,
            }
        )
    return borrows


def generate_graph() -> dict[str, object]:
    machines = parse_transition_tables()
    mappings, registers, grammar, map_row_count = read_action_sources()
    validate_source_scope(machines, mappings, registers, grammar, map_row_count)
    for machine in machines:
        validate_machine_grammar(machine, mappings, registers, grammar)
    nodes, node_by_key = build_nodes(machines)
    edges = build_edges(machines, node_by_key, mappings, registers)
    borrows = build_borrows(edges)
    stance_counts = Counter(str(edge["stance"]) for edge in edges)
    unmapped_edges = [edge for edge in edges if edge["canonical_action"] is None]
    stance_absent_edges = [
        edge
        for edge in edges
        if edge["canonical_action"] is None
        or str(edge["canonical_action"]) not in registers
    ]
    borrow_pairs = [pair for borrow in borrows for pair in borrow["pairs"]]
    computational_actions = sorted(
        canonical
        for canonical, (genre, _register, _stance) in registers.items()
        if genre == "computational"
    )
    discursive_actions = sorted(
        canonical
        for canonical, (genre, _register, _stance) in registers.items()
        if genre == "discursive"
    )
    return {
        "schema": 1,
        "meta": {
            "scope": (
                "The graph records the 222 computational machines in the "
                "transition-table compendium; the 18 discursive machines are outside it."
            ),
            "level_note": LEVEL_NOTE,
            "level_ladder": [
                {"level": level, "families": list(families)}
                for level, families in LEVEL_LADDER
            ],
            "layout": {
                "description": (
                    "Each level uses family angular sectors; machines occupy radial "
                    "bands inside a sector; each machine's states form a local ring."
                ),
                "z_coordinate": "The position z value is the authored level number.",
                "parameters": LAYOUT,
            },
            "canonical_action_scope": {
                "computational": computational_actions,
                "discursive_outside_graph": discursive_actions,
            },
            "counts": {
                "machines": len(machines),
                "families": len({machine.family for machine in machines}),
                "nodes": len(nodes),
                "edges": len(edges),
                "borrows": len(borrows),
                "borrow_pairs": len(borrow_pairs),
                "cross_family_borrow_pairs": sum(
                    bool(pair["cross_family"]) for pair in borrow_pairs
                ),
                "action_map_rows": map_row_count,
                "distinct_local_action_names": len({key[2] for key in mappings}),
                "declared_canonical_actions": len(registers),
                "computational_canonical_actions": len(computational_actions),
                "discursive_canonical_actions": len(discursive_actions),
                "mapped_canonical_actions_used_by_edges": len(
                    {edge["canonical_action"] for edge in edges if edge["canonical_action"]}
                ),
                "unmapped_local_actions": len(
                    {str(edge["local_action"]) for edge in unmapped_edges}
                ),
                "unmapped_edges": len(unmapped_edges),
                "stance_absent_edges_defaulted_neutral": len(stance_absent_edges),
                "edges_by_stance": {
                    stance: stance_counts.get(stance, 0)
                    for stance in ("conserving", "deforming", "neutral")
                },
            },
            "generation_sources": [
                "knowledge/strategies/transition_tables/*.pl",
                "knowledge/strategies/action_vocabulary_map.pl",
                "knowledge/strategies/action_grammar.pl",
                "scripts/research/build_machine_typology.py",
                "scripts/research/build_full_graph_json.py",
            ],
        },
        "nodes": nodes,
        "edges": edges,
        "borrows": borrows,
    }


def generate_json() -> str:
    return json.dumps(generate_graph(), indent=2, ensure_ascii=False) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=OUTPUT)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    content = generate_json()
    if args.check:
        current = args.output.read_text(encoding="utf-8") if args.output.exists() else ""
        if current != content:
            print(f"stale generated full graph: {args.output.relative_to(ROOT)}", file=sys.stderr)
            return 1
    else:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(content, encoding="utf-8")
    counts = json.loads(content)["meta"]["counts"]
    print(
        "full graph: "
        f"{counts['machines']} machines, {counts['nodes']} nodes, "
        f"{counts['edges']} edges, {counts['borrows']} borrow actions, "
        f"{counts['borrow_pairs']} borrow pairs"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
