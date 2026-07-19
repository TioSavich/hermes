/** <module> cw_multiplication_division_claim — canonical crosswalk family for the
 *  multiplication_division bucket
 *
 * Six literature commitments in this bucket have cross-surface presence: each is
 * stated as a literature canonical_commitment atom AND expressed by real,
 * verified non-literature legacy functors elsewhere in the repo. That dual
 * residence is what earns each a crosswalk home; a literature-only commitment is
 * already in one place and is not promoted here.
 *
 *   - equal_groups_composite_unit (c_equal_groups_equal_size): multiplication as
 *     coordinated equal groups, each carrying a composite unit. Verified clusters:
 *     action_automaton_cluster(multiplication, coordinate_groups_items, _) and
 *     action_automaton_cluster(multiplication, repeat_equal_groups, _).
 *
 *   - fair_share_partition_grouping (c_equal_sharing_partition_model): division as
 *     equal sharing tied to the partition model. Verified cluster:
 *     action_automaton_cluster(division, fair_share_equal_groups, _).
 *
 *   - division_quotient_remainder_coordination (c_division_structure_and_remainder):
 *     division coordinates total, group size, quotient and remainder. Verified:
 *     action_automaton_cluster(division, share_into_divisor_groups, _) and the
 *     vocabulary action_automaton_vocabulary(division, measure_groups_of_size, _).
 *
 *   - division_by_zero_undefined_deontic (c_division_by_zero_undefined): division
 *     by zero is undefined, and the numerical deformation that returns 0 is
 *     deontically incompatible with that entitlement. Verified:
 *     misconception_registry:incompatibility_with(division_by_zero_numerical, _).
 *
 *   - partial_product_not_additive_reduction (c_multiplicative_structure_not_additive):
 *     multiplicative structure (partial products) is not reducible to additive
 *     combination. Verified: the productive vocabulary
 *     action_automaton_vocabulary(multiplication, distribute_group_size_split, _)
 *     and the additive-reduction deformation cluster
 *     action_automaton_cluster(multiplication, add_counts_without_composite_unit, _).
 *
 *   - number_factor_multiple_structure (c_number_multiplicative_structure): a
 *     whole number is characterized by its factor/multiple structure, not parity.
 *     Verified in the number-theory axioms (loaded via the sequent engine):
 *     is_prime/1 and find_prime_factor/2.
 *
 * Same shape as the other crosswalk families: it RENAMES nothing and OWNS no
 * facts — vocabulary_source/2 is the contract the aggregator (canonical_all)
 * ranges over, canonical_concept/2 is the reverse map, and
 * multiplication_division_claim_unified/3 is the live query that pulls the
 * literature gloss and one row per verified edge per canonical term.
 *
 * Family slug: multiplication_division_claim.
 */
:- module(cw_multiplication_division_claim,
          [ multiplication_division_claim_unified/3, % (-Canonical, -Detail, -Source)
            multiplication_division_claim_witness/4, % (?Canonical, ?Detail, ?Source, -Witness)
            claim_literature_atom/2,                 % (?Canonical, ?LiteratureAtom)
            canonical_concept/2,                     % (?LegacyFunctor, ?Canonical)
            vocabulary_source/2                      % (?Canonical, ?ListOfLegacyFunctors)
          ]).

:- use_module(misconceptions(literature_vocabulary), []).
:- use_module(misconceptions(misconception_registry), []).
:- use_module(strategies('math/action_automata_registry'), []).
:- use_module(arche_trace(sequent_engine), []).
:- use_module(library(lists), [ member/2, append/2 ]).

%! md(?Canonical, ?LiteratureAtom, ?VerifiedEdges) is nondet.
%
%  The family table. Each row: the canonical concept; the real literature
%  canonical_commitment atom (verified present); and the list of verified
%  non-literature legacy edges. Each edge is edge(Surface, FunctorString) where
%  Surface is the structured surface tag carried on the unified query and
%  FunctorString is the rendered 'Module:Functor/Arity(args)' provenance atom,
%  taken verbatim from the owning module.
md(equal_groups_composite_unit,
   c_equal_groups_equal_size,
   [ edge(cluster(multiplication, coordinate_groups_items),
          'action_automata_registry:action_automaton_cluster/3(multiplication,coordinate_groups_items)'),
     edge(cluster(multiplication, repeat_equal_groups),
          'action_automata_registry:action_automaton_cluster/3(multiplication,repeat_equal_groups)') ]).
md(fair_share_partition_grouping,
   c_equal_sharing_partition_model,
   [ edge(cluster(division, fair_share_equal_groups),
          'action_automata_registry:action_automaton_cluster/3(division,fair_share_equal_groups)') ]).
md(division_quotient_remainder_coordination,
   c_division_structure_and_remainder,
   [ edge(cluster(division, share_into_divisor_groups),
          'action_automata_registry:action_automaton_cluster/3(division,share_into_divisor_groups)'),
     edge(vocabulary(division, measure_groups_of_size),
          'action_automata_registry:action_automaton_vocabulary/3(division,measure_groups_of_size)') ]).
md(division_by_zero_undefined_deontic,
   c_division_by_zero_undefined,
   [ edge(incompatibility(division_by_zero_numerical),
          'misconception_registry:incompatibility_with/2(division_by_zero_numerical)') ]).
md(partial_product_not_additive_reduction,
   c_multiplicative_structure_not_additive,
   [ edge(vocabulary(multiplication, distribute_group_size_split),
          'action_automata_registry:action_automaton_vocabulary/3(multiplication,distribute_group_size_split)'),
     edge(cluster(multiplication, add_counts_without_composite_unit),
          'action_automata_registry:action_automaton_cluster/3(multiplication,add_counts_without_composite_unit)') ]).
md(number_factor_multiple_structure,
   c_number_multiplicative_structure,
   [ edge(is_prime,
          'formalization/axioms_number_theory:is_prime/1'),
     edge(find_prime_factor,
          'formalization/axioms_number_theory:find_prime_factor/2') ]).

%! claim_literature_atom(?Canonical, ?LiteratureAtom) is nondet.
%  The literature commitment atom a canonical concept resolves to.
claim_literature_atom(Canonical, LitAtom) :- md(Canonical, LitAtom, _).

% The legacy functor strings for a canonical term: literature commitment atom
% first, then one functor per verified edge.
legacy_list(Canonical, Legacies) :-
    md(Canonical, Lit, Edges),
    atomic_list_concat(['literature_vocabulary:canonical_commitment/2(', Lit, ')'], LitFunctor),
    findall(F, member(edge(_, F), Edges), EdgeFunctors),
    append([[LitFunctor], EdgeFunctors], Legacies).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(Canonical, Legacies) :- legacy_list(Canonical, Legacies).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
canonical_concept(Legacy, Canonical) :-
    legacy_list(Canonical, Legacies),
    member(Legacy, Legacies).

%! multiplication_division_claim_unified(-Canonical, -Detail, -Source) is nondet.
%
%  Source = literature_commitment: Detail = commitment(Atom, Gloss) — the real
%  canonical_commitment gloss for this concept's literature atom.
%  Source = the verified surface functor string: Detail = edge(Surface) — one row
%  per verified non-literature legacy edge.
multiplication_division_claim_unified(Canonical, commitment(Lit, GlossS), literature_commitment) :-
    multiplication_division_claim_witness(Canonical,
                                          commitment(Lit, GlossS),
                                          literature_commitment,
                                          _).
multiplication_division_claim_unified(Canonical, edge(Surface), Functor) :-
    multiplication_division_claim_witness(Canonical, edge(Surface), Functor, _).

%! multiplication_division_claim_witness(?Canonical, ?Detail, ?Source, -Witness) is nondet.
%
%  Witnessed form of `multiplication_division_claim_unified/3`. This is a
%  closed-world finite check over the loaded multiplication/division claim table
%  and the source predicates that own each listed row. The table proposes
%  alignments; this predicate succeeds only when the owning source proves the
%  referenced literature commitment, action cluster, action vocabulary,
%  misconception incompatibility, or number-theory witness.
multiplication_division_claim_witness(
    Canonical,
    commitment(Lit, GlossS),
    literature_commitment,
    WitnessDict150) :-
    witness_dict:witness_dict(multiplication_division_claim_crosswalk, closed_world_finite_verified_multiplication_division_claim_edges,
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
                          gloss: GlossS } }, WitnessDict150),
    md(Canonical, Lit, _),
    catch(literature_vocabulary:canonical_commitment(Lit, Gloss), _, fail),
    ( string(Gloss) -> GlossS = Gloss ; format(string(GlossS), "~w", [Gloss]) ).
multiplication_division_claim_witness(
    Canonical,
    edge(Surface),
    Functor,
    WitnessDict170) :-
    witness_dict:witness_dict(multiplication_division_claim_crosswalk, closed_world_finite_verified_multiplication_division_claim_edges,
                              _{canonical: Canonical,
       detail: edge(Surface),
       source: Functor,
       legacy_functor: Functor,
       projection: verified_legacy_edge,
       derivation: owner_predicate_edge_check,
       source_witness: SourceWitness }, WitnessDict170),
    md(Canonical, _, Edges),
    member(edge(Surface, Functor), Edges),
    multiplication_division_edge_source_witness(Surface, SourceWitness).

multiplication_division_edge_source_witness(
    cluster(Operation, ActionKind),
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
multiplication_division_edge_source_witness(
    vocabulary(Operation, ActionKind),
    _{ kind: action_automaton_vocabulary_edge,
       module: action_automata_registry,
       predicate: action_automaton_vocabulary/3,
       operation: Operation,
       action_kind: ActionKind,
       vocabulary: Vocabulary }) :-
    catch(action_automata_registry:action_automaton_vocabulary(Operation, ActionKind, Vocabulary),
          _, fail).
multiplication_division_edge_source_witness(
    incompatibility(division_by_zero_numerical),
    _{ kind: misconception_registry_incompatibility_edge,
       module: misconception_registry,
       predicate: incompatibility_with/2,
       move: division_by_zero_numerical,
       conflict: Conflict,
       incompatibility_witness: IncompatibilityWitness }) :-
    catch(once(misconception_registry:incompatibility_with_witness(
                   division_by_zero_numerical,
                   Conflict,
                   IncompatibilityWitness)),
          _, fail).
multiplication_division_edge_source_witness(
    is_prime,
    _{ kind: number_theory_prime_case_edge,
       module: sequent_engine,
       source_file: 'formalization/axioms_number_theory.pl',
       legacy_predicate: is_prime/1,
       sample_list: [2, 3, 5],
       sample_prime: Prime,
       prime_fact: PrimeFact,
       number_theory_witness: NumberTheoryWitness }) :-
    catch(sequent_engine:number_theory_self_defeat_witness([2, 3, 5], NumberTheoryWitness),
          _, fail),
    Prime = NumberTheoryWitness.prime_case.prime,
    PrimeFact = NumberTheoryWitness.prime_case.prime_fact.
multiplication_division_edge_source_witness(
    find_prime_factor,
    _{ kind: number_theory_factor_edge,
       module: sequent_engine,
       source_file: 'formalization/axioms_number_theory.pl',
       legacy_predicate: find_prime_factor/2,
       sample_integer: 111,
       sample_list: [2, 5, 11],
       prime_factor: Factor,
       divides: Divides,
       number_theory_witness: NumberTheoryWitness }) :-
    catch(sequent_engine:number_theory_factor_witness(111, [2, 5, 11], NumberTheoryWitness),
          _, fail),
    Factor = NumberTheoryWitness.prime_factor,
    Divides = NumberTheoryWitness.divides.
