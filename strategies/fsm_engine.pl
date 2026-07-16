/** <module> Finite State Machine Engine
 *
 * This module provides a common execution engine for all student reasoning
 * strategies (sar_*.pl and smr_*.pl files). It eliminates code duplication
 * by centralizing the state machine execution logic.
 *
 * Each strategy file now only needs to define:
 * 1. transition/3 rules (State, NextState, Interpretation)
 * 2. initial_state/2 (for the strategy setup)
 * 3. accept_state/1 (to identify terminal states)
 *
 * @author UMEDCA System
 * 
 */
:- module(fsm_engine, [
    run_fsm/4,
    run_fsm_with_base/5,
    run_strategy/4
]).

:- use_module(library(lists)).
:- use_module(formalization(grounded_arithmetic)).
:- use_module(pml(pml_operators), [s/1]).

%!      run_fsm(+StrategyModule, +InitialState, +Parameters, -History) is det.
%
%       Generic FSM execution engine that works with any strategy module.
%       
%       @param StrategyModule The module containing transition rules
%       @param InitialState The starting state of the FSM
%       @param Parameters Additional parameters needed by the strategy
%       @param History The complete execution history
run_fsm(StrategyModule, InitialState, Parameters, History) :-
    incur_cost(inference),
    run_fsm_loop(StrategyModule, InitialState, Parameters, [], ReversedHistory),
    reverse(ReversedHistory, History).

%!      run_fsm_with_base(+StrategyModule, +InitialState, +Parameters, +Base, -History) is det.
%
%       FSM execution with a base parameter (for strategies that need base-10 operations).
run_fsm_with_base(StrategyModule, InitialState, Parameters, Base, History) :-
    incur_cost(inference),
    run_fsm_loop_with_base(StrategyModule, InitialState, Parameters, Base, [], ReversedHistory),
    reverse(ReversedHistory, History).

%!      run_strategy(+StrategyModule, +A, +B, -Result) is det.
%
%       High-level interface that handles the complete strategy execution
%       including setup, execution, and result extraction.
run_strategy(StrategyModule, A, B, Result) :-
    % Get the initial state from the strategy module
    call(StrategyModule:setup_strategy(A, B, InitialState, Parameters)),
    
    % Run the FSM
    run_fsm(StrategyModule, InitialState, Parameters, History),
    
    % Extract result from final state
    extract_result(StrategyModule, History, Result).

% --- Internal Implementation ---

%!      run_fsm_loop(+Module, +CurrentState, +Parameters, +AccHistory, -FinalHistory) is det.
%
%       Main FSM execution loop without base parameter.
run_fsm_loop(Module, CurrentState, Parameters, AccHistory, FinalHistory) :-
    % Check if this is an accept state
    ( call(Module:accept_state(CurrentState)) ->
        % Terminal state reached
        call(Module:final_interpretation(CurrentState, FinalInterpretation)),
        create_history_entry(CurrentState, FinalInterpretation, HistoryEntry),
        FinalHistory = [HistoryEntry | AccHistory]
    ;
        % Try to make a transition
        once(call(Module:transition(CurrentState, NextState, Interpretation))),
        create_history_entry(CurrentState, Interpretation, HistoryEntry),
        run_fsm_loop(Module, NextState, Parameters, [HistoryEntry | AccHistory], FinalHistory)
    ).

%!      run_fsm_loop_with_base(+Module, +CurrentState, +Parameters, +Base, +AccHistory, -FinalHistory) is det.
%
%       Main FSM execution loop with base parameter.
run_fsm_loop_with_base(Module, CurrentState, Parameters, Base, AccHistory, FinalHistory) :-
    % Check if this is an accept state  
    ( call(Module:accept_state(CurrentState)) ->
        % Terminal state reached
        call(Module:final_interpretation(CurrentState, FinalInterpretation)),
        create_history_entry(CurrentState, FinalInterpretation, HistoryEntry),
        FinalHistory = [HistoryEntry | AccHistory]
    ;
        % Try to make a transition (with base parameter)
        once(call(Module:transition(CurrentState, Base, NextState, Interpretation))),
        create_history_entry(CurrentState, Interpretation, HistoryEntry),
        run_fsm_loop_with_base(Module, NextState, Parameters, Base, [HistoryEntry | AccHistory], FinalHistory)
    ).

%!      create_history_entry(+State, +Interpretation, -HistoryEntry) is det.
%
%       Creates a standardized history entry from state and interpretation.
create_history_entry(State, Interpretation, step(StateName, StateData, Interpretation)) :-
    extract_state_info(State, StateName, StateData).

%!      extract_state_info(+State, -StateName, -StateData) is det.
%
%       Extracts state name and data from state terms.
extract_state_info(state(Name, Data), Name, Data) :- !.
extract_state_info(state(Name), Name, []) :- !.
extract_state_info(State, State, []).

%!      extract_result(+Module, +History, -Result) is det.
%
%       Extracts the final result from the execution history.
extract_result(Module, History, Result) :-
    ( call(Module:extract_result_from_history(History, Result)) ->
        true
    ;
        % Default: extract from last history entry
        last(History, LastEntry),
        extract_default_result(LastEntry, Result)
    ).

%!      extract_default_result(+HistoryEntry, -Result) is det.
%
%       Default result extraction from history entry.
extract_default_result(step(_, StateData, _), Result) :-
    ( StateData = [Result|_] ->
        true
    ; StateData = Result ->
        true
    ;
        Result = StateData
    ).

% --- Support for Cognitive Cost Integration ---

%!      emit_modal_signal(+ModalContext) is det.
%
%       Emits a modal context signal for embodied learning analysis.
emit_modal_signal(ModalContext) :-
    incur_cost(modal_shift),
    call(s(ModalContext)).

%!      emit_cognitive_state(+CognitiveState) is det.
%
%       Emits a cognitive state signal for learning analysis.
emit_cognitive_state(_CognitiveState) :-
    incur_cost(inference),
    % Could be extended to emit specific cognitive markers
    true.
