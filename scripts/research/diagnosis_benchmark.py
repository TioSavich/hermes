#!/usr/bin/env python3
"""Score a system on naming a student's error, not on sounding like a tutor.

MathTutorBench's generation columns ask a reward model whether a turn *sounds*
like good tutoring. No column asks whether the diagnosis behind it is *right*.
The data to ask that has been sitting in `eth-nlped/stepverify` unused: every
one of its 1002 items carries an `error_category` from a fixed set of seven,
and 707 carry a written `error_description`.

This is not an official MathTutorBench task and must never be reported as one.
It is a task defined here, over the benchmark's data and its annotators'
labels, because it measures the thing a symbolic diagnosis layer is for.

The floor that governs every number: the majority class, "Misunderstanding of
a question", is 28.6% of items. A category accuracy below that is worse than
answering the same thing every time, and no result here appears without it.

A responder sees the problem and the student's numbered solution — the same
fields `mistake_location` interpolates. It never sees the category, the
description, or the reference solution.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import time
import warnings
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import Any, Callable

warnings.filterwarnings("ignore")
sys.path.insert(0, str(Path(__file__).resolve().parent))

from datasets import load_dataset  # noqa: E402

import mtb_official_runner as runner  # noqa: E402
import mtb_responders  # noqa: E402

CATEGORIES = (
    "Misunderstanding of a question",
    "Extra quantity or Missing quantity",
    "Missing / Wrong factual knowledge",
    "Calculation error easily solved by a calculator",
    "None of the above",
    "Reached correct solution but proceeded further",
    "Unit conversion error",
)

# Two of the seven are quantity-binding errors by their own wording. They are
# 28.9% of the corpus, and they are the categories a checker that binds a
# magnitude to the kind it measures could in principle name. Reported
# separately so a gain there is not hidden inside an overall average.
QUANTITY_CATEGORIES = frozenset({
    "Extra quantity or Missing quantity",
    "Unit conversion error",
})

PROMPT = """An experienced teacher is reading a student's solution to find what
went wrong. The arithmetic may be perfectly correct and the solution still
wrong.

Problem: {problem}

Student's solution:
{solution}

Name the single category the student's first error belongs to, choosing
exactly one of:
{options}

Answer with the category text alone.
Category:"""


def numbered(steps: list[str]) -> str:
    return "\n".join(f"Step {i + 1} - {s}" for i, s in enumerate(steps))


def classify_reply(reply: str) -> tuple[str, str]:
    """Map a reply onto one of the seven, and name the route that did it.

    The route is recorded per item and counted in the summary because an
    unnamed route is how a refusal becomes an answer. Two of the seven
    categories contribute only two words longer than three characters, so the
    overlap fallback can reach its 0.5 threshold on a single generic word: a
    reply containing "question" scores as the majority class, and one saying
    "none of these apply" scores as "None of the above". Either can be the
    right reading of one reply and a misreading of the next, and an exhausted
    token budget returns an empty string that no threshold can rescue. So the
    route travels with the prediction rather than being argued about after.
    """
    text = " ".join(reply.split()).lower()
    if not text:
        return "", "empty"
    named = [c for c in CATEGORIES if c.lower() in text]  # exact wording first
    if named:
        return named[0], "exact" if len(named) == 1 else "exact_ambiguous"
    scored = []                                       # then best word overlap
    for category in CATEGORIES:
        words = {w for w in re.findall(r"[a-z]+", category.lower()) if len(w) > 3}
        hits = sum(1 for w in words if w in text)
        scored.append((hits / max(len(words), 1), category))
    best, category = max(scored)
    return (category, "overlap") if best >= 0.5 else ("", "no_match")


def parse_category(reply: str) -> str:
    """Map a reply onto one of the seven, or to the empty string."""
    return classify_reply(reply)[0]


def macro_f1(predictions: list[str], targets: list[str]) -> float:
    total = 0.0
    for category in CATEGORIES:
        tp = sum(1 for p, t in zip(predictions, targets) if p == t == category)
        fp = sum(1 for p, t in zip(predictions, targets)
                 if p == category and t != category)
        fn = sum(1 for p, t in zip(predictions, targets)
                 if p != category and t == category)
        precision = tp / (tp + fp) if tp + fp else 0.0
        recall = tp / (tp + fn) if tp + fn else 0.0
        total += (2 * precision * recall / (precision + recall)
                  if precision + recall else 0.0)
    return total / len(CATEGORIES)


def run(responder: Callable[..., str], split: str, limit: int | None,
        out: Path, workers: int = 1,
        provenance: dict[str, Any] | None = None) -> dict[str, Any]:
    """Answer every selected item once and score the replies.

    `workers` above one holds several calls open against the same server at
    once. Items are independent and decoding is greedy, so the reply to an
    item should not depend on what else is in flight. That is a claim about a
    server rather than an assumption, so it was checked: 40 dev items re-run
    at `--workers 4` returned all 40 replies byte-identical to `--workers 1`.
    The gain is small — 1.21x on a laptop Ollama that serves these calls
    close to serially — so the flag buys about an hour on the full corpus and
    nothing more.
    """
    data = load_dataset("eth-nlped/stepverify", "default", split="train")
    indexes = runner.select_indexes("diagnosis", len(data), split, limit, 0)
    options = "\n".join(f"- {c}" for c in CATEGORIES)

    def answer(index: int) -> tuple[int, dict[str, Any], str]:
        item = data[int(index)]
        prompt = PROMPT.format(
            problem=item["problem"],
            solution=numbered(item["student_incorrect_solution"][:-1]),
            options=options)
        try:
            reply = responder(prompt=prompt, stop=None,
                              example={}, task_name="diagnosis")
        except Exception as exc:
            reply = f"<<{type(exc).__name__}>>"
        return int(index), item, reply

    predictions: list[str] = []
    targets: list[str] = []
    routes: Counter[str] = Counter()
    unparsed = 0
    started = time.time()
    out.mkdir(parents=True, exist_ok=True)
    with (out / "diagnosis.jsonl").open("w", encoding="utf-8") as handle:
        pool = ThreadPoolExecutor(max_workers=workers) if workers > 1 else None
        answers = (pool.map(answer, indexes) if pool
                   else (answer(i) for i in indexes))
        try:
            for position, (index, item, reply) in enumerate(answers):
                prediction, route = classify_reply(reply)
                routes[route] += 1
                unparsed += not prediction
                predictions.append(prediction)
                targets.append(item["error_category"])
                handle.write(json.dumps({
                    "index": index, "raw": reply,
                    "prediction": prediction, "route": route,
                    "target": item["error_category"],
                    "description": item["error_description"],
                }, ensure_ascii=False) + "\n")
                handle.flush()
                if (position + 1) % 25 == 0:
                    print(f"diagnosis: {position + 1}/{len(indexes)}",
                          flush=True)
        finally:
            if pool is not None:
                pool.shutdown()

    correct = sum(p == t for p, t in zip(predictions, targets))
    counts = Counter(targets)
    majority = counts.most_common(1)[0][1] / len(targets) if targets else 0.0
    quantity_pairs = [(p, t) for p, t in zip(predictions, targets)
                      if t in QUANTITY_CATEGORIES]
    summary = {
        "task": "diagnosis (defined here, not an official column)",
        **(provenance or {}),
        "workers": workers,
        "split": split,
        "n": len(indexes),
        "category_accuracy": correct / len(targets) if targets else 0.0,
        "majority_class_floor": majority,
        "macro_f1": macro_f1(predictions, targets),
        "unparsed_replies": unparsed,
        "parse_routes": dict(routes.most_common()),
        "quantity_categories": {
            "n": len(quantity_pairs),
            "accuracy": (sum(p == t for p, t in quantity_pairs)
                         / len(quantity_pairs)) if quantity_pairs else None,
        },
        "elapsed_seconds": round(time.time() - started, 1),
    }
    (out / "summary-diagnosis.json").write_text(
        json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    return summary


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--responder", default="unassisted")
    parser.add_argument("--model", default="gemma4:e2b")
    parser.add_argument("--split", default="dev",
                        choices=["dev", "heldout", "all"])
    parser.add_argument("--limit", type=int, default=None)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--workers", type=int, default=1,
                        help="calls held open at once against the same server")
    parser.add_argument("--responder-arg", action="append", default=[],
                        metavar="KEY=VALUE")
    args = parser.parse_args()

    options = dict(pair.split("=", 1) for pair in args.responder_arg)
    options.setdefault("stop_mode", "post")
    responder = mtb_responders.build(args.responder, model=args.model, **options)
    summary = run(responder, args.split, args.limit, args.out, args.workers,
                  {"responder": args.responder, "model": args.model})
    print(json.dumps(summary, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
