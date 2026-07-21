% ===================================================================
% RHYTHM Axioms — Dialectical Rhythm
% ===================================================================
%
% This finite table models the manuscript's dialectical rhythm:
% unawareness, awareness, temptation, letting-go, transformed
% unawareness, and the bad-infinite trap.
%
% The compression/expansion polarity (comp_nec, exp_poss, etc.)
% tracks the felt quality of each transition — whether consciousness
% is narrowing (compressive necessity) or opening (expansive
% possibility).
%
% Reader's rule of thumb:
%   - rhythm_transition/2 is the finite transition table.
%   - rhythm_transition_witness/3 explains whether a conclusion is the direct
%     modal transition, such as s(exp_poss(lg)), or the actual state cashed out
%     by a necessity transition, such as s(lg) -> s(u_prime).
%   - Possibility transitions do not cash out as actual states here.
%
% Interpretive correspondence: this material may be read alongside
% Carspecken's Scene Two (The Feeling-Body), where meaning is
% located in internal body awareness and the rhythm of desire
% and letting-go. The modal operators track something like what
% Carspecken calls the "I-feeling mode" prior to the
% subject-object split. The compression/expansion polarity
% maps onto the felt tempo of proprioceptive experience.
% ===================================================================

% --- PML operator declarations ---
% These mirror formal/pml/pml_operators.pl so this file parses standalone.
% In the full system, sequent_engine.pl declares the same operators
% before including this file; declaring them here is idempotent.
:- op(500, fx, comp_nec).
:- op(500, fx, exp_nec).
:- op(500, fx, exp_poss).
:- op(500, fx, comp_poss).
:- op(500, fx, neg).
:- op(1050, xfy, =>).

% --- RHYTHM Material Inferences ---

rhythm_transition(s(u), s(comp_nec(a))).        % Emergence of awareness
rhythm_transition(s(u_prime), s(comp_nec(a))).  % Re-entry into the next cycle
rhythm_transition(s(a), s(exp_poss(lg))).       % Possibility of release
rhythm_transition(s(a), s(comp_poss(t))).       % Possibility of fixation
rhythm_transition(s(t), s(comp_nec(neg(u)))).   % Deepened contraction
rhythm_transition(s(lg), s(exp_nec(u_prime))).  % Sublation / release
rhythm_transition(s(t_b), s(comp_nec(t_n))).    % Bad infinite (Being -> Nothing)
rhythm_transition(s(t_n), s(comp_nec(t_b))).    % Bad infinite (Nothing -> Being)

rhythm_phase(s(u), unawareness).
rhythm_phase(s(u_prime), transformed_unawareness).
rhythm_phase(s(a), awareness).
rhythm_phase(s(t), temptation).
rhythm_phase(s(lg), letting_go).
rhythm_phase(s(t_b), bad_infinite_being).
rhythm_phase(s(t_n), bad_infinite_nothing).

rhythm_modal_term(s(ModalTerm), Modality, Payload) :-
    ModalTerm =.. [Modality, Payload],
    memberchk(Modality, [comp_nec, exp_nec, exp_poss, comp_poss]).

rhythm_transition_witness(From, To, Witness) :-
    rhythm_direct_transition_witness(From, To, Witness),
    !.
rhythm_transition_witness(From, To, Witness) :-
    rhythm_necessity_cashout_witness(From, To, Witness).

rhythm_direct_transition_witness(From, ModalTo,
                              _{kind: rhythm_transition,
                                source: direct_modal_transition,
                                phase: Phase,
                                from: From,
                                to: ModalTo,
                                modal_to: ModalTo,
                                modality: Modality,
                                payload: Payload}) :-
    axiom_pack_enabled(rhythm),
    rhythm_transition(From, ModalTo),
    rhythm_phase(From, Phase),
    rhythm_modal_term(ModalTo, Modality, Payload).
rhythm_necessity_cashout_witness(From, ActualTo,
                              _{kind: rhythm_transition,
                                source: necessity_cashout,
                                phase: Phase,
                                from: From,
                                modal_to: ModalTo,
                                to: ActualTo,
                                modality: Modality,
                                payload: Payload}) :-
    axiom_pack_enabled(rhythm),
    rhythm_transition(From, ModalTo),
    rhythm_phase(From, Phase),
    rhythm_modal_term(ModalTo, Modality, Payload),
    memberchk(Modality, [comp_nec, exp_nec]),
    ActualTo = s(Payload).

% Commitment 2: Emergence of Awareness (Temporal Compression)
proves_impl([A] => [C], _) :-
    rhythm_transition_witness(A, C, _).

% --- RHYTHM Dynamics Structural Rule ---
proves_impl((Premises => Conclusions), History) :-
    axiom_pack_enabled(rhythm),
    select(s(P), Premises, RestPremises), \+ member(s(P), History),
    rhythm_axiom(s(P), s(M_Q)),
    ( rhythm_transition_witness(s(P), s(Q), W),
      W.source == necessity_cashout
    -> proves_impl(([s(Q)|RestPremises] => Conclusions), [s(P)|History])
    ; ((M_Q = exp_poss _ ; M_Q = comp_poss _), (member(s(M_Q), Conclusions) ; member(M_Q, Conclusions)))
    ).

% --- RHYTHM Helpers ---
rhythm_axiom(A, C) :-
    axiom_pack_enabled(rhythm),
    rhythm_transition_witness(A, C, W),
    W.source == direct_modal_transition,
    is_rhythm_modality(C).

is_rhythm_modality(s(comp_nec _)).
is_rhythm_modality(s(exp_nec _)).
is_rhythm_modality(s(exp_poss _)).
is_rhythm_modality(s(comp_poss _)).
