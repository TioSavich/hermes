#!/usr/bin/env python3
"""Focused executable receipts for the PUSU seeded-1 and join fixes."""

from __future__ import annotations

import re
from pathlib import Path

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
QUANTITY = re.compile(r"^quantity\(([^(),]+),")
ROOT = Path(__file__).resolve().parents[2]
LANGUAGE_RUNTIME = ROOT / "hermes/app/runtime/experiments/language"


def source_row(record_id: str) -> dict[str, object]:
    return next(row for row in load_rows() if str(row["id"]) == record_id)


def reader_receipt(runner: PrologRunner, record_id: str) -> tuple[dict, dict]:
    row = source_row(record_id)
    normalization = normalize_surface(str(row["complete_statement"]), profile="im")
    sentence_texts = sentences(str(normalization["text"]))
    sentence_spans = sentence_source_spans(sentence_texts, normalization, row)
    reply = runner.run(sentence_texts, row, sentence_spans)
    return normalization, reply


def quantity_referents(sentence: dict) -> set[str]:
    return {match.group(1) for fact in sentence["facts"]
            if (match := QUANTITY.match(fact))}


def assert_no_query_seed(program: list[str]) -> None:
    asked = [match.group(1) for fact in program if (match := ASK.fullmatch(fact))]
    for referent in asked:
        forbidden = f"quantity({referent},1,"
        assert not any(fact.startswith(forbidden) for fact in program), (
            f"query referent {referent} was seeded by structural cardinality"
        )


def main() -> int:
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
    if not LANGUAGE_RUNTIME.is_dir():
        print(
            "SKIP PUSU seeded-1 corpus receipts: "
            "hermes/app/runtime/experiments/language absent locally "
            "(gitignored language runtime); tracked numeric ground-truth join verified"
        )
        return 0
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
    # The labelled subjects stay apart: Plane A and Plane B are read as two
    # subjects carrying their own numbers, not one subject read twice. Which
    # reader separates them is not pinned here. The ape rewrite rule
    # `labeled_entity_subject` did it while the incumbent lane refused these
    # sentences; the incumbent now reads them as rates and emits no rewrite
    # rule, so a pin on the rule name reported the arbitration, not the split.
    plane_a, plane_b = plane["sentences"][0], plane["sentences"][1]
    assert not quantity_referents(plane_a) & quantity_referents(plane_b)
    assert any("2800" in fact for fact in plane_a["facts"])
    assert any("3885" in fact for fact in plane_b["facts"])

    assert plane["completion"]["status"] == "parsed_not_completable"
    assert plane["completion"]["reason"] == "identity_demand"
    assert plane["completion"]["answers"] == []
    for receipt in (plane, pencils):
        assert_no_query_seed(receipt["program"])

    # The pencils row is one sub-problem of a statement that poses several. Its
    # `source_statement` stops before the questions and its task is
    # productive-divide(12,2), so the numeric question is this row's own and the
    # identity question beside it ("Which drawing matches the situation?")
    # belongs to a sibling row. The completion is scoped to one question and the
    # receipt names the scope in `program_basis`; the sibling's ask stays in its
    # own sentence row. A completion carrying the sibling's identity demand
    # instead would answer another row's question, which is what the
    # source-statement binding in pusu_harness_runner.pl:280 exists to prevent.
    assert pencils["completion"]["ask_targets"] == [
        {"referent": "lane_question_result",
         "referent_class": "colored",
         "target_kind": "numeric"}
    ]
    assert pencils["program_basis"]["kind"] == "contextual"
    assert pencils["program_basis"]["question_index"] == 2
    sibling = pencils["sentences"][3]
    assert "asks(result,drawing_1)" in sibling["facts"]

    truth = load_ground_truth()
    plane_join = compare_ground_truth(PLANE, plane["completion"], truth)
    pencils_join = compare_ground_truth(PENCILS, pencils["completion"], truth)
    # An identity demand is never scored against a numeric machine result.
    assert plane_join["verdict"] == "no_ground_truth"
    assert plane_join["reason"] == "target_kind_mismatch"
    # The pencils ask and the machine result share a kind, so the join is
    # comparable and the completion is scored. The reader lane does not yet
    # carry the 12 into the answering program, because the sentence holding it
    # names a person the incumbent lane refuses; the completion says so rather
    # than answering. Either arm below is honest. An answer that is not the
    # curriculum's 6 is neither arm, and fails here.
    assert pencils_join["comparable"] is True
    assert pencils_join["expected_values"] == ["6"]
    if pencils["completion"]["status"] == "completed":
        assert [answer["value"] for answer in
                pencils["completion"]["answers"]] == ["6"]
        assert pencils_join["verdict"] == "agree"
    else:
        assert pencils["completion"]["status"] == "parsed_not_completed"
        assert pencils["completion"]["reason"] == "underdetermined"
        assert pencils["completion"]["answers"] == []
        assert pencils_join["verdict"] == "not_completed"

    assert pencils_normalization["profile"] == "im"
    print("pusu_fixes: all focused receipts passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
