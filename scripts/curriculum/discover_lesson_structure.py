#!/usr/bin/env python3
"""Read IM lesson guides for their document structure, with a model's help.

The IM teacher guide is a two-column PDF text extract with labeled regions:
standards, goals, purpose, narrative, materials, timeline, then a sequence of
Warm-up, Activity N and Cool-down blocks, each carrying a narrative, a launch,
a student task statement, a student response, an activity synthesis, and
sometimes advancing-student-thinking prompts.

The regions are regular; the column offsets are not.  This script asks a model
to name each region and its line range, then checks that testimony against the
deterministic extractor the repository already trusts.  The model never decides
anything on its own: its answer is a proposal, the extractor is the referee,
and the disagreements are the finding.

One JSONL row per lesson, written after each call, so a long run resumes.
"""
from __future__ import annotations

import argparse
import json
import os
import pathlib
import random
import re
import sys
import threading
import time
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Any

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "scripts/research"))

from hermes.app import llm  # noqa: E402

GUIDES = ROOT / "curriculum/im_teacher_guides"
DEFAULT_OUT = ROOT / "hermes/app/runtime/experiments/language/lesson_structure.jsonl"

REGION_TYPES = [
    "lesson_header",
    "standards",
    "instructional_routines",
    "teacher_learning_goals",
    "student_facing_learning_goals",
    "lesson_purpose",
    "lesson_narrative",
    "access_disabilities",
    "access_english_learners",
    "required_materials",
    "lesson_timeline",
    "teacher_reflection_questions",
    "warm_up",
    "activity",
    "cool_down",
    "activity_narrative",
    "launch",
    "activity_steps",
    "student_task_statement",
    "student_response",
    "activity_synthesis",
    "advancing_student_thinking",
    "lesson_synthesis",
    "are_you_ready_for_more",
    "suggested_centers",
    "page_furniture",
]

TASK_KINDS = [
    "printed_expressions",
    "word_problem",
    "figure_dependent",
    "discussion_prompt",
    "construction_or_drawing",
    "mixed",
]

SYSTEM = (
    "You read Illustrative Mathematics teacher guide pages that were extracted "
    "from a two-column PDF. You name the regions of the page and where each one "
    "starts and ends. You answer with JSON only. You never invent a region that "
    "the text does not carry, and you never guess a line number you cannot see."
)

INSTRUCTION = """Below is one lesson from an Illustrative Mathematics teacher guide.
Every line carries its line number followed by a tab.

Return JSON with exactly these keys:

{{
  "lesson_code": string or null,
  "unit": integer or null,
  "lesson": integer or null,
  "title": string or null,
  "standards": [string],
  "regions": [
    {{"type": one of {regions},
      "label": string,
      "line_start": integer,
      "line_end": integer,
      "column": "left" | "right" | "full",
      "activity_index": integer or null}}
  ],
  "task_statements": [
    {{"line_start": integer,
      "line_end": integer,
      "activity_index": integer or null,
      "kind": one of {kinds},
      "question_count": integer,
      "printed_expressions": [string],
      "asks": [string]}}
  ],
  "responses": [
    {{"line_start": integer, "line_end": integer, "activity_index": integer or null}}
  ],
  "teacher_questions": [
    {{"line": integer, "text": string, "region_type": string}}
  ],
  "uncertain": [string]
}}

Rules:
- `printed_expressions` holds arithmetic written in symbols, copied verbatim,
  for example "7 + 1" or "336- 52". Never compute anything.
- `asks` holds the question or direction the task puts to the student, copied
  verbatim, for example "Find the value of each expression mentally."
- `teacher_questions` holds questions addressed to the teacher or asked by the
  teacher of the class, from launches, syntheses, and reflection prompts.
- Put anything you are unsure about in `uncertain` and leave the field out
  rather than guessing.
- JSON only. No prose before or after.

LESSON:
{body}
"""


def lesson_code(path: pathlib.Path) -> str:
    grade = path.parts[-3]
    grade = "K" if grade == "kindergarten" else grade.replace("grade", "")
    unit = path.parts[-2].replace("unit", "")
    lesson = path.stem.replace("lesson", "")
    return f"IM-G{grade}-U{unit}-L{lesson}"


def numbered(text: str, limit: int) -> str:
    lines = text.splitlines()[:limit]
    return "\n".join(f"{index + 1}\t{line}" for index, line in enumerate(lines))


def raw_extract_body(text: str) -> str:
    """The fenced raw extract if present, else the whole file."""
    match = re.search(r"```\n(.*?)\n```", text, re.S)
    return match.group(1) if match else text


def deterministic_task_statements(text: str) -> list[tuple[int, int]]:
    """What the repository's own extractor finds, as line ranges."""
    import extract_lesson_context as context

    raw = context.raw_extract(text)
    if raw is None:
        return []
    lines, offset = raw
    found: list[tuple[int, int]] = []
    current = "Lesson"
    index = 0
    while index < len(lines):
        heading = context.section_heading(lines[index])
        if heading:
            current = heading
        if "Student Task Statement" in lines[index]:
            item, nxt = context.task_statement(lines, index, current)
            if item is not None:
                found.append((index + 1 + offset, max(nxt, index + 1) + offset))
            index = nxt
            continue
        index += 1
    return found


def parse_json(content: str) -> Any:
    text = content.strip()
    fence = re.search(r"```(?:json)?\s*(.*?)```", text, re.S)
    if fence:
        text = fence.group(1).strip()
    start = text.find("{")
    end = text.rfind("}")
    if start == -1 or end == -1:
        raise ValueError("no JSON object in reply")
    return json.loads(text[start : end + 1])


def select(sample: int, seed: int, every_grade: bool) -> list[pathlib.Path]:
    files = [
        path
        for path in sorted(GUIDES.glob("*/unit*/lesson[0-9]*.md"))
        if re.fullmatch(r"lesson\d+", path.stem)
    ]
    if not every_grade or sample >= len(files):
        random.Random(seed).shuffle(files)
        return files[:sample]
    by_grade: dict[str, list[pathlib.Path]] = {}
    for path in files:
        by_grade.setdefault(path.parts[-3], []).append(path)
    per = max(1, sample // len(by_grade))
    chosen: list[pathlib.Path] = []
    for grade in sorted(by_grade):
        group = by_grade[grade][:]
        random.Random(seed).shuffle(group)
        chosen.extend(group[:per])
    return chosen[:sample]


def call_local(
    endpoint: str, model: str, messages: list[dict], max_tokens: int, timeout: int
) -> tuple[str, str]:
    """One chat completion against a local OpenAI-compatible server.

    Returns (outcome, content).  Big Red compute nodes carry no external
    network, so the same prompt reaches a node-local llama-server here instead
    of REALLMS.  The transport rule is the same either way: never read the
    content unless the outcome is ok.
    """
    import urllib.error
    import urllib.request

    payload = json.dumps(
        {
            "model": model,
            "messages": messages,
            "max_tokens": max_tokens,
            "temperature": 0.0,
            "stream": False,
        }
    ).encode("utf-8")
    request = urllib.request.Request(
        endpoint.rstrip("/") + "/v1/chat/completions",
        data=payload,
        headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            body = json.loads(response.read())
    except Exception as error:  # noqa: BLE001
        return f"transport:{type(error).__name__}", ""
    choices = body.get("choices") or []
    if not choices:
        return "no_choices", ""
    finish = choices[0].get("finish_reason")
    content = (choices[0].get("message") or {}).get("content") or ""
    if finish not in ("stop", None):
        return f"finish:{finish}", content
    return "ok", content


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sample", type=int, default=24)
    parser.add_argument("--seed", type=int, default=11)
    parser.add_argument("--model", default="glm-5.2")
    parser.add_argument("--out", type=pathlib.Path, default=DEFAULT_OUT)
    parser.add_argument("--max-lines", type=int, default=900)
    parser.add_argument("--max-tokens", type=int, default=8192)
    parser.add_argument("--all-grades", action="store_true", default=True)
    parser.add_argument("--restart", action="store_true")
    parser.add_argument("--workers", type=int, default=1)
    parser.add_argument(
        "--endpoint",
        default=None,
        help="Local OpenAI-compatible server, e.g. http://127.0.0.1:18000. "
        "When set, REALLMS is not called at all.",
    )
    args = parser.parse_args()

    key = url = ssl_ctx = None
    if not args.endpoint:
        llm.load_dotenv(ROOT)
        key = os.environ.get("REALLMS_API_KEY")
        if not key:
            raise SystemExit("REALLMS_API_KEY missing")
        url = llm.resolve_api_url()
        ssl_ctx = llm.build_ssl_context()

    args.out.parent.mkdir(parents=True, exist_ok=True)
    done: set[str] = set()
    if args.out.exists() and not args.restart:
        for line in args.out.read_text(encoding="utf-8").splitlines():
            try:
                done.add(json.loads(line)["lesson"])
            except Exception:
                continue
    elif args.restart and args.out.exists():
        args.out.unlink()

    targets = [p for p in select(args.sample, args.seed, args.all_grades) if lesson_code(p) not in done]
    print(f"lessons selected {len(targets)} (already done {len(done)})", flush=True)

    stats: Counter[str] = Counter()

    def read_one(path: pathlib.Path) -> dict[str, Any]:
        code = lesson_code(path)
        text = path.read_text(encoding="utf-8", errors="replace")
        body = numbered(raw_extract_body(text), args.max_lines)
        prompt = INSTRUCTION.format(
            regions=json.dumps(REGION_TYPES),
            kinds=json.dumps(TASK_KINDS),
            body=body,
        )
        messages = [
            {"role": "system", "content": SYSTEM},
            {"role": "user", "content": prompt},
        ]
        started = time.time()
        if args.endpoint:
            outcome, content = call_local(
                args.endpoint, args.model, messages, args.max_tokens, 900
            )
        else:
            result = llm.call_api_messages_result(
                messages,
                api_key=key,
                api_url=url,
                model=args.model,
                ssl_ctx=ssl_ctx,
                max_tokens=args.max_tokens,
                timeout=900,
            )
            outcome = result.outcome if result.outcome == "ok" else (
                result.finish_reason or result.outcome or "transport"
            )
            content = result.content
        row: dict[str, Any] = {
            "lesson": code,
            "path": str(path.relative_to(ROOT)),
            "model": args.model,
            "outcome": outcome,
            "seconds": round(time.time() - started, 2),
        }
        if outcome != "ok":
            row["error"] = outcome
            return row
        try:
            structure = parse_json(content)
        except Exception as error:  # noqa: BLE001
            row["error"] = f"{type(error).__name__}: {error}"
            row["raw_head"] = content[:400]
            return row
        row["structure"] = structure
        # The referee: the repository's own extractor, never the model.
        theirs = [
            (task.get("line_start"), task.get("line_end"))
            for task in structure.get("task_statements") or []
        ]
        ours = deterministic_task_statements(text)
        row["referee"] = {
            "extractor_statements": len(ours),
            "model_statements": len(theirs),
            "extractor_ranges": ours,
        }
        return row

    def tally(row: dict[str, Any]) -> None:
        if row.get("error"):
            stats["parse_failed" if "structure" not in row and row["outcome"] == "ok" else "transport_failed"] += 1
            return
        structure = row.get("structure") or {}
        stats["ok"] += 1
        for region in structure.get("regions") or []:
            stats[f"region:{region.get('type')}"] += 1
        for task in structure.get("task_statements") or []:
            stats[f"task_kind:{task.get('kind')}"] += 1
        stats["teacher_questions"] += len(structure.get("teacher_questions") or [])
        stats["printed_expressions"] += sum(
            len(task.get("printed_expressions") or [])
            for task in structure.get("task_statements") or []
        )
        referee = row.get("referee") or {}
        stats["extractor_statements"] += referee.get("extractor_statements", 0)
        stats["model_statements"] += referee.get("model_statements", 0)
        if referee.get("model_statements", 0) > referee.get("extractor_statements", 0):
            stats["model_found_more"] += 1
        elif referee.get("model_statements", 0) < referee.get("extractor_statements", 0):
            stats["extractor_found_more"] += 1
        else:
            stats["counts_match"] += 1

    handle = args.out.open("a", encoding="utf-8")
    write_lock = threading.Lock()
    finished = 0
    try:
        with ThreadPoolExecutor(max_workers=max(1, args.workers)) as pool:
            futures = {pool.submit(read_one, path): path for path in targets}
            for future in as_completed(futures):
                path = futures[future]
                try:
                    row = future.result()
                except Exception as error:  # noqa: BLE001
                    row = {
                        "lesson": lesson_code(path),
                        "path": str(path.relative_to(ROOT)),
                        "model": args.model,
                        "outcome": "error",
                        "error": f"{type(error).__name__}: {error}",
                    }
                with write_lock:
                    finished += 1
                    tally(row)
                    handle.write(json.dumps(row, ensure_ascii=False) + "\n")
                    handle.flush()
                    print(
                        f"[{finished}/{len(targets)}] {row['lesson']} "
                        f"{row['outcome']} {row.get('error', '')} "
                        f"{row.get('seconds', 0)}s",
                        flush=True,
                    )
    finally:
        handle.close()

    print("\n== summary ==", flush=True)
    for name, count in sorted(stats.items()):
        print(f"{count:6d}  {name}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
