% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_fraction.pl, db_row(40356)
% Citation: Der-Ching Yang & Iwan Andi J. Sianturi (2018)
% Documented error: place the two numbers in the problem directly as the top and bottom of a fraction
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=frac(3,5); ExpectedCorrect=frac(5,3)
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_40356_map_given_numbers_to_numerator_and_denominator(Num-Den, frac(Num, Den)) :-
    true).

test_harness:arith_misconception(db_row(40356), fraction, churn_40356_map_given_numbers_to_numerator_and_denominator,
    churn_candidate:churn_40356_map_given_numbers_to_numerator_and_denominator,
    3-5,
    frac(5,3)).
