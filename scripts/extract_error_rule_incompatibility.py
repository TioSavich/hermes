#!/usr/bin/env python3
"""Generate the error-rule material inferences and their discovered-set cache.

The reviewed codings in data/research/incompatibility_triples.json carry a rule,
what the rule licenses on the class where it agrees with the sanctioned
comparison, and the class where that licensed result diverges. Those three make
the set the incompatibility relation can hold:

    [ s(comp_nec(rule(R))), o(licensed_consequence(C)), o(context(K)) ]

This script writes two artifacts and never invents a verdict for either.

  formal/incompatibility/error_rule_inferences.pl
      included by defeasible_inference.pl. It contributes material_inference/3
      rows (holding the rule entitles you to its consequence) and
      error_rule_break/2 rows. The break predicate is kept apart from
      compiled_break/2 on purpose: a Lakoff-Nunez break is jointly incoherent as
      mathematics, while an error triple is incoherent relative to a community's
      sanction. error_rule_warrant/2 records which, so a claim built on the
      relation can say what it rests on.

  formal/incompatibility/incompatibility_sets_error_rules.pl
      the discovered-set rows for the new inferences, consulted by
      incompatibility_sets.pl beside the Big Red cache. Every row here is the
      output of running defeasible_inference's own classifier over the candidate
      grid; nothing is asserted by this script.

Regenerate: python3 scripts/extract_error_rule_incompatibility.py
Check:      python3 scripts/extract_error_rule_incompatibility.py --check
"""

from __future__ import annotations

import argparse
import difflib
import json
import re
import subprocess
import sys
import tempfile
import time
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REVIEWED = ROOT / "data" / "research" / "incompatibility_triples.json"
INFERENCES = ROOT / "formal" / "incompatibility" / "error_rule_inferences.pl"
CACHE = ROOT / "formal" / "incompatibility" / "incompatibility_sets_error_rules.pl"

ATOM_RE = re.compile(r"^[a-z][a-z0-9_]*$")

SWEEP_GOAL = r"""
use_module(incompat(defeasible_inference), [material_inference/3, classify_defeat/3, compiled_break/2, error_rule_break/2]),
forall(( member(Id, %(ids)s ),
         sweep_emergent_candidate(Id, Defeaters),
         classify_defeat(Id, Defeaters, Outcome),
         sweep_kind(Outcome, Kind)
       ),
       ( append([inference(Id)], Defeaters, Set),
         write('candidate'), put(9),
         write_term(Set, [quoted(true), ignore_ops(true), numbervars(true)]),
         put(9), write(Kind), nl )),
forall(member(Id, %(ids)s),
       ( sweep_crosstalk_count(Id, Count),
         write('crosstalk'), put(9), write(Id), put(9), write(Count), nl )),
halt
"""

# An emergent result in this bounded grid has one premise and two defeaters.
# It can only arise where those three commitments are exactly a declared
# three-condition break. Binary breaks whose two conditions are both defeaters
# are already incoherent below the candidate triple, so emergent_witness/4
# necessarily rejects them. They are retained below as a typed census rather
# than repeated discovered-set rows.
SWEEP_HELPERS = r"""
sweep_break(Conditions) :- compiled_break(_, Conditions).
sweep_break(Conditions) :- error_rule_break(_, Conditions).

sweep_emergent_candidate(Id, Defeaters) :-
    material_inference(Id, [Premise], _),
    sweep_break(Conditions),
    length(Conditions, 3),
    select(Premise, Conditions, Defeaters0),
    sort(Defeaters0, Defeaters),
    length(Defeaters, 2).

sweep_crosstalk_count(Id, Count) :-
    material_inference(Id, [Premise], _),
    findall(Conditions,
            ( sweep_break(Conditions),
              length(Conditions, 2),
              \+ memberchk(Premise, Conditions)
            ),
            Conditions0),
    sort(Conditions0, Conditions),
    length(Conditions, Count).

sweep_kind(incoherent(emergent_defeat(_, _)), emergent).
sweep_kind(incoherent(defeated(_, _)), defeated).
"""


def load_triples() -> tuple[list[dict], dict]:
    payload = json.loads(REVIEWED.read_text(encoding="utf-8"))
    triples: dict[tuple[str, str, str], list[int]] = {}
    for coding in payload["codings"]:
        if coding["valid_domain_status"] == "none_found":
            continue
        key = (coding["rule_atom"], coding["consequence_atom"], coding["divergence_atom"])
        for atom in key:
            if not ATOM_RE.match(atom):
                raise SystemExit(f"row {coding['row_id']} carries a non-atom name: {atom!r}")
        triples.setdefault(key, []).append(coding["row_id"])
    rows = [
        {
            "rule": rule,
            "consequence": consequence,
            "divergence": divergence,
            "rows": sorted(row_ids),
            "slices": sorted(
                {
                    coding["slice"]
                    for coding in payload["codings"]
                    if coding["valid_domain_status"] != "none_found"
                    and (coding["rule_atom"], coding["consequence_atom"], coding["divergence_atom"])
                    == (rule, consequence, divergence)
                }
            ),
            "inference_id": f"rule_{rule}_licenses_{consequence}"[:200],
            "break_id": f"rule_{rule}_diverges_at_{divergence}"[:200],
        }
        for (rule, consequence, divergence), row_ids in sorted(triples.items())
    ]
    identifiers = Counter(row["inference_id"] for row in rows)
    collisions = [name for name, count in identifiers.items() if count > 1]
    if collisions:
        raise SystemExit(f"inference identifiers collide: {collisions}")
    return rows, payload


def render_inferences(rows: list[dict], payload: dict) -> str:
    lines = [
        "% PURPOSE: Error-rule material inferences and their break points, generated from the",
        "% reviewed research-corpus codings; included by formal/incompatibility/defeasible_inference.pl.",
        "%",
        "% PROVENANCE: data/research/incompatibility_triples.json, coded against the standard in",
        f"% {payload['standard']}",
        "% and reviewed by hand before any database write. Slices:",
        *(
            f"%   {entry['slice']} — {entry['rows_in_slice']} rows, "
            f"coded {entry['coded_at']} through {entry['model']}"
            for entry in payload["slices"]
        ),
        "%",
        "% Each row of the corpus that carries a rule, a class where the rule agrees with the",
        "% sanctioned comparison, and a class where what it licenses diverges contributes one",
        "% material inference and one break. Rows coded none_found contribute nothing here:",
        "% a rule valid nowhere yields a pair, and a pair cannot be emergent. That exclusion is",
        "% a result about the vocabulary, not a gap in the coding.",
        "%",
        "% WARRANT. error_rule_break/2 is deliberately not compiled_break/2. A Lakoff-Nunez",
        "% break is jointly incoherent as mathematics and anyone can check it by doing the",
        "% mathematics. These sets are incoherent relative to a community's sanction, and the",
        "% community is named in the corpus column incompatible_with. error_rule_warrant/2",
        "% carries the difference so a claim built on the relation can state what it rests on.",
        "%",
        "% Generated by scripts/extract_error_rule_incompatibility.py — do not hand-edit.",
        "",
    ]
    for row in rows:
        provenance = ", ".join(str(row_id) for row_id in row["rows"])
        lines.append(f"% error_instances rows: {provenance}")
        lines.append(
            f"material_inference({row['inference_id']},\n"
            f"                   [s(comp_nec(rule({row['rule']})))],\n"
            f"                   o(licensed_consequence({row['consequence']})))."
        )
        lines.append(
            f"error_rule_break({row['break_id']},\n"
            f"                 [s(comp_nec(rule({row['rule']}))),\n"
            f"                  o(licensed_consequence({row['consequence']})),\n"
            f"                  o(context({row['divergence']}))])."
        )
        lines.append(f"error_rule_warrant({row['break_id']}, community_sanctioned).")
        lines.append(
            f"error_rule_source({row['break_id']}, [{provenance}])."
        )
        lines.append("")
    return "\n".join(lines)


def run_sweep(rows: list[dict]) -> tuple[list[tuple[str, str]], list[tuple[str, int]]]:
    identifiers = "[" + ", ".join(row["inference_id"] for row in rows) + "]"
    with tempfile.TemporaryDirectory(prefix="hermes-error-rule-sweep-") as directory:
        helpers = Path(directory) / "helpers.pl"
        helpers.write_text(SWEEP_HELPERS, encoding="utf-8")
        result = subprocess.run(
            [
                "swipl", "-q",
                "-l", str(ROOT / "paths.pl"),
                "-s", str(helpers),
                "-g", (SWEEP_GOAL % {"ids": identifiers}).replace("\n", " "),
            ],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
    if result.returncode:
        raise SystemExit(result.stderr.strip() or "error-rule sweep failed")
    if result.stderr.strip():
        raise SystemExit(result.stderr.strip())
    discovered: list[tuple[str, str]] = []
    crosstalk: list[tuple[str, int]] = []
    for line in result.stdout.splitlines():
        if not line.strip():
            continue
        fields = line.split("\t")
        if len(fields) != 3:
            raise SystemExit(f"sweep returned a malformed row: {line}")
        row_kind, first, second = fields
        if row_kind == "candidate" and second in {"emergent", "defeated"}:
            discovered.append((first, second))
        elif row_kind == "crosstalk" and second.isdecimal():
            crosstalk.append((first, int(second)))
        else:
            raise SystemExit(f"sweep returned an unexpected kind: {line}")
    expected_ids = {row["inference_id"] for row in rows}
    counted_ids = {identifier for identifier, _count in crosstalk}
    if counted_ids != expected_ids or len(crosstalk) != len(counted_ids):
        raise SystemExit("crosstalk census did not return one aggregate for every generated inference")
    return discovered, sorted(crosstalk)


KNOWN_GOOD_GOAL = r"""
use_module(incompat(defeasible_inference), [classify_defeat/3, compiled_break/2, error_rule_break/2, material_inference/3]),
forall(member(case(Id, Defeaters), %(cases)s),
       ( ( sweep_emergent_candidate(Id, Defeaters) -> Selected = selected ; Selected = omitted ),
         classify_defeat(Id, Defeaters, Outcome),
         sweep_kind(Outcome, Kind),
         write(Id), put(9), write(Selected), put(9), write(Kind), nl )),
halt
"""


def known_good_cases(rows: list[dict]) -> list[tuple[str, list[str]]]:
    """The four declared L&N triples and the original fraction-comparison 15."""
    lakoff_nunez = [
        ("measuring_stick_grounds_length", [
            "o(diagonal_of_unit_square_measured)", "o(length_is_count_of_units)"
        ]),
        ("functions_are_ordered_pairs_grounds_functions", [
            "o(rules_conceptually_distinct)", "o(two_rules_same_extension)"
        ]),
        ("spaces_are_point_sets_grounds_space", [
            "o(points_inherent_to_space)", "o(space_constituted_by_points)"
        ]),
        ("cantors_metaphor_grounds_cardinality", [
            "o(everyday_same_number_comparison)", "o(infinite_collection_compared)"
        ]),
    ]
    fraction = [
        (
            row["inference_id"],
            sorted([
                f"o(licensed_consequence({row['consequence']}))",
                f"o(context({row['divergence']}))",
            ]),
        )
        for row in rows
        if row["slices"] == ["fraction_comparison"]
    ]
    if len(fraction) != 15:
        raise SystemExit(
            "known-good fraction instrument expected 15 distinct fraction-comparison triples, "
            f"found {len(fraction)}"
        )
    return lakoff_nunez + fraction


def verify_known_good_cases(rows: list[dict]) -> None:
    cases = known_good_cases(rows)
    case_text = "[" + ", ".join(
        f"case({identifier}, [{', '.join(defeaters)}])"
        for identifier, defeaters in cases
    ) + "]"
    with tempfile.TemporaryDirectory(prefix="hermes-error-rule-known-good-") as directory:
        helpers = Path(directory) / "helpers.pl"
        helpers.write_text(SWEEP_HELPERS, encoding="utf-8")
        result = subprocess.run(
            [
                "swipl", "-q",
                "-l", str(ROOT / "paths.pl"),
                "-s", str(helpers),
                "-g", (KNOWN_GOOD_GOAL % {"cases": case_text}).replace("\n", " "),
            ],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
    if result.returncode:
        raise SystemExit(result.stderr.strip() or "known-good emergent instrument failed")
    if result.stderr.strip():
        raise SystemExit(result.stderr.strip())
    observed = [tuple(line.split("\t")) for line in result.stdout.splitlines() if line.strip()]
    if len(observed) != len(cases) or any(status != "selected" or kind != "emergent" for _id, status, kind in observed):
        raise SystemExit(f"known-good emergent instrument rejected a declared emergent case: {observed}")


def render_cache(
    discovered: list[tuple[str, str]],
    crosstalk: list[tuple[str, int]],
    rows: list[dict],
    payload: dict,
) -> str:
    kinds = Counter(kind for _set_text, kind in discovered)
    crosstalk_total = sum(count for _identifier, count in crosstalk)
    lines = [
        "% PURPOSE: Discovered-set cache for the error-rule material inferences, consulted at load",
        "% by formal/incompatibility/incompatibility_sets.pl beside the Big Red iteration7 cache.",
        "%",
        "% PROVENANCE: computed locally by scripts/extract_error_rule_incompatibility.py by running",
        "% defeasible_inference:classify_defeat/3 over the size 1..2 defeater grid for the",
        f"% {len(rows)} inferences generated from data/research/incompatibility_triples.json",
        f"% (slices {', '.join(entry['slice'] for entry in payload['slices'])}).",
        "% Every discovered kind below is the classifier's verdict.",
        f"% Rows: {kinds.get('emergent', 0)} emergent, {kinds.get('defeated', 0)} non-crosstalk defeated.",
        f"% Crosstalk: {crosstalk_total} binary-break defeats, retained as one count per inference.",
        "% A crosstalk count records binary breaks wholly inside the two defeaters while the",
        "% inference premise is absent. Each such candidate fails the classifier's minimality",
        "% check, so it cannot be emergent and does not describe the coded rule.",
        "%",
        "% This file is a second cache rather than an edit to the Big Red one: that cache is the",
        "% harvest of a named SLURM job and hand-editing it would break its provenance.",
        "%",
        "% The two predicates are declared dynamic and multifile by",
        "% formal/incompatibility/incompatibility_sets.pl. Re-declaring them here would",
        "% make this consult REPLACE the Big Red cache's clauses instead of adding to them.",
        "%",
        "% Generated by scripts/extract_error_rule_incompatibility.py — do not hand-edit.",
        "",
    ]
    for set_text, _kind in discovered:
        lines.append(f"incompatibility_sets:discovered_set_fact(defeasible_inference, {set_text}).")
    lines.append("")
    for set_text, kind in discovered:
        lines.append(
            f"incompatibility_sets:discovered_set_kind(defeasible_inference, {set_text}, {kind})."
        )
    lines.append("")
    for identifier, count in crosstalk:
        lines.append(
            "incompatibility_sets:error_rule_crosstalk_defeat_count("
            f"defeasible_inference, {identifier}, {count})."
        )
    lines.append("")
    return "\n".join(lines)


def compare(expected: str, path: Path) -> int:
    actual = path.read_text(encoding="utf-8") if path.is_file() else ""
    if actual == expected:
        return 0
    sys.stderr.write(
        "".join(
            difflib.unified_diff(
                actual.splitlines(True), expected.splitlines(True),
                fromfile=str(path), tofile="regenerated",
            )
        )
    )
    return 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail if either artifact is stale")
    arguments = parser.parse_args()
    started = time.perf_counter()
    rows, payload = load_triples()
    if not rows:
        raise SystemExit("no reviewed coding carries a full triple; nothing to generate")
    inferences = render_inferences(rows, payload)
    # The sweep reads the inference file through defeasible_inference, so it has
    # to be on disk in its regenerated form before the classifier runs.
    previous = INFERENCES.read_text(encoding="utf-8") if INFERENCES.is_file() else None
    INFERENCES.write_text(inferences, encoding="utf-8")
    try:
        discovered, crosstalk = run_sweep(rows)
        verify_known_good_cases(rows)
        cache = render_cache(discovered, crosstalk, rows, payload)
    except BaseException:
        if arguments.check and previous is not None:
            INFERENCES.write_text(previous, encoding="utf-8")
        raise
    elapsed = time.perf_counter() - started
    kinds = Counter(kind for _set_text, kind in discovered)
    crosstalk_total = sum(count for _identifier, count in crosstalk)
    summary = (
        f"error-rule incompatibility {'current' if arguments.check else 'written'}: "
        f"triples={len(rows)}; discovered={len(discovered)}; "
        f"emergent={kinds.get('emergent', 0)}; defeated={kinds.get('defeated', 0)}; "
        f"crosstalk_defeats={crosstalk_total}; "
        f"known_good_emergent_cases={len(known_good_cases(rows))}; "
        f"wall_seconds={elapsed:.1f}"
    )
    if arguments.check:
        if previous is not None:
            INFERENCES.write_text(previous, encoding="utf-8")
        if compare(inferences, INFERENCES) or compare(cache, CACHE):
            return 1
        print(summary)
        return 0
    CACHE.write_text(cache, encoding="utf-8")
    print(summary)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
