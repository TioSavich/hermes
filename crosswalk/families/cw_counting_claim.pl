/** <module> cw_counting_claim — canonical crosswalk family for the counting_subitizing bucket
 *
 * Five counting/subitizing commitments earned a crosswalk home because each has a
 * real, verified cross-surface legacy functor expressing the same concept outside
 * the literature vocabulary:
 *
 *   - unit_coordination_cardinality — counting and cardinality require one-to-one
 *     unit coordination over stable counted units. Backed by the diagnostic action
 *     automaton cluster action_automaton_cluster(diagnostic,
 *     rigorous_counting_procedure, diagnostic_cardinality_by_bijective_counting),
 *     whose vocabulary covers one_to_one_correspondence, stable_order,
 *     cardinal_principle, collection_cardinality, bijective_counting.
 *   - systematic_outcome_enumeration — combinatorial counts require systematic
 *     enumeration of a stipulated outcome structure. Backed by two probability
 *     action automaton clusters: the probability_weighted_terminal_tree cluster
 *     (tree_diagram, terminal_branch, disjoint_outcomes, non_equiprobable_terminal_paths)
 *     and the equiprobable_endpoint_counting kind (terminal_endpoint, endpoint_count,
 *     sample_set).
 *   - perceptual_pattern_quantity — structured arrangements present recognizable
 *     cardinal patterns, not only collections requiring serial unit counting. Backed
 *     by Indiana K.NS.4 standard_k_ns_4:subitize/2 and conceptual_subitize/3 (the
 *     latter carries a decomposition).
 *   - conventional_numeral_naming — counting follows the conventional stable
 *     number-word sequence, including its irregular teen names. Backed by Indiana
 *     K.NS.2 standard_k_ns_2:numeral_known/2 (the naming table) and number_word/2
 *     (eleven, twelve, thirteen, ...).
 *   - successor_total_generation — every natural number has a successor, so the
 *     counting sequence is unbounded. Backed by grounded_arithmetic:successor/2
 *     (the total successor operation: every number has a next).
 *
 * Same shape as the other crosswalk families (cf. cw_whole_number_claim,
 * cw_fraction_claim): it RENAMES nothing and OWNS no facts on the legacy surfaces —
 * vocabulary_source/2 is the contract the aggregator (canonical_all) ranges over,
 * canonical_concept/2 is the reverse map, and counting_claim_unified/3 is the live
 * query that pulls the canonical gloss and one row per verified legacy edge.
 *
 * All five canonical commitment atoms exist as
 * literature_vocabulary:canonical_commitment/2 facts (defined in
 * literature_canonical_mappings.pl), so the literature gloss resolves live. The
 * cc/4 LocalGloss field records the human-readable local intent of the table,
 * but exported literature rows are proved only through
 * literature_vocabulary:canonical_commitment/2.
 *
 * Family slug: counting_claim. Bucket: counting_subitizing.
 */
:- module(cw_counting_claim,
          [ counting_claim_unified/3,    % counting_claim_unified(-Canonical, -Detail, -Source)
            counting_claim_witness/4,    % counting_claim_witness(?Canonical, ?Detail, ?Source, -Witness)
            claim_literature_atom/2,     % claim_literature_atom(?Canonical, ?LiteratureAtom)
            canonical_concept/2,         % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2          % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

:- use_module(misconceptions(literature_vocabulary), []).
:- use_module(strategies('math/action_automata_registry'), []).
:- use_module(standards('indiana/standard_k_ns_2'), []).
:- use_module(standards('indiana/standard_k_ns_4'), []).
:- use_module(formalization(grounded_arithmetic), []).
:- use_module(library(lists), [ member/2, append/2 ]).

%! cc(?Canonical, ?LiteratureAtom, ?LocalGloss, ?VerifiedEdges) is nondet.
%
%  The family table. Each row: the canonical counting/subitizing concept; the
%  canonical commitment anchor atom; a local gloss for reader orientation; and the
%  verified non-literature legacy functor strings that express the same concept.
cc(unit_coordination_cardinality,
   c_counting_cardinality_units,
   "Counting and cardinality require one-to-one unit coordination and stable counted units.",
   [ 'action_automata_registry:action_automaton_cluster/3(diagnostic_cardinality_by_bijective_counting)' ]).
cc(systematic_outcome_enumeration,
   c_combinatorial_systematic_counting,
   "Combinatorial counts require systematic enumeration of the stipulated outcome structure.",
   [ 'action_automata_registry:action_automaton_cluster/3(terminal_tree_endpoint_probability_sum)',
     'action_automata_registry:action_automaton_cluster/3(equiprobable_endpoint_counting)' ]).
cc(perceptual_pattern_quantity,
   c_subitizing_structured_quantity,
   "Structured arrangements present recognizable cardinal patterns, not only collections requiring serial unit counting.",
   [ 'standard_k_ns_4:subitize/2',
     'standard_k_ns_4:conceptual_subitize/3' ]).
cc(conventional_numeral_naming,
   c_conventional_number_word_sequence,
   "Counting follows the conventional stable number-word sequence, including its irregular teen and decade names.",
   [ 'standard_k_ns_2:numeral_known/2',
     'standard_k_ns_2:number_word/2' ]).
cc(successor_total_generation,
   c_successor_unbounded_sequence,
   "Every natural number has a successor, so the counting sequence is unbounded and has no largest number.",
   [ 'grounded_arithmetic:successor/2' ]).

%! claim_literature_atom(?Canonical, ?LiteratureAtom) is nondet.
%  The canonical commitment anchor atom for a counting concept.
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

%! counting_claim_unified(?Canonical, ?Detail, ?Source) is nondet.
%
%  Source = literature_commitment: Detail = commitment(Atom, Gloss) — the canonical
%  literature gloss for this concept's anchor atom.
%  Source = <legacy functor string>: Detail = edge(Functor) — one row per verified
%  non-literature surface that expresses the concept.
counting_claim_unified(Canonical, Detail, Source) :-
    counting_claim_witness(Canonical, Detail, Source, _).

%! counting_claim_witness(?Canonical, ?Detail, ?Source, -Witness) is nondet.
%
%  Witnessed form of `counting_claim_unified/3`. This is a closed-world finite
%  check over the loaded counting-claim table and the source predicates that own
%  each listed row. The table proposes alignments; this predicate succeeds only
%  when the owning source proves the referenced literature commitment, action
%  cluster, standard row, or grounded successor relation.
counting_claim_witness(
    Canonical,
    commitment(Lit, GlossS),
    literature_commitment,
    WitnessDict130) :-
    witness_dict:witness_dict(counting_claim_crosswalk, closed_world_finite_verified_counting_claim_edges,
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
                          gloss: GlossS } }, WitnessDict130),
    cc(Canonical, Lit, _, _),
    catch(literature_vocabulary:canonical_commitment(Lit, Gloss), _, fail),
    ( string(Gloss) -> GlossS = Gloss ; format(string(GlossS), "~w", [Gloss]) ).
counting_claim_witness(
    Canonical,
    edge(Functor),
    Functor,
    WitnessDict150) :-
    witness_dict:witness_dict(counting_claim_crosswalk, closed_world_finite_verified_counting_claim_edges,
                              _{canonical: Canonical,
       detail: edge(Functor),
       source: Functor,
       legacy_functor: Functor,
       projection: verified_legacy_edge,
       derivation: owner_predicate_edge_check,
       source_witness: SourceWitness }, WitnessDict150),
    cc(Canonical, _, _, Edges),
    member(Functor, Edges),
    counting_claim_edge_source_witness(Functor, SourceWitness).

counting_claim_edge_source_witness(
    'action_automata_registry:action_automaton_cluster/3(diagnostic_cardinality_by_bijective_counting)',
    _{ kind: action_automaton_cluster_edge,
       module: action_automata_registry,
       predicate: action_automaton_cluster/3,
       operation: diagnostic,
       action_kind: rigorous_counting_procedure,
       cluster: diagnostic_cardinality_by_bijective_counting,
       vocabulary: Vocabulary }) :-
    catch(action_automata_registry:action_automaton_cluster(
              diagnostic,
              rigorous_counting_procedure,
              diagnostic_cardinality_by_bijective_counting),
          _, fail),
    catch(action_automata_registry:action_automaton_vocabulary(
              diagnostic,
              rigorous_counting_procedure,
              Vocabulary),
          _, fail).
counting_claim_edge_source_witness(
    'action_automata_registry:action_automaton_cluster/3(terminal_tree_endpoint_probability_sum)',
    _{ kind: action_automaton_cluster_edge,
       module: action_automata_registry,
       predicate: action_automaton_cluster/3,
       operation: probability,
       action_kind: terminal_tree_endpoint_probability_sum,
       cluster: probability_weighted_terminal_tree,
       vocabulary: Vocabulary }) :-
    catch(action_automata_registry:action_automaton_cluster(
              probability,
              terminal_tree_endpoint_probability_sum,
              probability_weighted_terminal_tree),
          _, fail),
    catch(action_automata_registry:action_automaton_vocabulary(
              probability,
              terminal_tree_endpoint_probability_sum,
              Vocabulary),
          _, fail).
counting_claim_edge_source_witness(
    'action_automata_registry:action_automaton_cluster/3(equiprobable_endpoint_counting)',
    _{ kind: action_automaton_cluster_edge,
       module: action_automata_registry,
       predicate: action_automaton_cluster/3,
       operation: probability,
       action_kind: equiprobable_endpoint_counting,
       cluster: probability_weighted_terminal_tree,
       vocabulary: Vocabulary }) :-
    catch(action_automata_registry:action_automaton_cluster(
              probability,
              equiprobable_endpoint_counting,
              probability_weighted_terminal_tree),
          _, fail),
    catch(action_automata_registry:action_automaton_vocabulary(
              probability,
              equiprobable_endpoint_counting,
              Vocabulary),
          _, fail).
counting_claim_edge_source_witness(
    'standard_k_ns_4:subitize/2',
    _{ kind: indiana_standard_subitize_edge,
       module: standard_k_ns_4,
       predicate: subitize/2,
       sample_pattern: dice(5),
       count: Count,
       count_as_integer: IntegerCount,
       inference_policy: direct_pattern_recognition }) :-
    catch(standard_k_ns_4:subitize(dice(5), Count), _, fail),
    catch(grounded_arithmetic:recollection_to_integer(Count, IntegerCount), _, fail).
counting_claim_edge_source_witness(
    'standard_k_ns_4:conceptual_subitize/3',
    _{ kind: indiana_standard_conceptual_subitize_edge,
       module: standard_k_ns_4,
       predicate: conceptual_subitize/3,
       sample_pattern: domino(3, 2),
       count: Count,
       count_as_integer: IntegerCount,
       decomposition: Decomposition }) :-
    catch(standard_k_ns_4:conceptual_subitize(domino(3, 2), Count, Decomposition),
          _, fail),
    catch(grounded_arithmetic:recollection_to_integer(Count, IntegerCount), _, fail).
counting_claim_edge_source_witness(
    'standard_k_ns_2:numeral_known/2',
    _{ kind: indiana_standard_numeral_known_edge,
       module: standard_k_ns_2,
       predicate: numeral_known/2,
       sample_integer: 13,
       sample_recollection: Recollection,
       numeral: thirteen,
       setup_policy: bounded_curriculum_setup_teach_numerals_to_20_state_preserved }) :-
    catch(grounded_arithmetic:integer_to_recollection(13, Recollection), _, fail),
    with_preserved_numerals(
        ( standard_k_ns_2:teach_numerals_to(20),
          standard_k_ns_2:numeral_known(Recollection, thirteen)
        )).
counting_claim_edge_source_witness(
    'standard_k_ns_2:number_word/2',
    _{ kind: indiana_standard_number_word_edge,
       module: standard_k_ns_2,
       predicate: number_word/2,
       sample_integer: 13,
       word: thirteen }) :-
    catch(standard_k_ns_2:number_word(13, thirteen), _, fail).
counting_claim_edge_source_witness(
    'grounded_arithmetic:successor/2',
    _{ kind: grounded_successor_edge,
       module: grounded_arithmetic,
       predicate: successor/2,
       from: Zero,
       to: One,
       from_integer: 0,
       to_integer: 1,
       derivation: embodied_successor_adds_one_tally }) :-
    catch(grounded_arithmetic:zero(Zero), _, fail),
    catch(grounded_arithmetic:successor(Zero, One), _, fail),
    catch(grounded_arithmetic:recollection_to_integer(One, 1), _, fail).

with_preserved_numerals(Goal) :-
    findall(R-N, standard_k_ns_2:numeral_known(R, N), Snapshot),
    setup_call_cleanup(
        standard_k_ns_2:reset_numerals,
        once(Goal),
        restore_numerals(Snapshot)).

restore_numerals(Snapshot) :-
    standard_k_ns_2:reset_numerals,
    forall(member(R-N, Snapshot),
           assertz(standard_k_ns_2:numeral_known(R, N))).
