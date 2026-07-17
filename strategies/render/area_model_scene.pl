/** <module> Area/array-model scene compiler (P3) — witness-walked
 *
 * Compiles an array / area-model claim into a sequence of scene frames in the
 * "area-model" v2 schema (docs/render-contract-v2.md). The direction is
 * Prolog -> picture, and the
 * counts that drive the picture come from witnesses, not from a re-multiply of
 * the integer inputs:
 *
 *   - standard_3_ca_3_4:multiply_array_witness/4 supplies the grid's
 *     rows_count / cols_count / product_count, and its rotated_model sub-dict
 *     supplies the transpose (the same finite cell count under rotation). The
 *     compiler reads those counts; it does not compute R*C or C*R itself.
 *   - cw_arithmetic_property_claim:arithmetic_property_witness/4 supplies the
 *     commutativity (commutativity_operation_specific) and distributivity
 *     (distributivity_over_sum) commitment glosses that label the property a
 *     transpose or a four-block tiling answers to.
 *   - fraction_action_pairs:run_fraction_action/5 supplies the area-model
 *     fraction-multiplication overlap. The productive automaton
 *     (area_model_part_of_part) reports the numerator/denominator products in
 *     its components term; the picture walks those, not a recomputed NA*NB.
 *
 * Color is emitted as a SEMANTIC ROLE atom per fill (whole / highlight /
 * iterated / inner / deformation / neutral), never a hex string. The Gate-E
 * token stylesheet maps each role to a CSS variable (--fig-<role>); this
 * compiler owns the geometry, the stylesheet owns the palette.
 *
 * The productive-vs-deformation contrast (area_compare/4) draws the
 * cross-multiplication-without-ground deformation as the OMITTED cross terms:
 * the productive overlap is the part-of-part rectangle the area model justifies,
 * and the deformation rectangle is shown in the `deformation` role to mark that
 * the same numbers were produced with no area figure of their own. The omitted
 * cross terms are the cells the deformation never partitions.
 *
 * An integer-only path is retained ONLY behind a test-mode flag
 * (area_model_test_mode/0, off by default). The default render path always
 * walks the witnesses; if a witness cannot be sourced the compiler emits an
 * annotation-only frame (sceneChanged:false) rather than recomputing or
 * throwing.
 *
 * Scope note. The four-block partial-products picture is a layout of the
 * identity (10+3)(10+4) = 100+40+30+12; it does not itself prove the
 * distributive law. The witness's distributivity gloss is the commitment the
 * layout answers to, carried as scene metadata, not a derivation.
 */

:- module(area_model_scene,
          [ area_render_frames/2,        % +Spec, -Frames
            area_render_json/2,          % +Spec, -Dict
            area_render_to_file/2,       % +Spec, +Path
            area_compare_json/2,         % +Spec, -Dict
            set_area_model_test_mode/1   % +Bool  (true|false)
          ]).

:- use_module(standards(indiana/standard_3_ca_3_4),
              [ multiply_array_witness/4 ]).
:- use_module(formalization(grounded_arithmetic),
              [ integer_to_recollection/2,
                recollection_to_integer/2 ]).
:- use_module(strategies(math/fraction_action_pairs),
              [ run_fraction_action/5 ]).
:- use_module(crosswalk(families/cw_arithmetic_property_claim),
              [ arithmetic_property_witness/4 ]).
:- use_module(library(http/json), [json_write_dict/3]).
:- use_module(library(lists)).
:- use_module(library(apply)).

% -----------------------------------------------------------------------------
% Geometry constants. UnitW = 420 = 2^2*3*5*7 divides evenly for the common
% partition counts, so cell widths stay integral when a unit square is split.
% Arrays use a fixed cell size; the unit square uses the full unit length.
% Canvas origin near (40,40), integer coordinates only.
% -----------------------------------------------------------------------------
origin_x(40).
origin_y(40).
unit_len(420).      % side of the unit square / full array length reference
cell_w(64).         % default array cell width
cell_h(48).         % default array cell height

% -----------------------------------------------------------------------------
% Test-mode flag. When true, the witness-walked generators fall back to an
% integer path so a geometry invariant can be checked without the standards /
% crosswalk witness layer loaded. Off by default; the default render path never
% recomputes from integers.
% -----------------------------------------------------------------------------
:- dynamic area_model_test_mode/0.

set_area_model_test_mode(true)  :- ( area_model_test_mode -> true ; assertz(area_model_test_mode) ).
set_area_model_test_mode(false) :- retractall(area_model_test_mode).


%!  area_render_frames(+Spec, -Frames) is det.
%
%   Build the filmstrip for the generator Spec. Each known generator emits one
%   or more frames; an unknown Spec, or one whose witness cannot be sourced,
%   emits a single annotation-only frame so the filmstrip narrates without
%   throwing.
area_render_frames(Spec, Frames) :-
    ( gen_frames(Spec, Frames0)
    -> Frames = Frames0
    ;  unknown_frame(Spec, F),
       Frames = [F]
    ).


% =============================================================================
% Witness sourcing. The grid counts come from multiply_array_witness/4, whose
% Rows/Cols arguments are grounded recollections. We feed it recollections and
% read the integer *_count fields back off the witness dict.
% =============================================================================

%!  array_grid_witness(+R, +C, -RowsCount, -ColsCount, -Product, -Rotated) is semidet.
%
%   RowsCount/ColsCount/Product are the witness's own counts (not R*C). Rotated
%   is rotated(RotRows, RotCols, RotProduct) from the witness's rotated_model.
array_grid_witness(R, C, RowsCount, ColsCount, Product, rotated(RotRows, RotCols, RotProduct)) :-
    integer(R), integer(C), R >= 1, C >= 1,
    integer_to_recollection(R, RecR),
    integer_to_recollection(C, RecC),
    catch(multiply_array_witness(RecR, RecC, _ProdRec, Witness), _, fail),
    RowsCount = Witness.rows_count,
    ColsCount = Witness.cols_count,
    Product   = Witness.product_count,
    Rot       = Witness.rotated_model,
    RotRows    = Rot.rows_count,
    RotCols    = Rot.cols_count,
    RotProduct = Rot.product_count.

%!  property_gloss(+Canonical, -Gloss) is semidet.
%
%   The literature-commitment gloss the property answers to, from
%   arithmetic_property_witness/4. Used as scene metadata, not as a derivation.
property_gloss(Canonical, Gloss) :-
    catch(arithmetic_property_witness(Canonical, commitment(_, Gloss),
                                      literature_commitment, _),
          _, fail),
    !.

%!  fraction_overlap_witness(+NA,+DA,+NB,+DB, -NumProd, -DenProd, -Result) is semidet.
%
%   The numerator/denominator products and the result fraction the productive
%   area-model automaton reports in its components term.
fraction_overlap_witness(NA, DA, NB, DB, NumProd, DenProd, Result) :-
    catch(run_fraction_action(area_model_part_of_part,
                              fraction_pair(NA, DA, NB, DB),
                              unit(whole), Outcome, _Trace),
          _, fail),
    Outcome = action_outcome(area_model_part_of_part, Props),
    memberchk(components(fraction_multiplication_components(NumProd, DenProd, Result)),
              Props).

%!  fraction_deformation_witness(+NA,+DA,+NB,+DB, -NumProd, -DenProd, -Result) is semidet.
%
%   The same products from the cross-multiplication-without-ground deformation.
%   It produces the correct numbers with no area figure of its own.
fraction_deformation_witness(NA, DA, NB, DB, NumProd, DenProd, Result) :-
    catch(run_fraction_action(cross_multiplication_rule_without_ground,
                              fraction_pair(NA, DA, NB, DB),
                              unit(whole), Outcome, _Trace),
          _, fail),
    Outcome = action_outcome(cross_multiplication_rule_without_ground, Props),
    memberchk(components(fraction_multiplication_components(NumProd, DenProd, Result)),
              Props).


% =============================================================================
% Generators. Each clause of gen_frames/2 maps a generator term to a list of
% frames. Frames are 1-based; each carries a v2 area-model scene.
% =============================================================================

%!  gen_frames(+Spec, -Frames) is semidet.

% --- array_multiplication(R, C): one R-by-C grid, all cells highlighted. ------
%   Counts are the witness's rows_count / cols_count / product_count.
gen_frames(array_multiplication(R, C), [Frame]) :-
    integer(R), integer(C), R >= 1, C >= 1,
    !,
    grid_counts(R, C, Rows, Cols, P),
    grid_rect(0, 0, Rows, Cols, highlight, "", RectGrid),
    grid_lines(0, 0, Rows, Cols, Lines),
    Scene = scene(Rows, Cols, [RectGrid], Lines),
    format(string(Cap), "~w rows by ~w columns = ~w cells.", [Rows, Cols, P]),
    make_frame(1, array_multiplication(R, C), Cap, true, Scene, Frame).

% --- commutativity_by_transpose(R, C): R x C, then the transpose from the
%     witness's rotated_model (not a recomputed C x R). -----------------------
gen_frames(commutativity_by_transpose(R, C), [F1, F2]) :-
    integer(R), integer(C), R >= 1, C >= 1,
    !,
    transpose_counts(R, C, Rows, Cols, P, RotRows, RotCols, RotP),
    % Frame 1: the R x C grid.
    grid_rect(0, 0, Rows, Cols, highlight, "", Grid1),
    grid_lines(0, 0, Rows, Cols, Lines1),
    Scene1 = scene(Rows, Cols, [Grid1], Lines1),
    format(string(Cap1), "~w rows by ~w columns = ~w cells.", [Rows, Cols, P]),
    make_frame(1, commutativity_by_transpose(R, C), Cap1, true, Scene1, F1),
    % Frame 2: the rotated model the witness records.
    grid_rect(0, 0, RotRows, RotCols, iterated, "", Grid2),
    grid_lines(0, 0, RotRows, RotCols, Lines2),
    Scene2 = scene(RotRows, RotCols, [Grid2], Lines2),
    ( property_gloss(commutativity_operation_specific, Gloss)
    -> format(string(Cap2),
              "Rotated: ~w rows by ~w columns = ~w cells. The cell count is unchanged. ~w",
              [RotRows, RotCols, RotP, Gloss])
    ;  format(string(Cap2),
              "Rotated: ~w rows by ~w columns = ~w cells. The cell count is unchanged.",
              [RotRows, RotCols, RotP])
    ),
    make_frame(2, commutativity_by_transpose(R, C), Cap2, true, Scene2, F2).

% --- partial_products(A, B): split A,B into tens/ones, four accumulating
%     inner blocks tiling the A x B rectangle. One frame per partial product. --
gen_frames(partial_products(A, B), Frames) :-
    integer(A), integer(B), A >= 10, A =< 99, B >= 10, B =< 99,
    !,
    grid_counts(A, B, Rows, Cols, Total),
    At is (Rows // 10) * 10, Ao is Rows mod 10,
    Bt is (Cols // 10) * 10, Bo is Cols mod 10,
    % Four blocks as (rowStart, colStart, rows, cols, value). All inner role;
    % each labelled with its own partial product. Tens then ones.
    P1v is At * Bt, P2v is At * Bo, P3v is Ao * Bt, P4v is Ao * Bo,
    Blocks = [ block(0,  0,  At, Bt, P1v),
               block(0,  Bt, At, Bo, P2v),
               block(At, 0,  Ao, Bt, P3v),
               block(At, Bt, Ao, Bo, P4v) ],
    ( property_gloss(distributivity_over_sum, Gloss) -> DistGloss = Gloss ; DistGloss = "" ),
    partial_frames(Blocks, [], 0, At, Bt, Ao, Bo, Rows, Cols, Total, DistGloss, Frames).

% --- area_model_fraction(NA, DA, NB, DB): unit square, split DA one way and DB
%     the other; the NA-by-NB overlap is the product. Counts (numerator and
%     denominator products) come from the area-model automaton's components. ---
gen_frames(area_model_fraction(NA, DA, NB, DB), [F1, F2, F3]) :-
    integer(NA), integer(DA), integer(NB), integer(DB),
    DA >= 1, DB >= 1, NA >= 0, NA =< DA, NB >= 0, NB =< DB,
    !,
    fraction_counts(NA, DA, NB, DB, NumProd, DenProd, ResultStr),
    % Frame 1: vertical split into DA columns, the first NA selected.
    unit_square_rect(USq),
    vertical_band(NA, DA, highlight, VBand),
    Scene1 = scene_unit([USq, VBand], DA, 1),
    format(string(Cap1), "Split the unit square into ~w columns; select ~w (~w/~w one way).",
           [DA, NA, NA, DA]),
    make_frame(1, area_model_fraction(NA, DA, NB, DB), Cap1, true, Scene1, F1),
    % Frame 2: horizontal split into DB rows, the first NB selected.
    horizontal_band(NB, DB, iterated, HBand),
    Scene2 = scene_unit([USq, VBand, HBand], DA, DB),
    format(string(Cap2), "Split the other way into ~w rows; select ~w (~w/~w the other way).",
           [DB, NB, NB, DB]),
    make_frame(2, area_model_fraction(NA, DA, NB, DB), Cap2, true, Scene2, F2),
    % Frame 3: the overlap rectangle, NA columns by NB rows; counts from witness.
    overlap_rect(NA, DA, NB, DB, inner, NumProd, ORect),
    Scene3 = scene_unit([USq, ORect], DA, DB),
    format(string(Cap3),
           "The overlap is ~w of ~w small rectangles: ~w/~w x ~w/~w = ~w.",
           [NumProd, DenProd, NA, DA, NB, DB, ResultStr]),
    make_frame(3, area_model_fraction(NA, DA, NB, DB), Cap3, true, Scene3, F3).


% --- partial_products accumulation -------------------------------------------

%!  partial_frames(+Blocks, +AccIn, +StepIn, +At,+Bt,+Ao,+Bo, +Rows,+Cols, +Total, +DistGloss, -Frames) is det.
%   Walk the four blocks, accumulating one frame per block; the final frame's
%   caption sums the partial products and carries the distributivity gloss.
partial_frames([], _Acc, _Step, _At, _Bt, _Ao, _Bo, _Rows, _Cols, _Total, _DG, []).
partial_frames([Block|Rest], Acc0, Step0, At, Bt, Ao, Bo, Rows, Cols, Total, DG, [Frame|More]) :-
    Step1 is Step0 + 1,
    block_rect(Block, Rect),
    append(Acc0, [Rect], Acc1),
    block_caption(Block, Rest, At, Bt, Ao, Bo, Rows, Cols, Total, DG, Cap),
    grid_lines(0, 0, Rows, Cols, Lines),
    Scene = scene(Rows, Cols, Acc1, Lines),
    make_frame(Step1, partial_products(Rows, Cols), Cap, true, Scene, Frame),
    partial_frames(Rest, Acc1, Step1, At, Bt, Ao, Bo, Rows, Cols, Total, DG, More).

block(RS, CS, R, C, V) :- block_(RS, CS, R, C, V).
block_(_, _, _, _, _).   % structural marker only

block_rect(block(RS, CS, R, C, V), Rect) :-
    format(string(Label), "~w", [V]),
    grid_rect(RS, CS, R, C, inner, Label, Rect).

block_caption(block(RS, CS, R, C, V), Rest, At, Bt, Ao, Bo, Rows, Cols, Total, DG, Cap) :-
    factor_label(RS, At, Ao, RowFactor),
    factor_label(CS, Bt, Bo, ColFactor),
    ( Rest == []
    -> P1v is At * Bt, P2v is At * Bo, P3v is Ao * Bt, P4v is Ao * Bo,
       ( DG == ""
       -> format(string(Cap),
                 "~w x ~w = ~w. The four blocks tile ~w x ~w: ~w + ~w + ~w + ~w = ~w.",
                 [RowFactor, ColFactor, V, Rows, Cols, P1v, P2v, P3v, P4v, Total])
       ;  format(string(Cap),
                 "~w x ~w = ~w. The four blocks tile ~w x ~w: ~w + ~w + ~w + ~w = ~w. ~w",
                 [RowFactor, ColFactor, V, Rows, Cols, P1v, P2v, P3v, P4v, Total, DG])
       )
    ;  format(string(Cap), "Partial product: ~w x ~w = ~w.",
              [RowFactor, ColFactor, V])
    ),
    _ = R, _ = C.

%!  factor_label(+Start, +Tens, +Ones, -Factor) is det.
%   A block starting at row/col 0 spans the tens part; one starting at Tens
%   spans the ones part.
factor_label(0, Tens, _Ones, Tens) :- !.
factor_label(_, _Tens, Ones, Ones).


% =============================================================================
% Count sourcing with a test-mode integer fallback. The default path walks the
% witness; the fallback only fires under area_model_test_mode.
% =============================================================================

%!  grid_counts(+R, +C, -Rows, -Cols, -Product) is semidet.
grid_counts(R, C, Rows, Cols, Product) :-
    ( array_grid_witness(R, C, Rows, Cols, Product, _Rot)
    -> true
    ;  area_model_test_mode,
       Rows = R, Cols = C, Product is R * C
    ).

%!  transpose_counts(+R,+C, -Rows,-Cols,-P, -RotRows,-RotCols,-RotP) is semidet.
transpose_counts(R, C, Rows, Cols, P, RotRows, RotCols, RotP) :-
    ( array_grid_witness(R, C, Rows, Cols, P, rotated(RotRows, RotCols, RotP))
    -> true
    ;  area_model_test_mode,
       Rows = R, Cols = C, P is R * C,
       RotRows = C, RotCols = R, RotP is C * R
    ).

%!  fraction_counts(+NA,+DA,+NB,+DB, -NumProd, -DenProd, -ResultStr) is semidet.
fraction_counts(NA, DA, NB, DB, NumProd, DenProd, ResultStr) :-
    ( fraction_overlap_witness(NA, DA, NB, DB, NumProd, DenProd, Result)
    -> term_to_string(Result, ResultStr)
    ;  area_model_test_mode,
       NumProd is NA * NB, DenProd is DA * DB,
       format(string(ResultStr), "~w/~w", [NumProd, DenProd])
    ).


% =============================================================================
% Productive-vs-deformation comparison (area_compare). The productive overlap
% is the part-of-part rectangle the area model justifies. The deformation
% (cross-multiplication-without-ground) is the SAME numbers with no area figure
% of its own; it is drawn in the `deformation` role over the cells it never
% partitions — the omitted cross terms.
% =============================================================================

%!  area_compare_frames(+NA,+DA,+NB,+DB, -ProdFrames, -DefFrames) is semidet.
area_compare_frames(NA, DA, NB, DB, ProdFrames, DefFrames) :-
    integer(NA), integer(DA), integer(NB), integer(DB),
    DA >= 1, DB >= 1, NA >= 0, NA =< DA, NB >= 0, NB =< DB,
    fraction_overlap_witness(NA, DA, NB, DB, NumProd, DenProd, Result),
    fraction_deformation_witness(NA, DA, NB, DB, NumProd, DenProd, Result),
    term_to_string(Result, ResultStr),
    % Productive: the grounded overlap rectangle (inner role).
    area_render_frames(area_model_fraction(NA, DA, NB, DB), ProdFrames),
    deformation_frames(NA, DA, NB, DB, NumProd, DenProd, ResultStr, DefFrames).

deformation_frames(NA, DA, NB, DB, NumProd, DenProd, ResultStr, [F1, F2, F3]) :-
    unit_square_rect(USq),
    % Beginning: the same partitioned unit is on the table, but no selected
    % overlap exists yet.
    Scene1 = scene_unit([USq], DA, DB),
    format(string(Cap1),
           "Begin with the same unit square split into ~w columns and ~w rows.",
           [DA, DB]),
    make_frame(1, cross_multiplication_begin(NA, DA, NB, DB),
               Cap1, true, Scene1, F1),
    % Middle: the rule produces a numerator count outside the unit square.
    omitted_cross_terms(NA, DA, NB, DB, deformation, NumProd, ProductRect),
    Scene2 = scene_unit([USq, ProductRect], DA, DB),
    format(string(Cap2),
           "Multiply the numerators: ~w x ~w gives ~w, but the product is not an overlap in the unit square.",
           [NA, NB, NumProd]),
    make_frame(2, multiply_without_area_unit(NA, DA, NB, DB),
               Cap2, true, Scene2, F2),
    % End: the detached product is reported against the denominator count.
    ungrounded_denominator_rect(DenProd, neutral, DenRect),
    Scene3 = scene_unit([USq, DenRect, ProductRect], DA, DB),
    format(string(Cap3),
           "Report ~w/~w x ~w/~w = ~w: ~w of ~w small rectangles are outside the unit square, not built as an overlap.",
           [NA, DA, NB, DB, ResultStr, NumProd, DenProd]),
    make_frame(3, detached_product_report(NA, DA, NB, DB),
               Cap3, true, Scene3, F3).

%!  omitted_cross_terms(+NA,+DA,+NB,+DB, +Role, +NumProd, -Rect) is det.
%   The numerator product the deformation produces without building an overlap.
%   It is intentionally detached from the unit square so the picture distinguishes
%   "got the same number" from "preserved the area-model grammar".
omitted_cross_terms(_NA, _DA, _NB, _DB, Role, NumProd, Rect) :-
    ungrounded_product_rect(NumProd, Role, Rect).


% =============================================================================
% Rect construction. Every drawable is a plain dict so json_write_dict
% serializes it directly. The drawer convention: rect cells are an R-by-C grid
% of cellW-by-cellH boxes; the rect's w/h is rows*cellW etc.
% =============================================================================

%!  grid_rect(+RowStart, +ColStart, +Rows, +Cols, +Role, +Label, -Rect) is det.
%   An array grid of Rows x Cols cells, each cell_w x cell_h, anchored at the
%   given cell offset from the origin. Carries a semantic role atom, never hex.
grid_rect(RowStart, ColStart, Rows, Cols, Role, Label, Rect) :-
    origin_x(OX), origin_y(OY),
    cell_w(CW), cell_h(CH),
    X is OX + ColStart * CW,
    Y is OY + RowStart * CH,
    W is Cols * CW,
    H is Rows * CH,
    role_atom(Role, RoleAtom),
    Rect = _{ x: X, y: Y, w: W, h: H,
              rows: Rows, cols: Cols,
              cellW: CW, cellH: CH,
              role: RoleAtom, label: Label, kind: "grid" }.

%!  grid_lines(+RowStart, +ColStart, +Rows, +Cols, -Lines) is det.
%   Vertical and horizontal interior grid line coordinates for an array grid,
%   as gridlines(Vs, Hs) (lists of pixel x / y). The drawer reads {v:[...],h:[...]}.
grid_lines(RowStart, ColStart, Rows, Cols, gridlines(Vs, Hs)) :-
    origin_x(OX), origin_y(OY),
    cell_w(CW), cell_h(CH),
    X0 is OX + ColStart * CW,
    Y0 is OY + RowStart * CH,
    findall(VX, ( between(0, Cols, K), VX is X0 + K * CW ), Vs),
    findall(HY, ( between(0, Rows, K), HY is Y0 + K * CH ), Hs).

%!  unit_square_rect(-Rect) is det.
%   The full unit square: a backdrop spanning the unit length, role whole.
unit_square_rect(Rect) :-
    origin_x(OX), origin_y(OY),
    unit_len(L),
    role_atom(whole, RoleAtom),
    Rect = _{ x: OX, y: OY, w: L, h: L,
              rows: 1, cols: 1, cellW: L, cellH: L,
              role: RoleAtom, label: "", kind: "square" }.

%!  vertical_band(+NA, +DA, +Role, -Rect) is det.
%   The leftmost NA of DA vertical columns of the unit square.
vertical_band(NA, DA, Role, Rect) :-
    origin_x(OX), origin_y(OY),
    unit_len(L),
    role_atom(Role, RoleAtom),
    ColW is L // DA,
    W is NA * ColW,
    Rect = _{ x: OX, y: OY, w: W, h: L,
              rows: 1, cols: NA, cellW: ColW, cellH: L,
              role: RoleAtom, label: "", kind: "band" }.

%!  horizontal_band(+NB, +DB, +Role, -Rect) is det.
%   The topmost NB of DB horizontal rows of the unit square.
horizontal_band(NB, DB, Role, Rect) :-
    origin_x(OX), origin_y(OY),
    unit_len(L),
    role_atom(Role, RoleAtom),
    RowH is L // DB,
    H is NB * RowH,
    Rect = _{ x: OX, y: OY, w: L, h: H,
              rows: NB, cols: 1, cellW: L, cellH: RowH,
              role: RoleAtom, label: "", kind: "band" }.

%!  overlap_rect(+NA,+DA,+NB,+DB, +Role, +NumProd, -Rect) is det.
%   The NA-column-by-NB-row overlap rectangle. The label is the numerator
%   product from the witness (the count of small rectangles selected).
overlap_rect(NA, DA, NB, DB, Role, NumProd, Rect) :-
    origin_x(OX), origin_y(OY),
    unit_len(L),
    role_atom(Role, RoleAtom),
    ColW is L // DA,
    RowH is L // DB,
    W is NA * ColW,
    H is NB * RowH,
    format(string(Label), "~w", [NumProd]),
    Rect = _{ x: OX, y: OY, w: W, h: H,
              rows: NB, cols: NA, cellW: ColW, cellH: RowH,
              role: RoleAtom, label: Label, kind: "overlap" }.

%!  ungrounded_product_rect(+NumProd, +Role, -Rect) is det.
%   A detached product grid, placed to the right of the unit square. It shows
%   the numerator product as cells that are not coordinated with the denominator
%   partition of the unit square.
ungrounded_product_rect(NumProd, Role, Rect) :-
    origin_x(OX), origin_y(OY),
    unit_len(L),
    cell_w(CW), cell_h(CH),
    role_atom(Role, RoleAtom),
    product_grid_shape(NumProd, Rows, Cols),
    X is OX + L + 56,
    Y is OY,
    W is Cols * CW,
    H is Rows * CH,
    format(string(Label), "~w", [NumProd]),
    Rect = _{ x: X, y: Y, w: W, h: H,
              rows: Rows, cols: Cols,
              cellW: CW, cellH: CH,
              role: RoleAtom, label: Label,
              kind: "ungrounded_product" }.

%!  ungrounded_denominator_rect(+DenProd, +Role, -Rect) is det.
%   The detached denominator grid that the unsupported rule reports against.
%   It is a ledger of small rectangles, not a partition of the unit square.
ungrounded_denominator_rect(DenProd, Role, Rect) :-
    origin_x(OX), origin_y(OY),
    unit_len(L),
    cell_w(CW), cell_h(CH),
    role_atom(Role, RoleAtom),
    product_grid_shape(DenProd, Rows, Cols),
    X is OX + L + 56,
    Y is OY,
    W is Cols * CW,
    H is Rows * CH,
    Rect = _{ x: X, y: Y, w: W, h: H,
              rows: Rows, cols: Cols,
              cellW: CW, cellH: CH,
              role: RoleAtom, label: "",
              kind: "ungrounded_denominator" }.

product_grid_shape(0, 1, 1) :-
    !.
product_grid_shape(NumProd, Rows, Cols) :-
    Cols is min(6, max(1, NumProd)),
    Rows is (NumProd + Cols - 1) // Cols.


% =============================================================================
% Semantic color roles. A compiler emits only the role atoms the render
% contract names; the drawer maps each to var(--fig-<role>).
% =============================================================================

%!  role_atom(+Role, -Atom) is det.
role_atom(whole,       whole).
role_atom(highlight,   highlight).
role_atom(iterated,    iterated).
role_atom(inner,       inner).
role_atom(deformation, deformation).
role_atom(neutral,     neutral).


% =============================================================================
% Scene + frame assembly. A scene(Rows, Cols, Rects, gridlines(Vs,Hs)) term
% becomes a v2 area-model scene dict. The unit-square fraction scenes use
% scene_unit(Rects, DA, DB): the "rows/cols" are the denominators and the grid
% lines are the column / row splits of the unit square.
% =============================================================================

%!  make_frame(+Step, +Verb, +Caption, +Changed, +Scene, -Frame) is det.
make_frame(Step, Verb, Caption, Changed, Scene, Frame) :-
    term_to_string(Verb, VerbStr),
    scene_dict(Scene, SceneDict),
    Frame = _{ step: Step,
               verb: VerbStr,
               caption: Caption,
               sceneChanged: Changed,
               scene: SceneDict }.

%!  scene_dict(+SceneTerm, -Scene) is det.
scene_dict(scene(Rows, Cols, Rects, gridlines(Vs, Hs)), Scene) :-
    Scene = _{ format: "area-model",
               version: 2,
               rows: Rows,
               cols: Cols,
               rects: Rects,
               gridlines: _{ v: Vs, h: Hs } }.
scene_dict(scene_unit(Rects, DA, DB), Scene) :-
    origin_x(OX), origin_y(OY),
    unit_len(L),
    ColW is L // DA,
    RowH is L // DB,
    findall(VX, ( between(0, DA, K), VX is OX + K * ColW ), Vs),
    findall(HY, ( between(0, DB, K), HY is OY + K * RowH ), Hs),
    Scene = _{ format: "area-model",
               version: 2,
               rows: DB,
               cols: DA,
               rects: Rects,
               gridlines: _{ v: Vs, h: Hs } }.

%!  unknown_frame(+Spec, -Frame) is det.
%   A deferred / unknown generator, or one whose witness could not be sourced:
%   one annotation-only frame, no rects.
unknown_frame(Spec, Frame) :-
    term_to_string(Spec, SpecStr),
    format(string(Cap), "No area-model layout for ~w.", [SpecStr]),
    Scene = scene(0, 0, [], gridlines([], [])),
    make_frame(1, Spec, Cap, false, Scene, Frame).


% =============================================================================
% JSON assembly.
% =============================================================================

%!  area_render_json(+Spec, -Dict) is det.
%   Assemble the full render document: kind / request / result / canvas /
%   frames per the render contract, plus the optional `tuple` field.
area_render_json(Spec, Dict) :-
    area_render_frames(Spec, Frames),
    spec_kind(Spec, KindStr),
    request_dict(Spec, Request),
    result_string(Spec, ResultStr),
    canvas_dict(Spec, Canvas),
    spec_tuple(Spec, TupleStr),
    Dict = _{ kind: KindStr,
              request: Request,
              result: ResultStr,
              canvas: Canvas,
              frames: Frames,
              tuple: TupleStr }.

%!  area_compare_json(+Spec, -Dict) is det.
%   The productive-vs-deformation comparison document. Spec is
%   area_compare(NA,DA,NB,DB). On a sourcing failure it degrades to an
%   annotation-only single-filmstrip document, never a faked picture.
area_compare_json(area_compare(NA, DA, NB, DB), Dict) :-
    !,
    ( area_compare_frames(NA, DA, NB, DB, ProdFrames, DefFrames)
    -> Pn is NA * NB, Pd is DA * DB,
       format(string(ResultStr), "~w/~w", [Pn, Pd]),
       Dict = _{ kind: "area_compare",
                 request: _{ numA: NA, denA: DA, numB: NB, denB: DB },
                 result: ResultStr,
                 canvas: _{ width: 700, height: 520 },
                 productive: _{ kind: "area_model_part_of_part",
                                frames: ProdFrames },
                 deformation: _{ kind: "cross_multiplication_rule_without_ground",
                                 frames: DefFrames },
                 note: "The deformation produces the same number with no area figure of its own.",
                 tuple: "cross_multiplication_rule_from_pattern vs _without_ground" }
    ;  unknown_frame(area_compare(NA, DA, NB, DB), F),
       Dict = _{ kind: "area_compare",
                 request: _{ numA: NA, denA: DA, numB: NB, denB: DB },
                 result: "n/a",
                 canvas: _{ width: 700, height: 520 },
                 error: "no area-model comparison available",
                 frames: [F] }
    ).
area_compare_json(Spec, Dict) :-
    area_render_json(Spec, Dict).

%!  spec_kind(+Spec, -KindStr) is det.
spec_kind(Spec, KindStr) :-
    ( compound(Spec) -> functor(Spec, Name, _) ; Name = Spec ),
    atom_string(Name, KindStr).

%!  spec_tuple(+Spec, -TupleStr) is det.
%   The generator's formal signature as a string (distinct from any frame verb).
spec_tuple(array_multiplication(R, C), S) :- !,
    format(string(S), "array_multiplication(~w, ~w) -> rows x cols", [R, C]).
spec_tuple(commutativity_by_transpose(R, C), S) :- !,
    format(string(S), "commutativity_by_transpose(~w, ~w) -> R*C = C*R", [R, C]).
spec_tuple(partial_products(A, B), S) :- !,
    format(string(S), "partial_products(~w, ~w) -> (t+o)(t+o)", [A, B]).
spec_tuple(area_model_fraction(NA, DA, NB, DB), S) :- !,
    format(string(S), "area_model_part_of_part(~w/~w, ~w/~w)", [NA, DA, NB, DB]).
spec_tuple(Spec, S) :- term_to_string(Spec, S).

%!  request_dict(+Spec, -Request) is det.
%   Echo the integer inputs of the generator.
request_dict(array_multiplication(R, C), _{ rows: R, cols: C }) :- !.
request_dict(commutativity_by_transpose(R, C), _{ rows: R, cols: C }) :- !.
request_dict(partial_products(A, B), _{ a: A, b: B }) :- !.
request_dict(area_model_fraction(NA, DA, NB, DB),
             _{ numA: NA, denA: DA, numB: NB, denB: DB }) :- !.
request_dict(Spec, _{ spec: SpecStr }) :- term_to_string(Spec, SpecStr).

%!  result_string(+Spec, -ResultStr) is det.
%   The result string is read off the witness where one is sourced, never a
%   bare re-multiply on the default path.
result_string(array_multiplication(R, C), S) :- !,
    ( grid_counts(R, C, _, _, P) -> fmt(S, "~w", [P]) ; S = "n/a" ).
result_string(commutativity_by_transpose(R, C), S) :- !,
    ( grid_counts(R, C, _, _, P) -> fmt(S, "~w", [P]) ; S = "n/a" ).
result_string(partial_products(A, B), S) :- !,
    ( grid_counts(A, B, _, _, P) -> fmt(S, "~w", [P]) ; S = "n/a" ).
result_string(area_model_fraction(NA, DA, NB, DB), S) :- !,
    ( fraction_counts(NA, DA, NB, DB, _, _, ResultStr) -> S = ResultStr ; S = "n/a" ).
result_string(_, "n/a").

fmt(S, F, A) :- format(string(S), F, A).

%!  canvas_dict(+Spec, -Canvas) is det.
%   Advisory canvas size; the viewer auto-fits the viewBox to the rects.
canvas_dict(_Spec, _{ width: 700, height: 520 }).

%!  term_to_string(+Term, -String) is det.
term_to_string(Term, String) :-
    ( string(Term)
    -> String = Term
    ;  format(string(String), '~w', [Term])
    ).


%!  area_render_to_file(+Spec, +Path) is det.
%   Render the document and write it as pretty-printed JSON to Path.
area_render_to_file(Spec, Path) :-
    area_render_json(Spec, Dict),
    setup_call_cleanup(
        open(Path, write, Stream),
        json_write_dict(Stream, Dict, [width(80)]),
        close(Stream)).
