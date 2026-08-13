:- encoding(utf8).
/** <module> Exact-quantity decoding for the grade 8 pilot automata
 *
 * WHAT THIS IS. The six `g8_*` pilots in this directory read grade 8 task
 * numbers off IM statements. Those numbers arrive as integers (7, 12),
 * decimals (2.5, 11.5, 0.00034), and fractions written as a numerator and a
 * denominator. Grade 8 answers turn on exact equality — whether two equations
 * have the same solution, whether a scientific-notation rewrite reconstructs
 * the numeral it came from, whether both observations sit on the fitted line —
 * so a decoded quantity is an SWI rational, never a float. Floats enter only
 * where a pilot reports a decimal approximation beside the exact value, and
 * they are labelled as approximations there.
 *
 * INPUT GENRE. Kind-tagged JSON strings, the wire genre the shared decoder in
 * `knowledge/strategies/automaton_input_contracts.pl` standardises on: values
 * arrive as strings and numbers, never as atoms. A quantity is one of
 *
 *     7                       an integer
 *     2.5                     a decimal numeral
 *     _{n: 3, d: 4}           a fraction, numerator over denominator
 *
 * QUARANTINE. Nothing outside `knowledge/strategies/abstraction/` imports this
 * module, and it renames nothing. The six g8 pilots import it rather than each
 * carrying its own copy of the same fifteen lines; that shared import is the
 * only coupling among them.
 */

:- module(g8_quantity_input,
          [ g8_quantity/2,               % +Value, -Rational
            g8_quantities/2,             % +Values, -Rationals
            g8_rational_text/2,          % +Rational, -Text
            g8_decimal_approximation/3,  % +Rational, +Places, -Float
            g8_integer_square_root/2,    % +NonNegativeInteger, -Root or fail
            g8_exact_root_text/2,        % +Rational, -Text
            g8_decimal_text/2            % +Rational, -Text
          ]).

:- use_module(library(dicts), []).

%!  g8_quantity(+Value, -Rational) is semidet.
%
%   Decode one wire value into an exact rational. Fails, rather than
%   throwing, on anything the contract does not admit; a pilot turns that
%   failure into a named refusal.
g8_quantity(Value, Rational) :-
    integer(Value), !,
    Rational = Value.
g8_quantity(Value, Rational) :-
    float(Value), !,
    Rational is rationalize(Value).
g8_quantity(Value, Rational) :-
    rational(Value), !,
    Rational = Value.
g8_quantity(Value, Rational) :-
    is_dict(Value), !,
    get_dict(n, Value, N0), get_dict(d, Value, D0),
    g8_quantity(N0, N), g8_quantity(D0, D),
    D =\= 0,
    Rational is N rdiv D.
g8_quantity(Value, Rational) :-
    string(Value), !,
    number_string(Number, Value),
    g8_quantity(Number, Rational).

g8_quantities([], []).
g8_quantities([V|Vs], [R|Rs]) :-
    g8_quantity(V, R),
    g8_quantities(Vs, Rs).

%!  g8_rational_text(+Rational, -Text) is det.
%
%   A reader-facing rendering: whole numbers as numerals, everything else as
%   numerator/denominator. No float appears, so nothing rounds silently.
g8_rational_text(R, Text) :-
    integer(R), !,
    format(string(Text), "~w", [R]).
g8_rational_text(R, Text) :-
    N is numerator(R), D is denominator(R),
    format(string(Text), "~w/~w", [N, D]).

%!  g8_decimal_approximation(+Rational, +Places, -Float) is det.
%
%   A rounded decimal to sit BESIDE an exact value, never to replace it.
g8_decimal_approximation(R, Places, Float) :-
    Scale is 10 ^ Places,
    Scaled is round(R * Scale),
    Float is Scaled / Scale.

%!  g8_integer_square_root(+N, -Root) is semidet.
%
%   Succeeds only when N is a perfect square, so a caller can tell an exact
%   whole-number side length from one that stays under a root sign.
g8_integer_square_root(N, Root) :-
    integer(N), N >= 0,
    Root is truncate(sqrt(N)),
    Root * Root =:= N.

%!  g8_exact_root_text(+Rational, -Text) is det.
%
%   Square root of a non-negative rational, written exactly: a numeral when
%   the root is rational, otherwise the radical itself.
g8_exact_root_text(R, Text) :-
    integer(R),
    g8_integer_square_root(R, Root), !,
    format(string(Text), "~w", [Root]).
g8_exact_root_text(R, Text) :-
    \+ integer(R),
    N is numerator(R), D is denominator(R),
    g8_integer_square_root(N, RN),
    g8_integer_square_root(D, RD), !,
    format(string(Text), "~w/~w", [RN, RD]).
g8_exact_root_text(R, Text) :-
    g8_rational_text(R, Inner),
    format(string(Text), "sqrt(~w)", [Inner]).

%!  g8_decimal_text(+Rational, -Text) is det.
%
%   An EXACT decimal rendering when the rational terminates in base ten —
%   that is, when its denominator has only 2s and 5s. Otherwise the
%   numerator/denominator form, because a repeating decimal cut short would
%   be a rounding no caller asked for. Scientific notation's coefficient is
%   conventionally written as a decimal, and every coefficient this pilot
%   derives from a written numeral terminates, so this renders it faithfully.
g8_decimal_text(R, Text) :-
    integer(R), !,
    format(string(Text), "~w", [R]).
g8_decimal_text(R, Text) :-
    D is denominator(R),
    strip_twos_and_fives(D, Remainder, Places),
    Remainder =:= 1, !,
    N is numerator(R),
    Scale is 10 ^ Places,
    Scaled is truncate(abs(N) * (Scale rdiv D)),
    Whole is Scaled // Scale,
    Fraction is Scaled mod Scale,
    format(atom(Padded), "~`0t~d~*|", [Fraction, Places]),
    ( N < 0 -> Sign = "-" ; Sign = "" ),
    format(string(Text), "~w~w.~w", [Sign, Whole, Padded]).
g8_decimal_text(R, Text) :-
    N is numerator(R), D is denominator(R),
    format(string(Text), "~w/~w", [N, D]).

% Divide out 2s and 5s, counting how many decimal places the larger of the
% two runs demands.
strip_twos_and_fives(D, Remainder, Places) :-
    strip_factor(D, 2, D1, Twos),
    strip_factor(D1, 5, Remainder, Fives),
    Places is max(Twos, Fives).

strip_factor(N, Factor, Result, Count) :-
    (   N mod Factor =:= 0
    ->  Next is N // Factor,
        strip_factor(Next, Factor, Result, Deeper),
        Count is Deeper + 1
    ;   Result = N, Count = 0
    ).
