/** <module> Canonical family: Brandomian material inference rule
 *
 * Slug: material_inference. Wave-2 of the canonical-vocabulary pass; follows
 * the union-query pattern established in crosswalk/canonical_vocabulary.pl.
 *
 * Problem this solves: a "material inference" — holding some premise(s)
 * materially entitles/commits you to a conclusion — is carried by several
 * different functors across layers, with different arities and premise shapes:
 *
 *   - arche_trace(defeasible_inference):material_inference/3
 *       (Id, Premises, Conclusion) — Premises is already a LIST. The
 *       grounding-metaphor catalogue (one inference per L&N metaphor).
 *   - learner(deontic_scorekeeper):material_inference/3
 *       (RuleName, P, Q) — P, Q are single terms. The finite deontic
 *       scorekeeping table (e.g. fraction_multiplication_via_area_model).
 *       Some clauses guard on integer/1 in the premise and only fire when
 *       called with ground data.
 *   - learner(deontic_scorekeeper):mua_derived_material_inference/3
 *       (Mechanism, committed_to(Base), committed_to(Elab)) — practice-
 *       elaboration inferences derived through the MUA pp_sufficient layer.
 *   - arche_trace(embodied_prover):pml_rhythm_axiom/2
 *       (A, C) — PML rhythm axioms recovered from the prover's multifile
 *       material_inference/3 table. Empty unless the PML axiom files are also
 *       loaded; it then contributes nothing (sound, not an error).
 *
 * These are NOT redundant: they sit at different discursive layers (defeasible
 * grounding, deontic scorekeeping, MUA elaboration, PML rhythm). Renaming them
 * into one functor would collapse the principled splits and break the provers.
 *
 * So this module renames nothing. It adds ONE canonical query predicate,
 * material_inference_unified/4, that ranges over every source and tags which
 * source each result came from. It now delegates through
 * material_inference_witness/5, so the finite source-union boundary, legacy
 * functor, premise projection, and derivation are inspectable. Every source
 * call is guarded with catch/3 so an absent/erroring source contributes
 * nothing. The premise shapes are projected to a common form: a LIST of
 * premises (defeasible already is a list; the single-term sources wrap their
 * one premise as [P]).
 *
 * Dropped sources (see the agent audit / sources_dropped):
 *   - geometry material_inference/4 (ConceptId, Premise, Conclusion, Polarity):
 *     real and populated, but its facts live behind geometry/schema.pl, a
 *     NON-module ensure_loaded chain that dumps ~30 files into user. Pulling
 *     that into a clean union-query module is a heavy side-effecting load, so it
 *     is intentionally not wired here.
 */
:- module(cw_material_inference,
          [ material_inference_unified/4,  % material_inference_unified(?Id, ?Premises, ?Conclusion, -Source)
            material_inference_witness/5,  % material_inference_witness(?Id, ?Premises, ?Conclusion, ?Source, -Witness)
            canonical_concept/2,           % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2            % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

% Source modules are called module-qualified, so empty import lists are
% intentional (no predicate names pulled into this module, no clash between the
% several material_inference/3 exporters).
:- use_module(arche_trace(defeasible_inference), []).
:- use_module(learner(deontic_scorekeeper), []).
:- use_module(arche_trace(embodied_prover), []).

%! material_inference_unified(?Id, ?Premises, ?Conclusion, -Source) is nondet.
%
%  True when, according to ANY layer, holding Premises (a LIST of premise terms)
%  materially entitles/commits to Conclusion, identified by Id. Source names the
%  layer the rule came from:
%
%   - defeasible : defeasible_inference:material_inference/3. Premises is the
%                  source list verbatim. (grounding-metaphor catalogue)
%   - deontic    : deontic_scorekeeper:material_inference/3. The single premise P
%                  is projected to the list [P]. Some clauses only fire with
%                  ground data (integer guards); with unbound args they fail
%                  inside the catch and contribute nothing.
%   - mua        : deontic_scorekeeper:mua_derived_material_inference/3. The
%                  single base premise is projected to a one-element list.
%   - pml_rhythm : embodied_prover:pml_rhythm_axiom/2. Id is fixed to the atom
%                  pml_rhythm (the source carries no rule id); the antecedent A
%                  is projected to [A]. Empty unless PML axiom files are loaded.
material_inference_unified(Id, Premises, Conclusion, defeasible) :-
    material_inference_witness(Id, Premises, Conclusion, defeasible, _).
material_inference_unified(Id, [P], Q, deontic) :-
    material_inference_witness(Id, [P], Q, deontic, _).
material_inference_unified(Mechanism, [Base], Elab, mua) :-
    material_inference_witness(Mechanism, [Base], Elab, mua, _).
material_inference_unified(pml_rhythm, [A], C, pml_rhythm) :-
    material_inference_witness(pml_rhythm, [A], C, pml_rhythm, _).


%! material_inference_witness(?Id, ?Premises, ?Conclusion, ?Source, -Witness) is nondet.
%
%  Witnessed form of `material_inference_unified/4`. This is a closed-world
%  finite source-union over the currently loaded material-inference predicates.
%  It does not decide every possible material consequence in an open system; it
%  records which loaded source accepted the concrete inference and how its
%  native premise shape was projected into the crosswalk list form.
material_inference_witness(Id, Premises, Conclusion, Source,
                           _{ kind: material_inference,
                              scope: closed_world_finite_loaded_material_sources,
                              source: Source,
                              legacy_functor: LegacyFunctor,
                              id: Id,
                              premises: Premises,
                              conclusion: Conclusion,
                              premise_projection: Projection,
                              derivation: Derivation,
                              source_witness: SourceWitness }) :-
    material_inference_source(Source, LegacyFunctor),
    source_material_inference_witness(Source,
                                      Id,
                                      Premises,
                                      Conclusion,
                                      Projection,
                                      Derivation,
                                      SourceWitness).


material_inference_source(defeasible,
                          'defeasible_inference:material_inference/3').
material_inference_source(deontic,
                          'deontic_scorekeeper:material_inference/3').
material_inference_source(mua,
                          'deontic_scorekeeper:mua_derived_material_inference/3').
material_inference_source(pml_rhythm,
                          'embodied_prover:pml_rhythm_axiom/2').


source_material_inference_witness(defeasible,
                                  Id,
                                  Premises,
                                  Conclusion,
                                  list_verbatim,
                                  defeasible_material_catalog_lookup,
                                  none) :-
    catch(defeasible_inference:material_inference(Id, Premises, Conclusion),
          _, fail).
source_material_inference_witness(deontic,
                                  Id,
                                  [P],
                                  Q,
                                  single_premise_wrapped_as_list,
                                  finite_scorekeeper_rule_evaluation,
                                  none) :-
    catch(deontic_scorekeeper:material_inference(Id, P, Q), _, fail).
source_material_inference_witness(mua,
                                  Mechanism,
                                  [Base],
                                  Elab,
                                  single_premise_wrapped_as_list,
                                  pp_sufficient_elaboration_witness,
                                  SourceWitness) :-
    catch(deontic_scorekeeper:mua_derived_material_inference_witness(
              Mechanism,
              Base,
              Elab,
              SourceWitness
          ), _, fail).
source_material_inference_witness(pml_rhythm,
                                  pml_rhythm,
                                  [A],
                                  C,
                                  antecedent_wrapped_as_singleton_list,
                                  loaded_multifile_pml_rhythm_axiom,
                                  none) :-
    catch(embodied_prover:pml_rhythm_axiom(A, C), _, fail).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
%
%  Maps each scattered legacy functor to its canonical query predicate.
canonical_concept('defeasible_inference:material_inference/3',          material_inference).
canonical_concept('deontic_scorekeeper:material_inference/3',           material_inference).
canonical_concept('deontic_scorekeeper:mua_derived_material_inference/3', material_inference).
canonical_concept('embodied_prover:pml_rhythm_axiom/2',                 material_inference).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(material_inference,
    [ 'defeasible_inference:material_inference/3',
      'deontic_scorekeeper:material_inference/3',
      'deontic_scorekeeper:mua_derived_material_inference/3',
      'embodied_prover:pml_rhythm_axiom/2' ]).
