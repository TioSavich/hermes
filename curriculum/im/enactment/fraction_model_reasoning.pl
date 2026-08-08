/** <module> Reference lane — fraction_model_reasoning
 *
 * The worked example for `curriculum/im/lesson_enactment.pl`. It carries one
 * form end to end so the breadth lanes have something to copy rather than a
 * contract to interpret. `fraction_model_reasoning` is not a lane this wave
 * (Tio's 2026-08-01 ruling puts fractions last), which is why the reference
 * lives here: it demonstrates the contract without claiming a lane's ground.
 *
 * ## The form
 *
 * `unit_fraction_partition`. Three lessons in this subclass ask a
 * class to take a strip that represents 1 and partition it into parts the task
 * names in words rather than in numerals: halves, thirds, tenths, twelfths.
 * The numeral extractor that feeds the arithmetic rung reads numerals, so it
 * read nothing here; that is why IM-G4-U2-L4 sits in
 * `not_enacted_by_measured_inventory` while its task statement prints its own
 * operands in plain sight.
 *
 * The doing is a partition and a labelling, not a computation. The enactment
 * opens the cited guide file, reads the part-words out of a bounded window at
 * the cited line, partitions a strip once per word, labels every part with its
 * unit fraction, and routes the result to the existing fraction-bars renderer.
 *
 * ## Two things a lane should copy
 *
 * 1. The operands come from the curriculum file at run time. `enactment_passes/4`
 *    opens `curriculum/im_teacher_guides/...` at the line the evidence cites and
 *    reads the words there. That is what earns `input_provenance: curriculum`.
 *    A lane whose lesson defers its numbers to the room ("measure your desk")
 *    supplies them itself and says `machine_supplied`.
 *
 * 2. The artifact reuses `render(fraction_bars_scene)` rather than drawing
 *    anything new. One `fraction_render_json/4` call per part-word, the frames
 *    concatenated and renumbered under one canvas, so the filmstrip runs
 *    through the strips in the order the task lists them.
 */

:- module(enactment_fraction_model_reasoning, []).

:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(readutil), [read_line_to_string/2]).
:- use_module(im_lessons(lesson_enactment), []).
:- use_module(render(fraction_bars_scene), [ fraction_render_json/4 ]).

:- multifile
       lesson_enactment:enactment_form/3,
       lesson_enactment:lesson_enactment_form/3,
       lesson_enactment:enactment_move/3,
       lesson_enactment:enactment_lane/2,
       lesson_enactment:enactment_verb/4,
       lesson_enactment:enactment_passes/4,
       lesson_enactment:enactment_artifact/5,
       lesson_enactment:enactment_disclaimer/2,
       lesson_enactment:enactment_input_provenance/3,
       lesson_enactment:lesson_enactment_refusal/2.


%% ======================================================================
%% The form
%% ======================================================================

lesson_enactment:enactment_lane(unit_fraction_partition,
                                fraction_model_reasoning).

lesson_enactment:enactment_form(
    unit_fraction_partition,
    'Partition a strip that represents 1 into the equal parts a task names in \c
     words, and label every part with its unit fraction.',
    warrant('IM-G4-U2-L4',
            'curriculum/im_teacher_guides/grade4/unit2/lesson4.md',
            196,
            'Use one blank strip to show tenths.')).

lesson_enactment:enactment_disclaimer(
    unit_fraction_partition,
    'The machine partitions a strip model and labels every part with its unit \c
     fraction; no paper was folded, and the row says nothing about how a \c
     student would partition the strip or what a class would say about it.').

lesson_enactment:enactment_input_provenance(
    unit_fraction_partition, Lesson, curriculum) :-
    partition_span(Lesson, _, _, _, _).


%% ======================================================================
%% The moves
%% ======================================================================

lesson_enactment:enactment_move(unit_fraction_partition, 1,
    move(establish_referent_whole, const(strip))).
lesson_enactment:enactment_move(unit_fraction_partition, 2,
    move(read_named_partition_count, input(part_word))).
lesson_enactment:enactment_move(unit_fraction_partition, 3,
    move(partition_into_equal_parts, prior)).
lesson_enactment:enactment_move(unit_fraction_partition, 4,
    move(label_each_part_with_its_unit_fraction, prior)).


%% ======================================================================
%% The verbs. Each one runs; none of them stores a string.
%% ======================================================================

lesson_enactment:enactment_verb(unit_fraction_partition,
                                establish_referent_whole, Kind,
                                referent_whole(Kind, 1)) :-
    atom(Kind).

lesson_enactment:enactment_verb(unit_fraction_partition,
                                read_named_partition_count, Word, Count) :-
    partition_word(Word, Count).

% Build the parts and check that they exhaust the whole before naming the unit
% fraction. The result term stays compact so the step label a reader meets says
% what was partitioned rather than reciting every piece; the parts themselves
% are rebuilt by the artifact, from the same predicate.
lesson_enactment:enactment_verb(unit_fraction_partition,
                                partition_into_equal_parts, Count,
                                equal_parts(Count, fraction(1, Count))) :-
    equal_parts_of_whole(Count, Parts),
    length(Parts, Count).

% Label every part, then check that every label names the unit fraction. A
% partition whose parts do not all carry 1/Count is not the doing this task
% asks for, so the verb fails rather than emitting a mixed strip.
lesson_enactment:enactment_verb(unit_fraction_partition,
                                label_each_part_with_its_unit_fraction,
                                equal_parts(Count, fraction(1, Count)),
                                labelled_parts(Count, Label)) :-
    part_labels(Count, Labels),
    length(Labels, Count),
    sort(Labels, [Label]).

%!  equal_parts_of_whole(+Count, -Parts) is semidet.
%
%   Count parts of one whole, each of them 1/Count, checked to exhaust it.
%   The check adds numerators over the shared denominator and compares two
%   integers. Summing 1/Count as division would compare floats, and ten tenths
%   do not add to 1.0 in binary floating point; the repo has been bitten by
%   exactly that comparison before.
equal_parts_of_whole(Count, Parts) :-
    integer(Count), Count >= 2,
    numlist(1, Count, Positions),
    findall(part(P, fraction(1, Count)), member(P, Positions), Parts),
    aggregate_all(sum(N), member(part(_, fraction(N, _)), Parts), Numerator),
    Numerator =:= Count.

%!  part_labels(+Count, -Labels) is semidet.
part_labels(Count, Labels) :-
    equal_parts_of_whole(Count, Parts),
    findall(Text,
            ( member(part(_, fraction(N, D)), Parts),
              format(atom(Text), '~w/~w', [N, D])
            ),
            Labels).

%!  partition_word(?Word, ?Count) is nondet.
%
%   The ordinary English names for equal parts of one whole, as the IM student
%   task statements in this subclass print them. The table stops at the words
%   these lessons use; a word outside it makes the second move fail, which is
%   what turns an unread task statement into a partial verdict rather than a
%   guessed denominator.
partition_word(halves, 2).
partition_word(thirds, 3).
partition_word(fourths, 4).
partition_word(fifths, 5).
partition_word(sixths, 6).
partition_word(sevenths, 7).
partition_word(eighths, 8).
partition_word(ninths, 9).
partition_word(tenths, 10).
partition_word(twelfths, 12).


%% ======================================================================
%% The lessons, each cited to a line of its own guide file
%% ======================================================================

%!  partition_span(?Lesson, ?Source, ?Line, ?Window, ?Verbatim) is nondet.
%
%   Line is where the task statement names its parts; Verbatim is a string that
%   occurs on that line in the tracked guide, and the gate checks it. Window is
%   how many lines the part-words run across, kept tight because the guides are
%   two-column PDF conversions and the launch column shares every line.
partition_span('IM-G3-U5-L2',
               'curriculum/im_teacher_guides/grade3/unit5/lesson2.md',
               254, 3,
               'Partition each rectangle into halves, thirds,').
partition_span('IM-G4-U2-L1',
               'curriculum/im_teacher_guides/grade4/unit2/lesson1.md',
               172, 2,
               'Use the strips to represent halves, fourths, and').
partition_span('IM-G4-U2-L4',
               'curriculum/im_teacher_guides/grade4/unit2/lesson4.md',
               196, 6,
               'Use one blank strip to show tenths.').

lesson_enactment:lesson_enactment_form(Lesson,
                                       unit_fraction_partition,
                                       evidence(Source, Line, Verbatim)) :-
    partition_span(Lesson, Source, Line, _, Verbatim).


%% ======================================================================
%% The passes: one per part-word the guide prints
%% ======================================================================

lesson_enactment:enactment_passes(unit_fraction_partition,
                                  Lesson, _Inputs, Passes) :-
    partition_span(Lesson, Source, Line, Window, _),
    guide_window_words(Source, Line, Window, Words),
    Words \== [],
    findall(pass(Word, [part_word-Word]), member(Word, Words), Passes).

%!  guide_window_words(+Source, +Line, +Window, -Words) is det.
%
%   Read the tracked guide file over the lines [Line, Line+Window), and return
%   the part-words it prints, in first-occurrence order and without repeats.
guide_window_words(Source, Line, Window, Words) :-
    repo_path(Source, Path),
    End is Line + Window - 1,
    read_line_range(Path, Line, End, Lines),
    atomic_list_concat(Lines, ' ', Blob),
    findall(Word-Position,
            ( partition_word(Word, _),
              sub_atom(Blob, Position, _, _, Word)
            ),
            Hits0),
    keysort_by_position(Hits0, Words).

keysort_by_position(Hits, Words) :-
    findall(Position-Word, member(Word-Position, Hits), Pairs0),
    msort(Pairs0, Pairs),
    findall(W, member(_-W, Pairs), Ws),
    first_occurrences(Ws, [], Words).

first_occurrences([], _, []).
first_occurrences([W | Rest], Seen, Out) :-
    (   memberchk(W, Seen)
    ->  first_occurrences(Rest, Seen, Out)
    ;   Out = [W | More],
        first_occurrences(Rest, [W | Seen], More)
    ).

read_line_range(Path, From, To, Lines) :-
    setup_call_cleanup(
        open(Path, read, Stream, [encoding(utf8)]),
        collect_lines(Stream, 1, From, To, Lines),
        close(Stream)).

collect_lines(Stream, N, From, To, Lines) :-
    (   N > To
    ->  Lines = []
    ;   read_line_to_string(Stream, Line),
        (   Line == end_of_file
        ->  Lines = []
        ;   N1 is N + 1,
            (   N >= From
            ->  Lines = [Line | More]
            ;   Lines = More
            ),
            collect_lines(Stream, N1, From, To, More)
        )
    ).

%!  repo_path(+Relative, -Absolute) is det.
repo_path(Relative, Absolute) :-
    module_property(enactment_fraction_model_reasoning, file(Self)),
    file_directory_name(Self, EnactmentDir),   % curriculum/im/enactment
    file_directory_name(EnactmentDir, ImDir),  % curriculum/im
    file_directory_name(ImDir, CurriculumDir), % curriculum
    file_directory_name(CurriculumDir, Root),
    atomic_list_concat([Root, Relative], '/', Absolute).


%% ======================================================================
%% The artifact: an existing renderer, once per part-word
%% ======================================================================

lesson_enactment:enactment_artifact(unit_fraction_partition,
                                    _Lesson, Passes, _Steps,
                                    scene(fraction_bars,
                                          partition_filmstrip(Counts),
                                          Document)) :-
    findall(Count,
            ( member(pass(Word, _), Passes),
              partition_word(Word, Count)
            ),
            Counts),
    Counts \== [],
    partition_filmstrip(Passes, Frames, Canvas),
    Frames \== [],
    findall(Text,
            ( member(Count, Counts),
              format(atom(Text), '1/~w', [Count])
            ),
            UnitFractions),
    atomic_list_concat(UnitFractions, ', ', ResultAtom),
    atom_string(ResultAtom, ResultStr),
    Document = _{
        kind: "productive",
        request: _{
            renderer: "fraction_bars_scene",
            call: "fraction_render_json/4",
            kind: "unit_fraction_partition",
            bases: Counts
        },
        result: ResultStr,
        canvas: Canvas,
        frames: Frames
    }.

%!  partition_filmstrip(+Passes, -Frames, -Canvas) is semidet.
%
%   One `fraction_render_json/4` document per part-word, their frames laid end
%   to end under one canvas and renumbered so the filmstrip runs straight
%   through. Each caption gains the word the task printed, so a reader knows
%   which strip a frame belongs to.
partition_filmstrip(Passes, Frames, Canvas) :-
    findall(Word-Document,
            ( member(pass(Word, _), Passes),
              partition_word(Word, Count),
              fraction_render_json(unit_fraction_partition, 1, Count, Document)
            ),
            Documents),
    Documents = [_-First | _],
    get_dict(canvas, First, Canvas),
    concat_frames(Documents, 1, Frames).

concat_frames([], _, []).
concat_frames([Word-Document | Rest], Index0, Frames) :-
    (   get_dict(frames, Document, Own)
    ->  true
    ;   Own = []
    ),
    renumber_frames(Own, Word, Index0, Index1, Head),
    concat_frames(Rest, Index1, Tail),
    append(Head, Tail, Frames).

renumber_frames([], _, Index, Index, []).
renumber_frames([Frame0 | Rest], Word, Index0, Index, [Frame | More]) :-
    (   get_dict(caption, Frame0, Caption0)
    ->  format(string(Caption), "~w: ~w", [Word, Caption0])
    ;   format(string(Caption), "~w", [Word])
    ),
    Frame = Frame0.put(_{step: Index0, caption: Caption}),
    Index1 is Index0 + 1,
    renumber_frames(Rest, Word, Index1, Index, More).
