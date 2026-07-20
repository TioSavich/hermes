/** <module> FSM Synthesis Engine — Utility Shim
 *
 * The synthesis engine was archived in Phase 1 (2026-04-14 modularization).
 * See archive/fsm_synthesis_engine.pl for the original.
 *
 * This shim preserves the module interface so existing imports don't break.
 * Only peano_to_int/2 and int_to_peano/2 are live. The synthesis predicates
 * are stubs that log and fail — they were never called in practice (the
 * 5-argument path wrapped oracle calls rather than synthesizing from
 * primitives; see archive/SYNTHESIS_HONESTY.md).
 */
:- module(fsm_synthesis_engine,
          [ synthesize_strategy_from_oracle/4,
            synthesize_strategy_from_oracle/5,
            peano_to_int/2,
            int_to_peano/2
          ]).

:- reexport(peano_utils, [peano_to_int/2, int_to_peano/2]).

% ===================================================================
% Stubs: synthesis predicates (archived, not live)
% ===================================================================

synthesize_strategy_from_oracle(_Goal, _FailedTrace, _TargetResult, _TargetInterpretation) :-
    writeln('[FSM Synthesis] Archived. See archive/fsm_synthesis_engine.pl'),
    fail.

synthesize_strategy_from_oracle(_Goal, _FailedTrace, _TargetResult, _TargetInterpretation, _StrategyName) :-
    writeln('[FSM Synthesis] Archived. See archive/fsm_synthesis_engine.pl'),
    fail.
