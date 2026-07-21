% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_decimal.pl, db_row(39398)
% Citation: JOHN MONAGHAN (2001)
% Documented error: treat a non-terminating decimal as an unfinished process rather than a fixed quantity
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=/(1,-(**(10,1),1)); ExpectedCorrect=0.1111111111111111
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_39398_unending_expansion_is_not_a_number(repeating(D, S), Got) :-
    Got = D / (10 ** S - 1)).

test_harness:arith_misconception(db_row(39398), decimal, churn_39398_unending_expansion_is_not_a_number,
    churn_candidate:churn_39398_unending_expansion_is_not_a_number,
    repeating(1, 1),
    0.1111111111111111).
