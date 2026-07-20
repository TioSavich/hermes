/** <module> Sequent calculus engine with negation-pair coherence checks.
 *
 * IMPORTANT: this module does NOT implement Brandomian incompatibility
 * semantics. It implements classical sequent calculus over `neg(P)`
 * pairs (the law of non-contradiction) plus explosion-from-incoherence
 * plus classical S5 elimination rules over a generic `nec/1` operator.
 *
 * What is missing (relative to Brandomian incompatibility semantics):
 *   - incompatibility hyperedges (sets X such that X is incoherent
 *     without any binary contradiction inside X)
 *   - `incompatibility_entails/2`: A entails B iff everything
 *     incompatible with B is incompatible with A
 *   - minimal-incompatible negation construction
 *   - persistence and the full Brandomian closure-of-incoherence
 *
 * The Brandomian machinery now lives in the sibling module
 * `arche-trace/brandomian_incompatibility.pl` (hyperedges, persistence,
 * `incompatibility_entails/2`, minimal-incompatible negation). The
 * opt-in bridge `arche-trace/sequent_brandom_bridge.pl` unions the two
 * notions of incoherence and uses THIS engine as a backstop that audits
 * the Brandomian relation for explosion. Neither is loaded by default;
 * this engine's behavior is unchanged. See
 * `docs/INCOMPATIBILITY_SPLIT_PLAN.md` for the design.
 *
 * Historical name: this file was `incompatibility_semantics.pl` until
 * 2026-05-24. The rename honors the project's voice commitment not to
 * overclaim implementation. The Brandom check report at
 * `docs/brandom-check-reports/2026-05-23-incompatibility-semantics.md`
 * named the gap; the split plan executed it.
 *
 * The PML operators (s/1, o/1, n/1, comp_nec/1, exp_nec/1, exp_poss/1,
 * comp_poss/1, neg/1) are re-exported from `pml(pml_operators)` for
 * SYNTACTIC compatibility with the axiom packs. The engine treats them
 * as syntactic constructors used by the law-of-non-contradiction matcher
 * and the S5 elimination rules. It does NOT give the PML operators the
 * modal semantics described in `pml/Modal_Logic/`.
 *
 * Reader's rule of thumb for the public predicates:
 *   - proves/1 is a yes/no theorem check.
 *   - incoherent/1 is a yes/no context-incoherence check.
 *   - incoherent_witness/2 explains why the engine found incoherence when the
 *     reason is structural enough to expose safely.
 *
 * The engine provides proves/1 — a sequent calculus prover operating on
 * sequents of the form Premises => Conclusions. It is scene-agnostic:
 * it does not care whether it is proving geometry, arithmetic, or
 * embodied modal logic. The axiom sets that establish the current
 * "assumptive horizon" are included from their respective modules:
 *
 *   formalization/axioms_geometry.pl    — quadrilateral taxonomy
 *   formalization/axioms_robinson.pl    — Robinson Q, arithmetic grounding
 *   formalization/axioms_number_theory.pl — Euclid's prime proof
 *   pml/axioms_eml.pl                  — embodied modal logic
 *   learner/axioms_domains.pl          — domain switching, norms, fractions
 *
 * The vanishing-point mark (automata.pl) and hollow proofs
 * (embodied_prover.pl) record where formalization honestly stops being
 * able to say anything.
 *
 * Priority ordering: Identity/Explosion -> Material Axioms -> Structural
 * Rules -> Reduction Schemata. The include directives preserve this
 * ordering: axiom sets contribute proves_impl/2 and is_incoherent/1
 * clauses at the appropriate priority level.
 */
:- module(sequent_engine,
          [ proves/1, safe_proves/2, is_recollection/2
          , incoherent/1, incoherent_witness/2
          , incoherent_base/1, incoherent_base_witness/2
          , entails_via_incompatibility/2, entails_via_incompatibility_witness/3
          , eml_transition_witness/3
          , robinson_axiom_witness/3, robinson_incoherence_witness/2
          , number_theory_self_defeat_witness/2, number_theory_factor_witness/3
          , normalize/2
          , set_domain/1, current_domain/1
          , enable_axiom_pack/1, disable_axiom_pack/1, enabled_axiom_pack/1, with_axiom_packs/2
          , product_of_list/2
          , s/1, o/1, n/1, 'comp_nec'/1, 'exp_nec'/1, 'exp_poss'/1, 'comp_poss'/1, 'neg'/1
          , bounded_region/4, equality_iterator/3
          % Normative Crisis Detection
          , prohibition/2, normative_crisis/2, check_norms/1, current_domain_context/1
          ]).

:- use_module(formalization(grounded_arithmetic), [incur_cost/1]).
:- use_module(library(time), [call_with_time_limit/2]).
:- use_module(pml(mua_relations), [lx_for/3, grounding_metaphor/2]).
:- use_module(pml(utils), [match_antecedents/2, select/3]).
:- use_module(learner(deontic_scorekeeper),
              [ commitment/2,
                entitlement/2,
                deontic_incoherent/2,
                requires_entitlement/1
              ]).
:- reexport(pml(pml_operators)).

:- discontiguous proves_impl/2.
:- discontiguous is_incoherent/1.
:- discontiguous axiom_incoherence_witness/2.
:- multifile axiom_incoherence_witness/2.
:- discontiguous check_norms/1.
:- dynamic axiom_pack_enabled/1.

% =================================================================
% Operators
% =================================================================

:- op(500, fx, comp_nec).
:- op(500, fx, exp_nec).
:- op(500, fx, exp_poss).
:- op(500, fx, comp_poss).
:- op(500, fx, neg).
:- op(1050, xfy, =>).
:- op(550, xfy, rdiv).

% =================================================================
% Engine Helpers
% =================================================================

default_axiom_pack(robinson).
default_axiom_pack(geometry).
default_axiom_pack(number_theory).
default_axiom_pack(eml).
default_axiom_pack(domains).

initialize_axiom_packs :-
    retractall(axiom_pack_enabled(_)),
    forall(default_axiom_pack(Pack),
           assertz(axiom_pack_enabled(Pack))).

known_axiom_pack(Pack) :-
    default_axiom_pack(Pack),
    !.
known_axiom_pack(Pack) :-
    throw(error(domain_error(axiom_pack, Pack), _)).

enable_axiom_pack(Pack) :-
    known_axiom_pack(Pack),
    (   axiom_pack_enabled(Pack)
    ->  true
    ;   assertz(axiom_pack_enabled(Pack))
    ).

disable_axiom_pack(Pack) :-
    known_axiom_pack(Pack),
    retractall(axiom_pack_enabled(Pack)).

enabled_axiom_pack(Pack) :-
    axiom_pack_enabled(Pack).

set_enabled_axiom_packs(Packs) :-
    retractall(axiom_pack_enabled(_)),
    forall(member(Pack, Packs),
           assertz(axiom_pack_enabled(Pack))).

normalize_axiom_packs(all, Packs) :-
    !,
    findall(Pack, default_axiom_pack(Pack), Packs).
normalize_axiom_packs(Packs, Normalized) :-
    is_list(Packs),
    !,
    maplist(known_axiom_pack, Packs),
    sort(Packs, Normalized).
normalize_axiom_packs(Packs, _) :-
    throw(error(type_error(list, Packs), _)).

with_axiom_packs(Packs, Goal) :-
    normalize_axiom_packs(Packs, Normalized),
    findall(Pack, axiom_pack_enabled(Pack), Saved),
    setup_call_cleanup(
        set_enabled_axiom_packs(Normalized),
        call(Goal),
        set_enabled_axiom_packs(Saved)
    ).

option_value(Key, [Option|_], Value) :-
    Option =.. [Key, Value],
    !.
option_value(Key, [_|Rest], Value) :-
    option_value(Key, Rest, Value).

safe_proves(Sequent, Options) :-
    (   option_value(time_limit, Options, TimeLimit)
    ->  true
    ;   TimeLimit = 2
    ),
    (   option_value(packs, Options, Packs)
    ->  SafeGoal = with_axiom_packs(Packs, proves(Sequent))
    ;   SafeGoal = proves(Sequent)
    ),
    catch(call_with_time_limit(TimeLimit, SafeGoal),
          time_limit_exceeded,
          fail).

% select/3 and match_antecedents/2 imported from pml(utils).

% =================================================================
% PRIORITY 1: Identity and Explosion (scene-agnostic)
% =================================================================

proves(Sequent) :- proves_impl(Sequent, []).

% Axiom of Identity (A |- A)
proves_impl((Premises => Conclusions), _) :-
    member(P, Premises), member(P, Conclusions), !.

% From base incoherence (Explosion)
proves_impl((Premises => _), _) :-
    is_incoherent(Premises), !.

% Incoherence wrapper
incoherent(X) :- incoherent_witness(X, _), !.


%!  incoherent_witness(+Context, -Witness) is semidet.
%
%   Human-readable reason for a context's incoherence. The first case exposes
%   structural negation-pair incoherence. The second preserves compatibility
%   with axiom-pack incoherence clauses. The third records that empty-succedent
%   derivability, not a directly inspectable structural pair, made the context
%   incoherent.
incoherent_witness(Context,
                   _{kind: incoherence,
                     source: base_structural_pair,
                     context: Context,
                     base_witness: BaseWitness}) :-
    incoherent_base_witness(Context, BaseWitness),
    !.
incoherent_witness(Context,
                   _{kind: incoherence,
                     source: axiom_pack_witness,
                     context: Context,
                     axiom_witness: AxiomWitness}) :-
    axiom_incoherence_witness(Context, AxiomWitness),
    !.
incoherent_witness(Context,
                   _{kind: incoherence,
                     source: axiom_pack_incoherence,
                     context: Context}) :-
    is_incoherent(Context),
    !.
incoherent_witness(Context,
                   _{kind: incoherence,
                     source: empty_succedent_derivation,
                     context: Context,
                     sequent: (Context => [])}) :-
    proves(Context => []).

% Law of Non-Contradiction
incoherent_base(X) :- incoherent_base_witness(X, _).


%!  incoherent_base_witness(+Context, -Witness) is semidet.
%
%   A structural witness for the law of non-contradiction. This intentionally
%   handles only the two syntactic contradiction shapes this engine owns:
%   `P` with `neg(P)`, and same-marker pairs such as `s(P)` with `s(neg(P))`.
incoherent_base_witness(Context,
                        _{kind: base_incoherence,
                          pattern: plain_negation_pair,
                          positive: P,
                          negative: NegP,
                          support: [P, NegP],
                          context: Context}) :-
    member(P, Context),
    NegP = neg(P),
    member(NegP, Context),
    !.
incoherent_base_witness(Context,
                        _{kind: base_incoherence,
                          pattern: same_marker_negation_pair,
                          marker: D,
                          positive: D_P,
                          negative: D_NegP,
                          support: [D_P, D_NegP],
                          context: Context}) :-
    member(D_P, Context),
    D_P =.. [D, P],
    member(D, [s,o,n]),
    D_NegP =.. [D, neg(P)],
    member(D_NegP, Context),
    !.

is_incoherent(Y) :- incoherent_base(Y), !.

% =================================================================
% PRIORITY 2: Material Axioms (from axiom sets)
% =================================================================

:- include('../formalization/axioms_robinson').
:- include('../formalization/axioms_geometry').
:- include('../formalization/axioms_number_theory').
:- include('../pml/axioms_eml').
:- include('../learner/axioms_domains').

% =================================================================
% PRIORITY 3: Structural Rules (scene-agnostic engine)
% =================================================================

% General Forward Chaining (Modus Ponens / MMP)
proves_impl((Premises => Conclusions), History) :-
    Module = sequent_engine,
    clause(Module:proves_impl((A_clause => [C_clause]), _), B_clause),
    copy_term((A_clause, C_clause, B_clause), (Antecedents, Consequent, Body)),
    is_list(Antecedents),
    match_antecedents(Antecedents, Premises),
    call(Module:Body),
    \+ member(Consequent, Premises),
    proves_impl(([Consequent|Premises] => Conclusions), History).

% Arithmetic Evaluation (legacy support)
proves_impl(([Premise|RestPremises] => Conclusions), History) :-
    (Premise =.. [Index, Expr], member(Index, [s, o, n]) ; (Index = none, Expr = Premise)),
    (compound(Expr) -> (
        functor(Expr, F, _),
        excluded_predicates(Excluded),
        \+ member(F, Excluded)
    ) ; true),
    \+ (compound(Expr), functor(Expr, rdiv, 2)),
    catch(Value is Expr, _, fail), !,
    (Index \= none -> NewPremise =.. [Index, Value] ; NewPremise = Value),
    proves_impl(([NewPremise|RestPremises] => Conclusions), History).

% =================================================================
% PRIORITY 4: Reduction Schemata (scene-agnostic logic)
% =================================================================

% Left Negation (LN)
proves_impl((P => C), H) :- select(neg(X), P, P1), proves_impl((P1 => [X|C]), H).
proves_impl((P => C), H) :- select(D_NegX, P, P1), D_NegX=..[D, neg(X)], member(D,[s,o,n]), D_X=..[D, X], proves_impl((P1 => [D_X|C]), H).

% Right Negation (RN)
proves_impl((P => C), H) :- select(neg(X), C, C1), proves_impl(([X|P] => C1), H).
proves_impl((P => C), H) :- select(D_NegX, C, C1), D_NegX=..[D, neg(X)], member(D,[s,o,n]), D_X=..[D, X], proves_impl(([D_X|P] => C1), H).

% Conjunction
proves_impl((P => C), H) :- select(conj(X,Y), P, P1), proves_impl(([X,Y|P1] => C), H).
proves_impl((P => C), H) :- select(s(conj(X,Y)), P, P1), proves_impl(([s(X),s(Y)|P1] => C), H).
proves_impl((P => C), H) :- select(conj(X,Y), C, C1), proves_impl((P => [X|C1]), H), proves_impl((P => [Y|C1]), H).
proves_impl((P => C), H) :- select(s(conj(X,Y)), C, C1), proves_impl((P => [s(X)|C1]), H), proves_impl((P => [s(Y)|C1]), H).

% S5 Modal rules
proves_impl((P => C), H) :- select(nec(X), P, P1), !, ( proves_impl((P1 => C), H) ; \+ proves_impl(([] => [X]), []) ).
proves_impl((P => C), H) :- select(nec(X), C, C1), !, ( proves_impl((P => C1), H) ; proves_impl(([] => [X]), []) ).

% =================================================================
% Syntactic vocabulary constructors
% =================================================================

% PML operators (s/1, o/1, n/1, neg/1, comp_nec/1, etc.) now live
% in pml/pml_operators.pl and are re-exported via :- reexport(pml(pml_operators)).

% These predicates reserve functor names used inside sequents. They must not
% succeed as raw goals, otherwise the engine can "prove" domain facts without
% going through the sequent rules.
square(_) :- fail.
rectangle(_) :- fail.
rhombus(_) :- fail.
parallelogram(_) :- fail.
trapezoid(_) :- fail.
kite(_) :- fail.
quadrilateral(_) :- fail.
r1(_) :- fail.
r2(_) :- fail.
r3(_) :- fail.
r4(_) :- fail.
r5(_) :- fail.
r6(_) :- fail.
prime(_) :- fail.
composite(_) :- fail.
divides(_, _) :- fail.
is_complete(_) :- fail.
analyze_euclid_number(_, _) :- fail.
rdiv(_, _) :- fail.
iterate(_, _, _) :- fail.
partition(_, _, _) :- fail.

bounded_region(I, L, U, R) :- ( number(I), I >= L, I =< U -> R = in_bounds(I) ; R = out_of_bounds(I) ).

equality_iterator(T, T, T) :- !.
equality_iterator(C, T, R) :- C < T, C1 is C + 1, equality_iterator(C1, T, R).

:- initialization(initialize_axiom_packs).
