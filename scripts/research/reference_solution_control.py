#!/usr/bin/env python3
"""How often does a step checker accuse work that is not wrong?

StepVerify holds only incorrect student solutions.  A rule that fires often
scores well at locating the first wrong step there whether or not it
discriminates, so a locate-the-error number from that corpus means nothing on
its own.  This runs the same checker over the `reference_solution` of the same
items, where every accusation is false.

Measured 2026-07-27 on the frozen dev 60: typed quantity binding as it stood at
373e8af accused 33 of 60 correct solutions while flagging 28 of 60 incorrect
ones — anti-correlated with error.  Removing the result-kind test left 10
against 20.  Arithmetic alone accuses 1.

Report the two numbers together or neither.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "scripts/research"))

import mtb_official_runner  # noqa: E402
import quantity_binding_probe as probe  # noqa: E402
from datasets import load_dataset  # noqa: E402


def reference_lines(reference: str) -> list[str]:
    """Lines of the reference solution that state an equation."""
    return [line.strip() for line in reference.splitlines()
            if line.strip() and re.search(probe.EQUATION, line)]


def accused_by_binding(problem: str, lines: list[str], model: str) -> tuple[list[int], dict]:
    bindings = {number: probe.model_bindings(problem, line, model=model)
                for number, line in enumerate(lines, 1)}
    accused = [number for number, line in enumerate(lines, 1)
               if probe.quantity_step_verdict(line, bindings.get(number, []))
               in {"refuted", "incommensurable"}]
    return accused, bindings


def accused_by_arithmetic(lines: list[str]) -> list[int]:
    flagged = probe.arithmetic_first_wrong(lines)
    return [flagged] if flagged is not None else []


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--limit", type=int, default=probe.DEFAULT_LIMIT)
    parser.add_argument("--model", default=probe.MODEL)
    parser.add_argument("--arm", choices=("binding", "arithmetic"), default="binding")
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()

    raw = load_dataset("eth-nlped/stepverify", "default", split="train")
    indexes = mtb_official_runner.select_indexes(probe.TASK, len(raw), "dev", args.limit, 0)

    records = []
    counts: Counter[str] = Counter()
    for position, index in enumerate(indexes, 1):
        example = dict(raw[index])
        lines = reference_lines(example["reference_solution"])
        if args.arm == "arithmetic":
            accused, bindings = accused_by_arithmetic(lines), {}
        else:
            accused, bindings = accused_by_binding(example["problem"], lines, args.model)
        counts["items"] += 1
        counts["lines"] += len(lines)
        counts["falsely_accused_lines"] += len(accused)
        if accused:
            counts["falsely_accused_items"] += 1
        records.append({
            "raw_index": index,
            "lines": lines,
            "accused": accused,
            "bindings": {str(k): [b.__dict__ for b in v] for k, v in bindings.items()},
        })
        print(f"control: {position}/{len(indexes)} raw={index} lines={len(lines)} "
              f"accused={accused}", flush=True)

    args.out.mkdir(parents=True, exist_ok=True)
    (args.out / f"{args.arm}.json").write_text(json.dumps(records, indent=2) + "\n",
                                               encoding="utf-8")
    summary = {**dict(counts), "arm": args.arm, "model": args.model,
               "false_accusation_rate": counts["falsely_accused_items"] / counts["items"]}
    (args.out / f"{args.arm}_summary.json").write_text(json.dumps(summary, indent=2) + "\n",
                                                       encoding="utf-8")
    print(json.dumps(summary, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
