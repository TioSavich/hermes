% concepts/volume_surface_area.pl — geometry concepts in the volume_surface_area topic.
%
% Append clauses for: geom_concept/4, geom_misconception/6,
%                     material_inference/4, tier/4 (covering all of these).
% Cross-tagging (van_hiele_marker, metaphor_source, bootstrap,
% standard_anchor) lives in the corresponding subdirs.
%
% Schema: ../schema.pl

:- multifile geom_concept/4, geom_misconception/6, material_inference/4, tier/4.
:- discontiguous geom_concept/4, geom_misconception/6, material_inference/4, tier/4,
               volume_surface_area_material_claim/5.

%!  volume_surface_area_material_claim_witness(+Id, -Witness) is semidet.
%
%   Inspectable proof object for a finite volume/surface-area material row.
volume_surface_area_material_claim_witness(Id, Witness) :-
    witness_dict:witness_dict(geometry_volume_surface_area_material_inference, closed_world_finite_volume_surface_area_table,
                              _{id: Id,
                 concept: Concept,
                 premise: Premise,
                 conclusion: Conclusion,
                 polarity: Polarity,
                 concept_tier_boundary: ConceptTierBoundary,
                 concept_tier_evidence: ConceptTierEvidence,
                 boundary: finite_volume_surface_area_curriculum_claim_not_general_solid_geometry,
                 condition_roles: Roles,
                 related_misconception_witnesses: MisconceptionWitnesses,
                 fact: material_inference(Concept, Premise, Conclusion, Polarity) }, WitnessDict27),
    volume_surface_area_material_claim(Id, Concept, Premise, Conclusion, Polarity),
    volume_surface_area_concept_tier_evidence(Concept,
                                              ConceptTierBoundary,
                                              ConceptTierEvidence),
    volume_surface_area_related_misconception_witnesses(
        Concept,
        MisconceptionWitnesses
    ),
    volume_surface_area_condition_roles(Id, Roles),
    Witness = WitnessDict27.

volume_surface_area_concept_tier_evidence(Concept,
                                          loaded_concept_tier_record,
                                          TierEvidence) :-
    findall(_{ tier: Tier,
               sources: Sources,
               source_note: SourceNote },
            tier(ref(concept, Concept), Tier, Sources, SourceNote),
            TierEvidence),
    TierEvidence \== [],
    !.
volume_surface_area_concept_tier_evidence(_Concept,
                                          no_concept_tier_record_in_loaded_geometry_schema,
                                          []).

volume_surface_area_related_misconception_witnesses(Concept, Witnesses) :-
    findall(Witness,
            volume_surface_area_misconception_witness(Concept, Witness),
            RawWitnesses),
    sort(RawWitnesses, Witnesses).

volume_surface_area_misconception_witness(Concept,
    _{ kind: geometry_volume_surface_area_misconception_support,
       id: Id,
       concept: Concept,
       name: Name,
       tier: Tier,
       sources: Sources,
       source_note: SourceNote,
       fact: geom_misconception(Id, Concept, Name, Triggers, Repair, Citation),
       triggers: Triggers,
       repair: Repair,
       citation: Citation,
       triangulation_evidence: TriangulationEvidence }) :-
    geom_misconception(Id, Concept, Name, Triggers, Repair, Citation),
    volume_surface_area_triangulation_evidence(Id, TriangulationEvidence),
    tier(ref(misconception, Id), Tier, Sources, SourceNote).

volume_surface_area_triangulation_evidence(Id, Evidence) :-
    findall(_{ record: ref(misconception, Id),
               agreement: Agreement },
            triangulation(ref(misconception, Id), Agreement),
            RawEvidence),
    sort(RawEvidence, Evidence).

volume_surface_area_condition_roles(euler_convex_polyhedron_formula,
                                    [ _{ kind: sufficiency_component,
                                         role: convex_polyhedron },
                                      _{ kind: structural_component,
                                         role: faces_vertices_edges_counted }
                                    ]) :-
    !.
volume_surface_area_condition_roles(prism_volume_base_times_height,
                                    [ _{ kind: sufficiency_component,
                                         role: base_area_known },
                                      _{ kind: sufficiency_component,
                                         role: height_known },
                                      _{ kind: unit_component,
                                         role: cubic_units }
                                    ]) :-
    !.
volume_surface_area_condition_roles(pyramid_volume_one_third_base_height,
                                    [ _{ kind: sufficiency_component,
                                         role: base_area_known },
                                      _{ kind: sufficiency_component,
                                         role: height_known },
                                      _{ kind: ratio_component,
                                         role: one_third_of_corresponding_prism }
                                    ]) :-
    !.
volume_surface_area_condition_roles(cubic_volume_scaling,
                                    [ _{ kind: invariance_component,
                                         role: three_independent_linear_dimensions_scaled },
                                      _{ kind: sufficiency_component,
                                         role: volume_factor_is_k_cubed }
                                    ]) :-
    !.
volume_surface_area_condition_roles(dimension_surface_coverage_area,
                                    [ _{ kind: classification_component,
                                         role: surface_coverage_is_two_dimensional },
                                      _{ kind: quantity_component,
                                         role: relevant_quantity_is_area }
                                    ]) :-
    !.
volume_surface_area_condition_roles(dimension_space_filling_volume,
                                    [ _{ kind: classification_component,
                                         role: space_filling_is_three_dimensional },
                                      _{ kind: quantity_component,
                                         role: relevant_quantity_is_volume }
                                    ]) :-
    !.
volume_surface_area_condition_roles(dimension_boundary_length,
                                    [ _{ kind: classification_component,
                                         role: boundary_or_distance_is_one_dimensional },
                                      _{ kind: quantity_component,
                                         role: relevant_quantity_is_length }
                                    ]) :-
    !.
volume_surface_area_condition_roles(visible_faces_not_volume,
                                    [ _{ kind: incompatibility_component,
                                         role: surface_faces_do_not_count_hidden_unit_cubes },
                                      _{ kind: necessary_condition_missing,
                                         role: complete_interior_unit_cube_count }
                                    ]) :-
    !.
volume_surface_area_condition_roles(volume_scaling_rejects_linear_or_quadratic,
                                    [ _{ kind: incompatibility_component,
                                         role: volume_scales_cubically_not_linearly_or_quadratically }
                                    ]) :-
    !.
volume_surface_area_condition_roles(base_orientation_rejection,
                                    [ _{ kind: incompatibility_component,
                                         role: base_is_structural_not_bottom_face },
                                      _{ kind: invariance_component,
                                         role: reorientation_does_not_change_base_relation }
                                    ]) :-
    !.
volume_surface_area_condition_roles(_, []).

material_inference(Concept, Premise, Conclusion, Polarity) :-
    volume_surface_area_material_claim_witness(_Id, Witness),
    get_dict(fact, Witness, material_inference(Concept,
                                               Premise,
                                               Conclusion,
                                               Polarity)).

% =====================================================================
% N103 (Aichele & Wolfe 2008) — Chapter 4 (3D Geometry) and Chapter 9 (Cones/Cylinders)
% =====================================================================

geom_concept(polyhedron,
    "A 3D solid figure whose surface is made up entirely of flat polygons (faces); no curved surfaces permitted",
    volume_surface_area,
    [3,4,5,6,7,8]).

tier(ref(concept, polyhedron), 1,
     [n103_ch4],
     "N103 Activity 4.1. Plural: polyhedra. Vocabulary: faces, edges, vertices.").

geom_concept(face_of_polyhedron,
    "A polygon that forms part of the surface of a polyhedron",
    volume_surface_area,
    [3,4,5,6,7,8]).

tier(ref(concept, face_of_polyhedron), 1,
     [n103_ch4],
     "Standard term named in N103 Activity 4.1.").

geom_concept(edge_of_polyhedron,
    "A line segment where two faces of a polyhedron meet",
    volume_surface_area,
    [3,4,5,6,7,8]).

tier(ref(concept, edge_of_polyhedron), 1,
     [n103_ch4],
     "Standard term named in N103 Activity 4.1.").

geom_concept(vertex_of_polyhedron,
    "A pointy corner where three or more edges of a polyhedron meet",
    volume_surface_area,
    [3,4,5,6,7,8]).

tier(ref(concept, vertex_of_polyhedron), 1,
     [n103_ch4],
     "Standard term; N103 Activity 4.1 calls them 'pointy corners.'").

geom_concept(eulers_polyhedron_formula,
    "For a convex polyhedron, F + V - E = 2 (faces plus vertices minus edges)",
    volume_surface_area,
    [6,7,8]).

tier(ref(concept, eulers_polyhedron_formula), 1,
     [n103_ch4],
     "N103 Activity 4.8 ('Edges, Faces, and Vertices of Polyhedra') has students discover this empirically before naming it Euler's formula.").

volume_surface_area_material_claim(euler_convex_polyhedron_formula,
    eulers_polyhedron_formula,
    "polyhedron P is convex AND has F faces, V vertices, E edges",
    "F + V - E = 2",
    entitled).

geom_concept(prism_n103,
    "A polyhedron with two congruent parallel faces (the bases) and lateral faces that are parallelograms",
    volume_surface_area,
    [3,4,5,6,7,8]).

tier(ref(concept, prism_n103), 1,
     [n103_ch4, ccss_6g],
     "N103 Activity 4.4 gives the canonical N103 definition: two congruent parallel faces, parallelogram lateral faces. Named by base shape (triangular, pentagonal, etc.).").

geom_concept(right_prism,
    "A prism whose lateral faces are perpendicular to the bases (lateral faces are rectangles)",
    volume_surface_area,
    [4,5,6,7,8]).

tier(ref(concept, right_prism), 1,
     [n103_ch4],
     "N103 Activity 4.4.").

geom_concept(oblique_prism,
    "A prism whose lateral faces are parallelograms but not rectangles (not perpendicular to bases)",
    volume_surface_area,
    [5,6,7,8]).

tier(ref(concept, oblique_prism), 1,
     [n103_ch4],
     "N103 Activity 4.4.").

geom_concept(parallelepiped,
    "A prism all of whose faces are parallelograms; faces come in opposite parallel pairs",
    volume_surface_area,
    [6,7,8]).

tier(ref(concept, parallelepiped), 1,
     [n103_ch4],
     "N103 Activity 4.4. Right parallelepiped = box.").

geom_concept(pyramid_n103,
    "A polyhedron with a polygonal base and an apex, where every other face is a triangle joining the apex to an edge of the base",
    volume_surface_area,
    [3,4,5,6,7,8]).

tier(ref(concept, pyramid_n103), 1,
     [n103_ch4, ccss_6g],
     "N103 Activity 4.7. Named by base shape.").

geom_concept(apex,
    "The single vertex of a pyramid that is not on the base",
    volume_surface_area,
    [4,5,6,7,8]).

tier(ref(concept, apex), 1,
     [n103_ch4],
     "N103 Activity 4.7.").

geom_concept(volume_of_prism_formula,
    "Volume of a prism = (area of base) * height",
    volume_surface_area,
    [5,6,7,8]).

tier(ref(concept, volume_of_prism_formula), 1,
     [n103_ch4, ccss_6g2],
     "N103 Activity 4.5 derives this from stacked geoboard solids — the unit-cube count for stacked layers.").

volume_surface_area_material_claim(prism_volume_base_times_height,
    volume_of_prism_formula,
    "prism has base of area B and height h",
    "the volume is B * h cubic units",
    entitled).

geom_concept(volume_of_pyramid_formula,
    "Volume of a pyramid = (1/3) * (area of base) * height",
    volume_surface_area,
    [6,7,8]).

tier(ref(concept, volume_of_pyramid_formula), 1,
     [n103_ch4, ccss_8g9],
     "N103 Activity 4.12 has students physically assemble three pyramids into a cube. The 1/3 is grounded, not memorized.").

volume_surface_area_material_claim(pyramid_volume_one_third_base_height,
    volume_of_pyramid_formula,
    "pyramid has base of area B and height h",
    "the volume is (1/3) * B * h cubic units",
    entitled).

geom_concept(volume_of_sphere_formula,
    "Volume of a sphere = (4/3) * pi * r^3",
    volume_surface_area,
    [7,8]).

tier(ref(concept, volume_of_sphere_formula), 1,
     [n103_ch4, ccss_8g9],
     "N103 Activity 4.11 cites the formula.").

geom_concept(surface_area_of_sphere,
    "Surface area of a sphere = 4 * pi * r^2 — exactly four times the area of a circle with the same radius",
    volume_surface_area,
    [7,8]).

tier(ref(concept, surface_area_of_sphere), 1,
     [n103_ch9, ccss_8g9],
     "N103 Activity 9.13. N103 derives experimentally: peel an orange, cover four equal-radius circles with the peel.").

geom_concept(cylinder_n103,
    "A 3D solid with two equal and parallel bases (which may have curved boundaries) connected by a (possibly curved) lateral surface",
    volume_surface_area,
    [4,5,6,7,8]).

tier(ref(concept, cylinder_n103), 1,
     [n103_ch9, ccss_8g9],
     "N103 Activity 9.12: 'Cylinders are shapes that are similar to prisms. However, the bases do not need to be polygons.'").

geom_concept(cone_n103,
    "A 3D solid with a base (which may have curved boundaries) and an apex, where every other point on the surface lies on a segment from the apex to a point on the boundary of the base",
    volume_surface_area,
    [5,6,7,8]).

tier(ref(concept, cone_n103), 1,
     [n103_ch9, ccss_8g9],
     "N103 Activity 9.12.").

geom_concept(volume_of_cylinder,
    "Volume of a cylinder = (area of base) * height — same formula as a prism",
    volume_surface_area,
    [6,7,8]).

tier(ref(concept, volume_of_cylinder), 1,
     [n103_ch9, ccss_8g9],
     "N103 Activity 9.12.").

geom_concept(volume_of_cone,
    "Volume of a cone = (1/3) * (area of base) * height — same formula as a pyramid",
    volume_surface_area,
    [6,7,8]).

tier(ref(concept, volume_of_cone), 1,
     [n103_ch9, ccss_8g9],
     "N103 Activity 9.12.").

geom_concept(antiprism,
    "A polyhedron with two parallel congruent bases connected by triangular lateral faces (versus parallelogram lateral faces of a prism)",
    volume_surface_area,
    [6,7,8]).

tier(ref(concept, antiprism), 3,
     [n103_ch4],
     "N103 Activity 4.9. Less-common solid; N103 uses it to extend pattern-recognition exercises.").

geom_concept(dipyramid,
    "A polyhedron formed by joining two pyramids base-to-base",
    volume_surface_area,
    [6,7,8]).

tier(ref(concept, dipyramid), 3,
     [n103_ch4],
     "N103 Activity 4.9.").

geom_concept(deltahedron,
    "A polyhedron all of whose faces are equilateral triangles",
    volume_surface_area,
    [6,7,8]).

tier(ref(concept, deltahedron), 3,
     [n103_ch4],
     "N103 Activity 4.20-4.21. Surprising fact: there are exactly 8 convex deltahedra.").

geom_concept(stellated_polyhedron,
    "A polyhedron formed by attaching a pyramid to each face of an existing polyhedron",
    volume_surface_area,
    [6,7,8]).

tier(ref(concept, stellated_polyhedron), 3,
     [n103_ch4],
     "N103 Activity 4.20. N103-specific framing tied to its unit-origami project.").

geom_concept(platonic_solids,
    "The five regular polyhedra: tetrahedron, cube, octahedron, dodecahedron, icosahedron — all faces regular polygons, same number of faces meeting at each vertex",
    volume_surface_area,
    [5,6,7,8]).

tier(ref(concept, platonic_solids), 1,
     [n103_ch4],
     "N103 Activity 4.1, 4.9. Standard.").

geom_concept(volume_scales_cubically,
    "When linear dimensions scale by k, volume scales by k cubed",
    volume_surface_area,
    [7,8]).

tier(ref(concept, volume_scales_cubically), 1,
     [n103_ch7],
     "N103 Activity 7.14: 'volume factor is the cube of the scale factor.'").

volume_surface_area_material_claim(cubic_volume_scaling,
    volume_scales_cubically,
    "linear dimensions of solid S scale by factor k",
    "the volume of S scales by k^3",
    entitled).

geom_concept(length_area_volume_dimension_distinction,
    "Physical quantities decompose as 1D (length: fencing, distance), 2D (area: paint, sod, fertilizer, living space), or 3D (volume: water, weight, popcorn)",
    volume_surface_area,
    [4,5,6,7,8]).

tier(ref(concept, length_area_volume_dimension_distinction), 1,
     [n103_ch7],
     "N103 Chapter 7 'How Do I Know if I Understand?': N103 names this as a Big Idea — recognizing whether a physical quantity is 1D, 2D, or 3D is essential for setting up applied problems.").

volume_surface_area_material_claim(dimension_surface_coverage_area,
    length_area_volume_dimension_distinction,
    "the application is about covering a surface (paint, sod, fertilizer)",
    "the relevant quantity is area (2D)",
    entitled).

volume_surface_area_material_claim(dimension_space_filling_volume,
    length_area_volume_dimension_distinction,
    "the application is about filling a space (water, popcorn, sand) or weight",
    "the relevant quantity is volume (3D)",
    entitled).

volume_surface_area_material_claim(dimension_boundary_length,
    length_area_volume_dimension_distinction,
    "the application is about a distance, dimension, or boundary (fencing, string)",
    "the relevant quantity is length (1D)",
    entitled).

geom_misconception(
    pyramid_volume_no_third,
    volume_of_pyramid_formula,
    "Pyramid volume computed as base * height (without the 1/3 factor)",
    [ "the volume of the pyramid is base times height",
      "I used B times h for the pyramid",
      "pyramids work like prisms" ],
    "Pyramid volume is (1/3) * (area of base) * height. The 1/3 comes from the fact that three congruent pyramids can be assembled into a cube — N103 has students do this physically. Without the 1/3, you have computed the volume of the *enclosing* prism, not the pyramid.",
    [n103_ch4]).

tier(ref(misconception, pyramid_volume_no_third), 1,
     [n103_ch4],
     "Implied by N103 Activity 4.12 design — the 1/3 is the moment students grapple with.").

% =====================================================================
% Research-corpus harvest (misconception_harvester) — appended below
% =====================================================================

:- multifile triangulation/2.
:- discontiguous triangulation/2.

% --- additional concept anchors ---

geom_concept(volume_as_filling_3d_space,
    "Volume is the count of unit cubes that fit inside a 3D region",
    volume_surface_area,
    [4,5,6,7,8]).

geom_concept(base_is_geometric_property_not_orientation,
    "The base of a solid is determined by its shape and structure, not by which face touches the ground",
    volume_surface_area,
    [5,6,7,8]).

% --- corpus_39524 / 38965 / 40603 / 40604 (Stacey/Battista): hidden cubes / counting visible faces
geom_misconception(
    volume_by_counting_visible_faces,
    volume_as_filling_3d_space,
    "Volume estimated by counting only visible faces or surface squares",
    [ "I counted the squares on the outside",
      "the volume is six faces times the face count",
      "I counted what I could see" ],
    "Volume requires counting unit cubes inside the solid, including hidden interior cubes — not just faces. For a 2x2x2 cube there are 8 cubes inside, not 24 visible face-squares. Build a small layered structure and count each layer's cubes, then sum.",
    [corpus_39524, corpus_38965, corpus_40603, corpus_40604]).

tier(ref(misconception, volume_by_counting_visible_faces), 2,
     [corpus_39524, corpus_38965, corpus_40603, corpus_40604],
     "research corpus — multi-source on the same surface-vs-interior conflation").

triangulation(ref(misconception, volume_by_counting_visible_faces),
    [ source(stacey_helme_2001, agrees),
      source(battista_2004, agrees) ]).

% --- corpus_38991 (Baturo & Nason): volume confused with area or edges
geom_misconception(
    volume_confused_with_area_or_edges,
    volume_as_filling_3d_space,
    "Volume identified as the empty space inside or as the edges of the solid (conflated with area or perimeter)",
    [ "the volume is the empty space inside",
      "the volume is the edges",
      "the area of the cube is its volume" ],
    "Volume is a 3D quantity (cubic units) measuring how much 3D space the solid occupies. Surface area is 2D (square units) measuring the total area of the solid's outside; edge length is 1D (linear units). Always check which dimension your number lives in.",
    [corpus_38991]).

tier(ref(misconception, volume_confused_with_area_or_edges), 3,
     [corpus_38991], "single-source corpus row 38991 (Baturo & Nason)").

% --- corpus_39662 (Zevenbergen): linear conversion for volume
geom_misconception(
    volume_conversion_with_linear_factor,
    volume_scales_cubically,
    "Volume converted between units using a linear factor (e.g., divide by 100 instead of 1,000,000)",
    [ "I divided by 100 to convert from cm³ to m³",
      "1 m = 100 cm so 1 m³ = 100 cm³",
      "I used the same conversion as for length" ],
    "Volume conversion cubes the linear factor: 1 m = 100 cm so 1 m³ = (100 cm)³ = 1,000,000 cm³. Cubing is necessary because the unit itself is three-dimensional. Show a unit cube and pack it with smaller cubes if helpful.",
    [corpus_39662]).

tier(ref(misconception, volume_conversion_with_linear_factor), 3,
     [corpus_39662], "single-source corpus row 39662").

% --- corpus_39923 / 39924 / 39925 / 39926 / 39927 (Horzum & Ertekin): base concept
geom_misconception(
    base_as_bottom_of_solid,
    base_is_geometric_property_not_orientation,
    "Base of a solid identified as whatever face is touching the ground",
    [ "the base is what's at the bottom",
      "rotate the prism and the base changes",
      "the base is the side resting on the table" ],
    "The base of a prism, pyramid, cylinder, or cone is determined by its geometric structure: for a prism, the two congruent parallel faces; for a pyramid, the face opposite the apex. Reorienting the solid doesn't change which face counts as the base. The everyday meaning of 'base' (bottom) is misleading here.",
    [corpus_39923, corpus_39924, corpus_39925, corpus_39926, corpus_39927]).

tier(ref(misconception, base_as_bottom_of_solid), 2,
     [corpus_39923, corpus_39924, corpus_39925, corpus_39926, corpus_39927],
     "research corpus — five rows from Horzum & Ertekin 2018 on base-concept variations").

triangulation(ref(misconception, base_as_bottom_of_solid),
    [ source(horzum_ertekin_2018, agrees) ]).

% --- corpus_40011 (Jankvist & Niss): volume scaled with linear factor
geom_misconception(
    volume_scaled_linearly,
    volume_scales_cubically,
    "Volume assumed to scale linearly with one of its dimensions",
    [ "if the side is twice as big, the weight is twice as big",
      "I just used the dimension factor",
      "doubling the edge doubles the volume" ],
    "Volume scales as the cube of the linear factor — doubling the edge of a cube increases volume by 8x, not 2x. Build a 2x2x2 cube out of 1x1x1 cubes and count: 8 unit cubes vs the original 1.",
    [corpus_40011]).

tier(ref(misconception, volume_scaled_linearly), 3,
     [corpus_40011], "single-source corpus row 40011").

% --- corpus_38052 (Kittel et al.): lateral vs total surface area
geom_misconception(
    lateral_vs_total_surface_confusion,
    surface_area_of_sphere,
    "Lateral surface area conflated with total surface area",
    [ "the surface area is just the side",
      "I forgot the top and bottom",
      "lateral and total are the same" ],
    "Lateral surface area is the side surface only (e.g., the curved face of a cylinder, excluding the two circular ends). Total surface area adds the area of the bases. For a closed cylinder with radius r and height h: lateral = 2πrh; total = 2πrh + 2πr². Decide which is required by the problem context (e.g., labeling a can vs. wrapping it entirely).",
    [corpus_38052]).

tier(ref(misconception, lateral_vs_total_surface_confusion), 3,
     [corpus_38052], "single-source corpus row 38052").

% --- corpus_37566 / 38634: 2D area applied to 1D or 3D contexts
geom_misconception(
    dimension_mismatch_application,
    length_area_volume_dimension_distinction,
    "Two-dimensional area concept applied to one-dimensional or three-dimensional real-world tasks",
    [ "the area of the board is its length",
      "the area is how much liquid fits",
      "use area for thickness" ],
    "Match the dimension to the question: distance/length is 1D; coverage of a flat region is 2D (area); filling a solid is 3D (volume). 'How much paint' for a wall is area; 'how much water' is volume; 'how long is the board' is length. Use unit dimensionality as a check.",
    [corpus_37566, corpus_38634]).

tier(ref(misconception, dimension_mismatch_application), 3,
     [corpus_37566, corpus_38634], "two-source — Pesek & Kirshner; Roth et al.").

% --- material inferences from harvest ---

volume_surface_area_material_claim(visible_faces_not_volume,
    volume_as_filling_3d_space,
    "I have counted only the visible faces or external squares of a solid",
    "I have measured the volume of the solid",
    incompatible).

volume_surface_area_material_claim(volume_scaling_rejects_linear_or_quadratic,
    volume_scales_cubically,
    "linear dimension is multiplied by k",
    "the volume is multiplied by k or k squared",
    incompatible).

volume_surface_area_material_claim(base_orientation_rejection,
    base_is_geometric_property_not_orientation,
    "the solid is reoriented so that a different face touches the ground",
    "the base of the solid changes",
    incompatible).
