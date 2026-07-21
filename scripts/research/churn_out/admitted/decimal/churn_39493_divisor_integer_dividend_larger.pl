% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_decimal.pl, db_row(39493)
% Citation: JEAN-PIERRE LEVAIN (1992)
% Documented error: division shares among a whole number of objects, so the divisor is an integer smaller than the dividend
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=0; ExpectedCorrect=0.7142857142857143
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_39493_divisor_integer_dividend_larger(dividend(D)-divisor(Dv), Got) :-
    integer(Dv),
    Dv > D,
    Got is 0).

test_harness:arith_misconception(db_row(39493), decimal, churn_39493_divisor_integer_dividend_larger,
    churn_candidate:churn_39493_divisor_integer_dividend_larger,
    dividend(5)-divisor(7),
    0.7142857142857143).
