% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(40020)
% Review reason: rejected in Task 69 semantic review; no distinct executable misconception was established.
% Citation: Despina Potari, Barbara Georgiadou-Kabouridis (2009)
% Documented error: treat the number you divide by as the count of items per share
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=24; ExpectedCorrect=6
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_40020_read_divisor_as_group_size(A-B, Got) :-
    Got is A // B * B).

test_harness:arith_misconception(db_row(40020), whole_number, churn_40020_read_divisor_as_group_size,
    churn_candidate:churn_40020_read_divisor_as_group_size,
    24-4,
    6).
