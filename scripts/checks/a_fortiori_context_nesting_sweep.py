#!/usr/bin/env python3
"""Sweep reviewed typed input classes and render the a-fortiori receipt.

The checked source is formal/incompatibility/context_input_classes.json.  Its
predicate column is a reviewed prose specification of input classes, not an
inference from context atom names.  The Python batteries are its executable
restatement; they retain boundary witnesses and refusals.
"""
from __future__ import annotations

import argparse
import difflib
import json
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from fractions import Fraction
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
INPUT_CLASSES = ROOT / "formal" / "incompatibility" / "context_input_classes.json"
RECEIPT = ROOT / "docs" / "research" / "2026-07-29-a-fortiori-input-nesting-settlement.md"


@dataclass(frozen=True)
class DecimalNumeral:
    whole: int
    digits: str
    fractional: int
    scale: int
    written: int

    def display(self) -> str:
        return f"{self.whole}.{self.digits}"


def sign(value: int | Fraction) -> int:
    return (value > 0) - (value < 0)


def decimal_order(left: DecimalNumeral, right: DecimalNumeral) -> int:
    return sign(left.written * right.scale - right.written * left.scale)


def fractional_numeral_order(left: DecimalNumeral, right: DecimalNumeral) -> int:
    return sign(int(left.digits) - int(right.digits))


def length_order(left: DecimalNumeral, right: DecimalNumeral) -> int:
    return sign(len(left.digits) - len(right.digits))


def canonical_decimal_battery() -> list[DecimalNumeral]:
    """Whole parts 0..1; one to three nonzero, non-trailing-zero decimal strings."""
    digits = [
        f"{number:0{places}d}"
        for places in range(1, 4)
        for number in range(1, 10 ** places)
        if number % 10
    ]
    return [
        DecimalNumeral(whole, suffix, int(suffix), 10 ** len(suffix), whole * (10 ** len(suffix)) + int(suffix))
        for whole in range(2)
        for suffix in digits
    ]


def ordered_pairs(values: list[DecimalNumeral]):
    for left in values:
        for right in values:
            if left != right:
                yield left, right


def containment_receipt(name: str, values, narrow, broad, display) -> dict[str, object]:
    narrow_count = broad_count = narrow_minus_broad_count = broad_minus_narrow_count = 0
    narrow_witnesses: list[str] = []
    broad_witnesses: list[str] = []
    for value in values:
        in_narrow = narrow(value)
        in_broad = broad(value)
        narrow_count += in_narrow
        broad_count += in_broad
        if in_narrow and not in_broad:
            narrow_minus_broad_count += 1
            if len(narrow_witnesses) < 2:
                narrow_witnesses.append(display(value))
        if in_broad and not in_narrow:
            broad_minus_narrow_count += 1
            if len(broad_witnesses) < 2:
                broad_witnesses.append(display(value))
    return {
        "name": name,
        "narrow": narrow_count,
        "broad": broad_count,
        "narrow_minus_broad": narrow_minus_broad_count,
        "broad_minus_narrow": broad_minus_narrow_count,
        "narrow_witnesses": "; ".join(narrow_witnesses) or "none",
        "broad_witnesses": "; ".join(broad_witnesses) or "none",
    }


def divisor_rows() -> list[dict[str, object]]:
    divisors = [Fraction(value) for value in (-5, -1, 1, 2, 3, 5, 10, 25)] + [Fraction(1, 4), Fraction(1, 3), Fraction(1, 2), Fraction(3, 4), Fraction(125), Fraction(625), Fraction(3125), Fraction(15625)]
    powers = {Fraction(5 ** exponent) for exponent in range(1, 7)}
    is_whole = lambda value: value.denominator == 1
    not_whole = lambda value: not is_whole(value)
    open_interval = lambda value: 0 < value < 1
    not_one = lambda value: value != 1
    power_of_five = lambda value: value in powers
    whole_not_ten = lambda value: is_whole(value) and value != 10
    display = lambda value: str(value.numerator) if value.denominator == 1 else f"{value.numerator}/{value.denominator}"
    return [
        containment_receipt("the_divisor_is_not_a_whole_number subset the_divisor_is_not_one", divisors, not_whole, not_one, display),
        containment_receipt("the_divisor_lies_between_zero_and_one subset the_divisor_is_not_one", divisors, open_interval, not_one, display),
        containment_receipt("the_divisor_is_a_power_of_five subset the_divisor_is_not_ten", divisors, power_of_five, whole_not_ten, display),
        containment_receipt("the_divisor_is_a_power_of_five subset the_divisor_is_not_one", divisors, power_of_five, not_one, display),
        containment_receipt("CONTROL the_divisor_is_not_a_whole_number subset the_divisor_is_not_ten", divisors, not_whole, whole_not_ten, display),
    ]


def decimal_rows() -> list[dict[str, object]]:
    decimals = canonical_decimal_battery()
    names = [
        "fraction_part_numeral_order_diverges_within_equal_integer_parts subset fraction_part_numeral_order_diverges_from_value_order",
        "numeral_length_order_inverts_decimal_value_order subset the_numerals_carry_different_place_counts",
        "written_numeral_order_diverges_from_decimal_value_order subset the_numerals_carry_different_place_counts",
        "CONTROL numeral_length_order_inverts_decimal_value_order subset numeral_length_order_tracks_decimal_value_order",
    ]
    counts = [[0, 0, 0, 0] for _ in names]  # narrow, broad, narrow-minus-broad, broad-minus-narrow
    narrow_witnesses = [[] for _ in names]
    broad_witnesses = [[] for _ in names]
    for left, right in ordered_pairs(decimals):
        exact_order = sign(left.written * right.scale - right.written * left.scale)
        fractional_order = sign(left.fractional - right.fractional)
        place_order = sign(len(left.digits) - len(right.digits))
        different_places = place_order != 0
        fraction_broad = fractional_order != exact_order
        fraction_narrow = left.whole == right.whole and fraction_broad
        length_inverts = different_places and place_order == -exact_order
        length_tracks = different_places and place_order == exact_order
        written_scale_loss = sign(left.written - right.written) != exact_order
        cases = ((fraction_narrow, fraction_broad), (length_inverts, different_places),
                 (written_scale_loss, different_places), (length_inverts, length_tracks))
        for index, (in_narrow, in_broad) in enumerate(cases):
            counts[index][0] += in_narrow
            counts[index][1] += in_broad
            if in_narrow and not in_broad:
                counts[index][2] += 1
                if len(narrow_witnesses[index]) < 2:
                    narrow_witnesses[index].append(f"{left.display()} vs {right.display()}")
            if in_broad and not in_narrow:
                counts[index][3] += 1
                if len(broad_witnesses[index]) < 2:
                    broad_witnesses[index].append(f"{left.display()} vs {right.display()}")
    return [
        {"name": name, "narrow": count[0], "broad": count[1], "narrow_minus_broad": count[2], "broad_minus_narrow": count[3],
         "narrow_witnesses": "; ".join(narrow_witnesses[index]) or "none", "broad_witnesses": "; ".join(broad_witnesses[index]) or "none"}
        for index, (name, count) in enumerate(zip(names, counts))
    ]


def multiplication_rows() -> list[dict[str, object]]:
    values = [Fraction(number, 10) for number in range(31)]
    pairs = [(left, right) for left in values for right in values]
    between_zero_and_one = lambda pair: any(0 < value < 1 for value in pair)
    non_integer_decimal = lambda pair: any(value.denominator != 1 for value in pair)
    display = lambda pair: f"{float(pair[0]):.1f} x {float(pair[1]):.1f}"
    return [containment_receipt("a_factor_lies_between_zero_and_one subset a_factor_is_a_non_integer_decimal", pairs, between_zero_and_one, non_integer_decimal, display)]


def scale_loss_condition(numerator_one: int, scale_one: int,
                         numerator_two: int, scale_two: int) -> str:
    produced = sign(numerator_one - numerator_two)
    expected = sign(numerator_one * scale_two - numerator_two * scale_one)
    return (
        "written_numeral_order_diverges_from_decimal_value_order"
        if produced != expected
        else "written_numeral_order_coincides_with_decimal_value_order"
    )


def automaton_probe() -> tuple[list[str], int]:
    sample_query = (
        "use_module(math(smr_decimal_fraction_compare)), "
        "run_decimal_scale_loss_compare(1,10,2,10,_,First,_), write_canonical(First), nl, "
        "run_decimal_scale_loss_compare(8,10,14,100,_,Second,_), write_canonical(Second), nl, halt"
    )
    completed = subprocess.run(
        ["swipl", "-q", "-l", str(ROOT / "paths.pl"), "-g", sample_query],
        cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
    )
    if completed.returncode or completed.stderr.strip():
        raise RuntimeError(completed.stderr.strip() or "decimal scale-loss automaton probe failed")
    lines = completed.stdout.splitlines()
    if len(lines) != 2 or "contextual_success" not in lines[0] or "written_numeral_order_diverges_from_decimal_value_order" not in lines[1]:
        raise RuntimeError(f"unexpected decimal scale-loss automaton probe: {lines!r}")
    battery_query = (
        "use_module(math(smr_decimal_fraction_compare)), "
        "forall((member(S1,[10,100,1000]), between(1,29,N1), "
        "member(S2,[10,100,1000]), between(1,29,N2), N1*S2 =\\= N2*S1), "
        "(run_decimal_scale_loss_compare(N1,S1,N2,S2,_,Viability,_), "
        "arg(2,Viability,condition(Condition)), "
        "format('~d\\t~d\\t~d\\t~d\\t~w~n',[N1,S1,N2,S2,Condition]))), halt"
    )
    battery = subprocess.run(
        ["swipl", "-q", "-l", str(ROOT / "paths.pl"), "-g", battery_query],
        cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
    )
    if battery.returncode or battery.stderr.strip():
        raise RuntimeError(battery.stderr.strip() or "decimal scale-loss automaton battery failed")
    observed = battery.stdout.splitlines()
    if len(observed) != 7474:
        raise RuntimeError(f"expected 7474 unequal-value automaton cases, found {len(observed)}")
    for line in observed:
        fields = line.split("\t")
        if len(fields) != 5:
            raise RuntimeError(f"malformed decimal scale-loss automaton row: {line!r}")
        numerator_one, scale_one, numerator_two, scale_two = map(int, fields[:4])
        if fields[4] != scale_loss_condition(numerator_one, scale_one, numerator_two, scale_two):
            raise RuntimeError(f"decimal scale-loss reimplementation disagrees with automaton: {line!r}")
    return lines, len(observed)


def validate_classes() -> None:
    source = json.loads(INPUT_CLASSES.read_text(encoding="utf-8"))
    if source.get("schema_version") != 1 or not isinstance(source.get("contexts"), dict):
        raise RuntimeError("unsupported context-input-class source")
    required = {"input_type", "feature", "predicate", "prose"}
    needed = {
        "the_divisor_is_not_a_whole_number", "the_divisor_lies_between_zero_and_one", "the_divisor_is_not_one", "the_divisor_is_a_power_of_five", "the_divisor_is_not_ten",
        "fraction_part_numeral_order_diverges_from_value_order", "fraction_part_numeral_order_diverges_within_equal_integer_parts",
        "numeral_length_order_inverts_decimal_value_order", "numeral_length_order_tracks_decimal_value_order", "the_numerals_carry_different_place_counts", "written_numeral_order_diverges_from_decimal_value_order",
        "a_factor_lies_between_zero_and_one", "a_factor_is_a_non_integer_decimal",
    }
    if not needed <= source["contexts"].keys():
        raise RuntimeError("context-input-class source omits a settled endpoint or control")
    for context in needed:
        row = source["contexts"][context]
        if not isinstance(row, dict) or set(row) != required or not all(isinstance(row[field], str) and row[field] for field in required):
            raise RuntimeError(f"invalid typed input class for {context}")


def render_row(row: dict[str, object], domain_decided: bool = True) -> str:
    if not domain_decided:
        verdict = "undecided_domain"
    elif row["narrow_minus_broad"] == 0 and row["broad_minus_narrow"]:
        verdict = "contained_strict"
    elif row["narrow_minus_broad"] == 0 and row["broad_minus_narrow"] == 0:
        verdict = "contained_equal"
    elif row["narrow"] and row["broad"] and row["narrow_minus_broad"] == row["narrow"]:
        verdict = "refused_disjoint"
    else:
        verdict = "refused_counterexample"
    return f"| `{row['name']}` | {row['narrow']} | {row['broad']} | {row['narrow_minus_broad']} | {row['broad_minus_narrow']} | {verdict} | narrow-not-broad: {row['narrow_witnesses']}; broad-not-narrow: {row['broad_witnesses']} |"


def receipt() -> str:
    validate_classes()
    divisor = divisor_rows()
    decimal = decimal_rows()
    multiplication = multiplication_rows()
    probe, automaton_cases = automaton_probe()
    settled = divisor[:4] + decimal[:3] + multiplication
    controls = [divisor[4], decimal[3]]
    if any(row["narrow_minus_broad"] != 0 or row["broad_minus_narrow"] == 0 for row in settled):
        raise RuntimeError("a proposed nesting did not sweep as a strict containment")
    if controls[0]["narrow_minus_broad"] != controls[0]["narrow"] or controls[1]["narrow_minus_broad"] == 0:
        raise RuntimeError("a required over-copy or complement control stopped refusing")
    return "\n".join([
        "# A-fortiori context nesting: input settlement receipt",
        "",
        "Generated by `python3 scripts/checks/a_fortiori_context_nesting_sweep.py`. The source predicate column is the reviewed prose specification; this Python battery is its executable restatement, so no verdict is inferred from context atom names.",
        "",
        "This receipt settles the eight Task 163 rows. The four pre-existing divisor/expansion rows retain their warrants in `formal/incompatibility/a_fortiori_context_nestings.json`.",
        "",
        "The divisor battery is `-5, -1, 1/4, 1/3, 1/2, 3/4, 1, 2, 3, 5, 10, 25, 125, 625, 3125, 15625`; powers of five mean `5^k` for `k = 1..6`. The decimal-pair battery has whole parts 0..1 and canonical one-to-three-place nonzero, non-trailing-zero fractional strings (1,998 written decimals; 3,990,006 ordered unequal pairs). The multiplication battery is ordered finite tenths from 0.0 through 3.0 (961 pairs).",
        "",
        "## Settled rows",
        "",
        "| narrow subset broad | narrow count | broad count | narrow-minus-broad count | broad-minus-narrow count | verdict | boundary witnesses |",
        "| --- | ---: | ---: | ---: | ---: | --- | --- |",
        *(render_row(row) for row in settled),
        "",
        f"The decimal scale-loss reimplementation agrees with `smr_decimal_fraction_compare:run_decimal_scale_loss_compare/7` on all {automaton_cases} ordered unequal-value inputs with scales 10, 100, and 1000 and numerators 1..29. This certifies the narrow endpoint's executable restatement only; the broad different-place predicate has no automaton decider, so the inclusion remains asserted.",
        "",
        f"- `1/10` vs `2/10`: `{probe[0]}`",
        f"- `8/10` vs `14/100`: `{probe[1]}`",
        "",
        "## Refusal controls",
        "",
        "| proposed narrow subset broad | narrow count | broad count | narrow-minus-broad count | broad-minus-narrow count | verdict | boundary witnesses |",
        "| --- | ---: | ---: | ---: | ---: | --- | --- |",
        *(render_row(row) for row in controls),
        "",
        "The first control retains the whole-divisor-remainder reading of `the_divisor_is_not_ten`: every non-whole-divisor input is outside that class. The second uses canonical decimal spellings, so unequal fractional-place counts have a strict exact order and the tracks/inverts predicates partition the battery.",
        "",
        "## Reading decisions",
        "",
        "- `the_divisor_lies_between_zero_and_one` uses the atom name; four of five codings exclude divisor = 1, and three name the open interval outright (44117, 45968, 46010; 45883 excludes 1 without a positive lower bound). Coding 46352 is the dissent: it says less than or equal to one. Under (0,1] this row is false because 1 is narrow and not in not-one.",
        "- `the_divisor_is_not_one` is not given the whole-divisor restriction used by not-ten. Coding 45251 uses a long-division remainder digit and needs a whole divisor; coding 46311 counts pieces in a visual model, and divisor 0.4 leaves a partial group on which the rule is defeated. Adding integer(D) would make both rows into not-one refused_disjoint.",
        "- `the_divisor_is_a_power_of_five` starts at `5^1` because coding 46236 classifies termination by powers of two: 5^0 = 1 = 2^0 does not diverge for that rule.",
        "- The multiplication row ranges over finite written decimal factors. It therefore does not claim that an arbitrary value such as `1/3` has a finite decimal numeral.",
        "",
        "## Open executable-predicate gap",
        "",
        "The predicate column is reviewed Prolog-shaped notation, not a loaded module: its named helpers are not all defined in SWI-Prolog. The Python sweep is the executable restatement. The scale-loss predicate is additionally checked against the loaded automaton above; the remaining predicate helpers should be made executable in a later input-class module.",
        "",
    ])


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
    artifact = receipt()
    if arguments.check:
        status = compare(artifact)
        if not status:
            print("a-fortiori input-nesting receipt current: settled=8; controls=2; decimal_pairs=3990006")
        return status
    RECEIPT.write_text(artifact, encoding="utf-8")
    print("a-fortiori input-nesting receipt written: settled=8; controls=2; decimal_pairs=3990006")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
