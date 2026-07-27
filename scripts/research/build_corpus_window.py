#!/usr/bin/env python3
"""Build the compact machine index in Prolog and plain text."""
from __future__ import annotations

import argparse
import collections
import re
import sys
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
TABLES = ROOT / "knowledge/strategies/transition_tables"
DISCOURSE = ROOT / "knowledge/discourse/commitment_automata.pl"
VOCABULARY = ROOT / "knowledge/strategies/action_vocabulary_map.pl"
GRAMMAR = ROOT / "knowledge/strategies/action_grammar.pl"
DEFAULT_OUTPUT = ROOT / "knowledge/index/corpus_window.pl"
DEFAULT_TEXT_OUTPUT = ROOT / "knowledge/index/corpus_window.txt"

# This is the authored source of truth for the structural block grouping.
# Generated Prolog makes the same assignment queryable; checks import this
# mapping rather than keeping another copy.
REGISTER_BLOCK_ROLES = {
    "comparison": "shell",
    "constitution": "shell",
    "delegation": "outside",
    "inscription": "closure",
    "iteration": "core",
    "normative": "closure",
    "operation": "core",
    "partition": "shell",
    "search": "shell",
    "transformation": "shell",
}
SHELL_REGISTERS = frozenset(
    register for register, role in REGISTER_BLOCK_ROLES.items() if role == "shell"
)
CORE_REGISTERS = frozenset(
    register for register, role in REGISTER_BLOCK_ROLES.items() if role == "core"
)
CLOSURE_REGISTERS = frozenset(
    register for register, role in REGISTER_BLOCK_ROLES.items() if role == "closure"
)

TUPLE_RE = re.compile(
    r"(?m)^automaton_tuple\((\w+),\s*(\w+),\s*states\(\[[^\]]*\]\),\s*"
    r"actions\(\[[^\]]*\]\),\s*start\((\w+)\),\s*accepting\(\[([^\]]*)\]\)\)"
)
TRANSITION_RE = re.compile(
    r"(?m)^automaton_transition\((\w+),\s*(\w+),\s*(\w+),\s*(\w+),\s*(\w+),\s*"
    r"provenance\((.*?)\)\)\."
)
MAP_RE = re.compile(r"(?m)^action_maps\((\w+), (\w+), (\w+), (\w+),")
REGISTER_RE = re.compile(
    r"(?m)^action_register\((\w+), genre\((\w+)\), register\((\w+)\), "
    r"stance\((\w+)\)\)"
)
ARC_RE = re.compile(r"(?m)^normative_arc\((\w+),")
GRAMMAR_RE = re.compile(
    r"(?m)^machine_grammar\((\w+), (\w+), (\w+), arc\((\w+)\),"
)


@dataclass(frozen=True)
class WindowRow:
    family: str
    signature: str
    arc: str
    shell: tuple[str, ...]
    core: tuple[str, ...]
    closure: tuple[str, ...]
    other: tuple[str, ...]


def _items(raw: str) -> tuple[str, ...]:
    return tuple(part.strip() for part in raw.split(",") if part.strip())


def read_machine_words(
    projection: dict[tuple[str, str, str], str],
    registers: dict[str, tuple[str, str, str]],
) -> dict[tuple[str, str], tuple[str, ...]]:
    starts: dict[tuple[str, str], str] = {}
    accepting: dict[tuple[str, str], set[str]] = {}
    edges: dict[tuple[str, str], set[tuple[str, str, str]]] = collections.defaultdict(set)

    paths = sorted(TABLES.glob("*.pl")) + [DISCOURSE]
    for path in paths:
        text = path.read_text(encoding="utf-8")
        for family, signature, start, accepting_raw in TUPLE_RE.findall(text):
            key = (family, signature)
            if key in starts:
                raise ValueError(f"duplicate automaton tuple for {family}/{signature}")
            starts[key] = start
            accepting[key] = set(_items(accepting_raw))
        for family, signature, source, action, target, _ in TRANSITION_RE.findall(text):
            edges[(family, signature)].add((source, action, target))

    if set(starts) != set(edges):
        missing_edges = sorted(set(starts) - set(edges))
        missing_tuples = sorted(set(edges) - set(starts))
        raise ValueError(
            f"machine declarations and transitions differ: "
            f"without transitions={missing_edges}, without tuples={missing_tuples}"
        )

    words: dict[tuple[str, str], tuple[str, ...]] = {}
    for key in sorted(edges):
        routes: dict[str, list[tuple[str, str]]] = collections.defaultdict(list)
        for source, local_action, target in sorted(edges[key]):
            canonical = projection.get((key[0], key[1], local_action), local_action)
            if canonical not in registers:
                raise ValueError(
                    f"{key[0]}/{key[1]} action {local_action} has no canonical register"
                )
            if canonical not in [action for action, _ in routes[source]]:
                routes[source].append((canonical, target))

        sequence: list[str] = []
        state = starts[key]
        seen = {state}
        while True:
            outgoing = routes.get(state, [])
            if not outgoing:
                if state not in accepting[key]:
                    raise ValueError(
                        f"{key[0]}/{key[1]} stops at non-accepting state {state}"
                    )
                break
            if len(outgoing) != 1:
                raise ValueError(
                    f"{key[0]}/{key[1]} has {len(outgoing)} canonical routes from {state}"
                )
            action, target = outgoing[0]
            sequence.append(action)
            if target in seen:
                break
            seen.add(target)
            state = target
        words[key] = tuple(sequence)
    return words


def build_data() -> tuple[
    list[WindowRow],
    dict[str, tuple[str, str, str]],
    collections.Counter[str],
]:
    vocabulary_text = VOCABULARY.read_text(encoding="utf-8")
    projection: dict[tuple[str, str, str], str] = {}
    for family, signature, local, canonical in MAP_RE.findall(vocabulary_text):
        key = (family, signature, local)
        if key in projection:
            raise ValueError(f"duplicate action mapping for {family}/{signature}/{local}")
        projection[key] = canonical

    registers: dict[str, tuple[str, str, str]] = {}
    for action, genre, register, stance in REGISTER_RE.findall(vocabulary_text):
        if action in registers:
            raise ValueError(f"duplicate action register for {action}")
        registers[action] = (genre, register, stance)

    grammar_text = GRAMMAR.read_text(encoding="utf-8")
    declared_arcs = set(ARC_RE.findall(grammar_text))
    machine_arcs: dict[tuple[str, str], str] = {}
    for _genre, family, signature, arc in GRAMMAR_RE.findall(grammar_text):
        key = (family, signature)
        if key in machine_arcs:
            raise ValueError(f"duplicate machine grammar for {family}/{signature}")
        if arc not in declared_arcs:
            raise ValueError(f"{family}/{signature} names undeclared arc {arc}")
        machine_arcs[key] = arc

    words = read_machine_words(projection, registers)
    if set(words) != set(machine_arcs):
        missing_arcs = sorted(set(words) - set(machine_arcs))
        invented_arcs = sorted(set(machine_arcs) - set(words))
        raise ValueError(
            f"machines and grammar rows differ: "
            f"without arcs={missing_arcs}, without machines={invented_arcs}"
        )

    rows: list[WindowRow] = []
    arc_counts: collections.Counter[str] = collections.Counter()
    for (family, signature), word in sorted(words.items()):
        groups: dict[str, list[str]] = {
            "shell": [],
            "core": [],
            "closure": [],
            "other": [],
        }
        for action in word:
            register = registers[action][1]
            if register in SHELL_REGISTERS:
                groups["shell"].append(action)
            elif register in CORE_REGISTERS:
                groups["core"].append(action)
            elif register in CLOSURE_REGISTERS:
                groups["closure"].append(action)
            else:
                groups["other"].append(action)
        arc = machine_arcs[(family, signature)]
        arc_counts[arc] += 1
        rows.append(
            WindowRow(
                family,
                signature,
                arc,
                tuple(groups["shell"]),
                tuple(groups["core"]),
                tuple(groups["closure"]),
                tuple(groups["other"]),
            )
        )
    return rows, dict(sorted(registers.items())), arc_counts


def _prolog_list(items: tuple[str, ...]) -> str:
    return "[" + ", ".join(items) + "]"


def render_prolog(
    rows: list[WindowRow],
    registers: dict[str, tuple[str, str, str]],
    arc_counts: collections.Counter[str],
) -> str:
    lines = [
        "% Generated by build_corpus_window.py. Hand edits will not survive the check.",
        "%",
        "% window_row/7 retains actions whose registers fall outside shell, core,",
        "% and closure. window_row/6 is the projection used by callers that need",
        "% the three named groups.",
        "% window_register_group/2 is the authored register grouping used by",
        "% the shell-core-closure census. outside is retained rather than",
        "% silently included in one of the three phases.",
        "",
    ]
    for register, role in sorted(REGISTER_BLOCK_ROLES.items()):
        lines.append(f"window_register_group({register}, {role}).")
    lines.append("")
    for action in sorted(registers):
        genre, register, stance = registers[action]
        lines.append(
            f"window_legend_action({action}, {genre}, {register}, {stance})."
        )
    lines.append("")
    for arc in sorted(arc_counts):
        lines.append(f"window_legend_arc({arc}, {arc_counts[arc]}).")
    lines.append("")
    for row in rows:
        lines.append(
            f"window_row({row.family}, {row.signature}, {row.arc}, "
            f"{_prolog_list(row.shell)}, {_prolog_list(row.core)}, "
            f"{_prolog_list(row.closure)}, {_prolog_list(row.other)})."
        )
    lines.extend(
        [
            "",
            "window_row(Family, Signature, Arc, Shell, Core, Closure) :-",
            "    window_row(Family, Signature, Arc, Shell, Core, Closure, _Other).",
            "",
        ]
    )
    return "\n".join(lines)


def _text_actions(items: tuple[str, ...]) -> str:
    return "+".join(items) if items else "none"


def render_text(
    rows: list[WindowRow],
    registers: dict[str, tuple[str, str, str]],
    arc_counts: collections.Counter[str],
) -> str:
    lines = ["LEGEND - actions (canonical, genre/register/stance)"]
    for action in sorted(registers):
        genre, register, stance = registers[action]
        lines.append(f"  {action}  {genre}/{register}/{stance}")
    lines.append("LEGEND - arcs (name, machines)")
    for arc in sorted(arc_counts):
        lines.append(f"  {arc}  {arc_counts[arc]}")
    lines.append(
        "MACHINES - family/signature arc=NAME shell=... core=... closure=... other=..."
    )
    for row in rows:
        lines.append(f"  {row.family}/{row.signature} arc={row.arc}")
        lines.append(
            f"    shell={_text_actions(row.shell)} "
            f"core={_text_actions(row.core)} "
            f"closure={_text_actions(row.closure)} "
            f"other={_text_actions(row.other)}"
        )
    rendered = "\n".join(lines) + "\n"
    rendered.encode("ascii")
    if any(line.rstrip() != line for line in rendered.splitlines()):
        raise ValueError("plain-text output contains trailing whitespace")
    return rendered


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--output-text", type=Path, default=DEFAULT_TEXT_OUTPUT)
    parser.add_argument(
        "--check",
        action="store_true",
        help="fail when the generated outputs differ from the checked-in files",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    rows, registers, arc_counts = build_data()
    prolog = render_prolog(rows, registers, arc_counts)
    text = render_text(rows, registers, arc_counts)
    if args.check:
        stale = [
            path
            for path, expected in ((args.output, prolog), (args.output_text, text))
            if not path.is_file() or path.read_text(encoding="ascii") != expected
        ]
        if stale:
            for path in stale:
                print(
                    f"corpus window is stale: {path}; run "
                    "python3 scripts/research/build_corpus_window.py",
                    file=sys.stderr,
                )
            return 1
        print(f"corpus window current: {args.output}; {args.output_text}")
        return 0
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output_text.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(prolog, encoding="ascii", newline="\n")
    args.output_text.write_text(text, encoding="ascii", newline="\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
