/** <module> Fraction ordering through common denominators or numerators */

:- module(smr_frac_common_unit_compare,
          [ run_common_unit_compare/6,
            run_additive_parts_compare/6
          ]).

:- use_module(math(comparison_helpers),
              [valid_fraction/2, fraction_order/7, integer_order/3]).
:- use_module(math(integer_helpers), [add_ints/3, multiply_ints/3]).

run_common_unit_compare(N, D1, N, D2, Result, History) :-
    valid_fraction(N, D1), valid_fraction(N, D2),
    integer_order(D1, D2, DenominatorOrder),
    invert_order(DenominatorOrder, Result),
    History = [
        hist(q_init, init(fraction(N, D1), fraction(N, D2))),
        hist(q_common_numerator, shared_numerator(N)),
        hist(q_transform_commensurate_1, unchanged(fraction(N, D1))),
        hist(q_transform_commensurate_2, unchanged(fraction(N, D2))),
        hist(q_measure_with_co_unit, same_count_different_unit_sizes(N)),
        hist(q_compare_same_numerator,
             inverse_denominator_relation(D1, D2, Result)),
        hist(q_emit_order, emit(Result)),
        hist(q_accept, accept(Result))
    ], !.
run_common_unit_compare(N1, D1, N2, D2, Result, History) :-
    fraction_order(N1, D1, N2, D2, Result, T1-H1, T2-H2),
    multiply_ints(D1, D2, CommonDenominator),
    History = [
        hist(q_init, init(fraction(N1, D1), fraction(N2, D2))),
        hist(q_common_partition, common_denominator(CommonDenominator)),
        hist(q_transform_commensurate_1,
             transformed(fraction(N1, D1), fraction(T1, CommonDenominator), H1)),
        hist(q_transform_commensurate_2,
             transformed(fraction(N2, D2), fraction(T2, CommonDenominator), H2)),
        hist(q_measure_with_co_unit,
             co_measure(unit_fraction(1, CommonDenominator), T1, T2)),
        hist(q_compare_same_denominator, compare_counts(T1, T2, Result)),
        hist(q_emit_order, emit(Result)),
        hist(q_accept, accept(Result))
    ].

run_additive_parts_compare(N1, D1, N2, D2, Result, History) :-
    valid_fraction(N1, D1), valid_fraction(N2, D2),
    add_ints(N1, D1, Sum1), add_ints(N2, D2, Sum2),
    integer_order(Sum1, Sum2, Result),
    History = [
        hist(q_init, init(fraction(N1, D1), fraction(N2, D2))),
        hist(q_common_partition, no_common_unit_constructed),
        hist(q_add_numerator_denominator, first(N1, D1, Sum1)),
        hist(q_add_numerator_denominator, second(N2, D2, Sum2)),
        hist(q_measure_with_co_unit, omitted),
        hist(q_compare_same_denominator, compare_unlike_sums(Sum1, Sum2, Result)),
        hist(q_emit_order, emit(Result)),
        hist(q_accept, accept(Result))
    ].

invert_order(equivalent, equivalent).
invert_order(less_than, greater_than).
invert_order(greater_than, less_than).
