/** <module> parametric_fraction_errors
 *
 * Equipartition-failure family of fraction-model errors, parametric over the
 * fraction. ADDITIVE over strategies/render/representation_grammar.pl: it does
 * NOT edit that grammar, and it never emits an unlabeled productive diagram for
 * a deformation. Every error scene carries the violated grammar rule and a
 * corpus-attested pattern as its evidence, matching the wrong-thing lane of
 * representation_grammar:misconception_visual/5 and the attested error patterns
 * in strategies/render/attested_deformations.pl.
 *
 * The point this layer makes useful: a documented student-work error is not a
 * single botched figure but a RULE that reproduces. If a child botches a model
 * of 1/4 by drawing the parts unequal, the same rule generates the botched
 * model for 1/5, 1/6, ... The errors here are functions of frac(M, N), so one
 * deformation replicates across the whole fraction family. This drives
 * lesson-specific monitoring charts: name the lesson's target fractions, get
 * the predicted botches for each, side by side.
 *
 * What distinguishes this family from the TRANSPLANT family
 * (strategies/render/attested_deformations.pl attested_transplant/5,
 * representation_grammar:deformation_spec_evidence/4 hybridization rows): a
 * transplant moves a foreign primitive onto an illicit host (a rectangle's
 * partition rule placed on a circle). An equipartition failure keeps the host's
 * own primitive but applies it wrongly -- the pieces are unequal, miscounted,
 * the wrong count is shaded, or a different whole is used. No foreign primitive
 * is involved.
 *
 * Output contract (the frozen render contract,
 * docs/research_assets/specs/2026-06-23-render-contract-frozen.md): each scene is a
 * {frames:[...]} document. Each frame is a dict carrying step, verb, caption,
 * and a scene the drawer (more-zeeman/render/drawer.js) can draw. Verbs are the
 * named B/M/E steps: establish_whole / apply_partition / shade_parts. The
 * geometry is computed here in Prolog; the drawer is pure projection.
 *
 * Hosts and the drawer primitives they project onto:
 *   - circle : host-circle + radial-partition (equal) ; the equipartition
 *              FAILURE for a circle is vertical-partition on the circle --
 *              equal-WIDTH vertical strips give unequal circular AREAS, the
 *              attested circle equipartition error.
 *   - bar    : a fraction-bars whole bar partitioned into explicit cells;
 *              unequal cells are emitted as splits of varying width.
 *   - area   : host-rect + explicit cells; unequal cells are varied-width rects.
 *
 * Load through paths.pl (swipl -l paths.pl); the render(...) search path resolves
 * representation_grammar and attested_deformations.
 */
:- module(parametric_fraction_errors,
          [ fraction_error_type/1,
            deformed_fraction_error_scene/4,
            error_evidence/4,
            fraction_error_host/1
          ]).

:- use_module(render(representation_grammar)).
:- use_module(render(attested_deformations)).

% --- vocabulary ------------------------------------------------------------

fraction_error_host(circle).
fraction_error_host(bar).
fraction_error_host(area).

fraction_error_type(unequal_partition).
fraction_error_type(miscount_partition).
fraction_error_type(shade_wrong_count(_M)).
fraction_error_type(wrong_referent_whole).

% --- corpus grounding ------------------------------------------------------
% error_evidence(ErrorType, Host, frac(M, N), Evidence) -- the violated grammar
% rule plus the attested pattern that licenses naming this as a misconception.
% A scene is ONLY ever drawn as a labeled misconception, never as an unlabeled
% productive diagram (representation_grammar:misconception_visual/5 discipline).
%
% AttestedPattern cites the controlled error vocabulary in
% attested_deformations:attested_representation_error/4 over the diagrammatic
% languages (area_model, set_grouping). The REALLMs corpus records these as
% representation-language errors (mostly 'unspecified_error' in the diagrammatic
% languages -- the residual bucket the equipartition failures sit in until the
% controlled vocabulary is widened to name them). Cite both the grammar rule the
% failure breaks and the corpus bucket it currently lands in, honestly.

% map a host to the grammar representation language it draws in
host_language(circle, area_model).
host_language(bar,    fraction_bars).
host_language(area,   area_model).

error_evidence(unequal_partition, Host, frac(M, N), Evidence) :-
    fraction(M, N),
    host_language(Host, Lang),
    grammar_blend_entailment(Lang, Entailment),
    attested_bucket(Lang, unequal_partition, Pattern, FigCount),
    frac_string(M, N, TaskStr),
    Evidence = _{
        mode: misconception,
        family: equipartition_failure,
        misconception: unequal_partition,
        host: Host,
        representation: Lang,
        correct_task: TaskStr,
        denominator: N,
        violated_blend_entailment: Entailment,
        violation: parts_not_equal_so_no_unit_fraction,
        attested_pattern: Pattern,
        attested_figure_count: FigCount
    }.

error_evidence(miscount_partition, Host, frac(M, N), Evidence) :-
    fraction(M, N),
    host_language(Host, Lang),
    grammar_blend_entailment(Lang, Entailment),
    drawn_region_count(miscount_partition, N, Drawn),
    attested_bucket(Lang, miscount_partition, Pattern, FigCount),
    frac_string(M, N, TaskStr),
    Evidence = _{
        mode: misconception,
        family: equipartition_failure,
        misconception: miscount_partition,
        host: Host,
        representation: Lang,
        correct_task: TaskStr,
        denominator_intended: N,
        denominator_drawn: Drawn,
        violated_blend_entailment: Entailment,
        violation: counts_the_cuts_not_the_regions_off_by_one,
        attested_pattern: Pattern,
        attested_figure_count: FigCount
    }.

error_evidence(shade_wrong_count(WrongM), Host, frac(M, N), Evidence) :-
    fraction(M, N),
    integer(WrongM),
    WrongM >= 0,
    WrongM =< N,
    WrongM =\= M,
    host_language(Host, Lang),
    attested_bucket(Lang, shade_wrong_count, Pattern, FigCount),
    frac_string(M, N, TaskStr),
    Evidence = _{
        mode: misconception,
        family: equipartition_failure,
        misconception: shade_wrong_count,
        host: Host,
        representation: Lang,
        correct_task: TaskStr,
        numerator_intended: M,
        numerator_shaded: WrongM,
        violation: wrong_number_of_unit_parts_shaded,
        attested_pattern: Pattern,
        attested_figure_count: FigCount
    }.

error_evidence(wrong_referent_whole, Host, frac(M, N), Evidence) :-
    fraction(M, N),
    host_language(Host, Lang),
    grammar_blend_entailment(Lang, Entailment),
    attested_bucket(Lang, wrong_referent_whole, Pattern, FigCount),
    frac_string(M, N, TaskStr),
    Evidence = _{
        mode: misconception,
        family: equipartition_failure,
        misconception: wrong_referent_whole,
        host: Host,
        representation: Lang,
        correct_task: TaskStr,
        denominator: N,
        violated_blend_entailment: Entailment,
        violation: partitions_a_different_whole_than_the_task_whole,
        attested_pattern: Pattern,
        attested_figure_count: FigCount
    }.

% frac_string(+M, +N, -Str): "M/N" as a string, JSON-clean (no compound term).
frac_string(M, N, Str) :-
    format(atom(A), '~w/~w', [M, N]),
    atom_string(A, Str).

% The grammar's part-whole blend entailment that an equipartition failure breaks.
% fraction_bars: blend(measuring_stick, part_whole) entails common_partitioned_whole.
% area_model:    blend(container, measuring_stick) entails multiplicative_measure_region.
grammar_blend_entailment(Lang, Entailment) :-
    representation_grammar:representation_grounding(Lang, Blend),
    representation_grammar:blend_entails(Blend, Entailment).

% Which attested corpus bucket this (language, error) currently lands in. The
% diagrammatic-language errors in the REALLMs corpus are recorded mostly as
% 'unspecified_error' (the residual bucket); cite it honestly as the corpus
% witness, with the figure count, rather than overclaiming a named bucket.
attested_bucket(Lang, _ErrorKind, Pattern, FigCount) :-
    attested_deformations:attested_representation_error(Lang, Pattern, FigCount, _Examples),
    Pattern == unspecified_error,
    !.
attested_bucket(Lang, _ErrorKind, none_in_corpus, 0) :-
    representation_grammar:representation_language(Lang).

% The off-by-one a miscount produces. Counts the N-1 internal cut lines plus the
% two boundaries as if they were regions, OR counts one region short; the
% canonical attested off-by-one draws N+1 regions (one extra). Parametric in N.
drawn_region_count(miscount_partition, N, Drawn) :-
    N >= 2,
    Drawn is N + 1.

% --- the scene builder -----------------------------------------------------
% deformed_fraction_error_scene(Host, frac(M, N), ErrorType, FramesDict).
% FramesDict is a JSON-serializable _{frames: [...], ...} document. B/M/E:
%   B establish_whole  : the host whole, intact.
%   M apply_partition  : the partition rule applied -- wrongly, per ErrorType.
%   E shade_parts      : the parts shaded -- wrongly, per ErrorType.

deformed_fraction_error_scene(Host, frac(M, N), ErrorType, FramesDict) :-
    fraction_error_host(Host),
    fraction(M, N),
    error_evidence(ErrorType, Host, frac(M, N), Evidence),
    error_frames(Host, frac(M, N), ErrorType, Frames),
    canon_error_type(ErrorType, ErrorTypeAtom),
    FramesDict = _{
        kind: parametric_fraction_error,
        host: Host,
        fraction: _{ m: M, n: N },
        error_type: ErrorTypeAtom,
        family: equipartition_failure,
        evidence: Evidence,
        canvas: _{ width: 760, height: 220 },
        frames: Frames
    }.

canon_error_type(shade_wrong_count(WrongM), Atom) :-
    !,
    format(atom(Atom), 'shade_wrong_count(~w)', [WrongM]).
canon_error_type(ErrorType, ErrorType).

% --- geometry constants ----------------------------------------------------

geom(circle, cx, 130).
geom(circle, cy, 110).
geom(circle, r, 84).
geom(bar, x, 30).
geom(bar, y, 70).
geom(bar, w, 320).
geom(bar, h, 76).
geom(area, x, 30).
geom(area, y, 60).
geom(area, w, 220).
geom(area, h, 110).

% =========================================================================
% B/M/E frame builders, per host. Each returns three frames.
% =========================================================================

error_frames(Host, frac(M, N), ErrorType, [B, MFrame, E]) :-
    establish_whole_frame(Host, frac(M, N), B),
    apply_partition_frame(Host, frac(M, N), ErrorType, MFrame),
    shade_parts_frame(Host, frac(M, N), ErrorType, E).

% --- B: establish the whole (intact, correct) ------------------------------

establish_whole_frame(circle, frac(_M, N), Frame) :-
    geom(circle, cx, CX), geom(circle, cy, CY), geom(circle, r, R),
    format(atom(Label), '1 whole (target: thirds-style ~w equal parts)', [N]),
    Frame = _{
        step: 1, verb: establish_whole,
        caption: "Establish the whole. One region, not yet partitioned.",
        sceneChanged: true,
        scene: _{ format: 'hybridization-model', version: 1,
                  primitives: [ _{ kind: 'host-circle', cx: CX, cy: CY, r: R,
                                   label: Label } ] }
    }.
establish_whole_frame(bar, frac(_M, N), Frame) :-
    geom(bar, x, X), geom(bar, y, Y), geom(bar, w, W), geom(bar, h, H),
    format(atom(Label), '1 whole (target: ~w equal parts)', [N]),
    Frame = _{
        step: 1, verb: establish_whole,
        caption: "Establish the whole bar. One length, not yet partitioned.",
        sceneChanged: true,
        scene: _{ format: 'fraction-bars', version: 1,
                  bars: [ _{ x: X, y: Y, w: W, h: H, label: Label, splits: [] } ] }
    }.
establish_whole_frame(area, frac(_M, N), Frame) :-
    geom(area, x, X), geom(area, y, Y), geom(area, w, W), geom(area, h, H),
    format(atom(Label), '1 whole (target: ~w equal parts)', [N]),
    Frame = _{
        step: 1, verb: establish_whole,
        caption: "Establish the whole region. One area, not yet partitioned.",
        sceneChanged: true,
        scene: _{ format: 'area-model', version: 1,
                  rects: [ _{ x: X, y: Y, w: W, h: H, rows: 1, cols: 1, label: Label } ] }
    }.

% --- M: apply the partition (wrongly, per ErrorType) -----------------------

% unequal_partition: N pieces, deliberately unequal. The host's own primitive,
% applied without equipartition.
apply_partition_frame(circle, frac(_M, N), unequal_partition, Frame) :-
    geom(circle, cx, CX), geom(circle, cy, CY), geom(circle, r, R),
    % equal-width vertical strips on a circle => unequal circular areas:
    % the attested circle equipartition failure, parametric in N.
    format(atom(Label), '~w vertical strips: equal WIDTH, unequal AREA', [N]),
    Frame = _{
        step: 2, verb: apply_partition,
        caption: "Cut the circle with equal-width vertical strips. The strips look even but the pieces are not equal areas.",
        sceneChanged: true,
        scene: _{ format: 'hybridization-model', version: 1,
                  primitives: [ _{ kind: 'host-circle', cx: CX, cy: CY, r: R },
                                _{ kind: 'vertical-partition', host: circle,
                                   cx: CX, cy: CY, r: R,
                                   columns: N, role: deformation, label: Label } ] }
    }.
apply_partition_frame(bar, frac(_M, N), unequal_partition, Frame) :-
    geom(bar, x, X), geom(bar, y, Y), geom(bar, w, W), geom(bar, h, H),
    unequal_widths(N, W, Widths),
    cells_from_widths(X, Y, H, Widths, 0, none, Splits),
    format(atom(Label), '~w unequal parts (no equipartition)', [N]),
    Frame = _{
        step: 2, verb: apply_partition,
        caption: "Partition the bar into parts of different sizes. There is no unit fraction because the parts are unequal.",
        sceneChanged: true,
        scene: _{ format: 'fraction-bars', version: 1,
                  bars: [ _{ x: X, y: Y, w: W, h: H, label: Label, splits: Splits } ] }
    }.
apply_partition_frame(area, frac(_M, N), unequal_partition, Frame) :-
    geom(area, x, X), geom(area, y, Y), geom(area, w, W), geom(area, h, H),
    unequal_widths(N, W, Widths),
    rects_from_widths(X, Y, H, Widths, 0, Rects),
    format(atom(Label), '~w unequal parts (no equipartition)', [N]),
    Rects = [First | Rest],
    FirstLabelled = First.put(_{label: Label}),
    Frame = _{
        step: 2, verb: apply_partition,
        caption: "Partition the region into parts of different areas. There is no unit fraction because the parts are unequal.",
        sceneChanged: true,
        scene: _{ format: 'area-model', version: 1,
                  rects: [FirstLabelled | Rest] }
    }.

% miscount_partition: draws N+1 regions (counts cut lines, off-by-one). Equal
% cells, but the wrong number of them.
apply_partition_frame(circle, frac(_M, N), miscount_partition, Frame) :-
    drawn_region_count(miscount_partition, N, Drawn),
    geom(circle, cx, CX), geom(circle, cy, CY), geom(circle, r, R),
    format(atom(Label), 'drew ~w sectors for a ~w-part task (off by one)', [Drawn, N]),
    Frame = _{
        step: 2, verb: apply_partition,
        caption: "Cut the circle into equal sectors, but count the cuts rather than the regions: one too many.",
        sceneChanged: true,
        scene: _{ format: 'hybridization-model', version: 1,
                  primitives: [ _{ kind: 'host-circle', cx: CX, cy: CY, r: R },
                                _{ kind: 'radial-partition', host: circle,
                                   cx: CX, cy: CY, r: R,
                                   segments: Drawn, role: deformation, label: Label } ] }
    }.
apply_partition_frame(bar, frac(_M, N), miscount_partition, Frame) :-
    drawn_region_count(miscount_partition, N, Drawn),
    geom(bar, x, X), geom(bar, y, Y), geom(bar, w, W), geom(bar, h, H),
    equal_widths(Drawn, W, Widths),
    cells_from_widths(X, Y, H, Widths, 0, none, Splits),
    format(atom(Label), 'drew ~w equal parts for a ~w-part task (off by one)', [Drawn, N]),
    Frame = _{
        step: 2, verb: apply_partition,
        caption: "Partition the bar into equal parts, but make the wrong number: count the cuts, not the regions.",
        sceneChanged: true,
        scene: _{ format: 'fraction-bars', version: 1,
                  bars: [ _{ x: X, y: Y, w: W, h: H, label: Label, splits: Splits } ] }
    }.
apply_partition_frame(area, frac(_M, N), miscount_partition, Frame) :-
    drawn_region_count(miscount_partition, N, Drawn),
    geom(area, x, X), geom(area, y, Y), geom(area, w, W), geom(area, h, H),
    format(atom(Label), 'drew ~w equal parts for a ~w-part task (off by one)', [Drawn, N]),
    Frame = _{
        step: 2, verb: apply_partition,
        caption: "Partition the region into equal parts, but make the wrong number: count the cuts, not the regions.",
        sceneChanged: true,
        scene: _{ format: 'area-model', version: 1,
                  rects: [ _{ x: X, y: Y, w: W, h: H, rows: 1, cols: Drawn, label: Label } ] }
    }.

% shade_wrong_count(WrongM): correct equal partition, but shades a different
% number of parts than M. The partition step is correct; the error shows in E.
apply_partition_frame(Host, frac(M, N), shade_wrong_count(_WrongM), Frame) :-
    correct_partition_frame(Host, frac(M, N), 2, apply_partition,
        "Partition the host into equal parts correctly. The error is in how many get shaded, next.",
        Frame).

% wrong_referent_whole: partitions a SECOND, differently-sized whole and reads
% the fraction off that, not the task whole. The task whole sits beside it.
apply_partition_frame(circle, frac(_M, N), wrong_referent_whole, Frame) :-
    geom(circle, cx, CX), geom(circle, cy, CY), geom(circle, r, R),
    R2 is integer(round(R * 0.55)),
    CX2 is CX + 2 * R + 40,
    format(atom(Label), 'a DIFFERENT (smaller) whole, partitioned into ~w', [N]),
    Frame = _{
        step: 2, verb: apply_partition,
        caption: "Partition a different, smaller whole into the parts, instead of the task whole on the left.",
        sceneChanged: true,
        scene: _{ format: 'hybridization-model', version: 1,
                  primitives: [ _{ kind: 'host-circle', cx: CX, cy: CY, r: R, label: 'task whole' },
                                _{ kind: 'host-circle', cx: CX2, cy: CY, r: R2 },
                                _{ kind: 'radial-partition', host: circle,
                                   cx: CX2, cy: CY, r: R2,
                                   segments: N, role: deformation, label: Label } ] }
    }.
apply_partition_frame(bar, frac(_M, N), wrong_referent_whole, Frame) :-
    geom(bar, x, X), geom(bar, y, Y), geom(bar, w, W), geom(bar, h, H),
    W2 is integer(round(W * 0.55)),
    X2 is X,
    Y2 is Y + H + 24,
    equal_widths(N, W2, Widths),
    cells_from_widths(X2, Y2, H, Widths, 0, none, Splits),
    format(atom(Label), 'a DIFFERENT (shorter) whole, partitioned into ~w', [N]),
    Frame = _{
        step: 2, verb: apply_partition,
        caption: "Partition a different, shorter whole into the parts, instead of the full task bar above.",
        sceneChanged: true,
        scene: _{ format: 'fraction-bars', version: 1,
                  bars: [ _{ x: X, y: Y, w: W, h: H, label: 'task whole', splits: [] },
                          _{ x: X2, y: Y2, w: W2, h: H, label: Label, splits: Splits } ] }
    }.
apply_partition_frame(area, frac(_M, N), wrong_referent_whole, Frame) :-
    geom(area, x, X), geom(area, y, Y), geom(area, w, W), geom(area, h, H),
    W2 is integer(round(W * 0.55)),
    X2 is X + W + 40,
    format(atom(Label), 'a DIFFERENT (smaller) whole, partitioned into ~w', [N]),
    Frame = _{
        step: 2, verb: apply_partition,
        caption: "Partition a different, smaller whole into the parts, instead of the task region on the left.",
        sceneChanged: true,
        scene: _{ format: 'area-model', version: 1,
                  rects: [ _{ x: X, y: Y, w: W, h: H, rows: 1, cols: 1, label: 'task whole' },
                           _{ x: X2, y: Y, w: W2, h: H, rows: 1, cols: N, label: Label } ] }
    }.

% --- E: shade the parts (wrongly, per ErrorType) ---------------------------

% unequal_partition: shade M of the unequal pieces. The shaded amount is not M/N
% because the pieces are not equal.
shade_parts_frame(circle, frac(M, N), unequal_partition, Frame) :-
    geom(circle, cx, CX), geom(circle, cy, CY), geom(circle, r, R),
    shade_list(M, Shade),
    format(atom(Label), 'shaded ~w of ~w unequal strips: not ~w/~w', [M, N, M, N]),
    Frame = _{
        step: 3, verb: shade_parts,
        caption: "Shade some strips. Because the strips are unequal, the shaded amount is not the intended fraction.",
        sceneChanged: true,
        scene: _{ format: 'hybridization-model', version: 1,
                  primitives: [ _{ kind: 'host-circle', cx: CX, cy: CY, r: R },
                                _{ kind: 'vertical-partition', host: circle,
                                   cx: CX, cy: CY, r: R,
                                   columns: N, role: deformation, shade: Shade,
                                   label: Label } ] }
    }.
shade_parts_frame(bar, frac(M, N), unequal_partition, Frame) :-
    geom(bar, x, X), geom(bar, y, Y), geom(bar, w, W), geom(bar, h, H),
    unequal_widths(N, W, Widths),
    cells_from_widths(X, Y, H, Widths, M, deformation, Splits),
    format(atom(Label), 'shaded ~w of ~w unequal parts: not ~w/~w', [M, N, M, N]),
    Frame = _{
        step: 3, verb: shade_parts,
        caption: "Shade some parts. Because the parts are unequal, the shaded amount is not the intended fraction.",
        sceneChanged: true,
        scene: _{ format: 'fraction-bars', version: 1,
                  bars: [ _{ x: X, y: Y, w: W, h: H, label: Label, splits: Splits } ] }
    }.
shade_parts_frame(area, frac(M, N), unequal_partition, Frame) :-
    geom(area, x, X), geom(area, y, Y), geom(area, w, W), geom(area, h, H),
    unequal_widths(N, W, Widths),
    rects_from_widths(X, Y, H, Widths, M, Rects),
    format(atom(Label), 'shaded ~w of ~w unequal parts: not ~w/~w', [M, N, M, N]),
    Rects = [First | Rest],
    FirstLabelled = First.put(_{label: Label}),
    Frame = _{
        step: 3, verb: shade_parts,
        caption: "Shade some parts. Because the parts have different areas, the shaded amount is not the intended fraction.",
        sceneChanged: true,
        scene: _{ format: 'area-model', version: 1,
                  rects: [FirstLabelled | Rest] }
    }.

% miscount_partition: shade M of the N+1 drawn regions. The denominator is wrong.
shade_parts_frame(circle, frac(M, N), miscount_partition, Frame) :-
    drawn_region_count(miscount_partition, N, Drawn),
    geom(circle, cx, CX), geom(circle, cy, CY), geom(circle, r, R),
    shade_list(M, Shade),
    format(atom(Label), 'read ~w/~w off a ~w-part figure (wanted /~w)', [M, Drawn, Drawn, N]),
    Frame = _{
        step: 3, verb: shade_parts,
        caption: "Shade and read the fraction off the miscounted figure. The denominator is off by one.",
        sceneChanged: true,
        scene: _{ format: 'hybridization-model', version: 1,
                  primitives: [ _{ kind: 'host-circle', cx: CX, cy: CY, r: R },
                                _{ kind: 'radial-partition', host: circle,
                                   cx: CX, cy: CY, r: R,
                                   segments: Drawn, role: deformation, shade: Shade,
                                   label: Label } ] }
    }.
shade_parts_frame(bar, frac(M, N), miscount_partition, Frame) :-
    drawn_region_count(miscount_partition, N, Drawn),
    geom(bar, x, X), geom(bar, y, Y), geom(bar, w, W), geom(bar, h, H),
    equal_widths(Drawn, W, Widths),
    cells_from_widths(X, Y, H, Widths, M, deformation, Splits),
    format(atom(Label), 'read ~w/~w off a ~w-part bar (wanted /~w)', [M, Drawn, Drawn, N]),
    Frame = _{
        step: 3, verb: shade_parts,
        caption: "Shade and read the fraction off the miscounted bar. The denominator is off by one.",
        sceneChanged: true,
        scene: _{ format: 'fraction-bars', version: 1,
                  bars: [ _{ x: X, y: Y, w: W, h: H, label: Label, splits: Splits } ] }
    }.
shade_parts_frame(area, frac(M, N), miscount_partition, Frame) :-
    drawn_region_count(miscount_partition, N, Drawn),
    geom(area, x, X), geom(area, y, Y), geom(area, w, W), geom(area, h, H),
    equal_widths(Drawn, W, Widths),
    rects_from_widths(X, Y, H, Widths, M, Rects),
    format(atom(Label), 'read ~w/~w off a ~w-part region (wanted /~w)', [M, Drawn, Drawn, N]),
    Rects = [First | Rest],
    FirstLabelled = First.put(_{label: Label}),
    Frame = _{
        step: 3, verb: shade_parts,
        caption: "Shade and read the fraction off the miscounted region. The denominator is off by one.",
        sceneChanged: true,
        scene: _{ format: 'area-model', version: 1,
                  rects: [FirstLabelled | Rest] }
    }.

% shade_wrong_count(WrongM): correct equal partition into N; shade WrongM, not M.
shade_parts_frame(Host, frac(_M, N), shade_wrong_count(WrongM), Frame) :-
    shade_parts_correct_partition(Host, N, WrongM, Frame).

% wrong_referent_whole: shade M parts of the wrong whole; the fraction is of the
% wrong referent.
shade_parts_frame(circle, frac(M, N), wrong_referent_whole, Frame) :-
    geom(circle, cx, CX), geom(circle, cy, CY), geom(circle, r, R),
    R2 is integer(round(R * 0.55)),
    CX2 is CX + 2 * R + 40,
    shade_list(M, Shade),
    format(atom(Label), '~w/~w of the WRONG whole', [M, N]),
    Frame = _{
        step: 3, verb: shade_parts,
        caption: "Shade the parts of the smaller whole. The fraction is of the wrong referent, not the task whole.",
        sceneChanged: true,
        scene: _{ format: 'hybridization-model', version: 1,
                  primitives: [ _{ kind: 'host-circle', cx: CX, cy: CY, r: R, label: 'task whole' },
                                _{ kind: 'host-circle', cx: CX2, cy: CY, r: R2 },
                                _{ kind: 'radial-partition', host: circle,
                                   cx: CX2, cy: CY, r: R2,
                                   segments: N, role: deformation, shade: Shade,
                                   label: Label } ] }
    }.
shade_parts_frame(bar, frac(M, N), wrong_referent_whole, Frame) :-
    geom(bar, x, X), geom(bar, y, Y), geom(bar, w, W), geom(bar, h, H),
    W2 is integer(round(W * 0.55)),
    Y2 is Y + H + 24,
    equal_widths(N, W2, Widths),
    cells_from_widths(X, Y2, H, Widths, M, deformation, Splits),
    format(atom(Label), '~w/~w of the WRONG whole', [M, N]),
    Frame = _{
        step: 3, verb: shade_parts,
        caption: "Shade the parts of the shorter whole. The fraction is of the wrong referent, not the task bar above.",
        sceneChanged: true,
        scene: _{ format: 'fraction-bars', version: 1,
                  bars: [ _{ x: X, y: Y, w: W, h: H, label: 'task whole', splits: [] },
                          _{ x: X, y: Y2, w: W2, h: H, label: Label, splits: Splits } ] }
    }.
shade_parts_frame(area, frac(M, N), wrong_referent_whole, Frame) :-
    geom(area, x, X), geom(area, y, Y), geom(area, w, W), geom(area, h, H),
    W2 is integer(round(W * 0.55)),
    X2 is X + W + 40,
    equal_widths(N, W2, Widths),
    rects_from_widths(X2, Y, H, Widths, M, Rects),
    format(atom(Label), '~w/~w of the WRONG whole', [M, N]),
    Rects = [First | Rest],
    FirstLabelled = First.put(_{label: Label}),
    Frame = _{
        step: 3, verb: shade_parts,
        caption: "Shade the parts of the smaller whole. The fraction is of the wrong referent, not the task region on the left.",
        sceneChanged: true,
        scene: _{ format: 'area-model', version: 1,
                  rects: [ _{ x: X, y: Y, w: W, h: H, rows: 1, cols: 1, label: 'task whole' }
                         | [FirstLabelled | Rest] ] }
    }.

% --- shared: correct equal partition (used by shade_wrong_count) ------------

correct_partition_frame(circle, frac(_M, N), Step, Verb, Caption, Frame) :-
    geom(circle, cx, CX), geom(circle, cy, CY), geom(circle, r, R),
    format(atom(Label), '~w equal sectors', [N]),
    Frame = _{
        step: Step, verb: Verb, caption: Caption, sceneChanged: true,
        scene: _{ format: 'hybridization-model', version: 1,
                  primitives: [ _{ kind: 'host-circle', cx: CX, cy: CY, r: R },
                                _{ kind: 'radial-partition', host: circle,
                                   cx: CX, cy: CY, r: R, segments: N, label: Label } ] }
    }.
correct_partition_frame(bar, frac(_M, N), Step, Verb, Caption, Frame) :-
    geom(bar, x, X), geom(bar, y, Y), geom(bar, w, W), geom(bar, h, H),
    format(atom(Label), '~w equal parts', [N]),
    equal_widths(N, W, Widths),
    cells_from_widths(X, Y, H, Widths, 0, none, Splits),
    Frame = _{
        step: Step, verb: Verb, caption: Caption, sceneChanged: true,
        scene: _{ format: 'fraction-bars', version: 1,
                  bars: [ _{ x: X, y: Y, w: W, h: H, label: Label, splits: Splits } ] }
    }.
correct_partition_frame(area, frac(_M, N), Step, Verb, Caption, Frame) :-
    geom(area, x, X), geom(area, y, Y), geom(area, w, W), geom(area, h, H),
    format(atom(Label), '~w equal parts', [N]),
    Frame = _{
        step: Step, verb: Verb, caption: Caption, sceneChanged: true,
        scene: _{ format: 'area-model', version: 1,
                  rects: [ _{ x: X, y: Y, w: W, h: H, rows: 1, cols: N, label: Label } ] }
    }.

shade_parts_correct_partition(circle, N, WrongM, Frame) :-
    geom(circle, cx, CX), geom(circle, cy, CY), geom(circle, r, R),
    shade_list(WrongM, Shade),
    format(atom(Label), 'shaded ~w of ~w (wrong count)', [WrongM, N]),
    Frame = _{
        step: 3, verb: shade_parts,
        caption: "Shade the wrong number of equal parts. The partition is right; the count shaded is not.",
        sceneChanged: true,
        scene: _{ format: 'hybridization-model', version: 1,
                  primitives: [ _{ kind: 'host-circle', cx: CX, cy: CY, r: R },
                                _{ kind: 'radial-partition', host: circle,
                                   cx: CX, cy: CY, r: R, segments: N,
                                   role: deformation, shade: Shade, label: Label } ] }
    }.
shade_parts_correct_partition(bar, N, WrongM, Frame) :-
    geom(bar, x, X), geom(bar, y, Y), geom(bar, w, W), geom(bar, h, H),
    equal_widths(N, W, Widths),
    cells_from_widths(X, Y, H, Widths, WrongM, deformation, Splits),
    format(atom(Label), 'shaded ~w of ~w (wrong count)', [WrongM, N]),
    Frame = _{
        step: 3, verb: shade_parts,
        caption: "Shade the wrong number of equal parts. The partition is right; the count shaded is not.",
        sceneChanged: true,
        scene: _{ format: 'fraction-bars', version: 1,
                  bars: [ _{ x: X, y: Y, w: W, h: H, label: Label, splits: Splits } ] }
    }.
shade_parts_correct_partition(area, N, WrongM, Frame) :-
    geom(area, x, X), geom(area, y, Y), geom(area, w, W), geom(area, h, H),
    equal_widths(N, W, Widths),
    rects_from_widths(X, Y, H, Widths, WrongM, Rects),
    format(atom(Label), 'shaded ~w of ~w (wrong count)', [WrongM, N]),
    Rects = [First | Rest],
    FirstLabelled = First.put(_{label: Label}),
    Frame = _{
        step: 3, verb: shade_parts,
        caption: "Shade the wrong number of equal parts. The partition is right; the count shaded is not.",
        sceneChanged: true,
        scene: _{ format: 'area-model', version: 1,
                  rects: [FirstLabelled | Rest] }
    }.

% =========================================================================
% Geometry helpers: equal vs unequal width lists; cell/rect builders.
% =========================================================================

% equal_widths(+N, +Total, -Widths): N equal cell widths summing to Total.
equal_widths(N, Total, Widths) :-
    N >= 1,
    Each is Total / N,
    length(Widths, N),
    maplist(=(Each), Widths).

% unequal_widths(+N, +Total, -Widths): N deliberately-unequal widths summing to
% Total. Parametric in N: a fixed skew pattern scaled so it always tiles the
% whole. The pattern is reproducible (same N => same widths), so the same botch
% appears for 1/5, 1/6, ... -- the replication the task asks for.
unequal_widths(N, Total, Widths) :-
    N >= 1,
    numlist(1, N, Ks),
    % weight_k: a deterministic skew that never makes a piece zero or equal.
    maplist(skew_weight(N), Ks, RawWeights),
    sum_list(RawWeights, Sum),
    maplist(scale_weight(Total, Sum), RawWeights, Widths).

% A skew weight in (0.5 .. 1.5), oscillating by index so adjacent pieces differ
% and no piece equals the equal-partition width. Deterministic in (N, K).
skew_weight(N, K, Weight) :-
    Phase is (K - 1) / max(1, N - 1),          % 0 .. 1 across the pieces
    Weight is 0.6 + 0.8 * abs(0.5 - Phase) * 2. % V-shape: ends fat, middle thin

scale_weight(Total, Sum, Raw, Width) :-
    Width is Total * Raw / Sum.

% cells_from_widths(+X, +Y, +H, +Widths, +ShadeCount, +ShadeRole, -Splits):
% lay the widths left to right as fraction-bars splits; shade the first
% ShadeCount of them with ShadeRole (an atom role, or `none` to shade nothing).
cells_from_widths(X, Y, H, Widths, ShadeCount, ShadeRole, Splits) :-
    cells_from_widths_(Widths, X, X, Y, H, 1, ShadeCount, ShadeRole, Splits).

cells_from_widths_([], _XCur, _X0, _Y, _H, _Idx, _ShadeCount, _Role, []).
cells_from_widths_([W | Ws], XCur, X0, Y, H, Idx, ShadeCount, Role, [Split | Rest]) :-
    RelX is XCur - X0,
    ( Idx =< ShadeCount, Role \== none
    -> Split = _{ x: RelX, y: 0, w: W, h: H, role: Role }
    ;  Split = _{ x: RelX, y: 0, w: W, h: H }
    ),
    XNext is XCur + W,
    Idx1 is Idx + 1,
    cells_from_widths_(Ws, XNext, X0, Y, H, Idx1, ShadeCount, Role, Rest).

% rects_from_widths(+X, +Y, +H, +Widths, +ShadeCount, -Rects): area-model rects
% laid left to right; shade the first ShadeCount with role deformation.
rects_from_widths(X, Y, H, Widths, ShadeCount, Rects) :-
    rects_from_widths_(Widths, X, Y, H, 1, ShadeCount, Rects).

rects_from_widths_([], _X, _Y, _H, _Idx, _ShadeCount, []).
rects_from_widths_([W | Ws], X, Y, H, Idx, ShadeCount, [Rect | Rest]) :-
    ( Idx =< ShadeCount
    -> Rect = _{ x: X, y: Y, w: W, h: H, rows: 1, cols: 1, role: deformation }
    ;  Rect = _{ x: X, y: Y, w: W, h: H, rows: 1, cols: 1 }
    ),
    XNext is X + W,
    Idx1 is Idx + 1,
    rects_from_widths_(Ws, XNext, Y, H, Idx1, ShadeCount, Rest).

% shade_list(+M, -List): [1, 2, ..., M], the 1-based indices the drawer shades.
shade_list(M, List) :-
    ( M =< 0 -> List = [] ; numlist(1, M, List) ).

% --- a proper fraction in range we draw cleanly ----------------------------
% The renderer stays legible for small denominators; keep N within a drawable
% band. M may exceed N (improper) -- shading clamps to the parts that exist.
fraction(M, N) :-
    integer(M), M >= 0,
    integer(N), N >= 2, N =< 12.
