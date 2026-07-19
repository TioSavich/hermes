/** <module> cw_place_value_number_claim — canonical crosswalk family for the
 *  place-value / whole-number CLAIM concepts (bucket: place_value_number)
 *
 * Companion to cw_fraction_claim. Five literature commitments about base-ten
 * place value, regrouping, base-parameterized positional arithmetic, and
 * estimation/rounding were resolvable only as raw `c_*` commitment atoms. Each
 * one, however, also has a REAL non-literature surface that expresses the same
 * concept — an action-automaton cluster, a grounded_arithmetic predicate, or the
 * CGI base parameter. That cross-surface presence is what earns each a crosswalk
 * home here; a literature-only commitment would mint a dead term and is not
 * promoted.
 *
 * Same shape as the other crosswalk families: it RENAMES nothing and OWNS no
 * facts. vocabulary_source/2 is the contract the aggregator (canonical_all)
 * ranges over, canonical_concept/2 is the reverse map, and
 * whole_number_claim_unified/3 is the live query that pulls the literature gloss
 * and one row per verified surface for each canonical term.
 *
 * Family slug: place_value_number.
 *
 * Every legacy edge recorded below was loaded and queried before promotion:
 *   - action_automaton_cluster(addition, column_addition_with_carrying, additive_column_algorithm)
 *   - action_automaton_cluster(addition, base_ones_chunking, additive_strategy_fluency)
 *   - action_automaton_cluster(multiplication, regroup_to_base_preserving_total, multiplicative_composite_units)
 *   - action_automaton_cluster(subtraction, decompose_base_for_ones, subtractive_strategy_fluency)
 *   - action_automaton_cluster(addition, round_then_adjust, additive_strategy_fluency)
 *   - grounded_arithmetic:leading_digit_chunk(234,10,200)
 *   - grounded_arithmetic:leading_place_value(234,10,100) ; leading_place_value(234,8,64)
 *   - cgi_base:set_cgi_base(8) -> current_cgi_base(8)
 */
:- module(cw_place_value_number_claim,
          [ whole_number_claim_unified/3, % whole_number_claim_unified(-Canonical, -Detail, -Source)
            place_value_number_claim_witness/4, % place_value_number_claim_witness(?Canonical, ?Detail, ?Source, -Witness)
            claim_literature_atom/2,       % claim_literature_atom(?Canonical, ?LiteratureAtom)
            canonical_concept/2,           % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2            % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

:- use_module(misconceptions(literature_vocabulary), []).
:- use_module(strategies('math/action_automata_registry'), []).
:- use_module(strategies('math/cgi_base'), []).
:- use_module(formalization(grounded_arithmetic), []).
:- use_module(library(lists), [ member/2 ]).

%! pv(?Canonical, ?LiteratureAtom, ?Surfaces) is nondet.
%
%  The family table. Each row: the canonical place-value claim concept; the real
%  literature canonical_commitment atom (verified present); and the list of
%  verified non-literature surfaces, each as a pair surface(Functor, Detail)
%  where Functor is the 'Module:Name/Arity'-style legacy atom and Detail is a
%  short ground description of the queried edge.
pv(base_ten_composite_unit_arithmetic,
   c_base_ten_composite_units,
   [ surface('action_automata_registry:action_automaton_cluster/3(addition,column_addition_with_carrying)',
             cluster(additive_column_algorithm)),
     surface('action_automata_registry:action_automaton_cluster/3(addition,base_ones_chunking)',
             cluster(additive_strategy_fluency)),
     surface('grounded_arithmetic:leading_digit_chunk/3',
             example('leading_digit_chunk(234,10,200)')) ]).

pv(place_value_regrouping_conservation,
   c_base_ten_place_value_regrouping,
   [ surface('action_automata_registry:action_automaton_cluster/3(addition,column_addition_with_carrying)',
             cluster(additive_column_algorithm)),
     surface('action_automata_registry:action_automaton_cluster/3(multiplication,regroup_to_base_preserving_total)',
             cluster(multiplicative_composite_units)),
     surface('action_automata_registry:action_automaton_cluster/3(subtraction,decompose_base_for_ones)',
             cluster(subtractive_strategy_fluency)) ]).

pv(base_parameterized_positional_arithmetic,
   c_positional_arithmetic_any_base,
   [ surface('grounded_arithmetic:leading_place_value/3',
             example('leading_place_value(234,10,100) ; leading_place_value(234,8,64)')),
     surface('cgi_base:set_cgi_base/1',
             example('set_cgi_base(8) -> current_cgi_base(8)')) ]).

pv(rounding_compensation_reasonableness,
   c_estimation_rounding_reasonableness,
   [ surface('action_automata_registry:action_automaton_pair/4(addition,round_then_adjust)',
             pair(deformation(round_without_adjusting), invariant(rounding_without_compensation))),
     surface('action_automata_registry:action_automaton_vocabulary/3(addition,round_then_adjust)',
             vocabulary([rounding_target,base,adjustment,temporary_sum,conservation])) ]).

pv(approximate_operand_before_computing,
   c_estimation_approximate_before_computing,
   [ surface('action_automata_registry:action_automaton_cluster/3(addition,round_then_adjust)',
             cluster(additive_strategy_fluency)) ]).

%! claim_literature_atom(?Canonical, ?LiteratureAtom) is nondet.
%  The literature commitment atom a canonical claim concept resolves to.
claim_literature_atom(Canonical, LitAtom) :- pv(Canonical, LitAtom, _).

% The legacy functor strings for a canonical term: the literature commitment
% functor plus each verified surface functor, all as 'Module:Functor/Arity'
% style atoms (matching the convention used by the other families).
legacy_list(Canonical, [LitFunctor | SurfaceFunctors]) :-
    pv(Canonical, Lit, Surfaces),
    atomic_list_concat(['literature_vocabulary:canonical_commitment/2(', Lit, ')'], LitFunctor),
    findall(F, member(surface(F, _), Surfaces), SurfaceFunctors).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(Canonical, Legacies) :- legacy_list(Canonical, Legacies).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
canonical_concept(Legacy, Canonical) :-
    legacy_list(Canonical, Legacies),
    member(Legacy, Legacies).

%! whole_number_claim_unified(?Canonical, ?Detail, ?Source) is nondet.
%
%  Source = literature_commitment: Detail = commitment(Atom, Gloss) — the real
%  canonical_commitment gloss for this concept's literature atom.
%  Source = <surface functor atom>: Detail = surface(GroundDetail) — one row per
%  verified non-literature surface that expresses the concept.
whole_number_claim_unified(Canonical, Detail, Source) :-
    place_value_number_claim_witness(Canonical, Detail, Source, _).

%! place_value_number_claim_witness(?Canonical, ?Detail, ?Source, -Witness) is nondet.
%
%  Witnessed form of `whole_number_claim_unified/3` for the place-value number
%  claim family. This is a closed-world finite check over the loaded
%  place-value claim table and the source predicates that own each listed row.
%  The table proposes alignments; this predicate succeeds only when the owning
%  source proves the referenced literature commitment, action-automaton row,
%  grounded-arithmetic example, or scoped CGI base configuration.
place_value_number_claim_witness(
    Canonical,
    commitment(Lit, GlossS),
    literature_commitment,
    WitnessDict130) :-
    witness_dict:witness_dict(place_value_number_claim_crosswalk, closed_world_finite_verified_place_value_number_claim_edges,
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
    pv(Canonical, Lit, _),
    catch(literature_vocabulary:canonical_commitment(Lit, Gloss), _, fail),
    ( string(Gloss) -> GlossS = Gloss ; format(string(GlossS), "~w", [Gloss]) ).
place_value_number_claim_witness(
    Canonical,
    surface(Detail),
    Source,
    WitnessDict150) :-
    witness_dict:witness_dict(place_value_number_claim_crosswalk, closed_world_finite_verified_place_value_number_claim_edges,
                              _{canonical: Canonical,
       detail: surface(Detail),
       source: Source,
       legacy_functor: Source,
       projection: verified_legacy_surface,
       derivation: owner_predicate_surface_check,
       source_witness: SourceWitness }, WitnessDict150),
    pv(Canonical, _, Surfaces),
    member(surface(Source, Detail), Surfaces),
    place_value_surface_witness(Source, Detail, SourceWitness).

place_value_surface_witness(
    'action_automata_registry:action_automaton_cluster/3(addition,column_addition_with_carrying)',
    cluster(additive_column_algorithm),
    SourceWitness) :-
    action_cluster_witness(addition,
                           column_addition_with_carrying,
                           additive_column_algorithm,
                           SourceWitness).
place_value_surface_witness(
    'action_automata_registry:action_automaton_cluster/3(addition,base_ones_chunking)',
    cluster(additive_strategy_fluency),
    SourceWitness) :-
    action_cluster_witness(addition,
                           base_ones_chunking,
                           additive_strategy_fluency,
                           SourceWitness).
place_value_surface_witness(
    'action_automata_registry:action_automaton_cluster/3(multiplication,regroup_to_base_preserving_total)',
    cluster(multiplicative_composite_units),
    SourceWitness) :-
    action_cluster_witness(multiplication,
                           regroup_to_base_preserving_total,
                           multiplicative_composite_units,
                           SourceWitness).
place_value_surface_witness(
    'action_automata_registry:action_automaton_cluster/3(subtraction,decompose_base_for_ones)',
    cluster(subtractive_strategy_fluency),
    SourceWitness) :-
    action_cluster_witness(subtraction,
                           decompose_base_for_ones,
                           subtractive_strategy_fluency,
                           SourceWitness).
place_value_surface_witness(
    'action_automata_registry:action_automaton_cluster/3(addition,round_then_adjust)',
    cluster(additive_strategy_fluency),
    SourceWitness) :-
    action_cluster_witness(addition,
                           round_then_adjust,
                           additive_strategy_fluency,
                           SourceWitness).
place_value_surface_witness(
    'action_automata_registry:action_automaton_pair/4(addition,round_then_adjust)',
    pair(deformation(round_without_adjusting),
         invariant(rounding_without_compensation)),
    _{ kind: action_automaton_pair_edge,
       module: action_automata_registry,
       predicate: action_automaton_pair/4,
       operation: addition,
       productive_kind: round_then_adjust,
       deformation_kind: round_without_adjusting,
       family: rounding_without_compensation }) :-
    catch(action_automata_registry:action_automaton_pair(
              addition,
              round_then_adjust,
              round_without_adjusting,
              rounding_without_compensation),
          _, fail).
place_value_surface_witness(
    'action_automata_registry:action_automaton_vocabulary/3(addition,round_then_adjust)',
    vocabulary(Vocabulary),
    _{ kind: action_automaton_vocabulary_edge,
       module: action_automata_registry,
       predicate: action_automaton_vocabulary/3,
       operation: addition,
       action_kind: round_then_adjust,
       vocabulary: Vocabulary }) :-
    catch(action_automata_registry:action_automaton_vocabulary(
              addition,
              round_then_adjust,
              Vocabulary),
          _, fail).
place_value_surface_witness(
    'grounded_arithmetic:leading_digit_chunk/3',
    example('leading_digit_chunk(234,10,200)'),
    _{ kind: grounded_arithmetic_example,
       module: grounded_arithmetic,
       predicate: leading_digit_chunk/3,
       input: _{ n: 234, base: 10 },
       chunk: 200,
       supporting_place_value: PlaceValue }) :-
    catch(grounded_arithmetic:leading_digit_chunk(234, 10, 200), _, fail),
    catch(grounded_arithmetic:leading_place_value(234, 10, PlaceValue), _, fail).
place_value_surface_witness(
    'grounded_arithmetic:leading_place_value/3',
    example('leading_place_value(234,10,100) ; leading_place_value(234,8,64)'),
    _{ kind: grounded_arithmetic_examples,
       module: grounded_arithmetic,
       predicate: leading_place_value/3,
       examples: [ _{ input: _{ n: 234, base: 10 },
                      place_value: 100 },
                   _{ input: _{ n: 234, base: 8 },
                      place_value: 64 } ] }) :-
    catch(grounded_arithmetic:leading_place_value(234, 10, 100), _, fail),
    catch(grounded_arithmetic:leading_place_value(234, 8, 64), _, fail).
place_value_surface_witness(
    'cgi_base:set_cgi_base/1',
    example('set_cgi_base(8) -> current_cgi_base(8)'),
    _{ kind: scoped_cgi_base_configuration,
       module: cgi_base,
       setup_predicate: set_cgi_base/1,
       read_predicate: current_cgi_base/1,
       configured_base: 8,
       observed_base: 8,
       cleanup: reset_cgi_base }) :-
    catch(setup_call_cleanup(cgi_base:set_cgi_base(8),
                             cgi_base:current_cgi_base(8),
                             cgi_base:reset_cgi_base),
          _, fail).

action_cluster_witness(
    Operation,
    ActionKind,
    ExpectedCluster,
    _{ kind: action_automaton_cluster_edge,
       module: action_automata_registry,
       predicate: action_automaton_cluster/3,
       operation: Operation,
       action_kind: ActionKind,
       cluster: ExpectedCluster,
       vocabulary: Vocabulary }) :-
    catch(action_automata_registry:action_automaton_cluster(
              Operation,
              ActionKind,
              ExpectedCluster),
          _, fail),
    catch(action_automata_registry:action_automaton_vocabulary(
              Operation,
              ActionKind,
              Vocabulary),
          _, fail).
