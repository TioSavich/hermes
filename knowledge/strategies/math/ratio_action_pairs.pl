/** <module> Ratio / proportional reasoning action/deformation pairs
 *
 * Minimal proportional-reasoning skeleton. The registry boundary takes the
 * base ratio as two integers A:B (e.g., 3:4). The productive automaton
 * scales the ratio unit multiplicatively to produce the next equivalent
 * ratio (2A):(2B). The deformation applies additive comparison to the
 * second term while the first term scales correctly, producing
 * (2A):(B+A) -- the classic Vergnaud-style "additive" treatment of
 * missing-value proportions.
 *
 * Both actions agree on the scaled numerator 2A, so the disagreement is
 * located precisely on the second-term operation (multiplicative vs.
 * additive). This is the domain-004 skeleton; richer ratio-unit
 * coordination (within/between scaling, unit rate construction, multi-step
 * proportion) elaborates this pair in later batches.
 */

:- module(ratio_action_pairs,
          [ run_ratio_action/5,
            run_ratio_scale/6,
            ratio_action_cluster/2,
            ratio_action_vocabulary/2,
            productive_ratio_deformation/3,
            ratio_action_misconception_hook/3
          ]).

:- use_module(math(integer_helpers), [positive_integer/1]).
:- use_module(render(ratio_diagram_scene), [ratio_diagram_render_json/2]).


%!  run_ratio_action(+Kind, +A, +B, -Outcome, -Trace) is semidet.
%
%   Execute a productive or deformed proportional-reasoning step. A and B
%   are the base-ratio terms (A:B). The implicit task is "what is the next
%   equivalent ratio that doubles the first term?" -- productive returns the
%   multiplicatively scaled pair; the additive deformation only matches the
%   target first term and applies the same absolute increment to the second.
run_ratio_action(scale_ratio_unit, A, B, Outcome, Trace) :-
    run_ratio_scale(scale_ratio_unit, A, B, 2, Outcome, Trace).
run_ratio_action(additive_extension_of_ratio, A, B, Outcome, Trace) :-
    run_ratio_scale(additive_extension_of_ratio, A, B, 2, Outcome, Trace).
run_ratio_action(construct_referent_ratio_diagram,
                 referent(FirstLabel, FirstCount),
                 referent(SecondLabel, SecondCount), Outcome, Trace) :-
    ratio_referent_components(FirstLabel, FirstCount,
                              SecondLabel, SecondCount, Scene),
    Result = ratio_statement(FirstLabel, FirstCount,
                             SecondLabel, SecondCount),
    Outcome = action_outcome(
                  construct_referent_ratio_diagram,
                  [ classification(productive),
                    cluster(proportional_ratio_referent_coordination),
                    automaton_state(coordinate_ordered_referents_and_counts),
                    vocabulary([ratio, ratio_language, ratio_diagram,
                                first_referent, second_referent,
                                ordered_pair, for_every, tape_diagram]),
                    input(referents(FirstLabel, SecondLabel)),
                    counts(FirstCount, SecondCount), result(Result),
                    expected(Result), representation(Scene),
                    invariant(ratio_order_tracks_named_referents),
                    validity(correct)
                  ]),
    Trace = [ establish_first_referent(FirstLabel, FirstCount),
              establish_second_referent(SecondLabel, SecondCount),
              coordinate_referent_counts,
              construct_ratio_diagram(FirstCount, SecondCount),
              inscribe_ordered_ratio(FirstLabel-SecondLabel,
                                     FirstCount-SecondCount)
            ].
run_ratio_action(reverse_ratio_referent_order,
                 referent(FirstLabel, FirstCount),
                 referent(SecondLabel, SecondCount), Outcome, Trace) :-
    ratio_referent_components(FirstLabel, FirstCount,
                              SecondLabel, SecondCount, Scene),
    FirstCount =\= SecondCount,
    Expected = ratio_statement(FirstLabel, FirstCount,
                               SecondLabel, SecondCount),
    Result = ratio_statement(FirstLabel, SecondCount,
                             SecondLabel, FirstCount),
    Outcome = action_outcome(
                  reverse_ratio_referent_order,
                  [ classification(deformation),
                    cluster(proportional_ratio_referent_coordination),
                    automaton_state(read_ratio_terms_against_reversed_referents),
                    vocabulary([ratio, ratio_language, ratio_diagram,
                                referent_order, reversed_terms, ratio_loss]),
                    input(referents(FirstLabel, SecondLabel)),
                    counts(FirstCount, SecondCount), result(Result),
                    expected(Expected), representation(Scene),
                    deformation_of(construct_referent_ratio_diagram),
                    misconception_family(reversed_ratio_referent_order),
                    violated_invariant(ratio_order_tracks_named_referents),
                    validity(incorrect)
                  ]),
    Trace = [ establish_counts_without_order(FirstCount, SecondCount),
              reverse_term_referent_alignment,
              inscribe_reversed_ratio(FirstLabel-SecondLabel,
                                      SecondCount-FirstCount),
              lose_ordered_referent_relation
            ].


%!  run_ratio_scale(+Kind, +A, +B, +Factor, -Outcome, -Trace) is semidet.
%
%   General scaling form. The registry's legacy run_ratio_action/5 surface is
%   the Factor=2 instance; curriculum task compilers can retain the factor.
run_ratio_scale(scale_ratio_unit, A, B, Factor, Outcome, Trace) :-
    ratio_components(A, B, Factor, Components),
    Components = ratio_components(ScaleFactor, ScaledNumerator,
                                  ScaledDenominator, _Increment, _AdditiveDenominator),
    Result = ratio_pair(ScaledNumerator, ScaledDenominator),
    Outcome = action_outcome(
                  scale_ratio_unit,
                  [ classification(productive),
                    cluster(proportional_ratio_unit_coordination),
                    automaton_state(equivalent_ratio_scaling),
                    vocabulary([ratio_pair, unit_ratio, scale_factor,
                                multiplicative_scaling, equivalent_ratio,
                                first_term, second_term]),
                    result(Result),
                    expected(Result),
                    validity(correct),
                    components(Components)
                  ]),
    Trace = [ identify_base_ratio(ratio_pair(A, B)),
              identify_scale_factor(ScaleFactor),
              scale_first_term_multiplicatively(A, ScaleFactor, ScaledNumerator),
              scale_second_term_multiplicatively(B, ScaleFactor, ScaledDenominator),
              compose_equivalent_ratio(Result),
              preserve_multiplicative_unit_ratio(Result)
            ].
run_ratio_scale(additive_extension_of_ratio, A, B, Factor, Outcome, Trace) :-
    ratio_components(A, B, Factor, Components),
    Components = ratio_components(ScaleFactor, ScaledNumerator,
                                  ScaledDenominator, Increment, AdditiveDenominator),
    Expected = ratio_pair(ScaledNumerator, ScaledDenominator),
    Result = ratio_pair(ScaledNumerator, AdditiveDenominator),
    AdditiveDenominator =\= ScaledDenominator,
    Outcome = action_outcome(
                  additive_extension_of_ratio,
                  [ classification(deformation),
                    cluster(proportional_ratio_unit_coordination),
                    automaton_state(equivalent_ratio_scaling),
                    vocabulary([ratio_pair, unit_ratio,
                                additive_comparison, first_term_increment,
                                second_term_increment, ratio_loss]),
                    result(Result),
                    expected(Expected),
                    validity(incorrect),
                    components(Components),
                    deformation_of(scale_ratio_unit),
                    misconception_family(additive_comparison_in_proportion)
                  ]),
    Trace = [ identify_base_ratio(ratio_pair(A, B)),
              compute_first_term_increment(A, ScaleFactor, ScaledNumerator, Increment),
              add_first_term_increment_to_second_term(B, Increment, AdditiveDenominator),
              compose_additive_pair(Result),
              lose_multiplicative_unit_ratio(expected(Expected), produced(Result))
            ].


%!  ratio_action_cluster(+Kind, -Cluster) is det.
ratio_action_cluster(scale_ratio_unit, proportional_ratio_unit_coordination).
ratio_action_cluster(additive_extension_of_ratio, proportional_ratio_unit_coordination).
ratio_action_cluster(construct_referent_ratio_diagram,
                     proportional_ratio_referent_coordination).
ratio_action_cluster(reverse_ratio_referent_order,
                     proportional_ratio_referent_coordination).


%!  ratio_action_vocabulary(+Kind, -Vocabulary) is det.
ratio_action_vocabulary(scale_ratio_unit,
                        [ratio_pair, unit_ratio, scale_factor,
                         multiplicative_scaling, equivalent_ratio,
                         first_term, second_term]).
ratio_action_vocabulary(additive_extension_of_ratio,
                        [ratio_pair, unit_ratio,
                         additive_comparison, first_term_increment,
                         second_term_increment, ratio_loss]).
ratio_action_vocabulary(construct_referent_ratio_diagram,
                        [ratio, ratio_language, ratio_diagram,
                         first_referent, second_referent,
                         ordered_pair, for_every, tape_diagram]).
ratio_action_vocabulary(reverse_ratio_referent_order,
                        [ratio, ratio_language, ratio_diagram,
                         referent_order, reversed_terms, ratio_loss]).


%!  productive_ratio_deformation(+ProductiveKind, +DeformationKind, -Family) is det.
productive_ratio_deformation(scale_ratio_unit,
                             additive_extension_of_ratio,
                             additive_comparison_in_proportion).
productive_ratio_deformation(construct_referent_ratio_diagram,
                             reverse_ratio_referent_order,
                             reversed_ratio_referent_order).


%!  ratio_action_misconception_hook(+Outcome, -Family, -Hook) is semidet.
ratio_action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
    member(classification(deformation), Fields),
    member(misconception_family(Family), Fields),
    member(deformation_of(ProductiveKind), Fields),
    member(vocabulary(Vocabulary), Fields),
    Hook = action_misconception_hook(
               [ deformation(Kind),
                 deformation_of(ProductiveKind),
                 family(Family),
                 vocabulary(Vocabulary),
                 repair(recover_productive_action(ProductiveKind)),
                 evidence(Fields)
               ]).
ratio_action_misconception_hook(action_outcome(Kind, Fields), Family, Hook) :-
    member(classification(productive), Fields),
    productive_ratio_deformation(Kind, DeformationKind, Family),
    member(vocabulary(Vocabulary), Fields),
    ratio_monitoring_focus(Kind, Focus),
    Hook = action_misconception_hook(
               [ productive_action(Kind),
                 nearby_deformation(DeformationKind),
                 family(Family),
                 vocabulary(Vocabulary),
                 monitoring_focus(Focus),
                 evidence(Fields)
               ]).


ratio_components(A, B, ScaleFactor,
                 ratio_components(ScaleFactor, ScaledNumerator,
                                  ScaledDenominator, Increment, AdditiveDenominator)) :-
    positive_integer(A),
    positive_integer(B),
    positive_integer(ScaleFactor),
    ScaleFactor > 1,
    ScaledNumerator is A * ScaleFactor,
    ScaledDenominator is B * ScaleFactor,
    Increment is ScaledNumerator - A,
    AdditiveDenominator is B + Increment.

ratio_referent_components(FirstLabel, FirstCount,
                          SecondLabel, SecondCount, Scene) :-
    atom(FirstLabel), atom(SecondLabel), FirstLabel \== SecondLabel,
    positive_integer(FirstCount), positive_integer(SecondCount),
    ratio_diagram_render_json(
        ratio(FirstLabel, FirstCount, SecondLabel, SecondCount), Scene),
    Scene.frames = [_|_].

ratio_monitoring_focus(scale_ratio_unit,
                       preserve_multiplicative_unit_ratio(scale_ratio_unit)).
ratio_monitoring_focus(construct_referent_ratio_diagram,
                       preserve_ordered_ratio_referents(
                           construct_referent_ratio_diagram)).


% positive_integer/1 imported from math(integer_helpers).
