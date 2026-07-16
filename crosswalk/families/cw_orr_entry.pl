/** <module> cw_orr_entry — registry for the "ORR-cycle entry point" family
 *
 * Concept family (slug: orr_entry): the predicates that ENTER the ORR cycle —
 * the top-level "run a computation, and on perturbation hand off to the
 * crisis/accommodation path" entry points. Two layers carry this concept:
 *
 *   - learner/execution_handler.pl  : the constructivist learner's ORR loop.
 *       run_computation/2     — public entry: solve Goal within inference Limit;
 *                               on error, retry through handle_perturbation/5.
 *       handle_perturbation/5 — crisis classifier/dispatcher (Error,Goal,Trace,
 *                               Limit,RetriesLeft); NOT exported, module-internal.
 *   - arche-trace/dialectical_engine.pl : the sequent-prover's ORR loop.
 *       run_computation/2     — public entry: prove Sequent within Limit;
 *                               on perturbation, accommodate then retry.
 *       handle_perturbation/3 — accommodation dispatcher (Error,Sequent,Limit);
 *                               NOT exported, module-internal.
 *
 * WHY registry_only, not a value-returning union query:
 *   These are EXECUTORS, not facts. run_computation/2 runs a bounded proof /
 * meta-interpretation, emits event-log entries, drives tension dynamics, and on
 * the crisis path retracts/asserts knowledge and may call a teacher/oracle.
 * handle_perturbation/N is its side-effecting continuation. There is no
 * truth-value here to range over and tag — calling these "to query the concept"
 * would fire the whole ORR machinery (and its side effects) as a side effect of
 * a lookup. That violates the side-effect-free contract for a canonical query.
 *
 *   So, honesty over force: this module does NOT call any of them. It exposes a
 * READ-ONLY REGISTRY mapping each scattered variant to its module:Functor/Arity,
 * the layer it belongs to, and its role (entry vs perturbation-handler), tagged
 * with -Source. The registry is verified live (catch-guarded current_predicate/
 * clause checks against the really-loaded modules), so a variant that is absent
 * or whose module failed to load simply does not appear.
 *
 * The two run_computation/2 are genuinely distinct predicates in distinct
 * modules (learner ORR over Goals vs sequent ORR over Sequents); they are NOT
 * renamed or merged here. Same name, two principled layers — the registry keeps
 * them distinct via the -Source tag.
 *
 * Pattern follows crosswalk/canonical_vocabulary.pl (wave 1): use_module each
 * real source with [] import list; catch-guarded, source-tagged clauses;
 * canonical_concept/2 + vocabulary_source/2 record the crosswalk.
 */
:- module(cw_orr_entry,
          [ orr_entry_unified/4,   % orr_entry_unified(-Variant, -PredIndicator, -Role, -Source)
            orr_entry_witness/5,   % orr_entry_witness(?Variant, ?PredIndicator, ?Role, ?Source, -Witness)
            canonical_concept/2,   % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2    % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

% Load the real owning modules with empty import lists (we only probe them by
% module-qualified name; nothing is pulled into this module's namespace).
% Both co-load cleanly (verified). If either fails to load, its registry rows
% are guarded out below and simply do not appear.
:- use_module(learner(execution_handler), []).
:- use_module(arche_trace(dialectical_engine), []).

%! orr_entry_unified(-Variant, -PredIndicator, -Role, -Source) is nondet.
%
%  Read-only registry of the ORR-cycle entry-point family. Each solution names
%  one scattered variant:
%   - Variant       : a stable atom id for the variant
%   - PredIndicator : Module:Functor/Arity (the real, untouched predicate)
%   - Role          : entry            — public top-level ORR entry point
%                     perturbation_handler — internal crisis/accommodation dispatcher
%   - Source        : learner_execution_handler | arche_trace_dialectical_engine
%
%  Side-effect-free: each row is gated by a witness that checks the loaded
%  predicate or internal clause. No ORR machinery runs.
orr_entry_unified(Variant, PredIndicator, Role, Source) :-
    orr_entry_witness(Variant, PredIndicator, Role, Source, _).

%! orr_entry_witness(?Variant, ?PredIndicator, ?Role, ?Source, -Witness) is nondet.
%
%  Witnessed form of `orr_entry_unified/4`. This is a closed-world finite
%  registry over the currently loaded ORR entry points and perturbation
%  handlers. The witness proves only registry membership and loaded predicate
%  presence; it deliberately does not invoke any entry point because these
%  predicates run bounded computation, emit events, consult recovery paths, and
%  may mutate learner state.
orr_entry_witness(Variant, PredIndicator, Role, Source,
                  _{ kind: orr_entry_registry_entry,
                     scope: closed_world_finite_loaded_orr_entry_registry,
                     variant: Variant,
                     predicate: PredIndicator,
                     role: Role,
                     source: Source,
                     legacy_functor: LegacyFunctor,
                     invocation_policy: registry_only_no_orr_execution,
                     side_effect_boundary: SideEffectBoundary,
                     target_visibility: Visibility,
                     target_witness: TargetWitness }) :-
    registry(Variant,
             PredIndicator,
             Role,
             Source,
             LegacyFunctor,
             SideEffectBoundary,
             Visibility),
    target_presence_witness(PredIndicator, Visibility, TargetWitness).

registry(eh_run_computation,
         execution_handler:run_computation/2,
         entry,
         learner_execution_handler,
         'execution_handler:run_computation/2',
         bounded_meta_interpreter_event_log_teacher_recovery,
         exported_predicate).
registry(eh_handle_perturbation,
         execution_handler:handle_perturbation/5,
         perturbation_handler,
         learner_execution_handler,
         'execution_handler:handle_perturbation/5',
         crisis_classification_recovery_state_and_teacher_path,
         module_internal_clause).
registry(de_run_computation,
         dialectical_engine:run_computation/2,
         entry,
         arche_trace_dialectical_engine,
         'dialectical_engine:run_computation/2',
         bounded_embodied_prover_critique_retry_loop,
         exported_predicate).
registry(de_handle_perturbation,
         dialectical_engine:handle_perturbation/3,
         perturbation_handler,
         arche_trace_dialectical_engine,
         'dialectical_engine:handle_perturbation/3',
         critique_accommodation_retry_loop,
         module_internal_clause).

target_presence_witness(Module:Name/Arity,
                        Visibility,
                        _{ kind: loaded_orr_entry_target,
                           module: Module,
                           name: Name,
                           arity: Arity,
                           visibility: Visibility,
                           properties: Properties }) :-
    once(target_present(Module, Name, Arity, Visibility)),
    findall(Property,
            target_property(Module, Name, Arity, Property),
            Properties0),
    sort(Properties0, Properties).

target_present(Module, Name, Arity, exported_predicate) :-
    catch(current_predicate(Module:Name/Arity), _, fail),
    functor(Head, Name, Arity),
    catch(predicate_property(Module:Head, exported), _, fail).
target_present(Module, Name, Arity, module_internal_clause) :-
    functor(Head, Name, Arity),
    catch(clause(Module:Head, _), _, fail).

target_property(Module, Name, Arity, defined) :-
    functor(Head, Name, Arity),
    predicate_property(Module:Head, defined).
target_property(Module, Name, Arity, exported) :-
    functor(Head, Name, Arity),
    predicate_property(Module:Head, exported).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
%
%  Maps each scattered legacy functor to its canonical registry term.
canonical_concept('execution_handler:run_computation/2',      orr_entry).
canonical_concept('execution_handler:handle_perturbation/5',  orr_entry).
canonical_concept('dialectical_engine:run_computation/2',     orr_entry).
canonical_concept('dialectical_engine:handle_perturbation/3', orr_entry).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(orr_entry,
    [ 'execution_handler:run_computation/2',
      'execution_handler:handle_perturbation/5',
      'dialectical_engine:run_computation/2',
      'dialectical_engine:handle_perturbation/3' ]).
