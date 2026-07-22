# What discourse analysis runs with no LLM at all

This note records the deterministic path available in the live checkout on
2026-07-21. It distinguishes a runnable computation from a reader's judgment.
The new claim reader compiles explicit surface arithmetic statements; it does
not infer a speaker's meaning, fill in omitted operands, or classify a turn.

## Inventory

| Layer | Input | Yield | Reachable from a raw transcript without a model call? | Verified seam |
| --- | --- | --- | --- | --- |
| Ingest, blinding, and numbering | A delimited table or `Speaker: utterance` text | Local `HermesEvent` records, blinded `S01` aliases, and `U0001` lines | Yes | `hermes/app/analysis/ingest.py:ingest`, `scripts/talkmoves_two_pass.py:blind_transcript`, `scripts/talkmoves_score_blind_corpus.py:number_transcript` |
| Math-claim adjudication | Ground typed claim JSON | A Prolog verdict and trace | Yes, after the deterministic claim reader supplies typed claims | `scripts/talkmoves_two_pass.py:adjudicate_claims` -> `hermes/math_claim_checker.pl:check_math_claim/2` |
| Masking, verdict arcs, and claims tension | Numbered transcript plus adjudicated claim objects | Verbatim-checked mask, refuted-claim timeline arcs, and cross-speaker shared-fraction joins | Yes, after typed claims exist | `scripts/talkmoves_two_pass.py:mask_transcript`, `verdict_arcs`, `claims_tension` |
| Uptake joint | Pass-2 readings with PML and uptake objects | Grouped `(operator, force, mode, fate)` counts | No. The input readings require a reader/model. | `scripts/talkmoves_two_pass.py:uptake_joint` |
| Deontic scoreboard | Two-pass readings and/or adjudicated claim terms | Per-speaker and pooled commitment boards | Partially. Claims can supply deterministic commitment terms, but this checkout lacks the required `scripts/pml_deontic_scoreboard_layer.py` module. | `scripts/talkmoves_two_pass.py:deontic_events_from_two_pass`, `pool_events_cross_speaker`; missing layer named by `run_deontic` |
| Elaboration detector and strategy graph | Strategy-transition patterns, not utterances | Pairwise pattern overlap/elaboration records | No. It analyzes registered strategy modules rather than a transcript. | `knowledge/strategies/meta/elaboration_detector.pl:compute_elaborations/2`, `automaton_analyzer.pl:analyze_all/0` and `all_elaborations/1` |
| Comparison machines | Grounded mathematical/state-machine inputs | A strategy or comparison trace | No raw-transcript adapter was found. | `knowledge/strategies/math/smr_*compare*` modules; checker routes through `math_claim_checker.pl:check_math_claim/2` for registered claim shapes |
| Generative misconceptions and scorekeeping | Registered deformation pairs or metaphor break facts, then an explicit agent enactment | Candidate misconception terms and commitment-without-entitlement records | No. It generates from registered formal data, not from language. | `knowledge/misconceptions/generative_misconceptions.pl:misconception/1`; `misconception_scorekeeping.pl:enact_misconception/2` |
| Rhythm/witness layer | No transcript-reader seam found in `scripts/`, `hermes/`, or `knowledge/` | No deterministic transcript result established | BLOCKED: the available rhythm material is prompt/prose-oriented, not a verified transcript parser. | Search completed over Python, Prolog, and Markdown sources; no seam to run |

The checker, misconception layer, and elaboration analyzer were loaded or run
directly. The analyzer produced 157 elaboration records in this checkout. The
deontic layer is a concrete integration block, not evidence that a board ran.

## Conservative deterministic claim reader

`scripts/research/deterministic_claim_reader.py` accepts numbered `U#### S##:`
lines and returns pass-1-compatible claim objects. Each object contains the
verbatim matched `surface`, lowercase `utterance_id`, registered `shape`, and
typed `args`; `scripts/talkmoves_two_pass.py:adjudicate_claims` adds the
existing `term` and verdict fields.

It only accepts complete, explicit forms for fraction equivalence, fraction of
a whole-number quantity, multiplication, division as a registered generic
arithmetic equation, whole-number addition, and whole-number subtraction.
It accepts numerals and a deliberately small number-word vocabulary, including
the supplied forms such as `nine times three is twenty-seven`, `14 divided by
3/4 is 18 and 2/3`, `2/4 is equal to 1/2`, and `three fourths of twelve is
nine`.

Abstention is deliberate. The reader emits nothing for partial expressions,
unstated results, pronouns, strategy names, implicit operations, repairs, or
any form outside these complete patterns. It does not resolve a referent or
turn a plausible statement into a claim.

## tm_0007 deterministic demonstration

`scripts/research/prolog_only_analysis.py` reads the embedded numbered
transcript at
`scripts/research/talkmoves_rerun_out/lesson_run/tm_0007_lesson_report.json`.
It compiles claims, calls SWI-Prolog through the existing adjudicator, masks
the verified surfaces, computes verdict arcs and claims tension, attempts the
existing deontic seam, and writes a teacher-report skeleton whose reader-only
fields remain absent.

The sandbox run compiled 5 claims. All 5 received `holds`; it therefore
produced 0 verdict arcs and 0 claims-tension joins. Against the union of the
two model extraction ledgers (`tm_0007_lesson_extractions.json` and
`tm_0007_baseline_extractions.json`), the exact shape-and-arguments comparison
was:

| Comparison class | Count |
| --- | ---: |
| Claims found by both | 1 |
| Model-only claims | 27 |
| Reader-only claims | 4 |

The reader-only rows are not a quality claim. They are the expected result of
strict pattern matching and a ledger whose model claims use different typed
representations or surfaces. Per-claim model verdicts are retained in the
demo's JSON comparison output. The deontic output records `unavailable` with
the missing-layer path instead of producing an invented board.

## What still requires a reader

Postures, referent judgments, and uptake fates require a reader. The
deterministic run reports each as absent: "posture reading requires a reader;
this run had none" (and corresponding referent and uptake statements). The
existing `uptake_joint` function can aggregate already-supplied readings, but
it does not supply those readings. The deterministic layer can preserve
surfaces, check registered mathematical forms, and make joins over its own
outputs; it does not understand classroom discourse.

IMPLEMENTATION_PARTIAL
Files changed: `scripts/research/deterministic_claim_reader.py`, `scripts/research/prolog_only_analysis.py`, and this report.
Verification evidence: `python3 -m py_compile` passed for both scripts; `deterministic_claim_reader.py --self-test` passed; the tm_0007 demo completed through adjudication/masking/arcs/tension and recorded the absent deontic module; SWI-Prolog directly checked fraction equivalence, loaded misconception scorekeeping, and ran the elaboration analyzer (157 records).
