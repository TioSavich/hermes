:- encoding(utf8).
/** <module> Narrow K-2 word-problem reader pilot
 *
 * This quarantined DCG accepts a small sentence class and emits the five-form
 * referent schema consumed by scripts/sidekick/diagnosis_saturate.pl. Webster
 * morphology supplies noun and verb bases. The incumbent math-claim reader
 * supplies number words. Unsupported sentences fail without partial facts.
 *
 * Check from the repository root:
 * `swipl -q -l paths.pl -l knowledge/strategies/abstraction/word_problem_reader_pilot.pl -g word_problem_reader_pilot:check_word_problem_reader_pilot -t halt`
 */

:- module(word_problem_reader_pilot,
          [ word_problem_facts/2,
            word_problem_reading/3,
            word_problem_refusal/2,
            exact_value_question_program/2,
            word_problem_reader_pilot_summary/1,
            check_word_problem_reader_pilot/0
          ]).

:- use_module(library(lists), [append/2, list_to_set/2]).
:- use_module(library(porter_stem), [tokenize_atom/2]).
:- use_module('english_morphology.pl').
:- use_module('lexical_typing_store.pl', []).
:- use_module('../../../hermes/math_claim_language.pl', []).
:- ensure_loaded('../../../scripts/sidekick/diagnosis_saturate.pl').

:- discontiguous question_form_receipt/4.
:- discontiguous question_form_negative/4.
:- discontiguous class_reader_receipt/5.
:- discontiguous class_negative_receipt/5.
:- discontiguous compile_events/7.
:- discontiguous problem_event//1.

word_problem_reader_pilot_summary(
    summary(role(orphan_seam_reader),
            accepted_classes([vacuous, possession, rate, payment_exchange,
                              motion_work_interval, acquire_remove,
                              change, conversion, remaining_question,
                              equal_group_conversion, existential_quantity,
                              partitioned_same_kind, measured_dimension,
                              container_possession, computable_comparison,
                              contextual_group_total_question,
                              amount_question, exact_value_question,
                              contextual_transfer, unit_rate_question,
                              declared_comparison, multiplicative_comparison,
                              open_verb]),
            output_contract(five_form_sidekick_schema),
            % Measured 2026-08-15 across all five receipt stores: 47 class,
            % 10 reader, 14 class-negative, 33 question-form, 11
            % question-negative.
            receipt_count(115))).

%! word_problem_facts(+Text, -Facts) is semidet.
%
%  Parse the whole text. Failure of any sentence refuses the text; the caller
%  never receives facts from an accepted prefix.
word_problem_facts(Text, Facts) :-
    word_problem_reading(Text, _Class, Facts).

%! word_problem_reading(+Text, -Class, -Facts) is semidet.
%
%  Return the named admitted class as metadata beside the unchanged five-form
%  fact stream.  A vacuous sentence succeeds with no facts.
word_problem_reading(Text, exact_value_question, Facts) :-
    text_string(Text, String0),
    exact_value_question_program(String0, Facts), !.
word_problem_reading(Text, unit_rate_question, Facts) :-
    text_string(Text, String0),
    unit_rate_question_program(String0, Facts), !.
word_problem_reading(Text, classes(Classes), Facts) :-
    text_string(Text, String0),
    string_lower(String0, String),
    tokenize_atom(String, Tokens),
    phrase(problem_events(Events), Tokens),
    Events \== [],
    event_classes(Events, Classes0),
    sort(Classes0, Classes),
    compile_events(Events, Facts).

%! word_problem_refusal(+Text, -Reason) is semidet.
%
%  Named language-lane refusals remain metadata.  They never enter the fact
%  stream and never imply that an arithmetic machine exists.
word_problem_refusal(Text, comparison_ask) :-
    refusal_tokens(Text, Tokens),
    ( append(_, [are,there,more|_], Tokens)
    ; append(_, [which|_], Tokens)
    ; append(_, [who|_], Tokens)
    ), !.
word_problem_refusal(Text, discourse_ask) :-
    refusal_tokens(Text, Tokens),
    ( append(_, [what,do,you,notice|_], Tokens)
    ; append(_, [what,do,you,wonder|_], Tokens)
    ; append(_, [explain,how,you,know|_], Tokens)
    ).

refusal_tokens(Text, Tokens) :-
    text_string(Text, String0), string_lower(String0, String),
    tokenize_atom(String, Tokens), memberchk('?', Tokens).

text_string(Text, Text) :- string(Text), !.
text_string(Text, String) :- atom(Text), !, atom_string(Text, String).
text_string(Text, String) :- string_codes(String, Text), !.
text_string(Text, String) :- string_chars(String, Text).

problem_events([Event|Events]) -->
    problem_event(Event),
    problem_events(Events).
problem_events([]) --> [].

% Language-lane events consume one whole sentence.  Classification is
% conservative at the quantity boundary: a vacuous reading is available only
% when no number, comparison, or ask is present.
problem_event(Event) -->
    lane_sentence_tokens(Tokens), lane_sentence_end(End),
    { lane_event(Tokens, End, Event) }.

lane_sentence_tokens([Token|Tokens]) -->
    [Token], { \+ memberchk(Token, ['.','?','!']) }, !,
    lane_sentence_tokens_rest(Tokens).

lane_sentence_tokens_rest([Token|Tokens]) -->
    [Token], { \+ memberchk(Token, ['.','?','!']) }, !,
    lane_sentence_tokens_rest(Tokens).
lane_sentence_tokens_rest([]) --> [].

lane_sentence_end('.') --> ['.'].
lane_sentence_end('?') --> ['?'].
lane_sentence_end('!') --> ['!'].

lane_event(Tokens, '?', lane(ask, Ask, Span)) :-
    \+ lane_legacy_question(Tokens),
    \+ lane_unsupported_ask(Tokens),
    lane_ask(Tokens, Ask),
    lane_span(Tokens, '?', Span), !.
lane_event(Tokens, '.', lane(Class, Rate, Span)) :-
    \+ lane_legacy_conversion(Tokens),
    lane_rate(Tokens, Rate),
    Rate = rate(Class,_,_,_,_,_),
    lane_span(Tokens, '.', Span), !.
lane_event(Tokens, '.', lane(possession, Possession, Span)) :-
    lane_possession(Tokens, Possession),
    lane_span(Tokens, '.', Span), !.
lane_event(Tokens, '.', lane(acquire_remove, Change, Span)) :-
    \+ lane_legacy_change_or_transfer(Tokens),
    lane_acquire_remove(Tokens, Change),
    lane_span(Tokens, '.', Span), !.
lane_event(Tokens, End, lane(vacuous, vacuous_sentence, Span)) :-
    End \== '?', lane_vacuous(Tokens),
    lane_span(Tokens, End, Span).

lane_span(Tokens, End, Span) :-
    append(Tokens, [End], Surface),
    atomic_list_concat(Surface, ' ', Atom), atom_string(Atom, Span).

lane_vacuous(Tokens) :-
    \+ lane_quantity_mentions(Tokens, [_|_]),
    \+ memberchk('$', Tokens),
    \+ lane_comparative_token(Tokens),
    \+ lane_ask_head(Tokens),
    \+ lane_incomplete_quantitative_frame(Tokens).

lane_incomplete_quantitative_frame(Tokens) :-
    memberchk(each, Tokens), !.
lane_incomplete_quantitative_frame(Tokens) :-
    append(_, [there,Copula|_], Tokens), memberchk(Copula, [is,are]), !.
lane_incomplete_quantitative_frame(Tokens) :-
    member(Surface, Tokens), once(em_verb_base(Surface, Base, _)),
    memberchk(Base, [have,hold,cost,pay,earn,buy,sell,give,get,receive,lose,
                     remove,take,travel,run,print,type,read,work,fill,produce,
                     represent]), !.

lane_comparative_token(Tokens) :-
    member(Token, Tokens),
    memberchk(Token, [more,fewer,less,greater,smaller,larger,fastest,
                      slowest,heaviest,lightest,better,worse,same,different,
                      difference,compare]).

lane_ask_head(Tokens) :-
    member(Head, [how,what,which,who,where,when,why]), memberchk(Head, Tokens), !.
lane_ask_head(Tokens) :-
    member(Head, [are,is,do,does,did,can,could,would,should]),
    Tokens = [Head|_].

lane_possession(Tokens, possession(Subject, Number, Kind)) :-
    lane_verb_position(Tokens, [have,own,possess], Subject, After),
    lane_quantity_start(After, mention(Number,Kind), Rest),
    lane_possession_tail(Rest).

lane_possession_tail([Head|_]) :-
    memberchk(Head, [in,inside,on,with,of,at]).

lane_legacy_conversion([each|Tokens]) :-
    member(Surface, Tokens), once(em_verb_base(Surface, Base, _)),
    memberchk(Base, [have,hold]), !.

lane_legacy_question(Tokens) :-
    append(_, [how,many|Tail], Tokens),
    ( append(_, [does|Rest], Tail), member(Have, Rest),
      once(em_verb_base(Have, have, _))
    ; append(_, [are,there|_], Tail)
    ), !.
lane_legacy_question(Tokens) :-
    append(_, [how,much|Tail], Tokens), append(_, [does|_], Tail).

lane_unsupported_ask(Tokens) :- memberchk(might, Tokens), !.
lane_unsupported_ask(Tokens) :- append(_, [could,be,there|_], Tokens), !.
lane_unsupported_ask(Tokens) :- append(_, [what,is,the,value,of|_], Tokens), !.
lane_unsupported_ask([if,you|Tokens]) :-
    memberchk(per, Tokens), lane_quantity_mentions(Tokens, Mentions),
    memberchk(mention(0,_), Mentions), !.
lane_unsupported_ask(Tokens) :-
    ( memberchk(longer, Tokens) ; memberchk(shorter, Tokens) ), !.

lane_legacy_change_or_transfer([_Subject,Surface|After]) :-
    once(em_verb_base(Surface, Action, _)),
    memberchk(Action, [buy,give,eat,lose,get]),
    ( phrase(integer(_), After, KindTail), KindTail = [KindSurface|Rest],
      lane_surface_kind(KindSurface, _), Rest == []
    ; memberchk(Action, [give,get]),
      ( memberchk(to, After) ; memberchk(from, After) )
    ), !.

lane_rate(Tokens,
          rate(rate,Subject,OutputNumber,OutputKind,
               InputNumber,InputKind)) :-
    lane_verb_position(Tokens, [cost], Subject, _After),
    lane_payment_pair(Tokens, OutputNumber, OutputKind, InputNumber, InputKind), !.
lane_rate(Tokens,
          rate(payment_exchange,Subject,OutputNumber,OutputKind,
               InputNumber,InputKind)) :-
    lane_verb_position(Tokens, [pay,earn,buy,sell], Subject, _After),
    lane_payment_pair(Tokens, OutputNumber, OutputKind, InputNumber, InputKind), !.
lane_rate(Tokens,
          rate(motion_work_interval,Subject,OutputNumber,OutputKind,
               InputNumber,InputKind)) :-
    lane_verb_position(Tokens,
                       [travel,run,print,type,read,work,mow,fill,produce],
                       Subject, _After),
    lane_quantity_mentions(Tokens, Mentions),
    lane_ordered_rate_pair(Tokens, Mentions,
                           OutputNumber,OutputKind,InputNumber,InputKind), !.
lane_rate(Tokens,
          rate(rate,Subject,OutputNumber,OutputKind,InputNumber,InputKind)) :-
    lane_rate_marker(Tokens),
    lane_rate_subject(Tokens, Subject),
    lane_quantity_mentions(Tokens, Mentions),
    lane_ordered_rate_pair(Tokens, Mentions,
                           OutputNumber,OutputKind,InputNumber,InputKind), !.
lane_rate(Tokens,
          rate(rate,Subject,OutputNumber,OutputKind,1,InputKind)) :-
    lane_each_rate(Tokens, Subject, OutputNumber, OutputKind, InputKind).

lane_payment_pair(Tokens, OutputNumber, dollar, InputNumber, InputKind) :-
    lane_quantity_mentions(Tokens, Mentions),
    member(mention(OutputNumber,dollar), Mentions),
    member(mention(InputNumber,InputKind), Mentions), InputKind \== dollar, !.
lane_payment_pair(Tokens, OutputNumber, dollar, InputNumber, InputKind) :-
    lane_quantity_mentions(Tokens, Mentions),
    member(mention(OutputNumber,dollar), Mentions),
    append(SubjectTokens, [Cost|After], Tokens),
    once(em_verb_base(Cost, cost, _)),
    lane_last_noun(SubjectTokens, InputKind),
    append(_, [for|ForTail], After),
    lane_bare_number(ForTail, InputNumber).

lane_ordered_rate_pair([for|_],
                       [mention(InputNumber,InputKind),
                        mention(OutputNumber,OutputKind)|_],
                       OutputNumber,OutputKind,InputNumber,InputKind) :- !.
lane_ordered_rate_pair(_Tokens,
                       [mention(OutputNumber,OutputKind),
                        mention(InputNumber,InputKind)|_],
                       OutputNumber,OutputKind,InputNumber,InputKind).

lane_each_rate(Tokens, Subject, OutputNumber, OutputKind, InputKind) :-
    lane_quantity_mentions(Tokens, [mention(OutputNumber,OutputKind)]),
    ( append(_, [each,InputSurface|_], Tokens)
    ; append(_, [every,InputSurface|_], Tokens)
    ; append(_, [per,InputSurface|_], Tokens)
    ),
    lane_surface_kind(InputSurface, InputKind),
    lane_rate_subject(Tokens, Subject).
lane_each_rate(Tokens, Subject, OutputNumber, OutputKind, InputKind) :-
    append(_, [each,InputSurface,Represents|_], Tokens),
    once(em_verb_base(Represents, represent, _)),
    lane_surface_kind(InputSurface, InputKind),
    lane_quantity_mentions(Tokens, [mention(OutputNumber,OutputKind)]),
    Subject = InputKind.

lane_rate_marker(Tokens) :-
    memberchk(per, Tokens), !.
lane_rate_marker(Tokens) :-
    memberchk(each, Tokens), !.
lane_rate_marker(Tokens) :-
    memberchk(every, Tokens), !.
lane_rate_marker(Tokens) :-
    append(_, [for|_], Tokens).

lane_rate_subject(Tokens, Subject) :-
    lane_verb_position(Tokens,
                       [represent,use,cost,pay,earn,buy,sell,travel,run,print,
                        type,read,work,mow,fill,produce],
                       Subject, _After), !.
lane_rate_subject(_Tokens, rate_context).

lane_acquire_remove(Tokens, change(Subject, Action, Number, Kind)) :-
    lane_verb_position(Tokens,
                       [buy,give,get,receive,lose,remove,take],
                       Subject, After),
    lane_change_action(Tokens, Action),
    lane_quantity_mentions(After, [mention(Number,Kind)|_]).

lane_change_action(Tokens, Action) :-
    member(Token, Tokens), once(em_verb_base(Token, Action, _)),
    memberchk(Action, [buy,give,get,receive,lose,remove,take]), !.

lane_verb_position(Tokens, Bases, Subject, After) :-
    append(Before, [Surface|After], Tokens),
    once(em_verb_base(Surface, Base, _)), memberchk(Base, Bases),
    lane_subject_label(Before, Subject), !.

lane_subject_label(Before, Subject) :-
    reverse(Before, Reversed),
    member(Surface, Reversed), atom(Surface),
    \+ memberchk(Surface, [a,an,the,to,can,will,would,could,should,is,are,was,
                           were,has,have,had,of,for,in,at,on,from,and,or,her,
                           his,their,he,she,they,it,each,every]),
    lane_surface_kind(Surface, Subject), !.
lane_subject_label(_Before, subject).

lane_last_noun(Tokens, Kind) :-
    reverse(Tokens, Reversed), member(Surface, Reversed),
    lane_surface_kind(Surface, Kind), !.

lane_quantity_mentions([], []).
lane_quantity_mentions(Tokens, [Mention|Mentions]) :-
    lane_quantity_start(Tokens, Mention, Rest), !,
    lane_quantity_mentions(Rest, Mentions).
lane_quantity_mentions([_|Tokens], Mentions) :-
    lane_quantity_mentions(Tokens, Mentions).

lane_quantity_start(['$',Number|Rest], mention(Number,dollar), Rest) :-
    number(Number), \+ float(Number), !.
lane_quantity_start(Tokens, mention(Number,Kind), Rest) :-
    phrase(integer(Number), Tokens, AfterNumber),
    number(Number), \+ float(Number),
    lane_quantity_kind(AfterNumber, Kind, Rest).

lane_quantity_kind([Modifier,Surface|Rest], Kind, Rest) :-
    em_category(Modifier, adjective), lane_surface_kind(Surface, Kind), !.
lane_quantity_kind([Surface|Rest], Kind, Rest) :-
    lane_surface_kind(Surface, Kind).

lane_surface_kind(Surface, Kind) :-
    atom(Surface),
    ( once(math_claim_language:measurement_unit(Surface, Kind))
    ; preferred_noun_base(Surface, Kind)
    ).
lane_surface_kind(ml, milliliter) :- !.
lane_surface_kind(Surface, Kind) :-
    atom(Surface), \+ lane_kind_stopword(Surface),
    atom_chars(Surface, Chars), Chars \== [],
    maplist(lane_alpha_char, Chars),
    ( atom_concat(Singular, s, Surface), Singular \== '' -> Kind = Singular
    ; Kind = Surface
    ).

lane_alpha_char(Char) :- char_type(Char, alpha).

lane_kind_stopword(Surface) :-
    memberchk(Surface, [a,an,the,to,of,for,in,on,at,from,and,or,if,then,than,
                        is,are,was,were,be,been,being,do,does,did,can,could,
                        will,would,should,may,might,must,has,have,had,with,
                        this,that,these,those,his,her,their,our,your,my]).

lane_bare_number(Tokens, Number) :-
    phrase(integer(Number), Tokens, _), number(Number), \+ float(Number).

lane_ask(Tokens, ask(Type,AskedKind,Mentions)) :-
    lane_ask_suffix(Tokens, Type, AskedKind, AskTail),
    lane_quantity_mentions(AskTail, Mentions).

lane_ask_suffix(Tokens, how_many, AskedKind, Tail) :-
    append(_, [how,many,Surface|Tail], Tokens),
    lane_surface_kind(Surface, AskedKind), !.
lane_ask_suffix(Tokens, how_much, AskedKind, Tail) :-
    append(_, [how,much,Surface|Tail], Tokens),
    ( lane_surface_kind(Surface, AskedKind) -> true ; AskedKind = amount ), !.
lane_ask_suffix(Tokens, how_far, distance, Tail) :-
    append(_, [how,far|Tail], Tokens), !.
lane_ask_suffix(Tokens, how_long, duration, Tail) :-
    append(_, [how,long|Tail], Tokens), !.
lane_ask_suffix(Tokens, what_value, value, Tail) :-
    append(_, [what,is,the,Surface|Tail], Tokens),
    memberchk(Surface, [value,cost,rate,total,difference]), !.

problem_event(has(Subject, Number, Kind, Span)) -->
    subject(Subject), stative_verb(_Base), integer(Number), count_noun(Kind),
    possession_tail, ['.'],
    { format(string(Span), '~w has ~w ~w', [Subject, Number, Kind]) }.
problem_event(has(there, Number, Kind, Span)) -->
    [there], existential_copula, integer(Number), noun_base(Kind),
    existential_tail, ['.'],
    { format(string(Span), 'there are ~w ~w', [Number, Kind]) }.
problem_event(parts(Subject, Action, FirstNumber, FirstModifier,
                    SecondNumber, SecondModifier, Kind, Span)) -->
    subject(Subject), collection_verb(Action),
    integer(FirstNumber), modifier(FirstModifier), noun_base(Kind), [and],
    integer(SecondNumber), modifier(SecondModifier), noun_base(Kind), ['.'],
    { format(string(Span), '~w ~w ~w ~w ~w and ~w ~w ~w',
             [Subject, Action, FirstNumber, FirstModifier, Kind,
              SecondNumber, SecondModifier, Kind]) }.
problem_event(change(Subject, Action, Number, Kind, Span)) -->
    subject(Subject), change_verb(Action), integer(Number), noun_base(Kind), ['.'],
    { format(string(Span), '~w ~w ~w ~w', [Subject, Action, Number, Kind]) }.
problem_event(transfer(Subject, Action, Number, Kind, Recipient, Span)) -->
    transfer_subject(Subject), transfer_verb(Action), integer(Number),
    transfer_object(Kind), transfer_preposition(Action),
    recipient_phrase(Recipient), ['.'],
    { transfer_description(Subject, Action, Number, Kind, Recipient, Span) }.
problem_event(conversion(FromKind, Factor, ToKind, Span)) -->
    [each], noun_base(FromKind), verb_base(hold), integer(Factor), noun_base(ToKind), ['.'],
    { format(string(Span), 'each ~w holds ~w ~w', [FromKind, Factor, ToKind]) }.
problem_event(conversion(FromKind, Factor, ToKind, Span)) -->
    [each], noun_base(FromKind), verb_base(have), integer(Factor),
    noun_base(ToKind), conversion_tail, ['.'],
    { format(string(Span), 'each ~w has ~w ~w', [FromKind, Factor, ToKind]) }.
problem_event(measurement(Subject, Number, Unit, Dimension, Span)) -->
    measured_subject(Subject), [is], integer(Number), measurement_unit(Unit),
    dimension_word(Dimension), ['.'],
    { format(string(Span), '~w is ~w ~w ~w',
             [Subject, Number, Unit, Dimension]) }.
problem_event(question(Subject, Kind, Time)) -->
    [how, many], noun_base(Kind), [does], subject(Subject), verb_base(have),
    question_time(Time), ['?'].
problem_event(question(generic, Kind, Time)) -->
    [how, many], noun_base(Kind), [are, there], generic_question_time(Time), ['?'].
problem_event(amount_question(Kind, Subject, Action, Span)) -->
    [how, much], noun_base(Kind), [does], amount_subject(Subject),
    verb_base(Action), question_words(Tail), ['?'],
    { format(string(Span), 'how much ~w does ~w ~w ~w',
             [Kind, Subject, Action, Tail]) }.
problem_event(amount_question(amount, Subject, Action, Span)) -->
    [how, much, does], amount_subject(Subject), verb_base(Action),
    question_words(Tail), ['?'],
    { format(string(Span), 'how much does ~w ~w ~w',
             [Subject, Action, Tail]) }.
problem_event(comparison(Direction, Subject, Other, Kind, Span)) -->
    [how, many], comparison_direction(Direction), count_noun(Kind), [does],
    subject(Subject), verb_base(have), comparison_other(Other), ['?'],
    { format(string(Span), 'how many ~w ~w does ~w have',
             [Direction, Kind, Subject]) }.

%   A declarative comparison states the gap between two holdings.  It emits
%   the same difference/2 shape the question-frame comparison emits, with
%   the gap known instead of asked.
problem_event(comparison_decl(Subject, Direction, Number, Kind, Other, Span)) -->
    subject(Subject), stative_verb(_), integer(Number),
    comparison_direction(Direction), count_noun(Kind), [than],
    subject(Other), ['.'],
    { format(string(Span), '~w has ~w ~w ~w than ~w',
             [Subject, Number, Direction, Kind, Other]) }.

%   A multiplicative comparison states one holding as a multiple of
%   another.  It emits the existing scale/2 shape; the factor's kind marks
%   a scale between like kinds.
problem_event(comparison_times(Subject, Number, Kind, Other, Span)) -->
    subject(Subject), stative_verb(_), integer(Number),
    [times, as, many], count_noun(Kind), [as], subject(Other), ['.'],
    { format(string(Span), '~w has ~w times as many ~w as ~w',
             [Subject, Number, Kind, Other]) }.

%   The open verb frame.  Any verb the morphology holds may carry a counted
%   noun; the lemma is recorded rather than tested against a list.  What
%   the verb does — assert a first state, name a change, name a scale — is
%   a separate authoring judgment consulted through the lexical typing
%   seam; a lemma with no typing row compiles to a bare quantity and no
%   relation, so the number is kept without inventing how it combines.
%   This clause must stay the LAST problem_event//1 clause in the file:
%   every closed frame reads first, so a sentence a closed frame accepts
%   never falls through to this one.
problem_event(open_verb(Subject, Lemma, Number, Kind, Span)) -->
    subject(Subject), open_modal, open_verb_lemma(Lemma), integer(Number),
    count_noun(Kind), open_tail, ['.'],
    { format(string(Span), '~w ~w ~w ~w', [Subject, Lemma, Number, Kind]) }.

open_modal --> [can], !.
open_modal --> [].

open_verb_lemma(Lemma) --> [Surface],
    { atom(Surface), once(em_verb_base(Surface, Lemma, _)) }.

%   One bounded prepositional phrase or one participle; anything longer
%   refuses, so the frame cannot run away over a sentence it has not
%   understood.
open_tail --> [Preposition], optional_determiner, count_noun(_),
    { memberchk(Preposition, [on, in, at, from, inside, outside, of, for,
                              to, about]) }, !.
open_tail --> [Surface],
    { atom(Surface), once(em_verb_base(Surface, _, ing)) }, !.
open_tail --> [].

%   A subject was one bare token, so "The Ferris wheel holds 20 people." and
%   "A teacher prints 720 copies." refused on their determiner alone while the
%   same sentences with a bare name read. One optional determiner is admitted
%   and the head token still names the referent.
subject(Subject) --> optional_determiner, [Subject],
    { atom(Subject), atom_chars(Subject, [First|_]), char_type(First, alpha) }.
noun_base(Base) --> [Surface], { atom(Surface), preferred_noun_base(Surface, Base) }.
verb_base(Base) --> [Surface], { atom(Surface), once(em_verb_base(Surface, Base, _)) }.
change_verb(Action) --> [Surface],
    { atom(Surface), once(em_verb_base(Surface, Action, _)),
      memberchk(Action, [give, buy, eat, lose]) }.

transfer_subject(Subject) --> [Subject],
    { memberchk(Subject, [he,she,they]) }.
transfer_subject(Subject) --> subject(Subject).

transfer_verb(Action) --> [Surface],
    { atom(Surface), once(em_verb_base(Surface, Action, _)),
      memberchk(Action, [give,get]) }.

transfer_object(Kind) --> count_noun(Kind), !.
transfer_object(implicit) --> [].

transfer_preposition(give) --> [to].
transfer_preposition(get) --> [from].

recipient_phrase(Recipient) --> recipient_words(Words),
    { Words \== [], atomic_list_concat(Words, '_', Recipient) }.

recipient_words([Word|Words]) --> [Word], { Word \== '.' }, !,
    recipient_words(Words).
recipient_words([]) --> [].

transfer_description(Subject, give, Number, implicit, Recipient, Span) :-
    format(string(Span), '~w give ~w to ~w', [Subject,Number,Recipient]).
transfer_description(Subject, give, Number, Kind, Recipient, Span) :-
    Kind \== implicit,
    format(string(Span), '~w give ~w ~w to ~w',
           [Subject,Number,Kind,Recipient]).
transfer_description(Subject, get, Number, implicit, Recipient, Span) :-
    format(string(Span), '~w get ~w from ~w', [Subject,Number,Recipient]).
transfer_description(Subject, get, Number, Kind, Recipient, Span) :-
    Kind \== implicit,
    format(string(Span), '~w get ~w ~w from ~w',
           [Subject,Number,Kind,Recipient]).

collection_verb(Action) --> [Surface],
    { atom(Surface), once(em_verb_base(Surface, Action, _)),
      memberchk(Action, [have, spill]) }.

modifier(Modifier) --> [Surface],
    { atom(Surface),
      ( em_category(Surface, adjective)
      ; em_noun_base(Surface, _)
      ),
      Modifier = Surface }.

%!  stative_verb(-Base)// is semidet.
%
%   A verb that asserts what a subject stands in relation to, rather than a
%   delta on a holding it already had.  `change//1` cannot carry these: its
%   compilation requires a prior state, and "Mai made 8 frogs." asserts a
%   first state rather than changing one.
%
%   The list is the demand the rewrite consultation measured on 2026-08-14.
%   Of 103 refused restatements with a testable head noun, 86 carried a noun
%   the reader already counts, so the verb was the gap.  Corpus receipts,
%   one per admitted verb beyond `have`, each re-verified reading on
%   2026-08-15 (four earlier receipts named corpus strings the reader
%   refused; a docstring receipt that refuses is a defect):
%     hold     "The swings hold 14 people."
%     make     "Mai made 8 frogs."
%     collect  "They collect 27 adult books."
%     print    "A teacher prints 720 copies."
%     count    "Clare counts 8 sharks swimming."
%   `earn` remains in the list for the rate lane's sake, but every corpus
%   attestation of `earn` carries a currency amount this reader does not
%   yet quantify, so it has no reading receipt — a named limit, not an
%   oversight.  `own` and `possess` were already reachable through the lane
%   reader's own verb list and are named here so the two readers agree.
stative_verb(Base) --> [Surface],
    { atom(Surface), once(em_verb_base(Surface, Base, _)),
      memberchk(Base, [have, own, possess, hold, contain,
                       make, collect, print, earn, count]) }.

%!  locative_tail// is semidet.
%
%   A prepositional phrase that says where a counted collection sits. It binds
%   no quantity, so it is read and dropped: "There are 20 people ON THE WHEEL."
%   was refused for this tail alone. Bounded to one phrase so it cannot run
%   away over a sentence it has not understood.
locative_tail --> [Preposition], optional_determiner, noun_base(_),
    { memberchk(Preposition, [on, in, at, from, inside, outside]) }, !.
locative_tail --> [].

optional_determiner --> [Determiner],
    { memberchk(Determiner, [the, a, an, his, her, their, its]) }, !.
optional_determiner --> [].

possession_tail --> [of], noun_base(_), !.
possession_tail --> [for], noun_base(_), !.
possession_tail --> [about], noun_base(_), !.
possession_tail --> locative_tail.

existential_copula --> [are].
existential_copula --> [is].

existential_tail --> [of], noun_base(_), !.
existential_tail --> locative_tail.

conversion_tail --> [of], noun_base(_), !.
conversion_tail --> [in, it], !.
conversion_tail --> [].

count_noun(Kind) --> noun_base(_Modifier), noun_base(Kind).
count_noun(Kind) --> noun_base(Kind).

measurement_unit(Unit) --> [Surface],
    { atom(Surface),
      ( once(math_claim_language:measurement_unit(Surface, Unit))
      ; preferred_noun_base(Surface, Unit)
      ) }.

measured_subject(Subject) -->
    [Owner, '’', s], noun_base(Object),
    { atomic_list_concat([Owner,Object], '_', Subject) }.
measured_subject(Subject) -->
    [now, her], noun_base(Object),
    { atomic_list_concat([her,Object], '_', Subject) }.
measured_subject(Subject) -->
    [the, First], noun_base(Second),
    { atom(First), atom_chars(First, [Initial|_]), char_type(Initial, alpha),
      atomic_list_concat([First,Second], '_', Subject) }.
measured_subject(Subject) -->
    [the], noun_base(First), noun_base(Second),
    { atomic_list_concat([First,Second], '_', Subject) }.
measured_subject(Subject) -->
    [a, First, of], noun_base(Second),
    { atom(First), atom_chars(First, [Initial|_]), char_type(Initial, alpha),
      atomic_list_concat([First,Second], '_', Subject) }.

dimension_word(long) --> [long].
dimension_word(tall) --> [tall].
dimension_word(wide) --> [wide].
dimension_word(high) --> [high].

generic_question_time(altogether) --> [altogether].
generic_question_time(unspecified) --> [].

comparison_direction(more) --> [more].
comparison_direction(fewer) --> [fewer].

comparison_other(Other) --> [than], subject(Other), !.
comparison_other(implicit) --> [].

amount_subject(Subject) --> [each], noun_base(Kind),
    { atomic_list_concat([each,Kind], '_', Subject) }.
amount_subject(Subject) --> [the], noun_base(Kind),
    { atomic_list_concat([the,Kind], '_', Subject) }.
amount_subject(Subject) --> subject(Subject).

question_words([Word|Words]) --> [Word], { Word \== '?' }, !,
    question_words(Words).
question_words([]) --> [].

% Webster sometimes gives one plural more than one historical base (cookies
% is both cookie and cooky). Prefer the transparent modern suffix reading,
% then retain the dictionary's first remaining reading.
preferred_noun_base(Surface, Base) :-
    em_noun_base(Surface, Base),
    atom_concat(Base, s, Surface), !.
preferred_noun_base(Surface, Base) :-
    em_noun_base(Surface, Surface), !,
    Base = Surface.
preferred_noun_base(Surface, Base) :-
    once(em_noun_base(Surface, Base)).

% This qualified DCG call reuses the incumbent number-word tables. No table is
% copied into this pilot.
integer(Number) --> math_claim_language:integer_value(Number).

question_time(left) --> [left].
question_time(now) --> [now].
question_time(in_all) --> [in, all].
question_time(altogether) --> [altogether].
question_time(unspecified) --> [].

compile_events(Events, Facts) :-
    compile_events(Events, [], [], 1, [], RawFacts, Kinds0),
    list_to_set(Kinds0, KindSet),
    sort(KindSet, Kinds),
    ( RawFacts == [] -> Facts = []
    ; append(RawFacts, [discrete_kinds(Kinds)], Facts)
    ).

event_classes([], []).
event_classes([Event|Events], Classes) :-
    event_class(Event, Class), !,
    Classes = [Class|Rest], event_classes(Events, Rest).
event_classes([_|Events], Classes) :-
    event_classes(Events, Classes).

event_class(lane(Class,_,_), Class).
event_class(has(_,_,_,_), possession).
event_class(change(_,_,_,_,_), change).
event_class(transfer(_,_,_,_,_,_), acquire_remove).
event_class(conversion(_,_,_,_), conversion).
event_class(measurement(_,_,_,_,_), measured_dimension).
event_class(question(_,_,_), remaining_question).
event_class(amount_question(_,_,_,_), amount_question).
event_class(comparison(_,_,_,_,_), computable_comparison).
event_class(parts(_,_,_,_,_,_,_,_), partitioned_same_kind).
event_class(comparison_decl(_,_,_,_,_,_), declared_comparison).
event_class(comparison_times(_,_,_,_,_), multiplicative_comparison).
event_class(open_verb(_,_,_,_,_), open_verb).

compile_events([], _States, _Conversions, _ActionIndex, Facts, Facts, []).
compile_events([lane(vacuous,_,_)|Events], States, Conversions, Index,
               Facts0, Facts, Kinds) :-
    compile_events(Events, States, Conversions, Index, Facts0, Facts, Kinds).
compile_events([lane(possession,possession(Subject,Number,Kind),_)|Events],
               States0, Conversions, Index, Facts0, Facts, Kinds) :-
    lane_name(Subject, Kind, possessed, Name),
    replace_state(Subject, Kind, Name, Number, States0, States),
    append(Facts0, [quantity(Name,Number,Kind)], Facts1),
    compile_events(Events, States, Conversions, Index, Facts1, Facts, TailKinds),
    lane_discrete_kinds([Kind], Marks), append(Marks, TailKinds, Kinds).
compile_events([lane(Class,
                          rate(Class,Subject,OutputNumber,OutputKind,
                               InputNumber,InputKind),Span)|Events],
               States0, Conversions, Index, Facts0, Facts, Kinds) :-
    lane_name(Subject, OutputKind, rate_total, Total),
    lane_name(Subject, InputKind, rate_interval, Interval),
    lane_rate_name(Subject, OutputKind, InputKind, Rate),
    EventFacts = [quantity(Total,OutputNumber,OutputKind),
                  quantity(Interval,InputNumber,InputKind),
                  quantity(Rate,unknown,rate(OutputKind,InputKind)),
                  relation(Total,scale(Interval,Rate),Span)],
    States = [lane_rate(Class,Subject,OutputKind,InputKind,Rate)|States0],
    append(Facts0, EventFacts, Facts1),
    compile_events(Events, States, Conversions, Index, Facts1, Facts, TailKinds),
    lane_discrete_kinds([OutputKind,InputKind], Marks),
    append(Marks, TailKinds, Kinds).
compile_events([lane(acquire_remove,change(Subject,Action,Number,Kind),Span)|Events],
               States0, Conversions, Index, Facts0, Facts, Kinds) :-
    lane_change_facts(Subject, Action, Number, Kind, Span, States0,
                      States, EventFacts),
    append(Facts0, EventFacts, Facts1),
    compile_events(Events, States, Conversions, Index, Facts1, Facts, TailKinds),
    lane_discrete_kinds([Kind], Marks), append(Marks, TailKinds, Kinds).
compile_events([lane(ask,Ask,Span)|Events], States, Conversions, Index,
               Facts0, Facts, Kinds) :-
    lane_ask_facts(Ask, Span, States, QuestionFacts, QuestionKinds),
    append(Facts0, QuestionFacts, Facts1),
    compile_events(Events, States, Conversions, Index, Facts1, Facts, TailKinds),
    append(QuestionKinds, TailKinds, Kinds).
compile_events([has(Subject, Number, Kind, _Span)|Events], States0, Conversions,
               Index, Facts0, Facts, [Kind|Kinds]) :-
    referent_name(Subject, Kind, initial, Name),
    replace_state(Subject, Kind, Name, Number, States0, States),
    append(Facts0, [quantity(Name, Number, Kind)], Facts1),
    compile_events(Events, States, Conversions, Index, Facts1, Facts, Kinds).

lane_name(Subject, Kind, Stage, Name) :-
    atomic_list_concat([lane,Subject,Kind,Stage], '_', Name).

lane_rate_name(Subject, OutputKind, InputKind, Name) :-
    atomic_list_concat([lane,Subject,OutputKind,per,InputKind], '_', Name).

lane_change_facts(Subject, Action, Number, Kind, Span, States0, States,
                  [quantity(Amount,Number,Kind),
                   quantity(Result,unknown,Kind),
                   relation(Result,Recipe,Span)]) :-
    memberchk(state(Subject,Kind,Prior,_), States0),
    lane_name(Subject,Kind,Action,Amount),
    lane_name(Subject,Kind,after_change,Result),
    lane_change_recipe(Action, Prior, Amount, Recipe),
    replace_state(Subject,Kind,Result,unknown,States0,States), !.
lane_change_facts(Subject, Action, Number, Kind, _Span, States0,
                  [state(Subject,Kind,Amount,Number)|States0],
                  [quantity(Amount,Number,Kind)]) :-
    lane_name(Subject,Kind,Action,Amount).

lane_change_recipe(Action, Prior, Amount, sum([Prior,Amount])) :-
    memberchk(Action, [buy,get,receive]).
lane_change_recipe(Action, Prior, Amount, difference(Prior,Amount)) :-
    memberchk(Action, [give,lose,remove,take]).

lane_ask_facts(ask(what_value,_AskedKind,_Mentions), _Span, States,
               [asks(result,Rate)], []) :-
    member(lane_rate(_,_,_,_,Rate), States), !.
lane_ask_facts(ask(Type,_AskedKind,Mentions), Span, States, Facts, Kinds) :-
    member(lane_rate(_,Subject,OutputKind,InputKind,Rate), States),
    lane_rate_question(Type, Mentions, Subject, OutputKind, InputKind, Rate,
                       Span, Facts, Kinds), !.
lane_ask_facts(ask(_Type,AskedKind,_Mentions), _Span, _States,
               [quantity(lane_question_result,unknown,AskedKind),
                asks(result,lane_question_result)], Kinds) :-
    lane_discrete_kinds([AskedKind], Kinds).

lane_rate_question(Type, [mention(InputNumber,InputKind)|_], Subject,
                   OutputKind, InputKind, Rate, Span,
                   [quantity(Input,InputNumber,InputKind),
                    quantity(Result,unknown,OutputKind),
                    relation(Result,scale(Input,Rate),Span),
                    asks(result,Result)], Kinds) :-
    memberchk(Type, [how_many,how_much,how_far]),
    lane_name(Subject,InputKind,question_interval,Input),
    lane_name(Subject,OutputKind,question_result,Result),
    lane_discrete_kinds([OutputKind,InputKind], Kinds).
lane_rate_question(how_long, [mention(OutputNumber,OutputKind)|_], Subject,
                   OutputKind, InputKind, Rate, Span,
                   [quantity(Output,OutputNumber,OutputKind),
                    quantity(Result,unknown,InputKind),
                    relation(Output,scale(Result,Rate),Span),
                    asks(result,Result)], Kinds) :-
    lane_name(Subject,OutputKind,question_total,Output),
    lane_name(Subject,InputKind,question_result,Result),
    lane_discrete_kinds([OutputKind,InputKind], Kinds).
lane_rate_question(how_many, [mention(OutputNumber,OutputKind)|_], Subject,
                   OutputKind, InputKind, Rate, Span,
                   [quantity(Output,OutputNumber,OutputKind),
                    quantity(Result,unknown,InputKind),
                    relation(Output,scale(Result,Rate),Span),
                    asks(result,Result)], Kinds) :-
    lane_name(Subject,OutputKind,question_total,Output),
    lane_name(Subject,InputKind,question_result,Result),
    lane_discrete_kinds([OutputKind,InputKind], Kinds).

lane_discrete_kinds(Kinds, Discrete) :-
    include(lane_discrete_kind, Kinds, Discrete).

lane_discrete_kind(Kind) :-
    atom(Kind), \+ lane_continuous_kind(Kind).

lane_continuous_kind(Kind) :-
    memberchk(Kind, [amount,value,distance,duration,dollar,cent,money,
                     foot,inch,mile,meter,kilometer,gram,kilogram,pound,
                     ounce,liter,milliliter,ml,second,minute,hour,day,
                     week,month,year,degree,gallon,cup,teaspoon]).
compile_events([parts(Subject, Action, FirstNumber, FirstModifier,
                      SecondNumber, SecondModifier, Kind, Span)|Events],
               States0, Conversions, Index, Facts0, Facts, [Kind|Kinds]) :-
    atomic_list_concat([FirstModifier,part], '_', FirstStage),
    atomic_list_concat([SecondModifier,part], '_', SecondStage),
    referent_name(Subject, Kind, FirstStage, First),
    referent_name(Subject, Kind, SecondStage, Second),
    referent_name(Subject, Kind, total, TotalName),
    Total is FirstNumber + SecondNumber,
    EventFacts = [quantity(First, FirstNumber, Kind),
                  quantity(Second, SecondNumber, Kind),
                  quantity(TotalName, unknown, Kind),
                  relation(TotalName, sum([First, Second]), Span)],
    replace_state(Subject, Kind, TotalName, Total, States0, States),
    append(Facts0, EventFacts, Facts1),
    ( Action == have -> Next = Index ; Next is Index + 1 ),
    compile_events(Events, States, Conversions, Next, Facts1, Facts, Kinds).
compile_events([change(Subject, Action, Number, Kind, Span)|Events],
               States0, Conversions, Index, Facts0, Facts, [Kind|Kinds]) :-
    memberchk(state(Subject, Kind, Prior, _PriorValue), States0),
    signed_change(Action, Number, Signed),
    action_label(Action, Index, DeltaStage, ResultStage),
    referent_name(Subject, Kind, DeltaStage, Delta),
    referent_name(Subject, Kind, ResultStage, Result),
    EventFacts = [quantity(Delta, Signed, Kind),
                  quantity(Result, unknown, Kind),
                  relation(Result, sum([Prior, Delta]), Span)],
    replace_state(Subject, Kind, Result, unknown, States0, States),
    append(Facts0, EventFacts, Facts1),
    Next is Index + 1,
    compile_events(Events, States, Conversions, Next, Facts1, Facts, Kinds).
compile_events([transfer(Subject0, Action, Number, Kind0, _Recipient, Span)|Events],
               States0, Conversions, Index, Facts0, Facts, [Kind|Kinds]) :-
    transfer_state(Subject0, Kind0, States0, Subject, Kind, Prior),
    signed_change(Action, Number, Signed),
    action_label(Action, Index, DeltaStage, ResultStage),
    referent_name(Subject, Kind, DeltaStage, Delta),
    referent_name(Subject, Kind, ResultStage, Result),
    EventFacts = [quantity(Delta, Signed, Kind),
                  quantity(Result, unknown, Kind),
                  relation(Result, sum([Prior, Delta]), Span)],
    replace_state(Subject, Kind, Result, unknown, States0, States),
    append(Facts0, EventFacts, Facts1),
    Next is Index + 1,
    compile_events(Events, States, Conversions, Next, Facts1, Facts, Kinds).
compile_events([conversion(FromKind, Factor, ToKind, Span)|Events],
               States, Conversions0, Index, Facts0, Facts, [FromKind,ToKind|Kinds]) :-
    append(Facts0, [conversion(FromKind, ToKind, Factor, Span)], Facts1),
    compile_events(Events, States,
                   [conversion(FromKind, ToKind, Factor, Span)|Conversions0],
                   Index, Facts1, Facts, Kinds).
compile_events([measurement(Subject, Number, Unit, Dimension, _Span)|Events],
               States0, Conversions, Index, Facts0, Facts, [Unit|Kinds]) :-
    atomic_list_concat([measurement,Dimension], '_', Stage),
    referent_name(Subject, Unit, Stage, Name),
    replace_state(Subject, Unit, Name, Number, States0, States),
    append(Facts0, [quantity(Name, Number, Unit)], Facts1),
    compile_events(Events, States, Conversions, Index, Facts1, Facts, Kinds).
compile_events([comparison(Direction, Subject, Other, Kind, Span)|Events],
               States0, Conversions, Index, Facts0, Facts, [Kind|Kinds]) :-
    comparison_operands(Direction, Subject, Other, Kind, States0,
                        Minuend, _SubtrahendSubject, Subtrahend),
    atomic_list_concat([comparison,Direction,result], '_', ResultStage),
    referent_name(Subject, Kind, ResultStage, Result),
    EventFacts = [quantity(Result, unknown, Kind),
                  relation(Result, difference(Minuend, Subtrahend), Span),
                  asks(result, Result)],
    replace_state(Subject, Kind, Result, unknown, States0, States),
    append(Facts0, EventFacts, Facts1),
    compile_events(Events, States, Conversions, Index, Facts1, Facts, Kinds).
compile_events([comparison_decl(Subject, Direction, Number, Kind, Other, Span)|Events],
               States0, Conversions, Index, Facts0, Facts, [Kind|Kinds]) :-
    declared_state(Subject, Kind, States0, SubjectRef, SubjectFacts),
    declared_state(Other, Kind, States0, OtherRef, OtherFacts),
    referent_name(Subject, Kind, comparison_gap, Gap),
    comparison_decl_operands(Direction, SubjectRef, OtherRef, Minuend, Subtrahend),
    append(SubjectFacts, OtherFacts, ReferentFacts),
    append(ReferentFacts,
           [quantity(Gap, Number, Kind),
            relation(Gap, difference(Minuend, Subtrahend), Span)],
           EventFacts),
    replace_state(Subject, Kind, SubjectRef, unknown, States0, States),
    append(Facts0, EventFacts, Facts1),
    compile_events(Events, States, Conversions, Index, Facts1, Facts, Kinds).
compile_events([comparison_times(Subject, Number, Kind, Other, Span)|Events],
               States0, Conversions, Index, Facts0, Facts, [Kind|Kinds]) :-
    declared_state(Other, Kind, States0, OtherRef, OtherFacts),
    referent_name(Subject, Kind, times_result, SubjectRef),
    referent_name(Subject, Kind, times_factor, Factor),
    append(OtherFacts,
           [quantity(Factor, Number, rate(Kind, Kind)),
            quantity(SubjectRef, unknown, Kind),
            relation(SubjectRef, scale(OtherRef, Factor), Span)],
           EventFacts),
    replace_state(Subject, Kind, SubjectRef, unknown, States0, States),
    append(Facts0, EventFacts, Facts1),
    compile_events(Events, States, Conversions, Index, Facts1, Facts, Kinds).
compile_events([open_verb(Subject, Lemma, Number, Kind, Span)|Events],
               States0, Conversions, Index, Facts0, Facts, [Kind|Kinds]) :-
    open_verb_compile(Lemma, Subject, Number, Kind, Span, Index,
                      States0, States, Next, EventFacts),
    append(Facts0, EventFacts, Facts1),
    compile_events(Events, States, Conversions, Next, Facts1, Facts, Kinds).
compile_events([question(Subject, Kind, _Time)|Events],
               States, Conversions, Index, Facts0, Facts, [Kind|Kinds]) :-
    question_facts(Subject, Kind, States, Conversions, QuestionFacts),
    append(Facts0, QuestionFacts, Facts1),
    compile_events(Events, States, Conversions, Index, Facts1, Facts, Kinds).

%   A referent a comparison talks about: the existing state if one is
%   threaded, else a fresh unknown the comparison itself licenses.
declared_state(Subject, Kind, States, Ref, []) :-
    memberchk(state(Subject, Kind, Ref, _), States), !.
declared_state(Subject, Kind, _States, Ref, [quantity(Ref, unknown, Kind)]) :-
    referent_name(Subject, Kind, compared, Ref).

%   `more` states subject minus other; `fewer` states other minus subject.
comparison_decl_operands(more, SubjectRef, OtherRef, SubjectRef, OtherRef).
comparison_decl_operands(fewer, SubjectRef, OtherRef, OtherRef, SubjectRef).

%   A gain- or loss-typed lemma compiles through the existing change
%   emission when a prior state exists.  A first_state typing threads a
%   first state the way `have` does.  Any other case — no typing row, a
%   signed verb with no prior state, a transfer or factor typing the open
%   frame cannot yet witness — keeps the quantity and invents no relation
%   and no state.
open_verb_compile(Lemma, Subject, Number, Kind, Span, Index,
                  States0, States, Next, EventFacts) :-
    lexical_typing_store:lexical_typing(Lemma, Typing),
    open_signed_typing(Typing, Number, Signed),
    memberchk(state(Subject, Kind, Prior, _), States0), !,
    action_label(Lemma, Index, DeltaStage, ResultStage),
    referent_name(Subject, Kind, DeltaStage, Delta),
    referent_name(Subject, Kind, ResultStage, Result),
    EventFacts = [quantity(Delta, Signed, Kind),
                  quantity(Result, unknown, Kind),
                  relation(Result, sum([Prior, Delta]), Span)],
    replace_state(Subject, Kind, Result, unknown, States0, States),
    Next is Index + 1.
open_verb_compile(Lemma, Subject, Number, Kind, _Span, Index,
                  States0, States, Index, [quantity(Name, Number, Kind)]) :-
    lexical_typing_store:lexical_typing(Lemma, first_state), !,
    referent_name(Subject, Kind, Lemma, Name),
    replace_state(Subject, Kind, Name, Number, States0, States).
open_verb_compile(Lemma, Subject, Number, Kind, _Span, Index,
                  States, States, Index, [quantity(Name, Number, Kind)]) :-
    referent_name(Subject, Kind, Lemma, Name).

open_signed_typing(gain, Number, Number).
open_signed_typing(loss, Number, Signed) :- Signed is -Number.
compile_events([amount_question(Kind, Subject, Action, Span)|Events],
               States, Conversions, Index, Facts0, Facts, [Kind|Kinds]) :-
    referent_name(Subject, Kind, amount, Result),
    append(Facts0,
           [quantity(Result, unknown, Kind), asks(result, Result)], Facts1),
    % The surface receipt retains the action and span.  No arithmetic recipe
    % is invented when the amount relation is absent from the parsed program.
    atom(Action), string(Span),
    compile_events(Events, States, Conversions, Index, Facts1, Facts, Kinds).

question_facts(generic, ToKind, States, Conversions,
               [quantity(Result, unknown, ToKind),
                relation(Result, convert(Source, ToKind), Span),
                asks(result, Result)]) :-
    memberchk(conversion(FromKind, ToKind, _Factor, Span), Conversions),
    memberchk(state(Subject, FromKind, Source, _), States),
    referent_name(Subject, ToKind, converted, Result), !.
question_facts(Subject0, Kind, States, _Conversions, [asks(result, Name)]) :-
    question_owner(Subject0, Kind, States, Subject),
    memberchk(state(Subject, Kind, Name, _), States), !.
question_facts(Subject0, ToKind, States, Conversions,
               [quantity(Result, unknown, ToKind),
                relation(Result, convert(Source, ToKind), Span),
    asks(result, Result)]) :-
    memberchk(conversion(FromKind, ToKind, _Factor, Span), Conversions),
    question_owner(Subject0, FromKind, States, Subject),
    memberchk(state(Subject, FromKind, Source, _), States),
    referent_name(Subject, ToKind, converted, Result).
question_facts(Subject, Kind, _States, _Conversions,
               [quantity(Result, unknown, Kind), asks(result, Result)]) :-
    referent_name(Subject, Kind, demanded, Result).

question_owner(Subject0, Kind, States, Subject) :-
    pronoun_subject(Subject0),
    member(state(Subject, Kind, _, _), States), named_owner(Subject), !.
question_owner(Subject, _Kind, _States, Subject).

%! exact_value_question_program(+Text, -Facts) is semidet.
%
%  Compile the attested "What is the value of A op B?" surface without
%  passing decimal text through a float.  The result uses only the existing
%  sum/1 and scale/2 recipes understood by diagnosis_saturate.pl.
exact_value_question_program(Text0, Facts) :-
    text_string(Text0, Text),
    split_string(Text, " \t\n", " \t\n", Parts),
    Parts = [What,Is,The,Value,Of,LeftText,OperatorText,RightQuestion],
    maplist(string_lower, [What,Is,The,Value,Of],
            ["what","is","the","value","of"]),
    strip_question_mark(RightQuestion, RightText),
    exact_decimal_string(LeftText, Left),
    exact_decimal_string(RightText, Right),
    exact_operator(OperatorText, Operator),
    expression_program(Operator, Left, Right, Text, Facts).

strip_question_mark(Text, Bare) :-
    string_concat(Bare, "?", Text), Bare \== "".

exact_operator("+", add).
exact_operator("-", subtract).
exact_operator("×", multiply).
exact_operator("x", multiply).
exact_operator("*", multiply).
exact_operator("÷", divide).
exact_operator("/", divide).

exact_decimal_string(Text, Value) :-
    split_string(Text, ".", "", [WholeText,FractionText]), !,
    WholeText \== "", FractionText \== "",
    string_codes(WholeText, WholeCodes), maplist(decimal_digit_code, WholeCodes),
    string_codes(FractionText, FractionCodes),
    maplist(decimal_digit_code, FractionCodes),
    number_string(Whole, WholeText), number_string(Fraction, FractionText),
    string_length(FractionText, Places), Scale is 10^Places,
    Value is (Whole * Scale + Fraction) rdiv Scale.
exact_decimal_string(Text, Value) :-
    string_codes(Text, Codes), Codes \== [], maplist(decimal_digit_code, Codes),
    number_string(Value, Text), integer(Value).

decimal_digit_code(Code) :- code_type(Code, digit).

expression_program(add, Left, Right, Span,
    [quantity(expression_left,Left,value),
     quantity(expression_right,Right,value),
     quantity(expression_result,unknown,value),
     relation(expression_result,sum([expression_left,expression_right]),Span),
     asks(result,expression_result), discrete_kinds([])]).
expression_program(subtract, Left, Right, Span,
    [quantity(expression_left,Left,value),
     quantity(expression_negated_right,Negated,value),
     quantity(expression_result,unknown,value),
     relation(expression_result,
              sum([expression_left,expression_negated_right]),Span),
     asks(result,expression_result), discrete_kinds([])]) :-
    Negated is -Right.
expression_program(multiply, Left, Right, Span,
    [quantity(expression_factor,Left,scalar),
     quantity(expression_multiplicand,Right,value),
     quantity(expression_result,unknown,value),
     relation(expression_result,
              scale(expression_factor,expression_multiplicand),Span),
     asks(result,expression_result), discrete_kinds([])]).
expression_program(divide, Left, Right, Span,
    [quantity(expression_total,Left,value),
     quantity(expression_divisor,Right,scalar),
     quantity(expression_result,unknown,value),
     relation(expression_total,
              scale(expression_divisor,expression_result),Span),
     asks(result,expression_result), discrete_kinds([])]) :-
    Right =\= 0.

%! unit_rate_question_program(+Text, -Facts) is semidet.
%
%  Compile the leading G6-8 refusal bin when the rate, interval, and demand
%  all occur in one sentence.  The two admitted shapes cover a product and
%  its quotient inverse without consulting a sibling row or a diagram.
unit_rate_question_program(Text0, Facts) :-
    text_string(Text0, Text), string_lower(Text, Lower),
    tokenize_atom(Lower, Tokens),
    phrase(unit_rate_question(Facts, Text), Tokens).

unit_rate_question(Facts, Span) -->
    [if,you], verb_base(Action), integer(Rate), rate_count_noun(ResultKind),
    [per], noun_base(UnitKind), [for], integer(UnitCount), noun_base(UnitKind),
    [',',how,many], rate_count_noun(ResultKind), [will,you], verb_base(Action), ['?'],
    { Rate =\= 0,
      Facts = [quantity(unit_rate_factor,Rate,scalar),
               quantity(unit_rate_units,UnitCount,UnitKind),
               quantity(unit_rate_result,unknown,ResultKind),
               relation(unit_rate_result,
                        scale(unit_rate_factor,unit_rate_units),Span),
               asks(result,unit_rate_result),
               discrete_kinds([ResultKind,UnitKind])] }.
unit_rate_question(Facts, Span) -->
    [if,you], verb_base(Action), integer(Rate), rate_count_noun(ResultKind),
    [per], noun_base(UnitKind), [',',how,many], noun_base(UnitKind),
    [will,it,take,you,to], verb_base(Action), integer(Total),
    rate_count_noun(ResultKind), ['?'],
    { Rate =\= 0,
      Facts = [quantity(unit_rate_total,Total,ResultKind),
               quantity(unit_rate_divisor,Rate,scalar),
               quantity(unit_rate_result,unknown,UnitKind),
               relation(unit_rate_result,
                        quotient(unit_rate_total,unit_rate_divisor),Span),
               asks(result,unit_rate_result),
               discrete_kinds([ResultKind,UnitKind])] }.

rate_count_noun(Kind) --> [new], noun_base(Kind), !.
rate_count_noun(Kind) --> count_noun(Kind).

comparison_operands(more, Subject, Other0, Kind, States,
                    SubjectName, Other, OtherName) :-
    memberchk(state(Subject, Kind, SubjectName, _), States),
    comparison_other_state(Other0, Subject, Kind, States, Other, OtherName).
comparison_operands(fewer, Subject, Other0, Kind, States,
                    OtherName, Subject, SubjectName) :-
    memberchk(state(Subject, Kind, SubjectName, _), States),
    comparison_other_state(Other0, Subject, Kind, States, _Other, OtherName).

comparison_other_state(implicit, Subject, Kind, States, Other, Name) :-
    member(state(Other, Kind, Name, _), States),
    Other \== Subject, !.
comparison_other_state(Other, _Subject, Kind, States, Other, Name) :-
    Other \== implicit,
    memberchk(state(Other, Kind, Name, _), States).

transfer_state(Subject0, Kind0, States, Subject, Kind, Prior) :-
    pronoun_subject(Subject0),
    member(state(Subject, Kind, Prior, _), States),
    named_owner(Subject), compatible_transfer_kind(Kind0, Kind), !.
transfer_state(Subject, Kind0, States, Subject, Kind, Prior) :-
    \+ pronoun_subject(Subject),
    memberchk(state(Subject, Kind, Prior, _), States),
    compatible_transfer_kind(Kind0, Kind).

compatible_transfer_kind(implicit, _Kind).
compatible_transfer_kind(Kind, Kind) :- Kind \== implicit.

named_owner(Subject) :-
    \+ memberchk(Subject, [generic,there,he,she,they,pronoun]).

pronoun_subject(Subject) :- memberchk(Subject, [he,she,they]).

replace_state(Subject, Kind, Name, Value, States0,
              [state(Subject, Kind, Name, Value)|States]) :-
    exclude(same_state(Subject, Kind), States0, States).

same_state(Subject, Kind, state(Subject, Kind, _, _)).

signed_change(buy, Number, Number).
signed_change(give, Number, Signed) :- Signed is -Number.
signed_change(get, Number, Number).
signed_change(eat, Number, Signed) :- Signed is -Number.
signed_change(lose, Number, Signed) :- Signed is -Number.

action_label(Action, Index, Delta, Result) :-
    atomic_list_concat([Action, Index], '_', Tail),
    atomic_list_concat([Tail, change], '_', Delta),
    atomic_list_concat([after, Tail], '_', Result).

referent_name(Subject, Kind, Stage, Name) :-
    atomic_list_concat([Subject, Kind, Stage], '_', Name).

% 2026-08-15 relation-emission receipts: the open verb frame (typed and
% untyped lemmas), both declarative comparison frames, and `per` supplying
% the implicit rate denominator.  All five sentences are corpus-attested.
class_reader_receipt(open_verb, typed_first_state_verb,
    corpus_lesson('IM-G1-U3-L15'),
    "She sees 4 orioles.",
    [quantity(she_oriole_see,4,oriole),discrete_kinds([oriole])]).
class_reader_receipt(open_verb, untyped_verb_keeps_quantity_only,
    corpus_lesson('IM-G6-U2-L14'),
    "The train traveled 1564 miles.",
    [quantity(train_mile_travel,1564,mile),discrete_kinds([mile])]).
class_reader_receipt(declared_comparison, fewer_states_the_gap,
    corpus_lesson('IM-G1-U6-L15'),
    "Elena has 10 fewer paper stars than Priya.",
    [quantity(elena_star_compared,unknown,star),
     quantity(priya_star_compared,unknown,star),
     quantity(elena_star_comparison_gap,10,star),
     relation(elena_star_comparison_gap,
              difference(priya_star_compared,elena_star_compared),
              "elena has 10 fewer star than priya"),
     discrete_kinds([star])]).
class_reader_receipt(multiplicative_comparison, times_as_many,
    corpus_lesson('IM-G4-U5-L2'),
    "Jada has 4 times as many cubes as Kiran.",
    [quantity(kiran_cube_compared,unknown,cube),
     quantity(jada_cube_times_factor,4,rate(cube,cube)),
     quantity(jada_cube_times_result,unknown,cube),
     relation(jada_cube_times_result,
              scale(kiran_cube_compared,jada_cube_times_factor),
              "jada has 4 times as many cube as kiran"),
     discrete_kinds([cube])]).
class_reader_receipt(rate, per_supplies_the_implicit_one,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                bytes(601282,601326)),
    "A car can travel 35 miles per gallon of gas.",
    [quantity(lane_car_mile_rate_total,35,mile),
     quantity(lane_car_gallon_rate_interval,1,gallon),
     quantity(lane_car_mile_per_gallon,unknown,rate(mile,gallon)),
     relation(lane_car_mile_rate_total,
              scale(lane_car_gallon_rate_interval,lane_car_mile_per_gallon),
              "a car can travel 35 miles per gallon of gas ."),
     discrete_kinds([])]).

check_word_problem_reader_pilot :-
    forall(reader_receipt(Id, _OldSource, Text, ExpectedFacts, ExpectedName, ExpectedValue),
           run_reader_receipt(Id, Text, ExpectedFacts, ExpectedName, ExpectedValue)),
    forall(class_reader_receipt(Class, Id, _ClassSource, Text, ExpectedFacts),
           run_class_reader_receipt(Class, Id, Text, ExpectedFacts)),
    forall(class_negative_receipt(Class, Id, _NegativeSource, Text, _ClassReason),
           run_class_negative_receipt(Class, Id, Text)),
    forall(question_form_receipt(Class, Id, _Source, Text),
           run_question_form_receipt(Class, Id, Text)),
    forall(question_form_negative(Class, Id, Text, _QuestionReason),
           run_class_negative_receipt(Class, Id, Text)),
    % Deliberate refusal: wondering whether an amount is enough is outside the
    % admitted sentence classes.
    \+ word_problem_facts("Mia wonders whether nine guavas are enough.", _),
    writeln('word_problem_reader_pilot: all receipts passed').

run_reader_receipt(Id, Text, ExpectedFacts, ExpectedName, ExpectedValue) :-
    ( word_problem_facts(Text, Facts),
      Facts == ExpectedFacts,
      maplist(five_form_fact, Facts),
      seed(Facts), saturate(Facts),
      derived(ExpectedName, Value, _),
      Value =:= ExpectedValue
    -> true
    ;  format(user_error, 'word_problem_reader receipt failed: ~q~n', [Id]),
       fail
    ).

run_class_reader_receipt(Class, Id, Text, ExpectedFacts) :-
    ( word_problem_reading(Text, ReadingClass, Facts),
      Facts == ExpectedFacts,
      receipt_reading_class(Class, ReadingClass),
      maplist(five_form_fact, Facts)
    -> true
    ;  format(user_error, 'word_problem_reader class receipt failed: ~q/~q~n',
              [Class, Id]),
       fail
    ).

receipt_reading_class(Class, ReadingClass) :-
    language_lane_class(Class), !,
    ( ReadingClass == Class
    ; ReadingClass = classes(Classes), memberchk(Class, Classes)
    ).
receipt_reading_class(_Class, _ReadingClass).

language_lane_class(vacuous).
language_lane_class(possession).
language_lane_class(rate).
language_lane_class(payment_exchange).
language_lane_class(motion_work_interval).
language_lane_class(acquire_remove).

run_class_negative_receipt(Class, Id, Text) :-
    ( \+ word_problem_facts(Text, _)
    -> true
    ;  format(user_error, 'word_problem_reader negative receipt failed: ~q/~q~n',
              [Class, Id]),
       fail
    ).

run_question_form_receipt(Class, Id, Text) :-
    ( word_problem_facts(Text, Facts),
      member(asks(result, _), Facts),
      ( member(quantity(_,_,_), Facts) ; member(relation(_,_,_), Facts) ),
      maplist(five_form_fact, Facts)
    -> true
    ;  format(user_error, 'word_problem_reader question receipt failed: ~q/~q~n',
              [Class, Id]),
       fail
    ).

five_form_fact(quantity(_Name, Value, _Kind)) :-
    ( Value == unknown ; number(Value), \+ float(Value) ).
five_form_fact(conversion(_FromKind, _ToKind, Factor, Span)) :-
    integer(Factor), string(Span).
five_form_fact(relation(_Name, Recipe, Span)) :-
    five_form_recipe(Recipe), string(Span).
five_form_fact(asks(result, _Name)).
five_form_fact(discrete_kinds(Kinds)) :- is_list(Kinds).

five_form_recipe(convert(_Source, _ToKind)).
five_form_recipe(scale(_Scale, _Source)).
five_form_recipe(sum(Parts)) :- is_list(Parts).
five_form_recipe(difference(_Minuend, _Subtrahend)).
five_form_recipe(quotient(_Dividend, _Divisor)).

% Slice 18 demand counts are controller measurements over the 767 unparsed
% grade 6-7 sentences with usable machine truth.  The acquire/remove count
% excludes two bracketed answer annotations whose prose contains "multiply".
class_occurrence_basis(vacuous, 161, controller_shape_census).
class_occurrence_basis(possession, 14, controller_shape_census).
class_occurrence_basis(rate, 36, controller_shape_census).
class_occurrence_basis(payment_exchange, 31, controller_shape_census).
class_occurrence_basis(motion_work_interval, 53, controller_shape_census).
class_occurrence_basis(acquire_remove, 5, live_im_content_sentence_census).

class_reader_receipt(vacuous, explain_reasoning,
    corpus_span('curriculum/im_teacher_guides/grade6/unit8/lesson9.md',
                lines(492,492)),
    "Explain or show your reasoning.", []).
class_reader_receipt(vacuous, share_thinking,
    corpus_span('curriculum/im_teacher_guides/grade2/unit2/lesson5.md',
                lines(177,177)),
    "Be prepared to share your thinking.", []).
class_reader_receipt(vacuous, optional_table,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(2942,2942)),
    "You can use a table if it is helpful.", []).

class_reader_receipt(possession, clare_dimes,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(3240,3240)),
    "Clare has 6 dimes in her pocket.",
    [quantity(lane_clare_dime_possessed,6,dime),discrete_kinds([dime])]).
class_reader_receipt(possession, han_quarters,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(3242,3242)),
    "Han has 6 quarters in his pocket.",
    [quantity(lane_han_quarter_possessed,6,quarter),
     discrete_kinds([quarter])]).
class_reader_receipt(possession, restaurant_tables,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(3436,3436)),
    "A restaurant has 26 tables in its dining room.",
    [quantity(lane_restaurant_table_possessed,26,table),
     discrete_kinds([table])]).

class_reader_receipt(rate, neon_bracelets,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(3156,3156)),
    "Neon bracelets cost $1 for 4.",
    [quantity(lane_bracelet_dollar_rate_total,1,dollar),
     quantity(lane_bracelet_bracelet_rate_interval,4,bracelet),
     quantity(lane_bracelet_dollar_per_bracelet,unknown,
              rate(dollar,bracelet)),
     relation(lane_bracelet_dollar_rate_total,
              scale(lane_bracelet_bracelet_rate_interval,
                    lane_bracelet_dollar_per_bracelet),
              "neon bracelets cost $ 1 for 4 ."),
     discrete_kinds([bracelet])]).
class_reader_receipt(rate, cube_two_ml,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(2996,2996)),
    "Suppose each cube represents 2 ml.",
    [quantity(lane_cube_milliliter_rate_total,2,milliliter),
     quantity(lane_cube_cube_rate_interval,1,cube),
     quantity(lane_cube_milliliter_per_cube,unknown,
              rate(milliliter,cube)),
     relation(lane_cube_milliliter_rate_total,
              scale(lane_cube_cube_rate_interval,
                    lane_cube_milliliter_per_cube),
              "suppose each cube represents 2 ml ."),
     discrete_kinds([cube])]).
class_reader_receipt(rate, cube_five_ml,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(3012,3012)),
    "Suppose each cube represents 5 ml.",
    [quantity(lane_cube_milliliter_rate_total,5,milliliter),
     quantity(lane_cube_cube_rate_interval,1,cube),
     quantity(lane_cube_milliliter_per_cube,unknown,
              rate(milliliter,cube)),
     relation(lane_cube_milliliter_rate_total,
              scale(lane_cube_cube_rate_interval,
                    lane_cube_milliliter_per_cube),
              "suppose each cube represents 5 ml ."),
     discrete_kinds([cube])]).

class_reader_receipt(payment_exchange, clare_paid,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(2928,2928)),
    "Clare is paid $90 for 5 hours of work.",
    [quantity(lane_clare_dollar_rate_total,90,dollar),
     quantity(lane_clare_hour_rate_interval,5,hour),
     quantity(lane_clare_dollar_per_hour,unknown,rate(dollar,hour)),
     relation(lane_clare_dollar_rate_total,
              scale(lane_clare_hour_rate_interval,lane_clare_dollar_per_hour),
              "clare is paid $ 90 for 5 hours of work ."),
     discrete_kinds([])]).
class_reader_receipt(payment_exchange, jada_tacos,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(2932,2932)),
    "Jada's family bought 50 tacos for a party and paid $72.",
    [quantity(lane_family_dollar_rate_total,72,dollar),
     quantity(lane_family_taco_rate_interval,50,taco),
     quantity(lane_family_dollar_per_taco,unknown,rate(dollar,taco)),
     relation(lane_family_dollar_rate_total,
              scale(lane_family_taco_rate_interval,lane_family_dollar_per_taco),
              "jada ' s family bought 50 tacos for a party and paid $ 72 ."),
     discrete_kinds([taco])]).
class_reader_receipt(payment_exchange, clare_mowing,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(3460,3460)),
    "Clare mowed the lawn of a community center for 2 hours and earned $30.",
    [quantity(lane_hour_dollar_rate_total,30,dollar),
     quantity(lane_hour_hour_rate_interval,2,hour),
     quantity(lane_hour_dollar_per_hour,unknown,rate(dollar,hour)),
     relation(lane_hour_dollar_rate_total,
              scale(lane_hour_hour_rate_interval,lane_hour_dollar_per_hour),
              "clare mowed the lawn of a community center for 2 hours and earned $ 30 ."),
     discrete_kinds([])]).

class_reader_receipt(motion_work_interval, cyclist,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(2942,2942)),
    "In a sprint to the finish line, a professional cyclist travels 380 meters in 20 seconds.",
    [quantity(lane_cyclist_meter_rate_total,380,meter),
     quantity(lane_cyclist_second_rate_interval,20,second),
     quantity(lane_cyclist_meter_per_second,unknown,rate(meter,second)),
     relation(lane_cyclist_meter_rate_total,
              scale(lane_cyclist_second_rate_interval,
                    lane_cyclist_meter_per_second),
              "in a sprint to the finish line , a professional cyclist travels 380 meters in 20 seconds ."),
     discrete_kinds([])]).
class_reader_receipt(motion_work_interval, typing,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(2952,2952)),
    "Diego can type 140 words in 4 minutes.",
    [quantity(lane_diego_word_rate_total,140,word),
     quantity(lane_diego_minute_rate_interval,4,minute),
     quantity(lane_diego_word_per_minute,unknown,rate(word,minute)),
     relation(lane_diego_word_rate_total,
              scale(lane_diego_minute_rate_interval,lane_diego_word_per_minute),
              "diego can type 140 words in 4 minutes ."),
     discrete_kinds([word])]).
class_reader_receipt(motion_work_interval, copy_machine,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(3466,3466)),
    "A copy machine can print 480 copies every 4 minutes.",
    [quantity(lane_machine_copy_rate_total,480,copy),
     quantity(lane_machine_minute_rate_interval,4,minute),
     quantity(lane_machine_copy_per_minute,unknown,rate(copy,minute)),
     relation(lane_machine_copy_rate_total,
              scale(lane_machine_minute_rate_interval,lane_machine_copy_per_minute),
              "a copy machine can print 480 copies every 4 minutes ."),
     discrete_kinds([copy])]).

% These three receipts reuse the incumbent transfer facts while naming the
% broader acquire/remove surface class introduced by this slice.
class_reader_receipt(acquire_remove, lin_seeds,
    corpus_span('curriculum/im_teacher_guides/grade2/unit2/lesson11.md',
                lines(272,273)),
    "Lin has 31 sunflower seeds. She gives 15 to Priya. How many seeds does Lin have now?",
    [quantity(lin_seed_initial,31,seed),
     quantity(lin_seed_give_1_change,-15,seed),
     quantity(lin_seed_after_give_1,unknown,seed),
     relation(lin_seed_after_give_1,
              sum([lin_seed_initial,lin_seed_give_1_change]),
              "she give 15 to priya"),
     asks(result,lin_seed_after_give_1), discrete_kinds([seed])]).
class_reader_receipt(acquire_remove, books_to_kiran,
    corpus_span('curriculum/im_teacher_guides/grade1/unit2/lesson4.md',
                lines(426,428)),
    "Tyler has 7 books about spiders. He gives 3 to Kiran to read. How many books does Tyler have left?",
    [quantity(tyler_book_initial,7,book),
     quantity(tyler_book_give_1_change,-3,book),
     quantity(tyler_book_after_give_1,unknown,book),
     relation(tyler_book_after_give_1,
              sum([tyler_book_initial,tyler_book_give_1_change]),
              "he give 3 to kiran_to_read"),
     asks(result,tyler_book_after_give_1), discrete_kinds([book])]).
class_reader_receipt(acquire_remove, glue_sticks_from_table,
    corpus_span('curriculum/im_teacher_guides/grade1/unit3/lesson25.md',
                lines(228,231)),
    "Clare has 4 glue sticks. Clare gets 8 glue sticks from the red table. How many sticks does Clare have now?",
    [quantity(clare_stick_initial,4,stick),
     quantity(clare_stick_get_1_change,8,stick),
     quantity(clare_stick_after_get_1,unknown,stick),
     relation(clare_stick_after_get_1,
              sum([clare_stick_initial,clare_stick_get_1_change]),
              "clare get 8 stick from the_red_table"),
     asks(result,clare_stick_after_get_1), discrete_kinds([stick])]).

class_negative_receipt(vacuous, quantity_bearing,
    constructed_near_miss, "Explain your reasoning about 12 tiles.",
    quantity_bearing_not_vacuous).
class_negative_receipt(possession, missing_quantity,
    constructed_near_miss, "Clare has several dimes in her pocket.",
    missing_quantity).
class_negative_receipt(rate, missing_rate_value,
    constructed_near_miss, "Each cube represents some ml.",
    missing_rate_value).
class_negative_receipt(payment_exchange, missing_payment,
    constructed_near_miss, "Clare is paid for five hours.",
    missing_payment_quantity).
class_negative_receipt(motion_work_interval, missing_distance,
    constructed_near_miss, "A cyclist travels several meters in 20 seconds.",
    missing_output_quantity).
class_negative_receipt(acquire_remove, missing_acquired_quantity,
    constructed_near_miss, "Kylar wants to buy several glasses.",
    missing_acquired_quantity).

% Each admitted class below is pinned to three verbatim corpus sentences and
% an explicit source span. Near misses are constructed to exercise the class
% boundary without adding uncited positive syntax.

class_reader_receipt(existential_quantity, students,
    corpus_span('curriculum/im_teacher_guides/grade1/unit2/lesson12.md',
                lines(397,397)),
    "There are 6 students.",
    [quantity(there_student_initial,6,student),
     discrete_kinds([student])]).
class_reader_receipt(existential_quantity, pencils,
    corpus_span('curriculum/im_teacher_guides/grade1/unit2/lesson12.md',
                lines(307,307)),
    "There are 5 pencils.",
    [quantity(there_pencil_initial,5,pencil),
     discrete_kinds([pencil])]).
class_reader_receipt(existential_quantity, folders,
    corpus_span('curriculum/im_teacher_guides/grade1/unit2/lesson12.md',
                lines(298,298)),
    "There are 7 folders.",
    [quantity(there_folder_initial,7,folder),
     discrete_kinds([folder])]).

class_reader_receipt(equal_group_conversion, strawberries,
    corpus_span('curriculum/im_teacher_guides/grade3/unit1/lesson10.md',
                lines(270,270)),
    "Each bag has 2 strawberries.",
    [conversion(bag,strawberry,2,"each bag has 2 strawberry"),
     discrete_kinds([bag,strawberry])]).
class_reader_receipt(equal_group_conversion, fingers,
    corpus_span('curriculum/im_teacher_guides/grade3/unit1/lesson10.md',
                lines(270,270)),
    "Each hand has 5 fingers.",
    [conversion(hand,finger,5,"each hand has 5 finger"),
     discrete_kinds([finger,hand])]).
class_reader_receipt(equal_group_conversion, ducks,
    corpus_span('curriculum/im_teacher_guides/grade3/unit1/lesson12.md',
                lines(302,302)),
    "Each pond has 5 ducks.",
    [conversion(pond,duck,5,"each pond has 5 duck"),
     discrete_kinds([duck,pond])]).

class_reader_receipt(partitioned_same_kind, fish,
    corpus_span('curriculum/im_teacher_guides/grade1/unit2/lesson6.md',
                lines(163,163)),
    "He has 4 red fish and 5 blue fish.",
    [quantity(he_fish_red_part,4,fish),
     quantity(he_fish_blue_part,5,fish),
     quantity(he_fish_total,unknown,fish),
     relation(he_fish_total,sum([he_fish_red_part,he_fish_blue_part]),
              "he have 4 red fish and 5 blue fish"),
     discrete_kinds([fish])]).
class_reader_receipt(partitioned_same_kind, clare_counters,
    corpus_span('curriculum/im_teacher_guides/grade1/unit3/lesson2.md',
                lines(196,196)),
    "Clare spills 2 red counters and 8 yellow counters.",
    [quantity(clare_counter_red_part,2,counter),
     quantity(clare_counter_yellow_part,8,counter),
     quantity(clare_counter_total,unknown,counter),
     relation(clare_counter_total,
              sum([clare_counter_red_part,clare_counter_yellow_part]),
              "clare spill 2 red counter and 8 yellow counter"),
     discrete_kinds([counter])]).
class_reader_receipt(partitioned_same_kind, priya_counters,
    corpus_span('curriculum/im_teacher_guides/grade1/unit3/lesson2.md',
                lines(167,167)),
    "Priya spills 7 red counters and 2 yellow counters.",
    [quantity(priya_counter_red_part,7,counter),
     quantity(priya_counter_yellow_part,2,counter),
     quantity(priya_counter_total,unknown,counter),
     relation(priya_counter_total,
              sum([priya_counter_red_part,priya_counter_yellow_part]),
              "priya spill 7 red counter and 2 yellow counter"),
     discrete_kinds([counter])]).

class_reader_receipt(measured_dimension, lincoln_memorial,
    corpus_span('curriculum/im_teacher_guides/grade3/unit3/lesson2.md',
                lines(199,199)),
    "The Lincoln Memorial is 99 feet tall.",
    [quantity(lincoln_memorial_foot_measurement_tall,99,foot),
     discrete_kinds([foot])]).
class_reader_receipt(measured_dimension, washington_monument,
    corpus_span('curriculum/im_teacher_guides/grade3/unit3/lesson2.md',
                lines(199,199)),
    "The Washington Monument is 555 feet tall.",
    [quantity(washington_monument_foot_measurement_tall,555,foot),
     discrete_kinds([foot])]).
class_reader_receipt(measured_dimension, stack_of_books,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(3496,3496)),
    "A stack of books is 72 inches tall.",
    [quantity(stack_book_inch_measurement_tall,72,inch),
     discrete_kinds([inch])]).

class_reader_receipt(container_possession, bags_of_carrots,
    corpus_span('curriculum/im_teacher_guides/grade3/unit1/lesson12.md',
                lines(210,210)),
    "Andre has 3 bags of carrots.",
    [quantity(andre_bag_initial,3,bag), discrete_kinds([bag])]).
class_reader_receipt(container_possession, pairs_of_socks,
    corpus_span('curriculum/im_teacher_guides/grade3/unit1/lesson13.md',
                lines(151,151)),
    "Andre has 5 pairs of socks.",
    [quantity(andre_pair_initial,5,pair), discrete_kinds([pair])]).
class_reader_receipt(container_possession, piles_of_socks,
    corpus_span('curriculum/im_teacher_guides/grade3/unit1/lesson15.md',
                lines(241,241)),
    "Diego has 8 piles of socks.",
    [quantity(diego_pile_initial,8,pile), discrete_kinds([pile])]).

class_reader_receipt(computable_comparison, pattern_blocks,
    corpus_span('curriculum/im_teacher_guides/grade1/unit2/lesson15.md',
                lines(234,234)),
    "Elena has 4 pattern blocks. Tyler has 6 pattern blocks. How many fewer pattern blocks does Elena have than Tyler?",
    [quantity(elena_block_initial,4,block),
     quantity(tyler_block_initial,6,block),
     quantity(elena_block_comparison_fewer_result,unknown,block),
     relation(elena_block_comparison_fewer_result,
              difference(tyler_block_initial,elena_block_initial),
              "how many fewer block does elena have"),
     asks(result,elena_block_comparison_fewer_result),
     discrete_kinds([block])]).
class_reader_receipt(computable_comparison, stamps,
    corpus_span('curriculum/im_teacher_guides/grade1/unit6/lesson14.md',
                lines(302,302)),
    "Noah has 6 stamps. Tyler has 16 stamps. How many fewer stamps does Noah have than Tyler?",
    [quantity(noah_stamp_initial,6,stamp),
     quantity(tyler_stamp_initial,16,stamp),
     quantity(noah_stamp_comparison_fewer_result,unknown,stamp),
     relation(noah_stamp_comparison_fewer_result,
              difference(tyler_stamp_initial,noah_stamp_initial),
              "how many fewer stamp does noah have"),
     asks(result,noah_stamp_comparison_fewer_result),
     discrete_kinds([stamp])]).
class_reader_receipt(computable_comparison, tickets,
    corpus_span('curriculum/im_teacher_guides/grade1/unit8/lesson6.md',
                lines(159,159)),
    "Lin has 7 tickets for rides. Mai has 12 tickets. How many more tickets does Mai have than Lin?",
    [quantity(lin_ticket_initial,7,ticket),
     quantity(mai_ticket_initial,12,ticket),
     quantity(mai_ticket_comparison_more_result,unknown,ticket),
     relation(mai_ticket_comparison_more_result,
              difference(mai_ticket_initial,lin_ticket_initial),
              "how many more ticket does mai have"),
     asks(result,mai_ticket_comparison_more_result),
     discrete_kinds([ticket])]).

class_reader_receipt(contextual_group_total_question, ponds,
    corpus_span('curriculum/im_teacher_guides/grade3/unit1/lesson12.md',
                lines(302,302)),
    "There are 4 ponds. Each pond has 5 ducks. How many ducks are there altogether?",
    [quantity(there_pond_initial,4,pond),
     conversion(pond,duck,5,"each pond has 5 duck"),
     quantity(there_duck_converted,unknown,duck),
     relation(there_duck_converted,convert(there_pond_initial,duck),
              "each pond has 5 duck"),
     asks(result,there_duck_converted), discrete_kinds([duck,pond])]).
class_reader_receipt(contextual_group_total_question, boxes_of_toys,
    corpus_span('curriculum/im_teacher_guides/grade3/unit1/lesson15.md',
                lines(321,321)),
    "There are 4 boxes. Each box has 10 toys. How many toys are there?",
    [quantity(there_box_initial,4,box),
     conversion(box,toy,10,"each box has 10 toy"),
     quantity(there_toy_converted,unknown,toy),
     relation(there_toy_converted,convert(there_box_initial,toy),
              "each box has 10 toy"),
     asks(result,there_toy_converted), discrete_kinds([box,toy])]).
class_reader_receipt(contextual_group_total_question, boxes_of_erasers,
    corpus_span('curriculum/im_teacher_guides/grade3/unit4/lesson7.md',
                lines(275,275)),
    "There are 6 boxes. Each box has 8 erasers. How many erasers are there?",
    [quantity(there_box_initial,6,box),
     conversion(box,eraser,8,"each box has 8 eraser"),
     quantity(there_eraser_converted,unknown,eraser),
     relation(there_eraser_converted,convert(there_box_initial,eraser),
              "each box has 8 eraser"),
     asks(result,there_eraser_converted), discrete_kinds([box,eraser])]).

class_reader_receipt(contextual_transfer, lin_seeds,
    corpus_span('curriculum/im_teacher_guides/grade2/unit2/lesson11.md',
                lines(272,273)),
    "Lin has 31 sunflower seeds. She gives 15 to Priya. How many seeds does Lin have now?",
    [quantity(lin_seed_initial,31,seed),
     quantity(lin_seed_give_1_change,-15,seed),
     quantity(lin_seed_after_give_1,unknown,seed),
     relation(lin_seed_after_give_1,
              sum([lin_seed_initial,lin_seed_give_1_change]),
              "she give 15 to priya"),
     asks(result,lin_seed_after_give_1), discrete_kinds([seed])]).
class_reader_receipt(contextual_transfer, books_to_kiran,
    corpus_span('curriculum/im_teacher_guides/grade1/unit2/lesson4.md',
                lines(426,428)),
    "Tyler has 7 books about spiders. He gives 3 to Kiran to read. How many books does Tyler have left?",
    [quantity(tyler_book_initial,7,book),
     quantity(tyler_book_give_1_change,-3,book),
     quantity(tyler_book_after_give_1,unknown,book),
     relation(tyler_book_after_give_1,
              sum([tyler_book_initial,tyler_book_give_1_change]),
              "he give 3 to kiran_to_read"),
     asks(result,tyler_book_after_give_1), discrete_kinds([book])]).
class_reader_receipt(contextual_transfer, glue_sticks_from_table,
    corpus_span('curriculum/im_teacher_guides/grade1/unit3/lesson25.md',
                lines(228,231)),
    "Clare has 4 glue sticks. Clare gets 8 glue sticks from the red table. How many sticks does Clare have now?",
    [quantity(clare_stick_initial,4,stick),
     quantity(clare_stick_get_1_change,8,stick),
     quantity(clare_stick_after_get_1,unknown,stick),
     relation(clare_stick_after_get_1,
              sum([clare_stick_initial,clare_stick_get_1_change]),
              "clare get 8 stick from the_red_table"),
     asks(result,clare_stick_after_get_1), discrete_kinds([stick])]).

class_negative_receipt(existential_quantity, missing_integer,
    constructed_near_miss, "There are several students.", missing_integer).
class_negative_receipt(equal_group_conversion, missing_factor,
    constructed_near_miss, "Each bag has some strawberries.", missing_integer).
class_negative_receipt(partitioned_same_kind, missing_second_part,
    constructed_near_miss, "He has 4 red fish and blue fish.", missing_integer).
class_negative_receipt(measured_dimension, missing_dimension,
    constructed_near_miss, "The Lincoln Memorial is 99 feet.",
    missing_dimension_word).
class_negative_receipt(container_possession, missing_container_count,
    constructed_near_miss, "Andre has bags of carrots.", missing_integer).
class_negative_receipt(computable_comparison, absent_referent_set,
    constructed_near_miss,
    "How many fewer stamps does Noah have than Tyler?", absent_referent_set).
class_negative_receipt(contextual_group_total_question, unsupported_modal,
    constructed_near_miss, "How many erasers could be there?",
    unsupported_modal).
class_negative_receipt(contextual_transfer, pronoun_without_antecedent,
    constructed_near_miss, "She gives 3 to Kiran.", absent_named_owner).

% Each admitted question family has three corpus receipts and one boundary.
% Comparison receipts include their quantitative context because an ask is
% emitted only when the program can carry the subtraction relation.
question_form_receipt(lane_how_many, copies,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(3466,3466)),
    "How many copies can it print in 10 minutes?").
question_form_receipt(lane_how_many, bottles,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(3190,3190)),
    "How many bottles can you buy for $3?").
question_form_receipt(lane_how_many, books,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(3162,3162)),
    "How many books can you buy for $21?").
question_form_negative(lane_how_many, comparison_ask,
    "Are there more cats or dogs?", comparison_ask).

question_form_receipt(lane_how_much, blue_paint,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(2996,2996)),
    "How much blue paint is there (3 blue cubes)?").
question_form_receipt(lane_how_much, red_paint,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(2998,2998)),
    "How much red paint is there (5 red cubes)?").
question_form_receipt(lane_how_much, cheese,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(2918,2918)),
    "How much cheese does Mai use per pizza?").
question_form_negative(lane_how_much, discourse_ask,
    "What do you notice?", discourse_ask).

question_form_receipt(lane_how_far, cyclist,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(2942,2942)),
    "How far does the cyclist travel in 3 seconds?").
question_form_receipt(lane_how_far, elevator_twelve,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(3438,3438)),
    "How far can this elevator travel in 12 seconds?").
question_form_receipt(lane_how_far, elevator_eleven,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(3452,3452)),
    "How far does the elevator travel in 11 seconds?").
question_form_negative(lane_how_far, comparison_ask,
    "How does its position compare to the other point?", comparison_ask).

question_form_receipt(lane_how_long, typing,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(2952,2952)),
    "How long will it take him to type 385 words?").
question_form_receipt(lane_how_long, printing,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(3472,3472)),
    "How long did it take to print?").
question_form_receipt(lane_how_long, tables,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(3436,3436)),
    "How long will it take the waitstaff to clear and set all the tables?").
question_form_negative(lane_how_long, comparison_ask,
    "How long is the longer route?", comparison_ask).

question_form_receipt(lane_what_named, bracelet_cost,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(3156,3156)),
    "What is the cost per bracelet?").
question_form_receipt(lane_what_named, book_cost,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(3162,3162)),
    "What is the cost per book?").
question_form_receipt(lane_what_named, bag_cost,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(3186,3186)),
    "What is the cost per bag?").
question_form_negative(lane_what_named, discourse_ask,
    "What do you notice?", discourse_ask).

question_form_receipt(how_many_have, rocks_now,
    corpus_span('curriculum/im_teacher_guides/grade1/unit3/lesson11.md',
                lines(152,152)),
    "How many rocks does Kiran have now?").
question_form_receipt(how_many_have, seeds_now,
    corpus_span('curriculum/im_teacher_guides/grade2/unit2/lesson11.md',
                lines(272,273)),
    "How many seeds does Lin have now?").
question_form_receipt(how_many_have, earrings,
    corpus_span('curriculum/im_teacher_guides/grade3/unit1/lesson12.md',
                lines(210,216)),
    "How many earrings does Jada have?").
question_form_negative(how_many_have, unsupported_modal,
    "How many rocks might Kiran have?", unsupported_modal).

question_form_receipt(how_many_there, toys,
    corpus_span('curriculum/im_teacher_guides/grade3/unit1/lesson15.md',
                lines(321,321)),
    "How many toys are there?").
question_form_receipt(how_many_there, shirts,
    corpus_span('curriculum/im_teacher_guides/grade3/unit1/lesson15.md',
                lines(254,258)),
    "How many shirts are there?").
question_form_receipt(how_many_there, trees,
    corpus_span('curriculum/im_teacher_guides/grade3/unit1/lesson19.md',
                lines(277,277)),
    "How many trees are there?").
question_form_negative(how_many_there, missing_kind,
    "How many are there?", missing_kind).

question_form_receipt(how_much, water,
    corpus_span('curriculum/im_teacher_guides/grade5/unit2/lesson3.md',
                lines(147,150)),
    "How much water does each dancer get?").
question_form_receipt(how_much, cheese,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(2918,2918)),
    "How much cheese does Mai use per pizza?").
question_form_receipt(how_much, gas,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(3378,3378)),
    "How much gas does the car use to go 100 miles?").
question_form_negative(how_much, unsupported_modal,
    "How much water might each dancer get?", unsupported_modal).

question_form_receipt(exact_value, multiplication,
    corpus_span('curriculum/im/generated/recovered_task_spans.json',
                lines(5374,5374)),
    "What is the value of 6 × 7?").
question_form_receipt(exact_value, division,
    corpus_span('curriculum/im/generated/recovered_task_spans.json',
                lines(7621,7621)),
    "What is the value of 78 ÷ 6?").
question_form_receipt(exact_value, decimal_addition,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(2730,2730)),
    "What is the value of 1.20 + 0.13?").
question_form_negative(exact_value, division_by_zero,
    "What is the value of 8 ÷ 0?", division_by_zero).

question_form_receipt(comparison, pattern_blocks,
    corpus_span('curriculum/im_teacher_guides/grade1/unit2/lesson15.md',
                lines(232,236)),
    "Elena has 4 pattern blocks. Tyler has 6 pattern blocks. How many fewer pattern blocks does Elena have than Tyler?").
question_form_receipt(comparison, stamps,
    corpus_span('curriculum/im_teacher_guides/grade1/unit6/lesson14.md',
                lines(302,305)),
    "Noah has 6 stamps. Tyler has 16 stamps. How many fewer stamps does Noah have than Tyler?").
question_form_receipt(comparison, tickets,
    corpus_span('curriculum/im_teacher_guides/grade1/unit8/lesson6.md',
                lines(159,162)),
    "Lin has 7 tickets for rides. Mai has 12 tickets. How many more tickets does Mai have than Lin?").
question_form_negative(comparison, absent_referent_set,
    "How many fewer stamps does Noah have than Tyler?", absent_referent_set).

question_form_receipt(unit_rate_question, practices,
    corpus_span('hermes/app/runtime/experiments/gemma4_tutor/docling/full-output/TeacherLessonGuides/Grade7/Grade7-5-12-Lesson-teacher-guide-/document.md',
                lines(111,111)),
    "If you run 15 laps per practice, how many practices will it take you to run 30 laps?").
question_form_receipt(unit_rate_question, shirts,
    corpus_span('hermes/app/runtime/experiments/gemma4_tutor/docling/full-output/TeacherLessonGuides/Grade7/Grade7-5-12-Lesson-teacher-guide-/document.md',
                lines(109,109)),
    "If you fold 5 shirts per minute for 8 minutes, how many shirts will you fold?").
question_form_receipt(unit_rate_question, songs,
    corpus_span('hermes/app/runtime/experiments/gemma4_tutor/docling/full-output/TeacherLessonGuides/Grade7/Grade7-5-12-Lesson-teacher-guide-/document.md',
                lines(110,110)),
    "If you hear 9 new songs per day for 3 days, how many new songs will you hear?").
question_form_negative(unit_rate_question, zero_rate,
    "If you fold 0 shirts per minute for 8 minutes, how many shirts will you fold?",
    zero_rate).

% The first sentence is verbatim from mistake_location_full.json item 22.
reader_receipt(dataset_22, mistake_location_full(22),
    "Mitchell has 30 pencils. Mitchell gives 6 pencils. How many pencils does Mitchell have left?",
    [quantity(mitchell_pencil_initial,30,pencil),
     quantity(mitchell_pencil_give_1_change,-6,pencil),
     quantity(mitchell_pencil_after_give_1,unknown,pencil),
     relation(mitchell_pencil_after_give_1,
              sum([mitchell_pencil_initial,mitchell_pencil_give_1_change]),
              "mitchell give 6 pencil"),
     asks(result,mitchell_pencil_after_give_1), discrete_kinds([pencil])],
    mitchell_pencil_after_give_1, 24).

% The first sentence is verbatim from mistake_location_full.json item 246.
reader_receipt(dataset_246, mistake_location_full(246),
    "She has 42 cookies. She eats 2 cookies. How many cookies does She have left?",
    [quantity(she_cookie_initial,42,cookie),
     quantity(she_cookie_eat_1_change,-2,cookie),
     quantity(she_cookie_after_eat_1,unknown,cookie),
     relation(she_cookie_after_eat_1,
              sum([she_cookie_initial,she_cookie_eat_1_change]),
              "she eat 2 cookie"),
     asks(result,she_cookie_after_eat_1), discrete_kinds([cookie])],
    she_cookie_after_eat_1, 40).

% The first sentence is verbatim from mistake_location_full.json item 1250.
reader_receipt(dataset_1250, mistake_location_full(1250),
    "He has 2 dogs. He buys 3 dogs. How many dogs does He have now?",
    [quantity(he_dog_initial,2,dog),
     quantity(he_dog_buy_1_change,3,dog),
     quantity(he_dog_after_buy_1,unknown,dog),
     relation(he_dog_after_buy_1,
              sum([he_dog_initial,he_dog_buy_1_change]),
              "he buy 3 dog"),
     asks(result,he_dog_after_buy_1), discrete_kinds([dog])],
    he_dog_after_buy_1, 5).

% Guava is absent from the incumbent measurement_unit/2 table; Webster noun1
% row 40834 supplies its morphology.
reader_receipt(webster_guava, constructed,
    "Mia has 9 guavas. Mia eats 4 guavas. How many guavas does Mia have left?",
    [quantity(mia_guava_initial,9,guava),
     quantity(mia_guava_eat_1_change,-4,guava),
     quantity(mia_guava_after_eat_1,unknown,guava),
     relation(mia_guava_after_eat_1,
              sum([mia_guava_initial,mia_guava_eat_1_change]),
              "mia eat 4 guava"),
     asks(result,mia_guava_after_eat_1), discrete_kinds([guava])],
    mia_guava_after_eat_1, 5).

reader_receipt(number_words, constructed,
    "Noah has twelve shells. Noah gives two shells. How many shells does Noah have left?",
    [quantity(noah_shell_initial,12,shell),
     quantity(noah_shell_give_1_change,-2,shell),
     quantity(noah_shell_after_give_1,unknown,shell),
     relation(noah_shell_after_give_1,
              sum([noah_shell_initial,noah_shell_give_1_change]),
              "noah give 2 shell"),
     asks(result,noah_shell_after_give_1), discrete_kinds([shell])],
    noah_shell_after_give_1, 10).

reader_receipt(lose_change, constructed,
    "Ava has 7 marbles. Ava loses 3 marbles. How many marbles does Ava have now?",
    [quantity(ava_marble_initial,7,marble),
     quantity(ava_marble_lose_1_change,-3,marble),
     quantity(ava_marble_after_lose_1,unknown,marble),
     relation(ava_marble_after_lose_1,
              sum([ava_marble_initial,ava_marble_lose_1_change]),
              "ava lose 3 marble"),
     asks(result,ava_marble_after_lose_1), discrete_kinds([marble])],
    ava_marble_after_lose_1, 4).

reader_receipt(buy_change, constructed,
    "Eli has 5 books. Eli buys 4 books. How many books does Eli have in all?",
    [quantity(eli_book_initial,5,book),
     quantity(eli_book_buy_1_change,4,book),
     quantity(eli_book_after_buy_1,unknown,book),
     relation(eli_book_after_buy_1,
              sum([eli_book_initial,eli_book_buy_1_change]),
              "eli buy 4 book"),
     asks(result,eli_book_after_buy_1), discrete_kinds([book])],
    eli_book_after_buy_1, 9).

reader_receipt(basket_conversion, constructed,
    "Lina has 3 baskets. Each basket holds 4 apples. How many apples does Lina have in all?",
    [quantity(lina_basket_initial,3,basket),
     conversion(basket,apple,4,"each basket holds 4 apple"),
     quantity(lina_apple_converted,unknown,apple),
     relation(lina_apple_converted,convert(lina_basket_initial,apple),
              "each basket holds 4 apple"),
     asks(result,lina_apple_converted), discrete_kinds([apple,basket])],
    lina_apple_converted, 12).

reader_receipt(box_conversion, constructed,
    "Omar has two boxes. Each box holds five pencils. How many pencils does Omar have now?",
    [quantity(omar_box_initial,2,box),
     conversion(box,pencil,5,"each box holds 5 pencil"),
     quantity(omar_pencil_converted,unknown,pencil),
     relation(omar_pencil_converted,convert(omar_box_initial,pencil),
              "each box holds 5 pencil"),
     asks(result,omar_pencil_converted), discrete_kinds([box,pencil])],
    omar_pencil_converted, 10).

reader_receipt(possession_identity, constructed,
    "Iris has eight balls. How many balls does Iris have now?",
    [quantity(iris_ball_initial,8,ball),
     asks(result,iris_ball_initial), discrete_kinds([ball])],
    iris_ball_initial, 8).
