:- module(dispatch_spec,
          [ dispatch_spec/4,
            dispatch_message/3
          ]).

% dispatch_spec(Op, Inputs, Call, Result).
% Inputs are Key-Converter pairs. Call arguments name bound keys, mark ignored
% outputs as drop, and name retained outputs with out(Name).

dispatch_spec(axiom_pack_witness,
    [pack-atom, source-atom],
    call(cw_axiom_pack:axiom_pack_witness, [pack, source, out(witness)]),
    witness(no_axiom_pack_witness)).
dispatch_spec(viability_witness,
    [resources-number, cost-number, source-term],
    call(cw_viability:viability_witness, [resources, cost, source, out(witness)]),
    witness(no_viability_witness)).
dispatch_spec(modal_context_witness,
    [term-term, context-term, source-term],
    call(cw_modal_context:modal_context_witness, [term, context, source, out(witness)]),
    witness(no_modal_context_witness)).
dispatch_spec(grounded_arith_witness,
    [operation-atom, inputs-term, output-term, source-atom],
    call(cw_grounded_arith:grounded_arith_witness,
         [operation, inputs, output, source, out(witness)]),
    witness(no_grounded_arith_witness)).
dispatch_spec(material_inference_witness,
    [inference_id-term, premises-term, conclusion-term, source-term],
    call(cw_material_inference:material_inference_witness,
         [inference_id, premises, conclusion, source, out(witness)]),
    witness(no_material_inference_witness)).
dispatch_spec(normative_crisis_witness,
    [context-term, goal-term, source-term],
    call(cw_normative_crisis:normative_crisis_witness,
         [context, goal, source, out(witness)]),
    witness(no_normative_crisis_witness)).
dispatch_spec(metaphor_break_witness,
    [metaphor-term, inference-term, detail-term, source-term],
    call(cw_metaphor_break:metaphor_break_witness,
         [metaphor, inference, detail, source, out(witness)]),
    witness(no_metaphor_break_witness)).
dispatch_spec(grounding_metaphor_witness,
    [metaphor-term, anchor-term, source-term],
    call(cw_grounding_metaphor:grounding_metaphor_witness,
         [metaphor, anchor, source, out(witness)]),
    witness(no_grounding_metaphor_witness)).
dispatch_spec(unit_coordination_witness,
    [key-term, detail-term, source-term],
    call(cw_unit_coordination:unit_coordination_witness,
         [key, detail, source, out(witness)]),
    witness(no_unit_coordination_witness)).
dispatch_spec(godel_primes_witness,
    [query-term, source-term],
    call(cw_godel_primes:godel_primes_witness,
         [query, drop, source, out(witness)]),
    witness(no_godel_primes_witness)).
dispatch_spec(fsm_engine_witness,
    [descriptor-term, source-term],
    call(cw_fsm_engine:fsm_engine_witness,
         [descriptor, source, out(witness)]),
    witness(no_fsm_engine_witness)).
dispatch_spec(action_cluster_witness,
    [operation-term, kind-term, cluster-term, source-term],
    call(cw_action_cluster:action_cluster_witness,
         [operation, kind, cluster, source, out(witness)]),
    witness(no_action_cluster_witness)).
dispatch_spec(practice_vocabulary_witness,
    [key-term, source-term],
    call(cw_practice_vocabulary:practice_vocabulary_witness,
         [key, drop, source, out(witness)]),
    witness(no_practice_vocabulary_witness)).
dispatch_spec(accommodation_witness,
    [target-term, source-term],
    call(cw_accommodation:accommodation_witness,
         [target, source, out(witness)]),
    witness(no_accommodation_witness)).
dispatch_spec(domain_context_witness,
    [domain-term, context-term, source-term],
    call(cw_domain_context:domain_context_witness,
         [domain, context, source, out(witness)]),
    witness(no_domain_context_witness)).
dispatch_spec(orr_entry_witness,
    [variant-term, source-term],
    call(cw_orr_entry:orr_entry_witness,
         [variant, drop, drop, source, out(witness)]),
    witness(no_orr_entry_witness)).
dispatch_spec(executable_practice_witness,
    [variant-term, source-term],
    call(cw_executable_practice:executable_practice_witness,
         [variant, drop, drop, source, out(witness)]),
    witness(no_executable_practice_witness)).
dispatch_spec(misconception_hook_witness,
    [operation-term, outcome-term, family-term, source-term],
    call(cw_misconception_hook:misconception_hook_witness,
         [operation, outcome, family, drop, source, out(witness)]),
    witness(no_misconception_hook_witness)).

dispatch_spec(algebra_claim_witness,
    [canonical-atom, source-atom],
    call(cw_driver:family_witness,
         [const(cw_algebra_claim), const(algebra_claim_witness), canonical, drop, source, out(witness)]),
    witness(no_algebra_claim_witness)).
dispatch_spec(integer_signed_claim_witness,
    [canonical-atom, source-atom],
    call(cw_driver:family_witness,
         [const(cw_integer_signed_claim), const(integer_signed_claim_witness), canonical, drop, source, out(witness)]),
    witness(no_integer_signed_claim_witness)).
dispatch_spec(arithmetic_property_witness,
    [canonical-atom, source-atom],
    call(cw_driver:family_witness,
         [const(cw_arithmetic_property_claim), const(arithmetic_property_witness), canonical, drop, source, out(witness)]),
    witness(no_arithmetic_property_witness)).
dispatch_spec(calculus_claim_witness,
    [canonical-atom, source-atom],
    call(cw_driver:family_witness,
         [const(cw_calculus_claim), const(calculus_claim_witness), canonical, drop, source, out(witness)]),
    witness(no_calculus_claim_witness)).
dispatch_spec(counting_claim_witness,
    [canonical-atom, source-atom],
    call(cw_counting_claim:counting_claim_witness,
         [canonical, drop, source, out(witness)]),
    witness(no_counting_claim_witness)).
dispatch_spec(whole_number_addsub_claim_witness,
    [canonical-atom, source-atom],
    call(cw_driver:family_witness,
         [const(cw_whole_number_addsub_claim), const(whole_number_addsub_claim_witness), canonical, drop, source, out(witness)]),
    witness(no_whole_number_addsub_claim_witness)).
dispatch_spec(ratio_proportion_claim_witness,
    [canonical-atom, source-atom],
    call(cw_driver:family_witness,
         [const(cw_ratio_proportion_claim), const(ratio_proportion_claim_witness), canonical, drop, source, out(witness)]),
    witness(no_ratio_proportion_claim_witness)).
dispatch_spec(magnitude_equivalence_claim_witness,
    [canonical-atom, source-atom],
    call(cw_driver:family_witness,
         [const(cw_magnitude_equivalence_claim), const(magnitude_equivalence_claim_witness), canonical, drop, source, out(witness)]),
    witness(no_magnitude_equivalence_claim_witness)).
dispatch_spec(multiplication_division_claim_witness,
    [canonical-atom, source-atom],
    call(cw_driver:family_witness,
         [const(cw_multiplication_division_claim), const(multiplication_division_claim_witness), canonical, drop, source, out(witness)]),
    witness(no_multiplication_division_claim_witness)).
dispatch_spec(decimal_claim_witness,
    [canonical-atom, source-atom],
    call(cw_driver:family_witness,
         [const(cw_decimal_claim), const(decimal_claim_witness), canonical, drop, source, out(witness)]),
    witness(no_decimal_claim_witness)).
dispatch_spec(place_value_number_claim_witness,
    [canonical-atom, source-atom],
    call(cw_place_value_number_claim:place_value_number_claim_witness,
         [canonical, drop, source, out(witness)]),
    witness(no_place_value_number_claim_witness)).
dispatch_spec(whole_number_claim_witness,
    [canonical-atom, source-atom],
    call(cw_whole_number_claim:whole_number_claim_witness,
         [canonical, drop, source, out(witness)]),
    witness(no_whole_number_claim_witness)).
dispatch_spec(fraction_extra_claim_witness,
    [canonical-atom, source-atom],
    call(cw_driver:family_witness,
         [const(cw_fraction_extra_claim), const(fraction_extra_claim_witness), canonical, drop, source, out(witness)]),
    witness(no_fraction_extra_claim_witness)).
dispatch_spec(fraction_claim_witness,
    [canonical-atom, source-atom],
    call(cw_fraction_claim:fraction_claim_witness,
         [canonical, drop, source, out(witness)]),
    witness(no_fraction_claim_witness)).
dispatch_spec(productive_deformation_witness,
    [operation-atom, productive-atom, deformation-atom, family-atom, source-atom],
    call(cw_productive_deformation:productive_deformation_witness,
         [operation, productive, deformation, family, source, out(witness)]),
    witness(no_productive_deformation_witness)).
dispatch_spec(mua_coherence_witness,
    [subject-term, input-dict, source-term],
    call(cw_mua_coherence:mua_coherence_witness,
         [subject, input, drop, source, out(witness)]),
    witness(no_mua_coherence_witness)).

dispatch_spec(geometry_entailment_witness,
    [entailer-term, entailed-term],
    call(sequent_engine:entails_via_incompatibility_witness,
         [entailer, entailed, out(witness)],
         [gate(axiom_pack(geometry))]),
    witness(no_geometry_entailment_witness,
            malformed_geometry_entailment_request)).
dispatch_spec(geometry_material_profile_witness,
    [concept-term],
    call(user:material_inference_profile_witness,
         [concept, out(profile), out(witness)]),
    witness_wrap([profile-profile], no_geometry_material_profile_witness,
                 missing_concept)).
dispatch_spec(geometry_quadrilateral_entailment_witness,
    [entailer-term, entailed-term],
    call(user:quad_entails_witness, [entailer, entailed, out(witness)]),
    witness(no_geometry_quadrilateral_entailment_witness,
            malformed_geometry_quadrilateral_entailment_request)).
dispatch_spec(geometry_strength_lift_coverage_witness,
    [],
    call(user:strength_lift_coverage_witness,
         [out(coverage), out(witness)]),
    witness_wrap([coverage-coverage],
                 no_geometry_strength_lift_coverage_witness)).
dispatch_spec(geometry_van_hiele_material_witness,
    [claim_id-term],
    call(user:van_hiele_material_inference_by_id_witness,
         [claim_id, out(witness)]),
    witness(no_geometry_van_hiele_material_witness, missing_claim_id)).
dispatch_spec(geometry_van_hiele_marker_witness,
    [concept-term, level-number],
    call(user:van_hiele_marker_witness, [concept, level, out(witness)]),
    witness(no_geometry_van_hiele_marker_witness,
            malformed_geometry_van_hiele_marker_request)).
dispatch_spec(geometry_cross_link_witness,
    [source-term, relation-term, target-term,
     status-default(term, entitled)],
    call(user:cross_link_witness,
         [source, relation, target, status, out(witness)]),
    witness(no_geometry_cross_link_witness,
            malformed_geometry_cross_link_request)).
dispatch_spec(geometry_developmental_arc_witness,
    [arc_id-term],
    call(user:developmental_arc_witness, [arc_id, out(witness)]),
    witness(no_geometry_developmental_arc_witness, missing_arc_id)).
dispatch_spec(geometry_attribute_material_witness,
    [claim_id-term],
    call(user:attribute_material_claim_witness, [claim_id, out(witness)]),
    witness(no_geometry_attribute_material_witness, missing_claim_id)).
dispatch_spec(geometry_similarity_material_witness,
    [claim_id-term],
    call(user:similarity_material_claim_witness, [claim_id, out(witness)]),
    witness(no_geometry_similarity_material_witness, missing_claim_id)).
dispatch_spec(geometry_pythagorean_material_witness,
    [claim_id-term],
    call(user:pythagorean_material_claim_witness, [claim_id, out(witness)]),
    witness(no_geometry_pythagorean_material_witness, missing_claim_id)).
dispatch_spec(geometry_van_hiele_level_material_witness,
    [claim_id-term],
    call(user:van_hiele_level_material_claim_witness,
         [claim_id, out(witness)]),
    witness(no_geometry_van_hiele_level_material_witness, missing_claim_id)).
dispatch_spec(geometry_measurement_misconception_witness,
    [id_value-term],
    call(user:measurement_misconception_witness, [id_value, out(witness)]),
    witness(no_geometry_measurement_misconception_witness, missing_id_value)).
dispatch_spec(geometry_n103_bootstrap_witness,
    [bootstrap_id-term],
    call(user:n103_bootstrap_witness, [bootstrap_id, out(witness)]),
    witness(no_geometry_n103_bootstrap_witness, missing_bootstrap_id)).
dispatch_spec(geometry_van_de_walle_bootstrap_witness,
    [bootstrap_id-term],
    call(user:van_de_walle_bootstrap_witness, [bootstrap_id, out(witness)]),
    witness(no_geometry_van_de_walle_bootstrap_witness, missing_bootstrap_id)).
dispatch_spec(geometry_shape_recognition_material_witness,
    [claim_id-term],
    call(user:shape_recognition_material_claim_witness,
         [claim_id, out(witness)]),
    witness(no_geometry_shape_recognition_material_witness, missing_claim_id)).
dispatch_spec(geometry_coordinate_material_witness,
    [claim_id-term],
    call(user:coordinate_geometry_material_claim_witness,
         [claim_id, out(witness)]),
    witness(no_geometry_coordinate_material_witness, missing_claim_id)).
dispatch_spec(geometry_angle_material_witness,
    [claim_id-term],
    call(user:angle_material_claim_witness, [claim_id, out(witness)]),
    witness(no_geometry_angle_material_witness, missing_claim_id)).
dispatch_spec(geometry_area_perimeter_material_witness,
    [claim_id-term],
    call(user:area_perimeter_material_claim_witness,
         [claim_id, out(witness)]),
    witness(no_geometry_area_perimeter_material_witness, missing_claim_id)).
dispatch_spec(geometry_volume_surface_area_material_witness,
    [claim_id-term],
    call(user:volume_surface_area_material_claim_witness,
         [claim_id, out(witness)]),
    witness(no_geometry_volume_surface_area_material_witness, missing_claim_id)).
dispatch_spec(geometry_transformation_material_witness,
    [claim_id-term],
    call(user:transformation_material_claim_witness, [claim_id, out(witness)]),
    witness(no_geometry_transformation_material_witness, missing_claim_id)).
dispatch_spec(geometry_classification_material_witness,
    [claim_id-term],
    call(user:classification_material_claim_witness, [claim_id, out(witness)]),
    witness(no_geometry_classification_material_witness, missing_claim_id)).
dispatch_spec(geometry_pck_classification_witness,
    [concept-term],
    call(user:pck_synthesis_witness, [concept, out(witness)]),
    witness(no_geometry_pck_classification_witness, missing_concept)).
dispatch_spec(geometry_measuring_stick_metaphor_witness,
    [concept-term, metaphor-term],
    call(user:measuring_stick_metaphor_witness,
         [concept, metaphor, out(witness)]),
    witness(no_geometry_measuring_stick_metaphor_witness,
            malformed_measuring_stick_metaphor_request)).
dispatch_spec(geometry_lakoff_nunez_metaphor_witness,
    [concept-term, metaphor-term],
    call(user:lakoff_nunez_metaphor_witness,
         [concept, metaphor, out(witness)]),
    witness(no_geometry_lakoff_nunez_metaphor_witness,
            malformed_lakoff_nunez_metaphor_request)).
dispatch_spec(geometry_synthesizer_anchor_material_witness,
    [claim_id-term],
    call(user:synthesizer_anchor_material_witness,
         [claim_id, out(witness)]),
    witness(no_geometry_synthesizer_anchor_material_witness, missing_claim_id)).
dispatch_spec(geometry_synthesizer_triangulation_witness,
    [concept-term],
    call(user:synthesizer_concept_triangulation_witness,
         [concept, out(witness)]),
    witness(no_geometry_synthesizer_triangulation_witness, missing_concept)).
dispatch_spec(geometry_ccss_standard_witness,
    [concept-term, code-string],
    call(user:ccss_geometry_standard_witness, [concept, code, out(witness)]),
    witness(no_geometry_ccss_standard_witness,
            malformed_geometry_ccss_standard_request)).
dispatch_spec(geometry_indiana_standard_witness,
    [concept-term, code-string],
    call(user:indiana_geometry_standard_witness, [concept, code, out(witness)]),
    witness(no_geometry_indiana_standard_witness,
            malformed_geometry_indiana_standard_request)).
dispatch_spec(geometry_im_grade8_lesson_standard_witness,
    [concept-term, code-string],
    call(user:im_grade8_lesson_standard_witness,
         [concept, code, out(witness)]),
    witness(no_geometry_im_grade8_lesson_standard_witness,
            malformed_geometry_im_grade8_lesson_standard_request)).
dispatch_spec(geometry_im_grade7_lesson_standard_witness,
    [concept-term, code-string],
    call(user:im_grade7_lesson_standard_witness,
         [concept, code, out(witness)]),
    witness(no_geometry_im_grade7_lesson_standard_witness,
            malformed_geometry_im_grade7_lesson_standard_request)).
dispatch_spec(geometry_im_grade6_lesson_standard_witness,
    [concept-term, code-string],
    call(user:im_grade6_lesson_standard_witness,
         [concept, code, out(witness)]),
    witness(no_geometry_im_grade6_lesson_standard_witness,
            malformed_geometry_im_grade6_lesson_standard_request)).
dispatch_spec(geometry_im_grade5_standard_anchor_witness,
    [concept-term, framework-term, code-string],
    call(user:im_grade5_standard_anchor_witness,
         [concept, framework, code, out(witness)]),
    witness(no_geometry_im_grade5_standard_anchor_witness,
            malformed_geometry_im_grade5_standard_anchor_request)).

% Standards witnesses. Defaults are part of the public boundary: the generic
% reader converts an authored default through the same converter as a supplied
% value, matching request_integer/request_recollection/request_fraction.
dispatch_spec(standard_k_ns_1_count_by_ones_witness,
    [from-default(recollection, 1), to-default(recollection, 10)],
    call(standard_k_ns_1:count_by_ones_witness,
         [from, to, drop, out(witness)]),
    witness(no_standard_k_ns_1_count_by_ones_witness)).
dispatch_spec(standard_k_ns_2_represent_count_witness,
    [object_count-default(int, 4)],
    call(user:standard_k_ns_2_dispatch_witness,
         [object_count, out(witness)]),
    witness(no_standard_k_ns_2_represent_count_witness)).
dispatch_spec(standard_1_ns_1_count_by_fives_witness,
    [from-default(recollection, 5), to-default(recollection, 20)],
    call(standard_1_ns_1:count_by_fives_witness,
         [from, to, drop, out(witness)]),
    witness(no_standard_1_ns_1_count_by_fives_witness)).
dispatch_spec(standard_2_ns_1_count_by_twos_witness,
    [from-default(recollection, 2), to-default(recollection, 10)],
    call(standard_2_ns_1:count_by_twos_witness,
         [from, to, drop, out(witness)]),
    witness(no_standard_2_ns_1_count_by_twos_witness)).
dispatch_spec(standard_2_ns_2_4_place_value_witness,
    [number-default(recollection, 347)],
    call(standard_2_ns_2_4:describe_three_digit_witness,
         [number, drop, out(witness)]),
    witness(no_standard_2_ns_2_4_place_value_witness)).
dispatch_spec(standard_2_ns_5_place_value_comparison_witness,
    [left-default(recollection, 347), right-default(recollection, 329)],
    call(standard_2_ns_5:compare_by_place_value_witness,
         [left, right, drop, out(witness)]),
    witness(no_standard_2_ns_5_place_value_comparison_witness)).
dispatch_spec(standard_3_ca_5_mult_skip_count_witness,
    [factor-default(recollection, 7), times-default(recollection, 8)],
    call(user:standard_3_ca_5_dispatch_witness,
         [factor, times, out(witness)]),
    witness(no_standard_3_ca_5_mult_skip_count_witness)).
dispatch_spec(standard_2_ns_3_parity_witness,
    [number-default(recollection, 4), result-default(term, _)],
    call(standard_2_ns_3:parity_witness,
         [number, result, out(witness)]),
    witness(no_standard_2_ns_3_parity_witness)).
dispatch_spec(standard_k_ns_3_order_independence_witness,
    [objects-term],
    call(standard_k_ns_3:verify_order_independence_witness,
         [objects, drop, out(witness)]),
    witness(no_standard_k_ns_3_order_independence_witness,
            malformed_standard_k_ns_3_order_independence_request)).
dispatch_spec(standard_k_ns_4_verify_subitizing_witness,
    [pattern-term],
    call(standard_k_ns_4:verify_subitizing_witness,
         [pattern, drop, out(witness)]),
    witness(no_standard_k_ns_4_verify_subitizing_witness,
            malformed_standard_k_ns_4_verify_subitizing_request)).
dispatch_spec(standard_k_ns_5_6_compare_groups_witness,
    [group_a-term, group_b-term],
    call(standard_k_ns_5_6:compare_groups_witness,
         [group_a, group_b, drop, out(witness)]),
    witness(no_standard_k_ns_5_6_compare_groups_witness,
            malformed_standard_k_ns_5_6_compare_groups_request)).
dispatch_spec(standard_k_ns_7_place_value_witness,
    [number-default(recollection, 14)],
    call(standard_k_ns_7:describe_place_value_witness,
         [number, drop, out(witness)]),
    witness(no_standard_k_ns_7_place_value_witness)).
dispatch_spec(standard_k_ca_1_3_complement_witness,
    [given-default(recollection, 6)],
    call(standard_k_ca_1_3:find_complement_to_ten_witness,
         [given, drop, out(witness)]),
    witness(no_standard_k_ca_1_3_complement_witness)).
dispatch_spec(standard_1_ns_2_place_value_witness,
    [number-default(recollection, 47)],
    call(standard_1_ns_2:describe_two_digit_witness,
         [number, drop, out(witness)]),
    witness(no_standard_1_ns_2_place_value_witness)).
dispatch_spec(standard_1_ca_1_making_ten_witness,
    [a-default(recollection, 8), b-default(recollection, 5)],
    call(standard_1_ca_1:add_making_ten_witness,
         [a, b, drop, out(witness)]),
    witness(no_standard_1_ca_1_making_ten_witness)).
dispatch_spec(standard_1_ca_3_add_by_place_value_witness,
    [a-default(recollection, 27), b-default(recollection, 35)],
    call(standard_1_ca_3:add_by_place_value_witness,
         [a, b, drop, out(witness)]),
    witness(no_standard_1_ca_3_add_by_place_value_witness)).
dispatch_spec(standard_2_ca_2_add_three_digit_witness,
    [a-default(recollection, 347), b-default(recollection, 286)],
    call(standard_2_ca_2:add_three_digit_witness,
         [a, b, drop, out(witness)]),
    witness(no_standard_2_ca_2_add_three_digit_witness)).
dispatch_spec(standard_3_ca_3_4_fact_family_witness,
    [a-default(recollection, 3), b-default(recollection, 4)],
    call(standard_3_ca_3_4:mult_div_family_witness,
         [a, b, drop, drop, out(witness)]),
    witness(no_standard_3_ca_3_4_fact_family_witness)).
dispatch_spec(standard_3_ns_2_unit_fraction_witness,
    [denominator-default(recollection, 4)],
    call(standard_3_ns_2:make_unit_fraction_witness,
         [denominator, drop, out(witness)]),
    witness(no_standard_3_ns_2_unit_fraction_witness)).
dispatch_spec(standard_3_ns_5_fraction_comparison_witness,
    [left-default(fraction, _{n:1, d:4}),
     right-default(fraction, _{n:3, d:4}),
     result-default(term, _)],
    call(standard_3_ns_5:compare_fractions_witness,
         [left, right, result, out(witness)]),
    witness(no_standard_3_ns_5_fraction_comparison_witness)).
dispatch_spec(multiply_array_witness,
    [rows-default(int, 3), cols-default(int, 4)],
    call(user:multiply_array_dispatch_witness,
         [rows, cols, out(witness)]),
    witness_input_errorless(no_multiply_array_witness)).
dispatch_spec(mult_div_family_witness,
    [a-default(int, 3), b-default(int, 4)],
    call(user:mult_div_family_dispatch_witness,
         [a, b, out(witness)]),
    witness_input_errorless(no_mult_div_family_witness)).

% Formal and PML witnesses, including the two formal axiom-pack gates.
dispatch_spec(axiom_hierarchy_witness,
    [kind-term],
    call(user:hierarchy_proof_witness, [kind, out(witness)]),
    witness(no_axiom_hierarchy_witness, missing_kind)).
dispatch_spec(critique_bad_infinite,
    [proof-term],
    call(critique:bad_infinite_witness, [proof, out(witness)]),
    witness(no_bad_infinite_witness, missing_proof)).
dispatch_spec(defeasible_classify,
    [inference_id-term, defeater_set-list],
    call(defeasible_inference:classify_defeat_witness,
         [inference_id, defeater_set, out(outcome), out(witness)]),
    witness_wrap_errorless([outcome-outcome],
                           malformed_defeasible_classify_request)).
dispatch_spec(embodied_proof_witness,
    [sequent-term, resources-json],
    call(embodied_prover:proves_witness,
         [sequent, resources, drop, drop, out(witness)]),
    witness(no_embodied_proof_witness,
            malformed_embodied_proof_request)).
dispatch_spec(eml_transition_witness,
    [from-term, to-term],
    call(sequent_engine:eml_transition_witness,
         [from, to, out(witness)]),
    witness(no_eml_transition_witness,
            malformed_eml_transition_request)).
dispatch_spec(incoherent_witness,
    [context-term],
    call(sequent_engine:incoherent_witness,
         [context, out(witness)]),
    witness(no_incoherent_witness, missing_context)).
dispatch_spec(incompatibility_discovery_witness,
    [context-term, set-term],
    call(incompatibility_discovery:classify_candidate_set_witness,
         [context, set, drop, out(witness)]),
    witness_errorless(malformed_incompatibility_discovery_request)).
dispatch_spec(incompatibility_entailment_witness,
    [replacement-term, replaced-term],
    call(incompatibility_sets:incompatibility_entailment_witness,
         [replacement, replaced, out(witness)]),
    witness(no_incompatibility_entailment_witness,
            malformed_incompatibility_entailment_request)).
dispatch_spec(number_theory_self_defeat_witness,
    [list-list],
    call(sequent_engine:number_theory_self_defeat_witness,
         [list, out(witness)],
         [gate(axiom_pack(number_theory))]),
    witness(no_number_theory_self_defeat_witness,
            malformed_number_theory_request)).
dispatch_spec(robinson_axiom_witness,
    [axiom-term, claim-term],
    call(sequent_engine:robinson_axiom_witness,
         [axiom, claim, out(witness)],
         [gate(axiom_pack(robinson))]),
    witness(no_robinson_axiom_witness,
            malformed_robinson_axiom_request)).
dispatch_spec(semantic_material_witness,
    [from-term, to-term],
    call(semantic_axioms:semantic_material_witness,
         [from, to, out(witness)]),
    witness(no_semantic_material_witness,
            malformed_semantic_material_request)).
dispatch_spec(intersubjective_material_witness,
    [from-term, to-term],
    call(intersubjective_praxis:intersubjective_material_witness,
         [from, to, out(witness)]),
    witness(no_intersubjective_material_witness,
            malformed_intersubjective_material_request)).
dispatch_spec(mua_kind_coherence_witness,
    [kind-term, row_text-json],
    call(cw_mua_coherence:mua_coherence_source_witness,
         [kind, row_text, drop, const(pml_vocabulary), out(witness)]),
    witness(no_mua_kind_coherence_witness,
            malformed_mua_kind_coherence_request)).
dispatch_spec(validate_reader_axioms,
    [clauses-json_list, lesson_code-code],
    call(hermes_encyclopedia:validate_reader_axioms_dict,
         [lesson_code, clauses, out(dict)]),
    raw(missing_arguments)).

% Grounding and misconception operations use thin response adapters where the
% historical result is an aggregate rather than a predicate-owned witness.
dispatch_spec(commitment_match,
    [content-nonempty_text],
    call(user:commitment_match_dispatch_dict, [content, out(dict)]),
    raw_safe(missing_content)).
dispatch_spec(corpus_grammar_summary,
    [],
    call(corpus_attested_grammar:corpus_grammar_summary, [out(witness)]),
    witness(no_corpus_grammar_summary)).
dispatch_spec(elaborations,
    [],
    call(user:elaborations_dispatch_dict, [out(dict)]),
    raw).
dispatch_spec(grounding_inference_witness,
    [metaphor-term, inference-term],
    call(grounding_metaphors:grounds_inference_witness,
         [metaphor, inference, drop, out(witness)]),
    witness(no_grounding_inference_witness,
            malformed_grounding_inference_request)).
dispatch_spec(image_schema,
    [practice-practice],
    call(user:image_schema_dispatch_dict, [practice, out(dict)]),
    raw(missing_practice)).
dispatch_spec(primitive_for_practice,
    [practice-practice],
    call(user:primitive_for_practice_dispatch_dict, [practice, out(dict)]),
    raw(missing_practice)).
dispatch_spec(representation_spine_witness,
    [concept-default(optional_code, _)],
    call(user:representation_spine_dispatch_witness,
         [concept, out(witness)]),
    witness(no_representation_spine_witness)).
dispatch_spec(target_expressive_power_witness,
    [target-term],
    call(user:target_expressive_power_witness, [target, out(witness)]),
    witness(no_target_expressive_power_witness, missing_target)).
dispatch_spec(misconception_incompatibility_witness,
    [move-term, conflict-term],
    call(misconception_registry:incompatibility_with_witness,
         [move, conflict, out(witness)]),
    witness(no_misconception_incompatibility_witness,
            malformed_misconception_incompatibility_request)).
dispatch_spec(lesson_misconception_incompatibility_witness,
    [lesson_code-json, name-term, operation-default(term, _)],
    call(user:lesson_misconception_incompatibility_witness,
         [lesson_code, operation, name, out(witness)]),
    witness(no_lesson_misconception_incompatibility_witness,
            malformed_lesson_misconception_incompatibility_request)).
dispatch_spec(misconception_pml_map,
    [misconception-default(json, "")],
    call(user:misconception_pml_map_dispatch_dict,
         [misconception, out(dict)]),
    raw).

dispatch_spec(event_score,
    [event-json],
    call(hermes_event_scoring:score_event, [event, out(dict)]),
    raw_safe(missing_event)).
dispatch_spec(batch_event_score,
    [events-json_list],
    call(user:batch_event_score_dispatch_dict, [events, out(dict)]),
    raw_safe(missing_events)).
dispatch_spec(pair_score,
    [events-json_list],
    call(hermes_pair_scoring:score_pair_candidates, [events, out(dict)]),
    raw_safe(missing_events)).
dispatch_spec(pair_graph,
    [events-json_list],
    call(user:pair_graph_dispatch_dict, [events, out(dict)]),
    raw_safe(missing_events)).
dispatch_spec(monitoring_chart_export,
    [lesson_code-code],
    call(user:monitoring_chart_export_dict, [lesson_code, out(dict)]),
    raw(unknown_lesson_code, missing_lesson_code)).
dispatch_spec(ranked_figures,
    [lesson_code-code],
    call(user:monitoring_chart_figure_export, [lesson_code, out(dict)]),
    raw(unknown_lesson_code, missing_lesson_code)).
dispatch_spec(field_context,
    [lesson_code-code],
    call(field_context:field_context_dict, [lesson_code, out(dict)]),
    raw(unknown_lesson_code, missing_lesson_code)).
dispatch_spec(field_connectivity_audit,
    [],
    call(field_context:field_connectivity_audit_dict, [out(dict)]),
    raw).
dispatch_spec(render_coverage,
    [],
    call(misconception_render_coverage:render_coverage_report_dict,
         [out(dict)]),
    raw).
dispatch_spec(expressive_power,
    [lesson-code],
    call(user:expressive_power_dispatch_dict, [lesson, out(dict)]),
    raw(missing_lesson)).
dispatch_spec(list_strategies,
    [],
    call(hermes_encyclopedia:strategy_catalog_dict, [out(dict)]),
    raw).
dispatch_spec(strategy_trace,
    [strategy-code, input-default(dict, _{})],
    call(hermes_encyclopedia:strategy_trace_dict,
         [strategy, input, out(dict)]),
    raw(missing_strategy)).
dispatch_spec(list_misconceptions,
    [domain-default(filter, all)],
    call(hermes_encyclopedia:misconception_catalog_dict,
         [domain, out(dict)]),
    raw).
dispatch_spec(list_standards,
    [framework-default(filter, all)],
    call(hermes_encyclopedia:standards_catalog_dict,
         [framework, out(dict)]),
    raw).
dispatch_spec(grounding_metaphors,
    [],
    call(hermes_encyclopedia:grounding_catalog_dict, [out(dict)]),
    raw).
dispatch_spec(grounding_for,
    [operation-code],
    call(hermes_encyclopedia:grounding_for_operation_dict,
         [operation, out(dict)]),
    raw(missing_operation)).
dispatch_spec(ground,
    [query-json],
    call(hermes_encyclopedia:ground_query_dict, [query, out(dict)]),
    raw(missing_query)).
dispatch_spec(lit_search,
    [query-json],
    call(hermes_encyclopedia:literature_search_dict, [query, out(dict)]),
    raw(missing_query)).
dispatch_spec(pml_score,
    [clauses-json_list],
    call(hermes_encyclopedia:pml_score_dict, [clauses, out(dict)]),
    raw(missing_clauses)).
dispatch_spec(canonical_contract,
    [],
    call(user:canonical_contract_dispatch_dict, [out(dict)]),
    raw).
dispatch_spec(brandom_backstop,
    [],
    call(user:brandom_backstop_dispatch_dict, [out(dict)]),
    raw_safe).
dispatch_spec(carving_strategy_proof,
    [operation-default(op_atom, add),
     x-fallback(int, 0), y-fallback(int, 0), z-fallback(int, 0)],
    call(user:carving_strategy_proof_dispatch_dict,
         [operation, x, y, z, out(dict)]),
    raw_safe(no_carving_proof, missing_fact_args)).
dispatch_spec(carving_operation_summary,
    [operation-default(op_atom, add)],
    call(carving_query:carving_operation_summary,
         [operation, out(dict)]),
    raw_safe(no_carving_summary, _)).
dispatch_spec(benny_demo,
    [],
    call(misconceptions_benny_demo:benny_demo_dict, [out(dict)]),
    raw_safe(no_benny_demo, _)).

dispatch_message(event_score, malformed, "event_score requires event").
dispatch_message(batch_event_score, malformed, "batch_event_score requires events list").
dispatch_message(pair_score, malformed, "pair_score requires events list").
dispatch_message(pair_graph, malformed, "pair_graph requires events list").
dispatch_message(monitoring_chart_export, malformed, "monitoring_chart_export requires lesson_code").
dispatch_message(monitoring_chart_export, no_result, "monitoring_chart_export found no chart for lesson_code").
dispatch_message(ranked_figures, malformed, "ranked_figures requires lesson_code").
dispatch_message(ranked_figures, no_result, "ranked_figures found no selector candidates for lesson_code").
dispatch_message(field_context, malformed, "field_context requires lesson_code").
dispatch_message(field_context, no_result, "field_context found no context for lesson_code").
dispatch_message(expressive_power, malformed, "expressive_power requires lesson").
dispatch_message(strategy_trace, malformed, "strategy_trace requires strategy").
dispatch_message(grounding_for, malformed, "grounding_for requires operation").
dispatch_message(ground, malformed, "ground requires query").
dispatch_message(lit_search, malformed, "lit_search requires query").
dispatch_message(pml_score, malformed, "pml_score requires clauses (a list of strings)").
dispatch_message(carving_strategy_proof, malformed, "carving_strategy_proof requires operation, x, y, and z").
dispatch_message(carving_strategy_proof, no_result, "carving_strategy_proof found no productive proof for that fact").
dispatch_message(carving_operation_summary, no_result, "carving_operation_summary found no bounded experiment for that operation").
dispatch_message(benny_demo, no_result, "benny_demo produced no comparison data").

dispatch_message(axiom_pack_witness, no_witness, "axiom_pack_witness found no enabled-pack recorded example").
dispatch_message(axiom_pack_witness, malformed, "axiom_pack_witness requires pack and source").
dispatch_message(viability_witness, no_witness, "viability_witness found no sufficient resource recorded example").
dispatch_message(viability_witness, malformed, "viability_witness requires resources, cost, and source").
dispatch_message(modal_context_witness, no_witness, "modal_context_witness found no modal-context recorded example").
dispatch_message(modal_context_witness, malformed, "modal_context_witness requires term, context, and source").
dispatch_message(grounded_arith_witness, no_witness, "grounded_arith_witness found no owner-verified grounded arithmetic operation").
dispatch_message(grounded_arith_witness, malformed, "grounded_arith_witness requires operation, inputs, output, and source").
dispatch_message(material_inference_witness, no_witness, "material_inference_witness found no material-inference recorded example").
dispatch_message(material_inference_witness, malformed, "material_inference_witness requires inference_id, premises, conclusion, and source").
dispatch_message(normative_crisis_witness, no_witness, "normative_crisis_witness found no normative-crisis recorded example").
dispatch_message(normative_crisis_witness, malformed, "normative_crisis_witness requires context, goal, and source").
dispatch_message(metaphor_break_witness, no_witness, "metaphor_break_witness found no metaphor-break recorded example").
dispatch_message(metaphor_break_witness, malformed, "metaphor_break_witness requires metaphor, inference, detail, and source").
dispatch_message(grounding_metaphor_witness, no_witness, "grounding_metaphor_witness found no grounding-metaphor recorded example").
dispatch_message(grounding_metaphor_witness, malformed, "grounding_metaphor_witness requires metaphor, anchor, and source").
dispatch_message(unit_coordination_witness, no_witness, "unit_coordination_witness found no unit-coordination recorded example").
dispatch_message(unit_coordination_witness, malformed, "unit_coordination_witness requires key, detail, and source").
dispatch_message(godel_primes_witness, no_witness, "godel_primes_witness found no prime-utility recorded example").
dispatch_message(godel_primes_witness, malformed, "godel_primes_witness requires query and source").
dispatch_message(fsm_engine_witness, no_witness, "fsm_engine_witness found no loaded FSM executor registry recorded example").
dispatch_message(fsm_engine_witness, malformed, "fsm_engine_witness requires descriptor and source").
dispatch_message(action_cluster_witness, no_witness, "action_cluster_witness found no action-cluster recorded example").
dispatch_message(action_cluster_witness, malformed, "action_cluster_witness requires operation, kind, cluster, and source").
dispatch_message(practice_vocabulary_witness, no_witness, "practice_vocabulary_witness found no practice-vocabulary recorded example").
dispatch_message(practice_vocabulary_witness, malformed, "practice_vocabulary_witness requires key and source").
dispatch_message(accommodation_witness, no_witness, "accommodation_witness found no accommodation registry recorded example").
dispatch_message(accommodation_witness, malformed, "accommodation_witness requires target and source").
dispatch_message(domain_context_witness, no_witness, "domain_context_witness found no domain-context recorded example").
dispatch_message(domain_context_witness, malformed, "domain_context_witness requires domain, context, and source").
dispatch_message(orr_entry_witness, no_witness, "orr_entry_witness found no Observe-React-Reorganize entry registry recorded example").
dispatch_message(orr_entry_witness, malformed, "orr_entry_witness requires variant and source").
dispatch_message(executable_practice_witness, no_witness, "executable_practice_witness found no executable-practice registry recorded example").
dispatch_message(executable_practice_witness, malformed, "executable_practice_witness requires variant and source").
dispatch_message(misconception_hook_witness, no_witness, "misconception_hook_witness found no misconception-hook recorded example").
dispatch_message(misconception_hook_witness, malformed, "misconception_hook_witness requires operation, outcome, family, and source").
dispatch_message(algebra_claim_witness, no_witness, "algebra_claim_witness: no recorded crosswalk record connects the requested algebra claim and source").
dispatch_message(integer_signed_claim_witness, no_witness, "integer_signed_claim_witness: no recorded crosswalk record connects the requested signed-integer claim and source").
dispatch_message(arithmetic_property_witness, no_witness, "arithmetic_property_witness: no recorded crosswalk record connects the requested arithmetic-property claim and source").
dispatch_message(calculus_claim_witness, no_witness, "calculus_claim_witness: no recorded crosswalk record connects the requested calculus claim and source").
dispatch_message(counting_claim_witness, no_witness, "counting_claim_witness: no recorded crosswalk record connects the requested counting claim and source").
dispatch_message(whole_number_addsub_claim_witness, no_witness, "whole_number_addsub_claim_witness: no recorded crosswalk record connects the requested addition/subtraction claim and source").
dispatch_message(ratio_proportion_claim_witness, no_witness, "ratio_proportion_claim_witness: no recorded crosswalk record connects the requested ratio/proportion claim and source").
dispatch_message(magnitude_equivalence_claim_witness, no_witness, "magnitude_equivalence_claim_witness: no recorded crosswalk record connects the requested magnitude-equivalence claim and source").
dispatch_message(multiplication_division_claim_witness, no_witness, "multiplication_division_claim_witness: no recorded crosswalk record connects the requested multiplication/division claim and source").
dispatch_message(decimal_claim_witness, no_witness, "decimal_claim_witness: no recorded crosswalk record connects the requested decimal claim and source").
dispatch_message(place_value_number_claim_witness, no_witness, "place_value_number_claim_witness: no recorded crosswalk record connects the requested place-value claim and source").
dispatch_message(whole_number_claim_witness, no_witness, "whole_number_claim_witness: no recorded crosswalk record connects the requested zero claim and source").
dispatch_message(fraction_extra_claim_witness, no_witness, "fraction_extra_claim_witness: no recorded crosswalk record connects the requested additional-fraction claim and source").
dispatch_message(fraction_claim_witness, no_witness, "fraction_claim_witness: no recorded crosswalk record connects the requested fraction claim and source").
dispatch_message(algebra_claim_witness, malformed, "algebra_claim_witness requires canonical and source").
dispatch_message(integer_signed_claim_witness, malformed, "integer_signed_claim_witness requires canonical and source").
dispatch_message(arithmetic_property_witness, malformed, "arithmetic_property_witness requires canonical and source").
dispatch_message(calculus_claim_witness, malformed, "calculus_claim_witness requires canonical and source").
dispatch_message(counting_claim_witness, malformed, "counting_claim_witness requires canonical and source").
dispatch_message(whole_number_addsub_claim_witness, malformed, "whole_number_addsub_claim_witness requires canonical and source").
dispatch_message(ratio_proportion_claim_witness, malformed, "ratio_proportion_claim_witness requires canonical and source").
dispatch_message(magnitude_equivalence_claim_witness, malformed, "magnitude_equivalence_claim_witness requires canonical and source").
dispatch_message(multiplication_division_claim_witness, malformed, "multiplication_division_claim_witness requires canonical and source").
dispatch_message(decimal_claim_witness, malformed, "decimal_claim_witness requires canonical and source").
dispatch_message(place_value_number_claim_witness, malformed, "place_value_number_claim_witness requires canonical and source").
dispatch_message(whole_number_claim_witness, malformed, "whole_number_claim_witness requires canonical and source").
dispatch_message(fraction_extra_claim_witness, malformed, "fraction_extra_claim_witness requires canonical and source").
dispatch_message(fraction_claim_witness, malformed, "fraction_claim_witness requires canonical and source").
dispatch_message(productive_deformation_witness, no_witness, "productive_deformation_witness found no recorded productive and wrong-answer pair").
dispatch_message(productive_deformation_witness, malformed, "productive_deformation_witness requires operation, productive, deformation, family, and source").
dispatch_message(mua_coherence_witness, no_witness, "mua_coherence_witness found no coherence scoring recorded example").
dispatch_message(mua_coherence_witness, malformed, "mua_coherence_witness requires subject, input, and source").
dispatch_message(geometry_entailment_witness, no_witness, "geometry_entailment_witness found no entailment recorded example").
dispatch_message(geometry_entailment_witness, malformed, "geometry_entailment_witness requires entailer and entailed").
dispatch_message(geometry_material_profile_witness, no_witness, "geometry_material_profile_witness found no profile recorded example for concept").
dispatch_message(geometry_material_profile_witness, malformed, "geometry_material_profile_witness requires concept").
dispatch_message(geometry_quadrilateral_entailment_witness, no_witness, "geometry_quadrilateral_entailment_witness found no entailment recorded example").
dispatch_message(geometry_quadrilateral_entailment_witness, malformed, "geometry_quadrilateral_entailment_witness requires entailer and entailed").
dispatch_message(geometry_strength_lift_coverage_witness, no_witness, "geometry_strength_lift_coverage_witness found no coverage recorded example").
dispatch_message(geometry_van_hiele_material_witness, no_witness, "geometry_van_hiele_material_witness found no material recorded example for claim_id").
dispatch_message(geometry_van_hiele_material_witness, malformed, "geometry_van_hiele_material_witness requires claim_id").
dispatch_message(geometry_van_hiele_marker_witness, no_witness, "geometry_van_hiele_marker_witness found no marker recorded example").
dispatch_message(geometry_van_hiele_marker_witness, malformed, "geometry_van_hiele_marker_witness requires concept and level").
dispatch_message(geometry_cross_link_witness, no_witness, "geometry_cross_link_witness found no cross-link recorded example").
dispatch_message(geometry_cross_link_witness, malformed, "geometry_cross_link_witness requires source, relation, and target").
dispatch_message(geometry_developmental_arc_witness, no_witness, "geometry_developmental_arc_witness found no arc recorded example").
dispatch_message(geometry_developmental_arc_witness, malformed, "geometry_developmental_arc_witness requires arc_id").
dispatch_message(geometry_attribute_material_witness, no_witness, "geometry_attribute_material_witness found no material recorded example").
dispatch_message(geometry_attribute_material_witness, malformed, "geometry_attribute_material_witness requires claim_id").
dispatch_message(geometry_similarity_material_witness, no_witness, "geometry_similarity_material_witness found no material recorded example").
dispatch_message(geometry_similarity_material_witness, malformed, "geometry_similarity_material_witness requires claim_id").
dispatch_message(geometry_pythagorean_material_witness, no_witness, "geometry_pythagorean_material_witness found no material recorded example").
dispatch_message(geometry_pythagorean_material_witness, malformed, "geometry_pythagorean_material_witness requires claim_id").
dispatch_message(geometry_van_hiele_level_material_witness, no_witness, "geometry_van_hiele_level_material_witness found no material recorded example").
dispatch_message(geometry_van_hiele_level_material_witness, malformed, "geometry_van_hiele_level_material_witness requires claim_id").
dispatch_message(geometry_measurement_misconception_witness, no_witness, "geometry_measurement_misconception_witness found no misconception recorded example").
dispatch_message(geometry_measurement_misconception_witness, malformed, "geometry_measurement_misconception_witness requires id_value").
dispatch_message(geometry_n103_bootstrap_witness, no_witness, "geometry_n103_bootstrap_witness found no bootstrap recorded example").
dispatch_message(geometry_n103_bootstrap_witness, malformed, "geometry_n103_bootstrap_witness requires bootstrap_id").
dispatch_message(geometry_van_de_walle_bootstrap_witness, no_witness, "geometry_van_de_walle_bootstrap_witness found no bootstrap recorded example").
dispatch_message(geometry_van_de_walle_bootstrap_witness, malformed, "geometry_van_de_walle_bootstrap_witness requires bootstrap_id").
dispatch_message(geometry_shape_recognition_material_witness, no_witness, "geometry_shape_recognition_material_witness found no material recorded example").
dispatch_message(geometry_shape_recognition_material_witness, malformed, "geometry_shape_recognition_material_witness requires claim_id").
dispatch_message(geometry_coordinate_material_witness, no_witness, "geometry_coordinate_material_witness found no material recorded example").
dispatch_message(geometry_coordinate_material_witness, malformed, "geometry_coordinate_material_witness requires claim_id").
dispatch_message(geometry_angle_material_witness, no_witness, "geometry_angle_material_witness found no material recorded example").
dispatch_message(geometry_angle_material_witness, malformed, "geometry_angle_material_witness requires claim_id").
dispatch_message(geometry_area_perimeter_material_witness, no_witness, "geometry_area_perimeter_material_witness found no material recorded example").
dispatch_message(geometry_area_perimeter_material_witness, malformed, "geometry_area_perimeter_material_witness requires claim_id").
dispatch_message(geometry_volume_surface_area_material_witness, no_witness, "geometry_volume_surface_area_material_witness found no material recorded example").
dispatch_message(geometry_volume_surface_area_material_witness, malformed, "geometry_volume_surface_area_material_witness requires claim_id").
dispatch_message(geometry_transformation_material_witness, no_witness, "geometry_transformation_material_witness found no material recorded example").
dispatch_message(geometry_transformation_material_witness, malformed, "geometry_transformation_material_witness requires claim_id").
dispatch_message(geometry_classification_material_witness, no_witness, "geometry_classification_material_witness found no material recorded example").
dispatch_message(geometry_classification_material_witness, malformed, "geometry_classification_material_witness requires claim_id").
dispatch_message(geometry_pck_classification_witness, no_witness, "geometry_pck_classification_witness found no synthesis recorded example").
dispatch_message(geometry_pck_classification_witness, malformed, "geometry_pck_classification_witness requires concept").
dispatch_message(geometry_measuring_stick_metaphor_witness, no_witness, "geometry_measuring_stick_metaphor_witness found no metaphor recorded example").
dispatch_message(geometry_measuring_stick_metaphor_witness, malformed, "geometry_measuring_stick_metaphor_witness requires concept and metaphor").
dispatch_message(geometry_lakoff_nunez_metaphor_witness, no_witness, "geometry_lakoff_nunez_metaphor_witness found no metaphor recorded example").
dispatch_message(geometry_lakoff_nunez_metaphor_witness, malformed, "geometry_lakoff_nunez_metaphor_witness requires concept and metaphor").
dispatch_message(geometry_synthesizer_anchor_material_witness, no_witness, "geometry_synthesizer_anchor_material_witness found no material recorded example").
dispatch_message(geometry_synthesizer_anchor_material_witness, malformed, "geometry_synthesizer_anchor_material_witness requires claim_id").
dispatch_message(geometry_synthesizer_triangulation_witness, no_witness, "geometry_synthesizer_triangulation_witness found no concept recorded example").
dispatch_message(geometry_synthesizer_triangulation_witness, malformed, "geometry_synthesizer_triangulation_witness requires concept").
dispatch_message(geometry_ccss_standard_witness, no_witness, "geometry_ccss_standard_witness found no standard recorded example").
dispatch_message(geometry_ccss_standard_witness, malformed, "geometry_ccss_standard_witness requires concept and code").
dispatch_message(geometry_indiana_standard_witness, no_witness, "geometry_indiana_standard_witness found no standard recorded example").
dispatch_message(geometry_indiana_standard_witness, malformed, "geometry_indiana_standard_witness requires concept and code").
dispatch_message(geometry_im_grade8_lesson_standard_witness, no_witness, "geometry_im_grade8_lesson_standard_witness found no lesson recorded example").
dispatch_message(geometry_im_grade8_lesson_standard_witness, malformed, "geometry_im_grade8_lesson_standard_witness requires concept and code").
dispatch_message(geometry_im_grade7_lesson_standard_witness, no_witness, "geometry_im_grade7_lesson_standard_witness found no lesson recorded example").
dispatch_message(geometry_im_grade7_lesson_standard_witness, malformed, "geometry_im_grade7_lesson_standard_witness requires concept and code").
dispatch_message(geometry_im_grade6_lesson_standard_witness, no_witness, "geometry_im_grade6_lesson_standard_witness found no lesson recorded example").
dispatch_message(geometry_im_grade6_lesson_standard_witness, malformed, "geometry_im_grade6_lesson_standard_witness requires concept and code").
dispatch_message(geometry_im_grade5_standard_anchor_witness, no_witness, "geometry_im_grade5_standard_anchor_witness found no standard recorded example").
dispatch_message(geometry_im_grade5_standard_anchor_witness, malformed, "geometry_im_grade5_standard_anchor_witness requires concept, framework, and code").
dispatch_message(standard_k_ns_1_count_by_ones_witness, no_witness, "standard_k_ns_1_count_by_ones_witness found no finite counting trace").
dispatch_message(standard_k_ns_2_represent_count_witness, no_witness, "standard_k_ns_2_represent_count_witness requires object_count between 0 and 20").
dispatch_message(standard_1_ns_1_count_by_fives_witness, no_witness, "standard_1_ns_1_count_by_fives_witness found no finite count-by-fives trace").
dispatch_message(standard_2_ns_1_count_by_twos_witness, no_witness, "standard_2_ns_1_count_by_twos_witness found no finite count-by-twos trace").
dispatch_message(standard_2_ns_2_4_place_value_witness, no_witness, "standard_2_ns_2_4_place_value_witness found no finite three-digit place-value proof").
dispatch_message(standard_2_ns_5_place_value_comparison_witness, no_witness, "standard_2_ns_5_place_value_comparison_witness found no finite place-value comparison proof").
dispatch_message(standard_3_ca_5_mult_skip_count_witness, no_witness, "standard_3_ca_5_mult_skip_count_witness found no finite skip-count multiplication result").
dispatch_message(standard_2_ns_3_parity_witness, no_witness, "standard_2_ns_3_parity_witness found no finite parity proof").
dispatch_message(standard_k_ns_3_order_independence_witness, no_witness, "standard_k_ns_3_order_independence_witness found no finite order-independence proof").
dispatch_message(standard_k_ns_3_order_independence_witness, malformed, "standard_k_ns_3_order_independence_witness requires objects").
dispatch_message(standard_k_ns_4_verify_subitizing_witness, no_witness, "standard_k_ns_4_verify_subitizing_witness found no finite recognition-count agreement proof").
dispatch_message(standard_k_ns_4_verify_subitizing_witness, malformed, "standard_k_ns_4_verify_subitizing_witness requires pattern").
dispatch_message(standard_k_ns_5_6_compare_groups_witness, no_witness, "standard_k_ns_5_6_compare_groups_witness found no finite group-comparison proof").
dispatch_message(standard_k_ns_5_6_compare_groups_witness, malformed, "standard_k_ns_5_6_compare_groups_witness requires group_a and group_b").
dispatch_message(standard_k_ns_7_place_value_witness, no_witness, "standard_k_ns_7_place_value_witness found no finite one-ten-group proof").
dispatch_message(standard_k_ca_1_3_complement_witness, no_witness, "standard_k_ca_1_3_complement_witness found no finite complement-to-ten proof").
dispatch_message(standard_1_ns_2_place_value_witness, no_witness, "standard_1_ns_2_place_value_witness found no finite two-digit place-value proof").
dispatch_message(standard_1_ca_1_making_ten_witness, no_witness, "standard_1_ca_1_making_ten_witness found no finite making-ten proof").
dispatch_message(standard_1_ca_3_add_by_place_value_witness, no_witness, "standard_1_ca_3_add_by_place_value_witness found no finite place-value addition proof").
dispatch_message(standard_2_ca_2_add_three_digit_witness, no_witness, "standard_2_ca_2_add_three_digit_witness found no finite three-digit addition proof").
dispatch_message(standard_3_ca_3_4_fact_family_witness, no_witness, "standard_3_ca_3_4_fact_family_witness found no finite multiplication/division family proof").
dispatch_message(standard_3_ns_2_unit_fraction_witness, no_witness, "standard_3_ns_2_unit_fraction_witness found no finite unit-fraction proof").
dispatch_message(standard_3_ns_5_fraction_comparison_witness, no_witness, "standard_3_ns_5_fraction_comparison_witness found no finite comparison proof").
dispatch_message(multiply_array_witness, no_witness, "multiply_array_witness found no array model for the given rows/cols").
dispatch_message(mult_div_family_witness, no_witness, "mult_div_family_witness found no fact family for the given a/b").
dispatch_message(axiom_hierarchy_witness, no_witness, "axiom_hierarchy_witness found no hierarchy proof recorded example for kind").
dispatch_message(axiom_hierarchy_witness, malformed, "axiom_hierarchy_witness requires kind").
dispatch_message(critique_bad_infinite, no_witness, "critique_bad_infinite found no bad-infinite recorded example for proof").
dispatch_message(critique_bad_infinite, malformed, "critique_bad_infinite requires proof").
dispatch_message(defeasible_classify, malformed, "defeasible_classify requires inference_id and defeater_set list").
dispatch_message(embodied_proof_witness, no_witness, "embodied_proof_witness found no proof recorded example").
dispatch_message(embodied_proof_witness, malformed, "embodied_proof_witness requires sequent and resources").
dispatch_message(eml_transition_witness, no_witness, "eml_transition_witness found no transition recorded example for from/to").
dispatch_message(eml_transition_witness, malformed, "eml_transition_witness requires from and to").
dispatch_message(incoherent_witness, no_witness, "incoherent_witness found no recorded example for context").
dispatch_message(incoherent_witness, malformed, "incoherent_witness requires context").
dispatch_message(incompatibility_discovery_witness, malformed, "incompatibility_discovery_witness requires context and set").
dispatch_message(incompatibility_entailment_witness, no_witness, "incompatibility_entailment_witness found no entailment recorded example").
dispatch_message(incompatibility_entailment_witness, malformed, "incompatibility_entailment_witness requires replacement and replaced").
dispatch_message(number_theory_self_defeat_witness, no_witness, "number_theory_self_defeat_witness found no Euclid recorded example for list").
dispatch_message(number_theory_self_defeat_witness, malformed, "number_theory_self_defeat_witness requires list").
dispatch_message(robinson_axiom_witness, no_witness, "robinson_axiom_witness found no recorded example for axiom/claim").
dispatch_message(robinson_axiom_witness, malformed, "robinson_axiom_witness requires axiom and claim").
dispatch_message(semantic_material_witness, no_witness, "semantic_material_witness found no material recorded example").
dispatch_message(semantic_material_witness, malformed, "semantic_material_witness requires from and to").
dispatch_message(intersubjective_material_witness, no_witness, "intersubjective_material_witness found no material recorded example").
dispatch_message(intersubjective_material_witness, malformed, "intersubjective_material_witness requires from and to").
dispatch_message(mua_kind_coherence_witness, no_witness, "mua_kind_coherence_witness found no scoring recorded example").
dispatch_message(mua_kind_coherence_witness, malformed, "mua_kind_coherence_witness requires kind and row_text").
dispatch_message(validate_reader_axioms, malformed, "validate_reader_axioms requires lesson_code and clauses (a list of strings)").
dispatch_message(commitment_match, malformed, "commitment_match requires non-empty content").
dispatch_message(corpus_grammar_summary, no_witness, "corpus_grammar_summary produced no summary").
dispatch_message(grounding_inference_witness, no_witness, "grounding_inference_witness found no grounding recorded example").
dispatch_message(grounding_inference_witness, malformed, "grounding_inference_witness requires metaphor and inference").
dispatch_message(image_schema, malformed, "image_schema requires practice (a practice atom string)").
dispatch_message(primitive_for_practice, malformed, "primitive_for_practice requires practice (a practice atom string)").
dispatch_message(representation_spine_witness, no_witness, "representation_spine_witness found no renders_on route or asset for that concept").
dispatch_message(target_expressive_power_witness, no_witness, "target_expressive_power_witness found no recorded example for target").
dispatch_message(target_expressive_power_witness, malformed, "target_expressive_power_witness requires target").
dispatch_message(misconception_incompatibility_witness, no_witness, "misconception_incompatibility_witness found no registry recorded example").
dispatch_message(misconception_incompatibility_witness, malformed, "misconception_incompatibility_witness requires move and conflict").
dispatch_message(lesson_misconception_incompatibility_witness, no_witness, "lesson_misconception_incompatibility_witness found no lesson recorded example").
dispatch_message(lesson_misconception_incompatibility_witness, malformed, "lesson_misconception_incompatibility_witness requires lesson_code and name").
