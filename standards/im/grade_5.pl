% standards/im/grade_5.pl - Mappings for grade 5 CCSS/Indiana standards
:- multifile standard_anchor/4.
:- discontiguous standard_anchor/4.

%!  im_grade5_standard_anchor_witness(+ConceptId, +Framework, +Code, -Witness) is semidet.
%
%   Inspectable witness for one IM-generated Grade 5 standard-alignment row in
%   the closed-world finite Grade 5 table. These rows do not carry local tier
%   facts, so the witness states the existing query default explicitly.
im_grade5_standard_anchor_witness(ConceptId, Framework, Code, Witness) :-
    witness_dict:witness_dict(im_grade5_standard_anchor, closed_world_finite_im_grade5_standard_anchor_table,
                              _{concept: ConceptId,
                 framework: Framework,
                 code: Code,
                 statement: Statement,
                 tier: 3,
                 tier_evidence: default_tier_for_missing_local_tier,
                 concept_boundary: loaded_geometry_concept_record,
                 concept_evidence: ConceptEvidence,
                 boundary: finite_im_grade5_standard_anchor_table_not_general_alignment_model,
                 fact: standard_anchor(ConceptId, Framework, Code, Statement) }, WitnessDict13),
    im_grade5_standard_anchor_fact(ConceptId, Framework, Code, Statement),
    im_grade5_standard_concept_evidence(ConceptId, ConceptEvidence),
    Witness = WitnessDict13.

im_grade5_standard_anchor_fact(ConceptId, Framework, Code, Statement) :-
    Clause = standard_anchor(ConceptId, Framework, Code, Statement),
    clause(Clause, true, Ref),
    clause_property(Ref, file(File)),
    sub_atom(File, _, _, _, 'standards/im/grade_5.pl').

im_grade5_standard_concept_evidence(ConceptId,
    _{ kind: geometry_concept_record,
       fact: geom_concept(ConceptId, Name, Topic, GradeBands) }) :-
    geom_concept(ConceptId, Name, Topic, GradeBands).

standard_anchor(im_grade5_u1_l1, ccss, "5.MD.C.3", "Recognize volume as an attribute of solid figures and understand concepts of volume measurement.").

standard_anchor(im_grade5_u1_l10, ccss, "5.MD.C.5", "Relate volume to the operations of multiplication and addition and solve real world and mathematical problems involving volume.").
standard_anchor(im_grade5_u1_l10, in_indiana, "5.CA.7", "Solve real-world problems involving multiplication of fractions, including mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").
standard_anchor(im_grade5_u1_l10, ccss, "5.OA.A.1", "Use parentheses, brackets, or braces in numerical expressions, and evaluate expressions with these symbols.").
standard_anchor(im_grade5_u1_l10, ccss, "5.OA.A.2", "Write simple expressions that record calculations with numbers, and interpret numerical expressions without evaluating them. *For example, express the calculation \"add 8 and 7, then multiply by 2\" as $2 \\times (8 + 7)$. Recognize that $3 \\times (18932 + 921)$ is three times as large as 18932 + 921, without having to calculate the indicated sum or product.*").

standard_anchor(im_grade5_u1_l11, ccss, "5.MD.C.3", "Recognize volume as an attribute of solid figures and understand concepts of volume measurement.").
standard_anchor(im_grade5_u1_l11, ccss, "5.MD.C.5", "Relate volume to the operations of multiplication and addition and solve real world and mathematical problems involving volume.").
standard_anchor(im_grade5_u1_l11, in_indiana, "5.CA.7", "Solve real-world problems involving multiplication of fractions, including mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").

standard_anchor(im_grade5_u1_l12, ccss, "5.MD.C.3", "Recognize volume as an attribute of solid figures and understand concepts of volume measurement.").
standard_anchor(im_grade5_u1_l12, ccss, "5.MD.C.5", "Relate volume to the operations of multiplication and addition and solve real world and mathematical problems involving volume.").
standard_anchor(im_grade5_u1_l12, in_indiana, "5.CA.7", "Solve real-world problems involving multiplication of fractions, including mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").

standard_anchor(im_grade5_u1_l2, ccss, "5.MD.C.3", "Recognize volume as an attribute of solid figures and understand concepts of volume measurement.").
standard_anchor(im_grade5_u1_l2, ccss, "5.MD.C.4", "Measure volumes by counting unit cubes, using cubic cm, cubic in, cubic ft, and improvised units.").

standard_anchor(im_grade5_u1_l3, ccss, "5.MD.C.4", "Measure volumes by counting unit cubes, using cubic cm, cubic in, cubic ft, and improvised units.").

standard_anchor(im_grade5_u1_l4, ccss, "5.MD.C.5", "Relate volume to the operations of multiplication and addition and solve real world and mathematical problems involving volume.").
standard_anchor(im_grade5_u1_l4, in_indiana, "5.CA.7", "Solve real-world problems involving multiplication of fractions, including mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").
standard_anchor(im_grade5_u1_l4, ccss, "5.OA.A.2", "Write simple expressions that record calculations with numbers, and interpret numerical expressions without evaluating them. *For example, express the calculation \"add 8 and 7, then multiply by 2\" as $2 \\times (8 + 7)$. Recognize that $3 \\times (18932 + 921)$ is three times as large as 18932 + 921, without having to calculate the indicated sum or product.*").

standard_anchor(im_grade5_u1_l5, ccss, "5.MD.C.5", "Relate volume to the operations of multiplication and addition and solve real world and mathematical problems involving volume.").
standard_anchor(im_grade5_u1_l5, in_indiana, "5.CA.7", "Solve real-world problems involving multiplication of fractions, including mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").

standard_anchor(im_grade5_u1_l6, ccss, "5.MD.C.5", "Relate volume to the operations of multiplication and addition and solve real world and mathematical problems involving volume.").
standard_anchor(im_grade5_u1_l6, in_indiana, "5.CA.7", "Solve real-world problems involving multiplication of fractions, including mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").
standard_anchor(im_grade5_u1_l6, ccss, "5.OA.A.1", "Use parentheses, brackets, or braces in numerical expressions, and evaluate expressions with these symbols.").
standard_anchor(im_grade5_u1_l6, ccss, "5.OA.A.2", "Write simple expressions that record calculations with numbers, and interpret numerical expressions without evaluating them. *For example, express the calculation \"add 8 and 7, then multiply by 2\" as $2 \\times (8 + 7)$. Recognize that $3 \\times (18932 + 921)$ is three times as large as 18932 + 921, without having to calculate the indicated sum or product.*").

standard_anchor(im_grade5_u1_l7, ccss, "5.MD.C.4", "Measure volumes by counting unit cubes, using cubic cm, cubic in, cubic ft, and improvised units.").

standard_anchor(im_grade5_u1_l8, ccss, "5.MD.C.5", "Relate volume to the operations of multiplication and addition and solve real world and mathematical problems involving volume.").
standard_anchor(im_grade5_u1_l8, in_indiana, "5.CA.7", "Solve real-world problems involving multiplication of fractions, including mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").

standard_anchor(im_grade5_u1_l9, ccss, "5.MD.C.5", "Relate volume to the operations of multiplication and addition and solve real world and mathematical problems involving volume.").
standard_anchor(im_grade5_u1_l9, in_indiana, "5.CA.7", "Solve real-world problems involving multiplication of fractions, including mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").
standard_anchor(im_grade5_u1_l9, ccss, "5.OA.A.2", "Write simple expressions that record calculations with numbers, and interpret numerical expressions without evaluating them. *For example, express the calculation \"add 8 and 7, then multiply by 2\" as $2 \\times (8 + 7)$. Recognize that $3 \\times (18932 + 921)$ is three times as large as 18932 + 921, without having to calculate the indicated sum or product.*").

standard_anchor(im_grade5_u2_l1, ccss, "5.NF.B.3", "Interpret a fraction as division of the numerator by the denominator ($\\frac{a}{b} = a \\div b$). Solve word problems involving division of whole numbers leading to answers in the form of fractions or mixed numbers, e.g., by using visual fraction models or equations to represent the problem. *For example, interpret $\\frac{3}{4}$ as the result of dividing 3 by 4, noting that $\\frac{3}{4}$ multiplied by 4 equals 3, and that when 3 wholes are shared equally among 4 people each person has a share of size $\\frac{3}{4}$. If 9 people want to share a 50-pound sack of rice equally by weight, how many pounds of rice should each person get? Between what two whole numbers does your answer lie?*").

standard_anchor(im_grade5_u2_l10, ccss, "5.NF.B.4", "Apply and extend previous understandings of multiplication to multiply a fraction or whole number by a fraction.").
standard_anchor(im_grade5_u2_l10, in_indiana, "5.CA.5", "Use visual fraction models to multiply a fraction by a fraction or a whole number. (E)").

standard_anchor(im_grade5_u2_l11, ccss, "5.NF.B.3", "Interpret a fraction as division of the numerator by the denominator ($\\frac{a}{b} = a \\div b$). Solve word problems involving division of whole numbers leading to answers in the form of fractions or mixed numbers, e.g., by using visual fraction models or equations to represent the problem. *For example, interpret $\\frac{3}{4}$ as the result of dividing 3 by 4, noting that $\\frac{3}{4}$ multiplied by 4 equals 3, and that when 3 wholes are shared equally among 4 people each person has a share of size $\\frac{3}{4}$. If 9 people want to share a 50-pound sack of rice equally by weight, how many pounds of rice should each person get? Between what two whole numbers does your answer lie?*").
standard_anchor(im_grade5_u2_l11, ccss, "5.NF.B.4", "Apply and extend previous understandings of multiplication to multiply a fraction or whole number by a fraction.").
standard_anchor(im_grade5_u2_l11, in_indiana, "5.CA.5", "Use visual fraction models to multiply a fraction by a fraction or a whole number. (E)").

standard_anchor(im_grade5_u2_l12, ccss, "5.NF.B.4", "Apply and extend previous understandings of multiplication to multiply a fraction or whole number by a fraction.").
standard_anchor(im_grade5_u2_l12, in_indiana, "5.CA.5", "Use visual fraction models to multiply a fraction by a fraction or a whole number. (E)").

standard_anchor(im_grade5_u2_l13, ccss, "5.NF.B.4", "Apply and extend previous understandings of multiplication to multiply a fraction or whole number by a fraction.").
standard_anchor(im_grade5_u2_l13, in_indiana, "5.CA.5", "Use visual fraction models to multiply a fraction by a fraction or a whole number. (E)").
standard_anchor(im_grade5_u2_l13, ccss, "5.OA.A.1", "Use parentheses, brackets, or braces in numerical expressions, and evaluate expressions with these symbols.").

standard_anchor(im_grade5_u2_l14, ccss, "5.NF.B.4", "Apply and extend previous understandings of multiplication to multiply a fraction or whole number by a fraction.").
standard_anchor(im_grade5_u2_l14, in_indiana, "5.CA.5", "Use visual fraction models to multiply a fraction by a fraction or a whole number. (E)").

standard_anchor(im_grade5_u2_l15, ccss, "5.NF.B.3", "Interpret a fraction as division of the numerator by the denominator ($\\frac{a}{b} = a \\div b$). Solve word problems involving division of whole numbers leading to answers in the form of fractions or mixed numbers, e.g., by using visual fraction models or equations to represent the problem. *For example, interpret $\\frac{3}{4}$ as the result of dividing 3 by 4, noting that $\\frac{3}{4}$ multiplied by 4 equals 3, and that when 3 wholes are shared equally among 4 people each person has a share of size $\\frac{3}{4}$. If 9 people want to share a 50-pound sack of rice equally by weight, how many pounds of rice should each person get? Between what two whole numbers does your answer lie?*").
standard_anchor(im_grade5_u2_l15, ccss, "5.NF.B.4", "Apply and extend previous understandings of multiplication to multiply a fraction or whole number by a fraction.").
standard_anchor(im_grade5_u2_l15, in_indiana, "5.CA.5", "Use visual fraction models to multiply a fraction by a fraction or a whole number. (E)").

standard_anchor(im_grade5_u2_l16, ccss, "5.NF.B.4", "Apply and extend previous understandings of multiplication to multiply a fraction or whole number by a fraction.").
standard_anchor(im_grade5_u2_l16, in_indiana, "5.CA.5", "Use visual fraction models to multiply a fraction by a fraction or a whole number. (E)").

standard_anchor(im_grade5_u2_l17, ccss, "5.NF.B.4", "Apply and extend previous understandings of multiplication to multiply a fraction or whole number by a fraction.").
standard_anchor(im_grade5_u2_l17, in_indiana, "5.CA.5", "Use visual fraction models to multiply a fraction by a fraction or a whole number. (E)").

standard_anchor(im_grade5_u2_l2, ccss, "5.NF.B.3", "Interpret a fraction as division of the numerator by the denominator ($\\frac{a}{b} = a \\div b$). Solve word problems involving division of whole numbers leading to answers in the form of fractions or mixed numbers, e.g., by using visual fraction models or equations to represent the problem. *For example, interpret $\\frac{3}{4}$ as the result of dividing 3 by 4, noting that $\\frac{3}{4}$ multiplied by 4 equals 3, and that when 3 wholes are shared equally among 4 people each person has a share of size $\\frac{3}{4}$. If 9 people want to share a 50-pound sack of rice equally by weight, how many pounds of rice should each person get? Between what two whole numbers does your answer lie?*").

standard_anchor(im_grade5_u2_l3, ccss, "5.NF.B.3", "Interpret a fraction as division of the numerator by the denominator ($\\frac{a}{b} = a \\div b$). Solve word problems involving division of whole numbers leading to answers in the form of fractions or mixed numbers, e.g., by using visual fraction models or equations to represent the problem. *For example, interpret $\\frac{3}{4}$ as the result of dividing 3 by 4, noting that $\\frac{3}{4}$ multiplied by 4 equals 3, and that when 3 wholes are shared equally among 4 people each person has a share of size $\\frac{3}{4}$. If 9 people want to share a 50-pound sack of rice equally by weight, how many pounds of rice should each person get? Between what two whole numbers does your answer lie?*").

standard_anchor(im_grade5_u2_l4, ccss, "5.NF.B.3", "Interpret a fraction as division of the numerator by the denominator ($\\frac{a}{b} = a \\div b$). Solve word problems involving division of whole numbers leading to answers in the form of fractions or mixed numbers, e.g., by using visual fraction models or equations to represent the problem. *For example, interpret $\\frac{3}{4}$ as the result of dividing 3 by 4, noting that $\\frac{3}{4}$ multiplied by 4 equals 3, and that when 3 wholes are shared equally among 4 people each person has a share of size $\\frac{3}{4}$. If 9 people want to share a 50-pound sack of rice equally by weight, how many pounds of rice should each person get? Between what two whole numbers does your answer lie?*").

standard_anchor(im_grade5_u2_l5, ccss, "5.NF.B.3", "Interpret a fraction as division of the numerator by the denominator ($\\frac{a}{b} = a \\div b$). Solve word problems involving division of whole numbers leading to answers in the form of fractions or mixed numbers, e.g., by using visual fraction models or equations to represent the problem. *For example, interpret $\\frac{3}{4}$ as the result of dividing 3 by 4, noting that $\\frac{3}{4}$ multiplied by 4 equals 3, and that when 3 wholes are shared equally among 4 people each person has a share of size $\\frac{3}{4}$. If 9 people want to share a 50-pound sack of rice equally by weight, how many pounds of rice should each person get? Between what two whole numbers does your answer lie?*").

standard_anchor(im_grade5_u2_l6, ccss, "5.NF.B.3", "Interpret a fraction as division of the numerator by the denominator ($\\frac{a}{b} = a \\div b$). Solve word problems involving division of whole numbers leading to answers in the form of fractions or mixed numbers, e.g., by using visual fraction models or equations to represent the problem. *For example, interpret $\\frac{3}{4}$ as the result of dividing 3 by 4, noting that $\\frac{3}{4}$ multiplied by 4 equals 3, and that when 3 wholes are shared equally among 4 people each person has a share of size $\\frac{3}{4}$. If 9 people want to share a 50-pound sack of rice equally by weight, how many pounds of rice should each person get? Between what two whole numbers does your answer lie?*").
standard_anchor(im_grade5_u2_l6, ccss, "5.OA.A.2", "Write simple expressions that record calculations with numbers, and interpret numerical expressions without evaluating them. *For example, express the calculation \"add 8 and 7, then multiply by 2\" as $2 \\times (8 + 7)$. Recognize that $3 \\times (18932 + 921)$ is three times as large as 18932 + 921, without having to calculate the indicated sum or product.*").

standard_anchor(im_grade5_u2_l7, ccss, "5.NF.B.3", "Interpret a fraction as division of the numerator by the denominator ($\\frac{a}{b} = a \\div b$). Solve word problems involving division of whole numbers leading to answers in the form of fractions or mixed numbers, e.g., by using visual fraction models or equations to represent the problem. *For example, interpret $\\frac{3}{4}$ as the result of dividing 3 by 4, noting that $\\frac{3}{4}$ multiplied by 4 equals 3, and that when 3 wholes are shared equally among 4 people each person has a share of size $\\frac{3}{4}$. If 9 people want to share a 50-pound sack of rice equally by weight, how many pounds of rice should each person get? Between what two whole numbers does your answer lie?*").
standard_anchor(im_grade5_u2_l7, ccss, "5.NF.B.4", "Apply and extend previous understandings of multiplication to multiply a fraction or whole number by a fraction.").
standard_anchor(im_grade5_u2_l7, in_indiana, "5.CA.5", "Use visual fraction models to multiply a fraction by a fraction or a whole number. (E)").

standard_anchor(im_grade5_u2_l8, ccss, "5.NF.B.4", "Apply and extend previous understandings of multiplication to multiply a fraction or whole number by a fraction.").
standard_anchor(im_grade5_u2_l8, in_indiana, "5.CA.5", "Use visual fraction models to multiply a fraction by a fraction or a whole number. (E)").
standard_anchor(im_grade5_u2_l8, ccss, "5.OA.A.2", "Write simple expressions that record calculations with numbers, and interpret numerical expressions without evaluating them. *For example, express the calculation \"add 8 and 7, then multiply by 2\" as $2 \\times (8 + 7)$. Recognize that $3 \\times (18932 + 921)$ is three times as large as 18932 + 921, without having to calculate the indicated sum or product.*").

standard_anchor(im_grade5_u2_l9, ccss, "5.NF.B.4", "Apply and extend previous understandings of multiplication to multiply a fraction or whole number by a fraction.").
standard_anchor(im_grade5_u2_l9, in_indiana, "5.CA.5", "Use visual fraction models to multiply a fraction by a fraction or a whole number. (E)").

standard_anchor(im_grade5_u3_l1, ccss, "5.NF.B.4", "Apply and extend previous understandings of multiplication to multiply a fraction or whole number by a fraction.").
standard_anchor(im_grade5_u3_l1, in_indiana, "5.CA.5", "Use visual fraction models to multiply a fraction by a fraction or a whole number. (E)").


standard_anchor(im_grade5_u3_l11, ccss, "5.NF.B.7", "Apply and extend previous understandings of division to divide unit fractions by whole numbers and whole numbers by unit fractions.").

standard_anchor(im_grade5_u3_l12, ccss, "5.NF.B.7", "Apply and extend previous understandings of division to divide unit fractions by whole numbers and whole numbers by unit fractions.").

standard_anchor(im_grade5_u3_l13, ccss, "5.NF.B.7", "Apply and extend previous understandings of division to divide unit fractions by whole numbers and whole numbers by unit fractions.").

standard_anchor(im_grade5_u3_l14, ccss, "5.NF.B.7", "Apply and extend previous understandings of division to divide unit fractions by whole numbers and whole numbers by unit fractions.").

standard_anchor(im_grade5_u3_l15, ccss, "5.NF.B.7", "Apply and extend previous understandings of division to divide unit fractions by whole numbers and whole numbers by unit fractions.").

standard_anchor(im_grade5_u3_l16, ccss, "5.NF.B.7", "Apply and extend previous understandings of division to divide unit fractions by whole numbers and whole numbers by unit fractions.").

standard_anchor(im_grade5_u3_l17, ccss, "5.NF.B.4", "Apply and extend previous understandings of multiplication to multiply a fraction or whole number by a fraction.").
standard_anchor(im_grade5_u3_l17, in_indiana, "5.CA.5", "Use visual fraction models to multiply a fraction by a fraction or a whole number. (E)").
standard_anchor(im_grade5_u3_l17, ccss, "5.NF.B.6", "Solve real world problems involving multiplication of fractions and mixed numbers, e.g., by using visual fraction models or equations to represent the problem.").
standard_anchor(im_grade5_u3_l17, in_indiana, "5.CA.7", "Solve real-world problems involving multiplication of fractions, including mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").
standard_anchor(im_grade5_u3_l17, in_indiana, "5.CA.8", "Solve real-world problems involving division of fractions and mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").
standard_anchor(im_grade5_u3_l17, ccss, "5.NF.B.7", "Apply and extend previous understandings of division to divide unit fractions by whole numbers and whole numbers by unit fractions.").

standard_anchor(im_grade5_u3_l18, ccss, "5.NF.B.4", "Apply and extend previous understandings of multiplication to multiply a fraction or whole number by a fraction.").
standard_anchor(im_grade5_u3_l18, in_indiana, "5.CA.5", "Use visual fraction models to multiply a fraction by a fraction or a whole number. (E)").
standard_anchor(im_grade5_u3_l18, ccss, "5.NF.B.6", "Solve real world problems involving multiplication of fractions and mixed numbers, e.g., by using visual fraction models or equations to represent the problem.").
standard_anchor(im_grade5_u3_l18, in_indiana, "5.CA.7", "Solve real-world problems involving multiplication of fractions, including mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").
standard_anchor(im_grade5_u3_l18, in_indiana, "5.CA.8", "Solve real-world problems involving division of fractions and mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").
standard_anchor(im_grade5_u3_l18, ccss, "5.NF.B.7", "Apply and extend previous understandings of division to divide unit fractions by whole numbers and whole numbers by unit fractions.").

standard_anchor(im_grade5_u3_l19, ccss, "5.NF.B.4", "Apply and extend previous understandings of multiplication to multiply a fraction or whole number by a fraction.").
standard_anchor(im_grade5_u3_l19, in_indiana, "5.CA.5", "Use visual fraction models to multiply a fraction by a fraction or a whole number. (E)").
standard_anchor(im_grade5_u3_l19, ccss, "5.NF.B.7", "Apply and extend previous understandings of division to divide unit fractions by whole numbers and whole numbers by unit fractions.").

standard_anchor(im_grade5_u3_l2, ccss, "5.NF.B.4", "Apply and extend previous understandings of multiplication to multiply a fraction or whole number by a fraction.").
standard_anchor(im_grade5_u3_l2, in_indiana, "5.CA.5", "Use visual fraction models to multiply a fraction by a fraction or a whole number. (E)").

standard_anchor(im_grade5_u3_l20, ccss, "5.NF.B.6", "Solve real world problems involving multiplication of fractions and mixed numbers, e.g., by using visual fraction models or equations to represent the problem.").
standard_anchor(im_grade5_u3_l20, in_indiana, "5.CA.7", "Solve real-world problems involving multiplication of fractions, including mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").
standard_anchor(im_grade5_u3_l20, in_indiana, "5.CA.8", "Solve real-world problems involving division of fractions and mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").
standard_anchor(im_grade5_u3_l20, ccss, "5.NF.B.7", "Apply and extend previous understandings of division to divide unit fractions by whole numbers and whole numbers by unit fractions.").

standard_anchor(im_grade5_u3_l3, ccss, "5.NF.B.4", "Apply and extend previous understandings of multiplication to multiply a fraction or whole number by a fraction.").
standard_anchor(im_grade5_u3_l3, in_indiana, "5.CA.5", "Use visual fraction models to multiply a fraction by a fraction or a whole number. (E)").

standard_anchor(im_grade5_u3_l4, ccss, "5.NF.B.4", "Apply and extend previous understandings of multiplication to multiply a fraction or whole number by a fraction.").
standard_anchor(im_grade5_u3_l4, in_indiana, "5.CA.5", "Use visual fraction models to multiply a fraction by a fraction or a whole number. (E)").

standard_anchor(im_grade5_u3_l5, ccss, "5.NF.B.4", "Apply and extend previous understandings of multiplication to multiply a fraction or whole number by a fraction.").
standard_anchor(im_grade5_u3_l5, in_indiana, "5.CA.5", "Use visual fraction models to multiply a fraction by a fraction or a whole number. (E)").

standard_anchor(im_grade5_u3_l6, ccss, "5.NF.B.4", "Apply and extend previous understandings of multiplication to multiply a fraction or whole number by a fraction.").
standard_anchor(im_grade5_u3_l6, in_indiana, "5.CA.5", "Use visual fraction models to multiply a fraction by a fraction or a whole number. (E)").

standard_anchor(im_grade5_u3_l7, ccss, "5.NF.B.4", "Apply and extend previous understandings of multiplication to multiply a fraction or whole number by a fraction.").
standard_anchor(im_grade5_u3_l7, in_indiana, "5.CA.5", "Use visual fraction models to multiply a fraction by a fraction or a whole number. (E)").

standard_anchor(im_grade5_u3_l8, ccss, "5.NF.B.4", "Apply and extend previous understandings of multiplication to multiply a fraction or whole number by a fraction.").
standard_anchor(im_grade5_u3_l8, in_indiana, "5.CA.5", "Use visual fraction models to multiply a fraction by a fraction or a whole number. (E)").

standard_anchor(im_grade5_u3_l9, ccss, "5.NF.B.4", "Apply and extend previous understandings of multiplication to multiply a fraction or whole number by a fraction.").
standard_anchor(im_grade5_u3_l9, in_indiana, "5.CA.5", "Use visual fraction models to multiply a fraction by a fraction or a whole number. (E)").
standard_anchor(im_grade5_u3_l9, ccss, "5.NF.B.6", "Solve real world problems involving multiplication of fractions and mixed numbers, e.g., by using visual fraction models or equations to represent the problem.").
standard_anchor(im_grade5_u3_l9, in_indiana, "5.CA.7", "Solve real-world problems involving multiplication of fractions, including mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").
standard_anchor(im_grade5_u3_l9, in_indiana, "5.CA.8", "Solve real-world problems involving division of fractions and mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").


standard_anchor(im_grade5_u4_l10, ccss, "5.NBT.B.6", "Find whole-number quotients of whole numbers with up to four-digit dividends and two-digit divisors, using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Illustrate and explain the calculation by using equations, rectangular arrays, and/or area models.").
standard_anchor(im_grade5_u4_l10, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").
standard_anchor(im_grade5_u4_l10, ccss, "5.OA.A.2", "Write simple expressions that record calculations with numbers, and interpret numerical expressions without evaluating them. *For example, express the calculation \"add 8 and 7, then multiply by 2\" as $2 \\times (8 + 7)$. Recognize that $3 \\times (18932 + 921)$ is three times as large as 18932 + 921, without having to calculate the indicated sum or product.*").

standard_anchor(im_grade5_u4_l11, ccss, "5.NBT.B.6", "Find whole-number quotients of whole numbers with up to four-digit dividends and two-digit divisors, using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Illustrate and explain the calculation by using equations, rectangular arrays, and/or area models.").
standard_anchor(im_grade5_u4_l11, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").

standard_anchor(im_grade5_u4_l12, ccss, "5.NBT.B.6", "Find whole-number quotients of whole numbers with up to four-digit dividends and two-digit divisors, using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Illustrate and explain the calculation by using equations, rectangular arrays, and/or area models.").
standard_anchor(im_grade5_u4_l12, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").

standard_anchor(im_grade5_u4_l13, ccss, "5.NBT.B.6", "Find whole-number quotients of whole numbers with up to four-digit dividends and two-digit divisors, using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Illustrate and explain the calculation by using equations, rectangular arrays, and/or area models.").
standard_anchor(im_grade5_u4_l13, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").

standard_anchor(im_grade5_u4_l14, ccss, "5.NBT.B.5", "Fluently multiply multi-digit whole numbers using the standard algorithm.").
standard_anchor(im_grade5_u4_l14, ccss, "5.NBT.B.6", "Find whole-number quotients of whole numbers with up to four-digit dividends and two-digit divisors, using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Illustrate and explain the calculation by using equations, rectangular arrays, and/or area models.").
standard_anchor(im_grade5_u4_l14, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").

standard_anchor(im_grade5_u4_l15, ccss, "5.NBT.B.6", "Find whole-number quotients of whole numbers with up to four-digit dividends and two-digit divisors, using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Illustrate and explain the calculation by using equations, rectangular arrays, and/or area models.").
standard_anchor(im_grade5_u4_l15, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").
standard_anchor(im_grade5_u4_l15, ccss, "5.NF.B.3", "Interpret a fraction as division of the numerator by the denominator ($\\frac{a}{b} = a \\div b$). Solve word problems involving division of whole numbers leading to answers in the form of fractions or mixed numbers, e.g., by using visual fraction models or equations to represent the problem. *For example, interpret $\\frac{3}{4}$ as the result of dividing 3 by 4, noting that $\\frac{3}{4}$ multiplied by 4 equals 3, and that when 3 wholes are shared equally among 4 people each person has a share of size $\\frac{3}{4}$. If 9 people want to share a 50-pound sack of rice equally by weight, how many pounds of rice should each person get? Between what two whole numbers does your answer lie?*").

standard_anchor(im_grade5_u4_l16, ccss, "5.OA.A.2", "Write simple expressions that record calculations with numbers, and interpret numerical expressions without evaluating them. *For example, express the calculation \"add 8 and 7, then multiply by 2\" as $2 \\times (8 + 7)$. Recognize that $3 \\times (18932 + 921)$ is three times as large as 18932 + 921, without having to calculate the indicated sum or product.*").

standard_anchor(im_grade5_u4_l17, ccss, "5.MD.C.5", "Relate volume to the operations of multiplication and addition and solve real world and mathematical problems involving volume.").
standard_anchor(im_grade5_u4_l17, in_indiana, "5.CA.7", "Solve real-world problems involving multiplication of fractions, including mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").

standard_anchor(im_grade5_u4_l18, ccss, "5.NBT.B.5", "Fluently multiply multi-digit whole numbers using the standard algorithm.").

standard_anchor(im_grade5_u4_l19, ccss, "5.MD.C.5", "Relate volume to the operations of multiplication and addition and solve real world and mathematical problems involving volume.").
standard_anchor(im_grade5_u4_l19, in_indiana, "5.CA.7", "Solve real-world problems involving multiplication of fractions, including mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").
standard_anchor(im_grade5_u4_l19, ccss, "5.NBT.B.5", "Fluently multiply multi-digit whole numbers using the standard algorithm.").
standard_anchor(im_grade5_u4_l19, ccss, "5.NBT.B.6", "Find whole-number quotients of whole numbers with up to four-digit dividends and two-digit divisors, using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Illustrate and explain the calculation by using equations, rectangular arrays, and/or area models.").
standard_anchor(im_grade5_u4_l19, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").


standard_anchor(im_grade5_u4_l20, ccss, "5.NBT.B.5", "Fluently multiply multi-digit whole numbers using the standard algorithm.").
standard_anchor(im_grade5_u4_l20, ccss, "5.NBT.B.6", "Find whole-number quotients of whole numbers with up to four-digit dividends and two-digit divisors, using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Illustrate and explain the calculation by using equations, rectangular arrays, and/or area models.").
standard_anchor(im_grade5_u4_l20, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").

standard_anchor(im_grade5_u4_l3, ccss, "5.OA.A.2", "Write simple expressions that record calculations with numbers, and interpret numerical expressions without evaluating them. *For example, express the calculation \"add 8 and 7, then multiply by 2\" as $2 \\times (8 + 7)$. Recognize that $3 \\times (18932 + 921)$ is three times as large as 18932 + 921, without having to calculate the indicated sum or product.*").

standard_anchor(im_grade5_u4_l4, ccss, "5.NBT.B.5", "Fluently multiply multi-digit whole numbers using the standard algorithm.").

standard_anchor(im_grade5_u4_l5, ccss, "5.NBT.B.5", "Fluently multiply multi-digit whole numbers using the standard algorithm.").

standard_anchor(im_grade5_u4_l6, ccss, "5.NBT.B.5", "Fluently multiply multi-digit whole numbers using the standard algorithm.").

standard_anchor(im_grade5_u4_l7, ccss, "5.NBT.B.5", "Fluently multiply multi-digit whole numbers using the standard algorithm.").

standard_anchor(im_grade5_u4_l8, ccss, "5.MD.C.3", "Recognize volume as an attribute of solid figures and understand concepts of volume measurement.").
standard_anchor(im_grade5_u4_l8, ccss, "5.MD.C.5", "Relate volume to the operations of multiplication and addition and solve real world and mathematical problems involving volume.").
standard_anchor(im_grade5_u4_l8, in_indiana, "5.CA.7", "Solve real-world problems involving multiplication of fractions, including mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").
standard_anchor(im_grade5_u4_l8, ccss, "5.NBT.B.5", "Fluently multiply multi-digit whole numbers using the standard algorithm.").


standard_anchor(im_grade5_u5_l1, ccss, "5.NBT.A.1", "Recognize that in a multi-digit number, a digit in one place represents 10 times as much as it represents in the place to its right and $\\frac{1}{10}$ of what it represents in the place to its left.").

standard_anchor(im_grade5_u5_l10, ccss, "5.NBT.A.3", "Read, write, and compare decimals to thousandths.").
standard_anchor(im_grade5_u5_l10, ccss, "5.NBT.A.4", "Use place value understanding to round decimals to any place.").

standard_anchor(im_grade5_u5_l11, ccss, "5.NBT.B.7", "Add, subtract, multiply, and divide decimals to hundredths, using concrete models or drawings and strategies based on place value, properties of operations, and/or the relationship between addition and subtraction; relate the strategy to a written method and explain the reasoning used.").
standard_anchor(im_grade5_u5_l11, in_indiana, "5.CA.9", "Add, subtract, multiply, and divide decimals to hundredths, using models or drawings and strategies based on place value or the properties of operations. Describe the strategy and explain the reasoning.").
standard_anchor(im_grade5_u5_l11, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").

standard_anchor(im_grade5_u5_l12, ccss, "5.NBT.B.7", "Add, subtract, multiply, and divide decimals to hundredths, using concrete models or drawings and strategies based on place value, properties of operations, and/or the relationship between addition and subtraction; relate the strategy to a written method and explain the reasoning used.").
standard_anchor(im_grade5_u5_l12, in_indiana, "5.CA.9", "Add, subtract, multiply, and divide decimals to hundredths, using models or drawings and strategies based on place value or the properties of operations. Describe the strategy and explain the reasoning.").
standard_anchor(im_grade5_u5_l12, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").

standard_anchor(im_grade5_u5_l13, ccss, "5.NBT.B.7", "Add, subtract, multiply, and divide decimals to hundredths, using concrete models or drawings and strategies based on place value, properties of operations, and/or the relationship between addition and subtraction; relate the strategy to a written method and explain the reasoning used.").
standard_anchor(im_grade5_u5_l13, in_indiana, "5.CA.9", "Add, subtract, multiply, and divide decimals to hundredths, using models or drawings and strategies based on place value or the properties of operations. Describe the strategy and explain the reasoning.").
standard_anchor(im_grade5_u5_l13, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").

standard_anchor(im_grade5_u5_l14, ccss, "5.NBT.B.7", "Add, subtract, multiply, and divide decimals to hundredths, using concrete models or drawings and strategies based on place value, properties of operations, and/or the relationship between addition and subtraction; relate the strategy to a written method and explain the reasoning used.").
standard_anchor(im_grade5_u5_l14, in_indiana, "5.CA.9", "Add, subtract, multiply, and divide decimals to hundredths, using models or drawings and strategies based on place value or the properties of operations. Describe the strategy and explain the reasoning.").
standard_anchor(im_grade5_u5_l14, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").

standard_anchor(im_grade5_u5_l15, ccss, "5.NBT.B.7", "Add, subtract, multiply, and divide decimals to hundredths, using concrete models or drawings and strategies based on place value, properties of operations, and/or the relationship between addition and subtraction; relate the strategy to a written method and explain the reasoning used.").
standard_anchor(im_grade5_u5_l15, in_indiana, "5.CA.9", "Add, subtract, multiply, and divide decimals to hundredths, using models or drawings and strategies based on place value or the properties of operations. Describe the strategy and explain the reasoning.").
standard_anchor(im_grade5_u5_l15, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").

standard_anchor(im_grade5_u5_l16, ccss, "5.NBT.B.7", "Add, subtract, multiply, and divide decimals to hundredths, using concrete models or drawings and strategies based on place value, properties of operations, and/or the relationship between addition and subtraction; relate the strategy to a written method and explain the reasoning used.").
standard_anchor(im_grade5_u5_l16, in_indiana, "5.CA.9", "Add, subtract, multiply, and divide decimals to hundredths, using models or drawings and strategies based on place value or the properties of operations. Describe the strategy and explain the reasoning.").
standard_anchor(im_grade5_u5_l16, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").

standard_anchor(im_grade5_u5_l17, ccss, "5.NBT.B.7", "Add, subtract, multiply, and divide decimals to hundredths, using concrete models or drawings and strategies based on place value, properties of operations, and/or the relationship between addition and subtraction; relate the strategy to a written method and explain the reasoning used.").
standard_anchor(im_grade5_u5_l17, in_indiana, "5.CA.9", "Add, subtract, multiply, and divide decimals to hundredths, using models or drawings and strategies based on place value or the properties of operations. Describe the strategy and explain the reasoning.").
standard_anchor(im_grade5_u5_l17, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").
standard_anchor(im_grade5_u5_l17, ccss, "5.OA.A.2", "Write simple expressions that record calculations with numbers, and interpret numerical expressions without evaluating them. *For example, express the calculation \"add 8 and 7, then multiply by 2\" as $2 \\times (8 + 7)$. Recognize that $3 \\times (18932 + 921)$ is three times as large as 18932 + 921, without having to calculate the indicated sum or product.*").

standard_anchor(im_grade5_u5_l18, ccss, "5.NBT.B.7", "Add, subtract, multiply, and divide decimals to hundredths, using concrete models or drawings and strategies based on place value, properties of operations, and/or the relationship between addition and subtraction; relate the strategy to a written method and explain the reasoning used.").
standard_anchor(im_grade5_u5_l18, in_indiana, "5.CA.9", "Add, subtract, multiply, and divide decimals to hundredths, using models or drawings and strategies based on place value or the properties of operations. Describe the strategy and explain the reasoning.").
standard_anchor(im_grade5_u5_l18, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").
standard_anchor(im_grade5_u5_l18, ccss, "5.OA.A.1", "Use parentheses, brackets, or braces in numerical expressions, and evaluate expressions with these symbols.").
standard_anchor(im_grade5_u5_l18, ccss, "5.OA.A.2", "Write simple expressions that record calculations with numbers, and interpret numerical expressions without evaluating them. *For example, express the calculation \"add 8 and 7, then multiply by 2\" as $2 \\times (8 + 7)$. Recognize that $3 \\times (18932 + 921)$ is three times as large as 18932 + 921, without having to calculate the indicated sum or product.*").

standard_anchor(im_grade5_u5_l19, ccss, "5.NBT.B.7", "Add, subtract, multiply, and divide decimals to hundredths, using concrete models or drawings and strategies based on place value, properties of operations, and/or the relationship between addition and subtraction; relate the strategy to a written method and explain the reasoning used.").
standard_anchor(im_grade5_u5_l19, in_indiana, "5.CA.9", "Add, subtract, multiply, and divide decimals to hundredths, using models or drawings and strategies based on place value or the properties of operations. Describe the strategy and explain the reasoning.").
standard_anchor(im_grade5_u5_l19, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").

standard_anchor(im_grade5_u5_l2, ccss, "5.NBT.A.3", "Read, write, and compare decimals to thousandths.").

standard_anchor(im_grade5_u5_l20, ccss, "5.NBT.B.7", "Add, subtract, multiply, and divide decimals to hundredths, using concrete models or drawings and strategies based on place value, properties of operations, and/or the relationship between addition and subtraction; relate the strategy to a written method and explain the reasoning used.").
standard_anchor(im_grade5_u5_l20, in_indiana, "5.CA.9", "Add, subtract, multiply, and divide decimals to hundredths, using models or drawings and strategies based on place value or the properties of operations. Describe the strategy and explain the reasoning.").
standard_anchor(im_grade5_u5_l20, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").
standard_anchor(im_grade5_u5_l20, ccss, "5.NF.B.4", "Apply and extend previous understandings of multiplication to multiply a fraction or whole number by a fraction.").
standard_anchor(im_grade5_u5_l20, in_indiana, "5.CA.5", "Use visual fraction models to multiply a fraction by a fraction or a whole number. (E)").

standard_anchor(im_grade5_u5_l21, ccss, "5.NBT.A.1", "Recognize that in a multi-digit number, a digit in one place represents 10 times as much as it represents in the place to its right and $\\frac{1}{10}$ of what it represents in the place to its left.").
standard_anchor(im_grade5_u5_l21, ccss, "5.NBT.B.7", "Add, subtract, multiply, and divide decimals to hundredths, using concrete models or drawings and strategies based on place value, properties of operations, and/or the relationship between addition and subtraction; relate the strategy to a written method and explain the reasoning used.").
standard_anchor(im_grade5_u5_l21, in_indiana, "5.CA.9", "Add, subtract, multiply, and divide decimals to hundredths, using models or drawings and strategies based on place value or the properties of operations. Describe the strategy and explain the reasoning.").
standard_anchor(im_grade5_u5_l21, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").

standard_anchor(im_grade5_u5_l22, ccss, "5.NBT.B.7", "Add, subtract, multiply, and divide decimals to hundredths, using concrete models or drawings and strategies based on place value, properties of operations, and/or the relationship between addition and subtraction; relate the strategy to a written method and explain the reasoning used.").
standard_anchor(im_grade5_u5_l22, in_indiana, "5.CA.9", "Add, subtract, multiply, and divide decimals to hundredths, using models or drawings and strategies based on place value or the properties of operations. Describe the strategy and explain the reasoning.").
standard_anchor(im_grade5_u5_l22, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").
standard_anchor(im_grade5_u5_l22, ccss, "5.NF.B.7", "Apply and extend previous understandings of division to divide unit fractions by whole numbers and whole numbers by unit fractions.").

standard_anchor(im_grade5_u5_l23, ccss, "5.NBT.B.7", "Add, subtract, multiply, and divide decimals to hundredths, using concrete models or drawings and strategies based on place value, properties of operations, and/or the relationship between addition and subtraction; relate the strategy to a written method and explain the reasoning used.").
standard_anchor(im_grade5_u5_l23, in_indiana, "5.CA.9", "Add, subtract, multiply, and divide decimals to hundredths, using models or drawings and strategies based on place value or the properties of operations. Describe the strategy and explain the reasoning.").
standard_anchor(im_grade5_u5_l23, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").
standard_anchor(im_grade5_u5_l23, ccss, "5.OA.A.2", "Write simple expressions that record calculations with numbers, and interpret numerical expressions without evaluating them. *For example, express the calculation \"add 8 and 7, then multiply by 2\" as $2 \\times (8 + 7)$. Recognize that $3 \\times (18932 + 921)$ is three times as large as 18932 + 921, without having to calculate the indicated sum or product.*").

standard_anchor(im_grade5_u5_l24, ccss, "5.NBT.B.7", "Add, subtract, multiply, and divide decimals to hundredths, using concrete models or drawings and strategies based on place value, properties of operations, and/or the relationship between addition and subtraction; relate the strategy to a written method and explain the reasoning used.").
standard_anchor(im_grade5_u5_l24, in_indiana, "5.CA.9", "Add, subtract, multiply, and divide decimals to hundredths, using models or drawings and strategies based on place value or the properties of operations. Describe the strategy and explain the reasoning.").
standard_anchor(im_grade5_u5_l24, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").

standard_anchor(im_grade5_u5_l25, ccss, "5.NBT.B.7", "Add, subtract, multiply, and divide decimals to hundredths, using concrete models or drawings and strategies based on place value, properties of operations, and/or the relationship between addition and subtraction; relate the strategy to a written method and explain the reasoning used.").
standard_anchor(im_grade5_u5_l25, in_indiana, "5.CA.9", "Add, subtract, multiply, and divide decimals to hundredths, using models or drawings and strategies based on place value or the properties of operations. Describe the strategy and explain the reasoning.").
standard_anchor(im_grade5_u5_l25, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").

standard_anchor(im_grade5_u5_l26, ccss, "5.NBT.B.7", "Add, subtract, multiply, and divide decimals to hundredths, using concrete models or drawings and strategies based on place value, properties of operations, and/or the relationship between addition and subtraction; relate the strategy to a written method and explain the reasoning used.").
standard_anchor(im_grade5_u5_l26, in_indiana, "5.CA.9", "Add, subtract, multiply, and divide decimals to hundredths, using models or drawings and strategies based on place value or the properties of operations. Describe the strategy and explain the reasoning.").
standard_anchor(im_grade5_u5_l26, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").

standard_anchor(im_grade5_u5_l3, ccss, "5.NBT.A.1", "Recognize that in a multi-digit number, a digit in one place represents 10 times as much as it represents in the place to its right and $\\frac{1}{10}$ of what it represents in the place to its left.").
standard_anchor(im_grade5_u5_l3, ccss, "5.NBT.A.3", "Read, write, and compare decimals to thousandths.").

standard_anchor(im_grade5_u5_l4, ccss, "5.NBT.A.1", "Recognize that in a multi-digit number, a digit in one place represents 10 times as much as it represents in the place to its right and $\\frac{1}{10}$ of what it represents in the place to its left.").
standard_anchor(im_grade5_u5_l4, ccss, "5.NBT.A.3", "Read, write, and compare decimals to thousandths.").

standard_anchor(im_grade5_u5_l5, ccss, "5.NBT.A.3", "Read, write, and compare decimals to thousandths.").

standard_anchor(im_grade5_u5_l6, ccss, "5.NBT.A.3", "Read, write, and compare decimals to thousandths.").

standard_anchor(im_grade5_u5_l7, ccss, "5.NBT.A.3", "Read, write, and compare decimals to thousandths.").
standard_anchor(im_grade5_u5_l7, ccss, "5.NBT.A.4", "Use place value understanding to round decimals to any place.").

standard_anchor(im_grade5_u5_l8, ccss, "5.NBT.A.3", "Read, write, and compare decimals to thousandths.").
standard_anchor(im_grade5_u5_l8, ccss, "5.NBT.A.4", "Use place value understanding to round decimals to any place.").

standard_anchor(im_grade5_u5_l9, ccss, "5.NBT.A.3", "Read, write, and compare decimals to thousandths.").

standard_anchor(im_grade5_u6_l1, ccss, "5.NBT.A.1", "Recognize that in a multi-digit number, a digit in one place represents 10 times as much as it represents in the place to its right and $\\frac{1}{10}$ of what it represents in the place to its left.").

standard_anchor(im_grade5_u6_l10, ccss, "5.NF.A.1", "Add and subtract fractions with unlike denominators (including mixed numbers) by replacing given fractions with equivalent fractions in such a way as to produce an equivalent sum or difference of fractions with like denominators. *For example, $\\frac{2}{3} + \\frac{5}{4} = \\frac{8}{12} + \\frac{15}{12} = \\frac{23}{12}$. (In general, $\\frac{a}{b} + \\frac{c}{d} = \\frac{(ad + bc)}{bd}$.)*").
standard_anchor(im_grade5_u6_l10, in_indiana, "5.CA.3", "Add and subtract fractions and mixed numbers with unlike denominators using strategies or the standard algorithm.").

standard_anchor(im_grade5_u6_l11, ccss, "5.NF.A.1", "Add and subtract fractions with unlike denominators (including mixed numbers) by replacing given fractions with equivalent fractions in such a way as to produce an equivalent sum or difference of fractions with like denominators. *For example, $\\frac{2}{3} + \\frac{5}{4} = \\frac{8}{12} + \\frac{15}{12} = \\frac{23}{12}$. (In general, $\\frac{a}{b} + \\frac{c}{d} = \\frac{(ad + bc)}{bd}$.)*").
standard_anchor(im_grade5_u6_l11, in_indiana, "5.CA.3", "Add and subtract fractions and mixed numbers with unlike denominators using strategies or the standard algorithm.").
standard_anchor(im_grade5_u6_l11, ccss, "5.NF.A.2", "Solve word problems involving addition and subtraction of fractions referring to the same whole, including cases of unlike denominators, e.g., by using visual fraction models or equations to represent the problem. Use benchmark fractions and number sense of fractions to estimate mentally and assess the reasonableness of answers. *For example, recognize an incorrect result $\\frac{2}{5} + \\frac{1}{2} = \\frac{3}{7}$, by observing that $\\frac{3}{7} < \\frac{1}{2}$.*").
standard_anchor(im_grade5_u6_l11, in_indiana, "5.CA.4", "Solve real-world problems involving addition and subtraction of fractions referring to the same whole, including cases of unlike denominators (e.g., by using visual fraction models and equations to represent the problem). Use benchmark fractions and number sense of fractions to estimate mentally and assess whether the answer is reasonable. (E)").
standard_anchor(im_grade5_u6_l11, in_indiana, "5.CA.7", "Solve real-world problems involving multiplication of fractions, including mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").

standard_anchor(im_grade5_u6_l12, ccss, "5.NF.A.1", "Add and subtract fractions with unlike denominators (including mixed numbers) by replacing given fractions with equivalent fractions in such a way as to produce an equivalent sum or difference of fractions with like denominators. *For example, $\\frac{2}{3} + \\frac{5}{4} = \\frac{8}{12} + \\frac{15}{12} = \\frac{23}{12}$. (In general, $\\frac{a}{b} + \\frac{c}{d} = \\frac{(ad + bc)}{bd}$.)*").
standard_anchor(im_grade5_u6_l12, in_indiana, "5.CA.3", "Add and subtract fractions and mixed numbers with unlike denominators using strategies or the standard algorithm.").
standard_anchor(im_grade5_u6_l12, ccss, "5.NF.A.2", "Solve word problems involving addition and subtraction of fractions referring to the same whole, including cases of unlike denominators, e.g., by using visual fraction models or equations to represent the problem. Use benchmark fractions and number sense of fractions to estimate mentally and assess the reasonableness of answers. *For example, recognize an incorrect result $\\frac{2}{5} + \\frac{1}{2} = \\frac{3}{7}$, by observing that $\\frac{3}{7} < \\frac{1}{2}$.*").
standard_anchor(im_grade5_u6_l12, in_indiana, "5.CA.4", "Solve real-world problems involving addition and subtraction of fractions referring to the same whole, including cases of unlike denominators (e.g., by using visual fraction models and equations to represent the problem). Use benchmark fractions and number sense of fractions to estimate mentally and assess whether the answer is reasonable. (E)").
standard_anchor(im_grade5_u6_l12, in_indiana, "5.CA.7", "Solve real-world problems involving multiplication of fractions, including mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").

standard_anchor(im_grade5_u6_l13, ccss, "5.NF.A.1", "Add and subtract fractions with unlike denominators (including mixed numbers) by replacing given fractions with equivalent fractions in such a way as to produce an equivalent sum or difference of fractions with like denominators. *For example, $\\frac{2}{3} + \\frac{5}{4} = \\frac{8}{12} + \\frac{15}{12} = \\frac{23}{12}$. (In general, $\\frac{a}{b} + \\frac{c}{d} = \\frac{(ad + bc)}{bd}$.)*").
standard_anchor(im_grade5_u6_l13, in_indiana, "5.CA.3", "Add and subtract fractions and mixed numbers with unlike denominators using strategies or the standard algorithm.").

standard_anchor(im_grade5_u6_l14, ccss, "5.MD.B.2", "Make a line plot to display a data set of measurements in fractions of a unit ($\\frac{1}{2}$, $\\frac{1}{4}$, $\\frac{1}{8}$). Use operations on fractions for this grade to solve problems involving information presented in line plots. *For example, given different measurements of liquid in identical beakers, find the amount of liquid each beaker would contain if the total amount in all the beakers were redistributed equally.*").
standard_anchor(im_grade5_u6_l14, ccss, "5.NF.A.1", "Add and subtract fractions with unlike denominators (including mixed numbers) by replacing given fractions with equivalent fractions in such a way as to produce an equivalent sum or difference of fractions with like denominators. *For example, $\\frac{2}{3} + \\frac{5}{4} = \\frac{8}{12} + \\frac{15}{12} = \\frac{23}{12}$. (In general, $\\frac{a}{b} + \\frac{c}{d} = \\frac{(ad + bc)}{bd}$.)*").
standard_anchor(im_grade5_u6_l14, in_indiana, "5.CA.3", "Add and subtract fractions and mixed numbers with unlike denominators using strategies or the standard algorithm.").

standard_anchor(im_grade5_u6_l15, ccss, "5.MD.B.2", "Make a line plot to display a data set of measurements in fractions of a unit ($\\frac{1}{2}$, $\\frac{1}{4}$, $\\frac{1}{8}$). Use operations on fractions for this grade to solve problems involving information presented in line plots. *For example, given different measurements of liquid in identical beakers, find the amount of liquid each beaker would contain if the total amount in all the beakers were redistributed equally.*").
standard_anchor(im_grade5_u6_l15, ccss, "5.NF.A.2", "Solve word problems involving addition and subtraction of fractions referring to the same whole, including cases of unlike denominators, e.g., by using visual fraction models or equations to represent the problem. Use benchmark fractions and number sense of fractions to estimate mentally and assess the reasonableness of answers. *For example, recognize an incorrect result $\\frac{2}{5} + \\frac{1}{2} = \\frac{3}{7}$, by observing that $\\frac{3}{7} < \\frac{1}{2}$.*").
standard_anchor(im_grade5_u6_l15, in_indiana, "5.CA.4", "Solve real-world problems involving addition and subtraction of fractions referring to the same whole, including cases of unlike denominators (e.g., by using visual fraction models and equations to represent the problem). Use benchmark fractions and number sense of fractions to estimate mentally and assess whether the answer is reasonable. (E)").
standard_anchor(im_grade5_u6_l15, in_indiana, "5.CA.7", "Solve real-world problems involving multiplication of fractions, including mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").
standard_anchor(im_grade5_u6_l15, ccss, "5.NF.B.4", "Apply and extend previous understandings of multiplication to multiply a fraction or whole number by a fraction.").
standard_anchor(im_grade5_u6_l15, in_indiana, "5.CA.5", "Use visual fraction models to multiply a fraction by a fraction or a whole number. (E)").

standard_anchor(im_grade5_u6_l16, ccss, "5.NF.B.5", "Interpret multiplication as scaling (resizing), by:").

standard_anchor(im_grade5_u6_l17, ccss, "5.NF.B.5", "Interpret multiplication as scaling (resizing), by:").

standard_anchor(im_grade5_u6_l18, ccss, "5.NF.B.5", "Interpret multiplication as scaling (resizing), by:").

standard_anchor(im_grade5_u6_l19, ccss, "5.NF.B.5", "Interpret multiplication as scaling (resizing), by:").

standard_anchor(im_grade5_u6_l2, ccss, "5.NBT.A.1", "Recognize that in a multi-digit number, a digit in one place represents 10 times as much as it represents in the place to its right and $\\frac{1}{10}$ of what it represents in the place to its left.").
standard_anchor(im_grade5_u6_l2, ccss, "5.NBT.A.2", "Explain patterns in the number of zeros of the product when multiplying a number by powers of 10, and explain patterns in the placement of the decimal point when a decimal is multiplied or divided by a power of 10. Use whole-number exponents to denote powers of 10.").
standard_anchor(im_grade5_u6_l2, in_indiana, "5.NS.3", "Explain patterns in the number of zeros of the product when multiplying a number by powers of 10, and explain patterns in the placement of the decimal point when a decimal is multiplied or divided by a power of 10. Use whole-number exponents to denote powers of 10.").

standard_anchor(im_grade5_u6_l20, ccss, "5.NF.B.5", "Interpret multiplication as scaling (resizing), by:").
standard_anchor(im_grade5_u6_l20, ccss, "5.OA.A.1", "Use parentheses, brackets, or braces in numerical expressions, and evaluate expressions with these symbols.").

standard_anchor(im_grade5_u6_l21, ccss, "5.MD.B.2", "Make a line plot to display a data set of measurements in fractions of a unit ($\\frac{1}{2}$, $\\frac{1}{4}$, $\\frac{1}{8}$). Use operations on fractions for this grade to solve problems involving information presented in line plots. *For example, given different measurements of liquid in identical beakers, find the amount of liquid each beaker would contain if the total amount in all the beakers were redistributed equally.*").
standard_anchor(im_grade5_u6_l21, ccss, "5.NF.A.2", "Solve word problems involving addition and subtraction of fractions referring to the same whole, including cases of unlike denominators, e.g., by using visual fraction models or equations to represent the problem. Use benchmark fractions and number sense of fractions to estimate mentally and assess the reasonableness of answers. *For example, recognize an incorrect result $\\frac{2}{5} + \\frac{1}{2} = \\frac{3}{7}$, by observing that $\\frac{3}{7} < \\frac{1}{2}$.*").
standard_anchor(im_grade5_u6_l21, in_indiana, "5.CA.4", "Solve real-world problems involving addition and subtraction of fractions referring to the same whole, including cases of unlike denominators (e.g., by using visual fraction models and equations to represent the problem). Use benchmark fractions and number sense of fractions to estimate mentally and assess whether the answer is reasonable. (E)").
standard_anchor(im_grade5_u6_l21, in_indiana, "5.CA.7", "Solve real-world problems involving multiplication of fractions, including mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").
standard_anchor(im_grade5_u6_l21, ccss, "5.NF.B.4", "Apply and extend previous understandings of multiplication to multiply a fraction or whole number by a fraction.").
standard_anchor(im_grade5_u6_l21, in_indiana, "5.CA.5", "Use visual fraction models to multiply a fraction by a fraction or a whole number. (E)").

standard_anchor(im_grade5_u6_l3, ccss, "5.MD.A.1", "Convert among different-sized standard measurement units within a given measurement system (e.g., convert 5 cm to 0.05 m), and use these conversions in solving multi-step, real world problems.").
standard_anchor(im_grade5_u6_l3, ccss, "5.NBT.A.2", "Explain patterns in the number of zeros of the product when multiplying a number by powers of 10, and explain patterns in the placement of the decimal point when a decimal is multiplied or divided by a power of 10. Use whole-number exponents to denote powers of 10.").
standard_anchor(im_grade5_u6_l3, in_indiana, "5.NS.3", "Explain patterns in the number of zeros of the product when multiplying a number by powers of 10, and explain patterns in the placement of the decimal point when a decimal is multiplied or divided by a power of 10. Use whole-number exponents to denote powers of 10.").

standard_anchor(im_grade5_u6_l4, ccss, "5.MD.A.1", "Convert among different-sized standard measurement units within a given measurement system (e.g., convert 5 cm to 0.05 m), and use these conversions in solving multi-step, real world problems.").
standard_anchor(im_grade5_u6_l4, ccss, "5.NBT.A.2", "Explain patterns in the number of zeros of the product when multiplying a number by powers of 10, and explain patterns in the placement of the decimal point when a decimal is multiplied or divided by a power of 10. Use whole-number exponents to denote powers of 10.").
standard_anchor(im_grade5_u6_l4, in_indiana, "5.NS.3", "Explain patterns in the number of zeros of the product when multiplying a number by powers of 10, and explain patterns in the placement of the decimal point when a decimal is multiplied or divided by a power of 10. Use whole-number exponents to denote powers of 10.").

standard_anchor(im_grade5_u6_l5, ccss, "5.MD.A.1", "Convert among different-sized standard measurement units within a given measurement system (e.g., convert 5 cm to 0.05 m), and use these conversions in solving multi-step, real world problems.").
standard_anchor(im_grade5_u6_l5, ccss, "5.NBT.A.1", "Recognize that in a multi-digit number, a digit in one place represents 10 times as much as it represents in the place to its right and $\\frac{1}{10}$ of what it represents in the place to its left.").

standard_anchor(im_grade5_u6_l6, ccss, "5.MD.A.1", "Convert among different-sized standard measurement units within a given measurement system (e.g., convert 5 cm to 0.05 m), and use these conversions in solving multi-step, real world problems.").
standard_anchor(im_grade5_u6_l6, ccss, "5.NBT.A.1", "Recognize that in a multi-digit number, a digit in one place represents 10 times as much as it represents in the place to its right and $\\frac{1}{10}$ of what it represents in the place to its left.").
standard_anchor(im_grade5_u6_l6, ccss, "5.NBT.A.2", "Explain patterns in the number of zeros of the product when multiplying a number by powers of 10, and explain patterns in the placement of the decimal point when a decimal is multiplied or divided by a power of 10. Use whole-number exponents to denote powers of 10.").
standard_anchor(im_grade5_u6_l6, in_indiana, "5.NS.3", "Explain patterns in the number of zeros of the product when multiplying a number by powers of 10, and explain patterns in the placement of the decimal point when a decimal is multiplied or divided by a power of 10. Use whole-number exponents to denote powers of 10.").

standard_anchor(im_grade5_u6_l7, ccss, "5.MD.A.1", "Convert among different-sized standard measurement units within a given measurement system (e.g., convert 5 cm to 0.05 m), and use these conversions in solving multi-step, real world problems.").

standard_anchor(im_grade5_u6_l8, ccss, "5.NF.A.1", "Add and subtract fractions with unlike denominators (including mixed numbers) by replacing given fractions with equivalent fractions in such a way as to produce an equivalent sum or difference of fractions with like denominators. *For example, $\\frac{2}{3} + \\frac{5}{4} = \\frac{8}{12} + \\frac{15}{12} = \\frac{23}{12}$. (In general, $\\frac{a}{b} + \\frac{c}{d} = \\frac{(ad + bc)}{bd}$.)*").
standard_anchor(im_grade5_u6_l8, in_indiana, "5.CA.3", "Add and subtract fractions and mixed numbers with unlike denominators using strategies or the standard algorithm.").

standard_anchor(im_grade5_u6_l9, ccss, "5.NF.A.1", "Add and subtract fractions with unlike denominators (including mixed numbers) by replacing given fractions with equivalent fractions in such a way as to produce an equivalent sum or difference of fractions with like denominators. *For example, $\\frac{2}{3} + \\frac{5}{4} = \\frac{8}{12} + \\frac{15}{12} = \\frac{23}{12}$. (In general, $\\frac{a}{b} + \\frac{c}{d} = \\frac{(ad + bc)}{bd}$.)*").
standard_anchor(im_grade5_u6_l9, in_indiana, "5.CA.3", "Add and subtract fractions and mixed numbers with unlike denominators using strategies or the standard algorithm.").
standard_anchor(im_grade5_u6_l9, ccss, "5.NF.A.2", "Solve word problems involving addition and subtraction of fractions referring to the same whole, including cases of unlike denominators, e.g., by using visual fraction models or equations to represent the problem. Use benchmark fractions and number sense of fractions to estimate mentally and assess the reasonableness of answers. *For example, recognize an incorrect result $\\frac{2}{5} + \\frac{1}{2} = \\frac{3}{7}$, by observing that $\\frac{3}{7} < \\frac{1}{2}$.*").
standard_anchor(im_grade5_u6_l9, in_indiana, "5.CA.4", "Solve real-world problems involving addition and subtraction of fractions referring to the same whole, including cases of unlike denominators (e.g., by using visual fraction models and equations to represent the problem). Use benchmark fractions and number sense of fractions to estimate mentally and assess whether the answer is reasonable. (E)").
standard_anchor(im_grade5_u6_l9, in_indiana, "5.CA.7", "Solve real-world problems involving multiplication of fractions, including mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").

standard_anchor(im_grade5_u7_l1, ccss, "5.G.A.1", "Use a pair of perpendicular number lines, called axes, to define a coordinate system, with the intersection of the lines (the origin) arranged to coincide with the 0 on each line and a given point in the plane located by using an ordered pair of numbers, called its coordinates. Understand that the first number indicates how far to travel from the origin in the direction of one axis, and the second number indicates how far to travel in the direction of the second axis, with the convention that the names of the two axes and the coordinates correspond (e.g., x-axis and x-coordinate, y-axis and y-coordinate).").

standard_anchor(im_grade5_u7_l10, ccss, "5.OA.B.3", "Generate two numerical patterns using two given rules. Identify apparent relationships between corresponding terms. Form ordered pairs consisting of corresponding terms from the two patterns, and graph the ordered pairs on a coordinate plane. *For example, given the rule \"Add 3\" and the starting number 0, and given the rule \"Add 6\" and the starting number 0, generate terms in the resulting sequences, and observe that the terms in one sequence are twice the corresponding terms in the other sequence. Explain informally why this is so.*").

standard_anchor(im_grade5_u7_l11, ccss, "5.G.A.1", "Use a pair of perpendicular number lines, called axes, to define a coordinate system, with the intersection of the lines (the origin) arranged to coincide with the 0 on each line and a given point in the plane located by using an ordered pair of numbers, called its coordinates. Understand that the first number indicates how far to travel from the origin in the direction of one axis, and the second number indicates how far to travel in the direction of the second axis, with the convention that the names of the two axes and the coordinates correspond (e.g., x-axis and x-coordinate, y-axis and y-coordinate).").
standard_anchor(im_grade5_u7_l11, ccss, "5.OA.B.3", "Generate two numerical patterns using two given rules. Identify apparent relationships between corresponding terms. Form ordered pairs consisting of corresponding terms from the two patterns, and graph the ordered pairs on a coordinate plane. *For example, given the rule \"Add 3\" and the starting number 0, and given the rule \"Add 6\" and the starting number 0, generate terms in the resulting sequences, and observe that the terms in one sequence are twice the corresponding terms in the other sequence. Explain informally why this is so.*").

standard_anchor(im_grade5_u7_l12, ccss, "5.G.A.2", "Represent real world and mathematical problems by graphing points in the first quadrant of the coordinate plane, and interpret coordinate values of points in the context of the situation.").
standard_anchor(im_grade5_u7_l12, in_indiana, "5.CA.11", "Represent real-world problems and equations by graphing ordered pairs in the first quadrant of the coor").
standard_anchor(im_grade5_u7_l12, ccss, "5.OA.A.2", "Write simple expressions that record calculations with numbers, and interpret numerical expressions without evaluating them. *For example, express the calculation \"add 8 and 7, then multiply by 2\" as $2 \\times (8 + 7)$. Recognize that $3 \\times (18932 + 921)$ is three times as large as 18932 + 921, without having to calculate the indicated sum or product.*").

standard_anchor(im_grade5_u7_l13, ccss, "5.G.A.2", "Represent real world and mathematical problems by graphing points in the first quadrant of the coordinate plane, and interpret coordinate values of points in the context of the situation.").
standard_anchor(im_grade5_u7_l13, in_indiana, "5.CA.11", "Represent real-world problems and equations by graphing ordered pairs in the first quadrant of the coor").
standard_anchor(im_grade5_u7_l13, ccss, "5.NBT.B.7", "Add, subtract, multiply, and divide decimals to hundredths, using concrete models or drawings and strategies based on place value, properties of operations, and/or the relationship between addition and subtraction; relate the strategy to a written method and explain the reasoning used.").
standard_anchor(im_grade5_u7_l13, in_indiana, "5.CA.9", "Add, subtract, multiply, and divide decimals to hundredths, using models or drawings and strategies based on place value or the properties of operations. Describe the strategy and explain the reasoning.").
standard_anchor(im_grade5_u7_l13, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").

standard_anchor(im_grade5_u7_l14, ccss, "5.G.A.2", "Represent real world and mathematical problems by graphing points in the first quadrant of the coordinate plane, and interpret coordinate values of points in the context of the situation.").
standard_anchor(im_grade5_u7_l14, in_indiana, "5.CA.11", "Represent real-world problems and equations by graphing ordered pairs in the first quadrant of the coor").

standard_anchor(im_grade5_u7_l2, ccss, "5.G.A.1", "Use a pair of perpendicular number lines, called axes, to define a coordinate system, with the intersection of the lines (the origin) arranged to coincide with the 0 on each line and a given point in the plane located by using an ordered pair of numbers, called its coordinates. Understand that the first number indicates how far to travel from the origin in the direction of one axis, and the second number indicates how far to travel in the direction of the second axis, with the convention that the names of the two axes and the coordinates correspond (e.g., x-axis and x-coordinate, y-axis and y-coordinate).").

standard_anchor(im_grade5_u7_l3, ccss, "5.G.A.1", "Use a pair of perpendicular number lines, called axes, to define a coordinate system, with the intersection of the lines (the origin) arranged to coincide with the 0 on each line and a given point in the plane located by using an ordered pair of numbers, called its coordinates. Understand that the first number indicates how far to travel from the origin in the direction of one axis, and the second number indicates how far to travel in the direction of the second axis, with the convention that the names of the two axes and the coordinates correspond (e.g., x-axis and x-coordinate, y-axis and y-coordinate).").

standard_anchor(im_grade5_u7_l4, ccss, "5.G.B.3", "Understand that attributes belonging to a category of two-dimensional figures also belong to all subcategories of that category. *For example, all rectangles have four right angles and squares are rectangles, so all squares have four right angles.*").
standard_anchor(im_grade5_u7_l4, ccss, "5.G.B.4", "Classify two-dimensional figures in a hierarchy based on properties.").

standard_anchor(im_grade5_u7_l5, ccss, "5.G.B.4", "Classify two-dimensional figures in a hierarchy based on properties.").

standard_anchor(im_grade5_u7_l6, ccss, "5.G.B.3", "Understand that attributes belonging to a category of two-dimensional figures also belong to all subcategories of that category. *For example, all rectangles have four right angles and squares are rectangles, so all squares have four right angles.*").
standard_anchor(im_grade5_u7_l6, ccss, "5.G.B.4", "Classify two-dimensional figures in a hierarchy based on properties.").

standard_anchor(im_grade5_u7_l7, ccss, "5.G.B.3", "Understand that attributes belonging to a category of two-dimensional figures also belong to all subcategories of that category. *For example, all rectangles have four right angles and squares are rectangles, so all squares have four right angles.*").
standard_anchor(im_grade5_u7_l7, ccss, "5.G.B.4", "Classify two-dimensional figures in a hierarchy based on properties.").

standard_anchor(im_grade5_u7_l8, ccss, "5.G.B.3", "Understand that attributes belonging to a category of two-dimensional figures also belong to all subcategories of that category. *For example, all rectangles have four right angles and squares are rectangles, so all squares have four right angles.*").
standard_anchor(im_grade5_u7_l8, ccss, "5.G.B.4", "Classify two-dimensional figures in a hierarchy based on properties.").

standard_anchor(im_grade5_u7_l9, ccss, "5.OA.B.3", "Generate two numerical patterns using two given rules. Identify apparent relationships between corresponding terms. Form ordered pairs consisting of corresponding terms from the two patterns, and graph the ordered pairs on a coordinate plane. *For example, given the rule \"Add 3\" and the starting number 0, and given the rule \"Add 6\" and the starting number 0, generate terms in the resulting sequences, and observe that the terms in one sequence are twice the corresponding terms in the other sequence. Explain informally why this is so.*").

standard_anchor(im_grade5_u8_l1, ccss, "5.NBT.B.5", "Fluently multiply multi-digit whole numbers using the standard algorithm.").

standard_anchor(im_grade5_u8_l10, ccss, "5.NF.A.1", "Add and subtract fractions with unlike denominators (including mixed numbers) by replacing given fractions with equivalent fractions in such a way as to produce an equivalent sum or difference of fractions with like denominators. *For example, $\\frac{2}{3} + \\frac{5}{4} = \\frac{8}{12} + \\frac{15}{12} = \\frac{23}{12}$. (In general, $\\frac{a}{b} + \\frac{c}{d} = \\frac{(ad + bc)}{bd}$.)*").
standard_anchor(im_grade5_u8_l10, in_indiana, "5.CA.3", "Add and subtract fractions and mixed numbers with unlike denominators using strategies or the standard algorithm.").

standard_anchor(im_grade5_u8_l11, ccss, "5.NF.A.1", "Add and subtract fractions with unlike denominators (including mixed numbers) by replacing given fractions with equivalent fractions in such a way as to produce an equivalent sum or difference of fractions with like denominators. *For example, $\\frac{2}{3} + \\frac{5}{4} = \\frac{8}{12} + \\frac{15}{12} = \\frac{23}{12}$. (In general, $\\frac{a}{b} + \\frac{c}{d} = \\frac{(ad + bc)}{bd}$.)*").
standard_anchor(im_grade5_u8_l11, in_indiana, "5.CA.3", "Add and subtract fractions and mixed numbers with unlike denominators using strategies or the standard algorithm.").

standard_anchor(im_grade5_u8_l12, ccss, "5.NBT.B.7", "Add, subtract, multiply, and divide decimals to hundredths, using concrete models or drawings and strategies based on place value, properties of operations, and/or the relationship between addition and subtraction; relate the strategy to a written method and explain the reasoning used.").
standard_anchor(im_grade5_u8_l12, in_indiana, "5.CA.9", "Add, subtract, multiply, and divide decimals to hundredths, using models or drawings and strategies based on place value or the properties of operations. Describe the strategy and explain the reasoning.").
standard_anchor(im_grade5_u8_l12, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").

standard_anchor(im_grade5_u8_l13, ccss, "5.NF.B.4", "Apply and extend previous understandings of multiplication to multiply a fraction or whole number by a fraction.").
standard_anchor(im_grade5_u8_l13, in_indiana, "5.CA.5", "Use visual fraction models to multiply a fraction by a fraction or a whole number. (E)").

standard_anchor(im_grade5_u8_l14, ccss, "5.NF.B.3", "Interpret a fraction as division of the numerator by the denominator ($\\frac{a}{b} = a \\div b$). Solve word problems involving division of whole numbers leading to answers in the form of fractions or mixed numbers, e.g., by using visual fraction models or equations to represent the problem. *For example, interpret $\\frac{3}{4}$ as the result of dividing 3 by 4, noting that $\\frac{3}{4}$ multiplied by 4 equals 3, and that when 3 wholes are shared equally among 4 people each person has a share of size $\\frac{3}{4}$. If 9 people want to share a 50-pound sack of rice equally by weight, how many pounds of rice should each person get? Between what two whole numbers does your answer lie?*").

standard_anchor(im_grade5_u8_l15, ccss, "5.NBT.B.5", "Fluently multiply multi-digit whole numbers using the standard algorithm.").

standard_anchor(im_grade5_u8_l16, ccss, "5.NBT.B.6", "Find whole-number quotients of whole numbers with up to four-digit dividends and two-digit divisors, using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Illustrate and explain the calculation by using equations, rectangular arrays, and/or area models.").
standard_anchor(im_grade5_u8_l16, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").

standard_anchor(im_grade5_u8_l17, ccss, "5.NF.A.1", "Add and subtract fractions with unlike denominators (including mixed numbers) by replacing given fractions with equivalent fractions in such a way as to produce an equivalent sum or difference of fractions with like denominators. *For example, $\\frac{2}{3} + \\frac{5}{4} = \\frac{8}{12} + \\frac{15}{12} = \\frac{23}{12}$. (In general, $\\frac{a}{b} + \\frac{c}{d} = \\frac{(ad + bc)}{bd}$.)*").
standard_anchor(im_grade5_u8_l17, in_indiana, "5.CA.3", "Add and subtract fractions and mixed numbers with unlike denominators using strategies or the standard algorithm.").

standard_anchor(im_grade5_u8_l18, ccss, "5.MD.C.3", "Recognize volume as an attribute of solid figures and understand concepts of volume measurement.").

standard_anchor(im_grade5_u8_l2, ccss, "5.NBT.B.5", "Fluently multiply multi-digit whole numbers using the standard algorithm.").

standard_anchor(im_grade5_u8_l3, ccss, "5.NBT.B.5", "Fluently multiply multi-digit whole numbers using the standard algorithm.").

standard_anchor(im_grade5_u8_l4, ccss, "5.G.B.3", "Understand that attributes belonging to a category of two-dimensional figures also belong to all subcategories of that category. *For example, all rectangles have four right angles and squares are rectangles, so all squares have four right angles.*").
standard_anchor(im_grade5_u8_l4, ccss, "5.G.B.4", "Classify two-dimensional figures in a hierarchy based on properties.").
standard_anchor(im_grade5_u8_l4, ccss, "5.NBT.B.6", "Find whole-number quotients of whole numbers with up to four-digit dividends and two-digit divisors, using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Illustrate and explain the calculation by using equations, rectangular arrays, and/or area models.").
standard_anchor(im_grade5_u8_l4, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").

standard_anchor(im_grade5_u8_l5, ccss, "5.NBT.B.6", "Find whole-number quotients of whole numbers with up to four-digit dividends and two-digit divisors, using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Illustrate and explain the calculation by using equations, rectangular arrays, and/or area models.").
standard_anchor(im_grade5_u8_l5, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").

standard_anchor(im_grade5_u8_l6, ccss, "5.MD.C.5", "Relate volume to the operations of multiplication and addition and solve real world and mathematical problems involving volume.").
standard_anchor(im_grade5_u8_l6, in_indiana, "5.CA.7", "Solve real-world problems involving multiplication of fractions, including mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").

standard_anchor(im_grade5_u8_l7, ccss, "5.MD.C.5", "Relate volume to the operations of multiplication and addition and solve real world and mathematical problems involving volume.").
standard_anchor(im_grade5_u8_l7, in_indiana, "5.CA.7", "Solve real-world problems involving multiplication of fractions, including mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").
standard_anchor(im_grade5_u8_l7, ccss, "5.NBT.B.5", "Fluently multiply multi-digit whole numbers using the standard algorithm.").

standard_anchor(im_grade5_u8_l8, ccss, "5.MD.C.5", "Relate volume to the operations of multiplication and addition and solve real world and mathematical problems involving volume.").
standard_anchor(im_grade5_u8_l8, in_indiana, "5.CA.7", "Solve real-world problems involving multiplication of fractions, including mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").
standard_anchor(im_grade5_u8_l8, ccss, "5.NBT.B.5", "Fluently multiply multi-digit whole numbers using the standard algorithm.").
standard_anchor(im_grade5_u8_l8, ccss, "5.NBT.B.6", "Find whole-number quotients of whole numbers with up to four-digit dividends and two-digit divisors, using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Illustrate and explain the calculation by using equations, rectangular arrays, and/or area models.").
standard_anchor(im_grade5_u8_l8, in_indiana, "5.CA.1", "Find whole-number quotients and remainders with up to four-digit dividends and two-digit divisors using strategies based on place value, the properties of operations, and/or the relationship between multiplication and division. Describe the strategy and explain the reasoning used. (E)").

standard_anchor(im_grade5_u8_l9, ccss, "5.MD.C.5", "Relate volume to the operations of multiplication and addition and solve real world and mathematical problems involving volume.").
standard_anchor(im_grade5_u8_l9, in_indiana, "5.CA.7", "Solve real-world problems involving multiplication of fractions, including mixed numbers (e.g., by using visual fraction models and equations to represent the problem). (E)").
