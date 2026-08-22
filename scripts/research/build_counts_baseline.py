#!/usr/bin/env python3
"""Derive the tracked count baseline from the repository's live artifacts."""

from __future__ import annotations

import importlib
import json
import os
import subprocess
import sys
import tempfile
from collections import Counter
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
for directory in (ROOT, ROOT / "scripts/research", ROOT / "scripts/curriculum"):
    if str(directory) not in sys.path:
        sys.path.insert(0, str(directory))

from scripts.counts_baseline_lib import (  # noqa: E402
    BASELINE_PATH,
    BaselineInputUnavailable,
    load_baseline,
)


def entry(value: int, derivation: str, producer: str) -> dict[str, Any]:
    return {
        "value": value,
        "derivation": derivation,
        "producer": producer,
        "carried": False,
    }


def checkpoint_counts() -> dict[str, dict[str, Any]]:
    from scripts.curriculum import compile_action_mappings as compiler
    from scripts.curriculum import extract_docling_grade as extraction
    from scripts.curriculum import recover_docling_grade8 as recovery

    derived: dict[str, dict[str, Any]] = {}
    k7_payloads: list[dict[str, Any]] = []
    for grade in ("k", "1", "2", "3", "4", "5", "6", "7"):
        docs = extraction.discover_question_guides(grade)
        derived[f"k7.grade_{grade}.lessons"] = entry(
            len(docs),
            f"discover_question_guides({grade}) lesson count",
            "scripts/checks/k7_guide_questions.py",
        )
        checkpoint_dir = extraction.DEFAULT_QUESTION_CHECKPOINT_ROOT / f"grade-{grade}"
        for doc in docs:
            checkpoint = extraction.checkpoint_path(checkpoint_dir, doc.code)
            payload = extraction.compatible_checkpoint(checkpoint, doc)
            if payload is None:
                raise BaselineInputUnavailable(
                    f"K-7 guide-question checkpoint is absent or stale: {doc.code}"
                )
            k7_payloads.append(payload)
    derived["k7.lessons"] = entry(
        len(k7_payloads),
        "compatible K-7 guide-question checkpoint count",
        "scripts/checks/k7_guide_questions.py",
    )
    derived["k7.guide_questions"] = entry(
        sum(len(payload["guide_questions"]) for payload in k7_payloads),
        "guide-question rows in compatible K-7 checkpoints",
        "scripts/checks/k7_guide_questions.py",
    )

    docs = extraction.discover_docs(8, compiler)
    payloads: list[dict[str, Any]] = []
    for doc in docs:
        base_path = extraction.checkpoint_path(recovery.BASE_CHECKPOINT_DIR, doc.code)
        base = extraction.compatible_checkpoint(base_path, doc)
        if base is None:
            raise BaselineInputUnavailable(
                f"Grade 8 base extraction checkpoint is absent or stale: {doc.code}"
            )
        path = recovery.recovery_checkpoint_path(recovery.DEFAULT_RECOVERY_DIR, doc.code)
        payload = recovery.compatible_recovery_checkpoint(path, base)
        if payload is None:
            raise BaselineInputUnavailable(
                f"Grade 8 recovery checkpoint is absent or stale: {doc.code}"
            )
        payloads.append(payload)
    derived["grade8.lessons"] = entry(
        len(docs),
        "discover_docs(8) lesson count",
        "scripts/checks/grade8_extraction.py",
    )
    derived["grade8.task_sections"] = entry(
        sum(len(payload["tasks"]) for payload in payloads),
        "task rows in compatible Grade 8 recovery checkpoints",
        "scripts/checks/grade8_extraction.py",
    )
    derived["grade8.guide_questions"] = entry(
        sum(len(payload["guide_questions"]) for payload in payloads),
        "guide-question rows in compatible Grade 8 recovery checkpoints",
        "scripts/checks/grade8_extraction.py",
    )

    return derived


def replay_record_count() -> int:
    fixture = ROOT / "scripts/checks/fixtures/task_240_branch_agent_replay.jsonl"
    with tempfile.TemporaryDirectory(prefix="hermes-count-baseline-") as directory:
        output = Path(directory) / "replay.json"
        completed = subprocess.run(
            [
                sys.executable,
                str(ROOT / "hermes/mcp/branch_agents.py"),
                "--replay",
                str(fixture),
                "--out",
                str(output),
            ],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        if completed.returncode:
            detail = completed.stderr.strip() or completed.stdout.strip()
            raise RuntimeError(f"branch-agent replay failed: {detail}")
        return len(json.loads(output.read_text(encoding="utf-8")))


def derive_baseline(
    existing: dict[str, dict[str, Any]] | None = None,
    *,
    preserve_carried: bool = False,
) -> dict[str, dict[str, Any]]:
    census = importlib.import_module("scripts.research.build_self_description_census")
    census_data = census.build()
    rows = census.parse_registry()
    values: dict[str, dict[str, Any]] = {
        "census.registry_rows": entry(
            len(rows),
            "capability_registry.pl row count via build_self_description_census",
            "regen_all tail: build_self_description_census.py",
        ),
        "census.orphan_rows": entry(
            len(census_data["orphan_modules"]),
            "orphan_modules rows via build_self_description_census",
            "regen_all tail: build_self_description_census.py",
        ),
        "census.unrouted_rows": entry(
            len(census_data["unrouted"]),
            "unrouted rows via build_self_description_census",
            "regen_all tail: build_self_description_census.py",
        ),
    }

    checkpoint_keys = {
        *(f"k7.grade_{grade}.lessons" for grade in ("k", "1", "2", "3", "4", "5", "6", "7")),
        "k7.lessons",
        "k7.guide_questions",
        "grade8.lessons",
        "grade8.task_sections",
        "grade8.guide_questions",
    }
    if preserve_carried:
        if existing is None:
            raise BaselineInputUnavailable("cannot preserve carried values without a baseline")
        carried = {
            key for key in checkpoint_keys if existing.get(key, {}).get("carried") is True
        }
        values.update({key: existing[key] for key in carried})
        live_checkpoints = checkpoint_counts()
        values.update(
            {
                key: live_checkpoints[key]
                for key in checkpoint_keys - carried
            }
        )
    else:
        try:
            live_checkpoints = checkpoint_counts()
        except BaselineInputUnavailable as exc:
            if existing is None:
                raise
            reason = str(exc)
            for key in checkpoint_keys:
                if key not in existing:
                    raise BaselineInputUnavailable(
                        f"cannot carry missing initial baseline entry {key}: {reason}"
                    ) from exc
                prior = dict(existing[key])
                prior["carried"] = True
                prior["carry_reason"] = reason
                values[key] = prior
        else:
            values.update(live_checkpoints)

    from scripts.research import extract_lesson_context as context

    labels, guide = context.admission_store_rows()
    question_rows = labels + guide
    warrants = Counter(
        row["warrant"] for row in question_rows if row["status"] == "mechanically_admitted"
    )
    admitted = sum(row["status"] == "mechanically_admitted" for row in question_rows)
    values.update(
        {
            "questions.im_author_heading": entry(
                warrants["im_author_heading"],
                "admitted question-store rows with im_author_heading warrant",
                "scripts/research/extract_lesson_context.py admission_store_rows",
            ),
            "questions.printed_region": entry(
                warrants["printed_region"],
                "admitted question-store rows with printed_region warrant",
                "scripts/research/extract_lesson_context.py admission_store_rows",
            ),
            "questions.admitted": entry(
                admitted,
                "mechanically_admitted rows in both question stores",
                "scripts/research/extract_lesson_context.py admission_store_rows",
            ),
            "questions.total": entry(
                len(question_rows),
                "rows in both question admission stores",
                "scripts/research/extract_lesson_context.py admission_store_rows",
            ),
        }
    )

    machine_typology = importlib.import_module("build_machine_typology")
    compendium = importlib.import_module("build_automata_compendium")
    quotients = importlib.import_module("build_graph_quotients")
    values["automata.full_graph_machines"] = entry(
        len(machine_typology.parse_transition_tables()),
        "parse_transition_tables machine count",
        "scripts/research/build_full_graph_json.py",
    )
    deformation = importlib.import_module("scripts.checks.deformation_validity")
    values["automata.deformation_validity_rows"] = entry(
        len(deformation.load_ledger()),
        "deformation_validity.pl rows via the gate ledger loader",
        "scripts/checks/deformation_validity.py",
    )
    pages = compendium.generate_compendium_pages()
    values["automata.compendium_pages"] = entry(
        len(pages),
        "generated compendium page mapping size",
        "scripts/research/build_automata_compendium.py",
    )
    composite_dir = ROOT / "docs/research/assets/automata"
    family_dir = ROOT / "docs/research/automata-compendium"
    values["automata.composite_svgs"] = entry(
        len(list(composite_dir.glob("*/_composite.svg"))),
        "tracked family composite SVG count",
        "scripts/checks/automata_vocabulary.py",
    )
    values["automata.family_pages"] = entry(
        len(list(family_dir.glob("*.html"))),
        "tracked automata family page count",
        "scripts/checks/automata_vocabulary.py",
    )
    quotient = json.loads(quotients.generate_json())
    values["automata.quotient_family_nodes"] = entry(
        len(quotient["nodes"]),
        "family quotient nodes from generate_json",
        "scripts/research/build_graph_quotients.py",
    )

    bridges = importlib.import_module("scripts.checks.admitted_bridges_store")
    bridge_rows = bridges.load_store()
    bridge_counts = bridges.admitted_measurements(bridge_rows)
    values["bridges.distinct_adapted_inputs"] = entry(
        bridge_counts["distinct_adapted_inputs"],
        "unique distinct_adapted_inputs value across admitted bridge facts",
        "scripts/checks/admitted_bridges_store.py load_store",
    )
    values["bridges.cross_family"] = entry(
        bridge_counts["cross_family"],
        "admitted bridge facts whose source and target families differ",
        "scripts/checks/admitted_bridges_store.py load_store",
    )
    values["bridges.facts"] = entry(
        bridge_counts["facts"],
        "admitted_bridge facts loaded from the tracked store",
        "scripts/checks/admitted_bridges_store.py load_store",
    )

    defrag = importlib.import_module("scripts.checks.im_defragged_task_instances")
    defrag_rows = defrag.read_rows()
    compiled_facts = defrag.scan_compiled_facts()
    values.update(
        {
            "defrag.compiled_facts": entry(
                len(compiled_facts),
                "compiled task facts scanned from source artifacts",
                "scripts/checks/im_defragged_task_instances.py scan_compiled_facts",
            ),
            "defrag.rows": entry(
                len(defrag_rows),
                "defragged task rows projected through SWI-Prolog",
                "scripts/checks/im_defragged_task_instances.py read_rows",
            ),
            "defrag.admitted_rows": entry(
                len(defrag_rows) - len(compiled_facts),
                "defragged rows after the compiled-fact prefix",
                "scripts/checks/im_defragged_task_instances.py check_identity",
            ),
            "defrag.visual_markers": entry(
                sum(row["visual_count"] for row in defrag_rows),
                "visual_count sum across defragged rows",
                "scripts/checks/im_defragged_task_instances.py check_census",
            ),
            "defrag.eligible_rows": entry(
                sum(
                    row["status"] in {"already_complete", "recovered", "recovered_with_referent"}
                    for row in defrag_rows
                ),
                "defragged rows in an eligible status",
                "scripts/checks/im_defragged_task_instances.py check_census",
            ),
            "defrag.widened_receipts": entry(
                sum(
                    "provenance_class(widened_checkpoint_receipt_v1)" in row["evidence_term"]
                    for row in defrag_rows
                ),
                "defragged rows carrying widened checkpoint receipt provenance",
                "scripts/checks/im_defragged_task_instances.py check_census",
            ),
            "defrag.span_fixtures": entry(
                len(json.loads(defrag.FIXTURES.read_text(encoding="utf-8"))),
                "IM defrag source-span fixture row count",
                "scripts/checks/im_defragged_task_instances.py check_span_fixtures",
            ),
        }
    )

    standards = importlib.import_module("scripts.curriculum.build_standards_progression_overlay")
    overlay = standards.build()
    values.update(
        {
            "standards.evidence_rows": entry(
                overlay["evidence_row_count"],
                "standards progression overlay evidence_row_count",
                "scripts/curriculum/build_standards_progression_overlay.py",
            ),
            "standards.edges": entry(
                overlay["edge_count"],
                "standards progression overlay edge_count",
                "scripts/curriculum/build_standards_progression_overlay.py",
            ),
            "standards.cross_grade_prefix_edges": entry(
                overlay["cross_grade_prefix_edge_count"],
                "standards progression overlay cross-grade prefix edge count",
                "scripts/curriculum/build_standards_progression_overlay.py",
            ),
        }
    )

    coverage = json.loads(
        (ROOT / "curriculum/im/coverage/im_coverage.json").read_text(encoding="utf-8")
    )
    lesson_codes = [row["lesson"] for row in coverage["published_lessons"]]
    lesson_codes += coverage["encoded_but_unpublished"]
    values["curriculum.lesson_topics"] = entry(
        len(lesson_codes),
        "published and encoded-but-unpublished lesson codes in im_coverage.json",
        "scripts/checks/lesson_topics_cache.py coverage_codes",
    )
    field_contexts = json.loads(
        (ROOT / "curriculum/im/generated/field_context_cache.json").read_text(encoding="utf-8")
    )["field_contexts"]
    values["curriculum.field_contexts"] = entry(
        len(field_contexts),
        "field_contexts object entries in the generated cache",
        "scripts/checks/field_context_cache.py",
    )

    vision = importlib.import_module("scripts.curriculum.vision_pass")
    worklist = vision.derive_worklist()
    values["vision.text_only_pairs"] = entry(
        len(vision.text_only_pairs()),
        "text_only_pairs derived from the Grade 6-7 checkpoint corpus",
        "scripts/curriculum/vision_pass.py",
    )
    values["vision.worklist_spans"] = entry(
        len(worklist["spans"]),
        "spans in the derived Grade 6-7 vision worklist",
        "scripts/curriculum/vision_pass.py",
    )
    values["mcp.branch_replay_records"] = entry(
        replay_record_count(),
        "records emitted by the task-240 offline branch-agent replay",
        "hermes/mcp/branch_agents.py --replay",
    )

    pedagogical = importlib.import_module("scripts.checks.pedagogical_questions_check")
    values["questions.pedagogical_clusters"] = entry(
        pedagogical.direct_lookup("all", "ignored")["match_count"],
        "whole-corpus pedagogical question lookup match_count",
        "scripts/checks/pedagogical_questions_check.py direct_lookup",
    )

    readings = importlib.import_module("scripts.checks.lesson_task_readings")
    docs, covered, attachments = readings.coverage()
    markerless, _citable = readings.markerless_grid_audit(docs, covered, attachments)
    values["curriculum.markerless_task_readings"] = entry(
        markerless,
        "marker-less multi-pair K-5 spans from markerless_grid_audit",
        "scripts/checks/lesson_task_readings.py",
    )
    measurement = importlib.import_module("scripts.checks.measurement_enactment")
    forms, _stderr = measurement.form_warrants()
    values["curriculum.measurement_enactment_forms"] = entry(
        len(forms),
        "measurement enactment form warrants read from the Prolog module",
        "scripts/checks/measurement_enactment.py form_warrants",
    )
    sidecar = importlib.import_module("scripts.checks.equation_verification_sidecar_segmenter")
    side_docs, side_covered, side_attachments, _tracked, _recovered = sidecar.corpus()
    side_rows = sidecar.compiler.validate_lesson_task_readings(
        ROOT, side_docs, side_covered, side_attachments
    )
    values["curriculum.sidecar_equation_rows"] = entry(
        sum(row["id"].startswith(("task_206_", "task_206fw_")) for row in side_rows),
        "witnessed task-206 rows from validate_lesson_task_readings",
        "scripts/checks/equation_verification_sidecar_segmenter.py",
    )
    return dict(sorted(values.items()))


def render(data: dict[str, dict[str, Any]]) -> str:
    return json.dumps(data, indent=2, sort_keys=True, ensure_ascii=False) + "\n"


def write_atomic(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temporary = Path(name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    finally:
        if temporary.exists():
            temporary.unlink()


def main() -> int:
    existing = load_baseline() if BASELINE_PATH.is_file() else None
    data = derive_baseline(existing)
    write_atomic(BASELINE_PATH, render(data))
    carried = sum(entry_["carried"] for entry_ in data.values())
    print(
        f"wrote {BASELINE_PATH.relative_to(ROOT)}: {len(data)} entries, "
        f"{carried} carried"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
