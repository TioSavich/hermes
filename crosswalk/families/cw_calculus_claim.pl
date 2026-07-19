/** <module> cw_calculus_claim — canonical crosswalk family for the "calculus" bucket
 *
 * Three calculus-bucket commitments earned a crosswalk home because each has a
 * real, verified cross-surface legacy functor expressing the same concept outside
 * the literature vocabulary — namely the action-automata registry in
 * strategies/math/action_automata_registry.pl:
 *
 *   - limit_process_evaluation — limits, continuity, and convergence read as
 *     limiting processes. Backed by three calculus
 *     action_automaton_cluster/3 entries: direct_substitution (limit by
 *     continuity), factor_cancel_substitute (limit through a removable
 *     discontinuity), and bounded_numerator_over_diverging_denominator
 *     (convergence to zero via a tail bound).
 *   - rate_of_change_covariation — rates and slopes coordinate covarying
 *     quantities. Backed by action_automaton_vocabulary/3 for the algebraic
 *     linear-pattern rule (whose vocabulary carries constant_rate_of_change and
 *     accumulated_change) and the algebraic guess-and-check deformation (whose
 *     vocabulary carries rate_of_change_loss — the move that drops the
 *     covariation relation).
 *   - accumulation_rate_distinction — accumulation and rate of change are
 *     distinct quantities. Backed by the same algebraic linear-pattern
 *     action_automaton_vocabulary/3 entry, where constant_rate_of_change and
 *     accumulated_change co-occur as separate vocabulary terms; the distinction
 *     is structurally present in that one vocabulary surface.
 *
 * Same shape as the other crosswalk families (cf. cw_whole_number_claim): it
 * RENAMES nothing and OWNS no facts on the legacy surfaces — vocabulary_source/2
 * is the contract the aggregator (canonical_all) ranges over, canonical_concept/2
 * is the reverse map, and calculus_claim_unified/3 is the live query that pulls the
 * canonical gloss and one row per verified legacy edge.
 *
 * All three canonical commitment atoms (c_calculus_limit_process_definition,
 * c_rate_of_change_covariation, c_accumulation_rate_distinction) exist as
 * literature_vocabulary:canonical_commitment/2 facts, so the literature gloss
 * resolves live. The cc/4 LocalGloss field records the human-readable local
 * intent of the table, but exported literature rows are proved only through
 * literature_vocabulary:canonical_commitment/2.
 *
 * Family slug: calculus_claim. Bucket: calculus.
 */
:- module(cw_calculus_claim,
          [ calculus_claim_unified/3,    % calculus_claim_unified(-Canonical, -Detail, -Source)
            calculus_claim_witness/4,    % calculus_claim_witness(?Canonical, ?Detail, ?Source, -Witness)
            claim_literature_atom/2,     % claim_literature_atom(?Canonical, ?LiteratureAtom)
            canonical_concept/2,         % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2          % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

:- use_module(misconceptions(literature_vocabulary), []).
:- use_module(strategies('math/action_automata_registry'), []).
:- use_module(library(lists), [ member/2, append/2 ]).

%! cc(?Canonical, ?LiteratureAtom, ?LocalGloss, ?VerifiedEdges) is nondet.
%
%  The family table. Each row: the canonical calculus concept; the canonical
%  commitment anchor atom; a local gloss for reader orientation; and the verified
%  non-literature legacy functor strings that express the same concept. The edge
%  strings name the registry predicate plus its (Operation,Kind) selector, since
%  that pair is what is verified to succeed.
cc(limit_process_evaluation,
   c_calculus_limit_process_definition,
   "Limits, continuity, and convergence are read as limiting processes.",
   [ 'action_automaton_cluster/3(calculus,direct_substitution)',
     'action_automaton_cluster/3(calculus,factor_cancel_substitute)',
     'action_automaton_cluster/3(calculus,bounded_numerator_over_diverging_denominator)' ]).
cc(rate_of_change_covariation,
   c_rate_of_change_covariation,
   "Rates of change and slopes coordinate covarying quantities.",
   [ 'action_automaton_vocabulary/3(algebraic,linear_pattern_contextual_rule)',
     'action_automaton_vocabulary/3(algebraic,guess_and_check_rule)' ]).
cc(accumulation_rate_distinction,
   c_accumulation_rate_distinction,
   "Accumulation and rate of change are distinct quantities.",
   [ 'action_automaton_vocabulary/3(algebraic,linear_pattern_contextual_rule)' ]).

%! claim_literature_atom(?Canonical, ?LiteratureAtom) is nondet.
%  The canonical commitment anchor atom for a calculus concept.
claim_literature_atom(Canonical, LitAtom) :- cc(Canonical, LitAtom, _, _).

% The legacy functor strings for a canonical term: the literature anchor (as a
% 'literature_vocabulary:canonical_commitment/2(Atom)' string) followed by every
% verified non-literature edge — matching the convention of the other families.
legacy_list(Canonical, Legacies) :-
    cc(Canonical, Lit, _, Edges),
    atomic_list_concat(['literature_vocabulary:canonical_commitment/2(', Lit, ')'], LitFunctor),
    append([[LitFunctor], Edges], Legacies).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(Canonical, Legacies) :- legacy_list(Canonical, Legacies).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
canonical_concept(Legacy, Canonical) :-
    legacy_list(Canonical, Legacies),
    member(Legacy, Legacies).

%! calculus_claim_unified(?Canonical, ?Detail, ?Source) is nondet.
%
%  Source = literature_commitment: Detail = commitment(Atom, Gloss) — the canonical
%  literature gloss for this concept's anchor atom.
%  Source = <legacy functor string>: Detail = edge(Functor) — one row per verified
%  non-literature surface that expresses the concept.
calculus_claim_unified(Canonical, Detail, Source) :-
    calculus_claim_witness(Canonical, Detail, Source, _).

%! calculus_claim_witness(?Canonical, ?Detail, ?Source, -Witness) is nondet.
%
%  Witnessed form of `calculus_claim_unified/3`. This is a closed-world finite
%  check over the loaded calculus-claim table and the registry predicates that
%  own each listed row. The table proposes alignments; this predicate succeeds
%  only when the owning source proves the referenced literature commitment,
%  action cluster, or action vocabulary.
calculus_claim_witness(
    Canonical,
    commitment(Lit, GlossS),
    literature_commitment,
    WitnessDict116) :-
    witness_dict:witness_dict(calculus_claim_crosswalk, closed_world_finite_verified_calculus_claim_edges,
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
                          gloss: GlossS } }, WitnessDict116),
    cc(Canonical, Lit, _, _),
    catch(literature_vocabulary:canonical_commitment(Lit, Gloss), _, fail),
    ( string(Gloss) -> GlossS = Gloss ; format(string(GlossS), "~w", [Gloss]) ).
calculus_claim_witness(
    Canonical,
    edge(Functor),
    Functor,
    WitnessDict136) :-
    witness_dict:witness_dict(calculus_claim_crosswalk, closed_world_finite_verified_calculus_claim_edges,
                              _{canonical: Canonical,
       detail: edge(Functor),
       source: Functor,
       legacy_functor: Functor,
       projection: verified_legacy_edge,
       derivation: owner_predicate_edge_check,
       source_witness: SourceWitness }, WitnessDict136),
    cc(Canonical, _, _, Edges),
    member(Functor, Edges),
    calculus_claim_edge_source_witness(Functor, SourceWitness).

calculus_claim_edge_source_witness(
    'action_automaton_cluster/3(calculus,direct_substitution)',
    _{ kind: action_automaton_cluster_edge,
       module: action_automata_registry,
       predicate: action_automaton_cluster/3,
       operation: calculus,
       action_kind: direct_substitution,
       cluster: Cluster }) :-
    catch(action_automata_registry:action_automaton_cluster(
              calculus, direct_substitution, Cluster),
          _, fail).
calculus_claim_edge_source_witness(
    'action_automaton_cluster/3(calculus,factor_cancel_substitute)',
    _{ kind: action_automaton_cluster_edge,
       module: action_automata_registry,
       predicate: action_automaton_cluster/3,
       operation: calculus,
       action_kind: factor_cancel_substitute,
       cluster: Cluster }) :-
    catch(action_automata_registry:action_automaton_cluster(
              calculus, factor_cancel_substitute, Cluster),
          _, fail).
calculus_claim_edge_source_witness(
    'action_automaton_cluster/3(calculus,bounded_numerator_over_diverging_denominator)',
    _{ kind: action_automaton_cluster_edge,
       module: action_automata_registry,
       predicate: action_automaton_cluster/3,
       operation: calculus,
       action_kind: bounded_numerator_over_diverging_denominator,
       cluster: Cluster }) :-
    catch(action_automata_registry:action_automaton_cluster(
              calculus, bounded_numerator_over_diverging_denominator, Cluster),
          _, fail).
calculus_claim_edge_source_witness(
    'action_automaton_vocabulary/3(algebraic,linear_pattern_contextual_rule)',
    _{ kind: action_automaton_vocabulary_edge,
       module: action_automata_registry,
       predicate: action_automaton_vocabulary/3,
       operation: algebraic,
       action_kind: linear_pattern_contextual_rule,
       vocabulary: Vocabulary }) :-
    catch(action_automata_registry:action_automaton_vocabulary(
              algebraic, linear_pattern_contextual_rule, Vocabulary),
          _, fail).
calculus_claim_edge_source_witness(
    'action_automaton_vocabulary/3(algebraic,guess_and_check_rule)',
    _{ kind: action_automaton_vocabulary_edge,
       module: action_automata_registry,
       predicate: action_automaton_vocabulary/3,
       operation: algebraic,
       action_kind: guess_and_check_rule,
       vocabulary: Vocabulary }) :-
    catch(action_automata_registry:action_automaton_vocabulary(
              algebraic, guess_and_check_rule, Vocabulary),
          _, fail).
