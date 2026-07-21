:- module(misconceptions_measurement_batch_2, []).
% Measurement misconceptions — research corpus batch 2/2.
% Native arithmetic layer only. Theoretical annotations as comments:
%   % GROUNDED: TODO
%   % SCHEMA: Container / Measuring Stick / etc.
%   % CONNECTS TO: s(comp_nec(unlicensed(...)))
%
% Registration convention (from Task 3 arch fix):
%   test_harness:arith_misconception(Source, measurement, Description,
%       misconceptions_measurement_batch_2:rule_name, Input, Expected).
% Rule predicates do NOT go on the module export list.

:- multifile test_harness:arith_misconception/6.
:- discontiguous test_harness:arith_misconception/6.
:- dynamic test_harness:arith_misconception/6.

% ---- Encodings appended by agent for measurement batch 2 ----

% === row 37545: base-10 regrouping applied to elapsed time ===
% Task: 7:08 - 2:53 elapsed time. Student borrows 100 min (base-10) instead of 60.
% Correct: 4:15
% Error: student borrows 100 and computes (108-53) and (6-2) = 4:55
% SCHEMA: Measuring Stick (time as scalar) — wrong base for regrouping
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(base10_regroup_on_time)))
r37545_base10_regroup_time(hours(H1,M1)-hours(H2,M2), hours(DH,DM)) :-
    (   M1 >= M2
    ->  DH is H1 - H2, DM is M1 - M2
    ;   DH is H1 - H2 - 1, DM is (M1 + 100) - M2
    ).

test_harness:arith_misconception(db_row(37545), measurement, base10_regroup_on_time,
    misconceptions_measurement_batch_2:r37545_base10_regroup_time,
    hours(7,8)-hours(2,53),
    hours(4,15)).

% === row 37566: area applied to 1D/3D contexts ===
% Too vague: categorical misapplication of 'area' as generic attribute.
% Not a computable input/output pair.
test_harness:arith_misconception(db_row(37566), measurement, too_vague,
    skip, none, none).

% === row 37568: invented rationales for formula constants ===
% Too vague: verbal explanation of formula components, not a calc.
test_harness:arith_misconception(db_row(37568), measurement, too_vague,
    skip, none, none).

% === row 37711: clock hand not exactly on the numeral ===
% Too vague: interpretation of clock hand position is not a numeric rule.
test_harness:arith_misconception(db_row(37711), measurement, too_vague,
    skip, none, none).

% === row 37713: 'half' mapped directly to '30' in digital answer ===
% Task: add 1 hour 30 minutes to 5:30.
% Correct: 7:00
% Error: student writes 6:30 — added 1 hour, replaced minute field with '30'.
% Input: hours(StartH,StartM)-hours(AddH,AddM). Rule returns buggy answer.
% SCHEMA: Symbol-as-object — '30' is the word for 'half', pasted in.
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(half_mapped_to_30)))
r37713_half_paste_30(hours(SH,_SM)-hours(AH,AM), hours(GH,GM)) :-
    GH is SH + AH,
    GM = AM.

test_harness:arith_misconception(db_row(37713), measurement, half_mapped_to_30,
    misconceptions_measurement_batch_2:r37713_half_paste_30,
    hours(5,30)-hours(1,30),
    hours(7,0)).

% === row 37721: generic perimeter/area interference ===
% Too vague: general confusion category with no unique numeric signature.
test_harness:arith_misconception(db_row(37721), measurement, too_vague,
    skip, none, none).

% === row 37805: angle as label not quantity ===
% Too vague: conceptual / definitional claim about angle measure.
test_harness:arith_misconception(db_row(37805), measurement, too_vague,
    skip, none, none).

% === row 37841: accepts non-conserving area after rearrangement ===
% Too vague: conservation acceptance is not a buggy calc.
test_harness:arith_misconception(db_row(37841), measurement, too_vague,
    skip, none, none).

% === row 38034: additive-not-multiplicative volume comparison ===
% Task: how many times larger is a big box that holds 900 unit cubes?
% Correct: 900 (multiplicative ratio)
% Error: 899 (subtractive: 900 - 1).
% Input: Count of unit cubes. Rule returns student's answer.
% SCHEMA: Container — ratio treated as difference
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(additive_ratio)))
r38034_subtractive_ratio(N, Got) :-
    Got is N - 1.

test_harness:arith_misconception(db_row(38034), measurement, additive_ratio_volume,
    misconceptions_measurement_batch_2:r38034_subtractive_ratio,
    900,
    900).

% === row 38036: blames tools for inconsistent measurements ===
% Too vague: attribution claim, not a computable procedure.
test_harness:arith_misconception(db_row(38036), measurement, too_vague,
    skip, none, none).

% === row 38100: unit equivalences as mechanical symbol shuffle ===
% Too vague: the student's calculation is correct; the misconception is conceptual.
test_harness:arith_misconception(db_row(38100), measurement, too_vague,
    skip, none, none).

% === row 38184: divide-then-iterate partitive ===
% Too vague: the student's numerical answer is correct; the misconception
% is in the partitioning process, not the output.
test_harness:arith_misconception(db_row(38184), measurement, too_vague,
    skip, none, none).

% === row 38291: radian treated as length for new radius ===
% Task: approximate sin(1.2) on unit circle; student uses 1.2 as new radius.
% Correct: sin(1.2) ≈ 0.932 (a fraction of unit radius)
% Error: returns 1.2 (treats input as length, not arc on unit circle)
% Input: radian value. Output: student's numeric "answer" for sin.
% SCHEMA: Measuring Stick — radian reread as absolute length
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(radian_as_length)))
r38291_radian_as_length(R, Got) :-
    Got = R.

test_harness:arith_misconception(db_row(38291), measurement, radian_as_length,
    misconceptions_measurement_batch_2:r38291_radian_as_length,
    1.2,
    0.932).

% === row 38340: steepness as directly-measurable quantity ===
% Too vague: conceptual claim about intensive vs extensive quantity.
test_harness:arith_misconception(db_row(38340), measurement, too_vague,
    skip, none, none).

% === row 38582: 8-inch square tile treated as 8 linear inches ===
% Task: how many 8-inch square tiles cover a 12-inch square foot?
% Correct: ceil(12/8)^2 with cutting, or 144/64 ≈ 2.25 (so 4 tiles with cuts).
% Student answer per row: reasoned 16 inches covered by 2 tiles, implying
% 144/8 = 18 total tiles are needed. We encode the linear-reduction bug:
% divide the 144 sq in by 8 linear in.
% Input: side length (in inches) of the square foot.
% SCHEMA: Measuring Stick overriding Container
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(tile_side_as_linear_unit)))
r38582_linear_tile_count(Side, Got) :-
    Got is (Side * Side) // 8.

test_harness:arith_misconception(db_row(38582), measurement, tile_side_as_linear,
    misconceptions_measurement_batch_2:r38582_linear_tile_count,
    12,
    4).

% === row 38584: sum raw piece counts instead of fractional tiles ===
% Task: cover a square foot (12x12) with 8x8, 8x4, 4x4 tile pieces.
% Correct: equivalent of (1 + 2*(1/2) + 1*(1/4)) = 2.25 full tiles.
% Error: student sums raw counts 1 + 2 + 1 = 4.
% Input: list of piece counts per cut type.
% SCHEMA: Container — parts-of-whole treated as units themselves
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(raw_piece_sum)))
r38584_raw_piece_sum([A,B,C], Got) :-
    Got is A + B + C.

test_harness:arith_misconception(db_row(38584), measurement, raw_piece_sum,
    misconceptions_measurement_batch_2:r38584_raw_piece_sum,
    [1,2,1],
    3).

% === row 38635: perimeter reported as area for irregular shape ===
% Too vague: no specific example numeric — general perimeter-for-area.
test_harness:arith_misconception(db_row(38635), measurement, too_vague,
    skip, none, none).

% === row 38675: area measured with ruler (length reported for area) ===
% Task: how much space does a 3x3 square cover?
% Correct: 9 square units
% Error: student measures one side = 3 inches, or measures around = 12 inches.
% Here we encode the most direct reading: student reports side length as area.
% Input: rect(W,H) of a square.
% SCHEMA: Measuring Stick applied where Container needed
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(area_via_length)))
r38675_area_as_side(rect(W,_H), Got) :-
    Got = W.

test_harness:arith_misconception(db_row(38675), measurement, area_as_side_length,
    misconceptions_measurement_batch_2:r38675_area_as_side,
    rect(3,3),
    9).

% === row 38677: unsystematic border-then-inside counting ===
% Too vague: counting path process, not a single output.
test_harness:arith_misconception(db_row(38677), measurement, too_vague,
    skip, none, none).

% === row 38694: diagonal across unit square counted as length 1 ===
% Task: perimeter of a shape drawn on grid that includes D diagonals.
% We encode the right-triangle perimeter hypotenuse case: legs A and B,
% hypotenuse counted as 1 (one grid step) when A = B = 1.
% Correct: 1 + 1 + sqrt(2) ≈ 3.414
% Error: 1 + 1 + 1 = 3
% Input: pair A-B of leg lengths on grid.
% SCHEMA: Measuring Stick — grid step equated with Euclidean length
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(diagonal_as_unit)))
r38694_diagonal_as_unit(A-B, Got) :-
    Got is A + B + 1.

test_harness:arith_misconception(db_row(38694), measurement, diagonal_as_unit,
    misconceptions_measurement_batch_2:r38694_diagonal_as_unit,
    1-1,
    3.414).

% === row 38991: volume confused with area for 3D shape ===
% Too vague: identification-of-attribute confusion, not a calc signature.
test_harness:arith_misconception(db_row(38991), measurement, too_vague,
    skip, none, none).

% === row 38993: 100 sq cm in 1 sq m (linear conversion for area) ===
% Task: convert 1 m^2 to cm^2.
% Correct: 10000
% Error: 100 (treats conversion as linear 100 cm per m).
% Input: value in m^2. Output: student's cm^2 answer.
% SCHEMA: Measuring Stick — linear scale applied to area
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(linear_area_conversion)))
r38993_linear_area_conv(Sqm, Got) :-
    Got is Sqm * 100.

test_harness:arith_misconception(db_row(38993), measurement, linear_area_conversion,
    misconceptions_measurement_batch_2:r38993_linear_area_conv,
    1,
    10000).

% === row 38995: area only exists when physically measured ===
% Too vague: ontological claim about area, not a numeric bug.
test_harness:arith_misconception(db_row(38995), measurement, too_vague,
    skip, none, none).

% === row 39003: area of triangle as product of three sides ===
% Task: area of a triangle with sides a, b, c.
% Correct: depends on shape; use Heron's formula. For 3-4-5 right triangle
% the true area is 6.
% Error: student computes a*b*c = 60.
% Input: list [a,b,c].
% SCHEMA: Formula Compression — 'three sides, so multiply three'
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(triangle_abc_product)))
r39003_triangle_abc_product([A,B,C], Got) :-
    Got is A * B * C.

test_harness:arith_misconception(db_row(39003), measurement, triangle_abc_product,
    misconceptions_measurement_batch_2:r39003_triangle_abc_product,
    [3,4,5],
    6).

% === row 39005: area unit requires physical paving ===
% Too vague: ontological belief about what allows unit expression.
test_harness:arith_misconception(db_row(39005), measurement, too_vague,
    skip, none, none).

% === row 39332: perimeter read as area outside boundary ===
% Too vague: everyday-language interference, not a distinct calc output.
test_harness:arith_misconception(db_row(39332), measurement, too_vague,
    skip, none, none).

% === row 39393: industry tolerances / standard gaps ignored ===
% Too vague: failure to attend to conventions, not a generic bug.
test_harness:arith_misconception(db_row(39393), measurement, too_vague,
    skip, none, none).

% === row 39524: volume via face count ===
% Task: number of unit cubes in a 2x2x2 block.
% Correct: 8
% Error: counts 6 visible faces × unit area = 24 (or "600" in the rowquote
% for a larger block). We encode the 2x2x2 face-count: 6 faces × 4 squares = 24.
% Input: box(L,W,H) of cube side lengths (assume cube).
% SCHEMA: Container — interior invisibly absent
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(face_count_for_volume)))
r39524_face_count_volume(box(L,W,H), Got) :-
    Got is 2 * (L*W + L*H + W*H).

test_harness:arith_misconception(db_row(39524), measurement, face_count_for_volume,
    misconceptions_measurement_batch_2:r39524_face_count_volume,
    box(2,2,2),
    8).

% === row 39536: one valid answer without optimization ===
% Too vague: stopping criterion, not a wrong number.
test_harness:arith_misconception(db_row(39536), measurement, too_vague,
    skip, none, none).

% === row 39593: teacher rejects multiplicative perimeter strategy ===
% Too vague: pedagogical framing bug, not a student calc error.
test_harness:arith_misconception(db_row(39593), measurement, too_vague,
    skip, none, none).

% === row 39598: orientation changes judged size ===
% Too vague: qualitative judgment about area conservation.
test_harness:arith_misconception(db_row(39598), measurement, too_vague,
    skip, none, none).

% === row 39607: decimal hours read as base-10 minutes ===
% Task: convert 1.2 hours to hours and minutes.
% Correct: hours(1, 12) — because 0.2 * 60 = 12.
% Error: hours(1, 20) — decimal part copied as minutes.
% Input: decimal-hour number as Whole-Decimal pair (e.g. 1-2 means 1.2 h).
% SCHEMA: Symbol-as-object — decimal digits reassigned as minutes
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(decimal_hours_direct)))
r39607_decimal_hours_direct(H-DecPart, hours(GH,GM)) :-
    GH = H,
    GM is DecPart * 10.

test_harness:arith_misconception(db_row(39607), measurement, decimal_hours_as_minutes,
    misconceptions_measurement_batch_2:r39607_decimal_hours_direct,
    1-2,
    hours(1,12)).

% === row 39621: area value substituted as perimeter value ===
% Task: perimeter of a rectangle with area 24 sq units (say 4x6).
% Correct: 2*(4+6) = 20
% Error: student says "24" because area is 24.
% Input: rect(W,H).
% SCHEMA: Container — one scalar labeled for the rectangle
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(area_as_perimeter_value)))
r39621_area_as_perimeter(rect(W,H), Got) :-
    Got is W * H.

test_harness:arith_misconception(db_row(39621), measurement, area_as_perimeter,
    misconceptions_measurement_batch_2:r39621_area_as_perimeter,
    rect(4,6),
    20).

% === row 39656: no row-column structure for area ===
% Too vague: structural concept gap, not a specific numeric bug.
test_harness:arith_misconception(db_row(39656), measurement, too_vague,
    skip, none, none).

% === row 39663: unreasonable volume accepted (no magnitude check) ===
% Too vague: missing estimation check, not a unique buggy procedure.
test_harness:arith_misconception(db_row(39663), measurement, too_vague,
    skip, none, none).

% === row 39743: rate computed without unit handling ===
% Too vague: unit labeling error, not a numeric procedure.
test_harness:arith_misconception(db_row(39743), measurement, too_vague,
    skip, none, none).

% === row 39863: continuous quantity forced to whole squares ===
% Too vague: constraint-imposition failure, many possible outputs.
test_harness:arith_misconception(db_row(39863), measurement, too_vague,
    skip, none, none).

% === row 40010: pizza value via diameter not area ===
% Task: pizza A diameter 30, pizza B diameter 40. How many times more
% area does B have than A?
% Correct: (40/30)^2 ≈ 1.777
% Error: 40/30 ≈ 1.333 (linear-diameter ratio).
% Input: DB-DA pair.
% SCHEMA: Measuring Stick — 1D stand-in for 2D attribute
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(diameter_for_area)))
r40010_diameter_ratio(DB-DA, Got) :-
    Got is DB / DA.

test_harness:arith_misconception(db_row(40010), measurement, diameter_for_area,
    misconceptions_measurement_batch_2:r40010_diameter_ratio,
    40-30,
    1.777).

% === row 40043: total area / card area, ignore orientation ===
% Task: how many 8x6 greeting cards fit on an 85x65 cardboard?
% Correct: orientation-aware packing ≈ 10*10 = 100 cards (max 110 with rotations).
% Error: 5525 // 48 = 115 (total area divided by card area).
% Input: pair board(LB,WB)-card(LC,WC).
% SCHEMA: Container — total quantity / unit quantity, orientation ignored
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(total_area_div_card_area)))
r40043_total_area_div(board(LB,WB)-card(LC,WC), Got) :-
    Got is (LB * WB) // (LC * WC).

test_harness:arith_misconception(db_row(40043), measurement, total_area_division_pack,
    misconceptions_measurement_batch_2:r40043_total_area_div,
    board(85,65)-card(8,6),
    110).

% === row 40157: area-perimeter relation not monotone ===
% Too vague: productive perturbation, not a student error per se.
test_harness:arith_misconception(db_row(40157), measurement, too_vague,
    skip, none, none).

% === row 40212: pervasive unit/rate imprecision ===
% Too vague: diffuse class of unit-handling failures.
test_harness:arith_misconception(db_row(40212), measurement, too_vague,
    skip, none, none).

% === row 40225: teacher validates shortcut algebraically ===
% Too vague: pedagogical choice, not a student calc.
test_harness:arith_misconception(db_row(40225), measurement, too_vague,
    skip, none, none).

% === row 40254: perimeter as L + W only (two sides) ===
% Task: perimeter of a rectangle 10 by 6.
% Correct: 2*(10+6) = 32
% Error: 10 + 6 = 16.
% Input: rect(W,H).
% SCHEMA: Container — only two sides traversed
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(perimeter_two_sides)))
r40254_perimeter_two_sides(rect(W,H), Got) :-
    Got is W + H.

test_harness:arith_misconception(db_row(40254), measurement, perimeter_two_sides_only,
    misconceptions_measurement_batch_2:r40254_perimeter_two_sides,
    rect(10,6),
    32).

% === row 40288: no understanding of cm * cm = cm^2 ===
% Too vague: conceptual unit-multiplication gap.
test_harness:arith_misconception(db_row(40288), measurement, too_vague,
    skip, none, none).

% === row 40362: area/perimeter undifferentiated (generic) ===
% Too vague: general category with no numeric signature.
test_harness:arith_misconception(db_row(40362), measurement, too_vague,
    skip, none, none).

% === row 40443: ribbon length judged by face count or volume ===
% Too vague: cross-attribute confusion, not a single numeric bug.
test_harness:arith_misconception(db_row(40443), measurement, too_vague,
    skip, none, none).

% === row 40602: random-path counting loses track ===
% Too vague: process failure, variable outputs.
test_harness:arith_misconception(db_row(40602), measurement, too_vague,
    skip, none, none).

% === row 40604: corner-cube triple-counting puzzle ===
% Too vague: multiple distinct bugs described in one row.
test_harness:arith_misconception(db_row(40604), measurement, too_vague,
    skip, none, none).

% === row 40638: first-foot-not-counted off-by-one ===
% Task: number of feet to cover a path that is N feet long.
% Correct: N
% Error: N - 1 (start counting on second placement).
% Input: integer N.
% SCHEMA: Measuring Stick — iteration step vs interval conflated
% GROUNDED: TODO — placeholder
% CONNECTS TO: s(comp_nec(unlicensed(first_foot_uncounted)))
r40638_first_foot_uncounted(N, Got) :-
    Got is N - 1.

test_harness:arith_misconception(db_row(40638), measurement, first_foot_uncounted,
    misconceptions_measurement_batch_2:r40638_first_foot_uncounted,
    5,
    5).

% === row 40640: count extends as sequential label, not accumulated ===
% Too vague: iteration-labeling error specific to bar-of-cubes context.
test_harness:arith_misconception(db_row(40640), measurement, too_vague,
    skip, none, none).

% === row 40654: perimeter reported for area of irregular island ===
% Too vague: duplicates 40362 — general area/perimeter swap without
% distinct numeric signature.
test_harness:arith_misconception(db_row(40654), measurement, too_vague,
    skip, none, none).

% === direct solo pass: remaining measurement queue cleanup ===

test_harness:arith_misconception(db_row(37696), measurement, too_vague,
    skip, none, none).

test_harness:arith_misconception(db_row(37896), measurement, too_vague,
    skip, none, none).

test_harness:arith_misconception(db_row(38769), measurement, too_vague,
    skip, none, none).

% === row 38879: incommensurable segments assumed to have common unit ===
% Task: decide whether a square side and diagonal share a common unit.
% Correct: false.
% Error: true, because the unit can supposedly always be made smaller.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO distinguish arbitrary refinement from commensurability.
% CONNECTS TO: s(comp_nec(unlicensed(always_common_unit_by_refinement)))
r38879_always_common_unit(segments(side, diagonal), true).

test_harness:arith_misconception(db_row(38879), measurement, always_common_unit_by_refinement,
    misconceptions_measurement_batch_2:r38879_always_common_unit,
    segments(side, diagonal),
    false).

% === row 38965: visible faces counted as volume units ===
% Task: enumerate minis in a 2 by 2 by 2 cube.
% Correct: 8.
% Error: 12, counting visible face squares on three visible faces.
% SCHEMA: Container.
% GROUNDED: TODO coordinate hidden volume units, not just visible surface units.
% CONNECTS TO: s(comp_nec(unlicensed(visible_faces_as_volume)))
r38965_visible_faces_volume(cube(2,2,2), 12).

test_harness:arith_misconception(db_row(38965), measurement, visible_faces_as_volume,
    misconceptions_measurement_batch_2:r38965_visible_faces_volume,
    cube(2,2,2),
    8).

% === row 39551: decimal part rejected as minutes ===
% Task: interpret 23.78 hours.
% Correct: hours_minutes(23,46.8).
% Error: invalid_minutes, because 78 is read as minutes and minutes cannot exceed 60.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO convert decimal fraction of an hour into base-60 minutes.
% CONNECTS TO: s(comp_nec(unlicensed(decimal_time_as_absolute_minutes)))
r39551_decimal_time_minutes(decimal_time(23,78), invalid_minutes).

test_harness:arith_misconception(db_row(39551), measurement, decimal_time_as_absolute_minutes,
    misconceptions_measurement_batch_2:r39551_decimal_time_minutes,
    decimal_time(23,78),
    hours_minutes(23,46.8)).

test_harness:arith_misconception(db_row(39552), measurement, too_vague,
    skip, none, none).

% === row 40241: square side from area by dividing by two ===
% Task: find side length of square with area 9.
% Correct: 3.
% Error: 4.5, dividing the area by two.
% SCHEMA: Container.
% GROUNDED: TODO inverse square-area relation via square root, not halving.
% CONNECTS TO: s(comp_nec(unlicensed(square_side_area_halved)))
r40241_area_halved_for_side(area_square(A), Side) :-
    Side is A / 2.

test_harness:arith_misconception(db_row(40241), measurement, square_side_area_halved,
    misconceptions_measurement_batch_2:r40241_area_halved_for_side,
    area_square(9),
    3).

test_harness:arith_misconception(db_row(40267), measurement, too_vague,
    skip, none, none).

% === direct solo pass: geometric rows with measurement-style signatures ===

% === row 37875: triangle angle sum depends on size ===
% Correct: 180.
% Error: larger triangle has a larger angle sum.
% SCHEMA: Container.
% GROUNDED: TODO preserve invariant angle sum under size/shape variation.
% CONNECTS TO: s(comp_nec(unlicensed(triangle_angle_sum_scales_with_size)))
r37875_triangle_sum_scales(triangle(large), 770).

test_harness:arith_misconception(db_row(37875), geometric, triangle_angle_sum_scales_with_size,
    misconceptions_measurement_batch_2:r37875_triangle_sum_scales,
    triangle(large),
    180).

% === row 38063: reciprocal side changes leave perimeter unchanged ===
% Rect 10 by 5 changed to 12 by 4.
% Correct perimeter: 32.
% Error: original perimeter 30 remains unchanged.
% SCHEMA: Container.
% GROUNDED: TODO compute new side lengths before perimeter comparison.
% CONNECTS TO: s(comp_nec(unlicensed(same_change_same_perimeter)))
r38063_same_perimeter_recip(rect(10,5), 30).

test_harness:arith_misconception(db_row(38063), geometric, same_change_same_perimeter,
    misconceptions_measurement_batch_2:r38063_same_perimeter_recip,
    rect(10,5),
    32).

% === row 39012: circumference scaling intuition overestimates added string ===
% Correct for 1.8m radius increase: about 11.31m extra circumference.
% Error: much_more.
% SCHEMA: Measuring Stick.
% GROUNDED: TODO use linear circumference change 2*pi*delta_r.
% CONNECTS TO: s(comp_nec(unlicensed(circumference_growth_overestimated)))
r39012_circumference_overestimate(radius_increase(1.8), much_more).

test_harness:arith_misconception(db_row(39012), geometric, circumference_growth_overestimated,
    misconceptions_measurement_batch_2:r39012_circumference_overestimate,
    radius_increase(1.8),
    meters(11.31)).

% === row 39106: visually different contours imply different areas ===
% Correct: equal.
% Error: not_equal.
% SCHEMA: Container.
% GROUNDED: TODO preserve area equivalence under translation between parallel curves.
% CONNECTS TO: s(comp_nec(unlicensed(visual_contour_overrides_area_equivalence)))
r39106_contour_area_not_equal(areas_between_parallel_curves, not_equal).

test_harness:arith_misconception(db_row(39106), geometric, visual_contour_overrides_area_equivalence,
    misconceptions_measurement_batch_2:r39106_contour_area_not_equal,
    areas_between_parallel_curves,
    equal).

% === row 39141: area equivalence requires congruence ===
% Correct: possible.
% Error: impossible without congruence or symmetry.
% SCHEMA: Container.
% GROUNDED: TODO distinguish equal measure from congruent shape.
% CONNECTS TO: s(comp_nec(unlicensed(area_equivalence_requires_congruence)))
r39141_area_requires_congruence(noncongruent_equal_area, impossible).

test_harness:arith_misconception(db_row(39141), geometric, area_equivalence_requires_congruence,
    misconceptions_measurement_batch_2:r39141_area_requires_congruence,
    noncongruent_equal_area,
    possible).

% === row 39143: additive side compensation preserves area ===
% Correct: not_equal.
% Error: equal because one side loses what the other gains.
% SCHEMA: Object Collection.
% GROUNDED: TODO compare products/area, not additive side balance.
% CONNECTS TO: s(comp_nec(unlicensed(additive_compensation_preserves_area)))
r39143_additive_area_balance(triangles((1,9),(3,7)), equal).

test_harness:arith_misconception(db_row(39143), geometric, additive_compensation_preserves_area,
    misconceptions_measurement_batch_2:r39143_additive_area_balance,
    triangles((1,9),(3,7)),
    not_equal).

% === row 39265: geography fixes a single equator/pole pair ===
% Correct: many_equators.
% Error: one_equator.
% SCHEMA: Container.
% GROUNDED: TODO treat poles/equators as relative to chosen great circle.
% CONNECTS TO: s(comp_nec(unlicensed(single_geographic_equator_on_sphere)))
r39265_single_equator(sphere, one_equator).

test_harness:arith_misconception(db_row(39265), geometric, single_geographic_equator_on_sphere,
    misconceptions_measurement_batch_2:r39265_single_equator,
    sphere,
    many_equators).

% === row 39266: spherical triangle forced to plane angle sum ===
% Correct example: 270.
% Error: 180.
% SCHEMA: Container.
% GROUNDED: TODO distinguish spherical surface from Euclidean plane.
% CONNECTS TO: s(comp_nec(unlicensed(spherical_triangle_plane_sum)))
r39266_spherical_plane_sum(spherical_triangle, 180).

test_harness:arith_misconception(db_row(39266), geometric, spherical_triangle_plane_sum,
    misconceptions_measurement_batch_2:r39266_spherical_plane_sum,
    spherical_triangle,
    270).

% === row 39516: additive side differences imply similarity ===
% Correct: false.
% Error: true because both sides increased by 2.
% SCHEMA: Object Collection.
% GROUNDED: TODO compare multiplicative ratios, not additive differences.
% CONNECTS TO: s(comp_nec(unlicensed(additive_similarity)))
r39516_additive_similarity(rect(3,5)-rect(5,7), true).

test_harness:arith_misconception(db_row(39516), geometric, additive_similarity,
    misconceptions_measurement_batch_2:r39516_additive_similarity,
    rect(3,5)-rect(5,7),
    false).

% === row 39585: area scales by the linear scale factor ===
% Correct: 4 for doubled length and width.
% Error: 2.
% SCHEMA: Container.
% GROUNDED: TODO square the linear scale factor for area.
% CONNECTS TO: s(comp_nec(unlicensed(area_scales_linearly)))
r39585_area_scales_linearly(scale2d(K), K).

test_harness:arith_misconception(db_row(39585), geometric, area_scales_linearly,
    misconceptions_measurement_batch_2:r39585_area_scales_linearly,
    scale2d(2),
    4).

% === row 40011: volume scales by edge scale instead of cube scale ===
% Correct: 8 for doubled edge length.
% Error: 2.
% SCHEMA: Container.
% GROUNDED: TODO cube the linear scale factor for volume.
% CONNECTS TO: s(comp_nec(unlicensed(volume_scales_linearly)))
r40011_volume_scales_linearly(edge_scale(K), K).

test_harness:arith_misconception(db_row(40011), geometric, volume_scales_linearly,
    misconceptions_measurement_batch_2:r40011_volume_scales_linearly,
    edge_scale(2),
    8).

% === row 40244: Pythagorean pattern replaced by triangle area ===
% Correct: sqrt(8) ~= 2.8284271247461903.
% Error: 2, multiplying legs and dividing by two.
% SCHEMA: Container.
% GROUNDED: TODO compute hypotenuse length, not area of the right triangle.
% CONNECTS TO: s(comp_nec(unlicensed(pythagorean_as_triangle_area)))
r40244_pythagorean_area(legs(A,B), Area) :-
    Area is A * B / 2.

test_harness:arith_misconception(db_row(40244), geometric, pythagorean_as_triangle_area,
    misconceptions_measurement_batch_2:r40244_pythagorean_area,
    legs(2,2),
    2.8284271247461903).

% === row 40261: triangle area omits divide-by-two ===
% Correct: 6.
% Error: 12.
% SCHEMA: Container.
% GROUNDED: TODO identify triangle as half of the corresponding rectangle.
% CONNECTS TO: s(comp_nec(unlicensed(triangle_area_no_half)))
r40261_triangle_area_no_half(triangle(B,H), Area) :-
    Area is B * H.

test_harness:arith_misconception(db_row(40261), geometric, triangle_area_no_half,
    misconceptions_measurement_batch_2:r40261_triangle_area_no_half,
    triangle(3,4),
    6).

% === row 40265: rectangle angle sum from three triangles ===
% Correct: 360.
% Error: 540.
% SCHEMA: Container.
% GROUNDED: TODO count a valid triangulation, not arbitrary auxiliary triangles.
% CONNECTS TO: s(comp_nec(unlicensed(rectangle_angle_sum_three_triangles)))
r40265_rectangle_three_triangles(rectangle, 540).

test_harness:arith_misconception(db_row(40265), geometric, rectangle_angle_sum_three_triangles,
    misconceptions_measurement_batch_2:r40265_rectangle_three_triangles,
    rectangle,
    360).
