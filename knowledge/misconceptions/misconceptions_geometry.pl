/** <module> Geometry misconception table
 *
 * This table holds literature-attested geometry entailment claims. Rows use
 * test_harness:entail_misconception/5 with the schema
 * entail_misconception(Source, Description, Shape, Target, Claim).
 *
 * Rows retain source order: existing non-batch rows first, followed by batch
 * rows in ascending batch number. Provenance stays with each row; git history
 * is the archive.
 */
:- module(misconceptions_geometry, []).

:- multifile test_harness:entail_misconception/5.
:- discontiguous test_harness:entail_misconception/5.
:- dynamic test_harness:entail_misconception/5.

% === row 37622: 3D coordinate axis interpretation ===
% Not a shape-taxonomy claim (axes on a coordinate plane).
test_harness:entail_misconception(db_row(37622), too_vague, none, none, holds).

% === row 37651: tessellation repeating tile ===
% About tiling, not shape subclass relations.
test_harness:entail_misconception(db_row(37651), too_vague, none, none, holds).

% === row 37724: empirical evidence as proof ===
% About proof epistemology, not shape taxonomy.
test_harness:entail_misconception(db_row(37724), too_vague, none, none, holds).

% === row 37730: circle through three points ===
% Analytic geometry setup error, not shape entailment.
test_harness:entail_misconception(db_row(37730), too_vague, none, none, holds).

% SKIP row 37750: measurement-flavored ("conceptual knowledge of pi / area formula")
% Would belong in misconceptions_measurement_batch_N — not encoded here.

% === row 37755: right triangle properties ===
% Triangles outside square/rectangle/rhombus/parallelogram/trapezoid/kite/quadrilateral vocabulary.
test_harness:entail_misconception(db_row(37755), too_vague, none, none, holds).

% === row 37757: similarity/congruence class inclusion ===
% Triangles + congruence, not in quadrilateral taxonomy.
test_harness:entail_misconception(db_row(37757), too_vague, none, none, holds).

% SKIP row 37875: measurement-flavored ("triangle angle sum depends on size")
% Would belong in misconceptions_measurement_batch_N — not encoded here.

% === row 37889: triangle inequality proof ===
% Triangle + proof reasoning, outside vocabulary.
test_harness:entail_misconception(db_row(37889), too_vague, none, none, holds).

% === row 37955: equipartitioning criteria ===
% Partitioning wholes, not shape taxonomy.
test_harness:entail_misconception(db_row(37955), too_vague, none, none, holds).

% === row 37970: congruence vs equal area ===
% Partitioning/congruence reasoning, not taxonomy.
test_harness:entail_misconception(db_row(37970), too_vague, none, none, holds).

% === row 38000: circle sector orientation ===
% Circles + orientation, outside quadrilateral vocabulary.
test_harness:entail_misconception(db_row(38000), too_vague, none, none, holds).

% === row 38040: partitional concept of parallelogram excludes rectangle ===
% Student claim: rectangle is NOT a parallelogram (parallelogram concept image excludes rectangles).
% Axiom result: rectangle entails parallelogram — student underclaims.
% SCHEMA: Container — shapes-within-shapes taxonomy
% CONNECTS TO: s(comp_nec(unlicensed(rect_not_parallelogram)))
test_harness:entail_misconception(db_row(38040), rect_not_parallelogram, rectangle, parallelogram, fails).

% === row 38067: prototypical triangle definition ===
% Triangles outside quadrilateral vocabulary.
test_harness:entail_misconception(db_row(38067), too_vague, none, none, holds).

% === row 38170: grid diagonal formula ===
% Number-theoretic edge case, not shape taxonomy.
test_harness:entail_misconception(db_row(38170), too_vague, none, none, holds).

% === row 38196: parallel lines ontology ===
% Not a shape taxonomy claim.
test_harness:entail_misconception(db_row(38196), too_vague, none, none, holds).

% === row 38216: turtle intrinsic measurement ===
% Measurement vocabulary issue, no shape claim.
test_harness:entail_misconception(db_row(38216), too_vague, none, none, holds).

% === row 38239: single-sided angle conception ===
% Angles, not shape taxonomy.
test_harness:entail_misconception(db_row(38239), too_vague, none, none, holds).

% === row 38290: unit circle projection ===
% Trigonometry, not shape taxonomy.
test_harness:entail_misconception(db_row(38290), too_vague, none, none, holds).

% === row 38326: parallelogram via slanted rectangle procedure ===
% Reasoning about Logo procedure, not a clean shape-inclusion claim.
test_harness:entail_misconception(db_row(38326), too_vague, none, none, holds).

% === row 38330: exterior vs interior angles ===
% Angle reasoning, not shape taxonomy.
test_harness:entail_misconception(db_row(38330), too_vague, none, none, holds).

% === row 38342: steepness increases uphill ===
% Slope reasoning, not shape taxonomy.
test_harness:entail_misconception(db_row(38342), too_vague, none, none, holds).

% === row 38387: vector-endpoint static relation ===
% Vectors/transformations, outside vocabulary.
test_harness:entail_misconception(db_row(38387), too_vague, none, none, holds).

% === row 38389: zero vector ===
% Vectors/transformations, outside vocabulary.
test_harness:entail_misconception(db_row(38389), too_vague, none, none, holds).

% === row 38447: parallelogram is a type of rectangle ===
% Student claim: parallelogram entails rectangle ("they are both rectangles").
% Axiom result: parallelogram does NOT entail rectangle — student overclaims.
% SCHEMA: Container — shapes-within-shapes taxonomy
% CONNECTS TO: s(comp_nec(unlicensed(parallelogram_is_rectangle)))
test_harness:entail_misconception(db_row(38447), parallelogram_is_rectangle, parallelogram, rectangle, holds).

% === row 38712: small infinity / contraction ===
% Infinity concept, not shape taxonomy.
test_harness:entail_misconception(db_row(38712), too_vague, none, none, holds).

% SKIP row 38723: measurement-flavored ("area depends on orientation")
% Would belong in misconceptions_measurement_batch_N — not encoded here.

% === row 38802: phenomenological circle definition ===
% Circles outside quadrilateral vocabulary.
test_harness:entail_misconception(db_row(38802), too_vague, none, none, holds).

% === row 38804: circle ontology via templates ===
% Circles + ontology, outside vocabulary.
test_harness:entail_misconception(db_row(38804), too_vague, none, none, holds).

% === row 38891: triangle orientation refusal ===
% Triangles outside quadrilateral vocabulary.
test_harness:entail_misconception(db_row(38891), too_vague, none, none, holds).

% === row 38893: altitude vs side perception ===
% Triangle internal structure, outside vocabulary.
test_harness:entail_misconception(db_row(38893), too_vague, none, none, holds).

% === row 38895: painted cube problem ===
% 3D geometry, outside vocabulary.
test_harness:entail_misconception(db_row(38895), too_vague, none, none, holds).

% === row 38984: disjunction rephrasing ===
% Logical language / triangle types, outside vocabulary.
test_harness:entail_misconception(db_row(38984), too_vague, none, none, holds).

% SKIP row 39006: measurement-flavored ("continuous area variation under deformation")
% Would belong in misconceptions_measurement_batch_N — not encoded here.

% === row 39082: 2D drawings of cubes ===
% 3D representation, outside vocabulary.
test_harness:entail_misconception(db_row(39082), too_vague, none, none, holds).

% === row 39098: parallelogram and trapezoid confusion ===
% Confusion is directional but rows shows student drawing trapezoid when parallelogram asked;
% not a clean subclass claim about whether trapezoid is a parallelogram.
test_harness:entail_misconception(db_row(39098), too_vague, none, none, holds).

% SKIP row 39106: measurement-flavored ("equivalent areas despite different contours")
% Would belong in misconceptions_measurement_batch_N — not encoded here.

% SKIP row 39141: measurement-flavored ("area equivalence requires congruence")
% Would belong in misconceptions_measurement_batch_N — not encoded here.

% SKIP row 39143: measurement-flavored ("area compensation: +1/-1 preserves area")
% Would belong in misconceptions_measurement_batch_N — not encoded here.

% === row 39172: reflection preserves orientation ===
% Transformations, outside vocabulary.
test_harness:entail_misconception(db_row(39172), too_vague, none, none, holds).

% === row 39174: reflection as moving mirror ===
% Transformations, outside vocabulary.
test_harness:entail_misconception(db_row(39174), too_vague, none, none, holds).

% === row 39189: subfigure discrimination ===
% Visual organization, not shape taxonomy.
test_harness:entail_misconception(db_row(39189), too_vague, none, none, holds).

% === row 39270: finite reality for infinite points ===
% Infinity concept, outside vocabulary.
test_harness:entail_misconception(db_row(39270), too_vague, none, none, holds).

% === row 39303: segment length vs cardinality ===
% Infinite sets, outside vocabulary.
test_harness:entail_misconception(db_row(39303), too_vague, none, none, holds).

% === row 39401: rotation as movement ===
% Angles/rotations, outside vocabulary.
test_harness:entail_misconception(db_row(39401), too_vague, none, none, holds).

% === row 39425: segment vs length ===
% Distance concept, outside vocabulary.
test_harness:entail_misconception(db_row(39425), too_vague, none, none, holds).

% === row 39542: abstract spatial vocabulary ===
% Not shape taxonomy.
test_harness:entail_misconception(db_row(39542), too_vague, none, none, holds).

% SKIP row 39585: measurement-flavored ("linear scaling scales area linearly")
% Would belong in misconceptions_measurement_batch_N — not encoded here.

% === row 39627: oblique line symmetry sketching ===
% Symmetry/reflection, outside vocabulary.
test_harness:entail_misconception(db_row(39627), too_vague, none, none, holds).

% === row 39760: visual vs axiomatic parallelism ===
% Axiomatic geometry, outside vocabulary.
test_harness:entail_misconception(db_row(39760), too_vague, none, none, holds).

% === row 39797: diagonals of rectangle as symmetry lines ===
% Symmetry claim about rectangle diagonals; not a subclass-taxonomy claim.
test_harness:entail_misconception(db_row(39797), too_vague, none, none, holds).

% === row 39829: spherical lines as arcs ===
% Spherical geometry, outside vocabulary.
test_harness:entail_misconception(db_row(39829), too_vague, none, none, holds).

% === row 39873: prototypical triangle concept ===
% Triangles outside quadrilateral vocabulary.
test_harness:entail_misconception(db_row(39873), too_vague, none, none, holds).

% === row 39875: every quadrilateral is a parallelogram ===
% Student claim: quadrilateral entails parallelogram ("Isn't every quadrilateral a parallelogram?").
% Axiom result: quadrilateral does NOT entail parallelogram — student overclaims.
% SCHEMA: Container — shapes-within-shapes taxonomy
% CONNECTS TO: s(comp_nec(unlicensed(quadrilateral_is_parallelogram)))
test_harness:entail_misconception(db_row(39875), quadrilateral_is_parallelogram, quadrilateral, parallelogram, holds).

% SKIP row 39920: measurement-flavored ("circle wedges form exact parallelogram")
% Would belong in misconceptions_measurement_batch_N — not encoded here.

% === row 39923: position-dependent base of solid ===
% 3D solid base naming, outside vocabulary.
test_harness:entail_misconception(db_row(39923), too_vague, none, none, holds).

% === row 39925: edge-dependent 3D base ===
% 3D solid base, outside vocabulary.
test_harness:entail_misconception(db_row(39925), too_vague, none, none, holds).

% === row 39927: naming-dependent base ===
% 3D solid base naming, outside vocabulary.
test_harness:entail_misconception(db_row(39927), too_vague, none, none, holds).

% === row 39966: proof invalidated by configuration change ===
% Proof + implicit suppositions, not shape taxonomy.
test_harness:entail_misconception(db_row(39966), too_vague, none, none, holds).

% SKIP row 40011: measurement-flavored ("volume scales linearly with edge")
% Would belong in misconceptions_measurement_batch_N — not encoded here.

% === row 40204: conic sections key-word jumping ===
% Conic sections, outside vocabulary.
test_harness:entail_misconception(db_row(40204), too_vague, none, none, holds).

% === row 40207: sectors called squares ===
% Circle sector terminology error, outside vocabulary.
test_harness:entail_misconception(db_row(40207), too_vague, none, none, holds).

% === row 40228: quadrilaterals limited to squares and rectangles ===
% Student claim: four-sided figures with non-right angles (e.g., parallelograms) are
% not quadrilaterals. Encoded as parallelogram does NOT entail quadrilateral.
% Axiom result: parallelogram DOES entail quadrilateral — student underclaims.
% SCHEMA: Container — shapes-within-shapes taxonomy
% CONNECTS TO: s(comp_nec(unlicensed(parallelogram_not_quadrilateral)))
test_harness:entail_misconception(db_row(40228), parallelogram_not_quadrilateral, parallelogram, quadrilateral, fails).

% SKIP row 40280: measurement-flavored ("rectangle area larger than parallelogram after transform")
% Would belong in misconceptions_measurement_batch_N — not encoded here.

% === row 40350: angle as width between sides ===
% Angle definition, outside vocabulary.
test_harness:entail_misconception(db_row(40350), too_vague, none, none, holds).

% === row 40352: square is not a rhombus ===
% Student claim: square does NOT entail rhombus ("a square is not a rhombus").
% Axiom result: square DOES entail rhombus — student underclaims.
% SCHEMA: Container — shapes-within-shapes taxonomy
% CONNECTS TO: s(comp_nec(unlicensed(square_not_rhombus)))
test_harness:entail_misconception(db_row(40352), square_not_rhombus, square, rhombus, fails).

% === row 40462: bow-tie equal angles ===
% Circle angle theorem error, outside vocabulary.
test_harness:entail_misconception(db_row(40462), too_vague, none, none, holds).

% === row 40464: tangent-point midpoint as circle center ===
% Circle construction error, outside vocabulary.
test_harness:entail_misconception(db_row(40464), too_vague, none, none, holds).

% === row 40534: uniform grid distance assumption ===
% Grid distance/triangle, outside vocabulary.
test_harness:entail_misconception(db_row(40534), too_vague, none, none, holds).

% === row 40566: diamond not recognized as square ===
% Orientation-based visual recognition rather than an inclusion claim; the
% student accepts the shape's properties but refuses the name based on tilt.
test_harness:entail_misconception(db_row(40566), too_vague, none, none, holds).

% === row 40616: hyperbolic plane via crocheted model ===
% Hyperbolic geometry + model ontology, outside vocabulary.
test_harness:entail_misconception(db_row(40616), too_vague, none, none, holds).

% === row 37650: polygon interior-angle sum ===
% Marta Civil (2002): multiplies 180 by the number of triangles in a polygon
% decomposition. This is not a quadrilateral-taxonomy entailment claim.
test_harness:entail_misconception(db_row(37650), too_vague, none, none, holds).

% === row 37714: vocabulary confusion 'similar' with natural language ===
% Student conflates 'similar' (math) with 'closely resembling but not identical'.
% No taxonomic shape-to-shape claim — too vague for geometric entailment axioms.
test_harness:entail_misconception(db_row(37714), too_vague, none, none, holds).

% === row 37729: overly restrictive/broad circle definitions ===
% Circle is outside the 7-atom quadrilateral-taxonomy vocabulary.
test_harness:entail_misconception(db_row(37729), too_vague, none, none, holds).

% SKIP row 37731: measurement-flavored ("polygon interior sum = 180*n")
% Would belong in misconceptions_measurement_batch_N — not encoded here.
test_harness:entail_misconception(db_row(37731), too_vague, none, none, holds).

% === row 37754: square recognition in nonstandard orientation ===
% Student fails to recognize a square when rotated — recognition issue,
% not a taxonomic inclusion claim about shape classes.
test_harness:entail_misconception(db_row(37754), too_vague, none, none, holds).

% === row 37756: similar triangles / angle scaling ===
% Triangle is outside the 7-atom vocabulary.
test_harness:entail_misconception(db_row(37756), too_vague, none, none, holds).

% === row 37758: geometric proof chaining ===
% About proof structure, not shape taxonomy.
test_harness:entail_misconception(db_row(37758), too_vague, none, none, holds).

% === row 37888: intercepted arcs terminology confusion ===
% Vocabulary error about circle terms; no taxonomic claim.
test_harness:entail_misconception(db_row(37888), too_vague, none, none, holds).

% SKIP row 37897: measurement-flavored ("rectangle area grows iff perimeter grows")
% Would belong in misconceptions_measurement_batch_N — not encoded here.
test_harness:entail_misconception(db_row(37897), too_vague, none, none, holds).

% === row 37956: partitioning circle for odd numbers ===
% Circle not in vocabulary; equipartitioning issue, not taxonomic.
test_harness:entail_misconception(db_row(37956), too_vague, none, none, holds).

% === row 37972: equipartitioning criteria for rectangle ===
% About partition validity, not taxonomic inclusion.
test_harness:entail_misconception(db_row(37972), too_vague, none, none, holds).

% === row 38010: indirect argumentation / figure deformation ===
% Proof-theoretic error, not a taxonomic claim.
test_harness:entail_misconception(db_row(38010), too_vague, none, none, holds).

% SKIP row 38050: measurement-flavored ("doubling radius doubles area")
% Would belong in misconceptions_measurement_batch_N — not encoded here.
test_harness:entail_misconception(db_row(38050), too_vague, none, none, holds).

% SKIP row 38130: measurement-flavored ("larger area => longer perimeter")
% Would belong in misconceptions_measurement_batch_N — not encoded here.
test_harness:entail_misconception(db_row(38130), too_vague, none, none, holds).

% === row 38191: line segment as necklace of beads ===
% Point/line ontology, not shape taxonomy.
test_harness:entail_misconception(db_row(38191), too_vague, none, none, holds).

% === row 38215: turtle geometry representation ===
% Representation mode confusion; no taxonomic claim.
test_harness:entail_misconception(db_row(38215), too_vague, none, none, holds).

% SKIP row 38217: measurement-flavored ("turtle turn angle = 180/n")
% Would belong in misconceptions_measurement_batch_N — not encoded here.
test_harness:entail_misconception(db_row(38217), too_vague, none, none, holds).

% === row 38249: trigonometry requires explicit right angle ===
% About trigonometry applicability, not shape taxonomy.
test_harness:entail_misconception(db_row(38249), too_vague, none, none, holds).

% === row 38292: unit circle trig symmetries ===
% Trigonometric reasoning, not taxonomy.
test_harness:entail_misconception(db_row(38292), too_vague, none, none, holds).

% === row 38329: empirical vs deductive reasoning from diagrams ===
% Epistemological issue about proof, not taxonomic claim.
test_harness:entail_misconception(db_row(38329), too_vague, none, none, holds).

% === row 38341: slope height/length covariation ===
% Quantity coordination on slope; not taxonomic.
test_harness:entail_misconception(db_row(38341), too_vague, none, none, holds).

% === row 38386: vector as reflection line ===
% Transformation type confusion, not shape taxonomy.
test_harness:entail_misconception(db_row(38386), too_vague, none, none, holds).

% === row 38388: translation domain as single object ===
% Domain of transformation; not taxonomic.
test_harness:entail_misconception(db_row(38388), too_vague, none, none, holds).

% === row 38411: steepness vs linear length ===
% Slope measurement confusion; not taxonomic.
test_harness:entail_misconception(db_row(38411), too_vague, none, none, holds).

% === row 38448: rectangles and parallelograms as disjoint classes ===
% Student claim: rectangle does NOT entail parallelogram.
% Axiom result: rectangle => parallelogram (entails).
% SCHEMA: Container — shapes-within-shapes taxonomy
% CONNECTS TO: s(comp_nec(unlicensed(rectangle_not_parallelogram)))
test_harness:entail_misconception(db_row(38448), rectangle_not_parallelogram, rectangle, parallelogram, fails).

% === row 38713: continuous geometric division terminates ===
% About infinity/convergence, not shape taxonomy.
test_harness:entail_misconception(db_row(38713), too_vague, none, none, holds).

% === row 38740: axiomatic hierarchy and deductive proof ===
% Meta-mathematical, not taxonomic.
test_harness:entail_misconception(db_row(38740), too_vague, none, none, holds).

% === row 38803: circle size confusion ===
% Circle not in vocabulary.
test_harness:entail_misconception(db_row(38803), too_vague, none, none, holds).

% === row 38807: parallel lines 'equal length' vs 'equidistant' ===
% Vocabulary confusion on lines, not shape taxonomy.
test_harness:entail_misconception(db_row(38807), too_vague, none, none, holds).

% === row 38892: general triangle confused with specific one ===
% Triangle not in vocabulary; representation/abstraction issue.
test_harness:entail_misconception(db_row(38892), too_vague, none, none, holds).

% === row 38894: Earth/gravity scaling misconceptions ===
% 3D spatial conceptualization, not quadrilateral taxonomy.
test_harness:entail_misconception(db_row(38894), too_vague, none, none, holds).

% === row 38912: tetrahedron called triangle ===
% 2D/3D conflation; neither shape in vocabulary.
test_harness:entail_misconception(db_row(38912), too_vague, none, none, holds).

% SKIP row 38996: measurement-flavored ("area of triangle = b/2 * h mechanically")
% Would belong in misconceptions_measurement_batch_N — not encoded here.
test_harness:entail_misconception(db_row(38996), too_vague, none, none, holds).

% === row 39015: algorithm selection on superficial features ===
% Problem-solving heuristic, not shape taxonomy.
test_harness:entail_misconception(db_row(39015), too_vague, none, none, holds).

% === row 39083: great circles and map distance ===
% Spherical geometry, not quadrilateral taxonomy.
test_harness:entail_misconception(db_row(39083), too_vague, none, none, holds).

% SKIP row 39105: measurement-flavored ("opposite angles sized by arm length")
% Would belong in misconceptions_measurement_batch_N — not encoded here.
test_harness:entail_misconception(db_row(39105), too_vague, none, none, holds).

% === row 39107: rectangles/squares/rhombuses rejected as parallelograms ===
% Student claim: rhombus does NOT entail parallelogram (and similarly for
% rectangle, square). Encoded on the rhombus leg; the rectangle/square
% legs appear separately in rows 38448, 39901, 40229, 40536.
% Axiom result: rhombus => parallelogram (entails).
% SCHEMA: Container — shapes-within-shapes taxonomy
% CONNECTS TO: s(comp_nec(unlicensed(rhombus_not_parallelogram)))
test_harness:entail_misconception(db_row(39107), rhombus_not_parallelogram, rhombus, parallelogram, fails).

% SKIP row 39142: measurement-flavored ("longer sides => greater area")
% Would belong in misconceptions_measurement_batch_N — not encoded here.
test_harness:entail_misconception(db_row(39142), too_vague, none, none, holds).

% === row 39144: visual assumption of perpendicularity ===
% Diagram-reading error, not taxonomic claim.
test_harness:entail_misconception(db_row(39144), too_vague, none, none, holds).

% === row 39173: reflection by linguistic opposites ===
% Transformation error via language, not taxonomic.
test_harness:entail_misconception(db_row(39173), too_vague, none, none, holds).

% === row 39175: over-generalized lines of symmetry ===
% Symmetry concept error, not shape taxonomy.
test_harness:entail_misconception(db_row(39175), too_vague, none, none, holds).

% === row 39260: atomistic view of the real line ===
% Continuity vs discreteness, not taxonomy.
test_harness:entail_misconception(db_row(39260), too_vague, none, none, holds).

% === row 39272: midpoint construction with rope ===
% Construction tool-definition coordination, not taxonomy.
test_harness:entail_misconception(db_row(39272), too_vague, none, none, holds).

% === row 39391: pipe assembly hypotenuse ===
% Right triangles in context; not quadrilateral taxonomy.
test_harness:entail_misconception(db_row(39391), too_vague, none, none, holds).

% === row 39402: slope as single sloping line ===
% Slope conceptualization, not taxonomy.
test_harness:entail_misconception(db_row(39402), too_vague, none, none, holds).

% === row 39508: hexagon equal sides => equal angles ===
% Hexagon not in 7-atom vocabulary.
test_harness:entail_misconception(db_row(39508), too_vague, none, none, holds).

% SKIP row 39579: measurement-flavored ("triangle angle sum by protractor")
% Would belong in misconceptions_measurement_batch_N — not encoded here.
test_harness:entail_misconception(db_row(39579), too_vague, none, none, holds).

% === row 39626: median/diagonal as symmetry axis ===
% Symmetry error, not taxonomic claim.
test_harness:entail_misconception(db_row(39626), too_vague, none, none, holds).

% === row 39628: straight line as symmetry axis of itself ===
% Symmetry concept error, not taxonomic.
test_harness:entail_misconception(db_row(39628), too_vague, none, none, holds).

% SKIP row 39796: measurement-flavored ("ratio of square areas = ratio of sides")
% Would belong in misconceptions_measurement_batch_N — not encoded here.
test_harness:entail_misconception(db_row(39796), too_vague, none, none, holds).

% === row 39828: cylinder/cone prototype images ===
% 3D solids outside 7-atom vocabulary.
test_harness:entail_misconception(db_row(39828), too_vague, none, none, holds).

% === row 39830: spherical geometry axioms ===
% Non-Euclidean geometry, not quadrilateral taxonomy.
test_harness:entail_misconception(db_row(39830), too_vague, none, none, holds).

% === row 39874: square defined with orientation requirement ===
% Definition error includes orientation; no clean taxonomic entailment claim.
test_harness:entail_misconception(db_row(39874), too_vague, none, none, holds).

% === row 39901: square is not a rectangle ===
% Student claim: square does NOT entail rectangle.
% Axiom result: square => rectangle (entails).
% SCHEMA: Container — shapes-within-shapes taxonomy
% CONNECTS TO: s(comp_nec(unlicensed(square_not_rectangle)))
test_harness:entail_misconception(db_row(39901), square_not_rectangle, square, rectangle, fails).

% === row 39921: arcs treated as straight in limiting parallelogram ===
% Calculus-of-sectors argument error, not taxonomy.
test_harness:entail_misconception(db_row(39921), too_vague, none, none, holds).

% === row 39924: figure-dependent base image ===
% Base concept for solids; not quadrilateral taxonomy.
test_harness:entail_misconception(db_row(39924), too_vague, none, none, holds).

% === row 39926: height-dependent base image ===
% Base concept for solids; not quadrilateral taxonomy.
test_harness:entail_misconception(db_row(39926), too_vague, none, none, holds).

% === row 39965: non-overlapping case treated as counterexample ===
% Conjecture/counterexample handling, not taxonomy.
test_harness:entail_misconception(db_row(39965), too_vague, none, none, holds).

% === row 39984: 2D to 3D scaling 'becomes flat' ===
% Dimensional transition, not quadrilateral taxonomy.
test_harness:entail_misconception(db_row(39984), too_vague, none, none, holds).

% === row 40203: conic sections as algebraic manipulations ===
% Representation/register shift, not taxonomy.
test_harness:entail_misconception(db_row(40203), too_vague, none, none, holds).

% === row 40205: inexact circumference definition ===
% Circle definition; circle not in vocabulary.
test_harness:entail_misconception(db_row(40205), too_vague, none, none, holds).

% === row 40210: 'edge' via rounded table edge ===
% Vocabulary/referent mismatch, not taxonomic.
test_harness:entail_misconception(db_row(40210), too_vague, none, none, holds).

% === row 40229: square is a special rectangle (student refuses) ===
% Student claim: square does NOT entail rectangle.
% Axiom result: square => rectangle (entails).
% SCHEMA: Container — shapes-within-shapes taxonomy
% CONNECTS TO: s(comp_nec(unlicensed(square_not_rectangle)))
test_harness:entail_misconception(db_row(40229), square_refuses_rectangle, square, rectangle, fails).

% === row 40296: rhombuses similarity by visual estimation ===
% Similarity judgment error; not taxonomic inclusion.
test_harness:entail_misconception(db_row(40296), too_vague, none, none, holds).

% === row 40351: parallelogram identified as rhombus ===
% Student claim: parallelogram entails rhombus (misidentifies shape).
% Axiom result: parallelogram does NOT entail rhombus.
% SCHEMA: Container — shapes-within-shapes taxonomy
% CONNECTS TO: s(comp_nec(unlicensed(parallelogram_is_rhombus)))
test_harness:entail_misconception(db_row(40351), parallelogram_is_rhombus, parallelogram, rhombus, holds).

% === row 40461: inscribed/central angle configurations ===
% Circle theorem configurations, not quadrilateral taxonomy.
test_harness:entail_misconception(db_row(40461), too_vague, none, none, holds).

% === row 40463: inscribed quadrilateral theorem misapplication ===
% Theorem application error; not a taxonomic inclusion claim.
test_harness:entail_misconception(db_row(40463), too_vague, none, none, holds).

% === row 40528: flip out of plane (rotation vs reflection) ===
% Transformation type confusion, not taxonomy.
test_harness:entail_misconception(db_row(40528), too_vague, none, none, holds).

% === row 40536: squares and rectangles as mutually exclusive ===
% Student claim: square does NOT entail rectangle.
% Axiom result: square => rectangle (entails).
% SCHEMA: Container — shapes-within-shapes taxonomy
% CONNECTS TO: s(comp_nec(unlicensed(square_not_rectangle)))
test_harness:entail_misconception(db_row(40536), square_disjoint_rectangle, square, rectangle, fails).

% === row 40581: monster-barring in tiling ===
% Problem-solving strategy, not taxonomic claim.
test_harness:entail_misconception(db_row(40581), too_vague, none, none, holds).

% === direct solo pass: remaining geometric queue rows outside current taxonomy ===

test_harness:entail_misconception(db_row(37611), too_vague, none, none, holds).
test_harness:entail_misconception(db_row(37612), too_vague, none, none, holds).
test_harness:entail_misconception(db_row(37697), too_vague, none, none, holds).
test_harness:entail_misconception(db_row(37750), too_vague, none, none, holds).
test_harness:entail_misconception(db_row(37949), too_vague, none, none, holds).
test_harness:entail_misconception(db_row(38005), too_vague, none, none, holds).
test_harness:entail_misconception(db_row(38081), too_vague, none, none, holds).
test_harness:entail_misconception(db_row(38159), too_vague, none, none, holds).
test_harness:entail_misconception(db_row(38723), too_vague, none, none, holds).
test_harness:entail_misconception(db_row(38762), too_vague, none, none, holds).
test_harness:entail_misconception(db_row(39006), too_vague, none, none, holds).
test_harness:entail_misconception(db_row(39212), too_vague, none, none, holds).
test_harness:entail_misconception(db_row(39230), too_vague, none, none, holds).
test_harness:entail_misconception(db_row(39264), too_vague, none, none, holds).
test_harness:entail_misconception(db_row(39549), too_vague, none, none, holds).
test_harness:entail_misconception(db_row(39920), too_vague, none, none, holds).
test_harness:entail_misconception(db_row(40176), too_vague, none, none, holds).
test_harness:entail_misconception(db_row(40238), too_vague, none, none, holds).
test_harness:entail_misconception(db_row(40280), too_vague, none, none, holds).
test_harness:entail_misconception(db_row(40505), too_vague, none, none, holds).
test_harness:entail_misconception(db_row(40627), too_vague, none, none, holds).
