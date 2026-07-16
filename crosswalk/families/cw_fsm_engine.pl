/** <module> Canonical vocabulary family — FSM execution engine (fsm_engine)
 *
 * Concept: "run a finite-state strategy automaton to completion, collecting an
 * execution history." Several functors across two modules denote roughly this
 * one activity, sitting at different layers and arities:
 *
 *   - strategies:fsm_engine:run_fsm/4
 *       The generic strategy executor. Incurs an inference cost, runs the
 *       student-strategy FSM loop, reverses the accumulated history.
 *   - strategies:fsm_engine:run_strategy/4
 *       High-level wrapper: setup_strategy/4 -> run_fsm/4 -> extract_result/3.
 *       Takes (Module, A, B, Result) rather than an explicit initial state.
 *   - arche_trace:dialectical_engine:run_fsm/4
 *       A second, independent generic FSM executor used by the ORR/critique
 *       rhythm. Same name and arity as the strategies one, but a distinct
 *       predicate in a distinct module, with stuck-state handling instead of
 *       the strategies loop's hard once/1 transition.
 *
 * REGISTRY-ONLY, by design. Unlike the wave-1 incompatible/incoherent
 * families, these functors are EXECUTORS: they call incur_cost/1, run search
 * loops over Module:transition/3, and build history. A value-returning union
 * query over them would have to actually run FSMs (side effects, unbounded
 * search, dependence on a loaded strategy module). That does not fit a
 * side-effect-free canonical query. So instead of invoking them, this module
 * exposes a REGISTRY: it names each variant as module:functor/arity and tags
 * the source. Callers (and the LLM legal-vocabulary contract) can discover
 * "these are the FSM-execution entry points" without this module executing
 * anything.
 *
 * The canonical query predicate is fsm_engine_unified/2:
 *     fsm_engine_unified(?Descriptor, -Source)
 * where Descriptor is the term Module:Functor/Arity and Source is a tag.
 * Each clause is catch-guarded so that if an owning module is absent (its
 * predicate not defined), that variant contributes nothing.
 *
 * Wave 2 of the canonical-vocabulary pass. Pattern follows
 * crosswalk/canonical_vocabulary.pl (source-tagged, guarded, union view).
 */
:- module(cw_fsm_engine,
          [ fsm_engine_unified/2,    % fsm_engine_unified(?Descriptor, -Source)
            fsm_engine_witness/3,    % fsm_engine_witness(?Descriptor, ?Source, -Witness)
            canonical_concept/2,     % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2      % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

% Load the owning modules so we can probe whether each variant predicate
% actually exists. Empty import lists: we never pull their names into this
% module; the registry is descriptive, not a re-export of the executors.
:- use_module(strategies(fsm_engine), []).
:- use_module(arche_trace(dialectical_engine), []).

%! fsm_engine_unified(?Descriptor, -Source) is nondet.
%
%  Enumerates the FSM-execution entry points across the codebase, each as a
%  Module:Functor/Arity descriptor with a Source tag. This does NOT run any
%  FSM. The catch/3 guard plus the predicate-existence check mean a variant
%  whose owning module failed to load (or whose predicate was renamed away)
%  silently drops out instead of erroring.
%
%  Source tags:
%   - strategy_generic   : strategies:fsm_engine:run_fsm/4
%   - strategy_high_level: strategies:fsm_engine:run_strategy/4
%   - dialectical_generic: arche_trace:dialectical_engine:run_fsm/4
fsm_engine_unified(fsm_engine:run_fsm/4, strategy_generic) :-
    fsm_engine_witness(fsm_engine:run_fsm/4, strategy_generic, _).
fsm_engine_unified(fsm_engine:run_strategy/4, strategy_high_level) :-
    fsm_engine_witness(fsm_engine:run_strategy/4, strategy_high_level, _).
fsm_engine_unified(dialectical_engine:run_fsm/4, dialectical_generic) :-
    fsm_engine_witness(dialectical_engine:run_fsm/4, dialectical_generic, _).

%! fsm_engine_witness(?Descriptor, ?Source, -Witness) is nondet.
%
%  Witnessed form of `fsm_engine_unified/2`. This is a closed-world finite
%  registry over the currently loaded FSM-execution entry points. It does not
%  execute an FSM; it proves that a concrete executor descriptor is present as a
%  defined predicate in its owning module and records the side-effect boundary.
fsm_engine_witness(Descriptor, Source,
                   _{ kind: fsm_engine_registry_entry,
                      scope: closed_world_finite_loaded_fsm_executor_registry,
                      descriptor: Descriptor,
                      source: Source,
                      legacy_functor: LegacyFunctor,
                      execution_policy: registry_only_no_fsm_execution,
                      side_effect_boundary: owning_executor_may_incur_cost_or_run_search,
                      source_witness: SourceWitness }) :-
    fsm_engine_variant(Source, Descriptor, LegacyFunctor, Module, Name, Arity),
    predicate_presence_witness(Module, Name, Arity, SourceWitness).

fsm_engine_variant(strategy_generic,
                   fsm_engine:run_fsm/4,
                   'fsm_engine:run_fsm/4',
                   fsm_engine,
                   run_fsm,
                   4).
fsm_engine_variant(strategy_high_level,
                   fsm_engine:run_strategy/4,
                   'fsm_engine:run_strategy/4',
                   fsm_engine,
                   run_strategy,
                   4).
fsm_engine_variant(dialectical_generic,
                   dialectical_engine:run_fsm/4,
                   'dialectical_engine:run_fsm/4',
                   dialectical_engine,
                   run_fsm,
                   4).

predicate_presence_witness(Module, Name, Arity,
                           _{ kind: loaded_predicate_presence,
                              module: Module,
                              name: Name,
                              arity: Arity,
                              descriptor: Module:Name/Arity,
                              properties: Properties }) :-
    variant_exists(Module, Name, Arity),
    predicate_properties(Module, Name, Arity, Properties).

predicate_properties(Module, Name, Arity, Properties) :-
    functor(Head, Name, Arity),
    findall(Property,
            predicate_registry_property(Module, Head, Property),
            Properties).

predicate_registry_property(Module, Head, defined) :-
    predicate_property(Module:Head, defined).
predicate_registry_property(Module, Head, exported) :-
    predicate_property(Module:Head, exported).
predicate_registry_property(Module, Head, interpreted) :-
    predicate_property(Module:Head, interpreted).
predicate_registry_property(Module, Head, static) :-
    predicate_property(Module:Head, static).

%! variant_exists(+Module, +Name, +Arity) is semidet.
%
%  True if Module:Name/Arity is a defined predicate. Guarded so a missing
%  module cannot throw; it simply makes the variant absent from the registry.
variant_exists(Module, Name, Arity) :-
    catch(
        ( current_predicate(Module:Name/Arity),
          functor(Head, Name, Arity),
          predicate_property(Module:Head, defined)
        ),
        _,
        fail
    ).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
%
%  Maps each scattered legacy functor to this family's canonical query name.
canonical_concept('fsm_engine:run_fsm/4',              fsm_engine).
canonical_concept('fsm_engine:run_strategy/4',         fsm_engine).
canonical_concept('dialectical_engine:run_fsm/4',      fsm_engine).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(fsm_engine,
    [ 'fsm_engine:run_fsm/4',
      'fsm_engine:run_strategy/4',
      'dialectical_engine:run_fsm/4' ]).
