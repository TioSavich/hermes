% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_decimal.pl, db_row(38531)
% Citation: David A. Yopp (2018)
% Documented error: 0.999... stays an infinitesimal amount below 1 and 0.333... below 1/3
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=0.999; ExpectedCorrect=1.0
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_38531_infinite_decimal_falls_short_of_its_limit(RepeatingDec, Got) :-
    RepeatingDec = 0.999,
    Got is 0.999;
    RepeatingDec = 0.333,
    Got is 0.333).

test_harness:arith_misconception(db_row(38531), decimal, churn_38531_infinite_decimal_falls_short_of_its_limit,
    churn_candidate:churn_38531_infinite_decimal_falls_short_of_its_limit,
    0.999,
    1.0).
