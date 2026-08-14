:- encoding(utf8).
/** <module> Consultation-loop admitted lexicon pilot
 *
 * Rows in this quarantined store begin with the five fields used by
 * lexicon_supplement_pilot:ls_word/5.  Two additional fields retain the
 * model testimony and the deterministic SWI-Prolog admission receipt.
 * The consultation driver appends rows below the generated-region marker.
 *
 * Check from the repository root:
 * `swipl -q -l paths.pl -l knowledge/strategies/abstraction/lexicon_loop_admitted_pilot.pl -g lexicon_loop_admitted_pilot:check_lexicon_loop_admitted -t halt`
 */

:- module(lexicon_loop_admitted_pilot,
          [ loop_admitted_word/7,
            lexicon_loop_admitted_summary/1,
            gate_candidate/7,
            check_lexicon_loop_admitted/0
          ]).

:- use_module(library(readutil), [read_file_to_string/3]).
:- use_module('english_morphology.pl').
:- use_module('lexicon_supplement_pilot.pl',
              [ls_word/5, lexicon_supplement_summary/1]).
:- use_module('word_problem_reader_pilot.pl',
              [check_word_problem_reader_pilot/0]).

:- dynamic loop_admitted_word/7.
:- dynamic pending_candidate/5.
:- dynamic loop_store_directory/1.
:- prolog_load_context(directory, Here), assertz(loop_store_directory(Here)).

% Class meanings are owned by lexicon_supplement_pilot.pl.  This store reads
% the live class census rather than copying a second class vocabulary.
loop_class(Class) :-
    lexicon_supplement_summary(
        summary(_, _, _, _, _, class_counts(Counts))),
    member(CountTerm, Counts),
    functor(CountTerm, Class, 1).

lexicon_loop_admitted_summary(
    summary(role(orphan_consultation_lexicon), word_rows(Count),
            model(sidekick_wave5_q4km), classes(by_reference_to_supplement))) :-
    aggregate_all(count, loop_admitted_word(_, _, _, _, _, _, _), Count).

%! gate_candidate(+Word,+Class,+Morphology,+Evidence,+Rationale,+Consultation,-Verdict)
%
%  Assert a candidate for the duration of its checks.  Verdict names the first
%  failed check, or returns the complete receipt list used in an admitted row.
gate_candidate(Word, Class, Morphology, Evidence, Rationale, Consultation,
               Verdict) :-
    setup_call_cleanup(
        assertz(pending_candidate(Word, Class, Morphology, Evidence, Rationale), Ref),
        candidate_verdict(Word, Class, Morphology, Evidence, Consultation, Verdict),
        erase(Ref)).

candidate_verdict(Word, Class, Morphology, Evidence, Consultation, Verdict) :-
    Checks = [no_class_conflict, morphology_round_trip, source_span_bound,
              relevant_pilot_check],
    ( first_failed_check(Checks, Word, Class, Morphology, Evidence, Consultation,
                         Failed)
    -> Verdict = rejected(Failed)
    ;  Verdict = passed(Checks)
    ).

first_failed_check([Check|_], W, C, M, E, Id, Check) :-
    \+ admission_check(Check, W, C, M, E, Id), !.
first_failed_check([_|Checks], W, C, M, E, Id, Failed) :-
    first_failed_check(Checks, W, C, M, E, Id, Failed).

admission_check(no_class_conflict, Word, Class, _, _, _) :-
    atom(Word), atom(Class), loop_class(Class),
    \+ ls_word(Word, _, _, _, _),
    \+ em_category(Word, _),
    \+ em_word_class(Word, _),
    \+ loop_admitted_word(Word, _, _, _, _, _, _).
admission_check(morphology_round_trip, Word, Class, Morphology, _, _) :-
    valid_morphology(Class, Morphology),
    morphology_contains_surface(Word, Morphology).
admission_check(source_span_bound, Word, _, _, Evidence, _) :-
    evidence_span(Evidence, Source, Sentence, Start, End),
    integer(Start), integer(End), Start >= 0, End > Start,
    Length is End - Start,
    sub_string(Sentence, Start, Length, _, Surface),
    string_lower(Surface, Lower), atom_string(Word, Lower),
    repository_file(Source, SourceFile), exists_file(SourceFile),
    read_file_to_string(SourceFile, Content, []),
    sub_string(Content, _, _, _, Sentence).
admission_check(relevant_pilot_check, _, _, _, _, _) :-
    with_output_to(string(_), check_word_problem_reader_pilot).

valid_morphology(Class, none) :-
    memberchk(Class, [given_name, family_name, place_name, named_entity,
                      tokenizer_artifact, contraction_fragment]).
valid_morphology(_, forms(invariant)).
valid_morphology(Class, forms(noun(Singular, Plural))) :-
    memberchk(Class, [common_noun, math_term, pedagogy_term, temporal_word]),
    atom(Singular), atom(Plural).
valid_morphology(corpus_verb, forms(verb(Base, Third, Past, Ing, Participle))) :-
    maplist(atom, [Base, Third, Past, Ing, Participle]).
valid_morphology(unit_abbreviation, expands_to(Full)) :-
    atom(Full), english_morphology:em_noun_base(Full, _).

morphology_contains_surface(Word, none) :- atom(Word).
morphology_contains_surface(Word, forms(invariant)) :- atom(Word).
morphology_contains_surface(Word, forms(noun(Singular, Plural))) :-
    memberchk(Word, [Singular, Plural]).
morphology_contains_surface(Word, forms(verb(Base, Third, Past, Ing, Participle))) :-
    memberchk(Word, [Base, Third, Past, Ing, Participle]).
morphology_contains_surface(Word, expands_to(_)) :- atom(Word).

evidence_span(evidence(guide_span(Source, _SentenceIndex, Sentence, Start, End)),
              Source, Sentence, Start, End) :-
    atom(Source), string(Sentence).

repository_file(Relative, Absolute) :-
    loop_store_directory(Here),
    directory_file_path(Here, '../../..', Repo0),
    absolute_file_name(Repo0, Repo, [file_type(directory), access(read)]),
    directory_file_path(Repo, Relative, Absolute).

check_lexicon_loop_admitted :-
    findall(W, loop_admitted_word(W, _, _, _, _, _, _), Words),
    sort(Words, Unique), length(Words, Count), length(Unique, Count),
    forall(loop_admitted_word(W, C, M, E, R, T, Receipt),
           check_stored_row(W, C, M, E, R, T, Receipt)),
    format('lexicon_loop_admitted_pilot: all ~d row receipts passed~n', [Count]).

check_stored_row(Word, Class, Morphology, Evidence, Rationale,
                 testimony(model(sidekick_wave5_q4km), consultation(Id)),
                 receipt(swipl_test(Checks))) :-
    string(Rationale), Rationale \== "", atom(Id),
    Checks == [no_class_conflict, morphology_round_trip, source_span_bound,
               relevant_pilot_check],
    % For a stored row, exclude the row itself from the cross-store check.
    loop_class(Class),
    \+ ls_word(Word, _, _, _, _),
    \+ em_category(Word, _),
    \+ em_word_class(Word, _),
    valid_morphology(Class, Morphology),
    morphology_contains_surface(Word, Morphology),
    admission_check(source_span_bound, Word, Class, Morphology, Evidence, Id),
    admission_check(relevant_pilot_check, Word, Class, Morphology, Evidence, Id).

% GENERATED ROWS FOLLOW. The consultation driver appends only after gate_candidate/7.
