:- module(misconceptions_fraction_batch_3, []).
% Fraction misconceptions — research corpus batch 3/7.
% Native arithmetic layer only. Theoretical annotations as comments:
%   % GROUNDED: TODO — placeholder for future embodied arithmetic layer
%   % SCHEMA: <schema name> — Lakoff & Nunez grounding when applicable
%   % CONNECTS TO: s(comp_nec(unlicensed(...))) — PML operator path
%
% Registration convention (from Task 3 arch fix):
%   test_harness:arith_misconception(Source, Domain, Description,
%       misconceptions_fraction_batch_3:rule_name, Input, Expected).
% Rule predicates do NOT go on the module export list.

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

% ---- Encodings appended by agent for batch 3 ----

% === row 37436: unit fraction named by piece length ===
% Task: name the unit fraction that a 6-stick is of a 24-stick
% Correct: frac(1,4)  (24/6 = 4)
% Error: frac(1,6) — naming the fraction by the length of the piece
% SCHEMA: Measuring Stick — the name comes from the part-whole *count*, not the piece length
% GROUNDED: TODO — iterate_count(Whole, Part, N); name(1/N)
% CONNECTS TO: s(comp_nec(unlicensed(name_by_length)))
r37436_name_by_length(Whole-Part, frac(1, Part)) :-
    integer(Whole), integer(Part), Part > 0.

test_harness:arith_misconception(db_row(37436), fraction, unit_frac_named_by_length,
    misconceptions_fraction_batch_3:r37436_name_by_length,
    24-6,
    frac(1,4)).

% === row 37443: guessed partition count from unrelated prior problem ===
% Task: compute frac(3,4) of frac(1,4)
% Correct: frac(3,16)
% Error: frac(3,10) — guessed denominator of 10 from a prior problem
% SCHEMA: Container — recursive partitioning required; student uses simultaneous guess
% GROUNDED: TODO — recursive_partition(frac, frac, frac)
% CONNECTS TO: s(comp_nec(unlicensed(guess_denominator_from_prior)))
r37443_guess_denom(frac(N1,_)-frac(_,_), frac(Got, 10)) :-
    Got is N1.

test_harness:arith_misconception(db_row(37443), fraction, guess_denom_from_prior,
    misconceptions_fraction_batch_3:r37443_guess_denom,
    frac(3,4)-frac(1,4),
    frac(3,16)).

% === row 37450: iterate resulting piece to rebuild whole ===
% Task: compute 1/2 of 1/15
% Correct: frac(1, 30)
% Error: student iterates the piece 30 times and names it 1/30 — which happens to be
% the correct value. The misconception is in the reasoning (iteration rather than
% recursive partition), but the numeric answer coincides. We encode the iteration
% strategy as written; harness will flag as well_formed (matches correct).
% SCHEMA: Container — counted iterations stand in for composed partition
% GROUNDED: TODO — iterate_to_whole(Piece, Count)
% CONNECTS TO: s(comp_nec(unlicensed(iterate_instead_of_compose)))
r37450_iterate_to_name(frac(N1,D1)-frac(N2,D2), frac(Num, Count)) :-
    % iterate the composed piece until it rebuilds the whole; name = 1/Count
    Num is N1 * N2,
    Count is D1 * D2.

test_harness:arith_misconception(db_row(37450), fraction, iterate_to_rebuild_whole,
    misconceptions_fraction_batch_3:r37450_iterate_to_name,
    frac(1,2)-frac(1,15),
    frac(1,30)).

% === row 37488: sum numerators over sum denominators ===
% Task: 1/2 + 2/3
% Correct: 7/6
% Error: (1+2)/(2+3) = 3/5
% SCHEMA: Arithmetic as Object Collection — overgeneralizing "add across"
% GROUNDED: TODO — add_grounded(N1,N2,N), add_grounded(D1,D2,D)
% CONNECTS TO: s(comp_nec(unlicensed(add_across_numer_and_denom)))
r37488_add_across(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2.

test_harness:arith_misconception(db_row(37488), fraction, add_num_over_sum_denom,
    misconceptions_fraction_batch_3:r37488_add_across,
    frac(1,2)-frac(2,3),
    frac(7,6)).

% === row 37512: rote add-across trusted over informal reasoning ===
% Task: 3/8 + 2/8
% Correct: frac(5,8)
% Error: 5/16 — applied add-across rule even when denominators match
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(rote_add_across_same_denom)))
r37512_rote_add_across(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2.

test_harness:arith_misconception(db_row(37512), fraction, rote_add_across_like_denom,
    misconceptions_fraction_batch_3:r37512_rote_add_across,
    frac(3,8)-frac(2,8),
    frac(5,8)).

% === row 37520: referent-whole shift combining identical wholes ===
% Task: 3/8 + 3/8 (interpreted as pieces from two pizzas pooled into 16-piece whole)
% Correct (add): frac(6,8)
% Student: 6/16 — shift referent whole to combined 16-piece total
% SCHEMA: Container — referent unit switched mid-operation
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(referent_whole_shift)))
r37520_referent_shift(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2.

test_harness:arith_misconception(db_row(37520), fraction, referent_whole_shift,
    misconceptions_fraction_batch_3:r37520_referent_shift,
    frac(3,8)-frac(3,8),
    frac(6,8)).

% === row 37548: division makes smaller, use multiplication instead ===
% Task: 4 / (1/4)  (how many 1/4-kg packages from 4 kg)
% Correct: 16
% Error: compute 1/4 * 4 = 1 instead
% SCHEMA: Arithmetic as Object Collection — primitive partitive model
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(div_must_shrink_swap_for_mult)))
r37548_swap_for_mult(Whole-frac(N,D), Got) :-
    % multiply instead of divide: (N/D) * Whole
    Got is (N * Whole) / D.

test_harness:arith_misconception(db_row(37548), fraction, div_swap_for_mult,
    misconceptions_fraction_batch_3:r37548_swap_for_mult,
    4-frac(1,4),
    16).

% === row 37573: denominators increase left to right on number line ===
% Task: label 3 tick marks between 0 and 1 (equally spaced at 1/4, 1/2, 3/4)
% Correct: [frac(1,4), frac(1,2), frac(3,4)]
% Error: [frac(1,2), frac(1,3), frac(1,4)] — consecutive unit denominators
% SCHEMA: Measuring Stick — whole-number-consistent left-to-right ordering
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(consecutive_unit_denoms)))
r37573_consecutive_denoms(3, [frac(1,2), frac(1,3), frac(1,4)]).

test_harness:arith_misconception(db_row(37573), fraction, consecutive_unit_denoms,
    misconceptions_fraction_batch_3:r37573_consecutive_denoms,
    3,
    [frac(1,4), frac(1,2), frac(3,4)]).

% === row 37587: more pieces means bigger fraction ===
% Task: compare frac(1,4) and frac(1,3)
% Correct: frac(1,3) larger
% Error: claim frac(1,4) larger because "more total pieces"
% SCHEMA: Arithmetic as Object Collection — whole-number transfer
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(more_pieces_larger)))
r37587_more_pieces_larger(frac(N1,D1)-frac(N2,D2), Larger) :-
    (D1 > D2 -> Larger = frac(N1,D1)
    ; D2 > D1 -> Larger = frac(N2,D2)
    ; Larger = equal).

test_harness:arith_misconception(db_row(37587), fraction, more_pieces_larger,
    misconceptions_fraction_batch_3:r37587_more_pieces_larger,
    frac(1,4)-frac(1,3),
    frac(1,3)).

% === row 37656: improper fractions require multiple wholes ===
% Too vague — a belief claim; no concrete wrong numeric answer.
test_harness:arith_misconception(db_row(37656), fraction, too_vague,
    skip, none, none).

% === row 37666: product of num*denom used inversely for ordering ===
% Task: compare frac(2,3) and frac(2,6)
% Correct: frac(2,3) larger
% Error: 2*6=12 > 2*3=6, so frac(2,6) smaller — happens to match here
% SCHEMA: Measuring Stick — rule invented from cover-count logic
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(product_inverse_order)))
r37666_product_inverse(frac(N1,D1)-frac(N2,D2), Larger) :-
    P1 is N1 * D1,
    P2 is N2 * D2,
    (P1 < P2 -> Larger = frac(N1,D1)
    ; P2 < P1 -> Larger = frac(N2,D2)
    ; Larger = equal).

test_harness:arith_misconception(db_row(37666), fraction, product_size_inverse,
    misconceptions_fraction_batch_3:r37666_product_inverse,
    frac(2,3)-frac(2,6),
    frac(2,3)).

% === row 37679: remainder cannot be shared ===
% Too vague — conceptual refusal to partition, no concrete wrong numeric output.
test_harness:arith_misconception(db_row(37679), fraction, too_vague,
    skip, none, none).

% === row 37720: key-word triggers for operation ===
% Too vague — strategy-selection error, no concrete wrong numeric answer given.
test_harness:arith_misconception(db_row(37720), fraction, too_vague,
    skip, none, none).

% === row 37768: part-whole scheme: pull 3 parts then 2 of those ===
% Task: produce 2/3 from a 6/6 bar
% Correct: pull 4 parts (4/6 = 2/3)
% Error: pulled 3 parts then took 2 of those = 2 parts = 2/6
% SCHEMA: Container — partitive scheme misapplied
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(pull_then_subpull)))
r37768_pull_then_subpull(frac(N,D)-_Whole, Got) :-
    % pull D parts, take N of those
    Pulled is D,
    _ = Pulled,
    Got is N.

test_harness:arith_misconception(db_row(37768), fraction, pull_then_subpull,
    misconceptions_fraction_batch_3:r37768_pull_then_subpull,
    frac(2,3)-6,
    4).

% === row 37781: compare shaded areas by counting pieces ===
% Task: compare two rectangles, each 7 shaded pieces, but different partition sizes
% Correct: depends on sizes; student claims "same, seven and seven"
% Input: count1-count2 = 7-7; Correct: requires piece size, cannot conclude same
% Encode as: rule returns `same` when counts match; expected is `not_same`.
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(count_pieces_ignore_size)))
r37781_count_pieces(C1-C2, Judgement) :-
    (C1 =:= C2 -> Judgement = same
    ; C1 > C2 -> Judgement = first_larger
    ; Judgement = second_larger).

test_harness:arith_misconception(db_row(37781), fraction, count_pieces_ignore_size,
    misconceptions_fraction_batch_3:r37781_count_pieces,
    7-7,
    depends_on_piece_size).

% === row 37804: decompose bundles into singletons and reapply ===
% Task: 3/4 of 8 bundles of 4 sticks — correct answer in bundles is 6
% Error: transform to 32 sticks, compute 24, then divide to get 6 bundles
% The student's procedure arrives at the same numeric answer (24 sticks / 6 bundles),
% so the misconception is in the unit-reasoning, not the number. Encode the
% singleton path as returning 24 (sticks) when the expected answer is 6 (bundles).
% SCHEMA: Arithmetic as Object Collection — collapses composite units
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(decompose_composite_units)))
r37804_singleton_path(frac(N,D)-bundles(B,S), Got) :-
    Total is B * S,
    Got is (Total * N) / D.

test_harness:arith_misconception(db_row(37804), fraction, decompose_composite_units,
    misconceptions_fraction_batch_3:r37804_singleton_path,
    frac(3,4)-bundles(8,4),
    6).

% === row 37822: partition by iteration + adjustment ===
% Too vague — describes search behavior rather than a concrete wrong numeric answer.
test_harness:arith_misconception(db_row(37822), fraction, too_vague,
    skip, none, none).

% === row 37846: standard notation without part-whole reference ===
% Too vague — notational use without a specific wrong numeric answer in the example.
test_harness:arith_misconception(db_row(37846), fraction, too_vague,
    skip, none, none).

% === row 37863: iterating 1/8 nine times called 9/9 ===
% Task: name the stick built by iterating frac(1,8) nine times
% Correct: frac(9,8)
% Error: frac(9,9) — shifts whole to the new 9-part stick
% SCHEMA: Container — referent whole reassigned to result
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(reference_whole_shift_iterate)))
r37863_shift_whole(frac(N,_)-Iter, frac(Iter, Iter)) :-
    integer(N), integer(Iter).

test_harness:arith_misconception(db_row(37863), fraction, shift_whole_on_iterate,
    misconceptions_fraction_batch_3:r37863_shift_whole,
    frac(1,8)-9,
    frac(9,8)).

% === row 37879: whole number treated as fraction with same denominator ===
% Task: 1 - 4/5
% Correct: frac(1,5)
% Error: reads 1 as 1/5, computes 4-1=3, answer 3/5
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(whole_as_num_same_denom)))
r37879_whole_as_unit(Whole-frac(N,D), frac(Num, D)) :-
    % treat Whole as Whole/D; compute N - Whole; take absolute value
    Num is abs(N - Whole).

test_harness:arith_misconception(db_row(37879), fraction, whole_as_unit_fraction,
    misconceptions_fraction_batch_3:r37879_whole_as_unit,
    1-frac(4,5),
    frac(1,5)).

% === row 37909: partial scaling in equivalent-fraction missing value ===
% Task: 6/4 = ?/8 — find missing numerator
% Correct: 12 (scale factor 2)
% Error: 3 — "three into six twice; two times four equals eight" — divides numerator by 2
% SCHEMA: Measuring Stick — misapplies reciprocal scaling
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(partial_scale_missing_numer)))
r37909_partial_scale(frac(N1,D1)-D2, Got) :-
    Factor is D2 / D1,
    Got is N1 / Factor.

test_harness:arith_misconception(db_row(37909), fraction, partial_scale_missing_numer,
    misconceptions_fraction_batch_3:r37909_partial_scale,
    frac(6,4)-8,
    12).

% === row 37940: 1/2 + 1/4 = 2/6 via multiply-like addition ===
% Task: 1/2 + 1/4
% Correct: frac(3,4)
% Error: add across → frac(2,6)
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_across_unlike)))
r37940_add_across(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2.

test_harness:arith_misconception(db_row(37940), fraction, add_across_unlike_denoms,
    misconceptions_fraction_batch_3:r37940_add_across,
    frac(1,2)-frac(1,4),
    frac(3,4)).

% === row 37974: 2/7 + 3/7 = 5/14 ===
% Task: 2/7 + 3/7
% Correct: frac(5,7)
% Error: add across → frac(5,14)
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_across_like_denoms)))
r37974_add_across(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2.

test_harness:arith_misconception(db_row(37974), fraction, add_across_like_denoms,
    misconceptions_fraction_batch_3:r37974_add_across,
    frac(2,7)-frac(3,7),
    frac(5,7)).

% === row 38055: 1/4 + 2/5 = 3/9 ===
% Task: 1/4 + 2/5
% Correct: frac(13,20)
% Error: add across → frac(3,9)
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_across_unlike)))
r38055_add_across(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2.

test_harness:arith_misconception(db_row(38055), fraction, add_across_unlike,
    misconceptions_fraction_batch_3:r38055_add_across,
    frac(1,4)-frac(2,5),
    frac(13,20)).

% === row 38113: multiply num and denom by whole number ===
% Task: (1/2) * 3
% Correct: frac(3,2)
% Error: multiply both parts by whole → frac(3,6)
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(mult_both_by_whole)))
r38113_mult_both_by_whole(frac(N,D)-K, frac(N2, D2)) :-
    N2 is N * K,
    D2 is D * K.

test_harness:arith_misconception(db_row(38113), fraction, mult_both_by_whole,
    misconceptions_fraction_batch_3:r38113_mult_both_by_whole,
    frac(1,2)-3,
    frac(3,2)).

% === row 38139: multiplication always makes bigger ===
% Too vague — a belief claim; no concrete example in CSV.
test_harness:arith_misconception(db_row(38139), fraction, too_vague,
    skip, none, none).

% === row 38220: multiplication only as repeated addition ===
% Too vague — rejection of operation, not a concrete wrong numeric answer.
test_harness:arith_misconception(db_row(38220), fraction, too_vague,
    skip, none, none).

% === row 38243: equal iff same absolute missing amount ===
% Task: compare frac(3,4) and frac(5,6)
% Correct: 5/6 > 3/4
% Error: both missing 1 piece, so "equal"
% SCHEMA: Arithmetic as Object Collection — compares complement counts
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(equal_by_missing_count)))
r38243_missing_pieces_equal(frac(N1,D1)-frac(N2,D2), Judgement) :-
    M1 is D1 - N1,
    M2 is D2 - N2,
    (M1 =:= M2 -> Judgement = equal
    ; M1 < M2 -> Judgement = first_larger
    ; Judgement = second_larger).

test_harness:arith_misconception(db_row(38243), fraction, equal_by_missing_piece_count,
    misconceptions_fraction_batch_3:r38243_missing_pieces_equal,
    frac(3,4)-frac(5,6),
    second_larger).

% === row 38260: 1/n only via equal partition — unequal means not 1/n ===
% Too vague — a rejection claim about representation, not a numeric transformation.
test_harness:arith_misconception(db_row(38260), fraction, too_vague,
    skip, none, none).

% === row 38283: missing-denominator task — couldn't proceed ===
% Too vague — strategy breakdown without a concrete wrong numeric output.
test_harness:arith_misconception(db_row(38283), fraction, too_vague,
    skip, none, none).

% === row 38315: biggest-numerator-means-biggest-fraction ===
% Task: compare frac(2,3) and frac(5,6) (or two arbitrary fractions)
% Correct: cross-product ordering
% Error: whoever has larger numerator is larger
% SCHEMA: Arithmetic as Object Collection — whole-number-consistent
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(bigger_numer_bigger_frac)))
r38315_bigger_numer(frac(N1,D1)-frac(N2,D2), Larger) :-
    (N1 > N2 -> Larger = frac(N1,D1)
    ; N2 > N1 -> Larger = frac(N2,D2)
    ; Larger = equal).

test_harness:arith_misconception(db_row(38315), fraction, bigger_numer_bigger_frac,
    misconceptions_fraction_batch_3:r38315_bigger_numer,
    frac(2,3)-frac(5,6),
    frac(5,6)).

% === row 38367: third of an eighth — guessed wrong frac ===
% Task: 1/3 of 1/8
% Correct: frac(1,24)
% Error: guessed frac(1,4) based on visual cues
% SCHEMA: Container — no iterable unit fractional part
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(guess_from_visual)))
r38367_guess_visual(frac(1,3)-frac(1,8), frac(1,4)).

test_harness:arith_misconception(db_row(38367), fraction, guess_recursive_partition,
    misconceptions_fraction_batch_3:r38367_guess_visual,
    frac(1,3)-frac(1,8),
    frac(1,24)).

% === row 38385: add full shortage to next estimate ===
% Too vague — describes adjustment strategy, not a concrete wrong numeric output.
test_harness:arith_misconception(db_row(38385), fraction, too_vague,
    skip, none, none).

% === row 38405: compare same-denom by numerator alone (whole number bias) ===
% Task: compare frac(7,8) and frac(3,8)
% Correct: frac(7,8) larger
% Error: correct answer but via isolated whole-number reasoning; no wrong numeric result.
% Still encode: student returns larger numerator's fraction — this matches correct.
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(numer_as_whole_numbers)))
r38405_numer_whole(frac(N1,D1)-frac(N2,D2), Larger) :-
    (N1 > N2 -> Larger = frac(N1,D1)
    ; N2 > N1 -> Larger = frac(N2,D2)
    ; Larger = equal).

test_harness:arith_misconception(db_row(38405), fraction, numer_as_whole_numbers,
    misconceptions_fraction_batch_3:r38405_numer_whole,
    frac(7,8)-frac(3,8),
    frac(7,8)).

% === row 38431: referent-unit switch in difference ===
% Task: frac(1,2) - frac(1,3)
% Correct: frac(1,6)
% Error: difference is 1/3 of the 1/2 rod — renames remainder with shifted referent
% SCHEMA: Container — referent unit switched mid-problem
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(referent_unit_switch_difference)))
r38431_referent_switch(frac(N1,D1)-frac(N2,D2), frac(1,3)) :-
    N1 = 1, D1 = 2, N2 = 1, D2 = 3.

test_harness:arith_misconception(db_row(38431), fraction, referent_unit_switch_difference,
    misconceptions_fraction_batch_3:r38431_referent_switch,
    frac(1,2)-frac(1,3),
    frac(1,6)).

% === row 38454: name fraction by count of pieces present ===
% Task: what fraction is shown when 5 of 6 pieces are present (one missing)
% Correct: frac(5,6)
% Error: frac(1,5) — names by count of pieces shown
% SCHEMA: Arithmetic as Object Collection — missing disembedding
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(name_by_count_present)))
r38454_name_by_count(present(Count, _Total), frac(1, Count)).

test_harness:arith_misconception(db_row(38454), fraction, name_by_count_present,
    misconceptions_fraction_batch_3:r38454_name_by_count,
    present(5, 6),
    frac(5,6)).

% === row 38491: add-across unlike denominators ===
% Task: 10/50 + 40/100
% Correct: frac(60, 100) i.e. frac(3,5)
% Error: 50/150 (add across)
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_across_unlike)))
r38491_add_across(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2.

test_harness:arith_misconception(db_row(38491), fraction, add_across_sheets,
    misconceptions_fraction_batch_3:r38491_add_across,
    frac(10,50)-frac(40,100),
    frac(60,100)).

% === row 38556: 1/3 of 12 by subtracting the denominator ===
% Task: 1/3 of 12
% Correct: 4
% Error: 12 - 3 = 9
% SCHEMA: Arithmetic as Object Collection — additive interpretation
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(unit_frac_as_subtract_denom)))
r38556_subtract_denom(frac(_,D)-N, Got) :-
    Got is N - D.

test_harness:arith_misconception(db_row(38556), fraction, unit_frac_as_subtract_denom,
    misconceptions_fraction_batch_3:r38556_subtract_denom,
    frac(1,3)-12,
    4).

% === row 38573: disembedding failure — whole destroyed when part removed ===
% Too vague — conceptual disembedding failure; no concrete numeric wrong answer.
test_harness:arith_misconception(db_row(38573), fraction, too_vague,
    skip, none, none).

% === row 38647: repeated halving breaks with odd sharers ===
% Too vague — strategy breakdown without a specific wrong numeric answer.
test_harness:arith_misconception(db_row(38647), fraction, too_vague,
    skip, none, none).

% === row 38663: multiplication algorithm needs denominators ===
% Too vague — inability to respond, not a wrong numeric answer.
test_harness:arith_misconception(db_row(38663), fraction, too_vague,
    skip, none, none).

% === row 38678: bigger-denominator-smaller-fraction as procedural fact ===
% Task: explain why 1/2 > 1/12
% Too vague for numeric encoding — meta/justification, not an arithmetic result.
test_harness:arith_misconception(db_row(38678), fraction, too_vague,
    skip, none, none).

% === row 38716: part-whole scheme rejects 9/7 ===
% Too vague — belief/rejection, no numeric transformation.
test_harness:arith_misconception(db_row(38716), fraction, too_vague,
    skip, none, none).

% === row 38753: bigger numbers means bigger fraction ===
% Task: compare frac(8,10) and frac(4,5)
% Correct: equal
% Error: frac(8,10) larger because "both bigger"
% SCHEMA: Arithmetic as Object Collection — whole-number bias
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(bigger_both_bigger_frac)))
r38753_bigger_both(frac(N1,D1)-frac(N2,D2), Larger) :-
    (N1 > N2, D1 > D2 -> Larger = frac(N1,D1)
    ; N2 > N1, D2 > D1 -> Larger = frac(N2,D2)
    ; Larger = unclear).

test_harness:arith_misconception(db_row(38753), fraction, bigger_both_bigger_frac,
    misconceptions_fraction_batch_3:r38753_bigger_both,
    frac(8,10)-frac(4,5),
    equal).

% === row 38836: convert smaller to larger denominator incorrectly ===
% Too vague — describes incorrect conversion attempts without specific numeric example.
test_harness:arith_misconception(db_row(38836), fraction, too_vague,
    skip, none, none).

% === row 38856: didactical contract — swap 2/1 for 1/2 ===
% Task: ratio of shaded(2) to unshaded(1)
% Correct: frac(2,1)
% Error: frac(1,2) — swapped to fit conventional appearance
% SCHEMA: Container — didactical contract overrides setup
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(swap_for_convention)))
r38856_swap_for_convention(ratio(Shaded, Unshaded), frac(Unshaded, Shaded)) :-
    integer(Shaded), integer(Unshaded).

test_harness:arith_misconception(db_row(38856), fraction, swap_ratio_for_convention,
    misconceptions_fraction_batch_3:r38856_swap_for_convention,
    ratio(2,1),
    frac(2,1)).

% === row 38913: lowest bottom number is greatest ===
% Task: compare frac(3,4) and frac(5,6)
% Correct: frac(5,6) larger
% Error: frac(3,4) — 4 < 6, so "lowest bottom wins"
% SCHEMA: Arithmetic as Object Collection — overgeneralized rule
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(lowest_denom_greatest)))
r38913_lowest_denom(frac(N1,D1)-frac(N2,D2), Larger) :-
    (D1 < D2 -> Larger = frac(N1,D1)
    ; D2 < D1 -> Larger = frac(N2,D2)
    ; Larger = equal).

test_harness:arith_misconception(db_row(38913), fraction, lowest_denom_greatest,
    misconceptions_fraction_batch_3:r38913_lowest_denom,
    frac(3,4)-frac(5,6),
    frac(5,6)).

% === row 38963: cannot halve a week ===
% Too vague — discreteness claim without numeric transformation.
test_harness:arith_misconception(db_row(38963), fraction, too_vague,
    skip, none, none).

% === row 38981: can be both ages simultaneously ===
% Too vague — timeline/ordering belief; no concrete fraction arithmetic output.
test_harness:arith_misconception(db_row(38981), fraction, too_vague,
    skip, none, none).

% === row 39011: partition without quantifying shares ===
% Too vague — inability to name shares; no wrong numeric output.
test_harness:arith_misconception(db_row(39011), fraction, too_vague,
    skip, none, none).

% === row 39073: can't divide smaller by larger ===
% Too vague — refusal of operation, no numeric wrong output.
test_harness:arith_misconception(db_row(39073), fraction, too_vague,
    skip, none, none).

% === row 39134: order-of-appearance ratio setup ===
% Task: given numbers 5,3,7,4 (problem mentions 3-out-of-5 and 4-out-of-7)
% Correct: compare frac(3,5) and frac(4,7)
% Error: compare frac(5,3) and frac(7,4) — order of appearance
% SCHEMA: Arithmetic as Object Collection — syntactic setup
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(order_of_appearance_ratio)))
r39134_order_of_appearance([A,B,C,D], [frac(A,B), frac(C,D)]) :-
    integer(A), integer(B), integer(C), integer(D).

test_harness:arith_misconception(db_row(39134), fraction, order_of_appearance_ratio,
    misconceptions_fraction_batch_3:r39134_order_of_appearance,
    [5,3,7,4],
    [frac(3,5), frac(4,7)]).

% === row 39162: add-tops-and-bottoms (whole-number bias) ===
% Task: 1/3 + 1/6
% Correct: frac(1,2) (i.e., 3/6)
% Error: add across → frac(2,9)
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_tops_and_bottoms)))
r39162_add_across(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2.

test_harness:arith_misconception(db_row(39162), fraction, add_tops_and_bottoms,
    misconceptions_fraction_batch_3:r39162_add_across,
    frac(1,3)-frac(1,6),
    frac(3,6)).

% === row 39192: dealing strategy abandoned ===
% Too vague — strategy abandonment, no concrete wrong numeric answer.
test_harness:arith_misconception(db_row(39192), fraction, too_vague,
    skip, none, none).

% === row 39273: degrees of equivalence ===
% Too vague — belief about equivalence; no wrong numeric computation.
test_harness:arith_misconception(db_row(39273), fraction, too_vague,
    skip, none, none).

% === row 39347: invert-and-multiply bugs — multiply without inverting ===
% Task: (3/5) / (1/20)
% Correct: frac(60, 5) i.e. 12
% Error: multiply without inverting → (3*1)/(5*20) = 3/100
% SCHEMA: Arithmetic as Object Collection — algorithmic bug
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(multiply_without_invert)))
r39347_multiply_no_invert(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 * N2,
    D is D1 * D2.

test_harness:arith_misconception(db_row(39347), fraction, multiply_without_invert,
    misconceptions_fraction_batch_3:r39347_multiply_no_invert,
    frac(3,5)-frac(1,20),
    frac(60,5)).

% === row 39411: improper fraction destabilized by realistic context ===
% Too vague — contextual rejection, no wrong numeric.
test_harness:arith_misconception(db_row(39411), fraction, too_vague,
    skip, none, none).

% === row 39470: overreliance on circle model ===
% Too vague — model-rigidity, no wrong numeric output.
test_harness:arith_misconception(db_row(39470), fraction, too_vague,
    skip, none, none).

% === row 39556: 1/2 = 1/3 via different-sized wholes ===
% Task: compare frac(1,2) and frac(1,3)
% Correct: frac(1,2) larger
% Error: declares equal by drawing different-sized wholes
% SCHEMA: Container — referent-whole size ignored
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(unequal_wholes)))
r39556_unequal_wholes(frac(_,_)-frac(_,_), equal).

test_harness:arith_misconception(db_row(39556), fraction, unequal_wholes_equal,
    misconceptions_fraction_batch_3:r39556_unequal_wholes,
    frac(1,2)-frac(1,3),
    frac(1,2)).

% === row 39600: whole number concepts interfere (general) ===
% Too vague — general claim, no specific wrong numeric example.
test_harness:arith_misconception(db_row(39600), fraction, too_vague,
    skip, none, none).

% === row 39619: 1/2 + 1/4 = 2/6 (add across) ===
% Task: 1/2 + 1/4
% Correct: frac(3,4)
% Error: frac(2,6)
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_across_unlike)))
r39619_add_across(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2.

test_harness:arith_misconception(db_row(39619), fraction, add_across_unlike,
    misconceptions_fraction_batch_3:r39619_add_across,
    frac(1,2)-frac(1,4),
    frac(3,4)).

% === row 39653: area-model only for unit fractions ===
% Too vague — model rigidity; no concrete wrong numeric output.
test_harness:arith_misconception(db_row(39653), fraction, too_vague,
    skip, none, none).

% === row 39689: "more" triggers addition ignoring unit ===
% Task: 1/5 more than cats(3) — correct: 3 + 1/5 * 3 = 3.6 (but dogs must be whole)
% Error: add 1/5 directly to 3 → 3 1/5 dogs
% SCHEMA: Arithmetic as Object Collection — keyword triggered addition
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(keyword_add_ignore_unit)))
r39689_keyword_add(more_than(Cats, frac(N,D)), mixed(Cats, frac(N,D))) :-
    integer(Cats).

test_harness:arith_misconception(db_row(39689), fraction, keyword_triggers_add,
    misconceptions_fraction_batch_3:r39689_keyword_add,
    more_than(3, frac(1,5)),
    whole_number_adjusted).

% === row 39712: mixed-to-improper: add parts ignoring whole ===
% Task: convert 1 4/5 to improper
% Correct: frac(9,5)
% Error: 4+5 = 9/5, ignoring the 1 — numerically coincides here, but method wrong.
% SCHEMA: Arithmetic as Object Collection — local algorithm
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(ignore_whole_add_parts)))
r39712_add_parts(mixed(_W, frac(N,D)), frac(Num, D)) :-
    Num is N + D.

test_harness:arith_misconception(db_row(39712), fraction, add_num_denom_ignore_whole,
    misconceptions_fraction_batch_3:r39712_add_parts,
    mixed(1, frac(4,5)),
    frac(9,5)).

% === row 39765: 3/8 + 4/10 = 7/18 ===
% Task: 3/8 + 4/10
% Correct: frac(62, 80) = frac(31,40)
% Error: frac(7,18)
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_across_unlike)))
r39765_add_across(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2.

test_harness:arith_misconception(db_row(39765), fraction, add_across_unlike,
    misconceptions_fraction_batch_3:r39765_add_across,
    frac(3,8)-frac(4,10),
    frac(62,80)).

% === row 39772: mismark number line for measurement division ===
% Too vague — placement error without a concrete numeric arithmetic output.
test_harness:arith_misconception(db_row(39772), fraction, too_vague,
    skip, none, none).

% === row 39811: "two-ninths" for 1/3 + 1/6 ===
% Task: 1/3 + 1/6
% Correct: frac(1,2)
% Error: frac(2,9)
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_across_unlike)))
r39811_add_across(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2.

test_harness:arith_misconception(db_row(39811), fraction, add_across_unlike,
    misconceptions_fraction_batch_3:r39811_add_across,
    frac(1,3)-frac(1,6),
    frac(3,6)).

% === row 39818: inconsistent units in fraction addition ===
% Too vague — unit inconsistency without specific numeric wrong answer.
test_harness:arith_misconception(db_row(39818), fraction, too_vague,
    skip, none, none).

% === row 39836: smaller denom means smaller fraction ===
% Task: compare frac(1,5) and frac(1,10)
% Correct: frac(1,5) larger
% Error: frac(1,10) larger (smaller denom is smaller)
% SCHEMA: Arithmetic as Object Collection — whole-number bias
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(smaller_denom_smaller_frac)))
r39836_smaller_denom_smaller(frac(N1,D1)-frac(N2,D2), Larger) :-
    (D1 > D2 -> Larger = frac(N1,D1)
    ; D2 > D1 -> Larger = frac(N2,D2)
    ; Larger = equal).

test_harness:arith_misconception(db_row(39836), fraction, smaller_denom_smaller_frac,
    misconceptions_fraction_batch_3:r39836_smaller_denom_smaller,
    frac(1,5)-frac(1,10),
    frac(1,5)).

% === row 39890: reverse-ordered notation — "5/2" for "two fifths" ===
% Task: write the fraction for "two fifths" (bottom-to-top in Turkish)
% Correct: frac(2,5)
% Error: frac(5,2) — wrote in read order
% SCHEMA: Measuring Stick — swap positions from reading order
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(swap_numer_denom_notation)))
r39890_swap_notation(spoken(Denom, Numer), frac(Denom, Numer)) :-
    integer(Denom), integer(Numer).

test_harness:arith_misconception(db_row(39890), fraction, swap_notation_direction,
    misconceptions_fraction_batch_3:r39890_swap_notation,
    spoken(5, 2),
    frac(2,5)).

% === row 39948: 1/5 + 1/3 = 2/8 ===
% Task: 1/5 + 1/3
% Correct: frac(8,15)
% Error: frac(2,8)
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_across_unlike)))
r39948_add_across(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2.

test_harness:arith_misconception(db_row(39948), fraction, add_across_unlike,
    misconceptions_fraction_batch_3:r39948_add_across,
    frac(1,5)-frac(1,3),
    frac(8,15)).

% === row 40034: treat linear shaded half as area 1/8 ===
% Too vague — perceptual misidentification; no clean numeric transformation.
test_harness:arith_misconception(db_row(40034), fraction, too_vague,
    skip, none, none).

% === row 40083: distribute denominator across multiplied numerators ===
% Task: estimate (600 * 7) / 20
% Correct: 210
% Error: 600/20 * 7/20 = 30 * (1/3) ≈ 10   (written wrong distribution of denom)
% SCHEMA: Arithmetic as Object Collection — distributes denom wrongly
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(distribute_denom_over_product)))
r40083_distribute_denom(prod(A,B)-D, Got) :-
    Got is (A / D) * (B / D).

test_harness:arith_misconception(db_row(40083), fraction, distribute_denom_wrongly,
    misconceptions_fraction_batch_3:r40083_distribute_denom,
    prod(600, 7)-20,
    210).

% === row 40103: smaller denominator always larger, ignore numerator ===
% Task: compare frac(5,8) and frac(1,2)
% Correct: frac(5,8) larger
% Error: frac(1,2) larger (smaller denom)
% SCHEMA: Arithmetic as Object Collection
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(smaller_denom_always_larger)))
r40103_smaller_denom_always(frac(N1,D1)-frac(N2,D2), Larger) :-
    (D1 < D2 -> Larger = frac(N1,D1)
    ; D2 < D1 -> Larger = frac(N2,D2)
    ; Larger = equal).

test_harness:arith_misconception(db_row(40103), fraction, smaller_denom_always_larger,
    misconceptions_fraction_batch_3:r40103_smaller_denom_always,
    frac(5,8)-frac(1,2),
    frac(5,8)).

% === row 40118: swap middle terms of inequality chain ===
% Too vague — meta-justification, no numeric wrong answer.
test_harness:arith_misconception(db_row(40118), fraction, too_vague,
    skip, none, none).

% === row 40134: division-by-whole-number story for fraction divisor ===
% Too vague — story-problem generation error, not a numeric computation.
test_harness:arith_misconception(db_row(40134), fraction, too_vague,
    skip, none, none).

% === row 40147: partitive story that takes fraction of dividend ===
% Task: 24 / (1/4) in a story context
% Correct: 96
% Error: treat as (1/4) * 24 = 6
% SCHEMA: Arithmetic as Object Collection — confuses divide with take-fraction-of
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(divide_as_take_fraction_of)))
r40147_take_fraction(Whole-frac(N,D), Got) :-
    Got is (Whole * N) / D.

test_harness:arith_misconception(db_row(40147), fraction, divide_as_take_fraction_of,
    misconceptions_fraction_batch_3:r40147_take_fraction,
    24-frac(1,4),
    96).

% === row 40175: denominator dominance ===
% Task: compare frac(8,24) and frac(13,39)
% Correct: equal (both 1/3)
% Error: frac(8,24) larger because 39 gives smaller pieces
% SCHEMA: Arithmetic as Object Collection — ignore numerator
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(denominator_dominance)))
r40175_denom_dominance(frac(N1,D1)-frac(N2,D2), Larger) :-
    (D1 < D2 -> Larger = frac(N1,D1)
    ; D2 < D1 -> Larger = frac(N2,D2)
    ; Larger = equal).

test_harness:arith_misconception(db_row(40175), fraction, denominator_dominance,
    misconceptions_fraction_batch_3:r40175_denom_dominance,
    frac(8,24)-frac(13,39),
    equal).

% === row 40195: surface-feature equated with understanding ===
% Too vague — teacher-evaluation artifact, not a fraction computation.
test_harness:arith_misconception(db_row(40195), fraction, too_vague,
    skip, none, none).

% === row 40215: correct answer via irrelevant strategy ===
% Too vague — assessment artifact, no wrong numeric student answer.
test_harness:arith_misconception(db_row(40215), fraction, too_vague,
    skip, none, none).

% === row 40245: 4/8 equals 1/2 but "shouldn't it be 2/4?" ===
% Task: halve frac(4,8)
% Correct: frac(2,4) (or simplified 1/2)
% Error: confusion between the two equivalent forms — no numeric error, just a
% semantic question. Treat as too_vague.
test_harness:arith_misconception(db_row(40245), fraction, too_vague,
    skip, none, none).

% === row 40270: default to symbolic procedure without blocks ===
% Too vague — pedagogical strategy, no numeric output.
test_harness:arith_misconception(db_row(40270), fraction, too_vague,
    skip, none, none).

% === row 40364: 1/7 larger than 1/5 because 7 > 5 ===
% Task: compare frac(1,7) and frac(1,5)
% Correct: frac(1,5) larger
% Error: frac(1,7) larger (larger denom)
% SCHEMA: Arithmetic as Object Collection — whole-number bias
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(larger_denom_larger_frac)))
r40364_larger_denom(frac(N1,D1)-frac(N2,D2), Larger) :-
    (D1 > D2 -> Larger = frac(N1,D1)
    ; D2 > D1 -> Larger = frac(N2,D2)
    ; Larger = equal).

test_harness:arith_misconception(db_row(40364), fraction, larger_denom_larger_frac,
    misconceptions_fraction_batch_3:r40364_larger_denom,
    frac(1,7)-frac(1,5),
    frac(1,5)).

% === row 40380: subtract wholes but add fractions in mixed subtraction ===
% Task: 3 17/25 - 2 3/25
% Correct: 1 14/25 (= mixed(1, frac(14,25)))
% Error: mixed(1, frac(20,25)) — subtracts wholes, adds fractional parts
% SCHEMA: Arithmetic as Object Collection — operation confusion
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(add_fracs_subtract_wholes)))
r40380_add_fracs_subtract_wholes(mixed(W1, frac(N1,D1))-mixed(W2, frac(N2,_D2)),
                                  mixed(W, frac(N,D))) :-
    W is W1 - W2,
    N is N1 + N2,
    D is D1.

test_harness:arith_misconception(db_row(40380), fraction, add_fracs_subtract_wholes,
    misconceptions_fraction_batch_3:r40380_add_fracs_subtract_wholes,
    mixed(3, frac(17,25))-mixed(2, frac(3,25)),
    mixed(1, frac(14,25))).

% === row 40411: reduce/expand with unlike denominators ===
% Too vague — difficulty description, no concrete wrong numeric answer.
test_harness:arith_misconception(db_row(40411), fraction, too_vague,
    skip, none, none).

% === row 40453: rationals as discrete not dense ===
% Too vague — density belief, no numeric example in row.
test_harness:arith_misconception(db_row(40453), fraction, too_vague,
    skip, none, none).

% === row 40480: same numerators, larger denom means larger ===
% Task: compare frac(7,10) and frac(7,11)
% Correct: frac(7,10) larger
% Error: frac(7,11) larger (11 > 10)
% SCHEMA: Arithmetic as Object Collection — whole-number bias
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(same_numer_larger_denom_larger)))
r40480_same_numer_larger_denom(frac(N1,D1)-frac(N2,D2), Larger) :-
    (D1 > D2 -> Larger = frac(N1,D1)
    ; D2 > D1 -> Larger = frac(N2,D2)
    ; Larger = equal).

test_harness:arith_misconception(db_row(40480), fraction, same_numer_larger_denom,
    misconceptions_fraction_batch_3:r40480_same_numer_larger_denom,
    frac(7,10)-frac(7,11),
    frac(7,10)).

% === row 40495: two diagonals on non-square rectangle give quarters ===
% Too vague — partitioning claim; not a numeric wrong answer in the usual sense.
test_harness:arith_misconception(db_row(40495), fraction, too_vague,
    skip, none, none).

% === row 40552: 1/4 > 1/2 because 4 > 2 ===
% Task: compare frac(1,4) and frac(1,2)
% Correct: frac(1,2) larger
% Error: frac(1,4) larger because 4 > 2
% SCHEMA: Arithmetic as Object Collection — component-as-whole-numbers
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(components_as_whole_numbers)))
r40552_components_whole(frac(N1,D1)-frac(N2,D2), Larger) :-
    (D1 > D2 -> Larger = frac(N1,D1)
    ; D2 > D1 -> Larger = frac(N2,D2)
    ; Larger = equal).

test_harness:arith_misconception(db_row(40552), fraction, components_as_whole_numbers,
    misconceptions_fraction_batch_3:r40552_components_whole,
    frac(1,4)-frac(1,2),
    frac(1,2)).

% === row 40620: repeated halving converges to whole in finite steps ===
% Too vague — infinite-series belief; no specific wrong numeric output.
test_harness:arith_misconception(db_row(40620), fraction, too_vague,
    skip, none, none).
