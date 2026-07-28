/** <module> Decimal comparison by fraction/place-value coordination */

:- module(smr_decimal_fraction_compare,
          [ run_decimal_fraction_compare/6,
            run_decimal_scale_loss_compare/7,
            decimal_order_viability/3
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

%!  decimal_value_order(+N1, +S1, +N2, +S2, -Order) is semidet.
%
%   The order two written decimals stand in once their scales are aligned.
%   This is the arithmetic run_decimal_fraction_compare/6 records as a trace;
%   stated separately so a viability judgment can reach it without calling an
%   automaton entry point.
decimal_value_order(N1, S1, N2, S2, Order) :-
    decimal_operand(N1, S1), decimal_operand(N2, S2),
    common_scale(S1, S2, CommonScale),
    F1 is CommonScale // S1, F2 is CommonScale // S2,
    multiply_ints(N1, F1, A1), multiply_ints(N2, F2, A2),
    integer_order(A1, A2, Order).

%!  run_decimal_scale_loss_compare(+N1, +S1, +N2, +S2, -Result, -Viability, -History) is semidet.
%
%   Comparing the written numerals is contextually correct exactly when its
%   order agrees with the decimal-value order.  The condition names are shared
%   with the parallel decimal comparison deformation in decimal_action_pairs.
run_decimal_scale_loss_compare(N1, S1, N2, S2, Result, Viability, History) :-
    decimal_operand(N1, S1), decimal_operand(N2, S2),
    integer_order(N1, N2, Result),
    % Reach the sanctioned order through the plain helper, not through
    % run_decimal_fraction_compare/6. The transition-table extractor reads a
    % trace statically and treats a call to another run_ entry point as
    % delegation, which cost this automaton its whole tuple and dropped the
    % observed-signature count from 106 to 105. smr_frac_benchmark_compare's
    % gap automaton reaches its expected order the same way, through
    % fraction_order/7 rather than through a run_ predicate.
    decimal_value_order(N1, S1, N2, S2, Expected),
    decimal_order_viability(Expected, Result, Viability),
    History = [
        hist(q_init, init(decimal(N1, S1), decimal(N2, S2))),
        hist(q_identify_decimal_units, scales_seen_but_not_coordinated(S1, S2)),
        hist(q_express_as_fraction, omitted),
        hist(q_scale_loss, compare_written_numerals(N1, N2)),
        hist(q_compare_decimal_magnitudes, compare(N1, N2, Result)),
        hist(q_viability_context, Viability),
        hist(q_emit, emit(Result)),
        hist(q_accept, accept(Result))
    ].

decimal_order_viability(Expected, Expected,
                        viability(contextual_success,
                                  condition(written_numeral_order_coincides_with_decimal_value_order),
                                  validity(contextually_correct))) :- !.
decimal_order_viability(Expected, Produced,
                        viability(fails_in_context,
                                  condition(written_numeral_order_diverges_from_decimal_value_order),
                                  expected(Expected), produced(Produced),
                                  validity(incorrect))).

decimal_operand(N, S) :- integer(N), N >= 0, valid_scale(S).
valid_scale(1) :- !.
valid_scale(S) :- integer(S), S >= 10, power_of_ten(S).
power_of_ten(10) :- !.
power_of_ten(S) :- S > 10, 0 is S mod 10, Next is S // 10, power_of_ten(Next).

common_scale(S1, S2, S1) :- S1 >= S2, !.
common_scale(_, S2, S2).
