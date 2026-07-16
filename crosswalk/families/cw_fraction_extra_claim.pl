/** <module> cw_fraction_extra_claim — canonical crosswalk family for the fraction_extra bucket
 *
 * Six fraction-claim commitments earned a crosswalk home because each has a real,
 * verified cross-surface legacy functor expressing the same concept outside the
 * literature vocabulary. These are the fraction commitments not already covered by
 * cw_fraction_claim; the bucket slug is fraction_extra.
 *
 *   - fraction_of_quantity_as_part_of_part — taking m/n of a quantity as partition-
 *     then-iterate. Backed by the area-model multiplication cluster
 *     action_automaton_cluster(fraction, area_model_part_of_part, _) and by the
 *     grounding-metaphor inference
 *     grounds_inference(arithmetic_is_object_construction,
 *     fraction_multiplication_as_part_of_part, _).
 *   - fraction_stable_referent_whole — a fraction interpreted against a stable
 *     referent whole. Backed by the improper-fraction iteration cluster
 *     action_automaton_cluster(fraction, improper_fraction_iteration, _) and by the
 *     misconception edge incompatibility_with(improper_fraction_chain_loss, _),
 *     which records losing the referent across an improper chain.
 *   - fraction_part_disembedded_as_quantity — a part disembedded and treated as a
 *     quantity while the whole stays intact. Backed by the recursive-partition
 *     cluster action_automaton_cluster(fraction, recursive_partition, _) and by the
 *     misconception edge incompatibility_with(clear_inner_referent, _).
 *   - cancellation_needs_common_factor — cancellation requires a common factor of
 *     the whole expression, not a matching surface term. Backed by the productive/
 *     deformation calculus pair action_automaton_cluster(calculus,
 *     factor_cancel_substitute, _) / action_automaton_cluster(calculus,
 *     factor_cancel_without_common_factor, _) and by the misconception edge
 *     incompatibility_with(factor_cancel_without_common_factor, _).
 *   - fraction_addition_on_common_unit — adding fractions requires a common unit
 *     first. Backed by the CGI co-denominator dispatch cluster
 *     action_automaton_cluster(fraction, co_denominator_count_on_from_larger, _).
 *   - fraction_division_as_reversible_inverse — fraction division coordinates the
 *     reversible inverse relation. Backed by the solve-for-unit cluster
 *     action_automaton_cluster(fraction, solve_for_unit, _) and by the misconception
 *     edge incompatibility_with(iterate_only_no_reverse, _).
 *
 * Same shape as the other crosswalk families (cf. cw_whole_number_claim): it
 * RENAMES nothing and OWNS no facts on the legacy surfaces — vocabulary_source/2 is
 * the contract the aggregator (canonical_all) ranges over, canonical_concept/2 is
 * the reverse map, and fraction_extra_claim_unified/3 is the live query that pulls
 * the canonical gloss and one row per verified legacy edge.
 *
 * All six canonical commitment atoms exist as
 * literature_vocabulary:canonical_commitment/2 facts, so the literature gloss
 * resolves live through the owner predicate.
 *
 * Family slug: fraction_extra_claim. Bucket: fraction_extra.
 */
:- module(cw_fraction_extra_claim,
          [ fraction_extra_claim_unified/3,  % fraction_extra_claim_unified(-Canonical, -Detail, -Source)
            fraction_extra_claim_witness/4,  % fraction_extra_claim_witness(?Canonical, ?Detail, ?Source, -Witness)
            claim_literature_atom/2,         % claim_literature_atom(?Canonical, ?LiteratureAtom)
            canonical_concept/2,             % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2              % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

:- use_module(misconceptions(literature_vocabulary), []).
:- use_module(misconceptions(misconception_registry), []).
:- use_module(strategies('math/action_automata_registry'), []).
:- use_module(formalization(grounding_metaphors), []).
:- use_module(library(lists), [ member/2, append/2 ]).

%! fe(?Canonical, ?LiteratureAtom, ?VerifiedEdges) is nondet.
%
%  The family table. Each row: the canonical fraction_extra concept; the canonical
%  commitment anchor atom; and the verified non-literature legacy functor strings
%  that express the same concept.
fe(fraction_of_quantity_as_part_of_part,
   c_fraction_of_quantity_multiplication,
   [ 'action_automata_registry:action_automaton_cluster/3(fraction,area_model_part_of_part)',
     'grounding_metaphors:grounds_inference/3(arithmetic_is_object_construction,fraction_multiplication_as_part_of_part)' ]).
fe(fraction_stable_referent_whole,
   c_fraction_referent_whole_invariance,
   [ 'action_automata_registry:action_automaton_cluster/3(fraction,improper_fraction_iteration)',
     'misconception_registry:incompatibility_with/2(improper_fraction_chain_loss)' ]).
fe(fraction_part_disembedded_as_quantity,
   c_part_whole_disembedding,
   [ 'action_automata_registry:action_automaton_cluster/3(fraction,recursive_partition)',
     'misconception_registry:incompatibility_with/2(clear_inner_referent)' ]).
fe(cancellation_needs_common_factor,
   c_cancellation_requires_common_factor,
   [ 'action_automata_registry:action_automaton_cluster/3(calculus,factor_cancel_substitute)',
     'action_automata_registry:action_automaton_cluster/3(calculus,factor_cancel_without_common_factor)',
     'misconception_registry:incompatibility_with/2(factor_cancel_without_common_factor)' ]).
fe(fraction_addition_on_common_unit,
   c_fraction_addition_common_unit,
   [ 'action_automata_registry:action_automaton_cluster/3(fraction,co_denominator_count_on_from_larger)' ]).
fe(fraction_division_as_reversible_inverse,
   c_fraction_division_inverse_relation,
   [ 'action_automata_registry:action_automaton_cluster/3(fraction,solve_for_unit)',
     'misconception_registry:incompatibility_with/2(iterate_only_no_reverse)' ]).

%! claim_literature_atom(?Canonical, ?LiteratureAtom) is nondet.
%  The canonical commitment anchor atom for a fraction_extra concept.
claim_literature_atom(Canonical, LitAtom) :- fe(Canonical, LitAtom, _).

% The legacy functor strings for a canonical term: the literature anchor (as a
% 'literature_vocabulary:canonical_commitment/2(Atom)' string) followed by every
% verified non-literature edge — matching the convention of the other families.
legacy_list(Canonical, Legacies) :-
    fe(Canonical, Lit, Edges),
    atomic_list_concat(['literature_vocabulary:canonical_commitment/2(', Lit, ')'], LitFunctor),
    append([[LitFunctor], Edges], Legacies).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(Canonical, Legacies) :- legacy_list(Canonical, Legacies).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
canonical_concept(Legacy, Canonical) :-
    legacy_list(Canonical, Legacies),
    member(Legacy, Legacies).

%! fraction_extra_claim_unified(?Canonical, ?Detail, ?Source) is nondet.
%
%  Source = literature_commitment: Detail = commitment(Atom, Gloss) — the
%  owner-proved canonical gloss for this concept's anchor atom.
%  Source = <legacy functor string>: Detail = edge(Functor) — one row per verified
%  non-literature surface that expresses the concept.
fraction_extra_claim_unified(Canonical, Detail, Source) :-
    fraction_extra_claim_witness(Canonical, Detail, Source, _).

%! fraction_extra_claim_witness(?Canonical, ?Detail, ?Source, -Witness) is nondet.
%
%  Witnessed form of `fraction_extra_claim_unified/3`. This is a closed-world
%  finite check over the loaded fraction-extra claim table and the source
%  predicates that own each listed row. The table proposes alignments; this
%  predicate succeeds only when the owning source proves the referenced
%  literature commitment, action cluster, grounded inference, or misconception
%  incompatibility.
fraction_extra_claim_witness(
    Canonical,
    commitment(Lit, GlossS),
    literature_commitment,
    _{ kind: fraction_extra_claim_crosswalk,
       scope: closed_world_finite_verified_fraction_extra_claim_edges,
       canonical: Canonical,
       detail: commitment(Lit, GlossS),
       source: literature_commitment,
       literature_atom: Lit,
       projection: literature_commitment_gloss,
       derivation: literature_canonical_commitment_lookup,
       source_witness: _{ kind: literature_commitment_row,
                          module: literature_vocabulary,
                          predicate: canonical_commitment/2,
                          atom: Lit,
                          gloss: GlossS } }) :-
    fe(Canonical, Lit, _),
    catch(literature_vocabulary:canonical_commitment(Lit, Gloss), _, fail),
    ( string(Gloss) -> GlossS = Gloss ; format(string(GlossS), "~w", [Gloss]) ).
fraction_extra_claim_witness(
    Canonical,
    edge(Functor),
    Functor,
    _{ kind: fraction_extra_claim_crosswalk,
       scope: closed_world_finite_verified_fraction_extra_claim_edges,
       canonical: Canonical,
       detail: edge(Functor),
       source: Functor,
       legacy_functor: Functor,
       projection: verified_legacy_edge,
       derivation: owner_predicate_edge_check,
       source_witness: SourceWitness }) :-
    fe(Canonical, _, Edges),
    member(Functor, Edges),
    fraction_extra_edge_witness(Functor, SourceWitness).

fraction_extra_edge_witness(
    'action_automata_registry:action_automaton_cluster/3(fraction,area_model_part_of_part)',
    SourceWitness) :-
    action_cluster_witness(fraction, area_model_part_of_part, SourceWitness).
fraction_extra_edge_witness(
    'action_automata_registry:action_automaton_cluster/3(fraction,improper_fraction_iteration)',
    SourceWitness) :-
    action_cluster_witness(fraction, improper_fraction_iteration, SourceWitness).
fraction_extra_edge_witness(
    'action_automata_registry:action_automaton_cluster/3(fraction,recursive_partition)',
    SourceWitness) :-
    action_cluster_witness(fraction, recursive_partition, SourceWitness).
fraction_extra_edge_witness(
    'action_automata_registry:action_automaton_cluster/3(calculus,factor_cancel_substitute)',
    SourceWitness) :-
    action_cluster_witness(calculus, factor_cancel_substitute, SourceWitness).
fraction_extra_edge_witness(
    'action_automata_registry:action_automaton_cluster/3(calculus,factor_cancel_without_common_factor)',
    SourceWitness) :-
    action_cluster_witness(calculus, factor_cancel_without_common_factor, SourceWitness).
fraction_extra_edge_witness(
    'action_automata_registry:action_automaton_cluster/3(fraction,co_denominator_count_on_from_larger)',
    SourceWitness) :-
    action_cluster_witness(fraction, co_denominator_count_on_from_larger, SourceWitness).
fraction_extra_edge_witness(
    'action_automata_registry:action_automaton_cluster/3(fraction,solve_for_unit)',
    SourceWitness) :-
    action_cluster_witness(fraction, solve_for_unit, SourceWitness).
fraction_extra_edge_witness(
    'grounding_metaphors:grounds_inference/3(arithmetic_is_object_construction,fraction_multiplication_as_part_of_part)',
    _{ kind: grounding_metaphor_inference_edge,
       module: grounding_metaphors,
       predicate: grounds_inference_witness/4,
       metaphor: arithmetic_is_object_construction,
       target_inference: fraction_multiplication_as_part_of_part,
       grounding_path: GroundingPath,
       grounding_witness: GroundingWitness }) :-
    catch(grounding_metaphors:grounds_inference_witness(
              arithmetic_is_object_construction,
              fraction_multiplication_as_part_of_part,
              GroundingPath,
              GroundingWitness),
          _, fail).
fraction_extra_edge_witness(Functor, SourceWitness) :-
    registry_functor(Functor, Move),
    registry_incompatibility_witness(Move, SourceWitness).

action_cluster_witness(
    Operation,
    ActionKind,
    _{ kind: action_automaton_cluster_edge,
       module: action_automata_registry,
       predicate: action_automaton_cluster/3,
       operation: Operation,
       action_kind: ActionKind,
       cluster: Cluster,
       vocabulary: Vocabulary }) :-
    catch(action_automata_registry:action_automaton_cluster(Operation, ActionKind, Cluster),
          _, fail),
    catch(action_automata_registry:action_automaton_vocabulary(Operation, ActionKind, Vocabulary),
          _, fail).

registry_incompatibility_witness(
    Move,
    _{ kind: misconception_registry_incompatibility_edge,
       module: misconception_registry,
       predicate: incompatibility_with_witness/3,
       move: Move,
       conflict: Conflict,
       incompatibility_witness: IncompatibilityWitness }) :-
    catch(once(misconception_registry:incompatibility_with_witness(
                   Move,
                   Conflict,
                   IncompatibilityWitness)),
          _, fail).

registry_functor(
    'misconception_registry:incompatibility_with/2(improper_fraction_chain_loss)',
    improper_fraction_chain_loss).
registry_functor(
    'misconception_registry:incompatibility_with/2(clear_inner_referent)',
    clear_inner_referent).
registry_functor(
    'misconception_registry:incompatibility_with/2(factor_cancel_without_common_factor)',
    factor_cancel_without_common_factor).
registry_functor(
    'misconception_registry:incompatibility_with/2(iterate_only_no_reverse)',
    iterate_only_no_reverse).
