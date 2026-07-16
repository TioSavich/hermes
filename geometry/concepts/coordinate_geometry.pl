% concepts/coordinate_geometry.pl — geometry concepts in the coordinate_geometry topic.
%
% Append clauses for: geom_concept/4, geom_misconception/6,
%                     material_inference/4, tier/4 (covering all of these).
% Cross-tagging (van_hiele_marker, metaphor_source, bootstrap,
% standard_anchor) lives in the corresponding subdirs.
%
% Schema: ../schema.pl

:- multifile geom_concept/4, geom_misconception/6, material_inference/4, tier/4.
:- discontiguous geom_concept/4, geom_misconception/6, material_inference/4, tier/4,
               coordinate_material_claim/5.
:- multifile triangulation/2.
:- discontiguous triangulation/2.

%!  coordinate_geometry_material_claim_witness(+Id, -Witness) is semidet.
%
%   Inspectable proof object for a finite coordinate-geometry material row.
coordinate_geometry_material_claim_witness(Id, Witness) :-
    coordinate_material_claim(Id, Concept, Premise, Conclusion, Polarity),
    coordinate_concept_tier_evidence(Concept,
                                     ConceptTierBoundary,
                                     ConceptTierEvidence),
    coordinate_related_misconception_witnesses(Concept, MisconceptionWitnesses),
    coordinate_condition_roles(Id, Roles),
    Witness = _{ kind: geometry_coordinate_material_inference,
                 scope: closed_world_finite_coordinate_geometry_table,
                 id: Id,
                 concept: Concept,
                 premise: Premise,
                 conclusion: Conclusion,
                 polarity: Polarity,
                 concept_tier_boundary: ConceptTierBoundary,
                 concept_tier_evidence: ConceptTierEvidence,
                 boundary: finite_coordinate_geometry_curriculum_claim_not_general_analytic_geometry,
                 condition_roles: Roles,
                 related_misconception_witnesses: MisconceptionWitnesses,
                 fact: material_inference(Concept, Premise, Conclusion, Polarity) }.

coordinate_concept_tier_evidence(Concept,
                                 loaded_concept_tier_record,
                                 TierEvidence) :-
    findall(_{ tier: Tier,
               sources: Sources,
               source_note: SourceNote },
            tier(ref(concept, Concept), Tier, Sources, SourceNote),
            TierEvidence),
    TierEvidence \== [],
    !.
coordinate_concept_tier_evidence(_Concept,
                                 no_concept_tier_record_in_loaded_geometry_schema,
                                 []).

coordinate_related_misconception_witnesses(Concept, Witnesses) :-
    findall(Witness,
            coordinate_misconception_witness(Concept, Witness),
            RawWitnesses),
    sort(RawWitnesses, Witnesses).

coordinate_misconception_witness(Concept,
    _{ kind: geometry_coordinate_misconception_support,
       id: Id,
       concept: Concept,
       name: Name,
       tier: Tier,
       sources: Sources,
       source_note: SourceNote,
       fact: geom_misconception(Id, Concept, Name, Triggers, Repair, Citation),
       triggers: Triggers,
       repair: Repair,
       citation: Citation }) :-
    geom_misconception(Id, Concept, Name, Triggers, Repair, Citation),
    tier(ref(misconception, Id), Tier, Sources, SourceNote).

coordinate_condition_roles(slope_ratio_over_height_only,
                           [ _{ kind: sufficiency_component,
                                role: two_points_on_nonvertical_line },
                             _{ kind: sufficiency_component,
                                role: vertical_change_over_horizontal_change }
                           ]) :-
    !.
coordinate_condition_roles(slope_invariance_over_ratio,
                           [ _{ kind: sufficiency_component,
                                role: straight_line },
                             _{ kind: invariance_component,
                                role: slope_constant_between_any_pair_of_points }
                           ]) :-
    !.
coordinate_condition_roles(oblique_3d_axis_rejection,
                           [ _{ kind: incompatibility_component,
                                role: oblique_drawing_is_perspective_convention },
                             _{ kind: incompatibility_component,
                                role: third_axis_not_negative_direction_of_other_axis }
                           ]) :-
    !.
coordinate_condition_roles(axis_label_convention,
                           [ _{ kind: sufficiency_component,
                                role: horizontal_axis_label_read },
                             _{ kind: sufficiency_component,
                                role: vertical_axis_label_read }
                           ]) :-
    !.
coordinate_condition_roles(axis_variable_reversal_rejection,
                           [ _{ kind: incompatibility_component,
                                role: axis_labels_override_context_order }
                           ]) :-
    !.
coordinate_condition_roles(slope_ratio_rejects_run_irrelevance,
                           [ _{ kind: incompatibility_component,
                                role: rise_without_run_is_insufficient_for_slope_comparison }
                           ]) :-
    !.
coordinate_condition_roles(slope_invariance_rejects_local_position,
                           [ _{ kind: incompatibility_component,
                                role: higher_position_on_straight_line_does_not_change_slope }
                           ]) :-
    !.
coordinate_condition_roles(_, []).

material_inference(Concept, Premise, Conclusion, Polarity) :-
    coordinate_geometry_material_claim_witness(_Id, Witness),
    get_dict(fact, Witness, material_inference(Concept,
                                               Premise,
                                               Conclusion,
                                               Polarity)).

% =====================================================================
% Concepts
% =====================================================================

geom_concept(coordinate_axes_3d_orthogonal,
    "In 3D, three mutually perpendicular axes; on a 2D drawing, the third axis is shown obliquely as a perspective convention",
    coordinate_geometry,
    [7,8]).

geom_concept(coordinate_axis_conventions,
    "Coordinate graphs use a fixed origin, scale, and axis-variable convention; points are interpreted by the quantity assigned to each axis",
    coordinate_geometry,
    [5,6,7,8]).

geom_concept(slope_as_ratio_of_change,
    "Slope = (change in y) / (change in x); the ratio of vertical change to horizontal change",
    coordinate_geometry,
    [6,7,8]).

geom_concept(slope_invariant_along_a_line,
    "The slope of a straight line is the same between any two points on it",
    coordinate_geometry,
    [6,7,8]).

% =====================================================================
% Tier 3 — research-corpus harvested misconceptions
% =====================================================================

% --- corpus_37622: 3D axis interpreted as negative direction in 2D
geom_misconception(
    oblique_axis_as_negative_direction,
    coordinate_axes_3d_orthogonal,
    "Oblique third axis on 2D drawing read as negative direction of the x or y axis",
    [ "this axis points down-and-left so it's negative",
      "the third axis must be the negative side",
      "drawing it diagonal means negative" ],
    "When a 3D coordinate system is sketched on paper, the third axis is drawn obliquely (typically into the page) as a perspective convention — it is *not* a continuation of the negative direction of either of the other axes. The three axes are mutually perpendicular in 3D space; the diagonal drawing is just how 3D is rendered on a 2D sheet.",
    [corpus_37622]).

tier(ref(misconception, oblique_axis_as_negative_direction), 3,
     [corpus_37622], "single-source corpus row 37622").

% --- corpus_38154: distance-time graph axes reversed
geom_misconception(
    axis_variable_reversal,
    coordinate_axis_conventions,
    "Axis variables reversed or assigned by context familiarity rather than the graph convention",
    [ "distance goes on the x-axis",
      "time should be on the y-axis",
      "I put distance first because that is what the problem is about" ],
    "Read the axis labels and scale before naming ordered pairs. The horizontal axis and vertical axis each name a quantity; reversing them changes both the coordinates and the relationship represented.",
    [corpus_38154]).

tier(ref(misconception, axis_variable_reversal), 3,
     [corpus_38154], "single-source corpus row 38154").

% --- corpus_38341 (Lobato & Siebert): steepness / height conflation
geom_misconception(
    steepness_as_height_only,
    slope_as_ratio_of_change,
    "Steepness conflated with height (the run is treated as a side-effect rather than independent)",
    [ "the steeper hill is the taller one",
      "steepness is just how high you go",
      "if the height is bigger, the slope is bigger" ],
    "Slope is the *ratio* of height (rise) to length (run), not just height. A 4-foot rise over a 2-foot run is steeper than a 4-foot rise over an 8-foot run — same height, different slopes. Always pair the height with its corresponding horizontal distance.",
    [corpus_38341, corpus_38411]).

tier(ref(misconception, steepness_as_height_only), 3,
     [corpus_38341, corpus_38411], "two-source").

% --- corpus_38342 (Lobato): slope increases as you go up the hill
geom_misconception(
    slope_increases_along_hill,
    slope_invariant_along_a_line,
    "Slope of a straight ramp assumed to increase as you climb higher",
    [ "the steeper part is at the top",
      "going up makes it steeper",
      "the slope grows with height" ],
    "On a *straight* ramp, the slope is constant — same rise/run anywhere along the line. Slope changes only when the line itself bends. Confusion may come from the climber's perceived effort (which is an embodied response, not a geometric measure).",
    [corpus_38342]).

tier(ref(misconception, slope_increases_along_hill), 3,
     [corpus_38342], "single-source corpus row 38342").

% --- corpus_38411 (Lobato & Siebert): slope as length
geom_misconception(
    slope_measured_as_length,
    slope_as_ratio_of_change,
    "Slope measured as the length of the slanted line (a single linear measurement)",
    [ "the slope is the length of the ramp",
      "I measured the slant in inches",
      "longer slant means more slope" ],
    "Slope is dimensionless (or ratio of like units): rise over run. The slant length doesn't enter directly. A 6-foot ramp could be steep or shallow depending on whether the height is 5 feet or 1 foot.",
    [corpus_38411]).

tier(ref(misconception, slope_measured_as_length), 3,
     [corpus_38411], "single-source corpus row 38411").

% --- corpus_39402 (Mitchelmore & White): slope as a single line, no reference axis
geom_misconception(
    slope_without_horizontal_reference,
    slope_as_ratio_of_change,
    "Slope conceived as a single sloped line without a horizontal reference",
    [ "the slope is just the angle of the line",
      "I show the slope by drawing the slanted line",
      "slope only needs one direction" ],
    "Slope quantifies the relationship between vertical change and horizontal change — both are needed. Always draw (or imagine) the horizontal reference line and measure rise vs run from it.",
    [corpus_39402]).

tier(ref(misconception, slope_without_horizontal_reference), 3,
     [corpus_39402], "single-source corpus row 39402").

% =====================================================================
% Material inferences
% =====================================================================

coordinate_material_claim(slope_ratio_over_height_only,
    slope_as_ratio_of_change,
    "two points (x1,y1) and (x2,y2) lie on a non-vertical line",
    "the slope of the line is (y2-y1)/(x2-x1)",
    entitled).

coordinate_material_claim(slope_invariance_over_ratio,
    slope_invariant_along_a_line,
    "line L is straight",
    "the slope of L is the same between any pair of points on L",
    entitled).

coordinate_material_claim(oblique_3d_axis_rejection,
    coordinate_axes_3d_orthogonal,
    "the third axis on a 2D drawing of a 3D system is drawn obliquely",
    "the third axis represents the negative direction of one of the other two axes",
    incompatible).

coordinate_material_claim(axis_label_convention,
    coordinate_axis_conventions,
    "the graph labels time on the horizontal axis and distance on the vertical axis",
    "the first coordinate records time and the second coordinate records distance",
    entitled).

coordinate_material_claim(axis_variable_reversal_rejection,
    coordinate_axis_conventions,
    "the context mentions distance and time",
    "distance must be plotted on the horizontal axis regardless of labels",
    incompatible).

coordinate_material_claim(slope_ratio_rejects_run_irrelevance,
    slope_as_ratio_of_change,
    "the height (rise) of a ramp is greater",
    "the slope is greater regardless of the run",
    incompatible).

coordinate_material_claim(slope_invariance_rejects_local_position,
    slope_invariant_along_a_line,
    "I am at a higher point on a straight ramp",
    "the local slope is steeper than at a lower point",
    incompatible).
