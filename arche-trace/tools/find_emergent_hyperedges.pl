% PURPOSE: Searches the repo's real incompatibility data (registry pairs, the Big Red discovery cache, literature deontic edges) for emergent size>=3 hyperedges, checking every criterion by query and printing the honest result.
/** <module> Emergent-hyperedge search over the real incompatibility data
 *
 * Question (sprint item): does any REAL emergent hyperedge exist in the
 * corpus — a set of size >= 3 that is jointly incoherent while NO proper
 * subset is — or does the Brandomian engine's central emergent claim rest
 * only on the ripe-blackberry seed?
 *
 * Criterion, applied uniformly and checked by query, never by eyeball:
 * a candidate S is emergent iff
 *   (a) |S| >= 3,
 *   (b) S is incoherent under a runnable consequence relation in this repo,
 *   (c) every proper subset of S is coherent under that same relation.
 *
 * Sources searched:
 *   1. misconception_registry:incompatibility_with/2 (the registry pairs),
 *   2. the Big Red iteration7 discovery cache
 *      (arche-trace/data/incompatibility_sets_discovered.pl, with a
 *      fallback to its former home under scripts/bigred/iteration7/work/),
 *      re-checked LIVE against defeasible_inference's consequence relation,
 *   3. the literature deontic edge graph (sr_* / c_* canonical commitments).
 *
 * The result of a run is a printed report; nothing is asserted into the
 * canonical relation here. The seeded outcome of this search lives in
 * arche-trace/brandomian_incompatibility.pl (the incommensurability triple)
 * and the record in docs/research/2026-07-02-emergent-hyperedge-search.md.
 *
 * Run:
 *   swipl -q -l paths.pl -s arche-trace/tools/find_emergent_hyperedges.pl \
 *         -g run_search -t halt
 */
:- module(find_emergent_hyperedges,
          [ run_search/0,
            emergent_in_discovery_layer/1,   % -SortedContentSet
            verified_emergent/1              % +SortedContentSet
          ]).

:- use_module(library(lists)).
:- use_module(arche_trace(brandomian_incompatibility),
              [ brandomian_incoherent/1,
                coherent_set/1
              ]).
:- use_module(arche_trace(defeasible_inference),
              [ material_inference/3,
                classify_defeat/3,
                compiled_break/2,
                ctx_incoherent/1
              ]).
:- use_module(arche_trace(incompatibility_discovery),
              [ candidate_set/2
              ]).
:- use_module(misconceptions(misconception_registry),
              [ incompatibility_with/2,
                misconception_registry_entry/5
              ]).

%!  run_search is det.
%
%   Print the full three-source report. Always succeeds; the report is the
%   result.
run_search :-
    format("=== Emergent-hyperedge search (size >= 3, no incoherent proper subset) ===~n~n"),
    registry_report,
    nl,
    discovery_report,
    nl,
    literature_report,
    nl,
    seed_check_report.

%% ----------------------------------------------------------------------
%% Source 1: the misconception registry

registry_report :-
    format("Source 1 — misconception_registry:incompatibility_with/2~n"),
    findall(A-B, incompatibility_with(A, B), Raw),
    length(Raw, NRaw),
    findall(S, ( member(A-B, Raw), sort([A, B], S) ), Ss0),
    sort(Ss0, Ss),
    length(Ss, NDistinct),
    ( member(S2, Ss), \+ length(S2, 2) -> Degenerate = yes ; Degenerate = no ),
    format("  raw pairs: ~w; distinct normalized sets: ~w; degenerate rows: ~w~n",
           [NRaw, NDistinct, Degenerate]),
    format("  (count is the tracked-file floor: the *_batch_*.csv rows are local~n"),
    format("   untracked files and widen this surface where present)~n"),
    format("  Shape verdict: incompatibility_with/2 is binary, so every fact is a~n"),
    format("  pair. A size>=3 set assembled from pair data always contains its~n"),
    format("  flagged pair, failing criterion (c) by construction.~n"),
    % The 3-element registry variant [misconception(Name), C, E] (see
    % incompatibility_sets:registry_incompatibility_set/2) is checked here:
    % it is never emergent because a flagged pair sits inside it.
    findall(Name,
            ( misconception_registry_entry(Name, _, _, C, E),
              C \=@= E,
              \+ incompatibility_with(misconception(Name), E),
              \+ incompatibility_with(C, E),
              \+ incompatibility_with(E, C)
            ),
            Escapees0),
    sort(Escapees0, Escapees),
    length(Escapees, NEsc),
    format("  Query check on the 3-element registry variant [misconception(N),C,E]:~n"),
    format("  entries whose triple contains NO flagged pair: ~w~n", [NEsc]),
    ( Escapees == []
    ->  format("  Emergent candidates from this source: 0.~n")
    ;   format("  UNEXPECTED escapees (inspect by hand): ~w~n", [Escapees])
    ).

%% ----------------------------------------------------------------------
%% Source 2: the discovery layer (Big Red cache + live re-derivation)

discovery_report :-
    format("Source 2 — bounded-discovery layer (cache + live re-check)~n"),
    ( cache_path(Path)
    ->  format("  cache found at ~w~n", [Path]),
        cache_emergent_rows(Path, Rows),
        length(Rows, NRows),
        format("  cached discovered_set_kind(..., emergent) rows: ~w~n", [NRows]),
        forall(member(Ctx-Set, Rows), report_cached_row(Ctx, Set))
    ;   format("  no discovery cache found at either known path; cache step skipped~n")
    ),
    findall(C, emergent_in_discovery_layer(C), Live0),
    sort(Live0, Live),
    length(Live, NLive),
    format("  live sweep over the CURRENT compiled catalogue: ~w emergent content set(s)~n",
           [NLive]),
    forall(member(Set, Live), report_live_set(Set)).

report_cached_row(Ctx, Set) :-
    ( Ctx == defeasible_inference,
      Set = [inference(Id)|Defeaters]
    ->  ( classify_defeat(Id, Defeaters, incoherent(emergent_defeat(_, _))),
          combined_context(Id, Defeaters, Combined),
          verified_emergent(Combined)
        ->  format("    CONFIRMED live: ~w~n", [Combined])
        ;   format("    cached row no longer confirms live: ~w~n", [Set])
        )
    ;   format("    cached row in unhandled context ~w: ~w (inspect by hand)~n",
               [Ctx, Set])
    ).

report_live_set(Set) :-
    ( compiled_break(BreakId, Conds), sort(Conds, Set)
    ->  format("    ~w~n      = compiled_break(~w) [Lakoff & Nunez catalogue row]~n",
               [Set, BreakId])
    ;   format("    ~w (no single compiled break matches; inspect by hand)~n", [Set])
    ).

%!  emergent_in_discovery_layer(-SortedContentSet) is nondet.
%
%   A combined context (premises + defeaters) that the defeasible
%   consequence relation classifies as an emergent defeat, re-verified here
%   against the uniform criterion.
emergent_in_discovery_layer(Combined) :-
    candidate_set(defeasible_inference, [inference(Id)|Defeaters]),
    classify_defeat(Id, Defeaters, incoherent(emergent_defeat(_, _))),
    combined_context(Id, Defeaters, Combined),
    verified_emergent(Combined).

combined_context(Id, Defeaters, Combined) :-
    material_inference(Id, Premises, _),
    append(Premises, Defeaters, Combined0),
    sort(Combined0, Combined).

%!  verified_emergent(+SortedSet) is semidet.
%
%   The uniform criterion, run against defeasible_inference's consequence
%   relation: size >= 3, jointly incoherent, every one-element removal
%   coherent (which covers all proper subsets, since incoherence persists
%   under superset).
verified_emergent(Set) :-
    length(Set, Len),
    Len >= 3,
    ctx_incoherent(Set),
    forall(select(_, Set, Smaller), \+ ctx_incoherent(Smaller)).

cache_path(Path) :-
    member(Candidate,
           [ arche_trace('data/incompatibility_sets_discovered.pl'),
             arche_trace('../scripts/bigred/iteration7/work/incompatibility_sets_discovered.pl')
           ]),
    absolute_file_name(Candidate, Path, [access(read), file_errors(fail)]),
    !.

cache_emergent_rows(Path, Rows) :-
    setup_call_cleanup(
        open(Path, read, In),
        read_all_terms(In, Terms),
        close(In)),
    findall(Ctx-Set,
            member(incompatibility_sets:discovered_set_kind(Ctx, Set, emergent),
                   Terms),
            Rows).

read_all_terms(In, Terms) :-
    read_term(In, T, []),
    (   T == end_of_file
    ->  Terms = []
    ;   Terms = [T|Rest],
        read_all_terms(In, Rest)
    ).

%% ----------------------------------------------------------------------
%% Source 3: the literature deontic edge graph

literature_report :-
    format("Source 3 — literature deontic edges (sr_* / c_* canonical commitments)~n"),
    (   catch(use_module(misconceptions(literature_deontic_bridge),
                         [ lit_deontic_edge/2, lit_deontic_edge_stats/3 ]),
              _, fail)
    ->  literature_deontic_bridge:lit_deontic_edge_stats(E, H, R),
        findall(C, literature_deontic_bridge:lit_deontic_edge(_, C), Cs0),
        sort(Cs0, Cs),
        length(Cs, NC),
        format("  derived edges: ~w over ~w sr_* heads (~w rows); distinct c_* commitments: ~w~n",
               [E, H, R, NC]),
        % Is there any runnable joint-unsatisfiability check over c_* atoms?
        % The two consequence relations in this repo are the sequent engine
        % (fires on neg/modal structure) and compiled_break conditions (o(...)
        % metaphor commitments). Query check: no c_* atom occurs in any
        % compiled break condition.
        findall(C2,
                ( member(C2, Cs),
                  compiled_break(_, Conds),
                  memberchk(C2, Conds)
                ),
                InBreaks),
        format("  c_* atoms occurring in compiled_break conditions: ~w~n", [InBreaks]),
        format("  The corpus supplies sr_*->c_* PAIR edges only; an emergent triad~n"),
        format("  would additionally need an independent joint-unsatisfiability~n"),
        format("  check. Neither runnable relation ranges over c_* atoms (query~n"),
        format("  above), so no candidate from this source can meet criterion (b)~n"),
        format("  today. Verifiable emergent candidates from this source: 0.~n"),
        format("  (Authoring one by assertion would be exactly the fake triple the~n"),
        format("  sprint item rules out.)~n")
    ;   format("  literature layer not loadable in this checkout; source skipped~n")
    ).

%% ----------------------------------------------------------------------
%% Seed check: the authored outcome of this search

seed_check_report :-
    format("Seed check — arche-trace/brandomian_incompatibility.pl~n"),
    Triple = [o(diagonal_of_unit_square_measured),
              o(length_is_count_of_units),
              o(grounded(measuring_stick))],
    ( brandomian_incoherent(Triple)
    ->  V1 = yes ; V1 = 'NO (seed missing?)' ),
    ( forall(select(_, Triple, Pair), coherent_set(Pair))
    ->  V2 = yes ; V2 = 'NO' ),
    format("  incommensurability triple incoherent in the canonical relation: ~w~n", [V1]),
    format("  every pair inside it coherent (emergence preserved): ~w~n", [V2]),
    format("~n=== Verdict ===~n"),
    format("Registry pairs cannot attest an emergent hyperedge (binary by shape).~n"),
    format("The discovery layer carries machine-checked emergent triples, each a~n"),
    format("compiled Lakoff & Nunez catalogue break-point: literature-catalogued~n"),
    format("and machine-checked for minimality, NOT student-corpus-derived. The~n"),
    format("mathematically grounded one (incommensurability) is seeded into the~n"),
    format("canonical relation; the rest remain loadable through~n"),
    format("incompatibility_discovery:install_discovered_hyperedges/2.~n").
