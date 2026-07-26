#!/usr/bin/env python3
"""Run MathTutorBench tasks through the benchmark's own task objects.

The benchmark ships a task registry, per-task YAML configs, response parsers,
and metric functions. This runner uses all of them unchanged. It supplies two
things the shipped `main.py` does not: a frozen dev/held-out split so tuning
can be kept off the reported items, and a pluggable responder so an assisted
arm can be compared against the unassisted one under one measurement path.

The prompt a responder receives is the config's rendered `system_prompt`, and
the string it returns goes to the config's own `parse_response`. Nothing in
this file interprets a task's content.

Responders live in `mtb_responders.py`. Add one there rather than branching
here.
"""
from __future__ import annotations

import argparse
import json
import os
import random
import re
import sys
import time
from pathlib import Path
from typing import Any, Callable

REPO_ROOT = Path(__file__).resolve().parents[2]
VENDOR = REPO_ROOT / "hermes/app/runtime/experiments/gemma4_tutor/vendor"

# The benchmark's modules import each other by bare name (`from tasks.base
# import Task`), so its own directory has to lead sys.path.
sys.path.insert(0, str(VENDOR))

import yaml  # noqa: E402

import tasks  # noqa: E402,F401  (registers every task class as a side effect)
from registry import TaskRegistry  # noqa: E402
from tasks.base import TaskConfig  # noqa: E402

SPLIT_SEED = 20260726
DEV_FRACTION = 0.30

CONFIG_FOR_TASK = {
    "problem_solving": "problem_solving.yaml",
    "socratic_questioning": "socratic_questioning.yaml",
    "solution_correctness": "student_solution_correctness.yaml",
    "mistake_location": "mistake_location.yaml",
    "mistake_correction": "mistake_correction.yaml",
    "scaffolding_generation": "scaffolding_generation.yaml",
    "scaffolding_generation_hard": "scaffolding_generation_hard.yaml",
    "pedagogy_following": "pedagogy_following.yaml",
    "pedagogy_following_hard": "pedagogy_following_hard.yaml",
}

# The reward model judges these; the shipped `compute_metrics` for them is a
# question-mark heuristic, not the published score.
REWARD_SCORED = {
    "scaffolding_generation",
    "scaffolding_generation_hard",
    "pedagogy_following",
    "pedagogy_following_hard",
}

# What a responder is allowed to read, task by task: exactly the fields that
# task's own `system_prompt` template interpolates, and nothing else. An
# assisted arm gets no field the unassisted prompt did not already carry.
#
# `reference_solution` appears in no template and so appears in no allowlist.
# It stays reachable to the runner, which hands it to the reward scorer after
# generation, and unreachable to anything that writes an answer.
RESPONDER_FIELDS = {
    "problem_solving": ("question", "shots"),
    "socratic_questioning": ("question", "shots"),
    "solution_correctness": ("question", "dialog_history",
                             "student_chat_solution", "shots"),
    "mistake_location": ("question", "student_solution", "shots"),
    "mistake_correction": ("question", "dialog_history",
                           "student_chat_solution"),
    "scaffolding_generation": ("question", "dialog_history"),
    "scaffolding_generation_hard": ("question", "dialog_history"),
    "pedagogy_following": ("question", "dialog_history"),
    "pedagogy_following_hard": ("question", "dialog_history"),
}


def visible_example(task_name: str, example: dict[str, Any]) -> dict[str, Any]:
    """The subset of an item a responder may read."""
    return {field: example[field]
            for field in RESPONDER_FIELDS[task_name] if field in example}


def audit_field_allowlist() -> list[str]:
    """Check each allowlist against its task's prompt, in both directions.

    Only `system_prompt` counts. `ground_truth_format` reads the answer
    fields — `answer`, `error_step`, `is_error`, `reference_solution` — and a
    responder must never receive those, so a variable's appearance there is
    not a licence to grant it.

    Under-granting starves a responder of context the unassisted prompt has.
    Over-granting hands an assisted arm something the unassisted arm never
    saw, which would make the comparison meaningless.
    """
    complaints = []
    for task_name, config_file in CONFIG_FOR_TASK.items():
        config = yaml.safe_load(
            (VENDOR / "configs" / config_file).read_text(encoding="utf-8"))
        used = set(re.findall(r"\{\{\s*([A-Za-z_][A-Za-z0-9_]*)",
                              config.get("system_prompt", "")))
        granted = set(RESPONDER_FIELDS[task_name])
        if used - granted:
            complaints.append(
                f"{task_name}: prompt reads {sorted(used - granted)} "
                f"that the allowlist withholds")
        if granted - used:
            complaints.append(
                f"{task_name}: allowlist grants {sorted(granted - used)} "
                f"that the prompt never reads")
    return complaints


def load_task(task_name: str):
    """Build a task from its shipped config.

    The mathdial configs carry a repository-relative `dataset_path`
    (`datasets/mathdial_bridge.json`), so the load happens from the vendor
    directory and the working directory is restored afterwards.
    """
    config_path = VENDOR / "configs" / CONFIG_FOR_TASK[task_name]
    config = TaskConfig(**yaml.safe_load(config_path.read_text(encoding="utf-8")))
    previous = os.getcwd()
    os.chdir(VENDOR)
    try:
        task = TaskRegistry.get_task(config.name)(config)
    finally:
        os.chdir(previous)
    return task, config


def frozen_split(task_name: str, count: int) -> dict[str, list[int]]:
    """Partition item indexes once, reproducibly, per task.

    The permutation depends only on the task name, the item count, and the
    seed, so the same split regenerates without a stored file. Dev items are
    the ones tuning may look at; held-out items carry the reported number.
    """
    order = list(range(count))
    random.Random(f"{SPLIT_SEED}:{task_name}:{count}").shuffle(order)
    cut = int(round(count * DEV_FRACTION))
    return {"dev": sorted(order[:cut]), "heldout": sorted(order[cut:])}


def select_indexes(task_name: str, count: int, split: str, limit: int | None,
                   offset: int) -> list[int]:
    if split == "all":
        chosen = list(range(count))
    else:
        chosen = frozen_split(task_name, count)[split]
    chosen = chosen[offset:]
    return chosen[:limit] if limit is not None else chosen


def run(task_name: str, responder: Callable[..., str], split: str,
        limit: int | None, offset: int, out_dir: Path,
        progress_every: int) -> dict[str, Any]:
    task, config = load_task(task_name)
    examples = task.get_test_examples()
    indexes = select_indexes(task_name, len(examples), split, limit, offset)

    out_dir.mkdir(parents=True, exist_ok=True)
    per_item_path = out_dir / f"{task_name}.jsonl"
    predictions: list[Any] = []
    targets: list[Any] = []
    generations: list[dict[str, Any]] = []
    errors = 0
    started = time.time()

    with per_item_path.open("w", encoding="utf-8") as handle:
        for position, index in enumerate(indexes):
            example = dict(examples[index])
            example["shots"] = config.few_shot_samples
            prompt = task.get_system_prompt(example)
            target = task.format_ground_truth(example)

            call_started = time.time()
            try:
                raw = responder(
                    prompt=prompt,
                    stop=config.stop,
                    example=visible_example(task_name, example),
                    task_name=task_name,
                )
                failure = None
            except Exception as exc:  # a responder failure is data, not a crash
                raw = ""
                failure = f"{type(exc).__name__}: {exc}"
                errors += 1

            prediction = task.parse_response(raw)
            predictions.append(prediction)
            targets.append(target)

            record = {
                "index": index,
                "position": position,
                "raw": raw,
                "prediction": prediction if _jsonable(prediction) else str(prediction),
                "target": target,
                "seconds": round(time.time() - call_started, 3),
            }
            if failure:
                record["error"] = failure
            handle.write(json.dumps(record, ensure_ascii=False) + "\n")
            handle.flush()

            if task_name in REWARD_SCORED:
                generations.append({
                    "problem": example.get("question", ""),
                    "reference_solution": example.get("reference_solution", "N/A"),
                    "dialog_history": example.get("conversation_json", []),
                    "dialog_formatted": example.get("dialog_history", ""),
                    "ground_truth_response": example.get("ground_truth_response", ""),
                    "generated_teacher_utterance": prediction,
                    "source_index": index,
                })

            if progress_every and (position + 1) % progress_every == 0:
                rate = (time.time() - started) / (position + 1)
                print(f"{task_name}: {position + 1}/{len(indexes)} "
                      f"({rate:.1f}s/item)", flush=True)

    try:
        metrics = task.compute_metrics(predictions, targets)
    except Exception as exc:
        metrics = {"metric_error": f"{type(exc).__name__}: {exc}"}

    summary = {
        "task": task_name,
        "split": split,
        "n": len(indexes),
        "offset": offset,
        "responder_errors": errors,
        "elapsed_seconds": round(time.time() - started, 1),
        "metrics": metrics,
        "reward_scored": task_name in REWARD_SCORED,
    }
    if task_name in REWARD_SCORED:
        gen_path = out_dir / f"generations-{task_name}.json"
        gen_path.write_text(json.dumps(generations, indent=2, ensure_ascii=False),
                            encoding="utf-8")
        summary["generations"] = str(gen_path)
        summary["note"] = ("shipped compute_metrics is a question-mark rate; "
                           "the published score comes from the reward model")

    (out_dir / f"summary-{task_name}.json").write_text(
        json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    return summary


def _jsonable(value: Any) -> bool:
    try:
        json.dumps(value)
        return True
    except (TypeError, ValueError):
        return False


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tasks", default="all",
                        help="comma-separated task names, or 'all'")
    parser.add_argument("--responder", default="unassisted")
    parser.add_argument("--model", default="gemma4:e2b")
    parser.add_argument("--split", default="dev",
                        choices=["dev", "heldout", "all"])
    parser.add_argument("--limit", type=int, default=None)
    parser.add_argument("--offset", type=int, default=0)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--progress-every", type=int, default=10)
    parser.add_argument("--responder-arg", action="append", default=[],
                        metavar="KEY=VALUE")
    args = parser.parse_args()

    drift = audit_field_allowlist()
    if drift:
        parser.error("responder field allowlist is out of step with the "
                     "shipped configs:\n  " + "\n  ".join(drift))

    import mtb_responders

    options = dict(pair.split("=", 1) for pair in args.responder_arg)
    responder = mtb_responders.build(args.responder, model=args.model, **options)

    names = list(CONFIG_FOR_TASK) if args.tasks == "all" else [
        name.strip() for name in args.tasks.split(",")]
    unknown = [name for name in names if name not in CONFIG_FOR_TASK]
    if unknown:
        parser.error(f"unknown task(s): {', '.join(unknown)}")

    summaries = []
    for name in names:
        print(f"=== {name} [{args.responder}] ===", flush=True)
        summaries.append(run(name, responder, args.split, args.limit,
                             args.offset, args.out, args.progress_every))
        print(json.dumps(summaries[-1]["metrics"], indent=2), flush=True)

    combined = {
        "responder": args.responder,
        "model": args.model,
        "split": args.split,
        "limit": args.limit,
        "split_seed": SPLIT_SEED,
        "dev_fraction": DEV_FRACTION,
        "tasks": summaries,
    }
    (args.out / "summary.json").write_text(
        json.dumps(combined, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(combined, indent=2))
    return 0


if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    raise SystemExit(main())
