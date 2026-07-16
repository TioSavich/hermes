:- module(hermes_event_scoring, [
    score_event/2,
    event_id/2,
    event_commitments/2,
    event_entitlements/2,
    event_missing_requirements/2,
    event_incompatibilities/2,
    event_material_inference_handles/2,
    event_literature_handles/2,
    event_content_inference_field/2,
    event_illocutionary_infrastructure/2,
    event_validity_profile/2,
    event_positional_reflection/2,
    event_recognition_profile/2,
    event_limit_nodes/2,
    event_question_candidates/2,
    repair_route/2
]).

/** <module> Hermes runtime event scoring.

This module scores already-structured Hermes runtime events. It separates
proof-bearing symbolic fields from expressive PML annotations and
Carspeckenian reconstructive routing. It does not parse raw prose or promote
candidate annotations into rules.
*/

normalize_token(Value, Token) :-
    (   string(Value)
    ->  atom_string(Token, Value)
    ;   Token = Value
    ).

event_id(Event, Id) :-
    get_dict(event_id, Event, Id).

event_commitments(Event, Commitments) :-
    symbolic_list(Event, commitments, Commitments).

event_entitlements(Event, Entitlements) :-
    symbolic_list(Event, entitlements, Entitlements).

event_missing_requirements(Event, Missing) :-
    symbolic_list(Event, missing_requirements, Missing).

event_incompatibilities(Event, Incompatibilities) :-
    symbolic_list(Event, incompatibilities, Incompatibilities).

event_material_inference_handles(Event, Handles) :-
    symbolic_list(Event, material_inferences, Records),
    findall(Handle, (
        member(Record, Records),
        material_inference_handle(Record, Handle)
    ), Handles).

event_literature_handles(Event, Handles) :-
    symbolic_list(Event, literature_handles, RawHandles),
    maplist(normalize_token, RawHandles, Handles).

event_question_candidates(Event, Questions) :-
    (   get_dict(question_candidates, Event, Questions)
    ->  true
    ;   Questions = []
    ).

event_content_inference_field(Event, Field) :-
    event_commitments(Event, Commitments),
    event_missing_requirements(Event, Missing),
    event_incompatibilities(Event, Incompatibilities),
    content_edges(commitment, Commitments, CommitmentEdges),
    content_edges(missing_requirement, Missing, MissingEdges),
    content_edges(incompatibility, Incompatibilities, IncompatibilityEdges),
    append([CommitmentEdges, MissingEdges, IncompatibilityEdges], Field).

event_illocutionary_infrastructure(Event, Infra) :-
    get_dict(actor, Event, Actor),
    get_dict(substrate, Event, Substrate),
    get_dict(role, Actor, Role),
    get_dict(utterance_type, Substrate, Type),
    Infra = [
        actor_role(Role),
        utterance_type(Type)
    ].

event_validity_profile(Event, validity(Profile, Horizon)) :-
    get_dict(pml, Event, Pml),
    get_dict(validity_focus, Pml, Profile),
    get_dict(pragmatic_horizon_level, Pml, Horizon).

event_positional_reflection(Event, Position) :-
    get_dict(pml, Event, Pml),
    (   get_dict(positional_reflection, Pml, Position)
    ->  true
    ;   infer_position(Event, Position)
    ).

event_recognition_profile(Event, recognition(Risk, Cost, Delta)) :-
    get_dict(carspecken, Event, Carspecken),
    get_dict(recognition_risk, Carspecken, Risk0),
    (   get_dict(identity_cost, Carspecken, Cost)
    ->  true
    ;   Cost = 0.0
    ),
    get_dict(proprioceptive_delta, Carspecken, Delta0),
    normalize_token(Risk0, Risk),
    normalize_token(Delta0, Delta).

event_limit_nodes(Event, [limit_node(missing_infinite)]) :-
    subject_limit_event(Event),
    !.
event_limit_nodes(_, []).

repair_route(Event, recognition_first) :-
    event_recognition_profile(Event, recognition(high, _, _)),
    !.
repair_route(Event, recognition_first) :-
    event_recognition_profile(Event, recognition(_, Cost, _)),
    number(Cost),
    Cost >= 0.7,
    !.
repair_route(Event, inferential_repair) :-
    event_incompatibilities(Event, Incompatibilities),
    Incompatibilities \= [],
    !.
repair_route(_, decompression).

score_event(Event, Score) :-
    event_id(Event, Id),
    event_commitments(Event, Commitments),
    event_entitlements(Event, Entitlements),
    event_missing_requirements(Event, Missing),
    event_incompatibilities(Event, Incompatibilities),
    event_material_inference_handles(Event, MaterialInferenceHandles),
    event_literature_handles(Event, LiteratureHandles),
    event_content_inference_field(Event, ContentField),
    event_illocutionary_infrastructure(Event, Infrastructure),
    event_validity_profile(Event, Validity),
    event_positional_reflection(Event, Position),
    event_recognition_profile(Event, Recognition),
    event_limit_nodes(Event, LimitNodes),
    event_question_candidates(Event, Questions),
    pml_status(Event, PmlStatus),
    reconstructive_action(Event, Action),
    guardrails(Event, Guardrails),
    Score = _{
        event_id: Id,
        pml_status: PmlStatus,
        proof_bearing_findings: _{
            commitments: Commitments,
            entitlements: Entitlements,
            missing_requirements: Missing,
            incompatibilities: Incompatibilities,
            material_inference_handles: MaterialInferenceHandles,
            literature_handles: LiteratureHandles
        },
        expressive_annotations: _{
            content_inference_field: ContentField,
            illocutionary_infrastructure: Infrastructure,
            validity: Validity,
            positional_reflection: Position
        },
        reconstructive_findings: _{
            recognition: Recognition,
            limit_nodes: LimitNodes,
            action: Action,
            guardrails: Guardrails
        },
        questions: Questions
    },
    !.

symbolic_list(Event, Key, Values) :-
    get_dict(symbolic, Event, Symbolic),
    (   get_dict(Key, Symbolic, Values)
    ->  true
    ;   Values = []
    ).

material_inference_handle(Record, material_inference_handle(Handle, Metaphor, Polarity)) :-
    is_dict(Record),
    get_dict(handle, Record, Handle0),
    normalize_token(Handle0, Handle),
    (   get_dict(metaphor, Record, Metaphor0)
    ->  normalize_token(Metaphor0, Metaphor)
    ;   Metaphor = unknown
    ),
    (   get_dict(polarity, Record, Polarity0)
    ->  normalize_token(Polarity0, Polarity)
    ;   Polarity = unknown
    ),
    !.
material_inference_handle(Record, material_inference_handle(Handle, unknown, unknown)) :-
    normalize_token(Record, Handle).

content_edges(_, [], []).
content_edges(Kind, [Item|Items], [content_edge(Kind, Item)|Edges]) :-
    content_edges(Kind, Items, Edges).

pml_status(Event, Status) :-
    get_dict(pml, Event, Pml),
    get_dict(status, Pml, Status).

infer_position(Event, first_person) :-
    get_dict(substrate, Event, Substrate),
    get_dict(utterance_type, Substrate, Type0),
    normalize_token(Type0, avowal),
    !.
infer_position(Event, second_person) :-
    get_dict(substrate, Event, Substrate),
    get_dict(utterance_type, Substrate, Type0),
    normalize_token(Type0, command),
    !.
infer_position(Event, second_person) :-
    get_dict(substrate, Event, Substrate),
    get_dict(utterance_type, Substrate, Type0),
    normalize_token(Type0, question),
    !.
infer_position(Event, third_person) :-
    get_dict(actor, Event, Actor),
    get_dict(role, Actor, Role0),
    normalize_token(Role0, analyst),
    !.
infer_position(_, undetermined).

reconstructive_action(Event, quarantine) :-
    event_limit_nodes(Event, Nodes),
    Nodes \= [],
    !.
reconstructive_action(Event, repair_required) :-
    event_incompatibilities(Event, Incompatibilities),
    Incompatibilities \= [],
    !.
reconstructive_action(_, continue).

guardrails(Event, [Guardrail]) :-
    get_dict(carspecken, Event, Carspecken),
    get_dict(apophatic_guardrail, Carspecken, Guardrail),
    !.
guardrails(_, []).

subject_limit_event(Event) :-
    get_dict(carspecken, Event, Carspecken),
    get_dict(infinite_seed, Carspecken, true),
    (   substrate_contains(Event, observed_markers, "limit_claim")
    ;   substrate_contains(Event, observed_markers, "non_objectifiable_subject")
    ;   substrate_contains(Event, candidate_terms, "missing_infinite")
    ;   substrate_contains(Event, candidate_terms, "transcendental_i")
    ;   symbolic_contains(Event, incompatibilities, "subject_as_object_model")
    ).

substrate_contains(Event, Key, Value) :-
    get_dict(substrate, Event, Substrate),
    get_dict(Key, Substrate, Values),
    memberchk(Value, Values).

symbolic_contains(Event, Key, Value) :-
    symbolic_list(Event, Key, Values),
    memberchk(Value, Values).
