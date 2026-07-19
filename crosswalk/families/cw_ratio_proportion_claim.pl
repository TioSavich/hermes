/** <module> cw_ratio_proportion_claim — canonical crosswalk family for the ratio_proportion bucket
 *
 * One ratio_proportion commitment earned a crosswalk home because it has real,
 * verified cross-surface legacy functors expressing the same concept outside the
 * literature vocabulary:
 *
 *   - multiplicative_proportional_scaling — proportional relationships scale by
 *     multiplication, so extending a ratio is valid only when no additive constant
 *     is injected (the zero-intercept condition). Backed by:
 *       * action_automata_registry:action_automaton_pair/4 — the ratio
 *         productive/deformation pair: scale_ratio_unit (multiplicative scaling,
 *         3:4 -> 6:8) versus additive_extension_of_ratio (the deformation that
 *         injects an additive constant, 3:4 -> 6:7), yielding the family
 *         additive_comparison_in_proportion. This is exactly the proportional-vs-
 *         additive (nonzero-intercept) distinction the commitment forbids.
 *       * misconception_registry:incompatibility_with/2 — the additive deformation
 *         is deontically incompatible with the scale_ratio_unit entitlement
 *         (incompatibility_with(additive_extension_of_ratio,
 *         strategy(ratio, scale_ratio_unit))), making the misconception queryable.
 *
 * Same shape as the other crosswalk families (cf. cw_whole_number_claim,
 * cw_integer_signed_claim): it RENAMES nothing and OWNS no facts on the legacy
 * surfaces — vocabulary_source/2 is the contract the aggregator (canonical_all)
 * ranges over, canonical_concept/2 is the reverse map, and
 * ratio_proportion_claim_unified/3 is the live query that pulls the canonical gloss
 * and one row per verified legacy edge.
 *
 * The canonical commitment atom (c_proportionality_requires_zero_intercept) exists
 * as a literature_vocabulary:canonical_commitment/2 fact (defined in
 * literature_canonical_mappings.pl), so the literature gloss resolves live. The
 * rp/4 LocalGloss field records the human-readable local intent of the table,
 * but exported literature rows are proved only through
 * literature_vocabulary:canonical_commitment/2.
 *
 * Family slug: ratio_proportion_claim. Bucket: ratio_proportion.
 */
:- module(cw_ratio_proportion_claim,
          [ ratio_proportion_claim_unified/3,  % ratio_proportion_claim_unified(-Canonical, -Detail, -Source)
            ratio_proportion_claim_witness/4,  % ratio_proportion_claim_witness(?Canonical, ?Detail, ?Source, -Witness)
            claim_literature_atom/2,           % claim_literature_atom(?Canonical, ?LiteratureAtom)
            canonical_concept/2,               % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2                % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

:- use_module(misconceptions(literature_vocabulary), []).
:- use_module(misconceptions(misconception_registry), []).
:- use_module(strategies('math/action_automata_registry'), []).
:- use_module(library(lists), [ member/2, append/2 ]).

%! rp(?Canonical, ?LiteratureAtom, ?LocalGloss, ?VerifiedEdges) is nondet.
%
%  The family table. Each row: the canonical ratio_proportion concept; the
%  canonical commitment anchor atom; a local gloss for reader orientation; and
%  the verified non-literature legacy functor strings that express the same
%  concept. Each edge string carries its disambiguating arguments inline,
%  matching the convention used by cw_integer_signed_claim.
rp(multiplicative_proportional_scaling,
   c_proportionality_requires_zero_intercept,
   "Proportional relationships scale by multiplication; extending a ratio is valid only when no additive constant is injected (the zero-intercept condition).",
   [ 'action_automata_registry:action_automaton_pair/4(ratio,scale_ratio_unit,additive_extension_of_ratio)',
     'misconception_registry:incompatibility_with/2(additive_extension_of_ratio)' ]).

%! claim_literature_atom(?Canonical, ?LiteratureAtom) is nondet.
%  The canonical commitment anchor atom for a ratio_proportion concept.
claim_literature_atom(Canonical, LitAtom) :- rp(Canonical, LitAtom, _, _).

% The legacy functor strings for a canonical term: the literature anchor (as a
% 'literature_vocabulary:canonical_commitment/2(Atom)' string) followed by every
% verified non-literature edge — matching the convention of the other families.
legacy_list(Canonical, Legacies) :-
    rp(Canonical, Lit, _, Edges),
    atomic_list_concat(['literature_vocabulary:canonical_commitment/2(', Lit, ')'], LitFunctor),
    append([[LitFunctor], Edges], Legacies).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(Canonical, Legacies) :- legacy_list(Canonical, Legacies).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
canonical_concept(Legacy, Canonical) :-
    legacy_list(Canonical, Legacies),
    member(Legacy, Legacies).

%! ratio_proportion_claim_unified(?Canonical, ?Detail, ?Source) is nondet.
%
%  Source = literature_commitment: Detail = commitment(Atom, Gloss) — the canonical
%  literature gloss for this concept's anchor atom.
%  Source = <legacy functor string>: Detail = edge(Functor) — one row per verified
%  non-literature surface that expresses the concept.
ratio_proportion_claim_unified(Canonical, Detail, Source) :-
    ratio_proportion_claim_witness(Canonical, Detail, Source, _).

%! ratio_proportion_claim_witness(?Canonical, ?Detail, ?Source, -Witness) is nondet.
%
%  Witnessed form of `ratio_proportion_claim_unified/3`. This is a
%  closed-world finite check over the loaded ratio/proportion claim table and
%  the source predicates that own each listed row. The table proposes
%  alignments; this predicate succeeds only when the owning source proves the
%  referenced literature commitment, productive/deformation action pair, or
%  misconception incompatibility.
ratio_proportion_claim_witness(
    Canonical,
    commitment(Lit, GlossS),
    literature_commitment,
    WitnessDict104) :-
    witness_dict:witness_dict(ratio_proportion_claim_crosswalk, closed_world_finite_verified_ratio_proportion_claim_edges,
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
                          gloss: GlossS } }, WitnessDict104),
    rp(Canonical, Lit, _, _),
    catch(literature_vocabulary:canonical_commitment(Lit, Gloss), _, fail),
    ( string(Gloss) -> GlossS = Gloss ; format(string(GlossS), "~w", [Gloss]) ).
ratio_proportion_claim_witness(
    Canonical,
    edge(Functor),
    Functor,
    WitnessDict124) :-
    witness_dict:witness_dict(ratio_proportion_claim_crosswalk, closed_world_finite_verified_ratio_proportion_claim_edges,
                              _{canonical: Canonical,
       detail: edge(Functor),
       source: Functor,
       legacy_functor: Functor,
       projection: verified_legacy_edge,
       derivation: owner_predicate_edge_check,
       source_witness: SourceWitness }, WitnessDict124),
    rp(Canonical, _, _, Edges),
    member(Functor, Edges),
    ratio_proportion_edge_source_witness(Canonical, Functor, SourceWitness).

ratio_proportion_edge_source_witness(
    multiplicative_proportional_scaling,
    'action_automata_registry:action_automaton_pair/4(ratio,scale_ratio_unit,additive_extension_of_ratio)',
    _{ kind: action_automaton_pair_edge,
       module: action_automata_registry,
       predicate: action_automaton_pair/4,
       operation: ratio,
       productive_kind: scale_ratio_unit,
       deformation_kind: additive_extension_of_ratio,
       family: additive_comparison_in_proportion,
       productive_vocabulary: ProductiveVocabulary,
       deformation_vocabulary: DeformationVocabulary }) :-
    catch(action_automata_registry:action_automaton_pair(
              ratio,
              scale_ratio_unit,
              additive_extension_of_ratio,
              additive_comparison_in_proportion),
          _, fail),
    catch(action_automata_registry:action_automaton_vocabulary(
              ratio,
              scale_ratio_unit,
              ProductiveVocabulary),
          _, fail),
    catch(action_automata_registry:action_automaton_vocabulary(
              ratio,
              additive_extension_of_ratio,
              DeformationVocabulary),
          _, fail).
ratio_proportion_edge_source_witness(
    multiplicative_proportional_scaling,
    'misconception_registry:incompatibility_with/2(additive_extension_of_ratio)',
    _{ kind: misconception_registry_incompatibility_edge,
       module: misconception_registry,
       predicate: incompatibility_with/2,
       move: additive_extension_of_ratio,
       conflict: strategy(ratio, scale_ratio_unit),
       incompatibility_witness: IncompatibilityWitness }) :-
    catch(once(misconception_registry:incompatibility_with_witness(
                   additive_extension_of_ratio,
                   strategy(ratio, scale_ratio_unit),
                   IncompatibilityWitness)),
          _, fail).
