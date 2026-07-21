/** <module> Single source of truth for the operative base of CGI strategies
 *
 * The CGI strategy catalog (count_on, make_ten, base_ones_chunking, etc.)
 * is described in the research literature for base-10 schools. The
 * synthesis result on bases {5, 7, 10, 12} shows that the structural-cost
 * naturality argument is base-agnostic: under a structurally defined cost,
 * the same canonical strategy shapes emerge under any base. This module
 * lifts the operative base from a literal scattered across ~30 sites to
 * a single configuration point so that:
 *
 *   - base 10 (the default) remains the production behavior
 *   - research that wants to study CGI-shaped strategies at base 12 or
 *     base 5 can do so by retracting and re-asserting one fact, without
 *     touching the strategy automata
 *   - the fraction-CGI dispatcher and the synthesis primitives can share
 *     a common notion of "the operative base"
 *
 * Important conceptual distinction: the operative base is NOT the
 * denominator of a fraction. Fractions in base 10 (like 3/5, where the
 * "5" is just a denominator) operate at base 10. In a hypothetical
 * base-5 number system, fractions and decimals would be represented
 * differently — what we call "tenths" would be called something else and
 * "fifths" would not be a fraction at all. See fraction_cgi_dispatch.pl
 * for the full discussion.
 *
 * Usage:
 *
 *   :- use_module(math(cgi_base), [current_cgi_base/1]).
 *   ...
 *   current_cgi_base(Base),
 *   next_base_target(Larger, Base, TargetBase),
 *   ...
 *
 * To change the operative base (single-threaded, for research):
 *
 *   :- use_module(math(cgi_base)).
 *   set_cgi_base(12).
 *   ...run strategy tests at base 12...
 *   reset_cgi_base.
 */

:- module(cgi_base,
          [ current_cgi_base/1,
            set_cgi_base/1,
            reset_cgi_base/0
          ]).

:- dynamic(cgi_base_fact/1).

cgi_base_fact(10).


%!  current_cgi_base(?Base) is det.
%
%   The currently configured operative base for CGI strategies. Defaults
%   to 10. Read this rather than writing literal 10 in any strategy file.
current_cgi_base(Base) :-
    cgi_base_fact(Base),
    !.
current_cgi_base(10).  % defensive default if dynamic fact is somehow missing


%!  set_cgi_base(+Base) is det.
%
%   Override the operative base. Intended for research — for example,
%   probing how the CGI strategy automata behave when reconfigured for
%   base 12. NOT thread-safe; single-threaded use only.
set_cgi_base(Base) :-
    integer(Base), Base >= 2,
    retractall(cgi_base_fact(_)),
    assertz(cgi_base_fact(Base)).


%!  reset_cgi_base is det.
%
%   Restore the default operative base of 10.
reset_cgi_base :-
    set_cgi_base(10).
