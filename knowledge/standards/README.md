# standards

Content standards anchored to concepts. Three frameworks share one shape:
`standard_anchor(ConceptId, Framework, Code, Statement)`, paired with a `tier/4`
provenance fact. The framework atoms are `ccss`, `in_indiana`, and `im_lesson`.

## What it holds

- `ccss/geometry.pl` — CCSS K–8.G, Tier-1 verbatim, retrieved via the Learning
  Commons Knowledge Graph (jurisdiction California, which adopts CCSS verbatim
  for K–8.G).
- `indiana/geometry.pl` — Indiana Academic Standards for Mathematics geometry
  anchors (2014/2020 revision). The neighboring `standard_*.pl` files are
  executable strategy modules, not rows of the shared anchor schema.
- `im/standards_im.pl` — the grades K–4 anchor table, ordered by ascending grade
  with rows retained in their original order.
- `im/grade_5.pl` through `im/grade_8.pl` — anchor tables with source-local
  witness predicates that depend on their current filenames.
- `im/lesson_anchors.pl` — an auto-generated geometry-concept and lesson-anchor
  table. Its hand-authored loader section loads the consolidated and held IM
  tables.

## Consumers and boundary

`hermes_worker.pl`, `knowledge/strategies/math/action_automata_registry.pl`, and the
`base_ten` and `area_model` render scenes load the standard modules. CCSS and
Indiana cite the official published text as authority and the Learning Commons
Knowledge Graph as retrieval source; the IM lesson ids derive from Illustrative
Mathematics (`NOTICE.md`). A witness proves membership in the loaded, closed
table; it is not a general standards-alignment model for open-ended curricula.
The IM stub concepts are flagged `developmental`, an honest coarse bucket with no
canonicalization synthesizer wired.
