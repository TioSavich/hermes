/** <module> Crosswalk family — practice/strategy vocabulary registry
 *
 * Problem this solves: several functors across the strategies and PML layers
 * all answer roughly one question — "what vocabulary terms does this practice
 * / strategy kind deploy?" They were never duplicates; they sit at different
 * layers and were written for different consumers:
 *
 *   - strategies/math/sar_add_action_pairs:action_vocabulary/2
 *       Additive strategy kinds -> the list of vocabulary atoms that kind's
 *       action automaton deploys. (+Kind, -Terms)
 *   - strategies/math/fraction_action_pairs:fraction_action_vocabulary/2
 *       Fraction strategy kinds -> their vocabulary atoms. (+Kind, -Terms)
 *   - pml/mua_relations:kind_vocabulary_terms/2
 *       Any registry kind -> the SORTED UNION of registry vocabulary and the
 *       MUA pv_sufficient-curated synonyms. (?Kind, -Terms)
 *   - pml/mua_relations:vocabulary/2
 *       A vocabulary IDENTIFIER (v_counting, v_area_model, ...) -> a prose
 *       description string. (?VocId, ?Description)
 *
 * Renaming these into one functor would collapse the layer split (the
 * registry-list layer vs the MUA-union layer) and the differing key/value
 * semantics, and would touch every call site. So this module renames nothing.
 * It adds ONE read-only union query, practice_vocabulary_unified/3, that ranges
 * over every source and tags which source each result came from. Underlying
 * predicates are untouched; every source call is wrapped in catch/3 so an
 * absent or erroring source contributes nothing.
 *
 * Normalization (the projection, since sources differ in value shape):
 *   practice_vocabulary_unified(Key, Vocabulary, Source)
 *     Key        : the lookup atom — a strategy/registry Kind for the three
 *                  kind-based sources, or a vocabulary-id (v_*) for the
 *                  description source.
 *     Vocabulary : a LIST. For the three kind-based sources this is the term
 *                  list verbatim. For mua_relations:vocabulary/2 the value is a
 *                  prose description STRING, which we project to a singleton
 *                  list [Description] so every result has the same shape. The
 *                  Source tag (mua_vocabulary_description) lets a caller that
 *                  cares unwrap it.
 *     Source     : additive_action | fraction_action | mua_kind_terms
 *                  | mua_vocabulary_description
 *
 * kind_vocabulary_terms/2 runs findall over registry + MUA facts (no
 * assert/retract, no bounded search), so it is side-effect-free; we still wrap
 * it in once/1 inside catch/3 to keep the union deterministic per Key/Source.
 */
:- module(cw_practice_vocabulary,
          [ practice_vocabulary_unified/3, % practice_vocabulary_unified(?Key, -Vocabulary, -Source)
            practice_vocabulary_witness/4, % practice_vocabulary_witness(?Key, -Vocabulary, ?Source, -Witness)
            canonical_concept/2,           % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2            % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

% Source modules are called module-qualified; empty import lists are
% intentional (nothing pulled into this module's namespace).
:- use_module(strategies(math/sar_add_action_pairs), []).
:- use_module(strategies(math/fraction_action_pairs), []).
:- use_module(pml(mua_relations), []).

%! practice_vocabulary_unified(?Key, -Vocabulary, -Source) is nondet.
%
%  True when practice/strategy Key deploys Vocabulary (a list of terms)
%  according to ANY source layer. Source names which layer answered.
practice_vocabulary_unified(Key, Vocabulary, additive_action) :-
    practice_vocabulary_witness(Key, Vocabulary, additive_action, _).
practice_vocabulary_unified(Key, Vocabulary, fraction_action) :-
    practice_vocabulary_witness(Key, Vocabulary, fraction_action, _).
practice_vocabulary_unified(Key, Vocabulary, mua_kind_terms) :-
    practice_vocabulary_witness(Key, Vocabulary, mua_kind_terms, _).
practice_vocabulary_unified(Key, [Description], mua_vocabulary_description) :-
    practice_vocabulary_witness(Key, [Description], mua_vocabulary_description, _).

%! practice_vocabulary_witness(?Key, -Vocabulary, ?Source, -Witness) is nondet.
%
%  Witnessed form of `practice_vocabulary_unified/3`. This is a closed-world
%  finite union over the currently loaded practice-vocabulary sources. It does
%  not claim an open-ended vocabulary ontology; it records which loaded table
%  accepted the row and how the source value was projected to the canonical
%  list-shaped `Vocabulary`.
practice_vocabulary_witness(Key, Vocabulary, Source,
                            WitnessDict80) :-
    witness_dict:witness_dict(practice_vocabulary_crosswalk, closed_world_finite_loaded_practice_vocabulary_sources,
                              _{key: Key,
                               vocabulary: Vocabulary,
                               source: Source,
                               legacy_functor: LegacyFunctor,
                               vocabulary_shape: VocabularyShape,
                               derivation: Derivation,
                               source_witness: SourceWitness }, WitnessDict80),
    source_practice_vocabulary_witness(Source,
                                       Key,
                                       Vocabulary,
                                       LegacyFunctor,
                                       VocabularyShape,
                                       Derivation,
                                       SourceWitness).

source_practice_vocabulary_witness(additive_action,
                                   Key,
                                   Vocabulary,
                                   'sar_add_action_pairs:action_vocabulary/2',
                                   term_list,
                                   direct_additive_action_vocabulary_row,
                                   _{ kind: direct_action_vocabulary_row,
                                      module: sar_add_action_pairs,
                                      predicate: action_vocabulary/2,
                                      action_kind: Key,
                                      terms: Vocabulary,
                                      term_count: TermCount }) :-
    catch(sar_add_action_pairs:action_vocabulary(Key, Vocabulary), _, fail),
    length(Vocabulary, TermCount).
source_practice_vocabulary_witness(fraction_action,
                                   Key,
                                   Vocabulary,
                                   'fraction_action_pairs:fraction_action_vocabulary/2',
                                   term_list,
                                   direct_fraction_action_vocabulary_row,
                                   _{ kind: direct_action_vocabulary_row,
                                      module: fraction_action_pairs,
                                      predicate: fraction_action_vocabulary/2,
                                      action_kind: Key,
                                      terms: Vocabulary,
                                      term_count: TermCount }) :-
    catch(fraction_action_pairs:fraction_action_vocabulary(Key, Vocabulary), _, fail),
    length(Vocabulary, TermCount).
source_practice_vocabulary_witness(mua_kind_terms,
                                   Key,
                                   Vocabulary,
                                   'mua_relations:kind_vocabulary_terms/2',
                                   sorted_term_union,
                                   mua_registry_and_curated_vocabulary_union,
                                   _{ kind: mua_kind_vocabulary_union,
                                      module: mua_relations,
                                      predicate: kind_vocabulary_terms/2,
                                      action_kind: Key,
                                      union_rule: registry_terms_plus_pv_sufficient_terms,
                                      terms: Vocabulary,
                                      term_count: TermCount }) :-
    catch(once(mua_relations:kind_vocabulary_terms(Key, Vocabulary)), _, fail),
    Vocabulary \== [],
    length(Vocabulary, TermCount).
source_practice_vocabulary_witness(mua_vocabulary_description,
                                   Key,
                                   [Description],
                                   'mua_relations:vocabulary/2',
                                   singleton_description_list,
                                   vocabulary_description_projected_to_singleton_list,
                                   _{ kind: mua_vocabulary_description,
                                      module: mua_relations,
                                      predicate: vocabulary/2,
                                      vocabulary_id: Key,
                                      description: Description,
                                      projection: description_as_singleton_list }) :-
    catch(mua_relations:vocabulary(Key, Description), _, fail).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
%
%  Maps each scattered legacy functor to its canonical query predicate.
canonical_concept('sar_add_action_pairs:action_vocabulary/2',          practice_vocabulary_unified).
canonical_concept('fraction_action_pairs:fraction_action_vocabulary/2', practice_vocabulary_unified).
canonical_concept('mua_relations:kind_vocabulary_terms/2',             practice_vocabulary_unified).
canonical_concept('mua_relations:vocabulary/2',                        practice_vocabulary_unified).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is det.
vocabulary_source(practice_vocabulary_unified,
    [ 'sar_add_action_pairs:action_vocabulary/2',
      'fraction_action_pairs:fraction_action_vocabulary/2',
      'mua_relations:kind_vocabulary_terms/2',
      'mua_relations:vocabulary/2' ]).
