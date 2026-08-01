#!/usr/bin/env python3
"""Ask a model for one scene per item, gate it, typeset it, checkpoint as it goes.

One code path for both runtime targets, as in round 1: local Ollama at
:11434/v1 and llama-server on a compute node both speak the OpenAI chat shape.

Two changes from the round-1 driver. The request asks for a JSON object where
the endpoint supports `response_format`, falling back silently where it does
not, since neither refusing nor crashing on an older server is useful. And a
schema violation gets ONE retry that quotes the violation back -- a second
attempt with the path named is cheap, and if the model still cannot hit the
vocabulary that is a finding about the design rather than something to hide.

Typesetting runs here, beside the gate, because the gate cannot pass an item it
has not drawn. On the cluster that costs nothing: the typesetter is standard
library and needs no model.

Standard library only, plus whatever gate_scene reaches for.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from gate_scene import gate                              # noqa: E402

try:
    from gate_svg import find_rasteriser
except ImportError:                                       # pragma: no cover
    def find_rasteriser():
        return None, "none"


def log(msg: str) -> None:
    print(f"[{time.strftime('%H:%M:%S')}] {msg}", flush=True)


def call_model(base_url: str, model: str, prompt: str, *, timeout: int,
               max_tokens: int, temperature: float,
               want_json: bool) -> tuple[str, dict]:
    payload = {
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": temperature,
        "max_tokens": max_tokens,
        "stream": False,
    }
    if want_json:
        payload["response_format"] = {"type": "json_object"}

    def _post(body: dict) -> dict:
        req = urllib.request.Request(
            base_url.rstrip("/") + "/chat/completions",
            data=json.dumps(body).encode(),
            headers={"Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.loads(resp.read())

    used_json_mode = want_json
    try:
        out = _post(payload)
    except urllib.error.HTTPError as exc:
        if not want_json or exc.code not in (400, 404, 422, 500):
            raise
        # An endpoint that does not know response_format says so with a 4xx.
        # Drop it and rely on the fence stripper, which round 1 showed is enough.
        payload.pop("response_format", None)
        used_json_mode = False
        out = _post(payload)

    choice = (out.get("choices") or [{}])[0]
    msg = choice.get("message") or {}
    text = msg.get("content") or ""
    return text, {
        "finish_reason": choice.get("finish_reason"),
        "usage": out.get("usage"),
        "had_reasoning_channel": bool(msg.get("reasoning_content")),
        "json_mode": used_json_mode,
    }


RETRY_PREFIX = """\
Your previous reply was a JSON object but it broke the vocabulary at this path:

    {err}

Fix that one thing and reply again with the whole scene as JSON only. Change
nothing else. Remember: no coordinates, sizes, or colours anywhere, and only the
block types the vocabulary lists.

"""


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--items", default="items/items.jsonl")
    ap.add_argument("--out", default="out")
    ap.add_argument("--base-url", default="http://localhost:11434/v1")
    ap.add_argument("--model", default="gemma4:e2b")
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--only", default="")
    ap.add_argument("--timeout", type=int, default=900)
    ap.add_argument("--max-tokens", type=int, default=4096)
    ap.add_argument("--temperature", type=float, default=0.3)
    ap.add_argument("--attempts", type=int, default=2,
                    help="total tries per item; a retry quotes the schema path")
    ap.add_argument("--no-json-mode", action="store_true")
    ap.add_argument("--resume", action="store_true")
    ap.add_argument("--run-label", default="")
    args = ap.parse_args()

    here = Path(__file__).resolve().parent
    items_path = (here / args.items) if not os.path.isabs(args.items) else Path(args.items)
    out_dir = (here / args.out) if not os.path.isabs(args.out) else Path(args.out)
    label = args.run_label or time.strftime("%Y%m%d-%H%M%S")
    run_dir = out_dir / label
    for sub in ("svg", "raw", "scene"):
        (run_dir / sub).mkdir(parents=True, exist_ok=True)

    items = [json.loads(l) for l in items_path.read_text().splitlines() if l.strip()]
    if args.only:
        want = {s.strip() for s in args.only.split(",") if s.strip()}
        items = [i for i in items if i["item_id"] in want]
    if args.limit:
        items = items[:args.limit]

    ras_exe, ras_label = find_rasteriser()
    log(f"run={label} model={args.model} endpoint={args.base_url}")
    log(f"items={len(items)} attempts={args.attempts} rasteriser={ras_label}")

    results_path = run_dir / "results.jsonl"
    done: set[str] = set()
    if args.resume and results_path.exists():
        for line in results_path.read_text().splitlines():
            if line.strip():
                done.add(json.loads(line)["item_id"])
        log(f"resume: {len(done)} items already on disk")

    (run_dir / "run_meta.json").write_text(json.dumps({
        "run_label": label, "model": args.model, "base_url": args.base_url,
        "temperature": args.temperature, "max_tokens": args.max_tokens,
        "attempts": args.attempts, "rasteriser": ras_label,
        "items": len(items), "pipeline": "scene JSON -> deterministic typesetter",
        "started_at": time.strftime("%Y-%m-%dT%H:%M:%S"),
        "gates": "validity only; whether the essence was caught is the owner's call",
    }, indent=2))

    n_valid = 0
    with results_path.open("a") as fh:
        for idx, item in enumerate(items, 1):
            iid = item["item_id"]
            if iid in done:
                log(f"({idx}/{len(items)}) {iid} already done, skipping")
                continue
            log(f"({idx}/{len(items)}) {iid} [{item['band']}] asking...")
            t0 = time.time()
            prompt = item["prompt"]
            raw, meta, err, verdict = "", {}, None, None
            tries = 0
            for attempt in range(1, args.attempts + 1):
                tries = attempt
                try:
                    raw, meta = call_model(
                        args.base_url, args.model, prompt,
                        timeout=args.timeout, max_tokens=args.max_tokens,
                        temperature=args.temperature,
                        want_json=not args.no_json_mode)
                except Exception as exc:
                    raw, meta = "", {}
                    err = f"{type(exc).__name__}: {str(exc)[:300]}"
                    break
                (run_dir / "raw" / f"{iid}.attempt{attempt}.txt").write_text(raw)
                verdict = gate(raw, rasteriser=ras_exe)
                if verdict["valid"]:
                    break
                # Retry on any failure, not only a schema violation. The smoke
                # lost an item to a reply that stopped mid-object, which is the
                # most obviously retryable failure there is and the first draft
                # walked straight past it.
                why = verdict.get("schema_error") or next(
                    (c["detail"] for c in verdict["checks"].values()
                     if c["status"] == "fail"), "unknown")
                if attempt < args.attempts:
                    log(f"    invalid, retrying once: {why[:120]}")
                    prompt = (RETRY_PREFIX.format(err=why) + item["prompt"])
            elapsed = time.time() - t0

            if verdict is None:
                verdict = {"valid": False, "checks": {"json_parses": {
                    "status": "fail", "detail": err or "empty reply"}},
                    "scene": None, "svg": None, "needed_stripping": False,
                    "byte_len": 0, "schema_error": None}
            (run_dir / "raw" / f"{iid}.txt").write_text(raw or "")

            svg_rel = scene_rel = None
            if verdict.get("svg"):
                (run_dir / "svg" / f"{iid}.svg").write_text(verdict["svg"])
                svg_rel = f"svg/{iid}.svg"
            if verdict.get("scene") is not None:
                (run_dir / "scene" / f"{iid}.json").write_text(
                    json.dumps(verdict["scene"], indent=1))
                scene_rel = f"scene/{iid}.json"

            rec = {
                "item_id": iid, "band": item["band"], "asset_id": item["asset_id"],
                "seconds": round(elapsed, 1), "attempts": tries, "error": err,
                "valid": verdict["valid"], "byte_len": verdict["byte_len"],
                "needed_stripping": verdict["needed_stripping"],
                "schema_error": verdict.get("schema_error"),
                "checks": verdict["checks"], "model_meta": meta,
                "svg_path": svg_rel, "scene_path": scene_rel,
                "raw_path": f"raw/{iid}.txt",
            }
            fh.write(json.dumps(rec) + "\n")
            fh.flush()
            os.fsync(fh.fileno())

            n_valid += int(verdict["valid"])
            failed = [k for k, c in verdict["checks"].items()
                      if c["status"] == "fail"]
            log(f"    {iid}: valid={verdict['valid']} {elapsed:.1f}s "
                f"tries={tries}" + (f" failed={failed}" if failed else ""))

    ran = len(items) - len(done & {i["item_id"] for i in items})
    log(f"done. valid {n_valid}/{ran} run this pass. results -> {results_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
