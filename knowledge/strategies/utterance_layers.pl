/** <module> utterance_layers -- what an utterance carries besides its mathematics
 *
 * THE DEFECT THIS ANSWERS. hermes/strategy_recognizer.pl matches token spans
 * against action surfaces and walks the matched actions through an automaton.
 * Probed live through the MCP server on 2026-07-25, these five all returned
 * addition/make_ten_split_leftover or its deformation partner at comparable
 * confidence:
 *
 *     i split the other number and made ten ...
 *     you split the other number and made ten ...
 *     she split the other number and made ten ...
 *     did you split the other number and make ten ...
 *     i did not make ten i just counted them all
 *
 * The first three differ in who is put in the commitment's place. The fourth is
 * a question rather than a claim. The fifth is a DENIAL, and it scored 0.2 in
 * favour of the strategy it denies: the recognizer matched "made ten" inside
 * "did not make ten" and counted it as evidence. Information that should have
 * removed a possibility added one.
 *
 * WHY LAYERS. A flat phrase bakes the person into the surface -- the phrases in
 * canonical_phrases.pl all begin "i" -- so the only way to cover second person,
 * questions, and denials is to write every combination out. Person by force by
 * polarity by predicate is a product, and writing a product out by hand is the
 * same mistake as writing one phrase per local action label. So the layers are
 * kept apart and the surface is their composition:
 *
 *     person      who the utterance puts in the commitment's place
 *     force       what the utterance does: claims, asks, reports
 *     polarity    whether the predicate is affirmed or denied
 *     action      the mathematical doing, a canonical action
 *
 * A parse reads each layer separately. The mathematical layer is invariant under
 * a change of person, which is the point: "I made a ten" and "you made a ten"
 * are the same arithmetic under two different deontic uptakes.
 *
 * SUBSTITUTION. layer_substitution/5 records that swapping a value in one layer
 * induces a swap in what the utterance does. First person to second person is
 * acknowledging to attributing -- the two sides of a Brandomian scorecard, and
 * the pair knowledge/discourse/commitment_automata.pl already runs as
 * acknowledge_commitment and attribute_commitment. The mathematics does not move.
 * That is what makes it a substitution rather than a different utterance.
 *
 * INFORMATION AS NEGATION. Each layer read narrows what the utterance can be
 * doing, and the narrowing is the information. layer_uptake/3 says which
 * discursive action a layer value commits the speaker to, so a parse of the
 * layers is a parse into the discursive genre rather than a set of tags. The
 * polarity layer is the one that negates outright: a denied predicate is
 * evidence against the strategy whose predicate it is, and
 * hermes/strategy_recognizer.pl consults denied_span/3 to drop those spans
 * instead of counting them.
 *
 * WHAT THIS IS NOT. Not a grammar of English. The forms below are the small
 * closed sets these three layers need to tell the cases above apart, and
 * anything outside them leaves its layer unread rather than guessed. An unread
 * layer is reported as unread; that is the honest form of not knowing, and it is
 * why every layer has an unmarked value.
 */
:- module(utterance_layers,
          [ utterance_layer/3,
            layer_form/3,
            layer_uptake/3,
            layer_substitution/5,
            canonical_predicate/2,
            read_layer/3,
            denied_span/3
          ]).

:- use_module(library(lists), [append/3, member/2, nth0/3]).

% utterance_layer(Layer, order(N), gloss(Text)) -- N is the order a parse peels
% them, outermost first. The action layer is last because the layers above it
% decide what to do with the action once it is found.
utterance_layer(person, order(1),
                gloss("Who the utterance puts in the commitment's place.")).
utterance_layer(force, order(2),
                gloss("What the utterance does with the predicate: claims it, asks after it, reports it as another's.")).
utterance_layer(polarity, order(3),
                gloss("Whether the predicate is affirmed or denied.")).
utterance_layer(action, order(4),
                gloss("The mathematical doing: a canonical action from knowledge/strategies/action_vocabulary_map.pl.")).

% layer_form(Layer, Value, Words) -- the closed set of forms each layer reads.
% The unmarked value has an empty form and matches by default, so a layer that
% is not written in the utterance is read as unmarked rather than guessed.
layer_form(person, unmarked, []).
layer_form(person, first_singular, [i]).
layer_form(person, first_plural, [we]).
layer_form(person, second, [you]).
layer_form(person, third_singular, [she]).
layer_form(person, third_singular, [he]).
layer_form(person, third_singular, [they]).
layer_form(person, third_named, [the, student]).

layer_form(force, unmarked, []).
layer_form(force, assertion, [so]).
layer_form(force, question, [did]).
layer_form(force, question, [do]).
layer_form(force, question, [how]).
layer_form(force, question, [why]).
layer_form(force, question, [what]).
layer_form(force, report, [said]).
layer_form(force, report, [told, me]).

layer_form(polarity, affirmed, []).
% Clause-level denials only. A bare "not" is too weak a form to read polarity
% from, because the action labels themselves carry negation words: the
% identifier-derived surface for decimal/decimal_scale_loss_comparison is
% "scales seen but not coordinated", and a bare-not form vetoed the span for the
% step that utterance was reporting. That collision is the entanglement this
% module exists to separate, seen from the other side -- polarity cannot be read
% off the same tokens as the action while the action's own surface is its
% identifier. Until the predicates displace the identifiers entirely, the
% conservative forms are the honest ones.
layer_form(polarity, denied, [did, not]).
layer_form(polarity, denied, [does, not]).
layer_form(polarity, denied, [didnt]).
layer_form(polarity, denied, [dont]).
layer_form(polarity, denied, [never]).
% [instead, of] is deliberately NOT a denial form. It marks a substitution --
% one thing done in place of another -- and the alphabet already carries that as
% the substitute_* family. Reading it as polarity denied it its own layer and
% broke decimal/decimal_point_rule_misapplication, whose own label is
% take_max_of_place_counts_instead_of_summing: the veto dropped the span for the
% step the utterance was reporting. The check
% scripts/checks/strategy_recognizer.pl caught that, which is the first thing it
% has caught since it started running on 2026-07-25.

% layer_uptake(Layer, Value, DiscursiveAction) -- what a layer value commits the
% speaker to, named in the discursive genre's own vocabulary so that a layer
% parse lands in knowledge/discourse/commitment_automata.pl rather than in a set
% of tags. Values with no uptake are absent rather than mapped to a default.
layer_uptake(person, first_singular, acknowledge_commitment).
layer_uptake(person, first_plural, acknowledge_commitment).
layer_uptake(person, second, attribute_commitment).
layer_uptake(person, third_singular, attribute_commitment).
layer_uptake(person, third_named, attribute_commitment).
layer_uptake(force, assertion, undertake_commitment).
layer_uptake(force, question, challenge_entitlement).
layer_uptake(force, report, attribute_commitment).
layer_uptake(polarity, denied, withdraw_commitment).

% layer_substitution(Layer, From, To, induces(Layer2, From2, To2), basis(Text)).
%
% A substitution licensed in one layer and what it does to another. The
% mathematical layer is invariant under all of them, which is what makes them
% substitutions in one utterance rather than two different utterances.
layer_substitution(person, first_singular, second,
                   induces(uptake, acknowledge_commitment, attribute_commitment),
                   basis("The arithmetic does not move; what moves is which side of the score the commitment sits on. Saying it is acknowledging it as one's own and hearing it said is attributing it to another, and the two are not interchangeable -- knowledge/discourse/commitment_automata.pl runs attribution_taken_as_acknowledgement as a deformation for exactly that reason.")).
layer_substitution(person, second, third_singular,
                   induces(uptake, attribute_commitment, attribute_commitment),
                   basis("Both attribute, so the uptake is unchanged. What changes is whether the person attributed to is present to answer for it, which the deontic score does not record and a teacher reporting to a class does.")).
layer_substitution(force, assertion, question,
                   induces(uptake, undertake_commitment, challenge_entitlement),
                   basis("The same predicate, undertaken in one case and asked after in the other. Asking does not put the commitment on the asker's score; it asks whether the other can vindicate it.")).
layer_substitution(polarity, affirmed, denied,
                   induces(uptake, undertake_commitment, withdraw_commitment),
                   basis("The predicate is the same and the commitment is refused. This is the substitution the recognizer was blind to: it matched the affirmed predicate inside the denial and counted it as evidence for what the utterance denies.")).

% canonical_predicate(CanonicalAction, Words) -- the mathematical predicate
% alone, with no person and no auxiliary. These are what the action layer reads,
% and they are person-free on purpose: the person layer reads the person.
canonical_predicate(regroup_to_base, [made, ten]).
canonical_predicate(regroup_to_base, [make, ten]).
canonical_predicate(regroup_to_base, [got, to, ten]).
canonical_predicate(regroup_to_base, [traded, ten, ones, for, a, ten]).
canonical_predicate(decompose_operand, [split, the, other, number]).
canonical_predicate(decompose_operand, [broke, the, other, number, up]).
canonical_predicate(decompose_operand, [split, one, of, them, apart]).
canonical_predicate(combine_quantities, [added, them]).
canonical_predicate(combine_quantities, [add, them]).
canonical_predicate(combine_quantities, [put, them, together]).
canonical_predicate(count_units, [counted, them]).
canonical_predicate(count_units, [count, them]).
canonical_predicate(count_units, [counted, them, all]).
canonical_predicate(count_on_from, [counted, on, from, there]).
canonical_predicate(count_on_from, [count, on, from, there]).
canonical_predicate(count_on_from, [started, from, the, bigger, number]).
canonical_predicate(align_to_common_unit, [gave, them, the, same, denominator]).
canonical_predicate(align_to_common_unit, [made, the, bottoms, match]).
canonical_predicate(align_to_common_unit, [put, them, in, the, same, units]).
canonical_predicate(partition_into_equal_parts, [cut, it, into, equal, parts]).
canonical_predicate(partition_into_equal_parts, [split, it, evenly]).
canonical_predicate(disembed_part, [pulled, out, one, part]).
canonical_predicate(disembed_part, [took, one, piece, out]).
canonical_predicate(iterate_unit, [kept, copying, the, piece]).
canonical_predicate(iterate_unit, [repeated, it, over, and, over]).
canonical_predicate(compare_magnitudes, [compared, them]).
canonical_predicate(compare_magnitudes, [worked, out, which, was, bigger]).
canonical_predicate(remove_quantity, [took, it, away]).
canonical_predicate(remove_quantity, [subtracted, it]).
canonical_predicate(retrieve_known_fact, [just, knew, it]).
canonical_predicate(retrieve_known_fact, [remembered, that, one]).
canonical_predicate(substitute_count_for_measure, [counted, the, marks]).
canonical_predicate(substitute_count_for_measure, [counted, the, pieces]).
canonical_predicate(record_conservation, [it, is, still, the, same, amount]).
canonical_predicate(record_loss, [lost, track, of, something]).

%!  read_layer(+Layer, +Tokens, -Value) is nondet.
%
%   Read one layer off a token list. A layer whose forms are all absent yields
%   its unmarked value, so an unread layer is reported as unread. Layers are
%   read independently: reading the person does not consume tokens the action
%   layer needs, because the two are different words in the same utterance.
read_layer(Layer, Tokens, Value) :-
    setof(Found, layer_form_present(Layer, Tokens, Found), Values),
    member(Value, Values).
read_layer(Layer, Tokens, Unmarked) :-
    layer_form(Layer, Unmarked, []),
    \+ layer_form_present(Layer, Tokens, _).

%!  layer_form_present(+Layer, +Tokens, -Value) is nondet.
%
%   One marked form of Layer occurs in Tokens. The auxiliary guard is the reason
%   this is not a bare append: "did" opens a question in "did you make ten" and
%   opens a denial in "did not make ten", and reading the second as a question
%   put a question uptake on an utterance that denies.
layer_form_present(Layer, Tokens, Value) :-
    layer_form(Layer, Value, Words),
    Words \== [],
    append(Prefix, Rest, Tokens),
    append(Words, After, Rest),
    \+ auxiliary_carried_by_denial(Layer, Words, After),
    Prefix = Prefix.

auxiliary_carried_by_denial(force, [Auxiliary], [not|_]) :-
    memberchk(Auxiliary, [did, do, does]).
auxiliary_carried_by_denial(force, [Auxiliary], [Negated|_]) :-
    memberchk(Auxiliary, [did, do, does]),
    memberchk(Negated, [didnt, dont]).

%!  denied_span(+Tokens, +Start, +End) is semidet.
%
%   True when the span from Start to End sits inside the scope of a denial. The
%   scope is deliberately crude: a denial token before the span, with no
%   sentence-ending token between them. Crude and stated is better here than
%   subtle and unstated, because the alternative in force is no scope at all --
%   the recognizer counted "made ten" inside "did not make ten" as evidence for
%   making ten.
denied_span(Tokens, Start, _End) :-
    append(Prefix, Rest, Tokens),
    append(DenialWords, _, Rest),
    layer_form(polarity, denied, DenialWords),
    DenialWords \== [],
    length(Prefix, Index),
    length(DenialWords, Length),
    DenialEnd is Index + Length,
    Start >= DenialEnd,
    denial_reach(Reach),
    Start - DenialEnd =< Reach,
    !.

%!  denial_reach(-Tokens) is det.
%
%   How far after a denial word a span is still taken to be denied. Three tokens,
%   chosen so that "did not make ten" denies "make ten" and "i did not make ten
%   i just counted them all" does not deny "counted them all". A clause parser
%   would do this properly; a stated window is what is here, and the alternative
%   in force before it was no scope at all.
denial_reach(3).
