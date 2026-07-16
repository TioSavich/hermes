/** <module> reorg_fraction_of_fraction — the shifting-referent cliff (Band 4)
 *
 * Fifth domain instance; engine reused unchanged. Builds on Band 3: level 1 = Stage 2
 * units coordination (cannot hold three levels of units at once); level 2 = Stage 3
 * (holds the global whole as the referent while operating on an embedded unit).
 *
 * The cliff (Hackenberg & Tillema 2009): take A/B of C/D and name the result. The
 * correct name is relative to the GLOBAL whole: (A*C)/(B*D). A Stage-2 learner partitions
 * the local C/D bar and names the result against THAT bar — e.g. 2/3 of 4/5 named 8/12
 * instead of 8/15 (Bridget's year-long pattern), because the 4/5 bar collapses into "the
 * whole I'm working in." Only Stage 3, holding the global whole and the embedded unit at
 * once, names it correctly.
 *
 * The cliff falls out: naming against the local bar is available at level 1; naming
 * against the global whole needs level 2, so the correct (A*C)/(B*D) is unreachable
 * until the third level of units is held.
 *
 * Problem term:  ff(A, B, C, D)             (A/B of C/D)
 * State term:    s(A, B, C, D, Referent)    Referent in {none, local, global}
 */

:- module(reorg_fraction_of_fraction, []).

:- multifile
       reorganize:rd_initial/4,
       reorganize:rd_goal/2,
       reorganize:rd_move/6,
       reorganize:rd_baseline/3,
       reorganize:rd_level_above/3,
       reorganize:rd_result/3.

% The `name_global` move is backed by the area-model fraction-of-fraction automaton.
:- use_module(math(fraction_action_pairs), [run_fraction_action/5]).

reorganize:rd_initial(fraction_of_fraction, ff(A, B, C, D), _Level, s(A, B, C, D, none)).

% Correct only when the result is named against the global whole.
reorganize:rd_goal(fraction_of_fraction, s(_A, _B, _C, _D, global)).

reorganize:rd_result(fraction_of_fraction, s(A, B, C, D, global), fraction(Num, Den)) :-
    Num is A * C,
    Den is B * D.

reorganize:rd_baseline(fraction_of_fraction, ff(_A, B, _C, D), Cost) :- Cost is B * D.

reorganize:rd_level_above(fraction_of_fraction, Level0, Level1) :-
    Level1 is Level0 + 1,
    Level1 =< 2.

% Name the result against the LOCAL bar (the C/D bar treated as the whole): the
% Stage-2 deformation. Available at any level; never the correct global name.
reorganize:rd_move(fraction_of_fraction, _Level, s(A, B, C, D, none), name_local,
                   s(A, B, C, D, local), 1).

% Name the result against the GLOBAL whole, holding three levels of units at once:
% Stage 3, available at level >= 2.
reorganize:rd_move(fraction_of_fraction, Level, s(A, B, C, D, none), name_global,
                   s(A, B, C, D, global), 1) :-
    Level >= 2,
    % fires only if the recursive part-of-part automaton (name against the global
    % whole) genuinely executes for A/B of C/D.
    run_fraction_action(area_model_part_of_part, fraction_pair(A, B, C, D), unit(whole), _, _).
