/** <module> cw_magnitude_equivalence_claim -- mechanical crosswalk family data. */
:- module(cw_magnitude_equivalence_claim,
          [ cw_family/1,
            cw_rule/1
          ]).

cw_family(cw_magnitude_equivalence_claim).
cw_rule(me(ratio_invariance_under_scaling, c_multiplicative_ratio_invariance, [ratio-scale_ratio_unit, ratio-additive_extension_of_ratio])).
cw_rule(me(total_conserved_under_transformation, c_conservation_invariance, [multiplication-commute_factors_preserve_product, multiplication-regroup_to_base_preserving_total, subtraction-sliding_constant_difference])).
cw_rule((claim_literature_atom(A, B):-me(A, B, _))).
cw_rule((edge_functor(A-B, C):-atomic_list_concat(['action_automata_registry:action_automaton_cluster/3(', A, ',', B, ')'], C))).
cw_rule((legacy_list(A, B):-me(A, C, D), atomic_list_concat(['literature_vocabulary:canonical_commitment/2(', C, ')'], E), findall(F, (member(G, D), edge_functor(G, F)), H), append([[E], H], B))).
cw_rule((vocabulary_source(A, B):-legacy_list(A, B))).
cw_rule((canonical_concept(A, B):-legacy_list(B, C), member(A, C))).
cw_rule((magnitude_equivalence_claim_unified(A, B, C):-magnitude_equivalence_claim_witness(A, B, C, _))).
cw_rule((magnitude_equivalence_claim_witness(A, commitment(B, C), literature_commitment, D):-witness_dict:witness_dict(magnitude_equivalence_claim_crosswalk, closed_world_finite_verified_magnitude_equivalence_claim_edges, _{canonical:A, derivation:literature_canonical_commitment_lookup, detail:commitment(B, C), literature_atom:B, projection:literature_commitment_gloss, source:literature_commitment, source_witness:_{atom:B, gloss:C, kind:literature_commitment_row, module:literature_vocabulary, predicate:canonical_commitment/2}}, D), me(A, B, _), catch(literature_vocabulary:canonical_commitment(B, E), _, fail), (string(E)->C=E;format(string(C), "~w", [E])))).
cw_rule((magnitude_equivalence_claim_witness(A, edge(B-C), D, E):-witness_dict:witness_dict(magnitude_equivalence_claim_crosswalk, closed_world_finite_verified_magnitude_equivalence_claim_edges, _{canonical:A, derivation:owner_predicate_edge_check, detail:edge(B-C), legacy_functor:D, projection:verified_legacy_edge, source:D, source_witness:F}, E), me(A, _, G), member(B-C, G), edge_functor(B-C, D), magnitude_equivalence_edge_source_witness(B, C, F))).
cw_rule((magnitude_equivalence_edge_source_witness(A, B, _{action_kind:B, cluster:D, kind:action_automaton_cluster_edge, module:action_automata_registry, operation:A, predicate:action_automaton_cluster/3, vocabulary:C}):-catch(action_automata_registry:action_automaton_cluster(A, B, D), _, fail), catch(action_automata_registry:action_automaton_vocabulary(A, B, C), _, fail))).
