/** <module> Typed bridge from IM lesson monitoring to learner action paths
 *
 * A lesson attachment, a registered action kind, and an executable task are
 * different claims. This module keeps them separate while connecting the three
 * existing systems:
 *
 *   lesson_monitoring -> action_automata_registry -> learner path machinery
 *
 * Contracts can therefore report useful source material without pretending a
 * lesson is runnable. Concrete task instances currently route addition through
 * primitive-path synthesis and unit fractions through recursive unit actions.
 */

:- module(activity_contract,
          [ lesson_activity_contract/2,
            activity_task_path/3,
            lesson_capability_row/2,
            lesson_task_instance/3,
            lesson_traversal_row/2,
            curriculum_capability_audit/2,
            curriculum_capability_graph/2,
            curriculum_traversal_audit/2,
            reset_curriculum_capability_cache/0
          ]).

:- use_module(lessons('im/lesson_monitoring'),
              [ im_lesson/6,
                lesson_standard/4,
                lesson_strategy/4,
                lesson_misconception/4,
                vision_lesson_strategy/4
              ]).
:- use_module(math(action_automata_registry),
              [ action_automaton_cluster/3,
                action_automaton_signature/4,
                action_automaton_pair/4,
                run_action_automaton/6
              ]).
:- use_module(math(recursive_unit_actions),
              [ fraction_unit_plan/3,
                run_unit_plan/3,
                plan_dict/2,
                value_numeral/3,
                integer_numeral/3,
                numeral_text/2,
                numeral_action_witness/3
              ]).
:- use_module(math(decimal_action_pairs), [run_decimal_action/5]).
:- use_module(math(integer_action_pairs), [run_integer_action/5]).
:- use_module(math(ratio_action_pairs), [run_ratio_scale/6]).
:- use_module(math(algebraic_action_pairs), [run_algebraic_action/5]).
:- use_module(math(diagnostic_validation_action_pairs),
              [run_diagnostic_action/5]).
:- use_module(math(geometry_action_pairs), [run_geometry_action/5]).
:- use_module(lessons('im/generated/compiled_task_instances'),
              [compiled_lesson_task_instance/3]).
:- use_module(render(area_model_scene), [area_render_json/2]).
:- use_module(render(solid_net_scene), [solid_net_render_json/2]).
:- use_module(render(coordinate_plane_scene),
              [coordinate_plane_render_json/2]).
:- use_module(formalization(grounded_arithmetic),
              [ integer_to_recollection/2,
                recollection_to_integer/2,
                add_grounded/3,
                multiply_grounded/3
              ]).
:- use_module(strategy_synthesis, []).
:- use_module(peano_utils, [int_to_peano/2]).
:- use_module(library(lists)).

:- dynamic
       cached_curriculum_capability_audit/2,
       cached_curriculum_capability_graph/2,
       cached_curriculum_traversal_audit/2,
       lesson_task_instance/3.

:- multifile lesson_task_instance/3.


%!  lesson_activity_contract(+LessonCode, -Contract) is semidet.
lesson_activity_contract(Code, Contract) :-
    im_lesson(Code, ConceptId, Title, grade(Grade), unit(Unit), lesson(LessonNo)),
    !,
    findall(_{framework: Framework, code: StandardCode, statement: Statement},
            lesson_standard(Code, Framework, StandardCode, Statement),
            Standards0),
    sort(Standards0, Standards),
    findall(Obligation,
            strategy_obligation(Code, Obligation),
            StrategyObligations0),
    sort(StrategyObligations0, StrategyObligations),
    findall(Obligation,
            misconception_obligation(Code, Obligation),
            MisconceptionObligations0),
    sort(MisconceptionObligations0, MisconceptionObligations),
    contract_status(StrategyObligations, Status),
    Contract = activity_contract{
        lesson: Code,
        concept_id: ConceptId,
        title: Title,
        grade: Grade,
        unit: Unit,
        lesson_number: LessonNo,
        standards: Standards,
        strategy_obligations: StrategyObligations,
        misconception_obligations: MisconceptionObligations,
        status: Status,
        execution_status: awaiting_task_instance
    }.

strategy_obligation(Code, Obligation) :-
    lesson_strategy(Code, Operation, Kind, Info),
    obligation_provenance(Info, Provenance),
    (   action_automaton_cluster(Operation, Kind, Cluster)
    ->  RegistryStatus = registered_action,
        RegistryCluster = Cluster,
        action_role(Operation, Kind, Role, Relation),
        action_signature(Operation, Kind, Signature)
    ;   RegistryStatus = missing_action_automaton,
        RegistryCluster = none,
        Role = unresolved,
        Relation = none,
        Signature = none
    ),
    Obligation = _{ operation: Operation,
                    kind: Kind,
                    role: Role,
                    relation: Relation,
                    invocation_signature: Signature,
                    registry_status: RegistryStatus,
                    registry_cluster: RegistryCluster,
                    provenance: Provenance }.
% Vision-attested demands (vision_lesson_strategy/4, generated
% grade_*_vision.pl) license execution without entering the monitoring-chart
% join; the guard keeps a chart-carried (operation, kind) from appearing twice.
strategy_obligation(Code, Obligation) :-
    vision_lesson_strategy(Code, Operation, Kind, _Info),
    \+ lesson_strategy(Code, Operation, Kind, _),
    (   action_automaton_cluster(Operation, Kind, Cluster)
    ->  RegistryStatus = registered_action,
        RegistryCluster = Cluster,
        action_role(Operation, Kind, Role, Relation),
        action_signature(Operation, Kind, Signature)
    ;   RegistryStatus = missing_action_automaton,
        RegistryCluster = none,
        Role = unresolved,
        Relation = none,
        Signature = none
    ),
    Obligation = _{ operation: Operation,
                    kind: Kind,
                    role: Role,
                    relation: Relation,
                    invocation_signature: Signature,
                    registry_status: RegistryStatus,
                    registry_cluster: RegistryCluster,
                    provenance: vision_attested }.

action_role(Operation, Kind, deformation,
            deformation_of(Productive, Family)) :-
    action_automaton_pair(Operation, Productive, Kind, Family),
    !.
action_role(Operation, Kind, productive,
            productive_with(Deformation, Family)) :-
    action_automaton_pair(Operation, Kind, Deformation, Family),
    !.
action_role(_Operation, _Kind, productive_unpaired, none).

misconception_obligation(Code, Obligation) :-
    lesson_misconception(Code, Operation, Kind, Info),
    obligation_provenance(Info, Provenance),
    (   action_automaton_pair(Operation, Productive, Kind, Family)
    ->  RegistryStatus = registered_deformation,
        Relation = deformation_of(Productive, Family)
    ;   RegistryStatus = registry_relation_missing,
        Relation = none
    ),
    Obligation = _{ operation: Operation,
                    kind: Kind,
                    registry_status: RegistryStatus,
                    relation: Relation,
                    provenance: Provenance }.

obligation_provenance(Info, Provenance) :-
    (   memberchk(provenance(Provenance0), Info)
    ->  Provenance = Provenance0
    ;   Provenance = unspecified
    ).

contract_status([], unattached(no_strategy_obligations)) :- !.
contract_status(Obligations, registered_actions) :-
    \+ ( member(O, Obligations),
         O.registry_status \== registered_action ),
    !.
contract_status(Obligations, partial(missing_action_automata(Missing))) :-
    findall(Operation-Kind,
            ( member(O, Obligations),
              O.registry_status == missing_action_automaton,
              Operation = O.operation,
              Kind = O.kind ),
            Missing0),
    sort(Missing0, Missing).


%!  activity_task_path(+LessonCode, +Task, -Outcome) is det.
%
%   Compile a concrete task only when the lesson contract licenses its operation
%   and a live executor exists. Missing concepts return structured boundaries.
activity_task_path(Code, Task, Outcome) :-
    (   lesson_activity_contract(Code, Contract)
    ->  task_descriptor(Task, Operation, Requirements),
        (   task_license(Contract, Task, Operation, _License)
        ->  execute_task_path(Task, Contract, Requirements, Outcome)
        ;   Outcome = unsupported{
                lesson: Code,
                task: Task,
                operation: Operation,
                reason: lesson_operation_not_wired,
                constituent_requirements: Requirements,
                contract_status: Contract.status
            }
        )
    ;   Outcome = unsupported{
            lesson: Code,
            task: Task,
            reason: unknown_lesson
        }
    ).

contract_has_operation(Contract, Operation) :-
    member(Obligation, Contract.strategy_obligations),
    Obligation.operation == Operation,
    Obligation.registry_status == registered_action,
    !.

task_license(Contract, _Task, Operation, registered_action) :-
    contract_has_operation(Contract, Operation),
    !.
task_license(Contract, Task, Operation, supplied_definition) :-
    definition_task_keyword(Task, Operation, Keyword),
    contract_mentions(Contract, Keyword).

contract_mentions(Contract, Keyword) :-
    member(Standard, Contract.standards),
    get_dict(statement, Standard, Statement),
    term_string(Statement, Text),
    sub_string(Text, _, _, _, Keyword),
    !.

task_descriptor(add(A, B), addition,
                [counted_quantities, successor_iteration, composite_unit_regrouping]) :-
    integer(A), A >= 0, integer(B), B >= 0,
    !.
task_descriptor(subtract(A, B), subtraction,
                [minuend_quantity, remove_subtrahend_units,
                 preserve_running_difference]) :-
    integer(A), integer(B), A >= B, B >= 0,
    !.
task_descriptor(multiply(N, S), multiplication,
                [equal_groups, coordinate_group_and_item_counts,
                 iterate_composite_unit]) :-
    integer(N), N > 0, integer(S), S > 0,
    !.
task_descriptor(divide(Total, Divisor), division,
                [total_quantity, divisor_as_group_size,
                 measure_composite_units, preserve_remainder]) :-
    integer(Total), Total >= 0, integer(Divisor), Divisor > 0,
    !.
task_descriptor(unit_fraction(N, D), fraction,
                [referent_whole, partition_equal_parts, iterate_unit_fraction]) :-
    integer(N), N > 0, integer(D), D > 0,
    !.
task_descriptor(iterate_improper_fraction(Numerator, Denominator), fraction,
                [referent_whole, unit_fraction_of_denominator,
                 iterate_units_beyond_one_whole]) :-
    integer(Numerator), integer(Denominator),
    Denominator > 0, Numerator > Denominator,
    !.
task_descriptor(decimal_value(Numeral, Scale), decimal,
                [integer_numeral, power_of_ten_scale,
                 negative_place_partitioning, positional_inscription]) :-
    integer(Numeral), Numeral >= 0,
    integer(Scale), Scale > 1,
    !.
task_descriptor(decimal_multiply(N1, S1, N2, S2), decimal,
                [operand_place_counts, whole_number_multiplication,
                 sum_fractional_places, positional_inscription]) :-
    maplist(nonnegative_integer, [N1, N2]),
    maplist(scale_integer, [S1, S2]),
    !.
task_descriptor(decimal_compare(N1, S1, N2, S2), decimal,
                [two_decimal_numerals, operand_scales,
                 common_decimal_unit, align_place_units,
                 compare_magnitudes]) :-
    maplist(nonnegative_integer, [N1, N2]),
    maplist(scale_integer, [S1, S2]),
    !.
task_descriptor(decimal_add(N1, S1, N2, S2), decimal,
                [two_decimal_addends, operand_scales,
                 common_decimal_unit, grounded_integer_addition,
                 positional_reinscription]) :-
    maplist(nonnegative_integer, [N1, N2]),
    maplist(scale_integer, [S1, S2]),
    !.
task_descriptor(decimal_subtract(N1, S1, N2, S2), decimal,
                [decimal_minuend_and_subtrahend, operand_scales,
                 common_decimal_unit, grounded_integer_subtraction,
                 positional_reinscription]) :-
    maplist(nonnegative_integer, [N1, N2]),
    maplist(scale_integer, [S1, S2]),
    !.
task_descriptor(regroup_decimal_units(Count, FromScale, ToScale), decimal,
                [decimal_unit_count, source_place_unit, target_place_unit,
                 nested_base_ten_relation, iterate_finer_unit,
                 preserve_quantity]) :-
    integer(Count), Count >= 0,
    maplist(scale_integer, [FromScale, ToScale]),
    ToScale > FromScale,
    !.
task_descriptor(signed_add(A, B), integer,
                [directed_magnitude, sign_relation,
                 same_sign_combination_or_opposite_sign_cancellation]) :-
    integer(A), integer(B),
    !.
task_descriptor(scale_ratio(A, B, Factor), ratio,
                [ratio_pair_referent, multiplicative_scale_factor,
                 scale_both_terms, preserve_unit_ratio]) :-
    integer(A), A > 0, integer(B), B > 0,
    integer(Factor), Factor > 1,
    !.
task_descriptor(evaluate_expression(Expression, Assignment), algebraic,
                [expression_tree, variable_assignment,
                 substitute_then_execute_grounded_operations]) :-
    is_list(Assignment),
    nonvar(Expression),
    !.
task_descriptor(linear_pattern(First, Change, Row, Context), algebraic,
                [initial_value, constant_change, row_index,
                 accumulate_change_from_first_row, preserve_context]) :-
    maplist(positive_integer, [First, Change, Row]),
    nonvar(Context),
    !.
task_descriptor(solve_linear(A, B, C), algebraic,
                [read_unknown_as_quantity, preserve_equality,
                 subtract_same_quantity_from_both_sides,
                 partition_both_sides_equally]) :-
    integer(A), A > 0, integer(B), B >= 0, integer(C), C >= B,
    !.
task_descriptor(validate_quotient(Proposed, Dividend, Divisor), diagnostic,
                [proposed_quotient, inverse_multiplication,
                 compare_product_with_dividend]) :-
    maplist(positive_integer, [Proposed, Dividend, Divisor]),
    !.
task_descriptor(rectangle_area(Rows, Columns), geometry,
                [length_units, width_units, coordinate_composite_unit,
                 iterate_rows_and_columns, count_square_units]) :-
    maplist(positive_integer, [Rows, Columns]),
    !.
task_descriptor(compare_rectangle_areas(L1, W1, L2, W2, Unit), geometry,
                [two_rectangles, side_lengths, common_linear_unit,
                 coordinate_square_units, compare_areas]) :-
    maplist(positive_integer, [L1, W1, L2, W2]),
    atom(Unit),
    !.
task_descriptor(rectangle_missing_side_from_area(Area, KnownSide, Unit),
                geometry,
                [rectangle_area, known_side_length, unknown_side_length,
                 inverse_multiplication, exact_division,
                 preserve_linear_and_square_units]) :-
    maplist(positive_integer, [Area, KnownSide]),
    atom(Unit),
    !.
task_descriptor(select_area_unit(ExtentClass, Candidates), geometry,
                [area_referent_extent, candidate_square_units,
                 compare_unit_scales, preserve_square_dimension]) :-
    atom(ExtentClass), is_list(Candidates), Candidates = [_, _|_],
    !.
task_descriptor(rectangle_perimeter(Length, Width, Unit), geometry,
                [rectangle_dimensions, measurement_unit,
                 traverse_complete_boundary, preserve_linear_unit]) :-
    maplist(positive_integer, [Length, Width]),
    atom(Unit),
    !.
task_descriptor(polygon_perimeter(SideLengths, Unit), geometry,
                [ordered_side_lengths, closed_boundary,
                 traverse_each_side_once, preserve_linear_unit]) :-
    is_list(SideLengths), SideLengths = [_, _, _|_],
    forall(member(Side, SideLengths), (number(Side), Side > 0)),
    atom(Unit),
    !.
task_descriptor(symmetry_missing_side(Orbits, Perimeter, Unit), geometry,
                [side_equivalence_orbits, total_perimeter,
                 reflection_preserves_length, inverse_boundary_reasoning,
                 preserve_linear_unit]) :-
    is_list(Orbits), Orbits = [_, _|_],
    positive_integer(Perimeter), atom(Unit),
    !.
task_descriptor(rectangle_side_lengths_for_perimeter(Perimeter, Unit), geometry,
                [target_perimeter, measurement_unit,
                 opposite_sides_equal, exhaustive_side_pair_search,
                 preserve_boundary_total]) :-
    integer(Perimeter), Perimeter >= 4, 0 is Perimeter mod 2,
    atom(Unit),
    !.
task_descriptor(construct_rectangle_with_perimeter(Perimeter, Unit), geometry,
                [target_perimeter, measurement_unit,
                 choose_positive_side_pair, preserve_boundary_total]) :-
    integer(Perimeter), Perimeter >= 4, 0 is Perimeter mod 2,
    atom(Unit),
    !.
task_descriptor(rectangle_missing_side_from_perimeter(Perimeter, Known, Unit),
                geometry,
                [target_perimeter, known_side_length, unknown_side_length,
                 opposite_sides_equal, inverse_boundary_reasoning,
                 preserve_linear_unit]) :-
    integer(Perimeter), Perimeter >= 4, 0 is Perimeter mod 2,
    positive_integer(Known), atom(Unit),
    !.
task_descriptor(construct_rectangle_with_area(Area), geometry,
                [target_area, whole_number_side_lengths,
                 factor_pair_search, preserve_square_unit]) :-
    positive_integer(Area),
    !.
task_descriptor(rectangle_side_lengths_for_area(Area), geometry,
                [target_area, whole_number_side_lengths,
                 exhaustive_factor_pair_search, preserve_square_unit]) :-
    positive_integer(Area),
    !.
task_descriptor(unit_cube_volume(Length, Width, Height), geometry,
                [length_units, width_units, height_units,
                 coordinate_three_dimensions, count_cubic_units]) :-
    maplist(positive_integer, [Length, Width, Height]),
    !.
task_descriptor(unit_cube_volume(Length, Width, Height, Unit), geometry,
                [length_units, width_units, height_units, measurement_unit,
                 coordinate_three_dimensions, count_cubic_units,
                 preserve_cubic_unit]) :-
    maplist(positive_integer, [Length, Width, Height]),
    atom(Unit),
    !.
task_descriptor(compare_solid_volumes(CountA, CountB, ExtentA, ExtentB),
                geometry,
                [two_solid_objects, unit_cube_counts, conserved_volume,
                 ignore_arrangement_extent, compare_cubic_units]) :-
    maplist(positive_integer, [CountA, CountB]),
    maplist(number, [ExtentA, ExtentB]),
    ExtentA > 0, ExtentB > 0,
    !.
task_descriptor(plot_points(Points), geometry,
                [coordinate_axes, ordered_pairs, directed_distance_from_origin,
                 preserve_coordinate_signs]) :-
    valid_points(Points),
    !.
task_descriptor(solid_net(Solid), geometry,
                [solid_referent, face_shapes, adjacency, fold_creases,
                 preserve_face_count_and_foldability]) :-
    atom(Solid),
    !.
task_descriptor(classify_shape(Shape, Attributes, QuarterTurns), geometry,
                [observed_attributes, defining_attributes,
                 preserve_name_under_rotation, retain_shape_hierarchy]) :-
    atom(Shape), is_list(Attributes), integer(QuarterTurns),
    !.
task_descriptor(angle_measure(Degrees), geometry,
                [fixed_vertex, initial_ray, amount_of_turn,
                 one_degree_unit, terminal_ray]) :-
    integer(Degrees), Degrees >= 1, Degrees =< 360,
    !.
task_descriptor(compose_angles(Parts, Whole), geometry,
                [shared_vertex, adjacent_angle_parts,
                 preserve_each_turn, sum_parts_to_whole]) :-
    is_list(Parts), Parts = [_|_], integer(Whole),
    !.
task_descriptor(compose_rigid_shapes(Columns, Rows, Pieces), geometry,
                [bounded_region, rigid_parts, rotation, translation,
                 cover_without_gaps_or_overlaps]) :-
    maplist(positive_integer, [Columns, Rows]),
    is_list(Pieces), Pieces = [_|_],
    !.
task_descriptor(measure_length(IntervalCount, Subdivisions, Unit), measurement,
                [length_attribute, fixed_unit, equal_subdivision,
                 iterate_intervals_from_zero, preserve_unit_name]) :-
    maplist(positive_integer, [IntervalCount, Subdivisions]),
    atom(Unit),
    !.
task_descriptor(read_liquid_volume(IntervalCount, Subdivisions, Unit), measurement,
                [liquid_volume_attribute, fixed_volume_unit, equal_scale_subdivision,
                 locate_fill_level_from_zero, preserve_volume_unit_name]) :-
    maplist(positive_integer, [IntervalCount, Subdivisions]),
    atom(Unit),
    !.
task_descriptor(convert_measurement(Count, FromUnit, ToUnit, Factor),
                measurement,
                [measured_quantity, source_unit, target_unit,
                 integer_conversion_factor, iterate_composite_unit,
                 preserve_quantity]) :-
    integer(Count), Count >= 0,
    atom(FromUnit), atom(ToUnit), FromUnit \== ToUnit,
    integer(Factor), Factor > 1,
    !.
task_descriptor(measured_quantity_change(Operation, A, B, Unit), measurement,
                [two_measured_quantities, common_measurement_unit,
                 grounded_addition_or_subtraction,
                 preserve_unit_in_result]) :-
    memberchk(Operation, [add, subtract]),
    maplist(nonnegative_integer, [A, B]),
    atom(Unit),
    !.
task_descriptor(count_collection(Count, Base), counting,
                [discrete_collection, one_to_one_correspondence,
                 stable_count_word_order, last_word_cardinality,
                 numeral_inscription]) :-
    positive_integer(Count), integer(Base), Base >= 2,
    !.
task_descriptor(inscribe_cardinality(Count, Base), counting,
                [cardinality, counting_cycles_in_base,
                 positional_digits, written_numeral]) :-
    positive_integer(Count), integer(Base), Base >= 2,
    !.
task_descriptor(inscribe_place_value(Count, Base), counting,
                [cardinality, recursive_base_cycles, positional_places,
                 composite_units, unit_tree, written_numeral]) :-
    integer(Count), Count >= 0, integer(Base), Base >= 2,
    !.
task_descriptor(compare_numerals_by_place_value(A, B, Base), counting,
                [two_cardinalities, common_base, align_places,
                 highest_differing_place, compare_place_digits]) :-
    maplist(nonnegative_integer, [A, B]), integer(Base), Base >= 2,
    !.
task_descriptor(compare_cardinalities(A, B, ExtentA, ExtentB), counting,
                [two_collections, one_to_one_matching, unmatched_surplus,
                 ignore_spatial_extent]) :-
    maplist(positive_integer, [A, B]),
    maplist(number, [ExtentA, ExtentB]),
    !.
task_descriptor(mean(Data), statistics,
                [data_set_referent, count_collection, sum_collection,
                 fair_share_total, preserve_measurement_unit]) :-
    valid_data(Data),
    !.
task_descriptor(median(Data), statistics,
                [data_set_referent, order_values, locate_middle,
                 average_two_middle_values_when_even]) :-
    valid_data(Data),
    !.
task_descriptor(mode(Data), statistics,
                [data_set_referent, classify_equal_values,
                 count_frequencies, retain_all_maximal_frequencies]) :-
    valid_data(Data),
    !.
task_descriptor(Task, unknown, [task_definition(Task)]).

definition_task_keyword(mean(_), statistics, "Mean").
definition_task_keyword(median(_), statistics, "Median").
definition_task_keyword(mode(_), statistics, "Data").
definition_task_keyword(rectangle_area(_, _), geometry, "area").
definition_task_keyword(rectangle_perimeter(_, _, _), geometry, "perimeter").
definition_task_keyword(rectangle_side_lengths_for_perimeter(_, _), geometry,
                        "perimeter").
definition_task_keyword(construct_rectangle_with_perimeter(_, _), geometry,
                        "perimeter").
definition_task_keyword(rectangle_missing_side_from_perimeter(_, _, _), geometry,
                        "perimeter").
definition_task_keyword(unit_cube_volume(_, _, _), geometry, "volume").
definition_task_keyword(unit_cube_volume(_, _, _, _), geometry, "volume").
definition_task_keyword(plot_points(_), geometry, "Coordinate Plane").
definition_task_keyword(solid_net(_), geometry, "Nets").

execute_task_path(add(A, B), Contract, Requirements, Outcome) :-
    int_to_peano(A, PA), int_to_peano(B, PB),
    (   strategy_synthesis:synthesize_for_goal(add(PA, PB, _), 10, 1, Synthesis)
    ->  Outcome = candidate_path{
            lesson: Contract.lesson,
            task: add(A, B),
            operation: addition,
            source: primitive_reorganization,
            scope: episode,
            requirements: Requirements,
            plan_shape: Synthesis.plan_shape,
            path: Synthesis.strategy,
            result: Synthesis.result,
            validation: Synthesis.validation
        }
    ;   registered_action_task_path(add(A, B), addition, Contract,
                                    Requirements, Outcome)
    ),
    !.
execute_task_path(Task, Contract, Requirements, Outcome) :-
    whole_number_task(Task, CurriculumOperation, LearnerOperation, A, B),
    LearnerGoal =.. [LearnerOperation, A, B, _Result],
    (   strategy_synthesis:synthesize_for_goal(LearnerGoal, 10, 1, Synthesis)
    ->  Outcome = candidate_path{
            lesson: Contract.lesson,
            task: Task,
            operation: CurriculumOperation,
            learner_operation: LearnerOperation,
            source: primitive_reorganization,
            scope: episode,
            requirements: Requirements,
            plan_shape: Synthesis.plan_shape,
            path: Synthesis.strategy,
            result: Synthesis.result,
            validation: Synthesis.validation
        }
    ;   registered_action_task_path(Task, CurriculumOperation, Contract,
                                    Requirements, Outcome)
    ),
    integer(A), integer(B),
    !.

execute_task_path(unit_fraction(N, D), Contract, Requirements, Outcome) :-
    fraction_unit_plan(N, D, Plan),
    run_unit_plan(Plan, Quantity, Trace),
    plan_dict(Plan, PlanDict),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: unit_fraction(N, D),
        operation: fraction,
        source: recursive_unit_actions,
        scope: reusable_plan,
        requirements: Requirements,
        plan: PlanDict,
        result: Quantity,
        trace: Trace,
        validation: referent_preserving_execution
    },
    !.
execute_task_path(iterate_improper_fraction(Numerator, Denominator), Contract,
                  Requirements, Outcome) :-
    run_action_automaton(fraction, improper_fraction_iteration,
                         Numerator, Denominator, ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: iterate_improper_fraction(Numerator, Denominator),
        operation: fraction,
        source: improper_fraction_iteration_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: fraction_plan(establish_unit_fraction(Denominator),
                            iterate_units(Numerator),
                            name_quantity_beyond_one_whole),
        result: Result,
        trace: ActionTrace,
        validation: improper_fraction_names_iterated_unit_fractions
    },
    !.
execute_task_path(decimal_value(Numeral, Scale), Contract, Requirements,
                  Outcome) :-
    run_decimal_action(positional_decimal_reading, Numeral, Scale,
                       ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, ActionResult),
    Value is Numeral rdiv Scale,
    numeral_projection(Value, 10, Projection),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: decimal_value(Numeral, Scale),
        operation: decimal,
        source: decimal_action_compiled_to_recursive_numeral,
        scope: reusable_plan,
        requirements: Requirements,
        plan: decimal_plan(read_positional(Numeral, Scale), Projection.numeral),
        result: Value,
        action_result: ActionResult,
        trace: ActionTrace,
        projection: Projection,
        validation: exact_rational_and_positional_action_agree
    },
    !.
execute_task_path(decimal_compare(N1, S1, N2, S2), Contract, Requirements,
                  Outcome) :-
    Pair = decimal_pair(N1, S1, N2, S2),
    run_decimal_action(decimal_comparison_by_aligned_units, Pair, ignored,
                       ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Relation),
    ActionOutcome = action_outcome(_, Fields),
    member(representation(Representation), Fields),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: decimal_compare(N1, S1, N2, S2),
        operation: decimal,
        source: decimal_comparison_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: decimal_plan(align_to_common_scale,
                           compare_common_decimal_units),
        result: Relation,
        trace: ActionTrace,
        representation: Representation,
        validation: decimal_magnitudes_compared_in_common_unit
    },
    !.
execute_task_path(decimal_add(N1, S1, N2, S2), Contract, Requirements,
                  Outcome) :-
    Pair = decimal_pair(N1, S1, N2, S2),
    run_decimal_action(decimal_addition_by_aligned_units, Pair, ignored,
                       ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    ActionOutcome = action_outcome(_, Fields),
    member(representation(Representation), Fields),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: decimal_add(N1, S1, N2, S2),
        operation: decimal,
        source: decimal_addition_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: decimal_plan(align_to_common_scale,
                           inherited_grounded_addition,
                           reinscribe_at_common_scale),
        result: Result,
        trace: ActionTrace,
        representation: Representation,
        validation: decimal_addition_preserves_common_unit
    },
    !.
execute_task_path(decimal_subtract(N1, S1, N2, S2), Contract, Requirements,
                  Outcome) :-
    Pair = decimal_pair(N1, S1, N2, S2),
    run_decimal_action(decimal_subtraction_by_aligned_units, Pair, ignored,
                       ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    ActionOutcome = action_outcome(_, Fields),
    member(representation(Representation), Fields),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: decimal_subtract(N1, S1, N2, S2),
        operation: decimal,
        source: decimal_subtraction_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: decimal_plan(align_to_common_scale,
                           inherited_grounded_subtraction,
                           reinscribe_at_common_scale),
        result: Result,
        trace: ActionTrace,
        representation: Representation,
        validation: decimal_subtraction_preserves_common_unit
    },
    !.
execute_task_path(regroup_decimal_units(Count, FromScale, ToScale), Contract,
                  Requirements, Outcome) :-
    Conversion = decimal_unit_conversion(Count, FromScale, ToScale),
    run_decimal_action(decimal_place_unit_regrouping, Conversion, ignored,
                       ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    ActionOutcome = action_outcome(_, Fields),
    member(representation(Representation), Fields),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: regroup_decimal_units(Count, FromScale, ToScale),
        operation: decimal,
        source: decimal_place_unit_regrouping_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: decimal_plan(identify_nested_place_units,
                           iterate_finer_unit,
                           preserve_quantity),
        result: Result,
        trace: ActionTrace,
        representation: Representation,
        validation: count_and_decimal_unit_change_together
    },
    !.
execute_task_path(decimal_multiply(N1, S1, N2, S2), Contract, Requirements,
                  Outcome) :-
    Pair = decimal_pair(N1, S1, N2, S2),
    run_decimal_action(decimal_multiplication_rule, Pair, ignored,
                       ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, ActionResult),
    Value is (N1 * N2) rdiv (S1 * S2),
    numeral_projection(Value, 10, Projection),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: decimal_multiply(N1, S1, N2, S2),
        operation: decimal,
        source: decimal_action_compiled_to_recursive_numeral,
        scope: reusable_plan,
        requirements: Requirements,
        plan: decimal_plan(multiply_integer_numerals(N1, N2),
                           combine_scales(S1, S2), Projection.numeral),
        result: Value,
        action_result: ActionResult,
        trace: ActionTrace,
        projection: Projection,
        validation: exact_product_and_place_count_action_agree
    },
    !.
execute_task_path(signed_add(A, B), Contract, Requirements, Outcome) :-
    run_integer_action(signed_addition_with_sign_relation, A, B,
                       ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    numeral_projection(Result, 10, Projection),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: signed_add(A, B),
        operation: integer,
        source: signed_action_compiled_to_recursive_numeral,
        scope: reusable_plan,
        requirements: Requirements,
        plan: signed_plan(compare_signs_then_combine_magnitudes),
        result: Result,
        trace: ActionTrace,
        projection: Projection,
        validation: sign_relation_preserved
    },
    !.
execute_task_path(scale_ratio(A, B, Factor), Contract, Requirements, Outcome) :-
    run_ratio_scale(scale_ratio_unit, A, B, Factor,
                    ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    Result = ratio_pair(ScaledA, ScaledB),
    integer_inscription(A, 10, AInscription),
    integer_inscription(B, 10, BInscription),
    integer_inscription(ScaledA, 10, ScaledAInscription),
    integer_inscription(ScaledB, 10, ScaledBInscription),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: scale_ratio(A, B, Factor),
        operation: ratio,
        source: ratio_action_over_recursive_numerals,
        scope: reusable_plan,
        requirements: Requirements,
        plan: ratio_plan(ratio(AInscription, BInscription),
                         scale_both(Factor),
                         ratio(ScaledAInscription, ScaledBInscription)),
        result: Result,
        trace: ActionTrace,
        validation: multiplicative_unit_ratio_preserved
    },
    !.
execute_task_path(evaluate_expression(Expression, Assignment), Contract,
                  Requirements, Outcome) :-
    run_algebraic_action(programming_expression_evaluation,
                         Expression, Assignment, ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, value(Value)),
    numeral_projection(Value, 10, Projection),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: evaluate_expression(Expression, Assignment),
        operation: algebraic,
        source: algebraic_expression_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: algebraic_plan(walk_expression_tree,
                             substitute(Assignment),
                             execute_grounded_subexpressions),
        result: Value,
        trace: ActionTrace,
        projection: Projection,
        validation: grounded_expression_tree_execution
    },
    !.
execute_task_path(linear_pattern(First, Change, Row, Context), Contract,
                  Requirements, Outcome) :-
    Pattern = linear_pattern(first(First), change(Change), row(Row)),
    run_algebraic_action(linear_pattern_contextual_rule, Pattern, Context,
                         ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, value(Value)),
    numeral_projection(Value, 10, Projection),
    Increments is Row - 1,
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: linear_pattern(First, Change, Row, Context),
        operation: algebraic,
        source: algebraic_pattern_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: algebraic_plan(initial(First),
                             iterate_change(Change, Increments),
                             preserve_context(Context)),
        result: Value,
        trace: ActionTrace,
        projection: Projection,
        validation: contextual_rate_and_initial_value_preserved
    },
    !.
execute_task_path(solve_linear(A, B, C), Contract, Requirements, Outcome) :-
    run_algebraic_action(balance_preserving_linear_solution,
                         linear_equation(A, B, C),
                         solution_domain(nonnegative_integer),
                         ActionOutcome, ActionTrace),
    ActionOutcome = action_outcome(_, Fields),
    member(result(value(Solution)), Fields),
    member(witness(Witness), Fields),
    member(representation(SceneDocument), Fields),
    numeral_projection(Solution, 10, Projection),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: solve_linear(A, B, C),
        operation: algebraic,
        source: balance_preserving_unknown_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: algebraic_plan(read_equation(Witness.read_equation),
                             preserve_balance(Witness.steps),
                             isolate_unknown),
        result: Solution,
        trace: ActionTrace,
        evidence: Fields,
        projection: Projection,
        scene: SceneDocument,
        validation: every_equation_step_preserves_balance
    },
    !.
execute_task_path(validate_quotient(Proposed, Dividend, Divisor), Contract,
                  Requirements, Outcome) :-
    Reference = dividend_divisor(Dividend, Divisor),
    run_diagnostic_action(multiplicative_bound_invalidation,
                          Proposed, Reference, ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: validate_quotient(Proposed, Dividend, Divisor),
        operation: diagnostic,
        source: grounded_diagnostic_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: diagnostic_plan(multiply(Divisor, Proposed),
                              compare_with(Dividend)),
        result: Result,
        trace: ActionTrace,
        validation: inverse_multiplication_bound_checked
    },
    !.
execute_task_path(rectangle_area(Rows, Columns), Contract, Requirements,
                  Outcome) :-
    grounded_product(Rows, Columns, Area),
    area_render_json(array_multiplication(Rows, Columns), SceneDocument),
    scene_document_success(SceneDocument),
    numeral_projection(Area, 10, Projection),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: rectangle_area(Rows, Columns),
        operation: geometry,
        source: area_action_over_grounded_multiplication,
        scope: reusable_plan,
        requirements: Requirements,
        plan: geometry_plan(iterate_row_unit(Rows),
                            iterate_column_unit(Columns),
                            coordinate_square_units),
        result: square_units(Area),
        trace: [establish_rectangle(Rows, Columns),
                coordinate_rows_and_columns, count_square_units(Area)],
        projection: Projection,
        scene: SceneDocument,
        validation: array_geometry_and_grounded_product_agree
    },
    !.
execute_task_path(compare_rectangle_areas(L1, W1, L2, W2, Unit), Contract,
                  Requirements, Outcome) :-
    grounded_product(L1, W1, Area1),
    grounded_product(L2, W2, Area2),
    area_relation(Area1, Area2, Relation),
    area_render_json(array_multiplication(L1, W1), Scene1),
    area_render_json(array_multiplication(L2, W2), Scene2),
    scene_document_success(Scene1),
    scene_document_success(Scene2),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: compare_rectangle_areas(L1, W1, L2, W2, Unit),
        operation: geometry,
        source: paired_rectangle_area_actions,
        scope: reusable_plan,
        requirements: Requirements,
        plan: geometry_plan(coordinate_first_rectangle_square_units,
                            coordinate_second_rectangle_square_units,
                            compare_area_totals),
        result: Relation,
        areas: [area(Area1, square(Unit)), area(Area2, square(Unit))],
        trace: [rectangle_area(L1, W1, Area1),
                rectangle_area(L2, W2, Area2),
                compare_square_units(Area1, Area2, Relation)],
        scenes: [Scene1, Scene2],
        validation: both_areas_use_same_square_unit
    },
    !.
execute_task_path(rectangle_missing_side_from_area(Area, KnownSide, Unit),
                  Contract, Requirements, Outcome) :-
    run_geometry_action(rectangle_missing_side_from_area,
                        area(Area), known_side(KnownSide),
                        ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    ActionOutcome = action_outcome(_, Fields),
    member(representation(Representation), Fields),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: rectangle_missing_side_from_area(Area, KnownSide, Unit),
        operation: geometry,
        source: inverse_rectangle_area_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: geometry_plan(preserve_area_product,
                            divide_by_known_side,
                            reconstruct_rectangle),
        result: Result,
        unit: Unit,
        trace: ActionTrace,
        representation: Representation,
        validation: known_side_times_result_equals_area
    },
    !.
execute_task_path(select_area_unit(ExtentClass, Candidates), Contract,
                  Requirements, Outcome) :-
    run_geometry_action(area_unit_scale_selection,
                        area_extent(ExtentClass), candidates(Candidates),
                        ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    ActionOutcome = action_outcome(_, Fields),
    member(representation(Representation), Fields),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: select_area_unit(ExtentClass, Candidates),
        operation: geometry,
        source: area_unit_scale_selection_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: geometry_plan(classify_referent_extent(ExtentClass),
                            compare_candidate_square_units,
                            select_matching_scale),
        result: Result,
        trace: ActionTrace,
        representation: Representation,
        validation: square_unit_scale_matches_referent_extent
    },
    !.
execute_task_path(rectangle_perimeter(Length, Width, Unit), Contract,
                  Requirements, Outcome) :-
    run_geometry_action(rectangle_perimeter_boundary_traversal,
                        rectangle(Length, Width), unit(Unit),
                        ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    ActionOutcome = action_outcome(_, Fields),
    member(representation(Scene), Fields),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: rectangle_perimeter(Length, Width, Unit),
        operation: geometry,
        source: rectangle_boundary_traversal_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: geometry_plan(establish_rectangle,
                            traverse_all_four_sides,
                            accumulate_linear_units),
        result: Result,
        trace: ActionTrace,
        scene: Scene,
        validation: complete_rectangle_boundary_preserved
    },
    !.
execute_task_path(polygon_perimeter(SideLengths, Unit), Contract,
                  Requirements, Outcome) :-
    run_geometry_action(polygon_perimeter_boundary_accumulation,
                        sides(SideLengths), unit(Unit),
                        ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    ActionOutcome = action_outcome(_, Fields),
    member(representation(Representation), Fields),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: polygon_perimeter(SideLengths, Unit),
        operation: geometry,
        source: polygon_boundary_cycle_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: geometry_plan(establish_closed_boundary,
                            traverse_each_side_once,
                            accumulate_linear_units),
        result: Result,
        trace: ActionTrace,
        representation: Representation,
        validation: complete_polygon_boundary_preserved
    },
    !.
execute_task_path(symmetry_missing_side(Orbits, Perimeter, Unit), Contract,
                  Requirements, Outcome) :-
    run_geometry_action(symmetry_constrained_side_reconstruction,
                        side_orbits(Orbits), perimeter(Perimeter, Unit),
                        ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    ActionOutcome = action_outcome(_, Fields),
    member(representation(Representation), Fields),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: symmetry_missing_side(Orbits, Perimeter, Unit),
        operation: geometry,
        source: symmetry_constrained_perimeter_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: geometry_plan(group_reflected_sides,
                            accumulate_known_orbits,
                            partition_remaining_boundary),
        result: Result,
        trace: ActionTrace,
        representation: Representation,
        validation: reflected_side_orbits_preserve_length
    },
    !.
execute_task_path(rectangle_side_lengths_for_perimeter(Perimeter, Unit),
                  Contract, Requirements, Outcome) :-
    run_geometry_action(rectangle_perimeter_side_pair_search, Perimeter,
                        side_scope(all), ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    ActionOutcome = action_outcome(_, Fields),
    member(side_pairs(Pairs), Fields),
    member(representations(Scenes), Fields),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: rectangle_side_lengths_for_perimeter(Perimeter, Unit),
        operation: geometry,
        source: fixed_perimeter_side_pair_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: geometry_plan(establish_target_perimeter,
                            enumerate_positive_side_pairs,
                            preserve_complete_boundary),
        result: Result,
        unit: Unit,
        alternatives: Pairs,
        trace: ActionTrace,
        scenes: Scenes,
        validation: every_candidate_has_perimeter(Perimeter)
    },
    !.
execute_task_path(construct_rectangle_with_perimeter(Perimeter, Unit),
                  Contract, Requirements, Outcome) :-
    run_geometry_action(rectangle_perimeter_side_pair_search, Perimeter,
                        side_scope(one), ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    ActionOutcome = action_outcome(_, Fields),
    member(side_pairs(Pairs), Fields),
    member(representations(Scenes), Fields),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: construct_rectangle_with_perimeter(Perimeter, Unit),
        operation: geometry,
        source: fixed_perimeter_side_pair_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: geometry_plan(establish_target_perimeter,
                            choose_positive_side_pair,
                            verify_complete_boundary),
        result: Result,
        unit: Unit,
        alternatives: Pairs,
        trace: ActionTrace,
        scenes: Scenes,
        validation: chosen_candidate_has_perimeter(Perimeter)
    },
    !.
execute_task_path(
        rectangle_missing_side_from_perimeter(Perimeter, Known, Unit),
        Contract, Requirements, Outcome) :-
    run_geometry_action(rectangle_missing_side_from_perimeter,
                        perimeter(Perimeter), known_side(Known),
                        ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    ActionOutcome = action_outcome(_, Fields),
    member(representation(Scene), Fields),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: rectangle_missing_side_from_perimeter(Perimeter, Known, Unit),
        operation: geometry,
        source: inverse_rectangle_perimeter_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: geometry_plan(halve_perimeter,
                            subtract_known_side,
                            verify_complete_boundary),
        result: Result,
        unit: Unit,
        trace: ActionTrace,
        scene: Scene,
        validation: reconstructed_rectangle_has_perimeter(Perimeter)
    },
    !.
execute_task_path(construct_rectangle_with_area(Area), Contract, Requirements,
                  Outcome) :-
    run_geometry_action(rectangle_factor_pair_search, Area, factor_scope(one),
                        ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    ActionOutcome = action_outcome(_, Fields),
    member(factor_pairs(Pairs), Fields),
    member(representations(Scenes), Fields),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: construct_rectangle_with_area(Area),
        operation: geometry,
        source: rectangle_factor_pair_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: geometry_plan(establish_target_area(Area),
                            search_factor_pairs,
                            choose_rectangle),
        result: Result,
        alternatives: Pairs,
        trace: ActionTrace,
        scenes: Scenes,
        validation: every_candidate_has_area(Area)
    },
    !.
execute_task_path(rectangle_side_lengths_for_area(Area), Contract, Requirements,
                  Outcome) :-
    run_geometry_action(rectangle_factor_pair_search, Area, factor_scope(all),
                        ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    ActionOutcome = action_outcome(_, Fields),
    member(factor_pairs(Pairs), Fields),
    member(representations(Scenes), Fields),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: rectangle_side_lengths_for_area(Area),
        operation: geometry,
        source: rectangle_factor_pair_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: geometry_plan(establish_target_area(Area),
                            exhaustive_factor_pair_search,
                            identify_rotations),
        result: Result,
        alternatives: Pairs,
        trace: ActionTrace,
        scenes: Scenes,
        validation: factor_pair_search_complete_for(Area)
    },
    !.
execute_task_path(unit_cube_volume(Length, Width, Height), Contract,
                  Requirements, Outcome) :-
    grounded_product(Length, Width, BaseArea),
    grounded_product(BaseArea, Height, Volume),
    solid_net_render_json(unit_cube_stack(Length, Width, Height), SceneDocument),
    scene_document_success(SceneDocument),
    numeral_projection(Volume, 10, Projection),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: unit_cube_volume(Length, Width, Height),
        operation: geometry,
        source: cube_stack_action_over_grounded_multiplication,
        scope: reusable_plan,
        requirements: Requirements,
        plan: geometry_plan(coordinate_base(Length, Width),
                            iterate_layers(Height), count_cubic_units),
        result: cubic_units(Volume),
        trace: [compose_base_area(BaseArea), iterate_height_layers(Height),
                count_cubic_units(Volume)],
        projection: Projection,
        scene: SceneDocument,
        validation: cube_stack_geometry_and_grounded_product_agree
    },
    !.
execute_task_path(unit_cube_volume(Length, Width, Height, Unit), Contract,
                  Requirements, Outcome) :-
    grounded_product(Length, Width, BaseArea),
    grounded_product(BaseArea, Height, Volume),
    solid_net_render_json(unit_cube_stack(Length, Width, Height), SceneDocument),
    scene_document_success(SceneDocument),
    numeral_projection(Volume, 10, Projection),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: unit_cube_volume(Length, Width, Height, Unit),
        operation: geometry,
        source: cube_stack_action_over_grounded_multiplication,
        scope: reusable_plan,
        requirements: Requirements,
        plan: geometry_plan(coordinate_base(Length, Width),
                            iterate_layers(Height), count_cubic_units),
        result: volume(Volume, cube(Unit)),
        trace: [compose_base_area(BaseArea), iterate_height_layers(Height),
                count_cubic_units(Volume), preserve_cubic_unit(Unit)],
        projection: Projection,
        scene: SceneDocument,
        validation: cube_stack_geometry_and_grounded_product_agree
    },
    !.
execute_task_path(compare_solid_volumes(CountA, CountB, ExtentA, ExtentB),
                  Contract, Requirements, Outcome) :-
    run_geometry_action(compare_solid_volume_by_cube_count,
                        solid_cube_counts(CountA, CountB),
                        visual_extents(ExtentA, ExtentB),
                        ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    ActionOutcome = action_outcome(_, Fields),
    member(representation(Representation), Fields),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: compare_solid_volumes(CountA, CountB, ExtentA, ExtentB),
        operation: geometry,
        source: solid_volume_cube_count_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: geometry_plan(count_unit_cubes_in_each_solid,
                            ignore_arrangement_extent,
                            compare_conserved_volume),
        result: Result,
        trace: ActionTrace,
        representation: Representation,
        validation: unit_cube_count_determines_constructed_solid_volume
    },
    !.
execute_task_path(plot_points(Points), Contract, Requirements, Outcome) :-
    coordinate_plane_render_json(plot_points(Points), SceneDocument),
    scene_document_success(SceneDocument),
    point_inscriptions(Points, Inscriptions),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: plot_points(Points),
        operation: geometry,
        source: coordinate_plane_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: geometry_plan(establish_axes,
                            locate_x_then_y_for_each_pair,
                            preserve_sign_and_order),
        result: plotted_points(Points),
        trace: [establish_axes, plot_ordered_pairs(Points)],
        projection: coordinate_numerals(Inscriptions),
        scene: SceneDocument,
        validation: every_pair_has_one_plotted_point
    },
    !.
execute_task_path(solid_net(Solid), Contract, Requirements, Outcome) :-
    solid_net_render_json(net_of(Solid), SceneDocument),
    scene_document_success(SceneDocument),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: solid_net(Solid),
        operation: geometry,
        source: solid_net_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: geometry_plan(place_faces, preserve_adjacency, mark_fold_creases),
        result: net_of(Solid),
        trace: SceneDocument.frames,
        scene: SceneDocument,
        validation: renderer_accepts_supported_foldable_net
    },
    !.
execute_task_path(classify_shape(Shape, Attributes, QuarterTurns), Contract,
                  Requirements, Outcome) :-
    run_geometry_action(shape_classification_by_defining_attributes,
                        shape(Shape, Attributes), orientation(QuarterTurns),
                        ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: classify_shape(Shape, Attributes, QuarterTurns),
        operation: geometry,
        source: defining_attribute_classification_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: geometry_plan(observe_attributes,
                            test_defining_attributes,
                            ignore_nondefining_orientation),
        result: Result,
        trace: ActionTrace,
        validation: defining_attributes_preserved_under_rotation
    },
    !.
execute_task_path(angle_measure(Degrees), Contract, Requirements, Outcome) :-
    run_geometry_action(angle_turn_measurement, Degrees, unit(degree),
                        ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    ActionOutcome = action_outcome(_, Fields),
    member(representation(Scene), Fields),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: angle_measure(Degrees),
        operation: geometry,
        source: angle_turn_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: geometry_plan(fix_vertex, establish_initial_ray,
                            iterate_degree_turn(Degrees), locate_terminal_ray),
        result: Result,
        trace: ActionTrace,
        scene: Scene,
        validation: ray_length_independent_turn_measurement
    },
    !.
execute_task_path(compose_angles(Parts, Whole), Contract, Requirements,
                  Outcome) :-
    run_geometry_action(angle_additive_composition, angle_parts(Parts),
                        whole_angle(Whole), ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    ActionOutcome = action_outcome(_, Fields),
    member(representation(Scene), Fields),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: compose_angles(Parts, Whole),
        operation: geometry,
        source: angle_additive_composition_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: geometry_plan(preserve_adjacent_turns(Parts),
                            sum_to_whole(Whole)),
        result: Result,
        trace: ActionTrace,
        scene: Scene,
        validation: part_turns_sum_to_whole_turn
    },
    !.
execute_task_path(compose_rigid_shapes(Columns, Rows, Pieces), Contract,
                  Requirements, Outcome) :-
    run_geometry_action(rigid_shape_composition, region(Columns, Rows), Pieces,
                        ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    ActionOutcome = action_outcome(_, Fields),
    member(representation(Scene), Fields),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: compose_rigid_shapes(Columns, Rows, Pieces),
        operation: geometry,
        source: rigid_shape_composition_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: geometry_plan(establish_bounded_region,
                            preserve_rigid_parts,
                            cover_without_gaps_or_overlaps),
        result: Result,
        trace: ActionTrace,
        scene: Scene,
        validation: parts_preserved_inside_bounded_whole
    },
    !.
execute_task_path(measure_length(IntervalCount, Subdivisions, Unit), Contract,
                  Requirements, Outcome) :-
    run_action_automaton(measurement, linear_unit_iteration,
                         measure(IntervalCount, Subdivisions), unit(Unit),
                         ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    ActionOutcome = action_outcome(_, Fields),
    member(representation(Scene), Fields),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: measure_length(IntervalCount, Subdivisions, Unit),
        operation: measurement,
        source: linear_measurement_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: measurement_plan(establish_unit(Unit),
                               partition_unit(Subdivisions),
                               iterate_intervals(IntervalCount)),
        result: Result,
        trace: ActionTrace,
        scene: Scene,
        validation: interval_count_preserves_fixed_unit
    },
    !.
execute_task_path(read_liquid_volume(IntervalCount, Subdivisions, Unit), Contract,
                  Requirements, Outcome) :-
    run_action_automaton(measurement, liquid_volume_scale_reading,
                         measure(IntervalCount, Subdivisions), unit(Unit),
                         ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    ActionOutcome = action_outcome(_, Fields),
    member(representation(Scene), Fields),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: read_liquid_volume(IntervalCount, Subdivisions, Unit),
        operation: measurement,
        source: liquid_volume_scale_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: measurement_plan(establish_volume_unit(Unit),
                               partition_volume_scale(Subdivisions),
                               locate_fill_level(IntervalCount)),
        result: Result,
        trace: ActionTrace,
        scene: Scene,
        validation: volume_scale_counts_intervals_not_marks
    },
    !.
execute_task_path(convert_measurement(Count, FromUnit, ToUnit, Factor),
                  Contract, Requirements, Outcome) :-
    run_action_automaton(measurement, unit_conversion_by_iteration,
                         quantity(Count, FromUnit), conversion(ToUnit, Factor),
                         ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    ActionOutcome = action_outcome(_, Fields),
    member(representation(Representation), Fields),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: convert_measurement(Count, FromUnit, ToUnit, Factor),
        operation: measurement,
        source: composite_unit_conversion_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: measurement_plan(establish_equivalence(
                                   one(FromUnit), Factor, ToUnit),
                               iterate_conversion_group(Count),
                               preserve_measured_quantity),
        result: Result,
        trace: ActionTrace,
        representation: Representation,
        validation: numeral_and_unit_change_preserve_quantity
    },
    !.
execute_task_path(measured_quantity_change(Operation, A, B, Unit), Contract,
                  Requirements, Outcome) :-
    Change = measured_change(Operation, A, B, Unit),
    run_action_automaton(measurement,
                         unit_preserving_measured_quantity_change,
                         Change, ignored, ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    ActionOutcome = action_outcome(_, Fields),
    member(representation(Representation), Fields),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: measured_quantity_change(Operation, A, B, Unit),
        operation: measurement,
        source: unit_preserving_measured_quantity_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: measurement_plan(establish_common_unit,
                               perform_grounded_change(Operation),
                               retain_unit_in_result),
        result: Result,
        trace: ActionTrace,
        representation: Representation,
        validation: quantity_change_preserves_measurement_unit
    },
    !.
execute_task_path(count_collection(Count, Base), Contract, Requirements,
                  Outcome) :-
    run_action_automaton(counting, enumerate_collection_one_to_one,
                         Count, base(Base), ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    ActionOutcome = action_outcome(_, Fields),
    member(inscription(Numeral), Fields),
    member(representation(Scene), Fields),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: count_collection(Count, Base),
        operation: counting,
        source: counting_cardinality_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: counting_plan(pair_each_object_with_one_count_word,
                            retain_last_word_as_cardinality,
                            inscribe_in_base(Base)),
        result: Result,
        inscription: Numeral,
        trace: ActionTrace,
        scene: Scene,
        validation: one_to_one_count_and_cardinality_preserved
    },
    !.
execute_task_path(inscribe_cardinality(Count, Base), Contract, Requirements,
                  Outcome) :-
    run_action_automaton(counting, inscribe_cardinality, Count, base(Base),
                         ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Numeral),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: inscribe_cardinality(Count, Base),
        operation: counting,
        source: recursive_numeral_inscription_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: counting_plan(establish_cardinality(Count),
                            recurse_over_base_cycles(Base),
                            emit_positional_digits),
        result: Numeral,
        trace: ActionTrace,
        validation: numeral_denotes_counted_cardinality
    },
    !.
execute_task_path(inscribe_place_value(Count, Base), Contract, Requirements,
                  Outcome) :-
    run_action_automaton(counting, recursive_place_value_inscription,
                         Count, base(Base), ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Numeral),
    ActionOutcome = action_outcome(_, Fields),
    member(representation(UnitTree), Fields),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: inscribe_place_value(Count, Base),
        operation: counting,
        source: recursive_place_value_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: counting_plan(recollect_completed_base_cycles,
                            coordinate_digits_with_place_units,
                            emit_positional_numeral),
        result: Numeral,
        trace: ActionTrace,
        representation: UnitTree,
        validation: each_place_recollects_recursively_regrouped_units
    },
    !.
execute_task_path(compare_numerals_by_place_value(A, B, Base), Contract,
                  Requirements, Outcome) :-
    run_action_automaton(counting, place_value_comparison,
                         counts(A, B), base(Base), ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    ActionOutcome = action_outcome(_, Fields),
    member(representation(Representation), Fields),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: compare_numerals_by_place_value(A, B, Base),
        operation: counting,
        source: place_value_comparison_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: counting_plan(inscribe_in_common_base(Base),
                            align_place_units,
                            compare_highest_differing_place),
        result: Result,
        trace: ActionTrace,
        representation: Representation,
        validation: higher_places_dominate_lower_places
    },
    !.
execute_task_path(compare_cardinalities(A, B, ExtentA, ExtentB), Contract,
                  Requirements, Outcome) :-
    run_action_automaton(counting, compare_cardinalities_one_to_one,
                         counts(A, B), extents(ExtentA, ExtentB),
                         ActionOutcome, ActionTrace),
    productive_outcome_result(ActionOutcome, Result),
    ActionOutcome = action_outcome(_, Fields),
    member(representation(Scene), Fields),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: compare_cardinalities(A, B, ExtentA, ExtentB),
        operation: counting,
        source: cardinality_comparison_action,
        scope: reusable_plan,
        requirements: Requirements,
        plan: counting_plan(match_one_to_one,
                            inspect_unmatched_surplus,
                            ignore_spatial_extent),
        result: Result,
        trace: ActionTrace,
        scene: Scene,
        validation: cardinality_independent_of_spatial_extent
    },
    !.
execute_task_path(solid_net(Solid), Contract, Requirements, Outcome) :-
    solid_net_render_json(net_of(Solid), SceneDocument),
    get_dict(error, SceneDocument, Error),
    Outcome = unsupported{
        lesson: Contract.lesson,
        task: solid_net(Solid),
        operation: geometry,
        reason: representation_capacity_refusal,
        representation: solid_net,
        detail: Error,
        constituent_requirements: Requirements
    },
    !.
execute_task_path(mean(Data), Contract, Requirements, Outcome) :-
    valid_data(Data),
    grounded_data_sum(Data, Sum, SumTrace),
    length(Data, Count),
    mean_plan(Sum, Count, Mean, Plan, PlanTrace),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: mean(Data),
        operation: statistics,
        source: supplied_statistical_definition,
        scope: reusable_plan,
        requirements: Requirements,
        plan: data_plan(sum_values(SumTrace),
                        fair_share_total(Plan)),
        result: Mean,
        trace: PlanTrace,
        validation: definition(mean_as_fair_share_of_total_by_count)
    },
    !.
execute_task_path(median(Data), Contract, Requirements, Outcome) :-
    valid_data(Data),
    msort(Data, Sorted),
    median_value(Sorted, Median, MiddleEvidence),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: median(Data),
        operation: statistics,
        source: supplied_statistical_definition,
        scope: reusable_plan,
        requirements: Requirements,
        plan: data_plan(order_values(Sorted), MiddleEvidence),
        result: Median,
        trace: [order_values(Sorted), MiddleEvidence],
        validation: definition(median_as_middle_of_ordered_data)
    },
    !.
execute_task_path(mode(Data), Contract, Requirements, Outcome) :-
    valid_data(Data),
    msort(Data, Sorted),
    clumped(Sorted, Frequencies),
    mode_values(Frequencies, Modes, MaxFrequency),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: mode(Data),
        operation: statistics,
        source: supplied_statistical_definition,
        scope: reusable_plan,
        requirements: Requirements,
        plan: data_plan(classify_and_count(Frequencies),
                        retain_maximal_frequency(MaxFrequency)),
        result: modes(Modes),
        trace: [order_values(Sorted), count_frequencies(Frequencies),
                retain_modes(Modes, MaxFrequency)],
        validation: definition(mode_as_all_maximally_frequent_values)
    },
    !.
execute_task_path(Task, Contract, Requirements, Outcome) :-
    Outcome = unsupported{
        lesson: Contract.lesson,
        task: Task,
        reason: activity_executor_missing,
        constituent_requirements: Requirements
    }.

action_signature(Operation, Kind, signature(Input, Output)) :-
    action_automaton_signature(Operation, Kind, Input, Output),
    !.
action_signature(_Operation, _Kind, unspecified).

registered_action_task_path(Task, Operation, Contract, Requirements, Outcome) :-
    member(Obligation, Contract.strategy_obligations),
    Obligation.operation == Operation,
    memberchk(Obligation.role, [productive, productive_unpaired]),
    Kind = Obligation.kind,
    task_action_operands(Task, Operation, Left, Right),
    run_action_automaton(Operation, Kind, Left, Right, ActionOutcome, Trace),
    productive_outcome_result(ActionOutcome, Result),
    Outcome = candidate_path{
        lesson: Contract.lesson,
        task: Task,
        operation: Operation,
        source: action_automata_registry,
        scope: reusable_plan,
        requirements: Requirements,
        action_kind: Kind,
        result: Result,
        trace: Trace,
        validation: registered_productive_action(Kind)
    },
    !.
registered_action_task_path(Task, Operation, Contract, Requirements,
                            unsupported{
                                lesson: Contract.lesson,
                                task: Task,
                                operation: Operation,
                                reason: registered_action_not_executable_for_input,
                                constituent_requirements: Requirements
                            }).

productive_outcome_result(action_outcome(_Kind, Fields), Result) :-
    memberchk(classification(productive), Fields),
    memberchk(validity(correct), Fields),
    memberchk(result(Result), Fields).

numeral_projection(Value, Base,
                   numeral_projection{
                       numeral: Numeral,
                       inscription: Text,
                       action_candidates: Candidates
                   }) :-
    value_numeral(Value, Base, Numeral),
    numeral_text(Numeral, Text),
    findall(action_candidate(Plan, Trace),
            numeral_action_witness(Numeral, Plan, Trace),
            Candidates).

integer_inscription(Integer, Base, Numeral) :-
    integer_numeral(Integer, Base, Numeral).

valid_data([Value|Values]) :-
    nonnegative_integer(Value),
    maplist(nonnegative_integer, Values).

grounded_data_sum(Data, Sum, Trace) :-
    integer_to_recollection(0, Zero),
    grounded_data_sum(Data, Zero, [], SumRec, ReverseTrace),
    reverse(ReverseTrace, Trace),
    recollection_to_integer(SumRec, Sum).

grounded_data_sum([], Sum, Trace, Sum, Trace).
grounded_data_sum([Value|Values], Acc0, Trace0, Sum, Trace) :-
    integer_to_recollection(Value, RecValue),
    add_grounded(Acc0, RecValue, Acc),
    grounded_data_sum(Values, Acc,
                      [add_measurement(Value, Acc0, Acc)|Trace0],
                      Sum, Trace).

mean_plan(0, Count, 0, zero_total_fair_share(Count),
          [sum_is_zero, share_zero_among(Count)]) :- !.
mean_plan(Sum, Count, Mean, Plan, Trace) :-
    fraction_unit_plan(Sum, Count, Plan),
    run_unit_plan(Plan, Quantity, Trace),
    Quantity = quantity(_, canonical_value(fraction(N, D)), _, _, _, _),
    Mean is N rdiv D.

median_value(Sorted, Median, middle_value(Index, Median)) :-
    length(Sorted, Count),
    1 is Count mod 2,
    Index is Count // 2,
    nth0(Index, Sorted, Median),
    !.
median_value(Sorted, Median,
             average_middle_values(LeftIndex-Left, RightIndex-Right)) :-
    length(Sorted, Count),
    0 is Count mod 2,
    RightIndex is Count // 2,
    LeftIndex is RightIndex - 1,
    nth0(LeftIndex, Sorted, Left),
    nth0(RightIndex, Sorted, Right),
    Median is (Left + Right) rdiv 2.

mode_values(Frequencies, Modes, MaxFrequency) :-
    findall(Count, member(_Value-Count, Frequencies), Counts),
    max_list(Counts, MaxFrequency),
    findall(Value, member(Value-MaxFrequency, Frequencies), Modes).

grounded_product(A, B, Product) :-
    integer_to_recollection(A, RA),
    integer_to_recollection(B, RB),
    multiply_grounded(RA, RB, RP),
    recollection_to_integer(RP, Product).

scene_document_success(Document) :-
    \+ get_dict(error, Document, _),
    get_dict(frames, Document, Frames),
    Frames = [_|_].

valid_points([X-Y|Points]) :-
    integer(X), integer(Y),
    valid_point_tail(Points).

valid_point_tail([]).
valid_point_tail([X-Y|Points]) :-
    integer(X), integer(Y),
    valid_point_tail(Points).

point_inscriptions([], []).
point_inscriptions([X-Y|Points],
                   [point_numerals(XNumeral, YNumeral)|Inscriptions]) :-
    integer_numeral(X, 10, XNumeral),
    integer_numeral(Y, 10, YNumeral),
    point_inscriptions(Points, Inscriptions).

nonnegative_integer(N) :- integer(N), N >= 0.
positive_integer(N) :- integer(N), N > 0.
scale_integer(N) :-
    integer(N), N >= 10,
    scale_integer_(N).

scale_integer_(10) :- !.
scale_integer_(N) :-
    0 is N mod 10,
    Next is N // 10,
    scale_integer_(Next).


%!  lesson_capability_row(+LessonCode, -Row) is semidet.
%
%   Compact classification suitable for a generated curriculum graph. A routed
%   operation means this module has a concrete-task compiler for it; it does not
%   mean every activity in the lesson is executable.
lesson_capability_row(Code, Row) :-
    lesson_activity_contract(Code, Contract),
    capability_row_from_obligations(Code, Contract.grade, Contract.title,
                                    Contract.status,
                                    Contract.strategy_obligations, Row).

capability_row_from_obligations(Code, Grade, Title, Status,
                                Obligations, Row) :-
    findall(Operation,
            ( member(O, Obligations),
              O.registry_status == registered_action,
              Operation = O.operation ),
            Operations0),
    sort(Operations0, Operations),
    include(routed_operation, Operations, Routed),
    exclude(routed_operation, Operations, Unrouted),
    findall(Operation-Kind,
            ( member(O, Obligations),
              O.registry_status == missing_action_automaton,
              Operation = O.operation,
              Kind = O.kind ),
            Missing0),
    sort(Missing0, Missing),
    include(productive_obligation, Obligations, Productive),
    include(deformation_obligation, Obligations, Deformations),
    length(Productive, ProductiveCount),
    length(Deformations, DeformationCount),
    Row = _{ lesson: Code,
             grade: Grade,
             title: Title,
             contract_status: Status,
             operations: Operations,
             routed_task_operations: Routed,
             unrouted_task_operations: Unrouted,
             missing_action_automata: Missing,
             action_obligations: Obligations,
             productive_obligation_count: ProductiveCount,
             deformation_obligation_count: DeformationCount }.

routed_operation(addition).
routed_operation(subtraction).
routed_operation(multiplication).
routed_operation(division).
routed_operation(fraction).
routed_operation(decimal).
routed_operation(integer).
routed_operation(ratio).
routed_operation(algebraic).
routed_operation(diagnostic).
routed_operation(statistics).
routed_operation(geometry).

whole_number_task(subtract(A, B), subtraction, subtract, A, B).
whole_number_task(multiply(A, B), multiplication, multiply, A, B).
whole_number_task(divide(A, B), division, divide, A, B).

productive_obligation(O) :-
    memberchk(O.role, [productive, productive_unpaired]).

deformation_obligation(O) :- O.role == deformation.


%!  curriculum_capability_audit(+MaxGrade, -Audit) is det.
%
%   Compile every loaded IM lesson through MaxGrade into one classification
%   artifact. The result records absence and unrouted operations instead of
%   filling them with cluster aliases.
curriculum_capability_audit(MaxGrade, Audit) :-
    integer(MaxGrade), MaxGrade >= 0,
    cached_curriculum_capability_audit(MaxGrade, Audit),
    !.
curriculum_capability_audit(MaxGrade, Audit) :-
    integer(MaxGrade), MaxGrade >= 0,
    compute_curriculum_capability_audit(MaxGrade, Audit),
    assertz(cached_curriculum_capability_audit(MaxGrade, Audit)).

compute_curriculum_capability_audit(MaxGrade, Audit) :-
    findall(Code,
            ( im_lesson(Code, _, _, grade(Grade), _, _),
              Grade =< MaxGrade ),
            Codes0),
    sort(Codes0, Codes),
    findall(Row,
            ( member(Code, Codes), lightweight_capability_row(Code, Row) ),
            Rows),
    include(row_registered, Rows, RegisteredRows),
    include(row_unattached, Rows, UnattachedRows),
    include(row_partial, Rows, PartialRows),
    length(Rows, LessonCount),
    length(RegisteredRows, RegisteredCount),
    length(UnattachedRows, UnattachedCount),
    length(PartialRows, PartialCount),
    findall(Operation,
            ( member(Row, Rows),
              member(Operation, Row.unrouted_task_operations) ),
            Unrouted0),
    sort(Unrouted0, UnroutedOperations),
    Audit = curriculum_capability_audit{
        through_grade: MaxGrade,
        lesson_count: LessonCount,
        registered_action_contracts: RegisteredCount,
        unattached_contracts: UnattachedCount,
        partial_contracts: PartialCount,
        concrete_task_routes: [addition, subtraction, multiplication,
                               division, fraction, decimal, integer, ratio,
                               algebraic, diagnostic, statistics, geometry,
                               measurement, counting],
        unrouted_operations: UnroutedOperations,
        rows: Rows
    }.


%!  curriculum_capability_graph(+MaxGrade, -Graph) is det.
%
%   Build a navigable graph from the cached audit. Its edges distinguish
%   operation attachment, productive action obligations, deformations, and
%   missing action automata. It does not claim that a whole lesson activity is
%   executable merely because an operation or action is attached.
curriculum_capability_graph(MaxGrade, Graph) :-
    integer(MaxGrade), MaxGrade >= 0,
    cached_curriculum_capability_graph(MaxGrade, Graph),
    !.
curriculum_capability_graph(MaxGrade, Graph) :-
    curriculum_capability_audit(MaxGrade, Audit),
    capability_graph_from_rows(MaxGrade, Audit.rows, Graph),
    assertz(cached_curriculum_capability_graph(MaxGrade, Graph)).


%!  lesson_traversal_row(+LessonCode, -Row) is semidet.
%
%   Execute source-backed task instances only. Operation attachments and task
%   signals are not promoted to instances. Likewise, a registered deformation
%   is a candidate dead end, not evidence that a learner traversed it.
lesson_traversal_row(Code, Row) :-
    lesson_capability_row(Code, Capability),
    traversal_row_from_capability(Capability, Row).

traversal_row_from_capability(Capability, Row) :-
    Code = Capability.lesson,
    findall(instance(Role, Task, Provenance),
            traversal_task_instance(Code, Role-Task, Provenance),
            Instances),
    findall(Execution,
            ( member(Instance, Instances),
              execute_lesson_instance(Code, Instance, Execution) ),
            Executions),
    productive_instance_status(Instances, Executions, ProductiveStatus),
    deformation_instance_status(Capability, Instances, Executions,
                                DeformationStatus),
    traversal_row_status(ProductiveStatus, DeformationStatus, Status),
    Row = curriculum_traversal_row{
        lesson: Code,
        grade: Capability.grade,
        operation_routes: Capability.routed_task_operations,
        productive_obligation_count: Capability.productive_obligation_count,
        deformation_obligation_count: Capability.deformation_obligation_count,
        task_instances: Instances,
        executions: Executions,
        productive_route_status: ProductiveStatus,
        dead_end_status: DeformationStatus,
        status: Status
    }.

traversal_task_instance(Code, RoleTask, Provenance) :-
    lesson_task_instance(Code, RoleTask, Provenance).
traversal_task_instance(Code, RoleTask, Provenance) :-
    compiled_lesson_task_instance(Code, RoleTask, Provenance).

execute_lesson_instance(Code, instance(productive, Task, Provenance),
                        execution(productive, Task, Provenance, Outcome)) :-
    activity_task_path(Code, Task, Outcome).
execute_lesson_instance(Code,
                        instance(deformation(Family), Task, Provenance),
                        execution(deformation(Family), Task, Provenance,
                                  Outcome)) :-
    deformation_task_path(Code, Family, Task, Outcome).

deformation_task_path(Code, Family, Task, Outcome) :-
    task_descriptor(Task, Operation, Requirements),
    lesson_deformation_license(Code, Operation, Family, DeformationKind),
    task_action_operands(Task, Operation, Left, Right),
    run_action_automaton(Operation, DeformationKind, Left, Right,
                         ActionOutcome, Trace),
    ActionOutcome = action_outcome(DeformationKind, Fields),
    member(result(Result), Fields),
    Outcome = candidate_path{
        lesson: Code,
        task: Task,
        operation: Operation,
        source: action_automata_registry,
        scope: reviewed_deformation_route,
        requirements: Requirements,
        deformation_family: Family,
        deformation_kind: DeformationKind,
        result: Result,
        trace: Trace,
        evidence: Fields,
        validation: deformation(Family, DeformationKind)
    },
    !.
deformation_task_path(Code, Family, Task,
                      unsupported{
                          lesson: Code,
                          task: Task,
                          reason: deformation_route_not_executable,
                          deformation_family: Family
                      }).

lesson_deformation_license(Code, Operation, Family, DeformationKind) :-
    lesson_activity_contract(Code, Contract),
    member(Obligation, Contract.strategy_obligations),
    Obligation.operation == Operation,
    Obligation.role == deformation,
    Obligation.kind = DeformationKind,
    Obligation.relation = deformation_of(_, Family),
    !.
lesson_deformation_license(Code, Operation, Family, DeformationKind) :-
    lesson_activity_contract(Code, Contract),
    member(Obligation, Contract.misconception_obligations),
    Obligation.operation == Operation,
    Obligation.registry_status == registered_deformation,
    Obligation.kind = DeformationKind,
    Obligation.relation = deformation_of(_, Family),
    !.

task_action_operands(add(A, B), addition, A, B).
task_action_operands(subtract(A, B), subtraction, A, B).
task_action_operands(multiply(A, B), multiplication, A, B).
task_action_operands(divide(A, B), division, A, B).
task_action_operands(unit_fraction(N, D), fraction, N, D).
task_action_operands(iterate_improper_fraction(Numerator, Denominator),
                     fraction, Numerator, Denominator).
task_action_operands(decimal_value(Numeral, Scale), decimal, Numeral, Scale).
task_action_operands(decimal_multiply(N1, S1, N2, S2), decimal,
                     decimal_pair(N1, S1, N2, S2), ignored).
task_action_operands(decimal_compare(N1, S1, N2, S2), decimal,
                     decimal_pair(N1, S1, N2, S2), ignored).
task_action_operands(decimal_add(N1, S1, N2, S2), decimal,
                     decimal_pair(N1, S1, N2, S2), ignored).
task_action_operands(decimal_subtract(N1, S1, N2, S2), decimal,
                     decimal_pair(N1, S1, N2, S2), ignored).
task_action_operands(regroup_decimal_units(Count, FromScale, ToScale), decimal,
                     decimal_unit_conversion(Count, FromScale, ToScale),
                     ignored).
task_action_operands(signed_add(A, B), integer, A, B).
task_action_operands(scale_ratio(A, B, _Factor), ratio, A, B).
task_action_operands(evaluate_expression(Expression, Assignment), algebraic,
                     Expression, Assignment).
task_action_operands(solve_linear(A, B, C), algebraic,
                     linear_equation(A, B, C),
                     solution_domain(nonnegative_integer)).
task_action_operands(classify_shape(Shape, Attributes, QuarterTurns), geometry,
                     shape(Shape, Attributes), orientation(QuarterTurns)).
task_action_operands(angle_measure(Degrees), geometry, Degrees, unit(degree)).
task_action_operands(rectangle_area(Rows, Columns), geometry, Rows, Columns).
task_action_operands(compare_rectangle_areas(L1, W1, L2, W2, _Unit),
                     geometry, rectangles(L1, W1), rectangle(L2, W2)).
task_action_operands(rectangle_missing_side_from_area(Area, KnownSide, _Unit),
                     geometry, area(Area), known_side(KnownSide)).
task_action_operands(select_area_unit(ExtentClass, Candidates), geometry,
                     area_extent(ExtentClass), candidates(Candidates)).
task_action_operands(unit_cube_volume(Length, Width, Height, _Unit), geometry,
                     prism(Length, Width), Height).
task_action_operands(compare_solid_volumes(CountA, CountB, ExtentA, ExtentB),
                     geometry, solid_cube_counts(CountA, CountB),
                     visual_extents(ExtentA, ExtentB)).
task_action_operands(rectangle_perimeter(Length, Width, Unit), geometry,
                     rectangle(Length, Width), unit(Unit)).
task_action_operands(polygon_perimeter(SideLengths, Unit), geometry,
                     sides(SideLengths), unit(Unit)).
task_action_operands(symmetry_missing_side(Orbits, Perimeter, Unit), geometry,
                     side_orbits(Orbits), perimeter(Perimeter, Unit)).
task_action_operands(rectangle_side_lengths_for_perimeter(Perimeter, _Unit),
                     geometry, Perimeter, side_scope(all)).
task_action_operands(construct_rectangle_with_perimeter(Perimeter, _Unit),
                     geometry, Perimeter, side_scope(one)).
task_action_operands(
    rectangle_missing_side_from_perimeter(Perimeter, Known, _Unit), geometry,
    perimeter(Perimeter), known_side(Known)).
task_action_operands(measure_length(IntervalCount, Subdivisions, Unit),
                     measurement, measure(IntervalCount, Subdivisions),
                     unit(Unit)).
task_action_operands(read_liquid_volume(IntervalCount, Subdivisions, Unit),
                     measurement, measure(IntervalCount, Subdivisions),
                     unit(Unit)).
task_action_operands(convert_measurement(Count, FromUnit, ToUnit, Factor),
                     measurement, quantity(Count, FromUnit),
                     conversion(ToUnit, Factor)).
task_action_operands(measured_quantity_change(Operation, A, B, Unit),
                     measurement, measured_change(Operation, A, B, Unit),
                     ignored).
task_action_operands(count_collection(Count, Base), counting,
                     Count, base(Base)).
task_action_operands(inscribe_cardinality(Count, Base), counting,
                     Count, base(Base)).
task_action_operands(inscribe_place_value(Count, Base), counting,
                     Count, base(Base)).
task_action_operands(compare_numerals_by_place_value(A, B, Base), counting,
                     counts(A, B), base(Base)).
task_action_operands(compare_cardinalities(A, B, ExtentA, ExtentB), counting,
                     counts(A, B), extents(ExtentA, ExtentB)).

area_relation(A, B, less) :- A < B, !.
area_relation(A, B, more) :- A > B, !.
area_relation(_, _, equal).

productive_instance_status(Instances, _Executions,
                           missing(no_concrete_activity_task)) :-
    \+ member(instance(productive, _, _), Instances),
    !.
productive_instance_status(_Instances, Executions, executed) :-
    forall(member(execution(productive, _, _, Outcome), Executions),
           is_dict(Outcome, candidate_path)),
    !.
productive_instance_status(_Instances, Executions,
                           failed(Outcomes)) :-
    findall(Outcome,
            ( member(execution(productive, _, _, Outcome), Executions),
              \+ is_dict(Outcome, candidate_path) ),
            Outcomes).

deformation_instance_status(_Capability, _Instances, Executions, exercised) :-
    member(execution(deformation(_), _, _, Outcome), Executions),
    is_dict(Outcome),
    get_dict(validation, Outcome, deformation(_, _)),
    !.
deformation_instance_status(Capability, Instances, _Executions,
                            missing(no_plausible_deformation_obligation)) :-
    Capability.deformation_obligation_count =:= 0,
    \+ member(instance(deformation(_), _, _), Instances),
    !.
deformation_instance_status(_Capability, Instances, _Executions,
                            registered_not_executed) :-
    \+ member(instance(deformation(_), _, _), Instances),
    !.
deformation_instance_status(_Capability, _Instances, Executions,
                            failed(Outcomes)) :-
    findall(Outcome,
            member(execution(deformation(_), _, _, Outcome), Executions),
            Outcomes).

traversal_row_status(executed, exercised, traversable) :- !.
traversal_row_status(Productive, Deformation,
                     incomplete(productive(Productive),
                                dead_end(Deformation))).


%!  curriculum_traversal_audit(+MaxGrade, -Audit) is det.
%
%   Completion audit for actual task traversal. It is intentionally stricter
%   than curriculum_capability_audit/2: no task instance means incomplete even
%   when every attached operation has a reusable compiler.
curriculum_traversal_audit(MaxGrade, Audit) :-
    integer(MaxGrade), MaxGrade >= 0,
    cached_curriculum_traversal_audit(MaxGrade, Audit),
    !.
curriculum_traversal_audit(MaxGrade, Audit) :-
    integer(MaxGrade), MaxGrade >= 0,
    curriculum_capability_audit(MaxGrade, CapabilityAudit),
    findall(Row,
            ( member(Capability, CapabilityAudit.rows),
              traversal_row_from_capability(Capability, Row) ),
            Rows),
    include(row_traversable, Rows, TraversableRows),
    include(row_missing_task_instance, Rows, MissingTaskRows),
    include(row_dead_end_unexercised, Rows, DeadEndGapRows),
    length(Rows, LessonCount),
    length(TraversableRows, TraversableCount),
    length(MissingTaskRows, MissingTaskCount),
    length(DeadEndGapRows, DeadEndGapCount),
    completion_verdict(LessonCount, TraversableCount, Verdict),
    Audit = curriculum_traversal_audit{
        through_grade: MaxGrade,
        claim_scope: concrete_source_backed_activity_instances,
        lesson_count: LessonCount,
        traversable_activity_contracts: TraversableCount,
        missing_task_instance_count: MissingTaskCount,
        unexercised_dead_end_count: DeadEndGapCount,
        completion: Verdict,
        rows: Rows
    },
    assertz(cached_curriculum_traversal_audit(MaxGrade, Audit)).

row_traversable(Row) :- Row.status == traversable.
row_missing_task_instance(Row) :-
    Row.productive_route_status = missing(no_concrete_activity_task).
row_dead_end_unexercised(Row) :-
    Row.dead_end_status \== exercised.

completion_verdict(Count, Count, complete) :- Count > 0, !.
completion_verdict(_LessonCount, _TraversableCount,
                   incomplete(source_backed_task_and_dead_end_coverage_required)).

capability_graph_from_rows(MaxGrade, Rows, Graph) :-
    findall(Node, (member(Row, Rows), lesson_graph_node(Row, Node)), LessonNodes),
    findall(node(operation(Operation), operation_metadata),
            ( member(Row, Rows), row_operation(Row, Operation) ),
            OperationNodes0),
    sort(OperationNodes0, OperationNodes),
    findall(node(action(Operation, Kind), action_metadata),
            ( member(Row, Rows),
              member(Obligation, Row.action_obligations),
              Operation = Obligation.operation,
              Kind = Obligation.kind ),
            ActionNodes0),
    sort(ActionNodes0, ActionNodes),
    append([LessonNodes, OperationNodes, ActionNodes], Nodes),
    findall(Edge,
            ( member(Row, Rows), row_graph_edge(Row, Edge) ),
            Edges0),
    sort(Edges0, Edges),
    length(LessonNodes, LessonCount),
    length(OperationNodes, OperationCount),
    length(ActionNodes, ActionCount),
    length(Edges, EdgeCount),
    Graph = curriculum_capability_graph{
        through_grade: MaxGrade,
        claim_scope: operation_and_action_obligations_not_full_activity_execution,
        lesson_count: LessonCount,
        operation_count: OperationCount,
        action_count: ActionCount,
        edge_count: EdgeCount,
        nodes: Nodes,
        edges: Edges
    }.

lesson_graph_node(Row,
                  node(lesson(Row.lesson),
                       lesson_metadata(Row.grade, Row.title,
                                       Row.contract_status))).

row_operation(Row, Operation) :-
    member(Operation, Row.operations).
row_operation(Row, Operation) :-
    member(Obligation, Row.action_obligations),
    Operation = Obligation.operation.

row_graph_edge(Row,
               edge(lesson(Row.lesson), operation(Operation),
                    operation_attachment(RouteStatus))) :-
    member(Operation, Row.operations),
    ( memberchk(Operation, Row.routed_task_operations)
    -> RouteStatus = concrete_task_route
    ;  RouteStatus = executor_missing
    ).
row_graph_edge(Row,
               edge(lesson(Row.lesson), action(Operation, Kind), Relation)) :-
    member(Obligation, Row.action_obligations),
    Operation = Obligation.operation,
    Kind = Obligation.kind,
    obligation_graph_relation(Obligation, Relation).
row_graph_edge(Row,
               edge(action(Operation, Kind), operation(Operation),
                    instantiates_operation)) :-
    member(Obligation, Row.action_obligations),
    Operation = Obligation.operation,
    Kind = Obligation.kind.

obligation_graph_relation(Obligation, missing_action_automaton) :-
    Obligation.registry_status == missing_action_automaton,
    !.
obligation_graph_relation(Obligation, possible_deformation(Obligation.relation)) :-
    Obligation.role == deformation,
    !.
obligation_graph_relation(Obligation, productive_action(Obligation.relation)).

reset_curriculum_capability_cache :-
    retractall(cached_curriculum_capability_audit(_, _)),
    retractall(cached_curriculum_capability_graph(_, _)),
    retractall(cached_curriculum_traversal_audit(_, _)).

row_registered(Row) :- Row.contract_status == registered_actions.
row_unattached(Row) :-
    Row.contract_status = unattached(no_strategy_obligations).
row_partial(Row) :- Row.contract_status = partial(_).

lightweight_capability_row(Code, Row) :-
    im_lesson(Code, _ConceptId, Title, grade(Grade), _Unit, _LessonNo),
    !,
    findall(Obligation,
            strategy_obligation(Code, Obligation),
            Obligations0),
    sort(Obligations0, Obligations),
    contract_status(Obligations, Status),
    capability_row_from_obligations(Code, Grade, Title, Status,
                                    Obligations, Row).
