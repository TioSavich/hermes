#!/usr/bin/env python3
"""Focused executable receipts for the PUSU seeded-1 and join fixes."""

from __future__ import annotations

import re

from probe_reader_coverage import sentences
from probe_task_statements import load_rows
from pusu_harness import (
    PrologRunner,
    compare_ground_truth,
    load_ground_truth,
    sentence_source_spans,
)
from surface_normalizer import normalize_surface


PENCILS = "im_defrag_95e6836c2e770aa507544dfc_1"
PLANE = "im_defrag_2f1df73a1a4681025ce9f31b_1"
ASK = re.compile(r"^asks\(result,([^()]+)\)$")


def source_row(record_id: str) -> dict[str, object]:
    return next(row for row in load_rows() if str(row["id"]) == record_id)


def reader_receipt(runner: PrologRunner, record_id: str) -> tuple[dict, dict]:
    row = source_row(record_id)
    normalization = normalize_surface(str(row["complete_statement"]), profile="im")
    sentence_texts = sentences(str(normalization["text"]))
    sentence_spans = sentence_source_spans(sentence_texts, normalization, row)
    reply = runner.run(sentence_texts, row, sentence_spans)
    return normalization, reply


def assert_no_query_seed(program: list[str]) -> None:
    asked = [match.group(1) for fact in program if (match := ASK.fullmatch(fact))]
    for referent in asked:
        forbidden = f"quantity({referent},1,"
        assert not any(fact.startswith(forbidden) for fact in program), (
            f"query referent {referent} was seeded by structural cardinality"
        )


def main() -> int:
    runner = PrologRunner()
    try:
        plane_normalization, plane = reader_receipt(runner, PLANE)
        pencils_normalization, pencils = reader_receipt(runner, PENCILS)
    finally:
        runner.close()

    assert "2,800" not in plane_normalization["text"]
    assert "3,885" not in plane_normalization["text"]
    n6_rows = [row for row in plane_normalization["applied_rules"]
               if row["rule"] == "N6"]
    assert n6_rows and all(row["audit_row"] for row in n6_rows)
    assert all(sentence["parsed"] for sentence in plane["sentences"][:2])
    assert all("labeled_entity_subject" in sentence["rewrite_rules"]
               for sentence in plane["sentences"][:2])

    for receipt in (plane, pencils):
        assert receipt["completion"]["status"] == "parsed_not_completable"
        assert receipt["completion"]["reason"] == "identity_demand"
        assert receipt["completion"]["answers"] == []
        assert_no_query_seed(receipt["program"])

    truth = load_ground_truth()
    plane_join = compare_ground_truth(PLANE, plane["completion"], truth)
    pencils_join = compare_ground_truth(PENCILS, pencils["completion"], truth)
    assert plane_join["verdict"] == "no_ground_truth"
    assert plane_join["reason"] == "target_kind_mismatch"
    assert pencils_join["verdict"] == "no_ground_truth"
    assert pencils_join["reason"] == "target_kind_mismatch"

    synthetic = compare_ground_truth(
        "numeric",
        {
            "status": "completed",
            "reason": "derived_all_asks",
            "answers": [{"value": "560"}],
            "ask_targets": [
                {"target_kind": "numeric", "referent_class": "rate"}
            ],
        },
        {"numeric": [{"result_term": "560"}]},
    )
    assert synthetic["verdict"] == "agree"
    assert pencils_normalization["profile"] == "im"
    print("pusu_fixes: all focused receipts passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
