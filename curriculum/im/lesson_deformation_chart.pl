/** <module> Lesson-specific deformation monitoring charts
 *
 * The usefulness payoff for the parametric-deformation layer. Given a real
 * Illustrative Mathematics fraction lesson, this assembles the monitoring chart
 * a teacher would want before the lesson runs: the PRODUCTIVE model for the
 * lesson's own fraction, beside the LIKELY student-work deformations to watch
 * for on that representation, every deformation drawn on the lesson's fraction.
 *
 * "Given a lesson on 1/4 modeled with a circle, here are the botches to expect,
 * rendered on 1/4" -- and because the deformations are parametric (the layers in
 * knowledge/strategies/render/parametric_partition_deformation.pl and
 * parametric_fraction_errors.pl are functions of the fraction), the same chart
 * regenerates for any fraction the lesson names.
 *
 * Three layers, all read-only over the grammar, the parametric deformation
 * generators, and the corpus-attested evidence:
 *
 *   1. lesson_chart_lesson(Code, Title, Standards, Hosts, Fractions)
 *      The encoded lessons. Each row is a REAL grade-3 IM fractions lesson, its
 *      addressed standards, the host representations it partitions in
 *      (circle / rectangle / bar), and the unit fractions it has students model.
 *      The fractions and hosts are read off the teacher-guide markdown in
 *      curriculum/im_teacher_guides/grade3/unit5/.
 *
 *   2. lesson_likely_deformation(Code, Host, frac(M,N), Deformation)
 *      For a lesson host and fraction, the deformations LIKELY on that
 *      representation. Two families:
 *        - transplant(Rule): a foreign partition rule on the host (the headline
 *          family). Chosen only when attested for that host in
 *          parametric_partition_deformation:attested_transplant_pair/2, which is
 *          itself anchored to a real corpus witness in attested_deformations.pl.
 *        - equipartition_failure(ErrorType): the host keeps its own primitive but
 *          applies it wrongly (unequal parts, miscount). From
 *          parametric_fraction_errors.pl.
 *      Every deformation is gated through gated_as_misconception/2 so it is a
 *      LABELED misconception, never an unlabeled productive diagram.
 *
 *   3. monitoring_chart(Code, Chart)
 *      The assembled chart dict: the lesson metadata, the productive scene per
 *      (host, fraction), and the likely deformation scenes per (host, fraction).
 *      Each scene is a drawer-compatible {frames:[...]} document, so the render
 *      driver projects it through hermes/web/render/drawer.js without this file
 *      touching the drawer or the grammar.
 *
 * GROUNDING vs RENDER separation is preserved: this file decides WHICH
 * deformations to watch for and on WHICH fraction; the drawer projects them. It
 * does not edit representation_grammar.pl or drawer.js.
 *
 * Load through paths.pl (the render(...) and lessons(...) search paths).
 */

:- module(lesson_deformation_chart,
          [ lesson_chart_lesson/5,           % ?Code, ?Title, ?Standards, ?Hosts, ?Fractions
            lesson_fraction_task/2,           % ?Code, ?frac(M,N)
            lesson_host_representation/2,      % ?Code, ?Host
            lesson_likely_deformation/4,       % ?Code, ?Host, ?frac(M,N), ?Deformation
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
:- use_module(lessons('im/generated/default_fill_lessons')).
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
%   Hosts     : the host representations the lesson partitions in. circle and
%               rectangle are area shapes; bar is the fraction-strip the lesson
%               folds. Read off the teacher-guide markdown.
%   Fractions : the unit fractions the lesson has students model, as frac(M,N).
%
% Three real grade-3 IM fractions lessons (unit 5):
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

% Hand-authored rows preserve their guide-specific hosts and fractions.  The
% default fill admits every other lesson through lesson_monitoring's explicit /
% compiled strategy union, not through a second inventory of lesson codes.
lesson_chart_lesson(Code, Title, Standards, Hosts, Fractions) :-
    hand_authored_chart_lesson(Code, Title, Standards, Hosts, Fractions).
lesson_chart_lesson(Code, Title, Standards, Hosts, Fractions) :-
    default_fill_chart_lesson(Code, Title, Standards, Hosts, Fractions),
    \+ hand_authored_chart_lesson(Code, _, _, _, _).

default_fill_chart_lesson(Code, Title, Standards,
        [circle, rectangle, bar],
        [frac(1,2), frac(1,3), frac(1,4), frac(1,6), frac(1,8)]) :-
    % Everything here is a generated fact lookup (see
    % generated/default_fill_lessons.pl and its builder). The strategy
    % union, lesson titles, and standards are all rule-backed in the
    % full worker image and cost minutes to walk at request time; the
    % build step walks them once and serves facts.
    default_fill_lessons:default_fill_lesson(Code, Title, Standards).

chart_provenance(Code, hand_authored) :-
    hand_authored_chart_lesson(Code, _, _, _, _),
    !.
chart_provenance(_Code, default_fill).

% lesson_fraction_task(Code, frac(M,N)): each fraction the lesson models.
lesson_fraction_task(Code, Frac) :-
    lesson_chart_lesson(Code, _, _, _, Fractions),
    member(Frac, Fractions).

% lesson_host_representation(Code, Host): each host the lesson partitions in.
lesson_host_representation(Code, Host) :-
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
    lesson_fraction_task(Code, Frac),
    lesson_host_representation(Code, Host),
    host_for_partition_layer(Host, PartitionHost),
    % only transplants anchored to a real attested witness for this host
    parametric_partition_deformation:attested_transplant_pair(PartitionHost, transplant(Rule)).

lesson_likely_deformation(Code, Host, Frac, equipartition_failure(ErrorType)) :-
    lesson_fraction_task(Code, Frac),
    lesson_host_representation(Code, Host),
    host_for_error_layer(Host, ErrorHost),
    likely_equipartition_error(ErrorType),
    % the error must actually have corpus-grounded evidence for this host+fraction
    parametric_fraction_errors:error_evidence(ErrorType, ErrorHost, Frac, _Evidence).

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

productive_scene_for_lesson(Code, Host, frac(_M, N), Dict) :-
    lesson_host_representation(Code, Host),
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
    Frac = frac(_M, N),
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
% misconception.
lesson_division_deformation_chart('IM-G6-U4-L10', Chart) :-
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
        likely_deformations: [
            _{name: "referent_unit_shift",
              status: "likely_deformation",
              citation: "Mi Yeon Lee (2017), ESM_Lee_2017_Pre-service",
              note: "The dividend bar is treated as the unit whole and repartitioned by the divisor."}
        ],
        provenance: hand_authored
    }.

monitoring_chart('IM-G6-U4-L10', Chart) :-
    !,
    lesson_division_deformation_chart('IM-G6-U4-L10', Chart).
monitoring_chart(Code, Chart) :-
    lesson_chart_lesson(Code, Title, Standards, Hosts, Fractions),
    findall(CellDict,
            ( member(Host, Hosts),
              member(Frac, Fractions),
              chart_cell(Code, Host, Frac, CellDict) ),
            Cells),
    standards_strings(Standards, StandardStrings),
    fractions_strings(Fractions, FractionStrings),
    maplist(atom_string, Hosts, HostStrings),
    chart_provenance(Code, Provenance),
    Chart = _{
        kind: lesson_deformation_chart,
        lesson_code: Code,
        title: Title,
        standards: StandardStrings,
        hosts: HostStrings,
        fractions: FractionStrings,
        cells: Cells,
        provenance: Provenance
    }.

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
    CellDict = _{
        host: HostStr,
        fraction: FracStr,
        numerator: M,
        denominator: N,
        productive: Productive,
        deformations: Deformations
    }.

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
