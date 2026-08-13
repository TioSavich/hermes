:- encoding(utf8).
/** <module> Grade 8 pilot: a linear model from two observations or from a rate
 *
 * WHAT THIS IS. A quarantined pilot automaton for the doing IM grade 8 unit 3
 * asks for and unit 5 returns to: given two observed (input, output) pairs, or
 * given a starting amount and a constant rate, produce the rate of change and
 * the vertical intercept, then use the model — evaluate it at a queried input,
 * solve it for the input that reaches a queried output, and test whether a
 * further observation sits on it.
 *
 * WHY IT IS NEW. Two extant machines touch the neighbourhood and neither does
 * this. `ratio/compute_unit_rate_from_ratio_pair` takes one pair through the
 * origin, which is the proportional case; grade 8's stacked cups, fare cards,
 * and reading plans have a non-zero vertical intercept, and the whole point of
 * unit 3 lesson 5 is that the cups are NOT proportional to the stack height.
 * `algebraic/linear_pattern_contextual_rule` takes a first term and a constant
 * change indexed by row number, which is a sequence, not a covariation of two
 * measured quantities. This pilot takes two observations at arbitrary inputs.
 * It leaves both extant machines untouched.
 *
 * VERIFICATION IS SUBSTITUTION, TWICE. A fitted model is reported correct only
 * when BOTH observations satisfy it in exact rational arithmetic. That is what
 * makes the third-observation test meaningful: when unit 5 lesson 9's board
 * game sales are fitted on the first two months and the third month misses the
 * line, the pilot reports the miss with its exact residual instead of quietly
 * absorbing it.
 *
 * DEFORMATION PARTNERS. Two, each attested in this repository's own research
 * corpus and licensed only at its attested locus:
 *   - `successive_output_difference_as_slope` reproduces db_row 37775
 *     (McCrory, Floden, Ferrini-Mundy, Reckase & Senk 2012, JRME, p. 606):
 *     the rate of change taken as the difference of successive outputs, with
 *     no division by the change in input. Licensed only where the inputs
 *     differ by something other than one, which is where it separates.
 *   - `drop_the_vertical_intercept` reproduces db_row 38094 (Galbraith &
 *     Stillman 2006, ZDM, pp. 153-154): a prediction made by dividing through
 *     by the rate alone, with the intercept ignored. Licensed only where the
 *     intercept is non-zero.
 *
 * QUARANTINE. Nothing imports this module; it renames nothing; its rows are
 * authored and vetoable one by one.
 * Check: `check_g8_linear_model_from_observations/0`.
 */

:- module(g8_linear_model_from_observations,
          [ run_g8_linear_model/4,
            g8_linear_model_from_json/2,
            g8_linear_model_states/1,
            g8_linear_model_state_label/4,
            g8_linear_model_summary/1,
            g8_linear_model_receipt/5,
            check_g8_linear_model_from_observations/0
          ]).

:- use_module(strategies('abstraction/g8_quantity_input'),
              [ g8_quantity/2, g8_rational_text/2 ]).

% ==========================================================================
% 1. INPUT CONTRACT
%
%   {"kind":"linear_model","given":"two_observations",
%    "first":{"input":6,"output":15},"second":{"input":12,"output":23},
%    "input_name":"cups","output_name":"stack height in cm"}
%   {"kind":"linear_model","given":"rate_and_initial",
%    "initial":40,"rate":-2.5,
%    "input_name":"rides","output_name":"dollars on the card"}
%
%   Query fields, any one of which wraps the model in its query term so
%   the JSON genre reaches every doing; each value passes through
%   g8_quantity/2, so printed decimals decode instead of raising:
%   "at_input":11.25            -> query(Model, at_input(45/4))
%   "for_output":"7.4"          -> query(Model, for_output(37/5))
%   "observation_input":3, "observation_output":21
%                               -> query(Model, observation(3, 21))
% ==========================================================================

g8_linear_model_input_contract(
    '{\"kind\":\"linear_model\",\"given\":\"string\",\"first\":{\"input\":\"number\",\"output\":\"number\"},\"second\":{\"input\":\"number\",\"output\":\"number\"},\"initial\":\"number\",\"rate\":\"number\",\"input_name\":\"string\",\"output_name\":\"string\"}',
    '{\"kind\":\"linear_model\",\"given\":\"two_observations\",\"first\":{\"input\":6,\"output\":15},\"second\":{\"input\":12,\"output\":23},\"input_name\":\"cups\",\"output_name\":\"stack height in cm\"}').

% The query-bearing clauses come first: a dict carrying a query field
% wraps the base model in its query term, with every query value routed
% through g8_quantity/2 (the probe file's decode/3 demonstrated this
% repair; printed decimals like 11.25 previously raised type errors
% inside rational arithmetic instead of decoding).
g8_linear_model_from_json(Dict, query(Model, at_input(Q))) :-
    is_dict(Dict), get_dict(at_input, Dict, Q0), !,
    g8_linear_model_base_from_json(Dict, Model),
    g8_quantity(Q0, Q).
g8_linear_model_from_json(Dict, query(Model, for_output(T))) :-
    is_dict(Dict), get_dict(for_output, Dict, T0), !,
    g8_linear_model_base_from_json(Dict, Model),
    g8_quantity(T0, T).
g8_linear_model_from_json(Dict, query(Model, observation(X, Y))) :-
    is_dict(Dict), get_dict(observation_input, Dict, X0), !,
    get_dict(observation_output, Dict, Y0),
    g8_linear_model_base_from_json(Dict, Model),
    g8_quantity(X0, X), g8_quantity(Y0, Y).
g8_linear_model_from_json(Dict, Model) :-
    g8_linear_model_base_from_json(Dict, Model).

g8_linear_model_base_from_json(Dict, two_observations(X1, Y1, X2, Y2, Names)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "linear_model"),
    get_dict(given, Dict, "two_observations"), !,
    get_dict(first, Dict, First), get_dict(second, Dict, Second),
    get_dict(input, First, X10), get_dict(output, First, Y10),
    get_dict(input, Second, X20), get_dict(output, Second, Y20),
    g8_quantity(X10, X1), g8_quantity(Y10, Y1),
    g8_quantity(X20, X2), g8_quantity(Y20, Y2),
    X1 =\= X2,
    quantity_names(Dict, Names).
g8_linear_model_base_from_json(Dict, rate_and_initial(Rate, Initial, Names)) :-
    is_dict(Dict),
    get_dict(kind, Dict, "linear_model"),
    get_dict(given, Dict, "rate_and_initial"),
    get_dict(rate, Dict, R0), get_dict(initial, Dict, I0),
    g8_quantity(R0, Rate), g8_quantity(I0, Initial),
    quantity_names(Dict, Names).

quantity_names(Dict, names(In, Out)) :-
    ( get_dict(input_name, Dict, A), string(A) -> In = A ; In = "input" ),
    ( get_dict(output_name, Dict, B), string(B) -> Out = B ; Out = "output" ).

% ==========================================================================
% 2. STATES
% ==========================================================================

g8_linear_model_states(
    [ q_name_input_and_output,
      q_read_two_observations,
      q_measure_vertical_change,
      q_measure_horizontal_change,
      q_form_rate_of_change,
      q_locate_vertical_intercept,
      q_verify_both_observations,
      q_accept_linear_model,
      q_evaluate_at_queried_input,
      q_solve_for_queried_output,
      q_test_further_observation,
      q_take_output_difference_as_rate,
      q_predict_without_the_intercept ]).

% g8_linear_model_state_label(State, Tradition, Label, Citation).
g8_linear_model_state_label(q_name_input_and_output, illustrative_mathematics,
    "the independent and dependent variables",
    "IM Grade 8 Unit 5 Lesson 6, Even More Graphs of Functions").
g8_linear_model_state_label(q_measure_vertical_change, illustrative_mathematics,
    "the vertical change",
    "IM Grade 8 Unit 3 Lesson 10, Calculating Slope").
g8_linear_model_state_label(q_measure_horizontal_change, illustrative_mathematics,
    "the horizontal change",
    "IM Grade 8 Unit 3 Lesson 10, Calculating Slope").
g8_linear_model_state_label(q_form_rate_of_change, van_de_walle,
    "rate of change",
    "Van de Walle, ch. 14, Proportional and Linear Relationships").
g8_linear_model_state_label(q_form_rate_of_change, lobato_siebert,
    "slope as a measure of a physical attribute, not a recipe",
    "db_rows 38341-38343; Lobato & Siebert 2002, Journal of Mathematical Behavior").
g8_linear_model_state_label(q_locate_vertical_intercept, illustrative_mathematics,
    "the vertical intercept",
    "IM Grade 8 Unit 3 Lesson 6, More Linear Relationships").
g8_linear_model_state_label(q_verify_both_observations, provisional,
    "check that both observations sit on the line",
    "provisional; no community label sourced for this checking step").
g8_linear_model_state_label(q_test_further_observation, illustrative_mathematics,
    "decide whether a single linear model is reasonable",
    "IM Grade 8 Unit 5 Lesson 9, Linear Models").
g8_linear_model_state_label(q_take_output_difference_as_rate, mccrory,
    "the difference of successive outputs taken as the slope",
    "db_row 37775; McCrory et al. 2012, JRME, p. 606").
g8_linear_model_state_label(q_predict_without_the_intercept, galbraith_stillman,
    "predicting from the rate alone",
    "db_row 38094; Galbraith & Stillman 2006, ZDM, pp. 153-154").

% ==========================================================================
% 3. TRANSITIONS
% ==========================================================================

g8_linear_model_transition(rate_of_change_from_two_observations,
    q_name_input_and_output, read_the_two_observations, q_read_two_observations).
g8_linear_model_transition(rate_of_change_from_two_observations,
    q_read_two_observations, subtract_the_outputs, q_measure_vertical_change).
g8_linear_model_transition(rate_of_change_from_two_observations,
    q_measure_vertical_change, subtract_the_inputs, q_measure_horizontal_change).
g8_linear_model_transition(rate_of_change_from_two_observations,
    q_measure_horizontal_change, divide_vertical_by_horizontal,
    q_form_rate_of_change).
g8_linear_model_transition(rate_of_change_from_two_observations,
    q_form_rate_of_change, back_up_to_input_zero, q_locate_vertical_intercept).
g8_linear_model_transition(rate_of_change_from_two_observations,
    q_locate_vertical_intercept, substitute_both_observations,
    q_verify_both_observations).
g8_linear_model_transition(rate_of_change_from_two_observations,
    q_verify_both_observations, report_the_model, q_accept_linear_model).
g8_linear_model_transition(linear_model_from_rate_and_initial,
    q_name_input_and_output, read_the_rate_and_the_starting_amount,
    q_form_rate_of_change).
g8_linear_model_transition(linear_model_from_rate_and_initial,
    q_form_rate_of_change, name_the_starting_amount_as_the_intercept,
    q_locate_vertical_intercept).
g8_linear_model_transition(evaluate_linear_model_at_input,
    q_accept_linear_model, substitute_the_queried_input,
    q_evaluate_at_queried_input).
g8_linear_model_transition(solve_linear_model_for_input,
    q_accept_linear_model, solve_for_the_input_reaching_the_output,
    q_solve_for_queried_output).
g8_linear_model_transition(test_third_observation_on_the_model,
    q_accept_linear_model, compare_the_further_observation_with_the_model,
    q_test_further_observation).
g8_linear_model_transition(successive_output_difference_as_slope,
    q_read_two_observations, take_the_output_difference_as_the_rate,
    q_take_output_difference_as_rate).
g8_linear_model_transition(drop_the_vertical_intercept,
    q_accept_linear_model, divide_the_target_by_the_rate_alone,
    q_predict_without_the_intercept).

% ==========================================================================
% 4. THE RUN
%
% A model is model(Rate, Intercept): Output = Rate * Input + Intercept.
% ==========================================================================

run_g8_linear_model(rate_of_change_from_two_observations,
                    two_observations(X1, Y1, X2, Y2, names(In, Out)),
                    Outcome, Trace) :-
    VerticalChange is Y2 - Y1,
    HorizontalChange is X2 - X1,
    Rate is VerticalChange rdiv HorizontalChange,
    Intercept is Y1 - Rate * X1,
    on_model(Rate, Intercept, X1, Y1, First),
    on_model(Rate, Intercept, X2, Y2, Second),
    ( First == closes, Second == closes -> Validity = correct
    ; Validity = unvindicated ),
    g8_rational_text(Rate, RateText),
    g8_rational_text(Intercept, InterceptText),
    Outcome = action_outcome(
        rate_of_change_from_two_observations,
        [ classification(productive),
          cluster(g8_linear_relationships_and_slope),
          automaton_state(q_accept_linear_model),
          vocabulary([independent_variable, dependent_variable,
                      vertical_change, horizontal_change, rate_of_change,
                      slope, vertical_intercept, linear_relationship]),
          input(two_observations(X1, Y1, X2, Y2, names(In, Out))),
          result(model(RateText, InterceptText)),
          expected(model(RateText, InterceptText)),
          model(Rate, Intercept),
          substitution([observation(X1, Y1)-First, observation(X2, Y2)-Second]),
          proportional(Intercept =:= 0),
          invariant(both_observations_sit_on_the_line),
          validity(Validity) ]),
    Trace = [ name_input_and_output(In, Out),
              read_the_two_observations(X1-Y1, X2-Y2),
              subtract_the_outputs(VerticalChange),
              subtract_the_inputs(HorizontalChange),
              divide_vertical_by_horizontal(RateText),
              back_up_to_input_zero(InterceptText),
              substitute_both_observations(First, Second),
              report_the_model(RateText, InterceptText) ].
run_g8_linear_model(linear_model_from_rate_and_initial,
                    rate_and_initial(Rate, Initial, names(In, Out)),
                    Outcome, Trace) :-
    on_model(Rate, Initial, 0, Initial, AtZero),
    OneStep is Rate * 1 + Initial,
    on_model(Rate, Initial, 1, OneStep, AtOne),
    ( AtZero == closes, AtOne == closes -> Validity = correct
    ; Validity = unvindicated ),
    g8_rational_text(Rate, RateText),
    g8_rational_text(Initial, InterceptText),
    Outcome = action_outcome(
        linear_model_from_rate_and_initial,
        [ classification(productive),
          cluster(g8_linear_relationships_and_slope),
          automaton_state(q_accept_linear_model),
          vocabulary([starting_amount, constant_rate, rate_of_change,
                      vertical_intercept, linear_relationship]),
          input(rate_and_initial(Rate, Initial, names(In, Out))),
          result(model(RateText, InterceptText)),
          expected(model(RateText, InterceptText)),
          model(Rate, Initial),
          substitution([observation(0, Initial)-AtZero,
                        observation(1, OneStep)-AtOne]),
          proportional(Initial =:= 0),
          invariant(both_observations_sit_on_the_line),
          validity(Validity) ]),
    Trace = [ name_input_and_output(In, Out),
              read_the_rate_and_the_starting_amount(RateText, InterceptText),
              name_the_starting_amount_as_the_intercept(InterceptText) ].
run_g8_linear_model(evaluate_linear_model_at_input,
                    query(Model, at_input(Query)), Outcome, Trace) :-
    model_of(Model, Rate, Intercept),
    Value is Rate * Query + Intercept,
    on_model(Rate, Intercept, Query, Value, Check),
    ( Check == closes -> Validity = correct ; Validity = unvindicated ),
    g8_rational_text(Value, ValueText),
    Outcome = action_outcome(
        evaluate_linear_model_at_input,
        [ classification(productive),
          cluster(g8_linear_relationships_and_slope),
          automaton_state(q_evaluate_at_queried_input),
          vocabulary([linear_relationship, input, output, evaluate]),
          input(query(Model, at_input(Query))),
          result(output(ValueText)),
          expected(output(ValueText)),
          substitution([observation(Query, Value)-Check]),
          invariant(both_observations_sit_on_the_line),
          validity(Validity) ]),
    Trace = [ substitute_the_queried_input(Query),
              report_the_output(ValueText) ].
run_g8_linear_model(solve_linear_model_for_input,
                    query(Model, for_output(Target)), Outcome, Trace) :-
    model_of(Model, Rate, Intercept),
    Rate =\= 0,
    Query is (Target - Intercept) rdiv Rate,
    on_model(Rate, Intercept, Query, Target, Check),
    ( Check == closes -> Validity = correct ; Validity = unvindicated ),
    g8_rational_text(Query, QueryText),
    Outcome = action_outcome(
        solve_linear_model_for_input,
        [ classification(productive),
          cluster(g8_linear_relationships_and_slope),
          automaton_state(q_solve_for_queried_output),
          vocabulary([linear_relationship, input, output, solve]),
          input(query(Model, for_output(Target))),
          result(input(QueryText)),
          expected(input(QueryText)),
          substitution([observation(Query, Target)-Check]),
          invariant(both_observations_sit_on_the_line),
          validity(Validity) ]),
    Trace = [ solve_for_the_input_reaching_the_output(Target),
              report_the_input(QueryText) ].
run_g8_linear_model(test_third_observation_on_the_model,
                    query(Model, observation(X, Y)), Outcome, Trace) :-
    model_of(Model, Rate, Intercept),
    Predicted is Rate * X + Intercept,
    Residual is Y - Predicted,
    on_model(Rate, Intercept, X, Y, Check),
    ( Check == closes -> Verdict = sits_on_the_model
    ; Verdict = misses_the_model ),
    g8_rational_text(Predicted, PredictedText),
    g8_rational_text(Residual, ResidualText),
    Outcome = action_outcome(
        test_third_observation_on_the_model,
        [ classification(productive),
          cluster(g8_linear_relationships_and_slope),
          automaton_state(q_test_further_observation),
          vocabulary([linear_model, observation, prediction, residual,
                      reasonable_model]),
          input(query(Model, observation(X, Y))),
          result(Verdict),
          expected(Verdict),
          predicted(PredictedText),
          residual(ResidualText),
          invariant(both_observations_sit_on_the_line),
          validity(correct) ]),
    Trace = [ compare_the_further_observation_with_the_model(X-Y),
              report_prediction_and_residual(PredictedText, ResidualText) ].
run_g8_linear_model(successive_output_difference_as_slope,
                    two_observations(X1, Y1, X2, Y2, Names), Outcome, Trace) :-
    % Attested locus: inputs a step other than one apart, where the missing
    % division by the change in input actually separates.
    HorizontalChange is X2 - X1,
    HorizontalChange =\= 1,
    VerticalChange is Y2 - Y1,
    ProductiveRate is VerticalChange rdiv HorizontalChange,
    g8_rational_text(VerticalChange, DeformedText),
    g8_rational_text(ProductiveRate, ProductiveText),
    ( VerticalChange =\= ProductiveRate -> Validity = incorrect
    ; Validity = unvindicated ),
    Outcome = action_outcome(
        successive_output_difference_as_slope,
        [ classification(deformation),
          cluster(g8_linear_relationships_and_slope),
          automaton_state(q_take_output_difference_as_rate),
          vocabulary([table, successive_outputs, difference, slope]),
          input(two_observations(X1, Y1, X2, Y2, Names)),
          expected(rate_of_change(ProductiveText)),
          result(rate_of_change(DeformedText)),
          deformation_of(rate_of_change_from_two_observations),
          violated_invariant(rate_divides_by_the_change_in_input),
          attested_as(db_row(37775),
                      "McCrory et al. 2012, JRME, p. 606"),
          validity(Validity) ]),
    Trace = [ read_the_two_observations(X1-Y1, X2-Y2),
              subtract_the_outputs(VerticalChange),
              take_the_output_difference_as_the_rate(DeformedText) ].
run_g8_linear_model(drop_the_vertical_intercept,
                    query(Model, for_output(Target)), Outcome, Trace) :-
    % Attested locus: a non-zero intercept, which is what gets dropped.
    model_of(Model, Rate, Intercept),
    Rate =\= 0, Intercept =\= 0,
    Deformed is Target rdiv Rate,
    Productive is (Target - Intercept) rdiv Rate,
    on_model(Rate, Intercept, Deformed, Target, Check),
    g8_rational_text(Deformed, DeformedText),
    g8_rational_text(Productive, ProductiveText),
    ( Check == fails -> Validity = incorrect ; Validity = unvindicated ),
    Outcome = action_outcome(
        drop_the_vertical_intercept,
        [ classification(deformation),
          cluster(g8_linear_relationships_and_slope),
          automaton_state(q_predict_without_the_intercept),
          vocabulary([linear_model, rate_of_change, vertical_intercept,
                      prediction]),
          input(query(Model, for_output(Target))),
          expected(input(ProductiveText)),
          result(input(DeformedText)),
          substitution([observation(Deformed, Target)-Check]),
          deformation_of(solve_linear_model_for_input),
          violated_invariant(the_model_carries_its_intercept),
          attested_as(db_row(38094),
                      "Galbraith & Stillman 2006, ZDM, pp. 153-154"),
          validity(Validity) ]),
    Trace = [ divide_the_target_by_the_rate_alone(DeformedText) ].

model_of(model(Rate, Intercept), Rate, Intercept).
model_of(Json, Rate, Intercept) :-
    is_dict(Json),
    g8_linear_model_from_json(Json, Figure),
    ( Figure = two_observations(_, _, _, _, _)
    ->  run_g8_linear_model(rate_of_change_from_two_observations, Figure,
                            action_outcome(_, Properties), _),
        memberchk(model(Rate, Intercept), Properties)
    ;   Figure = rate_and_initial(Rate, Intercept, _)
    ).

on_model(Rate, Intercept, X, Y, Verdict) :-
    Predicted is Rate * X + Intercept,
    ( Predicted =:= Y -> Verdict = closes ; Verdict = fails ).

% ==========================================================================
% 5. SELF-SUMMARY
% ==========================================================================

g8_linear_model_summary(
    summary{ module: g8_linear_model_from_observations,
             status: authored_pilot,
             generated: false,
             grade: 8,
             cluster: g8_linear_relationships_and_slope,
             doings: [ rate_of_change_from_two_observations,
                       linear_model_from_rate_and_initial,
                       evaluate_linear_model_at_input,
                       solve_linear_model_for_input,
                       test_third_observation_on_the_model,
                       successive_output_difference_as_slope,
                       drop_the_vertical_intercept ],
             verification: substitute_both_observations,
             arithmetic: exact_rational,
             imported_by: none,
             extant_machines_left_untouched:
                 [ 'ratio/compute_unit_rate_from_ratio_pair',
                   'algebraic/linear_pattern_contextual_rule' ] }).

% ==========================================================================
% 6. RECEIPTS
% ==========================================================================

g8_linear_model_receipt(
    'im_defrag_ab018b125b25d2d2892b9934_1', 'IM-G8-U3-L5',
    rate_of_change_from_two_observations,
    _{kind: "linear_model", given: "two_observations",
      first: _{input: 6, output: 15}, second: _{input: 12, output: 23},
      input_name: "cups", output_name: "stack height in cm"},
    model("4/3", "7")).
g8_linear_model_receipt(
    'im_defrag_47cc876bcdbea9f08714dcb9_1', 'IM-G8-U3-L3',
    rate_of_change_from_two_observations,
    _{kind: "linear_model", given: "two_observations",
      first: _{input: 11, output: 93.5}, second: _{input: 23, output: 195.5},
      input_name: "cars", output_name: "dollars raised"},
    model("17/2", "0")).
g8_linear_model_receipt(
    'im_defrag_b657d168951e429dd466a4d9_1', 'IM-G8-U5-L9',
    rate_of_change_from_two_observations,
    _{kind: "linear_model", given: "two_observations",
      first: _{input: 12, output: 4}, second: _{input: 18, output: 7},
      input_name: "months", output_name: "thousands of games sold"},
    model("1/2", "-2")).
g8_linear_model_receipt(
    'im_defrag_9f0b93332295308af4cfe5be_1', 'IM-G8-U4-L11',
    rate_of_change_from_two_observations,
    _{kind: "linear_model", given: "two_observations",
      first: _{input: 6, output: 36}, second: _{input: 9, output: 54},
      input_name: "seconds", output_name: "metres from the start"},
    model("6", "0")).
g8_linear_model_receipt(
    'im_defrag_0d09838d485f78f3aa07e7a2_1', 'IM-G8-U3-L9',
    linear_model_from_rate_and_initial,
    _{kind: "linear_model", given: "rate_and_initial",
      rate: -2.5, initial: 40,
      input_name: "rides", output_name: "dollars on the fare card"},
    model("-5/2", "40")).
g8_linear_model_receipt(
    'im_defrag_192321b482c543b8f27ebcf2_1', 'IM-G8-U3-L6',
    linear_model_from_rate_and_initial,
    _{kind: "linear_model", given: "rate_and_initial",
      rate: 40, initial: 30,
      input_name: "days", output_name: "pages read"},
    model("40", "30")).
g8_linear_model_receipt(
    'im_defrag_430a873ce676587a4099cd8d_1', 'IM-G8-U3-L9',
    linear_model_from_rate_and_initial,
    _{kind: "linear_model", given: "rate_and_initial",
      rate: 3, initial: 0,
      input_name: "minutes", output_name: "gallons of rainwater"},
    model("3", "0")).

% Final round: the fold-in supplied IM-G8-U2-L10's two graphed lines by
% their own named points, so the slopes the row asks about are now
% computable rather than read off a picture.
g8_linear_model_receipt(
    'im_defrag_e69842a60dbcb65880faaa8b_1', 'IM-G8-U2-L10',
    rate_of_change_from_two_observations,
    _{kind: "linear_model", given: "two_observations",
      first: _{input: 2, output: 0}, second: _{input: 7, output: 10},
      input_name: "x", output_name: "y"},
    model("2", "-4")).                        % line k, slope 2
g8_linear_model_receipt(
    'im_defrag_e69842a60dbcb65880faaa8b_1', 'IM-G8-U2-L10',
    rate_of_change_from_two_observations,
    _{kind: "linear_model", given: "two_observations",
      first: _{input: 0, output: 3}, second: _{input: 7, output: 10},
      input_name: "x", output_name: "y"},
    model("1", "3")).                         % line l, slope 1
g8_linear_model_receipt(
    'im_defrag_e7e39e7cbf9cf16aa69c026d_1', 'IM-G8-U3-L12',
    % Rectangles of perimeter 50: length plus width is 25, so the line
    % through (0, 25) and (25, 0) has slope -1.
    rate_of_change_from_two_observations,
    _{kind: "linear_model", given: "two_observations",
      first: _{input: 0, output: 25}, second: _{input: 25, output: 0},
      input_name: "length", output_name: "width"},
    model("-1", "25")).

% ==========================================================================
% 7. CHECK
% ==========================================================================

check_g8_linear_model_from_observations :-
    check_receipts,
    check_model_use,
    check_attested_deformations,
    check_negative,
    format('g8_linear_model_from_observations: all checks ok~n').

check_receipts :-
    findall(Lesson-Row-Doing-Result,
            ( g8_linear_model_receipt(Row, Lesson, Doing, Json, Expected),
              g8_linear_model_from_json(Json, Figure),
              run_g8_linear_model(Doing, Figure, Outcome, _),
              outcome_property(Outcome, result(Result)),
              Result = Expected,
              outcome_property(Outcome, validity(correct))
            ), Rows),
    findall(R-L, g8_linear_model_receipt(R, L, _, _, _), All),
    length(All, Total), length(Rows, Passed),
    Total =:= Passed,
    format('  receipts: ~w/~w real grade 8 rows fitted, both observations substituted~n',
           [Passed, Total]),
    forall(member(Lesson-Row-Doing-Result, Rows),
           format('    ~w  ~w  ~w -> ~q~n', [Lesson, Row, Doing, Result])).

check_model_use :-
    % IM-G8-U3-L5: how many cups reach a height of 50 cm?
    run_g8_linear_model(solve_linear_model_for_input,
                        query(model(4 rdiv 3, 7), for_output(50)), O1, _),
    outcome_property(O1, result(input("129/4"))),
    outcome_property(O1, validity(correct)),
    % IM-G8-U3-L9: dollars left after 1 and 2 rides.
    run_g8_linear_model(evaluate_linear_model_at_input,
                        query(model(-5 rdiv 2, 40), at_input(2)), O2, _),
    outcome_property(O2, result(output("35"))),
    % IM-G8-U5-L9: the third observation, 36 months and 15 thousand games,
    % misses the model fitted on the first two by exactly one thousand.
    run_g8_linear_model(test_third_observation_on_the_model,
                        query(model(1 rdiv 2, -2), observation(36, 15)), O3, _),
    outcome_property(O3, result(misses_the_model)),
    outcome_property(O3, predicted("16")),
    outcome_property(O3, residual("-1")),
    format('  model use: 129/4 cups reach 50 cm, $35 remains after 2 rides, and the 36-month sale misses its model by -1~n').

check_attested_deformations :-
    % db_row 37775 on the cup stacks: the rate read as 8 rather than 4/3.
    g8_linear_model_from_json(
        _{kind: "linear_model", given: "two_observations",
          first: _{input: 6, output: 15}, second: _{input: 12, output: 23},
          input_name: "cups", output_name: "stack height in cm"}, F),
    run_g8_linear_model(successive_output_difference_as_slope, F, O1, _),
    outcome_property(O1, result(rate_of_change("8"))),
    outcome_property(O1, expected(rate_of_change("4/3"))),
    outcome_property(O1, validity(incorrect)),
    % db_row 38094 on the same stacks: 50 cm read as 75/2 cups, not 129/4.
    run_g8_linear_model(drop_the_vertical_intercept,
                        query(model(4 rdiv 3, 7), for_output(50)), O2, _),
    outcome_property(O2, result(input("75/2"))),
    outcome_property(O2, expected(input("129/4"))),
    outcome_property(O2, validity(incorrect)),
    format('  attested deformations: db_row 37775 reads the rate as 8; db_row 38094 predicts 75/2 cups where the model gives 129/4~n').

check_negative :-
    % Two observations at the same input describe no function and refuse.
    \+ g8_linear_model_from_json(
           _{kind: "linear_model", given: "two_observations",
             first: _{input: 6, output: 15}, second: _{input: 6, output: 23}}, _),
    % The intercept-dropping deformation refuses on a proportional model,
    % where there is no intercept to drop.
    \+ run_g8_linear_model(drop_the_vertical_intercept,
                           query(model(6, 0), for_output(100)), _, _),
    % The successive-difference deformation refuses at unit input steps,
    % where it would coincide with the productive rate.
    g8_linear_model_from_json(
        _{kind: "linear_model", given: "two_observations",
          first: _{input: 1, output: 70}, second: _{input: 2, output: 110}}, G),
    \+ run_g8_linear_model(successive_output_difference_as_slope, G, _, _),
    format('  negative tests: a repeated input refuses; both deformations refuse where they would coincide with the productive run~n').

outcome_property(action_outcome(_, Props), Property) :-
    memberchk(Property, Props).
