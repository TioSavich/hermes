/** <module> grind_boundary: reason-tagged residue of the grade 6-7 arithmetic units
 *
 * PURPOSE: Phase 5 boundary closure. After the explicit division / fraction /
 * decimal mappings in lessons/im/grade_6.pl and lessons/im/grade_7.pl, some
 * lessons in the three grade 6-7 arithmetic units stay on
 * scope_sequence_only_lesson/1:
 *
 *   G6-U4  Dividing Fractions
 *   G6-U5  Arithmetic in Base Ten
 *   G7-U5  Rational Number Arithmetic
 *
 * This module names WHY each still-unmapped lesson stays unmapped, exactly one
 * reason per lesson, so the residue is queryable instead of silent. It maps no
 * lesson onto an automaton and asserts no task event; it records a boundary the
 * mapped system reaches. Every reason is a claim about the model's coverage of
 * the curriculum, never a claim about children.
 *
 *   grind_boundary(LessonCode, Reason)
 *
 * Reason is drawn from a fixed taxonomy:
 *
 *   needs_pair(signed_multiplication)  a signed-number multiplication lesson whose
 *   needs_pair(signed_division)        matching action pair the registry does not
 *                                      carry. Building one is a new FSM/scene
 *                                      family, a stop-and-report under the
 *                                      wrapper-only constraint, not a mapping.
 *   precursor_no_enacted_demand        an interpretive or representational lesson
 *                                      that sets up an operation (reading numbers,
 *                                      choosing a diagram) without demanding an
 *                                      enactable calculation of its own.
 *   geometry_measurement_blend         the arithmetic is carried inside a length /
 *                                      area / volume measurement task; the operative
 *                                      demand is geometric and lives in the geometry
 *                                      lane, not the arithmetic automata.
 *   application_of_mapped_operations   a multi-step application / problem-solving
 *                                      lesson that reuses operations already mapped
 *                                      elsewhere in its unit; it adds no new demand
 *                                      the mapped automata do not already cover.
 *   algebra_scope                      the lesson's demand is writing, solving, or
 *                                      interpreting expressions and equations -- an
 *                                      algebra obligation, not an arithmetic one.
 *
 * Lesson titles below are from geometry/corpus/im_scope_and_sequence/grade{6,7}.md.
 */
:- module(grind_boundary,
          [ grind_boundary/2,
            grind_boundary_unit_prefix/1
          ]).

%!  grind_boundary_unit_prefix(?Prefix) is nondet.
%
%   The three grade 6-7 arithmetic units this module accounts for. A test can
%   read these prefixes to check that every scope_sequence_only lesson in each
%   unit carries exactly one grind_boundary/2 reason.
grind_boundary_unit_prefix('IM-G6-U4-L').
grind_boundary_unit_prefix('IM-G6-U5-L').
grind_boundary_unit_prefix('IM-G7-U5-L').

% ---- G6-U4 Dividing Fractions -------------------------------------------
% L2, L3 (both division-interpretation automata) and L13 (area_model_part_of_part)
% are mapped in grade_6.pl; the rest of the unit stays here.
grind_boundary('IM-G6-U4-L1',  precursor_no_enacted_demand).       % Size of Divisor and Size of Quotient
grind_boundary('IM-G6-U4-L12', application_of_mapped_operations).  % Fractional Lengths
grind_boundary('IM-G6-U4-L14', geometry_measurement_blend).        % Fractional Lengths in Triangles and Prisms
grind_boundary('IM-G6-U4-L15', geometry_measurement_blend).        % Volume of Prisms
grind_boundary('IM-G6-U4-L16', application_of_mapped_operations).  % Solving Problems Involving Fractions
grind_boundary('IM-G6-U4-L17', geometry_measurement_blend).        % Fitting Boxes into Boxes

% ---- G6-U5 Arithmetic in Base Ten ---------------------------------------
% L1-L4 (decimal add/sub aligned-units) plus the multiplication and division
% lessons already mapped in grade_6.pl leave this residue.
grind_boundary('IM-G6-U5-L5',  precursor_no_enacted_demand).       % Using Fractions to Multiply Decimals
grind_boundary('IM-G6-U5-L7',  precursor_no_enacted_demand).       % Using Diagrams to Represent Multiplication
grind_boundary('IM-G6-U5-L9',  precursor_no_enacted_demand).       % Using Base-Ten Diagrams to Divide
grind_boundary('IM-G6-U5-L14', application_of_mapped_operations).  % Solving Problems Involving Decimals
grind_boundary('IM-G6-U5-L15', geometry_measurement_blend).        % Making and Measuring Boxes

% ---- G7-U5 Rational Number Arithmetic -----------------------------------
% L2-L7 (signed addition/subtraction) are mapped in grade_7.pl; the residue is
% the signed multiplication/division lessons the registry has no pair for, the
% opening interpretive lesson, the equation/expression lessons, and the applied
% problem-solving lesson.
grind_boundary('IM-G7-U5-L1',  precursor_no_enacted_demand).       % Interpreting Negative Numbers
grind_boundary('IM-G7-U5-L8',  needs_pair(signed_multiplication)). % Multiplying Rational Numbers (Part 1)
grind_boundary('IM-G7-U5-L9',  needs_pair(signed_multiplication)). % Multiplying Rational Numbers (Part 2)
grind_boundary('IM-G7-U5-L10', needs_pair(signed_multiplication)). % Multiply!
grind_boundary('IM-G7-U5-L11', needs_pair(signed_division)).       % Dividing Rational Numbers
grind_boundary('IM-G7-U5-L12', needs_pair(signed_division)).       % Negative Rates
grind_boundary('IM-G7-U5-L13', algebra_scope).                     % Expressions with Rational Numbers
grind_boundary('IM-G7-U5-L14', application_of_mapped_operations).  % Solving Problems with Rational Numbers
grind_boundary('IM-G7-U5-L15', algebra_scope).                     % Solving Equations with Rational Numbers
grind_boundary('IM-G7-U5-L16', algebra_scope).                     % Representing Contexts with Equations
grind_boundary('IM-G7-U5-L17', algebra_scope).                     % The Stock Market
