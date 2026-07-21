% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_fraction.pl, db_row(39816)
% Citation: Tuğrul Kar (2015)
% Documented error: add successive fractional amounts ignoring that each is taken from what remains
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=frac(4,4); ExpectedCorrect=frac(1,2)
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_39816_add_fractions_of_a_diminishing_whole_as_if_same_whole(frac(A1,B1)-frac(A2,B2), frac(SumNum, SumDenom)) :-
    SumNum is A1 * B2 + A2 * B1,
    SumDenom is B1 * B2).

test_harness:arith_misconception(db_row(39816), fraction, churn_39816_add_fractions_of_a_diminishing_whole_as_if_same_whole,
    churn_candidate:churn_39816_add_fractions_of_a_diminishing_whole_as_if_same_whole,
    frac(1,2)-frac(1,2),
    frac(1,2)).
