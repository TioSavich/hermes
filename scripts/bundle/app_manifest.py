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
    ("hermes", "console app, public web surfaces, representation assets, and root .pl modules (encyclopedia, scoring)"),
    ("data/asktm", "coded student-work corpus (PNGs + survey text) the gallery serves at /ASKTM_Data/; publicly shared at IU; NSF Grant No. 1561453 acknowledgement in NOTICE.md; coding documents stay in the source project"),
    ("knowledge", "empirically sourced action automata, misconception registry, standards anchors, geometry concepts and corpus, and canonical vocabulary crosswalk"),
    ("curriculum", "IM lesson monitoring KB and attributed teacher-guide inputs"),
    ("formal", "reasoning machinery: sequent and incompatibility engines, dialectic and juncture models, learner models, grounded formalization, PML semantics, and carving/audit tools"),
    ("data/research", "derivative layer of the literature corpus (coded db + bibliography); the copyrighted articles stay in the source project"),
    ("data/research_assets/research/student_work_figures",
     "student-work figures excerpted from the coded literature, served by the gallery with citations attached; the articles themselves stay in the source project"),
]
KEEP_TREES = [tree for tree, _ in KEEP_TREES_RATIONALE]

# Individual files outside the kept trees.
KEEP_FILES = [
    "paths.pl",                        # the loader; nothing resolves without it
    "hermes_worker.pl",                # the worker entry point
    "hermes/capability_registry.pl",   # generated worker capability inventory
    "hermes/dispatch_spec.pl",         # authored generic-dispatch identity + behavior
    "hermes/app/Hermes.command",       # double-click local app launcher
    "hermes/app/Hermes.svg",           # launcher icon asset
    "hermes/app/help_grounding.py",    # page-specific context for /api/help
    "knowledge/crosswalk/representation_spine.pl",
    "hermes/web/contact-sheets/goal-e-console.png",
    "hermes/web/contact-sheets/goal-e-contact-sheet.html",
    "hermes/web/contact-sheets/goal-e-contact-sheet.png",
    "hermes/web/contact-sheets/goal-e-fraction-bars.png",
    "hermes/web/contact-sheets/goal-e-gallery.png",
    "hermes/web/contact-sheets/goal-e-monitoring-chart.png",
    "hermes/web/contact-sheets/goal-e-scoreboard.png",
    "hermes/web/contact-sheets/goal-e-visualizations.png",
    "hermes/web/atlas.html",          # generated capability inventory surface
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
    "scripts/research/extract_lesson_context.py",  # regenerate attributed lesson prompts and synthesis sequences
    # Coded derivative data tables the worker consults at op time (cluster
    # maps, annotations, classifications). They ship; the student-work
    # figure images beside them are article excerpts and stay optional.
    "data/research_assets/research/2026-05-11-action-automata-corpus-bindings.csv",
    "data/research_assets/research/2026-05-11-fraction-monitoring-chart-clusters.json",
    "data/research_assets/research/2026-05-11-geometry-monitoring-chart-clusters.json",
    "data/research_assets/research/2026-05-11-k8-operations-monitoring-chart-clusters.json",
    "data/research_assets/research/2026-05-21-action-semantic-pragmatic-annotations.json",
    "data/research_assets/research/2026-05-21-action-topology-calculator-context.json",
    "data/research_assets/research/docling_classifications.json",
    "formal/learner/peano_utils.pl",          # shared Peano conversion utility
    "formal/learner/teacher_local_prolog.pl", # teacher-bound strategy provider
    "curriculum/im/generated/compiled_action_mappings.pl",  # lesson monitoring runtime cache
    "curriculum/im/generated/compiled_lesson_context.pl",  # attributed prompt and synthesis cache
    "curriculum/im/generated/compiled_task_instances.pl",  # source-backed learner task cache
    "knowledge/strategies/math/geometry_action_pairs.pl",  # registry geometry actions
    "knowledge/strategies/math/statistics_action_pairs.pl",  # registry data actions
    "knowledge/strategies/math/measurement_action_pairs.pl",  # registry measurement actions
    "knowledge/strategies/math/counting_action_pairs.pl",  # registry counting actions
    "knowledge/strategies/render/render_common.pl",  # shared scene-compiler plumbing
    "knowledge/strategies/render/area_unit_covering_scene.pl",  # unit-square area covering
    "knowledge/strategies/render/measurement_strip_scene.pl",  # lightweight measurement renderer
    "knowledge/strategies/render/ratio_diagram_scene.pl",  # ordered ratio referent tapes
    "knowledge/strategies/render/signed_number_line_scene.pl",  # signed order and inequality rays
    "formal/pml/mua_conjectures.pl",          # empty register for non-demonstrated MUA candidates
    "formal/tools/axiom_pack_audit.pl",       # loaded by the worker's audit op
    "formal/tools/axiom_toggle.pl",           # lazy-loaded by the axiom_toggle op
    "formal/tools/carving/groups_machine.pl",
    "formal/tools/carving/primitives.pl",     # strategy_machine substrate (worker load)
    "formal/tools/carving/query.pl",
    "formal/tools/carving/rationalizations.pl",
    "formal/tools/carving/strategy_machine.pl",
    "formal/tools/carving/synthesizer.pl",
    "formal/tools/carving/units_machine.pl",
    # Formal carve files are explicit so pre-staging regeneration includes
    # their working-tree locations before the controller records the renames.
    "formal/README.md",
    "formal/load.pl",
    "formal/sequent/sequent_engine.pl",
    "formal/sequent/embodied_prover.pl",
    "formal/sequent/automata.pl",
    "formal/incompatibility/brandomian_incompatibility.pl",
    "formal/incompatibility/sequent_brandom_bridge.pl",
    "formal/incompatibility/registry_incompatibility_adapter.pl",
    "formal/incompatibility/incompatibility_discovery.pl",
    "formal/incompatibility/incompatibility_sets.pl",
    "formal/incompatibility/defeasible_inference.pl",
    "formal/incompatibility/find_emergent_hyperedges.pl",
    "formal/incompatibility/incompatibility_sets_discovered.pl",
    "formal/dialectic/dialectical_engine.pl",
    "formal/dialectic/critique.pl",
    "formal/juncture/differance_juncture.pl",
]

# Markdown is documentation, not runtime — with the exceptions the running
# app reads: the quickstart the server serves through /api/quickstart, the
# two pass prompts /api/transcript_report sends as system messages, the
# per-command system prompts the workflow CLIs and /api/media_transcribe
# read at request time (kept by prefix so a newly added prompt cannot be
# silently dropped the way the first nine were), the module documentation
# excerpted by /api/help, the ASKTM survey text, and the teacher-guide inputs
# used to generate monitoring visuals.
KEEP_MD = {
    "hermes/app/QUICKSTART.md",
    "hermes/app/system_prompts/help.md",
    "docs/research/2026-07-01-talkmoves-pass1-math-prompt.md",
    "docs/research/2026-07-01-talkmoves-pass2-posture-prompt.md",
    "docs/research/2026-06-25-the-juncture-and-differance.md",
    "data/asktm/survey_questions.md",
    "curriculum/im_teacher_guides/ATTRIBUTION.md",
    "formal/README.md",
    "knowledge/crosswalk/README.md",
    "knowledge/crosswalk/families/README.md",
    "formal/formalization/README.md",
    "knowledge/geometry/README.md",
    "curriculum/im_teacher_guides/grade6/README.md",
    "hermes/README.md",
    "hermes/app/README.md",
    "formal/learner/README.md",
    "curriculum/README.md",
    "curriculum/im/README.md",
    "knowledge/misconceptions/README.md",
    "hermes/web/README.md",
    "hermes/web/render/README.md",
    "formal/pml/README.md",
    "hermes/representation/README.md",
    "knowledge/standards/README.md",
    "knowledge/strategies/README.md",
    "knowledge/strategies/math/README.md",
    "knowledge/strategies/render/README.md",
}
KEEP_MD_PREFIXES = (
    "hermes/app/system_prompts/",
    "curriculum/im_teacher_guides/",
    "curriculum/scope_and_sequence/",  # only grade6-8.md ship; lesson_monitoring.pl consults them
)

# Excluded from the kept trees. Substring "/tests/" prunes every test suite;
# the named directories are research material that no runtime path reads.
EXCLUDE_DIR_PARTS = ["/tests/"]
EXCLUDE_PREFIXES = [
    "knowledge/geometry/corpus/lakoff_nunez_existing_audit.md",
    "knowledge/geometry/corpus/misconception_harvest_log.md",
    "knowledge/geometry/corpus/n103_chapter_extracts.md",
    "knowledge/geometry/corpus/van_de_walle_excerpts.md",
    "knowledge/geometry/corpus/van_hiele_dissertation_excerpts.md",
    "knowledge/misconceptions/literature_derivation/",  # per-article derivation shards;
    "knowledge/misconceptions/round_2/",                # the compiled facts modules ship
    "knowledge/misconceptions/scripts/",
    "hermes/scripts/",                     # dev harness scripts (ralph, hardening)
]
EXCLUDE_FILES = {
    "hermes/web/bifurcation_verify.py",   # analysis script, not a surface
}

# Gallery figures (--with-figures): the literature student-work images the
# asset manifest points at. ~190 MB; the flash-drive bundle wants them, the
# Docker image degrades honestly without them (prebake-style manifest prune).
FIGURES_PREFIX = "data/research_assets/research/"


def tracked_files() -> list[str]:
    out = subprocess.run(
        ["git", "ls-files", "-z"], cwd=REPO, capture_output=True, check=True
    )
    # A task may move a tracked runtime tree before the controller stages the
    # rename. Resolve those index entries to their working-tree locations so a
    # pre-staging regeneration cannot silently under-ship the moved trees.
    relocated_trees = {"formalization", "pml", "tools", "learner"}
    knowledge_trees = {"strategies", "misconceptions", "standards", "geometry", "crosswalk"}
    data_trees = {
        "ASKTM_Data": "asktm",
        "research": "research",
        "docs/research_assets": "research_assets",
    }
    hermes_trees = {
        "more-zeeman": "web",
        "representation": "representation",
    }
    files: list[str] = []
    for path in out.stdout.decode().split("\0"):
        if not path:
            continue
        if (REPO / path).is_file():
            files.append(path)
            continue
        parts = path.split("/")
        curriculum_parts: list[str] = []
        if parts[:1] == ["lessons"]:
            curriculum_parts = ["curriculum", *parts[1:]]
        elif parts[:4] == ["knowledge", "geometry", "corpus", "im_teacher_guides"]:
            curriculum_parts = ["curriculum", "im_teacher_guides", *parts[4:]]
        elif parts[:4] == ["knowledge", "geometry", "corpus", "im_scope_and_sequence"]:
            curriculum_parts = ["curriculum", "scope_and_sequence", *parts[4:]]
        elif parts == ["knowledge", "geometry", "corpus", "ATTRIBUTION.md"]:
            curriculum_parts = ["curriculum", "im_teacher_guides", "ATTRIBUTION.md"]
        curriculum_path = "/".join(curriculum_parts)
        if curriculum_path and (REPO / curriculum_path).is_file():
            files.append(curriculum_path)
            continue
        for old_tree, new_tree in data_trees.items():
            if path == old_tree or path.startswith(old_tree + "/"):
                data_path = "data/" + new_tree + path[len(old_tree):]
                if (REPO / data_path).is_file():
                    files.append(data_path)
                    break
        else:
            data_path = ""
        if data_path and (REPO / data_path).is_file():
            continue
        for old_tree, new_tree in hermes_trees.items():
            if path == old_tree or path.startswith(old_tree + "/"):
                hermes_path = "hermes/" + new_tree + path[len(old_tree):]
                if (REPO / hermes_path).is_file():
                    files.append(hermes_path)
                    break
        else:
            hermes_path = ""
        if hermes_path and (REPO / hermes_path).is_file():
            continue
        tree, separator, remainder = path.partition("/")
        relocated = f"formal/{tree}/{remainder}" if separator and tree in relocated_trees else ""
        if separator and tree in knowledge_trees:
            relocated = f"knowledge/{tree}/{remainder}"
        if relocated and (REPO / relocated).is_file():
            files.append(relocated)
    return files


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
