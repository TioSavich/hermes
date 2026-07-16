% ===================================================================
% Geometry Axioms — Quadrilateral taxonomy via incompatibility
% ===================================================================
%
% These axioms establish geometric knowledge through a closed-world finite
% incompatibility profile: within this table of quadrilateral restrictions, a
% shape's identity is determined by what it EXCLUDES, not what it contains. A
% square is not defined here by "four equal sides and right angles" but by its
% incompatibility with the finite restriction set that lacks those properties.
%
% Boundary: incompatibility entailment is not globally computable in an open
% geometry universe. This file is the finite quadrilateral-hierarchy case: the
% shapes and restriction hyperedges listed below are the complete domain for
% `entails_via_incompatibility/2`.
%
% Interpretive correspondence: this material may be read alongside
% Carspecken's Scene One (Form and the Flux), where recognizable
% form emerges from a chaotic background through the act of
% perception. Geometric entailment via incompatibility is one
% formal reconstruction of how determinate shape-concepts arise.
% ===================================================================

% --- Geometric Restrictions (what a shape EXCLUDES) ---
% R1: No sides of X are equal
% R2: No pair of adjacent sides of X are equal
% R3: No pair of opposite sides of X are equal
% R4: Non-parallel sides of X are not congruent (isosceles trapezoid property)
% R5: No pair of opposite sides of X are parallel
% R6: No angles of X are right angles
%
% A 1 in Table 4 (manuscript §4) means the shape rejects that restriction.
% Inferential strength = number of restrictions rejected.
% square: rejects all six (strongest)
% trapezoid: rejects only R5 (weakest non-trivial)

% Reader's rule of thumb:
%   - incompatible_pair(Shape, Restriction) says Shape rejects a restriction.
%   - entails_via_incompatibility(P, Q) says P entails Q only when P rejects
%     every restriction Q rejects.
%   - entails_via_incompatibility_witness/3 returns the compared restriction
%     profiles, so the entailment is inspectable rather than merely declared.

% --- Incompatibility Pairs ---
% Each pair asserts that a shape is materially incompatible with
% a restriction. r1-r6 represent geometric properties whose
% absence distinguishes shapes from one another.

incompatible_pair(square, r1). incompatible_pair(rectangle, r1). incompatible_pair(rhombus, r1). incompatible_pair(parallelogram, r1). incompatible_pair(kite, r1).
incompatible_pair(square, r2). incompatible_pair(rhombus, r2). incompatible_pair(kite, r2).
incompatible_pair(square, r3). incompatible_pair(rectangle, r3). incompatible_pair(rhombus, r3). incompatible_pair(parallelogram, r3).
incompatible_pair(square, r4). incompatible_pair(rhombus, r4). incompatible_pair(kite, r4).
incompatible_pair(square, r5). incompatible_pair(rectangle, r5). incompatible_pair(rhombus, r5). incompatible_pair(parallelogram, r5). incompatible_pair(trapezoid, r5).
incompatible_pair(square, r6). incompatible_pair(rectangle, r6).

is_shape(S) :- (incompatible_pair(S, _); S = quadrilateral), !.

shape_rejections(quadrilateral, []) :- !.
shape_rejections(Shape, Rejections) :-
    is_shape(Shape),
    findall(R, incompatible_pair(Shape, R), Rs0),
    sort(Rs0, Rejections).

missing_rejections(Required, Proving, Missing) :-
    findall(R, (member(R, Required), \+ memberchk(R, Proving)), Missing0),
    sort(Missing0, Missing).

entails_via_incompatibility(P, Q) :-
    entails_via_incompatibility_witness(P, Q, _).

entails_via_incompatibility_witness(P, Q,
                                    _{kind: geometry_entailment,
                                      source: reflexive_identity,
                                      entailer: P,
                                      entailed: Q,
                                      required_rejections: Rejections,
                                      proving_rejections: Rejections,
                                      missing_rejections: []}) :-
    is_shape(P),
    P == Q,
    shape_rejections(P, Rejections),
    !.
entails_via_incompatibility_witness(P, quadrilateral,
                                    _{kind: geometry_entailment,
                                      source: quadrilateral_top,
                                      entailer: P,
                                      entailed: quadrilateral,
                                      required_rejections: [],
                                      proving_rejections: ProvingRejections,
                                      missing_rejections: []}) :-
    is_shape(P),
    shape_rejections(P, ProvingRejections),
    !.
entails_via_incompatibility_witness(P, Q,
                                    _{kind: geometry_entailment,
                                      source: incompatibility_profile_subset,
                                      entailer: P,
                                      entailed: Q,
                                      required_rejections: Required,
                                      proving_rejections: Proving,
                                      missing_rejections: []}) :-
    is_shape(P),
    is_shape(Q),
    Q \== quadrilateral,
    shape_rejections(Q, Required),
    shape_rejections(P, Proving),
    missing_rejections(Required, Proving, []),
    !.

geometric_predicates([square, rectangle, rhombus, parallelogram, trapezoid, kite, quadrilateral, r1, r2, r3, r4, r5, r6]).

% --- Geometric Incoherence ---
is_incoherent(X) :-
    axiom_pack_enabled(geometry),
    member(n(ShapePred), X), ShapePred =.. [Shape, V],
    member(n(RestrictionPred), X), RestrictionPred =.. [Restriction, V],
    ground(Shape), ground(Restriction),
    incompatible_pair(Shape, Restriction), !.

% --- Geometric Entailment (Structural Rule) ---
proves_impl((Premises => Conclusions), _) :-
    axiom_pack_enabled(geometry),
    member(n(P_pred), Premises), P_pred =.. [P_shape, X], is_shape(P_shape),
    member(n(Q_pred), Conclusions), Q_pred =.. [Q_shape, X], is_shape(Q_shape),
    entails_via_incompatibility(P_shape, Q_shape), !.
