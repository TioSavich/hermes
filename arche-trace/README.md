# arche-trace

Classical sequent reasoning and Brandomian material incompatibility, and the
symbolic place where the arche-trace, différance, and erasure structure is made
queryable.

## How it loads

`load.pl` is the entry point, after `paths.pl` sets the aliases. It loads, in
order: `pml(utils)` and `pml(pml_operators)`; `sequent_engine`; the semantic and
pragmatic axioms and `intersubjective_praxis`; `automata`; `embodied_prover`
(importing `proves/4` only); `critique` and `dialectical_engine`; then
`brandomian_incompatibility` and `sequent_brandom_bridge`. Other consumers load
individual modules directly.

## Key files

- `sequent_engine.pl` — classical sequent calculus over `neg/1` pairs. It states
  plainly that it does not carry Brandomian incompatibility semantics.
- `brandomian_incompatibility.pl` — material incompatibility with no explosion
  rule; nothing follows from incoherence here, and that absence is the point.
- `embodied_prover.pl` — a resource-tracked prover carrying the erasure mechanism.
- `incompatibility_sets.pl`, `incompatibility_discovery.pl` — the closed-world
  finite case; discovery proposes, the relational engine records.
- `differance_juncture.pl` — encodes and makes queryable a structural fact; it
  does not implement différance. It is wired only to web pages.
- `data/incompatibility_sets_discovered.pl` — a generated discovery cache (do not
  hand-edit); `tools/find_emergent_hyperedges.pl` searches the real data.

## Consumers and boundary

`hermes_worker.pl`, `learner/`, the `crosswalk` families, the `pml` axioms, and
`misconceptions/literature_deontic_bridge.pl` load these modules;
`tools/axiom_toggle.pl` and `tools/axiom_pack_audit.pl` load the full stack.
Full incompatibility entailment is not computable over an open language; this
computes the closed-world finite case. The Derridean structure is encoded and
made queryable, not implemented.
