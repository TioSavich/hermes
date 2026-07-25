# Closing the negation holes

Date: 2026-07-25

## Result

The pre-change generated layer declared 16 `known_topic/1` values, including
`fraction/thirds`. Only `data` subtracted zero machines: all 232 survived.

The builder now derives the following additions:

- `statistics` carries the `data` topic because the statistics transition table
  records `preserve_data_set` as an action. The generated source term is
  `automaton_action_evidence(statistics,
  box_plot_from_five_number_summary, preserve_data_set)`.
- A machine whose `machine_grammar/6` genre is `discursive` is excluded from a
  mathematical-topic query with a `nonmathematical_genre/3` reason. This
  subtracts all 18 discourse machines.
- A standard below a topic's first recorded IM lesson grade is excluded with a
  `standard_grade_below/3` reason. The source term names the lesson, topic, and
  grade.

The all-topic audit also found that `calculus` was an `operation_topic/2` value
returned by the builder's topic reader but was not emitted as `known_topic/1`.
The renderer now emits the full set returned by that reader. This adds no topic
word.

A direct Prolog query resolved all 21,551 generated exclusion reasons. The
commissioned `fraction/thirds` case still excludes all 139 kindergarten lessons
and leaves 209 lessons.

## Before and after

Each cell reports surviving lessons, standards, and machines in that order.
The pre-change file did not declare `calculus` as a known topic.

| Topic | Before L/S/M | After L/S/M |
|---|---:|---:|
| `addition` | 393/228/58 | 393/228/26 |
| `algebraic` | 384/228/54 | 384/228/22 |
| `calculus` | not declared | 103/228/10 |
| `cardinality` | 104/228/40 | 104/228/8 |
| `counting` | 177/228/47 | 177/228/15 |
| `data` | 1,308/228/232 | 189/228/22 |
| `decimal` | 149/228/56 | 149/104/24 |
| `division` | 200/228/55 | 200/228/23 |
| `fraction` | 245/228/68 | 245/139/36 |
| `fraction/thirds` | 209/173/68 | 209/173/36 |
| `geometry` | 408/228/86 | 408/228/54 |
| `integer` | 110/228/46 | 110/29/14 |
| `multiplication` | 284/228/60 | 284/228/28 |
| `probability` | 123/228/42 | 123/21/10 |
| `proportional` | 159/228/44 | 159/21/12 |
| `ratio` | 580/228/44 | 580/228/12 |
| `subtraction` | 313/228/54 | 313/228/22 |

The `data` survivors are 86 lessons tagged with `data`, the 103 lessons with no
recorded topic, the 14 statistics machines, and the eight still-unmapped
measurement machines. A data query does not retain the separate two-machine
probability family.

## 1. Topics that subtracted zero machines

Before this change, the complete zero-subtraction list over generated
`known_topic/1` facts was:

- `data`: 232 of 232 machines survived.

Every other declared topic subtracted at least one machine.

The statistics table contains 14 machines. Nine contain the
`preserve_data_set` action, and the same table names box plots, dot plots,
histograms, distribution summaries, medians, modes, and statistical questions.
This grounds `family_topics(statistics, [data])`. The evidence grounds no
`probability` relation for that family. Probability has its own
transition-table family, and no statistics tuple supplies probability evidence.

The check now enumerates the generated `known_topic/1` facts and fails when a
topic leaves all machine slices. Its explicit exemption dictionary is empty.
Any future exemption must carry a reason in that dictionary.

## 2. Standard grade floors

The generic rule applies only to standards. No generic standard-topic mismatch
is emitted. For each topic recorded by at least one live lesson, the builder
chooses the lowest `(Grade, LessonCode)` pair and emits it as
`lesson_topic_grade_evidence/3`.

The nonzero floors are:

| Topic | Floor | Source lesson | Standards surviving |
|---|---:|---|---:|
| `decimal` | 4 | `IM-G4-U4-L1` | 104 / 228 |
| `fraction` | 3 | `IM-G3-U5-L1` | 139 / 228 |
| `integer` | 6 | `IM-G6-U7-L1` | 29 / 228 |
| `probability` | 7 | `IM-G7-U8-L1` | 21 / 228 |
| `proportional` | 7 | `IM-G7-U1-L1` | 21 / 228 |

The remaining lesson-derived topics have a floor of kindergarten and therefore
exclude no standards by grade. `calculus` has no lesson-derived topic record,
so it receives no standard exclusion. This is a recorded gap rather than an
inferred floor.

`fraction/thirds` retains its separate Grade 2 source,
`standard_anchor_evidence(im_grade2_u6_l7, ccss, '2.G.A.3')`. A normalized
thirds query uses fraction family and lesson mismatch rows. Its standard
exclusions come from the separate Grade 2 source, so its standard count remains
173 of 228.

## 3. The 103 lessons with no recorded topic

All 103 also return `[]` when `compute_lesson_topics/2` is called directly, so
the cache is not masking newer predicate results.

| Cause | Lessons |
|---|---:|
| No text at all | 0 |
| Title-only source text with no keyword match | 46 |
| Descriptive lesson text with no keyword match | 57 |
| Cache drift or another cause | 0 |

The 46 title-only rows are all in grades 6 through 8. Their live source supplies
a lesson title but no descriptive lesson statement. The other 57 rows have
descriptive lesson text, but none of the 76 current keyword facts occurs in the
title, lesson statement, secondary standard text, or concept atom.

The distribution by grade is:

| Grade | Empty-topic lessons |
|---:|---:|
| K | 24 |
| 1 | 12 |
| 2 | 10 |
| 3 | 4 |
| 4 | 5 |
| 5 | 2 |
| 6 | 11 |
| 7 | 11 |
| 8 | 24 |

The grade and unit distribution is:

| Grade | Unit | Count |
|---:|---:|---:|
| K | 1 | 3 |
| K | 2 | 16 |
| K | 6 | 1 |
| K | 8 | 4 |
| 1 | 3 | 1 |
| 1 | 4 | 5 |
| 1 | 6 | 4 |
| 1 | 7 | 1 |
| 1 | 8 | 1 |
| 2 | 3 | 4 |
| 2 | 5 | 4 |
| 2 | 6 | 2 |
| 3 | 3 | 3 |
| 3 | 6 | 1 |
| 4 | 4 | 3 |
| 4 | 8 | 2 |
| 5 | 5 | 1 |
| 5 | 7 | 1 |
| 6 | 5 | 1 |
| 6 | 9 | 10 |
| 7 | 9 | 11 |
| 8 | 3 | 8 |
| 8 | 7 | 12 |
| 8 | 9 | 4 |

### Keyword proposals

The table records review candidates. The keyword facts in
`curriculum/im/lesson_monitoring.pl` remain unchanged.

| Candidate | Possible topic | Lesson text that motivates review |
|---|---|---|
| `one-to-one correspondence` | `counting` or `cardinality` | `IM-GK-U1-L10` says students develop and practice one-to-one correspondence. |
| `number of objects` | `counting` | `IM-GK-U2-L14` asks students to determine the number of objects in a group. |
| `symmetry`, `trapezoid`, `quadrilateral`, `tessellation` | `geometry` | `IM-G4-U8-L4` names line symmetry, `IM-G5-U7-L5` names trapezoids and quadrilaterals, and `IM-G8-U9-L2` is titled “Regular Tessellations.” |
| `linear relationship`, `slope` | `algebraic` | Eight empty rows in Grade 8 Unit 3 name linear relationships or slope. |
| `exponent`, `power of 10`, `scientific notation` | `algebraic` | Twelve empty rows in Grade 8 Unit 7 name exponents, powers of 10, or scientific notation. |
| `length`, `measure`, `measurement`, `inch`, `centimeter`, `clock`, `hour` | unresolved measurement topic | `IM-G2-U3-L1` says students measure by iterating same-size length units; `IM-G2-U6-L11` concerns an analog clock. |
| `place value`, `tens and ones`, `digit`, `round`, `nearest multiple` | unresolved place-value topic | `IM-G1-U3-L8` says 10 ones make a unit called a ten; the empty Grade 3 Unit 3 rows concern rounding and nearest multiples. |

Assigning the last two rows requires topic decisions. They expose missing topic
decisions as well as missing keyword coverage.

Adding any reviewed keyword requires rebuilding
`curriculum/im/lesson_topics_cache.pl`. Changing the keyword table without that
rebuild would leave the generated cache inconsistent with the live classifier.

## 4. Families without prior topic evidence

### Discourse

The action grammar records all 18 discourse machines with genre `discursive`.
Their tuples concern assertions, commitments, entitlements, compatibility, and
repair. A mathematical-topic query now excludes them. Each exclusion names the
machine's generated `machine_genre/3` evidence.

The decision concerns mathematical-topic membership in this index. Discourse
remains relevant to lesson and tutoring analyses.

### Measurement

No mapping was added. The eight machines cover linear unit iteration, liquid
volume scale reading, unit conversion, and unit-preserving quantity change.
Only two name liquid volume, so mapping the whole family to `geometry` from
those two tuples would overstate the evidence. The current topic enum has no
`measurement` value.

The eight measurement machines therefore remain in every topic result. This is
an open gap. Closing it requires either a grounded `measurement` topic or a
more granular machine-level relation.

### Statistics

The family now maps to `data` through transition-table action evidence. All 14
statistics machines survive a data query and are excluded from other
mathematical topics unless another grounded family topic is added later.
`probability` remains separate.

## Open gaps

- `measurement` has no family-wide topic that the present tree can ground.
- `calculus` has no lesson topic record, so no standard grade floor is emitted.
- Forty-six empty-topic lessons have only title-level source text. Keywords
  alone may not classify titles such as “Fermi Problems” or “Energy Flow.”
- The proposed measurement and place-value keyword groups need topic decisions
  before they can become classifier facts.
