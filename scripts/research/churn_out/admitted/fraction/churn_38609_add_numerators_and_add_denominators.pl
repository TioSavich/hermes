% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_fraction.pl, db_row(38609)
% Citation: Cheng-Yao Lin, Jerry Becker, Yi-Yin Ko, Mi-Ran Byun (2013)
% Documented error: add the tops together and the bottoms together to combine fractions
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=frac(+(1,1),+(2,3)); ExpectedCorrect=frac(5,6)
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_38609_add_numerators_and_add_denominators(frac(N1,D1)+frac(N2,D2), frac(N1+N2, D1+D2))).

test_harness:arith_misconception(db_row(38609), fraction, churn_38609_add_numerators_and_add_denominators,
    churn_candidate:churn_38609_add_numerators_and_add_denominators,
    frac(1,2)+frac(1,3),
    frac(5,6)).
