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
    call(cw_algebra_claim:algebra_claim_witness,
         [canonical, drop, source, out(witness)]),
    witness(no_algebra_claim_witness)).
dispatch_spec(integer_signed_claim_witness,
    [canonical-atom, source-atom],
    call(cw_integer_signed_claim:integer_signed_claim_witness,
         [canonical, drop, source, out(witness)]),
    witness(no_integer_signed_claim_witness)).
dispatch_spec(arithmetic_property_witness,
    [canonical-atom, source-atom],
    call(cw_arithmetic_property_claim:arithmetic_property_witness,
         [canonical, drop, source, out(witness)]),
    witness(no_arithmetic_property_witness)).
dispatch_spec(calculus_claim_witness,
    [canonical-atom, source-atom],
    call(cw_calculus_claim:calculus_claim_witness,
         [canonical, drop, source, out(witness)]),
    witness(no_calculus_claim_witness)).
dispatch_spec(counting_claim_witness,
    [canonical-atom, source-atom],
    call(cw_counting_claim:counting_claim_witness,
         [canonical, drop, source, out(witness)]),
    witness(no_counting_claim_witness)).
dispatch_spec(whole_number_addsub_claim_witness,
    [canonical-atom, source-atom],
    call(cw_whole_number_addsub_claim:whole_number_addsub_claim_witness,
         [canonical, drop, source, out(witness)]),
    witness(no_whole_number_addsub_claim_witness)).
dispatch_spec(ratio_proportion_claim_witness,
    [canonical-atom, source-atom],
    call(cw_ratio_proportion_claim:ratio_proportion_claim_witness,
         [canonical, drop, source, out(witness)]),
    witness(no_ratio_proportion_claim_witness)).
dispatch_spec(magnitude_equivalence_claim_witness,
    [canonical-atom, source-atom],
    call(cw_magnitude_equivalence_claim:magnitude_equivalence_claim_witness,
         [canonical, drop, source, out(witness)]),
    witness(no_magnitude_equivalence_claim_witness)).
dispatch_spec(multiplication_division_claim_witness,
    [canonical-atom, source-atom],
    call(cw_multiplication_division_claim:multiplication_division_claim_witness,
         [canonical, drop, source, out(witness)]),
    witness(no_multiplication_division_claim_witness)).
dispatch_spec(decimal_claim_witness,
    [canonical-atom, source-atom],
    call(cw_decimal_claim:decimal_claim_witness,
         [canonical, drop, source, out(witness)]),
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
    call(cw_fraction_extra_claim:fraction_extra_claim_witness,
         [canonical, drop, source, out(witness)]),
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
