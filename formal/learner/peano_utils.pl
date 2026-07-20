/** <module> Peano conversion utilities
 *
 * Shared integer <-> Peano conversions for the learner runtime. Keeping these
 * here prevents semantic drift across the ORR server, execution handler, and
 * archived synthesis shim.
 */
:- module(peano_utils,
          [ peano_to_int/2,
            int_to_peano/2
          ]).

%! peano_to_int(+Peano, -Int) is det.
peano_to_int(0, 0) :- !.
peano_to_int(s(N), Int) :-
    peano_to_int(N, SubInt),
    Int is SubInt + 1.

%! int_to_peano(+Int, -Peano) is det.
int_to_peano(0, 0) :- !.
int_to_peano(N, s(Peano)) :-
    N > 0,
    N1 is N - 1,
    int_to_peano(N1, Peano).
