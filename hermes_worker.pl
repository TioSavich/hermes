% hermes_worker.pl — local JSONL worker for Hermes.
%
% Protocol:
%   {"id":"req_1","op":"health"}
%   {"id":"req_2","op":"event_score","event":{...}}
%   {"id":"req_3","op":"batch_event_score","events":[...]}
%   {"id":"req_4","op":"pair_score","events":[...]}
%   {"id":"req_5","op":"pair_graph","events":[...]}
%   {"id":"req_6","op":"pair_candidate_witness","event_a":{...},"event_b":{...}}
%   {"id":"req_7","op":"diagnose_error","domain":"fraction","input":...,"got":...}
%   {"id":"req_8","op":"query_misconception","domain":"fraction","description":...}
%   {"id":"req_9","op":"discourse_features","utterances":[...],"context":{...}}
%   {"id":"req_10","op":"discourse_pragmatics","utterances":[...],"context":{...}}
%   {"id":"req_11","op":"trace_adjudication","utterances":[...],"context":{...},"ledger":{...}}
%   {"id":"req_12","op":"media_alignment","segments":[...],"source":"..."}
%   {"id":"req_13","op":"gesture_alignment","utterances":[...],"context":{...},"observations":[...]}
%
% One JSON object in, one JSON object out. Human-readable diagnostics go to
% stderr only.

:- use_module(library(http/json)).
:- use_module(library(readutil)).

:- op(500, fx, comp_nec).
:- op(500, fx, exp_nec).
:- op(500, fx, exp_poss).
:- op(500, fx, comp_poss).
:- op(500, fx, neg).

:- dynamic worker_root/1.
:- discontiguous dispatch_request/4.
:- prolog_load_context(directory, Dir),
   asserta(worker_root(Dir)).

worker_main :-
    catch(with_output_to(user_error, load_runtime), E, worker_fatal(E)),
    worker_loop.

load_runtime :-
    (   worker_root(Root)
    ->  true
    ;   Root = '.'
    ),
    directory_file_path(Root, 'paths.pl', PathsFile),
    (   exists_file(PathsFile)
    ->  consult(PathsFile)
    ;   % Fallback to UMEDCTA_ROOT environment variable if loaded from elsewhere
        (   getenv('UMEDCTA_ROOT', Root0)
        ->  atom_string(RootEnv, Root0),
            directory_file_path(RootEnv, 'paths.pl', RootPathsFile),
            consult(RootPathsFile)
        ;   throw(error(missing_paths_file(PathsFile), load_runtime/0))
        )
    ),
    use_module(hermes(event_scoring)),
    use_module(hermes(pair_scoring)),
    load_geometry_runtime(Root),
    use_module(im_lessons(lesson_monitoring)),
    use_module(im_lessons(lesson_monitoring_selector), []),
    use_module(im_lessons(field_context)),
    use_module(strategies(expressive_power)),
    use_module(strategies(visualization), []),
    use_module(render(fraction_bars_scene)),
    use_module(render(balance_scale_scene)),
    use_module(render(misconception_render_coverage), []),
    use_module(formalization(grounded_arithmetic),
               [ integer_to_recollection/2,
                 recollection_to_integer/2 ]),
    use_module(misconceptions(test_harness)),
    use_module(misconceptions(misconception_registry)),
    use_module(misconceptions(pml_wire), []),
    use_module(learner(deontic_scorekeeper)),
    use_module(learner(up_leveling)),
    use_module(formalization(grounding_metaphors)),
    use_module(pml(semantic_axioms)),
    use_module(pml(intersubjective_praxis)),
    use_module(pml(mua_relations)),
    use_module(pml(media_alignment), []),
    use_module(pml(gesture_alignment), []),
    use_module(pml(discourse_features), []),
    use_module(pml(discourse_pragmatics), []),
    use_module(pml(trace_adjudication), []),
    use_module(hermes(encyclopedia)),
    use_module(hermes(commitment_matcher), []),
    use_module(hermes(capability_registry), []),
    use_module(arche_trace(embodied_prover), []),
    use_module(arche_trace(sequent_engine), []),
    use_module(arche_trace(critique)),
    use_module(arche_trace(defeasible_inference), []),
    use_module(arche_trace(incompatibility_discovery)),
    use_module(arche_trace(incompatibility_sets), []),
    % The Brandomian incompatibility bridge. Selective import: only the union
    % incoherence front end and the backstop audit, to avoid the
    % incompatibility_entails/2 and => operator clashes the full module carries.
    % Loading it HERE is the opt-in the bridge's design asks for: the sequent
    % engine's own default behavior is unchanged, and the union incoherence plus
    % the canonical incompatibility_entails/2 are consulted at this app boundary
    % only (the brandomian_check op), never inside the engine.
    use_module(arche_trace(sequent_brandom_bridge),
               [ brandom_backstop/1, brandom_backstop_ok/0,
                 b_proves/1, b_incoherent/1 ]),
    load_axiom_pack_audit(Root),
    use_module(hermes(dispatch_spec),
               [ dispatch_spec/4, dispatch_message/3 ]),
    validate_dispatch_spec,
    use_module(crosswalk(canonical_all), []),
    % T0 representation spine: concept -> visual surface routing + manifest assets.
    use_module(crosswalk(representation_spine), []),
    use_module(standards(indiana/standard_k_ca_1_3), []),
    use_module(standards(indiana/standard_k_ns_1), []),
    use_module(standards(indiana/standard_k_ns_2), []),
    use_module(standards(indiana/standard_k_ns_3), []),
    use_module(standards(indiana/standard_k_ns_4), []),
    use_module(standards(indiana/standard_k_ns_5_6), []),
    use_module(standards(indiana/standard_k_ns_7), []),
    use_module(standards(indiana/standard_1_ns_1), []),
    use_module(standards(indiana/standard_1_ns_2), []),
    use_module(standards(indiana/standard_1_ca_1), []),
    use_module(standards(indiana/standard_1_ca_3), []),
    use_module(standards(indiana/standard_2_ca_2), []),
    use_module(standards(indiana/standard_2_ns_1), []),
    use_module(standards(indiana/standard_2_ns_2_4), []),
    use_module(standards(indiana/standard_2_ns_3), []),
    use_module(standards(indiana/standard_2_ns_5), []),
    use_module(standards(indiana/standard_3_ca_3_4), []),
    use_module(standards(indiana/standard_3_ca_5), []),
    use_module(standards(indiana/standard_3_ns_2), []),
    use_module(standards(indiana/standard_3_ns_5), []),
    % Render scene compilers for the visualization ops (Goal H). Loaded last and
    % import-free ([]): every dispatch clause calls them by explicit
    % module:pred qualification, so nothing is imported into `user`, and loading
    % after the base vocabulary layer avoids re-importing predicates the cw
    % families already settled.
    use_module(render(area_model_scene), []),
    use_module(render(base_ten_scene), []),
    use_module(render(set_grouping_scene), []),
    use_module(render(number_line_scene), []),
    use_module(render(unit_echo_scene), []),
    use_module(render(place_value_chart_scene), []),
    use_module(render(hybridization_scene), []),
    use_module(render(rigid_motion_scene), []),
    use_module(render(representation_grammar), []),
    % The corpus-attested grammar layer: which grammar objects/uses the student
    % corpus actually witnesses, and where the grammar runs ahead of the corpus.
    % Import-free; the dispatch clause qualifies calls by module:pred.
    use_module(render(corpus_attested_grammar), []),
    use_module(render(grounding_to_primitive), []),
    use_module(render(teacher_layer), []),
    % Notation glyph-level scenes, fraction->CGI numerator dispatch, the
    % parametric deformation chart, and the carving proof surface. Loaded
    % import-free ([]): every dispatch clause below qualifies them by
    % explicit module:pred, so nothing is imported into `user` and the
    % lesson_deformation_chart monitoring_chart/2 export cannot collide with
    % the lesson_monitoring monitoring_chart/2 already imported above.
    use_module(render(notation_scene), []),
    use_module(math(fraction_cgi_dispatch), []),
    use_module(im_lessons(lesson_deformation_chart), []),
    % The notation monitoring chart (183 K/G1 lessons). Import-free for the same
    % reason as lesson_deformation_chart: its monitoring_chart_*/N predicates
    % must not collide with the lesson_monitoring exports imported above.
    use_module(im_lessons(lesson_notation_chart), []),
    % The elaboration-graph analyzer: elaborates/7 over the strategy automata,
    % surfaced through all_elaborations/1. Import-free; the dispatch clause runs
    % analyze_all/0 on demand and qualifies calls by module:pred.
    use_module(strategies(meta/automaton_analyzer), []),
    use_module(carving(query), []),
    % Gate-G ops (brandomian_check / hyperedges / axiom_toggle /
    % unanticipated_strategies). Import-free ([]) and loaded last, per the
    % same convention as the render layer above: every dispatch clause
    % qualifies calls by module:pred, so nothing lands in `user`.
    %
    % brandomian_incompatibility is the canonical hyperedge relation; it must
    % stay module-qualified because incompatibility_sets exports a different,
    % profile-based incompatibility_entails/2 under the same name.
    use_module(arche_trace(brandomian_incompatibility), []),
    % The emergence criterion (size >= 3, jointly incoherent, every
    % one-element removal coherent), reused from the search tool rather than
    % reimplemented: the hyperedges op calls verified_emergent/1 on cached
    % discovery rows.
    use_module(arche_trace('tools/find_emergent_hyperedges'), []),
    % Lesson-vs-registry gap surface (flat Operation-Kind pairs) backing the
    % monitoring chart export's unanticipated_strategies key.
    use_module(lessons(lesson_gap), []).
    % NOT loaded here: tools/axiom_toggle.pl (the axiom_toggle op). Its
    % consult-time directive pulls arche_trace(load) into user, and that
    % chain's full re-imports collide with import bindings this loader has
    % already settled (a stream of harmless but alarming "No permission to
    % import" refusals on stderr). The op lazy-loads it on first use instead:
    % see ensure_axiom_toggle_loaded/0.

load_axiom_pack_audit(Root) :-
    directory_file_path(Root, 'tools/axiom_pack_audit.pl', AxiomAudit),
    ensure_loaded(AxiomAudit).

load_geometry_runtime(Root) :-
    directory_file_path(Root, 'geometry/schema.pl', Schema),
    consult(Schema).

worker_loop :-
    read_line_to_string(user_input, Line),
    (   Line == end_of_file
    ->  true
    ;   handle_line(Line),
        worker_loop
    ).

handle_line(Line) :-
    catch(
        ( atom_json_dict(Line, Request, []),
          handle_request(Request, Response)
        ),
        E,
        error_response("unknown", malformed_request, E, Response)
    ),
    json_write_dict(current_output, Response, [width(0)]),
    nl,
    flush_output(current_output).

handle_request(Request, Response) :-
    request_id(Request, Id),
    (   get_dict(op, Request, Op0)
    ->  atom_string(Op, Op0),
        (   catch(dispatch_request(Op, Id, Request, R), E, op_error(Id, Op, E, R))
        ->  Response = R
        ;   % A known op whose handler simply failed (no solution). Report it
            % honestly rather than letting it masquerade as an unknown op.
            format(string(FailMsg), "Operation '~w' is known but produced no result", [Op]),
            error_response(Id, op_failed, FailMsg, Response)
        )
    ;   error_response(Id, missing_op, "request has no op", Response)
    ).

%!  known_op(?Op) is nondet.
%
%   The ops with a dedicated handler. Used to keep the unknown_op catch-all
%   from swallowing a known op whose body failed (see handle_request/2).
known_op(health).
known_op(event_score).
known_op(batch_event_score).
known_op(discourse_features).
known_op(discourse_pragmatics).
known_op(trace_adjudication).
known_op(media_alignment).
known_op(gesture_alignment).
known_op(pair_score).
known_op(pair_graph).
known_op(pair_candidate_witness).
known_op(critique_bad_infinite).
known_op(defeasible_classify).
known_op(deontic_requires_entitlement).
known_op(deontic_scorecard).
known_op(deontic_crisis).
known_op(deontic_consequences).
known_op(deontic_up_level).
known_op(axiom_hierarchy_witness).
known_op(axiom_pack_witness).
known_op(robinson_axiom_witness).
known_op(semantic_material_witness).
known_op(incoherent_witness).
known_op(eml_transition_witness).
known_op(number_theory_self_defeat_witness).
known_op(embodied_proof_witness).
known_op(viability_witness).
known_op(modal_context_witness).
known_op(grounded_arith_witness).
known_op(material_inference_witness).
known_op(normative_crisis_witness).
known_op(metaphor_break_witness).
known_op(grounding_metaphor_witness).
known_op(sequent_proof_witness).
known_op(unit_coordination_witness).
known_op(unit_coordination_svg).
known_op(godel_primes_witness).
known_op(fsm_engine_witness).
known_op(action_cluster_witness).
known_op(practice_vocabulary_witness).
known_op(accommodation_witness).
known_op(domain_context_witness).
known_op(orr_entry_witness).
known_op(executable_practice_witness).
known_op(misconception_hook_witness).
known_op(algebra_claim_witness).
known_op(integer_signed_claim_witness).
known_op(arithmetic_property_witness).
known_op(calculus_claim_witness).
known_op(counting_claim_witness).
known_op(standard_k_ca_1_3_complement_witness).
known_op(standard_k_ns_1_count_by_ones_witness).
known_op(standard_k_ns_2_represent_count_witness).
known_op(standard_k_ns_3_order_independence_witness).
known_op(standard_k_ns_4_verify_subitizing_witness).
known_op(standard_k_ns_5_6_compare_groups_witness).
known_op(standard_k_ns_7_place_value_witness).
known_op(standard_1_ns_1_count_by_fives_witness).
known_op(standard_1_ns_2_place_value_witness).
known_op(standard_1_ca_1_making_ten_witness).
known_op(standard_1_ca_3_add_by_place_value_witness).
known_op(standard_2_ca_2_add_three_digit_witness).
known_op(standard_2_ns_1_count_by_twos_witness).
known_op(standard_2_ns_2_4_place_value_witness).
known_op(standard_2_ns_3_parity_witness).
known_op(standard_2_ns_5_place_value_comparison_witness).
known_op(standard_3_ca_3_4_fact_family_witness).
known_op(standard_3_ca_5_mult_skip_count_witness).
known_op(standard_3_ns_2_unit_fraction_witness).
known_op(standard_3_ns_5_fraction_comparison_witness).
known_op(misconception_jumps_witness).
known_op(misconception_pml_map).
known_op(balance_solve_witness).
known_op(whole_number_addsub_claim_witness).
known_op(ratio_proportion_claim_witness).
known_op(magnitude_equivalence_claim_witness).
known_op(multiplication_division_claim_witness).
known_op(decimal_claim_witness).
known_op(place_value_number_claim_witness).
known_op(whole_number_claim_witness).
known_op(fraction_extra_claim_witness).
known_op(fraction_claim_witness).
known_op(productive_deformation_witness).
known_op(representation_spine_witness).
known_op(geometry_entailment_witness).
known_op(incompatibility_discovery_witness).
known_op(incompatibility_entailment_witness).
known_op(misconception_incompatibility_witness).
known_op(intersubjective_material_witness).
known_op(mua_kind_coherence_witness).
known_op(mua_coherence_witness).
known_op(grounding_inference_witness).
known_op(target_expressive_power_witness).
known_op(lesson_misconception_incompatibility_witness).
known_op(geometry_material_profile_witness).
known_op(geometry_quadrilateral_entailment_witness).
known_op(geometry_strength_lift_coverage_witness).
known_op(geometry_van_hiele_material_witness).
known_op(geometry_van_hiele_marker_witness).
known_op(geometry_cross_link_witness).
known_op(geometry_developmental_arc_witness).
known_op(geometry_attribute_material_witness).
known_op(geometry_similarity_material_witness).
known_op(geometry_pythagorean_material_witness).
known_op(geometry_van_hiele_level_material_witness).
known_op(geometry_measurement_misconception_witness).
known_op(geometry_n103_bootstrap_witness).
known_op(geometry_van_de_walle_bootstrap_witness).
known_op(geometry_shape_recognition_material_witness).
known_op(geometry_coordinate_material_witness).
known_op(geometry_angle_material_witness).
known_op(geometry_area_perimeter_material_witness).
known_op(geometry_volume_surface_area_material_witness).
known_op(geometry_transformation_material_witness).
known_op(geometry_classification_material_witness).
known_op(geometry_pck_classification_witness).
known_op(geometry_measuring_stick_metaphor_witness).
known_op(geometry_lakoff_nunez_metaphor_witness).
known_op(geometry_synthesizer_anchor_material_witness).
known_op(geometry_synthesizer_triangulation_witness).
known_op(geometry_ccss_standard_witness).
known_op(geometry_indiana_standard_witness).
known_op(geometry_im_grade8_lesson_standard_witness).
known_op(geometry_im_grade7_lesson_standard_witness).
known_op(geometry_im_grade6_lesson_standard_witness).
known_op(geometry_im_grade5_standard_anchor_witness).
known_op(geometry).
known_op(diagnose_error).
known_op(query_misconception).
known_op(monitoring_chart_export).
known_op(ranked_figures).
known_op(field_context).
known_op(field_connectivity_audit).
known_op(render_coverage).
known_op(expressive_power).
known_op(list_strategies).
known_op(strategy_trace).
known_op(fraction_render).
known_op(fraction_compare).
known_op(area_render).
known_op(base_ten_render).
known_op(ace_of_bases_render).
known_op(unit_echo_render).
known_op(set_grouping_render).
known_op(balance_render).
known_op(number_line_render).
known_op(place_value_chart_render).
known_op(hybridization_render).
known_op(area_compare).
known_op(base_ten_compare).
known_op(set_grouping_compare).
known_op(balance_compare).
known_op(number_line_compare).
known_op(representation_check).
known_op(representation_candidates).
known_op(representation_spec_check).
known_op(teacher_layer).
known_op(primitive_for_practice).
known_op(image_schema).
known_op(set_base).
known_op(get_base).
known_op(multiply_array_witness).
known_op(mult_div_family_witness).
known_op(list_misconceptions).
known_op(list_standards).
known_op(grounding_metaphors).
known_op(grounding_for).
known_op(ground).
known_op(lit_search).
known_op(pml_score).
known_op(validate_reader_axioms).
known_op(canonical_contract).
known_op(canonical_check).
known_op(notation_render).
known_op(fraction_cgi_addition).
known_op(lesson_deformation_chart).
known_op(notation_monitoring_chart).
known_op(brandom_backstop).
known_op(brandomian_check).
known_op(hyperedges).
known_op(axiom_toggle).
known_op(commitment_match).
known_op(corpus_grammar_summary).
known_op(elaborations).
known_op(carving_strategy_proof).
known_op(carving_operation_summary).
known_op(benny_demo).
known_op(compute).
known_op(knowledge).
known_op(visualize_coordination).
known_op(reorganize).
known_op(learner_reset).
known_op(capability_atlas).

op_error(Id, Op, Error, Response) :-
    message_string(Error, Detail),
    format(string(Message), "Operation '~w' raised: ~w", [Op, Detail]),
    error_response(Id, op_exception, Message, Response).

dispatch_request(health, Id, _Request, Response) :-
    findall(Name,
        ( capability_registry:capability(Name, _, _, _, Status),
          Status \= orphan_module,
          Status \= lazy_reachable
        ),
        Ops),
    ok_response(Id, _{
        crosswalk_family_count: 38,
        worker: "hermes_swi",
        loaded: ["event_scoring", "pair_scoring", "critique", "defeasible_inference", "incompatibility_sets", "sequent_brandom_bridge", "brandomian_incompatibility", "find_emergent_hyperedges", "lesson_gap", "corpus_attested_grammar", "lesson_notation_chart", "lesson_monitoring_selector", "automaton_analyzer", "semantic_axioms", "intersubjective_praxis", "mua_relations", "media_alignment", "gesture_alignment", "discourse_features", "discourse_pragmatics", "trace_adjudication", "embodied_prover", "sequent_engine", "deontic_scorekeeper", "axiom_pack_audit", "geometry", "misconception_registry", "misconceptions", "misconception_render_coverage", "lesson_monitoring", "field_context", "field_connectivity_audit", "grounding_metaphors", "encyclopedia", "visualization", "fraction_bars_scene", "balance_scale_scene", "cw_viability", "cw_axiom_pack", "cw_modal_context", "cw_grounded_arith", "cw_material_inference", "cw_normative_crisis", "cw_metaphor_break", "cw_grounding_metaphor", "cw_sequent_proof", "cw_mua_coherence", "cw_unit_coordination", "cw_godel_primes", "cw_fsm_engine", "cw_action_cluster", "cw_practice_vocabulary", "cw_accommodation", "cw_domain_context", "cw_orr_entry", "cw_executable_practice", "cw_misconception_hook", "cw_algebra_claim", "cw_integer_signed_claim", "cw_arithmetic_property_claim", "cw_calculus_claim", "cw_counting_claim", "cw_whole_number_addsub_claim", "cw_ratio_proportion_claim", "cw_magnitude_equivalence_claim", "cw_multiplication_division_claim", "cw_decimal_claim", "cw_place_value_number_claim", "cw_whole_number_claim", "cw_fraction_extra_claim", "cw_fraction_claim", "cw_productive_deformation", "standard_k_ca_1_3", "standard_k_ns_1", "standard_k_ns_2", "standard_k_ns_3", "standard_k_ns_4", "standard_k_ns_5_6", "standard_k_ns_7", "standard_1_ns_1", "standard_1_ns_2", "standard_1_ca_1", "standard_1_ca_3", "standard_2_ca_2", "standard_2_ns_1", "standard_2_ns_2_4", "standard_2_ns_3", "standard_2_ns_5", "standard_3_ca_3_4", "standard_3_ca_5", "standard_3_ns_2", "standard_3_ns_5", "canonical_vocabulary", "representation_spine"],
        ops: Ops,
        mode: "persistent"
    }, Response).

dispatch_request(media_alignment, Id, Request, Response) :-
    (   get_dict(segments, Request, Segments),
        get_dict(source, Request, Source),
        media_alignment:analyze_media_alignment(Segments, Source, Bundle)
    ->  json_safe(Bundle, Safe),
        ok_response(Id, Safe, Response)
    ;   error_response(
            Id,
            malformed_media_alignment,
            "media_alignment requires an ordered segments list of strict {speaker, text, start_ms, end_ms} objects and an attributed source",
            Response)
    ).

dispatch_request(gesture_alignment, Id, Request, Response) :-
    (   get_dict(utterances, Request, JSONUtterances),
        request_utterances(JSONUtterances, Utterances)
    ->  (   request_discourse_context(Request, Utterances, ContextEvidence)
        ->  (   get_dict(observations, Request, Observations),
                gesture_alignment:align_gesture_observations(
                    Utterances, ContextEvidence, Observations, Bundle)
            ->  json_safe(Bundle, Safe),
                ok_response(Id, Safe, Response)
            ;   error_response(
                    Id,
                    malformed_gesture_observations,
                    "gesture_alignment requires strict attributed gesture intervals with valid targets and timing",
                    Response)
            )
        ;   error_response(
                Id,
                malformed_discourse_context,
                "gesture_alignment context metadata is malformed or refers to undeclared IDs or targets",
                Response)
        )
    ;   error_response(
            Id,
            malformed_utterances,
            "gesture_alignment requires an utterances list of unique {id, speaker, text} objects",
            Response)
    ).

dispatch_request(discourse_features, Id, Request, Response) :-
    (   get_dict(utterances, Request, JSONUtterances),
        request_utterances(JSONUtterances, Utterances)
    ->  (   request_discourse_context(Request, Utterances, ContextEvidence)
        ->  discourse_features:analyze_transcript(
                Utterances, ContextEvidence, Analysis),
            json_safe(Analysis, Safe),
            ok_response(Id, Safe, Response)
        ;   error_response(
                Id,
                malformed_discourse_context,
                "discourse_features context metadata is malformed or refers to undeclared IDs or targets",
                Response)
        )
    ;   error_response(
            Id,
            malformed_utterances,
            "discourse_features requires an utterances list of unique {id, speaker, text} objects",
            Response)
    ).

dispatch_request(discourse_pragmatics, Id, Request, Response) :-
    (   get_dict(utterances, Request, JSONUtterances),
        request_utterances(JSONUtterances, Utterances)
    ->  (   request_discourse_context(Request, Utterances, ContextEvidence)
        ->  discourse_pragmatics:analyze_pragmatics(
                Utterances, ContextEvidence, Analysis),
            json_safe(Analysis, Safe),
            ok_response(Id, Safe, Response)
        ;   error_response(
                Id,
                malformed_discourse_context,
                "discourse_pragmatics context metadata is malformed or refers to undeclared IDs or targets",
                Response)
        )
    ;   error_response(
            Id,
            malformed_utterances,
            "discourse_pragmatics requires an utterances list of unique {id, speaker, text} objects",
            Response)
    ).

dispatch_request(trace_adjudication, Id, Request, Response) :-
    (   get_dict(utterances, Request, JSONUtterances),
        request_utterances(JSONUtterances, Utterances)
    ->  (   request_discourse_context(Request, Utterances, ContextEvidence)
        ->  (   get_dict(ledger, Request, LedgerDict),
                trace_adjudication:adjudication_dict_terms(
                    LedgerDict, Proposals, Ledger)
            ->  discourse_pragmatics:pragmatic_evidence_candidates(
                    Utterances, ContextEvidence, Candidates),
                (   trace_adjudication:adjudication_summary(
                        Utterances, Candidates, Proposals, Ledger, Summary)
                ->  json_safe(Summary, Safe),
                    ok_response(Id, Safe, Response)
                ;   error_response(
                        Id,
                        invalid_trace_adjudication,
                        "trace_adjudication proposals or reviews do not match the current evidence candidates and utterance spans",
                        Response)
                )
            ;   error_response(
                    Id,
                    malformed_trace_ledger,
                    "trace_adjudication requires a strict ledger object with proposals and adjudications arrays",
                    Response)
            )
        ;   error_response(
                Id,
                malformed_discourse_context,
                "trace_adjudication context metadata is malformed or refers to undeclared IDs or targets",
                Response)
        )
    ;   error_response(
            Id,
            malformed_utterances,
            "trace_adjudication requires an utterances list of unique {id, speaker, text} objects",
            Response)
    ).

dispatch_request(pair_candidate_witness, Id, Request, Response) :-
    (   get_dict(event_a, Request, EventA),
        get_dict(event_b, Request, EventB)
    ->  (   hermes_pair_scoring:pair_candidate_witness(EventA, EventB, Witness)
        ->  json_safe(Witness, Safe),
            ok_response(Id, Safe, Response)
        ;   error_response(Id, no_pair_candidate_witness,
                "pair_candidate_witness found no recorded example for event_a/event_b",
                Response)
        )
    ;   error_response(Id, malformed_pair_candidate_request,
            "pair_candidate_witness requires event_a and event_b", Response)
    ).



dispatch_request(deontic_requires_entitlement, Id, Request, Response) :-
    (   get_dict(proposition, Request, JSONProposition)
    ->  json_to_term(JSONProposition, Proposition),
        (   deontic_scorekeeper:requires_entitlement_witness(Proposition, Witness)
        ->  json_safe(Witness, Safe),
            ok_response(Id, Safe, Response)
        ;   error_response(Id, no_deontic_entitlement_witness,
                "deontic_requires_entitlement found no entitlement recorded example for proposition",
                Response)
        )
    ;   error_response(Id, missing_proposition,
            "deontic_requires_entitlement requires proposition", Response)
    ).

%% deontic_scorecard: the full deontic board for one agent.
%%
%% Unlike deontic_requires_entitlement (a single-proposition lookup), this op
%% seeds an ephemeral agent from the request's `commitments` and `entitlements`
%% (each a list of Prolog term strings), then returns scorekeeper:scorecard/2 --
%% the agent's commitments, entitlements, and incoherences. The signature
%% incoherence a reviewer is looking for is
%% `commitment_without_entitlement(area_model_justification_missing)`: a
%% cross-multiplication commitment that deployed no area-model vocabulary and so
%% is procedurally correct but inferentially hollow. Depositing
%% `deployed_vocabulary(v_area_model)` as a commitment clears it.
%%
%% The op is deterministic across requests: it resets the agent before seeding
%% and again after reading the card, so the persistent worker carries no state
%% between scorecard requests. Entitlement grants that the scorekeeper refuses
%% (it requires a prior commitment) are skipped rather than failing the request.
dispatch_request(deontic_scorecard, Id, Request, Response) :-
    (   get_dict_opt(agent, Request, JSONAgent),
        json_to_term(JSONAgent, Agent0),
        ( atom(Agent0) -> Agent = Agent0 ; term_to_atom(Agent0, Agent) )
    ->  true
    ;   Agent = scoreboard
    ),
    ( get_dict_opt(commitments, Request, CJSON), is_list(CJSON) -> true ; CJSON = [] ),
    ( get_dict_opt(entitlements, Request, EJSON), is_list(EJSON) -> true ; EJSON = [] ),
    json_to_term(CJSON, Commitments),
    json_to_term(EJSON, Entitlements),
    (   catch(
            ( deontic_scorekeeper:reset_scorekeeper(Agent),
              forall(member(C, Commitments),
                     deontic_scorekeeper:undertake_commitment(Agent, C)),
              forall(member(E, Entitlements),
                     ignore(deontic_scorekeeper:grant_entitlement(Agent, E))),
              deontic_scorekeeper:scorecard(Agent, Card),
              deontic_scorekeeper:reset_scorekeeper(Agent)
            ),
            _Err,
            fail)
    ->  json_safe(Card, Safe),
        ok_response(Id, Safe, Response)
    ;   error_response(Id, deontic_scorecard_failed,
            "deontic_scorecard could not compute a commitment tracker for the request",
            Response)
    ).

%% deontic_crisis: name incoherence as a crisis descriptor.
%%
%% Seeds the same ephemeral deontic board as deontic_scorecard/3, then maps each
%% incoherence through crisis_from_deontic_incoherence/3 and reports the
%% commitments that can be withdrawn to repair that incoherence.
dispatch_request(deontic_crisis, Id, Request, Response) :-
    (   get_dict_opt(agent, Request, JSONAgent),
        json_to_term(JSONAgent, Agent0),
        ( atom(Agent0) -> Agent = Agent0 ; term_to_atom(Agent0, Agent) )
    ->  true
    ;   Agent = scoreboard
    ),
    ( get_dict_opt(commitments, Request, CJSON), is_list(CJSON) -> true ; CJSON = [] ),
    ( get_dict_opt(entitlements, Request, EJSON), is_list(EJSON) -> true ; EJSON = [] ),
    json_to_term(CJSON, Commitments),
    json_to_term(EJSON, Entitlements),
    (   catch(
            ( deontic_scorekeeper:reset_scorekeeper(Agent),
              forall(member(C, Commitments),
                     deontic_scorekeeper:undertake_commitment(Agent, C)),
              forall(member(E, Entitlements),
                     ignore(deontic_scorekeeper:grant_entitlement(Agent, E))),
              findall(Reason,
                      deontic_scorekeeper:deontic_incoherent(Agent, Reason),
                      Reasons0),
              sort(Reasons0, Reasons),
              findall(Crisis,
                      ( member(Reason, Reasons),
                        deontic_scorekeeper:crisis_from_deontic_incoherence(Agent, Reason, Crisis) ),
                      Crises),
              findall(Commitment,
                      ( member(Reason, Reasons),
                        deontic_scorekeeper:deontic_incoherence_commitments(Agent, Reason, CommitmentsForReason),
                        member(Commitment, CommitmentsForReason) ),
                      Withdrawable0),
              sort(Withdrawable0, Withdrawable),
              ( Reasons == [] -> Coherent = true ; Coherent = false ),
              Result = _{agent: Agent,
                         coherent: Coherent,
                         incoherences: Reasons,
                         crises: Crises,
                         withdrawable_commitments: Withdrawable},
              deontic_scorekeeper:reset_scorekeeper(Agent)
            ),
            _Err,
            fail)
    ->  json_safe(Result, Safe),
        ok_response(Id, Safe, Response)
    ;   error_response(Id, deontic_crisis_failed,
            "deontic_crisis could not compute crises for the request",
            Response)
    ).

%% deontic_consequences: what an agent's commitments materially commit them to.
%%
%% Exposes deontic_scorekeeper:commitment_consequence_witness/4 over the seeded
%% commitments. undertake_commitment/2 propagates consequences as further
%% commitments, so the result is the one-step consequence of every commitment in
%% the closure -- each with the witness recording WHICH rule or MUA PP-sufficient
%% mechanism justified it (local material inference, mastery elaboration, or
%% committed_to elaboration). Same reset-before/after discipline as
%% deontic_scorecard, so the persistent worker carries no state between requests.
dispatch_request(deontic_consequences, Id, Request, Response) :-
    (   get_dict_opt(agent, Request, JSONAgent),
        json_to_term(JSONAgent, Agent0),
        ( atom(Agent0) -> Agent = Agent0 ; term_to_atom(Agent0, Agent) )
    ->  true
    ;   Agent = scoreboard
    ),
    ( get_dict_opt(commitments, Request, CJSON), is_list(CJSON) -> true ; CJSON = [] ),
    json_to_term(CJSON, Commitments),
    (   catch(
            ( deontic_scorekeeper:reset_scorekeeper(Agent),
              forall(member(C, Commitments),
                     deontic_scorekeeper:undertake_commitment(Agent, C)),
              findall(_{premise: P, conclusion: Q, witness: W},
                      ( deontic_scorekeeper:commitment(Agent, P),
                        deontic_scorekeeper:commitment_consequence_witness(Agent, P, Q, W) ),
                      Consequences0),
              sort(Consequences0, Consequences),
              deontic_scorekeeper:reset_scorekeeper(Agent)
            ),
            _Err,
            fail)
    ->  json_safe(_{agent: Agent, consequences: Consequences}, Safe),
        ok_response(Id, Safe, Response)
    ;   error_response(Id, deontic_consequences_failed,
            "deontic_consequences could not compute consequences for the request",
            Response)
    ).

%% deontic_up_level: the objectivation move for gaps the within-level layer
%% cannot close (REPRESENTATIONAL -- see learner/up_leveling.pl).
%%
%% Seeds an agent from the request's commitments, then returns the up-level
%% witnesses: for each commitment_without_entitlement(_) that survived the full
%% commitment-consequence closure, the witness lifts the gap into a new object
%% of discourse one level up ("talking about talking"), in Zhang & Carspecken's
%% objectivation/up-leveling vocabulary, mapped onto the diagonal-sandwich form.
%% The witness's `erasure` field marks what the formalism does NOT supply (which
%% pragmatic metavocabulary resolves the new topic). A coherent or
%% within-level-dischargeable board returns an empty list. Same reset-before/
%% after discipline as the other deontic ops.
dispatch_request(deontic_up_level, Id, Request, Response) :-
    (   get_dict_opt(agent, Request, JSONAgent),
        json_to_term(JSONAgent, Agent0),
        ( atom(Agent0) -> Agent = Agent0 ; term_to_atom(Agent0, Agent) )
    ->  true
    ;   Agent = scoreboard
    ),
    ( get_dict_opt(commitments, Request, CJSON), is_list(CJSON) -> true ; CJSON = [] ),
    json_to_term(CJSON, Commitments),
    (   catch(
            ( deontic_scorekeeper:reset_scorekeeper(Agent),
              forall(member(C, Commitments),
                     deontic_scorekeeper:undertake_commitment(Agent, C)),
              up_leveling:up_level_scorecard(Agent, Witnesses),
              deontic_scorekeeper:reset_scorekeeper(Agent)
            ),
            _Err,
            fail)
    ->  json_safe(_{agent: Agent, up_levels: Witnesses}, Safe),
        ok_response(Id, Safe, Response)
    ;   error_response(Id, deontic_up_level_failed,
            "deontic_up_level could not name the stuck point as a new question for the request",
            Response)
    ).








% representation_spine_witness: the T0 representation spine as a live surface.
% With a `concept` string it returns that concept's render routes (renders_on/3)
% plus a capped sample of manifest-backed assets (asset_for/3) and the total
% asset count; with no concept it lists every renders_on route. This is the
% crosswalk consumer the spine lacked — renders_on/3 and asset_for/3 are now
% queryable at runtime, not only in the module's test.

dispatch_request(sequent_proof_witness, Id, Request, Response) :-
    (   get_dict(sequent, Request, JSONSequent),
        get_dict(source, Request, JSONSource)
    ->  json_to_term(JSONSequent, Sequent),
        json_to_term(JSONSource, Source),
        (   cw_sequent_proof:sequent_proof_witness(Sequent, Source, Witness)
        ->  json_safe(Witness, Safe),
            ok_response(Id, Safe, Response)
        ;   error_response(Id, no_sequent_proof_witness,
                "sequent_proof_witness found no sequent proof recorded example",
                Response)
        )
    ;   error_response(Id, malformed_sequent_proof_request,
            "sequent_proof_witness requires sequent and source",
            Response)
    ).

dispatch_request(unit_coordination_svg, Id, Request, Response) :-
    ensure_coordination_viz_loaded,
    request_integer(Request, base, 10, Base),
    request_integer(Request, value_up, 1234, ValueUp),
    request_integer(Request, numerator, 1, Numerator),
    request_integer(Request, denominator, Base, Denominator),
    (   unit_coordination_viz:generate_coordination_svg(
            Base,
            ValueUp,
            fraction(Numerator, Denominator),
            Svg
        )
    ->  Dict = _{ kind: "unit_coordination_svg",
                  content_type: "image/svg+xml",
                  request: _{ base: Base,
                              value_up: ValueUp,
                              numerator: Numerator,
                              denominator: Denominator },
                  svg: Svg },
        ok_response(Id, Dict, Response)
    ;   error_response(Id, invalid_unit_coordination_svg_request,
            "unit_coordination_svg requires base 2..15, non-negative value_up, and denominator > 0",
            Response)
    ).





























dispatch_request(geometry, Id, Request, Response) :-
    (   get_dict(predicate, Request, Predicate0),
        get_dict(args, Request, Args)
    ->  atom_string(Predicate, Predicate0),
        dispatch_geometry(Predicate, Args, Id, Response)
    ;   error_response(Id, malformed_geometry_request,
            "geometry requires predicate and args", Response)
    ).

dispatch_request(diagnose_error, Id, Request, Response) :-
    (   get_dict(domain, Request, DomainStr),
        get_dict(input, Request, JSONInput),
        get_dict(got, Request, JSONGot)
    ->  atom_string(Domain, DomainStr),
        json_to_term(JSONInput, Input),
        json_to_term(JSONGot, Got),
        findall(Match, diagnose_and_format(Domain, Input, Got, Match), Matches),
        ok_response(Id, Matches, Response)
    ;   error_response(Id, malformed_diagnose_request,
            "diagnose_error requires domain, input, and got", Response)
    ).

dispatch_request(query_misconception, Id, Request, Response) :-
    (   get_dict_opt(domain, Request, DomainVal) -> json_to_term(DomainVal, Domain) ; true ),
    (   get_dict_opt(description, Request, DescVal) -> json_to_term(DescVal, Description) ; true ),
    (   get_dict_opt(source, Request, SrcVal) -> json_to_term(SrcVal, Source) ; true ),
    findall(Match, query_and_format(Domain, Description, Source, Match), Matches),
    ok_response(Id, Matches, Response).

%% render_coverage: the four-lane misconception render-coverage report.
%% Stateless read over the registry and the render lanes; counts are computed
%% live in this process, so an installation carrying the local misconception
%% CSV corpus reports its larger registry through the same op.
dispatch_request(misconception_jumps_witness, Id, Request, Response) :-
    (   get_dict(operation, Request, JSONOperation),
        get_dict(deformation, Request, JSONDeformation),
        get_dict(a, Request, _),
        get_dict(b, Request, _)
    ->  json_to_term(JSONOperation, Operation0),
        json_to_term(JSONDeformation, Deformation0),
        string_or_atom_to_atom(Operation0, Operation),
        string_or_atom_to_atom(Deformation0, Deformation),
        request_integer(Request, a, 0, A),
        request_integer(Request, b, 0, B),
        (   visualization:misconception_jumps_witness(Operation, Deformation, A, B, Witness)
        ->  json_safe(Witness, Safe),
            ok_response(Id, Safe, Response)
        ;   error_response(Id, no_misconception_jumps_witness,
                "misconception_jumps_witness found no drawable number-line deformation trace",
                Response)
        )
    ;   error_response(Id, malformed_misconception_jumps_request,
            "misconception_jumps_witness requires operation, deformation, a, and b",
            Response)
    ).

dispatch_request(balance_solve_witness, Id, Request, Response) :-
    (   get_dict(a, Request, _),
        get_dict(b, Request, _),
        get_dict(c, Request, _)
    ->  request_integer(Request, a, 0, A),
        request_integer(Request, b, 0, B),
        request_integer(Request, c, 0, C),
        (   balance_scale_scene:balance_solve_witness(A, B, C, Witness)
        ->  json_safe(Witness, Safe),
            ok_response(Id, Safe, Response)
        ;   error_response(Id, no_balance_solve_witness,
                "balance_solve_witness found no non-negative integer one-unknown solution",
                Response)
        )
    ;   error_response(Id, malformed_balance_solve_request,
            "balance_solve_witness requires a, b, and c",
            Response)
    ).

dispatch_request(representation_check, Id, Request, Response) :-
    request_op_atom(Request, representation, base_ten_blocks, Representation),
    request_op_atom(Request, mode, productive, Mode),
    (   representation_task(Request, Task)
    ->  representation_check_dict(Mode, Representation, Task, Dict0),
        json_safe(Dict0, Dict),
        ok_response(Id, Dict, Response)
    ;   error_response(Id, malformed_representation_check_request,
            "representation_check requires a supported task plus its numeric fields",
            Response)
    ).

dispatch_request(representation_candidates, Id, Request, Response) :-
    request_lesson_context(Request, LessonContext),
    request_lesson_selector(Request, SelectorSource),
    request_string_atom(Request, strategy, unknown_strategy, Strategy),
    request_string_atom(Request, misconception, none, Misconception),
    (   representation_task(Request, Task)
    ->  representation_candidates_dict(
            SelectorSource,
            LessonContext,
            Task,
            Strategy,
            Misconception,
            Dict0
        ),
        json_safe(Dict0, Dict),
        ok_response(Id, Dict, Response)
    ;   error_response(Id, malformed_representation_candidates_request,
            "representation_candidates requires a supported task plus its numeric fields",
            Response)
    ).

dispatch_request(representation_spec_check, Id, Request, Response) :-
    request_op_atom(Request, representation, number_line, Representation),
    (   representation_render_spec(Request, Representation, Spec)
    ->  (   representation_spec_check_dict(Request, Representation, Spec, Dict0)
        ->  json_safe(Dict0, Dict),
            ok_response(Id, Dict, Response)
        ;   error_response(Id, no_representation_spec_denotation,
                "representation_spec_check could not infer a denotation or deformation evidence",
                Response)
        )
    ;   error_response(Id, malformed_representation_spec_request,
            "representation_spec_check requires a supported representation and render spec fields",
            Response)
    ).

% Lay out one fraction automaton as bars (v2 frames). Mirrors the viewer's
% live contract: kind selects the automaton, n/d feed the count/base.
dispatch_request(fraction_render, Id, Request, Response) :-
    (   get_dict(kind, Request, Kind0)
    ->  string_or_atom_to_atom(Kind0, Kind),
        fraction_render_dispatch(Kind, Id, Request, Response)
    ;   error_response(Id, missing_kind,
            "fraction_render requires kind", Response)
    ).

fraction_render_dispatch(arith, Id, Request, Response) :-
    !,
    request_op_atom(Request, operation, add, Op),
    request_integer(Request, na, 1, NA),
    request_integer(Request, da, 3, DA),
    request_integer(Request, nb, 1, NB),
    request_integer(Request, db, 4, DB),
    fraction_bars_scene:fraction_arith_json(Op, NA, DA, NB, DB, Dict),
    ok_response(Id, Dict, Response).
fraction_render_dispatch(add_numerators_and_denominators, Id, Request, Response) :-
    !,
    request_integer(Request, na, 1, NA),
    request_integer(Request, da, 3, DA),
    request_integer(Request, nb, 1, NB),
    request_integer(Request, db, 4, DB),
    fraction_bars_scene:fraction_componentwise_add_json(NA, DA, NB, DB, Dict),
    ok_response(Id, Dict, Response).
fraction_render_dispatch(Kind, Id, Request, Response) :-
    request_integer(Request, n, 5, N),
    request_integer(Request, d, 3, D),
    fraction_bars_scene:fraction_render_json(Kind, N, D, Dict),
    ok_response(Id, Dict, Response).

% Lay out the productive vs deformation comparison for a fraction scheme.
dispatch_request(fraction_compare, Id, Request, Response) :-
    (   get_dict(kind, Request, Kind0)
    ->  atom_string(Kind, Kind0),
        request_integer(Request, a, 5, A),
        request_integer(Request, b, 3, B),
        fraction_bars_scene:fraction_compare_json(Kind, A, B, Dict),
        ok_response(Id, Dict, Response)
    ;   error_response(Id, missing_kind,
            "fraction_compare requires kind", Response)
    ).

% =============================================================================
% Visualization render ops (Goal H / Gate E seam).
%
% Each op is a thin pass-through to a witness-walking scene compiler in the
% render/ directory, mirroring fraction_render. The compiler owns the geometry;
% the worker parses the request into the compiler's Spec, calls *_render_json/2,
% then threads the three additive document fields the frozen render contract
% names (doc.grounding §1.4a, doc.tuple §1.4b, doc.teacher §1.4c) onto the
% returned document via enrich_render_doc/3 — except where the compiler already
% emitted that field, in which case the existing value is kept (a compiler that
% sources a field itself is authoritative; the worker only fills gaps).
%
% The practice atom that selects the L&N metaphor footer and the teacher layer
% is derived per (op, spec) by render_practice/3, the worker-side counterpart of
% each compiler's own spec_practice mapping. A spec that maps to no practice
% (the inferentially hollow deformation) carries no grounding/teacher object —
% its absence is the claim, per the contract.
% =============================================================================

dispatch_request(area_render, Id, Request, Response) :-
    area_spec(Request, Spec),
    area_model_scene:area_render_json(Spec, Dict0),
    enrich_render_doc(area_render, Spec, Dict0, Dict),
    ok_response(Id, Dict, Response).

dispatch_request(area_compare, Id, Request, Response) :-
    request_integer(Request, na, 1, NA),
    request_integer(Request, da, 2, DA),
    request_integer(Request, nb, 1, NB),
    request_integer(Request, db, 3, DB),
    Spec = area_compare(NA, DA, NB, DB),
    area_model_scene:area_compare_json(Spec, Dict0),
    enrich_render_doc(area_compare, Spec, Dict0, Dict),
    ok_response(Id, Dict, Response).

dispatch_request(base_ten_render, Id, Request, Response) :-
    base_ten_spec(Request, Spec),
    base_ten_scene:base_ten_render_json(Spec, Dict0),
    enrich_render_doc(base_ten_render, Spec, Dict0, Dict),
    ok_response(Id, Dict, Response).

dispatch_request(ace_of_bases_render, Id, Request, Response) :-
    base_ten_spec(Request, Spec),
    base_ten_scene:base_ten_render_json(Spec, Dict0),
    enrich_render_doc(ace_of_bases_render, Spec, Dict0, Dict),
    ok_response(Id, Dict, Response).

dispatch_request(unit_echo_render, Id, Request, Response) :-
    request_integer(Request, base, 7, Base),
    request_integer(Request, iterations, Base, Iterations),
    (   unit_echo_scene:unit_echo_render_json(Base, Iterations, Dict0)
    ->  Spec = unit_echo(Base, Iterations),
        enrich_render_doc(unit_echo_render, Spec, Dict0, Dict),
        ok_response(Id, Dict, Response)
    ;   error_response(Id, invalid_unit_echo,
            "unit_echo_render requires base >= 2 and iterations >= 1", Response)
    ).

% The base-ten deformation path (dropped carry) is a render of the deformation
% spec; it maps to no practice (hollow), so no grounding/teacher footer.
dispatch_request(base_ten_compare, Id, Request, Response) :-
    request_integer(Request, a, 28, A),
    request_integer(Request, b, 47, B),
    request_integer(Request, base, 10, Base),
    Spec = add_with_dropped_carry(A, B, Base),
    base_ten_scene:base_ten_render_json(Spec, Dict0),
    enrich_render_doc(base_ten_compare, Spec, Dict0, Dict),
    ok_response(Id, Dict, Response).

dispatch_request(set_grouping_render, Id, Request, Response) :-
    set_grouping_spec(Request, Spec),
    set_grouping_scene:set_grouping_render_json(Spec, Dict0),
    enrich_render_doc(set_grouping_render, Spec, Dict0, Dict),
    ok_response(Id, Dict, Response).

dispatch_request(set_grouping_compare, Id, Request, Response) :-
    request_integer(Request, a, 5, A),
    request_integer(Request, b, 3, B),
    Spec = unfair_compare(A, B),
    set_grouping_scene:set_grouping_render_json(Spec, Dict0),
    enrich_render_doc(set_grouping_compare, Spec, Dict0, Dict),
    ok_response(Id, Dict, Response).

dispatch_request(balance_render, Id, Request, Response) :-
    request_integer(Request, a, 2, A),
    request_integer(Request, b, 3, B),
    request_integer(Request, c, 11, C),
    Spec = solve_linear(A, B, C),
    balance_scale_scene:balance_render_json(Spec, Dict0),
    enrich_render_doc(balance_render, Spec, Dict0, Dict),
    ok_response(Id, Dict, Response).

dispatch_request(balance_compare, Id, Request, Response) :-
    request_integer(Request, a, 2, A),
    request_integer(Request, b, 3, B),
    request_integer(Request, c, 11, C),
    Spec = solve_linear(A, B, C),
    balance_scale_scene:balance_compare_json(Spec, Dict0),
    enrich_render_doc(balance_compare, Spec, Dict0, Dict),
    ok_response(Id, Dict, Response).

dispatch_request(number_line_render, Id, Request, Response) :-
    number_line_spec(Request, Spec),
    number_line_scene:number_line_render_json(Spec, Dict0),
    enrich_render_doc(number_line_render, Spec, Dict0, Dict),
    ok_response(Id, Dict, Response).

dispatch_request(place_value_chart_render, Id, Request, Response) :-
    place_value_chart_spec(Request, Spec),
    place_value_chart_scene:place_value_chart_render_json(Spec, Dict0),
    enrich_render_doc(place_value_chart_render, Spec, Dict0, Dict),
    ok_response(Id, Dict, Response).

dispatch_request(hybridization_render, Id, Request, Response) :-
    hybridization_spec(Request, Spec),
    hybridization_scene:hybridization_render_json(Spec, Dict0),
    enrich_render_doc(hybridization_render, Spec, Dict0, Dict),
    ok_response(Id, Dict, Response).

dispatch_request(number_line_compare, Id, Request, Response) :-
    request_op_atom(Request, operation, addition, Op),
    request_integer(Request, a, 28, A),
    request_integer(Request, b, 47, B),
    Spec = rounding_compare(Op, A, B),
    number_line_scene:number_line_compare_json(Spec, Dict0),
    enrich_render_doc(number_line_compare, Spec, Dict0, Dict),
    ok_response(Id, Dict, Response).

% --- set_base / get_base: shift the operative base (Ace-of-Base base-invariance) ---
% cgi_base:set_cgi_base/1 (strategies/math/cgi_base.pl) is the single source of
% truth for the operative base; these ops surface base-shifting so the base-ten
% visualizer can show the same make-base move at base 10 and base 12 (the
% base-invariance the synthesis branch proved). The operative base is NOT a
% fraction denominator (cgi_base.pl header makes the distinction).
dispatch_request(set_base, Id, Request, Response) :-
    request_integer(Request, base, 10, Base),
    (   integer(Base), Base >= 2
    ->  cgi_base:set_cgi_base(Base),
        cgi_base:current_cgi_base(Now),
        ok_response(Id, _{operative_base: Now}, Response)
    ;   error_response(Id, invalid_base,
            "set_base requires an integer base >= 2", Response)
    ).
dispatch_request(get_base, Id, _Request, Response) :-
    cgi_base:current_cgi_base(Base),
    ok_response(Id, _{operative_base: Base}, Response).

% --- misconception_pml_map: recorded CONNECTS-TO annotations -------------

% --- teacher_layer (H8): the teacher panel for a named practice ------------
% Composes the standard, embodied source-practice gloss, incompatibility
% penumbra, and break/repair channels over witnesses that already exist.
dispatch_request(teacher_layer, Id, Request, Response) :-
    (   request_practice(Request, Practice)
    ->  (   teacher_layer:teacher_layer(Practice, Dict0)
        ->  % The witness is internal provenance (which channels populated, the
            % practice atom). It is not teacher-facing copy and the drawer never
            % reads it; drop it so the public surface carries only the humanized
            % display fields, not raw functor handles.
            ( del_dict(witness, Dict0, _, Dict1) -> true ; Dict1 = Dict0 ),
            json_safe(Dict1, Dict),
            ok_response(Id, Dict, Response)
        ;   error_response(Id, no_teacher_layer,
                "teacher_layer found no metaphor-grounded teacher channels for this practice",
                Response)
        )
    ;   error_response(Id, missing_practice,
            "teacher_layer requires practice (a practice atom string)", Response)
    ).

% --- primitive_for_practice (H3): grounding -> visual primitive routing -----
% Returns the visual primitive and grounding-metaphor label a practice's L&N
% grounding selects. A practice with no L&N grounding (the hollow deformation)
% returns no_metaphor_grounding rather than a faked primitive.

% --- image_schema (H2): the underlying image schema for an arithmetic practice

% --- multiply_array_witness: the array model's own witness, exposed ----------
% Inputs are integers; the witness takes grounded recollections, so the
% boundary converts them (mirroring the scene compilers' to_rec boundary).


% validate_reader_axioms: SEAM 2. Compare model-emitted reader_axiom/4 facts
% against the modal postures the named lesson's text licenses, so the Prolog
% layer audits a PML reading rather than only re-emitting it.

% --- Canonical vocabulary ops (the legal-vocabulary contract for the loop) ---

% canonical_contract: the legal vocabulary — each canonical query predicate and
% the scattered legacy functors it subsumes. The LLM-facing side reads this to
% know which terms are legal; swipl owns the mapping.
% canonical_check: judge a list of functor-name strings (as the LLM might emit)
% against the legal vocabulary. Each is classified canonical | legacy | unknown,
% with the canonical term it maps to. Module prefixes on legacy functors are
% matched flexibly (bare functor/arity also matches).
dispatch_request(canonical_check, Id, Request, Response) :-
    (   get_dict(terms, Request, Terms), is_list(Terms)
    ->  maplist(classify_canonical_term, Terms, Results),
        ok_response(Id, _{results: Results}, Response)
    ;   error_response(Id, missing_terms,
            "canonical_check requires terms (a list of functor-name strings)", Response)
    ).

% Glyph-level notation scene. kind selects the productive write_equation lane
% or the mirror_written deformation lane; operator is the symbol (+, -, =).
dispatch_request(notation_render, Id, Request, Response) :-
    (   get_dict(kind, Request, Kind0)
    ->  string_or_atom_to_atom(Kind0, Kind),
        notation_render_dispatch(Kind, Id, Request, Response)
    ;   error_response(Id, missing_kind,
            "notation_render requires kind (write_equation or mirror_written)",
            Response)
    ).

notation_render_dispatch(write_equation, Id, Request, Response) :-
    !,
    request_integer(Request, a, 2, A),
    request_integer(Request, b, 3, B),
    request_integer(Request, r, 5, R),
    request_op_atom(Request, operator, +, Op),
    (   notation_scene:notation_render_json(write_equation(A, Op, B, R), Dict0)
    ->  json_safe(Dict0, Dict),
        ok_response(Id, Dict, Response)
    ;   error_response(Id, no_notation_scene,
            "notation_render found no productive write_equation scene for the given fields",
            Response)
    ).
notation_render_dispatch(mirror_written, Id, Request, Response) :-
    !,
    request_integer(Request, digit, 3, Digit),
    request_integer(Request, a, 2, A),
    request_integer(Request, b, 3, B),
    request_integer(Request, r, 5, R),
    request_op_atom(Request, operator, +, Op),
    (   notation_scene:notation_render_json(mirror_written(Digit, A, Op, B, R), Dict0)
    ->  json_safe(Dict0, Dict),
        ok_response(Id, Dict, Response)
    ;   error_response(Id, no_notation_scene,
            "notation_render found no mirror_written deformation scene for the given fields",
            Response)
    ).
notation_render_dispatch(Kind, Id, _Request, Response) :-
    format(string(Msg),
        "notation_render kind '~w' is not supported (use write_equation or mirror_written)",
        [Kind]),
    error_response(Id, unsupported_notation_kind, Msg, Response).

% Same-denominator fraction addition routed to a CGI additive automaton at the
% numerator level. kind names the automaton (e.g. count_on_from_larger).
dispatch_request(fraction_cgi_addition, Id, Request, Response) :-
    (   get_dict(kind, Request, Kind0)
    ->  string_or_atom_to_atom(Kind0, Kind),
        request_integer(Request, na, 7, NA),
        request_integer(Request, nb, 8, NB),
        request_integer(Request, d, 10, D),
        (   fraction_cgi_dispatch:fraction_cgi_addition(
                Kind, fraction(NA, D), fraction(NB, D), Outcome, Annotation)
        ->  json_safe(_{kind: Kind, outcome: Outcome, annotation: Annotation}, Safe),
            ok_response(Id, Safe, Response)
        ;   error_response(Id, no_fraction_cgi_addition,
                "fraction_cgi_addition found no CGI route for that kind and same-denominator pair",
                Response)
        )
    ;   error_response(Id, missing_kind,
            "fraction_cgi_addition requires kind (a CGI addition automaton name)",
            Response)
    ).

% Parametric deformation chart for one IM lesson (covered: the three grade-3
% fraction lessons IM-G3-U5-L1/L2/L15). A code outside coverage fails the
% handler, which surfaces honestly as op_failed.
dispatch_request(lesson_deformation_chart, Id, Request, Response) :-
    (   get_dict(code, Request, Code0)
    ->  atom_string(Code, Code0),
        (   lesson_deformation_chart:monitoring_chart(Code, Chart)
        ->  json_safe(Chart, Safe),
            ok_response(Id, Safe, Response)
        ;   error_response(Id, no_deformation_chart,
                "lesson_deformation_chart covers only the grade-3 fraction lessons; no chart for that code",
                Response)
        )
    ;   error_response(Id, missing_code,
            "lesson_deformation_chart requires code (an IM lesson code)", Response)
    ).

% The notation monitoring chart for one lesson code (183 K/G1 lessons). Mirrors
% lesson_deformation_chart: a missing chart for the code is a clear coverage
% error rather than a silent failure.
dispatch_request(notation_monitoring_chart, Id, Request, Response) :-
    (   get_dict(code, Request, Code0)
    ->  atom_string(Code, Code0),
        (   lesson_notation_chart:notation_monitoring_chart(Code, Chart)
        ->  json_safe(Chart, Safe),
            ok_response(Id, Safe, Response)
        ;   error_response(Id, no_notation_chart,
                "lesson_notation_chart found no notation chart for that code",
                Response)
        )
    ;   error_response(Id, missing_code,
            "notation_monitoring_chart requires code (an IM lesson code)", Response)
    ).

% The Brandomian backstop audit: the per-check report plus the all-pass flag.
% This is how a skeptic queries that the data-driven incompatibility relation is
% non-explosive (and never weaker than the classical floor) through Hermes.
% The deterministic commitment matcher (implicit-commitment stage 1): free
% reading content -> typed canonical commitment terms with witnesses, or an
% honest abstention. The scoreboard layer calls this per event so scorecards
% run on terms the deontic rules actually cover.

% The Brandomian check for one commitment set: the bridge's union incoherence
% (declared hyperedges first, classical neg-pair floor second), the canonical
% incompatibility-entailment pairs that hold inside the set, and the classical
% backstop verdict, in one response. The entailment relation consulted is
% brandomian_incompatibility:incompatibility_entails/2 (quantification over
% DECLARED incompatible sets), not the profile-based relation
% incompatibility_sets exports under the same name; the response carries the
% finite-approximation scope so a caller cannot mistake it for classical
% consequence.
dispatch_request(brandomian_check, Id, Request, Response) :-
    (   get_dict(commitments, Request, CJSON),
        is_list(CJSON),
        CJSON \== []
    ->  json_to_term(CJSON, Commitments0),
        sort(Commitments0, Commitments),
        maplist(term_to_text, Commitments, CommitmentTexts),
        (   sequent_brandom_bridge:b_incoherent(Commitments)
        ->  Incoherent = true,
            brandomian_incoherence_source(Commitments, Source, WitnessEdge)
        ;   Incoherent = false,
            Source = null,
            WitnessEdge = null
        ),
        pairwise_incompatibility_entailments(Commitments, Entailments, Checked),
        queried_entailment(Request, Queried),
        sequent_brandom_bridge:brandom_backstop(BackstopReport),
        (   sequent_brandom_bridge:brandom_backstop_ok
        ->  BackstopOk = true
        ;   BackstopOk = false
        ),
        json_safe(_{ commitments: CommitmentTexts,
                     b_incoherent: Incoherent,
                     incoherence_source: Source,
                     witness_hyperedge: WitnessEdge,
                     entailments: Entailments,
                     entailments_checked: Checked,
                     entailment_scope: "declared incompatible sets only: a finite approximation, complete exactly to the extent the incompatibility data is",
                     queried_entailment: Queried,
                     backstop: _{ok: BackstopOk, checks: BackstopReport}
                   },
                  Safe),
        ok_response(Id, Safe, Response)
    ;   error_response(Id, missing_commitments,
            "brandomian_check requires a non-empty commitments list of term strings",
            Response)
    ).

% Discovered incompatibility hyperedges, surfaced for the console. Rows come
% from the Big Red iteration7 discovery cache (every discovered_set_kind/3
% row, cached kind and file provenance attached) plus the size >= 3
% hyperedges declared in the canonical relation (kind "declared" — where the
% catalogue-attested incommensurability triple lives). Emergence, meaning
% jointly incoherent with NO incoherent proper subset, is COMPUTED per row
% against a runnable relation rather than read off the cache: defeasible rows
% re-run verified_emergent/1 over the combined premise+defeater content set,
% scratch-context rows re-run the bounded discovery classifier on every
% one-element removal, and declared rows check minimality in the canonical
% relation. Optional "kind" filter (emergent / defeated / incoherent /
% nonterminating / declared); default all.
dispatch_request(hyperedges, Id, Request, Response) :-
    request_filter(Request, kind, KindFilter),
    findall(Row, hyperedge_row(KindFilter, Row), Rows),
    length(Rows, RowCount),
    aggregate_all(count,
                  ( member(R, Rows), get_dict(emergent, R, true) ),
                  EmergentCount),
    term_to_text(KindFilter, KindFilterText),
    json_safe(_{ criterion: "size >= 3, jointly incoherent under a runnable relation, every one-element removal coherent",
                 kind_filter: KindFilterText,
                 row_count: RowCount,
                 emergent_count: EmergentCount,
                 hyperedges: Rows },
              Safe),
    ok_response(Id, Safe, Response).

% Runtime axiom toggling over tools/axiom_toggle.pl. Only list/enable/disable
% are exposed: every disable made through the persistent worker stays
% inspectable (list) and reversible (enable) from the same surface. The
% scoped with_axioms_disabled/2 variant stays CLI-only by design; a scoped
% toggle on a persistent worker would be indistinguishable from a leak.
dispatch_request(axiom_toggle, Id, Request, Response) :-
    ensure_axiom_toggle_loaded,
    request_op_atom(Request, action, list, Action),
    axiom_toggle_action(Action, Id, Request, Response).

% =============================================================================
%% Research wing ops (learner)
% =============================================================================

dispatch_request(compute, Id, Request, Response) :-
    ensure_learner_compute_loaded,
    (   learner_compute_request(Request, Op, A, B, Limit, Mode)
    ->  event_log:reset_events,
        learner_run_compute(Mode, Op, A, B, Limit, Success),
        learner_compute_result(Success, Mode, Op, A, B, Limit, Result),
        json_safe(Result, Safe),
        ok_response(Id, Safe, Response)
    ;   error_response(Id, malformed_compute_request,
            "compute requires operation add|subtract|multiply|divide, integer a and b, positive integer limit, and mode direct|developmental",
            Response)
    ).

dispatch_request(knowledge, Id, _Request, Response) :-
    ensure_learner_knowledge_loaded,
    learner_knowledge_rows(Knowledge),
    json_safe(Knowledge, Safe),
    ok_response(Id, Safe, Response).

dispatch_request(visualize_coordination, Id, Request, Response) :-
    ensure_coordination_viz_loaded,
    (   learner_coordination_request(Request, Base, ValUp, ValDown)
    ->  (   unit_coordination_viz:generate_coordination_svg(
                Base, ValUp, ValDown, SVG)
        ->  ok_response(Id,
                _{content_type: "image/svg+xml", svg: SVG}, Response)
        ;   error_response(Id, invalid_visualize_coordination_request,
                "visualize_coordination requires base 2..15, non-negative val_up, and a non-zero denominator",
                Response)
        )
    ;   error_response(Id, malformed_visualize_coordination_request,
            "visualize_coordination requires integer base, non-negative integer val_up, and val_down as a number or fraction string",
            Response)
    ).

dispatch_request(reorganize, Id, Request, Response) :-
    ensure_fraction_band_ladder_loaded,
    (   learner_reorganize_request(Request, DomainAtom, A, B, C, D),
        learner_reorganize_problem(DomainAtom, A, B, C, D, Domain, Problem),
        fraction_band_ladder:story_for(Domain, Problem, Story)
    ->  json_safe(Story, Safe),
        ok_response(Id, Safe, Response)
    ;   error_response(Id, invalid_reorganize_request,
            "Could not run that problem; check the domain and integer inputs (improper fractions require the top number to exceed the bottom).",
            Response)
    ).

dispatch_request(learner_reset, Id, _Request, Response) :-
    ensure_learner_reset_loaded,
    retractall(more_machine_learner:run_learned_strategy(_, _, _, _, _)),
    strategy_synthesis:reset_synthesized_strategies,
    reflective_monitor:reset_success_reflection,
    event_log:reset_events,
    tension_dynamics:reset_tension,
    ok_response(Id, _{status: "reset"}, Response).

% The corpus-attested grammar summary: gap counts rolling up which grammar
% objects the student corpus witnesses and where the grammar runs unattested.

% The strategy elaboration graph: the elaborates/7 facts the analyzer derives
% over the automata. analyze_all/0 is run on demand the first time, when the
% dynamic relation is still empty.

% On-demand proof entitlement for an arithmetic fact via the carving surface.
% operation is add/sub/mult/div/frac; x, y, z are the fact arguments.
% Bounded carving summary for one operation: carved-fact count and residue.
% Benny's deformed rules side by side with their correct coordinated
% counterparts on shared inputs. Public encyclopedia surface; no student data.
% Machine-readable inventory of dispatch operations and shipped Prolog modules.
dispatch_request(capability_atlas, Id, _Request, Response) :-
    findall(Row, capability_atlas_row(Row), Rows),
    capability_status_count(routed_paged, RoutedPaged),
    capability_status_count(routed_only, RoutedOnly),
    capability_status_count(unrouted, Unrouted),
    capability_status_count(lazy_reachable, LazyReachable),
    capability_status_count(orphan_module, OrphanModules),
    ok_response(Id,
        _{ capabilities: Rows,
           counts: _{ routed_paged: RoutedPaged,
                      routed_only: RoutedOnly,
                      unrouted: Unrouted,
                      lazy_reachable: LazyReachable,
                      orphan_module: OrphanModules
                    }
         },
        Response).

capability_atlas_row(_{
    name: NameText,
    module: ModuleText,
    role: RoleText,
    inputs: InputTexts,
    surface_status: StatusText,
    route: Routes,
    pages: PageTexts,
    lazy_via: LazyViaTexts
}) :-
    capability_registry:capability(Name, Module, Role, Inputs, Status),
    atom_string(Name, NameText),
    atom_string(Module, ModuleText),
    atom_string(Role, RoleText),
    maplist(atom_string, Inputs, InputTexts),
    atom_string(Status, StatusText),
    findall(_{method: MethodText, path: PathText},
            ( capability_registry:capability_route(Name, Method, Path),
              atom_string(Method, MethodText),
              atom_string(Path, PathText)
            ),
            Routes),
    findall(PageText,
            ( capability_registry:capability_page(Name, Page),
              atom_string(Page, PageText)
            ),
            PageTexts),
    findall(OpText,
            ( capability_registry:capability_lazy_via(Name, Op),
              atom_string(Op, OpText)
            ),
            LazyViaTexts).

capability_status_count(Status, Count) :-
    aggregate_all(count,
                  capability_registry:capability(_, _, _, _, Status),
                  Count).

classify_canonical_term(T, _{term: T, status: Status, canonical: Canon}) :-
    atom_string(A, T),
    canonical_base_name(A, Base),
    (   canonical_label_for(Base, C)
    ->  Status = "canonical", term_string(C, Canon)
    ;   canonical_legacy_match(A, C)
    ->  Status = "legacy", term_string(C, Canon)
    ;   Status = "unknown", Canon = null
    ).

% Strip a trailing /Arity if present.
canonical_base_name(A, Base) :-
    (   atomic_list_concat([B, _Arity], '/', A) -> Base = B ; Base = A ).

% A base name is canonical if it is a contract label, OR that label + '_unified'
% (the family query predicates are <concept>_unified; wave 1 uses the bare name).
canonical_label_for(Base, C) :-
    canonical_all:contract(C, _, _),
    ( C == Base ; atom_concat(C, '_unified', Base) ),
    !.

canonical_legacy_match(A, Canon) :-
    canonical_all:legacy_term(Legacy, Canon),
    (   Legacy == A
    ;   atomic_list_concat(Parts, ':', Legacy), last(Parts, Bare), Bare == A
    ),
    !.

% Thin call/response adapters for spec rows whose historical clause did more
% than expose a single predicate-owned witness. They do not read Request; all
% boundary inputs remain explicit in dispatch_spec.pl.
standard_k_ns_2_dispatch_witness(Count, Witness) :-
    Count >= 0,
    Count =< 20,
    length(Objects, Count),
    standard_k_ns_2:teach_numerals_to_witness(20, _TeachWitness),
    standard_k_ns_2:represent_count_witness(
        Objects, _Recollection, _Name, Witness).

standard_3_ca_5_dispatch_witness(Factor, Times, Witness) :-
    standard_3_ca_5:mult_skip_count(Factor, Times, Product),
    recollection_to_integer(Factor, FactorCount),
    recollection_to_integer(Times, TimesCount),
    recollection_to_integer(Product, ProductCount),
    Witness = _{
        kind: standard_3_ca_5_mult_skip_count,
        scope: closed_world_finite_standard_3_ca_5_multiplication_within_100,
        standard: in_3_ca_5,
        source_predicate: mult_skip_count/3,
        factor: Factor,
        times: Times,
        product: Product,
        factor_count: FactorCount,
        times_count: TimesCount,
        product_count: ProductCount,
        derivation: repeated_grounded_addition_by_skip_counting,
        boundary: supplied_recollection_inputs_and_existing_standard_3_ca_5_predicate
    }.

multiply_array_dispatch_witness(Rows, Cols, Witness) :-
    integer_to_recollection(Rows, RowsRec),
    integer_to_recollection(Cols, ColsRec),
    standard_3_ca_3_4:multiply_array_witness(
        RowsRec, ColsRec, _Product, Witness).

mult_div_family_dispatch_witness(A, B, Witness) :-
    integer_to_recollection(A, ARec),
    integer_to_recollection(B, BRec),
    standard_3_ca_3_4:mult_div_family_witness(
        ARec, BRec, _Product, _Facts, Witness).

commitment_match_dispatch_dict(Content, Dict) :-
    findall(_{ term: TermText,
               source: SourceText,
               matched_tokens: TokenTexts },
            ( commitment_matcher:match_commitment_witness(Content, Term, W),
              term_to_text(Term, TermText),
              get_dict(source, W, Source),
              term_to_text(Source, SourceText),
              get_dict(matched_tokens, W, Tokens),
              maplist(term_to_text, Tokens, TokenTexts)
            ),
            Matches0),
    sort(Matches0, Matches),
    ( Matches == [] -> Abstained = true ; Abstained = false ),
    Dict = _{matches: Matches, abstained: Abstained}.

elaborations_dispatch_dict(Safe) :-
    (   automaton_analyzer:elaborates(_, _, _, _, _, _, _)
    ->  true
    ;   automaton_analyzer:analyze_all
    ),
    automaton_analyzer:all_elaborations(Elaborations),
    json_safe(Elaborations, Safe).

image_schema_dispatch_dict(Practice, Dict) :-
    atom_string(Practice, PracticeStr),
    (   grounding_to_primitive:image_schema_for_practice(Practice, Schema)
    ->  atom_string(Schema, SchemaStr),
        Dict = _{practice: PracticeStr, image_schema: SchemaStr}
    ;   Dict = _{ practice: PracticeStr,
                  image_schema: null,
                  note: "no_image_schema_grounding" }
    ).

primitive_for_practice_dispatch_dict(Practice, Dict) :-
    atom_string(Practice, PracticeStr),
    (   grounding_to_primitive:primitive_for_practice_witness(
            Practice, Primitive, Role, Witness)
    ->  json_safe(Witness, SafeWitness),
        atom_string(Primitive, PrimStr),
        atom_string(Role, RoleStr),
        ( get_dict(grounding_metaphor_label, Witness, Label0)
        -> atom_string(Label0, LabelStr)
        ;  LabelStr = null ),
        Dict = _{ practice: PracticeStr,
                  visual_primitive: PrimStr,
                  grounding_metaphor_label: LabelStr,
                  role: RoleStr,
                  witness: SafeWitness }
    ;   Dict = _{ practice: PracticeStr,
                  visual_primitive: null,
                  grounding_metaphor_label: null,
                  note: "no_metaphor_grounding" }
    ).

representation_spine_dispatch_witness(Concept, Witness) :-
    findall(_{concept: Concept, surface: Surface, data_shape: Shape},
            representation_spine:renders_on(Concept, Surface, Shape),
            Routes),
    (   nonvar(Concept)
    ->  findall(_{asset: Asset, provenance: Prov},
                representation_spine:asset_for(Concept, Asset, Prov), Assets0),
        length(Assets0, AssetCount),
        (   length(Capped, 20), append(Capped, _, Assets0)
        ->  Assets = Capped
        ;   Assets = Assets0
        )
    ;   Assets = [], AssetCount = 0
    ),
    ( Routes \== [] ; Assets \== [] ),
    Witness = _{renders_on: Routes, assets: Assets, asset_count: AssetCount}.

misconception_pml_map_dispatch_dict(Value, Dict) :-
    (   Value == null
    ->  Filter = ""
    ;   text_value(Value, Filter)
    ),
    findall(_{source_tag: SourceText,
              misconception: NameText,
              operator: OperatorText},
            ( pml_wire:misconception_pml(Source, Operator),
              sub_term(unlicensed(Name), Operator),
              term_to_text(Name, NameText),
              ( Filter == "" ; Filter == NameText ),
              term_to_text(Source, SourceText),
              term_to_text(Operator, OperatorText)
            ),
            Pairs),
    length(Pairs, Count),
    Dict = _{
        count: Count,
        pairs: Pairs,
        provenance: "generated from CONNECTS-TO annotations in the misconception registry"
    }.

batch_event_score_dispatch_dict(Events, Scores) :-
    maplist(hermes_event_scoring:score_event, Events, Scores).

pair_graph_dispatch_dict(Events, Graph) :-
    hermes_pair_scoring:score_pair_candidates(Events, Pairs),
    hermes_pair_scoring:pair_graph(Pairs, Graph).

expressive_power_dispatch_dict(Code, Dict) :-
    (   lesson_expressive_power_for(Code, Report)
    ->  Resolved = true
    ;   Report = none,
        Resolved = false
    ),
    expressive_power_export_dict(Report, Power),
    atom_string(Code, CodeString),
    Dict = _{lesson: CodeString, resolved: Resolved, expressive_power: Power}.

canonical_contract_dispatch_dict(Dict) :-
    findall(_{canonical: CS, module: MS, legacy: LS},
            ( canonical_all:contract(C, M, L),
              term_string(C, CS),
              term_string(M, MS),
              maplist(term_string, L, LS)
            ),
            Entries),
    length(Entries, N),
    Dict = _{vocabulary: Entries, count: N}.

brandom_backstop_dispatch_dict(Dict) :-
    sequent_brandom_bridge:brandom_backstop(Report),
    (   sequent_brandom_bridge:brandom_backstop_ok
    ->  Ok = true
    ;   Ok = false
    ),
    Dict = _{ok: Ok, checks: Report}.

carving_strategy_proof_dispatch_dict(Op, X, Y, Z, Dict) :-
    findall(P,
            carving_query:carving_strategy_proof(Op, X, Y, Z, P),
            Proofs),
    Proofs \== [],
    Dict = _{operation: Op, x: X, y: Y, z: Z, proofs: Proofs}.

% A response hook preserves a legacy response shape when the generic call
% frame itself would be observable. The geometry coverage witness contains
% Authored table dispatch. The 26 render operations and 29 irregular operations
% remain bespoke by design; spec-backed operations commit here before the
% catch-all.
dispatch_request(Op, Id, Request, Response) :-
    dispatch_spec(Op, Inputs, Call, Result),
    !,
    (   read_dispatch_inputs(Inputs, Request, Bound)
    ->  run_dispatch_call(Call, Bound, Outcome),
        treat_dispatch_result(Result, Op, Id, Outcome, Response)
    ;   dispatch_input_failure_response(Result, Op, Id, Response)
    ).

% Every converter named in the loaded spec must have a
% convert_dispatch_input/3 clause; a typo would otherwise surface only as a
% permanent malformed reply. Checked once at load, loudly.
validate_dispatch_spec :-
    forall(
        ( dispatch_spec(SpecOp, Inputs, _, _), member(_Key-Conv, Inputs) ),
        ( dispatch_converter_name(Conv, Converter),
          known_dispatch_converter(Converter)
        -> true
        ;  format(user_error,
                  "dispatch_spec ~w names unknown converter ~w~n",
                  [SpecOp, Conv]),
           throw(error(domain_error(dispatch_converter, Conv), SpecOp))
        )
    ).

dispatch_converter_name(default(Converter, _Default), Converter) :- !.
dispatch_converter_name(fallback(Converter, _Default), Converter) :- !.
dispatch_converter_name(Converter, Converter).

known_dispatch_converter(term).
known_dispatch_converter(atom).
known_dispatch_converter(code).
known_dispatch_converter(string).
known_dispatch_converter(dict).
known_dispatch_converter(json).
known_dispatch_converter(json_list).
known_dispatch_converter(filter).
known_dispatch_converter(op_atom).
known_dispatch_converter(nonempty_text).
known_dispatch_converter(optional_code).
known_dispatch_converter(practice).
known_dispatch_converter(int).
known_dispatch_converter(int(_, _)).
known_dispatch_converter(number).
known_dispatch_converter(recollection).
known_dispatch_converter(fraction).
known_dispatch_converter(list).

read_dispatch_inputs([], _Request, []).
read_dispatch_inputs([Key-default(Converter, Default)|Specs], Request,
        [Key-Value|Bound]) :-
    !,
    (   get_dict(Key, Request, JSONValue)
    ->  dispatch_supplied_default_input(
            Converter, JSONValue, Default, Value)
    ;   dispatch_default_input(Converter, Default, Value)
    ),
    read_dispatch_inputs(Specs, Request, Bound).
read_dispatch_inputs([Key-fallback(Converter, Default)|Specs], Request,
        [Key-Value|Bound]) :-
    get_dict(Key, Request, JSONValue),
    (   convert_dispatch_input(Converter, JSONValue, Value)
    ->  true
    ;   dispatch_default_input(Converter, Default, Value)
    ),
    read_dispatch_inputs(Specs, Request, Bound).
read_dispatch_inputs([Key-Converter|Specs], Request, [Key-Value|Bound]) :-
    get_dict(Key, Request, JSONValue),
    convert_dispatch_input(Converter, JSONValue, Value),
    read_dispatch_inputs(Specs, Request, Bound).

convert_dispatch_input(term, JSON, Value) :-
    json_to_term(JSON, Value).
convert_dispatch_input(atom, JSON, Value) :-
    json_to_term(JSON, Value0),
    string_or_atom_to_atom(Value0, Value).
convert_dispatch_input(code, JSON, Value) :-
    atom_string(Value, JSON).
convert_dispatch_input(string, Value, Value).
convert_dispatch_input(dict, Value, Value).
convert_dispatch_input(json, Value, Value).
convert_dispatch_input(json_list, Value, Value) :-
    is_list(Value).
convert_dispatch_input(filter, Value, Filter) :-
    Value \== "",
    Value \== null,
    atom_string(Atom, Value),
    downcase_atom(Atom, Filter).
convert_dispatch_input(op_atom, Value, Atom) :-
    Value \== "",
    string_or_atom_to_atom(Value, Atom0),
    downcase_atom(Atom0, Atom).
convert_dispatch_input(nonempty_text, Value, Text) :-
    Value \== null,
    text_value(Value, Text),
    Text \== "".
convert_dispatch_input(optional_code, Value, Atom) :-
    Value \== null,
    Value \== "",
    string_or_atom_to_atom(Value, Atom).
convert_dispatch_input(practice, Value, Practice) :-
    Value \== null,
    Value \== "",
    string_or_atom_to_atom(Value, Practice).
convert_dispatch_input(int, JSON, Value) :-
    dispatch_integer(JSON, Value).
convert_dispatch_input(number, Value, Value) :-
    number(Value).
convert_dispatch_input(int(Low, High), JSON, Value) :-
    dispatch_integer(JSON, Value),
    Value >= Low,
    ( High == inf -> true ; Value =< High ).
convert_dispatch_input(recollection, JSON, Recollection) :-
    (   json_to_term(JSON, Term), Term = recollection(_)
    ->  Recollection = Term
    ;   dispatch_integer(JSON, N),
        integer_to_recollection(N, Recollection)
    ).
convert_dispatch_input(fraction, JSON, Fraction) :-
    fraction_request_value(JSON, Fraction).
convert_dispatch_input(list, JSON, List) :-
    json_to_term(JSON, List),
    is_list(List).

dispatch_default_input(_Converter, Default, Default) :-
    var(Default),
    !.
dispatch_default_input(Converter, Default, Value) :-
    convert_dispatch_input(Converter, Default, Value).

dispatch_supplied_default_input(recollection, JSON, Default, Value) :-
    !,
    (   json_to_term(JSON, Term), Term = recollection(_)
    ->  Value = Term
    ;   dispatch_integer(JSON, N)
    ->  integer_to_recollection(N, Value)
    ;   dispatch_default_input(recollection, Default, Value)
    ).
dispatch_supplied_default_input(Converter, JSON, Default, Value) :-
    (   convert_dispatch_input(Converter, JSON, Value)
    ->  true
    ;   dispatch_default_input(Converter, Default, Value)
    ).

dispatch_integer(Value, Value) :-
    integer(Value),
    !.
dispatch_integer(Value, Integer) :-
    ( string(Value) ; atom(Value) ),
    atom_number(Value, Number),
    integer(Number),
    Integer = Number.

run_dispatch_call(call(Module:Pred, ArgSpec), Bound, Outcome) :-
    dispatch_call_args(ArgSpec, Bound, Args, Outputs),
    Goal =.. [Pred|Args],
    (   call(Module:Goal)
    ->  Outcome = success(Outputs)
    ;   Outcome = failure
    ).
run_dispatch_call(call(Module:Pred, ArgSpec, [gate(axiom_pack(Pack))]),
        Bound, Outcome) :-
    (   sequent_engine:enabled_axiom_pack(Pack)
    ->  run_dispatch_call(call(Module:Pred, ArgSpec), Bound, Outcome)
    ;   Outcome = axiom_pack_disabled(Pack)
    ).

dispatch_call_args([], _Bound, [], []).
dispatch_call_args([Spec|Specs], Bound, [Arg|Args], Outputs) :-
    dispatch_call_arg(Spec, Bound, Arg, Outputs, Rest),
    dispatch_call_args(Specs, Bound, Args, Rest).

dispatch_call_arg(drop, _Bound, _Arg, Outputs, Outputs) :- !.
dispatch_call_arg(out(Name), _Bound, Arg, [Name-Arg|Outputs], Outputs) :- !.
dispatch_call_arg(const(Value), _Bound, Value, Outputs, Outputs) :- !.
dispatch_call_arg(Key, Bound, Value, Outputs, Outputs) :-
    memberchk(Key-Value, Bound).

treat_dispatch_result(_Result, _Op, Id, axiom_pack_disabled(Pack), Response) :-
    axiom_pack_disabled_response(Pack, Id, Response),
    !.
treat_dispatch_result(witness(_NoWitness), _Op, Id, success(Outputs), Response) :-
    memberchk(witness-Witness, Outputs),
    json_safe(Witness, Safe),
    ok_response(Id, Safe, Response),
    !.
treat_dispatch_result(witness(NoWitness), Op, Id, failure, Response) :-
    dispatch_message(Op, no_witness, Message),
    error_response(Id, NoWitness, Message, Response).
treat_dispatch_result(witness(_NoWitness, _Malformed), _Op, Id,
        success(Outputs), Response) :-
    memberchk(witness-Witness, Outputs),
    json_safe(Witness, Safe),
    ok_response(Id, Safe, Response),
    !.
treat_dispatch_result(witness(NoWitness, _Malformed), Op, Id, failure, Response) :-
    dispatch_message(Op, no_witness, Message),
    error_response(Id, NoWitness, Message, Response).
treat_dispatch_result(witness_wrap(Fields, _NoWitness), _Op, Id,
        success(Outputs), Response) :-
    memberchk(witness-Witness, Outputs),
    dispatch_wrap_fields(Fields, Outputs, Wrapped0),
    Wrapped = Wrapped0.put(witness, Witness),
    json_safe(Wrapped, Safe),
    ok_response(Id, Safe, Response),
    !.
treat_dispatch_result(witness_wrap(_Fields, NoWitness), Op, Id, failure, Response) :-
    dispatch_message(Op, no_witness, Message),
    error_response(Id, NoWitness, Message, Response).
treat_dispatch_result(witness_wrap(Fields, _NoWitness, _Malformed), _Op, Id,
        success(Outputs), Response) :-
    memberchk(witness-Witness, Outputs),
    dispatch_wrap_fields(Fields, Outputs, Wrapped0),
    Wrapped = Wrapped0.put(witness, Witness),
    json_safe(Wrapped, Safe),
    ok_response(Id, Safe, Response),
    !.
treat_dispatch_result(witness_wrap(_Fields, NoWitness, _Malformed), Op, Id,
        failure, Response) :-
    dispatch_message(Op, no_witness, Message),
    error_response(Id, NoWitness, Message, Response).
treat_dispatch_result(witness_errorless(_Malformed), _Op, Id,
        success(Outputs), Response) :-
    memberchk(witness-Witness, Outputs),
    json_safe(Witness, Safe),
    ok_response(Id, Safe, Response),
    !.
treat_dispatch_result(witness_errorless(_Malformed), _Op, _Id,
        failure, _Response) :-
    fail.
treat_dispatch_result(witness_input_errorless(_NoWitness), _Op, Id,
        success(Outputs), Response) :-
    memberchk(witness-Witness, Outputs),
    json_safe(Witness, Safe),
    ok_response(Id, Safe, Response),
    !.
treat_dispatch_result(witness_input_errorless(NoWitness), Op, Id,
        failure, Response) :-
    dispatch_message(Op, no_witness, Message),
    error_response(Id, NoWitness, Message, Response).
treat_dispatch_result(witness_wrap_errorless(Fields, _Malformed), _Op, Id,
        success(Outputs), Response) :-
    memberchk(witness-Witness, Outputs),
    dispatch_wrap_fields(Fields, Outputs, Wrapped0),
    Wrapped = Wrapped0.put(witness, Witness),
    json_safe(Wrapped, Safe),
    ok_response(Id, Safe, Response),
    !.
treat_dispatch_result(witness_wrap_errorless(_Fields, _Malformed), _Op, _Id,
        failure, _Response) :-
    fail.
treat_dispatch_result(raw, _Op, Id, success(Outputs), Response) :-
    memberchk(dict-Dict, Outputs),
    ok_response(Id, Dict, Response).
treat_dispatch_result(raw(_Malformed), _Op, Id, success(Outputs), Response) :-
    memberchk(dict-Dict, Outputs),
    ok_response(Id, Dict, Response).
treat_dispatch_result(raw(_NoResult, _Malformed), _Op, Id,
        success(Outputs), Response) :-
    memberchk(dict-Dict, Outputs),
    ok_response(Id, Dict, Response).
treat_dispatch_result(raw(NoResult, _Malformed), Op, Id, failure, Response) :-
    dispatch_message(Op, no_result, Message),
    error_response(Id, NoResult, Message, Response).
treat_dispatch_result(raw_safe, _Op, Id, success(Outputs), Response) :-
    memberchk(dict-Dict, Outputs),
    json_safe(Dict, Safe),
    ok_response(Id, Safe, Response).
treat_dispatch_result(raw_safe(_Malformed), _Op, Id, success(Outputs), Response) :-
    memberchk(dict-Dict, Outputs),
    json_safe(Dict, Safe),
    ok_response(Id, Safe, Response).
treat_dispatch_result(raw_safe(_NoResult, _Malformed), _Op, Id,
        success(Outputs), Response) :-
    memberchk(dict-Dict, Outputs),
    json_safe(Dict, Safe),
    ok_response(Id, Safe, Response).
treat_dispatch_result(raw_safe(NoResult, _Malformed), Op, Id,
        failure, Response) :-
    dispatch_message(Op, no_result, Message),
    error_response(Id, NoResult, Message, Response).

dispatch_wrap_fields([], _Outputs, _{}).
dispatch_wrap_fields([Label-Slot|Fields], Outputs, Dict) :-
    memberchk(Slot-Value, Outputs),
    dispatch_wrap_fields(Fields, Outputs, Rest),
    Dict = Rest.put(Label, Value).

dispatch_malformed_response(Result, Op, Id, Response) :-
    (   dispatch_result_malformed_code(Result, Code)
    ->  true
    ;   atom_concat(Base, '_witness', Op)
    ->  true
    ;   Base = Op
    ),
    (   var(Code)
    ->  atomic_list_concat([malformed, Base, request], '_', Code)
    ;   true
    ),
    dispatch_message(Op, malformed, Message),
    error_response(Id, Code, Message, Response).

dispatch_result_malformed_code(witness(_, Code), Code).
dispatch_result_malformed_code(witness_wrap(_, _, Code), Code).
dispatch_result_malformed_code(witness_errorless(Code), Code).
dispatch_result_malformed_code(witness_wrap_errorless(_, Code), Code).
dispatch_result_malformed_code(raw(Code), Code).
dispatch_result_malformed_code(raw_safe(Code), Code).
dispatch_result_malformed_code(raw(_, Code), Code).
dispatch_result_malformed_code(raw_safe(_, Code), Code).

dispatch_input_failure_response(witness_input_errorless(_), _Op, _Id,
        _Response) :-
    !,
    fail.
dispatch_input_failure_response(Result, Op, Id, Response) :-
    dispatch_malformed_response(Result, Op, Id, Response).

% Catch-all: only genuinely unknown ops reach here. The \+ known_op/1 guard
% stops a KNOWN op whose body failed from backtracking into this clause; that
% case falls through to op_failed in handle_request/2, so the worker no longer
% mislabels a failed handler as "unknown_op".
dispatch_request(Op, Id, _Request, Response) :-
    \+ known_op(Op),
    format(string(Message), "Unsupported op: ~w", [Op]),
    error_response(Id, unknown_op, Message, Response).

%!  request_filter(+Request, +Key, -Filter) is det.
%
%   An optional string filter under Key, normalised to a lowercase atom, or
%   the atom `all` when absent/null/empty.
request_filter(Request, Key, Filter) :-
    (   get_dict_opt(Key, Request, Value),
        Value \== "",
        atom_string(Atom, Value)
    ->  downcase_atom(Atom, Filter)
    ;   Filter = all
    ).

%!  request_integer(+Request, +Key, +Default, -N) is det.
%
%   An optional integer under Key. Accepts a JSON number or a numeric string
%   (the viewer passes query-string values as strings); falls back to Default
%   when absent or unparseable.
request_integer(Request, Key, Default, N) :-
    (   get_dict_opt(Key, Request, Value)
    ->  ( integer(Value)
        -> N = Value
        ;  ( string(Value) ; atom(Value) ),
           atom_number(Value, Num), integer(Num)
        -> N = Num
        ;  N = Default
        )
    ;   N = Default
    ).

%!  request_recollection(+Request, +Key, +DefaultInt, -Recollection) is det.
%
%   Public worker callers should not have to spell grounded recollections for
%   the elementary-standard witnesses; accept the integer boundary and convert
%   it at the Prolog edge. Legacy grounded-term strings remain accepted.
request_recollection(Request, Key, Default, Recollection) :-
    (   get_dict_opt(Key, Request, Value),
        json_to_term(Value, Term),
        Term = recollection(_)
    ->  Recollection = Term
    ;   request_integer(Request, Key, Default, N),
        integer_to_recollection(N, Recollection)
    ).

%!  request_fraction(+Request, +Key, +Default, -Fraction) is det.
%
%   Accept an n/d string or a JSON {n,d} object and construct the grounded
%   fraction at the Prolog edge. Legacy grounded-term strings remain accepted.
request_fraction(Request, Key, Default, Fraction) :-
    (   get_dict_opt(Key, Request, Value),
        fraction_request_value(Value, Parsed)
    ->  Fraction = Parsed
    ;   fraction_request_value(Default, Fraction)
    ).

fraction_request_value(Value, Fraction) :-
    json_to_term(Value, Term),
    Term = fraction(_, _),
    !,
    Fraction = Term.
fraction_request_value(Value, fraction(Numerator, Denominator)) :-
    is_dict(Value),
    request_integer(Value, n, 0, N),
    request_integer(Value, d, 1, D),
    integer_to_recollection(N, Numerator),
    integer_to_recollection(D, Denominator).
fraction_request_value(Value, fraction(Numerator, Denominator)) :-
    ( string(Value) ; atom(Value) ),
    split_string(Value, "/", " \t", [NString, DString]),
    number_string(N, NString),
    number_string(D, DString),
    integer(N),
    integer(D),
    integer_to_recollection(N, Numerator),
    integer_to_recollection(D, Denominator).

% =============================================================================
% Render-op support: request -> compiler Spec, and the additive-field threading
% (doc.grounding, doc.tuple, doc.teacher) the frozen render contract names.
% =============================================================================

%!  request_op_atom(+Request, +Key, +Default, -Atom) is det.
%   An optional string/atom under Key, normalised to a lowercase atom.
request_op_atom(Request, Key, Default, Atom) :-
    (   get_dict_opt(Key, Request, Value), Value \== ""
    ->  string_or_atom_to_atom(Value, A0), downcase_atom(A0, Atom)
    ;   Atom = Default
    ).

%!  request_string_atom(+Request, +Key, +Default, -Atom) is det.
%   An optional string/atom under Key, normalised to an atom (case preserved —
%   strategy ids and practice atoms are case-significant).
request_string_atom(Request, Key, Default, Atom) :-
    (   get_dict_opt(Key, Request, Value), Value \== ""
    ->  string_or_atom_to_atom(Value, Atom)
    ;   Atom = Default
    ).

%!  request_practice(+Request, -Practice) is semidet.
%   The practice atom for the H3/teacher ops. Read from the `practice` field.
request_practice(Request, Practice) :-
    get_dict_opt(practice, Request, Value),
    Value \== "",
    string_or_atom_to_atom(Value, Practice).

%!  request_lesson_context(+Request, -LessonContext) is det.
%   The compact lesson context that representation_grammar:visual_candidate/5
%   consumes: grade plus standards. This is deliberately not a full lesson
%   object; the grammar owns the selection judgment.
request_lesson_context(Request, lesson_context(Grade, Standards)) :-
    (   get_dict_opt(lesson_code, Request, LessonCode0),
        string_or_atom_to_atom(LessonCode0, LessonCode),
        lesson_context_for_code(LessonCode, lesson_context(Grade, Standards))
    ->  true
    ;   request_string_atom(Request, grade, unknown_grade, Grade),
        request_standards(Request, Standards)
    ).

request_lesson_selector(Request, lesson_code(LessonCode)) :-
    get_dict_opt(lesson_code, Request, LessonCode0),
    string_or_atom_to_atom(LessonCode0, LessonCode),
    !.
request_lesson_selector(_, none).

request_standards(Request, Standards) :-
    (   get_dict_opt(standards, Request, Values),
        is_list(Values)
    ->  maplist(string_or_atom_to_atom, Values, Standards)
    ;   Standards = []
    ).

lesson_context_for_code(Code, lesson_context(GradeContext, StandardAliases)) :-
    lesson_monitoring:monitoring_chart(
        Code,
        monitoring_chart(Code, Lesson, Standards, _Strategies, _Misconceptions, _PMLFacts)
    ),
    lesson_grade_context(Lesson, GradeContext),
    lesson_standard_aliases(Standards, StandardAliases).

lesson_grade_context(lesson(_ConceptId, _Title, Grade, _Unit, _LessonNumber), GradeContext) :-
    grade_term_context(Grade, GradeContext).

grade_term_context(grade(N), GradeContext) :-
    integer(N),
    !,
    format(atom(GradeContext), 'grade_~w', [N]).
grade_term_context(grade(k), kindergarten) :- !.
grade_term_context(grade('K'), kindergarten) :- !.
grade_term_context(kindergarten, kindergarten) :- !.
grade_term_context(Grade, GradeContext) :-
    string_or_atom_to_atom(Grade, GradeContext).

lesson_standard_aliases(Standards, Aliases) :-
    findall(Alias,
            ( member(Standard, Standards),
              chart_standard_alias(Standard, Alias)
            ),
            Aliases0),
    sort(Aliases0, Aliases).

chart_standard_alias(standard(_Framework, Code, _Statement), Alias) :-
    standard_code_alias(Code, Alias).

standard_code_alias(Code0, Alias) :-
    string_or_atom_to_atom(Code0, CodeAtom0),
    downcase_atom(CodeAtom0, CodeAtom),
    atomic_list_concat(Parts, '.', CodeAtom),
    atomic_list_concat(Parts, '_', Alias).

%!  representation_task(+Request, -Task) is semidet.
%   Parse the public representation_check task vocabulary into the Prolog term
%   the representation grammar reasons over.
representation_task(Request, Task) :-
    request_op_atom(Request, task, whole_number, TaskKind),
    representation_task_for(TaskKind, Request, Task).

representation_task_for(whole_number, Request, whole_number(N)) :- !,
    request_integer(Request, n, 0, N).
representation_task_for(whole_number_addition, Request, whole_number_addition(A, B)) :- !,
    request_integer(Request, a, 0, A),
    request_integer(Request, b, 0, B).
representation_task_for(whole_number_subtraction, Request, whole_number_subtraction(A, B)) :- !,
    request_integer(Request, a, 0, A),
    request_integer(Request, b, 0, B).
representation_task_for(kindergarten_counting_collection, Request, kindergarten_counting_collection(N)) :- !,
    request_integer(Request, n, 0, N).
representation_task_for(fraction, Request, fraction(N, D)) :- !,
    request_integer(Request, n, 1, N),
    request_integer(Request, d, 2, D).
representation_task_for(fraction_addition, Request,
        fraction_addition(fraction(NA, DA), fraction(NB, DB))) :- !,
    request_integer(Request, na, 1, NA),
    request_integer(Request, da, 3, DA),
    request_integer(Request, nb, 1, NB),
    request_integer(Request, db, 4, DB).
representation_task_for(array, Request, array(Rows, Cols)) :- !,
    request_integer(Request, rows, 3, Rows),
    request_integer(Request, cols, 4, Cols).
representation_task_for(multiplication, Request, multiplication(A, B)) :- !,
    request_integer(Request, a, 3, A),
    request_integer(Request, b, 4, B).
representation_task_for(fraction_product, Request, fraction_product(NA, DA, NB, DB)) :- !,
    request_integer(Request, na, 1, NA),
    request_integer(Request, da, 2, DA),
    request_integer(Request, nb, 1, NB),
    request_integer(Request, db, 3, DB).
representation_task_for(equation_linear, Request, equation(linear(A, B, C))) :- !,
    request_integer(Request, a, 2, A),
    request_integer(Request, b, 3, B),
    request_integer(Request, c, 11, C).

representation_check_dict(calculator, Representation, Task, Dict) :- !,
    (   representation_grammar:calculator_refusal(Task, Representation, Reason)
    ->  representation_rejection_dict(calculator, Representation, Task, Reason, Dict)
    ;   representation_grammar:calculator_visual(
            Task,
            Representation,
            scene(Representation, Task),
            Answer
        )
    ->  representation_acceptance_dict(calculator, Representation, Task, Dict0),
        term_to_text(Answer, AnswerText),
        Dict = Dict0.put(answer, AnswerText)
    ;   Reason = reason(no_productive_grammar_for_task(Representation, Task)),
        representation_rejection_dict(calculator, Representation, Task, Reason, Dict)
    ).
representation_check_dict(productive, Representation, Task, Dict) :- !,
    (   representation_grammar:representation_refusal(Representation, Task, Reason)
    ->  representation_rejection_dict(productive, Representation, Task, Reason, Dict)
    ;   representation_grammar:productive_visual(
            Task,
            Representation,
            scene(Representation, Task)
        )
    ->  representation_acceptance_dict(productive, Representation, Task, Dict)
    ;   Reason = reason(no_productive_grammar_for_task(Representation, Task)),
        representation_rejection_dict(productive, Representation, Task, Reason, Dict)
    ).
representation_check_dict(Mode, Representation, Task, Dict) :-
    Reason = reason(unsupported_representation_check_mode(Mode)),
    representation_rejection_dict(Mode, Representation, Task, Reason, Dict).

representation_acceptance_dict(Mode, Representation, Task, Dict) :-
    atom_string(Mode, ModeText),
    atom_string(Representation, RepresentationText),
    term_to_text(Task, TaskText),
    representation_grounding_text(Representation, GroundingText),
    Dict = _{
        mode: ModeText,
        representation: RepresentationText,
        task: TaskText,
        allowed: true,
        grounding: GroundingText
    }.

representation_rejection_dict(Mode, Representation, Task, Reason, Dict) :-
    atom_string(Mode, ModeText),
    atom_string(Representation, RepresentationText),
    term_to_text(Task, TaskText),
    term_to_text(Reason, ReasonText),
    representation_preference_dict(Task, Preferred),
    Dict = _{
        mode: ModeText,
        representation: RepresentationText,
        task: TaskText,
        allowed: false,
        refusal: ReasonText,
        preferred: Preferred
    }.

representation_preference_dict(Task, Preferred) :-
    (   representation_grammar:preferred_representation(Task, Rep, Reason)
    ->  atom_string(Rep, RepText),
        term_to_text(Reason, ReasonText),
        Preferred = _{representation: RepText, reason: ReasonText}
    ;   Preferred = _{}
    ).

representation_grounding_text(Representation, GroundingText) :-
    (   representation_grammar:representation_grounding(Representation, Grounding)
    ->  term_to_text(Grounding, GroundingText)
    ;   GroundingText = ""
    ).

representation_candidates_dict(SelectorSource, LessonContext, Task, Strategy, Misconception, Dict) :-
    findall(Candidate,
            representation_candidate_dict(
                LessonContext,
                Task,
                Strategy,
                Misconception,
                Candidate
            ),
            Candidates0),
    sort(Candidates0, Candidates),
    findall(Refusal,
            representation_refusal_dict(
                LessonContext,
                Task,
                Strategy,
                Misconception,
                Refusal
            ),
            Refusals0),
    sort(Refusals0, Refusals),
    LessonContext = lesson_context(Grade, Standards),
    atom_string(Grade, GradeText),
    maplist(atom_to_string_value, Standards, StandardTexts),
    term_to_text(Task, TaskText),
    atom_string(Strategy, StrategyText),
    atom_string(Misconception, MisconceptionText),
    representation_selector_figures(SelectorSource, Figures),
    Dict = _{
        grade: GradeText,
        standards: StandardTexts,
        task: TaskText,
        strategy: StrategyText,
        misconception: MisconceptionText,
        figures: Figures,
        candidates: Candidates,
        refusals: Refusals
    }.

representation_selector_figures(lesson_code(LessonCode), Figures) :-
    monitoring_chart_figure_export(LessonCode, Figures),
    !.
representation_selector_figures(_, _{}).

representation_candidate_dict(LessonContext, Task, Strategy, Misconception, Dict) :-
    representation_grammar:visual_candidate_evidence(
        LessonContext,
        Task,
        Strategy,
        Misconception,
        Representation,
        Evidence
    ),
    atom_string(Representation, RepresentationText),
    maplist(term_to_text, Evidence, EvidenceTexts),
    candidate_render_status_text(Evidence, RenderStatusText),
    Dict = _{
        representation: RepresentationText,
        render_status: RenderStatusText,
        evidence: EvidenceTexts
    }.

candidate_render_status_text(Evidence, RenderStatusText) :-
    member(render_status(Status), Evidence),
    !,
    term_to_text(Status, RenderStatusText).
candidate_render_status_text(_, "").

representation_refusal_dict(LessonContext, Task, Strategy, Misconception, Dict) :-
    representation_grammar:representation_language(Representation),
    representation_grammar:visual_refusal(
        LessonContext,
        Task,
        Strategy,
        Misconception,
        Representation,
        Reason
    ),
    atom_string(Representation, RepresentationText),
    term_to_text(Reason, ReasonText),
    Dict = _{
        representation: RepresentationText,
        reason: ReasonText
    }.

representation_render_spec(Request, set_grouping, Spec) :-
    set_grouping_spec(Request, Spec).
representation_render_spec(Request, base_ten_blocks, Spec) :-
    request_string_atom(Request, kind, add_with_carry, Kind),
    request_integer(Request, base, 10, Base),
    base_ten_render_spec_for_check(Kind, Base, Request, Spec).
representation_render_spec(Request, number_line, Spec) :-
    number_line_spec(Request, Spec).
representation_render_spec(Request, place_value_chart, Spec) :-
    place_value_chart_spec(Request, Spec).
representation_render_spec(Request, area_model, Spec) :-
    area_spec(Request, Spec).
representation_render_spec(Request, fraction_bars, Spec) :-
    fraction_bars_spec(Request, Spec).
representation_render_spec(Request, balance_scale, Spec) :-
    balance_spec(Request, Spec).
representation_render_spec(Request, hybridization, Spec) :-
    hybridization_spec(Request, Spec).

fraction_bars_spec(Request, Spec) :-
    request_string_atom(Request, kind, unit_fraction_partition, Kind),
    fraction_bars_spec_for(Kind, Request, Spec).

fraction_bars_spec_for(arith, Request, fraction_arith(Op, NA, DA, NB, DB)) :-
    !,
    request_op_atom(Request, operation, add, Op),
    request_integer(Request, na, 1, NA),
    request_integer(Request, da, 3, DA),
    request_integer(Request, nb, 1, NB),
    request_integer(Request, db, 4, DB).
fraction_bars_spec_for(add_numerators_and_denominators, Request,
        fraction_arith_componentwise(add, NA, DA, NB, DB)) :-
    !,
    request_integer(Request, na, 1, NA),
    request_integer(Request, da, 3, DA),
    request_integer(Request, nb, 1, NB),
    request_integer(Request, db, 4, DB).
fraction_bars_spec_for(Kind, Request, fraction_render(Kind, N, D)) :-
    request_integer(Request, n, 1, N),
    request_integer(Request, d, 3, D).

base_ten_render_spec_for_check(add_with_dropped_carry, Base, Request, add_with_dropped_carry(A, B, Base)) :-
    !,
    request_integer(Request, a, 28, A),
    request_integer(Request, b, 47, B).
base_ten_render_spec_for_check(Kind, Base, Request, Spec) :-
    base_ten_spec_for(Kind, Base, Request, Spec).

representation_spec_check_dict(Request, Representation, Spec, Dict) :-
    (   representation_grammar:render_spec_denotes(Representation, Spec, DenotedTask)
    ->  representation_spec_denotation_dict(Representation, Spec, DenotedTask, Dict)
    ;   representation_target_task_for_spec(Representation, Spec, TargetTask)
    ->  representation_spec_deformation_dict_if_supported(Representation, Spec, TargetTask, Dict)
    ;   representation_task(Request, TargetTask),
        representation_spec_deformation_dict_if_supported(Representation, Spec, TargetTask, Dict)
    ).

representation_spec_deformation_dict_if_supported(Representation, Spec, TargetTask, Dict) :-
        representation_grammar:deformation_spec_evidence(
            Representation,
            Spec,
            TargetTask,
            Evidence
        ),
    representation_spec_deformation_dict(Representation, Spec, TargetTask, Evidence, Dict).

representation_target_task_for_spec(
        hybridization,
        circle_partition_on_rectangle,
        hybridization_case(circle_radial_partition, rectangle_area_model)).
representation_target_task_for_spec(
        hybridization,
        vertical_partition_on_circle,
        hybridization_case(rectangle_vertical_partition, circle_region)).
representation_target_task_for_spec(
        hybridization,
        radial_partition_on_set,
        hybridization_case(circle_radial_partition, fractional_set_model)).
representation_target_task_for_spec(
        hybridization,
        parallel_partition_on_triangle,
        hybridization_case(rectangle_parallel_partition, triangle_region)).

representation_spec_denotation_dict(Representation, Spec, DenotedTask, Dict) :-
    atom_string(Representation, RepresentationText),
    term_to_text(Spec, SpecText),
    term_to_text(DenotedTask, TaskText),
    (   representation_grammar:render_spec_preserves_task(Representation, Spec, DenotedTask)
    ->  Preserves = true
    ;   Preserves = false
    ),
    Dict = _{
        representation: RepresentationText,
        spec: SpecText,
        denoted_task: TaskText,
        preserves: Preserves
    }.

representation_spec_deformation_dict(Representation, Spec, TargetTask, Evidence, Dict) :-
    atom_string(Representation, RepresentationText),
    term_to_text(Spec, SpecText),
    term_to_text(TargetTask, TargetTaskText),
    Dict = _{
        representation: RepresentationText,
        spec: SpecText,
        target_task: TargetTaskText,
        preserves: false,
        deformation: Evidence
    }.

% --- request -> Spec, one per render op --------------------------------------
% Each parses the request's fields into the term the compiler dispatches on.
% A `kind`/`spec` field selects the generator; integer fields feed the operands.

%!  area_spec(+Request, -Spec) is det.
area_spec(Request, Spec) :-
    request_string_atom(Request, kind, array_multiplication, Kind),
    request_integer(Request, a, 3, A),
    request_integer(Request, b, 4, B),
    area_spec_for(Kind, A, B, Request, Spec).

area_spec_for(array_multiplication, A, B, _, array_multiplication(A, B)) :- !.
area_spec_for(commutativity_by_transpose, A, B, _, commutativity_by_transpose(A, B)) :- !.
area_spec_for(partial_products, A, B, _, partial_products(A, B)) :- !.
area_spec_for(area_model_fraction, _, _, Request, area_model_fraction(NA, DA, NB, DB)) :-
    !,
    request_integer(Request, na, 1, NA),
    request_integer(Request, da, 2, DA),
    request_integer(Request, nb, 1, NB),
    request_integer(Request, db, 3, DB).
area_spec_for(area_compare, _, _, Request, area_compare(NA, DA, NB, DB)) :-
    !,
    request_integer(Request, na, 1, NA),
    request_integer(Request, da, 2, DA),
    request_integer(Request, nb, 1, NB),
    request_integer(Request, db, 3, DB).
area_spec_for(_Other, A, B, _, array_multiplication(A, B)).

%!  balance_spec(+Request, -Spec) is det.
balance_spec(Request, Spec) :-
    request_string_atom(Request, kind, solve_linear, Kind),
    request_integer(Request, a, 2, A),
    request_integer(Request, b, 3, B),
    request_integer(Request, c, 11, C),
    balance_spec_for(Kind, A, B, C, Spec).

balance_spec_for(balance_compare, A, B, C, balance_compare(A, B, C)) :- !.
balance_spec_for(solve_linear, A, B, C, solve_linear(A, B, C)) :- !.
balance_spec_for(_Other, A, B, C, solve_linear(A, B, C)).

%!  hybridization_spec(+Request, -Spec) is det.
hybridization_spec(Request, Spec) :-
    request_string_atom(Request, kind, circle_partition_on_rectangle, Spec).

%!  base_ten_spec(+Request, -Spec) is det.
base_ten_spec(Request, Spec) :-
    request_string_atom(Request, kind, add_with_carry, Kind),
    request_integer(Request, base, 10, Base),
    base_ten_spec_for(Kind, Base, Request, Spec).

base_ten_spec_for(represent, Base, Request, represent(N, Base)) :- !,
    request_integer(Request, n, 28, N).
base_ten_spec_for(place_value_teen, _Base, Request, place_value_teen(N)) :- !,
    request_integer(Request, n, 14, N).
base_ten_spec_for(add_with_carry, Base, Request, add_with_carry(A, B, Base)) :- !,
    request_integer(Request, a, 28, A), request_integer(Request, b, 47, B).
base_ten_spec_for(subtract_with_borrow, Base, Request, subtract_with_borrow(A, B, Base)) :- !,
    request_integer(Request, a, 52, A), request_integer(Request, b, 27, B).
base_ten_spec_for(subtract_without_reducing_borrow, Base, Request, subtract_without_reducing_borrow(A, B, Base)) :- !,
    request_integer(Request, a, 52, A), request_integer(Request, b, 27, B).
base_ten_spec_for(base_decomposition, Base, Request, base_decomposition(N, Base)) :- !,
    request_integer(Request, n, 234, N).
base_ten_spec_for(decimal_place_value, _Base, Request, decimal_place_value(I, F)) :- !,
    request_integer(Request, intPart, 3, I), request_integer(Request, fracDigits, 14, F).
base_ten_spec_for(_Other, Base, Request, add_with_carry(A, B, Base)) :-
    request_integer(Request, a, 28, A), request_integer(Request, b, 47, B).

%!  set_grouping_spec(+Request, -Spec) is det.
set_grouping_spec(Request, Spec) :-
    request_string_atom(Request, kind, make_ten, Kind),
    set_grouping_spec_for(Kind, Request, Spec).

set_grouping_spec_for(ten_frame, Request, ten_frame(N)) :- !,
    request_integer(Request, n, 7, N).
set_grouping_spec_for(subitize, Request, subitize(Pattern, N)) :- !,
    request_string_atom(Request, pattern, auto, Pattern),
    request_integer(Request, n, 5, N).
set_grouping_spec_for(make_ten, Request, make_ten(A, B)) :- !,
    request_integer(Request, a, 7, A), request_integer(Request, b, 8, B).
set_grouping_spec_for(make_ten_drop_leftover, Request, make_ten_drop_leftover(A, B)) :- !,
    request_integer(Request, a, 7, A), request_integer(Request, b, 8, B).
set_grouping_spec_for(parity, Request, parity(N)) :- !,
    request_integer(Request, n, 7, N).
set_grouping_spec_for(compare, Request, compare(A, B)) :- !,
    request_integer(Request, a, 5, A), request_integer(Request, b, 3, B).
set_grouping_spec_for(equal_groups, Request, equal_groups(G, S)) :- !,
    request_integer(Request, g, 3, G), request_integer(Request, s, 4, S).
set_grouping_spec_for(fair_share, Request, fair_share(Total, Groups)) :- !,
    request_integer(Request, total, 12, Total), request_integer(Request, groups, 3, Groups).
set_grouping_spec_for(signed_chips, Request, signed_chips(A, B)) :- !,
    request_integer(Request, a, 3, A), request_integer(Request, b, -5, B).
set_grouping_spec_for(_Other, Request, make_ten(A, B)) :-
    request_integer(Request, a, 7, A), request_integer(Request, b, 8, B).

%!  number_line_spec(+Request, -Spec) is det.
%   `mode:"jumps"` (default) reads a strategy id + a/b; `mode:"length"` (or
%   "rounding") reads an operation + a/b for the Measuring-Stick length form.
number_line_spec(Request, Spec) :-
    request_op_atom(Request, mode, jumps, Mode),
    number_line_spec_for(Mode, Request, Spec).

number_line_spec_for(length, Request, rounding_length(Op, A, B)) :- !,
    request_op_atom(Request, operation, addition, Op),
    request_integer(Request, a, 28, A), request_integer(Request, b, 47, B).
number_line_spec_for(rounding, Request, Spec) :- !,
    number_line_spec_for(length, Request, Spec).
number_line_spec_for(magnitude, Request, magnitude_addition(A, B)) :- !,
    request_integer(Request, a, 28, A),
    request_integer(Request, b, 47, B).
number_line_spec_for(magnitude_addition, Request, Spec) :- !,
    number_line_spec_for(magnitude, Request, Spec).
number_line_spec_for(fraction, Request, fraction_iteration(N, D)) :- !,
    request_integer(Request, numerator, 7, N),
    request_integer(Request, denominator, 5, D).
number_line_spec_for(fraction_iteration, Request, Spec) :- !,
    number_line_spec_for(fraction, Request, Spec).
number_line_spec_for(_Jumps, Request, jumps(Strategy, A, B)) :-
    request_string_atom(Request, strategy, 'COBO', Strategy),
    request_integer(Request, a, 28, A), request_integer(Request, b, 47, B).

%!  place_value_chart_spec(+Request, -Spec) is det.
place_value_chart_spec(Request, Spec) :-
    request_string_atom(Request, kind, add_with_carry, Kind),
    request_integer(Request, base, 10, Base),
    place_value_chart_spec_for(Kind, Base, Request, Spec).

place_value_chart_spec_for(add_with_carry, Base, Request, add_with_carry(A, B, Base)) :- !,
    request_integer(Request, a, 28, A),
    request_integer(Request, b, 47, B).
place_value_chart_spec_for(_Other, Base, Request, add_with_carry(A, B, Base)) :-
    request_integer(Request, a, 28, A),
    request_integer(Request, b, 47, B).

% --- enrich_render_doc/3: thread the three additive document fields ----------
%!  enrich_render_doc(+Op, +Spec, +Dict0, -Dict) is det.
%   Adds doc.grounding (§1.4a), doc.tuple (§1.4b), and doc.teacher (§1.4c) to a
%   render document, each only when the compiler did not already emit it. The
%   practice atom is derived from (Op, Spec) by render_practice/3; a spec that
%   maps to no practice (a hollow deformation) gets no grounding/teacher object,
%   which is the contract's claim of inferential hollowness.
enrich_render_doc(Op, Spec, Dict0, Dict) :-
    ( render_practice(Op, Spec, Practice) -> true ; Practice = none ),
    add_grounding_field(Practice, Dict0, Dict1),
    add_tuple_field(Spec, Dict1, Dict2),
    add_teacher_field(Practice, Dict2, Dict3),
    % Defensive: a scene compiler may emit a document carrying a non-ground
    % term (e.g. a sub-dict with an unbound tag on some trace paths). json_safe
    % re-tags and stringifies such terms so a partially-instantiated compiler
    % document can never crash the worker mid-write — the same guard the witness
    % ops apply. Ground documents pass through unchanged.
    json_safe(Dict3, Dict).

add_grounding_field(none, Dict, Dict) :- !.
add_grounding_field(_Practice, Dict, Dict) :-
    get_dict(grounding, Dict, _), !.            % compiler already supplied it
add_grounding_field(Practice, Dict0, Dict) :-
    (   grounding_to_primitive:primitive_for_practice_witness(Practice, Primitive,
                                                              Role, Witness),
        get_dict(grounding_metaphor_label, Witness, Label),
        get_dict(metaphor_gloss, Witness, Gloss)
    ->  atom_string(Practice, PracticeStr),
        atom_string(Label, LabelStr),
        atom_string(Primitive, PrimStr),
        atom_string(Role, RoleStr),
        Grounding = _{ practice: PracticeStr,
                       metaphor_label: LabelStr,
                       metaphor_gloss: Gloss,
                       primitive: PrimStr,
                       role: RoleStr },
        Dict = Dict0.put(grounding, Grounding)
    ;   Dict = Dict0                            % no L&N grounding -> no footer
    ).

add_tuple_field(_Spec, Dict, Dict) :-
    get_dict(tuple, Dict, _), !.                % compiler already supplied it
add_tuple_field(Spec, Dict0, Dict) :-
    term_string(Spec, TupleStr),
    Dict = Dict0.put(tuple, TupleStr).

add_teacher_field(none, Dict, Dict) :- !.
add_teacher_field(_Practice, Dict, Dict) :-
    get_dict(teacher, Dict, _), !.              % compiler already supplied it
add_teacher_field(Practice, Dict0, Dict) :-
    (   teacher_layer:teacher_layer(Practice, Teacher0)
    ->  json_safe(Teacher0, Teacher),
        Dict = Dict0.put(teacher, Teacher)
    ;   Dict = Dict0                            % no teacher channels -> no panel
    ).

% --- render_practice/3: the (Op, Spec) -> practice atom selector -------------
%   The worker-side counterpart of each compiler's spec_practice mapping. A spec
%   with no entry maps to no practice (fails) — the deformation/hollow case.
render_practice(area_render, array_multiplication(_, _), p_rigorous_counting_procedure) :- !.
render_practice(area_render, commutativity_by_transpose(_, _), p_rigorous_counting_procedure) :- !.
render_practice(area_render, partial_products(_, _), p_column_addition_with_carrying) :- !.
render_practice(area_render, area_model_fraction(_, _, _, _), p_area_model_part_of_part) :- !.
render_practice(area_compare, area_compare(_, _, _, _), p_area_model_part_of_part) :- !.

render_practice(base_ten_render, add_with_carry(_, _, _), p_column_addition_with_carrying) :- !.
render_practice(base_ten_render, subtract_with_borrow(_, _, _), p_decompose_base_for_ones) :- !.
render_practice(base_ten_render, base_decomposition(_, _), p_decompose_base_for_ones) :- !.
render_practice(base_ten_render, represent(_, _), p_make_base_transfer) :- !.
render_practice(base_ten_render, place_value_teen(_), p_make_base_transfer) :- !.
render_practice(base_ten_render, decimal_place_value(_, _), p_make_base_transfer) :- !.
render_practice(ace_of_bases_render, add_with_carry(_, _, _), p_column_addition_with_carrying) :- !.
render_practice(ace_of_bases_render, subtract_with_borrow(_, _, _), p_decompose_base_for_ones) :- !.
render_practice(ace_of_bases_render, base_decomposition(_, _), p_decompose_base_for_ones) :- !.
render_practice(ace_of_bases_render, represent(_, _), p_make_base_transfer) :- !.
render_practice(ace_of_bases_render, place_value_teen(_), p_make_base_transfer) :- !.
render_practice(ace_of_bases_render, decimal_place_value(_, _), p_make_base_transfer) :- !.
render_practice(unit_echo_render, unit_echo(_, _), p_unit_fraction_iteration) :- !.
% base_ten_compare: add_with_dropped_carry is the hollow deformation — no practice.

render_practice(place_value_chart_render, add_with_carry(_, _, _), p_column_addition_with_carrying) :- !.

render_practice(set_grouping_render, make_ten(_, _), p_make_ten_split_leftover) :- !.
render_practice(set_grouping_render, ten_frame(_), p_make_ten_split_leftover) :- !.
render_practice(set_grouping_render, signed_chips(_, _), p_signed_addition_with_sign_relation) :- !.
% other set-grouping specs (parity, compare, equal_groups, fair_share) carry no
% L&N arithmetic grounding metaphor; they get no footer rather than a faked one.
% set_grouping_compare: unfair_compare is the deformation — no practice.

render_practice(number_line_render, jumps(_, _, _), p_count_on_from_larger) :- !.
render_practice(number_line_render, rounding_length(_, _, _), p_round_then_adjust) :- !.
render_practice(number_line_render, magnitude_addition(_, _), p_count_on_from_larger) :- !.
render_practice(number_line_render, fraction_iteration(_, _), p_unit_fraction_iteration) :- !.
% number_line_compare: rounding_compare's deformation half is hollow — no practice.

render_practice(balance_render, solve_linear(_, _, _), p_relational_equals_balance_preservation) :- !.
render_practice(balance_compare, solve_linear(_, _, _), p_relational_equals_balance_preservation) :- !.

lesson_misconception_incompatibility_witness(Code, Operation, Name, Witness) :-
    lesson_monitoring:monitoring_chart(
        Code,
        monitoring_chart(Code,
                         _Lesson,
                         _Standards,
                         _Strategies,
                         Misconceptions,
                         _PMLFacts)
    ),
    member(misconception(Operation, Name, Info), Misconceptions),
    member(incompatibility_witness(Witness), Info),
    !.

monitoring_chart_export_dict(Code, Dict) :-
    lesson_monitoring:monitoring_chart_export(
        Code,
        monitoring_chart_export(Code,
                                _Lesson,
                                _Standards,
                                Strategies,
                                Misconceptions,
                                PMLFacts,
                                Clusters)
    ),
    productive_core(Clusters, ProductiveCore),
    maplist(strategy_export_dict, Strategies, StrategyDicts),
    maplist(misconception_export_dict, Misconceptions, MisconceptionDicts),
    lesson_expressive_power_for(Code, ExpressivePowerReport),
    expressive_power_export_dict(ExpressivePowerReport, ExpressivePowerDict),
    findall(PMLDict,
            ( member(PMLFact, PMLFacts),
              pml_fact_export_dict(PMLFact, PMLDict)
            ),
            PMLDicts),
    monitoring_chart_figure_export(Code, FigureDict),
    (   lesson_monitoring:licensed_but_unanticipated(Code, OperationGaps)
    ->  true
    ;   OperationGaps = []
    ),
    maplist(operation_gap_export_dict, OperationGaps, OperationGapDicts),
    % Flat Operation-Kind pairs from lessons/lesson_gap.pl: the registry-covered
    % moves this chart does not anticipate — the opening the chart structurally
    % leaves. Delegates to the same licensed_but_unanticipated/2 computation
    % behind the per-operation key above, so the two surfaces cannot drift.
    (   lesson_gap:unanticipated_strategies(Code, GapMoves)
    ->  true
    ;   GapMoves = []
    ),
    maplist(gap_move_export_dict, GapMoves, GapMoveDicts),
    deformation_chart_scope_export(Code, DeformationChartDict),
    atom_string(Code, CodeString),
    Dict = _{
        lesson_code: CodeString,
        productive_core: ProductiveCore,
        anticipated_strategies: StrategyDicts,
        teacher_misconceptions: MisconceptionDicts,
        licensed_but_unanticipated: OperationGapDicts,
        unanticipated_strategies: GapMoveDicts,
        figures: FigureDict,
        deformation_chart: DeformationChartDict,
        expressive_power: ExpressivePowerDict,
        pml_facts: PMLDicts
    }.

deformation_chart_scope_export(Code, Dict) :-
    findall(CoveredCode,
            lesson_deformation_chart:lesson_chart_lesson(CoveredCode, _, _, _, _),
            Codes0),
    sort(Codes0, Codes),
    maplist(atom_string, Codes, CodeStrings),
    atom_string(Code, CodeString),
    (   memberchk(Code, Codes)
    ->  Dict = _{
            available: true,
            coverage: "covered",
            scope: "grade_3_fraction_lessons",
            lesson_code: CodeString,
            request_op: "lesson_deformation_chart",
            covered_lesson_codes: CodeStrings
        }
    ;   Dict = _{
            available: false,
            coverage: "scope_limited",
            scope: "grade_3_fraction_lessons",
            lesson_code: CodeString,
            request_op: "lesson_deformation_chart",
            covered_lesson_codes: CodeStrings,
            note: "Deformation charts are currently authored only for the covered grade-3 fraction lessons."
        }
    ).

% One flat gap pair. "Licensed" here means registry coverage (moves the
% action automata can run), not normative entitlement; an empty list on a
% lesson whose operations have no registry source marks an absent source,
% not a completed anticipation (lesson_gap's module header carries the full
% register note).
gap_move_export_dict(Operation-Kind, _{operation: OperationText, kind: KindText}) :-
    term_to_text(Operation, OperationText),
    term_to_text(Kind, KindText).

monitoring_chart_figure_export(Code, Dict) :-
    findall(figure_rank(NegScore, Status, CandidateId, Evidence, Refusals, RenderPlan),
            ( lesson_monitoring_selector:selected_figure(
                  Code, CandidateId, Status, Score, Evidence, Refusals, RenderPlan),
              NegScore is -Score ),
            Rows0),
    sort(Rows0, RankedRows),
    length(RankedRows, CandidateCount),
    take_n(6, RankedRows, TopRows),
    maplist(figure_rank_export_dict, TopRows, CandidateDicts),
    (   CandidateDicts = [Selected | _]
    ->  true
    ;   Selected = _{}
    ),
    Dict = _{
        candidate_count: CandidateCount,
        selected: Selected,
        candidates: CandidateDicts
    }.

take_n(0, _, []) :- !.
take_n(_, [], []) :- !.
take_n(N, [H | T], [H | Rest]) :-
    N > 0,
    N1 is N - 1,
    take_n(N1, T, Rest).

figure_rank_export_dict(
        figure_rank(NegScore, Status, CandidateId, Evidence, Refusals, RenderPlan),
        Dict) :-
    Score is -NegScore,
    term_to_text(Status, StatusText),
    term_to_text(Evidence.representation_language, RepText),
    text_value(Evidence.bibkey, BibKeyText),
    text_value(Evidence.grade_bucket, GradeBucketText),
    figure_source_label(Evidence, RenderPlan, SourceLabel),
    score_components_export(Evidence.score_components, ComponentDicts),
    maplist(json_safe, Refusals, SafeRefusals),
    json_safe(RenderPlan, SafeRenderPlan),
    Dict = _{
        image_path: CandidateId,
        status: StatusText,
        score: Score,
        source_label: SourceLabel,
        bibkey: BibKeyText,
        grade_bucket: GradeBucketText,
        representation_language: RepText,
        domains: Evidence.domains,
        evidence: _{
            score_components: ComponentDicts,
            is_hybridized_transplant: Evidence.is_hybridized_transplant
        },
        refusals: SafeRefusals,
        render_plan: SafeRenderPlan
    }.

figure_source_label(Evidence, RenderPlan, SourceLabel) :-
    text_value(Evidence.bibkey, BibKeyText),
    text_value(Evidence.grade_bucket, GradeBucketText),
    term_to_text(Evidence.representation_language, RepText),
    term_to_text(RenderPlan.source, SourceText),
    format(string(SourceLabel), "~s - ~s - ~s - ~s",
           [BibKeyText, GradeBucketText, RepText, SourceText]).

score_components_export([], []).
score_components_export([component(Name, Weight) | Rest], [Dict | Dicts]) :-
    term_to_text(Name, NameText),
    Dict = _{name: NameText, weight: Weight},
    score_components_export(Rest, Dicts).

operation_gap_export_dict(
        operation_gap(Operation, LicensedCount, AnticipatedCount, Unanticipated),
        Dict) :-
    term_to_text(Operation, OperationText),
    maplist(term_to_text, Unanticipated, UnanticipatedTexts),
    length(Unanticipated, UnanticipatedCount),
    Dict = _{
        operation: OperationText,
        licensed_count: LicensedCount,
        anticipated_count: AnticipatedCount,
        unanticipated_count: UnanticipatedCount,
        unanticipated: UnanticipatedTexts
    }.

expressive_power_export_dict(
        report(paths(ProofPaths),
               strategy_incompatibility(StrategyIncompatibilities),
               misconception_incompatibility(MisconceptionIncompatibilities),
               per_operation(OpPowers),
               _PerStrategy,
               _PerMisconception),
        Dict) :-
    maplist(operation_power_export_dict, OpPowers, OperationDicts),
    Dict = _{
        proof_paths: ProofPaths,
        strategy_incompatibilities: StrategyIncompatibilities,
        misconception_incompatibilities: MisconceptionIncompatibilities,
        per_operation: OperationDicts
    }.
expressive_power_export_dict(_, _{
    proof_paths: 0,
    strategy_incompatibilities: 0,
    misconception_incompatibilities: 0,
    per_operation: []
}).

operation_power_export_dict(Operation-region_paths(ProofPaths, Cells, SumDistinctCosts),
                            Dict) :-
    term_to_text(Operation, OperationText),
    Dict = _{
        operation: OperationText,
        proof_paths: ProofPaths,
        cells: Cells,
        distinct_costs: SumDistinctCosts
    }.

productive_core(Clusters, ProductiveCore) :-
    member(chart_cluster(_, _, Info), Clusters),
    member(productive_core(ProductiveCore), Info),
    ProductiveCore \== unknown,
    !.
productive_core(_, "").

strategy_export_dict(strategy(Operation, Kind, Info), Dict) :-
    term_to_text(Operation, OperationText),
    term_to_text(Kind, KindText),
    source_text(Info, SourceText),
    info_term_text(Info, provenance(_), ProvenanceText),
    info_term_text(Info, vocabulary(_), WhereToSpot),
    Dict = _{
        name: KindText,
        operation: OperationText,
        kind: KindText,
        provenance: ProvenanceText,
        source: SourceText,
        productive: true,
        where_to_spot: WhereToSpot
    }.

misconception_export_dict(misconception(Operation, Name, Info), Dict) :-
    term_to_text(Operation, OperationText),
    term_to_text(Name, NameText),
    citation_text(Info, CitationText),
    info_term_text(Info, provenance(_), ProvenanceText),
    info_term_text(Info, commitment_made(_), CommitmentText),
    info_term_text(Info, entitlement_lacked(_), EntitlementText),
    info_term_text(Info, incompatibility(_), IncompatibilityText),
    info_term_json_safe(Info, incompatibility_witness(_), IncompatibilityWitness),
    info_term_json_safe(Info, incompatibility_set_witness(_), IncompatibilitySetWitness),
    discovered_incompatibility_set_texts(Info, DiscoveredSetTexts),
    re_anchoring_text(EntitlementText, ReAnchoringText),
    info_term_gloss(Info, commitment_made(_), CommitmentGloss),
    info_term_gloss(Info, entitlement_lacked(_), EntitlementGloss),
    info_term_gloss(Info, incompatibility(_), IncompatibilityGloss),
    Dict = _{
        name: NameText,
        operation: OperationText,
        provenance: ProvenanceText,
        commitment_made: CommitmentText,
        commitment_made_gloss: CommitmentGloss,
        entitlement_lacked: EntitlementText,
        entitlement_lacked_gloss: EntitlementGloss,
        incompatibility: IncompatibilityText,
        incompatibility_gloss: IncompatibilityGloss,
        incompatibility_witness: IncompatibilityWitness,
        incompatibility_set_witness: IncompatibilitySetWitness,
        discovered_incompatibility_sets: DiscoveredSetTexts,
        citation: CitationText,
        re_anchoring_move: ReAnchoringText
    }.

%% English glosses for the deontic terms the export carries, so markdown and
%% scoreboard surfaces read in teacher language at the source. Mirrors the
%% console's client-side glossTerm; db_row provenance stays out of the
%% sentence (the citation field carries the source). The raw term text stays
%% in the un-suffixed field for formal-view consumers.
info_term_gloss(Info, Pattern, Gloss) :-
    (   member(Pattern, Info),
        arg(1, Pattern, Term)
    ->  deontic_term_gloss(Term, Gloss)
    ;   Gloss = ""
    ).

deontic_term_gloss(Term, Gloss) :-
    var(Term),
    !,
    Gloss = "".
deontic_term_gloss(strategy(Op, Kind), Gloss) :-
    !,
    atom_spaces(Kind, K),
    atom_spaces(Op, O),
    format(string(Gloss), "the '~w' strategy (~w)", [K, O]).
deontic_term_gloss(misconception(Name), Gloss) :-
    !,
    atom_spaces(Name, N),
    format(string(Gloss), "the '~w' misconception", [N]).
deontic_term_gloss(result_of(Name, db_row(_), Val), Gloss) :-
    !,
    atom_spaces(Name, N),
    format(string(Gloss), "the '~w' rule yields ~w", [N, Val]).
deontic_term_gloss(result_of(Name, Source, Val), Gloss) :-
    !,
    atom_spaces(Name, N),
    term_to_text(Source, S),
    format(string(Gloss), "the '~w' rule on ~w yields ~w", [N, S, Val]).
deontic_term_gloss(deformed_action(Prod, Def, _Family), Gloss) :-
    !,
    atom_spaces(Prod, P),
    atom_spaces(Def, D),
    format(string(Gloss), "the '~w' strategy deformed into '~w'", [P, D]).
% The batch-corpus deontic terms (misconception_registry.pl). As with
% result_of above, db_row provenance stays out of the sentence — the citation
% field carries the source. Mirrors gloss_commitment/2 in
% lessons/im/field_context.pl, which glosses db_row(Id) as "corpus row Id".
deontic_term_gloss(documented_batch_misconception(Name, _Source, _Detail, _Rule), Gloss) :-
    !,
    atom_spaces(Name, N),
    format(string(Gloss), "the '~w' misconception documented in the literature", [N]).
deontic_term_gloss(expected_mathematical_control(_Name, _Source, Operation), Gloss) :-
    !,
    atom_spaces(Operation, O),
    format(string(Gloss), "the expected mathematical control of ~w", [O]).
deontic_term_gloss(expected_result(Name, _Source, Expected), Gloss) :-
    !,
    atom_spaces(Name, N),
    term_to_text(Expected, E),
    format(string(Gloss), "the expected result ~w from the '~w' rule", [E, N]).
deontic_term_gloss(db_row(Id), Gloss) :-
    !,
    term_to_text(Id, IdText),
    format(string(Gloss), "corpus row ~w", [IdText]).
deontic_term_gloss(Term, Gloss) :-
    atom(Term),
    !,
    atom_spaces(Term, Gloss0),
    format(string(Gloss), "~w", [Gloss0]).
deontic_term_gloss(Term, Gloss) :-
    term_to_text(Term, Gloss).

atom_spaces(Atom, Spaced) :-
    atom(Atom),
    !,
    atomic_list_concat(Parts, '_', Atom),
    atomic_list_concat(Parts, ' ', Spaced).
atom_spaces(Other, Text) :-
    term_to_text(Other, Text).

pml_fact_export_dict(reader_axiom(Id, Premises, Conclusion, Polarity), Dict) :-
    term_to_text(Id, IdText),
    maplist(term_to_text, Premises, PremiseTexts),
    term_to_text(Conclusion, ConclusionText),
    term_to_text(Polarity, PolarityText),
    Dict = _{
        id: IdText,
        premises: PremiseTexts,
        conclusion: ConclusionText,
        polarity: PolarityText
    }.
pml_fact_export_dict(passage_mode(Id, Mode, Reading), Dict) :-
    term_to_text(Id, IdText),
    term_to_text(Mode, ModeText),
    text_value(Reading, ReadingText),
    Dict = _{
        id: IdText,
        premises: [],
        conclusion: ReadingText,
        polarity: ModeText
    }.
pml_fact_export_dict(coverage(Coverage), Dict) :-
    term_to_text(Coverage, CoverageText),
    Dict = _{
        id: "coverage",
        premises: [],
        conclusion: CoverageText,
        polarity: "coverage"
    }.

source_text(Info, SourceText) :-
    member(source(Source), Info),
    !,
    term_to_text(Source, SourceText).
source_text(_, "explicit").

citation_text(Info, CitationText) :-
    member(citation(Key, Note), Info),
    !,
    text_value(Key, KeyText),
    text_value(Note, NoteText),
    format(string(CitationText), "~s: ~s", [KeyText, NoteText]).
citation_text(Info, CitationText) :-
    member(citation(Citation), Info),
    !,
    term_to_text(Citation, CitationText).
citation_text(_, "").

info_term_text(Info, Template, Text) :-
    functor(Template, Functor, 1),
    member(Term, Info),
    functor(Term, Functor, 1),
    !,
    arg(1, Term, Value),
    term_to_text(Value, Text).
info_term_text(_, _, "").

info_term_json_safe(Info, Template, Safe) :-
    functor(Template, Functor, 1),
    member(Term, Info),
    functor(Term, Functor, 1),
    !,
    arg(1, Term, Value),
    json_safe(Value, Safe).
info_term_json_safe(_, _, _{}).

discovered_incompatibility_set_texts(Info, Texts) :-
    findall(Text,
            ( member(incompatibility_set(discovered, Set), Info),
              term_to_text(Set, Text)
            ),
            Texts).

re_anchoring_text("", "") :- !.
re_anchoring_text(EntitlementText, ReAnchoringText) :-
    format(string(ReAnchoringText), "Re-anchor toward ~s.", [EntitlementText]).

text_value(Value, Text) :-
    string(Value),
    !,
    Text = Value.
text_value(Value, Text) :-
    atom(Value),
    !,
    atom_string(Value, Text).
text_value(Value, Text) :-
    term_to_text(Value, Text).

term_to_text(Value, Text) :-
    string(Value),
    !,
    Text = Value.
term_to_text(Value, Text) :-
    atom(Value),
    !,
    atom_string(Value, Text).
term_to_text(Value, Text) :-
    term_string(Value, Text, [quoted(false), numbervars(true)]).

dispatch_geometry(matching_concepts, [Tokens, GradeBand], Id, Response) :-
    !,
    norm_grade_band(GradeBand, GB),
    matching_concepts(Tokens, GB, Concepts),
    maplist(concept_dict, Concepts, Dicts),
    ok_response(Id, Dicts, Response).

dispatch_geometry(workflow_monitoring_matches, [Tokens, GradeBand], Id, Response) :-
    !,
    norm_grade_band(GradeBand, GB),
    matching_concepts(Tokens, GB, Concepts0),
    take_n(3, Concepts0, Concepts),
    maplist(workflow_monitoring_concept_dict, Concepts, Dicts),
    ok_response(Id, _{concepts: Dicts}, Response).

dispatch_geometry(concepts_in_neighborhood, [ConceptIds, Depth], Id, Response) :-
    !,
    norm_concept_ids(ConceptIds, CIds),
    concepts_in_neighborhood(CIds, Depth, Neighborhood),
    maplist(atom_to_string_value, Neighborhood, Strings),
    ok_response(Id, Strings, Response).

dispatch_geometry(applicable_misconceptions, [UserText, ConceptIds], Id, Response) :-
    !,
    norm_concept_ids(ConceptIds, CIds),
    applicable_misconceptions(UserText, CIds, Misconceptions),
    json_safe(Misconceptions, Safe),
    ok_response(Id, Safe, Response).

dispatch_geometry(linked_misconceptions, [ConceptIds, MaxTier], Id, Response) :-
    !,
    norm_concept_ids(ConceptIds, CIds),
    linked_misconceptions(CIds, MaxTier, Misconceptions),
    json_safe(Misconceptions, Safe),
    ok_response(Id, Safe, Response).

dispatch_geometry(vh_markers_for, [ConceptId0, LevelOpt0], Id, Response) :-
    !,
    string_or_atom_to_atom(ConceptId0, ConceptId),
    norm_geometry_atom(LevelOpt0, LevelOpt),
    vh_markers_for(ConceptId, LevelOpt, Markers),
    json_safe(Markers, Safe),
    ok_response(Id, Safe, Response).

dispatch_geometry(bootstraps_for, [ConceptId0, Transition0, Kind0], Id, Response) :-
    !,
    string_or_atom_to_atom(ConceptId0, ConceptId),
    norm_geometry_atom(Transition0, Transition),
    norm_geometry_atom(Kind0, Kind),
    bootstraps_for(ConceptId, Transition, Kind, Bootstraps),
    json_safe(Bootstraps, Safe),
    ok_response(Id, Safe, Response).

dispatch_geometry(developmental_arc_for, [ConceptOrArcId0], Id, Response) :-
    !,
    string_or_atom_to_atom(ConceptOrArcId0, ConceptOrArcId),
    developmental_arc_for(ConceptOrArcId, Arc),
    json_safe(Arc, Raw),
    Safe = _{kind: "developmental_arc", raw: Raw},
    ok_response(Id, Safe, Response).

dispatch_geometry(pck_synthesis_for, [ConceptId0], Id, Response) :-
    !,
    string_or_atom_to_atom(ConceptId0, ConceptId),
    pck_synthesis_for(ConceptId, Pck),
    json_safe(Pck, Raw),
    Safe = _{kind: "pck_synthesis", raw: Raw},
    ok_response(Id, Safe, Response).

dispatch_geometry(standards_bundle_for, [Framework0, Code0], Id, Response) :-
    !,
    string_or_atom_to_atom(Framework0, Framework),
    geometry_code_value(Code0, Code),
    standards_bundle_for(Framework, Code, Bundle),
    json_safe(Bundle, Raw),
    Safe = _{kind: "standards_bundle", raw: Raw},
    ok_response(Id, Safe, Response).

dispatch_geometry(concept_monitoring_bundle, [ConceptId0], Id, Response) :-
    !,
    string_or_atom_to_atom(ConceptId0, ConceptId),
    (   concept_monitoring_bundle(ConceptId, Bundle)
    ->  json_safe(Bundle, Raw),
        Safe = _{kind: "concept_monitoring_bundle", raw: Raw},
        ok_response(Id, Safe, Response)
    ;   error_response(Id, no_geometry_monitoring_bundle,
            "concept_monitoring_bundle found no bundle for concept", Response)
    ).

dispatch_geometry(rigid_motion_render, [Spec0], Id, Response) :-
    !,
    json_to_term(Spec0, Spec),
    rigid_motion_scene:rigid_motion_render_json(Spec, Dict),
    json_safe(Dict, Safe),
    ok_response(Id, Safe, Response).

dispatch_geometry(applicable_misconceptions, _, Id, Response) :- !,
    error_response(Id, malformed_geometry_request,
        "applicable_misconceptions requires args [user_text, concept_ids]",
        Response).
dispatch_geometry(linked_misconceptions, _, Id, Response) :- !,
    error_response(Id, malformed_geometry_request,
        "linked_misconceptions requires args [concept_ids, max_tier]",
        Response).
dispatch_geometry(vh_markers_for, _, Id, Response) :- !,
    error_response(Id, malformed_geometry_request,
        "vh_markers_for requires args [concept_id, level_or_any]",
        Response).
dispatch_geometry(bootstraps_for, _, Id, Response) :- !,
    error_response(Id, malformed_geometry_request,
        "bootstraps_for requires args [concept_id, transition_or_any, kind_or_any]",
        Response).
dispatch_geometry(developmental_arc_for, _, Id, Response) :- !,
    error_response(Id, malformed_geometry_request,
        "developmental_arc_for requires args [concept_or_arc_id]",
        Response).
dispatch_geometry(pck_synthesis_for, _, Id, Response) :- !,
    error_response(Id, malformed_geometry_request,
        "pck_synthesis_for requires args [concept_id]",
        Response).
dispatch_geometry(standards_bundle_for, _, Id, Response) :- !,
    error_response(Id, malformed_geometry_request,
        "standards_bundle_for requires args [framework, code]",
        Response).
dispatch_geometry(concept_monitoring_bundle, _, Id, Response) :- !,
    error_response(Id, malformed_geometry_request,
        "concept_monitoring_bundle requires args [concept_id]",
        Response).
dispatch_geometry(rigid_motion_render, _, Id, Response) :- !,
    error_response(Id, malformed_geometry_request,
        "rigid_motion_render requires args [spec]",
        Response).

dispatch_geometry(Predicate, _Args, Id, Response) :-
    format(string(Message), "Unsupported geometry predicate: ~w", [Predicate]),
    error_response(Id, unknown_geometry_predicate, Message, Response).

workflow_monitoring_concept_dict(concept(Id, Name, Topic, Score), Dict) :-
    (   concept_monitoring_bundle(Id,
            geometry_monitoring_bundle(_, _, Related, Standards,
                                       Misconceptions, Metaphors, Markers, Arcs))
    ->  true
    ;   Related = [], Standards = [], Misconceptions = [],
        Metaphors = [], Markers = [], Arcs = []
    ),
    take_n(4, Related, Related0),
    take_n(4, Standards, Standards0),
    take_n(4, Misconceptions, Misconceptions0),
    take_n(4, Metaphors, Metaphors0),
    take_n(4, Markers, Markers0),
    take_n(3, Arcs, Arcs0),
    maplist(term_to_text, Related0, RelatedTexts),
    maplist(term_to_text, Standards0, StandardTexts),
    maplist(term_to_text, Misconceptions0, MisconceptionTexts),
    maplist(term_to_text, Metaphors0, MetaphorTexts),
    maplist(term_to_text, Markers0, MarkerTexts),
    maplist(term_to_text, Arcs0, ArcTexts),
    pck_synthesis_for(Id, Pck),
    term_to_text(Pck, PckText),
    concept_dict(concept(Id, Name, Topic, Score), Base),
    Dict = Base.put(_{
        related: RelatedTexts,
        standards: StandardTexts,
        misconceptions: MisconceptionTexts,
        metaphors: MetaphorTexts,
        markers: MarkerTexts,
        arcs: ArcTexts,
        pck: PckText
    }).

request_id(Request, Id) :-
    (   get_dict(id, Request, Id)
    ->  true
    ;   Id = "unknown"
    ).

request_utterances(JSONUtterances, Utterances) :-
    is_list(JSONUtterances),
    maplist(request_utterance, JSONUtterances, Utterances),
    findall(Id, member(utterance(Id, _Speaker, _Text), Utterances), Ids),
    sort(Ids, UniqueIds),
    same_length(Ids, UniqueIds).

request_utterance(Dict, utterance(Id, Speaker, Text)) :-
    is_dict(Dict),
    get_dict(id, Dict, Id),
    atomic(Id),
    get_dict(speaker, Dict, Speaker),
    transcript_text_value(Speaker),
    get_dict(text, Dict, Text),
    transcript_text_value(Text).

transcript_text_value(Value) :-
    string(Value),
    !.
transcript_text_value(Value) :-
    atom(Value).

request_discourse_context(Request, Utterances, ContextEvidence) :-
    (   get_dict(context, Request, JSONContext),
        JSONContext \== null
    ->  discourse_features:context_dict_evidence(
            Utterances, JSONContext, ContextEvidence)
    ;   ContextEvidence = []
    ).

ok_response(Id, Result, _{id: Id, ok: true, result: Result}).

error_response(Id, Type, Error, _{id: Id, ok: false, error: _{type: TypeString, message: Message}}) :-
    atom_string(Type, TypeString),
    message_string(Error, Message).

message_string(Error, Message) :-
    (   string(Error)
    ->  Message = Error
    ;   atom(Error)
    ->  atom_string(Error, Message)
    ;   message_to_string(Error, Message)
    ).

norm_grade_band(any, any) :- !.
norm_grade_band([], any) :- !.
norm_grade_band(L, L) :- is_list(L), !.
norm_grade_band(_, any).

norm_concept_ids(any, any) :- !.
norm_concept_ids(L, AtomIds) :-
    is_list(L),
    !,
    maplist(string_or_atom_to_atom, L, AtomIds).
norm_concept_ids(_, any).

norm_geometry_atom("any", any) :- !.
norm_geometry_atom(any, any) :- !.
norm_geometry_atom(Value, Atom) :-
    string_or_atom_to_atom(Value, Atom).

geometry_code_value(Value, Value) :-
    string(Value),
    !.
geometry_code_value(Value, String) :-
    atom(Value),
    !,
    atom_string(Value, String).
geometry_code_value(Value, String) :-
    term_string(Value, String).

string_or_atom_to_atom(Value, Atom) :-
    (   atom(Value)
    ->  Atom = Value
    ;   string(Value)
    ->  atom_string(Atom, Value)
    ;   term_string(Value, String),
        atom_string(Atom, String)
    ).

atom_to_string_value(Atom, String) :-
    atom_string(Atom, String).

concept_dict(concept(Id, Name, Topic, Score), _{
    kind: "concept",
    id: IdString,
    name: NameString,
    topic: TopicString,
    score: ScoreValue
}) :-
    atom_to_string_value(Id, IdString),
    atom_to_string_value(Name, NameString),
    atom_to_string_value(Topic, TopicString),
    score_value(Score, ScoreValue).

score_value(score(Value), Value) :- !.
score_value(Value, Value).

worker_fatal(Error) :-
    message_string(Error, Message),
    format(user_error, "hermes_worker fatal: ~s~n", [Message]),
    halt(2).

json_safe(Value, Safe) :-
    is_dict(Value),
    !,
    dict_pairs(Value, Tag, Pairs),
    maplist(json_safe_pair, Pairs, SafePairs),
    dict_pairs(Safe, Tag, SafePairs).
json_safe(Value, Safe) :-
    is_list(Value),
    !,
    maplist(json_safe, Value, Safe).
json_safe(Value, Safe) :-
    safe_reason_term(Value, Safe),
    !.
json_safe(Value, Value) :-
    atomic(Value),
    !.
json_safe(Value, Safe) :-
    term_string(Value, Safe).

json_safe_pair(Key-Value, Key-Safe) :-
    json_safe(Value, Safe).

safe_reason_term(shared_domain(Value), Safe) :-
    reason_value_string(Value, String),
    format(string(Safe), "shared_domain(~s)", [String]).
safe_reason_term(shared_topic(Value), Safe) :-
    reason_value_string(Value, String),
    format(string(Safe), "shared_topic(~s)", [String]).
safe_reason_term(shared_validity_register(Value), Safe) :-
    reason_value_string(Value, String),
    format(string(Safe), "shared_validity_register(~s)", [String]).

reason_value_string(Value, String) :-
    (   string(Value)
    ->  String = Value
    ;   atom(Value)
    ->  atom_string(Value, String)
    ;   term_string(Value, String)
    ).

% --- Misconceptions JSON Helper predicates ---

json_to_term(JSON, Term) :-
    string(JSON),
    !,
    catch(term_string(Term, JSON), _, Term = JSON).
json_to_term(JSON, Term) :-
    is_list(JSON),
    !,
    maplist(json_to_term, JSON, Term).
json_to_term(JSON, Term) :-
    is_dict(JSON),
    !,
    dict_pairs(JSON, Tag, Pairs),
    maplist(json_to_term_pair, Pairs, TermPairs),
    dict_pairs(Term, Tag, TermPairs).
json_to_term(JSON, JSON).

json_to_term_pair(Key-Value, Key-Term) :-
    json_to_term(Value, Term).

get_dict_opt(Key, Dict, Val) :-
    get_dict(Key, Dict, Val0),
    Val0 \== null,
    Val = Val0.

diagnose_and_format(Domain, Input, Got, SafeMatch) :-
    test_harness:diagnose_error(Domain, Input, Got, Match),
    json_safe(Match, SafeMatch).

query_and_format(Domain, Description, Source, SafeMatch) :-
    test_harness:query_misconception(Domain, Description, Source, Match),
    json_safe(Match, SafeMatch).

% =============================================================================
% Gate-G op support: brandomian_check, hyperedges, axiom_toggle helpers.
% =============================================================================

%!  brandomian_incoherence_source(+Set, -Source, -WitnessEdge) is det.
%
%   Which side of the union verdict fired, mirroring b_incoherent/1's own
%   order: a declared hyperedge contained in Set (that edge is the witness),
%   else the classical neg-pair floor (the clashing pair is the witness). The
%   final clause covers any other incoherent_base/1 case without a pair-shaped
%   witness.
brandomian_incoherence_source(Set, "brandomian_hyperedge", EdgeTexts) :-
    findall(Bad,
            ( brandomian_incompatibility:incompatible_set(Bad),
              bc_subset_eq(Bad, Set)
            ),
            [Edge|_]),
    !,
    maplist(term_to_text, Edge, EdgeTexts).
brandomian_incoherence_source(Set, "classical_negation_pair", PairTexts) :-
    member(P, Set),
    bc_member_eq(neg(P), Set),
    !,
    maplist(term_to_text, [P, neg(P)], PairTexts).
brandomian_incoherence_source(_, "classical_incoherence_base", null).

bc_subset_eq([], _).
bc_subset_eq([X|Xs], Set) :-
    bc_member_eq(X, Set),
    bc_subset_eq(Xs, Set).

bc_member_eq(X, [Y|_]) :- X == Y, !.
bc_member_eq(X, [_|Ys]) :- bc_member_eq(X, Ys).

%!  pairwise_incompatibility_entailments(+Commitments, -Entailments, -Checked) is det.
%
%   Every ordered pair inside the commitment set is checked against the
%   canonical relation; only the pairs where the entailment HOLDS are
%   returned (each is a positive finding), with the total checked count
%   alongside so an empty list is legible as "checked, none hold".
pairwise_incompatibility_entailments(Commitments, Entailments, Checked) :-
    findall(A-B,
            ( member(A, Commitments),
              member(B, Commitments),
              A \== B
            ),
            Pairs),
    length(Pairs, Checked),
    findall(_{from: FromText, to: ToText, holds: true},
            ( member(A-B, Pairs),
              brandomian_incompatibility:incompatibility_entails(A, B),
              term_to_text(A, FromText),
              term_to_text(B, ToText)
            ),
            Entailments).

%!  queried_entailment(+Request, -Result) is det.
%
%   Optional single entailment query: `entails: {from: TermString, to:
%   TermString}` checks one candidate pair whether or not both terms sit in
%   the commitment set. Absent request -> null.
queried_entailment(Request, Result) :-
    (   get_dict_opt(entails, Request, EJSON),
        is_dict(EJSON),
        get_dict_opt(from, EJSON, FromJSON),
        get_dict_opt(to, EJSON, ToJSON)
    ->  json_to_term(FromJSON, From),
        json_to_term(ToJSON, To),
        (   brandomian_incompatibility:incompatibility_entails(From, To)
        ->  Holds = true
        ;   Holds = false
        ),
        term_to_text(From, FromText),
        term_to_text(To, ToText),
        Result = _{from: FromText, to: ToText, holds: Holds}
    ;   Result = null
    ).

hyperedge_row(KindFilter, Row) :-
    incompatibility_sets:discovered_set_kind(Context, Set, Kind0),
    hyperedge_kind_atom(Kind0, Kind),
    (   KindFilter == all
    ->  true
    ;   Kind == KindFilter
    ),
    cached_row_emergence(Context, Set, Emergent, Check, ContentTexts, Break),
    maplist(term_to_text, Set, SetTexts),
    term_to_text(Context, ContextText),
    term_to_text(Kind, KindText),
    Row = _{ source: "bigred_iteration7_cache",
             provenance: "arche-trace/data/incompatibility_sets_discovered.pl (Big Red iteration7 bounded discovery; regeneration: docs/bigred-incompatibility-RUNBOOK.md)",
             context: ContextText,
             set: SetTexts,
             kind: KindText,
             emergent: Emergent,
             emergence_check: Check,
             content_set: ContentTexts,
             catalogue_break: Break }.
hyperedge_row(KindFilter, Row) :-
    (   KindFilter == all
    ->  true
    ;   KindFilter == declared
    ),
    brandomian_incompatibility:incompatible_set(Set),
    length(Set, Len),
    Len >= 3,
    (   brandomian_incompatibility:minimal_incompatible_set(Set)
    ->  Emergent = true,
        Check = "minimal_in_canonical_relation_no_declared_proper_subset"
    ;   Emergent = false,
        Check = "canonical_relation_declares_an_incoherent_proper_subset"
    ),
    catalogue_break_for(Set, Break),
    maplist(term_to_text, Set, SetTexts),
    Row = _{ source: "canonical_relation",
             provenance: "arche-trace/brandomian_incompatibility.pl declared incompatible claim groups (size >= 3 only; the seed pairs are reachable through brandomian_check)",
             context: "brandomian_engine",
             set: SetTexts,
             kind: "declared",
             emergent: Emergent,
             emergence_check: Check,
             content_set: SetTexts,
             catalogue_break: Break }.

hyperedge_kind_atom(Kind, Kind) :-
    atom(Kind),
    !.
hyperedge_kind_atom(Kind, Name) :-
    functor(Kind, Name, _).

% Defeasible rows are cached as [inference(Id)|Defeaters]; the emergence
% criterion runs over the combined premise+defeater CONTENT set, the same
% way the search tool verified the 4 cached emergent rows.
cached_row_emergence(defeasible_inference, [inference(InfId)|Defeaters],
                     Emergent, Check, ContentTexts, Break) :-
    !,
    (   defeasible_inference:material_inference(InfId, Premises, _)
    ->  append(Premises, Defeaters, Content0),
        sort(Content0, ContentSet),
        (   find_emergent_hyperedges:verified_emergent(ContentSet)
        ->  Emergent = true,
            Check = "live_verified_no_incoherent_proper_subset"
        ;   Emergent = false,
            Check = "fails_live_emergence_criterion"
        ),
        maplist(term_to_text, ContentSet, ContentTexts),
        catalogue_break_for(ContentSet, Break)
    ;   Emergent = false,
        Check = "inference_id_no_longer_defined",
        ContentTexts = [],
        Break = null
    ).
cached_row_emergence(Context, Set, Emergent, Check, ContentTexts, Break) :-
    maplist(term_to_text, Set, ContentTexts),
    catalogue_break_for(Set, Break),
    length(Set, Len),
    (   Len < 3
    ->  Emergent = false,
        Check = "size_below_3"
    ;   classifier_emergent(Context, Set)
    ->  Emergent = true,
        Check = "classifier_verified_no_incoherent_proper_subset"
    ;   Emergent = false,
        Check = "fails_classifier_emergence_criterion"
    ).

% Re-run the bounded discovery classifier on the full set and on every
% one-element removal (incoherence persists under superset, so one-element
% removals cover all proper subsets). A classifier throw counts against
% emergence, never for it.
classifier_emergent(Context, Set) :-
    catch(incompatibility_discovery:classify_candidate_set_witness(
              Context, Set, FullOutcome, _),
          _,
          fail),
    incoherent_outcome(FullOutcome),
    forall(select(_, Set, Smaller),
           ( catch(incompatibility_discovery:classify_candidate_set_witness(
                       Context, Smaller, SmallOutcome, _),
                   _,
                   fail),
             \+ incoherent_outcome(SmallOutcome)
           )).

incoherent_outcome(incoherent) :- !.
incoherent_outcome(incoherent(_)).

% The Lakoff & Nunez catalogue row a content set compiles from, when one
% matches exactly; null otherwise. Computed, not hand-tagged, so the
% catalogue attestation travels only with the sets that earn it.
catalogue_break_for(ContentSet, Break) :-
    (   defeasible_inference:compiled_break(BreakId, Conds),
        sort(Conds, ContentSet)
    ->  term_to_text(BreakId, Break)
    ;   Break = null
    ).

%!  ensure_learner_compute_loaded is det.
%
%   Import-free lazy load for the learner computation surface. Some of this
%   chain prints initialization text, so every first load is redirected away
%   from the worker's JSONL stdout.
ensure_learner_compute_loaded :-
    (   current_predicate(event_log:reset_events/0),
        current_predicate(arithmetic_machine:solve_arithmetic/3),
        current_predicate(teacher:available_strategies/2),
        current_predicate(more_machine_learner:run_learned_strategy/5),
        current_predicate(strategy_synthesis:synthesized_strategy/7),
        current_predicate(tension_dynamics:get_tension_state/1),
        current_predicate(execution_handler:run_computation/2),
        current_predicate(peano_utils:int_to_peano/2)
    ->  true
    ;   with_output_to(user_error,
            ( use_module(learner(event_log), []),
              use_module(learner(arithmetic_machine), []),
              use_module(learner(teacher), []),
              use_module(learner(more_machine_learner), []),
              use_module(learner(strategy_synthesis), []),
              use_module(learner(tension_dynamics), []),
              use_module(learner(execution_handler), []),
              use_module(learner(peano_utils), [])
            ))
    ).

%!  ensure_learner_knowledge_loaded is det.
ensure_learner_knowledge_loaded :-
    (   current_predicate(teacher:available_strategies/2),
        current_predicate(more_machine_learner:run_learned_strategy/5),
        current_predicate(strategy_synthesis:synthesized_strategy/7)
    ->  true
    ;   with_output_to(user_error,
            ( use_module(learner(teacher), []),
              use_module(learner(more_machine_learner), []),
              use_module(learner(strategy_synthesis), [])
            ))
    ).

%!  ensure_coordination_viz_loaded is det.
ensure_coordination_viz_loaded :-
    (   current_predicate(unit_coordination_viz:generate_coordination_svg/4)
    ->  true
    ;   with_output_to(user_error,
            use_module(math(unit_coordination_viz), []))
    ).

%!  ensure_fraction_band_ladder_loaded is det.
ensure_fraction_band_ladder_loaded :-
    (   current_predicate(fraction_band_ladder:story_for/3)
    ->  true
    ;   with_output_to(user_error,
            use_module(learner(fraction_band_ladder), []))
    ).

%!  ensure_learner_reset_loaded is det.
ensure_learner_reset_loaded :-
    ensure_learner_compute_loaded,
    (   current_predicate(reflective_monitor:reset_success_reflection/0)
    ->  true
    ;   with_output_to(user_error,
            use_module(learner(reflective_monitor), []))
    ).

learner_compute_request(Request, Op, A, B, Limit, Mode) :-
    get_dict(operation, Request, OpValue),
    learner_request_atom(OpValue, Op),
    memberchk(Op, [add, subtract, multiply, divide]),
    get_dict(a, Request, A),
    integer(A),
    get_dict(b, Request, B),
    integer(B),
    learner_optional_integer(Request, limit, 20, Limit),
    Limit > 0,
    (   get_dict_opt(mode, Request, ModeValue)
    ->  learner_request_atom(ModeValue, Mode)
    ;   Mode = direct
    ),
    memberchk(Mode, [direct, developmental]).

learner_run_compute(developmental, Op, A, B, Limit, Success) :-
    !,
    learner_developmental_goal(Op, A, B, Goal),
    (   catch(
            with_output_to(string(_),
                execution_handler:run_computation(Goal, Limit)),
            Error,
            ( event_log:emit(computation_failed,
                             _{goal: Goal, error: Error}),
              fail
            ))
    ->  Success = true
    ;   Success = false
    ).
learner_run_compute(direct, Op, A, B, _Limit, Success) :-
    Problem =.. [Op, A, B],
    event_log:emit(computation_start,
                   _{operation: Op, a: A, b: B, mode: direct}),
    (   catch(
            with_output_to(string(_),
                arithmetic_machine:solve_arithmetic(Problem, Result, Report)),
              Error,
              ( event_log:emit(computation_failed,
                               _{problem: Problem, error: Error}),
                fail
              ))
    ->  event_log:emit(computation_success,
            _{ result: Result,
               inferences_used: 0,
               strategy: Report.strategy,
               interpretation: Report.interpretation,
               teacher: Report.teacher,
               mode: direct }),
        Success = true
    ;   event_log:emit(computation_failed,
                       _{problem: Problem, error: 'no direct strategy'}),
        Success = false
    ).

learner_compute_result(Success, Mode, Op, A, B, Limit, Result) :-
    event_log:get_events(Events),
    maplist(learner_event_to_dict, Events, EventDicts),
    learner_knowledge_rows(Knowledge),
    tension_dynamics:get_tension_state(Tension),
    tension_dynamics:get_tension_history(TensionHistory),
    Result = _{ success: Success,
                mode: Mode,
                problem: _{operation: Op, a: A, b: B},
                budget: Limit,
                events: EventDicts,
                knowledge: Knowledge,
                tension: Tension,
                tension_history: TensionHistory }.

learner_developmental_goal(add, A, B, object_level:add(PA, PB, _)) :-
    peano_utils:int_to_peano(A, PA), peano_utils:int_to_peano(B, PB).
learner_developmental_goal(subtract, A, B, object_level:subtract(PA, PB, _)) :-
    peano_utils:int_to_peano(A, PA), peano_utils:int_to_peano(B, PB).
learner_developmental_goal(multiply, A, B, object_level:multiply(PA, PB, _)) :-
    peano_utils:int_to_peano(A, PA), peano_utils:int_to_peano(B, PB).
learner_developmental_goal(divide, A, B, object_level:divide(PA, PB, _)) :-
    peano_utils:int_to_peano(A, PA), peano_utils:int_to_peano(B, PB).

learner_event_to_dict(Event, SafeDict) :-
    dict_pairs(Event, Tag, Pairs),
    maplist(learner_event_pair, Pairs, SafePairs),
    dict_pairs(SafeDict, Tag, SafePairs).

learner_event_pair(Key-Value, Key-Safe) :-
    learner_event_value(Value, Safe).

learner_event_value(Value, Value) :- number(Value), !.
learner_event_value(Value, Value) :- atom(Value), !.
learner_event_value(Value, Value) :- string(Value), !.
learner_event_value(Value, Safe) :-
    is_dict(Value), !, learner_event_to_dict(Value, Safe).
learner_event_value(Value, Safe) :-
    is_list(Value), !, maplist(learner_event_value, Value, Safe).
learner_event_value(Value, Safe) :-
    peano_utils:peano_to_int(Value, Safe), !.
learner_event_value(Value, Safe) :-
    term_to_text(Value, Safe).

learner_knowledge_rows(Knowledge) :-
    findall(
        _{operation: Op, learned: Learned},
        ( member(Op, [add, subtract, multiply, divide]),
          teacher:available_strategies(Op, Available),
          findall(Label,
              ( member(Strategy, Available),
                clause(more_machine_learner:run_learned_strategy(
                           _, _, _, Strategy, _), _),
                term_string(Strategy, Label)
              ),
              TeacherBacked),
          findall(Label,
              ( strategy_synthesis:synthesized_strategy(
                    Op, _, _, _, Name, _, _),
                term_string(Name, Label)
              ),
              Synthesized),
          append(TeacherBacked, Synthesized, Learned0),
          sort(Learned0, Learned)
        ),
        Knowledge).

learner_coordination_request(Request, Base, ValUp, ValDown) :-
    learner_optional_integer(Request, base, 10, Base),
    between(2, 15, Base),
    learner_optional_integer(Request, val_up, 0, ValUp),
    ValUp >= 0,
    (   get_dict_opt(val_down, Request, ValDownValue)
    ->  learner_val_down(ValDownValue, ValDown)
    ;   ValDown = 1
    ),
    ValDown \= fraction(_, 0).

learner_val_down(Value, Value) :-
    number(Value),
    !.
learner_val_down(Value, fraction(Num, Den)) :-
    learner_request_string(Value, String),
    sub_string(String, Before, _, _, "/"),
    !,
    sub_string(String, 0, Before, _, NumString),
    After is Before + 1,
    sub_string(String, After, _, 0, DenString),
    number_string(Num, NumString),
    number_string(Den, DenString),
    integer(Num),
    integer(Den).
learner_val_down(Value, Number) :-
    learner_request_string(Value, String),
    catch(number_string(Number, String), _, fail),
    !.
learner_val_down(Value, String) :-
    learner_request_string(Value, String).

learner_reorganize_request(Request, Domain, A, B, C, D) :-
    (   get_dict_opt(domain, Request, DomainValue)
    ->  learner_request_atom(DomainValue, Domain)
    ;   Domain = fraction_splitting
    ),
    memberchk(Domain, [fraction_splitting, fraction_improper,
                       fraction_of_fraction, fraction_algebra]),
    learner_optional_integer(Request, a, 3, A),
    learner_optional_integer(Request, b, 8, B),
    learner_optional_integer(Request, c, 4, C),
    learner_optional_integer(Request, d, 5, D).

learner_reorganize_problem(fraction_splitting, A, B, _, _,
                           fraction_splitting, reverse(A, B)).
learner_reorganize_problem(fraction_improper, A, B, _, _,
                           fraction_improper, make_improper(A, B)).
learner_reorganize_problem(fraction_of_fraction, A, B, C, D,
                           fraction_of_fraction, ff(A, B, C, D)).
learner_reorganize_problem(fraction_algebra, A, B, _, _,
                           fraction_algebra, relate(A, B)).

learner_optional_integer(Request, Key, Default, Integer) :-
    (   get_dict_opt(Key, Request, Value)
    ->  learner_integer(Value, Integer)
    ;   Integer = Default
    ).

learner_integer(Value, Value) :- integer(Value), !.
learner_integer(Value, Integer) :-
    learner_request_string(Value, String),
    catch(number_string(Number, String), _, fail),
    integer(Number),
    Integer = Number.

learner_request_atom(Value, Atom) :-
    learner_request_string(Value, String),
    atom_string(Atom0, String),
    downcase_atom(Atom0, Atom).

learner_request_string(Value, String) :- string(Value), !, String = Value.
learner_request_string(Value, String) :- atom(Value), !, atom_string(Value, String).

%!  ensure_axiom_toggle_loaded is det.
%
%   Lazy load for tools/axiom_toggle.pl (see the load_runtime note on why it
%   is not a boot-time load). with_output_to(user_error, ...) matters: the
%   module's arche_trace(load) chain prints a banner to stdout at
%   initialization, and an unprotected load would corrupt the JSONL protocol
%   mid-session. A load failure surfaces as an op_exception through
%   handle_request/2's catch.
ensure_axiom_toggle_loaded :-
    (   current_predicate(axiom_toggle:list_toggles/1)
    ->  true
    ;   with_output_to(user_error, use_module(tools(axiom_toggle), []))
    ).

axiom_toggle_action(list, Id, _Request, Response) :-
    !,
    axiom_toggle:list_toggles(Toggles),
    maplist(toggle_export_dict, Toggles, Dicts),
    json_safe(_{action: "list", toggles: Dicts}, Safe),
    ok_response(Id, Safe, Response).
axiom_toggle_action(Action, Id, Request, Response) :-
    memberchk(Action, [enable, disable]),
    !,
    (   get_dict_opt(axiom, Request, AxiomJSON),
        text_value(AxiomJSON, AxiomText),
        AxiomText \== "",
        catch(term_string(Pattern, AxiomText), _, fail),
        nonvar(Pattern)
    ->  (   catch(apply_axiom_toggle(Action, Pattern),
                  error(domain_error(axiom_toggle, _), _),
                  fail)
        ->  matched_toggle_dicts(Pattern, Matched),
            term_to_text(Action, ActionText),
            json_safe(_{action: ActionText, axiom: AxiomText, toggles: Matched},
                      Safe),
            ok_response(Id, Safe, Response)
        ;   format(string(Msg),
                   "no known axiom toggle matches ~w (enumerate them with action=list)",
                   [AxiomText]),
            error_response(Id, unknown_axiom_toggle, Msg, Response)
        )
    ;   error_response(Id, missing_axiom,
            "axiom_toggle enable/disable requires axiom (a toggle term string such as pack(eml))",
            Response)
    ).
axiom_toggle_action(Action, Id, _Request, Response) :-
    format(string(Msg),
           "axiom_toggle action must be list, enable, or disable (got ~w)",
           [Action]),
    error_response(Id, unknown_axiom_toggle_action, Msg, Response).

apply_axiom_toggle(enable, Pattern) :-
    axiom_toggle:enable_axiom(Pattern).
apply_axiom_toggle(disable, Pattern) :-
    axiom_toggle:disable_axiom(Pattern).

matched_toggle_dicts(Pattern, Dicts) :-
    axiom_toggle:list_toggles(Toggles),
    findall(Dict,
            ( member(toggle(ToggleId, Status), Toggles),
              \+ ToggleId \= Pattern,
              toggle_export_dict(toggle(ToggleId, Status), Dict)
            ),
            Dicts).

toggle_export_dict(toggle(ToggleId, Status), _{axiom: IdText, status: StatusText}) :-
    term_to_text(ToggleId, IdText),
    term_to_text(Status, StatusText).

axiom_pack_disabled_response(Pack, Id, Response) :-
    format(string(Message),
           "axiom pack ~w is switched off; enable pack(~w) to query this recorded example",
           [Pack, Pack]),
    error_response(Id, axiom_pack_disabled, Message, Response).
