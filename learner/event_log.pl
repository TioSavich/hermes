/** <module> Structured Event Logger

    Emits JSON events for each ORR cycle step, making the system's
    developmental progression visible without reading Prolog traces.

    Events are accumulated in a thread-local list and can be retrieved
    as a JSON array. This is the prerequisite for any visualization.

    Usage:
        reset_events,
        ... (run ORR cycle) ...
        get_events(Events).   % Events is a list of dicts
*/
:- module(event_log, [
    emit/2,           % emit(+Type, +Data) — log a structured event
    reset_events/0,   % clear the event log
    get_events/1,     % get_events(-Events) — retrieve all events as list
    events_to_json/1  % events_to_json(-JSONAtom) — serialize events to JSON string
]).

:- use_module(library(http/json)).

%% Event storage — uses global assert for simplicity.
%% P3-3 will convert to thread_local when multi-user is needed.
:- dynamic stored_event/2.  % stored_event(Timestamp, EventDict)

%!  emit(+Type:atom, +Data:dict) is det.
%
%   Log a structured event. Type is one of:
%     computation_start, computation_success,
%     crisis_detected, crisis_classified,
%     oracle_consulted, oracle_exhausted,
%     synthesis_attempted, synthesis_succeeded, synthesis_failed,
%     validation_passed, validation_failed,
%     retry, computation_failed
%
emit(Type, Data) :-
    get_time(T),
    Event = event{type: Type, time: T}.put(Data),
    assert(stored_event(T, Event)).

%!  reset_events is det.
%
%   Clear all stored events. Call before starting a new computation.
%
reset_events :-
    retractall(stored_event(_, _)).

%!  get_events(-Events:list) is det.
%
%   Retrieve all stored events in chronological order.
%
get_events(Events) :-
    findall(E, stored_event(_, E), Events).

%!  events_to_json(-JSON:atom) is det.
%
%   Serialize the event log to a JSON string suitable for HTTP response
%   or file output.
%
events_to_json(JSON) :-
    get_events(Events),
    with_output_to(atom(JSON),
                   json_write_dict(current_output, Events, [])).
