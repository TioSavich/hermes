"""Two-pass subtraction pipeline for TalkMoves PML scoring.

The single-pass scorer asks Gemma to separate the math layer from the
discourse layer inside one call over raw transcript; the 51/2/1 mode skew
(docs/research/2026-07-01-pml-talkmoves-adversarial-review.md) is what that
separation-by-instruction produced. This module performs the separation by
subtraction instead:

  pass 1   Gemma extracts the math layer only: typed claims + candidate
           actions, each anchored to a verbatim `surface` substring of a
           named utterance. No PML vocabulary appears in the pass-1 prompt.
  dispose  Prolog adjudicates the typed claims (math_claim_checker) —
           holds / refuted / underdetermined / not_covered; unmapped shapes
           abstain as "unchecked".
  mask     A deterministic masker substitutes each verified claim surface
           with a checked token such as `[C1 n_over_n_is_one: holds]`,
           preserving every modal auxiliary, hedge, person marker, and
           force frame around it. The model proposes a surface; the masker
           verifies it verbatim against the named utterance and refuses to
           mask what it cannot verify (symbolic disposal applied to the
           masking itself).
  pass 2   Gemma codes PML posture over the residue — hard_mask variant
           (content replaced by tokens) or ledger_relief variant
           (transcript verbatim, adjudicated ledger prepended).
  compare  Masked-vs-unmasked agreement per PML field. This doubles as the
           content-independence check: if posture coding is real, it should
           survive content deletion.

Register: pipeline seam. Prompts live as tracked docs under docs/research/
(2026-07-01-talkmoves-pass1-math-prompt.md, -pass2-posture-prompt.md).
Dry-run by default; nothing here calls the network unless a caller wires
the live API through the existing scorer's `call_api`.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Any, Callable

REPO_ROOT = Path(__file__).resolve().parents[1]
PASS1_PROMPT_PATH = REPO_ROOT / "docs" / "research" / "2026-07-01-talkmoves-pass1-math-prompt.md"
PASS2_PROMPT_PATH = REPO_ROOT / "docs" / "research" / "2026-07-01-talkmoves-pass2-posture-prompt.md"

# ---------------------------------------------------------------------------
# Frame preservation
# ---------------------------------------------------------------------------
# Leading phrases trimmed off an over-captured claim surface so that the
# posture evidence they carry stays in the transcript. Tracked and small on
# purpose: every entry is a person/epistemic wrapper or modal auxiliary whose
# home is the discourse layer, not the math layer.
FRAME_PREFIXES = (
    "i think", "i guess", "i believe", "i know", "i feel", "i mean",
    "we think", "we know", "you know",
    "maybe", "probably", "definitely",
    "it has to be", "it must be", "it should be", "it could be",
    "it can't be", "it cannot be",
    "has to be", "must be", "should be", "could be",
    "it's", "it is", "that's", "that is", "so", "because",
)

# Trailing tag words stripped (with punctuation) from an over-captured surface.
FRAME_SUFFIXES = ("right", "okay", "ok", "yeah")

_UTTERANCE_LINE = re.compile(r"^(U\d{4})\s")
_TOKEN_SPAN = re.compile(r"\[[^\]]*\]")


def trim_frame(surface: str) -> str:
    """Strip leading frame phrases and trailing tags from a claim surface."""
    text = surface.strip()
    changed = True
    while changed:
        changed = False
        lowered = text.lower()
        for phrase in FRAME_PREFIXES:
            if lowered == phrase:
                return ""
            if lowered.startswith(phrase + " ") or lowered.startswith(phrase + ","):
                text = text[len(phrase):].lstrip(" ,")
                changed = True
                break
    changed = True
    while changed:
        changed = False
        text = text.rstrip(" .,!?;:")
        lowered = text.lower()
        for tag in FRAME_SUFFIXES:
            if lowered.endswith(" " + tag):
                text = text[: -len(tag)].rstrip(" ,")
                changed = True
                break
    return text.strip()


def extraction_token(extraction: dict[str, Any]) -> str:
    """Render the checked token that replaces a masked surface."""
    ident = str(extraction.get("id", "x")).upper()
    shape = extraction.get("shape", extraction.get("kind", "unknown"))
    if extraction.get("kind") == "action":
        return f"[{ident} {shape}]"
    verdict = extraction.get("verdict", "unchecked")
    return f"[{ident} {shape}: {verdict}]"


def mask_transcript(markdown: str, extractions: list[dict[str, Any]]) -> dict[str, Any]:
    """Substitute verified claim surfaces with checked tokens.

    Verbatim-verification rule: a surface is masked only where it occurs,
    case-insensitively at word boundaries, inside the utterance line the
    extraction names. Everything the masker cannot verify is skipped with a
    recorded reason; the transcript is never altered on faith.
    """
    lines = markdown.splitlines()
    line_for_utterance: dict[str, int] = {}
    for index, line in enumerate(lines):
        match = _UTTERANCE_LINE.match(line)
        if match:
            line_for_utterance[match.group(1).lower()] = index

    applied: list[dict[str, Any]] = []
    applied_extractions: list[dict[str, Any]] = []
    skipped: list[dict[str, Any]] = []

    def token_spans(text: str) -> list[tuple[int, int]]:
        return [m.span() for m in _TOKEN_SPAN.finditer(text)]

    # Longest surfaces first so a short surface never corrupts a longer mask.
    ordered = sorted(
        extractions,
        key=lambda ex: len(trim_frame(str(ex.get("surface", "")))),
        reverse=True,
    )
    for extraction in ordered:
        # Representation surfaces are the material discourse layer.  They stay
        # in the extraction record for the reader and renderer, never enter the
        # claim masker or the pass-2 ledger.
        if extraction.get("kind") == "representation":
            continue
        utterance = str(extraction.get("utterance_id", "")).lower()
        raw_surface = str(extraction.get("surface", ""))
        trimmed = trim_frame(raw_surface)
        record_base = {
            "id": extraction.get("id"),
            "utterance_id": utterance,
            "surface": raw_surface,
        }
        if not trimmed or not re.search(r"[A-Za-z0-9]", trimmed):
            skipped.append({**record_base, "reason": "frame_only_surface"})
            continue
        if utterance not in line_for_utterance:
            skipped.append({**record_base, "reason": "utterance_not_found"})
            continue
        index = line_for_utterance[utterance]
        line = lines[index]
        # Whitespace-run tolerance: TalkMoves transcription carries double
        # spaces; a single-spaced surface must still verify verbatim.
        body = r"\s+".join(re.escape(word) for word in trimmed.split())
        pattern = re.compile(
            r"(?<![A-Za-z0-9])" + body + r"(?![A-Za-z0-9])",
            re.IGNORECASE,
        )
        protected = token_spans(line)
        matches = [
            m for m in pattern.finditer(line)
            if not any(m.start() < end and m.end() > start
                       for start, end in protected)
        ]
        if not matches:
            skipped.append({**record_base, "reason": "surface_not_found"})
            continue
        token = extraction_token(extraction)
        rebuilt: list[str] = []
        cursor = 0
        for m in matches:
            rebuilt.append(line[cursor:m.start()])
            rebuilt.append(token)
            cursor = m.end()
        rebuilt.append(line[cursor:])
        lines[index] = "".join(rebuilt)
        applied.append({
            **record_base,
            "token": token,
            "occurrences": len(matches),
            "trimmed_surface": trimmed,
        })
        applied_extractions.append(extraction)

    masked = "\n".join(lines)
    if markdown.endswith("\n") and not masked.endswith("\n"):
        masked += "\n"
    return {
        "masked": masked,
        "original": markdown,
        "applied": applied,
        "skipped": skipped,
        "legend": build_ledger(applied_extractions),
    }


def build_ledger(extractions: list[dict[str, Any]]) -> list[str]:
    """One audit line per extraction: id, utterance, kind, shape, verdict.

    Surfaces are deliberately absent — the hard-mask variant must not
    reintroduce the content the mask removed.
    """
    lines = []
    for extraction in extractions:
        ident = str(extraction.get("id", "x")).upper()
        utterance = str(extraction.get("utterance_id", "?")).lower()
        kind = extraction.get("kind", "claim")
        shape = extraction.get("shape", "unknown")
        verdict = extraction.get("verdict", "unchecked")
        lines.append(f"{ident} ({utterance}) {kind} {shape}: {verdict}")
    return lines


# ---------------------------------------------------------------------------
# Pass-1 prompt (math layer only)
# ---------------------------------------------------------------------------

# JSON arg spec offered to the model for each checker-registered claim shape.
CLAIM_SHAPE_SPECS: dict[str, str] = {
    "equivalence": '{"left": {"num": 1, "den": 2}, "right": {"num": 2, "den": 4}}',
    "n_over_n_is_one": '{"frac": {"num": 12, "den": 12}}',
    "comparison": '{"left": {"num": 3, "den": 4}, "rel": "greater", "right": {"num": 1, "den": 2}}  (rel: greater/smaller/equal; operands may be fractions or whole numbers)',
    "multiplication": '{"a": {"num": 3, "den": 4}, "b": {"num": 2, "den": 5}, "product": {"num": 6, "den": 20}}',
    "fraction_of": '{"n": 12, "frac": {"num": 1, "den": 2}, "result": 6}',
    "fraction_sum": '{"a": {"num": 1, "den": 2}, "b": {"num": 1, "den": 2}, "result": 1}  (result: whole number or {"num","den"})',
    "sum": '{"a": 8, "b": 5, "c": 13}  (whole numbers only; fraction addition is "fraction_sum")',
    "subtraction": '{"a": 13, "b": 5, "c": 8}',
    "difference": '{"a": {"num": 3, "den": 4}, "b": {"num": 1, "den": 4}, "result": {"num": 2, "den": 4}}  (fraction subtraction; whole numbers go to "subtraction")',
    "improper": '{"frac": {"num": 7, "den": 5}}',
    "midpoint": '{"frac": {"num": 1, "den": 2}}',
    "iterate_to_whole": '{"frac": {"num": 1, "den": 4}, "times": 4}',
    "division_by_n_is_unit_fraction": '{"n": 4}',
    "number_line_position": '{"frac": {"num": 2, "den": 3}}',
    "ordering": '{"list": [2, 5, 9], "direction": "ascending"}  (whole numbers claimed strictly ascending or descending)',
    "arithmetic_equation": '{"left": "6 * 8", "right": "48"}  (any plain numeric equation; digits, + - * / ( ) . only)',
    "class_inclusion": '{"sub": "square", "super": "rectangle"}  (an "every SUB is a SUPER" claim; shapes: square, rectangle, rhombus, parallelogram, trapezoid, quadrilateral)',
    "shape_property": '{"shape": "rectangle", "property": "four_right_angles"}  (an "every SHAPE has PROPERTY" claim; properties: four_sides, four_right_angles, four_equal_sides, two_pairs_parallel_sides, opposite_sides_equal)',
}


def claim_shape_catalog() -> str:
    lines = ["Registered claim shapes (use these names and arg forms exactly):"]
    for shape, spec in CLAIM_SHAPE_SPECS.items():
        lines.append(f'- "{shape}": args {spec}')
    return "\n".join(lines)


REPRESENTATION_KINDS = (
    "tape_diagram", "number_line", "area_circle", "area_rectangle",
    "equation_chain",
)


def representation_catalog() -> str:
    """The only material representations pass 1 may name."""
    return "\n".join([
        "Representation mentions (not claims; use these kinds exactly):",
        "- tape_diagram: a partitioned strip/tape; needs partition_count.",
        "- number_line: a partitioned number line; needs partition_count.",
        "- area_circle: a partitioned circle/pizza; needs partition_count.",
        "- area_rectangle: a partitioned rectangle/area model; needs partition_count.",
        "- equation_chain: a written chain of equations; needs no inferred numbers.",
        "For each mention return id, utterance_id, surface, kind, partition_count",
        "(integer or null), unit_fraction ({num,den} or null), and confidence.",
        "The surface must be one exact contiguous substring. Mention only a",
        "representation actually said or described; do not infer a diagram from",
        "an equation or supply an absent partition count.",
    ])


def build_pass1_user_content(transcript_id: str, numbered_markdown: str,
                             *, action_catalog: str = "",
                             context_block: str = "") -> str:
    """User message for pass 1. Math layer only; no modal vocabulary.

    `context_block` is an optional caller-supplied section (a lesson
    monitoring chart, window framing) inserted before the transcript. The
    caller owns its wording, including any discipline the block must state
    about how the model may use it.
    """
    sections = [
        f"TRANSCRIPT_ID: {transcript_id}",
        "",
        "Extract the math layer of this blinded transcript. Return typed",
        "claims, candidate actions, and representation mentions only. Do not",
        "classify stance, tone, or speech function; a separate pass handles those.",
        "",
        "Anchoring discipline:",
        "- Every claim, action, and representation carries a `surface` field: the exact",
        "  verbatim substring of the named utterance that states the math",
        "  content. Copy it character for character; do not paraphrase.",
        "- Keep wrappers such as 'I think' or 'has to be' OUT of the",
        "  surface. The surface is the mathematical content alone.",
        "- Use lowercase utterance ids such as u0007.",
        "",
        claim_shape_catalog(),
        "",
        representation_catalog(),
    ]
    if action_catalog:
        sections.extend(["", action_catalog])
    if context_block:
        sections.extend(["", context_block])
    sections.extend([
        "",
        "----- BLINDED TRANSCRIPT -----",
        numbered_markdown,
    ])
    return "\n".join(sections)


# ---------------------------------------------------------------------------
# Adjudication (Prolog disposes)
# ---------------------------------------------------------------------------

def _fraction_term(value: Any) -> str | None:
    if isinstance(value, dict) and "num" in value and "den" in value:
        num, den = int(value["num"]), int(value["den"])
        if num < 0 or den < 0:
            return None
        return f"fraction({num},{den})"
    if isinstance(value, bool):
        raise ValueError("boolean is not a math value")
    if isinstance(value, int):
        return str(value)
    raise ValueError(f"unsupported math value: {value!r}")


def _forced_fraction_term(value: Any) -> str | None:
    """Like _fraction_term, but a whole number becomes fraction(N,1) so it
    lands in the checker's fraction clauses (which have no bare-integer
    variants in these argument positions)."""
    if isinstance(value, bool):
        raise ValueError("boolean is not a math value")
    if isinstance(value, int):
        if value < 0:
            return None
        return f"fraction({value},1)"
    return _fraction_term(value)


# The relation names the checker's comparison clauses accept, keyed by every
# surface form pass 1 has been observed to emit.
_COMPARISON_RELS = {
    "greater": "greater", "greater_than": "greater", "gt": "greater",
    ">": "greater", "more": "greater", "bigger": "greater", "larger": "greater",
    "smaller": "smaller", "less": "smaller", "less_than": "smaller",
    "lt": "smaller", "<": "smaller", "fewer": "smaller",
    "equal": "equal", "equals": "equal", "equal_to": "equal", "eq": "equal",
    "=": "equal", "same": "equal",
}

# Whitelist for arithmetic_equation sides: plain numeric expressions only.
# The term is interpolated into a swipl goal, so nothing beyond digits,
# arithmetic operators, parentheses, decimal points, and spaces may pass.
_ARITH_EXPR = re.compile(r"^[0-9+\-*/(). ]+$")
_PROLOG_ATOM = re.compile(r"^[a-z][a-z_]{0,39}$")


def _arith_side(value: Any) -> str:
    if isinstance(value, bool):
        raise ValueError("boolean is not an arithmetic expression")
    if isinstance(value, (int, float)):
        return f"({value})"
    text = str(value).strip()
    if (not text or len(text) > 80 or not _ARITH_EXPR.match(text)
            or not re.search(r"\d", text)):
        raise ValueError(f"not a plain numeric expression: {value!r}")
    return f"({text})"


def _atom(value: Any) -> str:
    text = str(value).strip().lower().replace(" ", "_").replace("-", "_")
    if not _PROLOG_ATOM.match(text):
        raise ValueError(f"not a plain atom: {value!r}")
    return text


def claim_to_term(claim: dict[str, Any]) -> str | None:
    """Map a pass-1 claim JSON object to a checker ground term, or None."""
    shape = claim.get("shape")
    args = claim.get("args", {}) or {}
    try:
        if shape == "equivalence":
            left, right = _fraction_term(args["left"]), _fraction_term(args["right"])
            return None if left is None or right is None else f"equivalence({left},{right})"
        if shape == "n_over_n_is_one":
            frac = _fraction_term(args["frac"])
            return None if frac is None else f"n_over_n_is_one({frac})"
        if shape == "comparison":
            rel = _COMPARISON_RELS.get(str(args["rel"]).strip().lower())
            if rel is None:
                return None
            left, right = _fraction_term(args["left"]), _fraction_term(args["right"])
            return None if left is None or right is None else f"comparison({left},{rel},{right})"
        if shape == "multiplication":
            # The checker takes fraction*fraction or integer*fraction; an
            # integer second factor or product must travel as N/1.
            a = _fraction_term(args["a"])
            b, product = _forced_fraction_term(args["b"]), _forced_fraction_term(args["product"])
            return None if a is None or b is None or product is None else f"multiplication({a},{b},{product})"
        if shape == "fraction_sum":
            result = args["result"]
            if isinstance(result, dict):
                target = _fraction_term(result)
            else:
                target = f"whole({int(result)})"
            a, b = _fraction_term(args["a"]), _fraction_term(args["b"])
            return None if a is None or b is None or target is None else f"fraction_sum({a},{b},{target})"
        if shape == "fraction_of":
            frac = _fraction_term(args["frac"])
            return None if frac is None else f"fraction_of({int(args['n'])},{frac},{int(args['result'])})"
        if shape == "sum":
            return f"sum({int(args['a'])},{int(args['b'])},{int(args['c'])})"
        if shape == "subtraction":
            return (f"subtraction({int(args['a'])},{int(args['b'])},"
                    f"{int(args['c'])})")
        if shape == "difference":
            result = args.get("result", args.get("c"))
            operands = (args["a"], args["b"], result)
            if all(isinstance(v, int) and not isinstance(v, bool)
                   for v in operands):
                # Whole-number difference is the subtraction checker's claim.
                return (f"subtraction({int(args['a'])},{int(args['b'])},"
                        f"{int(result)})")
            a, b, c = (_forced_fraction_term(args["a"]),
                       _forced_fraction_term(args["b"]),
                       _forced_fraction_term(result))
            return None if a is None or b is None or c is None else f"difference({a},{b},{c})"
        if shape == "ordering":
            values = args["list"]
            if not isinstance(values, list) or not values:
                return None
            direction = {"ascending": "ascending", "increasing": "ascending",
                         "descending": "descending", "decreasing": "descending",
                         }.get(str(args["direction"]).strip().lower())
            if direction is None:
                return None
            items = ",".join(str(int(v)) for v in values)
            return f"ordering([{items}],{direction})"
        if shape == "arithmetic_equation":
            return (f"arithmetic_equation({_arith_side(args['left'])},"
                    f"{_arith_side(args['right'])})")
        if shape == "class_inclusion":
            return (f"class_inclusion({_atom(args['sub'])},"
                    f"{_atom(args['super'])})")
        if shape == "shape_property":
            return (f"shape_property({_atom(args['shape'])},"
                    f"{_atom(args['property'])})")
        if shape == "improper":
            frac = _fraction_term(args["frac"])
            return None if frac is None else f"improper({frac})"
        if shape == "midpoint":
            frac = _fraction_term(args["frac"])
            return None if frac is None else f"midpoint({frac})"
        if shape == "iterate_to_whole":
            frac = _fraction_term(args["frac"])
            times = int(args["times"])
            if frac is None or times < 0:
                return None
            return f"iterate_to_whole({frac},times({times}))"
        if shape == "division_by_n_is_unit_fraction":
            return f"division_by_n_is_unit_fraction({int(args['n'])})"
        if shape == "number_line_position":
            frac = _fraction_term(args["frac"])
            return None if frac is None else f"number_line_position({frac},between(0,1))"
    except (KeyError, TypeError, ValueError):
        return None
    return None


def _run_swipl_goal(goal: str) -> subprocess.CompletedProcess:
    swipl = os.environ.get("HERMES_SWIPL", "swipl")
    return subprocess.run(
        [swipl, "-q", "-l", "paths.pl", "-s", "hermes/math_claim_checker.pl",
         "-g", goal],
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
        check=False,
    )


def swipl_check_claim(term: str) -> dict[str, Any]:
    """Adjudicate one ground claim term through math_claim_checker."""
    goal = (
        "use_module(library(http/json)), "
        f"math_claim_checker:check_math_claim({term}, D), "
        "json_write_dict(current_output, D, [width(0)]), nl, halt"
    )
    proc = _run_swipl_goal(goal)
    if proc.returncode != 0:
        return {"error": "swipl_failed", "stderr": proc.stderr.strip()}
    output = proc.stdout.strip().splitlines()
    if not output:
        return {"error": "swipl_empty_output"}
    try:
        return json.loads(output[-1])
    except json.JSONDecodeError:
        return {"error": "swipl_bad_json", "stdout": proc.stdout}


def swipl_check_claims(terms: list[str]) -> list[dict[str, Any]] | None:
    """Adjudicate many ground claim terms in ONE swipl process.

    The knowledge base load costs about a second; paying it once per
    transcript instead of once per claim is the whole point. Returns one
    dict per term, in order, or None when the batch as a whole failed (a
    syntax-broken term aborts the goal) — the caller then falls back to
    per-claim calls so one bad term cannot silence the rest.
    """
    if not terms:
        return []
    checks = ", ".join(
        f"math_claim_checker:check_math_claim({term}, D{i}), "
        f"json_write_dict(current_output, D{i}, [width(0)]), nl"
        for i, term in enumerate(terms)
    )
    goal = f"use_module(library(http/json)), {checks}, halt"
    proc = _run_swipl_goal(goal)
    if proc.returncode != 0:
        return None
    results = []
    for line in proc.stdout.strip().splitlines():
        try:
            results.append(json.loads(line))
        except json.JSONDecodeError:
            continue
    return results if len(results) == len(terms) else None


def adjudicate_claims(claims: list[dict[str, Any]],
                      runner: Callable[[str], dict[str, Any]] | None = swipl_check_claim,
                      ) -> list[dict[str, Any]]:
    """Attach a Prolog verdict to each claim; abstain honestly otherwise."""
    terms = [claim_to_term(claim) for claim in claims]
    # Default (live swipl) path: adjudicate the whole batch in one process.
    batch: dict[int, dict[str, Any]] = {}
    if runner is swipl_check_claim:
        indices = [i for i, term in enumerate(terms) if term is not None]
        results = swipl_check_claims([terms[i] for i in indices])
        if results is not None:
            batch = dict(zip(indices, results))
    adjudicated = []
    for i, claim in enumerate(claims):
        record = dict(claim)
        term = terms[i]
        if term is None:
            record["verdict"] = "unchecked"
            record["adjudication"] = {"reason": "shape_not_mapped"}
        elif runner is None:
            record["verdict"] = "unchecked"
            record["adjudication"] = {"reason": "no_runner"}
        else:
            result = batch.get(i) or runner(term)
            if "error" in result:
                record["verdict"] = "unchecked"
                record["adjudication"] = {"reason": result["error"],
                                          "detail": result}
            else:
                record["verdict"] = str(result.get("verdict",
                                                   result.get("adjudication",
                                                              "unchecked")))
                record["adjudication"] = result
        record["term"] = term
        adjudicated.append(record)
    return adjudicated


# ---------------------------------------------------------------------------
# Pass-2 prompt (posture over the residue)
# ---------------------------------------------------------------------------

_TOKEN_VERDICT = re.compile(r"\[([A-Z]+\d+ [^:\]]+): [^\]]+\]")


def blind_mask_result(mask_result: dict[str, Any]) -> dict[str, Any]:
    """Verdict-blind copy of a mask result: `[C7 equivalence: refuted]`
    becomes `[C7 equivalence]`, and the ledger drops its verdict column.

    The 'hiding wrong thinking' arm: pass-2 posture coding over this copy
    cannot lean on the adjudication, so comparing verdict-visible against
    verdict-blind coding measures whether the verdict contaminates the
    posture read."""
    blind = dict(mask_result)
    blind["masked"] = _TOKEN_VERDICT.sub(r"[\1]", mask_result.get("masked", ""))
    blind["legend"] = [line.rsplit(": ", 1)[0]
                       for line in mask_result.get("legend", [])]
    return blind


def build_pass2_user_content(transcript_id: str, mask_result: dict[str, Any],
                             *, variant: str, label: str | None = None,
                             context_block: str = "") -> str:
    """`context_block` as in build_pass1_user_content: an optional
    caller-owned section (lesson chart, window framing) before the ledger."""
    if variant not in ("hard_mask", "ledger_relief"):
        raise ValueError(f"unknown variant: {variant}")
    ledger = "\n".join(mask_result.get("legend", [])) or "(no checked claims)"
    if variant == "hard_mask":
        transcript = mask_result["masked"]
        relief = (
            "The math layer has been extracted, checked, and replaced by\n"
            "bracketed claim tokens. Code the posture each utterance enacts\n"
            "around its tokens: person, force, mode, operator, polarity."
        )
    else:
        transcript = mask_result["original"]
        relief = (
            "The math layer is already handled: every checked claim is listed\n"
            "in the ledger below. Do not re-adjudicate or re-code the math\n"
            "content. Code only what each utterance does: person, force,\n"
            "mode, operator, polarity."
        )
    sections = [
        f"TRANSCRIPT_ID: {transcript_id}",
        f"VARIANT: {label or variant}",
        "",
        relief,
    ]
    if context_block:
        sections.extend(["", context_block])
    sections.extend([
        "",
        "CLAIM LEDGER (adjudicated by the calculator):",
        ledger,
        "",
        "----- TRANSCRIPT -----",
        transcript,
    ])
    return "\n".join(sections)


# ---------------------------------------------------------------------------
# Verdict arcs (wrong thinking as signal, not category)
# ---------------------------------------------------------------------------

def _fraction_pairs(value: Any) -> set[tuple[int, int]]:
    """Collect every {num, den} pair reachable inside a claim's args."""
    pairs: set[tuple[int, int]] = set()
    if isinstance(value, dict):
        if "num" in value and "den" in value:
            try:
                pairs.add((int(value["num"]), int(value["den"])))
            except (TypeError, ValueError):
                pass
        for child in value.values():
            pairs |= _fraction_pairs(child)
    elif isinstance(value, list):
        for child in value:
            pairs |= _fraction_pairs(child)
    return pairs


def _utterance_order(utterance_id: str) -> int:
    match = re.search(r"(\d+)", str(utterance_id))
    return int(match.group(1)) if match else -1


def verdict_arcs(extractions: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Downstream fate of each refuted claim, computed from the timeline.

    A refuted claim whose fraction content reappears later in a claim that
    holds is `revisited_holds` (the classroom returned to the content and
    landed true); reappearing refuted is `reasserted_refuted`; never
    reappearing is `unresolved`. This is a deterministic join over Prolog
    verdicts and utterance order — a heuristic content-overlap signal for
    the reader to interpret, not a misconception category."""
    claims = [e for e in extractions if e.get("kind", "claim") == "claim"]
    arcs = []
    for refuted in claims:
        if refuted.get("verdict") != "refuted":
            continue
        origin = _utterance_order(refuted.get("utterance_id", ""))
        pairs = _fraction_pairs(refuted.get("args", {}))
        holds_after: list[str] = []
        refuted_after: list[str] = []
        for other in claims:
            if other is refuted:
                continue
            if _utterance_order(other.get("utterance_id", "")) <= origin:
                continue
            if not (pairs & _fraction_pairs(other.get("args", {}))):
                continue
            if other.get("verdict") == "holds":
                holds_after.append(str(other.get("id")))
            elif other.get("verdict") == "refuted":
                refuted_after.append(str(other.get("id")))
        if holds_after:
            status, evidence = "revisited_holds", holds_after
        elif refuted_after:
            status, evidence = "reasserted_refuted", refuted_after
        else:
            status, evidence = "unresolved", []
        arcs.append({
            "claim": str(refuted.get("id")),
            "utterance_id": refuted.get("utterance_id"),
            "status": status,
            "evidence": evidence,
        })
    return arcs


# ---------------------------------------------------------------------------
# Deontic adapter (M4 wire): two-pass output -> scoreboard events
# ---------------------------------------------------------------------------

_SPEAKER_LINE = re.compile(r"^(U\d{4})\s+(S\d\d):")


def transcript_speakers(numbered_markdown: str) -> dict[str, str]:
    """Map lowercase utterance ids to speaker aliases from numbered lines."""
    speakers: dict[str, str] = {}
    for line in numbered_markdown.splitlines():
        match = _SPEAKER_LINE.match(line)
        if match:
            speakers[match.group(1).lower()] = match.group(2)
    return speakers


def claims_tension(extractions: list[dict[str, Any]],
                   numbered_markdown: str) -> list[dict[str, Any]]:
    """Cross-speaker material tension: a refuted claim by one speaker sharing
    fraction content with a holds claim by a different speaker. Both verdicts
    come from the Prolog checker; the pairing is a deterministic join. This is
    the utterance-anchored cross-speaker incoherence signal (proposal M5)."""
    speakers = transcript_speakers(numbered_markdown)
    claims = [e for e in extractions if e.get("kind", "claim") == "claim"]
    tension = []
    for refuted in claims:
        if refuted.get("verdict") != "refuted":
            continue
        r_utt = str(refuted.get("utterance_id", "")).lower()
        r_speaker = speakers.get(r_utt, "?")
        r_pairs = _fraction_pairs(refuted.get("args", {}))
        for other in claims:
            if other.get("verdict") != "holds":
                continue
            o_utt = str(other.get("utterance_id", "")).lower()
            o_speaker = speakers.get(o_utt, "?")
            if o_speaker == r_speaker:
                continue
            shared = r_pairs & _fraction_pairs(other.get("args", {}))
            if not shared:
                continue
            tension.append({
                "refuted": str(refuted.get("id")),
                "refuted_speaker": r_speaker,
                "refuted_utterance": r_utt,
                "holds": str(other.get("id")),
                "holds_speaker": o_speaker,
                "holds_utterance": o_utt,
                "shared_fractions": sorted([list(p) for p in shared]),
            })
    return tension


def deontic_events_from_two_pass(
        readings: list[dict[str, Any]],
        extractions: list[dict[str, Any]],
        numbered_markdown: str,
        *,
        matcher: Callable[[str], list[str]] | None = None,
) -> list[dict[str, Any]]:
    """Adapt two-pass output to the deontic scoreboard layer's event shape.

    Posture readings contribute matcher-admitted canonical commitments
    (abstention falls back to the opaque pml_commitment wrapper, exactly as
    the audit adapter does). Adjudicated claims contribute their typed
    checker terms as commitments; a holds verdict is domain-verified, so the
    term travels as an entitlement too. Speaker attribution comes from the
    numbered transcript."""
    speakers = transcript_speakers(numbered_markdown)
    events: list[dict[str, Any]] = []

    def speaker_for(utterance_id: str) -> str:
        return speakers.get(str(utterance_id).lower(), "?")

    for reading in readings:
        content = str(reading.get("pml", {}).get("content", "") or "").strip()
        if not content:
            continue
        utterances = [str(u).lower() for u in reading.get("utterance_ids", [])]
        matched = list(matcher(content)) if matcher is not None else []
        commitments = matched or [f'pml_commitment("{content}")']
        events.append({
            "event_id": f"reading_{reading.get('id', len(events) + 1)}",
            "speaker_id": speaker_for(utterances[0]) if utterances else "?",
            "source_span_ids": utterances,
            "candidate_commitments": commitments,
            "candidate_entitlements": [],
        })

    for extraction in extractions:
        if extraction.get("kind", "claim") != "claim":
            continue
        term = extraction.get("term")
        if not term:
            continue
        utterance = str(extraction.get("utterance_id", "")).lower()
        events.append({
            "event_id": f"claim_{extraction.get('id', len(events) + 1)}",
            "speaker_id": speaker_for(utterance),
            "source_span_ids": [utterance],
            "candidate_commitments": [term],
            "candidate_entitlements": (
                [term] if extraction.get("verdict") == "holds" else []),
        })
    return events


def pool_events_cross_speaker(events: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Rewrite every event to one classroom-level agent so the deontic ops
    run over the pooled multi-speaker commitment set — the cross-speaker
    aggregation the per-speaker loop cannot perform."""
    return [dict(event, speaker_id="classroom") for event in events]


# ---------------------------------------------------------------------------
# Uptake joint distribution (the bid/field instrument)
# ---------------------------------------------------------------------------

def uptake_joint(readings: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Joint distribution over (operator, force, mode, fate) for readings
    that carry an uptake object. No move-type names are hardcoded — the
    grouping is the instrument; interpretation belongs to the reader."""
    groups: dict[tuple[str, str, str, str], list[list[str]]] = {}
    for reading in readings:
        uptake = reading.get("uptake") or {}
        fate = uptake.get("fate")
        if not fate:
            continue
        pml = reading.get("pml", {})
        key = (str(pml.get("operator")), str(pml.get("force")),
               str(pml.get("mode")), str(fate))
        groups.setdefault(key, []).append(
            [str(u) for u in reading.get("utterance_ids", [])])
    return [{"key": key, "count": len(utts), "utterances": utts}
            for key, utts in sorted(groups.items())]


# ---------------------------------------------------------------------------
# Masked-vs-unmasked agreement (the content-independence check)
# ---------------------------------------------------------------------------

_COMPARED_FIELDS = ("mode", "operator", "polarity", "force")


def compare_readings(masked: list[dict[str, Any]],
                     unmasked: list[dict[str, Any]]) -> dict[str, Any]:
    """Pair readings by utterance ids and report per-field agreement."""
    def grouped(readings):
        groups: dict[tuple[str, ...], list[dict[str, Any]]] = {}
        for reading in readings:
            key = tuple(sorted(str(u).lower()
                               for u in reading.get("utterance_ids", [])))
            groups.setdefault(key, []).append(reading)
        return groups

    masked_groups = grouped(masked)
    unmasked_groups = grouped(unmasked)
    matched = 0
    masked_only = 0
    unmasked_only = 0
    agreement = {field: {"agree": 0, "total": 0} for field in _COMPARED_FIELDS}
    disagreements: list[dict[str, Any]] = []

    for key in sorted(set(masked_groups) | set(unmasked_groups)):
        left = masked_groups.get(key, [])
        right = unmasked_groups.get(key, [])
        pairs = min(len(left), len(right))
        matched += pairs
        masked_only += len(left) - pairs
        unmasked_only += len(right) - pairs
        for m_reading, u_reading in zip(left[:pairs], right[:pairs]):
            m_pml = m_reading.get("pml", {})
            u_pml = u_reading.get("pml", {})
            for field in _COMPARED_FIELDS:
                m_value = m_pml.get(field)
                u_value = u_pml.get(field)
                if m_value is None and u_value is None:
                    continue
                agreement[field]["total"] += 1
                if m_value == u_value:
                    agreement[field]["agree"] += 1
                else:
                    disagreements.append({
                        "utterance_ids": list(m_reading.get("utterance_ids", [])),
                        "field": field,
                        "masked": m_value,
                        "unmasked": u_value,
                    })

    return {
        "matched": matched,
        "masked_only": masked_only,
        "unmasked_only": unmasked_only,
        "agreement": agreement,
        "disagreements": disagreements,
    }


# ---------------------------------------------------------------------------
# Speaker blinding (before any model call; deterministic, order of appearance)
# ---------------------------------------------------------------------------

_PASTED_SPEAKER = re.compile(r"^\s*([^:,\t]{1,40}?)\s*:\s*(.+)$")
_ALREADY_BLIND = re.compile(r"^S\d\d$")


def _table_rows(text: str) -> list[tuple[str, str]] | None:
    """Delegate table-shaped input to the app's format-agnostic ingest:
    sniffed delimiter (comma/tab/semicolon), header synonyms (name, student,
    participant, message, text, ...), and a guarded headerless two-column
    read. Falls back to None so the strict local parse below still covers
    a bare `swipl`-less checkout where the hermes package can't import."""
    try:
        if str(REPO_ROOT) not in sys.path:
            sys.path.insert(0, str(REPO_ROOT))
        from hermes.app.analysis.ingest import events_from_table
    except Exception:
        return None
    events = events_from_table(text)
    if not events:
        return None
    return [(e.student, e.text) for e in events]


def blind_transcript(text: str) -> tuple[str, dict[str, str]]:
    """Normalize a pasted transcript to blinded speaker lines.

    Accepts `Label: utterance` lines, or a delimited table — any of the
    header names the ingest layer knows, or a headerless two-column
    speaker/said shape. Labels map to S01, S02, ... in order of appearance;
    labels already in that form keep their alias. Real names never leave
    this function: this parse IS the blinding boundary, which is why it is
    deterministic and local rather than a model call."""
    rows: list[tuple[str, str]] = _table_rows(text) or []
    lines = [l for l in text.splitlines() if l.strip()]
    header = [c.strip().lower() for c in lines[0].split(",")] if lines else []
    if not rows and "speaker" in header and ("sentence" in header or "utterance" in header):
        import csv as _csv
        import io as _io
        reader = _csv.DictReader(_io.StringIO(text))
        text_col = "sentence" if "sentence" in header else "utterance"
        for record in reader:
            speaker = (record.get("speaker") or "").strip()
            said = (record.get(text_col) or "").strip()
            if speaker and said:
                rows.append((speaker, said))
    elif not rows:
        for line in lines:
            match = _PASTED_SPEAKER.match(line)
            if match:
                rows.append((match.group(1).strip(), match.group(2).strip()))
    aliases: dict[str, str] = {}
    out = []
    for speaker, said in rows:
        if speaker not in aliases:
            if _ALREADY_BLIND.match(speaker):
                aliases[speaker] = speaker
            else:
                aliases[speaker] = f"S{len(aliases) + 1:02d}"
        out.append(f"{aliases[speaker]}: {said}")
    return "\n".join(out) + ("\n" if out else ""), aliases


# ---------------------------------------------------------------------------
# Claim -> picture (thin wire onto the repo's scene-render ops)
# ---------------------------------------------------------------------------

def _frac_pair(value: Any) -> tuple[int, int] | None:
    if isinstance(value, dict) and "num" in value and "den" in value:
        try:
            return int(value["num"]), int(value["den"])
        except (TypeError, ValueError):
            return None
    return None


def claim_render_request(extraction: dict[str, Any]) -> dict[str, Any] | None:
    """Map one adjudicated claim onto a ready `/api/render` request, or None.

    The drawing packages already exist (knowledge/strategies/render/ scene compilers
    behind the worker's render ops); this is only the join. Three mappings,
    chosen because each is a straight pass-through:

    - a refuted fraction sum whose claimed result is componentwise
      (na+nb over da+db) draws the misconception itself — the
      add_numerators_and_denominators deformation filmstrip;
    - any other fraction sum or fraction difference draws the co-measured
      arithmetic, so a refuted claim sits next to the true picture;
    - a whole-number sum draws the count-on number line.

    Shapes with no scene compiler (equivalence, comparison, geometry) return
    None; no picture is invented for them.
    """
    if extraction.get("kind", "claim") != "claim":
        return None
    shape = extraction.get("shape")
    args = extraction.get("args", {}) or {}
    if shape == "fraction_sum" or shape == "difference":
        a = _frac_pair(args.get("a"))
        b = _frac_pair(args.get("b"))
        if a is None or b is None:
            return None
        if shape == "difference":
            return {"op": "fraction_render", "kind": "arith", "operation": "sub",
                    "na": a[0], "da": a[1], "nb": b[0], "db": b[1]}
        claimed = _frac_pair(args.get("result"))
        if (extraction.get("verdict") == "refuted" and claimed is not None
                and claimed == (a[0] + b[0], a[1] + b[1])):
            return {"op": "fraction_render",
                    "kind": "add_numerators_and_denominators",
                    "na": a[0], "da": a[1], "nb": b[0], "db": b[1]}
        return {"op": "fraction_render", "kind": "arith", "operation": "add",
                "na": a[0], "da": a[1], "nb": b[0], "db": b[1]}
    if shape == "sum":
        try:
            a, b = int(args["a"]), int(args["b"])
        except (KeyError, TypeError, ValueError):
            return None
        return {"op": "number_line_render", "mode": "jumps",
                "strategy": "COBO", "a": a, "b": b}
    return None


# ---------------------------------------------------------------------------
# Teacher report (reader-facing; no Prolog, no operator names in the prose)
# ---------------------------------------------------------------------------

VERDICT_FINDING = {
    "holds": "holds",
    "refuted": "refuted",
}
VERDICT_GLOSS = {
    "holds": "the calculator worked the claim through and it holds",
    "refuted": "the calculator worked the claim through and it fails",
}
_UNCHECKED_FINDING = "not covered"
_UNCHECKED_GLOSS = "outside what the calculator can currently check"

MOVE_PHRASE = {
    ("compressive", "comp_nec"): "treats the question as settled",
    ("compressive", "comp_poss"): "floats a candidate answer without settling it",
    ("expansive", "exp_poss"): "opens an alternative",
    ("expansive", "exp_nec"): "asks for openness: an explanation or a return "
                              "to the idea is required",
}
MODE_PHRASE = {
    "subjective": "speaking for themselves",
    "objective": "about the shared math",
    "normative": "about what the class may or must do",
}
FATE_PHRASE = {
    "taken_up": "the class took it up",
    "elaborated": "the class built on it",
    "contested": "the class pushed back",
    "narrowed": "the class narrowed it",
    "dropped": "the class let it drop",
    "repaired": "the class returned and repaired it",
}

TALKMOVES_ATTRIBUTION = ("Transcript data: TalkMoves dataset (SumnerLab / "
                         "Suresh et al.), CC BY-NC-SA 4.0, speaker-blinded "
                         "before any model call.")
LOCAL_ATTRIBUTION = ("Transcript supplied by the teacher; speakers blinded "
                     "on this machine before the report passes ran.")


def attribution_for(transcript_id: str) -> str:
    """TalkMoves ids (tm_*) carry the dataset attribution; everything else
    is the teacher's own transcript and must not claim to be TalkMoves data."""
    return (TALKMOVES_ATTRIBUTION if str(transcript_id).startswith("tm_")
            else LOCAL_ATTRIBUTION)


def _anchor_by_id(mask_result):
    """Claim-grain anchor verdict, read off the masker's verbatim gate.

    `mask_transcript` already runs the verbatim source-anchoring check on every
    report: a claim surface that verifies word-for-word inside its cited
    utterance lands in `applied`; a surface- or utterance-miss lands in
    `skipped`. This just names the buckets so the reader-facing row can assert
    "this refuted claim is anchored to a real student utterance." A frame-only
    surface has no math content to anchor, so it is not_applicable rather than a
    failed anchoring."""
    out = {}
    for record in mask_result.get("applied", []):
        out[str(record.get("id"))] = "anchored"
    for record in mask_result.get("skipped", []):
        out[str(record.get("id"))] = (
            "not_applicable" if record.get("reason") == "frame_only_surface"
            else "unanchored")
    return out


def _claim_rows(extractions, speakers, anchor_by_id=None):
    anchor_by_id = anchor_by_id or {}
    rows = []
    for e in extractions:
        if e.get("kind", "claim") != "claim":
            continue
        verdict = e.get("verdict", "unchecked")
        utterance = str(e.get("utterance_id", "")).lower()
        row = {
            "speaker": speakers.get(utterance, "?"),
            "utterance": utterance,
            "said": e.get("surface", ""),
            "finding": VERDICT_FINDING.get(verdict, _UNCHECKED_FINDING),
            "how": VERDICT_GLOSS.get(verdict, _UNCHECKED_GLOSS),
            "anchor_verdict": anchor_by_id.get(str(e.get("id")), "not_applicable"),
        }
        render = claim_render_request(e)
        if render is not None:
            row["render"] = render
        rows.append(row)
    return rows


def teacher_report(transcript_id: str,
                   extractions: list[dict[str, Any]],
                   readings: list[dict[str, Any]],
                   numbered_markdown: str,
                   mask_result: dict[str, Any] | None = None) -> dict[str, Any]:
    """A report a reader without Prolog or PML can interpret.

    Every finding is a plain sentence anchored to an utterance id. The full
    machine detail (typed terms, verdict dicts, raw readings) rides along
    under the single `machine` key for anyone who wants to audit it.

    Each claim row also carries an `anchor_verdict` read off the verbatim
    source-anchoring gate. Pass the already-computed `mask_result` to reuse it;
    otherwise the report recomputes it so CLI and test callers need not."""
    speakers = transcript_speakers(numbered_markdown)
    if mask_result is None:
        mask_result = mask_transcript(numbered_markdown, extractions)
    claims = _claim_rows(extractions, speakers, _anchor_by_id(mask_result))
    checked = [c for c in claims if c["finding"] != _UNCHECKED_FINDING]
    failed = [c for c in claims if c["finding"] == "refuted"]

    arcs = []
    for arc in verdict_arcs(extractions):
        utterance = str(arc.get("utterance_id", "")).lower()
        speaker = speakers.get(utterance, "?")
        if arc["status"] == "revisited_holds":
            arcs.append({
                "sentence": (f"{speaker}'s claim at {utterance} was refuted, "
                             "and the discussion returned to the same content "
                             "later and landed on a version that holds."),
                "anchors": [utterance] + arc["evidence"],
            })
        elif arc["status"] == "reasserted_refuted":
            arcs.append({
                "sentence": (f"{speaker}'s claim at {utterance} does not "
                             "check out, and the same content came back "
                             "later still not checking out."),
                "anchors": [utterance] + arc["evidence"],
            })
        else:
            arcs.append({
                "sentence": (f"{speaker}'s claim at {utterance} does not "
                             "check out, and the discussion did not return "
                             "to it."),
                "anchors": [utterance],
            })

    # One conflict per speaker pair for the reader; the anchors accumulate.
    tension_pairs: dict[tuple[str, str, str], dict[str, Any]] = {}
    for t in claims_tension(extractions, numbered_markdown):
        key = (t["refuted_speaker"], t["refuted_utterance"],
               t["holds_speaker"])
        row = tension_pairs.setdefault(key, {
            "sentence": (f"{t['refuted_speaker']} (at {t['refuted_utterance']}) "
                         f"and {t['holds_speaker']} (at {t['holds_utterance']}) "
                         "have made claims about the same fractions that "
                         "cannot both stand; the calculator backs "
                         f"{t['holds_speaker']}'s."),
            "anchors": [t["refuted_utterance"]],
        })
        if t["holds_utterance"] not in row["anchors"]:
            row["anchors"].append(t["holds_utterance"])
    tensions = list(tension_pairs.values())

    postures = []
    for reading in readings:
        pml = reading.get("pml", {})
        move = MOVE_PHRASE.get((str(pml.get("polarity")),
                                str(pml.get("operator"))))
        if not move:
            continue
        utterances = [str(u).lower() for u in reading.get("utterance_ids", [])]
        fate = (reading.get("uptake") or {}).get("fate")
        postures.append({
            "speaker": speakers.get(utterances[0], "?") if utterances else "?",
            "utterances": utterances,
            "move": move,
            "register": MODE_PHRASE.get(str(pml.get("mode")), ""),
            "response": FATE_PHRASE.get(fate, "no response recorded"),
        })

    headline = (f"{len(claims)} mathematical claims heard; "
                f"{len(checked)} checked by the calculator, "
                f"{len(failed)} refuted"
                + (f"; {len(tensions)} cross-speaker conflicts surfaced"
                   if tensions else "")
                + (". Every failed claim was later repaired in discussion."
                   if arcs and all("landed on a version" in a["sentence"]
                                   for a in arcs)
                   else "."))

    return {
        "transcript_id": transcript_id,
        "headline": headline,
        "claims": claims,
        "repair_arcs": arcs,
        "tensions": tensions,
        "postures": postures,
        "attribution": attribution_for(transcript_id),
        "caveats": [
            "The calculator checks a claim only when it can ground it; "
            "'not covered' means outside its current coverage, not wrong.",
            "Reading a speaker's move is interpretive. The model proposes "
            "the reading; only the claim verdicts are computed.",
            "One automated read of one transcript — a starting point for "
            "your own reading, not a verdict on the discussion.",
        ],
        "machine": {
            "extractions": extractions,
            "readings": readings,
        },
        "transcript": numbered_markdown,
    }


# ---------------------------------------------------------------------------
# CLI (thin glue; the tested logic is all above)
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="command", required=True)

    p1 = sub.add_parser("pass1", help="Build the pass-1 (math-only) prompt.")
    p1.add_argument("--transcript-file", type=Path, required=True)
    p1.add_argument("--transcript-id", default="tm_local")
    p1.add_argument("--out", type=Path, required=True)

    adj = sub.add_parser("adjudicate", help="Run claims through Prolog.")
    adj.add_argument("--claims", type=Path, required=True,
                     help="JSON array of pass-1 claim objects.")
    adj.add_argument("--out", type=Path, required=True)

    msk = sub.add_parser("mask", help="Mask adjudicated claims into tokens.")
    msk.add_argument("--transcript-file", type=Path, required=True)
    msk.add_argument("--extractions", type=Path, required=True)
    msk.add_argument("--out", type=Path, required=True)

    p2 = sub.add_parser("pass2", help="Build the pass-2 (posture) prompt.")
    p2.add_argument("--mask-result", type=Path, required=True)
    p2.add_argument("--transcript-id", default="tm_local")
    p2.add_argument("--variant", choices=("hard_mask", "ledger_relief"),
                    default="hard_mask")
    p2.add_argument("--out", type=Path, required=True)

    cmp_p = sub.add_parser("compare", help="Masked-vs-unmasked agreement.")
    cmp_p.add_argument("--masked", type=Path, required=True)
    cmp_p.add_argument("--unmasked", type=Path, required=True)
    cmp_p.add_argument("--out", type=Path, required=True)

    score = sub.add_parser(
        "score",
        help="Chain pass1 -> adjudicate -> mask -> pass2 for one transcript. "
             "Dry-run by default (writes the pass-1 request and stops); "
             "--live calls Gemma via the blind-corpus scorer's client.")
    score.add_argument("--transcript-file", type=Path, required=True)
    score.add_argument("--transcript-id", default="tm_local")
    score.add_argument("--out-dir", type=Path, required=True)
    score.add_argument("--live", action="store_true")
    score.add_argument("--variant", choices=("hard_mask", "ledger_relief"),
                       default="hard_mask")

    deo = sub.add_parser(
        "deontic",
        help="Compose a scored run into the deontic layer: adapter -> "
             "per-speaker scoreboard -> pooled cross-speaker board -> "
             "claims tension. Needs a local swipl worker, no LLM.")
    deo.add_argument("--numbered", type=Path, required=True)
    deo.add_argument("--extractions", type=Path, required=True)
    deo.add_argument("--readings", type=Path, required=True,
                     help="pass-2 JSON (its `readings` array is used).")
    deo.add_argument("--out", type=Path, required=True)

    args = parser.parse_args(argv)

    if args.command == "score":
        return run_score(args)
    if args.command == "deontic":
        return run_deontic(args)

    if args.command == "pass1":
        content = build_pass1_user_content(
            args.transcript_id,
            args.transcript_file.read_text(encoding="utf-8"))
        args.out.write_text(content, encoding="utf-8")
    elif args.command == "adjudicate":
        claims = json.loads(args.claims.read_text(encoding="utf-8"))
        args.out.write_text(
            json.dumps(adjudicate_claims(claims), indent=2, sort_keys=True) + "\n",
            encoding="utf-8")
    elif args.command == "mask":
        result = mask_transcript(
            args.transcript_file.read_text(encoding="utf-8"),
            json.loads(args.extractions.read_text(encoding="utf-8")))
        args.out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n",
                            encoding="utf-8")
    elif args.command == "pass2":
        mask_result = json.loads(args.mask_result.read_text(encoding="utf-8"))
        content = build_pass2_user_content(
            args.transcript_id, mask_result, variant=args.variant)
        args.out.write_text(content, encoding="utf-8")
    elif args.command == "compare":
        report = compare_readings(
            json.loads(args.masked.read_text(encoding="utf-8")),
            json.loads(args.unmasked.read_text(encoding="utf-8")))
        args.out.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n",
                            encoding="utf-8")
    print(f"[two-pass] {args.command} -> {args.out}", file=sys.stderr)
    return 0


def _load_scorer():
    """Load the blind-corpus scorer by path (numbering, dotenv, call_api)."""
    import importlib.util
    path = REPO_ROOT / "scripts" / "talkmoves_score_blind_corpus.py"
    spec = importlib.util.spec_from_file_location("talkmoves_scorer", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def run_deontic(args) -> int:
    """M5 composition: scored-run artifacts -> deontic boards + tension.

    Consolidates the scoreboard layer behind the two-pass CLI (it was a
    free-standing script): per-speaker boards via the commitment matcher,
    one pooled classroom-level board for cross-speaker incoherence, and the
    deterministic claims-tension join."""
    import importlib.util
    layer_path = REPO_ROOT / "scripts" / "pml_deontic_scoreboard_layer.py"
    spec = importlib.util.spec_from_file_location("deontic_layer", layer_path)
    layer = importlib.util.module_from_spec(spec)
    if str(REPO_ROOT) not in sys.path:
        sys.path.insert(0, str(REPO_ROOT))
    spec.loader.exec_module(layer)
    from hermes.app.worker import PersistentPrologWorker

    numbered = args.numbered.read_text(encoding="utf-8")
    extractions = json.loads(args.extractions.read_text(encoding="utf-8"))
    readings = json.loads(args.readings.read_text(encoding="utf-8"))
    if isinstance(readings, dict):
        readings = readings.get("readings", [])

    match_worker = PersistentPrologWorker()
    try:
        matcher = layer.worker_commitment_matcher(match_worker)
        events = deontic_events_from_two_pass(
            readings, extractions, numbered, matcher=matcher)
    finally:
        try:
            match_worker.close()
        except Exception:
            pass
    per_speaker = layer.deontic_scoreboard_layer(events)
    pooled = layer.deontic_scoreboard_layer(pool_events_cross_speaker(events))
    result = {
        "events": len(events),
        "per_speaker": per_speaker,
        "pooled_classroom": pooled,
        "claims_tension": claims_tension(extractions, numbered),
    }
    args.out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n",
                        encoding="utf-8")
    return 0


def run_score(args) -> int:
    """The tracked automated path: transcript -> per-utterance PML readings.

    Dry-run assembles and persists the pass-1 request so the exact prompt is
    auditable without network access; --live runs the full chain through the
    scorer's REALLMS client and the local Prolog adjudicator."""
    scorer = _load_scorer()
    out_dir = args.out_dir
    out_dir.mkdir(parents=True, exist_ok=True)
    tid = args.transcript_id
    markdown = args.transcript_file.read_text(encoding="utf-8")
    numbered, _aliases = scorer.number_transcript(markdown)
    (out_dir / f"{tid}_numbered.md").write_text(numbered, encoding="utf-8")
    user = build_pass1_user_content(tid, numbered)
    (out_dir / f"{tid}_pass1_request.txt").write_text(user, encoding="utf-8")
    manifest: dict[str, Any] = {"transcript_id": tid, "live": bool(args.live),
                                "variant": args.variant,
                                "stages_run": ["pass1_request"]}
    if args.live:
        scorer.load_dotenv(scorer.DEFAULT_INSTRUMENT_RUN)
        system1 = PASS1_PROMPT_PATH.read_text(encoding="utf-8")
        reply1 = scorer.call_api(system1, user, retries=2, timeout=240)
        (out_dir / f"{tid}_pass1_reply.md").write_text(reply1, encoding="utf-8")
        start = reply1.find("{", max(reply1.find("## MATH_JSON"), 0))
        math_json = json.loads(reply1[start:reply1.rfind("}") + 1])
        extractions = adjudicate_claims(math_json.get("claims", []))
        (out_dir / f"{tid}_extractions.json").write_text(
            json.dumps(extractions, indent=2, sort_keys=True) + "\n",
            encoding="utf-8")
        mask_result = mask_transcript(numbered, extractions)
        (out_dir / f"{tid}_mask.json").write_text(
            json.dumps(mask_result, indent=2, sort_keys=True) + "\n",
            encoding="utf-8")
        system2 = PASS2_PROMPT_PATH.read_text(encoding="utf-8")
        user2 = build_pass2_user_content(tid, mask_result,
                                         variant=args.variant)
        reply2 = scorer.call_api(system2, user2, retries=2, timeout=240)
        (out_dir / f"{tid}_pass2_reply.md").write_text(reply2, encoding="utf-8")
        start2 = reply2.find("{", max(reply2.find("## PML_JSON"), 0))
        pml_json = json.loads(reply2[start2:reply2.rfind("}") + 1])
        (out_dir / f"{tid}_pass2.json").write_text(
            json.dumps(pml_json, indent=2, sort_keys=True) + "\n",
            encoding="utf-8")
        manifest["stages_run"] = ["pass1", "adjudicate", "mask", "pass2"]
        manifest["claims"] = len(math_json.get("claims", []))
        manifest["readings"] = len(pml_json.get("readings", []))
    (out_dir / f"{tid}_score_manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n",
        encoding="utf-8")
    print(f"[two-pass] score ({'live' if args.live else 'dry-run'}) -> {out_dir}",
          file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
