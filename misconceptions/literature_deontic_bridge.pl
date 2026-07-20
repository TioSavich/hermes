/** <module> Literature -> deontic scorekeeper edge graph
 *
 * The normalized literature layer (`literature_vocabulary.pl`) already feeds
 * the deontic scorekeeper one `incompatible/2` clause per corpus row, in the
 * row-shaped form
 *
 *     incompatible(applies_rule(Rule, in_context(C)), normative_commitment(C))
 *
 * That chain is a catalog: it fires only when the querying side already
 * carries the row's own context term. What it does not give the scorekeeper
 * is a graph over canonical vocabulary — a bounded set of edges from an
 * `sr_*` head student rule to the `c_*` commitments the corpus says that rule
 * collides with, usable when a diagnosis knows the rule but not the row.
 *
 * This module derives that graph. An edge `SrRule -> Commitment` exists when
 * at least one corpus row passes ALL of these gates:
 *
 *   - confidence   == high        (the analysis pass was confident),
 *   - orientation  == deficit     (the row reads the rule as a deficit,
 *                                  not a productive or mixed resource),
 *   - canonical domain in {fraction, decimal, whole_number},
 *   - the raw `incompatible_with` atom maps through `commitment_map/2`
 *     to a canonical `c_*` commitment (not `uncategorized`),
 *   - the raw `student_rule` atom maps through `canonical_student_rule/2`
 *     to an `sr_*` head atom (i.e. it sits in
 *     `literature_student_rule_map:student_rule_map/2`; pass-through
 *     singletons never form edges).
 *
 * Each gate discards real corpus content on purpose: low-confidence rows,
 * productive orientations, tail domains, and unclustered rules stay in the
 * catalog and out of the graph. The graph is the narrow, high-agreement
 * slice; `lit_deontic_edge_row/3` keeps the row-level derivation queryable
 * so the narrowing is auditable rather than baked in.
 *
 * Scorekeeper wiring. The graph contributes multifile clauses in the shape
 * `deontic_scorekeeper` consumes (see the `incompatible/2` seeds and
 * `requires_entitlement_fact/1` in `formal/learner/deontic_scorekeeper.pl`):
 *
 *     incompatible(applies_rule(SrRule), normative_commitment(C))
 *     requires_entitlement_fact(applies_rule(SrRule))
 *
 * `applies_rule/1` is deliberately context-free, distinct from the catalog's
 * `applies_rule/2`: an agent committed to the head rule as such (the usual
 * situation when a rule is diagnosed from talk) is incoherent-without-
 * entitlement, and entitlement to the rule alongside entitlement to a
 * colliding `c_*` commitment registers as `entitlement_to_incompatible/2`.
 * Both argument orders are provided, matching the scorekeeper's own
 * both-direction convention for its registry-backed pairs.
 *
 * Hyperedge seeding (opt-in, audited). Loading this module still asserts
 * nothing into `brandomian_incompatibility:incompatible_set/1`; the graph
 * reaches the Brandomian engine only through an explicit call to
 * `install_lit_incompatible_sets/1`, which lifts each derived edge into a
 * two-member hyperedge `[applies_rule(SrRule), normative_commitment(C)]`
 * and then audits the mutated relation through the union bridge's explosion
 * backstop (`sequent_brandom_bridge:brandom_backstop/1`). A failed backstop
 * check retracts every seeded hyperedge and throws, so a bad install leaves
 * no residue; `uninstall_lit_incompatible_sets/1` is the symmetric explicit
 * removal. After a clean install, `b_incoherent/1` and the scorekeeper's
 * `hyperedge_incoherence/1` fire on literature commitment pairs, not only
 * on the engine's illustration seeds. One data property to keep named: two `sr_*`
 * heads whose edges collide with the same `c_*` commitments become
 * inter-entailing under `incompatibility_entails/2` — the finite-data
 * behavior `brandomian_incompatibility` documents, not explosion; the
 * backstop's fresh-probe checks stay clean either way.
 *
 * Content matching (Stage-1 seam for the PML deontic scoreboard layer).
 * `lit_deontic_content_match/2` maps free reading content to the canonical
 * commitment terms this graph has rules for — `applies_rule(sr_*)` and
 * `normative_commitment(c_*)` — through the existing canonicalizers
 * (`canonical_student_rule/2`, `normalized_commitment/2`). The admission
 * gate is deliberately strict (every name token of an attested raw spelling
 * must occur in the content), strictly stronger than the encyclopedia's
 * two-distinct-token floor: no match beats a wrong commitment, so [] is the
 * default verdict. The gate is bag-of-words and negation-blind; admitted
 * terms are candidate commitments for the scorekeeper to adjudicate, not
 * final verdicts.
 *
 * This module is a NON-DEFAULT load, in the same register as
 * `sequent_brandom_bridge.pl`: loading `deontic_scorekeeper` or
 * `literature_vocabulary` does not load this, and without it the
 * scorekeeper's behavior is exactly what it was. Callers that want the
 * graph (the Hermes encyclopedia is one) `use_module` it explicitly.
 */
:- module(literature_deontic_bridge,
          [ lit_deontic_edge/2,          % ?SrRule, ?Commitment
            lit_deontic_edge/3,          % ?SrRule, ?Commitment, ?SupportIds
            lit_deontic_edge_row/3,      % ?Id, ?SrRule, ?Commitment
            lit_deontic_edge_count/1,    % -Count
            lit_deontic_edge_stats/3,    % -EdgeCount, -HeadCount, -RowCount
            lit_deontic_probe/2,         % +SrRule, -Verdict
            refresh_lit_deontic_edges/0,
            lit_incompatible_hyperedge/1,       % ?Set
            install_lit_incompatible_sets/1,    % -Count
            uninstall_lit_incompatible_sets/1,  % -Count
            lit_deontic_content_match/2,        % +Content, -Terms
            lit_deontic_content_match_witness/3,% +Content, ?Term, -Witness
            lit_deontic_content_match_files/2   % +InJsonFile, +OutJsonFile
          ]).

:- use_module(misconceptions(literature_vocabulary),
              [ lit_incompatibility/7,
                canonical_student_rule/2,
                normalized_commitment/2,
                domain_map/2
              ]).
:- use_module(misconceptions(literature_student_rule_map),
              [ student_rule_map/2
              ]).
:- use_module(misconceptions(literature_incompatibility_facts),
              [ lit_derived/9
              ]).
:- use_module(learner(deontic_scorekeeper),
              [ reset_scorekeeper/1,
                undertake_commitment/2,
                deontic_incoherent/2
              ]).
:- use_module(incompat(brandomian_incompatibility),
              [ add_incompatible_set/1,
                retract_incompatible_set/1
              ]).
:- use_module(library(http/json), [ json_read_dict/2, json_write_dict/2 ]).

:- multifile deontic_scorekeeper:incompatible/2.
:- multifile deontic_scorekeeper:requires_entitlement_fact/1.


%% ----------------------------------------------------------------------
%% Row-level derivation (uncached, auditable)

%!  lit_deontic_edge_row(?Id, ?SrRule, ?Commitment) is nondet.
%
%   One corpus row supporting the edge SrRule -> Commitment, after all five
%   gates (module header). The row keeps its corpus Id so a consumer can get
%   back to `lit_derived_meta/4` citations and glosses. `student_rule_map/2`
%   membership is the head check: `canonical_student_rule/2` agrees on every
%   mapped atom and additionally passes unmapped atoms through, which is
%   exactly what an edge must not do.
lit_deontic_edge_row(Id, SrRule, Commitment) :-
    lit_incompatibility(Id, Domain, Commitment, RawRule, _ValidDomain,
                        deficit, high),
    memberchk(Domain, [fraction, decimal, whole_number]),
    Commitment \== uncategorized,
    sub_atom(Commitment, 0, _, _, c_),
    student_rule_map(RawRule, SrRule).


%% ----------------------------------------------------------------------
%% The edge graph (cached)
%%
%% The row scan walks the whole generated corpus through the fuzzy
%% commitment_map rules, so the distinct-edge view is materialized once per
%% session. `refresh_lit_deontic_edges/0` rebuilds it if the underlying
%% corpus or maps change in-session (they are static files in ordinary use).

:- dynamic lit_deontic_edge_cache/3.

%!  lit_deontic_edge(?SrRule, ?Commitment, ?SupportIds) is nondet.
%
%   Distinct derived edge with the sorted list of corpus row Ids supporting
%   it. SupportIds is never [] — an edge exists only through rows.
lit_deontic_edge(SrRule, Commitment, SupportIds) :-
    ensure_edge_cache,
    lit_deontic_edge_cache(SrRule, Commitment, SupportIds).

%!  lit_deontic_edge(?SrRule, ?Commitment) is nondet.
lit_deontic_edge(SrRule, Commitment) :-
    lit_deontic_edge(SrRule, Commitment, _SupportIds).

%!  lit_deontic_edge_count(-Count) is det.
lit_deontic_edge_count(Count) :-
    lit_deontic_edge_stats(Count, _HeadCount, _RowCount).

%!  lit_deontic_edge_stats(-EdgeCount, -HeadCount, -RowCount) is det.
%
%   EdgeCount distinct edges over HeadCount distinct sr_* heads, supported
%   by RowCount corpus rows in total.
lit_deontic_edge_stats(EdgeCount, HeadCount, RowCount) :-
    ensure_edge_cache,
    findall(Sr-Ids, lit_deontic_edge_cache(Sr, _, Ids), Pairs),
    length(Pairs, EdgeCount),
    pairs_keys(Pairs, Srs0),
    sort(Srs0, Srs),
    length(Srs, HeadCount),
    pairs_values(Pairs, IdLists),
    foldl([Ids, A0, A]>>(length(Ids, L), A is A0 + L), IdLists, 0, RowCount).

%!  refresh_lit_deontic_edges is det.
%
%   Also drops the content-candidate cache, which is derived from the same
%   edge set.
refresh_lit_deontic_edges :-
    retractall(lit_deontic_edge_cache(_, _, _)),
    retractall(content_candidate_cache(_, _, _, _)),
    ensure_edge_cache.

ensure_edge_cache :-
    lit_deontic_edge_cache(_, _, _),
    !.
ensure_edge_cache :-
    findall((SrRule-Commitment)-Id,
            lit_deontic_edge_row(Id, SrRule, Commitment),
            Rows0),
    keysort(Rows0, Rows),
    group_pairs_by_key(Rows, Grouped),
    forall(member((SrRule-Commitment)-Ids0, Grouped),
           ( sort(Ids0, Ids),
             assertz(lit_deontic_edge_cache(SrRule, Commitment, Ids))
           )).

:- use_module(library(pairs), [ pairs_keys/2, pairs_values/2,
                                group_pairs_by_key/2 ]).
:- use_module(library(apply), [ foldl/4 ]).
:- use_module(library(yall)).


%% ----------------------------------------------------------------------
%% Scorekeeper wiring (multifile contributions; only when this module
%% is loaded)

deontic_scorekeeper:incompatible(applies_rule(SrRule),
                                 normative_commitment(Commitment)) :-
    lit_deontic_edge(SrRule, Commitment, _SupportIds).
deontic_scorekeeper:incompatible(normative_commitment(Commitment),
                                 applies_rule(SrRule)) :-
    lit_deontic_edge(SrRule, Commitment, _SupportIds).

deontic_scorekeeper:requires_entitlement_fact(applies_rule(SrRule)) :-
    lit_deontic_edge(SrRule, _Commitment, _SupportIds).


%% ----------------------------------------------------------------------
%% Probe: run the scorekeeper over one head rule

%!  lit_deontic_probe(+SrRule, -Verdict) is semidet.
%
%   Exercise the scorekeeper on a scratch agent: undertake the bare
%   commitment `applies_rule(SrRule)` and ask whether the agent is
%   incoherent for lacking entitlement. Verdict is
%   `commitment_without_entitlement` when the incoherence registers and
%   `coherent` otherwise. Fails when SrRule heads no derived edge — the
%   probe only speaks for the graph. Scratch state is cleaned up either
%   way; no caller-visible deontic state survives the call.
lit_deontic_probe(SrRule, Verdict) :-
    once(lit_deontic_edge(SrRule, _, _)),
    Agent = lit_deontic_bridge_probe_agent_9z,
    setup_call_cleanup(
        reset_scorekeeper(Agent),
        ( undertake_commitment(Agent, applies_rule(SrRule)),
          (   deontic_incoherent(Agent,
                  commitment_without_entitlement(applies_rule(SrRule)))
          ->  Verdict = commitment_without_entitlement
          ;   Verdict = coherent
          )
        ),
        reset_scorekeeper(Agent)).


%% ----------------------------------------------------------------------
%% Opt-in hyperedge seeding into the Brandomian engine
%%
%% Each derived edge lifts to a two-member hyperedge. Seeding is an explicit
%% act, never a load-time side effect: callers that want b_incoherent/1 and
%% hyperedge_incoherence/1 to cover literature commitment pairs call
%% install_lit_incompatible_sets/1 and accept the backstop audit that comes
%% with it.

%!  lit_incompatible_hyperedge(?Set) is nondet.
%
%   The hyperedge form of one derived edge: the sorted two-member set
%   [applies_rule(SrRule), normative_commitment(C)]. This is a derived view;
%   nothing is asserted until install_lit_incompatible_sets/1 runs.
lit_incompatible_hyperedge(Set) :-
    lit_deontic_edge(SrRule, Commitment, _SupportIds),
    msort([applies_rule(SrRule), normative_commitment(Commitment)], Set).

%!  install_lit_incompatible_sets(-Count) is det.
%
%   Seed every derived hyperedge into
%   `brandomian_incompatibility:incompatible_set/1`, then audit the mutated
%   relation through `sequent_brandom_bridge:brandom_backstop/1`. If any
%   backstop check fails, every seeded hyperedge is retracted again and the
%   predicate throws `lit_deontic_backstop_failed(Report)`, so a failed
%   install leaves the engine exactly as it was. Count is the number of
%   derived hyperedges; repeated installs are idempotent
%   (`add_incompatible_set/1` skips sets already present).
install_lit_incompatible_sets(Count) :-
    findall(Set, lit_incompatible_hyperedge(Set), Sets0),
    sort(Sets0, Sets),
    forall(member(Set, Sets), add_incompatible_set(Set)),
    ensure_backstop_loaded,
    (   sequent_brandom_bridge:brandom_backstop_ok
    ->  true
    ;   sequent_brandom_bridge:brandom_backstop(Report),
        uninstall_lit_incompatible_sets(_Removed),
        throw(error(lit_deontic_backstop_failed(Report),
                    install_lit_incompatible_sets/1))
    ),
    length(Sets, Count).

%!  uninstall_lit_incompatible_sets(-Count) is det.
%
%   Retract every derived hyperedge from the engine. Count is the number of
%   derived hyperedges (whether or not each was present). If another caller
%   asserted an identical set independently, this removes it too — the
%   hyperedge, not its provenance, is what the engine stores.
uninstall_lit_incompatible_sets(Count) :-
    findall(Set, lit_incompatible_hyperedge(Set), Sets0),
    sort(Sets0, Sets),
    forall(member(Set, Sets), retract_incompatible_set(Set)),
    length(Sets, Count).

% The union bridge (and through it the classical sequent engine) loads only
% when an install actually runs, keeping this module's load-time footprint
% unchanged for consumers such as the encyclopedia.
ensure_backstop_loaded :-
    use_module(incompat(sequent_brandom_bridge), []).


%% ----------------------------------------------------------------------
%% Conservative content matcher (Stage-1 seam for the scoreboard layer)
%%
%% Candidate vocabulary is exactly the gated edge set's attested spelling:
%%   - every raw `student_rule` spelling in student_rule_map/2 whose sr_*
%%     canonical heads a derived edge (canonicalized via
%%     canonical_student_rule/2), admitting applies_rule(SrRule);
%%   - every raw `incompatible_with` atom on a row that passes all five
%%     edge gates (canonicalized via normalized_commitment/2), admitting
%%     normative_commitment(C).
%% Admission requires every name token of the raw spelling to occur in the
%% content (after shared light plural/verb-s stemming) and at least three
%% name tokens: a bare topic mention ("fraction addition") states no rule
%% and no entitlement, so two-token spellings never admit anything.

:- dynamic content_candidate_cache/4.   % Term, RawAtom, Source, NameTokens

%!  lit_deontic_content_match(+Content, -Terms) is det.
%
%   All admitted canonical commitment terms for the content, ranked by name
%   token count (more specific spellings first), duplicates removed. [] when
%   nothing is admitted — abstention is the default verdict.
lit_deontic_content_match(Content, Terms) :-
    findall(N-Term,
            ( lit_deontic_content_match_witness(Content, Term,
                                                witness(_, _, Tokens)),
              length(Tokens, N)
            ),
            Scored0),
    sort(1, @>=, Scored0, Scored),
    findall(Term, member(_-Term, Scored), Terms0),
    list_to_set(Terms0, Terms).

%!  lit_deontic_content_match_witness(+Content, ?Term, -Witness) is nondet.
%
%   Term is admitted for the content. Witness is
%   witness(RawAtom, Source, NameTokens): the attested spelling that carried
%   the admission, its vocabulary (student_rule_map or edge_row_commitment),
%   and the matched (stemmed) name tokens.
lit_deontic_content_match_witness(Content, Term,
                                  witness(Raw, Source, NameTokens)) :-
    match_content_words(Content, Words),
    Words \== [],
    ensure_content_candidates,
    content_candidate_cache(Term, Raw, Source, NameTokens),
    forall(member(T, NameTokens), memberchk(T, Words)).

%!  lit_deontic_content_match_files(+InJsonFile, +OutJsonFile) is det.
%
%   Batch seam for the Python scoreboard layer: InJsonFile holds a JSON
%   array of content strings; OutJsonFile receives a JSON array of
%   {content, terms} objects, terms serialized with term_to_atom/2. One
%   process serves a whole batch, so callers do not pay module load once
%   per content.
lit_deontic_content_match_files(InJsonFile, OutJsonFile) :-
    setup_call_cleanup(open(InJsonFile, read, In),
                       json_read_dict(In, Contents),
                       close(In)),
    must_be(list, Contents),
    findall(_{content: Content, terms: TermAtoms},
            ( member(Content, Contents),
              lit_deontic_content_match(Content, Terms),
              findall(A,
                      ( member(T, Terms), term_to_atom(T, A) ),
                      TermAtoms)
            ),
            Rows),
    setup_call_cleanup(open(OutJsonFile, write, Out),
                       json_write_dict(Out, Rows),
                       close(Out)).

ensure_content_candidates :-
    content_candidate_cache(_, _, _, _),
    !.
ensure_content_candidates :-
    forall(content_candidate(Term, Raw, Source, Tokens),
           assertz(content_candidate_cache(Term, Raw, Source, Tokens))).

content_candidate(applies_rule(SrRule), Raw, student_rule_map, Tokens) :-
    student_rule_map(Raw, _Mapped),
    canonical_student_rule(Raw, SrRule),
    once(lit_deontic_edge(SrRule, _, _)),
    name_match_tokens(Raw, Tokens),
    Tokens = [_, _, _|_].
content_candidate(normative_commitment(C), Raw, edge_row_commitment, Tokens) :-
    findall(Raw0-C0, gated_row_raw_commitment(Raw0, C0), Pairs0),
    sort(Pairs0, Pairs),
    member(Raw-C, Pairs),
    name_match_tokens(Raw, Tokens),
    Tokens = [_, _, _|_].

%!  gated_row_raw_commitment(-Raw, -C) is nondet.
%
%   Raw `incompatible_with` atom on a corpus row that passes the same five
%   gates as lit_deontic_edge_row/3, with C its canonical c_* commitment.
%   These are the attested spellings of the commitments the edge graph
%   already carries; nothing outside the gated slice enters the matcher.
gated_row_raw_commitment(Raw, C) :-
    lit_derived(_Id, RawDomain, _Topic, RawRule, _ValidDomain, Raw,
                deficit, _Scene, high),
    domain_map(RawDomain, Domain),
    memberchk(Domain, [fraction, decimal, whole_number]),
    student_rule_map(RawRule, _SrRule),
    normalized_commitment(Raw, C),
    C \== uncategorized,
    sub_atom(C, 0, _, _, c_),
    once(lit_deontic_edge(_, C, _)).

%% Shared normalization: name tokens (underscore split) and content words
%% (separator split) go through the same light stem, so plural/verb-s
%% spellings collide ("adds"/"numerators" match "add"/"numerator") without a
%% real stemmer's false positives.

name_match_tokens(Atom, Tokens) :-
    atomic_list_concat(Parts, '_', Atom),
    findall(T,
            ( member(P, Parts), P \== '', stem_token(P, T) ),
            Tokens0),
    list_to_set(Tokens0, Tokens).

match_content_words(Content, Words) :-
    (   atom(Content)
    ->  atom_string(Content, S)
    ;   text_to_string(Content, S)
    ),
    string_lower(S, Lower),
    split_string(Lower, " \t\n\r.,;:!?()[]{}\"'`/+*=<>-", "", Parts),
    findall(W,
            ( member(P, Parts),
              P \== "",
              atom_string(A, P),
              stem_token(A, W)
            ),
            Words0),
    list_to_set(Words0, Words).

%!  stem_token(+Atom, -Stem) is det.
%
%   Strip a final "s" from tokens longer than three characters unless they
%   end in ss/us/is (the propose_neighborhoods.py stem rule).
stem_token(Atom, Stem) :-
    atom_length(Atom, L),
    (   L > 3,
        sub_atom(Atom, _, 1, 0, s),
        \+ sub_atom(Atom, _, 2, 0, ss),
        \+ sub_atom(Atom, _, 2, 0, us),
        \+ sub_atom(Atom, _, 2, 0, is)
    ->  L1 is L - 1,
        sub_atom(Atom, 0, L1, 1, Stem)
    ;   Stem = Atom
    ).
