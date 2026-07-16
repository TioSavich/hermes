/** <module> Groups machine — multiplication and division as unit iteration
 *
 * The third slice of the units-coordination ladder, after the ENS add/sub
 * machine (tools/carving/strategy_machine.pl) and the fraction machine
 * (tools/carving/fraction_unit_machine.pl). The unifying primitive across all
 * three is ITERATE A UNIT, where the unit's grain differs:
 *
 *   strategy_machine : unit = 1 (inc1) or a base (add_unit(10|100))
 *   groups_machine   : unit = a COMPOSITE of size S (iterate_unit)   <-- here
 *   fraction_machine : unit = a unit fraction 1/B (iterate)
 *
 * Multiplication N x S and division T / D are the SAME search: reach a Target by
 * iterating a Unit. Multiplication gives (N, S) and asks for the product
 * (Target = N*S, Unit = S, the answer is read off as Made). Division gives
 * (T, D) and asks how many D-units reach T (Target = T, Unit = D, the quotient
 * is the count of iterate_unit steps). The resource ladder is the same shape as
 * the other machines:
 *
 *   level 1 : count_one only            -> count-all (cost = Target)
 *   level 2 : iterate_unit available    -> skip counting (cost = Target/Unit)
 *   level 3 : recall a known product    -> fact retrieval (cost = 1)
 *
 * Every move costs 1, so minimum cost is shortest path (BFS), as in the other
 * machines, and the reorganization landscape (count-all -> skip -> fact) falls
 * out of the search exactly as counting -> make-a-ten did for add/sub.
 */

:- module(groups_machine,
          [ g_initial/1,
            g_move/7,
            g_min_cost/6,
            g_strategy/2,
            known_product/3,
            stage_rank/2
          ]).

:- use_module(library(lists)).

g_initial(g(0)).

stage_rank(l1, 1).
stage_rank(l2, 2).
stage_rank(l3, 3).

% A small multiplication table is "known" at level 3 (recall).
known_product(A, B, P) :- between(1, 12, A), between(1, 12, B), P is A * B.

%!  g_move(+Stage, +Unit, +Target, +State0, -Move-State, -Cost) is nondet.
%
%   Moves over state g(Made), gated by stage. Unit and Target are the problem
%   parameters threaded by the search.
g_move(_Stage, _Unit, Target, g(M), count_one, g(M1), 1) :-
    M < Target, M1 is M + 1.
g_move(Stage, Unit, Target, g(M), iterate_unit, g(M1), 1) :-
    stage_rank(Stage, R), R >= 2, Unit > 1,
    M1 is M + Unit, M1 =< Target.
g_move(Stage, Unit, Target, g(0), recall(Target), g(Target), 1) :-
    stage_rank(Stage, R), R >= 3, Unit > 1,
    Q is Target // Unit, Q * Unit =:= Target,
    known_product(Q, Unit, Target).

%!  g_min_cost(+Stage, +Unit, +Target, +Cap, -MinCost, -Witness) is semidet.
%
%   Uniform-cost BFS to Made = Target. Fails cleanly if unreachable within Cap
%   (the count-all crisis for large products at level 1).
g_min_cost(Stage, Unit, Target, Cap, MinCost, Witness) :-
    g_initial(S0),
    bfs_g(Stage, Unit, Target, [S0-[]], [S0], 0, Cap, MinCost, Witness).

bfs_g(_Stage, _Unit, Target, Frontier, _Visited, Depth, _Cap, Depth, Witness) :-
    member(g(Target)-Rev, Frontier),
    !,
    reverse(Rev, Witness).
bfs_g(Stage, Unit, Target, Frontier, Visited, Depth, Cap, MinCost, Witness) :-
    Depth < Cap,
    findall(S1-[M|Rev],
            ( member(S-Rev, Frontier),
              g_move(Stage, Unit, Target, S, M, S1, _),
              \+ memberchk(S1, Visited) ),
            Next0),
    dedup_g(Next0, [], Next),
    Next \= [],
    findall(S1, member(S1-_, Next), NewStates),
    append(Visited, NewStates, Visited1),
    Depth1 is Depth + 1,
    bfs_g(Stage, Unit, Target, Next, Visited1, Depth1, Cap, MinCost, Witness).

dedup_g([], _Seen, []).
dedup_g([S-P | T], Seen, Out) :-
    ( memberchk(S, Seen)
    -> dedup_g(T, Seen, Out)
    ; Out = [S-P | Rest], dedup_g(T, [S | Seen], Rest) ).

%!  g_strategy(+Witness, -Signature) is det.
%   Name the path by the primitives it deploys (the CGI families).
g_strategy(W, Sig) :-
    ( W = [recall(_)|_] -> Sig = known_product_recall
    ; member(iterate_unit, W) -> Sig = skip_counting_composite_unit
    ; Sig = count_all_by_ones ).


:- begin_tests(groups_machine).

test(level1_counts_by_ones_to_target) :-
    g_min_cost(l1, 3, 12, 20, Cost, Witness),
    length(Witness, 12),
    assertion(Cost == 12),
    assertion(forall(member(Move, Witness), Move == count_one)),
    g_strategy(Witness, Strategy),
    assertion(Strategy == count_all_by_ones).

test(level2_iterates_composite_unit) :-
    g_min_cost(l2, 3, 12, 20, Cost, Witness),
    assertion(Cost == 4),
    assertion(Witness == [iterate_unit, iterate_unit, iterate_unit, iterate_unit]),
    g_strategy(Witness, Strategy),
    assertion(Strategy == skip_counting_composite_unit).

test(level3_recalls_known_product) :-
    g_min_cost(l3, 3, 12, 20, Cost, Witness),
    assertion(Cost == 1),
    assertion(Witness == [recall(12)]),
    g_strategy(Witness, Strategy),
    assertion(Strategy == known_product_recall).

test(insufficient_cap_fails_cleanly, [fail]) :-
    g_min_cost(l1, 3, 12, 11, _Cost, _Witness).

:- end_tests(groups_machine).
