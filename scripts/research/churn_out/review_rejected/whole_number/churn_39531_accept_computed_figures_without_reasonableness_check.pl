% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(39531)
% Review reason: rejected in Task 69 semantic review; no distinct executable misconception was established.
% Citation: ADRIAN TREFFERS (1991)
% Documented error: treat any number produced or stated as a valid cipher without checking it against real-world magnitude
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=1000000; ExpectedCorrect=1
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_39531_accept_computed_figures_without_reasonableness_check(A-B, Got) :-
    Got is A * B).

test_harness:arith_misconception(db_row(39531), whole_number, churn_39531_accept_computed_figures_without_reasonableness_check,
    churn_candidate:churn_39531_accept_computed_figures_without_reasonableness_check,
    1000-1000,
    1).
