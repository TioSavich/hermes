% PURPOSE: Lesson-level gap queries setting the action-automata registry's covered moves against a lesson chart's anticipated moves (unanticipated_strategies/2, licensed_moves/2, anticipated_moves/2).
/** <module> Lesson-vs-registry gap: licensed moves a lesson does not anticipate

The monitoring chart records the strategies a lesson anticipates
(lesson_monitoring:lesson_strategy/4). The action-automata registry records,
per operation, the action kinds it covers — productive strategies together
with their deformations (action_automata_registry:action_automaton_cluster/3).
This module joins the two at the LESSON level and returns the difference as
flat Operation-Kind pairs, one list per lesson code.

A register note on "licensed": here it means REGISTRY COVERAGE — the moves
this codebase can run and reason about for an operation — not normative
entitlement in the scorekeeping sense. The registry does not entitle a student
to a move; it records which moves the formalization has encoded, deformations
included. The gap this module computes is therefore "encoded but
unanticipated," the concrete opening described in
docs/research/2026-06-18-anticipation-and-the-unanticipated.md
("Where the limit already lives in the code").

The per-operation computation lives in
lesson_monitoring:licensed_but_unanticipated/2 (operation_gap/4 rows);
unanticipated_strategies/2 flattens those rows rather than recomputing them,
so this surface cannot drift from that one. Three boundary shapes deserve
care. An empty gap can mean the lesson anticipates every covered move (no
current lesson does) or that its anticipated operations have no registry
source at all — as of 2026-07-16 no real chart exhibits the absent-source
case either (the registry now carries geometry action-kind rows), but it
remains reachable for any operation the registry has not encoded, and the
tests keep it guarded with a fixture. A gap equal to the whole licensed set
means the lesson's anticipated kinds never name registry action kinds
(geometry scope-sequence lessons, whose "strategies" are concept ids — the
two vocabularies do not intersect). licensed_moves/2 tells the cases apart:
it is empty exactly when no registry source applies, and comparing the gap
against it exposes the vocabulary mismatch.
*/
:- module(lesson_gap,
          [ unanticipated_strategies/2,
            licensed_moves/2,
            anticipated_moves/2
          ]).

:- use_module(im_lessons(lesson_monitoring),
              [ lesson_strategy/4,
                licensed_but_unanticipated/2
              ]).
:- use_module(math(action_automata_registry),
              [ action_automaton_cluster/3
              ]).

%!  anticipated_moves(+LessonCode, -Moves) is det.
%
%   Moves is the sorted list of Operation-Kind pairs the lesson's monitoring
%   chart anticipates, exactly as lesson_strategy/4 reports them. Geometry
%   rows (Operation = geometry, Kind = a concept id) are kept: this predicate
%   reports the anticipation as recorded, whether or not a registry source
%   exists for the operation.
anticipated_moves(Code, Moves) :-
    findall(Operation-Kind,
            lesson_strategy(Code, Operation, Kind, _Info),
            Moves0),
    sort(Moves0, Moves).

%!  licensed_moves(+LessonCode, -Moves) is det.
%
%   Moves is the sorted list of Operation-Kind pairs the registry covers for
%   the operations this lesson anticipates at least one strategy in. Only
%   operations with a registry source contribute: a lesson anticipating only
%   operations the registry has not encoded yields []. Every operation the
%   current monitoring charts anticipate, geometry included, now has
%   action_automaton_cluster/3 rows, so the empty case survives only in test
%   fixtures. "Licensed" here is registry coverage, not normative entitlement;
%   the module header carries the full register note.
licensed_moves(Code, Moves) :-
    findall(Operation-Kind,
            ( anticipated_operation(Code, Operation),
              action_automaton_cluster(Operation, Kind, _Cluster)
            ),
            Moves0),
    sort(Moves0, Moves).

%!  unanticipated_strategies(+LessonCode, -UnanticipatedMoves) is det.
%
%   UnanticipatedMoves is the sorted list of Operation-Kind pairs the registry
%   covers but the lesson's chart does not anticipate: licensed_moves/2 minus
%   anticipated_moves/2, restricted to operations the lesson anticipates and
%   the registry sources. Flattened from
%   lesson_monitoring:licensed_but_unanticipated/2, which owns the
%   computation. For a geometry scope-sequence lesson the result equals the
%   full licensed set, because anticipated concept ids never name registry
%   action kinds. An empty result for a lesson whose anticipated operations
%   carry no registry source marks an absent source, not a completed
%   anticipation; the incompleteness argument in the anticipation doc says no
%   chart exhausts its registry.
unanticipated_strategies(Code, UnanticipatedMoves) :-
    licensed_but_unanticipated(Code, OperationGaps),
    findall(Operation-Kind,
            ( member(operation_gap(Operation, _Licensed, _Anticipated, Kinds),
                     OperationGaps),
              member(Kind, Kinds)
            ),
            Moves0),
    sort(Moves0, UnanticipatedMoves).

% Distinct operations the lesson anticipates. setof/3 fails on a lesson with
% no strategy rows, so a strategy-free lesson contributes no licensed moves.
anticipated_operation(Code, Operation) :-
    setof(Op, K^I^lesson_strategy(Code, Op, K, I), Operations),
    member(Operation, Operations).
