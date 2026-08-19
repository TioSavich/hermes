#!/usr/bin/env python3
"""Propose-verify driver for the 2026-08-18 coverage grind.

For each uncovered IM statement, one model call proposes a structured
analysis (quantities, ask, steps, answer). Five deterministic gates decide
admission; nothing the model says becomes a fact without surviving them.
The vocabulary the model brings (kinds, operation names) is recorded
verbatim under the 2026-08-18 diversity-over-abstraction ruling — it is
attributed testimony, never canonical vocabulary.

Backends: --backend openai (node-local llama-server /v1, Big Red) or
--backend reallms (hermes.app.llm client, controller laptop only).
Checkpoints one JSONL row per statement; reruns resume from the ledger.
"""
from __future__ import annotations

import argparse
import datetime as _dt
import json
import re
import sys
import time
import urllib.request
from fractions import Fraction
from pathlib import Path

import step_verifier as stepv

REPO = Path(__file__).resolve().parents[2]

PROMPT = """You are analyzing one elementary/middle-school mathematics story problem.

Reply with ONLY one JSON object, no prose, in exactly this shape:
{
 "quantities": [{"value": <number>, "unit_or_kind": "<short name>", "verbatim_span": "<exact substring of the problem that states this quantity>"}],
 "ask": "<one sentence restating what the problem asks>",
 "steps": [{"operation": "<name>", "operands": [<numbers>], "result": <number>}],
 "answer": {"value": <number>, "kind": "<short name>"},
 "missing_doing": "<name a doing this problem needs that plain arithmetic steps cannot express, or null>",
 "render_spec": null
}

Rules: every quantity's verbatim_span must be copied exactly from the problem
text. Every step's result must follow from its operands by exact arithmetic.
Use as many steps as the solution needs. If the problem states an equation or
claim to check rather than asking a question, compute each side in steps, add a
final step {"operation": "compare_equal", "operands": [<left>, <right>],
"result": true or false}, and give "answer": {"value": true or false,
"kind": "claim_verdict"}. If the problem asks nothing computable, reply
{"quantities": [], "ask": "<why>", "steps": [], "answer": null,
"missing_doing": "<name it>", "render_spec": null}.

PROBLEM:
"""

# =============================================================================
# 2026-08-18 recovery wave: three additional modes layered on the same
# transport/checkpoint/shard machinery above. Each target row (built by
# scripts/coverage/build_recovery_wave_targets.py) carries a "mode" field;
# rows with no mode field take the original PROMPT/gate path unchanged.
# =============================================================================

PROMPT_FIGURE_CONTEXT = """You are analyzing one elementary/middle-school mathematics
story problem. This problem references a picture, graph, or figure; model-
generated descriptions of the lesson's pictures follow the problem, offered
as CONTEXT ONLY -- most describe images unrelated to this specific problem
(logos, decorative art, other tasks on the same page). Use a description's
numbers only when they plainly belong to THIS problem.

Reply with ONLY one JSON object, no prose, in exactly this shape:
{{
 "quantities": [{{"value": <number>, "unit_or_kind": "<short name>", "verbatim_span": "<exact substring, from the PROBLEM text or a picture description below, that states this quantity>"}}],
 "ask": "<one sentence restating what the problem asks>",
 "steps": [{{"operation": "<name>", "operands": [<numbers>], "result": <number>}}],
 "answer": {{"value": <number>, "kind": "<short name>"}},
 "missing_doing": "<name a doing this problem needs that plain arithmetic steps cannot express, or null>",
 "render_spec": null
}}

Rules: every quantity's verbatim_span must be copied exactly, character for
character, from either the PROBLEM text or a PICTURE DESCRIPTION below --
never paraphrased or computed. Every step's result must follow from its
operands by exact arithmetic. If the problem asks nothing computable even
with the picture descriptions, reply {{"quantities": [], "ask": "<why>",
"steps": [], "answer": null, "missing_doing": "<name it>", "render_spec": null}}.

PROBLEM:
{statement}

PICTURE DESCRIPTIONS FROM THIS LESSON (context only, may be truncated, may
be unrelated to this problem):
{captions}
"""

PROMPT_EXPLANATION_FORM = """You are analyzing one elementary/middle-school mathematics
problem that asks for an EXPLANATION -- why a method works, how a comparison
came out, or a trace of a solution strategy -- not a bare numeral answer.

This problem's explanation family: {family_label}
The slots a grounded explanation for this family names:
{slot_structure}
{ledger_context}
Reply with ONLY one JSON object, no prose, in exactly this shape:
{{
 "quantities": [{{"value": <number>, "unit_or_kind": "<short name>", "verbatim_span": "<exact substring of the problem that states this quantity>"}}],
 "form": {{"<SLOT_NAME>": "<a short, numeral-free description of what fills this slot -- name the relation/operation/quantity role, never a specific number>", "...": "..."}},
 "steps": [{{"operation": "<name>", "operands": [<numbers>], "result": <number>}}],
 "answer": {{"value": <number or true/false>, "kind": "<short name>"}},
 "explanation": "<one to three sentences instantiating the form for THIS problem's actual numbers, in plain language>"
}}

Rules: every quantity's verbatim_span must be copied exactly from the problem
text. Every step's result must follow from its operands by exact arithmetic.
Every number that appears in "explanation" must equal a quantity's value or a
step's result -- never an invented or rounded figure. If the problem states
an equation or claim to check, add a final step {{"operation": "compare_equal",
"operands": [<left>, <right>], "result": true or false}} and answer with that
boolean. If no grounded explanation is possible, reply {{"quantities": [],
"form": {{}}, "steps": [], "answer": null, "explanation": null}}.

PROBLEM:
{statement}
"""

# =============================================================================
# 2026-08-18 targeted step-extraction: the family-form lane's 688
# no_verified_grounding declines. The prompt asks for a bare arithmetic
# trace only -- no ask, no answer narrative, no explanation -- and is
# steered toward step_verifier.py's own operation vocabulary so the trace
# it proposes has the best chance of being the exact thing that module can
# re-execute. Evaluation (evaluate_step_extraction, below) calls
# step_verifier.verify_step directly, never the looser symbol-guessing
# gate3_execution the other modes use.
# =============================================================================

STEP_EXTRACTION_OP_VOCAB = (
    "add, subtract, multiply, divide, square, exponentiation, modulo, "
    "floor, ceil, round_nearest_whole, round_nearest_tenth, "
    "round_nearest_hundredth, round_to_nearest_thousand, count_zeros, "
    "divisible_by, interior_angle_calculation, calculate_perimeter, "
    "compare_equal, compare_greater, compare_less, "
    "compare_greater_than_or_equal, compare_less_than_or_equal")

PROMPT_STEP_EXTRACTION = """You are extracting ONLY the arithmetic trace that solves one
elementary/middle-school mathematics problem -- not an explanation, not a
narrative, not a restatement of the answer in words. Output nothing but the
structured trace below.
{family_note}
Reply with ONLY one JSON object, no prose, in exactly this shape:
{{
 "quantities": [{{"value": <number>, "verbatim_span": "<exact substring of the problem that states this quantity>"}}],
 "steps": [{{"operation": "<name>", "operands": [<numbers>], "result": <number>}}]
}}

Rules:
- Every quantity's verbatim_span must be copied exactly, character for character,
  from the problem text.
- Every step's operands must each be either one of the quantities above or the
  result of an earlier step in this same list -- never an invented number.
- Every step's result must follow from its operands by exact arithmetic.
- Prefer these operation names -- this pipeline re-executes and verifies only
  these: {op_vocab}. A step using a name outside this list will not verify,
  and the whole row is declined when even one step fails, so use a name
  outside the list only when nothing on it fits.
- If the problem states an equation or claim to check (an inequality, an
  equality, "is X the same as Y"), compute each side in steps and add a
  final step whose operation is compare_equal, compare_greater, compare_less,
  compare_greater_than_or_equal, or compare_less_than_or_equal, with
  "operands": [<left side>, <right side>] and "result": true or false.
- Use as many steps as the solution needs. If no computable trace exists,
  reply {{"quantities": [], "steps": []}}.

PROBLEM:
{statement}
"""

STEP_EXTRACTION_FAMILY_NOTES = {
    "b_comparison": ("This problem is a how-do-you-know comparison: its steps "
                      "must end in one compare_* step whose result is the "
                      "claim's truth value."),
    "d_strategy_explanation": ("This problem asks for a strategy explanation: "
                                "give the full multi-step trace a solution "
                                "strategy would follow, in order."),
    "a_operation_justify": ("This problem asks why one operation fits: one "
                             "step naming that operation is enough."),
}


PROMPT_RENDER_SPEC = """You are choosing the concrete arguments for one existing
diagram-rendering routine, for one elementary/middle-school mathematics
problem that names a diagram, figure, or drawing.

The routine is fixed: {op} (kind: {kind})
Its argument contract:
{contract}

Reply with ONLY one JSON object, no prose, in exactly this shape:
{{
 "quantities": [{{"value": <number>, "verbatim_span": "<exact substring of the problem stating this number>"}}],
 "args": {{<the contract's fields, filled from the quantities above; non-numeric fields like kind/operator/strategy may use the contract's own vocabulary>}}
}}

Rules: every quantity's verbatim_span must be copied exactly from the problem
text. Every NUMBER inside "args" must equal the value of one of the
quantities above -- never an invented number, and never a contract example
value unless the problem itself states that number. If the problem does not
state enough numbers to fill every numeric field the contract requires,
reply {{"quantities": [], "args": {{}}}} rather than inventing one.

PROBLEM:
{statement}
"""

# Per-op argument contracts, ported from render_op_inventory.md's worker-op
# table (2026-08-18 read) and hermes_worker.pl's own *_spec/2 predicates
# (:2713-2938) -- the exact request keys, kind vocabulary, and bounds
# render_spec_gate.pl enforces when it executes the model's proposed args.
RENDER_OP_CONTRACTS = {
    "area_render": (
        "kind: array_multiplication | commutativity_by_transpose | "
        "partial_products (fields: a, b -- whole numbers) OR "
        "area_model_fraction | area_compare (fields: na, da, nb, db -- two "
        "fractions' numerators/denominators)"),
    "base_ten_render": (
        "kind: represent (field: n) | place_value_teen (field: n) | "
        "add_with_carry | subtract_with_borrow | "
        "subtract_without_reducing_borrow (fields: a, b, base[default 10]) | "
        "base_decomposition (field: n) | decimal_place_value "
        "(fields: intPart, fracDigits)"),
    "set_grouping_render": (
        "kind: ten_frame (field: n) | subitize (fields: pattern, n) | "
        "make_ten | make_ten_drop_leftover (fields: a, b) | parity (field: n) "
        "| compare (fields: a, b) | equal_groups (fields: g, s) | "
        "fair_share (fields: total, groups) | signed_chips (fields: a, b)"),
    "number_line_render": (
        "mode (NOT kind): jumps[default] (fields: strategy, a, b) | "
        "length or rounding (fields: operation, a, b) | "
        "magnitude or magnitude_addition (fields: a, b) | "
        "fraction or fraction_iteration (fields: numerator, denominator)"),
    "coordinate_plane_render": (
        "kind: plot_points (field: points -- 1 to 12 [x,y] pairs, each "
        "coordinate from -50 to 50) | plot_line (fields: slope, intercept, "
        "each from -20 to 20)"),
    "rigid_motion_render": (
        "field: vertices (3 to 12 [x,y] pairs, each coordinate -50 to 50); "
        "kind: translate (fields: dx, dy, each -50 to 50) | reflect "
        "(field: mirror = mirror_x or mirror_y) | rotate (fields: cx, cy "
        "each -50 to 50, degrees = 90, 180, or 270)"),
    "angle_circular_render": (
        "kind: angle or sector (field: degrees, a whole number 1 to 360)"),
    "data_display_render": (
        "kind: dot_plot (field: values -- 1 to 60 whole numbers, each -10000 "
        "to 10000) | bar_chart (field: pairs -- 1 to 12 {category, count} "
        "objects) | histogram (field: bins -- 1 to 20 {lower, upper, count} "
        "objects) | box_plot (field: summary -- exactly 5 whole numbers: "
        "min, Q1, median, Q3, max)"),
    "solid_net_render": (
        "kind: net_of (field: solid = cube, square_pyramid, "
        "triangular_prism, or rectangular_prism) | unit_cube_stack "
        "(fields: length, width, height, each 1 to 20)"),
    "geoboard_render": (
        "field: vertices (3 to 12 [x,y] pairs, each coordinate -20 to 20)"),
    "notation_render": (
        "kind: write_equation (fields: a, b, r, operator = + or -) | "
        "mirror_written (fields: digit, a, b, r, operator = + or -)"),
    "balance_render": ("fields: a, b, c (solve a*x + b = c, whole numbers)"),
}


def build_prompt(target: dict) -> str:
    mode = target.get("mode")
    statement = target["statement"]
    if mode == "figure_context":
        captions = target.get("caption_context") or "(none on file)"
        if target.get("caption_truncated"):
            captions += "\n[... truncated ...]"
        return PROMPT_FIGURE_CONTEXT.format(statement=statement, captions=captions)
    if mode == "explanation_form":
        ledger_context = ""
        steps = ((target.get("ledger_analysis") or {}).get("steps"))
        if steps:
            ledger_context = ("\nA prior automated pass computed this trace for "
                               "the same problem -- verify it against the problem "
                               "text rather than copying it blindly:\n" +
                               json.dumps(steps, ensure_ascii=False) + "\n")
        return PROMPT_EXPLANATION_FORM.format(
            statement=statement,
            family_label=target.get("family_label") or target.get("family") or "explanation",
            slot_structure=json.dumps(target.get("slot_structure") or {}, ensure_ascii=False),
            ledger_context=ledger_context)
    if mode == "render_spec":
        op = target["candidate_op"]
        return PROMPT_RENDER_SPEC.format(
            statement=statement, op=op, kind=target.get("op_kind") or "(see contract)",
            contract=RENDER_OP_CONTRACTS.get(op, "(no contract on file for this op)"))
    if mode == "step_extraction":
        note = STEP_EXTRACTION_FAMILY_NOTES.get(target.get("family"), "")
        return PROMPT_STEP_EXTRACTION.format(
            statement=statement, op_vocab=STEP_EXTRACTION_OP_VOCAB,
            family_note=note)
    return PROMPT + statement


NUMBER_WORDS = {
    "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
    "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10, "eleven": 11,
    "twelve": 12, "thirteen": 13, "fourteen": 14, "fifteen": 15,
    "sixteen": 16, "seventeen": 17, "eighteen": 18, "nineteen": 19,
    "twenty": 20, "thirty": 30, "forty": 40, "fifty": 50, "sixty": 60,
    "seventy": 70, "eighty": 80, "ninety": 90, "hundred": 100,
    "half": Fraction(1, 2), "third": Fraction(1, 3), "quarter": Fraction(1, 4),
    "fourth": Fraction(1, 4), "dozen": 12,
}

UNICODE_FRACTIONS = {
    "½": Fraction(1, 2), "⅓": Fraction(1, 3), "⅔": Fraction(2, 3),
    "¼": Fraction(1, 4), "¾": Fraction(3, 4), "⅕": Fraction(1, 5),
    "⅛": Fraction(1, 8), "⅜": Fraction(3, 8), "⅝": Fraction(5, 8),
    "⅞": Fraction(7, 8), "⅙": Fraction(1, 6), "⅚": Fraction(5, 6),
}

OP_TABLE = {
    "+": {"add", "addition", "sum", "plus", "combine", "total", "join", "increase"},
    "-": {"subtract", "subtraction", "minus", "difference", "take", "takeaway",
          "take_away", "remove", "decrease", "less", "left", "remaining"},
    "*": {"multiply", "multiplication", "times", "product", "scale", "repeat",
          "groups", "area", "rate_apply"},
    "/": {"divide", "division", "share", "split", "per", "quotient", "partition",
          "unit_rate", "ratio", "fair_share", "distribute"},
    "^": {"exponent", "exponentiation", "power", "square", "cube", "raise_to"},
}

STOPWORDS = {
    "the", "a", "an", "of", "and", "or", "to", "in", "is", "are", "was", "were",
    "how", "many", "much", "what", "which", "who", "does", "do", "did", "will",
    "for", "with", "on", "at", "by", "from", "it", "its", "his", "her", "their",
    "there", "this", "that", "these", "those", "than", "then", "if", "each",
}


def to_fraction(value) -> Fraction | None:
    """Exact number from a JSON value or numeric string; None when unreadable."""
    if isinstance(value, bool) or value is None:
        return None
    if isinstance(value, int):
        return Fraction(value)
    if isinstance(value, float):
        return Fraction(str(value))
    text = str(value).strip().replace(",", "").replace("$", "").replace("%", "")
    if not text:
        return None
    if text in UNICODE_FRACTIONS:
        return UNICODE_FRACTIONS[text]
    mixed = re.fullmatch(r"(-?\d+)\s+(\d+)\s*/\s*(\d+)", text)
    if mixed:
        whole, num, den = int(mixed.group(1)), int(mixed.group(2)), int(mixed.group(3))
        if den == 0:
            return None
        sign = -1 if whole < 0 else 1
        return Fraction(whole) + sign * Fraction(num, den)
    frac = re.fullmatch(r"(-?\d+)\s*/\s*(\d+)", text)
    if frac:
        if int(frac.group(2)) == 0:
            return None
        return Fraction(int(frac.group(1)), int(frac.group(2)))
    try:
        return Fraction(text)
    except (ValueError, ZeroDivisionError):
        return None


def last_json_object(text: str):
    """The LAST OUTERMOST parseable JSON object; models wrap replies in fences.

    Scanning every '{' would return the last NESTED fragment (an inner answer
    object) — measured on the first pilot. After a parse succeeds the scan
    resumes past that object's end, so only outermost objects are kept.
    """
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


def span_numbers(span: str) -> list[Fraction]:
    """Every number readable from a verbatim span: digits, fractions, words."""
    values: list[Fraction] = []
    for tok in re.findall(r"\d+(?:[.,]\d+)*(?:\s*/\s*\d+)?", span):
        v = to_fraction(tok)
        if v is not None:
            values.append(v)
    for ch, v in UNICODE_FRACTIONS.items():
        if ch in span:
            values.append(v)
    words = re.findall(r"[a-zA-Z]+", span.lower())
    word_vals = [NUMBER_WORDS[w] for w in words if w in NUMBER_WORDS]
    for v in word_vals:
        values.append(Fraction(v) if not isinstance(v, Fraction) else v)
    # compound like "twenty five"
    for i in range(len(word_vals) - 1):
        a, b = word_vals[i], word_vals[i + 1]
        if isinstance(a, int) and isinstance(b, int) and a % 10 == 0 and b < 10:
            values.append(Fraction(a + b))
    return values


def gate2_numeral_binding(analysis: dict, statement: str) -> tuple[bool, str]:
    quantities = analysis.get("quantities")
    if not isinstance(quantities, list) or not quantities:
        return False, "no_quantities"
    for q in quantities:
        if not isinstance(q, dict):
            return False, "quantity_not_object"
        span = q.get("verbatim_span")
        if not isinstance(span, str) or not span.strip():
            return False, "missing_span"
        if span not in statement:
            return False, f"span_not_in_source:{span[:40]}"
        value = to_fraction(q.get("value"))
        if value is None:
            return False, "unreadable_value"
        readable = span_numbers(span)
        if not any(value == r for r in readable):
            # scale variants the bytes themselves show: 3.00 vs 3, percent
            if not any(value * 100 == r or value == r * 100 for r in readable):
                return False, f"value_not_in_span:{q.get('value')}|{span[:40]}"
    return True, "ok"


def _normalize_scalar(value):
    """Reply-shape tolerance ONLY — never verification tolerance.

    Unwraps {'value': x} nesting and reads a SINGLE number out of a string
    like '4 boxes'. A string carrying two distinct numbers stays unreadable:
    ambiguity is refused, not resolved.
    """
    seen = 0
    while isinstance(value, dict) and "value" in value and seen < 3:
        value = value["value"]
        seen += 1
    if isinstance(value, str):
        tokens = re.findall(r"-?\d+(?:[.,]\d+)*(?:\s*/\s*\d+)?", value)
        distinct = {to_fraction(t) for t in tokens} - {None}
        if len(distinct) == 1:
            return distinct.pop()
    return value


def gate3_execution(analysis: dict) -> tuple[bool, str, list]:
    steps = analysis.get("steps")
    answer = analysis.get("answer")
    if isinstance(answer, (int, float)) and not isinstance(answer, bool):
        answer = {"value": answer}
    if not isinstance(steps, list) or not steps:
        return False, "no_steps", []
    if not isinstance(answer, dict):
        return False, "no_answer", []
    raw_answer = _normalize_scalar(answer.get("value"))
    if isinstance(raw_answer, bool):
        answer_value = raw_answer
    else:
        answer_value = to_fraction(raw_answer)
    if answer_value is None:
        return False, "unreadable_answer", []
    executed = []
    results: list = []
    for i, step in enumerate(steps):
        if not isinstance(step, dict):
            return False, f"step_{i}_not_object", []
        opname = str(step.get("operation", "")).lower().strip()
        operands = [to_fraction(_normalize_scalar(o))
                    for o in (step.get("operands") or [])]
        if ("compare" in opname or "equal" in opname or "verify" in opname
                or "check" in opname):
            claimed_bool = step.get("result")
            if not isinstance(claimed_bool, bool) or len(operands) != 2 \
                    or any(o is None for o in operands):
                return False, f"step_{i}_claim_unreadable", []
            if (operands[0] == operands[1]) != claimed_bool:
                return False, f"step_{i}_claim_not_reproduced", []
            executed.append({"operation_verbatim": step.get("operation"),
                             "inferred_op": "==",
                             "operands": [str(o) for o in operands],
                             "result": claimed_bool})
            results.append(claimed_bool)
            continue
        claimed = to_fraction(_normalize_scalar(step.get("result")))
        if claimed is None or any(o is None for o in operands) or len(operands) < 2:
            return False, f"step_{i}_unreadable", []
        symbol = None
        for sym, names in OP_TABLE.items():
            if opname in names or any(n in opname for n in names):
                symbol = sym
                break
        candidates = [symbol] if symbol else ["+", "-", "*", "/", "^"]
        matched = None
        for sym in candidates:
            try:
                acc = operands[0]
                for o in operands[1:]:
                    if sym == "+":
                        acc = acc + o
                    elif sym == "-":
                        acc = acc - o
                    elif sym == "*":
                        acc = acc * o
                    elif sym == "^":
                        if o.denominator != 1 or abs(o.numerator) > 12:
                            raise ZeroDivisionError
                        acc = acc ** o.numerator
                    else:
                        if o == 0:
                            raise ZeroDivisionError
                        acc = acc / o
                if acc == claimed:
                    matched = sym
                    break
            except ZeroDivisionError:
                continue
        if matched is None:
            return False, f"step_{i}_not_reproduced", []
        executed.append({"operation_verbatim": step.get("operation"),
                         "inferred_op": matched,
                         "operands": [str(o) for o in operands],
                         "result": str(claimed)})
        results.append(claimed)
    def same(a, b):
        if isinstance(a, bool) or isinstance(b, bool):
            return isinstance(a, bool) and isinstance(b, bool) and a is b
        return a == b

    if not any(same(answer_value, r) for r in results):
        return False, "answer_not_a_step_result", []
    return True, "ok", executed


def gate4_ask(analysis: dict, statement: str) -> tuple[bool, str]:
    ask = analysis.get("ask")
    if not isinstance(ask, str) or not ask.strip():
        return False, "no_ask"
    ask_words = {w for w in re.findall(r"[a-z]+", ask.lower())} - STOPWORDS
    stmt_words = {w for w in re.findall(r"[a-z]+", statement.lower())} - STOPWORDS
    if not stmt_words:
        # numeral-only statement (bare equation): the ask must name its numerals
        stmt_digits = set(re.findall(r"\d+", statement))
        ask_digits = set(re.findall(r"\d+", ask))
        if stmt_digits and not (stmt_digits & ask_digits):
            return False, "ask_shares_no_numerals"
        return True, "ok"
    if not ask_words & stmt_words:
        return False, "ask_shares_no_content_words"
    return True, "ok"


def gate5_oracle(analysis: dict, target: dict, executed: list) -> str:
    expected = target.get("oracle_expected")
    if not expected:
        return "unoracled_executable"
    raw = (analysis.get("answer") or {}).get("value")
    if isinstance(raw, bool):
        return "unoracled_executable"
    answer_value = to_fraction(raw)
    expected_fracs = [to_fraction(e) for e in expected]
    expected_fracs = [e for e in expected_fracs if e is not None]
    if not expected_fracs:
        return "unoracled_executable"
    if any(answer_value == e for e in expected_fracs):
        return "oracle_matched"
    # A receipt or expected value equal to an INTERMEDIATE step result marks
    # the oracle as answering its own sub-problem (the Han 33/4 pattern).
    steps = {to_fraction(s["result"]) for s in executed}
    if any(e in steps for e in expected_fracs):
        return "oracle_mismatched_held"
    for receipt in (target.get("receipts") or []):
        r = to_fraction(str(receipt.get("result_term", "")).strip("'\""))
        if r is not None and r in steps:
            return "oracle_mismatched_held"
    return "oracle_mismatched_held"


# =============================================================================
# Mode-specific gates for the 2026-08-18 recovery wave.
# =============================================================================

def gate2_numeral_binding_with_context(analysis: dict, statement: str, caption: str):
    """gate2_numeral_binding, but a quantity's verbatim_span may come from
    EITHER the statement OR the lesson's picture-caption context. Records,
    per quantity, which source bound it -- the tier suffix depends on it."""
    quantities = analysis.get("quantities")
    if not isinstance(quantities, list) or not quantities:
        return False, "no_quantities", []
    sources = []
    for q in quantities:
        if not isinstance(q, dict):
            return False, "quantity_not_object", []
        span = q.get("verbatim_span")
        if not isinstance(span, str) or not span.strip():
            return False, "missing_span", []
        if span in statement:
            source = "statement"
        elif caption and span in caption:
            source = "caption"
        else:
            return False, f"span_not_in_source:{span[:40]}", []
        value = to_fraction(q.get("value"))
        if value is None:
            return False, "unreadable_value", []
        readable = span_numbers(span)
        if not any(value == r for r in readable):
            if not any(value * 100 == r or value == r * 100 for r in readable):
                return False, f"value_not_in_span:{q.get('value')}|{span[:40]}", []
        sources.append(source)
    return True, "ok", sources


NUMBER_TOKEN_RE = re.compile(r"-?\d+(?:[.,]\d+)*(?:\s*/\s*\d+)?")


def gate_explanation_numbers(explanation, bound_values: list) -> tuple[bool, str]:
    """Every number appearing in the free-text "explanation" must equal a
    bound quantity value or an executed step result -- the row's own
    grounded numbers, never an invented or rounded figure."""
    if explanation is None:
        return True, "no_explanation"
    if not isinstance(explanation, str):
        return False, "explanation_not_string"
    for tok in NUMBER_TOKEN_RE.findall(explanation):
        v = to_fraction(tok)
        if v is None:
            continue
        if not any(v == b for b in bound_values):
            return False, f"explanation_number_unbound:{tok}"
    return True, "ok"


def flatten_numeric_leaves(value):
    """Every number reachable inside a JSON-shaped args tree, for the
    render_spec operand-binding gate."""
    out = []
    if isinstance(value, bool):
        return out
    if isinstance(value, (int, float)):
        out.append(value)
    elif isinstance(value, dict):
        for v in value.values():
            out.extend(flatten_numeric_leaves(v))
    elif isinstance(value, list):
        for v in value:
            out.extend(flatten_numeric_leaves(v))
    elif isinstance(value, str):
        f = to_fraction(value)
        if f is not None and re.fullmatch(r"\s*-?\d+(?:[.,]\d+)*\s*", value):
            out.append(f)
    return out


def gate_render_operands(args: dict, quantities: list) -> tuple[bool, str]:
    """Every numeric leaf inside the model's proposed args must equal a
    quantity value already bound to the statement -- the render_spec
    mode's "operands bind to statement bytes" half of its gate."""
    if not isinstance(args, dict) or not args:
        return False, "no_args"
    bound = []
    for q in quantities:
        v = to_fraction(q.get("value")) if isinstance(q, dict) else None
        if v is not None:
            bound.append(v)
    if not bound:
        return False, "no_bound_quantities"
    for leaf in flatten_numeric_leaves(args):
        leaf_f = leaf if isinstance(leaf, Fraction) else to_fraction(leaf)
        if leaf_f is None or not any(leaf_f == b for b in bound):
            return False, f"operand_unbound:{leaf}"
    return True, "ok"


def run_render_spec_gate(op: str, request_args: dict, swipl_bin: str,
                          gate_script: str, root: str, timeout: int = 30):
    """Execute the model's proposed render call through the standalone
    Prolog gate (render_spec_gate.pl) -- the spec EXECUTES half of the
    render_spec mode's gate. Never trusts the model's claim; runs the
    actual scene compiler and checks it produced a non-empty frames list."""
    import subprocess
    payload = json.dumps({"op": op, "request": request_args}, ensure_ascii=False)
    try:
        proc = subprocess.run(
            [swipl_bin, gate_script, "--root", root],
            input=payload, capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        return False, "gate_timeout"
    except Exception as exc:  # missing binary, etc.
        return False, f"gate_launch_error:{type(exc).__name__}"
    out = (proc.stdout or "").strip()
    if not out:
        return False, f"gate_no_output:{(proc.stderr or '')[-160:]}"
    try:
        result = json.loads(out.splitlines()[-1])
    except json.JSONDecodeError:
        return False, f"gate_unparseable_output:{out[:160]}"
    if result.get("ok"):
        return True, f"frames:{result.get('frame_count')}"
    return False, str(result.get("reason"))[:160]


def call_openai(endpoint: str, model: str, prompt: str, timeout: int, max_tokens: int):
    payload = {"model": model, "max_tokens": max_tokens,
               "messages": [{"role": "user", "content": prompt}]}
    req = urllib.request.Request(
        endpoint, data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"}, method="POST")
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        data = json.loads(resp.read().decode("utf-8"))
    msg = data["choices"][0]["message"]
    content = msg.get("content") or ""
    finish = data["choices"][0].get("finish_reason")
    return content, finish


def evaluate_step_extraction(analysis: dict, statement: str):
    """The step-extraction mode's own gate -- every operand traces to a
    statement byte or a prior verified step's result (fabrication refusal),
    and every step re-executes true under step_verifier.verify_step, the
    SAME module instantiate_explanations.py uses, not this file's own
    looser symbol-guessing gate3_execution. Any single step failing either
    check declines the WHOLE row, naming that step -- no partial-credit
    row, and no oracle tier (this mode never sees an oracle_expected).

    "Traces to a statement byte" is transitive across the step list: an
    intermediate step's result (once THAT step has itself verified) is a
    legitimate operand for a later step, exactly as instantiate_explanations
    already allows via its numerals_bound() check on rendered text -- a
    literal every-operand-in-source-text reading would reject ordinary
    multi-step traces whose middle terms are never printed in the problem.
    """
    steps = analysis.get("steps")
    if not isinstance(steps, list) or not steps:
        return "declined", "no_steps", None, None, {}

    quantities = analysis.get("quantities")
    if not isinstance(quantities, list):
        quantities = []
    bound: list = []
    for q in quantities:
        if not isinstance(q, dict):
            return "G2", "quantity_not_object", None, None, {}
        span = q.get("verbatim_span")
        if not isinstance(span, str) or not span.strip():
            return "G2", "missing_span", None, None, {}
        if span not in statement:
            return "G2", f"span_not_in_source:{span[:40]}", None, None, {}
        value = stepv.to_fraction(q.get("value"))
        if value is None:
            return "G2", "unreadable_value", None, None, {}
        readable = span_numbers(span)
        if not any(value == r for r in readable):
            if not any(value * 100 == r or value == r * 100 for r in readable):
                return "G2", f"value_not_in_span:{q.get('value')}|{span[:40]}", None, None, {}
        bound.append(value)
    if not bound:
        return "declined", "no_quantities", None, None, {}

    executed = []
    for i, step in enumerate(steps):
        if not isinstance(step, dict):
            return "declined", f"step_{i}_not_object", None, None, {}
        op = step.get("operation")
        operands = step.get("operands") or []
        result = step.get("result")
        if not isinstance(operands, list) or not operands:
            return "declined", f"step_{i}_no_operands", None, None, {}
        for o in operands:
            of = None if isinstance(o, bool) else stepv.to_fraction(o)
            if of is None:
                return "declined", f"step_{i}_operand_unbound:{o}", None, None, {}
            if not any(of == b for b in bound):
                return "declined", f"step_{i}_operand_unbound:{o}", None, None, {}
        ok = stepv.verify_step(op, operands, result)
        if ok is None:
            return "declined", f"step_{i}_operation_unverifiable:{op}", None, None, {}
        if ok is False:
            return "declined", f"step_{i}_not_reproduced", None, None, {}
        executed.append(step)
        if not isinstance(result, bool):
            rf = stepv.to_fraction(result)
            if rf is not None:
                bound.append(rf)

    return "admitted", None, "extraction_verified", executed, {}


def evaluate_analysis(mode: str, analysis: dict, target: dict, statement: str,
                       swipl_bin: str = "swipl", gate_script: str | None = None,
                       root: str | None = None):
    """Mode-specific gate pipeline for the 2026-08-18 recovery wave's three
    new modes. Returns (gate, reason, tier, executed, extra) where gate is
    one of declined/G2/G3/G4/admitted; reason is set unless admitted; tier
    is set only when admitted; extra is a dict of mode-specific fields to
    fold onto the output row (never overwrites analysis/executed/gate)."""
    if mode == "figure_context":
        declined = (not analysis.get("quantities")
                    and analysis.get("answer") in (None, {}))
        if declined:
            return ("declined", str(analysis.get("missing_doing"))[:120],
                     None, None, {})
        caption = target.get("caption_context") or ""
        ok2, why2, sources = gate2_numeral_binding_with_context(analysis, statement, caption)
        if not ok2:
            return "G2", why2, None, None, {}
        ok3, why3, executed = gate3_execution(analysis)
        if not ok3:
            return "G3", why3, None, None, {}
        ok4, why4 = gate4_ask(analysis, statement)
        if not ok4:
            return "G4", why4, None, None, {}
        tier = gate5_oracle(analysis, target, executed)
        if any(s == "caption" for s in sources):
            # 2026-08-18 vision wave: a target whose caption_context came
            # from a targeted vision-recovery call (or an inline docling
            # "Description of the Image" block) on THIS statement's own
            # nearby images carries "vision_grounded" -- a different,
            # narrower provenance than the earlier recovery wave's
            # whole-lesson caption dump, so it gets its own tier suffix
            # rather than reusing "_context_grounded" for a different claim.
            suffix = "_vision_grounded" if target.get("vision_grounded") else "_context_grounded"
            tier = f"{tier}{suffix}"
        return "admitted", None, tier, executed, {"quantity_sources": sources}

    if mode == "render_spec":
        quantities = analysis.get("quantities")
        render_args = analysis.get("args")
        if (not isinstance(quantities, list) or not quantities
                or not isinstance(render_args, dict) or not render_args):
            return "declined", "no_quantities_or_args", None, None, {}
        ok2, why2 = gate2_numeral_binding({"quantities": quantities}, statement)
        if not ok2:
            return "G2", why2, None, None, {}
        okr, whyr = gate_render_operands(render_args, quantities)
        if not okr:
            return "G2", whyr, None, None, {}
        op = target["candidate_op"]
        oke, whye = run_render_spec_gate(op, render_args, swipl_bin, gate_script, root)
        extra = {"op_call": {"op": op, "args": render_args}}
        if not oke:
            extra["gate_detail"] = whye
            return "G3", whye, None, None, extra
        extra["gate_detail"] = whye
        return "admitted", None, "render_verified", None, extra

    if mode == "explanation_form":
        declined = (not analysis.get("quantities")
                    and not analysis.get("steps")
                    and not analysis.get("explanation"))
        if declined:
            return "declined", "no_grounded_explanation", None, None, {}
        ok2, why2 = gate2_numeral_binding(analysis, statement)
        if not ok2:
            return "G2", why2, None, None, {}
        ok3, why3, executed = gate3_execution(analysis)
        if not ok3:
            return "G3", why3, None, None, {}
        bound_values = [to_fraction(q.get("value")) for q in analysis.get("quantities", [])
                         if isinstance(q, dict)]
        bound_values = [v for v in bound_values if v is not None]
        bound_values += [to_fraction(e["result"]) for e in executed
                          if not isinstance(e.get("result"), bool)]
        bound_values = [v for v in bound_values if v is not None]
        oke, whye = gate_explanation_numbers(analysis.get("explanation"), bound_values)
        if not oke:
            return "G3", whye, None, None, {}
        form = analysis.get("form")
        if not isinstance(form, dict) or not form:
            return "G4", "no_form", None, None, {}
        return "admitted", None, "form_grounded", executed, {"form": form}

    if mode == "step_extraction":
        return evaluate_step_extraction(analysis, statement)

    return None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--targets", required=True)
    ap.add_argument("--output", required=True)
    ap.add_argument("--backend", choices=["reallms", "openai"], required=True)
    ap.add_argument("--endpoint", default="http://127.0.0.1:8080/v1/chat/completions")
    ap.add_argument("--model", default="")
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--grades", default="")
    ap.add_argument("--record-ids", default="")
    ap.add_argument("--max-tokens", type=int, default=1200)
    ap.add_argument("--timeout", type=int, default=240)
    ap.add_argument("--shard", default="",
                    help="i/m round-robin slice of the target list, e.g. 2/6")
    ap.add_argument("--swipl-bin", default="swipl",
                    help="swipl binary for the render_spec mode's execution gate")
    ap.add_argument("--render-gate-script",
                    default=str(REPO / "scripts" / "coverage" / "render_spec_gate.pl"))
    ap.add_argument("--root", default=str(REPO),
                    help="repo root passed to render_spec_gate.pl (consults paths.pl)")
    args = ap.parse_args()

    targets = [json.loads(l) for l in open(args.targets, encoding="utf-8")]
    if args.grades:
        keep = set(args.grades.split(","))
        targets = [t for t in targets if t["grade"] in keep]
    if args.record_ids:
        keep_ids = set(Path(args.record_ids).read_text().split())
        targets = [t for t in targets if t["record_id"] in keep_ids]
    if args.shard:
        i, m = (int(x) for x in args.shard.split("/"))
        targets.sort(key=lambda t: t["record_id"])
        targets = [t for idx, t in enumerate(targets) if idx % m == i]

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    done = set()
    if out_path.exists():
        for line in open(out_path, encoding="utf-8"):
            try:
                done.add(json.loads(line)["record_id"])
            except (json.JSONDecodeError, KeyError):
                continue
    todo = [t for t in targets if t["record_id"] not in done]
    if args.limit:
        todo = todo[: args.limit]
    print(f"targets={len(targets)} done={len(done)} todo={len(todo)}", flush=True)

    reallms = None
    if args.backend == "reallms":
        sys.path.insert(0, str(REPO))
        from hermes.app import llm as reallms_mod  # lazy: laptop only
        reallms = reallms_mod
        api_key = reallms.load_key(REPO / "hermes" / "app")
        if not api_key:
            print("no REALLMS key found", flush=True)
            return 2
        api_url = reallms.resolve_api_url()
        model = args.model or reallms.resolve_model()
        ssl_ctx = reallms.build_ssl_context()
    else:
        model = args.model or "gemma-4-26B-A4B-it"

    stamp = _dt.date.today().isoformat()
    counts: dict[str, int] = {}
    with open(out_path, "a", encoding="utf-8") as out:
        for i, target in enumerate(todo):
            statement = target["statement"]
            mode = target.get("mode")
            prompt = build_prompt(target)
            if target.get("retry_note"):
                prompt += ("\n\nREPAIR NOTE — your previous reply to this "
                           "problem failed verification: " + target["retry_note"])
            row = {"record_id": target["record_id"], "lesson": target["lesson"],
                   "grade": target["grade"], "mode": mode,
                   "testimony": {"model": model, "backend": args.backend,
                                 "endpoint": args.endpoint if args.backend == "openai" else "reallms",
                                 "date": stamp}}
            t0 = time.time()
            try:
                if reallms is not None:
                    result = reallms.call_api_messages_result(
                        [{"role": "user", "content": prompt}],
                        api_key=api_key, api_url=api_url, model=model,
                        ssl_ctx=ssl_ctx, retries=2, timeout=args.timeout,
                        max_tokens=args.max_tokens)
                    if result.outcome != "ok":
                        row.update(gate="transport", reason=result.outcome)
                        out.write(json.dumps(row, ensure_ascii=False) + "\n")
                        out.flush()
                        counts["transport"] = counts.get("transport", 0) + 1
                        continue
                    content = result.content
                else:
                    content, _finish = call_openai(
                        args.endpoint, model, prompt, args.timeout, args.max_tokens)
            except Exception as exc:  # per-item guard: record and move on
                row.update(gate="transport", reason=f"{type(exc).__name__}: {exc}"[:200])
                out.write(json.dumps(row, ensure_ascii=False) + "\n")
                out.flush()
                counts["transport"] = counts.get("transport", 0) + 1
                continue
            row["elapsed_s"] = round(time.time() - t0, 1)

            analysis = last_json_object(content or "")
            if analysis is None:
                row.update(gate="G1", reason="no_json_object")
                counts["G1"] = counts.get("G1", 0) + 1
            elif mode in ("figure_context", "render_spec", "explanation_form",
                          "step_extraction"):
                gate, reason, tier, executed, extra = evaluate_analysis(
                    mode, analysis, target, statement,
                    swipl_bin=args.swipl_bin, gate_script=args.render_gate_script,
                    root=args.root)
                if gate == "admitted":
                    row.update(gate="admitted", tier=tier, analysis=analysis,
                               executed=executed, **extra)
                    counts[f"admitted:{tier}"] = counts.get(f"admitted:{tier}", 0) + 1
                else:
                    row.update(gate=gate, reason=reason, analysis=analysis, **extra)
                    counts[gate] = counts.get(gate, 0) + 1
            else:
                declined = (not analysis.get("quantities")
                            and analysis.get("answer") in (None, {}))
                if declined:
                    row.update(gate="declined",
                               reason=str(analysis.get("missing_doing"))[:120],
                               analysis=analysis)
                    counts["declined"] = counts.get("declined", 0) + 1
                else:
                    ok2, why2 = gate2_numeral_binding(analysis, statement)
                    if not ok2:
                        row.update(gate="G2", reason=why2, analysis=analysis)
                        counts["G2"] = counts.get("G2", 0) + 1
                    else:
                        ok3, why3, executed = gate3_execution(analysis)
                        if not ok3:
                            row.update(gate="G3", reason=why3, analysis=analysis)
                            counts["G3"] = counts.get("G3", 0) + 1
                        else:
                            ok4, why4 = gate4_ask(analysis, statement)
                            if not ok4:
                                row.update(gate="G4", reason=why4, analysis=analysis)
                                counts["G4"] = counts.get("G4", 0) + 1
                            else:
                                tier = gate5_oracle(analysis, target, executed)
                                row.update(gate="admitted", tier=tier,
                                           analysis=analysis, executed=executed)
                                counts[f"admitted:{tier}"] = counts.get(
                                    f"admitted:{tier}", 0) + 1
            out.write(json.dumps(row, ensure_ascii=False) + "\n")
            out.flush()
            if (i + 1) % 10 == 0:
                print(f"[{i+1}/{len(todo)}] {json.dumps(counts)}", flush=True)
    print("FINAL " + json.dumps(counts), flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
