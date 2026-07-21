/** <module> Misconception scorekeeping wire
 *
 * Connects generative_misconceptions.pl to formal/learner/deontic_scorekeeper.pl.
 * When an agent enacts a generated misconception, the wire:
 *
 *   1. records the misconception term as a commitment of the agent;
 *   2. does NOT grant entitlement to it;
 *   3. registers the misconception's term-shape as one that
 *      requires entitlement, so the scorekeeper's
 *      `commitment_without_entitlement` clause fires.
 *
 * The misconception is then visible to the engine as a deontically
 * incoherent commitment, without the system asserting the misconception
 * as true. That is the reachability story: misconceptions reach the
 * scorekeeper as commitments without entitlement.
 *
 * Why "enact" and not "assert". A misconception is a move an agent
 * makes, not a fact the system holds. The scorekeeper records the
 * move and the incoherence; downstream interpretation (teacher
 * response, crisis processor, dialogue) decides what to do about it.
 */
:- module(misconception_scorekeeping,
          [ enact_misconception/2,
            overgeneralization/3
          ]).

:- use_module(misconceptions(generative_misconceptions),
              [ misconception/1,
                overgeneralization/3
              ]).
:- use_module(learner(deontic_scorekeeper),
              [ undertake_commitment/2
              ]).


%% Extend the scorekeeper's requires_entitlement_fact/1 with the
%% misconception term-shapes. Any deformed_action or overgeneralization
%% commitment will require entitlement and, since enactment never
%% grants entitlement, will register as commitment_without_entitlement.
:- multifile deontic_scorekeeper:requires_entitlement_fact/1.

deontic_scorekeeper:requires_entitlement_fact(deformed_action(_, _, _)).
deontic_scorekeeper:requires_entitlement_fact(overgeneralization(_, _, _)).


%!  enact_misconception(+Agent, +Misconception) is semidet.
%
%   Records that Agent is enacting Misconception. The Misconception
%   term must be one the generator recognizes (verified via
%   misconception/1). The term is undertaken as a commitment of the
%   agent; entitlement is deliberately not granted.
%
%   Fails (with no scorekeeper change) if Misconception is not a
%   generator-recognized misconception term. This is the guard against
%   undertaking arbitrary terms as misconceptions.
enact_misconception(Agent, Misconception) :-
    misconception(Misconception),
    undertake_commitment(Agent, Misconception).
