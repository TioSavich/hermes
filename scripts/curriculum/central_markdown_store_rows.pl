:- module(central_markdown_store_rows, []).

:- use_module(library(http/json)).

:- initialization(main, main).


main([Artifact]) :-
    !,
    load_files(Artifact, [silent(true)]),
    compiled_defragged_task_instances:defragged_task_instance_summary(Total, Counts),
    findall(Row, artifact_row(Row), Rows),
    json_write_dict(current_output,
                    _{summary:_{total:Total, counts:Counts}, rows:Rows},
                    [width(0)]),
    nl.
main(_) :-
    format(user_error,
           'usage: swipl -q -s central_markdown_store_rows.pl -- ARTIFACT~n',
           []),
    halt(2).


artifact_row(Row) :-
    compiled_defragged_task_instances:defragged_task_instance(
        _InternalId,
        LessonCode,
        Class-Operation,
        Data
    ),
    term_string(Class, ClassText, [quoted(false), numbervars(true)]),
    compound_name_arguments(Operation, Functor, Arguments),
    maplist(term_json, Arguments, JsonArguments),
    get_dict(status, Data, Status),
    get_dict(blocker, Data, Blocker),
    get_dict(complete_statement, Data, Statement),
    get_dict(referents, Data, Referents),
    maplist(referent_json, Referents, JsonReferents),
    Row = _{lesson:LessonCode,
            class_label:ClassText,
            op_functor:Functor,
            op_args:JsonArguments,
            status:Status,
            blocker:Blocker,
            complete_statement:Statement,
            referents:JsonReferents}.


referent_json(Referent, Json) :-
    get_dict(surface, Referent, Surface),
    get_dict(kind, Referent, Kind),
    get_dict(status, Referent, Status),
    get_dict(antecedent, Referent, Antecedent),
    get_dict(absence_reason, Referent, AbsenceReason),
    Json = _{surface:Surface,
             kind:Kind,
             status:Status,
             antecedent:Antecedent,
             absence_reason:AbsenceReason}.


term_json(Term, Term) :-
    number(Term),
    !.
term_json(Term, Text) :-
    atom(Term),
    !,
    atom_string(Term, Text).
term_json(Term, Text) :-
    string(Term),
    !,
    Text = Term.
term_json(Term, _{functor:Functor, args:JsonArguments}) :-
    compound_name_arguments(Term, Name, Arguments),
    atom_string(Name, Functor),
    maplist(term_json, Arguments, JsonArguments).
