#!/usr/bin/env python3
"""Check the relevance-negation data and its surviving-slices query."""
from __future__ import annotations

import json
import py_compile
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
BUILDER = ROOT / "scripts/research/build_relevance_negation.py"
NEGATION = ROOT / "knowledge/index/relevance_negation.pl"
FIELD_CACHE = ROOT / "curriculum/im/generated/field_context_cache.json"
LESSON_MONITORING = ROOT / "curriculum/im/lesson_monitoring.pl"

OPERATION_TOPIC_RE = re.compile(r"(?m)^operation_topic\((\w+), (\w+)\)\.")
KNOWN_TOPIC_RE = re.compile(r"(?m)^known_topic\(([^)]+)\)\.")
LESSON_GRADE_RE = re.compile(r"(?m)^lesson_grade\(([^,]+), (\d+)\)\.")
SOURCE_GAP_RE = re.compile(r"(?m)^source_gap\(cache_only_lesson, ([^)]+)\)\.")
EXCLUDES_RE = re.compile(r"(?m)^excludes\(")

# A topic may appear here only when the tree supports no machine subtraction.
# Keep the explanation with the exemption so a zero-subtraction topic cannot
# enter silently. There are no exemptions in the current generated layer.
ZERO_MACHINE_SUBTRACTION_EXEMPTIONS: dict[str, str] = {}


def _unquote_atom(raw: str) -> str:
    value = raw.strip()
    if len(value) >= 2 and value[0] == value[-1] == "'":
        return value[1:-1].replace("\\'", "'").replace("\\\\", "\\")
    return value


def _pl_atom(value: str) -> str:
    if re.fullmatch(r"[a-z][a-zA-Z0-9_]*", value):
        return value
    return "'" + value.replace("\\", "\\\\").replace("'", "\\'") + "'"


def _run_builder(output: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(BUILDER), "--output", str(output)],
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=300,
        check=False,
    )


def _prolog_query(goal: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [
            "swipl",
            "-q",
            "--on-warning=status",
            "--on-error=status",
            "-g",
            f"consult('{NEGATION.relative_to(ROOT)}'),{goal},halt.",
        ],
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=180,
        check=False,
    )


def _slice_counts(topic: str) -> tuple[int, int, int, int, int, int]:
    goal = (
        f"surviving_slices({_pl_atom(topic)},S,_),"
        "findall(K,member(slice(lesson,K),S),Ls),length(Ls,L),"
        "findall(K,slice(lesson,K),L0s),length(L0s,L0),"
        "findall(K,member(slice(standard,K),S),Ss),length(Ss,St),"
        "findall(K,slice(standard,K),S0s),length(S0s,St0),"
        "findall(K,member(slice(family,K),S),Ms),length(Ms,M),"
        "findall(K,slice(family,K),M0s),length(M0s,M0),"
        "format('~d\\t~d\\t~d\\t~d\\t~d\\t~d\\n',[L,L0,St,St0,M,M0])"
    )
    result = _prolog_query(goal)
    if result.returncode:
        raise RuntimeError(f"query for {topic} failed: {result.stderr.strip()}")
    return tuple(int(value) for value in result.stdout.strip().split("\t"))  # type: ignore[return-value]


def main() -> int:
    errors: list[str] = []
    for path in (BUILDER, NEGATION, FIELD_CACHE, LESSON_MONITORING):
        if not path.exists():
            errors.append(f"{path.relative_to(ROOT)} does not exist")
    if errors:
        for error in errors:
            print(f"FAIL: {error}", file=sys.stderr)
        return 1

    for path in (BUILDER, Path(__file__)):
        try:
            py_compile.compile(str(path), doraise=True)
        except py_compile.PyCompileError as exc:
            errors.append(f"{path.name} does not compile: {exc}")

    workdir = Path(tempfile.mkdtemp(prefix="relevance-negation-"))
    try:
        first = workdir / "first.pl"
        second = workdir / "second.pl"
        first_result = _run_builder(first)
        second_result = _run_builder(second)
        for label, result in (("first", first_result), ("second", second_result)):
            if result.returncode:
                errors.append(
                    f"{label} builder run failed with exit {result.returncode}: "
                    f"{result.stderr.strip()}"
                )
        if not errors:
            if first.read_bytes() != NEGATION.read_bytes():
                errors.append("generated output differs from relevance_negation.pl")
            if first.read_bytes() != second.read_bytes():
                errors.append("two builder runs differ")
    finally:
        shutil.rmtree(workdir, ignore_errors=True)

    reason_check = _prolog_query(
        "forall(excludes(T,K,S,R),exclusion_reason_resolves(T,K,S,R))"
    )
    if reason_check.returncode:
        errors.append(
            f"an exclusion reason does not resolve: "
            f"{reason_check.stdout.strip()} {reason_check.stderr.strip()}"
        )

    topics = sorted(
        {
            topic
            for _operation, topic in OPERATION_TOPIC_RE.findall(
                LESSON_MONITORING.read_text(encoding="utf-8")
            )
        }
    )
    empty_topics: list[str] = []
    for topic in topics:
        result = _prolog_query(
            f"surviving_slices({topic},S,_),"
            "findall(X,(member(X,S),X\\=slice(grade_band,_)),Content),"
            "Content\\=[]"
        )
        if result.returncode:
            empty_topics.append(topic)
    if empty_topics:
        errors.append(f"topics with no surviving content slices: {empty_topics}")

    generated = NEGATION.read_text(encoding="utf-8")
    known_topics = sorted(
        {_unquote_atom(raw) for raw in KNOWN_TOPIC_RE.findall(generated)}
    )
    unknown_exemptions = sorted(
        set(ZERO_MACHINE_SUBTRACTION_EXEMPTIONS) - set(known_topics)
    )
    if unknown_exemptions:
        errors.append(
            "zero-machine-subtraction exemptions are not known topics: "
            f"{unknown_exemptions}"
        )
    empty_explanations = sorted(
        topic
        for topic, reason in ZERO_MACHINE_SUBTRACTION_EXEMPTIONS.items()
        if not reason.strip()
    )
    if empty_explanations:
        errors.append(
            "zero-machine-subtraction exemptions lack reasons: "
            f"{empty_explanations}"
        )
    zero_machine_topics: list[str] = []
    for topic in known_topics:
        try:
            *_other, machines, all_machines = _slice_counts(topic)
        except RuntimeError as exc:
            errors.append(str(exc))
            continue
        if machines == all_machines:
            zero_machine_topics.append(topic)
    unexplained_zero_topics = sorted(
        set(zero_machine_topics) - set(ZERO_MACHINE_SUBTRACTION_EXEMPTIONS)
    )
    if unexplained_zero_topics:
        errors.append(
            "known topics subtract zero machines without an exemption: "
            f"{unexplained_zero_topics}"
        )

    owner = _prolog_query(
        "surviving_slices('fraction/thirds',S,E),"
        "findall(C,lesson_grade(C,0),K0),sort(K0,K),"
        "findall(C,(member(C,K),memberchk(excluded(lesson,C,_),E)),EK0),sort(EK0,EK),"
        "K=EK,"
        "findall(C,member(slice(lesson,C),S),SL),length(EK,ExcludedK),"
        "length(SL,Surviving),"
        "format('~d\\t~d\\n',[ExcludedK,Surviving])"
    )
    if owner.returncode:
        errors.append(
            "fraction/thirds does not exclude every kindergarten lesson: "
            f"{owner.stdout.strip()} {owner.stderr.strip()}"
        )

    lesson_rows = {
        raw_code.strip("'"): int(grade)
        for raw_code, grade in LESSON_GRADE_RE.findall(generated)
    }
    cache_codes = set(
        json.loads(FIELD_CACHE.read_text(encoding="utf-8"))["field_contexts"]
    )
    expected_gaps = cache_codes - set(lesson_rows)
    recorded_gaps = {raw.strip("'") for raw in SOURCE_GAP_RE.findall(generated)}
    if recorded_gaps != expected_gaps:
        errors.append("cache-only lesson gap rows do not match the live lesson boundary")

    measurements: dict[str, tuple[int, int, int, int, int, int]] = {}
    for topic in ("fraction", "geometry", "algebraic", "probability"):
        try:
            measurements[topic] = _slice_counts(topic)
        except RuntimeError as exc:
            errors.append(str(exc))

    if errors:
        print(f"FAIL relevance negation: {len(errors)} problem(s)", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    excluded_k, owner_surviving = (
        int(value) for value in owner.stdout.strip().split("\t")
    )
    print("PASS regeneration is byte-identical twice")
    print(
        f"PASS every one of {len(EXCLUDES_RE.findall(generated))} exclusion reasons "
        "resolves against generated source evidence"
    )
    print(
        f"PASS every operation topic leaves content slices: {len(topics)} topics"
    )
    print(
        f"PASS every known topic subtracts machines or has a reasoned exemption: "
        f"{len(known_topics)} topics; "
        f"{len(ZERO_MACHINE_SUBTRACTION_EXEMPTIONS)} exemptions"
    )
    print(
        f"PASS owner case fraction/thirds: {excluded_k} kindergarten lessons excluded; "
        f"{owner_surviving} lessons survive"
    )
    for topic, counts in measurements.items():
        lessons, all_lessons, standards, all_standards, machines, all_machines = counts
        print(
            f"PASS subtraction {topic}: lessons {lessons}/{all_lessons}; "
            f"standards {standards}/{all_standards}; machines {machines}/{all_machines}"
        )
    print(
        f"PASS source boundary recorded: {len(lesson_rows)} live lesson rows; "
        f"{len(cache_codes)} cache rows; {len(recorded_gaps)} cache-only gaps"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
