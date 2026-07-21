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
 * counting, place-value, and fraction families that map cleanly onto an existing
 * drawable primitive. The broad K-6 topic space (geometry, measurement, decimal
 * magnitude, ratio) genuinely does not render today, and the report says so
 * rather than papering over it.
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
%  the IM-G3-U5 charts from this same lane.
op_parametric_backing(fraction, equipartition_failure,
                      error_evidence(unequal_partition, circle, frac(1, 4))).
%  decimal: the notation lane's place_value_writing_error computes the mirrored
%  inscription live; its corpus anchor is the registry's own decimal row
%  arith_misconception(db_row(38397), decimal, mirror_image_place_value, ...).
op_parametric_backing(decimal, notation_place_value_writing,
                      deformation_spec_evidence(notation,
                          place_value_writing_error(7, '+', 6, 13))).

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
