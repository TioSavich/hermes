# The singleton tail under `no_task_grammar_for_quantity_pair`

2026-07-27. Analysis only; no code ships from this file.

An earlier pass measured the shape distribution of the registry's rank-1 unresolved
reason under one equivalence — number-normalized full-span text — found three recurring
expression-list clusters and a tail of singletons, and concluded that further coverage
needs clustered word-problem grammars rather than one-off parsers. This pass tests that
conclusion by loosening the equivalence in five steps, by re-measuring at three different
units of text, and by building a deliberately generous word-problem grammar and counting
how often it is wrong.

The conclusion survives. The diagnosis behind it does not: the singleton count at the
strictest level was governed by the *unit* of comparison more than by the normalization,
and the reason the tail resists a parser is not that the prompts are all different. It is
that two thirds of them carry no operand pair at all, and that in the remaining third the
operation and the operand order are fixed by the situation type rather than by anything a
sentence-shape equivalence preserves.

## What was measured, and against what

Every claim below joins the registry's own rows to the live span text: the 3,163
`task_span_receipt/4` rows in `knowledge/index/task_span_absence_registry.pl` were parsed
and keyed by `(lesson, position)`, and `compile_action_mappings.extract_student_task_spans`
was run against the checked-out guides. The two agree on all 3,163 keys with no orphans on
either side, so the 960 spans analysed here are the same 960 the registry types.

The state read is the working tree, which at the time of writing carries the three
expression-list parsers and their regenerated registry uncommitted. The registry's
`no_task_grammar_for_quantity_pair` count was 960 throughout the analysis. It is 780 now,
because part of this analysis was then implemented as a new reason; the closing section
records what shipped, what did not, and why.

Denominators used throughout:

| Quantity | Count | Source |
|---|---|---|
| Student task spans in the corpus | 3,163 | `task_span_denominator(spans, _)` |
| Lessons with a teacher guide | 879 | `task_span_denominator(lessons, _)` |
| Spans typed `no_task_grammar_for_quantity_pair` when this analysis ran | 960 | `task_span_reason_count/2` |
| Lessons carrying at least one such span | 541 | measured on the join |
| Lessons carrying a compiled task instance | 227 | `compiled_task_instance_summary/2` |
| Lessons carrying none | 652 | 879 − 227 |
| Lessons missing only `executable_task` + `measured_transition` | 210 | `lesson_missing_only_task_evidence/1` |
| Of those 210, lessons carrying a quantity-pair span | 129 | `task_span_reason_queue(1, _, 129)` |

Of the 541 lessons with a quantity-pair span, 100 already carry a compiled task instance
and 441 do not. So 441 lessons is the ceiling on new-lesson reach from this reason, and 129
lessons is the ceiling on reach into the cohort where a task instance would flip the
readiness verdict. All 129 already carry at least one operation attachment, so the
compiler's `has_route` gate is not what blocks them; 76 of the 541 carry no attachment at
all and would reject any candidate regardless of grammar.

The phrase "the 227-lesson gap" in the request is ambiguous between the 652 lessons with no
task instance and the 210-lesson missing-only cohort. Both columns appear in every table
below, labelled `new lessons` (of the 652) and `cohort` (of the 210).

## The equivalence ladder

Six levels, cumulative, each a strict loosening of the one above:

- **N0** number-normalized text (every numeral to `#`, whitespace collapsed); the earlier
  pass's equivalence.
- **N1** N0 plus lowercasing and punctuation stripped.
- **N2** N1 plus the IM character roster collapsed to `NAME` (Jada, Han, Elena, Priya,
  Andre, Lin, Tyler, Diego, Clare, Kiran, Mai, Noah).
- **N3** N2 plus every content word outside a closed function-and-mathematics vocabulary
  collapsed to `W`, with runs of `W` merged. This erases referent nouns, container nouns,
  and situation nouns together.
- **N4** the ordered signature of quantity slots, operator characters, and question words,
  with all other text discarded.
- **N5** the set of question forms present plus the set of operator characters present, with
  order and count discarded.

N3 is more aggressive than the request's suggested moves taken separately: it collapses the
referent noun, the container noun, and the proper name in one step. N4 and N5 are past the
point where a parser could work at all and are included to locate where structure starts.

### At the full-span unit (the earlier pass's unit), n = 960

| Level | Distinct keys | Singletons | Clusters ≥ 5 | Spans in them | Lessons | New lessons | Cohort |
|---|---|---|---|---|---|---|---|
| N0 | 957 | 955 | 0 | 0 | 0 | 0 | 0 |
| N1 | 956 | 953 | 0 | 0 | 0 | 0 | 0 |
| N2 | 956 | 953 | 0 | 0 | 0 | 0 | 0 |
| N3 | 955 | 951 | 0 | 0 | 0 | 0 | 0 |
| N4 | 812 | 765 | 9 | 106 | 94 | 81 | 22 |
| N5 | 161 | 89 | 30 | 757 | 476 | 384 | 115 |

Collapsing names, referent nouns, and container nouns moves the singleton count from 955 to
951. Four spans. The referent-noun hypothesis, tested directly, accounts for essentially
nothing at this unit.

The clusters that do appear at N4 and N5 are empty of task content: the largest N4 keys are
`# # # #`, `# #`, and `# # # # # #`; the largest N5 keys are `ops=` with no question form at
all (261 spans) and `explain_only ops=` (90 spans). A grammar keyed on those would be keyed
on nothing.

### The unit was doing the work

A span is not a task. The span reader takes everything between the `Student Task Statement`
heading and the next heading, and IM prints several numbered tasks under one heading. Two
spans that each contain the same subtraction item still differ if their other items differ,
so full-span comparison guarantees singletons by construction.

Re-measuring at the compiler's own chunking (`_task_chunks`, splitting at a line-initial
`N.`), and again at a finer split that also breaks at lettered markers and bullets, changes
the count at the *strictest* level:

**Item unit** (1,164 items carrying two or more quantities):

| Level | Distinct keys | Singletons | Clusters ≥ 5 | Units in them | Lessons | New lessons | Cohort |
|---|---|---|---|---|---|---|---|
| N0 | 1,066 | 1,032 | 8 | 68 | 17 | 8 | 3 |
| N1 | 1,064 | 1,029 | 8 | 68 | 17 | 8 | 3 |
| N2 | 1,061 | 1,024 | 8 | 68 | 17 | 8 | 3 |
| N3 | 1,043 | 992 | 8 | 68 | 17 | 8 | 3 |
| N4 | 633 | 529 | 34 | 452 | 237 | 184 | 53 |
| N5 | 111 | 57 | 24 | — | — | — | — |

**Sub-item unit** (1,291 units carrying two or more quantities):

| Level | Distinct keys | Singletons | Clusters ≥ 5 | Units in them | Lessons | New lessons | Cohort |
|---|---|---|---|---|---|---|---|
| N0 | 1,066 | 990 | 20 | 158 | 46 | 35 | 9 |
| N1 | 1,054 | 980 | 21 | 175 | 51 | 40 | 11 |
| N2 | 1,051 | 975 | 21 | 175 | 51 | 40 | 11 |
| N3 | 1,017 | 917 | 22 | 181 | 55 | 44 | 12 |
| N4 | 515 | 386 | 49 | 693 | 284 | 228 | 67 |
| N5 | 83 | 37 | 27 | 1,206 | 438 | 353 | 108 |

**Sentence unit** (905 sentences carrying two or more quantities):

| Level | Distinct keys | Singletons | Clusters ≥ 5 | Units in them | Lessons | New lessons | Cohort |
|---|---|---|---|---|---|---|---|
| N0 | 755 | 703 | 13 | 103 | 29 | 17 | 5 |
| N1 | 748 | 694 | 14 | 110 | 32 | 19 | 5 |
| N2 | 737 | 676 | 15 | 116 | 33 | 20 | 5 |
| N3 | 672 | 579 | 19 | 145 | 44 | 30 | 7 |
| N4 | 249 | 181 | 28 | 614 | 264 | 207 | 60 |
| N5 | 41 | 18 | 13 | 861 | 351 | 285 | 86 |

Two results follow. First, structure appears at N0 once the unit is right: 20 clusters of
size five or more at the sub-item level under exact number-normalized text, no loosening
required. Second, the N0→N3 loosening buys almost nothing at any unit (sub-item singletons
move 990 → 917, and every one of the top twelve keys is unchanged). What the corpus repeats
is repeated *exactly*; what differs differs in ways no noun-level or name-level abstraction
touches.

The N0 clusters at the sub-item level are all bare arithmetic: `#. # × #` (17), `# + #`
(14), `# + # = #` (13), `#. # + # =` (11), `# × #` (11), `#. #- #` (10), `# + # = # + #`
(9). The three shipped parsers already work at this granularity, which is why the earlier
pass found them; the span-level measurement was taken at a coarser unit than the parsers it
was measuring.

The only sentence-level N0 cluster carrying words is `# students equally share # beads.`
(7 occurrences) and `NAME has # hundreds # tens and # ones` (6 at N2). Two clusters, one
family each.

## What the 960 spans actually contain

Sentence-shape clustering answers a narrow question. The wider one is what kind of thing
each span is. I read samples from every class below and built a regex census over them; the
classifier is approximate at the boundaries and the sampled reads, not the regexes, are the
evidence for what each class contains. Each span is assigned the most task-bearing class
among its sub-items.

| Dominant class | Spans | Lessons | New lessons | Cohort |
|---|---|---|---|---|
| `numeral_inventory_no_question` | 287 | 229 | 191 | 53 |
| `other` | 362 | 278 | 234 | 62 |
| `story_two_quantities_question` | 130 | 90 | 63 | 31 |
| `story_many_quantities_question` | 58 | 47 | 38 | 13 |
| `bare_binary_expression` | 43 | 29 | 17 | 7 |
| `expression_fragment_with_stray_text` | 41 | 39 | 33 | 10 |
| `multiplicative_comparison` | 20 | 10 | 8 | 4 |
| `dimension_geometry_question` | 16 | 14 | 11 | 6 |
| `expression_chain_equation` | 2 | 2 | 2 | 0 |
| `equation_truth_or_blank_list` | 1 | 1 | 1 | 0 |
| **total** | **960** | | | |

Rolled into three groups:

| Group | Spans | Lessons | New lessons | Cohort |
|---|---|---|---|---|
| Literal arithmetic in the extract | 87 | 68 | 52 | 17 |
| Word problems | 224 | 147 | 108 | 48 |
| No task recoverable from the text | 649 | 420 | 350 | 95 |

The last group is a fallthrough: a span lands there when no positive pattern matched it. Its
boundary is soft by roughly thirty spans, all of them geometry and comparison prompts that
belong in the first two groups; the closing section measures that error and says what survives
it. The interior of the group is solid and the paragraph below describes it.

**Two thirds of the tail carries no operand pair.** The 649 spans in the last group hold
numerals that are set members handed out for sorting (`A 94 36 109 163 229 B 24 52 216 11
481`), number-card decks (`1 3 5 4 6 8 10 9 2 7`), data-table cells whose values the student
reads off a graph, price lists, clock times, figure labels, category numbers, page
fragments, and two-column bleed where teacher text leaked into the student column
(`Kindergarten L with pattern blocks?" • Display all the ways...`). Sorting tasks, matching
tasks, error-analysis tasks, number-line labelling, and shape-drawing make up most of the
rest. No normalization reaches these, because there is no arithmetic in them to normalize.
They are correctly typed as unresolved and they are honestly unresolvable from text: the
reason name `no_task_grammar_for_quantity_pair` is accurate about the two quantities and
misleading about what a grammar could do with them.

## Can a parser at each promising level recover both operands with certainty?

### The word-problem class: no, and the error rate is measurable

`story_two_quantities_question` is the largest class where a parser is even conceivable:
191 sub-items, 130 spans, 90 lessons, 63 of them carrying no compiled task, 31 in the
210-lesson cohort. It is also the class the request's candidate moves are aimed at, since
its members differ mostly in referent noun, proper name, and question wording.

I wrote a generous grammar for it — two numerals in text order, operation chosen from
question form plus verb cue, order chosen from magnitude where the operation is
non-commutative — and it emits a task for 180 of the 191 units, covering 124 spans, 87
lessons, 59 new lessons, 29 of the cohort. Those are the reach numbers a clustered
word-problem grammar at this level of abstraction would claim.

I then adjudicated 60 of its outputs against the span text by hand, in two independently
seeded samples of 40 and 20. **Thirty are right and thirty are wrong, in both samples
separately (20/40 and 10/20).** The errors:

| Failure | Count | Example |
|---|---|---|
| Operation inverted by the question form | 8 | "Mai has 5 books. She checks out some more. Now she has 9. How many did Mai check out?" → emitted `add(5, 9)`; the task is `subtract(9, 5)` |
| Multiplication and division exchanged because `each` is present | 5 | "8 rows of seats and 27 seats in each row. How many seats?" → emitted `divide(27, 8)`; the task is `multiply(8, 27)` |
| Operand order wrong under both text order and magnitude order | 1 | "3 dancers share 2 liters equally. How much does each get?" → emitted `divide(3, 2)`; the task is `divide(2, 3)` |
| Part–whole read as a join | 2 | "Han has 8 pets. 5 are lizards. The rest are snakes. How many snakes?" → emitted `add(8, 5)` |
| A numeral that is not an operand | 8 | "…Find more than 1 solution" → the `1` became an operand; "How many students chose category 1 or category 2?" → the category labels became operands |
| A required operand absent from the extract | 4 | "A 150-pound bag of sand fills about 9 cubic feet. How many bags to fill the wagon?" — the wagon's volume is in a figure |
| Comparison misread | 2 | "674 steps to the second floor, 327 to the first. How many from the first to the second?" → emitted `add(674, 327)` |

The failures are not a matter of tuning. The first four rows all say the same thing: the
operation and the operand order are fixed by the *situation type* — join, separate,
part–part–whole, or compare, crossed with which of result, change, or start is unknown, and
equal-groups crossed with which of product, group size, or number of groups is unknown —
and the situation type is exactly what N1 through N3 discard and what N4 and N5 never had.
Text order does not carry it: "Now there are 55 students… how many at first" needs
`subtract(55, 34)` from a text that says 34 first. Magnitude order does not carry it
either: in the grade-5 sharing case the correct quotient is less than one.

The last three rows are worse than tuning problems: they are cases where the extract does
not contain the task. A grammar cannot be gated against them because nothing in the sentence
shape marks a category label as a label rather than a count.

Fifty percent is the number that decides this. A wrong task instance is a false claim about
a real curriculum, carried into every downstream artifact with a citation that verifies: the
excerpt is genuinely at the cited line, and the claim about it is still wrong. Reaching
29 of the 210-lesson cohort at that rate would put roughly 15 lessons' worth of fabricated
arithmetic into the compiled set with receipts that pass the gate. **Do not build this.**

The shipped `story_*` parsers already encode the safe version of this class: they gate on
grade 1–2, on exactly two whole numbers in the chunk, and on a specific question form per
situation type, and they check referent agreement before promoting. That narrowness is what
the 50% buys back. Extending them means adding situation types one at a time with their own
cue sets, which is the "carefully clustered variable word-problem grammars" the earlier pass
named. This measurement says how much care: each added type needs its own hand audit,
because the cost of a loose one is a false curricular claim.

### The literal-expression class: yes, and the barrier is a frame vocabulary

112 of the 960 spans carry a literal binary expression in the extract — 85 lessons, 61 of
them carrying no compiled task, 19 in the 210-lesson cohort. Here both operands are printed
characters, so recovery is exact by construction, the same certainty class as the three
shipped parsers.

What separates these from the spans the shipped parsers already read is the frame phrase.
The compiler gates on the literal strings `Find the value of each expression` and
`Find the value of each expression mentally` together with a `•` marker. The 43 spans whose
sub-items are bare binary expressions sit under 39 distinct frame phrases, nearly all of them
variants: `Find the value of each sum mentally`, `Find the value of each product`,
`Find the value of each difference`, `Find the unknown value mentally`,
`Find the number that makes each equation true`, `Use the standard algorithm to find the
value of each expression`, `Try using an algorithm to find the value of each sum`,
`Use the base-ten blocks to represent each expression. Then find the value`. The item
markers vary the same way (`1.` and `a.` alongside `•`).

Splitting the 112 by what the frame asks the student to do:

| Frame kind | Spans | Lessons | New lessons | Cohort |
|---|---|---|---|---|
| Evaluate (`find the value of…`, `find the number that makes…`, `use an algorithm to find…`) | 53 | 39 | 21 | 10 |
| Judge or select (`true or false`, `select all`, `circle the equations that match`, `which equation`, `what error`) | 36 | 34 | 30 | 7 |
| No frame phrase in the extract | 20 | 20 | 14 | 4 |
| Representational (`draw an array for each…`, `how does the expression represent…`) | 3 | 3 | 1 | 0 |

Only the first row is safe. Under an evaluation frame the printed expression is the task
and both operands are literal, so a parser generalizing the frame vocabulary would be exact.
**Reach: 53 spans, 39 lessons, 21 lessons gaining a first task instance, 10 of the
210-lesson cohort.**

The judge-or-select row is a trap that looks identical to a string matcher. Its expressions
are *options*, and some are deliberately wrong: `Select all the ways you could represent two
hundred fifty-seven. A. 572 B. 257 C. 200 + 50 + 7 D. 20 + 500 + 7 E. 200 + 40 + 17` and
`Circle the 2 equations that match this story problem. A. 25 + ? = 72 …`. Scraping
expressions from these emits arithmetic the curriculum prints in order to have the student
reject it. A frame-phrase generalization that is not explicitly negated against this
vocabulary would take all 36 along with the 53.

The `true or false` sub-case is a narrower question worth naming rather than deciding here:
`24 = 10 + 14` is exact arithmetic under an evaluation-adjacent frame, but the student's task
is a truth judgment, not a computation, and whether `add(10, 14)` is a true statement about
that task is a modelling decision, not a parsing one.

### The remaining classes

`multiplicative_comparison` (20 spans, 10 lessons, 8 new, 4 cohort) has a genuinely regular
surface — `N times as many/much/tall as` — and the two operands are literal. It is the
smallest safe-looking candidate, and it needs the same referent-agreement check the
equal-groups parsers already carry, because the comparison can run in either direction
(`How many times the number of books as Tyler does Mai stack?` is a division dressed in the
multiplication frame). Reach into the cohort: 4 lessons.

`dimension_geometry_question` (16 spans, 14 lessons, 11 new, 6 cohort) is a near-miss on the
shipped rectangle and prism parsers, differing in frame (`Its sides are 4 feet and 16 feet
long` rather than `a rectangle with side lengths 4 feet by 16 feet`). Operands and units are
literal; unit agreement is already checked. Reach into the cohort: 6 lessons.

`expression_fragment_with_stray_text` (41 spans, 39 lessons) is mostly equivalence and
comparison statements — `3 + 5 = 5 + 3`, `330 < 300 + 3`, `15 - 2 = 13 - 0` — where the task
is to judge the relation, not to evaluate a side. Same modelling question as `true or false`,
and the same answer: exact arithmetic, uncertain task claim.

## Verdict

The tail is not 900 spellings of twelve situations, and it is not 900 distinct pedagogical
situations either. It is around 620 spans that carry numerals without carrying an arithmetic
task, about 250 word problems drawn from a small closed set of situation types whose identity
no sentence-shape equivalence preserves, and about 90 spans of literal arithmetic whose only
barrier is a frame-phrase vocabulary. The first two counts are stated loosely on purpose: the
boundary between them is soft by about thirty spans, and 180 is the number that survives a
test strict enough to ship.

Against the request's question — artifact or genuine — the honest answer is both, in
different places, and the artifact is not the one that was suspected:

- The **955-of-960 singleton count is an artifact**, but of the unit rather than the
  normalization. Number-normalized text at the sub-item level yields 20 clusters of five or
  more with no loosening at all.
- The **irreducibility is genuine** and survives every loosening tested. Collapsing referent
  nouns, container nouns, and proper names together moves the singleton count by four spans
  at the span unit and by 73 at the sub-item unit, and leaves the top twelve clusters
  unchanged. Below that, at N4 and N5, the clusters are large and empty.
- The earlier pass's **recommendation stands, and now has a price attached**: a clustered
  word-problem grammar at the level of abstraction where the clusters are big scores 30/60
  in hand adjudication, and its characteristic failures are inverted operations and numerals
  that were never operands.

What is worth building, in order of certainty per lesson reached:

| Work | Certainty | Spans | Lessons | New lessons | Cohort |
|---|---|---|---|---|---|
| Generalize the evaluation frame vocabulary and the item markers | exact; operands are printed | 53 | 39 | 21 | 10 |
| Extend the rectangle and prism parsers' frames | exact; units already checked | 16 | 14 | 11 | 6 |
| Add a multiplicative-comparison parser with a direction check | exact if the direction check holds | 20 | 10 | 8 | 4 |
| Add situation types to the `story_*` parsers, one at a time, each hand-audited | narrow by construction | — | — | — | ≤ 31 |

The first three together reach at most 20 lessons of the 210-lesson cohort, and they are the
only parser work in this reason that can be done without a hand audit per rule. The no-task
spans should stop being counted as a coverage gap, which is a reason-vocabulary problem
rather than a parser problem. The next section records how far that retyping could honestly
be taken.

## What was retyped, and what was not

The generator now carries a reason `quantities_carry_no_operand_pair`, decided before
`no_task_grammar_for_quantity_pair` in the same cascade. A span falls to it when two or more
quantities survive and the extract carries **no operator printed between two numerals, no
question mark, no demand for a computed result, and no void slot**. Every row records all
five properties, so the test is checkable at the line range the row cites. The reason's kind
is `not_applicable`, which is what drops it out of `lesson_one_parser_away/3`.

| | Before | After |
|---|---|---|
| Spans in the corpus | 3,163 | 3,163 |
| `no_task_grammar_for_quantity_pair` | 960 | 780 |
| `quantities_carry_no_operand_pair` | — | 180 |
| `coverage_gap` spans | 1,284 | 1,104 |
| `not_applicable` spans | 642 | 822 |
| Queue rank 1 (`no_task_grammar_for_quantity_pair`) | 129 cohort lessons | 113 cohort lessons |

The 180 spans cover 152 lessons, 129 of them carrying no compiled task instance, 35 in the
210-lesson cohort.

**This is 180 spans, not the 649 this report grouped as no-task, and the difference is a
defect in the grouping rather than caution about it.** The 649 came from assigning each span
the most task-bearing class among its sub-items and letting a fallthrough class absorb
whatever matched no positive pattern. A test built to reproduce it retypes 30 spans that
carry perfectly reachable tasks, among them `A rectangle is 6 feet by 15 feet. What is the
area?`, `Wyoming is 600 kilometers wide and 452 kilometers long`, and `The space inside the
back of the moving truck is 15 feet long, 5 feet wide, and 8 feet tall` — targets of
rectangle-area, prism-volume, and missing-side parsers the compiler already carries. Marking
those as never reachable would be a worse error than the overstatement being corrected, so
the shipped test is the conservative core: every span it takes carries quantities that no
sentence in the extract puts into an arithmetic relation.

At the boundary the shipped test disagrees with this report's grouping on seven spans, and on
all seven the test is right and the grouping was wrong: a unit-choice prompt, two clue
puzzles, two matching-and-circling prompts, a draw-a-shape-with-this-perimeter prompt, and an
estimation prompt whose operand is not in the extract.

The 476 spans this report grouped as no-task and the shipped test leaves alone carry a
question or a demand whose operands live in a display the markdown dropped — a table, a line
plot, a picture graph, a set of cards, a diagram. 162 of them name that display in words
(`this diagram`, `the table`, `your teacher will give you`). They are unreachable by a text
parser and the extract does not say so, so typing them would take a judgment about where the
operands live rather than a property of the extracted text. A reason for that class is worth
building and would need its own sampling discipline; this analysis did not do that work and
the count above is a scoping measurement, not a finding.

## Limits of this analysis

The class boundaries are my carving and the census behind them is regular expressions over
the extracted text; it mis-sorts at the edges, and the sampled reads rather than the regexes
are what the class descriptions rest on. The 60-item adjudication is one reader's judgment
against the extracted text only, not against the source PDFs; where I marked a parse wrong
because the operand lives in a figure, the item is answerable by a human holding the page
and unanswerable by any text parser, which is the right call for this question and the wrong
one for a different one. The 50% figure is a rate for the specific grammar I wrote; a
different loose grammar at the same level of abstraction would fail differently, but the
seven failure kinds are properties of the corpus rather than of my regexes, and the first
four are unreachable by any equivalence that discards situation type.
