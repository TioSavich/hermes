% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(282)
% Review reason: rejected in Task 69 semantic review; no distinct executable misconception was established.
% Citation: Tim Rowland et al. (2015)
% Documented error: compute with a nearby round number then adjust by the amount added or removed
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=86; ExpectedCorrect=90
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_282_round_then_adjust_by_difference(A+B, Got) :-
    round_up_addend(A, RoundedA, Adjustment),
    Got is RoundedA + B,
    Got is (A + Adjustment) + B).

churn_candidate:(round_up_addend(A, RoundedA, Adjustment) :-
    A < 0,
    RoundedA is A,
    Adjustment is 0).
churn_candidate:(round_up_addend(A, RoundedA, Adjustment) :-
    A >= 0,
    RoundedA is ((A + 9) // 10) * 10,
    Adjustment is RoundedA - A).

test_harness:arith_misconception(db_row(282), whole_number, churn_282_round_then_adjust_by_difference,
    churn_candidate:churn_282_round_then_adjust_by_difference,
    47+36,
    90).
