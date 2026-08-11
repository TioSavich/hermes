:- encoding(utf8).
/** <module> r4_driver — the contract-bridge adapter search
 *
 * Run R4 of the design in
 * `.superpowers/sdd/task-2026-08-08-engineer-bigred-loops.md`: for an ordered
 * machine pair (M1, M2) and one adapter A from the authored library in
 * `r4_adapters.pl`, take sample inputs from M1's grid, run M1, carry its result
 * into an M2 input through A, and run M2. A candidate needs every sample to
 * compute on BOTH sides and every sample's warrant obligations discharged.
 * Everything else is a refusal inventory, which the design's own falsifier says
 * is the run's residual product.
 *
 *   swipl -q -l paths.pl -l scripts/bigred/loops/r4_driver.pl \
 *         -g r4_driver:main_item -t halt
 *
 * WHY A SIBLING MODULE, as with r3_driver.pl. loop_driver.pl carries R1 and R2
 * and r3_driver.pl carries R3; this file adds R4 without editing a line of
 * either, so those paths are unchanged by construction rather than by
 * inspection. What R4 needs from the substrate it imports.
 *
 * THE DESIGN SAYS "STATIC SCHEMA FILTER: M1 OUTPUT SCHEMA VS M2 INPUT SCHEMA".
 * THE TREE CARRIES NO OUTPUT SCHEMA. `automaton_input_contract/5` declares an
 * INPUT schema, a verified example and nothing about the result. So the output
 * side of the filter is MEASURED, not read: `source_signature/4` runs a machine
 * on its own verified example and classifies the result term through the
 * library's authored carrier table. That measurement is cheap — one run per
 * machine — and it is honest about being a measurement. The input side of the
 * filter is genuinely static: it compares schema strings.
 *
 * HOW AN M2 INPUT GETS BUILT, AND WHAT IS NEVER INVENTED. M2's contract is a
 * JSON object with typed slots (`"a":"integer"`), literal slots
 * (`"kind":"decimal_pair"`, `"scale":1`) and nested objects and arrays. Exactly
 * three things may fill a slot:
 *
 *   the carried value   at the placement position the adapter's produced kind
 *                       fits, taken in the schema's own document order
 *   the schema's literal at a slot the schema itself pins
 *   M1's own input      at the SAME path, when M1's contract has one there
 *
 * A slot none of the three reaches is not filled with a plausible number. The
 * adapter simply does not apply to that pair, the row says which path was
 * unreachable, and the pair joins the missing-contract inventory the design's
 * second consumer asks for. This is what "result to operand threading for
 * two-step tasks" is in practice, and it is why the library has no separate
 * row for it.
 *
 * PLACEMENT IS SEARCHED AND RECORDED, NOT ASSUMED. A two-slot target admits the
 * carried value in either slot, and which slot it takes is a difference in
 * ROLE — the dividend or the divisor. The driver tries the placements in
 * document order up to `max_placements`, and a candidate is a placement that
 * held for every sample. The winning placement's path is on the row, because a
 * bridge whose landing slot the reader has to guess is not executable.
 *
 * WHAT THE CEREMONY READS, AND WHAT IT MUST NOT. A candidate row carries
 * `samples_bridged` and `distinct_adapted_inputs`, and they are different
 * numbers. The carried value overwrites the slot it lands in, and that slot is
 * one the source's grid varies, so two grid inputs can produce the SAME adapted
 * input: measured on two pairs, twenty bridged samples came from ten and from
 * thirteen distinct adapted inputs. `samples_bridged` therefore counts
 * correlated trials as independent ones. **The ceremony reads
 * `distinct_adapted_inputs`, never `samples_bridged`**, and the driver keys
 * both `evidence_strength` and the candidate type on it: a bridge that held on
 * every sample but rested on fewer than `min_samples` distinct adapted inputs
 * is `insufficient_distinct_inputs`, a non-candidate.
 *
 * THE ADAPTED INPUT ON A ROW IS JSON, AND JSON HAS NO RATIONALS. A row-12
 * bridge carries three quarters as `3 rdiv 4`, and json_write_dict/3 writes
 * that as 0.75; an inverse-witness rescaling carries thirds and writes
 * 0.3333333333333333. So `adapted_input` is a readable approximation of what
 * the target machine received, and `carried_value_exact` on the same record is
 * the term. A reader rebinds the receipt by putting `carried_value_exact` back
 * at `placement_path`, and the fixture does exactly that.
 *
 * TIME. As in loop_driver.pl and r3_driver.pl: `call_with_time_limit/2` cannot
 * preempt a native builtin, so it is a best-effort inner bound and the binding
 * guard is the external watchdog in run_loop_array.py. The cumulative
 * per-(pair, adapter) budget is checked between samples and between placements,
 * where checking is cheap and reliable.
 */

:- module(r4_driver,
          [ schema_positions/2,
            placement_positions/3,
            unit_position/2,
            source_signature/4,
            statically_compatible/4,
            bridge_sample/6,
            machine_probe_indices/6,
            r4_row/2,
            main_item/0
          ]).

:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(time), [call_with_time_limit/2]).
:- use_module(library(http/json)).

% The substrate. Everything R4 borrows is already exported by the wave-1
% module; nothing here writes to it.
:- use_module(loop_driver,
              [ contracted_machine/1,
                machine_schema/2,
                grid_plan/3,
                machine_grid_plan/4,
                machine_grid_input/4,
                machine_grid_point_count/3,
                machine_grid_overlay_point_count/3,
                aa_run/4
              ]).
:- use_module(strategies(automaton_input_contracts),
              [ automaton_input_contract/5 ]).
:- use_module(r4_adapters,
              [ adapter/3,
                adapter_id/1,
                carried/3,
                carrier_kind/2,
                adapter_reads/3,
                adapter_produces/2,
                adapt/6,
                unit_slot_key/1,
                scaling_witness_keys/3
              ]).


% ==========================================================================
% 1. DEFAULTS
%
% Every one of these is an item field first and a default second, so a fixture
% runs the same code on a small budget.
% ==========================================================================

default(pair_budget_s,   300).   % the design's 5 minutes per (pair, adapter)
default(input_timeout_s,  60).   % the design's 60 s per item
default(sample_count,     20).   % the design's 20 sample inputs
default(probe_multiple,   10).   % grid points visited per sample wanted
default(min_samples,       2).   % below this a bridge is a coincidence
default(max_placements,    3).   % landing slots tried, in document order
default(max_records,      20).   % per-sample records retained on the row
default(signature_timeout_s, 20).% the one probe that measures an output shape

%!  design_samples(-Count) is det.
%
%   The 20 the design asks for, read off the DEFAULT rather than off the item,
%   so that a fixture lowering sample_count cannot clear its own lowered bar and
%   stamp the row `evidence_strength: "design"`.
design_samples(Count) :-
    default(sample_count, Count).


% ==========================================================================
% 2. THE TARGET CONTRACT AS POSITIONS
%
% A schema string is parsed with json_read's ordered form, not into a dict:
% dict keys sort, and sorting would make "the first operand slot" mean
% "alphabetically first", which for `{"multiplier":..., "multiplicand":...}` is
% the second one. Document order is the contract's own order, and role talk
% depends on it.
% ==========================================================================

%!  schema_positions(+SchemaString, -Positions) is semidet.
%
%   Positions is a list of pos(Path, Kind) in document order, one per node of
%   the schema below the root. Path is a list of key(Name) and index(N) steps.
%   Kind is:
%     typed(TypeName)   a slot the contract declares a type for
%     literal(Value)    a slot the contract pins to a constant
%     object(Keys)      a nested object, with its key list
%     array(Length)     a nested array
schema_positions(SchemaString, Positions) :-
    schema_term(SchemaString, Term),
    findall(Position, position_of(Term, [], Position), Positions).

schema_term(SchemaString, Term) :-
    (   atom(SchemaString)
    ->  Atom = SchemaString
    ;   atom_string(Atom, SchemaString)
    ),
    catch(atom_json_term(Atom, Term, [value_string_as(string)]), _, fail).

position_of(json(Pairs), Path, Position) :-
    member(Key=Value, Pairs),
    append(Path, [key(Key)], Extended),
    (   Position = pos(Extended, Kind),
        node_kind(Value, Kind)
    ;   position_of(Value, Extended, Position)
    ).
position_of(List, Path, Position) :-
    is_list(List),
    nth0(Index, List, Value),
    append(Path, [index(Index)], Extended),
    (   Position = pos(Extended, Kind),
        node_kind(Value, Kind)
    ;   position_of(Value, Extended, Position)
    ).

node_kind(json(Pairs), object(Keys)) :-
    !,
    findall(Key, member(Key=_, Pairs), Keys).
node_kind(List, array(Length)) :-
    is_list(List),
    !,
    length(List, Length).
node_kind(Value, typed(Value)) :-
    type_name(Value),
    !.
node_kind(Value, literal(Value)).

%   The contract vocabulary, measured over all 83 schema strings on 2026-08-10:
%   these five names and nothing else appear as type declarations. Every other
%   leaf is a constant the contract pins — `"kind":"decimal_pair"`,
%   `"node":"int"`, `"scale":1`.
type_name("integer").
type_name("positive_integer").
type_name("number").
type_name("positive_number").
type_name("atom").

%!  type_admits(+TypeName, +Value) is semidet.
type_admits("integer", Value) :- integer(Value).
type_admits("positive_integer", Value) :- integer(Value), Value > 0.
type_admits("number", Value) :- number(Value).
type_admits("positive_number", Value) :- number(Value), Value > 0.
type_admits("atom", Value) :- atom(Value), !.
type_admits("atom", Value) :- string(Value), Value \== "".

%!  type_class(+TypeName, -Class) is det.
%
%   The coarse class step 0's static filter joins on. The exact type is checked
%   per sample by the boundary obligation, because a schema declaring `integer`
%   may still supply a value a `positive_integer` slot accepts and a static join
%   on exact types would drop those pairs before anything measured them.
type_class("integer", numeric).
type_class("positive_integer", numeric).
type_class("number", numeric).
type_class("positive_number", numeric).
type_class("atom", nominal).

%!  placement_positions(+SchemaString, +ProducedKind, -Positions) is det.
%
%   Where a produced value may land, in document order. A number lands in a
%   numeric slot; a fraction object lands in a sub-object whose keys are exactly
%   n and d; a decimal object lands in one whose keys are exactly numeral and
%   scale. Key-set equality rather than containment: a sub-object with a third
%   key would need that key filled from somewhere, and the adapter has nothing
%   to fill it with.
placement_positions(SchemaString, ProducedKind, Positions) :-
    schema_positions(SchemaString, All),
    include(admits_produced(ProducedKind), All, Positions).

admits_produced(number, pos(_, typed(Type))) :-
    type_class(Type, numeric).
admits_produced(fraction_object, pos(_, object(Keys))) :-
    msort(Keys, [d, n]).
admits_produced(decimal_object, pos(_, object(Keys))) :-
    msort(Keys, [numeral, scale]).

%!  unit_position(+SchemaString, -Position) is semidet.
%
%   The first slot, in document order, that names the unit of a quantity the
%   contract carries. `unit_slot_key/1` in the library is the authored list, and
%   it cites the decode seam each key was read from.
unit_position(SchemaString, pos(Path, typed("atom"))) :-
    schema_positions(SchemaString, Positions),
    member(pos(Path, typed("atom")), Positions),
    last(Path, key(Key)),
    unit_slot_key(Key),
    !.


% ==========================================================================
% 3. READING M1's INPUT AT A PATH
% ==========================================================================

%!  input_at(+Path, +Input, -Value) is semidet.
input_at([], Value, Value).
input_at([key(Key)|Rest], Current, Value) :-
    is_dict(Current),
    atom_string(Atom, Key),
    get_dict(Atom, Current, Next),
    input_at(Rest, Next, Value).
input_at([index(Index)|Rest], Current, Value) :-
    is_list(Current),
    nth0(Index, Current, Next),
    input_at(Rest, Next, Value).

%!  path_string(+Path, -String) is det.
path_string([], "root") :- !.
path_string(Path, String) :-
    findall(Piece, (member(Step, Path), step_piece(Step, Piece)), Pieces),
    atomic_list_concat(Pieces, Joined),
    atom_string(Joined, String).

step_piece(key(Key), Piece) :-
    atom_string(Atom, Key),
    atomic_list_concat(['.', Atom], Piece).
step_piece(index(Index), Piece) :-
    format(atom(Piece), '[~w]', [Index]).


% ==========================================================================
% 4. BUILDING M2's INPUT
%
% One recursive walk of M2's schema. Each node is filled by the placement, by a
% supplied unit, by the schema's own literal, or by M1's input at the same path.
% A node none of them reaches returns gap(Path), and the caller records the
% unreachable path rather than substituting anything for it.
% ==========================================================================

%   plan(PlacementPath, PlacementValue, UnitPath, UnitValue)
%   UnitPath is `none` when nothing is supplied there.

%!  build_input(+SchemaString, +Plan, +SourceInput, -Outcome) is det.
%
%   Outcome is ok(Value, Slots) or gap(PathString, Reason). Slots is a list of
%   slot(PathString, Provenance, Value, Declared), Provenance one of `carried`,
%   `unit_supplied`, `literal`, `threaded`.
build_input(SchemaString, Plan, SourceInput, Outcome) :-
    schema_term(SchemaString, Term),
    build_node(Term, [], Plan, SourceInput, Outcome).

build_node(Node, Path, plan(Path, Value, _, _), _, ok(Built, Slots)) :-
    !,
    place_value(Node, Path, Value, Built, Slots).
build_node(_, Path, plan(_, _, Path, UnitValue),
           _, ok(UnitValue, [slot(PathString, unit_supplied, UnitValue,
                                  "atom")])) :-
    !,
    path_string(Path, PathString).
build_node(json(Pairs), Path, Plan, SourceInput, Outcome) :-
    !,
    build_pairs(Pairs, Path, Plan, SourceInput, [], [], Outcome).
build_node(List, Path, Plan, SourceInput, Outcome) :-
    is_list(List),
    !,
    build_elements(List, 0, Path, Plan, SourceInput, [], [], Outcome).
build_node(Leaf, Path, _, SourceInput, Outcome) :-
    path_string(Path, PathString),
    (   type_name(Leaf)
    ->  (   input_at(Path, SourceInput, Threaded)
        ->  Outcome = ok(Threaded,
                         [slot(PathString, threaded, Threaded, Leaf)])
        ;   Outcome = gap(PathString, "no value at this path in the source \c
                                       machine's own input")
        )
    ;   Outcome = ok(Leaf, [slot(PathString, literal, Leaf, literal)])
    ).

build_pairs([], _, _, _, Built, Slots, ok(json(Reversed), Slots)) :-
    reverse(Built, Reversed).
build_pairs([Key=Value|Rest], Path, Plan, SourceInput, Built, Slots, Outcome) :-
    atom_string(Atom, Key),
    append(Path, [key(Atom)], Extended),
    build_node(Value, Extended, Plan, SourceInput, Sub),
    (   Sub = ok(BuiltValue, SubSlots)
    ->  append(Slots, SubSlots, Slots1),
        build_pairs(Rest, Path, Plan, SourceInput,
                    [Atom=BuiltValue|Built], Slots1, Outcome)
    ;   Outcome = Sub
    ).

build_elements([], _, _, _, _, Built, Slots, ok(Reversed, Slots)) :-
    reverse(Built, Reversed).
build_elements([Value|Rest], Index, Path, Plan, SourceInput, Built, Slots,
               Outcome) :-
    append(Path, [index(Index)], Extended),
    build_node(Value, Extended, Plan, SourceInput, Sub),
    (   Sub = ok(BuiltValue, SubSlots)
    ->  append(Slots, SubSlots, Slots1),
        Next is Index + 1,
        build_elements(Rest, Next, Path, Plan, SourceInput,
                       [BuiltValue|Built], Slots1, Outcome)
    ;   Outcome = Sub
    ).

%   A number lands in a leaf; an object lands across the keys of a sub-object,
%   and a key the schema pins to a literal must already equal what the adapter
%   produced — a decimal object carrying scale 100 cannot land in a contract
%   that pins scale to 1.
place_value(_, Path, number(Value), Value,
            [slot(PathString, carried, Value, Declared)]) :-
    !,
    path_string(Path, PathString),
    Declared = carried_slot.
place_value(json(Pairs), Path, object(Produced), json(Built), Slots) :-
    findall(Key=Value-Slot,
            ( member(Key=Declared, Pairs),
              atom_string(Atom, Key),
              memberchk(Atom-Value, Produced),
              (   type_name(Declared)
              ->  true
              ;   Declared == Value
              ),
              append(Path, [key(Atom)], Extended),
              path_string(Extended, SlotPath),
              Slot = slot(SlotPath, carried, Value, Declared)
            ),
            Filled),
    length(Pairs, Expected),
    length(Filled, Expected),
    findall(Key=Value, member(Key=Value-_, Filled), Built),
    findall(Slot, member(_=_-Slot, Filled), Slots).

%!  json_to_input(+Term, -Input) is det.
%
%   The built json/1 term as the dict aa_run/4 reads. Keys become atoms and
%   string values stay strings, which is the shape loop_driver's own grids
%   produce and hermes/encyclopedia.pl's trace_inputs/3 decodes.
json_to_input(json(Pairs), Dict) :-
    !,
    findall(Key-Value,
            ( member(RawKey=RawValue, Pairs),
              atom_string(Key, RawKey),
              json_to_input(RawValue, Value)
            ),
            Converted),
    dict_pairs(Dict, _, Converted).
json_to_input(List, Converted) :-
    is_list(List),
    !,
    maplist(json_to_input, List, Converted).
json_to_input(Value, Value).


% ==========================================================================
% 5. THE WARRANT OBLIGATIONS
%
% Three checks, evaluated per sample and recorded per sample. A sample counts
% toward a candidate only when every obligation the adapter declares is
% discharged, so an adapter that never discharges them produces an inventory of
% refusals and no bridge — which is what the design asks the ceremony to read.
% ==========================================================================

%!  boundary_check(+Slots, -Status) is det.
%
%   Every typed slot holds a value its declared type admits. Slots the schema
%   pinned to a literal are the contract's own and are not re-checked; the
%   carried slot's declared type comes from the placement and is checked by the
%   caller, which knows it.
boundary_check(Slots, Status) :-
    findall(Violation,
            ( member(slot(PathString, _, Value, Declared), Slots),
              type_name(Declared),
              \+ type_admits(Declared, Value),
              format(string(Violation), "~w holds ~q, outside ~w",
                     [PathString, Value, Declared])
            ),
            Violations),
    (   Violations == []
    ->  Status = discharged("every filled slot inside its declared type")
    ;   atomic_list_concat(Violations, "; ", Joined),
        Status = refused(Joined)
    ).

%!  roles_record(+Slots, -Status) is det.
%
%   Where every slot's value came from. Discharged by construction — a slot with
%   no source made the build return a gap and there is no sample to record — so
%   what this writes is the provenance the reviewer has to read to judge whether
%   the roles survived.
roles_record(Slots, discharged(Summary)) :-
    tally_provenance(Slots, carried, Carried),
    tally_provenance(Slots, unit_supplied, Supplied),
    tally_provenance(Slots, threaded, Threaded),
    tally_provenance(Slots, literal, Literal),
    findall(Path, member(slot(Path, carried, _, _), Slots), CarriedPaths),
    atomic_list_concat(CarriedPaths, ", ", CarriedJoined),
    format(string(Summary),
           "carried into ~w (~w slot(s)); ~w unit supplied, ~w threaded from \c
            the source input, ~w schema literal(s)",
           [CarriedJoined, Carried, Supplied, Threaded, Literal]).

tally_provenance(Slots, Provenance, Count) :-
    findall(1, member(slot(_, Provenance, _, _), Slots), Ones),
    length(Ones, Count).

%!  refusal_obligation(+Reason, -Obligation) is det.
%
%   Which obligation an adapter's refusal belongs under, so the row's tally
%   reads by obligation rather than by message.
refusal_obligation(dropped(_), units).
refusal_obligation(relabelled_without_witness(_, _), units).
refusal_obligation(unit_not_nameable(_), units).
refusal_obligation(inexact_in_base_ten(_, _), exactness).
refusal_obligation(kernel_refused_inscription(_), exactness).

%   `no_relabel_required` is not a warrant failure. It says the relabel row was
%   offered a sample that needed no relabel, which means a different row is the
%   one that applies. Keeping it out of the refusal tally is what stops the
%   inventory from counting "this is the wrong tool" as "this bridge is unsafe".
not_applicable_reason(no_relabel_required(_)).


% ==========================================================================
% 6. ONE SAMPLE
% ==========================================================================

%!  bridge_sample(+Source, +Target, +Adapter, +Placement, +Input, -Sample)
%
%   Source and Target are machine(Family, Kind); Placement is
%   pos(Path, Kind) in Target's schema. Sample is
%   sample(Status, Record) where Status is `bridged`, `warrant_refused`,
%   `not_applicable`, `target_refused`, `source_refused` or `gap`, and Record is
%   the dict that goes on the row.
bridge_sample(Source, Target, Adapter, Placement, Input, Sample) :-
    default(input_timeout_s, Timeout),
    bridge_sample(Source, Target, Adapter, Placement, Input, Timeout, Sample).

bridge_sample(machine(SourceFamily, SourceKind), Target, Adapter, Placement,
              Input, Timeout, Sample) :-
    guarded_run(SourceFamily, SourceKind, Input, Timeout, SourceOutcome),
    (   SourceOutcome = result(SourceTerm, _, _)
    ->  carried_sample(SourceTerm, Target, Adapter, Placement, Input, Timeout,
                       Sample)
    ;   term_string(SourceOutcome, OutcomeString),
        base_record(Input, OutcomeString, Record0),
        Record = Record0.put(_{status: "source_refused",
                               note: "the source machine did not compute on \c
                                      this input"}),
        Sample = sample(source_refused, Record)
    ).

carried_sample(SourceTerm, Target, Adapter, Placement, Input, Timeout, Sample) :-
    term_string(SourceTerm, SourceString),
    base_record(Input, SourceString, Record0),
    (   \+ carried(SourceTerm, _, _)
    ->  Record = Record0.put(_{status: "not_applicable",
                               note: "no authored carrier reads this result \c
                                      shape"}),
        Sample = sample(not_applicable, Record)
    ;   carried(SourceTerm, Carrier, Route),
        carrier_kind(Carrier, Kind),
        \+ adapter_reads(Adapter, Kind, Route)
    ->  format(string(Note),
               "the carrier is ~w reached by ~w; this adapter reads a \c
                different one", [Kind, Route]),
        Record = Record0.put(_{status: "not_applicable", note: Note}),
        Sample = sample(not_applicable, Record)
    ;   carried(SourceTerm, Carrier, Route),
        adapted_sample(Carrier, Route, Target, Adapter, Placement, Input,
                       Timeout, Record0, Sample)
    ).

adapted_sample(Carrier, Route, machine(TargetFamily, TargetKind), Adapter,
               pos(PlacementPath, PlacementKind), Input, Timeout, Record0,
               Sample) :-
    machine_schema(machine(TargetFamily, TargetKind), TargetSchema),
    target_unit(TargetSchema, Carrier, Input, UnitPath, TargetUnit),
    witnesses(Input, Witnesses),
    (   adapt(Adapter, Carrier, Route, context(TargetUnit, Witnesses),
              Produced, Transform)
    ->  produced_sample(Produced, Transform, Carrier, Adapter,
                        machine(TargetFamily, TargetKind), TargetSchema,
                        pos(PlacementPath, PlacementKind), UnitPath, Input,
                        Timeout, Record0, Sample)
    ;   Record = Record0.put(_{status: "not_applicable",
                               note: "the adapter has no clause for this \c
                                      carrier"}),
        Sample = sample(not_applicable, Record)
    ).

produced_sample(refused(Reason), Transform, _, _, _, _, _, _, _, _, Record0,
                Sample) :-
    !,
    term_string(Reason, ReasonString),
    (   not_applicable_reason(Reason)
    ->  Status = not_applicable, Tag = "not_applicable"
    ;   Status = warrant_refused, Tag = "warrant_refused"
    ),
    (   refusal_obligation(Reason, Obligation)
    ->  atom_string(Obligation, ObligationString)
    ;   ObligationString = "applicability"
    ),
    Record = Record0.put(_{status: Tag,
                           transform: Transform,
                           refused_obligation: ObligationString,
                           refused_reason: ReasonString}),
    Sample = sample(Status, Record).
produced_sample(produced(Value, Disposition), Transform, _Carrier, Adapter,
                machine(TargetFamily, TargetKind), TargetSchema,
                pos(PlacementPath, PlacementKind), UnitPath, Input, Timeout,
                Record0, Sample) :-
    unit_supply(Disposition, UnitPath, SuppliedPath, SuppliedValue),
    Plan = plan(PlacementPath, Value, SuppliedPath, SuppliedValue),
    build_input(TargetSchema, Plan, Input, Built),
    (   Built = gap(GapPath, GapReason)
    ->  format(string(Note), "~w: ~w", [GapPath, GapReason]),
        Record = Record0.put(_{status: "not_applicable",
                               transform: Transform,
                               unfilled_path: GapPath,
                               note: Note}),
        Sample = sample(not_applicable, Record)
    ;   Built = ok(BuiltTerm, Slots),
        json_to_input(BuiltTerm, AdaptedInput),
        placement_slots(PlacementKind, PlacementPath, Value, TargetSchema,
                        CheckedSlots),
        append(Slots, CheckedSlots, AllSlots),
        boundary_check(AllSlots, BoundaryStatus),
        roles_record(Slots, RolesStatus),
        exactness_status(Adapter, ExactnessStatus),
        term_string(Disposition, UnitsString),
        carried_exact(Value, ExactString),
        status_strings(BoundaryStatus, BoundaryString, BoundaryOk),
        status_strings(RolesStatus, RolesString, RolesOk),
        Record1 = Record0.put(_{transform: Transform,
                                adapted_input: AdaptedInput,
                                carried_value_exact: ExactString,
                                units: UnitsString,
                                roles: RolesString,
                                boundary: BoundaryString,
                                exactness: ExactnessStatus}),
        (   BoundaryOk == false
        ->  Record = Record1.put(_{status: "warrant_refused",
                                   refused_obligation: "boundary",
                                   refused_reason: BoundaryString}),
            Sample = sample(warrant_refused, Record)
        ;   RolesOk == false
        ->  Record = Record1.put(_{status: "warrant_refused",
                                   refused_obligation: "roles",
                                   refused_reason: RolesString}),
            Sample = sample(warrant_refused, Record)
        ;   guarded_run(TargetFamily, TargetKind, AdaptedInput, Timeout,
                        TargetOutcome),
            term_string(TargetOutcome, TargetString),
            (   TargetOutcome = result(_, _, _)
            ->  Record = Record1.put(_{status: "bridged",
                                       target_result: TargetString}),
                Sample = sample(bridged, Record)
            ;   Record = Record1.put(_{status: "target_refused",
                                       target_result: TargetString}),
                Sample = sample(target_refused, Record)
            )
        )
    ).

%!  carried_exact(+Produced, -String) is det.
%
%   THE ADAPTED INPUT ON THE ROW IS JSON, AND JSON HAS NO RATIONALS.
%   json_write_dict/3 writes 3 rdiv 4 as 0.75 and 1 rdiv 3 as 0.3333333333333333,
%   so for `project_rational_magnitude` and for an inverse-witness rescaling the
%   `adapted_input` field is a readable approximation of what the target machine
%   received and NOT the term itself. This field carries the term. Together with
%   `placement_path` it is what makes the receipt bindable: a reader rebuilds the
%   adapted input by putting this value back at that path.
carried_exact(number(Value), String) :-
    !,
    term_string(Value, String).
carried_exact(object(Pairs), String) :-
    term_string(Pairs, String).

%   The carried slot's declared type is read back off the schema so the boundary
%   obligation covers it too. place_value/5 cannot know it: it is filling a
%   position, not reading one.
placement_slots(typed(Declared), Path, number(Value),
                _, [slot(PathString, carried, Value, Declared)]) :-
    !,
    path_string(Path, PathString).
placement_slots(_, _, _, _, []).

exactness_status(Adapter, Status) :-
    (   adapter(Adapter, _, Obligations),
        memberchk(exactness, Obligations)
    ->  Status = "exact; the transform found a scale that cleared the \c
                  denominator"
    ;   Status = "not an obligation of this adapter"
    ).

status_strings(discharged(Text), Text, true).
status_strings(refused(Text), Text, false).

unit_supply(preserved(Unit), UnitPath, UnitPath, String) :-
    UnitPath \== none,
    !,
    atom_string(Unit, String).
unit_supply(rescaled(_, Unit, _), UnitPath, UnitPath, String) :-
    UnitPath \== none,
    !,
    atom_string(Unit, String).
unit_supply(rescaled(_, Unit, _, _), UnitPath, UnitPath, String) :-
    UnitPath \== none,
    !,
    atom_string(Unit, String).
unit_supply(_, _, none, none).

%!  target_unit(+TargetSchema, +Carrier, +SourceInput, -UnitPath, -TargetUnit)
%
%   What unit the target will read beside the carried magnitude, and where. The
%   target's own contract decides whether there is a unit slot at all; when
%   there is, the unit it will hold is the one M1's input declares at that path
%   if M1 declares one, and otherwise the unit the carrier brings.
target_unit(TargetSchema, Carrier, SourceInput, UnitPath, TargetUnit) :-
    (   unit_position(TargetSchema, pos(Path, _))
    ->  UnitPath = Path,
        (   input_at(Path, SourceInput, Threaded),
            unit_atom(Threaded, Atom)
        ->  TargetUnit = unit(Atom)
        ;   Carrier = magnitude(_, unit(CarrierUnit))
        ->  TargetUnit = unit(CarrierUnit)
        ;   TargetUnit = none
        )
    ;   UnitPath = none,
        TargetUnit = none
    ).

unit_atom(Value, Atom) :-
    (   atom(Value)
    ->  Atom = Value
    ;   string(Value), Value \== "",
        atom_string(Atom, Value)
    ).

%!  witnesses(+SourceInput, -Witnesses) is det.
%
%   The conversions the sample itself declares. One shape, from the library's
%   authored key list; a sample declaring none yields none, and the relabel row
%   then computes nothing.
witnesses(SourceInput, Witnesses) :-
    findall(scaling(From, To, Factor),
            ( scaling_witness_keys(FromKey, ToKey, FactorKey),
              is_dict(SourceInput),
              get_dict(FromKey, SourceInput, RawFrom), unit_atom(RawFrom, From),
              get_dict(ToKey, SourceInput, RawTo), unit_atom(RawTo, To),
              get_dict(FactorKey, SourceInput, Factor), number(Factor)
            ),
            Witnesses).

base_record(Input, SourceString, _{input: Input,
                                   source_result: SourceString,
                                   adapted_input: null,
                                   carried_value_exact: null,
                                   target_result: null,
                                   transform: null,
                                   units: null,
                                   roles: null,
                                   boundary: null,
                                   exactness: null,
                                   refused_obligation: null,
                                   refused_reason: null,
                                   unfilled_path: null,
                                   note: null,
                                   status: "not_reached"}).

guarded_run(Family, Kind, Input, Timeout, Outcome) :-
    (   catch(call_with_time_limit(Timeout, aa_run(Family, Kind, Input,
                                                   Outcome0)),
              _, fail)
    ->  Outcome = Outcome0
    ;   Outcome = error(input_time_limit)
    ).


% ==========================================================================
% 7. THE MEASURED OUTPUT SIGNATURE AND THE STEP-0 FILTER
%
% The design's static filter wants M1's output schema. The tree carries none, so
% this measures one: run the machine on the verified example its own contract
% row records, and classify the result through the library's carrier table.
% A machine whose verified example does not compute through aa_run/4's decode
% seam has no measured signature and cannot be a bridge SOURCE — 23 of the 246
% are in that state, the same class r3_driver.pl records as
% machine_never_computed, and step 0 prints the count rather than hiding it.
%
% Both halves are MEMOISED. The join is 246 x 245 x 12 and re-parsing a schema
% string inside it would make step 0 an overnight job instead of a minute one;
% the corpus carries 83 distinct schema strings, so each is parsed once.
% ==========================================================================

:- dynamic positions_memo/2.
:- dynamic signature_memo/4.
:- dynamic signatures_measured/0.

%!  cached_positions(+SchemaString, -Positions) is det.
cached_positions(Schema, Positions) :-
    (   positions_memo(Schema, Cached)
    ->  Positions = Cached
    ;   (   schema_positions(Schema, Parsed)
        ->  true
        ;   Parsed = []
        ),
        assertz(positions_memo(Schema, Parsed)),
        Positions = Parsed
    ).

%!  source_signature(+Machine, -CarrierKind, -Route, -ResultString) is semidet.
%
%   Measured, not read. The machine runs on the example its contract row
%   records; that example is the one input the tree asserts computes.
source_signature(machine(Family, Kind), CarrierKind, Route, ResultString) :-
    automaton_input_contract(Family, Kind, _, ExampleJSON, _),
    catch(atom_json_dict(ExampleJSON, Input, [value_string_as(string)]),
          _, fail),
    default(signature_timeout_s, Timeout),
    guarded_run(Family, Kind, Input, Timeout, result(Term, _, _)),
    term_string(Term, ResultString),
    carried(Term, Carrier, Route),
    carrier_kind(Carrier, CarrierKind).

%!  measure_signatures is det.
%
%   One pass over the machine population, so the join below runs against a
%   table instead of re-running machines. Idempotent.
measure_signatures :-
    (   signatures_measured
    ->  true
    ;   forall(contracted_machine(Machine),
               (   source_signature(Machine, Kind, Route, Result)
               ->  assertz(signature_memo(Machine, Kind, Route, Result))
               ;   true
               )),
        assertz(signatures_measured)
    ).

%!  measured_source(?Machine, ?CarrierKind, ?Route) is nondet.
measured_source(Machine, CarrierKind, Route) :-
    measure_signatures,
    signature_memo(Machine, CarrierKind, Route, _).

%!  unmeasured_source(?Machine, ?Reason) is nondet.
%
%   A machine that cannot be a bridge source, and why. `never_computed` is the
%   decode-seam disagreement; `no_carrier` is a machine that computes and whose
%   result shape the library deliberately does not read, which uncarried/2 in
%   the library names one class at a time.
unmeasured_source(Machine, Reason) :-
    measure_signatures,
    contracted_machine(Machine),
    \+ signature_memo(Machine, _, _, _),
    Machine = machine(Family, Kind),
    (   automaton_input_contract(Family, Kind, _, ExampleJSON, _),
        catch(atom_json_dict(ExampleJSON, Input, [value_string_as(string)]),
              _, fail),
        default(signature_timeout_s, Timeout),
        guarded_run(Family, Kind, Input, Timeout, result(_, _, _))
    ->  Reason = no_carrier
    ;   Reason = never_computed
    ).

%!  statically_compatible(+Source, +Target, +Adapter, -PlacementCount) is nondet.
%
%   The step-0 filter. Measured on the output side, static on the input side:
%
%     1. the source's measured result carries something this adapter reads;
%     2. the target's contract has a landing position for what the adapter
%        produces;
%     3. every other typed position of the target's contract is reachable —
%        the schema pins it, the adapter supplies the unit there, or the
%        SOURCE's own contract declares a slot of the same coarse class at the
%        same path.
%
%   Clause 3 is a join over schema strings and nothing runs. It is coarse on
%   purpose: exact types are a per-sample question, and joining on them here
%   would drop pairs before anything measured whether their values fit.
statically_compatible(Source, Target, Adapter, PlacementCount) :-
    measured_source(Source, CarrierKind, Route),
    machine_schema(Source, SourceSchema),
    grid_plan(SourceSchema, _, _),
    contracted_machine(Target),
    Source \== Target,
    machine_schema(Target, TargetSchema),
    adapter_id(Adapter),
    adapter_reads(Adapter, CarrierKind, Route),
    schema_bridge(SourceSchema, TargetSchema, Adapter, CarrierKind,
                  PlacementCount).

%!  schema_bridge(+SourceSchema, +TargetSchema, +Adapter, +CarrierKind,
%!                -PlacementCount) is semidet.
%
%   The pair-independent half of the filter: everything here is a function of
%   the two schema strings and the adapter row, so a hit for one machine pair on
%   a schema pair is a hit for every machine pair on it.
schema_bridge(SourceSchema, TargetSchema, Adapter, CarrierKind,
              PlacementCount) :-
    adapter_produces(Adapter, Produced),
    cached_positions(TargetSchema, TargetPositions),
    include(admits_produced(Produced), TargetPositions, Placements),
    Placements \== [],
    default(max_placements, MaxPlacements),
    take_first(MaxPlacements, Placements, Considered),
    cached_positions(SourceSchema, SourcePositions),
    (   member(pos(UnitPath, typed("atom")), TargetPositions),
        last(UnitPath, key(UnitKey)),
        unit_slot_key(UnitKey)
    ->  true
    ;   UnitPath = none
    ),
    include(threading_reachable(TargetPositions, SourcePositions, UnitPath,
                                CarrierKind),
            Considered, Reachable),
    Reachable \== [],
    length(Reachable, PlacementCount).

threading_reachable(TargetPositions, SourcePositions, UnitPath, CarrierKind,
                    pos(PlacementPath, _)) :-
    forall(( member(pos(Path, typed(Type)), TargetPositions),
             \+ prefix_path(PlacementPath, Path),
             \+ ( UnitPath \== none, Path == UnitPath,
                  CarrierKind == magnitude_with_unit ) ),
           ( member(pos(Path, SourceKind), SourcePositions),
             source_supplies(SourceKind, Type) )).

prefix_path(Prefix, Path) :-
    append(Prefix, _, Path).

source_supplies(typed(SourceType), TargetType) :-
    type_class(SourceType, Class),
    type_class(TargetType, Class).
source_supplies(literal(Value), TargetType) :-
    type_admits(TargetType, Value).

%!  bridge_manifest(-Rows) is det.
%
%   What step 0 writes: one row per (source, target, adapter) the filter admits.
%   The placement is NOT fixed here — the driver searches it and records which
%   one held — but the count of reachable placements rides along so the manifest
%   can say how much search each item carries.
bridge_manifest(Rows) :-
    findall(bridge(SourceFamily, SourceKind, TargetFamily, TargetKind,
                   Adapter, PlacementCount),
            ( statically_compatible(machine(SourceFamily, SourceKind),
                                    machine(TargetFamily, TargetKind),
                                    Adapter, PlacementCount) ),
            Rows).


% ==========================================================================
% 8. THE WALK
%
% Sampling follows r3_driver.pl. Rounds spread within a machine overlay before
% they spread over the shared remainder. With no overlay, rounds remain spread
% over the whole grid exactly as before, so a walk stopping as soon as it has
% enough computing points still holds points from across the grid rather than
% the front of it.
% ==========================================================================

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

stratified_probe(Total, Wanted, Rounds, Probe) :-
    (   Total =< 0
    ->  Probe = []
    ;   Last is Total - 1,
        numlist(0, Last, All),
        probe_rounds(All, Wanted, Rounds, Probe)
    ).

%!  machine_probe_indices(+Machine, +Schema, +Total, +Wanted, +Rounds,
%!                        -Probe) is det.
%
%   The real R4 probe path. The overlay prefix is stratified first; when it fits
%   the nominal Wanted*Rounds budget every prefix point is included, and when
%   it does not the prefix is capped at that budget. Only a genuinely unspent
%   budget is stratified over the shared suffix. With no overlay, the legacy
%   stratified sequence is returned without an added ordering step.
machine_probe_indices(Machine, Schema, Total, Wanted, Rounds, Probe) :-
    machine_grid_overlay_point_count(Machine, Schema, OverlayPoints),
    (   OverlayPoints =:= 0
    ->  stratified_probe(Total, Wanted, Rounds, Probe)
    ;   overlay_first_probe(Total, OverlayPoints, Wanted, Rounds, Probe)
    ).

overlay_first_probe(Total, OverlayPoints, Wanted, Rounds, Probe) :-
    PrefixCount is min(OverlayPoints, Total),
    Budget is max(Wanted, 0) * max(Rounds, 0),
    PrefixBudget is min(PrefixCount, Budget),
    stratified_probe(PrefixCount, Wanted, Rounds, Prefix0),
    take_first(PrefixBudget, Prefix0, Prefix),
    SharedTotal is max(Total - PrefixCount, 0),
    SharedBudget is Budget - PrefixBudget,
    stratified_probe(SharedTotal, Wanted, Rounds, SharedRelative0),
    take_first(SharedBudget, SharedRelative0, SharedRelative),
    maplist(offset_index(PrefixCount), SharedRelative, Shared),
    append(Prefix, Shared, Probe).

offset_index(Offset, Relative, Absolute) :-
    Absolute is Offset + Relative.

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

%   Collect the source machine's computing inputs. Refusals and errors are
%   counted rather than dropped: a pair whose source computes nowhere is a
%   different finding from a pair whose bridge fails.
collect_inputs([], _, _, _, _, Collected, Collected, Probed, Probed,
               Refused, Refused, Errored, Errored, Stopped, Stopped) :- !.
collect_inputs(_, _, _, _, Wanted, Collected, Collected, Probed, Probed,
               Refused, Refused, Errored, Errored, Stopped, Stopped) :-
    length(Collected, Have),
    Have >= Wanted,
    !.
collect_inputs([Input|Rest], Source, Started, budget(Budget, Timeout), Wanted,
               Collected0, Collected, Probed0, Probed, Refused0, Refused,
               Errored0, Errored, Stopped0, Stopped) :-
    get_time(Now),
    Elapsed is Now - Started,
    (   Elapsed >= Budget
    ->  Collected = Collected0, Probed = Probed0, Refused = Refused0,
        Errored = Errored0, Stopped = pair_budget
    ;   Source = machine(Family, Kind),
        guarded_run(Family, Kind, Input, Timeout, Outcome),
        Probed1 is Probed0 + 1,
        (   Outcome = result(_, _, _)
        ->  append(Collected0, [Input], Collected1),
            Refused1 = Refused0, Errored1 = Errored0
        ;   Outcome = refused(_)
        ->  Collected1 = Collected0,
            Refused1 is Refused0 + 1, Errored1 = Errored0
        ;   Collected1 = Collected0,
            Refused1 = Refused0, Errored1 is Errored0 + 1
        ),
        collect_inputs(Rest, Source, Started, budget(Budget, Timeout), Wanted,
                       Collected1, Collected, Probed1, Probed,
                       Refused1, Refused, Errored1, Errored,
                       Stopped0, Stopped)
    ).


% ==========================================================================
% 9. THE PLACEMENT SEARCH
%
% Placements are tried in the target contract's document order. A placement is
% run over every sample and stops at the first sample it cannot bridge, because
% one failing sample already denies the candidate and the rest of that
% placement's runs would buy nothing. The attempt retained for the row is the
% one that bridged the most samples, so a row that certifies nothing still says
% how far the best landing slot got.
% ==========================================================================

try_placements([], _, _, _, _, _, _, Best, Best, Stopped, Stopped, Ran, Ran).
try_placements([Placement|Rest], Source, Target, Adapter, Inputs,
               guard(Started, Budget, Timeout), MinDistinct, Best0, Best,
               Stopped0, Stopped, Ran0, Ran) :-
    get_time(Now),
    Elapsed is Now - Started,
    (   Elapsed >= Budget
    ->  Best = Best0, Stopped = pair_budget, Ran = Ran0
    ;   run_placement(Inputs, Source, Target, Adapter, Placement,
                      guard(Started, Budget, Timeout), [], Samples, Halt),
        Ran1 is Ran0 + 1,
        attempt_score(Samples, Bridged, Declined, Distinct),
        Attempt = attempt(Placement, Samples, Bridged, Declined, Distinct),
        better_attempt(Attempt, Best0, Best1),
        length(Inputs, Wanted),
        %   A placement that bridges every sample on too few DISTINCT adapted
        %   inputs cannot certify, so the search does not stop on it: another
        %   landing slot may leave more of the grid's variation standing.
        (   Halt == pair_budget
        ->  Best = Best1, Stopped = pair_budget, Ran = Ran1
        ;   Bridged >= Wanted, Distinct >= MinDistinct
        ->  Best = Best1, Stopped = Stopped0, Ran = Ran1
        ;   try_placements(Rest, Source, Target, Adapter, Inputs,
                           guard(Started, Budget, Timeout), MinDistinct,
                           Best1, Best, Stopped0, Stopped, Ran1, Ran)
        )
    ).

run_placement([], _, _, _, _, _, Samples0, Samples, completed) :-
    reverse(Samples0, Samples).
run_placement([Input|Rest], Source, Target, Adapter, Placement,
              guard(Started, Budget, Timeout), Samples0, Samples, Halt) :-
    get_time(Now),
    Elapsed is Now - Started,
    (   Elapsed >= Budget
    ->  reverse(Samples0, Samples), Halt = pair_budget
    ;   bridge_sample(Source, Target, Adapter, Placement, Input, Timeout,
                      sample(Status, Record)),
        (   Status == bridged
        ->  run_placement(Rest, Source, Target, Adapter, Placement,
                          guard(Started, Budget, Timeout),
                          [Record|Samples0], Samples, Halt)
        ;   reverse([Record|Samples0], Samples), Halt = completed
        )
    ).

%   A bridged sample is a warranted sample: bridge_sample/7 refuses before it
%   runs the target machine when an obligation is undischarged, so nothing
%   reaches `bridged` with an obligation outstanding. Both counts go on the row
%   anyway, because a consumer reading one of them would otherwise have to take
%   the equality on trust.
attempt_score(Samples, Bridged, Declined, Distinct) :-
    findall(1, ( member(Record, Samples),
                 get_dict(status, Record, "bridged") ),
            Bridges),
    length(Bridges, Bridged),
    findall(1, ( member(Record, Samples),
                 get_dict(status, Record, "target_refused") ),
            Declines),
    length(Declines, Declined),
    distinct_adapted_inputs(Samples, Distinct).

%!  distinct_adapted_inputs(+Samples, -Count) is det.
%
%   TWENTY BRIDGED SAMPLES ARE NOT TWENTY PIECES OF EVIDENCE. The carried value
%   overwrites the slot it lands in, and that slot is one of the slots the
%   source's grid varies, so two different grid inputs can produce the SAME
%   adapted input — measured on two pairs, twenty bridged samples came from ten
%   and from thirteen distinct adapted inputs. A count of samples therefore
%   counts correlated trials as independent ones, and THE CEREMONY READS
%   `distinct_adapted_inputs`, NEVER `samples_bridged`.
%
%   Counted over every bridged sample the walk ran, not over the `sample_records`
%   the row retains: those are capped at `max_records`, and a display cap must
%   not move a number the ceremony filters on. At the defaults the two agree,
%   because max_records and sample_count are both 20.
distinct_adapted_inputs(Samples, Count) :-
    findall(Key, ( member(Record, Samples),
                   get_dict(status, Record, "bridged"),
                   get_dict(adapted_input, Record, Input),
                   Input \== null,
                   ground_key(Input, Key) ),
            Keys),
    sort(Keys, Distinct),
    length(Distinct, Count).

%!  ground_key(+Term, -Key) is det.
%
%   A DICT'S TAG IS A FRESH VARIABLE, AND TWO FREE VARIABLES ARE NOT THE SAME
%   TERM. json_to_input/2 builds each adapted input with dict_pairs/3 and an
%   anonymous tag, exactly as loop_driver's own grids do, so two structurally
%   identical adapted inputs compare unequal under ==/2 and sort/2 merges
%   nothing. Counting them straight would have reported every run as fully
%   distinct and quietly defeated the count this predicate exists to make.
%   Binding every free variable of a copy to one constant makes structurally
%   identical inputs identical terms, and leaves the inputs themselves alone.
ground_key(Term, Key) :-
    copy_term(Term, Key),
    term_variables(Key, Variables),
    maplist(=(dict_tag), Variables).

%   Most bridges first, and among equally bridging placements the one resting on
%   the most distinct adapted inputs.
better_attempt(Attempt, none, Attempt) :- !.
better_attempt(attempt(P1, S1, B1, D1, N1), attempt(_, _, B0, _, N0), Best) :-
    (   B1 > B0
    ->  true
    ;   B1 =:= B0, N1 > N0
    ),
    !,
    Best = attempt(P1, S1, B1, D1, N1).
better_attempt(_, Best, Best).


% ==========================================================================
% 10. THE ROW
%
% Every attempted item produces a row. A pair whose source never computes, a
% target with no landing slot, a spent budget and an exhausted placement search
% are all retained rows carrying their reason.
% ==========================================================================

r4_consumer(
    "the contract_bridge candidate queue for the admission ceremony + the \c
     stage-2 gap report's missing-contract inventory + the breadth reel's \c
     grade-cut upgrade queue").

base_evidence(Evidence) :-
    Evidence = _{kind: "failed_derivation",
                 source_outcome: "not reached",
                 target_outcome: "no adapted input was run",
                 elapsed_ms: 0,
                 adapter: null,
                 adapter_signature: null,
                 adapter_obligations: [],
                 source_schema: null,
                 target_schema: null,
                 placements_available: 0,
                 placements_run: 0,
                 placement_path: null,
                 placement_index: 0,
                 grid_points_available: 0,
                 grid_points_probed: 0,
                 source_computed: 0,
                 source_refused: 0,
                 source_errored: 0,
                 samples_required: 0,
                 samples_available: 0,
                 samples_evaluated: 0,
                 samples_bridged: 0,
                 samples_warranted: 0,
                 distinct_adapted_inputs: 0,
                 distinct_inputs_required: 0,
                 samples_target_refused: 0,
                 warrant_refusals: [],
                 sample_records: [],
                 evidence_strength: "not reached",
                 walk: "not_walked"}.

r4_evidence(Measured, Evidence) :-
    base_evidence(Base),
    Evidence = Base.put(Measured).

main_item :-
    json_read_dict(current_input, Item, [value_string_as(string)]),
    r4_row(Item, Row),
    json_write_dict(current_output, Row, [width(0)]),
    nl.

%!  r4_row(+Item, -Row) is det.
r4_row(Item, Row) :-
    item_run(Item, r4),
    item_machine(Item, source, Source),
    item_machine(Item, target, Target),
    item_adapter(Item, Adapter),
    item_number(Item, pair_budget_s, Budget),
    item_number(Item, input_timeout_s, Timeout),
    item_number(Item, sample_count, SampleCount),
    item_number(Item, probe_multiple, ProbeMultiple),
    item_number(Item, min_samples, MinSamples),
    item_number(Item, max_placements, MaxPlacements),
    item_number(Item, max_records, MaxRecords),
    get_time(Started),
    (   machine_schema(Source, SourceSchema)
    ->  true
    ;   SourceSchema = null
    ),
    (   machine_schema(Target, TargetSchema)
    ->  true
    ;   TargetSchema = null
    ),
    (   \+ adapter(Adapter, _, _)
    ->  no_adapter_row(Source, Target, Adapter, Started, Row)
    ;   ( SourceSchema == null ; TargetSchema == null )
    ->  no_contract_row(Source, Target, Adapter, Started, Row)
    ;   \+ machine_grid_plan(Source, SourceSchema, _, _)
    ->  no_grid_row(Source, Target, Adapter, SourceSchema, TargetSchema,
                    Started, Row)
    ;   walked_row(Source, Target, Adapter,
                   schemas(SourceSchema, TargetSchema),
                   budget(Budget, Timeout),
                   counts(SampleCount, ProbeMultiple, MinSamples,
                          MaxPlacements, MaxRecords),
                   Started, Row)
    ).

walked_row(Source, Target, Adapter, schemas(SourceSchema, TargetSchema),
           budget(Budget, Timeout),
           counts(SampleCount, ProbeMultiple, MinSamples, MaxPlacements,
                  MaxRecords),
           Started, Row) :-
    adapter_produces(Adapter, Produced),
    placement_positions(TargetSchema, Produced, AllPlacements),
    length(AllPlacements, PlacementCount),
    take_first(MaxPlacements, AllPlacements, Placements),
    findall(Input, machine_grid_input(Source, SourceSchema, _, Input),
            GridInputs),
    length(GridInputs, GridTotal),
    %   The landing slots are checked BEFORE the source machine is run. A
    %   target contract with nowhere to put the produced value cannot be
    %   bridged by this adapter whatever the source answers, and probing a
    %   grid to learn that would spend the budget on a question already
    %   settled by the two schema strings.
    (   Placements == []
    ->  no_placement_row(Source, Target, Adapter,
                         schemas(SourceSchema, TargetSchema),
                         probe(GridTotal, 0, 0, 0, 0), Started, Row)
    ;   machine_probe_indices(Source, SourceSchema, GridTotal, SampleCount,
                              ProbeMultiple, Indices),
        findall(Input, ( member(Index, Indices), nth0(Index, GridInputs, Input) ),
                Probes),
        collect_inputs(Probes, Source, Started, budget(Budget, Timeout),
                       SampleCount, [], Inputs, 0, Probed, 0, Refused, 0,
                       Errored, completed, CollectStopped),
        length(Inputs, Computed),
        walked_placements(Source, Target, Adapter,
                          schemas(SourceSchema, TargetSchema),
                          probe(GridTotal, Probed, Computed, Refused, Errored),
                          placements(PlacementCount, Placements), Inputs,
                          budget(Budget, Timeout),
                          counts(MinSamples, MaxRecords),
                          CollectStopped, Started, Row)
    ).

walked_placements(Source, Target, Adapter,
                  schemas(SourceSchema, TargetSchema),
                  probe(GridTotal, Probed, Computed, Refused, Errored),
                  placements(PlacementCount, Placements), Inputs,
                  budget(Budget, Timeout), counts(MinSamples, MaxRecords),
                  CollectStopped, Started, Row) :-
    (   Computed < MinSamples
    ->  insufficient_row(Source, Target, Adapter,
                         schemas(SourceSchema, TargetSchema),
                         probe(GridTotal, Probed, Computed, Refused, Errored),
                         placements(PlacementCount, 0), CollectStopped,
                         Started, Row)
    ;   try_placements(Placements, Source, Target, Adapter, Inputs,
                       guard(Started, Budget, Timeout), MinSamples, none, Best,
                       CollectStopped, Stopped, 0, Ran),
        bridged_row(Source, Target, Adapter,
                    schemas(SourceSchema, TargetSchema),
                    probe(GridTotal, Probed, Computed, Refused, Errored),
                    placements(PlacementCount, Ran), Best,
                    counts(MinSamples, MaxRecords), Stopped, Started, Row)
    ).

take_first(Count, List, Prefix) :-
    length(List, Length),
    Keep is min(Count, Length),
    length(Prefix, Keep),
    append(Prefix, _, List).

bridged_row(Source, Target, Adapter, schemas(SourceSchema, TargetSchema),
            probe(GridTotal, Probed, Computed, Refused, Errored),
            placements(PlacementCount, Ran),
            attempt(pos(PlacementPath, _), Samples, Bridged, Declined, Distinct),
            counts(MinDistinct, MaxRecords), Stopped, Started, Row) :-
    !,
    elapsed_ms(Started, ElapsedMs),
    atom_string(Adapter, AdapterString),
    (   machine_grid_plan(Source, SourceSchema, Bounds, _)
    ->  term_string(Bounds, BoundsString)
    ;   BoundsString = null
    ),
    (   machine_grid_point_count(Source, SourceSchema, AuthoredPoints)
    ->  true
    ;   AuthoredPoints = 0
    ),
    path_string(PlacementPath, PlacementString),
    placement_index(TargetSchema, Adapter, PlacementPath, PlacementIndex),
    length(Samples, Evaluated),
    take_first(MaxRecords, Samples, Records),
    refusal_tally(Samples, Refusals),
    first_sample_strings(Samples, SourceOutcome, TargetOutcome),
    design_samples(Design),
    %   Evidence strength keys on DISTINCT adapted inputs, never on the raw
    %   sample count: twenty samples that produced three distinct inputs are
    %   three trials, and calling them twenty would put a design-strength stamp
    %   on a correlated run.
    (   Distinct >= Design
    ->  Strength = "design"
    ;   Strength = "grid_limited"
    ),
    r4_verdict(Bridged, Computed, Distinct, MinDistinct, Stopped, Strength,
               Refusals, Declined, Outcome, CandidateType),
    (   Bridged >= Computed, Bridged > 0
    ->  EvidenceKind = "adapted_execution_bridge"
    ;   EvidenceKind = "failed_derivation"
    ),
    atom_string(Stopped, StoppedString),
    adapter_fields(Adapter, SignatureString, Obligations),
    r4_consumer(Consumer),
    r4_evidence(_{kind: EvidenceKind,
                  source_outcome: SourceOutcome,
                  target_outcome: TargetOutcome,
                  elapsed_ms: ElapsedMs,
                  adapter: AdapterString,
                  adapter_signature: SignatureString,
                  adapter_obligations: Obligations,
                  source_schema: SourceSchema,
                  target_schema: TargetSchema,
                  placements_available: PlacementCount,
                  placements_run: Ran,
                  placement_path: PlacementString,
                  placement_index: PlacementIndex,
                  grid_points_available: GridTotal,
                  grid_points_probed: Probed,
                  source_computed: Computed,
                  source_refused: Refused,
                  source_errored: Errored,
                  samples_required: Design,
                  samples_available: Computed,
                  samples_evaluated: Evaluated,
                  samples_bridged: Bridged,
                  samples_warranted: Bridged,
                  distinct_adapted_inputs: Distinct,
                  distinct_inputs_required: MinDistinct,
                  samples_target_refused: Declined,
                  warrant_refusals: Refusals,
                  sample_records: Records,
                  evidence_strength: Strength,
                  walk: StoppedString},
                Evidence),
    Source = machine(SourceFamily, SourceKind),
    Target = machine(TargetFamily, TargetKind),
    Row = _{run: "r4",
            candidate_type: CandidateType,
            source: _{family: SourceFamily, kind: SourceKind},
            target: _{family: TargetFamily, kind: TargetKind},
            input: _{schema: SourceSchema, bounds: BoundsString,
                     points: AuthoredPoints},
            evidence: Evidence,
            outcome: Outcome,
            consumer: Consumer}.
bridged_row(Source, Target, Adapter, Schemas, Probe, Placements, none,
            _Counts, Stopped, Started, Row) :-
    insufficient_row(Source, Target, Adapter, Schemas, Probe, Placements,
                     Stopped, Started, Row).

placement_index(TargetSchema, Adapter, Path, Index) :-
    adapter_produces(Adapter, Produced),
    placement_positions(TargetSchema, Produced, Placements),
    (   nth1(Index, Placements, pos(Path, _))
    ->  true
    ;   Index = 0
    ).

%   A pair certifies when every input the source computed on bridged AND
%   every one of those bridges discharged its warrants. The candidate types
%   split the misses by what stopped them, because "the adapter never applied",
%   "the adapter applied and the warrant refused" and "the target machine
%   declined the adapted input" are three different findings and only the
%   second is about the library.
%
%   The ceremony filters on candidate_type, never on outcome: `contract_bridge`
%   and `contract_bridge_thin_evidence` both read `certified_candidate` and rest
%   on different amounts of evidence.
%
%   AND THE AMOUNT OF EVIDENCE IS `distinct_adapted_inputs`, NOT
%   `samples_bridged`. The carried value overwrites the slot it lands in, so two
%   grid inputs can produce one adapted input and twenty bridged samples can be
%   ten trials. `insufficient_distinct_inputs` is what a bridge that held on
%   every sample and rested on fewer than `min_samples` distinct adapted inputs
%   reads; it is a non-candidate, because a bridge shown on one input is a
%   coincidence with a receipt.
r4_verdict(Bridged, Computed, Distinct, MinDistinct, Stopped, Strength,
           Refusals, Declined, Outcome, CandidateType) :-
    (   Stopped == pair_budget
    ->  Outcome = "timeout", CandidateType = "pair_budget_exhausted"
    ;   Bridged >= Computed, Bridged > 0, Distinct < MinDistinct
    ->  Outcome = "no_candidate",
        CandidateType = "insufficient_distinct_inputs"
    ;   Bridged >= Computed, Bridged > 0, Strength == "design"
    ->  Outcome = "certified_candidate", CandidateType = "contract_bridge"
    ;   Bridged >= Computed, Bridged > 0
    ->  Outcome = "certified_candidate",
        CandidateType = "contract_bridge_thin_evidence"
    ;   Refusals \== []
    ->  Outcome = "no_candidate", CandidateType = "warrant_refused"
    ;   Declined > 0
    ->  Outcome = "no_candidate", CandidateType = "target_refused"
    ;   Bridged > 0
    ->  Outcome = "no_candidate", CandidateType = "bridge_partial"
    ;   Outcome = "no_candidate", CandidateType = "measured_incompatible"
    ).

%   One entry per distinct (obligation, reason) with the number of samples it
%   refused. The inventory is the run's residual product when nothing certifies,
%   so it is grouped rather than listed sample by sample.
refusal_tally(Samples, Refusals) :-
    findall(Obligation-Reason,
            ( member(Record, Samples),
              get_dict(status, Record, "warrant_refused"),
              get_dict(refused_obligation, Record, Obligation),
              get_dict(refused_reason, Record, Reason)
            ),
            Pairs),
    sort(Pairs, Distinct),
    findall(_{obligation: Obligation, reason: Reason, samples: Count},
            ( member(Obligation-Reason, Distinct),
              aggregate_all(count, member(Obligation-Reason, Pairs), Count)
            ),
            Refusals).

first_sample_strings([], "the walk collected no sample",
                     "no adapted input was run") :- !.
first_sample_strings([Record|_], SourceOutcome, TargetOutcome) :-
    get_dict(source_result, Record, SourceOutcome),
    (   get_dict(target_result, Record, Target), Target \== null
    ->  TargetOutcome = Target
    ;   get_dict(note, Record, Note), Note \== null
    ->  TargetOutcome = Note
    ;   get_dict(refused_reason, Record, Reason), Reason \== null
    ->  TargetOutcome = Reason
    ;   TargetOutcome = "no adapted input was run"
    ).

adapter_fields(Adapter, SignatureString, Obligations) :-
    (   adapter(Adapter, Signature, ObligationAtoms)
    ->  term_string(Signature, SignatureString),
        findall(String, ( member(Atom, ObligationAtoms),
                          atom_string(Atom, String) ),
                Obligations)
    ;   SignatureString = "no such adapter row",
        Obligations = []
    ).

no_placement_row(Source, Target, Adapter, schemas(SourceSchema, TargetSchema),
                 probe(GridTotal, Probed, Computed, Refused, Errored),
                 Started, Row) :-
    elapsed_ms(Started, ElapsedMs),
    adapter_fields(Adapter, SignatureString, Obligations),
    atom_string(Adapter, AdapterString),
    r4_consumer(Consumer),
    r4_evidence(_{source_outcome: "the target contract has no slot this \c
                                   adapter's produced value can land in",
                  elapsed_ms: ElapsedMs,
                  adapter: AdapterString,
                  adapter_signature: SignatureString,
                  adapter_obligations: Obligations,
                  source_schema: SourceSchema,
                  target_schema: TargetSchema,
                  grid_points_available: GridTotal,
                  grid_points_probed: Probed,
                  source_computed: Computed,
                  source_refused: Refused,
                  source_errored: Errored,
                  walk: "no_placement"},
                Evidence),
    Source = machine(SourceFamily, SourceKind),
    Target = machine(TargetFamily, TargetKind),
    Row = _{run: "r4",
            candidate_type: "measured_incompatible",
            source: _{family: SourceFamily, kind: SourceKind},
            target: _{family: TargetFamily, kind: TargetKind},
            input: _{schema: SourceSchema, bounds: null, points: 0},
            evidence: Evidence,
            outcome: "no_candidate",
            consumer: Consumer}.

insufficient_row(Source, Target, Adapter, schemas(SourceSchema, TargetSchema),
                 probe(GridTotal, Probed, Computed, Refused, Errored),
                 placements(PlacementCount, Ran), Stopped, Started, Row) :-
    elapsed_ms(Started, ElapsedMs),
    adapter_fields(Adapter, SignatureString, Obligations),
    atom_string(Adapter, AdapterString),
    (   Stopped == pair_budget
    ->  Outcome = "timeout", CandidateType = "pair_budget_exhausted"
    ;   Computed =:= 0
    ->  Outcome = "refused", CandidateType = "source_never_computed"
    ;   Outcome = "no_candidate",
        CandidateType = "insufficient_source_samples"
    ),
    atom_string(Stopped, StoppedString),
    r4_consumer(Consumer),
    r4_evidence(_{source_outcome: "the source machine computed on too few \c
                                   probed grid points to sample a bridge",
                  elapsed_ms: ElapsedMs,
                  adapter: AdapterString,
                  adapter_signature: SignatureString,
                  adapter_obligations: Obligations,
                  source_schema: SourceSchema,
                  target_schema: TargetSchema,
                  placements_available: PlacementCount,
                  placements_run: Ran,
                  grid_points_available: GridTotal,
                  grid_points_probed: Probed,
                  source_computed: Computed,
                  source_refused: Refused,
                  source_errored: Errored,
                  evidence_strength: "grid_limited",
                  walk: StoppedString},
                Evidence),
    Source = machine(SourceFamily, SourceKind),
    Target = machine(TargetFamily, TargetKind),
    Row = _{run: "r4",
            candidate_type: CandidateType,
            source: _{family: SourceFamily, kind: SourceKind},
            target: _{family: TargetFamily, kind: TargetKind},
            input: _{schema: SourceSchema, bounds: null, points: 0},
            evidence: Evidence,
            outcome: Outcome,
            consumer: Consumer}.

no_grid_row(Source, Target, Adapter, SourceSchema, TargetSchema, Started, Row) :-
    elapsed_ms(Started, ElapsedMs),
    adapter_fields(Adapter, SignatureString, Obligations),
    atom_string(Adapter, AdapterString),
    r4_consumer(Consumer),
    r4_evidence(_{source_outcome: "the source contract schema carries no \c
                                   authored grid, so the bridge has no \c
                                   sample inputs",
                  elapsed_ms: ElapsedMs,
                  adapter: AdapterString,
                  adapter_signature: SignatureString,
                  adapter_obligations: Obligations,
                  source_schema: SourceSchema,
                  target_schema: TargetSchema,
                  walk: "no_grid_plan"},
                Evidence),
    Source = machine(SourceFamily, SourceKind),
    Target = machine(TargetFamily, TargetKind),
    Row = _{run: "r4",
            candidate_type: "uninstantiated_schema",
            source: _{family: SourceFamily, kind: SourceKind},
            target: _{family: TargetFamily, kind: TargetKind},
            input: _{schema: SourceSchema, bounds: null, points: 0},
            evidence: Evidence,
            outcome: "uninstantiated",
            consumer: Consumer}.

%   An item naming an adapter the library does not carry. A manifest typo would
%   otherwise fail the whole item and surface as a dead process, which reads as
%   the cluster's fault rather than the manifest's.
no_adapter_row(Source, Target, Adapter, Started, Row) :-
    elapsed_ms(Started, ElapsedMs),
    atom_string(Adapter, AdapterString),
    findall(Known, ( adapter_id(Id), atom_string(Id, Known) ), KnownIds),
    r4_consumer(Consumer),
    r4_evidence(_{source_outcome: "the item names an adapter the authored \c
                                   library does not carry",
                  elapsed_ms: ElapsedMs,
                  adapter: AdapterString,
                  adapter_signature: "no such adapter row",
                  adapter_obligations: KnownIds,
                  walk: "no_adapter_row"},
                Evidence),
    Source = machine(SourceFamily, SourceKind),
    Target = machine(TargetFamily, TargetKind),
    Row = _{run: "r4",
            candidate_type: "no_adapter_row",
            source: _{family: SourceFamily, kind: SourceKind},
            target: _{family: TargetFamily, kind: TargetKind},
            input: _{schema: null, bounds: null, points: 0},
            evidence: Evidence,
            outcome: "uninstantiated",
            consumer: Consumer}.

no_contract_row(Source, Target, Adapter, Started, Row) :-
    elapsed_ms(Started, ElapsedMs),
    adapter_fields(Adapter, SignatureString, Obligations),
    atom_string(Adapter, AdapterString),
    r4_consumer(Consumer),
    r4_evidence(_{source_outcome: "no automaton_input_contract row names one \c
                                   of these two machines",
                  elapsed_ms: ElapsedMs,
                  adapter: AdapterString,
                  adapter_signature: SignatureString,
                  adapter_obligations: Obligations,
                  walk: "no_contract_row"},
                Evidence),
    Source = machine(SourceFamily, SourceKind),
    Target = machine(TargetFamily, TargetKind),
    Row = _{run: "r4",
            candidate_type: "no_contract_row",
            source: _{family: SourceFamily, kind: SourceKind},
            target: _{family: TargetFamily, kind: TargetKind},
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
                    context(r4_driver:r4_row/2,
                            'r4_driver runs r4 items; r1 and r2 items go to \c
                             loop_driver:main_item and r3 items to \c
                             r3_driver:main_item')))
    ).

item_machine(Item, Key, machine(Family, Kind)) :-
    get_dict(Key, Item, Sub),
    get_dict(family, Sub, FamilyString),
    get_dict(kind, Sub, KindString),
    atom_string(Family, FamilyString),
    atom_string(Kind, KindString).

item_adapter(Item, Adapter) :-
    get_dict(adapter, Item, AdapterString),
    atom_string(Adapter, AdapterString).

item_number(Item, Key, Value) :-
    default(Key, Default),
    (   get_dict(Key, Item, Given), number(Given)
    ->  Value = Given
    ;   Value = Default
    ).
