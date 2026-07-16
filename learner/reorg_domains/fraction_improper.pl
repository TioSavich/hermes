/** <module> reorg_fraction_improper — the fractions-as-numbers cliff (Band 3)
 *
 * Fourth domain instance; engine reused unchanged. Builds on Band 2: a learner
 * here can split and iterate a unit fraction within the whole (level 1 = partitive
 * scheme, proper fractions only); level 2 = the iterative fraction scheme (Stage 3
 * units coordination), which holds the referent whole fixed even while iterating
 * past it.
 *
 * The cliff (Hackenberg 2007; Tzur 1999; Hackenberg & Lee 2015): represent N/D with
 * N > D (an improper fraction). Under a partitive part-whole scheme a fraction is so
 * many parts OUT OF the whole, so N > D is impossible — "you can't take 9 out of 7."
 * The learner either rejects it or iterates only up to the whole (K =< D) and then,
 * forced further, redefines the whole (calls 7/5 "7/7"), losing the referent. Only
 * the iterative fraction scheme — iterating the unit 1/D a whole number of times while
 * keeping D/D as the fixed referent — reaches N/D as a number in its own right.
 *
 * The cliff falls out: iterating WITHIN the whole (K =< D) is available at level 1,
 * but iterating PAST the whole (K > D) needs level 2, so N > D is unreachable until
 * the iterative scheme unlocks.
 *
 * Problem term:  make_improper(N, D)        (N > D)
 * State term:    s(N, D, K, intact)         K = unit fractions iterated so far
 */

:- module(reorg_fraction_improper, []).

:- multifile
       reorganize:rd_initial/4,
       reorganize:rd_goal/2,
       reorganize:rd_move/6,
       reorganize:rd_baseline/3,
       reorganize:rd_level_above/3,
       reorganize:rd_result/3.

% The unlocking `iterate_past` move is backed by the improper-fraction automaton.
:- use_module(math(fraction_action_pairs), [run_fraction_action/5]).

reorganize:rd_initial(fraction_improper, make_improper(N, D), _Level, s(N, D, 0, intact)).

% Reached N iterations of the unit, with the referent whole still held: N/D as a number.
reorganize:rd_goal(fraction_improper, s(N, _D, N, intact)).

reorganize:rd_result(fraction_improper, s(N, D, N, intact), fraction(N, D)).

reorganize:rd_baseline(fraction_improper, make_improper(N, _D), Cost) :- Cost is N + 5.

reorganize:rd_level_above(fraction_improper, Level0, Level1) :-
    Level1 is Level0 + 1,
    Level1 =< 2.

% Iterate the unit fraction WITHIN the whole (up to D): available at any level.
reorganize:rd_move(fraction_improper, _Level, s(N, D, K, intact), iterate,
                   s(N, D, K1, intact), 1) :-
    K1 is K + 1,
    K1 =< D.

% Iterate PAST the whole, keeping the referent fixed: the iterative fraction scheme,
% available at level >= 2. This is the move that makes improper fractions reachable.
reorganize:rd_move(fraction_improper, Level, s(N, D, K, intact), iterate_past,
                   s(N, D, K1, intact), 1) :-
    Level >= 2,
    K >= D,
    K1 is K + 1,
    % fires only if the improper-fraction automaton (iterate the unit past the
    % whole, referent held) genuinely executes for N/D.
    run_fraction_action(improper_fraction_iteration, N, D, _, _).
