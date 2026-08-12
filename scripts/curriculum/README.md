# Curriculum pipeline sources

These files hold the generators and reviewed inputs behind the checked-in
curriculum caches. Every one of them regenerates in this checkout.

That was not true when they were vendored on 2026-07-21, and this file said so
until 2026-07-27. What it recorded as four missing input corpora turned out to
be one thing in three spellings: a path vocabulary. The generated artifacts
already carried Hermes paths as their recorded provenance while the generators
still addressed `geometry/corpus/`, `lessons/im/`, and `learner/`, so each pair
named one corpus twice with nothing joining the two names. Each port changed
path literals only, and each is proved by regenerating the tracked artifact
byte-for-byte.

## Regenerations

```sh
python3 scripts/research/build_im_coverage.py
python3 scripts/curriculum/build_digest.py curriculum/im/generated/vision_lesson_digest.pl
python3 scripts/curriculum/build_sidecar_equation_census.py       # --check to compare only
python3 scripts/curriculum/build_equation_verifications.py       # --check to compare only
python3 scripts/curriculum/compile_action_mappings.py            # --check to compare only
python3 scripts/curriculum/ingest_vision.py --apply              # omit --apply for a dry run
python3 scripts/curriculum/build_lesson_evidence.py              # --check to compare only
python3 scripts/curriculum/extract_docling_grade.py --grade 8
python3 scripts/curriculum/recover_docling_grade8.py
python3 scripts/curriculum/recover_docling_grade8_vision.py --derive-only
python3 scripts/curriculum/build_im_defragged_task_instances.py
python3 scripts/research/extract_lesson_context.py
swipl -q -l paths.pl -g "consult('scripts/curriculum/mini_atlas.pl')"
```

`build_sidecar_equation_census.py` records the 23 recovered spans whose printed
equations still sit outside the named equation lanes. It retains both the
original survey match and the maximal equation reading, so flattened cross-item
joins remain explicit.

`build_equation_verifications.py` runs before the compiler because the compiler
reads its ledger. The ledger holds every equation the True-or-False routine
prints, the claim term it compiles to, and the verdict and reason trace a
registered checker in `hermes/math_claim_checker.pl` returned for it. The
compiler re-derives all of that from the guides and refuses any row the tree no
longer supports, so the ledger supplies the Prolog verdicts and nothing else.

`compile_action_mappings.py` names each corpus it reads once, in the constants
block at the top of the file. Rerouting a corpus is one line there; `--check`
is what says the reroute was faithful. `ingest_vision.py` follows the same
shape.

`extract_docling_grade.py` reads the linear Grade 6-8 Docling lesson guides.
It checkpoints one JSON record per lesson under the ignored app runtime,
copies task text with physical source spans, and writes pending assessing and
advancing questions in the same term shape as the reviewed L17 records. A task
whose expression is absent stays in the output with a named blocker and the
available image, description-file, and model provenance. The extractor does
not treat Granite descriptions as curriculum-authored text. `--lessons` runs a
bounded pilot, `--refresh` replaces compatible checkpoints, and `--check`
compares the full extraction with its generated outputs.

`recover_docling_grade8.py` runs only after the base Grade 8 checkpoints exist.
It flattens each `document.json` body tree in recorded reading order, aligns the
in-scope task headings, and copies allowed JSON text, list, formula, table, and
key-value items. Each recovery retains the raw JSON string, self-reference,
collection index, page and bounding box, byte range, and a separate rendering.
`docling_formula_spacing_v1` deterministically removes Docling's character
spacing in formulas; it does not alter the stored raw value. Rows the JSON does
not settle retain their original blocker.

`recover_docling_grade8_vision.py` derives the remaining image-bearing residue
from those JSON checkpoints. Its default worklist is narrower than the full
residue: an existing picture description must explicitly transcribe task text.
A live call uses `gemma-4-31B-it` with 2,500 output tokens and a 300-attempt hard
limit. Only an `ok`, certain statement that occurs in the description can enter
the facts. `--derive-only` writes the worklist without contacting REALLMS.

The Grade 8 task facts are an additional input to
`build_im_defragged_task_instances.py`. Its summary is computed from the loaded
facts while its legacy 2,146-row census remains an asserted compatibility
boundary. Grade 8 questions enter `compiled_lesson_context.pl` as
`pending_human_review`; the serving predicate continues to return approved
records only.

## What the ports cost, and what they did not buy

`compile_action_mappings.py` reproduces `compiled_task_instances.pl` exactly and
`compiled_action_mappings.pl` up to one row, `IM-G3-U7-L6`. That row states what
a hand-authored `explicit_lesson_strategy/4` fact in `curriculum/im/grade_3.pl`
already states, and the compiler declines to compile a mapping a lesson file
asserts directly. The fact arrived after the artifact was last built and no one
could regenerate to drop the duplicate.

`ingest_vision.py` reproduces `grade_6_vision.pl`, `grade_7_vision.pl`, and
`action_mapping_rules.json` exactly. One of its repairs is currently inert: the
`git show` of the compiled mappings failed silently under the old path, and
running it with the correct path changes no output, because the op-domains it
recovers are ones the harvest does not attest. The repair removes a silent
failure; it does not move grade 6-7 coverage.

`mini_atlas.pl` reproduces `formal/learner/atlas/basis_transitions.pl` exactly:
120 transitions over the declared basis. `learner(task_transition)` and
`learner(activity_contract)` both resolve through the `learner` alias in
`paths.pl`.

## Source boundaries

`curriculum/im_teacher_guides/` carries the fixed-width elementary extracts.
The app runtime's Docling corpus carries the linear Grade 6-8 lesson guides,
their exported image assets, and model-attributed picture descriptions. The
two guide genres have separate readers and share canonical lesson codes.

The vision harvests are snapshots. Re-running their PDF extraction still
requires the original Grade 6-8 unit teacher-guide PDFs and the external
vision-run machinery that produced the JSON.

Vendored 2026-07-21 from `/Users/tio/Documents/GitHub/umedcta-formalization`,
which stays read-only.

The vision-harvest JSON inputs record, inside their `subpdf` provenance values,
the source-checkout paths that held the PDFs when the harvest ran. Those values
are historical data and stay byte-identical; they are not a machinery dependency
on that checkout.
