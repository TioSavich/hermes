% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(40326)
% Citation: Raisa Guberman (2016)
% Documented error: every division must come out evenly with nothing left over
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=3; ExpectedCorrect=2
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_40326_division_always_yields_no_remainder(A-B, Got) :-
    Got is A // B).

test_harness:arith_misconception(db_row(40326), whole_number, churn_40326_division_always_yields_no_remainder,
    churn_candidate:churn_40326_division_always_yields_no_remainder,
    17-5,
    2).
