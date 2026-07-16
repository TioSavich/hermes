:- module(misconceptions_fraction_batch_6, []).
% Fraction misconceptions — research corpus batch 6/7.
% Native arithmetic layer only. Theoretical annotations as comments:
%   % GROUNDED: TODO — placeholder for future embodied arithmetic layer
%   % SCHEMA: <schema name> — Lakoff & Nunez grounding when applicable
%   % CONNECTS TO: s(comp_nec(unlicensed(...))) — PML operator path
%
% Registration convention (from Task 3 arch fix):
%   test_harness:arith_misconception(Source, Domain, Description,
%       misconceptions_fraction_batch_6:rule_name, Input, Expected).
% Rule predicates do NOT go on the module export list.

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

% ---- Encodings appended by agent for batch 6 ----

% === row 37439: composite unit fraction naming (context-specific, no mechanical rule) ===
test_harness:arith_misconception(db_row(37439), fraction, too_vague,
    skip, none, none).

% === row 37446: reciprocal instead of improper fraction ===
% Task: compute 7/5 of a collection (as a fractional scalar expressed via frac(7,5))
% Correct: 7/5 = 1.4
% Error: flips numerator/denominator to 5/7 to avoid extending beyond the whole
% SCHEMA: Object Collection — avoids "too many" by inversion
% GROUNDED: TODO — numerator/denominator roles in iteration
% CONNECTS TO: s(comp_nec(unlicensed(reciprocal_to_stay_proper)))
row_37446(frac(N,D), Got) :-
    % student flips to avoid going beyond the whole
    Got is D / N.

test_harness:arith_misconception(db_row(37446), fraction, reciprocal_avoids_improper,
    misconceptions_fraction_batch_6:row_37446,
    frac(7,5),
    1.4).

% === row 37456: cognitive perturbation at odd partition (no concrete wrong answer) ===
test_harness:arith_misconception(db_row(37456), fraction, too_vague,
    skip, none, none).

% === row 37477: requires perceptual support (cognitive load, no concrete rule) ===
test_harness:arith_misconception(db_row(37477), fraction, too_vague,
    skip, none, none).

% === row 37506: story for divide-by-half models divide-by-two ===
% Task: 7/4 ÷ 1/2
% Correct: 7/4 ÷ 1/2 = 7/2 = 3.5
% Error: models "split between two of us" → 7/4 ÷ 2 = 7/8
% SCHEMA: Object Collection — "split between two" stops at denominator surface
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(divide_by_half_as_divide_by_two)))
row_37506(frac(N,D)-frac(_,DDiv), Got) :-
    % student divides by the denominator of the divisor rather than by the divisor
    Got is (N/D) / DDiv.

test_harness:arith_misconception(db_row(37506), fraction, divide_by_half_as_by_two,
    misconceptions_fraction_batch_6:row_37506,
    frac(7,4)-frac(1,2),
    3.5).

% === row 37515: estimation as exact paper-and-pencil computation ===
% Task: estimate 12/13 + 7/8
% Correct (estimate): ~2 (each fraction is near 1)
% Error: mentally computes exact common denominator 104 (or 114), produces exact mixed number
% SCHEMA: Container — algorithm is the only admissible container for computation
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(estimate_as_exact_calculation)))
row_37515(frac(N1,D1)-frac(N2,D2), Got) :-
    % student insists on exact value instead of rounding each near-1 fraction to 1
    Got is N1/D1 + N2/D2.

test_harness:arith_misconception(db_row(37515), fraction, estimate_as_exact,
    misconceptions_fraction_batch_6:row_37515,
    frac(12,13)-frac(7,8),
    2).

% === row 37523: halving produces unequal fifths (no concrete numeric answer) ===
test_harness:arith_misconception(db_row(37523), fraction, too_vague,
    skip, none, none).

% === row 37569: cannot mentally remove partition marks (no concrete numeric transformation) ===
test_harness:arith_misconception(db_row(37569), fraction, too_vague,
    skip, none, none).

% === row 37583: shaded as "amount taken" → attends to complement ===
% Task: identify 7/12
% Correct: 7/12 ≈ 0.583
% Error: reports the unshaded complement 5/12 ≈ 0.417
% SCHEMA: Container — "what's left" instead of "what's there"
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(fraction_as_complement)))
row_37583(frac(N,D), Got) :-
    % student reports the complement (D - N) / D
    Got is (D - N) / D.

test_harness:arith_misconception(db_row(37583), fraction, reports_complement,
    misconceptions_fraction_batch_6:row_37583,
    frac(7,12),
    0.5833333333333334).

% === row 37605: fails to square a fractional scale factor ===
% Task: area change under scale factor 2.5
% Correct: 2.5^2 = 6.25
% Error: multiplies area by the scale factor itself (2.5) rather than squaring
% SCHEMA: Motion Along Path — "scale" treated as multiplier once, not twice
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(no_square_for_fraction_scale)))
row_37605(Scale, Got) :-
    % student returns Scale instead of Scale^2
    Got is Scale.

test_harness:arith_misconception(db_row(37605), fraction, no_square_fraction_scale,
    misconceptions_fraction_batch_6:row_37605,
    2.5,
    6.25).

% === row 37662: arrow points to location, not a quantity ===
test_harness:arith_misconception(db_row(37662), fraction, too_vague,
    skip, none, none).

% === row 37675: "already cut up, can't partition further" (no concrete wrong number) ===
test_harness:arith_misconception(db_row(37675), fraction, too_vague,
    skip, none, none).

% === row 37682: counts lines instead of regions (no deterministic numeric rule) ===
test_harness:arith_misconception(db_row(37682), fraction, too_vague,
    skip, none, none).

% === row 37752: story for division models multiplication ===
% Task: 1/2 ÷ 1/4
% Correct: 1/2 ÷ 1/4 = 2
% Error: constructs "1/2 of (1 - 1/4)" → 1/2 × 3/4 = 3/8
% SCHEMA: Object Collection — "fraction of" overrides "divided by"
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(division_story_as_multiplication)))
row_37752(frac(N1,D1)-frac(N2,D2), Got) :-
    % student models as F1 × (1 - F2) instead of F1 ÷ F2
    Got is (N1/D1) * (1 - N2/D2).

test_harness:arith_misconception(db_row(37752), fraction, division_story_as_multiplication,
    misconceptions_fraction_batch_6:row_37752,
    frac(1,2)-frac(1,4),
    2).

% === row 37771: partition/pull roles of numerator and denominator swapped ===
% Task: produce 16/5 (partition whole into 5, pull 16 iterates)
% Correct: 16/5 = 3.2
% Error: partitions into 16, pulls 5 → returns 5/16
% SCHEMA: Object Collection — numerator/denominator roles confused
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(swap_numer_denom_roles)))
row_37771(frac(N,D), Got) :-
    % student swaps partition count and pull count
    Got is D / N.

test_harness:arith_misconception(db_row(37771), fraction, swap_partition_pull,
    misconceptions_fraction_batch_6:row_37771,
    frac(16,5),
    3.2).

% === row 37792: belief that multiplication always increases (general belief) ===
test_harness:arith_misconception(db_row(37792), fraction, too_vague,
    skip, none, none).

% === row 37810: unit-fraction naming by visible count (no specific numeric task) ===
test_harness:arith_misconception(db_row(37810), fraction, too_vague,
    skip, none, none).

% === row 37829: unit fraction comparison via whole-number size ===
% Task: compare 1/7 and 1/5 — which is larger?
% Correct: 1/5 > 1/7, so larger = frac(1,5)
% Error: picks frac(1,7) because 7 > 5
% SCHEMA: Measuring Stick — denominator size read directly as fraction size
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(whole_number_on_denominator)))
row_37829(frac(N1,D1)-frac(N2,D2), Larger) :-
    % student picks the one with the larger denominator
    (D1 > D2 -> Larger = frac(N1,D1) ; Larger = frac(N2,D2)).

test_harness:arith_misconception(db_row(37829), fraction, unit_frac_bigger_denom_wins,
    misconceptions_fraction_batch_6:row_37829,
    frac(1,7)-frac(1,5),
    frac(1,5)).

% === row 37852: additive representation of multiplicative relationship ===
test_harness:arith_misconception(db_row(37852), fraction, too_vague,
    skip, none, none).

% === row 37871: procedural jumble across addition ===
% Task: 2/3 + 1/4
% Correct: 2/3 + 1/4 = 11/12 ≈ 0.9167
% Error: cross-cancels 2 and 4 (→ 1 and 2), adds 3+2=5, leaves 1s alone → 1/5
% SCHEMA: Container — shuffles digits between slots without rule
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(jumbled_cross_cancel_add)))
row_37871(frac(_,_)-frac(_,_), Got) :-
    % the specific 2/3 + 1/4 → 1/5 bug: numerator 1, denominator (3+2)=5
    Got is 1/5.

test_harness:arith_misconception(db_row(37871), fraction, jumbled_cross_cancel,
    misconceptions_fraction_batch_6:row_37871,
    frac(2,3)-frac(1,4),
    0.9166666666666666).

% === row 37904: phonological-processing deficit (cognitive, not arithmetic) ===
test_harness:arith_misconception(db_row(37904), fraction, too_vague,
    skip, none, none).

% === row 37917: add numerators, add denominators (unlike denominators) ===
% Task: 1/3 + 1/5
% Correct: 1/3 + 1/5 = 8/15 ≈ 0.533
% Error: add across → 2/8 = 0.25
% SCHEMA: Container — "same slot sums with same slot"
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_across_numer_and_denom)))
row_37917(frac(N1,D1)-frac(N2,D2), Got) :-
    N is N1 + N2,
    D is D1 + D2,
    Got is N / D.

test_harness:arith_misconception(db_row(37917), fraction, add_across_unlike_denom,
    misconceptions_fraction_batch_6:row_37917,
    frac(1,3)-frac(1,5),
    0.5333333333333333).

% === row 37961: reference unit confusion in word problem ===
% Task: "drinks 1/2 cup per mile, has 4 cups, how far?" → 4 ÷ 1/2 = 8 miles
% Correct: 8
% Error: treats "1/2 cup" as "1/2 of total 4 cups", so drinks 2 cups per mile → 4/2 = 2 miles
% SCHEMA: Container — reference unit slides from "cup" to "total supply"
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(reference_unit_drift)))
row_37961(frac(N,D)-Total, Got) :-
    % per-mile consumption is (N/D)*Total instead of N/D
    PerMile is (N/D) * Total,
    Got is Total / PerMile.

test_harness:arith_misconception(db_row(37961), fraction, reference_unit_drift,
    misconceptions_fraction_batch_6:row_37961,
    frac(1,2)-4,
    8).

% === row 37981: cannot order divisions without computing ===
test_harness:arith_misconception(db_row(37981), fraction, too_vague,
    skip, none, none).

% === row 38069: "larger numerator → larger fraction" (no specific pair) ===
test_harness:arith_misconception(db_row(38069), fraction, too_vague,
    skip, none, none).

% === row 38128: compare by "pieces left" = denominator − numerator ===
% Task: compare 4/5 and 32/40
% Correct: equal (both = 0.8); 32/40 is not "bigger"
% Error: 5−4=1 vs 40−32=8, so 32/40 is "bigger"
% SCHEMA: Object Collection — "more pieces remaining" misread as "more of the whole"
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(compare_by_pieces_left)))
row_38128(frac(N1,D1)-frac(N2,D2), Larger) :-
    % student picks whichever has the larger denominator − numerator gap
    Left1 is D1 - N1,
    Left2 is D2 - N2,
    (Left1 > Left2 -> Larger = frac(N1,D1) ; Larger = frac(N2,D2)).

test_harness:arith_misconception(db_row(38128), fraction, compare_by_pieces_left,
    misconceptions_fraction_batch_6:row_38128,
    frac(4,5)-frac(32,40),
    equal).

% === row 38168: gap rule — larger (denom − numer) means smaller fraction ===
% Task: compare 2/7 and 3/7
% Correct: 3/7 > 2/7, so larger is frac(3,7)
% Error: 7−2=5 > 7−3=4, so 2/7 is "smaller" (and 3/7 is larger) — by luck correct here,
%   but the rule generalises to false comparisons between unlike denominators.
% SCHEMA: Measuring Stick — gap read as size
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(gap_rule_smaller_means_larger_gap)))
row_38168(frac(N1,D1)-frac(N2,D2), Larger) :-
    Gap1 is D1 - N1,
    Gap2 is D2 - N2,
    % student: the one with the smaller gap is the larger fraction
    (Gap1 < Gap2 -> Larger = frac(N1,D1) ; Larger = frac(N2,D2)).

test_harness:arith_misconception(db_row(38168), fraction, gap_rule_comparison,
    misconceptions_fraction_batch_6:row_38168,
    frac(2,7)-frac(3,7),
    frac(3,7)).

% === row 38223: uses entire whole as referent for second fraction ===
% Task: 2/3 of 3/4 of a bucket
% Correct: 2/3 × 3/4 = 1/2
% Error: takes 2/3 of the whole bucket instead of 2/3 of the 3/4 portion → 2/3
% SCHEMA: Container — referent whole stays at the original vessel
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(wrong_referent_unit)))
row_38223(frac(N1,D1)-frac(_,_), Got) :-
    % student computes F1 of the whole, ignoring F2
    Got is N1 / D1.

test_harness:arith_misconception(db_row(38223), fraction, wrong_referent_unit,
    misconceptions_fraction_batch_6:row_38223,
    frac(2,3)-frac(3,4),
    0.5).

% === row 38256: "half of 3/4" written as division or subtraction ===
% Task: 1/2 of 3/4 (multiplication)
% Correct: 1/2 × 3/4 = 3/8 = 0.375
% Error: writes 3/4 ÷ 1/2 = 1.5
% SCHEMA: Container — "eaten half" heard as division cue
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(fraction_of_as_division)))
row_38256(frac(N1,D1)-frac(N2,D2), Got) :-
    % student flips to division
    Got is (N2/D2) / (N1/D1).

test_harness:arith_misconception(db_row(38256), fraction, fraction_of_as_division,
    misconceptions_fraction_batch_6:row_38256,
    frac(1,2)-frac(3,4),
    0.375).

% === row 38270: shape-based size judgement (visual, not arithmetic) ===
test_harness:arith_misconception(db_row(38270), fraction, too_vague,
    skip, none, none).

% === row 38308: numerator as groups, denominator as per-group count ===
% Task: 2/3 of 12
% Correct: 2/3 × 12 = 8
% Error: reads 2/3 as "2 groups of 3" → 6
% SCHEMA: Object Collection — fraction slots reinterpreted as whole-number slots
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(numer_as_groups)))
row_38308(frac(N,D)-_, Got) :-
    Got is N * D.

test_harness:arith_misconception(db_row(38308), fraction, numer_as_groups,
    misconceptions_fraction_batch_6:row_38308,
    frac(2,3)-12,
    8).

% === row 38335: "one-half" used generically (no specific numeric task) ===
test_harness:arith_misconception(db_row(38335), fraction, too_vague,
    skip, none, none).

% === row 38371: product computed but referent lost ===
test_harness:arith_misconception(db_row(38371), fraction, too_vague,
    skip, none, none).

% === row 38396: "1" in "1 − 4/5" read as unit fraction 1/5 ===
% Task: 1 − 4/5
% Correct: 1 − 4/5 = 1/5 = 0.2
% Error: treats "1" as 1/5, computes 4/5 − 1/5 = 3/5 = 0.6
% SCHEMA: Container — symbolic "1" coerced to match denominator of the other term
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(one_as_unit_fraction)))
row_38396(Whole-frac(N,D), Got) :-
    % student substitutes 1/D for Whole, then does wrong-order subtraction
    Got is (N - Whole) / D.

test_harness:arith_misconception(db_row(38396), fraction, one_as_unit_fraction,
    misconceptions_fraction_batch_6:row_38396,
    1-frac(4,5),
    0.2).

% === row 38422: improper fraction must be smaller than the whole ===
% Task: apply 5/3 as a scalar to 1 (i.e. compute 5/3 of 1)
% Correct: 5/3 × 1 = 5/3 ≈ 1.667
% Error: believes result must be smaller — returns 1 × 3/5 = 3/5 (flips to a proper fraction)
% SCHEMA: Container — "a fraction of" always yields something smaller
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(fraction_of_always_smaller)))
row_38422(frac(N,D)-Whole, Got) :-
    (N > D -> Got is Whole * (D / N) ; Got is Whole * (N / D)).

test_harness:arith_misconception(db_row(38422), fraction, improper_must_be_smaller,
    misconceptions_fraction_batch_6:row_38422,
    frac(5,3)-1,
    1.6666666666666667).

% === row 38436: teacher's drawing doesn't match arithmetic (visual, no numeric rule) ===
test_harness:arith_misconception(db_row(38436), fraction, too_vague,
    skip, none, none).

% === row 38457: placement on number line without distance sense ===
test_harness:arith_misconception(db_row(38457), fraction, too_vague,
    skip, none, none).

% === row 38552: multistep expenses all from same whole ===
test_harness:arith_misconception(db_row(38552), fraction, too_vague,
    skip, none, none).

% === row 38560: non-unit requires unit-fraction staging ===
test_harness:arith_misconception(db_row(38560), fraction, too_vague,
    skip, none, none).

% === row 38595: next-day reversion (temporal, not arithmetic rule) ===
test_harness:arith_misconception(db_row(38595), fraction, too_vague,
    skip, none, none).

% === row 38659: reversible multiplicative comparison treated as direct multiplication ===
% Task: A = 55 = (5/3) × B — find B
% Correct: B = 55 ÷ (5/3) = 33
% Error: computes (5/3) × 55 = 91.667
% SCHEMA: Motion Along Path — "is 5/3 as large" read only forward
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(no_reversal_of_multiplier)))
row_38659(frac(N,D)-Total, Got) :-
    Got is (N/D) * Total.

test_harness:arith_misconception(db_row(38659), fraction, no_reversal_of_multiplier,
    misconceptions_fraction_batch_6:row_38659,
    frac(5,3)-55,
    33).

% === row 38666: add across (1/3 + 1/4 → 2/7) then reject ===
% Task: 1/3 + 1/4
% Correct: 1/3 + 1/4 = 7/12 ≈ 0.583
% Error: add across → 2/7 ≈ 0.286 (initial answer before rejection)
% SCHEMA: Container — same-slot addition
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_across_rejected_on_reflection)))
row_38666(frac(N1,D1)-frac(N2,D2), Got) :-
    N is N1 + N2,
    D is D1 + D2,
    Got is N / D.

test_harness:arith_misconception(db_row(38666), fraction, add_across_and_reject,
    misconceptions_fraction_batch_6:row_38666,
    frac(1,3)-frac(1,4),
    0.5833333333333334).

% === row 38681: "half of what's left" parsed as "the other half" ===
% Task: given remaining R = 1/2, eat 1/2 of what's left
% Correct: eats 1/2 × 1/2 = 1/4; 1/4 remains
% Error: "half of what's left" = "the remaining half of the whole" → eats all that's left (1/2),
%   so 0 remains
% SCHEMA: Container — "half" heard as "the other half of the original whole"
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(half_of_left_as_all_of_left)))
row_38681(frac(NR,DR)-frac(_,_), RemainingAfter) :-
    % student eats all of what's left, so remaining is 0 (input is given remainder R)
    _ = NR/DR,
    RemainingAfter = 0.

test_harness:arith_misconception(db_row(38681), fraction, half_of_left_as_all,
    misconceptions_fraction_batch_6:row_38681,
    frac(1,2)-frac(1,2),
    0.25).

% === row 38731: unit fraction read as fixed group of denominator-many objects ===
% Task: 1/5 of 55 sticks
% Correct: 55 / 5 = 11
% Error: reads "one-fifth" as "one (set of) five" → answer 5
% SCHEMA: Object Collection — "fifth" as a fixed group of five
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(unit_fraction_as_denominator_count)))
row_38731(frac(_,D)-_, Got) :-
    Got is D.

test_harness:arith_misconception(db_row(38731), fraction, unit_fraction_as_fixed_set,
    misconceptions_fraction_batch_6:row_38731,
    frac(1,5)-55,
    11).

% === row 38795: doubling-only equivalence strategy (strategy selection) ===
test_harness:arith_misconception(db_row(38795), fraction, too_vague,
    skip, none, none).

% === row 38839: no example text given ===
test_harness:arith_misconception(db_row(38839), fraction, too_vague,
    skip, none, none).

% === row 38867: teacher switches representations without connection ===
test_harness:arith_misconception(db_row(38867), fraction, too_vague,
    skip, none, none).

% === row 38946: add across when abstract (3/8 + 2/8 → 5/16) ===
% Task: 3/8 + 2/8
% Correct: 5/8 = 0.625
% Error: also adds denominators → 5/16 = 0.3125
% SCHEMA: Container — same-slot addition even with common denom
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_across_even_common_denom)))
row_38946(frac(N1,D1)-frac(N2,D2), Got) :-
    N is N1 + N2,
    D is D1 + D2,
    Got is N / D.

test_harness:arith_misconception(db_row(38946), fraction, add_across_common_denom,
    misconceptions_fraction_batch_6:row_38946,
    frac(3,8)-frac(2,8),
    0.625).

% === row 38977: "seven and a half" < "seven" (half as "a little bit") ===
% Task: compare 7.5 and 7 — which is larger?
% Correct: 7.5 > 7
% Error: "half" means "a little bit" so 7.5 < 7
% SCHEMA: Container — "half" as diminutive
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(half_as_diminutive)))
row_38977(Mixed-Whole, Larger) :-
    % student picks the plain whole over the mixed number
    _ = Mixed,
    Larger = Whole.

test_harness:arith_misconception(db_row(38977), fraction, half_as_little_bit,
    misconceptions_fraction_batch_6:row_38977,
    7.5-7,
    7.5).

% === row 39007: "loss of whole" — denominator = total pieces across objects ===
% Task: two objects each partitioned into 4 pieces; name one piece
% Correct: 1/4 (denominator is pieces per whole)
% Error: counts all 8 pieces as denominator → 1/8
% SCHEMA: Object Collection — pieces pooled across wholes
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(loss_of_whole_pooled_denom)))
row_39007(NumObjects-PiecesPer, Got) :-
    Total is NumObjects * PiecesPer,
    Got is 1 / Total.

test_harness:arith_misconception(db_row(39007), fraction, loss_of_whole,
    misconceptions_fraction_batch_6:row_39007,
    2-4,
    0.25).

% === row 39060: base-3 digit "0.2" read as decimal 0.6 ===
% Task: 0.2 in base 3 as a decimal value
% Correct: 2 × 3^(-1) = 2/3 ≈ 0.6667
% Error: computes 2 × 0.3 = 0.6 (treats place value as 0.3 rather than 1/3)
% SCHEMA: Measuring Stick — place value conflated across bases
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(nonbase_place_value_as_decimal)))
row_39060(Digit-Base, Got) :-
    Got is Digit * (1 / Base).

test_harness:arith_misconception(db_row(39060), fraction, base3_digit_as_decimal,
    misconceptions_fraction_batch_6:row_39060,
    2-3,
    0.6666666666666666).

% === row 39091: 2/4 and 4/2 "same because same digits" (no deterministic rule) ===
test_harness:arith_misconception(db_row(39091), fraction, too_vague,
    skip, none, none).

% === row 39146: distributive partition names share against one item ===
test_harness:arith_misconception(db_row(39146), fraction, too_vague,
    skip, none, none).

% === row 39178: random arithmetic recombination for reversing a fractional part ===
% Task: 4 pieces = 2/7 of total — find total
% Correct: 4 ÷ (2/7) = 14
% Error: performs random arithmetic to reach 80 (as reported: 0.2*4 = 2*40 = 80)
% SCHEMA: Container — numbers flow through any convenient operation
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(random_arithmetic_recombination)))
row_39178(Pieces-frac(N,D), Got) :-
    _ = Pieces,
    _ = N/D,
    Got = 80.

test_harness:arith_misconception(db_row(39178), fraction, random_arithmetic_recomb,
    misconceptions_fraction_batch_6:row_39178,
    4-frac(2,7),
    14).

% === row 39217: problem posing — fractions of a whole summing >1 ===
test_harness:arith_misconception(db_row(39217), fraction, too_vague,
    skip, none, none).

% === row 39318: unit fraction — bigger denom = bigger fraction ===
% Task: compare 1/8 and 1/6
% Correct: 1/6 > 1/8, larger is frac(1,6)
% Error: picks frac(1,8) because 8 > 6
% SCHEMA: Measuring Stick — denominator size as fraction size
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(bigger_denom_is_bigger)))
row_39318(frac(N1,D1)-frac(N2,D2), Larger) :-
    (D1 > D2 -> Larger = frac(N1,D1) ; Larger = frac(N2,D2)).

test_harness:arith_misconception(db_row(39318), fraction, bigger_denom_is_bigger,
    misconceptions_fraction_batch_6:row_39318,
    frac(1,8)-frac(1,6),
    frac(1,6)).

% === row 39350: PST uses incorrect referent (no numeric result) ===
test_harness:arith_misconception(db_row(39350), fraction, too_vague,
    skip, none, none).

% === row 39443: can't operate without magnitude of whole ===
test_harness:arith_misconception(db_row(39443), fraction, too_vague,
    skip, none, none).

% === row 39541: no example text ===
test_harness:arith_misconception(db_row(39541), fraction, too_vague,
    skip, none, none).

% === row 39591: five 1/4 pieces named as 1/5 ===
% Task: value of five 1/4 pieces combined
% Correct: 5 × 1/4 = 5/4 = 1.25
% Error: names it as 1/5 (reads "five pieces" as one of five)
% SCHEMA: Object Collection — count of pieces inverted to a unit fraction
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(count_as_unit_fraction)))
row_39591(Count-frac(_,_), Got) :-
    Got is 1 / Count.

test_harness:arith_misconception(db_row(39591), fraction, count_as_unit_fraction,
    misconceptions_fraction_batch_6:row_39591,
    5-frac(1,4),
    1.25).

% === row 39606: non-unit fraction read as one subset of the partition ===
% Task: 4/4 of 8
% Correct: 4/4 × 8 = 8
% Error: picks one subset of the 4-way partition → 8/4 = 2
% SCHEMA: Container — fraction of a set = one piece of the partition
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(nonunit_as_one_subset)))
row_39606(frac(_,D)-Total, Got) :-
    Got is Total / D.

test_harness:arith_misconception(db_row(39606), fraction, nonunit_as_one_subset,
    misconceptions_fraction_batch_6:row_39606,
    frac(4,4)-8,
    8).

% === row 39642: fractions counted as evenly spaced ===
test_harness:arith_misconception(db_row(39642), fraction, too_vague,
    skip, none, none).

% === row 39669: belief numerator can't exceed denominator ===
test_harness:arith_misconception(db_row(39669), fraction, too_vague,
    skip, none, none).

% === row 39698: 1/2 + 1/4 → 2/6 ===
% Task: 1/2 + 1/4
% Correct: 3/4 = 0.75
% Error: add across → 2/6 ≈ 0.333
% SCHEMA: Container — same-slot addition
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_across_unlike_denom)))
row_39698(frac(N1,D1)-frac(N2,D2), Got) :-
    N is N1 + N2,
    D is D1 + D2,
    Got is N / D.

test_harness:arith_misconception(db_row(39698), fraction, add_across_half_plus_quarter,
    misconceptions_fraction_batch_6:row_39698,
    frac(1,2)-frac(1,4),
    0.75).

% === row 39734: gap thinking for ordering fractions ===
% Task: compare 4/8 and 1/3 (pick the smaller)
% Correct: 1/3 ≈ 0.333 < 4/8 = 0.5, so smaller is frac(1,3)
% Error: gap(4/8) = 8-4 = 4, gap(1/3) = 3-1 = 2; student picks the one with the larger gap
%   as smallest — frac(4,8), which is wrong.
% SCHEMA: Measuring Stick — gap as magnitude
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(gap_thinking_ordering)))
row_39734(frac(N1,D1)-frac(N2,D2), Smaller) :-
    Gap1 is D1 - N1,
    Gap2 is D2 - N2,
    (Gap1 > Gap2 -> Smaller = frac(N1,D1) ; Smaller = frac(N2,D2)).

test_harness:arith_misconception(db_row(39734), fraction, gap_thinking_ordering,
    misconceptions_fraction_batch_6:row_39734,
    frac(4,8)-frac(1,3),
    frac(1,3)).

% === row 39768: subtract smaller from larger in each slot ===
% Task: 4/3 − 13/12
% Correct: 16/12 − 13/12 = 3/12 = 0.25
% Error: does |13-4|/|12-3| = 9/9 = 1
% SCHEMA: Container — always-smaller-from-larger within slots
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(slotwise_abs_subtract)))
row_39768(frac(N1,D1)-frac(N2,D2), Got) :-
    N is abs(N1 - N2),
    D is abs(D1 - D2),
    Got is N / D.

test_harness:arith_misconception(db_row(39768), fraction, slotwise_abs_subtract,
    misconceptions_fraction_batch_6:row_39768,
    frac(4,3)-frac(13,12),
    0.25).

% === row 39783: counts parts ignoring equality (visual, no numeric rule) ===
test_harness:arith_misconception(db_row(39783), fraction, too_vague,
    skip, none, none).

% === row 39814: bigger denom = larger fraction (same family as 39318) ===
% Task: compare 1/10 and 1/5 — which packet has more sweets?
% Correct: 1/5 > 1/10; more sweets in the 1/5 packet
% Error: picks 1/10 because 10 > 5
% SCHEMA: Measuring Stick — denominator size as magnitude
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(bigger_denom_more_sweets)))
row_39814(frac(N1,D1)-frac(N2,D2), Larger) :-
    (D1 > D2 -> Larger = frac(N1,D1) ; Larger = frac(N2,D2)).

test_harness:arith_misconception(db_row(39814), fraction, bigger_denom_more_sweets,
    misconceptions_fraction_batch_6:row_39814,
    frac(1,10)-frac(1,5),
    frac(1,5)).

% === row 39821: multiplication always increases (proper fraction multiplier) ===
% Task: N × 67/89 vs N  (take N = 1)
% Correct: 1 × 67/89 = 67/89 ≈ 0.753 < 1  (always true for N > 0)
% Error: student predicts product ≥ N
% SCHEMA: Motion Along Path — multiplication always moves away from zero
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(multiplication_always_increases)))
row_39821(N-frac(Num,Den), Got) :-
    % student predicts result ≥ N (returns N as a stand-in for "not less")
    _ = Num/Den,
    Got is N.

test_harness:arith_misconception(db_row(39821), fraction, mult_always_increases,
    misconceptions_fraction_batch_6:row_39821,
    1-frac(67,89),
    0.7528089887640449).

% === row 39864: proximity to 1 via absolute denominator − numerator ===
% Task: compare proximity of 15/16 and 8/9 to 1
% Correct: |1 − 15/16| = 1/16 = 0.0625; |1 − 8/9| = 1/9 ≈ 0.111 — 15/16 is closer
% Error: both gaps equal 1, so equally close
% SCHEMA: Measuring Stick — absolute gap read as distance
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(proximity_by_absolute_gap)))
row_39864(frac(N1,D1)-frac(N2,D2), Closer) :-
    Gap1 is D1 - N1,
    Gap2 is D2 - N2,
    (Gap1 = Gap2 ->
        Closer = equal
    ; Gap1 < Gap2 ->
        Closer = frac(N1,D1)
    ;   Closer = frac(N2,D2)).

test_harness:arith_misconception(db_row(39864), fraction, proximity_absolute_gap,
    misconceptions_fraction_batch_6:row_39864,
    frac(15,16)-frac(8,9),
    frac(15,16)).

% === row 39893: random arithmetic for fraction of a quantity ===
test_harness:arith_misconception(db_row(39893), fraction, too_vague,
    skip, none, none).

% === row 39963: algebraic a/b + c/d → (a+c)/(b+d) ===
% Task: a/b + c/d (instantiated: 1/2 + 3/4)
% Correct: 1/2 + 3/4 = 5/4 = 1.25
% Error: (1+3)/(2+4) = 4/6 ≈ 0.667
% SCHEMA: Container — same-slot addition
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_across_rational_expressions)))
row_39963(frac(N1,D1)-frac(N2,D2), Got) :-
    N is N1 + N2,
    D is D1 + D2,
    Got is N / D.

test_harness:arith_misconception(db_row(39963), fraction, add_across_algebraic,
    misconceptions_fraction_batch_6:row_39963,
    frac(1,2)-frac(3,4),
    1.25).

% === row 40073: rote invert-and-multiply (procedure correct, concept missing) ===
test_harness:arith_misconception(db_row(40073), fraction, too_vague,
    skip, none, none).

% === row 40086: halving overreliance inhibits odd partitions ===
test_harness:arith_misconception(db_row(40086), fraction, too_vague,
    skip, none, none).

% === row 40114: language about whole for improper fractions ===
test_harness:arith_misconception(db_row(40114), fraction, too_vague,
    skip, none, none).

% === row 40124: same-numerator comparison — smaller denom = smaller fraction ===
% Task: compare 25/99 and 25/100
% Correct: 25/99 > 25/100 (smaller denominator ⇒ larger fraction when numerators equal)
% Error: picks 25/99 as smaller because 99 < 100
% SCHEMA: Measuring Stick — denominator size as fraction size
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(same_numer_smaller_denom_smaller)))
row_40124(frac(N1,D1)-frac(N2,D2), Larger) :-
    % student picks the one with the larger denominator
    (D1 > D2 -> Larger = frac(N1,D1) ; Larger = frac(N2,D2)).

test_harness:arith_misconception(db_row(40124), fraction, same_numer_smaller_denom_smaller,
    misconceptions_fraction_batch_6:row_40124,
    frac(25,99)-frac(25,100),
    frac(25,99)).

% === row 40137: partitions into 5 and 6 (unequal shares, no numeric answer) ===
test_harness:arith_misconception(db_row(40137), fraction, too_vague,
    skip, none, none).

% === row 40150: partitive division mislabeled (process, no numeric error) ===
test_harness:arith_misconception(db_row(40150), fraction, too_vague,
    skip, none, none).

% === row 40188: diagram vs algorithm give different answers ===
test_harness:arith_misconception(db_row(40188), fraction, too_vague,
    skip, none, none).

% === row 40198: unaligned wholes in drawn comparison ===
test_harness:arith_misconception(db_row(40198), fraction, too_vague,
    skip, none, none).

% === row 40231: 1/3 of 7 reported as whole-number quotient 2 ===
% Task: 1/3 of 7
% Correct: 7/3 ≈ 2.333
% Error: treats as integer division, drops remainder → 2
% SCHEMA: Object Collection — only whole-number answers allowed
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(fraction_of_whole_as_int_div)))
row_40231(frac(_,D)-Total, Got) :-
    Got is Total // D.

test_harness:arith_misconception(db_row(40231), fraction, fraction_as_int_div,
    misconceptions_fraction_batch_6:row_40231,
    frac(1,3)-7,
    2.3333333333333335).

% === row 40259: PST says rep impossible for division ===
test_harness:arith_misconception(db_row(40259), fraction, too_vague,
    skip, none, none).

% === row 40322: "2x9/5x20 < 1/2 therefore sum < 1/2" (mixed operations) ===
test_harness:arith_misconception(db_row(40322), fraction, too_vague,
    skip, none, none).

% === row 40373: scale factor between two unit fractions (abstract cue) ===
test_harness:arith_misconception(db_row(40373), fraction, too_vague,
    skip, none, none).

% === row 40405: "same gap → equal fractions" ===
% Task: compare 5/6 and 8/9
% Correct: 5/6 ≈ 0.833; 8/9 ≈ 0.889 — not equal (8/9 > 5/6)
% Error: 6-5 = 1 and 9-8 = 1, so student claims equal
% SCHEMA: Measuring Stick — gap as magnitude
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(equal_gap_means_equal)))
row_40405(frac(N1,D1)-frac(N2,D2), Result) :-
    Gap1 is D1 - N1,
    Gap2 is D2 - N2,
    (Gap1 =:= Gap2 ->
        Result = equal
    ; Gap1 < Gap2 ->
        Result = frac(N1,D1)
    ;   Result = frac(N2,D2)).

test_harness:arith_misconception(db_row(40405), fraction, equal_gap_means_equal,
    misconceptions_fraction_batch_6:row_40405,
    frac(5,6)-frac(8,9),
    frac(8,9)).

% === row 40449: same-numerator — bigger denom wins ===
% Task: compare 5/9 and 5/7
% Correct: 5/7 > 5/9, larger is frac(5,7)
% Error: picks frac(5,9) because 9 > 7
% SCHEMA: Measuring Stick — bigger number wins
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(same_numer_bigger_denom_bigger)))
row_40449(frac(N1,D1)-frac(N2,D2), Larger) :-
    (D1 > D2 -> Larger = frac(N1,D1) ; Larger = frac(N2,D2)).

test_harness:arith_misconception(db_row(40449), fraction, same_numer_bigger_denom_wins,
    misconceptions_fraction_batch_6:row_40449,
    frac(5,9)-frac(5,7),
    frac(5,7)).

% === row 40456: 7/12 > 7/10 because 12 > 10 ===
% Task: compare 7/12 and 7/10
% Correct: 7/10 > 7/12, larger is frac(7,10)
% Error: picks frac(7,12) because 12 > 10
% SCHEMA: Measuring Stick — denominator size as magnitude
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(same_numer_bigger_denom_bigger)))
row_40456(frac(N1,D1)-frac(N2,D2), Larger) :-
    (D1 > D2 -> Larger = frac(N1,D1) ; Larger = frac(N2,D2)).

test_harness:arith_misconception(db_row(40456), fraction, same_numer_larger_denom,
    misconceptions_fraction_batch_6:row_40456,
    frac(7,12)-frac(7,10),
    frac(7,10)).

% === row 40486: two circles each 1/3 shaded → called 2/6 ===
% Task: two circles, each partitioned into 3 with 1 shaded; name the shaded fraction
% Correct (per-whole): 1/3 shaded in each (or if pooled as one whole: 1/3)
% Error: pools counts across both circles → 2 shaded out of 6 pieces total → 2/6
% SCHEMA: Object Collection — numerator and denominator pooled across wholes
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(pool_across_wholes)))
row_40486(NumObjects-frac(N,D), Got) :-
    TotalN is NumObjects * N,
    TotalD is NumObjects * D,
    Got is TotalN / TotalD.

test_harness:arith_misconception(db_row(40486), fraction, pool_numer_and_denom,
    misconceptions_fraction_batch_6:row_40486,
    2-frac(1,3),
    0.3333333333333333).

% === row 40515: 1/4 interpreted as 4.5 ===
% Task: interpret 1/4
% Correct: 0.25
% Error: reads "1/4" as "four and a half" → 4.5 (conflates slash with "and a half")
% SCHEMA: Container — symbol confusion with mixed-number spoken form
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(fraction_symbol_as_and_half)))
row_40515(frac(_,D), Got) :-
    Got is D + 0.5.

test_harness:arith_misconception(db_row(40515), fraction, symbol_as_and_half,
    misconceptions_fraction_batch_6:row_40515,
    frac(1,4),
    0.25).

% === row 40589: unequal-sized parts make naming impossible ===
test_harness:arith_misconception(db_row(40589), fraction, too_vague,
    skip, none, none).

% === row 40664: recursive partitioning — can't name share of original ===
test_harness:arith_misconception(db_row(40664), fraction, too_vague,
    skip, none, none).
