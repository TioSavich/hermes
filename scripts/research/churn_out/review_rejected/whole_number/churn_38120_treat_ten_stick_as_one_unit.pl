% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(38120)
% Review reason: rejected in Task 69 semantic review; no distinct executable misconception was established.
% Citation: Mike Askew (2018)
% Documented error: count a ten-stick as a single object rather than as ten ones
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=10; ExpectedCorrect=1
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_38120_treat_ten_stick_as_one_unit(A, Got) :-
    Got is A).

test_harness:arith_misconception(db_row(38120), whole_number, churn_38120_treat_ten_stick_as_one_unit,
    churn_candidate:churn_38120_treat_ten_stick_as_one_unit,
    10,
    1).
