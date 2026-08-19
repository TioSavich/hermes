#!/usr/bin/env python3
"""Draft explanation FORMS, once per family -- not once per row.

A form is numeral-independent prose with named slots
({operation_phrase}, {operand_a}, {result}, ...), authored so the same
template instantiates for every row in its family once the slots are filled
from a row's own machine-verified steps. This script makes the (small
number of) REALLMS calls that draft candidate forms; it writes every
candidate to a scratch file for the calling session to read and vet by
hand -- rejecting forms that assert beyond their grounding, use deficit
language about students, or carry puffery/ocular metaphor -- before any
form is copied into explanation_forms.json.

This script never instantiates a row. See instantiate_explanations.py for
the deterministic (model-free) fill step.
"""
from __future__ import annotations

import argparse
import datetime as _dt
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
COVERAGE_DIR = REPO / "hermes" / "app" / "runtime" / "experiments" / "coverage_grind"

# Curated, RELEVANT vocabulary rows -- pulled by hand from
# knowledge/strategies/math/state_vocabulary.pl and
# knowledge/strategies/action_grammar.pl for the operations the three
# families' rows actually use (see step_verifier.KNOWN_OPS and the
# 2026-08-18 operation census: mostly plain add/subtract/multiply/divide/
# compare_*, not the fraction-scheme states state_vocabulary.pl documents).
# Every entry here is a verbatim atom or gloss fragment that exists in the
# named file today; nothing here is invented.
VOCAB_FOR_FAMILY = {
    "d_strategy_explanation": """
knowledge/strategies/action_grammar.pl -- canonical action alphabet
(action_grammar:action_phrase/3). These names exist in the file and are
safe for GENERIC arithmetic because they never co-occur, in any recorded
arc, with a mistake/deformation action (misname_result, omit_required_step,
record_loss, treat_relevant_as_irrelevant) -- using them for a CORRECT
strategy's steps does not borrow deficit vocabulary:
  - register_givens -- "Hold the givens" (from take_up_and_read gloss:
    "Hold the givens, then read the property the next step turns on.")
  - combine_quantities -- "Carry out the joining" (from
    operate_and_record_the_keeping gloss: "Carry out the joining and record
    that the total was conserved.")
  - compare_magnitudes -- "Decide the order" (from order_and_release gloss:
    "Decide the order and release it. The closing the comparison automata
    share.")
  - name_result / emit_result -- "name/release the result" (from
    count_and_name gloss: "Count the units the iteration produced and name
    that count as the answer"; order_and_release gloss above)
Most family-d rows use a plain arithmetic operation (subtract, multiply,
divide, exponentiate, round, ...) that this alphabet has no dedicated word
for -- forcing one of the above names onto e.g. division would misdescribe
it (division alone does not disclose sharing- vs measurement-division, and
the vocabulary's own author flags that distinction as high-risk to
conflate). For those operations, use plain, honest, non-cited English
naming the operation directly (e.g. "divides {a} by {b}").
""",
    "b_comparison": """
knowledge/strategies/action_grammar.pl -- order_and_release gloss: "Decide
the order and release it. The closing the comparison automata share." This
is the one generic, safe citation for ANY compare_equal/compare_greater/
compare_less step -- it names the closing move without asserting which
particular comparison STRATEGY (unitizing, benchmarking, common-denominator,
...) a student would use, which the raw operand values alone cannot
disclose.

hermes/math_claim_checker.pl -- the claim-family vocabulary the grounded
comparator itself uses: equivalence(...), comparison(...), ordering(...).
Use plain words drawn from these families for the COMPARATOR slot (equal
to / greater than / less than / equivalent to) rather than inventing new
comparator language.

knowledge/strategies/math/state_vocabulary.pl exists specifically for
FRACTION/DECIMAL comparison automata (q_compare_same_denominator,
q_benchmark_first, q_partition, ...) but names a specific STRATEGY a
student used -- do not claim one of these states for a row unless the
row's own verified steps show that strategy's structure (e.g. a
common-denominator step before the comparison). If the row only has a bare
compare_* step over two numbers, do not name a scheme; describe only what
the compare step itself shows.
""",
    "a_operation_justify": """
This family's INVARIANT_RELATION slot ("the algebraic property that
licenses the method") is explicitly UNGROUNDED per the census: "this slot
is NOT auto-filled by any existing store -- it names WHY the trace is
valid, not just what the trace computed." No form may assert a value for
this slot as fact. A form may either (a) omit the slot and claim only the
grounded trace (operands, operation, result), or (b) surface it as an open
question the explanation raises but does not answer for the reader.
Grounded material available: the row's own verified {operation, operands,
result} steps (same as family d) -- knowledge/strategies/action_grammar.pl
register_givens / combine_quantities / name_result apply the same way
family d uses them, for whichever rows actually use those operations.
""",
}

FAMILY_LABELS = {
    "d_strategy_explanation": "(d) strategy explanation",
    "b_comparison": "(b) how-do-you-know comparisons",
    "a_operation_justify": "(a) why-an-operation-fits",
}

SLOT_STRUCTURE = {
    "d_strategy_explanation": {
        "INITIAL_STATE": "the given quantities/constraints",
        "ACTION_SEQUENCE": "ordered list of (STATE_i, ACTION, STATE_i+1) triples, named from state_vocabulary.pl / action_grammar.pl where they genuinely apply, plain arithmetic language otherwise",
        "FINAL_STATE_ANSWER": "the last state / analysis.answer",
    },
    "b_comparison": {
        "EXPRESSION_A": "the first side of the claim (its computed value, already verified)",
        "EXPRESSION_B": "the second side of the claim (its computed value, already verified)",
        "COMPARATOR": "=, >, <, congruent-to, equivalent-to -- already computed by the step",
        "TRUTH_VALUE": "the boolean already computed by the step",
    },
    "a_operation_justify": {
        "OPERANDS": "the quantities being combined",
        "OPERATION": "the operation or named algorithm/method performed",
        "RESULT": "the computed value",
        "INVARIANT_RELATION": "UNGROUNDED -- no store fills this; the form must not assert it",
    },
}

PROMPT_TEMPLATE = """You are drafting REUSABLE PROSE TEMPLATES for grounded math
explanations, not writing an explanation for one problem.

FAMILY: {family_label}
SLOT STRUCTURE (every slot a grounded explanation for this family names):
{slot_structure}

THREE VERBATIM EXAMPLE PROBLEMS FROM THIS FAMILY (for register/genre only --
your templates must work for ALL problems in the family, not just these
three; never quote a number from these examples into your template):
{examples}

VOCABULARY AVAILABLE (use only where it genuinely fits; do not force it):
{vocabulary}

TASK: draft {n_forms} candidate templates. Each template is prose with named
slots in curly braces, e.g. {{operation_phrase}}, {{operand_a}}, {{result}}.
RULES:
- NEVER write a literal numeral in the template itself -- every number is a
  slot, filled later by a separate deterministic step, never by you.
- NEVER assert something beyond what the slot structure's grounded slots can
  supply. If a slot has no automated source (see vocabulary notes), either
  omit it from the template or phrase it as an open question, never as a
  stated fact.
- NEVER use deficit language about students (no "the student fails to...",
  "incorrectly...", "should have..."). These templates explain a WORKED,
  CORRECT trace.
- NEVER use ocular metaphor for knowing ("we can see that...", "it's clear
  that...", "notice that..."). Prefer action/record language: "the count
  records...", "the step names...", "the trace shows...".
- NEVER use puffery, exclamation, or a triadic list for its own sake.
- Each template may differ in which of the slot structure's slots it uses
  and in register (e.g. one might name every action explicitly, another
  might be terser) -- that variety is the point of drafting more than one.
- For each template, also state its GROUNDING REQUIREMENTS: which slots
  require a machine-verified step (name which), and which slots (if any)
  the template deliberately omits or leaves open because no store grounds
  them.

Reply with ONLY one JSON object, no prose outside it:
{{"forms": [
  {{"form_id": "<short_snake_case_name>",
    "template": "<the prose template with {{slot}} placeholders>",
    "slots_used": ["<slot name>", ...],
    "grounding_requirements": "<one or two sentences: which slots need a verified step, which are omitted/open and why>"}},
  ...
]}}
"""


def build_prompt(family: str, n_forms: int, examples: list[dict]) -> str:
    ex_text = "\n".join(
        f"- \"{e['statement']}\"" for e in examples
    )
    return PROMPT_TEMPLATE.format(
        family_label=FAMILY_LABELS[family],
        slot_structure=json.dumps(SLOT_STRUCTURE[family], indent=2),
        examples=ex_text,
        vocabulary=VOCAB_FOR_FAMILY[family],
        n_forms=n_forms,
    )


def last_json_object(text: str):
    decoder = json.JSONDecoder()
    found = None
    pos = 0
    while True:
        start = text.find("{", pos)
        if start == -1:
            return found
        try:
            obj, end = decoder.raw_decode(text, start)
        except json.JSONDecodeError:
            pos = start + 1
            continue
        if isinstance(obj, dict):
            found = obj
        pos = end


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--summary", default=str(COVERAGE_DIR / "explanation_families_summary.json"))
    ap.add_argument("--output", default=str(COVERAGE_DIR / "explanation_form_drafts_raw.json"))
    ap.add_argument("--n-forms", type=int, default=4)
    ap.add_argument("--families", default="d_strategy_explanation,b_comparison,a_operation_justify")
    ap.add_argument("--extra-note", default="",
                     help="appended to every prompt, e.g. a redraft repair note")
    ap.add_argument("--max-tokens", type=int, default=2200)
    ap.add_argument("--timeout", type=int, default=240)
    args = ap.parse_args()

    summary = json.loads(Path(args.summary).read_text(encoding="utf-8"))
    fam_by_key = {f["family"]: f for f in summary["families"]}

    sys.path.insert(0, str(REPO))
    from hermes.app import llm as reallms

    api_key = reallms.load_key(REPO / "hermes" / "app")
    if not api_key:
        print("no REALLMS key found", flush=True)
        return 2
    api_url = reallms.resolve_api_url()
    model = reallms.resolve_model()
    ssl_ctx = reallms.build_ssl_context()

    families = args.families.split(",")
    out = {"date": _dt.date.today().isoformat(), "model": model, "calls": []}
    for family in families:
        fam_summary = fam_by_key[family]
        examples = fam_summary["examples"]
        prompt = build_prompt(family, args.n_forms, examples)
        if args.extra_note:
            prompt += "\n\nREDRAFT NOTE (your prior draft was rejected on review): " + args.extra_note
        print(f"=== drafting forms for {family} ===", flush=True)
        result = reallms.call_api_messages_result(
            [{"role": "user", "content": prompt}],
            api_key=api_key, api_url=api_url, model=model,
            ssl_ctx=ssl_ctx, retries=2, timeout=args.timeout,
            max_tokens=args.max_tokens)
        call_record = {"family": family, "prompt_chars": len(prompt),
                        "outcome": result.outcome}
        if result.outcome != "ok":
            call_record["error"] = getattr(result, "content", None)
            print(f"  transport outcome={result.outcome}", flush=True)
            out["calls"].append(call_record)
            continue
        content = result.content
        parsed = last_json_object(content or "")
        call_record["raw_content"] = content
        call_record["parsed"] = parsed
        n_forms_drafted = len((parsed or {}).get("forms") or [])
        print(f"  parsed {n_forms_drafted} candidate forms", flush=True)
        out["calls"].append(call_record)

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(out, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"wrote {out_path}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
