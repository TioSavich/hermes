#!/usr/bin/env python3
"""PML score every thread in every parsed discussion.

Usage:

    python3 score.py
    python3 score.py --only 01_maddy_square_or_diamond
    python3 score.py --force

Reads `output/parsed/<prompt_id>.json` files. For each thread, one Gemma
call produces a PML scoring report. The prompt itself is also scored
once per prompt_id.

Output:
    output/scores/<prompt_id>/prompt_score.md
    output/scores/<prompt_id>/thread_NN_score.md
    output/scores/<prompt_id>.jsonl   (one JSON line per unit)
    output/scores/summary.csv         (combined CSV for grant tables)

Idempotent: skipped if both the per-thread .md and a matching JSONL line
already exist. Pass --force to rescore.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
from html.parser import HTMLParser
import json
import sys
from pathlib import Path

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[3]))

from hermes.app.workflow import service  # noqa: E402
from hermes.app.workflow.lib import api, monitoring as monlib, parser as parselib  # noqa: E402
from hermes.app.workflow.runtime import DATA, HERE  # noqa: E402

PARSED_DIR = DATA / "output" / "parsed"
SCORES_DIR = DATA / "output" / "scores"
SUMMARY_CSV = SCORES_DIR / "summary.csv"


class _HTMLTextExtractor(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.parts: list[str] = []

    def handle_data(self, data: str) -> None:
        text = data.strip()
        if text:
            self.parts.append(text)

    def text(self) -> str:
        return "\n".join(self.parts).strip()


def html_to_text(html: str) -> str:
    parser = _HTMLTextExtractor()
    parser.feed(html)
    return parser.text()


def load_prompt_source(pack_root: Path, prompt_id: str) -> dict | None:
    prompt_path = pack_root / "prompts" / f"{prompt_id}.html"
    if not prompt_path.exists():
        return None
    prompt_text = html_to_text(prompt_path.read_text(encoding="utf-8"))
    if not prompt_text:
        return None
    return {
        "prompt_id": prompt_id,
        "raw_header": prompt_id,
        "instructor_prompt_text": prompt_text,
        "threads": [],
    }


def load_score_inputs(pack_root: Path, only: str | None) -> list[tuple[str, dict]]:
    parsed_dir = pack_root / "output" / "parsed"
    items: list[tuple[str, dict]] = []
    if parsed_dir.exists():
        for parsed_file in sorted(parsed_dir.glob("*.json")):
            prompt_id = parsed_file.stem
            if only and prompt_id != only:
                continue
            parsed = json.loads(parsed_file.read_text(encoding="utf-8"))
            items.append((prompt_id, parsed))

    if not items and only:
        prompt_source = load_prompt_source(pack_root, only)
        if prompt_source:
            items.append((only, prompt_source))

    return items


def pck_block(prompt_id: str) -> str:
    worker_request = service.current_context().worker_request
    prolog_block = monlib.prolog_pck_block(HERE, prompt_id, worker_request=worker_request)
    if prolog_block:
        return prolog_block

    chart = monlib.chart_path_for(HERE, prompt_id)
    if not chart:
        return monlib.prolog_fallback_pck(HERE, prompt_id, worker_request=worker_request)
    excerpt = monlib.pck_section(chart)
    if not excerpt:
        return monlib.prolog_fallback_pck(HERE, prompt_id, worker_request=worker_request)
    return (
        "----- PCK CONTEXT (from monitoring chart; use for PCK Grounding scoring only) -----\n"
        f"Chart: {chart.relative_to(HERE)}\n\n"
        f"{excerpt}\n"
        "----- END PCK CONTEXT -----\n\n"
    )


def render_thread(thread: dict) -> str:
    pieces = []
    for i, p in enumerate(thread.get("posts", [])):
        name = p.get("author_raw_name") or p.get("author_student_id") or "Unknown"
        text = (p.get("text") or "").strip()
        role = (p.get("role") or "").lower()
        if i == 0 or role == "initial":
            header = f"Initial post from {name}"
        elif role == "return":
            header = f"Return post from {name}"
        else:
            header = f"Reply from {name}"
        pieces.append(f"{header}\n{text}")
    return "\n\n".join(pieces).strip()


def stable_hash(*parts: str) -> str:
    h = hashlib.sha256()
    for p in parts:
        h.update(p.encode("utf-8"))
        h.update(b"\0")
    return h.hexdigest()


def score_one(*, label: str, user_content: str, system_prompt: str, client: dict) -> tuple[str, dict | None]:
    print(f"  scoring {label}...", flush=True)
    reply = api.call_api(system_prompt, user_content, **client)
    score_json = parselib.extract_jsonline_loose(reply)
    return reply, score_json


def write_summary(scores_dir: Path) -> None:
    """Aggregate every per-prompt JSONL into output/scores/summary.csv."""
    rows: list[dict] = []
    for jsonl_file in sorted(scores_dir.glob("*.jsonl")):
        prompt_id = jsonl_file.stem
        for line in jsonl_file.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                rec = json.loads(line)
            except json.JSONDecodeError:
                continue
            rows.append({
                "prompt_id": prompt_id,
                "unit": rec.get("unit", ""),
                "authors": "|".join(rec.get("authors", []) or []),
                "openness": rec.get("openness", ""),
                "discussion_affordance": rec.get("discussion_affordance", ""),
                "async_protocol": rec.get("async_protocol", ""),
                "passage_modes": "|".join(rec.get("passage_modes", []) or []),
                "verdict": rec.get("verdict", ""),
            })
    if not rows:
        return
    fields = ["prompt_id", "unit", "authors", "openness", "discussion_affordance",
              "async_protocol", "passage_modes", "verdict"]
    with SUMMARY_CSV.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(rows)


def _main(argv: list[str] | None = None) -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--only", help="Only score one prompt_id.")
    ap.add_argument("--force", action="store_true", help="Re-score even if outputs already exist.")
    ap.add_argument("--skip-prompts", action="store_true", help="Skip scoring the prompts themselves; only score threads.")
    args = ap.parse_args(argv)

    score_inputs = load_score_inputs(DATA, args.only)
    if not score_inputs:
        if args.only:
            api.fail(
                f"no parsed file or prompts/{args.only}.html source found for {args.only}."
            )
        api.fail("no parsed files in output/parsed/. Run parse.py first.")

    client = api.make_client(DATA)
    system_prompt = (HERE / "system_prompts" / "score.md").read_text(encoding="utf-8")
    SCORES_DIR.mkdir(parents=True, exist_ok=True)

    for prompt_id, parsed in score_inputs:
        prompt_text = parsed.get("instructor_prompt_text", "") or ""
        threads = parsed.get("threads", [])
        prompt_dir = SCORES_DIR / prompt_id
        prompt_dir.mkdir(parents=True, exist_ok=True)
        jsonl_path = SCORES_DIR / f"{prompt_id}.jsonl"

        # Reset JSONL when forcing a fresh run for this prompt.
        if args.force and jsonl_path.exists():
            jsonl_path.unlink()

        existing_units = {r.get("unit") for r in parselib.read_jsonl(jsonl_path)}

        # Score the prompt itself.
        if prompt_text and not args.skip_prompts:
            prompt_score_path = prompt_dir / "prompt_score.md"
            if prompt_score_path.exists() and "prompt" in existing_units and not args.force:
                print(f"{prompt_id} (prompt): cached")
            else:
                user_content = (
                    f"UNIT: prompt\nPROMPT_ID: {prompt_id}\n\n"
                    "Score the discussion prompt itself in question-lite mode.\n\n"
                    + pck_block(prompt_id)
                    + "----- PROMPT TEXT -----\n" + prompt_text
                )
                reply, sjson = score_one(
                    label=f"{prompt_id} (prompt)",
                    user_content=user_content,
                    system_prompt=system_prompt,
                    client=client,
                )
                prompt_score_path.write_text(reply, encoding="utf-8")
                if sjson is None:
                    sjson = {"unit": "prompt", "prompt_id": prompt_id, "parse_error": True}
                sjson.setdefault("prompt_id", prompt_id)
                parselib.append_jsonl(jsonl_path, sjson)

        # Score each thread.
        for thread in threads:
            i = thread.get("thread_index") or (threads.index(thread) + 1)
            unit_label = f"thread {i}"
            thread_score_path = prompt_dir / f"thread_{i:02d}_score.md"
            if (
                thread_score_path.exists()
                and unit_label in existing_units
                and not args.force
            ):
                print(f"{prompt_id} {unit_label}: cached")
                continue

            thread_text = render_thread(thread)
            if not thread_text:
                print(f"{prompt_id} {unit_label}: empty after parse; skipping")
                continue

            authors = [
                p.get("author_student_id") for p in thread.get("posts", [])
                if p.get("author_student_id")
            ]
            user_content = (
                f"UNIT: {unit_label}\nPROMPT_ID: {prompt_id}\n\n"
                "Score this single thread in transcript-full + async-protocol mode.\n"
                "Apply the anti-parrot rule.\n\n"
                + pck_block(prompt_id)
                + "----- DISCUSSION PROMPT (reference; do not score) -----\n"
                + (prompt_text or "(prompt text not included in this parsed file)")
                + "\n\n----- THREAD -----\n"
                + thread_text
            )
            reply, sjson = score_one(
                label=f"{prompt_id} {unit_label}",
                user_content=user_content,
                system_prompt=system_prompt,
                client=client,
            )
            thread_score_path.write_text(reply, encoding="utf-8")
            if sjson is None:
                sjson = {"unit": unit_label, "prompt_id": prompt_id, "parse_error": True}
            sjson.setdefault("prompt_id", prompt_id)
            sjson.setdefault("authors", authors)
            parselib.append_jsonl(jsonl_path, sjson)

    write_summary(SCORES_DIR)
    print(f"done. {SCORES_DIR.relative_to(HERE)}/")


def run(payload: dict, context: service.WorkflowContext) -> service.WorkflowResult:
    return service.run_command("score", payload, context, _main)


def main(argv: list[str] | None = None) -> int:
    return service.run_cli("score", argv, _main)


if __name__ == "__main__":
    raise SystemExit(main())
