/** <module> Shared decoder for role-bearing automaton inputs
 *
 * The later action-automaton wave represents operand roles in structured JSON
 * objects. This module constructs the two Prolog operands consumed by both the
 * persistent worker and the loop drivers.
 */

:- module(automaton_role_input_decoder,
          [ role_input_kind/1,
            decode_role_inputs/3
          ]).

:- use_module(library(lists), [memberchk/2]).

%!  role_input_kind(?Kind) is nondet.
%
%   Kind is one of the structured input tags decoded by decode_role_inputs/3.
role_input_kind("signed_subtraction").
role_input_kind("signed_multiplication").
role_input_kind("signed_division").
role_input_kind("ratio_pair_unit_rate").
role_input_kind("ratio_pairs_proportionality_test").
role_input_kind("ratio_pair_solve_at_x").
role_input_kind("circle_co_measurement").
role_input_kind("triangle_conditions").
role_input_kind("angle_relation").
role_input_kind("frequency_record").
role_input_kind("sample_population_distribution").
role_input_kind("diagram_relation").
role_input_kind("percent_change").
role_input_kind("signed_linear_expression").

%!  decode_role_inputs(+Input, -A, -B) is semidet.
%
%   Decode a recognized role-bearing input. A malformed recognized kind raises
%   a kind-bearing error so callers cannot confuse a decoder fault with an
%   automaton refusal. Inputs outside this decoder's kind set fail.
decode_role_inputs(Input, A, B) :-
    is_dict(Input),
    get_dict(kind, Input, Kind),
    role_input_kind(Kind),
    !,
    (   decode_role_inputs_(Kind, Input, A, B)
    ->  true
    ;   throw(error(role_input_decode_failed(Kind),
                    context(automaton_role_input_decoder:decode_role_inputs/3,
                            'recognized role-bearing input is malformed')))
    ).

decode_role_inputs_("signed_subtraction", Input, A, B) :-
    json_integer_field(Input, minuend, Minuend),
    json_integer_field(Input, subtrahend, Subtrahend),
    A = minuend(Minuend), B = subtrahend(Subtrahend).
decode_role_inputs_("signed_multiplication", Input, A, B) :-
    json_integer_field(Input, multiplier, Multiplier),
    json_integer_field(Input, multiplicand, Multiplicand),
    A = multiplier(Multiplier), B = multiplicand(Multiplicand).
decode_role_inputs_("signed_division", Input, A, B) :-
    json_integer_field(Input, dividend, Dividend),
    json_integer_field(Input, divisor, Divisor),
    Divisor =\= 0,
    A = dividend(Dividend), B = divisor(Divisor).
decode_role_inputs_("ratio_pair_unit_rate", Input, A, B) :-
    positive_number_field(Input, first, First),
    positive_number_field(Input, second, Second),
    json_atom_field(Input, referent, Referent),
    memberchk(Referent, [first_per_second, second_per_first]),
    A = ratio_pair(First, Second), B = unit_rate(Referent).
decode_role_inputs_("ratio_pairs_proportionality_test", Input, A, B) :-
    get_dict(pairs, Input, JsonPairs),
    is_list(JsonPairs),
    JsonPairs = [_, _|_],
    maplist(json_ratio_pair, JsonPairs, Pairs),
    get_dict(test, Input, "proportionality_test"),
    A = ratio_pairs(Pairs), B = proportionality_test.
decode_role_inputs_("ratio_pair_solve_at_x", Input, A, B) :-
    positive_number_field(Input, first, First),
    positive_number_field(Input, second, Second),
    nonnegative_number_field(Input, target_x, TargetX),
    A = ratio_pair(First, Second), B = solve_at_x(TargetX).
decode_role_inputs_("circle_co_measurement", Input, A, B) :-
    json_atom_field(Input, given_measure, GivenMeasure),
    positive_number_field(Input, value, Value),
    json_atom_field(Input, unit, Unit),
    json_atom_field(Input, requested_measure, RequestedMeasure),
    get_dict(pi, Input, Pi),
    positive_integer_field(Pi, n, PiNumerator),
    positive_integer_field(Pi, d, PiDenominator),
    circle_request(GivenMeasure, RequestedMeasure,
                   rational(PiNumerator, PiDenominator), B),
    A = circle_measure(GivenMeasure, Value, Unit).
decode_role_inputs_("triangle_conditions", Input, A, B) :-
    json_atom_field(Input, condition, Condition),
    memberchk(Condition, [sss, sas, asa, aas, ssa, aaa]),
    get_dict(measures, Input, Measures),
    three_positive_numbers(Measures, ThreeMeasures),
    Conditions =.. [Condition|ThreeMeasures],
    A = triangle_conditions(Conditions), B = classify.
decode_role_inputs_("angle_relation", Input, A, B) :-
    positive_number_field(Input, whole, Whole),
    get_dict(known_parts, Input, KnownParts),
    is_list(KnownParts),
    KnownParts = [_|_],
    maplist(positive_number, KnownParts),
    json_atom_field(Input, unknown, Unknown),
    A = angle_relation(whole(Whole), known_parts(KnownParts)),
    B = unknown(Unknown).
decode_role_inputs_("frequency_record", Input, A, B) :-
    json_atom_field(Input, event, Event),
    nonnegative_integer_field(Input, successes, Successes),
    positive_integer_field(Input, trials, Trials),
    Successes =< Trials,
    get_dict(context, Input, "repeated_experiment"),
    A = frequency_record(Event, Successes, Trials),
    B = estimate_context(repeated_experiment).
decode_role_inputs_("sample_population_distribution", Input, A, B) :-
    get_dict(sample, Input, Sample),
    get_dict(population, Input, Population),
    get_dict(tolerances, Input, Tolerances),
    profile(Sample, SampleData, SampleShape),
    profile(Population, PopulationData, PopulationShape),
    nonnegative_number_field(Tolerances, center, CenterTolerance),
    nonnegative_number_field(Tolerances, spread, SpreadTolerance),
    A = sample(SampleData, shape(SampleShape)),
    B = population(PopulationData, shape(PopulationShape),
                   tolerances(center(CenterTolerance),
                              spread(SpreadTolerance))).
decode_role_inputs_("diagram_relation", Input, A, B) :-
    json_atom_field(Input, representation, Representation),
    memberchk(Representation, [tape, hanger]),
    positive_integer_field(Input, groups, Groups),
    get_dict(group_expression, Input, JsonGroupExpression),
    diagram_expression(JsonGroupExpression, GroupExpression),
    json_number_field(Input, additional, Additional),
    json_number_field(Input, total, Total),
    json_atom_field(Input, equation_form, EquationForm),
    memberchk(EquationForm,
              [px_plus_q_equals_r, p_times_x_plus_q_equals_r]),
    A = diagram(Representation, equal_groups(Groups, GroupExpression),
                additional(number(Additional)), total(number(Total))),
    B = equation_form(EquationForm).
decode_role_inputs_("percent_change", Input, A, B) :-
    json_atom_field(Input, amount_role, AmountRole),
    memberchk(AmountRole, [original_amount, changed_amount]),
    nonnegative_number_field(Input, amount, Amount),
    nonnegative_number_field(Input, rate_percent, Percent),
    json_atom_field(Input, direction, Direction),
    memberchk(Direction, [increase, decrease]),
    json_atom_field(Input, target, Target),
    memberchk(Target, [new_amount, original_amount]),
    AmountTerm =.. [AmountRole, Amount],
    A = percent_change(AmountTerm, rate_percent(Percent),
                       direction(Direction)),
    B = target(Target).
decode_role_inputs_("signed_linear_expression", Input, A, B) :-
    get_dict(variable_terms, Input, JsonVariableTerms),
    get_dict(constant_terms, Input, JsonConstantTerms),
    is_list(JsonVariableTerms),
    is_list(JsonConstantTerms),
    maplist(signed_variable_item, JsonVariableTerms, VariableItems),
    maplist(signed_constant_item, JsonConstantTerms, ConstantItems),
    append(VariableItems, ConstantItems, Items),
    Items = [_|_],
    get_dict(direction, Input, "combine_like_terms"),
    A = signed_linear_expression(Items),
    B = rewrite_direction(combine_like_terms).

json_ratio_pair(Dict, ratio_pair(First, Second)) :-
    is_dict(Dict),
    positive_number_field(Dict, first, First),
    positive_number_field(Dict, second, Second).

circle_request(diameter, circumference, Pi, circumference_with_pi(Pi)).
circle_request(circumference, diameter, Pi, diameter_with_pi(Pi)).

profile(Dict, Values, Shape) :-
    is_dict(Dict),
    get_dict(values, Dict, Values),
    is_list(Values),
    Values = [_, _|_],
    maplist(nonnegative_integer, Values),
    json_atom_field(Dict, shape, Shape).

diagram_expression(Dict, var(Name)) :-
    is_dict(Dict), get_dict(node, Dict, "var"), !,
    json_atom_field(Dict, name, Name).
diagram_expression(Dict, number(Value)) :-
    is_dict(Dict), get_dict(node, Dict, "number"), !,
    json_number_field(Dict, value, Value).
diagram_expression(Dict, add(Left, Right)) :-
    is_dict(Dict), get_dict(node, Dict, "add"), !,
    get_dict(left, Dict, JsonLeft),
    get_dict(right, Dict, JsonRight),
    diagram_expression(JsonLeft, Left),
    diagram_expression(JsonRight, Right).

signed_variable_item(Dict, Item) :-
    is_dict(Dict),
    json_atom_field(Dict, operation, Operation),
    memberchk(Operation, [add, subtract]),
    json_number_field(Dict, coefficient, Coefficient),
    json_atom_field(Dict, variable, Variable),
    Item =.. [Operation, term(Coefficient, var(Variable))].

signed_constant_item(Dict, Item) :-
    is_dict(Dict),
    json_atom_field(Dict, operation, Operation),
    memberchk(Operation, [add, subtract]),
    json_number_field(Dict, value, Value),
    Item =.. [Operation, constant(Value)].

positive_number_field(Dict, Key, Value) :-
    json_number_field(Dict, Key, Value),
    Value > 0.

nonnegative_number_field(Dict, Key, Value) :-
    json_number_field(Dict, Key, Value),
    Value >= 0.

json_number_field(Dict, Key, Value) :-
    get_dict(Key, Dict, Value),
    number(Value).

json_integer_field(Dict, Key, Value) :-
    get_dict(Key, Dict, Value),
    integer(Value).

nonnegative_integer_field(Dict, Key, Value) :-
    json_integer_field(Dict, Key, Value),
    Value >= 0.

positive_integer_field(Dict, Key, Value) :-
    json_integer_field(Dict, Key, Value),
    Value > 0.

json_atom_field(Dict, Key, Value) :-
    get_dict(Key, Dict, Raw),
    json_atom(Raw, Value).

json_atom(Raw, Atom) :-
    (   atom(Raw)
    ->  Atom = Raw
    ;   string(Raw), Raw \== "",
        atom_string(Atom, Raw)
    ).

positive_number(Value) :-
    number(Value),
    Value > 0.

nonnegative_integer(Value) :-
    integer(Value),
    Value >= 0.

three_positive_numbers([A, B, C], [A, B, C]) :-
    maplist(positive_number, [A, B, C]).
