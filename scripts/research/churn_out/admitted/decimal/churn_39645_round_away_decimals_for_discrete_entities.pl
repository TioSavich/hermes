% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_decimal.pl, db_row(39645)
% Citation: Nuria Planas & Marta Civil (2002)
% Documented error: drop the decimal part of a quotient when the quantity counts discrete real-world entities like people
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=13; ExpectedCorrect=12
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_39645_round_away_decimals_for_discrete_entities(quotient(Q), Got) :-
    Got is integer(Q)).

test_harness:arith_misconception(db_row(39645), decimal, churn_39645_round_away_decimals_for_discrete_entities,
    churn_candidate:churn_39645_round_away_decimals_for_discrete_entities,
    quotient(12.57),
    12).
