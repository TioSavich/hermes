:- module(misconceptions_measurement_batch_1, []).
% Measurement misconceptions — research corpus batch 1/2.
% Native arithmetic layer only. Theoretical annotations as comments:
%   % GROUNDED: TODO
%   % SCHEMA: Container / Measuring Stick / etc.
%   % CONNECTS TO: s(comp_nec(unlicensed(...)))
%
% Registration convention (from Task 3 arch fix):
%   test_harness:arith_misconception(Source, measurement, Description,
%       misconceptions_measurement_batch_1:rule_name, Input, Expected).
% Rule predicates do NOT go on the module export list.

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

% ---- Encodings appended by agent for measurement batch 1 ----

% === row 37528: count perimeter squares when asked for area ===
% Task: area of a rectangle on a grid, W=5,H=3 -> area = 15
% Correct: 15 (W*H)
% Error: counts boundary squares -> uses 2*(W+H)-4 or 2*(W+H); we use 2*(W+H) = 16
% SCHEMA: Container (area) confused with Measuring Stick (length around)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(area_as_perimeter_count)))
r37528_area_as_perimeter(rect(W,H), Got) :-
    Got is 2*(W+H).

test_harness:arith_misconception(db_row(37528), measurement, area_as_perimeter_count,
    misconceptions_measurement_batch_1:r37528_area_as_perimeter,
    rect(5,3), 15).

% === row 37565: area=inside / perimeter=outside rote definition ===
test_harness:arith_misconception(db_row(37565), measurement, too_vague,
    skip, none, none).

% === row 37567: haphazard guessing of operation ===
test_harness:arith_misconception(db_row(37567), measurement, too_vague,
    skip, none, none).

% === row 37627: cover 30x40 with 2x2 by adding sides and dividing ===
% Task: number of 2x2 tiles to cover 30x40 rectangle
% Correct: (30*40)/(2*2) = 300
% Error: (30+40)/2 = 35 (treats 2D covering as 1D sum)
% SCHEMA: Measuring Stick applied where Container is required
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(cover_by_sum_of_sides)))
r37627_cover_by_sum(cover(W-H, TW-_TH), Got) :-
    Got is (W+H) // TW.

test_harness:arith_misconception(db_row(37627), measurement, cover_by_sum_not_product,
    misconceptions_measurement_batch_1:r37627_cover_by_sum,
    cover(30-40, 2-2), 300).

% === row 37712: clock hands non-proportional (hour hand jumps) ===
test_harness:arith_misconception(db_row(37712), measurement, too_vague,
    skip, none, none).

% === row 37716: misinterpret scale on graph/figure ===
test_harness:arith_misconception(db_row(37716), measurement, too_vague,
    skip, none, none).

% === row 37782: blind word-problem arithmetic ignoring remainders ===
% Task: how many 1 m planks from four 2.5 m planks? Only whole planks count.
% Correct: 4 * floor(2.5) = 4 * 2 = 8
% Error: 4 * 2.5 = 10 (treats as continuous quantity)
% SCHEMA: Arithmetic is Symbolic Manipulation (ignore physical constraint)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(blind_arithmetic_no_remainders)))
r37782_ignore_remainders(planks(N, Each, Target), Got) :-
    Got is N * (Each / Target).

test_harness:arith_misconception(db_row(37782), measurement, ignore_physical_remainders,
    misconceptions_measurement_batch_1:r37782_ignore_remainders,
    planks(4, 2.5, 1), 8).

% === row 37824: map scale with unfamiliar idiom ===
test_harness:arith_misconception(db_row(37824), measurement, too_vague,
    skip, none, none).

% === row 37844: rigid reliance on school-taught algorithm ===
test_harness:arith_misconception(db_row(37844), measurement, too_vague,
    skip, none, none).

% === row 38035: obscured ruler requires reading numerals ===
test_harness:arith_misconception(db_row(38035), measurement, too_vague,
    skip, none, none).

% === row 38052: lateral vs total surface area vocabulary ===
test_harness:arith_misconception(db_row(38052), measurement, too_vague,
    skip, none, none).

% === row 38179: diagram runs out of space ===
test_harness:arith_misconception(db_row(38179), measurement, too_vague,
    skip, none, none).

% === row 38269: remainder treated as unmeasurable ===
% Task: how many B-units in a 13 A-unit beam, if B = 4 A-units?
% Correct: 13/4 = 3.25 (fractional B-units)
% Error: 0 ("4 times nothing equals 13", can't fit -> unmeasurable)
% SCHEMA: Measuring Stick (unit as rigid object, no partitioning)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(remainder_is_unmeasurable)))
r38269_remainder_unmeasurable(beam(Len, Unit), Got) :-
    ( Len mod Unit =:= 0
    -> Got is Len // Unit
    ;  Got = 0
    ).

test_harness:arith_misconception(db_row(38269), measurement, remainder_as_unmeasurable,
    misconceptions_measurement_batch_1:r38269_remainder_unmeasurable,
    beam(13, 4), 3.25).

% === row 38337: can't assemble area from composite units ===
test_harness:arith_misconception(db_row(38337), measurement, too_vague,
    skip, none, none).

% === row 38493: paper too thin to measure ===
test_harness:arith_misconception(db_row(38493), measurement, too_vague,
    skip, none, none).

% === row 38583: linear ratio used for square-tile area ratio ===
% Task: how many times larger is an 8-inch square tile than a 4-inch square tile?
% Correct: (8*8)/(4*4) = 4
% Error: 8/4 = 2 (linear ratio, ignoring quadratic scaling)
% SCHEMA: Container (area) scaled as Measuring Stick (length)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(linear_scaling_for_area)))
r38583_linear_area_ratio(side(Big)-side(Small), Got) :-
    Got is Big / Small.

test_harness:arith_misconception(db_row(38583), measurement, linear_scaling_for_area,
    misconceptions_measurement_batch_1:r38583_linear_area_ratio,
    side(8)-side(4), 4).

% === row 38634: map-scale area uses linear factor (no squaring) ===
% Task: region has area 5 (cm^2) on map; scale 1 cm = 1000 km. Real area in km^2?
% Correct: 5 * 1000 * 1000 = 5_000_000
% Error: 5 * 1000 = 5000 (linear scale factor applied once)
% SCHEMA: Container (area) scaled by Measuring Stick (length)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(linear_factor_for_area_scale)))
r38634_area_scale_linear(map_area(A, scale(S)), Got) :-
    Got is A * S.

test_harness:arith_misconception(db_row(38634), measurement, linear_factor_for_area_scaling,
    misconceptions_measurement_batch_1:r38634_area_scale_linear,
    map_area(5, scale(1000)), 5000000).

% === row 38636: number line numerals as discrete counts ===
test_harness:arith_misconception(db_row(38636), measurement, too_vague,
    skip, none, none).

% === row 38676: tiling with gaps/overlaps ===
test_harness:arith_misconception(db_row(38676), measurement, too_vague,
    skip, none, none).

% === row 38689: base-10 subtraction applied to time (7:08 - 2:53) ===
% Task: elapsed time from 2:53 to 7:08 -> 4h 15m
% Correct: hours(4,15)
% Error: 7:08 - 2:53 with base-10 borrow (1h -> 100m): 4h 55m
% SCHEMA: Mixed-base Measuring Stick collapsed onto base-10 stick
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(base10_regroup_on_time)))
r38689_time_base10(hours(H1,M1)-hours(H2,M2), Got) :-
    ( M1 >= M2
    -> DM is M1 - M2, DH is H1 - H2
    ;  DM is (M1 + 100) - M2, DH is H1 - H2 - 1
    ),
    Got = hours(DH, DM).

test_harness:arith_misconception(db_row(38689), measurement, time_regrouped_base_ten,
    misconceptions_measurement_batch_1:r38689_time_base10,
    hours(7,8)-hours(2,53), hours(4,15)).

% === row 38929: refusal to multiply mixed-unit numbers ===
test_harness:arith_misconception(db_row(38929), measurement, too_vague,
    skip, none, none).

% === row 38992: area labeled with linear units ===
% Task: area of 16x8 rectangle
% Correct: sq_cm(128)
% Error: cm(128) (linear unit label)
% SCHEMA: Container mislabeled with Measuring Stick unit
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(area_in_linear_units)))
r38992_area_as_linear(rect(W,H), Got) :-
    A is W * H,
    Got = cm(A).

test_harness:arith_misconception(db_row(38992), measurement, area_labeled_linear,
    misconceptions_measurement_batch_1:r38992_area_as_linear,
    rect(16,8), sq_cm(128)).

% === row 38994: reading '6 m^2' as '6 meters squared' ===
test_harness:arith_misconception(db_row(38994), measurement, too_vague,
    skip, none, none).

% === row 39002: increasing perimeter increases area ===
test_harness:arith_misconception(db_row(39002), measurement, too_vague,
    skip, none, none).

% === row 39004: parallelogram deformation and area conservation ===
test_harness:arith_misconception(db_row(39004), measurement, too_vague,
    skip, none, none).

% === row 39160: area via counting units, fails for algebraic sides ===
test_harness:arith_misconception(db_row(39160), measurement, too_vague,
    skip, none, none).

% === row 39392: "8' 1/2\"" read as 8.5 feet instead of 8 ft 1/2 in ===
% Task: convert imperial(feet=8, num=1, den=2) = 8 ft + 1/2 in to decimal feet
% Correct: 8 + (1/2)/12 = 8.041666...
% Error: reads as 8.5 feet (treats the fraction as fraction-of-foot)
% SCHEMA: Measuring Stick notation collapsed (foot and inch not distinguished)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(imperial_notation_collapse)))
r39392_imperial_collapse(imperial(Ft, Num, Den), Got) :-
    Got is Ft + Num / Den.

test_harness:arith_misconception(db_row(39392), measurement, imperial_half_as_half_foot,
    misconceptions_measurement_batch_1:r39392_imperial_collapse,
    imperial(8, 1, 2), 8.041666666666666).

% === row 39482: more points on longer segment ===
test_harness:arith_misconception(db_row(39482), measurement, too_vague,
    skip, none, none).

% === row 39527: angle measure only as formula artifact ===
test_harness:arith_misconception(db_row(39527), measurement, too_vague,
    skip, none, none).

% === row 39592: teacher can't handle irregular area ===
test_harness:arith_misconception(db_row(39592), measurement, too_vague,
    skip, none, none).

% === row 39597: unequal action-units for area ===
test_harness:arith_misconception(db_row(39597), measurement, too_vague,
    skip, none, none).

% === row 39599: mixes larger/smaller unit rods ===
test_harness:arith_misconception(db_row(39599), measurement, too_vague,
    skip, none, none).

% === row 39610: Zeno's paradox / infinite-spatial model of finite-temporal ===
test_harness:arith_misconception(db_row(39610), measurement, too_vague,
    skip, none, none).

% === row 39655: incomplete / inconsistent covering ===
test_harness:arith_misconception(db_row(39655), measurement, too_vague,
    skip, none, none).

% === row 39662: linear factor used for cubic unit conversion ===
% Task: how many cm^3 in 1 m^3?
% Correct: 1_000_000
% Error: 100 (uses linear cm-per-m factor, not cubed)
% SCHEMA: Container^3 scaled as Measuring Stick (length)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(linear_factor_for_volume_scale)))
r39662_volume_linear_conv(conv(V, m3, cm3), Got) :-
    Got is V * 100.

test_harness:arith_misconception(db_row(39662), measurement, linear_factor_for_volume,
    misconceptions_measurement_batch_1:r39662_volume_linear_conv,
    conv(1, m3, cm3), 1000000).

% === row 39664: superficial unit conversion (concrete->liquid, mass, etc.) ===
test_harness:arith_misconception(db_row(39664), measurement, too_vague,
    skip, none, none).

% === row 39803: SI-unit coherence failure ===
test_harness:arith_misconception(db_row(39803), measurement, too_vague,
    skip, none, none).

% === row 39983: decimal on ruler read as identifier ===
test_harness:arith_misconception(db_row(39983), measurement, too_vague,
    skip, none, none).

% === row 40042: area-cut problem: quotients of L/l, W/w but no multiply ===
% Task: from L=W=100 mm, cut cards of l=w=10 mm; how many cards?
% Correct: (L/l) * (W/w) = 10 * 10 = 100
% Error: stops at L/l = 10 (linear answer)
% SCHEMA: Container (area) reduced to Measuring Stick (length)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(dimensional_collapse_area_to_linear)))
r40042_linear_cut(cut(L-_W, LL-_WW), Got) :-
    Got is L // LL.

test_harness:arith_misconception(db_row(40042), measurement, area_cut_without_multiplying,
    misconceptions_measurement_batch_1:r40042_linear_cut,
    cut(100-100, 10-10), 100).

% === row 40098: reducing smallest dim for smallest delta-volume ===
test_harness:arith_misconception(db_row(40098), measurement, too_vague,
    skip, none, none).

% === row 40173: productive abstraction (not a misconception) ===
test_harness:arith_misconception(db_row(40173), measurement, too_vague,
    skip, none, none).

% === row 40224: angle measure as unit-less ratio ===
test_harness:arith_misconception(db_row(40224), measurement, too_vague,
    skip, none, none).

% === row 40253: iterating past tool end ===
test_harness:arith_misconception(db_row(40253), measurement, too_vague,
    skip, none, none).

% === row 40281: trig conceptual clash (angle vs ratio) ===
test_harness:arith_misconception(db_row(40281), measurement, too_vague,
    skip, none, none).

% === row 40355: estimation with no real-world anchor ===
test_harness:arith_misconception(db_row(40355), measurement, too_vague,
    skip, none, none).

% === row 40363: rote formulas, no decomposition of compound figures ===
test_harness:arith_misconception(db_row(40363), measurement, too_vague,
    skip, none, none).

% === row 40493: area as square of mean of sides ===
% Task: area of 22 x 28 rectangle
% Correct: 22 * 28 = 616
% Error: ((22+28)/2)^2 = 25^2 = 625
% SCHEMA: Perimeter symmetry mis-exported to Container (area)
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(mean_squared_as_area)))
r40493_mean_squared(rect(W,H), Got) :-
    M is (W + H) / 2,
    Got is M * M.

test_harness:arith_misconception(db_row(40493), measurement, mean_of_sides_squared,
    misconceptions_measurement_batch_1:r40493_mean_squared,
    rect(22,28), 616).

% === row 40603: double-counting cubes on multiple faces ===
test_harness:arith_misconception(db_row(40603), measurement, too_vague,
    skip, none, none).

% === row 40609: discrete-bead vs interval-boundary marking ===
test_harness:arith_misconception(db_row(40609), measurement, too_vague,
    skip, none, none).

% === row 40639: cannot mentally truncate tool past object ===
test_harness:arith_misconception(db_row(40639), measurement, too_vague,
    skip, none, none).

% === row 40641: counts hashmarks instead of intervals ===
% Task: spatial gap between two numbers A and B on a measurement strip
% Correct: |B - A|  (number of intervals)
% Error: |B - A| + 1 (counts hash marks)
% SCHEMA: Measuring Stick read as discrete counter
% GROUNDED: TODO
% CONNECTS TO: s(comp_nec(unlicensed(count_marks_not_intervals)))
r40641_count_marks(gap(A,B), Got) :-
    D is abs(B - A),
    Got is D + 1.

test_harness:arith_misconception(db_row(40641), measurement, count_marks_not_intervals,
    misconceptions_measurement_batch_1:r40641_count_marks,
    gap(2,5), 3).
