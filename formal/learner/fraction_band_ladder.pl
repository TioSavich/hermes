/** <module> fraction_band_ladder — the reorganization ladder, made inspectable
 *
 * Drives the SAME engine (`formal/learner/reorganize.pl`) across the four fraction
 * bands (splitting -> improper -> fraction-of-fraction -> fractions-to-algebra),
 * and assembles, for any problem in those domains, a falsifiable record of one
 * reorganization:
 *
 *   1. what the learner TRIED at its current level and why every attempt
 *      dead-ends (the exhaustive search, enumerated — not a scripted "I give up");
 *   2. the reorganization itself (a level-up unlocks a move that was not there);
 *   3. the method it BUILT — the primitive partition/iterate steps of the real
 *      action automaton now backing that move;
 *   4. RE-EXECUTING the built method move-by-move to get the answer by doing,
 *      not by retrieval (`run_learned_path/3` re-fires every move).
 *
 * No oracle is consulted: `reorganize/4` has no teacher/oracle path; the strategy
 * is found purely by searching the domain's primitive moves. This module only
 * reads the engine; it installs nothing global.
 */

:- module(fraction_band_ladder,
          [ story_for/3,            % +Domain, +Problem, -Story (dict)
            ladder_stories/1,       % -Stories (list of dicts)
            ladder_json/1,          % -Dict  (for the HTTP demo)
            print_story/1,          % +Story
            print_ladder/0,
            band_default/3          % ?Order, ?Domain, ?Problem
          ]).

:- use_module(learner(reorganize),
              [ reorganize/4, run_learned_path/3 ]).
:- use_module(learner('reorg_domains/fraction_splitting')).
:- use_module(learner('reorg_domains/fraction_improper')).
:- use_module(learner('reorg_domains/fraction_of_fraction')).
:- use_module(learner('reorg_domains/fraction_algebra')).
:- use_module(math(fraction_action_pairs), [ run_fraction_action/5 ]).
:- use_module(library(lists)).
:- use_module(library(apply), [maplist/3, include/3]).


%!  band_default(?Order, ?Domain, ?Problem) is nondet.
%   The headline problem for each band (used by the ladder and as demo defaults).
band_default(2, fraction_splitting,     reverse(3, 8)).
band_default(3, fraction_improper,      make_improper(7, 5)).
band_default(4, fraction_of_fraction,   ff(2, 3, 4, 5)).
band_default(5, fraction_algebra,       relate(3, 5)).

band_name(fraction_splitting,   "splitting (reversibility)").
band_name(fraction_improper,    "improper fractions (fractions as numbers)").
band_name(fraction_of_fraction, "fraction of a fraction (shifting referent)").
band_name(fraction_algebra,     "fractions to algebra (solve for the unknown)").

band_question(fraction_splitting, reverse(M, D),
              S) :- format(string(S),
              "A part is ~w/~w of a hidden whole. Find the whole.", [M, D]).
band_question(fraction_improper, make_improper(N, D),
              S) :- format(string(S),
              "Make ~w/~w — more parts than fit in one whole — as a number.", [N, D]).
band_question(fraction_of_fraction, ff(A, B, C, D),
              S) :- format(string(S),
              "Take ~w/~w of ~w/~w and name it against the original whole.", [A, B, C, D]).
band_question(fraction_algebra, relate(P, Q),
              S) :- format(string(S),
              "Relate two unknowns by the fraction ~w/~w (use it as an operator).", [P, Q]).


% ---- the runnable action automaton backing each band's unlocked move --------

%!  backing_trace(+Domain, +Problem, -Kind, -Result, -Steps) is semidet.
backing_trace(fraction_splitting, reverse(_M, D), splitting, Result, Steps) :-
    run_fraction_action(splitting, 1, D, Outcome, Trace),
    outcome_result(Outcome, Result),
    steps_strings(Trace, Steps).
backing_trace(fraction_improper, make_improper(N, D), improper_fraction_iteration, Result, Steps) :-
    run_fraction_action(improper_fraction_iteration, N, D, Outcome, Trace),
    outcome_result(Outcome, Result),
    steps_strings(Trace, Steps).
backing_trace(fraction_of_fraction, ff(A, B, C, D), area_model_part_of_part, Result, Steps) :-
    run_fraction_action(area_model_part_of_part, fraction_pair(A, B, C, D), unit(whole), Outcome, Trace),
    outcome_result(Outcome, Result),
    steps_strings(Trace, Steps).
backing_trace(fraction_algebra, relate(P, Q), solve_for_unit, Result, Steps) :-
    run_fraction_action(solve_for_unit, solve(P, Q), P, Outcome, Trace),
    outcome_result(Outcome, Result),
    steps_strings(Trace, Steps).

outcome_result(action_outcome(_, Fields), Result) :-
    member(result(R), Fields),
    term_string(R, Result).

% Keep only the legible top-level steps; drop the raw kernel sub-traces (huge
% tally structures) that would overwhelm a non-coder reader. The dropped traces
% are still in the underlying Prolog outcome for anyone who wants to dig in.
steps_strings(Trace, Steps) :-
    include(legible_step, Trace, Legible),
    maplist(readable_step, Legible, Steps).

legible_step(Step) :- \+ noisy_step(Step).

noisy_step(Step) :-
    functor(Step, F, 1),
    memberchk(F, [partition_trace, iterate_trace, solve_trace, kernel_trace,
                  recursive_partition_trace]).

readable_step(Step, S) :- term_string(Step, S).


% ---- making the search visible (the exhaustive level-N attempts) ------------

%!  explore_paths(+Domain, +Problem, +Level, +MaxDepth, -Paths) is det.
%
%   Every root-to-terminal move sequence at Level, each tagged with how it ends:
%   `goal` (reached the answer), `dead_end` (no move available, not the goal), or
%   `depth_limit`. At a pre-reorganization level the productive move is absent,
%   so no path is tagged `goal` — the "stuck" is a fact about the search, not a
%   scripted message.
explore_paths(Domain, Problem, Level, MaxDepth, Paths) :-
    reorganize:rd_initial(Domain, Problem, Level, S0),
    findall(_{moves: MoveStrs, status: Status},
            ( walk(Domain, Level, S0, MaxDepth, [], Moves, Status),
              maplist(readable_step, Moves, MoveStrs) ),
            Paths0),
    sort(Paths0, Paths).

walk(Domain, _Level, S, _D, RevAcc, Moves, goal) :-
    reorganize:rd_goal(Domain, S),
    !,
    reverse(RevAcc, Moves).
walk(Domain, Level, S, D, RevAcc, Moves, Status) :-
    \+ reorganize:rd_goal(Domain, S),
    D > 0,
    findall(M-S1, reorganize:rd_move(Domain, Level, S, M, S1, _), Succ),
    (   Succ == []
    ->  reverse(RevAcc, Moves), Status = dead_end
    ;   D1 is D - 1,
        member(M-S1, Succ),
        walk(Domain, Level, S1, D1, [M | RevAcc], Moves, Status)
    ).
walk(Domain, Level, S, 0, RevAcc, Moves, depth_limit) :-
    \+ reorganize:rd_goal(Domain, S),
    findall(_, reorganize:rd_move(Domain, Level, S, _, _, _), [_|_]),
    reverse(RevAcc, Moves).

reached_goal(Paths) :- member(P, Paths), get_dict(status, P, goal).


% ---- assembling one reorganization story ------------------------------------

%!  story_for(+Domain, +Problem, -Story) is semidet.
%
%   The full falsifiable record for reorganizing Problem in Domain, starting at
%   level 1.
story_for(Domain, Problem, Story) :-
    ( band_default(Order, Domain, _) -> true ; Order = 0 ),
    band_name(Domain, Name),
    band_question(Domain, Problem, Question),
    search_depth(Domain, Problem, MaxDepth),
    % 1. the stuck level
    explore_paths(Domain, Problem, 1, MaxDepth, L1Paths),
    ( reached_goal(L1Paths) -> L1Goal = true ; L1Goal = false ),
    % 2. the reorganization (engine, starting at level 1)
    reorganize(Domain, Problem, 1, Outcome),
    outcome_story(Outcome, Domain, Problem, MaxDepth, OutDict),
    term_string(Problem, ProblemStr),
    Story = _{ order: Order,
               name: Name,
               domain: Domain,
               problem: ProblemStr,
               question: Question,
               level1_attempts: L1Paths,
               level1_reached_goal: L1Goal,
               result: OutDict }.

term_str(T, S) :- term_string(T, S).

search_depth(fraction_improper, make_improper(N, _), D) :- !, D is N + 2.
search_depth(_, _, 6).

outcome_story(needs_oracle, _, _, _,
              _{ kind: "needs_oracle",
                 note: "No improving path at this level or one above — the honest boundary; the engine would have to ask a teacher." }).
outcome_story(reorganized(Kind, ToLevel, Strat), Domain, Problem, MaxDepth, Dict) :-
    Strat = strat(_, _, _, path(Cost, Moves)),
    maplist(readable_step, Moves, MoveStrs),
    % the built method re-executes move-by-move (not retrieval)
    ( run_learned_path(Strat, ReexecResult, _) -> term_string(ReexecResult, ReexecStr)
    ;  ReexecStr = "RE-EXECUTION FAILED" ),
    % the runnable automaton now backing the unlocked move
    ( backing_trace(Domain, Problem, BKind, BResult, BSteps)
    -> Backing = _{ automaton: BKind, result: BResult, steps: BSteps }
    ;  Backing = _{ automaton: none, result: "", steps: [] } ),
    % what the unlocked level can now reach
    explore_paths(Domain, Problem, ToLevel, MaxDepth, L2Paths),
    Dict = _{ kind: Kind,
              unlocked_at_level: ToLevel,
              installed_path: MoveStrs,
              installed_cost: Cost,
              reexecuted_result: ReexecStr,
              built_method: Backing,
              level_after_attempts: L2Paths }.


%!  ladder_stories(-Stories) is det.
ladder_stories(Stories) :-
    findall(Story,
            ( band_default(_, Domain, Problem),
              story_for(Domain, Problem, Story) ),
            Stories).

%!  ladder_json(-Dict) is det.
ladder_json(_{ claim: "Each band: the learner gets stuck (search exhausts, no path), reorganizes (a level-up unlocks a move), and the unlocked move IS a runnable method built from the primitives partition and iterate. Nothing is looked up; the method is re-run move-by-move to get the answer.",
               not_claimed: "The machine is not conscious and wants nothing. The ladder of levels is part of the model (from the research on children's fraction stages), not invented by the machine. What it does on its own: get stuck, search, and build a working method from primitives without being handed the answer.",
               oracle_consulted: false,
               bands: Stories }) :-
    ladder_stories(Stories).


% ---- CLI pretty-printer (the no-browser verification path) -------------------

%!  print_ladder is det.
print_ladder :-
    ladder_stories(Stories),
    forall(member(S, Stories), print_story(S)).

%!  print_story(+Story) is det.
print_story(Story) :-
    format("~n=== Band ~w: ~w ===~n", [Story.order, Story.name]),
    format("Problem: ~w   (~w)~n", [Story.problem, Story.question]),
    format("~n1. At its current level it searched and got STUCK. Every attempt:~n", []),
    forall(member(P, Story.level1_attempts),
           format("     tried ~w  ->  ~w~n", [P.moves, P.status])),
    format("   reached the answer at this level? ~w~n", [Story.level1_reached_goal]),
    R = Story.result,
    ( get_dict(kind, R, needs_oracle)
    -> format("~n2. needs_oracle: ~w~n", [R.note])
    ;  format("~n2. REORGANIZED (~w): a move unlocked one level up (level ~w).~n",
              [R.kind, R.unlocked_at_level]),
       format("   installed path: ~w  (cost ~w)~n", [R.installed_path, R.installed_cost]),
       format("~n3. The method it BUILT (runnable automaton ~w), step by step:~n",
              [R.built_method.automaton]),
       forall(member(Step, R.built_method.steps),
              format("     - ~w~n", [Step])),
       format("   automaton result: ~w~n", [R.built_method.result]),
       format("~n4. RE-EXECUTED move-by-move (not retrieved): ~w~n", [R.reexecuted_result])
    ),
    nl.
