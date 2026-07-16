/** <module> Teacher-layer composition for a render document
 *
 * Composes the `doc.teacher` field of the frozen render contract
 * (docs/research_assets/specs/2026-06-23-render-contract-frozen.md, §1.4c) for a
 * single arithmetic practice (the practice a content claim enacts). The layer
 * reads four already-existing witness/data sources and reports them as plain
 * teacher-facing strings; it composes, it does not compute new mathematics.
 *
 * The composition is routed by the practice's grounding metaphor
 * (`grounding_to_primitive:primitive_for_practice/3` selects the metaphor whose
 * visual primitive the claim draws on; `grounding_metaphors:
 * grounding_metaphor_for_practice/2` names the full metaphor id). Off that
 * metaphor the four channels are read:
 *
 *   1. standard    — the curricular strand the practice answers to, from
 *                    `mua_relations:practice_kind/3` (Operation + practice kind).
 *                    This is the operation-domain handle the practice falls
 *                    under, not a faked standard code; a practice with no
 *                    `practice_kind/3` fact omits the field.
 *   2. embodied    — the body relation, from `grounding_metaphors:
 *                    metaphor_source_practice/2` plus a one-sentence gloss of
 *                    the source practice (placing segments end to end, pooling
 *                    collections, moving along a path, fitting parts together).
 *   3. incompatibility_penumbra — what the representation rules out, from
 *                    `misconception_registry:incompatibility_with_witness/3`:
 *                    the paired deformation the productive scheme is
 *                    incompatible with. Omitted when the practice has no
 *                    registered deformation pair.
 *   4. breaks_at + repair — where the metaphor cannot follow and the
 *                    exfoliation move, from `grounding_metaphors:
 *                    metaphor_breaks_at/3` and `metaphor_repair/4`. Travel
 *                    together: a break with no repair (or vice versa) is
 *                    dropped. A repair recorded as `none_in_this_metaphor,
 *                    see(OtherMetaphor)` reads as "switch to <Other>".
 *
 * Honest thinness: any channel whose source is empty for a given practice is
 * omitted from the dict rather than invented. The witness the module returns
 * records, per channel, whether it was populated or thin, so a reader can see
 * which of the four were available.
 *
 * Render contract: docs/research_assets/specs/2026-06-23-render-contract-frozen.md
 */

:- module(teacher_layer,
          [ teacher_layer/2   % +Practice, -Dict
          ]).

:- use_module(pml(mua_relations),
              [ practice_kind/3
              ]).
:- use_module(strategies(render/grounding_to_primitive),
              [ primitive_for_practice/3
              ]).
:- use_module(formalization(grounding_metaphors),
              [ grounding_metaphor_for_practice/2,
                metaphor_source_practice/2,
                metaphor_breaks_at/3,
                metaphor_repair/4,
                metaphor_short_name/2
              ]).
:- use_module(math(action_automata_registry),
              [ action_automaton_pair/4
              ]).
:- use_module(misconceptions(misconception_registry),
              [ incompatibility_with_witness/3
              ]).
:- use_module(library(lists)).


%!  teacher_layer(+Practice, -Dict) is det.
%
%   Compose the teacher layer for a claim's Practice. Dict carries the present
%   channels among `standard`, `embodied`, `incompatibility_penumbra`,
%   `breaks_at`, `repair` (plus a `witness` recording per-channel presence).
%   Channels with a thin source are omitted, never invented. Always succeeds:
%   a practice with no usable source yields a dict whose witness reports every
%   channel thin.
teacher_layer(Practice, Dict) :-
    layer_metaphor(Practice, MetaphorId),
    channel_standard(Practice, StdPairs, StdState),
    channel_embodied(MetaphorId, EmbPairs, EmbState),
    channel_penumbra(Practice, PenPairs, PenState),
    channel_breaks_repair(MetaphorId, BrkPairs, BrkState),
    append([StdPairs, EmbPairs, PenPairs, BrkPairs], FieldPairs),
    Witness = _{ kind: teacher_layer,
                 practice: Practice,
                 metaphor_id: MetaphorId,
                 channels: _{ standard: StdState,
                              embodied: EmbState,
                              incompatibility_penumbra: PenState,
                              breaks_at: BrkState },
                 source: teacher_layer_composition_over_existing_witnesses },
    dict_pairs(Dict, _, [witness-Witness | FieldPairs]).


%!  layer_metaphor(+Practice, -MetaphorId) is det.
%
%   The full grounding-metaphor id that routes the layer. Prefer the metaphor
%   whose visual primitive the claim draws as `primary`
%   (`primitive_for_practice/3`); fall back to any grounding metaphor the
%   practice carries; fall back to `no_grounding_metaphor` when the practice is
%   ungrounded (e.g. a without-ground deformation), so the embodied/break
%   channels report thin rather than throwing.
layer_metaphor(Practice, MetaphorId) :-
    ( primary_metaphor(Practice, MetaphorId0)
    -> MetaphorId = MetaphorId0
    ;  grounding_metaphor_for_practice(Practice, MetaphorId0)
    -> MetaphorId = MetaphorId0
    ;  MetaphorId = no_grounding_metaphor
    ).

% The metaphor id behind the claim's primary visual primitive, if any.
primary_metaphor(Practice, MetaphorId) :-
    primitive_for_practice(Practice, _Primitive, primary),
    grounding_metaphor_for_practice(Practice, MetaphorId),
    metaphor_short_name_routes(MetaphorId, Practice),
    !.

% A grounding metaphor carried by the practice; keeps `primary_metaphor`
% deterministic by committing to the first that also names a source practice.
metaphor_short_name_routes(MetaphorId, _Practice) :-
    metaphor_source_practice(MetaphorId, _).


% --- Channel 1: standard ------------------------------------------------------

%!  channel_standard(+Practice, -Pairs, -State) is det.
%
%   The curricular strand the practice answers to: Operation + practice kind
%   from `practice_kind/3`. Not a standard code; the operation-domain handle the
%   claim falls under. Thin when no `practice_kind/3` fact exists.
channel_standard(Practice, [standard-Std], present) :-
    practice_kind(Practice, Operation, Kind),
    !,
    humanize_atom(Operation, OpPhrase),
    humanize_atom(Kind, KindPhrase),
    format(string(Std), "~w strand: ~w", [OpPhrase, KindPhrase]).
channel_standard(p_relational_equals_balance_preservation,
                 [standard-"algebra strand: relational equals balance preservation"],
                 present) :- !.
channel_standard(_Practice, [], thin).


% --- Channel 2: embodied basis ------------------------------------------------

%!  channel_embodied(+MetaphorId, -Pairs, -State) is det.
%
%   The body relation: the metaphor's source practice plus a one-sentence
%   gloss. Thin when the metaphor names no source practice.
channel_embodied(MetaphorId, [embodied-Emb], present) :-
    metaphor_source_practice(MetaphorId, SourcePractice),
    source_practice_gloss(SourcePractice, Emb),
    !.
channel_embodied(balance_preservation_schema,
                 [embodied-"Keep two sides level by making the same change to both pans."],
                 present) :- !.
channel_embodied(_MetaphorId, [], thin).

%!  source_practice_gloss(+SourcePractice, -Sentence) is det.
%
%   One plain sentence naming the bodily action the metaphor draws on. Each is
%   a verb-first description of what the body does, not a visual claim.
source_practice_gloss(p_placing_segments_end_to_end,
    "Place equal segments end to end and compare their lengths.").
source_practice_gloss(p_comparing_segment_lengths,
    "Lay segments alongside one another and compare their lengths.").
source_practice_gloss(p_pooling_of_collections,
    "Pool collections of objects together and count the result.").
source_practice_gloss(p_taking_collection_from_collection,
    "Take a smaller collection of objects out of a larger one.").
source_practice_gloss(p_fitting_parts_together,
    "Fit equal parts together into a whole object.").
source_practice_gloss(p_splitting_object_into_parts,
    "Split a whole object into equal parts.").
source_practice_gloss(p_moving_along_a_path,
    "Move along a path, away from or back toward a starting point.").
source_practice_gloss(p_rotation_in_the_plane,
    "Turn a segment through a half-turn in the plane.").


% --- Channel 3: incompatibility penumbra --------------------------------------

%!  channel_penumbra(+Practice, -Pairs, -State) is det.
%
%   What the productive scheme rules out: the paired deformation from the
%   misconception registry. Sources the deformation via the practice's
%   productive strategy (`practice_kind/3` -> `action_automaton_pair/4`) and
%   confirms the incompatibility holds (`incompatibility_with_witness/3`). Thin
%   when the practice has no registered productive/deformation pair.
channel_penumbra(Practice, [incompatibility_penumbra-Pen], present) :-
    practice_kind(Practice, Operation, Productive),
    action_automaton_pair(Operation, Productive, Deformation, Family),
    incompatibility_with_witness(Deformation, strategy(Operation, Productive), _Witness),
    !,
    humanize_atom(Deformation, DefPhrase),
    humanize_atom(Family, FamPhrase),
    ( Family == Deformation
    -> format(string(Pen),
              "Rules out the ~w deformation: the representation will not \
sustain it.",
              [DefPhrase])
    ;  format(string(Pen),
              "Rules out the ~w deformation (~w): the representation will not \
sustain it.",
              [DefPhrase, FamPhrase])
    ).
channel_penumbra(_Practice, [], thin).


% --- Channel 4: breaks_at + repair (travel together) --------------------------

%!  channel_breaks_repair(+MetaphorId, -Pairs, -State) is det.
%
%   Where the metaphor cannot follow, with the repair move. A break and its
%   repair travel together: a break with no repair, or a repair sentinel with
%   no exfoliation target, drops the pair. Collects every break that has a
%   usable repair into `breaks_at` (a list of {inference, reason} dicts) and
%   names one repair sentence in `repair`.
channel_breaks_repair(MetaphorId, [breaks_at-Breaks, repair-Repair], present) :-
    findall(B-RepairText,
            ( metaphor_breaks_at(MetaphorId, Inference, Reason),
              metaphor_repair(MetaphorId, Inference, RepairMetaphor, Mechanism),
              repair_sentence(RepairMetaphor, Mechanism, RepairText),
              break_dict(Inference, Reason, B)
            ),
            Found),
    Found \= [],
    !,
    pairs_keys_values(Found, BreakList, RepairTexts),
    Breaks = BreakList,
    RepairTexts = [Repair | _].
channel_breaks_repair(_MetaphorId, [], thin).

%!  break_dict(+Inference, +Reason, -Dict) is det.
%   The inference is a functor handle (`negative_numbers`, `zero_as_an_object`);
%   humanize it to plain words so the teacher panel reads as English rather than
%   a raw atom. The reason is already prose where it is a string.
break_dict(Inference, Reason, _{ inference: InferenceStr, reason: ReasonStr }) :-
    inference_string(Inference, InferenceStr),
    reason_string(Reason, ReasonStr).

inference_string(Inference, Str) :-
    ( atom(Inference) -> humanize_atom(Inference, Str)
    ; string(Inference) -> Str = Inference
    ; term_string(Inference, Str)
    ).

reason_string(Reason, Str) :-
    ( string(Reason) -> Str = Reason
    ; atom(Reason)   -> humanize_atom(Reason, Str)
    ; term_string(Reason, Str)
    ).

%!  repair_sentence(+RepairMetaphor, +Mechanism, -Sentence) is semidet.
%
%   The exfoliation move. A named repair metaphor reads as a switch to that
%   metaphor. The sentinel `none_in_this_metaphor` with a `see(Other)` mechanism
%   reads as a switch to Other. A sentinel with no `see/1` pointer fails, so the
%   break that has no repair is dropped (breaks and repairs travel together).
repair_sentence(none_in_this_metaphor, see(OtherMetaphor), Sentence) :-
    !,
    metaphor_display_name(OtherMetaphor, Name),
    format(string(Sentence), "Switch to ~w.", [Name]).
repair_sentence(none_in_this_metaphor, _Mechanism, _Sentence) :-
    !,
    fail.
repair_sentence(RepairMetaphor, _Mechanism, Sentence) :-
    metaphor_display_name(RepairMetaphor, Name),
    format(string(Sentence), "Switch to ~w.", [Name]).

%!  metaphor_display_name(+MetaphorId, -Name) is det.
metaphor_display_name(MetaphorId, Name) :-
    ( metaphor_short_name(MetaphorId, Short)
    -> atom_string(Short, Name)
    ;  humanize_atom(MetaphorId, Name)
    ).


% --- Small text helpers -------------------------------------------------------

%!  humanize_atom(+Atom, -String) is det.
%   Underscores -> spaces; leaves the rest as written (these are functor handles,
%   not sentences, so no capitalization is forced).
humanize_atom(Atom, String) :-
    ( atom(Atom) -> atom_string(Atom, S0) ; term_string(Atom, S0) ),
    split_string(S0, "_", "", Words),
    atomic_list_concat(Words, " ", Phrase),
    atom_string(Phrase, String).
