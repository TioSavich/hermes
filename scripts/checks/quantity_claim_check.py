#!/usr/bin/env python3
"""Focused deterministic checks for hermes/quantity_claim.pl."""
from __future__ import annotations

import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PATHS = ROOT / "paths.pl"


CASES = {
    "mixed kinds are incommensurable": (
        'sum(quantity(2,grapes,"2 grapes"),quantity(4,apples,"4 apples"),'
        'quantity(6,fruit,"6 fruit"))',
        'incommensurable',
    ),
    "like kinds add": (
        'sum(quantity(2,grapes,"2 grapes"),quantity(4,grapes,"4 grapes"),'
        'quantity(6,grapes,"6 grapes"))',
        'holds',
    ),
    "dimensionless scaling preserves kind": (
        'scaling(quantity(3,dimensionless,"3"),quantity(8,tires,"8 tires"),'
        'quantity(24,tires,"24 tires"))',
        'holds',
    ),
    "product retains a compound kind": (
        'product(quantity(3,meters,"3 meters"),quantity(8,meters,"8 meters"),'
        'quantity(24,meters_times_meters,"24 square meters"))',
        'holds',
    ),
    "like-kind quotient is dimensionless": (
        'quotient(quantity(24,tires,"24 tires"),quantity(4,tires,"4 tires"),'
        'quantity(6,dimensionless,"6"))',
        'holds',
    ),
    "unlike-kind quotient is a named rate": (
        'quotient(quantity(120,miles,"120 miles"),quantity(2,hours,"2 hours"),'
        'quantity(60,miles_per_hours,"60 miles per hour"))',
        'holds',
    ),
    "unbound stays unchecked": (
        'sum(quantity(2,unbound,"2"),quantity(4,grapes,"4 grapes"),'
        'quantity(6,grapes,"6 grapes"))',
        'not_checked',
    ),
    # Kinds that differ do not combine, however alike they read.  A shared
    # parent that made these one kind was measured and lost on every axis.
    "kinds that differ do not combine": (
        'difference(quantity(24,students_without_an_a,"24 students"),'
        'quantity(6,students_with_a_b_or_c,"6 students"),'
        'quantity(18,students,"18 students"))',
        'incommensurable',
    ),
    "a plural marker still names a different kind": (
        'sum(quantity(2,minutes_of_practice,"2 minutes"),'
        'quantity(4,minute_of_rest,"4 minutes"),'
        'quantity(6,minutes,"6 minutes"))',
        'incommensurable',
    ),
    "a rate is not its own base measure": (
        'difference(quantity(40,gallons,"40 gallons"),'
        'quantity(2,gallons_lost_per_hour,"2 gallons per hour"),'
        'quantity(38,gallons,"38 gallons"))',
        'incommensurable',
    ),
    # What a step calls its result is the step's own label.  Refusing a step
    # over that label accused 33 of 60 correct reference solutions, because it
    # cannot tell a badly named result from a wrongly computed one.
    "a result named by role is recorded, not refuted": (
        'product(quantity(12,length,"12 foot"),quantity(5,length,"5-foot"),'
        'quantity(60,area,"60 square feet"))',
        'holds',
    ),
    "a partitive quotient named by its dividend is not refuted": (
        'quotient(quantity(108,oranges,"108 oranges"),quantity(12,students,"12 students"),'
        'quantity(9,oranges,"9 oranges"))',
        'holds',
    ),
    # The candle case, and the limit it now marks: 45/8 is exactly 5.625, so
    # nothing in the magnitude refutes it.  What catches the step is the
    # incommensurability of the operands, not the name given to the result.
    "an exact quotient is not refuted by its result name": (
        'quotient(quantity(45,red_candles,"45"),quantity(8,ratio_parts,"8"),'
        'quantity(5.625,sets,"5.625"))',
        'holds',
    ),
    "the magnitude still decides": (
        'sum(quantity(2,grapes,"2 grapes"),quantity(4,grapes,"4 grapes"),'
        'quantity(7,grapes,"7 grapes"))',
        'refuted',
    ),
}


EXPRESSION_CASES = {
    "a tree adjudicates without intermediate kinds supplied": (
        'quotient(quantity(45,red_candles,"45"),'
        'sum(quantity(5,ratio_parts,"5"),quantity(3,ratio_parts,"3")))',
        'quantity(5.625,sets,"5.625")',
        'holds',
    ),
    "a tree refutes on the magnitude it computes": (
        'quotient(quantity(45,red_candles,"45"),'
        'sum(quantity(5,ratio_parts,"5"),quantity(3,ratio_parts,"3")))',
        'quantity(9,sets,"9")',
        'refuted',
    ),
    "a tree that holds all the way through holds": (
        'sum(quantity(2,grapes,"2 grapes"),'
        'sum(quantity(3,grapes,"3 grapes"),quantity(4,grapes,"4 grapes")))',
        'quantity(9,grapes,"9 grapes")',
        'holds',
    ),
    "the first blocking node is what the tree reports": (
        'sum(quantity(2,grapes,"2 grapes"),'
        'sum(quantity(3,apples,"3 apples"),quantity(4,minutes,"4 minutes")))',
        'quantity(9,grapes,"9 grapes")',
        'incommensurable',
    ),
    "one unbound leaf leaves the whole tree unchecked": (
        'sum(quantity(2,grapes,"2 grapes"),'
        'sum(quantity(3,unbound,"3"),quantity(4,grapes,"4 grapes")))',
        'quantity(9,grapes,"9 grapes")',
        'not_checked',
    ),
}


def run_goal(name: str, goal: str) -> None:
    result = subprocess.run(
        ["swipl", "-q", "-l", str(PATHS), "-g", goal, "-t", "halt"],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if result.returncode:
        raise AssertionError(
            f"{name}\nstdout: {result.stdout}\nstderr: {result.stderr}"
        )
    print(f"PASS {name}")


def run_case(name: str, claim: str, expected: str) -> None:
    goal = (
        "use_module(hermes(quantity_claim)),"
        f"quantity_claim:check_quantity_claim({claim}, D),"
        f"get_dict(verdict, D, \"{expected}\")"
    )
    run_goal(f"{name}: expected {expected}", goal)


def run_expression_case(name: str, expression: str, claimed: str, expected: str) -> None:
    goal = (
        "use_module(hermes(quantity_claim)),"
        f"quantity_claim:check_quantity_expression({expression}, {claimed}, D),"
        f"get_dict(verdict, D, \"{expected}\")"
    )
    run_goal(f"{name}: expected {expected}", goal)


def main() -> int:
    for name, (claim, expected) in CASES.items():
        run_case(name, claim, expected)
    for name, (expression, claimed, expected) in EXPRESSION_CASES.items():
        run_expression_case(name, expression, claimed, expected)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
