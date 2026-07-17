/** <module> Registry-to-Brandomian incompatibility adapter
 *
 * The Brandomian engine (`arche-trace/brandomian_incompatibility.pl`) ships
 * with four seed hyperedges; the misconception registry's
 * incompatibility_with/2 yields 342 distinct non-degenerate pairs (1,111
 * raw solutions before symmetry and self-pair reduction). This adapter
 * loads those pairs into `incompatible_set/1` as 2-element hyperedges, so
 * the formally vetted relation (persistence, vacuous-entailment guard,
 * minimality) can run over the actual corpus instead of the fruit demo.
 *
 * Loading is EXPLICIT and reversible, not a side effect of use_module. Two
 * reasons. First, mutating the global hyperedge table changes what
 * `incompatibility_entails/2` licenses everywhere in the process — richer
 * data legitimately withdraws entailments that sparse data licensed, and a
 * caller should choose that, not inherit it. Second, `unload/0` lets tests
 * and audits run at registry scale and then restore the seed-only state.
 *
 * Callers that mutate the table should re-run
 * `sequent_brandom_bridge:brandom_backstop_ok/0` afterwards; the test suite
 * pins that the backstop passes at full registry scale.
 *
 * Only pairs the adapter itself asserted are recorded in registry_hyperedge/1
 * and removed by unload; seed hyperedges and other contributors' sets are
 * left alone.
 */
:- module(registry_incompatibility_adapter,
          [ load_registry_hyperedges/0,
            unload_registry_hyperedges/0,
            registry_hyperedge_count/1,
            registry_hyperedge/1
          ]).

:- use_module(library(lists)).
:- use_module(library(aggregate)).
:- use_module(arche_trace(brandomian_incompatibility),
              [ incompatible_set/1,
                add_incompatible_set/1,
                retract_incompatible_set/1
              ]).
:- use_module(misconceptions(misconception_registry),
              [ incompatibility_with/2 ]).

%!  registry_hyperedge(?Set) is nondet.
%
%   A sorted 2-element hyperedge this adapter asserted into
%   brandomian_incompatibility:incompatible_set/1. Bookkeeping only:
%   unload retracts exactly these.
:- dynamic registry_hyperedge/1.

%!  load_registry_hyperedges is det.
%
%   Assert every distinct sorted registry pair as a hyperedge. Idempotent:
%   pairs already loaded (or already present in the engine from another
%   source) are skipped. Degenerate rows (a pair whose two members are the
%   same term) are skipped rather than asserted, since a singleton hyperedge
%   would poison the relation by persistence.
load_registry_hyperedges :-
    findall(Sorted,
            ( incompatibility_with(A, B),
              sort([A, B], Sorted),
              Sorted = [_, _|_]
            ),
            Sets0),
    sort(Sets0, Sets),
    forall(member(Set, Sets), load_one_hyperedge(Set)).

load_one_hyperedge(Set) :-
    (   registry_hyperedge(Set)
    ->  true
    ;   incompatible_set(Set)
    ->  true            % pre-existing (seed or other contributor); not ours to manage
    ;   add_incompatible_set(Set),
        assertz(registry_hyperedge(Set))
    ).

%!  unload_registry_hyperedges is det.
%
%   Retract exactly the hyperedges this adapter loaded.
unload_registry_hyperedges :-
    forall(retract(registry_hyperedge(Set)),
           retract_incompatible_set(Set)).

%!  registry_hyperedge_count(-N) is det.
registry_hyperedge_count(N) :-
    aggregate_all(count, registry_hyperedge(_), N).
