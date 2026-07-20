/** <module> Modal-context inference costs (consolidation)
 *
 * Shared cost facts for modal contexts (compressive / expansive / neutral).
 * Previously redefined locally with identical bodies in
 * formal/learner/meta_interpreter.pl and `arche-trace/embodied_prover.pl`.
 * Predicate carving (formal/tools/carving/predicate_carving.py) identified the
 * redundancy.
 *
 * The compressive context is more taxing (2 inferences per step) than
 * the expansive or neutral context (1 each). These costs feed both the
 * meta-interpreter's solve/4 step accounting and the embodied prover's
 * proof construction.
 */

:- module(modal_costs,
          [ get_inference_cost/2
          ]).

%!  get_inference_cost(+ModalContext, -Cost) is det.
%
%   Cost in inferences for a step taken in the given modal context.
get_inference_cost(compressive, 2). % Compressive state (↓) is more taxing.
get_inference_cost(expansive, 1).   % Expansive state (↑) is less taxing.
get_inference_cost(neutral, 1).
