# Literature corpus — metadata only

The converted research corpus (2,183 articles across 12 journals, plus
three books) is NOT distributed in this repository. The source PDFs and
their converted markdown are rights-restricted; the owner does not hold
redistribution rights, so the full texts live only in local working
copies and on the private cluster storage.

What this directory carries:

- `corpus_index.jsonl` — one record per converted document: bibliography
  key and match confidence, journal, page counts, document-element
  counts, and the relative paths a local corpus copy resolves.
- `corpus_failures.jsonl` — the eight conversion failures, with reasons.
- `corpus_manifest.json` — the deterministic merge manifest
  (sha-stamped; identical checkpoints produce identical bytes).

To rebuild or obtain the corpus locally: the conversion pipeline is
`scripts/research/literature_intake.py` and
`scripts/bigred/literature_docling/` (see its README). Given the source
PDFs, the pipeline reproduces the corpus deterministically; the index
here tells you exactly what it produces.
