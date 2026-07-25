#!/usr/bin/env python3
"""Recompute every lesson-topic list and compare it with the fact cache."""

from __future__ import annotations

import json
import subprocess
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
COVERAGE_PATH = ROOT / "curriculum/im/coverage/im_coverage.json"
EXPECTED_LESSONS = 1317
PROLOG_GOAL = """
use_module(library(http/json)),
use_module(im_lessons(lesson_monitoring)),
json_read_dict(user_input, Request),
get_dict(lessons, Request, LessonStrings),
findall(
    _{lesson:CodeString, cached_entries:CachedEntries, computed:Computed},
    (
        member(CodeString, LessonStrings),
        atom_string(Code, CodeString),
        findall(Cached, lesson_monitoring:lesson_topics_cached(Code, Cached), CachedEntries),
        lesson_monitoring:compute_lesson_topics(Code, Computed)
    ),
    Rows
),
findall(
    CacheCodeString,
    (
        lesson_monitoring:lesson_topics_cached(CacheCode, _),
        atom_string(CacheCode, CacheCodeString)
    ),
    CacheCodes
),
json_write_dict(user_output, _{rows:Rows, cache_codes:CacheCodes}, [width(0)]),
nl,
halt
""".replace("\n", " ")


def fail(message: str) -> "NoReturn":
    raise SystemExit(f"lesson_topics_cache.py: {message}")


def coverage_codes() -> list[str]:
    try:
        coverage = json.loads(COVERAGE_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"cannot read {COVERAGE_PATH}: {exc}")
    published = [row.get("lesson") for row in coverage.get("published_lessons", [])]
    codes = published + coverage.get("encoded_but_unpublished", [])
    if not all(isinstance(code, str) and code for code in codes):
        fail("coverage contains a missing or non-string lesson code")
    if len(codes) != len(set(codes)):
        fail("coverage contains duplicate lesson codes")
    if len(codes) != EXPECTED_LESSONS:
        fail(f"expected {EXPECTED_LESSONS} lesson codes, found {len(codes)}")
    return sorted(codes)


def prolog_rows(codes: list[str]) -> dict[str, Any]:
    command = [
        "swipl",
        "-q",
        "--on-warning=status",
        "--on-error=status",
        "-l",
        "paths.pl",
        "-g",
        PROLOG_GOAL,
    ]
    try:
        completed = subprocess.run(
            command,
            cwd=ROOT,
            input=json.dumps({"lessons": codes}),
            text=True,
            capture_output=True,
            check=False,
        )
    except FileNotFoundError:
        fail("swipl is required to check the lesson-topic cache")
    if completed.returncode != 0:
        detail = completed.stderr.strip() or f"swipl exited {completed.returncode}"
        fail(detail)
    try:
        return json.loads(completed.stdout)
    except json.JSONDecodeError as exc:
        fail(f"swipl returned invalid JSON: {exc}")


def grade_of(code: str) -> str:
    return code.split("-", 2)[1].removeprefix("G")


def main() -> int:
    codes = coverage_codes()
    result = prolog_rows(codes)
    rows = result.get("rows")
    cache_codes = result.get("cache_codes")
    if not isinstance(rows, list) or len(rows) != len(codes):
        fail("recomputation did not return one row per coverage lesson")
    if cache_codes != codes:
        fail("cache lesson codes differ from sorted coverage lesson codes")

    differences: list[str] = []
    for row in rows:
        code = row.get("lesson")
        cached_entries = row.get("cached_entries")
        computed = row.get("computed")
        if not isinstance(code, str) or not isinstance(cached_entries, list):
            fail("recomputation returned a malformed row")
        if len(cached_entries) != 1:
            differences.append(
                f"{code}: expected one cached list, found {len(cached_entries)}"
            )
        elif cached_entries[0] != computed:
            differences.append(
                f"{code}: cached={cached_entries[0]!r} computed={computed!r}"
            )
    if differences:
        fail("cache differences:\n  " + "\n  ".join(differences))

    grades = {grade_of(code) for code in codes}
    if grades != {"K", "1", "2", "3", "4", "5", "6", "7", "8"}:
        fail(f"coverage grades differ from K through 8: {sorted(grades)}")
    print(
        f"PASS lesson-topic cache: {len(codes)} entries; "
        f"recomputed {len(rows)} across grades K through 8"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
