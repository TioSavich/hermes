/** <module> Divaded fractional units
 *
 * This module is a text-grounded pilot for fractions as divaded units:
 * a part is both inside a partitioned whole and outside it as an iterable
 * unit that can reconstitute the whole.
 *
 * The implementation deliberately avoids using arithmetic shortcuts such as
 * lcm/3 or integer multiplication as the explanatory primitive. Composite
 * structures are built by coordinating recollection tallies, so the important
 * distinction is whether a structure remains available for further operation or
 * collapses to a flat count after activity.
 *
 * This is an operationalization of manuscript commitments, not a parallel
 * fraction theory:
 *   - fraction names are anaphoric and require a referent whole;
 *   - the local base is the executable surface of "fractions as fractal
 *     expansion of the base dialectic";
 *   - fraction-of-fraction cases elaborate the manuscript's FCS/composition
 *     rule while preserving the nested operational history.
 *
 * The main refinements imported from the later N101/Hackenberg/Steffe/Tzur
 * pass are: bounded vs freed outside-status, N101's distributive trace for
 * non-unit fraction products, and Tzur's reversible generator recovery.
 */

:- module(divaded_fractional_units,
          [ divade/4,
            divaded/3,
            inside_partition/3,
            iterable_to_reconstitute/3,
            partitive_fraction/5,
            iterative_fraction/6,
            fractional_connected_sequence/6,
            profiled_fraction_attempt/6,
            whole_number_times_fraction/7,
            unit_fraction_of_unit_fraction/6,
            nonunit_fraction_of_unit_fraction/7,
            unit_fraction_of_nonunit_fraction/7,
            clear_mark_unit_fraction_of_nonunit/6,
            nonunit_fraction_of_nonunit_fraction/8,
            anaphoric_fraction_equivalence/8,
            co_measure_fractions/7,
            add_fractions_by_co_measurement/7,
            subtract_fractions_by_co_measurement/7,
            measurement_divide_fractions/7,
            recover_unit_fraction_generator/6,
            rebuild_whole_from_generator/6,
            denominator_partition_nonunit_error/5,
            division_by_recovered_generator/7,
            improper_fraction_chain_loss/6,
            fraction_misconception_hook/3,
            recursive_divade/7,
            shared_completion/5,
            coordinate_units/4,
            rec_to_int/2
          ]).

:- use_module(formalization(grounded_arithmetic),
              [ recollection_to_integer/2,
                incur_cost/1
              ]).


%!  divade(+Whole, +Base, -Part, -Cycle) is det.
%
%   Create a local completion cycle. Part is inside Whole because it belongs
%   to Parts, and outside Whole because the same Part can be iterated Base
%   times to reconstitute Whole.
divade(Whole, Base, Part, cycle(Base, Whole, Parts)) :-
    positive_recollection(Base),
    Part = unit(divaded(Base, Whole)),
    copies(Base, Part, Parts),
    incur_cost(divaded_partition).


%!  divaded(+Part, +Whole, +Base) is semidet.
%
%   Part is divaded with respect to Whole when it has both inside-partition
%   status and outside-iterable status.
divaded(Part, Whole, Base) :-
    inside_partition(Part, Whole, Base),
    iterable_to_reconstitute(Part, Whole, Base).


%!  inside_partition(+Part, +Whole, +Base) is semidet.
%
%   Part has the inside status of a divaded unit.
inside_partition(unit(divaded(Base, Whole)), Whole, Base).


%!  iterable_to_reconstitute(+Part, +Whole, +Base) is semidet.
%
%   Part has the outside status of a divaded unit: it can be iterated through
%   the local completion cycle back to Whole.
iterable_to_reconstitute(unit(divaded(Base, Whole)), Whole, Base) :-
    positive_recollection(Base).


%!  partitive_fraction(+Count, +Base, +Whole, -State, -Trace) is semidet.
%
%   Build a proper or whole fraction inside the current referent whole. This
%   fails for counts beyond the local completion cycle.
partitive_fraction(Count, Base, Whole, State, Trace) :-
    not_greater_than(Count, Base),
    divade(Whole, Base, Part, Cycle),
    iterate_part(Part, Count, Iterated),
    Trace = [divade(Whole, Base), iterate_inside(Count, Base)],
    State = fraction_state(
                partitive,
                [ referent_whole(Whole),
                  local_base(Base),
                  tick_unit(Part),
                  produced_count(Count),
                  iterated_units(Iterated),
                  fraction_status(bounded_partitive),
                  meaning_source(part_to_whole_comparison),
                  anaphoric_chain_register(depth(two),
                                           chains([referent_whole_chain,
                                                   bounded_part_chain])),
                  foregrounded_relation(part_in_whole),
                  structure_status(enacted),
                  relation(within_whole),
                  evidence(Cycle)
                ]).


%!  iterative_fraction(+Count, +Base, +Whole, +Status, -State, -Trace) is det.
%
%   Build a fraction where the unit fraction is available as an iterable unit.
%   Counts may go beyond the whole if the structure has been made available.
iterative_fraction(Count, Base, Whole, Status, State, Trace) :-
    member(Status, [available_prior, enacted]),
    divade(Whole, Base, Part, Cycle),
    iterate_part(Part, Count, Iterated),
    fraction_relation(Count, Base, Relation),
    Trace = [divade(Whole, Base), iterate_as_unit(Count, Base, Relation)],
    State = fraction_state(
                iterative,
                [ referent_whole(Whole),
                  local_base(Base),
                  tick_unit(Part),
                  produced_count(Count),
                  iterated_units(Iterated),
                  fraction_status(freed_iterative),
                  meaning_source(multiple_of_fractional_unit),
                  anaphoric_chain_register(depth(two),
                                           chains([referent_whole_chain,
                                                   fractional_unit_iteration_chain])),
                  foregrounded_relation(unit_fraction_iteration),
                  structure_status(Status),
                  relation(Relation),
                  evidence(Cycle)
                ]).


%!  fractional_connected_sequence(+LimitCount, +Base, +Whole, +Profile, -State, -Trace) is semidet.
%
%   Build a connected fractional number sequence in a local base, such as
%   fifths counted through 5/5 and onward to 7/5 or 10/5. This is stronger
%   than producing improper fraction language: the original referent-whole
%   chain remains available while the unit fraction is iterated beyond it.
fractional_connected_sequence(LimitCount, Base, Whole, Profile, State, Trace) :-
    Profile = mc3,
    positive_recollection(LimitCount),
    divade(Whole, Base, Part, Cycle),
    build_fractional_sequence(LimitCount, Base, Part, Sequence, SequenceTrace),
    fraction_relation(LimitCount, Base, FinalRelation),
    State = fractional_connected_sequence_state(
                [ referent_whole(Whole),
                  local_base(Base),
                  tick_unit(Part),
                  sequence_limit(LimitCount),
                  sequence(Sequence),
                  completion_marker(fraction(Base, Base)),
                  fraction_status(freed_iterative),
                  meaning_source(multiple_of_fractional_unit),
                  anaphoric_chain_register(depth(two),
                                           chains([referent_whole_chain,
                                                   fractional_unit_iteration_chain])),
                  foregrounded_relation(unit_fraction_iteration),
                  profile(Profile),
                  structure_status(available_prior),
                  final_relation(FinalRelation),
                  evidence(Cycle)
                ]),
    append([preserve_referent_whole(Whole),
            free_unit_fraction_for_iteration(Base)|SequenceTrace],
           [maintain_chain_beyond_whole(fraction(LimitCount, Base), FinalRelation)],
           Trace).


%!  profiled_fraction_attempt(+Learner, +Count, +Base, +Whole, -State, -Trace) is semidet.
%
%   A small learner-profile bridge over the generic fraction automata. Jason
%   and Laura can produce bounded partitive fractions and even improper
%   language, but their beyond-whole attempts collapse the original referent
%   chain. Joe, and Jordan/Linda after reflection, use the freed fractional
%   connected sequence. Jordan/Linda before that reflection reject beyond-whole
%   fractions as outside the partitive task.
profiled_fraction_attempt(Learner, Count, Base, Whole, State, Trace) :-
    bounded_partitive_learner(Learner),
    not_greater_than(Count, Base),
    partitive_fraction(Count, Base, Whole, FractionState, FractionTrace),
    State = learner_fraction_state(
                Learner,
                bounded_partitive_success,
                [ attempted_fraction(fraction(Count, Base)),
                  referent_whole(Whole),
                  scheme(partitive_unit_fractional_scheme),
                  fraction_status(bounded_partitive),
                  meaning_source(part_to_whole_comparison),
                  structure_status(enacted),
                  evidence(FractionState)
                ]),
    Trace = [ use_partitive_fractional_scheme(Learner),
              FractionTrace
            ].
profiled_fraction_attempt(Learner, Count, Base, Whole, State, Trace) :-
    chain_loss_learner(Learner),
    positive_recollection(Count),
    positive_recollection(Base),
    \+ not_greater_than(Count, Base),
    improper_fraction_chain_loss(Count, Base, Whole, mc2, LossState, LossTrace),
    State = learner_fraction_state(
                Learner,
                improper_language_chain_loss,
                [ attempted_fraction(fraction(Count, Base)),
                  referent_whole(Whole),
                  scheme(partitive_unit_fractional_scheme),
                  fraction_status(bounded_partitive),
                  meaning_source(part_to_whole_comparison),
                  produced_language(fraction(Count, Base)),
                  reset_fraction(fraction(Count, Count)),
                  missing_fraction_status(freed_iterative),
                  error_kind(improper_fraction_reset_to_new_whole),
                  evidence(LossState)
                ]),
    Trace = [ attempt_to_iterate_beyond_bounded_whole(Learner),
              LossTrace
            ].
profiled_fraction_attempt(Learner, Count, Base, Whole, State, Trace) :-
    bounded_whole_lock_learner(Learner),
    positive_recollection(Count),
    positive_recollection(Base),
    \+ not_greater_than(Count, Base),
    State = learner_fraction_state(
                Learner,
                bounded_whole_lock,
                [ attempted_fraction(fraction(Count, Base)),
                  referent_whole(Whole),
                  scheme(partitive_unit_fractional_scheme),
                  fraction_status(bounded_partitive),
                  meaning_source(part_to_whole_comparison),
                  rejected_status(freed_iterative),
                  error_kind(beyond_whole_fraction_rejected),
                  needed_perturbation(maintain_referent_while_iterating_beyond_whole)
                ]),
    Trace = [ treat_fraction_as_part_inside_one_whole(Learner),
              reject_beyond_whole_fraction(fraction(Count, Base)),
              need_reflection_on_iterated_unit_fraction_chain
            ].
profiled_fraction_attempt(Learner, Count, Base, Whole, State, Trace) :-
    freed_sequence_learner(Learner),
    fractional_connected_sequence(Count, Base, Whole, mc3, SequenceState, SequenceTrace),
    State = learner_fraction_state(
                Learner,
                freed_iterative_sequence,
                [ attempted_fraction(fraction(Count, Base)),
                  referent_whole(Whole),
                  scheme(fractional_connected_number_sequence),
                  fraction_status(freed_iterative),
                  meaning_source(multiple_of_fractional_unit),
                  structure_status(available_prior),
                  evidence(SequenceState)
                ]),
    Trace = [ use_fractional_connected_number_sequence(Learner),
              SequenceTrace
            ].


%!  whole_number_times_fraction(+Multiplier, +FractionCount, +Base, +Whole, +Profile, -State, -Trace) is semidet.
%
%   Repeat a fractional-unit bundle a whole-number count of times. The result
%   is built by coordinated iteration of same-sized fractional units. If the
%   repeated bundle stays inside the referent whole, bounded partitive status is
%   sufficient; if it goes beyond the whole, MC3 availability is required.
whole_number_times_fraction(Multiplier, FractionCount, Base, Whole, Profile, State, Trace) :-
    positive_recollection(Multiplier),
    positive_recollection(FractionCount),
    positive_recollection(Base),
    member(Profile, [mc2, mc3]),
    coordinate_units(FractionCount, Multiplier, ResultCount, CoordinationTrace),
    whole_number_fraction_result(ResultCount,
                                 Base,
                                 Whole,
                                 Profile,
                                 FractionState,
                                 FractionTrace,
                                 FractionStatus,
                                 MeaningSource,
                                 StructureStatus),
    ResultPart = unit(divaded(Base, Whole)),
    iterate_part(ResultPart, ResultCount, ResultUnits),
    State = fraction_product_state(
                whole_number_times_fraction,
                [ multiplier(Multiplier),
                  repeated_fraction(fraction(FractionCount, Base)),
                  result_fraction(fraction(ResultCount, Base)),
                  result_units(ResultUnits),
                  fraction_status(FractionStatus),
                  meaning_source(MeaningSource),
                  structure_status(StructureStatus),
                  reasoning(repeat_same_fractional_unit_bundle),
                  compressed_algorithm_trace([result_count_from_repeating_fraction_count(FractionCount,
                                                                                         Multiplier,
                                                                                         ResultCount),
                                              denominator_preserved_as_local_base(Base)]),
                  evidence(FractionState)
                ]),
    Trace = [ repeat_fractional_unit_bundle(Multiplier,
                                            fraction(FractionCount, Base),
                                            ResultCount,
                                            CoordinationTrace),
              FractionTrace,
              classify_repeated_fraction_result(FractionStatus)
            ].


%!  unit_fraction_of_unit_fraction(+OperatorBase, +TargetBase, +Whole, +Profile, -State, -Trace) is semidet.
%
%   Model the N101 unit-fraction multiplication case:
%   1/OperatorBase of 1/TargetBase. The TargetBase cycle is built in the
%   original whole; the OperatorBase cycle is then built inside one target
%   part; the result is named by projecting that inner cycle back across the
%   original whole.
unit_fraction_of_unit_fraction(OperatorBase, TargetBase, Whole, Profile, State, Trace) :-
    one_recollection(One),
    recursive_divade(TargetBase,
                     OperatorBase,
                     Whole,
                     unit_fraction_multiplication_goal,
                     Profile,
                     RecursiveState,
                     RecursiveTrace),
    RecursiveState = recursive_state(_,
                                     _,
                                     _,
                                     _,
                                     _,
                                     composite_base(CompositeBase),
                                     _,
                                     _,
                                     _,
                                     structure_status(Status),
                                     _),
    CompositePart = unit(divaded(CompositeBase, Whole)),
    State = fraction_product_state(
                unit_fraction_of_unit_fraction,
                [ referent_whole(Whole),
                  operator_fraction(fraction(One, OperatorBase)),
                  target_fraction(fraction(One, TargetBase)),
                  result_fraction(fraction(One, CompositeBase)),
                  composite_base(CompositeBase),
                  result_units([CompositePart]),
                  structure_status(Status),
                  reasoning(nested_completion_cycle),
                  evidence(RecursiveState)
                ]),
    Trace = [ preserve_referent_whole(Whole),
              make_target_unit_fraction(TargetBase),
              make_operator_unit_fraction_inside_target(OperatorBase),
              project_inner_cycle_across_target_cycle(TargetBase, OperatorBase, CompositeBase),
              RecursiveTrace
            ].


%!  nonunit_fraction_of_unit_fraction(+OperatorCount, +OperatorBase, +TargetBase, +Whole, +Profile, -State, -Trace) is semidet.
%
%   Model N101's "small extension" case, such as 2/3 of 1/5. First make the
%   unit-of-unit part, then count more of those generated small parts.
nonunit_fraction_of_unit_fraction(OperatorCount, OperatorBase, TargetBase, Whole, Profile, State, Trace) :-
    positive_recollection(OperatorCount),
    not_greater_than(OperatorCount, OperatorBase),
    one_recollection(One),
    unit_fraction_of_unit_fraction(OperatorBase,
                                   TargetBase,
                                   Whole,
                                   Profile,
                                   UnitState,
                                   UnitTrace),
    product_state_field(UnitState, result_fraction(fraction(One, CompositeBase))),
    product_state_field(UnitState, structure_status(Status)),
    CompositePart = unit(divaded(CompositeBase, Whole)),
    iterate_part(CompositePart, OperatorCount, ResultUnits),
    State = fraction_product_state(
                nonunit_fraction_of_unit_fraction,
                [ referent_whole(Whole),
                  operator_fraction(fraction(OperatorCount, OperatorBase)),
                  target_fraction(fraction(One, TargetBase)),
                  result_fraction(fraction(OperatorCount, CompositeBase)),
                  composite_base(CompositeBase),
                  result_units(ResultUnits),
                  structure_status(Status),
                  reasoning(count_more_generated_small_parts),
                  evidence(UnitState)
                ]),
    Trace = [ UnitTrace,
              count_generated_small_parts(OperatorCount, CompositeBase)
            ].


%!  unit_fraction_of_nonunit_fraction(+OperatorBase, +TargetCount, +TargetBase, +Whole, +Profile, -State, -Trace) is semidet.
%
%   Model N101's harder contrast case, such as 1/5 of 2/3. The internal
%   target-unit marks are preserved, and the unit-fraction operation is
%   distributed over those visible target units so the result remains nameable
%   in relation to the original whole.
unit_fraction_of_nonunit_fraction(OperatorBase, TargetCount, TargetBase, Whole, Profile, State, Trace) :-
    positive_recollection(TargetCount),
    not_greater_than(TargetCount, TargetBase),
    one_recollection(One),
    unit_fraction_of_unit_fraction(OperatorBase,
                                   TargetBase,
                                   Whole,
                                   Profile,
                                   UnitState,
                                   UnitTrace),
    product_state_field(UnitState, result_fraction(fraction(One, CompositeBase))),
    product_state_field(UnitState, structure_status(Status)),
    divade(Whole, TargetBase, TargetPart, _TargetCycle),
    iterate_part(TargetPart, TargetCount, TargetUnits),
    CompositePart = unit(divaded(CompositeBase, Whole)),
    iterate_part(CompositePart, TargetCount, ResultUnits),
    State = fraction_product_state(
                unit_fraction_of_nonunit_fraction,
                [ referent_whole(Whole),
                  operator_fraction(fraction(One, OperatorBase)),
                  target_fraction(fraction(TargetCount, TargetBase)),
                  result_fraction(fraction(TargetCount, CompositeBase)),
                  target_units(TargetUnits),
                  composite_base(CompositeBase),
                  result_units(ResultUnits),
                  structure_status(Status),
                  reasoning(distribute_over_target_units),
                  evidence(UnitState)
                ]),
    Trace = [ preserve_internal_marks(TargetCount, TargetBase),
              distribute_unit_fraction_over_each_target_unit(OperatorBase, TargetCount),
              UnitTrace,
              collect_one_small_part_from_each_target_unit(TargetCount, CompositeBase)
            ].


%!  clear_mark_unit_fraction_of_nonunit(+OperatorBase, +TargetCount, +TargetBase, +Whole, -State, -Trace) is semidet.
%
%   Model the N101 warning case: clearing the mark between the target units and
%   partitioning the whole non-unit amount. This can produce an amount, but the
%   fraction name is not predictable from the preserved unit structure.
clear_mark_unit_fraction_of_nonunit(OperatorBase, TargetCount, TargetBase, Whole, State, Trace) :-
    positive_recollection(OperatorBase),
    positive_recollection(TargetCount),
    not_greater_than(TargetCount, TargetBase),
    one_recollection(One),
    State = fraction_product_state(
                clear_internal_mark_unit_fraction_of_nonunit,
                [ referent_whole(Whole),
                  operator_fraction(fraction(One, OperatorBase)),
                  target_fraction(fraction(TargetCount, TargetBase)),
                  internal_marks(cleared),
                  produced_amount(part_of_nonunit_target(One, OperatorBase)),
                  naming_status(unavailable_from_reasoning),
                  reasoning(partition_collapsed_nonunit_amount)
                ]),
    Trace = [ erase_target_unit_marks(TargetCount, TargetBase),
              partition_collapsed_target_amount(OperatorBase),
              cannot_project_part_name_to_original_whole
            ].


%!  nonunit_fraction_of_nonunit_fraction(+OperatorCount, +OperatorBase, +TargetCount, +TargetBase, +Whole, +Profile, -State, -Trace) is semidet.
%
%   Model N101's general fraction multiplication case, such as 2/3 of 4/5. The
%   operation is distributed over each target unit; the denominator comes from
%   unit-of-unit coordination, and the numerator comes from taking OperatorCount
%   small parts for each of TargetCount target units. This is the GFCS case in
%   Hackenberg/Tillema terms, so it requires MC3 availability rather than an
%   MC2 structure that is merely enacted and then collapsed.
nonunit_fraction_of_nonunit_fraction(OperatorCount,
                                     OperatorBase,
                                     TargetCount,
                                     TargetBase,
                                     Whole,
                                     Profile,
                                     State,
                                     Trace) :-
    positive_recollection(OperatorCount),
    positive_recollection(TargetCount),
    not_greater_than(OperatorCount, OperatorBase),
    not_greater_than(TargetCount, TargetBase),
    Profile = mc3,
    unit_fraction_of_unit_fraction(OperatorBase,
                                   TargetBase,
                                   Whole,
                                   Profile,
                                   UnitState,
                                   UnitTrace),
    product_state_field(UnitState, result_fraction(fraction(One, CompositeBase))),
    product_state_field(UnitState, structure_status(Status)),
    coordinate_units(OperatorCount, TargetCount, ResultCount, NumeratorTrace),
    CompositePart = unit(divaded(CompositeBase, Whole)),
    iterate_part(CompositePart, OperatorCount, PerTargetBundle),
    iterate_part(CompositePart, ResultCount, ResultUnits),
    State = fraction_product_state(
                nonunit_fraction_of_nonunit_fraction,
                [ referent_whole(Whole),
                  operator_fraction(fraction(OperatorCount, OperatorBase)),
                  target_fraction(fraction(TargetCount, TargetBase)),
                  unit_product(fraction(One, CompositeBase)),
                  per_target_bundle(fraction(OperatorCount, CompositeBase)),
                  per_target_bundle_units(PerTargetBundle),
                  repeated_bundle_count(TargetCount),
                  result_fraction(fraction(ResultCount, CompositeBase)),
                  composite_base(CompositeBase),
                  result_units(ResultUnits),
                  structure_status(Status),
                  reasoning(distribute_nonunit_operator_over_target_units),
                  distributive_algorithm_trace([unit_fraction_core(unit_fraction_of_unit_fraction(OperatorBase, TargetBase),
                                                                   result_unit(fraction(One, CompositeBase))),
                                                bundle_per_target_unit(take(OperatorCount,
                                                                            fraction(One, CompositeBase),
                                                                            fraction(OperatorCount, CompositeBase))),
                                                repeat_bundle(TargetCount,
                                                              fraction(OperatorCount, CompositeBase),
                                                              fraction(ResultCount, CompositeBase))]),
                  compressed_algorithm_trace([result_count_from_repeating_operator_count(OperatorCount, TargetCount, ResultCount),
                                              result_base_from_nested_completion(OperatorBase, TargetBase, CompositeBase)]),
                  evidence(UnitState)
                ]),
    Trace = [ distribute_operator_over_target_units(OperatorCount, OperatorBase, TargetCount, TargetBase),
              UnitTrace,
              form_per_target_bundle(OperatorCount, CompositeBase, PerTargetBundle),
              repeat_per_target_bundle(TargetCount, OperatorCount, ResultCount, NumeratorTrace),
              algorithm_shape_arises_from_distribution(
                  numerator_from_repeated_bundles(OperatorCount, TargetCount, ResultCount),
                  denominator_from_unit_fraction_of_unit_fraction(OperatorBase, TargetBase, CompositeBase)),
              collect_generated_small_parts(ResultCount, CompositeBase)
            ].


%!  anaphoric_fraction_equivalence(+CountA, +ReferentCountA, +CountB, +ReferentCountB, +Base, +Whole, -State, -Trace) is semidet.
%
%   Model the manuscript/N101 referent-whole point: a fraction name is
%   anaphoric. The same quantity can receive different fraction names when the
%   referent changes, such as 1/3 of two wholes and 2/3 of one whole.
anaphoric_fraction_equivalence(CountA,
                               ReferentCountA,
                               CountB,
                               ReferentCountB,
                               Base,
                               Whole,
                               State,
                               Trace) :-
    positive_recollection(CountA),
    positive_recollection(ReferentCountA),
    positive_recollection(CountB),
    positive_recollection(ReferentCountB),
    positive_recollection(Base),
    one_recollection(One),
    coordinate_units(CountA, ReferentCountA, SingleWholePartsA, TraceA),
    coordinate_units(CountB, ReferentCountB, SingleWholePartsB, TraceB),
    SingleWholePartsA = SingleWholePartsB,
    State = anaphoric_fraction_state(
                [ referent_whole(Whole),
                  local_base(Base),
                  first_name(fraction(CountA, Base), referent_wholes(ReferentCountA)),
                  second_name(fraction(CountB, Base), referent_wholes(ReferentCountB)),
                  single_whole_unit_fraction(fraction(One, Base)),
                  quantity_as_single_whole_parts(SingleWholePartsA),
                  reasoning(anaphoric_fraction_reference)
                ]),
    Trace = [ coordinate_first_name_to_single_whole_parts(CountA, ReferentCountA, SingleWholePartsA, TraceA),
              coordinate_second_name_to_single_whole_parts(CountB, ReferentCountB, SingleWholePartsB, TraceB),
              recognize_same_quantity_under_different_referents(SingleWholePartsA)
            ].


%!  co_measure_fractions(+CountA, +BaseA, +CountB, +BaseB, +Profile, -State, -Trace) is semidet.
%
%   Measure two fractions with a shared fractional unit. This is N101's
%   co-measurement step: first find a shared completion cycle, then determine
%   how many shared ticks measure each original fraction.
co_measure_fractions(CountA, BaseA, CountB, BaseB, Profile, State, Trace) :-
    positive_recollection(CountA),
    positive_recollection(CountB),
    one_recollection(One),
    shared_completion(BaseA, BaseB, Profile, SharedState, SharedTrace),
    SharedState = shared_completion(first_base(BaseA),
                                    second_base(BaseB),
                                    shared_base(SharedBase),
                                    profile(Profile),
                                    structure_status(Status)),
    group_count(SharedBase, BaseA, SharedTicksPerA, GroupTraceA),
    group_count(SharedBase, BaseB, SharedTicksPerB, GroupTraceB),
    coordinate_units(SharedTicksPerA, CountA, MeasuredCountA, MeasureTraceA),
    coordinate_units(SharedTicksPerB, CountB, MeasuredCountB, MeasureTraceB),
    State = co_measurement_state(
                [ first_fraction(fraction(CountA, BaseA)),
                  second_fraction(fraction(CountB, BaseB)),
                  co_measurement(fraction(One, SharedBase)),
                  first_as(fraction(MeasuredCountA, SharedBase)),
                  second_as(fraction(MeasuredCountB, SharedBase)),
                  shared_ticks_per_first_unit(SharedTicksPerA),
                  shared_ticks_per_second_unit(SharedTicksPerB),
                  anaphoric_chain_constructed(shared_measurement_chain(SharedBase)),
                  structure_status(Status),
                  reasoning(shared_completion_then_measurement),
                  evidence(SharedState)
                ]),
    Trace = [ find_shared_completion(BaseA, BaseB, SharedBase, SharedTrace),
              measure_first_unit_with_shared_ticks(BaseA, SharedBase, SharedTicksPerA, GroupTraceA),
              measure_second_unit_with_shared_ticks(BaseB, SharedBase, SharedTicksPerB, GroupTraceB),
              scale_first_measurement_by_count(CountA, MeasuredCountA, MeasureTraceA),
              scale_second_measurement_by_count(CountB, MeasuredCountB, MeasureTraceB),
              construct_shared_anaphoric_it(shared_measurement_chain(SharedBase))
            ].


%!  add_fractions_by_co_measurement(+CountA, +BaseA, +CountB, +BaseB, +Profile, -State, -Trace) is semidet.
%
%   Add two fractions only after they have been measured in the same shared
%   fractional unit. This keeps the operation tied to co-measurement rather
%   than treating a common denominator as a disconnected procedure.
add_fractions_by_co_measurement(CountA, BaseA, CountB, BaseB, Profile, State, Trace) :-
    co_measure_fractions(CountA, BaseA, CountB, BaseB, Profile, CoState, CoTrace),
    CoState = co_measurement_state(CoFields),
    member(co_measurement(fraction(One, SharedBase)), CoFields),
    member(first_as(fraction(MeasuredCountA, SharedBase)), CoFields),
    member(second_as(fraction(MeasuredCountB, SharedBase)), CoFields),
    member(structure_status(Status), CoFields),
    rec_append(MeasuredCountA, MeasuredCountB, ResultCount),
    State = fraction_sum_state(
                co_measurement_addition,
                [ first_fraction(fraction(CountA, BaseA)),
                  second_fraction(fraction(CountB, BaseB)),
                  co_measurement(fraction(One, SharedBase)),
                  first_as(fraction(MeasuredCountA, SharedBase)),
                  second_as(fraction(MeasuredCountB, SharedBase)),
                  result_fraction(fraction(ResultCount, SharedBase)),
                  structure_status(Status),
                  reasoning(add_same_sized_shared_ticks),
                  evidence(CoState)
                ]),
    Trace = [ CoTrace,
              join_same_sized_shared_ticks(MeasuredCountA, MeasuredCountB, ResultCount, SharedBase)
            ].


%!  subtract_fractions_by_co_measurement(+CountA, +BaseA, +CountB, +BaseB, +Profile, -State, -Trace) is semidet.
%
%   Subtract two fractions only after measuring both in the same shared
%   fractional unit. This is the subtraction twin of co-measurement addition:
%   the operation removes shared ticks, and fails when the subtrahend is larger
%   than the minuend in that shared measurement.
subtract_fractions_by_co_measurement(CountA, BaseA, CountB, BaseB, Profile, State, Trace) :-
    co_measure_fractions(CountA, BaseA, CountB, BaseB, Profile, CoState, CoTrace),
    CoState = co_measurement_state(CoFields),
    member(co_measurement(fraction(One, SharedBase)), CoFields),
    member(first_as(fraction(MeasuredCountA, SharedBase)), CoFields),
    member(second_as(fraction(MeasuredCountB, SharedBase)), CoFields),
    member(structure_status(Status), CoFields),
    rec_difference(MeasuredCountA, MeasuredCountB, ResultCount),
    fraction_relation(ResultCount, SharedBase, ResultRelation),
    State = fraction_difference_state(
                co_measurement_subtraction,
                [ minuend_fraction(fraction(CountA, BaseA)),
                  subtrahend_fraction(fraction(CountB, BaseB)),
                  co_measurement(fraction(One, SharedBase)),
                  minuend_as(fraction(MeasuredCountA, SharedBase)),
                  subtrahend_as(fraction(MeasuredCountB, SharedBase)),
                  result_fraction(fraction(ResultCount, SharedBase)),
                  result_relation(ResultRelation),
                  structure_status(Status),
                  reasoning(remove_same_sized_shared_ticks),
                  evidence(CoState)
                ]),
    Trace = [ CoTrace,
              remove_same_sized_shared_ticks(MeasuredCountA, MeasuredCountB, ResultCount, SharedBase)
            ].


%!  measurement_divide_fractions(+TotalCount, +TotalBase, +GroupCount, +GroupBase, +Profile, -State, -Trace) is semidet.
%
%   Divide fractions using N101's measurement meaning: how many group-size
%   amounts fit in the total amount? Both quantities are first measured with a
%   shared fractional unit; then the group-size count is repeatedly fit into
%   the total count. A leftover is named as a fraction of the group size.
measurement_divide_fractions(TotalCount, TotalBase, GroupCount, GroupBase, Profile, State, Trace) :-
    co_measure_fractions(TotalCount, TotalBase, GroupCount, GroupBase, Profile, CoState, CoTrace),
    CoState = co_measurement_state(CoFields),
    member(co_measurement(fraction(One, SharedBase)), CoFields),
    member(first_as(fraction(MeasuredTotal, SharedBase)), CoFields),
    member(second_as(fraction(MeasuredGroup, SharedBase)), CoFields),
    member(structure_status(Status), CoFields),
    group_count_with_remainder(MeasuredTotal,
                               MeasuredGroup,
                               QuotientWhole,
                               RemainderSharedTicks,
                               DivisionTrace),
    quotient_kind(RemainderSharedTicks, QuotientKind),
    State = fraction_division_state(
                measurement_division,
                [ total_fraction(fraction(TotalCount, TotalBase)),
                  group_size_fraction(fraction(GroupCount, GroupBase)),
                  co_measurement(fraction(One, SharedBase)),
                  total_as(fraction(MeasuredTotal, SharedBase)),
                  group_size_as(fraction(MeasuredGroup, SharedBase)),
                  quotient_whole_count(QuotientWhole),
                  quotient_remainder_fraction(fraction(RemainderSharedTicks, MeasuredGroup)),
                  quotient_kind(QuotientKind),
                  structure_status(Status),
                  reasoning(measure_how_many_group_sizes_fit),
                  evidence(CoState)
                ]),
    Trace = [ CoTrace,
              count_group_size_fits(MeasuredTotal, MeasuredGroup, QuotientWhole, RemainderSharedTicks, DivisionTrace)
            ].


%!  recover_unit_fraction_generator(+NonunitCount, +Base, +Whole, +Profile, -State, -Trace) is semidet.
%
%   Reverse the construction of a non-unit fraction. Given N/Base, partition
%   that produced non-unit amount by N to recover the generating unit fraction
%   1/Base. This is Tzur's reversible fraction conception.
recover_unit_fraction_generator(NonunitCount, Base, Whole, Profile, State, Trace) :-
    reversible_profile_status(Profile, Status),
    positive_recollection(NonunitCount),
    one_recollection(One),
    iterative_fraction(NonunitCount, Base, Whole, available_prior, FractionState, FractionTrace),
    Generator = unit(divaded(Base, Whole)),
    iterate_part(Generator, NonunitCount, ReconstructedGiven),
    State = reversible_generator_state(
                [ given_fraction(fraction(NonunitCount, Base)),
                  referent_whole(Whole),
                  partition_nonunit_by(NonunitCount),
                  recovered_generator_fraction(fraction(One, Base)),
                  recovered_generator_unit(Generator),
                  reconstructs_given_by_iterating(NonunitCount),
                  reconstructed_given_units(ReconstructedGiven),
                  fraction_status(reversible_generator),
                  structure_status(Status),
                  evidence(FractionState)
                ]),
    Trace = [ FractionTrace,
              hold_nonunit_fraction_as_composite_unit(NonunitCount, Base),
              partition_nonunit_by_its_count(NonunitCount),
              recover_generator(fraction(One, Base)),
              verify_by_reiterating_generator(NonunitCount)
            ].


%!  rebuild_whole_from_generator(+NonunitCount, +Base, +Whole, +Profile, -State, -Trace) is semidet.
%
%   Recover 1/Base from N/Base and rebuild the original whole by iterating the
%   recovered generator Base times. When N <= Base, also record how many
%   generator units complete the given fraction to the whole.
rebuild_whole_from_generator(NonunitCount, Base, Whole, Profile, State, Trace) :-
    recover_unit_fraction_generator(NonunitCount, Base, Whole, Profile, RecoveryState, RecoveryTrace),
    RecoveryState = reversible_generator_state(RecoveryFields),
    member(recovered_generator_fraction(fraction(One, Base)), RecoveryFields),
    member(recovered_generator_unit(Generator), RecoveryFields),
    member(structure_status(Status), RecoveryFields),
    iterate_part(Generator, Base, WholeUnits),
    completion_relation(NonunitCount, Base, CompletionRelation),
    State = reversible_rebuild_state(
                [ given_fraction(fraction(NonunitCount, Base)),
                  recovered_generator_fraction(fraction(One, Base)),
                  rebuilt_whole_fraction(fraction(Base, Base)),
                  rebuilt_whole_units(WholeUnits),
                  completion_relation(CompletionRelation),
                  structure_status(Status),
                  reasoning(rebuild_whole_from_recovered_generator),
                  evidence(RecoveryState)
                ]),
    Trace = [ RecoveryTrace,
              iterate_recovered_generator_to_whole(Base),
              CompletionRelation
            ].


%!  denominator_partition_nonunit_error(+NonunitCount, +Base, +Whole, -State, -Trace) is semidet.
%
%   Model the denominator-driven error in Tzur's reversible-fraction work:
%   partitioning an unmarked N/Base amount by Base rather than by N. This does
%   not recover the generator 1/Base.
denominator_partition_nonunit_error(NonunitCount, Base, Whole, State, Trace) :-
    positive_recollection(NonunitCount),
    positive_recollection(Base),
    one_recollection(One),
    coordinate_units(Base, Base, ErrorBase, ErrorBaseTrace),
    State = reversible_generator_error_state(
                [ given_fraction(fraction(NonunitCount, Base)),
                  referent_whole(Whole),
                  attempted_partition_by(Base),
                  needed_partition_by(NonunitCount),
                  produced_piece_fraction(fraction(NonunitCount, ErrorBase)),
                  intended_generator_fraction(fraction(One, Base)),
                  error_kind(denominator_driven_partition_of_nonunit),
                  continued_chain(denominator_chain),
                  needed_chain(nonunit_fraction_as_composite_chain),
                  naming_status(does_not_recover_generator),
                  evidence(ErrorBaseTrace)
                ]),
    Trace = [ hold_nonunit_fraction_as_if_it_were_whole(NonunitCount, Base),
              partition_by_denominator(Base),
              produce_piece(fraction(NonunitCount, ErrorBase)),
              fail_to_recover_generator(fraction(One, Base))
            ].


%!  improper_fraction_chain_loss(+Count, +Base, +Whole, +Profile, -State, -Trace) is semidet.
%
%   Model the manuscript/fragment failure: the learner iterates a unit fraction
%   beyond the referent whole but loses the chain connecting the unit fraction
%   back to that original whole. The produced quantity is then reset as its own
%   whole, e.g. 7/5 collapses into 7/7.
improper_fraction_chain_loss(Count, Base, Whole, Profile, State, Trace) :-
    member(Profile, [mc1, mc2]),
    positive_recollection(Count),
    positive_recollection(Base),
    \+ not_greater_than(Count, Base),
    divade(Whole, Base, Part, Cycle),
    iterate_part(Part, Count, IteratedUnits),
    State = anaphoric_chain_loss_state(
                [ intended_fraction(fraction(Count, Base)),
                  reset_fraction(fraction(Count, Count)),
                  referent_whole(Whole),
                  original_completion_chain(fraction(Base, Base)),
                  produced_quantity_chain(fraction(Count, Base)),
                  retained_chain(produced_quantity_as_whole_chain),
                  lost_chain(original_referent_whole_chain),
                  profile(Profile),
                  error_kind(improper_fraction_reset_to_new_whole),
                  structure_status(collapsed),
                  evidence(Cycle)
                ]),
    Trace = [ iterate_unit_fraction_beyond_whole(Count, Base, IteratedUnits),
              lose_chain(original_referent_whole_chain),
              retain_chain(produced_quantity_as_whole_chain),
              reset_completion_norm(Count),
              rename_result(fraction(Count, Count))
            ].


%!  division_by_recovered_generator(+TotalCount, +TotalBase, +GroupCount, +GroupBase, +Profile, -State, -Trace) is semidet.
%
%   Derive a quotient by recovering the divisor's generating unit fraction.
%   For Total / (GroupCount/GroupBase), recover 1/GroupBase from the divisor,
%   measure the total in that generator scale, then count GroupCount generator
%   units as one group. The quotient fraction is a record of that measurement,
%   not a primitive invert-and-multiply rule.
division_by_recovered_generator(TotalCount, TotalBase, GroupCount, GroupBase, Profile, State, Trace) :-
    recover_unit_fraction_generator(GroupCount,
                                    GroupBase,
                                    unit(group_size),
                                    Profile,
                                    RecoveryState,
                                    RecoveryTrace),
    one_recollection(One),
    co_measure_fractions(TotalCount, TotalBase, One, GroupBase, Profile, CoState, CoTrace),
    CoState = co_measurement_state(CoFields),
    member(co_measurement(fraction(One, SharedBase)), CoFields),
    member(first_as(fraction(MeasuredTotal, SharedBase)), CoFields),
    member(second_as(fraction(GeneratorSharedTicks, SharedBase)), CoFields),
    member(structure_status(Status), CoFields),
    coordinate_units(GeneratorSharedTicks, GroupCount, SharedTicksPerGroup, GroupTrace),
    State = fraction_division_state(
                reversible_measurement_division,
                [ total_fraction(fraction(TotalCount, TotalBase)),
                  group_size_fraction(fraction(GroupCount, GroupBase)),
                  recovered_group_generator(fraction(One, GroupBase)),
                  co_measurement(fraction(One, SharedBase)),
                  total_as(fraction(MeasuredTotal, SharedBase)),
                  generator_as(fraction(GeneratorSharedTicks, SharedBase)),
                  group_size_as_generator_bundle(GroupCount),
                  group_size_as_shared_ticks(SharedTicksPerGroup),
                  quotient_fraction(fraction(MeasuredTotal, SharedTicksPerGroup)),
                  structure_status(Status),
                  reasoning(recover_generator_then_measure_groups),
                  algorithm_trace([recover_generator_from_divisor(GroupCount, GroupBase),
                                   measure_total_in_generator_scale(MeasuredTotal, SharedBase),
                                   make_one_group_from_generator_units(GroupCount, GeneratorSharedTicks, SharedTicksPerGroup),
                                   quotient_as_total_ticks_over_group_ticks(MeasuredTotal, SharedTicksPerGroup)]),
                  evidence([RecoveryState, CoState])
                ]),
    Trace = [ RecoveryTrace,
              CoTrace,
              bundle_recovered_generators_into_group(GroupCount, GeneratorSharedTicks, SharedTicksPerGroup, GroupTrace),
              quotient_as_fraction_of_groups(MeasuredTotal, SharedTicksPerGroup)
            ].


%!  fraction_misconception_hook(+State, -Family, -Hook) is nondet.
%
%   Map a fraction kernel state to misconception families that clustering can
%   attach without re-deriving the theory. Productive states usually name the
%   fragile resource; error states name the observed failure.
fraction_misconception_hook(fraction_state(partitive, Fields),
                            bounded_whole_lock,
                            misconception_hook(
                                [ productive_resource(partitive_fractional_scheme),
                                  fragile_status(bounded_partitive),
                                  risk(apply_inside_whole_fraction_status_beyond_the_whole),
                                  evidence(Fields)
                                ])).
fraction_misconception_hook(fraction_product_state(clear_internal_mark_unit_fraction_of_nonunit, Fields),
                            clear_the_mark_failure,
                            misconception_hook(
                                [ productive_resource(partition_nonunit_amount),
                                  failure(loses_internal_target_unit_marks),
                                  missing_reasoning(distribute_over_visible_units),
                                  evidence(Fields)
                                ])).
fraction_misconception_hook(fraction_product_state(nonunit_fraction_of_nonunit_fraction, Fields),
                            premature_component_arithmetic,
                            misconception_hook(
                                [ productive_resource(compressed_algorithm_trace),
                                  risk(use_numerator_denominator_products_without_distribution),
                                  protective_reasoning(distributive_algorithm_trace),
                                  evidence(Fields)
                                ])).
fraction_misconception_hook(fraction_product_state(whole_number_times_fraction, Fields),
                            premature_component_arithmetic,
                            misconception_hook(
                                [ productive_resource(repeat_same_fractional_unit_bundle),
                                  risk(multiply_numerator_without_iterated_unit_meaning),
                                  protective_reasoning(repeated_fractional_unit_bundle),
                                  evidence(Fields)
                                ])).
fraction_misconception_hook(anaphoric_fraction_state(Fields),
                            referent_drift,
                            misconception_hook(
                                [ productive_resource(anaphoric_fraction_reference),
                                  risk(name_fraction_without_preserving_referent_whole),
                                  evidence(Fields)
                                ])).
fraction_misconception_hook(anaphoric_chain_loss_state(Fields),
                            improper_fraction_reset,
                            misconception_hook(
                                [ failure(loses_original_referent_whole_chain),
                                  repair_needed(maintain_fractional_unit_iteration_chain),
                                  evidence(Fields)
                                ])).
fraction_misconception_hook(learner_fraction_state(_Learner, improper_language_chain_loss, Fields),
                            improper_fraction_reset,
                            misconception_hook(
                                [ failure(produces_improper_language_without_freed_iterative_status),
                                  repair_needed(maintain_fractional_unit_iteration_chain),
                                  evidence(Fields)
                                ])).
fraction_misconception_hook(learner_fraction_state(_Learner, bounded_whole_lock, Fields),
                            bounded_whole_lock,
                            misconception_hook(
                                [ failure(rejects_beyond_whole_fraction),
                                  missing_status(freed_iterative),
                                  evidence(Fields)
                                ])).
fraction_misconception_hook(co_measurement_state(Fields),
                            common_denominator_proceduralism,
                            misconception_hook(
                                [ productive_resource(shared_measurement_chain),
                                  risk(treat_shared_denominator_as_symbolic_procedure),
                                  protective_reasoning(measure_both_fractions_with_same_size_unit),
                                  evidence(Fields)
                                ])).
fraction_misconception_hook(fraction_sum_state(co_measurement_addition, Fields),
                            common_denominator_proceduralism,
                            misconception_hook(
                                [ productive_resource(add_same_sized_shared_ticks),
                                  risk(add_after_denominator_change_without_co_measurement),
                                  evidence(Fields)
                                ])).
fraction_misconception_hook(fraction_difference_state(co_measurement_subtraction, Fields),
                            common_denominator_proceduralism,
                            misconception_hook(
                                [ productive_resource(remove_same_sized_shared_ticks),
                                  risk(subtract_after_denominator_change_without_co_measurement),
                                  evidence(Fields)
                                ])).
fraction_misconception_hook(reversible_generator_error_state(Fields),
                            denominator_driven_reversibility_failure,
                            misconception_hook(
                                [ failure(partitions_nonunit_fraction_by_denominator),
                                  repair_needed(partition_nonunit_fraction_by_its_count),
                                  evidence(Fields)
                                ])).
fraction_misconception_hook(fraction_division_state(reversible_measurement_division, Fields),
                            premature_invert_and_multiply,
                            misconception_hook(
                                [ productive_resource(recover_generator_then_measure_groups),
                                  risk(use_invert_and_multiply_without_recovered_generator),
                                  evidence(Fields)
                                ])).


%!  recursive_divade(+OuterBase, +InnerBase, +Whole, +GoalKind, +Profile, -State, -Trace) is semidet.
%
%   Coordinate one completion cycle inside another. Profile models the
%   Hackenberg/Tillema distinction between structures produced in activity and
%   structures available as material for further operation.
recursive_divade(OuterBase, InnerBase, Whole, GoalKind, Profile, State, Trace) :-
    profile_recursive_status(Profile, GoalKind, Status),
    divade(Whole, OuterBase, OuterPart, OuterCycle),
    divade(OuterPart, InnerBase, InnerPart, InnerCycle),
    coordinate_units(OuterBase, InnerBase, CompositeBase, CoordinationTrace),
    Trace = [divade(Whole, OuterBase),
             divade(OuterPart, InnerBase),
             coordinate(OuterBase, InnerBase, CompositeBase, CoordinationTrace)],
    State = recursive_state(goal(GoalKind),
                            profile(Profile),
                            referent_whole(Whole),
                            outer_base(OuterBase),
                            inner_base(InnerBase),
                            composite_base(CompositeBase),
                            outer_part(OuterPart),
                            inner_part(InnerPart),
                            anaphoric_chain_register(depth(three),
                                                     chains([referent_whole_chain,
                                                             outer_part_chain,
                                                             inner_part_chain])),
                            structure_status(Status),
                            evidence([OuterCycle, InnerCycle])).


%!  shared_completion(+BaseA, +BaseB, +Profile, -State, -Trace) is semidet.
%
%   Search for a shared completion cycle by stepping through BaseA-sized
%   completions until the candidate can also be grouped by BaseB. This is the
%   text-compatible alternative to starting with lcm.
shared_completion(BaseA, BaseB, Profile, State, Trace) :-
    profile_shared_status(Profile, Status),
    coordinate_until_shared(BaseA, BaseB, Shared, Trace),
    State = shared_completion(first_base(BaseA),
                              second_base(BaseB),
                              shared_base(Shared),
                              profile(Profile),
                              structure_status(Status)).


%!  coordinate_units(+UnitSize, +UnitCount, -Composite, -Trace) is det.
%
%   Build a composite unit by inserting UnitSize into each of UnitCount units.
coordinate_units(UnitSize, UnitCount, Composite, Trace) :-
    positive_recollection(UnitSize),
    positive_recollection(UnitCount),
    coordinate_units_(UnitCount, UnitSize, recollection([]), Composite, [], RevTrace),
    reverse(RevTrace, Trace),
    incur_cost(units_coordination).

coordinate_units_(recollection([]), _UnitSize, Acc, Acc, Trace, Trace).
coordinate_units_(recollection([_|Rest]), UnitSize, Acc, Composite, TraceIn, TraceOut) :-
    rec_append(Acc, UnitSize, Next),
    coordinate_units_(recollection(Rest),
                      UnitSize,
                      Next,
                      Composite,
                      [insert(UnitSize, Next)|TraceIn],
                      TraceOut).


coordinate_until_shared(BaseA, BaseB, Shared, Trace) :-
    coordinate_until_shared_(BaseA, BaseB, BaseA, [], Shared, RevTrace),
    reverse(RevTrace, Trace).

coordinate_until_shared_(_BaseA, BaseB, Candidate, TraceIn, Candidate, [try(Candidate, shared)|TraceIn]) :-
    exact_grouping(Candidate, BaseB),
    !,
    incur_cost(shared_completion).
coordinate_until_shared_(BaseA, BaseB, Candidate, TraceIn, Shared, TraceOut) :-
    rec_append(Candidate, BaseA, NextCandidate),
    coordinate_until_shared_(BaseA,
                             BaseB,
                             NextCandidate,
                             [try(Candidate, not_shared)|TraceIn],
                             Shared,
                             TraceOut).


profile_recursive_status(mc1, explicit_partitioning_goal, enacted).
profile_recursive_status(mc2, _GoalKind, enacted_then_collapsed).
profile_recursive_status(mc3, _GoalKind, available_prior).

profile_shared_status(mc2, enacted_then_collapsed).
profile_shared_status(mc3, available_prior).

reversible_profile_status(mc3, available_prior).


bounded_partitive_learner(jason).
bounded_partitive_learner(laura).
bounded_partitive_learner(jordan_initial).
bounded_partitive_learner(linda_initial).

chain_loss_learner(jason).
chain_loss_learner(laura).

bounded_whole_lock_learner(jordan_initial).
bounded_whole_lock_learner(linda_initial).

freed_sequence_learner(joe).
freed_sequence_learner(melissa).
freed_sequence_learner(jordan_reflected).
freed_sequence_learner(linda_reflected).


whole_number_fraction_result(ResultCount,
                             Base,
                             Whole,
                             _Profile,
                             FractionState,
                             FractionTrace,
                             bounded_partitive,
                             part_to_whole_comparison,
                             enacted) :-
    not_greater_than(ResultCount, Base),
    !,
    partitive_fraction(ResultCount, Base, Whole, FractionState, FractionTrace).
whole_number_fraction_result(ResultCount,
                             Base,
                             Whole,
                             mc3,
                             FractionState,
                             FractionTrace,
                             freed_iterative,
                             multiple_of_fractional_unit,
                             available_prior) :-
    \+ not_greater_than(ResultCount, Base),
    iterative_fraction(ResultCount, Base, Whole, available_prior, FractionState, FractionTrace).


build_fractional_sequence(LimitCount, Base, Part, Sequence, Trace) :-
    one_recollection(One),
    build_fractional_sequence_(One, LimitCount, Base, Part, Sequence, Trace).

build_fractional_sequence_(Current, LimitCount, Base, Part, [Entry|RestSequence], [TraceEntry|RestTrace]) :-
    not_greater_than(Current, LimitCount),
    iterate_part(Part, Current, IteratedUnits),
    sequence_entry_relation(Current, Base, Relation),
    Entry = fractional_sequence_entry(fraction(Current, Base),
                                      iterated_units(IteratedUnits),
                                      relation(Relation)),
    TraceEntry = name_fraction_tick(Current, Base, Relation),
    (   Current = LimitCount
    ->  RestSequence = [],
        RestTrace = []
    ;   one_recollection(One),
        rec_append(Current, One, Next),
        build_fractional_sequence_(Next,
                                   LimitCount,
                                   Base,
                                   Part,
                                   RestSequence,
                                   RestTrace)
    ).


sequence_entry_relation(Count, Base, completes_whole) :-
    Count = Base,
    !.
sequence_entry_relation(Count, Base, within_whole) :-
    not_greater_than(Count, Base),
    !.
sequence_entry_relation(_Count, _Base, beyond_whole_preserving_referent).


fraction_relation(Count, Base, within_whole) :-
    not_greater_than(Count, Base),
    !.
fraction_relation(_Count, _Base, extends_beyond_whole).


iterate_part(_Part, recollection([]), []).
iterate_part(Part, recollection([_|Rest]), [Part|Units]) :-
    iterate_part(Part, recollection(Rest), Units).


copies(Base, Item, Copies) :-
    iterate_part(Item, Base, Copies).


positive_recollection(recollection([_|_])).


not_greater_than(recollection([]), _).
not_greater_than(recollection([_|As]), recollection([_|Bs])) :-
    not_greater_than(recollection(As), recollection(Bs)).


exact_grouping(recollection([]), Base) :-
    positive_recollection(Base).
exact_grouping(recollection(Tallies), recollection(BaseTallies)) :-
    BaseTallies \= [],
    append(BaseTallies, RestTallies, Tallies),
    exact_grouping(recollection(RestTallies), recollection(BaseTallies)).


group_count(Total, GroupSize, Count, Trace) :-
    positive_recollection(GroupSize),
    group_count_(Total, GroupSize, recollection([]), Count, [], RevTrace),
    reverse(RevTrace, Trace).

group_count_(recollection([]), _GroupSize, Count, Count, Trace, Trace).
group_count_(recollection(Tallies), recollection(GroupTallies), Acc, Count, TraceIn, TraceOut) :-
    GroupTallies \= [],
    append(GroupTallies, RestTallies, Tallies),
    one_recollection(One),
    rec_append(Acc, One, NextAcc),
    group_count_(recollection(RestTallies),
                 recollection(GroupTallies),
                 NextAcc,
                 Count,
                 [group(recollection(GroupTallies), NextAcc)|TraceIn],
                 TraceOut).


group_count_with_remainder(Total, GroupSize, Count, Remainder, Trace) :-
    positive_recollection(GroupSize),
    group_count_with_remainder_(Total, GroupSize, recollection([]), Count, Remainder, [], RevTrace),
    reverse(RevTrace, Trace).

group_count_with_remainder_(Total, GroupSize, Acc, Count, Remainder, TraceIn, TraceOut) :-
    (   remove_group(Total, GroupSize, Rest)
    ->  one_recollection(One),
        rec_append(Acc, One, NextAcc),
        group_count_with_remainder_(Rest,
                                    GroupSize,
                                    NextAcc,
                                    Count,
                                    Remainder,
                                    [fit(GroupSize, NextAcc)|TraceIn],
                                    TraceOut)
    ;   Count = Acc,
        Remainder = Total,
        TraceOut = [remainder(Total)|TraceIn]
    ).


remove_group(recollection(TotalTallies), recollection(GroupTallies), recollection(RestTallies)) :-
    GroupTallies \= [],
    append(GroupTallies, RestTallies, TotalTallies).


quotient_kind(Remainder, exact) :-
    zero_recollection(Remainder),
    !.
quotient_kind(_Remainder, with_remainder).


completion_relation(NonunitCount, Base, completes_with(CompletionCount)) :-
    rec_difference(Base, NonunitCount, CompletionCount),
    !.
completion_relation(NonunitCount, Base, already_extends_beyond_whole(NonunitCount, Base)).


rec_difference(recollection(WholeTallies), recollection(PartTallies), recollection(RestTallies)) :-
    append(PartTallies, RestTallies, WholeTallies).


rec_append(recollection(A), recollection(B), recollection(C)) :-
    append(A, B, C).


zero_recollection(recollection([])).


one_recollection(recollection([tally])).


product_state_field(fraction_product_state(_Kind, Fields), Field) :-
    member(Field, Fields).


rec_to_int(Rec, Int) :-
    recollection_to_integer(Rec, Int).
