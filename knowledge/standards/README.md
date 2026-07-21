# standards

Content standards anchored to concepts. Three frameworks share one shape:
`standard_anchor(ConceptId, Framework, Code, Statement)`, paired with a `tier/4`
provenance fact. The framework atoms are `ccss`, `in_indiana`, and `im_lesson`.

## What it holds

- `ccss/geometry.pl` — CCSS K–8.G, Tier-1 verbatim, retrieved via the Learning
  Commons Knowledge Graph (jurisdiction California, which adopts CCSS verbatim
  for K–8.G).
- `indiana/` — `geometry.pl` plus 20 `standard_*.pl` modules holding the Indiana
  Academic Standards for Mathematics (2014/2020 revision).
- `im/` — `lesson_anchors.pl` (auto-generated) and `grade_k.pl` through
  `grade_8.pl`, anchoring Illustrative Mathematics lesson ids; each lesson row
  carries both a `ccss` and an `in_indiana` anchor.

## Consumers and boundary

`hermes_worker.pl`, `knowledge/strategies/math/action_automata_registry.pl`, and the
`base_ten` and `area_model` render scenes load the standard modules. CCSS and
Indiana cite the official published text as authority and the Learning Commons
Knowledge Graph as retrieval source; the IM lesson ids derive from Illustrative
Mathematics (`NOTICE.md`). A witness proves membership in the loaded, closed
table; it is not a general standards-alignment model for open-ended curricula.
The IM stub concepts are flagged `developmental`, an honest coarse bucket with no
canonicalization synthesizer wired.
