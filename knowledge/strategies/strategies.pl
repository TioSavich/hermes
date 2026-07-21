/** <module> Signpost to the deployed strategy dispatch surface
 *
 * This module is a signpost, not the dispatcher. The deployed dispatch
 * surface for arithmetic action automata is
 * knowledge/strategies/math/action_automata_registry.pl, which exports
 * run_action_automaton/6 across the addition, subtraction,
 * multiplication, division, fraction, decimal, integer, ratio,
 * diagnostic, calculus, algebraic, and probability families. That
 * predicate is re-exported here so that loading strategies(strategies)
 * routes to the real dispatcher instead of ending at documentation.
 *
 * knowledge/strategies/hermeneutic_calculator.pl is the v2 legacy router: its
 * calculate/6 dispatches on a fixed set of hardcoded display names and
 * has not been extended to the registry's coverage. Prefer
 * run_action_automaton/6 for new work.
 *
 * Individual FSM strategy modules (sar_add_chunking, smr_div_ucr, and
 * their siblings under knowledge/strategies/math/) remain loadable directly with
 * module-qualified calls when a caller needs a single machine rather
 * than the dispatch surface.
 */

:- module(strategies, []).

:- reexport(math(action_automata_registry), [run_action_automaton/6]).
