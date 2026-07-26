#!/usr/bin/env python3
"""Deterministic checks for math-claim reading and step adjudication."""
from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys
from typing import Any


ROOT = Path(__file__).resolve().parents[2]


def fail(message: str) -> None:
    raise AssertionError(message)


def prolog_json(goal: str) -> Any:
    completed = subprocess.run(
        ["swipl", "-q", "-l", "paths.pl", "-g", goal],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode:
        fail(
            "Prolog check failed "
            f"(exit {completed.returncode}): {completed.stderr.strip()}"
        )
    try:
        return json.loads(completed.stdout.strip())
    except json.JSONDecodeError as exc:
        fail(f"Prolog returned unreadable JSON: {completed.stdout!r} ({exc})")


def prolog_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def claims(surface: str) -> list[str]:
    goal = (
        "use_module(hermes(math_claim_language)),"
        "use_module(library(http/json)),"
        f"math_claims_in_text({prolog_string(surface)},Claims),"
        "maplist(term_string,Claims,Texts),"
        "json_write_dict(current_output,_{claims:Texts},[width(0)]),nl,halt"
    )
    return prolog_json(goal)["claims"]


def adjudicate(text: str) -> dict[str, Any]:
    goal = (
        "use_module(hermes(solution_step_check)),"
        "use_module(library(http/json)),"
        f"check_solution_steps({prolog_string(text)},Report),"
        "json_write_dict(current_output,Report,[width(0)]),nl,halt"
    )
    return prolog_json(goal)


def check_reader() -> None:
    fixtures = (
        ("7*10+5*25=195", ["arithmetic_equation(7*10+5*25,195)"]),
        (
            "200 + 200/2 = 200 + 100 = 300",
            [
                "arithmetic_equation(200+200/2,200+100)",
                "arithmetic_equation(200+100,300)",
            ],
        ),
        ("5+3 = 8", ["sum(5,3,8)"]),
        ("48/2 = 24", ["arithmetic_equation(48/2,24)"]),
        ("$2 * 13 = $26", ["arithmetic_equation(2*13,26)"]),
        ("half of 80 is 40", ["fraction_of(80,fraction(1,2),40)"]),
        ("50% of 80 = 40", ["arithmetic_equation(50/100*80,40)"]),
    )
    for surface, expected in fixtures:
        actual = claims(surface)
        if actual != expected:
            fail(f"{surface!r}: expected {expected!r}, received {actual!r}")


def check_abstentions() -> None:
    fixtures = (
        "First find the absent students: 2 students * 3 - 1= 5 students",
        "the colony was catching 158 * 1 1/2 = 237 fish per day",
        "she sold half as many",
        "two specialists each looked at Dakota for 15 minutes",
        "x + 3 = 7",
        "about 20 + 30 = 50ish",
        ".20*20 = $4.00",
    )
    for surface in fixtures:
        actual = claims(surface)
        if actual:
            fail(f"{surface!r}: expected abstention, received {actual!r}")


def step_by_index(report: dict[str, Any], index: int) -> dict[str, Any]:
    for step in report["steps"]:
        if step["index"] == index:
            return step
    fail(f"report contains no step {index}: {report!r}")


def check_chains() -> None:
    good = adjudicate(
        "Step 1 - 48 / 2 = 24\n"
        "Step 2 - 24 - 1 - 3 = 20\n"
        "Step 3 - 20 / 2 = 10"
    )
    if good["first_refuted_step"] != "none":
        fail(f"known-good chain was refuted: {good!r}")
    if good["checked_equations"] != 3 or good["refuted_equations"] != 0:
        fail(f"known-good counts are wrong: {good!r}")

    wrong_second = adjudicate(
        "Step 1 - 48 / 2 = 24\n"
        "Step 2 - 24 - 1 - 3 = 21\n"
        "Step 3 - 20 / 2 = 10"
    )
    if wrong_second["first_refuted_step"] != 2:
        fail(f"wrong second step was not located: {wrong_second!r}")

    unreadable_then_wrong = adjudicate(
        "Step 1 - 48 / 2 = 24\n"
        "Step 2 - she sold half as many\n"
        "Step 3 - 20 / 2 = 11"
    )
    if unreadable_then_wrong["first_refuted_step"] != 3:
        fail(f"wrong third step was not located: {unreadable_then_wrong!r}")
    if step_by_index(unreadable_then_wrong, 2)["verdict"] != "not_checked":
        fail(f"unreadable step was not not_checked: {unreadable_then_wrong!r}")


def check_precedence_and_narration() -> None:
    precedence = adjudicate("Step 1 - 7*10+5*25=195")
    if precedence["checked_equations"] != 1:
        fail(f"precedence regression was not adjudicated: {precedence!r}")
    if precedence["refuted_equations"] != 0:
        fail(f"true mixed-precedence equation was refuted: {precedence!r}")

    narrated = adjudicate("Step 4 - 5+3 = 9")
    equation = step_by_index(narrated, 4)["equations"][0]
    trace = " ".join(equation["trace"])
    if equation["verdict"] != "refuted" or "count on from 5 by 3" not in trace:
        fail(f"sum narration was not preserved: {narrated!r}")


def main() -> int:
    try:
        check_reader()
        check_abstentions()
        check_chains()
        check_precedence_and_narration()
    except AssertionError as exc:
        print(f"math claim language check: FAIL: {exc}", file=sys.stderr)
        return 1
    print("math claim language check: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
