% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(37690)
% Citation: Joanne T. Mulligan and Michael C. Mitchelmore (1997)
% Documented error: if the word 'times' appears, choose multiplication
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=0; ExpectedCorrect=15
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_37690_keyword_times_means_multiply(_-_ , Got) :-
    Got is 0).

test_harness:arith_misconception(db_row(37690), whole_number, churn_37690_keyword_times_means_multiply,
    churn_candidate:churn_37690_keyword_times_means_multiply,
    5-3,
    15).
