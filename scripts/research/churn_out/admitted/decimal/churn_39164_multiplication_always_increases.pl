% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_decimal.pl, db_row(39164)
% Citation: ANNA O. GRAEBER AND DINA TIROSH (1990)
% Documented error: expect a product to always be larger than its factors
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=9.0; ExpectedCorrect=9
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_39164_multiplication_always_increases(X * Y, Got) :-
    Got is X * Y,
    X > 0,
    Y > 0,
    Y < 1,
    Got < X).

test_harness:arith_misconception(db_row(39164), decimal, churn_39164_multiplication_always_increases,
    churn_candidate:churn_39164_multiplication_always_increases,
    15 * 0.6,
    9).
