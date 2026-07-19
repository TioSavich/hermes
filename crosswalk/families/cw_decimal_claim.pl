/** <module> cw_decimal_claim — canonical crosswalk family for decimal CLAIM concepts
 *
 * Bucket: decimal. Five literature commitments about decimal place value each
 * earn a crosswalk home because each has verified cross-surface presence — a
 * real, existing non-literature legacy functor expresses the same concept:
 *
 *   decimal_place_value_alignment_in_column_arithmetic
 *     (c_decimal_place_value_alignment)
 *     - three registered misconception incompatibilities for column-arithmetic
 *       deformations (ragged addition, no borrow across the point, summing
 *       decimal places while ignoring trailing zeros).
 *
 *   decimal_magnitude_ordered_by_place_value
 *     (c_decimal_place_value_ordering)
 *     - two registered misconception incompatibilities for ordering deformations
 *       (longer-is-larger, natural-number ordering of the decimal tail).
 *
 *   decimal_point_as_place_value_locator
 *     (c_decimal_positional_notation)
 *     - two decimal action-automaton clusters that read the point positionally
 *       (positional_decimal_reading, decimal_whole_number_reading),
 *     - two registered misconception incompatibilities (point-as-separator,
 *       decimal-part-as-integer).
 *
 *   decimal_trailing_zero_value_invariance
 *     (c_decimal_trailing_zero_invariance)
 *     - two registered misconception incompatibilities (trailing zeros increase
 *       value; summing decimal places while ignoring trailing zeros).
 *
 *   positive_decimal_greater_than_zero
 *     (c_positive_decimal_exceeds_zero)
 *     - two registered misconception incompatibilities (zero larger than a
 *       decimal; decimals are negative).
 *
 * Same shape as the other crosswalk families (see cw_integer_signed_claim): it
 * RENAMES nothing and OWNS no facts. vocabulary_source/2 is the contract the
 * aggregator (canonical_all) ranges over; canonical_concept/2 is the reverse
 * map; decimal_claim_unified/3 is the live query that pulls the literature gloss
 * plus one row per verified legacy edge.
 *
 * Every legacy edge recorded here was loaded and queried against the live system
 * before promotion. Edges flagged unverified upstream are NOT recorded.
 *
 * Family slug: decimal_claim.
 */
:- module(cw_decimal_claim,
          [ decimal_claim_unified/3,  % decimal_claim_unified(-Canonical, -Detail, -Source)
            decimal_claim_witness/4,  % decimal_claim_witness(?Canonical, ?Detail, ?Source, -Witness)
            claim_literature_atom/2,  % claim_literature_atom(?Canonical, ?LiteratureAtom)
            canonical_concept/2,      % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2       % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

:- use_module(misconceptions(literature_vocabulary), []).
:- use_module(misconceptions(misconception_registry), []).
:- use_module(strategies('math/action_automata_registry'), []).
:- use_module(library(lists), [ member/2 ]).

%! dc(?Canonical, ?LiteratureAtom, ?Edges) is nondet.
%
%  The family table. Each row: the canonical decimal concept; the real
%  literature canonical_commitment atom (verified present); and the list of
%  verified non-literature legacy edges that express the same concept. Each
%  edge is edge(Functor, Surface): Functor is the 'Module:Name/Arity(args)'
%  identifier string, Surface is the human-readable gloss of that edge.
dc(decimal_place_value_alignment_in_column_arithmetic,
   c_decimal_place_value_alignment,
   [ edge('misconception_registry:incompatibility_with/2(ragged_decimal_addition)',
          "Registered misconception: adding decimals right-aligned (ragged) rather than aligning on the point violates place-value alignment in column arithmetic."),
     edge('misconception_registry:incompatibility_with/2(no_borrow_across_point)',
          "Registered misconception: refusing to borrow across the decimal point violates place-value alignment in column subtraction."),
     edge('misconception_registry:incompatibility_with/2(sum_dp_ignoring_trailing_zeros)',
          "Registered misconception: summing decimal places while ignoring trailing zeros violates place-value alignment in column arithmetic.")
   ]).
dc(decimal_magnitude_ordered_by_place_value,
   c_decimal_place_value_ordering,
   [ edge('misconception_registry:incompatibility_with/2(longer_is_larger_ordering)',
          "Registered misconception: ordering decimals by digit count (longer is larger) violates place-value ordering of magnitude."),
     edge('misconception_registry:incompatibility_with/2(natural_number_ordering)',
          "Registered misconception: ordering the decimal tail as a whole number violates place-value ordering of magnitude.")
   ]).
dc(decimal_point_as_place_value_locator,
   c_decimal_positional_notation,
   [ edge('action_automata_registry:action_automaton_cluster/3(decimal,positional_decimal_reading)',
          "Decimal action automaton that reads the point as locating place-value units (positional reading)."),
     edge('action_automata_registry:action_automaton_cluster/3(decimal,decimal_whole_number_reading)',
          "Decimal action automaton that coordinates the whole-number and fractional sides across the point as one positional notation."),
     edge('misconception_registry:incompatibility_with/2(decimal_point_as_separator)',
          "Registered misconception: treating the point as separating two independent whole numbers violates the point-as-place-value-locator commitment."),
     edge('misconception_registry:incompatibility_with/2(decimal_part_as_integer)',
          "Registered misconception: reading the decimal part as an integer violates the point-as-place-value-locator commitment.")
   ]).
dc(decimal_trailing_zero_value_invariance,
   c_decimal_trailing_zero_invariance,
   [ edge('misconception_registry:incompatibility_with/2(trailing_zeros_increase_value)',
          "Registered misconception: treating trailing zeros as increasing value violates trailing-zero value invariance."),
     edge('misconception_registry:incompatibility_with/2(sum_dp_ignoring_trailing_zeros)',
          "Registered misconception: summing decimal places while ignoring trailing zeros violates trailing-zero value invariance.")
   ]).
dc(positive_decimal_greater_than_zero,
   c_positive_decimal_exceeds_zero,
   [ edge('misconception_registry:incompatibility_with/2(zero_larger_than_decimal)',
          "Registered misconception: judging zero larger than a positive decimal violates 'a positive decimal is greater than zero'."),
     edge('misconception_registry:incompatibility_with/2(decimals_are_negative)',
          "Registered misconception: treating decimals as negative violates 'a positive decimal is greater than zero'.")
   ]).

%! claim_literature_atom(?Canonical, ?LiteratureAtom) is nondet.
%  The literature commitment atom a canonical decimal concept resolves to.
claim_literature_atom(Canonical, LitAtom) :- dc(Canonical, LitAtom, _).

% The legacy functor strings for a canonical term: the literature commitment
% functor plus each verified edge functor, all as 'Module:Name/Arity(args)'
% style atoms (matching the convention used by the other families).
legacy_list(Canonical, [LitFunctor | EdgeFunctors]) :-
    dc(Canonical, Lit, Edges),
    atomic_list_concat(['literature_vocabulary:canonical_commitment/2(', Lit, ')'], LitFunctor),
    findall(F, member(edge(F, _), Edges), EdgeFunctors).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(Canonical, Legacies) :- legacy_list(Canonical, Legacies).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
canonical_concept(Legacy, Canonical) :-
    legacy_list(Canonical, Legacies),
    member(Legacy, Legacies).

%! decimal_claim_unified(?Canonical, ?Detail, ?Source) is nondet.
%
%  Source = literature_commitment: Detail = commitment(Atom, Gloss) — the real
%  canonical_commitment gloss for this concept's literature atom.
%  Source = <edge functor string>: Detail = edge_surface(Surface) — one row per
%  verified non-literature legacy edge that expresses the concept.
decimal_claim_unified(Canonical, Detail, Source) :-
    decimal_claim_witness(Canonical, Detail, Source, _).

%! decimal_claim_witness(?Canonical, ?Detail, ?Source, -Witness) is nondet.
%
%  Witnessed form of `decimal_claim_unified/3`. This is a closed-world finite
%  check over the loaded decimal-claim table and the source predicates that own
%  each listed row. The table proposes alignments; this predicate succeeds only
%  when the owning source proves the referenced literature commitment, action
%  cluster, action vocabulary, or misconception-registry incompatibility.
decimal_claim_witness(
    Canonical,
    commitment(Lit, GlossS),
    literature_commitment,
    WitnessDict148) :-
    witness_dict:witness_dict(decimal_claim_crosswalk, closed_world_finite_verified_decimal_claim_edges,
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
                          gloss: GlossS } }, WitnessDict148),
    dc(Canonical, Lit, _),
    catch(literature_vocabulary:canonical_commitment(Lit, Gloss), _, fail),
    ( string(Gloss) -> GlossS = Gloss ; format(string(GlossS), "~w", [Gloss]) ).
decimal_claim_witness(
    Canonical,
    edge_surface(Surface),
    Functor,
    WitnessDict168) :-
    witness_dict:witness_dict(decimal_claim_crosswalk, closed_world_finite_verified_decimal_claim_edges,
                              _{canonical: Canonical,
       detail: edge_surface(Surface),
       source: Functor,
       legacy_functor: Functor,
       projection: verified_legacy_edge_surface,
       derivation: owner_predicate_edge_check,
       source_witness: SourceWitness }, WitnessDict168),
    dc(Canonical, _, Edges),
    member(edge(Functor, Surface), Edges),
    decimal_edge_source_witness(Functor, SourceWitness).

decimal_edge_source_witness(
    'action_automata_registry:action_automaton_cluster/3(decimal,positional_decimal_reading)',
    SourceWitness) :-
    decimal_action_cluster_witness(positional_decimal_reading, SourceWitness).
decimal_edge_source_witness(
    'action_automata_registry:action_automaton_cluster/3(decimal,decimal_whole_number_reading)',
    SourceWitness) :-
    decimal_action_cluster_witness(decimal_whole_number_reading, SourceWitness).
decimal_edge_source_witness(Functor, SourceWitness) :-
    decimal_registry_functor(Functor, Move),
    decimal_registry_incompatibility_witness(Move, SourceWitness).

decimal_action_cluster_witness(
    ActionKind,
    _{ kind: action_automaton_cluster_edge,
       module: action_automata_registry,
       predicate: action_automaton_cluster/3,
       operation: decimal,
       action_kind: ActionKind,
       cluster: Cluster,
       vocabulary: Vocabulary }) :-
    catch(action_automata_registry:action_automaton_cluster(decimal, ActionKind, Cluster),
          _, fail),
    catch(action_automata_registry:action_automaton_vocabulary(decimal, ActionKind, Vocabulary),
          _, fail).

decimal_registry_incompatibility_witness(
    Move,
    _{ kind: misconception_registry_incompatibility_edge,
       module: misconception_registry,
       predicate: incompatibility_with/2,
       move: Move,
       conflict: Conflict,
       incompatibility_witness: IncompatibilityWitness }) :-
    catch(once(decimal_registry_conflict(Move, Conflict,
                                         IncompatibilityWitness)),
          _, fail).

% The registry's harness-backed clauses confirm an incompatibility only when
% the conflict term arrives bound (their guards refuse to enumerate). First
% let the registry derive the conflict itself — its CSV-backed entries
% enumerate where the local misconceptions/*_batch_*.csv files exist — then
% fall back to rebuilding the bound conflict from the tracked harness surface
% (test_harness:arith_misconception/6) and asking the registry to confirm it,
% so a tracked-files-only clone still proves these edges.
decimal_registry_conflict(Move, Conflict, Witness) :-
    misconception_registry:incompatibility_with_witness(Move, Conflict,
                                                        Witness).
decimal_registry_conflict(Move, Conflict, Witness) :-
    test_harness:arith_misconception(Source, _Domain, Move, Rule, _Input,
                                     Expected),
    Rule \== skip,
    Conflict = result_of(Move, Source, Expected),
    misconception_registry:incompatibility_with_witness(Move, Conflict,
                                                        Witness).

decimal_registry_functor(
    'misconception_registry:incompatibility_with/2(ragged_decimal_addition)',
    ragged_decimal_addition).
decimal_registry_functor(
    'misconception_registry:incompatibility_with/2(no_borrow_across_point)',
    no_borrow_across_point).
decimal_registry_functor(
    'misconception_registry:incompatibility_with/2(sum_dp_ignoring_trailing_zeros)',
    sum_dp_ignoring_trailing_zeros).
decimal_registry_functor(
    'misconception_registry:incompatibility_with/2(longer_is_larger_ordering)',
    longer_is_larger_ordering).
decimal_registry_functor(
    'misconception_registry:incompatibility_with/2(natural_number_ordering)',
    natural_number_ordering).
decimal_registry_functor(
    'misconception_registry:incompatibility_with/2(decimal_point_as_separator)',
    decimal_point_as_separator).
decimal_registry_functor(
    'misconception_registry:incompatibility_with/2(decimal_part_as_integer)',
    decimal_part_as_integer).
decimal_registry_functor(
    'misconception_registry:incompatibility_with/2(trailing_zeros_increase_value)',
    trailing_zeros_increase_value).
decimal_registry_functor(
    'misconception_registry:incompatibility_with/2(zero_larger_than_decimal)',
    zero_larger_than_decimal).
decimal_registry_functor(
    'misconception_registry:incompatibility_with/2(decimals_are_negative)',
    decimals_are_negative).
