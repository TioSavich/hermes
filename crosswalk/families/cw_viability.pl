/** <module> cw_viability — canonical query for the inference-budget viability check
 *
 * Concept family: "Inference-budget viability check". Two modules carry the
 * same private helper under the same functor name and identical semantics:
 *
 *   - embodied_prover:check_viability/2  (arche-trace/embodied_prover.pl)
 *       check_viability(R, Cost) :- R >= Cost, !.
 *       check_viability(_, _) :- throw(perturbation(resource_exhaustion)).
 *
 *   - meta_interpreter:check_viability/2 (learner/meta_interpreter.pl)
 *       check_viability(I, Cost) :- I >= Cost, !.
 *       check_viability(I, Cost) :- format(...), throw(perturbation(resource_exhaustion)).
 *
 * Both decide whether a remaining resource budget (cognitive inferences) is
 * sufficient to pay the next step's Cost. The fragmentation is principled: one
 * lives in the sequent-calculus embodied prover (resource = abstract reasoning
 * budget), the other in the ORR meta-interpreter (resource = inference counter).
 * Neither is exported by its owning module, so we call them module-qualified.
 *
 * This module does not rename or rewrite either predicate. It adds ONE
 * read-only, source-tagged union query:
 *
 *   viability_unified(+Resources, +Cost, -Source) is semidet (per source)
 *
 * Both source predicates share arity 2 and the same argument meaning
 * (Resources, Cost), so no projection is needed beyond tagging the Source.
 *
 * Side-effect note: both sources are NOT pure facts. On the insufficient-budget
 * branch each THROWS perturbation(resource_exhaustion); the meta_interpreter
 * variant also prints a "[CRISIS]" line to stdout before throwing. We wrap every
 * source call in once/1 + catch(Goal,_,fail) so:
 *   - a thrown perturbation contributes nothing (viability_unified just fails for
 *     that source), and
 *   - the query is deterministic per source.
 * The only residual side-effect is the meta_interpreter CRISIS print, which can
 * fire when Resources < Cost for the meta_interpreter source. Callers who must
 * stay silent should query the embodied_prover source (which prints nothing).
 *
 * Wave 2 of the canonical-vocabulary pass; same shape as crosswalk/canonical_vocabulary.pl.
 */
:- module(cw_viability,
          [ viability_unified/3,    % viability_unified(+Resources, +Cost, -Source)
            viability_witness/4,    % viability_witness(+Resources, +Cost, -Source, -Witness)
            canonical_concept/2,    % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2     % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

% Source modules are called module-qualified, so empty import lists are
% intentional (no private helpers pulled into this module's namespace).
:- use_module(arche_trace(embodied_prover), []).
:- use_module(learner(meta_interpreter), []).

%! viability_unified(+Resources, +Cost, -Source) is semidet.
%
%  True when a budget of Resources is sufficient to pay Cost according to the
%  named Source layer. Source:
%    - embodied_prover  : embodied_prover:check_viability/2 (sequent-prover budget)
%    - meta_interpreter : meta_interpreter:check_viability/2 (ORR inference counter)
%
%  Each source succeeds iff Resources >= Cost. The insufficient case throws in
%  the source; we catch it and contribute nothing, so viability_unified simply
%  fails for that source rather than propagating the perturbation. See the
%  module side-effect note re: the meta_interpreter CRISIS print.
viability_unified(Resources, Cost, embodied_prover) :-
    viability_witness(Resources, Cost, embodied_prover, _).
viability_unified(Resources, Cost, meta_interpreter) :-
    viability_witness(Resources, Cost, meta_interpreter, _).

%! viability_witness(+Resources, +Cost, ?Source, -Witness) is semidet.
%
%  Witnessed form of `viability_unified/3`. This is the finite budget
%  comparison made by the loaded resource-checking sources. It does not infer a
%  global cognitive limit; it records that the named Source accepted the
%  concrete Resources >= Cost check without throwing perturbation.
viability_witness(Resources, Cost, Source,
                  WitnessDict76) :-
    witness_dict:witness_dict(inference_budget_viability, closed_world_finite_resource_check,
                              _{source: Source,
                     legacy_functor: LegacyFunctor,
                     resources: Resources,
                     cost: Cost,
                     relation: resources_cover_cost,
                     comparison: Comparison,
                     caught_perturbation_boundary: insufficient_budget_throws_resource_exhaustion }, WitnessDict76),
    viability_source(Source, LegacyFunctor),
    must_be(number, Resources),
    must_be(number, Cost),
    Resources >= Cost,
    source_check_viability(Source, Resources, Cost),
    Comparison =.. [>=, Resources, Cost].


viability_source(embodied_prover, 'embodied_prover:check_viability/2').
viability_source(meta_interpreter, 'meta_interpreter:check_viability/2').


source_check_viability(embodied_prover, Resources, Cost) :-
    catch(once(embodied_prover:check_viability(Resources, Cost)), _, fail).
source_check_viability(meta_interpreter, Resources, Cost) :-
    catch(once(meta_interpreter:check_viability(Resources, Cost)), _, fail).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
%
%  Maps each scattered legacy functor to its canonical query predicate.
canonical_concept('embodied_prover:check_viability/2',  viability).
canonical_concept('meta_interpreter:check_viability/2', viability).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(viability,
    [ 'embodied_prover:check_viability/2',
      'meta_interpreter:check_viability/2' ]).
