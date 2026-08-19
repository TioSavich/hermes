#!/usr/bin/env python3
"""Deterministic instantiation: fill an authored form's slots from a row's
own machine-verified steps. No model call happens here.

For every row in families a_operation_justify / b_comparison /
d_strategy_explanation (explanation_families.jsonl), find its grounding by
joining merged_admitted_ledger.jsonl and recovery_wave_ledger.jsonl on
record_id -- INCLUDING rows the census excluded because it only looked at
non-admitted rows: a row admitted in today's recovery wave carries a fully
machine-verified analysis, and an admitted analysis paired with an
explanation-shaped ask is exactly what a grounded explanation should quote.

Each candidate step is independently re-executed by step_verifier (exact
Fraction arithmetic, never trusting the ledger's own gate label). Only
steps that re-execute true ever reach an instantiated sentence. A row with
zero independently-verifiable steps is declined with reason
no_verified_grounding -- never guessed.

A row's form is chosen deterministically (a stable hash of its record_id
mod the family's accepted form count), not at random and not always the
same form -- reproducible across reruns, varied across rows.
"""
from __future__ import annotations

import argparse
import datetime as _dt
import hashlib
import json
from decimal import Decimal, getcontext
from pathlib import Path

import step_verifier as sv

getcontext().prec = 40

REPO = Path(__file__).resolve().parents[2]
COVERAGE_DIR = REPO / "hermes" / "app" / "runtime" / "experiments" / "coverage_grind"

TARGET_FAMILIES = {"a_operation_justify", "b_comparison", "d_strategy_explanation"}

# --- number formatting -------------------------------------------------


def fmt(value) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    frac = sv.to_fraction(value)
    if frac is None:
        return str(value)
    if frac.denominator == 1:
        return str(frac.numerator)
    d = frac.denominator
    while d % 2 == 0:
        d //= 2
    while d % 5 == 0:
        d //= 5
    if d == 1:
        dec = Decimal(frac.numerator) / Decimal(frac.denominator)
        text = format(dec.normalize(), "f")
        return text
    return f"{frac.numerator}/{frac.denominator}"


def join_list(items: list[str]) -> str:
    if len(items) == 1:
        return items[0]
    if len(items) == 2:
        return f"{items[0]} and {items[1]}"
    return ", ".join(items[:-1]) + f", and {items[-1]}"


# --- family (d): action-clause phrasing --------------------------------
# Only combine_quantities (add-family) and compare_magnitudes (compare-
# family) are cited from action_grammar.pl; every other operation gets
# plain, honest, non-cited English naming what it does. See
# draft_explanation_forms.VOCAB_FOR_FAMILY["d_strategy_explanation"] for
# why forcing the cited vocabulary onto e.g. division would misdescribe it.

_COMPARATOR_WORD = {
    **{op: "equal to" for op in sv.EQ_CMP_OPS},
    **{op: "greater than" for op in sv.GT_CMP_OPS},
    **{op: "less than" for op in sv.LT_CMP_OPS},
    **{op: "greater than or equal to" for op in sv.GE_CMP_OPS},
    **{op: "less than or equal to" for op in sv.LE_CMP_OPS},
}


def action_clause(step: dict) -> str:
    op = str(step.get("operation") or "").strip().lower()
    operands = step.get("operands") or []
    result = step.get("result")
    ops_fmt = [fmt(o) for o in operands]

    if op in sv.ADD_OPS:
        return f"combines {join_list(ops_fmt)} to get {fmt(result)}"
    if op in sv.SUB_OPS:
        return f"subtracts {ops_fmt[1]} from {ops_fmt[0]} to get {fmt(result)}"
    if op in sv.MUL_OPS:
        return f"multiplies {join_list(ops_fmt)} to get {fmt(result)}"
    if op in sv.DIV_OPS:
        return f"divides {ops_fmt[0]} by {ops_fmt[1]} to get {fmt(result)}"
    if op in sv.POW_OPS:
        return f"raises {ops_fmt[0]} to the power {ops_fmt[1]} to get {fmt(result)}"
    if op in sv.SQUARE_OPS:
        return f"squares {ops_fmt[0]} to get {fmt(result)}"
    if op in sv.MOD_OPS:
        return f"finds the remainder of {ops_fmt[0]} divided by {ops_fmt[1]}, which is {fmt(result)}"
    if op in sv.FLOOR_OPS:
        return f"rounds {ops_fmt[0]} down to {fmt(result)}"
    if op in sv.CEIL_OPS:
        return f"rounds {ops_fmt[0]} up to {fmt(result)}"
    if op in sv.ROUND_WHOLE_OPS:
        return f"rounds {ops_fmt[0]} to the nearest whole number, {fmt(result)}"
    if op in sv.ROUND_TENTH_OPS:
        return f"rounds {ops_fmt[0]} to the nearest tenth, {fmt(result)}"
    if op in sv.ROUND_HUNDREDTH_OPS:
        return f"rounds {ops_fmt[0]} to the nearest hundredth, {fmt(result)}"
    if op in sv.ROUND_THOUSAND_OPS:
        return f"rounds {ops_fmt[0]} to the nearest thousand, {fmt(result)}"
    if op in sv.COUNT_ZEROS_OPS:
        return f"counts {fmt(result)} zero digits in {ops_fmt[0]}"
    if op in sv.DIVISIBILITY_OPS:
        return f"checks whether {ops_fmt[0]} is divisible by {ops_fmt[1]}, which is {fmt(result)}"
    if op in sv.INTERIOR_ANGLE_OPS:
        return f"computes the interior angle of a regular {ops_fmt[0]}-sided polygon as {fmt(result)} degrees"
    if op in sv.PERIMETER_OPS:
        return f"computes the perimeter of a rectangle with sides {ops_fmt[0]} and {ops_fmt[1]} as {fmt(result)}"
    if op in _COMPARATOR_WORD:
        return f"compares {ops_fmt[0]} and {ops_fmt[1]}, finding the relation {_COMPARATOR_WORD[op]} holds ({fmt(result)})"
    return f"applies {op.replace('_', ' ')} to {join_list(ops_fmt)} to get {fmt(result)}"


def initial_state_phrase(verified: list[dict]) -> str:
    seen = []
    for step in verified:
        for o in step.get("operands") or []:
            s = fmt(o)
            if s not in seen:
                seen.append(s)
    if not seen:
        return "the given quantities"
    return f"the given quantities used in the trace: {join_list(seen)}"


def final_state_phrase(verified: list[dict], answer_value) -> str:
    last = verified[-1]
    last_result = last.get("result")
    last_fmt = fmt(last_result)
    matches_answer = False
    if isinstance(last_result, bool):
        matches_answer = isinstance(answer_value, bool) and answer_value == last_result
    else:
        lr = sv.to_fraction(last_result)
        av = sv.to_fraction(answer_value) if not isinstance(answer_value, bool) else None
        matches_answer = lr is not None and av is not None and lr == av
    if matches_answer:
        return f"{last_fmt} as the answer"
    return f"{last_fmt}, the trace's own last independently-verified value"


# --- family (d) instantiation --------------------------------------------


def instantiate_d(form: dict, verified: list[dict], analysis: dict) -> tuple[str, dict]:
    initial = initial_state_phrase(verified)
    actions = "; then ".join(action_clause(s) for s in verified)
    answer_value = (analysis.get("answer") or {}).get("value") if isinstance(analysis.get("answer"), dict) else analysis.get("answer")
    final = final_state_phrase(verified, answer_value)
    text = form["template"].format(
        INITIAL_STATE=initial, ACTION_SEQUENCE=actions, FINAL_STATE_ANSWER=final)
    bindings = {
        "INITIAL_STATE": {"value": initial, "source": "verified step operands"},
        "ACTION_SEQUENCE": {"value": actions,
                              "source": f"{len(verified)} independently re-executed step(s)"},
        "FINAL_STATE_ANSWER": {"value": final, "source": "last verified step's result"},
    }
    return text, bindings


# --- family (b) instantiation --------------------------------------------


def instantiate_b(form: dict, compare_steps: list[dict]) -> tuple[str, dict]:
    clauses = []
    binding_list = []
    for step in compare_steps:
        op = str(step.get("operation") or "").strip().lower()
        operands = step.get("operands") or []
        result = step.get("result")
        comparator = _COMPARATOR_WORD.get(op, "related to")
        a, b = fmt(operands[0]), fmt(operands[1])
        truth = "true" if result else "false"
        clause = form["template"].format(
            EXPRESSION_A=a, EXPRESSION_B=b, COMPARATOR=comparator, TRUTH_VALUE=truth)
        clauses.append(clause)
        binding_list.append({
            "EXPRESSION_A": a, "EXPRESSION_B": b, "COMPARATOR": comparator,
            "TRUTH_VALUE": truth, "source": "verified compare_* step",
        })
    text = " ".join(clauses)
    return text, {"clauses": binding_list}


# --- family (a) instantiation --------------------------------------------


def instantiate_a(form: dict, step: dict) -> tuple[str, dict]:
    op = str(step.get("operation") or "").strip().lower().replace("_", " ")
    operands = [fmt(o) for o in (step.get("operands") or [])]
    result = fmt(step.get("result"))
    text = form["template"].format(OPERATION=op, OPERANDS=join_list(operands), RESULT=result)
    bindings = {
        "OPERATION": {"value": op, "source": "verified step"},
        "OPERANDS": {"value": join_list(operands), "source": "verified step operands"},
        "RESULT": {"value": result, "source": "verified step result"},
        "INVARIANT_RELATION": {"value": None, "source": "ungrounded -- never asserted"},
    }
    return text, bindings


# --- numeral self-consistency gate ----------------------------------------

import re as _re
_NUMBER_RE = _re.compile(r"-?\d+(?:\.\d+)?(?:/\d+)?")


def numerals_bound(text: str, bound_values: list) -> bool:
    for tok in _NUMBER_RE.findall(text):
        v = sv.to_fraction(tok)
        if v is None:
            continue
        if not any(v == b for b in bound_values if b is not None):
            return False
    return True


def form_pick(record_id: str, forms: list[dict]) -> dict:
    h = int(hashlib.sha1(record_id.encode("utf-8")).hexdigest(), 16)
    return forms[h % len(forms)]


def load_ledger(path: Path) -> dict:
    out = {}
    if not path.exists():
        return out
    with open(path, encoding="utf-8") as f:
        for line in f:
            row = json.loads(line)
            out[row["record_id"]] = row
    return out


def load_step_extraction_steps(path: Path) -> dict:
    """record_id -> its extraction_verified steps list, from the 2026-08-18
    targeted step-extraction grind (step_extraction_ledger.jsonl). Declined
    rows contribute nothing here -- their absence is exactly the same
    no_verified_grounding outcome as before this source existed."""
    out: dict[str, list] = {}
    if not path.exists():
        return out
    with open(path, encoding="utf-8") as f:
        for line in f:
            row = json.loads(line)
            if row.get("status") == "extraction_verified":
                out[row["record_id"]] = row.get("steps") or []
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--families-jsonl", default=str(COVERAGE_DIR / "explanation_families.jsonl"))
    ap.add_argument("--forms", default=str(COVERAGE_DIR / "explanation_forms.json"))
    ap.add_argument("--merged-ledger", default=str(COVERAGE_DIR / "merged_admitted_ledger.jsonl"))
    ap.add_argument("--recovery-ledger", default=str(COVERAGE_DIR / "recovery_wave_ledger.jsonl"))
    ap.add_argument("--step-extraction-ledger",
                     default=str(COVERAGE_DIR / "step_extraction_ledger.jsonl"),
                     help="2026-08-18 targeted step-extraction grind's output "
                          "(scripts/coverage/collect_step_extraction.py). A "
                          "third candidate-step source, joined and "
                          "independently re-verified exactly like the other "
                          "two -- never trusted on its own status label.")
    ap.add_argument("--output", default=str(COVERAGE_DIR / "explanation_ledger.jsonl"))
    args = ap.parse_args()

    fam_rows = []
    with open(args.families_jsonl, encoding="utf-8") as f:
        for line in f:
            row = json.loads(line)
            if row["family"] in TARGET_FAMILIES:
                fam_rows.append(row)

    forms_doc = json.loads(Path(args.forms).read_text(encoding="utf-8"))
    forms_by_family: dict[str, list[dict]] = {}
    for f in forms_doc["forms"]:
        forms_by_family.setdefault(f["family"], []).append(f)

    merged = load_ledger(Path(args.merged_ledger))
    recovery = load_ledger(Path(args.recovery_ledger))
    step_extraction_steps = load_step_extraction_steps(Path(args.step_extraction_ledger))

    stamp = _dt.date.today().isoformat()
    counts = {"admitted": 0, "declined": 0}
    by_family_grade = {}
    out_lines = []

    for fam_row in fam_rows:
        rid = fam_row["record_id"]
        family = fam_row["family"]
        grade = fam_row.get("grade")
        by_family_grade.setdefault(family, {}).setdefault(grade, {"admitted": 0, "declined": 0})

        merged_row = merged.get(rid)
        recovery_row = recovery.get(rid)
        extracted_steps = step_extraction_steps.get(rid) or []

        base_out = {
            "record_id": rid, "family": family, "lesson": fam_row.get("lesson"),
            "grade": grade, "date": stamp,
        }

        if merged_row is None and recovery_row is None and not extracted_steps:
            base_out.update(status="declined", reason="no_verified_grounding",
                             detail="record_id absent from all three sources")
            counts["declined"] += 1
            by_family_grade[family][grade]["declined"] += 1
            out_lines.append(base_out)
            continue

        # Pool candidate steps from all THREE sources -- a step that
        # verifies in any one of them grounds the row; a record's several
        # attempts (the original pass, the 2026-08-18 recovery wave, and
        # the 2026-08-18 targeted step-extraction grind aimed exactly at
        # this file's own prior declines) are not in competition, they are
        # independent sources for the same arithmetic. Each candidate is
        # re-executed on its own merits regardless of which source, or
        # which gate that source's own pass landed on, produced it.
        candidates = []
        for s in ((merged_row or {}).get("analysis") or {}).get("steps") or []:
            candidates.append((s, "merged_admitted_ledger.jsonl"))
        for s in ((recovery_row or {}).get("analysis") or {}).get("steps") or []:
            candidates.append((s, "recovery_wave_ledger.jsonl"))
        for s in extracted_steps:
            candidates.append((s, "step_extraction_ledger.jsonl"))

        verified_with_source = []
        seen_keys = set()
        for s, src in candidates:
            if not isinstance(s, dict):
                continue
            ok = sv.verify_step(s.get("operation"), s.get("operands"), s.get("result"))
            if ok is not True:
                continue
            key = (str(s.get("operation")).lower(), tuple(s.get("operands") or []), s.get("result"))
            if key in seen_keys:
                continue
            seen_keys.add(key)
            verified_with_source.append((s, src))

        verified = [s for s, _src in verified_with_source]
        sources_used = sorted({src for _s, src in verified_with_source})
        # The row's own stated answer (for the "names it as the answer"
        # check) comes from whichever ledger's analysis exists; recovery's
        # is today's pass and preferred when both exist.
        analysis = ((recovery_row or {}).get("analysis")
                    or (merged_row or {}).get("analysis") or {})

        if not verified:
            base_out.update(
                status="declined", reason="no_verified_grounding",
                detail=(f"{len(candidates)} declared step(s) across both ledgers, "
                        f"0 independently re-executed true"))
            counts["declined"] += 1
            by_family_grade[family][grade]["declined"] += 1
            out_lines.append(base_out)
            continue

        family_forms = forms_by_family.get(family)
        if not family_forms:
            base_out.update(status="declined", reason="no_form_for_family")
            counts["declined"] += 1
            by_family_grade[family][grade]["declined"] += 1
            out_lines.append(base_out)
            continue
        form = form_pick(rid, family_forms)

        if family == "d_strategy_explanation":
            text, bindings = instantiate_d(form, verified, analysis)
            bound_values = []
            for s in verified:
                for o in s.get("operands") or []:
                    v = sv.to_fraction(o)
                    if v is not None:
                        bound_values.append(v)
                if not isinstance(s.get("result"), bool):
                    v = sv.to_fraction(s.get("result"))
                    if v is not None:
                        bound_values.append(v)
        elif family == "b_comparison":
            compare_steps = [s for s in verified
                              if str(s.get("operation") or "").lower() in
                              (sv.EQ_CMP_OPS | sv.GT_CMP_OPS | sv.LT_CMP_OPS
                               | sv.GE_CMP_OPS | sv.LE_CMP_OPS)]
            if not compare_steps:
                base_out.update(status="declined", reason="no_verified_grounding",
                                 detail="verified step(s) present but none is a comparison",
                                 grounding_ledger=sources_used)
                counts["declined"] += 1
                by_family_grade[family][grade]["declined"] += 1
                out_lines.append(base_out)
                continue
            text, bindings = instantiate_b(form, compare_steps)
            bound_values = []
            for s in compare_steps:
                for o in s.get("operands") or []:
                    v = sv.to_fraction(o)
                    if v is not None:
                        bound_values.append(v)
        else:  # a_operation_justify
            step = verified[0]
            text, bindings = instantiate_a(form, step)
            bound_values = []
            for o in step.get("operands") or []:
                v = sv.to_fraction(o)
                if v is not None:
                    bound_values.append(v)
            if not isinstance(step.get("result"), bool):
                v = sv.to_fraction(step.get("result"))
                if v is not None:
                    bound_values.append(v)

        if not numerals_bound(text, bound_values):
            base_out.update(status="declined", reason="numeral_self_check_failed",
                             detail=text, grounding_ledger=sources_used)
            counts["declined"] += 1
            by_family_grade[family][grade]["declined"] += 1
            out_lines.append(base_out)
            continue

        if "step_extraction_ledger.jsonl" in sources_used:
            other_sources = [s for s in sources_used if s != "step_extraction_ledger.jsonl"]
            steps_provenance = ("model-extracted gate-verified"
                                 if not other_sources else
                                 "model-extracted gate-verified + solver-emitted machine-verified")
        else:
            steps_provenance = "solver-emitted machine-verified"

        base_out.update(
            status="admitted", tier="form_grounded", form_id=form["form_id"],
            instantiated_text=text, slot_bindings=bindings,
            n_verified_steps=len(verified), grounding_ledger=sources_used,
            testimony={"steps": steps_provenance,
                       "form": "model-drafted+vetted",
                       "instantiation": "deterministic"},
        )
        counts["admitted"] += 1
        by_family_grade[family][grade]["admitted"] += 1
        out_lines.append(base_out)

    out_path = Path(args.output)
    with open(out_path, "w", encoding="utf-8") as f:
        for row in out_lines:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")

    print(f"wrote {out_path}")
    print(f"total: admitted={counts['admitted']} declined={counts['declined']} "
          f"of {len(fam_rows)}")
    print("by family x grade:")
    for fam, grades in sorted(by_family_grade.items()):
        for grade, c in sorted(grades.items(), key=lambda kv: str(kv[0])):
            print(f"  {fam:28s} grade {str(grade):3s} admitted={c['admitted']:3d} declined={c['declined']:3d}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
