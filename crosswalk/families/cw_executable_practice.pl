/** <module> cw_executable_practice — registry for the "executable practice/strategy" family
 *
 * Concept family (slug: executable_practice): the predicates that name or carry
 * a mathematical practice/strategy as something that can be EXECUTED or LISTED.
 * Three layers carry this concept, at different arities and with different
 * ontological status:
 *
 *   - learner/more_machine_learner.pl
 *       run_learned_strategy/5  — the executable strategy hierarchy. A DYNAMIC,
 *           side-effecting executor: each clause is a learned FSM
 *           (A,B,Result,StrategyName,Trace) the meta-interpreter calls to
 *           actually run a computation and emit a trace. Empty at load time;
 *           clauses are asserted as the learner learns. Exported.
 *   - learner/oracle_server.pl
 *       list_available_strategies/2 — list_available_strategies(+Operation,
 *           -Strategies): the oracle's catalogue of expert strategy NAMES per
 *           operation (add/subtract/multiply/divide/fraction). Det fact table.
 *           Exported.
 *   - pml/mua_relations.pl
 *       practice/2 — practice(?PracticeId, ?Description): the MUA-layer registry
 *           of practice kinds (one per action-automaton kind), each with a
 *           one-line gloss. Fact table. Exported.
 *
 * WHY registry_only, not a single value-returning union query:
 *   The three are ontologically heterogeneous and one is a side-effecting
 * executor. run_learned_strategy/5 is not a fact to range over — calling it
 * RUNS a learned FSM (and emits a trace); it is also dynamic and empty at load,
 * so there is nothing to enumerate as a "value" at query time. list_available_
 * strategies/2 returns a LIST of strategy-name atoms keyed by operation;
 * practice/2 returns a (PracticeId, Description) pair. There is no common value
 * shape to unify, and forcing one would either fire the executor as a side
 * effect of a lookup or flatten three different ontic kinds into a lossy tuple.
 *
 *   So, honesty over force (same call the orr_entry family made): this module
 * does NOT call run_learned_strategy/5. It exposes a READ-ONLY REGISTRY mapping
 * each scattered variant to its Module:Functor/Arity, the layer it belongs to,
 * and its Kind (executor vs catalogue vs registry-fact), tagged with -Source.
 * The registry is existence-checked live (catch-guarded current_predicate/2
 * against the really-loaded modules), so a variant whose module failed to load
 * simply does not appear. No practice is ever executed.
 *
 * Projection note: the canonical predicate's shape is
 *   executable_practice_unified(-Variant, -PredIndicator, -Kind, -Source)
 * i.e. a registry row, NOT a (practice, value) pair. Kind records how the
 * variant denotes a practice:
 *   executor        — a callable that runs a strategy (run_learned_strategy/5)
 *   name_catalogue  — lists strategy NAMES per operation (list_available_strategies/2)
 *   registry_fact   — names a practice kind with a gloss (practice/2)
 *
 * Pattern follows crosswalk/canonical_vocabulary.pl (wave 1) and
 * crosswalk/families/cw_orr_entry.pl: use_module each real source with []
 * import list; catch-guarded, source-tagged clauses; canonical_concept/2 +
 * vocabulary_source/2 record the crosswalk. Nothing is renamed or merged.
 *
 * Name-scope note: the `executable_practice` slug overstates the family. Of the
 * three variants only run_learned_strategy/5 is executable; list_available_
 * strategies/2 is a name catalogue and practice/2 is a static registry fact,
 * and neither runs. The canonical predicate is a read-only registry recording
 * each variant's Kind (executor, name_catalogue, registry_fact); it executes no
 * practice. Read `executable_practice` as the practice/strategy family some of
 * whose members are executable, not as a claim that every member runs.
 */
:- module(cw_executable_practice,
          [ executable_practice_unified/4, % (-Variant, -PredIndicator, -Kind, -Source)
            executable_practice_witness/5, % (?Variant, ?PredIndicator, ?Kind, ?Source, -Witness)
            canonical_concept/2,           % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2            % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

% Load the real owning modules with empty import lists (we only probe them by
% module-qualified name; nothing is pulled into this module's namespace).
% All three co-load cleanly (verified). If any fails to load, its registry rows
% are guarded out below via current_predicate/2 and simply do not appear.
:- use_module(learner(more_machine_learner), []).
:- use_module(learner(oracle_server), []).
:- use_module(pml(mua_relations), []).

%! executable_practice_unified(-Variant, -PredIndicator, -Kind, -Source) is nondet.
%
%  Read-only registry of the executable-practice family. Each solution names one
%  scattered variant:
%   - Variant       : a stable atom id for the variant
%   - PredIndicator : Module:Functor/Arity (the real, untouched predicate)
%   - Kind          : executor | name_catalogue | registry_fact (see module header)
%   - Source        : more_machine_learner | oracle_server | mua_relations
%
%  Side-effect-free: each row is gated by a witness against the loaded module.
%  No practice is executed; the dynamic, side-effecting run_learned_strategy/5
%  is only probed for predicate presence.
executable_practice_unified(Variant, PredIndicator, Kind, Source) :-
    executable_practice_witness(Variant, PredIndicator, Kind, Source, _).

%! executable_practice_witness(?Variant, ?PredIndicator, ?Kind, ?Source, -Witness) is nondet.
%
%  Witnessed form of `executable_practice_unified/4`. This is a closed-world
%  finite registry over currently loaded executable-practice surfaces. It proves
%  row membership and source evidence only. It does not call
%  `run_learned_strategy/5`, because that predicate runs learned strategy clauses
%  when such clauses exist.
executable_practice_witness(Variant, PredIndicator, Kind, Source,
                            WitnessDict101) :-
    witness_dict:witness_dict(executable_practice_registry_entry, closed_world_finite_loaded_executable_practice_registry,
                              _{variant: Variant,
                               predicate: PredIndicator,
                               practice_kind: Kind,
                               source: Source,
                               legacy_functor: LegacyFunctor,
                               invocation_policy: InvocationPolicy,
                               source_witness: SourceWitness }, WitnessDict101),
    source_executable_practice_witness(Variant,
                                       PredIndicator,
                                       Kind,
                                       Source,
                                       LegacyFunctor,
                                       InvocationPolicy,
                                       SourceWitness).

source_executable_practice_witness(
    mml_run_learned_strategy,
    more_machine_learner:run_learned_strategy/5,
    executor,
    more_machine_learner,
    'more_machine_learner:run_learned_strategy/5',
    registry_only_no_strategy_execution,
    _{ kind: dynamic_executor_presence,
       module: more_machine_learner,
       predicate: run_learned_strategy/5,
       visibility: exported_predicate,
       dynamic: true,
       learned_clause_count: ClauseCount,
       properties: Properties }) :-
    predicate_presence_witness(more_machine_learner, run_learned_strategy, 5, Properties),
    count_learned_strategy_clauses(ClauseCount).
source_executable_practice_witness(
    oracle_list_available_strategies,
    oracle_server:list_available_strategies/2,
    name_catalogue,
    oracle_server,
    'oracle_server:list_available_strategies/2',
    read_only_catalogue_query,
    _{ kind: oracle_strategy_catalogue,
       module: oracle_server,
       predicate: list_available_strategies/2,
       operations: Operations,
       catalogue_size: CatalogueSize,
       sample_operation: add,
       sample_strategies: AddStrategies,
       properties: Properties }) :-
    predicate_presence_witness(oracle_server, list_available_strategies, 2, Properties),
    findall(Operation-Strategies,
            catch(oracle_server:list_available_strategies(Operation, Strategies), _, fail),
            Rows),
    pairs_keys(Rows, Operations),
    length(Rows, CatalogueSize),
    memberchk(add-AddStrategies, Rows).
source_executable_practice_witness(
    mua_practice,
    mua_relations:practice/2,
    registry_fact,
    mua_relations,
    'mua_relations:practice/2',
    read_only_registry_fact_query,
    _{ kind: mua_practice_registry,
       module: mua_relations,
       predicate: practice/2,
       sample_practice: p_count_on_from_larger,
       sample_description: Description,
       sample_operation: Operation,
       sample_action_kind: ActionKind,
       practice_count: PracticeCount,
       mapped_practice_count: MappedPracticeCount,
       properties: Properties }) :-
    predicate_presence_witness(mua_relations, practice, 2, Properties),
    catch(mua_relations:practice(p_count_on_from_larger, Description), _, fail),
    catch(mua_relations:practice_kind(p_count_on_from_larger, Operation, ActionKind), _, fail),
    findall(Practice, catch(mua_relations:practice(Practice, _), _, fail), Practices),
    sort(Practices, UniquePractices),
    length(UniquePractices, PracticeCount),
    findall(MappedPractice,
            catch(mua_relations:practice_kind(MappedPractice, _, _), _, fail),
            MappedPractices),
    sort(MappedPractices, UniqueMappedPractices),
    length(UniqueMappedPractices, MappedPracticeCount).

predicate_presence_witness(Module, Name, Arity, Properties) :-
    catch(current_predicate(Module:Name/Arity), _, fail),
    findall(Property,
            predicate_presence_property(Module, Name, Arity, Property),
            Properties0),
    sort(Properties0, Properties).

predicate_presence_property(Module, Name, Arity, defined) :-
    functor(Head, Name, Arity),
    predicate_property(Module:Head, defined).
predicate_presence_property(Module, Name, Arity, exported) :-
    functor(Head, Name, Arity),
    predicate_property(Module:Head, exported).
predicate_presence_property(Module, Name, Arity, dynamic) :-
    functor(Head, Name, Arity),
    predicate_property(Module:Head, dynamic).

count_learned_strategy_clauses(Count) :-
    findall(1,
            catch(clause(more_machine_learner:run_learned_strategy(_, _, _, _, _), _), _, fail),
            Ones),
    length(Ones, Count).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
%
%  Maps each scattered legacy functor to its canonical registry term.
canonical_concept('more_machine_learner:run_learned_strategy/5', executable_practice).
canonical_concept('oracle_server:list_available_strategies/2',   executable_practice).
canonical_concept('mua_relations:practice/2',                    executable_practice).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(executable_practice,
    [ 'more_machine_learner:run_learned_strategy/5',
      'oracle_server:list_available_strategies/2',
      'mua_relations:practice/2' ]).
