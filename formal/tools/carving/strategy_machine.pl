:- module(carving_strategy_machine,
          [ initial_state/5,
            goal_state/1,
            unit_for_level/2,
            move/4,
            set_seed/1,
            known_fact/3,
            all_paths/6,
            emit_paths_json/6
          ]).

:- use_module(library(http/json)).
:- use_module(library(plunit)).


% state(Acc, Rem, Level). Rem is signed amount still owed to Acc.
initial_state(add, A, B, L, state(A, B, L)).
initial_state(sub, A, B, L, state(A, Neg, L)) :-
    Neg is -B.


goal_state(state(_, 0, _)).


% Which composite units are usable at each unit level.
unit_for_level(L, 10)  :- L >= 2.
unit_for_level(L, 100) :- L >= 3.


% move(+State0, ?Move, -State, -Cost). Cost is magnitude-independent for every
% move except inc1/dec1, where each +/-1 costs 1.
move(state(Acc, Rem, L), inc1, state(Acc1, Rem1, L), 1) :-
    Acc1 is Acc + 1,
    Rem1 is Rem - 1.
move(state(Acc, Rem, L), dec1, state(Acc1, Rem1, L), 1) :-
    Acc1 is Acc - 1,
    Rem1 is Rem + 1.
move(state(Acc, Rem, L), add_unit(U), state(Acc1, Rem1, L), 1) :-
    unit_for_level(L, U),
    Acc1 is Acc + U,
    Rem1 is Rem - U.
move(state(Acc, Rem, L), sub_unit(U), state(Acc1, Rem1, L), 1) :-
    unit_for_level(L, U),
    Acc1 is Acc - U,
    Rem1 is Rem + U.


:- dynamic known_fact/3.


% Recall: magnitude-independent retrieval of a seeded fact. Fires when the
% current (Acc, Rem) matches a stored sum in either operand order.
move(state(Acc, Rem, L), recall(Acc, Rem, V), state(V, 0, L), 1) :-
    Rem =\= 0,
    ( known_fact(Acc, Rem, V)
    ; known_fact(Rem, Acc, V)
    ).


% Memory seeds. M1 is the identity-only floor: identity is structural in
% initial_state/5, so M1 seeds no recall facts.
set_seed(Level) :-
    retractall(known_fact(_, _, _)),
    seed_facts(Level).

seed_facts(m1).
seed_facts(m2) :-
    forall(between(1, 9, N),
           ( V is 10 + N,
             assertz(known_fact(10, N, V))
           )),
    forall(between(1, 9, X),
           ( Y is 10 - X,
             assertz(known_fact(X, Y, 10))
           )).
seed_facts(m3) :-
    seed_facts(m2),
    forall(between(1, 10, N),
           ( V is N + N,
             assertz(known_fact(N, N, V))
           )).


%!  all_paths(+Op, +A, +B, +Level, +Bound, -Paths) is det.
%
%   Every goal-reaching path with at most Bound moves. Redundant or
%   oscillating paths within the bound are retained on purpose; this is an
%   exploratory strategy-naive machine, not k-shortest search.
all_paths(Op, A, B, L, Bound, Paths) :-
    initial_state(Op, A, B, L, S0),
    findall(path(Cost, Moves),
            bounded_path(S0, Bound, [], 0, Moves, Cost),
            Paths).


bounded_path(S, _, RevAcc, Cost, Moves, Cost) :-
    goal_state(S),
    reverse(RevAcc, Moves).
bounded_path(S, Bound, RevAcc, Cost0, Moves, Cost) :-
    Bound > 0,
    \+ goal_state(S),
    move(S, M, S1, MC),
    Bound1 is Bound - 1,
    Cost1 is Cost0 + MC,
    bounded_path(S1, Bound1, [M|RevAcc], Cost1, Moves, Cost).


%!  emit_paths_json(+Op, +A, +B, +Level, +Seed, +Bound) is det.
%
%   Set the memory seed, enumerate paths, and print one JSON object. Kept for
%   batch drivers under exploratory/bigred/iteration6.
emit_paths_json(Op, A, B, L, Seed, Bound) :-
    set_seed(Seed),
    all_paths(Op, A, B, L, Bound, Paths),
    maplist(path_to_dict, Paths, PathDicts),
    Dict = _{op: Op,
             a: A,
             b: B,
             level: L,
             seed: Seed,
             bound: Bound,
             paths: PathDicts},
    json_write_dict(current_output, Dict),
    nl.


path_to_dict(path(Cost, Moves), _{cost: Cost, moves: MoveStrs}) :-
    maplist(move_to_string, Moves, MoveStrs).

move_to_string(M, S) :-
    term_string(M, S).


:- begin_tests(carving_strategy_machine_basics).

test(initial_add) :-
    carving_strategy_machine:initial_state(add, 7, 5, 2, S),
    assertion(S == state(7, 5, 2)).

test(initial_sub_signs_remainder) :-
    carving_strategy_machine:initial_state(sub, 9, 4, 2, S),
    assertion(S == state(9, -4, 2)).

test(goal_when_remainder_zero) :-
    assertion(carving_strategy_machine:goal_state(state(12, 0, 2))),
    assertion(\+ carving_strategy_machine:goal_state(state(12, 3, 2))).

test(units_gate_by_level) :-
    assertion(\+ carving_strategy_machine:unit_for_level(1, 10)),
    assertion(carving_strategy_machine:unit_for_level(2, 10)),
    assertion(carving_strategy_machine:unit_for_level(3, 100)),
    assertion(\+ carving_strategy_machine:unit_for_level(2, 100)).

:- end_tests(carving_strategy_machine_basics).


:- begin_tests(carving_strategy_machine_moves).

test(inc1_moves_one_from_rem_to_acc) :-
    findall(S-C, carving_strategy_machine:move(state(7, 5, 2), inc1, S, C), Rs),
    assertion(Rs == [state(8, 4, 2)-1]).

test(dec1_moves_one_back) :-
    findall(S-C, carving_strategy_machine:move(state(7, 5, 2), dec1, S, C), Rs),
    assertion(Rs == [state(6, 6, 2)-1]).

test(add_unit_ten_at_level2_costs_one) :-
    assertion(carving_strategy_machine:move(state(7, 5, 2),
                                            add_unit(10),
                                            state(17, -5, 2),
                                            1)).

test(add_unit_unavailable_at_level1) :-
    assertion(\+ carving_strategy_machine:move(state(7, 5, 1), add_unit(10), _, _)).

test(sub_unit_ten_at_level2) :-
    assertion(carving_strategy_machine:move(state(28, 5, 2),
                                            sub_unit(10),
                                            state(18, 15, 2),
                                            1)).

:- end_tests(carving_strategy_machine_moves).


:- begin_tests(carving_strategy_machine_memory).

test(m1_has_no_recall_facts) :-
    carving_strategy_machine:set_seed(m1),
    findall(_, carving_strategy_machine:known_fact(_, _, _), Fs),
    assertion(Fs == []).

test(m2_seeds_base_plus_ones) :-
    carving_strategy_machine:set_seed(m2),
    assertion(carving_strategy_machine:known_fact(10, 3, 13)).

test(m2_seeds_complements_to_ten) :-
    carving_strategy_machine:set_seed(m2),
    assertion(carving_strategy_machine:known_fact(8, 2, 10)).

test(recall_fires_at_a_seeded_fact) :-
    carving_strategy_machine:set_seed(m2),
    assertion(carving_strategy_machine:move(state(10, 3, 2),
                                            recall(10, 3, 13),
                                            state(13, 0, 2),
                                            1)).

test(recall_does_not_fire_when_unseeded) :-
    carving_strategy_machine:set_seed(m1),
    assertion(\+ carving_strategy_machine:move(state(10, 3, 2),
                                               recall(_, _, _),
                                               _,
                                               _)).

test(m3_seeds_doubles) :-
    carving_strategy_machine:set_seed(m3),
    assertion(carving_strategy_machine:known_fact(6, 6, 12)).

:- end_tests(carving_strategy_machine_memory).


:- begin_tests(carving_strategy_machine_enumerate).

test(counting_on_is_enumerated_l1) :-
    carving_strategy_machine:set_seed(m1),
    carving_strategy_machine:all_paths(add, 3, 2, 1, 6, Paths),
    memberchk(path(2, [inc1, inc1]), Paths).

test(overshoot_compensation_enumerated_l2) :-
    carving_strategy_machine:set_seed(m1),
    carving_strategy_machine:all_paths(add, 7, 8, 2, 8, Paths),
    memberchk(path(3, [add_unit(10), dec1, dec1]), Paths).

test(make_a_ten_enumerated_l2_m2) :-
    carving_strategy_machine:set_seed(m2),
    carving_strategy_machine:all_paths(add, 8, 5, 2, 8, Paths),
    memberchk(path(3, [inc1, inc1, recall(10, 3, 13)]), Paths).

:- end_tests(carving_strategy_machine_enumerate).
