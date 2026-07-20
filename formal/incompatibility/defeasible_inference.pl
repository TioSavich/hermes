/** <module> Defeasible material-inference hotswap (iteration8 substrate)
 *
 * Realizes the experiment: assert a material inference as a rule, hotswap extra
 * commitments into its context, and watch whether the inference SURVIVES, is
 * DEFEATED, or is defeated only by a SET with no single member responsible (an
 * emergent incompatibility hyperedge). Defeat is read off a real consequence
 * relation, not asserted — that is the difference from the registry's flat
 * binary verdicts.
 *
 * Reader's rule of thumb:
 *   - material_inference/3 names a defeasible entitlement.
 *   - compiled_break/2 names a runnable reason that some commitments cannot
 *     stand together.
 *   - classify_defeat_witness/4 returns the verdict plus the reason checked:
 *     which source made the context incoherent, and for emergent defeats, every
 *     one-element removal that was checked to prove minimality.
 *
 * Two incoherence sources, both run (nothing is hand-listed as "incompatible"):
 *   1. The sequent engine's own incoherence (sequent_engine:incoherent/1):
 *      structural P/neg(P), modal D(P)/D(neg(P)), the Robinson succ(x)=0 rule,
 *      and anything derivable to falsum. This is sparse but genuine.
 *   2. compiled_break/2: a faithful, clearly-marked compilation of L&N
 *      grounding-metaphor break-points into runnable conditions (contains-
 *      semantics: the break fires when all its conditions are present). The
 *      metaphor break-points are catalogued as data in grounding_metaphors*.pl;
 *      this turns a handful into something the consequence relation can run.
 *
 * HONEST SCOPE. The richness of discovery is bounded by how many incoherence
 * conditions exist. Source 1 is sparse; source 2 now compiles the FULL
 * catalogue: every metaphor_breaks_at/2 row in grounding_metaphors.pl and
 * every ln_metaphor_breaks_at/3 row in grounding_metaphors_extended.pl has a
 * compiled form (18 breaks, 4 of them emergent triples). The remaining lever
 * for growing emergent hyperedges is authoring CROSS-METAPHOR triples — sets
 * incoherent only across two metaphors' commitments. Those are not catalogued
 * data; they are philosophical judgment work (the lakoff-nunez steward's
 * brief), one candidate at a time, and belong beside the catalogue in
 * grounding_metaphors*.pl before they are compiled here.
 */
:- module(defeasible_inference,
          [ material_inference/3,        % Id, Premises, Conclusion
            defeater_vocabulary/1,       % -List of candidate defeater commitments
            classify_defeat/3,           % +Id, +DefeaterSet, -Outcome
            classify_defeat_witness/4,   % +Id, +DefeaterSet, -Outcome, -Witness
            discover_defeat/2,           % ?Id, -DefeaterSet (defeated or emergent)
            compiled_break/2,            % BreakId, ConditionSet  (compiled L&N break)
            ctx_incoherent/1,            % +Context
            ctx_incoherent_witness/2     % +Context, -Witness
          ]).

:- use_module(library(lists)).
:- use_module(sequent(sequent_engine),
              [ incoherent_witness/2,
                incoherent_base/1
              ]).


%!  material_inference(?Id, ?Premises, ?Conclusion) is nondet.
%
%   A material inference: holding Premises (a coherent context) entitles you to
%   Conclusion. Seeded with sequent-expressible cases tied to real incoherence
%   sources. Extend as the incoherence vocabulary grows.
%   Each material inference says "metaphor M grounds its target domain"; the
%   commitment that licenses it is o(grounded(M)). The compiled_break facts below
%   say where each M can no longer ground. One inference per catalogued metaphor.
material_inference(commit_p_entitles_q,
                   [o(p)],
                   o(q)).
material_inference(object_collection_grounds_subtraction,
                   [o(grounded(object_collection))],
                   o(subtraction_is_take_away)).
material_inference(object_construction_grounds_arithmetic,
                   [o(grounded(object_construction))],
                   o(numbers_are_built_objects)).
material_inference(measuring_stick_grounds_length,
                   [o(grounded(measuring_stick))],
                   o(length_is_count_of_units)).
material_inference(motion_along_path_grounds_arithmetic,
                   [o(grounded(motion_along_a_path))],
                   o(arithmetic_is_iterated_motion)).
material_inference(classes_are_containers_grounds_sets,
                   [o(grounded(classes_are_containers))],
                   o(membership_is_containment)).
material_inference(points_on_line_grounds_number,
                   [o(grounded(numbers_are_points_on_a_line))],
                   o(every_number_is_a_point)).
material_inference(functions_are_curves_grounds_functions,
                   [o(grounded(functions_are_curves))],
                   o(functions_are_smooth_curves)).
material_inference(functions_are_ordered_pairs_grounds_functions,
                   [o(grounded(functions_are_sets_of_ordered_pairs))],
                   o(function_is_its_extension)).
material_inference(weierstrass_continuity_grounds_continuity,
                   [o(grounded(weierstrass_continuity_metaphor))],
                   o(continuity_is_preserved_closeness)).
material_inference(spaces_are_point_sets_grounds_space,
                   [o(grounded(spaces_are_sets_of_points))],
                   o(space_is_a_set_of_points)).
material_inference(cantors_metaphor_grounds_cardinality,
                   [o(grounded(cantors_metaphor))],
                   o(same_number_is_pairability)).


%!  compiled_break(?BreakId, ?ConditionSet) is nondet.
%
%   A grounding-metaphor break-point compiled into a runnable condition: the set
%   is materially incoherent (the metaphor cannot ground all of it at once).
%   Contains-semantics — fires whenever every condition is present. Each traces
%   to a catalogued grounding_metaphors break-point (commented with its source).
%   Binary breaks are [grounded(M), trigger]; the "two inconsistent conceptions
%   held together" breaks are minimal triples (genuine emergent hyperedges).

% -- arithmetic_is_object_collection (4 catalogued breaks) ------------------
compiled_break(object_collection_subtraction_underflow,
               [o(grounded(object_collection)), o(subtract_larger_from_smaller)]).
compiled_break(object_collection_fractional_unit,
               [o(grounded(object_collection)), o(fractional_unit_demanded)]).
compiled_break(object_collection_irrational,
               [o(grounded(object_collection)), o(irrational_demanded)]).
compiled_break(object_collection_zero,
               [o(grounded(object_collection)), o(zero_demanded)]).

% -- arithmetic_is_object_construction (zero + irrationals) -----------------
compiled_break(object_construction_zero,
               [o(grounded(object_construction)), o(zero_demanded)]).
compiled_break(object_construction_irrational,
               [o(grounded(object_construction)), o(irrational_demanded)]).

% -- arithmetic_is_measuring_stick: negatives, and incommensurability -------
compiled_break(measuring_stick_negative,
               [o(grounded(measuring_stick)), o(negative_demanded)]).
%   Incommensurability (the diagonal): unit-measure + count-of-units + an
%   incommensurable length cannot be held together. No two alone are incoherent;
%   the incoherence is emergent in the triple.
compiled_break(measuring_stick_incommensurability,
               [o(grounded(measuring_stick)),
                o(length_is_count_of_units),
                o(diagonal_of_unit_square_measured)]).

%   Product of two negative quantities: the stick multiplies lengths into
%   areas, and two absent lengths demanding a positive area has no stick
%   reading. Catalogued: metaphor_breaks_at(measuring_stick,
%   product_of_two_negative_quantities).
compiled_break(measuring_stick_negative_product,
               [o(grounded(measuring_stick)), o(negative_product_demanded)]).

% -- arithmetic_is_motion_along_a_path: product of two negatives ------------
compiled_break(motion_negative_multiplier,
               [o(grounded(motion_along_a_path)), o(negative_multiplier_demanded)]).
%   Irrationals without completeness: stepwise motion reaches every rational
%   stopping place, but an irrational destination is a limit point the walk
%   never lands on — it demands the path's completeness, which the metaphor
%   does not carry. Catalogued: metaphor_breaks_at(motion_along_path,
%   irrationals_without_completeness).
compiled_break(motion_irrational_destination,
               [o(grounded(motion_along_a_path)), o(irrational_destination_demanded)]).

% -- classes_are_containers: self-membership (Foundation) -------------------
compiled_break(container_self_membership,
               [o(grounded(classes_are_containers)), o(set_contains_itself)]).

% -- numbers_are_points_on_a_line: a point at actual infinity ---------------
compiled_break(points_on_line_actual_infinity,
               [o(grounded(numbers_are_points_on_a_line)), o(infinity_as_point_demanded)]).

% -- functions_are_curves: pathological (Weierstrass) functions -------------
compiled_break(functions_are_curves_pathological,
               [o(grounded(functions_are_curves)), o(pathological_function_demanded)]).

% -- weierstrass_continuity_metaphor: loses continuous trajectory -----------
compiled_break(weierstrass_loses_trajectory,
               [o(grounded(weierstrass_continuity_metaphor)), o(continuous_trajectory_demanded)]).

% -- EMERGENT: functions_are_sets_of_ordered_pairs collapses rule vs extension
%   Holding "two rules with the same extension" together with "the rules are
%   conceptually distinct" under the extension-metaphor is jointly incoherent;
%   neither commitment alone breaks it.
compiled_break(ordered_pairs_rule_extension_collapse,
               [o(grounded(functions_are_sets_of_ordered_pairs)),
                o(two_rules_same_extension),
                o(rules_conceptually_distinct)]).

% -- EMERGENT: spaces_are_sets_of_points blends two inconsistent conceptions
%   "points are inherent to space" + "space is constituted by points" held
%   together under the metaphor is a blend, not a clean reduction.
compiled_break(spaces_point_blend_inconsistency,
               [o(grounded(spaces_are_sets_of_points)),
                o(points_inherent_to_space),
                o(space_constituted_by_points)]).

% -- EMERGENT: cantors_metaphor reassigns "same number as" -------------------
%   Everyday Same-Number-As (take-away comparison) + comparing an infinite
%   collection + Cantor's pairability reading cannot be held together.
compiled_break(cantor_same_number_reassignment,
               [o(grounded(cantors_metaphor)),
                o(everyday_same_number_comparison),
                o(infinite_collection_compared)]).


%!  defeater_vocabulary(-Vocabulary) is det.
%
%   The pool of candidate commitments the hotswap can add to an inference's
%   context. Drawn from the compiled-break conditions plus a structural negation,
%   so the sweep covers both genuine domain defeaters and a control.
defeater_vocabulary(Vocabulary) :-
    findall(Term,
            ( compiled_break(_, Conditions), member(Term, Conditions) ),
            BreakTerms0),
    sort(BreakTerms0, BreakTerms),
    % a structural defeater (negation of a premise) and a neutral control
    append(BreakTerms, [neg(o(p)), o(unrelated_control)], Vocabulary0),
    sort(Vocabulary0, Vocabulary).


%!  ctx_incoherent(+Context) is semidet.
%
%   The consequence relation: incoherent via the sequent engine, or via a
%   compiled break whose conditions are all present.
ctx_incoherent(Context) :-
    ctx_incoherent_witness(Context, _),
    !.


%!  ctx_incoherent_witness(+Context, -Witness) is semidet.
%
%   True when Context is materially incoherent, with a readable source witness.
%   The sequent engine is tried first to preserve ctx_incoherent/1's historical
%   behavior; compiled breaks are the explicit Lakoff-Nunez break witnesses.
ctx_incoherent_witness(Context,
                       _{source: sequent_engine,
                         rule: incoherent,
                         context: Context,
                         engine_witness: EngineWitness}) :-
    sequent_engine:incoherent_witness(Context, EngineWitness),
    !.
ctx_incoherent_witness(Context,
                       _{source: compiled_break,
                         break_id: BreakId,
                         conditions_present: Conditions,
                         context: Context}) :-
    compiled_break(BreakId, Conditions),
    subset_present(Conditions, Context),
    !.

subset_present([], _).
subset_present([T|Ts], Context) :-
    memberchk_eq(T, Context),
    subset_present(Ts, Context).

memberchk_eq(T, [H|_]) :- T == H, !.
memberchk_eq(T, [_|R]) :- memberchk_eq(T, R).


%!  classify_defeat(+Id, +DefeaterSet, -Outcome) is det.
%
%   Outcome:
%     coherent                          - the inference survives the addition
%       (or its base context was already incoherent, so there is nothing to
%        defeat — reported as coherent and skipped by discovery).
%     incoherent(defeated(Id, Set))     - adding Set made a coherent context
%       incoherent; some single member or structural pair is responsible.
%     incoherent(emergent_defeat(Id, Set)) - the set is jointly incoherent but
%       no single added member defeats it and no literal pair clashes: an
%       emergent material-incompatibility hyperedge.
classify_defeat(Id, DefeaterSet, Outcome) :-
    classify_defeat_witness(Id, DefeaterSet, Outcome, _).


%!  classify_defeat_witness(+Id, +DefeaterSet, -Outcome, -Witness) is det.
%
%   classify_defeat/3 plus a proof object for humans and graph exporters. The
%   witness explains which consequence source fired; if the result is emergent,
%   it also records the one-element-removal checks that prove minimality.
classify_defeat_witness(Id, DefeaterSet, Outcome,
                        _{kind: defeat_classification,
                          inference_id: Id,
                          premises: Premises,
                          conclusion: Conclusion,
                          added_commitments: DefeaterSet,
                          combined_context: Combined,
                          result_kind: ResultKind,
                          cause: Cause,
                          minimality: Minimality}) :-
    material_inference(Id, Premises, Conclusion),
    ( ctx_incoherent_witness(Premises, BaseCause)
    ->  Combined = Premises,
        Outcome = coherent,                       % base not entitled; skip
        ResultKind = base_already_incoherent,
        Cause = BaseCause,
        Minimality = not_applicable
    ;   append(Premises, DefeaterSet, Combined0),
        Combined = Combined0,
        ( ctx_incoherent_witness(Combined, Cause)
        ->  ( emergent_witness(Premises, DefeaterSet, Combined, Minimality)
            ->  Outcome = incoherent(emergent_defeat(Id, DefeaterSet)),
                ResultKind = emergent_defeat
            ;   Outcome = incoherent(defeated(Id, DefeaterSet)),
                ResultKind = defeated,
                Minimality = not_minimal_or_structural
            )
        ;   Outcome = coherent,
            ResultKind = survived,
            Cause = no_incoherence_found,
            Minimality = not_applicable
        )
    ).


%!  emergent_witness(+Premises, +DefeaterSet, +Combined, -Witness) is semidet.
%
%   Proves that Combined is a minimal incoherent set by checking every context
%   created by removing one commitment. Premises and DefeaterSet are kept in the
%   signature so callers can pass the same information used for the verdict.
emergent_witness(_Premises, _DefeaterSet, Combined,
                 _{kind: minimal_incoherent_context,
                   structural_clash: absent,
                   context_size: Len,
                   removal_checks: Checks}) :-
    \+ incoherent_base(Combined),
    length(Combined, Len),
    Len >= 3,
    findall(Removed-Smaller, select(Removed, Combined, Smaller), Pairs),
    forall(member(_-Smaller, Pairs),
           \+ ctx_incoherent(Smaller)),
    maplist(removal_check, Pairs, Checks).

removal_check(Removed-Smaller,
              _{removed: Removed,
                remaining_context: Smaller,
                remaining_coherent: true}).


%!  discover_defeat(?Id, -DefeaterSet) is nondet.
%
%   Defeater sets (size 1..2) that defeat the inference, for sweeping/discovery.
discover_defeat(Id, DefeaterSet) :-
    material_inference(Id, _, _),
    defeater_vocabulary(Vocabulary),
    between(1, 2, K),
    n_subset(K, Vocabulary, DefeaterSet),
    classify_defeat(Id, DefeaterSet, Outcome),
    defeat_outcome(Outcome).

defeat_outcome(incoherent(_)).

n_subset(0, _, []) :- !.
n_subset(N, [X|Xs], [X|Rest]) :-
    N > 0, N1 is N - 1,
    n_subset(N1, Xs, Rest).
n_subset(N, [_|Xs], Rest) :-
    N > 0,
    n_subset(N, Xs, Rest).
