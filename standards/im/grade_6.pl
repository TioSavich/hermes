% standards/im/grade_6.pl - Mappings for grade 6 CCSS/Indiana standards
:- multifile standard_anchor/4.
:- discontiguous standard_anchor/4.

%!  im_grade6_lesson_standard_witness(+ConceptId, +Code, -Witness) is semidet.
%
%   Inspectable witness for one IM Grade 6 lesson anchor in the closed-world
%   finite Grade 6 lesson table. These rows do not carry local tier facts, so
%   the witness states the existing query default explicitly.
im_grade6_lesson_standard_witness(ConceptId, Code, Witness) :-
    witness_dict:witness_dict(im_grade6_lesson_standard_anchor, closed_world_finite_im_grade6_lesson_table,
                              _{concept: ConceptId,
                 framework: im_lesson,
                 code: Code,
                 statement: Statement,
                 tier: 3,
                 tier_evidence: default_tier_for_missing_local_tier,
                 concept_boundary: loaded_geometry_concept_record,
                 concept_evidence: ConceptEvidence,
                 boundary: finite_im_grade6_lesson_anchor_table_not_general_curriculum_model,
                 fact: standard_anchor(ConceptId, im_lesson, Code, Statement) }, WitnessDict13),
    im_grade6_lesson_anchor_fact(ConceptId, Code, Statement),
    im_grade6_lesson_concept_evidence(ConceptId, ConceptEvidence),
    Witness = WitnessDict13.

im_grade6_lesson_anchor_fact(ConceptId, Code, Statement) :-
    Clause = standard_anchor(ConceptId, im_lesson, Code, Statement),
    clause(Clause, true, Ref),
    clause_property(Ref, file(File)),
    sub_atom(File, _, _, _, 'standards/im/grade_6.pl').

im_grade6_lesson_concept_evidence(ConceptId,
    _{ kind: geometry_concept_record,
       fact: geom_concept(ConceptId, Name, Topic, GradeBands) }) :-
    geom_concept(ConceptId, Name, Topic, GradeBands).

standard_anchor(area_compose_decompose_polygons, im_lesson, "IM-G6-U1-L1", "Tiling the Plane").

standard_anchor(area_compose_decompose_polygons, im_lesson, "IM-G6-U1-L2", "Finding Area by Decomposing and Rearranging").

standard_anchor(area_compose_decompose_polygons, im_lesson, "IM-G6-U1-L3", "Reasoning to Find Area").

standard_anchor(area_compose_decompose_polygons, im_lesson, "IM-G6-U1-L4", "Parallelograms").

standard_anchor(area_compose_decompose_polygons, im_lesson, "IM-G6-U1-L5", "Bases and Heights of Parallelograms").

standard_anchor(area_compose_decompose_polygons, im_lesson, "IM-G6-U1-L6", "Area of Parallelograms").

standard_anchor(area_compose_decompose_polygons, im_lesson, "IM-G6-U1-L7", "From Parallelograms to Triangles").

standard_anchor(area_compose_decompose_polygons, im_lesson, "IM-G6-U1-L8", "Area of Triangles").

standard_anchor(area_compose_decompose_polygons, im_lesson, "IM-G6-U1-L9", "Formula for the Area of a Triangle").

standard_anchor(area_compose_decompose_polygons, im_lesson, "IM-G6-U1-L10", "Bases and Heights of Triangles").

standard_anchor(area_compose_decompose_polygons, im_lesson, "IM-G6-U1-L11", "Polygons").

standard_anchor(area_compose_decompose_polygons, im_lesson, "IM-G6-U1-L12", "What Is Surface Area?").

standard_anchor(area_compose_decompose_polygons, im_lesson, "IM-G6-U1-L13", "Polyhedra").

standard_anchor(area_compose_decompose_polygons, im_lesson, "IM-G6-U1-L14", "Nets and Surface Area").

standard_anchor(area_compose_decompose_polygons, im_lesson, "IM-G6-U1-L15", "More Nets, More Surface Area").

standard_anchor(area_compose_decompose_polygons, im_lesson, "IM-G6-U1-L16", "Distinguishing Between Surface Area and Volume").

standard_anchor(area_compose_decompose_polygons, im_lesson, "IM-G6-U1-L17", "Squares and Cubes").

standard_anchor(area_compose_decompose_polygons, im_lesson, "IM-G6-U1-L18", "Surface Area of a Cube").

standard_anchor(area_compose_decompose_polygons, im_lesson, "IM-G6-U1-L19", "All about Tents").

standard_anchor(im_grade6_unit2, im_lesson, "IM-G6-U2-L1", "Introducing Ratios and Ratio Language").

standard_anchor(im_grade6_unit2, im_lesson, "IM-G6-U2-L2", "Representing Ratios with Diagrams").

standard_anchor(im_grade6_unit2, im_lesson, "IM-G6-U2-L3", "Recipes").

standard_anchor(im_grade6_unit2, im_lesson, "IM-G6-U2-L4", "Color Mixtures").

standard_anchor(im_grade6_unit2, im_lesson, "IM-G6-U2-L5", "Defining Equivalent Ratios").

standard_anchor(im_grade6_unit2, im_lesson, "IM-G6-U2-L6", "Introducing Double Number Line Diagrams").

standard_anchor(im_grade6_unit2, im_lesson, "IM-G6-U2-L7", "Creating Double Number Line Diagrams").

standard_anchor(im_grade6_unit2, im_lesson, "IM-G6-U2-L8", "How Much for One?").

standard_anchor(im_grade6_unit2, im_lesson, "IM-G6-U2-L9", "Constant Speed").

standard_anchor(im_grade6_unit2, im_lesson, "IM-G6-U2-L10", "Comparing Situations by Examining Ratios").

standard_anchor(im_grade6_unit2, im_lesson, "IM-G6-U2-L11", "Representing Ratios with Tables").

standard_anchor(im_grade6_unit2, im_lesson, "IM-G6-U2-L12", "Navigating a Table of Equivalent Ratios").

standard_anchor(im_grade6_unit2, im_lesson, "IM-G6-U2-L13", "Tables and Double Number Line Diagrams").

standard_anchor(im_grade6_unit2, im_lesson, "IM-G6-U2-L14", "Solving Equivalent Ratio Problems").

standard_anchor(im_grade6_unit2, im_lesson, "IM-G6-U2-L15", "Part-Part-Whole Ratios").

standard_anchor(im_grade6_unit2, im_lesson, "IM-G6-U2-L16", "Solving More Ratio Problems").

standard_anchor(im_grade6_unit2, im_lesson, "IM-G6-U2-L17", "A Fermi Problem").

standard_anchor(im_grade6_unit3, im_lesson, "IM-G6-U3-L1", "Anchoring Units of Measurement").

standard_anchor(im_grade6_unit3, im_lesson, "IM-G6-U3-L2", "Measuring with Different-Size Units").

standard_anchor(im_grade6_unit3, im_lesson, "IM-G6-U3-L3", "Converting Units").

standard_anchor(im_grade6_unit3, im_lesson, "IM-G6-U3-L4", "Comparing Speeds and Prices").

standard_anchor(im_grade6_unit3, im_lesson, "IM-G6-U3-L5", "Interpreting Rates").

standard_anchor(im_grade6_unit3, im_lesson, "IM-G6-U3-L6", "Equivalent Ratios Have the Same Unit Rates").

standard_anchor(im_grade6_unit3, im_lesson, "IM-G6-U3-L7", "More Rate Comparisons").

standard_anchor(im_grade6_unit3, im_lesson, "IM-G6-U3-L8", "Solving Rate Problems").

standard_anchor(im_grade6_unit3, im_lesson, "IM-G6-U3-L9", "More about Constant Speed").

standard_anchor(im_grade6_unit3, im_lesson, "IM-G6-U3-L10", "What Are Percentages?").

standard_anchor(im_grade6_unit3, im_lesson, "IM-G6-U3-L11", "Representing Percentages with Double Number Line Diagrams").

standard_anchor(im_grade6_unit3, im_lesson, "IM-G6-U3-L12", "Representing Percentages in Different Ways").

standard_anchor(im_grade6_unit3, im_lesson, "IM-G6-U3-L13", "Benchmark Percentages").

standard_anchor(im_grade6_unit3, im_lesson, "IM-G6-U3-L14", "Solving Percentage Problems").

standard_anchor(im_grade6_unit3, im_lesson, "IM-G6-U3-L15", "Finding This Percent of That").

standard_anchor(im_grade6_unit3, im_lesson, "IM-G6-U3-L16", "Finding the Percentage").

standard_anchor(im_grade6_unit3, im_lesson, "IM-G6-U3-L17", "Painting a Room").

standard_anchor(volume_prism_fractional_edges, im_lesson, "IM-G6-U4-L1", "Size of Divisor and Size of Quotient").

standard_anchor(volume_prism_fractional_edges, im_lesson, "IM-G6-U4-L2", "Meanings of Division").

standard_anchor(volume_prism_fractional_edges, im_lesson, "IM-G6-U4-L3", "Interpreting Division Situations").

standard_anchor(volume_prism_fractional_edges, im_lesson, "IM-G6-U4-L4", "How Many Groups? (Part 1)").

standard_anchor(volume_prism_fractional_edges, im_lesson, "IM-G6-U4-L5", "How Many Groups? (Part 2)").

standard_anchor(volume_prism_fractional_edges, im_lesson, "IM-G6-U4-L6", "Using Diagrams to Find the Number of Groups").

standard_anchor(volume_prism_fractional_edges, im_lesson, "IM-G6-U4-L7", "What Fraction of a Group?").

standard_anchor(volume_prism_fractional_edges, im_lesson, "IM-G6-U4-L8", "How Much in Each Group? (Part 1)").

standard_anchor(volume_prism_fractional_edges, im_lesson, "IM-G6-U4-L9", "How Much in Each Group? (Part 2)").

standard_anchor(volume_prism_fractional_edges, im_lesson, "IM-G6-U4-L10", "Dividing by Unit and Non-Unit Fractions").

standard_anchor(volume_prism_fractional_edges, im_lesson, "IM-G6-U4-L11", "Using an Algorithm to Divide Fractions").

standard_anchor(volume_prism_fractional_edges, im_lesson, "IM-G6-U4-L12", "Fractional Lengths").

standard_anchor(volume_prism_fractional_edges, im_lesson, "IM-G6-U4-L13", "Rectangles with Fractional Side Lengths").

standard_anchor(volume_prism_fractional_edges, im_lesson, "IM-G6-U4-L14", "Fractional Lengths in Triangles and Prisms").

standard_anchor(volume_prism_fractional_edges, im_lesson, "IM-G6-U4-L15", "Volume of Prisms").

standard_anchor(volume_prism_fractional_edges, im_lesson, "IM-G6-U4-L16", "Solving Problems Involving Fractions").

standard_anchor(volume_prism_fractional_edges, im_lesson, "IM-G6-U4-L17", "Fitting Boxes into Boxes").

standard_anchor(im_grade6_unit5, im_lesson, "IM-G6-U5-L1", "Using Decimals in a Shopping Context").

standard_anchor(im_grade6_unit5, im_lesson, "IM-G6-U5-L2", "Using Diagrams to Represent Addition and Subtraction").

standard_anchor(im_grade6_unit5, im_lesson, "IM-G6-U5-L3", "Adding and Subtracting Decimals with Few Non-Zero Digits").

standard_anchor(im_grade6_unit5, im_lesson, "IM-G6-U5-L4", "Adding and Subtracting Decimals with Many Non-Zero Digits").

standard_anchor(im_grade6_unit5, im_lesson, "IM-G6-U5-L5", "Using Fractions to Multiply Decimals").

standard_anchor(im_grade6_unit5, im_lesson, "IM-G6-U5-L6", "Methods for Multiplying Decimals").

standard_anchor(im_grade6_unit5, im_lesson, "IM-G6-U5-L7", "Using Diagrams to Represent Multiplication").

standard_anchor(im_grade6_unit5, im_lesson, "IM-G6-U5-L8", "Calculating Products of Decimals").

standard_anchor(im_grade6_unit5, im_lesson, "IM-G6-U5-L9", "Using Base-Ten Diagrams to Divide").

standard_anchor(im_grade6_unit5, im_lesson, "IM-G6-U5-L10", "Using Partial Quotients").

standard_anchor(im_grade6_unit5, im_lesson, "IM-G6-U5-L11", "Using Long Division").

standard_anchor(im_grade6_unit5, im_lesson, "IM-G6-U5-L12", "Dividing Numbers that Result in a Decimal").

standard_anchor(im_grade6_unit5, im_lesson, "IM-G6-U5-L13", "Dividing a Decimal by a Decimal").

standard_anchor(im_grade6_unit5, im_lesson, "IM-G6-U5-L14", "Solving Problems Involving Decimals").

standard_anchor(im_grade6_unit5, im_lesson, "IM-G6-U5-L15", "Making and Measuring Boxes").

standard_anchor(im_grade6_unit6, im_lesson, "IM-G6-U6-L1", "Tape Diagrams and Equations").

standard_anchor(im_grade6_unit6, im_lesson, "IM-G6-U6-L2", "Truth and Equations").

standard_anchor(im_grade6_unit6, im_lesson, "IM-G6-U6-L3", "Staying in Balance").

standard_anchor(im_grade6_unit6, im_lesson, "IM-G6-U6-L4", "Practice Solving Equations").

standard_anchor(im_grade6_unit6, im_lesson, "IM-G6-U6-L5", "Represent Situations with Equations").

standard_anchor(im_grade6_unit6, im_lesson, "IM-G6-U6-L6", "Percentages and Equations").

standard_anchor(im_grade6_unit6, im_lesson, "IM-G6-U6-L7", "Write Expressions with Variables").

standard_anchor(im_grade6_unit6, im_lesson, "IM-G6-U6-L8", "Equal and Equivalent").

standard_anchor(im_grade6_unit6, im_lesson, "IM-G6-U6-L9", "The Distributive Property, Part 1").

standard_anchor(im_grade6_unit6, im_lesson, "IM-G6-U6-L10", "The Distributive Property, Part 2").

standard_anchor(im_grade6_unit6, im_lesson, "IM-G6-U6-L11", "The Distributive Property, Part 3").

standard_anchor(im_grade6_unit6, im_lesson, "IM-G6-U6-L12", "Meaning of Exponents").

standard_anchor(im_grade6_unit6, im_lesson, "IM-G6-U6-L13", "Expressions with Exponents").

standard_anchor(im_grade6_unit6, im_lesson, "IM-G6-U6-L14", "Evaluating Expressions with Exponents").

standard_anchor(im_grade6_unit6, im_lesson, "IM-G6-U6-L15", "Equivalent Exponential Expressions").

standard_anchor(im_grade6_unit6, im_lesson, "IM-G6-U6-L16", "Two Related Quantities, Part 1").

standard_anchor(im_grade6_unit6, im_lesson, "IM-G6-U6-L17", "Two Related Quantities, Part 2").

standard_anchor(im_grade6_unit6, im_lesson, "IM-G6-U6-L18", "More Relationships").

standard_anchor(im_grade6_unit6, im_lesson, "IM-G6-U6-L19", "Tables, Equations, and Graphs, Oh My!").

standard_anchor(polygons_in_coordinate_plane, im_lesson, "IM-G6-U7-L1", "Positive and Negative Numbers").

standard_anchor(polygons_in_coordinate_plane, im_lesson, "IM-G6-U7-L2", "Points on the Number Line").

standard_anchor(polygons_in_coordinate_plane, im_lesson, "IM-G6-U7-L3", "Comparing Positive and Negative Numbers").

standard_anchor(polygons_in_coordinate_plane, im_lesson, "IM-G6-U7-L4", "Ordering Rational Numbers").

standard_anchor(polygons_in_coordinate_plane, im_lesson, "IM-G6-U7-L5", "Using Negative Numbers to Make Sense of Contexts").

standard_anchor(polygons_in_coordinate_plane, im_lesson, "IM-G6-U7-L6", "Absolute Value of Numbers").

standard_anchor(polygons_in_coordinate_plane, im_lesson, "IM-G6-U7-L7", "Comparing Numbers and Distance from Zero").

standard_anchor(polygons_in_coordinate_plane, im_lesson, "IM-G6-U7-L8", "Writing and Graphing Inequalities").

standard_anchor(polygons_in_coordinate_plane, im_lesson, "IM-G6-U7-L9", "Solutions of Inequalities").

standard_anchor(polygons_in_coordinate_plane, im_lesson, "IM-G6-U7-L10", "Interpreting Inequalities").

standard_anchor(polygons_in_coordinate_plane, im_lesson, "IM-G6-U7-L11", "Points in the Coordinate Plane").

standard_anchor(polygons_in_coordinate_plane, im_lesson, "IM-G6-U7-L12", "Constructing the Coordinate Plane").

standard_anchor(polygons_in_coordinate_plane, im_lesson, "IM-G6-U7-L13", "Interpreting Points in a Coordinate Plane").

standard_anchor(polygons_in_coordinate_plane, im_lesson, "IM-G6-U7-L14", "Distances in the Coordinate Plane").

standard_anchor(polygons_in_coordinate_plane, im_lesson, "IM-G6-U7-L15", "Shapes in the Coordinate Plane").

standard_anchor(polygons_in_coordinate_plane, im_lesson, "IM-G6-U7-L16", "Common Factors").

standard_anchor(polygons_in_coordinate_plane, im_lesson, "IM-G6-U7-L17", "Common Multiples").

standard_anchor(polygons_in_coordinate_plane, im_lesson, "IM-G6-U7-L18", "Using Common Multiples and Common Factors").

standard_anchor(polygons_in_coordinate_plane, im_lesson, "IM-G6-U7-L19", "Drawing in the Coordinate Plane").

standard_anchor(im_grade6_unit8, im_lesson, "IM-G6-U8-L1", "Got Data?").

standard_anchor(im_grade6_unit8, im_lesson, "IM-G6-U8-L2", "Statistical Questions").

standard_anchor(im_grade6_unit8, im_lesson, "IM-G6-U8-L3", "Representing Data Graphically").

standard_anchor(im_grade6_unit8, im_lesson, "IM-G6-U8-L4", "Dot Plots").

standard_anchor(im_grade6_unit8, im_lesson, "IM-G6-U8-L5", "Using Dot Plots to Answer Statistical Questions").

standard_anchor(im_grade6_unit8, im_lesson, "IM-G6-U8-L6", "Interpreting Histograms").

standard_anchor(im_grade6_unit8, im_lesson, "IM-G6-U8-L7", "Using Histograms to Answer Statistical Questions").

standard_anchor(im_grade6_unit8, im_lesson, "IM-G6-U8-L8", "Describing Distributions on Histograms").

standard_anchor(im_grade6_unit8, im_lesson, "IM-G6-U8-L9", "Mean").

standard_anchor(im_grade6_unit8, im_lesson, "IM-G6-U8-L10", "Finding and Interpreting the Mean as the Balance Point").

standard_anchor(im_grade6_unit8, im_lesson, "IM-G6-U8-L11", "Variability and MAD").

standard_anchor(im_grade6_unit8, im_lesson, "IM-G6-U8-L12", "Using Mean and MAD to Make Comparisons").

standard_anchor(im_grade6_unit8, im_lesson, "IM-G6-U8-L13", "Median").

standard_anchor(im_grade6_unit8, im_lesson, "IM-G6-U8-L14", "Comparing Mean and Median").

standard_anchor(im_grade6_unit8, im_lesson, "IM-G6-U8-L15", "Quartiles and Interquartile Range").

standard_anchor(im_grade6_unit8, im_lesson, "IM-G6-U8-L16", "Box Plots").

standard_anchor(im_grade6_unit8, im_lesson, "IM-G6-U8-L17", "Using Box Plots").

standard_anchor(im_grade6_unit8, im_lesson, "IM-G6-U8-L18", "Using Data to Solve Problems").

standard_anchor(im_grade6_unit9, im_lesson, "IM-G6-U9-L1", "Fermi Problems").

standard_anchor(im_grade6_unit9, im_lesson, "IM-G6-U9-L2", "Energy Flow").

standard_anchor(im_grade6_unit9, im_lesson, "IM-G6-U9-L3", "Making Paper").

standard_anchor(im_grade6_unit9, im_lesson, "IM-G6-U9-L4", "If Our Class Were the World").

standard_anchor(im_grade6_unit9, im_lesson, "IM-G6-U9-L5", "How Do We Choose?").

standard_anchor(im_grade6_unit9, im_lesson, "IM-G6-U9-L6", "More than Two Choices").

standard_anchor(im_grade6_unit9, im_lesson, "IM-G6-U9-L7", "Comparing Voting Systems").

standard_anchor(im_grade6_unit9, im_lesson, "IM-G6-U9-L8", "Picking Representatives").

standard_anchor(im_grade6_unit9, im_lesson, "IM-G6-U9-L9", "Designing Districts").

standard_anchor(im_grade6_unit9, im_lesson, "IM-G6-U9-L10", "Rectangle Madness").

standard_anchor(im_grade6_unit9, im_lesson, "IM-G6-U9-L11", "Rectangle Fractions").
