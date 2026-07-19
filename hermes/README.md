# hermes

The application face of the knowledge base: the local Python server (`app/`) and
the Prolog glue that shapes the KB into console answers. The worker itself,
`hermes_worker.pl`, sits at the repository root; the app loads it live rather than
copying it.

## The dispatch table

`dispatch_spec.pl` is an authored specification, not code paths. It carries 139
`dispatch_spec/4` rows (each names an operation, its typed inputs, the call to
run, and the empty-result witness) and 216 `dispatch_message/3` rows (the
malformed-input and no-result messages). One generic dispatcher, `dispatch_request/4`
in `hermes_worker.pl`, reads the spec and runs the call. `validate_dispatch_spec/0`
checks at load that every named converter exists, so a typo fails loudly rather
than surfacing as a permanent malformed reply.

## The other glue

- `capability_registry.pl` — generated (`capability/5`, `capability_route/3`,
  `capability_page/2`); regenerate with `scripts/extract_capability_registry.py`.
- `encyclopedia.pl` — the JSON-safe aggregation layer for the console.
- `commitment_matcher.pl` — reads content into canonical terms.
- `math_context.pl`, `math_claim_checker.pl` — the knowledge-spine context
  resolver and the PML-to-math claim bridge.
- `pair_scoring.pl`, `event_scoring.pl` — the scoring surfaces.
- `app/` — the server. See `app/README.md`.

## Boundary

The spec table handles the mechanical and witness operations; the 26 render
operations and 29 irregular operations stay bespoke in the worker by design, and
spec-backed operations commit before that catch-all.
