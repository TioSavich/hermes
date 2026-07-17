/** <module> PML + Arche-Trace Loader
 *
 *  This script loads all components of the Polarized Modal Logic (PML) Core Framework
 *  and the arche-trace modules in the correct order.
 *
 *  Requires paths.pl to have been loaded first so that file_search_path aliases
 *  (pml, arche_trace, strategies, formalization) are available.
 */

% Suppress singleton variable warnings, often common in DSL definitions.
:- style_check(-singleton).

% Ensure file_search_path aliases are available
:- ensure_loaded('../paths').

% =================================================================
% Load Order
% =================================================================

% 1. Utilities and Core Vocabulary (pml/ module)
:- use_module(pml(utils)).
:- use_module(pml(pml_operators)).

% 2. Core Prover (arche-trace/ — must be loaded before axioms that extend it)
:- use_module(sequent_engine).

% 3. Semantic Foundations (pml/ — axioms extending the prover)
:- use_module(pml(semantic_axioms)).

% 4. Pragmatic Foundations
% Automata must be loaded before Pragmatic Axioms that use them (e.g., Trace).
:- use_module(automata).
:- use_module(pml(pragmatic_axioms)).
:- use_module(pml(intersubjective_praxis)).

% 5. Embodied Prover (arche-trace/ — resource-tracked proves/4, separate module
% from scene-agnostic engine to avoid name collision). Selective import of
% proves/4 only; incoherent/1 stays with the scene-agnostic engine in user
% namespace. Tests that need other embodied prover predicates call them
% via module qualification (embodied_prover:<pred>).
:- use_module(embodied_prover, [proves/4]).

% 6. The Dialectical Engine and Critique (arche-trace/ — same dir)
:- use_module(critique).
:- use_module(dialectical_engine).

% 7. Brandomian material-incompatibility relation and classical backstop.
% These remain opt-in for consumers that load sequent_engine.pl directly, but
% load.pl is the documented full arche-trace stack entry point.
:- use_module(brandomian_incompatibility).
:- use_module(sequent_brandom_bridge).
