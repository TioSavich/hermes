/** <module> lesson_enactment — the second rung, for IM lessons no automaton computes
 *
 * The arithmetic rung (`executable_task`) counts a lesson when an automaton
 * ran a computation on operands the lesson printed. Most of the IM curriculum
 * does not ask for a computation. It asks a class to partition a strip, sort a
 * set of shapes, measure with a chosen unit, or put a question to a display.
 * This module carries the contract for machines that run THOSE doings.
 *
 * An enactment is not a claim that the software held a classroom discussion.
 * It is a machine that
 *   (a) names the structure a lesson asks a class to move through,
 *   (b) instantiates that structure on the lesson's own printed inputs, and
 *   (c) emits an artifact a teacher can read, next to a verdict and a sentence
 *       saying what the artifact does not claim.
 *
 * Lane modules live at `curriculum/im/enactment/<subclass>.pl`. A lane owns a
 * subclass of `data/learningcommons/derived/im_action_seam_recut.json` and adds
 * clauses to the multifile hooks below. This module owns no lesson facts of its
 * own; it owns the vocabulary, the runner, the verdict, the trace seam, and the
 * emission writer.
 *
 * ## The trace seam (binding)
 *
 * `Steps` is a list of `step(Index, Verb, Operand, Result)`, and
 * `enactment_trace_dict/2` is the ONE serializer every lane uses. It fills the
 * dict keys `hermes_encyclopedia:strategy_trace_dict/3` returns, so an
 * enactment reaches every consumer a strategy trace reaches. There is no
 * second display path and there is no second serializer.
 *
 * A trap worth naming, because the measurement lane found it the hard way.
 * `hermes/encyclopedia.pl` recognizes a legacy four-place history step as
 * `step_state_interp(step(S,_,_,I), S, I)`. Handing a raw
 * `step(Index, Verb, Operand, Result)` list to `history_steps/2` therefore
 * reads the INDEX as the state label and the RESULT as the value, and it does
 * so silently. Never pass the step list to `history_steps/2`. If you want that
 * route, `enactment_steps_history/2` rewrites first into the three-place shape
 * the seam reads correctly, and the gate checks the result.
 *
 * ## What a lane owes
 *
 * enactment_lane/2            which subclass owns the form
 * enactment_form/3            the form, its gloss, and the span it was read from
 * lesson_enactment_form/3     which lessons take the form, each with its span
 * enactment_move/3            the ordered moves, as verbs over operand roles
 * enactment_verb/4            the executable verb, one clause per named verb
 * enactment_passes/4          how a lesson's inputs split into repeated runs
 * enactment_artifact/5        the picture or the record
 * enactment_disclaimer/2      what the artifact does not claim, one sentence
 * enactment_lesson_disclaimer/2  the same, sharpened for one lesson
 * enactment_input_provenance/3  curriculum, curriculum_sample, machine_supplied
 * lesson_enactment_refusal/2  for a lesson with no form, the machine it needs
 *
 * Only the first six are required. The runner supplies defaults for passes,
 * artifact, and provenance so a lane can land a form in one file.
 *
 * ## Two routes to a run, and why the second one exists
 *
 * A lane can reach `enact/3` two ways.
 *
 * The **generic route** declares `enactment_verb/4` and `enactment_passes/4`
 * and lets the runner below drive the move sequence. The reference lane takes
 * it. It is the shorter route and it puts every commitment the contract makes
 * (one solution per form, no fabricated Result, provenance from the input
 * marks) in one place.
 *
 * The **lane route** supplies `enactment_run/3`: the lane derives its own
 * inputs for the pair and runs its own move sequence, returning the finished
 * `enactment/5` term. Four lanes here take it, because four lanes wrote their
 * machines before this module existed and their move sequences are not
 * uniform per form: a geometry construction runs a different arity of doing
 * than a geometry sort, and folding both into one `enactment_verb/4` table
 * would have rewritten working machines into a shape that fits the runner
 * rather than the mathematics. The contract does not require one route; it
 * requires that the count come from running the machines, and both routes run
 * them. What the lane route gives up is the runner's structural verdict, which
 * is why a lane that takes it supplies `enactment_lane_verdict/2` as well.
 *
 * Whichever route a lane takes, the census reaches it through `enact_lesson/2`
 * and nowhere else. Nothing in this rung reads a lane's own emission file.
 *
 * ## Four rules the first working lane established
 *
 * 1. **A lesson may take more than one form, and the form is the ONLY branch
 *    point.** `enact/3` is nondet over the forms a lesson declares, and a lane
 *    whose inputs already name the form should put the form first in its input
 *    list so `enact/3` reads it off its own arguments. Four measurement lessons
 *    exhibit two forms and one exhibits a single form at two settings; a
 *    semidet `enact/3` would have silently dropped the second reading of each.
 *
 *    Nondet `enact/3` is necessary and not sufficient. Every helper underneath
 *    it must be committed with `once/1`: move execution, operand binding, pass
 *    construction, artifact selection. The data lane's first run emitted 60
 *    rows for 43 lessons because one helper inside a move returned a second
 *    solution, and nothing failed. A second solution from inside a move is a
 *    second reading of one doing, and it multiplies quietly through findall.
 *    `enactment_solution_check/1` counts solutions against declared forms so
 *    the multiplication becomes loud.
 *
 * 2. **Every emitted step verb must be a declared move of its form.**
 *    `enactment_move_check/1` re-reads the verbs the machines emitted against
 *    the moves the lane declared. This is the "a name is not a doing" rule
 *    made executable in the other direction: the gate already refuses a
 *    declared move with no clause, and this refuses an emitted verb no move
 *    declares.
 *
 * 3. **A machine-supplied input caps the verdict.** An input marked
 *    `stand_in(Reason)` or `machine_supplied(Reason)` means the curriculum
 *    left the value to the room and the machine chose one. Such an enactment
 *    can never read `well_formed`; `enactment_verdict/2` caps it at
 *    `partial(inputs_supplied_by_machine(Keys))`. The rule lives here rather
 *    than in a lane, because a rung whose honesty depends on four independent
 *    lanes remembering it is not honest.
 *
 * 4. **Preferring an existing renderer carries a cost clause.** Some scene
 *    compilers are quadratic in their input: `measurement_strip_scene` emits
 *    one frame per interval and carries the whole jump list on each frame, and
 *    a 10,119-interval case did not return. A lane must bound its renderer
 *    input with `enactment_render_bound/2` and print instead of rendering past
 *    the bound. `bounded_artifact/5` does that in one call.
 *
 * ## The routine-template pattern
 *
 * A discourse routine is the shape this rung is most likely to get wrong, and
 * the wrong resolution is the one that looks more thorough.
 *
 * IM prints a step sequence for each of its routines: display the image, ask
 * what you notice and what you wonder, one minute of quiet think time, partner
 * discussion, share and record responses. The tempting reading is that those
 * are five moves. They are not. `allow_quiet_think_time` is not a doing a
 * machine performs; declaring it as an `enactment_move` would store a string
 * where the contract requires a verb, and the resulting form would look
 * thorough while enacting nothing. A gate can catch the missing
 * `enactment_verb/4` clause, but a lane that then writes a clause returning
 * `ok` has defeated the gate and kept the appearance.
 *
 * The pattern that works, which the data lane found: make the routine's step
 * sequence an OPERAND rather than a list of verbs. One move, whose doing is
 * instantiating IM's own printed template over this lesson's stimulus. The
 * machine fills slots; it does not pretend to perform classroom time. What the
 * enactment produces is a routine ready to run and a draft of the
 * contributions the stimulus licenses, which a facilitator holds beside what a
 * class actually offers.
 *
 * `fill_step_template/3` does the slot filling. The template belongs to a lane,
 * cited to the guide that prints it, and the row's
 * `what_it_does_not_claim` must say that the routine was not run.
 */

:- module(lesson_enactment,
          [ enactment_form/3,              % ?Form, ?Gloss, ?Warrant
            lesson_enactment_form/3,       % ?Lesson, ?Form, ?Evidence
            enactment_move/3,              % ?Form, ?Index, ?Move
            enactment_lane/2,              % ?Form, ?Subclass
            enactment_verb/4,              % +Form, +Verb, +Operand, -Result
            enactment_passes/4,            % +Form, +Lesson, +Inputs, -Passes
            enactment_artifact/5,          % +Form, +Lesson, +Passes, +Steps, -Artifact
            enactment_disclaimer/2,        % ?Form, ?Sentence
            enactment_lesson_disclaimer/2, % ?Lesson, ?Sentence
            enactment_input_provenance/3,  % ?Form, ?Lesson, ?Provenance
            enactment_render_bound/2,      % ?Renderer, ?MaxItems
            lesson_enactment_refusal/2,    % ?Lesson, ?MachineNeeded
            enactment_run/3,               % +Form, +Lesson, -Enactment
            enactment_lane_verdict/2,      % +Enactment, -Verdict

            enact/3,                       % +Lesson, +Inputs, -Enactment
            enact_lesson/2,                % +Lesson, -Enactment
            enactment_verdict/2,           % +Enactment, -Verdict
            enactment_verdict_text/2,      % +Verdict, -Text

            enactment_move_verb/2,         % +Move, -Verb
            enactment_lesson_forms/2,      % +Lesson, -Forms
            enactment_disclaimer_text/3,   % +Form, +Lesson, -Sentence
            enactment_move_check/1,        % -Dict
            enactment_solution_check/1,    % -Dict
            enactment_stand_in_keys/2,     % +Inputs, -Keys
            enactment_sample_keys/2,       % +Inputs, -Keys
            enactment_provenance_value/1,  % ?Provenance
            fill_step_template/3,          % +Template, +Bindings, -Steps
            within_render_bound/2,         % +Renderer, +Size
            bounded_artifact/5,            % +Renderer, +Size, +Term, +Fallback, -Artifact

            enactment_steps_history/2,     % +Steps, -History
            enactment_step_dict/2,         % +Step, -Dict
            enactment_trace_dict/2,        % +Enactment, -Dict
            enactment_row_dict/2,          % +Enactment, -Dict
            enactment_row_json/2,          % +Enactment, -JSONText

            enactment_emission_path/2,     % +Subclass, -Path
            write_enactment_rows/2,        % +Subclass, +Enactments
            enactment_lesson_grade/2,      % +Lesson, -Grade

            enactment_declared_lessons/1,  % -Lessons
            enactment_form_move_count/2    % +Form, -Count
          ]).

:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(http/json)).
:- use_module(library(filesex), [directory_file_path/3, make_directory_path/1]).

% The serializer the strategy display already consumes. Loading it here is what
% keeps an enactment on the existing seam rather than beside it.
:- use_module(hermes(encyclopedia), []).

:- multifile
       enactment_form/3,
       lesson_enactment_form/3,
       enactment_move/3,
       enactment_lane/2,
       enactment_verb/4,
       enactment_passes/4,
       enactment_artifact/5,
       enactment_disclaimer/2,
       enactment_lesson_disclaimer/2,
       enactment_input_provenance/3,
       enactment_render_bound/2,
       lesson_enactment_refusal/2,
       enactment_run/3,
       enactment_lane_verdict/2.

:- discontiguous
       enactment_form/3,
       lesson_enactment_form/3,
       enactment_move/3,
       enactment_lane/2.


%% ======================================================================
%% The vocabulary
%% ======================================================================

%!  enactment_form(?Form, ?Gloss, ?Warrant) is nondet.
%
%   A structural shape IM lessons take. Form is an atom named for the doing,
%   never for a topic. Gloss is one sentence in the present tense about what
%   the machine does. Warrant cites where the shape was read from:
%
%       warrant(LessonId, SourcePath, Line, SpanText)
%
%   SourcePath is repo-relative and SpanText occurs in that file. The gate
%   `scripts/checks/lesson_enactment.pl` opens the file and checks it, so a
%   warrant that names a span the curriculum does not print fails the build.

%!  lesson_enactment_form(?Lesson, ?Form, ?Evidence) is nondet.
%
%   Which shape a given lesson takes. Evidence is
%
%       evidence(SourcePath, Line, SpanText)
%
%   under the same rule: the text is checked against the file at build time.
%
%   **The two spans are different spans, and nothing requires them to agree.**
%   A form's warrant cites where the SHAPE was read from, once, in the lesson
%   that showed it most plainly. A lesson's evidence cites where THIS lesson
%   shows the shape. For ten geometry lessons the form was named from one
%   guide and the lesson was classified from another, which is the ordinary
%   case rather than a defect: a shape is named once and recognized many
%   times. A gate that required the two to be the same span would force a lane
%   either to re-warrant its form per lesson or to drop the lessons that read
%   the shape somewhere else, and both would make the citation worse. The gate
%   checks each span against its OWN cited file and stops there.

%!  enactment_move(?Form, ?Index, ?Move) is nondet.
%
%   The ordered doings the form asks for, Index counting from 1. Move takes
%   either shape, and `enactment_move_verb/2` reads the verb out of both:
%
%       move(Verb, OperandRole)   the generic runner's shape: this module binds
%                                 the operand and calls enactment_verb/4
%       Verb(Arg, ...)            a lane that runs its own steps and declares
%                                 the move as the verb applied to its argument
%
%   Verb is the functor of an `enactment_verb/4` clause the runner calls.
%   OperandRole says where the operand comes from:
%
%       input(Key)  a value the pass binds under Key
%       prior       the Result the previous move in this pass produced
%       const(V)    a literal
%       lesson      the lesson id
%
%   A move whose Verb has no `enactment_verb/4` clause is a name without a
%   doing; the gate fails on it.

%!  enactment_lane(?Form, ?Subclass) is nondet.
%
%   The `task_209_subclass` whose lane owns the form. The emission writer
%   routes rows by this.

%!  enactment_verb(+Form, +Verb, +Operand, -Result) is semidet.
%
%   The executed doing. Fails when the operand does not support the verb; the
%   runner turns that failure into a partial verdict rather than a guess.

%!  enactment_passes(+Form, +Lesson, +Inputs, -Passes) is semidet.
%
%   How one lesson's inputs split into repeated runs of the move sequence. A
%   lesson that asks for two strips runs the sequence twice. Passes is a list
%   of `pass(Label, Bindings)` where Bindings is a list of `Key-Value`.

%!  enactment_artifact(+Form, +Lesson, +Passes, +Steps, -Artifact) is semidet.
%
%   Artifact is one of three shapes:
%
%       scene(Renderer, Term, Dict)   a picture an existing module under
%                                     knowledge/strategies/render/ drew
%       printed(Record)               a record rather than a picture
%       [Artifact | ...]              both, in the order a reader meets them
%
%   The list arrived from the geometry lane and is not a convenience. Most
%   geometry doings produce a scene AND a printed record, and the two carry
%   different things: the scene is the figure, the record is the adjudication
%   (which of the eleven nets folded, which cells of the chart stay empty and
%   why). Folding the record into a step's Result would put it where a page
%   builder reads a step label, and dropping it would leave a picture with the
%   reasoning removed. A list keeps both, and the verdict counts the artifact
%   complete only when every member of the list is.

%!  enactment_disclaimer(?Form, ?Sentence) is nondet.
%
%   One sentence saying what the artifact does not claim. Never empty. This is
%   where the honesty of the rung lives: the machines run doings a machine
%   cannot fully do, and each row says so in its own words.

%!  enactment_lesson_disclaimer(?Lesson, ?Sentence) is nondet.
%
%   The same sentence, sharpened for one lesson, and it wins over the form's.
%   Some lessons cannot claim what the rest of their form can: the guide prints
%   the operand as a filled outline the markdown extraction drops, or the task
%   has no target because the choice belongs to the child. A form-level
%   sentence covering those cases would have to be vague enough to be useless
%   on the rest.

%!  enactment_input_provenance(?Form, ?Lesson, ?Provenance) is nondet.
%
%   Three values, because two were not enough:
%
%     curriculum         the lesson printed the values, and they are the values
%                        the task is about.
%     curriculum_sample  the lesson printed the values, but as one worked
%                        sample of a task whose answer is open. The numbers are
%                        curricular; the reading they support is one instance,
%                        not the task's answer.
%     machine_supplied   the lesson deferred the values to the room ("measure
%                        your desk") and the machine chose them.
%
%   The data lane found the middle case on four lessons and named the problem
%   exactly: calling a worked sample `curriculum` overstates it, and calling it
%   `machine_supplied` is false. All three are enactments, and the verdict enum
%   is untouched by this distinction. Only `machine_supplied` caps a verdict,
%   because only there did the machine choose the number.
%
%   A lane marks an input by writing its provenance in the input term:
%
%     input(Key, Value, curriculum(Source, Line))   printed and definitive
%     input(Key, Value, sample(Why))                printed as one worked case
%     input(Key, Value, stand_in(Why))              chosen by the machine

%!  enactment_render_bound(?Renderer, ?MaxItems) is nondet.
%
%   How many items a lane may hand a named scene compiler. Some compilers are
%   quadratic in their input, so an enactment on a large operand can stop
%   returning. A lane declares its own bound per renderer; the default below
%   applies to any renderer no lane bounded.

%!  lesson_enactment_refusal(?Lesson, ?MachineNeeded) is nondet.
%
%   For a lesson no form reaches: one sentence naming the machine it would
%   take. A refusal without a named machine is not a refusal, it is a shrug.
%
%   This is the rung's one refusal predicate. Two lanes each arrived at
%   `enactment_refusal/2` and a third at `enactment_refusal/3` before this
%   module existed; each of those now feeds this one through its lane's
%   registration block, so the census reads every refusal through one name.

%!  enactment_run(+Form, +Lesson, -Enactment) is semidet.
%
%   A lane that runs its own move sequence supplies this and skips
%   `enactment_verb/4` and `enactment_passes/4`. The lane derives the lesson's
%   inputs itself and returns the finished term
%   `enactment(Lesson, Form, Inputs, Steps, Artifact)`.
%
%   `enact/3` calls it inside `once/1`. A lane that wants two readings of one
%   lesson declares two forms, which is the contract's only branch point; a
%   second solution from inside a lane's runner is a second reading of one
%   doing and it would multiply through findall without failing.

%!  enactment_lane_verdict(+Enactment, -Verdict) is semidet.
%
%   A lane's own verdict, in the contract's grammar
%   `well_formed | partial(Reason) | refused(Reason)`. A lane that runs its own
%   move sequence needs this, because the structural verdict below counts steps
%   against a form's declared move count and a lane whose moves vary per lesson
%   would read partial for a run that completed.
%
%   Supplying it does not opt out of the provenance cap. `enactment_verdict/2`
%   applies that afterwards, to a lane verdict exactly as to a structural one.


%% ======================================================================
%% Move vocabulary, shared by the runner, the gate, and the move check
%% ======================================================================

%!  enactment_move_verb(+Move, -Verb) is semidet.
%
%   The verb a declared move names, under either declaration shape.
enactment_move_verb(move(Verb, _), Verb) :- !, atom(Verb).
enactment_move_verb(Move, Verb) :-
    compound(Move), !,
    functor(Move, Verb, _).
enactment_move_verb(Verb, Verb) :- atom(Verb).

%!  enactment_move_check(-Dict) is det.
%
%   Run every declared lesson and read the verbs the machines emitted back
%   against the moves the lane declared. The gate refuses a declared move with
%   no executable clause; this refuses the other direction, an emitted verb no
%   move declares. Between them a step verb is a doing the lane both named and
%   ran.
%
%   `index_mismatched` is reported and not refused: this module's runner
%   repeats a form's move sequence once per pass, so a step's position is its
%   move index modulo the sequence length, and a pass that stopped early moves
%   every later step. The count is information about alignment, not a defect.
enactment_move_check(_{steps_checked: Checked,
                       undeclared: Undeclared,
                       index_mismatched: Mismatched,
                       undeclared_verbs: Names}) :-
    findall(Form-Index-Verb,
            ( enactment_declared_lessons(Lessons),
              member(Lesson, Lessons),
              enact(Lesson, [], enactment(_, Form, _, Steps, _)),
              member(step(Index, Verb, _, _), Steps)
            ),
            Emitted),
    length(Emitted, Checked),
    findall(Form-Verb,
            ( member(Form-_-Verb, Emitted),
              \+ form_declares_verb(Form, Verb)
            ),
            Bad),
    length(Bad, Undeclared),
    sort(Bad, Names),
    findall(x,
            ( member(Form-Index-Verb, Emitted),
              form_declares_verb(Form, Verb),
              \+ verb_declared_at_index(Form, Index, Verb)
            ),
            Off),
    length(Off, Mismatched).

%!  enactment_solution_check(-Dict) is det.
%
%   Count `enact/3` solutions per lesson against the forms that lesson declares.
%   They must be equal: the form is the only branch point, so a lesson with one
%   form yields one enactment. A helper that returns a second solution shows up
%   here as a lesson whose enactment count exceeds its form count, which is the
%   shape of the data lane's 60-rows-for-43-lessons run.
enactment_solution_check(_{lessons: LessonCount,
                           enactments: EnactmentCount,
                           declared_form_pairs: FormPairs,
                           multiplied: Multiplied,
                           multiplied_lessons: Names}) :-
    enactment_declared_lessons(Lessons),
    length(Lessons, LessonCount),
    aggregate_all(count,
                  ( member(L, Lessons), enact(L, [], _) ),
                  EnactmentCount),
    findall(L-F, lesson_enactment_form(L, F, _), Pairs0),
    sort(Pairs0, Pairs),
    length(Pairs, FormPairs),
    findall(Lesson-Ran-Declared,
            ( member(Lesson, Lessons),
              aggregate_all(count, enact(Lesson, [], _), Ran),
              findall(F, lesson_enactment_form(Lesson, F, _), Fs0),
              sort(Fs0, Fs),
              length(Fs, Declared),
              Ran > Declared
            ),
            Bad),
    length(Bad, Multiplied),
    sort(Bad, Names).

form_declares_verb(Form, Verb) :-
    enactment_move(Form, _, Move),
    enactment_move_verb(Move, Verb), !.

verb_declared_at_index(Form, Index, Verb) :-
    enactment_form_move_count(Form, Count),
    Count > 0,
    Position is ((Index - 1) mod Count) + 1,
    enactment_move(Form, Position, Move),
    enactment_move_verb(Move, Verb), !.


%% ======================================================================
%% Inputs a machine supplied
%% ======================================================================

%!  enactment_stand_in_keys(+Inputs, -Keys) is det.
%
%   The input keys whose value the machine chose because the curriculum left it
%   to the room. A lane marks one by writing `input(Key, Value, stand_in(Why))`
%   or `input(Key, Value, machine_supplied(Why))`; anything else is read as
%   coming from the curriculum. Pass bindings are searched too, so the generic
%   runner's shape and a lane's own input list both reach this.
enactment_stand_in_keys(Inputs, Keys) :-
    findall(Key, stand_in_key(Inputs, Key), Keys0),
    sort(Keys0, Keys).

stand_in_key(Inputs, Key) :-
    marked_key(Inputs, machine_provenance, Key).

%!  enactment_sample_keys(+Inputs, -Keys) is det.
%
%   The input keys the curriculum printed as one worked sample of a task whose
%   answer is open. These are curricular values, so they do not cap a verdict,
%   but the row says `curriculum_sample` rather than `curriculum` so a reader
%   does not take one worked case for the task's answer.
enactment_sample_keys(Inputs, Keys) :-
    findall(Key, marked_key(Inputs, sample_provenance, Key), Keys0),
    sort(Keys0, Keys).

marked_key(Inputs, Test, Key) :-
    is_list(Inputs),
    member(Item, Inputs),
    (   Item = input(Key, _, Provenance),
        call(Test, Provenance)
    ;   Item = pass(_, Bindings),
        marked_key(Bindings, Test, Key)
    ;   Item = Key-Value,
        nonvar(Value),
        call(Test, Value)
    ).

machine_provenance(stand_in(_)).
machine_provenance(machine_supplied(_)).
machine_provenance(machine_supplied).

sample_provenance(sample(_)).
sample_provenance(curriculum_sample(_)).
sample_provenance(curriculum_sample).


%% ======================================================================
%% The routine-template pattern
%% ======================================================================

%!  fill_step_template(+Template, +Bindings, -Steps) is det.
%
%   Instantiate a routine's printed step sequence over this lesson's own
%   material. Template is a list whose entries are either literal text, which
%   passes through unchanged, or `slot(Key)` / `slot(Key, Format)`, which takes
%   its value from Bindings.
%
%   This is the whole of the routine-template pattern's machinery, and its
%   smallness is the point. A discourse routine's steps are mostly classroom
%   time a machine cannot spend; the machine's doing is filling the template,
%   and the filled sequence is an operand a facilitator reads, not a record of
%   anything performed. A lane that instead declares one `enactment_move` per
%   printed step has written names for doings, which is the failure this rung
%   exists to refuse.
%
%   A slot with no binding stays as its own printed marker rather than
%   vanishing, so a template a lane filled incompletely reads as incomplete.
fill_step_template(Template, Bindings, Steps) :-
    findall(Filled,
            ( member(Slot, Template),
              template_slot(Slot, Bindings, Filled)
            ),
            Steps).

template_slot(slot(Key, Format), Bindings, Filled) :-
    !,
    (   memberchk(Key-Value, Bindings)
    ->  format(atom(Filled), Format, [Value])
    ;   format(atom(Filled), 'unfilled slot: ~w', [Key])
    ).
template_slot(slot(Key), Bindings, Filled) :-
    !,
    (   memberchk(Key-Value, Bindings)
    ->  json_text(Value, Text), atom_string(Filled, Text)
    ;   format(atom(Filled), 'unfilled slot: ~w', [Key])
    ).
template_slot(Text, _, Text).


%% ======================================================================
%% The renderer cost clause
%% ======================================================================

%!  within_render_bound(+Renderer, +Size) is semidet.
%
%   True when a lane may hand Size items to Renderer. A lane's own
%   `enactment_render_bound/2` wins; otherwise the default applies.
within_render_bound(Renderer, Size) :-
    (   enactment_render_bound(Renderer, Max)
    ->  true
    ;   default_render_bound(Max)
    ),
    integer(Size),
    Size =< Max.

%!  default_render_bound(-Max) is det.
%
%   256 items. The number is a working bound, not a measured limit of any
%   particular compiler: it is small enough that a quadratic compiler still
%   returns quickly and large enough for every lesson-scale figure the lanes
%   have met. A lane that knows its compiler's real limit should say so.
default_render_bound(256).

%!  bounded_artifact(+Renderer, +Size, +Term, +Fallback, -Artifact) is det.
%
%   Route to the renderer when the input is within bound, and print the
%   fallback record when it is not. The printed record names the bound it
%   exceeded, so a reader meets the reason rather than a missing picture.
bounded_artifact(Renderer, Size, Term, Fallback, Artifact) :-
    (   within_render_bound(Renderer, Size),
        catch(render_scene_document(Renderer, Term, Document), _, fail)
    ->  Artifact = scene(Renderer, Term, Document)
    ;   \+ within_render_bound(Renderer, Size)
    ->  (   enactment_render_bound(Renderer, Max) -> true
        ;   default_render_bound(Max)
        ),
        Artifact = printed(over_render_bound(Renderer, Size, Max, Fallback))
    ;   Artifact = printed(renderer_refused(Renderer, Fallback))
    ).

%!  render_scene_document(+Renderer, +Term, -Document) is semidet.
%
%   A lane hook in all but name: the Term is a goal the lane wrote, of the form
%   `Module:Goal` with the document as its last argument. Keeping the call here
%   means the bound cannot be bypassed by a lane that calls its compiler
%   directly and forgets.
render_scene_document(_, Module:Goal, Document) :-
    !,
    Goal =.. Parts,
    append(Parts, [Document], Called),
    Call =.. Called,
    call(Module:Call).
render_scene_document(_, Goal, Document) :-
    Goal =.. Parts,
    append(Parts, [Document], Called),
    Call =.. Called,
    call(Call).


%% ======================================================================
%% Defaults for the optional hooks
%% ======================================================================

%!  form_passes(+Form, +Lesson, +Inputs, -Passes) is det.
%
%   A lane's own splitting when it has one, otherwise a single pass carrying
%   Inputs as its bindings.
form_passes(Form, Lesson, Inputs, Passes) :-
    (   once(( catch(enactment_passes(Form, Lesson, Inputs, Passes0), _, fail),
               Passes0 \== [] ))
    ->  Passes = Passes0
    ;   input_bindings(Inputs, Bindings),
        Passes = [pass(single, Bindings)]
    ).

input_bindings(Inputs, Bindings) :-
    (   is_list(Inputs)
    ->  Bindings = Inputs
    ;   is_dict(Inputs)
    ->  dict_pairs(Inputs, _, Bindings)
    ;   Bindings = []
    ).

%!  form_artifact(+Form, +Lesson, +Passes, +Steps, -Artifact) is det.
%
%   A lane's artifact when it builds one, otherwise the step results as a
%   printed record. The default is deliberately plain: a lane that ships no
%   artifact still emits something a reader can check, and the verdict says the
%   form reached no renderer.
form_artifact(Form, Lesson, Passes, Steps, Artifact) :-
    (   once(catch(enactment_artifact(Form, Lesson, Passes, Steps, Artifact0),
                   _, fail))
    ->  Artifact = Artifact0
    ;   findall(Verb-Result,
                member(step(_, Verb, _, Result), Steps),
                Record),
        Artifact = printed(step_results(Record))
    ).

%!  form_provenance(+Form, +Lesson, +Inputs, -Provenance) is det.
%
%   Weakest marking wins. A stand-in decides the row whatever the lane declared,
%   because a value the machine chose cannot be reported as one the curriculum
%   printed; a sample decides it next, for the same reason one worked case
%   cannot be reported as the task's answer. With neither marking, the lane's
%   own declaration stands, and `curriculum` is the default.
form_provenance(Form, Lesson, Inputs, Provenance) :-
    enactment_stand_in_keys(Inputs, StandIns),
    enactment_sample_keys(Inputs, Samples),
    (   StandIns \== []
    ->  Provenance = machine_supplied
    ;   Samples \== []
    ->  Provenance = curriculum_sample
    ;   enactment_input_provenance(Form, Lesson, P),
        ground(P),
        enactment_provenance_value(P)
    ->  Provenance = P
    ;   Provenance = curriculum
    ).

%!  enactment_provenance_value(?Provenance) is nondet.
%
%   The closed vocabulary. A lane that declares anything else falls back to
%   `curriculum` here and is named by the gate rather than passing silently.
enactment_provenance_value(curriculum).
enactment_provenance_value(curriculum_sample).
enactment_provenance_value(machine_supplied).

%!  enactment_disclaimer_text(+Form, +Lesson, -Sentence) is det.
%
%   What this row does not claim. The lesson's own sentence wins over the
%   form's, because a lesson whose operand the extraction dropped cannot claim
%   what the rest of its form claims. With neither declared, the row says the
%   reach is unstated rather than saying nothing, so a missing sentence reads
%   as a gap instead of as silence.
enactment_disclaimer_text(Form, Lesson, Sentence) :-
    (   enactment_lesson_disclaimer(Lesson, S), S \== ''
    ->  Sentence = S
    ;   enactment_disclaimer(Form, S), S \== ''
    ->  Sentence = S
    ;   format(atom(Sentence),
               'This row records what the ~w machine ran; the lane declared no \c
                sentence about what it does not claim, so treat its reach as \c
                unstated.', [Form])
    ).


%% ======================================================================
%% enact/3 — run the form over the lesson's own inputs
%% ======================================================================

%!  enact(+Lesson, +Inputs, -Enactment) is nondet.
%
%   Enactment is `enactment(Lesson, Form, Inputs, Steps, Artifact)`. Fails when
%   no form claims the lesson, or when the form's passes cannot be built from
%   the inputs. A move whose verb fails on its operand stops that pass and
%   leaves the verdict partial; it does not fabricate a Result.
%
%   Two departures from the signature as written in the spec.
%
%   The mode is nondet, not semidet. A lesson can exhibit more than one form,
%   and the measurement lane found four that do plus one that takes a single
%   form at two settings. Backtracking yields one enactment per form. A lane
%   whose inputs already name the form should put the form first in the input
%   list so `enact/3` reads it off its own arguments rather than searching.
%
%   The Inputs slot of the returned term carries the passes the lane derived
%   from the lesson when the caller supplied none, because those are the values
%   the enactment actually ran on and the emitted `inputs` field says so. A
%   caller who supplies inputs gets them back unchanged.
enact(Lesson, Inputs, Enactment) :-
    enact_form(Lesson, Inputs, Form),
    (   once(catch(enactment_run(Form, Lesson, Own), _, fail))
    ->  Own = enactment(_, _, RunInputs, Steps, Artifact0),
        Steps \== [],
        Effective = RunInputs
    ;   form_passes(Form, Lesson, Inputs, Passes),
        run_passes(Form, Lesson, Passes, 1, Steps),
        Steps \== [],
        form_artifact(Form, Lesson, Passes, Steps, Artifact0),
        ( Inputs == [] -> Effective = Passes ; Effective = Inputs )
    ),
    enactment_artifact_document(Artifact0, Artifact),
    Enactment = enactment(Lesson, Form, Effective, Steps, Artifact).

%!  enactment_artifact_document(+Artifact0, -Artifact) is det.
%
%   Normalize a lane's artifact into the shapes the verdict, the row, and the
%   trace dict read, compiling a scene term into its render document on the way.
%
%   All four breadth lanes emit `scene(Renderer, Term)` and each compiled the
%   document again inside its own serializer, so the document was built four
%   ways and reached the emitted row in none of them. Compiling it here puts one
%   document in the row, in the trace dict, and in the census scene check at
%   once, and it is why `scenes_validated` counts the whole rung rather than one
%   lane.
%
%   The renderer name carries the call. Every module under
%   `knowledge/strategies/render/` is `<Base>_scene` and exports
%   `<Base>_render_json/2`; the convention is uniform across the twenty-two of
%   them, so reading the predicate off the name is mechanical rather than a
%   guess. A renderer that refuses its term leaves a printed record naming the
%   refusal, which the verdict then reads as an incomplete artifact.
enactment_artifact_document(Artifact0, Artifact) :-
    (   var(Artifact0)
    ->  Artifact = printed(none)
    ;   is_list(Artifact0)
    ->  maplist(enactment_artifact_document, Artifact0, Artifact)
    ;   Artifact0 = scene(Renderer, Term)
    ->  (   scene_render_document(Renderer, Term, Document)
        ->  Artifact = scene(Renderer, Term, Document)
        ;   Artifact = printed(renderer_refused(Renderer, Term))
        )
    ;   Artifact = Artifact0
    ).

%!  scene_render_document(+Renderer, +Term, -Document) is semidet.
%
%   The document has to survive being written as JSON, and the check is a real
%   one rather than a formality: `area_unit_covering_scene` put raw `X-Y` pairs
%   on two of its keys, which no JSON writer accepts, and the census stopped on
%   the first lesson that reached it. That renderer is fixed. The check stays,
%   because a renderer whose document cannot be written is a renderer no reader
%   here can use, and the row should say so where a reader meets it rather than
%   stopping the build for every other lane.
scene_render_document(Renderer, Term, Document) :-
    atom(Renderer),
    (   atom_concat(Base, '_scene', Renderer) -> true ; Base = Renderer ),
    atom_concat(Base, '_render_json', Predicate),
    Goal =.. [Predicate, Term, Document],
    catch(call(Renderer:Goal), _, fail),
    is_dict(Document),
    \+ get_dict(error, Document, _),
    catch(with_output_to(string(_),
                         json_write_dict(current_output, Document, [width(0)])),
          _, fail).

%!  enact_form(+Lesson, +Inputs, -Form) is nondet.
%
%   The forms `enact/3` may branch over: the one the caller named, or each
%   DISTINCT form the lesson declares. Distinctness matters because a lane may
%   cite one lesson's form from two spans, and iterating `lesson_enactment_form/3`
%   directly would then run the same form twice and report two enactments for
%   one doing.
enact_form(Lesson, Inputs, Form) :-
    is_list(Inputs), memberchk(form(Form), Inputs), !,
    once(lesson_enactment_form(Lesson, Form, _Evidence)).
enact_form(Lesson, _, Form) :-
    enactment_lesson_forms(Lesson, Forms),
    member(Form, Forms).

%!  enactment_lesson_forms(+Lesson, -Forms) is det.
%
%   The distinct forms a lesson declares, in a stable order.
enactment_lesson_forms(Lesson, Forms) :-
    findall(F, lesson_enactment_form(Lesson, F, _), Fs),
    sort(Fs, Forms).

%!  enact_lesson(+Lesson, -Enactment) is semidet.
%
%   enact/3 on the inputs the lane's own passes derive. The census calls this,
%   so the count comes from running the machines rather than from reading a
%   table of what they were meant to do.
enact_lesson(Lesson, Enactment) :-
    enact(Lesson, [], Enactment).

run_passes(_, _, [], _, []).
run_passes(Form, Lesson, [pass(Label, Bindings) | Rest], Index0, Steps) :-
    run_moves(Form, Lesson, Label, Bindings, Index0, Index1, none, Head),
    run_passes(Form, Lesson, Rest, Index1, Tail),
    append(Head, Tail, Steps).

run_moves(Form, Lesson, Label, Bindings, Index0, Index, Prior, Steps) :-
    findall(I-M, enactment_move(Form, I, M), Pairs0),
    msort(Pairs0, Pairs),
    run_move_list(Pairs, Form, Lesson, Label, Bindings,
                  Index0, Index, Prior, Steps).

% A move runs once. The form is the only place enact/3 backtracks; a second
% solution from inside a move or from an operand binding would be a second
% reading of one doing, and findall would multiply it without failing.
run_move_list([], _, _, _, _, Index, Index, _, []).
run_move_list([_-move(Verb, Role) | Rest], Form, Lesson, Label, Bindings,
              Index0, Index, Prior, Steps) :-
    (   once(( operand_value(Role, Bindings, Lesson, Prior, Operand),
               catch(enactment_verb(Form, Verb, Operand, Result), _, fail) ))
    ->  Steps = [step(Index0, Verb, Operand, Result) | More],
        Index1 is Index0 + 1,
        run_move_list(Rest, Form, Lesson, Label, Bindings,
                      Index1, Index, Result, More)
    ;   % The verb refused this operand. Stop this pass rather than invent a
        % Result; the shortfall is what makes the verdict partial.
        Steps = [],
        Index = Index0
    ).

%!  operand_value(+Role, +Bindings, +Lesson, +Prior, -Operand) is semidet.
operand_value(input(Key), Bindings, _, _, Operand) :-
    memberchk(Key-Operand, Bindings).
operand_value(prior, _, _, Prior, Prior) :-
    Prior \== none.
operand_value(const(Value), _, _, _, Value).
operand_value(lesson, _, Lesson, _, Lesson).


%% ======================================================================
%% enactment_verdict/2
%% ======================================================================

%!  enactment_verdict(+Enactment, -Verdict) is det.
%
%   well_formed        every declared move ran in every pass, the artifact
%                      reached a renderer or a record, and every input came
%                      from the curriculum.
%   partial(Reason)    some pass stopped early, the lane shipped no artifact,
%                      or the machine supplied an input the curriculum left to
%                      the room.
%   refused(Reason)    no move ran at all.
%
%   The provenance cap is a contract rule and not a lane's choice. An enactment
%   that ran on a number the machine chose can be worth reading and can still
%   be right, but it is not the lesson's own arithmetic, and letting it read
%   `well_formed` would put a machine-chosen value and a printed one under one
%   word.
enactment_verdict(Enactment, Verdict) :-
    Enactment = enactment(Lesson, Form, Inputs, _, _),
    (   once(catch(enactment_lane_verdict(Enactment, Lane), _, fail)),
        verdict_shape(Lane)
    ->  Reached = Lane
    ;   structural_verdict(Enactment, Reached)
    ),
    enactment_stand_in_keys(Inputs, Keys),
    form_provenance(Form, Lesson, Inputs, Provenance),
    (   Reached \== well_formed
    ->  Verdict = Reached
    ;   Keys \== []
    ->  Verdict = partial(inputs_supplied_by_machine(Keys))
    ;   Provenance == machine_supplied
    ->  Verdict = partial('the curriculum leaves these values to the classroom \c
                           and the lane supplied them')
    ;   Verdict = well_formed
    ).

%!  verdict_shape(?Verdict) is semidet.
%
%   The three terms the grammar admits. A lane verdict outside them falls back
%   to the structural reading rather than reaching the emitted string, so a
%   fourth verdict cannot enter the enum through a lane.
verdict_shape(well_formed).
verdict_shape(partial(_)).
verdict_shape(refused(_)).

%!  structural_verdict(+Enactment, -Verdict) is det.
%
%   The verdict the steps and the artifact earn, before the provenance cap.
structural_verdict(enactment(_, Form, _, Steps, Artifact), Verdict) :-
    length(Steps, Ran),
    enactment_form_move_count(Form, PerPass),
    (   Ran =:= 0
    ->  format(atom(R),
               'no move of ~w ran on the inputs supplied', [Form]),
        Verdict = refused(R)
    ;   PerPass > 0,
        Ran mod PerPass =:= 0,
        artifact_complete(Artifact)
    ->  Verdict = well_formed
    ;   \+ artifact_complete(Artifact)
    ->  format(atom(R),
               '~w ran ~w step(s) but reached no renderer or record', [Form, Ran]),
        Verdict = partial(R)
    ;   Complete is Ran // PerPass,
        Leftover is Ran mod PerPass,
        format(atom(R),
               '~w completed ~w pass(es) of ~w moves and stopped ~w move(s) \c
                into another', [Form, Complete, PerPass, Leftover]),
        Verdict = partial(R)
    ).

artifact_complete(List) :-
    is_list(List), !,
    List \== [],
    forall(member(Part, List), artifact_complete(Part)).
artifact_complete(scene(_, _, Dict)) :- is_dict(Dict), !.
artifact_complete(printed(Record)) :- nonvar(Record), Record \== none.

%!  enactment_verdict_text(+Verdict, -Text) is det.
%
%   The emitted string form: "well_formed", "partial: <reason>",
%   "refused: <reason>".
enactment_verdict_text(well_formed, "well_formed") :- !.
enactment_verdict_text(partial(inputs_supplied_by_machine(Keys)), Text) :- !,
    atomic_list_concat(Keys, ', ', Joined),
    format(string(Text),
           "partial: the curriculum leaves these to the classroom, so the \c
            machine supplied them: ~w", [Joined]).
enactment_verdict_text(partial(Reason), Text) :- !,
    format(string(Text), "partial: ~w", [Reason]).
enactment_verdict_text(refused(Reason), Text) :- !,
    format(string(Text), "refused: ~w", [Reason]).
enactment_verdict_text(Other, Text) :-
    format(string(Text), "~w", [Other]).

%!  enactment_form_move_count(+Form, -Count) is det.
enactment_form_move_count(Form, Count) :-
    findall(I, enactment_move(Form, I, _), Is0),
    sort(Is0, Is),
    length(Is, Count).

%!  enactment_declared_lessons(-Lessons) is det.
enactment_declared_lessons(Lessons) :-
    findall(L, lesson_enactment_form(L, _, _), L0),
    sort(L0, Lessons).


%% ======================================================================
%% The trace seam
%% ======================================================================

%!  enactment_steps_history(+Steps, -History) is det.
%
%   Rewrite `step(Index, Verb, Operand, Result)` into the history shape
%   `hermes_encyclopedia:history_steps/2` reads CORRECTLY: a step/3 whose first
%   argument is the state and whose third is the interpretation. The state term
%   is `Verb(Operand)`, which prints as an action automaton's own trace states
%   print.
%
%   This rewrite exists because the raw step list must never be handed to
%   `history_steps/2`. That predicate also recognizes a legacy four-place step
%   as `step(State, _, _, Interp)`, so a `step(Index, Verb, Operand, Result)`
%   list matches it and reads the index as the state label, without an error
%   and without a warning. The gate checks that no serialized step label is a
%   bare number, which is what that corruption looks like from outside.
enactment_steps_history([], []).
enactment_steps_history([step(_, Verb, Operand, Result) | Rest],
                        [step(State, Operand, Result) | More]) :-
    State =.. [Verb, Operand],
    enactment_steps_history(Rest, More).

%!  enactment_step_dict(+Step, -Dict) is det.
%
%   One step in the `_{n, label, value}` shape the strategy display reads.
%   `label` is the bare verb and `value` carries the operand and the result the
%   verb produced. Keeping the operand out of the label bounds the label at a
%   verb name; a step whose operand is a list of every part of a partition would
%   otherwise put that whole list where the display expects a state name.
enactment_step_dict(step(Index, Verb, Operand, Result),
                    _{n: Index, label: Label, value: Value}) :-
    json_text(Verb, Label),
    json_text(Operand, OperandText),
    json_text(Result, ResultText),
    format(string(Value), "~w -> ~w", [OperandText, ResultText]).

%!  artifact_jumps(+Artifact, -Jumps) is det.
%
%   Number-line jumps when the artifact's render document carries them, and an
%   empty list otherwise. Some scene compilers (the measurement strip, the
%   number line) put a jump list on their frames, and a jump list a compiler
%   already computed belongs in the trace dict rather than being recomputed.
artifact_jumps(List, Jumps) :-
    is_list(List), !,
    (   member(Part, List), artifact_jumps(Part, Found), Found \== []
    ->  Jumps = Found
    ;   Jumps = []
    ).
artifact_jumps(scene(_, _, Document), Jumps) :-
    is_dict(Document),
    get_dict(frames, Document, Frames),
    Frames \== [],
    last(Frames, Frame),
    is_dict(Frame),
    get_dict(scene, Frame, Scene),
    is_dict(Scene),
    get_dict(jumps, Scene, Jumps0),
    is_list(Jumps0), !,
    Jumps = Jumps0.
artifact_jumps(_, []).

%!  enactment_trace_dict(+Enactment, -Dict) is det.
%
%   The one serializer. It fills the dict shape `strategy_trace_dict/3` returns,
%   plus the enactment keys a page builder needs, so an enactment appears
%   wherever a strategy trace appears. Every lane calls this rather than writing
%   its own; four serializers would be four chances to drift from the shape the
%   display reads.
%
%   jumps[] is filled from the artifact's own render document when the compiler
%   put one there, and is empty otherwise. An empty list carries a stated reason
%   in jump_witness rather than passing as an absence nobody asked about.
enactment_trace_dict(Enactment, Dict) :-
    Enactment = enactment(Lesson, Form, _Inputs, Steps, Artifact),
    maplist(enactment_step_dict, Steps, StepDicts),
    artifact_jumps(Artifact, Jumps),
    enactment_verdict(Enactment, Verdict),
    enactment_verdict_text(Verdict, VerdictText),
    enactment_disclaimer_text(Form, Lesson, Disclaimer),
    atom_string(Form, FormStr),
    atom_string(Lesson, LessonStr),
    (   enactment_form(Form, Gloss, _)
    ->  atom_string(Gloss, GlossStr)
    ;   GlossStr = ""
    ),
    artifact_summary(Artifact, ArtifactKind, ArtifactText),
    last_result_text(Steps, ResultStr),
    length(Steps, Ran),
    length(Jumps, JumpCount),
    (   Jumps == []
    ->  format(string(Note),
               "Enactment of ~w on ~w: ~w step(s) ran. This form's artifact \c
                carries no number-line jumps, so jumps[] is empty.",
               [Form, Lesson, Ran])
    ;   format(string(Note),
               "Enactment of ~w on ~w: ~w step(s) ran, and ~w jump(s) come \c
                from the artifact's own render document.",
               [Form, Lesson, Ran, JumpCount])
    ),
    atom_string(Disclaimer, DisclaimerStr),
    Dict = _{
        strategy: FormStr,
        ok: true,
        representation: "enactment",
        result: ResultStr,
        steps: StepDicts,
        jumps: Jumps,
        jump_witness: _{
            kind: "enactment_artifact_jump_list",
            scope: "jumps_present_only_when_the_scene_compiler_emitted_them",
            strategy: FormStr,
            extraction: "last_frame_scene_jumps",
            derivation: "read_from_the_artifact_render_document",
            sample_count: 0,
            jump_count: JumpCount,
            sums: [],
            jumps: Jumps
        },
        note: Note,
        lesson: LessonStr,
        form: FormStr,
        form_gloss: GlossStr,
        verdict: VerdictText,
        artifact_kind: ArtifactKind,
        artifact_summary: ArtifactText,
        what_it_does_not_claim: DisclaimerStr
    }.

artifact_summary(List, "scene_and_record", Text) :-
    is_list(List), List \== [], !,
    findall(Part,
            ( member(Member, List),
              artifact_summary(Member, _, Part)
            ),
            Parts),
    atomic_list_concat(Parts, '; ', Joined),
    atom_string(Joined, Text).
artifact_summary(scene(Renderer, Term, _), "scene", Text) :- !,
    format(string(Text), "~w scene from ~w", [Renderer, Term]).
artifact_summary(printed(Record), "printed", Text) :- !,
    term_string(Record, Text, [quoted(false), numbervars(true)]).
artifact_summary(Other, "unknown", Text) :-
    term_string(Other, Text, [quoted(false), numbervars(true)]).

last_result_text([], "") :- !.
last_result_text(Steps, Text) :-
    last(Steps, step(_, _, _, Result)),
    (   number(Result)
    ->  format(string(Text), "~w", [Result])
    ;   term_string(Result, Text, [quoted(false), numbervars(true)])
    ).


%% ======================================================================
%% Emission — one JSON object per enacted lesson
%% ======================================================================

%!  enactment_row_dict(+Enactment, -Dict) is det.
%
%   The emitted row. Every field is JSON-safe: strings, numbers, lists, dicts.
%   A page builder needs nothing beyond one of these files.
enactment_row_dict(Enactment, Dict) :-
    Enactment = enactment(Lesson, Form, Inputs, Steps, Artifact),
    atom_string(Lesson, LessonStr),
    atom_string(Form, FormStr),
    enactment_lesson_grade(Lesson, Grade),
    (   enactment_lane(Form, Subclass)
    ->  atom_string(Subclass, SubclassStr)
    ;   SubclassStr = ""
    ),
    (   enactment_form(Form, Gloss, _)
    ->  atom_string(Gloss, GlossStr)
    ;   GlossStr = ""
    ),
    % Two spans, and the row carries both rather than choosing.
    %
    % `warrant` is the span that licensed THIS lesson's reading. `form_warrant`
    % is the span the FORM was named from, which is a different span for ten
    % geometry lessons and for most of the data lane: a shape is named once, in
    % the lesson that shows it most plainly, and recognized many times after.
    % Emitting only the first would leave a reader unable to check the naming;
    % emitting only the second would attach every lesson to a guide page that
    % is not its own.
    (   lesson_enactment_form(Lesson, Form, Evidence)
    ->  warrant_dict(Evidence, WarrantDict)
    ;   enactment_form(Form, _, Warrant0)
    ->  warrant_dict(Warrant0, WarrantDict)
    ;   warrant_dict(none, WarrantDict)
    ),
    (   enactment_form(Form, _, Warrant)
    ->  form_warrant_dict(Warrant, FormWarrantDict)
    ;   form_warrant_dict(none, FormWarrantDict)
    ),
    inputs_json(Inputs, Steps, InputsJSON),
    form_provenance(Form, Lesson, Inputs, Provenance),
    atom_string(Provenance, ProvenanceStr),
    step_rows(Steps, StepRows),
    artifact_dict(Artifact, ArtifactDict),
    enactment_verdict(Enactment, Verdict),
    enactment_verdict_text(Verdict, VerdictText),
    enactment_disclaimer_text(Form, Lesson, Disclaimer),
    atom_string(Disclaimer, DisclaimerStr),
    emission_stamp(Stamp),
    Dict = _{
        lesson: LessonStr,
        grade: Grade,
        subclass: SubclassStr,
        form: FormStr,
        form_gloss: GlossStr,
        warrant: WarrantDict,
        form_warrant: FormWarrantDict,
        inputs: InputsJSON,
        input_provenance: ProvenanceStr,
        steps: StepRows,
        artifact: ArtifactDict,
        verdict: VerdictText,
        what_it_does_not_claim: DisclaimerStr,
        provenance: _{
            module: "curriculum/im/lesson_enactment.pl",
            predicate: "lesson_enactment:enact/3",
            generated_by: "scripts/curriculum/build_im_lesson_enactment_census.py",
            timestamp: Stamp
        }
    }.

%!  emission_stamp(-Stamp) is det.
%
%   The wall clock, unless HERMES_ENACTMENT_STAMP pins it. The census driver
%   pins it so a rerun that changed nothing produces byte-identical rows and a
%   diff that carries information.
emission_stamp(Stamp) :-
    (   getenv('HERMES_ENACTMENT_STAMP', Pinned), Pinned \== ''
    ->  atom_string(Pinned, Stamp)
    ;   get_time(Now),
        format_time(string(Stamp), '%FT%T%:z', Now)
    ).

warrant_dict(warrant(_, Source, Line, Text), _{
        source: SourceStr, line: Line, text: TextStr
    }) :- !,
    atom_string(Source, SourceStr),
    atom_string(Text, TextStr).
warrant_dict(evidence(Source, Line, Text), _{
        source: SourceStr, line: Line, text: TextStr
    }) :- !,
    atom_string(Source, SourceStr),
    atom_string(Text, TextStr).
warrant_dict(_, _{source: "", line: 0, text: ""}).

%!  form_warrant_dict(+Warrant, -Dict) is det.
%
%   The form's warrant, keeping the lesson it was read from. That lesson is
%   often not the row's lesson, and the field name says which is which so a
%   reader does not take one for the other.
form_warrant_dict(warrant(Lesson, Source, Line, Text), _{
        read_from_lesson: LessonStr, source: SourceStr, line: Line, text: TextStr
    }) :- !,
    atom_string(Lesson, LessonStr),
    atom_string(Source, SourceStr),
    atom_string(Text, TextStr).
form_warrant_dict(_, _{read_from_lesson: "", source: "", line: 0, text: ""}).

%!  inputs_json(+Inputs, +Steps, -JSON) is det.
%
%   The values the enactment ran on: one entry per pass when the lane derived
%   the passes, one entry per key when a caller supplied a binding list.
inputs_json([], Steps, JSON) :- !,
    findall(_{index: I, operand: OperandStr},
            ( member(step(I, _, Operand, _), Steps),
              json_text(Operand, OperandStr)
            ),
            JSON).
inputs_json(Inputs, _, JSON) :-
    is_list(Inputs),
    memberchk(input(_, _, _), Inputs), !,
    findall(_{key: KeyStr, value: ValueStr, provenance: ProvStr},
            ( member(input(Key, Value, Provenance), Inputs),
              json_text(Key, KeyStr),
              json_text(Value, ValueStr),
              json_text(Provenance, ProvStr)
            ),
            JSON).
inputs_json(Inputs, _, JSON) :-
    is_list(Inputs),
    memberchk(pass(_, _), Inputs), !,
    findall(_{pass: LabelStr, bindings: Bindings},
            ( member(pass(Label, Pairs), Inputs),
              json_text(Label, LabelStr),
              binding_rows(Pairs, Bindings)
            ),
            JSON).
inputs_json(Inputs, _, JSON) :-
    is_list(Inputs), !,
    binding_rows(Inputs, JSON).
inputs_json(Inputs, _, JSON) :-
    is_dict(Inputs), !,
    dict_pairs(Inputs, _, Pairs),
    inputs_json(Pairs, [], JSON).
inputs_json(Inputs, _, [JSON]) :-
    json_text(Inputs, Text),
    JSON = _{key: "input", value: Text}.

binding_rows(Pairs, Rows) :-
    findall(_{key: KeyStr, value: ValueStr},
            ( member(Key-Value, Pairs),
              json_text(Key, KeyStr),
              json_text(Value, ValueStr)
            ),
            Rows).

step_rows(Steps, Rows) :-
    findall(_{index: I, verb: VerbStr, operand: OperandStr, result: ResultStr},
            ( member(step(I, Verb, Operand, Result), Steps),
              json_text(Verb, VerbStr),
              json_text(Operand, OperandStr),
              json_text(Result, ResultStr)
            ),
            Rows).

artifact_dict(List, _{kind: "scene_and_record", parts: Parts}) :-
    is_list(List), List \== [], !,
    findall(Part,
            ( member(Member, List), artifact_dict(Member, Part) ),
            Parts).
artifact_dict(scene(Renderer, Term, Dict), _{
        kind: "scene", renderer: RendererStr, term: TermStr, scene: Dict
    }) :- !,
    json_text(Renderer, RendererStr),
    json_text(Term, TermStr).
artifact_dict(printed(Record), _{kind: "printed", record: RecordStr}) :- !,
    json_text(Record, RecordStr).
artifact_dict(Other, _{kind: "printed", record: Text}) :-
    json_text(Other, Text).

json_text(Value, Text) :-
    (   var(Value)
    ->  Text = ""
    ;   string(Value)
    ->  Text = Value
    ;   atom(Value)
    ->  atom_string(Value, Text)
    ;   number(Value)
    ->  format(string(Text), "~w", [Value])
    ;   term_string(Value, Text, [quoted(false), numbervars(true)])
    ).

%!  enactment_lesson_grade(+Lesson, -Grade) is det.
%
%   'IM-G4-U2-L4' -> "4". Kindergarten prints as "K", matching the recut.
enactment_lesson_grade(Lesson, Grade) :-
    atom_string(Lesson, S),
    (   sub_string(S, Before, _, _, "-U"),
        sub_string(S, 4, _, _, Rest),
        Len is Before - 4,
        sub_string(Rest, 0, Len, _, Grade)
    ->  true
    ;   Grade = ""
    ).

%!  enactment_row_json(+Enactment, -JSONText) is det.
%
%   One row as one line of JSON, no trailing newline.
enactment_row_json(Enactment, JSONText) :-
    enactment_row_dict(Enactment, Dict),
    with_output_to(string(JSONText),
                   json_write_dict(current_output, Dict, [width(0)])).

%!  enactment_emission_path(+Subclass, -Path) is det.
%
%   data/learningcommons/derived/lesson_enactments/<subclass>.jsonl, absolute.
enactment_emission_path(Subclass, Path) :-
    enactment_emission_dir(Dir),
    format(atom(File), '~w.jsonl', [Subclass]),
    directory_file_path(Dir, File, Path).

enactment_emission_dir(Dir) :-
    module_property(lesson_enactment, file(Self)),
    file_directory_name(Self, ImDir),          % curriculum/im
    file_directory_name(ImDir, CurriculumDir), % curriculum
    file_directory_name(CurriculumDir, Root),
    atomic_list_concat(
        [Root, 'data', 'learningcommons', 'derived', 'lesson_enactments'],
        '/', Dir).

%!  write_enactment_rows(+Subclass, +Enactments) is det.
%
%   Replace the subclass's emission file with one row per enactment, in the
%   order given. The file is rewritten whole rather than appended to, so a
%   rerun cannot leave a stale row from a form the lane has since retired.
write_enactment_rows(Subclass, Enactments) :-
    enactment_emission_path(Subclass, Path),
    file_directory_name(Path, Dir),
    make_directory_path(Dir),
    setup_call_cleanup(
        open(Path, write, Stream, [encoding(utf8)]),
        forall(member(E, Enactments),
               ( enactment_row_json(E, Line),
                 write(Stream, Line), nl(Stream) )),
        close(Stream)).
