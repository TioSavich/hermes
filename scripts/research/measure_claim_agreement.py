#!/usr/bin/env python3
"""Measure the claim pipeline against a witness it did not produce.

Every reader in this repo can be checked against its own source, and that is
exactly what lets a bad reading survive: the reader and the check agree because
they are the same reading twice. `4 x 5 = 20` parses one way, `4 × 5 = 20`
parses to `arithmetic_equation(5, 20)` and is adjudicated `refuted` with a
confident trace, and nothing internal to the pipeline can tell that a true claim
was just called false.

The teacher guides supply a witness from outside. A lesson that asks students to
decide whether statements are true prints its own answers, usually bulleted in
item order with the ground attached, sometimes numbered:

    • True: 4 + 6 is the same amount as 10.
    • False: 9 is the same amount as 9, and 9 is less than 10.

Measured over the 84 true/false lessons: 68 carry the bulleted form, 8 the
numbered one, 76 either. Order is a weaker key than a number, so a bulleted
lesson is aligned only when the counts match exactly on both sides.

Those verdicts were authored by the curriculum. No reader here produced them, so
agreement between them and the grounded checker is evidence, and disagreement is
a quarantine signal rather than a puzzle to resolve by preferring one side.

This script measures the agreement rate. It is an instrument, not a gate: it
asserts nothing about which side is right when they differ, and it writes no
claim into any register.

    python3 scripts/research/measure_claim_agreement.py
    python3 scripts/research/measure_claim_agreement.py --report out.json
"""
from __future__ import annotations

import argparse
import json
import pathlib
import re
import subprocess
import sys
from collections import Counter

ROOT = pathlib.Path(__file__).resolve().parents[2]
GUIDES = ROOT / "curriculum" / "im_teacher_guides"

# "Student Response 1. True 2. False" and its bolded variants. The number is the
# item it answers; alignment is by that number and nothing else.
NUMBERED_VERDICT = re.compile(r"(\d+)\s*[.):]\s*\**\s*(True|False)\b", re.I)
# The commoner shape by far. The guides answer in item order with the ground
# attached: "• True: 4 + 6 is the same amount as 10." Measured over the 84
# true/false lessons: 8 carry the numbered form, 68 carry this one, 76 carry
# either. An earlier count of 713 bare True/False tokens across 80 lessons was
# counting prose, not verdicts, and the difference matters — a witness is only a
# witness in a shape that can be aligned.
BULLET_VERDICT = re.compile(r"[•*]\s*\**\s*(True|False)\b\s*[:.]", re.I)


def printed_verdicts(text: str) -> tuple[dict[int, str], str]:
    """The guide's own answers, keyed by position, with the shape they came in.

    Numbered verdicts key on their own number. Bulleted verdicts key on their
    order of appearance, which is the item order the guide answers in. Order is
    a weaker key than a number and the caller must treat it as such: it is only
    used when the counts on both sides match exactly.
    """
    numbered: dict[int, str] = {}
    for number, verdict in NUMBERED_VERDICT.findall(text):
        index = int(number)
        token = verdict.lower()
        if index in numbered and numbered[index] != token:
            # The same item answered twice, differently. Refuse the lesson
            # rather than pick one.
            return {}, "conflicting"
        numbered[index] = token
    if numbered:
        return numbered, "numbered"
    bulleted = [v.lower() for v in BULLET_VERDICT.findall(text)]
    if bulleted:
        return {i: v for i, v in enumerate(bulleted, start=1)}, "bulleted"
    return {}, "absent"


def checker_verdicts(lesson_texts: list[tuple[str, str]]) -> dict[str, list[dict]]:
    """Run the repo's own reader and checker over each span, via swipl.

    Shelling out keeps the one loader rule: this measures the same predicates
    the worker serves, not a Python re-implementation of them.
    """
    # The lesson texts go into the probe file as facts, never onto the command
    # line: 76 guides overflow the argv limit.
    def pl_string(value: str) -> str:
        return '"' + value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'

    facts = "\n".join(
        f"probe_span({pl_string(key)}, {pl_string(text)})." for key, text in lesson_texts)
    script = (
        ':- use_module(hermes(math_claim_language), [math_claims_in_text/2]).\n'
        ':- use_module(hermes(math_claim_checker), [check_math_claim/2]).\n'
        ':- dynamic probe_span/2.\n'
        + facts + "\n"
        + "probe_all :- forall(probe_span(K, T),\n"
          "    ( ( math_claim_language:math_claims_in_text(T, Cs) -> true ; Cs = [] ),\n"
          "      forall(member(C, Cs),\n"
          "        ( catch(math_claim_checker:check_math_claim(C, V), _, V = error),\n"
          "          ( is_dict(V) -> get_dict(verdict, V, Vd) ; Vd = error ),\n"
          '          format("ROW\\t~w\\t~q\\t~w~n", [K, C, Vd]) )) )).\n'
    )
    goal = "probe_all, halt."
    tmp = ROOT / "scripts" / "research" / "_claim_agreement_probe.pl"
    tmp.write_text(script, encoding="utf-8")
    try:
        done = subprocess.run(
            ["swipl", "-q", "-l", "paths.pl", "-s", str(tmp), "-g", goal],
            cwd=ROOT, capture_output=True, text=True, timeout=900)
    finally:
        tmp.unlink(missing_ok=True)
    rows: dict[str, list[dict]] = {}
    for line in done.stdout.splitlines():
        if not line.startswith("ROW\t"):
            continue
        _, key, claim, verdict = line.split("\t", 3)
        rows.setdefault(key, []).append({"claim": claim, "verdict": verdict})
    return rows


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=pathlib.Path)
    parser.add_argument("--limit", type=int)
    arguments = parser.parse_args()

    lessons = []
    for path in sorted(GUIDES.rglob("lesson*.md")):
        text = path.read_text(encoding="utf-8", errors="replace")
        if not re.search(r"true or false", text, re.I):
            continue
        verdicts, shape = printed_verdicts(text)
        if not verdicts:
            continue
        lessons.append((str(path.relative_to(ROOT)), text, verdicts, shape))
    if arguments.limit:
        lessons = lessons[: arguments.limit]

    status = Counter()
    detail = []
    probe = [(str(index), text) for index, (_p, text, _v, _s) in enumerate(lessons)]
    produced = checker_verdicts(probe)

    for index, (path, _text, verdicts, shape) in enumerate(lessons):
        status[f"shape_{shape}"] += 1
        claims = produced.get(str(index), [])
        status["lessons"] += 1
        status["printed_verdicts"] += len(verdicts)
        status["claims_read"] += len(claims)
        if not claims:
            status["lessons_reader_silent"] += 1
            detail.append({"guide": path, "outcome": "reader_silent",
                           "printed": len(verdicts)})
            continue
        # Alignment is only honest when the counts match. Anything else is
        # reported as unalignable rather than forced into a pairing.
        if len(claims) != len(verdicts):
            status["lessons_count_mismatch"] += 1
            detail.append({"guide": path, "outcome": "count_mismatch",
                           "printed": len(verdicts), "read": len(claims)})
            continue
        agree = 0
        rows = []
        for position, item in enumerate(sorted(verdicts), start=1):
            printed = verdicts[item]
            read = claims[position - 1]["verdict"]
            mapped = {"holds": "true", "refuted": "false"}.get(read, read)
            same = mapped == printed
            agree += same
            rows.append({"item": item, "printed": printed,
                         "checker": read, "claim": claims[position - 1]["claim"],
                         "agree": same})
        status["aligned_lessons"] += 1
        status["aligned_items"] += len(rows)
        status["agreements"] += agree
        status["disagreements"] += len(rows) - agree
        detail.append({"guide": path, "outcome": "aligned", "shape": shape,
                       "agree": agree, "of": len(rows), "rows": rows})

    print("claim agreement against the guides' printed verdicts")
    for key in ("lessons", "shape_numbered", "shape_bulleted",
                "printed_verdicts", "claims_read",
                "lessons_reader_silent", "lessons_count_mismatch",
                "aligned_lessons", "aligned_items", "agreements", "disagreements"):
        print(f"  {key}={status.get(key, 0)}")
    aligned = status.get("aligned_items", 0)
    if aligned:
        rate = status.get("agreements", 0) / aligned
        print(f"  agreement_rate={rate:.3f} over {aligned} aligned items")
    else:
        print("  agreement_rate=unmeasurable; no lesson aligned")
    print("  NOTE: alignment requires equal counts on both sides, so the rate is"
          " measured on the subset the reader could read at all.")

    if arguments.report:
        arguments.report.write_text(
            json.dumps({"counts": dict(status), "lessons": detail}, indent=2) + "\n",
            encoding="utf-8")
        print(f"wrote {arguments.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
