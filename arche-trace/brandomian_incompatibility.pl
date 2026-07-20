/** <module> Brandomian material incompatibility engine
 *
 * This module models the machinery that the classical sequent engine
 * (`arche-trace/sequent_engine.pl`) deliberately does NOT carry: material
 * incompatibility as semantically primitive, in Brandom's (2008, Between
 * Saying and Doing, Technical Appendix) order of explanation.
 *
 * The order of explanation matters. The classical engine starts from formal
 * negation (`neg/1`) and the law of non-contradiction, then derives a notion
 * of incoherence and, from incoherence, EXPLOSION (anything follows). This
 * module inverts that: incompatibility between contents is the primitive,
 * recorded as data (`incompatible_set/1`), and the only thing that counts as
 * incoherent is a set that contains a declared incompatible set. There is no
 * explosion rule here. A set is incoherent or it is not; nothing "follows from"
 * incoherence inside this module. That absence is the point — it is what makes
 * the relation non-explosive, and it is what the classical engine is used to
 * back-stop in `arche-trace/sequent_brandom_bridge.pl`.
 *
 * What this module provides, and what it does NOT claim:
 *
 *  - `incompatible_set/1` — a hyperedge: a set of contents that cannot be held
 *    together. Crucially this includes EMERGENT hyperedges: sets that are
 *    jointly incoherent while no proper subset is. The ripe-blackberry seed
 *    illustrates the case; the incommensurability seed below carries it with
 *    a machine-checked provenance chain (see the seed comment and
 *    `docs/research/2026-07-02-emergent-hyperedge-search.md` for what the
 *    corpus does and does not attest). The classical engine cannot represent
 *    these; this module can.
 *  - persistence (Brandom's monotonicity of incompatibility) is built into
 *    `brandomian_incoherent/1`: every superset of an incompatible set is
 *    incoherent. It is checked on query, not saturated at load.
 *  - `incompatibility_entails/2` — A entails B iff everything incompatible with
 *    B is incompatible with A. This is Brandom's incompatibility-entailment,
 *    NOT classical consequence. It is a FINITE APPROXIMATION: it ranges only
 *    over the declared incompatible sets, so it is exactly as complete as the
 *    incompatibility data is. Sparse data yields too-strong entailments; that
 *    is a property of the data, not a bug in the relation. See
 *    `docs/negation-and-incompatibility.md`.
 *  - `brandomian_neg/2` — negation as the minimal incompatible: the negation of
 *    P is the family of minimal sets that rule P out. This is a derived
 *    relation over `incompatible_set/1`, distinct from the syntactic `neg/1`
 *    operator the classical engine uses.
 *
 * The data model is propositional: a "content" is a ground Prolog term, and an
 * incompatible set is a sorted list of them. This keeps subset, persistence,
 * and entailment purely structural and decidable. Callers that work with
 * mode-wrapped PML atoms (`o(...)`, `s(...)`, `n(...)`) pass them as ground
 * terms like any other content.
 *
 * `incompatible_set/1` is multifile + dynamic so axiom packs and other modules
 * can contribute hyperedges. The seed facts below are deliberately small and
 * are there to (a) give the bridge's backstop something to audit and (b)
 * demonstrate the classical/Brandomian divergence the split plan
 * (`docs/INCOMPATIBILITY_SPLIT_PLAN.md`, step 5) asked for.
 *
 * Consolidation (2026-07): this module is the CANONICAL incompatibility
 * relation. The other incompatibility engines feed it rather than running
 * parallel relations. Feeders share one contract: loading is explicit and
 * reversible (never a use_module side effect); every contributed hyperedge
 * is a sorted ground list of arity >= 2 asserted through
 * `add_incompatible_set/1`; each feeder keeps its own bookkeeping so its
 * unload retracts exactly its own contribution; and a set that already
 * exists in the relation is never claimed by a second feeder. Current
 * feeders: `registry_incompatibility_adapter:load_registry_hyperedges/0`
 * (misconception-registry pairs),
 * `incompatibility_discovery:install_discovered_hyperedges/2` (bounded
 * finite discovery — the discovery engine proposes classified sets, this
 * relation records them), and
 * `literature_deontic_bridge:install_lit_incompatible_sets/1`
 * (literature-derived rule/commitment pair edges).
 */
:- module(brandomian_incompatibility,
          [ incompatible_set/1,            % ?Set
            brandomian_incoherent/1,       % +Set
            coherent_set/1,                % +Set
            minimal_incompatible_set/1,    % ?Set
            incompatibility_profile/2,     % +Content, -MinimalSets
            incompatibility_entails/2,     % +A, +B
            brandomian_neg/2,              % +Content, -MinimalIncompatiblePartners
            add_incompatible_set/1,        % +Set
            retract_incompatible_set/1     % +Set
          ]).

:- use_module(library(lists)).

:- multifile incompatible_set/1.
:- dynamic incompatible_set/1.

% =================================================================
% Seed hyperedges
% =================================================================
%
% Each seed is a SORTED ground list. Three jobs:
%   1. The emergent hyperedge (ripe-blackberry) — jointly incoherent, no proper
%      subset incoherent. This is the case the classical engine provably misses.
%   2. A small arithmetic incompatibility lattice (even/odd/prime/composite)
%      that makes `incompatibility_entails/2` produce a correct MATERIAL
%      entailment (prime-greater-than-2 entails odd) and correctly REFUSE a
%      false one (odd does not entail prime-greater-than-2). The third fact
%      (composite vs prime) is what blocks the false entailment — a worked
%      example of why richer incompatibility data yields better entailment.
%   3. The incommensurability triple — the one emergent hyperedge in this repo
%      whose joint incoherence is machine-checked rather than seed-asserted,
%      carried here with its provenance so the emergent claim does not rest on
%      the blackberry illustration alone.

% --- Emergent hyperedge: a ripe blackberry is dark, not red. -------------
% No pair inside is incoherent: blackberry+ripe is fine, blackberry+red is fine
% (unripe blackberries are red), ripe+red is fine (a ripe strawberry). Only the
% triple cannot be held together. Brandom's canonical example.
incompatible_set([blackberry, red, ripe]).

% --- Emergent hyperedge, catalogue-attested: incommensurability. ---------
% "The stick grounds length" + "length is a count of stick-units" + "the
% diagonal of the unit square is measured" cannot be held together, while
% every pair can: the diagonal is incommensurable with the side (sqrt(2) is
% irrational), so a count-of-units reading has no value for it.
% Provenance chain, each link runnable:
%   - catalogue row: base_metaphor_breaks_at/3 for arithmetic_is_measuring_stick
%     (formal/formalization/grounding_metaphors.pl), a Lakoff & Nunez break-point;
%   - compiled form: compiled_break(measuring_stick_incommensurability, ...)
%     (arche-trace/defeasible_inference.pl), whose classification as
%     emergent_defeat carries a one-element-removal minimality witness
%     (classify_defeat_witness/4);
%   - re-derived by the bounded discovery sweep on Big Red iteration7
%     (arche-trace/data/incompatibility_sets_discovered.pl,
%     discovered_set_kind/3 = emergent).
% Scope, stated precisely: this triple is literature-catalogued and
% machine-checked; it is not derived from the student/misconception corpus,
% whose incompatibility facts are all pairs. Search method and result:
% docs/research/2026-07-02-emergent-hyperedge-search.md.
incompatible_set([o(diagonal_of_unit_square_measured),
                  o(length_is_count_of_units),
                  o(grounded(measuring_stick))]).

% --- Arithmetic incompatibility lattice ----------------------------------
incompatible_set([even, odd]).
incompatible_set([even, prime_greater_than_2]).
incompatible_set([composite, prime_greater_than_2]).

% =================================================================
% Coherence / incoherence (persistence baked in)
% =================================================================

%!  brandomian_incoherent(+Set) is semidet.
%
%   Set is incoherent iff some declared incompatible set is a subset of it.
%   This is persistence: supersets of an incompatible set are incompatible.
%   There is no explosion clause — incoherence is a verdict about Set, it does
%   not license deriving arbitrary further content.
brandomian_incoherent(Set) :-
    is_list(Set),
    sort(Set, Sorted),
    incompatible_set(Bad),
    subset_eq(Bad, Sorted),
    !.

%!  coherent_set(+Set) is semidet.
%
%   The complement of brandomian_incoherent/1 over a concrete set.
coherent_set(Set) :-
    is_list(Set),
    \+ brandomian_incoherent(Set).

% subset by structural equality (contents are ground; avoid unifying distinct
% contents that merely share variables).
subset_eq([], _).
subset_eq([X|Xs], Set) :-
    memberchk_eq(X, Set),
    subset_eq(Xs, Set).

memberchk_eq(X, [Y|_]) :- X == Y, !.
memberchk_eq(X, [_|Ys]) :- memberchk_eq(X, Ys).

% =================================================================
% Minimality and profiles
% =================================================================

%!  minimal_incompatible_set(?Set) is nondet.
%
%   A declared incompatible set with no proper incompatible subset. The emergent
%   hyperedges are exactly the minimal sets of size >= 3.
minimal_incompatible_set(Set) :-
    incompatible_set(Set),
    \+ ( incompatible_set(Smaller),
         Smaller \== Set,
         subset_eq(Smaller, Set)
       ).

%!  incompatibility_profile(+Content, -MinimalSets) is det.
%
%   MinimalSets is the list of minimal incompatible sets that contain Content.
%   This is the content's incompatibility profile — the Brandomian "meaning" of
%   Content insofar as it is fixed by what it rules out.
incompatibility_profile(Content, MinimalSets) :-
    findall(Set,
            ( minimal_incompatible_set(Set),
              memberchk_eq(Content, Set)
            ),
            Sets0),
    sort(Sets0, MinimalSets).

%!  brandomian_neg(+Content, -Partners) is det.
%
%   Negation as minimal incompatible: Partners is the family of minimal sets
%   that rule Content out, each with Content removed. The negation of Content is
%   "whatever is entailed by everything incompatible with Content"; concretely
%   it is presented here as these minimal incompatible partner-sets. Distinct
%   from the syntactic neg/1 operator used by the classical engine.
brandomian_neg(Content, Partners) :-
    incompatibility_profile(Content, MinimalSets),
    findall(Partner,
            ( member(Set, MinimalSets),
              exclude_eq(Content, Set, Partner)
            ),
            Partners0),
    sort(Partners0, Partners).

exclude_eq(_, [], []).
exclude_eq(X, [Y|Ys], Zs) :- X == Y, !, exclude_eq(X, Ys, Zs).
exclude_eq(X, [Y|Ys], [Y|Zs]) :- exclude_eq(X, Ys, Zs).

% =================================================================
% Incompatibility entailment
% =================================================================

%!  incompatibility_entails(+A, +B) is semidet.
%
%   A entails B (in Brandom's incompatibility sense) iff everything incompatible
%   with B is also incompatible with A: for every declared incompatible set S
%   containing B, replacing B by A keeps the set incoherent.
%
%   Two guards make this non-trivial:
%     - There must be at least one incompatible set containing B. Otherwise the
%       universally-quantified condition is vacuously true and EVERYTHING would
%       entail B, which is the entailment-side analogue of explosion. We refuse
%       the vacuous case.
%     - A == B is not specially privileged; reflexivity falls out only when B
%       actually has an incompatibility profile.
%
%   Honest scope: this quantifies over DECLARED incompatible sets only, so it is
%   a finite approximation of Brandom's relation, complete exactly to the extent
%   the incompatibility data is. With sparse data it can report an entailment
%   that richer data would defeat; adding the content that distinguishes A from
%   B (a set incompatible with B but not with A) withdraws the entailment.
incompatibility_entails(A, B) :-
    findall(S, ( incompatible_set(S), memberchk_eq(B, S) ), WithB),
    WithB \== [],
    forall(member(S, WithB),
           ( replace_eq(B, A, S, S1),
             brandomian_incoherent(S1)
           )).

replace_eq(_, _, [], []).
replace_eq(Old, New, [Old0|Rest], [New|Rest1]) :-
    Old == Old0, !,
    replace_eq(Old, New, Rest, Rest1).
replace_eq(Old, New, [H|Rest], [H|Rest1]) :-
    replace_eq(Old, New, Rest, Rest1).

% =================================================================
% Mutation API (for axiom packs / runtime contribution)
% =================================================================

%!  add_incompatible_set(+Set) is det.
%
%   Assert a hyperedge. Set is normalized (sorted, de-duplicated). A singleton
%   or empty set is rejected — incompatibility is a relation among >= 2 contents.
add_incompatible_set(Set) :-
    must_be(list, Set),
    sort(Set, Sorted),
    length(Sorted, N),
    ( N >= 2 -> true
    ; throw(error(domain_error(incompatible_set_arity, Set), _))
    ),
    ( incompatible_set(Sorted) -> true ; assertz(incompatible_set(Sorted)) ).

%!  retract_incompatible_set(+Set) is det.
retract_incompatible_set(Set) :-
    must_be(list, Set),
    sort(Set, Sorted),
    retractall(incompatible_set(Sorted)).
