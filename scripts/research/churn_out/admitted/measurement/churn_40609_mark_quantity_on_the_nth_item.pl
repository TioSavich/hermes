% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_measurement.pl, db_row(40609)
% Citation: Koeno Gravemeijer (1999)
% Documented error: place a quantity label on the discrete item bearing that ordinal position
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=5; ExpectedCorrect=4
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_40609_mark_quantity_on_the_nth_item(nth_bead(N), Got) :-
    Got = N).

test_harness:arith_misconception(db_row(40609), measurement, churn_40609_mark_quantity_on_the_nth_item,
    churn_candidate:churn_40609_mark_quantity_on_the_nth_item,
    nth_bead(5), 4).
