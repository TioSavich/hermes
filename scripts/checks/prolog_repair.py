#!/usr/bin/env python3
"""Check what the Prolog arm's repair ladder recovers, and what it must not.

Runs the authored corpus in `scripts/research/prolog_repair_corpus.py` through
the same extract, screen, and run path the benchmark arm uses, once with the
ladder off and once with it on. No model is called and no benchmark item is
read, so the whole check is deterministic and offline; it needs swipl.

Four properties have to hold together, and the ladder is only worth having if
all four do:

1. every program that already runs still runs, at the same value;
2. every program the harness discarded now runs, at the value it meant;
3. no program that fails to determine an answer acquires one;
4. no program the screen refuses becomes runnable at any rung.

`--json` prints the counts for a report to quote.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import shutil
import sys
import tempfile
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
RESEARCH = ROOT / "scripts/research"
if str(RESEARCH) not in sys.path:
    sys.path.insert(0, str(RESEARCH))

import mtb_prolog_repair  # noqa: E402
import mtb_prolog_responder as responder  # noqa: E402
import prolog_repair_corpus as corpus  # noqa: E402

ANSWERED = {"ran", "ran_grounded"}


def _run_one(program: str, scratch: Path) -> tuple[str, str | None]:
    """Screen then run one program text, the way the arm does."""
    screened = responder.screen_program(program)
    if not screened.allowed:
        return "rejected_unsafe", None
    result = responder.run_program(program, scratch)
    return result.outcome, result.value


def solve(
    reply: str, scratch: Path, *, repair: bool,
) -> tuple[str, str | None, tuple[str, ...], int]:
    """Return the outcome, value, repair steps, and rung for one reply."""
    program = responder.extract_program(reply)
    if program is None:
        return "no_program", None, (), 0
    outcome, value = _run_one(program, scratch)
    if outcome in ANSWERED or not repair:
        return outcome, value, (), 0
    try:
        rungs = mtb_prolog_repair.repair_ladder(program)
    except (ValueError, RecursionError):
        return outcome, value, (), 0
    for number, rung in enumerate(rungs, start=1):
        repaired_outcome, repaired_value = _run_one(rung.program, scratch)
        if repaired_outcome in ANSWERED:
            return repaired_outcome, repaired_value, rung.steps, number
    return outcome, value, (), 0


def evaluate(scratch: Path) -> dict[str, Any]:
    """Score every authored case with the ladder off and then on."""
    rows: list[dict[str, Any]] = []
    for case in corpus.CASES:
        plain_outcome, plain_value, _, _ = solve(
            case.reply, scratch, repair=False)
        outcome, value, steps, rung = solve(case.reply, scratch, repair=True)
        rows.append({
            "name": case.name,
            "verdict": case.verdict,
            "expected_value": case.value,
            "without_repair": {"outcome": plain_outcome, "value": plain_value},
            "with_repair": {
                "outcome": outcome, "value": value,
                "steps": list(steps), "rung": rung,
            },
        })
    return {
        "cases": len(rows),
        "answered_without_repair": sum(
            1 for row in rows if row["without_repair"]["outcome"] in ANSWERED),
        "answered_with_repair": sum(
            1 for row in rows if row["with_repair"]["outcome"] in ANSWERED),
        "rows": rows,
    }


def failures(report: dict[str, Any]) -> list[str]:
    """Name every case whose outcome breaks one of the four properties."""
    problems: list[str] = []
    for row in report["rows"]:
        name = row["name"]
        verdict = row["verdict"]
        plain = row["without_repair"]
        repaired = row["with_repair"]
        answered = repaired["outcome"] in ANSWERED

        if verdict == "runs":
            if plain["outcome"] not in ANSWERED:
                problems.append(
                    f"{name}: authored as running and did not run "
                    f"({plain['outcome']})")
            elif repaired["steps"] or repaired["rung"]:
                problems.append(f"{name}: a running program was repaired")
            elif repaired["value"] != row["expected_value"]:
                problems.append(
                    f"{name}: value {repaired['value']!r} is not the authored "
                    f"{row['expected_value']!r}")
        elif verdict == "harness":
            if plain["outcome"] in ANSWERED:
                problems.append(
                    f"{name}: authored as discarded and ran without repair")
            elif not answered:
                problems.append(
                    f"{name}: not recovered ({repaired['outcome']})")
            elif repaired["value"] != row["expected_value"]:
                problems.append(
                    f"{name}: recovered at {repaired['value']!r}, not the "
                    f"authored {row['expected_value']!r}")
        elif verdict == "model":
            if answered:
                problems.append(
                    f"{name}: repair invented the answer {repaired['value']!r} "
                    "for a program that determines none")
        elif verdict == "unsafe":
            if plain["outcome"] != "rejected_unsafe":
                problems.append(
                    f"{name}: authored as refused and was not "
                    f"({plain['outcome']})")
            elif repaired["outcome"] != "rejected_unsafe":
                problems.append(
                    f"{name}: repair carried a refused program to "
                    f"{repaired['outcome']}")
        else:
            problems.append(f"{name}: unknown verdict {verdict!r}")
    return problems


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true",
                        help="print the per-case report instead of PASS lines")
    arguments = parser.parse_args()

    if shutil.which("swipl") is None:
        print("prolog_repair.py: swipl is required", file=sys.stderr)
        return 2

    with tempfile.TemporaryDirectory() as temporary:
        report = evaluate(Path(temporary))
    problems = failures(report)

    if arguments.json:
        print(json.dumps(report, indent=2, sort_keys=True))
        return 1 if problems else 0

    if problems:
        for problem in problems:
            print(f"FAIL {problem}", file=sys.stderr)
        return 1

    counts = {verdict: len(corpus.by_verdict(verdict))
              for verdict in ("runs", "harness", "model", "unsafe")}
    print(
        f"PASS {counts['runs']} running programs untouched, "
        f"{counts['harness']} harness losses recovered at the authored value, "
        f"{counts['model']} undetermined programs left unanswered, "
        f"{counts['unsafe']} refused programs still refused"
    )
    print(
        f"PASS answered {report['answered_without_repair']}/{report['cases']} "
        f"without the ladder, {report['answered_with_repair']}/{report['cases']} "
        f"with it"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
