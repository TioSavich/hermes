/** <module> cw_edges -- recorded clauses and owner-predicate edges by family.
 *
 * Families are ordered alphabetically. Within each family, recorded clauses
 * and edge rows retain their original in-file order.
 */
:- module(cw_edges, [family/1, rule/2, edge/6]).

:- discontiguous family/1, rule/2, edge/6.

% Source modules required by the recorded clauses. Imports stay empty because
% the driver executes owner predicates module-qualified.
:- use_module(standards('indiana/standard_2_ns_3'), []).
:- use_module(standards('indiana/standard_3_ca_3_4'), []).
:- use_module(dialectic(critique), []).
:- use_module(learner(reorganization_engine), []).
:- use_module(strategies('math/sar_add_action_pairs'), []).
:- use_module(learner(deontic_scorekeeper), []).
:- use_module(learner(more_machine_learner), []).
:- use_module(learner(oracle_server), []).
:- use_module(pml(mua_relations), []).
:- use_module(strategies(fsm_engine), []).
:- use_module(dialectic(dialectical_engine), []).
:- use_module(sequent(automata), []).
:- use_module(formalization(grounded_utils), []).
:- use_module(formalization(robinson_q), []).
:- use_module(formalization(grounding_metaphors_extended), []).
:- use_module(incompat(defeasible_inference), []).
:- use_module(sequent(embodied_prover), []).
:- use_module(pml(semantic_axioms), []).
:- use_module(learner(meta_interpreter), []).
:- use_module(hermes(encyclopedia), []).
:- use_module(learner(execution_handler), []).
:- use_module(learner(reflective_monitor), []).
:- use_module(math(divaded_fractional_units), []).
:- use_module(misconceptions(literature_incompatibility_facts), []).
:- use_module(standards('indiana/standard_k_ca_1_3'), []).
:- use_module(standards('indiana/standard_1_ca_1'), []).
:- use_module(standards('indiana/standard_1_ca_3'), []).
:- use_module(standards('indiana/standard_2_ca_2'), []).

% cw_accommodation
family(cw_accommodation).
edge(cw_accommodation, critique,accommodate/1,[conceptual_change],[],call_match_ground).
rule(cw_accommodation, (accommodation_unified(A,B):-accommodation_witness(A,B,_2806))).
rule(cw_accommodation, (accommodation_witness(A,B,C):-witness_dict:witness_dict(accommodation_registry_entry,closed_world_finite_loaded_accommodation_registry,_2888{effect:G,invocation_policy:registry_only_no_executor_call,legacy_functor:E,side_effect_boundary:H,source:B,target:A,target_witness:I,trigger_shape:F},C),registry(A,B,G,F,H,E),target_defined_witness(A,I))).
rule(cw_accommodation, (registry(A,B,C):-registry(A,B,C,_3128,_,_))).
rule(cw_accommodation, registry(critique:accommodate/1,dialectic_critique,'sequent/commitment sublation; increments stress map, writes diagnostics, and fails to signal external intervention','perturbation(resource_exhaustion, Sequent) | incoherence(Commitments) | pathology(bad_infinite, Cycle) | Trigger',stress_map_and_stdout,'critique:accommodate/1')).
rule(cw_accommodation, registry(reorganization_engine:accommodate/1,learner_reorg,'learner accommodation; dispatches to belief revision or conceptual-stress repair on object_level','goal_failure(_) | perturbation(_) | incoherence(Commitments) | Trigger',object_level_stress_map_log_and_stdout,'reorganization_engine:accommodate/1')).
rule(cw_accommodation, registry(reorganization_engine:reorganize_system/2,learner_reorg,'ORR Reorganize entry point; current finite crisis-recovery path reports the archived FSM-synthesis boundary and fails','Goal, Trace',stdout_and_external_recovery_signal,'reorganization_engine:reorganize_system/2')).
rule(cw_accommodation, (target_defined_witness(A:B/C,_3476{arity:C,kind:loaded_predicate_presence,module:A,name:B,properties:E}):-catch(once((current_predicate(A:B/C);functor(F,B,C),predicate_property(A:F,defined))),_,fail),findall(H,target_property(A,B,C,H),I),sort(I,E))).
rule(cw_accommodation, (target_property(A,B,C,defined):-functor(D,B,C),predicate_property(A:D,defined))).
rule(cw_accommodation, (target_property(A,B,C,exported):-functor(D,B,C),predicate_property(A:D,exported))).
rule(cw_accommodation, canonical_concept('critique:accommodate/1',accommodation)).
rule(cw_accommodation, canonical_concept('reorganization_engine:accommodate/1',accommodation)).
rule(cw_accommodation, canonical_concept('reorganization_engine:reorganize_system/2',accommodation)).
rule(cw_accommodation, vocabulary_source(accommodation,['critique:accommodate/1','reorganization_engine:accommodate/1','reorganization_engine:reorganize_system/2'])).

% cw_action_cluster
family(cw_action_cluster).
edge(cw_action_cluster, sar_add_action_pairs,action_cluster/2,[derived_fact_adjustment],[2],call_bind_out).
rule(cw_action_cluster, (action_cluster_unified(addition,A,B,addition_pairs):-action_cluster_witness(addition,A,B,addition_pairs,_6340))).
rule(cw_action_cluster, (action_cluster_unified(fraction,A,B,fraction_pairs):-action_cluster_witness(fraction,A,B,fraction_pairs,_6432))).
rule(cw_action_cluster, (action_cluster_unified(A,B,C,registry):-action_cluster_witness(A,B,C,registry,_6524))).
rule(cw_action_cluster, (action_cluster_witness(A,B,C,D,E):-witness_dict:witness_dict(action_cluster_crosswalk,closed_world_finite_loaded_action_cluster_sources,_6622{action_kind:B,cluster:C,derivation:H,legacy_functor:G,operation:A,source:D,source_witness:I},E),source_action_cluster_witness(D,A,B,C,G,H,I))).
rule(cw_action_cluster, (source_action_cluster_witness(addition_pairs,addition,A,B,'sar_add_action_pairs:action_cluster/2',direct_addition_action_cluster_row,_6840{action_kind:A,cluster:B,implicit_operation:addition,kind:direct_action_cluster_row,module:sar_add_action_pairs,predicate:action_cluster/2}):-catch(sar_add_action_pairs:action_cluster(A,B),_,fail))).
rule(cw_action_cluster, (source_action_cluster_witness(fraction_pairs,fraction,A,B,'fraction_action_pairs:fraction_action_cluster/2',direct_fraction_action_cluster_row,_7004{action_kind:A,cluster:B,implicit_operation:fraction,kind:direct_action_cluster_row,module:fraction_action_pairs,predicate:fraction_action_cluster/2}):-catch(fraction_action_pairs:fraction_action_cluster(A,B),_,fail))).
rule(cw_action_cluster, (source_action_cluster_witness(registry,A,B,C,'action_automata_registry:action_automaton_cluster/3',registry_operation_dispatch,_7168{action_kind:B,cluster:C,dispatched_legacy_functor:G,dispatched_module:E,dispatched_predicate:F/2,kind:registry_action_cluster_dispatch,operation:A,registry_predicate:'action_automata_registry:action_automaton_cluster/3'}):-catch(action_automata_registry:action_automaton_cluster(A,B,C),_,fail),registry_cluster_dispatch(A,E,F,G),dispatched_cluster_row(E,F,B,C))).
rule(cw_action_cluster, registry_cluster_dispatch(addition,sar_add_action_pairs,action_cluster,'sar_add_action_pairs:action_cluster/2')).
rule(cw_action_cluster, registry_cluster_dispatch(subtraction,sar_sub_action_pairs,subtractive_action_cluster,'sar_sub_action_pairs:subtractive_action_cluster/2')).
rule(cw_action_cluster, registry_cluster_dispatch(multiplication,smr_mult_action_pairs,multiplicative_action_cluster,'smr_mult_action_pairs:multiplicative_action_cluster/2')).
rule(cw_action_cluster, registry_cluster_dispatch(division,smr_div_action_pairs,division_action_cluster,'smr_div_action_pairs:division_action_cluster/2')).
rule(cw_action_cluster, registry_cluster_dispatch(fraction,fraction_action_pairs,fraction_action_cluster,'fraction_action_pairs:fraction_action_cluster/2')).
rule(cw_action_cluster, registry_cluster_dispatch(decimal,decimal_action_pairs,decimal_action_cluster,'decimal_action_pairs:decimal_action_cluster/2')).
rule(cw_action_cluster, registry_cluster_dispatch(integer,integer_action_pairs,integer_action_cluster,'integer_action_pairs:integer_action_cluster/2')).
rule(cw_action_cluster, registry_cluster_dispatch(ratio,ratio_action_pairs,ratio_action_cluster,'ratio_action_pairs:ratio_action_cluster/2')).
rule(cw_action_cluster, registry_cluster_dispatch(diagnostic,diagnostic_validation_action_pairs,diagnostic_action_cluster,'diagnostic_validation_action_pairs:diagnostic_action_cluster/2')).
rule(cw_action_cluster, registry_cluster_dispatch(calculus,calculus_limits_action_pairs,calculus_action_cluster,'calculus_limits_action_pairs:calculus_action_cluster/2')).
rule(cw_action_cluster, registry_cluster_dispatch(algebraic,algebraic_action_pairs,algebraic_action_cluster,'algebraic_action_pairs:algebraic_action_cluster/2')).
rule(cw_action_cluster, registry_cluster_dispatch(probability,probability_action_pairs,probability_action_cluster,'probability_action_pairs:probability_action_cluster/2')).
rule(cw_action_cluster, (dispatched_cluster_row(A,B,C,D):-E=..[B,C,D],catch(call(A:E),_8064,fail))).
rule(cw_action_cluster, canonical_concept('sar_add_action_pairs:action_cluster/2',action_cluster_unified)).
rule(cw_action_cluster, canonical_concept('fraction_action_pairs:fraction_action_cluster/2',action_cluster_unified)).
rule(cw_action_cluster, canonical_concept('action_automata_registry:action_automaton_cluster/3',action_cluster_unified)).
rule(cw_action_cluster, vocabulary_source(action_cluster_unified,['sar_add_action_pairs:action_cluster/2','fraction_action_pairs:fraction_action_cluster/2','action_automata_registry:action_automaton_cluster/3'])).

% cw_algebra_claim
family(cw_algebra_claim).
rule(cw_algebra_claim, ac(value_substitution_into_expression, c_substitution_semantics, [edge('action_automata_registry:action_automaton_vocabulary/3(algebraic,programming_expression_evaluation)', "Algebraic program-evaluation vocabulary carrying variable_substitution and variable_assignment."), edge('action_automata_registry:action_automaton_cluster/3(calculus,direct_substitution)', "Calculus limit-by-continuity cluster whose vocabulary carries substitution and function_value."), edge('action_automata_registry:action_automaton_cluster/3(calculus,factor_cancel_substitute)', "Calculus removable-discontinuity cluster that cancels then substitutes — substitution after factoring.")])).
rule(cw_algebra_claim, ac(variable_as_indeterminate_quantity, c_variable_as_generalized_quantity, [edge('action_automata_registry:action_automaton_vocabulary/3(algebraic,programming_expression_evaluation)', "Algebraic program-evaluation vocabulary carrying algebraic_expression and variable_assignment — variables as assignable indeterminates."), edge('action_automata_registry:action_automaton_vocabulary/3(algebraic,linear_pattern_contextual_rule)', "Algebraic linear-pattern vocabulary carrying contextual_generalization and explicit_rule — the term standing for a generalized quantity in a relation.")])).
rule(cw_algebra_claim, ac(function_evaluation_at_argument, c_function_notation_evaluation, [edge('action_automata_registry:action_automaton_vocabulary/3(algebraic,programming_expression_evaluation)', "Algebraic program-evaluation vocabulary carrying evaluate_as_program, procedural_evaluation, and integer_value — computing the value at an assignment."), edge('action_automata_registry:action_automaton_vocabulary/3(calculus,direct_substitution)', "Calculus direct-substitution vocabulary carrying evaluation_at_a_point and function_value.")])).
rule(cw_algebra_claim, ac(function_as_univalent_correspondence, c_function_as_arbitrary_correspondence, [edge('grounding_metaphors:metaphor_breaks_at/3(functions_are_sets_of_ordered_pairs,conceptual_distinction_between_rule_and_extension)', "Break point: the ordered-pairs reading collapses two conceptually distinct rules that share an extension, marking where rule and extension come apart."), edge('grounding_metaphors:metaphor_breaks_at/3(functions_are_curves,monster_functions_lacking_tangents_or_continuity)', "Break point: pathological functions (continuous nowhere-differentiable, space-filling) cannot be grounded as smooth curves, forcing the arbitrary-correspondence reading.")])).
rule(cw_algebra_claim, ac(explicit_rule_generalization, c_structural_generalization, [edge('action_automata_registry:action_automaton_vocabulary/3(algebraic,linear_pattern_contextual_rule)', "Algebraic linear-pattern vocabulary carrying explicit_rule, contextual_generalization, and far_term_prediction — a structural rule that holds across all cases."), edge('misconception_registry:incompatibility_with/2(guess_and_check_rule,strategy(algebraic,linear_pattern_contextual_rule))', "Registered deformation incompatibility: guess-and-check against one instance loses the explicit structural rule.")])).
rule(cw_algebra_claim, ac(relational_strategy_over_brute_count, c_relational_strategy_choice, [edge('action_automata_registry:action_automaton_vocabulary/3(addition,derived_fact_adjustment)', "Additive derived-fact vocabulary carrying anchor_fact, relation_between_problems, and adjustment — exploiting a known fact's relation to the target."), edge('action_automata_registry:action_automaton_cluster/3(subtraction,sliding_constant_difference)', "Subtraction constant-difference shortcut: shift both terms to preserve the difference rather than counting unit-by-unit."), edge('action_automata_registry:action_automaton_cluster/3(addition,unbalanced_make_base_compensation)', "Addition compensation/conservation shortcut: adjust to a base and compensate rather than counting unit-by-unit.")])).
rule(cw_algebra_claim, ac(irrational_extension_of_number_system, c_real_extension_solvability, [edge('grounding_metaphors:metaphor_breaks_at/3(arithmetic_is_object_collection,irrational_numbers)', "Break point: irrationals have no source-domain referent as a collection, marking where the rationals are extended to the reals."), edge('grounding_metaphors:metaphor_breaks_at/3(arithmetic_is_object_construction,irrational_numbers)', "Break point: irrationals are not constructible by finite assembly of unit parts, marking where finite construction fails.")])).
rule(cw_algebra_claim, (claim_literature_atom(A, B):-ac(A, B, _))).
rule(cw_algebra_claim, (legacy_list(A, [B|C]):-ac(A, D, E), atomic_list_concat(['literature_vocabulary:canonical_commitment/2(', D, ')'], B), findall(F, member(edge(F, _), E), C))).
rule(cw_algebra_claim, (vocabulary_source(A, B):-legacy_list(A, B))).
rule(cw_algebra_claim, (canonical_concept(A, B):-legacy_list(B, C), member(A, C))).
rule(cw_algebra_claim, (algebra_claim_unified(A, B, C):-algebra_claim_witness(A, B, C, _))).
rule(cw_algebra_claim, (algebra_claim_witness(A, commitment(B, C), literature_commitment, D):-witness_dict:witness_dict(algebra_claim_crosswalk, closed_world_finite_verified_algebra_claim_edges, _{canonical:A, derivation:literature_canonical_commitment_lookup, detail:commitment(B, C), literature_atom:B, projection:literature_commitment_gloss, source:literature_commitment, source_witness:_{atom:B, gloss:C, kind:literature_commitment_row, module:literature_vocabulary, predicate:canonical_commitment/2}}, D), ac(A, B, _), catch(literature_vocabulary:canonical_commitment(B, E), _, fail), (string(E)->C=E;format(string(C), "~w", [E])))).
rule(cw_algebra_claim, (algebra_claim_witness(A, edge_surface(B), C, D):-witness_dict:witness_dict(algebra_claim_crosswalk, closed_world_finite_verified_algebra_claim_edges, _{canonical:A, derivation:owner_predicate_edge_check, detail:edge_surface(B), legacy_functor:C, projection:verified_legacy_edge_surface, source:C, source_witness:E}, D), ac(A, _, F), member(edge(C, B), F), algebra_edge_source_witness(C, E))).
rule(cw_algebra_claim, (algebra_edge_source_witness('action_automata_registry:action_automaton_vocabulary/3(algebraic,programming_expression_evaluation)', _{action_kind:programming_expression_evaluation, kind:action_automaton_vocabulary_edge, module:action_automata_registry, operation:algebraic, predicate:action_automaton_vocabulary/3, vocabulary:A}):-catch(action_automata_registry:action_automaton_vocabulary(algebraic, programming_expression_evaluation, A), _, fail))).
rule(cw_algebra_claim, (algebra_edge_source_witness('action_automata_registry:action_automaton_vocabulary/3(algebraic,linear_pattern_contextual_rule)', _{action_kind:linear_pattern_contextual_rule, kind:action_automaton_vocabulary_edge, module:action_automata_registry, operation:algebraic, predicate:action_automaton_vocabulary/3, vocabulary:A}):-catch(action_automata_registry:action_automaton_vocabulary(algebraic, linear_pattern_contextual_rule, A), _, fail))).
rule(cw_algebra_claim, (algebra_edge_source_witness('action_automata_registry:action_automaton_vocabulary/3(calculus,direct_substitution)', _{action_kind:direct_substitution, kind:action_automaton_vocabulary_edge, module:action_automata_registry, operation:calculus, predicate:action_automaton_vocabulary/3, vocabulary:A}):-catch(action_automata_registry:action_automaton_vocabulary(calculus, direct_substitution, A), _, fail))).
rule(cw_algebra_claim, (algebra_edge_source_witness('action_automata_registry:action_automaton_vocabulary/3(addition,derived_fact_adjustment)', _{action_kind:derived_fact_adjustment, kind:action_automaton_vocabulary_edge, module:action_automata_registry, operation:addition, predicate:action_automaton_vocabulary/3, vocabulary:A}):-catch(action_automata_registry:action_automaton_vocabulary(addition, derived_fact_adjustment, A), _, fail))).
rule(cw_algebra_claim, (algebra_edge_source_witness('action_automata_registry:action_automaton_cluster/3(calculus,direct_substitution)', _{action_kind:direct_substitution, cluster:A, kind:action_automaton_cluster_edge, module:action_automata_registry, operation:calculus, predicate:action_automaton_cluster/3}):-catch(action_automata_registry:action_automaton_cluster(calculus, direct_substitution, A), _, fail))).
rule(cw_algebra_claim, (algebra_edge_source_witness('action_automata_registry:action_automaton_cluster/3(calculus,factor_cancel_substitute)', _{action_kind:factor_cancel_substitute, cluster:A, kind:action_automaton_cluster_edge, module:action_automata_registry, operation:calculus, predicate:action_automaton_cluster/3}):-catch(action_automata_registry:action_automaton_cluster(calculus, factor_cancel_substitute, A), _, fail))).
rule(cw_algebra_claim, (algebra_edge_source_witness('action_automata_registry:action_automaton_cluster/3(subtraction,sliding_constant_difference)', _{action_kind:sliding_constant_difference, cluster:A, kind:action_automaton_cluster_edge, module:action_automata_registry, operation:subtraction, predicate:action_automaton_cluster/3}):-catch(action_automata_registry:action_automaton_cluster(subtraction, sliding_constant_difference, A), _, fail))).
rule(cw_algebra_claim, (algebra_edge_source_witness('action_automata_registry:action_automaton_cluster/3(addition,unbalanced_make_base_compensation)', _{action_kind:unbalanced_make_base_compensation, cluster:A, kind:action_automaton_cluster_edge, module:action_automata_registry, operation:addition, predicate:action_automaton_cluster/3}):-catch(action_automata_registry:action_automaton_cluster(addition, unbalanced_make_base_compensation, A), _, fail))).
rule(cw_algebra_claim, (algebra_edge_source_witness('grounding_metaphors:metaphor_breaks_at/3(functions_are_sets_of_ordered_pairs,conceptual_distinction_between_rule_and_extension)', _{kind:grounding_metaphor_break_edge, metaphor:functions_are_sets_of_ordered_pairs, module:grounding_metaphors, predicate:metaphor_breaks_at/3, reason:A, target_inference:conceptual_distinction_between_rule_and_extension}):-catch(grounding_metaphors:metaphor_breaks_at(functions_are_sets_of_ordered_pairs, conceptual_distinction_between_rule_and_extension, A), _, fail))).
rule(cw_algebra_claim, (algebra_edge_source_witness('grounding_metaphors:metaphor_breaks_at/3(functions_are_curves,monster_functions_lacking_tangents_or_continuity)', _{kind:grounding_metaphor_break_edge, metaphor:functions_are_curves, module:grounding_metaphors, predicate:metaphor_breaks_at/3, reason:A, target_inference:monster_functions_lacking_tangents_or_continuity}):-catch(grounding_metaphors:metaphor_breaks_at(functions_are_curves, monster_functions_lacking_tangents_or_continuity, A), _, fail))).
rule(cw_algebra_claim, (algebra_edge_source_witness('grounding_metaphors:metaphor_breaks_at/3(arithmetic_is_object_collection,irrational_numbers)', _{kind:grounding_metaphor_break_edge, metaphor:arithmetic_is_object_collection, module:grounding_metaphors, predicate:metaphor_breaks_at/3, reason:A, target_inference:irrational_numbers}):-catch(grounding_metaphors:metaphor_breaks_at(arithmetic_is_object_collection, irrational_numbers, A), _, fail))).
rule(cw_algebra_claim, (algebra_edge_source_witness('grounding_metaphors:metaphor_breaks_at/3(arithmetic_is_object_construction,irrational_numbers)', _{kind:grounding_metaphor_break_edge, metaphor:arithmetic_is_object_construction, module:grounding_metaphors, predicate:metaphor_breaks_at/3, reason:A, target_inference:irrational_numbers}):-catch(grounding_metaphors:metaphor_breaks_at(arithmetic_is_object_construction, irrational_numbers, A), _, fail))).
rule(cw_algebra_claim, (algebra_edge_source_witness('misconception_registry:incompatibility_with/2(guess_and_check_rule,strategy(algebraic,linear_pattern_contextual_rule))', _{conflict:strategy(algebraic, linear_pattern_contextual_rule), kind:misconception_registry_incompatibility_edge, module:misconception_registry, move:guess_and_check_rule, predicate:incompatibility_with_witness/3, registry_witness:A}):-catch(misconception_registry:incompatibility_with_witness(guess_and_check_rule, strategy(algebraic, linear_pattern_contextual_rule), A), _, fail))).

% cw_arithmetic_property_claim
family(cw_arithmetic_property_claim).
edge(cw_arithmetic_property_claim, standard_2_ns_3,parity_witness/3,[recollection([tally,tally,tally,tally])],[2,3],call_once_bind_out).
rule(cw_arithmetic_property_claim, ap(associativity_single_operation, c_associativity_single_operation, ['grounding_metaphors:grounds_inference/3(arithmetic_is_object_collection,associativity_of_addition,associative_erf_for_collections)'])).
rule(cw_arithmetic_property_claim, ap(commutativity_operation_specific, c_commutativity_operation_specific, ['grounding_metaphors:grounds_inference/3(arithmetic_is_object_collection,commutativity_of_addition,pooling_order_invariance)', 'action_automata_registry:action_automaton_cluster/3(multiplication,commute_factors_preserve_product,multiplicative_factor_relations)'])).
rule(cw_arithmetic_property_claim, ap(distributivity_over_sum, c_distributivity_expansion_structure, ['action_automata_registry:action_automaton_cluster/3(multiplication,distribute_group_size_split,multiplicative_composite_units)'])).
rule(cw_arithmetic_property_claim, ap(inverse_operation_coordination, c_inverse_relation_structure, ['action_automata_registry:action_automaton_cluster/3(division,inverse_fact_decomposition,division_grouping_structures)'])).
rule(cw_arithmetic_property_claim, ap(number_fact_compression, c_number_fact_compression_fluency, ['action_automata_registry:action_automaton_cluster/3(addition,known_fact_retrieval,additive_fact_fluency)', 'action_automata_registry:action_automaton_cluster/3(addition,derived_fact_adjustment,additive_fact_fluency)'])).
rule(cw_arithmetic_property_claim, (claim_literature_atom(A, B):-ap(A, B, _))).
rule(cw_arithmetic_property_claim, (legacy_list(A, B):-ap(A, C, D), atomic_list_concat(['literature_vocabulary:canonical_commitment/2(', C, ')'], E), append([[E], D], B))).
rule(cw_arithmetic_property_claim, (vocabulary_source(A, B):-legacy_list(A, B))).
rule(cw_arithmetic_property_claim, (canonical_concept(A, B):-legacy_list(B, C), member(A, C))).
rule(cw_arithmetic_property_claim, (arithmetic_property_unified(A, B, C):-arithmetic_property_witness(A, B, C, _))).
rule(cw_arithmetic_property_claim, (arithmetic_property_witness(A, commitment(B, C), literature_commitment, D):-witness_dict:witness_dict(arithmetic_property_crosswalk, closed_world_finite_verified_arithmetic_property_edges, _{canonical:A, derivation:literature_canonical_commitment_lookup, detail:commitment(B, C), literature_atom:B, projection:literature_commitment_gloss, source:literature_commitment, source_witness:_{atom:B, gloss:C, kind:literature_commitment_row, module:literature_vocabulary, predicate:canonical_commitment/2}}, D), ap(A, B, _), catch(literature_vocabulary:canonical_commitment(B, E), _, fail), (string(E)->C=E;format(string(C), "~w", [E])))).
rule(cw_arithmetic_property_claim, (arithmetic_property_witness(A, edge(B), B, C):-witness_dict:witness_dict(arithmetic_property_crosswalk, closed_world_finite_verified_arithmetic_property_edges, _{canonical:A, derivation:owner_predicate_edge_check, detail:edge(B), legacy_functor:B, projection:verified_legacy_edge, source:B, source_witness:D}, C), ap(A, _, E), member(B, E), arithmetic_property_edge_source_witness(B, D))).
rule(cw_arithmetic_property_claim, (arithmetic_property_edge_source_witness('grounding_metaphors:grounds_inference/3(arithmetic_is_object_collection,associativity_of_addition,associative_erf_for_collections)', _{grounding_path:associative_erf_for_collections, grounding_witness:A, kind:grounding_metaphor_inference_edge, metaphor:arithmetic_is_object_collection, module:grounding_metaphors, predicate:grounds_inference_witness/4, target_inference:associativity_of_addition}):-catch(grounding_metaphors:grounds_inference_witness(arithmetic_is_object_collection, associativity_of_addition, associative_erf_for_collections, A), _, fail))).
rule(cw_arithmetic_property_claim, (arithmetic_property_edge_source_witness('grounding_metaphors:grounds_inference/3(arithmetic_is_object_collection,commutativity_of_addition,pooling_order_invariance)', _{grounding_path:pooling_order_invariance, grounding_witness:A, kind:grounding_metaphor_inference_edge, metaphor:arithmetic_is_object_collection, module:grounding_metaphors, predicate:grounds_inference_witness/4, target_inference:commutativity_of_addition}):-catch(grounding_metaphors:grounds_inference_witness(arithmetic_is_object_collection, commutativity_of_addition, pooling_order_invariance, A), _, fail))).
rule(cw_arithmetic_property_claim, (arithmetic_property_edge_source_witness('action_automata_registry:action_automaton_cluster/3(multiplication,commute_factors_preserve_product,multiplicative_factor_relations)', _{action_kind:commute_factors_preserve_product, cluster:multiplicative_factor_relations, kind:action_automaton_cluster_edge, module:action_automata_registry, operation:multiplication, predicate:action_automaton_cluster/3}):-catch(action_automata_registry:action_automaton_cluster(multiplication, commute_factors_preserve_product, multiplicative_factor_relations), _, fail))).
rule(cw_arithmetic_property_claim, (arithmetic_property_edge_source_witness('action_automata_registry:action_automaton_cluster/3(multiplication,distribute_group_size_split,multiplicative_composite_units)', _{action_kind:distribute_group_size_split, cluster:multiplicative_composite_units, kind:action_automaton_cluster_edge, module:action_automata_registry, operation:multiplication, predicate:action_automaton_cluster/3}):-catch(action_automata_registry:action_automaton_cluster(multiplication, distribute_group_size_split, multiplicative_composite_units), _, fail))).
rule(cw_arithmetic_property_claim, (arithmetic_property_edge_source_witness('action_automata_registry:action_automaton_cluster/3(division,inverse_fact_decomposition,division_grouping_structures)', _{action_kind:inverse_fact_decomposition, cluster:division_grouping_structures, kind:action_automaton_cluster_edge, module:action_automata_registry, operation:division, predicate:action_automaton_cluster/3}):-catch(action_automata_registry:action_automaton_cluster(division, inverse_fact_decomposition, division_grouping_structures), _, fail))).
rule(cw_arithmetic_property_claim, (arithmetic_property_edge_source_witness('action_automata_registry:action_automaton_cluster/3(addition,known_fact_retrieval,additive_fact_fluency)', _{action_kind:known_fact_retrieval, cluster:additive_fact_fluency, kind:action_automaton_cluster_edge, module:action_automata_registry, operation:addition, predicate:action_automaton_cluster/3}):-catch(action_automata_registry:action_automaton_cluster(addition, known_fact_retrieval, additive_fact_fluency), _, fail))).
rule(cw_arithmetic_property_claim, (arithmetic_property_edge_source_witness('action_automata_registry:action_automaton_cluster/3(addition,derived_fact_adjustment,additive_fact_fluency)', _{action_kind:derived_fact_adjustment, cluster:additive_fact_fluency, kind:action_automaton_cluster_edge, module:action_automata_registry, operation:addition, predicate:action_automaton_cluster/3}):-catch(action_automata_registry:action_automaton_cluster(addition, derived_fact_adjustment, additive_fact_fluency), _, fail))).

% cw_axiom_pack
family(cw_axiom_pack).
edge(cw_axiom_pack, sequent_engine,enabled_axiom_pack/1,[core],[],call_match_ground).
rule(cw_axiom_pack, (axiom_pack_unified(A,B):-axiom_pack_witness(A,B,_8862))).
rule(cw_axiom_pack, (axiom_pack_witness(A,enabled_predicate,B):-witness_dict:witness_dict(axiom_pack_enabled_state,closed_world_finite_current_sequent_engine_axiom_packs,_8970{derivation:owner_predicate_state_read,pack:A,projection:exported_enabled_pack_reader,source:enabled_predicate,source_witness:_{kind:axiom_pack_reader_row,module:sequent_engine,pack:A,predicate:enabled_axiom_pack/1}},B),catch(sequent_engine:enabled_axiom_pack(A),_,fail))).
rule(cw_axiom_pack, (axiom_pack_witness(A,enabled_store,B):-witness_dict:witness_dict(axiom_pack_enabled_state,closed_world_finite_current_sequent_engine_axiom_packs,_9186{derivation:owner_predicate_state_read,pack:A,projection:dynamic_enabled_pack_store,source:enabled_store,source_witness:_{kind:axiom_pack_store_row,module:sequent_engine,pack:A,predicate:axiom_pack_enabled/1}},B),catch(sequent_engine:axiom_pack_enabled(A),_,fail))).
rule(cw_axiom_pack, (axiom_pack_control(A,B,C,D):-axiom_pack_control_witness(A,B,C,D,_9386))).
rule(cw_axiom_pack, (axiom_pack_control_witness(A,B,C,D,E):-witness_dict:witness_dict(axiom_pack_control_surface,closed_world_finite_sequent_engine_axiom_pack_controls,_9526{arity:D,derivation:current_predicate_control_surface_check,functor:C,module:B,projection:side_effect_boundary_registry,side_effect_policy:I,source:control_registry,source_witness:_{boundary:H,kind:axiom_pack_control_predicate,module:B,predicate:C/D,variant:A},variant:A},E),axiom_pack_control_spec(A,B,C,D,I,H),current_predicate(B:C/D))).
rule(cw_axiom_pack, axiom_pack_control_spec(enable,sequent_engine,enable_axiom_pack,1,mutates_enabled_pack_store,asserts_known_pack_enabled)).
rule(cw_axiom_pack, axiom_pack_control_spec(disable,sequent_engine,disable_axiom_pack,1,mutates_enabled_pack_store,retracts_known_pack_enabled)).
rule(cw_axiom_pack, axiom_pack_control_spec(scoped,sequent_engine,with_axiom_packs,2,executes_goal_under_temporary_pack_set,setup_call_cleanup_restores_prior_pack_state)).
rule(cw_axiom_pack, canonical_concept('sequent_engine:enabled_axiom_pack/1',axiom_pack_unified)).
rule(cw_axiom_pack, canonical_concept('sequent_engine:axiom_pack_enabled/1',axiom_pack_unified)).
rule(cw_axiom_pack, canonical_concept('sequent_engine:enable_axiom_pack/1',axiom_pack_control)).
rule(cw_axiom_pack, canonical_concept('sequent_engine:disable_axiom_pack/1',axiom_pack_control)).
rule(cw_axiom_pack, canonical_concept('sequent_engine:with_axiom_packs/2',axiom_pack_control)).
rule(cw_axiom_pack, vocabulary_source(axiom_pack_unified,['sequent_engine:enabled_axiom_pack/1','sequent_engine:axiom_pack_enabled/1'])).
rule(cw_axiom_pack, vocabulary_source(axiom_pack_control,['sequent_engine:enable_axiom_pack/1','sequent_engine:disable_axiom_pack/1','sequent_engine:with_axiom_packs/2'])).

% cw_calculus_claim
family(cw_calculus_claim).
rule(cw_calculus_claim, cc(limit_process_evaluation, c_calculus_limit_process_definition, "Limits, continuity, and convergence are read as limiting processes.", ['action_automaton_cluster/3(calculus,direct_substitution)', 'action_automaton_cluster/3(calculus,factor_cancel_substitute)', 'action_automaton_cluster/3(calculus,bounded_numerator_over_diverging_denominator)'])).
rule(cw_calculus_claim, cc(rate_of_change_covariation, c_rate_of_change_covariation, "Rates of change and slopes coordinate covarying quantities.", ['action_automaton_vocabulary/3(algebraic,linear_pattern_contextual_rule)', 'action_automaton_vocabulary/3(algebraic,guess_and_check_rule)'])).
rule(cw_calculus_claim, cc(accumulation_rate_distinction, c_accumulation_rate_distinction, "Accumulation and rate of change are distinct quantities.", ['action_automaton_vocabulary/3(algebraic,linear_pattern_contextual_rule)'])).
rule(cw_calculus_claim, (claim_literature_atom(A, B):-cc(A, B, _, _))).
rule(cw_calculus_claim, (legacy_list(A, B):-cc(A, C, _, D), atomic_list_concat(['literature_vocabulary:canonical_commitment/2(', C, ')'], E), append([[E], D], B))).
rule(cw_calculus_claim, (vocabulary_source(A, B):-legacy_list(A, B))).
rule(cw_calculus_claim, (canonical_concept(A, B):-legacy_list(B, C), member(A, C))).
rule(cw_calculus_claim, (calculus_claim_unified(A, B, C):-calculus_claim_witness(A, B, C, _))).
rule(cw_calculus_claim, (calculus_claim_witness(A, commitment(B, C), literature_commitment, D):-witness_dict:witness_dict(calculus_claim_crosswalk, closed_world_finite_verified_calculus_claim_edges, _{canonical:A, derivation:literature_canonical_commitment_lookup, detail:commitment(B, C), literature_atom:B, projection:literature_commitment_gloss, source:literature_commitment, source_witness:_{atom:B, gloss:C, kind:literature_commitment_row, module:literature_vocabulary, predicate:canonical_commitment/2}}, D), cc(A, B, _, _), catch(literature_vocabulary:canonical_commitment(B, E), _, fail), (string(E)->C=E;format(string(C), "~w", [E])))).
rule(cw_calculus_claim, (calculus_claim_witness(A, edge(B), B, C):-witness_dict:witness_dict(calculus_claim_crosswalk, closed_world_finite_verified_calculus_claim_edges, _{canonical:A, derivation:owner_predicate_edge_check, detail:edge(B), legacy_functor:B, projection:verified_legacy_edge, source:B, source_witness:D}, C), cc(A, _, _, E), member(B, E), calculus_claim_edge_source_witness(B, D))).
rule(cw_calculus_claim, (calculus_claim_edge_source_witness('action_automaton_cluster/3(calculus,direct_substitution)', _{action_kind:direct_substitution, cluster:A, kind:action_automaton_cluster_edge, module:action_automata_registry, operation:calculus, predicate:action_automaton_cluster/3}):-catch(action_automata_registry:action_automaton_cluster(calculus, direct_substitution, A), _, fail))).
rule(cw_calculus_claim, (calculus_claim_edge_source_witness('action_automaton_cluster/3(calculus,factor_cancel_substitute)', _{action_kind:factor_cancel_substitute, cluster:A, kind:action_automaton_cluster_edge, module:action_automata_registry, operation:calculus, predicate:action_automaton_cluster/3}):-catch(action_automata_registry:action_automaton_cluster(calculus, factor_cancel_substitute, A), _, fail))).
rule(cw_calculus_claim, (calculus_claim_edge_source_witness('action_automaton_cluster/3(calculus,bounded_numerator_over_diverging_denominator)', _{action_kind:bounded_numerator_over_diverging_denominator, cluster:A, kind:action_automaton_cluster_edge, module:action_automata_registry, operation:calculus, predicate:action_automaton_cluster/3}):-catch(action_automata_registry:action_automaton_cluster(calculus, bounded_numerator_over_diverging_denominator, A), _, fail))).
rule(cw_calculus_claim, (calculus_claim_edge_source_witness('action_automaton_vocabulary/3(algebraic,linear_pattern_contextual_rule)', _{action_kind:linear_pattern_contextual_rule, kind:action_automaton_vocabulary_edge, module:action_automata_registry, operation:algebraic, predicate:action_automaton_vocabulary/3, vocabulary:A}):-catch(action_automata_registry:action_automaton_vocabulary(algebraic, linear_pattern_contextual_rule, A), _, fail))).
rule(cw_calculus_claim, (calculus_claim_edge_source_witness('action_automaton_vocabulary/3(algebraic,guess_and_check_rule)', _{action_kind:guess_and_check_rule, kind:action_automaton_vocabulary_edge, module:action_automata_registry, operation:algebraic, predicate:action_automaton_vocabulary/3, vocabulary:A}):-catch(action_automata_registry:action_automaton_vocabulary(algebraic, guess_and_check_rule, A), _, fail))).

% cw_decimal_claim
family(cw_decimal_claim).
rule(cw_decimal_claim, dc(decimal_place_value_alignment_in_column_arithmetic, c_decimal_place_value_alignment, [edge('misconception_registry:incompatibility_with/2(ragged_decimal_addition)', "Registered misconception: adding decimals right-aligned (ragged) rather than aligning on the point violates place-value alignment in column arithmetic."), edge('misconception_registry:incompatibility_with/2(no_borrow_across_point)', "Registered misconception: refusing to borrow across the decimal point violates place-value alignment in column subtraction."), edge('misconception_registry:incompatibility_with/2(sum_dp_ignoring_trailing_zeros)', "Registered misconception: summing decimal places while ignoring trailing zeros violates place-value alignment in column arithmetic.")])).
rule(cw_decimal_claim, dc(decimal_magnitude_ordered_by_place_value, c_decimal_place_value_ordering, [edge('misconception_registry:incompatibility_with/2(longer_is_larger_ordering)', "Registered misconception: ordering decimals by digit count (longer is larger) violates place-value ordering of magnitude."), edge('misconception_registry:incompatibility_with/2(natural_number_ordering)', "Registered misconception: ordering the decimal tail as a whole number violates place-value ordering of magnitude.")])).
rule(cw_decimal_claim, dc(decimal_point_as_place_value_locator, c_decimal_positional_notation, [edge('action_automata_registry:action_automaton_cluster/3(decimal,positional_decimal_reading)', "Decimal action automaton that reads the point as locating place-value units (positional reading)."), edge('action_automata_registry:action_automaton_cluster/3(decimal,decimal_whole_number_reading)', "Decimal action automaton that coordinates the whole-number and fractional sides across the point as one positional notation."), edge('misconception_registry:incompatibility_with/2(decimal_point_as_separator)', "Registered misconception: treating the point as separating two independent whole numbers violates the point-as-place-value-locator commitment."), edge('misconception_registry:incompatibility_with/2(decimal_part_as_integer)', "Registered misconception: reading the decimal part as an integer violates the point-as-place-value-locator commitment.")])).
rule(cw_decimal_claim, dc(decimal_trailing_zero_value_invariance, c_decimal_trailing_zero_invariance, [edge('misconception_registry:incompatibility_with/2(trailing_zeros_increase_value)', "Registered misconception: treating trailing zeros as increasing value violates trailing-zero value invariance."), edge('misconception_registry:incompatibility_with/2(sum_dp_ignoring_trailing_zeros)', "Registered misconception: summing decimal places while ignoring trailing zeros violates trailing-zero value invariance.")])).
rule(cw_decimal_claim, dc(positive_decimal_greater_than_zero, c_positive_decimal_exceeds_zero, [edge('misconception_registry:incompatibility_with/2(zero_larger_than_decimal)', "Registered misconception: judging zero larger than a positive decimal violates 'a positive decimal is greater than zero'."), edge('misconception_registry:incompatibility_with/2(decimals_are_negative)', "Registered misconception: treating decimals as negative violates 'a positive decimal is greater than zero'.")])).
rule(cw_decimal_claim, (claim_literature_atom(A, B):-dc(A, B, _))).
rule(cw_decimal_claim, (legacy_list(A, [B|C]):-dc(A, D, E), atomic_list_concat(['literature_vocabulary:canonical_commitment/2(', D, ')'], B), findall(F, member(edge(F, _), E), C))).
rule(cw_decimal_claim, (vocabulary_source(A, B):-legacy_list(A, B))).
rule(cw_decimal_claim, (canonical_concept(A, B):-legacy_list(B, C), member(A, C))).
rule(cw_decimal_claim, (decimal_claim_unified(A, B, C):-decimal_claim_witness(A, B, C, _))).
rule(cw_decimal_claim, (decimal_claim_witness(A, commitment(B, C), literature_commitment, D):-witness_dict:witness_dict(decimal_claim_crosswalk, closed_world_finite_verified_decimal_claim_edges, _{canonical:A, derivation:literature_canonical_commitment_lookup, detail:commitment(B, C), literature_atom:B, projection:literature_commitment_gloss, source:literature_commitment, source_witness:_{atom:B, gloss:C, kind:literature_commitment_row, module:literature_vocabulary, predicate:canonical_commitment/2}}, D), dc(A, B, _), catch(literature_vocabulary:canonical_commitment(B, E), _, fail), (string(E)->C=E;format(string(C), "~w", [E])))).
rule(cw_decimal_claim, (decimal_claim_witness(A, edge_surface(B), C, D):-witness_dict:witness_dict(decimal_claim_crosswalk, closed_world_finite_verified_decimal_claim_edges, _{canonical:A, derivation:owner_predicate_edge_check, detail:edge_surface(B), legacy_functor:C, projection:verified_legacy_edge_surface, source:C, source_witness:E}, D), dc(A, _, F), member(edge(C, B), F), decimal_edge_source_witness(C, E))).
rule(cw_decimal_claim, (decimal_edge_source_witness('action_automata_registry:action_automaton_cluster/3(decimal,positional_decimal_reading)', A):-decimal_action_cluster_witness(positional_decimal_reading, A))).
rule(cw_decimal_claim, (decimal_edge_source_witness('action_automata_registry:action_automaton_cluster/3(decimal,decimal_whole_number_reading)', A):-decimal_action_cluster_witness(decimal_whole_number_reading, A))).
rule(cw_decimal_claim, (decimal_edge_source_witness(A, B):-decimal_registry_functor(A, C), decimal_registry_incompatibility_witness(C, B))).
rule(cw_decimal_claim, (decimal_action_cluster_witness(A, _{action_kind:A, cluster:C, kind:action_automaton_cluster_edge, module:action_automata_registry, operation:decimal, predicate:action_automaton_cluster/3, vocabulary:B}):-catch(action_automata_registry:action_automaton_cluster(decimal, A, C), _, fail), catch(action_automata_registry:action_automaton_vocabulary(decimal, A, B), _, fail))).
rule(cw_decimal_claim, (decimal_registry_incompatibility_witness(A, _{conflict:B, incompatibility_witness:C, kind:misconception_registry_incompatibility_edge, module:misconception_registry, move:A, predicate:incompatibility_with/2}):-catch(once(decimal_registry_conflict(A, B, C)), _, fail))).
rule(cw_decimal_claim, (decimal_registry_conflict(A, B, C):-misconception_registry:incompatibility_with_witness(A, B, C))).
rule(cw_decimal_claim, (decimal_registry_conflict(A, B, C):-test_harness:arith_misconception(D, _, A, E, _, F), E\==skip, B=result_of(A, D, F), misconception_registry:incompatibility_with_witness(A, B, C))).
rule(cw_decimal_claim, decimal_registry_functor('misconception_registry:incompatibility_with/2(ragged_decimal_addition)', ragged_decimal_addition)).
rule(cw_decimal_claim, decimal_registry_functor('misconception_registry:incompatibility_with/2(no_borrow_across_point)', no_borrow_across_point)).
rule(cw_decimal_claim, decimal_registry_functor('misconception_registry:incompatibility_with/2(sum_dp_ignoring_trailing_zeros)', sum_dp_ignoring_trailing_zeros)).
rule(cw_decimal_claim, decimal_registry_functor('misconception_registry:incompatibility_with/2(longer_is_larger_ordering)', longer_is_larger_ordering)).
rule(cw_decimal_claim, decimal_registry_functor('misconception_registry:incompatibility_with/2(natural_number_ordering)', natural_number_ordering)).
rule(cw_decimal_claim, decimal_registry_functor('misconception_registry:incompatibility_with/2(decimal_point_as_separator)', decimal_point_as_separator)).
rule(cw_decimal_claim, decimal_registry_functor('misconception_registry:incompatibility_with/2(decimal_part_as_integer)', decimal_part_as_integer)).
rule(cw_decimal_claim, decimal_registry_functor('misconception_registry:incompatibility_with/2(trailing_zeros_increase_value)', trailing_zeros_increase_value)).
rule(cw_decimal_claim, decimal_registry_functor('misconception_registry:incompatibility_with/2(zero_larger_than_decimal)', zero_larger_than_decimal)).
rule(cw_decimal_claim, decimal_registry_functor('misconception_registry:incompatibility_with/2(decimals_are_negative)', decimals_are_negative)).

% cw_deontic_incoherence
family(cw_deontic_incoherence).
edge(cw_deontic_incoherence, deontic_scorekeeper,deontic_incoherent/2,[learner],[2],call_bind_out).
rule(cw_deontic_incoherence, (deontic_incoherence_unified(A,B,deontic):-deontic_incoherence_witness(A,B,deontic,_10848))).
rule(cw_deontic_incoherence, (deontic_incoherence_unified(A,B,scorecard):-deontic_incoherence_witness(A,B,scorecard,_10936))).
rule(cw_deontic_incoherence, (deontic_incoherence_witness(A,B,C,D):-witness_dict:witness_dict(deontic_incoherence,closed_world_finite_scorekeeper_state,_11020{agent:A,derivation:G,legacy_functor:F,reason:B,reason_family:H,source:C,support:I},D),deontic_incoherence_source(C,F),source_deontic_incoherence_witness(C,A,B,G,I),reason_family(B,H))).
rule(cw_deontic_incoherence, deontic_incoherence_source(deontic,'deontic_scorekeeper:deontic_incoherent/2')).
rule(cw_deontic_incoherence, deontic_incoherence_source(scorecard,'deontic_scorekeeper:scorecard/2')).
rule(cw_deontic_incoherence, (source_deontic_incoherence_witness(deontic,A,B,direct_relation_query,_11344{commitments:D,entitlements:E}):-catch(deontic_scorekeeper:deontic_incoherent(A,B),_,fail),scorekeeper_state(A,D,E))).
rule(cw_deontic_incoherence, (source_deontic_incoherence_witness(scorecard,A,B,scorecard_incoherence_unfold,_11520{incoherence_count:E,scorecard:D}):-catch(scorecard_incoherence(A,B,D),_,fail),get_dict(incoherences,D,G),length(G,E))).
rule(cw_deontic_incoherence, reason_family(commitment_without_entitlement(_11716),commitment_without_entitlement)).
rule(cw_deontic_incoherence, reason_family(entitlement_to_incompatible(_11766,_),entitlement_to_incompatible)).
rule(cw_deontic_incoherence, reason_family(committed_to_negation_of_consequence(_11842,_),committed_to_negation_of_consequence)).
rule(cw_deontic_incoherence, (reason_family(A,other):-nonvar(A),\+A=commitment_without_entitlement(_11928),\+A=entitlement_to_incompatible(_,_),\+A=committed_to_negation_of_consequence(_,_))).
rule(cw_deontic_incoherence, (scorekeeper_state(A,B,C):-findall(D,deontic_scorekeeper:commitment(A,D),E),sort(E,B),findall(F,deontic_scorekeeper:entitlement(A,F),G),sort(G,C))).
rule(cw_deontic_incoherence, (scorecard_incoherence(A,B):-scorecard_incoherence(A,B,_12364))).
rule(cw_deontic_incoherence, (scorecard_incoherence(A,B,C):-distinct(A,deontic_scorekeeper:commitment(A,_12448)),deontic_scorekeeper:scorecard(A,C),get_dict(incoherences,C,E),member(B,E))).
rule(cw_deontic_incoherence, canonical_concept('deontic_scorekeeper:deontic_incoherent/2',deontic_incoherence_unified)).
rule(cw_deontic_incoherence, canonical_concept('deontic_scorekeeper:scorecard/2',deontic_incoherence_unified)).
rule(cw_deontic_incoherence, vocabulary_source(deontic_incoherence_unified,['deontic_scorekeeper:deontic_incoherent/2','deontic_scorekeeper:scorecard/2'])).

% cw_domain_context
family(cw_domain_context).
edge(cw_domain_context, sequent_engine,current_domain/1,[],[1],call_bind_out).
rule(cw_domain_context, (domain_context_unified(A,_13222,domain_atom):-domain_context_witness(A,not_projected_by_source,domain_atom,_))).
rule(cw_domain_context, (domain_context_unified(_13320,B,domain_context):-domain_context_witness(not_projected_by_source,B,domain_context,_))).
rule(cw_domain_context, (domain_context_witness(A,B,C,D):-witness_dict:witness_dict(domain_context_crosswalk,closed_world_finite_loaded_domain_state,_13430{context:B,derivation:G,domain:A,legacy_functor:F,setter_policy:set_domain_excluded_mutates_dynamic_state,source:C,source_witness:H,value_shape:I},D),source_domain_context_witness(C,A,B,F,I,G,H))).
rule(cw_domain_context, (source_domain_context_witness(domain_atom,A,not_projected_by_source,'sequent_engine:current_domain/1',bare_domain_atom,current_domain_dynamic_fact_read,_13672{domain:A,finite_domain_set:[n,z,q],kind:current_domain_dynamic_state,mapped_context:C,mapping_witness:D,module:sequent_engine,predicate:current_domain/1}):-catch(sequent_engine:current_domain(A),_,fail),domain_context_mapping_witness(A,C,D))).
rule(cw_domain_context, (source_domain_context_witness(domain_context,not_projected_by_source,A,'sequent_engine:current_domain_context/1',named_context_projection,current_domain_context_projection,_13884{context:A,current_domain:C,finite_context_set:[natural_numbers,integers,rationals],kind:current_domain_context_projection,mapping_witness:D,module:sequent_engine,predicate:current_domain_context/1}):-catch(sequent_engine:current_domain_context(A),_,fail),catch(sequent_engine:current_domain(C),_,fail),domain_context_mapping_witness(C,A,D))).
rule(cw_domain_context, (domain_context_mapping_witness(A,B,_14156{context:B,domain:A,kind:finite_domain_context_mapping,mapping_table:[n-natural_numbers,z-integers,q-rationals],source_file:'formal/learner/axioms_domains.pl'}):-domain_context_pair(A,B),catch(sequent_engine:domain_to_context(A,B),_,fail))).
rule(cw_domain_context, domain_context_pair(n,natural_numbers)).
rule(cw_domain_context, domain_context_pair(z,integers)).
rule(cw_domain_context, domain_context_pair(q,rationals)).
rule(cw_domain_context, canonical_concept('sequent_engine:current_domain/1',domain_context_unified)).
rule(cw_domain_context, canonical_concept('sequent_engine:current_domain_context/1',domain_context_unified)).
rule(cw_domain_context, canonical_concept('sequent_engine:set_domain/1',domain_context_unified)).
rule(cw_domain_context, vocabulary_source(domain_context_unified,['sequent_engine:current_domain/1','sequent_engine:current_domain_context/1','sequent_engine:set_domain/1'])).

% cw_executable_practice
family(cw_executable_practice).
edge(cw_executable_practice, more_machine_learner,run_learned_strategy/5,[addition,2,3],[4,5],call_once_bind_out).
rule(cw_executable_practice, (executable_practice_unified(A,B,C,D):-executable_practice_witness(A,B,C,D,_15266))).
rule(cw_executable_practice, (executable_practice_witness(A,B,C,D,E):-witness_dict:witness_dict(executable_practice_registry_entry,closed_world_finite_loaded_executable_practice_registry,_15376{invocation_policy:H,legacy_functor:G,practice_kind:C,predicate:B,source:D,source_witness:I,variant:A},E),source_executable_practice_witness(A,B,C,D,G,H,I))).
rule(cw_executable_practice, (source_executable_practice_witness(mml_run_learned_strategy,more_machine_learner:run_learned_strategy/5,executor,more_machine_learner,'more_machine_learner:run_learned_strategy/5',registry_only_no_strategy_execution,_15606{dynamic:true,kind:dynamic_executor_presence,learned_clause_count:C,module:more_machine_learner,predicate:run_learned_strategy/5,properties:B,visibility:exported_predicate}):-predicate_presence_witness(more_machine_learner,run_learned_strategy,5,B),count_learned_strategy_clauses(C))).
rule(cw_executable_practice, (source_executable_practice_witness(oracle_list_available_strategies,oracle_server:list_available_strategies/2,name_catalogue,oracle_server,'oracle_server:list_available_strategies/2',read_only_catalogue_query,_15762{catalogue_size:D,kind:oracle_strategy_catalogue,module:oracle_server,operations:C,predicate:list_available_strategies/2,properties:B,sample_operation:add,sample_strategies:E}):-predicate_presence_witness(oracle_server,list_available_strategies,2,B),findall(F-G,catch(oracle_server:list_available_strategies(F,G),_,fail),I),pairs_keys(I,C),length(I,D),memberchk(add-E,I))).
rule(cw_executable_practice, (source_executable_practice_witness(mua_practice,mua_relations:practice/2,registry_fact,mua_relations,'mua_relations:practice/2',read_only_registry_fact_query,_16078{kind:mua_practice_registry,mapped_practice_count:G,module:mua_relations,practice_count:F,predicate:practice/2,properties:B,sample_action_kind:E,sample_description:D,sample_operation:C,sample_practice:p_count_on_from_larger}):-predicate_presence_witness(mua_relations,practice,2,B),catch(mua_relations:practice(p_count_on_from_larger,D),_,fail),catch(mua_relations:practice_kind(p_count_on_from_larger,C,E),_,fail),findall(J,catch(mua_relations:practice(J,_),_,fail),M),sort(M,N),length(N,F),findall(O,catch(mua_relations:practice_kind(O,_,_),_,fail),S),sort(S,T),length(T,G))).
rule(cw_executable_practice, (predicate_presence_witness(A,B,C,D):-catch(current_predicate(A:B/C),_16706,fail),findall(F,predicate_presence_property(A,B,C,F),G),sort(G,D))).
rule(cw_executable_practice, (predicate_presence_property(A,B,C,defined):-functor(D,B,C),predicate_property(A:D,defined))).
rule(cw_executable_practice, (predicate_presence_property(A,B,C,exported):-functor(D,B,C),predicate_property(A:D,exported))).
rule(cw_executable_practice, (predicate_presence_property(A,B,C,dynamic):-functor(D,B,C),predicate_property(A:D,dynamic))).
rule(cw_executable_practice, (count_learned_strategy_clauses(A):-findall(1,catch(clause(more_machine_learner:run_learned_strategy(_17260,_,_,_,_),_),_,fail),I),length(I,A))).
rule(cw_executable_practice, canonical_concept('more_machine_learner:run_learned_strategy/5',executable_practice)).
rule(cw_executable_practice, canonical_concept('oracle_server:list_available_strategies/2',executable_practice)).
rule(cw_executable_practice, canonical_concept('mua_relations:practice/2',executable_practice)).
rule(cw_executable_practice, vocabulary_source(executable_practice,['more_machine_learner:run_learned_strategy/5','oracle_server:list_available_strategies/2','mua_relations:practice/2'])).

% cw_fraction_extra_claim
family(cw_fraction_extra_claim).
rule(cw_fraction_extra_claim, fe(fraction_of_quantity_as_part_of_part, c_fraction_of_quantity_multiplication, ['action_automata_registry:action_automaton_cluster/3(fraction,area_model_part_of_part)', 'grounding_metaphors:grounds_inference/3(arithmetic_is_object_construction,fraction_multiplication_as_part_of_part)'])).
rule(cw_fraction_extra_claim, fe(fraction_stable_referent_whole, c_fraction_referent_whole_invariance, ['action_automata_registry:action_automaton_cluster/3(fraction,improper_fraction_iteration)', 'misconception_registry:incompatibility_with/2(improper_fraction_chain_loss)'])).
rule(cw_fraction_extra_claim, fe(fraction_part_disembedded_as_quantity, c_part_whole_disembedding, ['action_automata_registry:action_automaton_cluster/3(fraction,recursive_partition)', 'misconception_registry:incompatibility_with/2(clear_inner_referent)'])).
rule(cw_fraction_extra_claim, fe(cancellation_needs_common_factor, c_cancellation_requires_common_factor, ['action_automata_registry:action_automaton_cluster/3(calculus,factor_cancel_substitute)', 'action_automata_registry:action_automaton_cluster/3(calculus,factor_cancel_without_common_factor)', 'misconception_registry:incompatibility_with/2(factor_cancel_without_common_factor)'])).
rule(cw_fraction_extra_claim, fe(fraction_addition_on_common_unit, c_fraction_addition_common_unit, ['action_automata_registry:action_automaton_cluster/3(fraction,co_denominator_count_on_from_larger)'])).
rule(cw_fraction_extra_claim, fe(fraction_division_as_reversible_inverse, c_fraction_division_inverse_relation, ['action_automata_registry:action_automaton_cluster/3(fraction,solve_for_unit)', 'misconception_registry:incompatibility_with/2(iterate_only_no_reverse)'])).
rule(cw_fraction_extra_claim, (claim_literature_atom(A, B):-fe(A, B, _))).
rule(cw_fraction_extra_claim, (legacy_list(A, B):-fe(A, C, D), atomic_list_concat(['literature_vocabulary:canonical_commitment/2(', C, ')'], E), append([[E], D], B))).
rule(cw_fraction_extra_claim, (vocabulary_source(A, B):-legacy_list(A, B))).
rule(cw_fraction_extra_claim, (canonical_concept(A, B):-legacy_list(B, C), member(A, C))).
rule(cw_fraction_extra_claim, (fraction_extra_claim_unified(A, B, C):-fraction_extra_claim_witness(A, B, C, _))).
rule(cw_fraction_extra_claim, (fraction_extra_claim_witness(A, commitment(B, C), literature_commitment, D):-witness_dict:witness_dict(fraction_extra_claim_crosswalk, closed_world_finite_verified_fraction_extra_claim_edges, _{canonical:A, derivation:literature_canonical_commitment_lookup, detail:commitment(B, C), literature_atom:B, projection:literature_commitment_gloss, source:literature_commitment, source_witness:_{atom:B, gloss:C, kind:literature_commitment_row, module:literature_vocabulary, predicate:canonical_commitment/2}}, D), fe(A, B, _), catch(literature_vocabulary:canonical_commitment(B, E), _, fail), (string(E)->C=E;format(string(C), "~w", [E])))).
rule(cw_fraction_extra_claim, (fraction_extra_claim_witness(A, edge(B), B, C):-witness_dict:witness_dict(fraction_extra_claim_crosswalk, closed_world_finite_verified_fraction_extra_claim_edges, _{canonical:A, derivation:owner_predicate_edge_check, detail:edge(B), legacy_functor:B, projection:verified_legacy_edge, source:B, source_witness:D}, C), fe(A, _, E), member(B, E), fraction_extra_edge_witness(B, D))).
rule(cw_fraction_extra_claim, (fraction_extra_edge_witness('action_automata_registry:action_automaton_cluster/3(fraction,area_model_part_of_part)', A):-action_cluster_witness(fraction, area_model_part_of_part, A))).
rule(cw_fraction_extra_claim, (fraction_extra_edge_witness('action_automata_registry:action_automaton_cluster/3(fraction,improper_fraction_iteration)', A):-action_cluster_witness(fraction, improper_fraction_iteration, A))).
rule(cw_fraction_extra_claim, (fraction_extra_edge_witness('action_automata_registry:action_automaton_cluster/3(fraction,recursive_partition)', A):-action_cluster_witness(fraction, recursive_partition, A))).
rule(cw_fraction_extra_claim, (fraction_extra_edge_witness('action_automata_registry:action_automaton_cluster/3(calculus,factor_cancel_substitute)', A):-action_cluster_witness(calculus, factor_cancel_substitute, A))).
rule(cw_fraction_extra_claim, (fraction_extra_edge_witness('action_automata_registry:action_automaton_cluster/3(calculus,factor_cancel_without_common_factor)', A):-action_cluster_witness(calculus, factor_cancel_without_common_factor, A))).
rule(cw_fraction_extra_claim, (fraction_extra_edge_witness('action_automata_registry:action_automaton_cluster/3(fraction,co_denominator_count_on_from_larger)', A):-action_cluster_witness(fraction, co_denominator_count_on_from_larger, A))).
rule(cw_fraction_extra_claim, (fraction_extra_edge_witness('action_automata_registry:action_automaton_cluster/3(fraction,solve_for_unit)', A):-action_cluster_witness(fraction, solve_for_unit, A))).
rule(cw_fraction_extra_claim, (fraction_extra_edge_witness('grounding_metaphors:grounds_inference/3(arithmetic_is_object_construction,fraction_multiplication_as_part_of_part)', _{grounding_path:A, grounding_witness:B, kind:grounding_metaphor_inference_edge, metaphor:arithmetic_is_object_construction, module:grounding_metaphors, predicate:grounds_inference_witness/4, target_inference:fraction_multiplication_as_part_of_part}):-catch(grounding_metaphors:grounds_inference_witness(arithmetic_is_object_construction, fraction_multiplication_as_part_of_part, A, B), _, fail))).
rule(cw_fraction_extra_claim, (fraction_extra_edge_witness(A, B):-registry_functor(A, C), registry_incompatibility_witness(C, B))).
rule(cw_fraction_extra_claim, (action_cluster_witness(A, B, _{action_kind:B, cluster:D, kind:action_automaton_cluster_edge, module:action_automata_registry, operation:A, predicate:action_automaton_cluster/3, vocabulary:C}):-catch(action_automata_registry:action_automaton_cluster(A, B, D), _, fail), catch(action_automata_registry:action_automaton_vocabulary(A, B, C), _, fail))).
rule(cw_fraction_extra_claim, (registry_incompatibility_witness(A, _{conflict:B, incompatibility_witness:C, kind:misconception_registry_incompatibility_edge, module:misconception_registry, move:A, predicate:incompatibility_with_witness/3}):-catch(once(misconception_registry:incompatibility_with_witness(A, B, C)), _, fail))).
rule(cw_fraction_extra_claim, registry_functor('misconception_registry:incompatibility_with/2(improper_fraction_chain_loss)', improper_fraction_chain_loss)).
rule(cw_fraction_extra_claim, registry_functor('misconception_registry:incompatibility_with/2(clear_inner_referent)', clear_inner_referent)).
rule(cw_fraction_extra_claim, registry_functor('misconception_registry:incompatibility_with/2(factor_cancel_without_common_factor)', factor_cancel_without_common_factor)).
rule(cw_fraction_extra_claim, registry_functor('misconception_registry:incompatibility_with/2(iterate_only_no_reverse)', iterate_only_no_reverse)).

% cw_fsm_engine
family(cw_fsm_engine).
edge(cw_fsm_engine, fsm_engine,run_fsm/4,[sample_fsm,start],[3,4],registry_projection).
rule(cw_fsm_engine, (fsm_engine_unified(fsm_engine:run_fsm/4,strategy_generic):-fsm_engine_witness(fsm_engine:run_fsm/4,strategy_generic,_18300))).
rule(cw_fsm_engine, (fsm_engine_unified(fsm_engine:run_strategy/4,strategy_high_level):-fsm_engine_witness(fsm_engine:run_strategy/4,strategy_high_level,_18384))).
rule(cw_fsm_engine, (fsm_engine_unified(dialectical_engine:run_fsm/4,dialectical_generic):-fsm_engine_witness(dialectical_engine:run_fsm/4,dialectical_generic,_18468))).
rule(cw_fsm_engine, (fsm_engine_witness(A,B,C):-witness_dict:witness_dict(fsm_engine_registry_entry,closed_world_finite_loaded_fsm_executor_registry,_18526{descriptor:A,execution_policy:registry_only_no_fsm_execution,legacy_functor:E,side_effect_boundary:owning_executor_may_incur_cost_or_run_search,source:B,source_witness:F},C),fsm_engine_variant(B,A,E,G,H,I),predicate_presence_witness(G,H,I,F))).
rule(cw_fsm_engine, fsm_engine_variant(strategy_generic,fsm_engine:run_fsm/4,'fsm_engine:run_fsm/4',fsm_engine,run_fsm,4)).
rule(cw_fsm_engine, fsm_engine_variant(strategy_high_level,fsm_engine:run_strategy/4,'fsm_engine:run_strategy/4',fsm_engine,run_strategy,4)).
rule(cw_fsm_engine, fsm_engine_variant(dialectical_generic,dialectical_engine:run_fsm/4,'dialectical_engine:run_fsm/4',dialectical_engine,run_fsm,4)).
rule(cw_fsm_engine, (predicate_presence_witness(A,B,C,_18958{arity:C,descriptor:A:B/C,kind:loaded_predicate_presence,module:A,name:B,properties:E}):-variant_exists(A,B,C),predicate_properties(A,B,C,E))).
rule(cw_fsm_engine, (predicate_properties(A,B,C,D):-functor(E,B,C),findall(F,predicate_registry_property(A,E,F),D))).
rule(cw_fsm_engine, (predicate_registry_property(A,B,defined):-predicate_property(A:B,defined))).
rule(cw_fsm_engine, (predicate_registry_property(A,B,exported):-predicate_property(A:B,exported))).
rule(cw_fsm_engine, (predicate_registry_property(A,B,interpreted):-predicate_property(A:B,interpreted))).
rule(cw_fsm_engine, (predicate_registry_property(A,B,static):-predicate_property(A:B,static))).
rule(cw_fsm_engine, (variant_exists(A,B,C):-catch((current_predicate(A:B/C),functor(D,B,C),predicate_property(A:D,defined)),_19690,fail))).
rule(cw_fsm_engine, canonical_concept('fsm_engine:run_fsm/4',fsm_engine)).
rule(cw_fsm_engine, canonical_concept('fsm_engine:run_strategy/4',fsm_engine)).
rule(cw_fsm_engine, canonical_concept('dialectical_engine:run_fsm/4',fsm_engine)).
rule(cw_fsm_engine, vocabulary_source(fsm_engine,['fsm_engine:run_fsm/4','fsm_engine:run_strategy/4','dialectical_engine:run_fsm/4'])).

% cw_godel_primes
family(cw_godel_primes).
edge(cw_godel_primes, automata,is_prime/1,[2],[],call_match_ground).
rule(cw_godel_primes, (godel_primes_unified(is_prime(A),true,automata):-godel_primes_witness(is_prime(A),true,automata,_20532))).
rule(cw_godel_primes, (godel_primes_unified(nth_prime(A),B,automata):-godel_primes_witness(nth_prime(A),B,automata,_20616))).
rule(cw_godel_primes, (godel_primes_unified(product_of_list(A),B,sequent_engine):-godel_primes_witness(product_of_list(A),B,sequent_engine,_20712))).
rule(cw_godel_primes, (godel_primes_witness(A,B,C,D):-witness_dict:witness_dict(godel_prime_utility_crosswalk,closed_world_finite_loaded_godel_prime_utilities,_20796{derivation:G,legacy_functor:F,query:A,result:B,source:C,source_witness:H},D),godel_prime_source(C,F),source_godel_prime_witness(C,A,B,G,H))).
rule(cw_godel_primes, godel_prime_source(automata,'automata:is_prime/1 or automata:nth_prime/2')).
rule(cw_godel_primes, godel_prime_source(sequent_engine,'sequent_engine:product_of_list/2')).
rule(cw_godel_primes, (source_godel_prime_witness(automata,is_prime(A),true,automata_primality_check,B):-catch(once(automata:is_prime(A)),_21124,fail),prime_check_witness(A,B))).
rule(cw_godel_primes, (source_godel_prime_witness(automata,nth_prime(A),B,automata_prime_enumeration,_21216{final_prime_witness:E,index:A,kind:nth_prime_enumeration,prefix:D,prefix_length:A,prime:B}):-positive_integer(A),catch(once(automata:nth_prime(A,B)),_,fail),prime_prefix(A,D),last(D,B),prime_check_witness(B,E))).
rule(cw_godel_primes, (source_godel_prime_witness(sequent_engine,product_of_list(A),B,sequent_engine_product_fold,_21448{identity:1,kind:product_of_list_fold,list:A,product:B,steps:D}):-catch(once(sequent_engine:product_of_list(A,B)),_,fail),product_trace(A,1,B,D))).
rule(cw_godel_primes, (positive_integer(A):-integer(A),A>0)).
rule(cw_godel_primes, (prime_check_witness(2,_21708{kind:primality_check,number:2,reason:first_prime,result:prime}):-!)).
rule(cw_godel_primes, (prime_check_witness(A,_21780{candidates_checked:D,divisor_search:finite_odd_divisors_up_to_floor_sqrt,kind:primality_check,number:A,parity:odd,rejected_divisors:D,result:prime,upper_bound:C}):-integer(A),A>2,A mod 2=\=0,floor_sqrt(A,C),odd_divisor_candidates(3,C,D),no_divides(A,D))).
rule(cw_godel_primes, (floor_sqrt(A,B):-B is floor(sqrt(A)))).
rule(cw_godel_primes, (odd_divisor_candidates(A,B,[]):-A>B,!)).
rule(cw_godel_primes, (odd_divisor_candidates(A,B,[A|C]):-A=<B,D is A+2,odd_divisor_candidates(D,B,C))).
rule(cw_godel_primes, no_divides(_22304,[])).
rule(cw_godel_primes, (no_divides(A,[B|C]):-A mod B=\=0,no_divides(A,C))).
rule(cw_godel_primes, (prime_prefix(A,B):-findall(C,(between(1,A,D),catch(once(automata:nth_prime(D,C)),_22502,fail)),B),length(B,A))).
rule(cw_godel_primes, product_trace([],A,A,[])).
rule(cw_godel_primes, (product_trace([A|B],C,D,[_22700{accumulator_in:C,accumulator_out:F,factor:A}|G]):-number(A),F is C*A,product_trace(B,F,D,G))).
rule(cw_godel_primes, canonical_concept('automata:is_prime/1',godel_primes_unified)).
rule(cw_godel_primes, canonical_concept('automata:nth_prime/2',godel_primes_unified)).
rule(cw_godel_primes, canonical_concept('sequent_engine:product_of_list/2',godel_primes_unified)).
rule(cw_godel_primes, canonical_concept('axioms_number_theory:is_prime/1',godel_primes_unified)).
rule(cw_godel_primes, canonical_concept('axioms_number_theory:product_of_list/2',godel_primes_unified)).
rule(cw_godel_primes, vocabulary_source(godel_primes_unified,['automata:is_prime/1','automata:nth_prime/2','sequent_engine:product_of_list/2','axioms_number_theory:is_prime/1','axioms_number_theory:product_of_list/2'])).

% cw_grounded_arith
family(cw_grounded_arith).
edge(cw_grounded_arith, grounded_arithmetic,add_grounded/3,[recollection([]),recollection([tally])],[3],call_with_snapshot).
rule(cw_grounded_arith, (with_cost_snapshot(A):-with_cost_snapshot_witness(A,_23798))).
rule(cw_grounded_arith, (with_cost_snapshot_witness(A,_23860{after_goal:D,after_restore:E,before:C,kind:grounded_arithmetic_cost_snapshot,policy:restore_direct_cost_accumulator_after_read}):-(catch(grounded_arithmetic:direct_cost_accumulated(C),_,fail)->true;C=none),(catch(once(A),_,fail)->H=succeeded;H=failed),(catch(grounded_arithmetic:direct_cost_accumulated(D),_,fail)->true;D=unavailable),(C==none->true;catch(restore_cost(C),_,true)),(catch(grounded_arithmetic:direct_cost_accumulated(E),_,fail)->true;E=unavailable),H==succeeded)).
rule(cw_grounded_arith, (restore_cost(A):-retractall(grounded_arithmetic:direct_cost_accumulator(_24330)),assertz(grounded_arithmetic:direct_cost_accumulator(A)))).
rule(cw_grounded_arith, (grounded_arith_unified(A,B,C,D):-grounded_arith_witness(A,B,C,D,_24440))).
rule(cw_grounded_arith, (grounded_arith_witness(add,[A,B],C,grounded_arithmetic,D):-with_cost_snapshot_witness(grounded_arithmetic:add_grounded(A,B,C),E),grounded_operation_witness(add,[A,B],C,grounded_arithmetic,add_grounded/3,recollection_history_concatenation,E,D))).
rule(cw_grounded_arith, (grounded_arith_witness(subtract,[A,B],C,grounded_arithmetic,D):-with_cost_snapshot_witness(grounded_arithmetic:subtract_grounded(A,B,C),E),grounded_operation_witness(subtract,[A,B],C,grounded_arithmetic,subtract_grounded/3,recollection_history_removal,E,D))).
rule(cw_grounded_arith, (grounded_arith_witness(successor,[A],B,grounded_arithmetic,C):-with_cost_snapshot_witness(grounded_arithmetic:successor(A,B),D),grounded_operation_witness(successor,[A],B,grounded_arithmetic,successor/2,add_one_tally_to_history,D,C))).
rule(cw_grounded_arith, (grounded_arith_witness(base_decompose,[A,B],bases_remainder(C,D),grounded_utils,E):-with_cost_snapshot_witness(grounded_utils:base_decompose_grounded(A,B,C,D),F),grounded_operation_witness(base_decompose,[A,B],bases_remainder(C,D),grounded_utils,base_decompose_grounded/4,repeated_base_group_subtraction,F,E))).
rule(cw_grounded_arith, (grounded_arith_witness(is_recollection,[A],history(B),robinson_q,C):-witness_dict:witness_dict(grounded_arith_crosswalk,closed_world_finite_verified_grounded_arithmetic_operations,_25428{cost_witness:_{after_goal:not_applicable,after_restore:not_applicable,before:not_applicable,kind:grounded_arithmetic_cost_snapshot,policy:source_predicate_is_pure},derivation:owner_predicate_operation_check,inputs:[A],op:is_recollection,output:history(B),projection:constructive_number_trace,source:robinson_q,source_witness:_{evidence:B,inputs:[A],kind:grounded_arithmetic_source_row,module:robinson_q,output:history(B),predicate:is_recollection/2}},C),catch(robinson_q:is_recollection(A,B),_,fail))).
rule(cw_grounded_arith, (grounded_operation_witness(A,B,C,D,E,F,G,H):-witness_dict:witness_dict(grounded_arith_crosswalk,closed_world_finite_verified_grounded_arithmetic_operations,_25710{cost_witness:G,derivation:owner_predicate_operation_check,inputs:B,op:A,output:C,projection:F,source:D,source_witness:_{input_lengths:K,inputs:B,kind:grounded_arithmetic_source_row,module:D,output:C,output_length:L,predicate:E}},H),maplist(recollection_length,B,K),recollection_length(C,L))).
rule(cw_grounded_arith, (recollection_length(recollection(A),B):-!,length(A,B))).
rule(cw_grounded_arith, (recollection_length(bases_remainder(A,B),bases_remainder(C,D)):-!,recollection_length(A,C),recollection_length(B,D))).
rule(cw_grounded_arith, recollection_length(A,not_recollection(A))).
rule(cw_grounded_arith, canonical_concept('grounded_arithmetic:add_grounded/3',grounded_arith_unified)).
rule(cw_grounded_arith, canonical_concept('grounded_arithmetic:subtract_grounded/3',grounded_arith_unified)).
rule(cw_grounded_arith, canonical_concept('grounded_arithmetic:successor/2',grounded_arith_unified)).
rule(cw_grounded_arith, canonical_concept('grounded_utils:base_decompose_grounded/4',grounded_arith_unified)).
rule(cw_grounded_arith, canonical_concept('robinson_q:is_recollection/2',grounded_arith_unified)).
rule(cw_grounded_arith, vocabulary_source(grounded_arith_unified,['grounded_arithmetic:add_grounded/3','grounded_arithmetic:subtract_grounded/3','grounded_arithmetic:successor/2','grounded_utils:base_decompose_grounded/4','robinson_q:is_recollection/2'])).

% cw_grounding_metaphor
family(cw_grounding_metaphor).
edge(cw_grounding_metaphor, grounding_metaphors,grounding_metaphor_definition/4,[arithmetic_is_object_collection],[2,3,4],registry_projection).
rule(cw_grounding_metaphor, (:-catch(user:ensure_loaded('knowledge/geometry/schema.pl'),_27174,true))).
rule(cw_grounding_metaphor, (grounding_metaphor_unified(A,domains(B,C),definition):-grounding_metaphor_witness(A,domains(B,C),definition,_27250))).
rule(cw_grounding_metaphor, (grounding_metaphor_unified(A,domains(B,C),extension):-grounding_metaphor_witness(A,domains(B,C),extension,_27362))).
rule(cw_grounding_metaphor, (grounding_metaphor_unified(A,practice(B),mua_practice):-grounding_metaphor_witness(A,practice(B),mua_practice,_27470))).
rule(cw_grounding_metaphor, (grounding_metaphor_unified(A,concept(B),geometry):-grounding_metaphor_witness(A,concept(B),geometry,_27566))).
rule(cw_grounding_metaphor, (grounding_metaphor_witness(A,B,C,D):-witness_dict:witness_dict(grounding_metaphor_crosswalk,closed_world_finite_loaded_grounding_metaphor_sources,_27650{anchor:B,derivation:G,legacy_functor:F,metaphor:A,projection:I,source:C,source_witness:H},D),grounding_metaphor_source(C,F),source_grounding_metaphor_witness(C,A,B,I,G,H))).
rule(cw_grounding_metaphor, grounding_metaphor_source(definition,'grounding_metaphors:grounding_metaphor_definition/4')).
rule(cw_grounding_metaphor, grounding_metaphor_source(extension,'grounding_metaphors_extended:ln_metaphor/4')).
rule(cw_grounding_metaphor, grounding_metaphor_source(mua_practice,'mua_relations:grounding_metaphor/2')).
rule(cw_grounding_metaphor, grounding_metaphor_source(geometry,'geometry:metaphor_source/4')).
rule(cw_grounding_metaphor, (source_grounding_metaphor_witness(definition,A,domains(B,C),domains_projection,definition_table_lookup,D):-catch(grounding_metaphors:grounding_metaphor_definition(A,B,C,_28082),_,fail),(catch(grounding_metaphors:grounding_metaphor_definition_witness(A,D),_,fail)->true;source_definition_witness(A,B,C,D)))).
rule(cw_grounding_metaphor, (source_grounding_metaphor_witness(extension,A,domains(B,C),domains_projection,extension_table_lookup,_28296{citations:F,description:E,kind:ln_metaphor_definition,metaphor_id:A,metaphor_kind:G,source_domain:B,target_domain:C}):-catch(grounding_metaphors_extended:ln_metaphor(A,B,C,E),_,fail),findall(I,catch(grounding_metaphors_extended:ln_metaphor_citation(A,I),_,fail),F),(catch(grounding_metaphors_extended:ln_metaphor_kind(A,G),_,fail)->true;G=unknown))).
rule(cw_grounding_metaphor, (source_grounding_metaphor_witness(mua_practice,A,practice(B),practice_anchor_projection,mua_practice_assignment_lookup,C):-catch(mua_relations:grounding_metaphor(B,A),_28678,fail),mua_practice_source_witness(B,A,C))).
rule(cw_grounding_metaphor, (source_grounding_metaphor_witness(geometry,A,concept(B),concept_anchor_projection,geometry_metaphor_source_lookup,_28784{citation:E,concept:B,geometry_witness:F,kind:geometry_metaphor_source,mapping:D,metaphor:A}):-catch(user:metaphor_source(B,A,D,E),_,fail),geometry_metaphor_source_witness(B,A,F))).
rule(cw_grounding_metaphor, source_definition_witness(A,B,C,_28994{kind:grounding_metaphor_definition,metaphor_id:A,source:grounding_metaphors_definition_lookup,source_domain:B,target_domain:C})).
rule(cw_grounding_metaphor, (mua_practice_source_witness(A,B,_29104{bridge_witness:E,kind:mua_grounding_metaphor_assignment,mua_short_label:B,practice:A,translated_metaphor_id:D}):-catch(grounding_metaphors:grounding_metaphor_for_practice_witness(A,D,E),_,fail),!)).
rule(cw_grounding_metaphor, mua_practice_source_witness(A,B,_29282{bridge_witness:none,kind:mua_grounding_metaphor_assignment,mua_short_label:B,practice:A,translated_metaphor_id:none})).
rule(cw_grounding_metaphor, (geometry_metaphor_source_witness(A,B,C):-catch(user:lakoff_nunez_metaphor_witness(A,B,C),_29402,fail),!)).
rule(cw_grounding_metaphor, (geometry_metaphor_source_witness(A,B,C):-catch(user:measuring_stick_metaphor_witness(A,B,C),_29520,fail),!)).
rule(cw_grounding_metaphor, geometry_metaphor_source_witness(_29614,_,none)).
rule(cw_grounding_metaphor, canonical_concept('grounding_metaphors:grounding_metaphor_definition/4',grounding_metaphor)).
rule(cw_grounding_metaphor, canonical_concept('grounding_metaphors_extended:ln_metaphor/4',grounding_metaphor)).
rule(cw_grounding_metaphor, canonical_concept('mua_relations:grounding_metaphor/2',grounding_metaphor)).
rule(cw_grounding_metaphor, canonical_concept('geometry:metaphor_source/4',grounding_metaphor)).
rule(cw_grounding_metaphor, vocabulary_source(grounding_metaphor,['grounding_metaphors:grounding_metaphor_definition/4','grounding_metaphors_extended:ln_metaphor/4','mua_relations:grounding_metaphor/2','geometry:metaphor_source/4'])).

% cw_integer_signed_claim
family(cw_integer_signed_claim).
rule(cw_integer_signed_claim, isc(directed_signed_quantity_operations, c_signed_number_order_and_operations, [edge('action_automata_registry:action_automaton_cluster/3(integer,signed_addition_with_sign_relation)', "Productive integer action automaton coordinating sign and magnitude; the sign-sensitive signed_number_combination cluster."), edge('grounding_metaphors:grounds_inference/3(arithmetic_is_motion_along_a_path,negative_numbers)', "Negatives grounded as directed point-locations ordered on a path (Motion Along a Path)."), edge('grounding_metaphors:grounds_inference/3(multiplication_by_minus_one_is_rotation_by_180_degrees,product_of_two_negatives)', "Sign-sensitive multiplication grounded as rotation: two 180-degree rotations compose to identity."), edge('misconception_registry:incompatibility_with/2(drop_sign_use_magnitude_sum)', "Derived incompatibility: dropping the sign and summing magnitudes violates the sign-sensitive combination commitment.")])).
rule(cw_integer_signed_claim, isc(algebraic_term_sign_attachment, c_signed_term_structure, [edge('misconception_registry:incompatibility_with/2(detach_sign_group_terms)', "Registered misconception: detaching a number from its preceding operation sign and regrouping by sign violates 'each term carries its operation sign'.")])).
rule(cw_integer_signed_claim, (claim_literature_atom(A, B):-isc(A, B, _))).
rule(cw_integer_signed_claim, (legacy_list(A, [B|C]):-isc(A, D, E), atomic_list_concat(['literature_vocabulary:canonical_commitment/2(', D, ')'], B), findall(F, member(edge(F, _), E), C))).
rule(cw_integer_signed_claim, (vocabulary_source(A, B):-legacy_list(A, B))).
rule(cw_integer_signed_claim, (canonical_concept(A, B):-legacy_list(B, C), member(A, C))).
rule(cw_integer_signed_claim, (integer_signed_claim_unified(A, B, C):-integer_signed_claim_witness(A, B, C, _))).
rule(cw_integer_signed_claim, (integer_signed_claim_witness(A, commitment(B, C), literature_commitment, D):-witness_dict:witness_dict(integer_signed_claim_crosswalk, closed_world_finite_verified_integer_signed_claim_edges, _{canonical:A, derivation:literature_canonical_commitment_lookup, detail:commitment(B, C), literature_atom:B, projection:literature_commitment_gloss, source:literature_commitment, source_witness:_{atom:B, gloss:C, kind:literature_commitment_row, module:literature_vocabulary, predicate:canonical_commitment/2}}, D), isc(A, B, _), catch(literature_vocabulary:canonical_commitment(B, E), _, fail), (string(E)->C=E;format(string(C), "~w", [E])))).
rule(cw_integer_signed_claim, (integer_signed_claim_witness(A, edge_surface(B), C, D):-witness_dict:witness_dict(integer_signed_claim_crosswalk, closed_world_finite_verified_integer_signed_claim_edges, _{canonical:A, derivation:owner_predicate_edge_check, detail:edge_surface(B), legacy_functor:C, projection:verified_legacy_edge_surface, source:C, source_witness:E}, D), isc(A, _, F), member(edge(C, B), F), integer_signed_edge_source_witness(C, E))).
rule(cw_integer_signed_claim, (integer_signed_edge_source_witness('action_automata_registry:action_automaton_cluster/3(integer,signed_addition_with_sign_relation)', _{action_kind:signed_addition_with_sign_relation, cluster:A, kind:action_automaton_cluster_edge, module:action_automata_registry, operation:integer, predicate:action_automaton_cluster/3}):-catch(action_automata_registry:action_automaton_cluster(integer, signed_addition_with_sign_relation, A), _, fail))).
rule(cw_integer_signed_claim, (integer_signed_edge_source_witness('grounding_metaphors:grounds_inference/3(arithmetic_is_motion_along_a_path,negative_numbers)', _{grounding_path:A, grounding_witness:B, kind:grounding_metaphor_inference_edge, metaphor:arithmetic_is_motion_along_a_path, module:grounding_metaphors, predicate:grounds_inference_witness/4, target_inference:negative_numbers}):-catch(grounding_metaphors:grounds_inference_witness(arithmetic_is_motion_along_a_path, negative_numbers, A, B), _, fail))).
rule(cw_integer_signed_claim, (integer_signed_edge_source_witness('grounding_metaphors:grounds_inference/3(multiplication_by_minus_one_is_rotation_by_180_degrees,product_of_two_negatives)', _{grounding_path:A, grounding_witness:B, kind:grounding_metaphor_inference_edge, metaphor:multiplication_by_minus_one_is_rotation_by_180_degrees, module:grounding_metaphors, predicate:grounds_inference_witness/4, target_inference:product_of_two_negatives}):-catch(grounding_metaphors:grounds_inference_witness(multiplication_by_minus_one_is_rotation_by_180_degrees, product_of_two_negatives, A, B), _, fail))).
rule(cw_integer_signed_claim, (integer_signed_edge_source_witness('misconception_registry:incompatibility_with/2(drop_sign_use_magnitude_sum)', _{conflict:strategy(integer, signed_addition_with_sign_relation), kind:misconception_registry_incompatibility_edge, module:misconception_registry, move:drop_sign_use_magnitude_sum, predicate:incompatibility_with_witness/3, registry_witness:A}):-catch(once(misconception_registry:incompatibility_with_witness(drop_sign_use_magnitude_sum, strategy(integer, signed_addition_with_sign_relation), A)), _, fail))).
rule(cw_integer_signed_claim, (integer_signed_edge_source_witness('misconception_registry:incompatibility_with/2(detach_sign_group_terms)', _{conflict:result_of(detach_sign_group_terms, db_row(39498), 60), kind:misconception_registry_incompatibility_edge, module:misconception_registry, move:detach_sign_group_terms, predicate:incompatibility_with_witness/3, registry_witness:A}):-catch(once(misconception_registry:incompatibility_with_witness(detach_sign_group_terms, result_of(detach_sign_group_terms, db_row(39498), 60), A)), _, fail))).

% cw_magnitude_equivalence_claim
family(cw_magnitude_equivalence_claim).
rule(cw_magnitude_equivalence_claim, me(ratio_invariance_under_scaling, c_multiplicative_ratio_invariance, [ratio-scale_ratio_unit, ratio-additive_extension_of_ratio])).
rule(cw_magnitude_equivalence_claim, me(total_conserved_under_transformation, c_conservation_invariance, [multiplication-commute_factors_preserve_product, multiplication-regroup_to_base_preserving_total, subtraction-sliding_constant_difference])).
rule(cw_magnitude_equivalence_claim, (claim_literature_atom(A, B):-me(A, B, _))).
rule(cw_magnitude_equivalence_claim, (edge_functor(A-B, C):-atomic_list_concat(['action_automata_registry:action_automaton_cluster/3(', A, ',', B, ')'], C))).
rule(cw_magnitude_equivalence_claim, (legacy_list(A, B):-me(A, C, D), atomic_list_concat(['literature_vocabulary:canonical_commitment/2(', C, ')'], E), findall(F, (member(G, D), edge_functor(G, F)), H), append([[E], H], B))).
rule(cw_magnitude_equivalence_claim, (vocabulary_source(A, B):-legacy_list(A, B))).
rule(cw_magnitude_equivalence_claim, (canonical_concept(A, B):-legacy_list(B, C), member(A, C))).
rule(cw_magnitude_equivalence_claim, (magnitude_equivalence_claim_unified(A, B, C):-magnitude_equivalence_claim_witness(A, B, C, _))).
rule(cw_magnitude_equivalence_claim, (magnitude_equivalence_claim_witness(A, commitment(B, C), literature_commitment, D):-witness_dict:witness_dict(magnitude_equivalence_claim_crosswalk, closed_world_finite_verified_magnitude_equivalence_claim_edges, _{canonical:A, derivation:literature_canonical_commitment_lookup, detail:commitment(B, C), literature_atom:B, projection:literature_commitment_gloss, source:literature_commitment, source_witness:_{atom:B, gloss:C, kind:literature_commitment_row, module:literature_vocabulary, predicate:canonical_commitment/2}}, D), me(A, B, _), catch(literature_vocabulary:canonical_commitment(B, E), _, fail), (string(E)->C=E;format(string(C), "~w", [E])))).
rule(cw_magnitude_equivalence_claim, (magnitude_equivalence_claim_witness(A, edge(B-C), D, E):-witness_dict:witness_dict(magnitude_equivalence_claim_crosswalk, closed_world_finite_verified_magnitude_equivalence_claim_edges, _{canonical:A, derivation:owner_predicate_edge_check, detail:edge(B-C), legacy_functor:D, projection:verified_legacy_edge, source:D, source_witness:F}, E), me(A, _, G), member(B-C, G), edge_functor(B-C, D), magnitude_equivalence_edge_source_witness(B, C, F))).
rule(cw_magnitude_equivalence_claim, (magnitude_equivalence_edge_source_witness(A, B, _{action_kind:B, cluster:D, kind:action_automaton_cluster_edge, module:action_automata_registry, operation:A, predicate:action_automaton_cluster/3, vocabulary:C}):-catch(action_automata_registry:action_automaton_cluster(A, B, D), _, fail), catch(action_automata_registry:action_automaton_vocabulary(A, B, C), _, fail))).

% cw_material_inference
family(cw_material_inference).
edge(cw_material_inference, defeasible_inference,material_inference/3,[arithmetic_is_object_collection],[2,3],call_bind_out).
edge(cw_material_inference, semantic_axioms,semantic_material_witness/3,[[s(u)]],[2,3],call_once_bind_out).
edge(cw_material_inference, user,angle_material_claim_witness/2,[polygon_sum_over_triangle_sum],[2],call_once_bind_out).
edge(cw_material_inference, user,area_perimeter_material_claim_witness/2,[area_complete_unit_cover],[2],call_once_bind_out).
edge(cw_material_inference, user,attribute_material_claim_witness/2,[equal_sides_not_angle_equality],[2],call_once_bind_out).
edge(cw_material_inference, user,classification_material_claim_witness/2,[square_to_rectangle],[2],call_once_bind_out).
edge(cw_material_inference, user,coordinate_geometry_material_claim_witness/2,[slope_ratio_over_height_only],[2],call_once_bind_out).
edge(cw_material_inference, user,cross_link_material_inference_witness/5,[tilted_square_as_diamond],[2,3,4,5],call_bind_out).
edge(cw_material_inference, user,developmental_arc_material_witness/2,[polygon_angle_sum_via_triangulation],[2],call_once_bind_out).
edge(cw_material_inference, user,material_inference_profile_witness/3,[square_classification_arc],[2,3],call_once_bind_out).
edge(cw_material_inference, user,pythagorean_material_claim_witness/2,[pythagorean_side_equation],[2],call_once_bind_out).
edge(cw_material_inference, user,quad_inference_witness/4,[square,rectangle],[3,4],call_once_bind_out).
edge(cw_material_inference, user,shape_recognition_material_claim_witness/2,[property_classification_over_visual],[2],call_once_bind_out).
edge(cw_material_inference, user,similarity_material_claim_witness/2,[similarity_definition],[2],call_once_bind_out).
edge(cw_material_inference, user,synthesizer_anchor_material_witness/2,[category_container_inclusion_license],[2],call_once_bind_out).
edge(cw_material_inference, user,transformation_material_claim_witness/2,[point_image_rotation_center_diagnostic],[2],call_once_bind_out).
edge(cw_material_inference, user,validated_strength_lift_witness/3,[square_to_rectangle],[2,3],call_once_bind_out).
edge(cw_material_inference, user,van_hiele_level_material_claim_witness/2,[level_0_square_rectangle_example],[2],call_once_bind_out).
edge(cw_material_inference, user,volume_surface_area_material_claim_witness/2,[euler_convex_polyhedron_formula],[2],call_once_bind_out).
rule(cw_material_inference, (:-catch(user:ensure_loaded('knowledge/geometry/schema.pl'),_,true))).
rule(cw_material_inference, (material_inference_unified(A,B,C,defeasible):-material_inference_witness(A,B,C,defeasible,_30540))).
rule(cw_material_inference, (material_inference_unified(A,[B],C,deontic):-material_inference_witness(A,[B],C,deontic,_30660))).
rule(cw_material_inference, (material_inference_unified(A,[B],C,mua):-material_inference_witness(A,[B],C,mua,_30780))).
rule(cw_material_inference, (material_inference_unified(pml_rhythm,[A],B,pml_rhythm):-material_inference_witness(pml_rhythm,[A],B,pml_rhythm,_30900))).
rule(cw_material_inference, (material_inference_witness(A,B,C,D,E):-witness_dict:witness_dict(material_inference,closed_world_finite_loaded_material_sources,_30986{conclusion:C,derivation:H,id:A,legacy_functor:G,premise_projection:J,premises:B,source:D,source_witness:I},E),material_inference_source(D,G),source_material_inference_witness(D,A,B,C,J,H,I))).
rule(cw_material_inference, material_inference_source(defeasible,'defeasible_inference:material_inference/3')).
rule(cw_material_inference, material_inference_source(deontic,'deontic_scorekeeper:material_inference/3')).
rule(cw_material_inference, material_inference_source(mua,'deontic_scorekeeper:mua_derived_material_inference/3')).
rule(cw_material_inference, material_inference_source(pml_rhythm,'embodied_prover:pml_rhythm_axiom/2')).
rule(cw_material_inference, (source_material_inference_witness(defeasible,A,B,C,list_verbatim,defeasible_material_catalog_lookup,none):-catch(defeasible_inference:material_inference(A,B,C),_31442,fail))).
rule(cw_material_inference, (source_material_inference_witness(deontic,A,[B],C,single_premise_wrapped_as_list,finite_scorekeeper_rule_evaluation,none):-catch(deontic_scorekeeper:material_inference(A,B,C),_31570,fail))).
rule(cw_material_inference, (source_material_inference_witness(mua,A,[B],C,single_premise_wrapped_as_list,pp_sufficient_elaboration_witness,D):-catch(deontic_scorekeeper:mua_derived_material_inference_witness(A,B,C,D),_31700,fail))).
rule(cw_material_inference, (source_material_inference_witness(pml_rhythm,pml_rhythm,[A],B,antecedent_wrapped_as_singleton_list,loaded_multifile_pml_rhythm_axiom,none):-catch(embodied_prover:pml_rhythm_axiom(A,B),_31838,fail))).
rule(cw_material_inference, canonical_concept('defeasible_inference:material_inference/3',material_inference)).
rule(cw_material_inference, canonical_concept('deontic_scorekeeper:material_inference/3',material_inference)).
rule(cw_material_inference, canonical_concept('deontic_scorekeeper:mua_derived_material_inference/3',material_inference)).
rule(cw_material_inference, canonical_concept('embodied_prover:pml_rhythm_axiom/2',material_inference)).
rule(cw_material_inference, vocabulary_source(material_inference,['defeasible_inference:material_inference/3','deontic_scorekeeper:material_inference/3','deontic_scorekeeper:mua_derived_material_inference/3','embodied_prover:pml_rhythm_axiom/2'])).

% cw_metaphor_break
family(cw_metaphor_break).
edge(cw_metaphor_break, grounding_metaphors,metaphor_breaks_at/3,[arithmetic_is_object_collection,irrational_numbers],[3],call_bind_out).
rule(cw_metaphor_break, (metaphor_break_unified(A,B,C,grounding_catalogue):-metaphor_break_witness(A,B,C,grounding_catalogue,_450))).
rule(cw_metaphor_break, (metaphor_break_unified(A,B,none,mua):-metaphor_break_witness(A,B,none,mua,_554))).
rule(cw_metaphor_break, (metaphor_break_unified(A,compiled,B,compiled):-metaphor_break_witness(A,compiled,B,compiled,_646))).
rule(cw_metaphor_break, (metaphor_break_witness(A,B,C,D,E):-witness_dict:witness_dict(metaphor_break_crosswalk,closed_world_finite_loaded_metaphor_break_sources,_732{derivation:H,detail:C,inference:B,legacy_functor:G,metaphor:A,projection:J,source:D,source_witness:I},E),metaphor_break_source(D,G),source_metaphor_break_witness(D,A,B,C,J,H,I))).
rule(cw_metaphor_break, metaphor_break_source(grounding_catalogue,'grounding_metaphors:metaphor_breaks_at/3')).
rule(cw_metaphor_break, metaphor_break_source(mua,'mua_relations:metaphor_breaks_at/2')).
rule(cw_metaphor_break, metaphor_break_source(compiled,'defeasible_inference:compiled_break/2')).
rule(cw_metaphor_break, (source_metaphor_break_witness(grounding_catalogue,A,B,C,reason_preserved,catalogue_break_witness,D):-catch(grounding_metaphors:metaphor_break_witness(A,B,C,D),_1144,fail))).
rule(cw_metaphor_break, (source_metaphor_break_witness(mua,A,B,none,terse_pair_detail_absent,mua_break_pair_lookup,none):-catch(mua_relations:metaphor_breaks_at(A,B),_1274,fail))).
rule(cw_metaphor_break, (source_metaphor_break_witness(compiled,A,compiled,B,break_id_and_condition_set,compiled_incoherent_condition_lookup,_1350{break_id:A,condition_count:D,condition_set:B,kind:compiled_break_condition_set}):-catch(defeasible_inference:compiled_break(A,B),_,fail),length(B,D))).
rule(cw_metaphor_break, canonical_concept('grounding_metaphors:metaphor_breaks_at/3',metaphor_break_unified)).
rule(cw_metaphor_break, canonical_concept('grounding_metaphors:ln_metaphor_breaks_at/3',metaphor_break_unified)).
rule(cw_metaphor_break, canonical_concept('mua_relations:metaphor_breaks_at/2',metaphor_break_unified)).
rule(cw_metaphor_break, canonical_concept('defeasible_inference:compiled_break/2',metaphor_break_unified)).
rule(cw_metaphor_break, vocabulary_source(metaphor_break_unified,['grounding_metaphors:metaphor_breaks_at/3','grounding_metaphors:ln_metaphor_breaks_at/3','mua_relations:metaphor_breaks_at/2','defeasible_inference:compiled_break/2'])).

% cw_misconception_hook
family(cw_misconception_hook).
edge(cw_misconception_hook, action_automata_registry,action_automaton_hook/4,[addition,count_all],[3,4],registry_projection).
edge(cw_misconception_hook, sar_sub_action_pairs,subtractive_action_misconception_hook/3,[action_outcome(take_away_base_ones,[classification(productive),vocabulary([minuend,subtrahend,base_chunk,ones_chunk,running_difference])])],[2,3],call_bind_out).
edge(cw_misconception_hook, smr_mult_action_pairs,multiplicative_action_misconception_hook/3,[action_outcome(coordinate_groups_items,[classification(productive),vocabulary([group_count,item_count,composite_unit,total_items])])],[2,3],call_bind_out).
edge(cw_misconception_hook, smr_div_action_pairs,division_action_misconception_hook/3,[action_outcome(measure_groups_of_size,[classification(productive),vocabulary([total,group_size,measured_group,quotient,remainder])])],[2,3],call_bind_out).
edge(cw_misconception_hook, fraction_action_pairs,fraction_action_misconception_hook/3,[action_outcome(unit_fraction_iteration,[classification(productive),vocabulary([referent_whole,unit_fraction,iteration_count,denominator,completion_marker,beyond_whole])])],[2,3],call_bind_out).
edge(cw_misconception_hook, decimal_action_pairs,decimal_action_misconception_hook/3,[action_outcome(positional_decimal_reading,[classification(productive),vocabulary([decimal_mark,whole_part,fractional_part,place_value,tenths,hundredths,scale_unit])])],[2,3],call_bind_out).
edge(cw_misconception_hook, integer_action_pairs,integer_action_misconception_hook/3,[action_outcome(signed_addition_with_sign_relation,[classification(productive),vocabulary([signed_addend,sign,magnitude,sign_relation,same_sign_combination,opposite_sign_cancellation,signed_sum])])],[2,3],call_bind_out).
edge(cw_misconception_hook, ratio_action_pairs,ratio_action_misconception_hook/3,[action_outcome(scale_ratio_unit,[classification(productive),vocabulary([ratio_pair,unit_ratio,scale_factor,multiplicative_scaling,equivalent_ratio,first_term,second_term])])],[2,3],call_bind_out).
edge(cw_misconception_hook, diagnostic_validation_action_pairs,diagnostic_action_misconception_hook/3,[action_outcome(multiplicative_bound_invalidation,[classification(productive),subfamily(validation),vocabulary([proposed_quotient,dividend,divisor,inverse_multiplication,multiplicative_bound,upper_bound_check,invalidate_quotient,consistency_check]),verdict(valid)])],[2,3],call_bind_out).
edge(cw_misconception_hook, calculus_limits_action_pairs,calculus_action_misconception_hook/3,[action_outcome(factor_cancel_substitute,[classification(productive),vocabulary([removable_discontinuity,common_factor,cancel,reduced_expression,substitution,function_value])])],[2,3],call_bind_out).
edge(cw_misconception_hook, algebraic_action_pairs,algebraic_action_misconception_hook/3,[action_outcome(linear_pattern_contextual_rule,[classification(productive),vocabulary([linear_pattern,first_value,row_number,constant_rate_of_change,accumulated_change,explicit_rule,contextual_generalization,initial_value,far_term_prediction])])],[2,3],call_bind_out).
edge(cw_misconception_hook, probability_action_pairs,probability_action_misconception_hook/3,[action_outcome(terminal_tree_endpoint_probability_sum,[classification(productive),vocabulary([tree_diagram,terminal_branch,terminal_endpoint,stopping_condition,branch_probability,disjoint_outcomes,probability_sum,stake_split,non_equiprobable_terminal_paths])])],[2,3],call_bind_out).
rule(cw_misconception_hook, (misconception_hook_unified(A,B,C,D,action_registry):-misconception_hook_witness(A,B,C,D,action_registry,_2388))).
rule(cw_misconception_hook, (misconception_hook_unified(fraction,A,B,C,fraction_action):-misconception_hook_witness(fraction,A,B,C,fraction_action,_2508))).
rule(cw_misconception_hook, (misconception_hook_unified(A,misconception(B),C,D,literature_registry):-misconception_hook_witness(A,misconception(B),C,D,literature_registry,_2624))).
rule(cw_misconception_hook, (misconception_hook_witness(A,B,C,D,E,F):-witness_dict:witness_dict(misconception_hook_crosswalk,closed_world_finite_loaded_misconception_hook_sources,_2736{derivation:I,family:C,hook:D,legacy_functor:H,operation:A,outcome:B,projection:K,source:E,source_witness:J},F),source_misconception_hook_witness(E,A,B,C,D,H,K,I,J))).
rule(cw_misconception_hook, (source_misconception_hook_witness(action_registry,A,B,C,D,'action_automata_registry:action_automaton_hook/4',action_outcome_hook_extraction,registry_operation_dispatch,_2984{dispatched_legacy_functor:F,family:C,hook_fields:H,kind:action_automata_hook_dispatch,operation:A,outcome_kind:G,registry_predicate:'action_automata_registry:action_automaton_hook/4'}):-catch(action_automata_registry:action_automaton_hook(A,B,C,D),_,fail),action_hook_dispatch(A,F),outcome_kind(B,G),hook_fields(D,H))).
rule(cw_misconception_hook, (source_misconception_hook_witness(fraction_action,fraction,A,B,C,'fraction_action_pairs:fraction_action_misconception_hook/3',action_outcome_hook_extraction,direct_fraction_hook_extraction,_3256{family:B,hook_fields:F,kind:direct_fraction_hook_extraction,module:fraction_action_pairs,outcome_kind:E,predicate:fraction_action_misconception_hook/3}):-catch(fraction_action_pairs:fraction_action_misconception_hook(A,B,C),_,fail),outcome_kind(A,E),hook_fields(C,F))).
rule(cw_misconception_hook, (source_misconception_hook_witness(literature_registry,A,misconception(B),A,registry_hook(C,D,E),'misconception_registry:misconception_registry_entry/5',registry_entry_projected_to_hook,bounded_literature_registry_projection,_3498{citation:E,commitment:C,entitlement:D,kind:literature_registry_misconception_hook,module:misconception_registry,name:B,operation:A,predicate:misconception_registry_entry/5}):-catch(once(misconception_registry:misconception_registry_entry(B,A,E,C,D)),_,fail))).
rule(cw_misconception_hook, outcome_kind(action_outcome(A,_3716),A)).
rule(cw_misconception_hook, (outcome_kind(A,unknown):-nonvar(A),A\=action_outcome(_3788,_))).
rule(cw_misconception_hook, (hook_fields(action_misconception_hook(A),A):-!)).
rule(cw_misconception_hook, hook_fields(A,A)).
rule(cw_misconception_hook, action_hook_dispatch(addition,'sar_add_action_pairs:action_misconception_hook/3')).
rule(cw_misconception_hook, action_hook_dispatch(subtraction,'sar_sub_action_pairs:subtractive_action_misconception_hook/3')).
rule(cw_misconception_hook, action_hook_dispatch(multiplication,'smr_mult_action_pairs:multiplicative_action_misconception_hook/3')).
rule(cw_misconception_hook, action_hook_dispatch(division,'smr_div_action_pairs:division_action_misconception_hook/3')).
rule(cw_misconception_hook, action_hook_dispatch(fraction,'fraction_action_pairs:fraction_action_misconception_hook/3')).
rule(cw_misconception_hook, action_hook_dispatch(decimal,'decimal_action_pairs:decimal_action_misconception_hook/3')).
rule(cw_misconception_hook, action_hook_dispatch(integer,'integer_action_pairs:integer_action_misconception_hook/3')).
rule(cw_misconception_hook, action_hook_dispatch(ratio,'ratio_action_pairs:ratio_action_misconception_hook/3')).
rule(cw_misconception_hook, action_hook_dispatch(diagnostic,'diagnostic_validation_action_pairs:diagnostic_action_misconception_hook/3')).
rule(cw_misconception_hook, action_hook_dispatch(calculus,'calculus_limits_action_pairs:calculus_action_misconception_hook/3')).
rule(cw_misconception_hook, action_hook_dispatch(algebraic,'algebraic_action_pairs:algebraic_action_misconception_hook/3')).
rule(cw_misconception_hook, action_hook_dispatch(probability,'probability_action_pairs:probability_action_misconception_hook/3')).
rule(cw_misconception_hook, canonical_concept('action_automata_registry:action_automaton_hook/4',misconception_hook)).
rule(cw_misconception_hook, canonical_concept('fraction_action_pairs:fraction_action_misconception_hook/3',misconception_hook)).
rule(cw_misconception_hook, canonical_concept('misconception_registry:misconception_registry_entry/5',misconception_hook)).
rule(cw_misconception_hook, vocabulary_source(misconception_hook,['action_automata_registry:action_automaton_hook/4','fraction_action_pairs:fraction_action_misconception_hook/3','misconception_registry:misconception_registry_entry/5'])).

% cw_modal_context
family(cw_modal_context).
edge(cw_modal_context, meta_interpreter,is_modal_operator/2,[necessarily],[2],call_bind_out).
rule(cw_modal_context, (modal_context_unified(A,B,meta_interpreter):-modal_context_witness(A,B,meta_interpreter,_5308))).
rule(cw_modal_context, (modal_context_unified(A,B,embodied_prover):-modal_context_witness(A,B,embodied_prover,_5396))).
rule(cw_modal_context, (modal_context_unified(A,B,pml_modality):-modal_context_witness(A,B,pml_modality,_5484))).
rule(cw_modal_context, (modal_context_witness(A,B,C,D):-witness_dict:witness_dict(modal_context,closed_world_finite_loaded_modal_sources,_5568{context:B,derivation:G,legacy_functor:F,polarity:H,shape:I,source:C,term:A},D),modal_context_source(C,F),source_modal_context_witness(C,A,B,H,I,G))).
rule(cw_modal_context, modal_context_source(meta_interpreter,'meta_interpreter:is_modal_operator/2')).
rule(cw_modal_context, modal_context_source(embodied_prover,'embodied_prover:determine_modal_context/2')).
rule(cw_modal_context, modal_context_source(pml_modality,'embodied_prover:is_pml_modality/1')).
rule(cw_modal_context, (source_modal_context_witness(meta_interpreter,A,B,C,bare_polarized_operator,fact_table_lookup):-catch(meta_interpreter:is_modal_operator(A,B),_5956,fail),modal_operator_polarity(A,C))).
rule(cw_modal_context, (source_modal_context_witness(embodied_prover,A,B,C,bare_polarized_operator,functor_dispatch):-catch(embodied_prover:determine_modal_context(A,B),_6084,fail),modal_operator_polarity(A,C))).
rule(cw_modal_context, (source_modal_context_witness(pml_modality,A,B,C,mode_wrapped_pml_operator,mode_wrapper_recognizer_plus_inner_polarity):-catch((embodied_prover:is_pml_modality(A),A=..[_6210,E],functor(E,F,_),operator_context(F,B)),_,fail),modal_operator_polarity(E,C))).
rule(cw_modal_context, (modal_operator_polarity(A,B):-nonvar(A),functor(A,C,_6448),operator_polarity(C,B))).
rule(cw_modal_context, operator_polarity(comp_nec,compressive_necessity)).
rule(cw_modal_context, operator_polarity(comp_poss,compressive_possibility)).
rule(cw_modal_context, operator_polarity(exp_nec,expansive_necessity)).
rule(cw_modal_context, operator_polarity(exp_poss,expansive_possibility)).
rule(cw_modal_context, polarity_context(compressive_necessity,compressive)).
rule(cw_modal_context, polarity_context(compressive_possibility,compressive)).
rule(cw_modal_context, polarity_context(expansive_necessity,expansive)).
rule(cw_modal_context, polarity_context(expansive_possibility,expansive)).
rule(cw_modal_context, (operator_context(A,B):-operator_polarity(A,C),polarity_context(C,B))).
rule(cw_modal_context, canonical_concept('meta_interpreter:is_modal_operator/2',modal_context_unified)).
rule(cw_modal_context, canonical_concept('embodied_prover:determine_modal_context/2',modal_context_unified)).
rule(cw_modal_context, canonical_concept('embodied_prover:is_pml_modality/1',modal_context_unified)).
rule(cw_modal_context, vocabulary_source(modal_context_unified,['meta_interpreter:is_modal_operator/2','embodied_prover:determine_modal_context/2','embodied_prover:is_pml_modality/1'])).

% cw_mua_coherence
family(cw_mua_coherence).
edge(cw_mua_coherence, mua_relations,kind_mua_coherence/3,[fraction,"unit fraction"],[3],call_bind_out).
rule(cw_mua_coherence, (mua_coherence_unified(A,B,C,pml_vocabulary):-mua_coherence_witness(A,B,C,pml_vocabulary,_7786))).
rule(cw_mua_coherence, (mua_coherence_unified(axiom_batch,A,B,pml_axiom_batch):-mua_coherence_witness(axiom_batch,A,B,pml_axiom_batch,_7890))).
rule(cw_mua_coherence, (mua_coherence_witness(A,B,C,D,E):-witness_dict:witness_dict(mua_coherence_crosswalk,closed_world_finite_loaded_mua_coherence_sources,_7976{derivation:H,input_scope:J,legacy_functor:G,score:C,score_meaning:K,source:D,source_witness:I,subject:A},E),mua_coherence_source(D,G),source_mua_coherence_witness(D,A,B,C,J,K,H,I))).
rule(cw_mua_coherence, (mua_coherence_source_witness(A,B,C,D,E):-mua_coherence_witness(A,B,C,D,F),get_dict(source_witness,F,E))).
rule(cw_mua_coherence, mua_coherence_source(pml_vocabulary,'mua_relations:kind_mua_coherence/3')).
rule(cw_mua_coherence, mua_coherence_source(pml_axiom_batch,'hermes_encyclopedia:pml_score_dict/2')).
rule(cw_mua_coherence, (source_mua_coherence_witness(pml_vocabulary,A,B,C,lower_cased_corpus_row_text,vocabulary_terms_hit_count,kind_vocabulary_hit_scan,D):-catch(mua_relations:kind_mua_coherence_witness(A,B,C,D),_8514,fail))).
rule(cw_mua_coherence, (source_mua_coherence_witness(pml_axiom_batch,axiom_batch,A,B,parsed_reader_axiom_clause_strings,valid_reader_axiom_count,pml_clause_validation,_8614{clause_count:D,kind:hermes_pml_axiom_batch_score,valid_count:B,validation:E}):-catch(hermes_encyclopedia:pml_score_dict(A,E),_,fail),get_dict(valid_count,E,B),get_dict(clause_count,E,D))).
rule(cw_mua_coherence, canonical_concept('mua_relations:kind_mua_coherence/3',mua_coherence_unified)).
rule(cw_mua_coherence, canonical_concept('hermes_encyclopedia:pml_score_dict/2',mua_coherence_unified)).
rule(cw_mua_coherence, vocabulary_source(mua_coherence_unified,['mua_relations:kind_mua_coherence/3','hermes_encyclopedia:pml_score_dict/2'])).

% cw_multiplication_division_claim
family(cw_multiplication_division_claim).
edge(cw_multiplication_division_claim, standard_3_ca_3_4,mult_div_family_witness/5,[recollection([tally,tally,tally]),recollection([tally,tally,tally,tally])],[3,4,5],call_once_bind_out).
rule(cw_multiplication_division_claim, md(equal_groups_composite_unit, c_equal_groups_equal_size, [edge(cluster(multiplication, coordinate_groups_items), 'action_automata_registry:action_automaton_cluster/3(multiplication,coordinate_groups_items)'), edge(cluster(multiplication, repeat_equal_groups), 'action_automata_registry:action_automaton_cluster/3(multiplication,repeat_equal_groups)')])).
rule(cw_multiplication_division_claim, md(fair_share_partition_grouping, c_equal_sharing_partition_model, [edge(cluster(division, fair_share_equal_groups), 'action_automata_registry:action_automaton_cluster/3(division,fair_share_equal_groups)')])).
rule(cw_multiplication_division_claim, md(division_quotient_remainder_coordination, c_division_structure_and_remainder, [edge(cluster(division, share_into_divisor_groups), 'action_automata_registry:action_automaton_cluster/3(division,share_into_divisor_groups)'), edge(vocabulary(division, measure_groups_of_size), 'action_automata_registry:action_automaton_vocabulary/3(division,measure_groups_of_size)')])).
rule(cw_multiplication_division_claim, md(division_by_zero_undefined_deontic, c_division_by_zero_undefined, [edge(incompatibility(division_by_zero_numerical), 'misconception_registry:incompatibility_with/2(division_by_zero_numerical)')])).
rule(cw_multiplication_division_claim, md(partial_product_not_additive_reduction, c_multiplicative_structure_not_additive, [edge(vocabulary(multiplication, distribute_group_size_split), 'action_automata_registry:action_automaton_vocabulary/3(multiplication,distribute_group_size_split)'), edge(cluster(multiplication, add_counts_without_composite_unit), 'action_automata_registry:action_automaton_cluster/3(multiplication,add_counts_without_composite_unit)')])).
rule(cw_multiplication_division_claim, md(number_factor_multiple_structure, c_number_multiplicative_structure, [edge(is_prime, 'formal/formalization/axioms_number_theory:is_prime/1'), edge(find_prime_factor, 'formal/formalization/axioms_number_theory:find_prime_factor/2')])).
rule(cw_multiplication_division_claim, (claim_literature_atom(A, B):-md(A, B, _))).
rule(cw_multiplication_division_claim, (legacy_list(A, B):-md(A, C, D), atomic_list_concat(['literature_vocabulary:canonical_commitment/2(', C, ')'], E), findall(F, member(edge(_, F), D), G), append([[E], G], B))).
rule(cw_multiplication_division_claim, (vocabulary_source(A, B):-legacy_list(A, B))).
rule(cw_multiplication_division_claim, (canonical_concept(A, B):-legacy_list(B, C), member(A, C))).
rule(cw_multiplication_division_claim, (multiplication_division_claim_unified(A, commitment(B, C), literature_commitment):-multiplication_division_claim_witness(A, commitment(B, C), literature_commitment, _))).
rule(cw_multiplication_division_claim, (multiplication_division_claim_unified(A, edge(B), C):-multiplication_division_claim_witness(A, edge(B), C, _))).
rule(cw_multiplication_division_claim, (multiplication_division_claim_witness(A, commitment(B, C), literature_commitment, D):-witness_dict:witness_dict(multiplication_division_claim_crosswalk, closed_world_finite_verified_multiplication_division_claim_edges, _{canonical:A, derivation:literature_canonical_commitment_lookup, detail:commitment(B, C), literature_atom:B, projection:literature_commitment_gloss, source:literature_commitment, source_witness:_{atom:B, gloss:C, kind:literature_commitment_row, module:literature_vocabulary, predicate:canonical_commitment/2}}, D), md(A, B, _), catch(literature_vocabulary:canonical_commitment(B, E), _, fail), (string(E)->C=E;format(string(C), "~w", [E])))).
rule(cw_multiplication_division_claim, (multiplication_division_claim_witness(A, edge(B), C, D):-witness_dict:witness_dict(multiplication_division_claim_crosswalk, closed_world_finite_verified_multiplication_division_claim_edges, _{canonical:A, derivation:owner_predicate_edge_check, detail:edge(B), legacy_functor:C, projection:verified_legacy_edge, source:C, source_witness:E}, D), md(A, _, F), member(edge(B, C), F), multiplication_division_edge_source_witness(B, E))).
rule(cw_multiplication_division_claim, (multiplication_division_edge_source_witness(cluster(A, B), _{action_kind:B, cluster:D, kind:action_automaton_cluster_edge, module:action_automata_registry, operation:A, predicate:action_automaton_cluster/3, vocabulary:C}):-catch(action_automata_registry:action_automaton_cluster(A, B, D), _, fail), catch(action_automata_registry:action_automaton_vocabulary(A, B, C), _, fail))).
rule(cw_multiplication_division_claim, (multiplication_division_edge_source_witness(vocabulary(A, B), _{action_kind:B, kind:action_automaton_vocabulary_edge, module:action_automata_registry, operation:A, predicate:action_automaton_vocabulary/3, vocabulary:C}):-catch(action_automata_registry:action_automaton_vocabulary(A, B, C), _, fail))).
rule(cw_multiplication_division_claim, (multiplication_division_edge_source_witness(incompatibility(division_by_zero_numerical), _{conflict:A, incompatibility_witness:B, kind:misconception_registry_incompatibility_edge, module:misconception_registry, move:division_by_zero_numerical, predicate:incompatibility_with/2}):-catch(once(misconception_registry:incompatibility_with_witness(division_by_zero_numerical, A, B)), _, fail))).
rule(cw_multiplication_division_claim, (multiplication_division_edge_source_witness(is_prime, _{kind:number_theory_prime_case_edge, legacy_predicate:is_prime/1, module:sequent_engine, number_theory_witness:C, prime_fact:B, sample_list:[2, 3, 5], sample_prime:A, source_file:'formal/formalization/axioms_number_theory.pl'}):-catch(sequent_engine:number_theory_self_defeat_witness([2, 3, 5], C), _, fail), get_dict(prime_case, C, D), get_dict(prime, D, A), get_dict(prime_fact, D, B))).
rule(cw_multiplication_division_claim, (multiplication_division_edge_source_witness(find_prime_factor, _{divides:C, kind:number_theory_factor_edge, legacy_predicate:find_prime_factor/2, module:sequent_engine, number_theory_witness:A, prime_factor:B, sample_integer:111, sample_list:[2, 5, 11], source_file:'formal/formalization/axioms_number_theory.pl'}):-catch(sequent_engine:number_theory_factor_witness(111, [2, 5, 11], A), _, fail), get_dict(prime_factor, A, B), get_dict(divides, A, C))).

% cw_normative_crisis
family(cw_normative_crisis).
edge(cw_normative_crisis, sequent_engine,prohibition/2,[natural_numbers,subtract(1,2,-1)],[],call_once_bind_out).
rule(cw_normative_crisis, (normative_crisis_unified(A,B,prohibition):-normative_crisis_witness(A,B,prohibition,_9514))).
rule(cw_normative_crisis, (normative_crisis_witness(A,B,C,D):-witness_dict:witness_dict(normative_crisis,closed_world_finite_live_domain_configuration,_9598{context:A,derivation:G,goal:B,goal_family:I,legacy_functor:F,source:C,support:H},D),normative_crisis_source(C,F),source_normative_crisis_witness(C,A,B,I,G,H))).
rule(cw_normative_crisis, normative_crisis_source(prohibition,'sequent_engine:prohibition/2')).
rule(cw_normative_crisis, (source_normative_crisis_witness(prohibition,A,B,C,non_mutating_prohibition_query,_9866{current_context:G,current_domain:E,domains_pack_enabled:F}):-catch(once(sequent_engine:prohibition(A,B)),_,fail),domains_pack_enabled(F),catch(sequent_engine:current_domain(E),_,E=unknown),catch(sequent_engine:current_domain_context(G),_,G=unknown),goal_family(B,C))).
rule(cw_normative_crisis, (domains_pack_enabled(true):-catch(sequent_engine:enabled_axiom_pack(domains),_10208,fail),!)).
rule(cw_normative_crisis, domains_pack_enabled(false)).
rule(cw_normative_crisis, (goal_family(subtract(A,B,_10314),subtract_larger_from_smaller_in_naturals):-number(A),number(B),B>A,!)).
rule(cw_normative_crisis, (goal_family(subtract(_10426,_,_),subtraction_not_closed_in_current_domain):-!)).
rule(cw_normative_crisis, (goal_family(divide(_10534,_,_),division_not_closed_in_current_domain):-!)).
rule(cw_normative_crisis, (goal_family(A,other_core_operation):-nonvar(A))).
rule(cw_normative_crisis, normative_crisis_variant(prohibition/2,'sequent_engine:prohibition/2':queryable_fact)).
rule(cw_normative_crisis, normative_crisis_variant(normative_crisis/2,'sequent_engine:normative_crisis/2':exception_term)).
rule(cw_normative_crisis, normative_crisis_variant(check_norms/1,'sequent_engine:check_norms/1':executor)).
rule(cw_normative_crisis, normative_crisis_variant(handle_normative_crisis/2,'reorganization_engine:handle_normative_crisis/2':executor)).
rule(cw_normative_crisis, canonical_concept('sequent_engine:prohibition/2',normative_crisis)).
rule(cw_normative_crisis, canonical_concept('sequent_engine:normative_crisis/2',normative_crisis)).
rule(cw_normative_crisis, canonical_concept('sequent_engine:check_norms/1',normative_crisis)).
rule(cw_normative_crisis, canonical_concept('reorganization_engine:handle_normative_crisis/2',normative_crisis)).
rule(cw_normative_crisis, vocabulary_source(normative_crisis,['sequent_engine:prohibition/2','sequent_engine:normative_crisis/2','sequent_engine:check_norms/1','reorganization_engine:handle_normative_crisis/2'])).

% cw_orr_entry
family(cw_orr_entry).
edge(cw_orr_entry, execution_handler,run_computation/2,[add(1,1)],[2],call_once_bind_out).
rule(cw_orr_entry, (orr_entry_unified(A,B,C,D):-orr_entry_witness(A,B,C,D,_11746))).
rule(cw_orr_entry, (orr_entry_witness(A,B,C,D,E):-witness_dict:witness_dict(orr_entry_registry_entry,closed_world_finite_loaded_orr_entry_registry,_11856{invocation_policy:registry_only_no_orr_execution,legacy_functor:G,predicate:B,role:C,side_effect_boundary:H,source:D,target_visibility:J,target_witness:I,variant:A},E),registry(A,B,C,D,G,H,J),target_presence_witness(B,J,I))).
rule(cw_orr_entry, registry(eh_run_computation,execution_handler:run_computation/2,entry,learner_execution_handler,'execution_handler:run_computation/2',bounded_meta_interpreter_event_log_teacher_recovery,exported_predicate)).
rule(cw_orr_entry, registry(eh_handle_perturbation,execution_handler:handle_perturbation/5,perturbation_handler,learner_execution_handler,'execution_handler:handle_perturbation/5',crisis_classification_recovery_state_and_teacher_path,module_internal_clause)).
rule(cw_orr_entry, registry(de_run_computation,dialectical_engine:run_computation/2,entry,dialectic_engine,'dialectical_engine:run_computation/2',bounded_embodied_prover_critique_retry_loop,exported_predicate)).
rule(cw_orr_entry, registry(de_handle_perturbation,dialectical_engine:handle_perturbation/3,perturbation_handler,dialectic_engine,'dialectical_engine:handle_perturbation/3',critique_accommodation_retry_loop,module_internal_clause)).
rule(cw_orr_entry, (target_presence_witness(A:B/C,D,_12386{arity:C,kind:loaded_orr_entry_target,module:A,name:B,properties:F,visibility:D}):-once(target_present(A,B,C,D)),findall(G,target_property(A,B,C,G),H),sort(H,F))).
rule(cw_orr_entry, (target_present(A,B,C,exported_predicate):-catch(current_predicate(A:B/C),_12630,fail),functor(E,B,C),catch(predicate_property(A:E,exported),_,fail))).
rule(cw_orr_entry, (target_present(A,B,C,module_internal_clause):-functor(D,B,C),catch(clause(A:D,_12820),_,fail))).
rule(cw_orr_entry, (target_property(A,B,C,defined):-functor(D,B,C),predicate_property(A:D,defined))).
rule(cw_orr_entry, (target_property(A,B,C,exported):-functor(D,B,C),predicate_property(A:D,exported))).
rule(cw_orr_entry, canonical_concept('execution_handler:run_computation/2',orr_entry)).
rule(cw_orr_entry, canonical_concept('execution_handler:handle_perturbation/5',orr_entry)).
rule(cw_orr_entry, canonical_concept('dialectical_engine:run_computation/2',orr_entry)).
rule(cw_orr_entry, canonical_concept('dialectical_engine:handle_perturbation/3',orr_entry)).
rule(cw_orr_entry, vocabulary_source(orr_entry,['execution_handler:run_computation/2','execution_handler:handle_perturbation/5','dialectical_engine:run_computation/2','dialectical_engine:handle_perturbation/3'])).

% cw_practice_vocabulary
family(cw_practice_vocabulary).
edge(cw_practice_vocabulary, sar_add_action_pairs,action_vocabulary/2,[count_on],[2],registry_projection).
rule(cw_practice_vocabulary, (practice_vocabulary_unified(A,B,additive_action):-practice_vocabulary_witness(A,B,additive_action,_14072))).
rule(cw_practice_vocabulary, (practice_vocabulary_unified(A,B,fraction_action):-practice_vocabulary_witness(A,B,fraction_action,_14160))).
rule(cw_practice_vocabulary, (practice_vocabulary_unified(A,B,mua_kind_terms):-practice_vocabulary_witness(A,B,mua_kind_terms,_14248))).
rule(cw_practice_vocabulary, (practice_vocabulary_unified(A,[B],mua_vocabulary_description):-practice_vocabulary_witness(A,[B],mua_vocabulary_description,_14352))).
rule(cw_practice_vocabulary, (practice_vocabulary_witness(A,B,C,D):-witness_dict:witness_dict(practice_vocabulary_crosswalk,closed_world_finite_loaded_practice_vocabulary_sources,_14436{derivation:G,key:A,legacy_functor:F,source:C,source_witness:H,vocabulary:B,vocabulary_shape:I},D),source_practice_vocabulary_witness(C,A,B,F,I,G,H))).
rule(cw_practice_vocabulary, (source_practice_vocabulary_witness(additive_action,A,B,'sar_add_action_pairs:action_vocabulary/2',term_list,direct_additive_action_vocabulary_row,_14654{action_kind:A,kind:direct_action_vocabulary_row,module:sar_add_action_pairs,predicate:action_vocabulary/2,term_count:D,terms:B}):-catch(sar_add_action_pairs:action_vocabulary(A,B),_,fail),length(B,D))).
rule(cw_practice_vocabulary, (source_practice_vocabulary_witness(fraction_action,A,B,'fraction_action_pairs:fraction_action_vocabulary/2',term_list,direct_fraction_action_vocabulary_row,_14842{action_kind:A,kind:direct_action_vocabulary_row,module:fraction_action_pairs,predicate:fraction_action_vocabulary/2,term_count:D,terms:B}):-catch(fraction_action_pairs:fraction_action_vocabulary(A,B),_,fail),length(B,D))).
rule(cw_practice_vocabulary, (source_practice_vocabulary_witness(mua_kind_terms,A,B,'mua_relations:kind_vocabulary_terms/2',sorted_term_union,mua_registry_and_curated_vocabulary_union,_15030{action_kind:A,kind:mua_kind_vocabulary_union,module:mua_relations,predicate:kind_vocabulary_terms/2,term_count:D,terms:B,union_rule:registry_terms_plus_pv_sufficient_terms}):-catch(once(mua_relations:kind_vocabulary_terms(A,B)),_,fail),B\==[],length(B,D))).
rule(cw_practice_vocabulary, (source_practice_vocabulary_witness(mua_vocabulary_description,A,[B],'mua_relations:vocabulary/2',singleton_description_list,vocabulary_description_projected_to_singleton_list,_15246{description:B,kind:mua_vocabulary_description,module:mua_relations,predicate:vocabulary/2,projection:description_as_singleton_list,vocabulary_id:A}):-catch(mua_relations:vocabulary(A,B),_,fail))).
rule(cw_practice_vocabulary, canonical_concept('sar_add_action_pairs:action_vocabulary/2',practice_vocabulary_unified)).
rule(cw_practice_vocabulary, canonical_concept('fraction_action_pairs:fraction_action_vocabulary/2',practice_vocabulary_unified)).
rule(cw_practice_vocabulary, canonical_concept('mua_relations:kind_vocabulary_terms/2',practice_vocabulary_unified)).
rule(cw_practice_vocabulary, canonical_concept('mua_relations:vocabulary/2',practice_vocabulary_unified)).
rule(cw_practice_vocabulary, vocabulary_source(practice_vocabulary_unified,['sar_add_action_pairs:action_vocabulary/2','fraction_action_pairs:fraction_action_vocabulary/2','mua_relations:kind_vocabulary_terms/2','mua_relations:vocabulary/2'])).

% cw_productive_deformation
family(cw_productive_deformation).
edge(cw_productive_deformation, action_automata_registry,action_automaton_pair/4,[addition,count_on],[3,4],registry_projection).
rule(cw_productive_deformation, (productive_deformation_unified(A,B,C,D,E):-productive_deformation_witness(A,B,C,D,E,_16268))).
rule(cw_productive_deformation, (productive_deformation_witness(A,B,C,D,registry,E):-catch(action_automata_registry:action_automaton_pair(A,B,C,D),_16410,fail),pair_witness(A,B,C,D,registry,action_automata_registry,action_automaton_pair/4,operation_tagged_registry_union,E))).
rule(cw_productive_deformation, (productive_deformation_witness(addition,A,B,C,addition,D):-catch(sar_add_action_pairs:productive_deformation(A,B,C),_16584,fail),pair_witness(addition,A,B,C,addition,sar_add_action_pairs,productive_deformation/3,fixed_operation_projection(addition),D))).
rule(cw_productive_deformation, (productive_deformation_witness(fraction,A,B,C,fraction,D):-catch(fraction_action_pairs:productive_fraction_deformation(A,B,C),_16750,fail),pair_witness(fraction,A,B,C,fraction,fraction_action_pairs,productive_fraction_deformation/3,fixed_operation_projection(fraction),D))).
rule(cw_productive_deformation, (pair_witness(A,B,C,D,E,F,G,H,I):-witness_dict:witness_dict(productive_deformation_crosswalk,closed_world_finite_verified_productive_deformation_pairs,_16938{deformation:C,deformation_witness:M,derivation:owner_predicate_pair_check,family:D,operation:A,productive:B,productive_witness:L,projection:H,source:E,source_witness:_{deformation:C,family:D,kind:productive_deformation_pair_row,module:F,operation:A,predicate:G,productive:B}},I),action_kind_witness(A,B,L),action_kind_witness(A,C,M))).
rule(cw_productive_deformation, (action_kind_witness(A,B,_17228{action_kind:B,cluster:D,kind:action_automaton_kind_metadata,module:action_automata_registry,operation:A,vocabulary:E}):-catch(action_automata_registry:action_automaton_cluster(A,B,D),_,fail),catch(action_automata_registry:action_automaton_vocabulary(A,B,E),_,fail),!)).
rule(cw_productive_deformation, action_kind_witness(A,B,_17462{action_kind:B,boundary:owner_pair_proved_without_registry_kind_metadata,kind:action_automaton_kind_metadata_absent,module:action_automata_registry,operation:A})).
rule(cw_productive_deformation, canonical_concept('action_automata_registry:action_automaton_pair/4',productive_deformation_unified)).
rule(cw_productive_deformation, canonical_concept('sar_add_action_pairs:productive_deformation/3',productive_deformation_unified)).
rule(cw_productive_deformation, canonical_concept('fraction_action_pairs:productive_fraction_deformation/3',productive_deformation_unified)).
rule(cw_productive_deformation, vocabulary_source(productive_deformation_unified,['action_automata_registry:action_automaton_pair/4','sar_add_action_pairs:productive_deformation/3','fraction_action_pairs:productive_fraction_deformation/3'])).

% cw_ratio_proportion_claim
family(cw_ratio_proportion_claim).
rule(cw_ratio_proportion_claim, rp(multiplicative_proportional_scaling, c_proportionality_requires_zero_intercept, "Proportional relationships scale by multiplication; extending a ratio is valid only when no additive constant is injected (the zero-intercept condition).", ['action_automata_registry:action_automaton_pair/4(ratio,scale_ratio_unit,additive_extension_of_ratio)', 'misconception_registry:incompatibility_with/2(additive_extension_of_ratio)'])).
rule(cw_ratio_proportion_claim, (claim_literature_atom(A, B):-rp(A, B, _, _))).
rule(cw_ratio_proportion_claim, (legacy_list(A, B):-rp(A, C, _, D), atomic_list_concat(['literature_vocabulary:canonical_commitment/2(', C, ')'], E), append([[E], D], B))).
rule(cw_ratio_proportion_claim, (vocabulary_source(A, B):-legacy_list(A, B))).
rule(cw_ratio_proportion_claim, (canonical_concept(A, B):-legacy_list(B, C), member(A, C))).
rule(cw_ratio_proportion_claim, (ratio_proportion_claim_unified(A, B, C):-ratio_proportion_claim_witness(A, B, C, _))).
rule(cw_ratio_proportion_claim, (ratio_proportion_claim_witness(A, commitment(B, C), literature_commitment, D):-witness_dict:witness_dict(ratio_proportion_claim_crosswalk, closed_world_finite_verified_ratio_proportion_claim_edges, _{canonical:A, derivation:literature_canonical_commitment_lookup, detail:commitment(B, C), literature_atom:B, projection:literature_commitment_gloss, source:literature_commitment, source_witness:_{atom:B, gloss:C, kind:literature_commitment_row, module:literature_vocabulary, predicate:canonical_commitment/2}}, D), rp(A, B, _, _), catch(literature_vocabulary:canonical_commitment(B, E), _, fail), (string(E)->C=E;format(string(C), "~w", [E])))).
rule(cw_ratio_proportion_claim, (ratio_proportion_claim_witness(A, edge(B), B, C):-witness_dict:witness_dict(ratio_proportion_claim_crosswalk, closed_world_finite_verified_ratio_proportion_claim_edges, _{canonical:A, derivation:owner_predicate_edge_check, detail:edge(B), legacy_functor:B, projection:verified_legacy_edge, source:B, source_witness:D}, C), rp(A, _, _, E), member(B, E), ratio_proportion_edge_source_witness(A, B, D))).
rule(cw_ratio_proportion_claim, (ratio_proportion_edge_source_witness(multiplicative_proportional_scaling, 'action_automata_registry:action_automaton_pair/4(ratio,scale_ratio_unit,additive_extension_of_ratio)', _{deformation_kind:additive_extension_of_ratio, deformation_vocabulary:B, family:additive_comparison_in_proportion, kind:action_automaton_pair_edge, module:action_automata_registry, operation:ratio, predicate:action_automaton_pair/4, productive_kind:scale_ratio_unit, productive_vocabulary:A}):-catch(action_automata_registry:action_automaton_pair(ratio, scale_ratio_unit, additive_extension_of_ratio, additive_comparison_in_proportion), _, fail), catch(action_automata_registry:action_automaton_vocabulary(ratio, scale_ratio_unit, A), _, fail), catch(action_automata_registry:action_automaton_vocabulary(ratio, additive_extension_of_ratio, B), _, fail))).
rule(cw_ratio_proportion_claim, (ratio_proportion_edge_source_witness(multiplicative_proportional_scaling, 'misconception_registry:incompatibility_with/2(additive_extension_of_ratio)', _{conflict:strategy(ratio, scale_ratio_unit), incompatibility_witness:A, kind:misconception_registry_incompatibility_edge, module:misconception_registry, move:additive_extension_of_ratio, predicate:incompatibility_with/2}):-catch(once(misconception_registry:incompatibility_with_witness(additive_extension_of_ratio, strategy(ratio, scale_ratio_unit), A)), _, fail))).

% cw_sequent_proof
family(cw_sequent_proof).
edge(cw_sequent_proof, sequent_engine,proves/1,[sequent([],identity,[])],[],call_once_bind_out).
rule(cw_sequent_proof, (sequent_proof_unified(A,sequent):-sequent_proof_witness(A,sequent,_18346))).
rule(cw_sequent_proof, (sequent_proof_unified(A,sequent_safe):-sequent_proof_witness(A,sequent_safe,_18418))).
rule(cw_sequent_proof, (sequent_proof_unified(A,sequent_impl):-sequent_proof_witness(A,sequent_impl,_18490))).
rule(cw_sequent_proof, (sequent_proof_unified(A,embodied):-sequent_proof_witness(A,embodied,_18562))).
rule(cw_sequent_proof, (sequent_proof_unified(A,deontic_bridge):-sequent_proof_witness(A,deontic_bridge,_18634))).
rule(cw_sequent_proof, (sequent_proof_witness(A,B,C):-witness_dict:witness_dict(sequent_proof_crosswalk,closed_world_finite_loaded_sequent_sources,_18704{derivation:F,legacy_functor:E,parameters:H,sequent:A,source:B,source_witness:G},C),sequent_proof_source(B,E),source_sequent_proof_witness(B,A,H,F,G))).
rule(cw_sequent_proof, sequent_proof_source(sequent,'sequent_engine:proves/1')).
rule(cw_sequent_proof, sequent_proof_source(sequent_safe,'sequent_engine:safe_proves/2')).
rule(cw_sequent_proof, sequent_proof_source(sequent_impl,'sequent_engine:proves_impl/2')).
rule(cw_sequent_proof, sequent_proof_source(embodied,'embodied_prover:proves/4')).
rule(cw_sequent_proof, sequent_proof_source(deontic_bridge,'deontic_scorekeeper:proves_via_sequent_core/1')).
rule(cw_sequent_proof, (source_sequent_proof_witness(sequent,A,_19138{mode:default_loaded_axiom_packs},sequent_engine_proves_call,C):-catch(once(sequent_engine:proves(A)),_,fail),sequent_engine_source_witness(A,C))).
rule(cw_sequent_proof, (source_sequent_proof_witness(sequent_safe,A,_19286{packs:current_enabled_axiom_packs,time_limit_seconds:2},bounded_safe_proves_call,C):-catch(once(sequent_engine:safe_proves(A,[time_limit(2)])),_,fail),sequent_engine_source_witness(A,E),C=_{bound:time_limit_seconds(2),engine_witness:E,kind:bounded_sequent_engine_proof})).
rule(cw_sequent_proof, (source_sequent_proof_witness(sequent_impl,A,_19520{history:[]},internal_driver_call,C):-catch(once(sequent_engine:proves_impl(A,[])),_,fail),sequent_engine_source_witness(A,E),C=_{engine_witness:E,history:[],kind:sequent_engine_internal_driver})).
rule(cw_sequent_proof, (source_sequent_proof_witness(embodied,A,_19734{initial_context:neutral,resources_in:1000},embodied_prover_witness_call,C):-catch(once(embodied_prover:proves_witness(A,1000,_,_,C)),_,fail))).
rule(cw_sequent_proof, (source_sequent_proof_witness(deontic_bridge,A,_19930{bridge:catch_guarded_sequent},deontic_scorekeeper_bridge_call,_{bridge:proves_via_sequent_core,engine_witness:D,kind:deontic_sequent_bridge}):-catch(once(deontic_scorekeeper:proves_via_sequent_core(A)),_,fail),sequent_engine_source_witness(A,D))).
rule(cw_sequent_proof, (sequent_engine_source_witness((A=>B),_20124{conclusions:B,kind:sequent_engine_identity,premises:A,rule:identity,shared_formula:D}):-member(D,A),member(D,B),!)).
rule(cw_sequent_proof, (sequent_engine_source_witness((A=>B),_20266{conclusions:B,incoherence_witness:D,kind:sequent_engine_explosion,premises:A,rule:explosion}):-catch(sequent_engine:incoherent_witness(A,D),_,fail),!)).
rule(cw_sequent_proof, sequent_engine_source_witness(A,_20428{kind:sequent_engine_semidet_proof,rule:loaded_axiom_or_structural_reduction,sequent:A})).
rule(cw_sequent_proof, canonical_concept('sequent_engine:proves/1',sequent_proof)).
rule(cw_sequent_proof, canonical_concept('sequent_engine:safe_proves/2',sequent_proof)).
rule(cw_sequent_proof, canonical_concept('sequent_engine:proves_impl/2',sequent_proof)).
rule(cw_sequent_proof, canonical_concept('embodied_prover:proves/4',sequent_proof)).
rule(cw_sequent_proof, canonical_concept('deontic_scorekeeper:proves_via_sequent_core/1',sequent_proof)).
rule(cw_sequent_proof, vocabulary_source(sequent_proof,['sequent_engine:proves/1','sequent_engine:safe_proves/2','sequent_engine:proves_impl/2','embodied_prover:proves/4','deontic_scorekeeper:proves_via_sequent_core/1'])).

% cw_strategy_action_kind
family(cw_strategy_action_kind).
rule(cw_strategy_action_kind, sak(unit_fraction_iteration, fraction_unit_referent_operations, whole_number_grab, whole_number_grab)).
rule(cw_strategy_action_kind, sak(improper_fraction_iteration, fraction_improper_number, improper_fraction_chain_loss, improper_fraction_reset)).
rule(cw_strategy_action_kind, sak(cross_multiplication_rule_from_pattern, fraction_area_model_multiplication, cross_multiplication_rule_without_ground, rule_without_grounding)).
rule(cw_strategy_action_kind, sak(splitting, fraction_reversibility_splitting, iterate_given_overshoot, no_splitting_iterate_overshoot)).
rule(cw_strategy_action_kind, (legacy_list(A, [B, C]):-sak(A, _, _, _), atomic_list_concat(['action_automata_registry:action_automaton_cluster/3(fraction,', A, ')'], B), atomic_list_concat(['fraction_action_pairs:productive_fraction_deformation/3(', A, ')'], C))).
rule(cw_strategy_action_kind, (vocabulary_source(A, B):-legacy_list(A, B))).
rule(cw_strategy_action_kind, (canonical_concept(A, B):-legacy_list(B, C), member(A, C))).
rule(cw_strategy_action_kind, (strategy_action_kind_unified(A, B, C):-strategy_action_kind_witness(A, B, C, _))).
rule(cw_strategy_action_kind, (strategy_action_kind_witness(A, edge(B), B, C):-witness_dict:witness_dict(strategy_action_kind_crosswalk, closed_world_finite_verified_strategy_action_kind_edges, _{canonical:A, derivation:owner_predicate_edge_check, detail:edge(B), legacy_functor:B, projection:verified_legacy_edge, source:B, source_witness:D}, C), legacy_list(A, E), member(B, E), strategy_action_kind_edge_witness(A, B, D))).
rule(cw_strategy_action_kind, (strategy_action_kind_edge_witness(A, B, _{action_kind:A, cluster:D, kind:action_automaton_cluster_edge, module:action_automata_registry, operation:fraction, predicate:action_automaton_cluster/3, vocabulary:C}):-sub_atom(B, _, _, _, action_automaton_cluster), sak(A, D, _, _), catch(action_automata_registry:action_automaton_cluster(fraction, A, D), _, fail), catch(action_automata_registry:action_automaton_vocabulary(fraction, A, C), _, fail))).
rule(cw_strategy_action_kind, (strategy_action_kind_edge_witness(A, B, _{deformation:D, family:C, kind:productive_fraction_deformation_edge, module:fraction_action_pairs, predicate:productive_fraction_deformation/3, productive:A}):-sub_atom(B, _, _, _, productive_fraction_deformation), sak(A, _, D, C), catch(fraction_action_pairs:productive_fraction_deformation(A, D, C), _, fail))).

% cw_stress_map
family(cw_stress_map).
edge(cw_stress_map, critique,get_stress_map/1,[],[1],call_aggregate).
rule(cw_stress_map, (stress_map_unified(A,B,critique):-stress_map_witness(A,B,critique,_21404))).
rule(cw_stress_map, (stress_map_unified(A,B,reflective_monitor):-stress_map_witness(A,B,reflective_monitor,_21492))).
rule(cw_stress_map, (stress_map_witness(A,B,C,D):-witness_dict:witness_dict(stress_map_entry,closed_world_finite_loaded_stress_map_snapshot,_21576{count:B,derivation:map_snapshot_membership,legacy_functor:F,signature:A,source:C,source_witness:G},D),stress_map_source(C,F),source_stress_map_witness(C,A,B,G))).
rule(cw_stress_map, stress_map_source(critique,'critique:get_stress_map/1')).
rule(cw_stress_map, stress_map_source(reflective_monitor,'reflective_monitor:get_stress_map/1')).
rule(cw_stress_map, (source_stress_map_witness(critique,A,B,_21864{entry:stress(A,B),kind:stress_map_snapshot_membership,layer:dialectic_critique,map_reader:'critique:get_stress_map/1',map_size:D,map_snapshot:E}):-catch(once(critique:get_stress_map(E)),_,fail),member(stress(A,B),E),length(E,D))).
rule(cw_stress_map, (source_stress_map_witness(reflective_monitor,A,B,_22078{entry:stress(A,B),kind:stress_map_snapshot_membership,layer:learner_reflective_monitor,map_reader:'reflective_monitor:get_stress_map/1',map_size:D,map_snapshot:E}):-catch(once(reflective_monitor:get_stress_map(E)),_,fail),member(stress(A,B),E),length(E,D))).
rule(cw_stress_map, canonical_concept('critique:get_stress_map/1',stress_map_unified)).
rule(cw_stress_map, canonical_concept('reflective_monitor:get_stress_map/1',stress_map_unified)).
rule(cw_stress_map, canonical_concept('critique:commitment_stress/2',stress_map_unified)).
rule(cw_stress_map, canonical_concept('critique:reflect/2',stress_map_unified)).
rule(cw_stress_map, canonical_concept('critique:reset_stress_map/0',stress_map_unified)).
rule(cw_stress_map, canonical_concept('reflective_monitor:reflect/2',stress_map_unified)).
rule(cw_stress_map, canonical_concept('reflective_monitor:reset_stress_map/0',stress_map_unified)).
rule(cw_stress_map, canonical_concept('reflective_monitor:parse_trace/3',stress_map_unified)).
rule(cw_stress_map, vocabulary_source(stress_map_unified,['critique:get_stress_map/1','reflective_monitor:get_stress_map/1','critique:commitment_stress/2','critique:reflect/2','critique:reset_stress_map/0','reflective_monitor:reflect/2','reflective_monitor:reset_stress_map/0','reflective_monitor:parse_trace/3'])).

% cw_unit_coordination
family(cw_unit_coordination).
edge(cw_unit_coordination, divaded_fractional_units,coordinate_units/4,[1,2],[3,4],call_bind_out).
rule(cw_unit_coordination, (unit_coordination_unified(lit(A,B),commitment(C,D,E,F),literature_commitment):-unit_coordination_witness(lit(A,B),commitment(C,D,E,F),literature_commitment,_23332))).
rule(cw_unit_coordination, (unit_coordination_unified(compose(A,B),composite(C),strategy_compose):-unit_coordination_witness(compose(A,B),composite(C),strategy_compose,_23488))).
rule(cw_unit_coordination, (unit_coordination_witness(A,B,C,D):-witness_dict:witness_dict(unit_coordination_crosswalk,closed_world_finite_loaded_unit_coordination_sources,_23584{derivation:G,detail:B,key:A,legacy_functor:F,source:C,source_witness:H},D),unit_coordination_source(C,F),source_unit_coordination_witness(C,A,B,G,H))).
rule(cw_unit_coordination, unit_coordination_source(strategy_compose,'divaded_fractional_units:coordinate_units/4')).
rule(cw_unit_coordination, unit_coordination_source(literature_commitment,'literature_incompatibility_facts:lit_derived/9(Topic=unit_coordination)')).
rule(cw_unit_coordination, (source_unit_coordination_witness(literature_commitment,lit(A,B),commitment(C,D,E,F),literature_topic_lookup,_23896{confidence:I,domain:B,id:A,incompatible_with:E,kind:unit_coordination_literature_commitment,level:H,student_rule:C,topic:unit_coordination,valence:F,valid_domain:D}):-catch(literature_incompatibility_facts:lit_derived(A,B,unit_coordination,C,D,E,F,H,I),_,fail))).
rule(cw_unit_coordination, (source_unit_coordination_witness(strategy_compose,compose(A,B),composite(C),deterministic_strategy_demo,_24162{composite_int:C,composite_recollection:H,demonstration:fixed_ground_strategy_demo,kind:unit_coordination_strategy_composition,trace:E,unit_count:B,unit_count_recollection:G,unit_size:A,unit_size_recollection:F}):-A=2,B=3,int_to_rec(A,F),int_to_rec(B,G),catch(once(divaded_fractional_units:coordinate_units(F,G,H,E)),_,fail),divaded_fractional_units:rec_to_int(H,C))).
rule(cw_unit_coordination, (int_to_rec(A,recollection(B)):-integer(A),A>=0,length(B,A),maplist(=(tally),B))).
rule(cw_unit_coordination, canonical_concept('divaded_fractional_units:coordinate_units/4',unit_coordination)).
rule(cw_unit_coordination, canonical_concept('literature_incompatibility_facts:lit_derived/9(Topic=unit_coordination)',unit_coordination)).
rule(cw_unit_coordination, vocabulary_source(unit_coordination,['divaded_fractional_units:coordinate_units/4','literature_incompatibility_facts:lit_derived/9(Topic=unit_coordination)'])).

% cw_viability
family(cw_viability).
edge(cw_viability, embodied_prover,check_viability/2,[5,1],[],call_guarded_numeric).
rule(cw_viability, (viability_unified(A,B,embodied_prover):-viability_witness(A,B,embodied_prover,_25258))).
rule(cw_viability, (viability_unified(A,B,meta_interpreter):-viability_witness(A,B,meta_interpreter,_25346))).
rule(cw_viability, (viability_witness(A,B,C,D):-witness_dict:witness_dict(inference_budget_viability,closed_world_finite_resource_check,_25430{caught_perturbation_boundary:insufficient_budget_throws_resource_exhaustion,comparison:G,cost:B,legacy_functor:F,relation:resources_cover_cost,resources:A,source:C},D),viability_source(C,F),must_be(number,A),must_be(number,B),A>=B,source_check_viability(C,A,B),G=..[>=,A,B])).
rule(cw_viability, viability_source(embodied_prover,'embodied_prover:check_viability/2')).
rule(cw_viability, viability_source(meta_interpreter,'meta_interpreter:check_viability/2')).
rule(cw_viability, (source_check_viability(embodied_prover,A,B):-catch(once(embodied_prover:check_viability(A,B)),_25808,fail))).
rule(cw_viability, (source_check_viability(meta_interpreter,A,B):-catch(once(meta_interpreter:check_viability(A,B)),_25910,fail))).
rule(cw_viability, canonical_concept('embodied_prover:check_viability/2',viability)).
rule(cw_viability, canonical_concept('meta_interpreter:check_viability/2',viability)).
rule(cw_viability, vocabulary_source(viability,['embodied_prover:check_viability/2','meta_interpreter:check_viability/2'])).

% cw_whole_number_addsub_claim
family(cw_whole_number_addsub_claim).
edge(cw_whole_number_addsub_claim, standard_k_ca_1_3,find_complement_to_ten_witness/3,[recollection([tally,tally,tally,tally,tally,tally])],[2,3],call_once_bind_out).
edge(cw_whole_number_addsub_claim, standard_1_ca_1,add_making_ten_witness/4,[recollection([tally,tally,tally,tally,tally,tally,tally,tally]),recollection([tally,tally,tally,tally,tally])],[3,4],call_once_bind_out).
edge(cw_whole_number_addsub_claim, standard_1_ca_3,add_by_place_value_witness/4,[recollection([tally,tally,tally,tally,tally,tally,tally,tally,tally,tally]),recollection([tally])],[3,4],call_once_bind_out).
edge(cw_whole_number_addsub_claim, standard_2_ca_2,add_three_digit_witness/4,[recollection([tally,tally,tally,tally,tally,tally,tally,tally,tally,tally]),recollection([tally])],[3,4],call_once_bind_out).
rule(cw_whole_number_addsub_claim, wn(addition_closure_totality, c_addition_total_operation, "Addition is defined for every pair of numbers and generates totals beyond any memorized set.", ['grounded_arithmetic:add_grounded/3', 'grounding_metaphors:grounds_inference/3'])).
rule(cw_whole_number_addsub_claim, wn(subtraction_fixed_removal, c_subtraction_removes_fixed_quantity, "Subtraction removes a fixed quantity from a starting amount (take-away).", ['action_automata_registry:action_automaton_cluster/3(subtraction,take_away_base_ones)', 'grounded_arithmetic:subtract_grounded/3'])).
rule(cw_whole_number_addsub_claim, wn(subtraction_directed_difference, c_subtraction_order_difference_relation, "Subtraction expresses a directed difference (comparison) and is order-sensitive: the larger cannot be removed from the smaller in the collection metaphor.", ['action_automata_registry:action_automaton_cluster/3(subtraction,compare_by_matching_difference)', 'grounding_metaphors:metaphor_breaks_at/3'])).
rule(cw_whole_number_addsub_claim, wn(self_subtraction_identity_zero, c_self_subtraction_yields_zero, "Any quantity minus itself is zero.", ['grounded_arithmetic:subtract_grounded/3'])).
rule(cw_whole_number_addsub_claim, (claim_literature_atom(A, B):-wn(A, B, _, _))).
rule(cw_whole_number_addsub_claim, (legacy_list(A, B):-wn(A, C, _, D), atomic_list_concat(['literature_vocabulary:canonical_commitment/2(', C, ')'], E), append([[E], D], B))).
rule(cw_whole_number_addsub_claim, (vocabulary_source(A, B):-legacy_list(A, B))).
rule(cw_whole_number_addsub_claim, (canonical_concept(A, B):-legacy_list(B, C), member(A, C))).
rule(cw_whole_number_addsub_claim, (whole_number_addsub_claim_unified(A, B, C):-whole_number_addsub_claim_witness(A, B, C, _))).
rule(cw_whole_number_addsub_claim, (whole_number_addsub_claim_witness(A, commitment(B, C), literature_commitment, D):-witness_dict:witness_dict(whole_number_addsub_claim_crosswalk, closed_world_finite_verified_whole_number_addsub_claim_edges, _{canonical:A, derivation:literature_canonical_commitment_lookup, detail:commitment(B, C), literature_atom:B, projection:literature_commitment_gloss, source:literature_commitment, source_witness:_{atom:B, gloss:C, kind:literature_commitment_row, module:literature_vocabulary, predicate:canonical_commitment/2}}, D), wn(A, B, _, _), catch(literature_vocabulary:canonical_commitment(B, E), _, fail), (string(E)->C=E;format(string(C), "~w", [E])))).
rule(cw_whole_number_addsub_claim, (whole_number_addsub_claim_witness(A, edge(B), B, C):-witness_dict:witness_dict(whole_number_addsub_claim_crosswalk, closed_world_finite_verified_whole_number_addsub_claim_edges, _{canonical:A, derivation:owner_predicate_edge_check, detail:edge(B), legacy_functor:B, projection:verified_legacy_edge, source:B, source_witness:D}, C), wn(A, _, _, E), member(B, E), whole_number_addsub_edge_source_witness(A, B, D))).
rule(cw_whole_number_addsub_claim, (whole_number_addsub_edge_source_witness(addition_closure_totality, 'grounded_arithmetic:add_grounded/3', _{evidence_policy:finite_sample_of_total_predicate, kind:grounded_addition_edge, module:grounded_arithmetic, predicate:add_grounded/3, samples:[A, B]}):-grounded_add_sample(2, 3, 5, A), grounded_add_sample(5, 2, 7, B))).
rule(cw_whole_number_addsub_claim, (whole_number_addsub_edge_source_witness(addition_closure_totality, 'grounding_metaphors:grounds_inference/3', _{grounding_witnesses:[A, B], kind:grounding_metaphor_inference_edge, metaphor:arithmetic_is_object_collection, module:grounding_metaphors, predicate:grounds_inference/3, target_inferences:[commutativity_of_addition, associativity_of_addition]}):-catch(grounding_metaphors:grounds_inference_witness(arithmetic_is_object_collection, commutativity_of_addition, _, A), _, fail), catch(grounding_metaphors:grounds_inference_witness(arithmetic_is_object_collection, associativity_of_addition, _, B), _, fail))).
rule(cw_whole_number_addsub_claim, (whole_number_addsub_edge_source_witness(subtraction_fixed_removal, 'action_automata_registry:action_automaton_cluster/3(subtraction,take_away_base_ones)', _{action_kind:take_away_base_ones, cluster:B, kind:action_automaton_cluster_edge, module:action_automata_registry, operation:subtraction, predicate:action_automaton_cluster/3, vocabulary:A}):-catch(action_automata_registry:action_automaton_cluster(subtraction, take_away_base_ones, B), _, fail), catch(action_automata_registry:action_automaton_vocabulary(subtraction, take_away_base_ones, A), _, fail))).
rule(cw_whole_number_addsub_claim, (whole_number_addsub_edge_source_witness(subtraction_fixed_removal, 'grounded_arithmetic:subtract_grounded/3', _{evidence_policy:finite_sample_of_partial_predicate, interpretation:fixed_removal, kind:grounded_subtraction_edge, module:grounded_arithmetic, predicate:subtract_grounded/3, samples:[A]}):-grounded_subtract_sample(5, 2, 3, A))).
rule(cw_whole_number_addsub_claim, (whole_number_addsub_edge_source_witness(subtraction_directed_difference, 'action_automata_registry:action_automaton_cluster/3(subtraction,compare_by_matching_difference)', _{action_kind:compare_by_matching_difference, cluster:B, kind:action_automaton_cluster_edge, module:action_automata_registry, operation:subtraction, predicate:action_automaton_cluster/3, vocabulary:A}):-catch(action_automata_registry:action_automaton_cluster(subtraction, compare_by_matching_difference, B), _, fail), catch(action_automata_registry:action_automaton_vocabulary(subtraction, compare_by_matching_difference, A), _, fail))).
rule(cw_whole_number_addsub_claim, (whole_number_addsub_edge_source_witness(subtraction_directed_difference, 'grounding_metaphors:metaphor_breaks_at/3', _{break_witness:B, kind:grounding_metaphor_break_edge, metaphor:arithmetic_is_object_collection, module:grounding_metaphors, predicate:metaphor_breaks_at/3, reason:A, target_inference:subtraction_of_larger_from_smaller}):-catch(grounding_metaphors:metaphor_break_witness(arithmetic_is_object_collection, subtraction_of_larger_from_smaller, A, B), _, fail))).
rule(cw_whole_number_addsub_claim, (whole_number_addsub_edge_source_witness(self_subtraction_identity_zero, 'grounded_arithmetic:subtract_grounded/3', _{evidence_policy:finite_samples_of_identity_case, interpretation:self_subtraction_identity_zero, kind:grounded_subtraction_edge, module:grounded_arithmetic, predicate:subtract_grounded/3, samples:[A, B]}):-grounded_subtract_sample(3, 3, 0, A), grounded_subtract_sample(4, 4, 0, B))).
rule(cw_whole_number_addsub_claim, (grounded_add_sample(A, B, C, _{left:E, left_integer:A, right:F, right_integer:B, sum:D, sum_integer:C}):-catch(grounded_arithmetic:integer_to_recollection(A, E), _, fail), catch(grounded_arithmetic:integer_to_recollection(B, F), _, fail), catch(grounded_arithmetic:add_grounded(E, F, D), _, fail), catch(grounded_arithmetic:recollection_to_integer(D, C), _, fail))).
rule(cw_whole_number_addsub_claim, (grounded_subtract_sample(A, B, C, _{difference:F, difference_integer:C, minuend:D, minuend_integer:A, subtrahend:E, subtrahend_integer:B}):-catch(grounded_arithmetic:integer_to_recollection(A, D), _, fail), catch(grounded_arithmetic:integer_to_recollection(B, E), _, fail), catch(grounded_arithmetic:subtract_grounded(D, E, F), _, fail), catch(grounded_arithmetic:recollection_to_integer(F, C), _, fail))).
