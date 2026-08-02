/** <module> Bounded read-only queries over loaded knowledge predicates
 *
 * This module turns caller text into one SWI-Prolog goal, checks the complete
 * call graph with library(sandbox), and enumerates a bounded set of solutions
 * inside a database snapshot. It also derives a filterable predicate listing
 * from the knowledge files loaded in the current worker process.
 */
:- module(prolog_query,
          [ prolog_query_dict/2
          ]).

:- use_module(library(pairs), [pairs_values/2]).
:- use_module(library(sandbox), [safe_goal/1]).
:- use_module(library(time), [call_with_time_limit/2]).


% The defaults below serve the interactive MCP surface. A batch caller that
% owns its own wall-clock budget — a benchmark driver, a corpus probe — may
% widen them through the environment; every reply still reports the limits
% it actually ran under, so a widened run cannot be mistaken for a default
% one.
solution_cap(Cap) :-
    limit_from_environment('HERMES_PROLOG_QUERY_SOLUTION_CAP',
                           integer, 100, Cap).
timeout_seconds(Timeout) :-
    limit_from_environment('HERMES_PROLOG_QUERY_TIMEOUT_SECONDS',
                           number, 2.0, Timeout).
listing_cap(Cap) :-
    limit_from_environment('HERMES_PROLOG_QUERY_LISTING_CAP',
                           integer, 100, Cap).

limit_from_environment(Name, Type, Default, Value) :-
    (   getenv(Name, Text),
        atom_number(Text, Number),
        limit_of_type(Type, Number),
        Number > 0
    ->  Value = Number
    ;   Value = Default
    ).

limit_of_type(integer, Number) :- integer(Number).
limit_of_type(number, Number) :- number(Number).


%!  prolog_query_dict(+Request:dict, -Dict:dict) is det.
%
%   Run Request.goal when it is a non-empty string. With no goal, return the
%   predicate listing narrowed by optional name, file, and arity filters.
prolog_query_dict(Request, Dict) :-
    (   get_dict(goal, Request, GoalReceived)
    ->  query_goal_dict(GoalReceived, Dict)
    ;   predicate_listing_dict(Request, Dict)
    ).


query_goal_dict(GoalReceived, Dict) :-
    query_limits(Limits),
    timeout_seconds(Timeout),
    catch(call_with_time_limit(
              Timeout,
              bounded_query_goal_dict(GoalReceived, Limits, Dict)),
          time_limit_exceeded,
          Dict = _{ kind: "query",
                    status: "timeout",
                    goal_received: GoalReceived,
                    goal_parsed: null,
                    bindings: [],
                    solution_count: null,
                    cap_hit: false,
                    limits: Limits,
                    error: _{ reason: "time_limit_exceeded",
                              message: "The query exceeded its recorded wall-clock limit." }
                  }).

bounded_query_goal_dict(GoalReceived, Limits, Dict) :-
    (   string(GoalReceived), GoalReceived \== ""
    ->  catch(parse_goal(GoalReceived, Goal, VariableNames, GoalParsed),
              Error,
              true),
        (   var(Error)
        ->  checked_goal_dict(
                GoalReceived, GoalParsed, Goal, VariableNames, Limits, Dict)
        ;   error_text(Error, Reason, Message),
            Dict = _{ kind: "query",
                      status: "parse_error",
                      goal_received: GoalReceived,
                      goal_parsed: null,
                      bindings: [],
                      solution_count: null,
                      cap_hit: false,
                      limits: Limits,
                      error: _{reason: Reason, message: Message}
                    }
        )
    ;   Dict = _{ kind: "query",
                  status: "parse_error",
                  goal_received: GoalReceived,
                  goal_parsed: null,
                  bindings: [],
                  solution_count: null,
                  cap_hit: false,
                  limits: Limits,
                  error: _{ reason: "type_error(non_empty_string, goal)",
                            message: "goal must be a non-empty string" }
                }
    ).

parse_goal(GoalReceived, Goal, VariableNames, GoalParsed) :-
    term_string(Goal, GoalReceived,
                [ module(user),
                  variable_names(VariableNames),
                  syntax_errors(error)
                ]),
    (   callable(Goal), acyclic_term(Goal)
    ->  true
    ;   throw(error(type_error(callable, Goal), prolog_query/2))
    ),
    term_string(Goal, GoalParsed,
                [ module(user),
                  quoted(true),
                  variable_names(VariableNames),
                  numbervars(true)
                ]).

checked_goal_dict(GoalReceived, GoalParsed, Goal, VariableNames, Limits, Dict) :-
    catch((safe_goal(user:Goal), Sandbox = safe),
          SandboxError,
          Sandbox = rejected(SandboxError)),
    (   Sandbox = rejected(Error)
    ->  error_text(Error, Reason, Message),
        query_refusal_dict(
            GoalReceived, GoalParsed, Limits, "sandbox_refused",
            "swi_sandbox", Reason, Message, Dict)
    ;   read_only_rejection(Goal, ReadOnlyReason)
    ->  format(string(Message),
               "The read-only query surface refuses ~s.", [ReadOnlyReason]),
        query_refusal_dict(
            GoalReceived, GoalParsed, Limits, "refused",
            "hermes_read_only_guard", ReadOnlyReason, Message, Dict)
    ;   knowledge_scope_rejection(Goal, ScopeReason)
    ->  format(string(Message),
               "The query surface accepts caller-named repository predicates from knowledge/ only: ~s.",
               [ScopeReason]),
        query_refusal_dict(
            GoalReceived, GoalParsed, Limits, "refused",
            "hermes_knowledge_scope", ScopeReason, Message, Dict)
    ;   execute_goal_dict(
            GoalReceived, GoalParsed, Goal, VariableNames, Limits, Dict)
    ).

query_refusal_dict(GoalReceived, GoalParsed, Limits, Status,
                   Source, Reason, Message, Dict) :-
    Dict = _{ kind: "query",
              status: Status,
              goal_received: GoalReceived,
              goal_parsed: GoalParsed,
              bindings: [],
              solution_count: null,
              cap_hit: false,
              limits: Limits,
              rejection: _{source: Source, reason: Reason, message: Message}
            }.

execute_goal_dict(GoalReceived, GoalParsed, Goal, VariableNames, Limits, Dict) :-
    solution_cap(Cap),
    ProbeLimit is Cap + 1,
    catch(snapshot(findnsols(ProbeLimit, VariableNames, Goal, RawSolutions)),
          ExecutionError,
          true),
    (   var(ExecutionError)
    ->  capped_solutions(RawSolutions, Cap, CappedSolutions, CapHit),
        maplist(binding_dict, CappedSolutions, Bindings),
        length(Bindings, SolutionCount),
        Dict = _{ kind: "query",
                  status: "ok",
                  goal_received: GoalReceived,
                  goal_parsed: GoalParsed,
                  bindings: Bindings,
                  solution_count: SolutionCount,
                  cap_hit: CapHit,
                  limits: Limits
                }
    ;   ExecutionError == time_limit_exceeded
    ->  Dict = _{ kind: "query",
                  status: "timeout",
                  goal_received: GoalReceived,
                  goal_parsed: GoalParsed,
                  bindings: [],
                  solution_count: null,
                  cap_hit: false,
                  limits: Limits,
                  error: _{ reason: "time_limit_exceeded",
                            message: "The query exceeded its recorded wall-clock limit." }
                }
    ;   error_text(ExecutionError, Reason, Message),
        Dict = _{ kind: "query",
                  status: "execution_error",
                  goal_received: GoalReceived,
                  goal_parsed: GoalParsed,
                  bindings: [],
                  solution_count: null,
                  cap_hit: false,
                  limits: Limits,
                  error: _{reason: Reason, message: Message}
                }
    ).

query_limits(_{solution_cap: Cap, timeout_seconds: Timeout}) :-
    solution_cap(Cap),
    timeout_seconds(Timeout).

capped_solutions(RawSolutions, Cap, Solutions, true) :-
    length(Solutions, Cap),
    append(Solutions, [_Extra|_], RawSolutions),
    !.
capped_solutions(Solutions, _Cap, Solutions, false).

binding_dict(NameValues, Dict) :-
    maplist(binding_pair, NameValues, Pairs),
    dict_pairs(Dict, bindings, Pairs).

binding_pair(Name=Value, Name-Value).


% SWI's sandbox intentionally permits local assert/retract and some local
% state operations. They are useful for hosted code, but this surface is a
% query surface. The snapshot below prevents incidental database writes in a
% called knowledge predicate from surviving; this guard also refuses goals
% that name a mutation directly, including through call/N or another closure.
read_only_rejection(Goal, Reason) :-
    sub_term(SubTerm, Goal),
    nonvar(SubTerm),
    callable(SubTerm),
    functor(SubTerm, Name, Arity),
    forbidden_mutation_name(Name),
    format(string(Reason), "forbidden_call(~w/~d)", [Name, Arity]),
    !.

forbidden_mutation_name(assert).
forbidden_mutation_name(asserta).
forbidden_mutation_name(assertz).
forbidden_mutation_name(retract).
forbidden_mutation_name(retractall).
forbidden_mutation_name(abolish).
forbidden_mutation_name(recorda).
forbidden_mutation_name(recordz).
forbidden_mutation_name(erase).
forbidden_mutation_name(setarg).
forbidden_mutation_name(nb_setarg).
forbidden_mutation_name(nb_setval).
forbidden_mutation_name(nb_linkval).
forbidden_mutation_name(nb_delete).
forbidden_mutation_name(b_setval).
forbidden_mutation_name(set_prolog_flag).
forbidden_mutation_name(set_base).
forbidden_mutation_name(reset_scorekeeper).
forbidden_mutation_name(undertake_commitment).
forbidden_mutation_name(grant_entitlement).
forbidden_mutation_name(withdraw_commitment).
forbidden_mutation_name(enable_axiom).
forbidden_mutation_name(disable_axiom).
forbidden_mutation_name(with_axioms_disabled).
forbidden_mutation_name(enable_axiom_pack).
forbidden_mutation_name(disable_axiom_pack).
forbidden_mutation_name(restore_axiom_packs).
forbidden_mutation_name(add_incompatible_set).
forbidden_mutation_name(remove_incompatible_set).
forbidden_mutation_name(review_decide_dict).


% The persistent worker also owns application and learner state. The generated
% vocabulary is deliberately limited to knowledge/, and caller-named repository
% predicates must come from that same boundary. SWI and library predicates may
% still compose a knowledge query.
knowledge_scope_rejection(Goal, Reason) :-
    sub_term(SubTerm, Goal),
    nonvar(SubTerm),
    callable(SubTerm),
    strip_module(user:SubTerm, Module, Plain),
    callable(Plain),
    predicate_repository_source(Module, Plain, SourceFile),
    repository_relative_file(SourceFile, RelativeFile),
    \+ sub_string(RelativeFile, 0, _, _, "knowledge/"),
    functor(Plain, Name, Arity),
    format(string(Reason), "predicate_outside_knowledge(~w:~w/~d,~s)",
           [Module, Name, Arity, RelativeFile]),
    !.
knowledge_scope_rejection(Goal, Reason) :-
    sub_term(SubTerm, Goal),
    nonvar(SubTerm),
    callable(SubTerm),
    strip_module(user:SubTerm, user, Plain),
    callable(Plain),
    predicate_property(user:Plain, defined),
    \+ predicate_property(user:Plain, built_in),
    \+ predicate_property(user:Plain, imported_from(_)),
    \+ ( predicate_repository_source(user, Plain, SourceFile),
         knowledge_relative_file(SourceFile, _)
       ),
    functor(Plain, Name, Arity),
    format(string(Reason), "unlisted_user_predicate(~w/~d)", [Name, Arity]),
    !.

predicate_repository_source(Module, Plain, SourceFile) :-
    predicate_property(Module:Plain, file(SourceFile)),
    !.
predicate_repository_source(Module, _Plain, SourceFile) :-
    module_property(Module, file(SourceFile)).


predicate_listing_dict(Request, Dict) :-
    listing_filters(Request, NameFilter, FileFilter, ArityFilter, Filters),
    listing_cap(Cap),
    timeout_seconds(Timeout),
    Limits = _{predicate_cap: Cap, timeout_seconds: Timeout},
    catch(call_with_time_limit(
              Timeout,
              predicate_listing_rows(
                  NameFilter, FileFilter, ArityFilter, Rows)),
          ListingError,
          true),
    (   var(ListingError)
    ->  length(Rows, MatchedCount),
        cap_listing(Rows, Cap, ReturnedRows, Truncated),
        length(ReturnedRows, ReturnedCount),
        Dict = _{ kind: "predicate_listing",
                  status: "ok",
                  filters: Filters,
                  matched_count: MatchedCount,
                  returned_count: ReturnedCount,
                  truncated: Truncated,
                  listing_cap: Cap,
                  limits: Limits,
                  predicates: ReturnedRows,
                  guidance: "Call without goal to list predicates. Narrow with a name substring, a knowledge-relative file substring, or an exact arity, then call the query tool with a module-qualified goal from the listing."
                }
    ;   ListingError == time_limit_exceeded
    ->  Dict = _{ kind: "predicate_listing",
                  status: "timeout",
                  filters: Filters,
                  matched_count: null,
                  returned_count: 0,
                  truncated: false,
                  listing_cap: Cap,
                  limits: Limits,
                  predicates: [],
                  error: _{ reason: "time_limit_exceeded",
                            message: "The predicate listing exceeded its recorded wall-clock limit." }
                }
    ;   error_text(ListingError, Reason, Message),
        Dict = _{ kind: "predicate_listing",
                  status: "execution_error",
                  filters: Filters,
                  matched_count: null,
                  returned_count: 0,
                  truncated: false,
                  listing_cap: Cap,
                  limits: Limits,
                  predicates: [],
                  error: _{reason: Reason, message: Message}
                }
    ).

predicate_listing_rows(NameFilter, FileFilter, ArityFilter, Rows) :-
    findall(Key-Row,
            predicate_listing_row(
                NameFilter, FileFilter, ArityFilter, Key, Row),
            KeyedRows0),
    sort(KeyedRows0, KeyedRows),
    pairs_values(KeyedRows, Rows).

listing_filters(Request, NameFilter, FileFilter, ArityFilter, Filters) :-
    listing_text_filter(Request, name, NameFilter, NameText),
    listing_text_filter(Request, file, FileFilter, FileText),
    (   get_dict(arity, Request, Arity0)
    ->  integer(Arity0), Arity0 >= 0,
        ArityFilter = Arity0,
        ArityValue = Arity0
    ;   ArityFilter = all,
        ArityValue = null
    ),
    Filters = _{name: NameText, file: FileText, arity: ArityValue}.

listing_text_filter(Request, Key, Filter, Text) :-
    (   get_dict(Key, Request, Value), string(Value), Value \== ""
    ->  string_lower(Value, Filter),
        Text = Value
    ;   Filter = all,
        Text = null
    ).

predicate_listing_row(NameFilter, FileFilter, ArityFilter,
                      key(NameText, Arity, ModuleText, RelativeFile),
                      Row) :-
    current_predicate(Module:Name/Arity),
    atom(Module),
    atom(Name),
    integer(Arity),
    functor(Head, Name, Arity),
    \+ predicate_property(Module:Head, imported_from(_)),
    predicate_property(Module:Head, file(SourceFile)),
    knowledge_relative_file(SourceFile, RelativeFile),
    predicate_property(Module:Head, number_of_clauses(ClauseCount)),
    ClauseCount > 0,
    atom_string(Name, NameText),
    atom_string(Module, ModuleText),
    listing_name_matches(NameFilter, NameText),
    listing_file_matches(FileFilter, RelativeFile),
    listing_arity_matches(ArityFilter, Arity),
    Base = _{ name: NameText,
              arity: Arity,
              module: ModuleText,
              file: RelativeFile,
              clause_count: ClauseCount
            },
    (   structured_predicate_summary(Module, Name, Arity, Summary)
    ->  Row = Base.put(summary, Summary)
    ;   Row = Base
    ).

knowledge_relative_file(SourceFile, RelativeFile) :-
    repository_relative_file(SourceFile, RelativeFile),
    sub_string(RelativeFile, 0, _, _, "knowledge/").

repository_relative_file(SourceFile, RelativeFile) :-
    source_file(prolog_query:prolog_query_dict(_, _), ThisFile),
    file_directory_name(ThisFile, HermesDirectory),
    file_directory_name(HermesDirectory, RepoRoot),
    absolute_file_name(SourceFile, AbsoluteSource,
                       [file_type(prolog), access(read)]),
    atom_concat(RepoRoot, Tail0, AbsoluteSource),
    atom_concat('/', Tail, Tail0),
    atom_string(Tail, RelativeFile).

listing_name_matches(all, _).
listing_name_matches(Filter, Name) :-
    string_lower(Name, LowerName),
    sub_string(LowerName, _, _, _, Filter).

listing_file_matches(all, _).
listing_file_matches(Filter, File) :-
    string_lower(File, LowerFile),
    sub_string(LowerFile, _, _, _, Filter).

listing_arity_matches(all, _).
listing_arity_matches(Arity, Arity).

structured_predicate_summary(Module, Name, Arity, Summary) :-
    current_predicate(prolog:predicate_summary/2),
    catch(prolog:predicate_summary(Module:Name/Arity, Summary0), _, fail),
    string(Summary0),
    Summary0 \== "",
    Summary = Summary0,
    !.

cap_listing(Rows, Cap, ReturnedRows, true) :-
    length(ReturnedRows, Cap),
    append(ReturnedRows, [_Extra|_], Rows),
    !.
cap_listing(Rows, _Cap, Rows, false).


error_text(Error, Reason, Message) :-
    term_string(Error, Reason,
                [ quoted(true),
                  numbervars(true),
                  max_depth(50)
                ]),
    message_to_string(Error, Message).
