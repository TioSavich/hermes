/** <module> Error-rule cache to Brandomian incompatibility adapter
 *
 * Loads the reviewed error-rule triples and a-fortiori closure triples from
 * `incompatibility_sets:discovered_set_fact/2` into the canonical Brandomian
 * relation. This is separate from the misconception-registry adapter because
 * its source is the generated discovery cache rather than registry pairs.
 *
 * Loading is explicit and reversible. Each contributed set is asserted through
 * `add_incompatible_set/1`; this module records only the sets it added, so
 * unload retracts no seed or other feeder contribution. A set already present
 * in the canonical relation is left unclaimed.
 */
:- module(error_rule_incompatibility_adapter,
          [ load_error_rule_hyperedges/0,
            unload_error_rule_hyperedges/0,
            error_rule_hyperedge_count/1,
            error_rule_hyperedge/1
          ]).

:- use_module(library(lists)).
:- use_module(library(aggregate)).
:- use_module(incompat(brandomian_incompatibility),
              [ incompatible_set/1,
                add_incompatible_set/1,
                retract_incompatible_set/1
              ]).
:- use_module(incompat(incompatibility_sets), []).

%! error_rule_hyperedge(?Set) is nondet.
%
%  A sorted hyperedge this adapter added to the canonical relation.
:- dynamic error_rule_hyperedge/1.

%! load_error_rule_hyperedges is det.
%
%  Load the 90 generated error-rule triples, identified by their `rule_`
%  inference ids, and the a-fortiori closure triples. Reading the public
%  discovery predicate directly keeps this feeder independent of which
%  contexts `incompatibility_sets/2` serves.
load_error_rule_hyperedges :-
    findall(Sorted,
            ( feeder_source_set(Set),
              sort(Set, Sorted),
              Sorted = [_, _|_]
            ),
            Sets0),
    sort(Sets0, Sets),
    forall(member(Set, Sets), load_one_hyperedge(Set)).

feeder_source_set(Set) :-
    incompatibility_sets:discovered_set_fact(defeasible_inference, Set),
    error_rule_cache_set(Set).
feeder_source_set(Set) :-
    incompatibility_sets:discovered_set_fact(a_fortiori_context_closure, Set).

error_rule_cache_set([inference(Id)|_]) :-
    atom(Id),
    sub_atom(Id, 0, 5, _, rule_).

load_one_hyperedge(Set) :-
    (   error_rule_hyperedge(Set)
    ->  true
    ;   incompatible_set(Set)
    ->  true
    ;   add_incompatible_set(Set),
        assertz(error_rule_hyperedge(Set))
    ).

%! unload_error_rule_hyperedges is det.
%
%  Retract exactly the hyperedges recorded by this adapter.
unload_error_rule_hyperedges :-
    forall(retract(error_rule_hyperedge(Set)),
           retract_incompatible_set(Set)).

%! error_rule_hyperedge_count(-N) is det.
error_rule_hyperedge_count(N) :-
    aggregate_all(count, error_rule_hyperedge(_), N).
