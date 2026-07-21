/** <module> Teacher Local Prolog Provider - Strategy Black Box
 *
 * This module implements the "Normative Oracle" - a black box interface to
 * the pre-defined expert strategies (sar_* and smr_* modules). The oracle
 * is intentionally isolated from the primordial machine, accessible only
 * through a single, restricted interface: query_oracle/4.
 *
 * ARCHITECTURAL SEPARATION:
 * The primordial machine CANNOT directly access the internal workings of
 * expert strategies. It can only observe their external results and
 * interpretations. This enforces the philosophical position that learning
 * must occur through "recognition" rather than "introspection."
 *
 * PHILOSOPHICAL GROUNDING:
 * The oracle represents the "normative" - the culturally established ways
 * of doing mathematics. The primordial machine is like a student who hears
 * a friend say "I added 8+5 by rearranging to make 10." The student knows
 * the answer (13) and has a linguistic description of the method, but must
 * reconstruct the internal rational structure using only their own primitive
 * cognitive tools.
 *
 * This is Pragmatic Expressive Bootstrapping: observing vocabulary (V) and
 * reconstructing the practice (P) that makes it intelligible.
 *
 * BLACK BOX CONSTRAINT:
 * The oracle returns ONLY:
 *   1. The final numerical result
 *   2. A high-level textual interpretation
 *
 * The oracle NEVER returns:
 *   - Step-by-step execution traces
 *   - Internal state transitions
 *   - FSM structures
 *   - Intermediate computational states
 *
 * This forces the learner into genuine synthesis, not template matching.
 *
 * SURFACE REGISTER — CRISIS, NOT DEMONSTRATION:
 * This oracle serves the crisis pipeline, and for IDP division it differs
 * on purpose from the strategy-explorer surface
 * (knowledge/strategies/hermeneutic_calculator.pl). IDP recalls multiplication facts.
 * Here the knowledge base stays empty: run_idp/6 unions in only the facts
 * the learner has earned through the ORR cycle, and until multiplication
 * has been learned, query_oracle/4 for IDP throws a named
 * prerequisite_gap error rather than producing a result. That refusal is
 * load-bearing (FRACTION_CRISIS_ASSESSMENT.md, gap 1): the elaboration
 * chain add → multiply → divide has to be earned, not given. The explorer
 * surface instead supplies a labeled demo times table
 * (hermeneutic_calculator:demo_multiplication_facts/2) so visitors can
 * watch the strategy run; its results carry demo provenance. Same
 * strategy, two registers, and the split is deliberate.
 *
 * @author UMEDCA System - Oracle Architecture
 * @version 1.0
 */

:- module(teacher_local_prolog, [
    query_teacher/4,
    list_available_strategies/2,
    strategy_appropriate_for/3,
    estimate_strategy_cost/5
]).

% Load the strategy modules (via file_search_path alias math(...))
:- use_module(math(sar_add_counting_on), [run_counting_on/4]).
:- use_module(math(sar_add_cobo), [run_cobo/4]).
:- use_module(math(sar_add_chunking), [run_chunking/4]).
:- use_module(math(sar_add_rmb), [run_rmb/4]).
:- use_module(math(sar_add_rounding), [run_rounding/4]).

% Subtraction strategies
:- use_module(math(sar_sub_counting_back), [run_counting_back/4]).
:- use_module(math(sar_sub_cobo_missing_addend), [run_cobo_ma/4]).
:- use_module(math(sar_sub_cbbo_take_away), [run_cbbo_ta/4]).
:- use_module(math(sar_sub_decomposition), [run_decomposition/4]).
:- use_module(math(sar_sub_rounding), [run_sub_rounding/4]).
:- use_module(math(sar_sub_sliding), [run_sliding/4]).
:- use_module(math(sar_sub_chunking_a), [run_chunking_a/4]).
:- use_module(math(sar_sub_chunking_b), [run_chunking_b/4]).
:- use_module(math(sar_sub_chunking_c), [run_chunking_c/4]).

% Multiplication strategies
:- use_module(math(smr_mult_c2c), [run_c2c/4]).
:- use_module(math(smr_mult_cbo), [run_cbo_mult/5]).
:- use_module(math(smr_mult_commutative_reasoning), [run_commutative_mult/4]).
:- use_module(math(smr_mult_dr), [run_dr/4]).

% Division strategies
:- use_module(math(smr_div_cbo), [run_cbo_div/5]).
:- use_module(math(smr_div_dealing_by_ones), [run_dealing_by_ones/4]).
:- use_module(math(smr_div_idp), [run_idp/5]).
:- use_module(math(smr_div_ucr), [run_ucr/4]).

% Fraction strategies (Jason's schemes — Steffe's ENS-based fractional reasoning)
:- use_module(math(jason_fsm), [run_pfs/5, run_fcs/5]).

% Load the hermeneutic calculator for strategy listing
:- use_module(strategies(hermeneutic_calculator), [list_strategies/2]).

%!      query_teacher(+Operation, +StrategyName, -Result, -Interpretation) is semidet.
%
%       The SOLE interface to the normative oracle. Given an arithmetic
%       operation and a strategy name, returns the numerical result and a
%       high-level interpretation of the method used.
%
%       BLACK BOX ENFORCEMENT:
%       - Input: Operation (e.g., add(8,5)) and StrategyName (e.g., 'RMB')
%       - Output: Result (e.g., 13) and Interpretation (e.g., 'Rearrange to make base 10')
%       - Hidden: All internal execution traces, state transitions, FSM structures
%
%       USAGE BY PRIMORDIAL MACHINE:
%       When the primordial machine encounters a crisis (resource_exhaustion),
%       it can query the oracle to see how an expert would solve the problem.
%       The machine receives the "what" (result) and "how" (interpretation),
%       but must synthesize its own "why" (FSM structure) from primitives.
%
%       @param Operation A compound term representing the arithmetic operation.
%                        Format: op(Num1, Num2) where op is add, subtract, multiply, or divide
%       @param StrategyName An atom identifying the expert strategy to use.
%                           Must be a valid strategy name from list_strategies/2.
%       @param Result The final numerical result (integer).
%       @param Interpretation A textual description of the strategy's approach (atom or string).
%
%       @throws error(domain_error) if StrategyName is not valid for the operation
%       @throws error(type_error) if Operation is malformed
%
%       @example Query the oracle for addition using "Rearranging to Make Bases"
%           ?- query_oracle(add(8,5), 'RMB', Result, Interp).
%           Result = 13,
%           Interp = 'Rearrange to make base 10: 8+5 = (8+2)+3 = 10+3 = 13'.
%
query_teacher(Operation, StrategyName, Result, Interpretation) :-
    % Validate and decompose the operation
    decompose_operation(Operation, Num1, Op, Num2),

    % Execute the strategy directly (bypassing hermeneutic_calculator due to its bugs)
    % This captures the full execution history
    execute_strategy(Num1, Op, Num2, StrategyName, Result, FullHistory),

    % Extract ONLY the high-level interpretation from the history
    % This is the BLACK BOX boundary - internal states are discarded
    extract_interpretation(StrategyName, Op, Num1, Num2, Result, FullHistory, Interpretation).

%!      execute_strategy(+Num1, +Op, +Num2, +StrategyName, -Result, -History) is semidet.
%
%       Executes a specific strategy directly by calling the appropriate module.
%       This bypasses the buggy hermeneutic_calculator dispatcher.
%
execute_strategy(Num1, +, Num2, 'Counting On', Result, History) :-
    sar_add_counting_on:run_counting_on(Num1, Num2, Result, History).
execute_strategy(Num1, +, Num2, 'COBO', Result, History) :-
    sar_add_cobo:run_cobo(Num1, Num2, Result, History).
execute_strategy(Num1, +, Num2, 'Chunking', Result, History) :-
    sar_add_chunking:run_chunking(Num1, Num2, Result, History).
execute_strategy(Num1, +, Num2, 'RMB', Result, History) :-
    sar_add_rmb:run_rmb(Num1, Num2, Result, History).
execute_strategy(Num1, +, Num2, 'Rounding', Result, History) :-
    sar_add_rounding:run_rounding(Num1, Num2, Result, History).

% Subtraction Strategies
execute_strategy(Num1, -, Num2, 'Counting Back', Result, History) :-
    sar_sub_counting_back:run_counting_back(Num1, Num2, Result, History).
execute_strategy(Num1, -, Num2, 'COBO (Missing Addend)', Result, History) :-
    sar_sub_cobo_missing_addend:run_cobo_ma(Num1, Num2, Result, History).
execute_strategy(Num1, -, Num2, 'CBBO (Take Away)', Result, History) :-
    sar_sub_cbbo_take_away:run_cbbo_ta(Num1, Num2, Result, History).
execute_strategy(Num1, -, Num2, 'Decomposition', Result, History) :-
    sar_sub_decomposition:run_decomposition(Num1, Num2, Result, History).
execute_strategy(Num1, -, Num2, 'Rounding', Result, History) :-
    sar_sub_rounding:run_sub_rounding(Num1, Num2, Result, History).
execute_strategy(Num1, -, Num2, 'Sliding', Result, History) :-
    sar_sub_sliding:run_sliding(Num1, Num2, Result, History).
execute_strategy(Num1, -, Num2, 'Chunking A', Result, History) :-
    sar_sub_chunking_a:run_chunking_a(Num1, Num2, Result, History).
execute_strategy(Num1, -, Num2, 'Chunking B', Result, History) :-
    sar_sub_chunking_b:run_chunking_b(Num1, Num2, Result, History).
execute_strategy(Num1, -, Num2, 'Chunking C', Result, History) :-
    sar_sub_chunking_c:run_chunking_c(Num1, Num2, Result, History).

% Multiplication Strategies
execute_strategy(Num1, *, Num2, 'C2C', Result, History) :-
    smr_mult_c2c:run_c2c(Num1, Num2, Result, History).
execute_strategy(Num1, *, Num2, 'CBO', Result, History) :-
    smr_mult_cbo:run_cbo_mult(Num1, Num2, 10, Result, History).
execute_strategy(Num1, *, Num2, 'Commutative Reasoning', Result, History) :-
    smr_mult_commutative_reasoning:run_commutative_mult(Num1, Num2, Result, History).
execute_strategy(Num1, *, Num2, 'DR', Result, History) :-
    smr_mult_dr:run_dr(Num1, Num2, Result, History).

% Division Strategies
execute_strategy(Num1, /, Num2, 'CGOB', Result, History) :-
    % /6 exposes the FSM step History; the /5 form's 5th arg is the remainder.
    smr_div_cbo:run_cbo_div(Num1, Num2, 10, Result, _Remainder, History).
execute_strategy(Num1, /, Num2, 'Dealing by Ones', Result, History) :-
    smr_div_dealing_by_ones:run_dealing_by_ones(Num1, Num2, Result, History).
execute_strategy(Num1, /, Num2, 'IDP', Result, History) :-
    % CRISIS path: no hardcoded KB — IDP must rely on learned multiplication
    % facts, which run_idp/6 unions in from the more_machine_learner. This
    % makes the elaboration chain (add → multiply → divide) real; see
    % knowledge/strategies/FRACTION_CRISIS_ASSESSMENT.md, gap 1. When nothing has been
    % learned yet, the honest outcome is a named prerequisite gap, not the
    % catch-all not_implemented error (IDP IS implemented — what is missing
    % is developmental, not code). The demonstration surface
    % (knowledge/strategies/hermeneutic_calculator.pl) differs on purpose: it supplies
    % a labeled demo times table so visitors can watch the strategy run.
    (   smr_div_idp:run_idp(Num1, Num2, [], Result, _Remainder, History)
    ->  true
    ;   throw(error(prerequisite_gap(idp_requires_learned_multiplication_facts),
                    context(teacher_local_prolog,
                            'IDP divides by recalling learned multiplication facts; this learner has not learned any yet. Learn a multiplication strategy first, or use the strategy explorer, which runs IDP on a labeled demo times table.')))
    ).
execute_strategy(Num1, /, Num2, 'UCR', Result, History) :-
    smr_div_ucr:run_ucr(Num1, Num2, Result, History).

% Fraction Strategies (Jason's ENS-based schemes)
execute_strategy(Num, fraction, Den, 'PFS', Result, Trace) :-
    Whole = unit(1, "Reference Unit"),
    jason_fsm:run_pfs(Whole, Num, Den, ResultUnit, Trace),
    ( ResultUnit = unit(ResultValue, _) -> Result = ResultValue ; Result = ResultUnit ).

execute_strategy(OuterFrac, fraction_composition, InnerFrac, 'FCS', Result, Trace) :-
    Whole = unit(1, "Reference Unit"),
    OuterFrac = A-B,
    InnerFrac = C-D,
    jason_fsm:run_fcs(Whole, A-B, C-D, ResultUnit, Trace),
    ( ResultUnit = unit(ResultValue, _) -> Result = ResultValue ; Result = ResultUnit ).

% Catch-all for unimplemented strategies
execute_strategy(_Num1, Op, _Num2, StrategyName, _Result, _History) :-
    throw(error(not_implemented(execute_strategy(Op, StrategyName)),
                context(teacher_local_prolog, 'Strategy not yet implemented in local teacher provider'))).

%!      decompose_operation(+Operation, -Num1, -Op, -Num2) is det.
%
%       Decomposes an operation term into its components.
%       Validates that the operation is well-formed.
decompose_operation(add(Num1, Num2), Num1, +, Num2) :-
    integer(Num1), integer(Num2).
decompose_operation(subtract(Num1, Num2), Num1, -, Num2) :-
    integer(Num1), integer(Num2).
decompose_operation(multiply(Num1, Num2), Num1, *, Num2) :-
    integer(Num1), integer(Num2).
decompose_operation(divide(Num1, Num2), Num1, /, Num2) :-
    integer(Num1), integer(Num2), Num2 \= 0.

% Fraction operations — PFS operates on a unit whole
decompose_operation(fraction(Num, Den), Num, fraction, Den) :-
    integer(Num), Num >= 0, integer(Den), Den > 0.

% Fraction composition — FCS finds (A/B) of (C/D) of a unit whole
decompose_operation(fraction_composition(A-B, C-D), A-B, fraction_composition, C-D) :-
    integer(A), A >= 0, integer(B), B > 0,
    integer(C), C >= 0, integer(D), D > 0.

decompose_operation(Op, _, _, _) :-
    throw(error(type_error(operation, Op),
                context(query_teacher/4, 'Operation must be add/subtract/multiply/divide/fraction/fraction_composition with valid arguments'))).

%!      extract_interpretation(+StrategyName, +Op, +Num1, +Num2, +Result, +History, -Interpretation) is det.
%
%       Extracts a high-level textual interpretation from the execution history.
%       This is where we enforce the BLACK BOX constraint - we summarize the
%       approach without revealing internal computational states.
%
%       The interpretation should be:
%       - High-level (conceptual, not computational)
%       - Linguistic (uses mathematical vocabulary)
%       - Sufficient to constrain synthesis (guides the search)
%       - Insufficient for template matching (doesn't give away the FSM)
%
extract_interpretation('Counting On', +, Num1, Num2, Result, _History, Interpretation) :-
    format(atom(Interpretation),
           'Count on from ~w by ones, ~w times, to reach ~w',
           [Num1, Num2, Result]).

extract_interpretation('COBO', +, Num1, Num2, Result, _History, Interpretation) :-
    % COBO = Count On by Bases and Ones: decompose B into tens and ones,
    % count on by 10s, then count on by 1s. NOT simple counting on.
    Bases is Num2 // 10,
    Ones is Num2 mod 10,
    format(atom(Interpretation),
           'Count on by bases then ones: Start at ~w, count on ~w tens then ~w ones to reach ~w',
           [Num1, Bases, Ones, Result]).

extract_interpretation('RMB', +, Num1, Num2, Result, _History, Interpretation) :-
    % Determine which number was closer to base 10
    Dist1 is abs(10 - Num1),
    Dist2 is abs(10 - Num2),
    (   Dist1 < Dist2
    ->  From = Num1, Adding = Num2
    ;   From = Num2, Adding = Num1
    ),
    format(atom(Interpretation),
           'Rearrange to make base 10: Start at ~w, move units from ~w to reach 10, then add remainder to get ~w',
           [From, Adding, Result]).

extract_interpretation('Chunking', +, Num1, Num2, Result, _History, Interpretation) :-
    format(atom(Interpretation),
           'Chunking: Break ~w+~w into decade chunks and ones, combine to get ~w',
           [Num1, Num2, Result]).

extract_interpretation('Rounding', +, _Num1, _Num2, Result, _History, Interpretation) :-
    format(atom(Interpretation),
           'Rounding: Round one number to nearest ten, adjust, result is ~w',
           [Result]).

% Subtraction interpretations
extract_interpretation('Counting Back', -, Minuend, Subtrahend, Result, _History, Interpretation) :-
    format(atom(Interpretation),
           'Count back from ~w by ones, ~w times, to reach ~w',
           [Minuend, Subtrahend, Result]).

extract_interpretation('COBO (Missing Addend)', -, Minuend, Subtrahend, Result, _History, Interpretation) :-
    format(atom(Interpretation),
           'Count on from subtrahend: Start at ~w, count up to ~w, the gap is ~w',
           [Subtrahend, Minuend, Result]).

extract_interpretation('CBBO (Take Away)', -, Minuend, Subtrahend, Result, _History, Interpretation) :-
    format(atom(Interpretation),
           'Count back from bigger: Start at ~w, count back ~w times to reach ~w',
           [Minuend, Subtrahend, Result]).

extract_interpretation('Decomposition', -, Minuend, Subtrahend, Result, _History, Interpretation) :-
    format(atom(Interpretation),
           'Decomposition: Break ~w into parts, subtract ~w from each part, recombine to get ~w',
           [Minuend, Subtrahend, Result]).

extract_interpretation('Sliding', -, _Minuend, _Subtrahend, Result, _History, Interpretation) :-
    format(atom(Interpretation),
           'Sliding: Adjust both numbers by same amount to simplify, then subtract to get ~w',
           [Result]).

extract_interpretation(Name, -, _, _, Result, _History, Interpretation) :-
    atom_string(Name, NameStr),
    (   sub_string(NameStr, _, _, _, "Chunking")
    ->  format(atom(Interpretation), 'Chunking subtraction to get ~w', [Result])
    ;   format(atom(Interpretation), 'Subtraction strategy ~w yields ~w', [Name, Result])
    ).

% Multiplication interpretations
extract_interpretation('CBO', *, Num1, Num2, Result, _History, Interpretation) :-
    format(atom(Interpretation),
           'Conversion to bases and ones: Regroup ~w groups of ~w by moving ones to make bases, then read off bases plus leftover ones to get ~w',
           [Num1, Num2, Result]).

extract_interpretation('C2C', *, Num1, Num2, Result, _History, Interpretation) :-
    format(atom(Interpretation),
           'Coordinating two counts: Count ~w copies of ~w by ones while tracking both the items and the number of groups to get ~w',
           [Num1, Num2, Result]).

extract_interpretation('Commutative Reasoning', *, Num1, Num2, Result, _History, Interpretation) :-
    format(atom(Interpretation),
           'Commutative reasoning: Recognize ~w×~w = ~w×~w for efficiency, result is ~w',
           [Num1, Num2, Num2, Num1, Result]).

extract_interpretation('DR', *, Num1, Num2, Result, _History, Interpretation) :-
    format(atom(Interpretation),
           'Distributive reasoning: Split the group size in ~w×~w into easier parts, multiply each, and recombine to get ~w',
           [Num1, Num2, Result]).

% Division interpretations
extract_interpretation('CGOB', /, Dividend, Divisor, Result, _History, Interpretation) :-
    format(atom(Interpretation),
           'Conversion to groups other than bases: See groups of ~w inside each base of ~w, take ones off each base to form more such groups, finding ~w groups',
           [Divisor, Dividend, Result]).

extract_interpretation('Dealing by Ones', /, Dividend, Divisor, Result, _History, Interpretation) :-
    format(atom(Interpretation),
           'Dealing by ones: Distribute ~w items one-by-one into ~w groups, ~w per group',
           [Dividend, Divisor, Result]).

extract_interpretation('IDP', /, Dividend, Divisor, Result, _History, Interpretation) :-
    format(atom(Interpretation),
           'Inverse of the distributive property: Split ~w into known multiples of ~w and sum the factors to get ~w',
           [Dividend, Divisor, Result]).

extract_interpretation('UCR', /, Dividend, Divisor, Result, _History, Interpretation) :-
    format(atom(Interpretation),
           'Using commutative reasoning: Reinterpret the number of groups so ~w÷~w can be solved as measurement division, giving ~w',
           [Dividend, Divisor, Result]).

% Fraction interpretations
extract_interpretation('PFS', fraction, Num, Den, Result, _History, Interpretation) :-
    format(atom(Interpretation),
           'Partitive fractional scheme: Partition the whole into ~w equal parts, disembed one part (1/~w), iterate ~w times to get ~w',
           [Den, Den, Num, Result]).

extract_interpretation('FCS', fraction_composition, OuterFrac, InnerFrac, Result, _History, Interpretation) :-
    OuterFrac = A-B,
    InnerFrac = C-D,
    format(atom(Interpretation),
           'Fractional composition scheme: Find ~w/~w of ~w/~w of the whole through metamorphic accommodation (nested partitioning), yielding ~w',
           [A, B, C, D, Result]).

% Generic fallback
extract_interpretation(StrategyName, _Op, _Num1, _Num2, Result, _History, Interpretation) :-
    format(atom(Interpretation),
           'Strategy ~w produces result ~w',
           [StrategyName, Result]).

%!      list_available_strategies(+Operation, -Strategies) is det.
%
%       Lists the available expert strategies for a given operation type.
%       This allows the primordial machine to know what strategies it could
%       query from the oracle.
%
%       @param Operation The operation type (add, subtract, multiply, divide)
%       @param Strategies A list of strategy names (atoms)
%
list_available_strategies(add, ['Counting On', 'RMB', 'COBO', 'Chunking', 'Rounding']).
list_available_strategies(subtract, ['Counting Back', 'COBO (Missing Addend)', 'CBBO (Take Away)', 'Decomposition', 'Rounding', 'Sliding', 'Chunking A', 'Chunking B', 'Chunking C']).
list_available_strategies(multiply, ['C2C', 'CBO', 'Commutative Reasoning', 'DR']).
list_available_strategies(divide, ['Dealing by Ones', 'CGOB', 'IDP', 'UCR']).
list_available_strategies(fraction, ['PFS', 'FCS']).

%!      strategy_appropriate_for(+Op, +Problem, -Strategy) is semidet.
%
%       Select the lowest-cost strategy for a given operation and problem size.
%       Problem is A+B where A and B are integers. Falls back to first
%       available strategy if cost estimation fails.
%
strategy_appropriate_for(Op, A+B, Strategy) :-
    list_available_strategies(Op, Strategies),
    findall(Cost-S, (
        member(S, Strategies),
        estimate_strategy_cost(Op, S, A, B, Cost)
    ), CostPairs),
    CostPairs \= [],
    sort(CostPairs, [_BestCost-Strategy|_]).

strategy_appropriate_for(Op, _Problem, Strategy) :-
    list_available_strategies(Op, [Strategy|_]).

%!      estimate_strategy_cost(+Op, +Strategy, +A, +B, -Cost) is det.
%
%       Estimate the cognitive cost of applying a strategy to operands A and B.
%       Lower cost = better fit for these operand sizes.
%
%       Cost profiles:
%       - Counting On: linear in min(A,B) — cheap for small problems
%       - RMB: depends on distance to base 10 — cheap when close to 10
%       - COBO: depends on decomposition into bases and ones — scales with B
%       - Chunking: depends on number of decade chunks — moderate for multi-digit
%       - Rounding: constant cost — always moderate
%
estimate_strategy_cost(add, 'Counting On', A, B, Cost) :-
    Cost is min(A, B) + 2.
estimate_strategy_cost(add, 'RMB', A, B, Cost) :-
    distance_to_next_base(A, DistA),
    distance_to_next_base(B, DistB),
    % Rearranging covers the gap to the base; the rest of the donor operand
    % still has to be added on afterward, and that residue scales with its
    % bases. Without the residue term RMB costs the same for 8+5 and 38+55,
    % which erases size-sensitive selection.
    (   DistA =< DistB
    ->  Gap = DistA, Donor = B
    ;   Gap = DistB, Donor = A
    ),
    Residue is max(0, Donor - Gap),
    Cost is Gap + Residue // 10 + 3.
estimate_strategy_cost(add, 'COBO', _A, B, Cost) :-
    Bases is B // 10,
    Ones is B mod 10,
    Cost is Bases + Ones + 4.
estimate_strategy_cost(add, 'Chunking', _A, B, Cost) :-
    Bases is B // 10,
    (   Bases =:= 0
    ->  Cost is 12
    ;   Cost is Bases + 3
    ).
estimate_strategy_cost(add, 'Rounding', _A, _B, Cost) :-
    Cost is 5.
estimate_strategy_cost(divide, 'Dealing by Ones', A, _B, Cost) :-
    Cost is A + 3.
estimate_strategy_cost(divide, 'CGOB', A, _B, Cost) :-
    Bases is A // 10,
    Cost is Bases + 8.
estimate_strategy_cost(divide, 'IDP', _A, _B, Cost) :-
    % IDP is cheap only after multiplication facts have been learned. The
    % Teacher facade does not assume that developmental prerequisite, so the
    % default chooser leaves IDP behind CGOB unless explicitly requested.
    Cost is 30.
estimate_strategy_cost(divide, 'UCR', _A, B, Cost) :-
    Cost is B + 12.
estimate_strategy_cost(_, _, _, _, 50).  % Unknown: high cost fallback.

distance_to_next_base(N, Distance) :-
    R is N mod 10,
    (   R =:= 0
    ->  Distance = 0
    ;   Distance is 10 - R
    ).

% ═══════════════════════════════════════════════════════════════════════
% ORACLE INTERFACE BOUNDARY
% ═══════════════════════════════════════════════════════════════════════
%
% Everything below this line is INTERNAL to the oracle and must not be
% directly accessible to the primordial machine.
%
% The oracle's internal workings (FSM structures, state transitions,
% computational traces) are hidden behind the query_oracle/4 interface.
%
% This architectural separation forces the primordial machine to engage
% in genuine synthesis through recognition, not template matching through
% introspection.
%
% ═══════════════════════════════════════════════════════════════════════
