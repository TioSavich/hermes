#!/usr/bin/env python3
"""Build CPU-only Wave 5 diagnosis floors on S2's held-out pairs."""
from __future__ import annotations

import argparse
import re
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

from build_wave5_f0 import FLOORS, PAIRS, REPO, compact_json, load_jsonl, sha256, write_json, write_jsonl


DIAGNOSIS = REPO / "hermes/app/runtime/experiments/sidekick/datasets/wave5-diagnosis-pairs.jsonl"
RESULTS_NAME = "wave5-f2-results.jsonl"
SUMMARY_NAME = "wave5-f2-floor.json"
BUILDER_VERSION = "wave5-f2-diagnosis-baselines-v1"


def verdict_fields(verdict: str) -> tuple[str, str]:
    family = re.search(r",misconception_family:([^,}]+),status:", verdict)
    step = re.search(r"^verdict\{located_step:(.*),misconception_family:", verdict)
    if not family or not step:
        raise ValueError(f"unrecognized verdict: {verdict}")
    return family.group(1), step.group(1)


def normalized_answer(value: str) -> str:
    return re.sub(r"\s+", "", value)


def mode(counter: Counter[str]) -> str:
    return sorted(counter.items(), key=lambda item: (-item[1], item[0]))[0][0]


def baseline_strata(rows: list[dict[str, Any]], baseline: str) -> list[dict[str, Any]]:
    grouped: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in rows:
        grouped[row["genre"]].append(row)
    output = []
    for genre, members in sorted(grouped.items()):
        total = len(members)
        if baseline == "modal_step_per_family":
            matched = sum(bool(row[baseline]["error_localization_match"]) for row in members)
            output.append(
                {
                    "genre": genre,
                    "n": total,
                    "family_match_count": total,
                    "family_match": 1.0,
                    "error_localization_match_count": matched,
                    "error_localization_match": round(matched / total, 6),
                }
            )
        else:
            matched = sum(bool(row[baseline]["validity_match"]) for row in members)
            output.append(
                {
                    "genre": genre,
                    "n": total,
                    "validity_match_count": matched,
                    "validity_match": round(matched / total, 6),
                }
            )
    return output


def build(output_dir: Path) -> dict[str, Any]:
    solutions = load_jsonl(PAIRS)
    solution_answers = {pair["id"]: pair["expected_answer"] for pair in solutions}
    diagnoses = load_jsonl(DIAGNOSIS)
    training = [pair for pair in diagnoses if pair["split"] == "train"]
    held_out = [pair for pair in diagnoses if pair["split"] == "held_out"]
    validity_counts = Counter(pair["validity_class"] for pair in training)
    majority = mode(validity_counts)
    step_counts: dict[str, Counter[str]] = defaultdict(Counter)
    for pair in training:
        family, step = verdict_fields(pair["verdict"])
        step_counts[family][step] += 1
    modal_steps = {family: mode(counts) for family, counts in sorted(step_counts.items())}

    results = []
    for pair in held_out:
        family, step = verdict_fields(pair["verdict"])
        expected_answer = solution_answers[pair["source_id"]]
        has_delta = normalized_answer(pair["observed_answer"]) != normalized_answer(expected_answer)
        delta_prediction = "candidate_deformation" if has_delta else "productive_trace"
        modal_step = modal_steps.get(family)
        results.append(
            {
                "id": pair["id"],
                "source_id": pair["source_id"],
                "lesson": pair["lesson"],
                "grade": pair["grade"],
                "genre": pair["genre"],
                "ground_validity_class": pair["validity_class"],
                "ground_misconception_family": family,
                "ground_located_step": step,
                "observed_answer": pair["observed_answer"],
                "computed_answer": expected_answer,
                "majority_validity_class": {
                    "prediction": majority,
                    "validity_match": majority == pair["validity_class"],
                },
                "answer_delta": {
                    "answer_differs": has_delta,
                    "prediction": delta_prediction,
                    "validity_match": delta_prediction == pair["validity_class"],
                },
                "modal_step_per_family": {
                    "predicted_family": family,
                    "predicted_step": modal_step,
                    "family_match": True,
                    "error_localization_match": modal_step == step,
                },
            }
        )
    summary = {
        "builder": BUILDER_VERSION,
        "status": "complete_s2_present",
        "source": str(DIAGNOSIS.relative_to(REPO)),
        "source_sha256": sha256(DIAGNOSIS),
        "solution_source": str(PAIRS.relative_to(REPO)),
        "solution_source_sha256": sha256(PAIRS),
        "held_out_count": len(held_out),
        "training_validity_counts": dict(sorted(validity_counts.items())),
        "majority_validity_class": majority,
        "majority_tie_break": "lexical class order after equal training counts",
        "modal_steps_per_family": modal_steps,
        "scoring_law": {
            "majority_validity_class": "exact three-class validity match",
            "answer_delta": "observed differs from productive computed answer predicts candidate_deformation; equality predicts productive_trace",
            "modal_step_per_family": "ground minted family is supplied and its training-mode exact step term is emitted",
            "pooling": "genre strata are reported separately and are never pooled",
        },
        "floors": {
            name: baseline_strata(results, name)
            for name in ("majority_validity_class", "answer_delta", "modal_step_per_family")
        },
    }
    output_dir.mkdir(parents=True, exist_ok=True)
    write_jsonl(output_dir / RESULTS_NAME, results)
    write_json(output_dir / SUMMARY_NAME, summary)
    return summary


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path, default=FLOORS)
    args = parser.parse_args()
    if not DIAGNOSIS.exists():
        raise SystemExit("PARTIAL-pending-S2: wave5-diagnosis-pairs.jsonl is absent")
    summary = build(args.output_dir)
    print(compact_json(summary["floors"]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
