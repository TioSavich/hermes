% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(229)
% Citation: Remillard, J. T., & Jackson, K. (2006)
% Documented error: treat multiplication as facts to be remembered rather than drawn or worked out
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=0; ExpectedCorrect=84
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_229_multiplication_is_memorized_recall(A-B, Got) :-
    % Student treats multiplication as a memorized fact, so they only produce the result when both operands are small (≤10),
    % and otherwise fail to compute it — returning 0 as a placeholder for "unknown" or "not memorized"
    (A =< 10, B =< 10 -> Got is A * B ; Got = 0)).

test_harness:arith_misconception(db_row(229), whole_number, churn_229_multiplication_is_memorized_recall,
    churn_candidate:churn_229_multiplication_is_memorized_recall,
    12-7,
    84).
