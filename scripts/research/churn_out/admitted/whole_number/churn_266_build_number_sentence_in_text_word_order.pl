% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(266)
% Citation: Ding (2018)
% Documented error: form the equation by following the order numbers appear in the problem text
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got==(+(5,3),8); ExpectedCorrect==(+(5,3),2)
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_266_build_number_sentence_in_text_word_order([A,B,C], A+B=C) :-
    true).

test_harness:arith_misconception(db_row(266), whole_number, churn_266_build_number_sentence_in_text_word_order,
    churn_candidate:churn_266_build_number_sentence_in_text_word_order,
    [5,3,8],
    5+3=2).
