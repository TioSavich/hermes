/** <module> Canonical vocabulary family — action-kind to cluster registry
 *
 * Concept: "which behavioural cluster does an action-kind belong to?" Three
 * scattered functors all answer roughly that question, at different layers and
 * arities:
 *
 *   - sar_add_action_pairs:action_cluster/2
 *       Kind -> Cluster, for the ADDITION family only (the addition module is
 *       the one that happens to export the bare name `action_cluster`).
 *   - fraction_action_pairs:fraction_action_cluster/2
 *       Kind -> Cluster, for the FRACTION family only.
 *   - action_automata_registry:action_automaton_cluster/3
 *       Operation, Kind -> Cluster — the unifying surface that already
 *       dispatches per operation (addition routes to action_cluster/2, fraction
 *       routes to fraction_action_cluster/2, plus ten other operations).
 *
 * This module does NOT rename or rewrite any of them. It adds one read-only
 * union query, action_cluster_unified/4, that ranges over all three and tags
 * each result with its source.
 *
 * Projection to a common shape: the canonical predicate is
 *   action_cluster_unified(?Operation, ?Kind, ?Cluster, -Source)
 * The two arity-2 sources carry an IMPLICIT operation (the only operation their
 * owning module models): action_cluster/2 is implicitly `addition`, and
 * fraction_action_cluster/2 is implicitly `fraction`. We supply that constant so
 * every row has an explicit Operation. The arity-3 registry already carries
 * Operation, so it maps directly. Because the registry dispatches addition and
 * fraction back to the same two arity-2 predicates, those two operations will
 * yield results under BOTH their direct source tag AND source=registry; that is
 * the honest provenance, not a duplicate bug.
 *
 * Every source call is wrapped in catch/3 so an absent or erroring source
 * contributes nothing. All three sources are pure facts (no assert/retract, no
 * search), so the union is side-effect-free.
 *
 * Wave-2 family of the canonical-vocabulary pass; same style as
 * crosswalk/canonical_vocabulary.pl.
 */
:- module(cw_action_cluster,
          [ action_cluster_unified/4,  % action_cluster_unified(?Operation, ?Kind, ?Cluster, -Source)
            action_cluster_witness/5,  % action_cluster_witness(?Operation, ?Kind, ?Cluster, ?Source, -Witness)
            canonical_concept/2,        % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2         % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

% Source modules are called module-qualified; empty import lists are intentional
% (we pull no names into this module). Loading the registry transitively loads
% sar_add_action_pairs and fraction_action_pairs, but we list them explicitly so
% the dependency is legible and survives if the registry stops re-exporting them.
:- use_module(strategies('math/sar_add_action_pairs'), []).
:- use_module(strategies('math/fraction_action_pairs'), []).
:- use_module(strategies('math/action_automata_registry'), []).

%! action_cluster_unified(?Operation, ?Kind, ?Cluster, -Source) is nondet.
%
%  True when action Kind belongs to Cluster within Operation, according to ANY
%  of the three cluster sources. Source names which one:
%   - addition_pairs : sar_add_action_pairs:action_cluster/2 (Operation fixed to addition)
%   - fraction_pairs : fraction_action_pairs:fraction_action_cluster/2 (Operation fixed to fraction)
%   - registry       : action_automata_registry:action_automaton_cluster/3 (Operation explicit)
action_cluster_unified(addition, Kind, Cluster, addition_pairs) :-
    action_cluster_witness(addition, Kind, Cluster, addition_pairs, _).
action_cluster_unified(fraction, Kind, Cluster, fraction_pairs) :-
    action_cluster_witness(fraction, Kind, Cluster, fraction_pairs, _).
action_cluster_unified(Operation, Kind, Cluster, registry) :-
    action_cluster_witness(Operation, Kind, Cluster, registry, _).

%! action_cluster_witness(?Operation, ?Kind, ?Cluster, ?Source, -Witness) is nondet.
%
%  Witnessed form of `action_cluster_unified/4`. This is a closed-world finite
%  union over the currently loaded action-cluster sources. It does not execute
%  any action automaton; it records which loaded cluster table accepted the row
%  and, for the registry source, which operation-specific cluster predicate the
%  registry dispatches through.
action_cluster_witness(Operation, Kind, Cluster, Source,
                       WitnessDict76) :-
    witness_dict:witness_dict(action_cluster_crosswalk, closed_world_finite_loaded_action_cluster_sources,
                              _{operation: Operation,
                          action_kind: Kind,
                          cluster: Cluster,
                          source: Source,
                          legacy_functor: LegacyFunctor,
                          derivation: Derivation,
                          source_witness: SourceWitness }, WitnessDict76),
    source_action_cluster_witness(Source,
                                  Operation,
                                  Kind,
                                  Cluster,
                                  LegacyFunctor,
                                  Derivation,
                                  SourceWitness).

source_action_cluster_witness(addition_pairs,
                              addition,
                              Kind,
                              Cluster,
                              'sar_add_action_pairs:action_cluster/2',
                              direct_addition_action_cluster_row,
                              _{ kind: direct_action_cluster_row,
                                 implicit_operation: addition,
                                 module: sar_add_action_pairs,
                                 predicate: action_cluster/2,
                                 action_kind: Kind,
                                 cluster: Cluster }) :-
    catch(sar_add_action_pairs:action_cluster(Kind, Cluster), _, fail).
source_action_cluster_witness(fraction_pairs,
                              fraction,
                              Kind,
                              Cluster,
                              'fraction_action_pairs:fraction_action_cluster/2',
                              direct_fraction_action_cluster_row,
                              _{ kind: direct_action_cluster_row,
                                 implicit_operation: fraction,
                                 module: fraction_action_pairs,
                                 predicate: fraction_action_cluster/2,
                                 action_kind: Kind,
                                 cluster: Cluster }) :-
    catch(fraction_action_pairs:fraction_action_cluster(Kind, Cluster), _, fail).
source_action_cluster_witness(registry,
                              Operation,
                              Kind,
                              Cluster,
                              'action_automata_registry:action_automaton_cluster/3',
                              registry_operation_dispatch,
                              _{ kind: registry_action_cluster_dispatch,
                                 registry_predicate: 'action_automata_registry:action_automaton_cluster/3',
                                 operation: Operation,
                                 action_kind: Kind,
                                 cluster: Cluster,
                                 dispatched_module: Module,
                                 dispatched_predicate: Predicate/2,
                                 dispatched_legacy_functor: DispatchedLegacyFunctor }) :-
    catch(action_automata_registry:action_automaton_cluster(Operation, Kind, Cluster), _, fail),
    registry_cluster_dispatch(Operation, Module, Predicate, DispatchedLegacyFunctor),
    dispatched_cluster_row(Module, Predicate, Kind, Cluster).

registry_cluster_dispatch(addition, sar_add_action_pairs, action_cluster,
                          'sar_add_action_pairs:action_cluster/2').
registry_cluster_dispatch(subtraction, sar_sub_action_pairs, subtractive_action_cluster,
                          'sar_sub_action_pairs:subtractive_action_cluster/2').
registry_cluster_dispatch(multiplication, smr_mult_action_pairs, multiplicative_action_cluster,
                          'smr_mult_action_pairs:multiplicative_action_cluster/2').
registry_cluster_dispatch(division, smr_div_action_pairs, division_action_cluster,
                          'smr_div_action_pairs:division_action_cluster/2').
registry_cluster_dispatch(fraction, fraction_action_pairs, fraction_action_cluster,
                          'fraction_action_pairs:fraction_action_cluster/2').
registry_cluster_dispatch(decimal, decimal_action_pairs, decimal_action_cluster,
                          'decimal_action_pairs:decimal_action_cluster/2').
registry_cluster_dispatch(integer, integer_action_pairs, integer_action_cluster,
                          'integer_action_pairs:integer_action_cluster/2').
registry_cluster_dispatch(ratio, ratio_action_pairs, ratio_action_cluster,
                          'ratio_action_pairs:ratio_action_cluster/2').
registry_cluster_dispatch(diagnostic, diagnostic_validation_action_pairs, diagnostic_action_cluster,
                          'diagnostic_validation_action_pairs:diagnostic_action_cluster/2').
registry_cluster_dispatch(calculus, calculus_limits_action_pairs, calculus_action_cluster,
                          'calculus_limits_action_pairs:calculus_action_cluster/2').
registry_cluster_dispatch(algebraic, algebraic_action_pairs, algebraic_action_cluster,
                          'algebraic_action_pairs:algebraic_action_cluster/2').
registry_cluster_dispatch(probability, probability_action_pairs, probability_action_cluster,
                          'probability_action_pairs:probability_action_cluster/2').

dispatched_cluster_row(Module, Predicate, Kind, Cluster) :-
    Goal =.. [Predicate, Kind, Cluster],
    catch(call(Module:Goal), _, fail).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
%
%  Maps each scattered legacy functor to its canonical query predicate.
canonical_concept('sar_add_action_pairs:action_cluster/2',                 action_cluster_unified).
canonical_concept('fraction_action_pairs:fraction_action_cluster/2',       action_cluster_unified).
canonical_concept('action_automata_registry:action_automaton_cluster/3',   action_cluster_unified).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(action_cluster_unified,
    [ 'sar_add_action_pairs:action_cluster/2',
      'fraction_action_pairs:fraction_action_cluster/2',
      'action_automata_registry:action_automaton_cluster/3' ]).
