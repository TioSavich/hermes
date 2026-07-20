/** <module> PML Operators and Vocabulary
 *
 *  This module defines the syntax and core vocabulary for Polarized Modal Logic (PML).
 *  It establishes the operators for the three modes of validity (S, O, N) and the
 *  two polarities (Compressive/↓ and Expansive/↑).
 *
 *  (Synthesis_1, Chapter 3)
 */
:- module(pml_operators,
          [ % Modes of Validity
            s/1, o/1, n/1,
            % Polarized Modal Operators
            'comp_nec'/1, 'exp_nec'/1, 'exp_poss'/1, 'comp_poss'/1,
            % Standard Logical Operators
            'neg'/1
            % Note: => (sequent) and conj (conjunction) are used but not explicitly exported as predicates
          ]).

% =================================================================
% Operator Definitions
% =================================================================

% Compressive Necessity (Box_down ↓)
:- op(500, fx, comp_nec).
% Expansive Necessity (Box_up ↑)
:- op(500, fx, exp_nec).
% Expansive Possibility (Diamond_up ↑)
:- op(500, fx, exp_poss).
% Compressive Possibility (Diamond_down ↓)
:- op(500, fx, comp_poss).

% Negation
:- op(500, fx, neg).

% Sequent Arrow
:- op(1050, xfy, =>).

% =================================================================
% Vocabulary Placeholders
% (Ensures predicates can be referenced even if not yet defined)
% =================================================================

%! pml_mode_payload(+P) is semidet.
% Payloads must be instantiated formula terms, not lists or dict-like data.
pml_mode_payload(P) :-
    nonvar(P),
    acyclic_term(P),
    \+ is_list(P),
    \+ is_dict(P).

%! s(P) is semidet.
% Subjective Validity wrapper.
s(P) :-
    pml_mode_payload(P).

%! o(P) is semidet.
% Objective Validity wrapper.
o(P) :-
    pml_mode_payload(P).

%! n(P) is semidet.
% Normative Validity wrapper.
n(P) :-
    pml_mode_payload(P).

%! neg(P) is det.
% Negation.
neg(_).

%! comp_nec(P) is det.
% Compressive necessity modality (↓). Fixation, Crystallization.
comp_nec(_).

%! exp_nec(P) is det.
% Expansive necessity modality (↑). Release, Liquefaction.
exp_nec(_).

%! exp_poss(P) is det.
% Expansive possibility modality (↑). Potential for release.
exp_poss(_).

%! comp_poss(P) is det.
% Compressive possibility modality (↓). Temptation to fixate.
comp_poss(_).
