#!/usr/bin/env swipl
/** Emit one JSON line per grade 8 pilot receipt.
 *
 * Companion to scripts/curriculum/build_g8_row_machine_map.py, in the same
 * relation scripts/sidekick/wave5_trace_runner.pl holds to its builder: the
 * Python side owns the pool and the file, and this side owns running the
 * machines. It loads the thirteen quarantined `g8_*` pilots under
 * knowledge/strategies/abstraction/, runs every receipt each one declares,
 * and writes the executed outcome. It asserts nothing about validity: a
 * receipt that comes back `unvindicated` is written as `unvindicated`, and
 * the builder decides what to do with it.
 *
 * Run from the repository root:
 *     swipl -q -f scripts/curriculum/g8_receipt_emitter.pl
 */
:- initialization(main, main).

:- use_module(library(http/json)).

main(_) :-
    consult('paths.pl'),
    use_module(strategies('abstraction/g8_linear_equation_balance')),
    use_module(strategies('abstraction/g8_linear_system_solution')),
    use_module(strategies('abstraction/g8_right_triangle_side')),
    use_module(strategies('abstraction/g8_round_solid_volume')),
    use_module(strategies('abstraction/g8_linear_model_from_observations')),
    use_module(strategies('abstraction/g8_power_of_ten_notation')),
    use_module(strategies('abstraction/g8_root_and_number_class')),
    use_module(strategies('abstraction/g8_polygon_angle_and_tessellation')),
    use_module(strategies('abstraction/g8_two_way_table_association')),
    use_module(strategies('abstraction/g8_scatter_data_fit')),
    use_module(strategies('abstraction/g8_exponent_rule_rewrite')),
    use_module(strategies('abstraction/g8_plane_transformation')),
    use_module(strategies('abstraction/g8_function_table')),
    forall(receipt(Module, Row, Lesson, Doing, Json, Cluster, Check),
           emit(Module, Row, Lesson, Doing, Json, Cluster, Check)).

receipt(g8_linear_equation_balance, Row, Lesson,
        balance_preserving_two_sided_solution, Json,
        g8_one_variable_linear_equations, substitution_into_the_original_equation) :-
    g8_linear_equation_balance:g8_linear_equation_receipt(Row, Lesson, Json, _).
receipt(g8_linear_system_solution, Row, Lesson,
        elimination_with_substitution_back, Json,
        g8_systems_of_linear_equations, substitution_into_both_original_equations) :-
    g8_linear_system_solution:g8_linear_system_receipt(Row, Lesson, Json, _).
receipt(g8_right_triangle_side, Row, Lesson, Doing, Json,
        g8_right_triangle_side_lengths, exact_relation_on_the_squares) :-
    g8_right_triangle_side:g8_right_triangle_receipt(Row, Lesson, Doing, Json, _).
receipt(g8_round_solid_volume, Row, Lesson, Doing, Json,
        g8_round_solid_volume, recompute_the_coefficient_by_a_second_route) :-
    g8_round_solid_volume:g8_round_solid_receipt(Row, Lesson, Doing, Json, _).
receipt(g8_linear_model_from_observations, Row, Lesson, Doing, Json,
        g8_linear_relationships_and_slope, substitute_both_observations) :-
    g8_linear_model_from_observations:g8_linear_model_receipt(Row, Lesson, Doing, Json, _).
receipt(g8_power_of_ten_notation, Row, Lesson, Doing, Json,
        g8_exponents_and_scientific_notation, rebuild_the_numeral_from_its_own_notation) :-
    g8_power_of_ten_notation:g8_power_of_ten_receipt(Row, Lesson, Doing, Json, _).
receipt(g8_root_and_number_class, Row, Lesson, Doing, Json,
        g8_roots_and_number_class, squaring_and_rebuilding_never_rooting) :-
    g8_root_and_number_class:g8_root_receipt(Row, Lesson, Doing, Json, _).
receipt(g8_polygon_angle_and_tessellation, Row, Lesson, Doing, Json,
        g8_polygon_angles_and_tessellation,
        triangulation_count_and_closing_the_full_turn) :-
    g8_polygon_angle_and_tessellation:g8_polygon_angle_receipt(Row, Lesson, Doing, Json, _).
receipt(g8_two_way_table_association, Row, Lesson, Doing, Json,
        g8_two_way_tables_and_association,
        rows_and_columns_agree_and_frequencies_sum_to_one) :-
    g8_two_way_table_association:g8_two_way_table_receipt(Row, Lesson, Doing, Json, _).
receipt(g8_scatter_data_fit, Row, Lesson, Doing, Json,
        g8_scatter_plots_and_line_fit, both_normal_equations_are_exactly_zero) :-
    g8_scatter_data_fit:g8_scatter_receipt(Row, Lesson, Doing, Json, _).
receipt(g8_exponent_rule_rewrite, Row, Lesson, Doing, Json,
        g8_exponent_rules, evaluate_both_sides_exactly_and_compare) :-
    g8_exponent_rule_rewrite:g8_exponent_receipt(Row, Lesson, Doing, Json, _, _).
receipt(g8_plane_transformation, Row, Lesson, Doing, Json,
        g8_plane_transformations,
        defining_relation_on_squares_and_the_scene_renders) :-
    g8_plane_transformation:g8_transformation_receipt(Row, Lesson, Doing, Json, _, _).
receipt(g8_function_table, Row, Lesson, Doing, Json,
        g8_function_tables, the_clash_exhibited_and_every_row_substituted) :-
    g8_function_table:g8_function_table_receipt(Row, Lesson, Doing, Json, _, _).

emit(Module, Row, Lesson, Doing, Json, Cluster, Check) :-
    decode(Module, Json, Figure),
    run(Module, Doing, Figure, action_outcome(_, Properties)),
    memberchk(result(Result), Properties),
    memberchk(validity(Validity), Properties),
    term_string(Result, ResultText, [quoted(true)]),
    term_string(Figure, FigureText, [quoted(true)]),
    atom_string(Module, ModuleText),
    atom_string(Doing, DoingText),
    atom_string(Cluster, ClusterText),
    atom_string(Check, CheckText),
    atom_string(Validity, ValidityText),
    atom_string(Row, RowText),
    atom_string(Lesson, LessonText),
    json_write_dict(current_output,
        _{row_id: RowText, lesson: LessonText, module: ModuleText,
          doing: DoingText, cluster: ClusterText, input: Json,
          decoded_input: FigureText, result_term: ResultText,
          validity: ValidityText, verification: CheckText},
        [width(0)]),
    nl.

decode(g8_linear_equation_balance, J, F) :-
    g8_linear_equation_balance:g8_linear_equation_from_json(J, F).
decode(g8_linear_system_solution, J, F) :-
    g8_linear_system_solution:g8_linear_system_from_json(J, F).
decode(g8_right_triangle_side, J, F) :-
    g8_right_triangle_side:g8_right_triangle_from_json(J, F).
decode(g8_round_solid_volume, J, F) :-
    g8_round_solid_volume:g8_round_solid_from_json(J, F).
decode(g8_linear_model_from_observations, J, F) :-
    g8_linear_model_from_observations:g8_linear_model_from_json(J, F).
decode(g8_power_of_ten_notation, J, F) :-
    g8_power_of_ten_notation:g8_power_of_ten_from_json(J, F).
decode(g8_root_and_number_class, J, F) :-
    g8_root_and_number_class:g8_root_from_json(J, F).
decode(g8_polygon_angle_and_tessellation, J, F) :-
    g8_polygon_angle_and_tessellation:g8_polygon_angle_from_json(J, F).
decode(g8_two_way_table_association, J, F) :-
    g8_two_way_table_association:g8_two_way_table_from_json(J, F).
decode(g8_scatter_data_fit, J, F) :-
    g8_scatter_data_fit:g8_scatter_from_json(J, F).
decode(g8_exponent_rule_rewrite, J, F) :-
    g8_exponent_rule_rewrite:g8_exponent_from_json(J, F).
decode(g8_plane_transformation, J, F) :-
    g8_plane_transformation:g8_transformation_from_json(J, F).
decode(g8_function_table, J, F) :-
    g8_function_table:g8_function_table_from_json(J, F).

run(g8_linear_equation_balance, D, F, O) :-
    g8_linear_equation_balance:run_g8_linear_equation(D, F, O, _).
run(g8_linear_system_solution, D, F, O) :-
    g8_linear_system_solution:run_g8_linear_system(D, F, O, _).
run(g8_right_triangle_side, D, F, O) :-
    g8_right_triangle_side:run_g8_right_triangle(D, F, O, _).
run(g8_round_solid_volume, D, F, O) :-
    g8_round_solid_volume:run_g8_round_solid_volume(D, F, O, _).
run(g8_linear_model_from_observations, D, F, O) :-
    g8_linear_model_from_observations:run_g8_linear_model(D, F, O, _).
run(g8_power_of_ten_notation, D, F, O) :-
    g8_power_of_ten_notation:run_g8_power_of_ten(D, F, O, _).
run(g8_root_and_number_class, D, F, O) :-
    g8_root_and_number_class:run_g8_root(D, F, O, _).
run(g8_polygon_angle_and_tessellation, D, F, O) :-
    g8_polygon_angle_and_tessellation:run_g8_polygon_angle(D, F, O, _).
run(g8_two_way_table_association, D, F, O) :-
    g8_two_way_table_association:run_g8_two_way_table(D, F, O, _).
run(g8_scatter_data_fit, D, F, O) :-
    g8_scatter_data_fit:run_g8_scatter_fit(D, F, O, _).
run(g8_exponent_rule_rewrite, D, F, O) :-
    g8_exponent_rule_rewrite:run_g8_exponent_rule(D, F, O, _).
run(g8_plane_transformation, D, F, O) :-
    g8_plane_transformation:run_g8_transformation(D, F, O, _).
run(g8_function_table, D, F, O) :-
    g8_function_table:run_g8_function_table(D, F, O, _).
