#!/usr/bin/env python3
"""Guard the task-119 defect class in the generated transition tables.

scripts/research/build_transition_tables.py reconstructs a fresh state chain
(``q_observed_1``, ``q_observed_2``, ...) whenever a bounded live observation
returns a different action sequence than the signature's static trace. That
reconstruction must still root at the signature's own declared start and
accepting atoms (the ``start(...)``/``accepting([...])`` in its
``automaton_tuple``) rather than a hardcoded literal — a hardcoded
``q_start`` silently disconnected the observed rows from the declared start
for three fraction comparison signatures whose declared start is ``q_init``
(task 119). Any consumer that walks the automaton from its tuple, rather
than reading facts in file order, would see an empty observed automaton.

This check has two parts:
  1. Rootedness — for every signature with observed transition rows, every
     state touched by those rows is reachable from the declared start atom.
  2. Determinism — rerunning the builder (``--check`` mode: rebuild in
     memory, compare against what is on disk) makes no changes, the fast
     form of the two-run byte comparison from the task-119 verification
     plan, covering every family including the fraction family task 119
     repaired.
"""
from __future__ import annotations

import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TABLES_DIR = ROOT / "knowledge/strategies/transition_tables"
BUILDER = ROOT / "scripts/research/build_transition_tables.py"

TUPLE = re.compile(
    r"automaton_tuple\(\s*([a-z][a-z0-9_]*)\s*,\s*([a-z][a-z0-9_]*)\s*,\s*"
    r"states\(\[[^\]]*\]\)\s*,\s*actions\(\[[^\]]*\]\)\s*,\s*"
    r"start\(\s*([a-z][a-z0-9_]*)\s*\)\s*,\s*accepting\(\[[^\]]*\]\)\s*\)\s*\."
)
OBSERVED_TRANSITION = re.compile(
    r"automaton_transition\(\s*([a-z][a-z0-9_]*)\s*,\s*([a-z][a-z0-9_]*)\s*,\s*"
    r"([a-z][a-z0-9_]*)\s*,\s*([a-z][a-z0-9_]*)\s*,\s*([a-z][a-z0-9_]*)\s*,\s*"
    r"provenance\(observed\(([a-z][a-z0-9_]*)\)\)\s*\)\s*\."
)


def _reachable(start: str, edges: dict[str, set[str]]) -> set[str]:
    seen = {start}
    frontier = [start]
    while frontier:
        node = frontier.pop()
        for nxt in edges.get(node, ()):
            if nxt not in seen:
                seen.add(nxt)
                frontier.append(nxt)
    return seen


def check_rootedness() -> tuple[list[str], int]:
    """Every observed-provenance transition set is reachable from the
    declared start atom of its own automaton_tuple."""
    failures: list[str] = []
    signature_count = 0
    for path in sorted(TABLES_DIR.glob("*.pl")):
        text = path.read_text(encoding="utf-8")
        starts: dict[tuple[str, str], str] = {
            (operation, kind): start for operation, kind, start in TUPLE.findall(text)
        }
        rows_by_signature_source: dict[tuple[str, str, str], list[tuple[str, str]]] = defaultdict(list)
        for operation, kind, before, _action, after, source in OBSERVED_TRANSITION.findall(text):
            rows_by_signature_source[(operation, kind, source)].append((before, after))
        for (operation, kind, source), edge_pairs in rows_by_signature_source.items():
            start = starts.get((operation, kind))
            if start is None:
                failures.append(
                    f"{path.name}: {operation}/{kind} has observed({source}) rows but no "
                    "automaton_tuple declaring its start state"
                )
                continue
            edges: dict[str, set[str]] = defaultdict(set)
            states: set[str] = set()
            for before, after in edge_pairs:
                edges[before].add(after)
                states.add(before)
                states.add(after)
            unreached = states - _reachable(start, edges)
            signature_count += 1
            if unreached:
                failures.append(
                    f"{path.name}: {operation}/{kind} observed({source}) rows unreachable "
                    f"from declared start {start!r}: {sorted(unreached)}"
                )
    if signature_count == 0:
        failures.append("no observed transition rows found under knowledge/strategies/transition_tables/")
    return failures, signature_count


def check_builder_determinism() -> list[str]:
    """The fast, sandbox-safe form of the two-run byte comparison: rebuild
    every family in memory and require it to match what is on disk
    byte-for-byte. Covers all families, including fraction (the family
    task 119 repaired)."""
    result = subprocess.run(
        [sys.executable, str(BUILDER), "--check"],
        cwd=ROOT, text=True, capture_output=True, timeout=180, check=False,
    )
    if result.returncode:
        return [
            "builder --check reported nondeterministic or stale output "
            f"(exit {result.returncode}): {result.stdout.strip()} {result.stderr.strip()}"
        ]
    return []


def main() -> int:
    rootedness_failures, signature_count = check_rootedness()
    determinism_failures = check_builder_determinism()
    failures = rootedness_failures + determinism_failures
    if failures:
        for failure in failures:
            print(failure, file=sys.stderr)
        return 1
    print(
        f"PASS transition tables: {signature_count} observed signature/source rows "
        "rooted at their declared start; builder rerun byte-identical"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
