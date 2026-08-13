#!/usr/bin/env python3
"""Generate the quarantined task-pattern pilot from the wave-5 row map.

Reads `curriculum/im/generated/wave5_row_machine_map.jsonl` (S1's artifact,
consumed, never rebuilt here), algebraicizes every mapped row, and writes one
Prolog row per constraint region with a verified witness. The module is
quarantined in the sense the abstraction directory already carries: nothing
imports it, it renames nothing, and every row is vetoable on its own.

Also writes a runtime index the question linker reads, so the linker never
re-derives ground truth.
"""
from __future__ import annotations

import argparse
import collections
import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))

from algebraicize import algebraicize, operation_term, witness_term  # noqa: E402

ROW_MAP = ROOT / "curriculum" / "im" / "generated" / "wave5_row_machine_map.jsonl"
CONTRACTS = ROOT / "knowledge" / "strategies" / "automaton_input_contracts.pl"
TYPOLOGY = ROOT / "knowledge" / "strategies" / "machine_typology.pl"
COINCIDENCE = ROOT / "knowledge" / "strategies" / "deformation_coincidence.pl"
VALIDITY = ROOT / "knowledge" / "strategies" / "deformation_validity.pl"
PILOT = ROOT / "knowledge" / "strategies" / "abstraction" / "task_pattern_pilot.pl"
RUNTIME = ROOT / "hermes" / "app" / "runtime" / "experiments" / "questions"
INDEX = RUNTIME / "task_patterns.json"
MENU = RUNTIME / "machine_menu.json"

GENERATED_DATE = "date(2026,8,12)"


def read_rows() -> list[dict]:
    return [json.loads(line) for line in ROW_MAP.read_text(encoding="utf-8").splitlines() if line.strip()]


def contract_table() -> dict[str, tuple[str, str]]:
    """machine kind -> (registry family, JSON schema string as written in Prolog)."""
    text = CONTRACTS.read_text(encoding="utf-8")
    table: dict[str, tuple[str, str]] = {}
    for match in re.finditer(
        r"automaton_input_contract\((\w+),\s*(\w+),\s*'((?:[^'\\]|\\.)*)'", text
    ):
        table.setdefault(match.group(2), (match.group(1), match.group(3)))
    return table


def typology_families() -> dict[str, str]:
    text = TYPOLOGY.read_text(encoding="utf-8")
    return {m.group(2): m.group(1) for m in re.finditer(r"machine_structure\((\w+),\s*(\w+),", text)}


def polarity_table(families: dict[str, str]) -> dict[str, str]:
    """productive / deformation / unmarked, from the two authored ledgers."""
    polarity: dict[str, str] = {}
    coincidence = COINCIDENCE.read_text(encoding="utf-8")
    for match in re.finditer(r"coincidence_profile\((\w+),\s*(\w+),\s*(\w+),", coincidence):
        polarity[match.group(2)] = match.group(3)
    validity = VALIDITY.read_text(encoding="utf-8")
    for match in re.finditer(r"^deformation_validity\((\w+),\s*(\w+),", validity, re.M):
        polarity[match.group(2)] = "deformation"
    for kind in families:
        polarity.setdefault(kind, "unmarked")
    return polarity


def quote_atom(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "\\'") + "'"


def build() -> dict[str, object]:
    rows = read_rows()
    contracts = contract_table()
    families = typology_families()
    polarity = polarity_table(families)

    patterns: dict[str, dict] = {}
    per_lesson: dict[tuple[str, str], int] = collections.Counter()
    exclusions: collections.Counter[str] = collections.Counter()
    token_guard: dict[tuple[str, str], tuple[str, ...]] = {}

    for row in sorted(rows, key=lambda item: item["id"]):
        machine = row.get("machine")
        if not machine:
            exclusions["unmapped_machine"] += 1
            continue
        schema = algebraicize(row["family"], row.get("input"))
        if schema is None:
            exclusions["no_numeric_parameters"] += 1
            continue
        signature = (row["family"], tuple(schema["parameters"]))
        seen = token_guard.setdefault(signature[0], tuple())
        token_guard[signature[0]] = seen
        verified = row["execution"].get("outcome") == "correct"
        pattern_id = schema["pattern_id"]
        entry = patterns.setdefault(
            pattern_id,
            {
                "pattern_id": pattern_id,
                "family": row["family"],
                "base": schema["base"],
                "parameters": schema["parameters"],
                "constraints": schema["constraints"],
                "witness": None,
                "witness_row": None,
                "witness_lesson": None,
                "witness_machine": None,
                "rows": 0,
                "verified_rows": 0,
                "machines": collections.Counter(),
                "lessons": collections.Counter(),
                "grades": collections.Counter(),
            },
        )
        if entry["parameters"] != schema["parameters"]:
            raise RuntimeError(
                f"pattern id {pattern_id} names two different parameter sets: "
                f"{entry['parameters']} and {schema['parameters']}"
            )
        entry["rows"] += 1
        entry["machines"][machine] += 1
        entry["lessons"][row["lesson"]] += 1
        entry["grades"][str(row["grade"])] += 1
        per_lesson[(row["lesson"], pattern_id)] += 1
        if verified:
            entry["verified_rows"] += 1
            if entry["witness"] is None:
                entry["witness"] = schema["witness_values"]
                entry["witness_row"] = row["id"]
                entry["witness_lesson"] = row["lesson"]
                entry["witness_machine"] = machine
                entry["witness_input"] = row.get("input")

    without_witness = {pid for pid, entry in patterns.items() if entry["witness"] is None}
    for pid in sorted(without_witness):
        exclusions["region_without_verified_witness"] += patterns[pid]["rows"]
        del patterns[pid]
    per_lesson = collections.Counter(
        {key: count for key, count in per_lesson.items() if key[1] in patterns}
    )

    lines: list[str] = []
    lines.append(":- encoding(utf8).")
    lines.append("/** <module> Task-pattern pilot — algebraicized regions of the mapped curriculum")
    lines.append(" *")
    lines.append(" * GENERATED by scripts/questions/build_task_pattern_pilot.py. Do not edit by")
    lines.append(" * hand; edit the generator or the wave-5 row map it reads.")
    lines.append(" *")
    lines.append(" * QUARANTINED in the sense this directory already carries: nothing imports")
    lines.append(" * this module, it renames nothing, and its rows are vetoable one by one. A")
    lines.append(" * row names a region of input space that the registered machines already")
    lines.append(" * discriminate; the numerals are washed out into guards, and the witness is")
    lines.append(" * one instance of the region that the formal core ran to a correct verdict.")
    lines.append(" *")
    lines.append(" * task_pattern(Id, operation(Term), base(B), constraints(Guards),")
    lines.append(" *              witness(Instance), contract_join(RegistryFamily, Schema)).")
    lines.append(" * task_pattern_witness(Id, row(RowId), lesson(Lesson), machine(Kind),")
    lines.append(" *                      verified(strategy_trace_correct)).")
    lines.append(" * task_pattern_lesson(lesson(Lesson), Id, rows(N)).")
    lines.append(" *")
    lines.append(" * Check: swipl -q -l paths.pl -l knowledge/strategies/abstraction/task_pattern_pilot.pl \\")
    lines.append(" *              -g task_pattern_pilot:check_task_pattern_pilot -t halt")
    lines.append(" */")
    lines.append(":- module(task_pattern_pilot,")
    lines.append("          [ task_pattern/6,")
    lines.append("            task_pattern_witness/5,")
    lines.append("            task_pattern_lesson/3,")
    lines.append("            task_pattern_pilot_summary/6,")
    lines.append("            check_task_pattern_pilot/0")
    lines.append("          ]).")
    lines.append("")
    lines.append(":- use_module(library(lists)).")
    lines.append("")

    for pattern_id in sorted(patterns):
        entry = patterns[pattern_id]
        family = entry["family"]
        machine = entry["witness_machine"]
        registry_family, schema_text = contracts.get(
            machine, (families.get(machine, "unregistered"), "")
        )
        guards = ", ".join(entry["constraints"])
        lines.append(f"task_pattern({pattern_id},")
        lines.append(f"    operation({operation_term(family, entry['parameters'])}),")
        lines.append(f"    base({entry['base']}),")
        lines.append(f"    constraints([{guards}]),")
        lines.append(f"    witness({witness_term(family, entry['witness'])}),")
        if schema_text:
            lines.append(f"    contract_join({registry_family}, '{schema_text}')).")
        else:
            lines.append(f"    contract_join({registry_family}, no_published_contract)).")
    lines.append("")
    for pattern_id in sorted(patterns):
        entry = patterns[pattern_id]
        lines.append(
            f"task_pattern_witness({pattern_id}, row({quote_atom(entry['witness_row'])}), "
            f"lesson({quote_atom(entry['witness_lesson'])}), machine({entry['witness_machine']}), "
            f"verified(strategy_trace_correct))."
        )
    lines.append("")
    for (lesson, pattern_id), count in sorted(per_lesson.items()):
        lines.append(f"task_pattern_lesson(lesson({quote_atom(lesson)}), {pattern_id}, rows({count})).")
    lines.append("")

    lesson_count = len({lesson for lesson, _ in per_lesson})
    covered = sum(entry["rows"] for entry in patterns.values())
    lines.append("%! task_pattern_pilot_summary(-Patterns, -Families, -Lessons, -Rows, -Excluded, -Generated)")
    lines.append("%")
    lines.append("%  What this file holds, so a reader never counts it by hand.")
    lines.append(
        "task_pattern_pilot_summary(patterns(%d), families(%d), lessons(%d), rows_covered(%d), "
        "rows_excluded(%d), generated(%s))."
        % (
            len(patterns),
            len({entry["family"] for entry in patterns.values()}),
            lesson_count,
            covered,
            sum(exclusions.values()),
            GENERATED_DATE,
        )
    )
    lines.append("")
    lines.extend(CHECK_SOURCE.splitlines())
    lines.append("")

    body = "\n".join(lines)
    PILOT.write_text(body, encoding="utf-8")

    index = {
        "generated_from": str(ROW_MAP.relative_to(ROOT)),
        "row_map_sha256": hashlib.sha256(ROW_MAP.read_bytes()).hexdigest(),
        "patterns": {
            pattern_id: {
                "family": entry["family"],
                "base": entry["base"],
                "parameters": entry["parameters"],
                "constraints": entry["constraints"],
                "witness": entry["witness"],
                "witness_input": entry.get("witness_input"),
                "witness_row": entry["witness_row"],
                "witness_lesson": entry["witness_lesson"],
                "witness_machine": entry["witness_machine"],
                "rows": entry["rows"],
                "verified_rows": entry["verified_rows"],
                "machines": dict(entry["machines"]),
                "lessons": sorted(entry["lessons"]),
                "grades": dict(entry["grades"]),
            }
            for pattern_id, entry in sorted(patterns.items())
        },
        "lesson_patterns": collections.defaultdict(list),
        "exclusions": dict(exclusions),
    }
    for (lesson, pattern_id), count in sorted(per_lesson.items()):
        index["lesson_patterns"][lesson].append({"pattern_id": pattern_id, "rows": count})
    index["lesson_patterns"] = dict(index["lesson_patterns"])
    RUNTIME.mkdir(parents=True, exist_ok=True)
    INDEX.write_text(json.dumps(index, indent=1, sort_keys=True) + "\n", encoding="utf-8")

    menu: dict[str, list[dict[str, str]]] = collections.defaultdict(list)
    for kind, registry_family in sorted(families.items()):
        menu[registry_family].append({"kind": kind, "polarity": polarity.get(kind, "unmarked")})
    MENU.write_text(json.dumps(menu, indent=1, sort_keys=True) + "\n", encoding="utf-8")

    return {
        "patterns": len(patterns),
        "families": len({entry["family"] for entry in patterns.values()}),
        "lessons": lesson_count,
        "rows_covered": covered,
        "exclusions": dict(exclusions),
        "pilot": str(PILOT.relative_to(ROOT)),
        "index": str(INDEX),
        "pilot_sha256": hashlib.sha256(PILOT.read_bytes()).hexdigest(),
    }


CHECK_SOURCE = '''%! check_task_pattern_pilot is det.
%
%  Every pattern's witness satisfies every guard the pattern states, ids are
%  unique, and each lesson row names a pattern this file holds. A guard that
%  the witness fails would mean the algebraicizer named a region its own
%  instance is outside of.
check_task_pattern_pilot :-
    findall(Id, task_pattern(Id, _, _, _, _, _), Ids),
    sort(Ids, Sorted),
    (   length(Ids, N), length(Sorted, N)
    ->  true
    ;   throw(error(duplicate_task_pattern_ids, _))
    ),
    forall(task_pattern(Id, operation(Op), base(Base), constraints(Guards),
                        witness(Witness), _),
           check_pattern(Id, Op, Base, Guards, Witness)),
    forall(task_pattern_lesson(_, Id2, _),
           (   task_pattern(Id2, _, _, _, _, _)
           ->  true
           ;   throw(error(unknown_task_pattern(Id2), _))
           )),
    forall(task_pattern_witness(Id3, _, _, _, _),
           (   task_pattern(Id3, _, _, _, _, _)
           ->  true
           ;   throw(error(unknown_task_pattern(Id3), _))
           )),
    task_pattern_pilot_summary(patterns(P), _, _, _, _, _),
    (   length(Sorted, P)
    ->  true
    ;   throw(error(summary_disagrees_with_rows, _))
    ),
    format("check_task_pattern_pilot: ~w patterns, every witness inside its guards~n", [P]).

check_pattern(Id, Op, Base, Guards, Witness) :-
    Op =.. [_|Names],
    Witness =.. [_|Values],
    (   length(Names, L), length(Values, L)
    ->  true
    ;   throw(error(witness_arity_mismatch(Id), _))
    ),
    pairs_keys_values(Bindings, Names, Values),
    forall(member(Guard, Guards),
           (   guard_holds(Guard, Base, Bindings)
           ->  true
           ;   throw(error(witness_outside_guard(Id, Guard), _))
           )).

guard_holds(zero(P), _, B) :- value(P, B, 0).
guard_holds(digit(P), Base, B) :- value(P, B, V), abs(V) < Base.
guard_holds(digits(P, D), Base, B) :- value(P, B, V), digit_count(V, Base, D).
guard_holds(multiple_of_base(P), Base, B) :- value(P, B, V), 0 =:= V mod Base.
guard_holds(lt(X, Y), Base, B) :- expr(X, Base, B, A), expr(Y, Base, B, C), A < C.
guard_holds(leq(X, Y), Base, B) :- expr(X, Base, B, A), expr(Y, Base, B, C), A =< C.
guard_holds(gt(X, Y), Base, B) :- expr(X, Base, B, A), expr(Y, Base, B, C), A > C.
guard_holds(geq(X, Y), Base, B) :- expr(X, Base, B, A), expr(Y, Base, B, C), A >= C.
guard_holds(eq(X, Y), Base, B) :- expr(X, Base, B, A), expr(Y, Base, B, C), A =:= C.
guard_holds(neq(X, Y), Base, B) :- expr(X, Base, B, A), expr(Y, Base, B, C), A =\\= C.
guard_holds(divides(X, Y), Base, B) :- expr(X, Base, B, A), expr(Y, Base, B, C), A =\\= 0, 0 =:= C mod A.
guard_holds(not_divides(X, Y), Base, B) :- expr(X, Base, B, A), expr(Y, Base, B, C), ( A =:= 0 -> true ; 0 =\\= C mod A ).
guard_holds(remainder(X, Y), Base, B) :- expr(X, Base, B, A), expr(Y, Base, B, C), C =\\= 0, 0 =\\= A mod C.
guard_holds(divides_one_way(X, Y), Base, B) :-
    expr(X, Base, B, A), expr(Y, Base, B, C),
    ( A =\\= 0, 0 =:= C mod A -> true ; C =\\= 0, 0 =:= A mod C ).
guard_holds(unit_fraction(Side), _, B) :- atom_concat(Side, '_n', P), value(P, B, 1).
guard_holds(whole_part_present, _, B) :-
    ( memberchk(left_whole-_, B) -> true ; memberchk(right_whole-_, B) ).
guard_holds(denominator_absent_on_one_side, _, B) :-
    ( \\+ memberchk(left_d-_, B) -> true ; \\+ memberchk(right_d-_, B) ).
guard_holds(scale_is_power_of_base(P), Base, B) :- value(P, B, V), power_of(V, Base).
guard_holds(no_relation_recorded, _, _).

value(Name, Bindings, Value) :- memberchk(Name-Value, Bindings).

expr(base, Base, _, Base) :- !.
expr(Number, _, _, Number) :- number(Number), !.
expr(ones(P), Base, B, V) :- !, value(P, B, X), V is abs(X) mod Base.
expr(plus(X, Y), Base, B, V) :- !, expr(X, Base, B, A), expr(Y, Base, B, C), V is A + C.
expr(max(X, Y), Base, B, V) :- !, expr(X, Base, B, A), expr(Y, Base, B, C), V is max(A, C).
expr(digits(P), Base, B, V) :- !, value(P, B, X), digit_count(X, Base, V).
expr(Name, _, B, V) :- value(Name, B, V).

digit_count(Value, Base, Digits) :-
    A is abs(truncate(Value)),
    (   A =:= 0
    ->  Digits = 1
    ;   digit_count_(A, Base, 0, Digits)
    ).

digit_count_(0, _, D, D) :- !.
digit_count_(N, Base, D0, D) :- D1 is D0 + 1, N1 is N // Base, digit_count_(N1, Base, D1, D).

power_of(Value, Base) :- Value >= 1, power_of_(Value, Base).
power_of_(1, _) :- !.
power_of_(V, Base) :- 0 =:= V mod Base, V1 is V // Base, power_of_(V1, Base).
'''


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="rebuild and report determinism")
    arguments = parser.parse_args()
    first = build()
    if arguments.check:
        before = PILOT.read_bytes()
        second = build()
        after = PILOT.read_bytes()
        first["byte_identical_rebuild"] = before == after
        first["index_stable"] = second["pilot_sha256"] == first["pilot_sha256"]
    print(json.dumps(first, indent=1, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
