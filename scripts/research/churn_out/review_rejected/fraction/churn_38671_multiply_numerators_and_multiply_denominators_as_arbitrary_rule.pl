% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_fraction.pl, db_row(38671)
% Review reason: rejected in Task 69 semantic review; no distinct executable misconception was established.
% Citation: Guy Brousseau, Nadine Brousseau, Virginia Warfield (2008)
% Documented error: multiply tops and bottoms because that is just what you are supposed to do
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=frac(2,6); ExpectedCorrect=frac(1,3)
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_38671_multiply_numerators_and_multiply_denominators_as_arbitrary_rule(frac(N1,D1) * frac(N2,D2), frac(NProd,DProd)) :-
    NProd is N1 * N2,
    DProd is D1 * D2).

test_harness:arith_misconception(db_row(38671), fraction, churn_38671_multiply_numerators_and_multiply_denominators_as_arbitrary_rule,
    churn_candidate:churn_38671_multiply_numerators_and_multiply_denominators_as_arbitrary_rule,
    frac(1,2) * frac(2,3),
    frac(1,3)).
