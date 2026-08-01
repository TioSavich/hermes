#!/usr/bin/env python3
"""Measure the monitoring-name bridge against task 222's visualizer test.

The measurement first reproduces task 222's frozen join, then re-prices the
same test from live lesson strategy and misconception rows.  Both passes read
the live render-coverage register and the IM K-8 spine.  The script writes only
temporary Prolog extractors outside the repo.  Use ``--baseline-only`` to stop
after the pre-registered task-222 baseline.
"""

from __future__ import annotations

import argparse
import collections
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


REPO = Path(os.environ.get("HERMES_REPO", Path(__file__).resolve().parents[2])).resolve()
SPINE = REPO / "data/learningcommons/derived/im_k8_spine.json"
DEFAULT_TASK222 = Path(
    "/private/tmp/claude-501/-Users-tio-Documents-GitHub-hermes/"
    "eb956062-1d65-4cdb-91a7-e16c0bd73b2d/scratchpad/t222"
)
DRAWABLE = {"renders_live", "parametric_deformation"}
EXPECTED_FROZEN_BASELINE = {
    "blocked": (424, {"K-5": 120, "6-8": 304}),
    "clear_other_three": (353, {"K-5": 87, "6-8": 266}),
}
EXPECTED_LIVE_REPRICE = {
    "blocked": (423, {"K-5": 119, "6-8": 304}),
    "clear_other_three": (352, {"K-5": 86, "6-8": 266}),
}
REFERENCE_EXTRA_NAMES = {"right_triangle_without_longest_side"}


def grain(grade: object) -> str:
    value = str(grade)
    if value in {"K", "0", "1", "2", "3", "4", "5"}:
        return "K-5"
    if value in {"6", "7", "8"}:
        return "6-8"
    return "other"


def prolog_source(with_bridge: bool) -> str:
    bridge_load = ""
    bridge_emit = ""
    if with_bridge:
        bridge_load = (
            ":- use_module(misconceptions(monitoring_registry_bridge), "
            "[monitoring_registry_bridge/4, monitoring_registry_bridge_declined/2]).\n"
        )
        bridge_emit = """
    forall(monitoring_registry_bridge(Name, Op, _, _),
           format('B\\t~w\\t~w~n', [Name, Op])),
    forall(monitoring_registry_bridge_declined(Name, Reason),
           format('D\\t~w\\t~q~n', [Name, Reason])),
"""
    return f"""\
:- use_module(render(misconception_render_coverage)).
:- use_module(misconceptions(misconception_registry), [misconception_registry_entry/5]).
{bridge_load}
run :-
    forall(op_coverage_lane(Op, Lane, _),
           format('O\\t~w\\t~w~n', [Op, Lane])),
    render_coverage_summary(Summary),
    format('R\\t~w\\t~w\\t~w\\t~w~n',
           [Summary.bridge_rows, Summary.lanes.renders_live,
            Summary.lanes.parametric_deformation, Summary.lanes.not_covered]),
    setof(Name, Op^Citation^Commitment^Entitlement^
                misconception_registry_entry(Name, Op, Citation, Commitment, Entitlement),
          RegistryNames),
    forall(member(RegistryName, RegistryNames), format('E\\t~w~n', [RegistryName])),
{bridge_emit}    halt(0).
:- initialization(run).
"""


def live_extract(with_bridge: bool) -> list[list[str]]:
    with tempfile.TemporaryDirectory(prefix="hermes-task230-") as directory:
        extractor = Path(directory) / "extract.pl"
        extractor.write_text(prolog_source(with_bridge), encoding="utf-8")
        process = subprocess.run(
            ["swipl", "-q", "-l", "paths.pl", "-s", str(extractor)],
            cwd=REPO,
            text=True,
            capture_output=True,
            check=False,
        )
    if process.returncode != 0:
        if process.stdout:
            print(process.stdout, end="", file=sys.stderr)
        if process.stderr:
            print(process.stderr, end="", file=sys.stderr)
        raise RuntimeError(f"live Prolog extraction failed with exit {process.returncode}")
    return [line.split("\t") for line in process.stdout.splitlines() if "\t" in line]


def live_clause_extract() -> list[list[str]]:
    source = """\
:- use_module(library(http/json)).
:- use_module(lessons(im/lesson_monitoring)).
run :-
    open('data/learningcommons/derived/im_lesson_capability_census.json', read, Stream),
    json_read_dict(Stream, Census),
    close(Stream),
    forall(member(Row, Census.lessons),
      ( atom_string(Code, Row.lesson),
        format('L\\t~w~n', [Code]),
        forall(lesson_monitoring:cluster_lesson_geometry_misconception(Code, Name, _),
               format('G\\t~w\\t~w~n', [Code, Name])),
        ( lesson_strategy(Code, geometry, _, _)
        -> format('S\\t~w~n', [Code])
        ;  true
        )
      )),
    halt(0).
:- initialization(run).
"""
    with tempfile.TemporaryDirectory(prefix="hermes-task230-clause-") as directory:
        extractor = Path(directory) / "extract.pl"
        extractor.write_text(source, encoding="utf-8")
        process = subprocess.run(
            ["swipl", "-q", "-l", "paths.pl", "-s", str(extractor)],
            cwd=REPO,
            text=True,
            capture_output=True,
            check=False,
        )
    if process.returncode != 0:
        if process.stderr:
            print(process.stderr, end="", file=sys.stderr)
        raise RuntimeError(f"live clause extraction failed with exit {process.returncode}")
    return [line.split("\t") for line in process.stdout.splitlines() if "\t" in line]


def live_lesson_extract() -> list[list[str]]:
    source = """\
:- use_module(lessons(im/lesson_monitoring)).
run :-
    forall(im_lesson(Code, _, _, _, _, _),
      ( forall(lesson_strategy(Code, Operation, Kind, _),
               format('S\\t~w\\t~w\\t~w~n', [Code, Operation, Kind])),
        forall(lesson_misconception(Code, Operation, Name, _),
               format('M\\t~w\\t~w\\t~w~n', [Code, Operation, Name])),
        format('L\\t~w~n', [Code])
      )),
    halt(0).
:- initialization(run).
"""
    with tempfile.TemporaryDirectory(prefix="hermes-task230-lessons-") as directory:
        extractor = Path(directory) / "extract.pl"
        extractor.write_text(source, encoding="utf-8")
        process = subprocess.run(
            ["swipl", "-q", "-l", "paths.pl", "-s", str(extractor)],
            cwd=REPO,
            text=True,
            capture_output=True,
            check=False,
        )
    if process.returncode != 0:
        if process.stdout:
            print(process.stdout, end="", file=sys.stderr)
        if process.stderr:
            print(process.stderr, end="", file=sys.stderr)
        raise RuntimeError(f"live lesson extraction failed with exit {process.returncode}")
    return [line.split("\t") for line in process.stdout.splitlines() if "\t" in line]


def parse_lesson_records(
    records: list[list[str]],
) -> tuple[
    dict[str, set[str]],
    dict[str, set[str]],
    dict[str, set[str]],
    dict[str, set[tuple[str, str]]],
]:
    strategy_ops: dict[str, set[str]] = collections.defaultdict(set)
    misconception_ops: dict[str, set[str]] = collections.defaultdict(set)
    misconception_names: dict[str, set[str]] = collections.defaultdict(set)
    misconception_pairs: dict[str, set[tuple[str, str]]] = collections.defaultdict(set)
    for record in records:
        if record[0] == "S" and len(record) == 4:
            strategy_ops[record[1]].add(record[2])
        elif record[0] == "M" and len(record) == 4:
            misconception_ops[record[1]].add(record[2])
            misconception_names[record[1]].add(record[3])
            misconception_pairs[record[1]].add((record[2], record[3]))
    return strategy_ops, misconception_ops, misconception_names, misconception_pairs


def price_population(
    population: dict[str, dict[str, object]],
    frozen_rows: dict[str, dict[str, object]],
    lanes: dict[str, str],
    strategy_ops: dict[str, set[str]],
    misconception_ops: dict[str, set[str]],
) -> tuple[
    dict[str, dict[str, object]],
    set[str],
    set[str],
    set[str],
]:
    rows: dict[str, dict[str, object]] = {}
    for lesson, source in population.items():
        operations = strategy_ops[lesson] | misconception_ops[lesson]
        rows[lesson] = {
            "grain": grain(source["grade"]),
            "standard": bool(frozen_rows[lesson]["i1_standard"]),
            "automaton": bool(strategy_ops[lesson]),
            "questions": bool(frozen_rows[lesson]["i6_questions"]),
            "visual": any(lanes.get(operation) in DRAWABLE for operation in operations),
        }
    visual = {lesson for lesson, row in rows.items() if row["visual"]}
    blocked = {
        lesson
        for lesson, row in rows.items()
        if row["automaton"] and not row["visual"]
    }
    clear_other_three = {
        lesson
        for lesson in blocked
        if rows[lesson]["standard"] and rows[lesson]["questions"]
    }
    return rows, visual, blocked, clear_other_three


def bridge_price(
    population: dict[str, dict[str, object]],
    visual_before: set[str],
    blocked: set[str],
    clear_other_three: set[str],
    misconception_names: dict[str, set[str]],
    bridge: dict[str, str],
    lanes: dict[str, str],
) -> tuple[set[str], set[str], set[str], set[str]]:
    added_ops: dict[str, set[str]] = collections.defaultdict(set)
    for lesson, names_for_lesson in misconception_names.items():
        for name in names_for_lesson:
            if name in bridge:
                added_ops[lesson].add(bridge[name])
    visual_after = {
        lesson
        for lesson in population
        if lesson in visual_before
        or any(lanes.get(operation) in DRAWABLE for operation in added_ops[lesson])
    }
    return (
        visual_after,
        blocked & visual_after,
        clear_other_three & visual_after,
        visual_before - visual_after,
    )


def name_set_projection(
    names: set[str], blocked: set[str], misconception_names: dict[str, set[str]]
) -> dict[str, frozenset[str]]:
    return {
        name: frozenset(
            lesson for lesson in blocked if name in misconception_names[lesson]
        )
        for name in names
    }


def split_count(lessons: set[str] | list[str], rows: dict[str, dict[str, object]]) -> dict[str, int]:
    count = collections.Counter(rows[lesson]["grain"] for lesson in lessons)
    return {"K-5": count["K-5"], "6-8": count["6-8"]}


def print_count(label: str, lessons: set[str] | list[str], rows: dict[str, dict[str, object]]) -> None:
    split = split_count(lessons, rows)
    print(f"{label}={len(lessons)} K-5={split['K-5']} 6-8={split['6-8']}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--baseline-only",
        action="store_true",
        help="reproduce the pre-bridge baseline without loading the bridge table",
    )
    parser.add_argument(
        "--task222-dir",
        type=Path,
        default=DEFAULT_TASK222,
        help="directory containing task 222 rows.json and extract2.tsv",
    )
    parser.add_argument(
        "--live-clause-check",
        action="store_true",
        help="enumerate the live capability-census codes and recount the geometry clause",
    )
    parser.add_argument(
        "--live-extract-path",
        type=Path,
        help="read a previously captured live S/M/L extract instead of invoking SWI-Prolog",
    )
    args = parser.parse_args()

    if args.live_clause_check:
        records = live_clause_extract()
        census = {record[1] for record in records if record[0] == "L"}
        clause_lessons = {record[1] for record in records if record[0] == "G"}
        names = {record[2] for record in records if record[0] == "G"}
        strategy_lessons = {record[1] for record in records if record[0] == "S"}
        middle = lambda code: code.startswith(("IM-G6-", "IM-G7-", "IM-G8-"))
        print(f"live_capability_census={len(census)}")
        print(
            f"live_geometry_clause_lessons={len(clause_lessons)} "
            f"grades_6_8={sum(map(middle, clause_lessons))}"
        )
        print(f"live_geometry_clause_distinct_names={len(names)}")
        print(
            f"live_strategy_geometry_lessons={len(strategy_lessons)} "
            f"grades_6_8={sum(map(middle, strategy_lessons))}"
        )
        frozen_extract = args.task222_dir.resolve() / "extract2.tsv"
        if frozen_extract.is_file():
            frozen_clause: set[str] = set()
            frozen_strategy: set[str] = set()
            for line in frozen_extract.read_text(encoding="utf-8").splitlines():
                record = line.split("\t")
                if len(record) == 4 and record[0] == "M" and record[2] == "geometry":
                    frozen_clause.add(record[1])
                elif len(record) == 4 and record[0] == "S" and record[2] == "geometry":
                    frozen_strategy.add(record[1])
            print(f"clause_frozen_only={','.join(sorted(frozen_clause - clause_lessons)) or '-'}")
            print(f"clause_live_only={','.join(sorted(clause_lessons - frozen_clause)) or '-'}")
            print(f"strategy_frozen_only={','.join(sorted(frozen_strategy - strategy_lessons)) or '-'}")
            print(f"strategy_live_only={','.join(sorted(strategy_lessons - frozen_strategy)) or '-'}")
        if (len(census), len(clause_lessons), sum(map(middle, clause_lessons)),
            len(names), len(strategy_lessons), sum(map(middle, strategy_lessons))) != (
                1317, 207, 99, 37, 241, 107
            ):
            print("LIVE_CLAUSE_MISMATCH expected=1317/207/99/37/241/107", file=sys.stderr)
            return 7
        print("LIVE_CLAUSE_REPRICED pre_registered=208/99 strategy=242/107")
        return 0

    spine = json.loads(SPINE.read_text(encoding="utf-8"))
    population = {row["repo_id"]: row for row in spine}
    if len(population) != 1308:
        print(f"BASELINE_MISMATCH spine_population={len(population)} expected=1308", file=sys.stderr)
        return 2

    task222 = args.task222_dir.resolve()
    rows_path = task222 / "rows.json"
    extract_path = task222 / "extract2.tsv"
    if not rows_path.is_file() or not extract_path.is_file():
        print(
            f"MISSING_TASK222_INPUT task222_dir={task222} "
            "expected=rows.json,extract2.tsv",
            file=sys.stderr,
        )
        return 2

    frozen_rows = json.loads(rows_path.read_text(encoding="utf-8"))
    if set(frozen_rows) != set(population):
        print("BASELINE_MISMATCH task222 population differs from live spine", file=sys.stderr)
        return 2

    records = live_extract(with_bridge=not args.baseline_only)
    lanes: dict[str, str] = {}
    bridge: dict[str, str] = {}
    declines: dict[str, str] = {}
    register_summary: tuple[int, int, int, int] | None = None
    registry_names: set[str] = set()

    for record in records:
        tag = record[0]
        if tag == "O" and len(record) == 3:
            lanes[record[1]] = record[2]
        elif tag == "R" and len(record) == 5:
            register_summary = tuple(int(value) for value in record[1:5])
        elif tag == "E" and len(record) == 2:
            registry_names.add(record[1])
        elif tag == "B" and len(record) == 3:
            if record[1] in bridge and bridge[record[1]] != record[2]:
                print(f"INVALID_BRIDGE duplicate_name={record[1]}", file=sys.stderr)
                return 3
            bridge[record[1]] = record[2]
        elif tag == "D" and len(record) >= 3:
            declines[record[1]] = "\t".join(record[2:])

    frozen_records = [
        line.split("\t")
        for line in extract_path.read_text(encoding="utf-8").splitlines()
        if "\t" in line
    ]
    (
        frozen_strategy_ops,
        frozen_misconception_ops,
        frozen_misconception_names,
        frozen_misconception_pairs,
    ) = parse_lesson_records(frozen_records)
    frozen_price = price_population(
        population,
        frozen_rows,
        lanes,
        frozen_strategy_ops,
        frozen_misconception_ops,
    )
    frozen_rows_priced, frozen_visual, frozen_blocked, frozen_clear = frozen_price

    print("PRE_REGISTERED_TASK222")
    print(f"population={len(population)}")
    if register_summary is not None:
        bridge_rows, renders_live, parametric, not_covered = register_summary
        print(
            "register "
            f"bridge_rows={bridge_rows} renders_live={renders_live} "
            f"parametric_deformation={parametric} not_covered={not_covered}"
        )
    print_count("visualizer_before", frozen_visual, frozen_rows_priced)
    print_count("blocked_before", frozen_blocked, frozen_rows_priced)
    print_count("blocked_clearing_other_three_before", frozen_clear, frozen_rows_priced)

    frozen_clause_lessons = {
        lesson
        for lesson in population
        if "geometry" in frozen_misconception_ops[lesson]
    }
    frozen_strategy_geometry = {
        lesson for lesson in population if "geometry" in frozen_strategy_ops[lesson]
    }
    frozen_geometry_names = {
        name
        for pairs in frozen_misconception_pairs.values()
        for operation, name in pairs
        if operation == "geometry"
    }
    print_count("geometry_clause_lessons", frozen_clause_lessons, frozen_rows_priced)
    print_count("strategy_geometry_lessons", frozen_strategy_geometry, frozen_rows_priced)
    print(f"geometry_clause_all_distinct_names={len(frozen_geometry_names)}")
    frozen_unresolved_names = frozen_geometry_names - registry_names
    print(f"geometry_clause_names_without_registry={len(frozen_unresolved_names)}")
    for name in sorted(frozen_unresolved_names):
        print(f"NAME {name}")

    baseline_ok = True
    for key, lessons in (("blocked", frozen_blocked), ("clear_other_three", frozen_clear)):
        expected_total, expected_split = EXPECTED_FROZEN_BASELINE[key]
        actual_split = split_count(lessons, frozen_rows_priced)
        if len(lessons) != expected_total or actual_split != expected_split:
            baseline_ok = False
            print(
                f"BASELINE_MISMATCH {key} actual={len(lessons)}/{actual_split} "
                f"expected={expected_total}/{expected_split}",
                file=sys.stderr,
            )
    if not baseline_ok:
        return 4
    print("PRE_REGISTERED_BASELINE_REPRODUCED")

    if args.baseline_only:
        return 0

    dispositions = set(bridge) | set(declines)
    names = dispositions
    if dispositions != frozen_unresolved_names or set(bridge) & set(declines):
        print(
            "INVALID_DISPOSITIONS "
            f"missing={sorted(frozen_unresolved_names - dispositions)} "
            f"extra={sorted(dispositions - frozen_unresolved_names)} "
            f"both={sorted(set(bridge) & set(declines))}",
            file=sys.stderr,
        )
        return 5
    print("unresolved_monitoring_names=37")
    bad_ops = sorted(name for name, op in bridge.items() if op not in lanes)
    if bad_ops:
        print(f"INVALID_BRIDGE non_registry_names={bad_ops}", file=sys.stderr)
        return 6

    _, frozen_freed, frozen_freed_clear, frozen_regressions = bridge_price(
        population,
        frozen_visual,
        frozen_blocked,
        frozen_clear,
        frozen_misconception_names,
        bridge,
        lanes,
    )
    frozen_name_sets = name_set_projection(
        names, frozen_blocked, frozen_misconception_names
    )
    frozen_reference_names = set(bridge) | REFERENCE_EXTRA_NAMES
    frozen_reference = set().union(
        *(frozen_name_sets[name] for name in frozen_reference_names)
    )
    frozen_ceiling = set().union(*frozen_name_sets.values())
    print_count("pre_registered_blocked_now_drawable", frozen_freed, frozen_rows_priced)
    print_count(
        "pre_registered_blocked_clearing_other_three_now_drawable",
        frozen_freed_clear,
        frozen_rows_priced,
    )
    print_count("pre_registered_reference", frozen_reference, frozen_rows_priced)
    print_count("pre_registered_ceiling", frozen_ceiling, frozen_rows_priced)
    print(f"pre_registered_regressions={len(frozen_regressions)}")
    if len(frozen_reference) != 163 or len(frozen_ceiling) != 174:
        print(
            "PROJECTION_MISMATCH "
            f"pre_registered_reference={len(frozen_reference)} "
            f"pre_registered_ceiling={len(frozen_ceiling)} expected=163/174",
            file=sys.stderr,
        )
        return 8

    if args.live_extract_path:
        live_records = [
            line.split("\t")
            for line in args.live_extract_path.resolve().read_text(encoding="utf-8").splitlines()
            if "\t" in line
        ]
    else:
        live_records = live_lesson_extract()
    live_codes = {record[1] for record in live_records if record[0] == "L"}
    if live_codes != set(population):
        print(
            "LIVE_REPRICE_MISMATCH lesson population differs from live spine",
            file=sys.stderr,
        )
        return 9
    (
        strategy_ops,
        misconception_ops,
        misconception_names,
        misconception_pairs,
    ) = parse_lesson_records(live_records)
    rows, visual_before, blocked, clear_other_three = price_population(
        population,
        frozen_rows,
        lanes,
        strategy_ops,
        misconception_ops,
    )

    print("LIVE_REPRICE")
    print_count("visualizer_before", visual_before, rows)
    print_count("blocked_before", blocked, rows)
    print_count("blocked_clearing_other_three_before", clear_other_three, rows)
    clause_lessons = {
        lesson for lesson in population if "geometry" in misconception_ops[lesson]
    }
    strategy_geometry = {
        lesson for lesson in population if "geometry" in strategy_ops[lesson]
    }
    all_geometry_names = {
        name
        for pairs in misconception_pairs.values()
        for operation, name in pairs
        if operation == "geometry"
    }
    print_count("geometry_clause_lessons", clause_lessons, rows)
    print_count("strategy_geometry_lessons", strategy_geometry, rows)
    unresolved_names = all_geometry_names - registry_names
    print(f"geometry_clause_names_without_registry={len(unresolved_names)}")
    if unresolved_names != dispositions:
        print(
            "LIVE_DISPOSITION_MISMATCH "
            f"missing={sorted(unresolved_names - dispositions)} "
            f"extra={sorted(dispositions - unresolved_names)}",
            file=sys.stderr,
        )
        return 9

    live_ok = True
    for key, lessons in (("blocked", blocked), ("clear_other_three", clear_other_three)):
        expected_total, expected_split = EXPECTED_LIVE_REPRICE[key]
        actual_split = split_count(lessons, rows)
        if len(lessons) != expected_total or actual_split != expected_split:
            live_ok = False
            print(
                f"LIVE_REPRICE_MISMATCH {key} actual={len(lessons)}/{actual_split} "
                f"expected={expected_total}/{expected_split}",
                file=sys.stderr,
            )
    blocked_removed = frozen_blocked - blocked
    blocked_added = blocked - frozen_blocked
    clear_removed = frozen_clear - clear_other_three
    clear_added = clear_other_three - frozen_clear
    for lesson in sorted(blocked_removed | blocked_added):
        direction = "removed" if lesson in blocked_removed else "added"
        print(
            f"BLOCKED_DELTA lesson={lesson} direction={direction} "
            f"frozen_strategy={','.join(sorted(frozen_strategy_ops[lesson])) or '-'} "
            f"live_strategy={','.join(sorted(strategy_ops[lesson])) or '-'} "
            f"frozen_names={','.join(sorted(frozen_misconception_names[lesson])) or '-'} "
            f"live_names={','.join(sorted(misconception_names[lesson])) or '-'}"
        )
    print(
        f"blocked_removed={','.join(sorted(blocked_removed)) or '-'} "
        f"blocked_added={','.join(sorted(blocked_added)) or '-'}"
    )
    print(
        f"clear_other_three_removed={','.join(sorted(clear_removed)) or '-'} "
        f"clear_other_three_added={','.join(sorted(clear_added)) or '-'}"
    )
    if (
        blocked_removed != {"IM-GK-U7-L14"}
        or blocked_added
        or clear_removed != {"IM-GK-U7-L14"}
        or clear_added
    ):
        live_ok = False
        print("LIVE_REPRICE_MISMATCH unexpected lesson-set delta", file=sys.stderr)
    if not live_ok:
        return 9
    print("LIVE_BASELINE_REPRICED")

    _, freed, freed_clear_three, regressions = bridge_price(
        population,
        visual_before,
        blocked,
        clear_other_three,
        misconception_names,
        bridge,
        lanes,
    )
    print(f"bridge_rows={len(bridge)} declines={len(declines)}")
    print_count("blocked_now_drawable", freed, rows)
    print_count("blocked_clearing_other_three_now_drawable", freed_clear_three, rows)
    print(f"visualizer_regressions={len(regressions)}")

    name_sets = name_set_projection(names, blocked, misconception_names)
    distinct_sets: dict[frozenset[str], list[str]] = collections.defaultdict(list)
    for name, lesson_set in name_sets.items():
        distinct_sets[lesson_set].append(name)
    print(f"distinct_blocked_lesson_sets={len(distinct_sets)}")
    ordered_sets = sorted(
        distinct_sets.items(), key=lambda item: (-len(item[0]), sorted(item[1])[0])
    )
    for index, (lesson_set, set_names) in enumerate(ordered_sets, start=1):
        covered_names = sorted(name for name in set_names if name in bridge)
        status = "covered" if covered_names else "not_covered"
        split = split_count(set(lesson_set), rows)
        print(
            f"SET {index} size={len(lesson_set)} K-5={split['K-5']} 6-8={split['6-8']} "
            f"status={status} names={','.join(sorted(set_names))} "
            f"bridge_names={','.join(covered_names) or '-'}"
        )

    unresolved_union = set().union(*name_sets.values()) if name_sets else set()
    no_unresolved_name = blocked - unresolved_union
    no_misconception_name = {
        lesson for lesson in blocked if not misconception_names[lesson]
    }
    reference_names = set(bridge) | REFERENCE_EXTRA_NAMES
    reference_union = set().union(*(name_sets[name] for name in reference_names))
    print(f"bridge_ceiling={len(unresolved_union)}")
    print(f"blocked_with_no_unresolved_monitoring_name={len(no_unresolved_name)}")
    print(f"blocked_with_no_misconception_name={len(no_misconception_name)}")
    print_count("reference", reference_union, rows)
    print_count("ceiling", unresolved_union, rows)
    for name in sorted(REFERENCE_EXTRA_NAMES):
        marginal = set(name_sets[name]) - freed
        print(
            f"REFERENCE_GAP name={name} raw={len(name_sets[name])} "
            f"marginal_over_bridge={len(marginal)}"
        )
    for name in sorted(declines):
        if name in reference_names:
            continue
        marginal = set(name_sets[name]) - reference_union
        if marginal:
            print(
                f"CEILING_GAP name={name} raw={len(name_sets[name])} "
                f"marginal_over_reference={len(marginal)}"
            )
    if len(reference_union) != 162 or len(unresolved_union) != 173:
        print(
            "PROJECTION_MISMATCH "
            f"live_reference={len(reference_union)} live_ceiling={len(unresolved_union)} "
            "expected=162/173",
            file=sys.stderr,
        )
        return 8
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
