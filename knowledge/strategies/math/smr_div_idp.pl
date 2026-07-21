/** <module> Student Division Strategy: Inverse of Distributive Property (IDP)
 *
 * This module implements a division strategy based on the inverse of the
 * distributive property, modeled as a finite state machine. It solves a
 * division problem (T / S) by using a knowledge base (KB) of known
 * multiplication facts for the divisor S.
 *
 * The process is as follows:
 * 1.  Given a knowledge base of facts for S (e.g., 2*S, 5*S, 10*S), find the
 *     largest known multiple of S that is less than or equal to the
 *     remaining total (T).
 * 2.  Subtract this multiple from T.
 * 3.  Add the corresponding factor to a running total for the quotient.
 * 4.  Repeat the process with the new, smaller remainder until no more known
 *     multiples can be subtracted.
 * 5.  The final quotient is the sum of the factors, and the final remainder
 *     is what's left of the total.
 * 6.  The strategy fails if the divisor (S) is not positive.
 *
 * The state is represented by the term:
 * `state(Name, Remaining, TotalQuotient, PartialTotal, PartialQuotient, KB, Divisor)`
 *
 * The history of execution is captured as a list of steps:
 * `step(Name, Remainder, TotalQuotient, PartialTotal, PartialQuotient, Interpretation)`
 *
 * 
 * 
 */
:- module(smr_div_idp,
          [ run_idp/5,
            run_idp/6,
            % FSM Engine Interface
            setup_strategy/5,
            transition/3,
            transition/4,
            accept_state/1,
            final_interpretation/2,
            extract_result_from_history/2
          ]).

:- use_module(library(lists)).
:- use_module(strategies(fsm_engine), [run_fsm_with_base/5]).
:- use_module(formalization(grounded_arithmetic), [incur_cost/1, integer_to_recollection/2,
                                    recollection_to_integer/2, add_grounded/3,
                                    subtract_grounded/3, smaller_than/2,
                                    greater_than/2]).
:- use_module(formalization(grounded_utils), [is_zero_grounded/1, is_positive_grounded/1]).
:- use_module(pml(pml_operators), [s/1, 'comp_nec'/1, 'exp_poss'/1]).
:- use_module(learner(more_machine_learner), [run_learned_strategy/5]).
:- use_module(learner(fsm_synthesis_engine), [int_to_peano/2, peano_to_int/2]).
:- use_module(math(cgi_base), [current_cgi_base/1]).

%!      run_idp(+T:integer, +S:integer, +KB_in:list, -FinalQuotient:integer, -FinalRemainder:integer) is det.
%
%       Executes the 'Inverse of Distributive Property' division strategy for T / S.
%
%       This predicate initializes and runs a state machine that models the IDP
%       strategy. It first checks for a positive divisor. If valid, it uses the
%       provided knowledge base `KB_in` to repeatedly subtract the largest
%       possible known multiple of `S` from `T`, accumulating the quotient.
%       It traces the entire execution.
%
%       @param T The Dividend (Total).
%       @param S The Divisor.
%       @param KB_in A list of `Multiple-Factor` pairs representing known
%       multiplication facts for `S`. Example: `[20-2, 50-5, 100-10]` for S=10.
%       @param FinalQuotient The calculated quotient of the division.
%       @param FinalRemainder The calculated remainder. If S is not positive,
%       this will be `T`.

run_idp(T, S, KB_in, FinalQuotient, FinalRemainder) :-
    run_idp(T, S, KB_in, FinalQuotient, FinalRemainder, _History).

%!      run_idp(+T, +S, +KB_in, -FinalQuotient, -FinalRemainder, -History) is semidet.
%
%       As run_idp/5, but exposes the FSM execution History so callers get the
%       actual step sequence instead of discarding it.
run_idp(T, S, KB_in, FinalQuotient, FinalRemainder, History) :-
    % Check if division is valid first
    (   integer_to_recollection(S, RecS),
        \+ is_positive_grounded(RecS) ->
        FinalQuotient = 'error', FinalRemainder = T, History = []
    ;
        % Try to extract learned multiplication facts for divisor S
        extract_learned_multiplication_facts(S, LearnedKB),

        % Combine any passed-in KB with learned facts
        append(KB_in, LearnedKB, CombinedKB),

        % If no facts available at all, fail — the elaboration chain
        % requires multiplication to have been learned first.
        CombinedKB \= [],

        % Sort KB descending by multiple (like original)
        keysort(CombinedKB, SortedKB_asc),
        reverse(SortedKB_asc, KB),

        % Use the FSM engine to run this strategy
        setup_strategy(T, S, KB, InitialState, Parameters),
        current_cgi_base(Base),
        run_fsm_with_base(smr_div_idp, InitialState, Parameters, Base, History),
        extract_result_from_history(History, [FinalQuotient, FinalRemainder])
    ).

%!      setup_strategy(+T, +S, +KB, -InitialState, -Parameters) is det.
%
%       Sets up the initial state for the IDP division strategy.
setup_strategy(T, S, KB, InitialState, Parameters) :-
    % Initialize with T as remaining, 0 as total quotient, KB, and S as divisor
    % State format: state(StateName, Remaining, TotalQuotient, PartialT, PartialQ, KB, Divisor)
    InitialState = state(q_init, T, 0, 0, 0, KB, S),
    Parameters = [T, S, KB],
    
    % Emit modal signal for strategy initiation
    s(exp_poss(initiating_inverse_distributive_property_strategy)),
    incur_cost(inference).
%!      transition(+StateNum, -NextStateNum, -Action) is det.
%
%       State transitions for IDP division FSM.

transition(q_init, q_search_KB, search_knowledge_base) :-
    s(comp_nec(transitioning_to_knowledge_base_search)),
    incur_cost(state_change).

transition(q_search_KB, q_apply_fact, apply_found_fact) :-
    s(exp_poss(applying_discovered_multiplication_fact)),
    incur_cost(fact_application).

transition(q_search_KB, q_accept, complete_decomposition) :-
    s(exp_poss(completing_inverse_distributive_decomposition)),
    incur_cost(completion).

transition(q_apply_fact, q_search_KB, continue_search) :-
    s(comp_nec(continuing_iterative_decomposition)),
    incur_cost(iteration).

transition(q_error, q_error, maintain_error) :-
    s(comp_nec(error_state_is_absorbing)),
    incur_cost(error_handling).

%!      transition(+State, +Base, -NextState, -Interpretation) is det.
%
%       Complete state transitions with full state tracking.

% From q_init, proceed to search the knowledge base.
transition(state(q_init, T, TQ, PT, PQ, KB, S), _,
           state(q_search_KB, T, TQ, PT, PQ, KB, S), 
           Interpretation) :-
    s(exp_poss(initializing_knowledge_base_search)),
    format(atom(Interpretation), 'Initialize: ~w / ~w. Loaded known facts for ~w.', [T, S, S]),
    incur_cost(initialization).

% In q_search_KB, find the best known multiple to subtract.
transition(state(q_search_KB, Rem, TQ, _, _, KB, S), _,
           state(q_apply_fact, Rem, TQ, Multiple, Factor, KB, S), 
           Interpretation) :-
    find_best_fact(KB, Rem, Multiple, Factor),
    s(exp_poss(discovering_applicable_multiplication_fact)),
    format(atom(Interpretation), 'Found known multiple: ~w (~w x ~w).', [Multiple, Factor, S]),
    incur_cost(fact_discovery).

% If no suitable fact is found, the process is complete.
transition(state(q_search_KB, Rem, TQ, _, _, KB, S), _,
           state(q_accept, Rem, TQ, 0, 0, KB, S), 
           'No suitable fact found.') :-
    \+ find_best_fact(KB, Rem, _, _),
    s(exp_poss(exhausting_knowledge_base_options)),
    incur_cost(exhaustion).

% In q_apply_fact, subtract the found multiple and add the factor to the quotient.
transition(state(q_apply_fact, Rem, TQ, PT, PQ, KB, S), _,
           state(q_search_KB, NewRem, NewTQ, 0, 0, KB, S), 
           Interpretation) :-
    s(comp_nec(applying_multiplication_fact_decomposition)),
    integer_to_recollection(Rem, RecRem),
    integer_to_recollection(PT, RecPT),
    subtract_grounded(RecRem, RecPT, RecNewRem),
    recollection_to_integer(RecNewRem, NewRem),
    integer_to_recollection(TQ, RecTQ),
    integer_to_recollection(PQ, RecPQ),
    add_grounded(RecTQ, RecPQ, RecNewTQ),
    recollection_to_integer(RecNewTQ, NewTQ),
    format(atom(Interpretation), 'Applied fact. Subtracted ~w. Added ~w to Quotient.', [PT, PQ]),
    incur_cost(fact_application).

transition(state(q_error, _, _, _, _, _, _), _,
           state(q_error, 0, 0, 0, 0, [], 0),
           'Error: Invalid divisor.') :-
    s(comp_nec(error_state_persistence)),
    incur_cost(error_maintenance).

%!      accept_state(+State) is semidet.
%
%       Defines accepting states for the FSM.
accept_state(state(q_accept, _, _, _, _, _, _)).

%!      final_interpretation(+State, -Interpretation) is det.
%
%       Provides final interpretation of the computation.
final_interpretation(state(q_accept, Remainder, Quotient, _, _, _, _), Interpretation) :-
    format(atom(Interpretation), 'Successfully computed division: Quotient=~w, Remainder=~w via IDP strategy', [Quotient, Remainder]).
final_interpretation(state(q_error, _, _, _, _, _, _), 'Error: IDP division failed - invalid divisor').

%!      extract_result_from_history(+History, -Result) is det.
%
%       Extracts the final result from the execution history.
extract_result_from_history(History, [Quotient, Remainder]) :-
    last(History, LastStep),
    (LastStep = step(state(q_accept, Remainder, Quotient, _, _, _, _), _, _) ->
        true
    ;
        Quotient = error,
        Remainder = error
    ).

% find_best_fact/4 is a helper to greedily find the largest applicable known fact.
% It assumes KB is sorted in descending order of multiples.
find_best_fact([Multiple-Factor | _], Rem, Multiple, Factor) :-
    integer_to_recollection(Multiple, RecMultiple),
    integer_to_recollection(Rem, RecRem),
    \+ greater_than(RecMultiple, RecRem).
find_best_fact([_ | Rest], Rem, BestMultiple, BestFactor) :-
    find_best_fact(Rest, Rem, BestMultiple, BestFactor).

%!      extract_learned_multiplication_facts(+Divisor, -LearnedKB) is det.
%
%       Extracts multiplication facts for Divisor from the learned knowledge system.
%       Returns facts in Multiple-Factor format that the system has genuinely learned.
%
%       This is the gear-wiring point: when the system has learned multiplication
%       through the ORR cycle (crisis → oracle → synthesis), those learned
%       strategies become available to division. IDP doesn't get a hardcoded
%       times table — it gets the output of running the multiplication gear.
%
%       The child who learned their 7-times-tables can now use them for division.
%       But they have to HAVE learned them first. If no multiplication strategy
%       exists, IDP gets an empty KB and must fall back to other division strategies.
%
extract_learned_multiplication_facts(Divisor, LearnedKB) :-
    % First check: has the system learned ANY multiplication strategy?
    (   has_learned_multiplication
    ->  % Generate facts by running the learned multiplication gear
        % for factors 1 through a reasonable ceiling.
        % The ceiling is generous — IDP's greedy search will only use what it needs.
        MaxFactor = 20,
        findall(Multiple-Factor,
            (   between(1, MaxFactor, Factor),
                learned_multiplication_fact(Divisor, Factor, Multiple)
            ),
            LearnedKB)
    ;   % No multiplication strategy learned yet — empty KB.
        % This is honest: you can't use times tables you don't have.
        LearnedKB = []
    ).

%!      has_learned_multiplication is semidet.
%
%       True if the system has learned at least one multiplication strategy
%       through the ORR cycle.
has_learned_multiplication :-
    clause(more_machine_learner:run_learned_strategy(_, _, _, StratName, _), _),
    % Check that it's a multiplication strategy (not add/subtract/divide)
    multiplication_strategy_name(StratName),
    !.

multiplication_strategy_name('C2C').
multiplication_strategy_name('CBO').
multiplication_strategy_name('Commutative Reasoning').
multiplication_strategy_name('DR').

%!      learned_multiplication_fact(+Divisor, +Factor, -Multiple) is semidet.
%
%       Computes Divisor * Factor = Multiple using a learned multiplication strategy.
%       This IS the gear — division calls multiplication, not a lookup table.
%
learned_multiplication_fact(Divisor, Factor, Multiple) :-
    integer_to_recollection(Divisor, RecDivisor),
    is_positive_grounded(RecDivisor),
    integer_to_recollection(Factor, RecFactor),
    is_positive_grounded(RecFactor),
    % Convert to Peano for the learned strategy interface
    fsm_synthesis_engine:int_to_peano(Divisor, PD),
    fsm_synthesis_engine:int_to_peano(Factor, PF),
    % Run the learned multiplication strategy (once — deterministic).
    % Without once/1, duplicate peano_to_int/2 clauses in fsm_synthesis_engine
    % cause exponential backtracking through findall.
    catch(
        once(more_machine_learner:run_learned_strategy(PD, PF, PResult, _StratName, _Trace)),
        _Error,
        fail
    ),
    % Convert result back to integer (also deterministic)
    once(fsm_synthesis_engine:peano_to_int(PResult, Multiple)).
