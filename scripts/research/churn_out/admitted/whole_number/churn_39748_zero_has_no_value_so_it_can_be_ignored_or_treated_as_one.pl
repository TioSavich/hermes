% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(39748)
% Citation: Aurelia Noda Herrera, Alicia Bruno, Carina González, Lorenzo Moreno & Hilda Sanabria (2011)
% Documented error: because zero names nothing, treat it as having no effect, as a counted object, or as the word one
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=1; ExpectedCorrect=5
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_39748_zero_has_no_value_so_it_can_be_ignored_or_treated_as_one(A-B, Got) :-
    ( A =:= 0 -> Got is 1 - B ; B =:= 0 -> Got is A - 1 ; Got is A - B )).

test_harness:arith_misconception(db_row(39748), whole_number, churn_39748_zero_has_no_value_so_it_can_be_ignored_or_treated_as_one,
    churn_candidate:churn_39748_zero_has_no_value_so_it_can_be_ignored_or_treated_as_one,
    5-0,
    5).
