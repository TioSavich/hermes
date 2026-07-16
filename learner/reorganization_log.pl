/** <module> Reorganization and Cognitive Process Logger
 *
 * This module provides a logging facility for the ORR (Observe, Reorganize,
 * Reflect) cycle. It captures key events during the cognitive process,
 * such as the start of a cycle, detection of disequilibrium, and the
 * success or failure of reorganization attempts.
 *
 * The log can be retrieved as a raw list of events or generated as a
 * human-readable narrative report using a Definite Clause Grammar (DCG).
 *
 * Log entries are stored as dynamic facts of the form:
 * `log_entry(Timestamp, Event)`.
 *
 * 
 * 
 */
:- module(reorganization_log, [
    log_event/1,
    get_log/1,
    clear_log/0,
    generate_report/1
]).

:- dynamic log_entry/2.

%!      log_event(+Event:term) is det.
%
%       Records a structured event in the log with a current timestamp.
%
%       @param Event The structured term representing the event to be logged
%       (e.g., `disequilibrium(trigger_term)`).
log_event(Event) :-
    get_time(Timestamp),
    assertz(log_entry(Timestamp, Event)).

%!      get_log(-Log:list) is det.
%
%       Retrieves the entire log as a list of `log_entry/2` facts.
%
%       @param Log A list of all `log_entry(Timestamp, Event)` terms currently
%       in the database.
get_log(Log) :-
    findall(log_entry(T, E), log_entry(T, E), Log).

%!      clear_log is det.
%
%       Clears all entries from the reorganization log by retracting all
%       `log_entry/2` facts. This is typically done before starting a new
%       `run_query/1`.
clear_log :-
    retractall(log_entry(_, _)).

%!      generate_report(-Report:string) is det.
%
%       Translates the current log into a single, human-readable narrative string.
%       It uses a DCG to convert the structured log events into descriptive sentences.
%
%       @param Report The generated narrative report as a string.
generate_report(Report) :-
    get_log(Log),
    phrase(narrative(Log), Tokens),
    atomics_to_string(Tokens, Report).

% --- DCG for Narrative Generation ---

% narrative//1 processes the list of log entries.
narrative([]) --> [].
narrative([log_entry(_, Event)|Rest]) -->
    event_narrative(Event),
    narrative(Rest).

% event_narrative//1 translates a single event term into a string component.
event_narrative(orr_cycle_start(Goal)) -->
    ["- System started observing goal: ", Goal, ".\n"].

event_narrative(disequilibrium(Trigger)) -->
    ["- Reflection detected disequilibrium. Trigger: ", Trigger, ".\n"].

event_narrative(reorganization_start(Signature)) -->
    ["- Reorganization started, targeting predicate: ", Signature, ".\n"].

event_narrative(retracted(Clause)) -->
    ["  - The old clause was retracted: ", Clause, ".\n"].

event_narrative(asserted(Clause)) -->
    ["  - A new clause was asserted: ", Clause, ".\n"].

event_narrative(reorganization_success) -->
    ["- Reorganization was successful. System is retrying the goal to seek a new equilibrium.\n"].

event_narrative(reorganization_failure) -->
    ["- Reorganization failed. The system could not find a way to accommodate the issue.\n"].

event_narrative(equilibrium) -->
    ["- Equilibrium reached. The goal succeeded and was found to be coherent.\n"].

event_narrative(Unknown) -->
    ["- An unknown event was logged: ", Unknown, ".\n"].