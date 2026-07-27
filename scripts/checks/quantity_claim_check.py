#!/usr/bin/env python3
"""Focused deterministic checks for hermes/quantity_claim.pl."""
from __future__ import annotations

import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MODULE = ROOT / "hermes/quantity_claim.pl"


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
}


def run_case(name: str, claim: str, expected: str) -> None:
    goal = (
        f"quantity_claim:check_quantity_claim({claim}, D),"
        f"get_dict(verdict, D, \"{expected}\")"
    )
    result = subprocess.run(
        ["swipl", "-q", "-s", str(MODULE), "-g", goal, "-t", "halt"],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if result.returncode:
        raise AssertionError(
            f"{name}: expected {expected}\nstdout: {result.stdout}\nstderr: {result.stderr}"
        )
    print(f"PASS {name}")


def main() -> int:
    for name, (claim, expected) in CASES.items():
        run_case(name, claim, expected)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
