#!/usr/bin/env python3
"""Focused executable receipts for completion from coherent partial parses."""

from __future__ import annotations

from fractions import Fraction
from pathlib import Path

from fixture_task_rows import fixture_row, fixture_source_hashes
from probe_reader_coverage import sentences
from pusu_harness import (
    PrologRunner,
    compare_ground_truth,
    load_ground_truth,
    metric_rows,
    output_row,
    sentence_source_spans,
)
from surface_normalizer import normalize_surface


BOXES = "im_defrag_748d648a603084b18ef50728_1"
COMPARISON = "im_defrag_bfee414957b9544aaf7a78bc_1"
EXPRESSION = "im_defrag_cccb8e4da6df0e2433600096_1"
ROOT = Path(__file__).resolve().parents[2]


def source_row(record_id: str) -> dict:
    return fixture_row(record_id)


def corpus_receipt(runner: PrologRunner, record_id: str) -> tuple[dict, dict, list[str]]:
    row = source_row(record_id)
    normalization = normalize_surface(str(row["complete_statement"]), profile="im")
    sentence_texts = sentences(str(normalization["text"]))
    return row, normalization, sentence_texts


def synthetic_source_row(text: str) -> dict:
    """A source row for a sentence with no corpus record behind it. Empty
    source_statement_spans makes the printed-expression reader refuse with
    no_source_statement_provenance, so these probes exercise the sentence
    reader exactly as they did before source-row provenance was required."""
    return {
        "source_statement": text,
        "complete_statement": text,
        "referents": [],
        "source_statement_spans": [],
    }


def main() -> int:
    truth = load_ground_truth()
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
    hashes = fixture_source_hashes()
    runner = PrologRunner()
    try:
        records = []
        for index, record_id in enumerate((BOXES, COMPARISON, EXPRESSION)):
            row, normalization, sentence_texts = corpus_receipt(runner, record_id)
            sentence_spans = sentence_source_spans(sentence_texts, normalization, row)
            reply = runner.run(sentence_texts, row, sentence_spans)
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
        assert boxes["completion_status"] == "completed_full"
        assert boxes["completion"]["status"] == "completed"
        assert boxes["answer"][0]["value"] == "40"
        # The row's own source statement ("There are 4 boxes. Each box has 10
        # toys.") carries no ask; the question is a sibling sub-problem. The
        # comparison guard added for that case declines the join rather than
        # scoring a category difference as an answer, so this reads as
        # no_ground_truth even though the derived value agrees with the
        # verified machine answer above.
        assert boxes["ground_truth_verdict"] == "no_ground_truth"
        assert boxes["ground_truth"]["reason"] == "source_statement_carries_no_ask"
        assert boxes["program_basis"]["kind"] == "contextual"
        assert all(row["parsed"] for row in boxes["sentences"])

        assert comparison["completion_status"] == "completed_full"
        assert comparison["answer"][0]["value"] == "10"
        assert comparison["ground_truth_verdict"] == "agree"
        comparison_question = next(
            row
            for row in comparison["sentences"]
            if row["sentence_form"] == "question"
        )
        assert comparison_question["reader"] == "incumbent_context"
        assert comparison_question["parsed"] is True

        assert expression["completion_status"] == "completed_full"
        assert expression["answer"][0]["value"] == "42"
        assert expression["ground_truth_verdict"] == "agree"

        decimal_text = "What is the value of 1.20 + 0.13?"
        decimal = runner.run([decimal_text], synthetic_source_row(decimal_text))
        assert decimal["completion"]["status"] == "completed"
        decimal_value = decimal["completion"]["answers"][0]["value"].replace("r", "/")
        assert Fraction(decimal_value) == Fraction(133, 100)

        unsupported_comparison_text = "How many fewer stamps does Noah have than Tyler?"
        unsupported_comparison = runner.run(
            [unsupported_comparison_text],
            synthetic_source_row(unsupported_comparison_text),
        )
        assert unsupported_comparison["completion"]["status"] == "not_parsed"
        assert unsupported_comparison["sentences"][0]["parsed"] is False

        incoherent_sentences = [
            "Mia has 3 books.",
            "Mia has 4 books.",
            "How many books does Mia have?",
        ]
        incoherent = runner.run(
            incoherent_sentences,
            synthetic_source_row(" ".join(incoherent_sentences)),
        )
        assert incoherent["completion"]["status"] == "refused_incoherent_program"
        assert incoherent["completion"]["incoherences"]
    finally:
        runner.close()

    totals = metric_rows(records)
    assert totals["completed_full"]["numerator"] == 3
    assert totals["completed_from_partial"]["numerator"] == 0
    assert totals["completed"]["numerator"] == 3

    print("completion_thesis: all focused receipts passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
