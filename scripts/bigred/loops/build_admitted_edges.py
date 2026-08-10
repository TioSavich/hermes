#!/usr/bin/env python3
"""Build and check the tracked wave-1 admitted crisis-release store.

The admission decision is mechanical over the docket's L2 rows.  This tool
applies the ceremony's same-question source rule and evidence bar, checks the
fixed wave arithmetic, and renders the resulting Prolog facts.  It does not
read collected Big Red shards or admit any candidate outside the docket.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[3]
DOCKET = ROOT / "docs/research/internal/2026-08-09-admission-docket.json"
STORE = ROOT / "scripts/bigred/loops/admitted_edges.pl"
PATHS = ROOT / "paths.pl"
WAVE = "2026-08-09-wave1"
DOCKET_CITATION = "docs/research/internal/2026-08-09-admission-docket.json"
CEREMONY_CITATION = (
    "plans/2026-08-09-admission-ceremony-wave1-draft.md"
)

# The ceremony draft excludes seven fraction sources because they answer a
# product, quotient, or sum question.  These are the four remaining authored
# fraction-comparison sources, and therefore the only fraction sources that
# pass its same-question test in wave 1.
FRACTION_COMPARISON_SOURCES = {
    "area_model_fraction_comparison",
    "area_model_unequal_partition_piece_count",
    "set_model_fraction_comparison",
    "set_model_subset_size_focus",
}

EXPECTED_RECEIVER_COUNTS = {
    "dropped_ones_chunk": 9,
    "unbalanced_make_base_compensation": 9,
    "number_line_count_marks_not_intervals": 4,
    "add_numerator_denominator_comparison": 4,
    "gap_thinking_fraction_comparison": 4,
    "stop_after_one_known_fact": 3,
    "append_column_sum_without_carrying": 1,
}

# Authored success conditions, copied from each receiver's action-pair clause.
# The source check below prevents a renamed or removed atom from silently
# surviving in the admitted store.
RECEIVER_CONDITIONS = {
    ("addition", "dropped_ones_chunk"): (
        "decomposed_addend_has_no_ones_chunk",
        ROOT / "knowledge/strategies/math/sar_add_action_pairs.pl",
    ),
    ("addition", "unbalanced_make_base_compensation"): (
        "selected_addend_already_at_target_base",
        ROOT / "knowledge/strategies/math/sar_add_action_pairs.pl",
    ),
    ("fraction", "number_line_count_marks_not_intervals"): (
        "mark_count_order_agrees_with_interval_measure",
        ROOT / "knowledge/strategies/math/fraction_action_pairs.pl",
    ),
    ("fraction", "add_numerator_denominator_comparison"): (
        "numerator_denominator_sum_order_agrees_with_common_unit_order",
        ROOT / "knowledge/strategies/math/fraction_action_pairs.pl",
    ),
    ("fraction", "gap_thinking_fraction_comparison"): (
        "gap_order_coincides_with_fraction_order",
        ROOT / "knowledge/strategies/math/smr_frac_benchmark_compare.pl",
    ),
    ("division", "stop_after_one_known_fact"): (
        "first_known_fact_completes_quotient_and_remainder",
        ROOT / "knowledge/strategies/math/smr_div_action_pairs.pl",
    ),
    ("addition", "append_column_sum_without_carrying"): (
        "raw_column_concatenation_preserves_place_value",
        ROOT / "knowledge/strategies/math/sar_add_action_pairs.pl",
    ),
}


class AdmissionError(RuntimeError):
    """The docket, authored conditions, or store disagrees with the ruling."""


def same_question(row: dict[str, Any]) -> bool:
    """Apply the ceremony's authored same-question source set for wave 1.

    The ceremony names the four fraction-comparison sources below.  Addition
    and division sources were verified as same-question during review.  The
    pinned EXPECTED_RECEIVER_COUNTS make any drift in the docket fail loudly.
    """
    source = row["source"]
    target = row["target"]
    if source["family"] != target["family"]:
        return False
    if source["family"] == "fraction":
        return source["kind"] in FRACTION_COMPARISON_SOURCES
    return source["family"] in {"addition", "division"}


def clears_bar(row: dict[str, Any]) -> bool:
    """Apply the authored wave-1 correct-or-contextually-correct evidence bar."""
    released = int(row["released_count"])
    counts = row["released_validity_counts"]
    correct = int(counts.get("correct", 0))
    contextually_correct = int(counts.get("contextually_correct", 0))
    clears = correct + contextually_correct
    return clears >= 100 or (
        clears >= 25
        and released > 0
        and clears / released >= 0.80
    )


def admitted_rows(docket: dict[str, Any]) -> list[dict[str, Any]]:
    """Derive wave-1 admissions and enforce the ceremony's exact arithmetic."""
    rows = [
        row
        for row in docket["r2_docket"]
        if row.get("band") == "L2" and same_question(row) and clears_bar(row)
    ]
    rows.sort(
        key=lambda row: (
            row["target"]["family"],
            row["target"]["kind"],
            row["source"]["family"],
            row["source"]["kind"],
        )
    )

    receiver_counts = Counter(row["target"]["kind"] for row in rows)
    if len(rows) != 34 or receiver_counts != Counter(EXPECTED_RECEIVER_COUNTS):
        raise AdmissionError(
            "mechanical admission does not match the ceremony table: "
            f"rows={len(rows)}, receivers={dict(sorted(receiver_counts.items()))}"
        )

    pairs = [
        (
            row["source"]["family"],
            row["source"]["kind"],
            row["target"]["family"],
            row["target"]["kind"],
        )
        for row in rows
    ]
    if len(pairs) != len(set(pairs)):
        raise AdmissionError("mechanical admission contains duplicate directed pairs")

    for row in rows:
        counts = row["released_validity_counts"]
        accounted = sum(int(value) for value in counts.values())
        if accounted != int(row["released_count"]):
            raise AdmissionError(
                "released validity counts do not sum to released_count for "
                f"{row['source']} -> {row['target']}"
            )
        if not row.get("released_witnesses"):
            raise AdmissionError(
                f"admitted row has no retained witnesses: {row['source']} -> "
                f"{row['target']}"
            )
        flags = row.get("lens_flags") or {}
        if flags.get("l2") is not True or flags.get("l3") is True:
            raise AdmissionError(
                f"wave-1 admission is not L2-only: {row['source']} -> "
                f"{row['target']}"
            )
    return rows


def prolog_atom(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "''") + "'"


def prolog_value(value: Any, *, dict_tag: str = "_") -> str:
    if isinstance(value, dict):
        fields = ", ".join(
            f"{key}:{prolog_value(item)}" for key, item in sorted(value.items())
        )
        return f"{dict_tag}{{{fields}}}"
    if isinstance(value, list):
        return "[" + ", ".join(prolog_value(item) for item in value) + "]"
    if isinstance(value, str):
        return prolog_atom(value)
    if value is True:
        return "true"
    if value is False:
        return "false"
    if value is None:
        return "null"
    if isinstance(value, (int, float)):
        return repr(value)
    raise TypeError(f"cannot render Prolog value {value!r}")


def verify_condition_atoms() -> None:
    """Check every tracked receiver-condition mapping against authored source."""
    for receiver in sorted(RECEIVER_CONDITIONS):
        atom, source = RECEIVER_CONDITIONS[receiver]
        text = source.read_text(encoding="utf-8")
        if not re.search(rf"\b{re.escape(atom)}\b", text):
            raise AdmissionError(
                f"condition atom {atom} is absent from {source.relative_to(ROOT)}"
            )


def render_store(rows: list[dict[str, Any]]) -> str:
    header = """/** <module> Ceremony-admitted learner-path edges
 *
 * Admission licenses only the coincidence sub-region cited by each row.  It
 * does not license the receiver over its full domain.  Rejected candidates
 * seed nothing: only facts in this store extend admitted reachability.
 *
 * Generated mechanically by scripts/bigred/loops/build_admitted_edges.py from
 * the cited admission docket under the cited ceremony draft.  One dated block
 * records one admission wave.
 */

:- module(admitted_edges,
          [ crisis_release/8,
            admitted_edge_dict/1,
            registered_machine/2
          ]).

:- use_module(math(action_automata_registry),
              [ action_automaton_signature/4 ]).

registered_machine(Family, Kind) :-
    action_automaton_signature(Family, Kind, _Input, _Output).

admitted_edge_dict(_{
        edge_type:crisis_release,
        source:_{family:SourceFamily, kind:SourceKind},
        target:_{family:TargetFamily, kind:TargetKind},
        released_region:_{
            released_count:ReleasedCount,
            contextually_correct_count:ContextuallyCorrectCount,
            incorrect_count:IncorrectCount,
            first_witness:FirstWitness,
            last_witness:LastWitness
        },
        condition:Condition,
        lens:Lens,
        wave:Wave,
        provenance:_{docket:Docket, ceremony_draft:CeremonyDraft},
        mua_type:MuaType
    }) :-
    crisis_release(
        source(SourceFamily, SourceKind),
        target(TargetFamily, TargetKind),
        released_region(
            released_count(ReleasedCount),
            contextually_correct_count(ContextuallyCorrectCount),
            incorrect_count(IncorrectCount),
            first_witness(FirstWitness),
            last_witness(LastWitness)
        ),
        condition(Condition),
        lens(Lens),
        wave(Wave),
        provenance(docket(Docket), ceremony_draft(CeremonyDraft)),
        mua_type(MuaType)
    ).

% ---------------------------------------------------------------------------
% Admission wave 2026-08-09-wave1
% ---------------------------------------------------------------------------
"""
    facts: list[str] = []
    for row in rows:
        source = row["source"]
        target = row["target"]
        counts = row["released_validity_counts"]
        witnesses = row["released_witnesses"]
        condition, _source_path = RECEIVER_CONDITIONS[
            (target["family"], target["kind"])
        ]
        fact = f"""crisis_release(
    source({prolog_atom(source['family'])}, {prolog_atom(source['kind'])}),
    target({prolog_atom(target['family'])}, {prolog_atom(target['kind'])}),
    released_region(
        released_count({int(row['released_count'])}),
        contextually_correct_count({int(counts.get('contextually_correct', 0))}),
        incorrect_count({int(counts.get('incorrect', 0))}),
        first_witness({prolog_value(witnesses[0]['input'], dict_tag='input')}),
        last_witness({prolog_value(witnesses[-1]['input'], dict_tag='input')})
    ),
    condition({prolog_atom(condition)}),
    lens(l2),
    wave({prolog_atom(WAVE)}),
    provenance(
        docket({prolog_atom(DOCKET_CITATION)}),
        ceremony_draft({prolog_atom(CEREMONY_CITATION)})
    ),
    mua_type(untyped)
)."""
        facts.append(fact)
    return header + "\n\n".join(facts) + "\n"


def swipl_check() -> tuple[list[dict[str, str]], list[str]]:
    goal = (
        "use_module(library(http/json)),"
        "findall(_{source_family:SF,source_kind:SK,target_family:TF,"
        "target_kind:TK,condition:C},"
        "admitted_edges:crisis_release(source(SF,SK),target(TF,TK),_,"
        "condition(C),_,_,_,_),Rows),"
        "findall(F/K,(admitted_edges:crisis_release(_,target(F,K),_,_,_,_,_,_),"
        "\\+action_automata_registry:action_automaton_pair(F,_,K,_)),Missing),"
        "json_write_dict(current_output,_{rows:Rows},[width(0)]),nl,"
        "format('~q\\n',[Missing])"
    )
    completed = subprocess.run(
        [
            "swipl",
            "-q",
            "-l",
            str(PATHS),
            "-s",
            str(STORE),
            "-g",
            goal,
            "-t",
            "halt",
        ],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode:
        raise AdmissionError(
            "admitted store failed to load: "
            f"{completed.stderr.strip()[:1000]}"
        )
    lines = [line.strip() for line in completed.stdout.splitlines() if line.strip()]
    if len(lines) < 2 or not lines[-2].startswith("{"):
        raise AdmissionError(f"unexpected SWI-Prolog check output: {lines}")
    rows = json.loads(lines[-2])["rows"]
    missing = [] if lines[-1] == "[]" else [lines[-1]]
    return rows, missing


def verify_tracked_store() -> Counter[str]:
    """Validate assertions available from tracked files alone."""
    if not STORE.is_file():
        raise AdmissionError(f"tracked store is absent: {STORE}")

    rows, missing_receivers = swipl_check()
    if len(rows) != 34:
        raise AdmissionError(f"Prolog store exposes {len(rows)} rows, expected 34")

    pairs = [
        (
            row["source_family"],
            row["source_kind"],
            row["target_family"],
            row["target_kind"],
        )
        for row in rows
    ]
    if len(pairs) != len(set(pairs)):
        raise AdmissionError("Prolog store contains duplicate directed pairs")
    if missing_receivers:
        raise AdmissionError(
            "receiver is not a registered deformation: "
            + ", ".join(missing_receivers)
        )

    store_receivers = {
        (row["target_family"], row["target_kind"]) for row in rows
    }
    missing_mapping = store_receivers - set(RECEIVER_CONDITIONS)
    if missing_mapping:
        raise AdmissionError(
            "receiver has no authored condition mapping: "
            f"{sorted(missing_mapping)}"
        )
    for row in rows:
        receiver = (row["target_family"], row["target_kind"])
        expected_condition, _source = RECEIVER_CONDITIONS[receiver]
        if row["condition"] != expected_condition:
            raise AdmissionError(
                "store condition disagrees with tracked receiver mapping for "
                f"{receiver}: {row['condition']} != {expected_condition}"
            )

    verify_condition_atoms()
    receiver_counts = Counter(row["target_kind"] for row in rows)
    if receiver_counts != Counter(EXPECTED_RECEIVER_COUNTS):
        raise AdmissionError(
            "tracked store receiver distribution disagrees with the ceremony: "
            f"{dict(sorted(receiver_counts.items()))}"
        )
    return receiver_counts


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help=(
            "validate the tracked store and, when the local docket exists, "
            "compare it with a fresh mechanical rendering"
        ),
    )
    args = parser.parse_args()

    docket_checked = False
    if DOCKET.is_file():
        docket = json.loads(DOCKET.read_text(encoding="utf-8"))
        rows = admitted_rows(docket)
        rendered = render_store(rows)
        if args.check:
            if not STORE.is_file():
                raise AdmissionError(f"tracked store is absent: {STORE}")
            if STORE.read_text(encoding="utf-8") != rendered:
                raise AdmissionError(
                    "tracked store differs from the mechanical docket rendering; "
                    "run scripts/bigred/loops/build_admitted_edges.py"
                )
        else:
            STORE.write_text(rendered, encoding="utf-8")
        docket_checked = True
    elif args.check:
        print(
            "SKIP admitted_edges docket re-derivation: "
            f"{DOCKET_CITATION} is local runtime and is absent"
        )
    else:
        raise AdmissionError(
            "cannot regenerate admitted_edges.pl without the local runtime "
            f"docket: {DOCKET_CITATION}"
        )

    receiver_counts = verify_tracked_store()
    print(
        "PASS admitted_edges: 34 "
        + ("docket-matched " if docket_checked else "tracked-store ")
        + "rows; no duplicate directed "
        "pairs; every receiver is a registered deformation"
    )
    print(
        "PASS receiver distribution: "
        + ", ".join(
            f"{kind}={receiver_counts[kind]}"
            for kind in EXPECTED_RECEIVER_COUNTS
        )
    )
    print("PASS authored conditions: 7 receiver atoms remain present in source")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AdmissionError, KeyError, ValueError, OSError) as error:
        print(f"FAIL admitted_edges: {error}", file=sys.stderr)
        raise SystemExit(1)
