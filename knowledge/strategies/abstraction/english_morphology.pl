:- encoding(utf8).
/** <module> Webster morphology interface pilot
 *
 * This quarantined pilot makes the runtime Webster store queryable through a
 * small morphology interface. It reads dictionary forms; it does not infer a
 * speaker's intended word or replace the incumbent math-claim reader.
 *
 * Check from the repository root:
 * `swipl -q -l paths.pl -l knowledge/strategies/abstraction/english_morphology.pl -g english_morphology:check_english_morphology -t halt`
 */

:- module(english_morphology,
          [ em_noun_base/2,
            em_verb_base/3,
            em_adjective_base/3,
            em_category/2,
            em_math_domain/1,
            em_word_class/2,
            em_expansion/2,
            english_morphology_summary/1,
            check_english_morphology/0
          ]).

:- dynamic webster_store_file/1.
:- dynamic wl_noun/2, wl_noun_plural_only/1.
:- dynamic wl_verb/6, wl_verb_defective/1.
:- dynamic wl_adjective/1, wl_adj_comp/2, wl_adj_superl/2.
:- dynamic wl_adverb/1, wl_preposition/1, wl_pronoun/1.
:- dynamic wl_conjunction/1, wl_interjection/1, wl_domain/2.
:- dynamic wl_summary/3.

:- table em_noun_base/2, em_verb_base/3, em_adjective_base/3.

:- prolog_load_context(directory, Here),
   directory_file_path(
       Here,
       '../../../hermes/app/runtime/experiments/language/webster_lexicon.pl',
       Store),
   assertz(webster_store_file(Store)),
   ( exists_file(Store) -> ensure_loaded(Store) ; true ).

:- use_module('lexicon_supplement_pilot.pl', [ls_word/5]).

english_morphology_summary(
    summary(source(webster_unabridged_gutenberg_673),
            role(orphan_morphology_interface),
            runtime_store('hermes/app/runtime/experiments/language/webster_lexicon.pl'),
            supplement('knowledge/strategies/abstraction/lexicon_supplement_pilot.pl'))).

%! em_noun_base(?Surface, ?Base) is nondet.
%
%  Relate a singular identity or attested plural to its base. Plural-only
%  entries have no separate singular in the source, so their identity is the
%  only reading this interface supplies.
em_noun_base(Base, Base) :-
    wl_noun(Base, _).
em_noun_base(Plural, Base) :-
    wl_noun(Base, Plural).
em_noun_base(Plural, Plural) :-
    wl_noun_plural_only(Plural).
em_noun_base(Base, Base) :-
    ls_word(_, _, forms(noun(Base, _)), _, _).
em_noun_base(Plural, Base) :-
    ls_word(_, _, forms(noun(Base, Plural)), _, _).

%! em_verb_base(?Surface, ?Base, ?Form) is nondet.
em_verb_base(Base, Base, base) :- wl_verb(Base, _, _, _, _, _).
em_verb_base(Third, Base, third_person) :- wl_verb(Base, Third, _, _, _, _).
em_verb_base(Past, Base, past) :- wl_verb(Base, _, Past, _, _, _).
em_verb_base(Ing, Base, ing) :- wl_verb(Base, _, _, Ing, _, _).
em_verb_base(Participle, Base, participle) :- wl_verb(Base, _, _, _, Participle, _).
em_verb_base(Base, Base, base) :- wl_verb_defective(Base).
em_verb_base(Base, Base, base) :-
    ls_word(_, _, forms(verb(Base, _, _, _, _)), _, _).
em_verb_base(Third, Base, third_person) :-
    ls_word(_, _, forms(verb(Base, Third, _, _, _)), _, _).
em_verb_base(Past, Base, past) :-
    ls_word(_, _, forms(verb(Base, _, Past, _, _)), _, _).
em_verb_base(Ing, Base, ing) :-
    ls_word(_, _, forms(verb(Base, _, _, Ing, _)), _, _).
em_verb_base(Participle, Base, participle) :-
    ls_word(_, _, forms(verb(Base, _, _, _, Participle)), _, _).

%! em_adjective_base(?Surface, ?Base, ?Degree) is nondet.
em_adjective_base(Base, Base, positive) :- wl_adjective(Base).
em_adjective_base(Comparative, Base, comparative) :- wl_adj_comp(Base, Comparative).
em_adjective_base(Superlative, Base, superlative) :- wl_adj_superl(Base, Superlative).
em_adjective_base(Word, Word, positive) :-
    ls_word(Word, adjective, forms(invariant), _, _).

%! em_category(+Surface, ?Category) is nondet.
%
%  Categories are dictionary readings. A surface can therefore return more
%  than one category on backtracking.
em_category(Surface, noun) :- atom(Surface), em_noun_base(Surface, _).
em_category(Surface, verb) :- atom(Surface), em_verb_base(Surface, _, _).
em_category(Surface, adjective) :- atom(Surface), em_adjective_base(Surface, _, _).
em_category(Surface, adverb) :- atom(Surface), wl_adverb(Surface).
em_category(Surface, preposition) :- atom(Surface), wl_preposition(Surface).
em_category(Surface, pronoun) :- atom(Surface), wl_pronoun(Surface).
em_category(Surface, conjunction) :- atom(Surface), wl_conjunction(Surface).
em_category(Surface, interjection) :- atom(Surface), wl_interjection(Surface).
em_category(Surface, adverb) :-
    atom(Surface), ls_word(Surface, adverb, forms(invariant), _, _).
em_category(Surface, pronoun) :-
    atom(Surface), ls_word(Surface, function_word, forms(invariant), _, _).

%! em_word_class(?Word, ?Class) is nondet.
%
%  Return the authored supplement class without turning names or notation into
%  grammatical noun readings.
em_word_class(Word, Class) :-
    ls_word(Word, Class, _, _, _).

%! em_expansion(?Abbreviation, ?Full) is nondet.
em_expansion(Abbreviation, Full) :-
    ls_word(Abbreviation, unit_abbreviation, expands_to(Full), _, _).

%! em_math_domain(?Word) is nondet.
%
%  Webster's abbreviated field labels Math, Arith, Geom, and Alg are the
%  admitted dictionary evidence. This is a historical tag, not a claim that
%  the word is used in every mathematics classroom.
em_math_domain(Word) :-
    wl_domain(Word, Field),
    memberchk(Field, [math, arith, geom, alg]).
em_math_domain(Word) :-
    ls_word(Word, Class, _, _, _),
    memberchk(Class, [math_term, math_notation, algebra_symbol]).

check_english_morphology :-
    require_webster_store,
    % Webster noun1 row 40834.
    must_once(em_noun_base(guavas, guava), guavas_to_guava),
    % Webster noun1 rows 19-21 carry three plural surfaces.
    findall(P, em_noun_base(P, abacus), Ps0),
    sort(Ps0, [abaci, abacus, abacuses]),
    % Webster verb-t row 28645 supplies the five distinct ordinary forms.
    forall(member(S-F, [eat-base, eats-third_person, ate-past,
                        eating-ing, eaten-participle]),
           must_once(em_verb_base(S, eat, F), eat_form(S, F))),
    % Webster comp/superl rows 8055-8056.
    must_once(em_adjective_base(worse, bad, comparative), worse_to_bad),
    must_once(em_adjective_base(worst, bad, superlative), worst_to_bad),
    % Absence is a semidet result rather than an exception.
    \+ em_category(not_in_webster_673_xyzzy, _),
    % Webster holds both noun1 Run/Runs and verb-i Run/Runs.
    findall(C, em_category(runs, C), Cs0),
    sort(Cs0, Cs),
    memberchk(noun, Cs), memberchk(verb, Cs),
    must_once(em_word_class(carla, given_name), carla_given_name),
    \+ em_category(carla, noun),
    must_once(em_expansion(kg, kilogram), kg_to_kilogram),
    forall(member(S-F, [restate-base, restates-third_person,
                        restated-past, restating-ing, restated-participle]),
           must_once(em_verb_base(S, restate, F), restate_form(S, F))),
    must_once(em_word_class(x, algebra_symbol), x_algebra_symbol),
    must_once(em_noun_base(cupcakes, cupcake), cupcakes_to_cupcake),
    wl_summary(total_rows(109678), residue_rows(108), _),
    writeln('english_morphology: all receipts passed').

require_webster_store :-
    webster_store_file(Store),
    ( exists_file(Store), current_predicate(wl_summary/3), wl_summary(_, _, _)
    -> true
    ;  format(user_error,
              'Webster lexicon store is absent. Run scripts/language/build_webster_lexicon.py.~n',
              []),
       fail
    ).

must_once(Goal, _Receipt) :- call(Goal), !.
must_once(_Goal, Receipt) :-
    format(user_error, 'english_morphology receipt failed: ~q~n', [Receipt]),
    fail.
