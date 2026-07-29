#!/usr/bin/env python3
"""Engine-only put-up-or-shut-up pass for diagnostic-ready IM lessons.

The script reads the generated lesson ledger and asks one local SWI-Prolog
process to execute the compiled task routes.  It never interprets lesson prose:
all inputs, routes, contrast rules, and verdict evidence come from existing
compiled facts and engine predicates.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
LEDGER = ROOT / "data/learningcommons/derived/im_lesson_evidence.json"
OUTPUT = ROOT / "data/learningcommons/derived/pusu_pass.json"
OUTPUT_PL = ROOT / "data/learningcommons/derived/pusu_pass.pl"
CALIBRATION = (
    "IM-G1-U5-L5", "IM-G2-U9-L1", "IM-G4-U5-L3",
    "IM-G5-U4-L5", "IM-G2-U7-L15", "IM-G7-U5-L1", "IM-GK-U5-L7",
)


# This is intentionally a stdin program, not a checked-in second runner: the
# public artifact remains a compact fact file and the only implementation is
# this script.  Every predicate below delegates to an already loaded engine
# surface; it adds no mathematics or diagnosis rules of its own.
PROLOG_RUNNER = r'''
:- use_module(formal(learner/activity_contract)).
:- use_module(misconceptions(test_harness)).
:- use_module(library(http/json)).
:- use_module(library(lists)).
:- use_module(library(time)).

pusu_text(Term, Text) :- term_string(Term, Text, [quoted(true), numbervars(true)]).
pusu_goal_text(Goal, Text) :- term_string(Goal, Text, [quoted(true), numbervars(true)]).
pusu_result(Outcome, Result) :- is_dict(Outcome), get_dict(result, Outcome, Result).
pusu_result(action_outcome(_, Fields), Result) :- member(result(Result), Fields).
pusu_operation_domain(addition, whole_number).
pusu_operation_domain(subtraction, whole_number).
pusu_operation_domain(multiplication, whole_number).
pusu_operation_domain(division, whole_number).
pusu_input(Left, Right, Left-Right).

pusu_run_productive(Code, Task, Outcome, Goal) :-
    activity_contract:task_action_operands(Task, Op, Left, Right),
    compiled_action_mappings:compiled_lesson_strategy(Code, Op, Kind, _),
    Goal = action_automata_registry:run_action_automaton(Op, Kind, Left, Right, Outcome, _),
    catch(call_with_time_limit(2, call(Goal)), _, fail), !.
pusu_run_productive(Code, Task, Outcome, Goal) :-
    Goal = activity_contract:activity_task_path(Code, Task, Outcome),
    catch(call_with_time_limit(2, call(Goal)), _, fail), !.

pusu_productive(Code, Row) :-
    compiled_task_instances:compiled_lesson_task_instance(Code, productive-Task, _),
    ( pusu_run_productive(Code, Task, Outcome, Goal) -> true ; Outcome = unsupported{} ),
    pusu_text(Task, TaskText), pusu_goal_text(Goal, GoalText),
    ( pusu_result(Outcome, Result)
    -> pusu_text(Result, ResultText), Status = "runs"
    ;  ResultText = "", Status = "cannot_run"
    ),
    Row = _{task:TaskText, status:Status, result:ResultText, goal:GoalText}.

pusu_public_diagnosis(Domain, Input, Wrong, Kind, Status, Detail) :-
    findall(Description,
            ( test_harness:diagnose_error(Domain, Input, Wrong, Match),
              Description = Match.description ), Descriptions0),
    sort(Descriptions0, Descriptions),
    ( memberchk(Kind, Descriptions)
    -> Status = "recovered", Detail = Descriptions
    ; Descriptions = []
    -> Status = "no_diagnosis", Detail = []
    ;  Status = "recovered_different_error", Detail = Descriptions
    ).

% The action registry is a second existing diagnostic surface.  It is used only
% after diagnose_error/4 has no answer, and records that fallback explicitly.
pusu_inverse_action_diagnosis(Op, Left, Right, Wrong, Kind, Status, Detail) :-
    findall(Candidate,
            ( action_automata_registry:action_automaton_pair(Op, _, Candidate, _),
              catch(action_automata_registry:run_action_automaton(
                        Op, Candidate, Left, Right, Outcome, _), _, fail),
              pusu_result(Outcome, CandidateResult), CandidateResult =@= Wrong ),
            Candidates0),
    sort(Candidates0, Candidates),
    ( memberchk(Kind, Candidates)
    -> Status = "recovered", Detail = Candidates
    ; Candidates = []
    -> Status = "no_diagnosis", Detail = []
    ;  Status = "recovered_different_error", Detail = Candidates
    ).

pusu_diagnosis(Op, Left, Right, Wrong, Kind, Status, Detail, Surface) :-
    pusu_operation_domain(Op, Domain), pusu_input(Left, Right, Input),
    pusu_public_diagnosis(Domain, Input, Wrong, Kind, PublicStatus, PublicDetail),
    ( PublicStatus == "no_diagnosis"
    -> pusu_inverse_action_diagnosis(Op, Left, Right, Wrong, Kind, Status, Detail),
       Surface = "action_automaton_inverse"
    ;  Status = PublicStatus, Detail = PublicDetail, Surface = "diagnose_error"
    ), !.
pusu_diagnosis(_, _, _, _, _, "no_diagnosis", [], "unavailable").

pusu_action_contrast(Code, Family, Task, Row) :-
    activity_contract:task_action_operands(Task, Op, Left, Right),
    Goal = activity_contract:deformation_task_path(Code, Family, Task, Outcome),
    pusu_goal_text(Goal, GoalText), pusu_text(Task, TaskText),
    ( catch(call_with_time_limit(2, call(Goal)), _, fail), pusu_result(Outcome, Wrong),
      get_dict(deformation_kind, Outcome, Kind)
    -> pusu_text(Wrong, WrongText),
       ( pusu_run_productive(Code, Task, Productive, _),
         pusu_result(Productive, Correct), Wrong =@= Correct
       -> ContrastStatus = "runs_vacuously", Diagnosis = "not_applicable",
          Detail = [], Surface = "none"
       ;  ContrastStatus = "runs",
          pusu_diagnosis(Op, Left, Right, Wrong, Kind, Diagnosis, Detail, Surface)
       )
    ;  Kind = Family, WrongText = "", ContrastStatus = "cannot_run",
       Diagnosis = "not_applicable", Detail = [], Surface = "none"
    ),
    pusu_text(Kind, KindText),
    Row = _{kind:KindText, family:Family, task:TaskText, source:"compiled_deformation_task",
            status:ContrastStatus, wrong_answer:WrongText, diagnosis:Diagnosis,
            diagnosis_detail:Detail, diagnosis_surface:Surface, goal:GoalText}.

pusu_rule_contrast(Code, Obligation, Task, Row) :-
    Op = Obligation.operation, Kind = Obligation.kind,
    activity_contract:task_action_operands(Task, Op, Left, Right),
    pusu_operation_domain(Op, Domain), pusu_input(Left, Right, Input),
    test_harness:arith_misconception(_, Domain, Kind, Rule, _, _),
    pusu_run_productive(Code, Task, Productive, _), pusu_result(Productive, Expected),
    Goal = test_harness:classify_arith_by_trace(Rule, Input, Expected, Class, Evidence),
    pusu_goal_text(Goal, GoalText), pusu_text(Task, TaskText), pusu_text(Kind, KindText),
    ( catch(call_with_time_limit(2, call(Goal)), _, fail)
    -> ( Class == wrong_answer
       -> pusu_text(Evidence, WrongText), ContrastStatus = "runs",
          pusu_diagnosis(Op, Left, Right, Evidence, Kind, Diagnosis, Detail, Surface)
       ;  pusu_text(Evidence, WrongText), ContrastStatus = "runs_vacuously",
          Diagnosis = "not_applicable", Detail = [], Surface = "none"
       )
    ;  WrongText = "", ContrastStatus = "cannot_run", Diagnosis = "not_applicable",
       Detail = [], Surface = "none"
    ),
    Row = _{kind:KindText, family:KindText, task:TaskText, source:"registered_misconception_rule",
            status:ContrastStatus, wrong_answer:WrongText, diagnosis:Diagnosis,
            diagnosis_detail:Detail, diagnosis_surface:Surface, goal:GoalText}.

pusu_contrasts(Code, Rows) :-
    findall(Row,
            ( compiled_task_instances:compiled_lesson_task_instance(Code, deformation(Family)-Task, _),
              pusu_action_contrast(Code, Family, Task, Row) ), ActionRows),
    ( catch(call_with_time_limit(2, lesson_activity_contract(Code, Contract)), _, fail)
    -> Obligations = Contract.misconception_obligations
    ;  Obligations = []
    ),
    findall(Row,
            ( member(Obligation, Obligations),
              Op = Obligation.operation,
              compiled_task_instances:compiled_lesson_task_instance(Code, productive-Task, _),
              pusu_rule_contrast(Code, Obligation, Task, Row) ), RuleRows),
    append(ActionRows, RuleRows, All), sort(All, Rows).

pusu_verdict(Productive, Contrasts, Verdict, Detail) :-
    ( Productive = []
    -> Verdict = "broken(no_instances)", Detail = "no compiled productive task instance"
    ; member(Row, Productive), Row.status == "cannot_run"
    -> Verdict = "broken(execute_mismatch)", Detail = "a productive task did not execute"
    ; Contrasts = []
    -> Verdict = "broken(contrast_cannot_run)", Detail = "no attached executable contrast route"
    ; member(Row, Contrasts), Row.status == "cannot_run"
    -> Verdict = "broken(contrast_cannot_run)", Detail = "an attached contrast could not run"
    ; member(Row, Contrasts), Row.status == "runs_vacuously"
    -> Verdict = "broken(contrast_vacuous)", Detail = "a contrast returned the productive value"
    ; member(Row, Contrasts), Row.diagnosis == "no_diagnosis"
    -> Verdict = "broken(diagnosis_missed)", Detail = "a wrong contrast answer was not recovered"
    ; member(Row, Contrasts), Row.diagnosis == "recovered_different_error"
    -> Verdict = "broken(diagnosis_wrong_error)", Detail = "a wrong contrast answer recovered another error"
    ; Verdict = "pass", Detail = "all compiled productive and contrast routes ran and recovered"
    ).

pusu_lesson(Code, Row) :-
    findall(Productive, pusu_productive(Code, Productive), ProductiveRows),
    pusu_contrasts(Code, ContrastRows),
    pusu_verdict(ProductiveRows, ContrastRows, Verdict, Detail),
    Row = _{lesson:Code, pusu:Verdict, detail:Detail,
            productive:ProductiveRows, contrasts:ContrastRows}.

pusu_main([]).
pusu_main([Code|Rest]) :-
    pusu_lesson(Code, Row), write('PUSU\t'), json_write_dict(current_output, Row, [width(1000000)]), nl,
    flush_output, pusu_main(Rest).
'''


def diagnostic_ready_lessons() -> list[str]:
    ledger = json.loads(LEDGER.read_text(encoding="utf-8"))
    return [row["lesson"] for row in ledger["lessons"] if row["readiness"] == "diagnostic_ready"]


def prolog_list(lessons: list[str]) -> str:
    return "[" + ",".join(repr(lesson).replace('"', "'") for lesson in lessons) + "]"


def run_engine(lessons: list[str]) -> list[dict]:
    program = PROLOG_RUNNER + "\n:- pusu_main(" + prolog_list(lessons) + "), halt.\n"
    proc = subprocess.run(
        ["swipl", "-q", "-l", str(ROOT / "paths.pl"), "-g", "consult(user),halt"],
        cwd=ROOT,
        input=program,
        text=True,
        capture_output=True,
        check=False,
        timeout=20 * 60,
    )
    if proc.returncode:
        raise RuntimeError(f"SWI-Prolog failed ({proc.returncode}):\n{proc.stderr.strip()}")
    rows = []
    for line in proc.stdout.splitlines():
        if line.startswith("PUSU\t"):
            try:
                rows.append(json.loads(line.split("\t", 1)[1]))
            except json.JSONDecodeError as exc:
                raise RuntimeError(f"invalid engine JSON: {line}") from exc
    if len(rows) != len(lessons):
        raise RuntimeError(
            f"SWI-Prolog returned {len(rows)} rows for {len(lessons)} lessons.\n{proc.stderr.strip()}"
        )
    return rows


def stage(verdict: str) -> str:
    if verdict == "pass":
        return "pass"
    return verdict.removeprefix("broken(").removesuffix(")")


def compact_prolog(rows: list[dict]) -> str:
    lines = ["% Generated by scripts/curriculum/pusu_pass.py; do not edit.",
             ":- module(pusu_pass, [pusu/2]).", ""]
    for row in rows:
        lesson = row["lesson"].replace("'", "\\'")
        verdict = row["pusu"]
        if verdict == "pass":
            term = "pass"
        else:
            term = "broken(" + stage(verdict) + ", " + repr(row["detail"]).replace('"', "'") + ")"
        lines.append(f"pusu('{lesson}', {term}).")
    return "\n".join(lines) + "\n"


def payload(rows: list[dict], elapsed: float, selected: list[str]) -> dict:
    distribution = Counter(stage(row["pusu"]) for row in rows)
    return {
        "schema": "pusu_pass_v1",
        "register": "put up or shut up: engine-only execution, contrast, and diagnosis pass",
        "scope": {"diagnostic_ready_lessons": len(selected), "lessons": selected},
        "timing_seconds": round(elapsed, 3),
        "verdict_distribution": dict(sorted(distribution.items())),
        "rows": rows,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--calibration", action="store_true", help="run the seven audited lessons only")
    parser.add_argument("--lesson", action="append", metavar="ID", help="run one named lesson (repeatable)")
    parser.add_argument("--first", type=int, metavar="N", help="run the first N diagnostic-ready lessons")
    parser.add_argument("--offset", type=int, default=0, metavar="N", help="skip N diagnostic-ready lessons before --first")
    parser.add_argument("--merge", action="append", metavar="JSON", help="merge prior --stdout batch documents and write artifacts")
    parser.add_argument("--stdout", action="store_true", help="emit JSON without writing artifacts")
    args = parser.parse_args()
    if args.merge:
        if args.calibration or args.lesson or args.first or args.offset or args.stdout:
            parser.error("--merge is only for writing prior batch documents")
        documents = [json.loads(Path(path).read_text(encoding="utf-8")) for path in args.merge]
        rows = [row for document in documents for row in document["rows"]]
        lessons = [lesson for document in documents for lesson in document["scope"]["lessons"]]
        document = payload(rows, sum(item["timing_seconds"] for item in documents), lessons)
        OUTPUT.write_text(json.dumps(document, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        OUTPUT_PL.write_text(compact_prolog(rows), encoding="utf-8")
        print(f"wrote {OUTPUT.relative_to(ROOT)} ({len(rows)} lessons, {document['timing_seconds']}s)")
        return 0
    if args.lesson and (args.first or args.offset):
        parser.error("--lesson and --first cannot be combined")
    lessons = args.lesson or (list(CALIBRATION) if args.calibration else diagnostic_ready_lessons())
    if args.first is not None:
        if args.first < 1:
            parser.error("--first must be positive")
        lessons = diagnostic_ready_lessons()[args.offset:args.offset + args.first]
    elif args.offset:
        parser.error("--offset requires --first")
    start = time.monotonic()
    rows = run_engine(lessons)
    document = payload(rows, time.monotonic() - start, lessons)
    if args.stdout:
        json.dump(document, sys.stdout, indent=2, sort_keys=True)
        sys.stdout.write("\n")
    else:
        OUTPUT.write_text(json.dumps(document, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        OUTPUT_PL.write_text(compact_prolog(rows), encoding="utf-8")
        print(f"wrote {OUTPUT.relative_to(ROOT)} ({len(rows)} lessons, {document['timing_seconds']}s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
