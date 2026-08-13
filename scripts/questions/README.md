# scripts/questions

Mining the K-8 teacher-guide questions, and minting the questioning
Prompt/Input/Output dataset. Design:
`.superpowers/sdd/task-2026-08-12-question-automaton-design.md`.

The mining unit is the SENTENCE inside a compiled question record, cited as
record plus sentence index. Rows that are not questions to students are
dropped by activity location before anything else runs, and the exclusions are
counted by class.

## Order of work

    python3 scripts/questions/dump_question_store.pl        # via swipl, see below
    python3 scripts/questions/build_task_pattern_pilot.py --check
    python3 scripts/questions/run_baseline_links.py
    python3 scripts/questions/run_glm_links.py --mode pilot --size 100
    python3 scripts/questions/run_glm_links.py --mode scale
    python3 scripts/questions/build_question_move_pilot.py
    python3 scripts/questions/build_general_move_table.py
    python3 scripts/questions/build_question_pio.py

The store dump is a Prolog script and takes its argument after `--`:

    swipl scripts/questions/dump_question_store.pl \
          -- curriculum/im/generated/compiled_lesson_context.pl \
          > hermes/app/runtime/experiments/questions/question_records.jsonl

## What each file does

- `question_corpus.py` — records to sentences with spans, the activity-location
  prefilter, the class of questions that need a second student's work, and the
  test of whether a sentence could name a region of input space at all.
- `algebraicize.py` — numerals to parameters and guards, mechanically, from the
  mapped operation term and the base. No model reads a numeral.
- `build_task_pattern_pilot.py` — the quarantined pattern store, one row per
  region, with a witness the formal core ran to a correct verdict.
- `linker.py` — link proposal and the three verification checks, shared by both
  proposers so the floor and the model are measured the same way.
- `run_baseline_links.py` — the mechanical floor. No mined yield is worth
  quoting without this number beside it.
- `glm_batches.py`, `run_glm_links.py` — batches carved from Hermes structure,
  a call ledger against a hard budget, checkpoints that resume, and the law
  that nothing is parsed unless the transport called the call ok.
- `build_question_move_pilot.py` — verified links to the quarantined move store.
- `build_general_move_table.py` — the moves that carry no region signal, by two
  measures: a sentence that names no quantity at all, and a wording licensed at
  many states.
- `build_question_pio.py` — the questioning dataset, under wave 5's four
  fragment gates, culling contract, contamination gates, and frozen split.

Runtime artifacts (raw responses, checkpoints, quarantine, datasets) land in
`hermes/app/runtime/experiments/questions/`, which is gitignored.
