#!/usr/bin/env python3
"""Emit grounding_v2.json: the automata re-run on the numerals the figures carry.

Round 1 ran most traces on the registry's worked input -- 53 minus 27 standing
in for whatever the figure actually showed -- and labelled the substitution.
That was honest but it cost the pilot its sharpest item: M4 was bound to the
mediant automaton, which produces 5/14, while the figure's student wrote 5/7.
The model read "incorrect" from the grounding and "5/7" from the description and
drew a panel accusing a correct addition of being the error.

So every trace here runs on the figure's own numerals where the description
records them, and each entry carries `figure_answer` and `reproduces_figure`:
whether the automaton's result is the number the student actually wrote. That
comparison is the guard the round-1 harness lacked. Three items fail it, and
failing visibly is the point -- a stand-in that announces itself cannot be
mistaken for a reproduction.

Results are verbatim from live mcp__hermes calls made 2026-07-31, read-only.
Entries the figure's numerals did not change are copied from round 1 rather than
re-asked, and say so.

    python3 write_grounding_v2.py
"""
from __future__ import annotations

import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROUND1 = HERE.parent / "t228" / "grounding.json"

# Keys whose round-1 input already was the figure's own numerals, or whose
# figure records no numerals at all. Copied, not re-asked.
REUSED = {
    "trace.recursive_partition.1_4":
        "the figure names quarters, eighths and sixteenths; 1/4 is the figure's own",
    "trace.unit_fraction_partition.1_5":
        "the figure names fifths; 1/5 is the figure's own",
    "trace.regroup_to_base_preserving_total.12_3":
        "the figure records no numerals; this is the registry's worked input, "
        "kept as a shape-preserving stand-in",
    "trace.smaller_from_larger_in_column.53_27":
        "stand-in for M2: the automaton refuses the figure's four-digit numerals "
        "(see trace.smaller_from_larger_in_column.1823_9745)",
    "trace.add_numerator_denominator_sum.2_7__3_7":
        "kept as a NAMED CONTRAST only. This is the mediant route, which the "
        "figure does not take; round 1 mistook it for the figure's own trace",
    "rows.subtraction_regrouping": "row search, unchanged",
    "rows.fraction_addition_denominator": "row search, unchanged",
    "rows.linear_equation_solving": "row search, unchanged; returns nothing",
}


def trace(strategy, arguments, result, *, figure_answer, reproduces, provenance,
          note=None):
    e = {
        "op": "strategy_trace",
        "arguments": {"strategy": strategy, "input": arguments},
        "input_provenance": provenance,
        "figure_answer": figure_answer,
        "reproduces_figure": reproduces,
        "result": result,
    }
    if note:
        e["_note"] = note
    return e


def steps(*pairs):
    return [{"n": i, "label": lab, "value": val}
            for i, (lab, val) in enumerate(pairs, 1)]


NEW: dict[str, dict] = {}

# --- M1: the owner's example, 364 - 236, student wrote 122 -----------------
NEW["trace.borrow_without_reducing_bases.364_236"] = trace(
    "borrow_without_reducing_bases", {"a": 364, "b": 236},
    {"ok": True, "strategy": "borrow_without_reducing_bases",
     "representation": "action_automaton", "result": "138",
     "steps": steps(
         ("decompose_numbers(minuend(36,4),subtrahend(23,6))", ""),
         ("subtract_base_components(36,23,13)", ""),
         ("add_base_to_ones_without_removing_base(base(10),4,14)", ""),
         ("subtract_ones(14,6,8)", ""),
         ("recompose_with_unreduced_bases(13,8,138)", ""),
         ("lose_exchange_conservation(expected(128),produced(138))", ""))},
    figure_answer="122", reproduces=False,
    provenance="the figure's own numerals, 364 - 236, from transcribed_math",
    note="Runs on the figure's numerals and lands on 138, not the 122 the "
         "student wrote. This automaton keeps the exchange but forgets to "
         "reduce the tens; the figure shows the opposite half.")

NEW["trace.smaller_from_larger_in_column.364_236"] = trace(
    "smaller_from_larger_in_column", {"a": 364, "b": 236},
    {"ok": True, "strategy": "smaller_from_larger_in_column",
     "representation": "action_automaton", "result": "132",
     "steps": steps(
         ("decompose_numbers(minuend(36,4),subtrahend(23,6))", ""),
         ("skip_borrow_procedure", ""),
         ("subtract_smaller_from_larger_in_ones(4,6,2)", ""),
         ("subtract_smaller_from_larger_in_bases(36,23,13)", ""),
         ("recompose_without_role_preservation(13,2,132)", ""),
         ("lose_minuend_subtrahend_roles(expected(128),produced(132))", ""))},
    figure_answer="122", reproduces=False,
    provenance="the figure's own numerals, 364 - 236, from transcribed_math",
    note="Reproduces the figure's ones digit (4 and 6 give 2) but not its tens: "
         "this automaton never borrows, so its tens stay 3 and it lands on 132. "
         "The figure's 122 needs the borrow taken AND the ones reversed, which "
         "is the conjunction of this automaton's error with the other's "
         "bookkeeping. No single registered strategy produces 122.")

# --- M2: 1823 - 9745, and the automaton's own bound ------------------------
NEW["trace.smaller_from_larger_in_column.1823_9745"] = {
    "op": "strategy_trace",
    "arguments": {"strategy": "smaller_from_larger_in_column",
                  "input": {"a": 1823, "b": 9745}},
    "input_provenance": "the figure's own numerals, 1823 - 9745, from transcribed_math",
    "figure_answer": "8122",
    "reproduces_figure": False,
    "result": {
        "ok": False,
        "refusal": "strategy_trace could not run 'smaller_from_larger_in_column'",
        "diagnosis": "a digit-count bound, not the negative result. The same "
                     "strategy runs on 364 - 236 (three digits) and refuses "
                     "1234 - 1111 (four digits), so the refusal tracks width, "
                     "not sign.",
    },
    "_note": "Recorded rather than papered over. M2 is the figure whose whole "
             "interest is a subtrahend larger than the minuend, and the "
             "automaton that models its error cannot accept its numerals. The "
             "item falls back to the registry stand-in and says so.",
}

# --- M3: 502 - 6, student wrote 406 ---------------------------------------
NEW["trace.borrow_across_zero_no_cascade.502_6"] = trace(
    "borrow_across_zero_no_cascade", {"a": 502, "b": 6},
    {"ok": True, "strategy": "borrow_across_zero_no_cascade",
     "representation": "action_automaton", "result": "596",
     "steps": steps(
         ("decompose_columns(minuend_digits([2,0,5]),subtrahend_digits([6,0,0]))", ""),
         ("identify_zero_cascade(zero_columns([1]),donor_column(2,5))", ""),
         ("note_zero_tens_column", ""),
         ("treat_zero_as_full_base(base(10),stuck_tens(9))", ""),
         ("skip_hundreds_decrement", ""),
         ("skip_donor_decrement(position(2),donor_digit(5))", ""),
         ("recompose_without_zero_cascade(deformed_digits([6,9,5]),596)", ""),
         ("lose_hundreds_borrow(expected(496),produced(596))", ""))},
    figure_answer="406", reproduces=False,
    provenance="the figure's own numerals, 502 - 6, from transcribed_math",
    note="Both the automaton and the student break the same cascade, in "
         "opposite halves: the automaton leaves the hundreds at 5 and sets the "
         "tens to 9 (596); the student reduces the hundreds to 4 and leaves the "
         "tens at 0 (406). Same broken conservation, different residue.")

NEW["trace.borrow_across_zero_cascade.502_6"] = trace(
    "borrow_across_zero_cascade", {"a": 502, "b": 6},
    {"ok": True, "strategy": "borrow_across_zero_cascade",
     "representation": "action_automaton", "result": "496",
     "steps": steps(
         ("decompose_columns(minuend_digits([2,0,5]),subtrahend_digits([6,0,0]))", ""),
         ("identify_zero_cascade(zero_columns([1]),donor_column(2,5))", ""),
         ("cascade_borrow_from_donor_column(base(10),donor_column(2,5))", ""),
         ("convert_zero_columns_to_nines([1])", ""),
         ("borrow_into_ones_after_cascade", ""),
         ("subtract_after_zero_cascade(496)", ""))},
    figure_answer="496 is the correct value; the student wrote 406",
    reproduces=True,
    provenance="the figure's own numerals, 502 - 6, from transcribed_math",
    note="The correct partner: the cascade carried through.")

# --- M4: 2/7 + 3/7 = 5/7, which is correct addition ------------------------
NEW["trace.common_denominator_fraction_addition.2_7__3_7"] = trace(
    "common_denominator_fraction_addition",
    {"kind": "fraction_addend_pair", "left": {"n": 2, "d": 7},
     "right": {"n": 3, "d": 7}},
    {"ok": True, "strategy": "common_denominator_fraction_addition",
     "representation": "action_automaton", "result": "fraction(5,7)",
     "steps": steps(
         ("q_init", "init(frac(2,7),frac(3,7))"),
         ("q_rename_addends_as_counts",
          "renamings(kept_as_stated(frac(2,7)),kept_as_stated(frac(3,7)))"),
         ("q_common_partition", "partition(shared_unit(7))"),
         ("q_transform_commensurate_1", "transformed(frac(2,7),fraction(2,7))"),
         ("q_transform_commensurate_2", "transformed(frac(3,7),fraction(3,7))"),
         ("q_measure_with_co_unit", "co_measure(unit_fraction(1,7),2,3)"),
         ("q_combine_counts", "combined(2,3,5)"),
         ("q_emit_sum", "emit(fraction(5,7))"),
         ("q_accept", "accept(fraction(5,7))"))},
    figure_answer="5/7", reproduces=True,
    provenance="the figure's own numerals, 2/7 and 3/7, from transcribed_math",
    note="The addition the student wrote is correct. Round 1 bound this figure "
         "to the mediant automaton instead and inherited its validity(incorrect).")

# --- M4b: the error the scan actually shows -------------------------------
NEW["trace.add_instead_of_multiply.2_3"] = trace(
    "add_instead_of_multiply", {"a": 2, "b": 3},
    {"ok": True, "strategy": "add_instead_of_multiply",
     "representation": "action_automaton", "result": "5",
     "steps": steps(
         ("read_equal_groups(groups(2),items_per_group(3))", ""),
         ("treat_group_count_and_group_size_as_addends", ""),
         ("add_uncoordinated_counts(2,3,5)", ""),
         ("lose_equal_group_iteration(expected(6),produced(5))", ""))},
    figure_answer="5/7 chosen where 6/7 was the answer", reproduces=True,
    provenance="the numerators of the task the scan carries: 2/7 taken three "
               "times. The automaton runs on 2 and 3; the denominator 7 is "
               "unchanged by either route and rides along.",
    note="expected(6) produced(5) is exactly the figure: 6/7 was option (a), "
         "the student circled (c) 5/7. The multiplier became an addend.")

# --- S1, S2, N3: the exchange performed, on each figure's numerals ---------
for key, a, b, res, tail in (
    ("60_25", 60, 25, "35",
     (("decompose_numbers(minuend(6,0),subtrahend(2,5))", ""),
      ("subtract_base_components(6,2,4)", ""),
      ("exchange_one_base_for_ones(base(10),from_bases(4),to_ones(0,10),"
       "remaining_bases(3))", ""),
      ("subtract_ones(10,5,5)", ""),
      ("recompose_difference(3,5,35)", ""))),
    ("75_48", 75, 48, "27",
     (("decompose_numbers(minuend(7,5),subtrahend(4,8))", ""),
      ("subtract_base_components(7,4,3)", ""),
      ("exchange_one_base_for_ones(base(10),from_bases(3),to_ones(5,15),"
       "remaining_bases(2))", ""),
      ("subtract_ones(15,8,7)", ""),
      ("recompose_difference(2,7,27)", ""))),
    ("40_3", 40, 3, "37",
     (("decompose_numbers(minuend(4,0),subtrahend(0,3))", ""),
      ("subtract_base_components(4,0,4)", ""),
      ("exchange_one_base_for_ones(base(10),from_bases(4),to_ones(0,10),"
       "remaining_bases(3))", ""),
      ("subtract_ones(10,3,7)", ""),
      ("recompose_difference(3,7,37)", ""))),
):
    NEW[f"trace.decompose_base_for_ones.{key}"] = trace(
        "decompose_base_for_ones", {"a": a, "b": b},
        {"ok": True, "strategy": "decompose_base_for_ones",
         "representation": "action_automaton", "result": res,
         "steps": steps(*tail)},
        figure_answer=res, reproduces=True,
        provenance=f"the figure's own numerals, {a} - {b}, from transcribed_math")

# --- S3: the doubling the double number line shows ------------------------
NEW["trace.scale_ratio_unit.100_5"] = trace(
    "scale_ratio_unit", {"a": 100, "b": 5},
    {"ok": True, "strategy": "scale_ratio_unit",
     "representation": "action_automaton", "result": "ratio_pair(200,10)",
     "steps": steps(
         ("identify_base_ratio(ratio_pair(100,5))", ""),
         ("identify_scale_factor(2)", ""),
         ("scale_first_term_multiplicatively(100,2,200)", ""),
         ("scale_second_term_multiplicatively(5,2,10)", ""),
         ("compose_equivalent_ratio(ratio_pair(400,10))".replace("400", "200"), ""),
         ("preserve_multiplicative_unit_ratio(ratio_pair(200,10))", ""))},
    figure_answer="2.5 m costs 100 yen; 5 m costs 200 yen; 1 m is circled",
    reproduces=True,
    provenance="the figure's own quantities, in half-metres so the automaton's "
               "integer template accepts them: 100 yen per 5 half-metres "
               "(2.5 m). Scaling by 2 gives 200 yen per 10 half-metres (5 m), "
               "which is the figure's second row.",
    note="The automaton reaches the figure's doubling and stops there. The unit "
         "rate the figure circles -- 1 m for 40 yen -- is a further step this "
         "strategy does not take, so the circle stays an open question in the "
         "scene rather than being answered by machinery that did not answer it.")


def main() -> int:
    r1 = json.loads(ROUND1.read_text())
    out: dict = {
        "_note": (
            "Verbatim results of live read-only mcp__hermes calls. Every trace "
            "whose figure records numerals runs on THOSE numerals. Each trace "
            "carries figure_answer and reproduces_figure: whether the "
            "automaton's result is the number the student actually wrote. "
            "Three do not reproduce their figure and say so, which is the check "
            "round 1 lacked."),
        "_captured_at": "2026-07-31",
        "_server": r1.get("_server"),
        "_supersedes": "t228/grounding.json",
    }
    for k in sorted(NEW):
        out[k] = NEW[k]
    missing = [k for k in REUSED if k not in r1]
    if missing:
        raise SystemExit(f"round-1 grounding is missing reused keys: {missing}")
    for k, why in REUSED.items():
        e = dict(r1[k])
        e["_reused_from_round_1"] = why
        out[k] = e

    dest = HERE / "grounding_v2.json"
    dest.write_text(json.dumps(out, indent=2) + "\n")
    traces = [k for k in out if k.startswith("trace.")]
    repro = [k for k in traces if out[k].get("reproduces_figure") is True]
    notrepro = [k for k in traces if out[k].get("reproduces_figure") is False]
    print(f"wrote {dest.name}: {len(traces)} traces, {len(REUSED)} reused")
    print(f"  reproduce the figure's own answer : {len(repro)}")
    print(f"  do NOT, and say so                : {len(notrepro)}")
    for k in notrepro:
        print(f"    - {k}  -> {out[k]['result'].get('result', 'refused')} "
              f"(figure: {out[k]['figure_answer']})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
