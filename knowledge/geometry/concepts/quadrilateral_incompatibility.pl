% concepts/quadrilateral_incompatibility.pl
%
% Queryable quadrilateral material inference via incompatibility.
%
% The rest of the geometry KB has many material_inference/4 records that are
% useful as human-readable commitments. This file adds the closed-world finite
% quadrilateral restriction table: a shape concept is inferentially stronger
% when it rejects a superset of the restrictions rejected by another shape
% concept. The witness predicates expose the restriction profiles that make
% the finite entailment or incompatibility hold.
%
% This mirrors the older formalization engine's axioms_geometry.pl, but keeps
% the contract local to the geometry KB consumed by discourse tooling and Hermes.

:- multifile material_inference/4.
:- discontiguous material_inference/4.

% Restrictions are phrased as the "hard no" properties a shape rejects.
quad_restriction(no_sides_equal,
    "No sides are equal").
quad_restriction(no_adjacent_sides_equal,
    "No pair of adjacent sides are equal").
quad_restriction(no_opposite_sides_equal,
    "No pair of opposite sides are equal").
quad_restriction(non_parallel_sides_not_congruent,
    "Non-parallel sides are not congruent").
quad_restriction(no_opposite_sides_parallel,
    "No pair of opposite sides are parallel").
quad_restriction(no_right_angles,
    "No angles are right angles").

quad_shape(quadrilateral, "Quadrilateral").
quad_shape(trapezoid, "Trapezoid").
quad_shape(parallelogram, "Parallelogram").
quad_shape(rectangle, "Rectangle").
quad_shape(rhombus, "Rhombus").
quad_shape(kite, "Kite").
quad_shape(square, "Square").

quad_shape(Shape) :-
    quad_shape(Shape, _).

% quad_rejects(+Shape, +Restriction)
%
% A fact means the shape is materially incompatible with that restriction.
% Example: square rejects no_right_angles, so a square commitment rules out a
% no-right-angles commitment.
quad_rejects(square, no_sides_equal).
quad_rejects(rectangle, no_sides_equal).
quad_rejects(rhombus, no_sides_equal).
quad_rejects(parallelogram, no_sides_equal).
quad_rejects(kite, no_sides_equal).

quad_rejects(square, no_adjacent_sides_equal).
quad_rejects(rhombus, no_adjacent_sides_equal).
quad_rejects(kite, no_adjacent_sides_equal).

quad_rejects(square, no_opposite_sides_equal).
quad_rejects(rectangle, no_opposite_sides_equal).
quad_rejects(rhombus, no_opposite_sides_equal).
quad_rejects(parallelogram, no_opposite_sides_equal).

quad_rejects(square, non_parallel_sides_not_congruent).
quad_rejects(rhombus, non_parallel_sides_not_congruent).
quad_rejects(kite, non_parallel_sides_not_congruent).

quad_rejects(square, no_opposite_sides_parallel).
quad_rejects(rectangle, no_opposite_sides_parallel).
quad_rejects(rhombus, no_opposite_sides_parallel).
quad_rejects(parallelogram, no_opposite_sides_parallel).
quad_rejects(trapezoid, no_opposite_sides_parallel).

quad_rejects(square, no_right_angles).
quad_rejects(rectangle, no_right_angles).

quad_rejections_witness(Shape,
                        WitnessDict77) :-
    witness_dict:witness_dict(quadrilateral_rejection_profile, closed_world_finite_quadrilateral_restriction_table,
                              _{shape: Shape,
                           label: Label,
                           rejections: Restrictions,
                           rejected_restriction_witnesses: RejectionWitnesses }, WitnessDict77),
    quad_shape(Shape),
    quad_shape(Shape, Label),
    findall(R, quad_rejects(Shape, R), Raw),
    sort(Raw, Restrictions),
    findall(Witness,
            ( member(Restriction, Restrictions),
              quad_restriction(Restriction, RestrictionLabel),
              Witness = _{ kind: quadrilateral_rejected_restriction,
                           shape: Shape,
                           restriction: Restriction,
                           label: RestrictionLabel,
                           fact: quad_rejects(Shape, Restriction) }
            ),
            RejectionWitnesses).

quad_strength_witness(Shape,
                      Strength,
                      WitnessDict100) :-
    witness_dict:witness_dict(quadrilateral_strength, closed_world_finite_quadrilateral_restriction_table,
                              _{shape: Shape,
                         strength: Strength,
                         rejections_witness: RejectionsWitness }, WitnessDict100),
    quad_rejections_witness(Shape, RejectionsWitness),
    get_dict(rejections, RejectionsWitness, Restrictions),
    length(Restrictions, Strength).

quad_entails(P, Q) :-
    quad_entails_witness(P, Q, _).

quad_entails_witness(P, Q, Witness) :-
    witness_dict:witness_dict(quadrilateral_entailment, closed_world_finite_quadrilateral_restriction_table,
                              _{entailer: P,
                 entailed: Q,
                 reason: Reason,
                 required_rejections: Required,
                 proving_rejections: Proving,
                 missing_rejections: Missing,
                 extra_rejections: Extra,
                 entailer_witness: ProvingWitness,
                 entailed_witness: RequiredWitness }, WitnessDict132),
    quad_shape(P),
    quad_shape(Q),
    quad_rejections_witness(P, ProvingWitness),
    quad_rejections_witness(Q, RequiredWitness),
    get_dict(rejections, ProvingWitness, Proving),
    get_dict(rejections, RequiredWitness, Required),
    (   P == Q
    ->  Reason = same_shape,
        Missing = [],
        ord_subtract(Proving, Required, Extra)
    ;   Q == quadrilateral
    ->  Reason = quadrilateral_base_shape,
        Missing = [],
        ord_subtract(Proving, Required, Extra)
    ;   ord_subset(Required, Proving)
    ->  Reason = all_required_rejections_present,
        Missing = [],
        ord_subtract(Proving, Required, Extra)
    ),
    Witness = WitnessDict132.

quad_non_entailment_witness(P,
                            Q,
                            WitnessDict146) :-
    witness_dict:witness_dict(quadrilateral_non_entailment, closed_world_finite_quadrilateral_restriction_table,
                              _{candidate_entailer: P,
                               candidate_entailed: Q,
                               relation: Relation,
                               required_rejections: Required,
                               proving_rejections: Proving,
                               missing_rejections: Missing,
                               candidate_entailer_witness: ProvingWitness,
                               candidate_entailed_witness: RequiredWitness }, WitnessDict146),
    quad_shape(P),
    quad_shape(Q),
    quad_rejections_witness(P, ProvingWitness),
    quad_rejections_witness(Q, RequiredWitness),
    get_dict(rejections, ProvingWitness, Proving),
    get_dict(rejections, RequiredWitness, Required),
    findall(R, (member(R, Required), \+ memberchk(R, Proving)), Missing0),
    sort(Missing0, Missing),
    Missing \== [],
    (   quad_entails(Q, P)
    ->  Relation = invalid_converse
    ;   Relation = independent_or_cross_cutting
    ).

quad_incompatible_with(Shape, Restriction) :-
    quad_incompatible_with_witness(Shape, Restriction, _).

quad_incompatible_with_witness(Shape,
                               Restriction,
                               WitnessDict175) :-
    witness_dict:witness_dict(quadrilateral_incompatibility, closed_world_finite_quadrilateral_restriction_table,
                              _{shape: Shape,
                                  restriction: Restriction,
                                  restriction_label: RestrictionLabel,
                                  reason: shape_rejects_restriction,
                                  shape_rejections: Rejections,
                                  shape_witness: ShapeWitness,
                                  fact: quad_rejects(Shape, Restriction) }, WitnessDict175),
    quad_shape(Shape),
    quad_restriction(Restriction, RestrictionLabel),
    quad_rejects(Shape, Restriction),
    quad_rejections_witness(Shape, ShapeWitness),
    get_dict(rejections, ShapeWitness, Rejections).

quad_inference_witness(P,
                       Q,
                       inference(P, Q, entitled, Detail),
                       WitnessDict193) :-
    witness_dict:witness_dict(quadrilateral_inference, closed_world_finite_quadrilateral_restriction_table,
                              _{status: entitled,
                          entailer: P,
                          entailed: Q,
                          detail: Detail,
                          entailment_witness: EntailmentWitness }, WitnessDict193),
    quad_entails_witness(P, Q, EntailmentWitness),
    quad_strength_witness(P, SP, _),
    quad_strength_witness(Q, SQ, _),
    get_dict(proving_rejections, EntailmentWitness, PR),
    get_dict(required_rejections, EntailmentWitness, QR),
    Detail = detail(
        strength(P, SP),
        strength(Q, SQ),
        rejects(P, PR),
        rejects(Q, QR),
        because(P, rejects_everything_rejected_by(Q))
    ).
quad_inference_witness(P,
                       Q,
                       inference(P, Q, not_entitled, Detail),
                       WitnessDict215) :-
    witness_dict:witness_dict(quadrilateral_inference, closed_world_finite_quadrilateral_restriction_table,
                              _{status: not_entitled,
                          candidate_entailer: P,
                          candidate_entailed: Q,
                          detail: Detail,
                          entailment_failure_witness: FailureWitness }, WitnessDict215),
    quad_non_entailment_witness(P, Q, FailureWitness),
    quad_strength_witness(P, SP, _),
    quad_strength_witness(Q, SQ, _),
    get_dict(proving_rejections, FailureWitness, PR),
    get_dict(required_rejections, FailureWitness, QR),
    get_dict(missing_rejections, FailureWitness, Missing),
    get_dict(relation, FailureWitness, Relation),
    Detail = detail(
        relation(Relation),
        strength(P, SP),
        strength(Q, SQ),
        rejects(P, PR),
        rejects(Q, QR),
        missing_rejections(Missing)
    ).

% Computed material_inference/4 clauses for consumers that already query the
% KB's material-inference relation.
material_inference(quadrilateral_hierarchy,
    shape(X, P),
    shape(X, Q),
    entitled) :-
    quad_entails_witness(P, Q, _),
    P \== Q.

material_inference(quadrilateral_hierarchy,
    shape(X, P),
    neg(shape(X, Q)),
    incompatible) :-
    quad_entails_witness(P, Q, _),
    P \== Q.

material_inference(quadrilateral_incompatibility,
    shape(X, Shape),
    restriction(X, Restriction),
    incompatible) :-
    quad_incompatible_with_witness(Shape, Restriction, _).
