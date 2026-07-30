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
python3 scripts/curriculum/build_equation_verifications.py       # --check to compare only
python3 scripts/curriculum/compile_action_mappings.py            # --check to compare only
python3 scripts/curriculum/ingest_vision.py --apply              # omit --apply for a dry run
python3 scripts/curriculum/build_lesson_evidence.py              # --check to compare only
swipl -q -l paths.pl -g "consult('scripts/curriculum/mini_atlas.pl')"
```

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

## Inputs this checkout does not carry

- The teacher-guide corpus stops at grade 6. `curriculum/im_teacher_guides/`
  holds 879 lesson guides across kindergarten through grade 6, and grade 6 is
  partial. Grades 7 and 8 have no guides, so every grade 7-8 attachment comes
  from the vision digest or the scope-and-sequence batches instead.
- The vision harvests are snapshots. Re-running the vision extraction needs the
  original Illustrative Mathematics grade 6-8 unit teacher-guide PDFs, named
  like `Grade6-1-Unit-teacher-guide-.pdf`, and the vision-run machinery that
  produced the JSON. Neither the PDFs nor those runs are carried here.

Vendored 2026-07-21 from `/Users/tio/Documents/GitHub/umedcta-formalization`,
which stays read-only.

The vision-harvest JSON inputs record, inside their `subpdf` provenance values,
the source-checkout paths that held the PDFs when the harvest ran. Those values
are historical data and stay byte-identical; they are not a machinery dependency
on that checkout.
