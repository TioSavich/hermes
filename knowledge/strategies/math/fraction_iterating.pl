/** <module> Iterating automaton — make N connected copies of a part
 *
 * A base-agnostic finite-state automaton for the iterating operation, built by
 * algorithmic elaboration of *multiplication* (repeated connected addition)
 * over grounded `recollection` quantities. Iterating takes a unit part and a
 * count N and produces N connected copies — the iterated quantity. When the
 * part is a `unit(divaded(D, W))`, the result is the fraction N/D relative to W.
 *
 * This is the second primitive automaton in the Band-2 (splitting) build. With
 * `fraction_partitioning` it lets us *probe* (not assert) the splitting
 * invariant: partition(D) ∘ iterate(D) = identity on the whole.
 *
 * == The automaton as a tuple  M_iterate = (Q, Σ, δ, q0, F) ==
 *
 *   Q  = { q_start, q_iterate, q_done }
 *   Σ  = the part P and the count N (no fixed base — N is any positive
 *        recollection)
 *   q0 = state(q_start, P, N, 0, [])
 *   F  = { q_done }
 *   state(Name, Part, Target, MadeCount, UnitsAcc)
 *
 *   δ (transition table):
 *   ┌────────────┬────────────┬────────────┬──────────────────────────────────┐
 *   │ from        │ guard      │ to          │ effect                            │
 *   ├────────────┼────────────┼────────────┼──────────────────────────────────┤
 *   │ q_start     │ N > 0      │ q_iterate   │ Made:=0, Units:=[]                │
 *   │ q_iterate   │ Made < N   │ q_iterate   │ Units:=[P|Units], Made:=Made+1    │
 *   │ q_iterate   │ Made = N   │ q_done      │ —                                 │
 *   └────────────┴────────────┴────────────┴──────────────────────────────────┘
 *
 * == Brandom / MUA ==
 *
 * The practice enacted is `p_unit_fraction_iteration`, sufficient for
 * `v_fraction_unit`. `formal/pml/mua_relations.pl` already records
 * `pp_necessary(p_unit_fraction_partition, p_unit_fraction_iteration)` —
 * partitioning is PP-necessary for iterating (you cannot iterate a part you
 * cannot first cut and disembed). The q_iterate loop is the *algorithmic
 * elaboration of multiplication as repeated connected addition*: the same
 * repeated-grouping skeleton as `smr_mult_*`, applied to a single unit part.
 * So **multiplication is PP-necessary for iterating**, and the vocabulary
 * sufficient for the elaboration is again just `v_fraction_unit`.
 *
 * == Reversibility and the inverse probe ==
 *
 * `count_copies/3` reads the iteration as a relation (given the connected
 * copies, recover the part and the count). `partition_iterate_inverse/2` runs
 * partition forward and iterate "backward over the same base" and lets the
 * unifier confirm the result reconstitutes the whole — the inverse invariant
 * the splitting scheme recognizes. We surface the invariant; we do not claim
 * the machine *is* splitting (the felt simultaneity stays off-machine).
 */

:- module(fraction_iterating,
          [ run_iterate/4,                % +Part, +CountRec, -Units, -History
            iterated_fraction/3,          % +UnitPart, +CountRec, -Fraction
            count_copies/3,               % +Units, ?Part, ?CountRec  (reversible)
            partition_iterate_inverse/2,  % +Whole, +BaseRec
            solve_for_unit/5              % +PRec, +QRec, +Total, -Unit, -History
          ]).

:- use_module(formalization(grounded_arithmetic),
              [ integer_to_recollection/2, recollection_to_integer/2,
                successor/2, zero/1, equal_to/2, greater_than/2, smaller_than/2,
                incur_cost/1 ]).
:- use_module(math(fraction_partitioning),
              [ run_partition/5, disembedded/3 ]).
:- use_module(math(divaded_fractional_units), [ inside_partition/3 ]).
:- use_module(library(lists), [member/2, append/3]).


%!  run_iterate(+Part, +CountRec, -Units, -History) is semidet.
%
%   Make CountRec connected copies of Part. Units is the list of copies (the
%   iterated quantity); History is the trace.
run_iterate(Part, Count, Units, History) :-
    incur_cost(inference),
    zero(Z0),
    drive_iter(state(q_start, Part, Count, Z0, []), [], RevHist, Final),
    reverse(RevHist, History),
    Final = state(q_done, _, _, _, Units).

drive_iter(State, Acc, Acc, State) :-
    State = state(q_done, _, _, _, _), !.
drive_iter(State, Acc, Final, FinalState) :-
    transition_iter(State, Next, Interp),
    State = state(Name, _, _, _, _),
    drive_iter(Next, [step(Name, State, Interp) | Acc], Final, FinalState).

% δ — the transition table (see module header).
transition_iter(state(q_start, P, N, _, _),
                state(q_iterate, P, N, Z, []),
                'Begin: make N connected copies of the part (elaborates multiplication as repeated connected addition).') :-
    positive_rec(N),
    zero(Z).
transition_iter(state(q_iterate, P, N, Made, Acc),
                state(q_iterate, P, N, Made1, [P | Acc]),
                Interp) :-
    smaller_than(Made, N),
    successor(Made, Made1),
    incur_cost(unit_count),
    recollection_to_integer(Made1, K),
    recollection_to_integer(N, Nn),
    format(string(Interp), 'Iterate connected copy ~w of ~w.', [K, Nn]).
transition_iter(state(q_iterate, P, N, Made, Acc),
                state(q_done, P, N, Made, Acc),
                'N connected copies made; the iterated quantity is complete.') :-
    equal_to(Made, N).


%!  iterated_fraction(+UnitPart, +CountRec, -Fraction) is det.
%
%   Name the iterated quantity as a fraction, relative to the unit part's whole.
%   N copies of 1/D is N/D.
iterated_fraction(unit(divaded(D, _Whole)), Count, fraction(N, Dn)) :-
    recollection_to_integer(Count, N),
    recollection_to_integer(D, Dn).


%!  count_copies(+Units, ?Part, ?CountRec) is semidet.
%
%   The iteration relation read backwards: every element of Units is the same
%   Part, and CountRec is how many. Reversible recovery of (Part, Count).
count_copies([P | Rest], P, Count) :-
    forall(member(X, [P | Rest]), X == P),
    length([P | Rest], N),
    integer_to_recollection(N, Count).


%!  partition_iterate_inverse(+Whole, +BaseRec) is semidet.
%
%   The inverse probe. Partition the whole into D parts (forward), disembed the
%   unit part, then iterate it D times; succeed iff the D connected copies
%   reconstitute the whole. This is partition(D) ∘ iterate(D) = identity — the
%   equality the splitter recognizes between the two actions, surfaced by the
%   unifier rather than asserted.
partition_iterate_inverse(Whole, Base) :-
    run_partition(Whole, Base, UnitPart, _Parts, _H1),
    disembedded(UnitPart, Whole, Base),
    run_iterate(UnitPart, Base, Units, _H2),
    recollection_to_integer(Base, D),
    length(Units, D),
    forall(member(X, Units), X == UnitPart),
    inside_partition(UnitPart, Whole, Base).


%!  solve_for_unit(+PRec, +QRec, +Total, -Unit, -History) is semidet.
%
%   Band 5 (fractions -> algebra): solve (P/Q) * x = Total for the unknown x by
%   the splitting inverse, now applied to an UNKNOWN. Partition Total into P
%   equal parts (recovering one q-th of x = Total/P), then iterate that part Q
%   times to recover x = (Q/P) * Total. Whole-number coefficient is Q = 1
%   (n * x = Total -> x = Total/n, a single partition; e.g. 7x = 28 -> x = 4).
%   The unknown is treated as a partitionable/iterable quantity — the move
%   Hackenberg & Lee (2015) identify as shared between fractions-as-numbers and
%   reasoning with quantitative unknowns. Partition undoing iteration is the
%   same inverse splitting recognizes; here it solves rather than verifies.
solve_for_unit(P, Q, Total, Unit, History) :-
    run_partition(Total, P, UnitPart, _Parts, H1),
    disembedded(UnitPart, Total, P),
    run_iterate(UnitPart, Q, Unit, H2),
    append(H1, H2, History).


positive_rec(N) :-
    zero(Z),
    greater_than(N, Z).
