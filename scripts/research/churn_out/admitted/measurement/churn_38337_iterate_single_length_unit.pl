% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_measurement.pl, db_row(38337)
% Citation: Erik S. Tillema ()
% Documented error: establish area by repeating one length unit rather than coordinating length and width
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=5; ExpectedCorrect=15
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_38337_iterate_single_length_unit(rect(W, _H), Got) :-
    Got is W).

test_harness:arith_misconception(db_row(38337), measurement, churn_38337_iterate_single_length_unit,
    churn_candidate:churn_38337_iterate_single_length_unit,
    rect(5,3), 15).
