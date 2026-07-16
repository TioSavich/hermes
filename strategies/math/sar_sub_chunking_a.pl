/** <module> Student Subtraction Strategy: Chunking Backwards by Place Value
 *
 * This module implements a "chunking" strategy for subtraction, modeled as a
 * finite state machine. The strategy involves subtracting the subtrahend (S)
 * from the minuend (M) in parts, based on place value (hundreds, tens, ones).
 *
 * The process is as follows:
 * 1. Identify the largest place-value chunk of the remaining subtrahend (S).
 *    For example, if S is 234, the first chunk is 200.
 * 2. Subtract this chunk from the current value (which starts at M).
 * 3. Repeat the process with the remainder of S. For S=234, the next chunk
 *    would be 30, then 4.
 * 4. The process ends when the entire subtrahend has been subtracted.
 * 5. The strategy fails if the subtrahend is larger than the minuend.
 *
 * The state of the automaton is represented by the term:
 * `state(Name, CurrentValue, S_Remaining, Chunk)`
 *
 * The history of execution is captured as a list of steps:
 * `step(Name, CurrentValue, S_Remaining, Chunk, Interpretation)`
 *
 * 
 * 
 */
:- module(sar_sub_chunking_a,
          [ run_chunking_a/4,
            % FSM Engine Interface
            setup_strategy/4,
            transition/3,
            transition/4,
            accept_state/1,
            final_interpretation/2,
            extract_result_from_history/2
          ]).

:- use_module(library(lists)).
:- use_module(strategies(fsm_engine)).
:- use_module(formalization(grounded_arithmetic), [incur_cost/1, leading_digit_chunk/3,
                                     integer_to_recollection/2,
                                     recollection_to_integer/2,
                                     subtract_grounded/3]).
:- use_module(arche_trace(sequent_engine), [s/1, comp_nec/1, exp_poss/1]).
:- use_module(math(cgi_base), [current_cgi_base/1]).

%!      run_chunking_a(+M:integer, +S:integer, -FinalResult:integer, -History:list) is det.
%
%       Executes the 'Chunking Backwards by Place Value' subtraction strategy for M - S.
%
%       This predicate initializes and runs a state machine that models the
%       chunking strategy. It first checks if the subtraction is possible (M >= S).
%       If so, it repeatedly identifies the largest place-value component of the
%       remaining subtrahend and subtracts it from the minuend. It traces
%       the entire execution, providing a step-by-step history.
%
%       @param M The Minuend, the number to subtract from.
%       @param S The Subtrahend, the number to subtract in chunks.
%       @param FinalResult The resulting difference (M - S). If S > M, this
%       will be the atom `'error'`.
%       @param History A list of `step/5` terms that describe the state
%       machine's execution path and the interpretation of each step.

run_chunking_a(M, S, FinalResult, History) :-
    % Use the FSM engine to run this strategy
    setup_strategy(M, S, InitialState, Parameters),
    current_cgi_base(Base),
    run_fsm_with_base(sar_sub_chunking_a, InitialState, Parameters, Base, History),
    extract_result_from_history(History, FinalResult).

%!      setup_strategy(+M, +S, -InitialState, -Parameters) is det.
%
%       Sets up the initial state for the chunking subtraction strategy.
setup_strategy(M, S, InitialState, Parameters) :-
    % Check if subtraction is valid
    (S > M ->
        InitialState = state(q_error, 0, 0, 0)
    ;
        InitialState = state(q_init, M, S, 0)
    ),
    Parameters = [M, S],
    
    % Emit modal signal for strategy initiation
    s(exp_poss(initiating_chunking_subtraction_strategy)),
    incur_cost(inference).

%!      transition(+CurrentState, -NextState, -Interpretation) is det.
%       transition(+CurrentState, +Base, -NextState, -Interpretation) is det.
%
%       State transition rules for the chunking subtraction strategy.

% Version without base parameter (for FSM engine compatibility)
transition(CurrentState, NextState, Interpretation) :-
    transition(CurrentState, 10, NextState, Interpretation).

% From q_init, proceed to identify the first chunk.
transition(state(q_init, M, S, _), _, state(q_identify_chunk, M, S, 0), Interp) :-
    s(exp_poss(setting_initial_values_for_chunking)),
    incur_cost(inference),
    format(string(Interp), 'Set CurrentValue=~w. S_Remaining=~w.', [M, S]).

% In q_identify_chunk, determine the next chunk of S to subtract.
% The chunk is the largest part of S based on place value (e.g., hundreds, tens).
%
% GROUNDED (March 2026): Replaced log/^ with leading_digit_chunk/3 from
% grounded_arithmetic. The child doesn't compute logarithms — they count
% through place values (ones, tens, hundreds...) until the next place would
% overshoot. The gear is the same carry mechanism as the DPDA in counting2.pl.
transition(state(q_identify_chunk, CV, S_Rem, _), _Base, state(q_subtract_chunk, CV, S_Rem, Chunk), Interp) :-
    S_Rem > 0,
    grounded_arithmetic:leading_digit_chunk(S_Rem, 10, Chunk),
    s(comp_nec(identifying_largest_place_value_chunk)),
    incur_cost(inference),
    format(string(Interp), 'Identified chunk to subtract: ~w.', [Chunk]).

% If no subtrahend remains, the process is finished.
transition(state(q_identify_chunk, CV, 0, _), _, state(q_accept, CV, 0, 0),
           'S fully subtracted.') :-
    s(comp_nec(completing_chunking_subtraction)),
    incur_cost(inference).

% In q_subtract_chunk, perform the subtraction and loop back to identify the next chunk.
transition(state(q_subtract_chunk, CV, S_Rem, Chunk), _, state(q_identify_chunk, NewCV, NewSRem, 0), Interp) :-
    integer_to_recollection(CV, RecCV),
    integer_to_recollection(Chunk, RecChunk),
    grounded_arithmetic:subtract_grounded(RecCV, RecChunk, RecNewCV),
    recollection_to_integer(RecNewCV, NewCV),
    integer_to_recollection(S_Rem, RecSRem),
    grounded_arithmetic:subtract_grounded(RecSRem, RecChunk, RecNewSRem),
    recollection_to_integer(RecNewSRem, NewSRem),
    s(exp_poss(subtracting_identified_chunk)),
    incur_cost(unit_count),
    format(string(Interp), 'Subtracted ~w. New Value=~w.', [Chunk, NewCV]).

%!      accept_state(+State) is semidet.
%
%       Identifies terminal states.
accept_state(state(q_accept, _, _, _)).
accept_state(state(q_error, _, _, _)).

%!      final_interpretation(+State, -Interpretation) is det.
%
%       Provides final interpretation for terminal states.
final_interpretation(state(q_accept, CV, _, _), Interpretation) :-
    format(string(Interpretation), 'Chunking subtraction complete. Result: ~w.', [CV]).

final_interpretation(state(q_error, _, _, _), 'Chunking subtraction failed: Subtrahend > Minuend.').

%!      extract_result_from_history(+History, -Result) is det.
%
%       Extracts the final result from the execution history.
extract_result_from_history(History, Result) :-
    last(History, LastStep),
    (LastStep = step(state(q_accept, CV, _, _), _, _) ->
        Result = CV
    ; LastStep = step(state(q_error, _, _, _), _, _) ->
        Result = 'error'
    ;
        Result = 'error'
    ).
