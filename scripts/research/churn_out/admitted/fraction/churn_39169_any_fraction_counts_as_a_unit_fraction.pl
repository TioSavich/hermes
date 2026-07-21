% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_fraction.pl, db_row(39169)
% Citation: Nurbanu Yilmaz, Ilhan Karatas (2018)
% Documented error: treat proper or improper fractions as interchangeable with unit fractions
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=true; ExpectedCorrect=false
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_39169_any_fraction_counts_as_a_unit_fraction(frac(N,D), true) :-
    N =\= 1,
    N > 0,
    D > 0).

test_harness:arith_misconception(db_row(39169), fraction, churn_39169_any_fraction_counts_as_a_unit_fraction,
    churn_candidate:churn_39169_any_fraction_counts_as_a_unit_fraction,
    frac(2,3),
    false).
