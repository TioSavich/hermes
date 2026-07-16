/** <module> The Dialectical Engine (The Rhythm of Thought)
 *
 *  This module implements the core engine driving the dialectical rhythm
 *  (Compression ↓ and Expansion ↑). It integrates the Finite State Machine (FSM)
 *  engine with the high-level execution controller (ORR Cycle).
 *
 *  It manages the execution flow, handles perturbations (Tension A), and
 *  initiates the critique/sublation process.
 *
 *  (Synthesis_1, Chapter 4.2)
 */
:- module(dialectical_engine,
          [
            run_computation/2, % Main entry point for the ORR cycle
            run_fsm/4          % Generic FSM executor
          ]).

:- use_module(embodied_prover, [proves/4]).
% The critique module is used to handle the response to perturbations.
:- use_module(critique, [accommodate/1]).
:- use_module(pml(utils), [select/3]).

% =================================================================
% Part 1: The Execution Controller (ORR Cycle Management)
% =================================================================

%!      run_computation(+Sequent:term, +Limit:integer) is semidet.
%
%       The main entry point for the dialectical engine (the ORR cycle).
%       It attempts to prove the given Sequent within the resource Limit.
%
%       If a perturbation occurs (e.g., resource exhaustion, incoherence),
%       it catches the error and initiates the critique/accommodation process.
%
%       @param Sequent The sequent to be proven.
%       @param Limit The maximum number of inference steps allowed.
run_computation(Sequent, Limit) :-
    format('--- Initiating Computation (Limit: ~w) ---~n', [Limit]),
    % The prover (Observe/Reflect) runs, potentially throwing a perturbation.
    catch(
        call_prover(Sequent, Limit, Proof),
        Error,
        % If a perturbation is caught, initiate Reorganization/Accommodation.
        handle_perturbation(Error, Sequent, Limit)
    ).

%!      call_prover(+Sequent, +Limit, -Proof) is det.
%
%       Wrapper for the embodied prover.
call_prover(Sequent, Limit, Proof) :-
    proves(Sequent, Limit, R_Out, Proof),
    format('--- Computation Successful (Resources Remaining: ~w) ---~n', [R_Out]).
    % Optionally, proactive reflection could be added here (analyze Proof for optimizations).

%!      handle_perturbation(+Error, +Sequent, +Limit) is semidet.
%
%       Catches perturbations from the prover and initiates the accommodation process.
%       After accommodation, it retries the computation.
%       Note: Proof is not available here as the error occurred during execution.
handle_perturbation(perturbation(Type), Sequent, Limit) :-
    format('--- Perturbation Detected: ~w. Initiating Critique/Accommodation ---~n', [Type]),

    % Create the trigger for the critique module.
    Trigger = perturbation(Type, Sequent),

    % Attempt to accommodate the disequilibrium (Reorganize).
    ( accommodate(Trigger) ->
        writeln('--- Accommodation Complete. Retrying Computation ---'),
        % Retry the original computation.
        run_computation(Sequent, Limit)
    ;
        format('--- Accommodation Failed. Computation halted. ---~n', []),
        fail
    ).

handle_perturbation(Error, _, _) :-
    % Handle unexpected errors.
    format('An unhandled error occurred: ~w~n', [Error]),
    fail.


% =================================================================
% Part 2: Finite State Machine (FSM) Engine
% =================================================================
% A generic engine for running automata (practices/abilities).

%!      run_fsm(+Module, +InitialState, +Parameters, -History) is det.
%
%       Generic FSM execution engine.
%       The Module must define transition/3, accept_state/1.
%
%       @param Module The module containing the FSM definition.
%       @param InitialState The starting state.
%       @param Parameters Contextual parameters for the FSM.
%       @param History The execution history (list of steps).
run_fsm(Module, InitialState, Parameters, History) :-
    run_fsm_loop(Module, InitialState, Parameters, [], ReversedHistory),
    reverse(ReversedHistory, History).

run_fsm_loop(Module, CurrentState, Parameters, AccHistory, FinalHistory) :-
    % Check if this is an accept state
    ( call(Module:accept_state(CurrentState)) ->
        % Terminal state reached
        (current_predicate(Module:final_interpretation/2) ->
            call(Module:final_interpretation(CurrentState, Interpretation))
        ;
            Interpretation = accept
        ),
        create_history_entry(CurrentState, Interpretation, HistoryEntry),
        FinalHistory = [HistoryEntry | AccHistory]
    ;
        % Try to make a transition
        ( once(call(Module:transition(CurrentState, NextState, Interpretation))) ->
            create_history_entry(CurrentState, Interpretation, HistoryEntry),
            run_fsm_loop(Module, NextState, Parameters, [HistoryEntry | AccHistory], FinalHistory)
        ;
            % Handle failure to transition (Stuck state)
            Interpretation = stuck,
            create_history_entry(CurrentState, Interpretation, HistoryEntry),
            FinalHistory = [HistoryEntry | AccHistory]
        )
    ).

create_history_entry(State, Interpretation, step(StateName, StateData, Interpretation)) :-
    extract_state_info(State, StateName, StateData).

extract_state_info(state(Name, Data), Name, Data) :- !.
extract_state_info(state(Name), Name, []) :- !.
extract_state_info(State, State, []).
