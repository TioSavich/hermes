% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(38566)
% Citation: Esther Levenson, Pessia Tsamir, Dina Tirosh (2007)
% Documented error: you cannot divide zero because there is nothing there to divide
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=error('division requires a nonempty quantity'); ExpectedCorrect=0
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_38566_division_requires_a_nonempty_quantity(A, Got) :-
    A = 0,
    Got = error('division requires a nonempty quantity')).

test_harness:arith_misconception(db_row(38566), whole_number, churn_38566_division_requires_a_nonempty_quantity,
    churn_candidate:churn_38566_division_requires_a_nonempty_quantity,
    0,
    0).
