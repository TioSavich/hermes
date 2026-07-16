/** <module> Standard 3.CA.5 — Multiply and divide within 100
 *
 * Indiana: 3.CA.5 — "Multiply and divide within 100 using strategies
 *          such as the relationship between multiplication and division
 *          or properties of operations." (E)
 * CCSS:    3.OA.C.7
 *
 * CONNECTION TO EXISTING AUTOMATA:
 *   This standard is the home of the multiplication/division automata:
 *
 *   Multiplication:
 *   - smr_mult_c2c.pl  — Coordinating Two Counts (primitive)
 *   - smr_mult_cbo.pl  — Count By Ones (repeated addition)
 *   - smr_mult_dr.pl   — Derived/Recalled facts
 *   - smr_mult_commutative_reasoning.pl — use commutativity
 *
 *   Division:
 *   - smr_div_dealing_by_ones.pl — dealing/sharing
 *   - smr_div_cbo.pl — repeated subtraction
 *   - smr_div_ucr.pl — unknown chunk reduction
 *   - smr_div_idp.pl — iterative decomposition
 *
 * Named strategies within 100:
 *   1. Skip counting (count by N)
 *   2. Known facts (memorized, O(1))
 *   3. Derived facts (7×8 = 7×7+7 = 49+7 = 56)
 *   4. Distributive property (7×6 = 7×5 + 7×1)
 *   5. Commutativity (3×7 = 7×3)
 *   6. Inverse (know 8×5=40 → 40÷5=8)
 */

:- module(standard_3_ca_5, [
    mult_skip_count/3,       % +Factor, +Times, -Product
    mult_derived_fact/4,     % +A, +B, -Product, -Derivation
    mult_distributive/4,     % +A, +B, -Product, -Steps
    div_by_inverse/3         % +Dividend, +Divisor, -Quotient
]).

:- use_module(formalization(grounded_arithmetic), [
    zero/1,
    successor/2,
    predecessor/2,
    equal_to/2,
    smaller_than/2,
    add_grounded/3,
    subtract_grounded/3,
    multiply_grounded/3,
    integer_to_recollection/2,
    recollection_to_integer/2,
    incur_cost/1
]).

% ============================================================
% Skip counting strategy
% ============================================================

%!  mult_skip_count(+Factor, +Times, -Product) is det.
%
%   Multiply by skip counting: count by Factor, Times times.
%   3 × 4 → "3, 6, 9, 12". Cost: O(Times) additions.

mult_skip_count(Factor, Times, Product) :-
    incur_cost(inference),
    zero(Zero),
    skip_mult_(Factor, Times, Zero, Product).

skip_mult_(_Factor, Times, Acc, Acc) :-
    zero(Zero), equal_to(Times, Zero), !.
skip_mult_(Factor, Times, Acc, Product) :-
    add_grounded(Acc, Factor, NewAcc),
    predecessor(Times, NewTimes),
    skip_mult_(Factor, NewTimes, NewAcc, Product).


% ============================================================
% Derived facts strategy
% ============================================================

%!  mult_derived_fact(+A, +B, -Product, -Derivation) is det.
%
%   Derive a fact from a nearby known fact.
%   Strategy: A × B = A × (B-1) + A
%   This uses the "one more group" reasoning.

mult_derived_fact(A, B, Product, Derivation) :-
    incur_cost(inference),
    predecessor(B, BMinusOne),
    multiply_grounded(A, BMinusOne, NearProduct),
    add_grounded(NearProduct, A, Product),
    recollection_to_integer(A, AI),
    recollection_to_integer(B, BI),
    recollection_to_integer(BMinusOne, BMI),
    recollection_to_integer(NearProduct, NPI),
    recollection_to_integer(Product, PI),
    Derivation = derived(AI, BI, from(AI, BMI, NPI), plus(AI), equals(PI)).


% ============================================================
% Distributive property strategy
% ============================================================

%!  mult_distributive(+A, +B, -Product, -Steps) is det.
%
%   Use the distributive property to break multiplication into
%   easier parts. Splits B into 5 + remainder (since ×5 facts
%   are typically known early).
%   A × B = A × 5 + A × (B-5)    when B ≥ 5
%   Falls back to direct multiplication when B < 5.

mult_distributive(A, B, Product, Steps) :-
    incur_cost(inference),
    integer_to_recollection(5, Five),
    (   smaller_than(B, Five)
    ->  % B < 5, just multiply directly
        multiply_grounded(A, B, Product),
        Steps = direct
    ;   % B ≥ 5: split as A×5 + A×(B-5)
        subtract_grounded(B, Five, Remainder),
        multiply_grounded(A, Five, PartA),
        multiply_grounded(A, Remainder, PartB),
        add_grounded(PartA, PartB, Product),
        recollection_to_integer(A, AI),
        recollection_to_integer(Five, FI),
        recollection_to_integer(Remainder, RI),
        recollection_to_integer(PartA, PAI),
        recollection_to_integer(PartB, PBI),
        Steps = distributed(AI, times, FI, equals, PAI,
                            plus, AI, times, RI, equals, PBI)
    ).


% ============================================================
% Division by inverse strategy
% ============================================================

%!  div_by_inverse(+Dividend, +Divisor, -Quotient) is semidet.
%
%   Divide by finding the multiplication inverse:
%   "What times Divisor equals Dividend?"
%   Uses grounded division (repeated subtraction).

div_by_inverse(Dividend, Divisor, Quotient) :-
    incur_cost(inference),
    % Find Q such that Divisor × Q = Dividend
    zero(Zero),
    find_quotient_(Dividend, Divisor, Zero, Quotient).

find_quotient_(Remainder, _Divisor, Acc, Acc) :-
    zero(Zero), equal_to(Remainder, Zero), !.
find_quotient_(Remainder, Divisor, Acc, Acc) :-
    smaller_than(Remainder, Divisor), !.
find_quotient_(Remainder, Divisor, Acc, Quotient) :-
    subtract_grounded(Remainder, Divisor, NewRemainder),
    successor(Acc, NewAcc),
    find_quotient_(NewRemainder, Divisor, NewAcc, Quotient).
