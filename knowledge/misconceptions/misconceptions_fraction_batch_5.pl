:- module(misconceptions_fraction_batch_5, []).
% Fraction misconceptions — research corpus batch 5/7.
% Native arithmetic layer only. Theoretical annotations as comments:
%   % GROUNDED: TODO — placeholder for future embodied arithmetic layer
%   % SCHEMA: <schema name> — Lakoff & Nunez grounding when applicable
%   % CONNECTS TO: s(comp_nec(unlicensed(...))) — PML operator path
%
% Registration convention (from Task 3 arch fix):
%   test_harness:arith_misconception(Source, Domain, Description,
%       misconceptions_fraction_batch_5:rule_name, Input, Expected).
% Rule predicates do NOT go on the module export list.

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

% ---- Encodings appended by agent for batch 5 ----

% === row 37438: multiplicative-as-additive comparison ===
% Task: stick that is 5 times longer than original.
% Correct: 5 (iterate 5 copies).
% Error: 6 (interpret "5 times longer" as "5 more", yielding 6 total).
% SCHEMA: Arithmetic is Object Collection — add-for-multiply slip
% GROUNDED: TODO — iterate_grounded vs succ_grounded
% CONNECTS TO: s(comp_nec(unlicensed(additive_for_multiplicative)))
r37438_five_times_as_five_more(Scalar, Got) :-
    Got is Scalar + 1.

test_harness:arith_misconception(db_row(37438), fraction, multiplicative_as_additive,
    misconceptions_fraction_batch_5:r37438_five_times_as_five_more,
    5,
    5).

% === row 37445: improper fraction partitioned to largest number ===
% Task: make 14/13 (improper) from a unit bar.
% Correct: frac(14,13) — partition into 13, iterate 14.
% Error: frac(14,14) — partitioned into 14 parts instead of 13.
% SCHEMA: Measuring Stick — denominator confused with larger numeral
% GROUNDED: TODO — partition_grounded(R13, ...) vs partition_grounded(R14, ...)
% CONNECTS TO: s(comp_nec(unlicensed(partition_by_largest_numeral)))
r37445_partition_by_largest(frac(N,D), frac(N,N)) :-
    N > D.

test_harness:arith_misconception(db_row(37445), fraction, improper_partition_by_largest,
    misconceptions_fraction_batch_5:r37445_partition_by_largest,
    frac(14,13),
    frac(14,13)).

% === row 37452: standard algorithm as hindrance to reasoning ===
% Student computed 2/3 × 7/9 = 14/27 by standard algorithm. The algorithm
% yields the correct numeric answer; the misconception is procedural
% reliance without structural modeling — no distinct wrong numeric answer.
test_harness:arith_misconception(db_row(37452), fraction, too_vague,
    skip, none, none).

% === row 37500: density — no fraction between consecutive numerators ===
% Task: produce a fraction between 2/5 and 3/5.
% Correct: frac(5,10) (or any midpoint).
% Error: none (student denies any fraction exists).
% SCHEMA: Measuring Stick — fraction sequence treated as whole-number counting
% GROUNDED: TODO — midpoint_grounded
% CONNECTS TO: s(comp_nec(unlicensed(density_denial(consecutive_numerators))))
r37500_density_denial(frac(_,_)-frac(_,_), none).

test_harness:arith_misconception(db_row(37500), fraction, density_denial,
    misconceptions_fraction_batch_5:r37500_density_denial,
    frac(2,5)-frac(3,5),
    frac(5,10)).

% === row 37514: Equal Outputs inverse relationship forgotten ===
% Task: compare 2/4 and 2/3.
% Correct: frac(2,3) (larger).
% Error: frac(2,4) (student says "4 blocks in" means larger).
% SCHEMA: Measuring Stick — inverse relation input↔size dropped
% GROUNDED: TODO — compare_grounded with inverse-aware reasoning
% CONNECTS TO: s(comp_nec(unlicensed(equal_outputs_inverse_drop)))
r37514_equal_outputs_inverse(frac(N1,D1)-frac(N2,D2), Larger) :-
    ( D1 > D2 -> Larger = frac(N1,D1) ; Larger = frac(N2,D2) ).

test_harness:arith_misconception(db_row(37514), fraction, equal_outputs_inverse_error,
    misconceptions_fraction_batch_5:r37514_equal_outputs_inverse,
    frac(2,4)-frac(2,3),
    frac(2,3)).

% === row 37522: language for halves ===
% No concrete wrong numeric answer — linguistic/terminological.
test_harness:arith_misconception(db_row(37522), fraction, too_vague,
    skip, none, none).

% === row 37562: referent whole confusion in 2/3 of 3/4 ===
% Task: 2/3 of 3/4.
% Correct: frac(6,12) — six of twelve sub-parts of the full whole.
% Error: frac(6,9) — student names the answer relative to the 3/4 piece.
% SCHEMA: Measuring Stick — referent whole displaced
% GROUNDED: TODO — multiply_grounded with fixed referent
% CONNECTS TO: s(comp_nec(unlicensed(referent_whole_displacement)))
r37562_referent_whole_drop(frac(N1,D1)-frac(N2,_D2), frac(Num, D1Num)) :-
    Num is N1 * N2,
    D1Num is D1 * N2.

test_harness:arith_misconception(db_row(37562), fraction, referent_whole_displacement,
    misconceptions_fraction_batch_5:r37562_referent_whole_drop,
    frac(2,3)-frac(3,4),
    frac(6,12)).

% === row 37582: "7 is 3/4 of 10 because 3+4=7" ===
% Task: evaluate claim "7 is 3/4 of 10".
% Correct answer to "what is 3/4 of 10?": 15/2 (not 7).
% Error: returns N+D = 7.
% SCHEMA: Arithmetic is Object Collection — syntactic addition for multiplicative claim
% GROUNDED: TODO — multiply_grounded vs add_grounded
% CONNECTS TO: s(comp_nec(unlicensed(syntactic_sum_for_fraction_of_whole)))
r37582_syntactic_sum(frac(N,D)-_Whole, Got) :-
    Got is N + D.

test_harness:arith_misconception(db_row(37582), fraction, syntactic_sum_for_fraction_of,
    misconceptions_fraction_batch_5:r37582_syntactic_sum,
    frac(3,4)-10,
    frac(15,2)).

% === row 37604: decimal approximation perturbation ===
% Conceptual — awareness that decimal approximations are not exact.
test_harness:arith_misconception(db_row(37604), fraction, too_vague,
    skip, none, none).

% === row 37658: invert-and-multiply misapplied to multiplication ===
% Task: half of a third = 1/2 × 1/3.
% Correct: frac(1,6).
% Error: frac(2,3) — applies division algorithm (1/3 ÷ 1/2 = 2/3).
% SCHEMA: Measuring Stick — operation substitution
% GROUNDED: TODO — multiply_grounded vs divide_grounded
% CONNECTS TO: s(comp_nec(unlicensed(operation_substitution(divide_for_multiply))))
r37658_invert_multiply_for_times(frac(N1,D1)-frac(N2,D2), frac(Num, Den)) :-
    Num is N1 * D2,
    Den is D1 * N2.

test_harness:arith_misconception(db_row(37658), fraction, invert_multiply_for_times,
    misconceptions_fraction_batch_5:r37658_invert_multiply_for_times,
    frac(1,2)-frac(1,3),
    frac(1,6)).

% === row 37668: embodiment transformations / perception ===
% Conceptual perception issue — no numeric wrong answer.
test_harness:arith_misconception(db_row(37668), fraction, too_vague,
    skip, none, none).

% === row 37681: partition too-small-to-be-viable ===
% Affective / size-viability block — not a numeric error.
test_harness:arith_misconception(db_row(37681), fraction, too_vague,
    skip, none, none).

% === row 37747: PSTs fail simple equivalence/comparison ===
% Population-level rates without specific wrong transformation.
test_harness:arith_misconception(db_row(37747), fraction, too_vague,
    skip, none, none).

% === row 37770: improper/mixed: 3/3 + 1/3 read as 3 and 1/3 ===
% Task: add 3/3 and 1/3 (or express as improper).
% Correct: frac(4,3).
% Error: frac(10,3) — reads 3/3 bar as whole "3" plus 1/3 → "3 and 1/3".
% SCHEMA: Measuring Stick — unit-whole coordination missing
% GROUNDED: TODO — add_grounded on fraction units
% CONNECTS TO: s(comp_nec(unlicensed(unit_whole_conflation)))
r37770_three_thirds_as_three(frac(N1,D)-frac(N2,D), frac(Num, D)) :-
    Whole is N1,
    Num is Whole * D + N2.

test_harness:arith_misconception(db_row(37770), fraction, three_thirds_as_three,
    misconceptions_fraction_batch_5:r37770_three_thirds_as_three,
    frac(3,3)-frac(1,3),
    frac(4,3)).

% === row 37791: perceptual distracters ===
% Task difficulty description, no numeric wrong answer.
test_harness:arith_misconception(db_row(37791), fraction, too_vague,
    skip, none, none).

% === row 37809: anticipatory checking strategies ===
% Developmental / strategic — no numeric answer.
test_harness:arith_misconception(db_row(37809), fraction, too_vague,
    skip, none, none).

% === row 37825: can't take 9 from 7 — part-whole limitation ===
% Task: draw 9/7 from a unit bar.
% Correct: partition into 7, iterate 9 (frac(9,7)).
% Error: partitioned bar into 9 pieces instead of iterating.
% SCHEMA: Container — part-whole ceiling at denominator
% GROUNDED: TODO — iterate_grounded past the whole
% CONNECTS TO: s(comp_nec(unlicensed(part_whole_ceiling)))
r37825_part_whole_ceiling(frac(N,D), frac(N,N)) :-
    N > D.

test_harness:arith_misconception(db_row(37825), fraction, part_whole_ceiling,
    misconceptions_fraction_batch_5:r37825_part_whole_ceiling,
    frac(9,7),
    frac(9,7)).

% === row 37848: 1/12 ÷ 1/3 = 0 (natural-number division) ===
% Task: 1/12 ÷ 1/3.
% Correct: frac(1,4) (invert and multiply).
% Error: 0 — "can't fit 1/3 into 1/12".
% SCHEMA: Container — measurement-division with whole-number containment
% GROUNDED: TODO — divide_grounded with scaling
% CONNECTS TO: s(comp_nec(unlicensed(containment_yields_zero)))
r37848_containment_zero(frac(N1,D1)-frac(N2,D2), 0) :-
    N1 =:= 1, N2 =:= 1, D1 > D2.

test_harness:arith_misconception(db_row(37848), fraction, containment_yields_zero,
    misconceptions_fraction_batch_5:r37848_containment_zero,
    frac(1,12)-frac(1,3),
    frac(1,4)).

% === row 37870: leftover-pieces count for comparison ===
% Task: compare 2/3 and 3/4.
% Correct: second_greater (3/4 > 2/3).
% Error: equal — "same number of pieces left over".
% SCHEMA: Container — complement count instead of shaded area
% GROUNDED: TODO — compare_grounded on shaded, not unshaded
% CONNECTS TO: s(comp_nec(unlicensed(leftover_pieces_for_comparison)))
r37870_leftover_pieces(frac(N1,D1)-frac(N2,D2), Result) :-
    L1 is D1 - N1,
    L2 is D2 - N2,
    ( L1 =:= L2 -> Result = equal
    ; L1 < L2 -> Result = first_greater
    ; Result = second_greater ).

test_harness:arith_misconception(db_row(37870), fraction, leftover_pieces_for_comparison,
    misconceptions_fraction_batch_5:r37870_leftover_pieces,
    frac(2,3)-frac(3,4),
    second_greater).

% === row 37899: teachers fail 1 3/4 ÷ 1/2 ===
% Population-level description; no one uniform wrong transformation.
test_harness:arith_misconception(db_row(37899), fraction, too_vague,
    skip, none, none).

% === row 37916: fractions not as numbers / number line ===
% Ontological claim, not a computable wrong answer.
test_harness:arith_misconception(db_row(37916), fraction, too_vague,
    skip, none, none).

% === row 37953: relational naming vs count ===
% Mixed "how many" vs "how much" — not a single numeric rule.
test_harness:arith_misconception(db_row(37953), fraction, too_vague,
    skip, none, none).

% === row 37980: rigid invert-and-multiply ===
% Description of algorithm preference without a distinct wrong answer.
test_harness:arith_misconception(db_row(37980), fraction, too_vague,
    skip, none, none).

% === row 38068: gap thinking — 5/6 = 7/8 ===
% Task: compare 5/6 and 7/8.
% Correct: second_greater.
% Error: equal — "both one bit from whole".
% SCHEMA: Measuring Stick — numerator-denominator gap ignores piece size
% GROUNDED: TODO — compare_grounded
% CONNECTS TO: s(comp_nec(unlicensed(gap_thinking)))
r38068_gap_thinking(frac(N1,D1)-frac(N2,D2), Result) :-
    G1 is D1 - N1,
    G2 is D2 - N2,
    ( G1 =:= G2 -> Result = equal
    ; G1 < G2 -> Result = first_greater
    ; Result = second_greater ).

test_harness:arith_misconception(db_row(38068), fraction, gap_thinking,
    misconceptions_fraction_batch_5:r38068_gap_thinking,
    frac(5,6)-frac(7,8),
    second_greater).

% === row 38127: largest components = largest fraction ===
% Task: which of 1/2, 3/6, 2/4 is biggest (all equal).
% Correct: equal.
% Error: first_greater for frac(3,6) vs frac(1,2) — picks larger numerals.
% SCHEMA: Measuring Stick — whole-number bias on components
% GROUNDED: TODO — compare_grounded with equivalence
% CONNECTS TO: s(comp_nec(unlicensed(largest_components_bias)))
r38127_largest_components(frac(N1,D1)-frac(N2,D2), Result) :-
    S1 is N1 + D1,
    S2 is N2 + D2,
    ( S1 =:= S2 -> Result = equal
    ; S1 > S2 -> Result = first_greater
    ; Result = second_greater ).

test_harness:arith_misconception(db_row(38127), fraction, largest_components_bias,
    misconceptions_fraction_batch_5:r38127_largest_components,
    frac(3,6)-frac(1,2),
    equal).

% === row 38147: N or D increasing → fraction increases ===
% No concrete example given; description only.
test_harness:arith_misconception(db_row(38147), fraction, too_vague,
    skip, none, none).

% === row 38222: rote cross-cancel without understanding ===
% Lisa's cross-canceling yields the correct answer; no wrong numeric output.
test_harness:arith_misconception(db_row(38222), fraction, too_vague,
    skip, none, none).

% === row 38255: divisor-dividend reversal ===
% Task: 8 ÷ 2/3.
% Correct: 12.
% Error: computes 2/3 ÷ 8 = frac(2,24) = frac(1,12).
% SCHEMA: Source-Path-Goal — partitive default reverses operands
% GROUNDED: TODO — divide_grounded in both directions
% CONNECTS TO: s(comp_nec(unlicensed(divisor_dividend_reversal)))
r38255_reverse_divisor(Whole-frac(N,D), frac(Num, Den)) :-
    integer(Whole),
    Num is N,
    Den is D * Whole.

test_harness:arith_misconception(db_row(38255), fraction, divisor_dividend_reversal,
    misconceptions_fraction_batch_5:r38255_reverse_divisor,
    8-frac(2,3),
    12).

% === row 38268: part-whole prohibits improper ===
% Failure to produce; no specific wrong numeric answer.
test_harness:arith_misconception(db_row(38268), fraction, too_vague,
    skip, none, none).

% === row 38285: missing denom — scale factor substituted ===
% Task: 4/? = 36/63. Correct: ? = 7.
% Error: ? = 9 (the scale factor 4×9=36 substituted for denom).
% SCHEMA: Measuring Stick — scale factor confused with result denom
% GROUNDED: TODO — equivalence_grounded
% CONNECTS TO: s(comp_nec(unlicensed(scale_factor_as_denom)))
r38285_scale_factor_as_denom(frac(N1,_)-frac(N2,_), D1) :-
    % Scale factor S = N2 / N1. Student substitutes S for the missing denom.
    D1 is N2 // N1.

test_harness:arith_misconception(db_row(38285), fraction, scale_factor_as_denom,
    misconceptions_fraction_batch_5:r38285_scale_factor_as_denom,
    frac(4,missing)-frac(36,63),
    7).

% === row 38334: partitive scheme — swaps N and D for improper ===
% Task: produce 10/8.
% Correct: frac(10,8).
% Error: frac(8,10) — Jordan partitioned into 10 and filled 8.
% SCHEMA: Container — cannot exceed the container
% GROUNDED: TODO — partition and iterate grounded
% CONNECTS TO: s(comp_nec(unlicensed(partitive_scheme_swap)))
r38334_partitive_swap(frac(N,D), frac(D,N)) :-
    N > D.

test_harness:arith_misconception(db_row(38334), fraction, partitive_scheme_swap,
    misconceptions_fraction_batch_5:r38334_partitive_swap,
    frac(10,8),
    frac(10,8)).

% === row 38370: proper fraction multipliers contradict iteration ===
% Conceptual refusal, not a uniform wrong numeric output.
test_harness:arith_misconception(db_row(38370), fraction, too_vague,
    skip, none, none).

% === row 38395: improper fraction denominator = total pieces ===
% Task: four-fourths + one-fourth more = five-fourths.
% Correct: frac(5,4).
% Error: frac(5,5) — total pieces (5) used as denom.
% SCHEMA: Container — referent unit shifts with piece count
% GROUNDED: TODO — iterate_grounded preserving referent
% CONNECTS TO: s(comp_nec(unlicensed(total_count_as_denom)))
r38395_total_count_as_denom(frac(N1,D)-frac(N2,D), frac(Sum, Sum)) :-
    Sum is N1 + N2.

test_harness:arith_misconception(db_row(38395), fraction, total_count_as_denom,
    misconceptions_fraction_batch_5:r38395_total_count_as_denom,
    frac(4,4)-frac(1,4),
    frac(5,4)).

% === row 38421: reversing — partition by denominator, not numerator ===
% Task: "bar is 5/7, make the other bar" — partition into 5 (each = 1/7).
% Correct partition count: 5 (the numerator).
% Error: 7 — Michael partitioned into 7 parts (the denominator).
% SCHEMA: Measuring Stick — reversal operand confusion
% GROUNDED: TODO — reverse_fraction_grounded
% CONNECTS TO: s(comp_nec(unlicensed(reverse_partition_by_denominator)))
r38421_partition_by_denominator(frac(_N,D), D).

test_harness:arith_misconception(db_row(38421), fraction, reverse_partition_by_denominator,
    misconceptions_fraction_batch_5:r38421_partition_by_denominator,
    frac(5,7),
    5).

% === row 38435: division word problem replaced by multiplication ===
% Conceptual replacement, not a single wrong numeric output on one task.
test_harness:arith_misconception(db_row(38435), fraction, too_vague,
    skip, none, none).

% === row 38456: 1/4 + 1/2 = 1/5 (count physical pieces) ===
% Task: 1/4 + 1/2.
% Correct: frac(3,4).
% Error: frac(1,5) — Tim said 4+1=5 pieces, one numerator.
% SCHEMA: Arithmetic is Object Collection — piece-count confusion
% GROUNDED: TODO — add_grounded with common denominator
% CONNECTS TO: s(comp_nec(unlicensed(piece_count_denom)))
r38456_piece_count_denom(frac(N1,D1)-frac(N2,D2), frac(1, Sum)) :-
    Sum is D1 + D2,
    _ = N1, _ = N2.

test_harness:arith_misconception(db_row(38456), fraction, piece_count_denom,
    misconceptions_fraction_batch_5:r38456_piece_count_denom,
    frac(1,4)-frac(1,2),
    frac(3,4)).

% === row 38541: commutativity elides conceptual difference ===
% Teacher pedagogical conflation; no wrong numeric answer.
test_harness:arith_misconception(db_row(38541), fraction, too_vague,
    skip, none, none).

% === row 38559: add N+N and D+D (unlike denominators) ===
% Task: add two fractions with unlike denominators.
% Correct: common denominator addition.
% Error: frac(N1+N2, D1+D2).
% SCHEMA: Arithmetic is Object Collection — componentwise addition
% GROUNDED: TODO — add_grounded with LCM
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_addition)))
r38559_add_components(frac(N1,D1)-frac(N2,D2), frac(Num, Den)) :-
    Num is N1 + N2,
    Den is D1 + D2.

test_harness:arith_misconception(db_row(38559), fraction, add_numerators_and_denominators,
    misconceptions_fraction_batch_5:r38559_add_components,
    frac(1,3)-frac(1,4),
    frac(7,12)).

% === row 38594: decomposing 5/8 — partition by denominator ===
% Task: given a stick that is 5/8, rebuild the whole — partition into 5.
% Correct: 5 (the numerator).
% Error: 8 (the denominator).
% SCHEMA: Measuring Stick — reversal operand confusion
% GROUNDED: TODO — reverse_fraction_grounded
% CONNECTS TO: s(comp_nec(unlicensed(decompose_by_denominator)))
r38594_decompose_by_denominator(frac(_N,D), D).

test_harness:arith_misconception(db_row(38594), fraction, decompose_by_denominator,
    misconceptions_fraction_batch_5:r38594_decompose_by_denominator,
    frac(5,8),
    5).

% === row 38658: (7/8)x = 5 — eighths of known instead of sevenths ===
% Task: solve (7/8)x = 5, i.e. find 1/7 of known, then add 5 units.
% Correct: 40/7 (student should divide 5 into 7 parts and iterate).
% Error: divided 5 into 8 parts (denom of 7/8), yielding 40 "small pieces"
%   and planning to add 5 — effectively returning 5 (or frac(5,8) of 8).
% SCHEMA: Measuring Stick — denom used as partition of known quantity
% GROUNDED: TODO — reverse_multiplication_grounded
% CONNECTS TO: s(comp_nec(unlicensed(denom_partitions_known)))
r38658_denom_partitions_known(frac(N,D)-Known, frac(Num, D)) :-
    integer(Known),
    Num is Known * N.

test_harness:arith_misconception(db_row(38658), fraction, denom_partitions_known,
    misconceptions_fraction_batch_5:r38658_denom_partitions_known,
    frac(7,8)-5,
    frac(40,7)).

% === row 38665: half of 1/4 = 4.5 (count pieces plus half-piece) ===
% Task: half of 1/4.
% Correct: frac(1,8).
% Error: 4.5 (student: "four of them and then one half of it").
% SCHEMA: Container — counts visible pieces plus fractional remainder
% GROUNDED: TODO — multiply_grounded for recursive partition
% CONNECTS TO: s(comp_nec(unlicensed(count_pieces_plus_half)))
r38665_count_pieces_plus_half(frac(_,D1)-frac(_,D2), frac(Num, Den)) :-
    % D2 pieces visible, half of one more: D2 + 1/2 = (2*D2+1)/2
    _ = D1,
    Num is 2 * D2 + 1,
    Den is 2.

test_harness:arith_misconception(db_row(38665), fraction, count_pieces_plus_half,
    misconceptions_fraction_batch_5:r38665_count_pieces_plus_half,
    frac(1,2)-frac(1,4),
    frac(1,8)).

% === row 38680: teacher misinterprets diagram referent ===
% Adult-pedagogical shift; not a student computational rule.
test_harness:arith_misconception(db_row(38680), fraction, too_vague,
    skip, none, none).

% === row 38718: improper fraction → redefine whole ===
% Task: name 4/3.
% Correct: frac(4,3).
% Error: frac(4,4) — whole redefined to extended quantity.
% SCHEMA: Container — whole stretches to include all pieces
% GROUNDED: TODO — iterate_grounded past whole, preserving referent
% CONNECTS TO: s(comp_nec(unlicensed(redefine_whole_as_total)))
r38718_redefine_whole(frac(N,D), frac(N,N)) :-
    N > D.

test_harness:arith_misconception(db_row(38718), fraction, redefine_whole_as_total,
    misconceptions_fraction_batch_5:r38718_redefine_whole,
    frac(4,3),
    frac(4,3)).

% === row 38794: larger denominator = smaller pieces = smaller fraction (ignoring N) ===
% Task: compare 2 1/3 and 2 2/6 (equal as mixed numbers).
% Correct: equal.
% Error: first_greater — "thirds are bigger than sixths".
% SCHEMA: Measuring Stick — piece-size focus, numerator ignored
% GROUNDED: TODO — compare_grounded with both N and D
% CONNECTS TO: s(comp_nec(unlicensed(denominator_only_comparison)))
r38794_denominator_only(frac(_,D1)-frac(_,D2), Result) :-
    ( D1 =:= D2 -> Result = equal
    ; D1 < D2 -> Result = first_greater
    ; Result = second_greater ).

test_harness:arith_misconception(db_row(38794), fraction, denominator_only_comparison,
    misconceptions_fraction_batch_5:r38794_denominator_only,
    frac(1,3)-frac(2,6),
    equal).

% === row 38838: 1/2 + 1/4 = 2/6 ===
% Task: 1/2 + 1/4.
% Correct: frac(3,4).
% Error: frac(2,6) — componentwise addition.
% SCHEMA: Arithmetic is Object Collection — two whole-numbers abstraction
% GROUNDED: TODO — add_grounded with LCM
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_addition)))
r38838_componentwise_add(frac(N1,D1)-frac(N2,D2), frac(Num, Den)) :-
    Num is N1 + N2,
    Den is D1 + D2.

test_harness:arith_misconception(db_row(38838), fraction, componentwise_addition,
    misconceptions_fraction_batch_5:r38838_componentwise_add,
    frac(1,2)-frac(1,4),
    frac(3,4)).

% === row 38858: arithmetic without conceptual understanding ===
% Descriptive — no specific wrong transformation.
test_harness:arith_misconception(db_row(38858), fraction, too_vague,
    skip, none, none).

% === row 38923: teacher forces procedure ===
% Adult-pedagogical; no student computational rule.
test_harness:arith_misconception(db_row(38923), fraction, too_vague,
    skip, none, none).

% === row 38973: natural-number bias — 14/57 > 1/3 ===
% Task: compare 14/57 and 1/3.
% Correct: second_greater (1/3 ≈ 0.333 > 14/57 ≈ 0.246).
% Error: first_greater — "14>1 and 57>3".
% SCHEMA: Measuring Stick — componentwise whole-number dominance
% GROUNDED: TODO — compare_grounded via cross-product
% CONNECTS TO: s(comp_nec(unlicensed(natural_number_bias)))
r38973_natural_number_bias(frac(N1,D1)-frac(N2,D2), Result) :-
    ( N1 > N2, D1 > D2 -> Result = first_greater
    ; N1 < N2, D1 < D2 -> Result = second_greater
    ; Result = equal ).

test_harness:arith_misconception(db_row(38973), fraction, natural_number_bias,
    misconceptions_fraction_batch_5:r38973_natural_number_bias,
    frac(14,57)-frac(1,3),
    second_greater).

% === row 38989: median-of-fractions as addition ===
% Task: add two fractions.
% Correct: common denominator sum.
% Error: (a+c)/(b+d).
% SCHEMA: Arithmetic is Object Collection — averaging op for addition
% GROUNDED: TODO — add_grounded with LCM
% CONNECTS TO: s(comp_nec(unlicensed(median_for_addition)))
r38989_median_for_add(frac(N1,D1)-frac(N2,D2), frac(Num, Den)) :-
    Num is N1 + N2,
    Den is D1 + D2.

test_harness:arith_misconception(db_row(38989), fraction, median_for_addition,
    misconceptions_fraction_batch_5:r38989_median_for_add,
    frac(1,2)-frac(1,3),
    frac(5,6)).

% === row 39040: algorithm executed incorrectly without meaning ===
% Idiosyncratic extraction ("4/3 and 2/2") — no regular rule.
test_harness:arith_misconception(db_row(39040), fraction, too_vague,
    skip, none, none).

% === row 39090: larger numbers dominance — 4/7 > 4/5 ===
% Task: compare 4/7 and 4/5.
% Correct: second_greater.
% Error: first_greater — "larger numbers in 4/7 (7>5)".
% SCHEMA: Measuring Stick — denominator-larger-means-bigger bias
% GROUNDED: TODO — compare_grounded
% CONNECTS TO: s(comp_nec(unlicensed(whole_number_dominance_denom)))
r39090_whole_number_dominance(frac(N1,D1)-frac(N2,D2), Result) :-
    ( N1 =:= N2
    -> ( D1 > D2 -> Result = first_greater
       ; D1 < D2 -> Result = second_greater
       ; Result = equal )
    ; D1 =:= D2
    -> ( N1 > N2 -> Result = first_greater
       ; N1 < N2 -> Result = second_greater
       ; Result = equal )
    ; Result = equal ).

test_harness:arith_misconception(db_row(39090), fraction, whole_number_dominance,
    misconceptions_fraction_batch_5:r39090_whole_number_dominance,
    frac(4,7)-frac(4,5),
    second_greater).

% === row 39139: no visual imagery for numerator>1 ===
% Failure to produce — no wrong numeric rule.
test_harness:arith_misconception(db_row(39139), fraction, too_vague,
    skip, none, none).

% === row 39170: equally spaced unit fractions on number line ===
% PST representation error; no specific numeric rule.
test_harness:arith_misconception(db_row(39170), fraction, too_vague,
    skip, none, none).

% === row 39199: cuts equal pieces ===
% Task: cuts to make N equal pieces.
% Correct: N-1.
% Error: N.
% SCHEMA: Source-Path-Goal — cut-piece count identification
% GROUNDED: TODO — partition_grounded
% CONNECTS TO: s(comp_nec(unlicensed(cuts_equal_pieces)))
r39199_cuts_equal_pieces(Pieces, Pieces).

test_harness:arith_misconception(db_row(39199), fraction, cuts_equal_pieces,
    misconceptions_fraction_batch_5:r39199_cuts_equal_pieces,
    3,
    2).

% === row 39275: invented fraction names ===
% Linguistic — no numeric error.
test_harness:arith_misconception(db_row(39275), fraction, too_vague,
    skip, none, none).

% === row 39349: PSTs failed to transfer info ===
% Description-only, no concrete wrong answer.
test_harness:arith_misconception(db_row(39349), fraction, too_vague,
    skip, none, none).

% === row 39433: fair-sharing reciprocal — 5/4 instead of 4/5 ===
% Task: 4 sandwiches shared among 5 people → each gets 4/5.
% Correct: frac(4,5).
% Error: frac(5,4) — N and D swapped.
% SCHEMA: Measuring Stick — extensive-quantity confusion in rate
% GROUNDED: TODO — divide_grounded as rate
% CONNECTS TO: s(comp_nec(unlicensed(fair_share_reciprocal)))
r39433_fair_share_reciprocal(Items-People, frac(People, Items)).

test_harness:arith_misconception(db_row(39433), fraction, fair_share_reciprocal,
    misconceptions_fraction_batch_5:r39433_fair_share_reciprocal,
    4-5,
    frac(4,5)).

% === row 39486: reverse — halving 1/6 to make 1/3 ===
% Task: given 1/6, make 1/3 (iterate twice).
% Correct: frac(1,3).
% Error: frac(1,12) — halved the 1/6 bar.
% SCHEMA: Measuring Stick — forward operation applied for inverse
% GROUNDED: TODO — reverse_partition_grounded
% CONNECTS TO: s(comp_nec(unlicensed(forward_for_reverse)))
r39486_forward_for_reverse(frac(N,D), frac(N, Doubled)) :-
    Doubled is 2 * D.

test_harness:arith_misconception(db_row(39486), fraction, forward_for_reverse,
    misconceptions_fraction_batch_5:r39486_forward_for_reverse,
    frac(1,6),
    frac(1,3)).

% === row 39571: larger denominator as cause of bigger fraction ===
% No example in corpus row.
test_harness:arith_misconception(db_row(39571), fraction, too_vague,
    skip, none, none).

% === row 39605: numerator as per-group count ===
% Task: 2/4 of 12.
% Correct: 6.
% Error: partitioned 12 into groups of 2 (N per group), producing 6 groups —
%   numeric answer coincidentally 6. No distinct wrong output.
test_harness:arith_misconception(db_row(39605), fraction, too_vague,
    skip, none, none).

% === row 39640: coordinating multiple meanings of 8/6 ===
% Conceptual struggle, no single wrong output.
test_harness:arith_misconception(db_row(39640), fraction, too_vague,
    skip, none, none).

% === row 39668: unequal rods called halves ===
% No arithmetic rule to encode.
test_harness:arith_misconception(db_row(39668), fraction, too_vague,
    skip, none, none).

% === row 39697: area-model in non-area context ===
% Geometric misapplication; no arithmetic output.
test_harness:arith_misconception(db_row(39697), fraction, too_vague,
    skip, none, none).

% === row 39723: fraction of a set interpreted as cutting items ===
% No numeric wrong answer.
test_harness:arith_misconception(db_row(39723), fraction, too_vague,
    skip, none, none).

% === row 39767: common denominator for multiplication ===
% Task: 1/3 × 5/4.
% Correct: frac(5,12).
% Error: frac(60,12) — converted to 4/12 and 15/12, then multiplied.
% SCHEMA: Arithmetic is Object Collection — additive rule misapplied
% GROUNDED: TODO — multiply_grounded without LCM conversion
% CONNECTS TO: s(comp_nec(unlicensed(common_denom_for_multiply)))
r39767_common_denom_multiply(frac(N1,D1)-frac(N2,D2), frac(Num, Den)) :-
    LCM is D1 * D2,
    Scaled1 is N1 * D2,
    Scaled2 is N2 * D1,
    Num is Scaled1 * Scaled2,
    Den is LCM.

test_harness:arith_misconception(db_row(39767), fraction, common_denom_for_multiply,
    misconceptions_fraction_batch_5:r39767_common_denom_multiply,
    frac(1,3)-frac(5,4),
    frac(5,12)).

% === row 39782: 2/3 + 1/7 = 3/10 (tops and bottoms) ===
% Task: 2/3 + 1/7.
% Correct: frac(17,21).
% Error: frac(3,10) — componentwise addition.
% SCHEMA: Arithmetic is Object Collection — componentwise addition
% GROUNDED: TODO — add_grounded with LCM
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_addition)))
r39782_componentwise_add(frac(N1,D1)-frac(N2,D2), frac(Num, Den)) :-
    Num is N1 + N2,
    Den is D1 + D2.

test_harness:arith_misconception(db_row(39782), fraction, tops_and_bottoms_addition,
    misconceptions_fraction_batch_5:r39782_componentwise_add,
    frac(2,3)-frac(1,7),
    frac(17,21)).

% === row 39813: halving-fails for odd denominators ===
% Strategy-selection issue, no numeric output.
test_harness:arith_misconception(db_row(39813), fraction, too_vague,
    skip, none, none).

% === row 39820: different wholes not coordinated ===
% Depends on unspecified values; no canonical wrong answer.
test_harness:arith_misconception(db_row(39820), fraction, too_vague,
    skip, none, none).

% === row 39852: 1/6 + 1/5 = 1/11 (add denominators only) ===
% Task: 1/6 + 1/5.
% Correct: frac(11,30).
% Error: frac(1,11) — numerator kept, denominators summed.
% SCHEMA: Arithmetic is Object Collection — denom-only addition
% GROUNDED: TODO — add_grounded with LCM
% CONNECTS TO: s(comp_nec(unlicensed(add_denominators_only)))
r39852_add_denom_only(frac(N,D1)-frac(N,D2), frac(N, Den)) :-
    Den is D1 + D2.

test_harness:arith_misconception(db_row(39852), fraction, add_denominators_only,
    misconceptions_fraction_batch_5:r39852_add_denom_only,
    frac(1,6)-frac(1,5),
    frac(11,30)).

% === row 39892: 3/6 + 1/6 = 4/12 (equal denominators, still add both) ===
% Task: 3/6 + 1/6.
% Correct: frac(4,6).
% Error: frac(4,12) — adds denominators too despite equality.
% SCHEMA: Arithmetic is Object Collection — componentwise addition
% GROUNDED: TODO — add_grounded (same-denom)
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_addition_same_denom)))
r39892_componentwise_same_denom(frac(N1,D)-frac(N2,D), frac(Num, Den)) :-
    Num is N1 + N2,
    Den is D + D.

test_harness:arith_misconception(db_row(39892), fraction, componentwise_same_denom,
    misconceptions_fraction_batch_5:r39892_componentwise_same_denom,
    frac(3,6)-frac(1,6),
    frac(4,6)).

% === row 39950: different denominators → unrelated fractions ===
% Conceptual refusal, not a numeric rule.
test_harness:arith_misconception(db_row(39950), fraction, too_vague,
    skip, none, none).

% === row 40072: PST conflations reproducing the whole ===
% Multiple distinct errors described; no single canonical transformation.
test_harness:arith_misconception(db_row(40072), fraction, too_vague,
    skip, none, none).

% === row 40085: how-many for how-much (4 pizzas / 5 people) ===
% Task: 4 pizzas among 5 people — how much per person.
% Correct: frac(4,5).
% Error: 4 (answers "how many pieces" — counts pieces).
% SCHEMA: Measuring Stick — count-for-proportion substitution
% GROUNDED: TODO — divide_grounded as rate
% CONNECTS TO: s(comp_nec(unlicensed(count_for_proportion)))
r40085_count_for_proportion(Items-_People, Items).

test_harness:arith_misconception(db_row(40085), fraction, count_for_proportion,
    misconceptions_fraction_batch_5:r40085_count_for_proportion,
    4-5,
    frac(4,5)).

% === row 40113: referent-whole language — 4/20 for 4 pizzas among 5 ===
% Task: what fraction of a pizza — 4/5. Student wrote 4/20 (of all pizzas).
% Correct: frac(4,5).
% Error: frac(4, Items*People) treating "of a" as "of all".
% SCHEMA: Measuring Stick — referent whole displaced to aggregate
% GROUNDED: TODO — rate_grounded with correct referent
% CONNECTS TO: s(comp_nec(unlicensed(referent_whole_aggregate)))
r40113_referent_whole_aggregate(Items-People, frac(Items, Total)) :-
    Total is Items * People.

test_harness:arith_misconception(db_row(40113), fraction, referent_whole_aggregate,
    misconceptions_fraction_batch_5:r40113_referent_whole_aggregate,
    4-5,
    frac(4,5)).

% === row 40123: PST gap thinking — 8/9 = 12/13 ===
% Task: compare 8/9 and 12/13.
% Correct: second_greater.
% Error: equal — both one piece from whole.
% SCHEMA: Measuring Stick — gap thinking (same as 38068)
% GROUNDED: TODO — compare_grounded
% CONNECTS TO: s(comp_nec(unlicensed(gap_thinking_pst)))
r40123_gap_thinking_pst(frac(N1,D1)-frac(N2,D2), Result) :-
    G1 is D1 - N1,
    G2 is D2 - N2,
    ( G1 =:= G2 -> Result = equal
    ; G1 < G2 -> Result = first_greater
    ; Result = second_greater ).

test_harness:arith_misconception(db_row(40123), fraction, gap_thinking_pst,
    misconceptions_fraction_batch_5:r40123_gap_thinking_pst,
    frac(8,9)-frac(12,13),
    second_greater).

% === row 40136: child writes "three plus four" for 3/4 ===
% Notational, not arithmetic.
test_harness:arith_misconception(db_row(40136), fraction, too_vague,
    skip, none, none).

% === row 40149: partitive/measurement model confusion ===
% Multiple interpretations yield the correct numeric answer.
test_harness:arith_misconception(db_row(40149), fraction, too_vague,
    skip, none, none).

% === row 40187: unequal parts treated as equal shares ===
% Geometric/partition issue with no numeric rule.
test_harness:arith_misconception(db_row(40187), fraction, too_vague,
    skip, none, none).

% === row 40197: smaller denominator = larger (ignoring numerator) ===
% Task: compare 5/6 and 6/7.
% Correct: second_greater.
% Error: first_greater — "6-piece block has larger pieces".
% SCHEMA: Measuring Stick — denom-only size reasoning
% GROUNDED: TODO — compare_grounded with numerator
% CONNECTS TO: s(comp_nec(unlicensed(smaller_denom_larger_fraction)))
r40197_smaller_denom_larger(frac(_,D1)-frac(_,D2), Result) :-
    ( D1 =:= D2 -> Result = equal
    ; D1 < D2 -> Result = first_greater
    ; Result = second_greater ).

test_harness:arith_misconception(db_row(40197), fraction, smaller_denom_larger_fraction,
    misconceptions_fraction_batch_5:r40197_smaller_denom_larger,
    frac(5,6)-frac(6,7),
    second_greater).

% === row 40230: 2/3 × 3/5 = 5/8 (add both in multiplication) ===
% Task: 2/3 × 3/5.
% Correct: frac(6,15).
% Error: frac(5,8) — componentwise addition applied to multiplication.
% SCHEMA: Arithmetic is Object Collection — operation substitution
% GROUNDED: TODO — multiply_grounded
% CONNECTS TO: s(comp_nec(unlicensed(add_for_multiply_components)))
r40230_add_for_multiply(frac(N1,D1)-frac(N2,D2), frac(Num, Den)) :-
    Num is N1 + N2,
    Den is D1 + D2.

test_harness:arith_misconception(db_row(40230), fraction, add_for_multiply_components,
    misconceptions_fraction_batch_5:r40230_add_for_multiply,
    frac(2,3)-frac(3,5),
    frac(6,15)).

% === row 40258: misinterpreting remainder in fraction division ===
% Adult pedagogical; no single numeric rule.
test_harness:arith_misconception(db_row(40258), fraction, too_vague,
    skip, none, none).

% === row 40319: 18/19 > 15/16 because N+D larger ===
% Student's comparison answer matches the correct comparison (18/19 > 15/16),
% so this rule has no distinct wrong output on this example.
test_harness:arith_misconception(db_row(40319), fraction, too_vague,
    skip, none, none).

% === row 40372: whole × improper fraction conflation ===
% Complex unit-coordination described without a single wrong numeric output.
test_harness:arith_misconception(db_row(40372), fraction, too_vague,
    skip, none, none).

% === row 40404: 8/9 > 5/6 because both larger ===
% Student's answer is correct numerically (8/9 > 5/6); no distinct wrong output.
test_harness:arith_misconception(db_row(40404), fraction, too_vague,
    skip, none, none).

% === row 40444: mechanical cross-multiplication ===
% No wrong numeric answer given — just an algorithmic preference.
test_harness:arith_misconception(db_row(40444), fraction, too_vague,
    skip, none, none).

% === row 40455: estimate sum by adding numerators only ===
% Task: estimate sum of two fractions (example gives 6+4=10).
% Correct depends on denominators. Without concrete denominators, no
% canonical correct value exists; use plausible frac(1,2)+frac(1,3)=frac(5,6)
% against student integer-output rule.
% SCHEMA: Arithmetic is Object Collection — numerators as standalone terms
% GROUNDED: TODO — add_grounded
% CONNECTS TO: s(comp_nec(unlicensed(numerator_only_addition)))
r40455_numerator_only_sum(frac(N1,_)-frac(N2,_), Sum) :-
    Sum is N1 + N2.

test_harness:arith_misconception(db_row(40455), fraction, numerator_only_addition,
    misconceptions_fraction_batch_5:r40455_numerator_only_sum,
    frac(6,7)-frac(4,9),
    frac(82,63)).

% === row 40483: fraction as part-over-remaining ===
% Task: 1 colored part, 6 uncolored → fraction colored.
% Correct: frac(1,7) (1 of 7 total).
% Error: frac(1,6) — uses remaining pieces as denom.
% SCHEMA: Container — part-to-remainder ratio instead of part-to-whole
% GROUNDED: TODO — ratio_grounded
% CONNECTS TO: s(comp_nec(unlicensed(part_over_remaining)))
r40483_part_over_remaining(Part-Total, frac(Part, Rem)) :-
    Rem is Total - Part.

test_harness:arith_misconception(db_row(40483), fraction, part_over_remaining,
    misconceptions_fraction_batch_5:r40483_part_over_remaining,
    1-7,
    frac(1,7)).

% === row 40499: density denial → bisection only ===
% Offers bisections (5.5, 5.25) — strategy description, not a fixed wrong rule.
test_harness:arith_misconception(db_row(40499), fraction, too_vague,
    skip, none, none).

% === row 40588: 31 × 17/31 — multiply first instead of recognizing inverse ===
% Task: 31 × 17/31.
% Correct: 17 (31 × 1/31 = 1).
% Error: computes 31 × 17 = 527 first (frac(527, 31)).
% SCHEMA: Measuring Stick — inverse not recognized
% GROUNDED: TODO — multiply_grounded with inverse detection
% CONNECTS TO: s(comp_nec(unlicensed(inverse_not_recognized)))
r40588_inverse_not_recognized(Whole-frac(N,D), frac(Num, D)) :-
    integer(Whole),
    Num is Whole * N.

test_harness:arith_misconception(db_row(40588), fraction, inverse_not_recognized,
    misconceptions_fraction_batch_5:r40588_inverse_not_recognized,
    31-frac(17,31),
    17).

% === row 40662: 5/5 + 1/5 called six sixths ===
% Task: add 5/5 and 1/5.
% Correct: frac(6,5).
% Error: frac(6,6) — denom redefined to total piece count.
% SCHEMA: Container — whole stretches as pieces accumulate
% GROUNDED: TODO — add_grounded preserving denom
% CONNECTS TO: s(comp_nec(unlicensed(denom_follows_piece_count)))
r40662_denom_follows_piece_count(frac(N1,D)-frac(N2,D), frac(Sum, Sum)) :-
    Sum is N1 + N2.

test_harness:arith_misconception(db_row(40662), fraction, denom_follows_piece_count,
    misconceptions_fraction_batch_5:r40662_denom_follows_piece_count,
    frac(5,5)-frac(1,5),
    frac(6,5)).
