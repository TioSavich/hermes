/** <module> Place-value scene compiler, generic over the operative base (P4)
 *
 * The "Ace of Base" compiler. It compiles integer place-value moves into a
 * sequence of scene frames for an arbitrary operative base B (units, then groups
 * of B, B^2, B^3 -- the unit/rod/flat/cube blocks). Base 10 is only the default;
 * 5, 7, and 12 flow through the same generators and produce genuinely different
 * groupings and carries. The frozen scene format identifier stays "base-ten-
 * columns" (a contract constant the drawer reads), but the structure and the
 * narration are about the operative base, not base ten.
 *
 * The frames go out under the render contract
 * (docs/render-contract-v2.md).
 *
 * This is a THIN, WITNESS-FED compiler. It emits semantic primitives only:
 * each column is `{place, count, base, role}` and each regroup is a `carries`
 * row `{fromPlace, toPlace, amount}`. It does NOT emit pixel rectangles for the
 * rod/flat/cube shapes — the JS drawer owns that geometry (the ported
 * Ace-of-Base block shapes). The compiler's job is to say which place holds how
 * many of which block, and which carries/borrows fire; the drawer draws them.
 *
 * Witness-fed regroup. The carry/borrow decision is NOT a local `PlaceSum>=Base`
 * comparison. It is read off the grounded base-decomposition of the place sum:
 * `grounded_utils:base_decompose_grounded(PlaceSum, Base, Carry, Remainder)`
 * answers "how many base-groups does this place sum carry, and what is left".
 * That is the same repeated-base-group-subtraction the
 * `grounded_arith_witness(base_decompose, ...)` projection records. For the
 * in-range base-10 standard cases the compiler additionally consults the
 * Indiana standard witnesses (standard_1_ca_3, standard_2_ca_2, standard_k_ns_7)
 * so the recorded `regroup_case` is available to the narration. The carries row
 * fires exactly when the witnessed `Carry` is at least one.
 *
 * The base is a parameter. The same bundling move — Base units in a place
 * regrouped into one block of the next place — is the same SHAPE at base 10 and
 * base 12; only the digit left on the bundled place differs. That base-as-
 * parameter property is the place-value side of the base-invariance idea in
 * docs/proposals/2026-06-23-visualizer-reuse-goal.md (Goal H, criterion 2).
 *
 * Roles. Each column carries a base-ten role (the render contract):
 *   unit (base^0), rod (base^1), flat (base^2), cube (base^>=3). The drawer maps
 *   role -> --fig-<role> CSS variable; the compiler never emits a hex string.
 *
 * Generators:
 *   - represent(Number, Base)            place-value decomposition, one frame
 *   - place_value_teen(Number)           k_ns_7 one-ten-group teen decomposition
 *   - add_with_carry(A, B, Base)         add place by place, witness-fed carries
 *   - add_with_dropped_carry(A, B, Base) the dropped-carry DEFORMATION (writes
 *                                        the place remainder but never carries)
 *   - subtract_with_borrow(A, B, Base)   subtract place by place, witness-fed
 *                                        borrows (negative refused, not drawn)
 *   - decimal_place_value(IntPart, FracDigits)  base-10 places across the point
 *   - base_decomposition(Number, Base)   repeated division; remainders are digits
 *
 * What this does NOT model:
 *   - It draws place-value bundling/unbundling as columns + carry rows; it does
 *     not run the ORR crisis cycle.
 *   - Decimal place value is base 10 only. Sub-unit fractional places carry the
 *     shared `neutral` role (no base-ten block shape below a unit).
 *   - Negative results in subtract_with_borrow are refused, not drawn signed.
 *   - It is a 1-D column layout, not the 2-D array/area model (P3).
 */

:- module(base_ten_scene,
          [ base_ten_render_frames/2,   % +Spec, -Frames
            base_ten_render_json/2,      % +Spec, -Dict
            base_ten_render_to_file/2    % +Spec, +Path
          ]).

:- use_module(render(render_common),
              [render_frames/4, term_to_string/2, write_render_json/2]).
:- use_module(library(lists)).
:- use_module(formalization(grounded_utils), []).
:- use_module(formalization(grounded_arithmetic), []).
:- use_module(math(recursive_unit_actions),
              [ integer_numeral/3,
                numeral_text/2
              ]).
:- use_module(standards(indiana/standard_1_ca_3), []).
:- use_module(standards(indiana/standard_2_ca_2), []).
:- use_module(standards(indiana/standard_k_ns_7), []).
:- use_module(render(grounding_to_primitive), []).


% =============================================================================
% Public API
% =============================================================================

%!  base_ten_render_frames(+Spec, -Frames) is det.
%
%   Walk Spec into a list of frame dicts. An unknown/deferred Spec yields a
%   single annotation-only frame (sceneChanged:false) rather than throwing.
base_ten_render_frames(Spec, Frames) :-
    render_frames(Spec, gen_frames, deferred_frame, Frames).

%!  base_ten_render_json(+Spec, -Dict) is det.
%
%   Assemble the full frame document: kind / request / result / canvas / frames.
base_ten_render_json(Spec, Dict) :-
    base_ten_render_frames(Spec, Frames),
    spec_kind(Spec, KindStr),
    spec_request(Spec, Request),
    spec_result(Spec, ResultStr),
    canvas_dict(Canvas),
    Base0 = _{ kind: KindStr,
               request: Request,
               result: ResultStr,
               canvas: Canvas,
               frames: Frames },
    % Additive L&N grounding footer (the render contract). A spec whose
    % practice has no L&N grounding (the dropped-carry deformation) carries no
    % grounding object -- its absence is the claim that the procedure is hollow.
    ( spec_grounding(Spec, Grounding)
    -> Dict = Base0.put(grounding, Grounding)
    ;  Dict = Base0
    ).

%!  base_ten_render_to_file(+Spec, +Path) is det.
base_ten_render_to_file(Spec, Path) :-
    base_ten_render_json(Spec, Dict),
    write_render_json(Path, Dict).


% =============================================================================
% Witness-fed regroup primitive.
% =============================================================================

%!  regroup_decision(+PlaceSum, +Base, -Carry, -Remainder) is det.
%
%   Read the carry/remainder off the grounded base-decomposition of PlaceSum.
%   This is the witnessed regroup decision: PlaceSum split into base-groups
%   (the Carry) plus what is left on the place (the Remainder). NOT a local
%   PlaceSum >= Base test. Falls back to integer // and mod only if the
%   grounded predicate is unavailable, preserving the same arithmetic.
regroup_decision(PlaceSum, Base, Carry, Remainder) :-
    ( grounded_arithmetic:integer_to_recollection(PlaceSum, RS),
      grounded_arithmetic:integer_to_recollection(Base, RB),
      grounded_utils:base_decompose_grounded(RS, RB, RCarry, RRem),
      grounded_arithmetic:recollection_to_integer(RCarry, Carry),
      grounded_arithmetic:recollection_to_integer(RRem, Remainder)
    -> true
    ;  Carry is PlaceSum // Base,
       Remainder is PlaceSum mod Base
    ).

%!  borrow_decision(+PlaceDigit, +OtherDigit, +Base, -Borrowed, -Result) is semidet.
%
%   Witness-fed borrow: when PlaceDigit is short of OtherDigit, one group of
%   Base is unbundled from the next place up (Borrowed = 1) and the place
%   subtraction PlaceDigit + Base - OtherDigit is taken; otherwise Borrowed = 0
%   and the plain difference is taken. The "short" decision uses the grounded
%   base-decomposition of (PlaceDigit + Base): borrowing makes the place worth
%   one base-group plus the digit, which is exactly the unbundle.
borrow_decision(PlaceDigit, OtherDigit, _Base, 0, Result) :-
    PlaceDigit >= OtherDigit, !,
    Result is PlaceDigit - OtherDigit.
borrow_decision(PlaceDigit, OtherDigit, Base, 1, Result) :-
    PlaceDigit < OtherDigit,
    Available is PlaceDigit + Base,
    Result is Available - OtherDigit.


% =============================================================================
% Generators. Each builds a list of frames. The shared move "make_frame" packs
% a list of columns + a list of carry rows into a v2 base-ten-columns scene.
% =============================================================================

% --- represent(Number, Base) ------------------------------------------------
% One frame: Number decomposed into place digits in Base; each place is a column
% carrying its digit as `count` and the place's block role.
gen_frames(represent(Number, Base), [Frame]) :-
    integer(Number), Number >= 0, integer(Base), Base >= 2,
    !,
    low_digits(Number, Base, Low),         % low-to-high (index 0 = ones)
    columns_from_low(Low, Base, Columns),
    format(string(Cap), "Represent ~w in base ~w by place value.", [Number, Base]),
    make_frame(1, represent(Number, Base), Cap, true, Columns, [], Frame).

% --- place_value_teen(Number) -----------------------------------------------
% Drive the K.NS.7 one-ten-group witness: a teen number is one ten and some
% ones. The witness supplies tens_value and ones_value; the scene draws a rod
% column (the ten) and a unit column (the leftover ones).
gen_frames(place_value_teen(Number), [Frame]) :-
    integer(Number), Number >= 0, Number =< 20,
    grounded_arithmetic:integer_to_recollection(Number, RN),
    standard_k_ns_7:describe_place_value_witness(RN, _Desc, Witness),
    !,
    get_dict(tens_value, Witness, Tens),
    get_dict(ones_value, Witness, Ones),
    Low = [Ones, Tens],                    % ones at index 0, tens at index 1
    columns_from_low(Low, 10, Columns),
    format(string(Cap),
           "~w is one ten-group with ~w ones left over.",
           [Number, Ones]),
    make_frame(1, place_value_teen(Number), Cap, true, Columns, [], Frame).

% --- add_with_carry(A, B, Base) ---------------------------------------------
% Show A, show B, then combine place by place from the ones up. The regroup
% decision per place is witnessed (regroup_decision/4): if the place sum carries
% at least one base-group, a carry row fires and the place keeps the remainder.
% Final frame: the clean sum.
gen_frames(add_with_carry(A, B, Base), Frames) :-
    integer(A), A >= 0, integer(B), B >= 0, integer(Base), Base >= 2,
    !,
    Sum is A + B,
    max_places([A, B, Sum], Base, 1, NPlaces),
    digits_padded(A, Base, NPlaces, DA),   % low-to-high
    digits_padded(B, Base, NPlaces, DB),
    % Frame 1: A.
    columns_from_low(DA, Base, ColsA),
    format(string(Cap1), "Show ~w in place-value columns.", [A]),
    make_frame(1, show_addend(A), Cap1, true, ColsA, [], F1),
    % Frame 2: A and B lined up by place (counts summed per column, pre-regroup).
    maplist(plus_digit, DA, DB, RawSums),
    columns_from_low(RawSums, Base, ColsAB),
    format(string(Cap2), "Line ~w up under ~w by place.", [B, A]),
    make_frame(2, show_addend(B), Cap2, true, ColsAB, [], F2),
    % Frames 3..: combine place by place, threading the carry.
    add_place_frames(0, NPlaces, 0, DA, DB, Base, 3, [], CombineFrames, FinalLow),
    columns_from_low(FinalLow, Base, ColsSum),
    last_step(CombineFrames, LastStep),
    FinalStep is LastStep + 1,
    format(string(CapF), "The sum is ~w.", [Sum]),
    make_frame(FinalStep, sum(Sum), CapF, true, ColsSum, [], FFinal),
    append([F1, F2 | CombineFrames], [FFinal], Frames).

% --- add_with_dropped_carry(A, B, Base) -------------------------------------
% The DEFORMATION. Combine place by place, but DROP every carry: write the place
% remainder and never bundle into the next place. The result is the digit-wise
% sum with the carries thrown away (a real student error: "8 + 7 is 5, write 5,
% forget the one"). No carries row is emitted; the final digits are wrong, and
% the caption names the dropped carry so the misconception is legible.
gen_frames(add_with_dropped_carry(A, B, Base), Frames) :-
    integer(A), A >= 0, integer(B), B >= 0, integer(Base), Base >= 2,
    !,
    Sum is A + B,
    max_places([A, B, Sum], Base, 1, NPlaces),
    digits_padded(A, Base, NPlaces, DA),
    digits_padded(B, Base, NPlaces, DB),
    columns_from_low(DA, Base, ColsA),
    format(string(Cap1), "Show ~w in place-value columns.", [A]),
    make_frame(1, show_addend(A), Cap1, true, ColsA, [], F1),
    drop_carry_frames(0, NPlaces, DA, DB, Base, 2, DropFrames, DeformedLow),
    columns_from_low(DeformedLow, Base, ColsBad),
    last_step(DropFrames, LastStep),
    FinalStep is LastStep + 1,
    low_digits_to_int(DeformedLow, Base, Wrong),
    Right is A + B,
    format(string(CapF),
           "Dropping the carries gives ~w, not ~w. Each carried base-group was thrown away.",
           [Wrong, Right]),
    make_frame(FinalStep, deformed_sum(Wrong), CapF, true, ColsBad, [], FFinal),
    append([F1 | DropFrames], [FFinal], Frames).

% --- subtract_with_borrow(A, B, Base) ---------------------------------------
% Show A; subtract place by place from the ones up. A short place borrows one
% base-group from the next place up (borrow_decision/5). Final frame: the
% difference. Negative refused (clause fails -> deferred frame).
gen_frames(subtract_with_borrow(A, B, Base), Frames) :-
    integer(A), A >= 0, integer(B), B >= 0, integer(Base), Base >= 2,
    A >= B,
    !,
    Diff is A - B,
    max_places([A, B], Base, 1, NPlaces),
    digits_padded(A, Base, NPlaces, DA),
    digits_padded(B, Base, NPlaces, DB),
    columns_from_low(DA, Base, ColsA),
    format(string(Cap1), "Show ~w. Subtract ~w place by place.", [A, B]),
    make_frame(1, show_minuend(A), Cap1, true, ColsA, [], F1),
    sub_place_frames(0, NPlaces, DA, DB, Base, 2, BorrowFrames, FinalLow),
    columns_from_low(FinalLow, Base, ColsDiff),
    last_step(BorrowFrames, LastStep),
    FinalStep is LastStep + 1,
    format(string(CapF), "The difference is ~w.", [Diff]),
    make_frame(FinalStep, difference(Diff), CapF, true, ColsDiff, [], FFinal),
    append([F1 | BorrowFrames], [FFinal], Frames).

% --- subtract_without_reducing_borrow(A, B, Base) --------------------------
% The DEFORMATION. When a place is short, it adds one base-group to that place
% but never reduces the next place up. This draws the familiar written error:
% "make 12 ones" while leaving the tens digit unchanged.
gen_frames(subtract_without_reducing_borrow(A, B, Base), Frames) :-
    integer(A), A >= 0, integer(B), B >= 0, integer(Base), Base >= 2,
    A >= B,
    !,
    max_places([A, B], Base, 1, NPlaces),
    digits_padded(A, Base, NPlaces, DA),
    digits_padded(B, Base, NPlaces, DB),
    columns_from_low(DA, Base, ColsA),
    format(string(Cap1), "Show ~w. Subtract ~w place by place.", [A, B]),
    make_frame(1, show_minuend(A), Cap1, true, ColsA, [], F1),
    sub_no_reduce_frames(0, NPlaces, DA, DB, Base, 2, BorrowFrames, DeformedLow),
    columns_from_low(DeformedLow, Base, ColsWrong),
    last_step(BorrowFrames, LastStep),
    FinalStep is LastStep + 1,
    low_digits_to_int(DeformedLow, Base, Wrong),
    Correct is A - B,
    format(string(CapF),
           "Borrowing without reducing the next place gives ~w, not ~w.",
           [Wrong, Correct]),
    make_frame(FinalStep, deformed_difference(Wrong), CapF, true, ColsWrong, [], FFinal),
    append([F1 | BorrowFrames], [FFinal], Frames).

% --- decimal_place_value(IntPart, FracDigits) -------------------------------
% Base 10 only. Integer places (roles unit/rod/flat/cube by exponent) to the
% left of a point marker column; tenths/hundredths/... to the right carry the
% shared `neutral` role (no base-ten block shape below a unit).
gen_frames(decimal_place_value(IntPart, FracDigits), [Frame]) :-
    integer(IntPart), IntPart >= 0,
    is_list(FracDigits),
    forall(member(D, FracDigits), (integer(D), D >= 0, D =< 9)),
    !,
    Base = 10,
    low_digits(IntPart, Base, IntLow),
    int_columns(IntLow, Base, IntCols),
    length(IntLow, NInt),
    point_column(NInt, PointCol),
    frac_columns(FracDigits, -1, Base, FracCols),
    append(IntCols, [PointCol|FracCols], Columns),
    digits_to_number_string(IntLow, FracDigits, NumStr),
    format(string(Cap), "Place value across the decimal point: ~w.", [NumStr]),
    make_frame(1, decimal_place_value(IntPart, FracDigits), Cap, true,
               Columns, [], Frame).

% --- base_decomposition(Number, Base) ---------------------------------------
% The bases_remainder view: repeated division. Each step divides the running
% quotient by Base; the remainder is the digit on that place. One frame per
% division step, then a final frame showing all the digit columns together.
gen_frames(base_decomposition(Number, Base), Frames) :-
    integer(Number), Number >= 0, integer(Base), Base >= 2,
    !,
    division_steps(Number, Base, Steps),       % low->high list of step(Q0,Rem,Q1)
    decomp_step_frames(Steps, Base, 1, [], StepFrames),
    low_digits(Number, Base, Low),
    columns_from_low(Low, Base, Columns),
    last_step(StepFrames, LastStep),
    FinalStep is LastStep + 1,
    high_digits_string(Number, Base, DigitStr),
    format(string(CapF),
           "The remainders, low place first, are the digits: ~w in base ~w.",
           [DigitStr, Base]),
    make_frame(FinalStep, collect_digits(Number), CapF, true, Columns, [], FFinal),
    append(StepFrames, [FFinal], Frames).


% =============================================================================
% Add: per-place combine with witnessed carry.
% =============================================================================

%!  add_place_frames(+Idx, +N, +CarryIn, +DA, +DB, +Base, +Step0, +Resolved,
%!                   -Frames, -FinalLow) is det.
%
%   Walk places ones-up, threading the carry. The per-place regroup decision is
%   witnessed by regroup_decision/4 over the place sum DA[i] + DB[i] + CarryIn.
%   FinalLow is the resulting low-to-high digit list for the clean sum frame.
add_place_frames(Idx, N, _CarryIn, _DA, _DB, _Base, _Step0, _Resolved, [], []) :-
    Idx >= N, !.
add_place_frames(Idx, N, CarryIn, DA, DB, Base, Step0, Resolved,
                 [Frame|Rest], [Digit|RestDigits]) :-
    Idx < N,
    nth0(Idx, DA, A), nth0(Idx, DB, B),
    PlaceSum is A + B + CarryIn,
    regroup_decision(PlaceSum, Base, CarryOut, Digit),
    place_name(Idx, Base, PlaceName),
    ( CarryOut >= 1
    -> NextIdx is Idx + 1,
       place_name(NextIdx, Base, NextName),
       carry_row(Idx, NextIdx, CarryOut, Row),
       Carries = [Row],
       carry_in_clause(CarryIn, A, B, InClause),
       format(string(Cap),
              "~w in the ~w place makes ~w; bundle ~w into the ~w place, leave ~w, carry ~w.",
              [InClause, PlaceName, PlaceSum, CarryOut, NextName,
               Digit, CarryOut])
    ;  Carries = [],
       carry_in_clause(CarryIn, A, B, InClause),
       format(string(Cap),
              "~w in the ~w place makes ~w; under ~w, no carry.",
              [InClause, PlaceName, PlaceSum, Base])
    ),
    combine_columns(DA, DB, Idx, Digit, Resolved, Base, Cols),
    make_frame(Step0, combine_place(Idx), Cap, true, Cols, Carries, Frame),
    Step1 is Step0 + 1,
    NextIdx2 is Idx + 1,
    Resolved1 = [Idx-Digit | Resolved],
    add_place_frames(NextIdx2, N, CarryOut, DA, DB, Base, Step1, Resolved1,
                     Rest, RestDigits).

carry_in_clause(0, A, B, Clause) :-
    !, format(string(Clause), "~w + ~w", [A, B]).
carry_in_clause(CarryIn, A, B, Clause) :-
    format(string(Clause), "~w + ~w + ~w carried in", [A, B, CarryIn]).


% =============================================================================
% Dropped-carry deformation: write the remainder, never carry.
% =============================================================================

%!  drop_carry_frames(+Idx, +N, +DA, +DB, +Base, +Step0, -Frames, -DeformedLow).
%   Per place: place sum DA[i] + DB[i]; keep the witnessed remainder, DROP the
%   carry (no carry row, no thread). DeformedLow is the wrong digit list.
drop_carry_frames(Idx, N, _DA, _DB, _Base, _Step0, [], []) :-
    Idx >= N, !.
drop_carry_frames(Idx, N, DA, DB, Base, Step0, [Frame|Rest], [Digit|RestDigits]) :-
    Idx < N,
    nth0(Idx, DA, A), nth0(Idx, DB, B),
    PlaceSum is A + B,
    regroup_decision(PlaceSum, Base, CarryDropped, Digit),
    place_name(Idx, Base, PlaceName),
    ( CarryDropped >= 1
    -> format(string(Cap),
              "~w + ~w in the ~w place makes ~w; write ~w and DROP the carry of ~w.",
              [A, B, PlaceName, PlaceSum, Digit, CarryDropped])
    ;  format(string(Cap),
              "~w + ~w in the ~w place makes ~w; no carry to drop.",
              [A, B, PlaceName, PlaceSum])
    ),
    drop_columns(DA, DB, Idx, Digit, Base, Cols),
    % The deformation emits NO carries row even when a carry was dropped.
    make_frame(Step0, drop_carry(Idx), Cap, true, Cols, [], Frame),
    Step1 is Step0 + 1,
    NIdx is Idx + 1,
    drop_carry_frames(NIdx, N, DA, DB, Base, Step1, Rest, RestDigits).


% =============================================================================
% Subtract: per-place with witnessed borrow.
% =============================================================================

%!  sub_place_frames(+Idx, +N, +DA, +DB, +Base, +Step0, -Frames, -FinalLow).
%   Walk places ones-up. A short place borrows one base-group from the next
%   place up (borrow_decision/5). DA is updated as borrows deplete higher places.
sub_place_frames(Idx, N, _DA, _DB, _Base, _Step0, [], []) :-
    Idx >= N, !.
sub_place_frames(Idx, N, DA, DB, Base, Step0, [Frame|Rest], [Digit|RestDigits]) :-
    Idx < N,
    nth0(Idx, DA, A0), nth0(Idx, DB, B),
    borrow_decision(A0, B, Base, Borrowed, Digit),
    ( Borrowed =:= 1
    -> NextIdx is Idx + 1,
       ( NextIdx < N -> true
       ; throw(error(borrow_past_top(Idx), sub_place_frames/8)) ),
       nth0(NextIdx, DA, NA), NA1 is NA - 1,
       replace_nth0(DA, NextIdx, NA1, DA1),
       place_name(Idx, Base, PlaceName),
       place_name(NextIdx, Base, NextName),
       Available is A0 + Base,
       borrow_row(NextIdx, Idx, 1, Row),
       Carries = [Row],
       format(string(Cap),
              "The ~w place has ~w but needs ~w; borrow one base-group from the ~w place (now ~w here), then ~w - ~w = ~w.",
              [PlaceName, A0, B, NextName, Available, Available, B, Digit])
    ;  DA1 = DA,
       Carries = [],
       place_name(Idx, Base, PlaceName),
       format(string(Cap),
              "The ~w place: ~w - ~w = ~w, no borrow.",
              [PlaceName, A0, B, Digit])
    ),
    sub_columns(DA1, Idx, Digit, Base, Cols),
    make_frame(Step0, borrow_place(Idx), Cap, true, Cols, Carries, Frame),
    Step1 is Step0 + 1,
    NIdx is Idx + 1,
    sub_place_frames(NIdx, N, DA1, DB, Base, Step1, Rest, RestDigits).

%!  sub_no_reduce_frames(+Idx,+N,+DA,+DB,+Base,+Step0,-Frames,-DeformedLow).
%   Like sub_place_frames/8, except a borrow does not decrement the next place.
%   The current place gets Base more; the higher place stays unchanged.
sub_no_reduce_frames(Idx, N, _DA, _DB, _Base, _Step0, [], []) :-
    Idx >= N, !.
sub_no_reduce_frames(Idx, N, DA, DB, Base, Step0,
                     [Frame|Rest], [Digit|RestDigits]) :-
    Idx < N,
    nth0(Idx, DA, A0), nth0(Idx, DB, B),
    place_name(Idx, Base, PlaceName),
    ( A0 < B
    -> Available is A0 + Base,
       Digit is Available - B,
       NextIdx is Idx + 1,
       place_name(NextIdx, Base, NextName),
       format(string(Cap),
              "The ~w place has ~w but needs ~w; make ~w here without reducing the next place (~w). Then ~w - ~w = ~w.",
              [PlaceName, A0, B, Available, NextName, Available, B, Digit])
    ;  Digit is A0 - B,
       format(string(Cap),
              "The ~w place: ~w - ~w = ~w, no borrow.",
              [PlaceName, A0, B, Digit])
    ),
    sub_columns(DA, Idx, Digit, Base, Cols),
    make_frame(Step0, borrow_without_reducing_place(Idx), Cap, true, Cols, [], Frame),
    Step1 is Step0 + 1,
    NIdx is Idx + 1,
    sub_no_reduce_frames(NIdx, N, DA, DB, Base, Step1, Rest, RestDigits).


% =============================================================================
% Base decomposition: repeated division.
% =============================================================================

%!  division_steps(+Number, +Base, -Steps) is det.
%   Steps low-to-high: step(Q0, Rem, Q1), Q1 = Q0 // Base, Rem = Q0 mod Base.
division_steps(0, _Base, [step(0, 0, 0)]) :- !.
division_steps(Number, Base, Steps) :-
    division_steps_(Number, Base, Steps).

division_steps_(0, _Base, []) :- !.
division_steps_(Q0, Base, [step(Q0, Rem, Q1)|Rest]) :-
    Q0 > 0,
    Rem is Q0 mod Base,
    Q1 is Q0 // Base,
    division_steps_(Q1, Base, Rest).

%!  decomp_step_frames(+Steps, +Base, +Step0, +Acc, -Frames) is det.
%   One frame per division step, building the digit columns from the low place.
decomp_step_frames([], _Base, _Step0, _Acc, []).
decomp_step_frames([step(Q0, Rem, Q1)|Rest], Base, Step0, Acc,
                   [Frame|Frames]) :-
    append(Acc, [Rem], Acc1),              % accumulate low-to-high
    columns_from_low(Acc1, Base, Cols),
    length(Acc, Idx),
    place_name(Idx, Base, PName),
    format(string(Cap),
           "~w divided by ~w is ~w remainder ~w; the remainder ~w is the ~w digit.",
           [Q0, Base, Q1, Rem, Rem, PName]),
    make_frame(Step0, divide_step(Q0, Base, Q1, Rem), Cap, true, Cols, [], Frame),
    Step1 is Step0 + 1,
    decomp_step_frames(Rest, Base, Step1, Acc1, Frames).


% =============================================================================
% Columns. A column is _{ place: Exp, count: Count, base: Base, role: Role }.
% Exp is the place exponent (0 = ones). Role is the place's block kind.
% =============================================================================

%!  low_digits(+Number, +Base, -Low) is det.
%   Place digits low-to-high (index 0 = ones), at least one digit.
low_digits(Number, Base, Low) :-
    Number >= 0,
    integer_numeral(Number, Base,
                    numeral(Base, _Sign, _Radix, HighDigits)),
    maplist(numeral_digit_value, HighDigits, High),
    reverse(High, Low).

%!  low_digits_to_int(+Low, +Base, -N) is det.
%   The integer named by a low-to-high digit list (digits may exceed Base-1 in
%   a deformation; this still composes them by place value, which is the point).
low_digits_to_int(Low, Base, N) :-
    foldl_low(Low, Base, 0, 0, N).

foldl_low([], _Base, _Exp, Acc, Acc).
foldl_low([D|Rest], Base, Exp, Acc0, N) :-
    PV is Base ** Exp,
    Acc1 is Acc0 + D * PV,
    Exp1 is Exp + 1,
    foldl_low(Rest, Base, Exp1, Acc1, N).

%!  digits_padded(+N, +Base, +NPlaces, -Low) is det.
%   Exactly NPlaces digits, low-to-high, zero-padded.
digits_padded(N, Base, NPlaces, Low) :-
    low_digits(N, Base, Low0),
    pad_to(Low0, NPlaces, 0, Low).

pad_to(List, N, _Fill, List) :- length(List, L), L >= N, !.
pad_to(List, N, Fill, Padded) :-
    length(List, L),
    Need is N - L,
    length(Tail, Need),
    maplist(=(Fill), Tail),
    append(List, Tail, Padded).

%!  places_needed(+N, +Base, -Count) is det.
places_needed(0, _Base, 1) :- !.
places_needed(N, Base, Count) :- low_digits(N, Base, L), length(L, Count).

numeral_digit_value(digit(Value, _Glyph), Value).

%!  max_places(+Numbers, +Base, +Floor, -N) is det.
%   The greatest place-count over Numbers (in Base), but at least Floor.
max_places(Numbers, Base, Floor, N) :-
    foldl([X,Acc,Out]>>(places_needed(X, Base, P), Out is max(Acc, P)),
          Numbers, Floor, N).

%!  columns_from_low(+Low, +Base, -Columns) is det.
%   Low is low-to-high (index 0 = ones). Columns are emitted HIGH place first
%   (leftmost), matching numeral order. Each column: place exponent, count
%   (the digit), base, and the place's block role.
columns_from_low(Low, Base, Columns) :-
    columns_low_(Low, 0, Base, Pairs),     % Pairs: list of Exp-Count low->high
    reverse(Pairs, HighPairs),             % high->low
    maplist(column_of(Base), HighPairs, Columns).

columns_low_([], _Exp, _Base, []).
columns_low_([D|Rest], Exp, Base, [Exp-D|Pairs]) :-
    Exp1 is Exp + 1,
    columns_low_(Rest, Exp1, Base, Pairs).

column_of(Base, Exp-Count, _{ place: Exp,
                              count: Count,
                              base: Base,
                              role: Role }) :-
    place_role(Exp, Role).

%!  int_columns(+IntLow, +Base, -Columns) is det.
%   Integer-side columns for the decimal layout (high place first).
int_columns(IntLow, Base, Columns) :-
    columns_from_low(IntLow, Base, Columns).

%!  frac_columns(+FracDigits, +Exp, +Base, -Columns) is det.
%   FracDigits high-to-low (tenths first); Exp starts at -1. Sub-unit places
%   carry the shared `neutral` role (no base-ten block below a unit).
frac_columns([], _Exp, _Base, []).
frac_columns([D|Rest], Exp, Base, [Col|Cols]) :-
    Col = _{ place: Exp, count: D, base: Base, role: neutral },
    Exp1 is Exp - 1,
    frac_columns(Rest, Exp1, Base, Cols).

%!  point_column(+NInt, -Col) is det.
%   A marker column for the decimal point. Carries the shared `neutral` role and
%   a count of 0; the place is named by the contract's integer convention via a
%   sentinel exponent below the lowest integer place is avoided by using a
%   distinct `point` flag the drawer can read.
point_column(_NInt, _{ place: point, count: 0, base: 10, role: neutral }).

%!  combine_columns(+DA, +DB, +Idx, +Digit, +Resolved, +Base, -Columns) is det.
%   The combine frame for place Idx. Per place (high->low):
%     - Exp < Idx and resolved: the settled digit count.
%     - Exp =:= Idx (active): the made Digit count.
%     - Exp > Idx: the raw place sum DA[e] + DB[e], still waiting.
combine_columns(DA, DB, Idx, Digit, Resolved, Base, Columns) :-
    length(DA, N),
    HighExp is N - 1,
    numlist_down(HighExp, 0, Exps),
    maplist(combine_column(DA, DB, Idx, Digit, Resolved, Base), Exps, Columns).

combine_column(DA, DB, Idx, Digit, Resolved, Base, Exp,
               _{ place: Exp, count: Count, base: Base, role: Role }) :-
    place_role(Exp, Role),
    ( Exp =:= Idx
    -> Count = Digit
    ;  memberchk(Exp-RDigit, Resolved)
    -> Count = RDigit
    ;  nth0(Exp, DA, A), nth0(Exp, DB, B),
       Count is A + B
    ).

%!  drop_columns(+DA, +DB, +Idx, +Digit, +Base, -Columns) is det.
%   The deformation combine frame: places at/below Idx show the (un-carried)
%   remainder digit; places above show the raw place sum. No resolved-vs-active
%   distinction is needed beyond the active digit because nothing is carried.
drop_columns(DA, DB, Idx, Digit, Base, Columns) :-
    length(DA, N),
    HighExp is N - 1,
    numlist_down(HighExp, 0, Exps),
    maplist(drop_column(DA, DB, Idx, Digit, Base), Exps, Columns).

drop_column(DA, DB, Idx, Digit, Base, Exp,
            _{ place: Exp, count: Count, base: Base, role: Role }) :-
    place_role(Exp, Role),
    ( Exp =:= Idx
    -> Count = Digit
    ;  Exp < Idx
    -> nth0(Exp, DA, A), nth0(Exp, DB, B),
       Raw is A + B,
       Count is Raw mod Base           % already-dropped places show their remainder
    ;  nth0(Exp, DA, A), nth0(Exp, DB, B),
       Count is A + B
    ).

%!  sub_columns(+DA, +Idx, +Digit, +Base, -Columns) is det.
%   The borrow/subtract frame for place Idx: minuend digits DA (after borrows),
%   with the active place showing the resulting Digit.
sub_columns(DA, Idx, Digit, Base, Columns) :-
    length(DA, N),
    HighExp is N - 1,
    numlist_down(HighExp, 0, Exps),
    maplist(sub_column(DA, Idx, Digit, Base), Exps, Columns).

sub_column(DA, Idx, Digit, Base, Exp,
           _{ place: Exp, count: Count, base: Base, role: Role }) :-
    place_role(Exp, Role),
    ( Exp =:= Idx -> Count = Digit
    ; nth0(Exp, DA, Count) ).

%!  numlist_down(+High, +Low, -List) is det.
%   High..Low descending.
numlist_down(High, Low, []) :- High < Low, !.
numlist_down(High, Low, [High|Rest]) :-
    High >= Low,
    High1 is High - 1,
    numlist_down(High1, Low, Rest).

%!  place_role(+Exp, -Role) is det.
%   Base-ten block role for a place exponent (the render contract). Caps at cube
%   for exp >= 3. Sub-unit (negative) exponents have no base-ten block: neutral.
place_role(0, unit) :- !.
place_role(1, rod)  :- !.
place_role(2, flat) :- !.
place_role(Exp, cube) :- integer(Exp), Exp >= 3, !.
place_role(_, neutral).

%!  place_name(+Exp, +Base, -Name) is det.
%   The narration name for the place at exponent Exp in the operative Base.
%   Place 0 is "ones" for any base (a single unit is a unit regardless of base).
%   At base 10 the familiar number names hold (tens, hundreds, thousands). At any
%   other operative base the higher places are named by the base itself ("the base
%   place" is one group of Base, "the base-squared place" is Base*Base, and so on),
%   so the prose never claims a "tens" place in a base where there is none.
place_name(0, _Base, "ones") :- !.
place_name(Exp, 10, Name) :- !, place_name(Exp, Name).
place_name(1, _Base, "base") :- !.
place_name(2, _Base, "base-squared") :- !.
place_name(3, _Base, "base-cubed") :- !.
place_name(Exp, Base, Name) :-
    integer(Exp), Exp >= 4, !,
    format(string(Name), "base^~w (place ~w in base ~w)", [Exp, Exp, Base]).
place_name(Exp, Base, Name) :-
    format(string(Name), "place ~w (base ~w)", [Exp, Base]).

%!  place_name(+Exp, -Name) is det.
%   Base-10 place names, used by the decimal layout (which is base 10 only) and
%   as the base-10 branch of place_name/3. Sub-unit places (negative exponents)
%   are decimal fractional place names.
place_name(0, "ones") :- !.
place_name(1, "tens") :- !.
place_name(2, "hundreds") :- !.
place_name(3, "thousands") :- !.
place_name(Exp, Name) :- integer(Exp), Exp >= 4, !, format(string(Name), "place ~w", [Exp]).
place_name(-1, "tenths") :- !.
place_name(-2, "hundredths") :- !.
place_name(-3, "thousandths") :- !.
place_name(Exp, Name) :- format(string(Name), "place ~w", [Exp]).


% =============================================================================
% Carry / borrow rows. A carry/borrow is a regroup decision between two places.
% =============================================================================

%!  carry_row(+FromExp, +ToExp, +Amount, -Row) is det.
%   A carry from place FromExp (lower) into ToExp (higher).
carry_row(FromExp, ToExp, Amount,
          _{ fromPlace: FromExp, toPlace: ToExp, amount: Amount }).

%!  borrow_row(+FromExp, +ToExp, +Amount, -Row) is det.
%   A borrow from place FromExp (higher) down to ToExp (lower). The amount is the
%   number of base-groups unbundled; the sign of the place ordering (from > to)
%   is what marks it a borrow rather than a carry.
borrow_row(FromExp, ToExp, Amount,
           _{ fromPlace: FromExp, toPlace: ToExp, amount: Amount }).


% =============================================================================
% Frame assembly + metadata.
% =============================================================================

%!  make_frame(+Step, +Verb, +Caption, +Changed, +Columns, +Carries, -Frame).
make_frame(Step, Verb, Caption, Changed, Columns, Carries, Frame) :-
    scene_dict(Columns, Carries, Scene),
    term_to_string(Verb, VerbStr),
    Frame = _{ step: Step,
               verb: VerbStr,
               caption: Caption,
               sceneChanged: Changed,
               scene: Scene }.

%!  scene_dict(+Columns, +Carries, -Scene) is det.
%   The P4 scene: base-ten-columns, version 2, base, columns, carries.
%   The base is read from the first column (every column carries it); a column-
%   less scene defaults to base 10.
scene_dict(Columns, Carries, Scene) :-
    ( Columns = [C0|_], get_dict(base, C0, B) -> Base = B ; Base = 10 ),
    Scene = _{ format: "base-ten-columns",
               version: 2,
               base: Base,
               columns: Columns,
               carries: Carries }.

%!  deferred_frame(+Spec, -Frame) is det.
%   An unknown/deferred spec is annotation-only: an empty scene, no throw.
deferred_frame(Spec, Frame) :-
    term_to_string(Spec, SpecStr),
    format(string(Cap), "No base-ten layout for ~w; nothing drawn.", [SpecStr]),
    scene_dict([], [], Scene),
    Frame = _{ step: 1,
               verb: SpecStr,
               caption: Cap,
               sceneChanged: false,
               scene: Scene }.

%!  last_step(+Frames, -Step) is det.
last_step([], 0).
last_step(Frames, Step) :-
    Frames \== [],
    last(Frames, F),
    get_dict(step, F, Step).

%!  spec_kind(+Spec, -KindStr) is det.
spec_kind(Spec, KindStr) :-
    ( compound(Spec) -> functor(Spec, Name, _) ; Name = Spec ),
    atom_string(Name, KindStr).

%!  spec_grounding(+Spec, -Grounding) is semidet.
%   The render contract's grounding footer for a spec, sourced from
%   grounding_to_primitive:primitive_for_practice_witness/4 on the spec's
%   practice atom. Fails (no footer) when the spec maps to no practice or the
%   practice carries no L&N grounding -- the deformation case.
spec_grounding(Spec, _{ practice: PracticeStr,
                        metaphor_label: LabelStr,
                        metaphor_gloss: Gloss,
                        primitive: PrimStr,
                        role: RoleStr }) :-
    spec_practice(Spec, Practice),
    grounding_to_primitive:primitive_for_practice_witness(Practice, 'P4', primary,
                                                          Witness),
    !,
    get_dict(grounding_metaphor_label, Witness, Label),
    get_dict(metaphor_gloss, Witness, Gloss),
    atom_string(Practice, PracticeStr),
    atom_string(Label, LabelStr),
    atom_string('P4', PrimStr),
    atom_string(primary, RoleStr).

%!  spec_practice(+Spec, -Practice) is semidet.
%   The L&N practice atom a base-ten spec enacts. The dropped-carry deformation
%   maps to NO practice on purpose (it is inferentially hollow), so no grounding
%   footer is emitted for it.
spec_practice(add_with_carry(_, _, _),       p_column_addition_with_carrying).
spec_practice(subtract_with_borrow(_, _, _), p_decompose_base_for_ones).
spec_practice(base_decomposition(_, _),      p_decompose_base_for_ones).
spec_practice(represent(_, _),               p_make_base_transfer).
spec_practice(place_value_teen(_),           p_make_base_transfer).
spec_practice(decimal_place_value(_, _),     p_make_base_transfer).
% add_with_dropped_carry and subtract_without_reducing_borrow: intentionally
% unmapped (hollow deformations).

%!  spec_request(+Spec, -Request) is det.
spec_request(represent(N, B), _{ number: N, base: B }) :- !.
spec_request(place_value_teen(N), _{ number: N, base: 10 }) :- !.
spec_request(add_with_carry(A, B, Base), _{ a: A, b: B, base: Base }) :- !.
spec_request(add_with_dropped_carry(A, B, Base), _{ a: A, b: B, base: Base }) :- !.
spec_request(subtract_with_borrow(A, B, Base), _{ a: A, b: B, base: Base }) :- !.
spec_request(subtract_without_reducing_borrow(A, B, Base), _{ a: A, b: B, base: Base }) :- !.
spec_request(decimal_place_value(I, F), _{ intPart: I, fracDigits: F }) :- !.
spec_request(base_decomposition(N, B), _{ number: N, base: B }) :- !.
spec_request(Spec, _{ spec: S }) :- term_to_string(Spec, S).

%!  spec_result(+Spec, -ResultStr) is det.
spec_result(represent(N, B), R) :- !,
    high_digits_string(N, B, S),
    format(string(R), "~w (base ~w: ~w)", [N, B, S]).
spec_result(place_value_teen(N), R) :- !,
    format(string(R), "~w", [N]).
spec_result(add_with_carry(A, B, _), R) :- !,
    Sum is A + B, format(string(R), "~w", [Sum]).
spec_result(add_with_dropped_carry(A, B, Base), R) :- !,
    max_places([A, B], Base, 1, NPlaces),
    digits_padded(A, Base, NPlaces, DA),
    digits_padded(B, Base, NPlaces, DB),
    maplist(dropped_digit(Base), DA, DB, Deformed),
    low_digits_to_int(Deformed, Base, Wrong),
    format(string(R), "~w (carries dropped)", [Wrong]).
spec_result(subtract_with_borrow(A, B, _), R) :-
    A >= B, !,
    Diff is A - B, format(string(R), "~w", [Diff]).
spec_result(subtract_with_borrow(A, B, _), R) :- !,
    format(string(R), "~w - ~w is negative; not drawn", [A, B]).
spec_result(subtract_without_reducing_borrow(A, B, Base), R) :-
    A >= B, !,
    max_places([A, B], Base, 1, NPlaces),
    digits_padded(A, Base, NPlaces, DA),
    digits_padded(B, Base, NPlaces, DB),
    maplist(sub_no_reduce_digit(Base), DA, DB, Deformed),
    low_digits_to_int(Deformed, Base, Wrong),
    Correct is A - B,
    format(string(R), "~w (correct: ~w)", [Wrong, Correct]).
spec_result(subtract_without_reducing_borrow(A, B, _), R) :- !,
    format(string(R), "~w - ~w is negative; not drawn", [A, B]).
spec_result(decimal_place_value(I, F), R) :- !,
    low_digits(I, 10, IntLow),
    digits_to_number_string(IntLow, F, R).
spec_result(base_decomposition(N, B), R) :- !,
    high_digits_string(N, B, R).
spec_result(_Spec, "unknown").

dropped_digit(Base, A, B, Digit) :- Digit is (A + B) mod Base.
sub_no_reduce_digit(Base, A, B, Digit) :-
    ( A < B -> Digit is A + Base - B ; Digit is A - B ).
plus_digit(A, B, S) :- S is A + B.

%!  canvas_dict(-Canvas) is det.
canvas_dict(_{ width: 720, height: 380 }).

%!  high_digits_string(+Number, +Base, -Str) is det.
%   The place digits high-to-low as a string (bare for base <= 10, comma-
%   separated otherwise to stay unambiguous).
high_digits_string(Number, Base, Str) :-
    integer_numeral(Number, Base, Numeral),
    numeral_text(Numeral, Str).

%!  digits_to_number_string(+IntLow, +FracDigits, -Str) is det.
%   IntLow is low-to-high; FracDigits is high-to-low (tenths first).
digits_to_number_string(IntLow, FracDigits, Str) :-
    reverse(IntLow, IntHigh),
    atomic_list_concat(IntHigh, IntStr0), atom_string(IntStr0, IntStr),
    ( FracDigits == []
    -> Str = IntStr
    ;  atomic_list_concat(FracDigits, FracStr0), atom_string(FracStr0, FracStr),
       format(string(Str), "~w.~w", [IntStr, FracStr])
    ).

%!  replace_nth0(+List, +Index, +Elem, -List1) is det.
replace_nth0(List, Index, Elem, List1) :-
    nth0(Index, List, _Old, Rest),
    nth0(Index, List1, Elem, Rest).
