:- encoding(utf8).
/** <module> r4_adapters — the authored contract-bridge adapter library
 *
 * The wave-4 library for R4 of the design in
 * `.superpowers/sdd/task-2026-08-08-engineer-bigred-loops.md`: twelve authored
 * ways to carry one machine's RESULT TERM into another machine's INPUT, each
 * one a reviewable row rather than sweep output. `r4_driver.pl` runs them; this
 * file is what the review reads.
 *
 * THE THING THE DESIGN ASKS THE REVIEW: does the adapter preserve units,
 * roles, boundary, and warrant, or is it a type-level pun? So every row
 * declares the obligations it must discharge on EVERY sample, and the driver
 * writes the per-sample record on the row. A sample whose obligations are not
 * all discharged cannot count toward a candidate, and an adapter that never
 * discharges them produces a refusal inventory instead of a bridge.
 *
 * WHAT A ROW IS
 *
 *     adapter(Id, signature(Accepts, Route, Produces), Obligations)
 *
 *   Accepts      the carrier shape read off M1's result term
 *   Route        how the carrier had to be reached for this row to apply
 *   Produces     the JSON value written into M2's input
 *   Obligations  what must be discharged per sample: units, roles, boundary,
 *                and, where a transform can be inexact, exactness
 *
 * `carried/3` is the shared authored table that turns a result term into a
 * carrier. It is authored from a MEASURED census of what the 246 contracted
 * machines answer on their own verified examples (2026-08-10): 58 answer with a
 * bare integer, 22 with a bare atom, 23 refuse their own example, and the rest
 * answer with compounds whose shapes are enumerated below. Every clause here
 * cites the shapes it was written for; a shape absent from the census is absent
 * here, and `uncarried/2` names the ones deliberately left out.
 *
 * WHAT UNITS MEAN HERE, AND THE LIMIT OF IT. A unit is tracked only when the
 * RESULT TERM names it — `length(16, centimeter)` carries a unit, `value(65)`
 * from an angle machine does not, even though the 65 is degrees. So the units
 * obligation catches a unit the term declares and drops, and does not catch a
 * unit the term never declared. That is a limit of the term vocabulary, not a
 * claim that the undeclared cases are safe.
 *
 * THE MEASUREMENT CONTRAST IS THE RULE, NOT AN EXAMPLE. The corpus's own pair
 * `measurement/change_unit_label_without_scaling` (answers `quantity(3, foot)`
 * for 3 yards) against `measurement/unit_conversion_by_iteration` (answers
 * `quantity(9, foot)`) is the modelled misconception: relabelling a unit
 * without scaling the magnitude. So relabelling here is one row,
 * `unit_relabel_with_scaling_witness`, and it computes nothing without a
 * witness — a `scaling(From, To, Factor)` read off the sample. A dimension
 * change (square(centimeter) to centimeter) has no witness of that form and is
 * therefore refused rather than rounded off, which is the other modelled
 * misconception, `geometry/linear_unit_for_area_or_volume`.
 *
 * WHAT IS NOT A ROW. The design's list names "result to operand threading for
 * two-step tasks". That is not a transform, it is where the carried value
 * LANDS and where the other slots come from, and every row does it: the driver
 * places the produced value in a numeric or object position of M2's schema and
 * fills every remaining slot from M1's own input at the same path, or from the
 * schema's own literal. A slot that neither source supplies is not invented —
 * the adapter simply does not apply to that pair. Making threading a
 * thirteenth row would count the same mechanism twice.
 */

:- module(r4_adapters,
          [ adapter/3,
            adapter_id/1,
            adapter_count/1,
            carried/3,
            uncarried/2,
            carrier_kind/2,
            adapter_reads/3,
            adapter_produces/2,
            adapt/6,
            unit_atomic/1,
            rescale_factor/3,
            unit_slot_key/1,
            scaling_witness_keys/3,
            obligation/2
          ]).

:- use_module(library(lists)).
:- use_module(strategies('abstraction/kernel_gate_pilot'),
              [ run_kernel/4 ]).


% ==========================================================================
% 1. THE TWELVE ROWS
%
% Read top to bottom; each row names the design line it comes from. The
% ordering is the order the driver tries them, and it is deliberate: the
% transforms that change least come first, so that where two rows could both
% bridge a pair, the row admitted first is the one that did the least to the
% value.
% ==========================================================================

%!  adapter(?Id, ?Signature, ?Obligations) is nondet.
%
%   Signature is signature(Accepts, Route, Produces).
%
%   Accepts is one of `magnitude_dimensionless`, `magnitude_with_unit`,
%   `fraction`, `decimal`, `quotient_remainder`, `rational_value` (a fraction
%   or a decimal read as one number). Route constrains how `carried/3` reached
%   the carrier: `direct` (the result term IS the carrier), `unwrapped` (it was
%   inside arity-one wrappers), `any` (the row is shape-driven and does not
%   care). Only the first two rows constrain the route, because the route is
%   exactly what tells them apart. Produces is `number`, `fraction_object`, or
%   `decimal_object`.
%
%   Obligations are discharged per sample by the driver and recorded on the
%   row. `units` and `roles` are on every row because every row moves a value
%   out of one contract and into another; `boundary` is on every row because
%   every target slot declares a type; `exactness` is on the one row whose
%   transform can fail to be exact.

% --- design line: "identity" ------------------------------------------------

%   R1. The result term is already the number the target slot wants. Nothing is
%   read out of a wrapper and nothing is recomputed; the only question the row
%   raises is whether the number may occupy that slot at all, which is the
%   boundary and roles obligation. 58 machines answer with a bare integer.
adapter(identity,
        signature(magnitude_dimensionless, direct, number),
        [units, roles, boundary]).

% --- design line: "field projection/renaming" -------------------------------

%   R2. The magnitude sits inside arity-one wrappers — `value(6)`,
%   `cardinality(83)`, `limit_value(17)`, `side_length(7)`, `square_units(24)`,
%   `overshot(fraction(7,4))`. An arity-one compound holds exactly one thing,
%   so reading it out is not a choice between arguments and needs no authored
%   role. Wrappers of arity two and above DO need one, and they are the field
%   rows below rather than this one.
adapter(project_wrapped_magnitude,
        signature(magnitude_dimensionless, unwrapped, number),
        [units, roles, boundary]).

%   R3/R4. `quotient_remainder(Q, R)` is two roles, not one payload, and which
%   of them a bridge carries is the whole difference between "then divide the
%   quotient" and "then divide the remainder". Two rows, so that a ceremony can
%   admit one and refuse the other. 7 machines answer with this shape.
adapter(project_quotient,
        signature(quotient_remainder, any, number),
        [units, roles, boundary]).

adapter(project_remainder,
        signature(quotient_remainder, any, number),
        [units, roles, boundary]).

%   R5. A measured magnitude keeps its unit: `length(16, centimeter)`,
%   `quantity(9, foot)`, `area(28, square(centimeter))`,
%   `volume(34, cube(centimeter))`, `side_length(slanted_side, 21, centimeter)`,
%   `measured_quantity(area, 28, unit_power(centimeter, 2))`. This row carries
%   the magnitude AND writes the unit into the target's own unit slot, so the
%   units obligation is discharged by preservation. A target with no unit slot
%   discharges nothing: the unit would be dropped, and a dropped unit is the
%   pun the ceremony refuses by rule.
adapter(carry_measured_magnitude,
        signature(magnitude_with_unit, any, number),
        [units, roles, boundary]).

% --- design line: "unit relabel WITH the scaling witness" -------------------

%   R6. The same measured carriers, where the unit the target will read is NOT
%   the unit the carrier holds. The magnitude is scaled by a witness the sample
%   itself supplies, and without one the row computes nothing at all. The only
%   witness shape this library admits is `scaling(From, To, Factor)`, read off
%   an input that declares `from_unit`, `to_unit` and `factor` — the
%   `quantity_conversion` contract, which is where the corpus records a
%   conversion rather than assuming one. A dimension change has no witness of
%   that shape and is refused.
adapter(unit_relabel_with_scaling_witness,
        signature(magnitude_with_unit, any, number),
        [units, roles, boundary]).

% --- design line: "field projection/renaming", object targets ---------------

%   R7. `fraction(3, 4)` and `rational(5, 1)` become the target's own
%   `{n, d}` sub-object. The two arguments are named by the target's keys
%   rather than by position alone, which is the renaming half of the design's
%   line. 16 machines answer with one of these two shapes.
adapter(rename_fraction_to_fraction_object,
        signature(fraction, any, fraction_object),
        [units, roles, boundary]).

%   R8. `decimal(2, fractional_digits(8, 1), tenths)` becomes the target's
%   `{numeral, scale}` sub-object. The whole part and the fractional digits are
%   one quantity in the target's encoding — 2 and 8 tenths is numeral 28 over
%   scale 10 — so the row recomputes the pair rather than copying two
%   arguments across. 7 machines answer with this shape.
adapter(rename_decimal_to_decimal_object,
        signature(decimal, any, decimal_object),
        [units, roles, boundary]).

% --- design line: "integer -> fraction-over-1" ------------------------------

%   R9. A whole number is the fraction whose denominator is one. The row exists
%   because the largest target in the corpus after the integer pair is the
%   19-machine fraction pair, and 58 machines answer with an integer that no
%   other row can put there.
adapter(integer_over_one_to_fraction_object,
        signature(magnitude_dimensionless, any, fraction_object),
        [units, roles, boundary]).

% --- design line: "fraction -> decimal via the base-cycle kernel" -----------

%   R10. n/d becomes numeral/10^k for the least k that makes the numerator
%   whole, and the base-cycle kernel K6 does the inscription: it recollects the
%   scaled numerator into base-ten positional digits, and its refusal is the
%   row's refusal. Denominators that divide no power of ten make the transform
%   inexact and the row records `exactness` undischarged rather than rounding.
adapter(fraction_to_decimal_via_base_cycles,
        signature(fraction, any, decimal_object),
        [units, roles, boundary, exactness]).

% --- design line: "decimal -> fraction" -------------------------------------

%   R11. numeral/scale is already a fraction; the row writes it as one. Exact
%   by construction, so `exactness` is not on it.
adapter(decimal_to_fraction,
        signature(decimal, any, fraction_object),
        [units, roles, boundary]).

% --- design line: "field projection/renaming", numeric targets --------------

%   R12. A fraction or a decimal carried into a plain numeric slot as its
%   VALUE. 33 slot positions in the corpus declare `number` or
%   `positive_number` and can hold a rational exactly; a slot declaring
%   `integer` cannot hold three quarters at all, and the boundary obligation is
%   what says so rather than a rounding rule. Nothing here can be inexact —
%   the value is carried as a rational, not as a decimal expansion — so
%   `exactness` is not on the row.
adapter(project_rational_magnitude,
        signature(rational_value, any, number),
        [units, roles, boundary]).


%!  adapter_id(?Id) is nondet.
adapter_id(Id) :-
    adapter(Id, _, _).

%!  adapter_count(-Count) is det.
adapter_count(Count) :-
    findall(Id, adapter_id(Id), Ids),
    length(Ids, Count).

%!  obligation(?Id, ?Obligation) is nondet.
obligation(Id, Obligation) :-
    adapter(Id, _, Obligations),
    member(Obligation, Obligations).

%!  adapter_reads(?Id, ?CarrierKind, ?Route) is nondet.
%
%   The join step 0's static filter and the driver both use, so that a pair the
%   manifest offers is a pair the driver will at least try. `rational_value`
%   admits either a fraction or a decimal, which is why the join is a predicate
%   and not a term comparison.
adapter_reads(Id, CarrierKind, Route) :-
    adapter(Id, signature(Accepts, RouteSpec, _), _),
    accepts_kind(Accepts, CarrierKind),
    route_matches(RouteSpec, Route).

accepts_kind(rational_value, fraction) :- !.
accepts_kind(rational_value, decimal) :- !.
accepts_kind(Accepts, Accepts).

route_matches(any, _) :- !.
route_matches(direct, direct) :- !.
route_matches(unwrapped, unwrapped(_)) :- !.

%!  adapter_produces(?Id, ?Produced) is nondet.
adapter_produces(Id, Produced) :-
    adapter(Id, signature(_, _, Produced), _).


% ==========================================================================
% 2. THE CARRIER TABLE
%
% carried/3 reads a result term and says what quantity it holds and how that
% quantity was reached. Authored from the 2026-08-10 census of all 246
% contracted machines run on their own verified examples; each clause names the
% shapes it was written for and how many machines answer with them.
%
% A shape with no clause here has no bridge, and that is a measurement rather
% than an oversight: uncarried/2 names each excluded shape with the reason.
% ==========================================================================

%!  carried(+ResultTerm, -Carrier, -Route) is semidet.
%
%   Carrier is one of
%     magnitude(Value, dimensionless)
%     magnitude(Value, unit(UnitTerm))
%     fraction(Numerator, Denominator)
%     decimal(Numeral, Scale)          the value is Numeral/Scale
%     quotient_remainder(Quotient, Remainder)
%   Route is `direct`, `unwrapped(Depth)`, or `field(Functor/Arity)`.
carried(Term, magnitude(Term, dimensionless), direct) :-
    number(Term),
    !.
carried(Term, Carrier, field(Name/Arity)) :-
    compound(Term),
    functor(Term, Name, Arity),
    Arity >= 2,
    field_carrier(Term, Carrier),
    !.
carried(Term, Carrier, unwrapped(Depth)) :-
    compound(Term),
    functor(Term, _, 1),
    unwrap(Term, 1, 4, Inner, Depth),
    (   number(Inner)
    ->  Carrier = magnitude(Inner, dimensionless)
    ;   field_carrier(Inner, Carrier)
    ),
    !.

%   The authored role rows for compounds of arity two and above. Position is
%   not enough here — `numeral(10, positive, radix(3), Digits)` puts the BASE
%   first, and a rule that read the first argument as the magnitude would
%   bridge a numeral machine on the number ten. So each shape below is written
%   out, and a shape not written out has no carrier.
field_carrier(fraction(N, D), fraction(N, D)) :-
    integer(N), integer(D), D =\= 0.
field_carrier(rational(N, D), fraction(N, D)) :-
    integer(N), integer(D), D =\= 0.
%   A negative whole part or a negative digit group is REFUSED rather than
%   folded in. `decimal(-2, fractional_digits(8, 1), tenths)` could mean minus
%   two and eight tenths or minus one and two tenths, and the term does not
%   say. Measured 2026-08-10: across the whole authored grid of all seven
%   machines that answer with decimal/3, not one negative part occurs, so this
%   guard costs nothing today and stops a wrong value if a later grid produces
%   one.
field_carrier(decimal(Whole, fractional_digits(Digits, Places), _),
              decimal(Numeral, Scale)) :-
    integer(Whole), Whole >= 0,
    integer(Digits), Digits >= 0,
    integer(Places), Places >= 0,
    Scale is 10 ^ Places,
    Numeral is Whole * Scale + Digits.
field_carrier(quotient_remainder(Q, R), quotient_remainder(Q, R)) :-
    number(Q), number(R).
field_carrier(length(Magnitude, Unit), magnitude(Value, unit(Unit))) :-
    magnitude_value(Magnitude, Value).
field_carrier(quantity(Magnitude, Unit), magnitude(Value, unit(Unit))) :-
    magnitude_value(Magnitude, Value).
field_carrier(volume(Magnitude, Unit), magnitude(Value, unit(Unit))) :-
    magnitude_value(Magnitude, Value).
field_carrier(area(Magnitude, Unit), magnitude(Value, unit(Unit))) :-
    magnitude_value(Magnitude, Value).
field_carrier(angle_measure(Magnitude), magnitude(Value, dimensionless)) :-
    magnitude_value(Magnitude, Value).
field_carrier(side_length(_Role, Magnitude, Unit),
              magnitude(Value, unit(Unit))) :-
    magnitude_value(Magnitude, Value).
field_carrier(measured_quantity(_Dimension, Magnitude, Unit),
              magnitude(Value, unit(Unit))) :-
    magnitude_value(Magnitude, Value).

%   Magnitudes are numbers, or the corpus's own `rational(N, D)` term, which
%   `measurement/linear_unit_iteration` and the statistics means answer with.
magnitude_value(Value, Value) :-
    number(Value),
    !.
magnitude_value(rational(N, D), Value) :-
    integer(N), integer(D), D =\= 0,
    Value is N rdiv D.

unwrap(Term, Depth, MaxDepth, Inner, Reached) :-
    Depth =< MaxDepth,
    compound(Term),
    functor(Term, _, 1),
    arg(1, Term, Held),
    (   number(Held)
    ->  Inner = Held, Reached = Depth
    ;   field_carrier(Held, _)
    ->  Inner = Held, Reached = Depth
    ;   Next is Depth + 1,
        unwrap(Held, Next, MaxDepth, Inner, Reached)
    ).

%!  carrier_kind(+Carrier, -Kind) is det.
%
%   The `Accepts` field a row matches on, through accepts_kind/2. A magnitude
%   splits on whether the result term named a unit, because that split is what
%   decides whether the units obligation has anything to hold on to.
carrier_kind(magnitude(_, dimensionless), magnitude_dimensionless).
carrier_kind(magnitude(_, unit(_)), magnitude_with_unit).
carrier_kind(fraction(_, _), fraction).
carrier_kind(decimal(_, _), decimal).
carrier_kind(quotient_remainder(_, _), quotient_remainder).

%!  uncarried(?Shape, ?Reason) is nondet.
%
%   Result shapes the census found and this library deliberately does not
%   carry. Each is a machine that R4 cannot bridge FROM, and the list is the
%   library-authoring queue the design's falsifier asks for rather than a
%   silent gap.
uncarried(bare_atom,
          "22 machines answer with a verdict atom (more, greater_than, \c
           true). Placing a verdict in an `atom` slot that means a unit, a \c
           scope or a variable name is the type-level pun the ceremony \c
           refuses by rule, so no row reads one.").
uncarried('numeral/4',
          "counting/inscribe_cardinality and \c
           counting/recursive_place_value_inscription answer with a \c
           positional inscription whose first argument is the BASE. Reading a \c
           magnitude out of it means re-evaluating the digit list under the \c
           radix, which is a computation and not a projection.").
uncarried('decimal_quotient/2',
          "decimal/recalled_result_scaling answers decimal_quotient(120, 0) \c
           and decimal/ecuadorian_decimal_long_division answers \c
           decimal_quotient(3, 0). Two samples do not settle what the second \c
           argument means, and a guessed role is worse than an absent row.").
uncarried('long_division_result/2',
          "division/long_division answers with a STRING quotient, \c
           long_division_result(\"1.6785\", 20). Parsing a numeral out of a \c
           string is a reader, not an adapter.").
uncarried(list_shapes,
          "rectangles/1, common_factors/1, ordered_values/1, modes/1, \c
           plotted_points/1 and their kin answer with collections. The corpus \c
           has list-typed slots, but which element of a collection a bridge \c
           carries is an authored role this library does not have.").
uncarried(expression_shapes,
          "add/2, mult/2, equation/3 and the algebraic rewrite results are \c
           syntax trees. The corpus's expression slots want authored node \c
           shapes, and rebuilding one from a result term is construction \c
           rather than adaptation.").


% ==========================================================================
% 3. THE TRANSFORMS
%
% adapt/6 is where a row does its work. It is semidet on applicability and
% returns a `refused(Reason)` produce when the row APPLIES but cannot discharge
% what it must — the difference matters, because a row that does not apply is
% silence and a row that refuses is evidence.
% ==========================================================================

%!  adapt(+Id, +Carrier, +Route, +Context, -Produced, -Transform) is semidet.
%
%   Context is context(TargetUnit, Witnesses) where TargetUnit is `none` when
%   the target schema has no unit slot governing the carried position, or
%   unit(U) when it has one and U is what will be written there; Witnesses is
%   the list of scaling(From, To, Factor) the sample supplies.
%
%   Produced is
%     produced(number(Value), UnitDisposition)
%     produced(object(Pairs), UnitDisposition)
%     refused(Reason)
%   and Transform is a short authored string naming what the row did, which
%   goes on the row so a reader has the doing in words rather than having to
%   infer it from the two terms.

adapt(identity, magnitude(Value, Unit), direct,
      context(TargetUnit, Witnesses), Produced, Transform) :-
    number(Value),
    unit_disposition(Unit, TargetUnit, Witnesses, none, Disposition),
    produced_number(Value, Disposition, Produced),
    Transform = "the result term is the number the slot takes; unchanged".

adapt(project_wrapped_magnitude, magnitude(Value, Unit), unwrapped(Depth),
      context(TargetUnit, Witnesses), Produced, Transform) :-
    number(Value),
    unit_disposition(Unit, TargetUnit, Witnesses, none, Disposition),
    produced_number(Value, Disposition, Produced),
    format(string(Transform),
           "the magnitude read out of ~w arity-one wrapper(s)", [Depth]).

adapt(project_quotient, quotient_remainder(Quotient, _), _,
      context(TargetUnit, Witnesses), Produced, Transform) :-
    unit_disposition(dimensionless, TargetUnit, Witnesses, none, Disposition),
    produced_number(Quotient, Disposition, Produced),
    Transform = "the quotient role of quotient_remainder/2".

adapt(project_remainder, quotient_remainder(_, Remainder), _,
      context(TargetUnit, Witnesses), Produced, Transform) :-
    unit_disposition(dimensionless, TargetUnit, Witnesses, none, Disposition),
    produced_number(Remainder, Disposition, Produced),
    Transform = "the remainder role of quotient_remainder/2".

adapt(carry_measured_magnitude, magnitude(Value, unit(Unit)), _,
      context(TargetUnit, Witnesses), Produced, Transform) :-
    unit_disposition(unit(Unit), TargetUnit, Witnesses, preserve, Disposition),
    produced_number(Value, Disposition, Produced),
    format(string(Transform),
           "the magnitude with its unit ~w written into the target's unit slot",
           [Unit]).

adapt(unit_relabel_with_scaling_witness, magnitude(Value, unit(Unit)), _,
      context(TargetUnit, Witnesses), Produced, Transform) :-
    unit_disposition(unit(Unit), TargetUnit, Witnesses, relabel, Disposition),
    (   rescale_factor(Disposition, Factor, Direction)
    ->  Scaled is Value * Factor,
        produced_number(Scaled, Disposition, Produced),
        format(string(Transform),
               "relabelled from ~w on ~w of factor ~w", [Unit, Direction, Factor])
    ;   Produced = refused(Disposition),
        Transform = "a relabel with no witness computes nothing"
    ).

adapt(rename_fraction_to_fraction_object, fraction(N, D), _,
      context(TargetUnit, Witnesses), Produced, Transform) :-
    unit_disposition(dimensionless, TargetUnit, Witnesses, none, Disposition),
    produced_object([n-N, d-D], Disposition, Produced),
    Transform = "the two arguments named by the target's own n and d keys".

adapt(rename_decimal_to_decimal_object, decimal(Numeral, Scale), _,
      context(TargetUnit, Witnesses), Produced, Transform) :-
    unit_disposition(dimensionless, TargetUnit, Witnesses, none, Disposition),
    produced_object([numeral-Numeral, scale-Scale], Disposition, Produced),
    format(string(Transform),
           "the whole part and the fractional digits as one numeral ~w over \c
            scale ~w", [Numeral, Scale]).

adapt(integer_over_one_to_fraction_object, magnitude(Value, Unit), _,
      context(TargetUnit, Witnesses), Produced, Transform) :-
    integer(Value),
    unit_disposition(Unit, TargetUnit, Witnesses, none, Disposition),
    produced_object([n-Value, d-1], Disposition, Produced),
    Transform = "the whole number as the fraction over one".

adapt(fraction_to_decimal_via_base_cycles, fraction(N, D), _,
      context(TargetUnit, Witnesses), Produced, Transform) :-
    unit_disposition(dimensionless, TargetUnit, Witnesses, none, Disposition),
    (   least_decimal_scale(N, D, 12, Scale, Numeral)
    ->  (   inscribes_in_base_ten(Numeral, Radix)
        ->  produced_object([numeral-Numeral, scale-Scale], Disposition,
                            Produced),
            format(string(Transform),
                   "~w/~w scaled to numeral ~w over ~w, inscribed by the \c
                    base-cycle kernel in ~w place(s)",
                   [N, D, Numeral, Scale, Radix])
        ;   Produced = refused(kernel_refused_inscription(Numeral)),
            Transform = "the base-cycle kernel refused the scaled numerator"
        )
    ;   Produced = refused(inexact_in_base_ten(N, D)),
        Transform = "no power of ten clears this denominator"
    ).

adapt(decimal_to_fraction, decimal(Numeral, Scale), _,
      context(TargetUnit, Witnesses), Produced, Transform) :-
    unit_disposition(dimensionless, TargetUnit, Witnesses, none, Disposition),
    produced_object([n-Numeral, d-Scale], Disposition, Produced),
    Transform = "the numeral over its scale, written as a fraction".

adapt(project_rational_magnitude, Carrier, _,
      context(TargetUnit, Witnesses), Produced, Transform) :-
    rational_carrier_value(Carrier, Value, Shown),
    unit_disposition(dimensionless, TargetUnit, Witnesses, none, Disposition),
    produced_number(Value, Disposition, Produced),
    format(string(Transform), "~w carried into a numeric slot as its value",
           [Shown]).

%   The factor a rescaling applies, and how the row came by it. Both go on the
%   per-sample record, so a reader never has to work out whether the witness was
%   read forwards or backwards.
rescale_factor(rescaled(_, _, Factor), Factor, "a declared witness").
rescale_factor(rescaled(_, _, Factor, inverted(Declared)), Factor, Direction) :-
    format(string(Direction), "the inverse of the declared witness ~w",
           [Declared]).

rational_carrier_value(fraction(N, D), Value, Shown) :-
    D =\= 0,
    Value is N rdiv D,
    format(string(Shown), "the fraction ~w/~w", [N, D]).
rational_carrier_value(decimal(Numeral, Scale), Value, Shown) :-
    Scale =\= 0,
    Value is Numeral rdiv Scale,
    format(string(Shown), "the decimal ~w/~w", [Numeral, Scale]).

produced_number(_, Disposition, refused(Disposition)) :-
    refused_disposition(Disposition),
    !.
produced_number(Value, Disposition, produced(number(Value), Disposition)).

produced_object(_, Disposition, refused(Disposition)) :-
    refused_disposition(Disposition),
    !.
produced_object(Pairs, Disposition, produced(object(Pairs), Disposition)).

refused_disposition(dropped(_)).
refused_disposition(relabelled_without_witness(_, _)).
refused_disposition(unit_not_nameable(_)).
refused_disposition(no_relabel_required(_)).


% ==========================================================================
% 4. THE UNITS OBLIGATION
%
% One predicate, because "did this bridge keep the unit" has to be answered the
% same way for every row. Mode says what the row intends: `none` (the carrier
% declares no unit), `preserve` (the carrier's unit goes to the target
% unchanged), `relabel` (the target reads a different unit and a witness is
% required).
% ==========================================================================

%!  unit_disposition(+CarrierUnit, +TargetUnit, +Witnesses, +Mode, -Disposition)
%
%   Disposition is dimensionless, preserved(U), rescaled(From, To, Factor),
%   rescaled(From, To, Factor, inverted(Declared)), or one of the refusals in
%   refused_disposition/1.
%
%   THE INVERSE OF A DECLARED WITNESS IS A WITNESS (ruling R1, 2026-08-10). The
%   first authoring read a witness only in the direction the sample wrote it,
%   and the measured consequence was that this row could never certify on this
%   corpus: the only contract that declares a factor is quantity_conversion,
%   whose machines answer in `to_unit` while their target contracts thread
%   `from_unit`, so the relabel always needs to_unit->from_unit and the witness
%   always says from_unit->to_unit. The ceremony ruled that a declared factor
%   licenses its own inverse, because one yard being three feet is one fact and
%   not two. The DIRECTION stays on the disposition — `rescaled/4` carries
%   `inverted(Declared)` naming the witness it was derived from — so a reader
%   never has to work out which way the row read it.
%
%   The declared direction is tried first. A zero factor licenses nothing and
%   the guard is local to the inverse clause, where the division is.
unit_disposition(dimensionless, none, _, _, dimensionless) :- !.
unit_disposition(dimensionless, unit(_), _, _, dimensionless) :- !.
%   A carrier that declares a unit and a target that has nowhere to put it: the
%   unit is lost at the seam, and a lost unit is what the ceremony's review
%   question is about.
unit_disposition(unit(Unit), none, _, _, dropped(Unit)) :- !.
unit_disposition(unit(Unit), unit(Target), Witnesses, Mode, Disposition) :-
    (   \+ unit_atomic(Unit)
    ->  Disposition = unit_not_nameable(Unit)
    ;   Unit == Target
    ->  (   Mode == relabel
        ->  Disposition = no_relabel_required(Unit)
        ;   Disposition = preserved(Unit)
        )
    ;   Mode == preserve
    ->  Disposition = relabelled_without_witness(Unit, Target)
    ;   Mode == relabel
    ->  (   memberchk(scaling(Unit, Target, Factor), Witnesses)
        ->  Disposition = rescaled(Unit, Target, Factor)
        ;   memberchk(scaling(Target, Unit, Declared), Witnesses),
            Declared =\= 0
        ->  Inverse is 1 rdiv Declared,
            Disposition = rescaled(Unit, Target, Inverse,
                                   inverted(scaling(Target, Unit, Declared)))
        ;   Disposition = relabelled_without_witness(Unit, Target)
        )
    ;   Disposition = relabelled_without_witness(Unit, Target)
    ).

%!  unit_atomic(+Unit) is semidet.
%
%   A unit an `atom` slot can hold and a machine can read back. `centimeter` is
%   one; `square(centimeter)`, `cube(centimeter)` and `unit_power(centimeter, 2)`
%   are not, and writing one of them into a linear unit slot is the dimension
%   collapse `geometry/linear_unit_for_area_or_volume` models. The scaling
%   witness this library admits relates two named units by a factor and cannot
%   relate a length to an area, so a dimension change has no route here at all.
unit_atomic(Unit) :-
    atom(Unit).

%!  unit_slot_key(?Key) is nondet.
%
%   Which key of a target contract names the unit of the quantity a bridge
%   carries into it. Both rows are read off the tree's own decode seam rather
%   than guessed from the name:
%
%     `unit`       hermes/encyclopedia.pl trace_inputs/3 pairs it with the
%                  measure — `B = unit(Unit)` beside `A = measure(...)` for
%                  measure_with_unit, and the same shape for rectangle_with_unit,
%                  triangle_with_unit, numeric_data_with_unit and their kin.
%     `from_unit`  the quantity_conversion clause reads
%                  `A = quantity(Count, FromUnit)`, so from_unit is the unit OF
%                  the count, and a bridge that fills the count while leaving
%                  from_unit threaded from somewhere else has renamed the
%                  quantity. `to_unit` is the conversion's destination and not
%                  the carried quantity's unit, so it is not on this list.
unit_slot_key(unit).
unit_slot_key(from_unit).

%!  scaling_witness_keys(?CountKey, ?FromKey, ?ToKey) is nondet.
%
%   Where a sample may declare a conversion. One row, because the corpus
%   records a conversion factor in exactly one contract — quantity_conversion,
%   carrying count, from_unit, to_unit and factor — and inventing a second
%   source would be inventing a conversion.
%
%   The witness is read in the direction it was written. A factor of 3 for
%   yard to foot is not read backwards as a third of a foot to a yard: an
%   inverse is a derivation, and the design's rule is that a relabel needs a
%   witness rather than a calculation. Vetoable; the ceremony may rule that an
%   inverse is a witness, and one clause would say so.
scaling_witness_keys(from_unit, to_unit, factor).


% ==========================================================================
% 5. THE BASE-CYCLE INSCRIPTION
% ==========================================================================

%   The least power of ten that clears the denominator, up to MaxPlaces. A
%   denominator carrying any prime factor other than two or five clears no
%   power of ten, and the search stopping is how the row learns that.
least_decimal_scale(N, D, MaxPlaces, Scale, Numeral) :-
    D =\= 0,
    between(0, MaxPlaces, Places),
    Candidate is 10 ^ Places,
    Product is N * Candidate,
    Product mod D =:= 0,
    !,
    Scale = Candidate,
    Numeral is Product // D.

%   K6 of the kernel/gate pilot recollects a cardinality into base-ten
%   positional digits. The transform's scaled numerator is exactly such a
%   cardinality, so the kernel does the inscription and its refusal — a
%   negative count, a base below two — is the row's refusal.
inscribes_in_base_ten(Numeral, Radix) :-
    catch(run_kernel(recollect_base_cycles, cardinality_in_base(10),
                     [cardinality(Numeral)], run(_, _, _, _, Result)),
          _, fail),
    Result = numeral(10, _, radix(Radix), _).
