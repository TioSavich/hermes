/** <module> reorg_fraction — the disembedding-cliff reorganization domain (Band 1)
 *
 * The second instance of the reorganization-domain interface (see
 * formal/learner/reorganize.pl). It reuses the engine unchanged; everything here is the
 * six rd_* predicates for domains of the form `fraction`.
 *
 * This is the disembedding cliff (crisis taxonomy Band 1; Steffe & Olive 2010,
 * Hackenberg 2013). The task: partition a whole into N equal parts, take one
 * part, and name it as a fraction OF THE WHOLE (1/N). Doing so requires
 * DISEMBEDDING — taking a part out while holding the whole mentally intact. A
 * learner who cannot yet disembed (level 1) can only CUT a part off, which
 * consumes the whole, leaving the part to be named against the leftover ("1/3
 * because three are left") — a wrong part-to-whole name. No amount of in-activity
 * partitioning fixes this; only the units-restructuring that makes the part stand
 * alone while the whole is conserved. So the disembedding cliff is a reachability
 * cliff: there is NO correct-naming path until `disembed` is available, and the
 * level-up that unlocks it IS the reorganization.
 *
 * The engine is unchanged — the cliff "falls out" of cheapest_path failing at
 * level 1 (no goal-reaching path) and succeeding at level 2.
 *
 * Problem term:  name_part(N)                  (name one of N equal parts)
 * State term:    s(Target, Partitioned, Part, Whole)
 *                  Part  in {none, held}, Whole in {intact, destroyed}
 */

:- module(reorg_fraction, []).

:- multifile
       reorganize:rd_initial/4,
       reorganize:rd_goal/2,
       reorganize:rd_move/6,
       reorganize:rd_baseline/3,
       reorganize:rd_level_above/3,
       reorganize:rd_result/3.

reorganize:rd_initial(fraction, name_part(N), _Level, s(N, 0, none, intact)).

% A correct part-to-whole name is reachable when a part is held AND the whole is
% still conserved.
reorganize:rd_goal(fraction, s(_N, P, held, intact)) :- P > 0.

reorganize:rd_result(fraction, s(N, _P, held, intact), fraction(1, N)).

% The inadequate in-activity route does not reach correct naming; this is a
% reachability cliff, so the baseline is a nominal "laborious attempt" cost that
% scales with the parts and that the disembed path (cost 2) beats. What makes it
% the cliff is that level 1 has NO correct path at all, not that it is dearer.
reorganize:rd_baseline(fraction, name_part(N), Cost) :- Cost is N + 2.

% Band 1 needs only two levels: pre-disembedding (1) and disembedding (2).
reorganize:rd_level_above(fraction, Level0, Level1) :-
    Level1 is Level0 + 1,
    Level1 =< 2.

% ---- operations ----

% Partition the intact whole into its target number of equal parts. The whole is
% not destroyed by partitioning.
reorganize:rd_move(fraction, _Level, s(N, 0, none, intact), partition(N),
                   s(N, N, none, intact), 1).

% Disembed: take a part out WHILE holding the whole intact. The Stage-2
% operation, available at level >= 2. This is the move the whole cliff turns on.
reorganize:rd_move(fraction, Level, s(N, P, none, intact), disembed,
                   s(N, P, held, intact), 1) :-
    Level >= 2,
    P > 0.

% Cut off: physically separate a part. Available at any level, but it consumes
% the whole (whole -> destroyed), so the part can then only be named against the
% leftover. This is the level-1 route, and it never reaches a correct name.
reorganize:rd_move(fraction, _Level, s(N, P, none, intact), cut_off,
                   s(N, P, held, destroyed), 1) :-
    P > 0.
