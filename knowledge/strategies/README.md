# strategies

Children's arithmetic strategies encoded as action automata, plus the machinery
that runs them and draws them.

## What it holds

- `hermeneutic_calculator.pl` — the strategy dispatcher.
- `fsm_engine.pl` — the finite-state-machine engine that steps an action-pair
  automaton.
- `composition_engine.pl`, `normalization.pl` — grounded fractional arithmetic
  (composition and normal forms over the grounded number representation).
- `inferential_strength.pl` — finite measures of a vocabulary's inferential reach.
- `math_benchmark.pl` — a reasoning benchmark over the registry.
- `strategies.pl` — a signpost to the deployed dispatch surface.
- `math/` — the automata registry and the per-operation action-pair modules.
  See `math/README.md`.
- `render/` — scene compilers that emit render-contract documents. See
  `render/README.md`.
- `meta/` — introspection over the automata (analyzer, pattern detectors,
  fact/json writers).

## How it loads

After `paths.pl` sets the `strategies` alias, consumers
`use_module(strategies(math/action_automata_registry))` for execution and
`use_module(strategies(render/<scene>))` for drawing.

## What consumes it

`hermes_worker.pl` runs strategy traces and render operations; `formal/learner/`,
`curriculum/im/`, and `hermes/` modules query the registry and render surfaces.

## Boundary

The automata run attested strategies from the CGI and constructivist literature
on representative operands within a bounded working base. They encode named
strategies; they are not a general solver.
