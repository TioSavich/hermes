# Task 81 report

## Implemented

- Added `scripts/curriculum/build_lesson_standard_anchors.py`. At build time it
  joins `vision_lesson_standard/3` to loaded CCSS `standard_anchor/4` rows and
  writes `lesson_monitoring:explicit_lesson_standard/4` facts. The generated
  facts take the explicit path, which suppresses the existing unit fallback.
  Missing statement text is counted and omitted; no code or statement is
  inferred.
- Added an optional load of `generated/lesson_standard_anchors.pl` in
  `curriculum/im/lesson_monitoring.pl`, so a checkout without the generated
  file still loads.
- Added `scripts/curriculum/build_default_fill_lessons.py`, the in-fence
  successor to the older research script. K-5 remains coverage-table driven.
  For G6-U4 it examines lessons attesting `6.NS.A.1`, admits only
  tape-diagram work, excludes algorithmic work, and excludes a lesson already
  served by a specialized division chart. This prevents a fixed fraction-
  partition chart from standing in for different lesson content.
- Added `--mapped-lessons` to `scripts/curriculum/build_lesson_resonance.py`.
  It enumerates the live `scope_sequence_mapped_lesson/1` facts and retains
  dry-run-only plan output; no network or embedding request is made in that
  mode.

## Verification

- `python3 -m py_compile` passed for all three touched builders.
- Standard-anchor dry-run: 238 facts for 158 lessons; 753 digest
  lesson/standard pairs were skipped because the loaded standards tables do
  not supply statement text.
- Default-fill dry-run: 74 existing coverage-table lessons plus
  `IM-G6-U4-L6` and `IM-G6-U4-L7`; 9 of the 11 examined G6-U4
  fraction-division lessons were skipped with a reason. L10 is excluded
  because `lesson_division_deformation_chart/2` already supplies its
  specialized chart.
- Resonance `--mapped-lessons --dry-run`: 27 mapped lessons in the plan.
- `swipl -q -l paths.pl -s curriculum/im/lesson_monitoring.pl -g halt`
  passed.
- Temporary generated-anchor probe: `monitoring_chart/2` for
  `IM-G6-U1-L2` and `IM-G6-U1-L3` each returned the table-backed
  `ccss/'6.G.A.1'` statement. A temporary default-fill table produced a
  `default_fill` chart for `IM-G6-U4-L7`.

## Controller follow-up

The brief reserves canonical generated-file writes, registry regeneration,
and the full gate chain to the controller. Run, in order:

```sh
python3 scripts/curriculum/build_lesson_standard_anchors.py
python3 scripts/curriculum/build_default_fill_lessons.py
```

Then regenerate the required registry and run the full controller gate chain.

PARTIAL — files changed: `curriculum/im/lesson_monitoring.pl`, `scripts/curriculum/build_lesson_standard_anchors.py`, `scripts/curriculum/build_default_fill_lessons.py`, `scripts/curriculum/build_lesson_resonance.py`, `curriculum/im/coverage/TASK-81-REPORT.md`; evidence: sandbox-safe dry-runs, temporary generated-fact probes, `py_compile`, and clean SWI-Prolog load passed; canonical generation and controller gate chain remain controller-run.
