/** <module> cw_arithmetic_property_claim — canonical crosswalk family for the "arithmetic_properties" bucket
 *
 * Five arithmetic-property commitments earned a crosswalk home because each has a
 * real, verified cross-surface legacy functor expressing the same concept outside
 * the literature vocabulary. A literature commitment that lived only on the
 * literature surface is already in one place and is NOT promoted here; only the
 * commitments below have a second, executable surface:
 *
 *   - associativity_single_operation — grounded in the L&N object-collection
 *     metaphor via grounding_metaphors:grounds_inference/3
 *     (arithmetic_is_object_collection -> associativity_of_addition).
 *   - commutativity_operation_specific — grounded BOTH in the object-collection
 *     metaphor (grounds_inference/3, commutativity_of_addition ->
 *     pooling_order_invariance) AND in the multiplication action-automaton cluster
 *     commute_factors_preserve_product (action_automaton_cluster/3).
 *   - distributivity_over_sum — the multiplication action-automaton cluster
 *     distribute_group_size_split (action_automaton_cluster/3).
 *   - inverse_operation_coordination — the division action-automaton cluster
 *     inverse_fact_decomposition, division as the inverse of multiplication
 *     (action_automaton_cluster/3).
 *   - number_fact_compression — the two addition action-automaton clusters
 *     known_fact_retrieval and derived_fact_adjustment, both in the
 *     additive_fact_fluency cluster (action_automaton_cluster/3).
 *
 * Same shape as the other crosswalk families (cf. cw_fraction_claim): it RENAMES
 * nothing and OWNS no facts on the legacy surfaces — vocabulary_source/2 is the
 * contract the aggregator (canonical_all) ranges over, canonical_concept/2 is the
 * reverse map, and arithmetic_property_unified/3 is the live query that pulls the
 * literature gloss and one row per verified legacy edge.
 *
 * Family slug: arithmetic_property. Bucket: arithmetic_properties.
 */
:- module(cw_arithmetic_property_claim,
          [ arithmetic_property_unified/3,  % arithmetic_property_unified(-Canonical, -Detail, -Source)
            arithmetic_property_witness/4,  % arithmetic_property_witness(?Canonical, ?Detail, ?Source, -Witness)
            claim_literature_atom/2,        % claim_literature_atom(?Canonical, ?LiteratureAtom)
            canonical_concept/2,            % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2             % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

:- use_module(misconceptions(literature_vocabulary), []).
:- use_module(strategies('math/action_automata_registry'), []).
:- use_module(formalization(grounding_metaphors), []).
:- use_module(library(lists), [ member/2, append/2 ]).

%! ap(?Canonical, ?LiteratureAtom, ?VerifiedEdges) is nondet.
%
%  The family table. Each row: the canonical arithmetic-property concept; the real
%  literature canonical_commitment atom (verified present); and the verified
%  non-literature legacy functor strings that express the same concept. Each edge
%  string carries the live argument tuple so the provenance is checkable by hand
%  against the owning module.
ap(associativity_single_operation,
   c_associativity_single_operation,
   [ 'grounding_metaphors:grounds_inference/3(arithmetic_is_object_collection,associativity_of_addition,associative_erf_for_collections)' ]).
ap(commutativity_operation_specific,
   c_commutativity_operation_specific,
   [ 'grounding_metaphors:grounds_inference/3(arithmetic_is_object_collection,commutativity_of_addition,pooling_order_invariance)',
     'action_automata_registry:action_automaton_cluster/3(multiplication,commute_factors_preserve_product,multiplicative_factor_relations)' ]).
ap(distributivity_over_sum,
   c_distributivity_expansion_structure,
   [ 'action_automata_registry:action_automaton_cluster/3(multiplication,distribute_group_size_split,multiplicative_composite_units)' ]).
ap(inverse_operation_coordination,
   c_inverse_relation_structure,
   [ 'action_automata_registry:action_automaton_cluster/3(division,inverse_fact_decomposition,division_grouping_structures)' ]).
ap(number_fact_compression,
   c_number_fact_compression_fluency,
   [ 'action_automata_registry:action_automaton_cluster/3(addition,known_fact_retrieval,additive_fact_fluency)',
     'action_automata_registry:action_automaton_cluster/3(addition,derived_fact_adjustment,additive_fact_fluency)' ]).

%! claim_literature_atom(?Canonical, ?LiteratureAtom) is nondet.
%  The literature commitment atom a canonical arithmetic-property concept resolves to.
claim_literature_atom(Canonical, LitAtom) :- ap(Canonical, LitAtom, _).

% The legacy functor strings for a canonical term: the literature commitment (as a
% 'literature_vocabulary:canonical_commitment/2(Atom)' string) followed by every
% verified non-literature edge — matching the convention of the other families.
legacy_list(Canonical, Legacies) :-
    ap(Canonical, Lit, Edges),
    atomic_list_concat(['literature_vocabulary:canonical_commitment/2(', Lit, ')'], LitFunctor),
    append([[LitFunctor], Edges], Legacies).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(Canonical, Legacies) :- legacy_list(Canonical, Legacies).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
canonical_concept(Legacy, Canonical) :-
    legacy_list(Canonical, Legacies),
    member(Legacy, Legacies).

%! arithmetic_property_unified(?Canonical, ?Detail, ?Source) is nondet.
%
%  Source = literature_commitment: Detail = commitment(Atom, Gloss) — the real
%  canonical_commitment gloss for this concept's literature atom.
%  Source = <legacy functor string>: Detail = edge(Functor) — one row per verified
%  non-literature surface that expresses the concept.
arithmetic_property_unified(Canonical, Detail, Source) :-
    arithmetic_property_witness(Canonical, Detail, Source, _).

%! arithmetic_property_witness(?Canonical, ?Detail, ?Source, -Witness) is nondet.
%
%  Witnessed form of `arithmetic_property_unified/3`. This is a closed-world
%  finite check over the loaded arithmetic-property claim table and the source
%  predicates that own each listed row. The table proposes alignments; this
%  predicate succeeds only when the owner proves the referenced literature
%  commitment, grounded inference, or action-cluster edge.
arithmetic_property_witness(
    Canonical,
    commitment(Lit, GlossS),
    literature_commitment,
    WitnessDict111) :-
    witness_dict:witness_dict(arithmetic_property_crosswalk, closed_world_finite_verified_arithmetic_property_edges,
                              _{canonical: Canonical,
       detail: commitment(Lit, GlossS),
       source: literature_commitment,
       literature_atom: Lit,
       projection: literature_commitment_gloss,
       derivation: literature_canonical_commitment_lookup,
       source_witness: _{ kind: literature_commitment_row,
                          module: literature_vocabulary,
                          predicate: canonical_commitment/2,
                          atom: Lit,
                          gloss: GlossS } }, WitnessDict111),
    ap(Canonical, Lit, _),
    catch(literature_vocabulary:canonical_commitment(Lit, Gloss), _, fail),
    ( string(Gloss) -> GlossS = Gloss ; format(string(GlossS), "~w", [Gloss]) ).
arithmetic_property_witness(
    Canonical,
    edge(Functor),
    Functor,
    WitnessDict131) :-
    witness_dict:witness_dict(arithmetic_property_crosswalk, closed_world_finite_verified_arithmetic_property_edges,
                              _{canonical: Canonical,
       detail: edge(Functor),
       source: Functor,
       legacy_functor: Functor,
       projection: verified_legacy_edge,
       derivation: owner_predicate_edge_check,
       source_witness: SourceWitness }, WitnessDict131),
    ap(Canonical, _, Edges),
    member(Functor, Edges),
    arithmetic_property_edge_source_witness(Functor, SourceWitness).

arithmetic_property_edge_source_witness(
    'grounding_metaphors:grounds_inference/3(arithmetic_is_object_collection,associativity_of_addition,associative_erf_for_collections)',
    _{ kind: grounding_metaphor_inference_edge,
       module: grounding_metaphors,
       predicate: grounds_inference_witness/4,
       metaphor: arithmetic_is_object_collection,
       target_inference: associativity_of_addition,
       grounding_path: associative_erf_for_collections,
       grounding_witness: GroundingWitness }) :-
    catch(grounding_metaphors:grounds_inference_witness(
              arithmetic_is_object_collection,
              associativity_of_addition,
              associative_erf_for_collections,
              GroundingWitness),
          _, fail).
arithmetic_property_edge_source_witness(
    'grounding_metaphors:grounds_inference/3(arithmetic_is_object_collection,commutativity_of_addition,pooling_order_invariance)',
    _{ kind: grounding_metaphor_inference_edge,
       module: grounding_metaphors,
       predicate: grounds_inference_witness/4,
       metaphor: arithmetic_is_object_collection,
       target_inference: commutativity_of_addition,
       grounding_path: pooling_order_invariance,
       grounding_witness: GroundingWitness }) :-
    catch(grounding_metaphors:grounds_inference_witness(
              arithmetic_is_object_collection,
              commutativity_of_addition,
              pooling_order_invariance,
              GroundingWitness),
          _, fail).
arithmetic_property_edge_source_witness(
    'action_automata_registry:action_automaton_cluster/3(multiplication,commute_factors_preserve_product,multiplicative_factor_relations)',
    _{ kind: action_automaton_cluster_edge,
       module: action_automata_registry,
       predicate: action_automaton_cluster/3,
       operation: multiplication,
       action_kind: commute_factors_preserve_product,
       cluster: multiplicative_factor_relations }) :-
    catch(action_automata_registry:action_automaton_cluster(
              multiplication,
              commute_factors_preserve_product,
              multiplicative_factor_relations),
          _, fail).
arithmetic_property_edge_source_witness(
    'action_automata_registry:action_automaton_cluster/3(multiplication,distribute_group_size_split,multiplicative_composite_units)',
    _{ kind: action_automaton_cluster_edge,
       module: action_automata_registry,
       predicate: action_automaton_cluster/3,
       operation: multiplication,
       action_kind: distribute_group_size_split,
       cluster: multiplicative_composite_units }) :-
    catch(action_automata_registry:action_automaton_cluster(
              multiplication,
              distribute_group_size_split,
              multiplicative_composite_units),
          _, fail).
arithmetic_property_edge_source_witness(
    'action_automata_registry:action_automaton_cluster/3(division,inverse_fact_decomposition,division_grouping_structures)',
    _{ kind: action_automaton_cluster_edge,
       module: action_automata_registry,
       predicate: action_automaton_cluster/3,
       operation: division,
       action_kind: inverse_fact_decomposition,
       cluster: division_grouping_structures }) :-
    catch(action_automata_registry:action_automaton_cluster(
              division,
              inverse_fact_decomposition,
              division_grouping_structures),
          _, fail).
arithmetic_property_edge_source_witness(
    'action_automata_registry:action_automaton_cluster/3(addition,known_fact_retrieval,additive_fact_fluency)',
    _{ kind: action_automaton_cluster_edge,
       module: action_automata_registry,
       predicate: action_automaton_cluster/3,
       operation: addition,
       action_kind: known_fact_retrieval,
       cluster: additive_fact_fluency }) :-
    catch(action_automata_registry:action_automaton_cluster(
              addition,
              known_fact_retrieval,
              additive_fact_fluency),
          _, fail).
arithmetic_property_edge_source_witness(
    'action_automata_registry:action_automaton_cluster/3(addition,derived_fact_adjustment,additive_fact_fluency)',
    _{ kind: action_automaton_cluster_edge,
       module: action_automata_registry,
       predicate: action_automaton_cluster/3,
       operation: addition,
       action_kind: derived_fact_adjustment,
       cluster: additive_fact_fluency }) :-
    catch(action_automata_registry:action_automaton_cluster(
              addition,
              derived_fact_adjustment,
              additive_fact_fluency),
          _, fail).
