#!/usr/bin/env python3
"""Turn a mapped curriculum row into a guarded parameter schema.

The conversion is mechanical: numerals become named parameters, and the
region they sit in becomes a constraint list written in the guard idiom the
kernel gates already speak (digit/1, lt/2, geq/2, plus/2, ones/1, base). No
model reads a numeral here. A pattern is the name of a region the registered
machines already discriminate; the witness is one verified instance of it.
"""
from __future__ import annotations

import json
from typing import Any

BASE = 10

# Parameter order per input shape, so a pattern id reads in the order a
# teacher would say the task. Keys absent from a row are skipped.
PREFERRED_ORDER = (
    "a", "b",
    "left_whole", "left_n", "left_d",
    "right_whole", "right_n", "right_d",
    "left_numeral", "left_scale",
    "right_numeral", "right_scale",
    "left", "right",
    "length", "width", "height",
    "area", "known_side", "perimeter",
    "count", "factor",
)

# Leaf keys that carry a setting rather than a quantity the student operates on.
SETTING_KEYS = {"base", "kind", "scope", "unit", "from_unit", "to_unit"}


def flatten(value: Any, prefix: str = "") -> list[tuple[str, Any]]:
    """Every leaf of an input dict, path-named, in source order."""
    out: list[tuple[str, Any]] = []
    if isinstance(value, dict):
        for key in sorted(value):
            out.extend(flatten(value[key], f"{prefix}_{key}" if prefix else key))
    elif isinstance(value, list):
        for index, item in enumerate(value, start=1):
            out.extend(flatten(item, f"{prefix}_{index}" if prefix else str(index)))
    else:
        out.append((prefix, value))
    return out


def parameters(row_input: Any) -> tuple[list[tuple[str, int]], int]:
    """Name the numeric parameters of one row and read its base."""
    base = BASE
    numeric: list[tuple[str, int]] = []
    for name, value in flatten(row_input):
        tail = name.rsplit("_", 1)[-1]
        if name == "base" and isinstance(value, int):
            base = value
            continue
        if tail in SETTING_KEYS or name in SETTING_KEYS:
            continue
        if isinstance(value, bool) or not isinstance(value, (int, float)):
            continue
        numeric.append((name, int(value) if float(value).is_integer() else value))
    order = {name: index for index, name in enumerate(PREFERRED_ORDER)}
    numeric.sort(key=lambda pair: (order.get(pair[0], len(order)), pair[0]))
    return numeric, base


def shorthand(name: str) -> str:
    return "".join(part[0] for part in name.split("_") if part)


def digit_class(value: int, base: int) -> int:
    magnitude = abs(int(value))
    if magnitude == 0:
        return 1
    digits = 0
    while magnitude:
        digits += 1
        magnitude //= base
    return digits


def parameter_constraints(name: str, value: int, base: int) -> tuple[list[str], str]:
    """Guards true of this parameter's region, plus its id token."""
    guards: list[str] = []
    token = shorthand(name)
    if value == 0:
        guards.append(f"zero({name})")
        return guards, f"{token}z"
    digits = digit_class(value, base)
    guards.append(f"digits({name},{digits})")
    if digits == 1:
        guards.append(f"digit({name})")
    token = f"{token}{digits}"
    if value % base == 0:
        guards.append(f"multiple_of_base({name})")
        token += "x"
    return guards, token


def ones(value: int, base: int) -> int:
    return abs(int(value)) % base


def relation_constraints(
    family: str, params: list[tuple[str, int]], base: int
) -> tuple[list[str], list[str]]:
    """Family relations that carve the region beyond parameter magnitude."""
    values = dict(params)
    guards: list[str] = []
    tokens: list[str] = []

    def has(*names: str) -> bool:
        return all(name in values for name in names)

    if family in {"add", "decimal_add"} and has("a", "b"):
        a, b = values["a"], values["b"]
        if ones(a, base) + ones(b, base) >= base:
            guards.append("geq(plus(ones(a),ones(b)),base)")
            tokens.append("cross_base")
        else:
            guards.append("lt(plus(ones(a),ones(b)),base)")
            tokens.append("within_base")
    elif family == "subtract" and has("a", "b"):
        a, b = values["a"], values["b"]
        if b > a:
            guards.append("gt(b,a)")
            tokens.append("negative_difference")
        elif ones(a, base) < ones(b, base):
            guards.append("lt(ones(a),ones(b))")
            tokens.append("decompose_base")
        else:
            guards.append("geq(ones(a),ones(b))")
            tokens.append("within_base")
    elif family == "multiply" and has("a", "b"):
        a, b = values["a"], values["b"]
        if abs(a) <= base and abs(b) <= base:
            guards.append("leq(a,base)")
            guards.append("leq(b,base)")
            tokens.append("single_base_facts")
        else:
            guards.append("gt(max(a,b),base)")
            tokens.append("beyond_base_facts")
    elif family == "divide" and has("a", "b"):
        a, b = values["a"], values["b"]
        if b == 0:
            guards.append("zero(b)")
            tokens.append("zero_divisor")
        elif a % b == 0:
            guards.append("divides(b,a)")
            tokens.append("exact")
        else:
            guards.append("remainder(a,b)")
            tokens.append("remainder")
    elif family in {"add_fractions", "subtract_fractions"}:
        left_d, right_d = values.get("left_d"), values.get("right_d")
        if "left_whole" in values or "right_whole" in values:
            guards.append("whole_part_present")
            tokens.append("mixed_operand")
        if left_d is None or right_d is None:
            guards.append("denominator_absent_on_one_side")
            tokens.append("whole_and_fraction")
        elif left_d == right_d:
            guards.append("eq(left_d,right_d)")
            tokens.append("same_denominator")
        elif left_d % right_d == 0 or right_d % left_d == 0:
            guards.append("divides_one_way(left_d,right_d)")
            tokens.append("related_denominator")
        else:
            guards.append("neq(left_d,right_d)")
            tokens.append("unlike_denominator")
        for side in ("left", "right"):
            if values.get(f"{side}_n") == 1:
                guards.append(f"unit_fraction({side})")
                tokens.append(f"{side}_unit")
    elif family in {"decimal_compare", "compare_numerals_by_place_value"}:
        left_name = "left_numeral" if "left_numeral" in values else "left"
        right_name = "right_numeral" if "right_numeral" in values else "right"
        left, right = values.get(left_name), values.get(right_name)
        if left is not None and right is not None:
            relation = "eq" if digit_class(left, base) == digit_class(right, base) else "neq"
            guards.append(f"{relation}(digits({left_name}),digits({right_name}))")
            tokens.append("same_length" if relation == "eq" else "different_length")
    elif family == "decimal_value" and has("a", "b"):
        guards.append("scale_is_power_of_base(b)")
        tokens.append(f"scale{values['b']}")
    elif family == "unit_fraction" and has("a", "b"):
        a, b = values["a"], values["b"]
        if b != 0 and a % b == 0:
            guards.append("divides(b,a)")
            tokens.append("whole_number_of_units")
        else:
            guards.append("not_divides(b,a)")
            tokens.append("partial_unit")
    elif family == "rectangle_missing_side_from_area" and has("area", "known_side"):
        area, side = values["area"], values["known_side"]
        if side != 0 and area % side == 0:
            guards.append("divides(known_side,area)")
            tokens.append("exact_side")
    elif family == "convert_measurement" and has("count", "factor"):
        guards.append("multiple_of_base(factor)")
        tokens.append(f"factor{values['factor']}")
    return guards, tokens


def algebraicize(family: str, row_input: Any) -> dict[str, Any] | None:
    """One row's guarded parameter schema, or None when it carries no numerals."""
    params, base = parameters(row_input)
    if not params:
        return None
    relation_guards, relation_tokens = relation_constraints(family, params, base)
    guards: list[str] = list(relation_guards)
    tokens: list[str] = list(relation_tokens)
    for name, value in params:
        parameter_guards, token = parameter_constraints(name, value, base)
        guards.extend(parameter_guards)
        tokens.append(token)
    pattern_id = "_".join(["tp", family] + tokens)
    return {
        "pattern_id": pattern_id,
        "family": family,
        "base": base,
        "parameters": [name for name, _ in params],
        "witness_values": [value for _, value in params],
        "constraints": guards,
    }


def operation_term(family: str, names: list[str]) -> str:
    return f"{family}({', '.join(names)})"


def witness_term(family: str, values: list[Any]) -> str:
    return f"{family}({', '.join(json.dumps(value) for value in values)})"
