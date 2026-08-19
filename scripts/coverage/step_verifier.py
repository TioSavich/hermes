"""Exact-arithmetic re-execution for one ledger step, independent of the gate
that produced it.

merged_admitted_ledger.jsonl and recovery_wave_ledger.jsonl each carry a gate
(admitted / declined / G1-G4) that reports whether the PIPELINE trusted a
row's full analysis (every quantity bound to the statement's bytes, an ask
that shares the statement's content, an answer that is one of the steps'
results). That gate is a fact about the whole row. It is not what this module
answers.

This module answers a narrower question, one step at a time: does the
step's declared result actually follow from its declared operands, under
exact rational arithmetic? A row that DECLINED for an unrelated reason (an
unreadable ask, an answer that was not among the steps) can still carry
steps whose arithmetic is independently checkable and true; a row that was
ADMITTED still needs each step checked here before an explanation quotes it,
because admission verified the row's ask and answer, never every
intermediate step's arithmetic in isolation.

Verification uses fractions.Fraction throughout -- never float equality --
so 0.1 + 0.2 reads as 3/10, not as whatever double is closest to it, and a
step is never accepted on floating-point luck.

Only operations with one unambiguous, well-defined semantics from operands
alone are covered. Operations whose meaning depends on a scheme or method
the operands cannot disclose (sharing-division vs measurement-division;
"classify" as exact/estimated; "sort" rank without a declared order) are
deliberately left unverifiable here -- returning None, never a guessed True.
"""
from __future__ import annotations

import math
from fractions import Fraction
from typing import Optional

# --- operand/result parsing -------------------------------------------------


def to_fraction(value) -> Optional[Fraction]:
    """Exact number from an int/float/numeric-string; None when unreadable.

    Floats are read through their repr string, so a JSON literal like 0.5
    reads as the exact fraction 1/2 rather than the nearest IEEE double --
    the ledgers hold values `json.load`-ed from model output, and
    `str(float)` round-trips the shortest decimal that reproduces it.
    """
    if isinstance(value, bool) or value is None:
        return None
    if isinstance(value, int):
        return Fraction(value)
    if isinstance(value, float):
        try:
            return Fraction(str(value))
        except (ValueError, ArithmeticError):
            return None
    if isinstance(value, str):
        text = value.strip().replace(",", "").replace("$", "")
        if not text:
            return None
        try:
            return Fraction(text)
        except (ValueError, ZeroDivisionError):
            return None
    return None


def round_half_up(value: Fraction, ndigits: int) -> Fraction:
    """Round-half-up (ties away from zero) at decimal place `ndigits`.

    `ndigits` follows Python's `round()` convention: positive rounds after
    the decimal point, negative rounds before it (-3 rounds to the nearest
    thousand).
    """
    scale = Fraction(10) ** ndigits
    scaled = value * scale
    sign = 1 if scaled >= 0 else -1
    rounded_units = math.floor(abs(scaled) + Fraction(1, 2))
    return sign * Fraction(rounded_units) / scale


# --- operation name classes -------------------------------------------------

ADD_OPS = {"add", "addition", "sum", "plus"}
SUB_OPS = {"subtract", "subtraction", "minus", "difference"}
MUL_OPS = {"multiply", "multiplication", "product"}
DIV_OPS = {"divide", "division", "quotient"}
POW_OPS = {"exponentiation", "power", "exponent"}
SQUARE_OPS = {"square"}
MOD_OPS = {"modulo", "remainder", "mod"}
FLOOR_OPS = {"floor"}
CEIL_OPS = {"ceil", "ceiling"}
ROUND_WHOLE_OPS = {"round_nearest_whole", "round_to_whole", "round_whole"}
ROUND_TENTH_OPS = {"round_nearest_tenth"}
ROUND_HUNDREDTH_OPS = {"round_nearest_hundredth"}
ROUND_THOUSAND_OPS = {"round_to_nearest_thousand", "rounding_to_nearest_thousand"}
COUNT_ZEROS_OPS = {"count_zeros"}
DIVISIBILITY_OPS = {"compare_divisibility", "divisible_by", "is_divisible"}
INTERIOR_ANGLE_OPS = {"interior_angle_calculation", "interior_angle"}
PERIMETER_OPS = {"calculate_perimeter", "perimeter"}

EQ_CMP_OPS = {"compare_equal", "equal_to", "equals"}
GT_CMP_OPS = {"compare_greater", "compare_greater_than", "greater_than"}
LT_CMP_OPS = {"compare_less", "compare_less_than", "less_than"}
GE_CMP_OPS = {"compare_greater_than_or_equal", "greater_than_or_equal"}
LE_CMP_OPS = {"compare_less_than_or_equal", "less_than_or_equal"}

BOOL_RESULT_OPS = (
    EQ_CMP_OPS | GT_CMP_OPS | LT_CMP_OPS | GE_CMP_OPS | LE_CMP_OPS | DIVISIBILITY_OPS
)

# Every op class this module can decide. An operation NOT in this union
# returns None from verify_step -- unverifiable, never guessed.
KNOWN_OPS = (
    ADD_OPS | SUB_OPS | MUL_OPS | DIV_OPS | POW_OPS | SQUARE_OPS | MOD_OPS
    | FLOOR_OPS | CEIL_OPS | ROUND_WHOLE_OPS | ROUND_TENTH_OPS
    | ROUND_HUNDREDTH_OPS | ROUND_THOUSAND_OPS | COUNT_ZEROS_OPS
    | DIVISIBILITY_OPS | INTERIOR_ANGLE_OPS | PERIMETER_OPS | BOOL_RESULT_OPS
)


def verify_step(operation, operands, result) -> Optional[bool]:
    """True/False the step's arithmetic re-executes to the declared result;
    None when the operation, operand count, or operand/result types are
    outside what this module can decide without guessing.
    """
    opl = str(operation or "").strip().lower()
    operands = operands or []

    if opl in BOOL_RESULT_OPS:
        if not isinstance(result, bool):
            return None
        fracs = [to_fraction(o) for o in operands]
        if any(f is None for f in fracs):
            return None
        if opl in EQ_CMP_OPS:
            if len(fracs) < 2:
                return None
            return (all(f == fracs[0] for f in fracs[1:])) == result
        if opl in DIVISIBILITY_OPS:
            if len(fracs) != 2 or fracs[1] == 0:
                return None
            if fracs[0].denominator != 1 or fracs[1].denominator != 1:
                return None
            return (fracs[0].numerator % fracs[1].numerator == 0) == result
        if len(fracs) != 2:
            return None
        a, b = fracs
        if opl in GT_CMP_OPS:
            return (a > b) == result
        if opl in LT_CMP_OPS:
            return (a < b) == result
        if opl in GE_CMP_OPS:
            return (a >= b) == result
        if opl in LE_CMP_OPS:
            return (a <= b) == result
        return None

    if opl not in KNOWN_OPS:
        return None

    res = to_fraction(result)
    if res is None:
        return None
    fracs = [to_fraction(o) for o in operands]
    if any(f is None for f in fracs):
        return None

    if opl in ADD_OPS:
        if len(fracs) < 2:
            return None
        return sum(fracs, Fraction(0)) == res
    if opl in SUB_OPS:
        if len(fracs) != 2:
            return None
        return fracs[0] - fracs[1] == res
    if opl in MUL_OPS:
        if len(fracs) < 2:
            return None
        product = Fraction(1)
        for f in fracs:
            product *= f
        return product == res
    if opl in DIV_OPS:
        if len(fracs) != 2 or fracs[1] == 0:
            return None
        return fracs[0] / fracs[1] == res
    if opl in POW_OPS:
        if len(fracs) != 2 or fracs[1].denominator != 1 or abs(fracs[1].numerator) > 20:
            return None
        base, exp = fracs[0], fracs[1].numerator
        if exp < 0 and base == 0:
            return None
        return (base ** exp if exp >= 0 else Fraction(1) / (base ** (-exp))) == res
    if opl in SQUARE_OPS:
        if len(fracs) != 1:
            return None
        return fracs[0] ** 2 == res
    if opl in MOD_OPS:
        if len(fracs) != 2 or fracs[1] == 0:
            return None
        if fracs[0].denominator != 1 or fracs[1].denominator != 1:
            return None
        return (fracs[0].numerator % fracs[1].numerator) == res
    if opl in FLOOR_OPS:
        if len(fracs) != 1:
            return None
        return Fraction(math.floor(fracs[0])) == res
    if opl in CEIL_OPS:
        if len(fracs) != 1:
            return None
        return Fraction(math.ceil(fracs[0])) == res
    if opl in ROUND_WHOLE_OPS:
        if len(fracs) != 1:
            return None
        return round_half_up(fracs[0], 0) == res
    if opl in ROUND_TENTH_OPS:
        if len(fracs) != 1:
            return None
        return round_half_up(fracs[0], 1) == res
    if opl in ROUND_HUNDREDTH_OPS:
        if len(fracs) != 1:
            return None
        return round_half_up(fracs[0], 2) == res
    if opl in ROUND_THOUSAND_OPS:
        if len(fracs) != 1:
            return None
        return round_half_up(fracs[0], -3) == res
    if opl in COUNT_ZEROS_OPS:
        if len(fracs) != 1 or fracs[0].denominator != 1:
            return None
        return str(abs(fracs[0].numerator)).count("0") == res
    if opl in INTERIOR_ANGLE_OPS:
        if len(fracs) != 1 or fracs[0].denominator != 1 or fracs[0] <= 2:
            return None
        n = fracs[0]
        return (n - 2) * 180 / n == res
    if opl in PERIMETER_OPS:
        if len(fracs) != 2:
            return None
        return 2 * (fracs[0] + fracs[1]) == res
    return None


def verified_steps(steps) -> list[dict]:
    """The subset of a `steps` list this module can independently confirm,
    each tagged `verified: True`. Steps whose operation, operand count, or
    types this module cannot decide are dropped -- never included as
    unverified, never marked False (False would claim the pipeline's own
    arithmetic is wrong, which this module has no standing to say for
    operations it cannot re-derive)."""
    out = []
    for step in steps or []:
        if not isinstance(step, dict):
            continue
        ok = verify_step(step.get("operation"), step.get("operands"), step.get("result"))
        if ok is True:
            out.append(step)
    return out
