#!/usr/bin/env python3
"""Fail before the batch, not eighty minutes into it.

Three Big Red launches have died on an import the submitting shell never tried,
so every import the driver performs is performed here, in the same interpreter
the job will use. Round 2 adds the parts that make the split work: the schema,
the typesetter, and a real scene typeset end to end -- because a typesetter that
imports and then raises on the first figure has told us nothing.

The rasteriser is checked but never required. On a compute node without PyMuPDF
the render gate reports `renderer_unavailable` and the item still counts valid;
the SVG is produced either way, since typesetting is standard library, and the
laptop re-gates on collection with `regate_scenes.py`.

    python3 preflight_v2.py --items items/items.jsonl [--model-path ...] \
        [--base-url http://127.0.0.1:PORT/v1 --model NAME]
"""
from __future__ import annotations

import argparse
import importlib
import json
import os
import sys
from pathlib import Path

FAILURES: list[str] = []


def check(label: str, ok: bool, detail: str = "") -> bool:
    print(f"  [{'ok' if ok else 'FAIL'}] {label}" + (f"  -- {detail}" if detail else ""),
          flush=True)
    if not ok:
        FAILURES.append(label)
    return ok


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--items", default="items/items.jsonl")
    ap.add_argument("--model-path", default="")
    ap.add_argument("--base-url", default="")
    ap.add_argument("--model", default="")
    args = ap.parse_args()

    here = Path(__file__).resolve().parent
    sys.path.insert(0, str(here))
    sys.path.insert(0, str(here.parent / "t228"))

    print(f"python {sys.version.split()[0]} at {sys.executable}", flush=True)

    print("\n-- standard library the driver reaches for --", flush=True)
    for mod in ("json", "argparse", "urllib.request", "urllib.error", "re",
                "textwrap", "tempfile", "base64", "html.parser"):
        try:
            importlib.import_module(mod)
            check(f"import {mod}", True)
        except Exception as exc:
            check(f"import {mod}", False, f"{type(exc).__name__}: {exc}")

    print("\n-- this pilot's own modules --", flush=True)
    for mod in ("scene_schema", "typeset", "prompt_v3", "gate_scene",
                "run_scene_pilot"):
        try:
            importlib.import_module(mod)
            check(f"import {mod}", True)
        except Exception as exc:
            check(f"import {mod}", False, f"{type(exc).__name__}: {exc}")

    print("\n-- the typesetter actually runs --", flush=True)
    try:
        from prompt_v3 import EXAMPLE
        from scene_schema import validate
        from typeset import typeset
        validate(EXAMPLE)
        svg = typeset(EXAMPLE)
        check("typeset the prompt's own worked example",
              svg.startswith("<svg") and svg.rstrip().endswith("</svg>")
              and len(svg) > 800, f"{len(svg)} bytes of SVG")
    except Exception as exc:
        check("typeset the prompt's own worked example", False,
              f"{type(exc).__name__}: {exc}")

    print("\n-- the gate runs end to end --", flush=True)
    try:
        from gate_scene import gate
        from prompt_v3 import EXAMPLE
        v = gate(json.dumps(EXAMPLE))
        rend = v["checks"].get("renders_non_empty", {}).get("status", "absent")
        check("gate a known-good scene", v["valid"],
              f"render gate: {rend}")
        bad = gate('{"title":"x","panels":[{"role":"student","blocks":'
                   '[{"type":"note","text":"x","x":4}]}]}')
        check("gate refuses a scene carrying a coordinate",
              not bad["valid"] and bad.get("schema_error"),
              (bad.get("schema_error") or "")[:80])
    except Exception as exc:
        check("gate a known-good scene", False, f"{type(exc).__name__}: {exc}")

    print("\n-- rasteriser (optional; absence is not a failure) --", flush=True)
    try:
        from gate_svg import find_rasteriser
        _, label = find_rasteriser()
        print(f"  [info] rasteriser: {label}"
              + ("  -- render gate will report renderer_unavailable and items "
                 "still count valid" if label in (None, "none") else ""),
              flush=True)
    except Exception as exc:
        print(f"  [info] no rasteriser module: {type(exc).__name__}: {exc}",
              flush=True)

    print("\n-- items --", flush=True)
    items_path = Path(args.items)
    if not items_path.is_absolute():
        items_path = here / args.items
    if check(f"items file exists: {items_path}", items_path.exists()):
        rows = [json.loads(l) for l in items_path.read_text().splitlines()
                if l.strip()]
        check("items parse", True, f"{len(rows)} records")
        check("every item carries a prompt",
              all(r.get("prompt") for r in rows),
              f"{min(len(r['prompt']) for r in rows)}-"
              f"{max(len(r['prompt']) for r in rows)} chars")
        check("every item id is unique",
              len({r["item_id"] for r in rows}) == len(rows))

    if args.model_path:
        p = Path(args.model_path)
        check(f"model file present: {p.name}", p.exists(),
              f"{p.stat().st_size / 2**30:.1f} GiB" if p.exists() else "missing")

    if args.base_url and args.model:
        print("\n-- endpoint --", flush=True)
        try:
            import urllib.request
            body = json.dumps({
                "model": args.model,
                "messages": [{"role": "user", "content":
                              'Reply with exactly {"ok":true}'}],
                "max_tokens": 24, "temperature": 0.0,
            }).encode()
            req = urllib.request.Request(
                args.base_url.rstrip("/") + "/chat/completions", data=body,
                headers={"Content-Type": "application/json"})
            with urllib.request.urlopen(req, timeout=180) as resp:
                out = json.loads(resp.read())
            txt = ((out.get("choices") or [{}])[0].get("message") or {}
                   ).get("content", "")
            check("chat route answers", bool(txt.strip()), repr(txt[:60]))
        except Exception as exc:
            check("chat route answers", False, f"{type(exc).__name__}: {exc}")

    print("")
    if FAILURES:
        print(f"PREFLIGHT FAILED: {len(FAILURES)} check(s): "
              + "; ".join(FAILURES), flush=True)
        return 1
    print("PREFLIGHT PASSED", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
