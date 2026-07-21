% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(39721)
% Citation: Gillian Boulton-Lewis & Graeme Halford (1992)
% Documented error: regard a group of ten as any loose gathering of ten separate objects rather than a single entity
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=10; ExpectedCorrect=1
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_39721_treat_ten_as_loose_collection_of_singles(A, Got) :-
    Got is A).

test_harness:arith_misconception(db_row(39721), whole_number, churn_39721_treat_ten_as_loose_collection_of_singles,
    churn_candidate:churn_39721_treat_ten_as_loose_collection_of_singles,
    10,
    1).
