:- module(misconceptions_geometric_batch_2, []).
% Geometric misconceptions — research corpus batch 2/2.
% Uses entails_via_incompatibility/2 from formal/formalization/axioms_geometry.pl
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

% ---- Encodings appended by agent for geometric batch 2 ----

% SKIP row 37650: measurement-flavored ("interior angles of hexagon = 6*180 = 1080")
% Would belong in misconceptions_measurement_batch_N — not encoded here.
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
