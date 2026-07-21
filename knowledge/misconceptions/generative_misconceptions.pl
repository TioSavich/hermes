/** <module> Generative misconceptions
 *
 * Two mechanisms produce misconceptions from data already in the codebase:
 *
 *   1. deformed_action/3: every productive/deformation pair registered
 *      by an action_pairs module yields a misconception. The deformation
 *      is the misconception; the family names the pattern.
 *
 *   2. overgeneralization/3: every metaphor_breaks_at/3 fact yields a
 *      misconception candidate. Extending the metaphor past the
 *      break-point is the move; the break-reason names where the
 *      reason-giving runs out.
 *
 * Both feed misconception/1, a uniform entry point that wraps either
 * mechanism's output as a misconception term.
 *
 * What this is NOT
 *   - Not a generator that produces NEW deformations from scratch
 *     (that would be FSM synthesis, which is archived).
 *   - Not a validator: it makes no claim that every overgeneralization
 *     is empirically attested. Validation against the research_corpus
 *     error_instances table is a separate step.
 *   - Not a Brandomian incompatibility module: incompatibility between
 *     misconception and commitment is detected downstream by
 *     misconception_scorekeeping.pl through the deontic_scorekeeper.
 */
:- module(generative_misconceptions,
          [ deformed_action/3,
            overgeneralization/3,
            misconception/1
          ]).

:- use_module(formalization(grounding_metaphors),
              [ metaphor_breaks_at/3
              ]).

:- use_module(math(action_automata_registry), [action_automaton_pair/4]).


%!  deformed_action(?Productive, ?Deformation, ?Family) is nondet.
%
%   True when (Productive, Deformation, Family) is a registered
%   productive/deformation action pair from one of the action_pairs
%   modules. The Deformation is the misconception; the Family names
%   the pattern of substitution.
deformed_action(Productive, Deformation, Family) :-
    action_automaton_pair(_Operation, Productive, Deformation, Family).


%!  overgeneralization(?MetaphorId, ?AttemptedInference, ?Reason) is nondet.
%
%   True when MetaphorId is a grounding metaphor that breaks at
%   AttemptedInference for Reason. Extending the metaphor past this
%   break-point is an overgeneralization misconception. A repair
%   metaphor may or may not exist; even when one exists, the
%   un-repaired extension is the misconception.
overgeneralization(MetaphorId, AttemptedInference, Reason) :-
    metaphor_breaks_at(MetaphorId, AttemptedInference, Reason).


%!  misconception(?Misconception) is nondet.
%
%   Uniform entry point. A misconception is either a deformed_action
%   triple or an overgeneralization triple, wrapped as a term.
misconception(deformed_action(Productive, Deformation, Family)) :-
    deformed_action(Productive, Deformation, Family).
misconception(overgeneralization(MetaphorId, AttemptedInference, Reason)) :-
    overgeneralization(MetaphorId, AttemptedInference, Reason).
