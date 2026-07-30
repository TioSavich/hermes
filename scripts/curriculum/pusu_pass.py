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
:- use_module(lessons('im/generated/compiled_receipt_routes')).
:- use_module(library(http/json)).
:- use_module(library(lists)).
:- use_module(library(time)).

% Measured bands: contract lookup takes 3.66--4.51s in known casualties;
% productive paths take 1.6--41s except the >45s magnitude wall.  All 235
% pre-179 contrast rows completed under the former two-second guard, so ten
% seconds isolates contrast and diagnosis failures without hiding them.
pusu_budget_seconds(contract_lookup, 30).
pusu_budget_seconds(productive_execution, 60).
pusu_budget_seconds(contrast_diagnosis, 10).

:- dynamic pusu_contract_memo/3.

pusu_text(Term, Text) :- term_string(Term, Text, [quoted(true), numbervars(true)]).
pusu_goal_text(Goal, Text) :- term_string(Goal, Text, [quoted(true), numbervars(true)]).
pusu_result(Outcome, Result) :- is_dict(Outcome), get_dict(result, Outcome, Result).
pusu_result(action_outcome(_, Fields), Result) :- member(result(Result), Fields).
pusu_operation_domain(addition, whole_number).
pusu_operation_domain(subtraction, whole_number).
pusu_operation_domain(multiplication, whole_number).
pusu_operation_domain(division, whole_number).
pusu_input(Left, Right, Left-Right).

pusu_call(Budget, Goal, Result) :-
    pusu_budget_seconds(Budget, Seconds),
    catch(
        ( call_with_time_limit(Seconds, call(Goal)) -> Result = succeeded ; Result = failed ),
        Error,
        pusu_call_exception(Error, Result)
    ).

pusu_call_exception(time_limit_exceeded, timed_out).
pusu_call_exception(error(time_limit_exceeded, _), timed_out).
pusu_call_exception(Error, failed(Failure)) :- pusu_text(Error, Failure).
pusu_failure(failed(Failure), Failure) :- !.
pusu_failure(_, "").
pusu_first_failure([Result|_], Failure) :-
    pusu_failure(Result, Failure), Failure \== "", !.
pusu_first_failure([_|Rest], Failure) :- pusu_first_failure(Rest, Failure).
pusu_first_failure([], "").
pusu_prefer_failure(First, _, First) :- First \== "", !.
pusu_prefer_failure(_, Second, Second).

pusu_registry_candidates(Code, Task, Candidates) :-
    findall(candidate(Goal, Outcome),
            ( activity_contract:task_action_operands(Task, Op, Left, Right),
              compiled_action_mappings:compiled_lesson_strategy(Code, Op, Kind, _),
              Goal = action_automata_registry:run_action_automaton(Op, Kind, Left, Right, Outcome, _) ),
            Candidates).

pusu_try_registry([], _, _, failed, []).
pusu_try_registry([candidate(CandidateGoal, CandidateOutcome)|Rest], Outcome, Goal, Result, Attempts) :-
    pusu_call(productive_execution, CandidateGoal, CandidateResult),
    ( CandidateResult == succeeded
    -> Outcome = CandidateOutcome, Goal = CandidateGoal, Result = succeeded, Attempts = [CandidateResult]
    ;  pusu_try_registry(Rest, Outcome, Goal, RestResult, RestAttempts),
       Attempts = [CandidateResult|RestAttempts],
       Result = RestResult
    ).

pusu_run_productive(Code, Task, Outcome, Goal, TimedOut, Failure) :-
    pusu_registry_candidates(Code, Task, RegistryCandidates),
    pusu_try_registry(RegistryCandidates, RegistryOutcome, RegistryGoal, RegistryResult, RegistryResults),
    ( RegistryResult == succeeded
    -> Outcome = RegistryOutcome, Goal = RegistryGoal, TimedOut = false, Failure = ""
    ;  Goal = activity_contract:activity_task_path(Code, Task, Outcome),
       pusu_call(productive_execution, Goal, PathResult),
       ( ( memberchk(timed_out, RegistryResults) ; PathResult == timed_out )
       -> TimedOut = true
       ;  TimedOut = false
       ),
       ( PathResult == succeeded -> true ; Outcome = unsupported{} ),
       pusu_failure(PathResult, PathFailure),
       pusu_first_failure(RegistryResults, RegistryFailure),
       pusu_prefer_failure(PathFailure, RegistryFailure, Failure)
    ), !.

pusu_productive(Code, Row) :-
    compiled_task_instances:compiled_lesson_task_instance(Code, productive-Task, _),
    pusu_run_productive(Code, Task, Outcome, Goal, TimedOut, Failure),
    pusu_text(Task, TaskText), pusu_goal_text(Goal, GoalText),
    ( pusu_result(Outcome, Result)
    -> pusu_text(Result, ResultText), Status = "runs"
    ;  ResultText = "", Status = "cannot_run"
    ),
    Row = _{task:TaskText, status:Status, result:ResultText, goal:GoalText,
            timed_out:TimedOut, failure:Failure}.

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

pusu_diagnosis_with_budget(Op, Left, Right, Wrong, Kind, Status, Detail, Surface, TimedOut, Failure) :-
    Goal = pusu_diagnosis(Op, Left, Right, Wrong, Kind, Status0, Detail0, Surface0),
    pusu_call(contrast_diagnosis, Goal, Result),
    ( Result == succeeded
    -> Status = Status0, Detail = Detail0, Surface = Surface0, TimedOut = false, Failure = ""
    ; Result == timed_out
    -> Status = "no_diagnosis", Detail = [], Surface = "timeout", TimedOut = true, Failure = ""
    ;  Status = "no_diagnosis", Detail = [], Surface = "none", TimedOut = false,
       pusu_failure(Result, Failure)
    ).

pusu_action_contrast(Code, Family, Task, Row) :-
    activity_contract:task_action_operands(Task, Op, Left, Right),
    Goal = activity_contract:deformation_task_path(Code, Family, Task, Outcome),
    pusu_goal_text(Goal, GoalText), pusu_text(Task, TaskText),
    pusu_call(contrast_diagnosis, Goal, CallResult),
    ( CallResult == succeeded, pusu_result(Outcome, Wrong),
      get_dict(deformation_kind, Outcome, Kind)
    -> pusu_text(Wrong, WrongText),
       ( pusu_run_productive(Code, Task, Productive, _, ProductiveTimedOut, _),
         pusu_result(Productive, Correct), Wrong =@= Correct
       -> ContrastStatus = "runs_vacuously", Diagnosis = "not_applicable",
          Detail = [], Surface = "none", TimedOut = ProductiveTimedOut, Failure = ""
       ;  ContrastStatus = "runs",
          pusu_diagnosis_with_budget(Op, Left, Right, Wrong, Kind, Diagnosis, Detail, Surface, TimedOut, Failure)
       )
    ;  Kind = Family, WrongText = "", ContrastStatus = "cannot_run",
       Diagnosis = "not_applicable", Detail = [], Surface = "none",
       ( CallResult == timed_out -> TimedOut = true ; TimedOut = false ),
       pusu_failure(CallResult, Failure)
    ),
    pusu_text(Kind, KindText),
    Row = _{kind:KindText, family:Family, task:TaskText, source:"compiled_deformation_task",
            status:ContrastStatus, wrong_answer:WrongText, diagnosis:Diagnosis,
            diagnosis_detail:Detail, diagnosis_surface:Surface, goal:GoalText,
            timed_out:TimedOut, failure:Failure}.

pusu_rule_contrast(Code, Obligation, Task, Row) :-
    Op = Obligation.operation, Kind = Obligation.kind,
    activity_contract:task_action_operands(Task, Op, Left, Right),
    pusu_operation_domain(Op, Domain), pusu_input(Left, Right, Input),
    test_harness:arith_misconception(_, Domain, Kind, Rule, _, _),
    pusu_run_productive(Code, Task, Productive, _, ProductiveTimedOut, _), pusu_result(Productive, Expected),
    Goal = test_harness:classify_arith_by_trace(Rule, Input, Expected, Class, Evidence),
    pusu_goal_text(Goal, GoalText), pusu_text(Task, TaskText), pusu_text(Kind, KindText),
    pusu_call(contrast_diagnosis, Goal, CallResult),
    ( CallResult == succeeded
    -> ( Class == wrong_answer
       -> pusu_text(Evidence, WrongText), ContrastStatus = "runs",
          pusu_diagnosis_with_budget(Op, Left, Right, Evidence, Kind, Diagnosis, Detail, Surface, DiagnosisTimedOut, Failure),
          ( ( ProductiveTimedOut == true ; DiagnosisTimedOut == true ) -> TimedOut = true ; TimedOut = false )
       ;  pusu_text(Evidence, WrongText), ContrastStatus = "runs_vacuously",
          Diagnosis = "not_applicable", Detail = [], Surface = "none", TimedOut = ProductiveTimedOut, Failure = ""
       )
    ;  WrongText = "", ContrastStatus = "cannot_run", Diagnosis = "not_applicable",
       Detail = [], Surface = "none",
       ( ( CallResult == timed_out ; ProductiveTimedOut == true ) -> TimedOut = true ; TimedOut = false ),
       pusu_failure(CallResult, Failure)
    ),
    Row = _{kind:KindText, family:KindText, task:TaskText, source:"registered_misconception_rule",
            status:ContrastStatus, wrong_answer:WrongText, diagnosis:Diagnosis,
            diagnosis_detail:Detail, diagnosis_surface:Surface, goal:GoalText,
            timed_out:TimedOut, failure:Failure}.

pusu_receipt_contrast(Code, Op, AltKind, Family, Task, Row) :-
    compiled_receipt_routes:receipt_contrast_route(Code, Op, AltKind, Family, Task, _),
    activity_contract:task_action_operands(Task, Op, Left, Right),
    Goal = action_automata_registry:run_action_automaton(Op, AltKind, Left, Right, Outcome, _),
    pusu_goal_text(Goal, GoalText), pusu_text(Task, TaskText), pusu_text(AltKind, KindText),
    pusu_call(contrast_diagnosis, Goal, CallResult),
    ( CallResult == succeeded, pusu_result(Outcome, Wrong)
    -> pusu_text(Wrong, WrongText),
       ( pusu_run_productive(Code, Task, Productive, _, ProductiveTimedOut, _),
         pusu_result(Productive, Correct), Wrong =@= Correct
       -> ContrastStatus = "runs_vacuously", Diagnosis = "not_applicable",
          Detail = [], Surface = "none", TimedOut = ProductiveTimedOut, Failure = ""
       ;  ContrastStatus = "runs",
          pusu_diagnosis_with_budget(Op, Left, Right, Wrong, AltKind, Diagnosis, Detail, Surface, TimedOut, Failure)
       )
    ;  WrongText = "", ContrastStatus = "cannot_run", Diagnosis = "not_applicable",
       Detail = [], Surface = "none",
       ( CallResult == timed_out -> TimedOut = true ; TimedOut = false ),
       pusu_failure(CallResult, Failure)
    ),
    Row = _{kind:KindText, family:Family, task:TaskText, source:"receipt_contrast_route",
            status:ContrastStatus, wrong_answer:WrongText, diagnosis:Diagnosis,
            diagnosis_detail:Detail, diagnosis_surface:Surface, goal:GoalText,
            timed_out:TimedOut, failure:Failure}.

pusu_receipt_defect(Code, Row) :-
    compiled_receipt_routes:receipt_route_defect(Code, Op, ProductiveKind, AltKind, Reason),
    pusu_text(AltKind, KindText), pusu_text(Reason, ReasonText),
    Row = _{kind:KindText, family:AltKind, task:"", source:"receipt_route_defect",
            status:"cannot_run", wrong_answer:"", diagnosis:"not_applicable",
            diagnosis_detail:[], diagnosis_surface:"none", goal:"", timed_out:false, failure:"",
            operation:Op, productive_kind:ProductiveKind, route_defect:ReasonText}.

pusu_contract_obligations(Code, Obligations, TimedOut, Failure) :-
    pusu_contract_memo(Code, Obligations, TimedOut-Failure), !.
pusu_contract_obligations(Code, Obligations, TimedOut, Failure) :-
    Goal = lesson_activity_contract(Code, Contract),
    pusu_call(contract_lookup, Goal, Result),
    ( Result == succeeded
    -> Obligations = Contract.misconception_obligations, TimedOut = false, Failure = ""
    ;  Obligations = [], ( Result == timed_out -> TimedOut = true ; TimedOut = false ),
       pusu_failure(Result, Failure)
    ),
    asserta(pusu_contract_memo(Code, Obligations, TimedOut-Failure)).

pusu_contract_timeout_row(Row) :-
    Row = _{kind:"lesson_activity_contract", family:"lesson_activity_contract",
            task:"", source:"lesson_activity_contract", status:"cannot_run",
            wrong_answer:"", diagnosis:"not_applicable", diagnosis_detail:[],
            diagnosis_surface:"timeout", goal:"lesson_activity_contract/2",
            timed_out:true, failure:""}.

pusu_contract_failure_row(Failure, Row) :-
    Row = _{kind:"lesson_activity_contract", family:"lesson_activity_contract",
            task:"", source:"lesson_activity_contract", status:"cannot_run",
            wrong_answer:"", diagnosis:"not_applicable", diagnosis_detail:[],
            diagnosis_surface:"none", goal:"lesson_activity_contract/2",
            timed_out:false, failure:Failure}.

pusu_contrasts(Code, Rows) :-
    findall(Row,
            ( compiled_task_instances:compiled_lesson_task_instance(Code, deformation(Family)-Task, _),
              pusu_action_contrast(Code, Family, Task, Row) ), ActionRows),
    pusu_contract_obligations(Code, Obligations, ContractTimedOut, ContractFailure),
    findall(Row,
            ( member(Obligation, Obligations),
              Op = Obligation.operation,
              compiled_task_instances:compiled_lesson_task_instance(Code, productive-Task, _),
              pusu_rule_contrast(Code, Obligation, Task, Row) ), RuleRows),
    findall(Row,
            pusu_receipt_contrast(Code, _, _, _, _, Row), ReceiptRows),
    findall(Row, pusu_receipt_defect(Code, Row), ReceiptDefectRows),
    ( ContractTimedOut == true -> pusu_contract_timeout_row(ContractTimeoutRow), ContractTimeoutRows = [ContractTimeoutRow] ; ContractTimeoutRows = [] ),
    ( ContractFailure \== "" -> pusu_contract_failure_row(ContractFailure, ContractFailureRow), ContractFailureRows = [ContractFailureRow] ; ContractFailureRows = [] ),
    append([ActionRows, RuleRows, ReceiptRows, ReceiptDefectRows, ContractTimeoutRows, ContractFailureRows], All), sort(All, Rows).

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


def run_engine(lessons: list[str], productive_budget: int | None = None) -> list[dict]:
    runner = PROLOG_RUNNER
    if productive_budget is not None:
        runner = runner.replace(
            "pusu_budget_seconds(productive_execution, 60).",
            f"pusu_budget_seconds(productive_execution, {productive_budget}).",
            1,
        )
    program = runner + "\n:- pusu_main(" + prolog_list(lessons) + "), halt.\n"
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
    parser.add_argument("--productive-budget", type=int, metavar="SECONDS", help="override the productive budget for a focused regression run")
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
    if args.productive_budget is not None and args.productive_budget < 1:
        parser.error("--productive-budget must be positive")
    lessons = args.lesson or (list(CALIBRATION) if args.calibration else diagnostic_ready_lessons())
    if args.first is not None:
        if args.first < 1:
            parser.error("--first must be positive")
        lessons = diagnostic_ready_lessons()[args.offset:args.offset + args.first]
    elif args.offset:
        parser.error("--offset requires --first")
    start = time.monotonic()
    rows = run_engine(lessons, productive_budget=args.productive_budget)
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
