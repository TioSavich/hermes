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
            exact_value_question_program/2,
            word_problem_reader_pilot_summary/1,
            check_word_problem_reader_pilot/0
          ]).

:- use_module(library(lists), [append/2, list_to_set/2]).
:- use_module(library(porter_stem), [tokenize_atom/2]).
:- use_module('english_morphology.pl').
:- use_module('../../../hermes/math_claim_language.pl', []).
:- ensure_loaded('../../../scripts/sidekick/diagnosis_saturate.pl').

:- discontiguous question_form_receipt/4.
:- discontiguous question_form_negative/4.

word_problem_reader_pilot_summary(
    summary(role(orphan_seam_reader),
            accepted_classes([possession, change, conversion, remaining_question,
                              equal_group_conversion, existential_quantity,
                              partitioned_same_kind, measured_dimension,
                              container_possession, computable_comparison,
                              contextual_group_total_question,
                              amount_question, exact_value_question,
                              contextual_transfer, unit_rate_question]),
            output_contract(five_form_sidekick_schema),
            receipt_count(62))).

%! word_problem_facts(+Text, -Facts) is semidet.
%
%  Parse the whole text. Failure of any sentence refuses the text; the caller
%  never receives facts from an accepted prefix.
word_problem_facts(Text, Facts) :-
    text_string(Text, String0),
    exact_value_question_program(String0, Facts), !.
word_problem_facts(Text, Facts) :-
    text_string(Text, String0),
    unit_rate_question_program(String0, Facts), !.
word_problem_facts(Text, Facts) :-
    text_string(Text, String0),
    string_lower(String0, String),
    tokenize_atom(String, Tokens),
    phrase(problem_events(Events), Tokens),
    compile_events(Events, Facts).

text_string(Text, Text) :- string(Text), !.
text_string(Text, String) :- atom(Text), !, atom_string(Text, String).
text_string(Text, String) :- string_codes(String, Text), !.
text_string(Text, String) :- string_chars(String, Text).

problem_events([Event|Events]) -->
    problem_event(Event),
    problem_events(Events).
problem_events([]) --> [].

problem_event(has(Subject, Number, Kind, Span)) -->
    subject(Subject), verb_base(have), integer(Number), count_noun(Kind),
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

subject(Subject) --> [Subject], { atom(Subject), atom_chars(Subject, [First|_]), char_type(First, alpha) }.
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

possession_tail --> [of], noun_base(_), !.
possession_tail --> [for], noun_base(_), !.
possession_tail --> [about], noun_base(_), !.
possession_tail --> [].

existential_copula --> [are].
existential_copula --> [is].

existential_tail --> [of], noun_base(_), !.
existential_tail --> [].

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
    append(RawFacts, [discrete_kinds(Kinds)], Facts).

compile_events([], _States, _Conversions, _ActionIndex, Facts, Facts, []).
compile_events([has(Subject, Number, Kind, _Span)|Events], States0, Conversions,
               Index, Facts0, Facts, [Kind|Kinds]) :-
    referent_name(Subject, Kind, initial, Name),
    replace_state(Subject, Kind, Name, Number, States0, States),
    append(Facts0, [quantity(Name, Number, Kind)], Facts1),
    compile_events(Events, States, Conversions, Index, Facts1, Facts, Kinds).
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
compile_events([question(Subject, Kind, _Time)|Events],
               States, Conversions, Index, Facts0, Facts, [Kind|Kinds]) :-
    question_facts(Subject, Kind, States, Conversions, QuestionFacts),
    append(Facts0, QuestionFacts, Facts1),
    compile_events(Events, States, Conversions, Index, Facts1, Facts, Kinds).
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
    ( word_problem_facts(Text, Facts),
      Facts == ExpectedFacts,
      maplist(five_form_fact, Facts)
    -> true
    ;  format(user_error, 'word_problem_reader class receipt failed: ~q/~q~n',
              [Class, Id]),
       fail
    ).

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
