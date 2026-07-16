:- module(misconceptions_geometric_batch_1, []).
% Geometric misconceptions — research corpus batch 1/2.
% Uses entails_via_incompatibility/2 from formalization/axioms_geometry.pl
% (loaded via arche-trace/load.pl by the test harness).
%
% Registration convention:
%   test_harness:entail_misconception(Source, Description, Shape, Target, Claim).
% Claim: holds (student says Shape is-a Target) | fails (student says it's not)
%
% If the error is measurement-flavored (about area/perimeter/angle), it can
% be moved into misconceptions_measurement_batch_N.pl instead as arith_misconception.

:- multifile test_harness:entail_misconception/5.
:- discontiguous test_harness:entail_misconception/5.
:- dynamic test_harness:entail_misconception/5.

% ---- Encodings appended by agent for geometric batch 1 ----

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
