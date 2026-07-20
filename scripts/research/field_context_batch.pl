/** <module> One-process field-context cache batch
 *
 * Internal helper for build_field_context_cache.py. The caller supplies a
 * JSON object with a lessons list on stdin. This process loads the same
 * runtime as the Hermes worker, computes every row with field_context_dict/2,
 * and writes one JSON object to stdout. Individual searches are bounded so a
 * single difficult lesson cannot stall regeneration.
 */
:- module(field_context_batch, [main/0]).

:- use_module(library(http/json)).
:- use_module(library(thread)).
:- use_module(library(time)).


main :-
    json_read_dict(user_input, Request),
    get_dict(lessons, Request, LessonStrings),
    maplist(atom_string, LessonCodes, LessonStrings),
    prepare_batch_tables,
    set_prolog_flag(cpu_count, 8),
    flag(field_context_batch_completed, _Previous, 0),
    % Populate the explicit field-context memos before worker threads race to
    % read them. The caches are process-local and their facts are static.
    field_context:lesson_readiness_inputs(_, _, _, _, _),
    field_context:literature_summary_dict(_),
    concurrent_maplist(field_context_entry, LessonCodes, InitialPairs),
    retry_timeout_entries(InitialPairs, Pairs),
    dict_pairs(Contexts, field_contexts, Pairs),
    json_write_dict(user_output, Contexts, [width(0)]),
    nl.


retry_timeout_entries([], []).
retry_timeout_entries([Code-Initial|Rest], [Code-Result|Retried]) :-
    (   get_dict(error, Initial, "field_context_dict/2 exceeded 120 seconds")
    ->  format(user_error,
               'field_context cache: retrying ~w sequentially~n',
               [Code]),
        catch(call_with_time_limit(120, field_context_result(Code, Result)),
              Error,
              field_context_error(Error, Result))
    ;   Result = Initial
    ),
    retry_timeout_entries(Rest, Retried).


% field_context_dict/2 remains the sole row builder. These tables only retain
% its pure, lesson-independent subqueries inside this generation process. In
% particular, a lesson's strategy targets otherwise recompute the same fixed
% operation region repeatedly, including more than once within one lesson.
prepare_batch_tables :-
    table((lesson_monitoring:encoded_lesson/6) as shared),
    table((lesson_monitoring:lesson_strategy/4) as shared),
    table((lesson_monitoring:lesson_misconception/4) as shared),
    table((lesson_monitoring:monitoring_chart_export/2) as shared),
    table((lesson_monitoring:lesson_guide_context_dict/2) as shared),
    table((field_context:audit_strategy_pairs/1) as shared),
    table((field_context:audit_cluster_pairs/2) as shared),
    table((field_context:audit_literature_link_pairs/1) as shared),
    table((field_context:literature_summary_dict/1) as shared),
    table((expressive_power:operation_path_power_for_vocabulary/5) as shared),
    table((expressive_power:operation_path_power_for_vocabulary_witness/5) as shared),
    table((expressive_power:incompatibility_power/2) as shared),
    table((expressive_power:incompatibility_power_witness/2) as shared),
    table((expressive_power:lesson_expressive_power/4) as shared).


field_context_entry(Code, Code-Result) :-
    catch(call_with_time_limit(120, field_context_result(Code, Result)),
          Error,
          field_context_error(Error, Result)),
    report_progress.


field_context_result(Code, Result) :-
    (   field_context:field_context_dict(Code, Context)
    ->  Result = Context
    ;   Result = _{error: "field_context_dict/2 failed"}
    ).


field_context_error(time_limit_exceeded,
                    _{error: "field_context_dict/2 exceeded 120 seconds"}) :-
    !.
field_context_error(Error, _{error: Message}) :-
    message_to_string(Error, Message).


report_progress :-
    flag(field_context_batch_completed, Completed0, Completed0 + 1),
    Completed is Completed0 + 1,
    (   0 is Completed mod 25
    ->  format(user_error,
               'field_context cache: ~d lessons complete~n',
               [Completed])
    ;   true
    ).
