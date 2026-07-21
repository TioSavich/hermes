% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(38090)
% Citation: Anne Teppo, Marja van den Heuvel-Panhuizen (2014)
% Documented error: draw each jump as a forward hop and place the landing point accordingly
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=8; ExpectedCorrect=2
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_38090_place_result_in_jump_direction_ignoring_sign(A-B, Got) :-
    Got is A + abs(B)).

test_harness:arith_misconception(db_row(38090), whole_number, churn_38090_place_result_in_jump_direction_ignoring_sign,
    churn_candidate:churn_38090_place_result_in_jump_direction_ignoring_sign,
    5-3,
    2).
