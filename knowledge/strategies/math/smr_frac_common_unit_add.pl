/** <module> Fraction addition and subtraction through a common partition
 *
 * Productive machines transform both addends into a shared fractional
 * unit and then combine or remove counts of that unit.  The partition
 * choice is recorded in the trace: a shared denominator is kept, a
 * denominator that divides the other is refined into it, and unlike
 * denominators fall back to the denominator product, the same general
 * fallback `smr_frac_common_unit_compare` uses for ordering.
 *
 * Addends arrive as printed: `frac(N, D)`, `mixed(W, N, D)`, or
 * `whole(W)`.  Mixed and whole addends are renamed as fraction counts
 * inside the trace, so the renaming is part of the recorded doing
 * rather than silent preprocessing.
 *
 * The deformation partner adds numerators and adds denominators.  The
 * result is the mediant of the two fractions: wrong as a sum, and the
 * trace names the difference per input, but the mediant lies between
 * its arguments, so the same operation is proper for the different
 * practice of finding a fraction between two fractions.  The engine
 * records that betweenness fact and the sum agreement or divergence
 * for every input rather than adjudicating the class once.
 */

:- module(smr_frac_common_unit_add,
          [ run_common_unit_add/4,
            run_common_unit_subtract/4,
            run_add_numerator_denominator_sum/5,
            addend_as_fraction/3,
            mediant_sum_viability/5,
            mediant_betweenness/7
          ]).

:- use_module(math(comparison_helpers), [valid_fraction/2]).
:- use_module(math(integer_helpers),
              [add_ints/3, subtract_ints/3, multiply_ints/3]).

%!  addend_as_fraction(+Addend, -Fraction, -Renaming) is semidet.
%
%   Normalize a printed addend to a fraction count, keeping the
%   renaming evidence for the trace.
addend_as_fraction(frac(N, D), frac(N, D), kept_as_stated(frac(N, D))) :-
    valid_fraction(N, D).
addend_as_fraction(mixed(W, N, D), frac(Count, D),
                   renamed_mixed_number(mixed(W, N, D), frac(Count, D))) :-
    integer(W), W >= 1,
    integer(N), N >= 1,
    integer(D), D > N,
    multiply_ints(W, D, WholeCount),
    add_ints(WholeCount, N, Count).
addend_as_fraction(whole(W), frac(W, 1),
                   renamed_whole_number(whole(W), frac(W, 1))) :-
    integer(W), W >= 0.

%!  common_partition(+D1, +D2, -Common, -Evidence) is det.
common_partition(D, D, D, shared_unit(D)) :- !.
common_partition(D1, D2, D2, refine_first_into_second(D1, D2, Factor)) :-
    D2 mod D1 =:= 0, !,
    Factor is D2 // D1.
common_partition(D1, D2, D1, refine_second_into_first(D2, D1, Factor)) :-
    D1 mod D2 =:= 0, !,
    Factor is D1 // D2.
common_partition(D1, D2, Common, cross_partition_product(D1, D2, Common)) :-
    multiply_ints(D1, D2, Common).

commensurate_count(N, D, Common, Count) :-
    Factor is Common // D,
    multiply_ints(N, Factor, Count).

%!  run_common_unit_add(+Left, +Right, -Result, -History) is semidet.
run_common_unit_add(Left, Right, fraction(Sum, Common), History) :-
    addend_as_fraction(Left, frac(N1, D1), Renaming1),
    addend_as_fraction(Right, frac(N2, D2), Renaming2),
    common_partition(D1, D2, Common, PartitionEvidence),
    commensurate_count(N1, D1, Common, T1),
    commensurate_count(N2, D2, Common, T2),
    add_ints(T1, T2, Sum),
    History = [
        hist(q_init, init(Left, Right)),
        hist(q_rename_addends_as_counts, renamings(Renaming1, Renaming2)),
        hist(q_common_partition, partition(PartitionEvidence)),
        hist(q_transform_commensurate_1,
             transformed(frac(N1, D1), fraction(T1, Common))),
        hist(q_transform_commensurate_2,
             transformed(frac(N2, D2), fraction(T2, Common))),
        hist(q_measure_with_co_unit,
             co_measure(unit_fraction(1, Common), T1, T2)),
        hist(q_combine_counts, combined(T1, T2, Sum)),
        hist(q_emit_sum, emit(fraction(Sum, Common))),
        hist(q_accept, accept(fraction(Sum, Common)))
    ].

%!  run_common_unit_subtract(+Left, +Right, -Result, -History) is semidet.
%
%   The count removed may not exceed the count held: this machine's
%   domain is the nonnegative differences the K--5 guides print.  A
%   pair whose difference would be negative is refused, and that
%   refusal is the domain boundary, not an error path.
run_common_unit_subtract(Left, Right, fraction(Difference, Common), History) :-
    addend_as_fraction(Left, frac(N1, D1), Renaming1),
    addend_as_fraction(Right, frac(N2, D2), Renaming2),
    common_partition(D1, D2, Common, PartitionEvidence),
    commensurate_count(N1, D1, Common, T1),
    commensurate_count(N2, D2, Common, T2),
    T1 >= T2,
    subtract_ints(T1, T2, Difference),
    History = [
        hist(q_init, init(Left, Right)),
        hist(q_rename_addends_as_counts, renamings(Renaming1, Renaming2)),
        hist(q_common_partition, partition(PartitionEvidence)),
        hist(q_transform_commensurate_1,
             transformed(frac(N1, D1), fraction(T1, Common))),
        hist(q_transform_commensurate_2,
             transformed(frac(N2, D2), fraction(T2, Common))),
        hist(q_measure_with_co_unit,
             co_measure(unit_fraction(1, Common), T1, T2)),
        hist(q_remove_counts, removed(T1, T2, Difference)),
        hist(q_emit_difference, emit(fraction(Difference, Common))),
        hist(q_accept, accept(fraction(Difference, Common)))
    ].

%!  run_add_numerator_denominator_sum(+Left, +Right, -Result, -Viability,
%!                                    -History) is semidet.
%
%   Add the numerators and add the denominators.  No common unit is
%   constructed, so the emitted count has no shared referent.  Each run
%   records whether the mediant coincides with the sum on this input
%   and whether it lies between the two addends.
run_add_numerator_denominator_sum(Left, Right, fraction(MN, MD), Viability,
                                  History) :-
    addend_as_fraction(Left, frac(N1, D1), Renaming1),
    addend_as_fraction(Right, frac(N2, D2), Renaming2),
    add_ints(N1, N2, MN),
    add_ints(D1, D2, MD),
    % The true sum this run diverges from, computed with the same
    % partition helpers the productive machine uses.  A nested call to
    % the full productive machine would also work, but the deformation
    % needs only the value, and the helpers keep this clause's history
    % statically readable end to end.
    common_partition(D1, D2, SD, _PartitionEvidence),
    commensurate_count(N1, D1, SD, S1),
    commensurate_count(N2, D2, SD, S2),
    add_ints(S1, S2, SN),
    mediant_sum_viability(MN, MD, SN, SD, Viability),
    mediant_betweenness(N1, D1, N2, D2, MN, MD, Betweenness),
    History = [
        hist(q_init, init(Left, Right)),
        hist(q_rename_addends_as_counts, renamings(Renaming1, Renaming2)),
        hist(q_common_partition, no_common_unit_constructed),
        hist(q_add_numerator_denominator,
             numerators_and_denominators_added(N1 + N2 = MN, D1 + D2 = MD)),
        hist(q_measure_with_co_unit, omitted),
        hist(q_between_check, record_betweenness(Betweenness)),
        hist(q_viability_context, record_viability(Viability)),
        hist(q_emit_sum, emit(fraction(MN, MD))),
        hist(q_accept, accept(fraction(MN, MD)))
    ].

mediant_sum_viability(MN, MD, SN, SD,
                      viability(contextual_success,
                                condition(mediant_coincides_with_sum),
                                validity(contextually_correct))) :-
    MN * SD =:= SN * MD, !.
mediant_sum_viability(MN, MD, SN, SD,
                      viability(fails_in_context,
                                condition(mediant_diverges_from_sum),
                                expected(fraction(SN, SD)),
                                produced(fraction(MN, MD)),
                                validity(incorrect))).

%!  mediant_betweenness(+N1, +D1, +N2, +D2, +MN, +MD, -Fact) is det.
%
%   The recorded fact of the practice the operation is proper for:
%   the mediant of two fractions never leaves their closed interval.
mediant_betweenness(N1, D1, N2, D2, MN, MD, Fact) :-
    LowCross is min(N1 * D2, N2 * D1),
    HighCross is max(N1 * D2, N2 * D1),
    (   MN * D1 * D2 >= LowCross * MD,
        MN * D1 * D2 =< HighCross * MD
    ->  Fact = mediant_lies_between(fraction(N1, D1), fraction(N2, D2),
                                    fraction(MN, MD))
    ;   Fact = mediant_escapes_interval(fraction(N1, D1), fraction(N2, D2),
                                        fraction(MN, MD))
    ).
