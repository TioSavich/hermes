% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(38049)
% Review reason: rejected in Task 69 semantic review; no distinct executable misconception was established.
% Citation: F. D. Rivera (2014)
% Documented error: after decomposing a ten into ones, recount the whole collection starting at one
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=-(13,5); ExpectedCorrect=8
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_38049_count_all_from_one(Subtrahend, Got) :-
    % Student decomposes a ten (e.g., 10 into 10 ones) but then
    % starts counting the entire collection from 1 instead of continuing
    % from the current count. For subtraction like 13 - 5:
    % After decomposing 13 as 10+3 → 10 becomes 10 ones, so total 13 ones.
    % Student then counts all 13 ones starting at 1, but stops at 5,
    % concluding answer = 5 (instead of 8).
    % Generalizing: after decomposition, student returns to counting
    % from 1 up to the subtrahend, ignoring the initial count.
    % We simulate this by returning the subtrahend directly.
    Got = Subtrahend).

test_harness:arith_misconception(db_row(38049), whole_number, churn_38049_count_all_from_one,
    churn_candidate:churn_38049_count_all_from_one,
    13-5,
    8).
