/** <module> Deterministic commitment matcher: reading content -> canonical terms
 *
 * Stage 1 of the implicit-commitment join (docs/proposals/
 * 2026-06-29-implicit-commitment-join.md). The deontic scoreboard layer used
 * to wrap free reading content as pml_commitment("...") — an atom the
 * scorekeeper's incompatible/2 can never match, so the join ran but could not
 * find a real incoherence. This module is the missing conversion: content
 * text becomes typed canonical commitment terms the deontic layer has rules
 * for, or nothing at all.
 *
 * The discipline is admission-gate, not similarity search: a candidate is
 * admitted only when EVERY token of its canonical name appears as a whole
 * word in the content (content words are lightly normalized: lowercased,
 * long plurals reduced). No fuzzy scores, no nearest-neighbor — a content
 * that names no registered term yields []. The model may propose prose; this
 * decides what the prose commits its speaker to, and abstains by default.
 *
 * Candidate vocabularies:
 *   - misconception(Name) for each misconception_registry entry
 *   - strategy(Operation, Kind) for each action-automata cluster row
 *
 * Matches rank by name-token count (more specific names first), so a content
 * that carries both "count all when count on available" and "count on"
 * surfaces the misconception before the strategy fragment.
 */
:- module(commitment_matcher,
          [ match_commitment/2,          % +ContentText, -CanonicalTerms
            match_commitment_witness/3   % +ContentText, ?Term, -Witness
          ]).

:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(misconceptions(misconception_registry), []).
:- use_module(strategies(math/action_automata_registry), []).

%!  match_commitment(+ContentText, -CanonicalTerms) is det.
%
%   All admitted canonical terms for the content, most specific first.
%   [] when nothing is admitted — abstention is the default verdict.
match_commitment(Content, Terms) :-
    findall(N-Term,
            ( match_commitment_witness(Content, Term, Witness),
              get_dict(matched_tokens, Witness, Tokens),
              length(Tokens, N)
            ),
            Scored0),
    sort(1, @>=, Scored0, Scored),
    findall(Term, member(_-Term, Scored), Terms0),
    list_to_set(Terms0, Terms).

%!  match_commitment_witness(+ContentText, ?Term, -Witness) is nondet.
%
%   Term is admitted for the content; Witness records which name tokens
%   carried the admission and which vocabulary the term comes from.
match_commitment_witness(Content, Term, Witness) :-
    content_words(Content, Words),
    Words \== [],
    ensure_candidate_cache,
    candidate_cache(Term, Source, NameTokens),
    NameTokens \== [],
    forall(member(T, NameTokens), memberchk(T, Words)),
    Witness = _{ kind: commitment_match,
                 term_source: admission_gate_all_name_tokens_present,
                 source: Source,
                 matched_tokens: NameTokens }.

%% ---------------------------------------------------------------------------
%% Candidate vocabularies. The table is computed once per process: the
%% registries are static after load, and a scored run calls the matcher once
%% per event, so re-deriving ~1,900 candidates per call is pure waste.

:- dynamic candidate_cache/3.

ensure_candidate_cache :-
    ( candidate_cache(_, _, _) -> true
    ; forall(candidate_term(Term, Source, Tokens),
             assertz(candidate_cache(Term, Source, Tokens)))
    ).

candidate_term(misconception(Name), misconception_registry, Tokens) :-
    misconception_registry:misconception_registry_entry(Name, _, _, _, _),
    name_tokens(Name, Tokens).
candidate_term(strategy(Operation, Kind), action_automata_registry, Tokens) :-
    action_automata_registry:action_automaton_cluster(Operation, Kind, _),
    name_tokens(Kind, Tokens).

name_tokens(Name, Tokens) :-
    atomic_list_concat(Tokens0, '_', Name),
    exclude(==(''), Tokens0, Tokens).

%% ---------------------------------------------------------------------------
%% Content normalization: lowercase word atoms; long plurals reduced so
%% "counts" admits the name token "count" while short words ("is", "as")
%% stay untouched.

content_words(Content, Words) :-
    ( atom(Content) -> atom_string(Content, S) ; S = Content ),
    string_lower(S, Lower),
    split_string(Lower, " \t\n.,;:!?()[]{}\"'/+*=-", "", Parts),
    findall(W,
            ( member(P, Parts),
              P \== "",
              normalized_word(P, W)
            ),
            Words0),
    list_to_set(Words0, Words).

%!  normalized_word(+Part, -Word) is multi.
%
%   Every content word admits itself; words longer than four characters that
%   end in "s" also admit their singular, so plural prose matches singular
%   name tokens without a stemmer's false positives on short words.
normalized_word(P, W) :-
    atom_string(W, P).
normalized_word(P, W) :-
    string_length(P, L),
    L > 4,
    sub_string(P, _, 1, 0, "s"),
    sub_string(P, 0, _, 1, Stem),
    atom_string(W, Stem).
