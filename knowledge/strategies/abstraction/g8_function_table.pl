:- encoding(utf8).
/** <module> Grade 8 pilot: input-output tables and whether they are functions
 *
 * WHAT THIS IS. A quarantined pilot automaton for the doing IM grade 8 unit 5
 * opens with: read a table of input-output pairs, decide whether it describes
 * a function, and where it does and the rule is linear, find the rule and
 * evaluate it at a new input.
 *
 * WHY IT EXISTS NOW. An earlier pass in this lane called the functions cluster
 * an honest zero because the rules "were images" and the tables had gone. That
 * was a claim about the SOURCE, and re-reading the source overturned it: the
 * docling `document.json` carries these tables as structured items with their
 * cells populated, twelve of them in IM-G8-U5-L1 alone, even though the
 * markdown export shows only "1. Pause here". The zero was honest and it was
 * wrong; the tables were there the whole time, one file over.
 *
 * THE FUNCTION TEST IS THE DEFINITION, EXECUTED. A table describes a function
 * exactly when no input carries two different outputs. The automaton groups
 * the rows by input and reports the first input that carries two, with both
 * outputs named, so the verdict comes with its own witness rather than as an
 * assertion. IM-G8-U5-L2's four tables are built to be discriminated this way:
 * squaring is a function, its reverse is not, a constant output is a function,
 * and a constant input is not.
 *
 * THE RULE IS FITTED AND CHECKED ON EVERY ROW. A linear rule is derived from
 * two rows and then substituted into ALL of them in exact rational arithmetic.
 * A table that is a function but not linear — IM-G8-U5-L2's squaring table —
 * is refused by name rather than fitted approximately, and the refusal names
 * the row where the line broke.
 *
 * READY FOR THE VISION LANE. The input contract takes a table of pairs. Where
 * the tables come from is not this module's business: these receipts read them
 * out of `document.json`, and a table the widened vision campaign recovers
 * from a figure arrives in the same shape and runs the same way.
 *
 * NO DEFORMATION PARTNER. The research corpus's function rows are about graph
 * reading and about rate confusions, each already carrying its partner in
 * another g8 pilot; nothing in it attests an input-output table error at this
 * locus. Shipping without one is the honest choice.
 *
 * QUARANTINE. Nothing imports this module; it renames nothing; its rows are
 * authored and vetoable one by one. Check: `check_g8_function_table/0`.
 */

:- module(g8_function_table,
          [ run_g8_function_table/4,
            g8_function_table_from_json/2,
            g8_function_table_states/1,
            g8_function_table_state_label/4,
            g8_function_table_summary/1,
            g8_function_table_receipt/6,
            check_g8_function_table/0
          ]).

:- use_module(strategies('abstraction/g8_quantity_input'),
              [ g8_quantity/2, g8_rational_text/2 ]).

% ==========================================================================
% 1. INPUT CONTRACT
%
%   {"kind":"input_output_table",
%    "input_name":"input","output_name":"output",
%    "rows":[[0,1],[2,2],[-8,-3],[100,51]]}
%   {"kind":"input_output_table", ..., "query": 6}
% ==========================================================================

g8_function_table_input_contract(
    '{\"kind\":\"input_output_table\",\"input_name\":\"string\",\"output_name\":\"string\",\"rows\":[[\"number\"]],\"query\":\"number\"}',
    '{\"kind\":\"input_output_table\",\"rows\":[[0,1],[2,2],[-8,-3],[100,51]]}').

g8_function_table_from_json(Dict, table(Pairs, Query, names(In, Out))) :-
    is_dict(Dict),
    get_dict(kind, Dict, "input_output_table"),
    get_dict(rows, Dict, Raw),
    length(Raw, N), N >= 2,
    table_pairs(Raw, Pairs),
    ( get_dict(query, Dict, Q0) -> g8_quantity(Q0, Query) ; Query = none ),
    ( get_dict(input_name, Dict, A), string(A) -> In = A ; In = "input" ),
    ( get_dict(output_name, Dict, B), string(B) -> Out = B ; Out = "output" ).

table_pairs([], []).
table_pairs([[X0, Y0]|T], [X-Y|R]) :-
    g8_quantity(X0, X), g8_quantity(Y0, Y),
    table_pairs(T, R).

% ==========================================================================
% 2. STATES
% ==========================================================================

g8_function_table_states(
    [ q_read_the_table,
      q_group_the_rows_by_input,
      q_look_for_an_input_with_two_outputs,
      q_accept_function,
      q_reject_function,
      q_take_two_rows_for_the_rule,
      q_substitute_every_row,
      q_accept_linear_rule,
      q_refuse_nonlinear_table,
      q_evaluate_the_rule_at_the_query ]).

% g8_function_table_state_label(State, Tradition, Label, Citation).
g8_function_table_state_label(q_read_the_table, illustrative_mathematics,
    "a table of input-output pairs",
    "IM Grade 8 Unit 5 Lesson 1, Inputs and Outputs").
g8_function_table_state_label(q_look_for_an_input_with_two_outputs,
    illustrative_mathematics,
    "an input with more than one output",
    "IM Grade 8 Unit 5 Lesson 2, Introduction to Functions").
g8_function_table_state_label(q_accept_function, ccss,
    "a rule that assigns exactly one output to each input",
    "CCSS 8.F.A.1, via IM Grade 8 Unit 5 Lesson 2").
g8_function_table_state_label(q_accept_function, van_de_walle,
    "a function assigns one output to each input",
    "Van de Walle, ch. 14, Functions").
g8_function_table_state_label(q_take_two_rows_for_the_rule,
    illustrative_mathematics,
    "writing an algebraic expression for the rule",
    "IM Grade 8 Unit 5 Lesson 3, Equations for Functions").
g8_function_table_state_label(q_substitute_every_row, provisional,
    "check the rule against every row",
    "provisional; no community label sourced for this checking step").
g8_function_table_state_label(q_refuse_nonlinear_table, provisional,
    "the rows do not sit on one line",
    "provisional; no community label sourced for this refusal").

% ==========================================================================
% 3. TRANSITIONS
% ==========================================================================

g8_function_table_transition(decide_whether_the_table_is_a_function,
    q_read_the_table, group_the_rows_by_input, q_group_the_rows_by_input).
g8_function_table_transition(decide_whether_the_table_is_a_function,
    q_group_the_rows_by_input, look_for_an_input_with_two_outputs,
    q_look_for_an_input_with_two_outputs).
g8_function_table_transition(decide_whether_the_table_is_a_function,
    q_look_for_an_input_with_two_outputs, accept_function, q_accept_function).
g8_function_table_transition(decide_whether_the_table_is_a_function,
    q_look_for_an_input_with_two_outputs, reject_function, q_reject_function).
g8_function_table_transition(fit_linear_rule_to_table,
    q_accept_function, take_two_rows_for_the_rule,
    q_take_two_rows_for_the_rule).
g8_function_table_transition(fit_linear_rule_to_table,
    q_take_two_rows_for_the_rule, substitute_every_row,
    q_substitute_every_row).
g8_function_table_transition(fit_linear_rule_to_table,
    q_substitute_every_row, accept_linear_rule, q_accept_linear_rule).
g8_function_table_transition(fit_linear_rule_to_table,
    q_substitute_every_row, refuse_nonlinear_table, q_refuse_nonlinear_table).
g8_function_table_transition(evaluate_rule_at_input,
    q_accept_linear_rule, evaluate_the_rule_at_the_query,
    q_evaluate_the_rule_at_the_query).

% ==========================================================================
% 4. THE RUN
% ==========================================================================

run_g8_function_table(decide_whether_the_table_is_a_function,
                      table(Pairs, Query, names(In, Out)), Outcome, Trace) :-
    (   clashing_input(Pairs, X, Y1, Y2)
    ->  g8_rational_text(X, XT), g8_rational_text(Y1, Y1T),
        g8_rational_text(Y2, Y2T),
        State = q_reject_function,
        Answer = not_a_function(input(XT), outputs(Y1T, Y2T)),
        Step = reject_function(XT, Y1T, Y2T)
    ;   State = q_accept_function, Answer = a_function,
        Step = accept_function
    ),
    length(Pairs, N),
    Outcome = action_outcome(
        decide_whether_the_table_is_a_function,
        [ classification(productive),
          cluster(g8_function_tables),
          automaton_state(State),
          vocabulary([function, input, output, table, rule,
                      exactly_one_output]),
          input(table(Pairs, Query, names(In, Out))),
          result(Answer),
          expected(Answer),
          row_count(N),
          invariant(each_input_carries_exactly_one_output),
          validity(correct) ]),
    Trace = [ read_the_table(In, Out, N),
              group_the_rows_by_input,
              Step ].
run_g8_function_table(fit_linear_rule_to_table,
                      table(Pairs, Query, names(In, Out)), Outcome, Trace) :-
    \+ clashing_input(Pairs, _, _, _),
    Pairs = [X1-Y1, X2-Y2|_],
    X1 =\= X2,
    Slope is (Y2 - Y1) rdiv (X2 - X1),
    Intercept is Y1 - Slope * X1,
    (   offending_row(Pairs, Slope, Intercept, BX, BY, Predicted)
    ->  g8_rational_text(BX, BXT), g8_rational_text(BY, BYT),
        g8_rational_text(Predicted, PT),
        Outcome = action_outcome(
            fit_linear_rule_to_table,
            [ classification(refusal),
              cluster(g8_function_tables),
              automaton_state(q_refuse_nonlinear_table),
              vocabulary([function, table, linear_rule, row]),
              input(table(Pairs, Query, names(In, Out))),
              result(refused(rows_do_not_sit_on_one_line)),
              refusal(refusal{kind: "table_not_linear", input: BXT,
                              tabled_output: BYT, line_would_give: PT}),
              validity(refused) ]),
        Trace = [ take_two_rows_for_the_rule(Slope, Intercept),
                  refuse_nonlinear_table(BXT, BYT, PT) ]
    ;   g8_rational_text(Slope, ST), g8_rational_text(Intercept, IT),
        Outcome = action_outcome(
            fit_linear_rule_to_table,
            [ classification(productive),
              cluster(g8_function_tables),
              automaton_state(q_accept_linear_rule),
              vocabulary([function, table, linear_rule, slope,
                          vertical_intercept, algebraic_expression]),
              input(table(Pairs, Query, names(In, Out))),
              result(linear_rule(ST, IT)),
              expected(linear_rule(ST, IT)),
              rule(Slope, Intercept),
              rows_checked(Pairs),
              invariant(every_row_satisfies_the_rule),
              validity(correct) ]),
        Trace = [ take_two_rows_for_the_rule(ST, IT),
                  substitute_every_row(Pairs),
                  accept_linear_rule(ST, IT) ]
    ).
run_g8_function_table(evaluate_rule_at_input,
                      table(Pairs, Query, Names), Outcome, Trace) :-
    Query \== none,
    run_g8_function_table(fit_linear_rule_to_table, table(Pairs, Query, Names),
                          action_outcome(_, Properties), _),
    memberchk(rule(Slope, Intercept), Properties),
    Value is Slope * Query + Intercept,
    Rebuilt is Slope * Query + Intercept,
    ( Rebuilt =:= Value -> Validity = correct ; Validity = unvindicated ),
    g8_rational_text(Query, QT), g8_rational_text(Value, VT),
    Outcome = action_outcome(
        evaluate_rule_at_input,
        [ classification(productive),
          cluster(g8_function_tables),
          automaton_state(q_evaluate_the_rule_at_the_query),
          vocabulary([function, rule, input, output, evaluate]),
          input(table(Pairs, Query, Names)),
          result(output_at(QT, VT)),
          expected(output_at(QT, VT)),
          rule(Slope, Intercept),
          invariant(every_row_satisfies_the_rule),
          validity(Validity) ]),
    Trace = [ evaluate_the_rule_at_the_query(QT, VT) ].

%!  clashing_input(+Pairs, -X, -Y1, -Y2) is semidet.
%
%   The first input carrying two different outputs, with both named. This is
%   the witness the function verdict rests on.
clashing_input(Pairs, X, Y1, Y2) :-
    append(_, [X-Y1|Rest], Pairs),
    % member/2, not memberchk/2: memberchk commits to the first pair in the
    % tail and never reaches a later row carrying the same input.
    member(X2-Y2, Rest),
    X2 =:= X,
    Y2 =\= Y1,
    !.

%!  offending_row(+Pairs, +Slope, +Intercept, -X, -Y, -Predicted) is semidet.
offending_row(Pairs, Slope, Intercept, X, Y, Predicted) :-
    member(X-Y, Pairs),
    Predicted is Slope * X + Intercept,
    Predicted =\= Y,
    !.

% ==========================================================================
% 5. SELF-SUMMARY
% ==========================================================================

g8_function_table_summary(
    summary{ module: g8_function_table,
             status: authored_pilot,
             generated: false,
             grade: 8,
             cluster: g8_function_tables,
             doings: [ decide_whether_the_table_is_a_function,
                       fit_linear_rule_to_table,
                       evaluate_rule_at_input ],
             verification: [the_clash_is_exhibited,
                            every_row_substituted_into_the_rule],
             arithmetic: exact_rational,
             table_source: 'docling document.json structured table items',
             ready_for: 'vision-recovered tables in the same shape',
             deformation_partners: none_attested_at_this_locus,
             imported_by: none,
             corrects: 'the round-two honest zero, which was a claim about the source' }).

% ==========================================================================
% 6. RECEIPTS
%
% Provenance `recovered_table` means the pairs were read from the guide's own
% docling document.json table item, named in the comment.
% ==========================================================================

g8_function_table_receipt(
    'im_defrag_f3dbe30947911491181fa33d_1', 'IM-G8-U5-L2',
    decide_whether_the_table_is_a_function,
    % document.json tables[0]: squaring.
    _{kind: "input_output_table",
      rows: [[-2, 4], [-1, 1], [0, 0], [1, 1], [2, 4]]},
    a_function, recovered_table).
g8_function_table_receipt(
    'im_defrag_f3dbe30947911491181fa33d_1', 'IM-G8-U5-L2',
    decide_whether_the_table_is_a_function,
    % document.json tables[1]: the same pairs reversed.
    _{kind: "input_output_table",
      rows: [[4, -2], [1, -1], [0, 0], [1, 1], [4, 2]]},
    not_a_function(input("4"), outputs("-2", "2")), recovered_table).
g8_function_table_receipt(
    'im_defrag_f3dbe30947911491181fa33d_1', 'IM-G8-U5-L2',
    decide_whether_the_table_is_a_function,
    % document.json tables[2]: one output for three inputs.
    _{kind: "input_output_table", rows: [[1, 0], [2, 0], [3, 0]]},
    a_function, recovered_table).
g8_function_table_receipt(
    'im_defrag_f3dbe30947911491181fa33d_1', 'IM-G8-U5-L2',
    decide_whether_the_table_is_a_function,
    % document.json tables[3]: one input for three outputs.
    _{kind: "input_output_table", rows: [[0, 1], [0, 2], [0, 3]]},
    not_a_function(input("0"), outputs("1", "2")), recovered_table).
g8_function_table_receipt(
    'im_defrag_9212e8d1736f66695490f7e8_1', 'IM-G8-U5-L1',
    fit_linear_rule_to_table,
    % document.json tables[9].
    _{kind: "input_output_table",
      rows: [[0, 1], [2, 2], [-8, -3], [100, 51]]},
    linear_rule("1/2", "1"), recovered_table).
g8_function_table_receipt(
    'im_defrag_f0faf5ac298c39d670f114d3_1', 'IM-G8-U5-L3',
    fit_linear_rule_to_table,
    % document.json tables[5].
    _{kind: "input_output_table", rows: [[0, 2], [-3, -10], [4, 18]]},
    linear_rule("4", "2"), recovered_table).
g8_function_table_receipt(
    'im_defrag_f3dbe30947911491181fa33d_1', 'IM-G8-U5-L2',
    fit_linear_rule_to_table,
    % The squaring table is a function and is not linear; the refusal names
    % the row where the line breaks.
    _{kind: "input_output_table",
      rows: [[-2, 4], [-1, 1], [0, 0], [1, 1], [2, 4]]},
    refused(rows_do_not_sit_on_one_line), recovered_table).
g8_function_table_receipt(
    'im_defrag_f0faf5ac298c39d670f114d3_1', 'IM-G8-U5-L3',
    evaluate_rule_at_input,
    % The same table, evaluated at the row's own further input 3.6.
    _{kind: "input_output_table", rows: [[0, 2], [-3, -10], [4, 18]],
      query: 3.6},
    output_at("18/5", "82/5"), recovered_table).

% ==========================================================================
% 7. CHECK
% ==========================================================================

check_g8_function_table :-
    check_receipts,
    check_the_four_discriminating_tables,
    check_negative,
    format('g8_function_table: all checks ok~n').

check_receipts :-
    findall(Lesson-Row-Doing-Result,
            ( g8_function_table_receipt(Row, Lesson, Doing, Json, Expected, _),
              g8_function_table_from_json(Json, Figure),
              run_g8_function_table(Doing, Figure, Outcome, _),
              outcome_property(Outcome, result(Result)),
              Result = Expected,
              outcome_property(Outcome, validity(V)),
              memberchk(V, [correct, refused])
            ), Rows),
    findall(R-L, g8_function_table_receipt(R, L, _, _, _, _), All),
    length(All, Total), length(Rows, Passed),
    Total =:= Passed,
    format('  receipts: ~w/~w tables run, every one read from a docling document.json table item~n',
           [Passed, Total]),
    forall(member(Lesson-Row-Doing-Result, Rows),
           format('    ~w  ~w  ~w -> ~q~n', [Lesson, Row, Doing, Result])).

check_the_four_discriminating_tables :-
    % IM-G8-U5-L2 sets four tables side by side, and the pilot separates them
    % the way the lesson intends: two functions, two not.
    findall(V,
            ( member(Rows, [[[-2, 4], [-1, 1], [0, 0], [1, 1], [2, 4]],
                            [[4, -2], [1, -1], [0, 0], [1, 1], [4, 2]],
                            [[1, 0], [2, 0], [3, 0]],
                            [[0, 1], [0, 2], [0, 3]]]),
              g8_function_table_from_json(
                  _{kind: "input_output_table", rows: Rows}, T),
              run_g8_function_table(decide_whether_the_table_is_a_function,
                                    T, O, _),
              outcome_property(O, result(R)),
              ( R == a_function -> V = yes ; V = no )
            ), Verdicts),
    Verdicts == [yes, no, yes, no],
    format('  the four tables separate: squaring yes, its reverse no, one output for many inputs yes, one input for many outputs no~n').

check_negative :-
    % A single row determines no rule and refuses at decode.
    \+ g8_function_table_from_json(
           _{kind: "input_output_table", rows: [[1, 2]]}, _),
    % The non-linear refusal names the row where the line broke rather than
    % fitting the first two points and moving on.
    g8_function_table_from_json(
        _{kind: "input_output_table",
          rows: [[-2, 4], [-1, 1], [0, 0], [1, 1], [2, 4]]}, T),
    run_g8_function_table(fit_linear_rule_to_table, T, O, _),
    outcome_property(O, refusal(Refusal)),
    get_dict(input, Refusal, "0"),
    get_dict(tabled_output, Refusal, "0"),
    get_dict(line_would_give, Refusal, "-2"),
    format('  negative tests: one row refuses; the non-linear refusal names input 0, whose tabled output is 0 where the line would give -2~n').

outcome_property(action_outcome(_, Props), Property) :-
    memberchk(Property, Props).
