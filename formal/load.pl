/** <module> Formal reasoning stack loader
 *
 *  This script loads the Polarized Modal Logic components and the sequent,
 *  incompatibility, and dialectic modules in dependency order.
 *
 *  Requires paths.pl to have been loaded first so that file_search_path aliases
 *  (pml, sequent, incompat, dialectic, strategies, formalization) are available.
 */

% Suppress singleton variable warnings, often common in DSL definitions.
:- style_check(-singleton).

% Ensure file_search_path aliases are available
:- ensure_loaded('../paths').

% =================================================================
% Load Order
% =================================================================

% 1. Utilities and Core Vocabulary (formal/pml/ module)
:- use_module(pml(utils)).
:- use_module(pml(pml_operators)).

% 2. Core Prover (must be loaded before axioms that extend it)
:- use_module(sequent(sequent_engine)).

% 3. Semantic Foundations (formal/pml/ — axioms extending the prover)
:- use_module(pml(semantic_axioms)).

% 4. Pragmatic Foundations
% Automata must be loaded before Pragmatic Axioms that use them (e.g., Trace).
:- use_module(sequent(automata)).
:- use_module(pml(pragmatic_axioms)).
:- use_module(pml(intersubjective_praxis)).

% 5. Embodied Prover (resource-tracked proves/4, separate module
% from scene-agnostic engine to avoid name collision). Selective import of
% proves/4 only; incoherent/1 stays with the scene-agnostic engine in user
% namespace. Tests that need other embodied prover predicates call them
% via module qualification (embodied_prover:<pred>).
:- use_module(sequent(embodied_prover), [proves/4]).

% 6. The Dialectical Engine and Critique
:- use_module(dialectic(critique)).
:- use_module(dialectic(dialectical_engine)).

% 7. Brandomian material-incompatibility relation and classical backstop.
% These remain opt-in for consumers that load sequent_engine.pl directly, but
% formal/load.pl is the documented whole-stack entry point.
:- use_module(incompat(brandomian_incompatibility)).
:- use_module(incompat(sequent_brandom_bridge)).
