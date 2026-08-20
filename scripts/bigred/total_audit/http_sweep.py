#!/usr/bin/env python3
"""http_sweep.py — request every page, every generated file, and every API
route from a locally booted Hermes server, and record what came back.

All 32 nav destinations return 200 at HEAD, so status codes alone prove
little; this sweep exists to (a) extend "every file" to the generated web
trees by serving each file once, (b) exercise every registered API route and
record its refusal semantics, (c) enumerate the lesson-keyed routes across
the full lesson-code pool, and (d) capture, via the audit-boot hook, which
repo files the server actually opens at request time versus at startup.

Usage (from the repo root, after sweep_driver.py wrote domains.json):
  python3 scripts/bigred/total_audit/http_sweep.py --out OUTDIR \
      [--port 8801] [--domains OUTDIR/domains.json] [--max-keyed 2000]
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path

import requests

REPO = Path(__file__).resolve().parents[3]
AUDIT_BOOT = REPO / "scripts" / "bigred" / "total_audit" / "audit_boot.py"

# Minimal honest payloads for POST routes: enough to distinguish "refuses
# with its contract" from "crashes". Routes keyed by lesson code additionally
# enumerate the full harvested pool.
POST_FIXTURES: dict[str, dict] = {
    "/api/field_context": {"code": "IM-G1-U3-L17"},
    "/api/pedagogical_questions": {"query": "fractions", "kind": "topic"},
    "/api/discourse_features": {"utterances": ["I think ten plus three is thirteen"]},
    "/api/discourse_pragmatics": {"utterances": ["I think ten plus three is thirteen"]},
}
LESSON_KEYED_POSTS = {"/api/field_context": "code"}


def wait_health(base: str, tries: int = 120) -> None:
    for _ in range(tries):
        try:
            if requests.get(base + "/", timeout=5).status_code == 200:
                return
        except requests.RequestException:
            pass
        time.sleep(1)
    raise RuntimeError("server did not answer within the boot window")


def enumerate_static() -> list[str]:
    urls: list[str] = []
    app_web = REPO / "hermes" / "app" / "web"
    for p in sorted(app_web.rglob("*")):
        if p.is_file():
            urls.append("/" + str(p.relative_to(app_web)))
    web = REPO / "hermes" / "web"
    for p in sorted(web.rglob("*")):
        if p.is_file():
            urls.append("/more-zeeman/" + str(p.relative_to(web)))
    reorg = REPO / "formal" / "learner" / "reorg_demo.html"
    if reorg.exists():
        urls.append("/learner/reorg_demo.html")
    return urls


def enumerate_routes():
    sys.path.insert(0, str(REPO))
    from hermes.app.routes.registry import build_router
    return [(r.method, r.path) for r in build_router().routes]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--port", type=int, default=8801)
    ap.add_argument("--domains", default=None)
    ap.add_argument("--max-keyed", type=int, default=2000)
    args = ap.parse_args()

    outdir = Path(args.out)
    outdir.mkdir(parents=True, exist_ok=True)
    opens_path = outdir / "server_opens.jsonl"
    results_path = outdir / "http_results.jsonl"
    base = f"http://127.0.0.1:{args.port}"

    codes: list[str] = []
    if args.domains and Path(args.domains).exists():
        codes = json.loads(Path(args.domains).read_text()).get("code", [])

    env = dict(os.environ, HERMES_AUDIT_OPENS=str(opens_path),
               PYTHONPATH=str(REPO))
    server_log = (outdir / "server.log").open("w")
    server = subprocess.Popen(
        [sys.executable, "-u", str(AUDIT_BOOT),
         "--host", "127.0.0.1", "--port", str(args.port)],
        cwd=REPO, env=env, stdout=server_log, stderr=server_log)
    print(f"[http] server pid {server.pid} on :{args.port}", flush=True)

    done: set[str] = set()
    if results_path.exists():
        for line in results_path.open():
            try:
                done.add(json.loads(line)["key"])
            except (json.JSONDecodeError, KeyError):
                continue
        print(f"[http] resume: {len(done)} recorded", flush=True)
    results = results_path.open("a")

    def record(key: str, method: str, url: str, payload=None):
        if key in done:
            return
        t0 = time.monotonic()
        try:
            if method == "GET":
                r = requests.get(base + url, timeout=120)
            else:
                r = requests.post(base + url, json=payload or {}, timeout=300)
            rec = {"key": key, "method": method, "url": url,
                   "status": r.status_code, "bytes": len(r.content),
                   "content_type": r.headers.get("content-type", ""),
                   "ms": round((time.monotonic() - t0) * 1000, 1)}
            if r.status_code >= 500:
                rec["body_head"] = r.text[:400]
        except requests.RequestException as e:
            rec = {"key": key, "method": method, "url": url,
                   "status": -1, "error": type(e).__name__,
                   "ms": round((time.monotonic() - t0) * 1000, 1)}
        results.write(json.dumps(rec, ensure_ascii=False) + "\n")
        results.flush()

    try:
        boot_t0 = time.time()
        wait_health(base)
        (outdir / "sweep_marker.json").write_text(json.dumps(
            {"boot_started": boot_t0, "sweep_started": time.time()}))

        static_urls = enumerate_static()
        print(f"[http] {len(static_urls)} static files", flush=True)
        for i, url in enumerate(static_urls):
            record(f"GET {url}", "GET", url)
            if (i + 1) % 500 == 0:
                print(f"[http] static {i + 1}/{len(static_urls)}", flush=True)

        routes = enumerate_routes()
        print(f"[http] {len(routes)} registered routes", flush=True)
        for method, path in routes:
            payload = POST_FIXTURES.get(path)
            record(f"{method} {path}", method, path, payload)

        for path, key_name in LESSON_KEYED_POSTS.items():
            pool = codes[: args.max_keyed]
            if len(codes) > args.max_keyed:
                print(f"[http] TRUNCATED {path}: {len(codes)} -> "
                      f"{args.max_keyed}", flush=True)
            print(f"[http] keyed sweep {path} over {len(pool)} codes",
                  flush=True)
            for i, code in enumerate(pool):
                record(f"POST {path} {code}", "POST", path, {key_name: code})
                if (i + 1) % 200 == 0:
                    print(f"[http] {path} {i + 1}/{len(pool)}", flush=True)
    finally:
        server.terminate()
        try:
            server.wait(timeout=15)
        except subprocess.TimeoutExpired:
            server.kill()
        server_log.close()
        results.close()

    lines = sum(1 for _ in results_path.open())
    print(f"[http] done: {lines} records; opens -> {opens_path}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
