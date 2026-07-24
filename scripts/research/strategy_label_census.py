#!/usr/bin/env python3
"""Inventory labels in the extracted strategy transition tables.

The census is read-only with respect to ``knowledge/strategies``.  Its JSON
output includes a machine-readable, review-pending normalization proposal;
it never rewrites an authored or generated transition table.
"""

from __future__ import annotations

import argparse
import csv
import io
import json
import re
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from difflib import SequenceMatcher
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_REGISTRY = ROOT / "knowledge/strategies/math/action_automata_registry.pl"
DEFAULT_TABLES = ROOT / "knowledge/strategies/transition_tables"
ATOM = re.compile(r"^[a-z][a-z0-9_]*$")


@dataclass(frozen=True, order=True)
class Signature:
    operation: str
    kind: str

    @property
    def name(self) -> str:
        return f"{self.operation}/{self.kind}"


@dataclass(frozen=True)
class Term:
    raw: str
    label: str
    arity: int
    shape: str


@dataclass
class Automaton:
    signature: Signature
    states: list[Term]
    actions: list[Term]
    start: str
    accepting: set[str]
    transitions: list[tuple[Term, Term, Term]]


def split_top_level(text: str, delimiter: str = ",") -> list[str]:
    """Split Prolog-ish terms without treating nested commas as separators."""
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
    """Yield the argument body of each requested Prolog fact."""
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
    prefix = f"{functor}("
    value = term.strip()
    if not value.startswith(prefix) or not value.endswith(")"):
        raise ValueError(f"expected {functor}/1, got {term!r}")
    return value[len(prefix) : -1].strip()


def parse_list(term: str) -> list[str]:
    value = term.strip()
    if not value.startswith("[") or not value.endswith("]"):
        raise ValueError(f"expected list, got {term!r}")
    body = value[1:-1].strip()
    return split_top_level(body) if body else []


def atom_name(raw: str) -> str:
    value = raw.strip()
    if len(value) >= 2 and value[0] == value[-1] == "'":
        return value[1:-1].replace("\\'", "'")
    match = re.match(r"^([a-z][a-z0-9_]*)", value)
    if not match:
        raise ValueError(f"unsupported label term {raw!r}")
    return match.group(1)


def term_info(raw: str) -> Term:
    value = raw.strip()
    name = atom_name(value)
    suffix = value[len(name) :].lstrip() if value.startswith(name) else ""
    if suffix.startswith("(") and suffix.endswith(")"):
        arguments = split_top_level(suffix[1:-1])
        shapes = ",".join(term_shape(argument) for argument in arguments)
        return Term(value, name, len(arguments), f"{name}({shapes})")
    return Term(value, name, 0, "atom")


def term_shape(raw: str) -> str:
    value = raw.strip()
    if not value:
        return "empty"
    if re.fullmatch(r"-?\d+(?:\.\d+)?", value):
        return "number"
    if value[0:1] in {"'", '"'}:
        return "quoted"
    if value.startswith("[") and value.endswith("]"):
        items = parse_list(value)
        return f"list[{','.join(term_shape(item) for item in items)}]"
    try:
        term = term_info(value)
    except ValueError:
        return "opaque"
    return term.shape if term.arity else "atom"


def read_registry(path: Path) -> list[Signature]:
    signatures: list[Signature] = []
    for body in iter_facts(path.read_text(encoding="utf-8"), "action_automaton_signature"):
        fields = split_top_level(body)
        if len(fields) != 4:
            raise ValueError(f"expected action_automaton_signature/4, got {len(fields)} fields")
        signatures.append(Signature(atom_name(fields[0]), atom_name(fields[1])))
    return sorted(signatures)


def read_tables(directory: Path) -> dict[Signature, Automaton]:
    automata: dict[Signature, Automaton] = {}
    transition_rows: dict[Signature, set[tuple[Term, Term, Term]]] = defaultdict(set)
    for path in sorted(directory.glob("*.pl")):
        text = path.read_text(encoding="utf-8")
        for body in iter_facts(text, "automaton_tuple"):
            fields = split_top_level(body)
            if len(fields) != 6:
                raise ValueError(f"{path}: expected automaton_tuple/6")
            signature = Signature(atom_name(fields[0]), atom_name(fields[1]))
            states = [term_info(item) for item in parse_list(unwrap(fields[2], "states"))]
            actions = [term_info(item) for item in parse_list(unwrap(fields[3], "actions"))]
            start = atom_name(unwrap(fields[4], "start"))
            accepting = {
                atom_name(item)
                for item in parse_list(unwrap(fields[5], "accepting"))
            }
            if signature in automata:
                raise ValueError(f"duplicate automaton tuple for {signature.name}")
            automata[signature] = Automaton(
                signature, states, actions, start, accepting, []
            )
        for body in iter_facts(text, "automaton_transition"):
            fields = split_top_level(body)
            if len(fields) != 6:
                raise ValueError(f"{path}: expected automaton_transition/6")
            signature = Signature(atom_name(fields[0]), atom_name(fields[1]))
            transition_rows[signature].add(
                (term_info(fields[2]), term_info(fields[3]), term_info(fields[4]))
            )
    for signature, rows in transition_rows.items():
        if signature not in automata:
            raise ValueError(f"transition without tuple for {signature.name}")
        automata[signature].transitions = sorted(
            rows, key=lambda row: (row[0].raw, row[1].raw, row[2].raw)
        )
    return automata


def signature_occurrences(
    automata: dict[Signature, Automaton], label_type: str
) -> tuple[dict[str, set[Signature]], Counter[str], dict[str, set[int]], dict[str, set[str]]]:
    signatures: dict[str, set[Signature]] = defaultdict(set)
    occurrences: Counter[str] = Counter()
    arities: dict[str, set[int]] = defaultdict(set)
    term_shapes: dict[str, set[str]] = defaultdict(set)
    for signature, automaton in automata.items():
        terms = automaton.actions if label_type == "action" else automaton.states
        for term in terms:
            signatures[term.label].add(signature)
            occurrences[term.label] += 1
            arities[term.label].add(term.arity)
            term_shapes[term.label].add(term.shape)
    return signatures, occurrences, arities, term_shapes


def stem_token(token: str) -> str:
    """Apply a deliberately small inflectional stemmer."""
    if len(token) > 5 and token.endswith("ies"):
        return token[:-3] + "y"
    if len(token) > 6 and token.endswith("ing"):
        stem = token[:-3]
        if len(stem) > 3 and stem[-1:] == stem[-2:-1]:
            stem = stem[:-1]
        return stem
    if len(token) > 5 and token.endswith("ed"):
        stem = token[:-2]
        if len(stem) > 3 and stem[-1:] == stem[-2:-1]:
            stem = stem[:-1]
        return stem
    if len(token) > 5 and token.endswith("es"):
        return token[:-2]
    if len(token) > 4 and token.endswith("s"):
        return token[:-1]
    return token


def stem_tokens(label: str) -> tuple[str, ...]:
    return tuple(stem_token(token) for token in label.split("_") if token)


def near_pair(left: str, right: str) -> dict[str, object] | None:
    left_tokens = stem_tokens(left)
    right_tokens = stem_tokens(right)
    if left_tokens == right_tokens:
        return {"method": "same_inflectional_stems", "stems": list(left_tokens)}
    if min(len(left_tokens), len(right_tokens)) < 2:
        return None
    left_set, right_set = set(left_tokens), set(right_tokens)
    union = left_set | right_set
    jaccard = len(left_set & right_set) / len(union) if union else 0.0
    ratio = SequenceMatcher(None, "_".join(left_tokens), "_".join(right_tokens)).ratio()
    same_head = left_tokens[0] == right_tokens[0]
    same_tail = left_tokens[-1] == right_tokens[-1]
    # Requiring both high token overlap and a shared action head or object tail
    # keeps this a review queue, not a semantic equivalence claim.
    if jaccard >= 0.8 and ratio >= 0.86 and (same_head or same_tail):
        return {
            "method": "conservative_string_stem_similarity",
            "jaccard": round(jaccard, 4),
            "sequence_ratio": round(ratio, 4),
            "shared_stems": sorted(left_set & right_set),
        }
    return None


def near_clusters(labels: Iterable[str]) -> list[dict[str, object]]:
    """Build deterministic complete-link clusters of conservative near pairs."""
    ordered = sorted(set(labels))
    evidence: dict[tuple[str, str], dict[str, object]] = {}
    for index, left in enumerate(ordered):
        for right in ordered[index + 1 :]:
            finding = near_pair(left, right)
            if finding:
                evidence[(left, right)] = finding
    clusters: list[list[str]] = [[label] for label in ordered]
    changed = True
    while changed:
        changed = False
        for left_index in range(len(clusters)):
            for right_index in range(left_index + 1, len(clusters)):
                cross = [
                    tuple(sorted((left, right)))
                    for left in clusters[left_index]
                    for right in clusters[right_index]
                ]
                if cross and all(pair in evidence for pair in cross):
                    clusters[left_index] = sorted(
                        clusters[left_index] + clusters[right_index]
                    )
                    del clusters[right_index]
                    changed = True
                    break
            if changed:
                break
    result: list[dict[str, object]] = []
    for members in clusters:
        if len(members) < 2:
            continue
        pair_evidence = [
            {"labels": list(pair), **evidence[pair]}
            for pair in sorted(evidence)
            if pair[0] in members and pair[1] in members
        ]
        result.append({"labels": members, "evidence": pair_evidence})
    return sorted(result, key=lambda row: row["labels"])


def label_inventory(
    automata: dict[Signature, Automaton], label_type: str
) -> dict[str, object]:
    signatures, occurrences, arities, term_shapes = signature_occurrences(
        automata, label_type
    )
    exact_duplicates = [
        {
            "label": label,
            "signature_count": len(signatures[label]),
            "occurrence_count": occurrences[label],
            "affected_signatures": [
                signature.name for signature in sorted(signatures[label])
            ],
        }
        for label in sorted(signatures)
        if len(signatures[label]) > 1
    ]
    singletons = [
        {
            "label": label,
            "occurrence_count": occurrences[label],
            "signature": next(iter(signatures[label])).name,
        }
        for label in sorted(signatures)
        if len(signatures[label]) == 1
    ]
    return {
        "unique_labels": len(signatures),
        "label_occurrences": sum(occurrences.values()),
        "exact_duplicate_label_count": len(exact_duplicates),
        "exact_duplicates": exact_duplicates,
        "near_synonym_clusters": near_clusters(signatures),
        "single_signature_label_count": len(singletons),
        "single_signature_labels": singletons,
        "arities": {label: sorted(values) for label, values in sorted(arities.items())},
        "term_shapes": {
            label: sorted(values) for label, values in sorted(term_shapes.items())
        },
        "_signature_index": signatures,
        "_occurrences": occurrences,
    }


def role(automaton: Automaton, state: str) -> str:
    if state == automaton.start:
        return "start"
    if state in automaton.accepting:
        return "accepting"
    if any(item.label == state for item in automaton.states):
        return "intermediate"
    return "undeclared"


def mismatch_inventory(automata: dict[Signature, Automaton]) -> dict[str, object]:
    arities: dict[str, set[int]] = defaultdict(set)
    term_shapes: dict[str, set[str]] = defaultdict(set)
    roles: dict[str, dict[tuple[str, str], set[Signature]]] = defaultdict(
        lambda: defaultdict(set)
    )
    for signature, automaton in automata.items():
        for source, action, target in automaton.transitions:
            arities[action.label].add(action.arity)
            term_shapes[action.label].add(action.shape)
            roles[action.label][(role(automaton, source.label), role(automaton, target.label))].add(
                signature
            )
    arity_mismatches = [
        {
            "label": label,
            "arities": sorted(arities[label]),
            "term_shapes": sorted(term_shapes[label]),
        }
        for label in sorted(arities)
        if len(arities[label]) > 1 or len(term_shapes[label]) > 1
    ]
    transition_shape_mismatches = []
    for label in sorted(roles):
        if len(roles[label]) < 2:
            continue
        transition_shape_mismatches.append(
            {
                "label": label,
                "role_shapes": [
                    {
                        "from": shape[0],
                        "to": shape[1],
                        "affected_signatures": [
                            signature.name for signature in sorted(signatures)
                        ],
                    }
                    for shape, signatures in sorted(roles[label].items())
                ],
            }
        )
    return {
        "arity_or_term_shape_mismatches": arity_mismatches,
        "transition_role_shape_mismatches": transition_shape_mismatches,
    }


def choose_canonical(
    labels: list[str], signatures: dict[str, set[Signature]], occurrences: Counter[str]
) -> str:
    return min(
        labels,
        key=lambda label: (
            -len(signatures[label]),
            -occurrences[label],
            len(label.split("_")),
            len(label),
            label,
        ),
    )


def proposal_rows(
    label_type: str, inventory: dict[str, object]
) -> list[dict[str, object]]:
    signatures = inventory["_signature_index"]
    occurrences = inventory["_occurrences"]
    assert isinstance(signatures, dict) and isinstance(occurrences, Counter)
    rows: list[dict[str, object]] = []
    clusters = inventory["near_synonym_clusters"]
    assert isinstance(clusters, list)
    for index, cluster in enumerate(clusters, start=1):
        labels = cluster["labels"]
        assert isinstance(labels, list)
        canonical = choose_canonical(labels, signatures, occurrences)
        cluster_id = f"{label_type}-{index:03d}"
        evidence = {
            "cluster_id": cluster_id,
            "basis": cluster["evidence"],
            "canonical_selection": (
                "most affected signatures, then occurrences, then shortest label, "
                "then lexical order"
            ),
        }
        for old_label in labels:
            if old_label == canonical:
                continue
            affected = sorted(signatures[old_label] | signatures[canonical])
            rows.append(
                {
                    "label_type": label_type,
                    "old_label": old_label,
                    "proposed_canonical_label": canonical,
                    "status": "review-pending",
                    "evidence": evidence,
                    "affected_signatures": [signature.name for signature in affected],
                }
            )
    return rows


def clean_inventory(inventory: dict[str, object]) -> dict[str, object]:
    return {
        key: value
        for key, value in inventory.items()
        if not key.startswith("_")
    }


def build_census(registry_path: Path, table_directory: Path) -> dict[str, object]:
    registry = read_registry(registry_path)
    automata = read_tables(table_directory)
    registry_set = set(registry)
    table_set = set(automata)
    action_inventory = label_inventory(automata, "action")
    state_inventory = label_inventory(automata, "state")
    proposals = (
        proposal_rows("action", action_inventory)
        + proposal_rows("state", state_inventory)
    )
    return {
        "schema_version": 1,
        "status": "review-pending",
        "scope": {
            "registry": str(registry_path.relative_to(ROOT)),
            "transition_tables": str(table_directory.relative_to(ROOT)),
            "registry_signature_count": len(registry),
            "table_signature_count": len(automata),
            "signatures_without_table": [
                signature.name for signature in sorted(registry_set - table_set)
            ],
            "tables_without_registry_signature": [
                signature.name for signature in sorted(table_set - registry_set)
            ],
        },
        "action_labels": clean_inventory(action_inventory),
        "state_labels": clean_inventory(state_inventory),
        "mismatches": mismatch_inventory(automata),
        "normalization_proposal": {
            "status": "review-pending",
            "policy": (
                "String and inflectional-stem candidates only. No table is rewritten; "
                "adoption requires owner review."
            ),
            "columns": [
                "label_type",
                "old_label",
                "proposed_canonical_label",
                "status",
                "evidence",
                "affected_signatures",
            ],
            "rows": proposals,
        },
    }


def proposal_csv(census: dict[str, object]) -> str:
    output = io.StringIO()
    columns = [
        "label_type",
        "old_label",
        "proposed_canonical_label",
        "status",
        "evidence",
        "affected_signatures",
    ]
    writer = csv.DictWriter(output, fieldnames=columns, lineterminator="\n")
    writer.writeheader()
    proposal = census["normalization_proposal"]
    assert isinstance(proposal, dict)
    rows = proposal["rows"]
    assert isinstance(rows, list)
    for row in rows:
        writer.writerow(
            {
                **row,
                "evidence": json.dumps(row["evidence"], sort_keys=True, separators=(",", ":")),
                "affected_signatures": ";".join(row["affected_signatures"]),
            }
        )
    return output.getvalue()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--registry", type=Path, default=DEFAULT_REGISTRY)
    parser.add_argument("--tables", type=Path, default=DEFAULT_TABLES)
    parser.add_argument(
        "--format",
        choices=("json", "proposal-csv"),
        default="json",
        help="emit the full census or only the review-pending proposal table",
    )
    parser.add_argument(
        "--output",
        type=Path,
        help="write to this path instead of stdout; use outside the source tree for review",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    census = build_census(args.registry.resolve(), args.tables.resolve())
    if args.format == "json":
        rendered = json.dumps(census, indent=2, sort_keys=True) + "\n"
    else:
        rendered = proposal_csv(census)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered, encoding="utf-8")
    else:
        sys.stdout.write(rendered)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
