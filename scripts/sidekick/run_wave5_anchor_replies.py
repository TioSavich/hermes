#!/usr/bin/env python3
"""Generate untuned replies to the wave-5 anchor prompts.

One command, run by the controller (this session's sandbox cannot reach the
serving endpoint): read the frozen anchor prompts, ask the untuned
`gemma4:e2b` checkpoint each one at temperature 0 through the local Ollama
endpoint, and write one reply row per prompt. Those replies are the
forgetting-guard targets wave 5 mixes into training at roughly 20% — the
tuned model is meant to still sound like this on an ordinary teaching
question after training on Prolog programs.

The system prompt is fixed and minimal, printed below and recorded in the
run manifest so the exact wording used for a batch of replies is on record
next to it, not left to be reconstructed from memory later.

Resumable: an id already present in the output file is skipped, so a
second run after a crash or a `--limit` continues rather than repeating
calls. The input prompts file's sha256 is pinned in a manifest next to the
output on the first run and checked on every later run; if the prompts
file has changed since, the run refuses rather than mixing replies to two
different prompt sets in one output file.

Standard library only for the HTTP call (urllib), per the no-new-dependency
constraint on this file.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
import threading
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]

DATASETS_DIR = REPO_ROOT / "hermes" / "app" / "runtime" / "experiments" / "sidekick" / "datasets"
PROMPTS_PATH = DATASETS_DIR / "wave5-anchor-prompts.jsonl"
OUTPUT_PATH = DATASETS_DIR / "wave5-anchor-replies.jsonl"
MANIFEST_PATH = DATASETS_DIR / "wave5-anchor-replies-manifest.json"

ENDPOINT = "http://127.0.0.1:11434/api/chat"
MODEL = "gemma4:e2b"
TEMPERATURE = 0.0
MAX_REPLY_TOKENS = 600
REQUEST_TIMEOUT_SECONDS = 120.0

# Minimal on purpose: the reply this elicits is the forgetting-guard target,
# so the prompt should look like an ordinary request to a teacher's
# assistant, not a framing that steers the register in some other way.
SYSTEM_PROMPT = "You are a mathematics teacher's assistant. Answer the teacher directly, in plain language."


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def sha256_text(text: str) -> str:
    return sha256_bytes(text.encode("utf-8"))


def load_prompts(path: Path) -> list[dict[str, Any]]:
    rows = []
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if line:
                rows.append(json.loads(line))
    return rows


def load_existing_replies(path: Path) -> dict[str, dict[str, Any]]:
    if not path.is_file():
        return {}
    rows: dict[str, dict[str, Any]] = {}
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if line:
                row = json.loads(line)
                rows[row["id"]] = row
    return rows


def check_or_write_manifest(prompts_sha256: str) -> None:
    """Pin the prompts file's sha256 on first run; refuse a mismatch later."""
    if MANIFEST_PATH.is_file():
        manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
        pinned = manifest.get("prompts_sha256")
        if pinned != prompts_sha256:
            print(
                "REFUSING: wave5-anchor-prompts.jsonl has changed since this "
                f"run's manifest was written (pinned {pinned}, now {prompts_sha256}). "
                "Move or delete the existing replies output and manifest to start "
                "a fresh run against the new prompts file.",
                file=sys.stderr,
            )
            raise SystemExit(1)
        return
    MANIFEST_PATH.parent.mkdir(parents=True, exist_ok=True)
    manifest = {
        "prompts_path": str(PROMPTS_PATH.relative_to(REPO_ROOT)),
        "prompts_sha256": prompts_sha256,
        "endpoint": ENDPOINT,
        "model": MODEL,
        "temperature": TEMPERATURE,
        "max_reply_tokens": MAX_REPLY_TOKENS,
        "system_prompt": SYSTEM_PROMPT,
    }
    MANIFEST_PATH.write_text(json.dumps(manifest, sort_keys=True, indent=2) + "\n", encoding="utf-8")


def call_ollama(prompt: str, timeout: float) -> str:
    body = {
        "model": MODEL,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": prompt},
        ],
        "stream": False,
        "think": False,
        "options": {"temperature": TEMPERATURE, "num_predict": MAX_REPLY_TOKENS},
    }
    request = urllib.request.Request(
        ENDPOINT, data=json.dumps(body).encode("utf-8"), headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        payload = json.loads(response.read())
    return payload.get("message", {}).get("content", "")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--limit", type=int, default=None,
        help="stop after this many NEW replies this invocation (existing rows are always skipped)",
    )
    parser.add_argument("--timeout", type=float, default=REQUEST_TIMEOUT_SECONDS)
    parser.add_argument(
        "--ids-file", type=Path, default=None,
        help="answer only the ids listed one per line in this file",
    )
    parser.add_argument(
        "--workers", type=int, default=1,
        help="how many requests are in flight at once; replies are written as they land",
    )
    arguments = parser.parse_args()

    if not PROMPTS_PATH.is_file():
        print(f"no prompts file at {PROMPTS_PATH}; run build_wave5_anchor_prompts.py first", file=sys.stderr)
        return 1

    prompts = load_prompts(PROMPTS_PATH)
    prompts_sha256 = sha256_file(PROMPTS_PATH)
    check_or_write_manifest(prompts_sha256)

    existing = load_existing_replies(OUTPUT_PATH)
    for row in prompts:
        prior = existing.get(row["id"])
        if prior is not None and prior.get("prompt_sha256") != sha256_text(row["prompt"]):
            print(
                f"REFUSING: existing reply for id {row['id']} was recorded against different "
                "prompt text than the current prompts file has for that id.",
                file=sys.stderr,
            )
            return 1

    todo = [row for row in prompts if row["id"] not in existing]
    if arguments.ids_file is not None:
        wanted = {
            line.strip()
            for line in arguments.ids_file.read_text(encoding="utf-8").splitlines()
            if line.strip()
        }
        todo = [row for row in todo if row["id"] in wanted]
    if arguments.limit is not None:
        todo = todo[: arguments.limit]

    print(f"prompts: {len(prompts)}  already answered: {len(existing)}  to answer this run: {len(todo)}")

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    answered = 0
    failures: list[str] = []
    write_lock = threading.Lock()

    def answer(row: dict[str, Any]) -> str | None:
        try:
            reply = call_ollama(row["prompt"], arguments.timeout)
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
            return f"{row['id']}: {type(exc).__name__} {exc}"
        # The system prompt and the prompt's own stratum travel with the reply:
        # the sequence builder renders the same system turn the reply was given
        # under, and the token accounting keeps anchors separable.
        out_row = {
            "id": row["id"],
            "prompt": row["prompt"],
            "reply": reply,
            "system": SYSTEM_PROMPT,
            "grade": row.get("grade"),
            "lesson": row.get("lesson"),
            "template_id": row.get("template_id"),
            "model": MODEL,
            "temperature": TEMPERATURE,
            "prompt_sha256": sha256_text(row["prompt"]),
        }
        line = json.dumps(out_row, sort_keys=True, ensure_ascii=False) + "\n"
        with write_lock:
            handle.write(line)
            handle.flush()
        return None

    with OUTPUT_PATH.open("a", encoding="utf-8") as handle:
        if arguments.workers > 1:
            with ThreadPoolExecutor(max_workers=arguments.workers) as pool:
                for result in pool.map(answer, todo):
                    if result is None:
                        answered += 1
                    else:
                        failures.append(result)
        else:
            for row in todo:
                result = answer(row)
                if result is None:
                    answered += 1
                else:
                    failures.append(result)
    for failure in failures:
        print(f"request failed for {failure}", file=sys.stderr)

    total_rows = len(existing) + answered
    output_sha256 = sha256_file(OUTPUT_PATH) if OUTPUT_PATH.is_file() else ""
    print(f"answered this run: {answered}")
    print(f"total rows in output: {total_rows}")
    print(f"output sha256: {output_sha256}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
