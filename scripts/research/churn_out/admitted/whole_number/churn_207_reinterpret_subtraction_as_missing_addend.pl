% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(207)
% Citation: Clarke (2011)
% Documented error: solve 12-9 by asking what added to 9 makes 12
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=21; ExpectedCorrect=3
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_207_reinterpret_subtraction_as_missing_addend(A-B, Got) :-
    Got is B + A).

test_harness:arith_misconception(db_row(207), whole_number, churn_207_reinterpret_subtraction_as_missing_addend,
    churn_candidate:churn_207_reinterpret_subtraction_as_missing_addend,
    12-9,
    3).
