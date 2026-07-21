% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(38708)
% Citation: Erik S. Tillema (2014)
% Documented error: you must physically form and count every symmetric addend pair rather than anticipate how many pairs there are
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=30; ExpectedCorrect=15
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_38708_materially_count_each_pair_before_totaling(A-B, Got) :-
    findall(Pair, (between(A, B, X), between(X, B, Y), X < Y, Pair = X-Y), Pairs),
    length(Pairs, Len),
    Got is Len * (A + B)).

test_harness:arith_misconception(db_row(38708), whole_number, churn_38708_materially_count_each_pair_before_totaling,
    churn_candidate:churn_38708_materially_count_each_pair_before_totaling,
    1-4,
    15).
