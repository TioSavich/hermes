/** <module> reorganize — domain-agnostic reorganization-as-search
 *
 * The "Reorganize" step of the ORR cycle, factored so it knows nothing about
 * the domain it reorganizes. On crisis, it searches a domain's primitive moves
 * for a path cheaper than the strategy that failed, and classifies the crisis:
 *
 *   - cheaper path at the current level        -> EFFICIENCY  (install it)
 *   - none here, one a level up                -> ACCOMMODATION (the level-up
 *                                                 is the reorganization)
 *   - no improving path anywhere               -> needs_oracle (honest boundary)
 *
 * Everything domain-specific lives behind a six-predicate interface, supplied
 * by a "reorganization domain" module (see
 * formal/learner/reorg_domains/arithmetic.pl for one whole-number instance):
 *
 *   rd_initial(Domain, Problem, Level, State)        the start state
 *   rd_goal(Domain, State)                           is this a goal?
 *   rd_move(Domain, Level, Inventory, S0, Move, S1, Cost)
 *                                                    a primitive move (Level
 *                                                    and acquired strategies
 *                                                    gate what is available)
 *   rd_baseline(Domain, Problem, Cost)               cost of the failed strategy
 *   rd_level_above(Domain, Level0, Level1)           the developmental ladder
 *   rd_result(Domain, GoalState, Result)             read the answer off a goal
 *
 * The engine never mentions a base, a number, partitioning, or any domain.
 * Reorganizing whole numbers, fractions, or vocabulary synonyms is the same
 * shape: write the six predicates for the domain.
 */

:- module(reorganize,
          [ reorganize/5,          % +Domain, +Problem, +Level0, +Inventory, -Outcome
            reorganize/4,          % legacy stage-only caller
            run_learned_path/4,    % +Strat, +Inventory, -Result, -StateTrace
            run_learned_path/3,    % legacy stage-only caller
            cheapest_path/6        % +Domain, +Problem, +Level, +Inventory, +Bound, -Path
          ]).

:- use_module(library(lists)).

% The domain interface. Instances add clauses to these (reorganize:rd_*).
:- multifile
       rd_initial/4,
       rd_goal/2,
       rd_move/7,
       rd_baseline/3,
       rd_level_above/3,
       rd_result/3.

%!  reorganize(+Domain, +Problem, +Level0, +Inventory, -Outcome) is det.
%
%   Search at the learner's current level; classify by whether an improving
%   path is found there, one level up, or nowhere.
reorganize(Domain, Problem, Level0, Inventory, Outcome) :-
    rd_baseline(Domain, Problem, Base),
    search_bound(Base, Bound),
    (   improving_strat(Domain, Problem, Level0, Inventory, Base, Bound, Strat)
    ->  Outcome = reorganized(efficiency, Level0, Strat)
    ;   rd_level_above(Domain, Level0, Level1),
        improving_strat(Domain, Problem, Level1, Inventory, Base, Bound, Strat)
    ->  Outcome = reorganized(accommodation, Level1, Strat)
    ;   Outcome = needs_oracle
    ).

% Legacy learner callers in strategy_synthesis, execution_handler, and
% reorganization_engine still use the stage-only interface. Empty inventory
% preserves that established route.
reorganize(Domain, Problem, Level0, Outcome) :-
    reorganize(Domain, Problem, Level0, [], Outcome).

%!  search_bound(+Baseline, -Bound) is det.
%
%   Generous-but-capped move budget. The search is brute-force, so the cap keeps
%   it bounded; the slack lets a make-a-base-style detour (a little longer than
%   the cheapest conceivable) be found.
search_bound(Base, Bound) :- Bound is min(Base + 2, 12).

%!  improving_strat(+Domain, +Problem, +Level, +Base, +Bound, -Strat) is semidet.
%
%   The cheapest path at Level is strictly cheaper than the failed strategy.
improving_strat(Domain, Problem, Level, Inventory, Base, Bound,
                strat(Domain, Problem, Level, path(Cost, Moves))) :-
    cheapest_path(Domain, Problem, Level, Inventory, Bound, path(Cost, Moves)),
    Cost < Base.

%!  cheapest_path(+Domain, +Problem, +Level, +Inventory, +Bound, -Path) is semidet.
%
%   The lowest-cost goal-reaching path within Bound, or failure if none exists.
cheapest_path(Domain, Problem, Level, Inventory, Bound, Best) :-
    rd_initial(Domain, Problem, Level, S0),
    findall(path(Cost, Moves),
            bounded_path(Domain, Level, Inventory, S0, Bound,
                         [S0], [], 0, Moves, Cost),
            Paths),
    Paths \== [],
    sort(Paths, [Best | _]).     % path(Cost, Moves): standard order sorts by Cost

bounded_path(Domain, _Level, _Inventory, S, _Bound, _Visited,
             RevAcc, Cost, Moves, Cost) :-
    rd_goal(Domain, S),
    reverse(RevAcc, Moves).
bounded_path(Domain, Level, Inventory, S, Bound, Visited,
             RevAcc, Cost0, Moves, Cost) :-
    Bound > 0,
    \+ rd_goal(Domain, S),
    rd_move(Domain, Level, Inventory, S, M, S1, MC),
    \+ memberchk(S1, Visited),
    Bound1 is Bound - 1,
    Cost1 is Cost0 + MC,
    bounded_path(Domain, Level, Inventory, S1, Bound1, [S1 | Visited],
                 [M | RevAcc], Cost1, Moves, Cost).

%!  run_learned_path(+Strat, +Inventory, -Result, -StateTrace) is semidet.
%
%   Re-execute an installed strategy by stepping its moves through the domain,
%   reading the result off the goal state. Genuine re-execution, not retrieval:
%   each move fires only if its preconditions hold at that step (a recall move
%   needs the learner to still possess that fact at that level), so a corrupted
%   path or a missing capability makes re-execution fail rather than return a
%   stored answer.
run_learned_path(strat(Domain, Problem, Level, path(_Cost, Moves)), Inventory,
                 Result, Trace) :-
    rd_initial(Domain, Problem, Level, S0),
    fold_moves(Domain, Level, Inventory, Moves, S0, [S0], SF, RevTrace),
    rd_goal(Domain, SF),
    rd_result(Domain, SF, Result),
    reverse(RevTrace, Trace).

run_learned_path(Strat, Result, Trace) :-
    run_learned_path(Strat, [], Result, Trace).

fold_moves(_Domain, _Level, _Inventory, [], S, Acc, S, Acc).
fold_moves(Domain, Level, Inventory, [M | Ms], S0, Acc, SF, Trace) :-
    once(rd_move(Domain, Level, Inventory, S0, M, S1, _Cost)),
    fold_moves(Domain, Level, Inventory, Ms, S1, [S1 | Acc], SF, Trace).
