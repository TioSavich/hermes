/** <module> Interactional trace event vocabulary and validation

This module owns the generic trace-event contract used by transcript
adjudication and by the optional Zeeman/PML bridge. It contains no mapping to a
PML operator and does not infer trace events from transcript evidence.
*/
:- module(interactional_trace, [
    valid_trace_event/1, % valid_trace_event(+TraceEvent)
    trace_event_dict/2   % trace_event_dict(+TraceEvent, -JSONSafeDict)
]).

%! valid_trace_event(+TraceEvent) is semidet.
valid_trace_event(
    trace_event(Id, span(From, To), Codes,
                trace_meta(Actor, Certifier, Condition))) :-
    ground(Id),
    ground(From),
    ground(To),
    ground(Actor),
    is_list(Codes),
    Codes \= [],
    maplist(valid_trace_code, Codes),
    sort(Codes, UniqueCodes),
    same_length(Codes, UniqueCodes),
    valid_certifier(Certifier),
    valid_condition(Condition),
    settlement_metadata_valid(Codes, Certifier),
    reopening_metadata_valid(Codes, Condition).

valid_trace_code(opening).
valid_trace_code(closure_bid).
valid_trace_code(uptake).
valid_trace_code(non_uptake).
valid_trace_code(reopening).
valid_trace_code(conditional_reopening).
valid_trace_code(settlement).

valid_certifier(none).
valid_certifier(authority(Actor)) :-
    ground(Actor).
valid_certifier(convergence(Actors)) :-
    is_list(Actors),
    Actors = [_, _ | _],
    maplist(ground, Actors).

valid_condition(none).
valid_condition(required_if(Condition)) :-
    ground(Condition).

settlement_metadata_valid(Codes, Certifier) :-
    ( memberchk(settlement, Codes) -> Certifier \== none
    ; Certifier == none
    ).

reopening_metadata_valid(Codes, Condition) :-
    ( memberchk(conditional_reopening, Codes) ->
        Condition = required_if(_)
    ; Condition == none
    ).

%! trace_event_dict(+TraceEvent, -JSONSafeDict) is semidet.
trace_event_dict(
    Event,
    _{id: Id, span: _{from: From, to: To}, codes: Codes,
      actor: Actor, certifier: CertifierDict,
      condition: ConditionDict}) :-
    valid_trace_event(Event),
    Event = trace_event(Id, span(From, To), Codes,
                        trace_meta(Actor, Certifier, Condition)),
    certifier_dict(Certifier, CertifierDict),
    condition_dict(Condition, ConditionDict).

certifier_dict(none, null).
certifier_dict(authority(Actor),
               _{kind: authority, actor: Actor}).
certifier_dict(convergence(Actors),
               _{kind: convergence, actors: Actors}).

condition_dict(none, null).
condition_dict(required_if(Condition),
               _{kind: required_if, condition: Condition}).
