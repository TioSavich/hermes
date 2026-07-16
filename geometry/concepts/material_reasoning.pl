% concepts/material_reasoning.pl
%
% Generic query predicates over material_inference/4.
%
% Most geometry files record material inferences as facts. The predicates below
% make those facts inspectable as entitlement/rejection profiles, so callers can
% ask where a concept licenses commitments, where it blocks commitments, and
% where two coded commitments meet at a boundary incompatibility.

material_concepts(Concepts) :-
    material_concepts_witness(Witness),
    get_dict(concepts, Witness, Concepts).

material_concepts_witness(_{ kind: material_concepts,
                             scope: closed_world_finite_geometry_kb,
                             concepts: Concepts }) :-
    findall(Concept,
            material_inference(Concept, _Premise, _Conclusion, _Polarity),
            Raw),
    sort(Raw, Concepts).

canonicalize_terms(Raw, Canonical) :-
    findall(Copy,
            ( member(Term, Raw),
              copy_term(Term, Copy),
              numbervars(Copy, 0, _)
            ),
            Numbered),
    sort(Numbered, Canonical).

material_commitments(Concept, Polarity, Commitments) :-
    material_commitments_witness(Concept, Polarity, Witness),
    get_dict(commitments, Witness, Commitments).

material_commitments_witness(Concept,
                             Polarity,
                             _{ kind: material_commitments,
                                scope: closed_world_finite_geometry_kb,
                                concept: Concept,
                                polarity: Polarity,
                                commitments: Commitments,
                                supporting_inferences: SupportingInferences }) :-
    findall(commitment(Premise, Conclusion),
            material_inference(Concept, Premise, Conclusion, Polarity),
            RawCommitments),
    canonicalize_terms(RawCommitments, Commitments),
    findall(material_inference(Concept, Premise, Conclusion, Polarity),
            material_inference(Concept, Premise, Conclusion, Polarity),
            RawInferences),
    canonicalize_terms(RawInferences, SupportingInferences).

material_inference_strength(Concept,
    strength(Concept, entitled(EntitledCount), incompatible(IncompatibleCount), total(Total))) :-
    material_inference_strength_witness(Concept, Strength, _),
    Strength = strength(Concept, entitled(EntitledCount), incompatible(IncompatibleCount), total(Total)).

material_inference_strength_witness(Concept,
                                    strength(Concept,
                                             entitled(EntitledCount),
                                             incompatible(IncompatibleCount),
                                             total(Total)),
                                    _{ kind: material_inference_strength,
                                       scope: closed_world_finite_geometry_kb,
                                       concept: Concept,
                                       entitled_count: EntitledCount,
                                       incompatible_count: IncompatibleCount,
                                       total: Total,
                                       entitled_witness: EntitledWitness,
                                       incompatible_witness: IncompatibleWitness }) :-
    material_commitments_witness(Concept, entitled, EntitledWitness),
    material_commitments_witness(Concept, incompatible, IncompatibleWitness),
    get_dict(commitments, EntitledWitness, Entitled),
    get_dict(commitments, IncompatibleWitness, Incompatible),
    length(Entitled, EntitledCount),
    length(Incompatible, IncompatibleCount),
    Total is EntitledCount + IncompatibleCount.

material_inference_profile(Concept,
    profile(Concept, Strength, entitled(Entitled), incompatible(Incompatible), boundaries(Boundaries))) :-
    material_inference_profile_witness(Concept,
                                       profile(Concept,
                                               Strength,
                                               entitled(Entitled),
                                               incompatible(Incompatible),
                                               boundaries(Boundaries)),
                                       _).

material_inference_profile_witness(Concept,
                                   profile(Concept,
                                           Strength,
                                           entitled(Entitled),
                                           incompatible(Incompatible),
                                           boundaries(Boundaries)),
                                   _{ kind: material_inference_profile,
                                      scope: closed_world_finite_geometry_kb,
                                      concept: Concept,
                                      strength_witness: StrengthWitness,
                                      entitled_witness: EntitledWitness,
                                      incompatible_witness: IncompatibleWitness,
                                      boundary_witnesses: BoundaryWitnesses }) :-
    material_inference_strength_witness(Concept, Strength, StrengthWitness),
    material_commitments_witness(Concept, entitled, EntitledWitness),
    material_commitments_witness(Concept, incompatible, IncompatibleWitness),
    get_dict(commitments, EntitledWitness, Entitled),
    get_dict(commitments, IncompatibleWitness, Incompatible),
    material_boundaries_for_witness(Concept, Boundaries, BoundaryWitnesses).

material_opposes_witness(neg(Term),
                         Term,
                         _{ kind: material_opposition,
                            source: explicit_negation_pair,
                            negative: neg(Term),
                            positive: Term }) :-
    !.
material_opposes_witness(Term,
                         neg(Term),
                         _{ kind: material_opposition,
                            source: explicit_negation_pair,
                            positive: Term,
                            negative: neg(Term) }).

same_or_opposed_commitment_witness(Conclusion,
                                   Conclusion,
                                   same_conclusion,
                                   _{ kind: material_same_conclusion,
                                      source: identical_conclusion,
                                      conclusion: Conclusion }).
same_or_opposed_commitment_witness(ConclusionA,
                                   ConclusionB,
                                   opposed_conclusion,
                                   Witness) :-
    material_opposes_witness(ConclusionA, ConclusionB, Witness).

material_boundary(ConceptA, ConceptB,
                  boundary(EntitledConcept,
                           IncompatibleConcept,
                           Premise,
                           EntitledConclusion,
                           IncompatibleConclusion,
                           Relation)) :-
    material_boundary_witness(ConceptA,
                              ConceptB,
                              boundary(EntitledConcept,
                                       IncompatibleConcept,
                                       Premise,
                                       EntitledConclusion,
                                       IncompatibleConclusion,
                                       Relation),
                              _).

material_boundary_witness(ConceptA,
                          ConceptB,
                          boundary(ConceptA,
                                   ConceptB,
                                   Premise,
                                   ConclusionA,
                                   ConclusionB,
                                   Relation),
                          Witness) :-
    material_inference(ConceptA, Premise, ConclusionA, entitled),
    material_inference(ConceptB, Premise, ConclusionB, incompatible),
    same_or_opposed_commitment_witness(ConclusionA, ConclusionB, Relation, RelationWitness),
    material_boundary_witness_term(ConceptA,
                                   ConceptB,
                                   Premise,
                                   ConclusionA,
                                   ConclusionB,
                                   Relation,
                                   RelationWitness,
                                   Witness).

material_boundary_witness(ConceptA,
                          ConceptB,
                          boundary(ConceptB,
                                   ConceptA,
                                   Premise,
                                   ConclusionB,
                                   ConclusionA,
                                   Relation),
                          Witness) :-
    material_inference(ConceptA, Premise, ConclusionA, incompatible),
    material_inference(ConceptB, Premise, ConclusionB, entitled),
    same_or_opposed_commitment_witness(ConclusionB, ConclusionA, Relation, RelationWitness),
    material_boundary_witness_term(ConceptB,
                                   ConceptA,
                                   Premise,
                                   ConclusionB,
                                   ConclusionA,
                                   Relation,
                                   RelationWitness,
                                   Witness).

material_boundary_witness_term(EntitledConcept,
                               IncompatibleConcept,
                               Premise,
                               EntitledConclusion,
                               IncompatibleConclusion,
                               Relation,
                               RelationWitness,
                               _{ kind: material_boundary,
                                  scope: closed_world_finite_geometry_kb,
                                  entitled_concept: EntitledConcept,
                                  incompatible_concept: IncompatibleConcept,
                                  premise: Premise,
                                  entitled_conclusion: EntitledConclusion,
                                  incompatible_conclusion: IncompatibleConclusion,
                                  relation: Relation,
                                  relation_witness: RelationWitness,
                                  entitled_fact: material_inference(EntitledConcept,
                                                                    Premise,
                                                                    EntitledConclusion,
                                                                    entitled),
                                  incompatible_fact: material_inference(IncompatibleConcept,
                                                                        Premise,
                                                                        IncompatibleConclusion,
                                                                        incompatible) }).

material_boundaries_for(Concept, Boundaries) :-
    material_boundaries_for_witness(Concept, Boundaries, _).

material_boundaries_for_witness(Concept, Boundaries, BoundaryWitnesses) :-
    nonvar(Concept),
    !,
    findall(Boundary-Witness,
            material_boundary_witness(Concept, _Other, Boundary, Witness),
            RawPairs),
    findall(Boundary,
            member(Boundary-_Witness, RawPairs),
            RawBoundaries),
    canonicalize_terms(RawBoundaries, Boundaries),
    findall(Witness,
            member(_Boundary-Witness, RawPairs),
            RawWitnesses),
    canonicalize_terms(RawWitnesses, BoundaryWitnesses).
material_boundaries_for_witness(Concept, Boundaries, BoundaryWitnesses) :-
    material_concepts(Concepts),
    findall(Boundary-Witness,
            ( member(Other, Concepts),
              material_boundary_witness(Concept, Other, Boundary, Witness)
            ),
            RawPairs),
    findall(Boundary,
            member(Boundary-_Witness, RawPairs),
            RawBoundaries),
    canonicalize_terms(RawBoundaries, Boundaries),
    findall(Witness,
            member(_Boundary-Witness, RawPairs),
            RawWitnesses),
    canonicalize_terms(RawWitnesses, BoundaryWitnesses).

material_boundary_summary(Summary) :-
    material_boundary_summary_witness(Summary, _).

material_boundary_summary_witness(Summary,
                                  _{ kind: material_boundary_summary,
                                     scope: closed_world_finite_geometry_kb,
                                     summary: Summary,
                                     concept_witnesses: ConceptWitnesses }) :-
    material_concepts(Concepts),
    findall(Concept-BoundaryCount-Witness,
            ( member(Concept, Concepts),
              material_boundaries_for_witness(Concept, Boundaries, BoundaryWitnesses),
              length(Boundaries, BoundaryCount),
              BoundaryCount > 0,
              Witness = _{ kind: material_boundary_count,
                           scope: closed_world_finite_geometry_kb,
                           concept: Concept,
                           boundary_count: BoundaryCount,
                           boundary_witnesses: BoundaryWitnesses }
            ),
            Pairs),
    findall(Concept-BoundaryCount,
            member(Concept-BoundaryCount-_Witness, Pairs),
            Summary),
    findall(Witness,
            member(_Concept-_BoundaryCount-Witness, Pairs),
            ConceptWitnesses).
