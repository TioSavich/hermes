# curriculum/im

The Illustrative Mathematics knowledge base: grade files, monitoring charts, and
generated lesson context.

## The grade files

`grade_k.pl` through `grade_8.pl` carry mappings, not prose: `explicit_lesson_strategy/4`
and `explicit_lesson_misconception/4` tie each lesson id to strategy and
misconception atoms, and `explicit_lesson_text_source/2` points to the
teacher-guide markdown under `curriculum/im_teacher_guides/`. `grade_6_vision.pl` and
`grade_7_vision.pl` add vision digests.

## Monitoring and generated context

- `lesson_monitoring.pl` builds the monitoring chart for an encoded lesson: the
  strategies it calls for and the student work that would signal each one. It
  surfaces the verbatim `activity_prompt` and `discussion_sequence` fields.
- `generated/` holds four generated files (do not hand-edit). The verbatim IM
  prompts and synthesis sequences live in `generated/compiled_lesson_context.pl`;
  `compiled_action_mappings.pl`, `compiled_task_instances.pl`, and
  `vision_lesson_digest.pl` complete the set.
- `lesson_monitoring_selector.pl`, `lesson_monitoring_figures.pl`,
  `lesson_deformation_chart.pl`, `lesson_notation_chart.pl`, and `field_context.pl`
  select figures and gather per-lesson surfaces.
- `im_glossary.pl` and `docling_figures.pl` are generated (glossary from the IM
  glossary, CC BY 4.0; figures from the literature crops).

## Lesson enactment

`lesson_enactment.pl` carries the contract for machines that run a lesson's
doing when that doing is not an arithmetic computation: naming the structural
form a task asks a class to move through, running its moves on the lesson's own
printed inputs, and emitting a scene or a printed record with a verdict. Lane
modules live in `enactment/` and register into it through its multifile hooks;
`scripts/curriculum/run_lesson_enactments.pl` loads every file there, so a lane
lands a file and needs no registration edit.

Two numbers stay apart. `executable_task` in the capability census means an
automaton ran a computation. `enacted_non_arithmetic` in
`data/learningcommons/derived/im_lesson_enactment_census.json` means a form ran.
A lesson can sit on both, on one, or on neither. Every emitted row in
`data/learningcommons/derived/lesson_enactments/` carries its own sentence
saying what the artifact does not claim, and an input the machine supplied
because the curriculum left it to the room caps that row's verdict at partial.

The gate is `scripts/checks/lesson_enactment.pl`.

## Boundary

The grade files map lesson ids to strategy and misconception atoms and point to
markdown; the verbatim activity prompts and discussion sequencing are in
`generated/compiled_lesson_context.pl`. IM attribution is in `NOTICE.md`.
