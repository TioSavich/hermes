# Receipts pass 6 — the 71-lesson pool, drafted and reviewed

Date: 2026-07-29. Pool: the 71 lessons missing only `structured_negative`
(47 with K-5 teacher guides, 24 grade 6-7 digest-sourced; all 71 carried
registry candidates, none carried a receipt). Drafter:
`scripts/research/generate_negative_receipts.py` (gemma-4-31B-it via
REALLMS), fresh output dir `negative_receipts_out/pass6`, all 71
completed. **32 proposals, 31 accepted by the v3 source gate, 40 refused**
— the refusals abstain by name, quoting the guide line that disqualifies
the candidate. Two were transport/JSON failures, not judgments.

## Review

Two independent opus reviewers, halves by index, the six-pattern rejection
taxonomy in-prompt, every named pair EXECUTED on the lesson's own
quantities through `run_action_automaton/6`. Decisions JSON preserved in
the session scratchpad and reproduced in the tables the reviewers wrote.

| half | accept | revise | reject |
|---|---:|---:|---:|
| A (0-15, all file-backed) | 8 | 5 | 3 |
| B (16-30; 7 file-backed, 8 digest) | 2 | 3 | 10 |
| combined | 10 | 8 | 13 |

By provenance: file-backed 10 accept / 8 revise / 5 reject of 23 (78%
salvageable); digest-backed 0 / 1 / 7 of 8. The 89%-vs-39% split holds.

Registry execution was again the decisive discipline. Guards invisible to
prose review did the rejecting: `share_into_divisor_groups` requires a
nonzero remainder, so it cannot deform an exact division; the
multiplication/division families are unsigned and integer-only (signed
velocity, decimal money, and unit-fraction items all raise type errors);
`context_free_fact_family_guess` needs a second factor pair with the same
product, which 3×3=9 does not have. One deformation was caught running
vacuously: `make_ten_drop_leftover` on single-digit addends returns the
correct sum while reporting `validity(incorrect)`.

## Controller rulings

- Index 28 rejected: its only viable revision needs mixed-number side
  lengths the docling conversion dropped; nothing citable remains.
- Index 24 stays rejected: the digest records `multiply(15, 5)` but no
  gain/loss characterization; the repeated-gain reading is an inference
  the record does not carry, and no grade-7 guide exists to confirm it.
- Index 18's revision was blocked by the receipt schema itself:
  `vision_lesson_computation` is not in the fact allowlist, though the
  fact exists verbatim and its pair separates 200 from 10. Recorded as an
  allowlist decision to revisit, not a defect in the receipt.

## Merge

16 receipts (10 accepts byte-identical, 6 revisions verified fragment-by-
fragment at their physical lines, every numeric claim re-probed live)
merged into `scripts/curriculum/lesson_negative_receipts.json` (147 →
163). `_validated_negative_receipts` admitted all 16. Ledger rebuilt:
**diagnostic_ready 294 → 310, structured_negative 448 → 464.**

## Standing findings for the next pass

1. `vision_lesson_boundary` should leave the drafting allowlist: its
   content is by construction the pipeline's own mapping narrative, and it
   produced this pass's bookkeeping-as-curriculum reject while a clean
   `vision_lesson_goal` for the same lesson carried the needed quantity.
2. Unit-fraction measurement division has no runnable counterpossibility:
   the division pair is integer-only and remainder-gated, and
   `fraction/measurement_division` has no deformation entry. Two receipts
   that read their lessons correctly were blocked by this vocabulary gap;
   it recurs across grade 5 unit 3.
3. Divisor-as-groups on an exact quotient wants the
   `fair_share_equal_groups` / `name_group_count_as_share_size` pair, not
   `measure_groups_of_size` / `share_into_divisor_groups` — drafting
   prompt guidance, not a gate rule.
4. An `add_instead_of_multiply` receipt needs both factors present in the
   quoted text or it collapses into "multiplication is not addition" —
   likewise prompt guidance.
