/** <module> Validated synthesis from the learner's primitive move space
 *
 * This is the live alternative to the archived FSM synthesizer and the
 * teacher-wrapper fallback. It asks the domain-agnostic reorganization engine
 * for a path, re-executes every primitive move, and validates the result through
 * grounded arithmetic before making the path available to the learner.
 *
 * A synthesized path is deliberately episode-scoped. A path found for 8+5 is
 * executable knowledge for 8+5, not yet a general make-base strategy. The
 * reflective monitor is responsible for recognizing a reusable plan only after
 * successful paths across distinct problems provide evidence for one.
 */

:- module(strategy_synthesis,
          [ synthesize_for_goal/4,
            install_synthesis/2,
            run_synthesized_strategy/5,
            run_synthesized_strategy/6,
            synthesized_strategy/7,
            reset_synthesized_strategies/0
          ]).

:- use_module(reorganize, [reorganize/4, run_learned_path/3]).
:- use_module('reorg_domains/arithmetic', []).
:- use_module('reorg_domains/whole_number_operations', []).
:- use_module(peano_utils, [peano_to_int/2, int_to_peano/2]).
:- use_module(reflective_monitor, [recognized_plan/3]).
:- use_module(spatial_recollection,
              [ fraction_spatial_recollection/3,
                notation_recollection/2
              ]).
:- use_module(formalization(grounded_arithmetic),
              [ integer_to_recollection/2,
                recollection_to_integer/2,
                add_grounded/3,
                subtract_grounded/3,
                multiply_grounded/3,
                divide_grounded/3
              ]).
:- use_module(math(sar_sub_action_pairs), [run_subtractive_action/5]).
:- use_module(math(smr_mult_action_pairs), [run_multiplicative_action/5]).
:- use_module(math(smr_div_action_pairs), [run_division_action/5]).
:- use_module(math(fraction_action_pairs), [run_fraction_action/5]).
:- use_module(math(recursive_unit_actions),
              [ fraction_unit_plan/3,
                integer_numeral/3,
                run_unit_plan/3,
                validate_fraction_candidate/4
              ]).
:- use_module(math(cgi_base),
              [ current_cgi_base/1,
                set_cgi_base/1
              ]).

:- dynamic synthesized_strategy/7.

:- meta_predicate
       with_operative_base(+, 0),
       grounded_binary_result(3, +, +, -).


%!  synthesize_for_goal(+Goal, +Base, +Level, -Synthesis) is semidet.
%
%   Search and validate a primitive path for a live learner goal. The current
%   Each operation selects a domain whose state preserves its unit structure.
synthesize_for_goal(Goal, _Base, _Level, Synthesis) :-
    normalized_fraction_goal(Goal, Numerator0, Denominator0),
    peano_or_integer(Numerator0, Numerator),
    peano_or_integer(Denominator0, Denominator),
    fraction_unit_plan(Numerator, Denominator, Plan),
    run_unit_plan(Plan, Quantity, StateTrace),
    validate_fraction_candidate(Numerator, Denominator, Plan,
                                licensed(exact_plan)),
    run_fraction_action(unit_fraction_iteration, Numerator, Denominator,
                        ActionOutcome, ActionTrace),
    productive_action_result(ActionOutcome, fraction(Numerator, Denominator)),
    fraction_spatial_recollection(Numerator, Denominator, SpatialEvidence),
    Cost is Numerator + 1,
    Moves = [partition(Denominator), iterate_unit_fraction(Numerator)],
    Synthesis = synthesis{
        operation: fraction,
        inputs: [Numerator, Denominator],
        result: Quantity,
        domain: recursive_units(fraction),
        crisis_kind: accommodation,
        acquired_level: 3,
        cost: Cost,
        moves: Moves,
        plan_shape: [partition_unit, iterate_unit_fraction],
        strategy: unit_action_strategy(fraction(Numerator, Denominator), Plan),
        state_trace: StateTrace,
        spatial_evidence: SpatialEvidence,
        validation: validated(
                        referent_preserving_execution,
                        action_automaton(unit_fraction_iteration, ActionTrace))
    },
    !.
synthesize_for_goal(Goal, Base, Level, Synthesis) :-
    integer(Base), Base >= 2,
    integer(Level), Level >= 1,
    normalized_goal(Goal, Operation, PeanoA, PeanoB),
    peano_or_integer(PeanoA, A),
    peano_or_integer(PeanoB, B),
    operation_problem(Operation, Base, A, B, Domain, Problem),
    reorganize(Domain, Problem, Level, Outcome),
    Outcome = reorganized(CrisisKind, AcquiredLevel, Strategy),
    Strategy = strat(Domain, Problem, AcquiredLevel, path(Cost, Moves)),
    Cost > 0,
    once(run_learned_path(Strategy, ReexecutedResult, StateTrace)),
    validate_result(Operation, Base, A, B, ReexecutedResult, Validation),
    ExpectedResult = ReexecutedResult,
    ReexecutedResult =:= ExpectedResult,
    move_plan_shape(Moves, PlanShape),
    integer_numeral(ReexecutedResult, Base, ResultNumeral),
    notation_recollection(ResultNumeral, NotationEvidence),
    Synthesis = synthesis{
        operation: Operation,
        inputs: [A, B],
        result: ReexecutedResult,
        domain: Domain,
        crisis_kind: CrisisKind,
        acquired_level: AcquiredLevel,
        cost: Cost,
        moves: Moves,
        plan_shape: PlanShape,
        strategy: Strategy,
        state_trace: StateTrace,
        representation_evidence: [NotationEvidence],
        validation: Validation
    }.


%!  install_synthesis(+Synthesis, -StrategyName) is det.
%
%   Install only the validated, episode-scoped path. Repeated installation is
%   idempotent. Newer paths are tried first.
install_synthesis(Synthesis, StrategyName) :-
    Op = Synthesis.operation,
    Synthesis.inputs = [A, B],
    Result = Synthesis.result,
    Strategy = Synthesis.strategy,
    Shape = Synthesis.plan_shape,
    Cost = Synthesis.cost,
    Level = Synthesis.acquired_level,
    Domain = Synthesis.domain,
    synthesis_strategy_name(Domain, Level, Shape, Cost, StrategyName),
    (   synthesized_strategy(Op, A, B, Result, StrategyName, Strategy, Shape)
    ->  true
    ;   asserta(synthesized_strategy(Op, A, B, Result,
                                     StrategyName, Strategy, Shape))
    ).


%!  run_synthesized_strategy(+A, +B, -Result, -Name, -Trace) is semidet.
%
%   Re-execute the installed path. The stored result is a validation witness,
%   not the execution result: Result is read from the final reached state.
run_synthesized_strategy(PeanoA, PeanoB, PeanoResult, Name, Trace) :-
    run_synthesized_strategy(add, PeanoA, PeanoB, PeanoResult, Name, Trace).

run_synthesized_strategy(fraction, Numerator0, Denominator0, Quantity,
                         Name, Trace) :-
    peano_or_integer(Numerator0, Numerator),
    peano_or_integer(Denominator0, Denominator),
    synthesized_strategy(fraction, Numerator, Denominator, Expected,
                         Name, Strategy, Shape),
    Strategy = unit_action_strategy(fraction(Numerator, Denominator), Plan),
    run_unit_plan(Plan, Actual, StateTrace),
    Actual == Expected,
    fraction_spatial_recollection(Numerator, Denominator, SpatialEvidence),
    Quantity = Actual,
    Name = unit_action_path(fraction, Shape, Cost),
    Trace = synthesized_path{
        source: recursive_unit_actions,
        scope: episode,
        domain: recursive_units(fraction),
        problem: fraction(Numerator, Denominator),
        level: 3,
        cost: Cost,
        moves: [partition(Denominator), iterate_unit_fraction(Numerator)],
        plan_shape: Shape,
        state_trace: StateTrace,
        spatial_evidence: SpatialEvidence,
        result: Actual
    }.
run_synthesized_strategy(Operation, PeanoA, PeanoB, PeanoResult, Name, Trace) :-
    peano_or_integer(PeanoA, A),
    peano_or_integer(PeanoB, B),
    synthesized_strategy(Operation, A, B, Expected, Name, Strategy, Shape),
    once(run_learned_path(Strategy, Actual, StateTrace)),
    Actual =:= Expected,
    int_to_peano(Actual, PeanoResult),
    Strategy = strat(Domain, Problem, Level, path(Cost, Moves)),
    domain_base(Domain, Base),
    integer_numeral(Actual, Base, ResultNumeral),
    notation_recollection(ResultNumeral, NotationEvidence),
    Trace = synthesized_path{
        source: primitive_reorganization,
        scope: episode,
        domain: Domain,
        problem: Problem,
        level: Level,
        cost: Cost,
        moves: Moves,
        plan_shape: Shape,
        state_trace: StateTrace,
        representation_evidence: [NotationEvidence],
        result: Actual
    }.
run_synthesized_strategy(Operation, PeanoA, PeanoB, PeanoResult, Name, Trace) :-
    memberchk(Operation, [add, subtract, multiply, divide]),
    peano_or_integer(PeanoA, A),
    peano_or_integer(PeanoB, B),
    reflective_monitor:recognized_plan(Operation, Shape, evidence(Cases)),
    recognized_base(Operation, Cases, Base),
    compile_recognized_path(Operation, Shape, Base, A, B, Strategy),
    once(run_learned_path(Strategy, Actual, StateTrace)),
    validate_result(Operation, Base, A, B, Actual, Validation),
    int_to_peano(Actual, PeanoResult),
    Strategy = strat(Domain, Problem, Level, path(Cost, Moves)),
    length(Cases, EvidenceCount),
    integer_numeral(Actual, Base, ResultNumeral),
    notation_recollection(ResultNumeral, NotationEvidence),
    Name = recognized_path(Domain, Shape, Cost),
    Trace = synthesized_path{
        source: successful_reflection,
        scope: recognized_plan,
        domain: Domain,
        problem: Problem,
        level: Level,
        cost: Cost,
        moves: Moves,
        plan_shape: Shape,
        state_trace: StateTrace,
        representation_evidence: [NotationEvidence],
        evidence_count: EvidenceCount,
        evidence: Cases,
        validation: Validation,
        result: Actual
    }.


reset_synthesized_strategies :-
    retractall(synthesized_strategy(_, _, _, _, _, _, _)).


normalized_goal(object_level:Goal, Operation, A, B) :- !,
    normalized_goal(Goal, Operation, A, B).
normalized_goal(Goal, Operation, A, B) :-
    Goal =.. [Operation, A, B, _],
    memberchk(Operation, [add, subtract, multiply, divide]).

normalized_fraction_goal(object_level:fraction(N, D, _), N, D) :- !.
normalized_fraction_goal(fraction(N, D, _), N, D).

synthesis_strategy_name(recursive_units(fraction), _Level, Shape, Cost,
                        unit_action_path(fraction, Shape, Cost)) :- !.
synthesis_strategy_name(Domain, Level, Shape, Cost,
                        reorganized_path(Domain, Level, Shape, Cost)).

operation_problem(add, Base, A, B, arithmetic(Base), add(A, B)).
operation_problem(subtract, Base, A, B,
                  whole_number(subtract, Base), subtract(A, B)) :- A >= B.
operation_problem(multiply, Base, A, B,
                  whole_number(multiply, Base), multiply(A, B)).
operation_problem(divide, Base, A, B,
                  whole_number(divide, Base), divide(A, B)) :- B > 0.

domain_base(arithmetic(Base), Base).
domain_base(whole_number(_Operation, Base), Base).

peano_or_integer(N, N) :- integer(N), N >= 0, !.
peano_or_integer(Peano, N) :- peano_to_int(Peano, N).

grounded_addition_result(A, B, Result) :-
    integer_to_recollection(A, RA),
    integer_to_recollection(B, RB),
    add_grounded(RA, RB, RR),
    recollection_to_integer(RR, Result).

validate_result(add, _Base, A, B, Result, grounded_addition) :-
    grounded_addition_result(A, B, Result).
validate_result(subtract, Base, A, B, Result,
                validated(grounded_subtraction,
                          action_automaton(take_away_base_ones, ActionTrace))) :-
    grounded_binary_result(subtract_grounded, A, B, Result),
    with_operative_base(Base,
        run_subtractive_action(take_away_base_ones, A, B, Outcome, ActionTrace)),
    productive_action_result(Outcome, Result).
validate_result(multiply, Base, A, B, Result,
                validated(grounded_multiplication,
                          action_automaton(coordinate_groups_items, ActionTrace))) :-
    grounded_binary_result(multiply_grounded, A, B, Result),
    with_operative_base(Base,
        run_multiplicative_action(coordinate_groups_items, A, B, Outcome, ActionTrace)),
    productive_action_result(Outcome, Result).
validate_result(divide, Base, A, B, Result,
                validated(grounded_division,
                          action_automaton(measure_groups_of_size, ActionTrace))) :-
    grounded_binary_result(divide_grounded, A, B, Result),
    with_operative_base(Base,
        run_division_action(measure_groups_of_size, A, B, Outcome, ActionTrace)),
    productive_division_result(Outcome, Result).

with_operative_base(Base, Goal) :-
    current_cgi_base(Previous),
    setup_call_cleanup(set_cgi_base(Base), Goal, set_cgi_base(Previous)).

grounded_binary_result(Predicate, A, B, Result) :-
    integer_to_recollection(A, RA),
    integer_to_recollection(B, RB),
    call(Predicate, RA, RB, RR),
    recollection_to_integer(RR, Result).

productive_action_result(action_outcome(_, Fields), Result) :-
    memberchk(classification(productive), Fields),
    memberchk(validity(correct), Fields),
    memberchk(result(Result), Fields).

productive_division_result(action_outcome(_, Fields), Result) :-
    memberchk(classification(productive), Fields),
    memberchk(validity(correct), Fields),
    memberchk(result(quotient_remainder(Result, _Remainder)), Fields).


% Collapse repeated primitive moves but retain their order. Concrete recall
% operands are generalized to the action family; they remain fully present in
% the installed strategy and execution trace.
move_plan_shape(Moves, Shape) :-
    maplist(move_family, Moves, Families),
    collapse_adjacent(Families, Shape).

move_family(inc1, count_on_unit) :- !.
move_family(dec1, count_back_unit) :- !.
move_family(add_unit(_), count_on_composite_unit) :- !.
move_family(sub_unit(_), count_back_composite_unit) :- !.
move_family(count_back_one, count_back_unit) :- !.
move_family(remove_composite_unit(_), count_back_composite_unit) :- !.
move_family(count_item, count_items) :- !.
move_family(iterate_composite_unit(_), iterate_composite_unit) :- !.
move_family(measure_composite_unit(_), measure_composite_unit) :- !.
move_family(recall(_, _, _), recall_base_partition) :- !.
move_family(Move, Move).

collapse_adjacent([], []).
collapse_adjacent([X | Xs], [X | Ys]) :-
    drop_same(X, Xs, Rest),
    collapse_adjacent(Rest, Ys).

drop_same(X, [X | Xs], Rest) :- !,
    drop_same(X, Xs, Rest).
drop_same(_, Xs, Xs).


recognized_base(add,
                [case(_, _, primitive_reorganization(arithmetic(Base))) | _],
                Base) :-
    integer(Base), Base >= 2.
recognized_base(Operation,
                [case(_, _, primitive_reorganization(
                                  whole_number(Operation, Base))) | _],
                Base) :-
    memberchk(Operation, [subtract, multiply, divide]),
    integer(Base), Base >= 2.

compile_recognized_path(add, [count_on_unit, recall_base_partition],
                        Base, A, B,
                        strat(arithmetic(Base), add(A, B), 2,
                              path(Cost, Moves))) :-
    A > 0, A < Base,
    Distance is Base - A,
    Distance > 0,
    B > Distance,
    Remaining is B - Distance,
    Remaining > 0, Remaining < Base,
    Result is Base + Remaining,
    length(UnitMoves, Distance),
    maplist(=(inc1), UnitMoves),
    append(UnitMoves, [recall(Base, Remaining, Result)], Moves),
    Cost is Distance + 1.
compile_recognized_path(add, [count_on_composite_unit],
                        Base, A, Base,
                        strat(arithmetic(Base), add(A, Base), 2,
                              path(1, [add_unit(Base)]))).
compile_recognized_path(subtract, Shape, Base, A, B,
                        strat(whole_number(subtract, Base), subtract(A, B), 2,
                              path(Cost, Moves))) :-
    A >= B,
    subtraction_shape_moves(Shape, Base, B, Moves),
    length(Moves, Cost),
    Cost > 0.
compile_recognized_path(multiply, [iterate_composite_unit], Base, N, S,
                        strat(whole_number(multiply, Base), multiply(N, S), 2,
                              path(N, Moves))) :-
    N > 0, S > 1,
    length(Moves, N),
    maplist(=(iterate_composite_unit(S)), Moves).
compile_recognized_path(multiply, [count_items], Base, N, S,
                        strat(whole_number(multiply, Base), multiply(N, S), 1,
                              path(Product, Moves))) :-
    Product is N * S,
    Product > 0,
    length(Moves, Product),
    maplist(=(count_item), Moves).
compile_recognized_path(divide, [measure_composite_unit], Base, Total, Divisor,
                        strat(whole_number(divide, Base),
                              divide(Total, Divisor), 2,
                              path(Quotient, Moves))) :-
    Divisor > 0,
    Quotient is Total // Divisor,
    Quotient > 0,
    length(Moves, Quotient),
    maplist(=(measure_composite_unit(Divisor)), Moves).

subtraction_shape_moves([count_back_unit], Base, B, Moves) :-
    B > 0, B < Base,
    repeated_moves(B, count_back_one, Moves).
subtraction_shape_moves([count_back_composite_unit], Base, B, Moves) :-
    B >= Base,
    0 is B mod Base,
    Count is B // Base,
    repeated_moves(Count, remove_composite_unit(Base), Moves).
subtraction_shape_moves([count_back_unit, count_back_composite_unit],
                        Base, B, Moves) :-
    UnitCount is B mod Base,
    CompositeCount is B // Base,
    UnitCount > 0,
    CompositeCount > 0,
    repeated_moves(UnitCount, count_back_one, UnitMoves),
    repeated_moves(CompositeCount, remove_composite_unit(Base), CompositeMoves),
    append(UnitMoves, CompositeMoves, Moves).

repeated_moves(Count, Move, Moves) :-
    integer(Count), Count >= 0,
    length(Moves, Count),
    maplist(=(Move), Moves).
