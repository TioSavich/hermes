/** <module> Decimal comparison by fraction/place-value coordination */

:- module(smr_decimal_fraction_compare,
          [ run_decimal_fraction_compare/6,
            run_decimal_scale_loss_compare/6
          ]).

:- use_module(math(comparison_helpers), [integer_order/3]).
:- use_module(math(integer_helpers), [multiply_ints/3]).

run_decimal_fraction_compare(N1, S1, N2, S2, Result, History) :-
    decimal_operand(N1, S1), decimal_operand(N2, S2),
    common_scale(S1, S2, CommonScale),
    F1 is CommonScale // S1, F2 is CommonScale // S2,
    multiply_ints(N1, F1, A1), multiply_ints(N2, F2, A2),
    integer_order(A1, A2, Result),
    History = [
        hist(q_init, init(decimal(N1, S1), decimal(N2, S2))),
        hist(q_identify_decimal_units, scales(S1, S2)),
        hist(q_express_as_fraction,
             fractions(fraction(N1, S1), fraction(N2, S2))),
        hist(q_align_place_value_units,
             common_scale(CommonScale, aligned_numerals(A1, A2))),
        hist(q_compare_decimal_magnitudes, compare(A1, A2, Result)),
        hist(q_emit, emit(Result)),
        hist(q_accept, accept(Result))
    ].

run_decimal_scale_loss_compare(N1, S1, N2, S2, Result, History) :-
    decimal_operand(N1, S1), decimal_operand(N2, S2),
    integer_order(N1, N2, Result),
    History = [
        hist(q_init, init(decimal(N1, S1), decimal(N2, S2))),
        hist(q_identify_decimal_units, scales_seen_but_not_coordinated(S1, S2)),
        hist(q_express_as_fraction, omitted),
        hist(q_scale_loss, compare_written_numerals(N1, N2)),
        hist(q_compare_decimal_magnitudes, compare(N1, N2, Result)),
        hist(q_emit, emit(Result)),
        hist(q_accept, accept(Result))
    ].

decimal_operand(N, S) :- integer(N), N >= 0, valid_scale(S).
valid_scale(1) :- !.
valid_scale(S) :- integer(S), S >= 10, power_of_ten(S).
power_of_ten(10) :- !.
power_of_ten(S) :- S > 10, 0 is S mod 10, Next is S // 10, power_of_ten(Next).

common_scale(S1, S2, S1) :- S1 >= S2, !.
common_scale(_, S2, S2).
