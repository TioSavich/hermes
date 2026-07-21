% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_decimal.pl, db_row(40651)
% Citation: Annie Selden, John Selden (2005)
% Documented error: judge decimal size using whole-number reasoning about the digit string
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=<; ExpectedCorrect=>
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_40651_compare_decimals_as_extensions_of_whole_numbers(Decimal1-Decimal2, Got) :-
    atom_string(Decimal1, Str1),
    atom_string(Decimal2, Str2),
    string_length(Str1, Len1),
    string_length(Str2, Len2),
    ( Len1 > Len2 -> Got = '>' ; ( Len1 < Len2 -> Got = '<' ; Got = '=' ) )).

test_harness:arith_misconception(db_row(40651), decimal, churn_40651_compare_decimals_as_extensions_of_whole_numbers,
    churn_candidate:churn_40651_compare_decimals_as_extensions_of_whole_numbers,
    '0.25'-'0.125',
    '>').
