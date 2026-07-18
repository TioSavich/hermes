#!/usr/bin/env python3
"""Compute the runtime file manifest for the Hermes application.

The manifest is the curated answer to "which tracked files does the running
app need": the Python console (hermes/app/), the Prolog knowledge base the
worker loads, the public web surfaces, and nothing else — no test suites, no
research documents, no manuscript chapters, no HPC packaging. Both the Docker
image and the flash-drive bundle are built from this one list, so the two
distributions cannot drift apart.

The list is rule-based (keep-trees minus named exclusions) with one safety
net: the worker's actual load closure. `--verify` starts SWI-Prolog, runs the
worker's load_runtime/0, and fails if any file Prolog loaded is missing from
the manifest. Rules decide what ships; the closure check proves the rules
never under-ship.

Usage:
  python3 scripts/bundle/app_manifest.py                 # print the manifest
  python3 scripts/bundle/app_manifest.py --out FILE      # write it
  python3 scripts/bundle/app_manifest.py --with-figures  # + gallery figures
  python3 scripts/bundle/app_manifest.py --verify        # closure safety net
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]

# Directories shipped (their tracked files, minus EXCLUDE rules below).
# Each entry pairs the tree with why it ships; build_app_bundle.py renders
# these rationales into the bundle's DIRECTORY_MAP.md.
KEEP_TREES_RATIONALE = [
    ("hermes", "console app + root .pl modules (encyclopedia, scoring)"),
    ("more-zeeman", "public web surfaces"),
    ("representation", "asset manifest the gallery reads"),
    ("ASKTM_Data", "coded student-work corpus (PNGs + survey text) the gallery serves; publicly shared at IU; coding documents stay in the source project"),
    ("strategies", "action automata, render scenes, registries"),
    ("misconceptions", "registry + compiled literature facts (runtime modules)"),
    ("crosswalk", "canonical vocabulary union"),
    ("standards", "CCSS / Indiana / IM anchors (worker glob-loads these)"),
    ("geometry", "schema, concepts, metaphors, van Hiele (glob-loaded); corpus/ holds attributed IM teacher-guide + scope-and-sequence inputs (see geometry/corpus/ATTRIBUTION.md)"),
    ("lessons", "IM lesson monitoring KB"),
    ("learner", "deontic scorekeeper, up-leveling"),
    ("formalization", "grounded arithmetic, grounding metaphors"),
    ("pml", "semantic axioms, MUA relations"),
    ("arche-trace", "provers, incompatibility engines"),
    ("research", "derivative layer of the literature corpus (coded db + bibliography); the copyrighted articles stay in the source project"),
    ("docs/research_assets/research/student_work_figures",
     "student-work figures excerpted from the coded literature, served by the gallery with citations attached; the articles themselves stay in the source project"),
]
KEEP_TREES = [tree for tree, _ in KEEP_TREES_RATIONALE]

# Individual files outside the kept trees.
KEEP_FILES = [
    "paths.pl",                        # the loader; nothing resolves without it
    "hermes_worker.pl",                # the worker entry point
    "hermes/capability_registry.pl",   # generated worker capability inventory
    "hermes/app/Hermes.command",       # double-click local app launcher
    "hermes/app/Hermes.svg",           # launcher icon asset
    "crosswalk/representation_spine.pl",
    "more-zeeman/contact-sheets/goal-e-console.png",
    "more-zeeman/contact-sheets/goal-e-contact-sheet.html",
    "more-zeeman/contact-sheets/goal-e-contact-sheet.png",
    "more-zeeman/contact-sheets/goal-e-fraction-bars.png",
    "more-zeeman/contact-sheets/goal-e-gallery.png",
    "more-zeeman/contact-sheets/goal-e-monitoring-chart.png",
    "more-zeeman/contact-sheets/goal-e-scoreboard.png",
    "more-zeeman/contact-sheets/goal-e-visualizations.png",
    "more-zeeman/atlas.html",          # generated capability inventory surface
    "scripts/talkmoves_two_pass.py",   # imported by server.py for masking
    # /api/transcript_report chain: talkmoves_two_pass._load_scorer()
    # path-loads the blind-corpus scorer for transcript numbering.
    "scripts/talkmoves_score_blind_corpus.py",
    "scripts/bundle/app_manifest.py",  # the distribution describes itself
    "scripts/bundle/app_manifest.txt",
    "scripts/bundle/prebake.py",       # manifest prune runs inside the image
    "scripts/bundle/smoke_bundle.py",  # staged-tree gate ships with its subject
    "scripts/html_surface_check.py",   # loopable checker for shipped HTML surfaces
    "scripts/extract_capability_registry.py",  # regenerate the shipped capability inventory
    "scripts/research/export_mua_for_mud.py",  # regenerate the MUD data snapshot
    # Coded derivative data tables the worker consults at op time (cluster
    # maps, annotations, classifications). They ship; the student-work
    # figure images beside them are article excerpts and stay optional.
    "docs/research_assets/research/2026-05-11-action-automata-corpus-bindings.csv",
    "docs/research_assets/research/2026-05-11-fraction-monitoring-chart-clusters.json",
    "docs/research_assets/research/2026-05-11-geometry-monitoring-chart-clusters.json",
    "docs/research_assets/research/2026-05-11-k8-operations-monitoring-chart-clusters.json",
    "docs/research_assets/research/2026-05-21-action-semantic-pragmatic-annotations.json",
    "docs/research_assets/research/2026-05-21-action-topology-calculator-context.json",
    "docs/research_assets/research/docling_classifications.json",
    "learner/peano_utils.pl",          # shared Peano conversion utility
    "learner/teacher_local_prolog.pl", # teacher-bound strategy provider
    "lessons/im/generated/compiled_action_mappings.pl",  # lesson monitoring runtime cache
    "lessons/im/generated/compiled_task_instances.pl",  # source-backed learner task cache
    "strategies/math/geometry_action_pairs.pl",  # registry geometry actions
    "strategies/math/statistics_action_pairs.pl",  # registry data actions
    "strategies/math/measurement_action_pairs.pl",  # registry measurement actions
    "strategies/math/counting_action_pairs.pl",  # registry counting actions
    "strategies/render/area_unit_covering_scene.pl",  # unit-square area covering
    "strategies/render/measurement_strip_scene.pl",  # lightweight measurement renderer
    "strategies/render/ratio_diagram_scene.pl",  # ordered ratio referent tapes
    "strategies/render/signed_number_line_scene.pl",  # signed order and inequality rays
    "pml/mua_conjectures.pl",          # empty register for non-demonstrated MUA candidates
    "tools/axiom_pack_audit.pl",       # loaded by the worker's audit op
    "tools/axiom_toggle.pl",           # lazy-loaded by the axiom_toggle op
    "tools/carving/groups_machine.pl",
    "tools/carving/primitives.pl",     # strategy_machine substrate (worker load)
    "tools/carving/query.pl",
    "tools/carving/rationalizations.pl",
    "tools/carving/strategy_machine.pl",
    "tools/carving/synthesizer.pl",
    "tools/carving/units_machine.pl",
]

# Markdown is documentation, not runtime — with the exceptions the running
# app reads: the quickstart the server serves through /api/quickstart, the
# two pass prompts /api/transcript_report sends as system messages, the
# per-command system prompts the workflow CLIs and /api/media_transcribe
# read at request time (kept by prefix so a newly added prompt cannot be
# silently dropped the way the first nine were), the ASKTM survey text, and
# the teacher-guide inputs used to generate monitoring visuals.
KEEP_MD = {
    "hermes/app/QUICKSTART_N103.md",
    "docs/research/2026-07-01-talkmoves-pass1-math-prompt.md",
    "docs/research/2026-07-01-talkmoves-pass2-posture-prompt.md",
    "docs/research/2026-06-25-the-juncture-and-differance.md",
    "ASKTM_Data/survey_questions.md",
    "geometry/corpus/ATTRIBUTION.md",
}
KEEP_MD_PREFIXES = (
    "hermes/app/system_prompts/",
    "geometry/corpus/im_teacher_guides/",
    "geometry/corpus/im_scope_and_sequence/",  # only grade6-8.md ship; lesson_monitoring.pl consults them
)

# Excluded from the kept trees. Substring "/tests/" prunes every test suite;
# the named directories are research material that no runtime path reads.
EXCLUDE_DIR_PARTS = ["/tests/"]
EXCLUDE_PREFIXES = [
    "geometry/corpus/lakoff_nunez_existing_audit.md",
    "geometry/corpus/misconception_harvest_log.md",
    "geometry/corpus/n103_chapter_extracts.md",
    "geometry/corpus/van_de_walle_excerpts.md",
    "geometry/corpus/van_hiele_dissertation_excerpts.md",
    "misconceptions/literature_derivation/",  # per-article derivation shards;
    "misconceptions/round_2/",                # the compiled facts modules ship
    "misconceptions/scripts/",
    "hermes/scripts/",                     # dev harness scripts (ralph, hardening)
]
EXCLUDE_FILES = {
    "more-zeeman/bifurcation_verify.py",   # analysis script, not a surface
}

# Gallery figures (--with-figures): the literature student-work images the
# asset manifest points at. ~190 MB; the flash-drive bundle wants them, the
# Docker image degrades honestly without them (prebake-style manifest prune).
FIGURES_PREFIX = "docs/research_assets/research/"


def tracked_files() -> list[str]:
    out = subprocess.run(
        ["git", "ls-files", "-z"], cwd=REPO, capture_output=True, check=True
    )
    # A task may delete a tracked runtime file before the controller stages the
    # deletion. Generate from the working tree that will be packaged, not from
    # an index entry whose path no longer exists.
    return [p for p in out.stdout.decode().split("\0") if p and (REPO / p).is_file()]


def keep(path: str, with_figures: bool) -> bool:
    if with_figures and path.startswith(FIGURES_PREFIX):
        return True
    if path in KEEP_FILES or path in KEEP_MD:
        return True
    if not any(path == t or path.startswith(t + "/") for t in KEEP_TREES):
        return False
    if path in EXCLUDE_FILES:
        return False
    if any(part in "/" + path for part in EXCLUDE_DIR_PARTS):
        return False
    if any(path.startswith(p) for p in EXCLUDE_PREFIXES):
        return False
    if path.endswith(".md") and path not in KEEP_MD \
            and not path.startswith(KEEP_MD_PREFIXES):
        return False
    return True


def build_manifest(with_figures: bool) -> list[str]:
    candidates = set(tracked_files())
    candidates |= {p for p in KEEP_FILES if (REPO / p).is_file()}
    candidates |= {p for p in KEEP_MD if (REPO / p).is_file()}
    return sorted(p for p in candidates if keep(p, with_figures))


# A closure far below this is not a smaller knowledge base — it is a broken
# probe. load_runtime pulls ~338 files; a symlinked checkout path (macOS
# /var/folders vs /private/var/folders) once made the prefix filter drop every
# line, and an empty closure passes the subset check vacuously while the
# registry extractor reads it as "everything is an orphan."
_CLOSURE_FLOOR = 200


def worker_closure() -> list[str]:
    """Ask SWI-Prolog which files the worker's load_runtime/0 actually loads."""
    goal = "load_runtime, forall(source_file(F), (write(F), nl)), halt."
    out = subprocess.run(
        ["swipl", "--on-error=status", "--on-warning=status",
         "-q", "-l", "hermes_worker.pl", "-g", goal],
        cwd=REPO, capture_output=True, text=True, timeout=600,
    )
    if out.returncode != 0:
        sys.exit(f"app_manifest --verify: swipl closure run failed:\n{out.stderr}")
    root = os.path.realpath(REPO) + os.sep
    closure = sorted(
        real[len(root):]
        for line in out.stdout.splitlines()
        if line.startswith(os.sep)
        for real in (os.path.realpath(line),)
        if real.startswith(root)
    )
    if len(closure) < _CLOSURE_FLOOR:
        sample = "\n".join(out.stdout.splitlines()[:5])
        sys.exit(
            f"app_manifest worker_closure: only {len(closure)} closure files "
            f"resolved under {root} — the probe is broken, not the KB small. "
            f"First reported lines:\n{sample}"
        )
    return closure


def manifest_map(manifest: list[str]) -> str:
    """Top-directory -> file-count table for the manifest (one line each)."""
    from walk_closure import group_by_top
    lines = [f"{top}\t{count}" for top, count in group_by_top(manifest)]
    return "\n".join(lines) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--out", type=Path, help="write the manifest to this file")
    ap.add_argument("--with-figures", action="store_true",
                    help="include the gallery's literature figure images")
    ap.add_argument("--verify", action="store_true",
                    help="run the worker load-closure safety net (needs swipl)")
    args = ap.parse_args()

    manifest = build_manifest(args.with_figures)

    if args.verify:
        missing = [f for f in worker_closure() if f not in set(manifest)]
        if missing:
            print("app_manifest --verify: worker loads files the manifest "
                  "does not ship:", file=sys.stderr)
            for f in missing:
                print(f"  {f}", file=sys.stderr)
            return 1
        absent = [f for f in manifest if not (REPO / f).is_file()]
        if absent:
            print("app_manifest --verify: manifest names missing files:",
                  file=sys.stderr)
            for f in absent:
                print(f"  {f}", file=sys.stderr)
            return 1
        print(f"app_manifest --verify: OK — closure covered, "
              f"{len(manifest)} files on disk")
        return 0

    text = "\n".join(manifest) + "\n"
    if args.out:
        args.out.write_text(text, encoding="utf-8")
        total = sum((REPO / f).stat().st_size for f in manifest)
        print(f"wrote {args.out}: {len(manifest)} files, "
              f"{total / 1048576:.1f} MB")
        map_path = args.out.parent / "app_manifest_map.txt"
        map_path.write_text(manifest_map(manifest), encoding="utf-8")
        print(f"wrote {map_path}")
    else:
        sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
