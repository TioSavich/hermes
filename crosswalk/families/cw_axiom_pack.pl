/** <module> cw_axiom_pack — canonical query layer for axiom-pack enable/disable control
 *
 * Family: "Axiom-pack enable/disable control" (slug: axiom_pack).
 *
 * The sequent engine (arche-trace/sequent_engine.pl) gates which axiom sets
 * are part of the current "assumptive horizon" with a small family of
 * predicates over a dynamic store `axiom_pack_enabled/1`:
 *
 *   - axiom_pack_enabled/1  : the dynamic store (one fact per enabled pack)
 *   - enabled_axiom_pack/1  : pure read of that store
 *   - enable_axiom_pack/1   : SIDE-EFFECTING — asserts a pack enabled (throws on unknown)
 *   - disable_axiom_pack/1  : SIDE-EFFECTING — retracts a pack (throws on unknown)
 *   - with_axiom_packs/2    : EXECUTOR — runs Goal under a temporary pack set
 *
 * All five live in ONE module (sequent_engine), so unlike Wave 1's
 * incompatible/incoherent families there is no cross-module scatter to
 * reconcile. What scatters here instead is the KIND of predicate: only the
 * read side (enabled_axiom_pack/1, axiom_pack_enabled/1) is a pure, value-
 * returning query. The mutators (enable/disable) and the executor
 * (with_axiom_packs/2) have side effects and cannot be folded into a
 * side-effect-free union view.
 *
 * So this module does two things, honestly split:
 *
 *   1. axiom_pack_unified(?Pack, -Source) — a READ-ONLY union query over the
 *      pure enabled-state readers. It tells you which packs are currently
 *      enabled, tagging the source reader. It NEVER mutates state and NEVER
 *      runs an arbitrary Goal.
 *
 *   2. axiom_pack_control/4 — a registry mapping each side-effecting /
 *      executor variant to its module:functor/arity, so the family is fully
 *      enumerable without being callable through the union query. Callers who
 *      genuinely want to mutate pack state call the real predicate directly.
 *
 * Every source call is wrapped in catch(Goal, _, fail) so an absent or
 * erroring source contributes nothing. The union query is side-effect-free.
 *
 * Like crosswalk/canonical_vocabulary.pl, this does not rename or rewrite any
 * existing predicate. It adds a new read-only view plus a registry.
 */
:- module(cw_axiom_pack,
          [ axiom_pack_unified/2,   % axiom_pack_unified(?Pack, -Source)
            axiom_pack_witness/3,   % axiom_pack_witness(?Pack, ?Source, -Witness)
            axiom_pack_control/4,   % axiom_pack_control(?Variant, ?Module, ?Functor, ?Arity)
            axiom_pack_control_witness/5, % axiom_pack_control_witness(?Variant, ?Module, ?Functor, ?Arity, -Witness)
            canonical_concept/2,    % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2     % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

% The single owning module. Empty import list: we call module-qualified, so
% nothing is pulled into this module's namespace.
:- use_module(arche_trace(sequent_engine), []).

%! axiom_pack_unified(?Pack, ?Source) is nondet.
%
%  True when Pack is currently an enabled axiom pack according to ANY pure
%  reader of the enabled-state store. Source names the reader:
%   - enabled_predicate : sequent_engine:enabled_axiom_pack/1 (the exported read API)
%   - enabled_store     : sequent_engine:axiom_pack_enabled/1 (the dynamic store directly)
%
%  Both readers range over the same dynamic store, so they normally agree;
%  keeping both as tagged sources records that the read API and its backing
%  store are two named entry points to one fact set. Side-effect-free: this
%  only reads, never asserts/retracts, never calls an arbitrary Goal.
axiom_pack_unified(Pack, Source) :-
    axiom_pack_witness(Pack, Source, _).

%! axiom_pack_witness(?Pack, ?Source, -Witness) is nondet.
%
%  Witnessed enabled-pack read. This is the closed-world finite case for the
%  currently loaded `sequent_engine` axiom-pack state: visible packs are exactly
%  the packs proven by the exported reader or by the backing dynamic store.
axiom_pack_witness(
    Pack,
    enabled_predicate,
    WitnessDict76) :-
    witness_dict:witness_dict(axiom_pack_enabled_state, closed_world_finite_current_sequent_engine_axiom_packs,
                              _{pack: Pack,
       source: enabled_predicate,
       projection: exported_enabled_pack_reader,
       derivation: owner_predicate_state_read,
       source_witness: _{ kind: axiom_pack_reader_row,
                          module: sequent_engine,
                          predicate: enabled_axiom_pack/1,
                          pack: Pack } }, WitnessDict76),
    catch(sequent_engine:enabled_axiom_pack(Pack), _, fail).
axiom_pack_witness(
    Pack,
    enabled_store,
    WitnessDict90) :-
    witness_dict:witness_dict(axiom_pack_enabled_state, closed_world_finite_current_sequent_engine_axiom_packs,
                              _{pack: Pack,
       source: enabled_store,
       projection: dynamic_enabled_pack_store,
       derivation: owner_predicate_state_read,
       source_witness: _{ kind: axiom_pack_store_row,
                          module: sequent_engine,
                          predicate: axiom_pack_enabled/1,
                          pack: Pack } }, WitnessDict90),
    catch(sequent_engine:axiom_pack_enabled(Pack), _, fail).

%! axiom_pack_control(?Variant, ?Module, ?Functor, ?Arity) is nondet.
%
%  Registry of the side-effecting / executor members of the family that do NOT
%  belong in the read-only union query. Enumerable but not callable through
%  this layer: callers invoke Module:Functor/Arity directly when they intend
%  the side effect.
%   - enable  : asserts a pack enabled (throws domain_error on unknown pack)
%   - disable : retracts a pack (throws domain_error on unknown pack)
%   - scoped  : runs a Goal with a temporary enabled-pack set (setup_call_cleanup)
axiom_pack_control(Variant, Module, Functor, Arity) :-
    axiom_pack_control_witness(Variant, Module, Functor, Arity, _).

%! axiom_pack_control_witness(?Variant, ?Module, ?Functor, ?Arity, -Witness) is nondet.
%
%  Witnessed registry for side-effecting or goal-executing axiom-pack controls.
%  This proves that the named control surface is present in `sequent_engine`
%  without invoking it.
axiom_pack_control_witness(
    Variant,
    Module,
    Functor,
    Arity,
    WitnessDict124) :-
    witness_dict:witness_dict(axiom_pack_control_surface, closed_world_finite_sequent_engine_axiom_pack_controls,
                              _{variant: Variant,
       module: Module,
       functor: Functor,
       arity: Arity,
       source: control_registry,
       projection: side_effect_boundary_registry,
       derivation: current_predicate_control_surface_check,
       side_effect_policy: Policy,
       source_witness: _{ kind: axiom_pack_control_predicate,
                          module: Module,
                          predicate: Functor/Arity,
                          variant: Variant,
                          boundary: Boundary } }, WitnessDict124),
    axiom_pack_control_spec(Variant, Module, Functor, Arity, Policy, Boundary),
    current_predicate(Module:Functor/Arity).

axiom_pack_control_spec(enable, sequent_engine, enable_axiom_pack, 1,
                        mutates_enabled_pack_store,
                        asserts_known_pack_enabled).
axiom_pack_control_spec(disable, sequent_engine, disable_axiom_pack, 1,
                        mutates_enabled_pack_store,
                        retracts_known_pack_enabled).
axiom_pack_control_spec(scoped, sequent_engine, with_axiom_packs, 2,
                        executes_goal_under_temporary_pack_set,
                        setup_call_cleanup_restores_prior_pack_state).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
%
%  Maps each scattered legacy functor to its canonical entry point. The two
%  pure readers map to the union query axiom_pack_unified; the mutators and
%  executor map to the registry axiom_pack_control.
canonical_concept('sequent_engine:enabled_axiom_pack/1', axiom_pack_unified).
canonical_concept('sequent_engine:axiom_pack_enabled/1', axiom_pack_unified).
canonical_concept('sequent_engine:enable_axiom_pack/1',  axiom_pack_control).
canonical_concept('sequent_engine:disable_axiom_pack/1', axiom_pack_control).
canonical_concept('sequent_engine:with_axiom_packs/2',   axiom_pack_control).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(axiom_pack_unified,
    [ 'sequent_engine:enabled_axiom_pack/1',
      'sequent_engine:axiom_pack_enabled/1' ]).
vocabulary_source(axiom_pack_control,
    [ 'sequent_engine:enable_axiom_pack/1',
      'sequent_engine:disable_axiom_pack/1',
      'sequent_engine:with_axiom_packs/2' ]).
