:- encoding(utf8).
/** <module> The grade 8 pilot automata behind the registry's one runner
 *
 * WHAT THIS IS. Thirteen grade 8 pilot modules under
 * `knowledge/strategies/abstraction/` each answer a doing with an
 * `action_outcome/2` and a trace, in the shape the action-pair modules beside
 * this file use. Until now nothing in the loaded core named them, so the
 * worker's `strategy_trace` seam had no way to select one: `run_named_strategy/5`
 * reaches a machine only through `action_automaton_cluster/3` and
 * `run_action_automaton/6`, and neither carried a grade 8 row. This module is
 * the single seam that closes that, and it is the ONLY thing in the loaded core
 * that imports a pilot.
 *
 * WHAT IT DOES NOT DO. It computes nothing. Every answer, every trace, and every
 * validity verdict comes from the pilot that owns the doing; this file decides
 * which pilot owns which name and hands the input across unchanged. The pilots
 * are byte-unchanged by its arrival.
 *
 * THE THREE TABLES. `g8_input_kind/2` is read off each pilot decoder's own
 * `get_dict(kind, Dict, "...")` guard, so a JSON kind selects exactly one
 * decoder. `g8_action_machine/2` names the pilot that answers to each machine
 * name. `run_g8_action/4` requires the two to agree: an input decoded by one
 * pilot and a machine name owned by another refuses rather than routing across.
 *
 * WHAT IS STILL QUARANTINED. Seven further `g8_*` pilots in that directory --
 * circle and solid dimensions, decimal and fraction form, exponent expression
 * equivalence, linear equation reading and authoring, the linear expression
 * normalizer, power of ten alignment, scaled copies and similar sides -- carry
 * no row here. They are not named by
 * `curriculum/im/generated/wave5_g8_row_machine_map.jsonl`, so no attested
 * curriculum row has yet run through them, and a contract written for them would
 * rest on nothing that was read.
 */

:- module(g8_action_pairs,
          [ run_g8_action/4,           % +Machine, +DecodedInput, -Outcome, -Trace
            g8_action_machine/2,       % ?Machine, ?PilotModule
            g8_action_cluster/2,       % ?Machine, ?Cluster
            g8_action_vocabulary/2,    % ?Machine, ?Vocabulary
            g8_input_kind/2,           % ?JsonKind, ?PilotModule
            g8_decode_input/2          % +InputDict, -DecodedInput
          ]).

:- use_module(strategies('abstraction/g8_exponent_rule_rewrite')).
:- use_module(strategies('abstraction/g8_function_table')).
:- use_module(strategies('abstraction/g8_linear_equation_balance')).
:- use_module(strategies('abstraction/g8_linear_model_from_observations')).
:- use_module(strategies('abstraction/g8_linear_system_solution')).
:- use_module(strategies('abstraction/g8_plane_transformation')).
:- use_module(strategies('abstraction/g8_polygon_angle_and_tessellation')).
:- use_module(strategies('abstraction/g8_power_of_ten_notation')).
:- use_module(strategies('abstraction/g8_right_triangle_side')).
:- use_module(strategies('abstraction/g8_root_and_number_class')).
:- use_module(strategies('abstraction/g8_round_solid_volume')).
:- use_module(strategies('abstraction/g8_scatter_data_fit')).
:- use_module(strategies('abstraction/g8_two_way_table_association')).

%!  g8_input_kind(?Kind, ?Module) is nondet.
%
%   The JSON `kind` tag each pilot decoder matches on, and the pilot that
%   matches it. No tag belongs to two of the thirteen, so the tag alone chooses
%   the decoder. `angle_parts` is also a geometry-family tag; the two are told
%   apart by their fields, not by their name -- geometry reads `parts`, this
%   pilot reads `known` -- and `g8_decode_input/2` decides by decoding, so a
%   geometry input is refused here rather than misread.

g8_input_kind("exponent_claim", g8_exponent_rule_rewrite).
g8_input_kind("exponent_rewrite", g8_exponent_rule_rewrite).
g8_input_kind("input_output_table", g8_function_table).
g8_input_kind("linear_equation_two_sided", g8_linear_equation_balance).
g8_input_kind("linear_model", g8_linear_model_from_observations).
g8_input_kind("linear_system_two_unknowns", g8_linear_system_solution).
g8_input_kind("plane_transformation", g8_plane_transformation).
g8_input_kind("angle_parts", g8_polygon_angle_and_tessellation).
g8_input_kind("regular_polygon", g8_polygon_angle_and_tessellation).
g8_input_kind("power_of_ten_multiple", g8_power_of_ten_notation).
g8_input_kind("power_of_ten_numeral", g8_power_of_ten_notation).
g8_input_kind("power_of_ten_product", g8_power_of_ten_notation).
g8_input_kind("right_triangle_sides", g8_right_triangle_side).
g8_input_kind("number_class", g8_root_and_number_class).
g8_input_kind("rational_decimal", g8_root_and_number_class).
g8_input_kind("root_bracket", g8_root_and_number_class).
g8_input_kind("square_area", g8_root_and_number_class).
g8_input_kind("value_between", g8_root_and_number_class).
g8_input_kind("round_solid", g8_round_solid_volume).
g8_input_kind("paired_measurements", g8_scatter_data_fit).
g8_input_kind("paired_measurements_with_queries", g8_scatter_data_fit).
g8_input_kind("two_way_table", g8_two_way_table_association).
g8_input_kind("two_way_table_partial", g8_two_way_table_association).

%!  g8_decode_input(+Input, -Decoded) is semidet.
%
%   Decode a kind-tagged JSON dict with the pilot that owns the tag. Decoded
%   carries the owning module beside the pilot's own term, so the run below can
%   refuse a machine name that belongs to a different pilot. Fails, never
%   throws, on anything no pilot admits.
g8_decode_input(Input, g8_input(Module, Term)) :-
    is_dict(Input),
    get_dict(kind, Input, Kind),
    g8_input_kind(Kind, Module),
    g8_decode(Module, Input, Term).

g8_decode(g8_exponent_rule_rewrite, Dict, Term) :-
    g8_exponent_rule_rewrite:g8_exponent_from_json(Dict, Term).
g8_decode(g8_function_table, Dict, Term) :-
    g8_function_table:g8_function_table_from_json(Dict, Term).
g8_decode(g8_linear_equation_balance, Dict, Term) :-
    g8_linear_equation_balance:g8_linear_equation_from_json(Dict, Term).
g8_decode(g8_linear_model_from_observations, Dict, Term) :-
    g8_linear_model_from_observations:g8_linear_model_from_json(Dict, Term).
g8_decode(g8_linear_system_solution, Dict, Term) :-
    g8_linear_system_solution:g8_linear_system_from_json(Dict, Term).
g8_decode(g8_plane_transformation, Dict, Term) :-
    g8_plane_transformation:g8_transformation_from_json(Dict, Term).
g8_decode(g8_polygon_angle_and_tessellation, Dict, Term) :-
    g8_polygon_angle_and_tessellation:g8_polygon_angle_from_json(Dict, Term).
g8_decode(g8_power_of_ten_notation, Dict, Term) :-
    g8_power_of_ten_notation:g8_power_of_ten_from_json(Dict, Term).
g8_decode(g8_right_triangle_side, Dict, Term) :-
    g8_right_triangle_side:g8_right_triangle_from_json(Dict, Term).
g8_decode(g8_root_and_number_class, Dict, Term) :-
    g8_root_and_number_class:g8_root_from_json(Dict, Term).
g8_decode(g8_round_solid_volume, Dict, Term) :-
    g8_round_solid_volume:g8_round_solid_from_json(Dict, Term).
g8_decode(g8_scatter_data_fit, Dict, Term) :-
    g8_scatter_data_fit:g8_scatter_from_json(Dict, Term).
g8_decode(g8_two_way_table_association, Dict, Term) :-
    g8_two_way_table_association:g8_two_way_table_from_json(Dict, Term).

%!  run_g8_action(+Machine, +Decoded, -Outcome, -Trace) is semidet.
%
%   Hand the decoded term to the pilot that owns the machine name. The guard is
%   the identity of the two modules: a machine may only run on an input its own
%   pilot decoded.
run_g8_action(Machine, g8_input(Module, Term), Outcome, Trace) :-
    g8_action_machine(Machine, Module),
    g8_run(Module, Machine, Term, Outcome, Trace).

g8_run(g8_exponent_rule_rewrite, Machine, Term, Outcome, Trace) :-
    g8_exponent_rule_rewrite:run_g8_exponent_rule(Machine, Term, Outcome, Trace).
g8_run(g8_function_table, Machine, Term, Outcome, Trace) :-
    g8_function_table:run_g8_function_table(Machine, Term, Outcome, Trace).
g8_run(g8_linear_equation_balance, Machine, Term, Outcome, Trace) :-
    g8_linear_equation_balance:run_g8_linear_equation(Machine, Term, Outcome, Trace).
g8_run(g8_linear_model_from_observations, Machine, Term, Outcome, Trace) :-
    g8_linear_model_from_observations:run_g8_linear_model(Machine, Term, Outcome, Trace).
g8_run(g8_linear_system_solution, Machine, Term, Outcome, Trace) :-
    g8_linear_system_solution:run_g8_linear_system(Machine, Term, Outcome, Trace).
g8_run(g8_plane_transformation, Machine, Term, Outcome, Trace) :-
    g8_plane_transformation:run_g8_transformation(Machine, Term, Outcome, Trace).
g8_run(g8_polygon_angle_and_tessellation, Machine, Term, Outcome, Trace) :-
    g8_polygon_angle_and_tessellation:run_g8_polygon_angle(Machine, Term, Outcome, Trace).
g8_run(g8_power_of_ten_notation, Machine, Term, Outcome, Trace) :-
    g8_power_of_ten_notation:run_g8_power_of_ten(Machine, Term, Outcome, Trace).
g8_run(g8_right_triangle_side, Machine, Term, Outcome, Trace) :-
    g8_right_triangle_side:run_g8_right_triangle(Machine, Term, Outcome, Trace).
g8_run(g8_root_and_number_class, Machine, Term, Outcome, Trace) :-
    g8_root_and_number_class:run_g8_root(Machine, Term, Outcome, Trace).
g8_run(g8_round_solid_volume, Machine, Term, Outcome, Trace) :-
    g8_round_solid_volume:run_g8_round_solid_volume(Machine, Term, Outcome, Trace).
g8_run(g8_scatter_data_fit, Machine, Term, Outcome, Trace) :-
    g8_scatter_data_fit:run_g8_scatter_fit(Machine, Term, Outcome, Trace).
g8_run(g8_two_way_table_association, Machine, Term, Outcome, Trace) :-
    g8_two_way_table_association:run_g8_two_way_table(Machine, Term, Outcome, Trace).

%!  g8_action_machine(?Machine, ?Module) is nondet.
%
%   The thirty-eight machine names, each beside the pilot whose run predicate
%   answers to it. Each name is a clause head of that pilot's `run_g8_*/4`, and
%   each has at least one attested curriculum row in
%   `curriculum/im/generated/wave5_g8_row_machine_map.jsonl` that ran to
%   `validity(correct)`. The deformation partners those pilots also carry are
%   absent: no attested row selects one, so none is named here.

g8_action_machine(association_direction_from_the_fit,        g8_scatter_data_fit).
g8_action_machine(balance_preserving_two_sided_solution,     g8_linear_equation_balance).
g8_action_machine(bracket_root_between_whole_numbers,        g8_root_and_number_class).
g8_action_machine(classify_number_as_rational_or_irrational, g8_root_and_number_class).
g8_action_machine(combine_multiples_of_powers_of_ten,        g8_power_of_ten_notation).
g8_action_machine(complete_two_way_table,                    g8_two_way_table_association).
g8_action_machine(cone_volume_as_third_of_cylinder,          g8_round_solid_volume).
g8_action_machine(copies_around_a_vertex,                    g8_polygon_angle_and_tessellation).
g8_action_machine(cylinder_volume_from_base_and_height,      g8_round_solid_volume).
g8_action_machine(decide_exponential_equivalence,            g8_exponent_rule_rewrite).
g8_action_machine(decide_whether_the_table_is_a_function,    g8_function_table).
g8_action_machine(decimal_representation_of_a_rational,      g8_root_and_number_class).
g8_action_machine(elimination_with_substitution_back,        g8_linear_system_solution).
g8_action_machine(evaluate_rule_at_input,                    g8_function_table).
g8_action_machine(exact_side_length_from_square_area,        g8_root_and_number_class).
g8_action_machine(fit_linear_rule_to_table,                  g8_function_table).
g8_action_machine(furthest_point_from_the_fitted_line,       g8_scatter_data_fit).
g8_action_machine(hemisphere_volume_as_half_sphere,          g8_round_solid_volume).
g8_action_machine(least_squares_line_from_pairs,             g8_scatter_data_fit).
g8_action_machine(linear_model_from_rate_and_initial,        g8_linear_model_from_observations).
g8_action_machine(map_figure_through_transformation,         g8_plane_transformation).
g8_action_machine(numeral_as_multiple_of_a_power_of_ten,     g8_power_of_ten_notation).
g8_action_machine(predict_and_compare_at_queries,            g8_scatter_data_fit).
g8_action_machine(prism_volume_from_base_area_and_height,    g8_round_solid_volume).
g8_action_machine(pythagorean_converse_test,                 g8_right_triangle_side).
g8_action_machine(pythagorean_hypotenuse_from_legs,          g8_right_triangle_side).
g8_action_machine(pythagorean_leg_from_hypotenuse,           g8_right_triangle_side).
g8_action_machine(range_of_each_variable,                    g8_scatter_data_fit).
g8_action_machine(rate_of_change_from_two_observations,      g8_linear_model_from_observations).
g8_action_machine(regular_polygon_interior_angle,            g8_polygon_angle_and_tessellation).
g8_action_machine(regular_tessellation_test,                 g8_polygon_angle_and_tessellation).
g8_action_machine(relative_frequency_by_column,              g8_two_way_table_association).
g8_action_machine(relative_frequency_by_row,                 g8_two_way_table_association).
g8_action_machine(relative_frequency_of_whole_table,         g8_two_way_table_association).
g8_action_machine(rewrite_by_exponent_rule,                  g8_exponent_rule_rewrite).
g8_action_machine(sphere_volume_from_radius,                 g8_round_solid_volume).
g8_action_machine(squares_between_two_whole_numbers,         g8_root_and_number_class).
g8_action_machine(unknown_angle_from_a_whole,                g8_polygon_angle_and_tessellation).

%!  g8_action_cluster(?Machine, ?Cluster) is nondet.
%
%   The cluster each machine reports in its own outcome, read back from a run
%   rather than assigned here.

g8_action_cluster(association_direction_from_the_fit,        g8_scatter_plots_and_line_fit).
g8_action_cluster(balance_preserving_two_sided_solution,     g8_one_variable_linear_equations).
g8_action_cluster(bracket_root_between_whole_numbers,        g8_roots_and_number_class).
g8_action_cluster(classify_number_as_rational_or_irrational, g8_roots_and_number_class).
g8_action_cluster(combine_multiples_of_powers_of_ten,        g8_exponents_and_scientific_notation).
g8_action_cluster(complete_two_way_table,                    g8_two_way_tables_and_association).
g8_action_cluster(cone_volume_as_third_of_cylinder,          g8_round_solid_volume).
g8_action_cluster(copies_around_a_vertex,                    g8_polygon_angles_and_tessellation).
g8_action_cluster(cylinder_volume_from_base_and_height,      g8_round_solid_volume).
g8_action_cluster(decide_exponential_equivalence,            g8_exponent_rules).
g8_action_cluster(decide_whether_the_table_is_a_function,    g8_function_tables).
g8_action_cluster(decimal_representation_of_a_rational,      g8_roots_and_number_class).
g8_action_cluster(elimination_with_substitution_back,        g8_systems_of_linear_equations).
g8_action_cluster(evaluate_rule_at_input,                    g8_function_tables).
g8_action_cluster(exact_side_length_from_square_area,        g8_roots_and_number_class).
g8_action_cluster(fit_linear_rule_to_table,                  g8_function_tables).
g8_action_cluster(furthest_point_from_the_fitted_line,       g8_scatter_plots_and_line_fit).
g8_action_cluster(hemisphere_volume_as_half_sphere,          g8_round_solid_volume).
g8_action_cluster(least_squares_line_from_pairs,             g8_scatter_plots_and_line_fit).
g8_action_cluster(linear_model_from_rate_and_initial,        g8_linear_relationships_and_slope).
g8_action_cluster(map_figure_through_transformation,         g8_plane_transformations).
g8_action_cluster(numeral_as_multiple_of_a_power_of_ten,     g8_exponents_and_scientific_notation).
g8_action_cluster(predict_and_compare_at_queries,            g8_scatter_plots_and_line_fit).
g8_action_cluster(prism_volume_from_base_area_and_height,    g8_round_solid_volume).
g8_action_cluster(pythagorean_converse_test,                 g8_right_triangle_side_lengths).
g8_action_cluster(pythagorean_hypotenuse_from_legs,          g8_right_triangle_side_lengths).
g8_action_cluster(pythagorean_leg_from_hypotenuse,           g8_right_triangle_side_lengths).
g8_action_cluster(range_of_each_variable,                    g8_scatter_plots_and_line_fit).
g8_action_cluster(rate_of_change_from_two_observations,      g8_linear_relationships_and_slope).
g8_action_cluster(regular_polygon_interior_angle,            g8_polygon_angles_and_tessellation).
g8_action_cluster(regular_tessellation_test,                 g8_polygon_angles_and_tessellation).
g8_action_cluster(relative_frequency_by_column,              g8_two_way_tables_and_association).
g8_action_cluster(relative_frequency_by_row,                 g8_two_way_tables_and_association).
g8_action_cluster(relative_frequency_of_whole_table,         g8_two_way_tables_and_association).
g8_action_cluster(rewrite_by_exponent_rule,                  g8_exponent_rules).
g8_action_cluster(sphere_volume_from_radius,                 g8_round_solid_volume).
g8_action_cluster(squares_between_two_whole_numbers,         g8_roots_and_number_class).
g8_action_cluster(unknown_angle_from_a_whole,                g8_polygon_angles_and_tessellation).

%!  g8_action_vocabulary(?Machine, ?Vocabulary) is nondet.
%
%   The vocabulary each machine reports in its own outcome, read back from a run
%   on that machine's attested input. Terms are the pilots' own; nothing is
%   merged across machines that happen to share one.

g8_action_vocabulary(association_direction_from_the_fit,
    [scatter_plot,association,positive,negative,slope]).
g8_action_vocabulary(balance_preserving_two_sided_solution,
    [equation,unknown,equivalent_equation,balance,coefficient,constant_term,solution]).
g8_action_vocabulary(bracket_root_between_whole_numbers,
    [square_root,cube_root,consecutive_whole_numbers,estimate,perfect_square,perfect_cube]).
g8_action_vocabulary(classify_number_as_rational_or_irrational,
    [rational_number,irrational_number,numerator,denominator,integer]).
g8_action_vocabulary(combine_multiples_of_powers_of_ten,
    [coefficient,power_of_ten,exponent,product,quotient,scientific_notation]).
g8_action_vocabulary(complete_two_way_table,
    [two_way_table,missing_cell,row_total,column_total,grand_total]).
g8_action_vocabulary(cone_volume_as_third_of_cylinder,
    [cone,radius,base_area,height,cubic_units,pi,one_third]).
g8_action_vocabulary(copies_around_a_vertex,
    [regular_polygon,interior_angle,vertex,full_turn,gap,overlap]).
g8_action_vocabulary(cylinder_volume_from_base_and_height,
    [cylinder,radius,diameter,base_area,height,cubic_units,pi]).
g8_action_vocabulary(decide_exponential_equivalence,
    [power,base,exponent,equivalent_expressions,negative_exponent]).
g8_action_vocabulary(decide_whether_the_table_is_a_function,
    [function,input,output,table,rule,exactly_one_output]).
g8_action_vocabulary(decimal_representation_of_a_rational,
    [rational_number,decimal_representation,terminating,repeating,long_division]).
g8_action_vocabulary(elimination_with_substitution_back,
    [system_of_equations,two_unknowns,elimination,substitution,intersection,solution_pair]).
g8_action_vocabulary(evaluate_rule_at_input,
    [function,rule,input,output,evaluate]).
g8_action_vocabulary(exact_side_length_from_square_area,
    [square,area,side_length,square_root,exact_value,perfect_square]).
g8_action_vocabulary(fit_linear_rule_to_table,
    [function,table,linear_rule,slope,vertical_intercept,algebraic_expression]).
g8_action_vocabulary(furthest_point_from_the_fitted_line,
    [scatter_plot,residual,line_of_fit,distance_from_line]).
g8_action_vocabulary(hemisphere_volume_as_half_sphere,
    [hemisphere,sphere,radius,cubic_units,pi,half]).
g8_action_vocabulary(least_squares_line_from_pairs,
    [scatter_plot,bivariate_data,line_of_fit,slope,vertical_intercept,residual]).
g8_action_vocabulary(linear_model_from_rate_and_initial,
    [starting_amount,constant_rate,rate_of_change,vertical_intercept,linear_relationship]).
g8_action_vocabulary(map_figure_through_transformation,
    [transformation,translation,rotation,reflection,dilation,center,scale_factor,image,pre_image,vertex,coordinate_plane]).
g8_action_vocabulary(numeral_as_multiple_of_a_power_of_ten,
    [numeral,place_value,power_of_ten,exponent,coefficient,scientific_notation]).
g8_action_vocabulary(predict_and_compare_at_queries,
    [linear_model,prediction,actual_value,residual,outlier,scatter_plot]).
g8_action_vocabulary(prism_volume_from_base_area_and_height,
    [rectangular_prism,base_area,height,cubic_units]).
g8_action_vocabulary(pythagorean_converse_test,
    [right_angle,longest_side,hypotenuse,square_on_a_side,converse]).
g8_action_vocabulary(pythagorean_hypotenuse_from_legs,
    [right_angle,leg,hypotenuse,square_on_a_side,area,square_root,exact_value]).
g8_action_vocabulary(pythagorean_leg_from_hypotenuse,
    [right_angle,leg,hypotenuse,square_on_a_side,area,square_root,exact_value]).
g8_action_vocabulary(range_of_each_variable,
    [range,minimum,maximum,variable,spread]).
g8_action_vocabulary(rate_of_change_from_two_observations,
    [independent_variable,dependent_variable,vertical_change,horizontal_change,rate_of_change,slope,vertical_intercept,linear_relationship]).
g8_action_vocabulary(regular_polygon_interior_angle,
    [regular_polygon,interior_angle,vertex,triangle,angle_sum,degrees]).
g8_action_vocabulary(regular_tessellation_test,
    [regular_tessellation,plane,vertex,gap,overlap,interior_angle]).
g8_action_vocabulary(relative_frequency_by_column,
    [two_way_table,categorical_variable,column_total,relative_frequency,percentage]).
g8_action_vocabulary(relative_frequency_by_row,
    [two_way_table,categorical_variable,row_total,relative_frequency,percentage]).
g8_action_vocabulary(relative_frequency_of_whole_table,
    [two_way_table,grand_total,relative_frequency,percentage]).
g8_action_vocabulary(rewrite_by_exponent_rule,
    [power,base,exponent,expanded_form,single_exponent,reciprocal,exponent_rule]).
g8_action_vocabulary(sphere_volume_from_radius,
    [sphere,radius,circumscribing_cylinder,cubic_units,pi,two_thirds]).
g8_action_vocabulary(squares_between_two_whole_numbers,
    [square_root,between,bounds,squaring]).
g8_action_vocabulary(unknown_angle_from_a_whole,
    [angle,whole,part,remaining_angle,degrees]).
