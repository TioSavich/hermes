:- encoding(utf8).
/** <module> Standards-to-doing router pilot
 *
 * This quarantined pilot joins a parsed statement to the receipt-backed CCSS
 * doing store.  Standard rows narrow the admissible operations, witnessed
 * task patterns license a second path, and decoded table shape licenses the
 * grade 8 table machines.  Concrete JSON shapes are checked against
 * automaton_input_contract/5 before values are bound into them.  This module
 * does not evaluate an arithmetic relation or table cell.
 *
 * Program is a list of Prolog terms, not the JSON strings used to transport
 * those terms in the language experiment artifact.  InputJSON is always a
 * JSON object string suitable for the worker's strategy_trace input field.
 */
:- module(standards_router_pilot,
          [ route_statement/3,
            pattern_guards_hold/2,
            check_pattern_guards/0,
            check_standards_router_pilot/0,
            check_table_routes/0
          ]).

:- use_module(library(http/json)).
:- use_module(library(lists)).
:- ensure_loaded(standards(ccss/geometry)).
:- ensure_loaded(standards(im/lesson_anchors)).
:- ensure_loaded(im_lessons('generated/lesson_standard_anchors')).
:- use_module(im_lessons('generated/vision_lesson_digest'),
              [vision_lesson_standard/3]).
:- use_module(im_lessons('generated/compiled_action_mappings'),
              [compiled_lesson_strategy/4]).
:- use_module(standards(standard_doing), [standard_doing/5]).
:- use_module(strategies(automaton_input_contracts),
              [automaton_input_contract/5]).
:- use_module(strategies('math/g8_action_pairs'),
              [g8_decode_input/2, run_g8_action/4]).
:- use_module('serialized_table_reader_pilot',
              [serialized_table_reading/3, serialized_table_facts/3]).
:- use_module('task_pattern_pilot',
              [ task_pattern/6,
                task_pattern_witness/5
              ]).

%!  route_statement(+Program:list, +Lesson:atom, -Route) is det.
%
%   Route is route(Family, Kind, InputJSON, because(License, Support)) or
%   abstain(Reason, Detail).  A non-unique program decision is returned as an
%   abstention; support never breaks an operation tie.
route_statement(Program, _Lesson, Route) :-
    must_be(list, Program),
    member(table_layout(_,_,_,_), Program),
    !,
    table_route(Program, Route).
route_statement(Program, Lesson, Route) :-
    must_be(list, Program),
    findall(Code,
            lesson_ccss_code(Lesson, Code),
            Codes0),
    sort(Codes0, Codes),
    route_with_codes(Codes, Program, Lesson, Route),
    !.

%! table_route(+Program, -Route) is det.
%
%  A decoded table is a third licensing source beside standards codes and
%  witnessed task patterns.  Shape selects or narrows a registered grade-8
%  machine; this router only assembles its input object.
table_route(Program, Route) :-
    member(table_layout(TableId,columns(Columns),rows(RowCount),
                        header(Header)), Program),
    table_rows(Program, TableId, RowCount, Columns, Rows),
    table_route_for(TableId, Columns, RowCount, Header, Rows, Program, Route),
    !.

% Input/output is the named function-table genre even when its rectangular
% shape also meets one of the more general numeric-pair rules.
table_route_for(TableId, 2, RowCount,
                [words(InputName),words(OutputName)], Rows, _Program, Route) :-
    table_label(InputName, "input"),
    table_label(OutputName, "output"),
    numeric_or_blank_pairs(Rows),
    !,
    ( rows_have_blank(Rows)
    -> Route = abstain(holes_outside_completion_route,
                       shape(TableId,columns(2),rows(RowCount)))
    ; Route = abstain(undecided(machine),
                      tied([decide_whether_the_table_is_a_function,
                            fit_linear_rule_to_table]))
    ).
table_route_for(TableId, Columns, RowCount, [blank|Headers], Rows,
                _Program,
                abstain(measurement_labels_do_not_witness_counts,
                        shape(TableId,columns(Columns),rows(RowCount),
                              header([blank|Headers])))) :-
    Columns >= 3,
    measurement_labeled_headers(Headers),
    rows_have_blank(Rows),
    !.
table_route_for(TableId, Columns, RowCount, [blank|Headers], Rows,
                Program, Route) :-
    Columns >= 3,
    two_way_shape(Headers, Rows, Shape),
    two_way_evidence(Headers, Rows, Program, TableId),
    !,
    ( table_has_share(Program, TableId)
    -> Route = abstain(shares_not_counts,
                       shape(TableId,columns(Columns),rows(RowCount)))
    ; \+ two_way_count_shape(Shape)
    -> Route = abstain(no_table_route,
                       shape(TableId,columns(Columns),rows(RowCount),
                             counts_not_witnessed))
    ; table_has_blank_cell(Program, TableId)
    -> two_way_partial_json(Shape, InputJSON),
       registered_table_kind(complete_two_way_table),
       Route = route(grade8, complete_two_way_table, InputJSON,
                     because(table_reading(TableId),
                             shape(columns(Columns),rows(RowCount))))
    ; Route = abstain(undecided(machine),
                      tied([relative_frequency_by_column,
                            relative_frequency_by_row,
                            relative_frequency_of_whole_table]))
    ).
table_route_for(TableId, 2, 2, [words(InputName),words(OutputName)], Rows,
                _Program, Route) :-
    complete_numeric_pairs(Rows, [[X1,Y1],[X2,Y2]]),
    !,
    registered_table_kind(rate_of_change_from_two_observations),
    Dict = _{kind:"linear_model", given:"two_observations",
             first:_{input:X1,output:Y1}, second:_{input:X2,output:Y2},
             input_name:InputName, output_name:OutputName},
    json_dict_string(Dict, InputJSON),
    Route = route(grade8, rate_of_change_from_two_observations, InputJSON,
                  because(table_reading(TableId),
                          shape(columns(2),rows(2)))).
table_route_for(_TableId, 2, RowCount,
                [words(_),words(_)], Rows, _Program,
                abstain(undecided(machine), tied(Kinds))) :-
    RowCount >= 3,
    complete_numeric_pairs(Rows, _),
    !,
    scatter_tied_kinds(Kinds).
table_route_for(_TableId, 3, RowCount,
                [blank,words(_),words(_)], Rows, _Program,
                abstain(undecided(machine), tied(Kinds))) :-
    RowCount >= 3,
    labeled_numeric_pairs(Rows),
    !,
    scatter_tied_kinds(Kinds).
table_route_for(TableId, Columns, RowCount, Header, _Rows, _Program,
                abstain(no_table_route,
                        shape(TableId,columns(Columns),rows(RowCount),
                              header(Header)))).

registered_table_kind(Kind) :-
    automaton_input_contract(grade8, Kind, _Schema, _Example,
                             verified(strategy_trace_ok)).

scatter_tied_kinds([association_direction_from_the_fit,
                    furthest_point_from_the_fitted_line,
                    least_squares_line_from_pairs,
                    range_of_each_variable]).

table_rows(Program, TableId, RowCount, Columns, Rows) :-
    findall(Row,
            ( between(1, RowCount, RowIndex),
              findall(Reading,
                      ( between(1, Columns, ColIndex),
                        memberchk(table_cell(TableId,RowIndex,ColIndex,Reading),
                                  Program)
                      ),
                      Row),
              length(Row, Columns)
            ),
            Rows),
    length(Rows, RowCount).

table_label(Surface, Label) :-
    string_lower(Surface, Lower),
    Lower == Label.

measurement_labeled_headers(Headers) :-
    member(words(Surface), Headers),
    string_lower(Surface, Lower),
    measurement_unit(Unit),
    format(string(Marker), '(~w)', [Unit]),
    sub_string(Lower, _, _, _, Marker),
    !.

measurement_unit(inch).
measurement_unit(inches).
measurement_unit(cm).
measurement_unit(centimeter).
measurement_unit(centimeters).
measurement_unit(mm).
measurement_unit(meter).
measurement_unit(meters).
measurement_unit(km).
measurement_unit(kilometer).
measurement_unit(kilometers).
measurement_unit(foot).
measurement_unit(feet).
measurement_unit(mile).
measurement_unit(miles).
measurement_unit(second).
measurement_unit(seconds).
measurement_unit(minute).
measurement_unit(minutes).
measurement_unit(hour).
measurement_unit(hours).
measurement_unit(gram).
measurement_unit(grams).
measurement_unit(kilogram).
measurement_unit(kilograms).
measurement_unit(pound).
measurement_unit(pounds).
measurement_unit(degree).
measurement_unit(degrees).

numeric_or_blank_pairs(Rows) :-
    forall(member(Row, Rows),
           ( Row = [Left,Right],
             numeric_or_blank(Left), numeric_or_blank(Right) )).

numeric_or_blank(blank).
numeric_or_blank(numeral(_,_)).

complete_numeric_pairs(Rows, Pairs) :-
    maplist(numeric_pair, Rows, Pairs).

numeric_pair([numeral(X,_),numeral(Y,_)], [X,Y]).

rows_have_blank(Rows) :-
    member(Row, Rows),
    memberchk(blank, Row),
    !.

labeled_numeric_pairs(Rows) :-
    forall(member(Row, Rows),
           Row = [words(_),numeral(_,_),numeral(_,_)]).

table_has_share(Program, TableId) :-
    member(table_cell(TableId,_,_,share(_,_)), Program),
    !.

table_has_blank_cell(Program, TableId) :-
    member(table_cell(TableId,_,_,blank), Program),
    !.

two_way_evidence(Headers, _Rows, _Program, _TableId) :-
    member(words(Label), Headers),
    table_label(Label, "total"),
    !.
two_way_evidence(_Headers, Rows, _Program, _TableId) :-
    member([words(Label)|_], Rows),
    table_label(Label, "total"),
    !.
two_way_evidence(_Headers, Rows, _Program, _TableId) :-
    length(Rows, 2),
    !.
two_way_evidence(_Headers, _Rows, Program, TableId) :-
    ( table_has_share(Program, TableId)
    ; table_has_blank_cell(Program, TableId)
    ),
    !.

two_way_shape(Headers, Rows,
              two_way(ColumnNames,RowNames,Cells,RowTotals,
                      ColumnTotals,GrandTotal)) :-
    strip_total_header(Headers, ColumnHeaders, HasTotalColumn),
    length(ColumnHeaders, ColumnCount),
    ColumnCount >= 2,
    maplist(words_surface, ColumnHeaders, ColumnNames),
    strip_total_row(Rows, DataRows, TotalRow),
    length(DataRows, DataCount),
    DataCount >= 2,
    maplist(two_way_data_row(ColumnCount, HasTotalColumn), DataRows,
            RowNames, Cells, RowTotals),
    two_way_total_values(ColumnCount, HasTotalColumn, TotalRow,
                         ColumnTotals, GrandTotal),
    append(Cells, [RowTotals,ColumnTotals,[GrandTotal]], ReadingGroups),
    forall((member(Group, ReadingGroups), member(Value, Group)),
           two_way_reading(Value)).

strip_total_header(Headers, Columns, true) :-
    append(Columns, [words(Total)], Headers),
    table_label(Total, "total"),
    !.
strip_total_header(Headers, Headers, false).

strip_total_row(Rows, DataRows, TotalValues) :-
    append(DataRows, [[words(Total)|TotalValues]], Rows),
    table_label(Total, "total"),
    !.
strip_total_row(Rows, Rows, none).

two_way_data_row(ColumnCount, true, [words(Label)|Values], Label,
                 Cells, RowTotal) :-
    length(Cells, ColumnCount),
    append(Cells, [RowTotal], Values).
two_way_data_row(ColumnCount, false, [words(Label)|Cells], Label,
                 Cells, blank) :-
    length(Cells, ColumnCount).

two_way_total_values(ColumnCount, true, Values, ColumnTotals, Grand) :-
    Values \== none,
    length(ColumnTotals, ColumnCount),
    append(ColumnTotals, [Grand], Values),
    !.
two_way_total_values(ColumnCount, _HasTotalColumn, Values,
                     ColumnTotals, blank) :-
    Values \== none,
    length(ColumnTotals, ColumnCount),
    Values = ColumnTotals,
    !.
two_way_total_values(ColumnCount, _HasTotalColumn, none,
                     ColumnTotals, blank) :-
    length(ColumnTotals, ColumnCount),
    maplist(=(blank), ColumnTotals).

words_surface(words(Surface), Surface).

count_reading(blank).
count_reading(numeral(Value,_)) :- integer(Value), Value >= 0.

two_way_reading(blank).
two_way_reading(numeral(_,_)).
two_way_reading(share(_,_)).

two_way_count_shape(two_way(_,_,Cells,RowTotals,ColumnTotals,GrandTotal)) :-
    append(Cells, [RowTotals,ColumnTotals,[GrandTotal]], CountGroups),
    forall((member(Group, CountGroups), member(Value, Group)),
           count_reading(Value)).

two_way_partial_json(two_way(ColumnNames,RowNames,Cells0,RowTotals0,
                             ColumnTotals0,Grand0), InputJSON) :-
    maplist(count_row_json, Cells0, Cells),
    maplist(count_json, RowTotals0, RowTotals),
    maplist(count_json, ColumnTotals0, ColumnTotals),
    count_json(Grand0, GrandTotal),
    Dict = _{kind:"two_way_table_partial", rows:RowNames,
             columns:ColumnNames, cells:Cells,
             row_totals:RowTotals, column_totals:ColumnTotals,
             grand_total:GrandTotal},
    json_dict_string(Dict, InputJSON).

count_row_json(Readings, Values) :- maplist(count_json, Readings, Values).
count_json(blank, "?").
count_json(numeral(Value,_), Value).

route_with_codes([], Program, _Lesson, Route) :-
    pattern_route(Program, Route).
route_with_codes(Codes, Program, Lesson, Route) :-
    Codes \= [],
    support_rows(Codes, Rows, Total),
    (   Total < 10
    ->  pattern_route(Program, PatternRoute),
        (   PatternRoute = route(_, _, _, _)
        ->  Route = PatternRoute
        ;   Route = abstain(thin_support, codes_total(Codes, Total))
        )
    ;   admissible_operations(Rows, Admissible),
        route_admitted(Program, Lesson, Codes, Rows, Total, Admissible, Route)
    ).

code_atom(Code, Code) :-
    atom(Code),
    !.
code_atom(CodeString, Code) :-
    string(CodeString),
    atom_string(Code, CodeString).

% This is the slice-1 source union without lesson_monitoring's Indiana import.
% Generated explicit rows retain priority. Otherwise the IM anchor store and
% vision `addressing` rows contribute CCSS codes.
lesson_ccss_code(Lesson, Code) :-
    lesson_monitoring:explicit_lesson_standard(Lesson, _, _, _),
    lesson_monitoring:explicit_lesson_standard(Lesson, ccss, RawCode, _),
    code_atom(RawCode, Code).
lesson_ccss_code(Lesson, Code) :-
    \+ lesson_monitoring:explicit_lesson_standard(Lesson, _, _, _),
    base_lesson_ccss_code(Lesson, Code).
lesson_ccss_code(Lesson, Code) :-
    vision_lesson_standard(Lesson, addressing, RawCode),
    code_atom(RawCode, Code).

base_lesson_ccss_code(Lesson, Code) :-
    lesson_parts(Lesson, Grade, Unit, LessonNumber),
    small_grade_concept(Grade, Unit, LessonNumber, Concept),
    standard_anchor(Concept, ccss, RawCode, _Statement),
    code_atom(RawCode, Code).
base_lesson_ccss_code(Lesson, Code) :-
    lesson_parts(Lesson, Grade, Unit, _LessonNumber),
    memberchk(Grade, ['6', '7', '8']),
    atomic_list_concat(['IM-G', Grade, '-U', Unit], UnitCode),
    atom_string(UnitCode, UnitCodeString),
    standard_anchor(Concept, im_lesson, UnitCodeString, _Title),
    standard_anchor(Concept, ccss, RawCode, _Statement),
    code_atom(RawCode, Code).

lesson_parts(Lesson, Grade, Unit, LessonNumber) :-
    atomic_list_concat(['IM', GradeToken, UnitToken, LessonToken], '-', Lesson),
    atom_concat('G', Grade, GradeToken),
    atom_concat('U', Unit, UnitToken),
    atom_concat('L', LessonNumber, LessonToken).

small_grade_concept('K', Unit, LessonNumber, Concept) :-
    atomic_list_concat([im_kindergarten, '_u', Unit, '_l', LessonNumber],
                       Concept).
small_grade_concept(Grade, Unit, LessonNumber, Concept) :-
    memberchk(Grade, ['1', '2', '3', '4', '5']),
    atomic_list_concat([im_grade, Grade, '_u', Unit, '_l', LessonNumber],
                       Concept).

support_rows(Codes, Rows, Total) :-
    findall(row(Code, Operation, Genre, N, Witness),
            ( member(Code, Codes),
              standard_doing(Code, Operation, Genre,
                             support(N, _Receipts, _Share), Witness)
            ),
            Rows),
    findall(N, member(row(_, _, _, N, _), Rows), Counts),
    sum_list(Counts, Total).

admissible_operations(Rows, Admissible) :-
    findall(Operation, member(row(_, Operation, _, _, _), Rows), Ops0),
    sort(Ops0, Admissible).

route_admitted(Program, _Lesson, Codes, _Rows, _Total, _Admissible,
               abstain(no_arithmetic_relation, Codes)) :-
    \+ program_operation_candidates(Program, _Candidates),
    !.
route_admitted(Program, _Lesson, _Codes, _Rows, _Total, Admissible,
               abstain(undecided(operation), admissible(Admissible))) :-
    program_operation_candidates(Program, Candidates),
    intersection(Candidates, Admissible, Intersection),
    sort(Intersection, Deciders),
    Deciders = [_,_|_],
    !.
route_admitted(Program, Lesson, Codes, Rows, Total, Admissible, Route) :-
    program_operation_candidates(Program, Candidates),
    intersection(Candidates, Admissible, Intersection0),
    sort(Intersection0, Intersection),
    (   Intersection = [Operation]
    ->  route_decided(Operation, Program, Lesson, Codes, Rows, Total, Route)
    ;   Intersection == []
    ->  Route = abstain(no_automaton_for_operation,
                        program_candidates(Candidates,
                                           admissible(Admissible)))
    ;   Route = abstain(undecided(operation), admissible(Admissible))
    ).

%!  program_operation_candidates(+Program, -Candidates) is semidet.
%
%   Candidates are operation-facing standard_doing families.  Multiple
%   relations contribute a union; they do not gain a support-based tie-break.
program_operation_candidates(Program, Candidates) :-
    findall(Operation,
            ( relevant_arithmetic_relation(Program, Outer, Expression),
              relation_operation_candidate(Program, Outer, Expression,
                                           Operation)
            ),
            Candidates0),
    sort(Candidates0, Candidates),
    Candidates \= [].

relevant_arithmetic_relation(Program, Outer, Expression) :-
    member(relation(Outer, Expression, _Surface), Program),
    arithmetic_expression(Expression),
    (   member(asks(result, Outer), Program)
    ->  true
    ;   \+ member(asks(result, _), Program)
    ).

arithmetic_expression(sum(_)).
arithmetic_expression(difference(_, _)).
arithmetic_expression(convert(_, _)).
arithmetic_expression(scale(_, _)).
arithmetic_expression(invert_scale(_, _)).
arithmetic_expression(quotient(_, _)).
arithmetic_expression(has_part(_, _)).

relation_operation_candidate(_Program, _Outer, sum(_), add).
relation_operation_candidate(_Program, _Outer, sum(_), add_fractions).
relation_operation_candidate(_Program, _Outer, sum(_), decimal_add).
relation_operation_candidate(_Program, _Outer, difference(_, _), subtract).
relation_operation_candidate(_Program, _Outer, difference(_, _),
                             subtract_fractions).
relation_operation_candidate(_Program, _Outer, convert(_, _), multiply).
relation_operation_candidate(Program, Outer, scale(Left, Right), multiply) :-
    quantity_value(Program, Outer, unknown),
    quantity_value(Program, Left, LeftValue),
    quantity_value(Program, Right, RightValue),
    LeftValue \== unknown,
    RightValue \== unknown.
relation_operation_candidate(Program, Outer, scale(Left, Right), divide) :-
    quantity_value(Program, Outer, OuterValue),
    OuterValue \== unknown,
    ( quantity_value(Program, Left, unknown)
    ; quantity_value(Program, Right, unknown)
    ).
relation_operation_candidate(Program, Outer, scale(Left, Right), multiply) :-
    \+ scale_position_decides(Program, Outer, Left, Right).
relation_operation_candidate(Program, Outer, scale(Left, Right), divide) :-
    \+ scale_position_decides(Program, Outer, Left, Right).
relation_operation_candidate(_Program, _Outer, invert_scale(_, _), divide).
relation_operation_candidate(_Program, _Outer, quotient(_, _), divide).
relation_operation_candidate(_Program, _Outer, has_part(_, _), add).
relation_operation_candidate(_Program, _Outer, has_part(_, _), subtract).

scale_position_decides(Program, Outer, Left, Right) :-
    quantity_value(Program, Outer, unknown),
    quantity_value(Program, Left, LeftValue),
    quantity_value(Program, Right, RightValue),
    LeftValue \== unknown,
    RightValue \== unknown,
    !.
scale_position_decides(Program, Outer, Left, Right) :-
    quantity_value(Program, Outer, OuterValue),
    OuterValue \== unknown,
    ( quantity_value(Program, Left, unknown)
    ; quantity_value(Program, Right, unknown)
    ).

quantity_value(Program, Referent, Value) :-
    member(quantity(Referent, Value, _Kind), Program),
    !.

%!  pattern_route(+Program:list, -Route) is det.
%
%   Use the witnessed task-pattern store as a second licensing source.  The
%   store's unregistered/no_published_contract row is a sentinel and can only
%   produce an explicit pattern_unlicensed abstention.
pattern_route(Program, Route) :-
    (   program_operation_candidates(Program, Candidates)
    ->  pattern_route_candidates(Program, Candidates, Route)
    ;   Route = abstain(no_arithmetic_relation, [])
    ).

pattern_route_candidates(_Program, _Candidates,
                         abstain(unsupported_pattern_guard, Guard)) :-
    unsupported_store_guard(Guard),
    !.
pattern_route_candidates(Program, Candidates, Route) :-
    findall(Match,
            licensed_pattern_match(Program, Candidates, Match),
            Licensed0),
    sort(Licensed0, Licensed),
    (   Licensed = [_|_]
    ->  select_pattern_match(Program, Licensed, Route)
    ;   findall(Id,
                sentinel_pattern_match(Program, Candidates, Id),
                SentinelIds0),
        sort(SentinelIds0, SentinelIds),
        (   SentinelIds = [Id|_]
        ->  Route = abstain(pattern_unlicensed, pattern(Id))
        ;   Route = abstain(no_pattern, candidates(Candidates))
        )
    ).

licensed_pattern_match(Program, Candidates,
                       candidate(Kind, Witnesses, Id, Operation,
                                 Family, Schema)) :-
    task_pattern(Id, operation(PatternOperation), base(Base),
                 constraints(Guards), _Witness,
                 contract_join(Family, Schema)),
    \+ sentinel_contract_join(Family, Schema),
    PatternOperation =.. [Operation|_],
    memberchk(Operation, Candidates),
    pattern_operation_bindings(PatternOperation, Base, Program, Bindings),
    pattern_guards_hold(Guards, Bindings),
    task_pattern_witness(Id, _Row, _Lesson, machine(Kind),
                         verified(strategy_trace_correct)),
    pattern_machine_witness_count(Id, Kind, Witnesses).

sentinel_pattern_match(Program, Candidates, Id) :-
    task_pattern(Id, operation(PatternOperation), base(Base),
                 constraints(Guards), _Witness,
                 contract_join(Family, Schema)),
    sentinel_contract_join(Family, Schema),
    PatternOperation =.. [Operation|_],
    memberchk(Operation, Candidates),
    pattern_operation_bindings(PatternOperation, Base, Program, Bindings),
    pattern_guards_hold(Guards, Bindings).

sentinel_contract_join(unregistered, no_published_contract).

pattern_machine_witness_count(Id, Kind, Count) :-
    findall(Row,
            task_pattern_witness(Id, Row, _Lesson, machine(Kind),
                                 verified(strategy_trace_correct)),
            Rows),
    length(Rows, Count),
    Count > 0.

select_pattern_match(Program, Matches, Route) :-
    findall(N, member(candidate(_, N, _, _, _, _), Matches), Counts),
    max_list(Counts, TopCount),
    include(candidate_has_count(TopCount), Matches, TopMatches),
    findall(Kind,
            member(candidate(Kind, TopCount, _, _, _, _), TopMatches),
            TopKinds0),
    sort(TopKinds0, TopKinds),
    (   TopKinds = [Kind]
    ->  include(candidate_has_kind(Kind), TopMatches, KindMatches0),
        sort(KindMatches0, KindMatches),
        KindMatches = [candidate(Kind, TopCount, Id, Operation,
                                 Family, Schema)|_],
        route_pattern_contract(Operation, Program, Id, Family, Kind, Schema,
                               TopCount, Route)
    ;   Route = abstain(undecided(machine), tied(TopKinds))
    ).

candidate_has_count(Count, candidate(_, Count, _, _, _, _)).
candidate_has_kind(Kind, candidate(Kind, _, _, _, _, _)).

route_pattern_contract(Operation, Program, Id, Family, Kind, Schema,
                       Witnesses, Route) :-
    (   automaton_input_contract(Family, Kind, Schema, _Example,
                                 verified(strategy_trace_ok))
    ->  fill_contract(Operation, Program, Schema, Fill),
        (   Fill = filled(InputJSON)
        ->  Route = route(Family, Kind, InputJSON,
                          because(pattern(Id), witnesses(Witnesses)))
        ;   Fill = underfilled(Detail)
        ->  Route = abstain(contract_underfilled, Detail)
        )
    ;   Route = abstain(no_automaton_for_operation, Operation)
    ).

%!  pattern_operation_bindings(+PatternOperation, +Base, +Program, -Bindings)
%   is nondet.
%
%   Bind the pattern's numeral-free argument names to values carried by one
%   relevant arithmetic relation.  A quotient binds divide/2; a missing
%   factor scale is a different relation shape and does not claim that task
%   pattern.
pattern_operation_bindings(PatternOperation, Base, Program, Bindings) :-
    PatternOperation =.. [Operation|Names],
    pattern_operation_values(Operation, Names, Program, Values),
    pairs_keys_values(Pairs, Names, Values),
    Bindings = [base-Base|Pairs].

pattern_operation_values(add, [a,b], Program, [A,B]) :-
    arithmetic_binary_values(add, Program, A, B),
    maplist(integer, [A,B]).
pattern_operation_values(subtract, [a,b], Program, [A,B]) :-
    arithmetic_binary_values(subtract, Program, A, B),
    maplist(integer, [A,B]).
pattern_operation_values(multiply, [a,b], Program, [A,B]) :-
    arithmetic_binary_values(multiply, Program, A, B),
    maplist(integer, [A,B]).
pattern_operation_values(divide, [a,b], Program, [A,B]) :-
    arithmetic_binary_values(divide, Program, A, B),
    maplist(integer, [A,B]).
pattern_operation_values(decimal_add,
                         [left_numeral,left_scale,right_numeral,right_scale],
                         Program, [LeftN,LeftScale,RightN,RightScale]) :-
    arithmetic_binary_values(add, Program, Left, Right),
    rational_components(Left, LeftN, LeftScale),
    rational_components(Right, RightN, RightScale),
    ( LeftScale > 1 ; RightScale > 1 ).
pattern_operation_values(Operation, Names, Program, Values) :-
    memberchk(Operation, [add_fractions,subtract_fractions]),
    fraction_binary_values(Operation, Program, Left, Right),
    fraction_pattern_values(Names, Left, Right, Values).
pattern_operation_values(compare_rectangle_areas,
                         [rectangles_1_length,rectangles_1_width,
                          rectangles_2_length,rectangles_2_width],
                         Program, [L1,W1,L2,W2]) :-
    member(pattern_instance(compare_rectangle_areas(L1,W1,L2,W2)), Program),
    maplist(number, [L1,W1,L2,W2]).

arithmetic_binary_values(add, Program, A, B) :-
    relevant_arithmetic_relation(Program, _Target, sum([Left, Right])),
    known_quantity(Program, Left, A),
    known_quantity(Program, Right, B).
arithmetic_binary_values(add, Program, A, B) :-
    relevant_arithmetic_relation(Program, _Target, has_part(Whole, Part)),
    known_quantity(Program, Whole, A),
    known_quantity(Program, Part, B).
arithmetic_binary_values(subtract, Program, A, B) :-
    relevant_arithmetic_relation(Program, _Target, difference(Left, Right)),
    known_quantity(Program, Left, A),
    known_quantity(Program, Right, B).
arithmetic_binary_values(subtract, Program, A, B) :-
    relevant_arithmetic_relation(Program, _Target, has_part(Whole, Part)),
    known_quantity(Program, Whole, A),
    known_quantity(Program, Part, B).
arithmetic_binary_values(multiply, Program, A, B) :-
    relevant_arithmetic_relation(Program, Target, scale(Left, Right)),
    quantity_value(Program, Target, unknown),
    known_quantity(Program, Left, A),
    known_quantity(Program, Right, B).
arithmetic_binary_values(multiply, Program, A, B) :-
    relevant_arithmetic_relation(Program, _Target, convert(Source, ToKind)),
    known_quantity(Program, Source, A),
    quantity_kind(Program, Source, FromKind),
    member(conversion(FromKind, ToKind, B, _Surface), Program),
    number(B).
arithmetic_binary_values(divide, Program, A, B) :-
    relevant_arithmetic_relation(Program, _Target, quotient(Left, Right)),
    known_quantity(Program, Left, A),
    known_quantity(Program, Right, B).

fraction_binary_values(add_fractions, Program, Left, Right) :-
    arithmetic_binary_values(add, Program, Left, Right),
    ( \+ integer(Left) ; \+ integer(Right) ).
fraction_binary_values(subtract_fractions, Program, Left, Right) :-
    arithmetic_binary_values(subtract, Program, Left, Right),
    ( \+ integer(Left) ; \+ integer(Right) ).

fraction_pattern_values(Names, Left, Right, Values) :-
    maplist(fraction_named_value(Names, Left, Right), Names, Values).

fraction_named_value(Names, Left, _Right, left_whole, Whole) :-
    fraction_mixed_components(Left, Whole, _Numerator, _Denominator),
    memberchk(left_whole, Names).
fraction_named_value(Names, Left, _Right, left_n, Numerator) :-
    (   memberchk(left_whole, Names)
    ->  fraction_mixed_components(Left, _Whole, Numerator, _Denominator)
    ;   rational_components(Left, Numerator, _Denominator)
    ).
fraction_named_value(_Names, Left, _Right, left_d, Denominator) :-
    rational_components(Left, _Numerator, Denominator),
    Denominator > 1.
fraction_named_value(_Names, _Left, Right, right_n, Numerator) :-
    rational_components(Right, Numerator, _Denominator).
fraction_named_value(_Names, _Left, Right, right_d, Denominator) :-
    rational_components(Right, _Numerator, Denominator),
    Denominator > 1.

rational_components(Value, Numerator, Denominator) :-
    rational(Value),
    Numerator is numerator(Value),
    Denominator is denominator(Value).

fraction_mixed_components(Value, Whole, Numerator, Denominator) :-
    rational_components(Value, ImproperNumerator, Denominator),
    Denominator > 1,
    Whole is ImproperNumerator // Denominator,
    Numerator is ImproperNumerator mod Denominator,
    Whole > 0,
    Numerator > 0.

%!  pattern_guards_hold(+Guards:list, +Bindings:list) is semidet.
%
%   Evaluate every guard.  Unsupported guards and expressions throw a named
%   error so a generated vocabulary change cannot silently widen a pattern.
pattern_guards_hold(Guards, Bindings) :-
    memberchk(base-Base, Bindings),
    maplist(pattern_guard_holds(Base, Bindings), Guards).

pattern_guard_holds(_Base, Bindings, zero(P)) :-
    pattern_value(P, Bindings, 0).
pattern_guard_holds(Base, Bindings, digit(P)) :-
    pattern_value(P, Bindings, Value),
    abs(Value) < Base.
pattern_guard_holds(Base, Bindings, digits(P, Digits)) :-
    pattern_value(P, Bindings, Value),
    pattern_digit_count(Value, Base, ActualDigits),
    ActualDigits =:= Digits.
pattern_guard_holds(Base, Bindings, multiple_of_base(P)) :-
    pattern_value(P, Bindings, Value),
    0 =:= Value mod Base.
pattern_guard_holds(Base, Bindings, lt(X, Y)) :-
    pattern_guard_expr(X, Base, Bindings, A),
    pattern_guard_expr(Y, Base, Bindings, B),
    A < B.
pattern_guard_holds(Base, Bindings, leq(X, Y)) :-
    pattern_guard_expr(X, Base, Bindings, A),
    pattern_guard_expr(Y, Base, Bindings, B),
    A =< B.
pattern_guard_holds(Base, Bindings, gt(X, Y)) :-
    pattern_guard_expr(X, Base, Bindings, A),
    pattern_guard_expr(Y, Base, Bindings, B),
    A > B.
pattern_guard_holds(Base, Bindings, geq(X, Y)) :-
    pattern_guard_expr(X, Base, Bindings, A),
    pattern_guard_expr(Y, Base, Bindings, B),
    A >= B.
pattern_guard_holds(Base, Bindings, eq(X, Y)) :-
    pattern_guard_expr(X, Base, Bindings, A),
    pattern_guard_expr(Y, Base, Bindings, B),
    A =:= B.
pattern_guard_holds(Base, Bindings, neq(X, Y)) :-
    pattern_guard_expr(X, Base, Bindings, A),
    pattern_guard_expr(Y, Base, Bindings, B),
    A =\= B.
pattern_guard_holds(Base, Bindings, divides(X, Y)) :-
    pattern_guard_expr(X, Base, Bindings, A),
    pattern_guard_expr(Y, Base, Bindings, B),
    A =\= 0,
    0 =:= B mod A.
pattern_guard_holds(Base, Bindings, not_divides(X, Y)) :-
    pattern_guard_expr(X, Base, Bindings, A),
    pattern_guard_expr(Y, Base, Bindings, B),
    ( A =:= 0 -> true ; 0 =\= B mod A ).
pattern_guard_holds(Base, Bindings, remainder(X, Y)) :-
    pattern_guard_expr(X, Base, Bindings, A),
    pattern_guard_expr(Y, Base, Bindings, B),
    B =\= 0,
    0 =\= A mod B.
pattern_guard_holds(Base, Bindings, divides_one_way(X, Y)) :-
    pattern_guard_expr(X, Base, Bindings, A),
    pattern_guard_expr(Y, Base, Bindings, B),
    ( A =\= 0, 0 =:= B mod A -> true
    ; B =\= 0, 0 =:= A mod B
    ).
pattern_guard_holds(_Base, Bindings, unit_fraction(Side)) :-
    atom_concat(Side, '_n', Parameter),
    pattern_value(Parameter, Bindings, 1).
pattern_guard_holds(_Base, Bindings, whole_part_present) :-
    ( memberchk(left_whole-_, Bindings)
    ; memberchk(right_whole-_, Bindings)
    ).
pattern_guard_holds(_Base, Bindings, denominator_absent_on_one_side) :-
    ( \+ memberchk(left_d-_, Bindings)
    ; \+ memberchk(right_d-_, Bindings)
    ).
pattern_guard_holds(Base, Bindings, scale_is_power_of_base(P)) :-
    pattern_value(P, Bindings, Value),
    pattern_power_of(Value, Base).
pattern_guard_holds(_Base, _Bindings, Guard) :-
    \+ supported_pattern_guard(Guard),
    throw(error(unsupported_pattern_guard(Guard), pattern_guards_hold/2)).

pattern_value(Name, Bindings, Value) :-
    memberchk(Name-Value, Bindings).

pattern_guard_expr(base, Base, _Bindings, Base) :- !.
pattern_guard_expr(Number, _Base, _Bindings, Number) :- number(Number), !.
pattern_guard_expr(ones(P), Base, Bindings, Value) :- !,
    pattern_value(P, Bindings, Number),
    Value is abs(Number) mod Base.
pattern_guard_expr(plus(X, Y), Base, Bindings, Value) :- !,
    pattern_guard_expr(X, Base, Bindings, A),
    pattern_guard_expr(Y, Base, Bindings, B),
    Value is A + B.
pattern_guard_expr(max(X, Y), Base, Bindings, Value) :- !,
    pattern_guard_expr(X, Base, Bindings, A),
    pattern_guard_expr(Y, Base, Bindings, B),
    Value is max(A, B).
pattern_guard_expr(digits(P), Base, Bindings, Value) :- !,
    pattern_value(P, Bindings, Number),
    pattern_digit_count(Number, Base, Value).
pattern_guard_expr(Name, _Base, Bindings, Value) :-
    atom(Name),
    pattern_value(Name, Bindings, Value),
    !.
pattern_guard_expr(Expression, _Base, _Bindings, _Value) :-
    \+ supported_pattern_expr(Expression),
    throw(error(unsupported_pattern_guard_expression(Expression),
                pattern_guards_hold/2)).

pattern_digit_count(Value, Base, Digits) :-
    Absolute is abs(truncate(Value)),
    (   Absolute =:= 0
    ->  Digits = 1
    ;   pattern_digit_count_(Absolute, Base, 0, Digits)
    ).

pattern_digit_count_(0, _Base, Count, Digits) :-
    !,
    Digits = Count.
pattern_digit_count_(Number, Base, Count0, Count) :-
    Count1 is Count0 + 1,
    Next is Number // Base,
    pattern_digit_count_(Next, Base, Count1, Count).

pattern_power_of(Value, Base) :-
    Value >= 1,
    pattern_power_of_(Value, Base).

pattern_power_of_(1, _Base) :- !.
pattern_power_of_(Value, Base) :-
    0 =:= Value mod Base,
    Next is Value // Base,
    pattern_power_of_(Next, Base).

unsupported_store_guard(Guard) :-
    task_pattern(_Id, _Operation, _Base, constraints(Guards), _Witness, _Join),
    member(Guard, Guards),
    \+ supported_pattern_guard(Guard),
    !.

supported_pattern_guard(zero(_)).
supported_pattern_guard(digit(_)).
supported_pattern_guard(digits(_, _)).
supported_pattern_guard(multiple_of_base(_)).
supported_pattern_guard(lt(X, Y)) :- supported_pattern_expr(X), supported_pattern_expr(Y).
supported_pattern_guard(leq(X, Y)) :- supported_pattern_expr(X), supported_pattern_expr(Y).
supported_pattern_guard(gt(X, Y)) :- supported_pattern_expr(X), supported_pattern_expr(Y).
supported_pattern_guard(geq(X, Y)) :- supported_pattern_expr(X), supported_pattern_expr(Y).
supported_pattern_guard(eq(X, Y)) :- supported_pattern_expr(X), supported_pattern_expr(Y).
supported_pattern_guard(neq(X, Y)) :- supported_pattern_expr(X), supported_pattern_expr(Y).
supported_pattern_guard(divides(X, Y)) :- supported_pattern_expr(X), supported_pattern_expr(Y).
supported_pattern_guard(not_divides(X, Y)) :- supported_pattern_expr(X), supported_pattern_expr(Y).
supported_pattern_guard(remainder(X, Y)) :- supported_pattern_expr(X), supported_pattern_expr(Y).
supported_pattern_guard(divides_one_way(X, Y)) :- supported_pattern_expr(X), supported_pattern_expr(Y).
supported_pattern_guard(unit_fraction(_)).
supported_pattern_guard(whole_part_present).
supported_pattern_guard(denominator_absent_on_one_side).
supported_pattern_guard(scale_is_power_of_base(_)).

supported_pattern_expr(base).
supported_pattern_expr(Value) :- number(Value).
supported_pattern_expr(Value) :- atom(Value), Value \== base.
supported_pattern_expr(ones(_)).
supported_pattern_expr(plus(X, Y)) :- supported_pattern_expr(X), supported_pattern_expr(Y).
supported_pattern_expr(max(X, Y)) :- supported_pattern_expr(X), supported_pattern_expr(Y).
supported_pattern_expr(digits(_)).

%!  check_pattern_guards is det.
%
%   Receipt that this evaluator accepts every generated pattern's own
%   witness, including the sentinel row, without consulting the generator's
%   private evaluator.
check_pattern_guards :-
    (   unsupported_store_guard(Guard)
    ->  throw(error(unsupported_pattern_guard(Guard), check_pattern_guards/0))
    ;   true
    ),
    forall(task_pattern(Id, operation(Operation), base(Base),
                        constraints(Guards), witness(Witness), _Join),
           check_pattern_guard_witness(Id, Operation, Base, Guards, Witness)),
    aggregate_all(count, task_pattern(_, _, _, _, _, _), PatternCount),
    aggregate_all(count,
                  task_pattern(_, _, _, _, _,
                               contract_join(unregistered,
                                             no_published_contract)),
                  SentinelCount),
    format('check_pattern_guards: ok patterns=~d sentinels=~d~n',
           [PatternCount, SentinelCount]).

check_pattern_guard_witness(Id, Operation, Base, Guards, Witness) :-
    Operation =.. [_|Names],
    Witness =.. [_|Values],
    pairs_keys_values(Pairs, Names, Values),
    Bindings = [base-Base|Pairs],
    (   pattern_guards_hold(Guards, Bindings)
    ->  true
    ;   throw(error(witness_outside_pattern_guards(Id),
                    check_pattern_guards/0))
    ).

route_decided(Operation, Program, Lesson, Codes, Rows, Total, Route) :-
    registry_family(Operation, Family),
    operation_rows(Operation, Rows, OperationRows),
    choose_contract_row(OperationRows, Lesson, Family,
                        Kind, Schema, Genre, SelectedSupport),
    !,
    fill_contract(Operation, Program, Schema, Fill),
    (   Fill = filled(InputJSON)
    ->  Route = route(Family, Kind, InputJSON,
                      because(Codes,
                              support(total(Total),
                                      selected(SelectedSupport),
                                      genre(Genre))))
    ;   Fill = underfilled(Detail)
    ->  Route = abstain(contract_underfilled, Detail)
    ).
route_decided(Operation, _Program, _Lesson, _Codes, _Rows, _Total,
              abstain(no_automaton_for_operation, Operation)).

operation_rows(Operation, Rows, OperationRows) :-
    include(row_has_operation(Operation), Rows, OperationRows).

row_has_operation(Operation, row(_, Operation, _, _, _)).

registry_family(add, addition).
registry_family(subtract, subtraction).
registry_family(multiply, multiplication).
registry_family(divide, division).
registry_family(decimal_add, decimal).
registry_family(decimal_subtract, decimal).
registry_family(decimal_multiply, decimal).
registry_family(decimal_divide, decimal).
registry_family(add_fractions, fraction).
registry_family(subtract_fractions, fraction).

choose_contract_row(Rows, Lesson, Family, Kind, Schema, Genre, Support) :-
    ranked_contract_rows(Rows, Ranked),
    member(_Key-row(_Code, _Operation, Genre, Support, Witness), Ranked),
    contract_kind_for_row(Lesson, Family, Genre, Witness, Kind, Schema),
    !.

ranked_contract_rows(Rows, Ranked) :-
    findall(Key-Row,
            ( member(Row, Rows),
              Row = row(Code, _Operation, Genre, Support, _Witness),
              NegativeSupport is -Support,
              Key = NegativeSupport-Code-Genre
            ),
            Pairs),
    keysort(Pairs, Ranked).

contract_kind_for_row(Lesson, Family, Genre, _Witness, Kind, Schema) :-
    compiled_lesson_strategy(Lesson, Family, Kind, _Evidence),
    automaton_input_contract(Family, Kind, Schema, _Example,
                             verified(strategy_trace_ok)),
    schema_genre(Schema, Genre),
    !.
contract_kind_for_row(_Lesson, Family, Genre,
                      witness(_RowId, Kind, _WitnessInput, _Result),
                      Kind, Schema) :-
    automaton_input_contract(Family, Kind, Schema, _Example,
                             verified(strategy_trace_ok)),
    schema_genre(Schema, Genre).

schema_genre(Schema, Genre) :-
    atom_json_dict(Schema, Dict, [value_string_as(string)]),
    (   get_dict(kind, Dict, KindString)
    ->  atom_string(Genre, KindString)
    ;   get_dict(a, Dict, _),
        get_dict(b, Dict, _)
    ->  Genre = 'a|b'
    ).

fill_contract(Operation, Program, Schema, Fill) :-
    schema_genre(Schema, Genre),
    contract_bindings(Operation, Program, Genre, Bindings0),
    sort(Bindings0, Bindings),
    (   Bindings = [Dict]
    ->  json_dict_string(Dict, InputJSON),
        Fill = filled(InputJSON)
    ;   Bindings == []
    ->  underfilled_detail(Genre, Program, Detail),
        Fill = underfilled(Detail)
    ;   findall(Target,
                ( member(binding(Target, _), Bindings0) ),
                Targets0),
        sort(Targets0, Targets),
        Fill = underfilled(multiple_targets(Targets))
    ).

contract_bindings(Operation, Program, Genre, Bindings) :-
    findall(Binding,
            contract_binding(Operation, Program, Genre, Binding),
            Bindings).

contract_binding(add, Program, 'a|b', binding(Target, _{a:A, b:B})) :-
    relevant_arithmetic_relation(Program, Target, sum([Left, Right])),
    known_quantity(Program, Left, A),
    known_quantity(Program, Right, B).
contract_binding(subtract, Program, 'a|b', binding(Target, _{a:A, b:B})) :-
    relevant_arithmetic_relation(Program, Target, difference(Left, Right)),
    known_quantity(Program, Left, A),
    known_quantity(Program, Right, B).
contract_binding(multiply, Program, 'a|b', binding(Target, _{a:A, b:B})) :-
    relevant_arithmetic_relation(Program, Target, scale(Left, Right)),
    quantity_value(Program, Target, unknown),
    known_quantity(Program, Left, A),
    known_quantity(Program, Right, B).
contract_binding(multiply, Program, 'a|b', binding(Target, _{a:A, b:B})) :-
    relevant_arithmetic_relation(Program, Target, convert(Source, ToKind)),
    known_quantity(Program, Source, A),
    quantity_kind(Program, Source, FromKind),
    member(conversion(FromKind, ToKind, B, _Surface), Program),
    number(B).
contract_binding(divide, Program, 'a|b', binding(Unknown, _{a:A, b:B})) :-
    relevant_arithmetic_relation(Program, Outer, scale(Left, Right)),
    known_quantity(Program, Outer, A),
    division_known_argument(Program, Left, Right, Unknown, B).
contract_binding(divide, Program, 'a|b', binding(Target, _{a:A, b:B})) :-
    relevant_arithmetic_relation(Program, Target, quotient(Left, Right)),
    known_quantity(Program, Left, A),
    known_quantity(Program, Right, B).

division_known_argument(Program, Left, Right, Left, B) :-
    quantity_value(Program, Left, unknown),
    known_quantity(Program, Right, B).
division_known_argument(Program, Left, Right, Right, B) :-
    quantity_value(Program, Right, unknown),
    known_quantity(Program, Left, B).

known_quantity(Program, Referent, Value) :-
    quantity_value(Program, Referent, Value),
    Value \== unknown,
    number(Value).

quantity_kind(Program, Referent, Kind) :-
    member(quantity(Referent, _Value, Kind), Program),
    !.

underfilled_detail(decimal_pair, Program, left.scale) :-
    member(relation(_, sum([Left, _Right]), _), Program),
    quantity_value(Program, Left, Value),
    rational(Value),
    \+ integer(Value),
    !.
underfilled_detail(Genre, _Program, required(Genre)).

json_dict_string(binding(_Target, Dict), JSON) :-
    !,
    json_dict_string(Dict, JSON).
json_dict_string(Dict, JSON) :-
    with_output_to(string(JSON),
                   json_write_dict(current_output, Dict, [width(0)])).

%!  check_standards_router_pilot is det.
%
%   Focused deterministic checks for the five examples in design section 3.3
%   plus pattern licensing, refusal, machine-tie, and sentinel receipts.
%   The fourth check pins the current threshold-three store boundary: its
%   decimal_add support-two row is absent, so the router refuses before contract
%   filling instead of manufacturing an admission.
check_standards_router_pilot :-
    check_pattern_guards,
    example_route_1(Route1),
    require_route(Route1, addition, count_on_from_larger,
                  '{"a":15, "b":23}'),
    example_route_2(Route2),
    require_route(Route2, subtraction, compare_by_matching_difference,
                  '{"a":12, "b":7}'),
    example_route_3(Route3),
    require_route(Route3, multiplication, multiplication_fact_retrieval,
                  '{"a":4, "b":10}'),
    example_route_4(Route4),
    require_term(Route4,
                 abstain(no_automaton_for_operation,
                         program_candidates([add,add_fractions,decimal_add],
                                            admissible([divide,multiply])))),
    example_route_5(Route5),
    require_term(Route5,
                 abstain(thin_support,
                         codes_total(['5.OA.A.2'], 4))),
    undecided_example(Undecided),
    require_term(Undecided,
                 abstain(undecided(operation),
                         admissible([add,subtract]))),
    pattern_route_example(PatternRoute),
    require_route(PatternRoute, addition, column_addition_with_carrying,
                  '{"a":6, "b":8}'),
    PatternRoute = route(_, _, _, PatternBecause),
    require_term(PatternBecause,
                 because(pattern(tp_add_cross_base_a1_b1), witnesses(1))),
    no_pattern_example(NoPattern),
    require_term(NoPattern,
                 abstain(no_pattern,
                         candidates([add,add_fractions,decimal_add]))),
    pattern_tie_example(PatternTie),
    require_term(PatternTie,
                 abstain(undecided(machine),
                         tied([column_addition_with_carrying,
                               take_away_base_ones]))),
    sentinel_pattern_example(Sentinel),
    require_term(Sentinel,
                 abstain(pattern_unlicensed,
                         pattern(tp_compare_rectangle_areas_r1l1_r1w1_r2l1_r2w1))),
    format('check_standards_router_pilot: ok examples=5 pattern=4 undecided=2~n').

%! check_table_routes is det.
%
%  The table fixtures pin both routing and the two machines this slice may
%  reach.  The asserted outcomes below were measured through g8_decode_input/2
%  and run_g8_action/4; no outcome is calculated in this router.
check_table_routes :-
    serialized_table_reader_pilot:fixture_f1(F1),
    fixture_table_facts(F1, Facts1),
    route_statement(Facts1, 'IM-G8-U3-L3', Route1),
    require_route(Route1, grade8, rate_of_change_from_two_observations,
                  '{"kind":"linear_model","given":"two_observations","first":{"input":10,"output":14},"second":{"input":25,"output":35},"input_name":"salt (grams)","output_name":"honey (grams)"}'),
    run_table_route(Route1, Outcome1),
    Outcome1 = action_outcome(rate_of_change_from_two_observations, Props1),
    memberchk(result(model("7/5","0")), Props1),
    memberchk(model(MeasuredRate,0), Props1),
    MeasuredRate =:= 7 rdiv 5,
    memberchk(validity(correct), Props1),
    serialized_table_reader_pilot:fixture_f2(F2),
    fixture_table_facts(F2, Facts2),
    route_statement(Facts2, 'IM-G8-U6-L2', Route2),
    scatter_tied_kinds(ScatterKinds),
    require_term(Route2,
                 abstain(undecided(machine), tied(ScatterKinds))),
    serialized_table_reader_pilot:fixture_f3(F3),
    fixture_table_facts(F3, Facts3),
    route_statement(Facts3, 'IM-G8-U6-L10', Route3),
    require_route(Route3, grade8, complete_two_way_table,
                  '{"kind":"two_way_table_partial","rows":["plays sport","does not play sport"],"columns":["plays instrument","does not play instrument"],"cells":[[5,"?"],["?","?"]],"row_totals":[16,"?"],"column_totals":["?",15],"grand_total":25}'),
    run_table_route(Route3, Outcome3),
    Outcome3 = action_outcome(complete_two_way_table, Props3),
    memberchk(result(completed_table([[5,11],[5,4]])), Props3),
    memberchk(row_totals([16,9]), Props3),
    memberchk(column_totals([10,15]), Props3),
    memberchk(grand_total(25,25), Props3),
    memberchk(validity(correct), Props3),
    Shares = "| | plays an instrument | does not play an instrument | total | |-----------------------|-----------------------|-------------------------------|---------| | plays a sport | | 89% | 100% | | does not play a sport | 71% | | 100% |",
    fixture_table_facts(Shares, ShareFacts),
    route_statement(ShareFacts, 'IM-G8-U6-L10', ShareRoute),
    require_term(ShareRoute,
                 abstain(shares_not_counts,
                         shape(table_1,columns(4),rows(2)))),
    CompleteTwoWay = "| | red | blue | |---|---|---| | class A | 5 | 6 | | class B | 7 | 8 |",
    fixture_table_facts(CompleteTwoWay, CompleteTwoWayFacts),
    route_statement(CompleteTwoWayFacts, 'IM-G8-U6-L3', CompleteTwoWayRoute),
    require_term(CompleteTwoWayRoute,
                 abstain(undecided(machine),
                         tied([relative_frequency_by_column,
                               relative_frequency_by_row,
                               relative_frequency_of_whole_table]))),
    CrashProgram = [
        table_layout(s2_table_1,columns(3),rows(4),
                     header([blank,words("height (inches)"),
                             words("shadow length (inches)")])),
        table_cell(s2_table_1,1,1,words("younger boy")),
        table_cell(s2_table_1,1,2,numeral(43,"43")),
        table_cell(s2_table_1,1,3,numeral(29,"29")),
        table_cell(s2_table_1,2,1,words("man")),
        table_cell(s2_table_1,2,2,numeral(72,"72")),
        table_cell(s2_table_1,2,3,numeral(48,"48")),
        table_cell(s2_table_1,3,1,words("older boy")),
        table_cell(s2_table_1,3,2,numeral(51,"51")),
        table_cell(s2_table_1,3,3,numeral(34,"34")),
        table_cell(s2_table_1,4,1,words("lamppost")),
        table_cell(s2_table_1,4,2,blank),
        table_cell(s2_table_1,4,3,numeral(114,"114"))
    ],
    route_statement(CrashProgram, 'IM-G8-U2-L13', CrashRoute),
    require_term(
        CrashRoute,
        abstain(measurement_labels_do_not_witness_counts,
                shape(s2_table_1,columns(3),rows(4),
                      header([blank,words("height (inches)"),
                              words("shadow length (inches)")])))),
    serialized_table_reader_pilot:fixture_f4(F4),
    fixture_table_facts(F4, Facts4),
    findall(TableId,
            member(table_layout(TableId,_,_,_), Facts4),
            TableIds),
    TableIds == [table_1,table_2,table_3],
    forall(member(TableId, TableIds),
           ( facts_for_table(Facts4, TableId, TableFacts),
             route_statement(TableFacts, 'IM-G8-U5-L1', Route4),
             require_term(Route4,
                          abstain(holes_outside_completion_route,
                                  shape(TableId,columns(2),rows(3))))
           )),
    format('check_table_routes: ok F1=model(7/5,0) F3=completed_table([[5,11],[5,4]]) abstentions=7~n').

fixture_table_facts(Text, Facts) :-
    serialized_table_reading(Text, Tables, _Remnants),
    serialized_table_facts(Tables, Facts, _FactSpans).

run_table_route(route(grade8, Kind, InputJSON, _Because), Outcome) :-
    atom_json_dict(InputJSON, InputDict, []),
    g8_decode_input(InputDict, Decoded),
    run_g8_action(Kind, Decoded, Outcome, _Trace).

facts_for_table(Facts, TableId, TableFacts) :-
    include(fact_for_table(TableId), Facts, TableFacts).

fact_for_table(TableId, table_layout(TableId,_,_,_)).
fact_for_table(TableId, table_cell(TableId,_,_,_)).

require_route(route(Family, Kind, JSON, _Because), Family, Kind, ExpectedJSON) :-
    string(JSON),
    atom_json_dict(JSON, Dict, []),
    atom_json_dict(ExpectedJSON, Expected, []),
    Dict =@= Expected,
    !.
require_route(Route, Family, Kind, JSON) :-
    throw(error(unexpected_route(Route, Family, Kind, JSON),
                check_standards_router_pilot/0)).

require_term(Actual, Expected) :-
    Actual =@= Expected,
    !.
require_term(Actual, Expected) :-
    throw(error(unexpected_term(Actual, Expected),
                check_standards_router_pilot/0)).

example_route_1(Route) :-
    Program = [quantity(jada_seed_apple_part,15,seed),
               quantity(jada_seed_orange_part,23,seed),
               quantity(jada_seed_total,unknown,seed),
               relation(jada_seed_total,
                        sum([jada_seed_apple_part,jada_seed_orange_part]), ""),
               asks(result,jada_seed_total),
               discrete_kinds([seed])],
    route_statement(Program, 'IM-G2-U2-L14', Route).

example_route_2(Route) :-
    Program = [quantity(lin_ticket_initial,7,ticket),
               quantity(mai_ticket_initial,12,ticket),
               quantity(mai_ticket_comparison_more_result,unknown,ticket),
               relation(mai_ticket_comparison_more_result,
                        difference(mai_ticket_initial,lin_ticket_initial), ""),
               asks(result,mai_ticket_comparison_more_result)],
    route_statement(Program, 'IM-G1-U8-L6', Route).

example_route_3(Route) :-
    Program = [quantity(there_box_initial,4,box),
               conversion(box,toy,10,""),
               quantity(there_toy_converted,unknown,toy),
               relation(there_toy_converted,
                        convert(there_box_initial,toy), ""),
               asks(result,there_toy_converted)],
    route_statement(Program, 'IM-G3-U1-L15', Route).

example_route_4(Route) :-
    Program = [quantity(expression_left,6r5,value),
               quantity(expression_right,13r100,value),
               quantity(expression_result,unknown,value),
               relation(expression_result,
                        sum([expression_left,expression_right]), ""),
               asks(result,expression_result)],
    route_statement(Program, 'IM-G5-U5-L11', Route).

example_route_5(Route) :-
    Program = [quantity(expression_total,78,value),
               quantity(expression_divisor,6,scalar),
               quantity(expression_result,unknown,value),
               relation(expression_total,
                        scale(expression_divisor,expression_result), ""),
               asks(result,expression_result)],
    route_statement(Program, 'IM-G5-U4-L16', Route).

undecided_example(Route) :-
    Program = [quantity(whole,9,object),
               quantity(part,4,object),
               quantity(result,unknown,object),
               relation(result,has_part(whole,part), ""),
               asks(result,result)],
    route_statement(Program, 'IM-G2-U2-L14', Route).

pattern_route_example(Route) :-
    Program = [quantity(left,6,item),
               quantity(right,8,item),
               quantity(total,unknown,item),
               relation(total,sum([left,right]), ""),
               asks(result,total)],
    route_statement(Program, 'MTB-PATTERN-ADD', Route).

no_pattern_example(Route) :-
    Program = [quantity(left,12345,item),
               quantity(right,67890,item),
               quantity(total,unknown,item),
               relation(total,sum([left,right]), ""),
               asks(result,total)],
    route_statement(Program, 'MTB-NO-PATTERN', Route).

pattern_tie_example(Route) :-
    Program = [quantity(whole,9,item),
               quantity(part,4,item),
               quantity(result,unknown,item),
               relation(result,has_part(whole,part), ""),
               asks(result,result)],
    route_statement(Program, 'MTB-PATTERN-TIE', Route).

sentinel_pattern_example(Route) :-
    Program = [pattern_instance(compare_rectangle_areas(9,2,4,5))],
    pattern_route_candidates(Program, [compare_rectangle_areas], Route).
