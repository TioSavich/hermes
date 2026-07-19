# tools/carving

Carving takes a bounded table of arithmetic facts and derives each one into
symbolic proofs built from primitive actions. Every distinct proof body is a
named strategy; facts that resist derivation are the structural residue. The read
is Brandomian: the proof head is a commitment, its body the entitlement. The
machines are base-parametric (checked at base 10 and base 5).

## What it holds

- `query.pl` (`carving_query`) — the production-facing entry: `carving_strategy_proof/5`,
  `carving_operation_summary/2`, `carving_strategy_path/7`, and the min-cost
  predicates.
- `synthesizer.pl` — the engine that searches for a primitive-action derivation
  per fact and replaces the bare fact with proof clauses.
- `primitives.pl` — proof rules for correct facts, one rule per strategy.
- `rationalizations.pl` — proof rules for incorrect facts (coherent-but-flawed
  procedures), active only when the config sets `rationalize`.
- `strategy_machine.pl`, `groups_machine.pl`, `units_machine.pl` — the add/subtract,
  multiply/divide, and fraction rungs, unified by the units machine reading
  counting through fractions as one search.

## Consumers and boundary

`hermes_worker.pl`, `strategies/expressive_power.pl`, `hermes/dispatch_spec.pl`,
and `hermes/capability_registry.pl` call `carving_query`. The two sibling files
`tools/axiom_pack_audit.pl` and `tools/axiom_toggle.pl` audit and toggle axiom
packs. The config bounds here are small, sized for loader-level smoke tests;
larger sweeps live in the source project (`run.pl` and the Big Red iterations),
which `exploratory_carving_artifact/2` names to keep the boundary queryable.
