% tools/carving/query.pl
%
% Production-facing query surface for the carving core. The batch runner in
% run.pl still owns experiment output generation; this module exposes small,
% deterministic predicates that the main UMEDCTA loader can import.

:- module(carving_query,
          [ carving_strategy_proof/5,
            carving_strategy_path/7,
            carving_group_min_cost/6,
            carving_unit_min_cost/5,
            carving_operation_summary/2,
            exploratory_carving_artifact/2
          ]).

:- use_module(synthesizer,
              [ init/3,
                find_proofs/3,
                carve_to_fixpoint/2
              ]).
:- use_module(primitives, []).
:- use_module(rationalizations, []).
:- use_module(strategy_machine, []).
:- use_module(groups_machine, []).
:- use_module(units_machine, []).


%!  carving_strategy_proof(+Operation, +X, +Y, +Z, -Proof) is nondet.
%
%   True when the productive carving rules can supply a proof body for
%   fact(Operation, X, Y, Z). This is the main-system surface: a fact head
%   is the commitment, and Proof is the symbolic entitlement.
carving_strategy_proof(Op, X, Y, Z, Proof) :-
    productive_config(Op, Config),
    find_proofs(fact(Op, X, Y, Z), Config, Proofs),
    member(Proof, Proofs).


%!  carving_strategy_path(+Op, +A, +B, +Level, +Seed, +Bound, -Path) is nondet.
%
%   True when the strategy-naive machine reaches the goal state for Op(A, B)
%   at Level under Seed within Bound moves. Path is path(Cost, Moves). This
%   exposes the productive iteration6 machine without committing its batch
%   sweep artifacts to the production loader.
carving_strategy_path(Op, A, B, Level, Seed, Bound, Path) :-
    carving_strategy_machine:set_seed(Seed),
    carving_strategy_machine:all_paths(Op, A, B, Level, Bound, Paths),
    member(Path, Paths).


%!  carving_group_min_cost(+Stage, +Unit, +Target, +Cap, -MinCost, -Witness) is semidet.
%
%   Public delegate for the multiplication/division composite-unit machine.
carving_group_min_cost(Stage, Unit, Target, Cap, MinCost, Witness) :-
    groups_machine:g_min_cost(Stage, Unit, Target, Cap, MinCost, Witness).


%!  carving_unit_min_cost(+Stage, +Target, +Cap, -MinCost, -Witness) is semidet.
%
%   Public delegate for the unified unit-iteration annealing machine.
carving_unit_min_cost(Stage, Target, Cap, MinCost, Witness) :-
    units_machine:u_min_cost(Stage, Target, Cap, MinCost, Witness).


%!  carving_operation_summary(+Operation, -Summary) is det.
%
%   Carves the bounded productive fact table for Operation and reports the
%   number of carved facts and remaining residue. Kept intentionally small
%   for loader-level smoke tests; larger sweeps belong to run.pl / Big Red.
carving_operation_summary(Op,
                          carving_summary(Op,
                                          MaxN,
                                          Config,
                                          carved(Carved),
                                          residue(Residue))) :-
    productive_experiment(Op, MaxN, Config, FactMode),
    init(Op, MaxN, FactMode),
    with_output_to(string(_), carve_to_fixpoint(Config, Stats)),
    Carved = Stats.total_carved,
    Residue = Stats.residue_count.


productive_experiment(add, 20, Config, correct) :-
    Config = _{base:10,
               unit_levels:2,
               unit_coords:2,
               tolerance:5,
               max_rounds:5,
               rationalize:false}.
productive_experiment(sub, 20, Config, correct) :-
    Config = _{base:10,
               unit_levels:2,
               unit_coords:2,
               tolerance:5,
               max_rounds:5,
               rationalize:false}.
productive_experiment(mult, 12, Config, correct) :-
    Config = _{base:10,
               unit_levels:2,
               unit_coords:2,
               tolerance:5,
               max_rounds:5,
               rationalize:false}.
productive_experiment(div, 20, Config, correct) :-
    Config = _{base:10,
               unit_levels:2,
               unit_coords:2,
               tolerance:5,
               max_rounds:5,
               rationalize:false}.
productive_experiment(frac, 10, Config, correct) :-
    Config = _{base:10,
               unit_levels:1,
               unit_coords:3,
               tolerance:5,
               max_rounds:5,
               rationalize:false}.


productive_config(Op, Config) :-
    productive_experiment(Op, _MaxN, Config, _FactMode).


%!  exploratory_carving_artifact(?Kind, ?Path) is nondet.
%
%   Existing branch artifacts that remain available but are not production
%   loader surfaces. This makes the exploratory boundary queryable.
exploratory_carving_artifact(bigred_iteration, 'exploratory/bigred/iteration2').
exploratory_carving_artifact(bigred_iteration, 'exploratory/bigred/iteration3').
exploratory_carving_artifact(bigred_iteration, 'exploratory/bigred/iteration4').
exploratory_carving_artifact(bigred_iteration, 'exploratory/bigred/iteration5').
exploratory_carving_artifact(bigred_iteration, 'exploratory/bigred/iteration6').
exploratory_carving_artifact(bigred_iteration, 'scripts/bigred/iteration11').
exploratory_carving_artifact(bigred_iteration, 'scripts/bigred/iteration12').
exploratory_carving_artifact(bigred_legacy_file, Path) :-
    legacy_bigred_iteration_file(RelativePath),
    atomic_list_concat(['exploratory/bigred', RelativePath], '/', Path).
exploratory_carving_artifact(batch_runner, 'tools/carving/run.pl').
exploratory_carving_artifact(batch_analyzer, 'tools/carving/analyze.py').
exploratory_carving_artifact(batch_analyzer, 'tools/carving/analyze_sweep.py').
exploratory_carving_artifact(batch_analyzer, 'tools/carving/recovery_audit.py').


legacy_bigred_iteration_file('iteration2/run_test.sh').
legacy_bigred_iteration_file('iteration2/test_pair.pl').
legacy_bigred_iteration_file('iteration3/aggregate.py').
legacy_bigred_iteration_file('iteration3/aggregate.sbatch').
legacy_bigred_iteration_file('iteration3/array.sbatch').
legacy_bigred_iteration_file('iteration3/enumerate_pairs.pl').
legacy_bigred_iteration_file('iteration3/generate_inputs.py').
legacy_bigred_iteration_file('iteration3/run_pair_batch.pl').
legacy_bigred_iteration_file('iteration3/submit.sh').
legacy_bigred_iteration_file('iteration4/README.md').
legacy_bigred_iteration_file('iteration4/aggregate.py').
legacy_bigred_iteration_file('iteration4/array.sbatch').
legacy_bigred_iteration_file('iteration4/grid.py').
legacy_bigred_iteration_file('iteration4/run_cell.pl').
legacy_bigred_iteration_file('iteration4/submit.sh').
legacy_bigred_iteration_file('iteration6/machine.pl').
