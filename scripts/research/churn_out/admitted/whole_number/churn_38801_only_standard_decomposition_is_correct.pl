% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(38801)
% Citation: Janne Fauskanger (2015)
% Documented error: a number may be decomposed correctly only by its standard place-value digits, not as 45x10+6
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=456; ExpectedCorrect=+(+(400,50),6)
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_38801_only_standard_decomposition_is_correct(N, Got) :-
    Got = N).

test_harness:arith_misconception(db_row(38801), whole_number, churn_38801_only_standard_decomposition_is_correct,
    churn_candidate:churn_38801_only_standard_decomposition_is_correct,
    456,
    400+50+6).
