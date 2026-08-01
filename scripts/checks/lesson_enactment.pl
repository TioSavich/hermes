/** <module> Gate for the lesson-enactment contract
 *
 * Runs every enactment every lane declares and refuses the ones that only look
 * like enactments. Thirteen checks, each of which has failed somewhere in this
 * repo's history in one form or another:
 *
 *   1  every form declares a lane, a gloss, a warrant, and a disclaimer
 *   2  a warrant's span text occurs in the tracked guide where it is cited
 *   3  a lesson's evidence span occurs in the tracked guide where it is cited
 *   4  move indices run 1..N with no gap and no repeat
 *   5  every declared move's verb is backed by a doing: an enactment_verb/4
 *      clause, or a step the lane's own runner emitted under that verb
 *   6  every emitted step verb is a move its form declared
 *   7  every declared lesson enacts, or carries a refusal naming its machine
 *   8  every enactment serializes through the strategy-trace seam intact
 *   9  the seam rewrite does not read a step index as a state label
 *  10  every emitted row carries the fields a page builder needs, filled
 *  11  every declared lesson belongs to the population, and any lesson a lane
 *      picks up from another lane's subclass is named
 *  12  a lesson yields exactly as many enactments as it declares forms
 *  13  the contract rules no lesson yet exercises, run on constructed terms
 *
 * The lanes are discovered by the same glob the census driver uses, so a lane
 * that lands is checked by the same run that counts it.
 *
 * Checks 5 and 6 are the pair that keeps the rung honest, running the "a name
 * is not a doing" rule in both directions. A form that declares
 * `move(sort_by_attribute, input(shapes))` with no clause and no step that ran
 * it has stored a name where a doing belongs; a machine that emits a step verb
 * no move declares has run a doing the lane never named.
 *
 * Check 9 guards a silent corruption. `hermes/encyclopedia.pl` recognizes a
 * legacy four-place history step as `step(State, _, _, Interp)`, so handing it
 * a raw `step(Index, Verb, Operand, Result)` list yields step dicts whose label
 * is the index. No error, no warning, just a display of numbers. The check
 * refuses a numeric label.
 *
 * Run: swipl -q -l paths.pl -s scripts/checks/lesson_enactment.pl -g main -t halt
 */

% Load order matters here. `hermes(encyclopedia)` reaches
% `misconceptions(test_harness)`, which does `user:ensure_loaded(formal(load))`,
% and that file imports utils:select/3 into `user`. Importing library(lists)
% into `user` first makes that import a permission error. Loading the
% encyclopedia before anything claims select/3, and leaving list and apply
% predicates to autoload, keeps this check's load silent.
:- use_module(hermes(encyclopedia), []).
:- use_module(library(http/json)).
:- use_module(library(readutil), [read_line_to_string/2]).

% Nothing is imported from either. The contract's names in `user` are in reach
% of any lane that calls an unqualified predicate it does not define, and the
% lanes must be loaded the way the census loads them or the gate would be
% checking a different program.
:- use_module(im_lessons(lesson_enactment), []).

main :-
    load_lanes(LaneCount),
    format("lesson_enactment: ~w lane module(s) loaded from \c
            curriculum/im/enactment/~n", [LaneCount]),
    repo_root(Root),
    load_population(Root, Population),
    Checks = [ check_form_declarations,
               check_form_warrants(Root),
               check_lesson_evidence(Root),
               check_move_indices,
               check_verbs_are_executable,
               check_emitted_verbs_are_declared,
               check_lessons_enact,
               check_trace_seam,
               check_seam_rewrite,
               check_emitted_rows,
               check_population_membership(Population),
               check_solutions_are_confined,
               check_contract_rules
             ],
    foldl(run_check, Checks, 0, Failures),
    (   Failures =:= 0
    ->  format("lesson_enactment: 13 checks PASS~n")
    ;   format(user_error, "lesson_enactment: ~w check(s) FAILED~n", [Failures]),
        halt(1)
    ).

%!  load_lanes(-Count) is det.
%
%   The same glob the census driver uses: every `.pl` directly in
%   `curriculum/im/enactment/`. Naming the lanes here instead would let a lane
%   land, be counted by the census, and never be checked.
load_lanes(Count) :-
    repo_root(Root),
    atomic_list_concat([Root, 'curriculum/im/enactment/*.pl'], '/', Pattern),
    expand_file_name(Pattern, Files),
    findall(F,
            ( member(F, Files),
              catch(user:use_module(F, []), E,
                    ( print_message(error, E), fail ))
            ),
            Loaded),
    length(Loaded, Count),
    length(Files, Count).

run_check(Goal, In, Out) :-
    (   catch(call(Goal), E,
              ( message_to_codes(E, Text),
                format(user_error, "check threw: ~w~n", [Text]), fail ))
    ->  Out = In
    ;   Out is In + 1
    ).

message_to_codes(E, Text) :-
    message_to_text(E, Text).
message_to_text(E, Text) :-
    term_string(E, Text).


%% ----------------------------------------------------------------------
%% 1. Declarations
%% ----------------------------------------------------------------------

check_form_declarations :-
    findall(F, lesson_enactment:enactment_form(F, _, _), Forms0),
    sort(Forms0, Forms),
    Forms \== [],
    findall(Problem,
            ( member(Form, Forms),
              form_declaration_problem(Form, Problem)
            ),
            Problems),
    (   Problems == []
    ->  length(Forms, N),
        format("lesson_enactment: ~w form(s) declare lane, gloss, warrant, \c
                and disclaimer: PASS~n", [N])
    ;   forall(member(P, Problems),
               format(user_error, "  form declaration: ~w~n", [P])),
        fail
    ).

form_declaration_problem(Form, Problem) :-
    \+ lesson_enactment:enactment_lane(Form, _),
    format(atom(Problem), '~w declares no lane', [Form]).
form_declaration_problem(Form, Problem) :-
    lesson_enactment:enactment_form(Form, Gloss, _),
    ( Gloss == '' ; Gloss == "" ),
    format(atom(Problem), '~w has an empty gloss', [Form]).
form_declaration_problem(Form, Problem) :-
    \+ ( lesson_enactment:enactment_form(Form, _, warrant(_, _, _, _)) ),
    format(atom(Problem), '~w has no warrant(Lesson, Source, Line, Text)', [Form]).
form_declaration_problem(Form, Problem) :-
    \+ ( lesson_enactment:enactment_disclaimer(Form, S), S \== '' ),
    format(atom(Problem),
           '~w declares no sentence about what it does not claim', [Form]).


%% ----------------------------------------------------------------------
%% 2 and 3. Cited spans, checked against the live tree
%% ----------------------------------------------------------------------

check_form_warrants(Root) :-
    findall(Form-Source-Line-Text,
            lesson_enactment:enactment_form(Form, _,
                                            warrant(_, Source, Line, Text)),
            Warrants),
    check_spans(Root, Warrants, "form warrant").

check_lesson_evidence(Root) :-
    findall(Lesson-Source-Line-Text,
            lesson_enactment:lesson_enactment_form(Lesson, _,
                                                   evidence(Source, Line, Text)),
            Spans),
    check_spans(Root, Spans, "lesson evidence").

%!  check_spans(+Root, +Spans, +Label) is semidet.
%
%   Two readings of "the guide prints this", because the guides are two-column
%   PDF extracts and the lanes cite them two ways.
%
%   A span that sits on one physical line is checked verbatim against that line,
%   whitespace collapsed. That is the strict reading and many spans meet it.
%
%   A span reconstructed from a task statement running across several physical
%   lines cannot meet it, because the extraction interleaves the launch column
%   with the student column and no single line carries the sentence. Those are
%   checked the way the geometry lane's own gate checks them: at least half the
%   span's content words occur in the window from three lines before the cite to
%   forty lines after. Requiring the strict reading of them would force a lane
%   to cite a fragment rather than a sentence, which reads worse and checks no
%   better.
%
%   Both counts are printed, so a lane drifting from verbatim citation toward
%   windowed citation shows up as a number moving rather than as nothing.
check_spans(Root, Spans, Label) :-
    findall(Problem,
            ( member(Owner-Source-Line-Text, Spans),
              \+ span_present(Root, Source, Line, Text, _),
              format(atom(Problem),
                     '~w cites ~w:~w for "~w", which the guide does not print \c
                      at or near that line', [Owner, Source, Line, Text])
            ),
            Problems),
    (   Problems == []
    ->  length(Spans, N),
        findall(x, ( member(_-S-L-T, Spans),
                     span_present(Root, S, L, T, verbatim) ), Exact),
        length(Exact, E),
        Windowed is N - E,
        format("lesson_enactment: ~w ~s span(s) occur where cited, ~w verbatim \c
                on the line and ~w in the window around it: PASS~n",
               [N, Label, E, Windowed])
    ;   forall(member(P, Problems),
               format(user_error, "  ~s: ~w~n", [Label, P])),
        fail
    ).

span_present(Root, Source, Line, Text, How) :-
    atomic_list_concat([Root, Source], '/', Path),
    exists_file(Path),
    (   nth_line(Path, Line, Content),
        collapse_spaces(Content, Collapsed),
        collapse_spaces(Text, Wanted),
        sub_string(Collapsed, _, _, _, Wanted)
    ->  How = verbatim
    ;   span_window(Path, Line, Window),
        content_words(Text, Wanted0), Wanted0 \== [],
        content_words(Window, Found),
        intersection(Wanted0, Found, Shared),
        length(Wanted0, Total), length(Shared, Hits),
        Hits * 2 >= Total,
        How = windowed
    ).

%!  span_window(+Path, +Line, -Window) is det.
%
%   Three lines before the cite through forty after, joined. The same window the
%   geometry lane's gate reads, so the two gates agree about what "near the
%   cited line" means.
span_window(Path, Line, Window) :-
    From is max(1, Line - 3),
    To is Line + 40,
    setup_call_cleanup(
        open(Path, read, Stream, [encoding(utf8)]),
        collect_range(Stream, 1, From, To, Lines),
        close(Stream)),
    atomic_list_concat(Lines, ' ', Window).

collect_range(Stream, N, From, To, Lines) :-
    (   N > To
    ->  Lines = []
    ;   read_line_to_string(Stream, Line),
        (   Line == end_of_file
        ->  Lines = []
        ;   N1 is N + 1,
            ( N >= From -> Lines = [Line | More] ; Lines = More ),
            collect_range(Stream, N1, From, To, More)
        )
    ).

%!  content_words(+Text, -Words) is det.
%
%   Lower-case alphanumeric runs, minus the closed-class words that match
%   anything. The stop list is the geometry gate's.
content_words(Text, Words) :-
    atom_string(Text, S),
    string_lower(S, Lower),
    split_string(Lower, " \t\n\r.,;:!?\"'()[]{}/\\-_*", "", Parts0),
    findall(W,
            ( member(P, Parts0), P \== "",
              \+ span_stopword(P),
              atom_string(W, P)
            ),
            Words0),
    sort(Words0, Words).

span_stopword(W) :-
    memberchk(W, ["the", "a", "an", "and", "or", "of", "to", "in", "is", "are",
                  "your", "you", "each", "that", "this", "with", "for", "it",
                  "be", "on", "how", "what", "then", "1", "2", "3", "4", "5",
                  "do", "will", "can", "if"]).

collapse_spaces(Text, Collapsed) :-
    atom_string(Text, S),
    split_string(S, " \t\n\r", " \t\n\r", Parts0),
    findall(P, ( member(P, Parts0), P \== "" ), Parts),
    atomic_list_concat(Parts, ' ', Atom),
    atom_string(Atom, Collapsed).

nth_line(Path, N, Line) :-
    setup_call_cleanup(
        open(Path, read, Stream, [encoding(utf8)]),
        seek_line(Stream, 1, N, Line),
        close(Stream)).

seek_line(Stream, N, N, Line) :- !,
    read_line_to_string(Stream, Line0),
    Line0 \== end_of_file,
    Line = Line0.
seek_line(Stream, I, N, Line) :-
    read_line_to_string(Stream, L),
    L \== end_of_file,
    I1 is I + 1,
    seek_line(Stream, I1, N, Line).


%% ----------------------------------------------------------------------
%% 4. Move indices
%% ----------------------------------------------------------------------

check_move_indices :-
    findall(F, lesson_enactment:enactment_form(F, _, _), Forms0),
    sort(Forms0, Forms),
    findall(Problem,
            ( member(Form, Forms),
              findall(I, lesson_enactment:enactment_move(Form, I, _), Is),
              msort(Is, Sorted),
              length(Sorted, N),
              numlist(1, N, Expected),
              (   N =:= 0
              ->  format(atom(Problem), '~w declares no move', [Form])
              ;   Sorted \== Expected
              ->  format(atom(Problem),
                         '~w has move indices ~w, expected 1..~w',
                         [Form, Sorted, N])
              ;   fail
              )
            ),
            Problems),
    (   Problems == []
    ->  aggregate_all(count, lesson_enactment:enactment_move(_, _, _), Total),
        length(Forms, FormCount),
        format("lesson_enactment: ~w move(s) across ~w form(s) index 1..N: \c
                PASS~n", [Total, FormCount])
    ;   forall(member(P, Problems),
               format(user_error, "  move indices: ~w~n", [P])),
        fail
    ).


%% ----------------------------------------------------------------------
%% 5. A name is not a doing
%% ----------------------------------------------------------------------

%!  check_verbs_are_executable is semidet.
%
%   Every declared move names a verb that ran. Two routes reach the rung and
%   the check reads both, because the same commitment is kept two ways.
%
%   A lane on the generic route declares `enactment_verb/4` and the clause is
%   the doing; the check finds it by `clause/2`. A lane on the lane route runs
%   its own move sequence, so the doing shows up as a step the machines emitted
%   under that verb, and the check finds it there. Either way the verb is
%   backed. A verb with neither is a name where a doing belongs, and that is
%   the thing this refuses.
%
%   Reading only the first route would have passed 1 form of 40 and failed the
%   other 39 for taking a route the contract offers.
check_verbs_are_executable :-
    findall(Form-Verb,
            ( lesson_enactment:enactment_move(Form, _, Move),
              lesson_enactment:enactment_move_verb(Move, Verb)
            ),
            Pairs0),
    sort(Pairs0, Pairs),
    emitted_verbs(Emitted),
    findall(Problem,
            ( member(Form-Verb, Pairs),
              \+ verb_has_clause(Form, Verb),
              \+ memberchk(Form-Verb, Emitted),
              format(atom(Problem),
                     '~w declares move ~w with no enactment_verb/4 clause and \c
                      no step that ran it; that is a name where a doing belongs',
                     [Form, Verb])
            ),
            Problems),
    (   Problems == []
    ->  length(Pairs, N),
        findall(P, ( member(P, Pairs), P = F-V, verb_has_clause(F, V) ), Clauses),
        length(Clauses, C),
        Ran is N - C,
        format("lesson_enactment: ~w declared verb(s) are backed by a doing, \c
                ~w by an enactment_verb/4 clause and ~w by a step that ran: \c
                PASS~n", [N, C, Ran])
    ;   forall(member(P, Problems),
               format(user_error, "  verb: ~w~n", [P])),
        fail
    ).

verb_has_clause(Form, Verb) :-
    Head = lesson_enactment:enactment_verb(Form, Verb, _, _),
    catch(clause(Head, _), _, fail), !.

%!  emitted_verbs(-Pairs) is det.
%
%   Form-Verb for every step the machines actually emitted, sorted.
emitted_verbs(Pairs) :-
    findall(Form-Verb,
            ( lesson_enactment:enactment_declared_lessons(Lessons),
              member(Lesson, Lessons),
              lesson_enactment:enact_lesson(Lesson, E),
              E = enactment(_, Form, _, Steps, _),
              member(step(_, Verb, _, _), Steps)
            ),
            Pairs0),
    sort(Pairs0, Pairs).


%% ----------------------------------------------------------------------
%% 6. Every emitted step verb is a move its form declared
%% ----------------------------------------------------------------------

check_emitted_verbs_are_declared :-
    lesson_enactment:enactment_move_check(Report),
    get_dict(steps_checked, Report, Checked),
    get_dict(undeclared, Report, Undeclared),
    get_dict(index_mismatched, Report, Mismatched),
    (   Undeclared =:= 0
    ->  format("lesson_enactment: ~w emitted step verb(s) are declared moves \c
                of their form, ~w undeclared, ~w off their move index: PASS~n",
               [Checked, Undeclared, Mismatched])
    ;   get_dict(undeclared_verbs, Report, Names),
        forall(member(Form-Verb, Names),
               format(user_error,
                      "  emitted verb: ~w ran ~w, which no move of that form \c
                       declares~n", [Form, Verb])),
        fail
    ).


%% ----------------------------------------------------------------------
%% 6. Every declared lesson enacts or refuses with a named machine
%% ----------------------------------------------------------------------

check_lessons_enact :-
    lesson_enactment:enactment_declared_lessons(Lessons),
    Lessons \== [],
    findall(Problem,
            ( member(Lesson, Lessons),
              \+ lesson_enactment:enact_lesson(Lesson, _),
              \+ ( lesson_enactment:lesson_enactment_refusal(Lesson, M),
                   M \== '' ),
              format(atom(Problem),
                     '~w is declared but neither enacts nor names the machine \c
                      it would need', [Lesson])
            ),
            Problems),
    (   Problems == []
    ->  findall(L, ( member(L, Lessons),
                     once(lesson_enactment:enact_lesson(L, _)) ), Ran),
        length(Ran, R), length(Lessons, N),
        format("lesson_enactment: ~w of ~w declared lesson(s) enact, the rest \c
                name their machine: PASS~n", [R, N])
    ;   forall(member(P, Problems),
               format(user_error, "  lesson: ~w~n", [P])),
        fail
    ).


%% ----------------------------------------------------------------------
%% 7. The trace seam
%% ----------------------------------------------------------------------

check_trace_seam :-
    lesson_enactment:enactment_declared_lessons(Lessons),
    findall(Problem,
            ( member(Lesson, Lessons),
              lesson_enactment:enact_lesson(Lesson, E),
              seam_problem(Lesson, E, Problem)
            ),
            Problems),
    (   Problems == []
    ->  format("lesson_enactment: every enactment serializes through \c
                hermes_encyclopedia:history_steps/2 with its step count \c
                intact: PASS~n")
    ;   forall(member(P, Problems),
               format(user_error, "  trace seam: ~w~n", [P])),
        fail
    ).

seam_problem(Lesson, E, Problem) :-
    E = enactment(_, _, _, Steps, _),
    length(Steps, N),
    (   \+ catch(lesson_enactment:enactment_trace_dict(E, _), _, fail)
    ->  format(atom(Problem), '~w produced no trace dict', [Lesson])
    ;   lesson_enactment:enactment_trace_dict(E, Dict),
        (   \+ ( get_dict(steps, Dict, S), length(S, N) )
        ->  format(atom(Problem),
                   '~w has ~w step(s) but its trace dict carries a different \c
                    number', [Lesson, N])
        ;   \+ ( get_dict(steps, Dict, S2),
                 forall(member(Row, S2),
                        ( get_dict(n, Row, _),
                          get_dict(label, Row, _),
                          get_dict(value, Row, _) )) )
        ->  format(atom(Problem),
                   '~w has a step row missing the n/label/value keys the \c
                    strategy display reads', [Lesson])
        ;   \+ ( get_dict(jumps, Dict, _),
                 get_dict(jump_witness, Dict, _),
                 get_dict(ok, Dict, _),
                 get_dict(result, Dict, _),
                 get_dict(note, Dict, _),
                 get_dict(strategy, Dict, _),
                 get_dict(representation, Dict, _) )
        ->  format(atom(Problem),
                   '~w is missing a key strategy_trace_dict/3 always returns',
                   [Lesson])
        ;   fail
        )
    ).


%% ----------------------------------------------------------------------
%% 9. The seam rewrite, and the corruption it exists to prevent
%% ----------------------------------------------------------------------

check_seam_rewrite :-
    lesson_enactment:enactment_declared_lessons(Lessons),
    findall(Problem,
            ( member(Lesson, Lessons),
              lesson_enactment:enact_lesson(Lesson, E),
              rewrite_problem(Lesson, E, Problem)
            ),
            Problems),
    (   Problems == []
    ->  demonstrate_raw_corruption(Shape),
        format("lesson_enactment: the seam rewrite keeps every label a verb \c
                term; the raw step list would have produced ~w: PASS~n",
               [Shape])
    ;   forall(member(P, Problems),
               format(user_error, "  seam rewrite: ~w~n", [P])),
        fail
    ).

rewrite_problem(Lesson, enactment(_, _, _, Steps, _), Problem) :-
    lesson_enactment:enactment_steps_history(Steps, History),
    hermes_encyclopedia:history_steps(History, Rows),
    member(Row, Rows),
    get_dict(label, Row, Label),
    (   number(Label)
    ;   atom_number(Label, _)
    ;   string(Label), number_string(_, Label)
    ),
    format(atom(Problem),
           '~w serialized a step whose label is the number ~w, which is what \c
            handing the raw step list to history_steps/2 looks like',
           [Lesson, Label]).

%!  demonstrate_raw_corruption(-Shape) is det.
%
%   Run the mistake once on a fixed pair so the check reports what it is
%   guarding against rather than asserting that it guards.
demonstrate_raw_corruption(Shape) :-
    Raw = [step(1, establish_referent_whole, strip, referent_whole(strip, 1))],
    hermes_encyclopedia:history_steps(Raw, [Row | _]),
    get_dict(label, Row, Label),
    format(atom(Shape), 'label "~w"', [Label]).


%% ----------------------------------------------------------------------
%% 10. The emitted row
%% ----------------------------------------------------------------------

required_row_field(lesson).
required_row_field(grade).
required_row_field(subclass).
required_row_field(form).
required_row_field(form_gloss).
required_row_field(warrant).
required_row_field(inputs).
required_row_field(input_provenance).
required_row_field(steps).
required_row_field(artifact).
required_row_field(verdict).
required_row_field(what_it_does_not_claim).
required_row_field(provenance).

check_emitted_rows :-
    lesson_enactment:enactment_declared_lessons(Lessons),
    findall(Problem,
            ( member(Lesson, Lessons),
              lesson_enactment:enact_lesson(Lesson, E),
              lesson_enactment:enactment_row_dict(E, Row),
              row_problem(Lesson, Row, Problem)
            ),
            Problems),
    (   Problems == []
    ->  format("lesson_enactment: every emitted row carries 13 filled fields, \c
                a stated provenance, and a sentence about what it does not \c
                claim: PASS~n")
    ;   forall(member(P, Problems),
               format(user_error, "  row: ~w~n", [P])),
        fail
    ).

row_problem(Lesson, Row, Problem) :-
    required_row_field(Field),
    \+ get_dict(Field, Row, _),
    format(atom(Problem), '~w is missing field ~w', [Lesson, Field]).
row_problem(Lesson, Row, Problem) :-
    get_dict(what_it_does_not_claim, Row, Text),
    ( Text == "" ; Text == '' ),
    format(atom(Problem),
           '~w has an empty what_it_does_not_claim', [Lesson]).
row_problem(Lesson, Row, Problem) :-
    get_dict(input_provenance, Row, P),
    \+ ( lesson_enactment:enactment_provenance_value(Value),
         atom_string(Value, P) ),
    format(atom(Problem),
           '~w has input_provenance ~w, which is outside the closed vocabulary \c
            curriculum | curriculum_sample | machine_supplied', [Lesson, P]).
row_problem(Lesson, Row, Problem) :-
    get_dict(warrant, Row, W),
    (   \+ get_dict(text, W, _)
    ;   get_dict(text, W, Text), Text == ""
    ),
    format(atom(Problem), '~w carries an empty warrant span', [Lesson]).
row_problem(Lesson, Row, Problem) :-
    get_dict(artifact, Row, A),
    get_dict(kind, A, Kind),
    \+ memberchk(Kind, ["scene", "printed", "scene_and_record"]),
    format(atom(Problem),
           '~w has artifact kind ~w, which is none of scene, printed, or \c
            scene_and_record', [Lesson, Kind]).
row_problem(Lesson, Row, Problem) :-
    get_dict(steps, Row, Steps),
    member(S, Steps),
    ( \+ get_dict(verb, S, _) ; \+ get_dict(operand, S, _)
    ; \+ get_dict(result, S, _) ; \+ get_dict(index, S, _) ),
    format(atom(Problem),
           '~w has a step row missing one of index/verb/operand/result',
           [Lesson]).


%% ----------------------------------------------------------------------
%% 9. Population membership
%% ----------------------------------------------------------------------

%!  check_population_membership(+Population) is semidet.
%
%   Every declared lesson is one of the 226 the recut carries. That half is a
%   failure: a lane enacting a lesson outside the population would put a count
%   on the rung that the denominator does not cover.
%
%   The other half is reported and not refused. A lane may enact a lesson the
%   recut files under another subclass, and one does: IM-G3-U8-L12 is filed
%   under `measurement_task` and its doing is a Notice and Wonder routine, which
%   the measurement lane refused by name and the data lane runs. The recut's
%   subclass is a reading of the lesson; the lane is a fact about which machines
%   reach it, and the two need not agree. The census counts by the recut's
%   subclass either way, so the count is unaffected; what the crossing changes
%   is which emission file the row lands in, which is why it is named here.
check_population_membership(Population) :-
    lesson_enactment:enactment_declared_lessons(Lessons),
    findall(Problem,
            ( member(Lesson, Lessons),
              membership_problem(Population, Lesson, Problem)
            ),
            Problems),
    findall(Lesson-Subclass-Lane,
            crossed_subclass(Population, Lesson, Subclass, Lane),
            Crossed0),
    sort(Crossed0, Crossed),
    length(Crossed, CrossedCount),
    (   Problems == []
    ->  length(Lessons, N),
        format("lesson_enactment: ~w declared lesson(s) sit in the recut \c
                population, ~w of them enacted by a lane other than the one \c
                their subclass names: PASS~n", [N, CrossedCount]),
        forall(member(L-S-Lane, Crossed),
               format("lesson_enactment:   ~w is ~w in the recut and reaches \c
                       the rung through the ~w lane~n", [L, S, Lane]))
    ;   forall(member(P, Problems),
               format(user_error, "  population: ~w~n", [P])),
        fail
    ).

membership_problem(Population, Lesson, Problem) :-
    \+ memberchk(Lesson-_, Population),
    format(atom(Problem),
           '~w is not one of the 226 lessons in im_action_seam_recut.json',
           [Lesson]).

crossed_subclass(Population, Lesson, Subclass, Lane) :-
    lesson_enactment:enactment_declared_lessons(Lessons),
    member(Lesson, Lessons),
    memberchk(Lesson-Subclass, Population),
    lesson_enactment:lesson_enactment_form(Lesson, Form, _),
    lesson_enactment:enactment_lane(Form, Lane),
    Lane \== Subclass.

%% ----------------------------------------------------------------------
%% 12. The form is the only branch point
%% ----------------------------------------------------------------------

%!  check_solutions_are_confined is semidet.
%
%   A lesson yields exactly as many enactments as it declares forms. More than
%   that means a helper under `enact/3` returned a second solution, which
%   multiplies through findall and emits duplicate rows without failing
%   anything. The data lane met this as 60 rows for 43 lessons.
check_solutions_are_confined :-
    lesson_enactment:enactment_solution_check(Report),
    get_dict(lessons, Report, Lessons),
    get_dict(enactments, Report, Enactments),
    get_dict(declared_form_pairs, Report, Pairs),
    get_dict(multiplied, Report, Multiplied),
    (   Multiplied =:= 0, Enactments =:= Pairs
    ->  format("lesson_enactment: ~w lesson(s) declaring ~w form(s) yield ~w \c
                enactment(s); the form is the only branch point: PASS~n",
               [Lessons, Pairs, Enactments])
    ;   get_dict(multiplied_lessons, Report, Names),
        forall(member(Lesson-Ran-Declared, Names),
               format(user_error,
                      "  solutions: ~w declares ~w form(s) and yielded ~w \c
                       enactment(s); a helper under enact/3 is missing a \c
                       once/1~n", [Lesson, Declared, Ran])),
        (   Enactments =\= Pairs
        ->  format(user_error,
                   "  solutions: ~w enactment(s) against ~w declared \c
                    lesson-form pair(s)~n", [Enactments, Pairs])
        ;   true
        ),
        fail
    ).


%% ----------------------------------------------------------------------
%% 13. The contract rules no lesson in this repo yet exercises
%% ----------------------------------------------------------------------

%!  check_contract_rules is semidet.
%
%   The provenance cap and the render bound are contract rules rather than lane
%   choices, so they are checked here on constructed terms rather than waiting
%   for a lane whose lessons happen to exercise them. Both would otherwise sit
%   in the module untested until a lane hit them at scale, which is how the
%   measurement lane met the quadratic renderer.
check_contract_rules :-
    Capped = enactment(
        'IM-G4-U2-L4', partition_strip_into_named_parts,
        [ input(part_word, tenths,
                stand_in('the lesson leaves the strip to the classroom')) ],
        [ step(1, establish_referent_whole, strip, referent_whole(strip, 1)),
          step(2, read_named_partition_count, tenths, 10),
          step(3, partition_whole_into_equal_parts, 10,
               equal_parts(10, fraction(1, 10))),
          step(4, label_each_part_with_its_unit_fraction,
               equal_parts(10, fraction(1, 10)), labelled_parts(10, '1/10')) ],
        printed(checked_by_the_gate)),
    lesson_enactment:enactment_verdict(Capped, CappedVerdict),
    (   CappedVerdict == partial(inputs_supplied_by_machine([part_word]))
    ->  true
    ;   format(user_error,
               "  contract rule: a stand-in input reached ~w instead of \c
                partial(inputs_supplied_by_machine([part_word]))~n",
               [CappedVerdict]),
        fail
    ),
    lesson_enactment:enactment_stand_in_keys(
        [ pass(one, [width-stand_in('measured in the room')]) ], PassKeys),
    (   PassKeys == [width]
    ->  true
    ;   format(user_error,
               "  contract rule: a stand-in inside a pass binding went \c
                unseen (~w)~n", [PassKeys]),
        fail
    ),
    (   \+ lesson_enactment:within_render_bound(measurement_strip_scene, 10119)
    ->  true
    ;   format(user_error,
               "  contract rule: 10119 items passed the render bound; the \c
                case that did not return would render again~n", []),
        fail
    ),
    lesson_enactment:bounded_artifact(
        measurement_strip_scene, 10119,
        no_such_module:no_such_goal, interval_count(10119), Bounded),
    (   Bounded = printed(over_render_bound(measurement_strip_scene, 10119, _, _))
    ->  true
    ;   format(user_error,
               "  contract rule: bounded_artifact/5 returned ~w past the \c
                bound instead of a printed record~n", [Bounded]),
        fail
    ),
    % A sample is curricular, so it must NOT cap the verdict, and it must still
    % change the row's provenance. Both halves are checked, because getting one
    % right and the other wrong is how a three-value vocabulary collapses back
    % into two.
    Sampled = enactment(
        'IM-G4-U2-L4', partition_strip_into_named_parts,
        [ input(part_word, tenths,
                sample('one worked case of a task whose answer is open')) ],
        [ step(1, establish_referent_whole, strip, referent_whole(strip, 1)),
          step(2, read_named_partition_count, tenths, 10),
          step(3, partition_whole_into_equal_parts, 10,
               equal_parts(10, fraction(1, 10))),
          step(4, label_each_part_with_its_unit_fraction,
               equal_parts(10, fraction(1, 10)), labelled_parts(10, '1/10')) ],
        printed(checked_by_the_gate)),
    lesson_enactment:enactment_verdict(Sampled, SampledVerdict),
    (   SampledVerdict == well_formed
    ->  true
    ;   format(user_error,
               "  contract rule: a curriculum sample capped the verdict at ~w; \c
                the machine chose nothing, so it must not cap~n",
               [SampledVerdict]),
        fail
    ),
    lesson_enactment:enactment_sample_keys(
        [ input(part_word, tenths, sample(why)) ], SampleKeys),
    (   SampleKeys == [part_word]
    ->  true
    ;   format(user_error,
               "  contract rule: a sample marking went unseen (~w)~n",
               [SampleKeys]),
        fail
    ),
    lesson_enactment:fill_step_template(
        [ slot(stimulus, 'Display ~w.'),
          "1 minute: quiet think time",
          slot(missing_on_purpose) ],
        [stimulus-'the dot plot'], Filled),
    (   Filled == ['Display the dot plot.',
                   "1 minute: quiet think time",
                   'unfilled slot: missing_on_purpose']
    ->  true
    ;   format(user_error,
               "  contract rule: fill_step_template/3 produced ~w~n", [Filled]),
        fail
    ),
    check_list_artifact,
    lesson_enactment:default_render_bound(Bound),
    format("lesson_enactment: a stand-in caps the verdict and a sample does \c
            not, both change the row's provenance, a ~w-item bound routes \c
            past-bound artifacts to print, a list artifact keeps both its \c
            parts, and a routine template fills its slots: PASS~n", [Bound]).

%!  check_list_artifact is semidet.
%
%   An Artifact may be a list, which is how a lane keeps a scene AND the printed
%   record beside it. No lane emits one today: the geometry lane, which asked
%   for the shape, currently returns one or the other per form. So the rule is
%   run here on a constructed term rather than left to a lane to discover, and
%   both halves are checked, because a list whose scene survives and whose
%   record is dropped would look like it worked.
check_list_artifact :-
    Document = _{kind: "checked_by_the_gate", frames: [], result: "none"},
    Both = enactment(
        'IM-G4-U2-L4', partition_strip_into_named_parts, [],
        [ step(1, establish_referent_whole, strip, referent_whole(strip, 1)),
          step(2, read_named_partition_count, tenths, 10),
          step(3, partition_whole_into_equal_parts, 10,
               equal_parts(10, fraction(1, 10))),
          step(4, label_each_part_with_its_unit_fraction,
               equal_parts(10, fraction(1, 10)), labelled_parts(10, '1/10')) ],
        [ scene(fraction_bars, partition_filmstrip([10]), Document),
          printed(the_record_beside_the_figure) ]),
    lesson_enactment:enactment_row_dict(Both, Row),
    get_dict(artifact, Row, Artifact),
    (   get_dict(kind, Artifact, "scene_and_record"),
        get_dict(parts, Artifact, [Scene, Printed]),
        get_dict(kind, Scene, "scene"),
        get_dict(kind, Printed, "printed")
    ->  true
    ;   format(user_error,
               "  contract rule: a list artifact serialized as ~w instead of a \c
                scene beside a printed record~n", [Artifact]),
        fail
    ),
    (   lesson_enactment:enactment_verdict(Both, well_formed)
    ->  true
    ;   lesson_enactment:enactment_verdict(Both, Reached),
        format(user_error,
               "  contract rule: a list artifact whose parts are both complete \c
                reached ~w instead of well_formed~n", [Reached]),
        fail
    ),
    Half = enactment(
        'IM-G4-U2-L4', partition_strip_into_named_parts, [],
        [ step(1, establish_referent_whole, strip, referent_whole(strip, 1)),
          step(2, read_named_partition_count, tenths, 10),
          step(3, partition_whole_into_equal_parts, 10,
               equal_parts(10, fraction(1, 10))),
          step(4, label_each_part_with_its_unit_fraction,
               equal_parts(10, fraction(1, 10)), labelled_parts(10, '1/10')) ],
        [ scene(fraction_bars, partition_filmstrip([10]), Document),
          printed(none) ]),
    (   \+ lesson_enactment:enactment_verdict(Half, well_formed)
    ->  true
    ;   format(user_error,
               "  contract rule: a list artifact with an empty part still read \c
                well_formed; the dropped half would be invisible~n", []),
        fail
    ).

%!  load_population(+Root, -Population) is det.
%
%   Lesson-Subclass pairs from the recut, the file the lanes were carved from.
load_population(Root, Population) :-
    atomic_list_concat(
        [Root, 'data/learningcommons/derived/im_action_seam_recut.json'],
        '/', Path),
    setup_call_cleanup(
        open(Path, read, Stream, [encoding(utf8)]),
        json_read_dict(Stream, Doc, [value_string_as(atom)]),
        close(Stream)),
    get_dict(lessons, Doc, Rows),
    findall(Lesson-Subclass,
            ( member(Row, Rows),
              get_dict(lesson, Row, Lesson),
              get_dict(task_209_subclass, Row, Subclass)
            ),
            Population).

repo_root(Root) :-
    source_file(main, Self),
    file_directory_name(Self, ChecksDir),
    file_directory_name(ChecksDir, ScriptsDir),
    file_directory_name(ScriptsDir, Root).
