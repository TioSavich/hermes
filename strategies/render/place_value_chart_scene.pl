/** <module> Place-value chart scene compiler
 *
 * A place-value chart is a symbolic positional representation. It names places,
 * aligns digits by place, and records regrouping/carry facts. It is not a
 * physical base-ten-block renderer and it emits no block primitives.
 */

:- module(place_value_chart_scene,
          [ place_value_chart_render_frames/2,   % +Spec, -Frames
            place_value_chart_render_json/2,      % +Spec, -Dict
            place_value_chart_render_to_file/2    % +Spec, +Path
          ]).

:- use_module(library(http/json), [json_write_dict/3]).
:- use_module(math(recursive_unit_actions),
              [ integer_numeral/3,
                numeral_text/2,
                digit_sign/3
              ]).


%!  place_value_chart_render_frames(+Spec, -Frames) is det.
place_value_chart_render_frames(add_with_carry(A, B, Base), Frames) :-
    integer(A), A >= 0,
    integer(B), B >= 0,
    integer(Base), Base >= 2,
    !,
    addition_frames(A, B, Base, Frames).
place_value_chart_render_frames(Spec, [Frame]) :-
    deferred_frame(Spec, Frame).

%!  place_value_chart_render_json(+Spec, -Dict) is det.
place_value_chart_render_json(Spec, Dict) :-
    place_value_chart_render_frames(Spec, Frames),
    spec_kind(Spec, Kind),
    spec_request(Spec, Request),
    spec_result(Spec, Result),
    canvas_dict(Canvas),
    Dict = _{ kind: Kind,
              request: Request,
              result: Result,
              canvas: Canvas,
              frames: Frames }.

%!  place_value_chart_render_to_file(+Spec, +Path) is det.
place_value_chart_render_to_file(Spec, Path) :-
    place_value_chart_render_json(Spec, Dict),
    setup_call_cleanup(
        open(Path, write, Stream),
        json_write_dict(Stream, Dict, [width(80)]),
        close(Stream)).


% --- Addition ---------------------------------------------------------------

addition_frames(A, B, Base, Frames) :-
    Sum is A + B,
    max_places([A, B, Sum], Base, 1, NPlaces),
    digits_padded(A, Base, NPlaces, ALow),
    digits_padded(B, Base, NPlaces, BLow),
    digits_padded(Sum, Base, NPlaces, SumLow),
    columns(NPlaces, Base, Columns),
    high_digits(ALow, AHigh),
    high_digits(BLow, BHigh),
    high_digits(SumLow, SumHigh),
    number_label(A, Base, ALabel),
    number_label(B, Base, BLabel),
    number_label(Sum, Base, SumLabel),
    digit_glyphs(Base, AHigh, AGlyphs),
    digit_glyphs(Base, BHigh, BGlyphs),
    digit_glyphs(Base, SumHigh, SumGlyphs),
    RowA = _{ role: "addend", label: ALabel, digits: AHigh,
              digitGlyphs: AGlyphs },
    RowB = _{ role: "addend", label: BLabel, digits: BHigh,
              digitGlyphs: BGlyphs },
    RowSum = _{ role: "sum", label: SumLabel, digits: SumHigh,
                digitGlyphs: SumGlyphs },
    addition_carries(ALow, BLow, Base, Carries),
    make_frame(
        1,
        show_addends(A, B),
        "Align the addends by place value.",
        Columns,
        [RowA, RowB],
        [],
        F1
    ),
    format(string(Cap2),
           "Regroup symbolically by place; carry only when a place makes a full base-group.",
           []),
    make_frame(2, carry_by_place, Cap2, Columns, [RowA, RowB], Carries, F2),
    format(string(Cap3), "~w + ~w = ~w.", [ALabel, BLabel, SumLabel]),
    make_frame(3, sum(Sum), Cap3, Columns, [RowA, RowB, RowSum], Carries, F3),
    Frames = [F1, F2, F3].

addition_carries(ALow, BLow, Base, Carries) :-
    addition_carries_(0, ALow, BLow, Base, 0, Carries).

addition_carries_(_Exp, [], [], _Base, _CarryIn, []) :- !.
addition_carries_(Exp, [A|As], [B|Bs], Base, CarryIn, Carries) :-
    Raw is A + B + CarryIn,
    CarryOut is Raw // Base,
    Exp1 is Exp + 1,
    addition_carries_(Exp1, As, Bs, Base, CarryOut, Rest),
    ( CarryOut > 0
    -> carry_label(Exp1, Base, CarryOut, Label),
       Carries = [_{ fromPlace: Exp,
                     toPlace: Exp1,
                     amount: CarryOut,
                     label: Label } | Rest]
    ;  Carries = Rest
    ).


% --- Scene assembly ---------------------------------------------------------

make_frame(Step, Verb, Caption, Columns, Rows, Carries, Frame) :-
    term_to_string(Verb, VerbStr),
    scene_dict(Columns, Rows, Carries, Scene),
    Frame = _{ step: Step,
               verb: VerbStr,
               caption: Caption,
               sceneChanged: true,
               scene: Scene }.

scene_dict(Columns, Rows, Carries, Scene) :-
    ( Columns = [C0|_], get_dict(base, C0, Base) -> true ; Base = 10 ),
    Scene = _{ format: "place-value-chart",
               version: 1,
               base: Base,
               columns: Columns,
               rows: Rows,
               carries: Carries }.

deferred_frame(Spec, Frame) :-
    term_to_string(Spec, SpecStr),
    format(string(Cap), "No place-value chart layout for ~w.", [SpecStr]),
    scene_dict([], [], [], Scene),
    Frame = _{ step: 1,
               verb: SpecStr,
               caption: Cap,
               sceneChanged: false,
               scene: Scene }.


% --- Columns and digits -----------------------------------------------------

columns(NPlaces, Base, Columns) :-
    High is NPlaces - 1,
    numlist_down(High, 0, Places),
    maplist(column(Base), Places, Columns).

column(Base, Exp, _{ place: Exp,
                     label: Label,
                     value: Value,
                     base: Base }) :-
    place_label(Exp, Base, Label),
    Value is Base ** Exp.

digits_padded(N, Base, NPlaces, Low) :-
    low_digits(N, Base, Low0),
    pad_to(Low0, NPlaces, 0, Low).

low_digits(N, Base, Low) :-
    N >= 0,
    integer_numeral(N, Base,
                    numeral(Base, _Sign, _Radix, HighDigits)),
    maplist(numeral_digit_value, HighDigits, High),
    reverse(High, Low).

pad_to(List, N, _Fill, List) :-
    length(List, L),
    L >= N,
    !.
pad_to(List, N, Fill, Padded) :-
    length(List, L),
    Need is N - L,
    length(Tail, Need),
    maplist(=(Fill), Tail),
    append(List, Tail, Padded).

high_digits(Low, High) :-
    reverse(Low, High).

max_places(Numbers, Base, Floor, N) :-
    max_places_(Numbers, Base, Floor, N).

max_places_([], _Base, N, N).
max_places_([X|Xs], Base, Acc, N) :-
    places_needed(X, Base, P),
    Acc1 is max(Acc, P),
    max_places_(Xs, Base, Acc1, N).

places_needed(0, _Base, 1) :- !.
places_needed(N, Base, Count) :-
    low_digits(N, Base, Low),
    length(Low, Count).

numeral_digit_value(digit(Value, _Glyph), Value).

digit_glyphs(Base, Values, Glyphs) :-
    maplist(digit_sign(Base), Values, Glyphs).

numlist_down(High, Low, []) :-
    High < Low,
    !.
numlist_down(High, Low, [High|Rest]) :-
    High >= Low,
    High1 is High - 1,
    numlist_down(High1, Low, Rest).


% --- Labels ----------------------------------------------------------------

place_label(Exp, 10, Label) :-
    !,
    base_ten_place_label(Exp, Label).
place_label(0, _Base, "ones") :- !.
place_label(Exp, Base, Label) :-
    format(string(Label), "base ~w^~w", [Base, Exp]).

base_ten_place_label(0, "ones") :- !.
base_ten_place_label(1, "tens") :- !.
base_ten_place_label(2, "hundreds") :- !.
base_ten_place_label(3, "thousands") :- !.
base_ten_place_label(4, "ten-thousands") :- !.
base_ten_place_label(5, "hundred-thousands") :- !.
base_ten_place_label(6, "millions") :- !.
base_ten_place_label(7, "ten-millions") :- !.
base_ten_place_label(8, "hundred-millions") :- !.
base_ten_place_label(Exp, Label) :-
    format(string(Label), "10^~w place", [Exp]).

singular_place_label(0, "one") :- !.
singular_place_label(1, "ten") :- !.
singular_place_label(2, "hundred") :- !.
singular_place_label(3, "thousand") :- !.
singular_place_label(4, "ten-thousand") :- !.
singular_place_label(5, "hundred-thousand") :- !.
singular_place_label(6, "million") :- !.
singular_place_label(Exp, Label) :-
    format(string(Label), "10^~w place", [Exp]).

carry_label(ToExp, 10, Amount, Label) :-
    !,
    singular_place_label(ToExp, Place),
    ( Amount =:= 1
    -> format(string(Label), "+1 ~w", [Place])
    ;  format(string(Label), "+~w ~ws", [Amount, Place])
    ).
carry_label(ToExp, Base, Amount, Label) :-
    format(string(Label), "+~w base ~w^~w unit", [Amount, Base, ToExp]).

number_label(N, 10, Label) :-
    !,
    format(string(Label), "~D", [N]).
number_label(N, Base, Label) :-
    integer_numeral(N, Base, Numeral),
    numeral_text(Numeral, Label).


% --- Spec metadata ----------------------------------------------------------

spec_kind(Spec, Kind) :-
    ( compound(Spec) -> functor(Spec, Name, _) ; Name = Spec ),
    atom_string(Name, Kind).

spec_request(add_with_carry(A, B, Base), _{ a: A, b: B, base: Base }) :- !.
spec_request(Spec, _{ spec: S }) :-
    term_to_string(Spec, S).

spec_result(add_with_carry(A, B, Base), Result) :- !,
    Sum is A + B,
    number_label(Sum, Base, Result).
spec_result(_Spec, "unknown").

canvas_dict(_{ width: 760, height: 360 }).

term_to_string(Term, String) :-
    ( string(Term)
    -> String = Term
    ;  format(string(String), '~w', [Term])
    ).
