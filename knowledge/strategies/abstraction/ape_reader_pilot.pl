:- encoding(utf8).
/** <module> APE second-reader pilot
 *
 * This quarantined reader runs only after the incumbent reader refuses.  It
 * applies a cited, deterministic rewrite, parses with the vendored LGPL APE
 * runtime and the generated Webster bridge, then maps the complete DRS to the
 * five-form sidekick schema.  A parse or mapping failure returns one refusal;
 * no accepted prefix is emitted.
 *
 * Check from the repository root:
 * `swipl -q -l paths.pl -l knowledge/strategies/abstraction/ape_reader_pilot.pl -g ape_reader_pilot:check_ape_reader_pilot -t halt`
 */

:- module(ape_reader_pilot,
          [ ape_reader_facts/2,
            ape_reader_result/2,
            ape_rewrite/4,
            ape_map_drs/4,
            ape_reader_pilot_summary/1,
            check_ape_reader_pilot/0
          ]).

:- op(500, xfx, =>).
:- op(500, xfx, v).

:- use_module(library(lists), [append/2, memberchk/2, reverse/2]).
:- use_module(library(apply), [exclude/3, include/3, maplist/2]).
:- use_module(library(readutil), [read_file_to_string/3]).
:- use_module('../../../third_party/ape/prolog/parser/ace_to_drs.pl', []).
:- use_module('word_problem_reader_pilot.pl', [exact_value_question_program/2]).

:- dynamic ape_user_lexicon_loaded/0.
:- dynamic pilot_directory/1.
:- discontiguous question_rewrite_receipt/5.
:- discontiguous question_rewrite_negative/4.
:- prolog_load_context(directory, Here), assertz(pilot_directory(Here)).

ape_reader_pilot_summary(
    summary(role(orphan_second_reader),
            order(after_incumbent_refusal),
            runtime(third_party_ape_lgpl_3),
            output_contract(five_form_sidekick_schema),
            positive_receipts(34),
            negative_receipts(11),
            mapper_constructors([object,predicate,relation,property,
                                 modifier_adv,modifier_pp,has_part,query,formula]),
            mapper_operators([command,question,implies,negation,disjunction]))).

%! ape_reader_facts(+Text, -Facts) is semidet.
%
%  Compatibility surface for arbitration.  Failure means refusal; callers
%  needing the failure token use ape_reader_result/2.
ape_reader_facts(Text, Facts) :-
    ape_reader_result(Text, parsed(Facts, _FactSpans, _RewriteRules)).

%! ape_reader_result(+Text, -Result) is det.
%
%  Result is parsed(Facts, FactSpans, RewriteRules) or
%  refusal(Token, span(Start,End,Text), Reason, RewriteRules).
ape_reader_result(Text0, Result) :-
    ensure_ape_user_lexicon,
    text_string(Text0, Text),
    ( source_text_refusal(Text, TokenRow0, SourceReason)
    -> token_row_refusal(TokenRow0, SourceReason, [], Result)
    ; exact_value_question_program(Text, ExactFacts)
    -> string_length(Text, ExactEnd),
       full_text_spans(ExactFacts, Text, ExactEnd, 1, ExactSpans),
       Result = parsed(ExactFacts, ExactSpans,
                       [exact_arithmetic_question_program])
    ; ( source_tokens(Text, SourceTokens),
      split_sentences(SourceTokens, SourceSentences),
      SourceSentences \== []
    -> ( preflight_refusal(SourceSentences, TokenRow, PreflightReason)
       -> token_row_refusal(TokenRow, PreflightReason, [], Result)
       ;  rewrite_sentences(SourceSentences, RewrittenSentences, RewriteRules),
          render_rewritten(RewrittenSentences, Rewritten, TokenOrigins),
          Origins = [source_text(Text)|TokenOrigins],
          ace_to_drs:acetext_to_drs(Rewritten, on, off, _Sentences, _Trees,
                                    Drs, Messages, _Time),
          ( first_ape_error(Messages, Location, ErrorReason)
          -> location_refusal(Location, Origins, ErrorReason, RewriteRules, Result)
          ; Drs == drs([], [])
          -> Result = refusal('', span(0,0,""), empty_drs, RewriteRules)
          ; catch(ape_map_drs(Drs, Origins, Facts0, FactSpans0),
                  map_refusal(MapLocation, MapReason),
                  location_refusal(MapLocation, Origins, MapReason,
                                   RewriteRules, MappedResult)),
            ( var(MappedResult)
            -> enrich_question_program(Text, Facts0, FactSpans0, RewriteRules,
                                       Facts, FactSpans, FinalRules),
               MappedResult = parsed(Facts, FactSpans, FinalRules)
            ;  true
            ),
            Result = MappedResult
          )
       )
      ; Result = refusal('', span(0,0,""), tokenization_failed, [])
      )
    ), !.

ensure_ape_user_lexicon :-
    ape_user_lexicon_loaded, !.
ensure_ape_user_lexicon :-
    with_mutex(ape_user_lexicon,
               ( ape_user_lexicon_loaded
               -> true
               ;  pilot_directory(Here),
                  directory_file_path(
                      Here,
                      '../../../hermes/app/runtime/experiments/language/ape_user_lexicon.pl',
                      Lexicon0),
                  absolute_file_name(Lexicon0, Lexicon,
                                     [access(read), file_errors(fail)]),
                  ulex:load_files(Lexicon, [silent(true)]),
                  assertz(ape_user_lexicon_loaded)
               )).

text_string(Text, Text) :- string(Text), !.
text_string(Text, String) :- atom(Text), !, atom_string(Text, String).
text_string(Text, String) :- string_codes(String, Text), !.
text_string(Text, String) :- string_chars(String, Text).

% ---------------------------------------------------------------------------
% Source token spans and deterministic rewrite

source_tokens(Text, Rows) :-
    tokenizer:tokenize(Text, Tokens),
    token_spans(Tokens, Text, 0, Rows).

token_spans([], _Text, _Cursor, []).
token_spans([Token|Tokens], Text, Cursor,
            [tok(Token, Start, End, Surface)|Rows]) :-
    token_surface(Token, TokenSurface),
    string_length(TokenSurface, Length),
    next_surface(Text, Cursor, TokenSurface, Start),
    End is Start + Length,
    sub_string(Text, Start, Length, _, Surface),
    token_spans(Tokens, Text, End, Rows).

token_surface(Token, Surface) :-
    string(Token), !, Surface = Token.
token_surface(Token, Surface) :-
    atom(Token), !, atom_string(Token, Surface).
token_surface(Token, Surface) :-
    number_string(Token, Surface).

next_surface(Text, Cursor, Surface, Start) :-
    sub_string(Text, Start, _, _, Surface),
    Start >= Cursor, !.
next_surface(Text, Cursor, Surface, Start) :-
    string_lower(Text, LowerText), string_lower(Surface, LowerSurface),
    sub_string(LowerText, Start, _, _, LowerSurface),
    Start >= Cursor, !.

split_sentences(Rows, Sentences) :-
    split_sentences(Rows, [], [], Reversed),
    reverse(Reversed, Sentences).

split_sentences([], [], Sentences, Sentences).
split_sentences([], Current0, Sentences0, [Current|Sentences0]) :-
    reverse(Current0, Current).
split_sentences([Row|Rows], Current0, Sentences0, Sentences) :-
    Row = tok(Token, _, _, _),
    ( terminal_token(Token)
    -> reverse([Row|Current0], Current),
       split_sentences(Rows, [], [Current|Sentences0], Sentences)
    ;  split_sentences(Rows, [Row|Current0], Sentences0, Sentences)
    ).

terminal_token('.').
terminal_token('?').
terminal_token('!').

%! ape_rewrite(+Text, -Rewritten, -Origins, -Rules) is semidet.
ape_rewrite(Text0, Rewritten, Origins, Rules) :-
    ensure_ape_user_lexicon,
    text_string(Text0, Text),
    \+ source_text_refusal(Text, _, _),
    source_tokens(Text, Rows),
    split_sentences(Rows, Sentences),
    Sentences \== [],
    \+ preflight_refusal(Sentences, _, _),
    rewrite_sentences(Sentences, RewrittenSentences, Rules),
    render_rewritten(RewrittenSentences, Rewritten, TokenOrigins),
    Origins = [source_text(Text)|TokenOrigins].

rewrite_sentences([], [], []).
rewrite_sentences([Sentence|Sentences], Rewritten, Rules) :-
    rewrite_sentence(Sentence, Here, HereRules),
    rewrite_sentences(Sentences, Rest, RestRules),
    append(Here, Rest, Rewritten),
    append(HereRules, RestRules, Rules0),
    list_to_set_stable(Rules0, Rules).

rewrite_sentence(Sentence, Rewritten, [relative_existential_measurement]) :-
    relative_measurement_rewrite(Sentence, Rewritten), !.
rewrite_sentence(Sentence, [Rewritten], [question_should_modality]) :-
    question_should_modality_rewrite(Sentence, Rewritten), !.
rewrite_sentence(Sentence, [Rewritten], [question_total_adjunct]) :-
    question_total_adjunct_rewrite(Sentence, Rewritten), !.
rewrite_sentence(Sentence, [Rewritten], [question_arithmetic_glyph]) :-
    question_arithmetic_glyph_rewrite(Sentence, Rewritten), !.
rewrite_sentence(Sentence, [Rewritten], [labeled_entity_subject]) :-
    labeled_entity_rewrite(Sentence, Rewritten), !.
rewrite_sentence(Sentence, [Rewritten], [addressee_insertion]) :-
    imperative_rewrite(Sentence, Rewritten), !.
rewrite_sentence(Sentence, [Sentence], []).

relative_measurement_rewrite(
    [There,Are,Number,Plural,That,Are2,Measure,Unit,Adjective,End],
    [[There,Are,Number,Plural,End],
     [Every,Singular,Has,Measure,Unit,End],
     [Every2,Singular2,Is,Adjective,End]]) :-
    row_word(There, there), row_word(Are, are), row_word(That, that),
    row_word(Are2, are), terminal_row(End), numeric_row(Measure),
    plural_singular_row(Plural, SingularAtom),
    replacement_row(That, 'Every', Every),
    replacement_row(Plural, SingularAtom, Singular),
    replacement_row(Are2, has, Has),
    replacement_row(That, 'Every', Every2),
    replacement_row(Plural, SingularAtom, Singular2),
    replacement_row(Are2, is, Is),
    adjective_row(Adjective), noun_row(Unit).

question_should_modality_rewrite(Sentence, Rewritten) :-
    Sentence = [How,Many|_], row_word(How, how), row_word(Many, many),
    append(Prefix, [Should,Go|Suffix], Sentence),
    row_word(Should, should), row_word(Go, go),
    append(Prefix, [Go|Suffix], Rewritten).

question_total_adjunct_rewrite(Sentence, Rewritten) :-
    Sentence = [How,Many|_], row_word(How, how), row_word(Many, many),
    ( append(Prefix, [Altogether,End], Sentence),
      row_word(Altogether, altogether), terminal_row(End),
      append(Prefix, [End], Rewritten)
    ; append(Prefix, [In,All,End], Sentence),
      row_word(In, in), row_word(All, all), terminal_row(End),
      append(Prefix, [End], Rewritten)
    ).

question_arithmetic_glyph_rewrite(Sentence, Rewritten) :-
    Sentence = [What,Is,The,Value,Of|_],
    maplist(row_atom_lower, [What,Is,The,Value,Of],
            [what,is,the,value,of]),
    append(Prefix, [Glyph|Suffix], Sentence),
    ( row_word(Glyph, '×'), Replacement = '*'
    ; row_word(Glyph, '÷'), Replacement = '/'
    ),
    replacement_row(Glyph, Replacement, Replaced),
    append(Prefix, [Replaced|Suffix], Rewritten).

% APE reads a sentence-initial common-noun label (for example, a vehicle or
% store followed by one capital label) as an imperative fragment.  Preserve
% the general noun-plus-label construction as one proper-name subject.  This
% is a reader rewrite, not an audit-normalizer rule.
labeled_entity_rewrite([Kind,Label,Verb|Rest], [Named,Verb|Rest]) :-
    noun_row(Kind), entity_label_row(Label), finite_verb_row(Verb),
    Kind = tok(KindToken, Start, _, KindSurface),
    Label = tok(LabelToken, _, End, LabelSurface),
    atomic_list_concat([KindToken,LabelToken], '_', NamedToken),
    string_concat(KindSurface, " ", Prefix),
    string_concat(Prefix, LabelSurface, Surface),
    Named = tok(NamedToken, Start, End, Surface).

entity_label_row(Row) :-
    row_atom_lower(Row, Lower), atom_length(Lower, 1),
    Row = tok(_Token, _, _, Surface), string_upper(Surface, Surface),
    string_codes(Surface, [Code]), char_type(Code, alpha).

imperative_rewrite([Verb,Next|Rest], [A,Student,Finite,Next|Rest]) :-
    Verb = tok(Original, Start, End, Surface),
    \+ ulex:pn_sg(Original, _, _),
    \+ finite_verb_row(Next),
    row_atom_lower(Verb, Base),
    once((ulex:tv_finsg(FiniteAtom, Base) ;
          ulex:iv_finsg(FiniteAtom, Base) ;
          ulex:dv_finsg(FiniteAtom, Base, _))),
    A = tok('A', Start, Start, ""),
    Student = tok(student, Start, Start, ""),
    Finite = tok(FiniteAtom, Start, End, Surface).

finite_verb_row(Row) :-
    row_atom_lower(Row, Verb),
    ( ulex:iv_finsg(Verb, _) ; ulex:tv_finsg(Verb, _) ;
      ulex:dv_finsg(Verb, _, _) ), !.

row_word(Row, Word) :- row_atom_lower(Row, Word).
memberchk_word(Row, Words) :- row_atom_lower(Row, Word), memberchk(Word, Words).
row_atom_lower(tok(Token, _, _, _), Lower) :-
    token_surface(Token, Surface), string_lower(Surface, LowerString),
    atom_string(Lower, LowerString).
numeric_row(tok(Token, _, _, _)) :- number(Token), !.
numeric_row(Row) :- row_atom_lower(Row, Word), number_word(Word).
noun_row(Row) :- row_atom_lower(Row, Word),
    ( ulex:noun_sg(Word, _, _) ; ulex:noun_pl(Word, _, _) ), !.
adjective_row(Row) :- row_atom_lower(Row, Word), ulex:adj_itr(Word, _), !.
plural_singular_row(Row, Singular) :-
    row_atom_lower(Row, Plural), once(ulex:noun_pl(Plural, Singular, _)).
terminal_row(tok(Token, _, _, _)) :- terminal_token(Token).
replacement_row(tok(_, Start, End, Surface), Token,
                tok(Token, Start, End, Surface)).

number_word(one). number_word(two). number_word(three). number_word(four).
number_word(five). number_word(six). number_word(seven). number_word(eight).
number_word(nine). number_word(ten). number_word(eleven). number_word(twelve).

render_rewritten(Sentences, Text, Origins) :-
    render_rewritten(Sentences, 1, TextParts, Origins),
    atomic_list_concat(TextParts, ' ', TextAtom), atom_string(TextAtom, Text).

render_rewritten([], _Sentence, [], []).
render_rewritten([Tokens|Sentences], Sentence, [Text|Texts], Origins) :-
    render_sentence(Tokens, Sentence, 1, TokenTexts, HereOrigins),
    atomic_list_concat(TokenTexts, ' ', Text),
    Next is Sentence + 1,
    render_rewritten(Sentences, Next, Texts, RestOrigins),
    append(HereOrigins, RestOrigins, Origins).

render_sentence([], _Sentence, _Token, [], []).
render_sentence([tok(Value, Start, End, Surface)|Rows], Sentence, Token,
                [Text|Texts], [origin(Sentence,Token,Start,End,Surface)|Origins]) :-
    token_surface(Value, String), atom_string(Text, String),
    Next is Token + 1,
    render_sentence(Rows, Sentence, Next, Texts, Origins).

enrich_question_program(Text, _Facts0, _Spans0, Rules0,
                        Facts, Spans, Rules) :-
    exact_value_question_program(Text, Facts), !,
    string_length(Text, End),
    full_text_spans(Facts, Text, End, 1, Spans),
    append(Rules0, [exact_arithmetic_question_program], Rules1),
    list_to_set_stable(Rules1, Rules).
enrich_question_program(_Text, Facts, Spans, Rules, Facts, Spans, Rules).

full_text_spans([], _Text, _End, _Index, []).
full_text_spans([_|Facts], Text, End, Index,
                [fact_span(Index,0,End,Text)|Spans]) :-
    Next is Index + 1,
    full_text_spans(Facts, Text, End, Next, Spans).

% Conservative boundary checks whose intended reading does not fit the five
% forms or whose syntax is deliberately outside this pilot.
preflight_refusal(Sentences, Token, Reason) :-
    member(Sentence, Sentences),
    sentence_preflight_refusal(Sentence, Token, Reason), !.

sentence_preflight_refusal([First,Of|_], First, bare_partitive) :-
    ( numeric_row(First) ; row_atom_lower(First, Word), number_word(Word) ),
    row_word(Of, of), !.
sentence_preflight_refusal(Sentence, Comparative, nominal_comparative) :-
    append(_, [Before,Comparative,Than|_], Sentence),
    numeric_row(Before), memberchk_word(Comparative, [more,fewer,less]),
    row_word(Than, than), !.
sentence_preflight_refusal(Sentence, Second, stacked_adjective) :-
    append(_, [Determiner,First,Second,Noun|_], Sentence),
    memberchk_word(Determiner, [a,an,the]), adjective_row(First),
    adjective_row(Second), noun_row(Noun), !.
sentence_preflight_refusal([First,Second|_], First, bare_plural) :-
    row_atom_lower(First, Plural), ulex:noun_pl(Plural, _, _),
    row_atom_lower(Second, Verb),
    ( ulex:iv_infpl(Verb, _) ; ulex:tv_infpl(Verb, _) ;
      ulex:dv_infpl(Verb, _, _) ), !.
sentence_preflight_refusal(Sentence, Token, source_artifact) :-
    member(Token, Sentence),
    Token = tok(_, _, _, Surface), sub_string(Surface, _, _, _, "•"), !.

source_text_refusal(Text, tok('•',Start,End,"•"), source_artifact) :-
    sub_string(Text, Start, 1, _, "•"), End is Start + 1, !.

first_ape_error(Messages, Location, Reason) :-
    member(message(error, Kind, Location, _Context, Message), Messages), !,
    Reason = ape_error(Kind, Message).

token_row_refusal(tok(Token, Start, End, Surface), Reason, Rules,
                  refusal(TokenString, span(Start,End,Surface), Reason, Rules)) :-
    token_surface(Token, TokenString).

location_refusal(Location0, Origins, Reason, Rules,
                 refusal(Token, span(Start,End,Surface), Reason, Rules)) :-
    normalize_location(Location0, Sentence, TokenIndex),
    nearest_origin(Origins, Sentence, TokenIndex,
                   origin(_,_,Start,End,Surface)), !,
    ( Surface == "" -> Token = "" ; Token = Surface ).
location_refusal(_Location, _Origins, Reason, Rules,
                 refusal('', span(0,0,""), Reason, Rules)).

normalize_location(Sentence-Token, Sentence, Token) :-
    integer(Sentence), integer(Token), !.
normalize_location(Sentence/Token, Sentence, Token) :-
    integer(Sentence), integer(Token), !.
normalize_location(_, 1, 1).

nearest_origin(Origins, Sentence, Token, Origin) :-
    member(Origin, Origins), Origin = origin(Sentence,Token,_,_,_), !.
nearest_origin(Origins, Sentence, Token, Origin) :-
    Token > 1, Prior is Token - 1,
    nearest_origin(Origins, Sentence, Prior, Origin).

% ---------------------------------------------------------------------------
% Complete DRS traversal and five-form mapping

%! ape_map_drs(+Drs, +Origins, -Facts, -FactSpans) is det.
%
%  Throws map_refusal(Location,Reason) if any condition cannot be represented.
ape_map_drs(Drs, Origins, Facts, FactSpans) :-
    collect_objects(Drs, Objects),
    build_ref_environment(Objects, 1, [], ObjectEnvironment),
    collect_events(Drs, Events),
    build_event_environment(Events, ObjectEnvironment, EventEnvironment),
    collect_aux_refs(Drs, AuxRefs),
    build_aux_environment(AuxRefs, EventEnvironment, Environment),
    map_drs_term(Drs, Drs, Environment, Origins, Emissions0, _Coverage),
    object_kinds(Objects, Kinds),
    ( Kinds == [] -> Emissions1 = Emissions0
    ; append(Emissions0, [emission(discrete_kinds(Kinds), none)], Emissions1)
    ),
    dedupe_emissions(Emissions1, Emissions),
    emissions_output(Emissions, Origins, 1, Facts, FactSpans),
    maplist(five_form_fact, Facts).

collect_objects(Term, Objects) :-
    collect_objects(Term, [], Reversed), reverse(Reversed, Objects).

collect_objects(drs(_, Conditions), In, Out) :- !,
    collect_objects_list(Conditions, In, Out).
collect_objects(command(Drs), In, Out) :- !, collect_objects(Drs, In, Out).
collect_objects(question(Drs), In, Out) :- !, collect_objects(Drs, In, Out).
collect_objects(-(Drs), In, Out) :- !, collect_objects(Drs, In, Out).
collect_objects(Left => Right, In, Out) :- !,
    collect_objects(Left, In, Mid), collect_objects(Right, Mid, Out).
collect_objects(Left v Right, In, Out) :- !,
    collect_objects(Left, In, Mid), collect_objects(Right, Mid, Out).
collect_objects(Conditions, In, Out) :- is_list(Conditions), !,
    collect_objects_list(Conditions, In, Out).
collect_objects(object(Ref,Kind,Quant,Unit,Op,Count)-Loc, In,
                [object_row(Ref,Kind,Quant,Unit,Op,Count,Loc)|In]) :- !.
collect_objects(_Other, In, In).

collect_objects_list([], In, In).
collect_objects_list([Condition|Conditions], In, Out) :-
    collect_objects(Condition, In, Mid),
    collect_objects_list(Conditions, Mid, Out).

build_ref_environment([], _Index, Environment, Environment).
build_ref_environment([object_row(Ref,Kind,_,_,_,_,_)|Rows], Index, In, Out) :-
    ( reference_pair(Ref, In, _)
    -> NextIn = In, NextIndex = Index
    ;  referent_base(Kind, Base), atomic_list_concat([Base,Index], '_', Name),
       NextIn = [ref(Ref,Name)|In], NextIndex is Index + 1
    ),
    build_ref_environment(Rows, NextIndex, NextIn, Out).

referent_base(na, collection) :- !.
referent_base(Kind, Kind) :- atom(Kind), !.
referent_base(_, referent).

reference_pair(Ref, [ref(Stored,Name)|_], Name) :- Ref == Stored, !.
reference_pair(Ref, [_|Pairs], Name) :- reference_pair(Ref, Pairs, Name).

collect_events(Term, Events) :-
    collect_events(Term, [], Reversed), reverse(Reversed, Events).

collect_events(drs(_, Conditions), In, Out) :- !,
    collect_events_list(Conditions, In, Out).
collect_events(command(Drs), In, Out) :- !, collect_events(Drs, In, Out).
collect_events(question(Drs), In, Out) :- !, collect_events(Drs, In, Out).
collect_events(-(Drs), In, Out) :- !, collect_events(Drs, In, Out).
collect_events(Left => Right, In, Out) :- !,
    collect_events(Left, In, Mid), collect_events(Right, Mid, Out).
collect_events(Left v Right, In, Out) :- !,
    collect_events(Left, In, Mid), collect_events(Right, Mid, Out).
collect_events(Conditions, In, Out) :- is_list(Conditions), !,
    collect_events_list(Conditions, In, Out).
collect_events(Core-Loc, In, [event_row(Event,Verb,Loc)|In]) :-
    compound(Core), functor(Core, predicate, Arity), Arity >= 3,
    arg(1, Core, Event), arg(2, Core, Verb), !.
collect_events(_Other, In, In).

collect_events_list([], In, In).
collect_events_list([Condition|Conditions], In, Out) :-
    collect_events(Condition, In, Mid),
    collect_events_list(Conditions, Mid, Out).

build_event_environment([], Environment, Environment).
build_event_environment([event_row(Ref,Verb,Loc)|Rows], In, Out) :-
    ( reference_pair(Ref, In, _)
    -> Next = In
    ;  event_name(Verb, Loc, Name), Next = [ref(Ref,Name)|In]
    ),
    build_event_environment(Rows, Next, Out).

collect_aux_refs(Term, Refs) :-
    collect_aux_refs(Term, [], Reversed), reverse(Reversed, Refs).

collect_aux_refs(drs(_, Conditions), In, Out) :- !,
    collect_aux_refs_list(Conditions, In, Out).
collect_aux_refs(command(Drs), In, Out) :- !, collect_aux_refs(Drs, In, Out).
collect_aux_refs(question(Drs), In, Out) :- !, collect_aux_refs(Drs, In, Out).
collect_aux_refs(-(Drs), In, Out) :- !, collect_aux_refs(Drs, In, Out).
collect_aux_refs(Left => Right, In, Out) :- !,
    collect_aux_refs(Left, In, Mid), collect_aux_refs(Right, Mid, Out).
collect_aux_refs(Left v Right, In, Out) :- !,
    collect_aux_refs(Left, In, Mid), collect_aux_refs(Right, Mid, Out).
collect_aux_refs(Conditions, In, Out) :- is_list(Conditions), !,
    collect_aux_refs_list(Conditions, In, Out).
collect_aux_refs(query(Ref,_)-Loc, In, [aux_row(Ref,answer,Loc)|In]) :- !.
collect_aux_refs(property(Ref,Lemma,_)-Loc, In,
                 [aux_row(Ref,Lemma,Loc)|In]) :- !.
collect_aux_refs(_Other, In, In).

collect_aux_refs_list([], In, In).
collect_aux_refs_list([Condition|Conditions], In, Out) :-
    collect_aux_refs(Condition, In, Mid),
    collect_aux_refs_list(Conditions, Mid, Out).

build_aux_environment([], Environment, Environment).
build_aux_environment([aux_row(Ref,Base,Loc)|Rows], In, Out) :-
    ( reference_pair(Ref, In, _)
    -> Next = In
    ;  location_name(Base, Loc, Name), Next = [ref(Ref,Name)|In]
    ),
    build_aux_environment(Rows, Next, Out).

ref_name(Ref, _Environment, Name) :- nonvar(Ref), Ref = named(Name), !.
ref_name(Ref, _Environment, Number) :- nonvar(Ref), Ref = int(Number), !.
ref_name(Ref, Environment, expression(Op,A,B)) :-
    nonvar(Ref), Ref = expr(Op,Left,Right), !,
    exact_expression(Left, Environment, A),
    exact_expression(Right, Environment, B).
ref_name(Ref, Environment, Name) :- reference_pair(Ref, Environment, Name), !.
ref_name(Value, _Environment, Value) :- atomic(Value), !.
ref_name(_Ref, _Environment, unknown_referent).

map_drs_term(drs(_, Conditions), Full, Env, Origins, Emissions, Coverage) :- !,
    map_conditions(Conditions, Full, Env, Origins, Emissions, Coverage).
map_drs_term(command(Drs), Full, Env, Origins, Emissions,
             [operator(command)|Coverage]) :- !,
    map_drs_term(Drs, Full, Env, Origins, Emissions, Coverage).
map_drs_term(question(Drs), Full, Env, Origins, Emissions,
             [operator(question)|Coverage]) :- !,
    map_drs_term(Drs, Full, Env, Origins, Emissions, Coverage).
map_drs_term(-(Drs), Full, Env, Origins,
             [emission(relation(negated_scope,negated(Facts),Span),Loc)],
             [operator(negation)|Coverage]) :- !,
    map_drs_term(Drs, Full, Env, Origins, Inner, Coverage),
    emissions_facts(Inner, Facts), first_emission_location(Inner, Loc),
    sentence_text(Origins, Loc, Span).
map_drs_term(Left => Right, Full, Env, Origins, Emissions, Coverage) :- !,
    ( conversion_implication(Left, Right, Env, Origins, Emissions)
    -> Coverage = [operator(implies),object,predicate]
    ;  map_drs_term(Left, Full, Env, Origins, LeftE, LeftC),
       map_drs_term(Right, Full, Env, Origins, RightE, RightC),
       emissions_facts(LeftE, LeftFacts), emissions_facts(RightE, RightFacts),
       append(LeftE, RightE, Both), first_emission_location(Both, Loc),
       sentence_text(Origins, Loc, Span),
       Emissions = [emission(relation(conditional_scope,
                                      implies(LeftFacts,RightFacts),Span),Loc)],
       append([operator(implies)|LeftC], RightC, Coverage)
    ).
map_drs_term(Left v Right, Full, Env, Origins,
             [emission(relation(disjunction_scope,either(LeftFacts,RightFacts),Span),Loc)],
             Coverage) :- !,
    map_drs_term(Left, Full, Env, Origins, LeftE, LeftC),
    map_drs_term(Right, Full, Env, Origins, RightE, RightC),
    emissions_facts(LeftE, LeftFacts), emissions_facts(RightE, RightFacts),
    append(LeftE, RightE, Both), first_emission_location(Both, Loc),
    sentence_text(Origins, Loc, Span),
    append([operator(disjunction)|LeftC], RightC, Coverage).
map_drs_term(Conditions, Full, Env, Origins, Emissions, Coverage) :-
    is_list(Conditions), !,
    map_conditions(Conditions, Full, Env, Origins, Emissions, Coverage).
map_drs_term(Term, _Full, _Env, _Origins, _Emissions, _Coverage) :-
    throw(map_refusal(none,unsupported_drs_term(Term))).

map_conditions([], _Full, _Env, _Origins, [], []).
map_conditions([Condition|Conditions], Full, Env, Origins, Emissions, Coverage) :-
    map_condition(Condition, Full, Env, Origins, Here, HereCoverage),
    map_conditions(Conditions, Full, Env, Origins, Rest, RestCoverage),
    append(Here, Rest, Emissions), append(HereCoverage, RestCoverage, Coverage).

map_condition(Embedded, Full, Env, Origins, Emissions, Coverage) :-
    \+ Embedded = (_-_), !,
    map_drs_term(Embedded, Full, Env, Origins, Emissions, Coverage).
map_condition(object(Ref,Kind,_Quant,_Unit,Op,Count)-Loc, Full, Env, _Origins,
              Emissions, [object]) :- !,
    ref_name(Ref, Env, Name),
    object_emission(Ref, Name, Kind, Op, Count, Loc, Full, Emissions).
map_condition(predicate(EventRef,Verb,Subject)-Loc, _Full, Env, Origins,
              [emission(relation(Event,event(Verb,[S]),Span),Loc)], [predicate]) :- !,
    ref_name(Subject, Env, S), ref_name(EventRef, Env, Event),
    sentence_text(Origins, Loc, Span).
map_condition(predicate(EventRef,Verb,Subject,Object)-Loc, _Full, Env, Origins,
              [emission(relation(Event,event(Verb,[S,O]),Span),Loc)], [predicate]) :- !,
    ref_name(Subject, Env, S), ref_name(Object, Env, O),
    ref_name(EventRef, Env, Event), sentence_text(Origins, Loc, Span).
map_condition(predicate(EventRef,Verb,A,B,C)-Loc, _Full, Env, Origins,
              [emission(relation(Event,event(Verb,[NA,NB,NC]),Span),Loc)], [predicate]) :- !,
    ref_name(A, Env, NA), ref_name(B, Env, NB), ref_name(C, Env, NC),
    ref_name(EventRef, Env, Event), sentence_text(Origins, Loc, Span).
map_condition(relation(Owned,of,Owner)-Loc, _Full, Env, Origins,
              [emission(relation(OwnedName,of(OwnerName),Span),Loc)], [relation]) :- !,
    ref_name(Owned, Env, OwnedName), ref_name(Owner, Env, OwnerName),
    sentence_text(Origins, Loc, Span).
map_condition(property(Ref,Lemma,Degree)-Loc, _Full, Env, Origins,
              [emission(relation(Name,property(Lemma,Degree),Span),Loc)], [property]) :- !,
    ref_name(Ref, Env, Name), sentence_text(Origins, Loc, Span).
map_condition(property(Ref,Lemma,Degree,Other)-Loc, _Full, Env, Origins,
              [emission(relation(Name,property(Lemma,Degree,OtherName),Span),Loc)],
              [property]) :- !,
    ref_name(Ref, Env, Name), ref_name(Other, Env, OtherName),
    sentence_text(Origins, Loc, Span).
map_condition(property(Ref,Lemma,Other,Degree,Role,Target)-Loc,
              _Full, Env, Origins,
              [emission(relation(Name,
                                 property(Lemma,OtherName,Degree,Role,TargetName),
                                 Span),Loc)], [property]) :- !,
    ref_name(Ref, Env, Name), ref_name(Other, Env, OtherName),
    ref_name(Target, Env, TargetName), sentence_text(Origins, Loc, Span).
map_condition(modifier_adv(Ref,Lemma,Degree)-Loc, _Full, Env, Origins,
              [emission(relation(Name,modifier_adv(Lemma,Degree),Span),Loc)],
              [modifier_adv]) :- !,
    ref_name(Ref, Env, Name), sentence_text(Origins, Loc, Span).
map_condition(modifier_pp(Ref,Lemma,Other)-Loc, _Full, Env, Origins,
              [emission(relation(Name,modifier_pp(Lemma,OtherName),Span),Loc)],
              [modifier_pp]) :- !,
    ref_name(Ref, Env, Name), ref_name(Other, Env, OtherName),
    sentence_text(Origins, Loc, Span).
map_condition(has_part(Whole,Part)-Loc, _Full, Env, Origins,
              [emission(relation(WholeName,has_part(PartName),Span),Loc)], [has_part]) :- !,
    ref_name(Whole, Env, WholeName), ref_name(Part, Env, PartName),
    sentence_text(Origins, Loc, Span).
map_condition(query(Ref,which)-Loc, Full, Env, Origins,
              [emission(asks(result,Name),Loc),
               emission(relation(Name,identity_demand(Kind),Span),Loc)],
              [query]) :- !,
    ref_name(Ref, Env, Name), drs_object_kind(Full, Ref, Kind),
    sentence_text(Origins, Loc, Span).
map_condition(query(Ref,_QueryWord)-Loc, _Full, Env, _Origins,
              [emission(asks(result,Name),Loc)], [query]) :- !,
    ref_name(Ref, Env, Name).
map_condition(formula(Left,Symbol,Right)-Loc, _Full, Env, Origins,
              [emission(relation(FormulaName,formula(L,Symbol,R),Span),Loc)], [formula]) :- !,
    exact_expression(Left, Env, L), exact_expression(Right, Env, R),
    location_name(formula, Loc, FormulaName), sentence_text(Origins, Loc, Span).
map_condition(Condition, _Full, _Env, _Origins, _Emissions, _Coverage) :-
    condition_location(Condition, Loc),
    throw(map_refusal(Loc,unsupported_condition(Condition))).

object_emission(_Ref, _Name, na, _Op, _Count, _Loc, _Full, []) :- !.
object_emission(_Ref, _Name, something, _Op, _Count, _Loc, _Full, []) :- !.
object_emission(_Ref, _Name, somebody, _Op, _Count, _Loc, _Full, []) :- !.
% A which-query object's eq(1) is DRS structure, not a mathematical given.
% It must never seed quantity(Name,1,Kind) in the saturation program.
object_emission(Ref, _Name, _Kind, _Op, _Count, _Loc, Full, []) :-
    drs_identity_query_ref(Full, Ref), !.
object_emission(_Ref, Name, Kind, Op, Count, Loc, _Full,
                [emission(quantity(Name,Number,Kind),Loc)]) :-
    memberchk(Op, [eq,exactly]), exact_number(Count, Number), !.
object_emission(Ref, Name, Kind, geq, _Count, Loc, Full,
                [emission(quantity(Name,unknown,Kind),Loc)]) :-
    drs_has_query_ref(Full, Ref), !.
object_emission(_Ref, _Name, _Kind, na, na, _Loc, _Full, []) :- !.
object_emission(_Ref, _Name, _Kind, Op, Count, Loc, _Full, _Emissions) :-
    throw(map_refusal(Loc,unsupported_quantity_bound(Op,Count))).

exact_number(Number, Number) :- integer(Number), !.
exact_number(Number, Number) :- rational(Number), \+ float(Number), !.

exact_expression(int(N), _Env, N) :- integer(N), !.
exact_expression(Number, _Env, Number) :- exact_number(Number, Number), !.
exact_expression(Ref, Env, Name) :- var(Ref), !, ref_name(Ref, Env, Name).
exact_expression(named(Name), _Env, Name) :- !.
exact_expression(Expression, Env, Normalized) :-
    compound(Expression), Expression =.. [Op,A,B], memberchk(Op, [+,-,*,/,^]), !,
    exact_expression(A, Env, NA), exact_expression(B, Env, NB),
    Normalized =.. [Op,NA,NB].
exact_expression(Expression, _Env, _Normalized) :-
    throw(map_refusal(none,non_exact_formula(Expression))).

drs_has_query_ref(Term, Ref) :-
    sub_term(Condition, Term), nonvar(Condition),
    Condition = query(QueryRef,_)-_, QueryRef == Ref, !.

drs_identity_query_ref(Term, Ref) :-
    sub_term(Condition, Term), nonvar(Condition),
    Condition = query(QueryRef,which)-_, QueryRef == Ref, !.

drs_object_kind(Term, Ref, Kind) :-
    sub_term(Condition, Term), nonvar(Condition),
    Condition = object(ObjectRef,Kind,_,_,_,_)-_, ObjectRef == Ref, !.
drs_object_kind(_Term, _Ref, unknown_identity).

conversion_implication(
    drs(_, Antecedent), drs(_, Consequent), Env, Origins,
    [emission(conversion(FromKind,ToKind,Factor,Span),Loc)]) :-
    member(object(FromRef,FromKind,countable,_,eq,1)-_, Antecedent),
    member(object(ToRef,ToKind,countable,_,eq,Factor)-_, Consequent),
    integer(Factor),
    member(predicate(_,Verb,FromRef0,ToRef0)-Loc, Consequent),
    FromRef0 == FromRef, ToRef0 == ToRef,
    memberchk(Verb, [have,contain,hold]),
    ref_name(FromRef, Env, _), ref_name(ToRef, Env, _),
    sentence_text(Origins, Loc, Span), !.

object_kinds(Objects, Kinds) :-
    findall(Kind,
            ( member(object_row(_,Kind,_,_,_,_,_), Objects),
              atom(Kind), \+ memberchk(Kind, [na,something,somebody]) ),
            Kinds0),
    sort(Kinds0, Kinds).

event_name(Verb, Loc, Name) :- location_name(Verb, Loc, Name).
location_name(Base, Sentence/Token, Name) :- !,
    atomic_list_concat([Base,Sentence,Token], '_', Name).
location_name(Base, _Loc, Name) :- atomic_list_concat([Base,event], '_', Name).

condition_location(_-Loc, Loc) :- !.
condition_location(_, none).

sentence_text(_Origins, none, "") :- !.
sentence_text(Origins, Location, Text) :-
    normalize_location(Location, Sentence, _),
    findall(Start-End-Surface,
            member(origin(Sentence,_Token,Start,End,Surface), Origins),
            Rows),
    Rows \== [], !,
    Rows = [First-_-_|_], last(Rows, _-Last-_),
    Length is max(0, Last - First),
    source_text_from_origins(Origins, Rows, First, Length, Text).
sentence_text(_Origins, _Location, "").

source_text_from_origins(Origins, _Rows, Start, Length, Text) :-
    member(source_text(Source), Origins),
    sub_string(Source, Start, Length, _, Text), !.
source_text_from_origins(_Origins, Rows, _Start, _Length, Text) :-
    findall(Surface, (member(_-_-Surface, Rows), Surface \== ""), Surfaces),
    atomic_list_concat(Surfaces, ' ', Atom), atom_string(Atom, Text).

first_emission_location([emission(_,Loc)|_], Loc) :- !.
first_emission_location([], none).
emissions_facts(Emissions, Facts) :-
    findall(Fact, member(emission(Fact,_), Emissions), Facts).

dedupe_emissions(Emissions, Unique) :- dedupe_emissions(Emissions, [], Unique).
dedupe_emissions([], _Seen, []).
dedupe_emissions([emission(Fact,Loc)|Rows], Seen, Unique) :-
    ( memberchk(Fact, Seen)
    -> dedupe_emissions(Rows, Seen, Unique)
    ;  Unique = [emission(Fact,Loc)|Rest],
       dedupe_emissions(Rows, [Fact|Seen], Rest)
    ).

emissions_output([], _Origins, _Index, [], []).
emissions_output([emission(Fact,Loc)|Rows], Origins, Index,
                 [Fact|Facts], [fact_span(Index,Start,End,Surface)|Spans]) :-
    emission_span(Loc, Origins, Start, End, Surface),
    Next is Index + 1,
    emissions_output(Rows, Origins, Next, Facts, Spans).

emission_span(none, _Origins, 0, 0, "") :- !.
emission_span(Location, Origins, Start, End, Surface) :-
    normalize_location(Location, Sentence, Token),
    nearest_origin(Origins, Sentence, Token,
                   origin(_,_,Start,End,Surface)), !.
emission_span(_Location, _Origins, 0, 0, "").

five_form_fact(quantity(_, Value, _)) :-
    Value == unknown, !.
five_form_fact(quantity(_, Value, _)) :- exact_number(Value, _).
five_form_fact(conversion(_, _, Factor, Span)) :- exact_number(Factor, _), string(Span).
five_form_fact(relation(_, _, Span)) :- string(Span).
five_form_fact(asks(result, _)).
five_form_fact(discrete_kinds(Kinds)) :- is_list(Kinds).

list_to_set_stable(List, Set) :- list_to_set_stable(List, [], Set).
list_to_set_stable([], _Seen, []).
list_to_set_stable([X|Xs], Seen, Set) :-
    ( memberchk(X, Seen)
    -> list_to_set_stable(Xs, Seen, Set)
    ;  Set = [X|Rest], list_to_set_stable(Xs, [X|Seen], Rest)
    ).

% ---------------------------------------------------------------------------
% Receipts

check_ape_reader_pilot :-
    ensure_ape_user_lexicon,
    forall(ape_positive_receipt(Id, Citation, Text),
           check_positive_receipt(Id, Citation, Text)),
    forall(ape_negative_receipt(Id, Text, ExpectedReason),
           check_negative_receipt(Id, Text, ExpectedReason)),
    forall(rewrite_receipt(Id, Before, Rule),
           check_rewrite_receipt(Id, Before, Rule)),
    forall(question_rewrite_receipt(Class, Id, Citation, Text, Rule),
           check_question_rewrite_receipt(Class, Id, Citation, Text, Rule)),
    forall(question_rewrite_negative(Class, Id, Text, Rule),
           check_question_rewrite_negative(Class, Id, Text, Rule)),
    check_mapper_coverage,
    check_query_object_cardinality_guard,
    writeln('ape_reader_pilot: all receipts passed').

check_positive_receipt(Id, Citation, Text) :-
    ( citation_exists(Citation),
      ape_reader_result(Text, parsed(Facts, Spans, _)),
      Facts \== [], same_length(Facts, Spans), maplist(five_form_fact, Facts)
    -> true
    ;  format(user_error, 'APE positive receipt failed: ~q~n', [Id]), fail
    ).

check_negative_receipt(Id, Text, ExpectedReason) :-
    ( ape_reader_result(Text, refusal(Token, span(Start,End,_), Reason, _)),
      string(Token), integer(Start), integer(End), End >= Start,
      reason_class(Reason, ExpectedReason)
    -> true
    ;  format(user_error, 'APE negative receipt failed: ~q~n', [Id]), fail
    ).

reason_class(Reason, Reason) :- atom(Reason), !.
reason_class(ape_error(_, _), ape_error) :- !.
reason_class(unsupported_quantity_bound(_, _), unsupported_quantity_bound).

check_rewrite_receipt(_Id, Before, Rule) :-
    ace_to_drs:acetext_to_drs(Before, on, off, _, _, _, BeforeMessages, _),
    first_ape_error(BeforeMessages, _, _),
    ape_reader_result(Before, parsed(_, _, Rules)), memberchk(Rule, Rules), !.
check_rewrite_receipt(Id, _Before, _Rule) :-
    format(user_error, 'APE rewrite receipt failed: ~q~n', [Id]), fail.

check_question_rewrite_receipt(Class, Id, Citation, Text, Rule) :-
    ( citation_exists(Citation),
      ape_reader_result(Text, parsed(Facts, Spans, Rules)),
      Facts \== [], same_length(Facts, Spans), memberchk(Rule, Rules),
      member(asks(result,_), Facts), maplist(five_form_fact, Facts)
    -> true
    ;  format(user_error, 'APE question rewrite receipt failed: ~q/~q~n',
              [Class, Id]), fail
    ).

check_question_rewrite_negative(Class, Id, Text, Rule) :-
    ( ape_reader_result(Text, Result),
      ( Result = parsed(_,_,Rules) ; Result = refusal(_,_,_,Rules) ),
      \+ memberchk(Rule, Rules)
    -> true
    ;  format(user_error, 'APE question rewrite negative failed: ~q/~q~n',
              [Class, Id]), fail
    ).

citation_exists(corpus_span(Relative, lines(Start,End))) :-
    atom(Relative), integer(Start), integer(End), Start =< End,
    pilot_directory(Here), directory_file_path(Here, '../../..', Repo0),
    absolute_file_name(Repo0, Repo, [file_type(directory), access(read)]),
    directory_file_path(Repo, Relative, Absolute), exists_file(Absolute).

check_mapper_coverage :-
    mapper_fixture(Drs),
    ape_map_drs(Drs, [], Facts, Spans),
    Facts \== [], same_length(Facts, Spans),
    operator_fixture(OperatorDrs),
    ape_map_drs(OperatorDrs, [], OperatorFacts, _), OperatorFacts \== [].

check_query_object_cardinality_guard :-
    query_object_fixture(Drs),
    ape_map_drs(Drs, [], Facts, _),
    member(asks(result,plane_1), Facts),
    member(relation(plane_1,identity_demand(plane),_), Facts),
    \+ member(quantity(plane_1,1,_), Facts),
    member(quantity(situation_2,1,situation), Facts),
    ape_reader_result("Which plane is faster?", parsed(ReceiptFacts, _, _)),
    member(asks(result,Asked), ReceiptFacts),
    \+ member(quantity(Asked,1,_), ReceiptFacts).

query_object_fixture(drs([Plane,Situation],
    [ query(Plane,which)-1/1,
      object(Plane,plane,countable,na,eq,1)-1/4,
      object(Situation,situation,countable,na,eq,1)-1/8
    ])).

mapper_fixture(drs([A,B,C,D],
    [ object(A,pencil,countable,na,eq,3)-1/2,
      object(B,student,countable,na,eq,1)-1/4,
      object(C,box,countable,na,eq,1)-1/6,
      object(D,answer,countable,na,geq,2)-1/8,
      predicate(_,contain,B,A)-1/3,
      relation(A,of,C)-1/5,
      property(C,red,pos)-1/7,
      modifier_adv(_,quickly,pos)-1/9,
      modifier_pp(_,with,A)-1/10,
      has_part(C,A)-1/11,
      query(D,howm)-1/12,
      formula(int(3),'=',int(3))-1/13
    ])).

operator_fixture(drs([], [
    command(drs([A],[object(A,pencil,countable,na,eq,1)-1/2])),
    question(drs([B],[query(B,howm)-1/3,
                      object(B,pencil,countable,na,geq,2)-1/4])),
    -(drs([C],[object(C,box,countable,na,eq,1)-1/5])),
    (drs([D],[object(D,bag,countable,na,eq,1)-1/6]) v
     drs([E],[object(E,basket,countable,na,eq,1)-1/7])),
    (drs([F],[object(F,student,countable,na,eq,1)-1/8]) =>
     drs([G],[object(G,pencil,countable,na,eq,2)-1/9]))
])).

rewrite_receipt(imperative_find_mean,
    "Find the mean.", addressee_insertion).
rewrite_receipt(relative_seedling_measurement,
    "There are 2 seedlings that are 3 inches tall.",
    relative_existential_measurement).

question_rewrite_receipt(total_adjunct, teams,
    corpus_span('curriculum/im_teacher_guides/grade3/unit1/lesson12.md',
                lines(210,216)),
    "How many teams are there altogether?", question_total_adjunct).
question_rewrite_receipt(total_adjunct, ducks,
    corpus_span('curriculum/im_teacher_guides/grade3/unit1/lesson12.md',
                lines(302,302)),
    "How many ducks are there altogether?", question_total_adjunct).
question_rewrite_receipt(total_adjunct, birds,
    corpus_span('curriculum/im_teacher_guides/grade1/unit3/lesson17.md',
                lines(337,337)),
    "How many birds are there in all?", question_total_adjunct).
question_rewrite_negative(total_adjunct, non_equivalent_adverb,
    "How many ducks are there nearby?", question_total_adjunct).

% This is the only attested should-go demand in the measured corpus.  Dropping
% the modal leaves the quantity demand while avoiding a claim about obligation.
question_rewrite_receipt(should_modality, colored_pencils,
    corpus_span('curriculum/im_teacher_guides/grade3/unit4/lesson3.md',
                lines(197,197)),
    "How many colored pencils should go in each box?",
    question_should_modality).
question_rewrite_negative(should_modality, different_modal,
    "How many colored pencils could go in each box?",
    question_should_modality).

question_rewrite_receipt(exact_value, multiplication,
    corpus_span('curriculum/im/generated/recovered_task_spans.json',
                lines(5374,5374)),
    "What is the value of 6 × 7?", exact_arithmetic_question_program).
question_rewrite_receipt(exact_value, division,
    corpus_span('curriculum/im/generated/recovered_task_spans.json',
                lines(7621,7621)),
    "What is the value of 78 ÷ 6?", exact_arithmetic_question_program).
question_rewrite_receipt(exact_value, decimal_addition,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',
                lines(2730,2730)),
    "What is the value of 1.20 + 0.13?",
    exact_arithmetic_question_program).
question_rewrite_negative(exact_value, division_by_zero,
    "What is the value of 8 ÷ 0?", exact_arithmetic_question_program).

ape_negative_receipt(bare_plural,
    "Students have pencils.", bare_plural).
ape_negative_receipt(stacked_adjective,
    "The small red box contains 3 pencils.", stacked_adjective).
ape_negative_receipt(range_quantity,
    "There are at least 3 pencils.", unsupported_quantity_bound).
ape_negative_receipt(unresolved_pronoun,
    "She has 3 pencils.", ape_error).
ape_negative_receipt(missing_predicate,
    "A student 3 pencils.", ape_error).
ape_negative_receipt(nominal_comparative,
    "There are 3 more than 2.", nominal_comparative).
ape_negative_receipt(bare_partitive,
    "Three of the students have pencils.", bare_partitive).
ape_negative_receipt(source_artifact,
    "Acti • • b.", source_artifact).

ape_positive_receipt(existential_markers,
    corpus_span('curriculum/im_teacher_guides/grade1/unit2/lesson12.md',lines(166,166)),
    "There are 6 markers.").
ape_positive_receipt(existential_folders,
    corpus_span('curriculum/im_teacher_guides/grade1/unit2/lesson12.md',lines(298,298)),
    "There are 7 folders.").
ape_positive_receipt(existential_pens,
    corpus_span('curriculum/im_teacher_guides/grade1/unit2/lesson12.md',lines(299,299)),
    "There are 9 pens.").
ape_positive_receipt(existential_pencils,
    corpus_span('curriculum/im_teacher_guides/grade1/unit2/lesson12.md',lines(307,307)),
    "There are 5 pencils.").
ape_positive_receipt(existential_markers_eight,
    corpus_span('curriculum/im_teacher_guides/grade1/unit2/lesson12.md',lines(308,308)),
    "There are 8 markers.").
ape_positive_receipt(existential_students,
    corpus_span('curriculum/im_teacher_guides/grade1/unit2/lesson12.md',lines(397,397)),
    "There are 6 students.").
ape_positive_receipt(each_bag_strawberries,
    corpus_span('curriculum/im_teacher_guides/grade3/unit1/lesson10.md',lines(270,272)),
    "Each bag has 2 strawberries.").
ape_positive_receipt(each_hand_fingers,
    corpus_span('curriculum/im_teacher_guides/grade3/unit1/lesson10.md',lines(272,275)),
    "Each hand has 5 fingers.").
ape_positive_receipt(each_pond_ducks,
    corpus_span('curriculum/im_teacher_guides/grade3/unit1/lesson12.md',lines(302,302)),
    "Each pond has 5 ducks.").
ape_positive_receipt(noah_stamps,
    corpus_span('curriculum/im_teacher_guides/grade1/unit6/lesson14.md',lines(302,302)),
    "Noah has 6 stamps.").
ape_positive_receipt(tyler_stamps,
    corpus_span('curriculum/im_teacher_guides/grade1/unit6/lesson14.md',lines(303,303)),
    "Tyler has 16 stamps.").
ape_positive_receipt(mai_tickets,
    corpus_span('curriculum/im_teacher_guides/grade1/unit8/lesson6.md',lines(160,160)),
    "Mai has 12 tickets.").
ape_positive_receipt(mai_books,
    corpus_span('curriculum/im_teacher_guides/grade1/unit2/lesson4.md',lines(388,388)),
    "Mai has 3 books.").
ape_positive_receipt(lin_books,
    corpus_span('curriculum/im_teacher_guides/grade1/unit2/lesson4.md',lines(435,435)),
    "Lin has 5 books.").
ape_positive_receipt(elena_pencils,
    corpus_span('curriculum/im_teacher_guides/grade1/unit2/lesson23.md',lines(237,237)),
    "Elena has 5 pencils.").
ape_positive_receipt(elena_counters,
    corpus_span('curriculum/im_teacher_guides/grade1/unit3/lesson26.md',lines(168,168)),
    "Elena has 6 counters.").
ape_positive_receipt(clare_cards,
    corpus_span('curriculum/im_teacher_guides/grade1/unit3/lesson15.md',lines(302,302)),
    "Clare has 4 cards.").
ape_positive_receipt(han_pets,
    corpus_span('curriculum/im_teacher_guides/grade1/unit2/lesson9.md',lines(186,186)),
    "Han has 8 pets.").
ape_positive_receipt(diego_pets,
    corpus_span('curriculum/im_teacher_guides/grade1/unit2/lesson9.md',lines(401,401)),
    "Diego has 7 pets.").
ape_positive_receipt(tyler_turtles,
    corpus_span('curriculum/im_teacher_guides/grade1/unit2/lesson6.md',lines(265,265)),
    "Tyler has 2 turtles.").
ape_positive_receipt(clare_dogs,
    corpus_span('curriculum/im_teacher_guides/grade1/unit2/lesson6.md',lines(266,266)),
    "Clare has 4 dogs.").
ape_positive_receipt(kiran_books,
    corpus_span('curriculum/im_teacher_guides/grade1/unit2/lesson3.md',lines(170,170)),
    "Kiran has 6 books.").
ape_positive_receipt(kiran_marbles,
    corpus_span('curriculum/im_teacher_guides/grade1/unit5/lesson4.md',lines(87,87)),
    "Kiran has 14 marbles.").
ape_positive_receipt(priya_marbles,
    corpus_span('curriculum/im_teacher_guides/grade1/unit5/lesson4.md',lines(89,89)),
    "Priya has 23 marbles.").
ape_positive_receipt(imperative_find_mean,
    corpus_span('curriculum/im_teacher_guides/grade6/unit8/unit_overview_teacher_guide.md',lines(10482,10482)),
    "Find the mean.").
ape_positive_receipt(relative_seedlings,
    corpus_span('curriculum/im_teacher_guides/grade3/unit6/lesson4.md',lines(164,164)),
    "There are 2 seedlings that are 3 inches tall.").
ape_positive_receipt(labeled_entity_rate,
    corpus_span('curriculum/im/generated/compiled_task_instances.pl',lines(3394,3394)),
    "Plane A travels 2800 miles in 5 hours.").
