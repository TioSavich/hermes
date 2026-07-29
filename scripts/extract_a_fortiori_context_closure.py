#!/usr/bin/env python3
"""Generate checked a-fortiori closure triples for reviewed context nestings.

The reviewed source records only strict input-class inclusions.  For each
``narrow ⊂ broad`` row, every error-rule triple defeated in ``broad`` also
holds in ``narrow``.  The generated triples preserve the original inference
and licensed consequence and replace only the context.  The source's status
is retained: an asserted nesting is never presented as automaton-certified.

Regenerate: python3 scripts/extract_a_fortiori_context_closure.py
Check:      python3 scripts/extract_a_fortiori_context_closure.py --check
"""
from __future__ import annotations

import argparse
import difflib
import json
import re
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
NESTINGS = ROOT / "formal" / "incompatibility" / "a_fortiori_context_nestings.json"
ERROR_CACHE = ROOT / "formal" / "incompatibility" / "incompatibility_sets_error_rules.pl"
OUTPUT = ROOT / "formal" / "incompatibility" / "incompatibility_sets_a_fortiori_context_closure.pl"
AUTOMATON_STATUSES = {
    "unavailable",
    "probed_narrow_endpoint_only",
    "probed_broad_endpoint_membership",
    "certified_narrow_endpoint_reimplementation",
    "certified_nesting",
}

FACT = re.compile(
    r"incompatibility_sets:discovered_set_fact\(defeasible_inference, "
    r"\[inference\((?P<inference>[a-z][a-z0-9_]*)\),"
    r"o\(context\((?P<context>[a-z][a-z0-9_]*)\)\),"
    r"o\(licensed_consequence\((?P<consequence>[a-z][a-z0-9_]*)\)\)\]\)\."
)


def load_error_triples() -> list[dict[str, str]]:
    triples = [match.groupdict() for match in FACT.finditer(ERROR_CACHE.read_text(encoding="utf-8"))]
    if len(triples) != 90:
        raise SystemExit(f"expected 90 generated error-rule triples, found {len(triples)}")
    if len({(row['inference'], row['consequence'], row['context']) for row in triples}) != len(triples):
        raise SystemExit("error-rule cache contains duplicate triples")
    return triples


def nesting_cycle(rows: list[dict[str, str]]) -> list[str] | None:
    """Return one declared directed cycle, if the nesting graph has one."""
    adjacency: dict[str, list[str]] = {}
    for row in rows:
        adjacency.setdefault(row["narrow"], []).append(row["broad"])
        adjacency.setdefault(row["broad"], [])
    for neighbours in adjacency.values():
        neighbours.sort()

    active: list[str] = []
    seen: set[str] = set()

    def visit(node: str) -> list[str] | None:
        if node in active:
            return active[active.index(node):] + [node]
        if node in seen:
            return None
        seen.add(node)
        active.append(node)
        for neighbour in adjacency[node]:
            cycle = visit(neighbour)
            if cycle:
                return cycle
        active.pop()
        return None

    for start in sorted(adjacency):
        cycle = visit(start)
        if cycle:
            return cycle
    return None


def load_nestings_payload(payload: dict[str, object], contexts: set[str]) -> list[dict[str, str]]:
    if payload.get("schema_version") != 1:
        raise SystemExit("unsupported a-fortiori nesting schema")
    rows = payload.get("nestings")
    if not isinstance(rows, list) or not rows:
        raise SystemExit("a-fortiori nesting source must carry at least one row")
    required = {"narrow", "broad", "status", "warrant", "basis", "automaton"}
    seen: set[tuple[str, str]] = set()
    checked: list[dict[str, str]] = []
    for row in rows:
        if not isinstance(row, dict) or set(row) != required:
            raise SystemExit("each nesting must carry exactly narrow, broad, status, warrant, basis, and automaton")
        if not all(isinstance(row[field], str) and row[field] for field in required):
            raise SystemExit(f"nesting contains an empty non-string field: {row!r}")
        pair = (row["narrow"], row["broad"])
        if pair[0] == pair[1] or pair in seen:
            raise SystemExit(f"nesting is reflexive or duplicated: {pair!r}")
        if pair[0] not in contexts or pair[1] not in contexts:
            raise SystemExit(f"nesting names a context absent from the generated error-rule cache: {pair!r}")
        if row["status"] != "asserted":
            raise SystemExit("only reviewed asserted nestings may be emitted here")
        if row["automaton"] not in AUTOMATON_STATUSES:
            raise SystemExit(f"unsupported a-fortiori automaton status: {row['automaton']!r}")
        seen.add(pair)
        checked.append({field: row[field] for field in required})
    cycle = nesting_cycle(checked)
    if cycle:
        raise SystemExit(f"a-fortiori nesting graph contains directed cycle: {' -> '.join(cycle)}")
    return sorted(checked, key=lambda row: (row["narrow"], row["broad"]))


def load_nestings(contexts: set[str]) -> list[dict[str, str]]:
    return load_nestings_payload(json.loads(NESTINGS.read_text(encoding="utf-8")), contexts)


def strictness_guard(triples: list[dict[str, str]], nestings: list[dict[str, str]]) -> None:
    """Require the native narrow edge that keeps each closure entailment strict."""
    # load_nestings_payload already requires both endpoints to occur in the
    # source cache. Keep this independent check at the semantic boundary: if
    # endpoint validation changes, a narrow class with no native edge must not
    # turn a strict nesting into a false equivalence.
    native_counts: dict[str, int] = {}
    for triple in triples:
        native_counts[triple["context"]] = native_counts.get(triple["context"], 0) + 1
    for nesting in nestings:
        narrow = nesting["narrow"]
        broad = nesting["broad"]
        if native_counts.get(narrow, 0) < 1:
            raise SystemExit(
                "strictness guard: narrow context retains no native error-rule triple "
                f"for declared nesting {narrow} -> {broad}"
            )
        if native_counts.get(broad, 0) < 1:
            raise SystemExit(
                "strictness guard: broad context has no native error-rule triple "
                f"for declared nesting {narrow} -> {broad}"
            )


def closure_rows(triples: list[dict[str, str]], nestings: list[dict[str, str]]) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for nesting in nestings:
        broad_rows = [row for row in triples if row["context"] == nesting["broad"]]
        for source in broad_rows:
            rows.append({
                "inference": source["inference"],
                "consequence": source["consequence"],
                "narrow": nesting["narrow"],
                "broad": nesting["broad"],
            })
    rows.sort(key=lambda row: (row["narrow"], row["broad"], row["inference"], row["consequence"]))
    if len({(row["inference"], row["consequence"], row["narrow"]) for row in rows}) != len(rows):
        raise SystemExit("a-fortiori closure would duplicate a declared triple")
    existing = {(row["inference"], row["consequence"], row["context"]) for row in triples}
    duplicated = [row for row in rows if (row["inference"], row["consequence"], row["narrow"]) in existing]
    if duplicated:
        raise SystemExit(f"a-fortiori closure repeats existing error-rule triples: {duplicated!r}")
    return rows


HEADER = """% PURPOSE: Checked a-fortiori closure triples for reviewed strict context nestings.
%
% Each row below preserves an error-rule inference and its licensed consequence.
% It changes only a broad divergence context to a reviewed narrower input class:
% a rule defeated throughout the broad class is defeated in every member of its
% subclass. The accompanying nesting facts retain their epistemic status.
%
% PROVENANCE: formal/incompatibility/a_fortiori_context_nestings.json and the generated
% error-rule cache. The source rows are asserted with named input-class
% warrants. A narrow-endpoint reimplementation can be checked against an
% automaton without certifying the inclusion; certification of a nesting still
% requires a decider for both endpoints and their input-class relation.
%
% Generated by scripts/extract_a_fortiori_context_closure.py -- do not hand-edit.
"""


def render(nestings: list[dict[str, str]], rows: list[dict[str, str]]) -> str:
    lines = [HEADER.rstrip(), ""]
    for nesting in nestings:
        lines.append(
            "incompatibility_sets:a_fortiori_context_nesting("
            f"{nesting['narrow']}, {nesting['broad']}, {nesting['status']}, {nesting['warrant']})."
        )
    lines.append("")
    for row in rows:
        terms = (
            f"[inference({row['inference']}),"
            f"o(context({row['narrow']})),"
            f"o(licensed_consequence({row['consequence']}))]"
        )
        lines.append(
            "incompatibility_sets:discovered_set_fact(a_fortiori_context_closure, " + terms + ")."
        )
        lines.append(
            "incompatibility_sets:discovered_set_kind(a_fortiori_context_closure, " + terms + ", a_fortiori_closure)."
        )
    lines.append("")
    return "\n".join(lines)


def compare(expected: str) -> int:
    actual = OUTPUT.read_text(encoding="utf-8") if OUTPUT.is_file() else ""
    if actual == expected:
        return 0
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False) as temporary:
        temporary.write(expected)
        temporary_path = Path(temporary.name)
    sys.stderr.write("".join(difflib.unified_diff(actual.splitlines(True), expected.splitlines(True), fromfile=str(OUTPUT), tofile=str(temporary_path))))
    temporary_path.unlink(missing_ok=True)
    return 1


def automaton_counts(nestings: list[dict[str, str]]) -> tuple[int, int, int]:
    certified_nestings = sum(row["automaton"] == "certified_nesting" for row in nestings)
    certified_endpoints = sum(row["automaton"] == "certified_narrow_endpoint_reimplementation" for row in nestings)
    probed_endpoints = sum(
        row["automaton"] in {"probed_narrow_endpoint_only", "probed_broad_endpoint_membership"}
        for row in nestings
    )
    return certified_nestings, certified_endpoints, probed_endpoints


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail if the generated closure cache is stale")
    parser.add_argument("--selftest", action="store_true", help="exercise sealed negative validation fixtures")
    arguments = parser.parse_args()
    if arguments.selftest:
        fixture = {
            "schema_version": 1,
            "nestings": [
                {"narrow": "alpha", "broad": "beta", "status": "asserted", "warrant": "fixture", "basis": "fixture", "automaton": "unavailable"},
                {"narrow": "beta", "broad": "alpha", "status": "asserted", "warrant": "fixture", "basis": "fixture", "automaton": "unavailable"},
            ],
        }
        try:
            load_nestings_payload(fixture, {"alpha", "beta"})
        except SystemExit as error:
            expected = "a-fortiori nesting graph contains directed cycle: alpha -> beta -> alpha"
            if str(error) != expected:
                raise
            print(f"PASS a-fortiori closure selftest: {error}")
            return 0
        raise SystemExit("a-fortiori closure selftest failed: synthetic cycle was accepted")
    triples = load_error_triples()
    nestings = load_nestings({row["context"] for row in triples})
    strictness_guard(triples, nestings)
    rows = closure_rows(triples, nestings)
    artifact = render(nestings, rows)
    if arguments.check:
        status = compare(artifact)
        if not status:
            certified, endpoint_certified, probed = automaton_counts(nestings)
            print(f"a-fortiori context closure current: nestings={len(nestings)}; closure_triples={len(rows)}; asserted={len(nestings)}; automaton_certified={certified}; automaton_endpoint_certified={endpoint_certified}; automaton_probed={probed}")
        return status
    OUTPUT.write_text(artifact, encoding="utf-8")
    certified, endpoint_certified, probed = automaton_counts(nestings)
    print(f"a-fortiori context closure written: nestings={len(nestings)}; closure_triples={len(rows)}; asserted={len(nestings)}; automaton_certified={certified}; automaton_endpoint_certified={endpoint_certified}; automaton_probed={probed}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
