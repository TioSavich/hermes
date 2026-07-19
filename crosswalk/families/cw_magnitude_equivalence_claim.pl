/** <module> cw_magnitude_equivalence_claim — canonical crosswalk family for the
 *  magnitude_equivalence bucket
 *
 * Two literature commitments in this bucket have cross-surface presence: each is
 * stated as a literature canonical_commitment atom AND expressed by real,
 * verified action-automaton clusters in the strategies registry. That dual
 * residence is what earns them a crosswalk home; a literature-only commitment is
 * already in one place and is not promoted here.
 *
 *   - ratio_invariance_under_scaling (c_multiplicative_ratio_invariance): the
 *     ratio is preserved under common scaling. Productive cluster:
 *     action_automaton_cluster(ratio, scale_ratio_unit, _). Deformation cluster
 *     that breaks multiplicative invariance by extending additively:
 *     action_automaton_cluster(ratio, additive_extension_of_ratio, _).
 *
 *   - total_conserved_under_transformation (c_conservation_invariance): a total
 *     or difference is preserved under a structure-respecting transformation.
 *     Verified clusters: commutation of factors preserves the product
 *     (multiplication, commute_factors_preserve_product), base regrouping
 *     preserves the total (multiplication, regroup_to_base_preserving_total), and
 *     sliding both terms preserves the difference
 *     (subtraction, sliding_constant_difference).
 *
 * Same shape as the other crosswalk families: it RENAMES nothing and OWNS no
 * facts — vocabulary_source/2 is the contract the aggregator (canonical_all)
 * ranges over, canonical_concept/2 is the reverse map, and
 * magnitude_equivalence_claim_unified/3 is the live query that pulls the
 * literature gloss and one row per verified edge per canonical term.
 *
 * Family slug: magnitude_equivalence_claim.
 */
:- module(cw_magnitude_equivalence_claim,
          [ magnitude_equivalence_claim_unified/3, % (-Canonical, -Detail, -Source)
            magnitude_equivalence_claim_witness/4, % (?Canonical, ?Detail, ?Source, -Witness)
            claim_literature_atom/2,               % (?Canonical, ?LiteratureAtom)
            canonical_concept/2,                   % (?LegacyFunctor, ?Canonical)
            vocabulary_source/2                    % (?Canonical, ?ListOfLegacyFunctors)
          ]).

:- use_module(misconceptions(literature_vocabulary), []).
:- use_module(strategies('math/action_automata_registry'), []).
:- use_module(library(lists), [ member/2, append/2 ]).

%! me(?Canonical, ?LiteratureAtom, ?VerifiedEdges) is nondet.
%
%  The family table. Each row: the canonical concept; the real literature
%  canonical_commitment atom (verified present); and the list of verified
%  action-automaton cluster edges, each as Operation-Kind, taken verbatim from
%  strategies/math/action_automata_registry.pl.
me(ratio_invariance_under_scaling,
   c_multiplicative_ratio_invariance,
   [ ratio-scale_ratio_unit,
     ratio-additive_extension_of_ratio ]).
me(total_conserved_under_transformation,
   c_conservation_invariance,
   [ multiplication-commute_factors_preserve_product,
     multiplication-regroup_to_base_preserving_total,
     subtraction-sliding_constant_difference ]).

%! claim_literature_atom(?Canonical, ?LiteratureAtom) is nondet.
%  The literature commitment atom a canonical concept resolves to.
claim_literature_atom(Canonical, LitAtom) :- me(Canonical, LitAtom, _).

% Render a verified Operation-Kind edge as a 'Module:Functor/Arity(args)' atom,
% matching the convention used by the other families.
edge_functor(Op-Kind, Functor) :-
    atomic_list_concat(['action_automata_registry:action_automaton_cluster/3(',
                        Op, ',', Kind, ')'], Functor).

% The legacy functor strings for a canonical term: literature commitment atom
% first, then one functor per verified edge.
legacy_list(Canonical, Legacies) :-
    me(Canonical, Lit, Edges),
    atomic_list_concat(['literature_vocabulary:canonical_commitment/2(', Lit, ')'], LitFunctor),
    findall(F, ( member(E, Edges), edge_functor(E, F) ), EdgeFunctors),
    append([[LitFunctor], EdgeFunctors], Legacies).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(Canonical, Legacies) :- legacy_list(Canonical, Legacies).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
canonical_concept(Legacy, Canonical) :-
    legacy_list(Canonical, Legacies),
    member(Legacy, Legacies).

%! magnitude_equivalence_claim_unified(-Canonical, -Detail, -Source) is nondet.
%
%  Source = literature_commitment: Detail = commitment(Atom, Gloss) — the real
%  canonical_commitment gloss for this concept's literature atom.
%  Source = the verified surface string: Detail = edge(Op-Kind) — one row per
%  verified action-automaton cluster edge.
magnitude_equivalence_claim_unified(Canonical, Detail, Source) :-
    magnitude_equivalence_claim_witness(Canonical, Detail, Source, _).

%! magnitude_equivalence_claim_witness(?Canonical, ?Detail, ?Source, -Witness) is nondet.
%
%  Witnessed form of `magnitude_equivalence_claim_unified/3`. This is a
%  closed-world finite check over the loaded magnitude-equivalence claim table
%  and the source predicates that own each listed row. The table proposes
%  alignments; this predicate succeeds only when the owning source proves the
%  referenced literature commitment, action cluster, and action vocabulary.
magnitude_equivalence_claim_witness(
    Canonical,
    commitment(Lit, GlossS),
    literature_commitment,
    WitnessDict106) :-
    witness_dict:witness_dict(magnitude_equivalence_claim_crosswalk, closed_world_finite_verified_magnitude_equivalence_claim_edges,
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
                          gloss: GlossS } }, WitnessDict106),
    me(Canonical, Lit, _),
    catch(literature_vocabulary:canonical_commitment(Lit, Gloss), _, fail),
    ( string(Gloss) -> GlossS = Gloss ; format(string(GlossS), "~w", [Gloss]) ).
magnitude_equivalence_claim_witness(
    Canonical,
    edge(Op-Kind),
    Functor,
    WitnessDict126) :-
    witness_dict:witness_dict(magnitude_equivalence_claim_crosswalk, closed_world_finite_verified_magnitude_equivalence_claim_edges,
                              _{canonical: Canonical,
       detail: edge(Op-Kind),
       source: Functor,
       legacy_functor: Functor,
       projection: verified_legacy_edge,
       derivation: owner_predicate_edge_check,
       source_witness: SourceWitness }, WitnessDict126),
    me(Canonical, _, Edges),
    member(Op-Kind, Edges),
    edge_functor(Op-Kind, Functor),
    magnitude_equivalence_edge_source_witness(Op, Kind, SourceWitness).

magnitude_equivalence_edge_source_witness(
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
