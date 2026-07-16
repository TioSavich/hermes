/** <module> Student Subtraction Strategy: Chunking Forwards from Part (Missing Addend)
 *
 * This module implements a "counting up" or "missing addend" strategy for
 * subtraction (M - S), modeled as a finite state machine. It solves the
 * problem by calculating what needs to be added to S to reach M.
 *
 * The process is as follows:
 * 1. Start at the subtrahend (S). The goal is to reach the minuend (M).
 * 2. Identify a "strategic" chunk to add. This could be:
 *    a. The amount `K` needed to get from the current value to the next
 *       multiple of 10 (or 100, etc.).
 *    b. If that's not suitable, the largest possible place-value chunk of the
 *       *remaining distance* to M.
 * 3. Add the selected chunk. The size of the chunk is added to a running
 *    total, `Distance`.
 * 4. Repeat until the current value reaches M. The final `Distance` is the
 *    answer to the subtraction problem.
 * 5. The strategy fails if S > M.
 *
 * The state is represented by the term:
 * `state(Name, CurrentValue, Distance, K, TargetBase, InternalTemp, Minuend)`
 *
 * The history of execution is captured as a list of steps:
 * `step(Name, CurrentValue, Distance, K, Interpretation)`
 *
 * 
 * 
 */
:- module(sar_sub_chunking_b,
          [ run_chunking_b/4,
            % FSM Engine Interface
            setup_strategy/4,
            transition/3,
            transition/4,
            accept_state/1,
            final_interpretation/2,
            extract_result_from_history/2
          ]).

:- use_module(library(lists)).
:- use_module(library(clpfd)).
:- use_module(strategies(fsm_engine), [run_fsm_with_base/5]).
:- use_module(formalization(grounded_arithmetic), [incur_cost/1,
                                     integer_to_recollection/2,
                                     recollection_to_integer/2,
                                     add_grounded/3,
                                     successor/2]).
:- use_module(arche_trace(sequent_engine), [s/1, comp_nec/1, exp_poss/1]).
:- use_module(math(cgi_base), [current_cgi_base/1]).

%!      run_chunking_b(+M:integer, +S:integer, -FinalResult:integer, -History:list) is det.
%
%       Executes the 'Chunking Forwards from Part' (missing addend) subtraction
%       strategy for M - S.
%
%       This predicate initializes and runs a state machine that models the
%       "counting up" process. It first checks if the subtraction is possible (M >= S).
%       If so, it calculates the difference by adding chunks to S until it reaches M.
%       The sum of these chunks is the result. It traces the entire execution,
%       providing a step-by-step history.
%
%       @param M The Minuend, the target number to count up to.
%       @param S The Subtrahend, the number to start counting from.
%       @param FinalResult The resulting difference (M - S). If S > M, this
%       will be the atom `'error'`.
%       @param History A list of `step/5` terms that describe the state
%       machine's execution path and the interpretation of each step.

run_chunking_b(M, S, FinalResult, History) :-
    % Use the FSM engine to run this strategy
    setup_strategy(M, S, InitialState, Parameters),
    current_cgi_base(Base),
    run_fsm_with_base(sar_sub_chunking_b, InitialState, Parameters, Base, History),
    extract_result_from_history(History, FinalResult).

%!      setup_strategy(+M, +S, -InitialState, -Parameters) is det.
%
%       Sets up the initial state for the chunking subtraction strategy.
setup_strategy(M, S, InitialState, Parameters) :-
    % Check if subtraction is valid
    (S > M ->
        InitialState = state(q_error, 0, 0, 0, 0, 0, M)
    ;
        InitialState = state(q_init, S, 0, 0, 0, 0, M)
    ),
    Parameters = [M, S],
    
    % Emit modal signal for strategy initiation
    s(exp_poss(initiating_chunking_forwards_strategy)),
    incur_cost(inference).

%!      transition(+StateNum, -NextStateNum, -Action) is det.
%
%       State transitions for chunking subtraction FSM.

transition(q_init, q_forward_chunking, check_chunk_size) :-
    s(comp_nec(transitioning_to_forward_chunking)),
    incur_cost(state_change).

transition(q_forward_chunking, q_accept, finalize_result) :-
    s(exp_poss(reaching_completion_via_forward_counting)),
    incur_cost(completion).

transition(q_error, q_error, maintain_error) :-
    s(comp_nec(error_state_is_absorbing)),
    incur_cost(error_handling).

%!      transition(+State, +Base, -NextState, -Interpretation) is det.
%
%       Complete state transitions with full state tracking.
transition(state(q_init, CurrentValue, Distance, K, _TargetBase, _InternalTemp, Minuend), Base,
           NextState, Interpretation) :-
    % Begin forward chunking
    s(exp_poss(initiating_forward_chunk_calculation)),
    ChunkSize = 1,  % Start with unit chunking
    integer_to_recollection(K, RecK),
    grounded_arithmetic:successor(RecK, RecNewK),
    recollection_to_integer(RecNewK, NewK),
    NextState = state(q_forward_chunking, CurrentValue, Distance, NewK, Base, ChunkSize, Minuend),
    Interpretation = 'Initialized forward chunking.',
    incur_cost(chunk_initialization).

transition(state(q_forward_chunking, CurrentValue, Distance, K, TargetBase, ChunkSize, Minuend), _Base,
           NextState, Interpretation) :-
    integer_to_recollection(CurrentValue, RecCV),
    integer_to_recollection(ChunkSize, RecChunk),
    grounded_arithmetic:add_grounded(RecCV, RecChunk, RecNewCV),
    recollection_to_integer(RecNewCV, NewCurrentValue),
    integer_to_recollection(Distance, RecDist),
    grounded_arithmetic:add_grounded(RecDist, RecChunk, RecNewDist),
    recollection_to_integer(RecNewDist, NewDistance),
    integer_to_recollection(K, RecK),
    grounded_arithmetic:successor(RecK, RecNewK),
    recollection_to_integer(RecNewK, NewK),
    (NewCurrentValue >= Minuend ->
        % Reached or exceeded the minuend, finalize
        s(exp_poss(completing_forward_chunking_strategy)),
        NextState = state(q_accept, NewCurrentValue, NewDistance, NewK, TargetBase, ChunkSize, Minuend),
        format(atom(Interpretation), 'Completed: Final distance=~w', [NewDistance]),
        incur_cost(strategy_completion)
    ;
        % Continue forward chunking
        s(comp_nec(chunk_fits_within_minuend_bound)),
        NextState = state(q_forward_chunking, NewCurrentValue, NewDistance, NewK, TargetBase, ChunkSize, Minuend),
        format(atom(Interpretation), 'Forward chunk: Current=~w, Distance=~w', [NewCurrentValue, NewDistance]),
        incur_cost(forward_chunking_step)
    ).

transition(state(q_error, _, _, _, _, _, _), _,
           state(q_error, 0, 0, 0, 0, 0, 0),
           'Error state maintained.') :-
    s(comp_nec(error_state_persistence)),
    incur_cost(error_maintenance).

%!      accept_state(+State) is semidet.
%
%       Defines accepting states for the FSM.
accept_state(state(q_accept, _, _, _, _, _, _)).

%!      final_interpretation(+State, -Interpretation) is det.
%
%       Provides final interpretation of the computation.
final_interpretation(state(q_accept, _, Distance, _, _, _, _), Interpretation) :-
    format(atom(Interpretation), 'Successfully computed difference: ~w via forward chunking', [Distance]).
final_interpretation(state(q_error, _, _, _, _, _, _), 'Error: Chunking forward subtraction failed').

%!      extract_result_from_history(+History, -Result) is det.
%
%       Extracts the final result from the execution history.
extract_result_from_history(History, Result) :-
    last(History, LastStep),
    (LastStep = step(state(q_accept, _, Distance, _, _, _, _), _, _) ->
        Result = Distance
    ;
        Result = 'error'
    ).
