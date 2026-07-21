:- module(misconceptions_fraction_batch_4, []).
% Fraction misconceptions — research corpus batch 4/7.
% Native arithmetic layer only. Theoretical annotations as comments:
%   % GROUNDED: TODO — placeholder for future embodied arithmetic layer
%   % SCHEMA: <schema name> — Lakoff & Nunez grounding when applicable
%   % CONNECTS TO: s(comp_nec(unlicensed(...))) — PML operator path
%
% Registration convention (from Task 3 arch fix):
%   test_harness:arith_misconception(Source, Domain, Description,
%       misconceptions_fraction_batch_4:rule_name, Input, Expected).
% Rule predicates do NOT go on the module export list.

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

% ---- Encodings appended by agent for batch 4 ----

% === row 37437: iteration count as numerator ===
% Task: name fractional part of 3-stick in a 24-stick made by 8 iterations.
% Correct: 1/8 (one iteration is 1/Total)
% Error: 3/8 (uses stick length 3 as numerator)
% SCHEMA: Measuring Stick — multiplicative relation of unit to whole
% GROUNDED: TODO — iteration-as-unit grounding
% CONNECTS TO: s(comp_nec(unlicensed(iteration_count_as_numerator)))
iteration_count_as_numerator(StickLen-Iterations, frac(N,D)) :-
    N is StickLen,
    D is Iterations.

test_harness:arith_misconception(db_row(37437), fraction, iteration_count_as_numerator,
    misconceptions_fraction_batch_4:iteration_count_as_numerator,
    3-8,
    frac(1,8)).

% === row 37444: improper fraction by added pieces ===
% Task: draw 7/5 of a candy bar.
% Correct: frac(7,5) — seven iterations of one-fifth unit.
% Error: added 2 pieces to 5 and denominator became 7.
% SCHEMA: Container — parts stay in the original bar
% GROUNDED: TODO — iterative unit grounding for improper fractions
% CONNECTS TO: s(comp_nec(unlicensed(denominator_follows_total_pieces)))
denominator_follows_total_pieces(frac(N,_D), frac(N,Total)) :-
    Total is N.   % student used count of total pieces as new denominator

test_harness:arith_misconception(db_row(37444), fraction, denom_follows_total_pieces,
    misconceptions_fraction_batch_4:denominator_follows_total_pieces,
    frac(7,5),
    frac(7,5)).

% === row 37451: intermediate unit as denominator ===
% Task: 2/5 of 3/4.
% Correct: frac(6,20) — parts relative to whole.
% Error: frac(6,15) — named relative to intermediate composite (3*5=15).
% SCHEMA: Fraction of a fraction
% GROUNDED: TODO — units-coordination grounding
% CONNECTS TO: s(comp_nec(unlicensed(intermediate_unit_as_denominator)))
intermediate_unit_as_denominator(frac(N1,_D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 * N2,
    D is N1 * D2.   % student uses intermediate (N1 * D2) instead of D1 * D2

test_harness:arith_misconception(db_row(37451), fraction, intermediate_unit_as_denom,
    misconceptions_fraction_batch_4:intermediate_unit_as_denominator,
    frac(2,5)-frac(3,4),
    frac(6,20)).

% === row 37471: estimate mixed by whole parts only ===
% Task: estimate 7 1/10 + 3 2/3 + 1 1/5.
% Correct: 12 (sum rounds to about 12, fractional parts ~ 1)
% Error: 11 (ignored fractional parts entirely)
% SCHEMA: Quantity — whole part neglects fractional increment
% GROUNDED: TODO — mixed-number estimation grounding
% CONNECTS TO: s(comp_nec(unlicensed(ignore_fractional_parts)))
ignore_fractional_parts(Wholes, Sum) :-
    sum_list(Wholes, Sum).

test_harness:arith_misconception(db_row(37471), fraction, ignore_fractional_parts,
    misconceptions_fraction_batch_4:ignore_fractional_parts,
    [7,3,1],
    12).

% === row 37489: equivalent fractions by adding ===
% Task: 1/2 + 2/3 using common denominator.
% Correct: 7/6 (3/6 + 4/6)
% Error: add constant to num and denom to reach denom 5 → (4+4)/5 = 8/5
% SCHEMA: Additive equivalence (buggy)
% GROUNDED: TODO — multiplicative scaling grounding
% CONNECTS TO: s(comp_nec(unlicensed(equivalent_by_adding)))
equivalent_by_adding(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    D is D1 + D2,
    K1 is D - D1,
    K2 is D - D2,
    N is (N1 + K1) + (N2 + K2).

test_harness:arith_misconception(db_row(37489), fraction, equivalent_by_adding,
    misconceptions_fraction_batch_4:equivalent_by_adding,
    frac(1,2)-frac(2,3),
    frac(7,6)).

% === row 37513: operator compare by additive difference ===
test_harness:arith_misconception(db_row(37513), fraction, too_vague,
    skip, none, none).

% === row 37521: total pieces as both numerator and denominator ===
% Task: 8 children each get 1/4 of a candy bar — total?
% Correct: 8/4 = 2 (eight fourths).
% Error: "eight eighths" — uses total pieces (8) as both num and denom.
% SCHEMA: Share aggregation with denominator drift
% GROUNDED: TODO — unit preservation grounding
% CONNECTS TO: s(comp_nec(unlicensed(total_pieces_as_num_and_denom)))
total_pieces_as_num_and_denom(Count-frac(_,_), frac(N,D)) :-
    N is Count,
    D is Count.

test_harness:arith_misconception(db_row(37521), fraction, total_pieces_both_places,
    misconceptions_fraction_batch_4:total_pieces_as_num_and_denom,
    8-frac(1,4),
    frac(8,4)).

% === row 37549: assume division commutative ===
% Task: 1 / (1/2).
% Correct: 2
% Error: student reverses to (1/2) / 1 = 1/2
% SCHEMA: Commutativity overgeneralized
% GROUNDED: TODO — inverse-operation grounding
% CONNECTS TO: s(comp_nec(unlicensed(division_commutative)))
division_commutative(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    % student computes (N2/D2) / (N1/D1) — swap then keep-change-flip
    N is N2 * D1,
    D is D2 * N1.

test_harness:arith_misconception(db_row(37549), fraction, division_commutative,
    misconceptions_fraction_batch_4:division_commutative,
    frac(1,1)-frac(1,2),
    2).

% === row 37581: shade 3 of the shown pieces ===
% Task: shade 3/4 of pizza predivided into 8ths.
% Correct: 6 pieces (3/4 of 8 = 6).
% Error: shades 3 pieces (takes numerator literally as count).
% SCHEMA: Area model — ignores fractional relation
% GROUNDED: TODO — unit-scaling grounding
% CONNECTS TO: s(comp_nec(unlicensed(numerator_as_piece_count)))
numerator_as_piece_count(frac(N,_)-_Total, N).

test_harness:arith_misconception(db_row(37581), fraction, numerator_as_piece_count,
    misconceptions_fraction_batch_4:numerator_as_piece_count,
    frac(3,4)-8,
    6).

% === row 37588: surface symbol rewrite ===
% Task: 1/2 + 1/4, student rewrites 1/4 as 1/2.
% Correct: 3/4
% Error: 1/2 + 1/2 = 2/2
% SCHEMA: Symbol manipulation without quantity-preservation
% GROUNDED: TODO — symbol/quantity link grounding
% CONNECTS TO: s(comp_nec(unlicensed(rewrite_denominator_freely)))
rewrite_denominator_freely(frac(N1,D1)-frac(N2,_), frac(N,D)) :-
    N is N1 + N2,   % 1 + 1 = 2
    D is D1.        % 2 + 2 = 2 (forced to match)

test_harness:arith_misconception(db_row(37588), fraction, rewrite_denom_freely,
    misconceptions_fraction_batch_4:rewrite_denominator_freely,
    frac(1,2)-frac(1,4),
    frac(3,4)).

% === row 37657: denominator cannot change across wholes ===
% Task: 7 students eat 2 slices each from two 12-slice pizzas.
% Correct: 14/24
% Error: 14/12 (refuses to update denominator when the whole expands)
% SCHEMA: Referent whole — rigid denominator
% GROUNDED: TODO — whole-unit coordination grounding
% CONNECTS TO: s(comp_nec(unlicensed(rigid_denominator)))
rigid_denominator(Eaten-PerWhole-_NumWholes, frac(N,D)) :-
    N is Eaten,
    D is PerWhole.   % denominator frozen to one whole, ignores NumWholes

test_harness:arith_misconception(db_row(37657), fraction, rigid_denominator,
    misconceptions_fraction_batch_4:rigid_denominator,
    14-12-2,
    frac(14,24)).

% === row 37667: translation failure ===
test_harness:arith_misconception(db_row(37667), fraction, too_vague,
    skip, none, none).

% === row 37680: count half as whole ===
% Task: 4 whole apples and 1 half — total shares?
% Correct: 9/2 (or 4 1/2)
% Error: 5 (counts half as one whole)
% SCHEMA: Part-whole coordination
% GROUNDED: TODO — fractional count grounding
% CONNECTS TO: s(comp_nec(unlicensed(half_counted_as_whole)))
half_counted_as_whole(Wholes-Halves, Total) :-
    Total is Wholes + Halves.

test_harness:arith_misconception(db_row(37680), fraction, half_counted_as_whole,
    misconceptions_fraction_batch_4:half_counted_as_whole,
    4-1,
    frac(9,2)).

% === row 37745: context vs symbolic ===
test_harness:arith_misconception(db_row(37745), fraction, too_vague,
    skip, none, none).

% === row 37769: drew 6/9 bigger than 2/3 ===
% Task: represent 6/9 and 2/3 as equivalent bars.
% Correct: same size (6/9 = 2/3).
% Error: 6/9 drawn larger because 9 > 3 (more parts).
% SCHEMA: Numerosity-of-parts confound
% GROUNDED: TODO — whole-preservation grounding
% CONNECTS TO: s(comp_nec(unlicensed(more_parts_means_bigger)))
more_parts_means_bigger(frac(_,D1)-frac(_,D2), Bigger) :-
    (   D1 > D2
    ->  Bigger = first
    ;   D2 > D1
    ->  Bigger = second
    ;   Bigger = equal
    ).

test_harness:arith_misconception(db_row(37769), fraction, more_parts_bigger_bar,
    misconceptions_fraction_batch_4:more_parts_means_bigger,
    frac(6,9)-frac(2,3),
    equal).

% === row 37790: fractional remainder units confused ===
test_harness:arith_misconception(db_row(37790), fraction, too_vague,
    skip, none, none).

% === row 37808: idiosyncratic sharing ===
test_harness:arith_misconception(db_row(37808), fraction, too_vague,
    skip, none, none).

% === row 37823: larger denominator means larger unit fraction ===
% Task: compare 1/8 and 1/3.
% Correct: 1/3 > 1/8
% Error: 1/8 > 1/3 because 8 > 3
% SCHEMA: Whole-number ordering overgeneralized to denominators
% GROUNDED: TODO — unit-size inversion grounding
% CONNECTS TO: s(comp_nec(unlicensed(larger_denom_larger_fraction)))
larger_denom_larger_fraction(frac(N1,D1)-frac(N2,D2), Bigger) :-
    (   D1 > D2
    ->  Bigger = first
    ;   D2 > D1
    ->  Bigger = second
    ;   N1 > N2
    ->  Bigger = first
    ;   N2 > N1
    ->  Bigger = second
    ;   Bigger = equal
    ).

test_harness:arith_misconception(db_row(37823), fraction, larger_denom_bigger,
    misconceptions_fraction_batch_4:larger_denom_larger_fraction,
    frac(1,8)-frac(1,3),
    second).

% === row 37847: "two tenths" as 2 × 10 (process bug, result coincides) ===
test_harness:arith_misconception(db_row(37847), fraction, too_vague,
    skip, none, none).

% === row 37869: unequal parts ===
test_harness:arith_misconception(db_row(37869), fraction, too_vague,
    skip, none, none).

% === row 37880: whole number as fraction symbol ===
% Task: 2/4 + 1/4.
% Correct: 3/4
% Error: wrote "= 3" (writes numerator only, omits denominator)
% SCHEMA: Numerator-only notation
% GROUNDED: TODO — shared-symbol grounding
% CONNECTS TO: s(comp_nec(unlicensed(numerator_only_sum)))
numerator_only_sum(frac(N1,_)-frac(N2,_), Sum) :-
    Sum is N1 + N2.

test_harness:arith_misconception(db_row(37880), fraction, numerator_only_sum,
    misconceptions_fraction_batch_4:numerator_only_sum,
    frac(2,4)-frac(1,4),
    frac(3,4)).

% === row 37910: separate num/denom whole-number comparisons ===
% Task: compare 3/5 and 6/10.
% Correct: equal
% Error: 3/5 < 6/10 because 3 < 6 and 5 < 10 (both parts smaller)
% SCHEMA: Componentwise whole-number order
% GROUNDED: TODO — fraction-as-ratio grounding
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_order)))
componentwise_order(frac(N1,D1)-frac(N2,D2), Bigger) :-
    (   N1 < N2, D1 < D2
    ->  Bigger = second
    ;   N1 > N2, D1 > D2
    ->  Bigger = first
    ;   Bigger = undecided
    ).

test_harness:arith_misconception(db_row(37910), fraction, componentwise_order,
    misconceptions_fraction_batch_4:componentwise_order,
    frac(3,5)-frac(6,10),
    equal).

% === row 37941: multiplication always enlarges ===
test_harness:arith_misconception(db_row(37941), fraction, too_vague,
    skip, none, none).

% === row 37979: larger divisor cannot fit ===
% Task: how many 1/2's are in 1/3?
% Correct: 2/3
% Error: 0 (larger fraction "cannot fit" into smaller)
% SCHEMA: Measurement-division with whole-number fit rule
% GROUNDED: TODO — measurement-division grounding
% CONNECTS TO: s(comp_nec(unlicensed(larger_cannot_fit)))
larger_cannot_fit(frac(N1,D1)-frac(N2,D2), Q) :-
    Correct is (N1 * D2) / (D1 * N2),
    (   Correct < 1
    ->  Q = 0
    ;   Q = Correct
    ).

test_harness:arith_misconception(db_row(37979), fraction, larger_cannot_fit,
    misconceptions_fraction_batch_4:larger_cannot_fit,
    frac(1,3)-frac(1,2),
    frac(2,3)).

% === row 38057: reject valid algorithm ===
test_harness:arith_misconception(db_row(38057), fraction, too_vague,
    skip, none, none).

% === row 38126: equivalent fraction by multiplying denom and new numer ===
% Task: find missing denom for 2/5 = 4/?.
% Correct: 10
% Error: 20 (multiply old denom 5 by new numerator 4)
% SCHEMA: Cross-multiplication rule misapplied
% GROUNDED: TODO — scale-factor grounding
% CONNECTS TO: s(comp_nec(unlicensed(wrong_cross_product)))
wrong_cross_product(frac(_N1,D1)-NewN, NewD) :-
    NewD is D1 * NewN.

test_harness:arith_misconception(db_row(38126), fraction, wrong_cross_product,
    misconceptions_fraction_batch_4:wrong_cross_product,
    frac(2,5)-4,
    10).

% === row 38140: division always smaller ===
test_harness:arith_misconception(db_row(38140), fraction, too_vague,
    skip, none, none).

% === row 38221: number sentence choice ===
test_harness:arith_misconception(db_row(38221), fraction, too_vague,
    skip, none, none).

% === row 38246: disembedding ===
test_harness:arith_misconception(db_row(38246), fraction, too_vague,
    skip, none, none).

% === row 38261: equal partitioning ignored ===
test_harness:arith_misconception(db_row(38261), fraction, too_vague,
    skip, none, none).

% === row 38284: subparts named by count in fraction bar ===
% Task: subdivide 3/7 into 5 subparts each — name the subparts.
% Correct: thirty-fifths (1/35)
% Error: fifteenths (counts 15 subparts in the 3/7 bar, not in the whole)
% SCHEMA: Recursive partitioning — wrong referent unit
% GROUNDED: TODO — recursive-unit-coordination grounding
% CONNECTS TO: s(comp_nec(unlicensed(subparts_count_in_bar)))
subparts_count_in_bar(frac(N,_D)-Sub, frac(1,NewD)) :-
    NewD is N * Sub.

test_harness:arith_misconception(db_row(38284), fraction, subparts_named_in_bar,
    misconceptions_fraction_batch_4:subparts_count_in_bar,
    frac(3,7)-5,
    frac(1,35)).

% === row 38327: unshaded is not a fraction ===
test_harness:arith_misconception(db_row(38327), fraction, too_vague,
    skip, none, none).

% === row 38369: simultaneous partitioning ===
test_harness:arith_misconception(db_row(38369), fraction, too_vague,
    skip, none, none).

% === row 38394: subtract denominators ===
% Task: 5/5 + 2/5.
% Correct: 7/5
% Error: operated on denominators too — e.g., 5 + 5 or 5 - 5 in denominator
% SCHEMA: Apply operation to both num and denom
% GROUNDED: TODO — denominator-preservation grounding
% CONNECTS TO: s(comp_nec(unlicensed(operate_on_denominators)))
operate_on_denominators(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2.

test_harness:arith_misconception(db_row(38394), fraction, operate_on_denominators,
    misconceptions_fraction_batch_4:operate_on_denominators,
    frac(5,5)-frac(2,5),
    frac(7,5)).

% === row 38406: benchmark failure ===
test_harness:arith_misconception(db_row(38406), fraction, too_vague,
    skip, none, none).

% === row 38434: missing factor geometric ===
test_harness:arith_misconception(db_row(38434), fraction, too_vague,
    skip, none, none).

% === row 38455: whole shaded for 1/6 ===
% Task: draw 1/6 of a circle.
% Correct: one of six equal parts shaded (frac(1,6)).
% Error: shades all six (treats "one sixth" as one-whole-of-six-pieces).
% SCHEMA: Unit fraction = the whole partition
% GROUNDED: TODO — unit-fraction grounding
% CONNECTS TO: s(comp_nec(unlicensed(whole_as_unit_fraction)))
whole_as_unit_fraction(frac(_,D), frac(N,D2)) :-
    N is D,
    D2 is D.

test_harness:arith_misconception(db_row(38455), fraction, whole_as_unit_fraction,
    misconceptions_fraction_batch_4:whole_as_unit_fraction,
    frac(1,6),
    frac(1,6)).

% === row 38492: discrete fractions ===
test_harness:arith_misconception(db_row(38492), fraction, too_vague,
    skip, none, none).

% === row 38558: improper fraction flipped ===
% Task: draw 6/5 of a unit.
% Correct: frac(6,5)
% Error: drew 5/6 (swapped since denom "cannot" be smaller)
% SCHEMA: Part-whole rigidity
% GROUNDED: TODO — improper-fraction grounding
% CONNECTS TO: s(comp_nec(unlicensed(swap_num_denom_for_proper)))
swap_num_denom_for_proper(frac(N,D), frac(Nout,Dout)) :-
    (   N > D
    ->  Nout = D, Dout = N
    ;   Nout = N, Dout = D
    ).

test_harness:arith_misconception(db_row(38558), fraction, swap_for_proper,
    misconceptions_fraction_batch_4:swap_num_denom_for_proper,
    frac(6,5),
    frac(6,5)).

% === row 38574: multiplicative as additive spaces ===
test_harness:arith_misconception(db_row(38574), fraction, too_vague,
    skip, none, none).

% === row 38648: cross-cut leftover items ===
test_harness:arith_misconception(db_row(38648), fraction, too_vague,
    skip, none, none).

% === row 38664: unit conflation under iteration ===
% Task: iterate 6-unit segment 4 times to make 24-unit — name the 6-segment.
% Correct: 1/4 of the 24-unit segment
% Error: 6/4 (uses segment length 6 as numerator, iteration count 4 as denom)
% SCHEMA: Iteration count as denominator, length as numerator
% GROUNDED: TODO — recursive-partitioning grounding
% CONNECTS TO: s(comp_nec(unlicensed(length_over_iteration_count)))
length_over_iteration_count(Length-Iterations, frac(N,D)) :-
    N is Length,
    D is Iterations.

test_harness:arith_misconception(db_row(38664), fraction, length_over_iterations,
    misconceptions_fraction_batch_4:length_over_iteration_count,
    6-4,
    frac(1,4)).

% === row 38679: second fraction of whole, not first ===
% Task: 2/3 of 3/4 of the class.
% Correct: frac(6,12) = 1/2 of the class
% Error: treats 2/3 as of the whole class, ignoring "of 3/4"
% SCHEMA: Compound fraction referent-whole drift
% GROUNDED: TODO — referent-whole coordination grounding
% CONNECTS TO: s(comp_nec(unlicensed(second_of_whole_not_first)))
second_of_whole_not_first(frac(N1,D1)-frac(_N2,_D2), frac(N1,D1)).

test_harness:arith_misconception(db_row(38679), fraction, second_of_whole_not_first,
    misconceptions_fraction_batch_4:second_of_whole_not_first,
    frac(2,3)-frac(3,4),
    frac(6,12)).

% === row 38717: partition given bar by denominator ===
% Task: given bar is 4/5 of a whole — construct the whole.
% Correct: bar extended to 5/4 of itself (add 1/4 of the bar's length).
% Error: partition the given bar into 5 parts (reads denom as partition count
% of the given bar).
% SCHEMA: Reversible partitive reasoning breakdown
% GROUNDED: TODO — reversible-partition grounding
% CONNECTS TO: s(comp_nec(unlicensed(partition_given_by_denominator)))
partition_given_by_denominator(frac(_,D), Partitions) :-
    Partitions = D.

test_harness:arith_misconception(db_row(38717), fraction, partition_given_by_denom,
    misconceptions_fraction_batch_4:partition_given_by_denominator,
    frac(4,5),
    frac(5,4)).

% === row 38789: unshaded is nothing ===
test_harness:arith_misconception(db_row(38789), fraction, too_vague,
    skip, none, none).

% === row 38837: count parts twice — 2/3 as 2/5 ===
% Task: identify 2/3 representation.
% Correct: frac(2,3) — 2 of 3 parts total.
% Error: picks 2/5 — counts the 2 separately and 3 unshaded separately (2+3=5).
% SCHEMA: Inclusion failure — parts counted twice
% GROUNDED: TODO — part-whole inclusion grounding
% CONNECTS TO: s(comp_nec(unlicensed(count_parts_twice)))
count_parts_twice(frac(N,D), frac(N,DOut)) :-
    DOut is N + D.   % shaded and unshaded counted separately

test_harness:arith_misconception(db_row(38837), fraction, count_parts_twice,
    misconceptions_fraction_batch_4:count_parts_twice,
    frac(2,3),
    frac(2,3)).

% === row 38857: count cuts as parts ===
test_harness:arith_misconception(db_row(38857), fraction, too_vague,
    skip, none, none).

% === row 38922: division equals multiplication ===
% Task: 1/3 ÷ 1/2.
% Correct: 2/3
% Error: student tries 1/2 × 1/3 = 1/6 and concludes operations are the same.
% SCHEMA: Operation conflation
% GROUNDED: TODO — operation-distinction grounding
% CONNECTS TO: s(comp_nec(unlicensed(div_as_mul)))
div_as_mul(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 * N2,
    D is D1 * D2.

test_harness:arith_misconception(db_row(38922), fraction, div_as_mul,
    misconceptions_fraction_batch_4:div_as_mul,
    frac(1,3)-frac(1,2),
    frac(2,3)).

% === row 38972: natural number bias addition ===
% Task: 2/3 + 3/5.
% Correct: 19/15
% Error: 5/8 (add numerators, add denominators)
% SCHEMA: Componentwise addition
% GROUNDED: TODO — common-denominator grounding
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_addition)))
componentwise_addition(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2.

test_harness:arith_misconception(db_row(38972), fraction, componentwise_addition,
    misconceptions_fraction_batch_4:componentwise_addition,
    frac(2,3)-frac(3,5),
    frac(19,15)).

% === row 38987: fractions strictly as objects ===
test_harness:arith_misconception(db_row(38987), fraction, too_vague,
    skip, none, none).

% === row 39039: contextual fraction comparison ===
test_harness:arith_misconception(db_row(39039), fraction, too_vague,
    skip, none, none).

% === row 39089: gap thinking — "same because each has one left" ===
% Task: compare 5/6 and 7/8.
% Correct: 7/8 > 5/6 (cross product: 40 vs 42 → second larger)
% Error: equal, because both have gap of 1 (same leftover).
% SCHEMA: Absolute difference as magnitude
% GROUNDED: TODO — ratio grounding
% CONNECTS TO: s(comp_nec(unlicensed(gap_thinking)))
gap_thinking(frac(N1,D1)-frac(N2,D2), Verdict) :-
    G1 is D1 - N1,
    G2 is D2 - N2,
    (   G1 < G2
    ->  Verdict = first_larger
    ;   G2 < G1
    ->  Verdict = second_larger
    ;   Verdict = equal
    ).

test_harness:arith_misconception(db_row(39089), fraction, gap_thinking,
    misconceptions_fraction_batch_4:gap_thinking,
    frac(5,6)-frac(7,8),
    second_larger).

% === row 39135: pie part model — fractions as two numbers ===
test_harness:arith_misconception(db_row(39135), fraction, too_vague,
    skip, none, none).

% === row 39169: unit fraction distinction ===
test_harness:arith_misconception(db_row(39169), fraction, too_vague,
    skip, none, none).

% === row 39193: adjusting unfair shares ===
test_harness:arith_misconception(db_row(39193), fraction, too_vague,
    skip, none, none).

% === row 39274: continuous to discrete mapping failure ===
test_harness:arith_misconception(db_row(39274), fraction, too_vague,
    skip, none, none).

% === row 39348: select multiplication instead of division ===
% Task: 3/5 ÷ 1/20 (problem calls for division).
% Correct: frac(60,5) (= 12)
% Error: student wrote 3/5 × 1/20 = 3/100
% SCHEMA: Operation selection from surface cues
% GROUNDED: TODO — operation-selection grounding
% CONNECTS TO: s(comp_nec(unlicensed(mul_instead_of_div)))
mul_instead_of_div(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 * N2,
    D is D1 * D2.

test_harness:arith_misconception(db_row(39348), fraction, mul_instead_of_div,
    misconceptions_fraction_batch_4:mul_instead_of_div,
    frac(3,5)-frac(1,20),
    frac(60,5)).

% === row 39432: divide both ways, pick easier quotient ===
% Task: partitive — share 4 pizzas among 7 people.
% Correct: 4/7 per person (about 0.571).
% Error: divides both ways, picks the one that "looks easier" (>= 1).
%   7/4 = 1.75 is picked even though the correct direction is 4/7.
% SCHEMA: Partitive direction
% GROUNDED: TODO — partitive-division grounding
% CONNECTS TO: s(comp_nec(unlicensed(pick_easier_quotient)))
pick_easier_quotient(A-B, Q) :-
    Q1 is A / B,
    Q2 is B / A,
    (   Q1 >= 1
    ->  Q = Q1
    ;   Q = Q2
    ).

test_harness:arith_misconception(db_row(39432), fraction, pick_easier_quotient,
    misconceptions_fraction_batch_4:pick_easier_quotient,
    4-7,
    frac(4,7)).

% === row 39471: fraction less than whole ===
test_harness:arith_misconception(db_row(39471), fraction, too_vague,
    skip, none, none).

% === row 39559: division always smaller ===
test_harness:arith_misconception(db_row(39559), fraction, too_vague,
    skip, none, none).

% === row 39604: denominator as group size ===
% Task: find 1/3 of 12 objects.
% Correct: 4
% Error: 3 (interprets denominator as number in each group)
% SCHEMA: Denominator-as-group-size confusion
% GROUNDED: TODO — fractions-of-discrete grounding
% CONNECTS TO: s(comp_nec(unlicensed(denominator_as_group_size)))
denominator_as_group_size(frac(_,D)-_Set, Count) :-
    Count is D.

test_harness:arith_misconception(db_row(39604), fraction, denom_as_group_size,
    misconceptions_fraction_batch_4:denominator_as_group_size,
    frac(1,3)-12,
    4).

% === row 39639: whole number interference comparing ===
test_harness:arith_misconception(db_row(39639), fraction, too_vague,
    skip, none, none).

% === row 39654: linear model partition without equal parts ===
test_harness:arith_misconception(db_row(39654), fraction, too_vague,
    skip, none, none).

% === row 39694: add across unlike denominators ===
% Task: 1/5 + 2/3.
% Correct: 13/15
% Error: 3/8 (adds numerators and denominators)
% SCHEMA: Componentwise addition (unlike denominators)
% GROUNDED: TODO — common-denominator grounding
% CONNECTS TO: s(comp_nec(unlicensed(add_across_unlike)))
add_across_unlike(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2.

test_harness:arith_misconception(db_row(39694), fraction, add_across_unlike,
    misconceptions_fraction_batch_4:add_across_unlike,
    frac(1,5)-frac(2,3),
    frac(13,15)).

% === row 39722: add 2/3 + 1/4 = 3/7 ===
% Task: 2/3 + 1/4.
% Correct: 11/12
% Error: 3/7 (componentwise)
% SCHEMA: Componentwise addition
% GROUNDED: TODO — common-denominator grounding
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_add_3_7)))
componentwise_add_3_7(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2.

test_harness:arith_misconception(db_row(39722), fraction, componentwise_add_simple,
    misconceptions_fraction_batch_4:componentwise_add_3_7,
    frac(2,3)-frac(1,4),
    frac(11,12)).

% === row 39766: multiply numerators, keep like denom ===
% Task: 4/7 × 3/7.
% Correct: 12/49
% Error: 12/7 (multiplies numerators, leaves common denominator)
% SCHEMA: Same-denominator addition overgeneralized to multiplication
% GROUNDED: TODO — multiplication-denominator grounding
% CONNECTS TO: s(comp_nec(unlicensed(mul_keep_denom)))
mul_keep_denom(frac(N1,D)-frac(N2,D), frac(N,D)) :-
    N is N1 * N2.

test_harness:arith_misconception(db_row(39766), fraction, mul_keep_common_denom,
    misconceptions_fraction_batch_4:mul_keep_denom,
    frac(4,7)-frac(3,7),
    frac(12,49)).

% === row 39773: unit-rate sharing must be multiplication ===
test_harness:arith_misconception(db_row(39773), fraction, too_vague,
    skip, none, none).

% === row 39812: unit fraction of discrete as denominator ===
% Task: one third of 12.
% Correct: 4
% Error: 3 (answers with denominator literally)
% SCHEMA: Denominator-as-answer
% GROUNDED: TODO — fraction-of-set grounding
% CONNECTS TO: s(comp_nec(unlicensed(denominator_as_answer)))
denominator_as_answer(frac(_,D)-_Set, Answer) :-
    Answer is D.

test_harness:arith_misconception(db_row(39812), fraction, denom_as_answer,
    misconceptions_fraction_batch_4:denominator_as_answer,
    frac(1,3)-12,
    4).

% === row 39819: mixed fraction whole parts omitted ===
test_harness:arith_misconception(db_row(39819), fraction, too_vague,
    skip, none, none).

% === row 39844: independent whole-number operations with weird scaling ===
test_harness:arith_misconception(db_row(39844), fraction, too_vague,
    skip, none, none).

% === row 39891: sort by smallest difference ===
% Task: identify the "smallest" among given fractions.
% Correct: requires comparing magnitudes.
% Error: picks fraction with smallest D-N gap (same family as gap thinking).
% SCHEMA: Gap sort
% GROUNDED: TODO — ratio grounding
% CONNECTS TO: s(comp_nec(unlicensed(sort_by_gap)))
sort_by_gap(Fracs, Smallest) :-
    maplist([frac(N,D), G-frac(N,D)]>>(G is D - N), Fracs, Pairs),
    keysort(Pairs, Sorted),
    Sorted = [_-Smallest|_].

test_harness:arith_misconception(db_row(39891), fraction, sort_by_gap,
    misconceptions_fraction_batch_4:sort_by_gap,
    [frac(5,6), frac(1,2), frac(2,3)],
    frac(1,2)).

% === row 39949: unit fraction comparison reasoning ===
test_harness:arith_misconception(db_row(39949), fraction, too_vague,
    skip, none, none).

% === row 40049: keyword-triggered procedure ===
test_harness:arith_misconception(db_row(40049), fraction, too_vague,
    skip, none, none).

% === row 40084: improper as needing "fixing" ===
test_harness:arith_misconception(db_row(40084), fraction, too_vague,
    skip, none, none).

% === row 40112: how-many vs how-much ===
% Task: share 4 pizzas equally among 5 people.
% Correct: 4/5 of a pizza each.
% Error: "4 pieces" — number of pieces rather than fractional amount.
% SCHEMA: Pieces-count instead of fractional share
% GROUNDED: TODO — how-much referent grounding
% CONNECTS TO: s(comp_nec(unlicensed(pieces_instead_of_fraction)))
pieces_instead_of_fraction(Objects-_People, Count) :-
    Count is Objects.  % student reports raw count of pieces

test_harness:arith_misconception(db_row(40112), fraction, pieces_instead_of_fraction,
    misconceptions_fraction_batch_4:pieces_instead_of_fraction,
    4-5,
    frac(4,5)).

% === row 40119: condensed explanation ===
test_harness:arith_misconception(db_row(40119), fraction, too_vague,
    skip, none, none).

% === row 40135: alt algorithm rejected ===
test_harness:arith_misconception(db_row(40135), fraction, too_vague,
    skip, none, none).

% === row 40148: iterating seen as multiplication ===
test_harness:arith_misconception(db_row(40148), fraction, too_vague,
    skip, none, none).

% === row 40178: teacher misinterprets student ===
test_harness:arith_misconception(db_row(40178), fraction, too_vague,
    skip, none, none).

% === row 40196: PST projection ===
test_harness:arith_misconception(db_row(40196), fraction, too_vague,
    skip, none, none).

% === row 40216: procedural taken as conceptual ===
test_harness:arith_misconception(db_row(40216), fraction, too_vague,
    skip, none, none).

% === row 40257: dividend and divisor drawn separately ===
test_harness:arith_misconception(db_row(40257), fraction, too_vague,
    skip, none, none).

% === row 40285: add numerators and denominators ===
% Task: 1/4 + 1/16.
% Correct: 5/16
% Error: 2/20 (add numerators and denominators)
% SCHEMA: Componentwise addition
% GROUNDED: TODO — common-denominator grounding
% CONNECTS TO: s(comp_nec(unlicensed(add_num_denom_1_4_1_16)))
add_num_denom_1_4_1_16(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2.

test_harness:arith_misconception(db_row(40285), fraction, add_num_and_denom_unlike,
    misconceptions_fraction_batch_4:add_num_denom_1_4_1_16,
    frac(1,4)-frac(1,16),
    frac(5,16)).

% === row 40370: reversible iterative fraction scheme ===
test_harness:arith_misconception(db_row(40370), fraction, too_vague,
    skip, none, none).

% === row 40381: equivalent by multiplying numerator and denominator of original ===
% Task: 6/9 = ?/18. Find missing numerator.
% Correct: 12 (scale by 2)
% Error: 54 (multiplies given numerator 6 by given denominator 9)
% SCHEMA: Equivalent-fraction procedure misapplication
% GROUNDED: TODO — scale-factor grounding
% CONNECTS TO: s(comp_nec(unlicensed(mul_orig_num_denom)))
mul_orig_num_denom(frac(N,D)-_NewD, MissingN) :-
    MissingN is N * D.

test_harness:arith_misconception(db_row(40381), fraction, mul_orig_num_denom,
    misconceptions_fraction_batch_4:mul_orig_num_denom,
    frac(6,9)-18,
    12).

% === row 40441: larger distance means smaller fraction ===
% Task: compare 1/2 and 5/8.
% Correct: 5/8 > 1/2 (5*2=10 vs 1*8=8).
% Error: 1/2 has larger D-N gap (3) than 5/8 (3) ... same — pick a clearer
% example: 1/4 vs 5/6 — gaps 3 vs 1, student says 1/4 is smaller because
% the gap is larger (matches correct); but for 2/3 (gap 1) vs 5/8 (gap 3),
% student says 5/8 is smaller, while actually 5/8 > 2/3 (15 vs 16, so 2/3
% larger; hmm 15<16 → 5/8 is actually smaller). We use a case where the bug
% flips the correct order: 3/4 (gap 1) vs 1/2 (gap 1) tied; use 5/7 (gap 2)
% vs 1/2 (gap 1) — correct: 5/7 ≈ 0.714 > 1/2; bug: first has larger gap so
% "smaller" = first.
% SCHEMA: Distance-based ordering
% GROUNDED: TODO — ratio grounding
% CONNECTS TO: s(comp_nec(unlicensed(sort_by_distance_larger_means_smaller)))
sort_by_distance_larger_smaller(frac(N1,D1)-frac(N2,D2), Smaller) :-
    Dist1 is D1 - N1,
    Dist2 is D2 - N2,
    (   Dist1 > Dist2
    ->  Smaller = first
    ;   Dist2 > Dist1
    ->  Smaller = second
    ;   Smaller = equal
    ).

test_harness:arith_misconception(db_row(40441), fraction, sort_by_distance,
    misconceptions_fraction_batch_4:sort_by_distance_larger_smaller,
    frac(5,7)-frac(1,2),
    second).

% === row 40454: add numerators and denominators (estimate) ===
% Task: 4/5 + 6/7.
% Correct: 58/35 (near 1.66, "close to 2")
% Error: 10/12 (componentwise), "close to 1"
% SCHEMA: Componentwise addition with magnitude inference
% GROUNDED: TODO — common-denominator grounding
% CONNECTS TO: s(comp_nec(unlicensed(componentwise_estimate)))
componentwise_estimate(frac(N1,D1)-frac(N2,D2), frac(N,D)) :-
    N is N1 + N2,
    D is D1 + D2.

test_harness:arith_misconception(db_row(40454), fraction, componentwise_estimate,
    misconceptions_fraction_batch_4:componentwise_estimate,
    frac(4,5)-frac(6,7),
    frac(58,35)).

% === row 40482: tangram pieces as equal fractions ===
test_harness:arith_misconception(db_row(40482), fraction, too_vague,
    skip, none, none).

% === row 40496: 3/4 ÷ 1/2 yields 6/8 ===
% Task: 3/4 ÷ 1/2.
% Correct: 3/2 (or 1.5)
% Error: 6/8 — model shades 3/4, cuts in half, reads 6 of 8.
% SCHEMA: Area model miscounting in division
% GROUNDED: TODO — division-as-measurement grounding
% CONNECTS TO: s(comp_nec(unlicensed(area_model_miscount_div)))
area_model_miscount_div(frac(N1,D1)-frac(_N2,D2), frac(N,D)) :-
    N is N1 * D2,
    D is D1 * D2.

test_harness:arith_misconception(db_row(40496), fraction, area_model_miscount_div,
    misconceptions_fraction_batch_4:area_model_miscount_div,
    frac(3,4)-frac(1,2),
    frac(3,2)).

% === row 40586: subtract 7/8 from 4 1/8 without regrouping ===
test_harness:arith_misconception(db_row(40586), fraction, too_vague,
    skip, none, none).

% === row 40661: differently-shaped halves equal? ===
test_harness:arith_misconception(db_row(40661), fraction, too_vague,
    skip, none, none).
