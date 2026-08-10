:- encoding(utf8).
/** <module> r3_driver — the kernel re-derivation sweep, depth 1
 *
 * Run R3 of the design in
 * `.superpowers/sdd/task-2026-08-08-engineer-bigred-loops.md`: for each
 * contracted machine M, search the depth-1 kernel/gate composition space for a
 * composition whose result term is the SAME TERM as M's own on every sampled
 * input. A match is a `kernel_dependency` candidate with a byte-identical
 * bridge proof. An exhausted search with no match is a MEASURED RESISTER — the
 * row says how much was searched, so that a miss reads as work done rather
 * than as work skipped.
 *
 * WHY A SIBLING MODULE. loop_driver.pl carries R1 and R2 and their collected
 * rows; this file adds R3 without editing a line of it, so the R1/R2 Prolog
 * paths are unchanged by construction rather than by inspection. What R3 needs
 * from the substrate — the authored grids, the machine population, the one
 * seam that runs a machine on an input — it imports.
 *
 *   swipl -q -l paths.pl -l scripts/bigred/loops/r3_driver.pl \
 *         -g r3_driver:main_item -t halt
 *
 * THE COMPOSITION LANGUAGE. A depth-1 composition is
 *
 *     comp(1, Kernel, GateSpec, ArgSpec)
 *
 * where GateSpec and ArgSpec are the pilot's own gate and argument terms with
 * `in(Path)` in the slots a grid input fills and `const(Value)` in the slots an
 * authored constant fills. apply_composition/3 grounds those slots against a
 * real input and runs the kernel, so a composition recorded in a row is a term
 * a reader can run again. An unrunnable receipt licenses nothing, so the
 * fixture re-runs one from its printed string.
 *
 * WHAT DEPTH 1 CANNOT REACH, recorded rather than hidden. Two of the seven
 * kernels take structured arguments — refine_bracket_by_order wants a rational
 * bracket, compare_place_sequences_by_significance wants numeral/4 terms — and
 * no numeric grid leaf supplies either. At depth 1 they contribute zero
 * compositions, and every row says so in `kernels_unbindable`. Reaching them
 * needs a kernel whose OUTPUT is such a term feeding a second kernel, which is
 * depth 2 and a later wave.
 *
 * IDENTITY IS THE CANDIDATE TEST, AND IT IS STRICT. Result terms are compared
 * with ==/2 on whole terms, never with =:=. Two terms agreeing numerically
 * while disagreeing in what they built is the distinction this run exists to
 * record. A machine that calls a kernel and then renames or projects its
 * result is therefore NOT a candidate here, and measurement of that case is in
 * `nearest_miss`: the composition whose result shares a compound payload with
 * the machine's. That field names a projection gap; it certifies nothing.
 *
 * TIME. No Prolog time limit preempts a native builtin, so, exactly as
 * loop_driver.pl has it, the binding guard is the external watchdog in
 * run_loop_array.py. The per-application `call_with_time_limit/2` here is a
 * best-effort inner bound on runaway pure-Prolog work, and the cumulative
 * machine budget is checked between applications, where checking is cheap and
 * reliable.
 */

:- module(r3_driver,
          [ input_leaves/3,
            gate_spec/2,
            arg_spec/3,
            composition_space/3,
            apply_composition/3,
            composition_string/2,
            payload_relation/3,
            r3_row/2,
            main_item/0
          ]).

:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(time), [call_with_time_limit/2]).
:- use_module(library(http/json)).

% The substrate. Everything R3 borrows is already exported by the wave-1
% module; nothing here writes to it.
:- use_module(loop_driver,
              [ contracted_machine/1,
                machine_schema/2,
                grid_plan/3,
                grid_input/3,
                grid_point_count/2,
                aa_run/4
              ]).
:- use_module(strategies('abstraction/kernel_gate_pilot'),
              [ run_kernel/4 ]).


% ==========================================================================
% 1. DEFAULTS
%
% Every one of these is an item field first and a default second, so a
% fixture runs the same code on a small budget.
% ==========================================================================

default(machine_budget_s,      2700).   % 45 minutes, the design's guard
default(composition_timeout_s,  120).   % the design's per-composition-sample bound
default(sample_count,            10).   % the screen
default(verify_count,           100).   % the confirmation before a row writes
default(probe_multiple,          10).   % grid points visited per sample wanted
default(max_compositions,     20000).   % a stop against blow-up, not a design bound
default(max_verifications,       50).   % how many screen-passers get confirmed
default(max_leaves,               8).   % input leaves that may bind kernel slots
default(min_points,               2).   % below this a match is a coincidence

%!  design_total(-Total) is det.
%
%   The 110 the design asks for, read off the DEFAULTS rather than off the
%   item. An item that lowers sample_count would otherwise clear its own
%   lowered bar and stamp the row `evidence_strength: "design"` — a fixture's
%   small budget must not be able to certify itself as a full run.
design_total(Total) :-
    default(sample_count, Sample),
    default(verify_count, Verify),
    Total is Sample + Verify.


% ==========================================================================
% 2. INPUT LEAVES
%
% A composition binds kernel and gate slots to values read out of the input,
% so the first thing the search needs is the input's integer leaves under
% stable paths. Paths are dotted for nested objects and bracketed for list
% positions; the order is the sort order of the path, so two inputs of one
% schema yield the same paths in the same order.
%
% Non-integer leaves are counted separately rather than dropped silently.
% A geometry input's `scope` atom binds nothing at depth 1, and that is part
% of why the geometry machines resist — a row that did not carry the count
% could not say so.
% ==========================================================================

%!  input_leaves(+Input, +MaxLeaves, -Leaves) is det.
%
%   Leaves is leaves(IntegerLeaves, IntegerPathCount, OtherPathCount, Truncated),
%   where IntegerLeaves is a list of leaf(Path, Value).
input_leaves(Input, MaxLeaves, leaves(Kept, Total, Others, Truncated)) :-
    findall(leaf(Path, Value)-Class,
            leaf_of(Input, '', Path, Value, Class),
            Pairs),
    findall(L, member(L-integer, Pairs), Integers0),
    findall(P, member(leaf(P, _)-other, Pairs), OtherPaths),
    sort(Integers0, Integers),
    length(Integers, Total),
    length(OtherPaths, Others),
    (   Total > MaxLeaves
    ->  length(Kept, MaxLeaves),
        append(Kept, _, Integers),
        Truncated = true
    ;   Kept = Integers,
        Truncated = false
    ).

leaf_of(Value, Prefix, Path, Value, integer) :-
    integer(Value),
    !,
    leaf_path(Prefix, Path).
leaf_of(Dict, Prefix, Path, Value, Class) :-
    is_dict(Dict),
    !,
    dict_pairs(Dict, _, Pairs),
    member(Key-Sub, Pairs),
    extend_path(Prefix, Key, Extended),
    leaf_of(Sub, Extended, Path, Value, Class).
leaf_of(List, Prefix, Path, Value, Class) :-
    is_list(List),
    !,
    nth0(Index, List, Sub),
    format(atom(Suffix), '[~w]', [Index]),
    atom_concat(Prefix, Suffix, Extended),
    leaf_of(Sub, Extended, Path, Value, Class).
leaf_of(Value, Prefix, Path, Value, other) :-
    leaf_path(Prefix, Path).

leaf_path('', root) :- !.
leaf_path(Prefix, Prefix).

extend_path('', Key, Key) :- !.
extend_path(Prefix, Key, Extended) :-
    atomic_list_concat([Prefix, '.', Key], Extended).

%!  leaf_value(+Path, +Input, -Value) is semidet.
%
%   Read one leaf back out of an input. The inverse of the path the
%   enumeration built, so a composition term is portable across the inputs of
%   one schema.
leaf_value(root, Value, Value) :- !.
leaf_value(Path, Input, Value) :-
    atomic_list_concat(Steps, '.', Path),
    walk_steps(Steps, Input, Value).

walk_steps([], Value, Value).
walk_steps([Step|Rest], Current, Value) :-
    step_into(Step, Current, Next),
    walk_steps(Rest, Next, Value).

step_into(Step, Current, Next) :-
    (   sub_atom(Step, Before, _, 0, Bracketed),
        sub_atom(Bracketed, 0, 1, _, '['),
        sub_atom(Step, 0, Before, _, Key),
        sub_atom(Bracketed, 1, _, 1, IndexAtom),
        atom_number(IndexAtom, Index)
    ->  (   Key == ''
        ->  Held = Current
        ;   get_dict(Key, Current, Held)
        ),
        nth0(Index, Held, Next)
    ;   get_dict(Step, Current, Next)
    ).


% ==========================================================================
% 3. THE COMPOSITION SPACE
%
% gate_spec/2 and arg_spec/3 are the two authored halves. The cross product
% of them is the depth-1 space: the design's "compositions of the 7 kernels
% under the 8 gates, parameters bound to S's grid".
%
% Gate parameters come from the input's integer leaves, plus the constant 10
% for the four gates whose parameter is a radix or a unit boundary — ten is
% the inscription base the corpus runs in, and the pilot's own demo gates use
% it. The two rectangle gates take no constant: their parameter is an area or
% a perimeter read off the problem, and a constant there would be a made-up
% problem rather than a binding.
% ==========================================================================

%!  gate_spec(+Leaves, -GateSpec) is nondet.
gate_spec(_, integer_line).
gate_spec(_, ordered_rational_interval).
gate_spec(Leaves, Gate) :-
    member(Functor, [whole_number, unit_fraction, positional_numerals,
                     cardinality_in_base]),
    radix_parameter(Leaves, Parameter),
    Gate =.. [Functor, Parameter].
gate_spec(Leaves, Gate) :-
    member(Functor, [rectangle_area_product, rectangle_even_perimeter]),
    member(leaf(Path, _), Leaves),
    Gate =.. [Functor, in(Path)].

radix_parameter(_, const(10)).
radix_parameter(Leaves, in(Path)) :-
    member(leaf(Path, _), Leaves).

%!  arg_spec(+Kernel, +Leaves, -ArgSpec) is nondet.
%
%   The argument list for one kernel with its numeric slots bound to leaves.
%   Two kernels appear here with no clause and the omission is the finding:
%   refine_bracket_by_order and compare_place_sequences_by_significance take
%   structured arguments that no numeric leaf supplies.
arg_spec(complete_to_unit, Leaves, [part(in(Path))]) :-
    member(leaf(Path, _), Leaves).
arg_spec(iterate_to_target, Leaves,
         [start(in(StartPath)), delta(in(DeltaPath)),
          direction(Direction), output(Output)]) :-
    member(leaf(StartPath, _), Leaves),
    member(leaf(DeltaPath, _), Leaves),
    StartPath \== DeltaPath,
    member(Direction, [up, down]),
    member(Output, [endpoint, distance]).
arg_spec(partition_regroup, Leaves, [unit(Unit), plan(Plan)]) :-
    member(Unit, [one, whole]),
    member(leaf(Path, _), Leaves),
    member(Shape, [regroup, partition]),
    Plan =.. [Shape, in(Path)].
arg_spec(recollect_base_cycles, Leaves, [cardinality(in(Path))]) :-
    member(leaf(Path, _), Leaves).
arg_spec(enumerate_positive_integer_pairs, _, []).

%!  kernel_unbindable(?Kernel) is nondet.
kernel_unbindable(refine_bracket_by_order).
kernel_unbindable(compare_place_sequences_by_significance).

r3_kernel(complete_to_unit).
r3_kernel(iterate_to_target).
r3_kernel(partition_regroup).
r3_kernel(refine_bracket_by_order).
r3_kernel(compare_place_sequences_by_significance).
r3_kernel(recollect_base_cycles).
r3_kernel(enumerate_positive_integer_pairs).

%!  composition_space(+Leaves, +MaxCompositions, -Space) is det.
%
%   Space is space(Compositions, Enumerated, Capped). Compositions are dealt
%   round robin across the kernels, so a cap that bites removes the tail of
%   every kernel rather than the whole of the last one.
composition_space(Leaves, MaxCompositions, space(Compositions, Enumerated, Capped)) :-
    findall(Kernel-Bucket,
            ( r3_kernel(Kernel),
              findall(comp(1, Kernel, GateSpec, ArgSpec),
                      ( arg_spec(Kernel, Leaves, ArgSpec),
                        gate_spec(Leaves, GateSpec) ),
                      Bucket)
            ),
            Buckets0),
    findall(Bucket, member(_-Bucket, Buckets0), Buckets),
    deal_round_robin(Buckets, All),
    length(All, Enumerated),
    (   Enumerated > MaxCompositions
    ->  length(Compositions, MaxCompositions),
        append(Compositions, _, All),
        Capped = true
    ;   Compositions = All,
        Capped = false
    ).

deal_round_robin(Buckets, Dealt) :-
    exclude(==([]), Buckets, NonEmpty),
    (   NonEmpty == []
    ->  Dealt = []
    ;   findall(Head, member([Head|_], NonEmpty), Heads),
        findall(Tail, member([_|Tail], NonEmpty), Tails),
        deal_round_robin(Tails, Rest),
        append(Heads, Rest, Dealt)
    ).

%!  apply_composition(+Composition, +Input, -Result) is semidet.
%
%   Ground the composition's slots against this input and run the kernel.
%   Fails when a slot has no value, when the gate refuses the parameter, or
%   when the kernel has no clause for that gate — all three are ordinary
%   non-applicability, not faults.
apply_composition(comp(1, Kernel, GateSpec, ArgSpec), Input, Result) :-
    ground_spec(GateSpec, Input, Gate),
    ground_spec(ArgSpec, Input, Args),
    run_kernel(Kernel, Gate, Args, run(_, _, _, _, Result)).

ground_spec(in(Path), Input, Value) :-
    !,
    leaf_value(Path, Input, Value).
ground_spec(const(Value), _, Value) :- !.
ground_spec(Spec, _, _) :-
    var(Spec),
    !,
    fail.
ground_spec(Spec, Input, Ground) :-
    compound(Spec),
    !,
    Spec =.. [Functor|Arguments],
    ground_specs(Arguments, Input, GroundArguments),
    Ground =.. [Functor|GroundArguments].
ground_spec(Spec, _, Spec).

ground_specs([], _, []).
ground_specs([Spec|Rest0], Input, [Ground|Rest]) :-
    ground_spec(Spec, Input, Ground),
    ground_specs(Rest0, Input, Rest).

%!  composition_string(+Composition, -String) is det.
%
%   The written form a row carries. term_string/2 reads it back, which is how
%   the fixture re-runs a recorded composition instead of trusting the row.
composition_string(Composition, String) :-
    term_string(Composition, String).


% ==========================================================================
% 4. HOW TWO RESULT TERMS CAN BE RELATED
%
% Only the first relation makes a candidate. The second is measurement of the
% commonest way a machine misses: it calls a kernel and re-wraps the result
% under its own functor. That is a projection gap, and naming it is what
% turns a resister row into a work list.
% ==========================================================================

%!  payload_relation(+MachineResult, +KernelResult, -Relation) is semidet.
%
%   Relation is `identical` or `shared_list_payload`. Fails when the two terms
%   have nothing worth recording in common.
%
%   The payload test is deliberately narrow: an immediate argument of one term
%   that is a NON-EMPTY LIST and occurs somewhere in the other. A wider test
%   fires on shared tags — two numerals both carrying radix(1) share a compound
%   and mean nothing by it — and a nearest-miss field that fires on everything
%   would carry no information. A list is the shape a machine re-wraps when it
%   calls a kernel for a collection and puts its own functor around the answer,
%   which is the projection gap this field exists to name. Projections of other
%   shapes go unrecorded here, and that is a limit of the field, not a claim
%   that they do not occur. Only the FIRST near miss the search meets is kept,
%   and which one that is depends on the round-robin enumeration order — where
%   several compositions share a payload with the machine, the retained one is
%   arbitrary among them and carries no ranking.
payload_relation(Machine, Kernel, identical) :-
    Machine == Kernel,
    !.
payload_relation(Machine, Kernel, shared_list_payload) :-
    (   list_payload(Kernel, Payload),
        occurs_within(Payload, Machine)
    ->  true
    ;   list_payload(Machine, Payload),
        occurs_within(Payload, Kernel)
    ).

list_payload(Term, Payload) :-
    compound(Term),
    arg(_, Term, Payload),
    Payload = [_|_].

%   A node budget rather than an unbounded walk: a machine result can be a
%   long list, and a search that could run for minutes inside the composition
%   loop would spend the machine's budget on bookkeeping.
occurs_within(Sub, Term) :-
    occurs_within([Term], Sub, 50000).

occurs_within([Term|Rest], Sub, Budget) :-
    Budget > 0,
    (   Term == Sub
    ->  true
    ;   Next is Budget - 1,
        (   compound(Term)
        ->  Term =.. [_|Arguments],
            append(Arguments, Rest, Queue)
        ;   Queue = Rest
        ),
        occurs_within(Queue, Sub, Next)
    ).


% ==========================================================================
% 5. THE WALK
%
% Sampling is stratified over the whole authored grid, not taken off the
% front: a machine whose refusals cluster at small operands would otherwise be
% sampled entirely inside its refusal region.
%
% Spreading the index SET is not enough, because the walk stops as soon as it
% has enough computing points, and a spread set visited in grid order still
% delivers the front of the grid. So the probe order is built in ROUNDS: round
% one is Sample+Verify indices spread evenly across the whole grid, round two
% is the same number spread evenly across what round one left, and so on. Stop
% where it may, the points in hand span the grid.
% ==========================================================================

%!  stratified_indices(+Total, +Wanted, -Indices) is det.
%
%   Wanted positions spread evenly over 0..Total-1, ascending and distinct.
stratified_indices(Total, Wanted, Indices) :-
    (   Wanted >= Total
    ->  Last is Total - 1,
        numlist(0, Last, Indices)
    ;   Wanted =< 0
    ->  Indices = []
    ;   Span is Total - 1,
        Steps is Wanted - 1,
        findall(Index,
                ( between(0, Steps, Position),
                  Index is (Position * Span) // max(Steps, 1)
                ),
                Raw),
        sort(Raw, Indices)
    ).

%!  stratified_probe(+Total, +Wanted, +Rounds, -Probe) is det.
%
%   The visiting order. Each round spreads over what the earlier rounds did
%   not take, so any prefix of Probe of length Wanted or more covers the grid.
stratified_probe(Total, Wanted, Rounds, Probe) :-
    (   Total =< 0
    ->  Probe = []
    ;   Last is Total - 1,
        numlist(0, Last, All),
        probe_rounds(All, Wanted, Rounds, Probe)
    ).

probe_rounds(_, _, Rounds, []) :-
    Rounds =< 0,
    !.
probe_rounds([], _, _, []) :- !.
probe_rounds(Available, Wanted, Rounds, Probe) :-
    length(Available, Count),
    stratified_indices(Count, Wanted, Positions),
    findall(Index, ( member(Position, Positions),
                     nth0(Position, Available, Index) ),
            Picked),
    findall(Index, ( nth0(Position, Available, Index),
                     \+ memberchk(Position, Positions) ),
            Remaining),
    NextRounds is Rounds - 1,
    probe_rounds(Remaining, Wanted, NextRounds, Rest),
    append(Picked, Rest, Probe).

%   walk(+Inputs, ..., -Collected, -Probed, -Refused, -Errored, -Stopped)
collect_points([], _, _, _, _, _, Collected, Collected, Probed, Probed,
               Refused, Refused, Errored, Errored, Stopped, Stopped) :- !.
collect_points(_, _, _, _, _, Wanted, Collected, Collected, Probed, Probed,
               Refused, Refused, Errored, Errored, Stopped, Stopped) :-
    length(Collected, Have),
    Have >= Wanted,
    !.
collect_points([Input|Rest], Family, Kind, Started, Budget, Wanted,
               Collected0, Collected, Probed0, Probed, Refused0, Refused,
               Errored0, Errored, Stopped0, Stopped) :-
    get_time(Now),
    Elapsed is Now - Started,
    (   Elapsed >= Budget
    ->  Collected = Collected0, Probed = Probed0, Refused = Refused0,
        Errored = Errored0, Stopped = machine_budget
    ;   run_machine(Family, Kind, Input, Outcome),
        Probed1 is Probed0 + 1,
        (   Outcome = result(Term, _, _)
        ->  append(Collected0, [point(Input, Term)], Collected1),
            Refused1 = Refused0, Errored1 = Errored0
        ;   Outcome = refused(_)
        ->  Collected1 = Collected0,
            Refused1 is Refused0 + 1, Errored1 = Errored0
        ;   Collected1 = Collected0,
            Refused1 = Refused0, Errored1 is Errored0 + 1
        ),
        collect_points(Rest, Family, Kind, Started, Budget, Wanted,
                       Collected1, Collected, Probed1, Probed,
                       Refused1, Refused, Errored1, Errored,
                       Stopped0, Stopped)
    ).

run_machine(Family, Kind, Input, Outcome) :-
    default(composition_timeout_s, Limit),
    (   catch(call_with_time_limit(Limit, aa_run(Family, Kind, Input, Outcome0)),
              _, fail)
    ->  Outcome = Outcome0
    ;   Outcome = error(input_time_limit)
    ).


% ==========================================================================
% 6. THE SEARCH
% ==========================================================================

%   search(+Compositions, +Screen, +Verify, +Started, +Budget, +Limits,
%          +State0, -State)
%
%   State is st(Tally, Candidates, Unverified, Nearest, Stopped) with
%   Tally = tally(Applicable, ScreenPassed, Verified, VerificationsSpent).
%
%   Screening is on the first screen point alone, because a composition that
%   already disagrees there cannot agree on all ten. Only a composition that
%   survives the whole screen is run against the confirmation set, and only a
%   composition that survives THAT becomes a candidate.
%
%   SCREEN-THEN-VERIFY IS TWO STEPS, AND AN ABSENT SECOND STEP IS NOT A WEAK
%   ONE. A machine whose grid supplies no held-out inputs — ten or fewer
%   computing points, all of them spent on the screen — can have a composition
%   agree everywhere and still have nothing confirmed against inputs the
%   screen did not choose. Those compositions go to Unverified, and the row
%   they make is `kernel_dependency_unverified`, a non-candidate that keeps
%   the machine in the census and out of the certified list. The same holds
%   when the verification budget is already spent, and when the machine budget
%   dies partway through a confirmation: an interrupted confirmation confirms
%   nothing.
search([], _, _, _, _, _, State, State).
search([Composition|Rest], Screen, Verify, Started, Budget, Limits,
       State0, State) :-
    get_time(Now),
    Elapsed is Now - Started,
    (   Elapsed >= Budget
    ->  set_stopped(State0, machine_budget, State)
    ;   step_composition(Composition, Screen, Verify, Started, Budget, Limits,
                         State0, State1),
        (   State1 = st(_, _, _, _, machine_budget)
        ->  State = State1
        ;   search(Rest, Screen, Verify, Started, Budget, Limits, State1, State)
        )
    ).

set_stopped(st(Tally, Candidates, Unverified, Nearest, _), Reason,
            st(Tally, Candidates, Unverified, Nearest, Reason)).

step_composition(Composition, [point(FirstInput, FirstTerm)|RestScreen], Verify,
                 Started, Budget, limits(Timeout, MaxVerifications),
                 st(tally(App0, Pass0, Ver0, Spent0),
                    Candidates0, Unverified0, Nearest0, Stopped0),
                 State) :-
    (   guarded_apply(Composition, FirstInput, Timeout, FirstResult)
    ->  App is App0 + 1,
        (   payload_relation(FirstTerm, FirstResult, Relation)
        ->  true
        ;   Relation = none
        ),
        (   Relation == identical
        ->  agrees_on(RestScreen, Composition, Timeout, Started, Budget,
                      ScreenStatus),
            screened(ScreenStatus, Composition, Verify, Started, Budget,
                     Timeout, MaxVerifications,
                     st(tally(App, Pass0, Ver0, Spent0),
                        Candidates0, Unverified0, Nearest0, Stopped0),
                     State)
        ;   (   Relation == shared_list_payload, Nearest0 == none
            ->  Nearest = nearest(Composition, FirstTerm, FirstResult,
                                  shared_list_payload)
            ;   Nearest = Nearest0
            ),
            State = st(tally(App, Pass0, Ver0, Spent0),
                       Candidates0, Unverified0, Nearest, Stopped0)
        )
    ;   State = st(tally(App0, Pass0, Ver0, Spent0),
                   Candidates0, Unverified0, Nearest0, Stopped0)
    ).

screened(budget, _, _, _, _, _, _, State0, State) :-
    !,
    set_stopped(State0, machine_budget, State).
screened(disagreed, _, _, _, _, _, _, State, State) :- !.
screened(agreed, Composition, Verify, Started, Budget, Timeout,
         MaxVerifications,
         st(tally(App, Pass0, Ver0, Spent0),
            Candidates0, Unverified0, Nearest, Stopped0),
         State) :-
    Pass is Pass0 + 1,
    (   Verify == []
    ->  append(Unverified0, [Composition], Unverified),
        State = st(tally(App, Pass, Ver0, Spent0),
                   Candidates0, Unverified, Nearest, Stopped0)
    ;   Spent0 >= MaxVerifications
    ->  append(Unverified0, [Composition], Unverified),
        State = st(tally(App, Pass, Ver0, Spent0),
                   Candidates0, Unverified, Nearest, Stopped0)
    ;   Spent is Spent0 + 1,
        agrees_on(Verify, Composition, Timeout, Started, Budget, VerifyStatus),
        (   VerifyStatus == agreed
        ->  Ver is Ver0 + 1,
            append(Candidates0, [Composition], Candidates),
            State = st(tally(App, Pass, Ver, Spent),
                       Candidates, Unverified0, Nearest, Stopped0)
        ;   VerifyStatus == budget
        ->  append(Unverified0, [Composition], Unverified),
            State = st(tally(App, Pass, Ver0, Spent),
                       Candidates0, Unverified, Nearest, machine_budget)
        ;   State = st(tally(App, Pass, Ver0, Spent),
                       Candidates0, Unverified0, Nearest, Stopped0)
        )
    ).

%!  agrees_on(+Points, +Composition, +Timeout, +Started, +Budget, -Status) is det.
%
%   Status is agreed, disagreed, or budget. The cumulative budget is checked
%   between points here as well as between compositions: a confirmation set is
%   up to a hundred applications, and a budget that dies inside one would
%   otherwise surface as an external watchdog kill rather than as the graceful
%   stop the guard is for.
agrees_on([], _, _, _, _, agreed).
agrees_on([point(Input, Term)|Rest], Composition, Timeout, Started, Budget,
          Status) :-
    get_time(Now),
    Elapsed is Now - Started,
    (   Elapsed >= Budget
    ->  Status = budget
    ;   guarded_apply(Composition, Input, Timeout, Result),
        Result == Term
    ->  agrees_on(Rest, Composition, Timeout, Started, Budget, Status)
    ;   Status = disagreed
    ).

guarded_apply(Composition, Input, Timeout, Result) :-
    catch(call_with_time_limit(Timeout,
                               apply_composition(Composition, Input, Result)),
          _, fail).


% ==========================================================================
% 7. THE ROW
%
% Every attempted machine produces a row. A machine that never computed, a
% schema with no grid, a spent budget and an exhausted search are all retained
% rows carrying their reason. An exhausted search reporting nothing is a
% claim, and it needs its evidence like any other.
% ==========================================================================

r3_consumer(
    "the kernel admission ceremony on knowledge/strategies/abstraction/\c
     kernel_gate_pilot.pl + the kernel_dependency overlay and blast-radius \c
     queries in the path-graph design + the R2 lens l3 kernel half + the \c
     breadth reel's composition handoffs").

%!  base_evidence(-Evidence) is det.
%
%   One evidence field set for every R3 row, so a consumer reading a resister
%   row and a candidate row reads the same keys. Each row builder overwrites
%   what it measured; what it did not reach keeps the zero below, and the
%   `walk` field says which of the two it is.
base_evidence(Evidence) :-
    findall(K, kernel_unbindable(K), Unbindable),
    Evidence = _{kind: "failed_derivation",
                 source_outcome: "not reached",
                 target_outcome: "no composition was run",
                 elapsed_ms: 0,
                 depth: 1,
                 grid_points_available: 0,
                 grid_points_probed: 0,
                 machine_computed: 0,
                 machine_refused: 0,
                 machine_errored: 0,
                 screen_inputs: [],
                 verification_inputs: [],
                 screen_size: 0,
                 screen_size_required: 0,
                 verification_size: 0,
                 evidence_strength: "not reached",
                 input_integer_leaves: [],
                 input_integer_leaf_count: 0,
                 input_other_leaf_count: 0,
                 input_leaves_truncated: false,
                 kernels_unbindable: Unbindable,
                 compositions_enumerated: 0,
                 compositions_truncated: false,
                 compositions_applicable: 0,
                 compositions_screen_passed: 0,
                 compositions_verified: 0,
                 verifications_spent: 0,
                 candidate_compositions: [],
                 candidate_kernels: [],
                 unverified_compositions: [],
                 nearest_miss: null,
                 walk: "not_walked"}.

%!  r3_evidence(+Measured, -Evidence) is det.
r3_evidence(Measured, Evidence) :-
    base_evidence(Base),
    Evidence = Base.put(Measured).

main_item :-
    json_read_dict(current_input, Item, [value_string_as(string)]),
    r3_row(Item, Row),
    json_write_dict(current_output, Row, [width(0)]),
    nl.

%!  r3_row(+Item, -Row) is det.
r3_row(Item, Row) :-
    item_run(Item, r3),
    item_machine(Item, source, machine(Family, Kind)),
    item_number(Item, machine_budget_s, MachineBudget),
    item_number(Item, composition_timeout_s, Timeout),
    item_number(Item, sample_count, SampleCount),
    item_number(Item, verify_count, VerifyCount),
    item_number(Item, probe_multiple, ProbeMultiple),
    item_number(Item, max_compositions, MaxCompositions),
    item_number(Item, max_verifications, MaxVerifications),
    item_number(Item, max_leaves, MaxLeaves),
    item_number(Item, min_points, MinPoints),
    get_time(Started),
    (   machine_schema(machine(Family, Kind), Schema)
    ->  true
    ;   Schema = null
    ),
    (   Schema == null
    ->  no_contract_row(Family, Kind, Started, Row)
    ;   grid_plan(Schema, Bounds, _)
    ->  walked_row(machine(Family, Kind), Schema, Bounds,
                   budgets(MachineBudget, Timeout),
                   counts(SampleCount, VerifyCount, ProbeMultiple,
                          MaxCompositions, MaxVerifications, MaxLeaves,
                          MinPoints),
                   Started, Row)
    ;   no_grid_row(Family, Kind, Schema, Started, Row)
    ).

walked_row(machine(Family, Kind), Schema, Bounds, budgets(MachineBudget, Timeout),
           counts(SampleCount, VerifyCount, ProbeMultiple, MaxCompositions,
                  MaxVerifications, MaxLeaves, MinPoints),
           Started, Row) :-
    findall(Input, grid_input(Schema, _, Input), GridInputs),
    length(GridInputs, GridTotal),
    Wanted is SampleCount + VerifyCount,
    stratified_probe(GridTotal, Wanted, ProbeMultiple, Indices),
    findall(Input, ( member(Index, Indices), nth0(Index, GridInputs, Input) ),
            Probes),
    collect_points(Probes, Family, Kind, Started, MachineBudget, Wanted,
                   [], Points, 0, Probed, 0, Refused, 0, Errored,
                   completed, CollectStopped),
    length(Points, Computing),
    split_points(Points, SampleCount, Screen, Verify),
    length(Screen, ScreenCount),
    length(Verify, VerifyActual),
    grid_point_count(Schema, AuthoredPoints),
    term_string(Bounds, BoundsString),
    InputField = _{schema: Schema, bounds: BoundsString, points: AuthoredPoints},
    design_total(Required),
    (   Computing < MinPoints
    ->  insufficient_row(machine(Family, Kind), InputField, Started,
                         probe(GridTotal, Probed, Computing, Refused, Errored),
                         Required, CollectStopped, Row)
    ;   Screen = [point(FirstInput, _)|_],
        input_leaves(FirstInput, MaxLeaves, Leaves),
        Leaves = leaves(LeafList, LeafTotal, OtherTotal, LeavesTruncated),
        composition_space(LeafList, MaxCompositions,
                          space(Compositions, Enumerated, Capped)),
        search(Compositions, Screen, Verify, Started, MachineBudget,
               limits(Timeout, MaxVerifications),
               st(tally(0, 0, 0, 0), [], [], none, CollectStopped),
               st(Tally, Candidates, Unverified, Nearest, Stopped)),
        candidate_row(machine(Family, Kind), InputField, Started,
                      probe(GridTotal, Probed, Computing, Refused, Errored),
                      sizes(ScreenCount, VerifyActual, LeafTotal, OtherTotal,
                            LeavesTruncated, Enumerated, Capped),
                      LeafList, Screen, Verify, Tally, Candidates, Unverified,
                      Nearest, Stopped, Row)
    ).

%   The screen is a stratified subsample of the computing points rather than
%   their first ten. The collected points already span the grid, so taking the
%   front of them would hand the screen one corner of it and leave the spread
%   entirely to the confirmation set.
split_points(Points, SampleCount, Screen, Verify) :-
    length(Points, Total),
    (   Total =< SampleCount
    ->  Screen = Points, Verify = []
    ;   stratified_indices(Total, SampleCount, Positions),
        findall(Point, ( member(Position, Positions),
                         nth0(Position, Points, Point) ),
                Screen),
        findall(Point, ( nth0(Position, Points, Point),
                         \+ memberchk(Position, Positions) ),
                Verify)
    ).

candidate_row(machine(Family, Kind), InputField, Started,
              probe(GridTotal, Probed, Computing, Refused, Errored),
              sizes(ScreenCount, VerifyCount, LeafTotal, OtherTotal,
                    LeavesTruncated, Enumerated, Capped),
              LeafList, Screen, Verify, tally(App, Pass, Ver, Spent),
              Candidates, Unverified, Nearest, Stopped, Row) :-
    maplist(composition_string, Candidates, CandidateStrings),
    maplist(composition_string, Unverified, UnverifiedStrings),
    findall(Path, member(leaf(Path, _), LeafList), LeafPaths),
    screen_strings(Screen, Candidates, MachineString, CompositionString),
    nearest_dict(Nearest, NearestDict),
    points_inputs(Screen, ScreenInputs),
    points_inputs(Verify, VerifyInputs),
    elapsed_ms(Started, ElapsedMs),
    design_total(Design),
    Tested is ScreenCount + VerifyCount,
    (   Tested >= Design
    ->  Strength = "design"
    ;   Strength = "grid_limited"
    ),
    r3_verdict(Candidates, Unverified, Stopped, Capped, Strength,
               Outcome, CandidateType, Kernels),
    (   Candidates = [comp(_, WinningKernel, _, _)|_]
    ->  Target = _{family: "kernel_gate_pilot", kind: WinningKernel}
    ;   Target = _{family: null, kind: null}
    ),
    (   Candidates == []
    ->  EvidenceKind = "failed_derivation"
    ;   EvidenceKind = "byte_identical_bridge"
    ),
    atom_string(Stopped, StoppedString),
    r3_consumer(Consumer),
    r3_evidence(_{kind: EvidenceKind,
                  source_outcome: MachineString,
                  target_outcome: CompositionString,
                  elapsed_ms: ElapsedMs,
                  grid_points_available: GridTotal,
                  grid_points_probed: Probed,
                  machine_computed: Computing,
                  machine_refused: Refused,
                  machine_errored: Errored,
                  screen_inputs: ScreenInputs,
                  verification_inputs: VerifyInputs,
                  screen_size: ScreenCount,
                  screen_size_required: Design,
                  verification_size: VerifyCount,
                  evidence_strength: Strength,
                  input_integer_leaves: LeafPaths,
                  input_integer_leaf_count: LeafTotal,
                  input_other_leaf_count: OtherTotal,
                  input_leaves_truncated: LeavesTruncated,
                  compositions_enumerated: Enumerated,
                  compositions_truncated: Capped,
                  compositions_applicable: App,
                  compositions_screen_passed: Pass,
                  compositions_verified: Ver,
                  verifications_spent: Spent,
                  candidate_compositions: CandidateStrings,
                  candidate_kernels: Kernels,
                  unverified_compositions: UnverifiedStrings,
                  nearest_miss: NearestDict,
                  walk: StoppedString},
                Evidence),
    Row = _{run: "r3",
            candidate_type: CandidateType,
            source: _{family: Family, kind: Kind},
            target: Target,
            input: InputField,
            evidence: Evidence,
            outcome: Outcome,
            consumer: Consumer}.

%   A candidate is a composition that answered with the machine's own result
%   term on every input the walk collected. Everything else the search measured
%   is a product, and the resister rows are the largest part of it, but only a
%   candidate goes to the ceremony.
%
%   Two candidate types, and the difference is the evidence and not the claim.
%   `kernel_dependency` cleared the design's 10 + 100. A machine whose authored
%   grid supplies fewer than 110 computing points but more than the screen
%   takes — the confirmation set is short, not absent — clears every point the
%   grid has and is recorded as `kernel_dependency_thin_evidence`. Withholding
%   the search from those machines would leave a known dependency permanently
%   unsearchable, and calling the thin result a full bridge proof would
%   overstate it.
%
%   A third type is NOT a candidate at all. `kernel_dependency_unverified`
%   means a composition agreed on every point the screen held and there was no
%   held-out point to confirm it against, or the confirmation was cut short.
%   The compositions are on the row under `unverified_compositions`; the
%   candidate list stays empty and the evidence kind stays failed_derivation,
%   because a bridge proof the run did not complete is not a bridge proof.
%
%   The ceremony filters on candidate_type, never on outcome: both
%   `kernel_dependency` and `kernel_dependency_thin_evidence` read
%   `certified_candidate` at the outcome field.
r3_verdict(Candidates, Unverified, Stopped, Capped, Strength,
           Outcome, CandidateType, Kernels) :-
    findall(Kernel, member(comp(_, Kernel, _, _), Candidates), Kernels0),
    sort(Kernels0, Kernels),
    (   Candidates \== [], Strength == "design"
    ->  Outcome = "certified_candidate", CandidateType = "kernel_dependency"
    ;   Candidates \== []
    ->  Outcome = "certified_candidate",
        CandidateType = "kernel_dependency_thin_evidence"
    ;   Stopped == machine_budget
    ->  Outcome = "timeout", CandidateType = "machine_budget_exhausted"
    ;   Unverified \== []
    ->  Outcome = "no_candidate",
        CandidateType = "kernel_dependency_unverified"
    ;   Capped == true
    ->  Outcome = "no_candidate", CandidateType = "search_truncated"
    ;   Strength == "grid_limited"
    ->  Outcome = "no_candidate", CandidateType = "measured_resister_thin_grid"
    ;   Outcome = "no_candidate", CandidateType = "measured_resister"
    ).

%   source_outcome and target_outcome keep the R1/R2 reading: what each side
%   answered at the first screen point. For a candidate they are the same
%   string, and that identity is the proof the row is making.
screen_strings([point(Input, Term)|_], Candidates, MachineString, ResultString) :-
    term_string(Term, MachineString),
    default(composition_timeout_s, Timeout),
    (   Candidates = [Composition|_],
        guarded_apply(Composition, Input, Timeout, Result)
    ->  term_string(Result, ResultString)
    ;   ResultString = "no composition answered with this term"
    ).

nearest_dict(none, null) :- !.
nearest_dict(nearest(Composition, MachineTerm, KernelTerm, Relation),
             _{composition: CompositionString,
               machine_result: MachineString,
               composition_result: KernelString,
               relation: RelationString}) :-
    composition_string(Composition, CompositionString),
    term_string(MachineTerm, MachineString),
    term_string(KernelTerm, KernelString),
    atom_string(Relation, RelationString).

points_inputs(Points, Inputs) :-
    findall(Input, member(point(Input, _), Points), Inputs).

insufficient_row(machine(Family, Kind), InputField, Started,
                 probe(GridTotal, Probed, Computing, Refused, Errored),
                 Required, Stopped, Row) :-
    elapsed_ms(Started, ElapsedMs),
    (   Stopped == machine_budget
    ->  Outcome = "timeout", CandidateType = "machine_budget_exhausted"
    ;   Computing =:= 0
    ->  Outcome = "refused", CandidateType = "machine_never_computed"
    ;   Outcome = "no_candidate", CandidateType = "insufficient_computed_samples"
    ),
    atom_string(Stopped, StoppedString),
    r3_consumer(Consumer),
    r3_evidence(_{source_outcome: "the machine computed on too few probed \c
                                   grid points to screen a composition",
                  elapsed_ms: ElapsedMs,
                  evidence_strength: "grid_limited",
                  grid_points_available: GridTotal,
                  grid_points_probed: Probed,
                  machine_computed: Computing,
                  machine_refused: Refused,
                  machine_errored: Errored,
                  screen_size: Computing,
                  screen_size_required: Required,
                  walk: StoppedString},
                Evidence),
    Row = _{run: "r3",
            candidate_type: CandidateType,
            source: _{family: Family, kind: Kind},
            target: _{family: null, kind: null},
            input: InputField,
            evidence: Evidence,
            outcome: Outcome,
            consumer: Consumer}.

no_grid_row(Family, Kind, Schema, Started, Row) :-
    elapsed_ms(Started, ElapsedMs),
    r3_consumer(Consumer),
    r3_evidence(_{source_outcome: "the contract schema carries no authored \c
                                   grid",
                  elapsed_ms: ElapsedMs,
                  walk: "no_grid_plan"},
                Evidence),
    Row = _{run: "r3",
            candidate_type: "uninstantiated_schema",
            source: _{family: Family, kind: Kind},
            target: _{family: null, kind: null},
            input: _{schema: Schema, bounds: null, points: 0},
            evidence: Evidence,
            outcome: "uninstantiated",
            consumer: Consumer}.

no_contract_row(Family, Kind, Started, Row) :-
    elapsed_ms(Started, ElapsedMs),
    r3_consumer(Consumer),
    r3_evidence(_{source_outcome: "no automaton_input_contract row names \c
                                   this machine",
                  elapsed_ms: ElapsedMs,
                  walk: "no_contract_row"},
                Evidence),
    Row = _{run: "r3",
            candidate_type: "no_contract_row",
            source: _{family: Family, kind: Kind},
            target: _{family: null, kind: null},
            input: _{schema: null, bounds: null, points: 0},
            evidence: Evidence,
            outcome: "uninstantiated",
            consumer: Consumer}.

elapsed_ms(Started, ElapsedMs) :-
    get_time(Now),
    ElapsedMs is round((Now - Started) * 1000).


% -------------------------------------------------------------------------
% Item field readers. Small enough to keep here rather than widen
% loop_driver.pl's interface, which would touch the R1/R2 module.
% -------------------------------------------------------------------------

item_run(Item, Expected) :-
    get_dict(run, Item, RunString),
    atom_string(Run, RunString),
    (   Run == Expected
    ->  true
    ;   throw(error(domain_error(supported_run, Run),
                    context(r3_driver:r3_row/2,
                            'r3_driver runs r3 items; r1 and r2 items go to \c
                             loop_driver:main_item')))
    ).

item_machine(Item, Key, machine(Family, Kind)) :-
    get_dict(Key, Item, Sub),
    get_dict(family, Sub, FamilyString),
    get_dict(kind, Sub, KindString),
    atom_string(Family, FamilyString),
    atom_string(Kind, KindString).

item_number(Item, Key, Value) :-
    default(Key, Default),
    (   get_dict(Key, Item, Given), number(Given)
    ->  Value = Given
    ;   Value = Default
    ).
