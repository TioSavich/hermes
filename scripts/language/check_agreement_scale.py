#!/usr/bin/env python3
"""Focused executable receipts for the agreement-scale language slice."""

from __future__ import annotations

import json
import subprocess
from pathlib import Path

from guide_sentences import editor_lines, fragments
from probe_reader_coverage import sentences
from probe_task_statements import load_rows
from pusu_harness import (
    PrologRunner,
    build_summary,
    load_ground_truth,
    output_row,
    sentence_source_spans,
    source_hashes,
)
from surface_normalizer import normalize_surface


REPO = Path(__file__).resolve().parents[2]
ENGINE = REPO / "scripts/sidekick/diagnosis_saturate.pl"
LIN = "im_defrag_1783d222456f739e3067673c_1"
UNIT_RATE_ROWS = {
    "im_defrag_90eb8a5c62cd0001fdf65e98_1": "2",
    "im_defrag_a0d5027fc2422d3df7a7cfcf_1": "40",
    "im_defrag_93e0f0a5aa46652109d4baf0_1": "27",
}
RESULTS = REPO / "hermes/app/runtime/experiments/language/pusu_results.jsonl"
SUMMARY = REPO / "hermes/app/runtime/experiments/language/pusu_summary.json"


def corpus_row(runner: PrologRunner, record_id: str, corpus_index: int) -> dict:
    source = next(row for row in load_rows() if str(row["id"]) == record_id)
    normalization = normalize_surface(str(source["complete_statement"]), profile="im")
    sentence_texts = sentences(str(normalization["text"]))
    sentence_spans = sentence_source_spans(sentence_texts, normalization, source)
    return output_row(
        corpus_index,
        source,
        runner.run(sentence_texts, source, sentence_spans),
        normalization,
        sentence_texts,
        load_ground_truth(),
        source_hashes(),
    )


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


def prolog_value(program: str, name: str) -> float:
    engine = str(ENGINE).replace("'", "''")
    goal = (
        f"ensure_loaded('{engine}'),Program={program},seed(Program),"
        f"saturate(Program),derived({name},Value,_),write(Value)"
    )
    result = subprocess.run(
        ["swipl", "-q", "-g", goal, "-t", "halt"],
        cwd=REPO,
        text=True,
        capture_output=True,
        check=True,
    )
    return float(result.stdout)


def check_engine_recipes() -> None:
    cases = [
        (
            "[quantity(a,19,item),quantity(b,7,item),"
            "quantity(d,unknown,item),relation(d,difference(a,b),\"d\")]",
            "d",
            12,
        ),
        (
            "[quantity(a,unknown,item),quantity(b,7,item),"
            "quantity(d,12,item),relation(d,difference(a,b),\"d\")]",
            "a",
            19,
        ),
        (
            "[quantity(a,19,item),quantity(b,unknown,item),"
            "quantity(d,12,item),relation(d,difference(a,b),\"d\")]",
            "b",
            7,
        ),
        (
            "[quantity(a,42,item),quantity(b,6,scalar),"
            "quantity(q,unknown,item),relation(q,quotient(a,b),\"q\")]",
            "q",
            7,
        ),
        (
            "[quantity(a,unknown,item),quantity(b,6,scalar),"
            "quantity(q,7,item),relation(q,quotient(a,b),\"q\")]",
            "a",
            42,
        ),
        (
            "[quantity(a,42,item),quantity(b,unknown,scalar),"
            "quantity(q,7,item),relation(q,quotient(a,b),\"q\")]",
            "b",
            6,
        ),
    ]
    for program, name, expected in cases:
        assert prolog_value(program, name) == expected


def check_guide_lines() -> None:
    guide = REPO / "curriculum/im_teacher_guides/grade1/unit1/lesson1.md"
    text = guide.read_text(encoding="utf-8")
    assert text.count("\f") == 6
    assert len(text.splitlines()) == len(editor_lines(text)) + 5
    by_line: dict[int, list[str]] = {}
    for number, fragment in fragments(guide):
        by_line.setdefault(number, []).append(fragment)
    assert "Materials to Gather" in by_line[66]
    assert "Materials to Gather" in by_line[173]
    assert editor_lines("a\fb\nc") == ["a\fb", "c"]


def check_full_artifacts() -> None:
    target = load_rows()
    rows = [json.loads(line) for line in RESULTS.read_text(encoding="utf-8").splitlines()
            if line.strip()]
    hashes = source_hashes()
    assert len(rows) == len(target) == 4712
    assert [row["record_id"] for row in rows] == [str(row["id"]) for row in target]
    assert len({row["record_id"] for row in rows}) == 4712
    assert sum(row["sentence_count"] for row in rows) == 28758
    assert all(row["source_sha256"] == hashes for row in rows)
    expected_summary = build_summary(rows, target, hashes)
    assert json.loads(SUMMARY.read_text(encoding="utf-8")) == expected_summary
    totals = expected_summary["total"]
    # 2026-08-15: the relation-emission slice adds five completions (three
    # agreeing, two without comparable truth) and two partial promotions;
    # measured from the final-tree harness pass, agreement rate unchanged
    # at 0.9913.
    assert totals["completed_full"]["numerator"] == 907
    assert totals["completed_from_partial"]["numerator"] == 163
    assert totals["agreeing"]["numerator"] == 1029
    assert totals["agreeing"]["denominator"] == 1038


def main() -> int:
    check_engine_recipes()
    check_guide_lines()
    check_full_artifacts()
    runner = PrologRunner()
    try:
        lin = corpus_row(runner, LIN, 0)
        assert lin["completion_status"] == "completed_from_partial"
        assert lin["answer"][0]["value"] == "16"
        assert lin["ground_truth_verdict"] == "agree"
        assert lin["program_basis"]["base_sentence_indices"] == [0, 1, 2]
        assert any("sum([lin_seed_initial,lin_seed_give_1_change])" in fact
                   for fact in lin["program"])

        for index, (record_id, expected) in enumerate(UNIT_RATE_ROWS.items(), 1):
            row = corpus_row(runner, record_id, index)
            assert row["completion_status"] == "completed_full"
            assert row["answer"][0]["value"] == expected
            assert row["ground_truth_verdict"] == "agree"

        no_antecedent_text = "She gives 3 to Kiran."
        no_antecedent = runner.run(
            [no_antecedent_text], synthetic_source_row(no_antecedent_text)
        )
        assert no_antecedent["completion"]["status"] == "not_parsed"
    finally:
        runner.close()

    print("agreement_scale: all focused receipts passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
