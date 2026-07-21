/** <module> Recursive unit actions and positional numerals
 *
 * A small, executable kernel for the recurring one-and-many structure shared
 * by counting, place-value regrouping, and fraction construction. Positional
 * numerals retain their base, sign, radix position, digit values, and digit
 * glyphs. Each place projects to the same regroup/partition actions used by the
 * fraction plans below, while distinct action histories remain distinct terms.
 *
 * Plans are ordinary Prolog terms and can therefore be executed, inspected,
 * nested, reconstructed from a scene, or supplied as the input to another
 * operation:
 *
 *   plan(unit(whole), [regroup(7)], iterate(1))
 *   plan(unit(whole), [partition(7)], iterate(7))
 *
 * The first plan names one seven-unit made from seven ones.  The second names
 * seven iterations of one seventh.  They are not the same operation: their
 * directions and resulting units remain in the plan and trace.  The shared
 * relation is that each coordinates seven current units with one referent at
 * the adjacent scale.
 */

:- module(recursive_unit_actions,
          [ integer_numeral/3,
            value_numeral/3,
            numeral_integer/2,
            numeral_value/2,
            numeral_text/2,
            numeral_well_formed/1,
            numeral_place/4,
            numeral_unit_tree/2,
            unit_tree_numeral/2,
            numeral_action_witness/3,
            action_witness_unit_tree/3,
            unit_tree_action_witness/3,
            run_numeral_plan/3,
            numeral_equivalent/2,
            numeral_deformation/4,
            numeral_plan_deformation/4,
            digit_sign/3,
            fraction_unit_plan/3,
            unit_plan_numeral/3,
            base_regroup_plan/2,
            base_count_plan/2,
            run_unit_plan/3,
            unit_equivalent/2,
            validate_fraction_candidate/4,
            unit_echo_witness/3,
            plan_dict/2
          ]).

:- use_module(formalization(grounded_arithmetic), [integer_to_digit_list/3]).


% -----------------------------------------------------------------------------
% Positional numeral kernel
% -----------------------------------------------------------------------------

%!  integer_numeral(+Integer, +Base, -Numeral) is semidet.
%
%   Produce a canonical positional inscription. Digits are high-place first;
%   Radix is the number of digits before the radix point. Glyph is kept beside
%   its value so bases above ten do not confuse a digit with its inscription.
integer_numeral(Integer, Base,
                numeral(Base, Sign, radix(Radix), Digits)) :-
    integer(Integer),
    valid_base(Base),
    Magnitude is abs(Integer),
    integer_to_digit_list(Magnitude, Base, Values),
    maplist(value_digit(Base), Values, Digits),
    length(Digits, Radix),
    integer_sign(Integer, Sign).


%!  value_numeral(+Value, +Base, -Numeral) is semidet.
%
%   Inscribe an integer or exactly terminating rational in Base. Failure for a
%   repeating expansion is deliberate: a finite positional inscription is not
%   fabricated for values such as one third in base ten.
value_numeral(Value, Base,
              numeral(Base, Sign, radix(Radix), Digits)) :-
    number(Value),
    \+ float(Value),
    valid_base(Base),
    value_sign(Value, Sign),
    Magnitude is abs(Value),
    Numerator is numerator(Magnitude),
    Denominator is denominator(Magnitude),
    finite_fractional_places(Denominator, Base, FractionalPlaces),
    Scale is Base ^ FractionalPlaces,
    Encoded is (Numerator * Scale) // Denominator,
    integer_to_digit_list(Encoded, Base, EncodedValues),
    pad_fractional_values(EncodedValues, FractionalPlaces, Values, Radix),
    maplist(value_digit(Base), Values, Digits),
    numeral_well_formed(numeral(Base, Sign, radix(Radix), Digits)).


%!  numeral_integer(+Numeral, -Integer) is semidet.
%
%   Read an integral numeral back to an integer. Numerals with a non-zero
%   fractional part fail rather than silently rounding.
numeral_integer(Numeral, Integer) :-
    numeral_value(Numeral, Value),
    Denominator is denominator(Value),
    Denominator =:= 1,
    Integer is numerator(Value).


%!  numeral_value(+Numeral, -Value) is semidet.
%
%   Evaluate the inscription exactly. Value is an integer or SWI rational, so
%   no floating-point approximation enters the projection.
numeral_value(numeral(Base, Sign, radix(Radix), Digits), Value) :-
    numeral_well_formed(numeral(Base, Sign, radix(Radix), Digits)),
    maplist(digit_value, Digits, Values),
    digits_integer(Values, Base, 0, Encoded),
    length(Digits, Length),
    FractionalPlaces is Length - Radix,
    Scale is Base ^ FractionalPlaces,
    Magnitude is Encoded rdiv Scale,
    signed_value(Sign, Magnitude, Value).


%!  numeral_text(+Numeral, -Text) is semidet.
%
%   Render canonical digit glyphs with the stored radix position. This is the
%   semantic inscription string; layout remains the responsibility of renderers.
numeral_text(numeral(Base, Sign, radix(Radix), Digits), Text) :-
    numeral_well_formed(numeral(Base, Sign, radix(Radix), Digits)),
    maplist(digit_glyph, Digits, Glyphs),
    length(IntegerGlyphs, Radix),
    append(IntegerGlyphs, FractionGlyphs, Glyphs),
    atomics_to_string(IntegerGlyphs, "", IntegerText0),
    integer_text(IntegerText0, IntegerText),
    fraction_text(FractionGlyphs, IntegerText, Unsigned),
    sign_text(Sign, Unsigned, Text).


%!  numeral_well_formed(+Numeral) is semidet.
numeral_well_formed(numeral(Base, Sign, radix(Radix), Digits)) :-
    valid_base(Base),
    memberchk(Sign, [negative, zero, positive]),
    is_list(Digits),
    Digits = [_|_],
    length(Digits, Length),
    integer(Radix), Radix >= 1, Radix =< Length,
    maplist(valid_digit(Base), Digits),
    maplist(digit_value, Digits, Values),
    values_sign(Values, Sign).


%!  numeral_place(+Numeral, -Exponent, -DigitValue, -Glyph) is nondet.
%
%   Enumerate explicit places. Exponent 0 is the unit place; negative exponents
%   are below the radix point and positive exponents are regrouped units.
numeral_place(numeral(Base, Sign, radix(Radix), Digits),
              Exponent, Value, Glyph) :-
    numeral_well_formed(numeral(Base, Sign, radix(Radix), Digits)),
    nth0(Index, Digits, digit(Value, Glyph)),
    Exponent is Radix - Index - 1.


%!  numeral_unit_tree(+Numeral, -Tree) is semidet.
%
%   Project every explicit digit place to the recursively reorganized unit it
%   counts. The tree retains zero-place nodes; omission is therefore observable
%   instead of disappearing during value evaluation.
numeral_unit_tree(Numeral,
                  unit_tree(unit(whole), Base, sign(Sign), radix(Radix),
                            Places)) :-
    Numeral = numeral(Base, Sign, radix(Radix), _),
    numeral_well_formed(Numeral),
    findall(place(Exponent, digit(Value, Glyph), unit(UnitExpr),
                  iterate(Value)),
            ( numeral_place(Numeral, Exponent, Value, Glyph),
              unit_actions_for_exponent(Base, Exponent, Actions),
              actions_unit_expr(unit(whole), Actions, UnitExpr)
            ),
            Places).


%!  unit_tree_numeral(+Tree, -Numeral) is semidet.
unit_tree_numeral(
        unit_tree(unit(whole), Base, sign(Sign), radix(Radix), Places),
        Numeral) :-
    maplist(tree_place_digit(Base), Places, Digits),
    Numeral = numeral(Base, Sign, radix(Radix), Digits),
    numeral_well_formed(Numeral),
    numeral_unit_tree(Numeral,
                      unit_tree(unit(whole), Base, sign(Sign), radix(Radix),
                                Places)).


%!  numeral_action_witness(+Numeral, -Plan, -Trace) is nondet.
%
%   Project an inscription to executable action structure. The first witness is
%   its positional decomposition. Integral non-negative numerals also admit the
%   distinct count-by-ones history; equivalence does not erase provenance.
numeral_action_witness(Numeral,
                       numeral_plan(unit(whole), Base, Sign, radix(Radix), Places),
                       [ establish_referent(unit(whole)),
                         establish_base(Base),
                         establish_sign(Sign),
                         establish_radix(Radix)
                       | PlaceTraces ]) :-
    Numeral = numeral(Base, Sign, radix(Radix), _),
    numeral_well_formed(Numeral),
    findall(Place,
            numeral_place_plan(Numeral, Place),
            Places),
    maplist(place_plan_trace, Places, PlaceTrace0),
    append(PlaceTrace0, [preserve_positional_sum], PlaceTraces).
numeral_action_witness(Numeral,
                       count_plan(unit(whole), iterate(Count), inscription(Numeral)),
                       [ establish_referent(unit(whole)),
                         iterate_current_unit(Count, unit(whole)),
                         inscribe(Numeral)
                       ]) :-
    numeral_integer(Numeral, Count),
    Count >= 0.


%!  action_witness_unit_tree(+Plan, +Trace, -Tree) is semidet.
action_witness_unit_tree(Plan, Trace, Tree) :-
    action_plan_numeral(Plan, Numeral),
    numeral_action_witness(Numeral, Plan, Trace),
    numeral_unit_tree(Numeral, Tree).


%!  unit_tree_action_witness(+Tree, -Plan, -Trace) is nondet.
unit_tree_action_witness(Tree, Plan, Trace) :-
    unit_tree_numeral(Tree, Numeral),
    numeral_action_witness(Numeral, Plan, Trace).


%!  run_numeral_plan(+Plan, -Value, -Trace) is semidet.
run_numeral_plan(
        numeral_plan(unit(whole), Base, Sign, radix(Radix), Places),
        Value,
        [execute_places(PlaceTraces), preserve_positional_sum]) :-
    valid_base(Base),
    memberchk(Sign, [negative, zero, positive]),
    integer(Radix), Radix >= 1,
    maplist(place_plan_value(Base), Places, Terms, PlaceTraces),
    sum_list(Terms, Magnitude),
    signed_value(Sign, Magnitude, Value),
    sign_matches_value(Sign, Value).
run_numeral_plan(
        count_plan(unit(whole), iterate(Count), inscription(Numeral)),
        Count,
        [iterate_current_unit(Count, unit(whole)), inscribe(Numeral)]) :-
    integer(Count), Count >= 0,
    numeral_integer(Numeral, Count).


%!  numeral_equivalent(+Left, +Right) is semidet.
numeral_equivalent(Left, Right) :-
    numeral_value(Left, LeftValue),
    numeral_value(Right, RightValue),
    LeftValue =:= RightValue.


%!  numeral_deformation(+Source, +Kind, -Produced, -Evidence) is semidet.
%
%   Named changes to an inscription. Each result remains a well-formed numeral
%   while failing to preserve the source value; the evidence records rather
%   than repairs that divergence.
numeral_deformation(Source, zero_placeholder_omission(Exponent), Produced,
                    Evidence) :-
    Source = numeral(Base, Sign, radix(Radix), Digits),
    numeral_well_formed(Source),
    nth0(Index, Digits, digit(0, _Glyph), Rest),
    length(Rest, RestLength),
    RestLength > 0,
    Exponent is Radix - Index - 1,
    ( Index < Radix -> NewRadix is Radix - 1 ; NewRadix = Radix ),
    Produced = numeral(Base, Sign, radix(NewRadix), Rest),
    deformation_evidence(Source, Produced, zero_placeholder_omission,
                         omitted_place(Exponent), Evidence).
numeral_deformation(Source, incorrect_place_shift(toward_higher_place),
                    Produced, Evidence) :-
    Source = numeral(Base, Sign, radix(Radix), Digits),
    length(Digits, Length),
    NewRadix is Radix + 1,
    NewRadix =< Length,
    Produced = numeral(Base, Sign, radix(NewRadix), Digits),
    deformation_evidence(Source, Produced, incorrect_place_shift,
                         radix_moved(Radix, NewRadix), Evidence).
numeral_deformation(Source, incorrect_place_shift(toward_lower_place),
                    Produced, Evidence) :-
    Source = numeral(Base, Sign, radix(Radix), Digits),
    NewRadix is Radix - 1,
    NewRadix >= 1,
    Produced = numeral(Base, Sign, radix(NewRadix), Digits),
    deformation_evidence(Source, Produced, incorrect_place_shift,
                         radix_moved(Radix, NewRadix), Evidence).
numeral_deformation(Source, wrong_radix_placement(NewRadix), Produced,
                    Evidence) :-
    Source = numeral(Base, Sign, radix(Radix), Digits),
    length(Digits, Length),
    integer(NewRadix), NewRadix >= 1, NewRadix =< Length,
    NewRadix =\= Radix,
    Produced = numeral(Base, Sign, radix(NewRadix), Digits),
    deformation_evidence(Source, Produced, wrong_radix_placement,
                         radix_moved(Radix, NewRadix), Evidence).
numeral_deformation(Source, digit_transposition(Left, Right), Produced,
                    Evidence) :-
    Source = numeral(Base, Sign, radix(Radix), Digits),
    integer(Left), integer(Right), Left >= 0, Right >= 0, Left < Right,
    nth0(Left, Digits, LeftDigit),
    nth0(Right, Digits, RightDigit),
    LeftDigit \== RightDigit,
    replace_nth0(Digits, Left, RightDigit, Swapped0),
    replace_nth0(Swapped0, Right, LeftDigit, Swapped),
    Produced = numeral(Base, Sign, radix(Radix), Swapped),
    deformation_evidence(Source, Produced, digit_transposition,
                         exchanged_places(Left, Right), Evidence).


%!  numeral_plan_deformation(+Numeral, +Kind, -Plan, -Evidence) is semidet.
numeral_plan_deformation(Numeral, omitted_regrouping(Exponent), DeformedPlan,
                         Evidence) :-
    numeral_action_witness(
        Numeral,
        numeral_plan(unit(whole), Base, Sign, radix(Radix), Places), _),
    nth0(Index, Places,
         place_action(Exponent, Digit, [regroup(Base)|Actions], Iterate)),
    DeformedPlace = place_action(Exponent, Digit, Actions, Iterate),
    replace_nth0(Places, Index, DeformedPlace, DeformedPlaces),
    DeformedPlan = numeral_plan(unit(whole), Base, Sign, radix(Radix),
                                DeformedPlaces),
    numeral_value(Numeral, ExpectedValue),
    run_numeral_plan(DeformedPlan, ProducedValue, _),
    ProducedValue =\= ExpectedValue,
    Evidence = numeral_deformation_evidence{
        family: omitted_regrouping,
        place: Exponent,
        expected_value: ExpectedValue,
        produced_value: ProducedValue,
        violation: regrouping_action_omitted
    }.


%!  digit_sign(+Base, +Value, -Glyph) is semidet.
%
%   Canonical digit alphabet: 0-9, A-Z, then bracketed values. The bracketed
%   fallback keeps the term defined for every finite base rather than imposing
%   an alphabetic base-36 ceiling.
digit_sign(Base, Value, Glyph) :-
    valid_base(Base),
    integer(Value), Value >= 0, Value < Base,
    canonical_digit_glyph(Value, Glyph).

value_sign(Value, zero) :- Value =:= 0, !.
value_sign(Value, positive) :- Value > 0, !.
value_sign(_Value, negative).

finite_fractional_places(1, _Base, 0) :- !.
finite_fractional_places(Denominator, Base, Places) :-
    Common is gcd(Denominator, Base),
    Common > 1,
    Reduced is Denominator // Common,
    finite_fractional_places(Reduced, Base, Rest),
    Places is Rest + 1.

pad_fractional_values(Values0, FractionalPlaces, Values, Radix) :-
    length(Values0, Length0),
    IntegerPlaces is Length0 - FractionalPlaces,
    ( IntegerPlaces >= 1
    -> Values = Values0,
       Radix = IntegerPlaces
    ;  ZeroCount is 1 - IntegerPlaces,
       length(Zeroes, ZeroCount),
       maplist(=(0), Zeroes),
       append(Zeroes, Values0, Values),
       Radix = 1
    ).


value_digit(Base, Value, digit(Value, Glyph)) :-
    digit_sign(Base, Value, Glyph).

valid_digit(Base, digit(Value, Glyph)) :-
    digit_sign(Base, Value, Glyph).

digit_value(digit(Value, _Glyph), Value).
digit_glyph(digit(_Value, Glyph), Glyph).

canonical_digit_glyph(Value, Glyph) :-
    Value =< 9,
    !,
    number_string(Value, Glyph).
canonical_digit_glyph(Value, Glyph) :-
    Value =< 35,
    !,
    Code is 0'A + Value - 10,
    string_codes(Glyph, [Code]).
canonical_digit_glyph(Value, Glyph) :-
    format(string(Glyph), "[~w]", [Value]).

integer_sign(Integer, zero) :- Integer =:= 0, !.
integer_sign(Integer, positive) :- Integer > 0, !.
integer_sign(_Integer, negative).

values_sign(Values, zero) :-
    maplist(=(0), Values),
    !.
values_sign(Values, Sign) :-
    memberchk(Sign, [positive, negative]),
    once((member(Value, Values), Value =\= 0)).

digits_integer([], _Base, Value, Value).
digits_integer([Digit|Digits], Base, Acc0, Value) :-
    Acc is Acc0 * Base + Digit,
    digits_integer(Digits, Base, Acc, Value).

signed_value(zero, _Magnitude, 0).
signed_value(positive, Magnitude, Magnitude) :- Magnitude > 0.
signed_value(negative, Magnitude, Value) :-
    Magnitude > 0,
    Value is -Magnitude.

sign_matches_value(zero, Value) :- Value =:= 0.
sign_matches_value(positive, Value) :- Value > 0.
sign_matches_value(negative, Value) :- Value < 0.

integer_text("", "0") :- !.
integer_text(Text, Text).

fraction_text([], IntegerText, IntegerText) :- !.
fraction_text(FractionGlyphs, IntegerText, Text) :-
    atomics_to_string(FractionGlyphs, "", FractionText),
    format(string(Text), "~w.~w", [IntegerText, FractionText]).

sign_text(negative, Unsigned, Text) :-
    !,
    string_concat("-", Unsigned, Text).
sign_text(_Sign, Text, Text).

numeral_place_plan(Numeral,
                   place_action(Exponent, digit(Value, Glyph), Actions,
                                iterate(Value))) :-
    Numeral = numeral(Base, _Sign, _Radix, _Digits),
    numeral_place(Numeral, Exponent, Value, Glyph),
    unit_actions_for_exponent(Base, Exponent, Actions).

unit_actions_for_exponent(Base, Exponent, Actions) :-
    Exponent >= 0,
    !,
    repeat_action(Exponent, regroup(Base), Actions).
unit_actions_for_exponent(Base, Exponent, Actions) :-
    Count is -Exponent,
    repeat_action(Count, partition(Base), Actions).

repeat_action(0, _Action, []) :- !.
repeat_action(Count, Action, [Action|Actions]) :-
    Count > 0,
    Next is Count - 1,
    repeat_action(Next, Action, Actions).

tree_place_digit(Base,
                 place(Exponent, digit(Value, Glyph), unit(UnitExpr),
                       iterate(Value)),
                 digit(Value, Glyph)) :-
    digit_sign(Base, Value, Glyph),
    unit_actions_for_exponent(Base, Exponent, Actions),
    actions_unit_expr(unit(whole), Actions, UnitExpr).

action_plan_numeral(
        numeral_plan(unit(whole), Base, Sign, radix(Radix), Places),
        numeral(Base, Sign, radix(Radix), Digits)) :-
    maplist(place_plan_digit, Places, Digits),
    numeral_well_formed(numeral(Base, Sign, radix(Radix), Digits)).
action_plan_numeral(
        count_plan(unit(whole), iterate(_Count), inscription(Numeral)),
        Numeral) :-
    numeral_well_formed(Numeral).

place_plan_digit(place_action(_Exponent, Digit, _Actions, _Iterate), Digit).

deformation_evidence(Source, Produced, Family, Change,
                     numeral_deformation_evidence{
                         family: Family,
                         change: Change,
                         expected_value: Expected,
                         produced_value: Actual,
                         violation: numeral_value_not_preserved
                     }) :-
    numeral_well_formed(Produced),
    numeral_value(Source, Expected),
    numeral_value(Produced, Actual),
    Actual =\= Expected.

replace_nth0([_Old|Rest], 0, New, [New|Rest]) :- !.
replace_nth0([Head|Rest], Index, New, [Head|Changed]) :-
    Index > 0,
    Next is Index - 1,
    replace_nth0(Rest, Next, New, Changed).

place_plan_trace(place_action(Exponent, Digit, Actions, Iterate),
                 execute_place(Exponent, Digit, Actions, Iterate)).

place_plan_value(Base,
                 place_action(Exponent, digit(Digit, Glyph), Actions,
                              iterate(Digit)),
                 Term,
                 execute_place(Exponent, digit(Digit, Glyph), Actions,
                               iterate(Digit))) :-
    digit_sign(Base, Digit, Glyph),
    actions_weight(Actions, Base, 1, Weight),
    Term is Digit * Weight.

actions_weight([], _Base, Weight, Weight).
actions_weight([regroup(Base)|Actions], Base, Weight0, Weight) :-
    Weight1 is Weight0 * Base,
    actions_weight(Actions, Base, Weight1, Weight).
actions_weight([partition(Base)|Actions], Base, Weight0, Weight) :-
    Weight1 is Weight0 rdiv Base,
    actions_weight(Actions, Base, Weight1, Weight).

place_weight(Base, Exponent, Weight) :-
    Exponent >= 0,
    !,
    Weight is Base ^ Exponent.
place_weight(Base, Exponent, Weight) :-
    PositiveExponent is -Exponent,
    Denominator is Base ^ PositiveExponent,
    Weight is 1 rdiv Denominator.


%!  fraction_unit_plan(+Numerator, +Denominator, -Plan) is semidet.
fraction_unit_plan(N, D,
                   plan(unit(whole), [partition(D)], iterate(N))) :-
    positive_integer(N),
    positive_integer(D).


%!  unit_plan_numeral(+Plan, +Base, -Numeral) is semidet.
unit_plan_numeral(Plan, Base, Numeral) :-
    run_unit_plan(Plan, Quantity, _Trace),
    Quantity = quantity(_, canonical_value(fraction(N, D)), _, _, _, _),
    Value is N rdiv D,
    value_numeral(Value, Base, Numeral).


%!  base_regroup_plan(+Base, -Plan) is semidet.
%
%   One composite base-unit, made by regrouping Base copies of the current
%   unit.  The plan's value is Base referent units, but its iteration count is
%   one because the current unit has changed.
base_regroup_plan(Base,
                  plan(unit(whole), [regroup(Base)], iterate(1))) :-
    valid_base(Base).


%!  base_count_plan(+Base, -Plan) is semidet.
%
%   The pre-regrouping side of the same base cycle: count Base bare units.
base_count_plan(Base,
                plan(unit(whole), [], iterate(Base))) :-
    valid_base(Base).


%!  run_unit_plan(+Plan, -Quantity, -Trace) is semidet.
%
%   Execute a numeral-level unit plan exactly.  RawFraction retains the named
%   unit structure (for example 7/7); CanonicalFraction supports equivalence
%   checks (the same example reduces to 1/1).  No action term is discarded.
run_unit_plan(plan(Referent, Actions, iterate(Count)), Quantity, Trace) :-
    valid_referent(Referent),
    is_list(Actions),
    positive_integer(Count),
    apply_unit_actions(Actions,
                       unit_state(Referent, 1, 1, Referent),
                       UnitState,
                       ActionTrace),
    UnitState = unit_state(Referent, UnitNumerator, UnitDenominator, UnitExpr),
    RawNumerator is Count * UnitNumerator,
    RawDenominator = UnitDenominator,
    reduce_fraction(RawNumerator, RawDenominator,
                    CanonicalNumerator, CanonicalDenominator),
    completion_count(UnitNumerator, UnitDenominator, Completion),
    Quantity = quantity(
                   raw_value(fraction(RawNumerator, RawDenominator)),
                   canonical_value(fraction(CanonicalNumerator,
                                            CanonicalDenominator)),
                   current_unit(UnitExpr),
                   referent(Referent),
                   completion_count(Completion),
                   source_plan(plan(Referent, Actions, iterate(Count)))),
    append([establish_referent(Referent) | ActionTrace],
           [iterate_current_unit(Count, UnitExpr),
            preserve_referent(Referent)],
           Trace).


%!  unit_equivalent(+UnitExprA, +UnitExprB) is semidet.
unit_equivalent(A, B) :-
    unit_expr_ratio(A, Ref, AN, AD),
    unit_expr_ratio(B, Ref, BN, BD),
    AN * BD =:= BN * AD.


%!  validate_fraction_candidate(+N, +D, +CandidatePlan, -Verdict) is det.
%
%   Validate a reconstructed or proposed plan against N/D while retaining
%   nearby unit-loss deformations as named outcomes.
validate_fraction_candidate(N, D, Candidate, Verdict) :-
    (   fraction_unit_plan(N, D, Expected),
        valid_plan(Candidate)
    ->  classify_fraction_candidate(N, D, Expected, Candidate, Verdict)
    ;   Verdict = unsupported(invalid_fraction_plan)
    ).


%!  unit_echo_witness(+Base, +Iterations, -Witness) is semidet.
%
%   Relate the outward base cycle to the inward fraction cycle without
%   identifying the radix with the denominator.  Base is deliberately copied
%   into the fraction plan by this caller: that is the representational echo.
unit_echo_witness(Base, Iterations, Witness) :-
    valid_base(Base),
    positive_integer(Iterations),
    base_count_plan(Base, CountPlan),
    base_regroup_plan(Base, RegroupPlan),
    fraction_unit_plan(Iterations, Base, FractionPlan),
    run_unit_plan(CountPlan, CountQuantity, CountTrace),
    run_unit_plan(RegroupPlan, RegroupQuantity, RegroupTrace),
    run_unit_plan(FractionPlan, FractionQuantity, FractionTrace),
    CountQuantity = quantity(_, CountCanonical, _, _, _, _),
    RegroupQuantity = quantity(_, RegroupCanonical, _, _, _, _),
    CountCanonical == RegroupCanonical,
    validate_fraction_candidate(Iterations, Base, FractionPlan, Verdict),
    Witness = unit_echo_witness(
                  base(Base),
                  outward_cycle(
                      count(CountPlan, CountQuantity, CountTrace),
                      regroup(RegroupPlan, RegroupQuantity, RegroupTrace),
                      invariant(Base, copies_of(unit(whole)),
                                one(regrouped_unit(Base)))),
                  inward_cycle(
                      fraction(FractionPlan, FractionQuantity, FractionTrace),
                      invariant(Base, copies_of(partition(Base, unit(whole))),
                                one(unit(whole))),
                      validation(Verdict)),
                  relation(opposed_reunitization_directions)).


%!  plan_dict(+Plan, -Dict) is det.
plan_dict(plan(Referent, Actions, iterate(Count)), Dict) :-
    term_string(Referent, ReferentString),
    maplist(term_string, Actions, ActionStrings),
    term_string(plan(Referent, Actions, iterate(Count)), PlanString),
    Dict = _{ plan: PlanString,
              referent: ReferentString,
              unitActions: ActionStrings,
              iterations: Count }.


% -----------------------------------------------------------------------------
% Execution
% -----------------------------------------------------------------------------

apply_unit_actions([], State, State, []).
apply_unit_actions([Action | Rest], State0, State, [Step | Steps]) :-
    apply_unit_action(Action, State0, State1, Step),
    apply_unit_actions(Rest, State1, State, Steps).

apply_unit_action(partition(M),
                  unit_state(Ref, N0, D0, Expr0),
                  unit_state(Ref, N0, D, partition(M, Expr0)),
                  partition_current_unit(M, Expr0, partition(M, Expr0))) :-
    positive_integer(M),
    D is D0 * M.
apply_unit_action(regroup(M),
                  unit_state(Ref, N0, D0, Expr0),
                  unit_state(Ref, N, D0, regroup(M, Expr0)),
                  regroup_current_unit(M, Expr0, regroup(M, Expr0))) :-
    positive_integer(M),
    N is N0 * M.

completion_count(1, D, D) :- !.
completion_count(_N, _D, none).

unit_expr_ratio(unit(Name), unit(Name), 1, 1).
unit_expr_ratio(partition(M, Expr), Ref, N, D) :-
    positive_integer(M),
    unit_expr_ratio(Expr, Ref, N, D0),
    D is D0 * M.
unit_expr_ratio(regroup(M, Expr), Ref, N, D) :-
    positive_integer(M),
    unit_expr_ratio(Expr, Ref, N0, D),
    N is N0 * M.


% -----------------------------------------------------------------------------
% Candidate classification
% -----------------------------------------------------------------------------

classify_fraction_candidate(_N, _D, Expected, Candidate,
                            licensed(exact_plan)) :-
    Candidate == Expected,
    !.
classify_fraction_candidate(N, D, Expected, Candidate,
                            licensed(equivalent_unit_plan)) :-
    Expected = plan(Ref, ExpectedActions, iterate(N)),
    Candidate = plan(Ref, CandidateActions, iterate(N)),
    actions_unit_expr(Ref, ExpectedActions, ExpectedUnit),
    actions_unit_expr(Ref, CandidateActions, CandidateUnit),
    unit_equivalent(ExpectedUnit, CandidateUnit),
    run_unit_plan(Candidate, Quantity, _),
    Quantity = quantity(raw_value(fraction(RawN, RawD)), _, _, _, _, _),
    RawN * D =:= N * RawD,
    !.
classify_fraction_candidate(N, D, _Expected,
                            plan(unit(whole), [], iterate(N)),
                            deformation(whole_number_grab,
                                        lost_unit(partition(D, unit(whole))))) :-
    !.
classify_fraction_candidate(N, D, _Expected,
                            plan(unit(whole), [partition(N)], iterate(N)),
                            deformation(referent_chain_reset,
                                        renamed(fraction(N, D), fraction(N, N)))) :-
    N > D,
    !.
classify_fraction_candidate(N, D, _Expected, Candidate,
                            unsupported(value_or_unit_mismatch(
                                            expected(fraction(N, D)),
                                            candidate(Candidate)))).

actions_unit_expr(Ref, Actions, UnitExpr) :-
    apply_unit_actions(Actions,
                       unit_state(Ref, 1, 1, Ref),
                       unit_state(Ref, _N, _D, UnitExpr),
                       _Trace).

valid_plan(plan(Referent, Actions, iterate(Count))) :-
    valid_referent(Referent),
    positive_integer(Count),
    actions_unit_expr(Referent, Actions, _).


% -----------------------------------------------------------------------------
% Small arithmetic and type guards
% -----------------------------------------------------------------------------

reduce_fraction(N, D, RN, RD) :-
    G is gcd(N, D),
    RN is N // G,
    RD is D // G.

valid_referent(unit(whole)).

valid_base(Base) :-
    integer(Base),
    Base >= 2.

positive_integer(N) :-
    integer(N),
    N > 0.
