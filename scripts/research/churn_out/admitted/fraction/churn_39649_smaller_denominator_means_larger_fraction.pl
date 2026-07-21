% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_fraction.pl, db_row(39649)
% Citation: Eugene Kaminski (2002)
% Documented error: the smaller the denominator, the larger the fraction regardless of numerator
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=frac(1,0); ExpectedCorrect=frac(3,2)
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_39649_smaller_denominator_means_larger_fraction(frac(N1,D1)-frac(N2,D2), frac(1,0)) :-
    D1 < D2,
    \+ (N1 =:= 0, N2 =:= 0)).

test_harness:arith_misconception(db_row(39649), fraction, churn_39649_smaller_denominator_means_larger_fraction,
    churn_candidate:churn_39649_smaller_denominator_means_larger_fraction,
    frac(1,2)-frac(3,4),
    frac(3,2)).
