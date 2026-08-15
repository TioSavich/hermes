:- encoding(utf8).
/** <module> Lexical typing store seam
 *
 * A neutral loading seam for lexical typing rows: judgments about what a
 * verb lemma does to a counted holding (asserts a first state, names a
 * gain or a loss, names a transfer, names a factor). The rows themselves
 * are a gitignored runtime artifact whose licensing is decided outside
 * this repository; tracked code holds only this seam and its vocabulary.
 *
 * Unlike the webster lexicon seam, absence here is LOUD: a missing store
 * prints one warning at load, and lexical_typing_store_present/1 lets the
 * harness record which condition a run measured. A run without the store
 * still works — every open-frame verb then compiles to a bare quantity —
 * but its numbers are not comparable to a run with it, and the ledger
 * must be able to say which one it was.
 *
 * Check from the repository root:
 * swipl -q -l paths.pl -l knowledge/strategies/abstraction/lexical_typing_store.pl -g lexical_typing_store:check_lexical_typing_store -t halt
 */

:- module(lexical_typing_store,
          [ lexical_typing/2,
            lexical_typing_row/4,
            lexical_typing_store_present/1,
            lexical_typing_vocabulary/1,
            check_lexical_typing_store/0
          ]).

:- dynamic typed_lemma/4.
:- dynamic store_file_loaded/1.

lexical_typing_vocabulary([first_state, gain, loss, transfer, factor]).

store_relative_path('../../../hermes/app/runtime/experiments/language/lexical_typings.pl').

:- prolog_load_context(directory, Here),
   store_relative_path(Relative),
   absolute_file_name(Relative, Absolute, [relative_to(Here)]),
   (   exists_file(Absolute)
   ->  ensure_loaded(Absolute),
       assertz(store_file_loaded(true))
   ;   assertz(store_file_loaded(false)),
       print_message(warning,
           format("lexical_typing_store: no typing rows at ~w; open-frame verbs will compile to bare quantities and harness numbers are not comparable to a run with the store", [Absolute]))
   ).

%! lexical_typing(?Lemma, ?Typing) is nondet.
%
%  The consulting form the reader compiles against.
lexical_typing(Lemma, Typing) :-
    typed_lemma(Lemma, Typing, _Receipt, _Attribution).

%! lexical_typing_row(?Lemma, ?Typing, ?Receipt, ?Attribution) is nondet.
lexical_typing_row(Lemma, Typing, Receipt, Attribution) :-
    typed_lemma(Lemma, Typing, Receipt, Attribution).

%! lexical_typing_store_present(-Present) is det.
%
%  Whether the gitignored row store was found at load time. Consumers
%  record this beside any measurement they report.
lexical_typing_store_present(Present) :-
    ( store_file_loaded(Present) -> true ; Present = false ).

%! check_lexical_typing_store is semidet.
%
%  With the store absent the seam itself still passes: an empty store is a
%  legal, loudly-announced condition. Every present row must be well
%  formed and carry the seam vocabulary.
check_lexical_typing_store :-
    lexical_typing_vocabulary(Vocabulary),
    aggregate_all(count, typed_lemma(_, _, _, _), Count),
    forall(typed_lemma(Lemma, Typing, receipt(Sentence, Anchor), Attribution),
           ( atom(Lemma),
             memberchk(Typing, Vocabulary),
             string(Sentence), Sentence \== "",
             ground(Anchor),
             Attribution = attributed(_, _)
           )),
    lexical_typing_store_present(Present),
    format("check_lexical_typing_store: ok rows=~w store_present=~w~n",
           [Count, Present]).
