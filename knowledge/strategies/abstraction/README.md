# abstraction

Candidate structure over the automata corpus, from the regularization
conversation of 2026-08-03
(`docs/research/2026-08-03-automata-abstraction-conversation.txt`).
Every module here is quarantined in the same sense as
`action_vocabulary_map.pl`: nothing imports it, it renames nothing, and
its rows are authored and vetoable one by one. These are pilots of a
possible reorganization, not the reorganization.

## What it holds

- `addition_action_signatures.pl` — types the 59 addition-family action
  atoms (operational step / invariant ledger / verdict), folds the 18
  transition tables into 6 machines with genuine branch points, and
  checks agreement between two validity encodings authored from the
  same reading. Check: `check_pilot/0`.
- `kernel_gate_pilot.pl` — runs three cross-domain kernels
  (complete_to_unit, iterate_to_target, partition/regroup) under genre
  gates; correct and incorrect doings are instances or single local
  mutations of the same kernel run, with execution-grounded validity and
  mutation tests against over-acceptance. Check: `check_kernel_pilot/0`.
- `refusal_genesis_sketch.pl` — loads the kernel pilot and adds three
  rows of structure: gate mutations have antecedent licenses, gate
  refusals repaired institutionally are new number systems, and the
  ladder ends where the repo already marks incommensurability. Check:
  `check_refusal_genesis/0`.
- `channel_collapse.pl` — a third reading beside productive and
  deformed, for errors with no formal antecedent (two task tokens
  collapsed in a child's articulation channel), with a discrimination
  test that separates channel errors from license errors by their
  distribution. Check: `check_channel_collapse/0`.

## How to run the checks

From the repo root:

    swipl -q -l paths.pl -l knowledge/strategies/abstraction/<file> \
          -g <module>:<check> -t halt

## What came out of the same morning

The audit machinery this line produced is live, not quarantined:
`scripts/checks/audit_purported_validity.pl`,
`scripts/checks/sweep_coincidence.pl`,
`scripts/checks/scan_self_certifying.py`, with generated data in
`knowledge/strategies/deformation_coincidence.pl`. Findings and the
work queue: `docs/research/2026-08-03-purported-validity-audit.md` and
`docs/research/2026-08-03-contract-coverage-todo.md`.
