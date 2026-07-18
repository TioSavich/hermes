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
    [resources-int, cost-int, source-term],
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
