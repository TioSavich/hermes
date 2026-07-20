# lessons

Lesson monitoring for the Illustrative Mathematics curriculum, plus a small set
of cited traditional comparison lessons.

## What it holds

- `im_harness.pl` — executes each grade's prescribed (operation, kind) through
  `action_automata_registry:run_action_automaton/6`, independently red-pens the
  arithmetic with SWI, and reports coverage: how many prescribed strategies run
  correctly and how many named misconceptions reproduce as runnable deformations.
- `lesson_gap.pl` — names registry-licensed moves a lesson's monitoring chart
  does not anticipate. "Licensed" here means registry coverage, not deontic
  entitlement.
- `im/` — the grade files, monitoring charts, and generated lesson context. See
  `im/README.md`.
- `traditional/rays_new_practical.pl` — comparison lessons drawn from Ray's
  arithmetic texts (non-IM).

## How it loads and what consumes it

After `paths.pl`, `hermes_worker.pl` loads the monitoring, selector, chart, and
gap modules; `formal/learner/activity_contract.pl` and
`crosswalk/families/cw_fraction_claim.pl` read `im/lesson_monitoring`.

## Attribution and boundary

Lesson identifiers, lesson-level goals, glossary language, and curriculum
structure derive from the Illustrative Mathematics K–8 curriculum (CC BY 4.0);
the teacher-guide markdown is CC BY-NC 4.0 (K–5) and CC BY 4.0 (grade 6 via Open
Up Resources). Terms are in `NOTICE.md`. Coverage follows the teacher-guide
markdown present under `geometry/corpus/`, which is partial and weighted to the
E343 slices.
