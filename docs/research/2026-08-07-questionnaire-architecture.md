# Questionnaire design: the system-driven decision tree over Hermes's own structure

Date: 2026-08-07. Design brief for codex; staff-neurosymbolic-engineer authored.
Commission (Tio): E2B's context-window/output-token struggles suggest multiple-choice
questionnaires could dial the neuro side into the right part of Hermes. This brief makes
that rigorous. Every strong claim cites file:line or names itself conjecture. Live-probe
claims were run against the worker on 2026-08-07 in the authoring session.

## Stance

The questionnaire is not a quiz the model grades. It is disposition-free control flow
(ceiling report §4, `.superpowers/sdd/task-2026-08-06-neurosymbolic-ceiling-report.md:359-379`):
the SYSTEM walks a fixed tree whose choice sets are compiled from Hermes artifacts; the
model answers one tiny constrained question per call; the leaves are symbolic op
invocations; the engine computes and the model never adjudicates the result. Two lanes:

- **Navigation questions** — multiple choice over Hermes's own carvings (region, family,
  operand shape). These replace the model-invented queries that matched 0/12
  (`docs/research/2026-07-26-mathtutorbench-nine-columns.md:264-293`).
- **Binding questions** — the operand slots, answered by choosing among the numerals
  verbatim in the student's work. Choices carved from the artifact itself carry their
  source spans by construction.

One deliberate refusal: the commission floated "misconception candidates from the ledger
rows reachable at that node" as a question level. That level must not exist. The model
choosing among misconception rows is the model adjudicating (charter: engine computes,
agents never adjudicate; ruling `adjudication-is-not-the-contribution`), and the
fact-extraction run measured what a text-mediated misconception gate carries: gated-shut
violations split 407 no-mistake / 418 real-mistake — no signal — and precision fell to
11.3% (`.bigred-collected/2026-08-02-mistake-location-gated/`, memory
`gemma-fact-extraction-pilot`). The discriminating instrument already exists and takes no
model judgment: `rule_builds/4` abduction on the actual numbers
(`knowledge/misconceptions/misconception_registry.pl:805-812`). Misconception candidates
are engine output, never a model choice.

## 1. The tree

Levels, each with its choice-set source. Fan-out is capped at 7 content choices plus one
mandatory exit ("X — none of these / cannot tell"). A level whose compiled choice set has
exactly one member is skipped — the system binds it; a one-option question manufactures
signal.

| Level | Question | Choice-set source | Fan-out |
|---|---|---|---|
| L0 | (no model) student-work gate, step split, numeral-span harvest | deterministic; regex spans over the excerpt | — |
| L1 | super-region: what is the work mostly doing? | authored partition of the 15 families into 5 groups, shipped as a data file | 5 + X |
| L2 | family within region | the 15-family quotient: `docs/research/assets/automata/family_graph.json` nodes (15 nodes, 105 bundle edges; machine counts 7–50 per family) | ≤5 + X |
| L3 | operand shape within family | distinct input-contract schemas for that family, from `knowledge/strategies/automaton_input_contracts.pl` (246 verified rows) | ≤7 + X (see geometry note) |
| L4 | operand slots, one question per slot | numerals verbatim in the excerpt (spans from L0), scoped to the schema slot | ≤7 + X |
| L5 | the student's final answer (`got`) | numerals verbatim in the final step/line | ≤7 + X |

Verified counts backing the choice sets (computed 2026-08-07; recount before quoting):

- 15 families / 245 machines: `family_graph.json` nodes; scope sentence in
  `docs/research/assets/automata/full_graph.json` meta ("245 computational machines").
- Distinct contract schemas per family: addition 1, subtraction 1, multiplication 1,
  probability 1, division 3, measurement 3, calculus 3, counting 4, decimal 5, ratio 5,
  integer 6, fraction 7, statistics 9, algebraic 13, **geometry 31**. Families with one
  schema (the three whole-number operation families and probability) skip L3 entirely.
  Fraction fits 7+X exactly. Statistics, algebraic, and geometry exceed the cap: the
  choice-set compiler groups schemas by their top-level `"kind"` discriminator and asks
  two staged questions; if a family's grouped set still exceeds 7, that family's L3 is
  served as two pages (offset continuation), never a wider question.
- The L1 partition (authored, vetoable, one data file — the same discipline as the
  hermes-shell accent map): (A) whole-number arithmetic {counting, addition, subtraction,
  multiplication, division}; (B) fractions, decimals, ratios {fraction, decimal, ratio};
  (C) signed numbers {integer}; (D) space and measure {geometry, measurement}; (E) data,
  chance, algebra, limits {statistics, probability, algebraic, calculus}. Authored means
  authored: the file header says so, and the dry-run prints the partition for veto.
- Machine typology (`knowledge/strategies/machine_typology.pl`, `machine_structure/8`) is
  NOT a question level: structural class (linear_trace vs branching) is not something a
  student excerpt attests. It stays diagnosis-side metadata on the receipts.

Worst-case model calls per item: L1 + L2 + L3(≤2) + slots(≤4) + got = **≤9 calls**, each
answering with one letter.

## 2. The call contract

Per question, on the laptop operating point (Ollama, `gemma4:e2b`, the 5.1B Q4_K_M
checkpoint, `docs/research/2026-07-26-mathtutorbench-nine-columns.md:9-12`):

- **Prompt**: instruction header ~80 tokens; excerpt ≤300 tokens for whole-solution
  questions, ≤60 for single-step questions (L4/L5 quote only the step); choices ≤8 lines
  × ~15 tokens ≈ 120. Total ≤ ~500 tokens. This is the fact-pilot's operating point
  (`scripts/research/gemma_hermes_protocol.py:53-124`), which E2B complied with; the
  measured essay-instead-of-contract failure came on a 12,678-token catalog prompt with a
  two-line contract (memory `gemma-checkpoint-configurations`, llama-server). Prompt size
  and contract complexity are the variables this design controls.
- **Output format**: exactly one letter. No confidence number — confidence would be a
  second judgment in the same call, and one judgment per call is the pilot's paid-for law
  (`gemma_hermes_protocol.py:26-27`). Uncertainty is expressed by choosing X.
- **Sampling**: `temperature 0`, `num_predict 8`, `"think": false` per request
  (`gemma_hermes_protocol.py:219`; no server-side think setting exists in this Ollama).
  Stops are never sent to the sampler; the letter is validated on the reply
  (decode-time stops killed the checkpoint mid-thought, nine-columns.md; reply-side
  stops are the house pattern, `hermes/app/llm.py:208-211`).
- **Budget**: cumulative `eval_count` cap per item, 2,500 (pilot precedent; a full item
  spends well under 100 output tokens across ≤9 calls).
- **Why this dodges the starvation leak**: starvation is long reasoning spending the
  generation budget before the answer (`llama-server-budget-trap`;
  `hermes/app/runtime/experiments/reallms_transport_smoke/2026-08-05/02_starvation_leak.json`).
  With think:false there is no reasoning channel to starve, and a one-letter answer
  cannot meaningfully hit `finish_reason: length` at num_predict 8. If a transport with
  channels is ever used (REALLMS), only `outcome == "ok"` is parsed
  (`hermes/app/llm.py:240-245`); `truncated`/`empty_content` route as abstention, never
  as content (glm transport contract).
- **Configuration risk, named**: E2B on llama-server with reasoning off wrote essays
  instead of contracts (memory, 2026-08-04, different prompt scale). Slice 2's live smoke
  measures single-letter compliance before anything else; if compliance fails, the
  fallback is thinking ON with reply-side newline stop and num_predict 256, re-smoked.
  Both configurations keep the answer channel one letter and abstain on non-ok.
- **Position-bias check**: choices are listed in a fixed deterministic order with X last;
  slice 2 asks a sample of questions twice with permuted orderings — a position-flipped
  answer counts as a compliance failure, not as data.

## 3. Abstention and conflict

Every question carries X. No forced choice anywhere; a manufactured choice is
manufactured signal.

| Where | X (or exhausted retry) routes to |
|---|---|
| L1 | terminal `not_covered`, recorded with the excerpt hash — refusal-as-data |
| L2 | reopen L1 once with the previously chosen option masked; second X → terminal |
| L3 | free route: `strategy_recognize(content)` (content-only contract, `hermes/mcp/server.py:91`; its empty list is already an honest abstention) → else terminal |
| L4/L5 | the slot stays unbound; the leaf receives a partial binding and reports `extraction_incomplete`; `rule_builds/4` requires ground input (`misconception_registry.pl:806`) so no abduction fires on a hole — an unbound slot is never filled with a default |
| transport non-ok | one corrective retry at the same budget (pilot precedent: one corrective retry per step), then treated as X |
| invalid letter | same: one corrective retry with the validator's note appended, then X |
| conflict | if retry yields a different valid letter than the first pass, record `conflict` and treat as X — the model never tie-breaks itself |

All abstentions, conflicts, and transport outcomes are first-class records in the item
ledger (ceiling report §2 consequences 2–4).

## 4. What the leaves do

A leaf is reached with: family, operand schema, a ground operand term assembled from
span-carrying numerals, and `got`. The system then computes; no model call adjudicates.

1. **Licensed result**: run the family's productive machine on the bound operands via
   `strategy_trace` (registry-backed names and worked inputs,
   `hermes/mcp/server.py:92`), or `check_math_claim` for explicit claims. Guard operand
   magnitude — grounded arithmetic is quadratic and 5000 is a refusal line (memory
   `enactment-seam-and-arithmetic-traps`).
2. **If `got` ≠ licensed**: abduce via
   `misconception_registry:rule_builds(Domain, InputTerm, Got, Rule)` through
   `prolog_query` (sandbox-licensed at `misconception_registry.pl:826`; read-only, 2 s
   cap, sweep measures in milliseconds per its docstring). Domain comes from an authored
   family→domain data map (the machine families and the misconception domains are
   different vocabularies: 11 domains, ~1,878 encoded rows — fraction 686, whole_number
   582, decimal 211, measurement 111, rational 89, integer 57, discrete 39, percent 34,
   ratio 31, combinatorial 24, geometric 14; grep-counted 2026-08-07). Returned rules
   carry `db_row` citations; `deformation_validity/8` rows (259,
   `knowledge/strategies/deformation_validity.pl`) attach viability modes
   (`objective_invalid` vs `context_sensitive_or_inefficient`) where the abduced rule's
   kind has ledger rows. The reply presents *candidates with citations* in viability
   language — never a diagnosis, never `too_vague` to a web user (ruling
   `misconception-under-erasure`).
3. **If `got` = licensed**: agreement record. An abduced rule that also builds the
   correct answer is a coincidence and is reported as viability context only, never an
   accusation (PUSU contrast semantics: vacuous-at-an-input is not vacuous; inefficiency
   is not error).

**Live-verified finding shaping this design (2026-08-07)**: the front-door
`diagnose_error` op matches only registered exemplar inputs. Probed live:
`diagnose_error(fraction, frac(1,7)-frac(1,7), frac(1,14))` returns db_row(37434);
the structurally identical `frac(1,9)-frac(1,9) → frac(1,18)` returns `[]` — because
`test_harness:diagnose_error/4` unifies the caller's input with each fact's recorded
exemplar (`knowledge/misconceptions/test_harness.pl:314-343`;
`hermes_worker.pl:767-778`). Meanwhile
`rule_builds(fraction, frac(1,9)-frac(1,9), frac(1,18), R)` abduces 5 rules live. The op
description ("whose runnable rule reproduces got for the stated domain and input",
`hermes/mcp/server.py:95`) reads like abduction but the op is exemplar-bound. Slice 1
adds a first-class abduction op rather than silently re-pointing a shipped op's
semantics; the description seam is named for repair in the same slice.

## 5. The falsifier

Cheapest experiment separating the questionnaire arm (Q) from candidate A's typed
quantity compiler, on the frozen 60-index corpus and its paired correct solutions,
exactly per the sanctioned protocol (ceiling report §5; indexes at
`scripts/research/quantity_binding_out/summary.json:2-66`). No MathTutorBench runner,
parser, reward model, or metric. `HUMAN_KIND_MAP` is named target leakage and is
excluded (`scripts/research/quantity_binding_probe.py:48,147`), as is any
target-bearing binding artifact, the final answer, the step index, the category label,
and the human teacher turn.

**Decision rule, fixed now, before any run** (verbatim the sanctioned rule):
first prefer the arm with fewer correct-solution accusations; if tied, prefer the arm
with more licensed differentiating receipts (verbatim span + registered typed op call +
non-`not_checked` verdict, present on the incorrect solution and absent on its paired
correct solution, counted without the labelled target step); if still tied, prefer the
arm with fewer model calls and tokens.

Pre-registered secondary reading (recorded, not part of the decision): the
complementarity count — items where exactly one arm produces a licensed differentiating
receipt — because the honest prediction is complementarity, not victory. These 60 items
are story problems whose measured loss is quantity binding (the 45-red-candles class);
Q's reach is operand-level arithmetic doing. Predicted: Q produces few receipts here but
near-zero correct-solution accusations (its accusation gate is exact arithmetic
difference, step 2 of §4). **If Q produces zero licensed differentiating receipts across
all 60 pairs, the questionnaire is falsified for this corpus shape** — that is a
success condition of the experiment, and it would locate Q's value (if any) on
operand-shaped corpora, a claim this brief does not make.

Dependency, stated honestly: candidate A's compiler does not exist in the tree yet. The
Q-arm half runs alone first and stores its per-item ledger against the same 60 indexes;
A's numbers land beside it later on identical inputs. The decision rule applies only
when both columns exist.

## 6. The honest no

Where multiple choice cannot help, and what those levels need instead:

- **Quantity modelling (referent binding).** L4 binds numerals to operand *slots*, not
  to story *referents*. No Hermes choice set carves "45 counts only the red candles";
  the questionnaire has no level whose choices are referents. This is the ceiling
  report's largest named loss (§1.2) and stays candidate A's territory — the typed
  compiler or the DCG problem-side grammar (Tio's ruling: faithful-by-construction, not
  bigger models; memory `gemma-fact-extraction-pilot`).
- **Step attribution.** A numeral chosen from the whole excerpt can be the right value
  from the wrong step; the measured signed-offset spread was symmetric attribution
  noise, not a fixable shift. Span-carrying choices mitigate location of the *numeral*,
  not attribution of the *step*. Exact mistake location (§1.3) inherits this.
- **Judgment questions.** A well-formed two-choice composition question ("is the total
  the parts together?") was answered wrongly by E2B (pilot memory, size-gated).
  Multiple choice repairs format compliance, never judgment quality. Any question whose
  answer is a judgment rather than a reading routes to the grammar or abstains — it is
  never asked of E2B.
- **Generation columns.** Scaffolding, pedagogy following, Socratic questioning (§1.1,
  §1.5): no questionnaire level touches teacher-turn quality. Candidate D's territory,
  after A or B earns trustworthy receipts.
- **Student-register recognition.** The free route at L3 falls back to
  `strategy_recognize`, whose student-prose top-1 is 0.042
  (`docs/research/2026-08-01-strategy-recognize-discrimination.md:338-348` via ceiling
  report §1.7). The fallback is honest, not strong. Whether family-level questions with
  plain-language glosses out-navigate the recognizer on student prose is a testable
  conjecture — slice 2 collects the first evidence, and no more is claimed.

## 7. Codex handoff

New code under `scripts/research/questionnaire/`; reuse `MCPClient` from
`gemma_hermes_protocol.py:229-278` (import, do not fork). Authored data files (region
partition, family→domain map) carry headers naming themselves authored and vetoable.

**Slice 1 — choice-set compiler, tree runner, dry-run (no model, no network).**
`build_choice_sets.py` compiles L1–L3 sets from `family_graph.json`,
`automaton_input_contracts.pl`, and the two authored maps; `runner.py` walks the tree
with an injected model client and transport-typed outcomes; leaves call the stdio MCP
(`--mode core`). Includes the new first-class abduction op (worker + registry row +
regenerated `capability_registry.pl` via `scripts/extract_capability_registry.py`) and
the `diagnose_error` description repair (§4). Verification, sandbox-safe:
`dry_run.py` with a scripted FakeModel asserts — every family reachable; every choice
set ≤ 8 including X; single-option levels skipped; every leaf call validated against the
family's `automaton_input_contract` example shape; every abstention route terminates;
zero network sockets. It prints the route census and the authored partitions for veto.

**Slice 2 — live E2B compliance smoke (minutes, laptop).** Three authored worked items —
invented, NOT drawn from the frozen corpus (that corpus is reserved for the falsifier;
this is the leakage boundary) — through Ollama `gemma4:e2b`, think:false, per §2.
Measures: valid-letter rate (gate ≥ 90%), non-ok transport rate, position-permutation
flips. Verification: the smoke writes a JSON ledger; a checker script asserts the gate
and that no non-ok content was ever parsed. Wildcat rules hold: short local run only.

**Slice 3 — position-bias mitigation (specified in §8 below, from the 2026-08-07 live
measurement).** The falsifier's Q-arm half moves to **slice 4 (HELD for Tio's go)**:
60 indexes × paired solutions per §5, ledger stored beside `quantity_binding_out/`
conventions. Batch scale (~1,000 model calls) runs on Big Red per the wildcat rules, or
an explicitly approved local overnight. The decision rule is already fixed in §5; the
run may not begin, and no number from it may be quoted, before Tio's word.

Every slice ends with the full gate chain unchanged; nothing here touches the formal
core, so no byte-equivalence proofs are triggered — but the registry regeneration in
slice 1 must ship in the same commit as the new op (count-pin cascade recipe).

## 8. Position bias, measured (added 2026-08-07, after the first live smoke)

Slices 1–2 are committed (14cc6cee, 5089cd98). The first live compliance smoke
completed all 3 items and 13 permutation pairs, then failed its own gate: 6 of 13
pairs flipped semantic answer under choice reordering (ledger written before the
assertion; summary row `position_permutation: pairs 13, flips 6, pass false`). To
quantify, a full rotation grid ran the same 3 authored items with every question asked
in all K content rotations plus a rotation-0 repeat: 70 live E2B calls, 33.8 s,
13 questions. Script and raw grid sit beside this doc
(`task-2026-08-07-position-grid.py`, `task-2026-08-07-position-grid-result.json`);
the script imports the committed modules unchanged and routes on the compiled-order
answer, so trajectories match the committed smoke.

### What the grid shows

1. **No coin-flipping anywhere.** The rotation-0 repeat was identical on 13/13
   questions — temperature-0 determinism holds; every effect below is a deterministic
   function of choice order.
2. **Navigation (L1/L2) is content-anchored.** L1 tracked `whole_number_arithmetic`
   through every rotation on all items (18/18 asks); L2 tracked the family perfectly on
   the addition and multiplication items (12/12). Aggregate navigation truth: 33/36.
   The one L2 failure is content confusion, not formatting: on `53 - 18` the model sits
   between `division` and `subtraction` (3/6 each), and the tie breaks by late position
   (5 of 6 asks landed on position D or E regardless of which family sat there). The
   compiled-order answer was `division`, which then routed the item into division's L3
   and leaf — a misroute the smoke's flip check is what caught.
3. **L4 numeral binding carries a hard anti-first-position pull.** Across 30 slot asks
   the chosen position histogram is A:0, B:15, C:10, D:5 — the model never selects the
   first-listed numeral. The regularity is exact for slot /a: it tracks the true first
   operand at any non-first position (12/12 across rotations on all three items) and
   substitutes another numeral whenever the truth is listed first (0/3). Because the
   committed compiler lists spans in source order, the true /a binding always sits at
   A compiled — the maximal collision, and the source of the smoke's flip cluster.
   Slot /b adds a content-level attraction to the equation's result numeral (the
   multiplication item never chose the true `7` in any of five /b asks — `42` three
   times, `6` twice; /b truth 4/15 vs /a 9/15). Aggregate L4 truth: 13/30 against a
   0.25 uniform floor.
4. **Excerpt-indiscriminable labels lock to A and never abstain.** The division L3
   question (3 opaque schema labels the excerpt gives no evidence to separate) chose
   letter A in 4/4 rotations — a different key every time. The honest answer was X;
   across all 70 asks in the grid, **X was chosen zero times**. The abstention exit
   exists and E2B never takes it. Abstention must be system-derived (validator and
   binding failures); it can never be expected from the model's own modesty. This is
   the charter's disposition finding surfacing in a new place.

### The ruling

Mixed, by measured level, consistent with system-asks/model-answers, one judgment per
call, and abstention over manufactured signal:

- **L1/L2 keep single-letter multiple choice.** Measured content-anchored (33/36) with
  position-spread histograms; no change. One deterministic addition at L0: when the
  excerpt carries an explicit operator token (`+`, `-`, `×`/`times`, `÷`/`/` in an
  equation line), the system binds the family from the token and asks no navigation
  question. This removes the one observed misroute class (division-for-`53 - 18`)
  without a model call. Prose excerpts still route through L1/L2.
- **L4/L5 abandon choice-selection for constrained transcription.** Selection asks the
  model to do the harness's span bookkeeping, and the measurement says it cannot
  (anti-first pull plus result-numeral attraction; 13/30). Transcription is the
  fact-pilot's measured strength (extraction reach 1,878/2,004; memory
  `gemma-fact-extraction-pilot`). For symbol-form work one call transcribes the
  equation ("Write the student's operation exactly as written"); the validator accepts
  only output whose numerals all appear verbatim in the excerpt (the
  `keep()`-pattern regex discipline, `gemma_hermes_protocol.py:281-289`); the system
  parses slots and `got` from the transcription and recovers spans by exact-text
  match, so verbatim provenance is preserved. A transcribed numeral absent from the
  excerpt → one corrective retry → abstention. Duplicate-text spans (42 twice) are
  value-identical for term building; provenance cites both. For prose work, per-slot
  `given()`-style questions as in the pilot. Call count per item drops (one
  transcription call replaces 2–3 slot questions plus L5).
- **L3 with excerpt-indiscriminable labels is not asked.** Bind operands first; the
  system selects the schema whose contract slots all bind (engine-side, deterministic).
  Only if two or more schemas fully bind does a model question remain, and it must be
  an excerpt-anchored yes/no (one binary per call, X preserved) — never a choice among
  labels the excerpt cannot separate.
- **Refused: K-permutation majority voting.** It multiplies calls 4–5× and, replayed
  on this grid, still loses the /b slots (majority key is the result numeral on 2 of 3
  items) — it launders a content-level error into a confident vote. Manufactured
  signal.
- **Refused: position-debiased scoring.** A statistical bias model between the answer
  and the route is an unauditable layer that converts a measured pathology into
  invisible correction. The receipts must stay readable.

Token math after the ruling: transcription output ≤ 16 tokens (`27 + 15 = 42`), so
`num_predict` rises to 24 for binding calls only; prompts shrink (no choice block).
Navigation calls unchanged. Worst-case model calls per item drop from ≤9 to ≤6
(operator-gated symbol items: 1–2). The eval-count cap 2,500 stands untouched.

### Slice 3 — codex brief (mitigation build)

Scope: `scripts/research/questionnaire/` only; no formal-core contact.

1. **L0 operator gate** in `runner.py`'s pre-navigation pass: regex over equation
   lines for the four operator tokens; on a unique token, bind family deterministically
   and record `l0_operator_bound` in the ledger; ambiguous or absent → L1/L2 as today.
2. **Binding rework**: replace the L4/L5 span-choice questions with the transcription
   call for symbol-form excerpts (new prompt in `call_contract.json`, verbatim-presence
   validator, span recovery by exact-text match, `num_predict` 24 for binding calls);
   keep per-slot questions only for prose excerpts, reworded to the pilot's `given()`
   shape. Every non-verbatim transcription: one corrective retry, then
   `extraction_incomplete` — never a default fact.
3. **Schema selection by binding**: move L3 after binding; select engine-side by
   contract conformance (`conforms()` in `build_choice_sets.py`); residual ties ask
   excerpt-anchored binaries; delete the label-choice L3 question.
4. **Smoke update**: `compliance_smoke.py` keeps the flip gate at 0 for the remaining
   letter questions (L1/L2); adds a transcription-fidelity gate (every accepted
   binding verbatim-present); the fixture transports updated to the new shapes.
   The authored smoke set gains one prose-form item so the per-slot lane stays
   exercised.
5. **Verification, sandbox-safe**: `--fixture` run green with zero sockets;
   `dry_run.py` route census updated (operator-gated route, binding-first schema
   selection, binary residual); then one live smoke (minutes, wildcat rules) with the
   full gate re-armed — expected: flips 0 on navigation, all bindings verbatim, and
   the three authored items leaf-computed in their own families (the `53 - 18`
   misroute must be gone via the operator gate).

The falsifier (slice 4) stays exactly as specified in §5 and stays held; nothing in
this section changes its decision rule.
