#!/usr/bin/env python3
"""Check the candidate standards overlay, stage-2 fixture, and worker query."""

from __future__ import annotations

import json
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "scripts/curriculum"))

import build_standards_progression_overlay as generator  # noqa: E402
from scripts.counts_baseline_lib import baseline_value  # noqa: E402
from normalize_learner_path_graph import (  # noqa: E402
    annotate_components_with_candidate_cross_grade_links,
    load_candidate_standards_overlay,
    normalize_nodes_by_typed_primary_key,
)
from hermes.app.worker import PersistentPrologWorker  # noqa: E402


OVERLAY = (
    ROOT / "data/learningcommons/derived/im_standards_progression_overlay.json"
)
FIXTURE = ROOT / "scripts/checks/fixtures/standards_progression_components.json"


def check_artifact() -> list[dict]:
    payload = json.loads(OVERLAY.read_text(encoding="utf-8"))
    assert payload == generator.build(), "tracked standards overlay is stale"
    assert payload["lesson_count"] == 1_308
    assert payload["evidence_row_count"] == baseline_value("standards.evidence_rows")
    assert payload["edge_count"] == baseline_value("standards.edges")
    assert payload["cross_grade_prefix_edge_count"] == baseline_value(
        "standards.cross_grade_prefix_edges"
    )
    assert payload["learner_reachability"] is False

    spine = json.loads(generator.SPINE.read_text(encoding="utf-8"))
    for edge in payload["edges"]:
        assert edge["learner_reachability"] is False
        assert edge["provenance"]
        assert len(edge["mediating_lessons"]) == len(edge["provenance"])
        for provenance in edge["provenance"]:
            source_row = provenance["source_row"]
            exact_row = spine[source_row - 1]
            assert provenance["spine_row"] == exact_row
            assert edge["from_code"] in exact_row["ccss"]["building_on"]
            assert edge["to_code"] in exact_row["ccss"]["addressing"]
    print(
        f"PASS standards overlay: lessons=1308 "
        f"evidence_rows={baseline_value('standards.evidence_rows')} "
        f"edges={baseline_value('standards.edges')} "
        f"cross_grade_prefix={baseline_value('standards.cross_grade_prefix_edges')} "
        "learner_reachability=false exact_provenance=true"
    )
    return load_candidate_standards_overlay(OVERLAY)


def check_normalizer_fixture(edges: list[dict]) -> None:
    components = json.loads(FIXTURE.read_text(encoding="utf-8"))
    original_nodes = {
        row["component_id"]: row["nodes"] for row in components
    }
    annotated = annotate_components_with_candidate_cross_grade_links(
        components, edges
    )
    by_id = {row["component_id"]: row for row in annotated}
    early = by_id["component_early_addition"]["candidate_cross_grade_links"]
    later = by_id["component_grade_two_fluency"]["candidate_cross_grade_links"]
    unrelated = by_id["component_unrelated"]["candidate_cross_grade_links"]
    assert any(
        row["from_code"] == "1.OA.C.6"
        and row["to_code"] == "2.OA.B.2"
        and row["learner_reachability"] is False
        and row["counterpart_component_ids"] == ["component_grade_two_fluency"]
        for row in early
    )
    assert any(
        row["from_code"] == "1.OA.C.6"
        and row["to_code"] == "2.OA.B.2"
        and row["learner_reachability"] is False
        and row["counterpart_component_ids"] == ["component_early_addition"]
        for row in later
    )
    assert unrelated == []
    assert {
        row["component_id"]: row["nodes"] for row in annotated
    } == original_nodes

    normalized = normalize_nodes_by_typed_primary_key(
        [
            {"node_type": "lesson", "node_id": "IM-G1-U1-L1", "title": "A"},
            {"node_type": "lesson", "node_id": "IM-G1-U1-L1", "title": "B"},
            {"node_type": "machine", "node_id": "IM-G1-U1-L1"},
        ]
    )
    assert len(normalized) == 2
    lesson = next(row for row in normalized if row["node_type"] == "lesson")
    assert len(lesson["source_records"]) == 2
    print(
        "PASS stage-2 fixture: typed node normalization retained source records; "
        "candidate cross-grade annotations preserved component membership and "
        "learner_reachability=false"
    )


def check_worker_query() -> None:
    worker = PersistentPrologWorker(umedcta_root=ROOT, timeout=120.0)
    try:
        result = worker.request(
            "standards_progression_candidates", code="1.OA.C.6"
        )
        missing = worker.raw_request(
            {
                "id": "missing_standard_candidate",
                "op": "standards_progression_candidates",
                "code": "fixture.unmatched.standard",
            }
        )
        malformed = worker.raw_request(
            {
                "id": "malformed_standard_candidate",
                "op": "standards_progression_candidates",
            }
        )
    finally:
        worker.close()
    assert result["learner_reachability"] is False
    assert result["outgoing_count"] >= 1
    matching = [
        edge for edge in result["outgoing"]
        if edge["to_code"] == "2.OA.B.2"
    ]
    assert matching and all(
        edge["learner_reachability"] is False for edge in matching
    )
    assert "learner_reachability is false" in result["promotion_requirement"]
    assert missing["ok"] is False
    assert "learner_reachability is false" in missing["error"]["message"]
    assert malformed["ok"] is False
    assert "learner_reachability remains false" in malformed["error"]["message"]
    print(
        "PASS worker standards progression query: code=1.OA.C.6 "
        "learner_reachability=false in success, empty-result, and malformed replies"
    )


def main() -> int:
    edges = check_artifact()
    check_normalizer_fixture(edges)
    check_worker_query()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
