:- module(wave5_pilot_route,
          [ g8_solution_result/4,
            g8_partner_result/5,
            scene_solution_result/3
          ]).

:- use_module(strategies('abstraction/g8_linear_equation_balance')).
:- use_module(strategies('abstraction/g8_linear_system_solution')).
:- use_module(strategies('abstraction/g8_right_triangle_side')).
:- use_module(strategies('abstraction/g8_round_solid_volume')).
:- use_module(strategies('abstraction/g8_linear_model_from_observations')).
:- use_module(strategies('abstraction/g8_power_of_ten_notation')).
:- use_module(strategies('abstraction/g8_root_and_number_class')).
:- use_module(strategies('abstraction/g8_polygon_angle_and_tessellation')).
:- use_module(strategies('abstraction/g8_two_way_table_association')).
:- use_module(strategies('abstraction/g8_scatter_data_fit')).
:- use_module(strategies('abstraction/g8_exponent_rule_rewrite')).
:- use_module(strategies('abstraction/g8_plane_transformation')).
:- use_module(strategies('abstraction/g8_function_table')).
:- use_module(strategies('abstraction/k7_array_grid')).
:- use_module(strategies('abstraction/k7_equal_share_bars')).

g8_solution_result(Module, Doing, Json, Result) :-
    decode(Module, Json, Figure),
    run(Module, Doing, Figure, action_outcome(_, Properties)),
    memberchk(validity(correct), Properties),
    memberchk(result(Result), Properties).

g8_partner_result(Module, ProductiveDoing, Variant, Json, Result) :-
    g8_partner(Module, ProductiveDoing, Variant, PartnerDoing),
    decode(Module, Json, Figure),
    run(Module, PartnerDoing, Figure, action_outcome(_, Properties)),
    memberchk(classification(Variant), Properties),
    memberchk(validity(incorrect), Properties),
    memberchk(result(Result), Properties).

% The pilot modules currently contain deformation partners but no
% correct-but-inefficient clauses. Keeping the relation explicit makes the
% absence queryable and prevents the diagnosis mint from completing a partial
% triple by substitution.
g8_partner(g8_linear_equation_balance,
           balance_preserving_two_sided_solution, deformation,
           subtract_constant_to_clear_negative_term).
g8_partner(g8_right_triangle_side,
           pythagorean_hypotenuse_from_legs, deformation,
           triangle_area_for_hypotenuse).
g8_partner(g8_right_triangle_side,
           pythagorean_hypotenuse_from_legs, deformation,
           grid_diagonal_as_one_unit).
g8_partner(g8_round_solid_volume,
           cylinder_volume_from_base_and_height, deformation,
           scale_volume_linearly_with_radius).
g8_partner(g8_round_solid_volume,
           cone_volume_as_third_of_cylinder, deformation,
           scale_volume_linearly_with_radius).
g8_partner(g8_round_solid_volume,
           sphere_volume_from_radius, deformation,
           scale_volume_linearly_with_radius).
g8_partner(g8_round_solid_volume,
           hemisphere_volume_as_half_sphere, deformation,
           scale_volume_linearly_with_radius).
g8_partner(g8_linear_model_from_observations,
           rate_of_change_from_two_observations, deformation,
           successive_output_difference_as_slope).
g8_partner(g8_linear_model_from_observations,
           solve_linear_model_for_input, deformation,
           drop_the_vertical_intercept).
g8_partner(g8_power_of_ten_notation,
           numeral_as_multiple_of_a_power_of_ten, deformation,
           write_the_exponent_without_its_sign).
g8_partner(g8_scatter_data_fit,
           least_squares_line_from_pairs, deformation,
           steepness_read_as_segment_length).
g8_partner(g8_exponent_rule_rewrite,
           rewrite_by_exponent_rule, deformation,
           negative_exponent_as_negative_value).
g8_partner(g8_plane_transformation,
           map_figure_through_transformation, deformation,
           dilate_by_adding_a_constant).

scene_solution_result(array_grid, Json, Result) :-
    k7_array_grid:k7_grid_from_json(Json, Task),
    k7_array_grid:run_k7_array_grid(
        draw_the_count_as_unit_squares, Task, action_outcome(_, Properties), _),
    memberchk(squares_drawn(Result), Properties),
    memberchk(validity(Validity), Properties),
    memberchk(Validity, [correct, incorrect]).
scene_solution_result(equal_share_bars, Json, Result) :-
    k7_equal_share_bars:k7_bars_from_json(Json, Task),
    k7_equal_share_bars:run_k7_equal_share_bars(
        draw_the_shares_as_bars, Task, action_outcome(_, Properties), _),
    memberchk(share_the_machine_named(Result), Properties),
    memberchk(validity(correct), Properties).

decode(g8_linear_equation_balance, J, F) :- g8_linear_equation_balance:g8_linear_equation_from_json(J, F).
decode(g8_linear_system_solution, J, F) :- g8_linear_system_solution:g8_linear_system_from_json(J, F).
decode(g8_right_triangle_side, J, F) :- g8_right_triangle_side:g8_right_triangle_from_json(J, F).
decode(g8_round_solid_volume, J, F) :- g8_round_solid_volume:g8_round_solid_from_json(J, F).
decode(g8_linear_model_from_observations, J, F) :- g8_linear_model_from_observations:g8_linear_model_from_json(J, F).
decode(g8_power_of_ten_notation, J, F) :- g8_power_of_ten_notation:g8_power_of_ten_from_json(J, F).
decode(g8_root_and_number_class, J, F) :- g8_root_and_number_class:g8_root_from_json(J, F).
decode(g8_polygon_angle_and_tessellation, J, F) :- g8_polygon_angle_and_tessellation:g8_polygon_angle_from_json(J, F).
decode(g8_two_way_table_association, J, F) :- g8_two_way_table_association:g8_two_way_table_from_json(J, F).
decode(g8_scatter_data_fit, J, F) :- g8_scatter_data_fit:g8_scatter_from_json(J, F).
decode(g8_exponent_rule_rewrite, J, F) :- g8_exponent_rule_rewrite:g8_exponent_from_json(J, F).
decode(g8_plane_transformation, J, F) :- g8_plane_transformation:g8_transformation_from_json(J, F).
decode(g8_function_table, J, F) :- g8_function_table:g8_function_table_from_json(J, F).

run(g8_linear_equation_balance, D, F, O) :- g8_linear_equation_balance:run_g8_linear_equation(D, F, O, _).
run(g8_linear_system_solution, D, F, O) :- g8_linear_system_solution:run_g8_linear_system(D, F, O, _).
run(g8_right_triangle_side, D, F, O) :- g8_right_triangle_side:run_g8_right_triangle(D, F, O, _).
run(g8_round_solid_volume, D, F, O) :- g8_round_solid_volume:run_g8_round_solid_volume(D, F, O, _).
run(g8_linear_model_from_observations, D, F, O) :- g8_linear_model_from_observations:run_g8_linear_model(D, F, O, _).
run(g8_power_of_ten_notation, D, F, O) :- g8_power_of_ten_notation:run_g8_power_of_ten(D, F, O, _).
run(g8_root_and_number_class, D, F, O) :- g8_root_and_number_class:run_g8_root(D, F, O, _).
run(g8_polygon_angle_and_tessellation, D, F, O) :- g8_polygon_angle_and_tessellation:run_g8_polygon_angle(D, F, O, _).
run(g8_two_way_table_association, D, F, O) :- g8_two_way_table_association:run_g8_two_way_table(D, F, O, _).
run(g8_scatter_data_fit, D, F, O) :- g8_scatter_data_fit:run_g8_scatter_fit(D, F, O, _).
run(g8_exponent_rule_rewrite, D, F, O) :- g8_exponent_rule_rewrite:run_g8_exponent_rule(D, F, O, _).
run(g8_plane_transformation, D, F, O) :- g8_plane_transformation:run_g8_transformation(D, F, O, _).
run(g8_function_table, D, F, O) :- g8_function_table:run_g8_function_table(D, F, O, _).
