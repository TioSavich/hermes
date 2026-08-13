:- encoding(utf8).
/** <module> Grade 8 pilot: two-way tables and the association they carry
 *
 * WHAT THIS IS. A quarantined pilot automaton for the doing IM grade 8 unit 6
 * asks for from lesson 9 onward: complete a two-way table from the totals it
 * already carries, turn its counts into relative frequencies by row, by
 * column, or over the whole table, and compare two rows to say whether the two
 * categorical variables look associated.
 *
 * WHY IT IS NEW. The statistics registry carries displays and summaries for
 * ONE variable — dot plots, histograms, five-number summaries, mean as fair
 * share. Nothing in it holds a table of counts cross-classified by two
 * categorical variables, and nothing computes a relative frequency conditional
 * on a row. That cross-classification is the whole of unit 6 lessons 9 through
 * 11. This pilot supplies it and leaves every registered machine untouched.
 *
 * FREQUENCIES ARE EXACT FRACTIONS, THEN PERCENTAGES. A relative frequency is
 * kept as a rational and rendered as a percentage beside it. That matters for
 * verification: each row of a by-row table must sum to exactly 1, and 89% plus
 * 11% only sums to 1 after rounding. The pilot checks the exact sum and
 * reports the rounded percentage separately, so a rounding never stands in for
 * the invariant.
 *
 * COMPLETION IS ARITHMETIC, NOT GUESSING. A missing cell is recovered from its
 * row total or its column total, and the completed table is then checked both
 * ways: every row must sum to its row total and every column to its column
 * total, with the grand total agreeing from both directions. A table that
 * cannot be completed from what it carries is refused by name rather than
 * filled with a plausible number.
 *
 * ASSOCIATION IS REPORTED, NEVER ADJUDICATED. The automaton computes the two
 * rows' conditional frequencies and their exact difference. It does not decide
 * whether that difference is large enough to matter; naming a threshold is a
 * judgement about a situation, and this engine computes rather than judges.
 *
 * NO DEFORMATION PARTNER. The research corpus carries no row attesting a
 * student error at the two-way-table locus. Shipping without one is the honest
 * choice rather than inventing a twin for symmetry.
 *
 * QUARANTINE. Nothing imports this module; it renames nothing; its rows are
 * authored and vetoable one by one.
 * Check: `check_g8_two_way_table_association/0`.
 */

:- module(g8_two_way_table_association,
          [ run_g8_two_way_table/4,
            g8_two_way_table_from_json/2,
            g8_two_way_table_states/1,
            g8_two_way_table_state_label/4,
            g8_two_way_table_summary/1,
            g8_two_way_table_receipt/5,
            check_g8_two_way_table_association/0
          ]).

:- use_module(strategies('abstraction/g8_quantity_input'),
              [ g8_quantity/2, g8_rational_text/2,
                g8_decimal_approximation/3 ]).
:- use_module(library(apply), [maplist/3, foldl/4]).
:- use_module(library(lists), [sum_list/2, nth0/3]).
:- use_module(library(clpfd), [transpose/2]).

% ==========================================================================
% 1. INPUT CONTRACT
%
%   {"kind":"two_way_table",
%    "rows":["10 to 12","13 to 15","16 to 18"],
%    "columns":["has phone","no phone"],
%    "cells":[[25,35],[40,10],[50,10]]}
%
%   A partial table names its missing cells with the string "?" and supplies
%   whatever totals it carries:
%
%   {"kind":"two_way_table_partial",
%    "rows":["plays sport","no sport"], "columns":["instrument","none"],
%    "cells":[[5,"?"],["?","?"]],
%    "row_totals":[16,"?"], "column_totals":["?",15], "grand_total":25}
% ==========================================================================

g8_two_way_table_input_contract(
    '{\"kind\":\"two_way_table\",\"rows\":[\"string\"],\"columns\":[\"string\"],\"cells\":[[\"number\"]]}',
    '{\"kind\":\"two_way_table\",\"rows\":[\"a\",\"b\"],\"columns\":[\"x\",\"y\"],\"cells\":[[25,35],[40,10]]}').

g8_two_way_table_from_json(Dict, table(Rows, Columns, Cells)) :-
    is_dict(Dict), get_dict(kind, Dict, "two_way_table"), !,
    get_dict(rows, Dict, Rows), get_dict(columns, Dict, Columns),
    get_dict(cells, Dict, Raw),
    length(Rows, R), length(Columns, C), R >= 2, C >= 2,
    length(Raw, R),
    maplist(row_of_length(C), Raw, Cells),
    forall(( member(Row, Cells), member(V, Row) ), V >= 0).
g8_two_way_table_from_json(Dict, partial(Rows, Columns, Cells, RowTotals,
                                         ColumnTotals, Grand)) :-
    is_dict(Dict), get_dict(kind, Dict, "two_way_table_partial"),
    get_dict(rows, Dict, Rows), get_dict(columns, Dict, Columns),
    get_dict(cells, Dict, Raw),
    length(Rows, R), length(Columns, C), R >= 2, C >= 2,
    length(Raw, R),
    maplist(partial_row_of_length(C), Raw, Cells),
    optional_list(Dict, row_totals, R, RowTotals),
    optional_list(Dict, column_totals, C, ColumnTotals),
    ( get_dict(grand_total, Dict, G0) -> maybe_quantity(G0, Grand)
    ; Grand = unknown ).

row_of_length(C, Raw, Row) :-
    length(Raw, C), maplist(g8_quantity, Raw, Row).

partial_row_of_length(C, Raw, Row) :-
    length(Raw, C), maplist(maybe_quantity, Raw, Row).

maybe_quantity("?", unknown) :- !.
maybe_quantity(V, Q) :- g8_quantity(V, Q).

optional_list(Dict, Key, Length, List) :-
    (   get_dict(Key, Dict, Raw), is_list(Raw), length(Raw, Length)
    ->  maplist(maybe_quantity, Raw, List)
    ;   length(List, Length), maplist(=(unknown), List)
    ).

% ==========================================================================
% 2. STATES
% ==========================================================================

g8_two_way_table_states(
    [ q_read_the_cross_classified_counts,
      q_total_each_row,
      q_total_each_column,
      q_recover_a_missing_cell,
      q_verify_totals_both_ways,
      q_accept_completed_table,
      q_refuse_incompletable_table,
      q_divide_each_cell_by_its_row_total,
      q_divide_each_cell_by_its_column_total,
      q_divide_each_cell_by_the_grand_total,
      q_compare_two_rows,
      q_report_association ]).

% g8_two_way_table_state_label(State, Tradition, Label, Citation).
g8_two_way_table_state_label(q_read_the_cross_classified_counts,
    illustrative_mathematics, "a two-way table",
    "IM Grade 8 Unit 6 Lesson 9, Looking for Associations").
g8_two_way_table_state_label(q_read_the_cross_classified_counts,
    van_de_walle, "categorical data cross-classified by two questions",
    "Van de Walle, ch. 21, Analyzing Data").
g8_two_way_table_state_label(q_total_each_row, illustrative_mathematics,
    "the row totals",
    "IM Grade 8 Unit 6 Lesson 9, Looking for Associations").
g8_two_way_table_state_label(q_divide_each_cell_by_its_row_total,
    illustrative_mathematics, "relative frequencies by row",
    "IM Grade 8 Unit 6 Lesson 10, Using Data Displays to Find Associations").
g8_two_way_table_state_label(q_divide_each_cell_by_the_grand_total,
    ccss, "relative frequencies calculated for rows or columns",
    "CCSS 8.SP.A.4, via IM Grade 8 Unit 6 Lesson 10").
g8_two_way_table_state_label(q_compare_two_rows, illustrative_mathematics,
    "comparing the rows to look for an association",
    "IM Grade 8 Unit 6 Lesson 10, Using Data Displays to Find Associations").
g8_two_way_table_state_label(q_report_association, provisional,
    "the difference between the two rows",
    "provisional; the engine reports the difference and never rules on it").
g8_two_way_table_state_label(q_refuse_incompletable_table, provisional,
    "the table does not carry enough to complete itself",
    "provisional; no community label sourced for this refusal").

% ==========================================================================
% 3. TRANSITIONS
% ==========================================================================

g8_two_way_table_transition(complete_two_way_table,
    q_read_the_cross_classified_counts, recover_a_missing_cell,
    q_recover_a_missing_cell).
g8_two_way_table_transition(complete_two_way_table,
    q_recover_a_missing_cell, verify_totals_both_ways,
    q_verify_totals_both_ways).
g8_two_way_table_transition(complete_two_way_table,
    q_verify_totals_both_ways, report_completed_table, q_accept_completed_table).
g8_two_way_table_transition(complete_two_way_table,
    q_recover_a_missing_cell, refuse_incompletable_table,
    q_refuse_incompletable_table).
g8_two_way_table_transition(relative_frequency_by_row,
    q_read_the_cross_classified_counts, total_each_row, q_total_each_row).
g8_two_way_table_transition(relative_frequency_by_row,
    q_total_each_row, divide_each_cell_by_its_row_total,
    q_divide_each_cell_by_its_row_total).
g8_two_way_table_transition(relative_frequency_by_column,
    q_read_the_cross_classified_counts, total_each_column, q_total_each_column).
g8_two_way_table_transition(relative_frequency_by_column,
    q_total_each_column, divide_each_cell_by_its_column_total,
    q_divide_each_cell_by_its_column_total).
g8_two_way_table_transition(relative_frequency_of_whole_table,
    q_read_the_cross_classified_counts, divide_each_cell_by_the_grand_total,
    q_divide_each_cell_by_the_grand_total).
g8_two_way_table_transition(association_between_two_rows,
    q_divide_each_cell_by_its_row_total, compare_two_rows, q_compare_two_rows).
g8_two_way_table_transition(association_between_two_rows,
    q_compare_two_rows, report_association, q_report_association).

% ==========================================================================
% 4. THE RUN
% ==========================================================================

run_g8_two_way_table(relative_frequency_by_row, table(Rows, Columns, Cells),
                     Outcome, Trace) :-
    maplist(sum_list, Cells, RowTotals),
    forall(member(T, RowTotals), T > 0),
    maplist(row_fractions, Cells, RowTotals, Fractions),
    maplist(sum_list, Fractions, RowSums),
    ( forall(member(S, RowSums), S =:= 1) -> Validity = correct
    ; Validity = unvindicated ),
    maplist(percent_row, Fractions, Percentages),
    Outcome = action_outcome(
        relative_frequency_by_row,
        [ classification(productive),
          cluster(g8_two_way_tables_and_association),
          automaton_state(q_divide_each_cell_by_its_row_total),
          vocabulary([two_way_table, categorical_variable, row_total,
                      relative_frequency, percentage]),
          input(table(Rows, Columns, Cells)),
          result(relative_frequencies_by_row(Percentages)),
          expected(relative_frequencies_by_row(Percentages)),
          fractions(Fractions),
          row_totals(RowTotals),
          row_sums(RowSums),
          invariant(each_row_of_relative_frequencies_sums_to_one),
          validity(Validity) ]),
    Trace = [ read_the_cross_classified_counts(Rows, Columns),
              total_each_row(RowTotals),
              divide_each_cell_by_its_row_total(Percentages) ].
run_g8_two_way_table(relative_frequency_by_column, table(Rows, Columns, Cells),
                     Outcome, Trace) :-
    transpose(Cells, ByColumn),
    maplist(sum_list, ByColumn, ColumnTotals),
    forall(member(T, ColumnTotals), T > 0),
    maplist(row_fractions, ByColumn, ColumnTotals, Fractions),
    maplist(sum_list, Fractions, ColumnSums),
    ( forall(member(S, ColumnSums), S =:= 1) -> Validity = correct
    ; Validity = unvindicated ),
    maplist(percent_row, Fractions, Percentages),
    Outcome = action_outcome(
        relative_frequency_by_column,
        [ classification(productive),
          cluster(g8_two_way_tables_and_association),
          automaton_state(q_divide_each_cell_by_its_column_total),
          vocabulary([two_way_table, categorical_variable, column_total,
                      relative_frequency, percentage]),
          input(table(Rows, Columns, Cells)),
          result(relative_frequencies_by_column(Percentages)),
          expected(relative_frequencies_by_column(Percentages)),
          fractions(Fractions),
          column_totals(ColumnTotals),
          column_sums(ColumnSums),
          invariant(each_column_of_relative_frequencies_sums_to_one),
          validity(Validity) ]),
    Trace = [ read_the_cross_classified_counts(Rows, Columns),
              total_each_column(ColumnTotals),
              divide_each_cell_by_its_column_total(Percentages) ].
run_g8_two_way_table(relative_frequency_of_whole_table,
                     table(Rows, Columns, Cells), Outcome, Trace) :-
    maplist(sum_list, Cells, RowTotals),
    sum_list(RowTotals, Grand),
    Grand > 0,
    maplist(whole_table_fractions(Grand), Cells, Fractions),
    maplist(sum_list, Fractions, PartSums),
    sum_list(PartSums, Total),
    ( Total =:= 1 -> Validity = correct ; Validity = unvindicated ),
    maplist(percent_row, Fractions, Percentages),
    Outcome = action_outcome(
        relative_frequency_of_whole_table,
        [ classification(productive),
          cluster(g8_two_way_tables_and_association),
          automaton_state(q_divide_each_cell_by_the_grand_total),
          vocabulary([two_way_table, grand_total, relative_frequency,
                      percentage]),
          input(table(Rows, Columns, Cells)),
          result(relative_frequencies_of_whole_table(Percentages)),
          expected(relative_frequencies_of_whole_table(Percentages)),
          fractions(Fractions),
          grand_total(Grand),
          table_sum(Total),
          invariant(the_whole_table_of_relative_frequencies_sums_to_one),
          validity(Validity) ]),
    Trace = [ read_the_cross_classified_counts(Rows, Columns),
              divide_each_cell_by_the_grand_total(Grand, Percentages) ].
run_g8_two_way_table(association_between_two_rows,
                     compare(table(Rows, Columns, Cells), FirstRow, SecondRow,
                             Column),
                     Outcome, Trace) :-
    nth0(FirstRow, Cells, RowA), nth0(SecondRow, Cells, RowB),
    sum_list(RowA, TotalA), sum_list(RowB, TotalB),
    TotalA > 0, TotalB > 0,
    nth0(Column, RowA, CellA), nth0(Column, RowB, CellB),
    ShareA is CellA rdiv TotalA,
    ShareB is CellB rdiv TotalB,
    Difference is ShareA - ShareB,
    Rebuilt is ShareB + Difference,
    ( Rebuilt =:= ShareA -> Validity = correct ; Validity = unvindicated ),
    percent_text(ShareA, TextA), percent_text(ShareB, TextB),
    percent_text(Difference, TextD),
    nth0(FirstRow, Rows, LabelA), nth0(SecondRow, Rows, LabelB),
    nth0(Column, Columns, ColumnLabel),
    Outcome = action_outcome(
        association_between_two_rows,
        [ classification(productive),
          cluster(g8_two_way_tables_and_association),
          automaton_state(q_report_association),
          vocabulary([two_way_table, association, conditional_frequency,
                      comparison, percentage]),
          input(compare(table(Rows, Columns, Cells), FirstRow, SecondRow,
                        Column)),
          result(row_comparison(LabelA-TextA, LabelB-TextB, ColumnLabel,
                                difference(TextD))),
          expected(row_comparison(LabelA-TextA, LabelB-TextB, ColumnLabel,
                                  difference(TextD))),
          shares(ShareA, ShareB),
          difference(Difference),
          invariant(the_difference_carries_one_share_to_the_other),
          validity(Validity) ]),
    Trace = [ compare_two_rows(LabelA, LabelB, ColumnLabel),
              report_association(TextA, TextB, TextD) ].
run_g8_two_way_table(complete_two_way_table,
                     partial(Rows, Columns, Cells, RowTotals, ColumnTotals,
                             Grand),
                     Outcome, Trace) :-
    (   complete(Cells, RowTotals, ColumnTotals, Grand, Filled)
    ->  maplist(sum_list, Filled, FilledRowTotals),
        transpose(Filled, ByColumn),
        maplist(sum_list, ByColumn, FilledColumnTotals),
        sum_list(FilledRowTotals, GrandFromRows),
        sum_list(FilledColumnTotals, GrandFromColumns),
        (   GrandFromRows =:= GrandFromColumns,
            totals_agree(RowTotals, FilledRowTotals),
            totals_agree(ColumnTotals, FilledColumnTotals),
            ( Grand == unknown -> true ; Grand =:= GrandFromRows )
        ->  Validity = correct
        ;   Validity = unvindicated
        ),
        Outcome = action_outcome(
            complete_two_way_table,
            [ classification(productive),
              cluster(g8_two_way_tables_and_association),
              automaton_state(q_accept_completed_table),
              vocabulary([two_way_table, missing_cell, row_total,
                          column_total, grand_total]),
              input(partial(Rows, Columns, Cells, RowTotals, ColumnTotals,
                            Grand)),
              result(completed_table(Filled)),
              expected(completed_table(Filled)),
              row_totals(FilledRowTotals),
              column_totals(FilledColumnTotals),
              grand_total(GrandFromRows, GrandFromColumns),
              invariant(rows_and_columns_agree_on_the_grand_total),
              validity(Validity) ]),
        Trace = [ read_the_cross_classified_counts(Rows, Columns),
                  recover_a_missing_cell(Filled),
                  verify_totals_both_ways(GrandFromRows, GrandFromColumns),
                  report_completed_table(Filled) ]
    ;   Outcome = action_outcome(
            complete_two_way_table,
            [ classification(refusal),
              cluster(g8_two_way_tables_and_association),
              automaton_state(q_refuse_incompletable_table),
              vocabulary([two_way_table, missing_cell, underdetermined]),
              input(partial(Rows, Columns, Cells, RowTotals, ColumnTotals,
                            Grand)),
              result(refused(table_does_not_determine_its_missing_cells)),
              refusal(refusal{kind: "two_way_table_underdetermined"}),
              validity(refused) ]),
        Trace = [ read_the_cross_classified_counts(Rows, Columns),
                  refuse_incompletable_table ]
    ).

% Explicit recursion rather than a lambda: yall copies its body, so a
% closure over Total would be renamed apart and left unbound.
row_fractions([], _, []).
row_fractions([C|Cs], Total, [F|Fs]) :-
    F is C rdiv Total,
    row_fractions(Cs, Total, Fs).

whole_table_fractions(_, [], []).
whole_table_fractions(Grand, [C|Cs], [F|Fs]) :-
    F is C rdiv Grand,
    whole_table_fractions(Grand, Cs, Fs).

percent_row(Fractions, Texts) :- maplist(percent_text, Fractions, Texts).

percent_text(Fraction, Text) :-
    Scaled is Fraction * 100,
    g8_decimal_approximation(Scaled, 0, Rounded),
    Whole is round(Rounded),
    format(string(Text), "~w%", [Whole]).

totals_agree([], []).
totals_agree([unknown|T], [_|U]) :- !, totals_agree(T, U).
totals_agree([V|T], [W|U]) :- V =:= W, totals_agree(T, U).

%!  complete(+Cells, +RowTotals, +ColumnTotals, +Grand, -Filled) is semidet.
%
%   Recover missing cells by repeated single-gap closure: a row or column
%   with exactly one unknown and a known total determines that unknown.
%   Fails when the table does not determine itself, which is a refusal
%   rather than a guess.
complete(Cells, RowTotals, ColumnTotals, Grand, Filled) :-
    infer_margins(RowTotals, ColumnTotals, Grand, R, C),
    close_gaps(Cells, R, C, Filled),
    forall(( member(Row, Filled), member(V, Row) ), nonnegative_number(V)).

nonnegative_number(V) :- number(V), V >= 0.

%!  infer_margins(+RowTotals, +ColumnTotals, +Grand, -R, -C) is det.
%
%   A margin with exactly one unknown entry and a known grand total
%   determines that entry. Run until nothing more closes.
infer_margins(RowTotals, ColumnTotals, Grand, R, C) :-
    close_margin(RowTotals, Grand, R0),
    close_margin(ColumnTotals, Grand, C0),
    grand_from(R0, C0, Grand, Grand1),
    (   Grand1 == Grand
    ->  R = R0, C = C0
    ;   infer_margins(R0, C0, Grand1, R, C)
    ).

close_margin(Totals, Grand, Closed) :-
    (   Grand \== unknown,
        include_unknown(Totals, 1)
    ->  known_sum(Totals, Known),
        Value is Grand - Known,
        replace_unknown(Totals, Value, Closed)
    ;   Closed = Totals
    ).

grand_from(R, C, unknown, Grand) :-
    (   \+ memberchk(unknown, R)
    ->  sum_list(R, Grand)
    ;   \+ memberchk(unknown, C)
    ->  sum_list(C, Grand)
    ;   Grand = unknown
    ).
grand_from(_, _, Grand, Grand) :- Grand \== unknown.

close_gaps(Cells, RowTotals, ColumnTotals, Filled) :-
    (   one_pass(Cells, RowTotals, ColumnTotals, Next), Next \== Cells
    ->  close_gaps(Next, RowTotals, ColumnTotals, Filled)
    ;   Filled = Cells,
        \+ ( member(Row, Filled), memberchk(unknown, Row) )
    ).

one_pass(Cells, RowTotals, ColumnTotals, Out) :-
    close_rows(Cells, RowTotals, Rowwise),
    transpose(Rowwise, ByColumn),
    close_rows(ByColumn, ColumnTotals, ColumnClosed),
    transpose(ColumnClosed, Out).

close_rows([], [], []).
close_rows([Row|Rows], [Total|Totals], [Closed|Rest]) :-
    close_one(Row, Total, Closed),
    close_rows(Rows, Totals, Rest).

close_one(Row, Total, Closed) :-
    (   Total \== unknown,
        include_unknown(Row, 1)
    ->  known_sum(Row, Known),
        Value is Total - Known,
        replace_unknown(Row, Value, Closed)
    ;   Closed = Row
    ).

include_unknown(Row, Count) :-
    foldl([V, A, B]>>( V == unknown -> B is A + 1 ; B = A ), Row, 0, Count).

known_sum(Row, Sum) :-
    foldl([V, A, B]>>( V == unknown -> B = A ; B is A + V ), Row, 0, Sum).

replace_unknown([unknown|T], Value, [Value|T]) :- !.
replace_unknown([H|T], Value, [H|Rest]) :- replace_unknown(T, Value, Rest).

% ==========================================================================
% 5. SELF-SUMMARY
% ==========================================================================

g8_two_way_table_summary(
    summary{ module: g8_two_way_table_association,
             status: authored_pilot,
             generated: false,
             grade: 8,
             cluster: g8_two_way_tables_and_association,
             doings: [ complete_two_way_table,
                       relative_frequency_by_row,
                       relative_frequency_by_column,
                       relative_frequency_of_whole_table,
                       association_between_two_rows ],
             verification: rows_and_columns_agree_and_frequencies_sum_to_one,
             arithmetic: exact_rational_with_percentages_beside,
             adjudication: none_the_engine_reports_the_difference,
             deformation_partners: none_attested_at_this_locus,
             imported_by: none,
             extant_machines_left_untouched:
                 [ 'statistics/categorical_frequency_bar_representation',
                   'statistics/estimate_probability_from_observed_frequency' ] }).

% ==========================================================================
% 6. RECEIPTS
% ==========================================================================

g8_two_way_table_receipt(
    'im_defrag_5f40fba082de7620a3187bbe_1', 'IM-G8-U6-L9',
    relative_frequency_by_row,
    _{kind: "two_way_table",
      rows: ["10 to 12 years old", "13 to 15 years old", "16 to 18 years old"],
      columns: ["has cell phone", "does not have cell phone"],
      cells: [[25, 35], [40, 10], [50, 10]]},
    relative_frequencies_by_row([["42%", "58%"], ["80%", "20%"],
                                 ["83%", "17%"]])).
g8_two_way_table_receipt(
    'im_defrag_5f40fba082de7620a3187bbe_1', 'IM-G8-U6-L9',
    relative_frequency_of_whole_table,
    _{kind: "two_way_table",
      rows: ["10 to 12 years old", "13 to 15 years old", "16 to 18 years old"],
      columns: ["has cell phone", "does not have cell phone"],
      cells: [[25, 35], [40, 10], [50, 10]]},
    relative_frequencies_of_whole_table([["15%", "21%"], ["24%", "6%"],
                                         ["29%", "6%"]])).
g8_two_way_table_receipt(
    'im_defrag_892c930bab7b2f4969579218_1', 'IM-G8-U6-L10',
    relative_frequency_by_row,
    _{kind: "two_way_table",
      rows: ["red", "blue", "yellow", "green"],
      columns: ["unflawed", "flawed"],
      cells: [[285, 15], [223, 17], [120, 80], [195, 65]]},
    relative_frequencies_by_row([["95%", "5%"], ["93%", "7%"],
                                 ["60%", "40%"], ["75%", "25%"]])).
g8_two_way_table_receipt(
    'im_defrag_892c930bab7b2f4969579218_1', 'IM-G8-U6-L10',
    relative_frequency_by_column,
    _{kind: "two_way_table",
      rows: ["red", "blue", "yellow", "green"],
      columns: ["unflawed", "flawed"],
      cells: [[285, 15], [223, 17], [120, 80], [195, 65]]},
    relative_frequencies_by_column([["35%", "27%", "15%", "24%"],
                                    ["8%", "10%", "45%", "37%"]])).
g8_two_way_table_receipt(
    'im_defrag_ab161cbb883e1496c7df2c4a_1', 'IM-G8-U6-L10',
    relative_frequency_by_row,
    _{kind: "two_way_table",
      rows: ["class A", "class B"],
      columns: ["prefers math", "prefers science", "prefers recess"],
      cells: [[6, 3, 8], [8, 7, 15]]},
    relative_frequencies_by_row([["35%", "18%", "47%"],
                                 ["27%", "23%", "50%"]])).
g8_two_way_table_receipt(
    'im_defrag_b6c94497749a10a71bd962e3_1', 'IM-G8-U6-L10',
    complete_two_way_table,
    _{kind: "two_way_table_partial",
      rows: ["plays sport", "does not play sport"],
      columns: ["plays instrument", "does not play instrument"],
      cells: [[5, "?"], ["?", "?"]],
      row_totals: [16, "?"], column_totals: ["?", 15], grand_total: 25},
    completed_table([[5, 11], [5, 4]])).
g8_two_way_table_receipt(
    'im_defrag_dbf89012934421ee15f04d7d_1', 'IM-G8-U6-L9',
    complete_two_way_table,
    _{kind: "two_way_table_partial",
      rows: ["plays a sport", "does not play a sport"],
      columns: ["plays an instrument", "does not play an instrument"],
      cells: [["?", 16], [5, "?"]],
      row_totals: ["?", "?"], column_totals: ["?", "?"], grand_total: 25},
    refused(table_does_not_determine_its_missing_cells)).

% ==========================================================================
% 7. CHECK
% ==========================================================================

check_g8_two_way_table_association :-
    check_receipts,
    check_association_reported_not_judged,
    check_negative,
    format('g8_two_way_table_association: all checks ok~n').

check_receipts :-
    findall(Lesson-Row-Doing-Result,
            ( g8_two_way_table_receipt(Row, Lesson, Doing, Json, Expected),
              g8_two_way_table_from_json(Json, Figure),
              run_g8_two_way_table(Doing, Figure, Outcome, _),
              outcome_property(Outcome, result(Result)),
              Result = Expected,
              outcome_property(Outcome, validity(V)),
              memberchk(V, [correct, refused])
            ), Rows),
    findall(R-L, g8_two_way_table_receipt(R, L, _, _, _), All),
    length(All, Total), length(Rows, Passed),
    Total =:= Passed,
    format('  receipts: ~w/~w real grade 8 rows run, each closing its totals or summing to one~n',
           [Passed, Total]),
    forall(member(Lesson-Row-Doing-Result, Rows),
           format('    ~w  ~w  ~w~n', [Lesson, Row, Doing])).

check_association_reported_not_judged :-
    % IM-G8-U6-L10: the yellow machine's flaw rate against the red machine's.
    g8_two_way_table_from_json(
        _{kind: "two_way_table",
          rows: ["red", "blue", "yellow", "green"],
          columns: ["unflawed", "flawed"],
          cells: [[285, 15], [223, 17], [120, 80], [195, 65]]}, T),
    run_g8_two_way_table(association_between_two_rows,
                         compare(T, 2, 0, 1), O, _),
    outcome_property(O, result(row_comparison("yellow"-"40%", "red"-"5%",
                                              "flawed", difference("35%")))),
    outcome_property(O, validity(correct)),
    % The engine reports the difference and never says whether it matters.
    \+ outcome_property(O, verdict(_)),
    format('  association: yellow flaws at 40% against red at 5%, a difference of 35 points, reported and not ruled on~n').

check_negative :-
    % A one-column table is not a cross-classification and refuses.
    \+ g8_two_way_table_from_json(
           _{kind: "two_way_table", rows: ["a", "b"], columns: ["x"],
             cells: [[1], [2]]}, _),
    % Every by-row frequency set sums to exactly 1 as a rational, which a
    % rounded percentage pair need not: 42% and 58% happen to sum to 100,
    % but the invariant is checked on the fractions.
    g8_two_way_table_from_json(
        _{kind: "two_way_table", rows: ["a", "b"],
          columns: ["x", "y"], cells: [[1, 2], [1, 5]]}, T),
    run_g8_two_way_table(relative_frequency_by_row, T, O, _),
    outcome_property(O, row_sums(Sums)),
    forall(member(S, Sums), S =:= 1),
    outcome_property(O, fractions([[A, B], [_, _]])),
    A =:= 1 rdiv 3, B =:= 2 rdiv 3,
    format('  negative tests: a one-column table refuses; the row invariant is checked on exact thirds, not on rounded percentages~n').

outcome_property(action_outcome(_, Props), Property) :-
    memberchk(Property, Props).
