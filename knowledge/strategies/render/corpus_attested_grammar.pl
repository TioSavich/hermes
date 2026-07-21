/** <module> corpus_attested_grammar
 *
 * One queryable companion to the logical visual grammar in
 * knowledge/strategies/render/representation_grammar.pl. ADDITIVE: it loads the three
 * generated, corpus-attested layers (objects, uses, deformations) and exposes
 * JOIN predicates that line each layer up against what the grammar names.
 * It never edits the grammar and asserts nothing the layers do not already
 * support; the joins are read-only over both sides.
 *
 * The three generated layers aggregate the per-figure REALLMs ground facts
 * (lessons/im/docling_figures_interpreted.pl) up to the language / object /
 * use-pattern / domain level. This module does NOT re-aggregate the figures; it
 * reconciles those aggregates with the grammar's own vocabulary.
 *
 * Status vocabulary (shared shape across the three registers):
 *   grammar_and_corpus      -- the grammar names it AND the corpus attests it
 *   grammar_only_unattested -- the grammar names it; the corpus shows no
 *                              student-work instance (below the resolution of
 *                              the automated figure read, or simply not yet seen)
 *   corpus_only_gap         -- the corpus attests it; the grammar does not name
 *                              it (a candidate to add, NOT a verdict that the
 *                              grammar is wrong)
 *
 * Honesty about the use register: the grammar denotes tasks through
 * render_spec_denotes/3, not through a use-pattern vocabulary. So a use pattern
 * counts as grammar-and-corpus only when attested_uses.pl carries an explicit
 * use_pattern_denotes/2 bridge to a grammar task term. Use patterns the grammar
 * cannot denote are recorded as corpus_only_gap, matching denotation_gap/3.
 * There is no grammar_only_unattested row in the use register: the grammar does
 * not enumerate uses independently of render specs, so "a use the grammar names
 * but the corpus never shows" is not a question this layer can ask honestly.
 */
:- module(corpus_attested_grammar,
          [ representation_object_status/3,
            representation_use_status/4,
            corpus_grammar_summary/1
          ]).

:- use_module(render(representation_grammar)).
:- use_module(render(attested_objects)).
:- use_module(render(attested_uses)).
:- use_module(render(attested_deformations)).

% --- object register join ------------------------------------------------
% representation_object_status(Language, Object, Status).
% Enumerates every (Language, Object) pair that either side knows about and
% tags it with one status. Deterministic per pair (no duplicate solutions).

representation_object_status(Language, Object, grammar_and_corpus) :-
    representation_grammar:representation_object(Language, Object),
    attested_objects:attested_representation_object(Language, Object, _Count, _Domains, _Examples).

representation_object_status(Language, Object, grammar_only_unattested) :-
    representation_grammar:representation_object(Language, Object),
    \+ attested_objects:attested_representation_object(Language, Object, _C, _D, _E).

representation_object_status(Language, Object, corpus_only_gap) :-
    attested_objects:proposed_representation_object(Language, Object, _Count, attested_not_in_grammar),
    \+ representation_grammar:representation_object(Language, Object).

% --- use register join ---------------------------------------------------
% representation_use_status(Language, Domain, UsePattern, Status).
% A use is grammar_and_corpus when the corpus attests it (any domain) AND the
% generated layer carries a use_pattern_denotes/2 bridge to a grammar task.
% A use is corpus_only_gap when the corpus attests it but it has no bridge
% (it is a denotation_gap, by language or because the grammar has no render
% spec for that verb).

representation_use_status(Language, Domain, UsePattern, grammar_and_corpus) :-
    attested_uses:attested_representation_use(Language, Domain, UsePattern, _Count, _Examples),
    attested_uses:use_pattern_denotes(UsePattern, _GrammarTask).

representation_use_status(Language, Domain, UsePattern, corpus_only_gap) :-
    attested_uses:attested_representation_use(Language, Domain, UsePattern, _Count, _Examples),
    \+ attested_uses:use_pattern_denotes(UsePattern, _GrammarTask).

% --- rollup --------------------------------------------------------------
% corpus_grammar_summary(-Summary): one dict rolling up the gap counts across
% all three registers (objects, uses, deformations). Counts are computed by
% findall over the layers' own facts and this module's status joins, so the
% summary stays faithful to whatever the generated files currently say.

corpus_grammar_summary(Summary) :-
    % object register
    count_object_status(grammar_and_corpus, ObjBoth),
    count_object_status(grammar_only_unattested, ObjGrammarOnly),
    count_object_status(corpus_only_gap, ObjCorpusOnly),
    % use register (distinct use patterns, and language-domain cells)
    distinct_use_patterns_with_status(grammar_and_corpus, UsePatBoth),
    distinct_use_patterns_with_status(corpus_only_gap, UsePatGap),
    count_use_cells(grammar_and_corpus, UseCellBoth),
    count_use_cells(corpus_only_gap, UseCellGap),
    findall(P-C, attested_uses:denotation_gap(_L, P, C), _GapPairs),
    findall(C, attested_uses:denotation_gap(_L2, _P2, C), GapCounts),
    sum_list(GapCounts, DenotationGapFigureTotal),
    % deformation register
    findall(t(Lg, Fp, Ih),
            attested_deformations:attested_transplant(Lg, Fp, Ih, _Bk, _Fig),
            Transplants),
    length(Transplants, TransplantCount),
    findall(C2,
            attested_deformations:attested_representation_error(_L3, _Pat, C2, _Ex),
            ErrorCounts),
    sum_list(ErrorCounts, ErrorFigureTotal),
    findall(L4-B4,
            attested_deformations:grounding_attested(L4, B4, supports),
            GroundingSupports),
    length(GroundingSupports, GroundingSupportCount),
    findall(L5-B5,
            attested_deformations:grounding_mismatch(L5, B5, _Use, _Note),
            GroundingMismatches),
    length(GroundingMismatches, GroundingMismatchCount),
    Summary = summary{
        objects: objects{
            grammar_and_corpus: ObjBoth,
            grammar_only_unattested: ObjGrammarOnly,
            corpus_only_gap: ObjCorpusOnly
        },
        uses: uses{
            distinct_patterns_grammar_and_corpus: UsePatBoth,
            distinct_patterns_corpus_only_gap: UsePatGap,
            cells_grammar_and_corpus: UseCellBoth,
            cells_corpus_only_gap: UseCellGap,
            denotation_gap_figure_total: DenotationGapFigureTotal
        },
        deformations: deformations{
            transplants: TransplantCount,
            error_figure_total: ErrorFigureTotal,
            grounding_attested: GroundingSupportCount,
            grounding_mismatch: GroundingMismatchCount
        }
    }.

count_object_status(Status, Count) :-
    findall(L-O, representation_object_status(L, O, Status), Pairs),
    sort(Pairs, Unique),
    length(Unique, Count).

distinct_use_patterns_with_status(Status, Count) :-
    findall(P,
            representation_use_status(_L, _D, P, Status),
            Patterns),
    sort(Patterns, Unique),
    length(Unique, Count).

count_use_cells(Status, Count) :-
    findall(L-D-P,
            representation_use_status(L, D, P, Status),
            Cells),
    sort(Cells, Unique),
    length(Unique, Count).
