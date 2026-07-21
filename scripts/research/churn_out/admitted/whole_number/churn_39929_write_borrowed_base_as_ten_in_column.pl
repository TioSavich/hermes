% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(39929)
% Citation: Paul M.E. Shutler & Ng Swee Fong (2010)
% Documented error: a borrowed base unit is written literally as 10 inside one column
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=47; ExpectedCorrect=37
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_39929_write_borrowed_base_as_ten_in_column(A-B, Got) :-
    A >= 10,
    B < 10,
    Got is (A // 10) * 10 + (A mod 10 + 10 - B)).

test_harness:arith_misconception(db_row(39929), whole_number, churn_39929_write_borrowed_base_as_ten_in_column,
    churn_candidate:churn_39929_write_borrowed_base_as_ten_in_column,
    42-5,
    37).
