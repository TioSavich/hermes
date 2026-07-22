#!/usr/bin/env python3
"""Build evidence-bearing transition tables from Hermes action automata.

The source registry is deliberately parsed rather than loaded: this builder
records source locations and does not execute arbitrary learner inputs.  The
action-pair trace lists provide the static transition sequence.  Comparison
machines retain their authored q_-state labels from ``hist/2`` traces.
"""

from __future__ import annotations

import argparse
import re
import shutil
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
REGISTRY = ROOT / "knowledge/strategies/math/action_automata_registry.pl"
PAIR_DIR = ROOT / "knowledge/strategies/math"
OUT_DIR = ROOT / "knowledge/strategies/transition_tables"

SIGNATURE = re.compile(
    r"action_automaton_signature\(\s*([a-z][a-z0-9_]*)\s*,\s*"
    r"([a-z][a-z0-9_]*)\s*,",
    re.MULTILINE,
)
RUNNER = re.compile(
    r"^\s*(run_[a-z0-9_]+)\(\s*([a-z][a-z0-9_]*)\s*,", re.MULTILINE
)
ELABORATES = re.compile(r"elaborates\((smr_[a-z0-9_]+):(run_[a-z0-9_]+)/")
HIST = re.compile(r"hist\((q_[a-z0-9_]+)\s*,\s*([a-z][a-z0-9_]*)")


@dataclass(frozen=True)
class Table:
    operation: str
    kind: str
    states: tuple[str, ...]
    actions: tuple[str, ...]
    transitions: tuple[tuple[str, str, str, str], ...]
    source: str


def line_at(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def balanced_list(text: str, start: int) -> tuple[str, int] | None:
    """Return the bracketed list beginning at start, respecting quoted atoms."""
    if start >= len(text) or text[start] != "[":
        return None
    depth, quote = 0, False
    for pos in range(start, len(text)):
        char = text[pos]
        if char == "'":
            quote = not quote
        elif not quote and char == "[":
            depth += 1
        elif not quote and char == "]":
            depth -= 1
            if depth == 0:
                return text[start + 1 : pos], pos + 1
    return None


def top_level_terms(body: str) -> list[str]:
    parts: list[str] = []
    start = 0
    stack: list[str] = []
    quote = False
    pairs = {"(": ")", "[": "]", "{": "}"}
    for pos, char in enumerate(body):
        if char == "'":
            quote = not quote
        elif not quote and char in pairs:
            stack.append(pairs[char])
        elif not quote and stack and char == stack[-1]:
            stack.pop()
        elif not quote and not stack and char == ",":
            parts.append(body[start:pos].strip())
            start = pos + 1
    tail = body[start:].strip()
    return parts + ([tail] if tail else [])


def functor(term: str) -> str | None:
    match = re.match(r"\s*([a-z][a-z0-9_]*)", term)
    return match.group(1) if match else None


def table_from_trace(operation: str, kind: str, body: str, source: str) -> Table | None:
    labels = [label for label in map(functor, top_level_terms(body)) if label]
    if not labels:
        return None
    states = tuple(["q_start", *(f"q_step_{number}" for number in range(1, len(labels))), "q_accept"])
    transitions = tuple(
        (states[index], label, states[index + 1], source)
        for index, label in enumerate(labels)
    )
    return Table(operation, kind, states, tuple(labels), transitions, source)


def table_from_history(operation: str, kind: str, body: str, source: str) -> Table | None:
    entries = HIST.findall(body)
    ordered: list[tuple[str, str]] = []
    for entry in entries:
        if entry not in ordered:
            ordered.append(entry)
    if len(ordered) < 2:
        return None
    states = tuple(state for state, _ in ordered)
    transitions = tuple(
        (states[index], action, states[index + 1], source)
        for index, (_, action) in enumerate(ordered[:-1])
    )
    return Table(operation, kind, states, tuple(action for _, action in ordered[:-1]), transitions, source)


def source_clauses(path: Path) -> dict[str, tuple[Path, str, int, str, str | None]]:
    """Index static trace lists by strategy kind in one action-pair source."""
    text = path.read_text(encoding="utf-8")
    matches = list(RUNNER.finditer(text))
    found: dict[str, tuple[Path, str, int, str, str | None]] = {}
    for index, match in enumerate(matches):
        end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
        clause = text[match.start() : end]
        trace_match = re.search(r"\bTrace\s*=\s*\[", clause)
        trace = None
        if trace_match:
            list_start = match.start() + trace_match.end() - 1
            trace = balanced_list(text, list_start)
        elaborates = ELABORATES.search(clause)
        found[match.group(2)] = (path,
            text,
            match.start(),
            trace[0] if trace else "",
            f"{elaborates.group(1)}:{elaborates.group(2)}" if elaborates else None,
        )
    return found


def comparison_history(module: str, predicate: str) -> tuple[str, int, str] | None:
    path = PAIR_DIR / f"{module}.pl"
    if not path.exists():
        return None
    text = path.read_text(encoding="utf-8")
    match = re.search(rf"^\s*{re.escape(predicate)}\(", text, re.MULTILINE)
    if not match:
        return None
    # Stop at the next exported run predicate. This keeps q-state collection
    # local to the requested comparison routine even when it assembles history
    # through several list fragments.
    next_match = re.search(r"^\s*run_[a-z0-9_]+\(", text[match.end() :], re.MULTILINE)
    end = match.end() + next_match.start() if next_match else len(text)
    return text, match.start(), text[match.start() : end]


def prolog_atom(value: str) -> str:
    return value if re.fullmatch(r"[a-z][a-z0-9_]*", value) else repr(value)


def render_table(table: Table) -> str:
    states = ", ".join(prolog_atom(state) for state in table.states)
    actions = ", ".join(prolog_atom(action) for action in table.actions)
    lines = [
        f"automaton_tuple({table.operation}, {table.kind}, states([{states}]), "
        f"actions([{actions}]), start({table.states[0]}), accepting([{table.states[-1]}]))."
    ]
    for before, action, after, source in table.transitions:
        lines.append(
            f"automaton_transition({table.operation}, {table.kind}, {before}, {action}, {after}, "
            f"provenance(static('{source}')))."
        )
    return "\n".join(lines)


def render_tuple(table: Table) -> str:
    states = ", ".join(prolog_atom(state) for state in table.states)
    actions = ", ".join(prolog_atom(action) for action in table.actions)
    return (
        f"automaton_tuple({table.operation}, {table.kind}, states([{states}]), "
        f"actions([{actions}]), start({table.states[0]}), accepting([{table.states[-1]}]))."
    )


def render_transitions(table: Table) -> str:
    return "\n".join(
        f"automaton_transition({table.operation}, {table.kind}, {before}, {action}, {after}, "
        f"provenance(static('{source}')))."
        for before, action, after, source in table.transitions
    )


def build() -> tuple[list[Table], list[tuple[str, str, str]], Counter[str]]:
    signatures = SIGNATURE.findall(REGISTRY.read_text(encoding="utf-8"))
    clauses: dict[str, tuple[Path, str, int, str, str | None]] = {}
    for path in sorted(PAIR_DIR.glob("*_action_pairs.pl")):
        clauses.update(source_clauses(path))

    tables: list[Table] = []
    skipped: list[tuple[str, str, str]] = []
    routes: Counter[str] = Counter()
    for operation, kind in signatures:
        row = clauses.get(kind)
        if not row:
            skipped.append((operation, kind, "no static action-pair clause"))
            continue
        source_path, text, offset, trace, elaboration = row
        source = f"{source_path.relative_to(ROOT)}:{line_at(text, offset)}"
        table = table_from_trace(operation, kind, trace, source) if trace else None
        if table:
            tables.append(table)
            routes[operation] += 1
            continue
        if elaboration:
            module, predicate = elaboration.split(":", 1)
            history = comparison_history(module, predicate)
            if history:
                history_text, history_offset, body = history
                history_source = f"{(PAIR_DIR / (module + '.pl')).relative_to(ROOT)}:{line_at(history_text, history_offset)}"
                table = table_from_history(operation, kind, body, history_source)
        if table:
            tables.append(table)
            routes[operation] += 1
        else:
            reason = "trace is delegated without a statically readable q-state history" if elaboration else "no static Trace list"
            skipped.append((operation, kind, reason))
    return tables, skipped, routes


def write(tables: list[Table]) -> None:
    if OUT_DIR.exists():
        shutil.rmtree(OUT_DIR)
    OUT_DIR.mkdir(parents=True)
    by_operation: dict[str, list[Table]] = defaultdict(list)
    for table in tables:
        by_operation[table.operation].append(table)
    for operation, rows in sorted(by_operation.items()):
        header = (
            f"% Generated by scripts/research/build_transition_tables.py.\n"
            f"% Static extraction only; each transition retains its source location.\n"
            ":- multifile automaton_tuple/6.\n"
            ":- multifile automaton_transition/6.\n\n"
        )
        ordered = sorted(rows, key=lambda row: row.kind)
        content = (
            header
            + "\n".join(render_tuple(row) for row in ordered)
            + "\n\n"
            + "\n\n".join(render_transitions(row) for row in ordered)
            + "\n"
        )
        (OUT_DIR / f"{operation}.pl").write_text(content, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail if generated facts are not current")
    args = parser.parse_args()
    tables, skipped, routes = build()
    if args.check:
        before = {path.name: path.read_text(encoding="utf-8") for path in OUT_DIR.glob("*.pl")} if OUT_DIR.exists() else {}
        write(tables)
        after = {path.name: path.read_text(encoding="utf-8") for path in OUT_DIR.glob("*.pl")}
        if before != after:
            print("transition tables were regenerated; rerun without --check and inspect the diff")
            return 1
    else:
        write(tables)
    print(f"extracted={len(tables)} skipped={len(skipped)}")
    for operation in sorted(set(routes) | {operation for operation, _, _ in skipped}):
        total = sum(1 for op, _ in SIGNATURE.findall(REGISTRY.read_text(encoding='utf-8')) if op == operation)
        print(f"{operation}: {routes[operation]}/{total}")
    for operation, kind, reason in skipped:
        print(f"SKIPPED {operation}/{kind}: {reason}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
