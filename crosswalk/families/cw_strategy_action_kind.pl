/** <module> cw_strategy_action_kind -- mechanical crosswalk family data. */
:- module(cw_strategy_action_kind,
          [ cw_family/1,
            cw_rule/1
          ]).

cw_family(cw_strategy_action_kind).
cw_rule(sak(unit_fraction_iteration, fraction_unit_referent_operations, whole_number_grab, whole_number_grab)).
cw_rule(sak(improper_fraction_iteration, fraction_improper_number, improper_fraction_chain_loss, improper_fraction_reset)).
cw_rule(sak(cross_multiplication_rule_from_pattern, fraction_area_model_multiplication, cross_multiplication_rule_without_ground, rule_without_grounding)).
cw_rule(sak(splitting, fraction_reversibility_splitting, iterate_given_overshoot, no_splitting_iterate_overshoot)).
cw_rule((legacy_list(A, [B, C]):-sak(A, _, _, _), atomic_list_concat(['action_automata_registry:action_automaton_cluster/3(fraction,', A, ')'], B), atomic_list_concat(['fraction_action_pairs:productive_fraction_deformation/3(', A, ')'], C))).
cw_rule((vocabulary_source(A, B):-legacy_list(A, B))).
cw_rule((canonical_concept(A, B):-legacy_list(B, C), member(A, C))).
cw_rule((strategy_action_kind_unified(A, B, C):-strategy_action_kind_witness(A, B, C, _))).
cw_rule((strategy_action_kind_witness(A, edge(B), B, C):-witness_dict:witness_dict(strategy_action_kind_crosswalk, closed_world_finite_verified_strategy_action_kind_edges, _{canonical:A, derivation:owner_predicate_edge_check, detail:edge(B), legacy_functor:B, projection:verified_legacy_edge, source:B, source_witness:D}, C), legacy_list(A, E), member(B, E), strategy_action_kind_edge_witness(A, B, D))).
cw_rule((strategy_action_kind_edge_witness(A, B, _{action_kind:A, cluster:D, kind:action_automaton_cluster_edge, module:action_automata_registry, operation:fraction, predicate:action_automaton_cluster/3, vocabulary:C}):-sub_atom(B, _, _, _, action_automaton_cluster), sak(A, D, _, _), catch(action_automata_registry:action_automaton_cluster(fraction, A, D), _, fail), catch(action_automata_registry:action_automaton_vocabulary(fraction, A, C), _, fail))).
cw_rule((strategy_action_kind_edge_witness(A, B, _{deformation:D, family:C, kind:productive_fraction_deformation_edge, module:fraction_action_pairs, predicate:productive_fraction_deformation/3, productive:A}):-sub_atom(B, _, _, _, productive_fraction_deformation), sak(A, _, D, C), catch(fraction_action_pairs:productive_fraction_deformation(A, D, C), _, fail))).
