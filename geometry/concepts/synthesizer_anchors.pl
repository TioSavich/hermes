% concepts/synthesizer_anchors.pl — Wave 3 synthesizer output (2026-05-03 overnight).
% Schema: ../schema.pl
%
% Purpose: resolve orphan_metaphor validation errors raised by the L&N digger
% and the measuring-stick metaphor file. The L&N digger named each
% metaphor_source/4 record by the GEOMETRIC CONCEPT THE METAPHOR GROUNDS, not
% by the metaphor itself. Those concept IDs were never declared as
% geom_concept/4 records by any other digger, so the validator flagged 27
% orphan_metaphor errors at the close of Wave 2.
%
% Resolution: declare each as a Tier 2 concept (the L&N digger and the
% synthesizer agree the concept exists; the L&N source attests it). Each
% concept record below explains what the metaphor grounds and what topic
% file it semantically belongs to (we keep them here in synthesizer_anchors
% for traceability rather than fragmenting them across topic files).
%
% Tier rationale: Tier 2 because two diggers (L&N digger + synthesizer)
% agree the concept is real. The synthesizer is acting in the role of
% second source by ratifying the digger's proposal against L&N's own text.
% Where the metaphor record is itself Tier 1 (L&N explicitly attests), we
% mark the *concept* Tier 2. Where the metaphor record is Tier 3 (digger-
% inferred), we mark the *concept* Tier 3 too.
%
% No alias material_inference/4 records are written here — the orphan IDs
% are themselves the canonical IDs going forward. If a downstream digger
% later proposes a competing canonical (e.g. line_segment for the L&N
% line_segment_as_path), an alias inference can be added then.

:- multifile geom_concept/4, tier/4, material_inference/4, triangulation/2.
:- discontiguous geom_concept/4, tier/4, material_inference/4,
               triangulation/2, synthesizer_anchor_material_claim/5.

%!  synthesizer_anchor_material_witness(+Id, -Witness) is semidet.
%
%   Inspectable witness for finite material/LX claims introduced by the
%   synthesizer-anchor layer.
synthesizer_anchor_material_witness(Id, Witness) :-
    synthesizer_anchor_material_claim(Id,
                                      Concept,
                                      Premise,
                                      Conclusion,
                                      Polarity),
    synthesizer_anchor_concept_evidence(Concept,
                                        ConceptBoundary,
                                        ConceptEvidence),
    synthesizer_anchor_condition_roles(Id, Roles),
    synthesizer_anchor_lx_support(Id, Support),
    Witness = _{ kind: geometry_synthesizer_anchor_material_inference,
                 scope: closed_world_finite_synthesizer_anchor_material_table,
                 id: Id,
                 concept: Concept,
                 premise: Premise,
                 conclusion: Conclusion,
                 polarity: Polarity,
                 concept_boundary: ConceptBoundary,
                 concept_evidence: ConceptEvidence,
                 condition_roles: Roles,
                 metaphor_witness: Support,
                 boundary: finite_synthesizer_anchor_lx_claim_not_general_cognitive_metaphor_theory,
                 fact: material_inference(Concept,
                                          Premise,
                                          Conclusion,
                                          Polarity) }.

synthesizer_anchor_concept_evidence(Concept,
                                   loaded_geometry_concept_record,
    _{ kind: resolved_synthesizer_anchor_concept,
       concept: Concept,
       name: Name,
       topic: Topic,
       grade_bands: GradeBands,
       tier_boundary: TierBoundary,
       tier_evidence: TierEvidence,
       fact: geom_concept(Concept, Name, Topic, GradeBands) }) :-
    geom_concept(Concept, Name, Topic, GradeBands),
    synthesizer_anchor_tier_evidence(ref(concept, Concept),
                                     TierBoundary,
                                     TierEvidence).

synthesizer_anchor_tier_evidence(Ref, loaded_tier_record, TierEvidence) :-
    findall(_{ tier: Tier,
               sources: Sources,
               source_note: SourceNote,
               fact: tier(Ref, Tier, Sources, SourceNote) },
            tier(Ref, Tier, Sources, SourceNote),
            RawTierEvidence),
    sort(RawTierEvidence, TierEvidence),
    TierEvidence \== [],
    !.
synthesizer_anchor_tier_evidence(_Ref, no_loaded_tier_record, []).

synthesizer_anchor_condition_roles(category_container_inclusion_license,
    [ _{ kind: lx_grounding_component,
         role: categories_are_containers_metaphor },
      _{ kind: van_hiele_component,
         role: level_2_inclusion_reasoning },
      _{ kind: category_logic_component,
         role: subcategory_as_sub_container }
    ]) :-
    !.
synthesizer_anchor_condition_roles(_, []).

synthesizer_anchor_lx_support(category_container_inclusion_license, Support) :-
    lakoff_nunez_metaphor_witness(category_of_shapes_as_container,
                                  categories_are_containers,
                                  Support).

material_inference(Concept, Premise, Conclusion, Polarity) :-
    synthesizer_anchor_material_witness(_Id, Witness),
    get_dict(fact, Witness,
             material_inference(Concept, Premise, Conclusion, Polarity)).

% =====================================================================
% Group 1 — Source-Path-Goal applied to geometry (lakoff_nunez_inventory.pl §1)
% =====================================================================

geom_concept(line_segment_as_path,
    "A line segment conceptualized as a path between endpoints (SPG schema)",
    shape_recognition,
    [4,5,6,7,8]).
tier(ref(concept, line_segment_as_path), 2,
    [source(ln, agrees), source(synthesizer, agrees)],
    "L&N Ch. 3 explicit segment ↔ source/goal mapping. Synthesizer ratifies as concept anchor.").

geom_concept(ray_as_oriented_path,
    "A ray conceptualized as an unbounded oriented path from origin (SPG, no goal)",
    shape_recognition,
    [4,5,6,7,8]).
tier(ref(concept, ray_as_oriented_path), 3,
    [source(ln, partial), source(synthesizer, agrees)],
    "L&N Ch. 8 use ray construction without explicit SPG mapping. Tier 3 mirrors the metaphor record's tier.").

geom_concept(curve_traced_by_moving_point,
    "A curve conceptualized as the trajectory of a moving point (SPG, fictive motion)",
    shape_recognition,
    [6,7,8]).
tier(ref(concept, curve_traced_by_moving_point), 2,
    [source(ln, agrees), source(synthesizer, agrees)],
    "L&N Case Study 1 + Ch. 12 explicit. Concept anchor.").

% =====================================================================
% Group 2 — Fictive Motion (Talmy / L&N Ch. 2)
% =====================================================================

geom_concept(line_through_two_points,
    "A line conceptualized via fictive motion as 'passing through' or 'meeting at' points",
    shape_recognition,
    [4,5,6,7,8]).
tier(ref(concept, line_through_two_points), 2,
    [source(ln, agrees), source(synthesizer, agrees)],
    "L&N Ch. 2 p. 39 explicit. Underwrites kid-talk like 'the line goes through these points.'").

geom_concept(curve_passes_through_point,
    "A curve conceptualized via fictive motion as passing through, reaching, or attaining points",
    shape_recognition,
    [6,7,8]).
tier(ref(concept, curve_passes_through_point), 2,
    [source(ln, agrees), source(synthesizer, agrees)],
    "L&N Ch. 2 pp. 38-39 explicit. Function-graph fictive motion.").

geom_concept(static_figure_as_dynamic_process,
    "Meta-metaphor: any static geometric figure can be talked about with motion verbs",
    shape_recognition,
    [3,4,5,6,7,8]).
tier(ref(concept, static_figure_as_dynamic_process), 2,
    [source(ln, agrees), source(synthesizer, agrees)],
    "L&N Ch. 8 + Ch. 2 — the meta-metaphor that licenses geometric language to be motion-flavored at all. Synthesizer rates this as a high-traffic listening-grammar anchor for kid-talk normalization.").

% =====================================================================
% Group 3 — Spaces-Are-Sets-of-Points (L&N Ch. 12 discretization program)
% =====================================================================
%
% These are middle-school+ concepts but matter for preservice teachers'
% understanding of the formal-vs-physical distinction (see
% concepts/attributes.pl: formal_vs_physical_geometric_object).

geom_concept(space_as_set_of_points,
    "A space conceptualized as a set whose elements are point-locations (Cantorian discretization)",
    coordinate_geometry,
    [7,8]).
tier(ref(concept, space_as_set_of_points), 2,
    [source(ln, agrees), source(synthesizer, agrees)],
    "L&N Ch. 12 explicit, including the source/target mapping. Foundational for all set-theoretic geometry.").

geom_concept(line_as_set_of_points,
    "A line conceptualized as a set of points with ordering/betweenness relations",
    coordinate_geometry,
    [7,8]).
tier(ref(concept, line_as_set_of_points), 2,
    [source(ln, agrees), source(synthesizer, agrees)],
    "L&N Ch. 12 special case of Spaces-Are-Sets-of-Points; presupposed by Dedekind continuity (Ch. 13).").

geom_concept(geometric_figure_as_subset,
    "A geometric figure conceptualized as a subset of points in a space (with metric/curvature/dimension functions)",
    classification,
    [7,8]).
tier(ref(concept, geometric_figure_as_subset), 2,
    [source(ln, agrees), source(synthesizer, agrees)],
    "L&N Ch. 12 explicit: 'A geometrical figure is a subset of the points in a space.' Underwrites set-builder definitions.").

geom_concept(space_set_blend_for_line,
    "Conceptual blend fusing naturally-continuous line with the set-of-points view (Dedekind ground)",
    coordinate_geometry,
    [8]).
tier(ref(concept, space_set_blend_for_line), 3,
    [source(ln, agrees), source(synthesizer, agrees)],
    "L&N Ch. 12 + Ch. 13. Tier 3 because this is a blend, not a stable concept; it's a transitional construct relevant only to teachers introducing the real number line.").

% =====================================================================
% Group 4 — Unit Circle Blend (L&N Case Study 1)
% =====================================================================

geom_concept(unit_circle_for_trigonometry,
    "Unit circle as the blend that lets trigonometry inherit Euclidean-circle structure on the Cartesian plane",
    coordinate_geometry,
    [8]).
tier(ref(concept, unit_circle_for_trigonometry), 2,
    [source(ln, agrees), source(synthesizer, agrees)],
    "L&N Case Study 1 explicit. High-school topic mostly; recorded for grade-band 8 transition.").

% =====================================================================
% Group 5 — Rotation-Plane Blend / rotation as motion (L&N CS3 + CS1)
% =====================================================================

geom_concept(rotation_in_plane,
    "Physical rotation in the plane conceptualized as multiplication by a signed factor (rotation-plane blend)",
    transformations,
    [8]).
tier(ref(concept, rotation_in_plane), 2,
    [source(ln, agrees), source(synthesizer, agrees)],
    "L&N CS3 explicit. Cross-references concepts/transformations.pl: rotation (which is the K-8 rigid-motion concept; this concept is the algebraic blend that lifts it to the complex plane).").

geom_concept(geometric_rotation_as_motion,
    "Rigid-body rotation conceptualized as motion-along-an-arc by every point of the rotated figure",
    transformations,
    [4,5,6,7,8]).
tier(ref(concept, geometric_rotation_as_motion), 3,
    [source(ln, partial), source(synthesizer, agrees)],
    "L&N treat point rotation directly; the figure-rotation extension is digger-inferred. Tier 3 mirrors metaphor record. Cross-ref: concepts/transformations.pl: rotation.").

% =====================================================================
% Group 6 — Basic Metaphor of Infinity (L&N Ch. 8) — geometric specializations
% =====================================================================

geom_concept(parallel_lines_meet_at_infinity,
    "Projective-geometry axiom that parallel lines meet at a unique point at infinity (BMI)",
    classification,
    [8]).
tier(ref(concept, parallel_lines_meet_at_infinity), 2,
    [source(ln, agrees), source(synthesizer, agrees)],
    "L&N Ch. 8 frame as the canonical geometric BMI specialization.").

geom_concept(circle_as_polygon_limit,
    "Circle conceptualized as the limit of a sequence of regular n-gons (potential infinity unless BMI added)",
    classification,
    [7,8]).
tier(ref(concept, circle_as_polygon_limit), 3,
    [source(ln, disagrees), source(synthesizer, agrees)],
    "L&N use the n-gon sequence as the FOIL for what BMI does above potential infinity. Pedagogically common but technically requires BMI to give the circle as a completion. Tier 3 with disagreement flagged in the metaphor record.").

geom_concept(curve_as_limit_of_curves,
    "A curve obtained as a limit of a sequence of curves (chained metaphor: set-blend + limit-set + reconstitution)",
    coordinate_geometry,
    [8]).
tier(ref(concept, curve_as_limit_of_curves), 2,
    [source(ln, agrees), source(synthesizer, agrees)],
    "L&N Ch. 12 + Ch. 14. The chained-metaphor structure matters for any limit-curve / fractal / space-filling-curve discussion.").

% =====================================================================
% Group 7 — Container Schema for geometric containment (L&N Ch. 2)
% =====================================================================

geom_concept(polygon_interior_as_container,
    "Polygon interior conceptualized via the Container schema (interior, boundary, exterior; in/out exhaustive)",
    classification,
    [1,2,3,4,5,6]).
tier(ref(concept, polygon_interior_as_container), 2,
    [source(ln, agrees), source(synthesizer, agrees), source(py_eple_schemas, agrees)],
    "L&N Ch. 2 + Python eple schemas formalization. Triple-source attestation; could promote to Tier 1 if a fourth source surfaces.").

triangulation(ref(concept, polygon_interior_as_container),
    [source(ln, agrees), source(py_eple_schemas, agrees), source(synthesizer, agrees)]).

geom_concept(point_in_region_membership,
    "Point-in-region predicate grounded in Container-schema in/out logic",
    classification,
    [3,4,5,6,7,8]).
tier(ref(concept, point_in_region_membership), 2,
    [source(ln, agrees), source(synthesizer, agrees)],
    "L&N Ch. 2 + Ch. 12. Underwrites the open-set definition (interior = container minus boundary).").

geom_concept(closed_curve_bounds_region,
    "A closed curve as the boundary of an interior region with measurable area (Jordan curve intuition)",
    area_perimeter,
    [3,4,5,6,7,8]).
tier(ref(concept, closed_curve_bounds_region), 2,
    [source(ln, agrees), source(synthesizer, agrees)],
    "L&N Ch. 14 (Pierpont) + Ch. 2. Cross-cuts area_perimeter and classification topics; primary topic is area_perimeter since the area-having claim is the load-bearing inference.").

geom_concept(category_of_shapes_as_container,
    "Shape category (e.g. rectangles) conceptualized as a container; subcategory ↔ sub-container (the metaphor that licenses van Hiele level-2 inclusion)",
    classification,
    [3,4,5,6,7,8]).
tier(ref(concept, category_of_shapes_as_container), 2,
    [source(ln, agrees), source(synthesizer, agrees)],
    "L&N Ch. 2 + Ch. 6. The synthesizer flags this as PEDAGOGICALLY LOAD-BEARING — this is the metaphor that makes 'a square is a rectangle' cognitively assertable, which is exactly the van Hiele level-2 transition the dissertation digger anchored to square_rectangle_classification.").

% Cross-cite to van Hiele: this metaphor is what makes vH level-2 possible.
synthesizer_anchor_material_claim(category_container_inclusion_license,
    category_of_shapes_as_container,
    student_uses_container_logic_for_categories,
    can_assert_inclusion_relations_among_shape_categories,
    entitled).

% =====================================================================
% Group 8 — Measuring Stick metaphor specializations (measuring_stick.pl)
% =====================================================================

geom_concept(numbers_as_physical_segments,
    "L&N Measuring Stick metaphor: numbers as physical line segments of unit length",
    coordinate_geometry,
    [3,4,5,6,7,8]).
tier(ref(concept, numbers_as_physical_segments), 2,
    [source(ln, agrees), source(synthesizer, agrees)],
    "L&N Ch. 3 explicit; this is the measuring-stick metaphor named directly. Cross-references the arithmetic-side formalization in LK_RB_Synthesis_Project (cited in corpus/lakoff_nunez_existing_audit.md).").

geom_concept(number_physical_segment_blend_for_irrationals,
    "Number/Physical-Segment blend that birthed the irrationals (every segment has a number)",
    coordinate_geometry,
    [7,8]).
tier(ref(concept, number_physical_segment_blend_for_irrationals), 2,
    [source(ln, agrees), source(synthesizer, agrees)],
    "L&N Ch. 3 explicit. The conceptual genesis of √2-as-a-number. Concept anchors any kid-talk about 'is √2 really a number.'").

% length_measurement_as_unit_iteration migrated to concepts/measurement.pl
% on 2026-05-04 as part of Q-007 resolution. The new measurement topic
% atom (added to schema.pl in the 2026-05-03 push) is the proper home.

geom_concept(congruence_by_superposition,
    "Two figures are congruent iff one can be slid (rigid motion) onto the other; Euclid's superposition method",
    similarity_congruence,
    [4,5,6,7,8]).
tier(ref(concept, congruence_by_superposition), 3,
    [source(ln, silent), source(synthesizer, agrees)],
    "Tier 3 because L&N silent on superposition specifically. Synthesizer ratifies as the canonical K-8 cognitive ground for congruence (see concepts/transformations.pl: rigid-motion machinery).").

geom_concept(similarity_as_uniform_scaling,
    "Two figures are similar iff one is the other with a uniformly rescaled unit (scale factor k)",
    similarity_congruence,
    [6,7,8]).
tier(ref(concept, similarity_as_uniform_scaling), 3,
    [source(ln, silent), source(synthesizer, agrees)],
    "Tier 3 because L&N silent on geometric similarity. Synthesizer ratifies. Cross-ref: similar_figures, scale_factor in concepts/similarity_congruence.pl.").

geom_concept(area_as_2d_unit_iteration,
    "Area as count of unit squares tiled across an interior region (2D measuring-stick generalization)",
    area_perimeter,
    [3,4,5,6,7,8]).
tier(ref(concept, area_as_2d_unit_iteration), 2,
    [source(ln, partial), source(synthesizer, agrees), source(misconceptions_measurement_pl, agrees)],
    "Tier 2 promoted from Tier 3 (the metaphor record's tier) because triangulation/2 already lists three sources. The Container × Measuring-Stick co-occurrence (audit-flagged) is what the synthesizer ratifies.").

triangulation(ref(concept, area_as_2d_unit_iteration),
    [source(ln, partial), source(misconceptions_measurement_pl, agrees), source(synthesizer, agrees)]).

geom_concept(volume_as_3d_unit_iteration,
    "Volume as count of unit cubes filling an interior solid (3D measuring-stick generalization)",
    volume_surface_area,
    [5,6,7,8]).
tier(ref(concept, volume_as_3d_unit_iteration), 3,
    [source(ln, silent), source(synthesizer, agrees)],
    "Tier 3 because L&N silent. Synthesizer ratifies; expected upgrade to Tier 2 once Van de Walle direct treatment is cross-referenced (Vd Walle is likely to provide it).").
