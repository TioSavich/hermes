% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_decimal.pl, db_row(40092)
% Review reason: rejected in Task 69 semantic review; no distinct executable misconception was established.
% Citation: JUDITH SOWDER, BARBARA ARMSTRONG, SUSAN LAMON, MARTIN SIMON, LARRY SOWDER and ALBA THOMPSON (1998)
% Documented error: assume multiplying always increases and dividing always decreases a quantity
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=1.0; ExpectedCorrect=0.25
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_40092_multiplication_makes_bigger_division_makes_smaller(Value, Result)) :-
    Result is Value * 2.

test_harness:arith_misconception(db_row(40092), decimal, churn_40092_multiplication_makes_bigger_division_makes_smaller,
    churn_candidate:churn_40092_multiplication_makes_bigger_division_makes_smaller,
    0.5,
    0.25).
