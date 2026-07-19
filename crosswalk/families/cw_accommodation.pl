/** <module> Crosswalk family: sublation / accommodation
 *
 * One concept — the ORR-cycle "Reorganize" move (Hegelian Aufhebung /
 * Piagetian accommodation): a state of disequilibrium triggers a modification
 * of the system's own knowledge base or commitment set. Two scattered functors
 * carry it:
 *
 *   - critique:accommodate/1           (arche-trace/critique.pl)
 *   - reorganization_engine:accommodate/1
 *                                      (learner/reorganization_engine.pl)
 *   - reorganization_engine:reorganize_system/2
 *                                      (learner/reorganization_engine.pl)
 *
 * WHY registry_only (not a value-returning union query like wave 1's
 * incompatible/3 and incoherent/2): every member of this family is an
 * EXECUTOR, not a fact source. They all print to stdout, mutate dynamic
 * stress maps (increment_stress/1, assert/retract on stress/2), and/or
 * attempt belief revision on object_level. They are semidet side-effecting
 * goals whose "answer" is a state change, not a binding. Folding them into a
 * value-returning predicate would either (a) run their side effects on every
 * crosswalk probe or (b) strip exactly the behaviour that makes them this
 * concept. Honesty over force: this module exposes a read-only REGISTRY that
 * names each variant's owning module, functor/arity, trigger shape, and effect,
 * so callers can discover and dispatch them deliberately — but it does NOT call
 * them. The canonical predicate accommodation_unified/2 ranges over registry
 * entries (side-effect-free); it never invokes an accommodation goal.
 *
 * No existing predicate is renamed or rewritten. use_module import lists are
 * empty: we only need the owners loaded (so the registered targets resolve if a
 * caller chooses to dispatch); we never pull their names into this module.
 *
 * Part of the canonical-vocabulary crosswalk (same style as
 * crosswalk/canonical_vocabulary.pl). Family slug: accommodation.
 */
:- module(cw_accommodation,
          [ accommodation_unified/2,   % accommodation_unified(-Target, -Source)
            accommodation_witness/3,   % accommodation_witness(?Target, ?Source, -Witness)
            canonical_concept/2,       % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2        % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

% Load the owning modules so their predicates exist for any caller that decides
% to dispatch a registered Target. Empty import lists: we call nothing here and
% pull no names in. Guarded at directive level by SWI's normal load; both were
% confirmed to load and co-load clean.
:- use_module(arche_trace(critique), []).
:- use_module(learner(reorganization_engine), []).

%! accommodation_unified(-Target, -Source) is nondet.
%
%  The canonical query for the sublation/accommodation family. Because the
%  members are side-effecting executors (see module header), this is a REGISTRY
%  view, not a value-returning union: each solution names a dispatchable Target
%  of the form Module:Functor/Arity together with the Source layer it belongs to.
%  It is side-effect-free — it ranges over registry/3 facts and never invokes an
%  accommodation goal.
%
%  Source values:
%   - arche_trace_critique : critique:accommodate/1 — sequent/commitment-layer
%                            sublation; mutates a stress map, prints, fails to
%                            signal external intervention.
%   - learner_reorg        : reorganization_engine:accommodate/1 — learner-layer
%                            accommodation; dispatches to belief-revision /
%                            conceptual-stress repair on object_level.
%   - learner_reorg        : reorganization_engine:reorganize_system/2 — the
%                            ORR "Reorganize" entry point (Goal, Trace); finite
%                            archived-synthesis boundary, with crisis recovery
%                            routed through oracle wrapping rather than live FSM
%                            synthesis.
accommodation_unified(Target, Source) :-
    accommodation_witness(Target, Source, _).

%! accommodation_witness(?Target, ?Source, -Witness) is nondet.
%
%  Witnessed form of `accommodation_unified/2`. This is a closed-world finite
%  registry over the currently loaded accommodation executors. It proves only
%  registry membership plus loaded predicate existence; it deliberately does not
%  invoke the target because these predicates write diagnostics, mutate stress
%  or knowledge state, or signal failure to external crisis handlers.
accommodation_witness(Target, Source,
                      WitnessDict81) :-
    witness_dict:witness_dict(accommodation_registry_entry, closed_world_finite_loaded_accommodation_registry,
                              _{target: Target,
                         source: Source,
                         legacy_functor: LegacyFunctor,
                         trigger_shape: TriggerShape,
                         effect: Effect,
                         invocation_policy: registry_only_no_executor_call,
                         side_effect_boundary: SideEffectBoundary,
                         target_witness: TargetWitness }, WitnessDict81),
    registry(Target,
             Source,
             Effect,
             TriggerShape,
             SideEffectBoundary,
             LegacyFunctor),
    target_defined_witness(Target, TargetWitness).

%! registry(-Target, -Source, -Effect) is nondet.
%
%  The crosswalk registry. Target is Module:Functor/Arity (a callable
%  specification, NOT a call); Source is the layer tag; Effect is a short prose
%  note on what dispatching the Target actually does (all are side-effecting).
registry(Target, Source, Effect) :-
    registry(Target, Source, Effect, _TriggerShape, _SideEffectBoundary, _LegacyFunctor).

registry(critique:accommodate/1,
         arche_trace_critique,
         'sequent/commitment sublation; increments stress map, writes diagnostics, and fails to signal external intervention',
         'perturbation(resource_exhaustion, Sequent) | incoherence(Commitments) | pathology(bad_infinite, Cycle) | Trigger',
         stress_map_and_stdout,
         'critique:accommodate/1').
registry(reorganization_engine:accommodate/1,
         learner_reorg,
         'learner accommodation; dispatches to belief revision or conceptual-stress repair on object_level',
         'goal_failure(_) | perturbation(_) | incoherence(Commitments) | Trigger',
         object_level_stress_map_log_and_stdout,
         'reorganization_engine:accommodate/1').
registry(reorganization_engine:reorganize_system/2,
         learner_reorg,
         'ORR Reorganize entry point; current finite crisis-recovery path reports the archived FSM-synthesis boundary and fails',
         'Goal, Trace',
         stdout_and_external_recovery_signal,
         'reorganization_engine:reorganize_system/2').

target_defined_witness(Module:Name/Arity,
                       _{ kind: loaded_predicate_presence,
                          module: Module,
                          name: Name,
                          arity: Arity,
                          properties: Properties }) :-
    catch(once(( current_predicate(Module:Name/Arity)
               ; functor(Head, Name, Arity),
                 predicate_property(Module:Head, defined)
               )), _, fail),
    findall(Property,
            target_property(Module, Name, Arity, Property),
            Properties0),
    sort(Properties0, Properties).

target_property(Module, Name, Arity, defined) :-
    functor(Head, Name, Arity),
    predicate_property(Module:Head, defined).
target_property(Module, Name, Arity, exported) :-
    functor(Head, Name, Arity),
    predicate_property(Module:Head, exported).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
%
%  Maps each scattered legacy functor to this family's canonical name.
canonical_concept('critique:accommodate/1',                    accommodation).
canonical_concept('reorganization_engine:accommodate/1',       accommodation).
canonical_concept('reorganization_engine:reorganize_system/2', accommodation).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(accommodation,
    [ 'critique:accommodate/1',
      'reorganization_engine:accommodate/1',
      'reorganization_engine:reorganize_system/2' ]).
