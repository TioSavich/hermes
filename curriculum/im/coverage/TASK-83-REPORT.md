# Task 83 report

## Implemented

- The monitoring payload now serializes registered task instances from
  `compiled_task_instances`, including their excerpt, task form, position, and
  teacher-guide source.
- The chart page labels those excerpts as registered task instances and keeps
  the one-clause limit: the full activity prompt is not carried.
- `IM-G6-U4-L10` now supplies a productive equal-share scene for its registered
  `12 / 3` warm-up. The chart page uses a lesson deformation chart's productive
  scene in both the strategy drawing and the generated-filmstrip area.
- The wrong-answer-chart control accepts the live lesson deformation chart, so
  L10's specialized division chart is available through that section rather
  than being excluded by the static gallery manifest.
- Field-context fallback clusters now reuse the operation-filtered monitoring
  selector. This prevents a unit anchor from reintroducing volume-packing rows
  after explicit fraction lesson facts have selected the lesson grain.

## Sandbox evidence

`swipl` loaded `lesson_monitoring` cleanly. The focused live payload probe for
`IM-G6-U4-L10` printed:

```
task_instances=3
productive_frames=1
wrong_answer_chart_reference=lesson_deformation_chart
discussion_cluster_ids=[procedural_compression,fraction_unit_referent_operations]
```

The discussion-cluster list contains no volume-packing cluster. `python3 -m
py_compile` passed for the touched Python-adjacent monitoring files, and
`node --check` passed for the extracted inline JavaScript from
`hermes/web/monitoring_chart.html` (Node does not accept `.html` directly).

## Files changed

- `curriculum/im/field_context.pl`
- `curriculum/im/lesson_deformation_chart.pl`
- `hermes_worker.pl`
- `hermes/web/monitoring_chart.html`
- `curriculum/im/coverage/TASK-83-REPORT.md`

## Controller-run verification remaining

The brief reserves the full gate chain, app restart, and live page check for
the controller. They were not run here.

IMPLEMENTATION_COMPLETE
