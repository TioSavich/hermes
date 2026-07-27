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

    # A topic query admits every cluster sharing a token and orders them by
    # how many hit, so the cluster named by the phrase leads rather than being
    # the only row. The conjunction this replaced abstained as soon as a query
    # grew precise, which ran recall opposite to how well the asker had named
    # the mathematics.
    by_topic = direct_lookup("topic", "equal partitioning")
    topic_row = by_topic["matches"][0]
    assert topic_row["cluster_id"] == "equal_partitioning", by_topic
    assert topic_row["match_basis"] == "topic_tokens_present"
    assert topic_row["tokens_matched"] == 2
    assert topic_row["tokens_asked"] == 2
    ranks = [row["tokens_matched"] for row in by_topic["matches"]]
    assert ranks == sorted(ranks, reverse=True), by_topic

    every = direct_lookup("all", "ignored")
    assert every["status"] == "matched"
    assert every["match_count"] == 42, every["match_count"]
    assert all(row["match_basis"] == "whole_corpus" for row in every["matches"])

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
        "PASS state, standard, ranked topic overlap, and whole-corpus "
        "admission; abstention on zero overlap; verbatim questions; "
        "worker round trip"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
