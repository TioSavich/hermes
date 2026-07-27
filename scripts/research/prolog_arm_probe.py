#!/usr/bin/env python3
"""Run a short MathTutorBench problem-solving slice through the Prolog arm."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

import mtb_official_runner
import mtb_prolog_responder


TASK_NAME = "problem_solving"


def _jsonable(value: Any) -> Any:
    try:
        json.dumps(value)
    except (TypeError, ValueError):
        return str(value)
    return value


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--items", type=int, default=2)
    parser.add_argument("--split", choices=["dev", "heldout", "all"],
                        default="dev")
    parser.add_argument("--offset", type=int, default=0)
    parser.add_argument("--model", default="gemma4:e2b")
    parser.add_argument("--scratch-dir", type=Path, required=True)
    parser.add_argument("--transcript-dir", type=Path)
    parser.add_argument(
        "--responder",
        choices=["prolog_solve", "prolog_solve_guarded"],
        default="prolog_solve",
    )
    parser.add_argument("--backend", choices=["ollama", "llama"],
                        default="ollama")
    parser.add_argument("--endpoint")
    parser.add_argument(
        "--num-predict", type=int,
        default=mtb_prolog_responder.mtb_responders.DEFAULT_NUM_PREDICT,
    )
    args = parser.parse_args()
    if args.items <= 0:
        parser.error("--items must be positive")
    if args.offset < 0:
        parser.error("--offset must be non-negative")

    task, config = mtb_official_runner.load_task(TASK_NAME)
    examples = task.get_test_examples()
    indexes = mtb_official_runner.select_indexes(
        TASK_NAME, len(examples), args.split, args.items, args.offset)

    options = {
        "scratch_dir": str(args.scratch_dir),
        "backend": args.backend,
        "num_predict": str(args.num_predict),
    }
    if args.transcript_dir is not None:
        options["transcript_dir"] = str(args.transcript_dir)
    if args.endpoint:
        options["endpoint"] = args.endpoint
    arm = mtb_prolog_responder.PrologResponder(
        args.model,
        guarded=args.responder == "prolog_solve_guarded",
        **options,
    )
    try:
        for position, index in enumerate(indexes):
            example = dict(examples[index])
            example["shots"] = config.few_shot_samples
            prompt = task.get_system_prompt(example)
            raw = arm.respond(
                prompt=prompt,
                stop=config.stop,
                example=mtb_official_runner.visible_example(
                    TASK_NAME, example),
                task_name=TASK_NAME,
            )
            print("MTB_PROLOG_PROBE " + json.dumps({
                "index": index,
                "position": position,
                "prediction": _jsonable(task.parse_response(raw)),
                "raw": raw,
            }, ensure_ascii=False, sort_keys=True), flush=True)
    finally:
        arm.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
