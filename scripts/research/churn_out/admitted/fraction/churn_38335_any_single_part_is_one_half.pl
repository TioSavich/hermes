% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_fraction.pl, db_row(38335)
% Citation: Ron Tzur (2000)
% Documented error: the word 'one-half' names any single piece of a partitioned whole
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=frac(1,2); ExpectedCorrect=frac(5,7)
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_38335_any_single_part_is_one_half(frac(_,_)-frac(N,D), frac(1,2)) :-
    N > 0,
    D > 0).

test_harness:arith_misconception(db_row(38335), fraction, churn_38335_any_single_part_is_one_half,
    churn_candidate:churn_38335_any_single_part_is_one_half,
    frac(2,5)-frac(3,7),
    frac(5,7)).
