#!/usr/bin/env python3
"""Build the receipt-backed CCSS standard-to-doing narrowing store.

The CCSS code narrows the admissible wave-5 family and contract genre.  It
does not select a machine or compute a result.  A generated row is admitted
only when it has a correct execution witness.  Its support count includes all
routed executions, including honest magnitude refusals and execution limits.

Two machine maps feed the store.  The pool map carries the arithmetic families
(`add`, `divide`, ...) for grades K-7.  Grade 8 records its runs in a sibling
map whose `family` field is `curriculum_task` for every row -- a position in a
guide rather than a doing -- so the grade 8 family is read from the row's
`cluster` instead, which groups machines by the doing they perform.  Three of
the fourteen clusters hold a single machine, so for those the code does reach
one machine; that is a property of the curriculum, not a narrowing this
builder performs.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

from fixture_task_rows import load_fixture_rows


ROOT = Path(__file__).resolve().parents[2]
PUSU_RESULTS = ROOT / "hermes/app/runtime/experiments/language/pusu_results.jsonl"
WAVE5_ROWS = ROOT / "curriculum/im/generated/wave5_row_machine_map.jsonl"
WAVE5_G8_ROWS = ROOT / "curriculum/im/generated/wave5_g8_row_machine_map.jsonl"
CONTRACTS = ROOT / "knowledge/strategies/automaton_input_contracts.pl"
EXPLICIT_STANDARDS = ROOT / "curriculum/im/generated/lesson_standard_anchors.pl"
VISION_DIGEST = ROOT / "curriculum/im/generated/vision_lesson_digest.pl"
IM_STANDARDS = ROOT / "knowledge/standards/im"
DEFAULT_OUTPUT = ROOT / "knowledge/standards/standard_doing.pl"
DEFAULT_COVERAGE = (
    ROOT / ".superpowers/sdd/language-lane/slice1-standard-coverage.json"
)

EXPECTED_STATEMENTS = 4712
EXPECTED_COVERAGE_BEFORE = 4142
EXPECTED_COVERAGE_AFTER = 4485
# 2026-08-15: the grade 8 sibling map joins the pool map as a second source.
# Full rows 357 -> 432, admitted rows 259 -> 289; measured from this builder,
# not copied.
EXPECTED_FULL_ROWS = 432
EXPECTED_THRESHOLD3_ROWS = 289

STANDARD_RE = re.compile(
    r'^\s*standard_anchor\(\s*([A-Za-z0-9_]+)\s*,\s*ccss\s*,\s*"([^"]+)"',
    re.MULTILINE,
)
IM_ANCHOR_RE = re.compile(
    r'^\s*standard_anchor\(\s*([A-Za-z0-9_]+)\s*,\s*im_lesson\s*,\s*"([^"]+)"',
    re.MULTILINE,
)
EXPLICIT_RE = re.compile(
    r"^\s*lesson_monitoring:explicit_lesson_standard\(\s*'([^']+)'\s*,"
    r"\s*ccss\s*,\s*'([^']+)'",
    re.MULTILINE,
)
VISION_ADDRESSING_RE = re.compile(
    r"^\s*vision_lesson_standard\(\s*'([^']+)'\s*,\s*addressing\s*,"
    r"\s*'([^']+)'",
    re.MULTILINE,
)
LESSON_RE = re.compile(r"^IM-G(K|[0-8])-U(\d+)-L(\d+)$")
CONTRACT_RE = re.compile(
    r"^automaton_input_contract\(\s*([a-z0-9_]+)\s*,\s*([a-z0-9_]+)\s*,",
    re.MULTILINE,
)


@dataclass(frozen=True)
class StoreRow:
    code: str
    family: str
    genre: str
    receipts: int
    lessons: int
    share: float
    row_id: str
    machine: str
    input_json: str
    result_term: str


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line]


def standard_sources() -> list[Path]:
    return [
        IM_STANDARDS / "standards_im.pl",
        *(IM_STANDARDS / f"grade_{grade}.pl" for grade in range(5, 9)),
        IM_STANDARDS / "lesson_anchors.pl",
    ]


def base_lesson_codes(lessons: set[str] | None = None) -> dict[str, set[str]]:
    """Reproduce the design's standards/im + generated-explicit baseline."""
    concept_codes: dict[str, set[str]] = defaultdict(set)
    unit_concepts: dict[str, str] = {}
    for path in standard_sources():
        source = path.read_text(encoding="utf-8")
        for concept, code in STANDARD_RE.findall(source):
            concept_codes[concept].add(code)
        for concept, lesson_or_unit in IM_ANCHOR_RE.findall(source):
            unit_concepts.setdefault(lesson_or_unit, concept)

    explicit: dict[str, set[str]] = defaultdict(set)
    for lesson, code in EXPLICIT_RE.findall(
        EXPLICIT_STANDARDS.read_text(encoding="utf-8")
    ):
        explicit[lesson].add(code)

    if lessons is None:
        lessons = {row["lesson"] for row in read_jsonl(PUSU_RESULTS)}
    result: dict[str, set[str]] = defaultdict(set)
    for lesson in lessons:
        if lesson in explicit:
            result[lesson].update(explicit[lesson])
            continue
        match = LESSON_RE.fullmatch(lesson)
        if match is None:
            continue
        grade, unit, lesson_number = match.groups()
        if grade == "K" or int(grade) <= 5:
            grade_name = "kindergarten" if grade == "K" else f"grade{grade}"
            concept = f"im_{grade_name}_u{unit}_l{lesson_number}"
        else:
            concept = unit_concepts.get(f"IM-G{grade}-U{unit}", "")
        result[lesson].update(concept_codes.get(concept, set()))
    return result


def addressing_codes() -> dict[str, set[str]]:
    result: dict[str, set[str]] = defaultdict(set)
    for lesson, code in VISION_ADDRESSING_RE.findall(
        VISION_DIGEST.read_text(encoding="utf-8")
    ):
        result[lesson].add(code)
    return result


def joined_lesson_codes(
    lessons: set[str] | None = None,
) -> tuple[dict[str, set[str]], dict[str, set[str]]]:
    before = base_lesson_codes(lessons)
    after = defaultdict(set, {lesson: set(codes) for lesson, codes in before.items()})
    for lesson, codes in addressing_codes().items():
        after[lesson].update(codes)
    return before, after


def grade_for_lesson(lesson: str) -> str:
    match = LESSON_RE.fullmatch(lesson)
    if match is None:
        raise ValueError(f"unexpected lesson id: {lesson}")
    return match.group(1)


def coverage_summary(
    statements: list[dict[str, Any]], lesson_codes: dict[str, set[str]]
) -> dict[str, Any]:
    uncovered = Counter(
        grade_for_lesson(row["lesson"])
        for row in statements
        if not lesson_codes[row["lesson"]]
    )
    covered = len(statements) - sum(uncovered.values())
    return {
        "statements_with_code": covered,
        "total_statements": len(statements),
        "share": round(covered / len(statements), 3),
        "uncovered_by_grade": {
            grade: uncovered.get(grade, 0)
            for grade in ("K", "1", "2", "3", "4", "5", "6", "7", "8")
            if uncovered.get(grade, 0)
        },
    }


def coverage_receipt() -> tuple[bytes, dict[str, set[str]]]:
    statements = read_jsonl(PUSU_RESULTS)
    before_codes, after_codes = joined_lesson_codes()
    before = coverage_summary(statements, before_codes)
    after = coverage_summary(statements, after_codes)
    if len(statements) != EXPECTED_STATEMENTS:
        raise RuntimeError(
            f"coverage corpus moved: {len(statements)} != {EXPECTED_STATEMENTS}"
        )
    if before["statements_with_code"] != EXPECTED_COVERAGE_BEFORE:
        raise RuntimeError(f"baseline coverage moved: {before}")
    if after["statements_with_code"] != EXPECTED_COVERAGE_AFTER:
        raise RuntimeError(f"addressing coverage moved: {after}")
    receipt = {
        "method": (
            "one row per pusu_results.jsonl statement; standards/im plus generated "
            "explicit lesson anchors, then union vision_lesson_standard addressing only"
        ),
        "before": before,
        "after": after,
        "delta_statements_with_code": (
            after["statements_with_code"] - before["statements_with_code"]
        ),
        "excluded_vision_relations": ["building_on", "building_toward"],
        "sources": [
            "hermes/app/runtime/experiments/language/pusu_results.jsonl",
            "knowledge/standards/im/standards_im.pl",
            "knowledge/standards/im/grade_5.pl",
            "knowledge/standards/im/grade_6.pl",
            "knowledge/standards/im/grade_7.pl",
            "knowledge/standards/im/grade_8.pl",
            "knowledge/standards/im/lesson_anchors.pl",
            "curriculum/im/generated/lesson_standard_anchors.pl",
            "curriculum/im/generated/vision_lesson_digest.pl",
        ],
    }
    return (json.dumps(receipt, indent=2, sort_keys=True) + "\n").encode(), after_codes


def focused_coverage_receipt() -> tuple[dict[str, Any], dict[str, set[str]]]:
    """Exercise the coverage join on the tracked focused fixture."""
    statements = load_fixture_rows()
    lessons = {str(row["lesson"]) for row in statements}
    _before_codes, after_codes = joined_lesson_codes(lessons)
    summary = coverage_summary(statements, after_codes)
    if summary["total_statements"] != len(statements):
        raise RuntimeError("focused standard coverage denominator drifted")
    return summary, after_codes


def contract_genre(input_value: dict[str, Any]) -> str:
    if "kind" in input_value:
        return str(input_value["kind"])
    return "|".join(sorted(input_value))


def routed(row: dict[str, Any]) -> bool:
    return row.get("route") != "unmappable"


def correct(row: dict[str, Any]) -> bool:
    return row.get("execution", {}).get("outcome") == "correct"


def doing_family(row: dict[str, Any]) -> str:
    """The row's operation-facing family.

    Every grade 8 row files `curriculum_task` -- a guide position, not a doing
    -- so its cluster carries the family instead.  The pool map's own family
    field is already operation-facing and is read unchanged.
    """
    if row.get("cluster"):
        return str(row["cluster"])
    return str(row["family"])


def row_key(row: dict[str, Any], code: str) -> tuple[str, str, str]:
    return code, doing_family(row), contract_genre(row["input"])


def cluster_contract_families() -> dict[str, str]:
    """Map each grade 8 cluster to its machines' contract family.
    The sibling map names the machines; the contract store names their family.
    A cluster whose machines disagree is an error rather than a choice here.
    """
    contract_family = {
        machine: family
        for family, machine in CONTRACT_RE.findall(
            CONTRACTS.read_text(encoding="utf-8")
        )
    }
    by_cluster: dict[str, set[str]] = defaultdict(set)
    for row in read_jsonl(WAVE5_G8_ROWS):
        machine = row.get("machine")
        if not machine:
            continue
        if machine not in contract_family:
            raise RuntimeError(f"grade 8 machine files no contract: {machine}")
        by_cluster[doing_family(row)].add(contract_family[machine])
    resolved: dict[str, str] = {}
    for cluster, families in sorted(by_cluster.items()):
        if len(families) != 1:
            raise RuntimeError(
                f"cluster spans several contract families: {cluster} {sorted(families)}"
            )
        resolved[cluster] = families.pop()
    return resolved


def build_rows(
    lesson_codes: dict[str, set[str]] | None, threshold: int
) -> tuple[list[StoreRow], dict[str, Any]]:
    wave_rows = read_jsonl(WAVE5_ROWS) + read_jsonl(WAVE5_G8_ROWS)
    if lesson_codes is None:
        _before_codes, lesson_codes = joined_lesson_codes(
            {row["lesson"] for row in wave_rows}
        )
    support: Counter[tuple[str, str, str]] = Counter()
    support_lessons: dict[tuple[str, str, str], set[str]] = defaultdict(set)
    witnesses: dict[tuple[str, str, str], dict[str, Any]] = {}

    for row in wave_rows:
        if not routed(row):
            continue
        for code in sorted(lesson_codes[row["lesson"]]):
            key = row_key(row, code)
            support[key] += 1
            support_lessons[key].add(row["lesson"])
            if correct(row):
                witnesses.setdefault(key, row)

    full_keys = sorted(witnesses)
    admitted_keys = [key for key in full_keys if support[key] >= threshold]
    if len(full_keys) != EXPECTED_FULL_ROWS:
        raise RuntimeError(f"full receipt rows moved: {len(full_keys)} != {EXPECTED_FULL_ROWS}")
    if threshold == 3 and len(admitted_keys) != EXPECTED_THRESHOLD3_ROWS:
        raise RuntimeError(
            f"support>=3 rows moved: {len(admitted_keys)} != {EXPECTED_THRESHOLD3_ROWS}"
        )

    totals_by_code: Counter[str] = Counter()
    for (code, _family, _genre), receipts in support.items():
        totals_by_code[code] += receipts

    rows: list[StoreRow] = []
    for key in admitted_keys:
        code, family, genre = key
        witness = witnesses[key]
        receipts = support[key]
        rows.append(
            StoreRow(
                code=code,
                family=family,
                genre=genre,
                receipts=receipts,
                lessons=len(support_lessons[key]),
                share=receipts / totals_by_code[code],
                row_id=witness["id"],
                machine=witness["machine"],
                input_json=json.dumps(
                    witness["input"], sort_keys=True, separators=(",", ":")
                ),
                result_term=witness["execution"]["result_term"],
            )
        )
    summary = {
        "threshold": threshold,
        "rows": len(rows),
        "codes": len({row.code for row in rows}),
        "full_rows": len(full_keys),
        "full_codes": len({key[0] for key in full_keys}),
        "routed_source_rows": sum(routed(row) for row in wave_rows),
        "correct_source_rows": sum(correct(row) for row in wave_rows),
        "support_outcomes": dict(
            sorted(
                Counter(
                    row["execution"]["outcome"] for row in wave_rows if routed(row)
                ).items()
            )
        ),
        "grade8_rows": sum(1 for row in rows if row.code.startswith("8.")),
        "grade8_codes": len(
            {row.code for row in rows if row.code.startswith("8.")}
        ),
    }
    return rows, summary


def prolog_atom(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "\\'") + "'"


def fact_lines(rows: Iterable[StoreRow]) -> list[str]:
    lines: list[str] = []
    for row in rows:
        lines.extend(
            [
                f"standard_doing({prolog_atom(row.code)}, {row.family},",
                f"               {prolog_atom(row.genre)},",
                f"               support({row.receipts}, {row.lessons}, {row.share:.3f}),",
                f"               witness({prolog_atom(row.row_id)},",
                f"                       {row.machine},",
                f"                       {prolog_atom(row.input_json)},",
                f"                       {prolog_atom(row.result_term)})).",
                "",
            ]
        )
    return lines


def generated_source(
    rows: list[StoreRow], threshold: int, clusters: dict[str, str]
) -> bytes:
    header = [
        "/** <module> Receipt-backed CCSS standard narrowing",
        " *",
        " * Generated by scripts/language/build_standard_doing.py; do not edit.",
        f" * Admission threshold: support >= {threshold} routed receipts.",
        " * A row is present only when at least one receipt completed correctly.",
        " * The standard narrows the family and contract genre; the parsed program",
        " * decides the operation. No predicate in this module computes arithmetic.",
        " *",
        " * Grade 8 rows carry a cluster as their family, because every grade 8",
        " * machine-map row files `curriculum_task` -- a guide position rather than",
        " * a doing. Three of the fourteen clusters hold one machine each, so for",
        " * those the family and the machine coincide.",
        " */",
        ":- module(standard_doing,",
        "          [ standard_doing/5,",
        "            check_standard_doing/0",
        "          ]).",
        "",
        ":- use_module(library(http/json)).",
        ":- use_module(library(lists)).",
        ":- use_module(library(readutil)).",
        ":- use_module('../strategies/automaton_input_contracts',",
        "              [automaton_input_contract/5]).",
        "",
        ":- discontiguous standard_doing/5.",
        "",
    ]
    footer = r'''
standard_doing_contract_family(add, addition).
standard_doing_contract_family(subtract, subtraction).
standard_doing_contract_family(multiply, multiplication).
standard_doing_contract_family(divide, division).
standard_doing_contract_family(add_fractions, fraction).
standard_doing_contract_family(subtract_fractions, fraction).
standard_doing_contract_family(unit_fraction, fraction).
standard_doing_contract_family(compare_numerals_by_place_value, counting).
standard_doing_contract_family(decimal_add, decimal).
standard_doing_contract_family(decimal_compare, decimal).
standard_doing_contract_family(decimal_value, decimal).
standard_doing_contract_family(construct_rectangle_with_area, geometry).
standard_doing_contract_family(rectangle_missing_side_from_area, geometry).
standard_doing_contract_family(rectangle_missing_side_from_perimeter, geometry).
standard_doing_contract_family(rectangle_perimeter, geometry).
standard_doing_contract_family(rectangle_side_lengths_for_area, geometry).
standard_doing_contract_family(unit_cube_volume, geometry).
standard_doing_contract_family(convert_measurement, measurement).
__G8_CONTRACT_FAMILIES__
%!  check_standard_doing is det.
%
%   Re-read the wave-5 JSONL source and verify every generated witness. The
%   wave family is normalized only for the contract lookup; standard_doing/5
%   retains the operation-facing family used by the statement map.
check_standard_doing :-
    standard_doing_wave5_rows(WaveRows),
    forall(standard_doing(Code, Family, Genre, Support, Witness),
           check_standard_doing_row(Code, Family, Genre, Support, Witness,
                                    WaveRows)),
    aggregate_all(count, standard_doing(_, _, _, _, _), RowCount),
    findall(Code, standard_doing(Code, _, _, _, _), Codes0),
    sort(Codes0, Codes),
    length(Codes, CodeCount),
    format("check_standard_doing: ok rows=~d codes=~d~n",
           [RowCount, CodeCount]).

check_standard_doing_row(
        _Code, Family, _Genre, support(Receipts, Lessons, Share),
        witness(RowId, Machine, InputJSON, ResultTerm), WaveRows) :-
    Receipts >= __THRESHOLD__,
    Lessons >= 1,
    Share > 0.0,
    Share =< 1.0,
    standard_doing_contract_family(Family, ContractFamily),
    automaton_input_contract(ContractFamily, Machine, _Schema, _Example,
                             verified(strategy_trace_ok)),
    atom_json_dict(InputJSON, ExpectedInput, [value_string_as(atom)]),
    member(Row, WaveRows),
    Row.id == RowId,
    Row.machine == Machine,
    Row.input =@= ExpectedInput,
    Row.execution.outcome == correct,
    Row.execution.result_term == ResultTerm,
    !.
check_standard_doing_row(Code, Family, Genre, Support, Witness, _WaveRows) :-
    throw(error(standard_doing_receipt_failed(
                    Code, Family, Genre, Support, Witness),
                check_standard_doing/0)).

%   Both machine maps are read.  A witness for a grade 8 row is recorded in the
%   sibling map, so checking against the pool map alone would reject every
%   grade 8 row for a witness that is present in the tree.
standard_doing_wave5_rows(Rows) :-
    findall(MapRows,
            ( standard_doing_machine_map(Relative),
              standard_doing_map_rows(Relative, MapRows)
            ),
            RowLists),
    append(RowLists, Rows).

standard_doing_machine_map(
    '../../curriculum/im/generated/wave5_row_machine_map.jsonl').
standard_doing_machine_map(
    '../../curriculum/im/generated/wave5_g8_row_machine_map.jsonl').

standard_doing_map_rows(Relative, Rows) :-
    source_file(standard_doing:standard_doing(_, _, _, _, _), SourceFile),
    file_directory_name(SourceFile, StandardsDirectory),
    directory_file_path(StandardsDirectory, Relative, RelativePath),
    absolute_file_name(RelativePath, Path, [access(read)]),
    setup_call_cleanup(
        open(Path, read, Stream, [encoding(utf8)]),
        read_standard_doing_jsonl(Stream, Rows),
        close(Stream)).

read_standard_doing_jsonl(Stream, Rows) :-
    read_line_to_string(Stream, Line),
    (   Line == end_of_file
    ->  Rows = []
    ;   atom_json_dict(Line, Row, [value_string_as(atom)]),
        Rows = [Row|Rest],
        read_standard_doing_jsonl(Stream, Rest)
    ).
'''.replace("__THRESHOLD__", str(threshold))
    used = sorted({row.family for row in rows} & set(clusters))
    cluster_lines = "".join(
        f"standard_doing_contract_family({cluster}, {clusters[cluster]}).\n"
        for cluster in used
    )
    footer = footer.replace("__G8_CONTRACT_FAMILIES__\n", cluster_lines)
    return ("\n".join(header + fact_lines(rows)) + footer).encode("utf-8")


def compare_or_write(path: Path, content: bytes, check: bool) -> bool:
    if check:
        if not path.exists() or path.read_bytes() != content:
            print(f"STALE {path.relative_to(ROOT)}", file=sys.stderr)
            return False
        return True
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(content)
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--threshold", type=int, default=3)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--coverage-output", type=Path, default=DEFAULT_COVERAGE)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if args.threshold < 1:
        parser.error("--threshold must be at least 1")

    pusu_available = PUSU_RESULTS.is_file() and not os.environ.get(
        "HERMES_SHIP_C_FORCE_CLONE"
    )
    if pusu_available:
        coverage_bytes, lesson_codes = coverage_receipt()
    else:
        focused_coverage, _focused_codes = focused_coverage_receipt()
        lesson_codes = None
    clusters = cluster_contract_families()
    rows, summary = build_rows(lesson_codes, args.threshold)
    store_bytes = generated_source(rows, args.threshold, clusters)
    fresh = compare_or_write(args.output, store_bytes, args.check)
    if pusu_available:
        fresh = compare_or_write(args.coverage_output, coverage_bytes, args.check) and fresh
    summary.update(
        {
            "mode": "check" if args.check else "build",
            "output": str(args.output),
            "coverage_output": str(args.coverage_output),
            "fresh": fresh,
        }
    )
    if pusu_available:
        print(json.dumps(summary, sort_keys=True))
    else:
        print(
            "standard-doing focused coverage: "
            f"{focused_coverage['statements_with_code']}/"
            f"{focused_coverage['total_statements']} fixture rows carry a code; "
            f"{summary['rows']}-row store verified"
        )
    return 0 if fresh else 1


if __name__ == "__main__":
    raise SystemExit(main())
