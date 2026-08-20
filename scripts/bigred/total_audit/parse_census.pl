% parse_census.pl — static term census of tracked Prolog files.
%
% Reads every file named in a list file (one repo-relative path per line),
% term by term, WITHOUT consulting: no directive executes, no module loads,
% no operator escapes into the reading context beyond the one deliberate
% prelude below. Emits one JSON object per file (JSONL) with term, directive,
% rule, and fact counts, per-predicate fact tallies, and parse-error counts.
%
%   swipl -q -g main scripts/bigred/total_audit/parse_census.pl -- \
%         FILELIST OUT.jsonl
%
% Known limit, recorded rather than hidden: files that rely on operators
% declared elsewhere (the APE parser's grammar operators, some script-local
% ops) report operator parse errors here. The PML operator set is preloaded
% because formal/pml fact stores are census targets and their operators are
% declaration-only. The load probe, not this census, answers whether a file
% actually loads.

:- use_module(library(http/json)).

main :-
    current_prolog_flag(argv, Argv),
    ( Argv = [ListFile, OutFile] -> true
    ; format(user_error, "usage: parse_census.pl -- FILELIST OUT.jsonl~n", []),
      halt(2)
    ),
    preload_pml_operators,
    read_file_to_lines(ListFile, Paths),
    setup_call_cleanup(
        open(OutFile, write, Out, [encoding(utf8)]),
        forall(member(P, Paths), census_file(P, Out)),
        close(Out)),
    halt(0).

% Mirrors the declarations hermes_worker.pl makes at its own top: the PML
% prefix operators are global there, so fact stores written against them are
% legitimate corpus, and the census reads them the way the worker would.
preload_pml_operators :-
    forall(member(Name, [comp_nec, exp_nec, exp_poss, comp_poss, neg]),
           op(500, fx, Name)).

read_file_to_lines(File, Lines) :-
    read_file_to_string(File, S, []),
    split_string(S, "\n", " \t\r", Parts0),
    exclude(==(""), Parts0, Parts),
    maplist(atom_string, Lines, Parts).

census_file(Path, Out) :-
    catch(census_file_(Path, Dict), E,
          ( message_to_codes(E, Codes),
            atom_codes(EA, Codes),
            Dict = _{path: Path, fatal_error: EA} )),
    json_write_dict(Out, Dict, [width(0)]),
    nl(Out),
    flush_output(Out).

message_to_codes(E, Codes) :-
    catch(with_output_to(codes(Codes), print_message_lines(
        current_output, '', [E-[]])), _, Codes = `error`).

census_file_(Path, Dict) :-
    setup_call_cleanup(
        open(Path, read, In, [encoding(utf8)]),
        census_stream(In, 0-0-0-0-0, [], Counts, Preds),
        close(In)),
    Counts = Terms-Dirs-Rules-Facts-Errs,
    msort(Preds, Sorted),
    tally(Sorted, Tally),
    dict_pairs(PredDict, _, Tally),
    Dict = _{path: Path, terms: Terms, directives: Dirs, rules: Rules,
             facts: Facts, parse_errors: Errs, fact_predicates: PredDict}.

census_stream(In, Acc0, Preds0, Counts, Preds) :-
    Acc0 = T0-D0-R0-F0-E0,
    catch(read_term(In, Term, [syntax_errors(error)]), _Err, Term = '$census_error'),
    ( Term == end_of_file
    -> Counts = Acc0, Preds = Preds0
    ; Term == '$census_error'
    -> E1 is E0 + 1, T1 is T0 + 1,
       census_stream(In, T1-D0-R0-F0-E1, Preds0, Counts, Preds)
    ; T1 is T0 + 1,
      classify(Term, Acc0, T1, Acc1, Preds0, Preds1),
      census_stream(In, Acc1, Preds1, Counts, Preds)
    ).

classify((:- _), _T0-D0-R0-F0-E0, T1, T1-D1-R0-F0-E0, P, P) :- !, D1 is D0 + 1.
classify((?- _), _T0-D0-R0-F0-E0, T1, T1-D1-R0-F0-E0, P, P) :- !, D1 is D0 + 1.
classify((_ :- _), _T0-D0-R0-F0-E0, T1, T1-D0-R1-F0-E0, P, P) :- !, R1 is R0 + 1.
classify((_ --> _), _T0-D0-R0-F0-E0, T1, T1-D0-R1-F0-E0, P, P) :- !, R1 is R0 + 1.
classify(Fact, _T0-D0-R0-F0-E0, T1, T1-D0-R0-F1-E0, P0, [Key|P0]) :-
    F1 is F0 + 1,
    functor(Fact, Name, Arity),
    format(atom(Key), "~w/~w", [Name, Arity]).

tally([], []).
tally([K|Rest], [K-N|Tally]) :-
    count_prefix(Rest, K, 1, N, Remainder),
    tally(Remainder, Tally).

count_prefix([K|Rest], K, N0, N, Remainder) :- !,
    N1 is N0 + 1,
    count_prefix(Rest, K, N1, N, Remainder).
count_prefix(Rest, _, N, N, Rest).
