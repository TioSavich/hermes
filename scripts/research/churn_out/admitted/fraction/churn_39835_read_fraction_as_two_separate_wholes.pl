% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_fraction.pl, db_row(39835)
% Citation: Kin Keung Poon (2018)
% Documented error: interpret the numerator and denominator as two independent counting numbers rather than one quantity
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=[3,4]; ExpectedCorrect=0.75
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_39835_read_fraction_as_two_separate_wholes(frac(N,D), [N,D])).

test_harness:arith_misconception(db_row(39835), fraction, churn_39835_read_fraction_as_two_separate_wholes,
    churn_candidate:churn_39835_read_fraction_as_two_separate_wholes,
    frac(3,4),
    0.75).
