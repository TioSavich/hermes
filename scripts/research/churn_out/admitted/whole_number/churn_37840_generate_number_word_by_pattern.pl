% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_whole_number.pl, db_row(37840)
% Citation: Arthur J. Baroody and Herbert P. Ginsburg (1990)
% Documented error: form the next number word by applying the observed decade-suffix pattern (ten gives tenty)
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=tenty; ExpectedCorrect=thirty
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_37840_generate_number_word_by_pattern(ten, Got) :- Got = tenty).
churn_candidate:(churn_37840_generate_number_word_by_pattern(twenty, Got) :- Got = twenty).
churn_candidate:(churn_37840_generate_number_word_by_pattern(thirty, Got) :- Got = tirty).
churn_candidate:(churn_37840_generate_number_word_by_pattern(forty, Got) :- Got = fourty).
churn_candidate:(churn_37840_generate_number_word_by_pattern(fifty, Got) :- Got = fivety).
churn_candidate:(churn_37840_generate_number_word_by_pattern(sixty, Got) :- Got = sixty).
churn_candidate:(churn_37840_generate_number_word_by_pattern(seventy, Got) :- Got = seventy).
churn_candidate:(churn_37840_generate_number_word_by_pattern(eighty, Got) :- Got = eighty).
churn_candidate:(churn_37840_generate_number_word_by_pattern(ninety, Got) :- Got = ninetys).

test_harness:arith_misconception(db_row(37840), whole_number, churn_37840_generate_number_word_by_pattern,
    churn_candidate:churn_37840_generate_number_word_by_pattern,
    ten,
    thirty).
