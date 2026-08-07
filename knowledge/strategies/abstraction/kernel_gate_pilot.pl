:- encoding(utf8).
/** <module> Kernel/gate pilot — reusable mathematical-action kernels under genre gates
 *
 * WHAT THIS IS. An executable pilot of the formulation
 *
 *     strategy = gate(genre, representation) |> shell [ kernel ]
 *
 * on three cross-domain probes (complete_to_unit, iterate_to_target,
 * partition/regroup), three single-gate probes (bracket refinement,
 * place-sequence comparison, base-cycle recollection), and one pair-
 * enumeration kernel shared by two geometry gates. The kernel carries control
 * flow and actually computes. The gate supplies sorts, admissibility guards,
 * the named boundary, and result interpretation. Correct and incorrect doings
 * are instances or single local mutations of the same kernel run.
 *
 * This file is standalone and quarantined in the sense of
 * action_vocabulary_map.pl: nothing imports it, it renames nothing,
 * and its rows are authored and vetoable. It is a candidate structure,
 * not a rewrite. Where its steps meet the canonical alphabet of
 * action_vocabulary_map.pl, the correspondence is recorded in
 * kernel_canonical/2 comments-as-data rather than by inventing a rival
 * alphabet: the 122-action map, its register axis, and its stance axis
 * already carry most of what the earlier addition pilot re-derived.
 *
 * WHAT IT CORRECTS FROM THE ADDITION PILOT (per the Codex review):
 *   - Validity is grounded in EXECUTION, not authorship. Every run
 *     computes; correct means computed = ground truth, where ground
 *     truth is calculated independently of the kernel under test
 *     (check_execution_validity/0). No hand-copied validity table.
 *   - Negative and mutation tests constrain over-acceptance: the
 *     recognizer rejects every mutant as productive, and rejects a
 *     trace whose asserted result its own execution cannot vindicate
 *     (check_negative/0). Acceptance, task, and execution are composed.
 *   - Predictions are called CANDIDATES, and attestation is matched at
 *     the locus, not the operator (candidate_deformation/3).
 *
 * THE TWO GENRES OF ERROR (the load-bearing distinction).
 *
 *   KERNEL MUTATIONS act inside a gate: drop a part, pick the wrong
 *   output, miscount by one, evade a refusal by swapping operands.
 *   For the two tested mutations, commutation with change of gate is a
 *   structural property of this encoding: translate_run/3 changes only
 *   the gate slot, which those mutations do not inspect.
 *   check_commutation/0 verifies that the encoding retains this property;
 *   it is not an empirical finding about student errors.
 *
 *   GATE MUTATIONS break the sort discipline itself: conflating the
 *   count of units with the size of the unit (adding across
 *   denominators), or using a relational token as a sequencing move
 *   (5-3=2=3-5; "pokey dog is"). In this encoding the tested gate
 *   mutation has no whole-number preimage because its mutate_run/3
 *   clause requires a unit_fraction/1 gate. check_commutation/0 verifies
 *   that authored domain restriction. They are failures
 *   of the gate, and diagnosing them means naming the sort that was
 *   collapsed, not a step that was skipped.
 *
 * THE BRIDGE IS LICENSED, NOT ASSUMED. The map psi_b(x) = x parts of
 * 1/b carries the base-b radix cycle to the partitioned whole. The
 * quotient-group version (Z/bZ into Q/Z) discards exactly the named
 * boundary the doing is directed at and does not preserve order; the
 * interval form used here keeps order, partial addition below the
 * boundary, and complement to it. Even so, the identification of
 * radix cycle with partitioned whole is a bridge/3 fact that a run
 * must cite — following recursive_unit_actions.pl, which keeps
 * plan(regroup(7)) and plan(partition(7)) distinct terms, and
 * fraction_cgi_dispatch.pl, which keeps the operative radix and the
 * denominator as different parameters. check_radix_denominator/0
 * holds that distinction under execution.
 *
 * REFUSALS GENERATE REPAIRS. A gate's partiality is not only a
 * boundary of competence; it is where a family of deformations comes
 * from. When the whole-number gate refuses 3 - 5, the attested bug
 * smaller_from_larger is the mutation evade_refusal(swap_operands):
 * the student stays inside the gate by deforming the problem. The
 * pilot reproduces this mechanically (check_gate_partiality/0). This
 * is the impasse-repair structure made executable.
 *
 * LIMITS.
 *   - Seven kernels do not cover the strategy corpus, and are not
 *     claimed to. check_resisters/0 REPORTS what resists them (the
 *     fact-retrieval economy, anchor-and-compensate, the columnar
 *     shell) instead of forcing it. Resisters are the work list for
 *     candidate kernels, not failures of the probe.
 *   - Gates here are eight: whole_number(B), integer_line,
 *     unit_fraction(D) over a referent whole, ordered_rational_interval,
 *     positional_numerals(B), cardinality_in_base(B),
 *     rectangle_area_product(Area), and
 *     rectangle_even_perimeter(Perimeter). Measurement, decimal, and equation
 *     gates are future waves.
 *   - Pair enumeration is deliberately bounded. The area-product gate admits
 *     products through 10,000; the perimeter gate retains the source
 *     machine's 1..100 side limit. The area gate has boundary(none). The
 *     perimeter gate's half-perimeter is a numeric sum boundary, so K1 can
 *     compute one complementary side under that gate but cannot enumerate the
 *     complete pair list. As with the prior admissions, gate/2 also exposes
 *     these gates to generic K2 and K3 calls; no cross-kernel sort repair is
 *     made in this slice.
 *   - The three new gates are visible through gate/2 to K1-K3 even though
 *     those kernels' argument sorts do not match them. This widens the sort
 *     discipline: K1 fails at boundary(none) for ordered_rational_interval
 *     but can run against the numeric boundaries of the other new gates;
 *     K2 and K3 use generic gate checks. Gate-parameter range handling also
 *     differs: existing gate-parametric kernel calls can fail when a gate
 *     parameter is outside its range, while K5 and K6 return refused(...) for
 *     invalid bases, and K7 returns refused(unsupported_pair_gate(GateId)) for
 *     an unsupported gate. This limit is recorded, not repaired, in this
 *     slice.
 *   - attested_as/2 annotations point at corpus kind names by hand;
 *     they are claims to check against the live tables, not links.
 *   - The commutation check runs on the mutations and bridges defined
 *     here. "Kernel mutations commute with gates" is a falsifiable
 *     schema to test against the corpus's cross-domain bug pairs, not
 *     a theorem about all mutations.
 */

:- module(kernel_gate_pilot,
          [ gate/2,
            run_kernel/4,
            mutate_run/3,
            bridge/3,
            translate_run/3,
            recognize/3,
            candidate_deformation/3,
            check_kernel_pilot/0
          ]).

:- discontiguous run_kernel/4.

% ==========================================================================
% 1. GATES
%
% gate(GateId, Properties). The gate supplies what the kernel may not
% decide for itself: the sort of the objects, the named boundary and
% what it is (a radix cycle is not a partitioned whole), which partial
% operations are admissible, and how a result is read.
%
% The fraction gate carries BOTH an operative radix and a unit
% boundary, and they are independent parameters — sevenths written in
% base-ten numerals have boundary 7 and radix 10. This follows
% fraction_cgi_dispatch.pl: the make-base move listens to the radix;
% the complement-to-whole move listens to the boundary.
% ==========================================================================

gate(whole_number(B),
     props(sort(count(ones)),
           boundary(B), boundary_kind(radix_cycle(B)),
           operative_radix(B),
           lower_limit(0),
           subtraction(partial))) :-
    integer(B), B > 1.
gate(integer_line,
     props(sort(signed_count(ones)),
           boundary(none), boundary_kind(none),
           operative_radix(10),
           lower_limit(none),
           subtraction(total))).
gate(unit_fraction(D),
     props(sort(count(unit_fraction(D))),
           boundary(D), boundary_kind(partitioned_whole(D)),
           operative_radix(10),
           lower_limit(0),
           subtraction(partial))) :-
    integer(D), D > 1.
gate(ordered_rational_interval,
     props(sort(target_with_decidable_rational_order),
           boundary(none),
           boundary_kind(containing_interval),
           operative_radix(none),
           lower_limit(none),
           subtraction(none))).
gate(positional_numerals(B),
     props(sort(pair(canonical_nonnegative_positional_numerals(B))),
           boundary(B), boundary_kind(radix_cycle(B)),
           operative_radix(B),
           lower_limit(0),
           subtraction(none))) :-
    integer(B), B > 1.
gate(cardinality_in_base(B),
     props(sort(nonnegative_cardinality),
           boundary(B), boundary_kind(radix_cycle(B)),
           operative_radix(B),
           lower_limit(0),
           subtraction(none))) :-
    integer(B), B > 1.
gate(rectangle_area_product(Area),
     props(sort(pair(positive_integer_side_lengths)),
           boundary(none), boundary_kind(product_constraint(Area)),
           operative_radix(none),
           lower_limit(1),
           subtraction(none))) :-
    integer(Area),
    pair_enumeration_area_limit(Limit),
    between(1, Limit, Area).
gate(rectangle_even_perimeter(Perimeter),
     props(sort(pair(bounded_positive_integer_side_lengths(1, 100))),
           boundary(Half), boundary_kind(half_perimeter_sum(Half)),
           operative_radix(none),
           lower_limit(1),
           subtraction(none))) :-
    integer(Perimeter),
    between(4, 400, Perimeter),
    0 is Perimeter mod 2,
    Half is Perimeter // 2.

pair_enumeration_area_limit(10000).

gate_boundary(GateId, B) :- gate(GateId, props(_, boundary(B), _, _, _, _)).
gate_boundary_kind(GateId, K) :- gate(GateId, props(_, _, boundary_kind(K), _, _, _)).
gate_radix(GateId, R) :- gate(GateId, props(_, _, _, operative_radix(R), _, _)).
gate_subtraction(GateId, S) :- gate(GateId, props(_, _, _, _, _, subtraction(S))).

% ==========================================================================
% 2. KERNELS
%
% run_kernel(Kernel, Gate, Args, run(Kernel, Gate, Args, Steps, Result)).
%
% Steps are the trace; Result is computed, not narrated. A gate refusal
% is a first-class result: refused(Guard). Refusal is data because
% repairs are made from it.
%
% Correspondence with the canonical alphabet (action_vocabulary_map.pl),
% recorded as data so reconciliation is a query, not a rewrite:
kernel_canonical(measure_gap_to_boundary, assign_roles).
kernel_canonical(complete_to(_), regroup_to_base).
kernel_canonical(step_to(_), accumulate_total).
kernel_canonical(read_off(_), inscribe_result).
kernel_canonical(partition_into(_), decompose_operand).
kernel_canonical(regroup_into(_), regroup_to_base).

% --- K1: complete_to_unit -------------------------------------------------
% The doing behind "2 is 5 away from 7" and "2/7 is 5/7 away from the
% whole": measure the gap from a part to the named boundary. The kernel
% is the same; the gate says what the boundary IS.
run_kernel(complete_to_unit, GateId, [part(P)],
           run(complete_to_unit, GateId, [part(P)], Steps, Result)) :-
    gate_boundary(GateId, B), B \= none,
    (   integer(P), P >= 0, P =< B
    ->  C is B - P,
        gate_boundary_kind(GateId, Kind),
        Steps = [ locate(part(P), within(Kind)),
                  measure_gap_to_boundary,
                  complete_to(B),
                  read_off(complement(C))
                ],
        Result = complement(C)
    ;   Steps = [ locate(part(P), within(boundary(B))) ],
        Result = refused(part_exceeds_boundary_or_negative)
    ).

% --- K2: iterate_to_target ------------------------------------------------
% One control loop, four readings, all attested:
%   endpoint reading  -> addition by counting on
%   distance reading  -> subtraction by counting up
%     (corpus: subtraction/count_up_missing_addend)
%   downward run past the lower limit -> refused at the whole-number
%     gate, computed at the integer gate; same kernel, no new control.
% Output selection is a parameter, so the attested bug of reporting the
% endpoint as the difference (subtraction/answer_as_endpoint_count_up)
% is a mutation of the selection, not another machine.
run_kernel(iterate_to_target, GateId, [start(S), delta(D), direction(up), output(Sel)],
           run(iterate_to_target, GateId, [start(S), delta(D), direction(up), output(Sel)],
               Steps, Result)) :-
    gate(GateId, _),
    E is S + D,
    tick_steps(S, E, up, Ticks),
    select_output(Sel, S, E, D, Result),
    append([[assign_start(S)], Ticks, [read_off(Result)]], Steps).
run_kernel(iterate_to_target, GateId, [start(S), delta(D), direction(down), output(Sel)],
           run(iterate_to_target, GateId, [start(S), delta(D), direction(down), output(Sel)],
               Steps, Result)) :-
    gate(GateId, props(_, _, _, _, lower_limit(L), _)),
    E is S - D,
    (   ( L == none ; E >= L )
    ->  tick_steps(S, E, down, Ticks),
        select_output(Sel, S, E, D, Result),
        append([[assign_start(S)], Ticks, [read_off(Result)]], Steps)
    ;   Steps = [ assign_start(S), meet_lower_limit(L) ],
        Result = refused(crosses_lower_limit)
    ).

tick_steps(S, E, up, Ticks) :-
    S =< E,
    findall(step_to(X), ( between(S, E, X), X > S ), Ticks).
tick_steps(S, E, down, Ticks) :-
    E =< S,
    findall(step_to(X), ( between(E, S, X), X < S ), Asc),
    reverse(Asc, Ticks).

select_output(endpoint, _S, E, _D, endpoint(E)).
select_output(distance, _S, _E, D, distance(D)).

% --- K3: partition / regroup ----------------------------------------------
% The one-and-many coordination, directed. Following
% recursive_unit_actions.pl: plan(regroup(N)) and plan(partition(N))
% are distinct terms with distinct result units. N ones regrouped make
% one N-unit (outward); one unit partitioned makes N Nths (inward).
% The kernel composes with itself: partitioning a part is the nesting
% the fraction schemes carry (recursive_partition; jason_fsm's FCS).
run_kernel(partition_regroup, GateId, [unit(U), plan(regroup(N))],
           run(partition_regroup, GateId, [unit(U), plan(regroup(N))], Steps, Result)) :-
    gate(GateId, _), integer(N), N > 1,
    Steps = [ take_units(N, of(U)), regroup_into(composite(N, U)) ],
    Result = made(1, composite_unit(N, U)).
run_kernel(partition_regroup, GateId, [unit(U), plan(partition(N))],
           run(partition_regroup, GateId, [unit(U), plan(partition(N))], Steps, Result)) :-
    gate(GateId, _), integer(N), N > 1,
    Steps = [ take_units(1, of(U)), partition_into(N) ],
    Result = made(N, part_unit(N, U)).

% Nesting: partition the part. 1/7 of 1/7 is 1/49 of the referent.
nested_partition(GateId, N1, N2, Result) :-
    run_kernel(partition_regroup, GateId, [unit(whole), plan(partition(N1))],
               run(_, _, _, _, made(_, part_unit(N1, whole)))),
    run_kernel(partition_regroup, GateId, [unit(part_unit(N1, whole)), plan(partition(N2))],
               run(_, _, _, _, made(_, PU))),
    PU = part_unit(N2, part_unit(N1, whole)),
    Scale is N1 * N2,
    Result = referent_scale(Scale).

% --- K4: refine bracket by order -----------------------------------------
% Admitted from the failed nested-interval derivation recorded in
% .superpowers/sdd/task-2026-08-06-nested-interval-probe-report.md.
% That report's algebraic_root/1 is narrowed here to square_root/1, the only
% degree its comparison-by-squaring test decides.
% The existing-kernel composition for nested interval refinement forms a
% rational cut, then stalls because no kernel compares the target with the
% cut or selects the target-preserving subinterval.
run_kernel(refine_bracket_by_order, ordered_rational_interval,
           [target(Target), bracket(interval(Lower, Upper)), cut(Cut)],
           run(refine_bracket_by_order, ordered_rational_interval,
               [target(Target), bracket(interval(Lower, Upper)), cut(Cut)],
               Steps, Result)) :-
    (   \+ bracket_target(Target)
    ->  Steps = [refuse_before_iteration],
        Result = refused(malformed_target(Target))
    ;   \+ ordered_rational_bracket(Lower, Cut, Upper)
    ->  Steps = [refuse_before_iteration],
        Result = refused(malformed_bracket(interval(Lower, Upper), cut(Cut)))
    ;   \+ target_inside_bracket(Target, Lower, Upper)
    ->  Steps = [refuse_before_iteration],
        Result = refused(target_outside_bracket(Target,
                                                interval(Lower, Upper)))
    ;   target_cut_order(Target, Cut, Order),
        refine_order_result(Order, Lower, Cut, Upper, DecisionSteps, Result),
        append([ admit(target_inside(interval(Lower, Upper))),
                 compare_target_to_cut(Order)
               ], DecisionSteps, Steps)
    ).

refine_order_result(equal, _Lower, Cut, _Upper,
                    [witness(target_equals_cut), read_off(exact(Cut))],
                    exact(Cut)).
refine_order_result(below, Lower, Cut, _Upper,
                    [ select_target_preserving_interval(interval(Lower, Cut)),
                      read_off(next(interval(Lower, Cut), target_below_cut))
                    ],
                    next(interval(Lower, Cut), target_below_cut)).
refine_order_result(above, _Lower, Cut, Upper,
                    [ select_target_preserving_interval(interval(Cut, Upper)),
                      read_off(next(interval(Cut, Upper), target_above_cut))
                    ],
                    next(interval(Cut, Upper), target_above_cut)).

ordered_rational_bracket(Lower, Cut, Upper) :-
    rational_point(Lower),
    rational_point(Cut),
    rational_point(Upper),
    rational_order(below, Lower, Cut),
    rational_order(below, Cut, Upper).

bracket_target(rational(Point)) :-
    rational_point(Point).
bracket_target(square_root(Radicand)) :-
    integer(Radicand),
    Radicand > 0.

rational_point(q(Numerator, Denominator)) :-
    integer(Numerator),
    integer(Denominator),
    Denominator > 0.

rational_order(Order, q(LeftNumerator, LeftDenominator),
               q(RightNumerator, RightDenominator)) :-
    Left is LeftNumerator * RightDenominator,
    Right is RightNumerator * LeftDenominator,
    compare(Relation, Left, Right),
    comparison_order(Relation, Order).

target_cut_order(rational(Target), Cut, Order) :-
    rational_order(Order, Target, Cut).
target_cut_order(square_root(Radicand), q(Numerator, Denominator), Order) :-
    (   Numerator < 0
    ->  Order = above
    ;   TargetSquared is Radicand * Denominator * Denominator,
        CutSquared is Numerator * Numerator,
        compare(Relation, TargetSquared, CutSquared),
        comparison_order(Relation, Order)
    ).

comparison_order((<), below).
comparison_order((=), equal).
comparison_order((>), above).

target_inside_bracket(Target, Lower, Upper) :-
    target_cut_order(Target, Lower, LowerOrder),
    memberchk(LowerOrder, [equal, above]),
    target_cut_order(Target, Upper, UpperOrder),
    memberchk(UpperOrder, [equal, below]).

% --- K5: compare place sequences by significance ------------------------
% Admitted from the failed derivation of counting/place_value_comparison in
% .superpowers/sdd/task-2026-08-06-placevalue-kernel-probe-report.md.
% The existing composition recovers the extensional relation but supplies no
% highest-differing-place witness. In the adopted numeral/4 term,
% radix(Radix) is the digit count (recursive_unit_actions.pl:64-65); the
% gate's operative_radix(Base) is the inscription base.
run_kernel(compare_place_sequences_by_significance, positional_numerals(Base),
           [left(LeftNumeral), right(RightNumeral)],
           run(compare_place_sequences_by_significance,
               positional_numerals(Base),
               [left(LeftNumeral), right(RightNumeral)], Steps, Result)) :-
    (   \+ gate(positional_numerals(Base), _)
    ->  Steps = [refuse_before_comparison],
        Result = refused(base_below_two_or_noninteger(Base))
    ;   canonical_nonnegative_numeral(Base, LeftNumeral, LeftValues)
    ->  (   canonical_nonnegative_numeral(Base, RightNumeral, RightValues)
        ->  align_place_values(LeftValues, RightValues,
                               AlignedLeft, AlignedRight),
            length(AlignedLeft, Width),
            compare_place_values(AlignedLeft, AlignedRight, Width,
                                 Relation, Witness),
            Result = relation(Relation, Witness),
            Steps = [ align_places_by_unit(AlignedLeft, AlignedRight),
                      locate_highest_differing_place(Witness),
                      compare_digits_at_that_place,
                      read_off(Result)
                    ]
        ;   Steps = [refuse_before_comparison],
            Result = refused(malformed_right_positional_numeral(RightNumeral))
        )
    ;   Steps = [refuse_before_comparison],
        Result = refused(malformed_left_positional_numeral(LeftNumeral))
    ).

canonical_nonnegative_numeral(
        Base, numeral(Base, Sign, radix(Radix), Digits), Values) :-
    Digits = [_|_],
    maplist(canonical_digit(Base), Digits, Values),
    length(Digits, Radix),
    canonical_nonnegative_values(Sign, Values).

canonical_digit(Base, digit(Value, Glyph), Value) :-
    integer(Value),
    Value >= 0,
    Value < Base,
    string(Glyph),
    canonical_digit_glyph(Value, Glyph).

canonical_nonnegative_values(zero, [0]).
canonical_nonnegative_values(positive, [First|_]) :-
    First > 0.

align_place_values(Left, Right, AlignedLeft, AlignedRight) :-
    length(Left, LeftWidth),
    length(Right, RightWidth),
    Width is max(LeftWidth, RightWidth),
    pad_place_values(Left, Width, AlignedLeft),
    pad_place_values(Right, Width, AlignedRight).

pad_place_values(Values, Width, Padded) :-
    length(Values, ValueWidth),
    ZeroCount is Width - ValueWidth,
    length(Zeroes, ZeroCount),
    maplist(=(0), Zeroes),
    append(Zeroes, Values, Padded).

compare_place_values([], [], _Width, same_number,
                     no_differing_place(equal_digit_sequences)).
compare_place_values([Left|Lefts], [Right|Rights], Width,
                     Relation, Witness) :-
    Exponent is Width - 1,
    (   Left > Right
    ->  Relation = more,
        Witness = highest_differing_place(Exponent, digits(Left, Right))
    ;   Left < Right
    ->  Relation = fewer,
        Witness = highest_differing_place(Exponent, digits(Left, Right))
    ;   NextWidth is Width - 1,
        compare_place_values(Lefts, Rights, NextWidth, Relation, Witness)
    ).

% --- K6: recollect base cycles -------------------------------------------
% Admitted from the failed derivation of
% counting/recursive_place_value_inscription in
% .superpowers/sdd/task-2026-08-06-placevalue-kernel-probe-report.md.
% The existing composition retains the cardinality but cannot feed a quotient
% and remainder into the next place. In the adopted numeral/4 term,
% radix(Radix) is the digit count (recursive_unit_actions.pl:64-65); the
% gate's operative_radix(Base) is the inscription base.
run_kernel(recollect_base_cycles, cardinality_in_base(Base),
           [cardinality(Count)],
           run(recollect_base_cycles, cardinality_in_base(Base),
               [cardinality(Count)], Steps, Result)) :-
    (   \+ gate(cardinality_in_base(Base), _)
    ->  Steps = [refuse_before_recollection],
        Result = refused(base_below_two_or_noninteger(Base))
    ;   \+ (integer(Count), Count >= 0)
    ->  Steps = [refuse_before_recollection],
        Result = refused(negative_or_noninteger_cardinality(Count))
    ;   recollect_digit_values(Count, Base, Values, CycleSteps),
        maplist(inscribe_digit(Base), Values, Digits),
        length(Digits, Radix),
        cardinality_sign(Count, Sign),
        append(CycleSteps,
               [ reverse_retained_remainders,
                 read_off(numeral(Base, Sign, radix(Radix), Digits))
               ], Steps),
        Result = numeral(Base, Sign, radix(Radix), Digits)
    ).

recollect_digit_values(0, _Base, [0],
                       [retain_unit_place_zero]) :-
    !.
recollect_digit_values(Count, Base, Values, CycleSteps) :-
    recollect_least_significant(Count, Base, LeastFirst, CycleSteps),
    reverse(LeastFirst, Values).

recollect_least_significant(0, _Base, [], []) :-
    !.
recollect_least_significant(Current, Base, [Remainder|Remainders],
                            [ quotient_remainder_cycle(
                                  current(Current), quotient(Quotient),
                                  remainder(Remainder))
                            | CycleSteps ]) :-
    Quotient is Current // Base,
    Remainder is Current mod Base,
    recollect_least_significant(Quotient, Base, Remainders, CycleSteps).

inscribe_digit(Base, Value, digit(Value, Glyph)) :-
    Value >= 0,
    Value < Base,
    canonical_digit_glyph(Value, Glyph).

% Copied from knowledge/strategies/math/recursive_unit_actions.pl:389-399.
canonical_digit_glyph(Value, Glyph) :-
    Value =< 9,
    !,
    number_string(Value, Glyph).
canonical_digit_glyph(Value, Glyph) :-
    Value =< 35,
    !,
    Code is 0'A + Value - 10,
    string_codes(Glyph, [Code]).
canonical_digit_glyph(Value, Glyph) :-
    format(string(Glyph), "[~w]", [Value]).

cardinality_sign(0, zero) :-
    !.
cardinality_sign(_Count, positive).

% --- K7: enumerate positive integer pairs -------------------------------
% Admitted from both failed derivations in
% .superpowers/sdd/task-2026-08-07-five-deferral-probe-report.md:
% geometry/rectangle_factor_pair_search reaches an area endpoint but cannot
% return the product-constrained pair set, and
% geometry/rectangle_perimeter_side_pair_search reaches the half-perimeter
% endpoint but cannot return the sum-constrained pair set. The machines are
% not bridged in this slice.
run_kernel(enumerate_positive_integer_pairs, GateId, [],
           run(enumerate_positive_integer_pairs, GateId, [], Steps, Result)) :-
    (   pair_gate_refusal(GateId, Why)
    ->  Steps = [refuse_before_enumeration],
        Result = refused(Why)
    ;   pair_gate_plan(GateId, Upper, Admission, Constraint),
        enumerate_admitted_pairs(GateId, Upper, Pairs),
        Steps = [ Admission,
                  enumerate_positive_integer_pairs,
                  test_pair_constraint(Constraint),
                  canonicalize_commutative_pairs,
                  read_off(positive_integer_pairs(Pairs))
                ],
        Result = positive_integer_pairs(Pairs)
    ).

pair_gate_refusal(GateId, unbound_pair_gate) :-
    var(GateId),
    !.
pair_gate_refusal(rectangle_area_product(Area), Why) :-
    !,
    area_product_refusal(Area, Why).
pair_gate_refusal(rectangle_even_perimeter(Perimeter), Why) :-
    !,
    even_perimeter_refusal(Perimeter, Why).
pair_gate_refusal(GateId, unsupported_pair_gate(GateId)).

area_product_refusal(Area, unbound_area) :-
    var(Area),
    !.
area_product_refusal(Area, noninteger_area(Area)) :-
    \+ integer(Area),
    !.
area_product_refusal(Area, nonpositive_area(Area)) :-
    Area =< 0,
    !.
area_product_refusal(Area, area_exceeds_enumeration_limit(Area, Limit)) :-
    pair_enumeration_area_limit(Limit),
    Area > Limit.

even_perimeter_refusal(Perimeter, unbound_perimeter) :-
    var(Perimeter),
    !.
even_perimeter_refusal(Perimeter, noninteger_perimeter(Perimeter)) :-
    \+ integer(Perimeter),
    !.
even_perimeter_refusal(Perimeter, perimeter_below_minimum(Perimeter, 4)) :-
    Perimeter < 4,
    !.
even_perimeter_refusal(Perimeter, odd_perimeter(Perimeter)) :-
    1 is Perimeter mod 2,
    !.
even_perimeter_refusal(Perimeter,
                       perimeter_exceeds_bounded_side_limit(Perimeter, 400)) :-
    Perimeter > 400.

pair_gate_plan(rectangle_area_product(Area), Area,
               admit(positive_integer_area(Area)), product(Area)) :-
    gate(rectangle_area_product(Area), _).
pair_gate_plan(rectangle_even_perimeter(Perimeter), MaxLength,
               admit(even_perimeter_with_bounded_positive_side_pair(
                         Perimeter)),
               sum(Half)) :-
    gate_boundary(rectangle_even_perimeter(Perimeter), Half),
    MaxLength is Half - 1.

enumerate_admitted_pairs(GateId, Upper, Pairs) :-
    findall(Length-Width,
            ( between(1, Upper, Length),
              gate_pair_width(GateId, Length, Width),
              Length =< Width
            ),
            Pairs).

gate_pair_width(rectangle_area_product(Area), Length, Width) :-
    0 is Area mod Length,
    Width is Area // Length.
gate_pair_width(rectangle_even_perimeter(Perimeter), Length, Width) :-
    Half is Perimeter // 2,
    Width is Half - Length,
    between(1, 100, Length),
    between(1, 100, Width).

% ==========================================================================
% 3. MUTATIONS
%
% mutate_run(+Mutation, +Run, -MutantRun). Local, explicit, applied to a
% productive run. A deformation is a (Kernel, Gate, Mutation) triple,
% never a separate control automaton.
%
% Kernel mutations (commute with gates):
%   off_by_one(complement)     - complement missing the boundary by one
%   drop_part(leftover)        - complement computed, then discarded
%   select_output(endpoint)    - report the endpoint where the distance
%                                was asked (attested:
%                                subtraction/answer_as_endpoint_count_up)
%   evade_refusal(swap_operands) - defined ONLY on refused runs: stay
%                                inside the gate by deforming the
%                                problem (attested:
%                                subtraction/smaller_from_larger_in_column)
%
% Gate mutation (no image across the bridge):
%   conflate_count_with_unit_size - treat the boundary as one more
%                                countable part (attested:
%                                fraction/add_numerator_denominator_sum,
%                                fraction/whole_number_grab)
% ==========================================================================

mutate_run(off_by_one(complement),
           run(complete_to_unit, G, A, Steps0, complement(C)),
           run(complete_to_unit, G, A, Steps, complement(C1))) :-
    C1 is C + 1,
    append(Front, [read_off(complement(C))], Steps0),
    append(Front, [miscount_gap, read_off(complement(C1))], Steps).

mutate_run(drop_part(leftover),
           run(complete_to_unit, G, A, Steps0, complement(_)),
           run(complete_to_unit, G, A, Steps, dropped)) :-
    append(Front, [read_off(_)], Steps0),
    append(Front, [drop(complement)], Steps).

mutate_run(select_output(endpoint),
           run(iterate_to_target, G, Args0, Steps0, distance(_)),
           run(iterate_to_target, G, Args, Steps, endpoint(E))) :-
    select(output(distance), Args0, output(endpoint), Args),
    append(Front, [read_off(_)], Steps0),
    last(Front, step_to(E)),
    append(Front, [substitute_output(distance, endpoint), read_off(endpoint(E))], Steps).

mutate_run(evade_refusal(swap_operands),
           run(iterate_to_target, G, [start(S), delta(D), direction(down), output(Sel)],
               _, refused(crosses_lower_limit)),
           MutantRun) :-
    S2 is D, D2 is S,
    run_kernel(iterate_to_target, G,
               [start(S2), delta(D2), direction(down), output(Sel)], Run1),
    Run1 = run(K, G, A, Steps1, R),
    MutantRun = run(K, G, A, [swap_operands_to_stay_in_gate | Steps1], R).

mutate_run(conflate_count_with_unit_size,
           run(complete_to_unit, unit_fraction(D), [part(P)], _, complement(_)),
           run(complete_to_unit, gate_broken(unit_fraction(D)), [part(P)],
               [ collapse_sort(unit_count, unit_size) ],
               sum_across(NSum, DSum))) :-
    % D/D treated as one more addable pair: P/D + (D-P)/D "=" (P+(D-P))/(D+D).
    NSum is P + (D - P),
    DSum is D + D.

% ==========================================================================
% 4. BRIDGES AND TRANSLATION
%
% bridge(From, To, psi(Scale)): the licensed identification. psi carries
% a count of ones under radix cycle B to a count of unit fractions 1/B
% under the partitioned whole. It is a fact a translation must cite —
% never applied silently, because the radix cycle and the partitioned
% whole are different things that happen to be isomorphic as bounded
% complement structures.
% ==========================================================================

bridge(whole_number(B), unit_fraction(B), psi(scale(B))).

translate_run(bridge(F, T, _),
              run(K, F, Args, Steps, Result),
              run(K, T, Args, Steps, Result)) :-
    bridge(F, T, _).
% Results and args carry counts of units; the bridge re-sorts the unit,
% so the count terms translate unchanged. What changes is what they
% count — recorded by the gate slot, which is the point.

% ==========================================================================
% 5. RECOGNITION, COMPOSED WITH THE TASK AND WITH EXECUTION
%
% recognize(+Task, +Run, -Reading). A run is read against what was
% ASKED, not only against its own coherence. This is the fix for the
% addition pilot's over-acceptance: the endpoint-as-difference mutant
% is a perfectly coherent endpoint run, and its deformity exists only
% relative to the subtraction task. Acceptance, execution, and task are
% composed:
%
%   productive    - unmutated trace, computed result answers the task.
%   deformed(M)   - the trace carries an explicit mutation marker M.
%   refusal(W)    - the gate refused; nothing was asserted.
%   unvindicated  - an unmutated trace whose asserted result does not
%                   answer the task: the run completes (commitment
%                   undertaken) and cannot be vindicated. Tampered
%                   verdicts land here instead of being accepted.
% ==========================================================================

recognize(Task, run(K, G, A, Steps, Result), productive) :-
    \+ mutant_marker(Steps),
    Result \= refused(_),
    task_answered(Task, K, G, A, Result).
recognize(_Task, run(_, _, _, Steps, _), deformed(Marker)) :-
    mutant_marker_name(Steps, Marker).
recognize(_Task, run(_, _, _, _, refused(Why)), refusal(Why)).
recognize(Task, run(K, G, A, Steps, Result), unvindicated) :-
    \+ mutant_marker(Steps),
    Result \= refused(_),
    \+ task_answered(Task, K, G, A, Result).

mutant_marker(Steps) :- mutant_marker_name(Steps, _).
mutant_marker_name(Steps, miscount_gap) :- memberchk(miscount_gap, Steps).
mutant_marker_name(Steps, drop(complement)) :- memberchk(drop(complement), Steps).
mutant_marker_name(Steps, swap_operands) :- memberchk(swap_operands_to_stay_in_gate, Steps).
mutant_marker_name(Steps, substitute_output) :- memberchk(substitute_output(_, _), Steps).
mutant_marker_name(Steps, collapse_sort) :- memberchk(collapse_sort(_, _), Steps).

% Ground truth: what answers the task, computed by plain arithmetic,
% independently of any kernel. A difference task is answered by the
% distance of an upward run or the endpoint of a downward run; an
% endpoint of an upward run answers a sum, never a difference.
task_answered(asked(complement_within(GateId, P)), complete_to_unit, _, _, complement(C)) :-
    gate_boundary(GateId, B), B \= none,
    C =:= B - P.
task_answered(asked(sum(A, B)), iterate_to_target, _, Args, endpoint(E)) :-
    memberchk(direction(up), Args),
    E =:= A + B.
task_answered(asked(difference(M, S)), iterate_to_target, _, Args, distance(D)) :-
    memberchk(direction(up), Args),
    D =:= M - S.
task_answered(asked(difference(M, S)), iterate_to_target, _, Args, endpoint(E)) :-
    memberchk(direction(down), Args),
    E =:= M - S.
task_answered(asked(partition(N)), partition_regroup, _, _, made(N, part_unit(N, _))).
task_answered(asked(regroup(N)), partition_regroup, _, _, made(1, composite_unit(N, _))).
task_answered(
    asked(refine_bracket_by_order(Target, interval(Lower, Upper), Cut)),
    refine_bracket_by_order, ordered_rational_interval,
    [target(Target), bracket(interval(Lower, Upper)), cut(Cut)],
    ClaimedResult) :-
    oracle_refinement_answer(Target, Lower, Cut, Upper, ClaimedResult).
task_answered(
    asked(compare_place_sequences_by_significance(LeftNumeral, RightNumeral)),
    compare_place_sequences_by_significance, positional_numerals(Base),
    [left(LeftNumeral), right(RightNumeral)], relation(Relation, Witness)) :-
    gate(positional_numerals(Base), _),
    numeral_cardinality(Base, LeftNumeral, LeftCount),
    numeral_cardinality(Base, RightNumeral, RightCount),
    oracle_integer_relation(LeftCount, RightCount, Relation),
    oracle_place_witness(Relation, LeftNumeral, RightNumeral, Witness).
task_answered(asked(recollect_base_cycles(Count, Base)),
              recollect_base_cycles, cardinality_in_base(Base),
              [cardinality(Count)], Numeral) :-
    gate(cardinality_in_base(Base), _),
    integer(Count),
    Count >= 0,
    numeral_cardinality(Base, Numeral, Count).
task_answered(asked(enumerate_positive_integer_pairs(GateId)),
              enumerate_positive_integer_pairs, GateId, [],
              positive_integer_pairs(Pairs)) :-
    oracle_positive_integer_pairs(GateId, Pairs).

% Ground truth for recollection reads the produced numeral back by place
% value; it does not reuse the quotient/remainder loop under test.
numeral_cardinality(Base, Numeral, Count) :-
    canonical_nonnegative_numeral(Base, Numeral, Values),
    place_values_cardinality(Values, Base, 0, Count).

place_values_cardinality([], _Base, Count, Count).
place_values_cardinality([Digit|Digits], Base, Acc0, Count) :-
    Acc1 is Acc0 * Base + Digit,
    place_values_cardinality(Digits, Base, Acc1, Count).

% Independent K7 oracle. It checks the claimed list's members and order by
% direct arithmetic, then counts every satisfying canonical pair without
% calling gate/2, pair_gate_plan/4, enumerate_admitted_pairs/3, or
% gate_pair_width/3 from the kernel under test. The count comprehension shares
% the gate-supplied scan bound with the kernel; its membership arithmetic is
% independent, as the K6 oracle shares a base while reading place value back.
oracle_positive_integer_pairs(rectangle_area_product(Area), Pairs) :-
    integer(Area),
    pair_enumeration_area_limit(Limit),
    between(1, Limit, Area),
    is_list(Pairs),
    Pairs = [_|_],
    oracle_strictly_increasing_pair_lengths(Pairs),
    maplist(oracle_area_pair(Area), Pairs),
    aggregate_all(count,
                  ( between(1, Area, Length),
                    0 is Area mod Length,
                    Width is Area // Length,
                    Length =< Width
                  ),
                  ExpectedCount),
    length(Pairs, ExpectedCount).
oracle_positive_integer_pairs(rectangle_even_perimeter(Perimeter), Pairs) :-
    integer(Perimeter),
    between(4, 400, Perimeter),
    0 is Perimeter mod 2,
    Half is Perimeter // 2,
    is_list(Pairs),
    Pairs = [_|_],
    oracle_strictly_increasing_pair_lengths(Pairs),
    maplist(oracle_perimeter_pair(Half), Pairs),
    MaxLength is Half - 1,
    aggregate_all(count,
                  ( between(1, MaxLength, Length),
                    Width is Half - Length,
                    Length =< Width,
                    between(1, 100, Length),
                    between(1, 100, Width)
                  ),
                  ExpectedCount),
    length(Pairs, ExpectedCount).

oracle_area_pair(Area, Length-Width) :-
    integer(Length),
    integer(Width),
    Length > 0,
    Length =< Width,
    Length * Width =:= Area.

oracle_perimeter_pair(Half, Length-Width) :-
    integer(Length),
    integer(Width),
    between(1, 100, Length),
    between(1, 100, Width),
    Length =< Width,
    Length + Width =:= Half.

oracle_strictly_increasing_pair_lengths([]).
oracle_strictly_increasing_pair_lengths([_]).
oracle_strictly_increasing_pair_lengths(
        [LeftLength-_LeftWidth, RightLength-RightWidth | Pairs]) :-
    integer(LeftLength),
    integer(RightLength),
    LeftLength < RightLength,
    oracle_strictly_increasing_pair_lengths(
        [RightLength-RightWidth | Pairs]).

% Independent K4 oracle. It duplicates the admitted arithmetic instead of
% calling rational_order/3, target_cut_order/3, target_inside_bracket/3, or
% refine_order_result/6 from the kernel under test.
oracle_refinement_answer(Target,
                         q(LowerNumerator, LowerDenominator),
                         q(CutNumerator, CutDenominator),
                         q(UpperNumerator, UpperDenominator),
                         ClaimedResult) :-
    maplist(integer,
            [ LowerNumerator, LowerDenominator,
              CutNumerator, CutDenominator,
              UpperNumerator, UpperDenominator
            ]),
    LowerDenominator > 0,
    CutDenominator > 0,
    UpperDenominator > 0,
    LowerNumerator * CutDenominator < CutNumerator * LowerDenominator,
    CutNumerator * UpperDenominator < UpperNumerator * CutDenominator,
    oracle_target_rational_order(
        Target, q(LowerNumerator, LowerDenominator), LowerOrder),
    memberchk(LowerOrder, [equal, above]),
    oracle_target_rational_order(
        Target, q(UpperNumerator, UpperDenominator), UpperOrder),
    memberchk(UpperOrder, [equal, below]),
    oracle_target_rational_order(
        Target, q(CutNumerator, CutDenominator), CutOrder),
    oracle_refinement_claim(
        CutOrder,
        q(LowerNumerator, LowerDenominator),
        q(CutNumerator, CutDenominator),
        q(UpperNumerator, UpperDenominator),
        ClaimedResult).

oracle_target_rational_order(rational(q(TargetNumerator, TargetDenominator)),
                             q(PointNumerator, PointDenominator), Order) :-
    integer(TargetNumerator),
    integer(TargetDenominator),
    TargetDenominator > 0,
    Left is TargetNumerator * PointDenominator,
    Right is PointNumerator * TargetDenominator,
    compare(Comparison, Left, Right),
    oracle_comparison_order(Comparison, Order).
oracle_target_rational_order(square_root(Radicand),
                             q(PointNumerator, PointDenominator), Order) :-
    integer(Radicand),
    Radicand > 0,
    (   PointNumerator < 0
    ->  Order = above
    ;   RootSquared is Radicand * PointDenominator * PointDenominator,
        PointSquared is PointNumerator * PointNumerator,
        compare(Comparison, RootSquared, PointSquared),
        oracle_comparison_order(Comparison, Order)
    ).

oracle_comparison_order((<), below).
oracle_comparison_order((=), equal).
oracle_comparison_order((>), above).

oracle_refinement_claim(equal, _Lower, Cut, _Upper, exact(Cut)).
oracle_refinement_claim(below, Lower, Cut, _Upper,
                        next(interval(Lower, Cut), target_below_cut)).
oracle_refinement_claim(above, _Lower, Cut, Upper,
                        next(interval(Cut, Upper), target_above_cut)).

% Independent K5 oracle. Cardinality order comes from Horner read-back. The
% claimed place witness is checked by direct indexing into the digit lists,
% with virtual leading zeroes supplied only for indices before a shorter list.
oracle_integer_relation(Left, Right, Relation) :-
    compare(Comparison, Left, Right),
    oracle_count_relation(Comparison, Relation).

oracle_count_relation((<), fewer).
oracle_count_relation((=), same_number).
oracle_count_relation((>), more).

oracle_place_witness(
    same_number, LeftNumeral, RightNumeral,
    no_differing_place(equal_digit_sequences)) :-
    oracle_numeral_digits(LeftNumeral, LeftDigits),
    oracle_numeral_digits(RightNumeral, RightDigits),
    oracle_aligned_width(LeftDigits, RightDigits, Width),
    oracle_equal_places(0, Width, LeftDigits, RightDigits, Width).
oracle_place_witness(
    Relation, LeftNumeral, RightNumeral,
    highest_differing_place(Exponent, digits(ClaimedLeft, ClaimedRight))) :-
    memberchk(Relation, [fewer, more]),
    oracle_numeral_digits(LeftNumeral, LeftDigits),
    oracle_numeral_digits(RightNumeral, RightDigits),
    oracle_aligned_width(LeftDigits, RightDigits, Width),
    integer(Exponent),
    Exponent >= 0,
    Exponent < Width,
    Position is Width - Exponent - 1,
    oracle_equal_places(0, Position, LeftDigits, RightDigits, Width),
    oracle_aligned_digit(LeftDigits, Width, Position, LeftDigit),
    oracle_aligned_digit(RightDigits, Width, Position, RightDigit),
    integer(ClaimedLeft),
    integer(ClaimedRight),
    ClaimedLeft =:= LeftDigit,
    ClaimedRight =:= RightDigit,
    compare(DigitComparison, LeftDigit, RightDigit),
    oracle_count_relation(DigitComparison, Relation).

oracle_numeral_digits(numeral(_Base, _Sign, radix(_Radix), Digits), Digits).

oracle_aligned_width(LeftDigits, RightDigits, Width) :-
    length(LeftDigits, LeftWidth),
    length(RightDigits, RightWidth),
    Width is max(LeftWidth, RightWidth).

oracle_aligned_digit(Digits, Width, Position, Value) :-
    length(Digits, DigitWidth),
    Padding is Width - DigitWidth,
    (   Position < Padding
    ->  Value = 0
    ;   DigitIndex is Position - Padding,
        nth0(DigitIndex, Digits, digit(Value, _Glyph))
    ).

oracle_equal_places(Position, Limit, _LeftDigits, _RightDigits, _Width) :-
    Position >= Limit,
    !.
oracle_equal_places(Position, Limit, LeftDigits, RightDigits, Width) :-
    oracle_aligned_digit(LeftDigits, Width, Position, LeftValue),
    oracle_aligned_digit(RightDigits, Width, Position, RightValue),
    LeftValue =:= RightValue,
    NextPosition is Position + 1,
    oracle_equal_places(NextPosition, Limit,
                        LeftDigits, RightDigits, Width).

% ==========================================================================
% 6. CANDIDATE DEFORMATIONS (not "predictions")
%
% A candidate is a (Kernel, Gate, Mutation) triple whose mutation is
% defined at that kernel and gate and which no attested_as/2 annotation
% covers AT THAT TRIPLE — locus-exact matching, correcting the addition
% pilot's operator-level matching. Candidates are hypotheses for the
% recognizer to watch for, pending validation against student data.
% ==========================================================================

attested_as(deformed(complete_to_unit, whole_number(10), drop_part(leftover)),
            addition/make_ten_drop_leftover).
attested_as(deformed(iterate_to_target, whole_number(10), select_output(endpoint)),
            subtraction/answer_as_endpoint_count_up).
attested_as(deformed(iterate_to_target, whole_number(10), evade_refusal(swap_operands)),
            subtraction/smaller_from_larger_in_column).
attested_as(deformed(complete_to_unit, unit_fraction(_), conflate_count_with_unit_size),
            fraction/add_numerator_denominator_sum).

mutation_defined_at(off_by_one(complement), complete_to_unit, _AnyGate).
mutation_defined_at(drop_part(leftover), complete_to_unit, _AnyGate).
mutation_defined_at(select_output(endpoint), iterate_to_target, _AnyGate).
mutation_defined_at(evade_refusal(swap_operands), iterate_to_target, G) :-
    gate_subtraction(G, partial).
mutation_defined_at(conflate_count_with_unit_size, complete_to_unit, unit_fraction(_)).

% The gate universe for enumeration. Parametric gates are enumerated at
% the corpus's operative instances; widening this list widens the
% candidate space and nothing else.
demo_gate(whole_number(10)).
demo_gate(unit_fraction(7)).
demo_gate(integer_line).

candidate_deformation(Kernel, GateId, Mutation) :-
    demo_gate(GateId),
    mutation_defined_at(Mutation, Kernel, GateId),
    \+ attested_as(deformed(Kernel, GateId, Mutation), _).

% ==========================================================================
% 7. CHECKS
% ==========================================================================

% One kernel, two gates: base-seven complement and sevenths complement,
% same trace skeleton, boundary kinds distinct, bridge cited to relate
% them. The gate difference is in the trace (radix_cycle(7) vs
% partitioned_whole(7)); everything else is shared.
check_shared_kernel :-
    run_kernel(complete_to_unit, whole_number(7), [part(2)], R1),
    R1 = run(_, _, _, S1, complement(5)),
    run_kernel(complete_to_unit, unit_fraction(7), [part(2)], R2),
    R2 = run(_, _, _, S2, complement(5)),
    memberchk(locate(_, within(radix_cycle(7))), S1),
    memberchk(locate(_, within(partitioned_whole(7))), S2),
    skeleton(S1, K), skeleton(S2, K),
    bridge(whole_number(7), unit_fraction(7), _),
    translate_run(bridge(whole_number(7), unit_fraction(7), _), R1, R1T),
    R1T = run(complete_to_unit, unit_fraction(7), [part(2)], _, complement(5)).

skeleton([], []).
skeleton([locate(_, _)|T], [locate|K]) :- !, skeleton(T, K).
skeleton([H|T], [F|K]) :- functor(H, F, _), skeleton(T, K).

% Radix and denominator stay distinct parameters: the sevenths gate
% carries operative radix 10 and boundary 7, and changing the
% denominator does not touch the radix. This is the
% fraction_cgi_dispatch distinction, held here as a check.
check_radix_denominator :-
    gate_radix(unit_fraction(7), 10),
    gate_boundary(unit_fraction(7), 7),
    gate_radix(unit_fraction(5), 10),
    gate_boundary(unit_fraction(5), 5),
    gate_radix(whole_number(7), 7),
    gate_boundary(whole_number(7), 7).

% The whole-number gate refuses 3 - 5; the integer gate computes it
% with the same kernel; and the refusal, repaired by swapping operands,
% yields exactly the attested smaller-from-larger answer.
check_gate_partiality :-
    run_kernel(iterate_to_target, whole_number(10),
               [start(3), delta(5), direction(down), output(endpoint)], RW),
    RW = run(_, _, _, _, refused(crosses_lower_limit)),
    run_kernel(iterate_to_target, integer_line,
               [start(3), delta(5), direction(down), output(endpoint)], RZ),
    RZ = run(_, _, _, _, endpoint(-2)),
    mutate_run(evade_refusal(swap_operands), RW, RM),
    RM = run(_, _, _, _, endpoint(2)),
    recognize(asked(difference(3, 5)), RM, deformed(swap_operands)),
    \+ recognize(asked(difference(3, 5)), RM, productive).

% One run of the loop, two readings: counting up 3 -> 8 reports
% distance 5 for subtraction; the endpoint mutation reports 8 and is
% recognized as deformed, not as another machine.
check_output_selection :-
    Task = asked(difference(8, 3)),
    run_kernel(iterate_to_target, whole_number(10),
               [start(3), delta(5), direction(up), output(distance)], R),
    R = run(_, _, _, _, distance(5)),
    recognize(Task, R, productive),
    mutate_run(select_output(endpoint), R, M),
    M = run(_, _, _, _, endpoint(8)),
    recognize(Task, M, deformed(substitute_output)),
    \+ recognize(Task, M, productive).

% Direction survives: regroup(7) and partition(7) coordinate the same
% seven-to-one and produce different units; no identity without a
% bridge; and partition composes with itself (1/7 of 1/7 = 1/49 scale).
check_partition_direction :-
    run_kernel(partition_regroup, whole_number(10), [unit(one), plan(regroup(7))], RO),
    RO = run(_, _, _, _, made(1, composite_unit(7, one))),
    run_kernel(partition_regroup, unit_fraction(7), [unit(whole), plan(partition(7))], RI),
    RI = run(_, _, _, _, made(7, part_unit(7, whole))),
    RO \= RI,
    nested_partition(unit_fraction(7), 7, 7, referent_scale(49)).

% Validity from execution alone: productive runs match ground truth,
% every kernel mutant misses it exactly when the mutation touches the
% answer, and the recognizer classification follows from that — no
% authored validity table anywhere in this file.
check_execution_validity :-
    forall(demo_productive(Task, R), recognize(Task, R, productive)),
    forall(demo_mutant(Task, M, _),
           ( mutant_answer_differs(Task, M),
             \+ recognize(Task, M, productive) )).

% A demo mutant earns its negative-example role only when its executed
% result fails the task's independently computed arithmetic relation.
mutant_answer_differs(Task, run(K, G, A, _, Result)) :-
    Result \= refused(_),
    \+ task_answered(Task, K, G, A, Result).

demo_productive(Task, R) :-
    member(Task-(K-G-A),
           [ asked(complement_within(whole_number(7), 2))-(complete_to_unit-whole_number(7)-[part(2)]),
             asked(complement_within(unit_fraction(7), 2))-(complete_to_unit-unit_fraction(7)-[part(2)]),
             asked(sum(5, 3))-(iterate_to_target-whole_number(10)-[start(5), delta(3), direction(up), output(endpoint)]),
             asked(difference(8, 3))-(iterate_to_target-whole_number(10)-[start(3), delta(5), direction(up), output(distance)]),
             asked(partition(7))-(partition_regroup-unit_fraction(7)-[unit(whole), plan(partition(7))]),
             asked(refine_bracket_by_order(rational(q(1, 3)),
                                           interval(q(0, 1), q(1, 1)),
                                           q(1, 2)))-
                 (refine_bracket_by_order-ordered_rational_interval-
                  [ target(rational(q(1, 3))),
                    bracket(interval(q(0, 1), q(1, 1))),
                    cut(q(1, 2))
                  ]),
             asked(compare_place_sequences_by_significance(
                       numeral(10, positive, radix(2),
                               [digit(5, "5"), digit(6, "6")]),
                       numeral(10, positive, radix(2),
                               [digit(2, "2"), digit(6, "6")])))-
                 (compare_place_sequences_by_significance-positional_numerals(10)-
                  [ left(numeral(10, positive, radix(2),
                                 [digit(5, "5"), digit(6, "6")])),
                    right(numeral(10, positive, radix(2),
                                  [digit(2, "2"), digit(6, "6")]))
                  ]),
             asked(recollect_base_cycles(347, 10))-
                 (recollect_base_cycles-cardinality_in_base(10)-
                  [cardinality(347)]),
             asked(enumerate_positive_integer_pairs(
                       rectangle_area_product(24)))-
                 (enumerate_positive_integer_pairs-
                  rectangle_area_product(24)-[]),
             asked(enumerate_positive_integer_pairs(
                       rectangle_even_perimeter(22)))-
                 (enumerate_positive_integer_pairs-
                  rectangle_even_perimeter(22)-[])
           ]),
    run_kernel(K, G, A, R).

% The admissions participate in the same task/execution recognition as K1-K3.
% Correct runs are productive; result tampering is unvindicated.
check_admitted_kernel_validity :-
    NewTasks =
        [ asked(refine_bracket_by_order(rational(q(1, 3)),
                                        interval(q(0, 1), q(1, 1)),
                                        q(1, 2))),
          asked(compare_place_sequences_by_significance(
                    numeral(10, positive, radix(2),
                            [digit(5, "5"), digit(6, "6")]),
                    numeral(10, positive, radix(2),
                            [digit(2, "2"), digit(6, "6")]))),
          asked(recollect_base_cycles(347, 10)),
          asked(enumerate_positive_integer_pairs(
                    rectangle_area_product(24))),
          asked(enumerate_positive_integer_pairs(
                    rectangle_even_perimeter(22)))
        ],
    forall(member(Task, NewTasks),
           ( demo_productive(Task, Run),
             recognize(Task, Run, productive),
             \+ recognize(Task, Run, unvindicated) )),
    NewTasks = [ RefineTask, CompareTask, RecollectTask,
                 AreaPairTask, PerimeterPairTask
               ],
    demo_productive(RefineTask, run(K4, G4, A4, S4, _)),
    WrongRefine = run(K4, G4, A4, S4, exact(q(1, 2))),
    recognize(RefineTask, WrongRefine, unvindicated),
    \+ recognize(RefineTask, WrongRefine, productive),
    demo_productive(CompareTask, run(K5, G5, A5, S5, _)),
    WrongCompare = run(K5, G5, A5, S5,
                       relation(more,
                                highest_differing_place(0, digits(5, 2)))),
    recognize(CompareTask, WrongCompare, unvindicated),
    \+ recognize(CompareTask, WrongCompare, productive),
    demo_productive(RecollectTask, run(K6, G6, A6, S6, _)),
    WrongRecollect = run(
        K6, G6, A6, S6,
        numeral(10, positive, radix(3),
                [digit(3, "3"), digit(4, "4"), digit(6, "6")])),
    recognize(RecollectTask, WrongRecollect, unvindicated),
    \+ recognize(RecollectTask, WrongRecollect, productive),
    demo_productive(AreaPairTask, run(K7A, G7A, A7A, S7A, _)),
    WrongAreaPairs = run(
        K7A, G7A, A7A, S7A,
        positive_integer_pairs([1-24, 2-12, 3-8])),
    recognize(AreaPairTask, WrongAreaPairs, unvindicated),
    \+ recognize(AreaPairTask, WrongAreaPairs, productive),
    demo_productive(PerimeterPairTask, run(K7P, G7P, A7P, S7P, _)),
    WrongPerimeterPairs = run(
        K7P, G7P, A7P, S7P,
        positive_integer_pairs([1-10, 2-9, 3-8, 4-7, 5-5])),
    recognize(PerimeterPairTask, WrongPerimeterPairs, unvindicated),
    \+ recognize(PerimeterPairTask, WrongPerimeterPairs, productive).

% The pair lists retain the prototype outputs. Gate-specific readings are
% parameters of one shared trace skeleton, and the asserted list is wrapped in
% a compound result for recognition.
check_pair_enumeration_admission :-
    run_kernel(enumerate_positive_integer_pairs,
               rectangle_area_product(24), [], AreaRun),
    AreaRun = run(
        enumerate_positive_integer_pairs, rectangle_area_product(24), [],
        [ admit(positive_integer_area(24)),
          enumerate_positive_integer_pairs,
          test_pair_constraint(product(24)),
          canonicalize_commutative_pairs,
          read_off(positive_integer_pairs([1-24, 2-12, 3-8, 4-6]))
        ],
        positive_integer_pairs([1-24, 2-12, 3-8, 4-6])),
    run_kernel(enumerate_positive_integer_pairs,
               rectangle_even_perimeter(22), [], PerimeterRun),
    PerimeterRun = run(
        enumerate_positive_integer_pairs, rectangle_even_perimeter(22), [],
        [ admit(even_perimeter_with_bounded_positive_side_pair(22)),
          enumerate_positive_integer_pairs,
          test_pair_constraint(sum(11)),
          canonicalize_commutative_pairs,
          read_off(positive_integer_pairs(
                       [1-10, 2-9, 3-8, 4-7, 5-6]))
        ],
        positive_integer_pairs([1-10, 2-9, 3-8, 4-7, 5-6])),
    AreaRun = run(_, _, _, AreaSteps, _),
    PerimeterRun = run(_, _, _, PerimeterSteps, _),
    skeleton(AreaSteps, PairSkeleton),
    skeleton(PerimeterSteps, PairSkeleton),
    gate_boundary(rectangle_area_product(24), none),
    gate_boundary(rectangle_even_perimeter(22), 11).

% The reviewed cross-kernel and malformed-glyph calls fail or refuse as data;
% neither reaches an arithmetic or string conversion exception.
check_admission_refusals :-
    \+ run_kernel(complete_to_unit, ordered_rational_interval,
                  [part(2)], _),
    findall(Gate-Run,
            run_kernel(complete_to_unit, Gate, [part(2)], Run),
            GateRuns),
    GateRuns == [],
    Left = numeral(10, positive, radix(2),
                   [digit(5, '5'), digit(6, "6")]),
    Right = numeral(10, positive, radix(2),
                    [digit(2, "2"), digit(6, "6")]),
    run_kernel(compare_place_sequences_by_significance,
               positional_numerals(10), [left(Left), right(Right)],
               run(_, _, _, [refuse_before_comparison],
                   refused(malformed_left_positional_numeral(Left)))),
    run_kernel(enumerate_positive_integer_pairs, UnboundGate, [],
               run(_, UnboundGate, _, [refuse_before_enumeration],
                   refused(unbound_pair_gate))),
    var(UnboundGate),
    run_kernel(enumerate_positive_integer_pairs,
               rectangle_area_product(UnboundArea), [],
               run(_, _, _, [refuse_before_enumeration],
                   refused(unbound_area))),
    var(UnboundArea),
    run_kernel(enumerate_positive_integer_pairs,
               rectangle_area_product(-1), [],
               run(_, _, _, [refuse_before_enumeration],
                   refused(nonpositive_area(-1)))),
    run_kernel(enumerate_positive_integer_pairs,
               rectangle_area_product(0), [],
               run(_, _, _, [refuse_before_enumeration],
                   refused(nonpositive_area(0)))),
    run_kernel(enumerate_positive_integer_pairs,
               rectangle_area_product(2.5), [],
               run(_, _, _, [refuse_before_enumeration],
                   refused(noninteger_area(2.5)))),
    pair_enumeration_area_limit(AreaLimit),
    HugeArea is AreaLimit + 1,
    run_kernel(enumerate_positive_integer_pairs,
               rectangle_area_product(HugeArea), [],
               run(_, _, _, [refuse_before_enumeration],
                   refused(area_exceeds_enumeration_limit(
                               HugeArea, AreaLimit)))),
    run_kernel(enumerate_positive_integer_pairs,
               rectangle_even_perimeter(UnboundPerimeter), [],
               run(_, _, _, [refuse_before_enumeration],
                   refused(unbound_perimeter))),
    var(UnboundPerimeter),
    run_kernel(enumerate_positive_integer_pairs,
               rectangle_even_perimeter(5), [],
               run(_, _, _, [refuse_before_enumeration],
                   refused(odd_perimeter(5)))),
    run_kernel(enumerate_positive_integer_pairs,
               rectangle_even_perimeter(402), [],
               run(_, _, _, [refuse_before_enumeration],
                   refused(perimeter_exceeds_bounded_side_limit(402, 400)))).

% K6 output is the canonical K5 input. The full 0..40 pair grid covers zero,
% exact base cycles for every listed base, multiple places in the smaller
% bases, and bracketed digit glyphs above base 36.
check_recollect_compare_composition :-
    Bases = [2, 10, 16, 36, 40],
    forall(( member(Base, Bases),
             between(0, 40, LeftCount),
             between(0, 40, RightCount) ),
           ( run_kernel(recollect_base_cycles, cardinality_in_base(Base),
                        [cardinality(LeftCount)], LeftRun),
             LeftRun = run(_, _, _, _, LeftNumeral),
             run_kernel(recollect_base_cycles, cardinality_in_base(Base),
                        [cardinality(RightCount)], RightRun),
             RightRun = run(_, _, _, _, RightNumeral),
             run_kernel(compare_place_sequences_by_significance,
                        positional_numerals(Base),
                        [left(LeftNumeral), right(RightNumeral)], CompareRun),
             CompareRun = run(_, _, _, _, relation(Relation, _Witness)),
             oracle_integer_relation(LeftCount, RightCount, Relation),
             CompareTask = asked(compare_place_sequences_by_significance(
                                     LeftNumeral, RightNumeral)),
             recognize(CompareTask, CompareRun, productive),
             \+ recognize(CompareTask, CompareRun, unvindicated) )).

demo_mutant(asked(complement_within(whole_number(7), 2)), M, Mu) :-
    run_kernel(complete_to_unit, whole_number(7), [part(2)], R1),
    member(Mu, [off_by_one(complement), drop_part(leftover)]),
    mutate_run(Mu, R1, M).
demo_mutant(asked(difference(8, 3)), M, select_output(endpoint)) :-
    run_kernel(iterate_to_target, whole_number(10),
               [start(3), delta(5), direction(up), output(distance)], R),
    mutate_run(select_output(endpoint), R, M).
demo_mutant(asked(complement_within(unit_fraction(7), 2)), M, conflate_count_with_unit_size) :-
    run_kernel(complete_to_unit, unit_fraction(7), [part(2)], R),
    mutate_run(conflate_count_with_unit_size, R, M).

% Negative tests: the recognizer rejects each mutant as productive AND
% rejects an unmutated trace whose result was tampered with (the
% dishonest-verdict case the addition pilot accepted).
check_negative :-
    forall(demo_mutant(Task, M, _),
           ( \+ recognize(Task, M, productive),
             recognize(Task, M, deformed(_)) )),
    Task2 = asked(complement_within(whole_number(7), 2)),
    run_kernel(complete_to_unit, whole_number(7), [part(2)],
               run(K, G, A, Steps, _)),
    Tampered = run(K, G, A, Steps, complement(4)),
    \+ recognize(Task2, Tampered, productive),
    recognize(Task2, Tampered, unvindicated).

% For the two tested kernel mutations, mutate then bridge equals bridge
% then mutate because translate_run/3 changes only the gate slot and the
% mutations do not inspect that slot. The gate mutation's lack of a
% whole-number preimage is likewise an authored mutate_run/3 domain
% restriction. This check preserves those structural properties; it
% does not discover a general fact about student errors.
check_commutation :-
    Br = bridge(whole_number(7), unit_fraction(7), psi(scale(7))),
    forall(member(Mu, [off_by_one(complement), drop_part(leftover)]),
           ( run_kernel(complete_to_unit, whole_number(7), [part(2)], R),
             mutate_run(Mu, R, M1), translate_run(Br, M1, MutThenBridge),
             translate_run(Br, R, RT), mutate_run(Mu, RT, BridgeThenMut),
             MutThenBridge = BridgeThenMut
           )),
    % gate mutation: defined at the fraction gate, undefined at the
    % whole-number gate, hence no preimage under the bridge.
    run_kernel(complete_to_unit, unit_fraction(7), [part(2)], RF),
    mutate_run(conflate_count_with_unit_size, RF, _),
    run_kernel(complete_to_unit, whole_number(7), [part(2)], RW),
    \+ mutate_run(conflate_count_with_unit_size, RW, _).

% What resists the pilot kernels, reported rather than forced. These
% name control forms the kernel set does not carry yet; each is a
% candidate kernel for the next wave, with its corpus locus.
resists(fact_retrieval_economy,
        'retrieve/derive from a fact store; no iteration, completion, or partition',
        [addition/known_fact_retrieval, addition/derived_fact_adjustment,
         multiplication/multiplication_fact_retrieval]).
resists(anchor_then_compensate,
        'suspend an invariant, run an easier problem, repair the difference',
        [addition/round_then_adjust, subtraction/sliding_constant_difference,
         multiplication/known_product_adjustment]).
resists(columnar_shell,
        'a traversal shell scheduling a per-place kernel; the shell, not the kernel, is missing here',
        [addition/column_addition_with_carrying, subtraction/borrow_across_zero_cascade]).

check_resisters :-
    aggregate_all(count, resists(_, _, _), N),
    N >= 3,
    format('  resisters reported: ~w control forms outside the pilot kernels~n', [N]).

% Locus-exact candidates, enumerated.
check_candidates :-
    aggregate_all(count, candidate_deformation(_, _, _), N),
    format('  candidate deformations (locus-exact, unattested here): ~w~n', [N]),
    N > 0.

check_kernel_pilot :-
    check_shared_kernel,
    format('shared kernel: 2|->5 at radix_cycle(7) and partitioned_whole(7), one skeleton, bridge cited ... ok~n'),
    check_radix_denominator,
    format('radix vs denominator: independent gate parameters ... ok~n'),
    check_gate_partiality,
    format('partiality: whole gate refuses 3-5, integer gate computes -2, repair reproduces smaller-from-larger ... ok~n'),
    check_output_selection,
    format('output selection: distance vs endpoint from one loop; endpoint-as-difference is a mutation ... ok~n'),
    check_partition_direction,
    format('partition/regroup: directions distinct, nesting composes to 1/49 ... ok~n'),
    check_execution_validity,
    format('validity: from execution against independent ground truth, no authored table ... ok~n'),
    check_admitted_kernel_validity,
    format('admitted validity: refinement, place comparison, recollection, and pair-enumeration runs are productive; tampered results unvindicated ... ok~n'),
    check_pair_enumeration_admission,
    format('pair enumeration: prototype pair lists, one skeleton across product and sum gates ... ok~n'),
    check_recollect_compare_composition,
    format('composition: recollection feeds canonical comparison for 8,405 pairs at counts 0..40 and bases 2,10,16,36,40 ... ok~n'),
    check_admission_refusals,
    format('admission refusals: reviewed malformed calls and out-of-gate pair inputs refuse without throwing ... ok~n'),
    check_negative,
    format('negative tests: mutants and tampered results rejected; dishonest runs named ... ok~n'),
    check_commutation,
    format('commutation: encoding preserves two structural commutations and its authored no-preimage restriction ... ok~n'),
    check_resisters,
    check_candidates.
