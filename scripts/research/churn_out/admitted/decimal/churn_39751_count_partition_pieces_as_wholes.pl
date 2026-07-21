% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_decimal.pl, db_row(39751)
% Citation: Zandra de Araujo, Chandra Hawley Orrill & Erik Jacobson (2018)
% Documented error: treat each one-tenth piece drawn in a division model as if it were a whole unit
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=6; ExpectedCorrect=6.0
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_39751_count_partition_pieces_as_wholes(dividend(D)-divisor(Dv), Got) :-
    % Student draws D as D whole units, partitions each into 10 tenths, counts all tenths as whole units,
    % then divides by divisor, i.e., (D * 10) / Dv, but interprets result as whole units instead of tenths.
    Got is (D * 10) / Dv).

test_harness:arith_misconception(db_row(39751), decimal, churn_39751_count_partition_pieces_as_wholes,
    churn_candidate:churn_39751_count_partition_pieces_as_wholes,
    dividend(3)-divisor(5),
    0.6).
