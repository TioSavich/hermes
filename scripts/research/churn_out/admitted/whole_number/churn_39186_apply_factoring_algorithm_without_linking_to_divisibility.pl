% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(39186)
% Citation: Pessia Tsamir (2002)
% Documented error: carry out factorization procedurally without connecting it to what divisibility means
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=[2,3,4,6,12]; ExpectedCorrect=[2,3]
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_39186_apply_factoring_algorithm_without_linking_to_divisibility(N, Got) :-
    factorize_procedurally(N, Got)).

factorize_procedurally(N, Factors) :-
    findall(F, (between(2, N, F), 0 is N mod F), Factors).

test_harness:arith_misconception(db_row(39186), whole_number, churn_39186_apply_factoring_algorithm_without_linking_to_divisibility,
    churn_candidate:churn_39186_apply_factoring_algorithm_without_linking_to_divisibility,
    12,
    [2,3]).
