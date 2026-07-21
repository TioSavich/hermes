/** <module> Grounded helpers shared by fraction-comparison automata */

:- module(comparison_helpers,
          [ valid_fraction/2,
            fraction_order/7,
            integer_order/3,
            absolute_difference/3
          ]).

:- use_module(formalization(grounded_arithmetic),
              [ integer_to_recollection/2, equal_to/2, smaller_than/2 ]).
:- use_module(math(integer_helpers), [subtract_ints/3]).
:- use_module(math(smr_mult_commutative_reasoning),
              [run_commutative_mult/4]).

valid_fraction(N, D) :-
    integer(N), N >= 0,
    integer(D), D > 0.

fraction_order(N1, D1, N2, D2, Relation, Cross1-Hist1, Cross2-Hist2) :-
    valid_fraction(N1, D1),
    valid_fraction(N2, D2),
    run_commutative_mult(N1, D2, Cross1, Hist1),
    run_commutative_mult(N2, D1, Cross2, Hist2),
    integer_order(Cross1, Cross2, Relation).

integer_order(A, B, equivalent) :-
    integer_to_recollection(A, RA),
    integer_to_recollection(B, RB),
    equal_to(RA, RB),
    !.
integer_order(A, B, less_than) :-
    integer_to_recollection(A, RA),
    integer_to_recollection(B, RB),
    smaller_than(RA, RB),
    !.
integer_order(_, _, greater_than).

absolute_difference(A, B, Difference) :-
    integer_order(A, B, Relation),
    absolute_difference_(Relation, A, B, Difference).

absolute_difference_(equivalent, _, _, 0).
absolute_difference_(less_than, A, B, Difference) :-
    subtract_ints(B, A, Difference).
absolute_difference_(greater_than, A, B, Difference) :-
    subtract_ints(A, B, Difference).
