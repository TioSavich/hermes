# Grade 8 Goals vocabulary sweep

Date: 2026-08-07

## Result

The Goals vocabulary supports the ordering claim in its bounded form. Covariation vocabulary occurs before Unit 8: it begins in the Unit 2 slope sequence, appears in 13 of 15 Unit 3 sections, appears in 15 of 22 Unit 5 sections, and occurs in all 11 Unit 6 sections. Partition vocabulary is most concentrated in Unit 8, where it occurs in 7 of 18 sections. Unit 8 has no covariation-classified section under the frozen markers.

The stronger claim that variables arrive exclusively or uniformly through covariation in Units 3–5 is not supported by this vocabulary test. Unit 4 is variable- and equation-bearing, but 15 of its 16 sections are neither because generic `variable`, `equation`, and `relationship` were not treated as covariation markers. Partition vocabulary is also not exclusive to Unit 8: one hit occurs in Unit 1, one in Unit 5, and two in Unit 7. The result therefore supports covariation-before-Unit-8 and a late concentration of partition vocabulary, not a clean curricular partition between the two vocabularies.

Across all 134 sections: **11 partition, 46 covariation, 0 both, and 77 neither**. Of the 11 partition sections, 7 (63.6%) are in Unit 8. Units 3–5 contain 29 covariation sections, 1 partition section, and 23 neither sections.

This is a vocabulary-presence result. It does not establish what teachers or students enact, what a letter conceptually requires, or whether continuum construction causes variable use.

## Frozen method

The lexicons below were written to `goals-sweep/frozen-lexicons.json` before the classification program was run. Matching is case-insensitive regular-expression presence over each extracted Goals body. Markdown image-only lines are retained in the raw extraction but omitted from the prose searched for markers. A section is partition when only partition markers occur, covariation when only covariation markers occur, both when both families occur, and neither when no marker occurs.

The lexicons are narrow by design. `divide`, `dividing`, and `division` alone are not partition markers because the corpus often names a quotient operation without naming subdivision into parts. Generic `change`, `relationship`, `variable`, and `quantity` are not covariation markers because they also occur in transformation, equation, and static comparison contexts. The covariation list admits slope and bivariate-data representations because they explicitly coordinate quantities or their variation. The partition list admits named units, fractions, decomposition, one-half, and whole-number bounding of roots.

Citation keys below use `unit-lesson:Goals-heading-line`. For example, `8-1:7` expands to `hermes/app/runtime/experiments/gemma4_tutor/docling/full-output/TeacherLessonGuides/Grade8/Grade8-8-1-Lesson-teacher-guide-/document.md:7`.

### Partition markers

| Frozen marker | Exact match expression | Verbatim corpus example | Matched sections |
|---|---|---|---|
| decompose / decomposition | `\bdecompos(?:e\|ed\|es\|ing\|ition\|itions)\b` | “Calculate the area of a tilted square on a grid by using decomposition” (8-1:7) | 1-15, 8-1 |
| one-half | `\bone-half\b` | “repeated multiplication by one-half” (7-1:7) | 7-1 |
| fraction / fractions | `\bfractions?\b` | “a positive or negative fraction” (8-4:7) | 8-4, 8-16 |
| units of measure | `\bunits of measure\b` | “different units of measure” (5-12:7) | 5-12 |
| base-ten units | `\bbase-ten units\b` | “base-ten units” (7-9:7) | 7-9 |
| square units | `\bsquare units\b` | “whose area is square units” (8-2:7) | 8-2 |
| cubic units | `\bcubic units\b` | “whose volume is cubic units” (8-14:7) | 8-14 |
| whole number(s) ... between | `(?:\bwhole numbers?\b[^.]{0,100}\bbetween\b\|\bbetween\b[^.]{0,100}\bwhole numbers?\b)` | “the two whole number values that a square root is between” (8-6:7) | 8-6, 8-15 |

### Covariation markers

| Frozen marker | Exact match expression | Verbatim corpus example | Matched sections |
|---|---|---|---|
| slope / slopes | `\bslopes?\b` | “To find the slope, divide the vertical change by the horizontal change” (2-10:7) | 2-10, 2-11, 2-12, 3-5, 3-6, 3-7, 3-9, 3-10, 3-15, 6-6, 6-8 |
| proportional relationship(s) | `\bproportional relationships?\b` | “proportional relationships in context” (3-1:7) | 3-1, 3-2, 3-3, 3-4 |
| linear relationship(s) | `\blinear relationships?\b` | “nonproportional linear relationships” (3-5:7) | 3-5, 3-6, 3-7, 3-8, 3-9, 3-12, 3-13, 3-15, 4-11 |
| rate(s) of change | `\brates? of change\b` | “the rates of change for two proportional relationships” (3-4:7) | 3-4, 3-8, 3-9, 5-8, 5-10, 5-11 |
| initial value(s) | `\binitial values?\b` | “different initial values” (3-8:5) | 3-8, 5-8 |
| input / inputs | `\binputs?\b` | “input-output diagrams” (5-1:7) | 5-1, 5-2, 5-3, 5-5, 5-18 |
| output / outputs | `\boutputs?\b` | “input-output pairs” (5-1:7) | 5-1, 5-2, 5-3, 5-5, 5-18 |
| depends on | `\bdepends on\b` | “[The output] depends on [the input].” (5-2:7) | 5-2 |
| independent and dependent variable(s) | `\bindependent and dependent variables?\b` | “the independent and dependent variables of a function” (5-3:7) | 5-3 |
| function / functions | `\bfunctions?\b` | “[The output] is a function of [the input]” (5-2:7) | 5-2, 5-3, 5-4, 5-5, 5-6, 5-7, 5-8, 5-9, 5-10, 5-11, 5-17, 5-18, 5-20, 5-22, 6-1 |
| increasing | `\bincreasing\b` | “a graph of a function as 'increasing'” (5-5:7) | 3-9, 5-5 |
| decreasing | `\bdecreasing\b` | “or 'decreasing' over an interval” (5-5:7) | 5-5 |
| two variables | `\btwo variables\b` | “represents data with two variables” (6-1:7) | 5-3, 6-1, 6-6 |
| bivariate | `\bbivariate\b` | “bivariate data” (6-8:7) | 6-8, 6-11, 9-4, 9-5, 9-6 |
| association / associations | `\bassociations?\b` | “non-linear association” (6-7:7) | 6-7, 6-9, 6-10, 6-11 |
| trend / trends | `\btrends?\b` | “the trend of the data” (6-2:7) | 6-2, 6-3 |
| line / lines of fit | `\blines? of fit\b` | “a line of fit” (6-4:7) | 6-4, 6-8, 9-6 |
| scatter plot / plots | `\bscatter plots?\b` | “data in scatter plots and tables” (6-1:7) | 6-1, 6-2, 6-3, 6-4, 6-5, 6-6, 6-7, 6-8, 6-11, 9-5, 9-6 |

## Per-unit classification

Codes: `P` = partition, `C` = covariation, `B` = both, `N` = neither. The sequence column lists every lesson in numeric lesson order.

| Unit | Lesson-order classifications | P | C | B | N | Total |
|---:|---|---:|---:|---:|---:|---:|
| 1 | L1 N; L2 N; L3 N; L4 N; L5 N; L6 N; L7 N; L8 N; L9 N; L10 N; L11 N; L12 N; L13 N; L14 N; L15 P; L16 N; L17 N | 1 | 0 | 0 | 16 | 17 |
| 2 | L1 N; L2 N; L3 N; L4 N; L5 N; L6 N; L7 N; L8 N; L9 N; L10 C; L11 C; L12 C; L13 N | 0 | 3 | 0 | 10 | 13 |
| 3 | L1 C; L2 C; L3 C; L4 C; L5 C; L6 C; L7 C; L8 C; L9 C; L10 C; L11 N; L12 C; L13 C; L14 N; L15 C | 0 | 13 | 0 | 2 | 15 |
| 4 | L1 N; L2 N; L3 N; L4 N; L5 N; L6 N; L7 N; L8 N; L9 N; L10 N; L11 C; L12 N; L13 N; L14 N; L15 N; L16 N | 0 | 1 | 0 | 15 | 16 |
| 5 | L1 C; L2 C; L3 C; L4 C; L5 C; L6 C; L7 C; L8 C; L9 C; L10 C; L11 C; L12 P; L13 N; L14 N; L15 N; L16 N; L17 C; L18 C; L19 N; L20 C; L21 N; L22 C | 1 | 15 | 0 | 6 | 22 |
| 6 | L1 C; L2 C; L3 C; L4 C; L5 C; L6 C; L7 C; L8 C; L9 C; L10 C; L11 C | 0 | 11 | 0 | 0 | 11 |
| 7 | L1 P; L2 N; L3 N; L4 N; L5 N; L6 N; L7 N; L8 N; L9 P; L10 N; L11 N; L12 N; L13 N; L14 N; L15 N; L16 N | 2 | 0 | 0 | 14 | 16 |
| 8 | L1 P; L2 P; L3 N; L4 P; L5 N; L6 P; L7 N; L8 N; L9 N; L10 N; L11 N; L12 N; L13 N; L14 P; L15 P; L16 P; L17 N; L18 N | 7 | 0 | 0 | 11 | 18 |
| 9 | L1 N; L2 N; L3 N; L4 C; L5 C; L6 C | 0 | 3 | 0 | 3 | 6 |
| **All** | **134 classified sections** | **11** | **46** | **0** | **77** | **134** |

## Verbatim classification samples

There are no both-classified sections, so there are no BOTH quotes to report. The ten single-family samples are stratified across both classes and across Units 1–8. Each quote is the complete marker-bearing bullet copied from the extracted Goals body.

### 1-15: partition

Markers: `decompose / decomposition`. Source: `1-15:7`.

> - Describe (orally) that a straight angle can be decomposed into 3 angles to construct a triangle.

### 5-12: partition

Markers: `units of measure`. Source: `5-12:7`.

> - Estimate the volumes of various containers using different units of measure, and explain (orally) the reasoning.

### 7-1: partition

Markers: `one-half`. Source: `7-1:7`.

> - Comprehend that repeated division by 2 is equivalent to repeated multiplication by one-half.

### 8-6: partition

Markers: `whole number(s) ... between`. Source: `8-6:7`.

> - Identify the two whole number values that a square root is between and explain (orally) the reasoning.

### 8-16: partition

Markers: `fraction / fractions`. Source: `8-16:7`.

> - Represent rational numbers as equivalent decimals and fractions, and explain (orally) the solution method.

### 2-10: covariation

Markers: `slope / slopes`. Source: `2-10:7`.

> - Comprehend the term 'slope' to mean a number that tells how steep a line is. To find the slope, divide the vertical change by the horizontal change for any two points on the line.

### 3-4: covariation

Markers: `proportional relationship(s)`, `rate(s) of change`. Source: `3-4:7`.

> - Compare the rates of change for two proportional relationships, given multiple representations.

### 4-11: covariation

Markers: `linear relationship(s)`. Source: `4-11:7`.

> - Create a graph that represents two linear relationships in context, and interpret (orally and in writing) the point of intersection.

### 5-2: covariation

Markers: `input / inputs`, `output / outputs`, `depends on`, `function / functions`. Source: `5-2:7`.

> - Comprehend the structure of a function as having one and only one output for each allowable input.

### 6-9: covariation

Markers: `association / associations`. Source: `6-9:7`.

> - Calculate relative frequencies, and describe (orally and in writing) associations between variables using a relative frequency table.

## Extraction provenance

The analyzed corpus is `hermes/app/runtime/experiments/gemma4_tutor/docling/full-output/TeacherLessonGuides/Grade8/`. The tracked `curriculum/im_teacher_guides/grade8` tree was not used. The runtime corpus contains 134 `document.md` files and each contains exactly one `## Goals` heading. Unit counts are 17, 13, 15, 16, 22, 11, 16, 18, and 6 for Units 1 through 9, totaling 134.

`goals-sweep/extract_goals.py` locates the sole Goals heading in each guide and copies everything after that heading through the next Markdown heading, removing only surrounding line breaks. `goals-sweep/goals-sections.md` is the human-readable verbatim extraction; `goals-sweep/goals-sections.json` records the same text with source paths and heading lines. A few Docling documents place unheaded `Learning Targets` text before the next Markdown heading, so that text remains part of the mechanically bounded Goals extraction. Inline mathematics omitted by Docling was not reconstructed.

`goals-sweep/classify_goals.py` applies only `goals-sweep/frozen-lexicons.json`. Its complete per-lesson outputs are `goals-sweep/classifications.csv` and `goals-sweep/classifications.json`; aggregate counts are in `goals-sweep/summary.json`. These artifacts and this report are all under `.superpowers/sdd/`.

## Limits

- Marker selection determines the boundary of the result. Broader choices such as generic `divide`, `variable`, or `relationship` would change counts and could introduce both classifications.
- Presence does not measure emphasis. One marker occurrence and several occurrences produce the same section class.
- `square units` and `cubic units` name measurement units; their admission as partition-shaped vocabulary records unitization, not evidence of recursive partitioning by itself.
- `slope`, `scatter plot`, and `line of fit` are admitted as covariation-shaped representations; their presence does not show that a lesson enacts covariational reasoning.
- Unit 8 operationalizes the survey's continuum location through root approximation, fraction/decimal language, measurement units, and whole-number bounds. The word `continuum` is not itself a marker in the Goals corpus.

IMPLEMENTATION_COMPLETE
