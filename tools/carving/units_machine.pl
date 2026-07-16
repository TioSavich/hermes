/** <module> Units machine — counting through fractions as one search
 *
 * The annealing machine. The three rung machines (strategy_machine = add/sub,
 * groups_machine = x/÷, fraction_unit_machine = fractions) are slices of this
 * one. The deep unity is one-and-the-many: a quantity is built by ITERATING a
 * current unit, and the unit can be RE-UNITIZED in two directions —
 *
 *   regroup(B)  : Unit -> Unit * B   (group B ones into a bigger one:
 *                                      bases 10/100, composite groups S)
 *   partition(B): Unit -> Unit / B   (split one into B sub-units: unit fractions)
 *
 * iterate is counting the current one. So counting (Unit = 1), place value
 * (regroup to 10), multiplication (regroup to a composite S), and fractions
 * (partition to 1/B) are the SAME two moves at different ratios. The resource
 * ladder gates which re-unitizations are available:
 *
 *   stage 1 : iterate only            -> count by ones
 *   stage 2 : + regroup               -> bases and composite groups
 *   stage 3 : + partition             -> unit fractions
 *
 * Values and units are SWI rationals (rdiv). Every move costs 1, so minimum
 * cost is shortest path (BFS). A rational Target is reached when Val =:= Target.
 * This does NOT track the fraction chain (intact/collapsed) — the rung-specific
 * deformations live in the rung machines; this machine anneals the PRODUCTIVE
 * path across rungs and shows where each re-unitization first pays off.
 */

:- module(units_machine,
          [ u_initial/1,
            u_move/6,
            u_min_cost/5,
            u_strategy/2,
            u_stage_rank/2
          ]).

:- use_module(library(lists)).

u_initial(u(0, 1)).            % value 0, unit = one

u_stage_rank(s1, 1).
u_stage_rank(s2, 2).
u_stage_rank(s3, 3).

max_factor(12).

% The canonical unit inventory: a base/group built from the bare one, or a unit
% fraction. Re-unitization acts ONLY on Unit = 1 (no chaining composites into
% arbitrary products like 5 -> 25), so the developmental gradient survives — a
% unit is a base, a small composite group, or a unit fraction, and it must be
% iterated to do the work. back_to_one drops to counting for a remainder, which
% is what makes mixed strategies (tens then ones) available.
regroup_unit(B) :- max_factor(Max), between(2, Max, B).   % groups + ten
regroup_unit(100).
regroup_unit(1000).

%!  u_move(+Stage, +Target, +State0, ?Move, -State, -Cost) is nondet.
u_move(_Stage, Target, u(V, U), iterate, u(V1, U), 1) :-
    V1 is V + U,
    V1 =< Target.                                  % never overshoot the target
u_move(Stage, _Target, u(V, 1), regroup(B), u(V, B), 1) :-
    u_stage_rank(Stage, R), R >= 2,
    regroup_unit(B).
u_move(Stage, _Target, u(V, U), back_to_one, u(V, 1), 1) :-
    u_stage_rank(Stage, R), R >= 2,
    U =\= 1.
u_move(Stage, _Target, u(V, 1), partition(B), u(V, U1), 1) :-
    u_stage_rank(Stage, R), R >= 3,
    max_factor(Max), between(2, Max, B),
    U1 is 1 rdiv B.

%!  u_min_cost(+Stage, +Target, +Cap, -MinCost, -Witness) is semidet.
%
%   Uniform-cost BFS to Val =:= Target. Target is a rational (e.g. 50, or
%   7 rdiv 5). Fails cleanly if unreachable within Cap (the count-all crisis,
%   or a fraction target with no partition available below stage 3).
u_min_cost(Stage, Target, Cap, MinCost, Witness) :-
    u_initial(S0),
    bfs_u(Stage, Target, [S0-[]], [S0], 0, Cap, MinCost, Witness).

bfs_u(_Stage, Target, Frontier, _Visited, Depth, _Cap, Depth, Witness) :-
    member(u(V, _)-Rev, Frontier),
    V =:= Target,
    !,
    reverse(Rev, Witness).
bfs_u(Stage, Target, Frontier, Visited, Depth, Cap, MinCost, Witness) :-
    Depth < Cap,
    findall(S1-[M|Rev],
            ( member(S-Rev, Frontier),
              u_move(Stage, Target, S, M, S1, _),
              bounded_unit(S1, Target),
              \+ seen(S1, Visited) ),
            Next0),
    dedup_u(Next0, [], Next),
    Next \= [],
    findall(S1, member(S1-_, Next), NewStates),
    append(Visited, NewStates, Visited1),
    Depth1 is Depth + 1,
    bfs_u(Stage, Target, Next, Visited1, Depth1, Cap, MinCost, Witness).

% Keep the search finite: unit numerator/denominator bounded by a window around
% the target's own denominator, value within [0, Target].
bounded_unit(u(V, U), Target) :-
    V >= 0, V =< Target,
    Uden is denominator(U), Unum is numerator(U),
    Uden =< 1728, Unum =< 1728.

seen(S, Visited) :- memberchk(S, Visited).

dedup_u([], _Seen, []).
dedup_u([S-P | T], Seen, Out) :-
    ( memberchk(S, Seen)
    -> dedup_u(T, Seen, Out)
    ; Out = [S-P | Rest], dedup_u(T, [S | Seen], Rest) ).

%!  u_strategy(+Witness, -Signature) is det.
u_strategy(W, Sig) :-
    ( W == []                       -> Sig = identity
    ; has(W, partition(_))          -> Sig = partition_then_iterate_unit_fraction
    ; has(W, regroup(_)), has(W, back_to_one) -> Sig = mixed_base_and_ones
    ; has(W, regroup(_))            -> Sig = regroup_then_iterate_composite_unit
    ; Sig = count_by_ones ).

has(W, P) :- \+ \+ member(P, W).


:- begin_tests(units_machine).

test(stage1_counts_by_ones) :-
    u_min_cost(s1, 6, 20, Cost, Witness),
    assertion(Cost == 6),
    assertion(Witness == [iterate, iterate, iterate, iterate, iterate, iterate]),
    u_strategy(Witness, Strategy),
    assertion(Strategy == count_by_ones).

test(stage2_regroups_and_iterates_composite_unit) :-
    u_min_cost(s2, 12, 20, Cost, Witness),
    assertion(Cost == 2),
    assertion(Witness == [regroup(12), iterate]),
    u_strategy(Witness, Strategy),
    assertion(Strategy == regroup_then_iterate_composite_unit).

test(stage2_cannot_reach_fraction_unit) :-
    assertion(\+ u_min_cost(s2, 1 rdiv 3, 20, _Cost, _Witness)).

test(stage3_partitions_and_iterates_unit_fraction) :-
    u_min_cost(s3, 4 rdiv 3, 20, Cost, Witness),
    assertion(Cost == 3),
    assertion(Witness == [iterate, partition(3), iterate]),
    u_strategy(Witness, Strategy),
    assertion(Strategy == partition_then_iterate_unit_fraction).

:- end_tests(units_machine).
