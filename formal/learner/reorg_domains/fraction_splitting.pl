/** <module> reorg_fraction_splitting — the reversibility/splitting cliff (Band 2)
 *
 * Third domain instance; engine reused unchanged. Builds on Band 1: a learner
 * here already disembeds and iterates (forward), so level 1 = "can iterate but
 * not split"; level 2 = "splitting unlocked."
 *
 * The reversibility cliff (Steffe 2002; Norton 2008; Wilkins & Norton 2011): given
 * a part that is M/D of a hidden whole, find the whole. A non-splitter ITERATES
 * the given part (repeats it — 3/8, 6/8, 9/8, overshooting) and never recovers the
 * whole. Splitting — the simultaneous coordination of partitioning and iterating as
 * one reversible operation — partitions the given M/D into its M unit parts,
 * recovering 1/D, and rebuilds the whole. Norton & Wilkins (2013): splitting
 * "cannot be directly taught" — it is a reorganization the learner must construct.
 * In this model that is exactly what it is: at level 1 there is NO path to the
 * whole (only the iterate-the-given deformation), and the operation cannot be
 * handed over — the level-up is the construction.
 *
 * Problem term:  reverse(M, D)        (given M/D of a hidden whole, find the whole)
 * State term:    s(M, D, Status)      Status in {given, whole_recovered, overshot}
 */

:- module(reorg_fraction_splitting, []).

:- multifile
       reorganize:rd_initial/4,
       reorganize:rd_goal/2,
       reorganize:rd_move/6,
       reorganize:rd_baseline/3,
       reorganize:rd_level_above/3,
       reorganize:rd_result/3.

% The `split` move IS the runnable splitting action automaton (Band 2 wiring).
:- use_module(math(fraction_action_pairs), [run_fraction_action/5]).

reorganize:rd_initial(fraction_splitting, reverse(M, D), _Level, s(M, D, given)).

reorganize:rd_goal(fraction_splitting, s(_M, _D, whole_recovered)).

% The recovered whole is the unit whole, D/D.
reorganize:rd_result(fraction_splitting, s(_M, D, whole_recovered), fraction(D, D)).

reorganize:rd_baseline(fraction_splitting, reverse(M, D), Cost) :- Cost is M + D + 1.

reorganize:rd_level_above(fraction_splitting, Level0, Level1) :-
    Level1 is Level0 + 1,
    Level1 =< 2.

% Splitting: partition the given M/D into its M unit parts and rebuild the whole,
% as one reversible operation. Available at level >= 2.
reorganize:rd_move(fraction_splitting, Level, s(M, D, given), split,
                   s(M, D, whole_recovered), 1) :-
    Level >= 2,
    % fires only if the splitting FSM (partition into D, iterate the unit D
    % times, recognize the inverse) genuinely executes for this base.
    run_fraction_action(splitting, 1, D, _, _).

% Iterate the given part: the non-splitter's move — repeats M/D, overshooting.
% Available at any level, never reaches the whole.
reorganize:rd_move(fraction_splitting, _Level, s(M, D, given), iterate_given,
                   s(M, D, overshot), 1).
