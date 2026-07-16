/** <module> cw_whole_number_claim — canonical crosswalk family for the "zero" bucket
 *
 * Two zero-concept commitments earned a crosswalk home because each has a real,
 * verified cross-surface legacy functor expressing the same concept outside the
 * literature vocabulary:
 *
 *   - zero_as_a_number_status — the L&N grounding-metaphor account of why zero is
 *     not a source-domain referent in the collection/construction metaphors, and
 *     the ad-hoc repair metaphor that restores the additive identity. Backed by
 *     grounding_metaphors:metaphor_breaks_at/3 (the arithmetic_is_object_collection
 *     and arithmetic_is_object_construction breaks at zero_as_a_number) and
 *     grounding_metaphors:metaphor_repair/4 (the zero_collection_metaphor repair).
 *   - multiplicative_annihilation_by_zero — the grounded-arithmetic fact that any
 *     number times zero is zero. Backed by grounded_arithmetic:multiply_grounded/3
 *     (multiply_grounded(_A, recollection([]), Zero) :- zero(Zero)).
 *
 * Same shape as the other crosswalk families (cf. cw_fraction_claim): it RENAMES
 * nothing and OWNS no facts on the legacy surfaces — vocabulary_source/2 is the
 * contract the aggregator (canonical_all) ranges over, canonical_concept/2 is the
 * reverse map, and whole_number_claim_unified/3 is the live query that pulls the
 * canonical gloss and one row per verified legacy edge.
 *
 * Both canonical commitment atoms (c_zero_number_status,
 * c_zero_multiplicative_annihilation) exist as
 * literature_vocabulary:canonical_commitment/2 facts, so the literature gloss
 * resolves live through the owner predicate.
 *
 * Family slug: whole_number_claim. Bucket: zero.
 */
:- module(cw_whole_number_claim,
          [ whole_number_claim_unified/3,  % whole_number_claim_unified(-Canonical, -Detail, -Source)
            whole_number_claim_witness/4,  % whole_number_claim_witness(?Canonical, ?Detail, ?Source, -Witness)
            claim_literature_atom/2,       % claim_literature_atom(?Canonical, ?LiteratureAtom)
            canonical_concept/2,           % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2            % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

:- use_module(misconceptions(literature_vocabulary), []).
:- use_module(formalization(grounding_metaphors), []).
:- use_module(formalization(grounded_arithmetic), []).
:- use_module(library(lists), [ member/2, append/2 ]).

%! wn(?Canonical, ?LiteratureAtom, ?VerifiedEdges) is nondet.
%
%  The family table. Each row: the canonical zero concept; the canonical
%  commitment anchor atom; and the verified non-literature legacy functor strings
%  that express the same concept.
wn(zero_as_a_number_status,
   c_zero_number_status,
   [ 'grounding_metaphors:metaphor_breaks_at/3',
     'grounding_metaphors:metaphor_repair/4' ]).
wn(multiplicative_annihilation_by_zero,
   c_zero_multiplicative_annihilation,
   [ 'grounded_arithmetic:multiply_grounded/3' ]).

%! claim_literature_atom(?Canonical, ?LiteratureAtom) is nondet.
%  The canonical commitment anchor atom for a zero concept.
claim_literature_atom(Canonical, LitAtom) :- wn(Canonical, LitAtom, _).

% The legacy functor strings for a canonical term: the literature anchor (as a
% 'literature_vocabulary:canonical_commitment/2(Atom)' string) followed by every
% verified non-literature edge — matching the convention of the other families.
legacy_list(Canonical, Legacies) :-
    wn(Canonical, Lit, Edges),
    atomic_list_concat(['literature_vocabulary:canonical_commitment/2(', Lit, ')'], LitFunctor),
    append([[LitFunctor], Edges], Legacies).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(Canonical, Legacies) :- legacy_list(Canonical, Legacies).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
canonical_concept(Legacy, Canonical) :-
    legacy_list(Canonical, Legacies),
    member(Legacy, Legacies).

%! whole_number_claim_unified(?Canonical, ?Detail, ?Source) is nondet.
%
%  Source = literature_commitment: Detail = commitment(Atom, Gloss) — the
%  owner-proved canonical gloss for this concept's anchor atom.
%  Source = <legacy functor string>: Detail = edge(Functor) — one row per verified
%  non-literature surface that expresses the concept.
whole_number_claim_unified(Canonical, Detail, Source) :-
    whole_number_claim_witness(Canonical, Detail, Source, _).

%! whole_number_claim_witness(?Canonical, ?Detail, ?Source, -Witness) is nondet.
%
%  Witnessed form of `whole_number_claim_unified/3`. This is a closed-world
%  finite check over the loaded zero-claim crosswalk table and the source
%  predicates that own each listed row. The table proposes alignments; this
%  predicate succeeds only when the owning source proves the referenced
%  literature commitment, grounding-metaphor break/repair, or grounded
%  multiplication-by-zero result.
whole_number_claim_witness(
    Canonical,
    commitment(Lit, GlossS),
    literature_commitment,
    _{ kind: whole_number_claim_crosswalk,
       scope: closed_world_finite_verified_zero_claim_edges,
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
    wn(Canonical, Lit, _),
    anchor_gloss(Lit, GlossS).
whole_number_claim_witness(
    Canonical,
    edge(Functor),
    Functor,
    _{ kind: whole_number_claim_crosswalk,
       scope: closed_world_finite_verified_zero_claim_edges,
       canonical: Canonical,
       detail: edge(Functor),
       source: Functor,
       legacy_functor: Functor,
       projection: verified_legacy_edge,
       derivation: owner_predicate_edge_check,
       source_witness: SourceWitness }) :-
    wn(Canonical, _, Edges),
    member(Functor, Edges),
    whole_number_edge_witness(Functor, SourceWitness).

anchor_gloss(Lit, GlossS) :-
    catch(literature_vocabulary:canonical_commitment(Lit, Gloss), _, fail),
    ( string(Gloss) -> GlossS = Gloss ; format(string(GlossS), "~w", [Gloss]) ).

whole_number_edge_witness(
    'grounding_metaphors:metaphor_breaks_at/3',
    _{ kind: grounding_metaphor_break_set,
       module: grounding_metaphors,
       predicate: metaphor_breaks_at/3,
       target_inference: zero_as_a_number,
       break_witnesses: BreakWitnesses }) :-
    findall(
        _{ metaphor: Metaphor,
           reason: Reason,
           break_witness: BreakWitness },
        catch(grounding_metaphors:metaphor_break_witness(
                  Metaphor,
                  zero_as_a_number,
                  Reason,
                  BreakWitness),
              _, fail),
        BreakWitnesses),
    BreakWitnesses \== [].
whole_number_edge_witness(
    'grounding_metaphors:metaphor_repair/4',
    _{ kind: grounding_metaphor_repair_set,
       module: grounding_metaphors,
       predicate: metaphor_repair/4,
       broken_inference: zero_as_a_number,
       repair_witnesses: RepairWitnesses }) :-
    findall(
        _{ broken_metaphor: BrokenMetaphor,
           repair_metaphor: RepairMetaphor,
           mechanism: Mechanism,
           repair_witness: RepairWitness },
        catch(grounding_metaphors:metaphor_repair_witness(
                  BrokenMetaphor,
                  zero_as_a_number,
                  RepairMetaphor,
                  Mechanism,
                  RepairWitness),
              _, fail),
        RepairWitnesses),
    RepairWitnesses \== [].
whole_number_edge_witness(
    'grounded_arithmetic:multiply_grounded/3',
    _{ kind: grounded_arithmetic_multiplication_by_zero,
       module: grounded_arithmetic,
       predicate: multiply_grounded/3,
       sample_left_factor: recollection([unit]),
       sample_right_factor: recollection([]),
       product: recollection([]),
       zero_witness: zero(recollection([])) }) :-
    catch(grounded_arithmetic:multiply_grounded(
              recollection([unit]),
              recollection([]),
              recollection([])),
          _, fail),
    catch(grounded_arithmetic:zero(recollection([])), _, fail).
