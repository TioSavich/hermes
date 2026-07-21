% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(39560)
% Citation: Anne Gooding and Kaye Stacey (1993)
% Documented error: write the dividend and divisor into the long-division bracket in the same left-to-right order they appear in a/b
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=bracket(12,3); ExpectedCorrect=4
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_39560_transcribe_linear_order_into_bracket(A-B, Got) :-
    Got = bracket(A, B)).

test_harness:arith_misconception(db_row(39560), whole_number, churn_39560_transcribe_linear_order_into_bracket,
    churn_candidate:churn_39560_transcribe_linear_order_into_bracket,
    12-3,
    bracket(3,12)).
