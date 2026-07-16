/** <module> Student Subtraction Strategy: Counting Back By Bases and Ones (Take Away)
 *
 * This module implements the 'Counting Back by Bases and then Ones' (CBBO)
 * strategy for subtraction, often conceptualized as "taking away". It is
 * modeled as a finite state machine.
 *
 * The process is as follows:
 * 1. The subtrahend (S) is decomposed into its base-10 components (bases/tens and ones).
 * 2. Starting from the minuend (M), the strategy first "takes away" or
 *    counts back by the number of bases (tens).
 * 3. After all bases are subtracted, it counts back by the number of ones.
 * 4. The final value is the result of the subtraction.
 * 5. The strategy fails if the subtrahend is larger than the minuend.
 *
 * The state of the automaton is represented by the term:
 * `state(Name, CurrentValue, BaseCounter, OneCounter)`
 *
 * The history of execution is captured as a list of steps:
 * `step(Name, CurrentValue, BaseCounter, OneCounter, Interpretation)`
 *
 * 
 * 
 */
:- module(sar_sub_cbbo_take_away,
          [ run_cbbo_ta/4,
            % FSM Engine Interface
            setup_strategy/4,
            transition/3,
            transition/4,
            accept_state/1,
            final_interpretation/2,
            extract_result_from_history/2
          ]).

:- use_module(library(lists)).
:- use_module(strategies(fsm_engine), [run_fsm_with_base/5]).
:- use_module(formalization(grounded_arithmetic), [integer_to_recollection/2, recollection_to_integer/2,
                                  successor/2, predecessor/2,
                                  add_grounded/3, subtract_grounded/3,
                                  greater_than/2, smaller_than/2, equal_to/2,
                                  incur_cost/1]).
:- use_module(formalization(grounded_utils), [base_decompose_grounded/4, base_recompose_grounded/4,
                             is_zero_grounded/1, is_positive_grounded/1]).
:- use_module(arche_trace(sequent_engine), [s/1, comp_nec/1, exp_poss/1]).
:- use_module(math(cgi_base), [current_cgi_base/1]).

%!      run_cbbo_ta(+M:integer, +S:integer, -FinalResult:integer, -History:list) is det.
%
%       Executes the 'Counting Back by Bases and Ones' (Take Away) subtraction
%       strategy for M - S.
%
%       This predicate initializes and runs a state machine that models the
%       CBBO strategy. It first checks if the subtraction is possible (M >= S).
%       If so, it decomposes S and simulates the process of counting back from M,
%       first by tens and then by ones. It traces the entire execution,
%       providing a step-by-step history.
%
%       @param M The Minuend, the number to subtract from.
%       @param S The Subtrahend, the number to subtract.
%       @param FinalResult The resulting difference (M - S). If S > M, this
%       will be the atom `'error'`.
%       @param History A list of `step/5` terms that describe the state
%       machine's execution path and the interpretation of each step.

%!      run_cbbo_ta(+M:integer, +S:integer, -FinalResult:integer, -History:list) is det.
%
%       Executes the 'Counting Back by Bases and Ones' (Take Away) subtraction
%       strategy for M - S using the FSM engine with modal logic integration.
run_cbbo_ta(M, S, FinalResult, History) :-
    % Emit cognitive cost for strategy initiation
    incur_cost(strategy_selection),
    
    % Use the FSM engine to run this strategy
    setup_strategy(M, S, InitialState, Parameters),
    current_cgi_base(Base),
    run_fsm_with_base(sar_sub_cbbo_take_away, InitialState, Parameters, Base, History),
    extract_result_from_history(History, FinalResult).

%%!      setup_strategy(+M, +S, -InitialState, -Parameters) is det.
%
%       Sets up the initial state for the CBBO take away strategy.
setup_strategy(M, S, InitialState, Parameters) :-
    % Check if subtraction is valid
    integer_to_recollection(S, RecS),
    integer_to_recollection(M, RecM),
    (greater_than(RecS, RecM) ->
        InitialState = state(q_error, 0, 0, 0)
    ;
        % Emit cognitive cost for grounded arithmetic operations
        incur_cost(inference),

        % Use grounded decomposition
        current_cgi_base(Base),
        integer_to_recollection(Base, RecBase),
        base_decompose_grounded(RecS, RecBase, RecQuotient, RecRemainder),
        recollection_to_integer(RecQuotient, BC),
        recollection_to_integer(RecRemainder, OC),

        InitialState = state(q_init, M, BC, OC)
    ),
    Parameters = [M, S],

    % Emit modal signal for strategy initiation
    s(exp_poss(initiating_cbbo_take_away_subtraction)),
    incur_cost(inference).

%!      transition(+StateNum, -NextStateNum, -Action) is det.
%
%       State transitions for CBBO take away FSM.

transition(q_init, q_sub_bases, subtract_bases) :-
    s(comp_nec(transitioning_to_base_subtraction)),
    incur_cost(state_change).

transition(q_sub_bases, q_sub_bases, count_back_base) :-
    s(exp_poss(continuing_base_subtraction_iteration)),
    incur_cost(iteration).

transition(q_sub_bases, q_sub_ones, switch_to_ones) :-
    s(comp_nec(completing_base_subtraction_phase)),
    incur_cost(phase_transition).

transition(q_sub_ones, q_sub_ones, count_back_one) :-
    s(exp_poss(continuing_ones_subtraction_iteration)),
    incur_cost(iteration).

transition(q_sub_ones, q_accept, complete_subtraction) :-
    s(comp_nec(finalizing_subtraction_computation)),
    incur_cost(completion).

transition(q_error, q_error, maintain_error) :-
    s(comp_nec(error_state_is_absorbing)),
    incur_cost(error_handling).

%!      transition(+State, +Base, -NextState, -Interpretation) is det.
%
%       Complete state transitions with full state tracking and modal integration.

% From q_init, proceed to subtract the bases (tens).
transition(state(q_init, CV, BC, OC), _,
           state(q_sub_bases, CV, BC, OC), 
           Interpretation) :-
    s(exp_poss(initiating_base_subtraction_phase)),
    format(atom(Interpretation), 'Initialize at M (~w). Decompose S: ~w bases, ~w ones. Proceed to subtract bases.', [CV, BC, OC]),
    incur_cost(initialization).

% Loop in q_sub_bases, counting back by one base (10) at a time.
transition(state(q_sub_bases, CV, BC, OC), Base,
           state(q_sub_bases, NewCV, NewBC, OC),
           Interpretation) :-
    integer_to_recollection(BC, RecBC),
    \+ is_zero_grounded(RecBC),
    s(comp_nec(applying_embodied_base_subtraction)),
    integer_to_recollection(CV, RecCV),
    integer_to_recollection(Base, RecBase),
    subtract_grounded(RecCV, RecBase, RecNewCV),
    recollection_to_integer(RecNewCV, NewCV),
    predecessor(RecBC, RecNewBC),
    recollection_to_integer(RecNewBC, NewBC),
    format(atom(Interpretation), 'Count back by base (-~w). New Value=~w.', [Base, NewCV]),
    incur_cost(base_subtraction).

% When all bases are subtracted, transition to q_sub_ones.
transition(state(q_sub_bases, CV, 0, OC), _, 
           state(q_sub_ones, CV, 0, OC),
           'Bases finished. Switching to ones.') :-
    s(exp_poss(transitioning_from_bases_to_ones)),
    incur_cost(phase_completion).

% Loop in q_sub_ones, counting back by one at a time.
transition(state(q_sub_ones, CV, BC, OC), _,
           state(q_sub_ones, NewCV, BC, NewOC),
           Interpretation) :-
    integer_to_recollection(OC, RecOC),
    \+ is_zero_grounded(RecOC),
    s(comp_nec(applying_embodied_ones_subtraction)),
    integer_to_recollection(CV, RecCV),
    predecessor(RecCV, RecNewCV),
    recollection_to_integer(RecNewCV, NewCV),
    predecessor(RecOC, RecNewOC),
    recollection_to_integer(RecNewOC, NewOC),
    format(atom(Interpretation), 'Count back by one (-1). New Value=~w.', [NewCV]),
    incur_cost(ones_subtraction).

% When all ones are subtracted, transition to the final accept state.
transition(state(q_sub_ones, CV, BC, 0), _, 
           state(q_accept, CV, BC, 0),
           'Subtraction finished.') :-
    s(exp_poss(completing_cbbo_take_away_strategy)),
    incur_cost(strategy_completion).

% Error state transitions
transition(state(q_error, _, _, _), _,
           state(q_error, 0, 0, 0),
           'Error: Subtrahend > Minuend.') :-
    s(comp_nec(error_state_persistence)),
    incur_cost(error_maintenance).

%!      accept_state(+State) is semidet.
%
%       Defines the accept states for the FSM.
accept_state(state(q_accept, _, _, _)).

%!      final_interpretation(+State, -Interpretation) is det.
%
%       Provides final interpretation of the computation.
final_interpretation(state(q_accept, CV, _, _), Interpretation) :-
    format(atom(Interpretation), 'Subtraction finished. Result (Final Position) = ~w.', [CV]).
final_interpretation(state(q_error, _, _, _), 'Error: Subtrahend > Minuend.').

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
