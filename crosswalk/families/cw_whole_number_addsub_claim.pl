/** <module> cw_whole_number_addsub_claim — canonical crosswalk family for the
 *  whole-number addition/subtraction bucket
 *
 * Four addition/subtraction commitments earned a crosswalk home because each has
 * a real, verified cross-surface legacy functor expressing the same concept
 * outside the literature vocabulary:
 *
 *   - addition_closure_totality — addition is defined for every pair and generates
 *     totals beyond a memorized set. Backed by grounded_arithmetic:add_grounded/3
 *     (computes a total for any pair of recollections; verified 2+3=5, 5+2=7) and
 *     grounding_metaphors:grounds_inference/3 (the object-collection metaphor
 *     grounds commutativity_of_addition and associativity_of_addition).
 *   - subtraction_fixed_removal — subtraction removes a fixed quantity (take-away).
 *     Backed by action_automata_registry:action_automaton_cluster/3 for the
 *     subtraction kind take_away_base_ones and by
 *     grounded_arithmetic:subtract_grounded/3 (verified 5-2=3).
 *   - subtraction_directed_difference — subtraction as a difference (comparison)
 *     relation, with order-sensitivity. Backed by
 *     action_automata_registry:action_automaton_cluster/3 for the subtraction kind
 *     compare_by_matching_difference and by grounding_metaphors:metaphor_breaks_at/3
 *     (the arithmetic_is_object_collection break at subtraction_of_larger_from_smaller,
 *     which marks the order-sensitivity boundary).
 *   - self_subtraction_identity_zero — any quantity minus itself is zero. Backed by
 *     grounded_arithmetic:subtract_grounded/3 (verified 3-3=0, 4-4=0).
 *
 * Same shape as the other crosswalk families (cf. cw_whole_number_claim,
 * cw_fraction_claim): it RENAMES nothing and OWNS no facts on the legacy surfaces
 * — vocabulary_source/2 is the contract the aggregator (canonical_all) ranges
 * over, canonical_concept/2 is the reverse map, and
 * whole_number_addsub_claim_unified/3 is the live query that pulls the canonical
 * gloss and one row per verified legacy edge.
 *
 * All four canonical commitment atoms (c_addition_total_operation,
 * c_subtraction_removes_fixed_quantity, c_subtraction_order_difference_relation,
 * c_self_subtraction_yields_zero) resolve as
 * literature_vocabulary:canonical_commitment/2 facts, so the literature gloss
 * resolves live. The wn/4 LocalGloss field records the human-readable local
 * intent of the table, but exported literature rows are proved only through
 * literature_vocabulary:canonical_commitment/2.
 *
 * The action_automaton_cluster edges are recorded with the bound (subtraction,
 * Kind) arguments embedded in the functor string so the reverse map and the
 * aggregator can tell the two subtraction kinds apart; the predicate itself is
 * action_automaton_cluster/3.
 *
 * Family slug: whole_number_addsub_claim. Bucket: whole_number_addition_subtraction.
 */
:- module(cw_whole_number_addsub_claim,
          [ whole_number_addsub_claim_unified/3,  % whole_number_addsub_claim_unified(-Canonical, -Detail, -Source)
            whole_number_addsub_claim_witness/4,  % whole_number_addsub_claim_witness(?Canonical, ?Detail, ?Source, -Witness)
            claim_literature_atom/2,              % claim_literature_atom(?Canonical, ?LiteratureAtom)
            canonical_concept/2,                  % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2                   % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

:- use_module(misconceptions(literature_vocabulary), []).
:- use_module(strategies('math/action_automata_registry'), []).
:- use_module(formalization(grounded_arithmetic), []).
:- use_module(formalization(grounding_metaphors), []).
:- use_module(library(lists), [ member/2, append/2 ]).

%! wn(?Canonical, ?LiteratureAtom, ?LocalGloss, ?VerifiedEdges) is nondet.
%
%  The family table. Each row: the canonical addition/subtraction concept; the
%  canonical commitment anchor atom; a local gloss for reader orientation; and
%  the verified non-literature legacy functor strings that express the same
%  concept.
wn(addition_closure_totality,
   c_addition_total_operation,
   "Addition is defined for every pair of numbers and generates totals beyond any memorized set.",
   [ 'grounded_arithmetic:add_grounded/3',
     'grounding_metaphors:grounds_inference/3' ]).
wn(subtraction_fixed_removal,
   c_subtraction_removes_fixed_quantity,
   "Subtraction removes a fixed quantity from a starting amount (take-away).",
   [ 'action_automata_registry:action_automaton_cluster/3(subtraction,take_away_base_ones)',
     'grounded_arithmetic:subtract_grounded/3' ]).
wn(subtraction_directed_difference,
   c_subtraction_order_difference_relation,
   "Subtraction expresses a directed difference (comparison) and is order-sensitive: the larger cannot be removed from the smaller in the collection metaphor.",
   [ 'action_automata_registry:action_automaton_cluster/3(subtraction,compare_by_matching_difference)',
     'grounding_metaphors:metaphor_breaks_at/3' ]).
wn(self_subtraction_identity_zero,
   c_self_subtraction_yields_zero,
   "Any quantity minus itself is zero.",
   [ 'grounded_arithmetic:subtract_grounded/3' ]).

%! claim_literature_atom(?Canonical, ?LiteratureAtom) is nondet.
%  The canonical commitment anchor atom for an addition/subtraction concept.
claim_literature_atom(Canonical, LitAtom) :- wn(Canonical, LitAtom, _, _).

% The legacy functor strings for a canonical term: the literature anchor (as a
% 'literature_vocabulary:canonical_commitment/2(Atom)' string) followed by every
% verified non-literature edge — matching the convention of the other families.
legacy_list(Canonical, Legacies) :-
    wn(Canonical, Lit, _, Edges),
    atomic_list_concat(['literature_vocabulary:canonical_commitment/2(', Lit, ')'], LitFunctor),
    append([[LitFunctor], Edges], Legacies).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(Canonical, Legacies) :- legacy_list(Canonical, Legacies).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
canonical_concept(Legacy, Canonical) :-
    legacy_list(Canonical, Legacies),
    member(Legacy, Legacies).

%! whole_number_addsub_claim_unified(?Canonical, ?Detail, ?Source) is nondet.
%
%  Source = literature_commitment: Detail = commitment(Atom, Gloss) — the canonical
%  literature gloss for this concept's anchor atom.
%  Source = <legacy functor string>: Detail = edge(Functor) — one row per verified
%  non-literature surface that expresses the concept.
whole_number_addsub_claim_unified(Canonical, Detail, Source) :-
    whole_number_addsub_claim_witness(Canonical, Detail, Source, _).

%! whole_number_addsub_claim_witness(?Canonical, ?Detail, ?Source, -Witness) is nondet.
%
%  Witnessed form of `whole_number_addsub_claim_unified/3`. This is a
%  closed-world finite check over the loaded addition/subtraction claim table
%  and the source predicates that own each listed row. The table proposes
%  alignments; this predicate succeeds only when the owning source proves the
%  referenced literature commitment, action cluster, grounded arithmetic
%  relation, or grounding-metaphor relation.
whole_number_addsub_claim_witness(
    Canonical,
    commitment(Lit, GlossS),
    literature_commitment,
    WitnessDict129) :-
    witness_dict:witness_dict(whole_number_addsub_claim_crosswalk, closed_world_finite_verified_whole_number_addsub_claim_edges,
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
                          gloss: GlossS } }, WitnessDict129),
    wn(Canonical, Lit, _, _),
    catch(literature_vocabulary:canonical_commitment(Lit, Gloss), _, fail),
    ( string(Gloss) -> GlossS = Gloss ; format(string(GlossS), "~w", [Gloss]) ).
whole_number_addsub_claim_witness(
    Canonical,
    edge(Functor),
    Functor,
    WitnessDict149) :-
    witness_dict:witness_dict(whole_number_addsub_claim_crosswalk, closed_world_finite_verified_whole_number_addsub_claim_edges,
                              _{canonical: Canonical,
       detail: edge(Functor),
       source: Functor,
       legacy_functor: Functor,
       projection: verified_legacy_edge,
       derivation: owner_predicate_edge_check,
       source_witness: SourceWitness }, WitnessDict149),
    wn(Canonical, _, _, Edges),
    member(Functor, Edges),
    whole_number_addsub_edge_source_witness(Canonical, Functor, SourceWitness).

whole_number_addsub_edge_source_witness(
    addition_closure_totality,
    'grounded_arithmetic:add_grounded/3',
    _{ kind: grounded_addition_edge,
       module: grounded_arithmetic,
       predicate: add_grounded/3,
       samples: [SampleA, SampleB],
       evidence_policy: finite_sample_of_total_predicate }) :-
    grounded_add_sample(2, 3, 5, SampleA),
    grounded_add_sample(5, 2, 7, SampleB).
whole_number_addsub_edge_source_witness(
    addition_closure_totality,
    'grounding_metaphors:grounds_inference/3',
    _{ kind: grounding_metaphor_inference_edge,
       module: grounding_metaphors,
       predicate: grounds_inference/3,
       metaphor: arithmetic_is_object_collection,
       target_inferences: [commutativity_of_addition, associativity_of_addition],
       grounding_witnesses: [CommutativeWitness, AssociativeWitness] }) :-
    catch(grounding_metaphors:grounds_inference_witness(
              arithmetic_is_object_collection,
              commutativity_of_addition,
              _CommutativePath,
              CommutativeWitness),
          _, fail),
    catch(grounding_metaphors:grounds_inference_witness(
              arithmetic_is_object_collection,
              associativity_of_addition,
              _AssociativePath,
              AssociativeWitness),
          _, fail).
whole_number_addsub_edge_source_witness(
    subtraction_fixed_removal,
    'action_automata_registry:action_automaton_cluster/3(subtraction,take_away_base_ones)',
    _{ kind: action_automaton_cluster_edge,
       module: action_automata_registry,
       predicate: action_automaton_cluster/3,
       operation: subtraction,
       action_kind: take_away_base_ones,
       cluster: Cluster,
       vocabulary: Vocabulary }) :-
    catch(action_automata_registry:action_automaton_cluster(
              subtraction,
              take_away_base_ones,
              Cluster),
          _, fail),
    catch(action_automata_registry:action_automaton_vocabulary(
              subtraction,
              take_away_base_ones,
              Vocabulary),
          _, fail).
whole_number_addsub_edge_source_witness(
    subtraction_fixed_removal,
    'grounded_arithmetic:subtract_grounded/3',
    _{ kind: grounded_subtraction_edge,
       module: grounded_arithmetic,
       predicate: subtract_grounded/3,
       interpretation: fixed_removal,
       samples: [Sample],
       evidence_policy: finite_sample_of_partial_predicate }) :-
    grounded_subtract_sample(5, 2, 3, Sample).
whole_number_addsub_edge_source_witness(
    subtraction_directed_difference,
    'action_automata_registry:action_automaton_cluster/3(subtraction,compare_by_matching_difference)',
    _{ kind: action_automaton_cluster_edge,
       module: action_automata_registry,
       predicate: action_automaton_cluster/3,
       operation: subtraction,
       action_kind: compare_by_matching_difference,
       cluster: Cluster,
       vocabulary: Vocabulary }) :-
    catch(action_automata_registry:action_automaton_cluster(
              subtraction,
              compare_by_matching_difference,
              Cluster),
          _, fail),
    catch(action_automata_registry:action_automaton_vocabulary(
              subtraction,
              compare_by_matching_difference,
              Vocabulary),
          _, fail).
whole_number_addsub_edge_source_witness(
    subtraction_directed_difference,
    'grounding_metaphors:metaphor_breaks_at/3',
    _{ kind: grounding_metaphor_break_edge,
       module: grounding_metaphors,
       predicate: metaphor_breaks_at/3,
       metaphor: arithmetic_is_object_collection,
       target_inference: subtraction_of_larger_from_smaller,
       reason: Reason,
       break_witness: BreakWitness }) :-
    catch(grounding_metaphors:metaphor_break_witness(
              arithmetic_is_object_collection,
              subtraction_of_larger_from_smaller,
              Reason,
              BreakWitness),
          _, fail).
whole_number_addsub_edge_source_witness(
    self_subtraction_identity_zero,
    'grounded_arithmetic:subtract_grounded/3',
    _{ kind: grounded_subtraction_edge,
       module: grounded_arithmetic,
       predicate: subtract_grounded/3,
       interpretation: self_subtraction_identity_zero,
       samples: [SampleA, SampleB],
       evidence_policy: finite_samples_of_identity_case }) :-
    grounded_subtract_sample(3, 3, 0, SampleA),
    grounded_subtract_sample(4, 4, 0, SampleB).

grounded_add_sample(LeftInteger, RightInteger, SumInteger,
                    _{ left_integer: LeftInteger,
                       right_integer: RightInteger,
                       sum_integer: SumInteger,
                       left: Left,
                       right: Right,
                       sum: Sum }) :-
    catch(grounded_arithmetic:integer_to_recollection(LeftInteger, Left), _, fail),
    catch(grounded_arithmetic:integer_to_recollection(RightInteger, Right), _, fail),
    catch(grounded_arithmetic:add_grounded(Left, Right, Sum), _, fail),
    catch(grounded_arithmetic:recollection_to_integer(Sum, SumInteger), _, fail).

grounded_subtract_sample(MinuendInteger, SubtrahendInteger, DifferenceInteger,
                         _{ minuend_integer: MinuendInteger,
                            subtrahend_integer: SubtrahendInteger,
                            difference_integer: DifferenceInteger,
                            minuend: Minuend,
                            subtrahend: Subtrahend,
                            difference: Difference }) :-
    catch(grounded_arithmetic:integer_to_recollection(MinuendInteger, Minuend), _, fail),
    catch(grounded_arithmetic:integer_to_recollection(SubtrahendInteger, Subtrahend), _, fail),
    catch(grounded_arithmetic:subtract_grounded(Minuend, Subtrahend, Difference), _, fail),
    catch(grounded_arithmetic:recollection_to_integer(Difference, DifferenceInteger), _, fail).
