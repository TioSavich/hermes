#!/usr/bin/env python3
"""Controller-run Wave 5 untuned few-shot floor harness.

This script is network-capable by design, but S3 only builds and validates it.
The controller supplies an OpenAI-compatible endpoint and untuned E2B model.
Every extracted program is scored by the bounded S1 SWI-Prolog runner.
"""
from __future__ import annotations

import argparse
import json
import re
import urllib.error
import urllib.request
from collections import defaultdict
from pathlib import Path
from typing import Any

from build_wave5_f0 import (
    FLOORS,
    PAIRS,
    REPO,
    ProgramRunner,
    load_jsonl,
    sha256,
    summarize,
    write_json,
    write_jsonl,
)


RUNNER_VERSION = "wave5-f1-untuned-few-shot-v1"
RESULTS_NAME = "wave5-f1-results.jsonl"
SUMMARY_NAME = "wave5-f1-floor.json"
SERVING_PROMPT = """Translate one mathematics task into one executable Prolog program.
Use only quantity/3 facts, one asks/2 fact, and one solve/1 clause that calls
hermes_encyclopedia:strategy_trace_dict/4 with a registered machine. Copy the
task's numerals, bind them to named referents, and use JSON-compatible strings
for kind tags. Reply with the program only. Do not calculate the answer in prose."""


def few_shots(training: list[dict[str, Any]], count: int) -> list[dict[str, Any]]:
    """Select a stable family- and genre-diverse frame without held-out text."""
    groups: dict[tuple[str, str], list[dict[str, Any]]] = defaultdict(list)
    for pair in training:
        groups[(pair["genre"], pair["family"])].append(pair)
    candidates = [
        sorted(rows, key=lambda row: row["id"])[0]
        for _, rows in sorted(groups.items())
    ]
    candidates.sort(key=lambda row: (row["family"], row["genre"], row["id"]))
    if count > len(candidates):
        raise ValueError(f"requested {count} shots but only {len(candidates)} strata exist")
    # Round-robin by family rather than taking only the alphabetically first genre.
    selected: list[dict[str, Any]] = []
    used_families: set[str] = set()
    for candidate in candidates:
        if candidate["family"] not in used_families:
            selected.append(candidate)
            used_families.add(candidate["family"])
            if len(selected) == count:
                return selected
    for candidate in candidates:
        if candidate not in selected:
            selected.append(candidate)
            if len(selected) == count:
                break
    return selected


def messages(pair: dict[str, Any], shots: list[dict[str, Any]]) -> list[dict[str, str]]:
    framed: list[dict[str, str]] = [{"role": "system", "content": SERVING_PROMPT}]
    for shot in shots:
        framed.extend(
            [
                {"role": "user", "content": shot["input"]},
                {"role": "assistant", "content": shot["output"]},
            ]
        )
    framed.append({"role": "user", "content": pair["input"]})
    return framed


def extract_program(reply: str) -> tuple[str | None, str]:
    fences = re.findall(r"```(?:prolog)?\s*\n?(.*?)```", reply, flags=re.DOTALL | re.IGNORECASE)
    candidate = fences[0].strip() if fences else reply.strip()
    start_positions = [
        position
        for marker in ("quantity(", "asks(", "solve(")
        if (position := candidate.find(marker)) >= 0
    ]
    if not start_positions:
        return None, "no-program-marker"
    candidate = candidate[min(start_positions):]
    solve = re.search(r"solve\s*\(\s*A\s*\)\s*:-.*?\.\s*", candidate, re.DOTALL)
    if not solve:
        return None, "no-complete-solve-clause"
    program = candidate[: solve.end()].strip()
    return program, "fenced" if fences else "plain"


def chat(endpoint: str, api_key: str | None, payload: dict[str, Any], timeout: float) -> str:
    url = endpoint.rstrip("/")
    if not url.endswith("/chat/completions"):
        url += "/chat/completions"
    headers = {"Content-Type": "application/json"}
    if api_key:
        headers["Authorization"] = f"Bearer {api_key}"
    request = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers=headers,
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            body = json.loads(response.read().decode("utf-8"))
    except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError) as error:
        raise RuntimeError(f"F1 transport failed: {type(error).__name__}: {error}") from error
    return str(body["choices"][0]["message"]["content"])


def artifact_shape(output_dir: Path, shots: list[dict[str, Any]]) -> None:
    shape = {
        "runner": RUNNER_VERSION,
        "inference_status": "CONTROLLER_RUN",
        "serving_prompt": SERVING_PROMPT,
        "few_shot_ids": [shot["id"] for shot in shots],
        "expected_results_jsonl_fields": [
            "id", "lesson", "grade", "genre", "ground_family", "raw_response",
            "extraction_status", "program", "expected_answer", "result_term",
            "execute_match", "validity_match", "answer_match", "runner",
        ],
        "expected_summary_fields": [
            "runner", "model", "source_sha256", "few_shot_ids", "genre_strata",
        ],
        "output_paths": [RESULTS_NAME, SUMMARY_NAME],
    }
    output_dir.mkdir(parents=True, exist_ok=True)
    write_json(output_dir / "wave5-f1-expected-artifact-shape.json", shape)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--endpoint", help="OpenAI-compatible /v1 endpoint")
    parser.add_argument("--model", help="untuned E2B model name")
    parser.add_argument("--api-key")
    parser.add_argument("--output-dir", type=Path, default=FLOORS)
    parser.add_argument("--few-shots", type=int, default=8)
    parser.add_argument("--timeout", type=float, default=120.0)
    parser.add_argument("--dry-run", action="store_true", help="validate prompts without inference")
    args = parser.parse_args()

    pairs = load_jsonl(PAIRS)
    training = [pair for pair in pairs if pair["split"] == "train"]
    held_out = [pair for pair in pairs if pair["split"] == "held_out"]
    shots = few_shots(training, args.few_shots)
    artifact_shape(args.output_dir, shots)
    if args.dry_run:
        for pair in held_out:
            framed = messages(pair, shots)
            if framed[-1]["content"] != pair["input"]:
                raise RuntimeError(f"prompt framing changed held-out input {pair['id']}")
        print(f"PASS F1 dry-run: {len(held_out)} held-out prompts; no model calls")
        return 0
    if not args.endpoint or not args.model:
        parser.error("--endpoint and --model are required unless --dry-run is used")

    results: list[dict[str, Any]] = []
    with ProgramRunner() as runner:
        for pair in held_out:
            raw = chat(
                args.endpoint,
                args.api_key,
                {
                    "model": args.model,
                    "messages": messages(pair, shots),
                    "temperature": 0,
                    "max_tokens": 256,
                },
                args.timeout,
            )
            program, extraction_status = extract_program(raw)
            execution = (
                runner.run(program, pair["expected_answer"])
                if program
                else {"ok": False, "parsed": False, "ran": False, "answer_match": False, "result_term": ""}
            )
            ran = bool(execution.get("parsed") and execution.get("ran"))
            results.append(
                {
                    "id": pair["id"],
                    "lesson": pair["lesson"],
                    "grade": pair["grade"],
                    "genre": pair["genre"],
                    "ground_family": pair["family"],
                    "raw_response": raw,
                    "extraction_status": extraction_status,
                    "program": program,
                    "expected_answer": pair["expected_answer"],
                    "result_term": execution.get("result_term", ""),
                    "execute_match": ran,
                    "validity_match": ran,
                    "answer_match": bool(execution.get("answer_match")),
                    "runner": execution,
                }
            )
    summary = {
        "runner": RUNNER_VERSION,
        "model": args.model,
        "source": str(PAIRS.relative_to(REPO)),
        "source_sha256": sha256(PAIRS),
        "few_shot_ids": [shot["id"] for shot in shots],
        "temperature": 0,
        "max_tokens": 256,
        "execution_cap_seconds": 3,
        "genre_strata": summarize(results, ("genre",)),
        "genre_family_strata": summarize(results, ("genre", "ground_family")),
    }
    write_jsonl(args.output_dir / RESULTS_NAME, results)
    write_json(args.output_dir / SUMMARY_NAME, summary)
    print(args.output_dir / SUMMARY_NAME)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
