% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_measurement.pl, db_row(38493)
% Citation: Guy Brousseau, Nadine Brousseau, Virginia Warfield (2004)
% Documented error: a quantity below the smallest gradation of the instrument has no measurable magnitude
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=0; ExpectedCorrect=0.5
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_38493_if_smaller_than_smallest_unit_then_has_no_measure(thickness(Microns), Got) :-
    Microns < 1,
    Got = 0).

test_harness:arith_misconception(db_row(38493), measurement, churn_38493_if_smaller_than_smallest_unit_then_has_no_measure,
    churn_candidate:churn_38493_if_smaller_than_smallest_unit_then_has_no_measure,
    thickness(0.5), 0.5).
