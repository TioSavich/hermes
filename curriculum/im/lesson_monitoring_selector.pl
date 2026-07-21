/** <module> Descriptor-aware figure selector for monitoring charts
 *
 * Supersedes the bibkey-only join in lesson_monitoring_figures.pl while
 * keeping that bibkey match available as a low-priority provenance signal.
 *
 * The old join attached any docling figure whose article a lesson's
 * misconception happened to cite, regardless of what the figure actually
 * depicts. That mistook a citation for a representation match: a grade-1
 * make-ten lesson picked up the Gray (1999) epsilon-N limit diagram because
 * one of its misconceptions cites Gray, even though the figure carries
 * representation_language(none), domain(calculus), grade_bucket(tertiary).
 *
 * This selector normalizes a lesson's task signals (grade, standards,
 * operation, numerals, visual vocabulary, materials, lesson purpose), scores
 * candidate figures from docling_figure_rich/8 on what the figure depicts
 * (representation language, spatial elements, domain, grade band, strategy and
 * error topics, transcribed numerals), and gates every candidate through the
 * existing representation_grammar predicates. A candidate that the grammar
 * refuses can still surface as a literature exemplar, a labeled misconception,
 * or a misfit, but it can never become productive_fit.
 *
 * Productive render permission belongs to representation_grammar.pl, not here.
 * This module only ranks and labels; it invents no new grammar layer.
 */
:- module(lesson_monitoring_selector,
          [ lesson_task_signals/2,        % +Lesson, -Signals
            task_signals/2,               % +TaskSpec, -Signals (explicit)
            candidate_figure_score/4,     % +Signals, +CandidateId, -Score, -Components
            selected_figure/7,            % +LessonOrSignals, -CandidateId, -Status, -Score, -Evidence, -Refusals, -RenderPlan
            ranked_figures/2,             % +LessonOrSignals, -RankedRows
            selector_grade_band/2,        % +Grade, -Band  (exposed for tests)
            figure_bucket_band/2          % +Bucket, -Band  (exposed for tests)
          ]).

:- use_module(lessons('im/docling_figures_interpreted'),
              [ docling_figure_rich/8 ]).
:- use_module(strategies('render/representation_grammar'),
              [ representation_language/1,
                preferred_representation/3,
                standard_supports_representation/4,
                standard_warns_against_representation/4,
                valid_task_for_representation/2,
                representation_refusal/3,
                representation_render_status/2
              ]).
:- use_module(lessons('im/lesson_monitoring'),
              [ im_lesson/6,
                lesson_standard/4,
                lesson_strategy/4,
                lesson_misconception/4
              ]).
% Old bibkey join, retained only as a low-priority provenance signal.
:- use_module(lessons('im/lesson_monitoring_figures'),
              [ misconception_bibkey/2 ]).

:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(aggregate)).

% =====================================================================
% 1. Lesson task-signal normalization
% =====================================================================

%!  lesson_task_signals(+Lesson, -Signals) is det.
%
%   Normalize an IM lesson code into a task-signals record drawn from
%   lesson_monitoring (grade, standards, operations) plus the registered
%   visual-vocabulary hints. Signals is a dict-free term:
%
%     signals{ lesson, grade, band, standards, grammar_standards,
%              operations, domains, representations, numerals,
%              materials, purpose_terms, bibkeys }
%
%   grade is the integer (0 for kindergarten); band is the coarse
%   counting/grouping/place_value/fraction band the grammar reasons over.
lesson_task_signals(Lesson, Signals) :-
    ( im_lesson(Lesson, _, _, grade(Grade0), _, _) -> Grade = Grade0 ; Grade = unknown ),
    selector_grade_band(Grade, Band),
    findall(S, lesson_standard(Lesson, _, S, _), Ss0),
    sort(Ss0, Standards),
    maplist(normalize_standard, Standards, GStds0),
    exclude(==(none), GStds0, GStds1),
    sort(GStds1, GrammarStandards),
    findall(Op, lesson_strategy(Lesson, Op, _, _), Ops0),
    findall(Op, lesson_misconception(Lesson, Op, _, _), Ops1),
    append(Ops0, Ops1, OpsAll),
    sort(OpsAll, Operations),
    maplist(operation_domain, Operations, Domains0),
    sort(Domains0, Domains),
    lesson_representations(Grade, Operations, GrammarStandards, Representations),
    lesson_numerals(Lesson, Numerals),
    lesson_materials(Lesson, Materials),
    findall(BK,
            ( lesson_misconception(Lesson, _, Name, _),
              misconception_bibkey(Name, BK) ),
            BKs0),
    sort(BKs0, BibKeys),
    Signals = signals{
        lesson: Lesson,
        grade: Grade,
        band: Band,
        standards: Standards,
        grammar_standards: GrammarStandards,
        operations: Operations,
        domains: Domains,
        representations: Representations,
        numerals: Numerals,
        materials: Materials,
        purpose_terms: [],
        bibkeys: BibKeys
    }.

%!  task_signals(+TaskSpec, -Signals) is det.
%
%   Build a signals record from an explicit specification, so a caller (or a
%   test) can describe a task without depending on the loaded lesson corpus.
%   TaskSpec is a list of grade(G), standards([..]), operations([..]),
%   domains([..]), representations([..]), numerals([..]), materials([..]),
%   bibkeys([..]). Missing fields default sensibly.
task_signals(TaskSpec, Signals) :-
    is_list(TaskSpec),
    ( memberchk(grade(Grade), TaskSpec) -> true ; Grade = unknown ),
    selector_grade_band(Grade, Band),
    ( memberchk(standards(Standards0), TaskSpec) -> true ; Standards0 = [] ),
    sort(Standards0, Standards),
    maplist(normalize_standard, Standards, GStds0),
    exclude(==(none), GStds0, GStds1),
    sort(GStds1, GrammarStandards),
    ( memberchk(operations(Ops0), TaskSpec) -> true ; Ops0 = [] ),
    sort(Ops0, Operations),
    ( memberchk(domains(Doms0), TaskSpec)
    -> sort(Doms0, Domains)
    ;  ( maplist(operation_domain, Operations, Doms1), sort(Doms1, Domains) ) ),
    ( memberchk(representations(Reps0), TaskSpec)
    -> sort(Reps0, Representations)
    ;  lesson_representations(Grade, Operations, GrammarStandards, Representations) ),
    ( memberchk(numerals(Nums0), TaskSpec) -> sort(Nums0, Numerals) ; Numerals = [] ),
    ( memberchk(materials(Mats0), TaskSpec) -> sort(Mats0, Materials) ; Materials = [] ),
    ( memberchk(bibkeys(BKs0), TaskSpec) -> sort(BKs0, BibKeys) ; BibKeys = [] ),
    ( memberchk(lesson(L), TaskSpec) -> Lesson = L ; Lesson = explicit ),
    Signals = signals{
        lesson: Lesson,
        grade: Grade,
        band: Band,
        standards: Standards,
        grammar_standards: GrammarStandards,
        operations: Operations,
        domains: Domains,
        representations: Representations,
        numerals: Numerals,
        materials: Materials,
        purpose_terms: [],
        bibkeys: BibKeys
    }.

% --- grade / band helpers ---------------------------------------------------

%!  selector_grade_band(+Grade, -Band) is det.
selector_grade_band(0, counting) :- !.
selector_grade_band(1, grouping) :- !.
selector_grade_band(2, place_value) :- !.
selector_grade_band(3, fraction) :- !.
selector_grade_band(4, large_whole_number) :- !.
selector_grade_band(5, large_whole_number) :- !.
selector_grade_band(G, secondary) :- integer(G), G >= 6, !.
selector_grade_band(_, unknown).

% Coarse K-5 / 6-8 / 9-12 family used to compare against figure grade buckets.
selector_grade_family(G, elementary) :- integer(G), G >= 0, G =< 5, !.
selector_grade_family(G, middle) :- integer(G), G >= 6, G =< 8, !.
selector_grade_family(G, secondary) :- integer(G), G >= 9, !.
selector_grade_family(_, unknown).

%!  figure_bucket_band(+Bucket, -Family) is det.
figure_bucket_band('elementary (K–5)', elementary) :- !.
figure_bucket_band('middle (6–8)', middle) :- !.
figure_bucket_band('secondary (9–12)', secondary) :- !.
figure_bucket_band('preservice teachers', teacher) :- !.
figure_bucket_band('in-service teachers', teacher) :- !.
figure_bucket_band('tertiary / adult', tertiary) :- !.
figure_bucket_band(_, unspecified).

% =====================================================================
% 2. Standard / operation / representation mapping
% =====================================================================

% Map a loaded standard code (CCSS '1.OA.B.3', Indiana '1.CA.1', or the IM
% anchor) to the grammar's standard atom vocabulary, or none if unmapped.
normalize_standard(Std, Grammar) :-
    ( indiana_grammar_standard(Std, Grammar)
    -> true
    ;  ccss_grammar_standard(Std, Grammar)
    -> true
    ;  Grammar = none ).

indiana_grammar_standard('K.NS.3', k_ns_3).
indiana_grammar_standard('K.NS.4', k_ns_4).
indiana_grammar_standard('K.NS.7', k_ns_7).
indiana_grammar_standard('1.NS.2', '1_ns_2').
indiana_grammar_standard('1.CA.1', '1_ca_1').
indiana_grammar_standard('1.CA.3', '1_ca_3').
indiana_grammar_standard('2.CA.2', '2_ca_2').
indiana_grammar_standard('3.NS.2', '3_ns_2').
indiana_grammar_standard('3.NS.5', '3_ns_5').
indiana_grammar_standard('4.NF.3', '4_nf_3').
indiana_grammar_standard('3.CA.3', '3_ca_3_4').
indiana_grammar_standard('3.CA.4', '3_ca_3_4').

% A few CCSS codes used by the K-5 corpus map onto the same grammar atoms.
ccss_grammar_standard('1.OA.C.6', '1_ca_1').
ccss_grammar_standard('1.NBT.B.2', '1_ns_2').
ccss_grammar_standard('1.NBT.C.4', '1_ca_3').
ccss_grammar_standard('2.NBT.B.5', '2_ca_2').
ccss_grammar_standard('3.NF.A.1', '3_ns_2').
ccss_grammar_standard('3.NF.A.3', '3_ns_5').
ccss_grammar_standard('3.G.A.2', '3_g_a_2').
ccss_grammar_standard('4.NF.B.3', '4_nf_3').
ccss_grammar_standard('3.OA.A.3', '3_ca_3_4').
ccss_grammar_standard('4.NBT.B.4', '4_nbt_b_4').
ccss_grammar_standard('6.EE.B.5', '6_ee_b_5').

% Operation -> registry domain tag (matches docling coding{domains}).
operation_domain(addition, whole_number).
operation_domain(subtraction, whole_number).
operation_domain(multiplication, whole_number).
operation_domain(division, whole_number).
operation_domain(fraction, fraction).
operation_domain(geometry, geometry).
operation_domain(Other, Other).

% The representations the grammar would prefer for this lesson, derived from
% the standards it supports and from the grade band. This is the lesson's
% "expected visual vocabulary" used to score figures, NOT a render decision.
lesson_representations(Grade, _Operations, GrammarStandards, Representations) :-
    selector_grade_family(Grade, _),
    grade_atom(Grade, GradeAtom),
    findall(R,
            ( member(Std, GrammarStandards),
              standard_supports_representation(Std, R, _Grade, _Purpose) ),
            FromStds),
    findall(R,
            ( band_default_representation(Grade, R) ),
            FromBand),
    append(FromStds, FromBand, R0),
    ( R0 == []
    -> findall(R, band_default_representation_relaxed(GradeAtom, R), R0b),
       sort(R0b, Representations)
    ;  sort(R0, Representations) ).

grade_atom(0, kindergarten) :- !.
grade_atom(N, Atom) :- integer(N), N >= 1, atom_concat('grade_', N, Atom), !.
grade_atom(_, unknown).

% Band-level default visual vocabulary (used in addition to standard-driven).
band_default_representation(0, set_grouping).
band_default_representation(1, set_grouping).
band_default_representation(1, base_ten_blocks).
band_default_representation(2, base_ten_blocks).
band_default_representation(2, place_value_chart).
band_default_representation(3, fraction_bars).
band_default_representation(3, area_model).
band_default_representation(4, number_line).
band_default_representation(4, place_value_chart).
band_default_representation(5, number_line).
band_default_representation(5, place_value_chart).

band_default_representation_relaxed(_, set_grouping).
band_default_representation_relaxed(_, number_line).

% =====================================================================
% 3. Lesson numerals and materials (visual vocabulary)
% =====================================================================

% Numerals: integers mentioned in the lesson's strategy/misconception Info.
% Kept conservative; the selector tolerates an empty set.
lesson_numerals(Lesson, Numerals) :-
    findall(N,
            ( ( lesson_strategy(Lesson, _, _, Info)
              ; lesson_misconception(Lesson, _, Info0, _), Info = Info0 ),
              term_integers(Info, Ns),
              member(N, Ns) ),
            Ns0),
    sort(Ns0, Numerals).

term_integers(Term, Ints) :-
    findall(I, ( sub_term(Sub, Term), integer(Sub), I = Sub ), Is),
    sort(Is, Ints).

sub_term(T, T).
sub_term(Sub, T) :-
    compound(T),
    arg(_, T, A),
    sub_term(Sub, A).

% Materials inferred from the lesson's grade band default (the teacher guides
% name connecting cubes / counters / ten-frames for early number). The
% selector treats materials as a soft hint, defaulting to band vocabulary.
lesson_materials(Lesson, Materials) :-
    ( im_lesson(Lesson, _, _, grade(Grade), _, _) -> true ; Grade = unknown ),
    findall(M, band_material(Grade, M), Ms),
    sort(Ms, Materials).

band_material(0, counters).
band_material(0, ten_frame).
band_material(1, counters).
band_material(1, connecting_cubes).
band_material(1, ten_frame).
band_material(2, base_ten_blocks).
band_material(3, fraction_strips).
band_material(4, number_line).
band_material(5, number_line).
band_material(_, none).

% =====================================================================
% 4. Scoring
% =====================================================================

%!  candidate_figure_score(+Signals, +CandidateId, -Score, -Components) is det.
%
%   CandidateId is the figure RelPath. Components is a list of
%   component(Name, Weight) for transparency. The score is a plain integer.
candidate_figure_score(Signals, CandidateId, Score, Components) :-
    docling_figure_rich(CandidateId, BibKey, GradeBucket, _Hybrid,
                        Core, Coding, _HybridDetails, _Strategy),
    RepLang = Core.representation_language,
    Spatial = Core.spatial_elements,
    Domains = Coding.domains,
    ErrTopics = Coding.error_topics,
    StratTopics = Coding.strategy_topics,
    % representation-language match against the lesson's expected vocabulary
    score_rep_language(Signals, RepLang, RepScore),
    % spatial-element overlap with the expected representation's objects
    score_spatial(Signals, RepLang, Spatial, SpatialScore),
    % domain overlap
    score_domain(Signals, Domains, DomainScore),
    % grade-band agreement
    score_grade(Signals, GradeBucket, GradeScore),
    % strategy / error topic overlap with the lesson's operations
    score_topics(Signals, StratTopics, ErrTopics, TopicScore),
    % transcribed-math / numeral overlap
    score_numerals(Signals, Core.transcribed_math, NumScore),
    % low-priority provenance: the old bibkey join
    score_bibkey(Signals, BibKey, BibScore),
    Score is RepScore + SpatialScore + DomainScore + GradeScore
             + TopicScore + NumScore + BibScore,
    Components = [
        component(representation_language, RepScore),
        component(spatial_elements, SpatialScore),
        component(domain, DomainScore),
        component(grade_band, GradeScore),
        component(topics, TopicScore),
        component(transcribed_numerals, NumScore),
        component(bibkey_provenance, BibScore)
    ].

% Representation language match: +40 for a representation the lesson expects;
% a strong negative for a different concrete representation; 0 for none.
score_rep_language(Signals, RepLang, Score) :-
    Reps = Signals.representations,
    ( RepLang == none
    -> Score = 0
    ;  ( memberchk(RepLang, Reps)
       -> Score = 40
       ;  Score = -20 ) ).

% Spatial-element overlap with the canonical objects of the matched language.
score_spatial(Signals, RepLang, Spatial, Score) :-
    Reps = Signals.representations,
    ( RepLang \== none, memberchk(RepLang, Reps)
    -> length(Spatial, NS),
       ( NS > 0 -> Score = 5 ; Score = 0 )
    ;  Score = 0 ).

% Domain overlap: +25 per shared domain (capped), -15 if the figure's domains
% are entirely disjoint from the lesson's and the lesson has a clear domain.
score_domain(Signals, FigDomains, Score) :-
    LessonDomains = Signals.domains,
    intersection(LessonDomains, FigDomains, Shared),
    ( Shared \== []
    -> Score = 25
    ;  ( LessonDomains \== [], FigDomains \== []
       -> Score = -15
       ;  Score = 0 ) ).

% Grade-band agreement: +20 same family, -15 elementary-vs-tertiary mismatch.
score_grade(Signals, GradeBucket, Score) :-
    selector_grade_family(Signals.grade, LessonFamily),
    figure_bucket_band(GradeBucket, FigFamily),
    ( LessonFamily == FigFamily, LessonFamily \== unknown
    -> Score = 20
    ;  grade_family_penalty(LessonFamily, FigFamily, Score) ).

grade_family_penalty(elementary, tertiary, -30) :- !.
grade_family_penalty(elementary, secondary, -20) :- !.
grade_family_penalty(elementary, middle, -8) :- !.
grade_family_penalty(_, _, 0).

% Strategy / error topic overlap with the lesson's operation words.
score_topics(Signals, StratTopics, ErrTopics, Score) :-
    Ops = Signals.operations,
    append(StratTopics, ErrTopics, AllTopics),
    ( ops_mention_topic(Ops, AllTopics)
    -> Score = 10
    ;  Score = 0 ).

ops_mention_topic(Ops, Topics) :-
    member(Op, Ops),
    atom_string(Op, OpStr),
    member(Topic, Topics),
    ( sub_atom_icasechk(Topic, OpStr) -> true ; fail ),
    !.

sub_atom_icasechk(Topic, Needle) :-
    ( atom(Topic) -> TopicA = Topic ; atom_string(TopicA, Topic) ),
    downcase_atom(TopicA, TopicL),
    downcase_atom(Needle, NeedleL),
    sub_atom(TopicL, _, _, _, NeedleL).

% Transcribed-math overlap: +8 if any lesson numeral appears in the figure's
% transcribed math string (the Godino "10 + 6 = 16" case).
score_numerals(Signals, TranscribedMath, Score) :-
    Numerals = Signals.numerals,
    ( Numerals == []
    -> Score = 0
    ;  ( TranscribedMath == none
       -> Score = 0
       ;  ( atom_string(TranscribedMath, TMStr),
            ( member(N, Numerals), number_string(N, NStr), sub_string(TMStr, _, _, _, NStr)
            -> Score = 8
            ;  Score = 0 ) ) ) ).

% Low-priority provenance: the old bibkey join contributes a small +3 only.
score_bibkey(Signals, BibKey, Score) :-
    ( memberchk(BibKey, Signals.bibkeys) -> Score = 3 ; Score = 0 ).

% =====================================================================
% 5. Grammar gating + status assignment
% =====================================================================

%!  selected_figure(+LessonOrSignals, -CandidateId, -Status, -Score, -Evidence, -Refusals, -RenderPlan) is nondet.
%
%   For each candidate figure, classify it against the lesson signals and the
%   representation grammar. Status is one of:
%     productive_fit          - representation match, grammar accepts, no refusal
%     literature_exemplar_only- a real student-work figure that documents the
%                               topic but cannot model the lesson's exact task
%                               (e.g. grammar has no productive task here, or
%                               the figure is from another grade family)
%     labeled_misconception   - a hybrid transplant or named deformation
%     misfit                  - representation conflicts or domain mismatch
%     uninterpreted           - representation_language(none), no model possible
%
%   Only productive_fit may become an unlabeled productive diagram. A grammar
%   refusal forces a non-productive status.
selected_figure(LessonOrSignals, CandidateId, Status, Score, Evidence, Refusals, RenderPlan) :-
    as_signals(LessonOrSignals, Signals),
    docling_figure_rich(CandidateId, BibKey, GradeBucket, IsHybrid,
                        Core, Coding, HybridDetails, _Strategy),
    candidate_figure_score(Signals, CandidateId, Score, Components),
    classify_candidate(Signals, CandidateId, BibKey, GradeBucket, IsHybrid,
                       Core, Coding, HybridDetails, Score,
                       Status, Refusals, RenderPlan0),
    Evidence = evidence{
        score_components: Components,
        representation_language: Core.representation_language,
        domains: Coding.domains,
        grade_bucket: GradeBucket,
        bibkey: BibKey,
        is_hybridized_transplant: IsHybrid
    },
    RenderPlan = RenderPlan0.

as_signals(Signals, Signals) :- is_dict(Signals, signals), !.
as_signals(TaskSpec, Signals) :- is_list(TaskSpec), !, task_signals(TaskSpec, Signals).
as_signals(Lesson, Signals) :- lesson_task_signals(Lesson, Signals).

% --- classification ---------------------------------------------------------
%
% classify_candidate/12 computes Status (an output) deterministically from the
% candidate's discriminants. Status MUST never be consulted to choose a clause:
% the hybrid-transplant and representation_language(none) guards gate on their
% real discriminants (the IsHybrid flag and Core.representation_language) in the
% body, BEFORE Status is bound, so a caller that pre-binds Status to
% productive_fit cannot slip past those gates. (An earlier version put the
% status atom in the clause head; a pre-bound productive_fit then failed head
% unification and skipped the hybrid guard. Do not reintroduce that.)

classify_candidate(Signals, CandId, BibKey, Bucket, IsHybrid,
                   Core, Coding, HybridDetails, Score,
                   Status, Refusals, RenderPlan) :-
    (   IsHybrid == true
    ->  classify_hybrid(HybridDetails, Status, Refusals, RenderPlan)
    ;   Core.representation_language == none
    ->  classify_uninterpreted(Status, Refusals, RenderPlan)
    ;   classify_interpreted(Signals, CandId, BibKey, Bucket,
                             Core, Coding, Score,
                             Status, Refusals, RenderPlan)
    ).

% A hybridized transplant is always a labeled misconception, never
% productive_fit, regardless of score or requested status.
classify_hybrid(HybridDetails, labeled_misconception, Refusals, RenderPlan) :-
    Refusals = [refusal(hybridized_transplant, HybridDetails)],
    RenderPlan = render_plan{
        kind: labeled_misconception,
        source: literature_png,
        productive: false,
        note: 'hybridized model transplant; render only as labeled misconception'
    }.

classify_uninterpreted(uninterpreted, Refusals, RenderPlan) :-
    Refusals = [refusal(no_representation_language, none)],
    RenderPlan = render_plan{
        kind: uninterpreted,
        source: literature_png,
        productive: false,
        note: 'figure carries no interpretable representation language'
    }.

classify_interpreted(Signals, _CandId, _BibKey, GradeBucket,
                     Core, Coding, _Score,
                     Status, Refusals, RenderPlan) :-
    RepLang = Core.representation_language,
    Reps = Signals.representations,
    grammar_refusals(Signals, RepLang, GrammarRefusals),
    selector_grade_family(Signals.grade, LessonFamily),
    figure_bucket_band(GradeBucket, FigFamily),
    intersection(Signals.domains, Coding.domains, SharedDomains),
    (   GrammarRefusals \== []
    ->  Status = literature_exemplar_only,
        Refusals = GrammarRefusals,
        RenderPlan = render_plan{
            kind: literature_exemplar,
            source: literature_png,
            productive: false,
            note: 'grammar refuses this representation for the task; show as exemplar only'
        }
    ;   \+ memberchk(RepLang, Reps)
    ->  Status = misfit,
        Refusals = [refusal(representation_not_expected_for_lesson, RepLang)],
        RenderPlan = render_plan{
            kind: misfit,
            source: literature_png,
            productive: false,
            note: 'figure representation is not in the lesson visual vocabulary'
        }
    ;   ( LessonFamily \== FigFamily, member(FigFamily, [tertiary, secondary]) )
    ->  Status = literature_exemplar_only,
        Refusals = [refusal(grade_family_mismatch, FigFamily)],
        RenderPlan = render_plan{
            kind: literature_exemplar,
            source: literature_png,
            productive: false,
            note: 'matched representation but wrong grade family; exemplar only'
        }
    ;   SharedDomains == [], Signals.domains \== []
    ->  Status = misfit,
        Refusals = [refusal(domain_mismatch, Coding.domains)],
        RenderPlan = render_plan{
            kind: misfit,
            source: literature_png,
            productive: false,
            note: 'representation matches but figure domain is disjoint from lesson'
        }
    ;   % representation in vocabulary, grammar accepts, grade family agrees,
        % domain overlaps -> the only path to productive_fit
        Status = productive_fit,
        Refusals = [],
        RenderPlan = render_plan{
            kind: productive_diagram,
            source: svg_analogue,
            productive: true,
            note: 'representation grammar accepts; lesson-exact analogue may be generated'
        }
    ).

% Ask the representation grammar whether it has any productive task this
% representation can denote for the lesson, and surface refusals where the
% lesson band would push the representation past its grammar limits.
grammar_refusals(Signals, RepLang, Refusals) :-
    ( RepLang == none
    -> Refusals = []
    ;  findall(refusal(grammar, Reason),
               band_grammar_refusal(Signals, RepLang, Reason),
               Rs0),
       sort(Rs0, Refusals) ).

% A kindergarten counting/subitizing lesson refuses number-line-as-default.
band_grammar_refusal(Signals, number_line, Reason) :-
    Signals.grade == 0,
    representation_refusal(number_line, kindergarten_counting_collection(10), reason(Reason)).
band_grammar_refusal(Signals, number_line, Reason) :-
    Signals.grade == 0,
    representation_refusal(number_line, subitizing(5), reason(Reason)).

% A grade 4/5 large-whole-number lesson refuses base-ten blocks above 9999.
band_grammar_refusal(Signals, base_ten_blocks, Reason) :-
    memberchk(Signals.band, [large_whole_number]),
    large_lesson_numeral(Signals, N),
    N > 9999,
    representation_refusal(base_ten_blocks, whole_number(N), reason(Reason)).

large_lesson_numeral(Signals, N) :-
    member(N, Signals.numerals),
    integer(N),
    N > 9999.
% If no explicit numeral is carried, a large-whole-number lesson still refuses
% base-ten blocks by the band's stated magnitude (the standard warns against
% physical block vocabulary at this grade).
large_lesson_numeral(Signals, 10000) :-
    \+ ( member(M, Signals.numerals), integer(M), M > 9999 ),
    memberchk('4_nbt_b_4', Signals.grammar_standards).

% =====================================================================
% 6. Ranking
% =====================================================================

%!  ranked_figures(+LessonOrSignals, -RankedRows) is det.
%
%   All candidate figures for the lesson, ranked by descending score. Each row
%   is row(Score, Status, CandidateId, Refusals). productive_fit rows with the
%   highest score lead; misfits and exemplars remain visible below them.
ranked_figures(LessonOrSignals, RankedRows) :-
    as_signals(LessonOrSignals, Signals),
    findall(row(NegScore, Status, CandidateId, Refusals),
            ( selected_figure(Signals, CandidateId, Status, Score, _Ev, Refusals, _RP),
              NegScore is -Score ),
            Rows0),
    sort(Rows0, RowsSorted),
    maplist(unneg_row, RowsSorted, RankedRows).

unneg_row(row(NegScore, Status, CandidateId, Refusals),
          row(Score, Status, CandidateId, Refusals)) :-
    Score is -NegScore.
