% PURPOSE: Runtime on/off toggles for problematic (looping) axioms: pack-gate delegation plus lazy guard hooks over the two modal-transition fact tables; consulting this module changes no engine behavior until a toggle is called.
/** <module> Runtime axiom toggling
 *
 * The meta-mathematical error-pattern work needs to turn a problematic axiom
 * off at runtime and back on again, without editing engine code and without
 * restarting the process. This module supplies that lever. It is deliberately
 * small: five exported predicates, three toggle families, no state until the
 * first toggle.
 *
 * ## What an "axiom" is here, concretely
 *
 * Three toggle-identifier families, each enumerated from the live
 * representation (list_toggles/1 shows all of them):
 *
 *   - `pack(Pack)` — one of the five sequent-engine axiom packs
 *     (robinson, geometry, number_theory, rhythm, domains), or the opt-in
 *     registry_incompatibility adapter. A sequent pack is a family of
 *     `proves_impl/2` / `is_incoherent/1` clauses include-compiled into
 *     `formal/sequent/sequent_engine.pl`, each clause gated by the dynamic fact
 *     `sequent_engine:axiom_pack_enabled/1`. The adapter pack delegates to
 *     its documented reversible load/unload interface.
 *   - `rhythm_transition(From, To)` — one row of the finite rhythm modal
 *     transition table compiled into the sequent engine from
 *     `formal/pml/rhythm_axioms.pl` (for example the bad-infinite pair
 *     `rhythm_transition(s(t_b), s(comp_nec(t_n)))` and its converse).
 *   - `dialectical_transition(Stage, ModalTo)` — one row of the dialectical
 *     rhythm table in `formal/pml/semantic_axioms.pl`, which feeds
 *     `embodied_prover:material_inference/3` and any FSM that speaks the
 *     table through `dialectical_engine:run_fsm/4`.
 *
 * ## Why guard hooks, not clause retract/re-assert
 *
 * The axiom clauses are include-compiled STATIC predicates: `retract/1` and
 * `erase/1` on `sequent_engine:proves_impl/2` raise
 * `permission_error(modify, static_procedure, ...)` (verified against the
 * live engine; `formal/dialectic/critique.pl` documents hitting the same wall in
 * its accommodation-lifecycle note). So the representation itself rules the
 * retract/re-assert mechanism out, and the module uses the two seams the
 * representation does support:
 *
 *   1. Pack granularity: the dynamic gate `axiom_pack_enabled/1` already
 *      exists and every pack clause consults it on both consumption paths
 *      (direct clause resolution, and the forward chainer's `call(Body)`).
 *      `pack(Pack)` toggles delegate to
 *      `sequent_engine:enable_axiom_pack/1` / `disable_axiom_pack/1`.
 *   2. Fact granularity: the two modal-transition tables are called BY
 *      PREDICATE NAME from every consumer (the rhythm witness predicates inside
 *      the sequent engine, the semantic-axiom witness bodies behind
 *      `embodied_prover:material_inference/3`, and FSM fixtures). A
 *      `library(prolog_wrap)` supervisor on the table predicate intercepts
 *      all of those calls, including module-internal ones, and post-filters
 *      solutions against `disabled_axiom/1`. Post-filtering (run the
 *      original, drop disabled rows) keeps enumeration with unbound
 *      arguments exact: the ground fact rows come out unchanged minus the
 *      disabled ones.
 *
 * ## Inertness guarantee
 *
 * Consulting this module installs nothing: no wrapper, no gate change, an
 * empty `disabled_axiom/1` table. A family's wrapper is installed lazily on
 * the first `disable_axiom/1` that touches it and removed again when the
 * family's last disabled row is re-enabled, so a fully re-enabled system
 * runs the engine's own supervisors, not a pass-through guard.
 *
 * ## Boundaries, named precisely
 *
 *   - Fact-level toggling covers the two transition tables only. The other
 *     pack axioms (the robinson/geometry/number_theory/domains
 *     `proves_impl/2` clauses) toggle at pack granularity, because their
 *     representation offers no finer runtime seam short of editing the
 *     engine. Adding another fact-table family is one `toggle_family/3` row.
 *   - A per-query `packs(...)` option to `sequent_engine:safe_proves/2`
 *     resets the ambient pack gate for that query (existing engine
 *     semantics, unchanged here), so it overrides a `pack(Pack)` toggle for
 *     the query's duration. Fact-level toggles are not affected by
 *     `packs(...)`.
 *   - Toggles are process-global, not thread-local.
 *
 * ## The looping axiom this was built against
 *
 * The repo's own classifiers name the bad-infinite pair as the problematic
 * axiom: `formal/pml/semantic_axioms.pl` labels
 * `dialectical_transition(t_b, comp_nec(t_n))` / `(t_n, comp_nec(t_b))` as
 * `bad_infinite_being_to_nothing` / `bad_infinite_nothing_to_being`, and
 * `critique:bad_infinite_witness/2` classifies the closed compressive cycle
 * as `pathology(bad_infinite, Cycle)` — with an accommodate/1 handler that
 * deliberately fails pending external intervention. The audit tool
 * (`formal/tools/axiom_pack_audit.pl`) classifies non-termination by timeout:
 * `safe_proves/2` treats `time_limit_exceeded` as failure.
 * `dialectical_engine:run_fsm/4` has no cycle guard, so an FSM speaking the
 * live table genuinely does not terminate from `state(t_b)`;
 * `formal/tools/tests/test_axiom_toggle.pl` shows that call timing out with the
 * axiom on and terminating under `with_axioms_disabled/2`.
 */
:- module(axiom_toggle,
          [ axiom_enabled/1,
            disable_axiom/1,
            enable_axiom/1,
            with_axioms_disabled/2,
            list_toggles/1
          ]).

% paths.pl asserts into user:file_search_path/2, and formal/load.pl is a
% non-module file, so both belong in `user` regardless of who consults this
% module first. Loading them from this module's context would re-load the
% already-user-loaded files into axiom_toggle and fail.
:- (   user:file_search_path(sequent, _)
   ->  true
   ;   ensure_loaded('../../paths')
   ).
:- user:ensure_loaded(formal(load)).

:- use_module(library(prolog_wrap), [wrap_predicate/4, unwrap_predicate/2]).
:- use_module(library(lists), [member/2]).
:- use_module(library(apply), [maplist/2, include/3]).
:- use_module(incompat(registry_incompatibility_adapter), []).

%!  disabled_axiom(?Id) is nondet.
%
%   Ground fact-level toggle identifiers currently switched off. Empty at
%   consult time. Pack toggles do not live here; their truth is the live
%   `sequent_engine:axiom_pack_enabled/1` gate.
:- dynamic disabled_axiom/1.

%!  guard_installed(?Family) is nondet.
%
%   Families whose wrap_predicate supervisor is currently installed.
:- dynamic guard_installed/1.

:- meta_predicate with_axioms_disabled(+, 0).

% =================================================================
% Toggle registry (enumerated from the live representation)
% =================================================================

%!  toggle_family(?Family, ?Module, ?PredicateIndicator) is nondet.
%
%   The fact-table families that support per-row toggling. The family name
%   doubles as the toggle-identifier functor and the wrapped predicate name.
toggle_family(rhythm_transition,      sequent_engine,  rhythm_transition/2).
toggle_family(dialectical_transition, semantic_axioms, dialectical_transition/2).

%!  known_toggle(?Id) is nondet.
%
%   Every toggleable identifier, read from the loaded engine rather than
%   from a frozen list: packs from `default_axiom_pack/1` (the audited
%   registry of packs, independent of their current gate state), fact rows
%   via `clause/2` (the same access path the engine's forward chainer uses;
%   wrapping does not hide clauses from `clause/2`).
known_toggle(pack(Pack)) :-
    known_pack(Pack).
known_toggle(Id) :-
    toggle_family(Family, Module, Name/Arity),
    functor(Head, Name, Arity),
    clause(Module:Head, true),
    Head =.. [Name|Args],
    Id =.. [Family|Args].

known_pack(Pack) :-
    sequent_engine:default_axiom_pack(Pack).
known_pack(registry_incompatibility).

% =================================================================
% Public surface
% =================================================================

%!  axiom_enabled(?Id) is nondet.
%
%   True when Id is a known toggle that is currently on. With everything at
%   its default this succeeds for every known toggle: consulting the module
%   leaves current engine behavior unchanged. Pack state is read from the
%   live gate, so it stays honest even when other code flips packs directly.
axiom_enabled(pack(Pack)) :-
    known_toggle(pack(Pack)),
    pack_enabled(Pack).
axiom_enabled(Id) :-
    known_toggle(Id),
    Id \= pack(_),
    \+ disabled_axiom(Id).

%!  disable_axiom(+Id) is det.
%
%   Switch off every known toggle unifying with Id (so
%   `disable_axiom(dialectical_transition(a, _))` switches off both of the
%   a-stage rows). Throws `instantiation_error` for an unbound Id and
%   `domain_error(axiom_toggle, Id)` when nothing matches — mirroring
%   `sequent_engine:known_axiom_pack/1`. Idempotent.
disable_axiom(Id) :-
    resolve_toggles(Id, Toggles),
    maplist(disable_one, Toggles).

%!  enable_axiom(+Id) is det.
%
%   Switch every known toggle unifying with Id back on. Same errors as
%   disable_axiom/1. Idempotent; re-enabling the last disabled row of a
%   family removes that family's wrapper entirely.
enable_axiom(Id) :-
    resolve_toggles(Id, Toggles),
    maplist(enable_one, Toggles).

%!  with_axioms_disabled(+Ids, :Goal) is nondet.
%
%   Run Goal with every toggle matched by the list Ids switched off, then
%   restore. Restoration happens whether Goal succeeds, fails, or throws
%   (setup_call_cleanup/3), and only covers toggles this scope actually
%   switched off, so nesting and pre-existing disables compose: an outer
%   disable survives an inner scope that names the same toggle.
with_axioms_disabled(Ids, Goal) :-
    (   is_list(Ids)
    ->  true
    ;   throw(error(type_error(list, Ids),
                    context(axiom_toggle:with_axioms_disabled/2, _)))
    ),
    findall(Toggle,
            ( member(Id, Ids),
              resolve_toggles(Id, Toggles),
              member(Toggle, Toggles)
            ),
            All0),
    sort(All0, All),
    include(axiom_enabled, All, NewlyDisabled),
    setup_call_cleanup(
        maplist(disable_one, NewlyDisabled),
        Goal,
        maplist(enable_one, NewlyDisabled)).

%!  list_toggles(-Toggles) is det.
%
%   Toggles is the sorted list of `toggle(Id, enabled|disabled)` terms for
%   every known toggle. Disabled rows stay listed: the registry reads
%   clauses, which wrapping does not remove.
list_toggles(Toggles) :-
    findall(toggle(Id, Status),
            ( known_toggle(Id),
              (   axiom_enabled(Id)
              ->  Status = enabled
              ;   Status = disabled
              )
            ),
            Toggles0),
    sort(Toggles0, Toggles).

% =================================================================
% Resolution
% =================================================================

resolve_toggles(Id, _) :-
    var(Id),
    !,
    throw(error(instantiation_error,
                context(axiom_toggle:resolve_toggles/2, _))).
resolve_toggles(Id, Toggles) :-
    findall(Id, known_toggle(Id), Toggles),
    (   Toggles == []
    ->  throw(error(domain_error(axiom_toggle, Id),
                    context(axiom_toggle:resolve_toggles/2, _)))
    ;   true
    ).

% =================================================================
% Single-toggle switches
% =================================================================

disable_one(pack(Pack)) :-
    !,
    disable_pack(Pack).
disable_one(Id) :-
    (   disabled_axiom(Id)
    ->  true
    ;   assertz(disabled_axiom(Id)),
        functor(Id, Family, _),
        ensure_guard(Family)
    ).

enable_one(pack(Pack)) :-
    !,
    enable_pack(Pack).
enable_one(Id) :-
    retractall(disabled_axiom(Id)),
    functor(Id, Family, _),
    maybe_remove_guard(Family).

pack_enabled(registry_incompatibility) :-
    !,
    registry_incompatibility_adapter:registry_hyperedge_count(Count),
    Count > 0.
pack_enabled(Pack) :-
    sequent_engine:enabled_axiom_pack(Pack).

disable_pack(registry_incompatibility) :-
    !,
    registry_incompatibility_adapter:unload_registry_hyperedges.
disable_pack(Pack) :-
    sequent_engine:disable_axiom_pack(Pack).

enable_pack(registry_incompatibility) :-
    !,
    registry_incompatibility_adapter:load_registry_hyperedges.
enable_pack(Pack) :-
    sequent_engine:enable_axiom_pack(Pack).

% =================================================================
% Guard lifecycle (lazy install, eager removal)
% =================================================================

ensure_guard(Family) :-
    (   guard_installed(Family)
    ->  true
    ;   install_guard(Family),
        assertz(guard_installed(Family))
    ).

%   The wrapper runs the original definition and drops any solution whose
%   row is currently disabled. `Wrapped` is prolog_wrap's closure over the
%   original supervisor, so an unwrapped-then-rewrapped family always sees
%   the true clause set.
install_guard(Family) :-
    once(toggle_family(Family, Module, Name/Arity)),
    functor(Head, Name, Arity),
    Head =.. [Name|Args],
    Id =.. [Family|Args],
    wrap_predicate(Module:Head, axiom_toggle_guard, Wrapped,
                   ( Wrapped,
                     \+ axiom_toggle:disabled_axiom(Id)
                   )).

maybe_remove_guard(Family) :-
    (   guard_installed(Family),
        \+ family_has_disabled(Family)
    ->  once(toggle_family(Family, Module, PredicateIndicator)),
        unwrap_predicate(Module:PredicateIndicator, axiom_toggle_guard),
        retractall(guard_installed(Family))
    ;   true
    ).

family_has_disabled(Family) :-
    disabled_axiom(Id),
    functor(Id, Family, _),
    !.
