/** <module> Reorganization domains for subtraction, multiplication, and division
 *
 * These domains expose three different unit structures to the generic ORR
 * search. Subtraction removes units from a quantity, multiplication iterates a
 * composite group, and division measures how many divisor-sized groups can be
 * removed. They share an interface, not a fabricated common state machine.
 */

:- module(reorg_whole_number_operations, []).

:- multifile
       reorganize:rd_initial/4,
       reorganize:rd_goal/2,
       reorganize:rd_move/6,
       reorganize:rd_baseline/3,
       reorganize:rd_level_above/3,
       reorganize:rd_result/3.


% Subtraction as take-away. The composite-unit move preserves the direction of
% the action: both the accumulated quantity and the amount still to remove go
% down together.
reorganize:rd_initial(whole_number(subtract, _Base), subtract(A, B), _Level,
                      subtraction_state(A, B)).
reorganize:rd_goal(whole_number(subtract, _Base), subtraction_state(_A, 0)).
reorganize:rd_result(whole_number(subtract, _Base),
                     subtraction_state(Result, 0), Result).
reorganize:rd_baseline(whole_number(subtract, _Base), subtract(_A, B), B).

reorganize:rd_move(whole_number(subtract, _Base), _Level,
                   subtraction_state(A, R), count_back_one,
                   subtraction_state(A1, R1), 1) :-
    R > 0,
    A > 0,
    A1 is A - 1,
    R1 is R - 1.
reorganize:rd_move(whole_number(subtract, Base), Level,
                   subtraction_state(A, R), remove_composite_unit(U),
                   subtraction_state(A1, R1), 1) :-
    Level >= 2,
    subtraction_unit(Base, R, U),
    A >= U,
    A1 is A - U,
    R1 is R - U.


% Multiplication as iterating N equal groups of size S. count_item is the
% count-all baseline; iterate_composite_unit is available only after the group
% can be coordinated as one unit.
reorganize:rd_initial(whole_number(multiply, _Base), multiply(N, S), _Level,
                      multiplication_state(0, Target, S)) :-
    Target is N * S.
reorganize:rd_goal(whole_number(multiply, _Base),
                   multiplication_state(_Made, 0, _S)).
reorganize:rd_result(whole_number(multiply, _Base),
                     multiplication_state(Product, 0, _S), Product).
reorganize:rd_baseline(whole_number(multiply, _Base), multiply(N, S), Cost) :-
    Cost is N * S.

reorganize:rd_move(whole_number(multiply, _Base), _Level,
                   multiplication_state(Made, R, S), count_item,
                   multiplication_state(Made1, R1, S), 1) :-
    R > 0,
    Made1 is Made + 1,
    R1 is R - 1.
reorganize:rd_move(whole_number(multiply, _Base), Level,
                   multiplication_state(Made, R, S), iterate_composite_unit(S),
                   multiplication_state(Made1, R1, S), 1) :-
    Level >= 2,
    S > 1,
    R >= S,
    Made1 is Made + S,
    R1 is R - S.


% Division as measurement. The terminal state retains a remainder rather than
% discarding it; the learner result is the count of measured groups, matching
% divide_grounded/3's whole-number quotient.
reorganize:rd_initial(whole_number(divide, _Base), divide(Total, Divisor), _Level,
                      division_state(Total, Divisor, 0)).
reorganize:rd_goal(whole_number(divide, _Base),
                   division_state(Remainder, Divisor, _Q)) :-
    Remainder >= 0,
    Remainder < Divisor.
reorganize:rd_result(whole_number(divide, _Base),
                     division_state(_Remainder, _Divisor, Quotient), Quotient).
reorganize:rd_baseline(whole_number(divide, _Base), divide(Total, _Divisor), Total).

reorganize:rd_move(whole_number(divide, _Base), Level,
                   division_state(R, D, Q), measure_composite_unit(D),
                   division_state(R1, D, Q1), 1) :-
    Level >= 2,
    D > 0,
    R >= D,
    R1 is R - D,
    Q1 is Q + 1.


reorganize:rd_level_above(whole_number(_Operation, _Base), Level0, Level1) :-
    Level1 is Level0 + 1,
    Level1 =< 3.

subtraction_unit(Base, Remaining, Base) :-
    Base >= 2,
    Remaining >= Base.
