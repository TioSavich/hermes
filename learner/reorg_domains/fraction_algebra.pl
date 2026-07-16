/** <module> reorg_fraction_algebra — the abandon-the-fraction cliff (Band 5)
 *
 * Sixth domain instance; engine reused unchanged. Builds on Bands 3-4: level 1 = Stage 2
 * (whole-number multiplicative relationships only); level 2 = Stage 3 with an interiorized
 * iterative fraction scheme, where a fraction can act multiplicatively on an unknown.
 *
 * The cliff (Hackenberg, Jones et al. 2017; Hackenberg & Sevinc 2022): express a fractional
 * relationship between two unknowns as an equation, e.g. s = (P/Q) f (the sunflower is 3/5
 * of the fern). A Stage-2 learner cannot multiply a quantity by a fraction to produce a
 * SMALLER quantity ("multiplication makes bigger"), so they abandon the fraction and fall
 * back to whole-number division (write the inverse whole-number relation instead). Only the
 * interiorized iterative fraction scheme lets the fraction operate on the unknown — and then
 * the reciprocal f = (Q/P) s follows.
 *
 * The cliff falls out: a whole-number relation is available at level 1; using the fraction
 * as an operator needs level 2, so the fractional equation is unreachable until the
 * iterative scheme is interiorized.
 *
 * Problem term:  relate(P, Q)               (express s = (P/Q) f)
 * State term:    s(P, Q, Equation)          Equation in {none, whole_number, fractional}
 */

:- module(reorg_fraction_algebra, []).

:- multifile
       reorganize:rd_initial/4,
       reorganize:rd_goal/2,
       reorganize:rd_move/6,
       reorganize:rd_baseline/3,
       reorganize:rd_level_above/3,
       reorganize:rd_result/3.

% The `fraction_operate` move is backed by the solve-for-unknown automaton.
:- use_module(math(fraction_action_pairs), [run_fraction_action/5]).

reorganize:rd_initial(fraction_algebra, relate(P, Q), _Level, s(P, Q, none)).

% Correct only when the fraction is used as the operator on the unknown.
reorganize:rd_goal(fraction_algebra, s(_P, _Q, fractional)).

% The equation uses the fraction P/Q as operator (and licenses the reciprocal Q/P).
reorganize:rd_result(fraction_algebra, s(P, Q, fractional),
                     equation(s = times(fraction(P, Q), f), reciprocal(fraction(Q, P)))).

reorganize:rd_baseline(fraction_algebra, relate(P, Q), Cost) :- Cost is P + Q + 1.

reorganize:rd_level_above(fraction_algebra, Level0, Level1) :-
    Level1 is Level0 + 1,
    Level1 =< 2.

% Fall back to a whole-number relation, dropping the fraction: the Stage-2 deformation.
% Available at any level; never expresses the fractional relationship.
reorganize:rd_move(fraction_algebra, _Level, s(P, Q, none), whole_number_relate,
                   s(P, Q, whole_number), 1).

% Use the fraction as an operator on the unknown: Stage 3 with the interiorized
% iterative fraction scheme, available at level >= 2.
reorganize:rd_move(fraction_algebra, Level, s(P, Q, none), fraction_operate,
                   s(P, Q, fractional), 1) :-
    Level >= 2,
    % fires only if the solve-for-unknown automaton (fraction as operator on an
    % unknown, partition-as-inverse-of-iterate) genuinely executes for P/Q.
    run_fraction_action(solve_for_unit, solve(P, Q), P, _, _).
