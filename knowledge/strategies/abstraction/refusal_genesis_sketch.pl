:- encoding(utf8).
/** <module> Refusal genesis sketch — licenses, antecedents, and the gate ladder
 *
 * A SKETCH, smaller and more provisional than kernel_gate_pilot.pl,
 * loading that module and adding three ideas from the owner's note of
 * 2026-08-03. It is quarantined like everything else in this line:
 * nothing imports it, nothing is renamed.
 *
 * IDEA 1 — GATE MUTATIONS HAVE ANTECEDENTS. 3-5=2=5-3 is not a sort
 * collapse out of nowhere: it is commutativity, a rule the collection
 * gate licenses for addition, transported to a difference where no
 * gate licenses it. Adding across denominators is componentwise
 * combination, licensed where components are independent counts
 * (2 apples + 3 oranges), transported to a fraction whose "components"
 * are a count and its unit size. Equals-as-arrow is procedural
 * sequencing, licensed in the do-this-then-that genre, transported
 * into assertion. So the diagnosis of a gate mutation is not "the sort
 * was collapsed" but "WHICH gate licenses this move, and what did the
 * transfer forget." license/2 and antecedent/3 record this;
 * check_antecedents/0 is a referential-integrity check: every authored
 * gate-level mutation names a home license that is also an authored
 * license row. In scorekeeping terms:
 * the student claims an entitlement by inheritance from a practice
 * where it was earned, and the inheritance is what fails.
 *
 * IDEA 2 — REFUSALS GENERATE REPAIRS *AND* MATHEMATICS. The pilot
 * showed a gate refusal repaired by a student mutation
 * (evade_refusal). The same refusal, repaired institutionally, is a
 * NEW GATE: the integers are the licensing of the run the whole-number
 * gate refuses at 3-5; the rationals license the share the whole
 * gate refuses; the reals license the segment the measuring-stick
 * gate refuses at the diagonal of the unit square. genesis/3 records
 * the ladder; check_genesis/0 runs the subtraction rung end to end
 * (same kernel run: refused at whole_number(10), computed at
 * integer_line). The repo already attests the top rung twice over:
 * the incommensurability triple in
 * formal/incompatibility/brandomian_incompatibility.pl (the one
 * machine-checked emergent hyperedge — stick grounds length, length
 * is a count of stick-units, the diagonal is measured: jointly
 * incoherent, pairwise fine) and the L&N blend row in
 * knowledge/geometry/metaphors/measuring_stick.pl
 * (sqrt_2_must_exist_as_a_number — the blend that "gave birth to the
 * irrational numbers"). A misconception and a number system are the
 * same move — a license transported past a refusal — under different
 * scorekeeping: the student's transfer goes unvindicated; the
 * institution's is made coherent and becomes a gate.
 *
 * IDEA 3 — KERNELS ENTER ONLY BY FAILED DERIVATION. The direction
 * question (start from counting up, or from fraction division down)
 * dissolves under this rule: try to derive the complex practice by
 * composing existing kernels under gates; a new kernel is admitted
 * only when the derivation fails, and each admission is the finding.
 * Here: non-common-denominator addition costs exactly ONE new kernel
 * (co_measure — find the common refinement of two units), after which
 * it is co_measure, a bridge, and the whole-number iterate kernel at
 * the numerator level (check_noncommon_addition/0). Fraction
 * measurement division then costs ZERO further kernels: a shell that
 * loops the iterate kernel downward and uses the GATE'S OWN REFUSAL
 * as its stopping condition (check_fraction_division/0). And
 * co_measure is the kernel whose refusal at (side, diagonal) is the
 * top of the ladder. check_comeasure_refusal/0 is a referential-integrity
 * check over the authored refusal, genesis, and license rows.
 *
 * LIMITS. Incommensurability is flagged symbolically (a length marked
 * irrational is refused), not detected — detecting it is mathematics,
 * not bookkeeping. The ladder has three rungs and the middle one is
 * stated, not run. Licenses and antecedents are hand-named rows,
 * vetoable one by one. The discourse-genre antecedent
 * (equals-as-arrow) is recorded as data and not run: performing
 * assertion is not claimed here, per commitment_automata.pl.
 */

:- module(refusal_genesis_sketch,
          [ license/2,
            antecedent/3,
            genesis/3,
            run_co_measure/3,
            add_noncommon/3,
            measure_out/4,
            check_refusal_genesis/0
          ]).

:- use_module(kernel_gate_pilot,
              [ run_kernel/4, mutate_run/3, gate/2 ]).

% ==========================================================================
% 1. LICENSES AND ANTECEDENTS
%
% license(Gate, Rule): the gate grants the rule. Gates here include the
% grounding-metaphor gates the corpus already annotates
% (grounding_metaphor/2 in formal/pml/mua_relations.pl uses
% object_collection, object_construction, motion_along_path).
% ==========================================================================

license(collection(addition), commutativity).
license(collection(addition), componentwise_combination(independent_counts)).
license(path(addition), commutativity).
license(procedure_genre, sequencing(then)).
license(integer_line, totality(subtraction)).
license(real_line, every_segment_corresponds_to_a_number).
% The blend license is the L&N row: measuring_stick.pl,
% number_physical_segment_blend_for_irrationals.

% antecedent(Mutation, HomeLicense, WhatTheTransferForgets).
antecedent(evade_refusal(swap_operands),
           license(collection(addition), commutativity),
           forgets(order_carries_role(minuend, subtrahend))).
antecedent(conflate_count_with_unit_size,
           license(collection(addition), componentwise_combination(independent_counts)),
           forgets(denominator_is_unit_size_not_count)).
antecedent(equals_as_arrow,
           license(procedure_genre, sequencing(then)),
           forgets(equality_is_symmetric_and_flanks_one_quantity)).

% Referential integrity over the authored antecedent and license rows.
check_antecedents :-
    forall(antecedent(_Mutation, license(Gate, Rule), forgets(_)),
           license(Gate, Rule)).

% ==========================================================================
% 2. THE GATE LADDER
%
% genesis(FromGate, Refusal, ToGate): the institutional repair of a
% refusal is a new gate under which the refused run computes.
% ==========================================================================

genesis(whole_number(_), refused(crosses_lower_limit), integer_line).
% Middle rung, stated not run in this sketch: the equal share the
% whole-number gate refuses (3 shared among 4) is licensed by the
% unit-fraction gate — partitive genesis of the rationals.
genesis(whole_number(_), refused(non_integer_share), unit_fraction(_)).
genesis(measuring_stick, refused(incommensurable), real_line).
% Provenance for the top rung: incompatible_set([stick_grounds_length,
% length_is_count_of_stick_units, diagonal_is_measured]) — the
% machine-checked emergent hyperedge in brandomian_incompatibility.pl —
% and the L&N blend row cited in the header.

% The subtraction rung, end to end: one kernel run, refused at the old
% gate, computed at the new one named by genesis/3.
check_genesis :-
    Args = [start(3), delta(5), direction(down), output(endpoint)],
    run_kernel(iterate_to_target, whole_number(10), Args, R),
    R = run(_, _, _, _, refused(Why)),
    genesis(whole_number(10), refused(Why), NewGate),
    run_kernel(iterate_to_target, NewGate, Args, R2),
    R2 = run(_, _, _, _, endpoint(-2)).

% ==========================================================================
% 3. CO_MEASURE — the one admitted kernel
%
% Find the common refinement of two units. Unit sizes are uf(D) (the
% unit fraction 1/D of a shared referent) or len(irrational(Name)) for
% a length with no common unit with the referent. Refusal at the
% incommensurable pair is the point, not an error state.
% ==========================================================================

run_co_measure(uf(D1), uf(D2), co_measured(uf(L), factor(F1), factor(F2))) :-
    integer(D1), integer(D2), D1 > 0, D2 > 0,
    L is lcm(D1, D2),
    F1 is L // D1,
    F2 is L // D2.
run_co_measure(uf(_), len(irrational(N)), refused(incommensurable(N))).
run_co_measure(len(irrational(N)), uf(_), refused(incommensurable(N))).

% Referential integrity over one executed refusal and the authored
% genesis and license rows that name it.
check_comeasure_refusal :-
    run_co_measure(uf(1), len(irrational(sqrt2)), refused(incommensurable(sqrt2))),
    genesis(measuring_stick, refused(incommensurable), real_line),
    license(real_line, every_segment_corresponds_to_a_number).

% ==========================================================================
% 4. COMPOSITION, NOT NEW CONTROL
%
% Non-common-denominator addition: co_measure, then the whole-number
% iterate kernel on counts of the common unit. Quantities stay
% quantities: c(Count, Unit) throughout, and the arithmetic never
% leaves "a count of a named unit."
% ==========================================================================

add_noncommon(c(N1, uf(D1)), c(N2, uf(D2)), c(Sum, uf(L))) :-
    run_co_measure(uf(D1), uf(D2), co_measured(uf(L), factor(F1), factor(F2))),
    C1 is N1 * F1,
    C2 is N2 * F2,
    run_kernel(iterate_to_target, whole_number(10),
               [start(C1), delta(C2), direction(up), output(endpoint)],
               run(_, _, _, _, endpoint(Sum))).

check_noncommon_addition :-
    % 1/4 + 1/6 = 3/12 + 2/12 = 5/12
    add_noncommon(c(1, uf(4)), c(1, uf(6)), c(5, uf(12))).

% Fraction measurement division as a shell over the iterate kernel:
% how many divisor-chunks fit in the dividend, both expressed in the
% co-measured unit. The loop's stopping condition is the whole-number
% gate's own refusal to go below zero — the refusal is the control.
measure_out(Total, Chunk, Quotient, Remainder) :-
    number(Chunk),
    Chunk > 0,
    measure_out_loop(Total, Chunk, 0, Quotient, Remainder).

measure_out_loop(Left, Chunk, Q0, Quotient, Remainder) :-
    run_kernel(iterate_to_target, whole_number(10),
               [start(Left), delta(Chunk), direction(down), output(endpoint)], R),
    (   R = run(_, _, _, _, endpoint(Next))
    ->  Q1 is Q0 + 1,
        measure_out_loop(Next, Chunk, Q1, Quotient, Remainder)
    ;   R = run(_, _, _, _, refused(crosses_lower_limit)),
        Quotient = Q0,
        Remainder = Left
    ).

check_fraction_division :-
    % 3/4 divided by 2/3: co-measure to twelfths, 9 and 8; one chunk of
    % 8 fits with 1 left, so the quotient is 1 and 1/8 of the divisor.
    run_co_measure(uf(4), uf(3), co_measured(uf(12), factor(F1), factor(F2))),
    N1 is 3 * F1, N2 is 2 * F2,
    N1 =:= 9, N2 =:= 8,
    \+ measure_out(N1, 0, _, _),
    \+ measure_out(N1, -1, _, _),
    measure_out(N1, N2, 1, 1).

check_refusal_genesis :-
    check_antecedents,
    format('antecedents: authored mutation rows refer to authored home-license rows ... ok~n'),
    check_genesis,
    format('genesis: 3-5 refused at whole_number(10), computed at integer_line via genesis/3 ... ok~n'),
    check_comeasure_refusal,
    format('co_measure: authored refusal, genesis, and real-line license rows agree ... ok~n'),
    check_noncommon_addition,
    format('composition: 1/4 + 1/6 = 5/12 via co_measure + whole-number iterate, one new kernel ... ok~n'),
    check_fraction_division,
    format('composition: 3/4 by 2/3 measures out 1 rem 1/12 via a shell, zero new kernels ... ok~n').
