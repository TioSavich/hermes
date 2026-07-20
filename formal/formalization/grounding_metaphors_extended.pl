/** <module> Lakoff & Núñez grounding metaphors — extensions beyond arithmetic
 *
 * STAGED FOR REVIEW (2026-05-24, L&N steward run). This module
 * extends `grounding_metaphors.pl` along the lines L&N argue for in
 * *Where Mathematics Comes From* (2000) beyond the four basic
 * arithmetic grounding metaphors plus repairs. The arithmetic table
 * remains in `grounding_metaphors.pl` and is not edited here.
 *
 * What this module adds:
 *
 *   1. The Fundamental Metonymy of Algebra (Ch. 3) and the family of
 *      Algebraic Essence (AE) metaphors (Ch. 5) that bridge arithmetic
 *      to abstract algebra.
 *   2. The Basic Metaphor of Infinity (BMI) (Ch. 8) as the master
 *      metaphor for actual infinity, plus selected specializations
 *      (limits of sequences, mathematical induction, infinite sets of
 *      naturals, points at infinity in projective geometry, least
 *      upper bounds, infinitesimals, transfinite cardinals/ordinals).
 *   3. Calculus-grounding metaphors (Chs. 11, 14, Case Study 2):
 *      Numbers Are Points on a Line; Instantaneous Change Is Average
 *      Change Over an Infinitely Small Interval; Tangent Is the Limit
 *      of Secants (Newton); Functions Are Curves (Descartes);
 *      Functions Are Sets of Ordered Pairs (Weierstrass);
 *      Weierstrass's Continuity Metaphor (preservation of closeness).
 *   4. The discretization metaphors (Ch. 12): A Space Is a Set of
 *      Points and the Space-Set Blend.
 *   5. Set-theoretic / logical grounding metaphors (Chs. 6, 7):
 *      Classes Are Containers, Boole's Metaphor, the Propositional
 *      Logic Metaphor, Sets Are Objects, Cantor's Metaphor (Same
 *      Number As Is Pairability), Sets Are Graphs (Aczel's hypersets).
 *
 * Citation atoms follow `ln_chN[_pNNN]` per
 * `geometry/metaphors/lakoff_nunez_inventory.pl`. Pages are recorded
 * where the NotebookLM response surfaced them; otherwise chapter only.
 *
 * Heroic-register note: L&N name specific embodied groundings the
 * project can model. The codebase makes those groundings queryable.
 * It does NOT claim L&N's framework "explains" cognition or that
 * encoding a mapping is the same as instantiating the concept.
 *
 * Hard constraints honored:
 *   - No Prolog-native arithmetic. This module only registers facts.
 *   - No silent edits to the basic-four arithmetic table.
 *   - All entries below have NotebookLM textual support; entries
 *     without explicit page-anchored support are flagged
 *     `candidate_unconfirmed` in their citation list and named in the
 *     open-questions section of the audit report.
 */

:- module(grounding_metaphors_extended,
          [ ln_metaphor/4,
            ln_metaphor_mapping/4,
            ln_metaphor_breaks_at/3,
            ln_metaphor_repair/4,
            ln_metaphor_target_practice/2,
            ln_bmi_specialization/3,
            ln_metaphor_citation/2,
            ln_metaphor_kind/2
          ]).


%% ----------------------------------------------------------------------
%% Extension metaphor definitions
%%
%% Mirrors `grounding_metaphor_definition/4` from
%% `grounding_metaphors.pl` but lives in a separate predicate
%% (`ln_metaphor/4`) so the QB can review extensions before any
%% promotion into the canonical table. SourceDomain / TargetDomain are
%% short atoms; Description is the one-line summary.

%!  ln_metaphor(?MetaphorId, ?SourceDomain, ?TargetDomain, ?Description) is nondet.

% -- Algebra (Ch. 3, 5) ---------------------------------------------------
ln_metaphor(fundamental_metonymy_of_algebra,
            role_individual_metonymy,
            algebra,
            "A notation (e.g. x) stands metonymically for a role (Number) which stands for an individual number; the everyday role-for-individual mechanism that licenses 'whatever number x happens to be, x+2=7' and laws like x+y=y+x.").
ln_metaphor(essence_is_form,
            form_of_object,
            essence_of_object,
            "Greek philosophical metaphor adopted by algebra: an object's essence is its form. Underwrites algebra as the study of abstract structure.").
ln_metaphor(essence_of_mathematical_system_is_algebraic_structure,
            algebraic_structure,
            essence_of_mathematical_system,
            "Master AE metaphor: the essence of a mathematical system in any domain D outside algebra is an abstract algebraic structure (group, ring, field). Licenses 'addition modulo 3 is a commutative group with three elements'.").
ln_metaphor(addition_mod_3_as_commutative_group,
            algebra_groups,
            modular_arithmetic,
            "Specialization of the general AE metaphor: maps the commutative group with three elements onto addition modulo 3 — abstract elements {I,A,B} to numbers {0,1,2}, abstract * to +, abstract identity I to arithmetic identity 0, abstract laws to arithmetic laws.").

% -- Basic Metaphor of Infinity (Ch. 8) -----------------------------------
ln_metaphor(basic_metaphor_of_infinity,
            completed_iterative_processes,
            iterative_processes_without_end,
            "Master metaphor for actual infinity: an iterative process without end is conceptualized in terms of a completed iterative process by metaphorically adding a 'final resultant state' to the unending process; the final resultant state is unique and follows every nonfinal state.").

% -- Calculus / continuity (Chs. 9, 11, 14, Case Study 2) -----------------
ln_metaphor(numbers_are_points_on_a_line,
            points_on_a_line,
            collection_of_numbers,
            "Numerical analogue of Motion Along a Path: a point P on a line is a number, point O is zero, point 1 is to the right of O, distance from O to P is absolute value of P. Underwrites the Number-Line blend and the Cartesian-Plane blend.").
ln_metaphor(instantaneous_change_is_average_change_over_infinitely_small_interval,
            average_change_over_an_interval,
            instantaneous_change_at_a_point,
            "Calculus grounding metaphor: instantaneous rate of change is conceptualized as average rate of change over an interval of infinitely small size. The 'infinitely small interval' is itself metaphorical and is arithmetized differently by Newton (limit) and Leibniz (infinitesimal).").
ln_metaphor(change_is_motion,
            spatial_motion,
            numerical_change,
            "Everyday grounding metaphor: change of a variable is conceptualized as motion of a trajector along a path. Together with Numbers Are Points on a Line and Talmy's fictive-motion schema, supports phrases like 'x approaches a' for static numerical relations.").
ln_metaphor(change_of_function_is_coordinated_motion_of_two_trajectors,
            two_coordinated_trajectors_in_motion,
            change_of_a_function,
            "The change of a function f(x) as x varies is conceptualized as two coordinated trajectors: one moves in the domain, the other in the range. Underwrites the standard reading of 'f(x) approaches L as x approaches a'.").
ln_metaphor(tangent_is_limit_of_secants,
            sequence_of_secant_lines_to_a_curve,
            tangent_line_at_a_point,
            "Newton's geometric metaphor for the derivative: the tangent to a curve at a point is the limit of a sequence of secant lines whose two intersection points draw arbitrarily close together. A specialization of the BMI for limits, applied to the geometric tangent.").
ln_metaphor(functions_are_curves,
            curves_in_the_cartesian_plane,
            mathematical_functions,
            "Descartes's metaphor: a mathematical function is a curve in the Cartesian plane. Pillar of the geometric paradigm of calculus; allows numerical functions to be visualized spatially.").
ln_metaphor(functions_are_sets_of_ordered_pairs,
            sets_of_ordered_pairs_of_numbers,
            mathematical_functions,
            "Weierstrass-era metaphor that replaced Descartes's curve-grounding: a function IS its set of input-output pairs. Two conceptually different rules that determine the same set of ordered pairs are 'the same function'.").
ln_metaphor(weierstrass_continuity_metaphor,
            preservation_of_numerical_closeness,
            continuity_of_functions_over_continuous_curves,
            "Static-arithmetic reconceptualization of continuity: a function preserves closeness if, for every epsilon-neighborhood in the range, there is a corresponding delta-neighborhood in the domain. Eliminates motion and naturally continuous space; produces the epsilon-delta definition.").

% -- Spaces / discretization (Ch. 12) -------------------------------------
ln_metaphor(spaces_are_sets_of_points,
            set_with_elements,
            naturally_continuous_space_with_point_locations,
            "The central metaphor of the discretization program: an n-dimensional space (line, plane, ...) is a set; elements are point-locations; set-membership distinctness maps to point-location distinctness; relations among members map to properties of space. Reverses the natural-continuity-priority of points.").
ln_metaphor(space_set_blend,
            naturally_continuous_space_blended_with_set_of_elements,
            geometric_objects_as_subsets_of_a_set_of_points,
            "Conceptual blend of Spaces Are Sets of Points with naturally continuous space: a line is at once a set of points and a continuous geometric object; a circle is at once a subset of the point-set and a geometric curve. Dedekind's continuity-as-gaplessness lives inside this blend.").

% -- Logic / set theory (Chs. 6, 7) ---------------------------------------
ln_metaphor(classes_are_containers,
            container_schemas,
            classes,
            "Premathematical metaphor: a class is a bounded region in space; members are objects in the interior. Underwrites Venn diagrams; gives modus ponens, modus tollens, excluded middle, and hypothetical syllogism their spatial logic.").
ln_metaphor(booles_metaphor,
            algebra,
            classes,
            "Boole's mathematization of the Classes Are Containers metaphor: abstract elements correspond to classes; abstract operations to union and intersection; 0 to the empty class; 1 to the universal class; arithmetic laws to laws on classes.").
ln_metaphor(propositional_logic_metaphor,
            boolean_classes,
            propositions,
            "Conceptualizes each proposition P as the class of world-states in which P is true; A union B becomes 'P or Q'; A intersect B becomes 'P and Q'; complement becomes negation. Carries Container-schema inferences into propositional calculus.").
ln_metaphor(sets_are_objects,
            objects_on_a_par_with_other_objects,
            sets_in_modern_set_theory,
            "Modern set theory's prerequisite metaphor: a set is an object that can itself be a member of another set. Lets us form power sets. Combined with the Container-schema reading of sets, supports the von Neumann axiom of Foundation (sets cannot contain themselves).").
ln_metaphor(cantors_metaphor,
            mappings_one_to_one_correspondence,
            numeration_same_number_as,
            "Cantor's replacement of the everyday Same-Number-As concept by 'pairability': set A and set B have the same number of elements iff they can be put into one-to-one correspondence. Enables transfinite cardinal arithmetic.").
ln_metaphor(sets_are_graphs,
            accessible_pointed_graphs,
            sets_hypersets,
            "Aczel-Barwise-Moss metaphor: a set is an accessible pointed graph (APG); membership is an arrow; nodes-that-are-tails are sets; decorations on nodes-that-are-heads are members. Eliminates the Container reading; supports the Anti-Foundation axiom and sets that contain themselves.").


%% ----------------------------------------------------------------------
%% Cross-domain mappings (selected; not exhaustive)
%%
%% Mirrors `metaphor_mapping/4`. Each ln_metaphor_mapping/4 records a
%% single source-to-target concept pairing with a Notes string for
%% provenance or constraint.

%!  ln_metaphor_mapping(?MetaphorId, ?SourceConcept, ?TargetConcept, ?Notes) is nondet.

ln_metaphor_mapping(basic_metaphor_of_infinity,
                    beginning_state_of_iterative_process,
                    beginning_state_of_unending_process,
                    "Base of the mapping.").
ln_metaphor_mapping(basic_metaphor_of_infinity,
                    process_step_produces_next_state,
                    process_step_produces_next_state,
                    "The iterative step maps identically.").
ln_metaphor_mapping(basic_metaphor_of_infinity,
                    final_resultant_state_of_completed_process,
                    final_resultant_state_actual_infinity,
                    "The metaphorically-imposed completion; this is the load-bearing line of the mapping.").
ln_metaphor_mapping(basic_metaphor_of_infinity,
                    uniqueness_of_final_state,
                    uniqueness_of_actual_infinity_entity,
                    "Entailment E: the final resultant state is unique and follows every nonfinal state.").

ln_metaphor_mapping(numbers_are_points_on_a_line,
                    point_to_right_of_origin,
                    positive_number,
                    "Underwrites magnitude and ordering on the number line.").
ln_metaphor_mapping(numbers_are_points_on_a_line,
                    points_to_left_of_origin,
                    negative_numbers,
                    "Negatives are point-locations on the opposite side of zero (cf. Motion Along a Path in basic table).").
ln_metaphor_mapping(numbers_are_points_on_a_line,
                    distance_between_points,
                    absolute_value_of_difference,
                    "Geometric distance grounds arithmetic |x - y|.").

ln_metaphor_mapping(functions_are_curves,
                    continuous_motion_of_a_point,
                    continuous_variation_of_numerical_variables,
                    "Descartes's observation that planar motion correlates with continuous changes of x and y in algebraic equations.").
ln_metaphor_mapping(functions_are_curves,
                    tangent_line_to_curve_at_point,
                    derivative_at_a_point,
                    "Grounds Newton's geometric derivative; itself requires Tangent Is Limit of Secants to be arithmetized.").

ln_metaphor_mapping(functions_are_sets_of_ordered_pairs,
                    set_of_ordered_pairs_of_real_numbers,
                    a_function,
                    "Two conceptually different rules with the same Taylor series determine the same set of ordered pairs and hence 'are the same function'.").

ln_metaphor_mapping(weierstrass_continuity_metaphor,
                    epsilon_delta_quantifier_pattern,
                    preservation_of_closeness_at_a_point,
                    "For every epsilon there exists delta such that ... — static logical constraint replacing geometric approach.").

ln_metaphor_mapping(spaces_are_sets_of_points,
                    membership_in_the_set,
                    being_a_point_in_the_space,
                    "The constitutive mapping.").
ln_metaphor_mapping(spaces_are_sets_of_points,
                    subset_of_the_set,
                    geometric_figure_as_subset,
                    "A circle, triangle, or curve is just a subset of the point-set with relations holding among the points.").
ln_metaphor_mapping(spaces_are_sets_of_points,
                    distance_function_on_set,
                    metric_on_the_space,
                    "Distance becomes a function assigning numbers to pairs of set members.").

ln_metaphor_mapping(classes_are_containers,
                    interior_of_container_schema,
                    a_class,
                    "Class = bounded interior.").
ln_metaphor_mapping(classes_are_containers,
                    overlap_of_interiors,
                    intersection_of_classes,
                    "Set intersection grounded in spatial overlap.").
ln_metaphor_mapping(classes_are_containers,
                    totality_of_interiors,
                    union_of_classes,
                    "Set union grounded in spatial totality.").
ln_metaphor_mapping(classes_are_containers,
                    exterior_of_a_container,
                    complement_of_a_class,
                    "Set complement grounded in spatial exterior.").

ln_metaphor_mapping(cantors_metaphor,
                    one_to_one_correspondence_between_sets,
                    same_number_as,
                    "Identifies 'same numerosity' with pairability; the move that licenses |N| = |2N| for infinite sets.").

ln_metaphor_mapping(sets_are_graphs,
                    apg_arrow_from_node_to_node,
                    set_membership_relation,
                    "Membership becomes an asymmetric arrow in a directed graph.").
ln_metaphor_mapping(sets_are_graphs,
                    loop_in_apg,
                    set_that_contains_itself,
                    "Hypersets: a loop in the graph models a set that contains itself; replaces axiom of Foundation with Anti-Foundation.").

ln_metaphor_mapping(fundamental_metonymy_of_algebra,
                    notation_x_as_role,
                    individual_number_filling_role,
                    "The role-for-individual metonymy that licenses x+y=y+x as a law over all numbers.").

ln_metaphor_mapping(essence_of_mathematical_system_is_algebraic_structure,
                    abstract_group_with_three_elements,
                    essence_of_addition_modulo_3,
                    "The instance worked out in Ch. 5.").


%% ----------------------------------------------------------------------
%% Break points (Ch. 7, 9, 12, 14; Case Studies)
%%
%% Where the source domain cannot ground a target inference the target
%% domain nevertheless validates. Same shape as basic-table breaks.

%!  ln_metaphor_breaks_at(?MetaphorId, ?TargetInference, ?Reason) is nondet.

ln_metaphor_breaks_at(classes_are_containers,
                      sets_that_contain_themselves,
                      "Physical containers cannot be placed inside their own interiors; the Container-reading of sets blocks self-membership (codified as the axiom of Foundation).").

ln_metaphor_breaks_at(numbers_are_points_on_a_line,
                      actual_infinity_as_a_point_on_the_line,
                      "The number line has no point at infinity in the everyday version; specializations of the BMI introduce one (projective geometry, inversive geometry, infinitesimals).").

ln_metaphor_breaks_at(functions_are_curves,
                      monster_functions_lacking_tangents_or_continuity,
                      "Weierstrass-type pathological functions (continuous everywhere, differentiable nowhere; space-filling curves) violate the prototypical-curve properties Pierpont named; the metaphor cannot ground them.").

ln_metaphor_breaks_at(functions_are_sets_of_ordered_pairs,
                      conceptual_distinction_between_rule_and_extension,
                      "Two conceptually different rules with the same extension become the same function under this metaphor; the conceptual distinction the rule-reading preserves is collapsed.").

ln_metaphor_breaks_at(weierstrass_continuity_metaphor,
                      naturally_continuous_motion_of_a_trajectory,
                      "Preservation of closeness has no motion, no approach, no time; what is lost is precisely the everyday phenomenology of continuity as continuous trajectory.").

ln_metaphor_breaks_at(spaces_are_sets_of_points,
                      naturally_continuous_space_as_constitutively_pre_point,
                      "L&N flag the 'two conceptions are inconsistent': in everyday cognition points are inherent to space; here space is constituted by points. The metaphor's target requires holding both simultaneously, which is a blend, not a clean reduction.").

ln_metaphor_breaks_at(cantors_metaphor,
                      everyday_same_number_as_for_infinite_collections,
                      "'There are just as many even numbers as natural numbers' is true under Cantor's pairability metaphor; under everyday Same-Number-As (take-away comparison) the naturals have more. Cantor's metaphor reassigns the concept.").


%% ----------------------------------------------------------------------
%% Repairs
%%
%% Where L&N name a new metaphor introduced to preserve closure of the
%% target under inferences a prior metaphor cannot ground.

%!  ln_metaphor_repair(?BrokenMetaphor, ?BrokenInference, ?RepairMetaphor, ?Mechanism) is nondet.

ln_metaphor_repair(classes_are_containers,
                   sets_that_contain_themselves,
                   sets_are_graphs,
                   accessible_pointed_graphs_with_loops_replace_containment_with_membership_arrows).

ln_metaphor_repair(functions_are_curves,
                   monster_functions_lacking_tangents_or_continuity,
                   functions_are_sets_of_ordered_pairs,
                   set_theoretic_reading_admits_pathological_functions_at_the_cost_of_geometric_intuition).

ln_metaphor_repair(numbers_are_points_on_a_line,
                   actual_infinity_as_a_point_on_the_line,
                   basic_metaphor_of_infinity,
                   bmi_supplies_unique_final_resultant_state_for_specialized_iterative_processes).


%% ----------------------------------------------------------------------
%% BMI specializations
%%
%% L&N derive a long list of mathematical concepts as special cases of
%% the BMI by specifying the iterative process. Each fact below names
%% the special case, the iterative process that is being completed,
%% and the chapter/page where the specialization is worked out.

%!  ln_bmi_specialization(?SpecializationId, ?IterativeProcessDescription, ?LocationAtom) is nondet.

ln_bmi_specialization(bmi_for_enumeration,
                      "Unending sequence of integers used for enumeration; final resultant state is the 'integer' infinity larger than every other integer.",
                      ln_ch8_p165).
ln_bmi_specialization(bmi_for_set_of_all_natural_numbers,
                      "Unending process of generating natural numbers via successor; final resultant state is the completed infinite set N.",
                      ln_ch8_p174).
ln_bmi_specialization(bmi_for_mathematical_induction,
                      "Iterative verification S(n-1) -> S(n); final resultant state is S(x) true for the infinite set of all finite natural numbers.",
                      ln_ch8_p175).
ln_bmi_specialization(bmi_for_generative_closure,
                      "Iterative extension of a set under closure under operations; final resultant state is the infinite closure containing every finite combination.",
                      ln_ch8_p176).
ln_bmi_specialization(bmi_for_projective_parallel_lines,
                      "Sequence of isosceles triangles with apex distance growing unboundedly; final resultant state is parallel lines meeting at a unique point at infinity.",
                      ln_ch8_p167).
ln_bmi_specialization(bmi_for_inversive_point_at_infinity,
                      "Iteration of f(x)=1/x applied to points on rays approaching the origin; final resultant state is a unique inverse point infinitely far from the origin shared by all rays.",
                      ln_ch8_p170).
ln_bmi_specialization(bmi_for_infinite_decimals,
                      "Unending process of appending decimal digits; final resultant state is an infinitely long fixed sequence — a real number between zero and one.",
                      ln_ch9_p182).
ln_bmi_specialization(bmi_for_limit_of_infinite_sequence,
                      "Process by which |x_n - L| gets progressively smaller; final resultant state has zero remaining distance to L.",
                      ln_ch9_p186).
ln_bmi_specialization(bmi_for_infinite_sums,
                      "Piggybacks on BMI for limits: an infinite sum is the limit of an infinite sequence of partial sums.",
                      ln_ch9_p197).
ln_bmi_specialization(bmi_for_limit_of_function,
                      "Coordinated sequences in domain and range converging to a and L respectively; built on the BMI for limits of sequences.",
                      ln_ch9_p198).
ln_bmi_specialization(bmi_for_least_upper_bound,
                      "Sequence of ever-smaller finite upper bounds for a set; final resultant state is a unique least upper bound. Creates irrationals like pi from cognitive perspective.",
                      ln_ch9_p202).
ln_bmi_specialization(bmi_for_nested_intervals,
                      "Sequence of nested closed intervals each contained in the previous; final resultant state is a unique real number at the intersection.",
                      ln_ch9_p206).
ln_bmi_specialization(bmi_for_transfinite_cardinal_aleph_0,
                      "Cantor's pairability combined with the BMI's completion of the natural-number generation; yields the cardinal aleph_0.",
                      ln_ch10_p208).
ln_bmi_specialization(bmi_for_transfinite_ordinal_omega,
                      "Completion of the sequence of natural numbers in their natural order; yields the first transfinite ordinal omega.",
                      ln_ch10_p217).
ln_bmi_specialization(bmi_for_infinitesimals,
                      "Iterative process forming sets of numbers greater than zero and less than 1/n; final resultant state is the first infinitesimal delta.",
                      ln_ch11_p228).
ln_bmi_specialization(bmi_for_logical_compactness,
                      "Iterative process of finding models for progressively larger finite subsets of sentences; final resultant state is a single model satisfying the entire infinite set.",
                      ln_ch11_p231).


%% ----------------------------------------------------------------------
%% Target-domain practice bridges
%%
%% Where an existing practice id from `formal/pml/mua_relations.pl` deploys
%% the source-domain action of one of the new metaphors. Same shape as
%% `metaphor_target_practice/2` in the basic table.

%!  ln_metaphor_target_practice(?MetaphorId, ?TargetPracticeId) is nondet.

ln_metaphor_target_practice(numbers_are_points_on_a_line,
                            p_count_on_from_larger).
ln_metaphor_target_practice(numbers_are_points_on_a_line,
                            p_signed_addition_with_sign_relation).

% Calculus practices in strategies/math/calculus_limits_action_pairs.pl.
% Direct substitution, factor-cancel-substitute, the
% bounded-numerator/diverging-denominator practice, and
% factor-cancel-without-common-factor all deploy the limit notion
% formalized via the BMI for limits of functions (Ch. 9).
ln_metaphor_target_practice(basic_metaphor_of_infinity,
                            p_direct_substitution).
ln_metaphor_target_practice(basic_metaphor_of_infinity,
                            p_factor_cancel_substitute).
ln_metaphor_target_practice(basic_metaphor_of_infinity,
                            p_bounded_numerator_over_diverging_denominator).

ln_metaphor_target_practice(instantaneous_change_is_average_change_over_infinitely_small_interval,
                            p_factor_cancel_substitute).

ln_metaphor_target_practice(weierstrass_continuity_metaphor,
                            p_direct_substitution).
ln_metaphor_target_practice(weierstrass_continuity_metaphor,
                            p_factor_cancel_without_common_factor).

% Functions Are Sets of Ordered Pairs underwrites the static logical
% reading that classifies `factor_cancel_without_common_factor` as
% inferentially hollow: under the rule-reading two expressions might
% disagree, but under the ordered-pair reading the extensions decide
% sameness.
ln_metaphor_target_practice(functions_are_sets_of_ordered_pairs,
                            p_factor_cancel_substitute).
ln_metaphor_target_practice(functions_are_sets_of_ordered_pairs,
                            p_factor_cancel_without_common_factor).

% Classes Are Containers grounds the diagnostic-validation practices
% that route through class-membership reasoning (e.g. the multiplicative
% bound invalidation diagnoses an element as outside the class of valid
% answers).
ln_metaphor_target_practice(classes_are_containers,
                            p_multiplicative_bound_invalidation).
ln_metaphor_target_practice(classes_are_containers,
                            p_error_magnitude_estimate_comparison).

% Fundamental Metonymy of Algebra grounds any practice that uses a
% variable in place of a specific number. The programming-expression
% evaluation practice in strategies/math/algebraic_action_pairs.pl is
% the most direct deployment in the current codebase.
ln_metaphor_target_practice(fundamental_metonymy_of_algebra,
                            p_programming_expression_evaluation).


%% ----------------------------------------------------------------------
%% Citations
%%
%% Each metaphor id gets one or more citation atoms following the
%% `ln_chN_pNNN` form. Where the NotebookLM response surfaced a page,
%% the page is recorded; where it did not, the citation is chapter-only
%% and is flagged in the audit report's open questions.

%!  ln_metaphor_citation(?MetaphorId, ?CitationAtom) is nondet.

ln_metaphor_citation(fundamental_metonymy_of_algebra,           ln_ch3).
ln_metaphor_citation(essence_is_form,                           ln_ch5).
ln_metaphor_citation(essence_of_mathematical_system_is_algebraic_structure,
                                                                ln_ch5).
ln_metaphor_citation(addition_mod_3_as_commutative_group,       ln_ch5).
ln_metaphor_citation(basic_metaphor_of_infinity,                ln_ch8_p158).
ln_metaphor_citation(basic_metaphor_of_infinity,                ln_ch8_p159).
ln_metaphor_citation(numbers_are_points_on_a_line,              ln_ch12).
ln_metaphor_citation(instantaneous_change_is_average_change_over_infinitely_small_interval,
                                                                ln_ch11).
ln_metaphor_citation(instantaneous_change_is_average_change_over_infinitely_small_interval,
                                                                ln_cs2).
ln_metaphor_citation(change_is_motion,                          ln_cs2).
ln_metaphor_citation(change_of_function_is_coordinated_motion_of_two_trajectors,
                                                                ln_ch9).
ln_metaphor_citation(tangent_is_limit_of_secants,               ln_ch11).
ln_metaphor_citation(functions_are_curves,                      ln_ch14).
ln_metaphor_citation(functions_are_sets_of_ordered_pairs,       ln_ch14).
ln_metaphor_citation(weierstrass_continuity_metaphor,           ln_ch14_p311).
ln_metaphor_citation(spaces_are_sets_of_points,                 ln_ch12_p263).
ln_metaphor_citation(spaces_are_sets_of_points,                 ln_ch12_p264).
ln_metaphor_citation(space_set_blend,                           ln_ch12).
ln_metaphor_citation(classes_are_containers,                    ln_ch6).
ln_metaphor_citation(booles_metaphor,                           ln_ch6).
ln_metaphor_citation(propositional_logic_metaphor,              ln_ch6).
ln_metaphor_citation(sets_are_objects,                          ln_ch7).
ln_metaphor_citation(cantors_metaphor,                          ln_ch7).
ln_metaphor_citation(cantors_metaphor,                          ln_ch10).
ln_metaphor_citation(sets_are_graphs,                           ln_ch7).


%% ----------------------------------------------------------------------
%% Metaphor kind
%%
%% Coarse classification used by downstream tools. 'basic' = a primary
%% grounding metaphor (e.g. the BMI itself, Classes Are Containers).
%% 'repair' = introduced to preserve closure of a target under
%% inferences a prior metaphor cannot ground (Sets Are Graphs for
%% self-membership; Functions Are Sets of Ordered Pairs for monsters).
%% 'algebraic_essence' = AE family. 'specialization_substrate' = the
%% BMI used as substrate for specializations.

%!  ln_metaphor_kind(?MetaphorId, ?Kind) is nondet.
ln_metaphor_kind(fundamental_metonymy_of_algebra,               metonymy).
ln_metaphor_kind(essence_is_form,                               philosophical_substrate).
ln_metaphor_kind(essence_of_mathematical_system_is_algebraic_structure, algebraic_essence).
ln_metaphor_kind(addition_mod_3_as_commutative_group,           algebraic_essence).
ln_metaphor_kind(basic_metaphor_of_infinity,                    specialization_substrate).
ln_metaphor_kind(numbers_are_points_on_a_line,                  basic).
ln_metaphor_kind(instantaneous_change_is_average_change_over_infinitely_small_interval, basic).
ln_metaphor_kind(change_is_motion,                              basic).
ln_metaphor_kind(change_of_function_is_coordinated_motion_of_two_trajectors, basic).
ln_metaphor_kind(tangent_is_limit_of_secants,                   basic).
ln_metaphor_kind(functions_are_curves,                          basic).
ln_metaphor_kind(functions_are_sets_of_ordered_pairs,           repair).
ln_metaphor_kind(weierstrass_continuity_metaphor,               repair).
ln_metaphor_kind(spaces_are_sets_of_points,                     basic).
ln_metaphor_kind(space_set_blend,                               blend).
ln_metaphor_kind(classes_are_containers,                        basic).
ln_metaphor_kind(booles_metaphor,                               basic).
ln_metaphor_kind(propositional_logic_metaphor,                  basic).
ln_metaphor_kind(sets_are_objects,                              basic).
ln_metaphor_kind(cantors_metaphor,                              basic).
ln_metaphor_kind(sets_are_graphs,                               repair).
