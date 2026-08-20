/** <module> Lesson-specific deformation monitoring charts
 *
 * Each served fraction chart joins lesson-owned host and fraction citations to
 * a licensed deformation renderer. Circle, rectangle, and bar hosts use the
 * partition/error renderers; number-line and set hosts use paired comparison
 * scenes. A lesson without the required evidence receives a named refusal.
 *
 * Load through paths.pl.
 */

:- module(lesson_deformation_chart,
          [ lesson_chart_lesson/5,           % ?Code, ?Title, ?Standards, ?Hosts, ?Fractions
            charted_lesson_code/1,            % ?Code
            chart_provenance/2,               % ?Code, -Provenance
            chart_provenance_note/2,          % ?Provenance, ?Note
            chart_provenance_census/1,        % -Dict
            chart_refusal/3,                  % +Code, -Reason, -Message
            chart_fraction/2,                 % ?Code, ?frac(M,N)
            chart_host/2,                     % ?Code, ?Host
            lesson_likely_deformation/4,       % ?Code, ?Host, ?frac(M,N), ?Deformation
            division_chart_lesson/1,          % ?Code
            lesson_division_deformation_chart/2, % +Code, -Chart
            gated_as_misconception/2,          % +Deformation, -Evidence
            productive_scene_for_lesson/4,     % +Code, +Host, +frac(M,N), -Dict
            deformation_scene_for_lesson/5,    % +Code, +Host, +frac(M,N), +Deformation, -Dict
            monitoring_chart/2,                % +Code, -Chart
            monitoring_chart_to_file/2         % +Chart, +Path
          ]).

:- use_module(library(http/json), [json_write_dict/3]).
:- use_module(library(lists)).

:- use_module(render(representation_grammar)).
:- use_module(render(attested_deformations)).
:- use_module(render(parametric_partition_deformation)).
:- use_module(render(parametric_fraction_errors)).
:- use_module(render(set_grouping_scene)).
:- use_module(render(fraction_comparison_scene), [fraction_comparison_compare_json/2]).
:- use_module(lessons('im/generated/default_fill_lessons')).
:- use_module(lessons('im/generated/lesson_representation_evidence')).
:- use_module(lessons('im/lesson_monitoring'),
              [ im_lesson/6,
                lesson_standard/4,
                lesson_strategy/4
              ]).

% =========================================================================
% 1. The encoded lessons.
% =========================================================================
%
% lesson_chart_lesson(Code, Title, Standards, Hosts, Fractions).
%   Code      : the IM lesson code, matching curriculum/im/grade_3.pl.
%   Title     : the lesson's own title.
%   Standards : the standards the teacher guide lists as "Addressing".
%   Hosts     : circle, rectangle, bar, number_line, or set.
%   Fractions : cited lesson fractions, capped at six, as frac(M,N).
%
% Three rows remain hand-authored. Other served rows join the generated lesson
% evidence store; chart_provenance/2 names the source class.
%
% Three grade-3 IM fractions lessons (unit 5), read off their teacher guides:
%
%   IM-G3-U5-L1  "Name the Parts"            3.G.A.2, 3.NF.A.1
%       partitions rectangles and circles into 2,3,4,6,8 equal parts.
%   IM-G3-U5-L2  "Name Parts as Fractions"   3.G.A.2, 3.NF.A.1
%       partitions shapes and fraction strips into halves/thirds/fourths/
%       sixths/eighths, names each part as the unit fraction 1/N.
%   IM-G3-U5-L15 "Compare Fractions, Same Denominator" 3.NF.A.3.d
%       compares fractions with the same denominator on area diagrams,
%       fraction strips, and number lines (fourths and sixths in the task set).

hand_authored_chart_lesson('IM-G3-U5-L1', "Name the Parts",
        ['3.G.A.2', '3.NF.A.1'],
        [rectangle, circle],
        [frac(1,2), frac(1,3), frac(1,4), frac(1,6), frac(1,8)]).
hand_authored_chart_lesson('IM-G3-U5-L2', "Name Parts as Fractions",
        ['3.G.A.2', '3.NF.A.1'],
        [rectangle, circle, bar],
        [frac(1,2), frac(1,3), frac(1,4), frac(1,6), frac(1,8)]).
hand_authored_chart_lesson('IM-G3-U5-L15', "Compare Fractions with the Same Denominator",
        ['3.NF.A.3.d'],
        [bar, circle],
        [frac(1,4), frac(1,6)]).

lesson_chart_lesson(Code, Title, Standards, Hosts, Fractions) :-
    hand_authored_chart_lesson(Code, Title, Standards, Hosts, Fractions).
lesson_chart_lesson(Code, Title, Standards, Hosts, Fractions) :-
    default_fill_lessons:default_fill_lesson(Code, Title, Standards),
    \+ hand_authored_chart_lesson(Code, _, _, _, _),
    evidence_hosts(Code, Hosts),
    Hosts = [_|_],
    evidence_fractions(Code, Fractions),
    Fractions = [_|_].

evidence_hosts(Code, Hosts) :-
    findall(Host,
            lesson_representation_evidence:lesson_host_evidence(
                Code, Host, _, _),
            Hosts0),
    sort(Hosts0, Hosts).

evidence_fractions(Code, Fractions) :-
    findall(Frac,
            lesson_representation_evidence:lesson_fraction_evidence(
                Code, Frac, _, _, _),
            Fractions0),
    sort(Fractions0, Unique),
    predsort(compare_fraction, Unique, Ordered),
    take_at_most(6, Ordered, Fractions).

compare_fraction(Order, frac(M1,N1), frac(M2,N2)) :-
    compare(DenominatorOrder, N1, N2),
    ( DenominatorOrder == (=) -> compare(Order, M1, M2)
    ; Order = DenominatorOrder
    ).

take_at_most(0, _, []) :- !.
take_at_most(_, [], []) :- !.
take_at_most(N, [Head|Tail], [Head|Taken]) :-
    Next is N - 1,
    take_at_most(Next, Tail, Taken).

%!  charted_lesson_code(?Code) is nondet.
%
%   Every lesson code this module charts: the fraction charts plus the one
%   division chart. The second clause subtracts any overlap, so enumerating
%   this predicate never reports a code twice even if the generated inventory
%   later stops excluding the division lesson. Callers that need the covered
%   list read it here rather than rebuilding the disjunction, so the module and
%   its consumers cannot answer differently about what "charted" covers.
charted_lesson_code(Code) :-
    lesson_chart_lesson(Code, _, _, _, _).
charted_lesson_code(Code) :-
    division_chart_lesson(Code),
    \+ lesson_chart_lesson(Code, _, _, _, _).

chart_provenance(Code, Provenance) :-
    charted_lesson_code(Code),
    (   hand_authored_chart_lesson(Code, _, _, _, _)
    ->  Provenance = hand_authored
    ;   division_chart_lesson(Code)
    ->  Provenance = division
    ;   Provenance = evidence
    ).

%!  chart_provenance_note(?Provenance, ?Note) is det.
%
%   What the provenance value means, in the words a reader of the payload needs.
chart_provenance_note(hand_authored,
    "Hosts and unit fractions are read off this lesson's teacher guide.").
chart_provenance_note(evidence,
    "Hosts and fractions cite this lesson's guide text or its compiled evidence rows.").
chart_provenance_note(division,
    "Division expressions cite compiled task instances from this lesson's teacher guide.").

%!  chart_provenance_census(-Census) is det.
%
%   How many charted lesson codes carry quantities read from a teacher guide and
%   how many carry the default set. Counted from the rows, so a surface never
%   has to quote a number the data could move underneath it.
chart_provenance_census(_{ hand_authored: HandAuthored,
                           evidence: Evidence,
                           division: Division,
                           total: Total }) :-
    findall(Provenance,
            ( charted_lesson_code(Code),
              chart_provenance(Code, Provenance) ),
            Provenances),
    aggregate_all(count, member(hand_authored, Provenances), HandAuthored),
    aggregate_all(count, member(evidence, Provenances), Evidence),
    aggregate_all(count, member(division, Provenances), Division),
    length(Provenances, Total).

chart_refusal(Code, no_deformation_chart,
              "No lesson-owned host representation was found for this lesson code.") :-
    default_fill_lessons:default_fill_lesson(Code),
    \+ hand_authored_chart_lesson(Code, _, _, _, _),
    evidence_hosts(Code, []).
chart_refusal(Code, fraction_operands_unrecoverable,
              "No fraction operands were recoverable from this lesson's cited sources.") :-
    default_fill_lessons:default_fill_lesson(Code),
    \+ hand_authored_chart_lesson(Code, _, _, _, _),
    evidence_hosts(Code, [_|_]),
    evidence_fractions(Code, []).
chart_refusal(Code, no_deformation_chart,
              "No deformation chart is available for this lesson code.") :-
    \+ default_fill_lessons:default_fill_lesson(Code),
    \+ hand_authored_chart_lesson(Code, _, _, _, _),
    \+ division_chart_lesson(Code).

chart_fraction(Code, Frac) :-
    lesson_chart_lesson(Code, _, _, _, Fractions),
    member(Frac, Fractions).

chart_host(Code, Host) :-
    lesson_chart_lesson(Code, _, _, Hosts, _),
    member(Host, Hosts).

% =========================================================================
% 2. The likely deformations for a lesson's representation + fraction.
% =========================================================================
%
% lesson_likely_deformation(Code, Host, frac(M,N), Deformation).
%   The deformations to watch for on this lesson's host, for this fraction.
%   Deformation is one of:
%     transplant(Rule)               -- a foreign partition rule on the host
%     equipartition_failure(ErrType) -- the host's own primitive, applied wrongly
%
% Only deformations attested for the host are surfaced (transplants gated by
% parametric_partition_deformation:attested_transplant_pair/2; equipartition
% failures gated by the host being a fraction_error_host the corpus error
% buckets cover). The fraction is the lesson's own, so the chart is "the botches
% on 1/N", parametric over N.

lesson_likely_deformation(Code, Host, Frac, transplant(Rule)) :-
    chart_fraction(Code, Frac),
    chart_host(Code, Host),
    host_for_partition_layer(Host, PartitionHost),
    % only transplants anchored to a real attested witness for this host
    parametric_partition_deformation:attested_transplant_pair(PartitionHost, transplant(Rule)).

lesson_likely_deformation(Code, Host, Frac, equipartition_failure(ErrorType)) :-
    chart_fraction(Code, Frac),
    chart_host(Code, Host),
    host_for_error_layer(Host, ErrorHost),
    likely_equipartition_error(ErrorType),
    % the error must actually have corpus-grounded evidence for this host+fraction
    parametric_fraction_errors:error_evidence(ErrorType, ErrorHost, Frac, _Evidence).

lesson_likely_deformation(Code, number_line, Frac,
                          number_line_count_marks_not_intervals) :-
    chart_host(Code, number_line),
    chart_fraction(Code, Frac).
lesson_likely_deformation(Code, set, Frac, set_model_subset_size_focus) :-
    chart_host(Code, set),
    chart_fraction(Code, Frac).

% The two equipartition failures most worth a teacher's attention when a child
% first models a unit fraction: the parts come out unequal, or the count is off.
% (shade_wrong_count and wrong_referent_whole are available in the error layer
% but are less specific to the "first partition" lessons here.)
likely_equipartition_error(unequal_partition).
likely_equipartition_error(miscount_partition).

% Map a lesson host to the host atom the partition (transplant) layer uses. The
% lesson's "rectangle" and "bar" both have their licensed home in the rectangle
% area model, so they share the radial-on-them transplant; the circle has the
% vertical/grid transplants.
host_for_partition_layer(circle, circle).
host_for_partition_layer(rectangle, rectangle).
host_for_partition_layer(bar, rectangle).

% Map a lesson host to the host atom the equipartition-error layer uses.
host_for_error_layer(circle, circle).
host_for_error_layer(rectangle, area).
host_for_error_layer(bar, bar).

% =========================================================================
% The misconception gate.
% =========================================================================
%
% gated_as_misconception(Deformation, Evidence): a deformation is admitted to a
% monitoring chart ONLY if it routes through the grammar's misconception lane and
% carries misconception evidence (mode: misconception). This is the discipline
% representation_grammar enforces: a deformation is only ever a labeled
% misconception, never an unlabeled productive diagram. We do not edit the
% grammar; we consult it.
%
%   - transplant(Rule, Host): grounded by
%     representation_grammar:deformation_spec_evidence(hybridization, Spec, _, Ev),
%     the same hybridization rows the parametric transplant layer generalises.
%   - equipartition_failure(ErrType, Host, Frac): grounded by
%     parametric_fraction_errors:error_evidence/4, whose evidence dict carries
%     mode: misconception and the violated grammar blend entailment.

gated_as_misconception(transplant(Rule, Host), Evidence) :-
    rule_host_to_grammar_spec(Rule, Host, Spec, Case),
    representation_grammar:deformation_spec_evidence(hybridization, Spec, Case, Evidence),
    get_dict(mode, Evidence, misconception).

gated_as_misconception(equipartition_failure(ErrorType, Host, Frac), Evidence) :-
    host_for_error_layer(Host, ErrorHost),
    parametric_fraction_errors:error_evidence(ErrorType, ErrorHost, Frac, Evidence),
    get_dict(mode, Evidence, misconception).

% rule_host_to_grammar_spec(Rule, Host, Spec, Case): the grammar's hybridization
% deformation_spec_evidence key for a (foreign rule, host) transplant. Matches
% the four hybridization rows in representation_grammar.pl.
rule_host_to_grammar_spec(vertical, circle,
        vertical_partition_on_circle,
        hybridization_case(rectangle_vertical_partition, circle_region)).
rule_host_to_grammar_spec(grid, circle,
        % a grid rule on a circle reads as the circle-radial-on-rectangle's
        % mirror; the grammar's circle-region transplant row is the closest
        % attested key. The corpus witness is the grid-on-circle figure (Cadez).
        vertical_partition_on_circle,
        hybridization_case(rectangle_vertical_partition, circle_region)).
rule_host_to_grammar_spec(radial, rectangle,
        circle_partition_on_rectangle,
        hybridization_case(circle_radial_partition, rectangle_area_model)).
rule_host_to_grammar_spec(radial, bar,
        circle_partition_on_rectangle,
        hybridization_case(circle_radial_partition, rectangle_area_model)).
rule_host_to_grammar_spec(radial, set,
        radial_partition_on_set,
        hybridization_case(circle_radial_partition, fractional_set_model)).

% =========================================================================
% 3a. The productive scene for a lesson's (host, fraction).
% =========================================================================
%
% productive_scene_for_lesson(Code, Host, frac(M,N), Dict): the CORRECT 1/N model
% in the host's own licensed partition rule, three B/M/E frames. Uses the
% parametric productive generator; the denominator is the lesson fraction's N.

productive_scene_for_lesson(Code, Host, frac(1, N), Dict) :-
    chart_host(Code, Host),
    host_for_partition_layer(Host, PartitionHost),
    parametric_partition_deformation:productive_partition_scene(PartitionHost, N, Dict).

% =========================================================================
% 3b. The deformation scene for a lesson's (host, fraction, deformation).
% =========================================================================
%
% deformation_scene_for_lesson(Code, Host, frac(M,N), Deformation, Dict): the
% labeled-misconception scene for this deformation on this fraction. Routes to
% the transplant generator or the equipartition-failure generator, and asserts
% the gate (gated_as_misconception/2) so a scene that the grammar does not admit
% as a misconception is never produced.

deformation_scene_for_lesson(Code, Host, Frac, transplant(Rule), Dict) :-
    lesson_likely_deformation(Code, Host, Frac, transplant(Rule)),
    host_for_partition_layer(Host, PartitionHost),
    Frac = frac(1, N),
    gated_as_misconception(transplant(Rule, PartitionHost), _Evidence),
    parametric_partition_deformation:deformed_partition_scene(
        PartitionHost, N, transplant(Rule), Dict).

deformation_scene_for_lesson(Code, Host, Frac, equipartition_failure(ErrorType), Dict) :-
    lesson_likely_deformation(Code, Host, Frac, equipartition_failure(ErrorType)),
    host_for_error_layer(Host, ErrorHost),
    gated_as_misconception(equipartition_failure(ErrorType, Host, Frac), _Evidence),
    parametric_fraction_errors:deformed_fraction_error_scene(
        ErrorHost, Frac, ErrorType, Dict).

% =========================================================================
% 3c. The assembled monitoring chart.
% =========================================================================
%
% monitoring_chart(Code, Chart): one dict per lesson. For every (host, fraction)
% the lesson uses, the productive scene plus every likely deformation scene. The
% chart is the artifact a teacher reads: "for this lesson's fractions, on these
% representations, watch for these botches."

% IM-G6-U4-L10 is a division lesson, not a fraction-partition lesson.  Its
% teacher-guide tasks are therefore retained as division expressions rather
% than forced through the grade-3 fraction-scene renderer.  The cited referent
% shift is a likely deformation: its corpus row is not presently admitted by
% misconception_registry_entry/5, so this chart does not label it a registered
% misconception. Named as a fact as well as a clause head so a caller can
% enumerate coverage without building the chart.
division_chart_lesson('IM-G6-U4-L10').

lesson_division_deformation_chart(Code, Chart) :-
    division_chart_lesson(Code),
    % This warm-up instance is a registered task, so its equal-share scene can
    % be drawn without inventing a fraction-partition prompt the payload lacks.
    set_grouping_scene:set_grouping_render_json(fair_share(12, 3), ProductiveScene),
    ProvenanceNote = "Division expressions cite compiled task instances from this lesson's teacher guide.",
    Chart = _{
        kind: lesson_deformation_chart,
        lesson_code: 'IM-G6-U4-L10',
        title: "Dividing by Unit and Non-Unit Fractions",
        standards: ["6.NS.A.1"],
        task_source: "teacher-guide-derived compiled task instances",
        tasks: [
            _{expression: "12 / 3", position: "warm_up", source_pages: "181-183"},
            _{expression: "12 / 4", position: "warm_up", source_pages: "181-183"},
            _{expression: "12 / 6", position: "warm_up", source_pages: "181-183"}
        ],
        productive_scene: ProductiveScene,
        likely_deformations: [
            _{name: "referent_unit_shift",
              status: "likely_deformation",
              citation: "Mi Yeon Lee (2017), ESM_Lee_2017_Pre-service",
              note: "The dividend bar is treated as the unit whole and repartitioned by the divisor."}
        ],
        provenance: division,
        provenance_note: ProvenanceNote
    }.

monitoring_chart('IM-G6-U4-L10', Chart) :-
    !,
    lesson_division_deformation_chart('IM-G6-U4-L10', Chart).
monitoring_chart(Code, Chart) :-
    lesson_chart_lesson(Code, Title, Standards, Hosts, Fractions),
    findall(CellDict,
            ( member(Host, Hosts),
              chart_cell_for_host(Code, Host, Fractions, CellDict) ),
            Cells),
    standards_strings(Standards, StandardStrings),
    fractions_strings(Fractions, FractionStrings),
    maplist(atom_string, Hosts, HostStrings),
    chart_provenance(Code, Provenance),
    chart_provenance_note(Provenance, ProvenanceNote),
    Base = _{
        kind: lesson_deformation_chart,
        lesson_code: Code,
        title: Title,
        standards: StandardStrings,
        hosts: HostStrings,
        fractions: FractionStrings,
        cells: Cells,
        provenance: Provenance,
        provenance_note: ProvenanceNote
    },
    (   Provenance == evidence
    ->  chart_evidence_dict(Code, Hosts, Fractions, Evidence),
        Chart = Base.put(provenance_evidence, Evidence)
    ;   Chart = Base
    ).

chart_cell_for_host(Code, Host, Fractions, Cell) :-
    comparison_host(Host),
    !,
    comparison_chart_cell(Code, Host, Fractions, Cell).
chart_cell_for_host(Code, Host, Fractions, Cell) :-
    member(frac(1,N), Fractions),
    chart_cell(Code, Host, frac(1,N), Cell).

comparison_host(number_line).
comparison_host(set).

comparison_family(number_line, number_line_fraction_comparison,
                  number_line_count_marks_not_intervals).
comparison_family(set, set_model_fraction_comparison,
                  set_model_subset_size_focus).

lesson_comparison_pair([First, Second|_], First, Second,
                       "Both fractions come from this lesson's evidence.") :- !.
lesson_comparison_pair([Only], Only, frac(1,2),
                       "This lesson supplies one fraction, so the comparison uses the 1/2 benchmark.").

comparison_chart_cell(Code, Host, Fractions, Cell) :-
    lesson_comparison_pair(Fractions, frac(M1,N1), frac(M2,N2), PairNote),
    comparison_family(Host, Family, DeformationKind),
    fraction_comparison_compare_json(
        compare_spec(Family, M1, N1, M2, N2), Document),
    frac_string(M1, N1, FirstText),
    frac_string(M2, N2, SecondText),
    format(string(PairText), "~s vs ~s", [FirstText, SecondText]),
    atom_string(Host, HostText),
    atom_string(DeformationKind, DeformationText),
    comparison_cell_payload(Document, DeformationText, Productive,
                            Deformations, RenderStatus),
    evidence_for_host(Code, Host, HostEvidence),
    evidence_for_fraction(Code, frac(M1,N1), FirstEvidence),
    evidence_for_fraction(Code, frac(M2,N2), SecondEvidence),
    Cell = _{ host:HostText,
              fraction:PairText,
              fractions:[FirstText,SecondText],
              numerator:M1, denominator:N1,
              comparison_family:Family,
              pair_note:PairNote,
              render_status:RenderStatus,
              productive:Productive,
              deformations:Deformations,
              evidence:_{host:HostEvidence,
                         fractions:[FirstEvidence,SecondEvidence]} }.

comparison_cell_payload(Document, DeformationText, Productive,
                        Deformations, drawn) :-
    \+ get_dict(error, Document, _),
    get_dict(productive, Document, Productive),
    get_dict(deformation, Document, DeformationScene),
    Deformations = [_{deformation:DeformationText,
                      family:"comparison_deformation",
                      scene:DeformationScene}].
comparison_cell_payload(Document, DeformationText,
                        _{frames:[], status:"text_only"},
                        [_{deformation:DeformationText,
                           family:"comparison_deformation",
                           scene:_{frames:[], status:"text_only", note:Error}}],
                        text_only) :-
    get_dict(error, Document, Error).

% chart_cell(Code, Host, frac(M,N), CellDict): the productive scene and the
% likely deformation scenes for one (host, fraction) of the lesson.
chart_cell(Code, Host, Frac, CellDict) :-
    Frac = frac(M, N),
    productive_scene_for_lesson(Code, Host, Frac, Productive),
    findall(_{ deformation: DefStr,
               family: Family,
               scene: DefScene },
            ( lesson_likely_deformation(Code, Host, Frac, Deformation),
              deformation_scene_for_lesson(Code, Host, Frac, Deformation, DefScene),
              deformation_label(Deformation, DefStr, Family) ),
            Deformations),
    frac_string(M, N, FracStr),
    atom_string(Host, HostStr),
    evidence_for_host(Code, Host, HostEvidence),
    evidence_for_fraction(Code, Frac, FractionEvidence),
    CellDict = _{
        host: HostStr,
        fraction: FracStr,
        numerator: M,
        denominator: N,
        productive: Productive,
        deformations: Deformations,
        evidence: _{host:HostEvidence, fraction:FractionEvidence}
    }.

chart_evidence_dict(Code, Hosts, Fractions,
                    _{hosts:HostRows, fractions:FractionRows}) :-
    findall(Row,
            ( member(Host, Hosts), evidence_for_host(Code, Host, Row) ),
            HostRows),
    findall(Row,
            ( member(Frac, Fractions), evidence_for_fraction(Code, Frac, Row) ),
            FractionRows).

evidence_for_host(Code, Host, Row) :-
    lesson_representation_evidence:lesson_host_evidence(
        Code, Host, Source, excerpt(Excerpt)),
    source_dict(Source, SourceDict),
    atom_string(Host, HostText),
    Row = _{host:HostText, source:SourceDict, excerpt:Excerpt}.
evidence_for_host(Code, Host,
                  _{host:HostText, source:_{class:"hand_authored"}}) :-
    \+ lesson_representation_evidence:lesson_host_evidence(Code, Host, _, _),
    chart_provenance(Code, hand_authored),
    atom_string(Host, HostText).

evidence_for_fraction(Code, frac(M,N), Row) :-
    lesson_representation_evidence:lesson_fraction_evidence(
        Code, frac(M,N), Source, excerpt(Excerpt), form(Form)),
    source_dict(Source, SourceDict),
    frac_string(M, N, FractionText),
    atom_string(Form, FormText),
    Row = _{fraction:FractionText, source:SourceDict,
            excerpt:Excerpt, form:FormText}.
evidence_for_fraction(Code, frac(M,N),
                      _{fraction:FractionText,
                        source:_{class:"hand_authored"}}) :-
    \+ lesson_representation_evidence:lesson_fraction_evidence(
        Code, frac(M,N), _, _, _),
    chart_provenance(Code, hand_authored),
    frac_string(M, N, FractionText).
evidence_for_fraction(Code, frac(M,N),
                      _{fraction:FractionText,
                        source:_{class:"benchmark"}}) :-
    \+ lesson_representation_evidence:lesson_fraction_evidence(
        Code, frac(M,N), _, _, _),
    chart_provenance(Code, evidence),
    frac_string(M, N, FractionText).

source_dict(source(Path, line(Line)), _{path:PathText, line:Line}) :-
    atom_string(Path, PathText).
source_dict(source(Path, page(Range)), _{path:PathText, page:Range}) :-
    atom_string(Path, PathText).

deformation_label(transplant(Rule), Str, "transplant_deformation") :-
    format(atom(A), "transplant(~w)", [Rule]),
    atom_string(A, Str).
deformation_label(equipartition_failure(ErrorType), Str, "equipartition_failure") :-
    format(atom(A), "equipartition_failure(~w)", [ErrorType]),
    atom_string(A, Str).

% =========================================================================
% Serialisation.
% =========================================================================

monitoring_chart_to_file(Chart, Path) :-
    setup_call_cleanup(
        open(Path, write, Stream, [encoding(utf8)]),
        json_write_dict(Stream, Chart, [width(80)]),
        close(Stream)).

% =========================================================================
% Helpers.
% =========================================================================

frac_string(M, N, Str) :-
    format(atom(A), "~w/~w", [M, N]),
    atom_string(A, Str).

standards_strings(Standards, Strings) :-
    maplist(atom_string, Standards, Strings).

fractions_strings(Fractions, Strings) :-
    findall(S, ( member(frac(M,N), Fractions), frac_string(M, N, S) ), Strings).
