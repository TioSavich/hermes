/** <module> Set-and-grouping scene compiler (witness-driven)
 *
 * Compiles small discrete-collection arithmetic moves into a sequence of
 * "set-grouping" scene frames: dots (chips/counters), optional ten-frame cell
 * outlines, pairing lines, and labelled bins. The direction is Prolog ->
 * picture: a generator term (e.g. make_ten(8,5)) names the move, the standards
 * WITNESS computes the move as a finite proof, and this compiler reads the
 * witness's already-computed quantities to lay out integer dot/bin/line
 * coordinates. The JS drawer only places primitives where the scene puts them.
 *
 * The arithmetic of each move is NOT recomputed here. Each builder walks the
 * matching standards witness and reads its fields:
 *
 *   make_ten(A,B)       <- standard_1_ca_1:add_making_ten_witness/4
 *                          (need_count, rest_count, sum_count, addend counts)
 *   parity(N)           <- standard_2_ns_3:parity_witness/3
 *                          (trace of paired_two/remainder terms, result)
 *   subitize(P,_)       <- standard_k_ns_4:verify_subitizing_witness/3
 *                          (subitized_count, counted_count, result)
 *   compare(A,B)        <- standard_k_ns_5_6:compare_groups_witness/4
 *                          (count_a_value, count_b_value, result,
 *                           incompatible_results)
 *   unfair_compare(A,B) <- the same compare witness; the deformation claims one
 *                          of the witness's incompatible_results, drawn in the
 *                          deformation role beside the grounded comparison.
 *
 * The frame builders carry no local 10-A or N//2 arithmetic; the quantities
 * are read off the witness so the picture and the finite proof cannot drift.
 *
 * Frozen render contract. Each fill carries a semantic ROLE atom (unit /
 * highlight / iterated / deformation / neutral), never a hex string; Gate E's
 * token stylesheet maps role -> hex. See
 * docs/render-contract-v2.md (the scene format
 * is "set-grouping", version 2).
 *
 * Worker wiring (left for a later integration pass; do not register here):
 *   op name: set_grouping_render
 *   dispatch_request(set_grouping_render, Id, Request, Response) :-
 *       ( get_dict(spec, Request, SpecStr)
 *       -> term_string(Spec, SpecStr),
 *          set_grouping_scene:set_grouping_render_json(Spec, Dict),
 *          ok_response(Id, Dict, Response)
 *       ; error_response(Id, missing_spec,
 *           "set_grouping_render requires spec", Response) ).
 *
 * Scope and limits. This compiler draws the *doing* of these moves as a static
 * arrangement of chips. It does NOT model:
 *   - the act of recognizing a pattern (subitizing is drawn as a finished dot
 *     arrangement, not as the perceptual jump it names);
 *   - acquisition or strategy choice (no ORR cycle, no crisis — a fixed
 *     generator produces a fixed filmstrip);
 *   - multi-digit place value (P4's columns own that), area/array
 *     multiplication (P3 owns that), or fractions (P2 owns that);
 *   - any claim that the dealt arrangement is the *only* correct one.
 * A generator term whose witness does not hold (e.g. a make-ten that does not
 * cross ten, or an integer-path term behind the test flag) yields a single
 * annotation-only frame (sceneChanged:false) rather than an error, so the
 * filmstrip never throws.
 */

:- module(set_grouping_scene,
          [ set_grouping_render_frames/2,   % +Spec, -Frames
            set_grouping_render_json/2,      % +Spec, -Dict
            set_grouping_render_to_file/2,   % +Spec, +Path
            set_grouping_integer_path/1      % ?Enabled  (test flag)
          ]).

:- use_module(library(http/json), [json_write_dict/3]).
:- use_module(library(lists)).
:- use_module(standard_indiana(standard_1_ca_1)).
:- use_module(standard_indiana(standard_2_ns_3)).
:- use_module(standard_indiana(standard_k_ns_4)).
:- use_module(standard_indiana(standard_k_ns_5_6)).
:- use_module(formalization(grounded_arithmetic),
              [ integer_to_recollection/2, recollection_to_integer/2 ]).

% -----------------------------------------------------------------------------
% Geometry constants. Origin near (40,40). A dot lives on a grid cell of side
% CELL; the dot radius is DOTR. Ten-frame cells reuse CELL so a ten-frame and a
% loose dot pattern line up. Integer coordinates throughout. These are the
% renderer's layout choices; they carry no arithmetic about the move itself.
% -----------------------------------------------------------------------------
origin_x(40).
origin_y(40).
cell(64).          % grid pitch for dots and ten-frame cells
dot_r(20).         % dot radius
bin_pad(12).       % padding inside a bin around its dots
bin_gap(28).       % horizontal gap between bins

% Cell centre for column C, row R (both 0-based), offset by (OX,OY).
cell_center(OX, OY, C, R, X, Y) :-
    cell(S),
    X is OX + C * S + S // 2,
    Y is OY + R * S + S // 2.


% =============================================================================
% Integer-path test flag. The signed_chips integer-arithmetic path is drawn
% only when this flag is set (it has no K-2 standards witness of its own, so it
% is not part of the witness-driven default). Default: off.
% =============================================================================

:- dynamic set_grouping_integer_path_flag/0.

%!  set_grouping_integer_path(?Enabled) is det.
%   Read or set the integer-path flag. set_grouping_integer_path(true) enables
%   the signed_chips builder; set_grouping_integer_path(false) disables it;
%   set_grouping_integer_path(X) reads the current state into X.
set_grouping_integer_path(true) :-
    ( set_grouping_integer_path_flag -> true ; assertz(set_grouping_integer_path_flag) ),
    !.
set_grouping_integer_path(false) :-
    retractall(set_grouping_integer_path_flag),
    !.
set_grouping_integer_path(X) :-
    var(X),
    ( set_grouping_integer_path_flag -> X = true ; X = false ).


% =============================================================================
% Public entry points.
% =============================================================================

%!  set_grouping_render_frames(+Spec, -Frames) is det.
%
%   Build the filmstrip for the generator term Spec. Each recognized kind walks
%   its standards witness; a term whose witness does not hold (or an integer
%   path with the flag off) yields one annotation-only frame.
set_grouping_render_frames(Spec, Frames) :-
    ( build_frames(Spec, Frames0)
    -> Frames = Frames0
    ;  deferred_frame(Spec, F),
       Frames = [F]
    ).

%!  set_grouping_render_json(+Spec, -Dict) is det.
%
%   Assemble the full frame document per the frozen contract: kind / request /
%   result / canvas / frames.
set_grouping_render_json(Spec, Dict) :-
    set_grouping_render_frames(Spec, Frames),
    spec_kind(Spec, KindStr),
    spec_request(Spec, Request),
    spec_result(Spec, ResultStr),
    canvas_dict(Canvas),
    Dict = _{ kind: KindStr,
              request: Request,
              result: ResultStr,
              canvas: Canvas,
              frames: Frames }.

%!  set_grouping_render_to_file(+Spec, +Path) is det.
set_grouping_render_to_file(Spec, Path) :-
    set_grouping_render_json(Spec, Dict),
    setup_call_cleanup(
        open(Path, write, Stream),
        json_write_dict(Stream, Dict, [width(80)]),
        close(Stream)).


% =============================================================================
% Per-kind frame builders. Each reads the matching standards witness for the
% move's quantities, then lays out the scene primitives (dots / frames10 /
% pairLines / bins) at integer coordinates. Each fill carries a role atom.
% =============================================================================

%!  build_frames(+Spec, -Frames) is semidet.

% --- ten_frame(N): a 2x5 ten-frame with N cells filled. ----------------------
% Drawn via the K.NS.4 subitize witness for ten_frame(N): the witness names N
% as a recognized quantity, and the complement to ten is read from it.
build_frames(ten_frame(N), Frames) :-
    integer(N), N >= 0, N =< 10,
    subitize_quantity(ten_frame(N), N),     % witness agrees the pattern is N
    filled_dots(N, FilledDots),
    ten_frame_cells(Cells),
    Comp is 10 - N,
    format(string(Cap),
           "A ten-frame with ~w filled. The complement to ten is ~w.",
           [N, Comp]),
    Scene = scene(FilledDots, Cells, [], []),
    scene_dict(Scene, SceneDict),
    mk_frame(1, ten_frame(N), Cap, true, SceneDict, F1),
    Frames = [ F1 ].

% --- make_ten(A,B): fill A, complete the ten, then the rest. -----------------
% All counts come from standard_1_ca_1:add_making_ten_witness. The witness only
% holds when the sum crosses ten; otherwise build_frames fails and the caller
% emits a deferred frame.
build_frames(make_ten(A, B), Frames) :-
    integer(A), integer(B), A >= 0, B >= 0,
    making_ten_quantities(A, B, Start, ToTen, Over, Sum),
    ten_frame_cells(Cells),
    % Frame 1 — Start chips in the ten-frame (the first addend).
    range_dots_role(0, Start, unit, F1Dots),
    format(string(Cap1), "Start with ~w in the ten-frame.", [Start]),
    Scene1 = scene(F1Dots, Cells, [], []),
    % Frame 2 — add ToTen chips (the part that completes the ten), highlighted.
    range_dots_role(Start, ToTen, highlight, AddDots),
    append(F1Dots, AddDots, F2Dots),
    ( ToTen > 0
    -> format(string(Cap2),
              "Add ~w to make ten: ~w needs ~w more, and ~w has it to give.",
              [ToTen, Start, ToTen, B])
    ;  Cap2 = "The ten is already full."
    ),
    Scene2 = scene(F2Dots, Cells, [], []),
    % Frame 3 — the leftover Over chips spill into a row beneath (iterated).
    overflow_dots(Over, iterated, OverDots),
    append(F2Dots, OverDots, F3Dots),
    format(string(Cap3),
           "~w + ~w = ~w: split ~w into ~w and ~w, make ten, then ~w left.",
           [Start, B, Sum, B, ToTen, Over, Over]),
    Scene3 = scene(F3Dots, Cells, [], []),
    scene_dict(Scene1, SD1), scene_dict(Scene2, SD2), scene_dict(Scene3, SD3),
    mk_frame(1, make_ten(A, B), Cap1, true, SD1, MF1),
    mk_frame(2, make_ten(A, B), Cap2, true, SD2, MF2),
    mk_frame(3, make_ten(A, B), Cap3, true, SD3, MF3),
    Frames = [ MF1, MF2, MF3 ].

% --- make_ten_drop_leftover(A,B): deformation of make-ten. ------------------
% The grounded make-ten witness still supplies Start / ToTen / Over / Sum.
% The deformation completes the ten but drops the leftover Over chips instead
% of preserving them as the rest of the addend.
build_frames(make_ten_drop_leftover(A, B), Frames) :-
    integer(A), integer(B), A >= 0, B >= 0,
    making_ten_quantities(A, B, Start, ToTen, Over, Sum),
    Over > 0,
    ten_frame_cells(Cells),
    range_dots_role(0, Start, unit, F1Dots),
    format(string(Cap1), "Start with ~w in the ten-frame.", [Start]),
    Scene1 = scene(F1Dots, Cells, [], []),
    range_dots_role(Start, ToTen, highlight, AddDots),
    append(F1Dots, AddDots, F2Dots),
    format(string(Cap2),
           "Add ~w to make ten: ~w needs ~w more, and ~w has it to give.",
           [ToTen, Start, ToTen, B]),
    Scene2 = scene(F2Dots, Cells, [], []),
    overflow_dots(Over, deformation, DroppedDots),
    append(F2Dots, DroppedDots, F3Dots),
    format(string(Cap3),
           "The ten is full, but the leftover ~w from ~w is dropped. The student keeps 10 instead of preserving the full sum ~w.",
           [Over, B, Sum]),
    Scene3 = scene(F3Dots, Cells, [], []),
    scene_dict(Scene1, SD1), scene_dict(Scene2, SD2), scene_dict(Scene3, SD3),
    mk_frame(1, make_ten_drop_leftover(A, B), Cap1, true, SD1, MF1),
    mk_frame(2, make_ten_drop_leftover(A, B), Cap2, true, SD2, MF2),
    mk_frame(3, make_ten_drop_leftover(A, B), Cap3, true, SD3, MF3),
    Frames = [ MF1, MF2, MF3 ].

% --- subitize(Pattern, N): a canonical dot pattern for N. --------------------
% The generator carries the requested count N; the K.NS.4 verify_subitizing
% witness confirms recognition and counting agree for a ten_frame(N) before the
% picture is drawn, so the count the picture shows is witness-confirmed.
build_frames(subitize(Pattern, N), Frames) :-
    integer(N), N >= 1, N =< 10,
    subitize_quantity(ten_frame(N), N),
    ( N =< 6, member(Pattern, [dice, auto])
    -> dice_dots(N, Dots), Frames10 = [],
       PatName = dice
    ;  ten_frame_cells(Cells), filled_dots(N, Dots), Frames10 = Cells,
       PatName = ten_frame
    ),
    format(string(Cap),
           "Subitize ~w as a ~w pattern (recognized as a whole, not counted).",
           [N, PatName]),
    Scene = scene(Dots, Frames10, [], []),
    scene_dict(Scene, SD),
    mk_frame(1, subitize(Pattern, N), Cap, true, SD, SF1),
    Frames = [ SF1 ].

% --- parity(N): N dots paired up; one left over if odd. ----------------------
% Pairs and the leftover are read from standard_2_ns_3:parity_witness's trace,
% not from a local N//2.
build_frames(parity(N), Frames) :-
    integer(N), N >= 0,
    parity_from_witness(N, Result, Pairs, Rem, Incompatible),
    parity_dots(N, Pairs, Rem, Dots),
    pair_lines(Pairs, Lines),
    ( Rem =:= 0
    -> format(string(Cap),
              "~w dots pair up with none left over: ~w is ~w (~w pairs), not ~w.",
              [N, N, Result, Pairs, Incompatible])
    ;  format(string(Cap),
              "~w dots pair up with one left over: ~w is ~w (~w pairs and 1), not ~w.",
              [N, N, Result, Pairs, Incompatible])
    ),
    Scene = scene(Dots, [], Lines, []),
    scene_dict(Scene, SD),
    mk_frame(1, parity(N), Cap, true, SD, PF1),
    Frames = [ PF1 ].

% --- compare(A,B): two groups counted and compared (the grounded move). ------
% Counts and the relation come from standard_k_ns_5_6:compare_groups_witness.
build_frames(compare(A, B), Frames) :-
    compare_quantities(A, B, CountA, CountB, Result, _Incompatible),
    compare_layout(CountA, CountB, unit, unit, Bins, Dots, MatchLines),
    relation_phrase(Result, Phrase),
    relation_symbol(Result, Sym),
    format(string(Cap),
           "~w against ~w: match one-to-one. ~w (~w ~w ~w).",
           [CountA, CountB, Phrase, CountA, Sym, CountB]),
    Scene = scene(Dots, [], MatchLines, Bins),
    scene_dict(Scene, SD),
    mk_frame(1, compare(A, B), Cap, true, SD, CF1),
    Frames = [ CF1 ].

% --- unfair_compare(A,B): the deformation that mis-pairs the two groups. ------
% Frame 1 draws the grounded comparison (the witness result). Frame 2 draws the
% deformation: it claims one of the witness's incompatible_results by mis-
% pairing the surplus of the larger group, marking those surplus chips in the
% deformation role. The truth and the named-wrong alternative both come from the
% compare witness — no ad-hoc "wrong answer" is invented here.
build_frames(unfair_compare(A, B), Frames) :-
    compare_quantities(A, B, CountA, CountB, Result, Incompatible),
    Result \== equal_to,                    % a deformation needs an unequal pair
    member(equal_to, Incompatible),         % the mis-pairing claims "equal"
    % Frame 1 — the grounded one-to-one match (same as compare).
    compare_layout(CountA, CountB, unit, unit, Bins1, Dots1, MatchLines1),
    relation_phrase(Result, Phrase),
    format(string(Cap1),
           "Match one-to-one: ~w against ~w. ~w.",
           [CountA, CountB, Phrase]),
    Scene1 = scene(Dots1, [], MatchLines1, Bins1),
    % Frame 2 — the deformation: the surplus of the larger group is left out of
    % the pairing yet still called "the same", drawn in the deformation role.
    Surplus is abs(CountA - CountB),
    compare_deform_layout(CountA, CountB, Bins2, Dots2, MatchLines2),
    format(string(Cap2),
           "Mis-pairing the ~w surplus chip(s) and calling the groups equal is a deformation: it claims ~w, which the count rules out.",
           [Surplus, equal_to]),
    Scene2 = scene(Dots2, [], MatchLines2, Bins2),
    scene_dict(Scene1, SD1), scene_dict(Scene2, SD2),
    mk_frame(1, unfair_compare(A, B), Cap1, true, SD1, UF1),
    mk_frame(2, unfair_compare(A, B), Cap2, true, SD2, UF2),
    Frames = [ UF1, UF2 ].

% --- equal_groups(G,S): G bins each with S dots. -----------------------------
build_frames(equal_groups(G, S), Frames) :-
    integer(G), integer(S), G >= 1, S >= 0,
    Product is G * S,
    equal_groups_layout(G, S, Bins, Dots),
    format(string(Cap),
           "~w groups of ~w: ~w x ~w = ~w.",
           [G, S, G, S, Product]),
    Scene = scene(Dots, [], [], Bins),
    scene_dict(Scene, SD),
    mk_frame(1, equal_groups(G, S), Cap, true, SD, EF1),
    Frames = [ EF1 ].

% --- fair_share(Total,Groups): round-robin deal into Groups bins. ------------
build_frames(fair_share(Total, Groups), Frames) :-
    integer(Total), integer(Groups), Total >= 0, Groups >= 1,
    Q is Total // Groups,
    R is Total mod Groups,
    fair_share_counts(Total, Groups, Counts),
    fair_share_layout(Counts, Bins, Dots),
    ( R =:= 0
    -> format(string(Cap),
              "Deal ~w one at a time into ~w groups: ~w each, none left over.",
              [Total, Groups, Q])
    ;  format(string(Cap),
              "Deal ~w one at a time into ~w groups: ~w each, ~w left over.",
              [Total, Groups, Q, R])
    ),
    Scene = scene(Dots, [], [], Bins),
    scene_dict(Scene, SD),
    mk_frame(1, fair_share(Total, Groups), Cap, true, SD, FF1),
    Frames = [ FF1 ].

% --- signed_chips(A,B): integer addition with zero-pair cancellation. --------
% This is the INTEGER PATH: it has no K-2 standards witness, so it draws only
% when the integer-path test flag is set. min(|pos|,|neg|) pairs cancel
% (neutral role); survivors = |A+B| in the deformation/unit roles by sign.
build_frames(signed_chips(A, B), Frames) :-
    set_grouping_integer_path_flag,   % only when the integer-path flag is set
    integer(A), integer(B),
    Sum is A + B,
    Pos is max(A, 0) + max(B, 0),
    Neg is max(-A, 0) + max(-B, 0),
    Cancel is min(Pos, Neg),
    % Frame 1 — all chips: positives row 0 (unit), negatives row 1 (deformation
    % role marks the opposite-sign chips so the zero pair is legible).
    signed_layout(Pos, Neg, PosDots, NegDots),
    append(PosDots, NegDots, AllDots),
    format(string(Cap1),
           "Add ~w and ~w: ~w positive chip(s) and ~w negative chip(s).",
           [A, B, Pos, Neg]),
    Scene1 = scene(AllDots, [], [], []),
    % Frame 2 — Cancel zero-pair lines; cancelled chips go neutral.
    zero_pair_lines(Cancel, PairLines),
    neutralise_cancelled(PosDots, NegDots, Cancel, NeutralDots),
    ( Cancel > 0
    -> format(string(Cap2),
              "Each opposite pair is a zero pair: ~w pair(s) cancel.",
              [Cancel])
    ;  Cap2 = "No zero pairs to cancel."
    ),
    Scene2 = scene(NeutralDots, [], PairLines, []),
    % Frame 3 — survivors only, in the result's sign role.
    survivor_dots(Sum, SurvDots),
    signed_result_caption(A, B, Sum, Cap3),
    Scene3 = scene(SurvDots, [], [], []),
    scene_dict(Scene1, SD1), scene_dict(Scene2, SD2), scene_dict(Scene3, SD3),
    mk_frame(1, signed_chips(A, B), Cap1, true, SD1, GF1),
    mk_frame(2, signed_chips(A, B), Cap2, true, SD2, GF2),
    mk_frame(3, signed_chips(A, B), Cap3, true, SD3, GF3),
    Frames = [ GF1, GF2, GF3 ].


% =============================================================================
% Witness bridges. Each reads the matching standards witness and projects out
% the integer quantities the geometry needs. No arithmetic about the move
% happens here beyond reading the witness's own fields.
% =============================================================================

%!  making_ten_quantities(+A, +B, -Start, -ToTen, -Over, -Sum) is semidet.
%   Read the making-ten witness for A+B: Start = first addend count, ToTen =
%   how many of B complete the ten (need_count), Over = the leftover
%   (rest_count), Sum = the total (sum_count). Fails when A+B does not cross
%   ten (the witness does not hold).
making_ten_quantities(A, B, Start, ToTen, Over, Sum) :-
    integer_to_recollection(A, RA),
    integer_to_recollection(B, RB),
    standard_1_ca_1:add_making_ten_witness(RA, RB, _Sum, W),
    get_dict(addends, W, Addends),
    get_dict(a_count, Addends, Start),
    get_dict(need_count, W, ToTen),
    get_dict(rest_count, W, Over),
    get_dict(sum_count, W, Sum).

%!  parity_from_witness(+N, -Result, -Pairs, -Rem, -Incompatible) is semidet.
%   Read parity_witness for N: Result (even/odd), Pairs (the count of paired_two
%   steps in the trace), Rem (0 or 1, from the terminal remainder step), and
%   Incompatible (the opposite parity the witness excludes).
parity_from_witness(N, Result, Pairs, Rem, Incompatible) :-
    integer_to_recollection(N, RN),
    standard_2_ns_3:parity_witness(RN, Result, W),
    get_dict(trace, W, Trace),
    get_dict(incompatible_with, W, Incompatible),
    trace_pairs_and_remainder(Trace, Pairs, Rem).

%!  trace_pairs_and_remainder(+Trace, -Pairs, -Rem) is det.
%   Count paired_two/2 steps and read the terminal remainder(R, _) from the
%   parity trace.
trace_pairs_and_remainder(Trace, Pairs, Rem) :-
    include([Step]>>(Step = paired_two(_, _)), Trace, PairSteps),
    length(PairSteps, Pairs),
    ( member(remainder(R, _), Trace) -> Rem = R ; Rem = 0 ).

%!  subitize_quantity(+Pattern, -N) is semidet.
%   Confirm the recognized count N via the K.NS.4 verify_subitizing witness for
%   ten_frame(N). For N=0 the empty ten-frame needs no recognition proof; for
%   N>=1 the witness must report match(SubitizedCount, CountedCount) with the
%   subitized count equal to N.
subitize_quantity(ten_frame(N), N) :-
    integer(N), N >= 0, N =< 10,
    ( N >= 1
    -> standard_k_ns_4:verify_subitizing_witness(ten_frame(N), Result, W),
       get_dict(subitized_count, W, SubRec),
       recollection_to_integer(SubRec, N),
       Result = match(_, _)
    ;  true                                  % zero is the empty ten-frame
    ).

%!  compare_quantities(+A, +B, -CountA, -CountB, -Result, -Incompatible) is semidet.
%   Read compare_groups_witness for two groups. A and B may be integers (turned
%   into object lists of that length) or already-built object lists.
compare_quantities(A, B, CountA, CountB, Result, Incompatible) :-
    to_object_list(A, GroupA),
    to_object_list(B, GroupB),
    standard_k_ns_5_6:compare_groups_witness(GroupA, GroupB, Result, W),
    get_dict(count_a_value, W, CountA),
    get_dict(count_b_value, W, CountB),
    get_dict(incompatible_results, W, Incompatible).

to_object_list(L, L) :- is_list(L), !.
to_object_list(N, L) :- integer(N), N >= 0, length(L, N), maplist(=(obj), L).


% =============================================================================
% Geometry helpers. Roles, not hex.
% =============================================================================

% --- Ten-frame ---------------------------------------------------------------

%!  ten_frame_cells(-Cells) is det.
%   The 2x5 ten-frame outline: 10 cell rectangles, columns 0..4, rows 0..1.
ten_frame_cells(Cells) :-
    origin_x(OX), origin_y(OY), cell(S),
    findall(Cell,
            ( between(0, 1, R), between(0, 4, C),
              X is OX + C * S, Y is OY + R * S,
              Cell = _{ x: X, y: Y, w: S, h: S }
            ),
            Cells).

%!  filled_dots(+N, -Dots) is det.
%   N filled chips, one per ten-frame cell, in reading order, in the unit role.
filled_dots(N, Dots) :-
    range_dots_role(0, N, unit, Dots).

%!  range_dots_role(+Start, +Count, +Role, -Dots) is det.
%   Count chips placed in ten-frame cells Start, Start+1, ... (reading order),
%   each carrying the given role atom.
range_dots_role(Start, Count, Role, Dots) :-
    origin_x(OX), origin_y(OY), dot_r(R),
    End is Start + Count - 1,
    ( Count =< 0
    -> Dots = []
    ;  findall(Dot,
               ( between(Start, End, I),
                 Col is I mod 5, Row is I // 5,
                 cell_center(OX, OY, Col, Row, X, Y),
                 Dot = _{ x: X, y: Y, r: R, role: Role,
                          group: 0, tag: "filled" }
               ),
               Dots)
    ).

%!  overflow_dots(+Over, +Role, -Dots) is det.
%   Over chips spilling into a row beneath the ten-frame (the part of a
%   make-ten sum past 10), in the given role.
overflow_dots(Over, Role, Dots) :-
    ( Over =< 0
    -> Dots = []
    ;  origin_x(OX), origin_y(OY), dot_r(R), cell(S),
       OverY0 is OY + 2 * S,
       Hi is Over - 1,
       findall(Dot,
               ( between(0, Hi, I),
                 cell_center(OX, OverY0, I, 0, X, Y),
                 Dot = _{ x: X, y: Y, r: R, role: Role,
                          group: 1, tag: "overflow" }
               ),
               Dots)
    ).

% --- Dice (subitizing) -------------------------------------------------------

%!  dice_dots(+N, -Dots) is det.
%   The canonical dice face for N in 1..6 on a 3x3 pip grid (columns/rows 0..2).
dice_dots(N, Dots) :-
    dice_cells(N, Cells),
    origin_x(OX), origin_y(OY), dot_r(R),
    findall(Dot,
            ( member(Col-Row, Cells),
              cell_center(OX, OY, Col, Row, X, Y),
              Dot = _{ x: X, y: Y, r: R, role: unit, group: 0, tag: "pip" }
            ),
            Dots).

% Pip positions on a 3x3 grid (Col-Row, 0-based), per a standard die face.
dice_cells(1, [1-1]).
dice_cells(2, [0-0, 2-2]).
dice_cells(3, [0-0, 1-1, 2-2]).
dice_cells(4, [0-0, 2-0, 0-2, 2-2]).
dice_cells(5, [0-0, 2-0, 1-1, 0-2, 2-2]).
dice_cells(6, [0-0, 2-0, 0-1, 2-1, 0-2, 2-2]).

% --- Parity ------------------------------------------------------------------

%!  parity_dots(+N, +Pairs, +Rem, -Dots) is det.
%   N dots in two rows: Pairs columns of stacked partners (rows 0 and 1); if
%   Rem =:= 1, one leftover sits alone in the top row past the pairs, in the
%   highlight role (the salient unpaired chip the witness names).
parity_dots(_N, Pairs, Rem, Dots) :-
    origin_x(OX), origin_y(OY), dot_r(R),
    HiPair is Pairs - 1,
    findall(D,
            ( between(0, HiPair, C),
              cell_center(OX, OY, C, 0, X0, Y0),
              cell_center(OX, OY, C, 1, X1, Y1),
              ( D = _{ x: X0, y: Y0, r: R, role: unit, group: C, tag: "top" }
              ; D = _{ x: X1, y: Y1, r: R, role: unit, group: C, tag: "bottom" }
              )
            ),
            PairDots),
    ( Rem =:= 1
    -> cell_center(OX, OY, Pairs, 0, XL, YL),
       Leftover = [ _{ x: XL, y: YL, r: R, role: highlight,
                       group: Pairs, tag: "leftover" } ]
    ;  Leftover = []
    ),
    append(PairDots, Leftover, Dots).

%!  pair_lines(+Pairs, -Lines) is det.
%   A vertical line joining each stacked pair (column 0..Pairs-1).
pair_lines(Pairs, Lines) :-
    origin_x(OX), origin_y(OY),
    HiPair is Pairs - 1,
    ( Pairs =< 0
    -> Lines = []
    ;  findall(L,
               ( between(0, HiPair, C),
                 cell_center(OX, OY, C, 0, X, Y0),
                 cell_center(OX, OY, C, 1, X, Y1),
                 L = _{ x1: X, y1: Y0, x2: X, y2: Y1 }
               ),
               Lines)
    ).

% --- Compare (two groups, one-to-one matching) -------------------------------

%!  compare_layout(+CountA, +CountB, +RoleA, +RoleB, -Bins, -Dots, -MatchLines)
%   Two bins side by side, CountA chips in the left and CountB in the right,
%   each in a single column so a one-to-one match draws as horizontal lines
%   between aligned rows. MatchLines join the min(CountA,CountB) aligned pairs.
compare_layout(CountA, CountB, RoleA, RoleB, Bins, Dots, MatchLines) :-
    origin_x(OX), origin_y(OY), cell(CS), bin_pad(P), bin_gap(Gap), dot_r(R),
    MaxC is max(CountA, CountB),
    BinW is CS + 2 * P,
    BinH is max(1, MaxC) * CS + 2 * P,
    LeftX is OX,
    RightX is OX + BinW + Gap,
    BinA = _{ x: LeftX,  y: OY, w: BinW, h: BinH, label: "group A" },
    BinB = _{ x: RightX, y: OY, w: BinW, h: BinH, label: "group B" },
    Bins = [BinA, BinB],
    column_dots(CountA, LeftX + P,  OY + P, R, RoleA, 0, "a", DotsA),
    column_dots(CountB, RightX + P, OY + P, R, RoleB, 1, "b", DotsB),
    append(DotsA, DotsB, Dots),
    Matched is min(CountA, CountB),
    match_lines(Matched, LeftX + P, RightX + P, OY + P, R, MatchLines).

%!  compare_deform_layout(+CountA, +CountB, -Bins, -Dots, -MatchLines)
%   The deformation: the same two bins, but the surplus chips of the larger
%   group are tinted in the deformation role (left out of the matching yet
%   called "equal"). Match lines still cover only the genuinely matched pairs.
compare_deform_layout(CountA, CountB, Bins, Dots, MatchLines) :-
    origin_x(OX), origin_y(OY), cell(CS), bin_pad(P), bin_gap(Gap), dot_r(R),
    MaxC is max(CountA, CountB),
    BinW is CS + 2 * P,
    BinH is max(1, MaxC) * CS + 2 * P,
    LeftX is OX,
    RightX is OX + BinW + Gap,
    BinA = _{ x: LeftX,  y: OY, w: BinW, h: BinH, label: "group A" },
    BinB = _{ x: RightX, y: OY, w: BinW, h: BinH, label: "group B" },
    Bins = [BinA, BinB],
    Matched is min(CountA, CountB),
    % The surplus belongs to whichever group is larger.
    ( CountA > CountB
    -> deform_column(CountA, Matched, LeftX + P,  OY + P, R, 0, "a", DotsA),
       column_dots(CountB, RightX + P, OY + P, R, unit, 1, "b", DotsB)
    ;  column_dots(CountA, LeftX + P, OY + P, R, unit, 0, "a", DotsA),
       deform_column(CountB, Matched, RightX + P, OY + P, R, 1, "b", DotsB)
    ),
    append(DotsA, DotsB, Dots),
    match_lines(Matched, LeftX + P, RightX + P, OY + P, R, MatchLines).

%!  column_dots(+Count, +OXExpr, +OYExpr, +R, +Role, +Group, +Tag, -Dots) is det.
column_dots(Count, OXExpr, OYExpr, R, Role, Group, Tag, Dots) :-
    OX is OXExpr, OY is OYExpr,
    Hi is Count - 1,
    ( Count =< 0
    -> Dots = []
    ;  findall(D,
               ( between(0, Hi, I),
                 cell_center(0, 0, 0, I, DX0, DY0),
                 X is OX + DX0, Y is OY + DY0,
                 D = _{ x: X, y: Y, r: R, role: Role, group: Group, tag: Tag }
               ),
               Dots)
    ).

%!  deform_column(+Count, +Matched, ...) is det.
%   A column where the first Matched chips are unit and the rest (the surplus)
%   are in the deformation role.
deform_column(Count, Matched, OXExpr, OYExpr, R, Group, Tag, Dots) :-
    OX is OXExpr, OY is OYExpr,
    Hi is Count - 1,
    ( Count =< 0
    -> Dots = []
    ;  findall(D,
               ( between(0, Hi, I),
                 ( I < Matched -> Role = unit ; Role = deformation ),
                 cell_center(0, 0, 0, I, DX0, DY0),
                 X is OX + DX0, Y is OY + DY0,
                 D = _{ x: X, y: Y, r: R, role: Role, group: Group, tag: Tag }
               ),
               Dots)
    ).

%!  match_lines(+Count, +LeftXExpr, +RightXExpr, +OYExpr, +R, -Lines) is det.
%   Horizontal lines joining the aligned chips of the two columns, one per
%   matched pair (rows 0..Count-1).
match_lines(Count, LeftXExpr, RightXExpr, OYExpr, _R, Lines) :-
    LX is LeftXExpr, RX is RightXExpr, OY is OYExpr,
    Hi is Count - 1,
    ( Count =< 0
    -> Lines = []
    ;  findall(L,
               ( between(0, Hi, I),
                 cell_center(0, 0, 0, I, _DX, DY),
                 Y is OY + DY,
                 L = _{ x1: LX, y1: Y, x2: RX, y2: Y }
               ),
               Lines)
    ).

relation_phrase(less_than, "the first group is smaller").
relation_phrase(greater_than, "the first group is larger").
relation_phrase(equal_to, "the groups are the same size").

%!  relation_symbol(+Relation, -Symbol) is det.
relation_symbol(less_than, "<").
relation_symbol(greater_than, ">").
relation_symbol(equal_to, "=").

% --- Equal groups ------------------------------------------------------------

%!  equal_groups_layout(+G, +S, -Bins, -Dots) is det.
equal_groups_layout(G, S, Bins, Dots) :-
    origin_x(OX), origin_y(OY),
    bin_columns(S, Cols),
    Rows is max(1, (S + Cols - 1) // Cols),
    cell(CS), bin_pad(P), bin_gap(Gap), dot_r(R),
    BinW is Cols * CS + 2 * P,
    BinH is Rows * CS + 2 * P,
    HiG is G - 1,
    findall(Bin-GroupDots,
            ( between(0, HiG, Gi),
              BinX is OX + Gi * (BinW + Gap),
              BinY is OY,
              GiLabel is Gi + 1,
              format(string(Label), "group ~w", [GiLabel]),
              Bin = _{ x: BinX, y: BinY, w: BinW, h: BinH, label: Label },
              DotOX is BinX + P, DotOY is BinY + P,
              s_dots_in_bin(S, Cols, DotOX, DotOY, R, Gi, unit, GroupDots)
            ),
            Pairs),
    pairs_keys_values(Pairs, Bins, DotLists),
    append(DotLists, Dots).

%!  s_dots_in_bin(+S, +Cols, +OX, +OY, +R, +Group, +Role, -Dots) is det.
s_dots_in_bin(S, Cols, OX, OY, R, Group, Role, Dots) :-
    Hi is S - 1,
    ( S =< 0
    -> Dots = []
    ;  findall(D,
               ( between(0, Hi, I),
                 Col is I mod Cols, Row is I // Cols,
                 cell_center(OX, OY, Col, Row, X, Y),
                 D = _{ x: X, y: Y, r: R, role: Role,
                        group: Group, tag: "in_group" }
               ),
               Dots)
    ).

%!  bin_columns(+S, -Cols) is det.
bin_columns(S, Cols) :-
    ( S =< 1 -> Cols = 1
    ; S =< 4 -> Cols = 2
    ; S =< 9 -> Cols = 3
    ; Cols = 5
    ).

% --- Fair share --------------------------------------------------------------

%!  fair_share_counts(+Total, +Groups, -Counts) is det.
fair_share_counts(Total, Groups, Counts) :-
    Q is Total // Groups,
    R is Total mod Groups,
    HiG is Groups - 1,
    findall(C,
            ( between(0, HiG, Gi),
              ( Gi < R -> C is Q + 1 ; C = Q )
            ),
            Counts).

%!  fair_share_layout(+Counts, -Bins, -Dots) is det.
fair_share_layout(Counts, Bins, Dots) :-
    origin_x(OX), origin_y(OY),
    max_list_or_zero(Counts, MaxC),
    bin_columns(MaxC, Cols),
    Rows is max(1, (MaxC + Cols - 1) // Cols),
    cell(CS), bin_pad(P), bin_gap(Gap), dot_r(R),
    BinW is Cols * CS + 2 * P,
    BinH is Rows * CS + 2 * P,
    length(Counts, G),
    HiG is G - 1,
    findall(Bin-GroupDots,
            ( between(0, HiG, Gi),
              nth0(Gi, Counts, S),
              BinX is OX + Gi * (BinW + Gap),
              BinY is OY,
              GiLabel is Gi + 1,
              format(string(Label), "group ~w (~w)", [GiLabel, S]),
              Bin = _{ x: BinX, y: BinY, w: BinW, h: BinH, label: Label },
              DotOX is BinX + P, DotOY is BinY + P,
              s_dots_in_bin(S, Cols, DotOX, DotOY, R, Gi, unit, GroupDots)
            ),
            Pairs),
    pairs_keys_values(Pairs, Bins, DotLists),
    append(DotLists, Dots).

max_list_or_zero([], 0) :- !.
max_list_or_zero(L, M) :- max_list(L, M).

% --- Signed chips (integer path) ---------------------------------------------

%!  signed_layout(+Pos, +Neg, -PosDots, -NegDots) is det.
%   Positives in row 0 (unit role), negatives in row 1 (deformation role to
%   mark the opposite sign), aligned by column so a positive and a negative in
%   the same column form a visible zero pair.
signed_layout(Pos, Neg, PosDots, NegDots) :-
    origin_x(OX), origin_y(OY), dot_r(R),
    row_dots(Pos, 0, OX, OY, R, unit, "pos", PosDots),
    row_dots(Neg, 1, OX, OY, R, deformation, "neg", NegDots).

row_dots(Count, Row, OX, OY, R, Role, Tag, Dots) :-
    Hi is Count - 1,
    ( Count =< 0
    -> Dots = []
    ;  findall(D,
               ( between(0, Hi, C),
                 cell_center(OX, OY, C, Row, X, Y),
                 D = _{ x: X, y: Y, r: R, role: Role, group: Row, tag: Tag }
               ),
               Dots)
    ).

%!  zero_pair_lines(+Cancel, -Lines) is det.
zero_pair_lines(Cancel, Lines) :-
    origin_x(OX), origin_y(OY),
    Hi is Cancel - 1,
    ( Cancel =< 0
    -> Lines = []
    ;  findall(L,
               ( between(0, Hi, C),
                 cell_center(OX, OY, C, 0, X, Y0),
                 cell_center(OX, OY, C, 1, X, Y1),
                 L = _{ x1: X, y1: Y0, x2: X, y2: Y1 }
               ),
               Lines)
    ).

%!  neutralise_cancelled(+PosDots, +NegDots, +Cancel, -Dots) is det.
%   Re-role the first Cancel chips in each row to neutral (the cancelled zero
%   pair) so the surviving chips stand out.
neutralise_cancelled(PosDots, NegDots, Cancel, Dots) :-
    neutral_first(PosDots, Cancel, PosN),
    neutral_first(NegDots, Cancel, NegN),
    append(PosN, NegN, Dots).

neutral_first(Dots, 0, Dots) :- !.
neutral_first([], _, []) :- !.
neutral_first([D0|Rest], K, [D1|RestN]) :-
    K > 0,
    D1 = D0.put(role, neutral).put(tag, "cancelled"),
    K1 is K - 1,
    neutral_first(Rest, K1, RestN).

%!  survivor_dots(+Sum, -Dots) is det.
%   |Sum| chips in row 0; the unit role if Sum >= 0, the deformation role if
%   Sum < 0 (the result carries the surviving sign).
survivor_dots(Sum, Dots) :-
    origin_x(OX), origin_y(OY), dot_r(R),
    Abs is abs(Sum),
    ( Sum < 0 -> Role = deformation, Tag = "neg_survivor"
    ;            Role = unit,        Tag = "pos_survivor" ),
    Hi is Abs - 1,
    ( Abs =< 0
    -> Dots = []
    ;  findall(D,
               ( between(0, Hi, C),
                 cell_center(OX, OY, C, 0, X, Y),
                 D = _{ x: X, y: Y, r: R, role: Role, group: 0, tag: Tag }
               ),
               Dots)
    ).

signed_result_caption(A, B, Sum, Cap) :-
    ( Sum =:= 0
    -> format(string(Cap),
              "~w + ~w = 0: every chip is in a zero pair, nothing survives.",
              [A, B])
    ;  AbsSum is abs(Sum),
       ( Sum > 0 -> Sign = "positive" ; Sign = "negative" ),
       format(string(Cap),
              "~w + ~w = ~w: ~w ~w chip(s) survive.",
              [A, B, Sum, AbsSum, Sign])
    ).


% =============================================================================
% Frame and document assembly.
% =============================================================================

%!  scene_dict(+scene(Dots, Frames10, PairLines, Bins), -Dict) is det.
%   Wrap the four primitive arrays in the frozen set-grouping scene (version 2).
scene_dict(scene(Dots, Frames10, PairLines, Bins), Dict) :-
    Dict = _{ format: "set-grouping", version: 2,
              dots: Dots, frames10: Frames10,
              pairLines: PairLines, bins: Bins }.

% Build the frame dict. The verb term is stringified for the JSON field.
mk_frame(Step, Verb, Caption, Changed, Scene, Frame) :-
    term_to_string(Verb, VerbStr),
    Frame = _{ step: Step, verb: VerbStr, caption: Caption,
               sceneChanged: Changed, scene: Scene }.

%!  deferred_frame(+Spec, -Frame) is det.
%   An annotation-only frame for a generator term whose witness does not hold
%   (or an integer path with the flag off).
deferred_frame(Spec, Frame) :-
    term_to_string(Spec, SpecStr),
    format(string(Cap), "No set-grouping picture for ~w (annotation only).",
           [SpecStr]),
    scene_dict(scene([], [], [], []), EmptyScene),
    mk_frame(1, Spec, Cap, false, EmptyScene, Frame).

%!  spec_kind(+Spec, -KindStr) is det.
spec_kind(Spec, KindStr) :-
    ( compound(Spec) -> functor(Spec, Name, _) ; Name = Spec ),
    atom_string(Name, KindStr).

%!  spec_request(+Spec, -Request) is det.
spec_request(ten_frame(N), _{ n: N }) :- !.
spec_request(make_ten(A, B), _{ a: A, b: B }) :- !.
spec_request(make_ten_drop_leftover(A, B), _{ a: A, b: B }) :- !.
spec_request(subitize(P, N), _{ pattern: PS, n: N }) :- !, term_to_string(P, PS).
spec_request(parity(N), _{ n: N }) :- !.
spec_request(compare(A, B), _{ a: AS, b: BS }) :- !,
    term_to_string(A, AS), term_to_string(B, BS).
spec_request(unfair_compare(A, B), _{ a: AS, b: BS }) :- !,
    term_to_string(A, AS), term_to_string(B, BS).
spec_request(equal_groups(G, S), _{ groups: G, size: S }) :- !.
spec_request(fair_share(T, G), _{ total: T, groups: G }) :- !.
spec_request(signed_chips(A, B), _{ a: A, b: B }) :- !.
spec_request(_, _{}).

%!  spec_result(+Spec, -ResultStr) is det.
spec_result(ten_frame(N), R) :- !, C is 10 - N,
    format(string(R), "~w filled, ~w to ten", [N, C]).
spec_result(make_ten(A, B), R) :- !,
    ( making_ten_quantities(A, B, _, _, _, Sum)
    -> format(string(R), "~w", [Sum])
    ;  R = "does not cross ten" ).
spec_result(make_ten_drop_leftover(A, B), R) :- !,
    ( making_ten_quantities(A, B, _, _, Over, Sum)
    -> format(string(R), "10 (leftover ~w dropped; correct sum ~w)", [Over, Sum])
    ;  R = "does not cross ten" ).
spec_result(subitize(_, N), R) :- !, format(string(R), "~w", [N]).
spec_result(parity(N), R) :- !,
    ( parity_from_witness(N, Res, _, _, _) -> R = Res ; R = "unknown" ).
spec_result(compare(A, B), R) :- !,
    ( compare_quantities(A, B, _, _, Res, _)
    -> term_to_string(Res, R) ; R = "unknown" ).
spec_result(unfair_compare(A, B), R) :- !,
    ( compare_quantities(A, B, _, _, Res, _)
    -> format(string(R), "grounded: ~w; deformation claims equal_to", [Res])
    ;  R = "unknown" ).
spec_result(equal_groups(G, S), R) :- !, P is G * S,
    format(string(R), "~w", [P]).
spec_result(fair_share(T, G), R) :- !, Q is T // G, Rem is T mod G,
    ( Rem =:= 0 -> format(string(R), "~w each", [Q])
    ; format(string(R), "~w each, ~w left", [Q, Rem]) ).
spec_result(signed_chips(A, B), R) :- !, S is A + B,
    format(string(R), "~w", [S]).
spec_result(_, "unknown").

%!  canvas_dict(-Canvas) is det.
canvas_dict(_{ width: 700, height: 360 }).

%!  term_to_string(+Term, -String) is det.
term_to_string(Term, String) :-
    ( string(Term)
    -> String = Term
    ;  format(string(String), '~w', [Term])
    ).
