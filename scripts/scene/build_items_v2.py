#!/usr/bin/env python3
"""Join the manifest rows to the corrected grounding and build prompt v3.

Three changes from round 1, each one traceable to something the owner or the
scan caught.

1. Grounding runs on the figure's own numerals, and every trace declares whether
   it reaches the number the student actually wrote.

2. M4 is split. The pipeline's description of the Sahin figure records only the
   student's written line, 2/7 + 3/7 = 5/7, which is a correct like-denominator
   addition. The scan shows the rest: the printed task asks for 2/7 taken three
   times, the options are 6/7, 23/7, 5/7, 8/7, and the student circled 5/7. The
   error is a multiplier read as an addend, and it lives entirely in the task
   stem the description dropped. So M4 keeps its pipeline description untouched
   and moves to the strategy band, where what it says is true; M4B carries the
   stem restored by hand and is the only item in the set whose description did
   not come from the pipeline. The pair measures the thing the round-1 failure
   raised: whether the model draws the right error when the description carries
   the task.

3. Bands follow what each description actually supports, so no item asks for an
   error its input does not contain.

    python3 build_items_v2.py
"""
from __future__ import annotations

import json
from pathlib import Path

from prompt_v3 import build_prompt

HERE = Path(__file__).resolve().parent
ROUND1_ITEMS = HERE.parent / "t228" / "items" / "items.jsonl"
GROUNDING = HERE / "grounding_v2.json"
DEST = HERE / "items" / "items.jsonl"

# item id -> (band, grounding keys, selected_because)
WIRING: dict[str, tuple[str, list[str], str]] = {
    "M1": ("misconception",
           ["trace.borrow_without_reducing_bases.364_236",
            "trace.smaller_from_larger_in_column.364_236",
            "rows.subtraction_regrouping"],
           "the owner's example, 364 - 236 with the student writing 122. Both "
           "registered automata now run on those numerals and neither reaches "
           "122: the figure needs the borrow taken AND the ones reversed, which "
           "no single strategy in the registry does."),
    "M2": ("misconception",
           ["trace.smaller_from_larger_in_column.1823_9745",
            "trace.smaller_from_larger_in_column.53_27",
            "rows.subtraction_regrouping"],
           "borrowing refused outright, with a subtrahend larger than the "
           "minuend. The automaton that models the error will not accept the "
           "figure's four-digit numerals, so the refusal is passed to the model "
           "beside a two-digit stand-in."),
    "M3": ("misconception",
           ["trace.borrow_across_zero_no_cascade.502_6",
            "trace.borrow_across_zero_cascade.502_6"],
           "borrowing across a zero. The automaton and the student break the "
           "same cascade in opposite halves -- 596 against the figure's 406 -- "
           "and the correct partner, 496, is grounded beside it."),
    "M4": ("strategy",
           ["trace.common_denominator_fraction_addition.2_7__3_7",
            "rows.fraction_addition_denominator"],
           "the line the pipeline's description records, 2/7 + 3/7 = 5/7, is a "
           "correct like-denominator addition, and the description names no "
           "error. Round 1 filed this as a misconception and bound it to the "
           "mediant automaton, which reaches 5/14; the model then drew the "
           "student's correct answer as the error. Here the item says only what "
           "its description supports."),
    "M4B": ("misconception",
            ["trace.add_instead_of_multiply.2_3",
             "trace.common_denominator_fraction_addition.2_7__3_7",
             "rows.fraction_addition_denominator"],
            "the same figure with the task stem restored from the scan. The "
            "printed question asks for 2/7 taken three times; the student "
            "circled 5/7 and justified it by adding. The error is the "
            "multiplier becoming an addend, and it is invisible without the "
            "stem. The only hand-written description in the set, and it is "
            "marked as such."),
    "M5": ("misconception", ["rows.linear_equation_solving"],
           "an item whose grounding lane abstains: the row search returns "
           "nothing and the model is given the empty result rather than a "
           "near-miss row."),
    "S1": ("strategy", ["trace.decompose_base_for_ones.60_25"],
           "the correct partner to M1 and M2: 60 broken into 50 and 10 so the "
           "ones can be taken. The automaton reaches the figure's own 35."),
    "S2": ("strategy", ["trace.decompose_base_for_ones.75_48"],
           "the same exchange carried by blocks rather than digits. The "
           "automaton reaches the figure's own 27."),
    "S3": ("strategy", ["trace.scale_ratio_unit.100_5"],
           "a double number line. The automaton reaches the doubling the figure "
           "shows and stops short of the unit rate the figure circles, which is "
           "left open rather than answered by machinery that did not answer it."),
    "S4": ("strategy", ["trace.recursive_partition.1_4"],
           "partitioning applied to its own output: quarters into eighths into "
           "sixteenths."),
    "N1": ("notation", ["trace.regroup_to_base_preserving_total.12_3"],
           "the bare place-value claim, five ten-rods and four unit-cubes "
           "asserting 54. The figure records no numerals, so the grounding is "
           "the registry's worked input and says so."),
    "N2": ("notation", ["trace.regroup_to_base_preserving_total.12_3"],
           "the same claim with a rod left partly marked. No numerals recorded; "
           "the grounding is a labelled stand-in."),
    "N3": ("notation", ["trace.decompose_base_for_ones.40_3",
                        "rows.subtraction_regrouping"],
           "a place-value chart where the notation and the exchange are one "
           "act. The automaton reaches the figure's own 37."),
    "N4": ("notation", ["trace.unit_fraction_partition.1_5"],
           "fraction bars asserting that a fifth cut five ways names a "
           "twenty-fifth."),
    "T1": ("thin", [],
           "one clause about a drawn trapezoid, with nothing for the grounding "
           "lane to bind. A control: the band is expected to fail."),
    "T2": ("thin", [],
           "polyominoes on a dot grid; the description names shapes and no "
           "mathematics. A control."),
}

# What the model is NOT given, recorded for the reviewer's page only.
KNOWN_GAPS = {
    "M4": ("The scan carries a printed task stem the description drops: 'A man "
           "spent 2/7 of his money three times. What fraction of money a man "
           "spent?' with options 6/7, 23/7, 5/7, 8/7, and 5/7 circled. The "
           "figure's real error -- three times read as plus 3/7 -- is not "
           "reachable from the description the model receives, and the model is "
           "not asked to find it. M4B is the same figure with the stem "
           "restored."),
    "M1": ("No registered automaton reproduces the figure's 122. The two that "
           "run on 364 - 236 reach 138 and 132."),
    "M3": ("No registered automaton reproduces the figure's 406; the deformation "
           "automaton reaches 596."),
    "M2": ("The automaton refuses the figure's numerals on a digit-count bound, "
           "so the model receives a refusal plus a two-digit stand-in."),
}

M4B_DESCRIPTION = {
    "student_strategy":
        "The printed task asks what fraction of his money a man spent if he "
        "spent 2/7 of it three times, offering 6/7, 23/7, 5/7 and 8/7. The "
        "student circled 5/7 and wrote the working 2/7 + 3/7 = 5/7 underneath.",
    "transcribed_math":
        "A man spent 2/7 of his money three times. What fraction of money a man "
        "spent?  a. 6/7   b. 23/7   c. 5/7 [circled]   d. 8/7\n"
        "student's working: 2/7 + 3/7 = 5/7",
    "error_topics": ["word problems / Multiplication interpretation"],
    "strategy_topics": [],
}


def resolve(keys: list[str], grounding: dict) -> list[dict]:
    out = []
    for k in keys:
        if k not in grounding:
            raise SystemExit(f"grounding_v2.json has no key {k!r}")
        e = dict(grounding[k])
        e["_key"] = k
        out.append(e)
    return out


def main() -> int:
    grounding = json.loads(GROUNDING.read_text())
    base = {}
    for line in ROUND1_ITEMS.read_text().splitlines():
        if line.strip():
            r = json.loads(line)
            base[r["item_id"]] = r

    DEST.parent.mkdir(parents=True, exist_ok=True)
    records = []
    for iid, (band, keys, because) in WIRING.items():
        src = base[iid[:2] if iid == "M4B" else iid]
        rec = {k: v for k, v in src.items()
               if k not in ("prompt", "grounding", "grounding_keys",
                            "band", "selected_because")}
        rec["item_id"] = iid
        rec["band"] = band
        rec["selected_because"] = because
        if iid == "M4B":
            rec["description"] = M4B_DESCRIPTION
            rec["description_provenance"] = (
                "HAND-REPAIRED from the scan by the controller. Every other "
                "item's description came from the manifest's LLM pass. This one "
                "is the deliberate contrast and is not comparable to the rest.")
        else:
            rec["description_provenance"] = (
                "the asset manifest's description pass, whose generating script "
                "is not in the repository")
        rec["grounding_keys"] = keys
        rec["grounding"] = resolve(keys, grounding)
        rec["figure_reproduced_by_grounding"] = [
            {"key": g["_key"], "reproduces": g.get("reproduces_figure"),
             "automaton_result": (g["result"].get("result")
                                  if g["result"].get("ok", True)
                                  else "refused"),
             "figure_answer": g.get("figure_answer")}
            for g in rec["grounding"] if g["op"] == "strategy_trace"]
        if iid in KNOWN_GAPS:
            rec["known_gap_not_given_to_the_model"] = KNOWN_GAPS[iid]
        rec["prompt"] = build_prompt(rec)
        rec["prompt_chars"] = len(rec["prompt"])
        records.append(rec)

    with DEST.open("w") as fh:
        for r in records:
            fh.write(json.dumps(r) + "\n")

    bands: dict[str, int] = {}
    for r in records:
        bands[r["band"]] = bands.get(r["band"], 0) + 1
    lens = [r["prompt_chars"] for r in records]
    print(f"wrote {DEST} : {len(records)} items")
    print("  bands: " + ", ".join(f"{k} {v}" for k, v in sorted(bands.items())))
    print(f"  prompt length: {min(lens)}-{max(lens)} chars "
          f"(mean {sum(lens) // len(lens)})")
    nr = [(r["item_id"], f["key"], f["automaton_result"], f["figure_answer"])
          for r in records for f in r["figure_reproduced_by_grounding"]
          if f["reproduces"] is False]
    print(f"  traces that do not reproduce their figure: {len(nr)}")
    for iid, key, got, want in nr:
        print(f"    {iid}: {key.split('.')[1]} -> {got}  (figure: {want})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
