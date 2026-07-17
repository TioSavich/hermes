/** <module> Notation scene compiler
 *
 * Notation is the glyph-level representation language: a written equation as a
 * row of single inscribed characters, each at its own (x, y), each carrying an
 * optional per-glyph deformation transform. The compiler emits the scene dict
 * the drawer's "notation" format reads (the render contract,
 * docs/render-contract-v2.md). Layout x is
 * computed here in Prolog as Col * glyphPitch; the drawer does no arithmetic.
 *
 * Two lanes, mirroring the rest of the render suite:
 *
 *   - Productive: write_equation(A, Op, B, R) lays every glyph straight
 *     (flip:none, ghost:none) with an empty marks list. This is a correct
 *     inscription: a child writes 2 + 3 = 5.
 *
 *   - Deformation: a spec routed through the grammar's labeled-misconception
 *     lane (deformation_spec_evidence(notation, Spec, _, Evidence) with
 *     mode:misconception) changes EXACTLY ONE field relative to its productive
 *     twin. A mirror-written digit flips one glyph; an operational-equals chain
 *     appends one mark. Nothing else differs. That one-field diff is the
 *     invariant the tests pin down and the reason the misconception is legible
 *     at the glyph level.
 *
 * The grammar decides WHICH glyph reverses and what the violation is; this
 * compiler places glyphs and applies the named change. `write_numeral/1` also
 * carries base/radix/digit metadata, allowing notation_scene_numeral/3 to
 * reconstruct an inscription and notation_scene_action/3 to recover candidate
 * action plans. The drawer remains render-only.
 *
 * Loaded through paths.pl (render-strategies search path).
 */

:- module(notation_scene,
          [ notation_render_frames/2,   % +Spec, -Frames
            notation_render_json/2,      % +Spec, -Dict
            notation_render_to_file/2,   % +Spec, +Path
            notation_scene_numeral/3,    % +Scene, -Numeral, -Evidence
            notation_scene_deformation/4,% +Scene, +Expected, +Kind, -Evidence
            notation_scene_action/3      % +Scene, -Plan, -Trace
          ]).

:- use_module(library(http/json), [json_write_dict/3]).
:- use_module(library(lists), [member/2, append/3]).
:- use_module(render(representation_grammar),
              [ deformation_spec_evidence/4,
                write_equation_task/5,
                written_equation_correct/4,
                reversal_prone_digit/1 ]).
:- use_module(math(recursive_unit_actions),
              [ integer_numeral/3,
                numeral_text/2,
                numeral_well_formed/1,
                numeral_place/4,
                numeral_action_witness/3,
                numeral_deformation/4
              ]).

% --- Layout constants (the render contract's notation format) --------------

notation_baseline(40).      % glyph text baseline (y), integer
notation_glyph_pitch(24).   % horizontal pitch between glyph slots
notation_glyph_size(20).    % font size
notation_canvas(_{ width: 760, height: 120 }).


%!  notation_render_frames(+Spec, -Frames) is det.
%
%   One B/M/E-style frame list. A productive inscription is a single frame; a
%   deformation is a single frame whose scene carries the one changed field.
notation_render_frames(Spec, Frames) :-
    notation_scene(Spec, Verb, Caption, Scene),
    !,
    Frame = _{ step: 1,
               verb: Verb,
               caption: Caption,
               sceneChanged: true,
               scene: Scene },
    Frames = [Frame].
notation_render_frames(Spec, [Frame]) :-
    deferred_frame(Spec, Frame).

%!  notation_render_json(+Spec, -Dict) is det.
notation_render_json(Spec, Dict) :-
    notation_render_frames(Spec, Frames),
    spec_kind(Spec, Kind),
    spec_request(Spec, Request),
    spec_result(Spec, Result),
    notation_canvas(Canvas),
    Dict = _{ kind: Kind,
              request: Request,
              result: Result,
              canvas: Canvas,
              frames: Frames }.

%!  notation_render_to_file(+Spec, +Path) is det.
notation_render_to_file(Spec, Path) :-
    notation_render_json(Spec, Dict),
    setup_call_cleanup(
        open(Path, write, Stream, [encoding(utf8)]),
        json_write_dict(Stream, Dict, [width(80)]),
        close(Stream)).


% --- Scene construction -----------------------------------------------------
%
% notation_scene(+Spec, -Verb, -Caption, -Scene): the productive lane and each
% deformation lane. A productive spec lays straight glyphs and empty marks. A
% deformation spec consults the grammar's deformation_spec_evidence/4 (the
% labeled-misconception lane) and applies EXACTLY ONE change to the productive
% scene: one glyph flips, or one mark is appended.

% Productive: write_equation(A, Op, B, R) -> straight inscription.
notation_scene(write_equation(A, Op, B, R), Verb, Caption, Scene) :-
    write_equation_task(Op, A, B, R, _Task),
    written_equation_correct(Op, A, B, R),
    !,
    equation_tokens(A, Op, B, R, Tokens),
    base_glyphs(Tokens, Glyphs),
    format(string(Verb), "write_equation(~w,~w,~w,~w)", [A, Op, B, R]),
    format(string(Caption), "Write ~w ~w ~w = ~w.", [A, Op, B, R]),
    assemble_scene(Glyphs, [], Scene).

% Deformation: a well-formed arithmetic inscription with a false result. The
% written result remains visible and is marked as the deformed region.
notation_scene(write_equation(A, Op, B, R), Verb, Caption, Scene) :-
    deformation_spec_evidence(notation, write_equation(A, Op, B, R),
                              _Task, Evidence),
    get_dict(misconception, Evidence, false_equation),
    get_dict(expected_answer, Evidence, Expected),
    !,
    equation_tokens(A, Op, B, R, Tokens),
    base_glyphs(Tokens, Glyphs0),
    mark_written_result_as_deformation(Glyphs0, Glyphs),
    format(string(Verb), "false_equation(~w,~w,~w,~w)", [A, Op, B, R]),
    format(string(Caption),
           "The inscription ~w ~w ~w = ~w conflicts with the result ~w.",
           [A, Op, B, R, Expected]),
    assemble_scene(Glyphs, [], Scene).

% Productive numeral inscription. Unlike a bare equation glyph row, this scene
% retains enough metadata to recollect the positional numeral from the drawing.
notation_scene(write_numeral(Numeral), Verb, Caption, Scene) :-
    numeral_well_formed(Numeral),
    numeral_text(Numeral, Text),
    numeral_tokens(Numeral, Tokens),
    base_glyphs(Tokens, Glyphs),
    Numeral = numeral(Base, Sign, radix(Radix), _Digits),
    atom_string(Sign, SignText),
    assemble_scene(Glyphs, [], Scene0),
    Scene = Scene0.put(_{version: 2,
                         numeralBase: Base,
                         numeralSign: SignText,
                         numeralRadix: Radix}),
    term_string(write_numeral(Numeral), Verb),
    format(string(Caption), "Write ~w in base ~w.", [Text, Base]).

% A named numeral deformation is still a fully reconstructable inscription.
% The kernel computes the changed numeral and its value divergence; this
% compiler only externalizes the resulting signs and records the named change.
notation_scene(write_deformed_numeral(Source, Kind), Verb, Caption, Scene) :-
    numeral_deformation(Source, Kind, Produced, KernelEvidence),
    numeral_text(Source, SourceText),
    numeral_text(Produced, ProducedText),
    numeral_tokens(Produced, Tokens),
    base_glyphs(Tokens, Glyphs),
    Produced = numeral(Base, Sign, radix(Radix), _),
    atom_string(Sign, SignText),
    term_string(Kind, KindText),
    Mark = _{kind: "numeral-deformation", family: KindText},
    assemble_scene(Glyphs, [Mark], Scene0),
    Scene = Scene0.put(_{version: 2,
                         numeralBase: Base,
                         numeralSign: SignText,
                         numeralRadix: Radix,
                         deformationType: KindText,
                         expectedInscription: SourceText,
                         producedInscription: ProducedText}),
    term_string(write_deformed_numeral(Source, Kind), Verb),
    get_dict(family, KernelEvidence, Family),
    format(string(Caption), "~w changes ~w to ~w.",
           [Family, SourceText, ProducedText]).

% Deformation: mirror-written numeral. The grammar names which digit reverses;
% this clause flips THAT one glyph (flip:horizontal, role:deformation) and
% leaves everything else identical to the productive twin. One field differs.
notation_scene(mirror_written(Digit, A, Op, B, R), Verb, Caption, Scene) :-
    deformation_spec_evidence(notation,
                              mirror_written(Digit, A, Op, B, R),
                              _Task, Evidence),
    get_dict(mode, Evidence, misconception),
    !,
    equation_tokens(A, Op, B, R, Tokens),
    base_glyphs(Tokens, Glyphs0),
    flip_first_digit(Glyphs0, Digit, Glyphs),
    format(string(Verb), "mirror_written(~w,~w,~w,~w,~w)",
           [Digit, A, Op, B, R]),
    format(string(Caption),
           "Mirror-written ~w in ~w ~w ~w = ~w.", [Digit, A, Op, B, R]),
    assemble_scene(Glyphs, [], Scene).

% Deformation: operational-equals chain. The productive glyph row is unchanged;
% one chain-equals mark is appended under the equals sign. One field differs
% (marks goes from [] to a singleton); the glyph list is untouched.
notation_scene(operational_equals_chain(A, Op, B, RunningTotal),
               Verb, Caption, Scene) :-
    deformation_spec_evidence(notation,
                              operational_equals_chain(A, Op, B, RunningTotal),
                              _Task, Evidence),
    get_dict(mode, Evidence, misconception),
    !,
    equation_tokens(A, Op, B, RunningTotal, Tokens),
    base_glyphs(Tokens, Glyphs),
    equals_glyph_x(Glyphs, EqX),
    notation_baseline(Y),
    Mark = _{ kind: "chain-equals", x: EqX, y: Y },
    format(string(Verb), "operational_equals_chain(~w,~w,~w,~w)",
           [A, Op, B, RunningTotal]),
    format(string(Caption),
           "Equals read as makes: ~w ~w ~w chained to ~w.",
           [A, Op, B, RunningTotal]),
    assemble_scene(Glyphs, [Mark], Scene).

% Deformation: the FULL running-equals chain (the literal 2+3=5+4=9 inscription).
% Steps is a list of Acc-Op-B links; Final is the last running total. The whole
% chain is laid as one glyph row left to right; a chain-equals tick is appended
% under each = whose cumulative left side no longer equals its right side (every =
% after the first, since the running string 2+3=5+4 is already false against 9).
% Gated through the grammar's labeled-misconception lane exactly like the
% single-step form.
notation_scene(operational_equals_chain_full(Steps, Final),
               Verb, Caption, Scene) :-
    deformation_spec_evidence(notation,
                              operational_equals_chain_full(Steps, Final),
                              _Task, Evidence),
    get_dict(mode, Evidence, misconception),
    !,
    chain_tokens(Steps, Final, Tokens),
    base_glyphs(Tokens, Glyphs),
    chain_equals_marks(Glyphs, Marks),
    format(string(Verb), "operational_equals_chain_full(~w,~w)",
           [Steps, Final]),
    chain_string(Steps, Final, ChainStr),
    format(string(Caption),
           "Equals read as makes: the running chain ~w.", [ChainStr]),
    assemble_scene(Glyphs, Marks, Scene).

% Deformation: place-value writing error. The A Op B = part is laid straight; the
% result is re-inscribed with its digits in reversed place-value order (13 -> 31),
% every reversed result glyph carrying role:deformation. The grammar names the
% mis-ordered answer; this clause only places the glyphs. Marks stays empty -- the
% deformation lives in the result glyphs, not in a mark. Gated through the
% labeled-misconception lane exactly like the other deformations.
notation_scene(place_value_writing_error(A, Op, B, R), Verb, Caption, Scene) :-
    deformation_spec_evidence(notation,
                              place_value_writing_error(A, Op, B, R),
                              _Task, Evidence),
    get_dict(mode, Evidence, misconception),
    get_dict(wrong_answer, Evidence, WrongAnswer),
    !,
    equation_tokens(A, Op, B, R, Tokens),
    base_glyphs(Tokens, Glyphs0),
    mark_result_as_deformation(Glyphs0, WrongAnswer, Glyphs),
    format(string(Verb), "place_value_writing_error(~w,~w,~w,~w)",
           [A, Op, B, R]),
    format(string(Caption),
           "Place value reversed: ~w ~w ~w = ~w written as ~w.",
           [A, Op, B, R, WrongAnswer]),
    assemble_scene(Glyphs, [], Scene).

% Deformation: dropped carry mark. The units sum carries into the next place; the
% child writes the dropped-carry answer (8 + 4 = 12 recorded as 2) and omits the
% carry. The result is re-inscribed as the dropped-carry value (role:deformation),
% and ONE carry mark sits above the result as a superscript, tagged status:dropped
% -- the small carry digit the child failed to add. The grammar computes both the
% dropped answer and the carry digit; this clause only places them.
notation_scene(carry_mark(A, Op, B, R), Verb, Caption, Scene) :-
    deformation_spec_evidence(notation,
                              carry_mark(A, Op, B, R),
                              _Task, Evidence),
    get_dict(mode, Evidence, misconception),
    get_dict(wrong_answer, Evidence, WrongAnswer),
    get_dict(carry_digit, Evidence, CarryDigit),
    !,
    equation_tokens(A, Op, B, R, Tokens),
    base_glyphs(Tokens, Glyphs0),
    mark_result_as_deformation(Glyphs0, WrongAnswer, Glyphs),
    carry_mark_over_result(Glyphs, CarryDigit, CarryMark),
    format(string(Verb), "carry_mark(~w,~w,~w,~w)", [A, Op, B, R]),
    format(string(Caption),
           "Dropped carry: ~w ~w ~w = ~w written as ~w (carry ~w not added).",
           [A, Op, B, R, WrongAnswer, CarryDigit]),
    assemble_scene(Glyphs, [CarryMark], Scene).


% --- Token -> glyph layout --------------------------------------------------
%
% equation_tokens/5 turns A Op B = R into a flat token list, one token per
% inscribed character. Multi-digit numbers contribute one digit token each, so
% the glyph row reads left to right exactly as written.

equation_tokens(A, Op, B, R, Tokens) :-
    number_digit_tokens(A, ATokens),
    number_digit_tokens(B, BTokens),
    number_digit_tokens(R, RTokens),
    op_token(Op, OpToken),
    append(ATokens, [OpToken | BTokens], Left),
    append(Left, [equals('=') | RTokens], Tokens).

number_digit_tokens(N, Tokens) :-
    integer(N), N >= 0,
    integer_numeral(N, 10, numeral(10, _Sign, _Radix, Digits)),
    maplist(plain_digit_token, Digits, Tokens).

plain_digit_token(digit(_Value, Glyph), digit(Glyph)).

numeral_tokens(Numeral, Tokens) :-
    Numeral = numeral(_Base, Sign, radix(Radix), Digits),
    numeral_well_formed(Numeral),
    findall(numeral_digit(Value, Glyph, Place),
            numeral_place(Numeral, Place, Value, Glyph),
            DigitTokens),
    length(IntegerTokens, Radix),
    append(IntegerTokens, FractionTokens, DigitTokens),
    radix_tokens(FractionTokens, IntegerTokens, UnsignedTokens),
    sign_tokens(Sign, UnsignedTokens, Tokens),
    same_length(Digits, DigitTokens).

radix_tokens([], IntegerTokens, IntegerTokens) :- !.
radix_tokens(FractionTokens, IntegerTokens, Tokens) :-
    append(IntegerTokens, [radix_point('.')|FractionTokens], Tokens).

sign_tokens(negative, Tokens, [sign('-')|Tokens]) :- !.
sign_tokens(_Sign, Tokens, Tokens).

% chain_tokens(+Steps, +Final, -Tokens): flatten a running chain into a token row.
% Steps is [Acc-Op-B|...]; the inscription reads Acc Op B = NextAcc Op B = ... Final.
% Each link contributes Acc Op B = ; the chain ends at Final. The first link
% inscribes its own Acc, so the row spells the whole running string left to right.
chain_tokens([Acc - Op - B | More], Final, Tokens) :-
    number_digit_tokens(Acc, AccTokens),
    op_token(Op, OpToken),
    number_digit_tokens(B, BTokens),
    append(AccTokens, [OpToken | BTokens], Head),
    chain_rest(More, Final, RestTokens),
    append(Head, [equals('=') | RestTokens], Tokens).

% chain_rest(+RemainingLinks, +Final, -Tokens): the tail after the first link's =.
% A link Acc-Op-B inscribes Acc Op B = (its Acc is the prior running total written
% again). When no links remain, the chain terminates at Final.
chain_rest([], Final, FinalTokens) :-
    number_digit_tokens(Final, FinalTokens).
chain_rest([Acc - Op - B | More], Final, Tokens) :-
    number_digit_tokens(Acc, AccTokens),
    op_token(Op, OpToken),
    number_digit_tokens(B, BTokens),
    append(AccTokens, [OpToken | BTokens], Head),
    chain_rest(More, Final, RestTokens),
    append(Head, [equals('=') | RestTokens], Tokens).

% chain_equals_marks(+Glyphs, -Marks): one chain-equals tick under every equals
% glyph except the first. The first = (Acc Op B = its own correct sum) reads true;
% every later = makes the cumulative inscription false, so each carries a tick.
chain_equals_marks(Glyphs, Marks) :-
    notation_baseline(Y),
    findall(EX, ( member(G, Glyphs),
                  get_dict(role, G, "equals"),
                  get_dict(x, G, EX) ), EqXs),
    ( EqXs = [_First | RunningFalse]
    -> findall(_{ kind: "chain-equals", x: EX, y: Y },
               member(EX, RunningFalse), Marks)
    ;  Marks = [] ).

% chain_string(+Steps, +Final, -String): the readable running string for the
% caption, e.g. "2+3=5+4=9".
chain_string([Acc - Op - B | More], Final, String) :-
    format(string(Head), "~w~w~w", [Acc, Op, B]),
    chain_string_rest(More, Final, Rest),
    string_concat(Head, Rest, String).

chain_string_rest([], Final, String) :-
    format(string(String), "=~w", [Final]).
chain_string_rest([Acc - Op - B | More], Final, String) :-
    format(string(Head), "=~w~w~w", [Acc, Op, B]),
    chain_string_rest(More, Final, Rest),
    string_concat(Head, Rest, String).

op_token(+, operator('+')).
op_token(-, operator('-')).
op_token(=, equals('=')).
op_token(*, operator('×')).

% base_glyphs(+Tokens, -Glyphs): lay the token row left to right at column
% pitch, every glyph straight (flip:none, ghost:none). Column index drives x.
base_glyphs(Tokens, Glyphs) :-
    notation_baseline(Y),
    notation_glyph_pitch(Pitch),
    notation_glyph_size(Size),
    enumerate(Tokens, 0, Indexed),
    findall(G,
            ( member(Col-Token, Indexed),
              token_glyph(Token, Col, Pitch, Y, Size, G) ),
            Glyphs).

enumerate([], _, []).
enumerate([T|Ts], I, [I-T|Rest]) :-
    I1 is I + 1,
    enumerate(Ts, I1, Rest).

token_glyph(Token, Col, Pitch, Y, Size, Glyph) :-
    X is Col * Pitch,
    token_char_role(Token, Ch, Role),
    Glyph0 = _{ x: X,
                y: Y,
                ch: Ch,
                role: Role,
                size: Size,
                flip: "none",
                ghost: "none" },
    token_metadata(Token, Glyph0, Glyph).

token_char_role(digit(D), Ch, "digit") :-
    ( string(D) -> Ch = D ; atom_string(D, Ch) ).
token_char_role(numeral_digit(_Value, Glyph, _Place), Glyph, "digit").
token_char_role(operator(O), Ch, "operator") :-
    atom_string(O, Ch).
token_char_role(equals(E), Ch, "equals") :-
    atom_string(E, Ch).
token_char_role(radix_point(Point), Ch, "radix") :-
    atom_string(Point, Ch).
token_char_role(sign(Sign), Ch, "sign") :-
    atom_string(Sign, Ch).

token_metadata(numeral_digit(Value, Glyph, Place), Glyph0, GlyphDict) :-
    !,
    GlyphDict = Glyph0.put(_{digitValue: Value,
                             digitGlyph: Glyph,
                             place: Place}).
token_metadata(_Token, Glyph, Glyph).


% --- The single-field deformation edits -------------------------------------
%
% flip_first_digit(+Glyphs, +Digit, -Glyphs): flip the FIRST glyph whose
% character is Digit. flip:none -> horizontal and role:digit -> deformation on
% that one glyph; every other glyph is returned unchanged. Exactly one glyph,
% exactly two fields on it, change; x/y/ch/size/ghost are untouched.
flip_first_digit(Glyphs, Digit, Flipped) :-
    atom_string(Digit, DigitStr),
    flip_first_digit_(Glyphs, DigitStr, Flipped).

flip_first_digit_([], _DigitStr, []).
flip_first_digit_([G|Gs], DigitStr, [G2|Gs]) :-
    get_dict(ch, G, DigitStr),
    get_dict(role, G, "digit"),
    !,
    G1 = G.put(flip, "horizontal"),
    G2 = G1.put(role, "deformation").
flip_first_digit_([G|Gs], DigitStr, [G|Rest]) :-
    flip_first_digit_(Gs, DigitStr, Rest).

% mark_result_as_deformation(+Glyphs, +WrongAnswer, -Glyphs2): replace every glyph
% after the equals sign with the WrongAnswer digits, each laid on the same x grid
% (starting at the original first result slot, advancing by glyph pitch) and marked
% role:deformation. The prefix A Op B = is untouched, so only the inscribed result
% changes. Shared by the place-value-writing-error and dropped-carry scenes.
mark_result_as_deformation(Glyphs0, WrongAnswer, Glyphs) :-
    split_glyphs_at_equals(Glyphs0, Prefix, EqGlyph, ResultGlyphs),
    ResultGlyphs = [FirstResult | _],
    get_dict(x, FirstResult, StartX),
    get_dict(y, FirstResult, Y),
    get_dict(size, FirstResult, Size),
    notation_glyph_pitch(Pitch),
    number_codes(WrongAnswer, WrongCodes),
    deformation_result_glyphs(WrongCodes, StartX, Pitch, Y, Size, NewResult),
    append(Prefix, [EqGlyph | NewResult], Glyphs).

mark_written_result_as_deformation(Glyphs0, Glyphs) :-
    split_glyphs_at_equals(Glyphs0, Prefix, EqGlyph, ResultGlyphs0),
    maplist(mark_deformation_glyph, ResultGlyphs0, ResultGlyphs),
    append(Prefix, [EqGlyph | ResultGlyphs], Glyphs).

mark_deformation_glyph(Glyph0, Glyph) :-
    Glyph = Glyph0.put(role, "deformation").

% split_glyphs_at_equals(+Glyphs, -Prefix, -EqGlyph, -ResultGlyphs): partition the
% glyph row at the equals sign.
split_glyphs_at_equals([G | Gs], [], G, Gs) :-
    get_dict(role, G, "equals"),
    !.
split_glyphs_at_equals([G | Gs], [G | Prefix], EqGlyph, ResultGlyphs) :-
    split_glyphs_at_equals(Gs, Prefix, EqGlyph, ResultGlyphs).

% deformation_result_glyphs(+Codes, +X, +Pitch, +Y, +Size, -Glyphs): inscribe the
% wrong-answer digits left to right from X, each role:deformation, straight glyphs.
deformation_result_glyphs([], _, _, _, _, []).
deformation_result_glyphs([C | Cs], X, Pitch, Y, Size, [G | Gs]) :-
    char_code(Ch, C),
    atom_string(Ch, ChStr),
    G = _{ x: X, y: Y, ch: ChStr, role: "deformation",
           size: Size, flip: "none", ghost: "none" },
    X1 is X + Pitch,
    deformation_result_glyphs(Cs, X1, Pitch, Y, Size, Gs).

% carry_mark_over_result(+Glyphs, +CarryDigit, -Mark): the dropped carry as a
% single superscript mark sitting above the first (deformed) result glyph, one
% glyph pitch above the baseline. status:dropped records that the child omitted it.
carry_mark_over_result(Glyphs, CarryDigit, Mark) :-
    ( member(G, Glyphs),
      get_dict(role, G, "deformation"),
      get_dict(x, G, StartX)
    -> true
    ;  StartX = 0 ),
    notation_baseline(Y),
    notation_glyph_pitch(Pitch),
    CarryY is Y - Pitch,
    atom_string(CarryDigit, CarryStr),
    Mark = _{ kind: "carry", x: StartX, y: CarryY,
              carry: CarryStr, status: "dropped" }.

% equals_glyph_x(+Glyphs, -X): the x of the equals glyph, where the chain-equals
% tick is anchored.
equals_glyph_x(Glyphs, X) :-
    member(G, Glyphs),
    get_dict(role, G, "equals"),
    get_dict(x, G, X),
    !.


% --- Scene assembly ---------------------------------------------------------

assemble_scene(Glyphs, Marks, Scene) :-
    notation_baseline(Y),
    notation_glyph_pitch(Pitch),
    Scene = _{ format: "notation",
               version: 1,
               baseline: Y,
               glyphPitch: Pitch,
               glyphs: Glyphs,
               marks: Marks }.


%!  notation_scene_numeral(+Scene, -Numeral, -Evidence) is semidet.
%
%   Recollect a numeral from glyph metadata emitted by write_numeral/1. The
%   displayed glyph must still agree with its digit sign; a changed inscription
%   is not silently repaired during reconstruction.
notation_scene_numeral(Scene, Numeral, Evidence) :-
    get_dict(format, Scene, "notation"),
    get_dict(numeralBase, Scene, Base),
    get_dict(numeralSign, Scene, SignText),
    get_dict(numeralRadix, Scene, Radix),
    atom_string(Sign, SignText),
    get_dict(glyphs, Scene, Glyphs),
    findall(Digit,
            ( member(Glyph, Glyphs), scene_digit(Glyph, Digit) ),
            Digits),
    Digits = [_|_],
    Numeral = numeral(Base, Sign, radix(Radix), Digits),
    numeral_well_formed(Numeral),
    findall(action_candidate(Plan, Trace),
            numeral_action_witness(Numeral, Plan, Trace),
            Candidates),
    length(Digits, DigitCount),
    Evidence = notation_recollection{
        source: glyph_metadata,
        digit_count: DigitCount,
        action_candidates: Candidates
    }.


%!  notation_scene_action(+Scene, -Plan, -Trace) is nondet.
notation_scene_action(Scene, Plan, Trace) :-
    notation_scene_numeral(Scene, Numeral, _Evidence),
    numeral_action_witness(Numeral, Plan, Trace).


%!  notation_scene_deformation(+Scene, +Expected, +Kind, -Evidence) is semidet.
notation_scene_deformation(Scene, Expected, Kind, Evidence) :-
    notation_scene_numeral(Scene, Produced, Recollection),
    numeral_deformation(Expected, Kind, Produced, KernelEvidence),
    term_string(Kind, KindText),
    get_dict(deformationType, Scene, KindText),
    Evidence = notation_deformation_recollection{
        kind: KindText,
        produced_numeral: Produced,
        kernel_evidence: KernelEvidence,
        recollection: Recollection
    }.

scene_digit(Glyph, digit(Value, DigitGlyph)) :-
    get_dict(role, Glyph, "digit"),
    get_dict(digitValue, Glyph, Value),
    get_dict(digitGlyph, Glyph, DigitGlyph),
    get_dict(ch, Glyph, DigitGlyph).

deferred_frame(Spec, Frame) :-
    term_string(Spec, SpecStr),
    format(string(Cap), "No notation layout for ~w.", [SpecStr]),
    assemble_scene([], [], Scene),
    Frame = _{ step: 1,
               verb: SpecStr,
               caption: Cap,
               sceneChanged: false,
               scene: Scene }.


% --- Spec metadata ----------------------------------------------------------

spec_kind(Spec, Kind) :-
    ( compound(Spec) -> functor(Spec, Name, _) ; Name = Spec ),
    atom_string(Name, Kind).

spec_request(write_equation(A, Op, B, R), _{ a: A, op: OpStr, b: B, r: R }) :-
    !,
    atom_string(Op, OpStr).
spec_request(write_numeral(Numeral),
             _{base: Base, sign: SignText, radix: Radix, numeral: Text}) :-
    !,
    Numeral = numeral(Base, Sign, radix(Radix), _),
    atom_string(Sign, SignText),
    numeral_text(Numeral, Text).
spec_request(write_deformed_numeral(Source, Kind),
             _{source: SourceText, deformation: KindText}) :-
    !,
    numeral_text(Source, SourceText),
    term_string(Kind, KindText).
spec_request(Spec, _{ spec: S }) :-
    term_string(Spec, S).

spec_result(write_equation(_A, _Op, _B, R), Result) :-
    !,
    ( integer(R) -> atom_string(R, Result) ; term_string(R, Result) ).
spec_result(mirror_written(_D, _A, _Op, _B, R), Result) :-
    !,
    ( integer(R) -> atom_string(R, Result) ; term_string(R, Result) ).
spec_result(write_numeral(Numeral), Result) :-
    !,
    numeral_text(Numeral, Result).
spec_result(write_deformed_numeral(Source, Kind), Result) :-
    !,
    numeral_deformation(Source, Kind, Produced, _),
    numeral_text(Produced, Result).
spec_result(_Spec, "unknown").
