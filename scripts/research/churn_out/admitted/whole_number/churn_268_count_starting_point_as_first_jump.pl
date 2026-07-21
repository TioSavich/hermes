% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(268)
% Citation: Galbraith (1975)
% Documented error: include the starting tick when counting jumps along the number line
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=5; ExpectedCorrect=4
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_268_count_starting_point_as_first_jump(A-B, Got) :-
    Got is B - A + 1).

test_harness:arith_misconception(db_row(268), whole_number, churn_268_count_starting_point_as_first_jump,
    churn_candidate:churn_268_count_starting_point_as_first_jump,
    3-7,
    4).
