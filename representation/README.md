# representation

Python tooling that builds the representation-spine asset data: a JSON manifest
of coded student-work images (ASKTM clips and literature figure crops) and the
draft bindings from ASKTM categories to action automata.

## What it produces

- `build_asset_manifest.py` — emits `asset_manifest.json`, read by
  `more-zeeman/gallery.html`, `more-zeeman/spine.js`,
  `more-zeeman/monitoring_chart.html`, `knowledge/crosswalk/representation_spine.pl`, and
  `scripts/bundle/prebake.py`.
- `extract_figures_docling.py`, `extract_literature_figures.py` — render
  per-figure PNG crops from the literature and write the candidate lists the
  manifest builder reads.
- `generate_asktm_bindings_draft.py` — writes `asktm_bindings_draft.json` and
  `asktm_bindings_review.md`.
- `regenerate_docling_interpreted.py` — rebuilds
  `curriculum/im/docling_figures_interpreted.pl`.

## Boundary and attribution

No student data lives here: the directory carries scripts plus generated
manifests and image ids that reference PNGs stored under repo paths. The
standalone repository ships the clipping PNGs, not the source coding documents,
so absent metadata degrades to honest nulls. The ASKTM material carries an NSF
Grant No. 1561453 acknowledgement in `NOTICE.md` (also shown on the gallery
page). The binding draft is owner-unverified: `asktm_bindings_review.md` records
140 codes, 63 mapped, 77 with no defensible binding, 0 verified.
