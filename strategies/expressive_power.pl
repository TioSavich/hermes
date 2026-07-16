/** <module> Expressive power: finite measures of a vocabulary's inferential reach
 *
 * This module makes one manuscript idea computable on a finite system: the
 * *expressive power* a piece of mathematical vocabulary carries, measured two
 * ways that the project already has engines for.
 *
 * 1. PROOF-PATHS (the "inversion"). How many goal-reaching paths exist through
 *    the strategy-naive action machine for a region of the action space. This
 *    is the inverted reading of a predicate: not "is this fact derivable" but
 *    "how many ways is it derivable". Backed by carving_strategy_machine:all_paths/6.
 *
 * 2. INCOMPATIBILITIES (the "cheese-grater"). How many other commitments or
 *    discovered bounded sets a piece of vocabulary is materially incompatible
 *    with — how many holes its content excludes. Backed by
 *    misconception_registry:incompatibility_with/2 and the bounded
 *    arche-trace incompatibility-set surface.
 *
 * The two measures are deliberately NOT collapsed into one number. Path-power is
 * a property of a region of the action space (an operation at a level); the
 * incompatibility count is a property of a named strategy or misconception. A
 * lesson puts both kinds of expressive power in play, and this module reports
 * them side by side.
 *
 * SCOPE AND HONESTY. These predicates compute closed-world finite measures.
 * Path counts are comparative, not absolute: all_paths/6 retains oscillating
 * paths within the bound, so the raw total grows with the bound. The bound and
 * action-space range are fixed (operation_default/3) so comparisons across
 * lessons use the same yardstick. Addition/subtraction use the strategy-naive
 * carving machine; multiplication/division use the composite-unit groups
 * machine; fraction uses the unified units machine at the fraction-capable
 * rung. Decimal, geometry, and other action-registry operations still carry
 * incompatibility counts, but they report `no_path_measure` until a
 * corresponding operation model is wired.
 * "Expressive power grown in a lesson" is computed here as the expressive power
 * the lesson's target vocabulary PUTS IN PLAY. A true before/after delta would
 * need a model of the learner's prior vocabulary state, which the system does
 * not yet carry; lesson_expressive_power_delta/2 documents that gap rather than
 * faking a baseline.
 */
:- module(expressive_power,
          [ path_power/6,                  % +Op,+A,+B,+Level,+Bound,-power_paths(Total,DistinctCosts,MinCost)
            path_power_witness/6,          % +Op,+A,+B,+Level,+Bound,-Witness
            operation_path_power/5,        % +Op,+Level,+Bound,+MaxAddend,-region_paths(Total,Cells,SumDistinctCosts)
            operation_path_power_witness/5,% +Op,+Level,+Bound,+MaxAddend,-Witness
            incompatibility_power/2,       % +Target,-Count
            incompatibility_power_witness/2,% +Target,-Witness
            target_expressive_power/2,     % +Target,-expressive_power(Target,Paths,Incompat)
            target_expressive_power_witness/2,% +Target,-Witness
            lesson_expressive_power/4,     % +Ops,+Strategies,+Misconceptions,-Report
            lesson_expressive_power_for/2, % +LessonCode,-Report   (pulls vocabulary from lesson_monitoring if loaded)
            lesson_expressive_power_delta/2,% +LessonCode,-Delta    (needs learner pre-state)
            commensurate_lesson/3,         % ?IMCode,?TraditionalCode,?Standard
            expressive_power_comparison/4, % +Standard,-IMReport,-TraditionalReport,-Delta
            expressive_power_comparison_report/1,% -Report
            expressive_power_wiring_audit/1,% -Rows
            expressive_power_comparison_json/1,  % -JSONDict
            write_expressive_power_comparison_json/1
          ]).

:- use_module(carving(strategy_machine), [ all_paths/6 ]).
:- use_module(carving(groups_machine), []).
:- use_module(carving(units_machine), []).
:- use_module(arche_trace(incompatibility_discovery),
              [ candidate_set/2,
                classify_candidate_set/3
              ]).
:- use_module(misconceptions(misconception_registry),
              [ incompatibility_with/2,
                incompatibility_with_witness/3
              ]).
:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(aggregate)).
:- use_module(library(http/json)).

%!  operation_default(-Bound, -MaxAddend, -Level) is det.
%
%   The fixed yardstick for path-power so lesson-to-lesson comparisons use the
%   same bound and action-space range. Bounded small for tractability.
operation_default(8, 3, 1).

%!  machine_op(+VocabularyOp, -MachineOp) is semidet.
%
%   Bridges the strategy/lesson vocabulary (addition, subtraction) to the
%   action machine's operation atoms (add, sub).
machine_op(add, add).
machine_op(addition, add).
machine_op(sub, sub).
machine_op(subtraction, sub).

groups_machine_op(mult).
groups_machine_op(multiplication).
groups_machine_op(div).
groups_machine_op(division).

units_machine_op(frac).
units_machine_op(fraction).


%!  path_power(+Op, +A, +B, +Level, +Bound, -Power) is det.
%
%   Power = power_paths(Total, DistinctCosts, MinCost). Total is every
%   goal-reaching path within Bound moves (the inversion count). DistinctCosts
%   is how many qualitatively different efficiency tiers reach the goal — a
%   more strategy-meaningful number than the inflated raw Total. MinCost is the
%   cheapest route.
path_power(Op, A, B, Level, Bound, Power) :-
    path_power_witness(Op, A, B, Level, Bound, Witness),
    get_dict(power, Witness, Power).


%!  path_power_witness(+Op, +A, +B, +Level, +Bound, -Witness) is det.
%
%   Witness explains the closed-world finite path count for one bounded cell
%   of the carving strategy machine.
path_power_witness(Op, A, B, Level, Bound,
                   _{ kind: path_power,
                      source: carving_strategy_machine,
                      scope: closed_world_finite_carving_region,
                      operation: Op,
                      region: cell(A, B),
                      level: Level,
                      bound: Bound,
                      power: power_paths(Total, DistinctCosts, MinCost),
                      counts: _{ total_paths: Total,
                                 distinct_costs: DistinctCosts,
                                 min_cost: MinCost },
                      costs: SortedCosts,
                      sample_paths: SamplePaths }) :-
    all_paths(Op, A, B, Level, Bound, Paths),
    length(Paths, Total),
    findall(C, member(path(C, _), Paths), Costs),
    sort(Costs, SortedCosts),
    length(SortedCosts, DistinctCosts),
    ( SortedCosts = [MinCost|_] -> true ; MinCost = none ),
    first_n(3, Paths, SamplePaths).


%!  operation_path_power(+Op, +Level, +Bound, +MaxAddend, -Region) is det.
%
%   Region = region_paths(TotalPaths, Cells, SumDistinctCosts). Sums path-power
%   over the A,B in 0..MaxAddend square of the action space. This is the
%   path-expressive-power of an operation in a bounded region: how much
%   strategic room the operation opens up.
operation_path_power(Op, Level, Bound, MaxAddend, Region) :-
    operation_path_power_witness(Op, Level, Bound, MaxAddend, Witness),
    get_dict(power, Witness, Region).


%!  operation_path_power_witness(+Op, +Level, +Bound, +MaxAddend, -Witness) is det.
%
%   Witness explains the bounded region aggregate used for lesson comparisons.
operation_path_power_witness(Op, Level, Bound, MaxAddend,
                             _{ kind: operation_path_power,
                                source: carving_strategy_machine,
                                scope: closed_world_finite_carving_region,
                                operation: Op,
                                level: Level,
                                bound: Bound,
                                max_addend: MaxAddend,
                                power: region_paths(TotalPaths,
                                                    Cells,
                                                    SumDistinctCosts),
                                counts: _{ total_paths: TotalPaths,
                                           cells: Cells,
                                           sum_distinct_costs: SumDistinctCosts },
                                cell_witnesses: CellWitnesses }) :-
    findall(Total-DistinctCosts,
            ( between(0, MaxAddend, A),
              between(0, MaxAddend, B),
              path_power(Op, A, B, Level, Bound, power_paths(Total, DistinctCosts, _))
            ),
            Pairs),
    findall(CellWitness,
            ( between(0, MaxAddend, A),
              between(0, MaxAddend, B),
              path_power_witness(Op, A, B, Level, Bound, CellWitness)
            ),
            CellWitnesses),
    length(Pairs, Cells),
    ( Pairs == []
    ->  TotalPaths = 0, SumDistinctCosts = 0
    ;   aggregate_all(sum(T), member(T-_, Pairs), TotalPaths),
        aggregate_all(sum(D), member(_-D, Pairs), SumDistinctCosts)
    ).


operation_path_power_for_vocabulary(Op, Level, Bound, MaxAddend, Region) :-
    operation_path_power_for_vocabulary_witness(Op, Level, Bound, MaxAddend, Witness),
    get_dict(power, Witness, Region).


operation_path_power_for_vocabulary_witness(Op, Level, Bound, MaxAddend, Witness) :-
    machine_op(Op, MachineOp),
    operation_path_power_witness(MachineOp, Level, Bound, MaxAddend, Witness0),
    Witness = Witness0.put(_{ vocabulary_operation: Op,
                              machine_operation: MachineOp }),
    !.
operation_path_power_for_vocabulary_witness(Op, _Level, Bound, MaxAddend,
        _{ kind: operation_path_power,
           source: groups_machine,
           scope: closed_world_finite_carving_region,
           operation: Op,
           stage: l2,
           bound: Bound,
           max_addend: MaxAddend,
           power: region_paths(Reached, Cells, Reached),
           counts: _{ reachable_cells: Reached,
                      cells: Cells,
                      sum_distinct_costs: Reached },
           cell_witnesses: SampleWitnesses }) :-
    groups_machine_op(Op),
    group_region_witnesses(l2, Bound, MaxAddend, CellWitnesses, Cells),
    length(CellWitnesses, Reached),
    first_n(3, CellWitnesses, SampleWitnesses),
    Reached > 0,
    !.
operation_path_power_for_vocabulary_witness(Op, _Level, Bound, MaxAddend,
        _{ kind: operation_path_power,
           source: units_machine,
           scope: closed_world_finite_carving_region,
           operation: Op,
           stage: s3,
           bound: Bound,
           max_addend: MaxAddend,
           power: region_paths(Reached, Cells, Reached),
           counts: _{ reachable_cells: Reached,
                      cells: Cells,
                      sum_distinct_costs: Reached },
           cell_witnesses: SampleWitnesses }) :-
    units_machine_op(Op),
    units_fraction_region_witnesses(s3, Bound, MaxAddend, CellWitnesses, Cells),
    length(CellWitnesses, Reached),
    first_n(3, CellWitnesses, SampleWitnesses),
    Reached > 0,
    !.


group_region_witnesses(Stage, Bound, MaxAddend, CellWitnesses, Cells) :-
    MaxUnit is MaxAddend + 1,
    MaxCount is MaxAddend + 1,
    Cells is (MaxUnit - 1) * MaxCount,
    findall(_{ unit: Unit,
               target: Target,
               cost: Cost,
               witness: Witness,
               strategy: Strategy },
            ( between(2, MaxUnit, Unit),
              between(1, MaxCount, Count),
              Target is Unit * Count,
              groups_machine:g_min_cost(Stage, Unit, Target, Bound, Cost, Witness),
              groups_machine:g_strategy(Witness, Strategy)
            ),
            CellWitnesses).


units_fraction_region_witnesses(Stage, Bound, MaxAddend, CellWitnesses, Cells) :-
    units_fraction_targets(MaxAddend, Targets),
    length(Targets, Cells),
    findall(_{ target: Target,
               cost: Cost,
               witness: Witness,
               strategy: Strategy },
            ( member(Target, Targets),
              units_machine:u_min_cost(Stage, Target, Bound, Cost, Witness),
              units_machine:u_strategy(Witness, Strategy)
            ),
            CellWitnesses).


units_fraction_targets(MaxAddend, Targets) :-
    MaxDenominator is MaxAddend + 2,
    findall(Target,
            ( between(2, MaxDenominator, Denominator),
              MaxNumerator is Denominator + 1,
              between(1, MaxNumerator, Numerator),
              Target is Numerator rdiv Denominator
            ),
            Targets0),
    sort(Targets0, Targets).


%!  incompatibility_power(+Target, -Count) is det.
%
%   The cheese-grater count: how many DISTINCT commitments or discovered
%   bounded sets Target is materially incompatible with. Tries the bare term
%   and the misconception(_) wrapper so a lesson can pass a bare misconception
%   name. Count is 0 when nothing is registered or discovered.
incompatibility_power(Target, Count) :-
    incompatibility_power_witness(Target, Witness),
    get_dict(count, Witness, Count).


%!  incompatibility_power_witness(+Target, -Witness) is det.
%
%   Witness explains the closed-world finite incompatibility count from the
%   misconception registry plus bounded Big Red discovery contexts.
incompatibility_power_witness(Target,
                              _{ kind: incompatibility_power,
                                 target: Target,
                                 scope: closed_world_finite_registry_and_bounded_discovery,
                                 count: Count,
                                 conflicts: Conflicts,
                                 registry_witnesses: RegistryWitnesses,
                                 discovered_witnesses: DiscoveredWitnesses }) :-
    findall(Conflict-Witness,
            registry_target_witness(Target, Conflict, Witness),
            RegistryPairs0),
    sort(RegistryPairs0, RegistryPairs),
    pairs_keys(RegistryPairs, RegistryConflicts),
    pairs_values(RegistryPairs, RegistryWitnesses),
    findall(discovered_set(Context, Set)-DiscoveryWitness,
            discovered_target_set_witness(Target, Context, Set, DiscoveryWitness),
            DiscoveredPairs0),
    sort(DiscoveredPairs0, DiscoveredPairs),
    pairs_keys(DiscoveredPairs, DiscoveredConflicts),
    pairs_values(DiscoveredPairs, DiscoveredWitnesses),
    append(RegistryConflicts, DiscoveredConflicts, Conflicts0),
    sort(Conflicts0, Conflicts),
    length(Conflicts, Count).

discovered_target_set(Target, Context, Set) :-
    discovered_target_set_witness(Target, Context, Set, _).


discovered_target_set_witness(Target, Context, Set,
                              _{ kind: bounded_discovery_incompatibility_set,
                                 target: Target,
                                 context: Context,
                                 set: Set,
                                 outcome: Outcome,
                                 source: big_red_bounded_discovery }) :-
    discovered_context_for_target(Target, Context),
    target_candidate_set(Target, Context, Set),
    classify_candidate_set(Context, Set, Outcome),
    discovered_outcome(Outcome).


target_candidate_set(Target, registry_neighborhood, Set) :-
    !,
    registry_target_candidate_set(Target, Set).
target_candidate_set(Target, Context, Set) :-
    candidate_set(Context, Set),
    target_member(Target, Set).


registry_target_candidate_set(Target, Set) :-
    target_registry_term(Target, RegistryTerm),
    registry_neighbor(RegistryTerm, Neighbor),
    sort([RegistryTerm, Neighbor], Set).


target_registry_term(Target, Target).
target_registry_term(Target, misconception(Target)) :-
    atom(Target).


registry_neighbor(Term, Neighbor) :-
    incompatibility_with(Term, Neighbor).


registry_target_witness(Target, Conflict, Witness) :-
    incompatibility_with_witness(Target, Conflict, Witness).
registry_target_witness(Target, Conflict, Witness) :-
    atom(Target),
    incompatibility_with_witness(misconception(Target), Conflict, Witness).


discovered_outcome(incoherent(_)).
discovered_outcome(nonterminating(_)).


discovered_context_for_target(rule(loop_self), finite_loop_program) :-
    !.
discovered_context_for_target(rule(_), finite_three_rule_program) :-
    !.
discovered_context_for_target(_Target, registry_neighborhood).


target_member(Target, Set) :-
    member(Term, Set),
    target_matches(Target, Term),
    !.


target_matches(Target, Term) :-
    Target == Term,
    !.
target_matches(Target, misconception(Target)) :-
    atom(Target).


%!  target_expressive_power(+Target, -Power) is det.
%
%   Power = expressive_power(Target, PathsTerm, IncompatCount). Strategy targets
%   strategy(Op,Kind) get a region path-power; everything else (misconceptions,
%   geometry concepts) gets no_path_measure, since they do not name a productive
%   region of the whole-number action machine.
target_expressive_power(Target, Power) :-
    target_expressive_power_witness(Target, Witness),
    get_dict(power, Witness, Power).


%!  target_expressive_power_witness(+Target, -Witness) is det.
%
%   Witness combines the target's bounded path surface, when available, with
%   the finite incompatibility witness.
target_expressive_power_witness(Target,
                                _{ kind: target_expressive_power,
                                   target: Target,
                                   scope: closed_world_finite_expressive_power,
                                   power: expressive_power(Target,
                                                           PathsTerm,
                                                           Incompat),
                                   path_witness: PathWitness,
                                   incompatibility_witness: IncompatibilityWitness }) :-
    incompatibility_power_witness(Target, IncompatibilityWitness),
    get_dict(count, IncompatibilityWitness, Incompat),
    target_paths_witness(Target, PathsTerm, PathWitness).

target_paths_witness(strategy(Op, Kind), PathsTerm, PathWitness) :-
    operation_default(Bound, MaxAddend, Level),
    operation_path_power_for_vocabulary_witness(Op, Level, Bound, MaxAddend, PathWitness0),
    get_dict(power, PathWitness0, PathsTerm),
    PathsTerm = region_paths(Total, _, _),
    Total > 0,
    PathWitness = PathWitness0.put(_{ target: strategy(Op, Kind),
                                      vocabulary_operation: Op }),
    !.
target_paths_witness(Target, no_path_measure,
                     _{ kind: no_path_measure,
                        target: Target,
                        source: carving_strategy_machine,
                        reason: no_supported_operation_model,
                        scope: closed_world_finite_carving_region }).


first_n(N, List, Prefix) :-
    length(Prefix, N),
    append(Prefix, _, List),
    !.
first_n(_, List, List).


%!  lesson_expressive_power(+Ops, +Strategies, +Misconceptions, -Report) is det.
%
%   Report aggregates the expressive power a lesson's vocabulary puts in play.
%   Ops is the list of operations the lesson exercises; Strategies is a list of
%   strategy(Op,Kind); Misconceptions is a list of bare misconception names.
lesson_expressive_power(Ops, Strategies, Misconceptions,
        report(paths(TotalPaths),
               strategy_incompatibility(StrategyIncompat),
               misconception_incompatibility(MiscIncompat),
               per_operation(OpPowers),
               per_strategy(StrategyPowers),
               per_misconception(MiscPowers))) :-
    operation_default(Bound, MaxAddend, Level),
    findall(Op-Region,
            ( member(Op, Ops),
              operation_path_power_for_vocabulary(Op, Level, Bound, MaxAddend, Region)
            ),
            OpPowers),
    ( OpPowers == []
    ->  TotalPaths = 0
    ;   aggregate_all(sum(P),
                      member(_-region_paths(P, _, _), OpPowers),
                      TotalPaths)
    ),
    maplist(target_expressive_power, Strategies, StrategyPowers),
    sum_incompat(StrategyPowers, StrategyIncompat),
    findall(Name-N,
            ( member(Name, Misconceptions),
              incompatibility_power(Name, N)
            ),
            MiscPowers),
    ( MiscPowers == []
    ->  MiscIncompat = 0
    ;   aggregate_all(sum(N), member(_-N, MiscPowers), MiscIncompat)
    ).

sum_incompat(StrategyPowers, Sum) :-
    ( StrategyPowers == []
    ->  Sum = 0
    ;   aggregate_all(sum(I),
                      member(expressive_power(_, _, I), StrategyPowers),
                      Sum)
    ).


%!  lesson_expressive_power_for(+LessonCode, -Report) is det.
%
%   Pulls the lesson's strategies and misconceptions from lesson_monitoring (if
%   that module is loaded) and computes the lesson's expressive power. Returns
%   lesson_monitoring_not_loaded when the chart module is unavailable, so this
%   module stays loadable on its own.
lesson_expressive_power_for(LessonCode, Report) :-
    ( current_predicate(lesson_monitoring:lesson_strategy/4),
      current_predicate(lesson_monitoring:lesson_misconception/4)
    ->  findall(strategy(Op, Kind),
                lesson_monitoring:lesson_strategy(LessonCode, Op, Kind, _),
                Strategies0),
        sort(Strategies0, Strategies),
        findall(Name,
                lesson_monitoring:lesson_misconception(LessonCode, _, Name, _),
                Misconceptions0),
        sort(Misconceptions0, Misconceptions),
        findall(Op, member(strategy(Op, _), Strategies), Ops0),
        sort(Ops0, Ops),
        lesson_expressive_power(Ops, Strategies, Misconceptions, Report)
    ;   Report = lesson_monitoring_not_loaded
    ).


%!  lesson_expressive_power_delta(+LessonCode, -Delta) is det.
%
%   Boundary: a measured expressive-power delta is (power after the lesson)
%   minus (power the learner already held). The system has no learner pre-state
%   model, so a measured baseline cannot be computed here. This returns the
%   in-play power tagged as the upper bound of what the lesson could grow, with
%   the missing baseline named explicitly. Do not report this as a measured
%   delta.
lesson_expressive_power_delta(LessonCode,
        delta(in_play(Report),
              baseline(unmodelled_learner_prior_state),
              note('in_play is the expressive power the lesson puts in reach; \c
                    a measured delta needs a learner pre-state the system does not carry'))) :-
    lesson_expressive_power_for(LessonCode, Report).


%!  commensurate_lesson(?IMCode, ?TraditionalCode, ?Standard) is nondet.
%
%   Curated standard-matched pairs for the comparison run. Each pair is checked
%   against lesson_monitoring:lesson_standard/4 on both sides so a stale or
%   mismatched explicit pairing fails instead of silently reporting.
commensurate_lesson(IMCode, TraditionalCode, Standard) :-
    curated_commensurate_lesson(IMCode, TraditionalCode, Standard),
    once(lesson_has_standard(IMCode, Standard)),
    once(lesson_has_standard(TraditionalCode, Standard)).

curated_commensurate_lesson('IM-G1-U3-L17',
                            'TRAD-RAY-G1-OA-C6-ADD-FACTS',
                            standard(ccss, '1.OA.C.6')).
curated_commensurate_lesson('IM-G2-U2-L7',
                            'TRAD-RAY-G2-NBT-B5-COLUMN-ADD-SUB',
                            standard(ccss, '2.NBT.B.5')).
curated_commensurate_lesson('IM-G4-U4-L20',
                            'TRAD-RAY-G4-NBT-B4-MULTIDIGIT',
                            standard(ccss, '4.NBT.B.4')).
curated_commensurate_lesson('IM-G3-U1-L14',
                            'TRAD-RAY-G3-OA-C7-MULT-FACTS',
                            standard(ccss, '3.OA.C.7')).
curated_commensurate_lesson('IM-G5-U6-L14',
                            'TRAD-RAY-G5-NF-A1-FRACTION-ADD',
                            standard(ccss, '5.NF.A.1')).


lesson_has_standard(LessonCode, standard(Framework, StandardCode)) :-
    current_predicate(lesson_monitoring:lesson_standard/4),
    lesson_monitoring:lesson_standard(LessonCode, Framework, Code0, _Statement),
    normalize_standard_code(Code0, Code),
    normalize_standard_code(StandardCode, Code).

normalize_standard_code(Code, Normalized) :-
    atom(Code),
    !,
    Normalized = Code.
normalize_standard_code(Code, Normalized) :-
    string(Code),
    !,
    atom_string(Normalized, Code).


%!  expressive_power_comparison(+Standard, -IMReport, -TraditionalReport, -Delta) is nondet.
%
%   Compares one curated IM/traditional pair on the same standard. Delta is
%   always IM minus traditional. Unsupported path regions are marked
%   non_commensurable rather than scored as zero.
expressive_power_comparison(Standard, IMReport, TraditionalReport, Delta) :-
    commensurate_lesson(IMCode, TraditionalCode, Standard),
    lesson_expressive_power_for(IMCode, IMReport),
    lesson_expressive_power_for(TraditionalCode, TraditionalReport),
    comparison_delta(IMCode, TraditionalCode, IMReport, TraditionalReport, Delta).


comparison_delta(IMCode, TraditionalCode, IMReport, TraditionalReport,
        delta(proof_paths(PathDelta),
              strategy_incompatibilities(StrategyDelta),
              misconception_incompatibilities(MisconceptionDelta),
              emergent_hyperedges(HyperedgeDelta),
              notes(Notes))) :-
    path_axis_delta(IMCode, TraditionalCode, IMReport, TraditionalReport, PathDelta),
    report_strategy_incompatibility(IMReport, IMStrategy),
    report_strategy_incompatibility(TraditionalReport, TraditionalStrategy),
    StrategyDelta is IMStrategy - TraditionalStrategy,
    report_misconception_incompatibility(IMReport, IMMisconception),
    report_misconception_incompatibility(TraditionalReport, TraditionalMisconception),
    MisconceptionDelta is IMMisconception - TraditionalMisconception,
    lesson_emergent_hyperedge_count_for(IMCode, IMHyperedges),
    lesson_emergent_hyperedge_count_for(TraditionalCode, TraditionalHyperedges),
    HyperedgeDelta is IMHyperedges - TraditionalHyperedges,
    comparison_notes(Notes).

comparison_notes([
    structural_claim(puts_in_play),
    understanding_hypothesis(explicate_exclusions),
    decentering_link(downstream_conjecture_not_result),
    measure_note('proof paths are region-level and compared only when both lessons use supported operation regions'),
    measure_note('incompatibility counts proxy how much a lesson makes explicit about what a move rules out'),
    measure_note('delta is IM minus traditional; negative values mean the traditional lesson leads on that axis')
]).

report_strategy_incompatibility(report(_, strategy_incompatibility(Value), _, _, _, _), Value).
report_misconception_incompatibility(report(_, _, misconception_incompatibility(Value), _, _, _), Value).

path_axis_delta(IMCode, TraditionalCode, IMReport, TraditionalReport, Delta) :-
    report_path_total(IMReport, IMPaths),
    report_path_total(TraditionalReport, TraditionalPaths),
    report_operation_powers(IMReport, IMOperationPowers),
    report_operation_powers(TraditionalReport, TraditionalOperationPowers),
    ( IMOperationPowers == []
    -> unsupported_path_delta(IMCode, TraditionalCode, Delta)
    ; TraditionalOperationPowers == []
    -> unsupported_path_delta(IMCode, TraditionalCode, Delta)
    ; operation_power_keys(IMOperationPowers, IMOps),
      operation_power_keys(TraditionalOperationPowers, TraditionalOps),
      ( IMOps == TraditionalOps
      -> Delta is IMPaths - TraditionalPaths
      ;  Delta = non_commensurable(mismatched_path_regions(operations(IMOps, TraditionalOps)))
      )
    ).

unsupported_path_delta(IMCode, TraditionalCode,
                       non_commensurable(no_supported_path_model(operations(IMOps, TraditionalOps)))) :-
    lesson_operations(IMCode, IMOps),
    lesson_operations(TraditionalCode, TraditionalOps).

report_path_total(report(paths(Value), _, _, _, _, _), Value).
report_operation_powers(report(_, _, _, per_operation(OperationPowers), _, _), OperationPowers).

operation_power_keys(OperationPowers, Ops) :-
    findall(Op, member(Op-_, OperationPowers), Ops0),
    sort(Ops0, Ops).


lesson_operations(LessonCode, Ops) :-
    lesson_vocabulary(LessonCode, Ops, _Strategies, _Misconceptions).

lesson_vocabulary(LessonCode, Ops, Strategies, Misconceptions) :-
    current_predicate(lesson_monitoring:lesson_strategy/4),
    current_predicate(lesson_monitoring:lesson_misconception/4),
    findall(strategy(Op, Kind),
            lesson_monitoring:lesson_strategy(LessonCode, Op, Kind, _),
            Strategies0),
    sort(Strategies0, Strategies),
    findall(Name,
            lesson_monitoring:lesson_misconception(LessonCode, _, Name, _),
            Misconceptions0),
    sort(Misconceptions0, Misconceptions),
    findall(Op, member(strategy(Op, _), Strategies), Ops0),
    sort(Ops0, Ops).

lesson_emergent_hyperedge_count_for(LessonCode, Count) :-
    lesson_vocabulary(LessonCode, _Ops, Strategies, Misconceptions),
    findall(Target,
            ( member(Target, Strategies)
            ; member(Name, Misconceptions),
              Target = Name
            ),
            Targets0),
    sort(Targets0, Targets),
    findall(Set,
            ( member(Target, Targets),
              discovered_target_set(Target, _Context, Set)
            ),
            Sets0),
    sort(Sets0, Sets),
    length(Sets, Count).


%!  expressive_power_comparison_report(-Report) is nondet.
%
%   Report = report(Standard, pair(IMCode, TraditionalCode), IM, Traditional,
%   Delta, Notes), where IM/Traditional carry the lesson power report plus
%   provenance rows used by the side-by-side view.
expressive_power_comparison_report(
        report(Standard,
               pair(IMCode, TraditionalCode),
               im(IMCode, IMLesson, IMReport, IMEvidence),
               traditional(TraditionalCode, TraditionalLesson, TraditionalReport, TraditionalEvidence),
               Delta,
               Notes)) :-
    commensurate_lesson(IMCode, TraditionalCode, Standard),
    lesson_expressive_power_for(IMCode, IMReport),
    lesson_expressive_power_for(TraditionalCode, TraditionalReport),
    comparison_delta(IMCode, TraditionalCode, IMReport, TraditionalReport, Delta),
    comparison_notes(Notes),
    lesson_descriptor(IMCode, IMLesson),
    lesson_descriptor(TraditionalCode, TraditionalLesson),
    lesson_evidence(IMCode, IMEvidence),
    lesson_evidence(TraditionalCode, TraditionalEvidence).

lesson_descriptor(Code, lesson(ConceptId, Title, Grade, Unit, LessonNumber)) :-
    current_predicate(lesson_monitoring:encoded_lesson/6),
    lesson_monitoring:encoded_lesson(Code, ConceptId, Title, Grade, Unit, LessonNumber).

lesson_evidence(Code, evidence(Strategies, Misconceptions, Citations)) :-
    findall(strategy(Operation, Kind, Provenance, Sources, CitationStrings),
            ( lesson_monitoring:lesson_strategy(Code, Operation, Kind, Info),
              info_provenance(Info, Provenance),
              info_sources(Info, Sources),
              info_citations(Info, CitationStrings)
            ),
            Strategies0),
    sort(Strategies0, Strategies),
    findall(misconception(Operation, Name, Provenance, Sources, CitationStrings),
            ( lesson_monitoring:lesson_misconception(Code, Operation, Name, Info),
              info_provenance(Info, Provenance),
              info_sources(Info, Sources),
              info_citations(Info, CitationStrings)
            ),
            Misconceptions0),
    sort(Misconceptions0, Misconceptions),
    findall(Citation,
            ( member(strategy(_, _, _, _, StrategyCitations), Strategies0),
              member(Citation, StrategyCitations)
            ; member(misconception(_, _, _, _, MiscCitations), Misconceptions0),
              member(Citation, MiscCitations)
            ),
            Citations0),
    sort(Citations0, Citations).

info_provenance(Info, Provenance) :-
    member(provenance(Provenance), Info),
    !.
info_provenance(_, unspecified).

info_sources(Info, Sources) :-
    findall(SourceString,
            ( member(Source, Info),
              compound(Source),
              functor(Source, source, _),
              term_string(Source, SourceString)
            ),
            Sources0),
    sort(Sources0, Sources).

info_citations(Info, Citations) :-
    findall(CitationString,
            ( member(citation(Key, Note), Info),
              format(string(CitationString), "~w: ~w", [Key, Note])
            ),
            Citations0),
    sort(Citations0, Citations).


%!  expressive_power_wiring_audit(-Rows) is det.
%
%   Rows are per-lesson wiring diagnostics for the curated comparison set. The
%   audit deliberately separates "what the report currently uses" from
%   "review flags" so sparse lesson encodings stay visible instead of becoming
%   silent zeroes in the comparison chart.
expressive_power_wiring_audit(Rows) :-
    findall(Row, comparison_lesson_wiring_row(Row), Rows0),
    sort(Rows0, Rows).


comparison_lesson_wiring_row(
        lesson_wiring(Code, Role, Standard, Counts, issues(Issues))) :-
    commensurate_lesson(IMCode, TraditionalCode, Standard),
    (   Role = im,
        Code = IMCode
    ;   Role = traditional,
        Code = TraditionalCode
    ),
    lesson_wiring_counts(Code, Counts),
    lesson_wiring_issues(Counts, Issues).


lesson_wiring_counts(
        Code,
        counts(strategies(StrategyCount),
               misconceptions(MisconceptionCount),
               citations(CitationCount),
               clusters(ClusterCount))) :-
    lesson_evidence(Code, evidence(Strategies, Misconceptions, Citations)),
    length(Strategies, StrategyCount),
    length(Misconceptions, MisconceptionCount),
    length(Citations, CitationCount),
    findall(Source-ClusterId,
            lesson_monitoring:monitoring_chart_cluster(Code, Source, ClusterId, _Info),
            ClusterRows0),
    sort(ClusterRows0, ClusterRows),
    length(ClusterRows, ClusterCount).


lesson_wiring_issues(Counts, Issues) :-
    findall(Issue, lesson_wiring_issue(Counts, Issue), Issues0),
    sort(Issues0, Issues).


lesson_wiring_issue(counts(strategies(0), _, _, _), no_strategy_encoding).
lesson_wiring_issue(counts(_, misconceptions(0), _, _), no_misconception_encoding).
lesson_wiring_issue(counts(_, _, citations(0), _), missing_citation_evidence).
lesson_wiring_issue(
        counts(strategies(StrategyCount),
               misconceptions(MisconceptionCount),
               _,
               clusters(ClusterCount)),
        cluster_available_but_sparse_direct_encoding(
            strategy_count(StrategyCount),
            misconception_count(MisconceptionCount),
            clusters(ClusterCount))) :-
    ClusterCount > 0,
    (   StrategyCount < 2
    ;   MisconceptionCount =:= 0
    ).


%!  expressive_power_comparison_json(-JSONDict) is det.
%
%   JSON-shaped dict consumed by more-zeeman/expressive-power-comparison.html.
expressive_power_comparison_json(_{
    title: "Expressive Power Comparison: IM vs Ray-style Traditional Lessons",
    claim_register: _{
        structural_claim: "Each lesson's report is the expressive power it puts in play.",
        understanding_hypothesis: "Understanding grows as students and teachers can explicate what it is not: what a concept, operation, or strategy excludes, what it rules out, and what is materially incompatible with it.",
        decentering_link: "downstream conjecture only: this exclusion map may support teacher decentering, but the comparison does not measure classroom decentering or learning outcomes."
    },
    wiring_audit: AuditRows,
    pairs: PairDicts
}) :-
    expressive_power_wiring_audit(Audit),
    maplist(wiring_audit_dict, Audit, AuditRows),
    findall(PairDict,
            ( expressive_power_comparison_report(Report),
              comparison_report_dict(Report, PairDict)
            ),
            PairDicts).

write_expressive_power_comparison_json(Path) :-
    expressive_power_comparison_json(JSON),
    setup_call_cleanup(
        open(Path, write, Stream, [encoding(utf8)]),
        ( json_write_dict(Stream, JSON, [width(128)]),
          nl(Stream)
        ),
        close(Stream)
    ).

comparison_report_dict(
        report(Standard,
               pair(IMCode, TraditionalCode),
               im(IMCode, IMLesson, IMReport, IMEvidence),
               traditional(TraditionalCode, TraditionalLesson, TraditionalReport, TraditionalEvidence),
               Delta,
               Notes),
        _{
            standard: StandardDict,
            im: IMDict,
            traditional: TraditionalDict,
            delta: DeltaDict,
            notes: NoteStrings
        }) :-
    standard_dict(Standard, StandardDict),
    lesson_report_dict(IMCode, IMLesson, IMReport, IMEvidence, IMDict),
    lesson_report_dict(TraditionalCode, TraditionalLesson, TraditionalReport, TraditionalEvidence, TraditionalDict),
    delta_dict(Delta, DeltaDict),
    maplist(term_text, Notes, NoteStrings).

wiring_audit_dict(
        lesson_wiring(Code,
                      Role,
                      Standard,
                      counts(strategies(StrategyCount),
                             misconceptions(MisconceptionCount),
                             citations(CitationCount),
                             clusters(ClusterCount)),
                      issues(Issues)),
        _{
            code: CodeString,
            role: RoleString,
            standard: StandardDict,
            counts: _{
                strategies: StrategyCount,
                misconceptions: MisconceptionCount,
                citations: CitationCount,
                clusters: ClusterCount
            },
            status: Status,
            issues: IssueStrings
        }) :-
    term_text(Code, CodeString),
    term_text(Role, RoleString),
    standard_dict(Standard, StandardDict),
    audit_status(Issues, Status),
    maplist(term_text, Issues, IssueStrings).

audit_status([], "ok") :- !.
audit_status(_, "review").

standard_dict(standard(Framework, Code), _{framework: FrameworkString, code: CodeString, label: Label}) :-
    term_text(Framework, FrameworkString),
    term_text(Code, CodeString),
    format(string(Label), "~w ~w", [Framework, Code]).

lesson_report_dict(Code,
                   lesson(ConceptId, Title, Grade, Unit, LessonNumber),
                   Report,
                   evidence(StrategyEvidence, MisconceptionEvidence, Citations),
                   _{
                       code: CodeString,
                       concept: ConceptString,
                       title: TitleString,
                       grade: GradeString,
                       unit: UnitString,
                       lesson: LessonString,
                       report: Summary,
                       strategies: StrategyRows,
                       misconceptions: MisconceptionRows,
                       citations: Citations
                   }) :-
    term_text(Code, CodeString),
    term_text(ConceptId, ConceptString),
    term_text(Title, TitleString),
    term_text(Grade, GradeString),
    term_text(Unit, UnitString),
    term_text(LessonNumber, LessonString),
    report_summary_dict(Report, Summary),
    maplist(strategy_evidence_dict, StrategyEvidence, StrategyRows),
    maplist(misconception_evidence_dict, MisconceptionEvidence, MisconceptionRows).

report_summary_dict(report(paths(Paths),
                           strategy_incompatibility(StrategyIncompatibility),
                           misconception_incompatibility(MisconceptionIncompatibility),
                           per_operation(OperationPowers),
                           per_strategy(StrategyPowers),
                           per_misconception(MisconceptionPowers)),
                    _{
                        proof_paths: Paths,
                        strategy_incompatibilities: StrategyIncompatibility,
                        misconception_incompatibilities: MisconceptionIncompatibility,
                        operations: OperationRows,
                        strategy_count: StrategyCount,
                        misconception_count: MisconceptionCount
                    }) :-
    maplist(operation_power_dict, OperationPowers, OperationRows),
    length(StrategyPowers, StrategyCount),
    length(MisconceptionPowers, MisconceptionCount).

operation_power_dict(Op-region_paths(Total, Cells, DistinctCosts),
                     _{operation: OpString, total_paths: Total, cells: Cells, sum_distinct_costs: DistinctCosts}) :-
    term_text(Op, OpString).

strategy_evidence_dict(strategy(Operation, Kind, Provenance, Sources, Citations),
                       _{operation: OperationString, kind: KindString, provenance: ProvenanceString, sources: Sources, citations: Citations}) :-
    term_text(Operation, OperationString),
    term_text(Kind, KindString),
    term_text(Provenance, ProvenanceString).

misconception_evidence_dict(misconception(Operation, Name, Provenance, Sources, Citations),
                            _{operation: OperationString, name: NameString, provenance: ProvenanceString, sources: Sources, citations: Citations}) :-
    term_text(Operation, OperationString),
    term_text(Name, NameString),
    term_text(Provenance, ProvenanceString).

delta_dict(delta(proof_paths(PathDelta),
                 strategy_incompatibilities(StrategyDelta),
                 misconception_incompatibilities(MisconceptionDelta),
                 emergent_hyperedges(HyperedgeDelta),
                 notes(Notes)),
           _{
               proof_paths: PathDeltaJSON,
               strategy_incompatibilities: StrategyDelta,
               misconception_incompatibilities: MisconceptionDelta,
               emergent_hyperedges: HyperedgeDelta,
               notes: NoteStrings
           }) :-
    axis_delta_json(PathDelta, PathDeltaJSON),
    maplist(term_text, Notes, NoteStrings).

axis_delta_json(Value, Value) :-
    integer(Value),
    !.
axis_delta_json(non_commensurable(Reason),
                _{status: "non_commensurable", reason: ReasonString}) :-
    term_text(Reason, ReasonString).

term_text(Value, Text) :-
    string(Value),
    !,
    Text = Value.
term_text(Value, Text) :-
    atom(Value),
    !,
    atom_string(Value, Text).
term_text(Value, Text) :-
    term_string(Value, Text).
