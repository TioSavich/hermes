# Formal reasoning modules

`formal/load.pl` is the whole-stack entry point after `paths.pl` establishes
module aliases. It loads the PML vocabulary, the sequent core, semantic and
pragmatic axioms, the embodied prover, the dialectic modules, and the material
incompatibility relation in dependency order. Consumers that need a narrower
surface load modules through the `formalization`, `pml`, `sequent`, `incompat`,
`dialectic`, `juncture`, `learner`, `tools`, or `carving` aliases.

## `formalization/`

The formalization subtree contains grounded arithmetic, geometry and number
theory axioms, modal costs, witness construction, and synthesis experiments.
Its modules supply mathematical relations used by the prover and by runtime
witnesses; the synthesis directory remains a bounded research surface rather
than part of every application request.

## `pml/`

The PML subtree encodes semantic and pragmatic relations for interactional
traces, discourse features, gesture and media alignment, and MUA audits. Its
semantic and pragmatic axioms extend the sequent vocabulary. The framework
makes those relations queryable within the predicates and data present here;
it does not settle open-ended interpretations of discourse.

## `sequent/`

The sequent subtree contains the classical calculus, the resource-tracked
embodied prover, and supporting automata. `sequent_engine.pl` reasons over
`neg/1` pairs and deliberately does not treat material incompatibility as
classical negation. `automata.pl` carries the attributed-variable
vanishing-point mark, while `embodied_prover.pl` records hollow proof nodes
whose warrant has been withdrawn.

## `incompatibility/`

The incompatibility subtree records Brandomian material incompatibility,
defeasible inference, the opt-in sequent bridge, and bounded discovery over a
finite registry. Nothing follows merely from incoherence in the material
relation. `incompatibility_sets_discovered.pl` is the Big Red discovery cache;
its provenance header and regeneration instructions remain authoritative, and
`find_emergent_hyperedges.pl` queries the tracked sources without claiming
complete entailment over an open language.

## `dialectic/`

The dialectic subtree contains the critique and accommodation cycle used by
the bounded dialectical engine. It detects resource exhaustion, incoherence,
and bad-infinite cycles, then applies the accommodations encoded in the
module. These predicates model a specific computational cycle and do not make
a general claim about dialectical reasoning.

## `juncture/`

The juncture subtree contains `differance_juncture.pl`, a small structural
model used by the Theory pages. It makes the declared derivations, licenses,
and effaced paths queryable. It does not implement differance or extend the
runtime proof relation beyond those predicates.

## `learner/`

The learner subtree contains commitment scorekeeping, reorganization,
curriculum processing, learner-state transitions, and teacher-facing
adapters. The scorekeeper can ask the sequent core through
`proves_via_sequent_core/1`, but ordinary scorekeeping remains separate from
proof search. Server entry points bind ports and are loaded only by their
launch paths.

## `tools/`

The tools subtree contains axiom audits, toggles, and the carving machines.
The audit and toggle modules load the whole formal stack when their operations
require it; the carving modules expose narrower construction and query
surfaces. They report behavior of the loaded finite knowledge base rather than
certifying completeness.
