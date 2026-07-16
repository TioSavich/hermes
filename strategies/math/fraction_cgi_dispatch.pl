/** <module> Fraction → CGI numerator-dispatcher bridge
 *
 * Routes same-denominator fraction-pair inputs to the CGI additive automata
 * (count_on_from_larger, make_ten_split_leftover, make_base_transfer,
 * base_ones_chunking, derived_fact_adjustment, known_fact_retrieval, etc.)
 * at the numerator level, with an explicit three-level units-coordination
 * annotation per Hackenberg-Norton (Stage 2/3 reorganization hypothesis).
 *
 * Conceptual note (important, easy to get wrong):
 *
 *   The base of arithmetic operation and the denominator of a fraction
 *   are two different things. "Fifths" (1/5) are still base-10 numerals —
 *   we just denote a fractional unit whose size is "the whole divided
 *   into five." In base 5, what we now call a "fifth" would not be a
 *   fraction at all; it would be a positional digit (0.1 in base 5), and
 *   what is "tenths" in base 10 would be called "handths" or some such.
 *
 *   So this dispatcher is NOT a "support for non-base-10 fractions"
 *   bridge. The operative base remains 10. The denominator D is the
 *   size of the fractional unit, which can be any positive integer.
 *   For ANY D, the CGI strategies on integer numerators apply at base
 *   10 — that is the structural-cost claim.
 *
 *   What's special about D = 10 (or powers of 10) is that the
 *   regrouping moves at the denominator boundary align with the
 *   operative base's regrouping moves. So 7/10 + 8/10 = 15/10 hits the
 *   make-ten move (numerator sum 7 + 8 = 15 crosses 10, the operative
 *   base) AND simultaneously crosses the denominator boundary —
 *   producing the visually-clean "1 and 5/10" outcome. For D = 5, the
 *   numerator sum 3 + 4 = 7 stays inside one base-10 decade, so the
 *   CGI move that fires is count_on (no make-ten needed); the
 *   denominator-boundary crossing 7/5 = 1 + 2/5 happens at a different
 *   structural level.
 *
 * Empirical motivation: the multi-base synthesis result verified across
 * whole-number bases {5, 7, 10, 12} concerns the operative base, not
 * the denominator. The current dispatch confirms that at base 10, CGI
 * strategies route through to numerator arithmetic for any same-D pair.
 * Whether each CGI Kind FIRES (vs. failing in a trigger condition)
 * depends on the specific numerator pair, not on D.
 *
 * Base configuration: the operative base is read from
 * `strategies/math/cgi_base.pl` (`current_cgi_base/1`, defaults to 10).
 * Changing it requires retracting and asserting; for production use
 * this is single-threaded.
 *
 * This module is plumbing. It introduces no new domain logic. It is
 * registered with `action_automata_registry.pl` as fraction Kinds of the
 * form `co_denominator_<cgi_kind>` (see fraction_action_pairs.pl).
 *
 * See:
 * - docs/prolog-connector-reports/2026-05-23-fraction-integration.md
 * - project_fraction_invariance_hypothesis memory entry
 */

:- module(fraction_cgi_dispatch,
          [ fraction_cgi_addition/5    % +Kind, +F1, +F2, -Outcome, -Annotation
          ]).

:- use_module(math(action_automata_registry), [run_action_automaton/6]).
:- use_module(math(cgi_base), [current_cgi_base/1]).


%!  fraction_cgi_addition(+Kind, +F1, +F2, -Outcome, -Annotation) is semidet.
%
%   Dispatch same-denominator fraction addition to a CGI additive automaton
%   at the numerator level. Fails (does not error) when denominators differ
%   — non-same-denominator fraction addition requires co-measurement, which
%   lives in `divaded_fractional_units`, not in the CGI strategies.
%
%   The operative base is read from `current_cgi_base/1` (default 10) and
%   is used purely for the annotation. The CGI Kind itself reads the same
%   configuration upstream.
%
%   @arg Kind       A CGI addition automaton kind name, e.g.,
%                   `count_on_from_larger`, `make_ten_split_leftover`,
%                   `make_base_transfer`, `base_ones_chunking`.
%   @arg F1, F2     `fraction(N, D)` terms with matching denominators and
%                   non-negative integer numerators.
%   @arg Outcome    The CGI automaton's `action_outcome/2` term, unchanged.
%                   Read its `result/1` field to recover the numerator-sum.
%   @arg Annotation A `three_level_units_coordination/4` term carrying the
%                   operative base, unit fraction, referent whole, and
%                   iteration commitment per Hackenberg-Norton.
fraction_cgi_addition(Kind, fraction(A, D), fraction(B, D), Outcome, Annotation) :-
    integer(A), integer(B), integer(D),
    A >= 0, B >= 0, D > 0,
    current_cgi_base(Base),
    run_action_automaton(addition, Kind, A, B, Outcome, _Trace),
    Annotation = three_level_units_coordination(
                     operative_base(Base),
                     unit_fraction(fraction(1, D)),
                     referent_whole(fraction(D, D)),
                     iteration_count_at_unit(addition_of(A, B))).
