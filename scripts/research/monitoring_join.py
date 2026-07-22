#!/usr/bin/env python3
"""Pass 3: the monitoring join. Refuted claims re-read against the
lesson's viability contexts; anticipations matched to what occurred.

The two-pass chain adjudicates each claim as stated. This join asks the
question a monitoring teacher asks next: is a refuted claim one of the
lesson's anticipated patterns — true of a different referent, or true
under a quotient-with-remainder reading? Every re-read is verified
through swipl over exact rationals; no model is consulted. Ambient
referent units come from lesson facts first (registered task divisors),
then from fractions spoken near the claim, each labeled with its
provenance.

Matching a re-read to a chart row is lexical here (shared stems such as
"referent"/"unit whole" against the row's documented-error text) and is
labeled as lexical; embedding-based matching belongs to the interpreter
tier, not to this deterministic pass.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
from fractions import Fraction
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]

_NUMBERED = re.compile(r"^U(\d{4})\s")


def swipl_rational_check(equations: list[tuple[str, str]]) -> list[bool]:
    """Verify candidate equalities through swipl exact-rational arithmetic.

    Each pair is (left, right) in swipl rational syntax (e.g. "1r3 / 2r3",
    "1r2"). Returns one boolean per pair; a load or parse failure fails
    the whole batch closed (all False) rather than guessing."""
    if not equations:
        return []
    checks = ", ".join(
        f"( catch((X{i} is {left}, X{i} =:= {right}), _, fail) "
        f"-> write(t) ; write(f) ), nl"
        for i, (left, right) in enumerate(equations)
    )
    goal = f"{checks}, halt."
    proc = subprocess.run(
        [os.environ.get("HERMES_SWIPL", "swipl"), "-q", "-g", goal],
        text=True, capture_output=True, check=False,
    )
    lines = proc.stdout.strip().splitlines()
    if proc.returncode != 0 or len(lines) != len(equations):
        return [False] * len(equations)
    return [line.strip() == "t" for line in lines]


def rational(value: Fraction) -> str:
    return f"{value.numerator}r{value.denominator}"


def fraction_pairs(term: str) -> list[Fraction]:
    return [Fraction(int(a), int(b))
            for a, b in re.findall(r"fraction\((\d+),(\d+)\)", term)]


def lesson_task_units(facts: dict[str, Any]) -> set[Fraction]:
    units = set()
    for task in facts.get("tasks", []):
        try:
            units.add(Fraction(int(task["b"])))
        except (KeyError, TypeError, ValueError):
            continue
    return units


def spoken_units(lines: list[str], index: dict[int, int],
                 utterance_id: str, radius: int) -> set[Fraction]:
    match = re.search(r"(\d+)", str(utterance_id))
    if not match or int(match.group(1)) not in index:
        return set()
    center = index[int(match.group(1))]
    found: set[Fraction] = set()
    for line in lines[max(0, center - radius):center + radius + 1]:
        for a, b in re.findall(r"(\d+)\s*/\s*(\d+)", line):
            if int(b):
                found.add(Fraction(int(a), int(b)))
    return found


def transcript_index(numbered: str) -> tuple[list[str], dict[int, int]]:
    lines = numbered.splitlines()
    return lines, {int(m.group(1)): i for i, line in enumerate(lines)
                   if (m := _NUMBERED.match(line))}


def candidate_rereads(claim: dict[str, Any], facts: dict[str, Any],
                      lines: list[str], index: dict[int, int],
                      radius: int) -> list[dict[str, Any]]:
    """Candidate viability re-reads; each carries the swipl equation that
    must verify before the re-read is reported."""
    term = str(claim.get("term", ""))
    out: list[dict[str, Any]] = []

    m = re.match(r"equivalence\(fraction\((\d+),(\d+)\),"
                 r"fraction\((\d+),(\d+)\)\)", term)
    if m:
        a = Fraction(int(m.group(1)), int(m.group(2)))
        b = Fraction(int(m.group(3)), int(m.group(4)))
        units = ([(u, "lesson_task") for u in sorted(lesson_task_units(facts))]
                 + [(u, "spoken_nearby") for u in sorted(spoken_units(
                     lines, index, claim.get("utterance_id", ""), radius))])
        for unit, provenance in units:
            if unit in (0, 1):
                continue
            out.append({
                "reading": "holds_under_referent_shift",
                "context": (f"{a} of the whole is {b} of a {unit}-sized "
                            f"group (unit provenance: {provenance})"),
                "equation": (f"{rational(a)} / {rational(unit)}",
                             rational(b)),
                "unit": str(unit),
                "unit_provenance": provenance,
            })

    m = re.match(r"arithmetic_equation\(\((.+?)\),\((.+?)\)\)", term)
    if m:
        left, right = m.group(1), m.group(2)
        dm = re.match(r"\s*(\d+)\s*/\s*(\d+)\s*$", left)
        rm = re.match(r"\s*(\d+)\s*$", right)
        if dm and rm:
            dividend, divisor = int(dm.group(1)), int(dm.group(2))
            claimed = int(rm.group(1))
            if divisor and dividend % divisor:
                out.append({
                    "reading": "holds_as_quotient_with_remainder",
                    "context": (f"{dividend} = {claimed} x {divisor} + "
                                f"{dividend - claimed * divisor}"),
                    "equation": (f"{dividend} // {divisor}", str(claimed)),
                    "remainder": dividend % divisor,
                })
    return out


_REREAD_ROW_STEMS = {
    "holds_under_referent_shift": ("referent", "unit whole", "dividend bar"),
    "holds_as_quotient_with_remainder": ("remainder", "left over"),
}


def chart_matches(reading: str, rows: list[dict[str, Any]]) -> list[str]:
    stems = _REREAD_ROW_STEMS.get(reading, ())
    return [str(row.get("citation", ""))
            for row in rows
            if any(stem in str(row.get("citation", "")).lower()
                   for stem in stems)]


def join_arm(arm: str, run_dir: Path, transcript_id: str,
             facts: dict[str, Any], radius: int) -> dict[str, Any]:
    extractions = json.loads(
        (run_dir / f"{transcript_id}_{arm}_extractions.json").read_text(
            encoding="utf-8"))
    report = json.loads(
        (run_dir / f"{transcript_id}_{arm}_report.json").read_text(
            encoding="utf-8"))["report"]
    lines, index = transcript_index(report["transcript"])
    rows = facts.get("resonant") or []

    refuted = [c for c in extractions if c.get("verdict") == "refuted"]
    all_candidates: list[tuple[int, dict[str, Any]]] = []
    for i, claim in enumerate(refuted):
        for candidate in candidate_rereads(claim, facts, lines, index,
                                           radius):
            all_candidates.append((i, candidate))
    verdicts = swipl_rational_check(
        [c["equation"] for _, c in all_candidates])

    entries = []
    for i, claim in enumerate(refuted):
        verified = [
            {key: value for key, value in candidate.items()
             if key != "equation"}
            | {"swipl_equation": f"{candidate['equation'][0]} =:= "
                                 f"{candidate['equation'][1]}",
               "chart_rows": chart_matches(candidate["reading"], rows)}
            for (j, candidate), ok in zip(all_candidates, verdicts)
            if j == i and ok
        ]
        entries.append({
            "id": claim.get("id"),
            "utterance_id": claim.get("utterance_id"),
            "surface": claim.get("surface"),
            "term": claim.get("term"),
            "as_stated": "refuted",
            "viability_rereads": verified,
            "standing": ("viable_in_context" if verified
                         else "stands_refuted"),
        })
    return {"arm": arm, "refuted_claims": len(refuted), "entries": entries}


def render_markdown(transcript_id: str, lesson: str,
                    results: list[dict[str, Any]]) -> str:
    body = [f"# {transcript_id}: monitoring join ({lesson})", "",
            "Each refuted claim, re-read against the lesson's viability "
            "contexts. Every re-read shown here was verified through "
            "swipl over exact rationals; chart-row matches are lexical "
            "and labeled as such. A claim with no verified re-read "
            "stands refuted — that standing is a finding, not a "
            "failure.", ""]
    for result in results:
        body.append(f"## {result['arm']} arm "
                    f"({result['refuted_claims']} refuted claims)")
        body.append("")
        for entry in result["entries"]:
            body.append(f"- `{entry['id']}` @ {entry['utterance_id']}: "
                        f"\"{entry['surface']}\" — {entry['standing']}")
            for reread in entry["viability_rereads"]:
                body.append(f"  - {reread['reading']}: {reread['context']} "
                            f"(swipl: {reread['swipl_equation']})")
                for citation in reread["chart_rows"]:
                    body.append(f"    - anticipated: {citation}")
        body.append("")
    return "\n".join(body) + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--run-dir", type=Path, required=True)
    parser.add_argument("--transcript", default="tm_0007")
    parser.add_argument("--lesson", required=True)
    parser.add_argument("--radius", type=int, default=8,
                        help="utterance radius for spoken referent units")
    args = parser.parse_args(argv)

    facts = json.loads(
        (args.run_dir / f"{args.lesson}_facts.json").read_text(
            encoding="utf-8"))
    results = []
    for arm in ("baseline", "lesson"):
        if (args.run_dir / f"{args.transcript}_{arm}_extractions.json"
                ).is_file():
            results.append(join_arm(arm, args.run_dir, args.transcript,
                                    facts, args.radius))
    payload = {"transcript_id": args.transcript, "lesson": args.lesson,
               "results": results, "model_calls": 0}
    (args.run_dir / f"{args.transcript}_monitoring_join.json").write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8")
    (args.run_dir / f"{args.transcript}_monitoring_join.md").write_text(
        render_markdown(args.transcript, args.lesson, results),
        encoding="utf-8")
    print(f"monitoring join written: {args.run_dir}/"
          f"{args.transcript}_monitoring_join.md")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
