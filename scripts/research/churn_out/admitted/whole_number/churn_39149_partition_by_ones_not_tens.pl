% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(39149)
% Citation: SARA HENNESSY, TIM O'SHEA, RICK EVERTSZ AND ANN FLOYD (1989)
% Documented error: break a number into single units rather than into tens during mental calculation
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=47; ExpectedCorrect=+(40,7)
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_39149_partition_by_ones_not_tens(N, Got) :-
    Got is N).

test_harness:arith_misconception(db_row(39149), whole_number, churn_39149_partition_by_ones_not_tens,
    churn_candidate:churn_39149_partition_by_ones_not_tens,
    47,
    40+7).
