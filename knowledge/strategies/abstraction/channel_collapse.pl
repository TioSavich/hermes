:- encoding(utf8).
/** <module> Channel collapse — the third reading, for errors with no antecedent
 *
 * The license/mutation account (kernel_gate_pilot.pl,
 * refusal_genesis_sketch.pl) reads every deformation as a licensed
 * move applied outside its license. The owner's counterexample: a
 * child whose articulation made thirteen and fourteen the same spoken
 * word. Her arithmetic could be entirely right and her answers wrong
 * at the interface, because two task-level tokens were one token in
 * her channel. "Drops a count" has an antecedent; the collapse of
 * thirteen and fourteen into one sound does not reach formal
 * description — physiology is not a move in a practice.
 *
 * So the recognizer needs a third reading beside productive and
 * deformed: PRODUCTIVE MODULO CHANNEL. And the diagnostic discipline
 * needs an ordering: TEST THE CHANNEL HYPOTHESIS BEFORE CHARGING A
 * LICENSE. Charging a misconception for an articulation collapse is
 * the dogma the license account would otherwise fall into — a formal
 * story forced onto a material fact.
 *
 * What is checkable and what is not. The channel map itself is NOT
 * derived here and never could be: its rows carry
 * observed(clinical), not authored(interpretation), and
 * check_no_antecedent/0 checks the actual authored license and
 * antecedent rows and requires that none names the channel. What IS
 * checkable is the discrimination's form. Channel collapse and license
 * transfer predict different error PATTERNS. A channel error tracks token collision
 * and nothing else — it appears wherever the colliding tokens appear,
 * across structurally unrelated tasks, and vanishes wherever they do
 * not. A license error tracks structure — it appears wherever the
 * structural precondition holds (a refusal to evade, a part to drop),
 * whatever the tokens. The evidence sets are authored from those
 * predictor patterns. check_discrimination/0 demonstrates the form:
 * each family scores its own pattern and not the other's. It is not an
 * empirical discrimination test.
 *
 * The formal mark for the unformalizable follows the repo's own
 * device: formal/sequent/automata.pl carries the vanishing-point mark,
 * "the track left in a proof where reference fails." A channel row is
 * that kind of object — the formal track of something the formalism
 * does not capture, kept so the system can point at its own limit
 * instead of papering over it.
 *
 * LIMITS. The lexicon is a toy (a dozen number words); the channel
 * model is a token merge, which covers articulation and hearing but
 * not, e.g., attention or affect; the discriminator is coverage
 * counting, not inference to the best explanation — it orders
 * hypotheses, it does not close the case. A real case stays open to
 * clinical evidence the way this file stays open to a veto.
 */

:- module(channel_collapse,
          [ channel_row/4,
            express/3,
            hypothesis_predicts/3,
            score_hypothesis/4,
            best_hypothesis/3,
            read_response/4,
            outside_formal_description/1,
            check_channel_collapse/0
          ]).

:- use_module(refusal_genesis_sketch, [license/2, antecedent/3]).

% ==========================================================================
% 1. TOKENS AND CHANNELS
% ==========================================================================

number_word(2, two).      number_word(3, three).
number_word(5, five).     number_word(8, eight).
number_word(12, twelve).  number_word(13, thirteen).
number_word(14, fourteen). number_word(15, fifteen).
number_word(16, sixteen). number_word(19, nineteen).
number_word(20, twenty).

% channel_row(Channel, TaskToken, ChannelToken, Provenance).
% The provenance is the point: observed, never authored, never derived.
channel_row(eliza_articulation, thirteen, furteen, observed(clinical)).
channel_row(eliza_articulation, fourteen, furteen, observed(clinical)).

% express(+Channel, +Word, -Heard): the channel quotient. Identity off
% the merged tokens.
% One clause, deterministic: the identity channel (none) falls out of
% channel_row/4 having no rows for it.
express(Channel, Word, Heard) :-
    ( channel_row(Channel, Word, Heard0, _) -> Heard = Heard0 ; Heard = Word ).

% ==========================================================================
% 2. TASKS, TRUTH, HYPOTHESES
%
% Evidence is obs(Task, said(SurfaceToken)). Truth is computed by plain
% arithmetic. Each hypothesis predicts a surface token for a task;
% explanation is exact match of the prediction.
% ==========================================================================

task_truth(asked(sum(A, B)), T) :- T is A + B.
task_truth(asked(difference(M, S)), T) :- T is M - S.

% hypothesis_predicts(+Hypothesis, +Task, -SurfaceToken)
hypothesis_predicts(competent(Channel), Task, Heard) :-
    task_truth(Task, T),
    number_word(T, W),
    express(Channel, W, Heard).
hypothesis_predicts(mutation(evade_refusal(swap_operands)), Task, Heard) :-
    (   Task = asked(difference(M, S)), M < S
    ->  V is S - M                       % the swap fires only at the refusal
    ;   task_truth(Task, V)
    ),
    V >= 0, number_word(V, W),
    express(none, W, Heard).
hypothesis_predicts(mutation(off_by_one), Task, Heard) :-
    task_truth(Task, T), V is T + 1,
    number_word(V, W),
    express(none, W, Heard).

score_hypothesis(H, Evidence, Explained, Total) :-
    length(Evidence, Total),
    aggregate_all(count,
                  ( member(obs(Task, said(Tok)), Evidence),
                    once(hypothesis_predicts(H, Task, Tok)) ),
                  Explained).

hypothesis_space([ competent(eliza_articulation),
                   competent(none),
                   mutation(evade_refusal(swap_operands)),
                   mutation(off_by_one)
                 ]).

best_hypothesis(Evidence, Best, Explained-Total) :-
    hypothesis_space(Hs),
    findall(E-H, ( member(H, Hs), score_hypothesis(H, Evidence, E, _) ), Scored),
    msort(Scored, Sorted), reverse(Sorted, [Explained-Best|_]),
    length(Evidence, Total).

% ==========================================================================
% 3. THE THIRD READING
%
% read_response(+ChannelHypothesis, +Task, +said(Tok), -Reading).
% With no channel on the table a colliding answer reads unvindicated;
% with the channel hypothesis it reads productive_modulo_channel, and
% the collapsed pair is named so a teacher knows what to check by ear,
% not by worksheet.
% ==========================================================================

read_response(Channel, Task, said(Tok), Reading) :-
    task_truth(Task, T),
    number_word(T, TrueWord),
    express(Channel, TrueWord, PredictedHeard),
    (   Tok == TrueWord
    ->  Reading = productive
    ;   Tok == PredictedHeard,
        Channel \== none,
        findall(W, channel_row(Channel, W, Tok, _), Ws), Ws = [_, _|_]
    ->  Reading = productive_modulo_channel(collapsed(Ws))
    ;   Reading = unvindicated
    ).

% The channel is outside the license space: no antecedent row exists
% for it and none may be manufactured. This predicate is the formal
% mark of that limit — the vanishing-point discipline applied here.
outside_formal_description(channel(C)) :-
    channel_row(C, _, _, observed(clinical)),
    \+ formal_license_row_mentions(C).

% Range over the actual authored license space. A channel is outside
% that space only while neither a license nor an antecedent row names it.
formal_license_row_mentions(C) :-
    license(Gate, Rule),
    sub_term(C, license(Gate, Rule)).
formal_license_row_mentions(C) :-
    antecedent(Mutation, HomeLicense, TransferLoss),
    sub_term(C, antecedent(Mutation, HomeLicense, TransferLoss)).

% ==========================================================================
% 4. EVIDENCE SETS AND CHECKS
% ==========================================================================

% Eliza-style: two collisions, two clean answers on the same task type.
% The arithmetic is right throughout; only the colliding tokens err.
eliza_evidence([ obs(asked(sum(5, 8)), said(furteen)),     % 13 -> furteen
                 obs(asked(sum(2, 12)), said(furteen)),    % 14 -> furteen
                 obs(asked(sum(3, 12)), said(fifteen)),    % clean
                 obs(asked(difference(15, 3)), said(twelve))  % clean
               ]).

% Swap-style: the error tracks structure (fires exactly where the
% whole-number gate refuses), not tokens.
swap_evidence([ obs(asked(difference(3, 5)), said(two)),
                obs(asked(difference(2, 15)), said(thirteen)),
                obs(asked(difference(8, 3)), said(five))     % no refusal: correct
              ]).

% These authored evidence rows mirror the predictors' patterns. The check
% demonstrates discrimination form, not empirical discrimination.
check_discrimination :-
    eliza_evidence(E1),
    best_hypothesis(E1, competent(eliza_articulation), 4-4),
    score_hypothesis(mutation(evade_refusal(swap_operands)), E1, SE1, _), SE1 < 4,
    score_hypothesis(mutation(off_by_one), E1, SO1, _), SO1 < 4,
    score_hypothesis(competent(none), E1, SN1, _), SN1 < 4,
    swap_evidence(E2),
    best_hypothesis(E2, mutation(evade_refusal(swap_operands)), 3-3),
    score_hypothesis(competent(eliza_articulation), E2, SC2, _), SC2 < 3.

% The reading changes with the hypothesis, and the change is explicit:
% the same response reads unvindicated blind and
% productive_modulo_channel with the channel on the table.
check_third_reading :-
    read_response(none, asked(sum(2, 12)), said(furteen), unvindicated),
    read_response(eliza_articulation, asked(sum(2, 12)), said(furteen),
                  productive_modulo_channel(collapsed([thirteen, fourteen]))),
    read_response(eliza_articulation, asked(sum(3, 12)), said(fifteen), productive).

% No license is ever charged for a channel: the row is clinically
% observed, outside the license space, and the mark says so.
check_no_antecedent :-
    forall(channel_row(C, _, _, observed(clinical)),
           outside_formal_description(channel(C))),
    \+ ( channel_row(C, _, _, P), P \= observed(clinical), C == eliza_articulation ).

check_channel_collapse :-
    check_discrimination,
    format('discrimination form: each hypothesis scores its authored pattern and not the other ... ok~n'),
    check_third_reading,
    format('third reading: same answer, unvindicated blind, productive_modulo_channel with the channel named ... ok~n'),
    check_no_antecedent,
    format('no antecedent: channel rows are observed(clinical), outside the license space, marked as such ... ok~n').
