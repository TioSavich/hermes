# Wave 5 target grammar

Date: 2026-08-12. Status: closed S1 grammar for review before S2.

This grammar defines the supervised language for Wave 5. A model authors a
bounded problem representation. The system executes that representation. The
registered machine remains the source of the answer and verdict.

## Lexical forms

`atom` is a lowercase Prolog atom beginning with a letter. `number` is an
integer, decimal, `fraction(N,D)`, or `mixed(W,N,D)` value copied from the
mapped operation. `machine` is a registered machine name. Machine inputs use
JSON-compatible dictionaries. Values for `kind`, `unit`, `scope`, and other
kind tags are strings, not Prolog atoms.

The demand lexicon is fixed at S1 as:

`analyze`, `calculate`, `choose`, `compare`, `complete`, `construct`,
`convert`, `describe`, `determine`, `draw`, `estimate`, `evaluate`, `explain`,
`fill`, `find`, `give`, `graph`, `identify`, `justify`, `label`, `list`,
`make`, `match`, `name`, `order`, `plot`, `prove`, `represent`, `select`,
`show`, `simplify`, `solve`, `sort`, `state`, `tell`, `verify`, `what`,
`when`, `where`, `which`, `who`, `why`, and the two-token demand `how many`.

A question mark also supplies an interrogative demand. A recovered expression
list is actionable when a referent carries a nonempty instruction antecedent
containing one of the imperative tokens above. The bullet separator is not a
demand. A bare expression or sentence shard does not pass the demand rule.

## Input shape

A row that already contains one demand uses its culled complete statement. A
row whose provenance position selects a member of a list uses the authored
instruction antecedent joined to that one expression or question span.
Numbered `activity_*_item(N)` positions select numbered student item `N`, not
a teacher-response excerpt shared by several items. If a compound row still
maps one input span to several programs, the input also names the one
mechanically mapped operation. The complete statement remains in provenance
for display and is not substituted for an item-scoped training input.

Every mint enforces zero `(split, input)` groups with differing outputs. A
nonzero count blocks artifact generation.

## Solution shape

```ebnf
solution       = quantity_fact, { quantity_fact }, asks_fact, solve_clause ;
quantity_fact  = "quantity(", role, ", ", number, ", ", referent, ")." ;
asks_fact      = "asks(", answer_role, ", ", referent, ")." ;
solve_clause   = "solve(A) :- hermes_encyclopedia:strategy_trace_dict(",
                 machine, ", ", input_dict,
                 ", D), get_dict(result, D, A)." ;
```

Every numeral in a fact is bound to a statement-derived unit or referent. The
goal names a registered machine. An operation family such as `addition` is not
a legal goal target. S1 mints one solution program for each admitted,
machine-mapped row whose referent can be extracted mechanically.

Illustrative example, not a literal mint template:

```prolog
quantity(books_present, 5, books).
quantity(books_added, 2, books).
asks(total, books).
solve(A) :- hermes_encyclopedia:strategy_trace_dict(
    count_on_from_larger, _{a:5, b:2}, D),
    get_dict(result, D, A).
```

## Diagnosis shape

```ebnf
diagnosis      = quantity_fact, { quantity_fact }, observed_fact, test_clause,
                 verdict_block ;
observed_fact  = "observed_answer(", number, ")." ;
test_clause    = "test(V) :- ", registered_contrast_goal, "." ;
registered_contrast_goal
               = "lesson_arithmetic_demonstration:lesson_arithmetic_demonstration_dict(",
                 lesson, ", ", task_id, ", O, \"\", D), get_dict(reading, D, V)"
               | "observed_answer(O), wave5_diagnosis_route:receipt_contrast_verdict(",
                 operation, ", ", productive_machine, ", ", contrast_machine,
                 ", ", input_dict, ", O, V)" ;
verdict_block  = "verdict{status:", status,
                 ", misconception_family:", family,
                 ", located_step:", engine_step,
                 ", viability_context:", engine_context, "}." ;
status         = "productive_trace"
               | "candidate_deformation(human_endorsement_required)"
               | "correct_but_inefficient" ;
```

This is the closed contrast-route list. `lesson_arithmetic_demonstration_dict/5`
is the lesson-bounded route for its four registered tasks.
`receipt_contrast_verdict/6` is the corpus route: it runs the named productive
and contrast machines on the supplied wire-genre input, requires the observed
answer to equal the selected machine's result, and returns the engine verdict.
No direct operation-family goal, unregistered helper, or stored receipt lookup
is a legal `test/1` target.

The verdict block is copied verbatim from a fresh execution of the pair's own
test program. `misconception_family` is the registered name. `located_step` is
the engine's step term. `viability_context` is the engine value when supplied,
and the explicit atom `not_emitted` otherwise. A stored block that does not
match fresh execution blocks the pair. At serving time the engine's block is
authoritative.

Illustrative shape only:

```prolog
quantity(starting_amount, 53, objects).
quantity(amount_removed, 27, objects).
observed_answer(34).
test(V) :- registered_productive_deformation_contrast(V).
verdict{status:candidate_deformation(human_endorsement_required),
        misconception_family:smaller_from_larger_in_column,
        located_step:lose_minuend_subtrahend_roles(expected(26),produced(34)),
        viability_context:not_emitted}.
```

Diagnosis pairs are an S2 deliverable. S1 fixes their language so that the S2
variant census cannot change the target after examining its volume.

## Four design laws

1. Every numeral in facts carries a statement-derived unit or referent. A bare
   numeral in a fact is a mint defect.
2. Every solve or test goal names a registered machine or registered
   demonstration/contrast route. Operation-family names alone are forbidden.
3. A program does not adjudicate its own diagnosis. The engine emits the
   status, registered misconception family, located step, and available
   viability context. Stored diagnosis text is a verbatim execution receipt.
4. Output is bounded. The S1 solution bound is 256 whitespace-delimited
   tokens. S2 measures the longer diagnosis form and fixes its bound before
   training. A bound violation is excluded and counted; no output is
   truncated. Kind-tagged machine values are strings.

## Mint-time admission and text culling

Rows pass four ordered gates. Status must be `already_complete`, `recovered`,
or `recovered_with_referent`. `visuals` must be empty, and an unresolved
image- or diagram-kind referent excludes the row. Every referent must have a
resolved status and `absence_reason:none`. Finally, the complete statement
must contain the fixed demand lexicon, a question mark, or an instruction
antecedent joined to its expression list. Each row is attributed to its first
failing gate so exclusion counts sum to the frozen pool.

Mint input culling is deterministic and versioned as
`wave5-culling-v1`: paired `$...$` delimiters are removed while their contents
remain; an unpaired dollar sign immediately before a numeral remains as
currency; each `•` separator becomes ` ; `; whitespace is collapsed. The mint
checks that no paired-dollar span remains, currency-dollar count is conserved,
and the separator transform is deterministic. Source and display stores are
read only.

## Split and contamination rules

The split unit is a lesson. Train and held-out assignments are stratified by
grade, operation family, and genre (`word_problem` or
`expression_fragment`). No lesson may occur in both partitions. Every minted
input passes the local benchmark 13-gram index. Training inputs are also
checked against admitted held-out lesson text with an 8-gram gate. Held-out
rows use the same item scoping when a scored row is available and retain
complete source text when a later mapping, engine-guard, or referent-extraction
gate excludes the row. A hit excludes and records a pair; benchmark text never
enters a Wave 5 artifact.
