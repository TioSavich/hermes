/** <module> Hermeneutic Calculator - Strategy Dispatcher
 *
 * This module acts as a high-level dispatcher for the various cognitive
 * strategy models implemented in the `sar_*` and `smr_*` modules. It provides
 * a unified interface to execute a calculation using a specific, named
 * strategy and to list the available strategies for each arithmetic operation.
 *
 * This allows the user interface or other components to abstract away the
 * details of individual strategy modules.
 *
 * SURFACE REGISTER — DEMONSTRATION, NOT CRISIS:
 * This dispatcher is the strategy-explorer surface (the /api/strategy/run
 * route and the more-zeeman strategy pages). It differs on purpose from the
 * crisis surface in `formal/learner/oracle_server.pl` for exactly one strategy:
 * IDP division. IDP works by recalling multiplication facts. Here, the
 * demonstration supplies a labeled demo times table for the actual divisor
 * (`demo_multiplication_facts/2`), so a visitor can watch the strategy run.
 * In the crisis pipeline the knowledge base stays empty: the learner must
 * have earned multiplication facts through the ORR cycle first, and until
 * then IDP honestly refuses (see oracle_server.pl and
 * strategies/FRACTION_CRISIS_ASSESSMENT.md, gap 1). Callers that report a
 * demo-backed IDP result should mark its provenance; `demo_kb_strategy/2`
 * says which dispatches use the demo table.
 */
:- module(hermeneutic_calculator,
          [ calculate/6
          , list_strategies/2
          , demo_multiplication_facts/2
          , demo_kb_strategy/2
          ]).

% Addition Strategies
:- use_module(math(sar_add_cobo), [run_cobo/4]).
:- use_module(math(sar_add_chunking), [run_chunking/4]).
:- use_module(math(sar_add_rmb), [run_rmb/4]).
:- use_module(math(sar_add_rounding), [run_rounding/4]).

% Subtraction Strategies  
:- use_module(math(sar_sub_cobo_missing_addend), [run_cobo_ma/4]).
:- use_module(math(sar_sub_cbbo_take_away), [run_cbbo_ta/4]).
:- use_module(math(sar_sub_decomposition), [run_decomposition/4]).
:- use_module(math(sar_sub_rounding), [run_sub_rounding/4]).
:- use_module(math(sar_sub_sliding), [run_sliding/4]).
:- use_module(math(sar_sub_chunking_a), [run_chunking_a/4]).
:- use_module(math(sar_sub_chunking_b), [run_chunking_b/4]).
:- use_module(math(sar_sub_chunking_c), [run_chunking_c/4]).

% Multiplication Strategies
:- use_module(math(smr_mult_c2c), [run_c2c/4]).
:- use_module(math(smr_mult_cbo), [run_cbo_mult/5]).
:- use_module(math(smr_mult_commutative_reasoning), [run_commutative_mult/4]).
:- use_module(math(smr_mult_dr), [run_dr/4]).

% Division Strategies
:- use_module(math(smr_div_cbo), [run_cbo_div/6]).
:- use_module(math(smr_div_dealing_by_ones), [run_dealing_by_ones/4]).
:- use_module(math(smr_div_idp), [run_idp/6]).
:- use_module(math(smr_div_ucr), [run_ucr/4]).

% --- Strategy Lists ---

%!      list_strategies(+Op:atom, -Strategies:list) is nondet.
%
%       Provides a list of available strategy names for a given arithmetic
%       operator.
%
%       @param Op The operator (`+`, `-`, `*`, `/`).
%       @param Strategies A list of atoms representing the names of the
%       strategies available for that operator.
list_strategies(+, [
    'COBO',
    'Chunking',
    'RMB',
    'Rounding'
]).
list_strategies(-, [
    'COBO (Missing Addend)',
    'CBBO (Take Away)',
    'Decomposition',
    'Rounding',
    'Sliding',
    'Chunking A',
    'Chunking B',
    'Chunking C'
]).
list_strategies(*, [
    'C2C',
    'CBO',
    'Commutative Reasoning',
    'DR'
]).
list_strategies(/, [
    'CGOB',
    'Dealing by Ones',
    'IDP',
    'UCR'
]).

% --- Calculator Dispatch ---

%!      calculate(+Num1:integer, +Op:atom, +Num2:integer, +Strategy:atom, -Result:integer, -History:list) is semidet.
%
%       Executes a calculation using a specified cognitive strategy.
%       This predicate acts as a dispatcher, calling the appropriate
%       `run_*` predicate from the various strategy modules based on the
%       `Strategy` name. It now captures and returns the execution trace.
%
%       @param Num1 The first operand.
%       @param Op The arithmetic operator (`+`, `-`, `*`, `/`).
%       @param Num2 The second operand.
%       @param Strategy The name of the strategy to use (must match one from
%       `list_strategies/2`).
%       @param Result The numerical result of the calculation. Fails if the
%       strategy does not complete successfully.
%       @param History A list of terms representing the execution trace of
%       the chosen strategy.
calculate(N1, +, N2, 'COBO', Result, History) :-
    run_cobo(N1, N2, Result, History).
calculate(N1, +, N2, 'Chunking', Result, History) :-
    run_chunking(N1, N2, Result, History).
calculate(N1, +, N2, 'RMB', Result, History) :-
    run_rmb(N1, N2, Result, History).
calculate(N1, +, N2, 'Rounding', Result, History) :-
    run_rounding(N1, N2, Result, History).

calculate(M, -, S, 'COBO (Missing Addend)', Result, History) :-
    run_cobo_ma(M, S, Result, History).
calculate(M, -, S, 'CBBO (Take Away)', Result, History) :-
    run_cbbo_ta(M, S, Result, History).
calculate(M, -, S, 'Decomposition', Result, History) :-
    run_decomposition(M, S, Result, History).
calculate(M, -, S, 'Rounding', Result, History) :-
    run_sub_rounding(M, S, Result, History).
calculate(M, -, S, 'Sub Rounding', Result, History) :-
    run_sub_rounding(M, S, Result, History).
calculate(M, -, S, 'Sliding', Result, History) :-
    run_sliding(M, S, Result, History).
calculate(M, -, S, 'Chunking A', Result, History) :-
    run_chunking_a(M, S, Result, History).
calculate(M, -, S, 'Chunking B', Result, History) :-
    run_chunking_b(M, S, Result, History).
calculate(M, -, S, 'Chunking C', Result, History) :-
    run_chunking_c(M, S, Result, History).

calculate(N, *, S, 'C2C', Result, History) :-
    run_c2c(N, S, Result, History).
calculate(N, *, S, 'CBO', Result, History) :-
    run_cbo_mult(N, S, 10, Result, History).
calculate(N, *, S, 'Commutative Reasoning', Result, History) :-
    run_commutative_mult(N, S, Result, History).
calculate(N, *, S, 'DR', Result, History) :-
    run_dr(N, S, Result, History).

calculate(T, /, S, 'CGOB', Result, History) :-
    % run_cbo_div/6 exposes the FSM History; the /5 form's 5th arg is the
    % remainder, so passing History there would capture the remainder, not steps.
    run_cbo_div(T, S, 10, Result, _Remainder, History).
calculate(T, /, N, 'Dealing by Ones', Result, History) :-
    run_dealing_by_ones(T, N, Result, History).
calculate(T, /, S, 'IDP', Result, History) :-
    % DEMONSTRATION path: supply a demo times table for the actual divisor.
    % The earlier hardcoded KB [40-5, 16-2, 8-1] was a divisor-8 table, so
    % any other divisor produced a wrong quotient (56/7 came back 7).
    % The crisis surface (formal/learner/oracle_server.pl) passes [] instead; see
    % the module header for why the two surfaces differ.
    demo_multiplication_facts(S, KB),
    run_idp(T, S, KB, Result, _Remainder, History).
calculate(E, /, G, 'UCR', Result, History) :-
    run_ucr(E, G, Result, History).

% --- Demonstration Knowledge Base ---

%!      demo_multiplication_facts(+Divisor:integer, -KB:list) is semidet.
%
%       The single demo-KB source for strategies that recall multiplication
%       facts (currently IDP division). Produces `Multiple-Factor` pairs for
%       factors 1..10 of the given divisor — a stand-in times table so the
%       demonstration surface can show the strategy running. These facts are
%       GIVEN, not learned: the crisis pipeline never uses this predicate,
%       because there the learner has to earn its multiplication facts
%       through the ORR cycle before IDP can recall them.
%
%       Fails (rather than guessing) for non-integer or non-positive
%       divisors; run_idp/6 handles those refusals upstream.
demo_multiplication_facts(Divisor, KB) :-
    integer(Divisor),
    Divisor >= 1,
    findall(Multiple-Factor,
            ( between(1, 10, Factor),
              Multiple is Divisor * Factor
            ),
            KB).

%!      demo_kb_strategy(?Op:atom, ?Strategy:atom) is nondet.
%
%       Which (Op, Strategy) dispatches run on the demo times table.
%       Callers reporting results for these pairs should carry the
%       provenance forward (e.g., a `kb: demo_facts` field) so a demo-backed
%       result is never mistaken for a learned one.
demo_kb_strategy(/, 'IDP').
