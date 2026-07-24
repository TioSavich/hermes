#!/usr/bin/env python3
"""Analyze algebraic relations among execution-observed strategy automata.

The script uses only Python's standard library and the extracted Prolog
transition tables.  Full mode is intended for Big Red.  ``--smoke`` selects
three signatures and is the only mode intended for a laptop check.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from collections import Counter, defaultdict, deque
from dataclasses import dataclass
from itertools import combinations
from pathlib import Path
from typing import Iterable


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
DEFAULT_TABLES = ROOT / "knowledge/strategies/transition_tables"
DEFAULT_OUTPUT = ROOT / ".bigred-output/strategy-algebra"
PRESERVATION_POLICY = (
    "Pedagogically distinct strategies are preserved even when minimized "
    "structures coincide. A coincidence is reported as a finding, never a merge."
)
SMOKE_SIGNATURES = (
    "fraction/common_unit_fraction_comparison",
    "fraction/number_line_count_marks_not_intervals",
    "fraction/number_line_fraction_comparison",
)


@dataclass(frozen=True, order=True)
class Signature:
    operation: str
    kind: str

    @property
    def name(self) -> str:
        return f"{self.operation}/{self.kind}"


@dataclass(frozen=True, order=True)
class Edge:
    source: str
    action: str
    target: str


@dataclass
class Automaton:
    signature: Signature
    states: set[str]
    actions: set[str]
    start: str
    accepting: set[str]
    edges: set[Edge]


def split_top_level(text: str, delimiter: str = ",") -> list[str]:
    result: list[str] = []
    start = 0
    stack: list[str] = []
    quote: str | None = None
    escaped = False
    pairs = {"(": ")", "[": "]", "{": "}"}
    for index, char in enumerate(text):
        if quote:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
        elif char in {"'", '"'}:
            quote = char
        elif char in pairs:
            stack.append(pairs[char])
        elif stack and char == stack[-1]:
            stack.pop()
        elif not stack and char == delimiter:
            result.append(text[start:index].strip())
            start = index + 1
    tail = text[start:].strip()
    if tail:
        result.append(tail)
    return result


def iter_facts(text: str, functor: str) -> Iterable[str]:
    pattern = re.compile(rf"(?m)^[ \t]*{re.escape(functor)}\s*\(")
    for match in pattern.finditer(text):
        depth = 1
        quote: str | None = None
        escaped = False
        index = match.end()
        while index < len(text) and depth:
            char = text[index]
            if quote:
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == quote:
                    quote = None
            elif char in {"'", '"'}:
                quote = char
            elif char == "(":
                depth += 1
            elif char == ")":
                depth -= 1
            index += 1
        if depth:
            raise ValueError(f"unterminated {functor}/? fact")
        yield text[match.end() : index - 1].strip()


def unwrap(term: str, functor: str) -> str:
    value = term.strip()
    prefix = f"{functor}("
    if not value.startswith(prefix) or not value.endswith(")"):
        raise ValueError(f"expected {functor}/1, got {term!r}")
    return value[len(prefix) : -1].strip()


def parse_list(term: str) -> list[str]:
    value = term.strip()
    if not value.startswith("[") or not value.endswith("]"):
        raise ValueError(f"expected list, got {term!r}")
    body = value[1:-1].strip()
    return split_top_level(body) if body else []


def label_name(raw: str) -> str:
    value = raw.strip()
    if len(value) >= 2 and value[0] == value[-1] == "'":
        return value[1:-1].replace("\\'", "'")
    match = re.match(r"^([a-z][a-z0-9_]*)", value)
    if not match:
        raise ValueError(f"unsupported transition label {raw!r}")
    return match.group(1)


def read_observed_automata(directory: Path) -> list[Automaton]:
    tuples: dict[Signature, tuple[set[str], set[str], str, set[str]]] = {}
    observed_edges: dict[Signature, set[Edge]] = defaultdict(set)
    for path in sorted(directory.glob("*.pl")):
        text = path.read_text(encoding="utf-8")
        for body in iter_facts(text, "automaton_tuple"):
            fields = split_top_level(body)
            if len(fields) != 6:
                raise ValueError(f"{path}: expected automaton_tuple/6")
            signature = Signature(label_name(fields[0]), label_name(fields[1]))
            states = {
                label_name(value)
                for value in parse_list(unwrap(fields[2], "states"))
            }
            actions = {
                label_name(value)
                for value in parse_list(unwrap(fields[3], "actions"))
            }
            start = label_name(unwrap(fields[4], "start"))
            accepting = {
                label_name(value)
                for value in parse_list(unwrap(fields[5], "accepting"))
            }
            tuples[signature] = (states, actions, start, accepting)
        for body in iter_facts(text, "automaton_transition"):
            fields = split_top_level(body)
            if len(fields) != 6:
                raise ValueError(f"{path}: expected automaton_transition/6")
            if not fields[5].strip().startswith("provenance(observed("):
                continue
            signature = Signature(label_name(fields[0]), label_name(fields[1]))
            observed_edges[signature].add(
                Edge(
                    label_name(fields[2]),
                    label_name(fields[3]),
                    label_name(fields[4]),
                )
            )
    automata = []
    for signature in sorted(observed_edges):
        if signature not in tuples:
            raise ValueError(f"observed transitions lack tuple for {signature.name}")
        states, actions, start, accepting = tuples[signature]
        edges = observed_edges[signature]
        automata.append(
            Automaton(
                signature,
                states | {edge.source for edge in edges} | {edge.target for edge in edges},
                actions | {edge.action for edge in edges},
                start,
                accepting,
                edges,
            )
        )
    return automata


def outgoing(automaton: Automaton) -> dict[str, list[Edge]]:
    result: dict[str, list[Edge]] = defaultdict(list)
    for edge in sorted(automaton.edges):
        result[edge.source].append(edge)
    return result


def reachable_states(automaton: Automaton) -> set[str]:
    routes = outgoing(automaton)
    reached = {automaton.start}
    queue = deque([automaton.start])
    while queue:
        state = queue.popleft()
        for edge in routes.get(state, []):
            if edge.target not in reached:
                reached.add(edge.target)
                queue.append(edge.target)
    return reached


def assert_action_deterministic(automaton: Automaton) -> None:
    destinations: dict[tuple[str, str], set[str]] = defaultdict(set)
    for edge in automaton.edges:
        destinations[(edge.source, edge.action)].add(edge.target)
    conflicts = {
        key: sorted(values)
        for key, values in destinations.items()
        if len(values) > 1
    }
    if conflicts:
        raise ValueError(
            f"{automaton.signature.name} is nondeterministic by action: {conflicts}"
        )


def minimize(automaton: Automaton) -> Automaton:
    """Compute the finite labeled-transition bisimulation quotient."""
    assert_action_deterministic(automaton)
    reached = reachable_states(automaton)
    routes = outgoing(automaton)
    partitions: list[set[str]] = [
        group
        for group in (
            reached & automaton.accepting,
            reached - automaton.accepting,
        )
        if group
    ]
    while True:
        block_of = {
            state: block_index
            for block_index, block in enumerate(partitions)
            for state in block
        }
        refined: list[set[str]] = []
        for block in partitions:
            groups: dict[tuple[bool, tuple[tuple[str, int], ...]], set[str]] = defaultdict(set)
            for state in sorted(block):
                descriptor = (
                    state in automaton.accepting,
                    tuple(
                        sorted(
                            (edge.action, block_of[edge.target])
                            for edge in routes.get(state, [])
                            if edge.target in reached
                        )
                    ),
                )
                groups[descriptor].add(state)
            refined.extend(groups[key] for key in sorted(groups, key=repr))
        if {frozenset(block) for block in refined} == {
            frozenset(block) for block in partitions
        }:
            partitions = refined
            break
        partitions = refined
    block_of = {
        state: block_index
        for block_index, block in enumerate(partitions)
        for state in block
    }
    names = {index: f"m{index}" for index in range(len(partitions))}
    edges = {
        Edge(names[block_of[edge.source]], edge.action, names[block_of[edge.target]])
        for edge in automaton.edges
        if edge.source in reached and edge.target in reached
    }
    return Automaton(
        automaton.signature,
        set(names.values()),
        {edge.action for edge in edges},
        names[block_of[automaton.start]],
        {names[index] for index, block in enumerate(partitions) if block & automaton.accepting},
        edges,
    )


def canonical_structure(automaton: Automaton) -> dict[str, object]:
    """Canonicalize a rooted action-deterministic structure without state names."""
    assert_action_deterministic(automaton)
    routes = outgoing(automaton)
    ids = {automaton.start: 0}
    queue = deque([automaton.start])
    ordered_edges: list[tuple[int, str, int]] = []
    while queue:
        source = queue.popleft()
        for edge in sorted(routes.get(source, []), key=lambda item: item.action):
            if edge.target not in ids:
                ids[edge.target] = len(ids)
                queue.append(edge.target)
            ordered_edges.append((ids[source], edge.action, ids[edge.target]))
    return {
        "state_count": len(ids),
        "start": 0,
        "accepting": sorted(ids[state] for state in automaton.accepting if state in ids),
        "transitions": [list(row) for row in sorted(ordered_edges)],
    }


def structure_key(structure: dict[str, object]) -> str:
    return json.dumps(structure, sort_keys=True, separators=(",", ":"))


def automaton_record(original: Automaton, minimized: Automaton) -> dict[str, object]:
    return {
        "signature": original.signature.name,
        "original": {
            "reachable_state_count": len(reachable_states(original)),
            "transition_count": len(original.edges),
            "action_count": len({edge.action for edge in original.edges}),
        },
        "minimized": canonical_structure(minimized),
    }


def trace_fragments(automaton: Automaton, max_length: int) -> set[tuple[str, ...]]:
    """Enumerate bounded action subtraces beginning at every reachable state."""
    routes = outgoing(automaton)
    fragments: set[tuple[str, ...]] = set()
    for initial in sorted(reachable_states(automaton)):
        queue: deque[tuple[str, tuple[str, ...]]] = deque([(initial, ())])
        while queue:
            state, trace = queue.popleft()
            if len(trace) >= max_length:
                continue
            for edge in routes.get(state, []):
                extended = trace + (edge.action,)
                if len(extended) >= 2:
                    fragments.add(extended)
                queue.append((edge.target, extended))
    return fragments


def homomorphism(source: Automaton, target: Automaton) -> dict[str, str] | None:
    """Find the rooted action-preserving map forced by deterministic edges."""
    source_routes = outgoing(source)
    target_routes = {
        (edge.source, edge.action): edge.target for edge in target.edges
    }
    mapping = {source.start: target.start}
    queue = deque([source.start])
    while queue:
        source_state = queue.popleft()
        target_state = mapping[source_state]
        if (source_state in source.accepting) != (target_state in target.accepting):
            return None
        for edge in source_routes.get(source_state, []):
            target_destination = target_routes.get((target_state, edge.action))
            if target_destination is None:
                return None
            known = mapping.get(edge.target)
            if known is not None and known != target_destination:
                return None
            if known is None:
                mapping[edge.target] = target_destination
                queue.append(edge.target)
    if set(mapping) != reachable_states(source):
        return None
    return dict(sorted(mapping.items()))


def synchronous_product(
    left: Automaton, right: Automaton, max_states: int
) -> dict[str, object] | None:
    shared_domain = sorted(left.actions & right.actions)
    if not shared_domain:
        return None
    left_routes = outgoing(left)
    right_routes = outgoing(right)
    start = (left.start, right.start)
    ids = {start: 0}
    queue = deque([start])
    edges: list[tuple[int, str, int]] = []
    while queue:
        left_state, right_state = queue.popleft()
        left_by_action = {edge.action: edge.target for edge in left_routes.get(left_state, [])}
        right_by_action = {
            edge.action: edge.target for edge in right_routes.get(right_state, [])
        }
        for action in sorted(left_by_action.keys() & right_by_action.keys()):
            destination = (left_by_action[action], right_by_action[action])
            if destination not in ids:
                if len(ids) >= max_states:
                    return {
                        "status": "omitted-over-limit",
                        "max_states": max_states,
                    }
                ids[destination] = len(ids)
                queue.append(destination)
            edges.append((ids[(left_state, right_state)], action, ids[destination]))
    accepting = sorted(
        identifier
        for (left_state, right_state), identifier in ids.items()
        if left_state in left.accepting and right_state in right.accepting
    )
    return {
        "status": "constructed",
        "state_count": len(ids),
        "start": 0,
        "accepting": accepting,
        "shared_action_domain": shared_domain,
        "deadlocked_at_start": not edges,
        "transitions": [list(row) for row in sorted(edges)],
    }


def coincidence_classes(
    automata: list[Automaton],
) -> list[dict[str, object]]:
    groups: dict[str, list[str]] = defaultdict(list)
    structures: dict[str, dict[str, object]] = {}
    for automaton in automata:
        structure = canonical_structure(automaton)
        key = structure_key(structure)
        groups[key].append(automaton.signature.name)
        structures[key] = structure
    return [
        {
            "finding_only": True,
            "signatures": sorted(signatures),
            "minimized_structure": structures[key],
        }
        for key, signatures in sorted(groups.items(), key=lambda item: item[1])
        if len(signatures) > 1
    ]


def pairwise_analysis(
    automata: list[Automaton],
    max_subtrace: int,
    max_shared_per_pair: int,
    max_product_states: int,
) -> tuple[list[dict[str, object]], list[dict[str, object]], list[dict[str, object]]]:
    fragments = {
        automaton.signature: trace_fragments(automaton, max_subtrace)
        for automaton in automata
    }
    pair_rows: list[dict[str, object]] = []
    homomorphisms: list[dict[str, object]] = []
    products: list[dict[str, object]] = []
    for left, right in combinations(automata, 2):
        shared = sorted(
            fragments[left.signature] & fragments[right.signature],
            key=lambda trace: (-len(trace), trace),
        )
        left_to_right = homomorphism(left, right)
        right_to_left = homomorphism(right, left)
        homomorphism_refs = []
        for source, target, mapping in (
            (left, right, left_to_right),
            (right, left, right_to_left),
        ):
            if mapping is None:
                continue
            reference = len(homomorphisms)
            homomorphisms.append(
                {
                    "source": source.signature.name,
                    "target": target.signature.name,
                    "mapping": mapping,
                    "finding_only": True,
                }
            )
            homomorphism_refs.append(reference)
        product = synchronous_product(left, right, max_product_states)
        product_ref = None
        if product is not None:
            product_ref = len(products)
            products.append(
                {
                    "left": left.signature.name,
                    "right": right.signature.name,
                    "finding_only": True,
                    **product,
                }
            )
        pair_rows.append(
            {
                "left": left.signature.name,
                "right": right.signature.name,
                "shared_action_count": len(left.actions & right.actions),
                "shared_subtrace_count": len(shared),
                "shared_subtraces": [
                    list(trace) for trace in shared[:max_shared_per_pair]
                ],
                "shared_subtraces_truncated": len(shared) > max_shared_per_pair,
                "homomorphism_refs": homomorphism_refs,
                "product_ref": product_ref,
            }
        )
    return pair_rows, homomorphisms, products


def render_summary(result: dict[str, object]) -> str:
    scope = result["scope"]
    findings = result["findings"]
    assert isinstance(scope, dict) and isinstance(findings, dict)
    return "\n".join(
        [
            "# Strategy algebra analysis",
            "",
            PRESERVATION_POLICY,
            "",
            f"- Mode: `{scope['mode']}`",
            f"- Signatures: {scope['signature_count']}",
            f"- Pairwise comparisons: {scope['pairwise_comparison_count']}",
            f"- Structural-coincidence classes: {findings['coincidence_class_count']}",
            f"- Candidate homomorphisms: {findings['candidate_homomorphism_count']}",
            f"- Small products: {findings['product_count']}",
            f"- Elapsed seconds: {result['runtime']['elapsed_seconds']}",
            "",
        ]
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tables", type=Path, default=DEFAULT_TABLES)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument(
        "--smoke",
        action="store_true",
        help="analyze exactly three sorted execution-observed signatures",
    )
    parser.add_argument("--max-subtrace", type=int, default=6)
    parser.add_argument("--max-shared-per-pair", type=int, default=20)
    parser.add_argument("--max-product-states", type=int, default=100)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.max_subtrace < 2:
        raise SystemExit("--max-subtrace must be at least 2")
    if args.max_shared_per_pair < 1 or args.max_product_states < 1:
        raise SystemExit("pair and product bounds must be positive")
    started = time.monotonic()
    observed = read_observed_automata(args.tables.resolve())
    if len(observed) != 69:
        raise SystemExit(
            f"expected 69 execution-observed signatures, found {len(observed)}"
        )
    if args.smoke:
        by_name = {automaton.signature.name: automaton for automaton in observed}
        missing_smoke = sorted(set(SMOKE_SIGNATURES) - set(by_name))
        if missing_smoke:
            raise SystemExit(f"--smoke signatures missing: {missing_smoke}")
        selected = [by_name[name] for name in SMOKE_SIGNATURES]
    else:
        selected = observed
    if args.smoke and len(selected) != 3:
        raise SystemExit("--smoke requires at least three observed signatures")
    minimized = [minimize(automaton) for automaton in selected]
    coincidences = coincidence_classes(minimized)
    pairs, homomorphisms, products = pairwise_analysis(
        minimized,
        args.max_subtrace,
        args.max_shared_per_pair,
        args.max_product_states,
    )
    result = {
        "schema_version": 1,
        "preservation_policy": PRESERVATION_POLICY,
        "scope": {
            "mode": "smoke" if args.smoke else "full",
            "source_table_directory": str(args.tables.resolve()),
            "execution_observed_signature_count": len(observed),
            "signature_count": len(selected),
            "signatures": [automaton.signature.name for automaton in selected],
            "pairwise_comparison_count": len(pairs),
            "expected_pairwise_formula": f"{len(selected)}*{len(selected) - 1}/2",
            "bounds": {
                "max_subtrace": args.max_subtrace,
                "max_shared_per_pair": args.max_shared_per_pair,
                "max_product_states": args.max_product_states,
            },
        },
        "minimized_automata": [
            automaton_record(original, reduced)
            for original, reduced in zip(selected, minimized, strict=True)
        ],
        "structural_coincidence_classes": coincidences,
        "pairwise": pairs,
        "candidate_homomorphisms": homomorphisms,
        "products": products,
        "findings": {
            "coincidence_class_count": len(coincidences),
            "candidate_homomorphism_count": len(homomorphisms),
            "product_count": len(products),
        },
        "runtime": {
            "elapsed_seconds": round(time.monotonic() - started, 6),
            "python": sys.version.split()[0],
        },
    }
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output / "strategy_algebra.json").write_text(
        json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    (args.output / "summary.md").write_text(
        render_summary(result), encoding="utf-8"
    )
    print(
        "STRATEGY_ALGEBRA_COMPLETE "
        f"mode={result['scope']['mode']} "
        f"signatures={len(selected)} pairs={len(pairs)} "
        f"output={args.output}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
