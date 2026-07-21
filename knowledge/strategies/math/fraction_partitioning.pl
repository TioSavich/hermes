/** <module> Partitioning automaton — break a whole into D equal parts
 *
 * A base-agnostic finite-state automaton for the partitioning operation, built
 * by algorithmic elaboration of *division* over grounded `recollection`
 * quantities, reusing the `divaded_fractional_units` representation as its
 * primitive. Partitioning takes a referent whole and a base D and produces D
 * equal unit parts, each `unit(divaded(D, Whole))`, that exactly reconstitute
 * the whole.
 *
 * This is a *primitive* automaton in the Band-2 (splitting) build: splitting is
 * the recognition that partitioning and iterating are mutual inverses. Here we
 * build partitioning on its own, reversibly; `fraction_iterating` builds the
 * other half and probes the inverse relationship by composition.
 *
 * == The automaton as a tuple  M_partition = (Q, Σ, δ, q0, F) ==
 *
 *   Q  = { q_start, q_partition, q_verify, q_done }
 *   Σ  = the base D and the referent Whole (the operands; no fixed base — D is
 *        any positive recollection, so base-5 partition is the same machine)
 *   q0 = state(q_start, Whole, D, 0, [])
 *   F  = { q_done }
 *   state(Name, Whole, Base, MadeCount, PartsAcc)
 *
 *   δ (transition table):
 *   ┌────────────┬──────────────────────────────┬────────────┬───────────────────────────┐
 *   │ from        │ guard                         │ to          │ effect                     │
 *   ├────────────┼──────────────────────────────┼────────────┼───────────────────────────┤
 *   │ q_start     │ D > 0                         │ q_partition │ Made:=0, Acc:=[]           │
 *   │ q_partition │ Made < D                      │ q_partition │ Acc:=[1/D|Acc], Made:=Made+1│
 *   │ q_partition │ Made = D                      │ q_verify    │ —                          │
 *   │ q_verify    │ inside_partition(1/D, W, D)   │ q_done      │ certify each part is 1/D   │
 *   └────────────┴──────────────────────────────┴────────────┴───────────────────────────┘
 *
 * == Brandom / MUA: the necessary-and-sufficient vocabularies ==
 *
 * The practice this automaton enacts is `p_unit_fraction_partition`, sufficient
 * for the vocabulary `v_fraction_unit` (pv_sufficient, already in
 * `formal/pml/mua_relations.pl`). The dealing loop (q_partition) is the *algorithmic
 * elaboration of equal-sharing division*: the same deal-one-share-at-a-time
 * skeleton as `smr_div_dealing_by_ones`, applied to a continuous whole rather
 * than a discrete collection. So **division is PP-necessary for partitioning**
 * (you must be able to share equally to cut equal parts), and the vocabulary
 * sufficient to establish the elaboration is just `v_fraction_unit` (referent
 * whole + unit part + the closing cycle) — no new operative vocabulary is
 * needed beyond what `divaded_fractional_units` already supplies.
 *
 * == Reversibility ==
 *
 * `partitioned_unit/3` is the partition relation read as a relation: a part
 * `unit(divaded(D, W))` carries its own whole and base, so the machine reverses
 * structurally (given the unit part, recover W and D). This is what lets
 * `fraction_iterating:partition_iterate_inverse/2` ask the unifier to *find*
 * the inverse rather than stipulate it.
 */

:- module(fraction_partitioning,
          [ run_partition/5,        % +Whole, +BaseRec, -UnitPart, -Parts, -History
            partitioned_unit/3,     % ?Whole, ?BaseRec, ?UnitPart   (reversible)
            whole_of_unit/2,        % +UnitPart, -Whole
            base_of_unit/2,         % +UnitPart, -BaseRec
            run_disembed/4,         % +UnitPart, +Whole, +BaseRec, -History
            disembedded/3,          % +UnitPart, +Whole, +BaseRec
            run_recursive_partition/5, % +Whole, +OuterRec, +InnerRec, -InnerPart, -History
            recursive_part_bases/3  % ?InnerPart, ?OuterRec, ?InnerRec   (reversible)
          ]).

:- use_module(formalization(grounded_arithmetic),
              [ integer_to_recollection/2, recollection_to_integer/2,
                successor/2, zero/1, equal_to/2, greater_than/2, smaller_than/2,
                incur_cost/1 ]).
:- use_module(math(divaded_fractional_units),
              [ inside_partition/3, iterable_to_reconstitute/3 ]).
:- use_module(library(lists), [member/2, append/3]).


%!  run_partition(+Whole, +BaseRec, -UnitPart, -Parts, -History) is semidet.
%
%   Partition Whole into BaseRec equal parts. UnitPart is the unit fraction
%   `unit(divaded(BaseRec, Whole))`; Parts is the list of D copies that
%   reconstitute the whole; History is the trace of the automaton's run.
run_partition(Whole, Base, UnitPart, Parts, History) :-
    incur_cost(inference),
    zero(Z0),
    drive_part(state(q_start, Whole, Base, Z0, []), [], RevHist, Final),
    reverse(RevHist, History),
    Final = state(q_done, _, _, _, Parts),
    UnitPart = unit(divaded(Base, Whole)).

drive_part(State, Acc, Acc, State) :-
    State = state(q_done, _, _, _, _), !.
drive_part(State, Acc, Final, FinalState) :-
    transition_part(State, Next, Interp),
    State = state(Name, _, _, _, _),
    drive_part(Next, [step(Name, State, Interp) | Acc], Final, FinalState).

% δ — the transition table (see module header).
transition_part(state(q_start, W, D, _, _),
                state(q_partition, W, D, Z, []),
                'Establish the referent whole; deal it into D equal parts (elaborates equal-sharing division).') :-
    positive_rec(D),
    zero(Z).
transition_part(state(q_partition, W, D, Made, Acc),
                state(q_partition, W, D, Made1, [Part | Acc]),
                Interp) :-
    smaller_than(Made, D),
    Part = unit(divaded(D, W)),
    successor(Made, Made1),
    incur_cost(unit_count),
    recollection_to_integer(Made1, K),
    recollection_to_integer(D, Dn),
    format(string(Interp), 'Cut equal part ~w of ~w.', [K, Dn]).
transition_part(state(q_partition, W, D, Made, Acc),
                state(q_verify, W, D, Made, Acc),
                'All D equal parts cut.') :-
    equal_to(Made, D).
transition_part(state(q_verify, W, D, Made, Acc),
                state(q_done, W, D, Made, Acc),
                'Certified: each part is 1/D, inside the whole and (once disembedded) iterable.') :-
    inside_partition(unit(divaded(D, W)), W, D).


%!  partitioned_unit(?Whole, ?BaseRec, ?UnitPart) is det.
%
%   The partition relation. Reversible: the unit part carries its whole and
%   base, so this runs in any mode.
partitioned_unit(Whole, Base, unit(divaded(Base, Whole))).

whole_of_unit(unit(divaded(_, Whole)), Whole).

base_of_unit(unit(divaded(Base, _)), Base).


%!  run_disembed(+UnitPart, +Whole, +BaseRec, -History) is semidet.
%
%   The disembedding gate (Hackenberg/Norton Stage 1 → Stage 2). Takes a part
%   that is inside the partitioned whole and certifies that it can be taken out
%   *without destroying the whole* — i.e. granted iterable-to-reconstitute
%   status — so that `fraction_iterating` can repeat it. For a `divaded` unit
%   both statuses already cohabit, so disembedding here *licenses* rather than
%   *constructs*; it is the necessary bridge between the two primitive automata.
%
%   M_disembed = ({q_embedded, q_disembedded}, δ, q_embedded, {q_disembedded}).
run_disembed(UnitPart, Whole, Base, History) :-
    incur_cost(inference),
    disembedded(UnitPart, Whole, Base),
    History = [ step(q_embedded, UnitPart,
                     'Part is inside the partitioned whole.'),
                step(q_disembedded, UnitPart,
                     'Part taken out without destroying the whole; now iterable.') ].

%!  disembedded(+UnitPart, +Whole, +BaseRec) is semidet.
disembedded(UnitPart, Whole, Base) :-
    inside_partition(UnitPart, Whole, Base),
    iterable_to_reconstitute(UnitPart, Whole, Base).


%!  run_recursive_partition(+Whole, +OuterBase, +InnerBase, -InnerPart, -History) is semidet.
%
%   Band 4 (fraction of a fraction): apply the partitioning automaton to its own
%   output. Partition the whole into OuterBase parts, disembed one part, then
%   partition *that part* into InnerBase parts. The inner part
%   `unit(divaded(InnerBase, unit(divaded(OuterBase, Whole))))` is 1/(OuterBase*
%   InnerBase) of the whole — the composite unit. The *recursion* (partitioning a
%   part rather than a fresh whole) is the cognitive content; the same primitive
%   automaton runs twice, the second time on a part.
run_recursive_partition(Whole, OuterBase, InnerBase, InnerPart, History) :-
    run_partition(Whole, OuterBase, OuterPart, _OuterParts, H1),
    disembedded(OuterPart, Whole, OuterBase),
    run_partition(OuterPart, InnerBase, InnerPart, _InnerParts, H2),
    append(H1, H2, History).

%!  recursive_part_bases(?InnerPart, ?OuterBase, ?InnerBase) is det.
%
%   The recursive-partition relation read as a relation: the nested part carries
%   both bases, so the composition reverses structurally.
recursive_part_bases(unit(divaded(InnerBase, unit(divaded(OuterBase, _Whole)))),
                     OuterBase, InnerBase).


positive_rec(D) :-
    zero(Z),
    greater_than(D, Z).
