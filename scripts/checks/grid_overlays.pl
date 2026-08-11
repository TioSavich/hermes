/** Focused checks for the G-series grid repairs and ruled widenings. */

:- module(grid_overlays_check, [main/0]).

:- use_module('../bigred/loops/loop_driver.pl', []).
:- use_module('../bigred/loops/r3_driver.pl', []).
:- use_module('../bigred/loops/r4_driver.pl', []).


main :-
    check_ten_computing_fixtures,
    check_overlay_order_and_counts,
    check_shared_grid_no_leak,
    check_widened_plans,
    check_probe_paths,
    check_repaired_result_profiles,
    format('PASS grid overlays: fixtures compute; overlay strata are budgeted and stratified; seven machines reach 20 distinct R4 results; four ruled exclusions are named~n').


check_ten_computing_fixtures :-
    findall(Machine-Input,
            loop_driver:computing_grid_fixture(Machine, Input),
            Fixtures),
    length(Fixtures, 10),
    maplist(check_computing_fixture, Fixtures).

check_computing_fixture(machine(Family, Kind)-Fixture) :-
    Machine = machine(Family, Kind),
    loop_driver:machine_schema(Machine, Schema),
    once(( loop_driver:machine_grid_input(Machine, Schema, _, GridInput),
           GridInput =@= Fixture )),
    loop_driver:aa_run(Family, Kind, Fixture, Outcome),
    Outcome = result(_, _, _),
    format('  computes ~w/~w: ~q~n', [Family, Kind, Fixture]).


check_overlay_order_and_counts :-
    forall(expected_machine_points(Machine, Expected),
           check_machine_points(Machine, Expected)),
    forall(overlay_points(Machine, OverlayPoints),
           check_additive_overlay(Machine, OverlayPoints)),
    check_target_overlay_selection,
    check_two_overlay_pairs_deduplicate.

expected_machine_points(machine(algebraic, exponential_equivalence_by_expansion), 20).
expected_machine_points(machine(fraction, co_denominator_make_base_transfer), 712).
expected_machine_points(machine(fraction, co_denominator_make_ten_split_leftover), 712).
expected_machine_points(machine(geometry, angle_additive_composition), 24).
expected_machine_points(machine(integer, drop_sign_use_magnitude_sum), 2800).
expected_machine_points(machine(subtraction, borrow_across_zero_cascade), 2524).
expected_machine_points(machine(subtraction, borrow_across_zero_no_cascade), 2524).
expected_machine_points(machine(geometry, angle_as_ray_length), 24).
expected_machine_points(machine(geometry, angle_turn_measurement), 24).
expected_machine_points(machine(integer, inequality_as_boundary_point), 100).

overlay_points(machine(fraction, co_denominator_make_base_transfer), 87).
overlay_points(machine(fraction, co_denominator_make_ten_split_leftover), 87).
overlay_points(machine(integer, drop_sign_use_magnitude_sum), 300).
overlay_points(machine(subtraction, borrow_across_zero_cascade), 24).
overlay_points(machine(subtraction, borrow_across_zero_no_cascade), 24).

check_machine_points(Machine, Expected) :-
    loop_driver:machine_schema(Machine, Schema),
    loop_driver:machine_grid_point_count(Machine, Schema, Expected),
    aggregate_all(count,
                  loop_driver:machine_grid_input(Machine, Schema, _, _),
                  Actual),
    Actual =:= Expected.

check_additive_overlay(Machine, OverlayPoints) :-
    Machine = machine(Family, Kind),
    loop_driver:machine_schema(Machine, Schema),
    findall(Input,
            loop_driver:machine_grid_input(Machine, Schema, _, Input),
            Effective),
    length(Overlay, OverlayPoints),
    append(Overlay, SharedSuffix, Effective),
    findall(Input, loop_driver:grid_input(Schema, _, Input), Shared),
    SharedSuffix =@= Shared,
    forall(member(Input, Overlay),
           loop_driver:aa_run(Family, Kind, Input, result(_, _, _))).

check_target_overlay_selection :-
    check_pair_target_overlay(
        machine(addition, base_ones_chunking),
        machine(integer, drop_sign_use_magnitude_sum), 300),
    check_pair_target_overlay(
        machine(fraction, benchmark_fraction_comparison),
        machine(fraction, co_denominator_make_ten_split_leftover), 87).

check_pair_target_overlay(Source, Target, OverlayPoints) :-
    loop_driver:machine_schema(Source, Schema),
    loop_driver:machine_schema(Target, Schema),
    findall(Input,
            loop_driver:pair_grid_input(Source, Target, Schema, _, Input),
            Effective),
    length(Overlay, OverlayPoints),
    append(Overlay, SharedSuffix, Effective),
    findall(Input, loop_driver:grid_input(Schema, _, Input), Shared),
    SharedSuffix =@= Shared.

check_two_overlay_pairs_deduplicate :-
    check_two_overlay_pair(
        machine(fraction, co_denominator_make_base_transfer),
        machine(fraction, co_denominator_make_ten_split_leftover), 712),
    check_two_overlay_pair(
        machine(subtraction, borrow_across_zero_cascade),
        machine(subtraction, borrow_across_zero_no_cascade), 2524),
    format('  two-overlay pairs: enumerated == distinct == declared (712 fraction; 2524 zero-cascade)~n').

check_two_overlay_pair(Source, Target, Expected) :-
    loop_driver:machine_schema(Source, Schema),
    loop_driver:machine_schema(Target, Schema),
    loop_driver:pair_grid_point_count(Source, Target, Schema, Expected),
    findall(Input,
            loop_driver:pair_grid_input(Source, Target, Schema, _, Input),
            Inputs),
    length(Inputs, Expected),
    variant_distinct(Inputs, Distinct),
    length(Distinct, Expected).

variant_distinct(Inputs, Distinct) :-
    variant_distinct(Inputs, [], Reversed),
    reverse(Reversed, Distinct).

variant_distinct([], Distinct, Distinct).
variant_distinct([Input|Rest], Seen, Distinct) :-
    (   member(Existing, Seen),
        Input =@= Existing
    ->  variant_distinct(Rest, Seen, Distinct)
    ;   variant_distinct(Rest, [Input|Seen], Distinct)
    ).


check_shared_grid_no_leak :-
    integer_pair_schema(IntegerSchema),
    fraction_pair_schema(FractionSchema),
    findall(Input, legacy_integer_pair_input(Input), LegacyIntegers),
    findall(Input, loop_driver:grid_input(IntegerSchema, _, Input),
            SharedIntegers),
    LegacyIntegers =@= SharedIntegers,
    findall(Input, legacy_fraction_pair_input(Input), LegacyFractions),
    findall(Input, loop_driver:grid_input(FractionSchema, _, Input),
            SharedFractions),
    LegacyFractions =@= SharedFractions,
    forall(no_leak_sample(Machine),
           check_machine_uses_shared_grid_unchanged(Machine)),
    format('  no-leak shared grids: integer_pair=2500 fraction_pair=625; 4 other machines unchanged~n').

integer_pair_schema('{\"a\":\"integer\",\"b\":\"integer\"}').
fraction_pair_schema('{\"kind\":\"fraction_pair\",\"left\":{\"n\":\"integer\",\"d\":\"positive_integer\"},\"right\":{\"n\":\"integer\",\"d\":\"positive_integer\"}}').

legacy_integer_pair_input(_{a:A, b:B}) :-
    between(0, 49, A),
    between(0, 49, B).

legacy_fraction_pair_input(
    _{kind:"fraction_pair", left:_{n:LeftN,d:LeftD},
      right:_{n:RightN,d:RightD}}) :-
    between(0, 4, LeftN),
    between(1, 5, LeftD),
    between(0, 4, RightN),
    between(1, 5, RightD).

no_leak_sample(machine(addition, base_ones_chunking)).
no_leak_sample(machine(multiplication, add_instead_of_multiply)).
no_leak_sample(machine(fraction, benchmark_fraction_comparison)).
no_leak_sample(machine(fraction, area_model_fraction_comparison)).

check_machine_uses_shared_grid_unchanged(Machine) :-
    loop_driver:machine_schema(Machine, Schema),
    findall(Input,
            loop_driver:machine_grid_input(Machine, Schema, _, Input),
            Effective),
    findall(Input, loop_driver:grid_input(Schema, _, Input), Shared),
    Effective =@= Shared.


check_widened_plans :-
    forall(member(Kind, [angle_as_ray_length, angle_turn_measurement]),
           check_all_angle_points_compute(Kind)),
    inequality_relations(Relations),
    Relations == ["gt", "gte", "lt", "lte"],
    forall(member(Kind, [inequality_as_boundary_point,
                         inequality_solution_set_representation]),
           check_all_inequality_points_compute(Kind)),
    format('  widened plans: angle=24 distinct points; inequality=100 points over gt,gte,lt,lte~n').

check_all_angle_points_compute(Kind) :-
    Machine = machine(geometry, Kind),
    loop_driver:machine_schema(Machine, Schema),
    findall(Input,
            loop_driver:machine_grid_input(Machine, Schema, _, Input),
            Inputs),
    sort(Inputs, Distinct),
    length(Distinct, 24),
    forall(member(Input, Inputs),
           loop_driver:aa_run(geometry, Kind, Input, result(_, _, _))).

inequality_relations(Relations) :-
    Machine = machine(integer, inequality_as_boundary_point),
    loop_driver:machine_schema(Machine, Schema),
    setof(Relation, Bound^Variable^Kind^
          Input^( loop_driver:machine_grid_input(Machine, Schema, _, Input),
                  get_dict(kind, Input, Kind),
                  get_dict(variable, Input, Variable),
                  get_dict(bound, Input, Bound),
                  get_dict(relation, Input, Relation) ),
          Relations).

check_all_inequality_points_compute(Kind) :-
    Machine = machine(integer, Kind),
    loop_driver:machine_schema(Machine, Schema),
    aggregate_all(count,
                  loop_driver:machine_grid_input(Machine, Schema, _, _),
                  100),
    forall(loop_driver:machine_grid_input(Machine, Schema, _, Input),
           loop_driver:aa_run(integer, Kind, Input, result(_, _, _))).


check_probe_paths :-
    forall(graduable_probe_machine(Machine),
           check_r4_probe_reaches_design_bar(Machine)),
    replay_r4_probe(machine(subtraction, borrow_across_zero_cascade),
                    20, 20),
    replay_r4_probe(machine(subtraction, borrow_across_zero_no_cascade),
                    20, 20),
    forall(probe_exclusion(Machine, Reason),
           check_probe_exclusion(Machine, Reason)),
    check_r3_and_r4_overlay_prefixes,
    check_large_overlay_budget_cap,
    forall(probe_no_leak_sample(Machine),
           check_legacy_probe_sequence_unchanged(Machine)),
    format('  R4 collected results: zero-cascade = 20/20 distinct on both; co-denominator = 13/20 distinct on both; drop-sign = 15/20 distinct~n'),
    format('  probe design bar: 7 graduable G/W machines reach 20 distinct results~n'),
    format('  probe exclusions: fraction/co_denominator_make_base_transfer and fraction/co_denominator_make_ten_split_leftover are thin at 13/20; integer/drop_sign_use_magnitude_sum is thin at 15/20; algebraic/exponential_equivalence_by_expansion is unmeasured_source(no_carrier)~n'),
    format('  probe no-leak: R3 and R4 select byte-identical legacy points for 3 non-overlay machines~n').

% The seven machines that can reach the 20-distinct-result bar. The four ruled
% exclusions below stay separate so a thin probe is never reported as absent.
graduable_probe_machine(
    machine(subtraction, borrow_across_zero_cascade)).
graduable_probe_machine(
    machine(subtraction, borrow_across_zero_no_cascade)).
graduable_probe_machine(machine(geometry, angle_additive_composition)).
graduable_probe_machine(machine(geometry, angle_as_ray_length)).
graduable_probe_machine(machine(geometry, angle_turn_measurement)).
graduable_probe_machine(machine(integer, inequality_as_boundary_point)).
graduable_probe_machine(
    machine(integer, inequality_solution_set_representation)).

probe_exclusion(machine(fraction, co_denominator_make_base_transfer),
                thin(distinct_results(13, 20))).
probe_exclusion(machine(fraction, co_denominator_make_ten_split_leftover),
                thin(distinct_results(13, 20))).
probe_exclusion(machine(integer, drop_sign_use_magnitude_sum),
                thin(distinct_results(15, 20))).
probe_exclusion(
    machine(algebraic, exponential_equivalence_by_expansion), no_carrier).

check_probe_exclusion(Machine, thin(distinct_results(Distinct, Collected))) :-
    replay_r4_probe(Machine, Collected, Distinct).
check_probe_exclusion(Machine, no_carrier) :-
    r4_driver:unmeasured_source(Machine, no_carrier),
    replay_r4_probe(Machine, 20, 1).

check_r4_probe_reaches_design_bar(Machine) :-
    replay_r4_probe(Machine, 20, DistinctCount),
    DistinctCount >= 20.

replay_r4_probe(Machine, CollectedCount, DistinctCount) :-
    machine_grid_inputs(Machine, Inputs),
    length(Inputs, Total),
    r4_probe_parameters(Wanted, Rounds),
    Machine = machine(Family, Kind),
    loop_driver:machine_schema(Machine, Schema),
    r4_driver:machine_probe_indices(Machine, Schema, Total, Wanted, Rounds,
                                    Indices),
    indices_inputs(Indices, Inputs, Probes),
    collect_computing_results(Probes, Family, Kind, Wanted, Results),
    length(Results, CollectedCount),
    variant_distinct(Results, DistinctResults),
    length(DistinctResults, DistinctCount).

collect_computing_results(_, _, _, 0, []) :- !.
collect_computing_results([], _, _, _, []).
collect_computing_results([Input|Rest], Family, Kind, Wanted, Results) :-
    loop_driver:aa_run(Family, Kind, Input, Outcome),
    (   Outcome = result(Result, _, _)
    ->  Results = [Result|Tail],
        Remaining is Wanted - 1
    ;   Results = Tail,
        Remaining = Wanted
    ),
    collect_computing_results(Rest, Family, Kind, Remaining, Tail).

check_r3_and_r4_overlay_prefixes :-
    forall(member(Machine,
                  [machine(subtraction, borrow_across_zero_cascade),
                   machine(subtraction, borrow_across_zero_no_cascade)]),
           check_driver_overlay_prefixes(Machine)).

check_driver_overlay_prefixes(Machine) :-
    loop_driver:machine_schema(Machine, Schema),
    loop_driver:machine_grid_point_count(Machine, Schema, Total),
    index_range(24, OverlayIndices),
    r4_probe_parameters(R4Wanted, R4Rounds),
    r4_driver:machine_probe_indices(Machine, Schema, Total, R4Wanted,
                                    R4Rounds, R4Indices),
    length(R4Prefix, 24),
    append(R4Prefix, _, R4Indices),
    sort(R4Prefix, OverlayIndices),
    r3_probe_parameters(R3Wanted, R3Rounds),
    r3_driver:machine_probe_indices(Machine, Schema, Total, R3Wanted,
                                    R3Rounds, R3Indices),
    length(R3Prefix, 24),
    append(R3Prefix, _, R3Indices),
    sort(R3Prefix, OverlayIndices).

check_large_overlay_budget_cap :-
    Machine = machine(integer, drop_sign_use_magnitude_sum),
    loop_driver:machine_schema(Machine, Schema),
    loop_driver:machine_grid_point_count(Machine, Schema, Total),
    r4_probe_parameters(Wanted, Rounds),
    Budget is Wanted * Rounds,
    r4_driver:machine_probe_indices(Machine, Schema, Total, Wanted, Rounds,
                                    Indices),
    length(Indices, Budget),
    forall(member(Index, Indices), Index < 300),
    index_range(Budget, Contiguous),
    Indices \== Contiguous,
    CoMachine = machine(fraction, co_denominator_make_base_transfer),
    loop_driver:machine_schema(CoMachine, CoSchema),
    loop_driver:machine_grid_point_count(CoMachine, CoSchema, CoTotal),
    r4_driver:machine_probe_indices(CoMachine, CoSchema, CoTotal, Wanted,
                                    Rounds, CoIndices),
    length(CoIndices, Budget),
    findall(Index,
            ( member(Index, CoIndices), Index >= 87 ),
            CoSharedIndices),
    length(CoSharedIndices, 113).

r4_probe_parameters(Wanted, Rounds) :-
    r4_driver:default(sample_count, Wanted),
    r4_driver:default(probe_multiple, Rounds).

r3_probe_parameters(Wanted, Rounds) :-
    r3_driver:default(sample_count, Sample),
    r3_driver:default(verify_count, Verify),
    Wanted is Sample + Verify,
    r3_driver:default(probe_multiple, Rounds).

machine_grid_inputs(Machine, Inputs) :-
    loop_driver:machine_schema(Machine, Schema),
    findall(Input,
            loop_driver:machine_grid_input(Machine, Schema, _, Input),
            Inputs).

probe_no_leak_sample(machine(addition, base_ones_chunking)).
probe_no_leak_sample(machine(fraction, benchmark_fraction_comparison)).
probe_no_leak_sample(machine(geometry, angle_as_ray_length)).

check_legacy_probe_sequence_unchanged(Machine) :-
    machine_grid_inputs(Machine, Inputs),
    length(Inputs, Total),
    loop_driver:machine_schema(Machine, Schema),
    loop_driver:machine_grid_overlay_point_count(Machine, Schema, 0),
    r4_probe_parameters(R4Wanted, R4Rounds),
    legacy_stratified_probe(Total, R4Wanted, R4Rounds, LegacyR4Indices),
    r4_driver:machine_probe_indices(Machine, Schema, Total, R4Wanted,
                                    R4Rounds, CurrentR4Indices),
    CurrentR4Indices == LegacyR4Indices,
    indices_inputs(CurrentR4Indices, Inputs, CurrentR4Inputs),
    indices_inputs(LegacyR4Indices, Inputs, LegacyR4Inputs),
    canonical_input_bytes(CurrentR4Inputs, CurrentR4Bytes),
    canonical_input_bytes(LegacyR4Inputs, LegacyR4Bytes),
    CurrentR4Bytes == LegacyR4Bytes,
    r3_probe_parameters(R3Wanted, R3Rounds),
    legacy_stratified_probe(Total, R3Wanted, R3Rounds, LegacyR3Indices),
    r3_driver:machine_probe_indices(Machine, Schema, Total, R3Wanted,
                                    R3Rounds, CurrentR3Indices),
    CurrentR3Indices == LegacyR3Indices,
    indices_inputs(CurrentR3Indices, Inputs, CurrentR3Inputs),
    indices_inputs(LegacyR3Indices, Inputs, LegacyR3Inputs),
    canonical_input_bytes(CurrentR3Inputs, CurrentR3Bytes),
    canonical_input_bytes(LegacyR3Inputs, LegacyR3Bytes),
    CurrentR3Bytes == LegacyR3Bytes.

indices_inputs(Indices, Inputs, Selected) :-
    findall(Input,
            ( member(Index, Indices), nth0(Index, Inputs, Input) ),
            Selected).

canonical_input_bytes(Inputs, Bytes) :-
    copy_term(Inputs, Grounded),
    numbervars(Grounded, 0, _, [singletons(true)]),
    term_string(Grounded, Bytes, [quoted(true)]).

legacy_stratified_probe(Total, Wanted, Rounds, Probe) :-
    (   Total =< 0
    ->  Probe = []
    ;   Last is Total - 1,
        numlist(0, Last, All),
        legacy_probe_rounds(All, Wanted, Rounds, Probe)
    ).

legacy_probe_rounds(_, _, Rounds, []) :-
    Rounds =< 0,
    !.
legacy_probe_rounds([], _, _, []) :- !.
legacy_probe_rounds(Available, Wanted, Rounds, Probe) :-
    length(Available, Count),
    legacy_stratified_indices(Count, Wanted, Positions),
    findall(Index, ( member(Position, Positions),
                     nth0(Position, Available, Index) ),
            Picked),
    findall(Index, ( nth0(Position, Available, Index),
                     \+ memberchk(Position, Positions) ),
            Remaining),
    NextRounds is Rounds - 1,
    legacy_probe_rounds(Remaining, Wanted, NextRounds, Rest),
    append(Picked, Rest, Probe).

legacy_stratified_indices(Total, Wanted, Indices) :-
    (   Wanted >= Total
    ->  Last is Total - 1,
        numlist(0, Last, Indices)
    ;   Wanted =< 0
    ->  Indices = []
    ;   Span is Total - 1,
        Steps is Wanted - 1,
        findall(Index,
                ( between(0, Steps, Position),
                  Index is (Position * Span) // max(Steps, 1) ),
                Raw),
        sort(Raw, Indices)
    ).

index_range(Count, Indices) :-
    Last is Count - 1,
    numlist(0, Last, Indices).


check_repaired_result_profiles :-
    check_result_profile(
        machine(algebraic, exponential_equivalence_by_expansion), 20, 1),
    check_result_profile(
        machine(geometry, angle_additive_composition), 24, 24),
    check_result_profile(
        machine(subtraction, borrow_across_zero_cascade), 24, 24),
    check_result_profile(
        machine(subtraction, borrow_across_zero_no_cascade), 24, 24),
    format('  result profiles: angle-additive and both zero-cascade machines 24/24 distinct; exponential 20 inputs/1 constant result~n').

check_result_profile(machine(Family, Kind), ExpectedComputing,
                     ExpectedDistinct) :-
    Machine = machine(Family, Kind),
    loop_driver:machine_schema(Machine, Schema),
    findall(Result,
            ( loop_driver:machine_grid_input(Machine, Schema, _, Input),
              loop_driver:aa_run(Family, Kind, Input,
                                 result(Result, _, _)) ),
            Results),
    length(Results, ExpectedComputing),
    variant_distinct(Results, Distinct),
    length(Distinct, ExpectedDistinct).
