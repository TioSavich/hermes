/** <module> Authored lifecycle declarations for fact stores
 *
 * Each store_lifecycle/5 row states how one store enters a consumer path.
 * Each consumption_probe/3 row states the local check for that path. Facts
 * stay on one physical line so the Python wrapper can count them without
 * loading this file.
 */

% store_lifecycle(Store, Lifecycle, Consumer, Since, Note).
% Lifecycle is one of runtime_eager, runtime_lazy, runtime_python,
% build_intermediate, check_only, separate_process, quarantined, third_party,
% or stalled_input.

% consumption_probe(Store, Rung, Spec).
% Rung is one of consumer_goal, check_goal, python_check, producer_consumer,
% not_loaded, eager, or consumer_ref.

store_lifecycle('curriculum/im/docling_figures.pl', runtime_lazy, 'curriculum/im/lesson_monitoring_figures.pl', '2026-08-22', "run-2 hint stale 2026-08-20: sweep_missed; lesson_monitoring_figures loads and queries the figure rows").
store_lifecycle('curriculum/im/enactment/support/data_representation_lessons.pl', runtime_lazy, 'curriculum/im/enactment/data_representation.pl', '2026-08-22', "include-active lesson rows consumed through the data representation enactment module").
store_lifecycle('curriculum/im/generated/compiled_receipt_routes.pl', build_intermediate, 'scripts/curriculum/build_lesson_evidence.py', '2026-08-22', "compile_receipt_routes produces the store and build_lesson_evidence reads it").
store_lifecycle('curriculum/im/generated/grade_1_extracted_guide_questions.pl', check_only, 'scripts/checks/k7_guide_questions.py', '2026-08-22', "run-2 hint stale 2026-08-20: check_only; K-7 check constructs and queries this grade module").
store_lifecycle('curriculum/im/generated/grade_2_extracted_guide_questions.pl', check_only, 'scripts/checks/k7_guide_questions.py', '2026-08-22', "run-2 hint stale 2026-08-20: check_only; K-7 check constructs and queries this grade module").
store_lifecycle('curriculum/im/generated/grade_3_extracted_guide_questions.pl', check_only, 'scripts/checks/k7_guide_questions.py', '2026-08-22', "run-2 hint stale 2026-08-20: check_only; K-7 check constructs and queries this grade module").
store_lifecycle('curriculum/im/generated/grade_4_extracted_guide_questions.pl', check_only, 'scripts/checks/k7_guide_questions.py', '2026-08-22', "run-2 hint stale 2026-08-20: check_only; K-7 check constructs and queries this grade module").
store_lifecycle('curriculum/im/generated/grade_5_extracted_guide_questions.pl', check_only, 'scripts/checks/k7_guide_questions.py', '2026-08-22', "run-2 hint stale 2026-08-20: check_only; K-7 check constructs and queries this grade module").
store_lifecycle('curriculum/im/generated/grade_6_extracted_guide_questions.pl', check_only, 'scripts/checks/k7_guide_questions.py', '2026-08-22', "run-2 hint stale 2026-08-20: check_only; K-7 check constructs and queries this grade module").
store_lifecycle('curriculum/im/generated/grade_7_extracted_guide_questions.pl', check_only, 'scripts/checks/k7_guide_questions.py', '2026-08-22', "run-2 hint stale 2026-08-20: check_only; K-7 check constructs and queries this grade module").
store_lifecycle('curriculum/im/generated/grade_8_extracted_guide_questions.pl', check_only, 'scripts/checks/grade8_extraction.py', '2026-08-22', "run-2 hint stale 2026-08-20: check_only; Grade 8 check queries the generated module").
store_lifecycle('curriculum/im/generated/grade_8_extracted_task_instances.pl', runtime_lazy, 'curriculum/im/generated/compiled_defragged_task_instances.pl', '2026-08-22', "run-2 hint stale 2026-08-20: sweep_missed; defragged task compiler loads the Grade 8 task store").
store_lifecycle('curriculum/im/generated/grade_k_extracted_guide_questions.pl', check_only, 'scripts/checks/k7_guide_questions.py', '2026-08-22', "run-2 hint stale 2026-08-20: check_only; K-7 check constructs and queries this grade module").
store_lifecycle('curriculum/im/generated/lesson_misconception_witness_store.pl', runtime_lazy, 'hermes_worker.pl', '2026-08-22', "generated witness facts are conditionally loaded by lesson_monitoring and served first by lesson_misconception_incompatibility_witness after a full bake").
store_lifecycle('curriculum/im/generated/vision_fraction_recovery.pl', check_only, 'curriculum/im/generated/vision_fraction_recovery.pl', '2026-08-22', "unhinted run-2 row; the run_all entry executes its fact-querying module check").
store_lifecycle('curriculum/im/grind_boundary.pl', runtime_lazy, 'curriculum/im/lesson_monitoring.pl', '2026-08-22', "run-2 hint stale 2026-08-20: sweep_missed; lesson monitoring loads the boundary store").
store_lifecycle('curriculum/im/im_glossary.pl', stalled_input, none_named, '2026-08-22', "run-2 registry orphan; no load or exported-predicate query found outside its own checks and metadata").
store_lifecycle('data/learningcommons/derived/pusu_pass.pl', build_intermediate, 'scripts/sidekick/build_wave5_diagnosis_mint.py', '2026-08-22', "pusu_pass produces the Prolog store and the diagnosis mint reads it").
store_lifecycle('formal/formalization/axioms_geometry.pl', runtime_lazy, 'formal/sequent/sequent_engine.pl', '2026-08-22', "run-2 hint stale 2026-08-20: sweep_missed; sequent_engine loads the geometry axioms").
store_lifecycle('formal/formalization/synthesis/synth_lazy.pl', runtime_lazy, 'formal/formalization/synthesis/run_lazy.pl', '2026-08-22', "run-2 registry orphan; run_lazy loads and calls the lazy synthesis store").
store_lifecycle('formal/incompatibility/error_rule_inferences.pl', runtime_lazy, 'formal/incompatibility/defeasible_inference.pl', '2026-08-22', "run-2 hint stale 2026-08-20: sweep_missed; defeasible_inference includes the error-rule rows used by hyperedge discovery").
store_lifecycle('formal/incompatibility/incompatibility_entailment_order.pl', check_only, 'scripts/checks/incompatibility_register_runtime_agreement.pl', '2026-08-22', "run_all check queries the earned entailment register against the runtime reader").
store_lifecycle('formal/incompatibility/incompatibility_sets_a_fortiori_context_closure.pl', runtime_lazy, 'formal/incompatibility/incompatibility_sets.pl', '2026-08-22', "run-2 hint stale 2026-08-20: sweep_missed; incompatibility_sets consults the context closure").
store_lifecycle('formal/incompatibility/incompatibility_sets_discovered.pl', runtime_lazy, 'formal/incompatibility/incompatibility_sets.pl', '2026-08-22', "run-2 hint stale 2026-08-20: sweep_missed; dynamic cache rows feed incompatibility_set output").
store_lifecycle('formal/incompatibility/incompatibility_sets_error_rules.pl', stalled_input, 'formal/incompatibility/find_emergent_hyperedges.pl', '2026-08-22', "run-2 hint corrected: intended hyperedge consumer does not load this cache or query its predicates").
store_lifecycle('formal/pml/talkmoves_adapter.pl', stalled_input, none_named, '2026-08-22', "run-2 registry orphan; no live loader or exported-predicate query found").
store_lifecycle('formal/tools/axiom_pack_audit.pl', runtime_lazy, 'hermes_worker.pl', '2026-08-22', "run-2 hint stale 2026-08-20: sweep_missed; worker lazy path loads the axiom-pack audit").
store_lifecycle('hermes/math_claim_checker.pl', runtime_lazy, 'hermes/encyclopedia.pl', '2026-08-22', "run-2 hint stale 2026-08-20: sweep_missed; encyclopedia loads the claim checker").
store_lifecycle('hermes/math_context.pl', runtime_lazy, 'hermes/encyclopedia.pl', '2026-08-22', "run-2 hint stale 2026-08-20: sweep_missed; encyclopedia loads and queries math context").
store_lifecycle('knowledge/crosswalk/vocabulary_licenses.pl', stalled_input, 'knowledge/strategies/action_vocabulary_map.pl', '2026-08-22', "mandatory row reclassified: action_vocabulary_map mentions licenses only in prose; no load or query of exported predicates repository-wide").
store_lifecycle('knowledge/discourse/commitment_automata.pl', runtime_lazy, 'scripts/research/build_action_grammar.py', '2026-08-22', "run-2 hint stale 2026-08-20: sweep_missed; action grammar builder parses the discourse table").
store_lifecycle('knowledge/geometry/schema.pl', runtime_lazy, 'curriculum/im/lesson_monitoring.pl', '2026-08-22', "run-2 hint stale 2026-08-20: sweep_missed; lesson monitoring loads geometry schema through its runtime closure").
store_lifecycle('knowledge/geometry/geometry_bridge.pl', quarantined, none_named, '2026-08-22', "standing load constraint; the runtime closure must leave geometry_bridge unloaded").
store_lifecycle('knowledge/index/consumption_attested_run2.pl', check_only, 'scripts/checks/consumption_gate.py', '2026-08-22', "tree drift after run-2; consumption_gate reads the dated attestation rows").
store_lifecycle('knowledge/index/consumption_lifecycle.pl', check_only, 'scripts/checks/consumption_gate.py', '2026-08-22', "tree drift after run-2; consumption_gate reads and validates its authored lifecycle rows").
store_lifecycle('knowledge/index/admitted_review_proposals.pl', runtime_lazy, 'knowledge/index/index_query.pl', '2026-08-22', "tree drift after run-2; index_query serves admitted signature anchors").
store_lifecycle('knowledge/index/coverage_absence_registry.pl', stalled_input, 'scripts/extract_research_measurement_registry.py', '2026-08-22', "byte-identity adjudication: its extractor checks production; the intended registry builder checks path existence but never queries exported predicates").
store_lifecycle('knowledge/index/data_consumption_manifest.pl', stalled_input, 'scripts/research/build_self_description_census.py', '2026-08-22', "run-2 registry orphan; intended self-description surface does not load or query this manifest").
store_lifecycle('knowledge/index/im_lesson_identity.pl', build_intermediate, 'scripts/extract_coverage_absence_registry.py', '2026-08-22', "extract_im_lesson_identity produces the store and coverage absence extraction queries it").
store_lifecycle('knowledge/index/machine_block_decomposition.pl', stalled_input, none_named, '2026-08-22', "run-2 registry orphan; no live loader or exported-predicate query found").
store_lifecycle('knowledge/index/research_measurement_registry.pl', stalled_input, none_named, '2026-08-22', "run-2 registry orphan; no live loader or exported-predicate query found").
store_lifecycle('knowledge/index/task_span_absence_registry.pl', stalled_input, 'knowledge/index/research_measurement_registry.pl', '2026-08-22', "byte-identity adjudication: only its producer checks bytes; intended registry carries path prose but does not load or query exported predicates").
store_lifecycle('knowledge/index/vision_lesson_digest_audit.pl', stalled_input, 'curriculum/im/lesson_monitoring.pl', '2026-08-22', "run-2 registry orphan; intended lesson-monitoring consumer does not load or query exported predicates").
store_lifecycle('knowledge/misconceptions/diagnosis_taxonomy.pl', runtime_lazy, 'knowledge/misconceptions/misconception_registry.pl', '2026-08-22', "run-2 hint stale 2026-08-20: sweep_missed; misconception registry loads the taxonomy").
store_lifecycle('knowledge/misconceptions/literature_canonical_mappings.pl', runtime_lazy, 'curriculum/im/field_context.pl', '2026-08-22', "include-active store; field_context resolves canonical commitment labels through literature_vocabulary").
store_lifecycle('knowledge/misconceptions/misconceptions_geometry.pl', runtime_lazy, 'knowledge/misconceptions/misconception_registry.pl', '2026-08-22', "run-2 hint stale 2026-08-20: sweep_missed; misconception registry loads the geometry module").
store_lifecycle('knowledge/misconceptions/monitoring_registry_bridge.pl', runtime_lazy, 'knowledge/strategies/abstraction/g8_right_triangle_side.pl', '2026-08-22', "run-2 hint stale 2026-08-20: sweep_missed; the right-triangle adapter loads and queries the monitoring bridge").
store_lifecycle('knowledge/misconceptions/research_corpus_automaton_bindings.pl', stalled_input, 'formal/learner/reorg_domains/whole_number_operations.pl', '2026-08-22', "controller adjudication: intended consumer names the store only in prose; no load or query of either exported predicate repository-wide").
store_lifecycle('knowledge/standards/standard_doing.pl', build_intermediate, 'scripts/language/check_standards_bridge.py', '2026-08-22', "build_standard_doing produces the store and the standards bridge check reads it").
store_lifecycle('knowledge/strategies/abstraction/addition_action_signatures.pl', check_only, 'scripts/checks/deformation_validity.py', '2026-08-22', "run-2 hint stale 2026-08-20: check_only; deformation validity check parses the addition ledger").
store_lifecycle('knowledge/strategies/abstraction/ape_reader_pilot.pl', runtime_lazy, 'scripts/language/pusu_harness_runner.pl', '2026-08-22', "run-2 hint stale 2026-08-20: build_intermediate; live PUSU runner loads and queries this authored reader").
store_lifecycle('knowledge/strategies/abstraction/g8_circle_and_solid_dimensions.pl', quarantined, none_named, '2026-08-22', "CLAUDE quarantine ruling: unattested G8 pilot remains outside the runtime closure").
store_lifecycle('knowledge/strategies/abstraction/g8_decimal_fraction_form.pl', quarantined, none_named, '2026-08-22', "CLAUDE quarantine ruling: unattested G8 pilot remains outside the runtime closure").
store_lifecycle('knowledge/strategies/abstraction/g8_exponent_expression_equivalence.pl', quarantined, none_named, '2026-08-22', "CLAUDE quarantine ruling: unattested G8 pilot remains outside the runtime closure").
store_lifecycle('knowledge/strategies/abstraction/g8_linear_equation_reading_and_authoring.pl', quarantined, none_named, '2026-08-22', "CLAUDE quarantine ruling: unattested G8 pilot remains outside the runtime closure").
store_lifecycle('knowledge/strategies/abstraction/g8_linear_expression_normalizer.pl', quarantined, none_named, '2026-08-22', "CLAUDE quarantine ruling: unattested G8 pilot remains outside the runtime closure").
store_lifecycle('knowledge/strategies/abstraction/g8_power_of_ten_alignment.pl', quarantined, none_named, '2026-08-22', "CLAUDE quarantine ruling: unattested G8 pilot remains outside the runtime closure").
store_lifecycle('knowledge/strategies/abstraction/g8_scaled_copy_and_similar_sides.pl', quarantined, none_named, '2026-08-22', "CLAUDE quarantine ruling: unattested G8 pilot remains outside the runtime closure").
store_lifecycle('knowledge/strategies/abstraction/k7_array_grid.pl', quarantined, none_named, '2026-08-22', "CLAUDE quarantine ruling: K-7 scene-emission sibling remains outside the runtime closure").
store_lifecycle('knowledge/strategies/abstraction/k7_equal_share_bars.pl', quarantined, none_named, '2026-08-22', "CLAUDE quarantine ruling: K-7 scene-emission sibling remains outside the runtime closure").
store_lifecycle('knowledge/strategies/abstraction/k7_fraction_number_line.pl', quarantined, none_named, '2026-08-22', "CLAUDE quarantine ruling: K-7 scene-emission sibling remains outside the runtime closure").
store_lifecycle('knowledge/strategies/abstraction/k7_number_line_hops.pl', quarantined, none_named, '2026-08-22', "CLAUDE quarantine ruling: K-7 scene-emission sibling remains outside the runtime closure").
store_lifecycle('knowledge/strategies/abstraction/lexicon_supplement_pilot.pl', runtime_lazy, 'scripts/language/consultation_scan.pl', '2026-08-22', "run-2 build hint corrected: authored supplement is queried by consultation_scan; no producer exists").
store_lifecycle('knowledge/strategies/abstraction/math_lexicon_pilot.pl', build_intermediate, 'scripts/language/consultation_scan.pl', '2026-08-22', "build_math_lexicon produces the store and consultation_scan queries ml_word").
store_lifecycle('knowledge/strategies/abstraction/metaphor_seam_registry.pl', check_only, 'scripts/checks/metaphor_seam_registry.py', '2026-08-22', "run-2 hint stale 2026-08-20: check_only; Python check parses the registry rows").
store_lifecycle('knowledge/strategies/abstraction/pedagogy_force_pilot.pl', runtime_lazy, 'scripts/language/pusu_harness_runner.pl', '2026-08-22', "run-2 build hint corrected: PUSU runner queries the authored force store but cannot be loaded after the shared paths file").
store_lifecycle('knowledge/strategies/abstraction/printed_expression_reader_pilot.pl', runtime_lazy, 'scripts/language/pusu_harness_runner.pl', '2026-08-22', "run-2 build hint corrected: authored expression reader is queried by the PUSU runner").
store_lifecycle('knowledge/strategies/abstraction/question_move_pilot.pl', runtime_lazy, 'hermes/dispatch_spec.pl', '2026-08-22', "live-tree correction: dispatch_spec loads the admitted store and serves question_moves through question_moves_dict").
store_lifecycle('knowledge/strategies/abstraction/rewrite_consultation_admitted_pilot.pl', stalled_input, 'scripts/language/rewrite_consultation.py', '2026-08-22', "admitted-by-ceremony registry orphan; intended consultation path does not load or query exported predicates").
store_lifecycle('knowledge/strategies/abstraction/standards_router_pilot.pl', stalled_input, 'knowledge/strategies/math/statistics_action_pairs.pl', '2026-08-22', "run-2 lexical hint was measurement_unit only; intended consumer does not load the store or query exported predicates").
store_lifecycle('knowledge/strategies/abstraction/task_pattern_pilot.pl', quarantined, none_named, '2026-08-22', "CLAUDE quarantine ruling: task-pattern store remains outside the runtime closure").
store_lifecycle('knowledge/strategies/abstraction/word_problem_reader_pilot.pl', runtime_lazy, 'scripts/language/pusu_harness_runner.pl', '2026-08-22', "run-2 build hint corrected: authored word-problem reader is queried by the PUSU runner").
store_lifecycle('knowledge/strategies/action_grammar.pl', build_intermediate, 'scripts/research/build_corpus_window.py', '2026-08-22', "build_action_grammar produces the store and build_corpus_window reads it").
store_lifecycle('knowledge/strategies/deformation_coincidence.pl', runtime_lazy, 'knowledge/strategies/automaton_input_contracts.pl', '2026-08-22', "run-2 hint stale 2026-08-20: sweep_missed; input contracts load the coincidence profiles").
store_lifecycle('knowledge/strategies/deformation_validity.pl', check_only, 'scripts/checks/deformation_validity.py', '2026-08-22', "run-2 build hint corrected: authored ledger is parsed by its run_all check").
store_lifecycle('knowledge/strategies/machine_typology.pl', build_intermediate, 'scripts/sidekick/wave5_diagnosis_runner.pl', '2026-08-22', "build_machine_typology produces the store and the diagnosis runner consults it").
store_lifecycle('knowledge/strategies/render/authored_render_citations.pl', runtime_python, 'scripts/research/build_misconception_render_link.py', '2026-08-22', "the render-link builder reads every authored verdict; its run_all check regenerates and re-derives the consumed links and refusals").
store_lifecycle('knowledge/strategies/render/misconception_render_link.pl', check_only, 'scripts/checks/misconception_render_link.py', '2026-08-22', "tree drift after run-2; Python check queries the generated render-link module").
store_lifecycle('knowledge/strategies/transition_tables/addition.pl', runtime_lazy, 'hermes/strategy_recognizer.pl', '2026-08-22', "include-active transition table consumed through observed_strategy").
store_lifecycle('knowledge/strategies/transition_tables/algebraic.pl', runtime_lazy, 'hermes/strategy_recognizer.pl', '2026-08-22', "include-active transition table consumed through observed_strategy").
store_lifecycle('knowledge/strategies/transition_tables/calculus.pl', runtime_lazy, 'hermes/strategy_recognizer.pl', '2026-08-22', "include-active transition table consumed through observed_strategy").
store_lifecycle('knowledge/strategies/transition_tables/counting.pl', runtime_lazy, 'hermes/strategy_recognizer.pl', '2026-08-22', "include-active transition table consumed through observed_strategy").
store_lifecycle('knowledge/strategies/transition_tables/decimal.pl', runtime_lazy, 'hermes/strategy_recognizer.pl', '2026-08-22', "include-active transition table consumed through observed_strategy").
store_lifecycle('knowledge/strategies/transition_tables/division.pl', runtime_lazy, 'hermes/strategy_recognizer.pl', '2026-08-22', "include-active transition table consumed through observed_strategy").
store_lifecycle('knowledge/strategies/transition_tables/fraction.pl', runtime_lazy, 'hermes/strategy_recognizer.pl', '2026-08-22', "include-active transition table consumed through observed_strategy").
store_lifecycle('knowledge/strategies/transition_tables/geometry.pl', runtime_lazy, 'hermes/strategy_recognizer.pl', '2026-08-22', "include-active transition table consumed through observed_strategy").
store_lifecycle('knowledge/strategies/transition_tables/integer.pl', runtime_lazy, 'hermes/strategy_recognizer.pl', '2026-08-22', "include-active transition table consumed through observed_strategy").
store_lifecycle('knowledge/strategies/transition_tables/measurement.pl', runtime_lazy, 'hermes/strategy_recognizer.pl', '2026-08-22', "include-active transition table consumed through observed_strategy").
store_lifecycle('knowledge/strategies/transition_tables/multiplication.pl', runtime_lazy, 'hermes/strategy_recognizer.pl', '2026-08-22', "include-active transition table consumed through observed_strategy").
store_lifecycle('knowledge/strategies/transition_tables/probability.pl', runtime_lazy, 'hermes/strategy_recognizer.pl', '2026-08-22', "include-active transition table consumed through observed_strategy").
store_lifecycle('knowledge/strategies/transition_tables/ratio.pl', runtime_lazy, 'hermes/strategy_recognizer.pl', '2026-08-22', "include-active transition table consumed through observed_strategy").
store_lifecycle('knowledge/strategies/transition_tables/statistics.pl', runtime_lazy, 'hermes/strategy_recognizer.pl', '2026-08-22', "include-active transition table consumed through observed_strategy").
store_lifecycle('knowledge/strategies/transition_tables/subtraction.pl', runtime_lazy, 'hermes/strategy_recognizer.pl', '2026-08-22', "include-active transition table consumed through observed_strategy").

consumption_probe('curriculum/im/docling_figures.pl', consumer_ref, ref(include_active)).
consumption_probe('curriculum/im/enactment/support/data_representation_lessons.pl', consumer_goal, probe(load('curriculum/im/enactment/data_representation.pl'), store_fact('curriculum/im/enactment/support/data_representation_lessons.pl', data_representation_enactment:lane_lesson(Lesson, _Grade, _Source)), data_representation_enactment:lesson_enactment_form(Lesson, Form, _Evidence), nonvar(Form))).
consumption_probe('curriculum/im/generated/compiled_receipt_routes.pl', producer_consumer, scripts('scripts/curriculum/compile_receipt_routes.py', 'scripts/curriculum/build_lesson_evidence.py')).
consumption_probe('curriculum/im/generated/grade_1_extracted_guide_questions.pl', python_check, check('k7_guide_questions.py')).
consumption_probe('curriculum/im/generated/grade_2_extracted_guide_questions.pl', python_check, check('k7_guide_questions.py')).
consumption_probe('curriculum/im/generated/grade_3_extracted_guide_questions.pl', python_check, check('k7_guide_questions.py')).
consumption_probe('curriculum/im/generated/grade_4_extracted_guide_questions.pl', python_check, check('k7_guide_questions.py')).
consumption_probe('curriculum/im/generated/grade_5_extracted_guide_questions.pl', python_check, check('k7_guide_questions.py')).
consumption_probe('curriculum/im/generated/grade_6_extracted_guide_questions.pl', python_check, check('k7_guide_questions.py')).
consumption_probe('curriculum/im/generated/grade_7_extracted_guide_questions.pl', python_check, check('k7_guide_questions.py')).
consumption_probe('curriculum/im/generated/grade_8_extracted_guide_questions.pl', python_check, check('grade8_extraction.py')).
consumption_probe('curriculum/im/generated/grade_8_extracted_task_instances.pl', consumer_ref, ref(include_active)).
consumption_probe('curriculum/im/generated/grade_k_extracted_guide_questions.pl', python_check, check('k7_guide_questions.py')).
consumption_probe('curriculum/im/generated/lesson_misconception_witness_store.pl', consumer_goal, probe(none, store_fact('curriculum/im/generated/lesson_misconception_witness_store.pl', lesson_monitoring:lesson_misconception_witness_fact(Code, Operation, Name, _StoredWitness)), user:lesson_misconception_incompatibility_witness(Code, Operation, Name, Witness), nonvar(Witness))).
consumption_probe('curriculum/im/generated/vision_fraction_recovery.pl', check_goal, check('vision_fraction_recovery.pl', vision_fraction_recovery:check_vision_fraction_recovery)).
consumption_probe('curriculum/im/grind_boundary.pl', consumer_ref, ref(include_active)).
consumption_probe('data/learningcommons/derived/pusu_pass.pl', producer_consumer, scripts('scripts/curriculum/pusu_pass.py', 'scripts/sidekick/build_wave5_diagnosis_mint.py')).
consumption_probe('formal/formalization/axioms_geometry.pl', consumer_ref, ref(include_active)).
consumption_probe('formal/formalization/synthesis/synth_lazy.pl', consumer_ref, ref(no_callable_entry)).
consumption_probe('formal/incompatibility/error_rule_inferences.pl', consumer_ref, ref(include_active)).
consumption_probe('formal/incompatibility/incompatibility_entailment_order.pl', check_goal, check('incompatibility_register_runtime_agreement.pl', consumption_gate_check:main)).
consumption_probe('formal/incompatibility/incompatibility_sets_a_fortiori_context_closure.pl', consumer_ref, ref(include_active)).
consumption_probe('formal/incompatibility/incompatibility_sets_discovered.pl', consumer_goal, probe(load('formal/incompatibility/incompatibility_sets.pl'), store_fact('formal/incompatibility/incompatibility_sets_discovered.pl', incompatibility_sets:discovered_set_fact(Context, Set)), incompatibility_sets:incompatibility_set(Context, set(discovered, Set)), nonvar(Set))).
consumption_probe('formal/tools/axiom_pack_audit.pl', consumer_ref, ref(no_callable_entry)).
consumption_probe('hermes/math_claim_checker.pl', consumer_ref, ref(no_callable_entry)).
consumption_probe('hermes/math_context.pl', consumer_ref, ref(no_callable_entry)).
consumption_probe('knowledge/discourse/commitment_automata.pl', consumer_ref, ref(python_reader)).
consumption_probe('knowledge/geometry/schema.pl', consumer_ref, ref(include_active)).
consumption_probe('knowledge/geometry/geometry_bridge.pl', not_loaded, none).
consumption_probe('knowledge/index/consumption_attested_run2.pl', python_check, check('consumption_gate.py')).
consumption_probe('knowledge/index/consumption_lifecycle.pl', python_check, check('consumption_gate.py')).
consumption_probe('knowledge/index/admitted_review_proposals.pl', consumer_goal, probe(load('knowledge/index/index_query.pl'), store_fact('knowledge/index/admitted_review_proposals.pl', admitted_review_proposals:admitted_signature_anchor(Family, Signature, _RowType, _RowId, _Role, _Evidence, _Anchor, _Testimony, _Receipt)), index_query:signature_anchors_dict(Family, Signature, Dict), nonvar(Dict))).
consumption_probe('knowledge/index/im_lesson_identity.pl', producer_consumer, scripts('scripts/extract_im_lesson_identity.py', 'scripts/extract_coverage_absence_registry.py')).
consumption_probe('knowledge/misconceptions/diagnosis_taxonomy.pl', consumer_ref, ref(include_active)).
consumption_probe('knowledge/misconceptions/literature_canonical_mappings.pl', consumer_goal, probe(load('curriculum/im/field_context.pl'), store_fact('knowledge/misconceptions/literature_canonical_mappings.pl', literature_vocabulary:canonical_commitment(Key, _Label)), field_context:canonical_commitment_label(Key, Row), nonempty(Row))).
consumption_probe('knowledge/misconceptions/misconceptions_geometry.pl', consumer_ref, ref(include_active)).
consumption_probe('knowledge/misconceptions/monitoring_registry_bridge.pl', consumer_ref, ref(include_active)).
consumption_probe('knowledge/standards/standard_doing.pl', producer_consumer, scripts('scripts/language/build_standard_doing.py', 'scripts/language/check_standards_bridge.py')).
consumption_probe('knowledge/strategies/abstraction/addition_action_signatures.pl', python_check, check('deformation_validity.py')).
consumption_probe('knowledge/strategies/abstraction/ape_reader_pilot.pl', consumer_ref, ref(no_callable_entry)).
consumption_probe('knowledge/strategies/abstraction/g8_circle_and_solid_dimensions.pl', not_loaded, none).
consumption_probe('knowledge/strategies/abstraction/g8_decimal_fraction_form.pl', not_loaded, none).
consumption_probe('knowledge/strategies/abstraction/g8_exponent_expression_equivalence.pl', not_loaded, none).
consumption_probe('knowledge/strategies/abstraction/g8_linear_equation_reading_and_authoring.pl', not_loaded, none).
consumption_probe('knowledge/strategies/abstraction/g8_linear_expression_normalizer.pl', not_loaded, none).
consumption_probe('knowledge/strategies/abstraction/g8_power_of_ten_alignment.pl', not_loaded, none).
consumption_probe('knowledge/strategies/abstraction/g8_scaled_copy_and_similar_sides.pl', not_loaded, none).
consumption_probe('knowledge/strategies/abstraction/k7_array_grid.pl', not_loaded, none).
consumption_probe('knowledge/strategies/abstraction/k7_equal_share_bars.pl', not_loaded, none).
consumption_probe('knowledge/strategies/abstraction/k7_fraction_number_line.pl', not_loaded, none).
consumption_probe('knowledge/strategies/abstraction/k7_number_line_hops.pl', not_loaded, none).
consumption_probe('knowledge/strategies/abstraction/lexicon_supplement_pilot.pl', consumer_goal, probe(load('scripts/language/consultation_scan.pl'), store_fact('knowledge/strategies/abstraction/lexicon_supplement_pilot.pl', lexicon_supplement_pilot:ls_word(Token, _Class, _Forms, _Evidence, _Note)), consultation_scan:token_source(Token, Source), contains(Source, "supplement"))).
consumption_probe('knowledge/strategies/abstraction/math_lexicon_pilot.pl', producer_consumer, scripts('scripts/language/build_math_lexicon.py', 'scripts/language/consultation_scan.pl')).
consumption_probe('knowledge/strategies/abstraction/metaphor_seam_registry.pl', python_check, check('metaphor_seam_registry.py')).
consumption_probe('knowledge/strategies/abstraction/pedagogy_force_pilot.pl', consumer_ref, ref(no_callable_entry)).
consumption_probe('knowledge/strategies/abstraction/printed_expression_reader_pilot.pl', consumer_ref, ref(no_callable_entry)).
consumption_probe('knowledge/strategies/abstraction/question_move_pilot.pl', consumer_goal, probe(none, store_fact('knowledge/strategies/abstraction/question_move_pilot.pl', question_move_pilot:question_move(_Id, _From, _Type, _Template, _Effect, _To, evidence([q_ref(Lesson, _Span, _Sentence)]), _Review, _Verification)), question_move_pilot:question_moves_dict(Lesson, 1, Dict), nonvar(Dict))).
consumption_probe('knowledge/strategies/abstraction/task_pattern_pilot.pl', not_loaded, none).
consumption_probe('knowledge/strategies/abstraction/word_problem_reader_pilot.pl', consumer_ref, ref(no_callable_entry)).
consumption_probe('knowledge/strategies/action_grammar.pl', producer_consumer, scripts('scripts/research/build_action_grammar.py', 'scripts/research/build_corpus_window.py')).
consumption_probe('knowledge/strategies/deformation_coincidence.pl', consumer_ref, ref(include_active)).
consumption_probe('knowledge/strategies/deformation_validity.pl', python_check, check('deformation_validity.py')).
consumption_probe('knowledge/strategies/machine_typology.pl', producer_consumer, scripts('scripts/research/build_machine_typology.py', 'scripts/sidekick/wave5_diagnosis_runner.pl')).
consumption_probe('knowledge/strategies/render/authored_render_citations.pl', python_check, check('misconception_render_link.py')).
consumption_probe('knowledge/strategies/render/misconception_render_link.pl', python_check, check('misconception_render_link.py')).
consumption_probe('knowledge/strategies/transition_tables/addition.pl', consumer_goal, probe(load('hermes/strategy_recognizer.pl'), store_fact('knowledge/strategies/transition_tables/addition.pl', strategy_recognizer:automaton_transition(Family, Signature, _Before, _Action, _After, provenance(observed(contract_example)))), strategy_recognizer:observed_strategy(Family, Signature, Actions), nonempty(Actions))).
consumption_probe('knowledge/strategies/transition_tables/algebraic.pl', consumer_goal, probe(load('hermes/strategy_recognizer.pl'), store_fact('knowledge/strategies/transition_tables/algebraic.pl', strategy_recognizer:automaton_transition(Family, Signature, _Before, _Action, _After, provenance(observed(contract_example)))), strategy_recognizer:observed_strategy(Family, Signature, Actions), nonempty(Actions))).
consumption_probe('knowledge/strategies/transition_tables/calculus.pl', consumer_goal, probe(load('hermes/strategy_recognizer.pl'), store_fact('knowledge/strategies/transition_tables/calculus.pl', strategy_recognizer:automaton_transition(Family, Signature, _Before, _Action, _After, provenance(observed(contract_example)))), strategy_recognizer:observed_strategy(Family, Signature, Actions), nonempty(Actions))).
consumption_probe('knowledge/strategies/transition_tables/counting.pl', consumer_goal, probe(load('hermes/strategy_recognizer.pl'), store_fact('knowledge/strategies/transition_tables/counting.pl', strategy_recognizer:automaton_transition(Family, Signature, _Before, _Action, _After, provenance(observed(contract_example)))), strategy_recognizer:observed_strategy(Family, Signature, Actions), nonempty(Actions))).
consumption_probe('knowledge/strategies/transition_tables/decimal.pl', consumer_goal, probe(load('hermes/strategy_recognizer.pl'), store_fact('knowledge/strategies/transition_tables/decimal.pl', strategy_recognizer:automaton_transition(Family, Signature, _Before, _Action, _After, provenance(observed(contract_example)))), strategy_recognizer:observed_strategy(Family, Signature, Actions), nonempty(Actions))).
consumption_probe('knowledge/strategies/transition_tables/division.pl', consumer_goal, probe(load('hermes/strategy_recognizer.pl'), store_fact('knowledge/strategies/transition_tables/division.pl', strategy_recognizer:automaton_transition(Family, Signature, _Before, _Action, _After, provenance(observed(contract_example)))), strategy_recognizer:observed_strategy(Family, Signature, Actions), nonempty(Actions))).
consumption_probe('knowledge/strategies/transition_tables/fraction.pl', consumer_goal, probe(load('hermes/strategy_recognizer.pl'), store_fact('knowledge/strategies/transition_tables/fraction.pl', strategy_recognizer:automaton_transition(Family, Signature, _Before, _Action, _After, provenance(observed(contract_example)))), strategy_recognizer:observed_strategy(Family, Signature, Actions), nonempty(Actions))).
consumption_probe('knowledge/strategies/transition_tables/geometry.pl', consumer_goal, probe(load('hermes/strategy_recognizer.pl'), store_fact('knowledge/strategies/transition_tables/geometry.pl', strategy_recognizer:automaton_transition(Family, Signature, _Before, _Action, _After, provenance(observed(contract_example)))), strategy_recognizer:observed_strategy(Family, Signature, Actions), nonempty(Actions))).
consumption_probe('knowledge/strategies/transition_tables/integer.pl', consumer_goal, probe(load('hermes/strategy_recognizer.pl'), store_fact('knowledge/strategies/transition_tables/integer.pl', strategy_recognizer:automaton_transition(Family, Signature, _Before, _Action, _After, provenance(observed(contract_example)))), strategy_recognizer:observed_strategy(Family, Signature, Actions), nonempty(Actions))).
consumption_probe('knowledge/strategies/transition_tables/measurement.pl', consumer_goal, probe(load('hermes/strategy_recognizer.pl'), store_fact('knowledge/strategies/transition_tables/measurement.pl', strategy_recognizer:automaton_transition(Family, Signature, _Before, _Action, _After, provenance(observed(contract_example)))), strategy_recognizer:observed_strategy(Family, Signature, Actions), nonempty(Actions))).
consumption_probe('knowledge/strategies/transition_tables/multiplication.pl', consumer_goal, probe(load('hermes/strategy_recognizer.pl'), store_fact('knowledge/strategies/transition_tables/multiplication.pl', strategy_recognizer:automaton_transition(Family, Signature, _Before, _Action, _After, provenance(observed(contract_example)))), strategy_recognizer:observed_strategy(Family, Signature, Actions), nonempty(Actions))).
consumption_probe('knowledge/strategies/transition_tables/probability.pl', consumer_goal, probe(load('hermes/strategy_recognizer.pl'), store_fact('knowledge/strategies/transition_tables/probability.pl', strategy_recognizer:automaton_transition(Family, Signature, _Before, _Action, _After, provenance(observed(contract_example)))), strategy_recognizer:observed_strategy(Family, Signature, Actions), nonempty(Actions))).
consumption_probe('knowledge/strategies/transition_tables/ratio.pl', consumer_goal, probe(load('hermes/strategy_recognizer.pl'), store_fact('knowledge/strategies/transition_tables/ratio.pl', strategy_recognizer:automaton_transition(Family, Signature, _Before, _Action, _After, provenance(observed(contract_example)))), strategy_recognizer:observed_strategy(Family, Signature, Actions), nonempty(Actions))).
consumption_probe('knowledge/strategies/transition_tables/statistics.pl', consumer_goal, probe(load('hermes/strategy_recognizer.pl'), store_fact('knowledge/strategies/transition_tables/statistics.pl', strategy_recognizer:automaton_transition(Family, Signature, _Before, _Action, _After, provenance(observed(contract_example)))), strategy_recognizer:observed_strategy(Family, Signature, Actions), nonempty(Actions))).
consumption_probe('knowledge/strategies/transition_tables/subtraction.pl', consumer_goal, probe(load('hermes/strategy_recognizer.pl'), store_fact('knowledge/strategies/transition_tables/subtraction.pl', strategy_recognizer:automaton_transition(Family, Signature, _Before, _Action, _After, provenance(observed(contract_example)))), strategy_recognizer:observed_strategy(Family, Signature, Actions), nonempty(Actions))).
