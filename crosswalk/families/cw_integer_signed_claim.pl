/** <module> cw_integer_signed_claim — canonical crosswalk family for integer-signed CLAIM concepts
 *
 * Bucket: integer_signed. Two literature commitments about signed/directed
 * quantity each earn a crosswalk home because each has verified cross-surface
 * presence — a real, existing non-literature legacy functor expresses the same
 * concept:
 *
 *   directed_signed_quantity_operations  (c_signed_number_order_and_operations)
 *     - the integer action automaton that coordinates sign and magnitude,
 *     - two grounding-metaphor grounds_inference/3 facts (motion-along-a-path
 *       for ordered directed locations; rotation-by-180 for product-of-two-
 *       negatives),
 *     - a derived misconception incompatibility (dropping the sign).
 *
 *   algebraic_term_sign_attachment  (c_signed_term_structure)
 *     - a registered misconception incompatibility for detaching a term from
 *       its preceding operation sign and regrouping.
 *
 * Same shape as the other crosswalk families (see cw_fraction_claim): it
 * RENAMES nothing and OWNS no facts. vocabulary_source/2 is the contract the
 * aggregator (canonical_all) ranges over; canonical_concept/2 is the reverse
 * map; integer_signed_claim_unified/3 is the live query that pulls the
 * literature gloss plus one row per verified legacy edge.
 *
 * Every legacy edge recorded here was loaded and queried against the live
 * system before promotion. Edges flagged unverified upstream are NOT recorded.
 *
 * Family slug: integer_signed_claim.
 */
:- module(cw_integer_signed_claim,
          [ integer_signed_claim_unified/3, % integer_signed_claim_unified(-Canonical, -Detail, -Source)
            integer_signed_claim_witness/4, % integer_signed_claim_witness(?Canonical, ?Detail, ?Source, -Witness)
            claim_literature_atom/2,         % claim_literature_atom(?Canonical, ?LiteratureAtom)
            canonical_concept/2,             % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2              % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

:- use_module(misconceptions(literature_vocabulary), []).
:- use_module(strategies('math/action_automata_registry'), []).
:- use_module(formalization(grounding_metaphors), []).
:- use_module(misconceptions(misconception_registry), []).
:- use_module(library(lists), [ member/2 ]).

%! isc(?Canonical, ?LiteratureAtom, ?Edges) is nondet.
%
%  The family table. Each row: the canonical signed-quantity concept; the real
%  literature canonical_commitment atom (verified present); and the list of
%  verified non-literature legacy edges that express the same concept. Each
%  edge is edge(Functor, Surface): Functor is the 'Module:Name/Arity(args)'
%  identifier string, Surface is the human-readable gloss of that edge.
isc(directed_signed_quantity_operations,
    c_signed_number_order_and_operations,
    [ edge('action_automata_registry:action_automaton_cluster/3(integer,signed_addition_with_sign_relation)',
           "Productive integer action automaton coordinating sign and magnitude; the sign-sensitive signed_number_combination cluster."),
      edge('grounding_metaphors:grounds_inference/3(arithmetic_is_motion_along_a_path,negative_numbers)',
           "Negatives grounded as directed point-locations ordered on a path (Motion Along a Path)."),
      edge('grounding_metaphors:grounds_inference/3(multiplication_by_minus_one_is_rotation_by_180_degrees,product_of_two_negatives)',
           "Sign-sensitive multiplication grounded as rotation: two 180-degree rotations compose to identity."),
      edge('misconception_registry:incompatibility_with/2(drop_sign_use_magnitude_sum)',
           "Derived incompatibility: dropping the sign and summing magnitudes violates the sign-sensitive combination commitment.")
    ]).
isc(algebraic_term_sign_attachment,
    c_signed_term_structure,
    [ edge('misconception_registry:incompatibility_with/2(detach_sign_group_terms)',
           "Registered misconception: detaching a number from its preceding operation sign and regrouping by sign violates 'each term carries its operation sign'.")
    ]).

%! claim_literature_atom(?Canonical, ?LiteratureAtom) is nondet.
%  The literature commitment atom a canonical signed-quantity concept resolves to.
claim_literature_atom(Canonical, LitAtom) :- isc(Canonical, LitAtom, _).

% The legacy functor strings for a canonical term: the literature commitment
% functor plus each verified edge functor, all as 'Module:Name/Arity(args)'
% style atoms (matching the convention used by the other families).
legacy_list(Canonical, [LitFunctor | EdgeFunctors]) :-
    isc(Canonical, Lit, Edges),
    atomic_list_concat(['literature_vocabulary:canonical_commitment/2(', Lit, ')'], LitFunctor),
    findall(F, member(edge(F, _), Edges), EdgeFunctors).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(Canonical, Legacies) :- legacy_list(Canonical, Legacies).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
canonical_concept(Legacy, Canonical) :-
    legacy_list(Canonical, Legacies),
    member(Legacy, Legacies).

%! integer_signed_claim_unified(?Canonical, ?Detail, ?Source) is nondet.
%
%  Source = literature_commitment: Detail = commitment(Atom, Gloss) — the real
%  canonical_commitment gloss for this concept's literature atom.
%  Source = <edge functor string>: Detail = edge_surface(Surface) — one row per
%  verified non-literature legacy edge that expresses the concept.
integer_signed_claim_unified(Canonical, Detail, Source) :-
    integer_signed_claim_witness(Canonical, Detail, Source, _).

%! integer_signed_claim_witness(?Canonical, ?Detail, ?Source, -Witness) is nondet.
%
%  Witnessed form of `integer_signed_claim_unified/3`. This is a closed-world
%  finite check over the loaded signed-integer claim table and the source
%  predicates that own each listed row. The table proposes alignments; this
%  predicate succeeds only when the owner proves the referenced literature
%  commitment or legacy edge.
integer_signed_claim_witness(
    Canonical,
    commitment(Lit, GlossS),
    literature_commitment,
    WitnessDict108) :-
    witness_dict:witness_dict(integer_signed_claim_crosswalk, closed_world_finite_verified_integer_signed_claim_edges,
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
                          gloss: GlossS } }, WitnessDict108),
    isc(Canonical, Lit, _),
    catch(literature_vocabulary:canonical_commitment(Lit, Gloss), _, fail),
    ( string(Gloss) -> GlossS = Gloss ; format(string(GlossS), "~w", [Gloss]) ).
integer_signed_claim_witness(
    Canonical,
    edge_surface(Surface),
    Functor,
    WitnessDict128) :-
    witness_dict:witness_dict(integer_signed_claim_crosswalk, closed_world_finite_verified_integer_signed_claim_edges,
                              _{canonical: Canonical,
       detail: edge_surface(Surface),
       source: Functor,
       legacy_functor: Functor,
       projection: verified_legacy_edge_surface,
       derivation: owner_predicate_edge_check,
       source_witness: SourceWitness }, WitnessDict128),
    isc(Canonical, _, Edges),
    member(edge(Functor, Surface), Edges),
    integer_signed_edge_source_witness(Functor, SourceWitness).

integer_signed_edge_source_witness(
    'action_automata_registry:action_automaton_cluster/3(integer,signed_addition_with_sign_relation)',
    _{ kind: action_automaton_cluster_edge,
       module: action_automata_registry,
       predicate: action_automaton_cluster/3,
       operation: integer,
       action_kind: signed_addition_with_sign_relation,
       cluster: Cluster }) :-
    catch(action_automata_registry:action_automaton_cluster(
              integer, signed_addition_with_sign_relation, Cluster),
          _, fail).
integer_signed_edge_source_witness(
    'grounding_metaphors:grounds_inference/3(arithmetic_is_motion_along_a_path,negative_numbers)',
    _{ kind: grounding_metaphor_inference_edge,
       module: grounding_metaphors,
       predicate: grounds_inference_witness/4,
       metaphor: arithmetic_is_motion_along_a_path,
       target_inference: negative_numbers,
       grounding_path: GroundingPath,
       grounding_witness: GroundingWitness }) :-
    catch(grounding_metaphors:grounds_inference_witness(
              arithmetic_is_motion_along_a_path,
              negative_numbers,
              GroundingPath,
              GroundingWitness),
          _, fail).
integer_signed_edge_source_witness(
    'grounding_metaphors:grounds_inference/3(multiplication_by_minus_one_is_rotation_by_180_degrees,product_of_two_negatives)',
    _{ kind: grounding_metaphor_inference_edge,
       module: grounding_metaphors,
       predicate: grounds_inference_witness/4,
       metaphor: multiplication_by_minus_one_is_rotation_by_180_degrees,
       target_inference: product_of_two_negatives,
       grounding_path: GroundingPath,
       grounding_witness: GroundingWitness }) :-
    catch(grounding_metaphors:grounds_inference_witness(
              multiplication_by_minus_one_is_rotation_by_180_degrees,
              product_of_two_negatives,
              GroundingPath,
              GroundingWitness),
          _, fail).
integer_signed_edge_source_witness(
    'misconception_registry:incompatibility_with/2(drop_sign_use_magnitude_sum)',
    _{ kind: misconception_registry_incompatibility_edge,
       module: misconception_registry,
       predicate: incompatibility_with_witness/3,
       move: drop_sign_use_magnitude_sum,
       conflict: strategy(integer, signed_addition_with_sign_relation),
       registry_witness: RegistryWitness }) :-
    catch(once(misconception_registry:incompatibility_with_witness(
                   drop_sign_use_magnitude_sum,
                   strategy(integer, signed_addition_with_sign_relation),
                   RegistryWitness)),
          _, fail).
integer_signed_edge_source_witness(
    'misconception_registry:incompatibility_with/2(detach_sign_group_terms)',
    _{ kind: misconception_registry_incompatibility_edge,
       module: misconception_registry,
       predicate: incompatibility_with_witness/3,
       move: detach_sign_group_terms,
       conflict: result_of(detach_sign_group_terms, db_row(39498), 60),
       registry_witness: RegistryWitness }) :-
    catch(once(misconception_registry:incompatibility_with_witness(
                   detach_sign_group_terms,
                   result_of(detach_sign_group_terms, db_row(39498), 60),
                   RegistryWitness)),
          _, fail).
