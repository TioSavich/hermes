/** <module> Productive and deformed measurement action automata
 *
 * Linear measure coordinates a fixed unit, its equal subdivisions, and the
 * intervals covered from zero. The paired deformation counts boundary marks
 * as though they were intervals. That error is attested in the local corpus
 * (measurement row 40641 and fraction rows 37572/39635).
 */

:- module(measurement_action_pairs,
          [ run_measurement_action/5,
            measurement_action_cluster/2,
            measurement_action_vocabulary/2,
            productive_measurement_deformation/3,
            measurement_action_misconception_hook/3
          ]).

:- use_module(render(measurement_strip_scene),
              [measurement_strip_render_json/2]).
:- use_module(math(integer_helpers), [add_ints/3, subtract_ints/3]).


run_measurement_action(linear_unit_iteration,
                       measure(IntervalCount, Subdivisions), unit(Unit),
                       Outcome, Trace) :-
    valid_measure(IntervalCount, Subdivisions, Unit),
    measurement_strip_render_json(measure(IntervalCount, Subdivisions, Unit),
                                  Scene),
    successful_scene(Scene),
    reduced_rational(IntervalCount, Subdivisions, Measure),
    Outcome = action_outcome(
                  linear_unit_iteration,
                  [ classification(productive),
                    cluster(measurement_linear_unit_iteration),
                    automaton_state(iterate_equal_intervals_from_zero),
                    vocabulary([measured_attribute, length, unit, equal_unit,
                                subdivision, interval, endpoint, ruler,
                                number_line, fraction, mixed_number]),
                    input(measure(IntervalCount, Subdivisions, unit(Unit))),
                    result(length(Measure, Unit)),
                    expected(length(Measure, Unit)),
                    representation(Scene),
                    invariant(interval_count_not_mark_count),
                    validity(correct)
                  ]),
    Trace = [ establish_length_attribute,
              establish_unit(Unit),
              partition_unit_into_equal_intervals(Subdivisions),
              iterate_interval_from_zero(IntervalCount),
              read_accumulated_length(Measure, Unit)
            ].
run_measurement_action(count_marks_not_intervals,
                       measure(IntervalCount, Subdivisions), unit(Unit),
                       Outcome, Trace) :-
    valid_measure(IntervalCount, Subdivisions, Unit),
    MarkCount is IntervalCount + 1,
    reduced_rational(IntervalCount, Subdivisions, Expected),
    reduced_rational(MarkCount, Subdivisions, Misread),
    Outcome = action_outcome(
                  count_marks_not_intervals,
                  [ classification(deformation),
                    cluster(measurement_linear_unit_iteration),
                    automaton_state(count_both_boundary_marks_as_units),
                    vocabulary([ruler, number_line, tick_mark, endpoint,
                                interval, unit, overcount]),
                    input(measure(IntervalCount, Subdivisions, unit(Unit))),
                    expected(length(Expected, Unit)),
                    result(length(Misread, Unit)),
                    deformation_of(linear_unit_iteration),
                    violated_invariant(interval_count_not_mark_count),
                    validity(incorrect)
                  ]),
    Trace = [ expose_interval_boundary_marks(IntervalCount, MarkCount),
              count_marks_instead_of_spaces,
              overcount_by_one_subunit(Subdivisions)
            ].
run_measurement_action(liquid_volume_scale_reading,
                       measure(IntervalCount, Subdivisions), unit(Unit),
                       Outcome, Trace) :-
    valid_measure(IntervalCount, Subdivisions, Unit),
    measurement_strip_render_json(measure(IntervalCount, Subdivisions, Unit),
                                  Scene),
    successful_scene(Scene),
    reduced_rational(IntervalCount, Subdivisions, Measure),
    Outcome = action_outcome(
                  liquid_volume_scale_reading,
                  [ classification(productive),
                    cluster(measurement_liquid_volume_scale),
                    automaton_state(read_equal_volume_intervals_from_zero),
                    vocabulary([liquid_volume, container, capacity, liter,
                                equal_interval, measurement_scale, fill_level,
                                estimate, draw_volume]),
                    input(measure(IntervalCount, Subdivisions, unit(Unit))),
                    result(volume(Measure, Unit)),
                    expected(volume(Measure, Unit)), representation(Scene),
                    invariant(volume_scale_counts_intervals_not_marks),
                    validity(correct)
                  ]),
    Trace = [ establish_liquid_volume_attribute,
              establish_volume_unit(Unit),
              partition_volume_scale(Subdivisions),
              locate_fill_level_after_intervals(IntervalCount),
              read_liquid_volume(Measure, Unit)
            ].
run_measurement_action(liquid_volume_count_marks_not_intervals,
                       measure(IntervalCount, Subdivisions), unit(Unit),
                       Outcome, Trace) :-
    valid_measure(IntervalCount, Subdivisions, Unit),
    MarkCount is IntervalCount + 1,
    reduced_rational(IntervalCount, Subdivisions, Expected),
    reduced_rational(MarkCount, Subdivisions, Misread),
    measurement_strip_render_json(measure(IntervalCount, Subdivisions, Unit),
                                  Scene),
    successful_scene(Scene),
    Outcome = action_outcome(
                  liquid_volume_count_marks_not_intervals,
                  [ classification(deformation),
                    cluster(measurement_liquid_volume_scale),
                    automaton_state(count_volume_scale_marks_as_intervals),
                    vocabulary([liquid_volume, container, liter,
                                measurement_scale, tick_mark, interval,
                                fill_level, overcount]),
                    input(measure(IntervalCount, Subdivisions, unit(Unit))),
                    result(volume(Misread, Unit)),
                    expected(volume(Expected, Unit)), representation(Scene),
                    deformation_of(liquid_volume_scale_reading),
                    violated_invariant(volume_scale_counts_intervals_not_marks),
                    validity(incorrect)
                  ]),
    Trace = [ expose_volume_scale_marks(IntervalCount, MarkCount),
              count_marks_instead_of_volume_intervals,
              overcount_liquid_volume_by_one_subunit(Subdivisions)
            ].
run_measurement_action(unit_conversion_by_iteration,
                       quantity(Count, FromUnit),
                       conversion(ToUnit, Factor), Outcome, Trace) :-
    valid_unit_conversion(Count, FromUnit, ToUnit, Factor),
    Converted is Count * Factor,
    Outcome = action_outcome(
                  unit_conversion_by_iteration,
                  [ classification(productive),
                    cluster(measurement_composite_unit_conversion),
                    automaton_state(iterate_smaller_units_inside_larger_unit),
                    vocabulary([measurement, unit, composite_unit,
                                conversion_factor, equivalent_quantity,
                                iterate, multiplicative_comparison]),
                    input(quantity(Count, FromUnit)),
                    conversion(ToUnit, Factor),
                    result(quantity(Converted, ToUnit)),
                    expected(quantity(Converted, ToUnit)),
                    representation(unit_conversion_chain(
                                       copies(Count, FromUnit),
                                       factor(Factor),
                                       copies(Converted, ToUnit))),
                    invariant(quantity_preserved_while_unit_count_changes),
                    validity(correct)
                  ]),
    Trace = [ establish_equivalence(one(FromUnit), Factor, ToUnit),
              iterate_conversion_group(Count, Factor),
              multiply_unit_count(Count, Factor, Converted),
              relabel_as_smaller_unit(ToUnit)
            ].
run_measurement_action(change_unit_label_without_scaling,
                       quantity(Count, FromUnit),
                       conversion(ToUnit, Factor), Outcome, Trace) :-
    valid_unit_conversion(Count, FromUnit, ToUnit, Factor),
    Expected is Count * Factor,
    Outcome = action_outcome(
                  change_unit_label_without_scaling,
                  [ classification(deformation),
                    cluster(measurement_composite_unit_conversion),
                    automaton_state(relabel_quantity_without_iterating_unit),
                    vocabulary([measurement, unit, conversion_factor,
                                equivalent_quantity, relabel, unchanged_number]),
                    input(quantity(Count, FromUnit)),
                    conversion(ToUnit, Factor),
                    result(quantity(Count, ToUnit)),
                    expected(quantity(Expected, ToUnit)),
                    representation(unit_label_substitution(
                                       quantity(Count, FromUnit),
                                       quantity(Count, ToUnit))),
                    deformation_of(unit_conversion_by_iteration),
                    violated_invariant(quantity_preserved_while_unit_count_changes),
                    validity(incorrect)
                  ]),
    Trace = [ read_conversion_factor(Factor),
              omit_iteration_by_factor,
              preserve_numeral(Count),
              change_unit_label(FromUnit, ToUnit)
            ].
run_measurement_action(unit_preserving_measured_quantity_change,
                       measured_change(Operation, A, B, Unit), ignored,
                       Outcome, Trace) :-
    measured_change_result(Operation, A, B, ResultNumber),
    Result = quantity(ResultNumber, Unit),
    Outcome = action_outcome(
                  unit_preserving_measured_quantity_change,
                  [ classification(productive),
                    cluster(measurement_quantity_change),
                    automaton_state(preserve_unit_through_quantity_change),
                    vocabulary([measured_quantity, measurement_unit,
                                addition, subtraction, quantity_change,
                                unit_preservation]),
                    input(measured_change(Operation, A, B, Unit)),
                    result(Result), expected(Result),
                    representation(unit_bearing_equation(
                        Operation, quantity(A, Unit), quantity(B, Unit),
                        Result)),
                    invariant(quantities_share_unit_and_result_retains_it),
                    validity(correct)
                  ]),
    Trace = [ establish_common_measurement_unit(Unit),
              perform_grounded_quantity_change(Operation, A, B, ResultNumber),
              retain_measurement_unit(ResultNumber, Unit),
              report_unit_bearing_result(Result)
            ].
run_measurement_action(drop_unit_from_measured_quantity_change,
                       measured_change(Operation, A, B, Unit), ignored,
                       Outcome, Trace) :-
    measured_change_result(Operation, A, B, ResultNumber),
    Expected = quantity(ResultNumber, Unit),
    Outcome = action_outcome(
                  drop_unit_from_measured_quantity_change,
                  [ classification(deformation),
                    cluster(measurement_quantity_change),
                    automaton_state(calculate_bare_numeral_and_discard_unit),
                    vocabulary([measured_quantity, bare_number,
                                unit_omission, quantity_change]),
                    input(measured_change(Operation, A, B, Unit)),
                    result(ResultNumber), expected(Expected),
                    representation(unit_erased_equation(
                        Operation, A, B, ResultNumber)),
                    deformation_of(
                        unit_preserving_measured_quantity_change),
                    violated_invariant(
                        quantities_share_unit_and_result_retains_it),
                    validity(incorrect)
                  ]),
    Trace = [ read_quantity_numerals(A, B),
              perform_grounded_quantity_change(Operation, A, B, ResultNumber),
              discard_measurement_unit(Unit),
              report_bare_numeral(ResultNumber)
            ].


measurement_action_cluster(linear_unit_iteration,
                           measurement_linear_unit_iteration).
measurement_action_cluster(count_marks_not_intervals,
                           measurement_linear_unit_iteration).
measurement_action_cluster(liquid_volume_scale_reading,
                           measurement_liquid_volume_scale).
measurement_action_cluster(liquid_volume_count_marks_not_intervals,
                           measurement_liquid_volume_scale).
measurement_action_cluster(unit_conversion_by_iteration,
                           measurement_composite_unit_conversion).
measurement_action_cluster(change_unit_label_without_scaling,
                           measurement_composite_unit_conversion).
measurement_action_cluster(unit_preserving_measured_quantity_change,
                           measurement_quantity_change).
measurement_action_cluster(drop_unit_from_measured_quantity_change,
                           measurement_quantity_change).

measurement_action_vocabulary(linear_unit_iteration,
                              [measured_attribute, length, unit, equal_unit,
                               subdivision, interval, endpoint, ruler,
                               number_line, fraction, mixed_number]).
measurement_action_vocabulary(count_marks_not_intervals,
                              [ruler, number_line, tick_mark, endpoint,
                               interval, unit, overcount]).
measurement_action_vocabulary(liquid_volume_scale_reading,
                              [liquid_volume, container, capacity, liter,
                               equal_interval, measurement_scale, fill_level,
                               estimate, draw_volume]).
measurement_action_vocabulary(liquid_volume_count_marks_not_intervals,
                              [liquid_volume, container, liter,
                               measurement_scale, tick_mark, interval,
                               fill_level, overcount]).
measurement_action_vocabulary(unit_conversion_by_iteration,
                              [measurement, unit, composite_unit,
                               conversion_factor, equivalent_quantity,
                               iterate, multiplicative_comparison]).
measurement_action_vocabulary(change_unit_label_without_scaling,
                              [measurement, unit, conversion_factor,
                               equivalent_quantity, relabel, unchanged_number]).
measurement_action_vocabulary(unit_preserving_measured_quantity_change,
                              [measured_quantity, measurement_unit, addition,
                               subtraction, quantity_change,
                               unit_preservation]).
measurement_action_vocabulary(drop_unit_from_measured_quantity_change,
                              [measured_quantity, bare_number, unit_omission,
                               quantity_change]).

productive_measurement_deformation(linear_unit_iteration,
                                   count_marks_not_intervals,
                                   count_marks_not_intervals).
productive_measurement_deformation(liquid_volume_scale_reading,
                                   liquid_volume_count_marks_not_intervals,
                                   liquid_volume_count_marks_not_intervals).
productive_measurement_deformation(unit_conversion_by_iteration,
                                   change_unit_label_without_scaling,
                                   change_unit_label_without_scaling).
productive_measurement_deformation(
    unit_preserving_measured_quantity_change,
    drop_unit_from_measured_quantity_change,
    drop_unit_from_measured_quantity_change).

measurement_action_misconception_hook(action_outcome(Kind, Fields),
                                      measurement_productive_monitoring(Kind),
                                      Hook) :-
    member(classification(productive), Fields),
    member(vocabulary(Vocabulary), Fields),
    Hook = action_misconception_hook(
               [ productive_measurement_action(Kind),
                 vocabulary(Vocabulary),
                 monitoring_focus(preserve_equal_interval_unit(Kind)),
                 evidence(Fields)
               ]).
measurement_action_misconception_hook(action_outcome(Kind, Fields), Family,
                                      Hook) :-
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


valid_measure(IntervalCount, Subdivisions, Unit) :-
    integer(IntervalCount),
    IntervalCount > 0,
    integer(Subdivisions),
    Subdivisions > 0,
    atom(Unit).

valid_unit_conversion(Count, FromUnit, ToUnit, Factor) :-
    integer(Count),
    Count >= 0,
    atom(FromUnit),
    atom(ToUnit),
    FromUnit \== ToUnit,
    integer(Factor),
    Factor > 1.

measured_change_result(add, A, B, Result) :-
    maplist(nonnegative_integer, [A, B]),
    add_ints(A, B, Result).
measured_change_result(subtract, A, B, Result) :-
    maplist(nonnegative_integer, [A, B]),
    subtract_ints(A, B, Result).

nonnegative_integer(N) :- integer(N), N >= 0.

successful_scene(Scene) :-
    is_dict(Scene),
    \+ get_dict(error, Scene, _),
    get_dict(frames, Scene, [_|_]).

reduced_rational(Numerator, Denominator, rational(N, D)) :-
    GCD is gcd(abs(Numerator), Denominator),
    N is Numerator // GCD,
    D is Denominator // GCD.
