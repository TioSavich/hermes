/** <module> cw_fraction_extra_claim -- mechanical crosswalk family data. */
:- module(cw_fraction_extra_claim,
          [ cw_family/1,
            cw_rule/1
          ]).

cw_family(cw_fraction_extra_claim).
cw_rule(fe(fraction_of_quantity_as_part_of_part, c_fraction_of_quantity_multiplication, ['action_automata_registry:action_automaton_cluster/3(fraction,area_model_part_of_part)', 'grounding_metaphors:grounds_inference/3(arithmetic_is_object_construction,fraction_multiplication_as_part_of_part)'])).
cw_rule(fe(fraction_stable_referent_whole, c_fraction_referent_whole_invariance, ['action_automata_registry:action_automaton_cluster/3(fraction,improper_fraction_iteration)', 'misconception_registry:incompatibility_with/2(improper_fraction_chain_loss)'])).
cw_rule(fe(fraction_part_disembedded_as_quantity, c_part_whole_disembedding, ['action_automata_registry:action_automaton_cluster/3(fraction,recursive_partition)', 'misconception_registry:incompatibility_with/2(clear_inner_referent)'])).
cw_rule(fe(cancellation_needs_common_factor, c_cancellation_requires_common_factor, ['action_automata_registry:action_automaton_cluster/3(calculus,factor_cancel_substitute)', 'action_automata_registry:action_automaton_cluster/3(calculus,factor_cancel_without_common_factor)', 'misconception_registry:incompatibility_with/2(factor_cancel_without_common_factor)'])).
cw_rule(fe(fraction_addition_on_common_unit, c_fraction_addition_common_unit, ['action_automata_registry:action_automaton_cluster/3(fraction,co_denominator_count_on_from_larger)'])).
cw_rule(fe(fraction_division_as_reversible_inverse, c_fraction_division_inverse_relation, ['action_automata_registry:action_automaton_cluster/3(fraction,solve_for_unit)', 'misconception_registry:incompatibility_with/2(iterate_only_no_reverse)'])).
cw_rule((claim_literature_atom(A, B):-fe(A, B, _))).
cw_rule((legacy_list(A, B):-fe(A, C, D), atomic_list_concat(['literature_vocabulary:canonical_commitment/2(', C, ')'], E), append([[E], D], B))).
cw_rule((vocabulary_source(A, B):-legacy_list(A, B))).
cw_rule((canonical_concept(A, B):-legacy_list(B, C), member(A, C))).
cw_rule((fraction_extra_claim_unified(A, B, C):-fraction_extra_claim_witness(A, B, C, _))).
cw_rule((fraction_extra_claim_witness(A, commitment(B, C), literature_commitment, D):-witness_dict:witness_dict(fraction_extra_claim_crosswalk, closed_world_finite_verified_fraction_extra_claim_edges, _{canonical:A, derivation:literature_canonical_commitment_lookup, detail:commitment(B, C), literature_atom:B, projection:literature_commitment_gloss, source:literature_commitment, source_witness:_{atom:B, gloss:C, kind:literature_commitment_row, module:literature_vocabulary, predicate:canonical_commitment/2}}, D), fe(A, B, _), catch(literature_vocabulary:canonical_commitment(B, E), _, fail), (string(E)->C=E;format(string(C), "~w", [E])))).
cw_rule((fraction_extra_claim_witness(A, edge(B), B, C):-witness_dict:witness_dict(fraction_extra_claim_crosswalk, closed_world_finite_verified_fraction_extra_claim_edges, _{canonical:A, derivation:owner_predicate_edge_check, detail:edge(B), legacy_functor:B, projection:verified_legacy_edge, source:B, source_witness:D}, C), fe(A, _, E), member(B, E), fraction_extra_edge_witness(B, D))).
cw_rule((fraction_extra_edge_witness('action_automata_registry:action_automaton_cluster/3(fraction,area_model_part_of_part)', A):-action_cluster_witness(fraction, area_model_part_of_part, A))).
cw_rule((fraction_extra_edge_witness('action_automata_registry:action_automaton_cluster/3(fraction,improper_fraction_iteration)', A):-action_cluster_witness(fraction, improper_fraction_iteration, A))).
cw_rule((fraction_extra_edge_witness('action_automata_registry:action_automaton_cluster/3(fraction,recursive_partition)', A):-action_cluster_witness(fraction, recursive_partition, A))).
cw_rule((fraction_extra_edge_witness('action_automata_registry:action_automaton_cluster/3(calculus,factor_cancel_substitute)', A):-action_cluster_witness(calculus, factor_cancel_substitute, A))).
cw_rule((fraction_extra_edge_witness('action_automata_registry:action_automaton_cluster/3(calculus,factor_cancel_without_common_factor)', A):-action_cluster_witness(calculus, factor_cancel_without_common_factor, A))).
cw_rule((fraction_extra_edge_witness('action_automata_registry:action_automaton_cluster/3(fraction,co_denominator_count_on_from_larger)', A):-action_cluster_witness(fraction, co_denominator_count_on_from_larger, A))).
cw_rule((fraction_extra_edge_witness('action_automata_registry:action_automaton_cluster/3(fraction,solve_for_unit)', A):-action_cluster_witness(fraction, solve_for_unit, A))).
cw_rule((fraction_extra_edge_witness('grounding_metaphors:grounds_inference/3(arithmetic_is_object_construction,fraction_multiplication_as_part_of_part)', _{grounding_path:A, grounding_witness:B, kind:grounding_metaphor_inference_edge, metaphor:arithmetic_is_object_construction, module:grounding_metaphors, predicate:grounds_inference_witness/4, target_inference:fraction_multiplication_as_part_of_part}):-catch(grounding_metaphors:grounds_inference_witness(arithmetic_is_object_construction, fraction_multiplication_as_part_of_part, A, B), _, fail))).
cw_rule((fraction_extra_edge_witness(A, B):-registry_functor(A, C), registry_incompatibility_witness(C, B))).
cw_rule((action_cluster_witness(A, B, _{action_kind:B, cluster:D, kind:action_automaton_cluster_edge, module:action_automata_registry, operation:A, predicate:action_automaton_cluster/3, vocabulary:C}):-catch(action_automata_registry:action_automaton_cluster(A, B, D), _, fail), catch(action_automata_registry:action_automaton_vocabulary(A, B, C), _, fail))).
cw_rule((registry_incompatibility_witness(A, _{conflict:B, incompatibility_witness:C, kind:misconception_registry_incompatibility_edge, module:misconception_registry, move:A, predicate:incompatibility_with_witness/3}):-catch(once(misconception_registry:incompatibility_with_witness(A, B, C)), _, fail))).
cw_rule(registry_functor('misconception_registry:incompatibility_with/2(improper_fraction_chain_loss)', improper_fraction_chain_loss)).
cw_rule(registry_functor('misconception_registry:incompatibility_with/2(clear_inner_referent)', clear_inner_referent)).
cw_rule(registry_functor('misconception_registry:incompatibility_with/2(factor_cancel_without_common_factor)', factor_cancel_without_common_factor)).
cw_rule(registry_functor('misconception_registry:incompatibility_with/2(iterate_only_no_reverse)', iterate_only_no_reverse)).
