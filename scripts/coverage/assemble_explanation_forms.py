#!/usr/bin/env python3
"""Assemble explanation_forms.json from the drafted candidates plus the
vetting decision made by hand on 2026-08-18 (see the accompanying report
for the reasoning behind each accept/reject).

Reads the raw model output written by draft_explanation_forms.py (the
original batch and the one family-a redraft), keeps only the templates a
human reviewer accepted, and writes the accepted set with grounding
requirements and drafting testimony to explanation_forms.json.

This script embeds the vetting VERDICT (which form_ids were kept, which
were rejected and why) as data rather than re-deriving it, because the
review itself -- reading each template for deficit language, ocular
metaphor, puffery, or an assertion the family's grounding cannot support
-- is not a thing a script can do; it is recorded here as the record of
what a reviewer decided and why.
"""
from __future__ import annotations

import datetime as _dt
import json
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
COVERAGE_DIR = REPO / "hermes" / "app" / "runtime" / "experiments" / "coverage_grind"

RAW_PATH = COVERAGE_DIR / "explanation_form_drafts_raw.json"
REDRAFT_A_PATH = COVERAGE_DIR / "explanation_form_drafts_raw_redraft_a.json"
REDRAFT_B_PATH = COVERAGE_DIR / "explanation_form_drafts_raw_redraft_b.json"
OUT_PATH = COVERAGE_DIR / "explanation_forms.json"

# Vetting verdicts, by (family, form_id) -> keep? and why (rejection reason
# recorded either way, so an accepted form's clean bill of health is on the
# record next to the one rejection).
VERDICT = {
    "d_strategy_explanation": {
        "formal_trace": (True, "no deficit language, no ocular metaphor, no puffery; every clause names only what a verified step supplies"),
        "concise_narrative": (True, "same review; shorter register, same grounding"),
        "analytical_derivation": (True, "same review; formal register, same grounding"),
        "step_record": (True, "same review; uses 'records'/'transitions' -- action language, not ocular"),
    },
    "b_comparison": {
        # First-pass review checked for deficit language / ocular metaphor /
        # puffery / overclaiming and all four cleared -- but a SECOND defect
        # surfaced only once real (false-truth-value) rows were instantiated
        # against them: every one of these four phrases "{A} is {COMPARATOR}
        # {B}" as an ASSERTED FACT (via "is", "Since", "The value of...is",
        # "yields a result of"), then separately states TRUTH_VALUE. When
        # TRUTH_VALUE is false this is self-contradictory and states a wrong
        # numeric fact before disclaiming it -- e.g. "Since 0.355 is greater
        # than 0.359, the statement is false" asserts a false claim as
        # premise. All four REJECTED on this second pass; redrafted as a
        # family with the defect named explicitly (see explanation_form_
        # drafts_raw_redraft_b.json).
        "formal_verification": (False, "self-contradictory under a false TRUTH_VALUE: asserts '{A} is {COMPARATOR} {B}' as fact ('The value of...is...which means'), never hedged as the claim under test"),
        "concise_relation": (False, "same defect: 'Since {A} is {COMPARATOR} {B}, the statement is {TRUTH_VALUE}' states a false numeric relation as a premise when TRUTH_VALUE is false"),
        "procedural_order": (False, "same defect: 'indicates that {A} is {COMPARATOR} {B}' asserts the relation as fact"),
        "comparison_yield": (False, "same defect: 'yields a result of {COMPARATOR}' names the tested relation as the actual outcome regardless of TRUTH_VALUE"),
    },
    "a_operation_justify": {
        "direct_trace": (True, "OPERATION/OPERANDS/RESULT only; INVARIANT_RELATION correctly omitted rather than asserted"),
        "inquiry_based": (True, "surfaces INVARIANT_RELATION as an open question the reader is left with, rather than a claim -- the family's own ungrounded-slot note requires exactly this or omission"),
        "process_focus": (True, "same grounded slots, result-first register; INVARIANT_RELATION omitted"),
        "method_validation": (False, "the fixed prose said '{OPERATION} combines {OPERANDS}' -- 'combines' specifically names joining/addition (it is action_grammar.pl's combine_quantities). Most family-a rows use subtract/multiply/divide/exponentiate; forcing 'combines' onto those operations asserts a joining action the verified step never showed. REJECTED, one redraft requested."),
    },
}

# The redraft's accepted replacement (renamed to avoid a form_id collision
# with the original batch's own "direct_trace").
REDRAFT_ACCEPT_FORM_ID = "direct_trace"  # form_id as drafted in the redraft call
REDRAFT_ACCEPT_RENAME = "operation_applies"
REDRAFT_VERDICT_NOTE = (
    "redraft requested after method_validation's rejection, with the "
    "specific defect named in the redraft prompt. Both redraft candidates "
    "came back clean (operation-neutral: 'applies {OPERATION} to "
    "{OPERANDS}', never presupposing what the operation does). Kept one "
    "(renamed operation_applies to avoid a form_id collision with the "
    "original batch's own direct_trace) as family a's fourth accepted "
    "form; the second redraft candidate (inquiry_trace) duplicated "
    "inquiry_based's open-question structure closely enough that keeping "
    "both would not add coverage, so it was left out.")

REDRAFT_B_VERDICT_NOTE = (
    "redraft requested after all four original family-b forms were "
    "rejected together for the false-TRUTH_VALUE contradiction (see "
    "VERDICT above). All four redraft candidates correctly frame "
    "'{EXPRESSION_A} is {COMPARATOR} {EXPRESSION_B}' as the CLAIM under "
    "test rather than an asserted fact ('The claim that...is', 'Testing "
    "whether...yields', 'the statement that...is', 'Evaluating if...'), "
    "so each reads coherently whether TRUTH_VALUE is true or false. All "
    "four accepted.")

FAMILY_LABELS = {
    "d_strategy_explanation": "(d) strategy explanation",
    "b_comparison": "(b) how-do-you-know comparisons",
    "a_operation_justify": "(a) why-an-operation-fits",
}

SLOT_STRUCTURE = {
    "d_strategy_explanation": ["INITIAL_STATE", "ACTION_SEQUENCE", "FINAL_STATE_ANSWER"],
    "b_comparison": ["EXPRESSION_A", "EXPRESSION_B", "COMPARATOR", "TRUTH_VALUE"],
    "a_operation_justify": ["OPERATION", "OPERANDS", "RESULT", "INVARIANT_RELATION (never asserted)"],
}


def load_calls(path: Path) -> dict:
    if not path.exists():
        return {}
    data = json.loads(path.read_text(encoding="utf-8"))
    by_family = {}
    for call in data.get("calls", []):
        by_family.setdefault(call["family"], []).append(call)
    return by_family, data.get("model"), data.get("date")


def main() -> int:
    raw_by_family, model, date = load_calls(RAW_PATH)
    redraft_by_family, redraft_model, redraft_date = load_calls(REDRAFT_A_PATH)
    redraft_b_by_family, redraft_b_model, redraft_b_date = load_calls(REDRAFT_B_PATH)

    forms_out = []
    rejected_out = []

    for family, verdicts in VERDICT.items():
        drafted = {}
        for call in raw_by_family.get(family, []):
            for f in (call.get("parsed") or {}).get("forms") or []:
                drafted[f["form_id"]] = f
        for form_id, (keep, reason) in verdicts.items():
            draft = drafted.get(form_id)
            if draft is None:
                continue
            if keep:
                forms_out.append({
                    "form_id": form_id,
                    "family": family,
                    "family_label": FAMILY_LABELS[family],
                    "template": draft["template"],
                    "slots": SLOT_STRUCTURE[family],
                    "grounding_requirements": draft.get("grounding_requirements"),
                    "testimony": {
                        "authorship": "model-drafted, human-vetted",
                        "model": model,
                        "date": date,
                        "vetting_note": reason,
                    },
                })
            else:
                rejected_out.append({
                    "form_id": form_id, "family": family,
                    "template": draft["template"], "rejection_reason": reason,
                })

        # Fold in the family-a redraft's accepted replacement.
        if family == "a_operation_justify":
            for call in redraft_by_family.get(family, []):
                for f in (call.get("parsed") or {}).get("forms") or []:
                    if f["form_id"] == REDRAFT_ACCEPT_FORM_ID:
                        forms_out.append({
                            "form_id": REDRAFT_ACCEPT_RENAME,
                            "family": family,
                            "family_label": FAMILY_LABELS[family],
                            "template": f["template"],
                            "slots": SLOT_STRUCTURE[family],
                            "grounding_requirements": f.get("grounding_requirements"),
                            "testimony": {
                                "authorship": "model-drafted (redraft), human-vetted",
                                "model": redraft_model,
                                "date": redraft_date,
                                "vetting_note": REDRAFT_VERDICT_NOTE,
                            },
                        })
                        break

        # Fold in ALL FOUR family-b redraft candidates (the whole original
        # batch was rejected together for the false-TRUTH_VALUE defect).
        if family == "b_comparison":
            for call in redraft_b_by_family.get(family, []):
                for f in (call.get("parsed") or {}).get("forms") or []:
                    forms_out.append({
                        "form_id": f["form_id"],
                        "family": family,
                        "family_label": FAMILY_LABELS[family],
                        "template": f["template"],
                        "slots": SLOT_STRUCTURE[family],
                        "grounding_requirements": f.get("grounding_requirements"),
                        "testimony": {
                            "authorship": "model-drafted (redraft), human-vetted",
                            "model": redraft_b_model,
                            "date": redraft_b_date,
                            "vetting_note": REDRAFT_B_VERDICT_NOTE,
                        },
                    })

    out = {
        "date": _dt.date.today().isoformat(),
        "method": ("Forms authored once per family via REALLMS "
                   "(gemma-4-31B-it), then vetted by hand in two passes. "
                   "Pass 1 (reading the templates cold) checked: no "
                   "assertion beyond the family's grounded slots, no "
                   "deficit language about students, no ocular metaphor, "
                   "no puffery. One family-a form failed pass 1 (forced "
                   "'combines' onto every operation) and was redrafted. "
                   "Pass 2 (reading real instantiated output) caught a "
                   "defect pass 1 missed: all four family-b forms read as "
                   "self-contradictory when TRUTH_VALUE is false (they "
                   "assert '{A} is {COMPARATOR} {B}' as fact, not as the "
                   "claim under test). All four were rejected together "
                   "and redrafted as a family; family d's four forms and "
                   "family a's four (three original plus the pass-1 "
                   "redraft) needed no pass-2 correction."),
        "forms_accepted": len(forms_out),
        "forms_rejected": len(rejected_out),
        "forms": forms_out,
        "rejected": rejected_out,
    }
    OUT_PATH.write_text(json.dumps(out, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"wrote {OUT_PATH}: {len(forms_out)} accepted, {len(rejected_out)} rejected")
    for f in forms_out:
        print(f"  [{f['family']}] {f['form_id']}: {f['template'][:90]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
