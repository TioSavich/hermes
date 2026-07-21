% Misconception churn candidate; not integrated into a domain table.
% Source: knowledge/misconceptions/misconceptions_fraction.pl, db_row(37570)
% Citation: George W. Bright, Merlyn J. Behr, Thomas R. Post and Ipke Wachsmuth (1988)
% Documented error: take the entire drawn span (here 0 to 2) as the single reference unit
% Gate: loaded, executed, returned an incorrect documented-pattern outcome
% Gate outcome: Got=unit(-(2,0)); ExpectedCorrect=unit(1)
:- module(churn_candidate, []).
:- multifile test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.

churn_candidate:(churn_37570_whole_visible_segment_is_the_unit(number_line(Start, End), unit(End - Start))) :-
    Start < End.

test_harness:arith_misconception(db_row(37570), fraction, churn_37570_whole_visible_segment_is_the_unit,
    churn_candidate:churn_37570_whole_visible_segment_is_the_unit,
    number_line(0, 2),
    unit(1)).
