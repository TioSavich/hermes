#!/usr/bin/env python3
"""Deterministic checks for arithmetic step reading and Prolog adjudication."""
from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import subprocess
import sys
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
READER_PATH = ROOT / "scripts" / "research" / "arith_step_reader.py"


def fail(message: str) -> None:
    raise AssertionError(message)


def load_reader() -> Any:
    spec = importlib.util.spec_from_file_location("arith_step_reader", READER_PATH)
    if spec is None or spec.loader is None:
        fail(f"could not load {READER_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


READER = load_reader()


def one_equation(surface: str) -> dict[str, str]:
    steps = READER.read_steps(surface)
    if len(steps) != 1:
        fail(f"{surface!r}: expected one step, received {steps!r}")
    equations = steps[0]["equations"]
    if len(equations) != 1:
        fail(f"{surface!r}: expected one equation, received {equations!r}")
    return equations[0]


def check_surface_forms() -> None:
    fixtures = (
        ("48/2 = 24", "48 / 2", "24"),
        ("3 x 8 = 24", "3 * 8", "24"),
        ("2 * 4 = 8", "2 * 4", "8"),
        ("48 + 24 = 72", "48 + 24", "72"),
        ("24-1-3 = 20", "24 - 1 - 3", "20"),
        # Two precedences in one line. Bracketing the operators left to right
        # renders this ((7 * 10) + 5) * 25 and refutes a true statement, so the
        # reader leaves precedence to Prolog, which reads it as the writer did.
        ("7*10+5*25=195", "7 * 10 + 5 * 25", "195"),
        ("200 + 200/2 = 300", "200 + 200 / 2", "300"),
        ("100 - 20/4 = 95", "100 - 20 / 4", "95"),
        ("20 / 2 = 10", "20 / 2", "10"),
        ("$2 * 13 = $26", "2 * 13", "26"),
        ("1,200 + 300 = 1500", "1200 + 300", "1500"),
        ("60 * 0.5 = 30", "60 * 0.5", "30"),
        ("3 times 4 is 12", "3 * 4", "12"),
        ("half of 80 is 40", "1 / 2 * 80", "40"),
        ("50% of 80 = 40", "50 / 100 * 80", "40"),
    )
    for surface, expected_left, expected_right in fixtures:
        equation = one_equation(surface)
        actual = (equation["left"], equation["right"])
        expected = (expected_left, expected_right)
        if actual != expected:
            fail(f"{surface!r}: expected {expected!r}, received {actual!r}")
        if equation["span"] != surface:
            fail(f"{surface!r}: source span changed to {equation['span']!r}")

    multiple = READER.read_steps("3 * 8 = 24, then 24 + 1 = 25")
    if len(multiple) != 1 or len(multiple[0]["equations"]) != 2:
        fail(f"multiple equations in one step were not retained: {multiple!r}")

    unit_equation = one_equation("3 * 8 = 24 dollars")
    if unit_equation["right"] != "24":
        fail(f"trailing unit was not removed: {unit_equation!r}")


def check_abstentions() -> None:
    fixtures = (
        "she sold half as many",
        "two specialists each looked at Dakota for 15 minutes",
        "x + 3 = 7",
        "about 20 + 30 = 50ish",
        # An operand cut off from its own expression by the words between.
        # Reading `3 - 1= 5` out of this refutes a true line, which is worse
        # than saying nothing about it.
        "First find the absent students: 2 students * 3 - 1= 5 students",
        # A mixed number the reader cannot represent; `1/2 = 237` is not what
        # the line says.
        "the colony was catching 158 * 1 1/2 = 237 fish per day",
    )
    for surface in fixtures:
        steps = READER.read_steps(surface)
        equations = [equation for step in steps for equation in step["equations"]]
        if equations:
            fail(f"{surface!r}: expected abstention, received {equations!r}")


def prolog_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def step_terms(steps: list[dict[str, Any]]) -> str:
    rendered_steps: list[str] = []
    for step in steps:
        equations = ",".join(
            "equation("
            f"{prolog_string(equation['span'])},"
            f"{equation['left']},"
            f"{equation['right']}"
            ")"
            for equation in step["equations"]
        )
        rendered_steps.append(f"step({step['index']},[{equations}])")
    return f"[{','.join(rendered_steps)}]"


def adjudicate(text: str) -> dict[str, Any]:
    terms = step_terms(READER.read_steps(text))
    goal = (
        "use_module(hermes(solution_step_check)),"
        "use_module(library(http/json)),"
        f"check_solution_steps({terms},Report),"
        "json_write_dict(current_output,Report,[width(0)]),nl,halt"
    )
    completed = subprocess.run(
        ["swipl", "-q", "-l", "paths.pl", "-g", goal],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode:
        fail(
            "Prolog adjudication failed "
            f"(exit {completed.returncode}): {completed.stderr.strip()}"
        )
    try:
        return json.loads(completed.stdout.strip())
    except json.JSONDecodeError as exc:
        fail(f"Prolog returned unreadable JSON: {completed.stdout!r} ({exc})")


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
        fail(f"unreadable step was not marked not_checked: {unreadable_then_wrong!r}")


def check_numbering() -> None:
    steps = READER.read_steps("Step 2 - 3 * 8 = 24\nStep 7: 24 + 1 = 25")
    if [step["index"] for step in steps] != [2, 7]:
        fail(f"source step numbering was not preserved: {steps!r}")


def main() -> int:
    try:
        check_surface_forms()
        check_abstentions()
        check_numbering()
        check_chains()
    except AssertionError as exc:
        print(f"arith step reader check: FAIL: {exc}", file=sys.stderr)
        return 1
    print("arith step reader check: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
