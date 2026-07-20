/** <module> reorg_arithmetic — the whole-number-addition reorganization domain
 *
 * The first instance of the reorganization-domain interface (see
 * formal/learner/reorganize.pl). It contributes clauses to the reorganize:rd_* hooks
 * for domains of the form arithmetic(Base).
 *
 * BASE-AGNOSTIC by construction: nothing here assumes base ten. The composite
 * units available at higher levels are powers of Base, and the base-partition
 * facts a learner possesses once the base is saturated (complements to the base
 * and base-plus-ones) are computed from Base. arithmetic(10) gives make-a-ten;
 * arithmetic(5) gives make-a-five; arithmetic(8) gives make-an-eight; all
 * through the same engine and the same domain.
 *
 * A developmental level is *earned*: possessing the base-partition fact space is
 * what makes the recall and composite-unit moves available (level >= 2). This
 * mirrors the crisis taxonomy's "taken as given prior to activity."
 *
 * Primitives: inc1, dec1 (count on / back by one), add_unit / sub_unit (move by
 * a composite unit), recall (regenerative use of a possessed base-partition
 * fact). These generalize formal/tools/carving/strategy_machine.pl's base-ten
 * primitives to arbitrary base; strategy_machine remains the carving substrate.
 *
 * Problem term:  add(A, B)        (find A + B)
 * State term:    state(Acc, Rem)  (Rem is the amount still owed to Acc)
 */

:- module(reorg_arithmetic, []).

:- use_module(library(lists)).

:- multifile
       reorganize:rd_initial/4,
       reorganize:rd_goal/2,
       reorganize:rd_move/6,
       reorganize:rd_baseline/3,
       reorganize:rd_level_above/3,
       reorganize:rd_result/3.

reorganize:rd_initial(arithmetic(_Base), add(A, B), _Level, state(A, B)).

reorganize:rd_goal(arithmetic(_Base), state(_Acc, 0)).

reorganize:rd_result(arithmetic(_Base), state(Acc, 0), Acc).

% Counting on from A by B ones is the strategy whose exhaustion triggered the
% crisis; a reorganization must beat it.
reorganize:rd_baseline(arithmetic(_Base), add(_A, B), B).

% The developmental ladder: ones (1), then composite units at 2 and 3.
reorganize:rd_level_above(arithmetic(_Base), Level0, Level1) :-
    Level1 is Level0 + 1,
    Level1 =< 3.

% ---- primitive moves ----

% Count on / count back by one: always available.
reorganize:rd_move(arithmetic(_Base), _Level, state(A, R), inc1, state(A1, R1), 1) :-
    A1 is A + 1,
    R1 is R - 1.
reorganize:rd_move(arithmetic(_Base), _Level, state(A, R), dec1, state(A1, R1), 1) :-
    A1 is A - 1,
    R1 is R + 1.

% Move by a composite unit (a power of Base), available at level >= 2.
reorganize:rd_move(arithmetic(Base), Level, state(A, R), add_unit(U), state(A1, R1), 1) :-
    composite_unit(Base, Level, U),
    A1 is A + U,
    R1 is R - U.
reorganize:rd_move(arithmetic(Base), Level, state(A, R), sub_unit(U), state(A1, R1), 1) :-
    composite_unit(Base, Level, U),
    A1 is A - U,
    R1 is R + U.

% Recall: regenerative use of a possessed base-partition fact, available at
% level >= 2. The fact's value is carried in the move so re-execution checks it.
reorganize:rd_move(arithmetic(Base), Level, state(A, R), recall(A, R, V), state(V, 0), 1) :-
    Level >= 2,
    R =\= 0,
    base_partition_fact(Base, A, R, V).

% ---- base-derived structure (the agnostic core) ----

%!  composite_unit(+Base, +Level, -Unit) is nondet.
%
%   At level k (>= 2), Base^(k-1) is an available composite unit: level 2 gives
%   Base, level 3 gives Base and Base*Base.
composite_unit(Base, Level, Unit) :-
    Level >= 2,
    between(2, Level, K),
    Pow is K - 1,
    Unit is Base ^ Pow.

%!  base_partition_fact(+Base, +A, +R, -V) is semidet.
%
%   The facts a learner possesses once the base's partition space is saturated,
%   derived entirely from Base:
%     - base-plus-ones:  Base + R = V   (e.g. base 10: 10 + 3 = 13)
%     - complements:     A + R = Base   (e.g. base 10:  8 + 2 = 10)
base_partition_fact(Base, Base, R, V) :-
    R > 0, R < Base,
    V is Base + R.
base_partition_fact(Base, A, R, Base) :-
    A > 0, A < Base,
    R =:= Base - A.
