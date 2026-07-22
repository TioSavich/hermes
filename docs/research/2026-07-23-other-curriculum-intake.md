# Other-curriculum intake: VMC, CMP, and EM4 transcripts

## Method

This is an offline, read-only survey of the sibling checkout. For every map row it checks the named raw and converted files, resolves the transcript filename against the blind manifest, and accepts a pairing only when a substantial spoken-prompt span occurs in the corresponding blinded markdown. The source-path match alone is not treated as verification. Coverage names are checked against Hermes's current action-automata registry and `safe_math_claim_shape/1` surface. Resonance results use the stored misconception vectors locally; no embedding request is made.

## Inventory and verified map

| Transcript | Curriculum / grade | Task | Raw source | Converted source | Blind ID | Prompt evidence | Pairing |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Video Mosiac 11th grade World Series 2.xlsx | Video Mosaic Collaborative (VMC) / 11th Grade | VMC-WORLD-SERIES | present; PDF parsed | present; Markdown parsed | tm_0138 | S06: There's seven games in a World Series. S06: What are the chances the World Series will be won in four games, five games, six games and seven games. | verified |
| Video Mosaic Grade 3 Shirts and Pants 2.xlsx | Video Mosaic Collaborative (VMC) / 3rd Grade | VMC-SHIRTS-PANTS | present; PDF parsed | present; Markdown parsed | tm_0534 | S02: Well do it and see okay? S02: Remember so you got the same  three shirts and the same two pairs of pants but now you got  a new pair of pants for Christmas. | verified |
| Towers 1_Grade 4.xlsx | Video Mosaic Collaborative (VMC) / 4th Grade | VMC-TOWERS | present; PDF parsed | present; Markdown parsed | tm_0469 | S01: Okay, this is (inaudible). S02: Did everybody figure out how many different towers they  can make? | verified |
| Towers 2_Grade 4.xlsx | Video Mosaic Collaborative (VMC) / 4th Grade | VMC-TOWERS | present; PDF parsed | present; Markdown parsed | tm_0393 | — | unverified |
| Ladder problem 1_ Grade 7.xlsx | Video Mosaic Collaborative (VMC) / 7th Grade | VMC-LADDER | present; PDF parsed | present; Markdown parsed | tm_0501 | S01: Does it look like one? S01: In this particular case, what would you call this if we called this a ladder? | verified |
| What is one half 1_Grade 4.xlsx | Video Mosaic Collaborative (VMC) / 4th Grade | VMC-ONE-HALF-CUISENAIRE | present; PDF parsed | present; Markdown parsed | tm_0382 | S05: They're  not exactly the same, but they're both  halves. S05: Because the purple would be half of  this even though the yellow is bigger  because if you put the purple on the bottom  and the yellow on top it's equal, so they're  both halves, but only one's bigger than the  other. | verified |
| Martino Fraction Equivalence 1_Grade 4.xlsx | Video Mosaic Collaborative (VMC) / 4th Grade | VMC-MARTINO-EQUIVALENCE | present; PDF parsed | present; Markdown parsed | tm_0543 | S01: Yeah, because I think you have the idea, I  think I'm just not understanding it. S05: If you put all the whites you could up against  it and you, and you double  them up… If you put two whites together to  make one block, it would be a red block. | verified |
| Video Mosaic Grade 4 Alans Infinity.xlsx | Video Mosaic Collaborative (VMC) / 4th Grade | VMC-ALANS-INFINITY | present; PDF parsed | present; Markdown parsed | tm_0371 | S01: You could divide that, you could divide from zero to one it’s the smallest of fractions. | verified |
| TalkBack.Year1.Gautier.Spring.031020.xlsx | Connected Mathematics Project (CMP) / 8th Grade | CMP-LFP-PROB1.1 | missing | missing | tm_0296 | S01: All right, people, so we are going to watch a very quick video. S01: If you could, as I'm loading the video, if you could please open up your Looking for Pythagoras book to page seven. | verified |
| TalkBack.Year2.Strathom.Spring.020221.xlsx | Everyday Mathematics (EM4) / 4th Grade | EM4-G4-L3.8 | missing | missing | tm_0350 | S01: A ll right. S01: So today our learning intention for lesson 3.8. | verified |
| TalkBack.Year1.Tolliver.Fall.121019.xlsx | Everyday Mathematics (EM4) / 4th Grade | EM4-G4-L4.9 | missing | missing | tm_0429 | — | unverified |
| TalkBack.Year2.Strathom.Spring.040621.xlsx | Everyday Mathematics (EM4) / 4th Grade | EM4-G4-L5.10 | missing | missing | tm_0541 | S01: Okay, so our learning intention today is; I can use area model to find fraction products. | verified |

## Coverage join and next-slice proposals

### VMC-WORLD-SERIES — World Series Problem

- Registry domains: probability; combinatorial.
- Fitting claim shapes: multiplication/3.
- Runnable seam: probability action automata; no outcome-sequence contract (live names verified).
- Offline resonance: seed `arrangement_as_combination_sum`; nearest stored rows: `blind_combine_numbers` (0.736), `overlap_overcount_combinatorics` (0.689), `cartesian_product_as_one_to_one` (0.645). This is a retrieval lead, not a diagnosis of a speaker.
- Verdict: needs specific coverage: a best-of-seven outcome-sequence contract and probability claim shape.
- Next slice: Add one VMC task-statement fact with equal-team assumption, series length, and outcome space; then a compact probability monitoring chart.

### VMC-SHIRTS-PANTS — Shirts and Pants (Outfits) Problem

- Registry domains: counting; combinatorial.
- Fitting claim shapes: multiplication/3.
- Runnable seam: counting and multiplication action automata; no Cartesian-product contract (live names verified).
- Offline resonance: seed `blind_combine_numbers`; nearest stored rows: `arrangement_as_combination_sum` (0.736), `juxtapose_unit_totals` (0.732), `add_instead_of_multiply` (0.714). This is a retrieval lead, not a diagnosis of a speaker.
- Verdict: needs specific coverage: an outfit/Cartesian-product task contract.
- Next slice: Add one VMC task-statement fact for shirt/pants choices and a counting-table monitoring chart.

### VMC-TOWERS — Building Towers Problem

- Registry domains: counting; combinatorial.
- Fitting claim shapes: arithmetic_equation/3.
- Runnable seam: counting action automata; no colored-tower enumeration contract (live names verified).
- Offline resonance: seed `guess_recursive_partition`; nearest stored rows: `guess_denom_from_prior` (0.852), `guess_total_parts_for_fraction_of_fraction` (0.813), `part_to_part_as_part_whole` (0.806). This is a retrieval lead, not a diagnosis of a speaker.
- Verdict: needs specific coverage: a height-and-colour tower generator with its count invariant.
- Next slice: Add one shared VMC Towers fact plus transcript-specific prompt evidence; chart the generate/count/prove moves.

### VMC-TOWERS — Building Towers Problem

- Registry domains: counting; combinatorial.
- Fitting claim shapes: arithmetic_equation/3.
- Runnable seam: counting action automata; no colored-tower enumeration contract (live names verified).
- Offline resonance: seed `guess_recursive_partition`; nearest stored rows: `guess_denom_from_prior` (0.852), `guess_total_parts_for_fraction_of_fraction` (0.813), `part_to_part_as_part_whole` (0.806). This is a retrieval lead, not a diagnosis of a speaker.
- Verdict: needs specific coverage: a height-and-colour tower generator with its count invariant.
- Next slice: Add one shared VMC Towers fact plus transcript-specific prompt evidence; chart the generate/count/prove moves.

### VMC-LADDER — The Ladder Problem

- Registry domains: algebraic; geometry.
- Fitting claim shapes: arithmetic_equation/3.
- Runnable seam: algebraic and geometry action automata; no ladder-growth contract (live names verified).
- Offline resonance: no named row is close enough from the task statement alone; none is claimed.
- Verdict: needs specific coverage: a figural-growth/ladder rule contract.
- Next slice: Add one VMC ladder task-statement fact with figure index, units, and expected growth relation; then a pattern-rule chart.

### VMC-ONE-HALF-CUISENAIRE — What is One Half / Relative Fraction Units

- Registry domains: fraction.
- Fitting claim shapes: equivalence/2; fraction_of/3.
- Runnable seam: fraction action automata (live names verified).
- Offline resonance: seed `loss_of_whole`; nearest stored rows: `total_count_as_denom` (0.873), `numerator_as_piece_count` (0.836), `denom_follows_total_pieces` (0.832). This is a retrieval lead, not a diagnosis of a speaker.
- Verdict: analyzable today for unit-relative fraction claims; needs a Cuisenaire referent fact for a lesson-grain chart.
- Next slice: Add one VMC task-statement fact naming rod relations and the chosen whole; reuse a fraction monitoring chart with a referent column.

### VMC-MARTINO-EQUIVALENCE — Martino Fraction Equivalence

- Registry domains: fraction.
- Fitting claim shapes: equivalence/2; multiplication/3.
- Runnable seam: fraction action automata (live names verified).
- Offline resonance: seed `additive_equivalence`; nearest stored rows: `equivalent_by_adding` (0.953), `additive_equivalence_pattern` (0.935), `equiv_additive_misapplication` (0.916). This is a retrieval lead, not a diagnosis of a speaker.
- Verdict: analyzable today for equivalence claims; needs the rod-composition task data to trace the transcript faithfully.
- Next slice: Add one VMC task-statement fact for rod compositions/equivalent units and a fraction-equivalence monitoring chart.

### VMC-ALANS-INFINITY — Alans Infinity Problem

- Registry domains: fraction; calculus.
- Fitting claim shapes: number_line_position/2.
- Runnable seam: fraction and calculus action automata; no density/infinite-subdivision contract (live names verified).
- Offline resonance: no named row is close enough from the task statement alone; none is claimed.
- Verdict: needs specific coverage: a between-any-two-fractions/density contract.
- Next slice: Add one VMC task-statement fact for the interval and subdivision operation; propose a number-line/density chart after the contract exists.

### CMP-LFP-PROB1.1 — Looking for Pythagoras: Problem 1.1 Driving Around Euclid & Problem 1.2 Planning Parks

- Registry domains: geometry; measurement.
- Fitting claim shapes: shape_property/2; arithmetic_equation/3.
- Runnable seam: geometry and measurement action automata (live names verified).
- Offline resonance: no named row is close enough from the task statement alone; none is claimed.
- Verdict: needs specific coverage: coordinate-distance/Pythagorean task facts and a theorem-justification claim shape.
- Next slice: Add one CMP task-statement fact for coordinates, route/park constraints, and distance relation; then a geometry monitoring chart.

### EM4-G4-L3.8 — Lesson 3-8: Rename Mixed Numbers

- Registry domains: fraction.
- Fitting claim shapes: improper/1; equivalence/2.
- Runnable seam: fraction action automata (live names verified).
- Offline resonance: seed `whole_as_unit_fraction`; nearest stored rows: `wrong_referent_unit` (0.869), `merge_wholes_as_unit` (0.858), `one_as_unit_fraction` (0.854). This is a retrieval lead, not a diagnosis of a speaker.
- Verdict: analyzable today for symbolic mixed/improper equivalence; needs EM4 representation details for lesson-grain treatment.
- Next slice: Add one EM4 lesson fact for the rename forms and fraction-circle/area-model referents; reuse a fraction monitoring chart.

### EM4-G4-L4.9 — Lesson 4-9: Multi-Digit Multiplication using Partial Products

- Registry domains: multiplication; place value.
- Fitting claim shapes: multiplication/3; arithmetic_equation/3.
- Runnable seam: multiplication action automata (live names verified).
- Offline resonance: seed `partial_products_no_shift`; nearest stored rows: `partial_products_no_place_shift` (0.972), `no_cross_multiply_digits` (0.817), `partial_products_decimal_error` (0.816). This is a retrieval lead, not a diagnosis of a speaker.
- Verdict: analyzable today for partial-product arithmetic; needs the EM4 decomposition convention and examples.
- Next slice: Add one EM4 lesson fact for place-value decomposition and partial-product recombination; use a multiplication monitoring chart.

### EM4-G4-L5.10 — Lesson 5-10: Fraction Multiplication & Area Models

- Registry domains: fraction; multiplication; geometry.
- Fitting claim shapes: multiplication/3; fraction_of/3.
- Runnable seam: fraction and multiplication action automata (live names verified).
- Offline resonance: seed `area_model_count_addition`; nearest stored rows: `mc1_add_by_part_count` (0.851), `piece_count_denom` (0.847), `componentwise_addition` (0.836). This is a retrieval lead, not a diagnosis of a speaker.
- Verdict: analyzable today for fraction-product claims; needs the area-model partition contract.
- Next slice: Add one EM4 lesson fact for both factors, whole rectangle, and cross-hatched region; use an area-model monitoring chart.

## Boundary

10 of 12 map rows have a source-path match plus prompt evidence. No non-IM curriculum facts or monitoring charts were written. The proposals above are sized follow-on slices, not assertions that the current IM lesson machinery already covers these tasks.

## Verified map table

| Task | Blind ID | Verified pairing |
| --- | --- | --- |
| VMC-WORLD-SERIES | tm_0138 | verified |
| VMC-SHIRTS-PANTS | tm_0534 | verified |
| VMC-TOWERS | tm_0469 | verified |
| VMC-TOWERS | tm_0393 | unverified |
| VMC-LADDER | tm_0501 | verified |
| VMC-ONE-HALF-CUISENAIRE | tm_0382 | verified |
| VMC-MARTINO-EQUIVALENCE | tm_0543 | verified |
| VMC-ALANS-INFINITY | tm_0371 | verified |
| CMP-LFP-PROB1.1 | tm_0296 | verified |
| EM4-G4-L3.8 | tm_0350 | verified |
| EM4-G4-L4.9 | tm_0429 | unverified |
| EM4-G4-L5.10 | tm_0541 | verified |

IMPLEMENTATION_COMPLETE
