/** Focused check for the shared role-bearing automaton input decoder. */

:- module(shared_role_input_decoder_check, [main/0]).

:- use_module(library(http/json), [atom_json_dict/3]).
:- use_module(strategies(automaton_input_contracts),
              [automaton_input_contract/5]).
:- use_module(strategies(automaton_role_input_decoder), []).
:- use_module('../bigred/loops/loop_driver.pl', []).

main :-
    findall(contract(Family, Kind, Input),
            role_contract(Family, Kind, Input),
            Contracts),
    length(Contracts, ContractCount),
    (   ContractCount =:= 23
    ->  true
    ;   format("expected 23 role-bearing contracts, found ~w~n", [ContractCount]),
        fail
    ),
    maplist(check_contract, Contracts),
    check_loud_failure,
    check_legacy_numeric_fallback,
    format('PASS shared role input decoder: 23 contract examples compute; worker and loop operands agree; malformed signed_division names its kind~n').

role_contract(Family, Kind, Input) :-
    automaton_input_contract(Family, Kind, _, ExampleAtom, _),
    atom_json_dict(ExampleAtom, Input, []),
    get_dict(kind, Input, InputKind),
    automaton_role_input_decoder:role_input_kind(InputKind).

check_contract(contract(Family, Kind, Input)) :-
    automaton_role_input_decoder:decode_role_inputs(Input, SharedA, SharedB),
    hermes_encyclopedia:trace_inputs(Input, LoopA, LoopB),
    SharedA == LoopA,
    SharedB == LoopB,
    loop_driver:aa_run(Family, Kind, Input, LoopOutcome),
    direct_outcome(Family, Kind, SharedA, SharedB, DirectOutcome),
    LoopOutcome == DirectOutcome,
    LoopOutcome = result(_, _, _).

direct_outcome(Family, Kind, A, B, result(Result, Expected, Validity)) :-
    action_automata_registry:run_action_automaton(
        Family, Kind, A, B, action_outcome(_, Fields), _),
    memberchk(result(Result), Fields),
    (memberchk(expected(Expected), Fields) -> true ; Expected = none),
    (memberchk(validity(Validity), Fields) -> true ; Validity = none).

check_loud_failure :-
    BadInput = _{kind:"signed_division", dividend:6, divisor:0},
    catch(automaton_role_input_decoder:decode_role_inputs(BadInput, _, _),
          DecodeError, true),
    DecodeError = error(role_input_decode_failed("signed_division"), _),
    loop_driver:aa_run(integer, signed_division_by_sign_rule,
                       BadInput, LoopOutcome),
    LoopOutcome = error(input_decode_raised(
        error(role_input_decode_failed("signed_division"), _))).

check_legacy_numeric_fallback :-
    hermes_encyclopedia:trace_inputs(_{a:7, b:3}, A, B),
    A == 7,
    B == 3.
