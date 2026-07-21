% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(39409)
% Review reason: rejected in Task 69 semantic review; no distinct executable misconception was established.
% Citation: ALEKSANDRA URBAŃSKA (1993)
% Documented error: the row that stretches further contains the greater quantity
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=>; ExpectedCorrect==
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_39409_longer_row_has_more_items(A-B, Got) :-
    length(A, LA),
    length(B, LB),
    (LA > LB -> Got = '>' ; Got = '=<')).

test_harness:arith_misconception(db_row(39409), whole_number, churn_39409_longer_row_has_more_items,
    churn_candidate:churn_39409_longer_row_has_more_items,
    [1,2,3,4,5]-[1,2,3],
    '=').
