# MCP sweep, funneled: 150 probed calls across three slices

Three parallel sweeps exercised the hermes MCP surface on 2026-07-23
(raw rows and per-slice summaries in the gitignored
`scripts/research/talkmoves_rerun_out/mcp_sweep/`; 41 + 65 + 44 = 150
JSONL rows). This document is the controller's synthesis: what the
surface genuinely does, what fails, and the repair order.

## Capabilities confirmed

- The tools compose into analysis without outside interpretation:
  slice B chained an adjudicated comparison claim, commitment_match
  over an utterance, per-speaker deontic boards, and a runnable
  strategy trace — each step a tool result, none a model's opinion.
- The full checker grammar is live over dispatch (registry mode):
  holds, refuted, not_covered, and malformed inputs all answer
  correctly, including the recently guarded edges.
- Offline retrieval works at usable latency (~1.0-1.5 s for row search
  and stored-vector neighbors over 2,056 rows).
- Robustness after the slice-C patches: absent embedding artifacts or
  a missing generated registry now produce structured errors naming
  the artifact and its exact rebuild command; a crashed worker is
  retired immediately and the next call gets a fresh one. The
  operating worry that motivated the robustness slice — required
  offline data quietly wrecking the experience — is addressed at the
  error-message layer; shipping the artifacts with the checkout
  remains the actual guarantee (they are tracked files today).

## Defects, funneled and ranked

1. Kindergarten monitoring charts time out (25 s; lesson-sensitive,
   consistent with the ~10 s live field_context cost slice C
   measured). The Big Red cache rebuild in flight serves exactly this;
   after it lands, re-probe GK lessons before calling this closed.
2. Core and registry modes disagree about check_math_claim: core still
   describes and accepts only fraction equivalence while registry
   accepts the full grammar. One surface must be true: point the core
   tool at the dispatch op.
3. Unpaginated payloads: misconception_lookup(domain=fraction) returns
   157 KB; registry inventories reach 267 KB. Add limit/offset
   arguments and a default cap with an honest truncation notice.
4. Registry parameter metadata remains name-only for the long tail
   (task 95 enriched the core ops). Wrong-typed input can route to
   not_covered instead of malformed. Extend the enrichment beyond the
   seeded ops; wrong-type must fail as malformed everywhere.
5. Detail-pointer drift: the documented deformation detail id
   ($.cells[0].productive) is stale for a covered lesson; the served
   inventory names $.productive_scene. Detail pointers must be
   generated from the same payload they point into.
6. Vocabulary lexicons are unpublished: shape_property wants
   four_right_angles and rejects right_angles; the accepted property
   and shape lexicons belong in the tool description (they are finite
   and known).
7. Suggestion relevance: near-miss strategy names get good
   suggestions; unrelated names get long weak lists. Cap suggestions
   by distance threshold.
8. The deontic bridge is semantically thin in practice: matched terms
   are accepted but yielded no consequences or up-levels in probes.
   Whether the corpus lacks rules for those pairings or the terms need
   a different form is undiagnosed — a real investigation, not a copy
   fix.

## Repair order (proposed)

(1) core/registry grammar unification and (3) pagination are small and
high-traffic. (5) and (6) are generation fixes in the server. (4) is
the standing registry-enrichment slice. (1-GK) waits on the cache then
re-probes. (8) is its own diagnostic task on the deontic corpus. (7)
is a one-line threshold.
