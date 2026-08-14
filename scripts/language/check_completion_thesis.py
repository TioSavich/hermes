#!/usr/bin/env python3
"""Focused executable receipts for completion from coherent partial parses."""

from __future__ import annotations

from fractions import Fraction

from probe_reader_coverage import sentences
from probe_task_statements import load_rows
from pusu_harness import (
    PrologRunner,
    compare_ground_truth,
    load_ground_truth,
    metric_rows,
    output_row,
    source_hashes,
)
from surface_normalizer import normalize_surface


BOXES = "im_defrag_748d648a603084b18ef50728_1"
COMPARISON = "im_defrag_bfee414957b9544aaf7a78bc_1"
EXPRESSION = "im_defrag_cccb8e4da6df0e2433600096_1"


def source_row(record_id: str) -> dict:
    return next(row for row in load_rows() if str(row["id"]) == record_id)


def corpus_receipt(runner: PrologRunner, record_id: str) -> tuple[dict, dict, list[str]]:
    row = source_row(record_id)
    normalization = normalize_surface(str(row["complete_statement"]), profile="im")
    sentence_texts = sentences(str(normalization["text"]))
    return row, normalization, sentence_texts


def main() -> int:
    truth = load_ground_truth()
    hashes = source_hashes()
    runner = PrologRunner()
    try:
        records = []
        for index, record_id in enumerate((BOXES, COMPARISON, EXPRESSION)):
            row, normalization, sentence_texts = corpus_receipt(runner, record_id)
            reply = runner.run(sentence_texts)
            record = output_row(
                index,
                row,
                reply,
                normalization,
                sentence_texts,
                truth,
                hashes,
            )
            records.append(record)

        boxes, comparison, expression = records
        assert boxes["completion_status"] == "completed_from_partial"
        assert boxes["completion"]["status"] == "completed"
        assert boxes["answer"][0]["value"] == "40"
        assert boxes["ground_truth_verdict"] == "agree"
        assert boxes["program_basis"]["kind"] == "contextual"
        assert any(not row["parsed"] for row in boxes["sentences"])

        assert comparison["completion_status"] == "completed_from_partial"
        assert comparison["answer"][0]["value"] == "10"
        assert comparison["ground_truth_verdict"] == "agree"
        comparison_question = next(
            row
            for row in comparison["sentences"]
            if row["sentence_form"] == "question"
        )
        assert comparison_question["reader"] == "incumbent_context"
        assert comparison_question["parsed"] is True

        assert expression["completion_status"] == "completed_from_partial"
        assert expression["answer"][0]["value"] == "42"
        assert expression["ground_truth_verdict"] == "agree"

        decimal = runner.run(["What is the value of 1.20 + 0.13?"])
        assert decimal["completion"]["status"] == "completed"
        decimal_value = decimal["completion"]["answers"][0]["value"].replace("r", "/")
        assert Fraction(decimal_value) == Fraction(133, 100)

        unsupported_comparison = runner.run(
            ["How many fewer stamps does Noah have than Tyler?"]
        )
        assert unsupported_comparison["completion"]["status"] == "not_parsed"
        assert unsupported_comparison["sentences"][0]["parsed"] is False

        incoherent = runner.run(
            [
                "Mia has 3 books.",
                "Mia has 4 books.",
                "How many books does Mia have?",
            ]
        )
        assert incoherent["completion"]["status"] == "refused_incoherent_program"
        assert incoherent["completion"]["incoherences"]
    finally:
        runner.close()

    totals = metric_rows(records)
    assert totals["completed_full"]["numerator"] == 0
    assert totals["completed_from_partial"]["numerator"] == 3
    assert totals["completed"]["numerator"] == 3

    synthetic_join = compare_ground_truth(
        "synthetic",
        {
            "status": "completed",
            "answers": [{"value": "4"}],
            "ask_targets": [{"target_kind": "numeric", "referent_class": "book"}],
        },
        {"synthetic": [{"result_term": "4"}]},
    )
    assert synthetic_join["verdict"] == "agree"
    print("completion_thesis: all focused receipts passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
