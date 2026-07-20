/** <module> Intersubjective Praxis (Multi-agent Dynamics)
 *
 *  This module implements the dynamics of interaction, dialogue, and recognition
 *  between multiple agents. It focuses on the Oobleck Dynamic and the structure
 *  of mutual recognition (Geist).
 *
 *  (Synthesis_1, Chapter 5.3 and 7.3)
 */
:- module(intersubjective_praxis,
          [ oobleck_transition/4,
            intersubjective_material_witness/3
          ]).

% Import operators - must be declared before use
:- op(500, fx, comp_nec).
:- op(500, fx, exp_nec).
:- op(500, fx, exp_poss).
:- op(500, fx, comp_poss).
:- op(500, fx, neg).

:- use_module(arche_trace(sequent_engine)).
:- use_module(pml_operators).

% =================================================================
% Multifile Declarations
% =================================================================
% Extend the logic engine with intersubjective axioms.
:- multifile embodied_prover:material_inference/3.
:- discontiguous intersubjective_material_witness/3.

% =================================================================
% The Oobleck Dynamic (Inter-Agent S-O Transfer)
% =================================================================
% Principle 2 (Oobleck) captured as a compact rule table

oobleck_transition(
    comp_nec(action(A, aggressive)),
    comp_nec(position(B, crystallized)),
    A, B
).
oobleck_transition(
    exp_nec(action(A, listening)),
    exp_nec(position(B, liquefied)),
    A, B
).

oobleck_transition_interpretation(aggressive, crystallized,
                                  aggressive_action_crystallizes_the_other).
oobleck_transition_interpretation(listening, liquefied,
                                  listening_action_liquefies_the_other).

modal_payload(comp_nec(Term), comp_nec, Term).
modal_payload(exp_nec(Term), exp_nec, Term).

intersubjective_material_witness(
    [s(LHS)],
    o(RHS),
    _{kind: inter_agent_oobleck_transfer,
      from: s(LHS),
      to: o(RHS),
      actor: A,
      other: B,
      actor_distinct_from_other: true,
      modality: Modality,
      action_style: ActionStyle,
      position_state: PositionState,
      interpretation: Interpretation}
) :-
    oobleck_transition(LHS, RHS, A, B),
    A \= B,
    modal_payload(LHS, Modality, action(A, ActionStyle)),
    modal_payload(RHS, Modality, position(B, PositionState)),
    oobleck_transition_interpretation(ActionStyle, PositionState, Interpretation),
    !.

embodied_prover:material_inference(
    [s(LHS)],
    o(RHS),
    intersubjective_praxis:intersubjective_material_witness([s(LHS)], o(RHS), _)
) :-
    intersubjective_material_witness([s(LHS)], o(RHS), _).

% =================================================================
% Recognition (Anerkennung)
% =================================================================
% The Grand Sublation: Forgiveness (Mutual Recognition) realizes Geist.
% (Synthesis_1, Chapter 7.3)

% Mutual Confession and Forgiveness leads to necessary normative release (Geist).
% [n(confession(A)), n(confession(B))] => [n(exp_nec(forgiveness(A, B)))]
intersubjective_material_witness(
    [n(confession(A)), n(confession(B))],
    n(exp_nec(forgiveness(A, B))),
    _{kind: mutual_recognition,
      from: [n(confession(A)), n(confession(B))],
      to: n(exp_nec(forgiveness(A, B))),
      participants: [A, B],
      participants_distinct: true,
      normative_release: n(exp_nec(forgiveness(A, B))),
      principle: mutual_confession_licenses_forgiveness}
) :-
    A \= B,
    !.

embodied_prover:material_inference(
    [n(confession(A)), n(confession(B))],
    n(exp_nec(forgiveness(A, B))),
    intersubjective_praxis:intersubjective_material_witness(
        [n(confession(A)), n(confession(B))],
        n(exp_nec(forgiveness(A, B))),
        _
    )
).
