:- encoding(utf8).
/** <module> Kernel/gate pilot — reusable mathematical-action kernels under genre gates
 *
 * WHAT THIS IS. An executable pilot of the formulation
 *
 *     strategy = gate(genre, representation) |> shell [ kernel ]
 *
 * on three cross-domain probes: complete_to_unit, iterate_to_target,
 * and partition/regroup. The kernel carries control flow and actually
 * computes. The gate supplies sorts, admissibility guards, the named
 * boundary, and result interpretation. Correct and incorrect doings are
 * instances or single local mutations of the same kernel run.
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
 *   - Three kernels do not cover the strategy corpus, and are not
 *     claimed to. check_resisters/0 REPORTS what resists them (the
 *     fact-retrieval economy, anchor-and-compensate, the columnar
 *     shell) instead of forcing it. Resisters are the work list for
 *     candidate kernels, not failures of the probe.
 *   - Gates here are three: whole_number(B), integer_line, and
 *     unit_fraction(D) over a referent whole. Measurement, decimal,
 *     and equation gates are future waves.
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
             asked(partition(7))-(partition_regroup-unit_fraction(7)-[unit(whole), plan(partition(7))])
           ]),
    run_kernel(K, G, A, R).

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

% What resists the three kernels, reported rather than forced. These
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
    format('  resisters reported: ~w control forms outside the three kernels~n', [N]).

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
    check_negative,
    format('negative tests: mutants and tampered results rejected; dishonest runs named ... ok~n'),
    check_commutation,
    format('commutation: encoding preserves two structural commutations and its authored no-preimage restriction ... ok~n'),
    check_resisters,
    check_candidates.
