# lessons/im

The Illustrative Mathematics knowledge base: grade files, monitoring charts, and
generated lesson context.

## The grade files

`grade_k.pl` through `grade_8.pl` carry mappings, not prose: `explicit_lesson_strategy/4`
and `explicit_lesson_misconception/4` tie each lesson id to strategy and
misconception atoms, and `explicit_lesson_text_source/2` points to the
teacher-guide markdown under `geometry/corpus/`. `grade_6_vision.pl` and
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

## Boundary

The grade files map lesson ids to strategy and misconception atoms and point to
markdown; the verbatim activity prompts and discussion sequencing are in
`generated/compiled_lesson_context.pl`. IM attribution is in `NOTICE.md`.
