% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(37718)
% Citation: Sandra P. Marshall (1983)
% Documented error: subtract whenever two money amounts appear because that worked before
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=125; ExpectedCorrect=875
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_37718_reapply_operation_associated_with_quantity_type(A-B, Got) :-
    Got is A - B).

test_harness:arith_misconception(db_row(37718), whole_number, churn_37718_reapply_operation_associated_with_quantity_type,
    churn_candidate:churn_37718_reapply_operation_associated_with_quantity_type,
    500-375,
    875).
