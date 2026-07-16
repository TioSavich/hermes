:- module(hermes_pair_scoring, [
    score_pair_candidates/2,
    pair_candidate_witness/3,
    safe_question_move/2,
    question_move_score/2,
    pair_graph/2
]).

:- use_module(library(lists)).
:- use_module(event_scoring).

/** <module> Research-safe Hermes pair scoring.

This module scores pairs from already-structured canonical events. Pair output
is designed for GUI orchestration: it includes handles, pseudonyms, reasons,
and question-move metadata, but never raw student work, actor identifiers, or
source paths.
*/

score_pair_candidates(Events, Pairs) :-
    include(pairable_event, Events, PairableEvents),
    findall(
        Score-Pair,
        pair_score(PairableEvents, Score, Pair),
        ScoredPairs
    ),
    sort(1, @>=, ScoredPairs, Sorted),
    pairs_values(Sorted, Pairs).

pairable_event(Event) :-
    score_event(Event, Score),
    get_dict(reconstructive_findings, Score, Reconstructive),
    get_dict(action, Reconstructive, Action),
    Action \= quarantine.

pair_score(Events, Score, Pair) :-
    append(_, [EventA|AfterA], Events),
    member(EventB, AfterA),
    safe_pair_candidate(EventA, EventB, Pair),
    get_dict(score, Pair, Score),
    Score > 0.

safe_pair_candidate(EventA, EventB, Pair) :-
    pair_candidate_witness(EventA, EventB, Witness),
    pair_from_witness(Witness, Pair).

%!  pair_candidate_witness(+EventA, +EventB, -Witness) is semidet.
%
%   Research-safe proof object for a proposed pair. The witness exposes which
%   event fields support each reason and derives the score from reason points.
%   It keeps the same privacy boundary as the public pair: event ids,
%   pseudonyms, roles, reason metadata, and question metadata only.
pair_candidate_witness(EventA, EventB,
                       _{ kind: pair_candidate,
                          pair_id: PairId,
                          event_a: IdA,
                          event_b: IdB,
                          pseudonym_a: PseudonymA,
                          pseudonym_b: PseudonymB,
                          roles: [RoleA, RoleB],
                          score: Score,
                          reason_witnesses: ReasonWitnesses,
                          question_moves: Moves,
                          research_safety:
                            _{ omits: [student_text_payload,
                                       private_person_key,
                                       origin_record_key,
                                       filesystem_location],
                               exposes: [event_ids, pseudonyms, roles, reason_metadata, question_metadata] } }) :-
    event_atom_id(EventA, IdA),
    event_atom_id(EventB, IdB),
    pair_id(IdA, IdB, PairId),
    actor_public_view(EventA, RoleA, PseudonymA),
    actor_public_view(EventB, RoleB, PseudonymB),
    pair_reason_witnesses(EventA, EventB, ReasonWitnesses),
    ReasonWitnesses \= [],
    reason_witness_score(ReasonWitnesses, Score),
    pair_question_moves(EventA, EventB, Moves).

pair_from_witness(Witness, Pair) :-
    reason_terms(Witness.reason_witnesses, Reasons),
    Pair = _{
        pair_id: Witness.pair_id,
        event_a: Witness.event_a,
        event_b: Witness.event_b,
        pseudonym_a: Witness.pseudonym_a,
        pseudonym_b: Witness.pseudonym_b,
        roles: Witness.roles,
        score: Witness.score,
        reasons: Reasons,
        question_moves: Witness.question_moves
    }.

reason_terms([], []).
reason_terms([Witness|Witnesses], [Reason|Reasons]) :-
    Reason = Witness.reason,
    reason_terms(Witnesses, Reasons).

event_atom_id(Event, Id) :-
    event_id(Event, IdString),
    atom_string(Id, IdString).

pair_id(IdA, IdB, PairId) :-
    atomic_list_concat([pair, IdA, IdB], '_', PairId).

actor_public_view(Event, Role, Pseudonym) :-
    get_dict(actor, Event, Actor),
    get_dict(role, Actor, Role),
    get_dict(pseudonym, Actor, Pseudonym).

pair_reason_witnesses(EventA, EventB, Witnesses) :-
    findall(Reason-Witness,
            pair_reason_witness(EventA, EventB, Reason, Witness),
            RawWitnesses),
    keysort(RawWitnesses, Sorted),
    unique_reason_witnesses(Sorted, Witnesses).

unique_reason_witnesses([], []).
unique_reason_witnesses([Reason-Witness|Rest], [Witness|Witnesses]) :-
    drop_reason(Reason, Rest, Remaining),
    unique_reason_witnesses(Remaining, Witnesses).

drop_reason(Reason, [Reason-_|Rest], Remaining) :-
    !,
    drop_reason(Reason, Rest, Remaining).
drop_reason(_, Rest, Rest).

pair_reason_witness(EventA, EventB, shared_domain(Domain),
                    _{ kind: shared_domain,
                       reason: shared_domain(Domain),
                       domain: Domain,
                       event_a_domain: Domain,
                       event_b_domain: Domain,
                       points: Points }) :-
    event_domain(EventA, Domain),
    event_domain(EventB, Domain),
    reason_points(shared_domain(Domain), Points).
pair_reason_witness(EventA, EventB, shared_topic(Topic),
                    _{ kind: shared_topic,
                       reason: shared_topic(Topic),
                       topic: Topic,
                       event_a_topic: Topic,
                       event_b_topic: Topic,
                       points: Points }) :-
    event_topic(EventA, Topic),
    event_topic(EventB, Topic),
    reason_points(shared_topic(Topic), Points).
pair_reason_witness(EventA, EventB, pml_polarity_contrast,
                    _{ kind: pml_polarity_contrast,
                       reason: pml_polarity_contrast,
                       polarity_a: PolarityA,
                       polarity_b: PolarityB,
                       points: Points }) :-
    event_polarity(EventA, PolarityA),
    event_polarity(EventB, PolarityB),
    PolarityA \= PolarityB,
    reason_points(pml_polarity_contrast, Points).
pair_reason_witness(EventA, EventB, repair_affordance,
                    _{ kind: repair_affordance,
                       reason: repair_affordance,
                       source_event: SourceEvent,
                       evidence: Evidence,
                       points: Points }) :-
    pair_repair_affordance_witness(EventA, EventB, SourceEvent, Evidence),
    reason_points(repair_affordance, Points).
pair_reason_witness(EventA, EventB, shared_validity_register(Register),
                    _{ kind: shared_validity_register,
                       reason: shared_validity_register(Register),
                       validity_register: Register,
                       points: Points }) :-
    event_validity_register(EventA, Register),
    event_validity_register(EventB, Register),
    reason_points(shared_validity_register(Register), Points).
pair_reason_witness(EventA, EventB, recognition_balance,
                    _{ kind: recognition_balance,
                       reason: recognition_balance,
                       risk_a: RiskA,
                       risk_b: RiskB,
                       points: Points }) :-
    recognition_risk(EventA, RiskA),
    recognition_risk(EventB, RiskB),
    RiskA \= RiskB,
    reason_points(recognition_balance, Points).
pair_reason_witness(EventA, EventB, shared_material_inference_handle(Handle),
                    _{ kind: shared_material_inference_handle,
                       reason: shared_material_inference_handle(Handle),
                       handle: Handle,
                       points: Points }) :-
    material_inference_handle_id(EventA, Handle),
    material_inference_handle_id(EventB, Handle),
    reason_points(shared_material_inference_handle(Handle), Points).

pair_repair_affordance_witness(EventA, _EventB, SourceEvent, Evidence) :-
    event_atom_id(EventA, SourceEvent),
    repair_affordance_evidence(EventA, Evidence),
    !.
pair_repair_affordance_witness(_EventA, EventB, SourceEvent, Evidence) :-
    event_atom_id(EventB, SourceEvent),
    repair_affordance_evidence(EventB, Evidence).

repair_affordance_evidence(Event, _{kind: missing_requirements,
                                    missing_requirements: Missing}) :-
    event_missing_requirements(Event, Missing),
    Missing \= [],
    !.
repair_affordance_evidence(Event, _{kind: incompatibilities,
                                    incompatibilities: Incompatibilities}) :-
    event_incompatibilities(Event, Incompatibilities),
    Incompatibilities \= [].

event_domain(Event, Domain) :-
    get_dict(source, Event, Source),
    get_dict(metadata, Source, Metadata),
    get_dict(domain, Metadata, Domain).

event_topic(Event, Topic) :-
    get_dict(source, Event, Source),
    get_dict(metadata, Source, Metadata),
    get_dict(topic, Metadata, Topic).

event_polarity(Event, Polarity) :-
    get_dict(pml, Event, Pml),
    get_dict(polarity, Pml, Polarity).

event_validity_register(Event, Register) :-
    get_dict(pml, Event, Pml),
    get_dict(validity_focus, Pml, Registers),
    member(Register, Registers).

recognition_risk(Event, Risk) :-
    event_recognition_profile(Event, recognition(Risk, _, _)).

material_inference_handle_id(Event, Handle) :-
    event_material_inference_handles(Event, Handles),
    member(material_inference_handle(Handle, _, _), Handles).

reason_witness_score(Witnesses, Score) :-
    findall(Points, (
        member(Witness, Witnesses),
        get_dict(points, Witness, Points)
    ), AllPoints),
    sum_list(AllPoints, Score).

reason_points(shared_domain(_), 2).
reason_points(shared_topic(_), 1).
reason_points(pml_polarity_contrast, 1).
reason_points(repair_affordance, 2).
reason_points(shared_validity_register(_), 1).
reason_points(recognition_balance, 1).
reason_points(shared_material_inference_handle(_), 2).

pair_question_moves(EventA, EventB, Moves) :-
    event_question_candidates(EventA, QuestionsA),
    event_question_candidates(EventB, QuestionsB),
    append(QuestionsA, QuestionsB, Questions),
    maplist(safe_question_move, Questions, Moves).

safe_question_move(Question, Move) :-
    get_dict(question_id, Question, QuestionIdString),
    atom_string(QuestionId, QuestionIdString),
    get_dict(move_type, Question, MoveType),
    get_dict(validity_register, Question, ValidityRegister),
    get_dict(target_commitment, Question, TargetCommitment),
    get_dict(constraints_satisfied, Question, Constraints),
    question_move_score(Question, ScoreDetail),
    get_dict(prompt_score, ScoreDetail, PromptScore),
    get_dict(score_reasons, ScoreDetail, ScoreReasons),
    Move = _{
        question_id: QuestionId,
        move_type: MoveType,
        validity_register: ValidityRegister,
        target_commitment: TargetCommitment,
        constraints_satisfied: Constraints,
        prompt_score: PromptScore,
        score_reasons: ScoreReasons
    }.

question_move_score(Question, _{prompt_score: Score, score_reasons: Reasons}) :-
    findall(Reason, question_score_reason(Question, Reason), RawReasons),
    sort(RawReasons, Reasons),
    findall(Points, (
        member(Reason, Reasons),
        question_reason_points(Reason, Points)
    ), AllPoints),
    sum_list(AllPoints, Score).

question_score_reason(Question, constraint(Constraint)) :-
    get_dict(constraints_satisfied, Question, Constraints),
    member(Constraint, Constraints).
question_score_reason(Question, move_type(MoveType)) :-
    get_dict(move_type, Question, MoveType).
question_score_reason(Question, validity_register(ValidityRegister)) :-
    get_dict(validity_register, Question, ValidityRegister).
question_score_reason(Question, targets_commitment) :-
    get_dict(target_commitment, Question, TargetCommitment),
    TargetCommitment \= "".

question_reason_points(constraint("recognition_safe"), 3) :- !.
question_reason_points(constraint("repair_affordance"), 3) :- !.
question_reason_points(constraint("targets_missing_requirement"), 2) :- !.
question_reason_points(constraint("targets_live_commitment"), 2) :- !.
question_reason_points(constraint("opens_validity_claim"), 2) :- !.
question_reason_points(constraint("decompresses_background_norm"), 2) :- !.
question_reason_points(constraint("action_impetus_open"), 1) :- !.
question_reason_points(constraint("infinite_seed"), 1) :- !.
question_reason_points(constraint("apophatic_guardrail"), 1) :- !.
question_reason_points(constraint(_), 1) :- !.
question_reason_points(move_type("recognition"), 2) :- !.
question_reason_points(move_type("decompression"), 2) :- !.
question_reason_points(move_type(_), 1) :- !.
question_reason_points(validity_register("subjective_truthfulness"), 2) :- !.
question_reason_points(validity_register("normative_rightness"), 2) :- !.
question_reason_points(validity_register("objective_truth"), 1) :- !.
question_reason_points(validity_register(_), 1) :- !.
question_reason_points(targets_commitment, 1).

pair_graph(Pairs, _{nodes: Nodes, edges: Edges}) :-
    findall(Id-Node, pair_node_keyed(Pairs, Id, Node), RawNodes),
    keysort(RawNodes, KeyedNodes),
    keyed_node_values(KeyedNodes, Nodes),
    maplist(pair_edge, Pairs, Edges).

pair_node_keyed(Pairs, Id, Node) :-
    pair_node(Pairs, Node),
    get_dict(id, Node, Id).

keyed_node_values([], []).
keyed_node_values([Id-Node|Rest], [Node|Nodes]) :-
    drop_matching_key(Id, Rest, Remaining),
    keyed_node_values(Remaining, Nodes).

drop_matching_key(Id, [Id-_|Rest], Remaining) :-
    !,
    drop_matching_key(Id, Rest, Remaining).
drop_matching_key(_, Rest, Rest).

pair_node(Pairs, Node) :-
    member(Pair, Pairs),
    (   get_dict(event_a, Pair, Id),
        get_dict(pseudonym_a, Pair, Label),
        get_dict(roles, Pair, [Role|_])
    ;   get_dict(event_b, Pair, Id),
        get_dict(pseudonym_b, Pair, Label),
        get_dict(roles, Pair, [_, Role])
    ),
    Node = _{
        id: Id,
        label: Label,
        role: Role
    }.

pair_edge(Pair, Edge) :-
    get_dict(pair_id, Pair, PairId),
    get_dict(event_a, Pair, Source),
    get_dict(event_b, Pair, Target),
    get_dict(score, Pair, Weight),
    get_dict(reasons, Pair, Reasons),
    get_dict(question_moves, Pair, QuestionMoves),
    length(QuestionMoves, QuestionCount),
    move_types(QuestionMoves, MoveTypes),
    Edge = _{
        id: PairId,
        source: Source,
        target: Target,
        weight: Weight,
        reasons: Reasons,
        question_count: QuestionCount,
        move_types: MoveTypes
    }.

move_types(QuestionMoves, MoveTypes) :-
    findall(MoveType, (
        member(Move, QuestionMoves),
        get_dict(move_type, Move, MoveType)
    ), RawMoveTypes),
    sort(RawMoveTypes, MoveTypes).
