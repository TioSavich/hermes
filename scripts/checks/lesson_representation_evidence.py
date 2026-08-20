#!/usr/bin/env python3
"""Verify generated lesson representation evidence and its source citations."""
from __future__ import annotations

import json
import subprocess
import sys
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
STORE = ROOT / "curriculum/im/generated/lesson_representation_evidence.pl"
VISION = ROOT / "curriculum/im/generated/vision_lesson_digest.pl"
CIRCLE_GUARD = {"IM-G3-U5-L16", "IM-G4-U2-L12", "IM-G4-U2-L13"}
# IM-G5-U3-L19 ("Fraction Games") keeps zero representation evidence: its
# Student Task Statement is a blank digit-fill template, not a printed
# fraction. The other five lessons this set once held were fractionless
# only because the PDF-to-Markdown conversion destroyed their glyphs; a
# 2026-08-20 vision recovery restored them (see
# build_lesson_representation_evidence.py's add_vision_recovery_fractions),
# so they now carry real fraction rows and belong in FIXTURES below instead.
FRACTIONLESS = {
    "IM-G5-U3-L19",
}


def fail(message: str) -> None:
    print(f"FAIL lesson representation evidence: {message}", file=sys.stderr)
    raise SystemExit(1)


def store_rows() -> list[dict[str, object]]:
    goal = r'''use_module(library(http/json)),use_module('curriculum/im/generated/lesson_representation_evidence.pl'),forall((lesson_host_evidence(Code,Host,source(Path,Locator),excerpt(Excerpt)),(Locator=line(N)->Kind=line,Value=N;Locator=page(Range),Kind=page,Value=Range)),(json_write_dict(current_output,_{row:host,code:Code,host:Host,path:Path,locator_kind:Kind,locator:Value,excerpt:Excerpt},[width(0)]),nl)),forall((lesson_fraction_evidence(Code,frac(M,N),source(Path,Locator),excerpt(Excerpt),form(Form)),(Locator=line(Line)->Kind=line,Value=Line;Locator=page(Range),Kind=page,Value=Range)),(json_write_dict(current_output,_{row:fraction,code:Code,numerator:M,denominator:N,path:Path,locator_kind:Kind,locator:Value,excerpt:Excerpt,form:Form},[width(0)]),nl)),lesson_representation_evidence_summary(Summary),json_write_dict(current_output,_{row:summary,summary:Summary},[width(0)]),nl,halt'''
    completed = subprocess.run(
        ["swipl", "-q", "-l", "paths.pl", "-g", goal], cwd=ROOT,
        text=True, capture_output=True, check=False, timeout=60,
    )
    if completed.returncode:
        fail(completed.stderr.strip() or f"SWI-Prolog exited {completed.returncode}")
    try:
        return [json.loads(line) for line in completed.stdout.splitlines() if line]
    except json.JSONDecodeError as exc:
        fail(f"store query did not return JSONL: {exc}")


def verify_line(row: dict[str, object]) -> None:
    path = ROOT / str(row["path"])
    if not path.is_file():
        fail(f"{row['code']} cites missing source {row['path']}")
    lines = path.read_text(encoding="utf-8").splitlines()
    line_number = int(row["locator"])
    excerpt = str(row["excerpt"])
    nearby = lines[max(0, line_number - 3) : min(len(lines), line_number + 2)]
    if not any(excerpt in line for line in nearby):
        fail(f"{row['code']} excerpt is absent within two lines of {row['path']}:{line_number}")


def verify_page(row: dict[str, object], vision_text: str) -> None:
    if row["row"] != "fraction" or row.get("form") != "computation":
        fail(f"{row['code']} uses page provenance outside a computation row")
    code = str(row["code"])
    page = str(row["locator"])
    excerpt = str(row["excerpt"])
    expression, separator, answer = excerpt.partition(" = ")
    if not separator:
        fail(f"{code} computation excerpt has no result separator")
    needle = f"vision_lesson_computation('{code}', \"{expression}\", \"{answer}\","
    if needle not in vision_text or f'\"{page}\"' not in vision_text[vision_text.index(needle) : vision_text.index(needle) + 250]:
        fail(f"{code} page {page} computation is absent from vision_lesson_digest.pl")


def main() -> int:
    rows = store_rows()
    summaries = [row["summary"] for row in rows if row["row"] == "summary"]
    if len(summaries) != 1:
        fail(f"expected one summary row, found {len(summaries)}")
    evidence = [row for row in rows if row["row"] != "summary"]
    vision_text = VISION.read_text(encoding="utf-8")
    for row in evidence:
        if row["locator_kind"] == "line":
            verify_line(row)
        elif row["locator_kind"] == "page":
            verify_page(row, vision_text)
        else:
            fail(f"{row['code']} has unsupported locator {row['locator_kind']}")

    hosts: dict[str, set[str]] = defaultdict(set)
    fractions: dict[str, set[tuple[int, int]]] = defaultdict(set)
    for row in evidence:
        code = str(row["code"])
        if row["row"] == "host":
            hosts[code].add(str(row["host"]))
        else:
            fractions[code].add((int(row["numerator"]), int(row["denominator"])))

    codes = hosts.keys() | fractions.keys() | {"IM-G5-U3-L19"}
    measured = {
        "lessons": 74,
        "host_rows": sum(map(len, hosts.values())),
        "fraction_rows": sum(map(len, fractions.values())),
        "both": sum(bool(hosts[code]) and bool(fractions[code]) for code in codes),
        "hosts_only": sum(bool(hosts[code]) and not fractions[code] for code in codes),
        "fractions_only": sum(not hosts[code] and bool(fractions[code]) for code in codes),
        "neither": sum(not hosts[code] and not fractions[code] for code in codes),
    }
    if summaries[0] != measured:
        fail(f"summary {summaries[0]} does not match computed {measured}")
    if (measured["both"], measured["hosts_only"], measured["fractions_only"], measured["neither"]) != (73, 0, 0, 1):
        fail(f"lesson classes changed: {measured}")
    for code in CIRCLE_GUARD:
        if "circle" in hosts[code]:
            fail(f"{code} admitted imperative circle as a host")
    for code in FRACTIONLESS:
        if fractions[code]:
            fail(f"{code} unexpectedly has fraction operands")
    if hosts["IM-G5-U3-L19"] or fractions["IM-G5-U3-L19"]:
        fail("IM-G5-U3-L19 must have no evidence rows")

    fixtures = {
        "IM-G3-U5-L5": ({"number_line"}, {(1, 2), (1, 3), (1, 4), (1, 6), (1, 8)}),
        "IM-G4-U3-L3": ({"set"}, {(1, 8)}),
        "IM-G5-U2-L2": ({"rectangle"}, {(1, 2)}),
        "IM-G6-U4-L6": ({"bar", "rectangle"}, {(5, 2), (2, 3), (3, 4)}),
        # 2026-08-20 vision recovery (fraction glyphs the PDF-to-Markdown
        # conversion destroyed, read back off the source PDF pages and
        # anchored to a surviving Markdown line each):
        "IM-G4-U2-L14": ({"number_line", "set"}, {(1, 2), (3, 4), (7, 12), (4, 6)}),
        "IM-G5-U2-L3": ({"bar", "number_line", "rectangle", "set"}, {(3, 2)}),
        "IM-G5-U3-L5": ({"rectangle"}, {(1, 3), (2, 5), (1, 15)}),
        "IM-G5-U3-L6": ({"rectangle"}, {(1, 30), (8, 30)}),
        "IM-G5-U3-L13": ({"bar", "rectangle"}, {(1, 6)}),
    }
    for code, (expected_hosts, expected_fractions) in fixtures.items():
        if not expected_hosts <= hosts[code] or not expected_fractions <= fractions[code]:
            fail(f"{code} does not satisfy its census fixture")

    print(
        "PASS lesson representation evidence: "
        f"{measured['both']} both, {measured['hosts_only']} hosts-only, "
        f"{measured['neither']} neither; {len(evidence)} citations verified"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
