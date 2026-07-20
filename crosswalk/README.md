# crosswalk

One canonical vocabulary over the scattered functors the rest of the knowledge
base defines. A canonical term names a concept once; the crosswalk records which
legacy predicate in which module answers for it, and holds the witness that
proves the concept in context.

## What it holds

- `canonical_all.pl` — the loader. Auto-generated from each module's real export
  list; re-exports every `*_unified`/registry query and exposes the family
  contract: `contract/3`, `legal_term/1`, `legacy_term/2`, `crosswalk_family/1`,
  `crosswalk_family_count/1`, `validate_crosswalk_families/0`.
- `canonical_vocabulary.pl` — the incompatibility layer (`incompatible/3`,
  `incoherent/2`) over the sequent engine, defeasible inference, and the deontic
  scorekeeper.
- `merge_evidence.pl` — the citation gate. Every `canonical_concept/2` assertion
  needs a companion evidence fact; `merge_gate_baseline.txt` lists the facts
  grandfathered before the gate.
- `representation_spine.pl` — crosswalks coded student-work assets, reading
  `representation/asset_manifest.json`.
- `families/` — the 38 crosswalk families. See `families/README.md`.

## How it loads

`use_module(crosswalk(canonical_all))` after `paths.pl` sets the `crosswalk`
alias. `validate_crosswalk_families/0` confirms the family count and contract at
load.

## What consumes it

`hermes_worker.pl` queries the `*_unified` and `*_witness` predicates through the
worker; `hermes/dispatch_spec.pl` routes witness operations to
`cw_driver:family_witness`.

## Boundary

The crosswalk records where a canonical term is answered; it does not own the
underlying facts, which live in `strategies/`, `arche-trace/`, `formal/formalization/`,
`misconceptions/`, and `formal/learner/`. A witness proves membership in a loaded,
closed-world table, not general alignment over open-ended curricula.
