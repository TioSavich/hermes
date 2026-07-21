% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_fraction.pl, db_row(38371)
% Citation: Martin A. Simon, Melike Kara, Anderson Norton, Nicora Placa (2018)
% Documented error: the product of two fractions is that many parts of the second factor rather than of the whole
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=frac(1,*(2,3)); ExpectedCorrect=frac(1,6)
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_38371_product_referent_is_the_second_factor(frac(N1,D1) * frac(N2,D2), frac(NProd, D1*D2)) :-
    NProd is N1 * N2).

test_harness:arith_misconception(db_row(38371), fraction, churn_38371_product_referent_is_the_second_factor,
    churn_candidate:churn_38371_product_referent_is_the_second_factor,
    frac(1,2) * frac(1,3),
    frac(1,6)).
