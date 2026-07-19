/** <module> Canonical vocabulary family — L&N grounding-metaphor break point
 *
 * Family slug: metaphor_break.
 *
 * Problem this solves: the concept "a Lakoff & Núñez grounding metaphor fails
 * to support an inference its target domain nevertheless validates" is carried
 * by several scattered functors at different layers and arities:
 *
 *   - formalization/grounding_metaphors.pl
 *       metaphor_breaks_at/3 (MetaphorId, TargetInference, Reason)
 *       — the union of base + extended break catalogue; the extended module's
 *         ln_metaphor_breaks_at/3 is re-exported here and is reachable through
 *         this same predicate, so we wire the grounding_metaphors owner only
 *         (the standalone grounding_metaphors_extended would double-load).
 *   - pml/mua_relations.pl
 *       metaphor_breaks_at/2 (Metaphor, Inference)
 *       — the MUA layer's terser break catalogue: a metaphor/inference pair
 *         with no reason carried.
 *   - arche-trace/defeasible_inference.pl
 *       compiled_break/2 (BreakId, ConditionSet)
 *       — a *different layer*: a handful of break-points compiled into runnable
 *         incoherent condition-sets the defeasible consequence relation can run.
 *
 * These are NOT redundant duplicates. They sit at different layers (catalogue
 * vs MUA-terse vs compiled-to-runnable) with different arities. Renaming them
 * into one functor would collapse the principled splits. So this module does
 * not rename anything. It adds ONE canonical query predicate that ranges over
 * every underlying source and tags which source a result came from. That query
 * now delegates through metaphor_break_witness/5 so the source layer,
 * projection, and available proof object are inspectable. Every source call is
 * guarded with catch/3 so a source that is absent or errors simply contributes
 * nothing.
 *
 * Projection to a common shape: metaphor_break_unified(?Metaphor, ?Inference,
 * ?Detail, -Source). The three sources have arities 3, 2, and 2 with different
 * meanings, normalized as:
 *   - grounding_metaphors : Metaphor=MetaphorId, Inference=TargetInference,
 *                           Detail=Reason (the prose reason).
 *   - mua_relations       : Metaphor=Metaphor, Inference=Inference,
 *                           Detail=none (the MUA layer carries no reason).
 *   - defeasible_inference: Metaphor=BreakId, Inference=compiled,
 *                           Detail=ConditionSet (the runnable condition list;
 *                           there is no metaphor/inference split at this layer,
 *                           so the BreakId stands in the Metaphor slot and the
 *                           atom `compiled` marks the Inference slot).
 *
 * Read-only union view. The underlying predicates are untouched and keep
 * working. None of the wired sources assert/retract or run heavy search in the
 * goals called here (each is a plain fact lookup), so no once/1 is needed.
 *
 * Part of the canonical-vocabulary pass (see crosswalk/canonical_vocabulary.pl
 * for Wave 1: incompatible/3, incoherent/2).
 */
:- module(cw_metaphor_break,
          [ metaphor_break_unified/4,   % metaphor_break_unified(?Metaphor, ?Inference, ?Detail, -Source)
            metaphor_break_witness/5,   % metaphor_break_witness(?Metaphor, ?Inference, ?Detail, ?Source, -Witness)
            canonical_concept/2,        % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2         % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

% Source modules are called module-qualified, so empty import lists are
% intentional (no names pulled into this module, no clashes).
:- use_module(formalization(grounding_metaphors), []).
:- use_module(pml(mua_relations), []).
:- use_module(arche_trace(defeasible_inference), []).

%! metaphor_break_unified(?Metaphor, ?Inference, ?Detail, -Source) is nondet.
%
%  True when grounding metaphor Metaphor fails to support inference Inference,
%  according to ANY layer. Source names the layer the verdict came from:
%   - grounding_catalogue : grounding_metaphors:metaphor_breaks_at/3 (covers the
%                           base catalogue AND the re-exported ln_metaphor_breaks_at/3).
%   - mua                 : mua_relations:metaphor_breaks_at/2 (MUA-terse pair).
%   - compiled            : defeasible_inference:compiled_break/2 (compiled to a
%                           runnable incoherent condition-set).
metaphor_break_unified(Metaphor, Inference, Detail, grounding_catalogue) :-
    metaphor_break_witness(Metaphor, Inference, Detail, grounding_catalogue, _).
metaphor_break_unified(Metaphor, Inference, none, mua) :-
    metaphor_break_witness(Metaphor, Inference, none, mua, _).
metaphor_break_unified(BreakId, compiled, ConditionSet, compiled) :-
    metaphor_break_witness(BreakId, compiled, ConditionSet, compiled, _).


%! metaphor_break_witness(?Metaphor, ?Inference, ?Detail, ?Source, -Witness) is nondet.
%
%  Witnessed form of `metaphor_break_unified/4`. This is a closed-world finite
%  union over the currently loaded metaphor-break sources. It does not decide
%  every possible metaphor failure in an open system; it records which loaded
%  layer accepted the concrete break and how that layer was projected into the
%  shared `(Metaphor, Inference, Detail)` shape.
metaphor_break_witness(Metaphor, Inference, Detail, Source,
                       WitnessDict92) :-
    witness_dict:witness_dict(metaphor_break_crosswalk, closed_world_finite_loaded_metaphor_break_sources,
                              _{source: Source,
                          legacy_functor: LegacyFunctor,
                          metaphor: Metaphor,
                          inference: Inference,
                          detail: Detail,
                          projection: Projection,
                          derivation: Derivation,
                          source_witness: SourceWitness }, WitnessDict92),
    metaphor_break_source(Source, LegacyFunctor),
    source_metaphor_break_witness(Source,
                                  Metaphor,
                                  Inference,
                                  Detail,
                                  Projection,
                                  Derivation,
                                  SourceWitness).


metaphor_break_source(grounding_catalogue,
                      'grounding_metaphors:metaphor_breaks_at/3').
metaphor_break_source(mua,
                      'mua_relations:metaphor_breaks_at/2').
metaphor_break_source(compiled,
                      'defeasible_inference:compiled_break/2').


source_metaphor_break_witness(grounding_catalogue,
                              Metaphor,
                              Inference,
                              Detail,
                              reason_preserved,
                              catalogue_break_witness,
                              SourceWitness) :-
    catch(grounding_metaphors:metaphor_break_witness(Metaphor,
                                                     Inference,
                                                     Detail,
                                                     SourceWitness),
          _, fail).
source_metaphor_break_witness(mua,
                              Metaphor,
                              Inference,
                              none,
                              terse_pair_detail_absent,
                              mua_break_pair_lookup,
                              none) :-
    catch(mua_relations:metaphor_breaks_at(Metaphor, Inference), _, fail).
source_metaphor_break_witness(compiled,
                              BreakId,
                              compiled,
                              ConditionSet,
                              break_id_and_condition_set,
                              compiled_incoherent_condition_lookup,
                              _{ kind: compiled_break_condition_set,
                                 break_id: BreakId,
                                 condition_set: ConditionSet,
                                 condition_count: Count }) :-
    catch(defeasible_inference:compiled_break(BreakId, ConditionSet), _, fail),
    length(ConditionSet, Count).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
%
%  Maps each scattered legacy functor to its canonical query predicate.
canonical_concept('grounding_metaphors:metaphor_breaks_at/3',    metaphor_break_unified).
canonical_concept('grounding_metaphors:ln_metaphor_breaks_at/3', metaphor_break_unified).
canonical_concept('mua_relations:metaphor_breaks_at/2',          metaphor_break_unified).
canonical_concept('defeasible_inference:compiled_break/2',       metaphor_break_unified).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(metaphor_break_unified,
    [ 'grounding_metaphors:metaphor_breaks_at/3',
      'grounding_metaphors:ln_metaphor_breaks_at/3',
      'mua_relations:metaphor_breaks_at/2',
      'defeasible_inference:compiled_break/2' ]).
