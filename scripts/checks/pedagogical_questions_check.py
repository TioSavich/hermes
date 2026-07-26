#!/usr/bin/env python3
"""Deterministic checks for the monitoring-question lookup and worker route."""
from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from hermes.app.worker import PersistentPrologWorker

CLUSTER_FILES = sorted(
    (ROOT / "data/research_assets/research").glob(
        "*monitoring-chart-clusters.json"))


def direct_lookup(kind: str, query: str) -> dict[str, Any]:
    query_literal = json.dumps(query, ensure_ascii=False)
    goal = (
        "use_module(library(http/json)),"
        "use_module(im_lessons(lesson_monitoring)),"
        f"lesson_monitoring:pedagogical_question_clusters("
        f"{kind},{query_literal},Result),"
        "json_write_dict(current_output,Result),halt."
    )
    completed = subprocess.run(
        ["swipl", "-q", "-l", str(ROOT / "paths.pl"), "-g", goal],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    assert completed.returncode == 0, completed.stderr
    return json.loads(completed.stdout)


def source_cluster(cluster_id: str) -> dict[str, Any]:
    for path in CLUSTER_FILES:
        root = json.loads(path.read_text(encoding="utf-8"))
        for cluster in root["clusters"]:
            if cluster["id"] == cluster_id:
                return cluster
    raise AssertionError(f"missing source cluster {cluster_id}")


def only_match(result: dict[str, Any], expected_id: str) -> dict[str, Any]:
    matches = result["matches"]
    assert len(matches) == 1, result
    assert matches[0]["cluster_id"] == expected_id, result
    return matches[0]


def main() -> int:
    by_state = direct_lookup("automaton_state", "equalized_part")
    state_row = only_match(by_state, "equal_partitioning")
    assert state_row["match_basis"] == "automaton_state_exact"

    by_topic = direct_lookup("topic", "equal partitioning")
    topic_row = only_match(by_topic, "equal_partitioning")
    assert topic_row["match_basis"] == "topic_phrase_all_tokens_present"

    by_standard = direct_lookup("standard", "CCSS 3.NF.A.1")
    assert {
        row["cluster_id"] for row in by_standard["matches"]
    } == {
        "equal_partitioning",
        "referent_control",
        "unit_iteration_nonunit",
    }
    assert all(
        row["match_basis"] == "standard_exact"
        for row in by_standard["matches"]
    )

    absent = direct_lookup("topic", "quadratic discriminant roots")
    assert absent["status"] == "abstained"
    assert absent["match_count"] == 0
    assert absent["matches"] == []

    source = source_cluster("equal_partitioning")
    for row in (state_row, topic_row):
        assert row["assessing_questions"] == source["assessing_questions"]
        assert row["advancing_questions"] == source["advancing_questions"]

    worker = PersistentPrologWorker(timeout=120)
    try:
        routed = worker.request(
            "pedagogical_questions",
            kind="automaton_state",
            query="equalized_part",
        )
        only_match(routed, "equal_partitioning")
        malformed = worker.raw_request(
            {"id": "pedagogical-check", "op": "pedagogical_questions"})
    finally:
        worker.close()

    assert malformed["ok"] is False, malformed
    assert malformed["error"]["type"] == "malformed_pedagogical_questions"
    print(
        "PASS state, standard, and whole-word topic admission; explicit "
        "abstention; verbatim questions; worker round trip"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
