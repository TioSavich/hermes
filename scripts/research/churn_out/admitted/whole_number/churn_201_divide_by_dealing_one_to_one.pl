% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(201)
% Citation: Pepper, KL and Hunting, RP (1998)
% Documented error: distribute items one at a time into groups using one-to-one correspondence
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=12; ExpectedCorrect=3
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_201_divide_by_dealing_one_to_one(A-B, Got) :-
    between(1, B, _),
    Got is A).

test_harness:arith_misconception(db_row(201), whole_number, churn_201_divide_by_dealing_one_to_one,
    churn_candidate:churn_201_divide_by_dealing_one_to_one,
    12-4,
    3).
