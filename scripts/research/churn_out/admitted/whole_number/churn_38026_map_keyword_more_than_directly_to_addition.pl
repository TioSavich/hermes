% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(38026)
% Citation: Berinderjeet Kaur (2018)
% Documented error: choose addition whenever the phrase 'more than' appears
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=22; ExpectedCorrect=8
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_38026_map_keyword_more_than_directly_to_addition(A-B, Got) :-
    Got is A + B).

test_harness:arith_misconception(db_row(38026), whole_number, churn_38026_map_keyword_more_than_directly_to_addition,
    churn_candidate:churn_38026_map_keyword_more_than_directly_to_addition,
    15-7,
    8).
