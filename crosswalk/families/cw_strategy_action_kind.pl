/** <module> cw_strategy_action_kind — canonical crosswalk family for claim-concept action kinds
 *
 * Four fraction action kinds are load-bearing claim_concept/2 targets in
 * hermes/math_context.pl (the consumer this family exists for):
 *
 *   - unit_fraction_iteration              — math_context.pl claim_concept for
 *     n_over_n_is_one/1 and iterate_to_whole/2
 *   - improper_fraction_iteration          — math_context.pl claim_concept for
 *     improper/1
 *   - cross_multiplication_rule_from_pattern — math_context.pl claim_concept for
 *     multiplication/3
 *   - splitting                            — math_context.pl claim_concept for
 *     iterate_to_whole/2
 *
 * Before this family, none of the four was a legal_term/1, so the worker's
 * canonical_check op classified them "unknown" — a caller asking whether a
 * claim-concept target is legally emittable got a wrong answer. This family
 * promotes them. Each has real cross-surface presence in
 * strategies/math/fraction_action_pairs.pl: a fraction_action_cluster/2 row
 * (reachable through action_automata_registry:action_automaton_cluster/3) and a
 * productive_fraction_deformation/3 row where the kind is the productive head.
 *
 * Same shape as the other crosswalk families: it RENAMES nothing and OWNS no
 * facts — vocabulary_source/2 is the contract the aggregator (canonical_all)
 * ranges over, canonical_concept/2 is the reverse map, and
 * strategy_action_kind_unified/3 is the live query that resolves one row per
 * verified legacy edge.
 *
 * Family slug: strategy_action_kind.
 */
:- module(cw_strategy_action_kind,
          [ strategy_action_kind_unified/3,  % strategy_action_kind_unified(-Canonical, -Detail, -Source)
            strategy_action_kind_witness/4,  % strategy_action_kind_witness(?Canonical, ?Detail, ?Source, -Witness)
            canonical_concept/2,             % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2              % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

:- use_module(strategies('math/fraction_action_pairs'), []).
:- use_module(strategies('math/action_automata_registry'), []).
:- use_module(library(lists), [ member/2 ]).

%! sak(?Canonical, ?Cluster, ?DeformationKind, ?DeformationFamily) is nondet.
%
%  The family table. Each row: the canonical action-kind concept; the
%  fraction_action_cluster/2 cluster it belongs to; and the deformation kind +
%  family for which it is the productive head in
%  productive_fraction_deformation/3. All three columns are verified against
%  strategies/math/fraction_action_pairs.pl by the witness clauses below.
sak(unit_fraction_iteration,               fraction_unit_referent_operations,  whole_number_grab,                        whole_number_grab).
sak(improper_fraction_iteration,           fraction_improper_number,           improper_fraction_chain_loss,             improper_fraction_reset).
sak(cross_multiplication_rule_from_pattern, fraction_area_model_multiplication, cross_multiplication_rule_without_ground, rule_without_grounding).
sak(splitting,                             fraction_reversibility_splitting,   iterate_given_overshoot,                  no_splitting_iterate_overshoot).

% The legacy functor strings for a canonical term: the registry cluster edge and
% the per-domain deformation-pair edge, both as 'Module:Functor/Arity(...)'
% style atoms (matching the convention used by the other families).
legacy_list(Canonical, [ClusterEdge, DeformationEdge]) :-
    sak(Canonical, _, _, _),
    atomic_list_concat(
        ['action_automata_registry:action_automaton_cluster/3(fraction,',
         Canonical, ')'],
        ClusterEdge),
    atomic_list_concat(
        ['fraction_action_pairs:productive_fraction_deformation/3(',
         Canonical, ')'],
        DeformationEdge).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(Canonical, Legacies) :- legacy_list(Canonical, Legacies).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
canonical_concept(Legacy, Canonical) :-
    legacy_list(Canonical, Legacies),
    member(Legacy, Legacies).

%! strategy_action_kind_unified(?Canonical, ?Detail, ?Source) is nondet.
%
%  Source = <legacy functor string>: Detail = edge(Functor) — one row per
%  verified legacy edge (cluster membership; productive/deformation pairing).
strategy_action_kind_unified(Canonical, Detail, Source) :-
    strategy_action_kind_witness(Canonical, Detail, Source, _).

%! strategy_action_kind_witness(?Canonical, ?Detail, ?Source, -Witness) is nondet.
%
%  Witnessed form of `strategy_action_kind_unified/3`. This is a closed-world
%  finite check over the loaded action-kind table and the source predicates
%  that own each listed row. The table proposes alignments; this predicate
%  succeeds only when the owning source proves the referenced action cluster or
%  productive/deformation pair.
strategy_action_kind_witness(
    Canonical,
    edge(Functor),
    Functor,
    _{ kind: strategy_action_kind_crosswalk,
       scope: closed_world_finite_verified_strategy_action_kind_edges,
       canonical: Canonical,
       detail: edge(Functor),
       source: Functor,
       legacy_functor: Functor,
       projection: verified_legacy_edge,
       derivation: owner_predicate_edge_check,
       source_witness: SourceWitness }) :-
    legacy_list(Canonical, Legacies),
    member(Functor, Legacies),
    strategy_action_kind_edge_witness(Canonical, Functor, SourceWitness).

% The cluster edge: proven through the registry dispatch surface plus the
% kind's vocabulary row.
strategy_action_kind_edge_witness(
    Canonical,
    Functor,
    _{ kind: action_automaton_cluster_edge,
       module: action_automata_registry,
       predicate: action_automaton_cluster/3,
       operation: fraction,
       action_kind: Canonical,
       cluster: Cluster,
       vocabulary: Vocabulary }) :-
    sub_atom(Functor, _, _, _, 'action_automaton_cluster'),
    sak(Canonical, Cluster, _, _),
    catch(action_automata_registry:action_automaton_cluster(fraction, Canonical, Cluster),
          _, fail),
    catch(action_automata_registry:action_automaton_vocabulary(fraction, Canonical, Vocabulary),
          _, fail).
% The deformation edge: the kind is the productive head of a fraction
% productive/deformation pair.
strategy_action_kind_edge_witness(
    Canonical,
    Functor,
    _{ kind: productive_fraction_deformation_edge,
       module: fraction_action_pairs,
       predicate: productive_fraction_deformation/3,
       productive: Canonical,
       deformation: Deformation,
       family: Family }) :-
    sub_atom(Functor, _, _, _, 'productive_fraction_deformation'),
    sak(Canonical, _, Deformation, Family),
    catch(fraction_action_pairs:productive_fraction_deformation(Canonical, Deformation, Family),
          _, fail).
