% knowledge/standards/im/grade_8.pl - Mappings for grade 8 CCSS/Indiana standards
:- multifile standard_anchor/4.
:- discontiguous standard_anchor/4.

%!  im_grade8_lesson_standard_witness(+ConceptId, +Code, -Witness) is semidet.
%
%   Inspectable witness for one IM Grade 8 lesson anchor in the closed-world
%   finite Grade 8 lesson table. These rows do not carry local tier facts, so
%   the witness states the existing query default explicitly.
im_grade8_lesson_standard_witness(ConceptId, Code, Witness) :-
    witness_dict:witness_dict(im_grade8_lesson_standard_anchor, closed_world_finite_im_grade8_lesson_table,
                              _{concept: ConceptId,
                 framework: im_lesson,
                 code: Code,
                 statement: Statement,
                 tier: 3,
                 tier_evidence: default_tier_for_missing_local_tier,
                 concept_boundary: loaded_geometry_concept_record,
                 concept_evidence: ConceptEvidence,
                 boundary: finite_im_grade8_lesson_anchor_table_not_general_curriculum_model,
                 fact: standard_anchor(ConceptId, im_lesson, Code, Statement) }, WitnessDict13),
    im_grade8_lesson_anchor_fact(ConceptId, Code, Statement),
    im_grade8_lesson_concept_evidence(ConceptId, ConceptEvidence),
    Witness = WitnessDict13.

im_grade8_lesson_anchor_fact(ConceptId, Code, Statement) :-
    Clause = standard_anchor(ConceptId, im_lesson, Code, Statement),
    clause(Clause, true, Ref),
    clause_property(Ref, file(File)),
    sub_atom(File, _, _, _, 'knowledge/standards/im/grade_8.pl').

im_grade8_lesson_concept_evidence(ConceptId,
    _{ kind: geometry_concept_record,
       fact: geom_concept(ConceptId, Name, Topic, GradeBands) }) :-
    geom_concept(ConceptId, Name, Topic, GradeBands).

standard_anchor(rigid_motion_properties, im_lesson, "IM-G8-U1-L1", "Moving in the Plane").

standard_anchor(rigid_motion_properties, im_lesson, "IM-G8-U1-L2", "Naming the Moves").

standard_anchor(rigid_motion_properties, im_lesson, "IM-G8-U1-L3", "Grid Moves").

standard_anchor(rigid_motion_properties, im_lesson, "IM-G8-U1-L4", "Making the Moves").

standard_anchor(rigid_motion_properties, im_lesson, "IM-G8-U1-L5", "Coordinate Moves").

standard_anchor(rigid_motion_properties, im_lesson, "IM-G8-U1-L6", "Describing Transformations").

standard_anchor(rigid_motion_properties, im_lesson, "IM-G8-U1-L7", "No Bending or Stretching").

standard_anchor(rigid_motion_properties, im_lesson, "IM-G8-U1-L8", "Rotation Patterns").

standard_anchor(rigid_motion_properties, im_lesson, "IM-G8-U1-L9", "Moves in Parallel").

standard_anchor(rigid_motion_properties, im_lesson, "IM-G8-U1-L10", "Composing Figures").

standard_anchor(rigid_motion_properties, im_lesson, "IM-G8-U1-L11", "What Is the Same?").

standard_anchor(rigid_motion_properties, im_lesson, "IM-G8-U1-L12", "Congruent Polygons").

standard_anchor(rigid_motion_properties, im_lesson, "IM-G8-U1-L13", "Congruence").

standard_anchor(rigid_motion_properties, im_lesson, "IM-G8-U1-L14", "Alternate Interior Angles").

standard_anchor(rigid_motion_properties, im_lesson, "IM-G8-U1-L15", "Adding the Angles in a Triangle").

standard_anchor(rigid_motion_properties, im_lesson, "IM-G8-U1-L16", "Parallel Lines and the Angles in a Triangle").

standard_anchor(rigid_motion_properties, im_lesson, "IM-G8-U1-L17", "Rotate and Tessellate").

standard_anchor(similarity_via_transformations, im_lesson, "IM-G8-U2-L1", "Projecting and Scaling").

standard_anchor(similarity_via_transformations, im_lesson, "IM-G8-U2-L2", "Circular Grid").

standard_anchor(similarity_via_transformations, im_lesson, "IM-G8-U2-L3", "Dilations with No Grid").

standard_anchor(similarity_via_transformations, im_lesson, "IM-G8-U2-L4", "Dilations on a Square Grid").

standard_anchor(similarity_via_transformations, im_lesson, "IM-G8-U2-L5", "More Dilations").

standard_anchor(similarity_via_transformations, im_lesson, "IM-G8-U2-L6", "Similarity").

standard_anchor(similarity_via_transformations, im_lesson, "IM-G8-U2-L7", "Similar Polygons").

standard_anchor(similarity_via_transformations, im_lesson, "IM-G8-U2-L8", "Similar Triangles").

standard_anchor(similarity_via_transformations, im_lesson, "IM-G8-U2-L9", "Side Length Quotients in Similar Triangles").

standard_anchor(similarity_via_transformations, im_lesson, "IM-G8-U2-L10", "Meet Slope").

standard_anchor(similarity_via_transformations, im_lesson, "IM-G8-U2-L11", "Writing Equations for Lines").

standard_anchor(similarity_via_transformations, im_lesson, "IM-G8-U2-L12", "Using Equations for Lines").

standard_anchor(similarity_via_transformations, im_lesson, "IM-G8-U2-L13", "The Shadow Knows").

standard_anchor(im_grade8_unit3, im_lesson, "IM-G8-U3-L1", "Understanding Proportional Relationships").

standard_anchor(im_grade8_unit3, im_lesson, "IM-G8-U3-L2", "Graphs of Proportional Relationships").

standard_anchor(im_grade8_unit3, im_lesson, "IM-G8-U3-L3", "Representing Proportional Relationships").

standard_anchor(im_grade8_unit3, im_lesson, "IM-G8-U3-L4", "Comparing Proportional Relationships").

standard_anchor(im_grade8_unit3, im_lesson, "IM-G8-U3-L5", "Introduction to Linear Relationships").

standard_anchor(im_grade8_unit3, im_lesson, "IM-G8-U3-L6", "More Linear Relationships").

standard_anchor(im_grade8_unit3, im_lesson, "IM-G8-U3-L7", "Representations of Linear Relationships").

standard_anchor(im_grade8_unit3, im_lesson, "IM-G8-U3-L8", "Translating to").

standard_anchor(im_grade8_unit3, im_lesson, "IM-G8-U3-L9", "Slopes Don't Have to Be Positive").

standard_anchor(im_grade8_unit3, im_lesson, "IM-G8-U3-L10", "Calculating Slope").

standard_anchor(im_grade8_unit3, im_lesson, "IM-G8-U3-L11", "Line Designs").

standard_anchor(im_grade8_unit3, im_lesson, "IM-G8-U3-L12", "Equations of All Kinds of Lines").

standard_anchor(im_grade8_unit3, im_lesson, "IM-G8-U3-L13", "Solutions to Linear Equations").

standard_anchor(im_grade8_unit3, im_lesson, "IM-G8-U3-L14", "More Solutions to Linear Equations").

standard_anchor(im_grade8_unit3, im_lesson, "IM-G8-U3-L15", "Using Linear Relations to Solve Problems").

standard_anchor(im_grade8_unit4, im_lesson, "IM-G8-U4-L1", "Writing Equivalent Equations").

standard_anchor(im_grade8_unit4, im_lesson, "IM-G8-U4-L2", "Keeping the Equation Balanced").

standard_anchor(im_grade8_unit4, im_lesson, "IM-G8-U4-L3", "Balanced Moves").

standard_anchor(im_grade8_unit4, im_lesson, "IM-G8-U4-L4", "More Balanced Moves").

standard_anchor(im_grade8_unit4, im_lesson, "IM-G8-U4-L5", "Solving Any Linear Equation").

standard_anchor(im_grade8_unit4, im_lesson, "IM-G8-U4-L6", "Strategic Solving").

standard_anchor(im_grade8_unit4, im_lesson, "IM-G8-U4-L7", "All, Some, or No Solutions").

standard_anchor(im_grade8_unit4, im_lesson, "IM-G8-U4-L8", "How Many Solutions?").

standard_anchor(im_grade8_unit4, im_lesson, "IM-G8-U4-L9", "When Are They the Same?").

standard_anchor(im_grade8_unit4, im_lesson, "IM-G8-U4-L10", "On or Off the Line?").

standard_anchor(im_grade8_unit4, im_lesson, "IM-G8-U4-L11", "On Both of the Lines").

standard_anchor(im_grade8_unit4, im_lesson, "IM-G8-U4-L12", "Systems of Equations").

standard_anchor(im_grade8_unit4, im_lesson, "IM-G8-U4-L13", "Solving Systems of Equations").

standard_anchor(im_grade8_unit4, im_lesson, "IM-G8-U4-L14", "Solving More Systems").

standard_anchor(im_grade8_unit4, im_lesson, "IM-G8-U4-L15", "Writing Systems of Equations").

standard_anchor(im_grade8_unit4, im_lesson, "IM-G8-U4-L16", "Solving Problems with Systems of Equations").

standard_anchor(volume_cone_cylinder_sphere, im_lesson, "IM-G8-U5-L1", "Inputs and Outputs").

standard_anchor(volume_cone_cylinder_sphere, im_lesson, "IM-G8-U5-L2", "Introduction to Functions").

standard_anchor(volume_cone_cylinder_sphere, im_lesson, "IM-G8-U5-L3", "Equations for Functions").

standard_anchor(volume_cone_cylinder_sphere, im_lesson, "IM-G8-U5-L4", "Tables, Equations, and Graphs of Functions").

standard_anchor(volume_cone_cylinder_sphere, im_lesson, "IM-G8-U5-L5", "More Graphs of Functions").

standard_anchor(volume_cone_cylinder_sphere, im_lesson, "IM-G8-U5-L6", "Even More Graphs of Functions").

standard_anchor(volume_cone_cylinder_sphere, im_lesson, "IM-G8-U5-L7", "Connecting Representations of Functions").

standard_anchor(volume_cone_cylinder_sphere, im_lesson, "IM-G8-U5-L8", "Linear Functions").

standard_anchor(volume_cone_cylinder_sphere, im_lesson, "IM-G8-U5-L9", "Linear Models").

standard_anchor(volume_cone_cylinder_sphere, im_lesson, "IM-G8-U5-L10", "Piecewise Linear Functions").

standard_anchor(volume_cone_cylinder_sphere, im_lesson, "IM-G8-U5-L11", "Filling Containers").

standard_anchor(volume_cone_cylinder_sphere, im_lesson, "IM-G8-U5-L12", "How Much Will Fit?").

standard_anchor(volume_cone_cylinder_sphere, im_lesson, "IM-G8-U5-L13", "The Volume of a Cylinder").

standard_anchor(volume_cone_cylinder_sphere, im_lesson, "IM-G8-U5-L14", "Finding Cylinder Dimensions").

standard_anchor(volume_cone_cylinder_sphere, im_lesson, "IM-G8-U5-L15", "The Volume of a Cone").

standard_anchor(volume_cone_cylinder_sphere, im_lesson, "IM-G8-U5-L16", "Finding Cone Dimensions").

standard_anchor(volume_cone_cylinder_sphere, im_lesson, "IM-G8-U5-L17", "Scaling One Dimension").

standard_anchor(volume_cone_cylinder_sphere, im_lesson, "IM-G8-U5-L18", "Scaling Two Dimensions").

standard_anchor(volume_cone_cylinder_sphere, im_lesson, "IM-G8-U5-L19", "Estimating a Hemisphere").

standard_anchor(volume_cone_cylinder_sphere, im_lesson, "IM-G8-U5-L20", "The Volume of a Sphere").

standard_anchor(volume_cone_cylinder_sphere, im_lesson, "IM-G8-U5-L21", "Cylinders, Cones, and Spheres").

standard_anchor(volume_cone_cylinder_sphere, im_lesson, "IM-G8-U5-L22", "Volume as a Function of . . .").

standard_anchor(im_grade8_unit6, im_lesson, "IM-G8-U6-L1", "Organizing Data").

standard_anchor(im_grade8_unit6, im_lesson, "IM-G8-U6-L2", "Plotting Data").

standard_anchor(im_grade8_unit6, im_lesson, "IM-G8-U6-L3", "What a Point in a Scatter Plot Means").

standard_anchor(im_grade8_unit6, im_lesson, "IM-G8-U6-L4", "Fitting a Line to Data").

standard_anchor(im_grade8_unit6, im_lesson, "IM-G8-U6-L5", "Describing Trends in Scatter Plots").

standard_anchor(im_grade8_unit6, im_lesson, "IM-G8-U6-L6", "The Slope of a Fitted Line").

standard_anchor(im_grade8_unit6, im_lesson, "IM-G8-U6-L7", "Observing More Patterns in Scatter Plots").

standard_anchor(im_grade8_unit6, im_lesson, "IM-G8-U6-L8", "Analyzing Bivariate Data").

standard_anchor(im_grade8_unit6, im_lesson, "IM-G8-U6-L9", "Looking for Associations").

standard_anchor(im_grade8_unit6, im_lesson, "IM-G8-U6-L10", "Using Data Displays to Find Associations").

standard_anchor(im_grade8_unit6, im_lesson, "IM-G8-U6-L11", "Gone in 30 Seconds").

standard_anchor(im_grade8_unit7, im_lesson, "IM-G8-U7-L1", "Exponent Review").

standard_anchor(im_grade8_unit7, im_lesson, "IM-G8-U7-L2", "Multiplying Powers of 10").

standard_anchor(im_grade8_unit7, im_lesson, "IM-G8-U7-L3", "Powers of Powers of 10").

standard_anchor(im_grade8_unit7, im_lesson, "IM-G8-U7-L4", "Dividing Powers of 10").

standard_anchor(im_grade8_unit7, im_lesson, "IM-G8-U7-L5", "Negative Exponents with Powers of 10").

standard_anchor(im_grade8_unit7, im_lesson, "IM-G8-U7-L6", "What about Other Bases?").

standard_anchor(im_grade8_unit7, im_lesson, "IM-G8-U7-L7", "Practice with Rational Bases").

standard_anchor(im_grade8_unit7, im_lesson, "IM-G8-U7-L8", "Combining Bases").

standard_anchor(im_grade8_unit7, im_lesson, "IM-G8-U7-L9", "Describing Large and Small Numbers Using Powers of 10").

standard_anchor(im_grade8_unit7, im_lesson, "IM-G8-U7-L10", "Representing Large Numbers on the Number Line").

standard_anchor(im_grade8_unit7, im_lesson, "IM-G8-U7-L11", "Representing Small Numbers on the Number Line").

standard_anchor(im_grade8_unit7, im_lesson, "IM-G8-U7-L12", "Applications of Arithmetic with Powers of 10").

standard_anchor(im_grade8_unit7, im_lesson, "IM-G8-U7-L13", "Definition of Scientific Notation").

standard_anchor(im_grade8_unit7, im_lesson, "IM-G8-U7-L14", "Estimating with Scientific Notation").

standard_anchor(im_grade8_unit7, im_lesson, "IM-G8-U7-L15", "Adding and Subtracting with Scientific Notation").

standard_anchor(im_grade8_unit7, im_lesson, "IM-G8-U7-L16", "Is a Smartphone Smart Enough to Go to the Moon?").

standard_anchor(pythagorean_theorem, im_lesson, "IM-G8-U8-L1", "The Areas of Squares").

standard_anchor(pythagorean_theorem, im_lesson, "IM-G8-U8-L2", "Side Lengths and Areas").

standard_anchor(pythagorean_theorem, im_lesson, "IM-G8-U8-L3", "Square Roots").

standard_anchor(pythagorean_theorem, im_lesson, "IM-G8-U8-L4", "Rational and Irrational Numbers").

standard_anchor(pythagorean_theorem, im_lesson, "IM-G8-U8-L5", "Square Roots on the Number Line").

standard_anchor(pythagorean_theorem, im_lesson, "IM-G8-U8-L6", "Reasoning about Square Roots").

standard_anchor(pythagorean_theorem, im_lesson, "IM-G8-U8-L7", "Finding Side Lengths of Triangles").

standard_anchor(pythagorean_theorem, im_lesson, "IM-G8-U8-L8", "A Proof of the Pythagorean Theorem").

standard_anchor(pythagorean_theorem, im_lesson, "IM-G8-U8-L9", "Finding Unknown Side Lengths").

standard_anchor(pythagorean_theorem, im_lesson, "IM-G8-U8-L10", "The Converse").

standard_anchor(pythagorean_theorem, im_lesson, "IM-G8-U8-L11", "Applications of the Pythagorean Theorem").

standard_anchor(pythagorean_theorem, im_lesson, "IM-G8-U8-L12", "More Applications of the Pythagorean Theorem").

standard_anchor(pythagorean_theorem, im_lesson, "IM-G8-U8-L13", "Finding Distances in the Coordinate Plane").

standard_anchor(pythagorean_theorem, im_lesson, "IM-G8-U8-L14", "Edge Lengths and Volumes").

standard_anchor(pythagorean_theorem, im_lesson, "IM-G8-U8-L15", "Cube Roots").

standard_anchor(pythagorean_theorem, im_lesson, "IM-G8-U8-L16", "Decimal Representations of Rational Numbers").

standard_anchor(pythagorean_theorem, im_lesson, "IM-G8-U8-L17", "Infinite Decimal Expansions").

standard_anchor(pythagorean_theorem, im_lesson, "IM-G8-U8-L18", "When Is the Same Size Not the Same Size?").

standard_anchor(im_grade8_unit9, im_lesson, "IM-G8-U9-L1", "Tessellations of the Plane").

standard_anchor(im_grade8_unit9, im_lesson, "IM-G8-U9-L2", "Regular Tessellations").

standard_anchor(im_grade8_unit9, im_lesson, "IM-G8-U9-L3", "Tessellating Polygons").

standard_anchor(im_grade8_unit9, im_lesson, "IM-G8-U9-L4", "What Influences Temperature?").

standard_anchor(im_grade8_unit9, im_lesson, "IM-G8-U9-L5", "Plotting the Temperature").

standard_anchor(im_grade8_unit9, im_lesson, "IM-G8-U9-L6", "Using and Interpreting a Mathematical Model").
