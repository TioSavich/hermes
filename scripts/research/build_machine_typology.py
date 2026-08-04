#!/usr/bin/env python3
"""Build a structural typology from the generated automaton tables.

The transition tables are parsed as data.  This generator does not load the
strategy modules or execute learner input.  Its classifications describe only
the graph recorded by the tables; authored machine-class claims live in
knowledge/strategies/machine_class_attestations.pl.
"""
from __future__ import annotations

import argparse
import re
import sys
from collections import defaultdict, deque
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
TABLES_DIR = ROOT / "knowledge/strategies/transition_tables"
OUTPUT = ROOT / "knowledge/strategies/machine_typology.pl"
ATOM = r"[a-z][a-z0-9_]*"

TUPLE = re.compile(
    rf"automaton_tuple\(\s*({ATOM})\s*,\s*({ATOM})\s*,\s*"
    rf"states\(\[([^]]*)\]\)\s*,\s*actions\(\[([^]]*)\]\)\s*,\s*"
    rf"start\(\s*({ATOM})\s*\)\s*,\s*accepting\(\[([^]]*)\]\)\s*\)\s*\."
)
TRANSITION = re.compile(
    rf"automaton_transition\(\s*({ATOM})\s*,\s*({ATOM})\s*,\s*"
    rf"({ATOM})\s*,\s*({ATOM})\s*,\s*({ATOM})\s*,\s*"
    r"provenance\((static\('(?:[^']|'')*'\)|observed\([a-z][a-z0-9_]*\))\)\s*\)\s*\."
)


@dataclass(frozen=True)
class Transition:
    before: str
    action: str
    after: str
    provenance: str

    @property
    def provenance_kind(self) -> str:
        return "static" if self.provenance.startswith("static(") else "observed"


@dataclass(frozen=True)
class Machine:
    family: str
    kind: str
    declared_states: tuple[str, ...]
    declared_actions: tuple[str, ...]
    start: str
    accepting: tuple[str, ...]
    transitions: tuple[Transition, ...]

    @property
    def states(self) -> tuple[str, ...]:
        """All states named by the row or its transitions, in stable order."""
        values = list(self.declared_states)
        for edge in self.transitions:
            values.extend((edge.before, edge.after))
        return stable_unique(values)

    @property
    def actions(self) -> tuple[str, ...]:
        return tuple(sorted({edge.action for edge in self.transitions}))

    @property
    def unique_edges(self) -> tuple[tuple[str, str, str], ...]:
        return tuple(sorted({(e.before, e.action, e.after) for e in self.transitions}))


@dataclass(frozen=True)
class Structure:
    machine: Machine
    structural_class: str
    branching_states: tuple[str, ...]
    loop_edges: tuple[tuple[str, str, str], ...]
    static_rows: int
    observed_rows: int


def atoms(body: str) -> tuple[str, ...]:
    return tuple(part.strip() for part in body.split(",") if part.strip())


def stable_unique(values: list[str] | tuple[str, ...]) -> tuple[str, ...]:
    return tuple(dict.fromkeys(values))


def parse_transition_tables(tables_dir: Path = TABLES_DIR) -> list[Machine]:
    tuples: dict[tuple[str, str], tuple[tuple[str, ...], tuple[str, ...], str, tuple[str, ...]]] = {}
    transitions: dict[tuple[str, str], list[Transition]] = defaultdict(list)
    for path in sorted(tables_dir.glob("*.pl")):
        text = path.read_text(encoding="utf-8")
        for match in TUPLE.finditer(text):
            family, kind, states, actions_body, start, accepting = match.groups()
            key = (family, kind)
            if key in tuples:
                raise ValueError(f"duplicate automaton_tuple for {family}/{kind}")
            tuples[key] = (atoms(states), atoms(actions_body), start, atoms(accepting))
        for match in TRANSITION.finditer(text):
            family, kind, before, action, after, provenance = match.groups()
            transitions[(family, kind)].append(
                Transition(before, action, after, provenance)
            )
    if not tuples:
        raise ValueError(f"no automaton_tuple rows found in {tables_dir}")
    orphaned = sorted(set(transitions) - set(tuples))
    if orphaned:
        raise ValueError(f"transition rows without tuples: {orphaned}")
    machines = []
    for (family, kind), (states, declared_actions, start, accepting) in sorted(tuples.items()):
        machines.append(
            Machine(
                family,
                kind,
                states,
                declared_actions,
                start,
                accepting,
                tuple(transitions.get((family, kind), ())),
            )
        )
    return machines


def reachable(start: str, adjacency: dict[str, set[str]]) -> set[str]:
    found = {start}
    queue = deque([start])
    while queue:
        current = queue.popleft()
        for nxt in sorted(adjacency.get(current, ())):
            if nxt not in found:
                found.add(nxt)
                queue.append(nxt)
    return found


def is_loop_edge(machine: Machine, candidate: tuple[str, str, str]) -> bool:
    """Whether the edge returns to a state already available on a start path.

    The candidate is removed while finding that path.  This makes the closing
    edge of a cycle a loop edge without labeling every forward edge in the
    cycle as a return.  A reachable self-loop is a loop by definition.
    """
    before, _action, after = candidate
    remaining = [edge for edge in machine.unique_edges if edge != candidate]
    adjacency: dict[str, set[str]] = defaultdict(set)
    for source, _label, target in remaining:
        adjacency[source].add(target)
    if after not in reachable(machine.start, adjacency):
        return False
    if before == after:
        return True
    return before in reachable(after, adjacency)


def structure(machine: Machine) -> Structure:
    outgoing: dict[str, set[tuple[str, str]]] = defaultdict(set)
    for before, action, after in machine.unique_edges:
        outgoing[before].add((action, after))
    branching = tuple(sorted(state for state, edges in outgoing.items() if len(edges) > 1))
    loops = tuple(edge for edge in machine.unique_edges if is_loop_edge(machine, edge))
    if branching and loops:
        label = "branching_looping"
    elif branching:
        label = "branching"
    elif loops:
        label = "looping"
    else:
        label = "linear_trace"
    return Structure(
        machine,
        label,
        branching,
        loops,
        sum(edge.provenance_kind == "static" for edge in machine.transitions),
        sum(edge.provenance_kind == "observed" for edge in machine.transitions),
    )


def generate_typology(tables_dir: Path = TABLES_DIR) -> str:
    rows = [structure(machine) for machine in parse_transition_tables(tables_dir)]
    lines = [
        "% Generated by scripts/research/build_machine_typology.py.",
        "% Structural classes are computed from transition-table graphs only.",
        "% They do not assert a computational class beyond what those rows witness.",
        ":- multifile machine_structure/8.",
        "",
    ]
    for row in rows:
        machine = row.machine
        lines.append(
            f"machine_structure({machine.family}, {machine.kind}, "
            f"class({row.structural_class}), states({len(machine.states)}), "
            f"actions({len(machine.actions)}), branching({len(row.branching_states)}), "
            f"loops({len(row.loop_edges)}), "
            f"rows(static({row.static_rows}), observed({row.observed_rows})))."
        )
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=OUTPUT)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    content = generate_typology()
    if args.check:
        current = args.output.read_text(encoding="utf-8") if args.output.exists() else ""
        if current != content:
            print(f"stale generated typology: {args.output}", file=sys.stderr)
            return 1
    else:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(content, encoding="utf-8")
    print(f"machine typology: {len(parse_transition_tables())} machines")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
