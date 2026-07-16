/** <module> Counting, inscription, and cardinality-comparison actions
 *
 * These actions expose the K-2 counting resources through the shared registry.
 * Counting coordinates one count word with one object and retains the final
 * word as cardinality. Inscription externalizes that cardinality in a chosen
 * base. Comparison uses one-to-one matching; its paired deformation substitutes
 * spatial extent for cardinality, attested in corpus row 39409.
 */

:- module(counting_action_pairs,
          [ run_counting_action/5,
            counting_action_cluster/2,
            counting_action_vocabulary/2,
            productive_counting_deformation/3,
            counting_action_misconception_hook/3
          ]).

:- use_module(render(set_grouping_scene), [set_grouping_render_json/2]).
:- use_module(math(recursive_unit_actions),
              [ integer_numeral/3,
                numeral_unit_tree/2,
                numeral_action_witness/3,
                numeral_plan_deformation/4
              ]).


run_counting_action(enumerate_collection_one_to_one, Count, base(Base),
                    Outcome, Trace) :-
    valid_small_count(Count),
    valid_base(Base),
    set_grouping_render_json(subitize(auto, Count), Scene),
    successful_scene(Scene),
    integer_numeral(Count, Base, Numeral),
    count_steps(Count, Steps),
    Outcome = action_outcome(
                  enumerate_collection_one_to_one,
                  [ classification(productive),
                    cluster(counting_cardinality_coordination),
                    automaton_state(pair_one_count_word_with_each_object),
                    vocabulary([collection, object, one_to_one,
                                stable_order, count_word, cardinality,
                                last_word_principle, numeral]),
                    input(collection_size(Count)),
                    result(cardinality(Count)),
                    expected(cardinality(Count)),
                    inscription(Numeral),
                    representation(Scene),
                    invariant(each_object_counted_once),
                    validity(correct)
                  ]),
    append(Steps, [retain_last_count_word_as_cardinality(Count)], Trace).
run_counting_action(inscribe_cardinality, Count, base(Base), Outcome, Trace) :-
    valid_small_count(Count),
    valid_base(Base),
    integer_numeral(Count, Base, Numeral),
    Outcome = action_outcome(
                  inscribe_cardinality,
                  [ classification(productive),
                    cluster(counting_cardinality_inscription),
                    automaton_state(project_cardinality_into_positional_numeral),
                    vocabulary([cardinality, number_name, written_number,
                                numeral, digit, base, inscription]),
                    input(cardinality(Count)),
                    base(Base),
                    result(Numeral),
                    expected(Numeral),
                    invariant(inscription_denotes_counted_cardinality),
                    validity(correct)
                  ]),
    Trace = [ establish_cardinality(Count), choose_base(Base),
              project_counting_cycles_into_digits(Numeral) ].
run_counting_action(recursive_place_value_inscription, Count, base(Base),
                    Outcome, Trace) :-
    valid_cardinality(Count),
    valid_base(Base),
    integer_numeral(Count, Base, Numeral),
    numeral_unit_tree(Numeral, UnitTree),
    numeral_action_witness(Numeral, _Plan, WitnessTrace),
    Outcome = action_outcome(
                  recursive_place_value_inscription,
                  [ classification(productive),
                    cluster(counting_recursive_place_value),
                    automaton_state(recollect_base_cycles_as_positional_places),
                    vocabulary([cardinality, base, digit, place_value,
                                composite_unit, regroup, positional_numeral,
                                inscription, unit_tree]),
                    input(cardinality(Count)),
                    base(Base), result(Numeral), expected(Numeral),
                    representation(UnitTree),
                    invariant(each_place_counts_recursively_regrouped_units),
                    validity(correct)
                  ]),
    Trace = [ establish_cardinality(Count), establish_base(Base),
              recollect_completed_base_cycles
            | WitnessTrace ].
run_counting_action(omit_highest_place_regrouping, Count, base(Base),
                    Outcome, Trace) :-
    valid_cardinality(Count),
    valid_base(Base),
    Count >= Base,
    integer_numeral(Count, Base, Numeral),
    highest_regrouped_exponent(Numeral, Exponent),
    numeral_plan_deformation(Numeral, omitted_regrouping(Exponent),
                             DeformedPlan, Evidence),
    ProducedValue = Evidence.produced_value,
    Outcome = action_outcome(
                  omit_highest_place_regrouping,
                  [ classification(deformation),
                    cluster(counting_recursive_place_value),
                    automaton_state(read_high_place_digit_without_its_base_cycle),
                    vocabulary([cardinality, base, digit, place_value,
                                composite_unit, omitted_regrouping,
                                positional_numeral]),
                    input(cardinality(Count)),
                    base(Base), result(cardinality(ProducedValue)),
                    expected(cardinality(Count)),
                    representation(DeformedPlan),
                    deformation_of(recursive_place_value_inscription),
                    violated_invariant(each_place_counts_recursively_regrouped_units),
                    evidence(Evidence), validity(incorrect)
                  ]),
    Trace = [ establish_positional_numeral(Numeral),
              select_highest_regrouped_place(Exponent),
              omit_regrouping_action(Exponent),
              read_deformed_cardinality(ProducedValue)
            ].
run_counting_action(place_value_comparison, counts(A, B), base(Base),
                    Outcome, Trace) :-
    valid_cardinality(A), valid_cardinality(B), valid_base(Base),
    integer_numeral(A, Base, NumeralA),
    integer_numeral(B, Base, NumeralB),
    numeral_unit_tree(NumeralA, TreeA),
    numeral_unit_tree(NumeralB, TreeB),
    count_relation(A, B, Relation),
    Outcome = action_outcome(
                  place_value_comparison,
                  [ classification(productive),
                    cluster(counting_place_value_comparison),
                    automaton_state(compare_highest_differing_composite_units),
                    vocabulary([number, numeral, digit, place_value, base,
                                compare, order, highest_differing_place,
                                greater, less, equal]),
                    input(counts(A, B)), base(Base), result(Relation),
                    expected(Relation),
                    representation(compare_unit_trees(TreeA, TreeB)),
                    invariant(higher_places_dominate_lower_places),
                    validity(correct)
                  ]),
    Trace = [ inscribe_in_common_base(A, B, Base), align_places_by_unit,
              locate_highest_differing_place, compare_digits_at_that_place,
              conclude_count_relation(Relation) ].
run_counting_action(compare_ones_digits_only, counts(A, B), base(Base),
                    Outcome, Trace) :-
    valid_cardinality(A), valid_cardinality(B), valid_base(Base),
    OnesA is A mod Base, OnesB is B mod Base,
    count_relation(A, B, Expected),
    count_relation(OnesA, OnesB, Reported),
    Reported \== Expected,
    Outcome = action_outcome(
                  compare_ones_digits_only,
                  [ classification(deformation),
                    cluster(counting_place_value_comparison),
                    automaton_state(compare_only_unit_place_digits),
                    vocabulary([number, digit, place_value, ones_digit,
                                ignored_higher_place, compare, order]),
                    input(counts(A, B)), base(Base), result(Reported),
                    expected(Expected),
                    representation(ones_digit_comparison(OnesA, OnesB)),
                    deformation_of(place_value_comparison),
                    violated_invariant(higher_places_dominate_lower_places),
                    validity(incorrect)
                  ]),
    Trace = [ inscribe_in_common_base(A, B, Base),
              discard_higher_place_digits,
              compare_ones_digits(OnesA, OnesB),
              conclude_count_relation(Reported) ].
run_counting_action(compare_cardinalities_one_to_one, counts(A, B),
                    extents(_ExtentA, _ExtentB), Outcome, Trace) :-
    valid_small_count(A),
    valid_small_count(B),
    count_relation(A, B, Relation),
    set_grouping_render_json(compare(A, B), Scene),
    successful_scene(Scene),
    Outcome = action_outcome(
                  compare_cardinalities_one_to_one,
                  [ classification(productive),
                    cluster(counting_cardinality_comparison),
                    automaton_state(match_objects_one_to_one_then_compare_surplus),
                    vocabulary([collection, one_to_one, match, surplus,
                                more, fewer, same_number, cardinality]),
                    input(counts(A, B)),
                    result(Relation),
                    expected(Relation),
                    representation(Scene),
                    invariant(cardinality_independent_of_spatial_extent),
                    validity(correct)
                  ]),
    Trace = [ establish_collections(A, B), match_objects_one_to_one,
              inspect_unmatched_surplus, conclude_count_relation(Relation) ].
run_counting_action(spatial_extent_as_cardinality, counts(A, B),
                    extents(ExtentA, ExtentB), Outcome, Trace) :-
    valid_small_count(A),
    valid_small_count(B),
    number(ExtentA), number(ExtentB),
    count_relation(A, B, Expected),
    count_relation(ExtentA, ExtentB, Misread),
    Misread \== Expected,
    Outcome = action_outcome(
                  spatial_extent_as_cardinality,
                  [ classification(deformation),
                    cluster(counting_cardinality_comparison),
                    automaton_state(compare_row_lengths_without_one_to_one_matching),
                    vocabulary([collection, row_length, spatial_extent,
                                more, fewer, same_number, cardinality]),
                    input(counts(A, B)),
                    extents(ExtentA, ExtentB),
                    expected(Expected),
                    result(Misread),
                    deformation_of(compare_cardinalities_one_to_one),
                    violated_invariant(cardinality_independent_of_spatial_extent),
                    validity(incorrect)
                  ]),
    Trace = [ ignore_one_to_one_correspondence,
              compare_spatial_extents(ExtentA, ExtentB),
              substitute_extent_relation_for_count_relation(Misread) ].


counting_action_cluster(enumerate_collection_one_to_one,
                        counting_cardinality_coordination).
counting_action_cluster(inscribe_cardinality,
                        counting_cardinality_inscription).
counting_action_cluster(recursive_place_value_inscription,
                        counting_recursive_place_value).
counting_action_cluster(omit_highest_place_regrouping,
                        counting_recursive_place_value).
counting_action_cluster(place_value_comparison,
                        counting_place_value_comparison).
counting_action_cluster(compare_ones_digits_only,
                        counting_place_value_comparison).
counting_action_cluster(compare_cardinalities_one_to_one,
                        counting_cardinality_comparison).
counting_action_cluster(spatial_extent_as_cardinality,
                        counting_cardinality_comparison).

counting_action_vocabulary(enumerate_collection_one_to_one,
                           [collection, object, one_to_one, stable_order,
                            count_word, cardinality, last_word_principle, numeral]).
counting_action_vocabulary(inscribe_cardinality,
                           [cardinality, number_name, written_number, numeral,
                            digit, base, inscription]).
counting_action_vocabulary(recursive_place_value_inscription,
                           [cardinality, base, digit, place_value,
                            composite_unit, regroup, positional_numeral,
                            inscription, unit_tree]).
counting_action_vocabulary(omit_highest_place_regrouping,
                           [cardinality, base, digit, place_value,
                            composite_unit, omitted_regrouping,
                            positional_numeral]).
counting_action_vocabulary(place_value_comparison,
                           [number, numeral, digit, place_value, base,
                            compare, order, highest_differing_place,
                            greater, less, equal]).
counting_action_vocabulary(compare_ones_digits_only,
                           [number, digit, place_value, ones_digit,
                            ignored_higher_place, compare, order]).
counting_action_vocabulary(compare_cardinalities_one_to_one,
                           [collection, one_to_one, match, surplus, more, fewer,
                            same_number, cardinality]).
counting_action_vocabulary(spatial_extent_as_cardinality,
                           [collection, row_length, spatial_extent, more, fewer,
                            same_number, cardinality]).

productive_counting_deformation(compare_cardinalities_one_to_one,
                                spatial_extent_as_cardinality,
                                spatial_extent_substituted_for_cardinality).
productive_counting_deformation(recursive_place_value_inscription,
                                omit_highest_place_regrouping,
                                omitted_place_value_regrouping).
productive_counting_deformation(place_value_comparison,
                                compare_ones_digits_only,
                                ones_digit_substituted_for_place_value_comparison).

counting_action_misconception_hook(action_outcome(Kind, Fields),
                                   counting_productive_monitoring(Kind), Hook) :-
    member(classification(productive), Fields),
    member(vocabulary(Vocabulary), Fields),
    Hook = action_misconception_hook(
               [ productive_counting_action(Kind),
                 vocabulary(Vocabulary),
                 monitoring_focus(preserve_counting_invariants(Kind)),
                 evidence(Fields)
               ]).
counting_action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
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


valid_small_count(Count) :- integer(Count), between(1, 10, Count).
valid_cardinality(Count) :- integer(Count), Count >= 0.
valid_base(Base) :- integer(Base), Base >= 2.

highest_regrouped_exponent(
    numeral(_Base, _Sign, radix(Radix), _Digits), Exponent) :-
    Exponent is Radix - 1,
    Exponent > 0.

successful_scene(Scene) :-
    is_dict(Scene),
    get_dict(frames, Scene, [_|_]).

count_relation(A, B, more) :- A > B, !.
count_relation(A, B, fewer) :- A < B, !.
count_relation(_, _, same_number).

count_steps(Count, Steps) :-
    findall(pair_object_with_count_word(Index, Index),
            between(1, Count, Index), Steps).
