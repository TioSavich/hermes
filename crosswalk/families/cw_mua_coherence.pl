/** <module> cw_mua_coherence — canonical union query for MUA coherence scoring
 *
 * Family: "MUA coherence scoring" (slug: mua_coherence). Two scattered functors
 * both denote "score how coherent some input is against a legal/MUA vocabulary,"
 * but they sit at different layers and arities and are NOT redundant:
 *
 *   - pml(mua_relations):kind_mua_coherence/3
 *       kind_mua_coherence(+Kind, +RowText, -Score)
 *       Scores binding a corpus row to a registry KIND: Score = how many of the
 *       kind's PV-sufficient vocabulary terms appear in the lower-cased row text.
 *       Pure (findall + length).
 *
 *   - hermes(encyclopedia):pml_score_dict/2
 *       pml_score_dict(+ClauseStrings, -Dict)
 *       Validates + scores a batch of model-emitted reader_axiom/4 + passage_mode/3
 *       clause strings against the 12 legal PML operators. Returns a dict; the
 *       integer coherence measure is Dict.valid_count (how many clauses were
 *       legal PML axioms). Read-only: clause strings are PARSED (term_string/2),
 *       never consulted or executed.
 *
 * This module does NOT rename or rewrite either predicate. It adds a read-only
 * union query, mua_coherence_unified/4, that ranges over both and tags each
 * result with its -Source. The public yes/no/count query delegates through
 * mua_coherence_witness/5 so the vocabulary hits or PML-validation dict are not
 * lost behind the shared integer Score projection.
 *
 * PROJECTION (the two arities normalized to one queryable shape):
 *   mua_coherence_unified(?Subject, ?Input, -Score, -Source)
 *     - Subject : the thing being scored.
 *                 For pml_vocabulary : the registry Kind (an atom).
 *                 For pml_axiom_batch: the atom `axiom_batch` (the batch has no
 *                                      single subject; the clause strings ARE the
 *                                      subject, carried in Input).
 *     - Input   : the text/clauses scored.
 *                 For pml_vocabulary : the RowText (string/atom).
 *                 For pml_axiom_batch: the list of clause strings.
 *     - Score   : an integer coherence count (>= 0).
 *                 For pml_vocabulary : count of vocabulary terms hit.
 *                 For pml_axiom_batch: Dict.valid_count (count of legal axioms).
 *     - Source  : pml_vocabulary | pml_axiom_batch
 *
 * Both sources are pure / side-effect-free, so no once/1 guarding is needed
 * beyond the catch/3 wrapper. Both source predicates are det given ground input,
 * so the union is det per source when Subject+Input are bound.
 */
:- module(cw_mua_coherence,
          [ mua_coherence_unified/4,   % mua_coherence_unified(?Subject, ?Input, -Score, -Source)
            mua_coherence_witness/5,   % mua_coherence_witness(?Subject, ?Input, -Score, ?Source, -Witness)
            mua_coherence_source_witness/5,
            canonical_concept/2,       % canonical_concept(LegacyFunctor, Canonical)
            vocabulary_source/2        % vocabulary_source(Canonical, ListOfLegacyFunctors)
          ]).

% Source modules are called module-qualified; empty import lists are intentional
% (nothing pulled into this module's namespace, no clashes).
:- use_module(pml(mua_relations), []).
:- use_module(hermes(encyclopedia), []).

%! mua_coherence_unified(?Subject, ?Input, -Score, -Source) is nondet.
%
%  Union query over both MUA-coherence scorers. Each clause tags its -Source.
%  Every source call is catch-guarded so an absent/erroring source contributes
%  nothing. Both sources expect Subject (where applicable) and Input bound; with
%  those bound each is deterministic.

mua_coherence_unified(Kind, RowText, Score, pml_vocabulary) :-
    mua_coherence_witness(Kind, RowText, Score, pml_vocabulary, _).

mua_coherence_unified(axiom_batch, ClauseStrings, Score, pml_axiom_batch) :-
    mua_coherence_witness(axiom_batch, ClauseStrings, Score, pml_axiom_batch, _).


%! mua_coherence_witness(?Subject, ?Input, -Score, ?Source, -Witness) is nondet.
%
%  Witnessed form of `mua_coherence_unified/4`. This is a closed-world finite
%  union over the currently loaded MUA-coherence sources. It does not decide
%  every possible coherence relation; it records which loaded scorer accepted
%  the concrete input and the exact evidence that produced the integer score.
mua_coherence_witness(Subject, Input, Score, Source,
                      WitnessDict79) :-
    witness_dict:witness_dict(mua_coherence_crosswalk, closed_world_finite_loaded_mua_coherence_sources,
                              _{source: Source,
                         legacy_functor: LegacyFunctor,
                         subject: Subject,
                         input_scope: InputScope,
                         score: Score,
                         score_meaning: ScoreMeaning,
                         derivation: Derivation,
                         source_witness: SourceWitness }, WitnessDict79),
    mua_coherence_source(Source, LegacyFunctor),
    source_mua_coherence_witness(Source,
                                 Subject,
                                 Input,
                                 Score,
                                 InputScope,
                                 ScoreMeaning,
                                 Derivation,
                                 SourceWitness).


%! mua_coherence_source_witness(?Subject, ?Input, -Score, ?Source,
%!                              -SourceWitness) is nondet.
%
%  Project the source-owned witness from the canonical union witness.  Public
%  routes that need the historical source shape still execute the one union
%  predicate and then select its source evidence.
mua_coherence_source_witness(Subject, Input, Score, Source, SourceWitness) :-
    mua_coherence_witness(Subject, Input, Score, Source, Witness),
    get_dict(source_witness, Witness, SourceWitness).


mua_coherence_source(pml_vocabulary,
                     'mua_relations:kind_mua_coherence/3').
mua_coherence_source(pml_axiom_batch,
                     'hermes_encyclopedia:pml_score_dict/2').


source_mua_coherence_witness(pml_vocabulary,
                             Kind,
                             RowText,
                             Score,
                             lower_cased_corpus_row_text,
                             vocabulary_terms_hit_count,
                             kind_vocabulary_hit_scan,
                             SourceWitness) :-
    catch(mua_relations:kind_mua_coherence_witness(Kind,
                                                   RowText,
                                                   Score,
                                                   SourceWitness),
          _, fail).
source_mua_coherence_witness(pml_axiom_batch,
                             axiom_batch,
                             ClauseStrings,
                             Score,
                             parsed_reader_axiom_clause_strings,
                             valid_reader_axiom_count,
                             pml_clause_validation,
                             _{ kind: hermes_pml_axiom_batch_score,
                                clause_count: ClauseCount,
                                valid_count: Score,
                                validation: Dict }) :-
    catch(hermes_encyclopedia:pml_score_dict(ClauseStrings, Dict), _, fail),
    get_dict(valid_count, Dict, Score),
    get_dict(clause_count, Dict, ClauseCount).

%! canonical_concept(?LegacyFunctor, ?Canonical) is nondet.
%
%  Maps each scattered legacy functor to its canonical query predicate.
canonical_concept('mua_relations:kind_mua_coherence/3',   mua_coherence_unified).
canonical_concept('hermes_encyclopedia:pml_score_dict/2', mua_coherence_unified).

%! vocabulary_source(?Canonical, ?LegacyFunctors) is nondet.
vocabulary_source(mua_coherence_unified,
    [ 'mua_relations:kind_mua_coherence/3',
      'hermes_encyclopedia:pml_score_dict/2' ]).
