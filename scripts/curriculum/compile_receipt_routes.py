#!/usr/bin/env python3
"""Compile validated negative receipts into runnable contrast routes.

The receipt register establishes source-backed material incompatibility.  This
compiler separately asks SWI-Prolog whether that cited alternative can run on
the lesson's already compiled productive operands.  A receipt that cannot bind
is retained as a first-class defect fact rather than being dropped.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from collections import Counter
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.curriculum.build_lesson_evidence import (  # noqa: E402
    COMPILED_MAPPINGS,
    COMPILED_STRATEGY_MAPPING_RE,
    DIRECT_STRATEGY_MAPPING_RE,
    SPINE,
    _merge_mappings,
    _strategy_mappings,
    _validated_negative_receipts,
)


OUTPUT = ROOT / "curriculum/im/generated/compiled_receipt_routes.pl"
# Measured verification found every current semantic refusal fail in under a
# hundredth of a second even with a 60-second limit; two seconds bounds a new
# route without relabelling an overrun as a refusal.
ROUTE_TIMEOUT_SECONDS = 2


# One SWI process resolves the registry pair, joins compiled productive tasks,
# and tests every operand pair.  JSON is transport only: the generated facts
# below are rendered from these engine-owned terms, never from receipt prose.
PROLOG_BATCH = rf'''
:- use_module(formal(learner/activity_contract)).
:- use_module(strategies('math/action_automata_registry')).
:- use_module(library(http/json)).
:- use_module(library(lists)).
:- use_module(library(time)).

route_timeout_seconds({ROUTE_TIMEOUT_SECONDS}).

term_text(Term, Text) :- term_string(Term, Text, [quoted(true), numbervars(true)]).
emit(Tag, Row) :- write(Tag), write('\t'), json_write_dict(current_output, Row, [width(1000000)]), nl.

route_attempt(Op, Alternative, Left, Right, Result) :-
    route_timeout_seconds(Limit),
    catch(
        ( call_with_time_limit(Limit,
              action_automata_registry:run_action_automaton(Op, Alternative, Left, Right, _, _))
        -> Result = succeeded
        ;  Result = failed
        ),
        Error,
        route_attempt_exception(Error, Result)
    ).

route_attempt_exception(time_limit_exceeded, timed_out).
route_attempt_exception(error(time_limit_exceeded, _), timed_out).
route_attempt_exception(_, errored).

receipt_routes(Id, Lesson, Op, Productive, Alternative) :-
    ( action_automata_registry:action_automaton_pair(Op, Productive, Alternative, Family)
    -> findall(task(Task, Left, Right),
               ( compiled_task_instances:compiled_lesson_task_instance(Lesson, productive-Task, _),
                 activity_contract:task_action_operands(Task, Op, Left, Right) ),
               Tasks0),
       sort(Tasks0, Tasks),
       ( Tasks = []
       -> emit('DEFECT', _{{id:Id, reason:"no_task_with_receipt_operation", operands:[]}})
       ;  findall(attempt(Task, Left, Right, Result),
                  ( member(task(Task, Left, Right), Tasks),
                    route_attempt(Op, Alternative, Left, Right, Result) ),
                  Attempts),
          findall(task(Task, Left, Right),
                  member(attempt(Task, Left, Right, succeeded), Attempts), Runnable0),
          sort(Runnable0, Runnable),
          ( Runnable = []
          -> findall(Left-Right, member(task(_, Left, Right), Tasks), OperandPairs0),
             sort(OperandPairs0, OperandPairs),
             findall(PairText, ( member(Pair, OperandPairs), term_text(Pair, PairText) ), OperandTexts),
             ( member(attempt(_, _, _, errored), Attempts)
             -> Reason = "automaton_errors_operands"
             ; member(attempt(_, _, _, timed_out), Attempts)
             -> Reason = "automaton_times_out_operands"
             ;  Reason = "automaton_refuses_operands"
             ),
             emit('DEFECT', _{{id:Id, reason:Reason, operands:OperandTexts}})
          ;  forall(member(task(Task, _, _), Runnable),
                     ( term_text(Task, TaskText),
                       emit('ROUTE', _{{id:Id, family:Family, task:TaskText}}) ))
          )
       )
    ;  emit('DEFECT', _{{id:Id, reason:"alternative_not_in_registry", operands:[]}})
    ).

receipt_batch([]).
receipt_batch([receipt(Id, Lesson, Op, Productive, Alternative)|Rest]) :-
    receipt_routes(Id, Lesson, Op, Productive, Alternative),
    receipt_batch(Rest).
'''


def _prolog_atom(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "\\'") + "'"


def _prolog_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def _source_terms(receipt: dict[str, Any]) -> list[tuple[str, str]]:
    """Return every validated citation without inventing lines for fact sources."""
    source = receipt["source"]
    path = _prolog_atom(source["path"])
    if source.get("kind", "file") == "fact":
        return [
            (f"source({path}, predicate({_prolog_atom(fragment['predicate'])}))",
             _prolog_string(fragment["text"]))
            for fragment in source["fragments"]
        ]
    return [
        (f"source({path}, line({fragment['line']}))", _prolog_string(fragment["text"]))
        for fragment in source["fragments"]
    ]


def validated_receipts() -> list[dict[str, Any]]:
    spine = json.loads(SPINE.read_text(encoding="utf-8"))
    grade_sources = sorted((ROOT / "curriculum/im").glob("grade_*.pl"))
    mappings = _merge_mappings(
        _strategy_mappings(grade_sources, DIRECT_STRATEGY_MAPPING_RE, "direct_lesson_fact"),
        _strategy_mappings(
            [COMPILED_MAPPINGS], COMPILED_STRATEGY_MAPPING_RE,
            "compiled_source_mapping",
        ),
    )
    index = _validated_negative_receipts({row["repo_id"] for row in spine}, mappings)
    return sorted(
        (receipt for rows in index.values() for receipt in rows),
        key=lambda receipt: (receipt["lesson"], receipt["alternative"]),
    )


def run_batch(receipts: list[dict[str, Any]]) -> dict[int, list[dict[str, Any]]]:
    inputs = []
    for index, receipt in enumerate(receipts):
        intended = receipt["intended_action"]
        inputs.append(
            "receipt("
            f"{index}, {_prolog_atom(receipt['lesson'])}, {intended['operation']}, "
            f"{intended['kind']}, {receipt['alternative']})"
        )
    program = PROLOG_BATCH + "\n:- receipt_batch([" + ",".join(inputs) + "]), halt.\n"
    result = subprocess.run(
        ["swipl", "-q", "-l", str(ROOT / "paths.pl"), "-g", "consult(user),halt"],
        cwd=ROOT,
        input=program,
        text=True,
        capture_output=True,
        check=False,
        timeout=10 * 60,
    )
    if result.returncode:
        raise RuntimeError(f"SWI-Prolog failed ({result.returncode}):\n{result.stderr.strip()}")
    rows: dict[int, list[dict[str, Any]]] = {}
    for line in result.stdout.splitlines():
        if not (line.startswith("ROUTE\t") or line.startswith("DEFECT\t")):
            continue
        tag, payload = line.split("\t", 1)
        row = json.loads(payload)
        row["tag"] = tag
        rows.setdefault(row["id"], []).append(row)
    missing = [str(index) for index in range(len(receipts)) if index not in rows]
    if missing:
        raise RuntimeError("SWI-Prolog emitted no route or defect for receipt ids: " + ", ".join(missing))
    return rows


def render(receipts: list[dict[str, Any]], engine_rows: dict[int, list[dict[str, Any]]]) -> tuple[str, Counter[str]]:
    routes: list[str] = []
    defects: list[str] = []
    summary: Counter[str] = Counter()
    for index, receipt in enumerate(receipts):
        rows = engine_rows[index]
        route_rows = [row for row in rows if row["tag"] == "ROUTE"]
        defect_rows = [row for row in rows if row["tag"] == "DEFECT"]
        if bool(route_rows) == bool(defect_rows):
            raise RuntimeError(
                f"receipt invariant failed for {(receipt['lesson'], receipt['alternative'])}: "
                "expected routes xor one defect"
            )
        intended = receipt["intended_action"]
        if route_rows:
            summary["route_receipts"] += 1
            for row in route_rows:
                source_terms = _source_terms(receipt)
                primary_source, primary_excerpt = source_terms[0]
                citations = ", ".join(
                    f"citation({source_term}, excerpt({excerpt}))"
                    for source_term, excerpt in source_terms
                )
                evidence = (
                    f"receipt_evidence(intended({intended['operation']}, {intended['kind']}), "
                    f"{primary_source}, excerpt({primary_excerpt}), citations([{citations}]))"
                )
                routes.append(
                    "receipt_contrast_route("
                    f"{_prolog_atom(receipt['lesson'])}, {intended['operation']}, "
                    f"{receipt['alternative']}, {row['family']}, {row['task']},\n"
                    f"                       {evidence})."
                )
        else:
            summary["defect_receipts"] += 1
            defect = defect_rows[0]
            reason = defect["reason"]
            summary[reason] += 1
            if reason in {
                "automaton_refuses_operands",
                "automaton_times_out_operands",
                "automaton_errors_operands",
            }:
                reason_term = "automaton_refuses_operands([" + ", ".join(defect["operands"]) + "])"
            else:
                reason_term = reason
            defects.append(
                "receipt_route_defect("
                f"{_prolog_atom(receipt['lesson'])}, {intended['operation']}, "
                f"{intended['kind']}, {receipt['alternative']}, {reason_term})."
            )
    if summary["route_receipts"] + summary["defect_receipts"] != len(receipts):
        raise RuntimeError("receipt coverage invariant failed")
    lines = [
        "/** <module> Generated verified receipt contrast routes", " *",
        " * Generated by scripts/curriculum/compile_receipt_routes.py.",
        " * Each route has executed on its compiled productive operands; each",
        " * unbindable receipt remains an explicit defect fact.",
        " */",
        ":- module(compiled_receipt_routes,",
        "          [ receipt_contrast_route/6,",
        "            receipt_route_defect/5,",
        "            receipt_route_summary/2",
        "          ]).",
        "",
        f"receipt_route_summary({summary['route_receipts']}, {summary['defect_receipts']}).",
        "",
        *routes,
        "",
        *defects,
        "",
    ]
    return "\n".join(lines), summary


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="fail when the generated route artifact is stale")
    args = parser.parse_args()
    receipts = validated_receipts()
    rendered, summary = render(receipts, run_batch(receipts))
    if args.check:
        current = OUTPUT.read_text(encoding="utf-8") if OUTPUT.exists() else ""
        if current != rendered:
            print(f"stale generated receipt routes: {OUTPUT.relative_to(ROOT)}", file=sys.stderr)
            return 1
    else:
        OUTPUT.write_text(rendered, encoding="utf-8")
    print(
        f"receipts={len(receipts)} route_receipts={summary['route_receipts']} "
        f"defect_receipts={summary['defect_receipts']} "
        f"alternative_not_in_registry={summary['alternative_not_in_registry']} "
        f"no_task_with_receipt_operation={summary['no_task_with_receipt_operation']} "
        f"automaton_refuses_operands={summary['automaton_refuses_operands']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
