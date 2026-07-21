% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(227)
% Citation: Simon (2006)
% Documented error: treat ten strictly as ten separate single units, not also as one thing
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=10; ExpectedCorrect=1
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_227_ten_is_only_ten_ones(10, Got) :-
    Got = 10).

test_harness:arith_misconception(db_row(227), whole_number, churn_227_ten_is_only_ten_ones,
    churn_candidate:churn_227_ten_is_only_ten_ones,
    10,
    1).
