#!/usr/bin/env python3
"""Sweep reviewed typed input classes and render the a-fortiori receipt.

The JSON predicate column is reviewed prose, never an atom-name inference.
This bounded battery is its executable restatement, including dissent branches
and refused comparisons.  It deliberately does not load learner servers or the
geometry bridge; one SWI-Prolog invocation checks both loaded automaton probes.
"""
from __future__ import annotations

import argparse
import difflib
import json
import subprocess
import sys
import tempfile
from collections import Counter
from dataclasses import dataclass
from fractions import Fraction
from itertools import permutations
from operator import attrgetter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
INPUT_CLASSES = ROOT / "formal/incompatibility/context_input_classes.json"
NESTINGS = ROOT / "formal/incompatibility/a_fortiori_context_nestings.json"
RECEIPT = ROOT / "docs/research/2026-07-29-a-fortiori-input-nesting-settlement.md"

FRACTION_CONTEXT_NAMES = {
    "GAP": "gap_order_diverges_from_fraction_order",
    "DEN": "denominator_order_inverts_for_equal_numerators",
    "CSUM": "component_sum_inverts_for_equal_numerators",
    "CORD": "component_order_inverts_for_equal_numerators",
    "NORD": "numerator_order_diverges_for_unequal_denominators",
    "IDEN": "inverse_denominator_order_diverges_for_unequal_numerators",
    "ICOMP": "inverse_component_order_diverges_for_equal_denominators",
}

@dataclass(frozen=True)
class DecimalNumeral:
    whole: int
    digits: str

    def display(self) -> str:
        return f"{self.whole}.{self.digits}"


@dataclass(frozen=True)
class DecimalContextFeatures:
    raw_disagrees: bool
    equal_integer_part_diverges: bool
    length_inverts: bool
    length_tracks: bool
    different_places: bool
    written_diverges: bool
    smaller_fraction_part_tracks: bool


DECIMAL_CONTEXT_SPECS = (
    ("fraction_part_numeral_order_diverges_from_value_order",
     attrgetter("raw_disagrees")),
    ("fraction_part_numeral_order_diverges_within_equal_integer_parts",
     attrgetter("equal_integer_part_diverges")),
    ("numeral_length_order_inverts_decimal_value_order",
     attrgetter("length_inverts")),
    ("numeral_length_order_tracks_decimal_value_order",
     attrgetter("length_tracks")),
    ("the_numerals_carry_different_place_counts",
     attrgetter("different_places")),
    ("written_numeral_order_diverges_from_decimal_value_order",
     attrgetter("written_diverges")),
    ("smaller_fraction_part_numeral_names_the_smaller_decimal",
     attrgetter("smaller_fraction_part_tracks")),
)
DECIMAL_CONTEXT_NAMES = tuple(
    name for name, _predicate in DECIMAL_CONTEXT_SPECS
)


def sign(value: int | Fraction) -> int:
    return (value > 0) - (value < 0)


def verdict(row: dict[str, object]) -> str:
    if row["narrow_minus_broad"] == 0 and row["broad_minus_narrow"]:
        return "contained_strict"
    if row["narrow_minus_broad"] == 0 and row["broad_minus_narrow"] == 0:
        return "contained_equal"
    if row["narrow"] and row["broad"] and row["narrow_minus_broad"] == row["narrow"]:
        return "refused_disjoint"
    return "refused_counterexample"


def fraction_display(pair: tuple[tuple[int, int], tuple[int, int]]) -> str:
    return f"{pair[0][0]}/{pair[0][1]} vs {pair[1][0]}/{pair[1][1]}"


def fraction_grid(limit: int) -> list[tuple[tuple[int, int], tuple[int, int]]]:
    fractions = [(n, d) for d in range(2, limit + 1) for n in range(1, d)]
    return [(left, right) for left in fractions for right in fractions if left != right]


def exact(left: tuple[int, int], right: tuple[int, int]) -> int:
    return sign(left[0] * right[1] - right[0] * left[1])


def natural(left: int, right: int, abstain_ties: bool = False) -> int | None:
    if abstain_ties and left == right:
        return None
    return sign(left - right)


def dominance(left: tuple[int, int], right: tuple[int, int], strict_and: bool = False) -> int | None:
    ln, ld = left
    rn, rd = right
    if strict_and:
        if ln > rn and ld > rd:
            return 1
        if rn > ln and rd > ld:
            return -1
        return None
    if ln >= rn and ld >= rd and (ln > rn or ld > rd):
        return 1
    if rn >= ln and rd >= ld and (rn > ln or rd > ld):
        return -1
    return None


def defeat(pairs, rule):
    return {pair for pair in pairs if (produced := rule(*pair)) is not None and produced != exact(*pair)}


def fraction_classes(limit: int, *, abstain_ties: bool = False, strict_and: bool = False):
    pairs = fraction_grid(limit)
    den = {pair for pair in pairs if pair[0][0] == pair[1][0]}
    gap = {pair for pair in pairs if pair[0][1] - pair[0][0] == pair[1][1] - pair[1][0]}
    icomp = {pair for pair in pairs if pair[0][1] == pair[1][1]}
    return pairs, {
        "GAP": gap,
        "DEN": den,
        "CSUM": den,
        "CORD": defeat(pairs, lambda l, r: dominance(l, r, strict_and)),
        "NORD": defeat(pairs, lambda l, r: natural(l[0], r[0], abstain_ties)),
        "IDEN": defeat(pairs, lambda l, r: natural(r[1], l[1], abstain_ties)),
        "ICOMP": icomp,
    }


def set_row(name: str, values, narrow: set, broad: set, display) -> dict[str, object]:
    narrow_only = narrow - broad
    broad_only = broad - narrow
    return {
        "name": name,
        "narrow": len(narrow), "broad": len(broad),
        "narrow_minus_broad": len(narrow_only), "broad_minus_narrow": len(broad_only),
        "narrow_witnesses": "; ".join(display(value) for value in sorted(narrow_only, key=display)[:2]) or "none",
        "broad_witnesses": "; ".join(display(value) for value in sorted(broad_only, key=display)[:2]) or "none",
    }


def decimal_numerals(whole_limit: int, *, include_zero_fraction: bool = False) -> list[DecimalNumeral]:
    digits = [f"{number:0{places}d}" for places in range(1, 4)
              for number in range(1, 10 ** places) if number % 10]
    if include_zero_fraction:
        digits = ["0", "00", "000"] + digits
    return [DecimalNumeral(whole, suffix) for whole in range(whole_limit + 1) for suffix in digits]


def decimal_exact_order(left: DecimalNumeral, right: DecimalNumeral) -> int:
    left_scale, right_scale = 10 ** len(left.digits), 10 ** len(right.digits)
    left_written = left.whole * left_scale + int(left.digits)
    right_written = right.whole * right_scale + int(right.digits)
    return sign(left_written * right_scale - right_written * left_scale)


def old_divisor_rows() -> list[dict[str, object]]:
    divisors, classes = division_classes()
    display_divisor = lambda value: str(value.numerator) if value.denominator == 1 else f"{value.numerator}/{value.denominator}"
    old = [
        set_row("the_divisor_is_not_a_whole_number subset the_divisor_is_not_one", divisors, classes["the_divisor_is_not_a_whole_number"], classes["the_divisor_is_not_one"], display_divisor),
        set_row("the_divisor_lies_between_zero_and_one subset the_divisor_is_not_one", divisors, classes["the_divisor_lies_between_zero_and_one"], classes["the_divisor_is_not_one"], display_divisor),
        set_row("the_divisor_is_a_power_of_five subset the_divisor_is_not_ten", divisors, classes["the_divisor_is_a_power_of_five"], classes["the_divisor_is_not_ten"], display_divisor),
        set_row("the_divisor_is_a_power_of_five subset the_divisor_is_not_one", divisors, classes["the_divisor_is_a_power_of_five"], classes["the_divisor_is_not_one"], display_divisor),
        set_row("CONTROL the_divisor_is_not_a_whole_number subset the_divisor_is_not_ten", divisors, classes["the_divisor_is_not_a_whole_number"], classes["the_divisor_is_not_ten"], display_divisor),
    ]
    return old


def division_classes() -> tuple[list[Fraction], dict[str, set[Fraction]]]:
    divisors = [Fraction(value) for value in (-5, -1, 1, 2, 3, 5, 10, 25)] + [
        Fraction(1, 4), Fraction(1, 3), Fraction(1, 2), Fraction(3, 4),
        Fraction(125), Fraction(625), Fraction(3125), Fraction(15625),
    ]
    powers = {Fraction(5 ** exponent) for exponent in range(1, 7)}
    return divisors, {
        "the_divisor_is_not_a_whole_number": {value for value in divisors if value.denominator != 1},
        "the_divisor_lies_between_zero_and_one": {value for value in divisors if 0 < value < 1},
        "the_divisor_is_not_one": {value for value in divisors if value != 0 and value != 1},
        "the_divisor_is_a_power_of_five": {value for value in divisors if value in powers},
        "the_divisor_is_not_ten": {value for value in divisors if value.denominator == 1 and value != 0 and value != 10},
    }


def decimal_context_rows() -> tuple[
    list[dict[str, object]],
    list[dict[str, object]],
    Counter[int],
]:
    """Measure B-1998 and B-2004 together, without a second pair sweep."""
    decimals = decimal_numerals(1, include_zero_fraction=True)
    names = [
        "fraction_part_numeral_order_diverges_within_equal_integer_parts subset fraction_part_numeral_order_diverges_from_value_order",
        "numeral_length_order_inverts_decimal_value_order subset the_numerals_carry_different_place_counts",
        "written_numeral_order_diverges_from_decimal_value_order subset the_numerals_carry_different_place_counts",
        "CONTROL numeral_length_order_inverts_decimal_value_order subset numeral_length_order_tracks_decimal_value_order",
        "W3-1 fraction_part_numeral_order_diverges_within_equal_integer_parts subset the_numerals_carry_different_place_counts",
        "W3-2 fraction_part_numeral_order_diverges_within_equal_integer_parts subset written_numeral_order_diverges_from_decimal_value_order",
        "W3-3 fraction_part_numeral_order_diverges_within_equal_integer_parts subset numeral_length_order_inverts_decimal_value_order",
        "W3-4 numeral_length_order_tracks_decimal_value_order subset the_numerals_carry_different_place_counts",
        "CONTROL written_numeral_order_diverges_from_decimal_value_order subset numeral_length_order_inverts_decimal_value_order",
        "CONTROL fraction_part_numeral_order_diverges_from_value_order subset the_numerals_carry_different_place_counts",
        "CONTROL fraction_part_numeral_order_diverges_within_equal_integer_parts subset numeral_length_order_tracks_decimal_value_order",
    ]
    base_counts = [[0, 0, 0, 0] for _ in names]
    base_narrow_witnesses = [[] for _ in names]
    base_broad_witnesses = [[] for _ in names]
    extended_counts = [[0, 0, 0, 0] for _ in names]
    extended_narrow_witnesses = [[] for _ in names]
    extended_broad_witnesses = [[] for _ in names]
    frontier_masks: Counter[int] = Counter()
    for left in decimals:
        for right in decimals:
            if left == right:
                continue
            exact_order = decimal_exact_order(left, right)
            raw_disagrees = sign(int(left.digits) - int(right.digits)) != exact_order
            different_places = len(left.digits) != len(right.digits)
            length_order = sign(len(left.digits) - len(right.digits))
            length_inverts = different_places and length_order == -exact_order
            written_diverges = sign(int(f"{left.whole}{left.digits}") - int(f"{right.whole}{right.digits}")) != exact_order
            length_tracks = different_places and length_order == exact_order
            fpe = left.whole == right.whole and raw_disagrees
            smaller_fraction_part_tracks = (
                sign(int(left.digits) - int(right.digits)) != 0
                and sign(int(left.digits) - int(right.digits)) == exact_order
            )
            frontier_features = DecimalContextFeatures(
                raw_disagrees=raw_disagrees,
                equal_integer_part_diverges=fpe,
                length_inverts=length_inverts,
                length_tracks=length_tracks,
                different_places=different_places,
                written_diverges=written_diverges,
                smaller_fraction_part_tracks=smaller_fraction_part_tracks,
            )
            frontier_mask = sum(
                1 << index
                for index, (_name, predicate)
                in enumerate(DECIMAL_CONTEXT_SPECS)
                if predicate(frontier_features)
            )
            frontier_masks[frontier_mask] += 1
            cases = ((fpe, raw_disagrees),
                     (length_inverts, different_places),
                     (written_diverges, different_places),
                     (length_inverts, length_tracks),
                     (fpe, different_places),
                     (fpe, written_diverges),
                     (fpe, length_inverts),
                     (length_tracks, different_places),
                     (written_diverges, length_inverts),
                     (raw_disagrees, different_places),
                     (fpe, length_tracks))
            label = f"{left.display()} vs {right.display()}"
            is_base_pair = left.digits not in {"0", "00", "000"} and right.digits not in {"0", "00", "000"}
            for index, (in_narrow, in_broad) in enumerate(cases):
                extended_counts[index][0] += in_narrow
                extended_counts[index][1] += in_broad
                if in_narrow and not in_broad:
                    extended_counts[index][2] += 1
                    if len(extended_narrow_witnesses[index]) < 2:
                        extended_narrow_witnesses[index].append(label)
                if in_broad and not in_narrow:
                    extended_counts[index][3] += 1
                    if len(extended_broad_witnesses[index]) < 2:
                        extended_broad_witnesses[index].append(label)
                if is_base_pair:
                    base_counts[index][0] += in_narrow
                    base_counts[index][1] += in_broad
                    if in_narrow and not in_broad:
                        base_counts[index][2] += 1
                        if len(base_narrow_witnesses[index]) < 2:
                            base_narrow_witnesses[index].append(label)
                    if in_broad and not in_narrow:
                        base_counts[index][3] += 1
                        if len(base_broad_witnesses[index]) < 2:
                            base_broad_witnesses[index].append(label)

    def rows_for(counts, narrow_witnesses, broad_witnesses):
        return [
            {"name": name, "narrow": count[0], "broad": count[1],
             "narrow_minus_broad": count[2], "broad_minus_narrow": count[3],
             "narrow_witnesses": "; ".join(narrow_witnesses[index]) or "none",
             "broad_witnesses": "; ".join(broad_witnesses[index]) or "none"}
            for index, (name, count) in enumerate(zip(names, counts))
        ]

    return (
        rows_for(base_counts, base_narrow_witnesses, base_broad_witnesses),
        rows_for(extended_counts, extended_narrow_witnesses, extended_broad_witnesses),
        frontier_masks,
    )


def multiplication_row() -> dict[str, object]:
    pairs, classes = multiplication_classes()
    display = lambda p: f"{float(p[0]):.1f} x {float(p[1]):.1f}"
    return set_row(
        "a_factor_lies_between_zero_and_one subset a_factor_is_a_non_integer_decimal",
        pairs,
        classes["a_factor_lies_between_zero_and_one"],
        classes["a_factor_is_a_non_integer_decimal"],
        display,
    )


def multiplication_classes() -> tuple[
    list[tuple[Fraction, Fraction]],
    dict[str, set[tuple[Fraction, Fraction]]],
]:
    values = [Fraction(number, 10) for number in range(31)]
    pairs = [(left, right) for left in values for right in values]
    return pairs, {
        "a_factor_lies_between_zero_and_one": {
            pair for pair in pairs if any(0 < factor < 1 for factor in pair)
        },
        "a_factor_is_a_non_integer_decimal": {
            pair for pair in pairs
            if any(factor.denominator != 1 for factor in pair)
        },
    }


def scale_loss_condition(numerator_one: int, scale_one: int,
                         numerator_two: int, scale_two: int) -> str:
    produced = sign(numerator_one - numerator_two)
    expected = sign(numerator_one * scale_two - numerator_two * scale_one)
    return (
        "written_numeral_order_diverges_from_decimal_value_order"
        if produced != expected
        else "written_numeral_order_coincides_with_decimal_value_order"
    )


def automaton_probes(pairs, gap: set) -> tuple[int, str, int, tuple[str, str], int]:
    """Check GAP and scale-loss probes in one SWI-Prolog invocation."""
    query = " ".join([
        "use_module(math(smr_frac_benchmark_compare)),",
        "use_module(math(smr_decimal_fraction_compare)),",
        "forall((between(2,12,D1), U1 is D1-1, between(1,U1,N1),",
        "between(2,12,D2), U2 is D2-1, between(1,U2,N2),",
        "\\+ (N1 =:= N2, D1 =:= D2)),",
        "(run_gap_thinking_compare(N1,D1,N2,D2,_,V,_), arg(2,V,condition(C)),",
        "format('gap\\t~d\\t~d\\t~d\\t~d\\t~w~n',[N1,D1,N2,D2,C]))),",
        "forall((member(S1,[10,100,1000]), between(1,29,N1),",
        "member(S2,[10,100,1000]), between(1,29,N2), N1*S2 =\\= N2*S1),",
        "(run_decimal_scale_loss_compare(N1,S1,N2,S2,_,V,_), arg(2,V,condition(C)),",
        "format('scale\\t~d\\t~d\\t~d\\t~d\\t~w~n',[N1,S1,N2,S2,C]))),",
        "forall((between(0,1,W), member(S1,[10,100]), U1 is S1-1, between(1,U1,D1), D1 mod 10 =\\= 0,",
        "member(S2,[10,100]), U2 is S2-1, between(1,U2,D2), D2 mod 10 =\\= 0,",
        "N1 is W*S1+D1, N2 is W*S2+D2, \\+ (N1 =:= N2, S1 =:= S2),",
        "R is sign(D1-D2), E is sign(N1*S2-N2*S1), R =\\= E),",
        "(run_decimal_scale_loss_compare(N1,S1,N2,S2,_,V,_), arg(2,V,condition(C)),",
        "format('fpe\\t~d\\t~d\\t~d\\t~d\\t~w~n',[N1,S1,N2,S2,C]))),",
        "forall(member(probe(N1,S1,N2,S2),[probe(105,100,15,10),probe(11,100,11,10)]),",
        "(run_decimal_scale_loss_compare(N1,S1,N2,S2,_,V,_), arg(2,V,condition(C)),",
        "format('spot\\t~d\\t~d\\t~d\\t~d\\t~w~n',[N1,S1,N2,S2,C]))),",
        "run_decimal_scale_loss_compare(10,10,100,100,_,EqualV,_), arg(2,EqualV,condition(EqualC)),",
        "format('equal\\t10\\t10\\t100\\t100\\t~w~n',[EqualC]), halt",
    ])
    completed = subprocess.run(["swipl", "-q", "-l", str(ROOT / "paths.pl"), "-g", query], cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    if completed.returncode or completed.stderr.strip():
        raise RuntimeError(completed.stderr.strip() or "gap automaton probe failed")
    gap_conditions = {}
    scale_conditions = {}
    fpe_conditions = {}
    spot_conditions = {}
    equal_condition = None
    for row in completed.stdout.splitlines():
        probe, n1, d1, n2, d2, condition = row.split("\t")
        key = (int(n1), int(d1), int(n2), int(d2))
        if probe == "gap":
            gap_conditions[((key[0], key[1]), (key[2], key[3]))] = condition
        elif probe == "scale":
            scale_conditions[key] = condition
        elif probe == "fpe":
            fpe_conditions[key] = condition
        elif probe == "spot":
            spot_conditions[key] = condition
        elif probe == "equal":
            equal_condition = condition
        else:
            raise RuntimeError(f"unknown automaton probe prefix: {probe!r}")
    if len(gap_conditions) != len(pairs):
        raise RuntimeError(f"gap automaton double-count or omission: expected {len(pairs)}, found {len(gap_conditions)}")
    divergence = "gap_order_diverges_from_fraction_order"
    if sum(c == divergence for c in gap_conditions.values()) != 974:
        raise RuntimeError("gap automaton condition class is not the reviewed 974-member probe class")
    if any(gap_conditions[pair] != divergence for pair in gap):
        raise RuntimeError("a reviewed equal-gap member lacks the one-sided automaton condition")
    separating = gap_conditions[((1, 2), (2, 4))]
    if separating != divergence:
        raise RuntimeError("gap separating witness no longer demonstrates automaton over-coverage")
    if len(scale_conditions) != 7474:
        raise RuntimeError(f"expected 7474 unequal-value scale-loss cases, found {len(scale_conditions)}")
    for (n1, s1, n2, s2), condition in scale_conditions.items():
        if condition != scale_loss_condition(n1, s1, n2, s2):
            raise RuntimeError(f"scale-loss reimplementation disagrees with automaton: {(n1, s1, n2, s2, condition)!r}")
    scale_samples = (scale_conditions[(1, 10, 2, 10)], scale_conditions[(8, 10, 14, 100)])
    if scale_samples != (
        "written_numeral_order_coincides_with_decimal_value_order",
        "written_numeral_order_diverges_from_decimal_value_order",
    ):
        raise RuntimeError(f"unexpected scale-loss sample conditions: {scale_samples!r}")
    small_decimals = [value for value in decimal_numerals(1) if len(value.digits) <= 2]
    expected_fpe = sum(
        left.whole == right.whole
        and sign(int(left.digits) - int(right.digits)) != decimal_exact_order(left, right)
        for left in small_decimals for right in small_decimals if left != right
    )
    divergence = "written_numeral_order_diverges_from_decimal_value_order"
    if len(fpe_conditions) != expected_fpe or any(condition != divergence for condition in fpe_conditions.values()):
        raise RuntimeError("a W3-2 broad-endpoint probe missed an FPE member or lost its divergence condition")
    if set(spot_conditions) != {(105, 100, 15, 10), (11, 100, 11, 10)} or any(condition != divergence for condition in spot_conditions.values()):
        raise RuntimeError("W3-2 three-place spot probes no longer return the scale-loss divergence condition")
    if equal_condition != divergence:
        raise RuntimeError("WND subset LIV control lost the equal-value scale-loss divergence condition")
    return 974, separating, len(scale_conditions), scale_samples, len(fpe_conditions)


def validate_source() -> dict[str, object]:
    source = json.loads(INPUT_CLASSES.read_text(encoding="utf-8"))
    if source.get("schema_version") != 1 or not isinstance(source.get("contexts"), dict):
        raise RuntimeError("unsupported context-input-class source")
    required = {"input_type", "feature", "predicate", "prose"}
    task_163_needed = {
        "the_divisor_is_not_a_whole_number", "the_divisor_lies_between_zero_and_one", "the_divisor_is_not_one", "the_divisor_is_a_power_of_five", "the_divisor_is_not_ten",
        "fraction_part_numeral_order_diverges_from_value_order", "fraction_part_numeral_order_diverges_within_equal_integer_parts",
        "numeral_length_order_inverts_decimal_value_order", "numeral_length_order_tracks_decimal_value_order", "the_numerals_carry_different_place_counts", "written_numeral_order_diverges_from_decimal_value_order",
        "a_factor_lies_between_zero_and_one", "a_factor_is_a_non_integer_decimal",
    }
    task_171_needed = {
        "gap_order_diverges_from_fraction_order", "denominator_order_inverts_for_equal_numerators", "component_sum_inverts_for_equal_numerators", "component_order_inverts_for_equal_numerators", "inverse_component_order_diverges_for_equal_denominators", "numerator_order_diverges_for_unequal_denominators", "inverse_denominator_order_diverges_for_unequal_numerators", "the_tenths_digit_is_nine", "the_numeral_carries_a_nonzero_fraction_part", "numerator_sum_diverges_for_unequal_denominators", "the_multiplier_is_not_a_whole_number", "the_factors_include_a_decimal_fraction", "smaller_fraction_part_numeral_names_the_smaller_decimal", "the_subtrahend_carries_a_nonzero_fraction_part",
    }
    needed = task_163_needed | task_171_needed
    if not needed <= source["contexts"].keys():
        raise RuntimeError("context-input-class source omits a Task 163 or Task 171 endpoint or refusal")
    for name, row in source["contexts"].items():
        expected = required | ({"refused"} if name == "numerator_sum_diverges_for_unequal_denominators" and row.get("refused") is True else set()) if isinstance(row, dict) else set()
        if (not isinstance(row, dict) or set(row) != expected
                or not all(isinstance(row[field], str) and row[field] for field in required)):
            raise RuntimeError(f"invalid typed input class: {name}")
    if source["contexts"]["numerator_sum_diverges_for_unequal_denominators"].get("refused") is not True:
        raise RuntimeError("NSUM must remain explicitly refused-unspecifiable")
    return source


def declared_nesting_pairs() -> set[tuple[str, str]]:
    source = json.loads(NESTINGS.read_text(encoding="utf-8"))
    if source.get("schema_version") != 1 or not isinstance(source.get("nestings"), list):
        raise RuntimeError("unsupported a-fortiori context-nesting source")
    pairs: set[tuple[str, str]] = set()
    for row in source["nestings"]:
        if not isinstance(row, dict):
            raise RuntimeError("invalid a-fortiori context nesting row")
        narrow = row.get("narrow")
        broad = row.get("broad")
        if not isinstance(narrow, str) or not isinstance(broad, str):
            raise RuntimeError("a-fortiori context nesting lacks named endpoints")
        pair = (narrow, broad)
        if pair in pairs:
            raise RuntimeError(f"duplicate a-fortiori context nesting: {narrow} < {broad}")
        pairs.add(pair)
    return pairs


def set_frontier_rows(
    battery: str,
    classes: dict[str, set],
) -> list[dict[str, object]]:
    rows = []
    for narrow, broad in permutations(sorted(classes), 2):
        narrow_set = classes[narrow]
        broad_set = classes[broad]
        rows.append({
            "battery": battery,
            "narrow_name": narrow,
            "broad_name": broad,
            "narrow": len(narrow_set),
            "broad": len(broad_set),
            "narrow_minus_broad": len(narrow_set - broad_set),
            "broad_minus_narrow": len(broad_set - narrow_set),
        })
    return rows


def mask_frontier_rows(
    battery: str,
    names: tuple[str, ...],
    mask_counts: Counter[int],
) -> list[dict[str, object]]:
    rows = []
    for narrow_index, broad_index in permutations(range(len(names)), 2):
        narrow_bit = 1 << narrow_index
        broad_bit = 1 << broad_index
        narrow_count = sum(count for mask, count in mask_counts.items() if mask & narrow_bit)
        broad_count = sum(count for mask, count in mask_counts.items() if mask & broad_bit)
        narrow_only = sum(
            count
            for mask, count in mask_counts.items()
            if mask & narrow_bit and not mask & broad_bit
        )
        broad_only = sum(
            count
            for mask, count in mask_counts.items()
            if mask & broad_bit and not mask & narrow_bit
        )
        rows.append({
            "battery": battery,
            "narrow_name": names[narrow_index],
            "broad_name": names[broad_index],
            "narrow": narrow_count,
            "broad": broad_count,
            "narrow_minus_broad": narrow_only,
            "broad_minus_narrow": broad_only,
        })
    return rows


def assert_declared_strict_frontier(
    rows: list[dict[str, object]],
    declared_pairs: set[tuple[str, str]],
) -> list[dict[str, object]]:
    undeclared = [
        row for row in rows
        if verdict(row) == "contained_strict"
        and (row["narrow_name"], row["broad_name"]) not in declared_pairs
    ]
    if undeclared:
        found = "; ".join(
            f"{row['narrow_name']} < {row['broad_name']} [{row['battery']}]"
            for row in undeclared
        )
        raise RuntimeError(
            "undeclared strict same-type context nesting(s): " + found
        )
    return undeclared


def assert_exhaustive_same_type_frontier(
    source: dict[str, object],
    fraction_classes_small: dict[str, set],
    fraction_classes_large: dict[str, set],
    decimal_masks: Counter[int],
) -> dict[str, int]:
    declared_pairs = declared_nesting_pairs()
    _, division = division_classes()
    _, numeral = numeral_classes()
    _, multiplication = multiplication_classes()
    fraction_small = {
        FRACTION_CONTEXT_NAMES[name]: values
        for name, values in fraction_classes_small.items()
    }
    fraction_large = {
        FRACTION_CONTEXT_NAMES[name]: values
        for name, values in fraction_classes_large.items()
    }
    primary_classes = {
        "frac_pair": set(fraction_small),
        "dec_pair": set(DECIMAL_CONTEXT_NAMES),
        "division": set(division),
        "numeral": set(numeral),
        "multiplication": set(multiplication),
    }

    contexts = source["contexts"]
    grouped: dict[str, set[str]] = {}
    for name, row in contexts.items():
        grouped.setdefault(row["input_type"], set()).add(name)
    multi_context_groups = {
        input_type: names
        for input_type, names in grouped.items()
        if len(names) > 1
    }
    if primary_classes != multi_context_groups:
        missing = {
            input_type: sorted(names - primary_classes.get(input_type, set()))
            for input_type, names in multi_context_groups.items()
            if names - primary_classes.get(input_type, set())
        }
        extra = {
            input_type: sorted(names - multi_context_groups.get(input_type, set()))
            for input_type, names in primary_classes.items()
            if names - multi_context_groups.get(input_type, set())
        }
        raise RuntimeError(
            f"same-type frontier builder coverage drift: missing={missing}; extra={extra}"
        )

    primary_rows = [
        *set_frontier_rows("frac_pair D<=12", fraction_small),
        *mask_frontier_rows("dec_pair", DECIMAL_CONTEXT_NAMES, decimal_masks),
        *set_frontier_rows("division", division),
        *set_frontier_rows("numeral", numeral),
        *set_frontier_rows("multiplication", multiplication),
    ]
    robustness_rows = set_frontier_rows("frac_pair D<=20", fraction_large)
    undeclared = assert_declared_strict_frontier(
        primary_rows + robustness_rows,
        declared_pairs,
    )
    strict_pairs = {
        (row["narrow_name"], row["broad_name"])
        for row in primary_rows
        if verdict(row) == "contained_strict"
    }
    return {
        "typed_contexts": len(contexts),
        "ordered_pairs": len(primary_rows),
        "strict": len(strict_pairs),
        "undeclared_strict": len(undeclared),
    }


def render_row(row: dict[str, object], extra: str = "") -> str:
    return f"| `{row['name']}` | {row['narrow']} | {row['broad']} | {row['narrow_minus_broad']} | {row['broad_minus_narrow']} | {verdict(row)} | narrow-not-broad: {row['narrow_witnesses']}; broad-not-narrow: {row['broad_witnesses']}{extra} |"


def required_fraction_rows(classes: dict[str, set], pairs) -> tuple[list[dict[str, object]], list[dict[str, object]]]:
    shipped = [
        ("S1 GAP subset IDEN", "GAP", "IDEN", "R1 intersection; one-sided gap automaton probe", "none; survives R2 abstain"),
        ("S2 DEN subset CORD", "DEN", "CORD", "R3 >= with one strict", "strict-AND -> refused_disjoint"),
        ("S3 CSUM subset CORD", "CSUM", "CORD", "R3 >= with one strict", "strict-AND -> refused_disjoint"),
        ("S4 DEN subset NORD", "DEN", "NORD", "R2 total ties equal", "abstain ties -> refused_disjoint"),
        ("S5 CSUM subset NORD", "CSUM", "NORD", "R2 total ties equal", "abstain ties -> refused_disjoint"),
        ("S6 ICOMP subset IDEN", "ICOMP", "IDEN", "R2 total ties equal", "abstain ties -> refused_disjoint"),
    ]
    rows = []
    for name, narrow, broad, procedure, dissent in shipped:
        row = set_row(name, pairs, classes[narrow], classes[broad], fraction_display)
        row["procedure"], row["dissent"] = procedure, dissent
        if verdict(row) != "contained_strict":
            raise RuntimeError(f"{name} disagrees with its predicted contained_strict verdict")
        rows.append(row)
    controls = [
        set_row("CONTROL DEN subset IDEN", pairs, classes["DEN"], classes["IDEN"], fraction_display),
        set_row("CONTROL GAP subset CORD", pairs, classes["GAP"], classes["CORD"], fraction_display),
    ]
    if any(verdict(row) != "refused_disjoint" for row in controls):
        raise RuntimeError("a mandated fraction control stopped refusing")
    return rows, controls


def numeral_classes() -> tuple[
    list[DecimalNumeral],
    dict[str, set[DecimalNumeral]],
]:
    values = decimal_numerals(3, include_zero_fraction=True)
    return values, {
        "the_tenths_digit_is_nine": {
            value for value in values
            if len(value.digits) == 1 and value.digits == "9"
        },
        "the_numeral_carries_a_nonzero_fraction_part": {
            value for value in values if int(value.digits) != 0
        },
    }


def numeral_row() -> dict[str, object]:
    values, classes = numeral_classes()
    row = set_row(
        "S7 T9 subset NNF",
        values,
        classes["the_tenths_digit_is_nine"],
        classes["the_numeral_carries_a_nonzero_fraction_part"],
        lambda value: value.display(),
    )
    row["procedure"] = "4,008-numeral one-to-three-place battery, including 0/00/000 fraction parts; numeral retype"
    row["dissent"] = "subtraction-operand reading -> refused_type_mismatch"
    if verdict(row) != "contained_strict":
        raise RuntimeError("S7 disagrees with its predicted contained_strict verdict")
    return row


def receipt() -> tuple[str, dict[str, int]]:
    source = validate_source()
    pairs, classes = fraction_classes(12)
    large_pairs, large_classes = fraction_classes(20)
    if len(pairs) != 4290 or len(large_pairs) != 35910:
        raise RuntimeError("fraction-grid cardinality drift")
    fraction_rows, fraction_controls = required_fraction_rows(classes, pairs)
    # The larger grid guards against an accidental finite-grid containment.
    large_rows, _ = required_fraction_rows(large_classes, large_pairs)
    if [(r["narrow_minus_broad"], r["broad_minus_narrow"]) for r in large_rows] != [(0, 16960), (0, 4990), (0, 4990), (0, 4990), (0, 4990), (0, 16960)]:
        raise RuntimeError("D <= 20 robustness sweep differs from the predicted algebraic pattern")
    condition_count, separating, scale_case_count, scale_samples, fpe_probe_count = automaton_probes(pairs, classes["GAP"])
    numeral = numeral_row()
    old_divisors = old_divisor_rows()
    decimals, decimal_robustness, decimal_masks = decimal_context_rows()
    frontier = assert_exhaustive_same_type_frontier(
        source,
        classes,
        large_classes,
        decimal_masks,
    )
    expected_wave3 = [
        (163512, 719280, 0, 555768),
        (163512, 326808, 0, 163296),
        (163512, 359640, 0, 196128),
        (359640, 719280, 0, 359640),
    ]
    expected_wave3_robustness = [
        (163512, 735288, 0, 571776),
        (163512, 330594, 0, 167082),
        (163512, 364074, 0, 200562),
        (371202, 735288, 0, 364086),
    ]
    measure = lambda rows: [(row["narrow"], row["broad"], row["narrow_minus_broad"], row["broad_minus_narrow"]) for row in rows]
    if measure(decimals[4:8]) != expected_wave3 or measure(decimal_robustness[4:8]) != expected_wave3_robustness:
        raise RuntimeError("Wave 3 decimal containment counts differ from the reviewed batteries")
    if (verdict(decimal_robustness[8]) != "refused_counterexample"
            or decimal_robustness[8]["narrow_minus_broad"] != 6
            or "1.0 vs 1.00" not in decimal_robustness[8]["narrow_witnesses"]):
        raise RuntimeError("WND subset LIV control stopped biting on equal-value written numerals")
    if verdict(decimals[9]) != "refused_counterexample" or verdict(decimals[10]) != "refused_disjoint":
        raise RuntimeError("a mandated Wave 3 decimal refusal control stopped refusing")
    existing_controls = [old_divisors[-1], decimals[3]]
    retained_rows = old_divisors[:4] + decimals[:3] + [multiplication_row()]
    for row in retained_rows:
        if verdict(row) != "contained_strict":
            raise RuntimeError(f"existing settled row drifted: {row['name']}")
    if any(verdict(row) != "refused_disjoint" for row in existing_controls):
        raise RuntimeError("an existing refusal control stopped refusing")

    all_controls = existing_controls + fraction_controls + [decimal_robustness[8], decimals[9], decimals[10]]
    identities = [
        set_row("DEN subset CSUM", pairs, classes["DEN"], classes["CSUM"], fraction_display),
        set_row("CSUM subset DEN", pairs, classes["CSUM"], classes["DEN"], fraction_display),
        set_row("CORD subset NORD", pairs, classes["CORD"], classes["NORD"], fraction_display),
        set_row("NORD subset CORD", pairs, classes["NORD"], classes["CORD"], fraction_display),
    ]
    if any(verdict(row) != "contained_equal" for row in identities):
        raise RuntimeError("a declared true class identity drifted")

    # All other typed fraction pairings are retained as refusals, not silently discarded.
    declared = {("GAP", "IDEN"), ("DEN", "CORD"), ("CSUM", "CORD"), ("DEN", "NORD"), ("CSUM", "NORD"), ("ICOMP", "IDEN")}
    abbreviations = ["GAP", "DEN", "CSUM", "CORD", "ICOMP", "NORD", "IDEN"]
    refused_fraction = []
    for narrow in abbreviations:
        for broad in abbreviations:
            if narrow == broad or (narrow, broad) in declared or (narrow, broad) in {("DEN", "CSUM"), ("CSUM", "DEN"), ("CORD", "NORD"), ("NORD", "CORD")}:
                continue
            row = set_row(f"{narrow} subset {broad}", pairs, classes[narrow], classes[broad], fraction_display)
            refused_fraction.append(row)
    if len(refused_fraction) != 32 or any(verdict(row) not in {"refused_disjoint", "refused_counterexample"} for row in refused_fraction):
        raise RuntimeError("fraction refusal matrix is incomplete")

    lines = [
        "# A-fortiori context nesting: input settlement receipt", "",
        "Generated by `python3 scripts/checks/a_fortiori_context_nesting_sweep.py`. The JSON predicate column is the reviewed typed specification; this battery is its executable restatement. No containment is inferred from atom names.", "",
        "## Exhaustive same-type frontier invariant", "",
        f"`typed_contexts={frontier['typed_contexts']}; ordered_pairs={frontier['ordered_pairs']}; strict={frontier['strict']}; undeclared_strict={frontier['undeclared_strict']}`", "",
        "These byte-compared fields cover every typed context and every ordered same-input-type pair. A changed strict count or a newly undeclared strict pair makes `--check` report receipt drift. The `undeclared_strict=0` field is emitted only after the undeclared-pair assertion has passed; it records that gate outcome rather than an independent measurement.", "",
        "## Decided readings and procedures", "",
        "- R1: multi-rule atoms use the intersection of every native rule's defeat set. It fixes GAP at equal gaps (440), not the gap automaton's 974-member condition class; coding 46920 states the equal-gap class.",
        "- R2: whole-number comparison heuristics are total and a tie yields equal. The loaded gap automaton attests this behavior; abstain-on-ties branches are retained below.",
        "- R3: component dominance uses >= with one strict. Rows 44707, 45650, and 47009 require it; strict-AND branches are retained below.", "",
        "The fraction battery contains ordered written-distinct proper fractions with 1 <= N < D <= 12: 66 fractions and 4,290 pairs. The independent D <= 20 rerun has 35,910 pairs. The numeral battery contains 4,008 canonical one-to-three-place decimals with whole parts 0..3, including 0/00/000 fraction parts.", "",
        "B-2004 comprises 1,998 canonical one-to-three-place numerals with whole parts 0..1 and no trailing zeros, extended to 2,004 by the six zero-fraction forms; W3-3 therefore applies only to canonical numerals, while W3-2 held with no canonical-numeral restriction across the mandated batteries.", "",
        "## Settled Task 171 rows", "",
        "| row | narrow count | broad count | narrow-minus-broad count | broad-minus-narrow count | verdict | procedure and dissent |",
        "| --- | ---: | ---: | ---: | ---: | --- | --- |",
    ]
    for row in fraction_rows + [numeral]:
        lines.append(f"| `{row['name']}` | {row['narrow']} | {row['broad']} | {row['narrow_minus_broad']} | {row['broad_minus_narrow']} | {verdict(row)} | {row['procedure']}; dissent: {row['dissent']}; broad-only: {row['broad_witnesses']} |")
    lines.extend([
        "",
        "## Retained Task 163 settled rows", "",
        "| narrow subset broad | narrow count | broad count | narrow-minus-broad count | broad-minus-narrow count | verdict | boundary witnesses |",
        "| --- | ---: | ---: | ---: | ---: | --- | --- |",
        *(render_row(row) for row in retained_rows),
        "",
        "## Wave 3 leaked decimal rows",
        "",
        "| narrow subset broad | narrow count | broad count | narrow-minus-broad count | broad-minus-narrow count | verdict | boundary witnesses |",
        "| --- | ---: | ---: | ---: | ---: | --- | --- |",
        *(render_row(row, f"; B-2004: {decimal_robustness[index + 4]['narrow']} / {decimal_robustness[index + 4]['broad']} / {decimal_robustness[index + 4]['narrow_minus_broad']} / {decimal_robustness[index + 4]['broad_minus_narrow']}") for index, row in enumerate(decimals[4:8])),
        "",
        f"The D <= 20 robustness rerun keeps all six fraction rows strict: each has narrow-minus-broad 0. Its broad-only counts are {', '.join(str(row['broad_minus_narrow']) for row in large_rows)} in S1..S6 order.",
        f"Gap automaton probe: all 440 GAP members carry `gap_order_diverges_from_fraction_order`; the automaton condition class has {condition_count} of 4,290 members. `1/2 vs 2/4` returns `{separating}`, so the probe is `probed_narrow_endpoint_only`, not a decider for R1's 440 boundary.",
        f"Scale-loss reimplementation probe: `smr_decimal_fraction_compare:run_decimal_scale_loss_compare/7` agrees with the Python predicate on all {scale_case_count} ordered unequal-value inputs at scales 10, 100, and 1000. `1/10` vs `2/10` returns `{scale_samples[0]}`; `8/10` vs `14/100` returns `{scale_samples[1]}`. The W3-2 broad-endpoint probe ran every one of the {fpe_probe_count} FPE members on the canonical one-to-two-place sub-battery plus `1.05` vs `1.5` and `0.11` vs `1.1`; every probe returned the divergence condition. This attests broad membership, not the boundary.",
        "",
        "## Refusal controls", "",
        "| proposed narrow subset broad | narrow count | broad count | narrow-minus-broad count | broad-minus-narrow count | verdict | boundary witnesses |",
        "| --- | ---: | ---: | ---: | ---: | --- | --- |",
        *(render_row(row) for row in all_controls), "",
        "The first two controls preserve the Task 163 whole-divisor and decimal complement refusals. DEN is IDEN's coder-recorded valid equal-numerator domain, and GAP is CORD's coder-recorded equal-gap success domain (46964); both proposed Task 171 containments must therefore refuse. WND subset LIV is measured on B-2004 so equal-value dual written numerals remain in scope: `1.0` vs `1.00` and `1.0` vs `1.000` are narrow-only counterexamples, and the loaded scale-loss automaton emits its divergence condition on 1.0 versus 1.00.", "",
        "## Refusal scope", "",
        "### Fraction matrix", "",
        "The 56 ordered fraction pairs resolve to six declared strict rows, four true identities the directed cycle guard refuses, fourteen NSUM refusals, and 32 disjoint/counterexample refusals. This is the complete same-type matrix, not an atom-name shortlist.", "",
        "| identity direction | narrow count | broad count | narrow-minus-broad count | broad-minus-narrow count | verdict | reason |",
        "| --- | ---: | ---: | ---: | ---: | --- | --- |",
        *(f"| `{row['name']}` | {row['narrow']} | {row['broad']} | {row['narrow_minus_broad']} | {row['broad_minus_narrow']} | {verdict(row)} | true typed identity; mutual rows would form a cycle |" for row in identities), "",
        "| refused typed fraction pair | verdict | witnesses or ground |",
        "| --- | --- | --- |",
        *(f"| `{row['name']}` | {verdict(row)} | narrow-not-broad: {row['narrow_witnesses']}; broad-not-narrow: {row['broad_witnesses']} |" for row in refused_fraction),
        "| `NSUM` with each of GAP, DEN, CSUM, CORD, ICOMP, NORD, IDEN in both directions (14 ordered pairs) | refused_unspecifiable | coding 45599: Compare the magnitude of fraction-based quantities by summing the numerators and ignoring the denominators. It does not fix the compared collection's shape. |", "",
        "### Multiplication, decimal, and numeral refusals", "",
        "| pair | verdict | typed ground |",
        "| --- | --- | --- |",
        "| `B01 subset MNW` | refused_type_mismatch | B01 is a role-free multiplication pair; MNW is a role-marked multiplier input. Rows 45157 and 46052 fix opposite positions. |",
        "| `MNW subset B01` | refused_type_mismatch | MNW is role-marked; B01 is a role-free multiplication pair. |",
        "| `NID subset MNW` | refused_type_mismatch | NID is a role-free multiplication pair; MNW is role-marked. |",
        "| `MNW subset NID` | refused_type_mismatch | MNW is role-marked; NID is a role-free multiplication pair. |",
        "| `NID subset FDF` | refused_type_mismatch | FDF is a product-selection set (row 47041), not a multiplication pair. |",
        "| `FDF subset NID` | refused_type_mismatch | FDF is a product-selection set (row 47041), not a multiplication pair. |",
        "| `B01 subset FDF` | refused_type_mismatch | FDF is a product-selection set (row 47041), not a multiplication pair. |",
        "| `FDF subset B01` | refused_type_mismatch | FDF is a product-selection set (row 47041), not a multiplication pair. |",
        "| `SFN subset FPD`; `SFN subset FPE` | refused_disjoint | Row 46493's inverted fraction-part rule makes SFN the complement of FPD on strict raw-digit-order pairs; FPE is within FPD. |",
        "| `T9 subset SNF`; `NNF subset SNF`; `SNF subset NNF` | refused_type_mismatch | T9 and NNF are single numerals; SNF is a two-operand subtraction input (row 44544). |", "",
        "## Executable limit", "",
        "Predicate prose is reviewed source. The Python sweep is executable for every row above. The single SWI-Prolog invocation checks the one-sided GAP probe, the 7,474-case scale-loss reimplementation agreement, the W3-2 broad-endpoint membership probe, and the equal-value WND control. GAP remains asserted because its condition over-covers the reviewed 440 boundary; W3-2's probe attests membership rather than a class boundary.",
        "",
    ])
    return "\n".join(lines), frontier


def compare(expected: str) -> int:
    actual = RECEIPT.read_text(encoding="utf-8") if RECEIPT.is_file() else ""
    if actual == expected:
        return 0
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False) as temporary:
        temporary.write(expected)
        temporary_path = Path(temporary.name)
    sys.stderr.write("".join(difflib.unified_diff(actual.splitlines(True), expected.splitlines(True), fromfile=str(RECEIPT), tofile=str(temporary_path))))
    temporary_path.unlink(missing_ok=True)
    return 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail if the generated settlement receipt is stale")
    arguments = parser.parse_args()
    artifact, frontier = receipt()
    frontier_status = (
        f"typed_contexts={frontier['typed_contexts']}; "
        f"ordered_pairs={frontier['ordered_pairs']}; "
        f"strict={frontier['strict']}; "
        f"undeclared_strict={frontier['undeclared_strict']}"
    )
    if arguments.check:
        status = compare(artifact)
        if not status:
            print(
                "a-fortiori input-nesting receipt current: "
                "settled=19; task171=7; controls=7; fraction_pairs=4290; "
                + frontier_status
            )
        return status
    RECEIPT.write_text(artifact, encoding="utf-8")
    print(
        "a-fortiori input-nesting receipt written: "
        "settled=19; task171=7; controls=7; fraction_pairs=4290; "
        + frontier_status
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
