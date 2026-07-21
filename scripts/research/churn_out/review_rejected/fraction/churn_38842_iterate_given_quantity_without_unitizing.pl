% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_fraction.pl, db_row(38842)
% Review reason: rejected in Task 69 semantic review; no distinct executable misconception was established.
% Citation: Tatjana Hodnik Cadez, Vida Manfreda Kolar (2018)
% Documented error: try to rebuild the whole by iterating the shown 2/5 region directly instead of first finding the 1/5 unit
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=frac(*(2,5),2); ExpectedCorrect=frac(10,2)
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_38842_iterate_given_quantity_without_unitizing(frac(N,D), frac(M*D,N)) :-
    N > 0,
    D > 0,
    M is N).

test_harness:arith_misconception(db_row(38842), fraction, churn_38842_iterate_given_quantity_without_unitizing,
    churn_candidate:churn_38842_iterate_given_quantity_without_unitizing,
    frac(2,5),
    frac(10,2)).
