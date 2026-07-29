# Grade-8 vision-harvest excerpt check

The Opus-verified G6–7 control does **not** calibrate this check: 568 of 2,273
joined quoted rows pass after whitespace collapse (24.99%; 5 rows are
unjoinable). This is well below the predeclared 90% threshold. Consequently,
the broad-harvest results below are measurements of exact-ish string presence,
not a basis for admitting grade-8 evidence or changing
`REQUIRED_FOR_DIAGNOSIS`.

The checker is [check_vision_harvest_excerpts.py](../../scripts/research/check_vision_harvest_excerpts.py).
Its checkpointed inputs, every row result, summary, failure exhibits, and run
transcript are under the ignored
`scripts/research/vision_excerpt_verification_out/g8_excerpt_check/` directory.
It reads both harvests and Docling only; it changes no ingestion, digest, or
evidence-admission code.

## Method and field inventory

The checker joins a reading to
`TeacherLessonGuides/Grade<g>/Grade<g>-<unit>-<lesson>-Lesson-teacher-guide-/document.md`
through its `code` (`IM-G<g>-U<unit>-L<lesson>`). It indexed 1,169 grade-1–8
documents; the remaining 139 of the stated 1,308 are Kindergarten documents.
There were no duplicate code joins. A missing document is reported as
`unjoinable`, never skipped.

The artifacts contain these relevant fields:

| Field | Broad harvest nonblank | Opus harvest nonblank | Treatment |
| --- | ---: | ---: | --- |
| `task_events[].excerpt` | 3,130 | 2,239 | Checked as quoted source text. |
| `task_events[].deformation.excerpt` | 27 | 39 | Checked as quoted source text. |
| `boundary_note` | 437 | 189 | Recorded but not checked: it is an interpretive boundary summary, not an attributed quotation. |
| `quote` | 0 | 0 | Absent. |

Grade 8 carries 615 nonblank `task_events[].excerpt` values, so this is not an
implementation block caused by structured-only readings.

### Normalization ledger

| Normalization | Used | Reason and limit |
| --- | --- | --- |
| Collapse every whitespace run to one ASCII space; trim ends | Yes | Makes line wraps and markdown paragraph spacing immaterial. |
| Case folding | No | Would weaken a literal source-text check. |
| Unicode or punctuation folding | No | Would make typographic substitutions invisible. |
| Markdown removal | No | Would discard source content. |
| Fuzzy matching | No | Used only to select the failure exhibit beside a claim, never to pass a row. |

## Results

The calibration is stated first because it governs interpretation. The Opus
set has 2,278 checked rows: 568 passed, 1,705 failed, and 5 were unjoinable.
At 24.99% among joined rows, the whitespace-only predicate has not shown that
it is measuring source provenance rather than Docling extraction loss. In
particular, several failures retain the prose prompt but lose symbols,
coordinates, or image-contained content.

### Broad G6–8 harvest

| Grade | Field | Checked | Passed | Failed | Unjoinable | Pass rate among joined |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| 6 | `task_events[].excerpt` | 1,411 | 330 | 1,076 | 5 | 23.47% |
| 6 | `task_events[].deformation.excerpt` | 18 | 6 | 12 | 0 | 33.33% |
| 7 | `task_events[].excerpt` | 1,104 | 247 | 848 | 9 | 22.56% |
| 7 | `task_events[].deformation.excerpt` | 9 | 2 | 7 | 0 | 22.22% |
| 8 | `task_events[].excerpt` | 615 | 130 | 466 | 19 | 21.81% |

The broad unjoinable codes are G6: `IM-G6-U5-L16`; G7:
`IM-G7-U7-L21`, `IM-G7-U8-L21`; and G8: `IM-G8-U2-L14`,
`IM-G8-U2-L15`, `IM-G8-U6-L14`, `IM-G8-U6-L17`, `IM-G8-U6-L18`, and
`IM-G8-U7-L20`. Multiple event excerpts can account for more than one
unjoinable row per code.

### Opus-verified G6–7 control

| Grade | Field | Checked | Passed | Failed | Unjoinable | Pass rate among joined |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| 6 | `task_events[].excerpt` | 1,402 | 349 | 1,048 | 5 | 24.98% |
| 6 | `task_events[].deformation.excerpt` | 19 | 7 | 12 | 0 | 36.84% |
| 7 | `task_events[].excerpt` | 837 | 210 | 627 | 0 | 25.09% |
| 7 | `task_events[].deformation.excerpt` | 20 | 2 | 18 | 0 | 10.00% |

The control's sole unjoinable code is `IM-G6-U5-L16`.

## Overlap check

The broad harvest has 438 lesson records and the Opus harvest has 191. They
share 134 codes; all 134 lesson records and all 134 corresponding
`task_events` arrays are byte-identical after canonical JSON serialization.
The broad harvest has 304 additional lessons and the Opus harvest has none
outside the broad set. This verifies the shared material rather than assuming
it.

## Failure exhibits from the broad harvest

The Docling text is shown as an exhibit, not a fuzzy pass. Two failures per
grade follow.

| Grade and code | Harvest claim | Nearby Docling text |
| --- | --- | --- |
| G6 `IM-G6-U1-L1` | “Area of A is 15 square units. Area of B is 15 square units. Area of C is 12 square units. The area of the entire region is 15 + 15 + 12, or 42 square units.” | “Area of A is 15 square units. Area of B is 15 square units. Area of C is 12 square units. The area of the entire region is , or 42 square units.” |
| G6 `IM-G6-U1-L2` | “The area of the small triangle is _____ square units. I know this because...” | “The area is 8 square units. Sample response:” |
| G7 `IM-G7-U1-L2` | “What is the scale factor from polygon ABCD to polygon PQRS?” | “Polygon is a scaled copy of polygon .” |
| G7 `IM-G7-U1-L3` | “Complete each equation to make it true: 5 ___ = 10, 3 ___ = 15, 14 ___ = 21, 30 ___ = 6” | “Complete each equation to make it true.” |
| G8 `IM-G8-U1-L5` | “If the point (13, 10) were reflected using the x-axis as the line of reflection, what would be the coordinates of the image? What about (13, -20)? (13, 570)?” | “Suppose you reflect a point using the -axis as the line of reflection. How would you describe its image?” |
| G8 `IM-G8-U1-L5` | “Without graphing, predict the coordinates of the image of point R if point R were reflected using the y-axis as the line of reflection. ... What are the coordinates of R'?” | “Label the image of point as . What are the coordinates of ?” |

## Self-bite and interpretation boundary

`--self-bite` appends a unique corruption marker to one excerpt only in memory.
The resulting one-row check reported `checked=1, passed=0, failed=1,
unjoinable=0`, so the checker detects a changed quoted string. The final
transcript tail records the per-grade counts and this result.

Substring presence would establish only that this quoted text was read from the
joined lesson's Docling text. It would not establish that the harvest's
operation, kind, answer, task interpretation, or figure-bound judgment is
right. In this run, absence does not establish the opposite either, because the
control shows that Docling frequently omits mathematical or image-derived
content.

## Open questions

1. Should a later provenance check use the rendered page/image layer that the
   harvest actually read, rather than treating Docling markdown as a complete
   textual control?
2. Which explicit additional normalization, if any, can be calibrated without
   concealing dropped mathematical content?
3. Should the missing G6–8 code joins be reconciled with the Docling export
   before any subsequent grade-8 semantics decision?

IMPLEMENTATION_COMPLETE — checker, checkpointed measurement, calibration warning, and self-bite are complete; no evidence-admission wiring changed.
