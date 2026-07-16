/** <module> Parametric notation deformations
 *
 * The inscription family. A documented student-work error in the written act
 * itself — a reversed numeral, a transposed answer, an equals sign read as
 * "makes" — is GENERALISED here into a function of the lesson's numbers. The
 * same rule that flips the 3 in 3+2=5 flips the 7 in 7+1=8; the deformation is
 * a rule over which reversal-prone digit the operands contain, not a fixed
 * picture. This mirrors parametric_partition_deformation.pl, where the same
 * transplant botches 1/4, 1/5, 1/6, 1/8 and differs only in the cut count.
 *
 * Three layers, all read-only over the grammar and the notation compiler:
 *
 *   1. productive_notation_scene(write_equation(A, Op, B, R), FramesDict)
 *      The CORRECT inscription: every glyph straight, no marks. A child writes
 *      2 + 3 = 5. Delegates to notation_scene:notation_render_json/2.
 *
 *   2. deformed_notation_scene(Spec, notation_error(Type), FramesDict)
 *      A named notation misconception, parametric over the operands. EVERY
 *      deformed scene is routed through the grammar's labeled-misconception
 *      gate deformation_spec_evidence(notation, ...) before any glyph flips:
 *      there is no ungated flip. role:deformation marks the changed glyph(s),
 *      so a deformation is only ever a labeled misconception, never an
 *      unlabeled productive inscription.
 *
 *   3. replicate_notation_deformation(notation_error(Type), ListOfArgs, FramesList)
 *      The replication win: the SAME deformation across several operand sets.
 *      The frame specs differ only in which glyph is inscribed/flipped; the
 *      deformation rule (flip the reversal-prone digit / transpose the answer)
 *      is constant. FramesList is a list of Args-FramesDict pairs.
 *
 * notation_deformation_evidence/2 carries each error's honesty boundary into
 * the data: corpus_attested for the equals-as-makes chain (its inscription
 * form and violation family are attested, though the K/G1 instance is not),
 * literature_only for the reversed numeral and the transposed answer (no
 * instance in this corpus; rendered parametrically). The provenance comes from
 * the grammar's own Evidence dict, not from a hard-coded list here.
 *
 * The parametric move per error:
 *   - mirror_written_numeral: a function of WHICH reversal-prone digit (3,5,7,9)
 *     the operands contain. Change the operands and only the flipped glyph
 *     changes.
 *   - digit_transposition: a function of (A, B). The transposed (wrong) answer
 *     is computed in Prolog by the grammar gate, not supplied by the drawer.
 *   - operational_equals_chain: a function of the chained running total.
 *
 * GROUNDING vs RENDER separation is preserved: the grammar decides what the
 * deformation IS and which numbers it is a function of; the notation compiler
 * places glyphs; the drawer projects. This file edits neither the grammar nor
 * the drawer; it composes the existing pieces into a parametric author.
 *
 * Loaded through paths.pl (render-strategies search path).
 */

:- module(parametric_notation_deformation,
          [ productive_notation_scene/2,     % +write_equation(A,Op,B,R), -FramesDict
            deformed_notation_scene/3,        % +Spec, +notation_error(Type), -FramesDict
            replicate_notation_deformation/3, % +notation_error(Type), +ListOfArgs, -FramesList
            reversal_prone_digit/1,           % ?Digit   (3 ; 5 ; 7 ; 9)
            notation_deformation_evidence/2   % +notation_error(Type), -Provenance
          ]).

:- use_module(library(lists), [member/2, append/3]).
:- use_module(render(notation_scene),
              [ notation_render_json/2 ]).
:- use_module(render(representation_grammar),
              [ deformation_spec_evidence/4,
                write_equation_task/5,
                reversal_prone_digit/1 ]).

% Re-export the reversal-prone digit set so callers of this layer can ask which
% digits the parametric move ranges over without also importing the grammar.
% The single source of truth is the grammar's reversal_prone_digit/1.


% --- Layer 1: productive (licensed) inscription ------------------------------
%
% productive_notation_scene(+write_equation(A, Op, B, R), -FramesDict): the
% CORRECT inscription. Delegates straight to the notation compiler's productive
% lane, which lays every glyph flip:none/ghost:none with an empty marks list.

productive_notation_scene(write_equation(A, Op, B, R), Dict) :-
    write_equation_task(Op, A, B, R, _Task),
    notation_render_json(write_equation(A, Op, B, R), Dict).


% --- Layer 2: deformed (misconception) inscription ---------------------------
%
% deformed_notation_scene(+Spec, +notation_error(Type), -FramesDict): a named
% notation misconception, parametric over the operands. The Type selects which
% grammar gate the Spec must pass. mirror_written_numeral and
% operational_equals_chain delegate to the notation compiler (which itself
% re-consults the gate, so the flip/mark is gated twice over). digit_transposition
% has no compiler clause yet, so this layer builds its scene directly from the
% productive glyphs and the gate's computed wrong answer.

% mirror_written_numeral: the compiler flips the named reversal-prone digit. The
% Spec is mirror_written(Digit, A, Op, B, R). When the caller hands a
% write_equation(...) spec, choose the reversal-prone digit from the operands.
deformed_notation_scene(Spec, notation_error(mirror_written_numeral), Dict) :-
    mirror_spec(Spec, mirror_written(Digit, A, Op, B, R)),
    % gate: the flip exists only because the grammar names it a misconception.
    deformation_spec_evidence(notation,
                              mirror_written(Digit, A, Op, B, R),
                              _Task, Evidence),
    get_dict(mode, Evidence, misconception),
    notation_render_json(mirror_written(Digit, A, Op, B, R), Dict).

% operational_equals_chain: the compiler appends one chain-equals mark. The Spec
% is operational_equals_chain(A, Op, B, RunningTotal).
deformed_notation_scene(operational_equals_chain(A, Op, B, RunningTotal),
                        notation_error(operational_equals_chain), Dict) :-
    deformation_spec_evidence(notation,
                              operational_equals_chain(A, Op, B, RunningTotal),
                              _Task, Evidence),
    get_dict(mode, Evidence, misconception),
    notation_render_json(operational_equals_chain(A, Op, B, RunningTotal), Dict).

% digit_transposition: the gate computes the swapped (wrong) answer from (A, B);
% this layer lays the productive A Op B = part straight and inscribes the
% transposed answer digits as role:deformation. The wrong answer is a Prolog
% fact from the gate, not a drawer choice.
deformed_notation_scene(digit_transposition(A, Op, B, R),
                        notation_error(digit_transposition), Dict) :-
    deformation_spec_evidence(notation,
                              digit_transposition(A, Op, B, R),
                              _Task, Evidence),
    get_dict(mode, Evidence, misconception),
    get_dict(wrong_answer, Evidence, WrongAnswer),
    transposition_scene(A, Op, B, R, WrongAnswer, Dict).

% place_value_writing_error: the gate computes the reversed-place-value answer; the
% notation compiler lays the A Op B = part straight and re-inscribes the result with
% the reversed digits as role:deformation. Delegated to the compiler (which itself
% re-consults the gate), so the deformation is gated twice over.
deformed_notation_scene(place_value_writing_error(A, Op, B, R),
                        notation_error(place_value_writing_error), Dict) :-
    deformation_spec_evidence(notation,
                              place_value_writing_error(A, Op, B, R),
                              _Task, Evidence),
    get_dict(mode, Evidence, misconception),
    notation_render_json(place_value_writing_error(A, Op, B, R), Dict).

% carry_mark: the gate computes the dropped-carry answer (reusing the grammar's
% dropped_carry_answer/4) and the units carry digit; the notation compiler writes
% the dropped answer as role:deformation and the carry as a dropped superscript mark.
deformed_notation_scene(carry_mark(A, Op, B, R),
                        notation_error(carry_mark), Dict) :-
    deformation_spec_evidence(notation,
                              carry_mark(A, Op, B, R),
                              _Task, Evidence),
    get_dict(mode, Evidence, misconception),
    notation_render_json(carry_mark(A, Op, B, R), Dict).

% glyph_overwrite: the gate (representation_grammar.pl) admits the self-correction
% ONLY when the corrected value is still wrong. Read the struck/corrected values
% it computed and build the scene from the productive glyphs, re-inscribing the
% result slot with the over-digit(s) carrying the struck under-digit in ghost.
deformed_notation_scene(glyph_overwrite(A, Op, B, R, Struck, Corrected),
                        notation_error(glyph_overwrite), Dict) :-
    deformation_spec_evidence(notation,
                              glyph_overwrite(A, Op, B, R, Struck, Corrected),
                              _Task, Evidence),
    get_dict(mode, Evidence, misconception),
    get_dict(struck_value, Evidence, Struck),
    get_dict(corrected_value, Evidence, Corrected),
    overwrite_scene(A, Op, B, R, Struck, Corrected, Dict).


% mirror_spec(+CallerSpec, -GrammarSpec): accept either an explicit
% mirror_written(...) spec or a write_equation(...) spec, in which case choose
% the reversal-prone digit the operands contain. Parametric move: change the
% operands and the chosen digit changes.
mirror_spec(mirror_written(Digit, A, Op, B, R),
            mirror_written(Digit, A, Op, B, R)) :- !.
mirror_spec(write_equation(A, Op, B, R),
            mirror_written(Digit, A, Op, B, R)) :-
    reversal_prone_digit_in([A, B, R], Digit).

% reversal_prone_digit_in(+Numbers, -Digit): the first reversal-prone digit that
% appears in the operand/result list. Deterministic: one chosen digit per
% lesson's numbers.
reversal_prone_digit_in(Numbers, Digit) :-
    member(N, Numbers),
    integer(N),
    number_codes(N, Codes),
    member(C, Codes),
    char_code(Ch, C),
    atom_number(Ch, D),
    reversal_prone_digit(D),
    Digit = D,
    !.


% --- Layer 2 helper: build the transposition scene ---------------------------
%
% transposition_scene(+A, +Op, +B, +R, +WrongAnswer, -Dict): the productive
% A Op B = inscription with the transposed answer digits inscribed as
% role:deformation. Built on the compiler's productive JSON so the glyph
% geometry (baseline, pitch, layout) is the compiler's, not re-derived here.

transposition_scene(A, Op, B, R, WrongAnswer, Dict) :-
    notation_render_json(write_equation(A, Op, B, R), Base),
    get_dict(frames, Base, [Frame0]),
    get_dict(scene, Frame0, Scene0),
    get_dict(glyphs, Scene0, Glyphs0),
    replace_result_with_transposed(Glyphs0, WrongAnswer, Glyphs),
    Scene = Scene0.put(glyphs, Glyphs),
    format(string(Verb), "digit_transposition(~w,~w,~w,~w)", [A, Op, B, R]),
    format(string(Caption),
           "Digit transposition: ~w ~w ~w = ~w recorded as ~w.",
           [A, Op, B, R, WrongAnswer]),
    Frame = Frame0.put(_{ verb: Verb, caption: Caption, scene: Scene }),
    ( integer(WrongAnswer)
    -> atom_string(WrongAnswer, WrongAnswerStr)
    ;  term_string(WrongAnswer, WrongAnswerStr) ),
    Dict = Base.put(_{ frames: [Frame],
                       result: WrongAnswerStr }).

% replace_result_with_transposed(+Glyphs, +WrongAnswer, -Glyphs2): the result
% digits sit after the equals glyph. Drop them and inscribe the transposed
% answer's digits, marked role:deformation, at the same x slots.
replace_result_with_transposed(Glyphs0, WrongAnswer, Glyphs) :-
    split_at_equals(Glyphs0, Prefix, EqGlyph, ResultGlyphs),
    ResultGlyphs = [FirstResult | _],
    get_dict(x, FirstResult, StartX),
    get_dict(y, FirstResult, Y),
    get_dict(size, FirstResult, Size),
    pitch_between(Prefix, EqGlyph, Pitch),
    number_codes(WrongAnswer, WrongCodes),
    transposed_result_glyphs(WrongCodes, StartX, Pitch, Y, Size, NewResult),
    append3(Prefix, [EqGlyph], NewResult, Glyphs).

% split_at_equals(+Glyphs, -Prefix, -EqGlyph, -ResultGlyphs): partition the glyph
% row at the equals sign.
split_at_equals([G | Gs], [], G, Gs) :-
    get_dict(role, G, "equals"),
    !.
split_at_equals([G | Gs], [G | Prefix], EqGlyph, ResultGlyphs) :-
    split_at_equals(Gs, Prefix, EqGlyph, ResultGlyphs).

% pitch_between(+Prefix, +EqGlyph, -Pitch): recover the horizontal pitch from two
% adjacent glyph x slots, so the new result digits land on the same grid.
pitch_between(Prefix, EqGlyph, Pitch) :-
    ( append(_, [Last], Prefix), get_dict(x, Last, LX)
    -> get_dict(x, EqGlyph, EX), Pitch is EX - LX
    ;  Pitch = 24 ).

% transposed_result_glyphs(+Codes, +StartX, +Pitch, +Y, +Size, -Glyphs): inscribe
% the wrong-answer digits left to right from StartX, each role:deformation.
transposed_result_glyphs([], _, _, _, _, []).
transposed_result_glyphs([C | Cs], X, Pitch, Y, Size,
                         [G | Gs]) :-
    char_code(Ch, C),
    atom_string(Ch, ChStr),
    G = _{ x: X, y: Y, ch: ChStr, role: "deformation",
           size: Size, flip: "none", ghost: "none" },
    X1 is X + Pitch,
    transposed_result_glyphs(Cs, X1, Pitch, Y, Size, Gs).

append3(A, B, C, ABC) :-
    append(A, B, AB),
    append(AB, C, ABC).


% --- Layer 2 helper: build the glyph-overwrite scene -------------------------
%
% overwrite_scene(+A, +Op, +B, +R, +Struck, +Corrected, -Dict): the productive
% A Op B = inscription with the result slot re-inscribed as the over-digit(s)
% (ch: Corrected, role: deformation), each carrying the struck under-digit in
% ghost: Struck — the one field the drawer's overwrite branch reads. Built on the
% compiler's productive JSON so the glyph geometry is the compiler's.
overwrite_scene(A, Op, B, R, Struck, Corrected, Dict) :-
    notation_render_json(write_equation(A, Op, B, R), Base),
    get_dict(frames, Base, [Frame0]),
    get_dict(scene, Frame0, Scene0),
    get_dict(glyphs, Scene0, Glyphs0),
    overwrite_result_glyphs(Glyphs0, Struck, Corrected, Glyphs),
    Scene = Scene0.put(glyphs, Glyphs),
    format(string(Verb), "glyph_overwrite(~w,~w,~w,~w,~w,~w)",
           [A, Op, B, R, Struck, Corrected]),
    format(string(Caption),
           "Self-correction still wrong: ~w struck and rewritten as ~w in ~w ~w ~w = ~w.",
           [Struck, Corrected, A, Op, B, R]),
    Frame = Frame0.put(_{ verb: Verb, caption: Caption, scene: Scene }),
    ( integer(Corrected)
    -> atom_string(Corrected, CorrStr)
    ;  term_string(Corrected, CorrStr) ),
    Dict = Base.put(_{ frames: [Frame], result: CorrStr }).

% overwrite_result_glyphs(+Glyphs, +Struck, +Corrected, -Glyphs2): replace the
% result digits after the equals glyph with the corrected (over) digits, each
% marked role:deformation and carrying the matching struck digit in ghost.
overwrite_result_glyphs(Glyphs0, Struck, Corrected, Glyphs) :-
    split_at_equals(Glyphs0, Prefix, EqGlyph, ResultGlyphs),
    ResultGlyphs = [FirstResult | _],
    get_dict(x, FirstResult, StartX),
    get_dict(y, FirstResult, Y),
    get_dict(size, FirstResult, Size),
    pitch_between(Prefix, EqGlyph, Pitch),
    number_codes(Corrected, CorrCodes),
    number_codes(Struck, StruckCodes),
    overwrite_glyphs(CorrCodes, StruckCodes, StartX, Pitch, Y, Size, NewResult),
    append3(Prefix, [EqGlyph], NewResult, Glyphs).

% overwrite_glyphs(+CorrCodes, +StruckCodes, +X, +Pitch, +Y, +Size, -Glyphs):
% inscribe the corrected digits left to right; each pairs with the struck digit
% at the same position (ghost), or "none" once the struck value runs out.
overwrite_glyphs([], _, _, _, _, _, []).
overwrite_glyphs([C | Cs], StruckCodes, X, Pitch, Y, Size, [G | Gs]) :-
    char_code(Ch, C),
    atom_string(Ch, ChStr),
    ( StruckCodes = [SC | SRest]
    -> char_code(SCh, SC), atom_string(SCh, GhostStr)
    ;  SRest = [], GhostStr = "none" ),
    G = _{ x: X, y: Y, ch: ChStr, role: "deformation",
           size: Size, flip: "none", ghost: GhostStr },
    X1 is X + Pitch,
    overwrite_glyphs(Cs, SRest, X1, Pitch, Y, Size, Gs).


% --- Layer 3: replication (the same deformation across operand sets) ---------
%
% replicate_notation_deformation(+notation_error(Type), +ListOfArgs, -FramesList):
% render the SAME deformation across a list of operand sets. Each element of
% ListOfArgs is a [A, Op, B, R] list. FramesList is a list of Args-FramesDict
% pairs. Across the list the deformation rule is constant; only which glyph is
% inscribed/flipped changes — the notation cousin of the partition layer's
% count-field-only invariant.

replicate_notation_deformation(notation_error(Type), ListOfArgs, FramesList) :-
    findall(Args-Dict,
            ( member(Args, ListOfArgs),
              args_spec(Type, Args, Spec),
              deformed_notation_scene(Spec, notation_error(Type), Dict) ),
            FramesList).

% args_spec(+Type, +Args, -Spec): turn a [A, Op, B, R] operand list into the
% caller spec each error type expects.
args_spec(mirror_written_numeral, [A, Op, B, R], write_equation(A, Op, B, R)).
args_spec(digit_transposition, [A, Op, B, R], digit_transposition(A, Op, B, R)).
args_spec(operational_equals_chain, [A, Op, B, R],
          operational_equals_chain(A, Op, B, R)).
args_spec(place_value_writing_error, [A, Op, B, R],
          place_value_writing_error(A, Op, B, R)).
args_spec(carry_mark, [A, Op, B, R], carry_mark(A, Op, B, R)).
args_spec(glyph_overwrite, [A, Op, B, R, Struck, Corrected],
          glyph_overwrite(A, Op, B, R, Struck, Corrected)).


% --- Provenance: the honesty boundary, queryable -----------------------------
%
% notation_deformation_evidence(+notation_error(Type), -Provenance): the
% provenance (corpus_attested | literature_only) the grammar's Evidence dict
% carries for this error type. Drawn from the gate by probing a representative
% spec, not hard-coded here, so the boundary stays in one place (the grammar).

notation_deformation_evidence(notation_error(Type), Provenance) :-
    representative_spec(Type, Spec),
    deformation_spec_evidence(notation, Spec, _Task, Evidence),
    get_dict(provenance, Evidence, Provenance),
    !.

% representative_spec(+Type, -Spec): a spec that satisfies the gate for Type, used
% only to read the provenance flag off the Evidence dict.
representative_spec(mirror_written_numeral, mirror_written(3, 3, '+', 2, 5)).
representative_spec(operational_equals_chain,
                    operational_equals_chain(2, '+', 3, 5)).
representative_spec(digit_transposition, digit_transposition(8, '+', 4, 12)).
representative_spec(place_value_writing_error,
                    place_value_writing_error(8, '+', 4, 12)).
representative_spec(carry_mark, carry_mark(8, '+', 4, 12)).
representative_spec(glyph_overwrite, glyph_overwrite(3, '+', 2, 5, 4, 6)).
