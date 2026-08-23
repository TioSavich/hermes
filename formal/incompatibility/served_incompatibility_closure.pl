/** <module> Incompatibility feeders installed by the served worker
 *
 * The worker and gates that audit its incompatibility entailments call this
 * predicate so they evaluate the same tracked hyperedge union. Installation
 * order matches the worker contract and every feeder is idempotent.
 */

:- module(served_incompatibility_closure,
          [ install_served_incompatibility_closure/0
          ]).

:- use_module(misconceptions(literature_deontic_bridge), []).
:- use_module(incompat(registry_incompatibility_adapter), []).
:- use_module(incompat(error_rule_incompatibility_adapter), []).


%! install_served_incompatibility_closure is det.
%
%  Install the tracked literature, misconception-registry, and error-rule
%  hyperedges that the worker serves in addition to the canonical seed rows.
install_served_incompatibility_closure :-
    literature_deontic_bridge:install_lit_incompatible_sets(_),
    registry_incompatibility_adapter:load_registry_hyperedges,
    error_rule_incompatibility_adapter:load_error_rule_hyperedges.
