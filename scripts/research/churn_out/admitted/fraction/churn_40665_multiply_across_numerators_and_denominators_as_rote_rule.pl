% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_fraction.pl, db_row(40665)
% Citation: John Olive (1999)
% Documented error: multiply tops and bottoms as a memorized procedure detached from quantity meaning
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=frac(2,6); ExpectedCorrect=frac(4,6)
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_40665_multiply_across_numerators_and_denominators_as_rote_rule(frac(N1,D1)-frac(N2,D2), frac(NProd, DProd)) :-
    NProd is N1 * N2,
    DProd is D1 * D2).

test_harness:arith_misconception(db_row(40665), fraction, churn_40665_multiply_across_numerators_and_denominators_as_rote_rule,
    churn_candidate:churn_40665_multiply_across_numerators_and_denominators_as_rote_rule,
    frac(1,2)-frac(2,3),
    frac(4,6)).
