% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_measurement.pl, db_row(39552)
% Citation: Thomas Lingefjard & Stephanie Meier (2010)
% Documented error: do not connect arc minutes to degrees or to the unit circle's circumference
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=60; ExpectedCorrect=1
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_39552_treat_arc_minutes_as_unrelated_to_degrees(arc_minutes(N), Got) :-
    Got = N).

test_harness:arith_misconception(db_row(39552), measurement, churn_39552_treat_arc_minutes_as_unrelated_to_degrees,
    churn_candidate:churn_39552_treat_arc_minutes_as_unrelated_to_degrees,
    arc_minutes(60), 1).
