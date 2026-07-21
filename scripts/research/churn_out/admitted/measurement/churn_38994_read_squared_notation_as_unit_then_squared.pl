% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_measurement.pl, db_row(38994)
% Citation: ANNETTE BATURO and ROD NASON (1996)
% Documented error: interpret 6 m^2 as 'six meters, squared' rather than 'six square meters'
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=36; ExpectedCorrect=6
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_38994_read_squared_notation_as_unit_then_squared(meters_squared(N), Got) :-
    Got is N*N).

test_harness:arith_misconception(db_row(38994), measurement, churn_38994_read_squared_notation_as_unit_then_squared,
    churn_candidate:churn_38994_read_squared_notation_as_unit_then_squared,
    meters_squared(6), 6).
