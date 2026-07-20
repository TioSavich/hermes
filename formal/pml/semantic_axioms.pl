/** <module> Semantic Axioms (Inter-Modal Dynamics)
 *
 *  This module defines the semantic axioms of Polarized Modal Logic (PML).
 *  These axioms govern the vocabulary and the interaction between the modes (S, O, N).
 *  They are defined as material inferences, integrating with the sequent_engine module.
 *
 *  (Synthesis_1, Chapter 3.6 and Chapter 4)
 */
:- module(semantic_axioms,
          [ dialectical_transition/2,
            semantic_material_witness/3
          ]).

% Import operators - must be declared before use
:- op(500, fx, comp_nec).
:- op(500, fx, exp_nec).
:- op(500, fx, exp_poss).
:- op(500, fx, comp_poss).
:- op(500, fx, neg).

% Note: We do not explicitly use_module(sequent_engine), but we rely on its definition of material_inference/3.
:- use_module(pml_operators). % Import operators for readability

% =================================================================
% Multifile Declarations
% =================================================================
% We extend the material_inference predicate defined in sequent_engine.
% CONTRACT: the third argument is a *callable witness goal*, not the literal
% `true`. embodied_prover:pml_rhythm_axiom/2 runs it with call/1, so the goal
% must be idempotent and side-effect-free (here: semantic_material_witness/3,
% which is deterministic for given inputs). A bare `true` remains valid for
% any other contributor that has no witness to attach.
:- multifile embodied_prover:material_inference/3.
:- discontiguous semantic_material_witness/3.

% =================================================================
% Dialectical Rhythm (Data-Driven)
% =================================================================
% Each fact encodes a row from the Section 5 table in synthesized_paper.md:
% Stage -> Modal transition. The generic material_inference clause below
% keeps the implementation concise and prevents duplicate definitions.

dialectical_transition(u,        comp_nec(a)).        % Emergence of tension from unity
dialectical_transition(u_prime,  comp_nec(a)).        % Re-entry into the next cycle
dialectical_transition(a,        exp_poss(lg)).       % Letting-go option
dialectical_transition(a,        comp_poss(t)).       % Temptation to fixate
dialectical_transition(lg,       exp_nec(u_prime)).   % Sublation / release
dialectical_transition(t,        comp_nec(neg(u))).   % Pathological contraction
dialectical_transition(t_b,      comp_nec(t_n)).      % Bad infinite (Being -> Nothing)
dialectical_transition(t_n,      comp_nec(t_b)).      % Bad infinite (Nothing -> Being)

modal_term(Modality, Payload, Term) :-
    Term =.. [Modality, Payload],
    memberchk(Modality, [comp_nec, exp_nec, exp_poss, comp_poss]).

dialectical_interpretation(u, comp_nec(a), emergence_of_tension_from_unity).
dialectical_interpretation(u_prime, comp_nec(a), reentry_into_next_cycle).
dialectical_interpretation(a, exp_poss(lg), letting_go_option).
dialectical_interpretation(a, comp_poss(t), fixation_temptation).
dialectical_interpretation(lg, exp_nec(u_prime), sublation_release).
dialectical_interpretation(t, comp_nec(neg(u)), pathological_contraction).
dialectical_interpretation(t_b, comp_nec(t_n), bad_infinite_being_to_nothing).
dialectical_interpretation(t_n, comp_nec(t_b), bad_infinite_nothing_to_being).

semantic_material_witness([s(Stage)], s(ModalTerm),
                          _{kind: dialectical_transition,
                            premise: s(Stage),
                            conclusion: s(ModalTerm),
                            stage: Stage,
                            modality: Modality,
                            payload: Payload,
                            interpretation: Interpretation}) :-
    dialectical_transition(Stage, ModalTerm),
    modal_term(Modality, Payload, ModalTerm),
    dialectical_interpretation(Stage, ModalTerm, Interpretation).

embodied_prover:material_inference([s(Stage)], s(ModalTerm),
                                   semantic_axioms:semantic_material_witness([s(Stage)], s(ModalTerm), _)) :-
    semantic_material_witness([s(Stage)], s(ModalTerm), _).


% =================================================================
% Inter-Modal Dynamics
% =================================================================
% (Synthesis_1, Chapter 3.6)

% --- Principle 2: The Oobleck Dynamic (S-O Transfer) ---

% Box_down_S => Box_down_O (Effort/Force -> Crystallization)
semantic_material_witness([s(comp_nec(P))], o(comp_nec(P)),
                          _{kind: oobleck_s_to_o_transfer,
                            principle: effort_force_to_crystallization,
                            from: s(comp_nec(P)),
                            to: o(comp_nec(P)),
                            from_mode: s,
                            to_mode: o,
                            modality: comp_nec,
                            payload: P}).

embodied_prover:material_inference([s(comp_nec P)], o(comp_nec P),
                                   semantic_axioms:semantic_material_witness([s(comp_nec(P))], o(comp_nec(P)), _)) :-
    semantic_material_witness([s(comp_nec(P))], o(comp_nec(P)), _).

% Box_up_S => Box_up_O (Release/Openness -> Liquefaction)
semantic_material_witness([s(exp_nec(P))], o(exp_nec(P)),
                          _{kind: oobleck_s_to_o_transfer,
                            principle: release_openness_to_liquefaction,
                            from: s(exp_nec(P)),
                            to: o(exp_nec(P)),
                            from_mode: s,
                            to_mode: o,
                            modality: exp_nec,
                            payload: P}).

embodied_prover:material_inference([s(exp_nec P)], o(exp_nec P),
                                   semantic_axioms:semantic_material_witness([s(exp_nec(P))], o(exp_nec(P)), _)) :-
    semantic_material_witness([s(exp_nec(P))], o(exp_nec(P)), _).

% --- Principle 5: Internalization of Norms (N -> S) ---
% Formulated here as N-N dynamics reflecting the collective rhythm.

% Normative Solidification leading to potential opening
semantic_material_witness([n(comp_nec(P))], n(exp_poss(P)),
                          _{kind: normative_solidification,
                            from: n(comp_nec(P)),
                            to: n(exp_poss(P)),
                            modality_from: comp_nec,
                            modality_to: exp_poss,
                            payload: P,
                            principle: collective_norm_can_open_a_possible_release}).

embodied_prover:material_inference([n(comp_nec P)], n(exp_poss P),
                                   semantic_axioms:semantic_material_witness([n(comp_nec(P))], n(exp_poss(P)), _)) :-
    semantic_material_witness([n(comp_nec(P))], n(exp_poss(P)), _).

% Normative Liquefaction leading to potential re-closure
semantic_material_witness([n(exp_nec(P))], n(comp_poss(P)),
                          _{kind: normative_liquefaction,
                            from: n(exp_nec(P)),
                            to: n(comp_poss(P)),
                            modality_from: exp_nec,
                            modality_to: comp_poss,
                            payload: P,
                            principle: released_norm_can_reclose_as_a_possibility}).

embodied_prover:material_inference([n(exp_nec P)], n(comp_poss P),
                                   semantic_axioms:semantic_material_witness([n(exp_nec(P))], n(comp_poss(P)), _)) :-
    semantic_material_witness([n(exp_nec(P))], n(comp_poss(P)), _).

% =================================================================
% Hylomorphic Shift: O → N (added 2026-04-16 per Phase 5 audit §6)
% =================================================================
% The Phase 5 audit flagged that the three modes — s/1, o/1, n/1 — carry
% no rule-governed handoffs beyond the Oobleck S→O transfer above. Modes
% read as permissive type-tags rather than as inferential registers.
%
% This rule operationalizes the Hegelian dictum "what is rational is
% actual": an objective proof (execution that reaches a formal q_accept)
% licenses a normative commitment. The shift is read directly off
% Brandom's bimodal hylomorphic conceptual realism (ASOT, ch. 1–2): the
% same conceptual content can wear either form; the rule grants the
% practitioner the entitlement to re-wear it normatively once it has
% been objectively made out.
%
% We do not yet add an N → S internalization rule. N → S is named in the
% prose accompanying this framework but the conditions under which
% normative commitment becomes subjectively embraced (internalized)
% depend on trace-grounding via the I-feeling mechanism, which the
% intersubjective praxis module only partly models. That rule awaits
% the next revision.
semantic_material_witness([o(P)], n(P),
                          _{kind: hylomorphic_o_to_n_shift,
                            from: o(P),
                            to: n(P),
                            from_mode: o,
                            to_mode: n,
                            payload: P,
                            warrant: objective_proof_licenses_normative_commitment,
                            limitation: no_n_to_s_internalization_rule_here}).

embodied_prover:material_inference([o(P)], n(P),
                                   semantic_axioms:semantic_material_witness([o(P)], n(P), _)) :-
    semantic_material_witness([o(P)], n(P), _).
