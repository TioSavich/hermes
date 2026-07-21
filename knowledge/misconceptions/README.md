# misconceptions

A registry of attested student misconceptions compiled from the research
literature. Each entry is a coherent-but-flawed rule that runs, together with its
provenance: the operation it targets, the source that attests it, the commitment
it makes, and the entitlement it lacks.

## The registry

`misconception_registry.pl` exposes `misconception_registry_entry/5`
(name, target operation, citation, commitment made, entitlement lacked) plus
witnesses. The entry predicate is a small set of rules that assemble entries from
the underlying data: about 1920 `test_harness:arith_misconception/6` facts, each
an attested deformation paired with the rule predicate that runs it.

## The batch files

`misconceptions_<domain>_batch_N.pl` carry the per-domain corpus of
`arith_misconception/6` facts. The non-batch domain files
(`misconceptions_whole_number.pl`, `misconceptions_decimal.pl`,
`misconceptions_extended_arithmetic.pl`, and the rest) are thin loaders that
re-export the batches; a few add hand-written ASKTM-linked facts.

## Literature layer

`literature_canonical_mappings.pl`, `literature_incompatibility_facts.pl`,
`literature_student_rule_map.pl`, and `literature_vocabulary.pl` are generated
from the source-project research corpus. `benny.pl` carries Benny's rule
deformations (Erlwanger 1973); `pml_wire.pl`, `generative_misconceptions.pl`, and
`misconception_scorekeeping.pl` wire the registry to the modal and deontic layers.
Named sources in the code include Erlwanger 1973, Byers & Erlwanger 1984, Leatham
2014, and Resnick.

## Consumers and boundary

`hermes_worker.pl`, the `formal/incompatibility` modules, `knowledge/strategies/`
(expressive power, render coverage), `curriculum/im/`, `hermes/` scoring, and
`knowledge/crosswalk/families/cw_driver.pl` load the registry. An entry is an attested move
with a source, not merely a generated deformation; the generated literature facts
come from a source-project database and are not hand-edited here.
