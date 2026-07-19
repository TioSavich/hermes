/** <module> Knowledge-spine math context resolver
 *
 * math_context_for_claim/2 takes the same ground, typed math-claim shapes the
 * checker (math_claim_checker:check_math_claim/2) adjudicates, resolves each to
 * one or more canonical concepts via claim_concept/2, then fans out across the
 * project's EXISTING knowledge surfaces to assemble SUGGESTIVE related context:
 *
 *   - crosswalk strategy families (productive/deformation pairs, action
 *     clusters, unit-coordination rows)
 *   - the literature canonical commitments (and a few example incompatibility
 *     ids)
 *   - the Lakoff & Nunez grounding-metaphor inferences (grounds_inference/3)
 *   - the standards catalog (joined by a per-concept CCSS/Indiana code
 *     whitelist, since no concept->standard predicate exists)
 *   - the misconception/deformation pairs already surfaced on the strategy
 *     surface
 *   - the grounded subtract primitive that backs the difference checker
 *     (named as related context only)
 *
 * SEPARATION (Hard Rule 4). The truth-checked verdict (holds / refuted /
 * not_covered) from check_math_claim/2 is returned in a SEPARATE top-level
 * field `verdict`. It is never attached to a context candidate. No context
 * candidate, of any provenance, proves the claim. `grounded` provenance on a
 * candidate means a grounded predicate supplied SUGGESTIVE context, not a
 * verdict.
 *
 * The `analytic_generated` provenance bucket is DECLARED but stays empty in
 * this slice. No generated analytic corpus is read (Hard Rule 2).
 *
 * Run: swipl -q -l paths.pl -s hermes/tests/test_math_context.pl -g run_tests -t halt
 */
:- module(math_context,
          [ math_context_for_claim/2,
            claim_concept/2,
            provenance/1 ]).

% --- surfaces (loaded with empty import lists; called module-qualified) ------
% The crosswalk families export overlapping helper predicates
% (canonical_concept/2, vocabulary_source/2); importing several at once
% collides. We load them for side effect only and qualify every call.
:- use_module(crosswalk(families/cw_productive_deformation), []).
:- use_module(crosswalk(families/cw_action_cluster), []).
:- use_module(crosswalk(families/cw_unit_coordination), []).
:- use_module(crosswalk(families/cw_grounding_metaphor), []).
:- use_module(crosswalk(families/cw_fraction_claim), []).
:- use_module(crosswalk(families/cw_whole_number_addsub_claim), []).
:- use_module(crosswalk(families/cw_decimal_claim), []).
% Mechanical claim families are data modules loaded by cw_driver. These loads
% also keep the family modules present for the canonical 38-family contract.
:- use_module(crosswalk(families/cw_algebra_claim), []).
:- use_module(crosswalk(families/cw_arithmetic_property_claim), []).
:- use_module(crosswalk(families/cw_calculus_claim), []).
:- use_module(crosswalk(families/cw_counting_claim), []).
:- use_module(crosswalk(families/cw_fraction_extra_claim), []).
:- use_module(crosswalk(families/cw_integer_signed_claim), []).
:- use_module(crosswalk(families/cw_magnitude_equivalence_claim), []).
:- use_module(crosswalk(families/cw_multiplication_division_claim), []).
:- use_module(crosswalk(families/cw_place_value_number_claim), []).
:- use_module(crosswalk(families/cw_ratio_proportion_claim), []).
:- use_module(crosswalk(families/cw_whole_number_claim), []).
:- use_module(crosswalk(canonical_all), []).
:- use_module(misconceptions(literature_vocabulary), []).
:- use_module(misconceptions(misconception_registry), []).
:- use_module(formalization(grounding_metaphors), []).
:- use_module(hermes(encyclopedia), []).
:- use_module(hermes(math_claim_checker), [ check_math_claim/2 ]).

:- use_module(library(lists), [ member/2, memberchk/2, append/2 ]).
:- use_module(library(apply), [ foldl/4, include/3 ]).

% ===========================================================================
% provenance/1 — the closed set of labels a context candidate may carry.
% truth-checked is NOT in this enum (the verdict lives in a separate field).
% ===========================================================================

provenance(grounded).            % grounded/co-measurement primitives as RELATED context
provenance(literature).          % literature_vocabulary canonical_commitment + lit_incompatibility
provenance(metaphor).            % grounding_metaphors:grounds_inference
provenance(standard).            % standards_catalog_dict joined by code whitelist
provenance(strategy).            % crosswalk action clusters / productive-deformation pairs
provenance(misconception).       % deformations attested by the productive/deformation pairs
provenance(analytic_generated).  % DECLARED, UNPOPULATED in this slice (Hard Rule 2)

provenance_keys([ grounded, literature, metaphor, standard, strategy,
                  misconception, analytic_generated ]).

% ===========================================================================
% claim_concept/2 — maps each of the 8 checker claim shapes to canonical
% concept(s). Convention: list ONLY concepts proven to exist on a real surface
% (crosswalk action-kind / unit_coordination, literature c_* atom, strategy
% kind, or grounding-metaphor inference id). A claim may have several concepts;
% math_context_for_claim fans out over ALL of them, deduping candidates.
%
% Wave-3 (resolved): the eight fraction-claim concepts are now first-class
% crosswalk legal_terms via the cw_fraction_claim family. claim_concept/2 keys on
% the claim TERM and points at canonical crosswalk concepts; literature is reached
% THROUGH the canonical term (see concept_literature_atom/2 + literature_candidates),
% not by a raw c_* atom in this table. Pre-existing crosswalk terms
% (unit_coordination, strategy kinds) are kept where they add a second surface.
% ===========================================================================

% equivalence: promoted fraction_equivalence + the unit_coordination surface.
claim_concept(equivalence(_,_), unit_coordination).
claim_concept(equivalence(_,_), fraction_equivalence).

% n_over_n_is_one: promoted fraction_completes_whole + strategy iteration kind.
claim_concept(n_over_n_is_one(_), fraction_completes_whole).
claim_concept(n_over_n_is_one(_), unit_fraction_iteration).

% improper: crosswalk action-kind + promoted fraction_exceeds_whole.
claim_concept(improper(_), improper_fraction_iteration).
claim_concept(improper(_), fraction_exceeds_whole).

% number_line_position: promoted fraction_number_line_measure + unit_coordination.
claim_concept(number_line_position(_,_), fraction_number_line_measure).
claim_concept(number_line_position(_,_), unit_coordination).

% midpoint: delegates to equivalence-against-1/2; unit_coordination + promoted
% magnitude/common-whole concept.
claim_concept(midpoint(_), unit_coordination).
claim_concept(midpoint(_), fraction_magnitude_common_whole).

% multiplication: the load-bearing fraction case. action-kind pair + promoted
% part-of-part concept.
claim_concept(multiplication(_,_,_), cross_multiplication_rule_from_pattern).
claim_concept(multiplication(_,_,_), fraction_multiplication).

% difference: grounded subtract op + promoted common-unit concept.
claim_concept(difference(_,_,_), grounded_arith_unified).
claim_concept(difference(_,_,_), fraction_subtraction_common_unit).

% iterate_to_whole: splitting/iteration kinds + promoted iterable-measure concept.
claim_concept(iterate_to_whole(_,_), unit_fraction_iteration).
claim_concept(iterate_to_whole(_,_), splitting).
claim_concept(iterate_to_whole(_,_), unit_fraction_iterable_measure).

% arithmetic red-pen equations: truth is checked by SWI arithmetic; context is
% routed to existing addition/decimal spine terms.
claim_concept(arithmetic_equation(A+B, _), decimal_place_value_alignment_in_column_arithmetic) :-
    ( float(A) ; float(B) ), !.
claim_concept(arithmetic_equation(A+B, _), addition_closure_totality) :-
    number(A),
    number(B).

% ===========================================================================
% standards whitelist — per claim head, a small set of CCSS/Indiana CODE
% strings. No concept->standard predicate exists; selection is by code presence
% in the LIVE catalog, never by the whitelist alone.
% ===========================================================================

claim_standard_codes(equivalence(_,_),        ["4.NF.A.1", "4.NS.3"]).
claim_standard_codes(n_over_n_is_one(_),      ["3.NS.2", "5.NF.B.3"]).
claim_standard_codes(number_line_position(_,_),["3.NF.A.2", "4.NF.C.6"]).
claim_standard_codes(midpoint(_),             ["3.NF.A.2", "4.NF.C.6"]).
claim_standard_codes(multiplication(_,_,_),   ["5.NF.B.4", "5.CA.5", "4.NF.B.4"]).
claim_standard_codes(difference(_,_,_),       ["5.NF.A.1", "5.CA.3"]).
claim_standard_codes(iterate_to_whole(_,_),   ["3.NS.2", "3.NF.A.1"]).
% improper: no 'improper' standard (audit) -> no codes.

% ===========================================================================
% math_context_for_claim/2 — top-level. Always succeeds.
% ===========================================================================

%!  math_context_for_claim(+Claim, -Dict) is det.
%
%   Dict = _{ claim, concepts, verdict, context, coverage_note }.
%   `verdict` is the full check_math_claim/2 dict (truth-checked, SEPARATE).
%   `context` is _{ grounded, literature, metaphor, standard, strategy,
%                   misconception, analytic_generated }, each a list of
%   candidate dicts (suggestive only).
math_context_for_claim(Claim, Dict) :-
    format(string(ClaimStr), "~w", [Claim]),
    findall(C, claim_concept(Claim, C), Concepts0),
    sort(Concepts0, Concepts),
    safe_verdict(Claim, Verdict),
    build_context(Claim, Concepts, Context),
    coverage_note(Concepts, Note),
    Dict = _{ claim: ClaimStr,
              concepts: Concepts,
              verdict: Verdict,
              context: Context,
              coverage_note: Note }.

% The verdict comes from the checker, wrapped so a checker failure cannot break
% context assembly. check_math_claim/2 is itself det and always succeeds, but we
% guard anyway.
safe_verdict(Claim, Verdict) :-
    ( catch(check_math_claim(Claim, V), _, fail)
    ->  Verdict = V
    ;   Verdict = _{ status: "not_covered", verdict: "not_checked",
                     reason: "checker raised or failed" }
    ).

coverage_note([], Note) :- !,
    Note = "no concept registered for this claim shape; context is empty".
coverage_note(Concepts, Note) :-
    length(Concepts, N),
    format(string(Note),
           "context is suggestive only and does not prove the claim; ~w concept(s) resolved",
           [N]).

% ===========================================================================
% build_context/3 — assemble each provenance bucket, dedup, and key on dict.
% ===========================================================================

build_context(Claim, Concepts, Context) :-
    bucket(grounded,           grounded_candidates(Claim, Concepts),        G),
    bucket(literature,         literature_candidates(Concepts),             L),
    bucket(metaphor,           metaphor_candidates(Claim, Concepts),        M),
    bucket(standard,           standard_candidates(Claim),                  Sd),
    bucket(strategy,           strategy_candidates(Concepts),               St),
    bucket(misconception,      misconception_candidates(Concepts),          Mc),
    Context = _{ grounded: G,
                 literature: L,
                 metaphor: M,
                 standard: Sd,
                 strategy: St,
                 misconception: Mc,
                 analytic_generated: [] }.   % DECLARED, UNPOPULATED (Hard Rule 2)

% bucket(+Provenance, :Goal, -DedupedList).
% Goal binds its last argument to a raw candidate list; we dedup by the join
% key (provenance, source, detail) so double-source crosswalk rows do not
% inflate counts.
bucket(_Prov, Goal, Deduped) :-
    ( catch(call(Goal, Raw), _, Raw = []) -> true ; Raw = [] ),
    dedup_candidates(Raw, Deduped).

dedup_candidates(Raw, Deduped) :-
    foldl(dedup_step, Raw, []-[], _Seen-RevDeduped),
    reverse(RevDeduped, Deduped).

dedup_step(C, Seen0-Acc0, Seen-Acc) :-
    candidate_key(C, Key),
    ( memberchk(Key, Seen0)
    ->  Seen = Seen0, Acc = Acc0
    ;   Seen = [Key|Seen0], Acc = [C|Acc0]
    ).

candidate_key(C, key(P, S, Det)) :-
    get_dict(provenance, C, P),
    get_dict(source, C, S),
    get_dict(detail, C, Det).

% ===========================================================================
% strategy candidates — crosswalk productive/deformation pairs + action
% clusters, keyed on the resolved concept matching a Kind.
% ===========================================================================

strategy_candidates(Concepts, Cands) :-
    findall(C,
            ( member(Concept, Concepts),
              strategy_candidate(Concept, C) ),
            Cands).

% Productive side of a productive/deformation pair whose productive == Concept.
strategy_candidate(Concept, Cand) :-
    catch(cw_productive_deformation:productive_deformation_unified(
              fraction, Concept, Deform, Family, _Source),
          _, fail),
    cluster_of(Concept, Cluster),
    fa(Concept, KindS), fa(Cluster, ClusterS), fa(Family, FamilyS),
    fa(Deform, DeformS),
    Cand = candidate{
        concept: Concept,
        provenance: strategy,
        source: "crosswalk:productive_deformation_unified/5",
        detail: _{ kind: KindS, cluster: ClusterS, family: FamilyS,
                   vocabulary: [KindS, DeformS] },
        note: "" }.

% Action-cluster membership for a kind that is not the productive head of a
% deformation pair (e.g. unit_fraction_iteration, splitting, improper kind).
strategy_candidate(Concept, Cand) :-
    \+ catch(cw_productive_deformation:productive_deformation_unified(
                 fraction, Concept, _, _, _), _, fail),
    catch(cw_action_cluster:action_cluster_unified(fraction, Concept, Cluster, _Source),
          _, fail),
    fa(Concept, KindS), fa(Cluster, ClusterS),
    Cand = candidate{
        concept: Concept,
        provenance: strategy,
        source: "crosswalk:action_cluster_unified/4",
        detail: _{ kind: KindS, cluster: ClusterS, family: "fraction",
                   vocabulary: [KindS] },
        note: "" }.

cluster_of(Kind, Cluster) :-
    ( catch(once(cw_action_cluster:action_cluster_unified(fraction, Kind, Cluster, _)),
            _, fail)
    ->  true
    ;   Cluster = fraction ).

% ===========================================================================
% literature candidates — for c_* concepts, the canonical commitment gloss
% plus a couple example incompatibility ids. NEVER via literature_search_dict
% (token-substring; cannot filter by atom; misses c_unit_fraction_iterable_
% measure which lacks the 'iterat' token).
% ===========================================================================

literature_candidates(Concepts, Cands) :-
    findall(C,
            ( member(Concept, Concepts),
              concept_literature_atom(Concept, LitAtom),
              literature_candidate(LitAtom, Concept, C) ),
            Cands).

% Resolve a resolved concept to its literature commitment atom. Either the
% concept already IS a c_* atom (back-compat), or it is a promoted
% fraction-claim canonical term whose crosswalk family names a c_* legacy.
concept_literature_atom(Concept, Concept) :- is_lit_atom(Concept), !.
concept_literature_atom(Concept, LitAtom) :-
    claim_family_module(Mod),
    (   cw_driver:data_family(Mod)
    ->  catch(cw_driver:family_call(Mod,
                                    claim_literature_atom(Concept, LitAtom)),
              _, fail)
    ;   catch(Mod:claim_literature_atom(Concept, LitAtom), _, fail)
    ).

% The 14 crosswalk claim families map a canonical concept to its c_* literature
% atom. concept_literature_atom/2 fans out over all of them; downstream dedup
% keys on the candidate, so a concept owned by more than one family does not
% inflate counts.
claim_family_module(cw_fraction_claim).
claim_family_module(cw_whole_number_addsub_claim).
claim_family_module(cw_decimal_claim).
claim_family_module(cw_algebra_claim).
claim_family_module(cw_arithmetic_property_claim).
claim_family_module(cw_calculus_claim).
claim_family_module(cw_counting_claim).
claim_family_module(cw_fraction_extra_claim).
claim_family_module(cw_integer_signed_claim).
claim_family_module(cw_magnitude_equivalence_claim).
claim_family_module(cw_multiplication_division_claim).
claim_family_module(cw_place_value_number_claim).
claim_family_module(cw_ratio_proportion_claim).
claim_family_module(cw_whole_number_claim).

is_lit_atom(Concept) :- atom(Concept), sub_atom(Concept, 0, 2, _, 'c_').

% The candidate still records the literature commitment atom in `concept`; `via`
% names the crosswalk canonical term it was reached through (empty when the
% concept was itself the c_* atom).
literature_candidate(LitAtom, ViaConcept, Cand) :-
    catch(literature_vocabulary:canonical_commitment(LitAtom, Gloss), _, fail),
    example_lit_id(LitAtom, ExampleId),
    ( LitAtom == ViaConcept -> ViaS = "" ; fa(ViaConcept, ViaS) ),
    fa(LitAtom, ConceptS), fa(Gloss, GlossS),
    Cand = candidate{
        concept: LitAtom,
        provenance: literature,
        source: "literature_vocabulary:canonical_commitment/2",
        detail: _{ commitment: ConceptS, gloss: GlossS, example_id: ExampleId, via: ViaS },
        note: "" }.

% Bind Commitment=CAtom and take ONE example id (do not enumerate open).
example_lit_id(Concept, IdS) :-
    ( catch(once(literature_vocabulary:lit_incompatibility(
                     Id, _Dom, Concept, _, _, _, _)),
            _, fail)
    ->  fa(Id, IdS)
    ;   IdS = "" ).

% ===========================================================================
% metaphor candidates — grounds_inference/3 DIRECTLY (the encyclopedia
% operation dict omits it). Only emit for the claims whose deep content lives in
% an inference. NONE for improper (no metaphor target).
% ===========================================================================

% Map the claim head to the grounds_inference inference ids it should surface.
claim_inferences(multiplication(_,_,_),
                 [ fraction_multiplication_as_part_of_part ]).
claim_inferences(iterate_to_whole(_,_),
                 [ multiplicative_inverse_1_over_n_times_n_is_1 ]).
claim_inferences(n_over_n_is_one(_),
                 [ multiplicative_inverse_1_over_n_times_n_is_1 ]).
claim_inferences(equivalence(_,_),
                 [ simple_fractions_1_over_n ]).
claim_inferences(midpoint(_),
                 [ simple_fractions_1_over_n ]).
claim_inferences(number_line_position(_,_),
                 [ simple_fractions_1_over_n ]).
% improper(_) and difference(_,_,_): no metaphor target -> no clause -> [].

metaphor_candidates(Claim, _Concepts, Cands) :-
    ( claim_inferences(Claim, Inferences)
    ->  findall(C,
                ( member(Inf, Inferences),
                  metaphor_candidate(Inf, C) ),
                Cands)
    ;   Cands = [] ).

metaphor_candidate(Inference, Cand) :-
    catch(grounding_metaphors:grounds_inference(
              arithmetic_is_object_construction, Inference, Mechanism),
          _, fail),
    MetaphorId = arithmetic_is_object_construction,
    fa(MetaphorId, MetaphorS), fa(Inference, InferenceS), fa(Mechanism, MechanismS),
    Cand = candidate{
        concept: MetaphorId,
        provenance: metaphor,
        source: "formalization:grounding_metaphors:grounds_inference/3",
        detail: _{ metaphor_id: MetaphorS, inference: InferenceS,
                   mechanism: MechanismS },
        note: "" }.

% ===========================================================================
% standard candidates — per-claim code whitelist, selected against the LIVE
% catalog (assert by code presence, never by whitelist alone). NONE for
% improper (no whitelist clause).
% ===========================================================================

standard_candidates(Claim, Cands) :-
    ( claim_standard_codes(Claim, Codes)
    ->  catch(hermes_encyclopedia:standards_catalog_dict(all, SD), _, fail),
        get_dict(standards, SD, Standards),
        findall(C,
                ( member(Code, Codes),
                  member(St, Standards),
                  get_dict(code, St, Code),
                  standard_candidate(St, C) ),
                Cands)
    ;   Cands = [] ).

standard_candidate(St, Cand) :-
    get_dict(code, St, Code),
    get_dict(framework, St, Framework),
    get_dict(statement, St, Statement),
    fa(Code, CodeS), fa(Framework, FrameworkS), fa(Statement, StatementS),
    Cand = candidate{
        concept: standards_catalog,
        provenance: standard,
        source: "encyclopedia:standards_catalog_dict/2",
        detail: _{ framework: FrameworkS, code: CodeS, statement: StatementS },
        note: "" }.

% ===========================================================================
% misconception candidates — derive from the productive/deformation pairs found
% on the strategy surface. Confirm via incompatibility_with/2 with BOTH args
% bound (avoid 247x whole_number_grab inflation when unbound).
% ===========================================================================

misconception_candidates(Concepts, Cands) :-
    findall(C,
            ( member(Concept, Concepts),
              misconception_candidate(Concept, C) ),
            Cands).

misconception_candidate(Productive, Cand) :-
    catch(cw_productive_deformation:productive_deformation_unified(
              fraction, Productive, Deform, Family, _Source),
          _, fail),
    confirm_incompatibility(Deform, Productive, Confirmed),
    fa(Productive, ProductiveS), fa(Deform, DeformS), fa(Family, FamilyS),
    Cand = candidate{
        concept: Productive,
        provenance: misconception,
        source: "crosswalk:productive_deformation_unified/5",
        detail: _{ productive: ProductiveS, deformation: DeformS, family: FamilyS },
        note: Confirmed }.
misconception_candidate(Concept, Cand) :-
    catch(cw_driver:decimal_claim_unified(Concept, edge_surface(Surface), Source),
          _, fail),
    atom(Source),
    sub_atom(Source, 0, _, _, 'misconception_registry:'),
    fa(Source, SourceS), fa(Surface, SurfaceS),
    Cand = candidate{
        concept: Concept,
        provenance: misconception,
        source: SourceS,
        detail: _{ deformation: SourceS, surface: SurfaceS },
        note: "registered decimal misconception from existing crosswalk surface" }.

% Both args bound — never enumerate. Note records whether the registry confirms.
confirm_incompatibility(Deform, Productive, Note) :-
    ( catch(once(misconception_registry:incompatibility_with(
                     Deform, strategy(fraction, Productive))),
            _, fail)
    ->  Note = "incompatibility confirmed in misconception_registry"
    ;   Note = "deformation from crosswalk pair; registry confirmation not found" ).

% ===========================================================================
% grounded candidates — difference only. Name the grounded subtract primitive
% that BACKS the checker, as RELATED context. Do NOT recompute the verdict.
% ===========================================================================

grounded_candidates(difference(_,_,_), Concepts, [Cand]) :-
    memberchk(grounded_arith_unified, Concepts), !,
    Cand = candidate{
        concept: grounded_arith_unified,
        provenance: grounded,
        source: "crosswalk:grounded_arith_unified/4",
        detail: _{ predicate: "grounded_arithmetic:subtract_grounded",
                   mechanism: "grounded subtraction over recollections" },
        note: "related context, not the verdict" }.
grounded_candidates(arithmetic_equation(A+B, _), Concepts, [Cand]) :-
    memberchk(addition_closure_totality, Concepts),
    number(A),
    number(B), !,
    Cand = candidate{
        concept: addition_closure_totality,
        provenance: grounded,
        source: "grounded_arithmetic:add_grounded/3",
        detail: _{ predicate: "grounded_arithmetic:add_grounded",
                   mechanism: "grounded addition over recollections" },
        note: "related context, not the SWI red-pen verdict" }.
grounded_candidates(_, _, []).

% ===========================================================================
% fa/2 — force an atom/number/string to a JSON-safe string.
% ===========================================================================

fa(X, S) :- ( string(X) -> S = X ; format(string(S), "~w", [X]) ).
