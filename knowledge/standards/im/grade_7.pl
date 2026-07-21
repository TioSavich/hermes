% knowledge/standards/im/grade_7.pl - Mappings for grade 7 CCSS/Indiana standards
:- multifile standard_anchor/4.
:- discontiguous standard_anchor/4.

%!  im_grade7_lesson_standard_witness(+ConceptId, +Code, -Witness) is semidet.
%
%   Inspectable witness for one IM Grade 7 lesson anchor in the closed-world
%   finite Grade 7 lesson table. These rows do not carry local tier facts, so
%   the witness states the existing query default explicitly.
im_grade7_lesson_standard_witness(ConceptId, Code, Witness) :-
    witness_dict:witness_dict(im_grade7_lesson_standard_anchor, closed_world_finite_im_grade7_lesson_table,
                              _{concept: ConceptId,
                 framework: im_lesson,
                 code: Code,
                 statement: Statement,
                 tier: 3,
                 tier_evidence: default_tier_for_missing_local_tier,
                 concept_boundary: loaded_geometry_concept_record,
                 concept_evidence: ConceptEvidence,
                 boundary: finite_im_grade7_lesson_anchor_table_not_general_curriculum_model,
                 fact: standard_anchor(ConceptId, im_lesson, Code, Statement) }, WitnessDict13),
    im_grade7_lesson_anchor_fact(ConceptId, Code, Statement),
    im_grade7_lesson_concept_evidence(ConceptId, ConceptEvidence),
    Witness = WitnessDict13.

im_grade7_lesson_anchor_fact(ConceptId, Code, Statement) :-
    Clause = standard_anchor(ConceptId, im_lesson, Code, Statement),
    clause(Clause, true, Ref),
    clause_property(Ref, file(File)),
    sub_atom(File, _, _, _, 'knowledge/standards/im/grade_7.pl').

im_grade7_lesson_concept_evidence(ConceptId,
    _{ kind: geometry_concept_record,
       fact: geom_concept(ConceptId, Name, Topic, GradeBands) }) :-
    geom_concept(ConceptId, Name, Topic, GradeBands).

standard_anchor(scale_drawings, im_lesson, "IM-G7-U1-L1", "What Are Scaled Copies?").

standard_anchor(scale_drawings, im_lesson, "IM-G7-U1-L2", "Corresponding Parts and Scale Factors").

standard_anchor(scale_drawings, im_lesson, "IM-G7-U1-L3", "Making Scaled Copies").

standard_anchor(scale_drawings, im_lesson, "IM-G7-U1-L4", "Scaled Relationships").

standard_anchor(scale_drawings, im_lesson, "IM-G7-U1-L5", "The Size of the Scale Factor").

standard_anchor(scale_drawings, im_lesson, "IM-G7-U1-L6", "Scaling and Area").

standard_anchor(scale_drawings, im_lesson, "IM-G7-U1-L7", "Scale Drawings").

standard_anchor(scale_drawings, im_lesson, "IM-G7-U1-L8", "Scale Drawings and Maps").

standard_anchor(scale_drawings, im_lesson, "IM-G7-U1-L9", "Creating Scale Drawings").

standard_anchor(scale_drawings, im_lesson, "IM-G7-U1-L10", "Changing Scales in Scale Drawings").

standard_anchor(scale_drawings, im_lesson, "IM-G7-U1-L11", "Scales without Units").

standard_anchor(scale_drawings, im_lesson, "IM-G7-U1-L12", "Units in Scale Drawings").

standard_anchor(scale_drawings, im_lesson, "IM-G7-U1-L13", "Draw It to Scale").

standard_anchor(im_grade7_unit2, im_lesson, "IM-G7-U2-L1", "One of These Things Is Not Like the Others").

standard_anchor(im_grade7_unit2, im_lesson, "IM-G7-U2-L2", "Introducing Proportional Relationships with Tables").

standard_anchor(im_grade7_unit2, im_lesson, "IM-G7-U2-L3", "More about Constant of Proportionality").

standard_anchor(im_grade7_unit2, im_lesson, "IM-G7-U2-L4", "Proportional Relationships and Equations").

standard_anchor(im_grade7_unit2, im_lesson, "IM-G7-U2-L5", "Two Equations for Each Relationship").

standard_anchor(im_grade7_unit2, im_lesson, "IM-G7-U2-L6", "Writing Equations to Represent Relationships").

standard_anchor(im_grade7_unit2, im_lesson, "IM-G7-U2-L7", "Comparing Relationships with Tables").

standard_anchor(im_grade7_unit2, im_lesson, "IM-G7-U2-L8", "Comparing Relationships with Equations").

standard_anchor(im_grade7_unit2, im_lesson, "IM-G7-U2-L9", "Solving Problems about Proportional Relationships").

standard_anchor(im_grade7_unit2, im_lesson, "IM-G7-U2-L10", "Introducing Graphs of Proportional Relationships").

standard_anchor(im_grade7_unit2, im_lesson, "IM-G7-U2-L11", "Interpreting Graphs of Proportional Relationships").

standard_anchor(im_grade7_unit2, im_lesson, "IM-G7-U2-L12", "Using Graphs to Compare Relationships").

standard_anchor(im_grade7_unit2, im_lesson, "IM-G7-U2-L13", "Two Graphs for Each Relationship").

standard_anchor(im_grade7_unit2, im_lesson, "IM-G7-U2-L14", "Four Representations").

standard_anchor(im_grade7_unit2, im_lesson, "IM-G7-U2-L15", "Using Water Efficiently").

standard_anchor(circle_area_circumference, im_lesson, "IM-G7-U3-L1", "How Well Can You Measure?").

standard_anchor(circle_area_circumference, im_lesson, "IM-G7-U3-L2", "Exploring Circles").

standard_anchor(circle_area_circumference, im_lesson, "IM-G7-U3-L3", "Exploring Circumference").

standard_anchor(circle_area_circumference, im_lesson, "IM-G7-U3-L4", "Applying Circumference").

standard_anchor(circle_area_circumference, im_lesson, "IM-G7-U3-L5", "Circumference and Wheels").

standard_anchor(circle_area_circumference, im_lesson, "IM-G7-U3-L6", "Estimating Areas").

standard_anchor(circle_area_circumference, im_lesson, "IM-G7-U3-L7", "Exploring the Area of a Circle").

standard_anchor(circle_area_circumference, im_lesson, "IM-G7-U3-L8", "Relating Area to Circumference").

standard_anchor(circle_area_circumference, im_lesson, "IM-G7-U3-L9", "Applying Area of Circles").

standard_anchor(circle_area_circumference, im_lesson, "IM-G7-U3-L10", "Distinguishing Circumference and Area").

standard_anchor(circle_area_circumference, im_lesson, "IM-G7-U3-L11", "Stained-Glass Windows").

standard_anchor(im_grade7_unit4, im_lesson, "IM-G7-U4-L1", "Lots of Flags").

standard_anchor(im_grade7_unit4, im_lesson, "IM-G7-U4-L2", "Ratios and Rates with Fractions").

standard_anchor(im_grade7_unit4, im_lesson, "IM-G7-U4-L3", "Revisiting Proportional Relationships").

standard_anchor(im_grade7_unit4, im_lesson, "IM-G7-U4-L4", "More than That, Less than That").

standard_anchor(im_grade7_unit4, im_lesson, "IM-G7-U4-L5", "Say It with Decimals").

standard_anchor(im_grade7_unit4, im_lesson, "IM-G7-U4-L6", "Increasing and Decreasing").

standard_anchor(im_grade7_unit4, im_lesson, "IM-G7-U4-L7", "One Hundred Percent").

standard_anchor(im_grade7_unit4, im_lesson, "IM-G7-U4-L8", "Percent Increase and Decrease with Equations").

standard_anchor(im_grade7_unit4, im_lesson, "IM-G7-U4-L9", "Part of a Percent").

standard_anchor(im_grade7_unit4, im_lesson, "IM-G7-U4-L10", "Tax and Tip").

standard_anchor(im_grade7_unit4, im_lesson, "IM-G7-U4-L11", "Percentage Contexts").

standard_anchor(im_grade7_unit4, im_lesson, "IM-G7-U4-L12", "Solving Multi-step Percentage Problems").

standard_anchor(im_grade7_unit4, im_lesson, "IM-G7-U4-L13", "Measurement Error").

standard_anchor(im_grade7_unit4, im_lesson, "IM-G7-U4-L14", "Percent Error").

standard_anchor(im_grade7_unit4, im_lesson, "IM-G7-U4-L15", "Changes on the Earth").

standard_anchor(im_grade7_unit4, im_lesson, "IM-G7-U4-L16", "Posing Percentage Problems").

standard_anchor(im_grade7_unit5, im_lesson, "IM-G7-U5-L1", "Interpreting Negative Numbers").

standard_anchor(im_grade7_unit5, im_lesson, "IM-G7-U5-L2", "Changing Temperatures").

standard_anchor(im_grade7_unit5, im_lesson, "IM-G7-U5-L3", "Changing Elevation").

standard_anchor(im_grade7_unit5, im_lesson, "IM-G7-U5-L4", "Money and Debts").

standard_anchor(im_grade7_unit5, im_lesson, "IM-G7-U5-L5", "Representing Subtraction").

standard_anchor(im_grade7_unit5, im_lesson, "IM-G7-U5-L6", "Finding Differences").

standard_anchor(im_grade7_unit5, im_lesson, "IM-G7-U5-L7", "Adding and Subtracting to Solve Problems").

standard_anchor(im_grade7_unit5, im_lesson, "IM-G7-U5-L8", "Multiplying Rational Numbers (Part 1)").

standard_anchor(im_grade7_unit5, im_lesson, "IM-G7-U5-L9", "Multiplying Rational Numbers (Part 2)").

standard_anchor(im_grade7_unit5, im_lesson, "IM-G7-U5-L10", "Multiply!").

standard_anchor(im_grade7_unit5, im_lesson, "IM-G7-U5-L11", "Dividing Rational Numbers").

standard_anchor(im_grade7_unit5, im_lesson, "IM-G7-U5-L12", "Negative Rates").

standard_anchor(im_grade7_unit5, im_lesson, "IM-G7-U5-L13", "Expressions with Rational Numbers").

standard_anchor(im_grade7_unit5, im_lesson, "IM-G7-U5-L14", "Solving Problems with Rational Numbers").

standard_anchor(im_grade7_unit5, im_lesson, "IM-G7-U5-L15", "Solving Equations with Rational Numbers").

standard_anchor(im_grade7_unit5, im_lesson, "IM-G7-U5-L16", "Representing Contexts with Equations").

standard_anchor(im_grade7_unit5, im_lesson, "IM-G7-U5-L17", "The Stock Market").

standard_anchor(im_grade7_unit6, im_lesson, "IM-G7-U6-L1", "Relationships between Quantities").

standard_anchor(im_grade7_unit6, im_lesson, "IM-G7-U6-L2", "Reasoning about Contexts with Tape Diagrams").

standard_anchor(im_grade7_unit6, im_lesson, "IM-G7-U6-L3", "Reasoning about Equations with Tape Diagrams").

standard_anchor(im_grade7_unit6, im_lesson, "IM-G7-U6-L4", "Reasoning about Equations and Tape Diagrams (Part 1)").

standard_anchor(im_grade7_unit6, im_lesson, "IM-G7-U6-L5", "Reasoning about Equations and Tape Diagrams (Part 2)").

standard_anchor(im_grade7_unit6, im_lesson, "IM-G7-U6-L6", "Distinguishing between Two Types of Situations").

standard_anchor(im_grade7_unit6, im_lesson, "IM-G7-U6-L7", "Reasoning about Solving Equations (Part 1)").

standard_anchor(im_grade7_unit6, im_lesson, "IM-G7-U6-L8", "Reasoning about Solving Equations (Part 2)").

standard_anchor(im_grade7_unit6, im_lesson, "IM-G7-U6-L9", "Dealing with Negative Numbers").

standard_anchor(im_grade7_unit6, im_lesson, "IM-G7-U6-L10", "Different Options for Solving One Equation").

standard_anchor(im_grade7_unit6, im_lesson, "IM-G7-U6-L11", "Using Equations to Solve Problems").

standard_anchor(im_grade7_unit6, im_lesson, "IM-G7-U6-L12", "Solving Problems about Percent Increase or Decrease").

standard_anchor(im_grade7_unit6, im_lesson, "IM-G7-U6-L13", "Reintroducing Inequalities").

standard_anchor(im_grade7_unit6, im_lesson, "IM-G7-U6-L14", "Finding Solutions to Inequalities in Context").

standard_anchor(im_grade7_unit6, im_lesson, "IM-G7-U6-L15", "Efficiently Solving Inequalities").

standard_anchor(im_grade7_unit6, im_lesson, "IM-G7-U6-L16", "Interpreting Inequalities").

standard_anchor(im_grade7_unit6, im_lesson, "IM-G7-U6-L17", "Modeling with Inequalities").

standard_anchor(im_grade7_unit6, im_lesson, "IM-G7-U6-L18", "Subtraction in Equivalent Expressions").

standard_anchor(im_grade7_unit6, im_lesson, "IM-G7-U6-L19", "Expanding and Factoring").

standard_anchor(im_grade7_unit6, im_lesson, "IM-G7-U6-L20", "Combining Like Terms (Part 1)").

standard_anchor(im_grade7_unit6, im_lesson, "IM-G7-U6-L21", "Combining Like Terms (Part 2)").

standard_anchor(im_grade7_unit6, im_lesson, "IM-G7-U6-L22", "Applications of Expressions").

standard_anchor(angle_pair_relationships, im_lesson, "IM-G7-U7-L1", "Relationships of Angles").

standard_anchor(angle_pair_relationships, im_lesson, "IM-G7-U7-L2", "Adjacent Angles").

standard_anchor(angle_pair_relationships, im_lesson, "IM-G7-U7-L3", "Nonadjacent Angles").

standard_anchor(angle_pair_relationships, im_lesson, "IM-G7-U7-L4", "Solving for Unknown Angles").

standard_anchor(angle_pair_relationships, im_lesson, "IM-G7-U7-L5", "Using Equations to Solve for Unknown Angles").

standard_anchor(angle_pair_relationships, im_lesson, "IM-G7-U7-L6", "Building Polygons (Part 1)").

standard_anchor(angle_pair_relationships, im_lesson, "IM-G7-U7-L7", "Building Polygons (Part 2)").

standard_anchor(angle_pair_relationships, im_lesson, "IM-G7-U7-L8", "Triangles with 3 Common Measures").

standard_anchor(angle_pair_relationships, im_lesson, "IM-G7-U7-L9", "Drawing Triangles (Part 1)").

standard_anchor(angle_pair_relationships, im_lesson, "IM-G7-U7-L10", "Drawing Triangles (Part 2)").

standard_anchor(angle_pair_relationships, im_lesson, "IM-G7-U7-L11", "Slicing Solids").

standard_anchor(angle_pair_relationships, im_lesson, "IM-G7-U7-L12", "Volume of Right Prisms").

standard_anchor(angle_pair_relationships, im_lesson, "IM-G7-U7-L13", "Decomposing Bases for Area").

standard_anchor(angle_pair_relationships, im_lesson, "IM-G7-U7-L14", "Surface Area of Right Prisms").

standard_anchor(angle_pair_relationships, im_lesson, "IM-G7-U7-L15", "Distinguishing Volume and Surface Area").

standard_anchor(angle_pair_relationships, im_lesson, "IM-G7-U7-L16", "Applying Volume and Surface Area").

standard_anchor(angle_pair_relationships, im_lesson, "IM-G7-U7-L17", "Building Prisms").

standard_anchor(im_grade7_unit8, im_lesson, "IM-G7-U8-L1", "Mystery Bags").

standard_anchor(im_grade7_unit8, im_lesson, "IM-G7-U8-L2", "Chance Experiments").

standard_anchor(im_grade7_unit8, im_lesson, "IM-G7-U8-L3", "What Are Probabilities?").

standard_anchor(im_grade7_unit8, im_lesson, "IM-G7-U8-L4", "Estimating Probabilities through Repeated Experiments").

standard_anchor(im_grade7_unit8, im_lesson, "IM-G7-U8-L5", "More Estimating Probabilities").

standard_anchor(im_grade7_unit8, im_lesson, "IM-G7-U8-L6", "Estimating Probabilities Using Simulation").

standard_anchor(im_grade7_unit8, im_lesson, "IM-G7-U8-L7", "Simulating Multi-step Experiments").

standard_anchor(im_grade7_unit8, im_lesson, "IM-G7-U8-L8", "Keeping Track of All Possible Outcomes").

standard_anchor(im_grade7_unit8, im_lesson, "IM-G7-U8-L9", "Multi-step Experiments").

standard_anchor(im_grade7_unit8, im_lesson, "IM-G7-U8-L10", "Designing Simulations").

standard_anchor(im_grade7_unit8, im_lesson, "IM-G7-U8-L11", "Comparing Groups").

standard_anchor(im_grade7_unit8, im_lesson, "IM-G7-U8-L12", "Larger Populations").

standard_anchor(im_grade7_unit8, im_lesson, "IM-G7-U8-L13", "What Makes a Good Sample?").

standard_anchor(im_grade7_unit8, im_lesson, "IM-G7-U8-L14", "Sampling in a Fair Way").

standard_anchor(im_grade7_unit8, im_lesson, "IM-G7-U8-L15", "Estimating Population Measures of Center").

standard_anchor(im_grade7_unit8, im_lesson, "IM-G7-U8-L16", "Estimating Population Proportions").

standard_anchor(im_grade7_unit8, im_lesson, "IM-G7-U8-L17", "More about Sampling Variability").

standard_anchor(im_grade7_unit8, im_lesson, "IM-G7-U8-L18", "Comparing Populations Using Samples").

standard_anchor(im_grade7_unit8, im_lesson, "IM-G7-U8-L19", "Comparing Populations with Friends").

standard_anchor(im_grade7_unit8, im_lesson, "IM-G7-U8-L20", "Memory Test").

standard_anchor(im_grade7_unit9, im_lesson, "IM-G7-U9-L1", "Cost of a Meal").

standard_anchor(im_grade7_unit9, im_lesson, "IM-G7-U9-L2", "Costs of Running a Restaurant").

standard_anchor(im_grade7_unit9, im_lesson, "IM-G7-U9-L3", "Restaurant Floor Plan").

standard_anchor(im_grade7_unit9, im_lesson, "IM-G7-U9-L4", "How Crowded Is This Neighborhood?").

standard_anchor(im_grade7_unit9, im_lesson, "IM-G7-U9-L5", "Fermi Problems").

standard_anchor(im_grade7_unit9, im_lesson, "IM-G7-U9-L6", "More Expressions and Equations").

standard_anchor(im_grade7_unit9, im_lesson, "IM-G7-U9-L7", "Measurement Error").

standard_anchor(im_grade7_unit9, im_lesson, "IM-G7-U9-L8", "Deforestation at Scale").

standard_anchor(im_grade7_unit9, im_lesson, "IM-G7-U9-L9", "Measuring Long Distances over Uneven Terrain").

standard_anchor(im_grade7_unit9, im_lesson, "IM-G7-U9-L10", "Building a Trundle Wheel").

standard_anchor(im_grade7_unit9, im_lesson, "IM-G7-U9-L11", "Using a Trundle Wheel to Measure Distances").

standard_anchor(im_grade7_unit9, im_lesson, "IM-G7-U9-L12", "Designing a 5K Course").
