% consumption_gate_probes.pl -- execute authored consumption probes.
%
% The runner loads the Hermes runtime once. Each consumer_goal selects a fact
% whose clause source is the declared store, carries its bindings through the
% consumer goal, and checks the declared postcondition. This works for static
% and dynamic reads because the check concerns the consumer result rather than
% coverage instrumentation.

:- use_module(library(aggregate)).
:- discontiguous run_probe_/3.

main :-
    catch(main_, Error,
          ( print_message(error, Error),
            halt(2)
          )).

main_ :-
    load_files('paths.pl', [if(not_loaded)]),
    load_files('hermes_worker.pl', [if(not_loaded)]),
    once(load_runtime),
    lifecycle_path(LifecyclePath),
    load_files(LifecyclePath, [if(changed)]),
    findall(Store-Rung-Spec,
            ( consumption_probe(Store, Rung, Spec),
              executable_rung(Rung)
            ),
            Probes0),
    sort(Probes0, Probes),
    length(Probes, Expected),
    format('PROBES_EXPECTED ~d~n', [Expected]),
    maplist(run_probe, Probes),
    length(Probes, Done),
    format('PROBES_DONE ~d~n', [Done]),
    halt(0).

lifecycle_path(Path) :-
    (   getenv('CONSUMPTION_GATE_LIFECYCLE', Path0)
    ->  atom_string(Path, Path0)
    ;   Path = 'knowledge/index/consumption_lifecycle.pl'
    ).

executable_rung(consumer_goal).
executable_rung(check_goal).
executable_rung(not_loaded).
executable_rung(eager).

run_probe(Store-Rung-Spec) :-
    catch(run_probe_(Store, Rung, Spec), Error,
          ( message_to_string(Error, Message),
            print_verdict(Store, Rung, fail, Message)
          )),
    !.
run_probe(Store-Rung-_Spec) :-
    print_verdict(Store, Rung, fail, failed_without_reason).

run_probe_(Store, consumer_goal,
           probe(Loader, SentinelGoal, ConsumerGoal, Post)) :-
    run_loader(Loader),
    (   once(SentinelGoal)
    ->  (   once(ConsumerGoal)
        ->  (   postcondition(Post)
            ->  print_verdict(Store, consumer_goal, pass, ok)
            ;   print_verdict(Store, consumer_goal, fail, adapter_dead)
            )
        ;   print_verdict(Store, consumer_goal, fail, adapter_dead)
        )
    ;   print_verdict(Store, consumer_goal, fail, sentinel_failed)
    ).
run_probe_(Store, check_goal, check(_Entry, Module:Goal)) :-
    store_lifecycle(Store, _Lifecycle, Consumer, _Since, _Note),
    load_check_consumer(Consumer, Module),
    (   once(Module:Goal)
    ->  print_verdict(Store, check_goal, pass, ok)
    ;   print_verdict(Store, check_goal, fail, check_goal_failed)
    ).

load_check_consumer(Consumer, consumption_gate_check) :-
    !,
    consumption_gate_check:load_files(Consumer, [if(not_loaded)]).
load_check_consumer(Consumer, _Module) :-
    load_files(Consumer, [if(not_loaded)]).
run_probe_(Store, not_loaded, none) :-
    (   store_source_loaded(Store)
    ->  print_verdict(Store, not_loaded, fail, store_loaded)
    ;   print_verdict(Store, not_loaded, pass, ok)
    ).
run_probe_(Store, eager, none) :-
    (   store_source_loaded(Store)
    ->  print_verdict(Store, eager, pass, ok)
    ;   print_verdict(Store, eager, fail, store_not_loaded)
    ).

run_loader(none).
run_loader(load(Path)) :-
    use_module(Path, []).

postcondition(nonvar(Value)) :-
    nonvar(Value).
postcondition(nonempty(Value)) :-
    (   string(Value)
    ->  string_length(Value, Length)
    ;   is_list(Value)
    ->  length(Value, Length)
    ),
    Length > 0.
postcondition(contains(Value, Part)) :-
    sub_term(Part, Value).

store_fact(Store, Module:Head) :-
    absolute_file_name(Store, Absolute, [access(read)]),
    clause(Module:Head, true, Reference),
    clause_property(Reference, file(Source)),
    same_file(Absolute, Source),
    !.

store_source_loaded(Store) :-
    absolute_file_name(Store, Absolute, [access(read)]),
    source_file(Source),
    same_file(Absolute, Source),
    !.

same_file(Left, Right) :-
    absolute_file_name(Left, LeftAbsolute, [access(read)]),
    absolute_file_name(Right, RightAbsolute, [access(read)]),
    LeftAbsolute == RightAbsolute.

print_verdict(Store, Rung, pass, _Reason) :-
    format('PROBE ~w ~w PASS~n', [Rung, Store]).
print_verdict(Store, Rung, fail, Reason) :-
    term_string(Reason, ReasonString, [quoted(true)]),
    format('PROBE ~w ~w FAIL ~s~n', [Rung, Store, ReasonString]).

:- initialization(main, main).
