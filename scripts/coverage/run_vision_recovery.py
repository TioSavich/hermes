#!/usr/bin/env python3
"""Vision serving for the 2026-08-18 vision wave.

Reads vision_targets.jsonl (scripts/coverage/build_vision_targets.py) and
recovers STRUCTURED content for each statement's candidate images: counts of
discrete objects (grouped how), any table as pipe-serialized rows, any
labeled values/coordinates/marks, any expression or equation shown --
verbatim numerals, no interpretation.

Serving choice (recorded, not re-derived here): REALLMS gemma-4-31B-it.
Verified live 2026-08-18 (this session) with a real docling image before
this script was written; the base64 image_url multimodal call pattern is
scripts/curriculum/vision_pass.py's, reused via hermes/app/llm.py. Big Red's
node-local llama-server path was available (channel checked live, master
running) but standing up rsync + SLURM + gpu-debug smoke costs far more wall
time than a direct REALLMS call from the controller, for a batch this size.

Calls are deduped by (lesson, sorted image ref tuple): several statements in
the same section (e.g. Part A / Part B splits) often share one image set,
and a docling lesson directory's IM-logo/furniture images are already
excluded by build_vision_targets.py's targeting, not here.

Checkpointed per call-group key; reruns resume without repeating a call.
Rows whose targeting already found an inline "Description of the Image"
block cost no call (build_vision_targets.py) and are folded in from there.
"""
from __future__ import annotations

import argparse
import base64
import concurrent.futures
import importlib.util
import json
import mimetypes
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
GRIND = REPO / "hermes" / "app" / "runtime" / "experiments" / "coverage_grind"

sys.path.insert(0, str(REPO))
_llm_spec = importlib.util.spec_from_file_location("hermes_llm_vision_recovery", REPO / "hermes" / "app" / "llm.py")
llm = importlib.util.module_from_spec(_llm_spec)
sys.modules[_llm_spec.name] = llm
_llm_spec.loader.exec_module(llm)

MODEL = "gemma-4-31B-it"
# 31B spends its budget on reasoning_content below ~2500 max_tokens and
# returns empty content with finish_reason=length (memory:
# reallms-two-auth-stacks.md, thinking-model-breaks-benchmark-stops.md,
# reproduced live in this session's --limit 6 smoke: 3/6 truncated at 1400).
MAX_TOKENS = 4000
TIMEOUT = 150
RETRIES = 3

VISION_PROMPT = """You are reading ONE or more images cropped from a K-8 mathematics teacher's
lesson guide. Report only what is literally printed or drawn -- never solve,
interpret, or add anything not visible.

Reply with ONLY one JSON object, no prose, in exactly this shape:
{
 "counts": [{"group": "<what is being counted, e.g. 'red counters'>", "n": <integer>}],
 "table_rows": ["<row 1, pipe-separated cells, e.g. 'x | y'>", "<row 2>", "..."],
 "labels": [{"label": "<the printed label or coordinate>", "value": "<the value shown next to it, or null>"}],
 "expressions": ["<any equation or expression exactly as printed>"],
 "summary": "<one plain sentence naming what the image(s) show, no numbers invented>"
}

Rules: every number in "counts", "table_rows", "labels", and "expressions"
must be a number you can actually see printed or drawn in the image -- never
a computed or inferred value. If nothing in the image has any of these four
kinds of content, use empty lists for all four keys and describe the image
in "summary" only. If multiple images are attached, cover all of them in one
reply."""


def image_data_url(path: Path) -> str:
    mime_type = mimetypes.guess_type(path.name)[0] or "image/png"
    encoded = base64.b64encode(path.read_bytes()).decode("ascii")
    return f"data:{mime_type};base64,{encoded}"


def build_messages(image_paths: list[Path]) -> list[dict]:
    content = [{"type": "text", "text": VISION_PROMPT}]
    for p in image_paths:
        content.append({"type": "image_url", "image_url": {"url": image_data_url(p)}})
    return [{"role": "user", "content": content}]


def parse_vision_json(content: str) -> dict | None:
    stripped = (content or "").strip()
    if stripped.startswith("```"):
        lines = stripped.splitlines()
        if lines and lines[0].startswith("```"):
            lines = lines[1:]
        if lines and lines[-1].strip() == "```":
            lines = lines[:-1]
        stripped = "\n".join(lines).strip()
    start = stripped.find("{")
    end = stripped.rfind("}")
    if start == -1 or end == -1 or end < start:
        return None
    try:
        obj = json.loads(stripped[start:end + 1])
    except json.JSONDecodeError:
        return None
    if not isinstance(obj, dict):
        return None
    for key, default in (("counts", []), ("table_rows", []), ("labels", []), ("expressions", [])):
        if key not in obj or not isinstance(obj[key], list):
            obj[key] = default
    if not isinstance(obj.get("summary"), str):
        obj["summary"] = ""
    return obj


def group_key(row: dict) -> tuple:
    return (row["lesson"], tuple(sorted(im["source_ref"] for im in row["images"])))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--targets", default=str(GRIND / "vision_targets.jsonl"))
    ap.add_argument("--output", default=str(GRIND / "vision_recovery_checkpoints.jsonl"))
    ap.add_argument("--workers", type=int, default=8)
    ap.add_argument("--limit", type=int, default=0)
    args = ap.parse_args()

    rows = [json.loads(l) for l in open(args.targets, encoding="utf-8") if l.strip()]

    llm.load_dotenv(REPO)
    api_url = llm.resolve_api_url()
    api_key = llm.require_api_key()
    ssl_ctx = llm.build_ssl_context()

    groups: dict[tuple, list[dict]] = {}
    inline_groups: dict[tuple, str] = {}
    for row in rows:
        inline = next((im["inline_description"] for im in row["images"]
                        if im.get("inline_description")), None)
        key = group_key(row)
        if inline is not None:
            inline_groups.setdefault(key, inline)
            continue
        groups.setdefault(key, row["images"])

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    done: dict[str, dict] = {}
    if out_path.exists():
        for line in open(out_path, encoding="utf-8"):
            line = line.strip()
            if not line:
                continue
            try:
                r = json.loads(line)
                done[r["group_key"]] = r
            except (json.JSONDecodeError, KeyError):
                continue

    def key_str(k: tuple) -> str:
        return json.dumps(list(k), ensure_ascii=False)

    todo = [(k, imgs) for k, imgs in groups.items() if key_str(k) not in done]
    if args.limit:
        todo = todo[: args.limit]
    print(f"call_groups={len(groups)} inline_groups={len(inline_groups)} "
          f"already_done={len(done)} todo={len(todo)}", flush=True)

    def call_one(key: tuple, images: list[dict]) -> dict:
        paths = [REPO / im["path"] for im in images]
        t0 = time.time()
        try:
            result = llm.call_api_messages_result(
                build_messages(paths), api_key=api_key, api_url=api_url,
                model=MODEL, ssl_ctx=ssl_ctx, retries=RETRIES, timeout=TIMEOUT,
                max_tokens=MAX_TOKENS)
        except Exception as exc:  # per-item guard
            return {"group_key": key_str(key), "lesson": key[0],
                    "image_refs": list(key[1]), "outcome": "exception",
                    "error": f"{type(exc).__name__}: {exc}"[:300],
                    "elapsed_s": round(time.time() - t0, 1),
                    "model": MODEL}
        elapsed = round(time.time() - t0, 1)
        base = {"group_key": key_str(key), "lesson": key[0],
                "image_refs": list(key[1]), "model": MODEL,
                "elapsed_s": elapsed}
        if result.outcome != "ok":
            return {**base, "outcome": result.outcome, "error": result.error}
        parsed = parse_vision_json(result.content)
        if parsed is None:
            return {**base, "outcome": "unparseable", "raw_content": result.content[:2000]}
        return {**base, "outcome": "ok", "content": parsed}

    with open(out_path, "a", encoding="utf-8") as out:
        with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
            futures = {pool.submit(call_one, k, imgs): k for k, imgs in todo}
            n = 0
            counts: dict[str, int] = {}
            for fut in concurrent.futures.as_completed(futures):
                row = fut.result()
                out.write(json.dumps(row, ensure_ascii=False) + "\n")
                out.flush()
                n += 1
                counts[row["outcome"]] = counts.get(row["outcome"], 0) + 1
                if n % 20 == 0 or n == len(todo):
                    print(f"[{n}/{len(todo)}] {json.dumps(counts)}", flush=True)

    print("FINAL " + json.dumps(counts if todo else {"nothing_to_do": True}), flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
