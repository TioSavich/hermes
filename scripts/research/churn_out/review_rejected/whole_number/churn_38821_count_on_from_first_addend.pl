% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(38821)
% Review reason: rejected in Task 69 semantic review; no distinct executable misconception was established.
% Citation: HANS FREUDENTHAL (1981)
% Documented error: add by counting forward the second addend starting from the first
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=3; ExpectedCorrect=7
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_38821_count_on_from_first_addend(A+B, Got) :-
    between(1, B, _),
    count_up(A, 0, Got)).

count_up(X, N, X) :- N =:= X.
count_up(X, N, Got) :- N < X, N1 is N+1, count_up(X, N1, Got).

test_harness:arith_misconception(db_row(38821), whole_number, churn_38821_count_on_from_first_addend,
    churn_candidate:churn_38821_count_on_from_first_addend,
    3+4,
    7).
