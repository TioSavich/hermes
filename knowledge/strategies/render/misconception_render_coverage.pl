/** <module> Misconception render-coverage report
 *
 * Answers one question a skeptic asks directly: of the misconceptions the
 * registry knows about, which ones can the render layer actually draw, and
 * which ones cannot?
 *
 * The registry keys each entry on a free-text topic atom (its target
 * operation), e.g. addition, area_of_a_triangle, '2d_shapes'. The render layer
 * draws grounded numeric tasks (whole_number_addition(3,4), fraction_addition(
 * fraction(1,4),fraction(1,4))) on a fixed set of representations. Nothing in
 * the repo joined the two, so the coverage question had no runnable answer.
 *
 * This module supplies the join through op_render_family/3: an explicit,
 * auditable table mapping a registry op atom to a representation and one
 * exemplar task that representation already admits. An op with no row is
 * reported not_renderable(no_render_family_mapping). The bridge is a
 * conservative starter, not a claim of completeness: it covers the whole-number,
 * counting, place-value, fraction, and written-notation families, and the
 * middle-grades families the seven spatial and statistical formats draw —
 * plotted graphs, isometries, tiled regions, angles, distributions, solids and
 * lattice polygons, plus the balance for linear equations. What still does not
 * render says so rather than papering over it: ratio and signed number have
 * scene compilers with no language declared in the grammar, division has no
 * task shape at all, and the coarse topic atoms (geometry, algebraic,
 * measurement) carry registry entries no picture is about. The declines are
 * written out beside the rows, with the reason attached to each.
 *
 * Beyond the live-render lane, two further lanes classify what the repo holds
 * for an op that does not draw today:
 *
 *   - parametric_deformation: a parametric deformation clause computes the
 *     op's misconception scenes or wrong answers live (the equipartition
 *     failures in parametric_fraction_errors.pl, the notation deformations in
 *     representation_grammar.pl). The lesson deformation charts in
 *     curriculum/im/lesson_deformation_chart.pl consume this same lane.
 *   - evidence_pointer: an aggregated corpus-figure bucket in
 *     attested_deformations.pl documents the error pattern; a pointer to
 *     literature figures, not scene geometry.
 *
 * Both joins are hand-curated tables in the op_render_family/3 discipline:
 * every row's backing goal was verified live before the row was written, and
 * an op with no row in any table is reported not_covered.
 *
 * Run:
 *   swipl -q -l paths.pl -g "use_module(render(misconception_render_coverage)), \
 *     render_coverage_summary(S), print_term(S,[]), nl" -t halt
 */

:- module(misconception_render_coverage,
          [ render_coverage_row/3,        % -Op, -Status, -Why
            render_coverage_summary/1,    % -Dict
            render_coverage_report_dict/1,% -Dict (JSON-safe summary + rows)
            op_coverage_lane/3,           % -Op, -Lane, -Why
            renderable_op/3,              % ?Op, ?Representation, ?Task
            op_render_family/3,           % ?Op, ?Representation, ?ExemplarTask
            op_parametric_backing/3,      % ?Op, ?Family, ?Witness
            op_evidence_pointer/3 ]).     % ?Op, ?Language, ?Pattern

:- use_module(misconceptions(misconception_registry),
              [ misconception_registry_entry/5 ]).
:- use_module(strategies(render/representation_grammar),
              [ valid_task_for_representation/2,
                representation_render_status/2,
                misconception_visual/5,
                deformation_spec_evidence/4 ]).
:- use_module(strategies(render/parametric_fraction_errors),
              [ error_evidence/4 ]).
:- use_module(strategies(render/attested_deformations),
              [ attested_representation_error_scope/5 ]).
:- use_module(library(aggregate)).

:- dynamic registry_operations_cache/1.

%! registry_operations(-Ops) is det.
%  The sorted distinct registry op atoms, memoized. misconception_registry_entry/5
%  is a rule that re-derives all ~1800 entries on every call (~3s), so the
%  distinct-op list is computed once per process and cached. The registry is
%  static at runtime, so the cache cannot go stale within a session.
registry_operations(Ops) :-
    ( registry_operations_cache(Ops)
    -> true
    ;  findall(O, misconception_registry_entry(_, O, _, _, _), Os),
       sort(Os, Ops),
       assertz(registry_operations_cache(Ops))
    ).

%! registry_operation(-Op) is nondet.
%  Each DISTINCT registry target-op atom, once, in standard order.
registry_operation(Op) :-
    registry_operations(Ops),
    member(Op, Ops).

%! op_render_family(?Op, ?Representation, ?ExemplarTask) is nondet.
%
%  The auditable join. Each row pairs a registry op atom with a representation
%  and an exemplar task that valid_task_for_representation/2 already admits and
%  representation_render_status/2 reports renderable. Every row below was
%  verified live against the grammar before it was written; an op with no row
%  defaults to not-renderable.
%
%  These are deliberately the families that map onto an existing drawable
%  primitive. Adding a row is a curation decision about which exemplar best
%  stands for a topic, not a code change.
%
%  --- whole-number / counting (set_grouping, base_ten_blocks) ---
op_render_family(addition,                  set_grouping,    whole_number_addition(3, 4)).
op_render_family(subtraction,               set_grouping,    whole_number_subtraction(9, 4)).
op_render_family(addition_and_subtraction,  base_ten_blocks, whole_number_addition(28, 47)).
op_render_family(counting,                  set_grouping,    kindergarten_counting_collection(8)).
op_render_family(counting_and_comparing_sets, set_grouping,  comparison(whole_number(8), whole_number(5))).
op_render_family(comparison,                set_grouping,    comparison(whole_number(8), whole_number(5))).
op_render_family(comparing_quantities,      set_grouping,    comparison(whole_number(8), whole_number(5))).
op_render_family(multiplication,            set_grouping,    multiplication(3, 4)).
%  --- place value (base_ten_blocks) ---
op_render_family(place_value,               base_ten_blocks, whole_number(2356)).
op_render_family(base_ten_system,           base_ten_blocks, whole_number(2356)).
%  --- fractions (fraction_bars) ---
op_render_family(addition_of_fractions,     fraction_bars,   fraction_addition(fraction(1, 4), fraction(1, 4))).
op_render_family(fraction_addition,         fraction_bars,   fraction_addition(fraction(1, 4), fraction(1, 4))).
op_render_family(addition_and_subtraction_of_fractions, fraction_bars, fraction_subtraction(fraction(3, 4), fraction(1, 4))).
op_render_family(fraction_addition_and_subtraction,     fraction_bars, fraction_subtraction(fraction(3, 4), fraction(1, 4))).
%  --- area as a rectangular-array model (area_model) ---
op_render_family(area_models,               area_model,      multiplication(3, 4)).
%  --- written arithmetic notation (notation) ---
%  The notation monitoring-chart lane draws these today: 260 encoded IM lessons
%  host a chart keyed on equation(A, Op, B, R) (lesson_notation_chart.pl), and
%  the exemplars below carry that same key shape. multiplication takes the
%  equation form of necessity — the grammar admits equation(3, *, 4, 12) for
%  notation but not multiplication(3, 4); the rest take it for uniformity with
%  the lane they attest. The written_subtraction exemplar hosts a borrow
%  (41 - 17), the written_computation exemplar a units carry (28 + 47), so each
%  row's equation is one the op's registry entries are about.
%  One bar is weaker here than for every other family in this table:
%  render_spec_denotes/3 carries no link for the equation(A, Op, B, R) shape, so
%  these rows rest on renderable_op/3 alone (grammar admission plus renderable
%  status). The consumers that draw the lane — notation_render_dispatch in
%  hermes_worker.pl and productive_notation_cell_scene/3 in
%  lesson_notation_chart.pl — rebuild write_equation(A, Op, B, R) from the same
%  fields and compile real glyphs; notation_render_frames/2 called on the bare
%  equation term instead lands in the deferred fallback and draws nothing.
op_render_family(addition,                  notation,        equation(3, +, 4, 7)).
op_render_family(subtraction,               notation,        equation(9, -, 4, 5)).
op_render_family(addition_and_subtraction,  notation,        equation(28, +, 47, 75)).
op_render_family(multiplication,            notation,        equation(3, *, 4, 12)).
op_render_family(written_subtraction,       notation,        equation(41, -, 17, 24)).
op_render_family(written_computation,       notation,        equation(28, +, 47, 75)).

%  --- the middle-grades spatial and statistical formats ---
%
%  Seven formats built for grades 6-8 content had no row in this table, so every
%  op that dominates those grades reported not_covered while its drawer sat
%  dispatched and unused. The rows below close that, one op at a time, under a
%  rule stated here because it did the deciding: a row is written when the
%  MAJORITY of the op's registry entries concern the object the exemplar draws,
%  and declined when the majority concern a relation among classes, an algebraic
%  register, a verbal translation, or an object the format itself refuses. The
%  declines are the substance of the curation, not its residue; §Declined below
%  records them so the next reader does not re-litigate each one.
%
%  Every exemplar here clears a bar the older rows did not have to state: it is
%  admitted by valid_task_for_representation/2 AND some render_spec_denotes/3
%  spec compiles it to a scene. That second half matters, because three shapes
%  the grammar admits denote no spec at all — point(X, Y), region(C, R) and
%  central_angle(D) pass the admission test and draw nothing. renderable_op/3
%  would have called them covered. None is used as an exemplar.

%  coordinate_plane: plotted points and plotted lines on an indexed plane.
%  graphing / graphing_functions / functions_and_graphs turn on reading a curve
%  off finitely many plotted points, so their exemplars are point sets, not
%  lines — Even 1990's point-wise plotting that misses global behaviour, and
%  Delgadillo 2016's continuity assumed from a handful of points, are about the
%  points. slope and linear_functions turn on the line's parameters, so theirs
%  is a line carrying both a rate and an intercept. The two motion ops take a
%  line through the origin, which is the distance-time picture their entries
%  argue over (Moschkovich 2018's reversed axes, Zahner 2012's horizontal
%  segment read as movement).
op_render_family(graphing,                  coordinate_plane, linear_graph(2, 1)).
op_render_family(graphing_functions,        coordinate_plane, point_set([0-1, 1-3, 2-5])).
op_render_family(functions_and_graphs,      coordinate_plane, point_set([0-1, 1-3, 2-5])).
op_render_family(linear_functions,          coordinate_plane, linear_graph(2, 1)).
op_render_family(slope,                     coordinate_plane, linear_graph(2, 1)).
op_render_family(distance_time_graphs,      coordinate_plane, linear_graph(2, 0)).
op_render_family(graphing_motion,           coordinate_plane, linear_graph(2, 0)).

%  rigid_motion: a lattice polygon and its image under an isometry. Yanik 2009's
%  four entries under geometric_transformations are all about a vector acting on
%  a figure, which is the translate spec exactly; reflection_geometry and
%  line_symmetry take the reflection spec, since both turn on an image being a
%  mirror rather than merely congruent. line_symmetry's oblique-axis entry sits
%  outside the format, which reflects over x or y only — one entry of three, so
%  the row stands with the limit named rather than hidden.
op_render_family(geometric_transformations, rigid_motion,
                 isometry_image([0-0, 3-0, 0-2], translation(4, 1))).
op_render_family(reflection_geometry,       rigid_motion,
                 isometry_image([0-0, 3-0, 0-2], reflection(y))).
op_render_family(line_symmetry,             rigid_motion,
                 isometry_image([0-0, 3-0, 0-2], reflection(y))).

%  polyform_tiling: rigid pieces filling a bounded region. area and
%  area_measurement are dominated by covering and row-and-column structuring of
%  a region — gaps and overlaps, counting without an array structure, partial
%  tiles — which is what tile_area draws. tiling_tasks is DECLINED from this
%  table: its sole registry entry (batch_row_40581, dismissing an impossible
%  task) concerns impossibility, the productive tiling/2 exemplar draws a
%  completable partial cover that carries none of that, and the parity lane
%  that does stage impossibility (unfillable_by_parity_compare, verified live
%  through polyform_tiling_compare_json/2) has no deformation_spec_evidence
%  row in the grammar, so no witness shape in this module reaches it. The
%  seam for a future row is grammar-side evidence for the parity lane first.
op_render_family(area,                      polyform_tiling, area_by_tiling(region(4, 3), 4*3)).
op_render_family(area_measurement,          polyform_tiling, area_by_tiling(region(4, 3), 4*3)).

%  angle_circular: a turn drawn as an angle or a sector. angles carries
%  Fischbein 1999's ray-length error, which this format computes (see the
%  parametric row below); angle carries the turtle-geometry confusion of the
%  turn with the interior angle, so its exemplar is 120 degrees, an exterior
%  turn; angle_measure carries the arc-and-sector reading, and 90 degrees draws
%  a quarter sector. central_angle(D) would have been the truer term for the
%  last of these and is deliberately not used: no spec denotes it.
op_render_family(angles,                    angle_circular,  angle_measure(45)).
op_render_family(angle,                     angle_circular,  angle_measure(120)).
op_render_family(angle_measure,             angle_circular,  angle_measure(90)).

%  data_display: a distribution drawn as bars or dots. The dot plot is chosen
%  over the bar chart because these three ops argue about reading a distribution
%  globally rather than case by case (Konold 2015, Hahn 2014), and about the
%  mode standing in for the mean (Mokros 1995). The exemplar is curated so those
%  two values come apart: [3,3,4,5,5,5,6] has mode 5 and mean 31/7, so the
%  picture is one where the substitution is visibly wrong.
op_render_family(data_analysis,             data_display,    data_display(dot_plot, [3,3,4,5,5,5,6])).
op_render_family(average,                   data_display,    data_display(dot_plot, [3,3,4,5,5,5,6])).
op_render_family(mean,                      data_display,    data_display(dot_plot, [3,3,4,5,5,5,6])).

%  solid_net: a solid's faces, unfolded, or a stack of unit cubes. volume and
%  volume_enumeration are Battista 2004 and Stacey 2001 almost word for word —
%  hidden interior cubes, corner cubes counted twice, exterior faces counted
%  instead of the solid — which is the unit-cube stack. geometric_solids is
%  Horzum 2018 on which face of a prism counts as the base, and a net is the
%  only builder here that draws a solid's faces individually.
op_render_family(volume,                    solid_net,       solid_volume(3, 4, 5)).
op_render_family(volume_enumeration,        solid_net,       solid_volume(3, 4, 5)).
op_render_family(geometric_solids,          solid_net,       net(rectangular_prism)).

%  geoboard: a band bounding a region on a peg lattice, which carries an area
%  and a boundary at once — the two attributes area_and_perimeter and
%  perimeter_and_area report students conflating. perimeter takes a right
%  triangle on purpose: its hypotenuse crosses grid squares, which is Clarke
%  2018's error of counting a diagonal as one unit. triangles takes an oblique
%  scalene triangle, since three of its four entries are about refusing a
%  figure drawn off the prototypical horizontal base.
op_render_family(perimeter,                 geoboard,        geoboard_polygon([0-0, 3-0, 0-4])).
op_render_family(area_and_perimeter,        geoboard,        geoboard_polygon([0-0, 4-0, 4-3, 0-3])).
op_render_family(perimeter_and_area,        geoboard,        geoboard_polygon([0-0, 4-0, 4-3, 0-3])).
op_render_family(triangles,                 geoboard,        geoboard_polygon([1-0, 4-1, 2-3])).

%  area_model, reached by a route worth naming: Ron 2017's three entries under
%  area_model_for_probability are about a unit square whose sub-rectangles are
%  event probabilities, and the area model's fraction_product spec draws exactly
%  that — a 1/2-by-1/3 sub-rectangle of the unit square. The op reads as
%  probability and its drawer is an area model.
op_render_family(area_model_for_probability, area_model,     fraction_product(1, 2, 1, 3)).

%  balance_scale: two pans that stay level. linear_equations is dominated by the
%  balance principle and its misapplication (Pirie 1997, Cooper 2008, Tall 2007
%  on where the balance breaks for negative terms), and equations by the
%  relational reading of the equals sign that a level balance depicts — one of
%  its entries is a critique of over-relying on this very model. 3x + 4 = 19.
op_render_family(linear_equations,          balance_scale,   equation(linear(3, 4, 19))).
op_render_family(equations,                 balance_scale,   equation(linear(3, 4, 19))).

%  Declined, with the reason each time, so the boundary is a record and not a
%  silence. Grouped by what does the declining.
%
%  No language registered, so no row can be witnessed: ratio, proportional_
%  reasoning, ratio_and_proportion, ratio_comparison, rate_of_change and the
%  rest of the ratio family; integer, negative_numbers, operations_with_integers.
%  ratio_diagram_scene.pl and signed_number_line_scene.pl are both built and
%  both compile scenes, but representation_grammar.pl declares no language and
%  no render status for either, so representation_render_status/2 fails and
%  renderable_op/3 cannot hold. Registering the two languages is the unlock, and
%  it is a grammar change, not a row.
%
%  The format refuses the object outright: similarity, geometric_enlargement,
%  similar_rectangles — representation_refusal(rigid_motion, dilation(_, K), _)
%  declines dilation by design, and every entry under these three is about
%  multiplicative enlargement. spherical_geometry — solid_net refuses curved
%  surfaces. 3d_geometry — its concept-image entry is about cylinders and cones,
%  which solid_net_supported_solid/1 does not carry.
%
%  One task, but the misconception needs two things: area_comparison,
%  area_conservation (two figures compared; every admitted tiling task carries
%  one region), arithmetic_mean (weighted means of two subgroups; one series per
%  display), line_graphs (two lines and their intersection point; the plane's
%  line spec draws one), systems_of_linear_equations (two equations; the balance
%  carries one).
%
%  A name is not a doing: translation — its single entry is reversing variables
%  when translating a verbal statement into symbols, which is not a geometric
%  translation. transformations — both entries are translating a function graph
%  in the algebraic register. linear_equation_word_problems, equation_solving —
%  word-problem translation and symbol manipulation. statistics — the lesson
%  join uses this atom for 23 lessons, but the registry carries zero entries
%  under it, so no row can pair a registry op with anything.
%
%  The op's content is a relation among classes, which one drawn figure cannot
%  settle: quadrilaterals, shape_classification, 2d_shapes, geometric_figures,
%  polygons (interior-angle sums; no admitted geoboard task carries an angle).
%
%  No admitted task carries the object: probability, sample_space,
%  theoretical_probability (sample spaces and spinners), circle_properties
%  (inscribed angles, chords, tangents), circle_area (rearranged sectors and a
%  limit), sampling (populations and repeated draws), variables, geometry (its
%  one entry, Bell 1979, is about properties not forming a deductive hierarchy —
%  nothing here draws that), algebraic, measurement, division. division is the
%  same wall task 225 hit from the notation side: no task shape in the grammar
%  expresses division at all.

%! renderable_op(?Op, -Representation, -Task) is nondet.
%
%  An op renders live when its bridge row's exemplar task passes the same two
%  conditions drawable_visual_candidate/5 adds over visual_candidate/5
%  (representation_grammar.pl:671-673): the task is in-scope for the
%  representation, and the representation has a renderable render-status. The
%  per-op lesson-context filter drawable_visual_candidate/5 also applies is left
%  out on purpose: an op-level coverage report has no single lesson to bind.
renderable_op(Op, Rep, Task) :-
    op_render_family(Op, Rep, Task),
    valid_task_for_representation(Rep, Task),
    representation_render_status(Rep, renderable(_)).

%! op_has_deformation_scene(+Op) is semidet.
%
%  The misconception lane: the op's exemplar correct task has a labeled
%  misconception_visual/5 deformation. Backed by the misconception_deformation/4
%  clauses in representation_grammar.pl, which are sparse, so this lights up for
%  only a few ops today. Informational; renderability does not depend on it.
op_has_deformation_scene(Op) :-
    op_render_family(Op, _Rep, Task),
    misconception_visual(Task, _Misc, _R, _Scene, _Ev),
    !.

%! op_parametric_backing(?Op, ?Family, ?Witness) is nondet.
%
%  The parametric-deformation join. Each row pairs a registry op atom with the
%  deformation family that backs it and one witness goal (interpreted by
%  parametric_witness/1) verified live before the row was written. A row here
%  says: the repo computes this op's misconception content parametrically —
%  a deformed scene or wrong answer derived by a clause, not a static figure —
%  even though no bridge row draws the op live.
%
%  fraction: the four equipartition failures in parametric_fraction_errors.pl
%  (unequal_partition, miscount_partition, shade_wrong_count, wrong_referent_
%  whole) over the circle/bar/area hosts. lesson_deformation_chart.pl builds
%  77 of its 78 IM lesson charts from this same lane, not only the three it
%  reads off a teacher guide; the one exception, the division chart for
%  IM-G6-U4-L10, is hardcoded in that module and never touches this lane.
op_parametric_backing(fraction, equipartition_failure,
                      error_evidence(unequal_partition, circle, frac(1, 4))).
%  decimal: the notation lane's place_value_writing_error computes the mirrored
%  inscription live; its corpus anchor is the registry's own decimal row
%  arith_misconception(db_row(38397), decimal, mirror_image_place_value, ...).
op_parametric_backing(decimal, notation_place_value_writing,
                      deformation_spec_evidence(notation,
                          place_value_writing_error(7, '+', 6, 13))).
%  decimal_notation: the same lane and anchor — mirror_image_place_value is
%  itself an entry under decimal_notation, and place_value_writing_error
%  computes the mirrored inscription for it live.
op_parametric_backing(decimal_notation, notation_place_value_writing,
                      deformation_spec_evidence(notation,
                          place_value_writing_error(7, '+', 6, 13))).
%  equal_sign / equality: operational_equals_chain computes the operational
%  reading of the equals sign live (reason(equals_read_as_makes),
%  corpus_attested), and the lesson notation charts admit it for any hosted
%  equation. The evidence contour differs by atom and is thin under the first:
%  equal_sign holds two entries, of which db_row(40252) describes the
%  operational interpretation as previously held — a perturbation the teachers
%  it documents worked through — and the other concerns answer-position format,
%  not this chain. The direct computational-command reports sit under equality
%  (db_row(37932)/db_row(38494)/db_row(40111)). The two atoms name one doing,
%  so both rows stand, with equality carrying the direct evidence.
op_parametric_backing(equal_sign, notation_operational_equals_chain,
                      deformation_spec_evidence(notation,
                          operational_equals_chain(3, '+', 4, 7))).
op_parametric_backing(equality, notation_operational_equals_chain,
                      deformation_spec_evidence(notation,
                          operational_equals_chain(3, '+', 4, 7))).
%  angles: the one place a spatial break lane and a registry entry name the same
%  error. angle_circular's ray_length_error redraws a turn with longer rays and
%  reads it as bigger; the registry's ESM_Fischbein_1999 entry under angles is
%  students judging an angle by the length of its drawn arms. The lane comment
%  in representation_grammar.pl calls that break literature-only, with no row in
%  this corpus; this row is the counterexample, and the comment wants correcting
%  when someone next edits the grammar. The row does not change the op's lane —
%  the bridge row above already makes angles render live — it records that the
%  repo computes the error, not only that it can draw the correct angle.
op_parametric_backing(angles, angle_circular_ray_length,
                      deformation_spec_evidence(angle_circular,
                          ray_length_error(45, 2, 6))).

%! parametric_witness(+Witness) is semidet.
%
%  Run a backing row's witness goal against the live lane predicates. Each
%  shape names the module that owns the clause; a row whose witness fails is a
%  dead row, and the test suite refuses it.
parametric_witness(error_evidence(ErrorType, Host, Frac)) :-
    error_evidence(ErrorType, Host, Frac, _Evidence),
    !.
parametric_witness(deformation_spec_evidence(Representation, Deformation)) :-
    deformation_spec_evidence(Representation, Deformation, _Task, _Evidence),
    !.

%! op_evidence_pointer(?Op, ?Language, ?Pattern) is nondet.
%
%  The corpus-evidence join. Each row pairs a registry op atom with an
%  aggregated figure bucket in attested_deformations.pl that documents the
%  error pattern for that topic. These are pointers to literature figures,
%  never scene geometry; attested_representation_error_scope/5 classifies
%  every one as evidence_pointer and the tests hold the rows to that.
op_evidence_pointer(ratio,     none, cross_multiply_without_ground).
op_evidence_pointer(algebraic, none, sqrt_distributes_over_addition).
op_evidence_pointer(algebraic, none, factoring_or_root_error).
op_evidence_pointer(algebraic, none, order_of_operations_error).

%! op_coverage_lane(-Op, -Lane, -Why) is nondet.
%
%  Exactly one row per distinct registry op, with Lane one of renders_live,
%  parametric_deformation, evidence_pointer, not_covered — in that precedence
%  order (a live render outranks a parametric clause outranks a corpus
%  pointer). The enumeration is driven by registry_operation/1; the lane is
%  decided by an inner if-then-else so the per-op verdict commits without
%  cutting the enumeration. Why carries the evidence for the verdict.
op_coverage_lane(Op, Lane, Why) :-
    registry_operation(Op),
    (   renderable_op(Op, Rep, Task)
    ->  Lane = renders_live,
        ( op_has_deformation_scene(Op)
        -> Why = renders_live(Rep, Task, deformation_lane)
        ;  Why = renders_live(Rep, Task)
        )
    ;   op_parametric_backing(Op, Family, Witness),
        parametric_witness(Witness)
    ->  Lane = parametric_deformation,
        Why = parametric_deformation(Family, Witness)
    ;   op_evidence_pointer(Op, Language, Pattern),
        attested_representation_error_scope(Language, Pattern, FigureCount,
                                            evidence_pointer, _ScopeWhy)
    ->  Lane = evidence_pointer,
        Why = evidence_pointer(Language, Pattern, FigureCount)
    ;   Lane = not_covered,
        ( op_render_family(Op, Rep, Task)
        -> Why = bridge_task_rejected(Rep, Task)   % a row exists but the grammar refuses it
        ;  Why = no_render_family_mapping           % conservative default: no row in any table
        )
    ).

%! render_coverage_row(-Op, -Status, -Why) is nondet.
%
%  The binary partition, kept for callers that only ask "does it draw?".
%  Status is renderable exactly on the renders_live lane; every other lane is
%  not_renderable, with the lane's own Why carried through.
render_coverage_row(Op, Status, Why) :-
    op_coverage_lane(Op, Lane, Why),
    (   Lane == renders_live
    ->  Status = renderable
    ;   Status = not_renderable
    ).

%! render_coverage_summary(-Dict) is det.
%
%  The partition, as a dict. total_ops is the live distinct-op count, not a
%  frozen constant; renderable + not_renderable always sum to it, and the
%  lanes sub-dict partitions the same total four ways.
render_coverage_summary(Summary) :-
    findall(Op-Lane, op_coverage_lane(Op, Lane, _), Rows),
    length(Rows, Total),
    aggregate_all(count, member(_-renders_live, Rows), RL),
    aggregate_all(count, member(_-parametric_deformation, Rows), PD),
    aggregate_all(count, member(_-evidence_pointer, Rows), EP),
    aggregate_all(count, member(_-not_covered, Rows), NC),
    NR is PD + EP + NC,
    findall(O, member(O-renders_live, Rows), RenderableOps0),
    sort(RenderableOps0, RenderableOps),
    aggregate_all(count, op_render_family(_, _, _), BridgeRows),
    Summary = _{ total_ops: Total,
                 renderable: RL,
                 not_renderable: NR,
                 bridge_rows: BridgeRows,
                 renderable_ops: RenderableOps,
                 lanes: _{ renders_live: RL,
                           parametric_deformation: PD,
                           evidence_pointer: EP,
                           not_covered: NC } }.

%! render_coverage_report_dict(-Dict) is det.
%
%  The whole report as one JSON-safe dict for the Hermes worker: the summary
%  plus every per-op row, each row's why rendered as text. Counts are computed
%  live from the registry loaded in this process; installations that carry the
%  local misconception CSV corpus report a larger registry through the same
%  predicate.
render_coverage_report_dict(_{ summary: Summary, rows: RowDicts }) :-
    render_coverage_summary(Summary0),
    maplist(atom_string, Summary0.renderable_ops, RenderableOps),
    Summary = Summary0.put(renderable_ops, RenderableOps),
    findall(_{ op: OpText, lane: LaneText, why: WhyText },
            ( op_coverage_lane(Op, Lane, Why),
              atom_string(Op, OpText),
              atom_string(Lane, LaneText),
              format(string(WhyText), "~w", [Why])
            ),
            RowDicts).
