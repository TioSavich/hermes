% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_fraction.pl, db_row(40538)
% Citation: Anne Watson (2010)
% Documented error: read a fraction as two separate whole numbers rather than one quantity
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=[3,4]; ExpectedCorrect=/(3,4)
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_40538_fraction_is_pair_of_independent_integers(frac(N,D), [N,D])).

test_harness:arith_misconception(db_row(40538), fraction, churn_40538_fraction_is_pair_of_independent_integers,
    churn_candidate:churn_40538_fraction_is_pair_of_independent_integers,
    frac(3,4),
    3/4).
