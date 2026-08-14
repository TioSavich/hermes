:- encoding(utf8).
/** <module> Persistent Prolog worker for the PUSU language harness
 *
 * The Python harness sends one defragged task statement at a time.  This
 * worker keeps the incumbent reader, APE, its generated user lexicon, and the
 * referent saturation predicates loaded across statements.  It returns one
 * complete JSON receipt per input line.
 */

:- module(pusu_harness_runner, []).

:- use_module(library(http/json)).
:- use_module(library(porter_stem), [tokenize_atom/2]).
:- use_module(library(readutil), [read_line_to_string/2]).
:- use_module('../../knowledge/strategies/abstraction/word_problem_reader_pilot.pl').
:- use_module('../../knowledge/strategies/abstraction/ape_reader_pilot.pl').
:- use_module('../../knowledge/strategies/abstraction/pedagogy_force_pilot.pl').
:- use_module('../../knowledge/strategies/abstraction/english_morphology.pl', []).

:- initialization(main, main).

main :-
    prompt_loop.

prompt_loop :-
    read_line_to_string(user_input, Line),
    ( Line == end_of_file
    -> true
    ; catch(process_line(Line, Reply), Error, error_reply(Error, Reply)),
      json_write_dict(user_output, Reply, [width(0)]), nl,
      flush_output(user_output),
      prompt_loop
    ).

process_line(Line, Reply) :-
    atom_json_dict(Line, Request, []),
    get_dict(sentences, Request, Sentences),
    read_sentences(Sentences, 0, SentenceRows0, ScopedProgram),
    contextualize_questions(Sentences, SentenceRows0, SentenceRows, Candidates),
    select_program(Candidates, ScopedProgram, Program0, ProgramBasis),
    merge_discrete_kinds(Program0, Program),
    completion_receipt(Program, Completion),
    maplist(term_text, Program, ProgramStrings),
    Reply = _{ok:true, sentences:SentenceRows,
              program:ProgramStrings, program_basis:ProgramBasis,
              completion:Completion}.

error_reply(Error, _{ok:false, error:Text}) :-
    message_to_string(Error, Text).

read_sentences([], _Index, [], []).
read_sentences([Text|Texts], Index, [Row|Rows], Program) :-
    sentence_form(Text, Form),
    sentence_force_tag(Text, Force, ForceFrame),
    arbitration_result(Text, Form, Row0, Facts),
    put_dict(_{force:Force, force_frame:ForceFrame}, Row0, Row),
    namespace_facts(Index, Facts, ScopedFacts),
    Next is Index + 1,
    read_sentences(Texts, Next, Rows, Rest),
    append(ScopedFacts, Rest, Program).

% Re-run the incumbent over a bounded suffix of its accepted quantitative
% sentences plus each question.  This preserves the reader's own state and
% comparison rules while leaving refused pedagogy sentences in their original
% ledger rows.  A question is context-recovered only when the combined text
% yields an ask and a five-form program.
contextualize_questions(Sentences, Rows0, Rows, Candidates) :-
    contextualize_questions(Sentences, Rows0, 0, [], Rows, Candidates).

contextualize_questions([], [], _Index, _Prior, [], []).
contextualize_questions([Text|Texts], [Row0|Rows0], Index, Prior0,
                        [Row|Rows], Candidates) :-
    ( get_dict(sentence_form, Row0, question),
      best_context_candidate(Prior0, Text, Index, Candidate)
    -> context_question_row(Row0, Candidate, Row),
       Candidates = [Candidate|RestCandidates]
    ;  Row = Row0, Candidates = RestCandidates
    ),
    ( ( get_dict(reader, Row0, incumbent)
      ; contextual_support_sentence(Text)
      )
    -> append(Prior0, [indexed_text(Index,Text)], Prior1),
       last_n(6, Prior1, Prior)
    ;  Prior = Prior0
    ),
    Next is Index + 1,
    contextualize_questions(Texts, Rows0, Next, Prior, Rows, RestCandidates).

% A pronoun transfer is deliberately refused sentence-locally because it has
% no owner or carried kind there.  Retain only that bounded syntax as possible
% context so the combined incumbent reading can resolve it against a preceding
% named state.  Other refused sentences do not enter contextual programs.
contextual_support_sentence(Text) :-
    string_lower(Text, Lower), tokenize_atom(Lower, Tokens),
    phrase(word_problem_reader_pilot:problem_event(
               transfer(_Subject,_Action,_Number,_Kind,_Recipient,_Span)),
           Tokens).

best_context_candidate(Prior, Question, Index,
                       candidate(Index,Program,BaseIndices,DerivesAll)) :-
    append(_Dropped, Suffix, Prior),
    findall(Text, member(indexed_text(_,Text), Suffix), BaseTexts),
    append(BaseTexts, [Question], ProgramTexts),
    atomics_to_string(ProgramTexts, " ", Combined),
    word_problem_reader_pilot:word_problem_facts(Combined, Program),
    member(asks(result,_), Program), program_has_support(Program),
    findall(BaseIndex, member(indexed_text(BaseIndex,_), Suffix), BaseIndices),
    ( program_derives_all_asks(Program) -> DerivesAll = true
    ; DerivesAll = false
    ), !.

context_question_row(Row0, candidate(_Index,Program,BaseIndices,_), Row) :-
    question_program_facts(Program, QuestionFacts),
    maplist(term_text, QuestionFacts, FactStrings),
    Context = _{base_sentence_indices:BaseIndices,
                rule:contextual_incumbent_question},
    ( get_dict(parsed, Row0, true)
    -> put_dict(_{contextual_recovery:Context}, Row0, Row)
    ; put_dict(_{parsed:true,reader:incumbent_context,
                 facts:FactStrings,fact_spans:[],
                 rewrite_rules:["contextual_incumbent_question"],
                 contextual_recovery:Context}, Row0, Row)
    ).

question_program_facts(Program, Facts) :-
    findall(Fact,
            ( member(asks(result,Name), Program),
              ( Fact = asks(result,Name)
              ; member(Fact, Program), Fact = quantity(Name,_,_)
              ; member(Fact, Program), Fact = relation(Name,_,_)
              )
            ), Facts0),
    sort(Facts0, Facts).

select_program(Candidates, _Fallback, Program,
               _{kind:contextual,question_index:Index,
                 base_sentence_indices:BaseIndices}) :-
    include(deriving_candidate, Candidates, Deriving), Deriving \== [], !,
    last(Deriving, candidate(Index,Program,BaseIndices,_)).
select_program(Candidates, _Fallback, Program,
               _{kind:contextual,question_index:Index,
                 base_sentence_indices:BaseIndices}) :-
    Candidates \== [], !,
    last(Candidates, candidate(Index,Program,BaseIndices,_)).
select_program([], Fallback, Fallback,
               _{kind:sentence_scoped,question_index:null,
                 base_sentence_indices:[]}).

deriving_candidate(candidate(_,_,_,true)).

program_derives_all_asks(Program) :-
    word_problem_reader_pilot:seed(Program),
    word_problem_reader_pilot:saturate(Program),
    forall(member(asks(result,Name), Program),
           word_problem_reader_pilot:derived(Name,_,_)).

program_has_support(Program) :- member(quantity(_,_,_), Program), !.
program_has_support(Program) :- member(relation(_,Recipe,_), Program),
    supported_recipe(Recipe), !.
program_has_support(Program) :- member(conversion(_,_,_,_), Program).

supported_recipe(convert(_,_)).
supported_recipe(scale(_,_)).
supported_recipe(sum(_)).
supported_recipe(difference(_,_)).
supported_recipe(quotient(_,_)).

last_n(Count, List, Tail) :-
    length(List, Length), Drop is max(0, Length - Count),
    length(Prefix, Drop), append(Prefix, Tail, List).

arbitration_result(Text, Form, Row, Facts) :-
    ( word_problem_reader_pilot:word_problem_facts(Text, IncumbentFacts)
    -> maplist(term_text, IncumbentFacts, FactStrings),
       Row = _{parsed:true, reader:incumbent, sentence_form:Form,
               facts:FactStrings, fact_spans:[], rewrite_rules:[], refusals:_{}},
       Facts = IncumbentFacts
    ; incumbent_entry_token(Text, EntryToken),
      ape_reader_pilot:ape_reader_result(Text, ApeResult),
      ape_result_row(ApeResult, EntryToken, Form, Row, Facts)
    ).

ape_result_row(parsed(Facts, FactSpans, Rules), EntryToken, Form, Row, Facts) :-
    maplist(term_text, Facts, FactStrings),
    findall(_{fact_index:Index,start:Start,end:End,text:Text},
            member(fact_span(Index,Start,End,Text), FactSpans), SpanRows),
    maplist(term_text, Rules, RuleStrings),
    Row = _{parsed:true, reader:ape, sentence_form:Form,
            facts:FactStrings, fact_spans:SpanRows, rewrite_rules:RuleStrings,
            refusals:_{incumbent:_{token:EntryToken,
                token_basis:sentence_entry_no_failure_api}}}.
ape_result_row(refusal(Token,span(Start,End,Surface),Reason,Rules),
               EntryToken, Form, Row, []) :-
    term_text(Reason, ReasonString),
    maplist(term_text, Rules, RuleStrings),
    Row = _{parsed:false, reader:both_refused, sentence_form:Form,
            facts:[], fact_spans:[], rewrite_rules:RuleStrings,
            refusals:_{incumbent:_{token:EntryToken,
                token_basis:sentence_entry_no_failure_api},
                ape:_{token:Token,start:Start,end:End,text:Surface,
                      reason:ReasonString}}}.

incumbent_entry_token(Text, TokenString) :-
    string_lower(Text, Lower),
    tokenize_atom(Lower, Tokens),
    ( Tokens = [Entry|_] -> term_text(Entry, TokenString) ; TokenString = "" ).

sentence_form(Text, question) :-
    normalize_space(string(Trimmed), Text),
    sub_string(Trimmed, _, 1, 0, "?"), !.
sentence_form(Text, directive) :-
    string_lower(Text, Lower),
    tokenize_atom(Lower, Tokens0),
    drop_leading_markers(Tokens0, Tokens),
    Tokens = [Head|_], atom(Head),
    once(english_morphology:em_verb_base(Head, Head, _)), !.
sentence_form(_Text, declarative).

sentence_force_tag(Text, Force, FrameId) :-
    pedagogy_force_pilot:sentence_force(Text, Force, FrameId), !.
sentence_force_tag(_Text, unmarked, null).

drop_leading_markers([Token,'.'|Tokens], Rest) :-
    number(Token), !, drop_leading_markers(Tokens, Rest).
drop_leading_markers([Token|Tokens], Rest) :-
    memberchk(Token, ['\u2022','\u25e6','-']), !, drop_leading_markers(Tokens, Rest).
drop_leading_markers(Tokens, Tokens).

term_text(Term, Text) :-
    term_string(Term, Text, [quoted(true)]).

% A reader invocation is sentence-local.  Its referent names therefore need a
% sentence scope before several readings can share one saturation program;
% otherwise APE's book_1 in two different sentences would create a false join.
namespace_facts(_Index, [], []).
namespace_facts(Index, [Fact|Facts], [Scoped|ScopedFacts]) :-
    namespace_fact(Index, Fact, Scoped),
    namespace_facts(Index, Facts, ScopedFacts).

namespace_fact(Index, quantity(Name,Value,Kind), quantity(Scoped,Value,Kind)) :- !,
    scoped_name(Index, Name, Scoped).
namespace_fact(Index, asks(result,Name), asks(result,Scoped)) :- !,
    scoped_name(Index, Name, Scoped).
namespace_fact(Index, relation(Name,Recipe,Span), relation(Scoped,ScopedRecipe,Span)) :- !,
    scoped_name(Index, Name, Scoped),
    namespace_recipe(Index, Recipe, ScopedRecipe).
namespace_fact(_Index, Fact, Fact).

namespace_recipe(Index, convert(Source,Kind), convert(Scoped,Kind)) :- !,
    scoped_name(Index, Source, Scoped).
namespace_recipe(Index, scale(Scale,Source), scale(ScopedScale,ScopedSource)) :- !,
    scoped_name(Index, Scale, ScopedScale),
    scoped_name(Index, Source, ScopedSource).
namespace_recipe(Index, sum(Parts), sum(ScopedParts)) :- !,
    maplist(scoped_name(Index), Parts, ScopedParts).
namespace_recipe(Index, difference(Minuend,Subtrahend),
                 difference(ScopedMinuend,ScopedSubtrahend)) :- !,
    scoped_name(Index, Minuend, ScopedMinuend),
    scoped_name(Index, Subtrahend, ScopedSubtrahend).
namespace_recipe(Index, quotient(Dividend,Divisor),
                 quotient(ScopedDividend,ScopedDivisor)) :- !,
    scoped_name(Index, Dividend, ScopedDividend),
    scoped_name(Index, Divisor, ScopedDivisor).
namespace_recipe(_Index, Recipe, Recipe).

scoped_name(Index, Name, Scoped) :-
    format(atom(Scoped), 's~d_~w', [Index,Name]).

merge_discrete_kinds(Program0, Program) :-
    findall(Kind,
            ( member(discrete_kinds(Kinds), Program0), member(Kind, Kinds) ),
            Kinds0),
    sort(Kinds0, Kinds),
    exclude(is_discrete_kinds, Program0, Facts),
    ( Kinds == [] -> Program = Facts ; append(Facts, [discrete_kinds(Kinds)], Program) ).

is_discrete_kinds(discrete_kinds(_)).

completion_receipt([], _{status:not_parsed,reason:no_parsed_sentences,
                         asks:[],ask_targets:[],answers:[]}) :- !.
completion_receipt(Program, Receipt) :-
    findall(Name, member(asks(result,Name), Program), Asked0),
    sort(Asked0, Asked),
    ask_targets(Asked, Program, AskTargets),
    ( Asked == []
    -> Receipt = _{status:parsed_not_completed,reason:no_ask,
                   asks:[],ask_targets:[],answers:[]}
    ; \+ program_has_support(Program)
    -> Receipt = _{status:parsed_not_completed,reason:no_program_facts,
                   asks:Asked,ask_targets:AskTargets,answers:[]}
    ; program_incoherences(Program, Incoherences), Incoherences \== []
    -> Receipt = _{status:refused_incoherent_program,
                   reason:inconsistent_referent_bindings,
                   asks:Asked,ask_targets:AskTargets,answers:[],
                   incoherences:Incoherences}
    ; identity_target_names(AskTargets, IdentityNames), IdentityNames \== []
    -> Receipt = _{status:parsed_not_completable,reason:identity_demand,
                   asks:Asked,ask_targets:AskTargets,answers:[],
                   identity_asks:IdentityNames}
    ; word_problem_reader_pilot:seed(Program),
      word_problem_reader_pilot:saturate(Program),
      answer_rows(Asked, Answers),
      findall(Name, (member(Name,Asked), \+ answer_for(Name,Answers)), Missing),
      ( Missing \== []
      -> maplist(term_text, Missing, MissingStrings),
         Receipt = _{status:parsed_not_completed,reason:underdetermined,
                     asks:Asked,ask_targets:AskTargets,answers:Answers,
                     missing_asks:MissingStrings}
      ; conflicting_answer(Answers, Conflicting)
      -> term_text(Conflicting, ConflictString),
         Receipt = _{status:parsed_not_completed,reason:contradictory,
                     asks:Asked,ask_targets:AskTargets,answers:Answers,
                     conflicting_ask:ConflictString}
      ; non_integer_answer(Program, Answers, BadName, BadValue)
      -> term_text(BadName, BadNameString), term_text(BadValue, BadValueString),
         Receipt = _{status:parsed_not_completed,reason:non_integer_demand,
                     asks:Asked,ask_targets:AskTargets,answers:Answers,
                     non_integer:_{referent:BadNameString,value:BadValueString}}
      ; Receipt = _{status:completed,reason:derived_all_asks,
                    asks:Asked,ask_targets:AskTargets,answers:Answers}
      )
    ).

program_incoherences(Program, Rows) :-
    findall(conflict(Name,KindA,ValueA,KindB,ValueB),
            inconsistent_binding(Program, Name, KindA, ValueA, KindB, ValueB),
            Conflicts0),
    sort(Conflicts0, Conflicts),
    maplist(conflict_dict, Conflicts, Rows).

inconsistent_binding(Program, Name, KindA, ValueA, KindB, ValueB) :-
    member(quantity(Name,ValueA,KindA), Program), number(ValueA),
    member(quantity(Name,ValueB,KindB), Program), number(ValueB),
    quantity_binding_key(KindA,ValueA, First),
    quantity_binding_key(KindB,ValueB, Second), First @< Second,
    ( KindA \== KindB
    ; \+ word_problem_reader_pilot:close_enough(ValueA, ValueB)
    ).

quantity_binding_key(Kind, Value, Kind-Value).

conflict_dict(conflict(Name,KindA,ValueA,KindB,ValueB),
              _{referent:NameText,
                first:_{kind:KindAText,value:ValueAText},
                second:_{kind:KindBText,value:ValueBText}}) :-
    maplist(term_text,
            [Name,KindA,ValueA,KindB,ValueB],
            [NameText,KindAText,ValueAText,KindBText,ValueBText]).

ask_targets([], _Program, []).
ask_targets([Name|Names], Program, [Target|Targets]) :-
    ask_target(Name, Program, Target),
    ask_targets(Names, Program, Targets).

ask_target(Name, Program,
           _{referent:NameString,target_kind:identity,
             referent_class:KindString}) :-
    member(relation(Name,identity_demand(Kind),_), Program), !,
    term_text(Name, NameString), term_text(Kind, KindString).
ask_target(Name, Program,
           _{referent:NameString,target_kind:numeric,
             referent_class:KindString}) :-
    member(quantity(Name,_,Kind), Program), !,
    term_text(Name, NameString), term_text(Kind, KindString).
ask_target(Name, _Program,
           _{referent:NameString,target_kind:unknown,
             referent_class:unknown}) :-
    term_text(Name, NameString).

identity_target_names(Targets, Names) :-
    findall(Name,
            ( member(Target, Targets),
              get_dict(target_kind, Target, identity),
              get_dict(referent, Target, Name) ),
            Names).

answer_rows(Asked, Answers) :-
    findall(answer(Name,Value,How),
            ( member(Name, Asked),
              word_problem_reader_pilot:derived(Name,Value,How) ),
            Answers0),
    sort(Answers0, Unique),
    maplist(answer_dict, Unique, Answers).

answer_dict(answer(Name,Value,How),
            _{referent:NameString,value:ValueString,derivation:HowString}) :-
    term_text(Name, NameString),
    term_text(Value, ValueString),
    term_text(How, HowString).

answer_for(Name, Answers) :-
    term_text(Name, NameString),
    member(Answer, Answers), get_dict(referent, Answer, NameString), !.

conflicting_answer(Answers, Name) :-
    member(First, Answers), get_dict(referent, First, Name),
    findall(Value,
            ( member(Answer,Answers), get_dict(referent,Answer,Name),
              get_dict(value,Answer,Value) ), Values0),
    sort(Values0, Values), length(Values, Count), Count > 1, !.

non_integer_answer(Program, Answers, Name, Value) :-
    member(Answer, Answers),
    get_dict(referent, Answer, NameString), get_dict(value, Answer, ValueString),
    term_string(Name, NameString), term_string(Value, ValueString),
    member(quantity(Name,_,Kind), Program),
    member(discrete_kinds(Kinds), Program), memberchk(Kind, Kinds),
    Rounded is round(Value),
    \+ word_problem_reader_pilot:close_enough(Value, Rounded), !.
