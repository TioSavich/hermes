/** <module> Pragmatic Axioms (The Axioms of Praxis)
 *
 *  This module defines the pragmatic axioms governing embodied action,
 *  separated from the semantic rules. These articulate the fundamental
 *  drives and limitations of praxis by integrating them directly into the logic.
 *
 *  (Synthesis_1, Chapter 4.1)
 */
:- module(pragmatic_axioms,
          [
            i_feeling/1,        % I_f (The Elusive Subject)
            identity_claim/1,   % C_Id (The Objectified Self)
            impetus/1,          % I (Holistic striving)
            pragmatic_material_witness/3,
            pragmatic_incoherence_witness/2
          ]).

% Import operators - must be declared before use
:- op(500, fx, comp_nec).
:- op(500, fx, exp_nec).
:- op(500, fx, exp_poss).
:- op(500, fx, comp_poss).
:- op(500, fx, neg).

:- use_module(sequent(automata),
              [generate_vanishing_point/1, contains_vanishing_point/1]).
:- use_module(sequent(sequent_engine)).
:- use_module(pml_operators).

% =================================================================
% Multifile Declarations
% =================================================================
% Extend the logic engine with the pragmatic axioms.
:- multifile embodied_prover:material_inference/3.
:- multifile sequent_engine:is_incoherent/1.
:- multifile sequent_engine:axiom_incoherence_witness/2.

% =================================================================
% The Vocabulary of Praxis
% =================================================================

%!  i_feeling(?I_f) is semidet.
%   The I-Feeling Mode (I_f): The singular, unifying aspect of experience; the elusive subject.
%   Modeled with the vanishing-point mark so a concrete binding is refused.
i_feeling(I_f) :-
    ( var(I_f) -> generate_vanishing_point(I_f)
    ; contains_vanishing_point(I_f)
    ).

%!  identity_claim(?C_Id) is semidet.
%   The Identity Claim (C_Id): The articulated, objectified self (the "me").
%   Must be a concrete term (cannot carry the vanishing-point mark).
identity_claim(C_Id) :-
    \+ contains_vanishing_point(C_Id).

%!  impetus(?I) is semidet.
%   The Impetus to Act (I): The holistic, pre-conceptual striving.
%   Boundary: represented here by the named finite surface available to this
%   axiom pack; no stronger formalization of holistic striving is claimed.
impetus(holistic_striving).

% =================================================================
% Axiom 1: The Elusive Subject (S-O Inversion)
% =================================================================
% Any attempt to subjectively fixate (Box_down_S) the I-Feeling (I_f)
% results in its necessary objective dissolution (Box_up_O).
% (Synthesis_1, Chapter 3.6.1, Axiom 1)

% Box_down_S(I_f) => Box_up_O(I_f)
pragmatic_material_witness(
    [s(comp_nec(IFeeling))],
    o(exp_nec(IFeeling)),
    _{kind: elusive_subject_inversion,
      axiom: elusive_subject,
      from: s(comp_nec(IFeeling)),
      to: o(exp_nec(IFeeling)),
      subject: IFeeling,
      subject_has_trace: true,
      principle: subjective_fixation_of_the_i_feeling_dissolves_objectively}
) :-
    i_feeling(IFeeling),
    !.

embodied_prover:material_inference(
    [s(comp_nec IFeeling)],
    o(exp_nec IFeeling),
    pragmatic_axioms:pragmatic_material_witness(
        [s(comp_nec(IFeeling))],
        o(exp_nec(IFeeling)),
        _
    )
) :-
    pragmatic_material_witness(
        [s(comp_nec(IFeeling))],
        o(exp_nec(IFeeling)),
        _
    ).

% =================================================================
% Axiom 3: The Unsatisfiable Desire
% =================================================================
% The infinite desire for recognition of the "I" (I_f) can never be fully
% satisfied by the recognition of a finite identity claim (C_Id).
% (Synthesis_1, Chapter 4.1.1, Axiom 3)

% This is implemented as an incoherence: It is impossible to simultaneously
% hold that an Identity Claim (C_Id) fully represents the I-Feeling (I_f).

pragmatic_incoherence_witness(
    Context,
    _{kind: unsatisfiable_desire,
      axiom: unsatisfiable_desire,
      context: Context,
      blocked_claim: n(represents(C_Id, IFeeling)),
      identity_claim: C_Id,
      i_feeling: IFeeling,
      identity_is_finite: true,
      i_feeling_has_trace: true,
      reason: finite_identity_claim_cannot_fully_represent_the_trace_bearing_i_feeling}
) :-
    member(n(represents(C_Id, IFeeling)), Context),
    identity_claim(C_Id),
    i_feeling(IFeeling),
    !.

sequent_engine:axiom_incoherence_witness(Context, Witness) :-
    pragmatic_incoherence_witness(Context, Witness).

sequent_engine:is_incoherent(X) :-
    pragmatic_incoherence_witness(X, _).
