% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(37891)
% Citation: Lawal O. Adetula (1989)
% Documented error: the word 'more' in a problem means you should add
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=22; ExpectedCorrect=8
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_37891_keyword_more_signals_addition(A-B, Got) :-
    Got is A + B).

test_harness:arith_misconception(db_row(37891), whole_number, churn_37891_keyword_more_signals_addition,
    churn_candidate:churn_37891_keyword_more_signals_addition,
    15-7,
    8).
