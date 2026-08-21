#!/usr/bin/env bash
# Run every check in scripts/checks/. Each check prints PASS lines and exits
# nonzero on failure. The default stops at the first failure and names it;
# HERMES_KEEP_GOING=1 runs every check and reports the failures in suite order.
# The suite includes strict SWI-Prolog loads and Node renders; a full run
# takes several minutes. route_behavior.py binds a loopback port.
set -uo pipefail
CHECKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEEP_GOING=${HERMES_KEEP_GOING:-0}
FAILED=()

# The two Prolog checks need -g main -t halt. Loading a file whose entry point is
# :- initialization(main, main) with -s does not run main: both checks sat in this
# suite contributing exit 0 without asserting anything. Found 2026-07-25 while
# checking whether a change to strategy_recognizer.pl had broken its round trips;
# it had not, and neither had anything else, because the check was not running.
run() {
    echo "== $1"
    if "${@:2}"; then
        return 0
    else
        local status=$?
        FAILED+=("$1 (exit $status)")
        if [[ "$KEEP_GOING" != 1 ]]; then
            exit "$status"
        fi
    fi
}

run root_resolver.py        python3 "$CHECKS_DIR/root_resolver.py"
run route_registry.py       python3 "$CHECKS_DIR/route_registry.py"
run witness_registry.py     python3 "$CHECKS_DIR/witness_registry.py"
run witness_defaults.py     python3 "$CHECKS_DIR/witness_defaults.py"
run static_route_containment.py python3 "$CHECKS_DIR/static_route_containment.py"
run hermes_shell_page_context.py python3 "$CHECKS_DIR/hermes_shell_page_context.py"
run required_system_prompts.py python3 "$CHECKS_DIR/required_system_prompts.py"
run mcp_description_counts.py python3 "$CHECKS_DIR/mcp_description_counts.py"
run fraction_comparison_scene.py python3 "$CHECKS_DIR/fraction_comparison_scene.py"
run deformation_compare_scene.py python3 "$CHECKS_DIR/deformation_compare_scene.py"
run visual_surface_indexes.py python3 "$CHECKS_DIR/visual_surface_indexes.py"
run mcp_search_rows.py      python3 "$CHECKS_DIR/mcp_search_rows.py"
run mcp_full_graph.py       python3 "$CHECKS_DIR/mcp_full_graph.py"
run task_240_branch_agents.py python3 "$CHECKS_DIR/task_240_branch_agents.py"
run sidekick_strategy_surface.py python3 "$CHECKS_DIR/sidekick_strategy_surface.py"
run sidekick_shadow_scorer.py python3 "$CHECKS_DIR/sidekick_shadow_scorer.py"
# The three below read the sidekick's local runtime — the checkpoint's template
# and vocabulary, M-1 evidence, and built rows. They print SKIP and pass when it is
# absent, because nothing tracked may hard-require a gitignored input.
run sidekick_mask          python3 "$CHECKS_DIR/../sidekick/supervision.py"
run sidekick_wave2_contracts.py python3 "$CHECKS_DIR/sidekick_wave2_contracts.py"
run sidekick_wave3_decomposition.py python3 "$CHECKS_DIR/sidekick_wave3_decomposition.py"
run sidekick_dataset       python3 "$CHECKS_DIR/../sidekick/dataset.py" --if-present
run math_claim_language.pl  swipl -q -l "$CHECKS_DIR/../../paths.pl" -s "$CHECKS_DIR/math_claim_language.pl" -g main -t halt
run pedagogical_questions_check.py python3 "$CHECKS_DIR/pedagogical_questions_check.py"
run strategy_recognizer.pl  swipl -q -l "$CHECKS_DIR/../../paths.pl" -s "$CHECKS_DIR/strategy_recognizer.pl" -g main -t halt
run mobius_band_readers.py  python3 "$CHECKS_DIR/mobius_band_readers.py"
run transition_tables.py    python3 "$CHECKS_DIR/transition_tables.py"
run deformation_validity.py python3 "$CHECKS_DIR/deformation_validity.py"
run vision_fraction_recovery.pl swipl -q -l "$CHECKS_DIR/../../paths.pl" -s curriculum/im/generated/vision_fraction_recovery.pl -g vision_fraction_recovery:check_vision_fraction_recovery -t halt
run lesson_representation_evidence.py python3 "$CHECKS_DIR/lesson_representation_evidence.py"
run lesson_deformation_chart_evidence.py python3 "$CHECKS_DIR/lesson_deformation_chart_evidence.py"
run misconception_render_link.py python3 "$CHECKS_DIR/misconception_render_link.py"
run build_admitted_edges python3 "$CHECKS_DIR/../bigred/loops/build_admitted_edges.py" --check
run admitted_bridges_store.py python3 "$CHECKS_DIR/admitted_bridges_store.py"
run build_kernel_dependency_overlay python3 "$CHECKS_DIR/../bigred/loops/build_kernel_dependency_overlay.py" --check
run recompute_r2_kernel_lens python3 "$CHECKS_DIR/../bigred/loops/recompute_r2_kernel_lens.py" --check
run elaboration_queries python3 "$CHECKS_DIR/../bigred/loops/elaboration_queries.py" --check
run metaphor_seam_registry.py python3 "$CHECKS_DIR/metaphor_seam_registry.py"
run automata_compendium.py  python3 "$CHECKS_DIR/automata_compendium.py"
run automata_vocabulary.py  python3 "$CHECKS_DIR/automata_vocabulary.py"
run scan_self_certifying.py python3 "$CHECKS_DIR/scan_self_certifying.py"
run full_graph.py           python3 "$CHECKS_DIR/full_graph.py"
run graph_quotients.py      python3 "$CHECKS_DIR/graph_quotients.py"
run vocabulary_licenses.py  python3 "$CHECKS_DIR/vocabulary_licenses.py"
run action_vocabulary_map.py python3 "$CHECKS_DIR/action_vocabulary_map.py"
run action_grammar.py       python3 "$CHECKS_DIR/action_grammar.py"
run corpus_window.py        python3 "$CHECKS_DIR/corpus_window.py"
run promote_review_proposals.py python3 "$CHECKS_DIR/../research/promote_review_proposals.py" --check
run admitted_review_proposals.pl swipl -q -l "$CHECKS_DIR/../../paths.pl" -s knowledge/index/admitted_review_proposals.pl -g admitted_review_proposals:check_admitted_review_proposals -t halt
run automaton_input_contracts.py python3 "$CHECKS_DIR/automaton_input_contracts.py"
run strategy_trace_worker_guard.py python3 "$CHECKS_DIR/strategy_trace_worker_guard.py"
run worker_readline_deadline.py python3 "$CHECKS_DIR/worker_readline_deadline.py"
run shared_role_input_decoder.pl swipl -q -l "$CHECKS_DIR/../../paths.pl" -s "$CHECKS_DIR/shared_role_input_decoder.pl" -g main -t halt
run grid_overlays.pl swipl -q -l "$CHECKS_DIR/../../paths.pl" -l "$CHECKS_DIR/grid_overlays.pl" -g grid_overlays_check:main -t halt
run relevance_negation.py   python3 "$CHECKS_DIR/relevance_negation.py"
run lesson_topics_cache.py  python3 "$CHECKS_DIR/lesson_topics_cache.py"
run canonical_phrases.py    python3 "$CHECKS_DIR/canonical_phrases.py"
run utterance_layers.py     python3 "$CHECKS_DIR/utterance_layers.py"
run attested_phrases.py     python3 "$CHECKS_DIR/attested_phrases.py"
run recognition_benchmark.py python3 "$CHECKS_DIR/recognition_benchmark.py"
run too_vague_articulation.py python3 "$CHECKS_DIR/too_vague_articulation.py"
run prolog_repair.py        python3 "$CHECKS_DIR/prolog_repair.py"
run test_mtb_prolog_responder python3 -m unittest discover -s "$CHECKS_DIR/../research" -p "test_mtb_prolog_responder.py" -q
run extract_capability_registry python3 "$CHECKS_DIR/../extract_capability_registry.py" --check
run extract_im_lesson_identity python3 "$CHECKS_DIR/../extract_im_lesson_identity.py" --check
run extract_machine_block_decomposition python3 "$CHECKS_DIR/../extract_machine_block_decomposition.py" --check
run extract_coverage_absence_registry python3 "$CHECKS_DIR/../extract_coverage_absence_registry.py" --check
run extract_research_corpus_misconceptions python3 "$CHECKS_DIR/../extract_research_corpus_misconceptions.py" --check
run a_fortiori_context_closure python3 "$CHECKS_DIR/../extract_a_fortiori_context_closure.py" --check
run a_fortiori_context_closure_selftest python3 "$CHECKS_DIR/../extract_a_fortiori_context_closure.py" --selftest
run a_fortiori_context_nesting_sweep python3 "$CHECKS_DIR/a_fortiori_context_nesting_sweep.py" --check
run a_fortiori_context_closure_automaton_battery swipl -q -l "$CHECKS_DIR/../../paths.pl" -s "$CHECKS_DIR/a_fortiori_context_closure_automaton_battery.pl" -g main -t halt
run extract_task_span_absence_registry python3 "$CHECKS_DIR/../extract_task_span_absence_registry.py" --check
run compile_receipt_routes python3 "$CHECKS_DIR/../curriculum/compile_receipt_routes.py" --check
run action_mapping_docling_reader.py python3 "$CHECKS_DIR/action_mapping_docling_reader.py"
run lesson_task_readings.py python3 "$CHECKS_DIR/lesson_task_readings.py"
run build_sidecar_equation_census python3 "$CHECKS_DIR/../curriculum/build_sidecar_equation_census.py" --check
run equation_verification_sidecar_segmenter.py python3 "$CHECKS_DIR/equation_verification_sidecar_segmenter.py"
run build_equation_verifications python3 "$CHECKS_DIR/../curriculum/build_equation_verifications.py" --check
run equation_verification_witness.py python3 "$CHECKS_DIR/equation_verification_witness.py"
run strategy_task_span_refusal.py python3 "$CHECKS_DIR/strategy_task_span_refusal.py"
run im_defragged_task_instances.py python3 "$CHECKS_DIR/im_defragged_task_instances.py"
run k7_guide_questions.py python3 "$CHECKS_DIR/k7_guide_questions.py"
run assessing_advancing_labels.py python3 "$CHECKS_DIR/assessing_advancing_labels.py"
run admitted_question_stores.py python3 "$CHECKS_DIR/admitted_question_stores.py"
run admitted_question_labels.pl swipl -q -l "$CHECKS_DIR/../../paths.pl" -s curriculum/im/generated/admitted_teacher_question_labels.pl -g admitted_teacher_question_labels:check_admitted_question_labels -t halt
run admitted_guide_questions.pl swipl -q -l "$CHECKS_DIR/../../paths.pl" -s curriculum/im/generated/admitted_guide_questions.pl -g admitted_guide_questions:check_admitted_guide_questions -t halt
run extract_vision_lesson_digest_audit python3 "$CHECKS_DIR/../extract_vision_lesson_digest_audit.py" --check
run self_description_census.py python3 "$CHECKS_DIR/self_description_census.py"
# After the census: the census writes a docs/research report, and the measurement
# registry indexes every report. Checking the registry first reports a staleness
# whose cause is one line further down.
run extract_research_measurement_registry python3 "$CHECKS_DIR/../extract_research_measurement_registry.py" --check
run render_contract.py      python3 "$CHECKS_DIR/render_contract.py"
run check_prebaked.py       python3 "$CHECKS_DIR/../render/check_prebaked.py"
run strict_load.sh          bash "$CHECKS_DIR/strict_load.sh"
run field_context_cache.py  python3 "$CHECKS_DIR/field_context_cache.py"
run monitoring_route_budget.py python3 "$CHECKS_DIR/monitoring_route_budget.py"
run monitoring_chart_client_guard.py python3 "$CHECKS_DIR/monitoring_chart_client_guard.py"
run coordinate_plane_grapher.py python3 "$CHECKS_DIR/coordinate_plane_grapher.py"
run lesson_typesetting.py python3 "$CHECKS_DIR/lesson_typesetting.py"
run lesson_arithmetic_demonstration.pl swipl -q -l "$CHECKS_DIR/../../paths.pl" -s "$CHECKS_DIR/lesson_arithmetic_demonstration.pl" -g main -t halt
run vertical_slice_build1.py python3 "$CHECKS_DIR/vertical_slice_build1.py"
run crosswalk_load.sh       bash "$CHECKS_DIR/crosswalk_load.sh"
run geometry_load.sh        bash "$CHECKS_DIR/geometry_load.sh"
run strict_gate_failures.py python3 "$CHECKS_DIR/strict_gate_failures.py"
run llm_client.py python3 "$CHECKS_DIR/llm_client.py"
run g68_harvest.py python3 "$CHECKS_DIR/g68_harvest.py"
run vision_pass.py python3 "$CHECKS_DIR/vision_pass.py"
run tls_verified_first.py python3 "$CHECKS_DIR/tls_verified_first.py"
run diagnostics_payload.py python3 "$CHECKS_DIR/diagnostics_payload.py"
run workflow_service.py     python3 "$CHECKS_DIR/workflow_service.py"
run drawer_parity.sh        bash "$CHECKS_DIR/drawer_parity.sh"
run zeeman_bifurcation.sh   bash "$CHECKS_DIR/zeeman_bifurcation.sh"
run route_behavior.py       python3 "$CHECKS_DIR/route_behavior.py"
run math_claim_language_check.py python3 "$CHECKS_DIR/math_claim_language_check.py"
run quantity_claim_check.py python3 "$CHECKS_DIR/quantity_claim_check.py"
run pusu_calibration.py     python3 "$CHECKS_DIR/pusu_calibration.py"
run check_agreement_scale.py python3 "$CHECKS_DIR/../language/check_agreement_scale.py"
run check_completion_thesis.py python3 "$CHECKS_DIR/../language/check_completion_thesis.py"
run check_expression_reader.py python3 "$CHECKS_DIR/../language/check_expression_reader.py" --check
run serialized_table_reader.pl swipl -q -l "$CHECKS_DIR/../../paths.pl" -l "$CHECKS_DIR/../../knowledge/strategies/abstraction/serialized_table_reader_pilot.pl" -g serialized_table_reader_pilot:check_serialized_table_reader -t halt
run table_ask_binding.pl swipl -q -l "$CHECKS_DIR/../../paths.pl" -l "$CHECKS_DIR/../../knowledge/strategies/abstraction/table_ask_binding_pilot.pl" -g table_ask_binding_pilot:check_table_ask_binding -t halt
run pusu_sentence_routes.pl swipl -q -l "$CHECKS_DIR/../language/pusu_harness_runner.pl" -g '(pusu_harness_runner:check_expression_routing,pusu_harness_runner:check_serialized_table_routing)' -t halt
run standards_router_pilot.pl swipl -q -l "$CHECKS_DIR/../../paths.pl" -l "$CHECKS_DIR/../../knowledge/strategies/abstraction/standards_router_pilot.pl" -g '(standards_router_pilot:check_standards_router_pilot,standards_router_pilot:check_table_routes)' -t halt
run standards_router_roundtrip.py python3 "$CHECKS_DIR/../language/check_standards_router_roundtrip.py"
run check_pusu_fixes.py python3 "$CHECKS_DIR/../language/check_pusu_fixes.py"
run build_standard_doing.py python3 "$CHECKS_DIR/../language/build_standard_doing.py" --check
run check_standards_bridge.py python3 "$CHECKS_DIR/../language/check_standards_bridge.py" --check
run pusu_schema_translation_fixtures.py python3 "$CHECKS_DIR/../curriculum/pusu_schema_translation_fixtures.py"
run build_standards_progression_overlay python3 "$CHECKS_DIR/../curriculum/build_standards_progression_overlay.py" --check
run standards_progression_overlay.py python3 "$CHECKS_DIR/standards_progression_overlay.py"
run build_im_lesson_capability_census python3 "$CHECKS_DIR/../curriculum/build_im_lesson_capability_census.py" --check
run build_im_zero_candidate_triage python3 "$CHECKS_DIR/../curriculum/build_im_zero_candidate_triage.py" --check
run build_im_action_seam_recut python3 "$CHECKS_DIR/../curriculum/build_im_action_seam_recut.py" --check
run grade8_extraction.py python3 "$CHECKS_DIR/grade8_extraction.py"
# The two row-to-machine maps are tracked stores that the wave-5 mints read.
# The pool map is checked first because the grade 8 map joins its rows to the
# pilot receipts, so a stale pool map would report as a stale grade 8 map.
run build_wave5_row_map python3 "$CHECKS_DIR/../sidekick/build_wave5_row_map.py" --check
run build_g8_row_machine_map python3 "$CHECKS_DIR/../curriculum/build_g8_row_machine_map.py" --check

# The lesson-enactment rung. Each lane's own gate runs first, because a lane
# checks things its own machines know and the contract's gate cannot see: the
# geometry lane re-derives its figure algebra, the measurement lane re-reads
# its spans, the data lane re-reads its citations. The contract gate then reads
# every lane through one vocabulary, and the census runs last, because the
# census counts what the enactors did and a form whose warrant cites a span the
# curriculum does not print must fail before it is counted.
run geometry_enactment.pl swipl -q -l "$CHECKS_DIR/../../paths.pl" -s "$CHECKS_DIR/geometry_enactment.pl" -g main -t halt
run geometry_enactment_warrants.py python3 "$CHECKS_DIR/geometry_enactment_warrants.py"
run measurement_enactment.py python3 "$CHECKS_DIR/measurement_enactment.py"
run data_representation_enactment_citations.pl swipl -q -l "$CHECKS_DIR/../../paths.pl" -s "$CHECKS_DIR/data_representation_enactment_citations.pl" -g check -t halt
run lesson_enactment.pl     swipl -q -l "$CHECKS_DIR/../../paths.pl" -s "$CHECKS_DIR/lesson_enactment.pl" -g main -t halt
run build_im_lesson_enactment_census python3 "$CHECKS_DIR/../curriculum/build_im_lesson_enactment_census.py" --check
# Last on this rung: the counting diagnosis joins the re-cut, the emitted rows,
# and the lane's refusals, so it reads what the census has just checked.
run build_counting_place_value_diagnosis python3 "$CHECKS_DIR/../curriculum/build_counting_place_value_diagnosis.py" --check

run incompatibility_entailment_order python3 "$CHECKS_DIR/../extract_incompatibility_entailment_order.py" --check
run incompatibility_register_runtime_agreement.pl swipl -q -l "$CHECKS_DIR/../../paths.pl" -s "$CHECKS_DIR/incompatibility_register_runtime_agreement.pl" -g main -t halt
run error_rule_incompatibility python3 "$CHECKS_DIR/../extract_error_rule_incompatibility.py" --check
run error_rule_automaton_join.pl swipl -q -l "$CHECKS_DIR/../../paths.pl" -s "$CHECKS_DIR/error_rule_automaton_join.pl" -g main -t halt

# Last: the manifest indexes every data artifact and the readers that open it, so
# it describes the settled state after every other generator has run.
run extract_data_consumption_manifest python3 "$CHECKS_DIR/../extract_data_consumption_manifest.py" --check

if (( ${#FAILED[@]} )); then
    printf 'FAILED %d check(s):\n' "${#FAILED[@]}"
    for index in "${!FAILED[@]}"; do
        printf '  %d. %s\n' "$((index + 1))" "${FAILED[$index]}"
    done
    exit 1
fi

echo "all checks passed"
