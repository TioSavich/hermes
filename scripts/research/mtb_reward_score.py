#!/usr/bin/env python3
"""Score generation-task replies with MathTutorBench's published reward model.

The four generation columns are win rates: how often a reward model prefers
the produced teacher turn to the one the human teacher actually wrote. This
reproduces that calculation over the runner's `generations-*.json` files,
using the benchmark's own system prompt and conversation shape.

Scores are comparable only within one invocation. Rescoring already-scored
items on a workstation has drifted from cluster values by as much as 0.45
reward points, so both sides of every comparison are scored here, in one
process, and a number from one run is never set beside a number from another.
"""
from __future__ import annotations

import argparse
import json
import math
import time
from pathlib import Path

import torch
from transformers import AutoModelForSequenceClassification, AutoTokenizer, set_seed

SYSTEM_PROMPT = (
    "Judge the pedagogical quality of the responses provided by two teachers. "
    "Focus on the quality of the scaffolding guidance, correctness, and "
    "actionability of the feedback through nudges, questions and hints. Do not "
    "give high scores for revealing the full answer."
)
REWARD_MODEL = "eth-nlped/Qwen2.5-1.5B-pedagogical-rewardmodel"


def conversation(item: dict, reply: str) -> list[dict[str, str]]:
    turns = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user",
         "content": "Problem: " + item.get("problem", "")
                    + "\nReference Solution: " + item.get("reference_solution", "")},
    ]
    for entry in item["dialog_history"]:
        role = "assistant" if entry["user"] in ("Teacher", "Tutor") else "user"
        turns.append({"role": role, "content": entry["text"]})
    turns.append({"role": "assistant", "content": reply})
    return turns


def wilson(wins: int, n: int) -> tuple[float, float]:
    """95% Wilson interval, so a win rate never appears without its width."""
    if n == 0:
        return (0.0, 0.0)
    z = 1.959963984540054
    p = wins / n
    d = 1 + z * z / n
    centre = (p + z * z / (2 * n)) / d
    half = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / d
    return (max(0.0, centre - half), min(1.0, centre + half))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runs", type=Path, required=True)
    parser.add_argument("--model", default=REWARD_MODEL)
    parser.add_argument("--out", type=Path, default=None)
    args = parser.parse_args()
    set_seed(42)

    tokenizer = AutoTokenizer.from_pretrained(args.model, trust_remote_code=True)
    model = AutoModelForSequenceClassification.from_pretrained(
        args.model, dtype=torch.float32, trust_remote_code=True, num_labels=1).eval()
    for module in model.modules():
        if isinstance(module, torch.nn.Dropout):
            module.p = 0

    @torch.inference_mode()
    def score(turns: list[dict[str, str]]) -> float:
        ids = tokenizer.apply_chat_template(turns, tokenize=True,
                                            return_tensors="pt")
        if hasattr(ids, "keys"):
            ids = ids["input_ids"]
        return float(model(ids.to(model.device)).logits[0][0])

    summary: dict[str, object] = {"reward_model": args.model, "arms": {}}
    for path in sorted(args.runs.glob("generations-*.json")):
        arm = path.stem.removeprefix("generations-")
        rows = json.loads(path.read_text(encoding="utf-8"))
        wins = ties = 0
        margins = []
        started = time.time()
        for position, item in enumerate(rows):
            ground = item["ground_truth_response"]
            ground_text = ground["text"] if isinstance(ground, dict) else str(ground)
            produced = score(conversation(item, item["generated_teacher_utterance"]))
            reference = score(conversation(item, ground_text))
            wins += produced > reference
            ties += produced == reference
            margins.append(produced - reference)
            item["generated_score"] = produced
            item["ground_truth_score"] = reference
            if (position + 1) % 25 == 0:
                rate = (time.time() - started) / (position + 1)
                print(f"{arm}: {position + 1}/{len(rows)} ({rate:.1f}s/item)",
                      flush=True)
        n = len(rows) or 1
        low, high = wilson(wins, len(rows))
        summary["arms"][arm] = {
            "n": len(rows),
            "win_rate_over_teacher": wins / n,
            "wilson95": [round(low, 4), round(high, 4)],
            "ties": ties,
            "mean_margin": sum(margins) / n,
        }
        (args.runs / f"reward-{arm}.json").write_text(
            json.dumps(rows, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(json.dumps({arm: summary["arms"][arm]}, indent=2), flush=True)

    destination = args.out or (args.runs / "reward-summary.json")
    destination.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
