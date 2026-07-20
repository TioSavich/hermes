/** <module> Lakoff & Núñez grounding metaphors for arithmetic
 *
 * Encodes the four arithmetic grounding metaphors from Lakoff & Núñez
 * (Where Mathematics Comes From, ch. 3) plus the canonical *repair*
 * metaphor that fixes the product-of-two-negatives break in Motion
 * Along a Path.
 *
 * The point of this module is *not* to assert that the metaphors are
 * complete or that any one of them grounds arithmetic in a global
 * sense. Each metaphor is PP-sufficient for a circumscribed set of
 * target inferences and *breaks* at specific others. The breaks are
 * recorded as first-class facts so the project's "Built to Break"
 * stance is queryable: there is no flowery prose about productive
 * failure here, only the points at which each metaphor fails to
 * support an inference the target domain nevertheless validates.
 *
 * Where another metaphor must be introduced to preserve closure under
 * arithmetic operations (the canonical case: Multiplication by -1 IS
 * Rotation by 180 degrees, which repairs the product-of-two-negatives
 * break in Motion Along a Path), the repair is recorded explicitly as
 * a separate metaphor plus a `metaphor_repair/4` fact connecting the
 * broken metaphor to the repair.
 *
 * Equivalent Result Frames (ERFs) are the L&N mechanism by which the
 * source-domain practice of pooling collections grounds the
 * associative law. The ERF for object collections has a single
 * desired result and two equivalent paths to it; the metaphor maps the
 * physical ERF onto an arithmetic ERF whose cognitive content IS the
 * associative law. The structure is encoded as a Prolog term so the
 * mapping can be inspected by downstream tools.
 *
 * Source-domain practices named here are PP-necessary in Brandom's
 * sense for the corresponding arithmetic practices. They are described
 * in module comments; the practice ids are intended to be stable
 * handles, not natural-kind claims.
 *
 * Bridges to the MUA layer: `metaphor_target_practice/2` connects each
 * grounding metaphor to one or more practices already named in
 * `formal/pml/mua_relations.pl`. The MUA module's `grounding_metaphor/2`
 * predicate remains authoritative for the per-practice assignment;
 * this module's `grounding_metaphor_for_practice/2` is a thin glue
 * predicate over that table.
 *
 * Sources:
 *   - LK_RB_Synthesis/Metaphor_Knowledge_Base.md (the four metaphors,
 *     their key mappings, and entailments)
 *   - docs/research/2026-05-14-lakoff-vandewalle-mua-seed.md
 *     (the break points, the repair metaphor, and the ERF mechanism
 *     extracted from NotebookLM against L&N's text)
 *   - formal/pml/mua_relations.pl (authoritative practice ids and
 *     per-practice grounding-metaphor assignments)
 *
 * Source-domain practices (defined in module comments, used by
 * `metaphor_source_practice/2`):
 *   - p_pooling_of_collections        : putting collections of objects together;
 *                                       pooling-order-invariance is observable here
 *   - p_taking_collection_from_collection : removing a subcollection from a larger one
 *   - p_splitting_object_into_parts    : splitting a unit object into n equal parts
 *   - p_fitting_parts_together         : assembling parts into a whole; supports
 *                                       fraction multiplication directly
 *   - p_placing_segments_end_to_end    : measuring-stick addition; lengths combine
 *   - p_comparing_segment_lengths      : ordering segments by length
 *   - p_moving_along_a_path            : motion from origin toward a goal; supports
 *                                       directionality (positive vs negative side)
 *   - p_rotation_in_the_plane          : the repair metaphor's source-domain
 *                                       practice; rotation by 180 degrees composes
 *                                       to the identity, grounding (-1)*(-1) = 1
 */

:- module(grounding_metaphors,
          [ grounding_metaphor_definition/4,
            metaphor_source_practice/2,
            metaphor_target_practice/2,
            metaphor_mapping/4,
            metaphor_breaks_at/3,
            metaphor_break_witness/4,
            metaphor_repair/4,
            metaphor_repair_witness/5,
            equivalent_result_frame/3,
            grounds_inference/3,
            grounding_metaphor_for_practice/2,
            grounding_metaphor_for_practice_witness/3,
            grounds_inference_witness/4,
            metaphor_kind/2,
            metaphor_short_name/2,
            % Extension exports
            bmi_specialization/3,
            metaphor_citation/2
          ]).

:- use_module(pml(mua_relations)).
:- use_module(formalization(grounding_metaphors_extended),
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
%% Grounding metaphor definitions
%%
%% One fact per L&N grounding metaphor plus the canonical repair.
%% SourceDomain and TargetDomain are short atoms naming the conceptual
%% domains being bridged; Description is the one-line summary.

%!  grounding_metaphor_definition(?MetaphorId, ?SourceDomain, ?TargetDomain, ?Description) is nondet.
grounding_metaphor_definition(MetaphorId, SourceDomain, TargetDomain, Description) :-
    base_grounding_metaphor_definition(MetaphorId, SourceDomain, TargetDomain, Description).
grounding_metaphor_definition(MetaphorId, SourceDomain, TargetDomain, Description) :-
    ln_metaphor(MetaphorId, SourceDomain, TargetDomain, Description).

base_grounding_metaphor_definition(arithmetic_is_object_collection,
                                   physical_object_collections,
                                   arithmetic,
                                   "Numbers are collections of objects; addition is pooling, subtraction is taking-from, multiplication is pooling A subcollections of size B.").
base_grounding_metaphor_definition(arithmetic_is_object_construction,
                                   physical_object_construction,
                                   arithmetic,
                                   "Numbers are whole objects made of parts; fractions are parts produced by splitting a unit object; m/n is m parts of size 1/n fitted together.").
base_grounding_metaphor_definition(arithmetic_is_measuring_stick,
                                   physical_segments_and_lengths,
                                   arithmetic,
                                   "Numbers are physical segments; addition is placing segments end-to-end; every length must have a number, which forces irrationals into existence.").
base_grounding_metaphor_definition(arithmetic_is_motion_along_a_path,
                                   motion_along_a_path,
                                   arithmetic,
                                   "Numbers are point-locations on a path; zero is the origin; addition is motion away from origin; negatives are point-locations on the opposite side of zero.").
base_grounding_metaphor_definition(multiplication_by_minus_one_is_rotation_by_180_degrees,
                                   rotation_in_the_plane,
                                   arithmetic_of_signed_numbers,
                                   "Repair metaphor: multiplication by -1 IS rotation by 180 degrees. Introduced specifically to preserve arithmetic closure for the product of two negatives, which Motion Along a Path cannot ground.").
base_grounding_metaphor_definition(zero_collection_metaphor,
                                   absence_of_objects,
                                   arithmetic_with_zero,
                                   "Repair metaphor: an empty collection IS zero. Introduced to give Object Collection an additive identity (A + 0 = A) that 'no collection at all' would otherwise leave undefined.").
base_grounding_metaphor_definition(zero_object_metaphor,
                                   absence_of_an_object,
                                   arithmetic_with_zero,
                                   "Repair metaphor: the absence of an object IS zero. Introduced to give Object Construction an additive identity that 'no object at all' would otherwise leave undefined.").
base_grounding_metaphor_definition(balance_preservation_schema,
                                   two_pan_balance,
                                   relational_equality,
                                   "Project-local relational-equals schema: two expressions name equal quantities, and applying the same operation to both sides preserves that equality.").


%% ----------------------------------------------------------------------
%% Source-domain practices
%%
%% Each metaphor's source domain is a physical practice. These are the
%% PP-necessary source practices in Brandom's sense for the arithmetic
%% practices the metaphor grounds. Practice ids are documented in the
%% module header.

%!  metaphor_source_practice(?MetaphorId, ?SourcePracticeId) is nondet.
metaphor_source_practice(arithmetic_is_object_collection,
                         p_pooling_of_collections).
metaphor_source_practice(arithmetic_is_object_collection,
                         p_taking_collection_from_collection).
metaphor_source_practice(arithmetic_is_object_construction,
                         p_fitting_parts_together).
metaphor_source_practice(arithmetic_is_object_construction,
                         p_splitting_object_into_parts).
metaphor_source_practice(arithmetic_is_measuring_stick,
                         p_placing_segments_end_to_end).
metaphor_source_practice(arithmetic_is_measuring_stick,
                         p_comparing_segment_lengths).
metaphor_source_practice(arithmetic_is_motion_along_a_path,
                         p_moving_along_a_path).
metaphor_source_practice(multiplication_by_minus_one_is_rotation_by_180_degrees,
                         p_rotation_in_the_plane).


%% ----------------------------------------------------------------------
%% Target-domain practices
%%
%% Bridges each metaphor to one or more practices already named in
%% `formal/pml/mua_relations.pl`. Not exhaustive; each entry records a
%% practice for which the metaphor's source-domain action is named in
%% the L&N text as a grounding.

%!  metaphor_target_practice(?MetaphorId, ?TargetPracticeId) is nondet.
metaphor_target_practice(MetaphorId, TargetPracticeId) :-
    base_metaphor_target_practice(MetaphorId, TargetPracticeId).
metaphor_target_practice(MetaphorId, TargetPracticeId) :-
    ln_metaphor_target_practice(MetaphorId, TargetPracticeId).

base_metaphor_target_practice(arithmetic_is_object_collection,
                              p_rigorous_counting_procedure).
base_metaphor_target_practice(arithmetic_is_object_construction,
                              p_area_model_part_of_part).
base_metaphor_target_practice(arithmetic_is_object_construction,
                              p_unit_fraction_partition).
base_metaphor_target_practice(arithmetic_is_object_construction,
                              p_make_base_transfer).
base_metaphor_target_practice(arithmetic_is_measuring_stick,
                              p_unit_fraction_iteration).
base_metaphor_target_practice(arithmetic_is_measuring_stick,
                              p_scale_ratio_unit).
base_metaphor_target_practice(arithmetic_is_motion_along_a_path,
                              p_count_on_from_larger).
base_metaphor_target_practice(arithmetic_is_motion_along_a_path,
                              p_signed_addition_with_sign_relation).


%% ----------------------------------------------------------------------
%% Cross-domain mappings
%%
%% For each metaphor, the key source-to-target concept mappings drawn
%% from `Metaphor_Knowledge_Base.md`. SourceConcept and TargetConcept
%% are short atoms; Notes records anything the mapping flags (e.g.
%% "iteration extension", "ad-hoc Zero Object Metaphor required").

%!  metaphor_mapping(?MetaphorId, ?SourceConcept, ?TargetConcept, ?Notes) is nondet.
metaphor_mapping(MetaphorId, SourceConcept, TargetConcept, Notes) :-
    base_metaphor_mapping(MetaphorId, SourceConcept, TargetConcept, Notes).
metaphor_mapping(MetaphorId, SourceConcept, TargetConcept, Notes) :-
    ln_metaphor_mapping(MetaphorId, SourceConcept, TargetConcept, Notes).

% -- Arithmetic IS Object Collection
base_metaphor_mapping(arithmetic_is_object_collection,
                      collections_of_objects,
                      numbers,
                      "Size of collection corresponds to magnitude of number.").
base_metaphor_mapping(arithmetic_is_object_collection,
                      pooling_collections,
                      addition,
                      "Putting collections together; pooling-order-invariance grounds commutativity and the associative ERF grounds associativity.").
base_metaphor_mapping(arithmetic_is_object_collection,
                      taking_smaller_collection_from_larger,
                      subtraction,
                      "Source-domain operation only defined when the taken collection is no larger than the source.").
base_metaphor_mapping(arithmetic_is_object_collection,
                      pooling_A_subcollections_of_size_B,
                      multiplication,
                      "Multiplication as iterated pooling; A subcollections each of size B.").
base_metaphor_mapping(arithmetic_is_object_collection,
                      splitting_collection_into_A_equal_subcollections,
                      division,
                      "Division as equal-splitting; also expressible as iterated subtraction.").
base_metaphor_mapping(arithmetic_is_object_collection,
                      empty_collection,
                      zero,
                      "Requires ad-hoc Zero Collection Metaphor: 'no objects' conceptualised as a special empty collection.").

% -- Arithmetic IS Object Construction
base_metaphor_mapping(arithmetic_is_object_construction,
                      parts_of_unit_size,
                      numbers,
                      "Numbers are whole objects made of ultimate parts of unit size.").
base_metaphor_mapping(arithmetic_is_object_construction,
                      fitting_parts_together,
                      addition,
                      "Joining parts into a larger constructed object.").
base_metaphor_mapping(arithmetic_is_object_construction,
                      taking_a_part_away,
                      subtraction,
                      "Removing a part from a constructed object.").
base_metaphor_mapping(arithmetic_is_object_construction,
                      splitting_unit_into_n_parts,
                      fraction_1_over_n,
                      "Simple fraction 1/n grounded as a single part produced by splitting a unit object into n equal parts.").
base_metaphor_mapping(arithmetic_is_object_construction,
                      fitting_together_m_parts_of_size_1_over_n,
                      fraction_m_over_n,
                      "Complex fraction m/n grounded by fitting together m parts of size 1/n.").
base_metaphor_mapping(arithmetic_is_object_construction,
                      lack_of_object,
                      zero,
                      "Requires ad-hoc Zero Object Metaphor: lack-of-object conceptualised as the number zero.").

% -- Arithmetic IS Measuring Stick
base_metaphor_mapping(arithmetic_is_measuring_stick,
                      physical_segments,
                      numbers,
                      "Segments are numbers; length of segment is magnitude of number.").
base_metaphor_mapping(arithmetic_is_measuring_stick,
                      basic_unit_segment,
                      one,
                      "A chosen basic physical segment grounds the unit.").
base_metaphor_mapping(arithmetic_is_measuring_stick,
                      placing_segments_end_to_end,
                      addition,
                      "Lengths combine by concatenation.").
base_metaphor_mapping(arithmetic_is_measuring_stick,
                      taking_shorter_segment_from_longer,
                      subtraction,
                      "Source-domain subtraction only defined when the second segment is no longer than the first.").
base_metaphor_mapping(arithmetic_is_measuring_stick,
                      lack_of_segment,
                      zero,
                      "Zero is grounded as the absence of any physical segment.").
base_metaphor_mapping(arithmetic_is_measuring_stick,
                      every_physical_length_must_have_a_number,
                      irrational_numbers,
                      "The conceptual blend forces irrationals into existence: a diagonal of a unit square has a definite physical length but no rational name, so a number must exist for it.").

% -- Arithmetic IS Motion Along a Path
base_metaphor_mapping(arithmetic_is_motion_along_a_path,
                      point_locations_on_path,
                      numbers,
                      "Numbers are points on a path that extends in both directions.").
base_metaphor_mapping(arithmetic_is_motion_along_a_path,
                      origin,
                      zero,
                      "Zero is the origin by its very nature; no entity-creating metaphor required for zero here.").
base_metaphor_mapping(arithmetic_is_motion_along_a_path,
                      distance_from_origin,
                      magnitude,
                      "Magnitude grounded as distance traveled from the origin.").
base_metaphor_mapping(arithmetic_is_motion_along_a_path,
                      moving_away_from_origin,
                      addition,
                      "Addition is motion away from the origin along the path.").
base_metaphor_mapping(arithmetic_is_motion_along_a_path,
                      moving_toward_origin,
                      subtraction,
                      "Subtraction is motion back toward the origin.").
base_metaphor_mapping(arithmetic_is_motion_along_a_path,
                      point_locations_opposite_side_of_origin,
                      negative_numbers,
                      "Negatives are point-locations on the opposite side of zero. Bombelli (16th c.) made this explicit.").
base_metaphor_mapping(arithmetic_is_motion_along_a_path,
                      repeated_motion_in_one_direction,
                      multiplication_of_positives,
                      "Multiplication grounded as iterated motion; only works for positive multipliers because 'doing something a negative number of times' has no source-domain referent.").

% -- Multiplication by -1 IS Rotation by 180 degrees (repair metaphor)
base_metaphor_mapping(multiplication_by_minus_one_is_rotation_by_180_degrees,
                      rotation_by_180_degrees,
                      multiplication_by_negative_one,
                      "Single application of -1 corresponds to a half-turn in the plane.").
base_metaphor_mapping(multiplication_by_minus_one_is_rotation_by_180_degrees,
                      composition_of_two_180_degree_rotations,
                      multiplication_of_two_negatives_yielding_positive,
                      "Two 180-degree rotations compose to the identity (360 = 0 mod 360), so (-1)*(-1) is grounded as returning to the original orientation -- which IS 1.").


%% ----------------------------------------------------------------------
%% Break points
%%
%% Each fact records a target inference the metaphor's target domain
%% validates but the metaphor's source domain cannot ground. The
%% Reason field names the source-domain feature that fails to
%% support the inference. These are the canonical L&N breaks; they are
%% not exhaustive.

%!  metaphor_breaks_at(?MetaphorId, ?TargetInference, ?Reason) is nondet.
metaphor_breaks_at(MetaphorId, TargetInference, Reason) :-
    base_metaphor_breaks_at(MetaphorId, TargetInference, Reason).
metaphor_breaks_at(MetaphorId, TargetInference, Reason) :-
    ln_metaphor_breaks_at(MetaphorId, TargetInference, Reason).

base_metaphor_breaks_at(arithmetic_is_object_collection,
                        subtraction_of_larger_from_smaller,
                        "No source-domain referent for 'taking a larger collection from a smaller one'.").
base_metaphor_breaks_at(arithmetic_is_object_collection,
                        fractions_of_a_unit,
                        "Object collections are discrete; there are no 'fractional collections'.").
base_metaphor_breaks_at(arithmetic_is_object_collection,
                        irrational_numbers,
                        "Irrationals have no source-domain referent as a collection.").
base_metaphor_breaks_at(arithmetic_is_object_collection,
                        zero_as_a_number,
                        "No source-domain referent for 'a collection of nothing'; requires the ad-hoc Zero Collection Metaphor to supply the additive identity.").
base_metaphor_breaks_at(arithmetic_is_object_construction,
                        zero_as_an_object,
                        "Zero requires the ad-hoc Zero Object Metaphor; lack-of-object is not itself a constructible object.").
base_metaphor_breaks_at(arithmetic_is_object_construction,
                        zero_as_a_number,
                        "No source-domain referent for 'an object that is the absence of an object'; requires the ad-hoc Zero Object Metaphor.").
base_metaphor_breaks_at(arithmetic_is_object_construction,
                        irrational_numbers,
                        "Irrationals are not constructible by finite assembly of unit parts.").
base_metaphor_breaks_at(arithmetic_is_measuring_stick,
                        negative_numbers,
                        "The source domain has 'lack of any physical segment' as zero; you cannot have a segment shorter than nothing, so negatives have no source-domain referent.").
base_metaphor_breaks_at(arithmetic_is_motion_along_a_path,
                        product_of_two_negatives,
                        "In the source domain of motion, doing something a negative number of times makes no sense; the iterated-motion grounding of multiplication cannot be extended to negative multipliers.").


%% ----------------------------------------------------------------------
%% Repairs
%%
%% Records the L&N pattern: when a target inference is invalidated by
%% a break in one metaphor but the target domain nevertheless
%% validates it, a *different* metaphor must be introduced to preserve
%% arithmetic closure. RepairMetaphor is itself an entry in
%% `grounding_metaphor_definition/4`. Where there is no clean repair
%% inside the four basic metaphors, the RepairMetaphor field records
%% `none_in_this_metaphor` with a `see/1` pointer.

%!  metaphor_repair(?BrokenMetaphor, ?BrokenInference, ?RepairMetaphor, ?Mechanism) is nondet.
metaphor_repair(BrokenMetaphor, BrokenInference, RepairMetaphor, Mechanism) :-
    base_metaphor_repair(BrokenMetaphor, BrokenInference, RepairMetaphor, Mechanism).
metaphor_repair(BrokenMetaphor, BrokenInference, RepairMetaphor, Mechanism) :-
    ln_metaphor_repair(BrokenMetaphor, BrokenInference, RepairMetaphor, Mechanism).

%!  metaphor_break_witness(?MetaphorId, ?TargetInference, ?Reason, -Witness) is nondet.
%
%   Positive proof object for a metaphor break. The witness records the
%   explicit break fact and the absence of a grounding fact for the same
%   metaphor/inference pair.
metaphor_break_witness(MetaphorId, TargetInference, Reason,
                       _{ kind: metaphor_break,
                          metaphor_id: MetaphorId,
                          target_inference: TargetInference,
                          reason: Reason,
                          grounding_absence: no_grounding_fact_for_metaphor_and_inference,
                          definition_witness: DefinitionWitness,
                          kind_witness: KindWitness,
                          source: Source }) :-
    metaphor_break_source(MetaphorId, TargetInference, Reason, Source),
    \+ grounds_inference(MetaphorId, TargetInference, _),
    grounding_metaphor_definition_witness(MetaphorId, DefinitionWitness),
    metaphor_kind_witness(MetaphorId, KindWitness).

metaphor_break_source(MetaphorId, TargetInference, Reason, base_grounding_metaphors) :-
    base_metaphor_breaks_at(MetaphorId, TargetInference, Reason),
    !.
metaphor_break_source(MetaphorId, TargetInference, Reason, grounding_metaphors_extended) :-
    ln_metaphor_breaks_at(MetaphorId, TargetInference, Reason).

%!  metaphor_repair_witness(?BrokenMetaphor, ?BrokenInference, ?RepairMetaphor, ?Mechanism, -Witness) is nondet.
%
%   Positive proof object for a repair relation. When a named repair metaphor
%   exists, the witness includes its definition and kind. Sentinel repairs such
%   as `none_in_this_metaphor` remain inspectable but have no repair definition.
metaphor_repair_witness(BrokenMetaphor, BrokenInference, RepairMetaphor, Mechanism,
                        _{ kind: metaphor_repair,
                           broken_metaphor: BrokenMetaphor,
                           broken_inference: BrokenInference,
                           repair_metaphor: RepairMetaphor,
                           mechanism: Mechanism,
                           break_witness: BreakWitness,
                           repair_definition_witness: RepairDefinitionWitness,
                           repair_kind_witness: RepairKindWitness,
                           source: Source }) :-
    metaphor_repair_source(BrokenMetaphor, BrokenInference, RepairMetaphor, Mechanism, Source),
    metaphor_break_witness(BrokenMetaphor, BrokenInference, _, BreakWitness),
    repair_target_witnesses(RepairMetaphor, RepairDefinitionWitness, RepairKindWitness).

metaphor_repair_source(BrokenMetaphor, BrokenInference, RepairMetaphor, Mechanism,
                       base_grounding_metaphors) :-
    base_metaphor_repair(BrokenMetaphor, BrokenInference, RepairMetaphor, Mechanism),
    !.
metaphor_repair_source(BrokenMetaphor, BrokenInference, RepairMetaphor, Mechanism,
                       grounding_metaphors_extended) :-
    ln_metaphor_repair(BrokenMetaphor, BrokenInference, RepairMetaphor, Mechanism).

repair_target_witnesses(none_in_this_metaphor,
                        _{kind: no_repair_metaphor_definition,
                          repair_metaphor: none_in_this_metaphor},
                        _{kind: no_repair_metaphor_kind,
                          repair_metaphor: none_in_this_metaphor}) :-
    !.
repair_target_witnesses(RepairMetaphor, DefinitionWitness, KindWitness) :-
    grounding_metaphor_definition_witness(RepairMetaphor, DefinitionWitness),
    metaphor_kind_witness(RepairMetaphor, KindWitness).

base_metaphor_repair(arithmetic_is_motion_along_a_path,
                     product_of_two_negatives,
                     multiplication_by_minus_one_is_rotation_by_180_degrees,
                     rotation_by_180_degrees_preserves_arithmetic_closure_under_all_four_grounding_metaphors).
base_metaphor_repair(arithmetic_is_object_collection,
                     zero_as_a_number,
                     zero_collection_metaphor,
                     empty_collection_introduced_as_an_entity_to_preserve_additive_identity).
base_metaphor_repair(arithmetic_is_object_construction,
                     zero_as_a_number,
                     zero_object_metaphor,
                     absence_of_object_introduced_as_an_entity_to_preserve_additive_identity).
base_metaphor_repair(arithmetic_is_object_construction,
                     zero_as_an_object,
                     zero_object_metaphor,
                     absence_of_object_introduced_as_an_entity_to_preserve_construction_closure).
base_metaphor_repair(arithmetic_is_object_collection,
                     fractions_of_a_unit,
                     none_in_this_metaphor,
                     see(arithmetic_is_object_construction)).
base_metaphor_repair(arithmetic_is_object_collection,
                     irrational_numbers,
                     none_in_this_metaphor,
                     see(arithmetic_is_measuring_stick)).
base_metaphor_repair(arithmetic_is_object_construction,
                     irrational_numbers,
                     none_in_this_metaphor,
                     see(arithmetic_is_measuring_stick)).
base_metaphor_repair(arithmetic_is_measuring_stick,
                     negative_numbers,
                     none_in_this_metaphor,
                     see(arithmetic_is_motion_along_a_path)).


%% ----------------------------------------------------------------------
%% Equivalent Result Frames (ERFs)
%%
%% L&N's mechanism (Where Mathematics Comes From, ch. 3) for grounding
%% laws like associativity and commutativity. An ERF names a desired
%% result plus multiple physical paths to that result; the metaphor
%% maps the physical ERF onto an arithmetic ERF whose cognitive content
%% IS the law.
%%
%% Each fact records the structure as:
%%   erf(desired_result(...),
%%       entities([...]),
%%       operation(...),
%%       equivalents([...]))
%% with the equivalents listing the alternative paths whose
%% source-domain equivalence grounds the law.

%!  equivalent_result_frame(?MetaphorId, ?ERFName, ?ERFStructure) is nondet.
equivalent_result_frame(arithmetic_is_object_collection,
                        associative_erf_for_collections,
                        erf(desired_result(collection_of_size_n_from_inputs_a_b_c),
                            entities([collection_a, collection_b, collection_c]),
                            operation(pooling_collections),
                            equivalents([
                                path(pool_first(b_with_c), then_pool(a, result)),
                                path(pool_first(a_with_b), then_pool(result, c))
                            ]))).

equivalent_result_frame(arithmetic_is_object_collection,
                        commutativity_erf_for_pooling,
                        erf(desired_result(collection_of_size_n_from_inputs_a_b),
                            entities([collection_a, collection_b]),
                            operation(pooling_collections),
                            equivalents([
                                path(pool(a, b)),
                                path(pool(b, a))
                            ]))).

equivalent_result_frame(arithmetic_is_object_construction,
                        associative_erf_for_object_construction,
                        erf(desired_result(object_of_size_n_from_parts_a_b_c),
                            entities([part_a, part_b, part_c]),
                            operation(fitting_parts_together),
                            equivalents([
                                path(fit_first(b_with_c), then_fit(a, result)),
                                path(fit_first(a_with_b), then_fit(result, c))
                            ]))).


%% ----------------------------------------------------------------------
%% Inference grounding
%%
%% For each target inference the project is interested in, name the
%% source-domain practice (or ERF, or repair mechanism) that grounds
%% it. Absence is meaningful: if there is no fact
%% `grounds_inference(M, I, _)`, then M does not ground I -- either
%% because the metaphor breaks at I (see `metaphor_breaks_at/3`) or
%% because the target inference is outside the metaphor's scope.

%!  grounds_inference(?MetaphorId, ?TargetInference, ?GroundingPath) is nondet.
grounds_inference(arithmetic_is_object_collection,
                  commutativity_of_addition,
                  pooling_order_invariance).
grounds_inference(arithmetic_is_object_collection,
                  associativity_of_addition,
                  associative_erf_for_collections).
grounds_inference(arithmetic_is_object_construction,
                  simple_fractions_1_over_n,
                  splitting_unit_into_n_parts).
grounds_inference(arithmetic_is_object_construction,
                  complex_fractions_m_over_n,
                  fitting_together_m_parts_of_size_1_over_n).
grounds_inference(arithmetic_is_object_construction,
                  fraction_multiplication_as_part_of_part,
                  nested_partition_of_unit_object).
% The mutual-inverse entailment L&N state explicitly (Ch. 3, Arithmetic Is
% Object Construction): splitting a unit object into n parts and fitting the n
% parts back together returns the unit object -- i.e. 1/n * n = 1, so 1/n is the
% multiplicative inverse of n. This is the material inference the splitting
% action pair deploys; partition and iterate are not two unrelated operations
% but a closed pair under which the unit is invariant.
grounds_inference(arithmetic_is_object_construction,
                  multiplicative_inverse_1_over_n_times_n_is_1,
                  partition_then_iterate_returns_unit).
grounds_inference(arithmetic_is_measuring_stick,
                  irrational_numbers,
                  every_length_must_have_a_number_blend).
grounds_inference(arithmetic_is_motion_along_a_path,
                  negative_numbers,
                  point_locations_on_opposite_side_of_origin).
grounds_inference(arithmetic_is_motion_along_a_path,
                  multiplication_of_positives,
                  repeated_motion_in_one_direction).
grounds_inference(multiplication_by_minus_one_is_rotation_by_180_degrees,
                  product_of_two_negatives,
                  composition_of_two_180_degree_rotations_to_identity).

%!  grounds_inference_witness(?MetaphorId, ?TargetInference, ?GroundingPath, -Witness) is nondet.
%
%   Positive proof object for a grounded inference. The witness exposes the
%   metaphor definition, kind, and the evidence for the grounding path when the
%   path is an ERF, repair mechanism, mapping, or direct grounding fact.
grounds_inference_witness(MetaphorId, TargetInference, GroundingPath,
                          _{ kind: grounded_inference,
                             metaphor_id: MetaphorId,
                             target_inference: TargetInference,
                             grounding_path: GroundingPath,
                             definition_witness: DefinitionWitness,
                             kind_witness: KindWitness,
                             path_witness: PathWitness }) :-
    grounds_inference(MetaphorId, TargetInference, GroundingPath),
    grounding_metaphor_definition_witness(MetaphorId, DefinitionWitness),
    metaphor_kind_witness(MetaphorId, KindWitness),
    grounding_path_witness(MetaphorId, TargetInference, GroundingPath, PathWitness).

grounding_path_witness(MetaphorId, _TargetInference, GroundingPath,
                       _{ kind: equivalent_result_frame,
                          metaphor_id: MetaphorId,
                          frame_name: GroundingPath,
                          frame: Frame }) :-
    equivalent_result_frame(MetaphorId, GroundingPath, Frame),
    !.
grounding_path_witness(MetaphorId, TargetInference, GroundingPath,
                       _{ kind: repair_mechanism,
                          broken_metaphor: BrokenMetaphor,
                          target_inference: TargetInference,
                          repair_metaphor: MetaphorId,
                          mechanism: GroundingPath }) :-
    metaphor_repair(BrokenMetaphor, TargetInference, MetaphorId, GroundingPath),
    !.
grounding_path_witness(MetaphorId, TargetInference, GroundingPath,
                       _{ kind: metaphor_mapping,
                          metaphor_id: MetaphorId,
                          source_concept: GroundingPath,
                          target_concept: TargetInference,
                          notes: Notes }) :-
    metaphor_mapping(MetaphorId, GroundingPath, TargetInference, Notes),
    !.
grounding_path_witness(MetaphorId, TargetInference, GroundingPath,
                       _{ kind: direct_grounding_fact,
                          metaphor_id: MetaphorId,
                          target_inference: TargetInference,
                          grounding_path: GroundingPath }).


%% ----------------------------------------------------------------------
%% Bridge to MUA layer
%%
%% Thin glue predicate. `formal/pml/mua_relations.pl` is authoritative for
%% which practice falls under which grounding metaphor. This module
%% translates the short MUA metaphor labels (e.g. `object_collection`,
%% `motion_along_path`) to the full grounding-metaphor ids used here
%% (e.g. `arithmetic_is_object_collection`,
%% `arithmetic_is_motion_along_a_path`).

%!  grounding_metaphor_for_practice(?PracticeId, ?MetaphorId) is nondet.
%
%   For any practice with a `grounding_metaphor/2` fact in
%   `formal/pml/mua_relations.pl`, returns the corresponding full metaphor id
%   from this module. Does not introduce new per-practice assignments;
%   the MUA table remains the single source of truth for those.
grounding_metaphor_for_practice(Practice, MetaphorId) :-
    mua_relations:grounding_metaphor(Practice, ShortLabel),
    mua_label_to_metaphor_id(ShortLabel, MetaphorId).

%!  grounding_metaphor_for_practice_witness(?PracticeId, ?MetaphorId, -Witness) is nondet.
%
%   Positive proof object for the MUA -> grounding-metaphor bridge. The MUA
%   short label is preserved so readers can see the exact translation step.
grounding_metaphor_for_practice_witness(Practice, MetaphorId,
                                        _{ kind: grounding_metaphor_for_practice,
                                           practice: Practice,
                                           mua_short_label: ShortLabel,
                                           metaphor_id: MetaphorId,
                                           source: pml_mua_relations_grounding_metaphor,
                                           definition_witness: DefinitionWitness,
                                           kind_witness: KindWitness }) :-
    mua_relations:grounding_metaphor(Practice, ShortLabel),
    mua_label_to_metaphor_id(ShortLabel, MetaphorId),
    grounding_metaphor_definition_witness(MetaphorId, DefinitionWitness),
    metaphor_kind_witness(MetaphorId, KindWitness).

mua_label_to_metaphor_id(object_collection,    arithmetic_is_object_collection).
mua_label_to_metaphor_id(object_construction,  arithmetic_is_object_construction).
mua_label_to_metaphor_id(measuring_stick,      arithmetic_is_measuring_stick).
mua_label_to_metaphor_id(motion_along_path,    arithmetic_is_motion_along_a_path).
mua_label_to_metaphor_id(balance_preservation_schema, balance_preservation_schema).
% no_metaphor_grounding has no metaphor id here; the lookup simply
% fails, which is the correct behaviour for the without-ground
% deformation.


%% ----------------------------------------------------------------------
%% Metaphor classification + short names (consumed by the MUDs page)
%%
%% These predicates make the basic-vs-repair distinction and the
%% display-friendly short names queryable from Prolog rather than
%% hardcoded in JavaScript. The export script reads them through and
%% emits `kind` and `short_name` fields on each metaphor in
%% `more-zeeman/mua_data.json`. Adding a new metaphor to
%% `grounding_metaphor_definition/4` should be accompanied by a fact
%% here so the MUDs page picks it up without further JS edits.

%!  metaphor_kind(?MetaphorId, ?Kind) is nondet.
%
%   Kind is one of `basic` (the four canonical L&N grounding metaphors)
%   or `repair` (a metaphor introduced specifically to preserve closure
%   of a target inference some basic metaphor cannot ground).
%   Derivation: a metaphor is a `repair` if and only if it appears as
%   the third argument of any `metaphor_repair/4` fact AND is not the
%   sentinel `none_in_this_metaphor`. Otherwise it is `basic`.
metaphor_kind(balance_preservation_schema, schema).
metaphor_kind(MetaphorId, Kind) :-
    ln_metaphor_kind(MetaphorId, Kind).
metaphor_kind(MetaphorId, Kind) :-
    grounding_metaphor_definition(MetaphorId, _, _, _),
    MetaphorId \== none_in_this_metaphor,
    MetaphorId \== balance_preservation_schema,
    \+ ln_metaphor_kind(MetaphorId, _),
    ( metaphor_repair(_, _, MetaphorId, _)
    -> Kind = repair
    ;  Kind = basic
    ).

grounding_metaphor_definition_witness(MetaphorId,
                                      _{ kind: grounding_metaphor_definition,
                                         metaphor_id: MetaphorId,
                                         source_domain: SourceDomain,
                                         target_domain: TargetDomain,
                                         description: Description,
                                         source: Source }) :-
    ( base_grounding_metaphor_definition(MetaphorId, SourceDomain, TargetDomain, Description)
    -> Source = base_grounding_metaphors
    ;  ln_metaphor(MetaphorId, SourceDomain, TargetDomain, Description),
       Source = grounding_metaphors_extended
    ).

metaphor_kind_witness(MetaphorId,
                      _{ kind: metaphor_kind,
                         metaphor_id: MetaphorId,
                         metaphor_kind: Kind,
                         source: Source }) :-
    metaphor_kind(MetaphorId, Kind),
    ( ln_metaphor_kind(MetaphorId, Kind)
    -> Source = grounding_metaphors_extended
    ;  Source = repair_rule_or_basic_default
    ).


% -- Extension helpers
%!  bmi_specialization(?SpecializationId, ?IterativeProcessDescription, ?LocationAtom) is nondet.
bmi_specialization(SpecializationId, ProcessDesc, LocationAtom) :-
    ln_bmi_specialization(SpecializationId, ProcessDesc, LocationAtom).

%!  metaphor_citation(?MetaphorId, ?CitationAtom) is nondet.
metaphor_citation(MetaphorId, CitationAtom) :-
    ln_metaphor_citation(MetaphorId, CitationAtom).


%!  metaphor_short_name(?MetaphorId, ?ShortName) is det.
%
%   Display-friendly short name for the MUDs page. Falls back to the
%   id with underscores replaced by spaces when no explicit fact is
%   registered, which is the right default for new metaphors that
%   have not yet been given a short name.
metaphor_short_name(arithmetic_is_object_collection,    'Object Collection').
metaphor_short_name(arithmetic_is_object_construction,  'Object Construction').
metaphor_short_name(arithmetic_is_measuring_stick,      'Measuring Stick').
metaphor_short_name(arithmetic_is_motion_along_a_path,  'Motion Along a Path').
metaphor_short_name(balance_preservation_schema,         'Balance Preservation').
metaphor_short_name(multiplication_by_minus_one_is_rotation_by_180_degrees,
                    'Multiplication by -1 is Rotation by 180 degrees').
metaphor_short_name(zero_collection_metaphor,           'Zero Collection').
metaphor_short_name(zero_object_metaphor,               'Zero Object').
metaphor_short_name(MetaphorId, ShortName) :-
    grounding_metaphor_definition(MetaphorId, _, _, _),
    \+ has_explicit_short_name(MetaphorId),
    atom_string(MetaphorId, IdStr),
    re_replace("_"/g, " ", IdStr, ShortName).

has_explicit_short_name(arithmetic_is_object_collection).
has_explicit_short_name(arithmetic_is_object_construction).
has_explicit_short_name(arithmetic_is_measuring_stick).
has_explicit_short_name(arithmetic_is_motion_along_a_path).
has_explicit_short_name(balance_preservation_schema).
has_explicit_short_name(multiplication_by_minus_one_is_rotation_by_180_degrees).
has_explicit_short_name(zero_collection_metaphor).
has_explicit_short_name(zero_object_metaphor).
