/** <module> Productive geometry action automata
 *
 * Makes the executable geometry plans used by learner/activity_contract.pl
 * available through the shared action registry. These actions coordinate a
 * measurement or location action with an existing spatial scene compiler.
 * They are productive-only until a deformation is supported by an explicit
 * transformation and a corresponding representation check.
 */

:- module(geometry_action_pairs,
          [ run_geometry_action/5,
            geometry_action_cluster/2,
            geometry_action_vocabulary/2,
            productive_geometry_deformation/3,
            geometry_action_misconception_hook/3
          ]).

:- use_module(formalization(grounded_arithmetic),
              [ integer_to_recollection/2,
                recollection_to_integer/2,
                add_grounded/3,
                multiply_grounded/3
              ]).
:- use_module(render(area_model_scene), [area_render_json/2]).
:- use_module(render(geoboard_scene), [geoboard_render_json/2]).
:- use_module(render(area_unit_covering_scene),
              [area_unit_covering_render_json/2]).
:- use_module(render(solid_net_scene), [solid_net_render_json/2]).
:- use_module(render(coordinate_plane_scene), [coordinate_plane_render_json/2]).
:- use_module(render(angle_circular_scene),
              [ angle_circular_render_json/2,
                angle_circular_compare_json/2
              ]).
:- use_module(render(polyform_tiling_scene), [polyform_tiling_render_json/2]).


run_geometry_action(rectangle_area_unit_iteration, Rows, Columns,
                    Outcome, Trace) :-
    positive_integer(Rows),
    positive_integer(Columns),
    grounded_product(Rows, Columns, Area),
    area_render_json(array_multiplication(Rows, Columns), Scene),
    successful_scene(Scene),
    Outcome = action_outcome(
                  rectangle_area_unit_iteration,
                  [ classification(productive),
                    cluster(geometry_area_as_composite_unit_iteration),
                    automaton_state(coordinate_rows_columns_and_square_units),
                    vocabulary([rectangle, row, column, unit_square,
                                square_unit, tile_without_gaps_or_overlaps,
                                area, composite_unit]),
                    input(rectangle(Rows, Columns)),
                    result(square_units(Area)),
                    expected(square_units(Area)),
                    representation(Scene),
                    validity(correct),
                    elaborates(formalization:grounded_arithmetic:multiply_grounded/3)
                  ]),
    Trace = [ establish_rectangle(Rows, Columns),
              iterate_rows(Rows),
              iterate_columns(Columns),
              coordinate_square_units,
              count_square_units(Area)
            ].
run_geometry_action(area_as_perimeter_count, Rows, Columns, Outcome, Trace) :-
    bounded_rectangle_dimension(Rows),
    bounded_rectangle_dimension(Columns),
    grounded_product(Rows, Columns, Area),
    rectangle_perimeter_value(Rows, Columns, Perimeter),
    rectangle_geoboard_scene(Rows, Columns, Scene),
    Outcome = action_outcome(
                  area_as_perimeter_count,
                  [ classification(deformation),
                    cluster(geometry_area_as_composite_unit_iteration),
                    automaton_state(count_boundary_units_instead_of_covering_interior),
                    vocabulary([rectangle, area, perimeter, interior,
                                boundary, square_unit, unit_segment,
                                container_schema]),
                    input(rectangle(Rows, Columns)),
                    expected(square_units(Area)),
                    result(boundary_units(Perimeter)),
                    representation(Scene),
                    deformation_of(rectangle_area_unit_iteration),
                    violated_invariant(area_counts_interior_square_units),
                    validity(incorrect)
                  ]),
    Trace = [ establish_rectangle(Rows, Columns),
              ignore_interior_coverage,
              traverse_boundary_instead(Perimeter),
              substitute_boundary_count_for_area
            ].
run_geometry_action(area_unit_covering,
                    covered_cells(Cells), unit(Unit), Outcome, Trace) :-
    sort(Cells, UniqueCells),
    UniqueCells = [_|_],
    same_length(Cells, UniqueCells),
    atom(Unit),
    area_unit_covering_render_json(cover(UniqueCells, Unit), Scene),
    successful_scene(Scene),
    length(UniqueCells, Area),
    Outcome = action_outcome(
                  area_unit_covering,
                  [ classification(productive),
                    cluster(geometry_area_as_unit_covering),
                    automaton_state(cover_region_once_with_equal_unit_squares),
                    vocabulary([area, region, unit_square, cover, interior,
                                no_gap, no_overlap, square_unit, spatial_extent]),
                    input(covered_cells(Cells)), unit(Unit),
                    result(area(Area, square(Unit))),
                    expected(area(Area, square(Unit))), representation(Scene),
                    invariant(each_covered_cell_counted_exactly_once),
                    validity(correct)
                  ]),
    Trace = [ establish_unit_square(Unit), place_equal_unit_squares(Cells),
              verify_distinct_coverage(UniqueCells), count_covered_cells(Area),
              report_area_in_square_units(Area, Unit)
            ].
run_geometry_action(count_overlapping_area_tiles,
                    placed_tiles(Cells), unit(Unit), Outcome, Trace) :-
    sort(Cells, UniqueCells),
    UniqueCells = [_|_],
    length(Cells, PlacedCount),
    length(UniqueCells, CoveredCount),
    PlacedCount > CoveredCount,
    atom(Unit),
    area_unit_covering_render_json(overlap(Cells, Unit), Scene),
    successful_scene(Scene),
    Outcome = action_outcome(
                  count_overlapping_area_tiles,
                  [ classification(deformation),
                    cluster(geometry_area_as_unit_covering),
                    automaton_state(count_placements_without_checking_overlap),
                    vocabulary([area, region, unit_square, overlap,
                                repeated_cell, double_count, square_unit]),
                    input(placed_tiles(Cells)), unit(Unit),
                    result(area(PlacedCount, square(Unit))),
                    expected(area(CoveredCount, square(Unit))),
                    representation(Scene),
                    deformation_of(area_unit_covering),
                    violated_invariant(each_covered_cell_counted_exactly_once),
                    validity(incorrect)
                  ]),
    Trace = [ place_unit_squares(Cells), omit_overlap_check,
              count_tile_placements(PlacedCount),
              double_count_covered_cells(PlacedCount, CoveredCount)
            ].
run_geometry_action(area_unit_scale_selection,
                    area_extent(ExtentClass), candidates(Candidates),
                    Outcome, Trace) :-
    select_area_unit(ExtentClass, Candidates, Unit),
    Outcome = action_outcome(
                  area_unit_scale_selection,
                  [ classification(productive),
                    cluster(geometry_area_unit_scale_coordination),
                    automaton_state(match_square_unit_scale_to_area_referent),
                    vocabulary([area, referent, spatial_extent, square_unit,
                                centimeter, inch, foot, meter, unit_choice]),
                    input(area_extent(ExtentClass)),
                    candidates(Candidates),
                    result(square_unit(Unit)),
                    expected(square_unit(Unit)),
                    representation(area_unit_scale_table(Candidates,
                                                         selected(Unit))),
                    invariant(area_unit_scale_matches_referent_extent),
                    validity(correct)
                  ]),
    Trace = [ classify_area_referent_extent(ExtentClass),
              compare_candidate_square_unit_scales(Candidates),
              select_matching_square_unit(Unit)
            ].
run_geometry_action(choose_first_area_unit_without_scale,
                    area_extent(ExtentClass), candidates(Candidates),
                    Outcome, Trace) :-
    select_area_unit(ExtentClass, Candidates, ExpectedUnit),
    Candidates = [unit(ReportedUnit, ReportedClass)|_],
    ReportedClass \== ExtentClass,
    Outcome = action_outcome(
                  choose_first_area_unit_without_scale,
                  [ classification(deformation),
                    cluster(geometry_area_unit_scale_coordination),
                    automaton_state(select_familiar_unit_without_extent_comparison),
                    vocabulary([area, referent, spatial_extent, square_unit,
                                familiar_unit, uncoordinated_scale]),
                    input(area_extent(ExtentClass)),
                    candidates(Candidates),
                    result(square_unit(ReportedUnit)),
                    expected(square_unit(ExpectedUnit)),
                    representation(area_unit_scale_table(
                                       Candidates, selected(ReportedUnit))),
                    deformation_of(area_unit_scale_selection),
                    violated_invariant(area_unit_scale_matches_referent_extent),
                    validity(incorrect)
                  ]),
    Trace = [ ignore_area_referent_extent(ExtentClass),
              select_first_familiar_unit(ReportedUnit),
              omit_unit_scale_comparison
            ].
run_geometry_action(rectangle_perimeter_boundary_traversal,
                    rectangle(Length, Width), unit(Unit), Outcome, Trace) :-
    bounded_rectangle_dimension(Length),
    bounded_rectangle_dimension(Width),
    atom(Unit),
    rectangle_perimeter_value(Length, Width, Perimeter),
    rectangle_geoboard_scene(Length, Width, Scene),
    Outcome = action_outcome(
                  rectangle_perimeter_boundary_traversal,
                  [ classification(productive),
                    cluster(geometry_perimeter_as_complete_boundary_traversal),
                    automaton_state(traverse_four_sides_and_preserve_length_unit),
                    vocabulary([rectangle, perimeter, boundary, side_length,
                                opposite_sides_equal, unit_segment,
                                complete_traversal, container_schema]),
                    input(rectangle(Length, Width, unit(Unit))),
                    result(length(Perimeter, Unit)),
                    expected(length(Perimeter, Unit)),
                    representation(Scene),
                    invariant(perimeter_traverses_all_four_sides),
                    validity(correct)
                  ]),
    Trace = [ establish_rectangle(Length, Width),
              traverse_side(length, Length),
              traverse_side(width, Width),
              traverse_opposite_side(length, Length),
              traverse_opposite_side(width, Width),
              accumulate_boundary_length(Perimeter, Unit)
            ].
run_geometry_action(perimeter_two_sides_only,
                    rectangle(Length, Width), unit(Unit), Outcome, Trace) :-
    bounded_rectangle_dimension(Length),
    bounded_rectangle_dimension(Width),
    atom(Unit),
    grounded_sum(Length, Width, Partial),
    rectangle_perimeter_value(Length, Width, Expected),
    rectangle_geoboard_scene(Length, Width, Scene),
    Outcome = action_outcome(
                  perimeter_two_sides_only,
                  [ classification(deformation),
                    cluster(geometry_perimeter_as_complete_boundary_traversal),
                    automaton_state(stop_after_one_length_and_one_width),
                    vocabulary([rectangle, perimeter, boundary, side_length,
                                incomplete_traversal, unit_segment]),
                    input(rectangle(Length, Width, unit(Unit))),
                    expected(length(Expected, Unit)),
                    result(length(Partial, Unit)),
                    representation(Scene),
                    deformation_of(rectangle_perimeter_boundary_traversal),
                    violated_invariant(perimeter_traverses_all_four_sides),
                    validity(incorrect)
                  ]),
    Trace = [ traverse_side(length, Length), traverse_side(width, Width),
              stop_before_opposite_sides, report_partial_boundary(Partial, Unit) ].
run_geometry_action(perimeter_uses_area_formula,
                    rectangle(Length, Width), unit(Unit), Outcome, Trace) :-
    bounded_rectangle_dimension(Length),
    bounded_rectangle_dimension(Width),
    atom(Unit),
    grounded_product(Length, Width, AreaValue),
    rectangle_perimeter_value(Length, Width, Expected),
    rectangle_geoboard_scene(Length, Width, Scene),
    Outcome = action_outcome(
                  perimeter_uses_area_formula,
                  [ classification(deformation),
                    cluster(geometry_perimeter_as_complete_boundary_traversal),
                    automaton_state(multiply_dimensions_instead_of_traversing_boundary),
                    vocabulary([rectangle, perimeter, area, boundary, interior,
                                formula_substitution, container_schema]),
                    input(rectangle(Length, Width, unit(Unit))),
                    expected(length(Expected, Unit)),
                    result(length(AreaValue, Unit)),
                    representation(Scene),
                    deformation_of(rectangle_perimeter_boundary_traversal),
                    violated_invariant(boundary_measure_is_not_interior_area),
                    validity(incorrect)
                  ]),
    Trace = [ observe_dimensions(Length, Width),
              select_area_formula_by_surface_association,
              multiply_dimensions(AreaValue),
              report_area_value_as_perimeter(AreaValue, Unit) ].
run_geometry_action(polygon_perimeter_boundary_accumulation,
                    sides(SideLengths), unit(Unit), Outcome, Trace) :-
    valid_side_lengths(SideLengths),
    atom(Unit),
    sum_list(SideLengths, Perimeter),
    Outcome = action_outcome(
                  polygon_perimeter_boundary_accumulation,
                  [ classification(productive),
                    cluster(geometry_polygon_perimeter_boundary_cycle),
                    automaton_state(traverse_each_polygon_side_once),
                    vocabulary([polygon, perimeter, boundary, side_length,
                                boundary_cycle, linear_unit, accumulation]),
                    input(sides(SideLengths)), unit(Unit),
                    result(length(Perimeter, Unit)),
                    expected(length(Perimeter, Unit)),
                    representation(boundary_cycle(
                                       segments(SideLengths), closed(true))),
                    invariant(each_boundary_side_accumulated_exactly_once),
                    validity(correct)
                  ]),
    Trace = [ establish_closed_polygon_boundary,
              traverse_side_lengths_in_order(SideLengths),
              accumulate_complete_boundary(Perimeter, Unit)
            ].
run_geometry_action(omit_unlabeled_boundary_side,
                    sides(SideLengths), unit(Unit), Outcome, Trace) :-
    valid_side_lengths(SideLengths),
    atom(Unit),
    append(CountedSides, [OmittedSide], SideLengths),
    CountedSides = [_|_],
    sum_list(SideLengths, Expected),
    sum_list(CountedSides, Reported),
    Outcome = action_outcome(
                  omit_unlabeled_boundary_side,
                  [ classification(deformation),
                    cluster(geometry_polygon_perimeter_boundary_cycle),
                    automaton_state(sum_visible_labels_without_closing_boundary),
                    vocabulary([polygon, perimeter, boundary, side_length,
                                unlabeled_side, incomplete_cycle]),
                    input(sides(SideLengths)), unit(Unit),
                    result(length(Reported, Unit)),
                    expected(length(Expected, Unit)),
                    representation(open_boundary_path(
                                       counted(CountedSides),
                                       omitted(OmittedSide))),
                    deformation_of(polygon_perimeter_boundary_accumulation),
                    violated_invariant(each_boundary_side_accumulated_exactly_once),
                    validity(incorrect)
                  ]),
    Trace = [ read_labeled_sides(CountedSides),
              stop_before_boundary_closure,
              omit_side_length(OmittedSide),
              report_partial_boundary(Reported, Unit)
            ].
run_geometry_action(symmetry_constrained_side_reconstruction,
                    side_orbits(Orbits), perimeter(Perimeter, Unit), Outcome, Trace) :-
    atom(Unit),
    solve_symmetry_orbits(Orbits, Perimeter, Name, SideLength,
                          KnownContribution, Multiplicity),
    Outcome = action_outcome(
                  symmetry_constrained_side_reconstruction,
                  [ classification(productive),
                    cluster(geometry_symmetry_constrained_perimeter),
                    automaton_state(group_reflected_sides_then_solve_boundary),
                    vocabulary([line_symmetry, reflection, side_orbit,
                                equal_length, perimeter, unknown_side,
                                inverse_operation]),
                    input(side_orbits(Orbits)), perimeter(Perimeter, Unit),
                    result(side_length(Name, SideLength, Unit)),
                    expected(side_length(Name, SideLength, Unit)),
                    representation(symmetry_orbit_equation(
                                       total(Perimeter),
                                       known(KnownContribution),
                                       unknown_copies(Multiplicity, Name))),
                    invariant(reflected_sides_share_length),
                    validity(correct)
                  ]),
    Trace = [ establish_perimeter(Perimeter),
              group_sides_into_reflection_orbits(Orbits),
              accumulate_known_orbits(KnownContribution),
              isolate_unknown_orbit(Multiplicity, Name),
              partition_remaining_boundary(Multiplicity, SideLength)
            ].
run_geometry_action(ignore_symmetry_multiplicity,
                    side_orbits(Orbits), perimeter(Perimeter, Unit), Outcome, Trace) :-
    atom(Unit),
    solve_symmetry_orbits(Orbits, Perimeter, Name, Expected,
                          _KnownContribution, _Multiplicity),
    flatten_orbit_multiplicities(Orbits, FlatKnown, Name),
    Reported is Perimeter - FlatKnown,
    Reported > 0,
    Reported =\= Expected,
    Outcome = action_outcome(
                  ignore_symmetry_multiplicity,
                  [ classification(deformation),
                    cluster(geometry_symmetry_constrained_perimeter),
                    automaton_state(count_each_side_orbit_once),
                    vocabulary([line_symmetry, side_orbit, perimeter,
                                unknown_side, ignored_multiplicity]),
                    input(side_orbits(Orbits)), perimeter(Perimeter, Unit),
                    result(side_length(Name, Reported, Unit)),
                    expected(side_length(Name, Expected, Unit)),
                    representation(flattened_orbit_equation(
                                       total(Perimeter), known(FlatKnown))),
                    deformation_of(symmetry_constrained_side_reconstruction),
                    violated_invariant(reflected_sides_share_length),
                    validity(incorrect)
                  ]),
    Trace = [ establish_perimeter(Perimeter),
              ignore_reflected_side_copies,
              count_each_orbit_once(FlatKnown),
              subtract_flat_known_total(Reported)
            ].
run_geometry_action(rectangle_perimeter_side_pair_search, Perimeter,
                    side_scope(Scope), Outcome, Trace) :-
    integer(Perimeter), Perimeter >= 4, 0 is Perimeter mod 2,
    memberchk(Scope, [one, all]),
    rectangle_perimeter_pairs(Perimeter, Pairs),
    Pairs = [_|_],
    perimeter_pair_scenes(Pairs, Scenes),
    perimeter_scope_result(Scope, Perimeter, Pairs, Result),
    Outcome = action_outcome(
                  rectangle_perimeter_side_pair_search,
                  [ classification(productive),
                    cluster(geometry_fixed_perimeter_dimension_search),
                    automaton_state(vary_side_pairs_while_preserving_boundary_total),
                    vocabulary([rectangle, perimeter, side_length,
                                opposite_sides_equal, fixed_boundary,
                                exhaustive_search, area_varies]),
                    input(perimeter(Perimeter)),
                    side_pairs(Pairs),
                    result(Result),
                    expected(Result),
                    representations(Scenes),
                    invariant(each_pair_has_perimeter(Perimeter)),
                    validity(correct)
                  ]),
    Trace = [ establish_target_perimeter(Perimeter),
              halve_for_length_plus_width,
              enumerate_positive_side_pairs(Pairs),
              retain_complete_boundaries(Perimeter),
              satisfy_side_scope(Scope)
            ].
run_geometry_action(rectangle_missing_side_from_perimeter,
                    perimeter(Perimeter), known_side(Known), Outcome, Trace) :-
    integer(Perimeter), Perimeter >= 4, 0 is Perimeter mod 2,
    positive_integer(Known),
    Half is Perimeter // 2,
    Missing is Half - Known,
    positive_integer(Missing),
    rectangle_geoboard_scene(Known, Missing, Scene),
    Outcome = action_outcome(
                  rectangle_missing_side_from_perimeter,
                  [ classification(productive),
                    cluster(geometry_inverse_perimeter_side_reasoning),
                    automaton_state(recover_missing_side_from_half_perimeter),
                    vocabulary([rectangle, perimeter, known_side,
                                unknown_side, opposite_sides_equal,
                                inverse_operation, boundary]),
                    input(perimeter_and_known_side(Perimeter, Known)),
                    result(side_length(Missing)),
                    expected(side_length(Missing)),
                    representation(Scene),
                    invariant(twice_side_sum_equals_perimeter),
                    validity(correct)
                  ]),
    Trace = [ establish_target_perimeter(Perimeter),
              coordinate_opposite_side_pairs,
              halve_perimeter(Half),
              subtract_known_side(Known, Missing),
              verify_rectangle_boundary(Perimeter)
            ].
run_geometry_action(rectangle_factor_pair_search, Area, factor_scope(Scope),
                    Outcome, Trace) :-
    positive_integer(Area),
    memberchk(Scope, [one, all]),
    rectangle_factor_pairs(Area, Pairs),
    Pairs = [_|_],
    pair_scenes(Pairs, Scenes),
    scope_result(Scope, Pairs, Result),
    Outcome = action_outcome(
                  rectangle_factor_pair_search,
                  [ classification(productive),
                    cluster(geometry_area_factor_pair_construction),
                    automaton_state(search_whole_number_side_lengths_preserving_area),
                    vocabulary([rectangle, area, whole_number_side_length,
                                factor, factor_pair, commutative_pair,
                                exhaustive_search, square_unit]),
                    input(area_in_square_units(Area)),
                    scope(Scope),
                    factor_pairs(Pairs),
                    result(Result),
                    expected(Result),
                    representations(Scenes),
                    validity(correct),
                    elaborates(rectangle_area_unit_iteration)
                  ]),
    Trace = [ establish_target_area(Area),
              enumerate_whole_number_side_lengths,
              retain_products_equal_to_area(Pairs),
              identify_rotations_as_commutative_pairs,
              satisfy_factor_scope(Scope)
            ].
run_geometry_action(rectangle_area_perimeter_constraint_search,
                    constraints(area(Area), perimeter(Perimeter)),
                    constraint_scope(all), Outcome, Trace) :-
    positive_integer(Area),
    integer(Perimeter), Perimeter >= 4, 0 is Perimeter mod 2,
    rectangle_factor_pairs(Area, AreaPairs),
    include_pairs_with_perimeter(AreaPairs, Perimeter, Pairs),
    Pairs = [_|_],
    pair_scenes(Pairs, Scenes),
    Result = rectangles(Pairs),
    Outcome = action_outcome(
                  rectangle_area_perimeter_constraint_search,
                  [ classification(productive),
                    cluster(geometry_rectangle_conjunctive_constraint_search),
                    automaton_state(intersect_area_and_perimeter_side_pair_sets),
                    vocabulary([rectangle, area, perimeter, side_length,
                                constraint, factor_pair, boundary,
                                intersection, design]),
                    input(constraints(area(Area), perimeter(Perimeter))),
                    result(Result), expected(Result), representations(Scenes),
                    invariant(each_rectangle_satisfies_area_and_perimeter),
                    validity(correct)
                  ]),
    Trace = [ establish_area_constraint(Area),
              establish_perimeter_constraint(Perimeter),
              enumerate_area_factor_pairs(AreaPairs),
              retain_pairs_with_perimeter(Perimeter, Pairs),
              report_constrained_rectangles(Pairs)
            ].
run_geometry_action(ignore_perimeter_rectangle_constraint,
                    constraints(area(Area), perimeter(Perimeter)),
                    constraint_scope(all), Outcome, Trace) :-
    positive_integer(Area),
    integer(Perimeter), Perimeter >= 4, 0 is Perimeter mod 2,
    rectangle_factor_pairs(Area, AreaPairs),
    include_pairs_with_perimeter(AreaPairs, Perimeter, ExpectedPairs),
    ExpectedPairs = [_|_],
    AreaPairs \== ExpectedPairs,
    pair_scenes(AreaPairs, Scenes),
    Outcome = action_outcome(
                  ignore_perimeter_rectangle_constraint,
                  [ classification(deformation),
                    cluster(geometry_rectangle_conjunctive_constraint_search),
                    automaton_state(retain_area_pairs_without_boundary_filter),
                    vocabulary([rectangle, area, perimeter, constraint,
                                factor_pair, ignored_constraint, design]),
                    input(constraints(area(Area), perimeter(Perimeter))),
                    result(rectangles(AreaPairs)),
                    expected(rectangles(ExpectedPairs)), representations(Scenes),
                    deformation_of(rectangle_area_perimeter_constraint_search),
                    violated_invariant(each_rectangle_satisfies_area_and_perimeter),
                    validity(incorrect)
                  ]),
    Trace = [ establish_area_constraint(Area),
              ignore_perimeter_constraint(Perimeter),
              retain_all_area_factor_pairs(AreaPairs),
              report_unfiltered_rectangles(AreaPairs)
            ].
run_geometry_action(rectangle_missing_side_from_area,
                    area(Area), known_side(KnownSide), Outcome, Trace) :-
    positive_integer(Area), positive_integer(KnownSide),
    0 is Area mod KnownSide,
    MissingSide is Area // KnownSide,
    positive_integer(MissingSide),
    rectangle_geoboard_scene(KnownSide, MissingSide, Scene),
    Outcome = action_outcome(
                  rectangle_missing_side_from_area,
                  [ classification(productive),
                    cluster(geometry_inverse_area_dimension_reasoning),
                    automaton_state(invert_area_product_by_exact_division),
                    vocabulary([rectangle, area, known_side, unknown_side,
                                inverse_multiplication, exact_division,
                                factor, square_unit]),
                    input(area(Area)), known_side(KnownSide),
                    result(side_length(MissingSide)),
                    expected(side_length(MissingSide)), representation(Scene),
                    invariant(known_side_times_missing_side_equals_area),
                    validity(correct)
                  ]),
    Trace = [ establish_area_product(Area), retain_known_side(KnownSide),
              divide_area_by_known_side(Area, KnownSide, MissingSide),
              reconstruct_rectangle(KnownSide, MissingSide)
            ].
run_geometry_action(subtract_side_from_area,
                    area(Area), known_side(KnownSide), Outcome, Trace) :-
    positive_integer(Area), positive_integer(KnownSide),
    0 is Area mod KnownSide,
    MissingSide is Area // KnownSide,
    ReportedSide is Area - KnownSide,
    ReportedSide > 0, ReportedSide =\= MissingSide,
    rectangle_geoboard_scene(KnownSide, MissingSide, Scene),
    Outcome = action_outcome(
                  subtract_side_from_area,
                  [ classification(deformation),
                    cluster(geometry_inverse_area_dimension_reasoning),
                    automaton_state(treat_area_as_additive_total),
                    vocabulary([rectangle, area, known_side, unknown_side,
                                subtraction, product_as_sum, operation_confusion]),
                    input(area(Area)), known_side(KnownSide),
                    result(side_length(ReportedSide)),
                    expected(side_length(MissingSide)), representation(Scene),
                    deformation_of(rectangle_missing_side_from_area),
                    violated_invariant(known_side_times_missing_side_equals_area),
                    validity(incorrect)
                  ]),
    Trace = [ establish_area_as_total(Area),
              subtract_known_side(Area, KnownSide, ReportedSide),
              omit_inverse_multiplication,
              report_additive_remainder_as_side(ReportedSide)
            ].
run_geometry_action(rectangular_prism_volume_layer_iteration,
                    prism(Length, Width), Height, Outcome, Trace) :-
    positive_integer(Length),
    positive_integer(Width),
    positive_integer(Height),
    grounded_product(Length, Width, BaseArea),
    grounded_product(BaseArea, Height, Volume),
    solid_net_render_json(unit_cube_stack(Length, Width, Height), Scene),
    successful_scene(Scene),
    Outcome = action_outcome(
                  rectangular_prism_volume_layer_iteration,
                  [ classification(productive),
                    cluster(geometry_volume_as_layered_composite_unit),
                    automaton_state(iterate_unit_cube_layers_over_base),
                    vocabulary([rectangular_prism, unit_cube, base,
                                base_area, layer, height, cubic_unit, volume]),
                    input(rectangular_prism(Length, Width, Height)),
                    base_area(BaseArea),
                    result(cubic_units(Volume)),
                    expected(cubic_units(Volume)),
                    representation(Scene),
                    validity(correct),
                    elaborates(formalization:grounded_arithmetic:multiply_grounded/3)
                  ]),
    Trace = [ coordinate_base(Length, Width, BaseArea),
              establish_unit_cube_as_volume_unit,
              iterate_height_layers(Height),
              count_cubic_units(Volume)
            ].
run_geometry_action(rectangular_prism_missing_dimension_from_volume,
                    volume(Volume), known_base(Length, Width), Outcome, Trace) :-
    positive_integer(Volume), positive_integer(Length), positive_integer(Width),
    grounded_product(Length, Width, BaseArea),
    0 is Volume mod BaseArea,
    Height is Volume // BaseArea,
    positive_integer(Height),
    solid_net_render_json(unit_cube_stack(Length, Width, Height), Scene),
    successful_scene(Scene),
    Outcome = action_outcome(
                  rectangular_prism_missing_dimension_from_volume,
                  [ classification(productive),
                    cluster(geometry_inverse_volume_dimension_reasoning),
                    automaton_state(invert_three_factor_volume_by_known_base),
                    vocabulary([rectangular_prism, volume, base_area,
                                known_dimensions, unknown_dimension,
                                inverse_multiplication, exact_division,
                                cubic_unit]),
                    input(volume(Volume)), known_base(Length, Width),
                    base_area(BaseArea), result(dimension(Height)),
                    expected(dimension(Height)), representation(Scene),
                    invariant(base_area_times_height_equals_volume),
                    validity(correct)
                  ]),
    Trace = [ coordinate_known_base(Length, Width, BaseArea),
              divide_volume_by_base_area(Volume, BaseArea, Height),
              reconstruct_unit_cube_stack(Length, Width, Height)
            ].
run_geometry_action(divide_volume_by_one_dimension,
                    volume(Volume), known_base(Length, Width), Outcome, Trace) :-
    positive_integer(Volume), positive_integer(Length), positive_integer(Width),
    Width > 1,
    grounded_product(Length, Width, BaseArea),
    0 is Volume mod BaseArea,
    Height is Volume // BaseArea,
    0 is Volume mod Length,
    ReportedHeight is Volume // Length,
    ReportedHeight =\= Height,
    solid_net_render_json(unit_cube_stack(Length, Width, Height), Scene),
    successful_scene(Scene),
    Outcome = action_outcome(
                  divide_volume_by_one_dimension,
                  [ classification(deformation),
                    cluster(geometry_inverse_volume_dimension_reasoning),
                    automaton_state(invert_volume_using_only_one_known_dimension),
                    vocabulary([rectangular_prism, volume, base_area,
                                known_dimensions, dropped_dimension,
                                partial_division, cubic_unit]),
                    input(volume(Volume)), known_base(Length, Width),
                    result(dimension(ReportedHeight)),
                    expected(dimension(Height)), representation(Scene),
                    deformation_of(rectangular_prism_missing_dimension_from_volume),
                    violated_invariant(base_area_times_height_equals_volume),
                    validity(incorrect)
                  ]),
    Trace = [ retain_one_known_dimension(Length),
              drop_second_base_dimension(Width),
              divide_volume_by_length_only(Volume, Length, ReportedHeight),
              report_partial_quotient_as_height(ReportedHeight)
            ].
run_geometry_action(composite_prism_volume_sum,
                    certified_disjoint_prisms(Prisms), unit(Unit),
                    Outcome, Trace) :-
    prism_components(Prisms, ComponentVolumes, Scenes),
    sum_list(ComponentVolumes, Volume),
    Outcome = action_outcome(
                  composite_prism_volume_sum,
                  [ classification(productive),
                    cluster(geometry_composite_prism_volume),
                    automaton_state(decompose_into_disjoint_prisms_then_sum_volumes),
                    vocabulary([composite_solid, rectangular_prism, unit_cube,
                                disjoint_decomposition, component_volume,
                                additive_volume, cubic_unit]),
                    input(certified_disjoint_prisms(Prisms)), unit(Unit),
                    component_volumes(ComponentVolumes),
                    result(volume(Volume, cube(Unit))),
                    expected(volume(Volume, cube(Unit))),
                    representations(Scenes),
                    invariant(disjoint_component_volumes_sum_to_whole),
                    validity(correct)
                  ]),
    Trace = [ certify_disjoint_prism_decomposition,
              calculate_component_volumes(ComponentVolumes),
              sum_component_volumes(Volume), preserve_composite_volume
            ].
run_geometry_action(sum_overlapping_prism_volumes,
                    overlapping_prisms(Prisms, OverlapVolume), unit(Unit),
                    Outcome, Trace) :-
    prism_components(Prisms, ComponentVolumes, Scenes),
    positive_integer(OverlapVolume),
    sum_list(ComponentVolumes, ReportedVolume),
    ExpectedVolume is ReportedVolume - OverlapVolume,
    ExpectedVolume > 0,
    Outcome = action_outcome(
                  sum_overlapping_prism_volumes,
                  [ classification(deformation),
                    cluster(geometry_composite_prism_volume),
                    automaton_state(sum_components_without_subtracting_overlap),
                    vocabulary([composite_solid, rectangular_prism, overlap,
                                double_count, component_volume, cubic_unit]),
                    input(overlapping_prisms(Prisms, OverlapVolume)), unit(Unit),
                    component_volumes(ComponentVolumes),
                    result(volume(ReportedVolume, cube(Unit))),
                    expected(volume(ExpectedVolume, cube(Unit))),
                    representations(Scenes),
                    deformation_of(composite_prism_volume_sum),
                    violated_invariant(disjoint_component_volumes_sum_to_whole),
                    validity(incorrect)
                  ]),
    Trace = [ calculate_component_volumes(ComponentVolumes),
              omit_overlap_correction(OverlapVolume),
              double_count_shared_cubes(OverlapVolume),
              report_component_sum(ReportedVolume)
            ].
run_geometry_action(ordered_pair_coordinate_plot, Points, axes(cartesian),
                    Outcome, Trace) :-
    valid_points(Points),
    coordinate_plane_render_json(plot_points(Points), Scene),
    successful_scene(Scene),
    Outcome = action_outcome(
                  ordered_pair_coordinate_plot,
                  [ classification(productive),
                    cluster(geometry_ordered_pair_location),
                    automaton_state(locate_first_coordinate_then_second),
                    vocabulary([coordinate_plane, origin, horizontal_axis,
                                vertical_axis, ordered_pair, first_coordinate,
                                second_coordinate, directed_distance, point]),
                    input(Points),
                    result(plotted_points(Points)),
                    expected(plotted_points(Points)),
                    representation(Scene),
                    validity(correct)
                  ]),
    Trace = [ establish_cartesian_axes,
              preserve_coordinate_order,
              locate_first_then_second_for_each_pair(Points)
            ].
run_geometry_action(axis_aligned_coordinate_distance,
                    points(point(X1, Y1), point(X2, Y2)), unit(Unit),
                    Outcome, Trace) :-
    integer(X1), integer(Y1), integer(X2), integer(Y2),
    atom(Unit),
    axis_aligned_difference(X1, Y1, X2, Y2, Axis, DirectedDifference),
    Distance is abs(DirectedDifference),
    coordinate_plane_render_json(plot_points([X1-Y1, X2-Y2]), Scene),
    successful_scene(Scene),
    Outcome = action_outcome(
                  axis_aligned_coordinate_distance,
                  [ classification(productive),
                    cluster(geometry_axis_aligned_coordinate_distance),
                    automaton_state(hold_one_coordinate_fixed_and_measure_absolute_change),
                    vocabulary([coordinate_plane, ordered_pair, horizontal_axis,
                                vertical_axis, aligned_points, directed_difference,
                                absolute_value, distance, length_unit]),
                    input(points(point(X1, Y1), point(X2, Y2))), axis(Axis),
                    result(length(Distance, Unit)),
                    expected(length(Distance, Unit)), representation(Scene),
                    invariant(distance_is_nonnegative_absolute_coordinate_change),
                    validity(correct)
                  ]),
    Trace = [ plot_endpoint(point(X1, Y1)), plot_endpoint(point(X2, Y2)),
              hold_other_coordinate_fixed(Axis),
              subtract_varying_coordinates(DirectedDifference),
              take_absolute_coordinate_change(Distance, Unit)
            ].
run_geometry_action(directed_difference_as_coordinate_distance,
                    points(point(X1, Y1), point(X2, Y2)), unit(Unit),
                    Outcome, Trace) :-
    integer(X1), integer(Y1), integer(X2), integer(Y2),
    atom(Unit),
    axis_aligned_difference(X1, Y1, X2, Y2, Axis, DirectedDifference),
    DirectedDifference < 0,
    Distance is abs(DirectedDifference),
    coordinate_plane_render_json(plot_points([X1-Y1, X2-Y2]), Scene),
    successful_scene(Scene),
    Outcome = action_outcome(
                  directed_difference_as_coordinate_distance,
                  [ classification(deformation),
                    cluster(geometry_axis_aligned_coordinate_distance),
                    automaton_state(report_directed_change_without_absolute_value),
                    vocabulary([coordinate_plane, aligned_points,
                                directed_difference, absolute_value, distance,
                                negative_length]),
                    input(points(point(X1, Y1), point(X2, Y2))), axis(Axis),
                    result(length(DirectedDifference, Unit)),
                    expected(length(Distance, Unit)), representation(Scene),
                    deformation_of(axis_aligned_coordinate_distance),
                    violated_invariant(distance_is_nonnegative_absolute_coordinate_change),
                    validity(incorrect)
                  ]),
    Trace = [ plot_endpoint(point(X1, Y1)), plot_endpoint(point(X2, Y2)),
              subtract_varying_coordinates(DirectedDifference),
              omit_absolute_value,
              report_directed_change_as_length(DirectedDifference, Unit)
            ].
run_geometry_action(area_preserving_polygon_decomposition,
                    polygon(Vertices), certified_partition(Pieces), Outcome, Trace) :-
    polygon_double_area(Vertices, WholeArea2),
    maplist(polygon_double_area, Pieces, PieceAreas2),
    sum_list(PieceAreas2, WholeArea2),
    area_value(WholeArea2, Area),
    maplist(area_value, PieceAreas2, PieceAreas),
    polygon_scenes([Vertices|Pieces], Scenes),
    Outcome = action_outcome(
                  area_preserving_polygon_decomposition,
                  [ classification(productive),
                    cluster(geometry_polygon_area_conservation),
                    automaton_state(decompose_without_gap_or_overlap_then_sum_parts),
                    vocabulary([polygon, area, decompose, compose, rearrange,
                                nonoverlap, no_gap, part, whole, conservation]),
                    input(polygon(Vertices)), certified_partition(Pieces),
                    part_areas(PieceAreas), result(square_units(Area)),
                    expected(square_units(Area)), representations(Scenes),
                    invariant(certified_partition_preserves_whole_area),
                    validity(correct)
                  ]),
    Trace = [ establish_polygon(Vertices),
              decompose_into_nonoverlapping_pieces(Pieces),
              measure_piece_areas(PieceAreas),
              sum_piece_areas(Area), preserve_whole_area(Area)
            ].
run_geometry_action(decomposition_with_gap_or_overlap,
                    polygon(Vertices), decomposition(Pieces), Outcome, Trace) :-
    polygon_double_area(Vertices, WholeArea2),
    maplist(polygon_double_area, Pieces, PieceAreas2),
    sum_list(PieceAreas2, ReportedArea2),
    ReportedArea2 =\= WholeArea2,
    area_value(WholeArea2, ExpectedArea),
    area_value(ReportedArea2, ReportedArea),
    maplist(area_value, PieceAreas2, PieceAreas),
    polygon_scenes([Vertices|Pieces], Scenes),
    Outcome = action_outcome(
                  decomposition_with_gap_or_overlap,
                  [ classification(deformation),
                    cluster(geometry_polygon_area_conservation),
                    automaton_state(sum_piece_areas_without_coverage_check),
                    vocabulary([polygon, area, decomposition, gap, overlap,
                                part, whole, conservation]),
                    input(polygon(Vertices)), decomposition(Pieces),
                    part_areas(PieceAreas),
                    result(square_units(ReportedArea)),
                    expected(square_units(ExpectedArea)), representations(Scenes),
                    deformation_of(area_preserving_polygon_decomposition),
                    violated_invariant(sum_part_areas_equals_whole_area),
                    validity(incorrect)
                  ]),
    Trace = [ establish_polygon(Vertices), accept_unchecked_pieces(Pieces),
              omit_gap_overlap_test,
              sum_piece_areas(ReportedArea),
              lose_whole_area(ExpectedArea)
            ].
run_geometry_action(parallelogram_area_base_height,
                    parallelogram(Base, Height, SlantedSide, Offset), unit(Unit),
                    Outcome, Trace) :-
    valid_parallelogram_dimensions(Base, Height, SlantedSide, Offset),
    Area is Base * Height,
    parallelogram_scene(Base, Height, Offset, Scene),
    Outcome = action_outcome(
                  parallelogram_area_base_height,
                  [ classification(productive),
                    cluster(geometry_parallelogram_area_base_height),
                    automaton_state(cut_translate_and_coordinate_perpendicular_height),
                    vocabulary([parallelogram, base, perpendicular_height,
                                slanted_side, cut, translate, rectangle, area,
                                square_unit]),
                    input(parallelogram(Base, Height, SlantedSide, Offset)),
                    unit(Unit), result(area(Area, square(Unit))),
                    expected(area(Area, square(Unit))), representation(Scene),
                    invariant(height_is_perpendicular_distance_to_opposite_base),
                    validity(correct)
                  ]),
    Trace = [ identify_base(Base),
              distinguish_height_from_slanted_side(Height, SlantedSide),
              cut_and_translate_to_rectangle,
              multiply_base_by_perpendicular_height(Base, Height, Area)
            ].
run_geometry_action(slanted_side_as_parallelogram_height,
                    parallelogram(Base, Height, SlantedSide, Offset), unit(Unit),
                    Outcome, Trace) :-
    valid_parallelogram_dimensions(Base, Height, SlantedSide, Offset),
    SlantedSide =\= Height,
    ExpectedArea is Base * Height,
    ReportedArea is Base * SlantedSide,
    parallelogram_scene(Base, Height, Offset, Scene),
    Outcome = action_outcome(
                  slanted_side_as_parallelogram_height,
                  [ classification(deformation),
                    cluster(geometry_parallelogram_area_base_height),
                    automaton_state(multiply_base_by_nonperpendicular_side),
                    vocabulary([parallelogram, base, height, slanted_side,
                                perpendicular, area]),
                    input(parallelogram(Base, Height, SlantedSide, Offset)),
                    unit(Unit), result(area(ReportedArea, square(Unit))),
                    expected(area(ExpectedArea, square(Unit))), representation(Scene),
                    deformation_of(parallelogram_area_base_height),
                    violated_invariant(height_is_perpendicular_distance_to_opposite_base),
                    validity(incorrect)
                  ]),
    Trace = [ identify_base(Base), select_slanted_side_as_height(SlantedSide),
              omit_perpendicularity_check,
              multiply_base_by_slanted_side(Base, SlantedSide, ReportedArea)
            ].
run_geometry_action(triangle_area_half_base_height,
                    triangle(Base, Height), unit(Unit), Outcome, Trace) :-
    positive_integer(Base), positive_integer(Height), atom(Unit),
    Product is Base * Height,
    area_value(Product, 2, Area),
    triangle_scene(Base, Height, Scene),
    Outcome = action_outcome(
                  triangle_area_half_base_height,
                  [ classification(productive),
                    cluster(geometry_triangle_area_half_product),
                    automaton_state(compose_matching_triangle_pair_then_take_one_half),
                    vocabulary([triangle, base, perpendicular_height,
                                matching_copy, parallelogram, half, area,
                                square_unit]),
                    input(triangle(Base, Height)), unit(Unit),
                    result(area(Area, square(Unit))),
                    expected(area(Area, square(Unit))), representation(Scene),
                    invariant(triangle_is_half_matching_parallelogram),
                    validity(correct)
                  ]),
    Trace = [ identify_base(Base), identify_perpendicular_height(Height),
              compose_matching_triangle_copy,
              form_parallelogram_product(Product),
              take_one_of_two_equal_triangles(Area)
            ].
run_geometry_action(omit_half_in_triangle_area,
                    triangle(Base, Height), unit(Unit), Outcome, Trace) :-
    positive_integer(Base), positive_integer(Height), atom(Unit),
    Product is Base * Height,
    area_value(Product, 2, ExpectedArea),
    triangle_scene(Base, Height, Scene),
    Outcome = action_outcome(
                  omit_half_in_triangle_area,
                  [ classification(deformation),
                    cluster(geometry_triangle_area_half_product),
                    automaton_state(report_matching_parallelogram_area_for_one_triangle),
                    vocabulary([triangle, base, height, parallelogram,
                                half, area, omitted_halving]),
                    input(triangle(Base, Height)), unit(Unit),
                    result(area(Product, square(Unit))),
                    expected(area(ExpectedArea, square(Unit))), representation(Scene),
                    deformation_of(triangle_area_half_base_height),
                    violated_invariant(triangle_is_half_matching_parallelogram),
                    validity(incorrect)
                  ]),
    Trace = [ multiply_base_by_height(Base, Height, Product),
              omit_matching_copy_relation,
              omit_halving, report_parallelogram_area_for_triangle(Product)
            ].
run_geometry_action(polyhedron_surface_area_from_net,
                    net(Solid, FaceAreas), unit(Unit), Outcome, Trace) :-
    valid_face_areas(Solid, FaceAreas), atom(Unit),
    sum_list(FaceAreas, SurfaceArea),
    solid_net_render_json(net_of(Solid), Scene),
    successful_scene(Scene),
    Outcome = action_outcome(
                  polyhedron_surface_area_from_net,
                  [ classification(productive),
                    cluster(geometry_surface_area_as_all_face_coverage),
                    automaton_state(unfold_then_sum_every_nonoverlapping_face),
                    vocabulary([polyhedron, face, net, unfold, surface_area,
                                square_unit, prism, pyramid, all_faces]),
                    input(net(Solid, FaceAreas)), unit(Unit),
                    result(area(SurfaceArea, square(Unit))),
                    expected(area(SurfaceArea, square(Unit))), representation(Scene),
                    invariant(each_polyhedron_face_counted_exactly_once),
                    validity(correct)
                  ]),
    Trace = [ identify_polyhedron(Solid), unfold_to_net,
              enumerate_all_face_areas(FaceAreas),
              sum_each_face_exactly_once(SurfaceArea)
            ].
run_geometry_action(visible_faces_only_surface_area,
                    net(Solid, FaceAreas), unit(Unit), Outcome, Trace) :-
    valid_face_areas(Solid, FaceAreas), atom(Unit),
    append(VisibleFaceAreas, [_HiddenFace], FaceAreas),
    VisibleFaceAreas = [_|_],
    sum_list(FaceAreas, ExpectedSurfaceArea),
    sum_list(VisibleFaceAreas, ReportedSurfaceArea),
    solid_net_render_json(net_of(Solid), Scene),
    successful_scene(Scene),
    Outcome = action_outcome(
                  visible_faces_only_surface_area,
                  [ classification(deformation),
                    cluster(geometry_surface_area_as_all_face_coverage),
                    automaton_state(sum_drawn_visible_faces_and_omit_hidden_face),
                    vocabulary([polyhedron, face, net, visible_face,
                                hidden_face, surface_area, incomplete_coverage]),
                    input(net(Solid, FaceAreas)), unit(Unit),
                    result(area(ReportedSurfaceArea, square(Unit))),
                    expected(area(ExpectedSurfaceArea, square(Unit))),
                    representation(Scene),
                    deformation_of(polyhedron_surface_area_from_net),
                    violated_invariant(each_polyhedron_face_counted_exactly_once),
                    validity(incorrect)
                  ]),
    Trace = [ inspect_solid_view, enumerate_visible_faces(VisibleFaceAreas),
              omit_hidden_face, report_partial_surface_area(ReportedSurfaceArea)
            ].
run_geometry_action(dimensional_measure_unit_coordination,
                    measure(Dimension, Value), unit(Unit), Outcome, Trace) :-
    dimension_power(Dimension, Power, MeasureName),
    number(Value), Value >= 0, atom(Unit),
    Quantity = measured_quantity(MeasureName, Value, unit_power(Unit, Power)),
    Outcome = action_outcome(
                  dimensional_measure_unit_coordination,
                  [ classification(productive),
                    cluster(geometry_dimension_measure_unit_coordination),
                    automaton_state(match_iteration_dimension_to_unit_exponent),
                    vocabulary([length, area, volume, dimension, linear_unit,
                                square_unit, cubic_unit, exponent, notation]),
                    input(measure(Dimension, Value)), unit(Unit),
                    result(Quantity), expected(Quantity),
                    representation(unit_inscription(Unit, Power)),
                    invariant(unit_exponent_matches_measure_dimension),
                    validity(correct)
                  ]),
    Trace = [ identify_measure_dimension(Dimension),
              identify_measure_name(MeasureName),
              coordinate_unit_iteration_power(Power),
              inscribe_unit_exponent(Unit, Power)
            ].
run_geometry_action(linear_unit_for_area_or_volume,
                    measure(Dimension, Value), unit(Unit), Outcome, Trace) :-
    dimension_power(Dimension, Power, MeasureName),
    Power > 1, number(Value), Value >= 0, atom(Unit),
    Expected = measured_quantity(MeasureName, Value, unit_power(Unit, Power)),
    Reported = measured_quantity(MeasureName, Value, unit_power(Unit, 1)),
    Outcome = action_outcome(
                  linear_unit_for_area_or_volume,
                  [ classification(deformation),
                    cluster(geometry_dimension_measure_unit_coordination),
                    automaton_state(write_linear_unit_for_higher_dimensional_measure),
                    vocabulary([area, volume, dimension, linear_unit,
                                square_unit, cubic_unit, exponent, notation]),
                    input(measure(Dimension, Value)), unit(Unit),
                    result(Reported), expected(Expected),
                    representation(unit_inscription(Unit, 1)),
                    deformation_of(dimensional_measure_unit_coordination),
                    violated_invariant(unit_exponent_matches_measure_dimension),
                    validity(incorrect)
                  ]),
    Trace = [ identify_measure_dimension(Dimension),
              ignore_dimension_power(Power),
              write_linear_unit(Unit), lose_unit_exponent(Power)
            ].
run_geometry_action(shape_classification_by_defining_attributes,
                    shape(Shape, ObservedAttributes), orientation(QuarterTurns),
                    Outcome, Trace) :-
    shape_profile(Shape, RequiredAttributes, Superclasses),
    valid_quarter_turns(QuarterTurns),
    attributes_include(ObservedAttributes, RequiredAttributes),
    Outcome = action_outcome(
                  shape_classification_by_defining_attributes,
                  [ classification(productive),
                    cluster(geometry_shape_attribute_classification),
                    automaton_state(test_defining_attributes_then_preserve_name_under_rotation),
                    vocabulary([shape, defining_attribute, side, vertex, angle,
                                parallel, equal_length, orientation, rotation,
                                category, hierarchy]),
                    input(shape(Shape, ObservedAttributes)),
                    orientation(quarter_turns(QuarterTurns)),
                    required_attributes(RequiredAttributes),
                    result(classifications([Shape|Superclasses])),
                    expected(classifications([Shape|Superclasses])),
                    invariant(classification_independent_of_orientation),
                    validity(correct)
                  ]),
    Trace = [ observe_attributes(ObservedAttributes),
              test_required_attributes(RequiredAttributes),
              ignore_nondefining_orientation(QuarterTurns),
              retain_hierarchical_categories([Shape|Superclasses])
            ].
run_geometry_action(orientation_bound_shape_classification,
                    shape(Shape, ObservedAttributes), orientation(QuarterTurns),
                    Outcome, Trace) :-
    shape_profile(Shape, RequiredAttributes, Superclasses),
    attributes_include(ObservedAttributes, RequiredAttributes),
    valid_quarter_turns(QuarterTurns),
    QuarterTurns =\= 0,
    Outcome = action_outcome(
                  orientation_bound_shape_classification,
                  [ classification(deformation),
                    cluster(geometry_shape_attribute_classification),
                    automaton_state(reject_nonprototype_orientation),
                    vocabulary([shape, defining_attribute, prototype,
                                orientation, rotation, category]),
                    input(shape(Shape, ObservedAttributes)),
                    orientation(quarter_turns(QuarterTurns)),
                    expected(classifications([Shape|Superclasses])),
                    result(not_recognized_as(Shape)),
                    deformation_of(shape_classification_by_defining_attributes),
                    violated_invariant(classification_independent_of_orientation),
                    validity(incorrect)
                  ]),
    Trace = [ observe_attributes(ObservedAttributes),
              privilege_prototype_orientation,
              reject_after_rotation(QuarterTurns, Shape)
            ].
run_geometry_action(angle_turn_measurement, Degrees, unit(degree), Outcome, Trace) :-
    valid_angle_measure(Degrees),
    angle_circular_render_json(angle(Degrees), Scene),
    successful_scene(Scene),
    Outcome = action_outcome(
                  angle_turn_measurement,
                  [ classification(productive),
                    cluster(geometry_angle_as_turn_measurement),
                    automaton_state(iterate_one_degree_turns_around_fixed_vertex),
                    vocabulary([angle, vertex, initial_ray, terminal_ray,
                                turn, degree, protractor, rotation]),
                    input(angle_measure(Degrees)),
                    result(angle_measure(Degrees)),
                    expected(angle_measure(Degrees)),
                    representation(Scene),
                    invariant(ray_length_does_not_change_angle_measure),
                    validity(correct)
                  ]),
    Trace = [ establish_fixed_vertex,
              establish_initial_ray,
              iterate_degree_turn(Degrees),
              locate_terminal_ray,
              read_angle_measure(Degrees)
            ].
run_geometry_action(angle_as_ray_length, Degrees, unit(degree), Outcome, Trace) :-
    valid_angle_measure(Degrees),
    angle_circular_compare_json(angle_length_compare(Degrees, 150, 300), Scene),
    \+ get_dict(error, Scene, _),
    Outcome = action_outcome(
                  angle_as_ray_length,
                  [ classification(deformation),
                    cluster(geometry_angle_as_turn_measurement),
                    automaton_state(read_longer_drawn_ray_as_larger_angle),
                    vocabulary([angle, ray_length, visual_extent, bigger,
                                degree, turn]),
                    input(angle_measure(Degrees)),
                    expected(angle_measure(Degrees)),
                    result(misread_as_larger(angle_measure(Degrees))),
                    representation(Scene),
                    deformation_of(angle_turn_measurement),
                    violated_invariant(ray_length_does_not_change_angle_measure),
                    validity(incorrect)
                  ]),
    Trace = [ preserve_turn(Degrees), stretch_ray_length(150, 300),
              misread_visual_extent_as_angle_magnitude
            ].
run_geometry_action(angle_additive_composition, angle_parts(Parts),
                    whole_angle(Expected), Outcome, Trace) :-
    valid_angle_parts(Parts),
    sum_list(Parts, Total),
    Total =:= Expected,
    valid_angle_measure(Total),
    angle_circular_render_json(angle(Total), Scene),
    successful_scene(Scene),
    Outcome = action_outcome(
                  angle_additive_composition,
                  [ classification(productive),
                    cluster(geometry_angle_additive_composition),
                    automaton_state(join_adjacent_turns_with_shared_vertex),
                    vocabulary([angle, adjacent_angles, composition,
                                decomposition, part, whole, unknown_angle,
                                addition, subtraction]),
                    input(angle_parts(Parts)),
                    result(angle_measure(Total)),
                    expected(angle_measure(Expected)),
                    representation(Scene),
                    invariant(part_turns_sum_to_whole_turn),
                    validity(correct)
                  ]),
    Trace = [ establish_shared_vertex, preserve_adjacent_turns(Parts),
              sum_part_measures(Total), verify_whole_angle(Expected)
            ].
run_geometry_action(rigid_shape_composition, region(Columns, Rows), Pieces,
                    Outcome, Trace) :-
    positive_integer(Columns),
    positive_integer(Rows),
    is_list(Pieces),
    Pieces = [_|_],
    polyform_tiling_render_json(
        tile_region(cols(Columns), rows(Rows), Pieces), Scene),
    successful_scene(Scene),
    Outcome = action_outcome(
                  rigid_shape_composition,
                  [ classification(productive),
                    cluster(geometry_shape_composition),
                    automaton_state(place_rigid_parts_inside_bounded_whole),
                    vocabulary([shape, part, whole, compose, decompose,
                                rigid_motion, rotate, translate, fit,
                                boundary, no_gap, no_overlap]),
                    input(tiling(region(Columns, Rows), Pieces)),
                    result(composed_region(Columns, Rows)),
                    expected(composed_region(Columns, Rows)),
                    representation(Scene),
                    invariant(parts_preserved_inside_bounded_whole),
                    validity(correct)
                  ]),
    Trace = [ establish_bounded_region(Columns, Rows),
              preserve_rigid_parts(Pieces),
              place_parts_by_rigid_motion,
              inspect_coverage_without_gaps_or_overlaps
            ].
run_geometry_action(compare_solid_volume_by_cube_count,
                    solid_cube_counts(CountA, CountB),
                    visual_extents(ExtentA, ExtentB), Outcome, Trace) :-
    maplist(positive_integer, [CountA, CountB]),
    maplist(positive_number, [ExtentA, ExtentB]),
    geometry_relation(CountA, CountB, Relation),
    Representation = cube_count_comparison(
                         solid_a(cubes(CountA), extent(ExtentA)),
                         solid_b(cubes(CountB), extent(ExtentB))),
    Outcome = action_outcome(
                  compare_solid_volume_by_cube_count,
                  [ classification(productive),
                    cluster(geometry_solid_volume_comparison),
                    automaton_state(compare_conserved_cubic_units),
                    vocabulary([solid_object, volume, unit_cube,
                                cube_count, composition, conservation,
                                visual_extent]),
                    input(solid_cube_counts(CountA, CountB)),
                    result(Relation), expected(Relation),
                    representation(Representation),
                    invariant(volume_compared_by_conserved_cubic_units),
                    validity(correct)
                  ]),
    Trace = [ establish_unit_cube_as_volume_unit,
              count_cubes_in_solid(a, CountA),
              count_cubes_in_solid(b, CountB),
              ignore_arrangement_extent(ExtentA, ExtentB),
              compare_cubic_unit_counts(CountA, CountB, Relation)
            ].
run_geometry_action(compare_solid_volume_by_visible_extent,
                    solid_cube_counts(CountA, CountB),
                    visual_extents(ExtentA, ExtentB), Outcome, Trace) :-
    maplist(positive_integer, [CountA, CountB]),
    maplist(positive_number, [ExtentA, ExtentB]),
    geometry_relation(CountA, CountB, Expected),
    geometry_relation(ExtentA, ExtentB, Result),
    relation_validity(Expected, Result, Validity),
    Representation = cube_count_comparison(
                         solid_a(cubes(CountA), extent(ExtentA)),
                         solid_b(cubes(CountB), extent(ExtentB))),
    Outcome = action_outcome(
                  compare_solid_volume_by_visible_extent,
                  [ classification(deformation),
                    cluster(geometry_solid_volume_comparison),
                    automaton_state(compare_bounding_extent_as_volume),
                    vocabulary([solid_object, volume, visual_extent,
                                height, spread, cube_count_ignored]),
                    input(solid_cube_counts(CountA, CountB)),
                    result(Result), expected(Expected),
                    representation(Representation),
                    deformation_of(compare_solid_volume_by_cube_count),
                    violated_invariant(
                        volume_compared_by_conserved_cubic_units),
                    validity(Validity)
                  ]),
    Trace = [ inspect_visible_extent(ExtentA, ExtentB),
              ignore_unit_cube_counts(CountA, CountB),
              compare_bounding_extents(ExtentA, ExtentB, Result)
            ].


geometry_action_cluster(rectangle_area_unit_iteration,
                        geometry_area_as_composite_unit_iteration).
geometry_action_cluster(area_as_perimeter_count,
                        geometry_area_as_composite_unit_iteration).
geometry_action_cluster(area_unit_covering,
                        geometry_area_as_unit_covering).
geometry_action_cluster(count_overlapping_area_tiles,
                        geometry_area_as_unit_covering).
geometry_action_cluster(area_unit_scale_selection,
                        geometry_area_unit_scale_coordination).
geometry_action_cluster(choose_first_area_unit_without_scale,
                        geometry_area_unit_scale_coordination).
geometry_action_cluster(rectangle_perimeter_boundary_traversal,
                        geometry_perimeter_as_complete_boundary_traversal).
geometry_action_cluster(perimeter_two_sides_only,
                        geometry_perimeter_as_complete_boundary_traversal).
geometry_action_cluster(perimeter_uses_area_formula,
                        geometry_perimeter_as_complete_boundary_traversal).
geometry_action_cluster(polygon_perimeter_boundary_accumulation,
                        geometry_polygon_perimeter_boundary_cycle).
geometry_action_cluster(omit_unlabeled_boundary_side,
                        geometry_polygon_perimeter_boundary_cycle).
geometry_action_cluster(symmetry_constrained_side_reconstruction,
                        geometry_symmetry_constrained_perimeter).
geometry_action_cluster(ignore_symmetry_multiplicity,
                        geometry_symmetry_constrained_perimeter).
geometry_action_cluster(rectangle_perimeter_side_pair_search,
                        geometry_fixed_perimeter_dimension_search).
geometry_action_cluster(rectangle_missing_side_from_perimeter,
                        geometry_inverse_perimeter_side_reasoning).
geometry_action_cluster(rectangle_factor_pair_search,
                        geometry_area_factor_pair_construction).
geometry_action_cluster(rectangle_area_perimeter_constraint_search,
                        geometry_rectangle_conjunctive_constraint_search).
geometry_action_cluster(ignore_perimeter_rectangle_constraint,
                        geometry_rectangle_conjunctive_constraint_search).
geometry_action_cluster(rectangle_missing_side_from_area,
                        geometry_inverse_area_dimension_reasoning).
geometry_action_cluster(subtract_side_from_area,
                        geometry_inverse_area_dimension_reasoning).
geometry_action_cluster(rectangular_prism_volume_layer_iteration,
                        geometry_volume_as_layered_composite_unit).
geometry_action_cluster(rectangular_prism_missing_dimension_from_volume,
                        geometry_inverse_volume_dimension_reasoning).
geometry_action_cluster(divide_volume_by_one_dimension,
                        geometry_inverse_volume_dimension_reasoning).
geometry_action_cluster(composite_prism_volume_sum,
                        geometry_composite_prism_volume).
geometry_action_cluster(sum_overlapping_prism_volumes,
                        geometry_composite_prism_volume).
geometry_action_cluster(ordered_pair_coordinate_plot,
                        geometry_ordered_pair_location).
geometry_action_cluster(axis_aligned_coordinate_distance,
                        geometry_axis_aligned_coordinate_distance).
geometry_action_cluster(directed_difference_as_coordinate_distance,
                        geometry_axis_aligned_coordinate_distance).
geometry_action_cluster(area_preserving_polygon_decomposition,
                        geometry_polygon_area_conservation).
geometry_action_cluster(decomposition_with_gap_or_overlap,
                        geometry_polygon_area_conservation).
geometry_action_cluster(parallelogram_area_base_height,
                        geometry_parallelogram_area_base_height).
geometry_action_cluster(slanted_side_as_parallelogram_height,
                        geometry_parallelogram_area_base_height).
geometry_action_cluster(triangle_area_half_base_height,
                        geometry_triangle_area_half_product).
geometry_action_cluster(omit_half_in_triangle_area,
                        geometry_triangle_area_half_product).
geometry_action_cluster(polyhedron_surface_area_from_net,
                        geometry_surface_area_as_all_face_coverage).
geometry_action_cluster(visible_faces_only_surface_area,
                        geometry_surface_area_as_all_face_coverage).
geometry_action_cluster(dimensional_measure_unit_coordination,
                        geometry_dimension_measure_unit_coordination).
geometry_action_cluster(linear_unit_for_area_or_volume,
                        geometry_dimension_measure_unit_coordination).
geometry_action_cluster(shape_classification_by_defining_attributes,
                        geometry_shape_attribute_classification).
geometry_action_cluster(orientation_bound_shape_classification,
                        geometry_shape_attribute_classification).
geometry_action_cluster(angle_turn_measurement,
                        geometry_angle_as_turn_measurement).
geometry_action_cluster(angle_as_ray_length,
                        geometry_angle_as_turn_measurement).
geometry_action_cluster(angle_additive_composition,
                        geometry_angle_additive_composition).
geometry_action_cluster(rigid_shape_composition,
                        geometry_shape_composition).
geometry_action_cluster(compare_solid_volume_by_cube_count,
                        geometry_solid_volume_comparison).
geometry_action_cluster(compare_solid_volume_by_visible_extent,
                        geometry_solid_volume_comparison).

geometry_action_vocabulary(rectangle_area_unit_iteration,
                           [rectangle, row, column, unit_square, square_unit,
                            tile_without_gaps_or_overlaps, area, composite_unit]).
geometry_action_vocabulary(area_as_perimeter_count,
                           [rectangle, area, perimeter, interior, boundary,
                            square_unit, unit_segment, container_schema]).
geometry_action_vocabulary(area_unit_covering,
                           [area, region, unit_square, cover, interior,
                            no_gap, no_overlap, square_unit, spatial_extent]).
geometry_action_vocabulary(count_overlapping_area_tiles,
                           [area, region, unit_square, overlap,
                            repeated_cell, double_count, square_unit]).
geometry_action_vocabulary(area_unit_scale_selection,
                           [area, referent, spatial_extent, square_unit,
                            centimeter, inch, foot, meter, unit_choice]).
geometry_action_vocabulary(choose_first_area_unit_without_scale,
                           [area, referent, spatial_extent, square_unit,
                            familiar_unit, uncoordinated_scale]).
geometry_action_vocabulary(rectangle_perimeter_boundary_traversal,
                           [rectangle, perimeter, boundary, side_length,
                            opposite_sides_equal, unit_segment,
                            complete_traversal, container_schema]).
geometry_action_vocabulary(perimeter_two_sides_only,
                           [rectangle, perimeter, boundary, side_length,
                            incomplete_traversal, unit_segment]).
geometry_action_vocabulary(perimeter_uses_area_formula,
                           [rectangle, perimeter, area, boundary, interior,
                            formula_substitution, container_schema]).
geometry_action_vocabulary(polygon_perimeter_boundary_accumulation,
                           [polygon, perimeter, boundary, side_length,
                            boundary_cycle, linear_unit, accumulation]).
geometry_action_vocabulary(omit_unlabeled_boundary_side,
                           [polygon, perimeter, boundary, side_length,
                            unlabeled_side, incomplete_cycle]).
geometry_action_vocabulary(symmetry_constrained_side_reconstruction,
                           [line_symmetry, reflection, side_orbit,
                            equal_length, perimeter, unknown_side,
                            inverse_operation]).
geometry_action_vocabulary(ignore_symmetry_multiplicity,
                           [line_symmetry, side_orbit, perimeter,
                            unknown_side, ignored_multiplicity]).
geometry_action_vocabulary(rectangle_perimeter_side_pair_search,
                           [rectangle, perimeter, side_length,
                            opposite_sides_equal, fixed_boundary,
                            exhaustive_search, area_varies]).
geometry_action_vocabulary(rectangle_missing_side_from_perimeter,
                           [rectangle, perimeter, known_side, unknown_side,
                            opposite_sides_equal, inverse_operation, boundary]).
geometry_action_vocabulary(rectangle_factor_pair_search,
                           [rectangle, area, whole_number_side_length, factor,
                            factor_pair, commutative_pair, exhaustive_search,
                            square_unit]).
geometry_action_vocabulary(rectangle_area_perimeter_constraint_search,
                           [rectangle, area, perimeter, side_length,
                            constraint, factor_pair, boundary,
                            intersection, design]).
geometry_action_vocabulary(ignore_perimeter_rectangle_constraint,
                           [rectangle, area, perimeter, constraint,
                            factor_pair, ignored_constraint, design]).
geometry_action_vocabulary(rectangle_missing_side_from_area,
                           [rectangle, area, known_side, unknown_side,
                            inverse_multiplication, exact_division,
                            factor, square_unit]).
geometry_action_vocabulary(subtract_side_from_area,
                           [rectangle, area, known_side, unknown_side,
                            subtraction, product_as_sum, operation_confusion]).
geometry_action_vocabulary(rectangular_prism_volume_layer_iteration,
                           [rectangular_prism, unit_cube, base, base_area,
                            layer, height, cubic_unit, volume]).
geometry_action_vocabulary(rectangular_prism_missing_dimension_from_volume,
                           [rectangular_prism, volume, base_area,
                            known_dimensions, unknown_dimension,
                            inverse_multiplication, exact_division, cubic_unit]).
geometry_action_vocabulary(divide_volume_by_one_dimension,
                           [rectangular_prism, volume, base_area,
                            known_dimensions, dropped_dimension,
                            partial_division, cubic_unit]).
geometry_action_vocabulary(composite_prism_volume_sum,
                           [composite_solid, rectangular_prism, unit_cube,
                            disjoint_decomposition, component_volume,
                            additive_volume, cubic_unit]).
geometry_action_vocabulary(sum_overlapping_prism_volumes,
                           [composite_solid, rectangular_prism, overlap,
                            double_count, component_volume, cubic_unit]).
geometry_action_vocabulary(ordered_pair_coordinate_plot,
                           [coordinate_plane, origin, horizontal_axis,
                            vertical_axis, ordered_pair, first_coordinate,
                            second_coordinate, directed_distance, point]).
geometry_action_vocabulary(axis_aligned_coordinate_distance,
                           [coordinate_plane, ordered_pair, horizontal_axis,
                            vertical_axis, aligned_points, directed_difference,
                            absolute_value, distance, length_unit]).
geometry_action_vocabulary(directed_difference_as_coordinate_distance,
                           [coordinate_plane, aligned_points,
                            directed_difference, absolute_value, distance,
                            negative_length]).
geometry_action_vocabulary(area_preserving_polygon_decomposition,
                           [polygon, area, decompose, compose, rearrange,
                            nonoverlap, no_gap, part, whole, conservation]).
geometry_action_vocabulary(decomposition_with_gap_or_overlap,
                           [polygon, area, decomposition, gap, overlap,
                            part, whole, conservation]).
geometry_action_vocabulary(parallelogram_area_base_height,
                           [parallelogram, base, perpendicular_height,
                            slanted_side, cut, translate, rectangle, area,
                            square_unit]).
geometry_action_vocabulary(slanted_side_as_parallelogram_height,
                           [parallelogram, base, height, slanted_side,
                            perpendicular, area]).
geometry_action_vocabulary(triangle_area_half_base_height,
                           [triangle, base, perpendicular_height, matching_copy,
                            parallelogram, half, area, square_unit]).
geometry_action_vocabulary(omit_half_in_triangle_area,
                           [triangle, base, height, parallelogram, half, area,
                            omitted_halving]).
geometry_action_vocabulary(polyhedron_surface_area_from_net,
                           [polyhedron, face, net, unfold, surface_area,
                            square_unit, prism, pyramid, all_faces]).
geometry_action_vocabulary(visible_faces_only_surface_area,
                           [polyhedron, face, net, visible_face, hidden_face,
                            surface_area, incomplete_coverage]).
geometry_action_vocabulary(dimensional_measure_unit_coordination,
                           [length, area, volume, dimension, linear_unit,
                            square_unit, cubic_unit, exponent, notation]).
geometry_action_vocabulary(linear_unit_for_area_or_volume,
                           [area, volume, dimension, linear_unit, square_unit,
                            cubic_unit, exponent, notation]).
geometry_action_vocabulary(shape_classification_by_defining_attributes,
                           [shape, defining_attribute, side, vertex, angle,
                            parallel, equal_length, orientation, rotation,
                            category, hierarchy]).
geometry_action_vocabulary(orientation_bound_shape_classification,
                           [shape, defining_attribute, prototype, orientation,
                            rotation, category]).
geometry_action_vocabulary(angle_turn_measurement,
                           [angle, vertex, initial_ray, terminal_ray, turn,
                            degree, protractor, rotation]).
geometry_action_vocabulary(angle_as_ray_length,
                           [angle, ray_length, visual_extent, bigger, degree,
                            turn]).
geometry_action_vocabulary(angle_additive_composition,
                           [angle, adjacent_angles, composition, decomposition,
                            part, whole, unknown_angle, addition, subtraction]).
geometry_action_vocabulary(rigid_shape_composition,
                           [shape, part, whole, compose, decompose, rigid_motion,
                            rotate, translate, fit, boundary, no_gap, no_overlap]).
geometry_action_vocabulary(compare_solid_volume_by_cube_count,
                           [solid_object, volume, unit_cube, cube_count,
                            composition, conservation, visual_extent]).
geometry_action_vocabulary(compare_solid_volume_by_visible_extent,
                           [solid_object, volume, visual_extent, height,
                            spread, cube_count_ignored]).

productive_geometry_deformation(
    rectangle_area_unit_iteration,
    area_as_perimeter_count,
    area_as_perimeter).
productive_geometry_deformation(
    rectangle_perimeter_boundary_traversal,
    perimeter_two_sides_only,
    perimeter_two_sides).
productive_geometry_deformation(
    rectangle_perimeter_boundary_traversal,
    perimeter_uses_area_formula,
    perimeter_uses_area_formula).
productive_geometry_deformation(
    polygon_perimeter_boundary_accumulation,
    omit_unlabeled_boundary_side,
    incomplete_polygon_boundary_cycle).
productive_geometry_deformation(
    symmetry_constrained_side_reconstruction,
    ignore_symmetry_multiplicity,
    symmetry_side_orbit_multiplicity_ignored).
productive_geometry_deformation(
    shape_classification_by_defining_attributes,
    orientation_bound_shape_classification,
    shape_classification_bound_to_prototype_orientation).
productive_geometry_deformation(
    angle_turn_measurement,
    angle_as_ray_length,
    angle_confused_with_ray_length).
productive_geometry_deformation(
    axis_aligned_coordinate_distance,
    directed_difference_as_coordinate_distance,
    directed_change_reported_as_distance).
productive_geometry_deformation(
    area_preserving_polygon_decomposition,
    decomposition_with_gap_or_overlap,
    polygon_decomposition_gap_or_overlap).
productive_geometry_deformation(
    composite_prism_volume_sum,
    sum_overlapping_prism_volumes,
    overlapping_component_volume_double_count).
productive_geometry_deformation(
    rectangle_missing_side_from_area,
    subtract_side_from_area,
    area_product_treated_as_additive_total).
productive_geometry_deformation(
    area_unit_covering,
    count_overlapping_area_tiles,
    overlapping_area_tiles_double_counted).
productive_geometry_deformation(
    area_unit_scale_selection,
    choose_first_area_unit_without_scale,
    area_unit_selected_without_extent_coordination).
productive_geometry_deformation(
    rectangle_area_perimeter_constraint_search,
    ignore_perimeter_rectangle_constraint,
    perimeter_constraint_ignored_in_rectangle_design).
productive_geometry_deformation(
    rectangular_prism_missing_dimension_from_volume,
    divide_volume_by_one_dimension,
    one_base_dimension_omitted_from_volume_inverse).
productive_geometry_deformation(
    parallelogram_area_base_height,
    slanted_side_as_parallelogram_height,
    slanted_side_used_as_height).
productive_geometry_deformation(
    triangle_area_half_base_height,
    omit_half_in_triangle_area,
    triangle_area_omits_half).
productive_geometry_deformation(
    polyhedron_surface_area_from_net,
    visible_faces_only_surface_area,
    hidden_faces_omitted_from_surface_area).
productive_geometry_deformation(
    dimensional_measure_unit_coordination,
    linear_unit_for_area_or_volume,
    dimension_unit_exponent_confusion).
productive_geometry_deformation(
    compare_solid_volume_by_cube_count,
    compare_solid_volume_by_visible_extent,
    solid_volume_compared_by_visible_extent).

geometry_action_misconception_hook(action_outcome(Kind, Fields),
                                   geometry_productive_monitoring(Kind), Hook) :-
    member(classification(productive), Fields),
    member(vocabulary(Vocabulary), Fields),
    Hook = action_misconception_hook(
               [ productive_geometry_action(Kind),
                 vocabulary(Vocabulary),
                 monitoring_focus(preserve_spatial_unit_and_action_order(Kind)),
                 evidence(Fields)
               ]).
geometry_action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
    member(classification(deformation), Fields),
    member(deformation_of(Productive), Fields),
    member(violated_invariant(Invariant), Fields),
    Hook = action_misconception_hook(
               [ misconception(Family),
                 deformed_action(Kind),
                 productive_action(Productive),
                 violated_invariant(Invariant),
                 repair(recover_productive_action(Productive)),
                 evidence(Fields)
               ]).


positive_integer(Value) :- integer(Value), Value > 0.

valid_side_lengths([Side|Sides]) :-
    positive_number(Side),
    maplist(positive_number, Sides).

positive_number(Value) :- number(Value), Value > 0.

geometry_relation(A, B, less) :- A < B, !.
geometry_relation(A, B, more) :- A > B, !.
geometry_relation(_, _, equal).

relation_validity(Expected, Expected, accidentally_correct) :- !.
relation_validity(_, _, incorrect).

select_area_unit(ExtentClass, Candidates, Unit) :-
    valid_extent_class(ExtentClass),
    is_list(Candidates),
    Candidates = [_, _|_],
    maplist(valid_area_unit_candidate, Candidates),
    findall(CandidateUnit,
            member(unit(CandidateUnit, ExtentClass), Candidates),
            [Unit]).

valid_area_unit_candidate(unit(Unit, ExtentClass)) :-
    atom(Unit),
    valid_extent_class(ExtentClass).

valid_extent_class(very_small).
valid_extent_class(small).
valid_extent_class(medium).
valid_extent_class(large).

solve_symmetry_orbits(Orbits, Perimeter, Name, SideLength,
                      KnownContribution, Multiplicity) :-
    is_list(Orbits),
    Orbits = [_, _|_],
    positive_integer(Perimeter),
    select(orbit(Multiplicity, unknown(Name)), Orbits, KnownOrbits),
    atom(Name),
    integer(Multiplicity), Multiplicity > 0,
    maplist(valid_known_orbit, KnownOrbits),
    findall(Contribution,
            ( member(orbit(Copies, known(Length)), KnownOrbits),
              Contribution is Copies * Length ),
            Contributions),
    sum_list(Contributions, KnownContribution),
    Remaining is Perimeter - KnownContribution,
    Remaining > 0,
    0 is Remaining mod Multiplicity,
    SideLength is Remaining // Multiplicity.

valid_known_orbit(orbit(Copies, known(Length))) :-
    integer(Copies), Copies > 0,
    positive_integer(Length).

flatten_orbit_multiplicities(Orbits, FlatKnown, Name) :-
    select(orbit(_Multiplicity, unknown(Name)), Orbits, KnownOrbits),
    findall(Length,
            member(orbit(_Copies, known(Length)), KnownOrbits),
            Lengths),
    sum_list(Lengths, FlatKnown).

grounded_product(A, B, Product) :-
    integer_to_recollection(A, RA),
    integer_to_recollection(B, RB),
    multiply_grounded(RA, RB, RP),
    recollection_to_integer(RP, Product).

grounded_sum(A, B, Sum) :-
    integer_to_recollection(A, RA),
    integer_to_recollection(B, RB),
    add_grounded(RA, RB, RS),
    recollection_to_integer(RS, Sum).

bounded_rectangle_dimension(Value) :-
    integer(Value),
    between(1, 100, Value).

rectangle_perimeter_value(Length, Width, Perimeter) :-
    grounded_sum(Length, Width, HalfPerimeter),
    grounded_sum(HalfPerimeter, HalfPerimeter, Perimeter).

axis_aligned_difference(X, Y1, X, Y2, vertical, Difference) :-
    Y2 =\= Y1,
    Difference is Y2 - Y1,
    !.
axis_aligned_difference(X1, Y, X2, Y, horizontal, Difference) :-
    X2 =\= X1,
    Difference is X2 - X1.

polygon_double_area(Vertices, Area2) :-
    Vertices = [_, _, _|_],
    maplist(integer_lattice_point, Vertices),
    Vertices = [First|_],
    append(Vertices, [First], Closed),
    shoelace_sum(Closed, SignedArea2),
    Area2 is abs(SignedArea2),
    Area2 > 0.

integer_lattice_point(X-Y) :- integer(X), integer(Y).

shoelace_sum([_], 0).
shoelace_sum([X1-Y1, X2-Y2|Rest], Sum) :-
    shoelace_sum([X2-Y2|Rest], Tail),
    Sum is X1 * Y2 - Y1 * X2 + Tail.

area_value(DoubleArea, Area) :- area_value(DoubleArea, 2, Area).

area_value(Numerator, Denominator, Area) :-
    GCD is gcd(abs(Numerator), Denominator),
    ReducedNumerator is Numerator // GCD,
    ReducedDenominator is Denominator // GCD,
    ( ReducedDenominator =:= 1
    -> Area = ReducedNumerator
    ;  Area = rational(ReducedNumerator, ReducedDenominator)
    ).

polygon_scenes([], []).
polygon_scenes([Vertices|Polygons], [Scene|Scenes]) :-
    geoboard_render_json(stretch_polygon(Vertices), Scene),
    successful_scene(Scene),
    polygon_scenes(Polygons, Scenes).

valid_parallelogram_dimensions(Base, Height, SlantedSide, Offset) :-
    positive_integer(Base),
    positive_integer(Height),
    positive_integer(SlantedSide),
    integer(Offset), Offset >= 0,
    SlantedSquared is SlantedSide * SlantedSide,
    ComponentsSquared is Height * Height + Offset * Offset,
    SlantedSquared =:= ComponentsSquared.

parallelogram_scene(Base, Height, Offset, Scene) :-
    FarX is Base + Offset,
    Vertices = [0-0, Base-0, FarX-Height, Offset-Height],
    geoboard_render_json(stretch_polygon(Vertices), Scene),
    successful_scene(Scene).

triangle_scene(Base, Height, Scene) :-
    Vertices = [0-0, Base-0, 0-Height],
    geoboard_render_json(stretch_polygon(Vertices), Scene),
    successful_scene(Scene).

prism_components([Prism|Prisms], [Volume|Volumes], [Scene|Scenes]) :-
    prism_component(Prism, Volume, Scene),
    prism_components_(Prisms, Volumes, Scenes).

prism_components_([], [], []).
prism_components_([Prism|Prisms], [Volume|Volumes], [Scene|Scenes]) :-
    prism_component(Prism, Volume, Scene),
    prism_components_(Prisms, Volumes, Scenes).

prism_component(prism(Length, Width, Height), Volume, Scene) :-
    positive_integer(Length), positive_integer(Width), positive_integer(Height),
    grounded_product(Length, Width, BaseArea),
    grounded_product(BaseArea, Height, Volume),
    solid_net_render_json(unit_cube_stack(Length, Width, Height), Scene),
    successful_scene(Scene).

valid_face_areas(Solid, FaceAreas) :-
    solid_face_count(Solid, FaceCount),
    length(FaceAreas, FaceCount),
    FaceAreas = [_|_],
    maplist(positive_integer, FaceAreas).

solid_face_count(cube, 6).
solid_face_count(rectangular_prism, 6).
solid_face_count(triangular_prism, 5).
solid_face_count(square_pyramid, 5).

dimension_power(one_dimensional, 1, length).
dimension_power(two_dimensional, 2, area).
dimension_power(three_dimensional, 3, volume).

rectangle_geoboard_scene(Length, Width, Scene) :-
    geoboard_render_json(
        stretch_polygon([0-0, Length-0, Length-Width, 0-Width]), Scene),
    successful_scene(Scene).

rectangle_perimeter_pairs(Perimeter, Pairs) :-
    HalfPerimeter is Perimeter // 2,
    MaxLength is HalfPerimeter - 1,
    findall(Length-Width,
            ( between(1, MaxLength, Length),
              Width is HalfPerimeter - Length,
              Length =< Width,
              bounded_rectangle_dimension(Length),
              bounded_rectangle_dimension(Width)
            ),
            Pairs).

perimeter_pair_scenes([], []).
perimeter_pair_scenes([Length-Width|Pairs], [Scene|Scenes]) :-
    rectangle_geoboard_scene(Length, Width, Scene),
    perimeter_pair_scenes(Pairs, Scenes).

perimeter_scope_result(one, Perimeter, Pairs,
                       construction_choices(perimeter(Perimeter), Pairs)).
perimeter_scope_result(all, Perimeter, Pairs,
                       all_rectangle_side_pairs(perimeter(Perimeter), Pairs)).

rectangle_factor_pairs(Area, Pairs) :-
    findall(Length-Width,
            ( between(1, Area, Length),
              0 is Area mod Length,
              Width is Area // Length,
              Length =< Width
            ),
            Pairs).

include_pairs_with_perimeter(Pairs, Perimeter, Matching) :-
    findall(Length-Width,
            ( member(Length-Width, Pairs),
              rectangle_perimeter_value(Length, Width, Perimeter)
            ),
            Matching).

pair_scenes([], []).
pair_scenes([Length-Width|Pairs], [Scene|Scenes]) :-
    area_render_json(array_multiplication(Length, Width), Scene),
    successful_scene(Scene),
    pair_scenes(Pairs, Scenes).

scope_result(one, Pairs, construction_choices(Pairs)).
scope_result(all, Pairs, all_factor_pair_rectangles(Pairs)).

successful_scene(Scene) :-
    is_dict(Scene),
    \+ get_dict(error, Scene, _),
    get_dict(frames, Scene, Frames),
    Frames = [_|_].

valid_points([Point|Rest]) :-
    valid_point(Point),
    maplist(valid_point, Rest).

valid_point(point(X, Y)) :- number(X), number(Y).
valid_point(X-Y) :- number(X), number(Y).

valid_quarter_turns(Turns) :- integer(Turns), between(0, 3, Turns).

attributes_include(Observed, Required) :-
    is_list(Observed),
    forall(member(Attribute, Required), memberchk(Attribute, Observed)).

shape_profile(circle, [closed_curve, no_straight_sides], []).
shape_profile(triangle, [straight_sides(3), vertices(3)], []).
shape_profile(quadrilateral, [straight_sides(4), vertices(4)], []).
shape_profile(pentagon, [straight_sides(5), vertices(5)], []).
shape_profile(hexagon, [straight_sides(6), vertices(6)], []).
shape_profile(trapezoid,
              [straight_sides(4), vertices(4), parallel_side_pairs(at_least(1))],
              [quadrilateral]).
shape_profile(parallelogram,
              [straight_sides(4), vertices(4), parallel_side_pairs(2)],
              [trapezoid, quadrilateral]).
shape_profile(rectangle,
              [straight_sides(4), vertices(4), right_angles(4)],
              [parallelogram, trapezoid, quadrilateral]).
shape_profile(rhombus,
              [straight_sides(4), vertices(4), equal_sides(4)],
              [parallelogram, trapezoid, quadrilateral]).
shape_profile(square,
              [straight_sides(4), vertices(4), right_angles(4), equal_sides(4)],
              [rectangle, rhombus, parallelogram, trapezoid, quadrilateral]).

valid_angle_measure(Degrees) :-
    integer(Degrees),
    between(1, 360, Degrees).

valid_angle_parts([Part|Parts]) :-
    valid_angle_measure(Part),
    maplist(valid_angle_measure, Parts).
