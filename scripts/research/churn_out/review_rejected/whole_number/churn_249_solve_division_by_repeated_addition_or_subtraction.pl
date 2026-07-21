% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(249)
% Review reason: rejected in Task 69 semantic review; no distinct executable misconception was established.
% Citation: Cai, J. (1998)
% Documented error: find a quotient and remainder by repeatedly adding or subtracting the divisor
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=3; ExpectedCorrect=4
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_249_solve_division_by_repeated_addition_or_subtraction(A-B, Got) :-
    A > 0, B > 0,
    quotient_by_repeated_addition(A, B, 0, Got)).

churn_candidate:(quotient_by_repeated_addition(A, B, Acc, Acc) :-
    A < B).
churn_candidate:(quotient_by_repeated_addition(A, B, Acc, Q) :-
    A >= B,
    A1 is A - B,
    Acc1 is Acc + 1,
    quotient_by_repeated_addition(A1, B, Acc1, Q)).

test_harness:arith_misconception(db_row(249), whole_number, churn_249_solve_division_by_repeated_addition_or_subtraction,
    churn_candidate:churn_249_solve_division_by_repeated_addition_or_subtraction,
    17-5,
    4).
