:- encoding(utf8).
/** <module> Deterministic first crack and consultation admission gate
 *
 * Python owns model sequencing.  This helper owns tokenization, store lookup,
 * the narrow reader attempt, residue classification, and candidate validation.
 */

:- module(consultation_scan, [main/0]).

:- use_module(library(http/json)).
:- use_module(library(lists), [last/2]).
:- use_module(library(porter_stem), [tokenize_atom/2]).
:- use_module('../../knowledge/strategies/abstraction/english_morphology.pl').
:- use_module('../../knowledge/strategies/abstraction/math_lexicon_pilot.pl').
:- use_module('../../knowledge/strategies/abstraction/lexicon_supplement_pilot.pl').
:- use_module('../../knowledge/strategies/abstraction/word_problem_reader_pilot.pl').
:- use_module('../../knowledge/strategies/abstraction/lexicon_loop_admitted_pilot.pl').
:- use_module('../../hermes/math_claim_language.pl', []).

:- initialization(main, main).

main :-
    current_prolog_flag(argv, Argv),
    ( append(_, ['--mode', ModeAtom|_], Argv) -> atom_string(ModeAtom, Mode)
    ; Mode = "scan"
    ),
    json_read_dict(user_input, Input),
    catch(run_mode(Mode, Input, Output), Error,
          error_output(Error, Output)),
    json_write_dict(user_output, Output, [width(0)]), nl.

run_mode("scan", Input, _{ok:true, rows:Rows, reader_classes:Classes,
                           change_actions:Actions}) :-
    maplist(scan_text, Input.sentences, Rows),
    reader_classes(Classes),
    change_actions(Actions).
run_mode("gate", Input, Output) :-
    atom_string(Word, Input.word),
    atom_string(Class, Input.class),
    morphology_term(Input.morphology, Morphology),
    atom_string(Source, Input.evidence.source),
    Evidence = evidence(guide_span(Source, Input.evidence.sentence_index,
                                   Input.evidence.sentence,
                                   Input.evidence.start, Input.evidence.end)),
    atom_string(Consultation, Input.consultation_id),
    lexicon_loop_admitted_pilot:gate_candidate(
        Word, Class, Morphology, Evidence, Input.rationale, Consultation, Verdict),
    verdict_dict(Verdict, Output).

error_output(Error, _{ok:false, error:Message}) :-
    message_to_string(Error, Message).

morphology_term(Dict, none) :- Dict.kind == "none", !.
morphology_term(Dict, forms(invariant)) :- Dict.kind == "invariant", !.
morphology_term(Dict, forms(noun(Singular, Plural))) :-
    Dict.kind == "noun", atom_string(Singular, Dict.singular),
    atom_string(Plural, Dict.plural), !.
morphology_term(Dict, forms(verb(Base, Third, Past, Ing, Participle))) :-
    Dict.kind == "verb",
    maplist(atom_string, [Base,Third,Past,Ing,Participle],
            [Dict.base,Dict.third,Dict.past,Dict.ing,Dict.participle]), !.
morphology_term(Dict, expands_to(Full)) :-
    Dict.kind == "expands_to", atom_string(Full, Dict.full), !.

verdict_dict(passed(Checks), _{ok:true, verdict:"passed", checks:Names}) :-
    maplist(atom_string, Checks, Names).
verdict_dict(rejected(Check), _{ok:true, verdict:"rejected", failed_check:Name}) :-
    atom_string(Check, Name).

scan_text(Text, Row) :-
    string_lower(Text, Lower), tokenize_atom(Lower, Tokens),
    maplist(token_dict, Tokens, TokenRows),
    ( word_problem_reader_pilot:word_problem_facts(Text, Facts)
    -> Parsed = true, maplist(term_string, Facts, FactStrings), Residues = []
    ;  Parsed = false, FactStrings = [], classify_residue(Tokens, TokenRows, Residues)
    ),
    Row = _{text:Text, tokens:TokenRows, parsed:Parsed, facts:FactStrings,
            residues:Residues}.

token_dict(Token, _{surface:Surface, lexical:Lexical, known:Known,
                    sources:Sources, categories:Categories, noun_bases:NounBases}) :-
    term_string(Token, Surface0, [quoted(false)]), string_lower(Surface0, Surface),
    ( lexical_atom(Token) -> Lexical = true ; Lexical = false ),
    findall(Source, token_source(Token, Source), Sources0), sort(Sources0, Sources),
    findall(Category, token_category(Token, Category), Cs0), sort(Cs0, Categories),
    findall(BaseString,
            (atom(Token), english_morphology:em_noun_base(Token, Base),
             atom_string(Base, BaseString)), Bs0), sort(Bs0, NounBases),
    ( (Lexical == false ; Sources \== []) -> Known = true ; Known = false ).

lexical_atom(Token) :-
    atom(Token), atom_chars(Token, Chars), member(Char, Chars), char_type(Char, alpha), !.

token_source(Token, "supplement") :- atom(Token), ls_word(Token, _, _, _, _).
token_source(Token, "loop_admitted") :-
    atom(Token), loop_admitted_word(Token, _, _, _, _, _, _).
token_source(Token, "webster_morphology") :-
    atom(Token), english_morphology:em_category(Token, _),
    \+ ls_word(Token, _, _, _, _).
token_source(Token, "math_lexicon") :-
    atom(Token), math_lexicon_surface(Token).
token_source(Token, "incumbent_math_tables") :-
    atom(Token), incumbent_token(Token).

math_lexicon_surface(Token) :-
    math_lexicon_pilot:ml_word(_, _, forms(Forms), _), memberchk(Token, Forms), !.

incumbent_token(Token) :- math_claim_language:anaphor_token(Token), !.
incumbent_token(Token) :- math_claim_language:measurement_unit(Token, _), !.
incumbent_token(Token) :- phrase(math_claim_language:integer_value(_), [Token]), !.

token_category(Token, CategoryString) :-
    atom(Token), english_morphology:em_category(Token, Category),
    atom_string(Category, CategoryString).
token_category(Token, ClassString) :-
    atom(Token), english_morphology:em_word_class(Token, Class),
    atom_string(Class, ClassString).
token_category(Token, CategoryString) :-
    atom(Token), math_lexicon_pilot:ml_word(_, Category, forms(Forms), _),
    memberchk(Token, Forms), atom_string(Category, CategoryString).

classify_residue(Tokens, TokenRows, Residues) :-
    unknown_runs(TokenRows, 0, Runs),
    ( Runs \== []
    -> maplist(run_residue(Tokens), Runs, Residues)
    ; r2_residue(Tokens, R2)
    -> Residues = [R2]
    ; reader_classes(Classes),
      length(Tokens, TokenCount),
      Residues = [_{class:"r3_sentence_class_unparsed", token_start:0,
                    token_end:TokenCount, known:_{tokens:TokenRows},
                    choices:Classes}]
    ).

unknown_runs([], _, []).
unknown_runs([Row|Rows], Index, Runs) :-
    ( Row.lexical == true, Row.known == false
    -> take_unknown(Rows, Index, [Index], Indices, Rest, Next),
       Runs = [Indices|More], unknown_runs(Rest, Next, More)
    ;  Next is Index + 1, unknown_runs(Rows, Next, Runs)
    ).

take_unknown([Row|Rows], Index0, Acc, Indices, Rest, Next) :-
    Row.lexical == true, Row.known == false, !,
    Index is Index0 + 1,
    take_unknown(Rows, Index, [Index|Acc], Indices, Rest, Next).
take_unknown([Dot,Following|Rows], Index0, Acc, Indices, Rest, Next) :-
    Dot.lexical == false, Dot.surface == ".",
    Following.lexical == true, Following.known == false, !,
    DotIndex is Index0 + 1, FollowingIndex is Index0 + 2,
    take_unknown(Rows, FollowingIndex, [FollowingIndex,DotIndex|Acc],
                 Indices, Rest, Next).
take_unknown(Rest, Index0, Acc, Indices, Rest, Next) :-
    reverse(Acc, Indices), Next is Index0 + 1.

run_residue(Tokens, Indices, Residue) :-
    Indices = [Start|_], last(Indices, Last), End is Last + 1,
    maplist(nth0_token(Tokens), Indices, RunTokens),
    maplist(atom_string, RunTokens, RunStrings),
    ( Indices = [Only], likely_unit_position(Tokens, Only)
    -> Class = "r6_unit_unknown_or_kind_gap",
       unit_choices(Tokens, UnitChoices),
       Known = _{unit_surface:RunStrings, text_noun_candidates:UnitChoices},
       Choices = UnitChoices
    ;  Class = "r1_token_unknown", Known = _{unknown_run:RunStrings},
       supplement_classes(Choices)
    ),
    Residue = _{class:Class, token_start:Start, token_end:End,
                known:Known, choices:Choices}.

nth0_token(Tokens, Index, Token) :- nth0(Index, Tokens, Token).

likely_unit_position(Tokens, Index) :-
    Index > 0, Prior is Index - 1, nth0(Prior, Tokens, Prev),
    ( number(Prev) ; atom(Prev), phrase(math_claim_language:integer_value(_), [Prev]) ),
    nth0(Index, Tokens, Token), atom_length(Token, Length), Length =< 5.

unit_choices(Tokens, Choices) :-
    findall(BaseString,
            (member(Token, Tokens), atom(Token),
             english_morphology:em_noun_base(Token, Base),
             atom_string(Base, BaseString)), Bases0),
    sort(Bases0, Choices).

r2_residue(Tokens, Residue) :-
    phrase(r2_shape(Surface, Base), Tokens),
    change_actions(Actions),
    atom_string(Base, BaseString),
    \+ (member(Action, Actions), get_dict(base, Action, BaseString)),
    Residue = _{class:"r2_no_category_fits_slot", token_start:1, token_end:2,
                known:_{surface:Surface, base:BaseString,
                        slot:"change_verb", admitted:Actions}, choices:Actions}.

r2_shape(Surface, Base) -->
    word_problem_reader_pilot:subject(_), [Surface],
    {english_morphology:em_verb_base(Surface, Base, _)},
    word_problem_reader_pilot:integer(_),
    word_problem_reader_pilot:noun_base(_), ['.'].

reader_classes(Classes) :-
    word_problem_reader_pilot:word_problem_reader_pilot_summary(
        summary(_, accepted_classes(Atoms), _, _)),
    maplist(atom_string, Atoms, Classes).

change_actions(Actions) :-
    findall(_{base:BaseString, effect:Effect},
            (word_problem_reader_pilot:signed_change(Base, 1, Signed),
             atom_string(Base, BaseString),
             (Signed < 0 -> Effect = "fewer" ; Effect = "more")),
            Actions).

supplement_classes(Classes) :-
    lexicon_supplement_pilot:lexicon_supplement_summary(
        summary(_, _, _, _, _, class_counts(Counts))),
    findall(Name, (member(Term, Counts), functor(Term, Class, 1),
                   atom_string(Class, Name)), Classes).
