% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(40108)
% Review reason: rejected in Task 69 semantic review; no distinct executable misconception was established.
% Citation: Jason Cooper, Ronnie Karsenty (2018)
% Documented error: treat two divisions with the same quotient and remainder as equal
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=-(3,2); ExpectedCorrect=3
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_40108_equate_division_expressions_by_quotient_and_remainder(A-B, Got) :-
    Q is A div B,
    R is A mod B,
    Got = (Q-R)).

test_harness:arith_misconception(db_row(40108), whole_number, churn_40108_equate_division_expressions_by_quotient_and_remainder,
    churn_candidate:churn_40108_equate_division_expressions_by_quotient_and_remainder,
    17-5,
    3).
