#!/usr/bin/env python3
"""sweep_driver.py — drive every worker op across enumerable input domains,
under clause coverage.

The driver spawns the Hermes JSONL worker wrapped in cov_worker.pl, asks it
for its own op list (the health reply carries one), harvests input domains
from the worker's list-shaped replies plus the typed parameter declarations
in hermes/dispatch_spec.pl, then executes the resulting work list with an
external per-item watchdog. Coverage data lands in per-segment files that
coverage_ledger.py joins against the static census.

Honesty rules built in:
  - every op gets at least a shape probe; a refusal is a recorded outcome,
    never an error to hide;
  - per-op enumeration caps are LOGGED as truncations, never silent;
  - a watchdog kill requeues the killed segment's completed items once, so
    their coverage is re-collected in a fresh segment.

Usage (from the repo root):
  python3 scripts/bigred/total_audit/sweep_driver.py --out OUTDIR \
      [--max-per-op 2000] [--item-timeout 180] [--segment-items 4000]
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import selectors
import signal
import subprocess
import sys
import time
from collections import Counter, defaultdict, deque
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
COV_WORKER = "scripts/bigred/total_audit/cov_worker.pl"
DISPATCH_SPEC = REPO / "hermes" / "dispatch_spec.pl"

HARVEST_OPS = [
    "list_strategies", "list_misconceptions", "list_standards",
    "capability_atlas", "render_coverage", "lesson_enactment_list",
]
# File-side domain supplements: op replies alone under-harvest the lesson
# codes (the compiled corpus is larger than any one list op's reach).
SUPPLEMENT_FILES = [
    "curriculum/im/generated/field_context_cache.json",
    "hermes/app/web/generated/notation_lesson_charts/manifest.json",
    "hermes/app/web/generated/lesson_deformation_charts/manifest.json",
]
# Param names whose values are enumerable pools; harvested from replies.
POOL_KEYS = {
    "code", "cluster", "kind", "operation", "family", "standard",
    "misconception", "strategy", "state", "context", "pack", "topic",
    "lesson", "domain",
}
IM_CODE = re.compile(r"^IM-G[K0-9]")
TIMEOUT_OVERRIDES = {"lesson_enactment_run": 360, "monitoring_chart_export": 360,
                     "lesson_enactment_list": 360, "field_connectivity_audit": 600}
TYPE_FIXTURES = {"atom": "probe", "string": "probe", "code": "IM-G1-U3-L17",
                 "term": "probe", "number": 1, "int": 1, "dict": {},
                 "json": {}, "json_list": [], "list": [],
                 "nonempty_text": "ten plus three is thirteen",
                 "math_claim": "3 + 4 = 7", "fraction": "1/2",
                 "optional_code": "IM-G1-U3-L17", "op_atom": "probe",
                 "filter": {}}
# Param types with structured shapes the driver cannot fabricate honestly
# (recollection, practice, fallback, ...) stay unresolved: those ops get a
# shape probe, and their refusal message records the contract.


def parse_dispatch_specs() -> dict[str, list[tuple[str, str, bool]]]:
    """Return op -> [(param, type, optional)], read from dispatch_spec.pl."""
    text = DISPATCH_SPEC.read_text(encoding="utf-8")
    specs: dict[str, list[tuple[str, str, bool]]] = {}
    for m in re.finditer(r"^dispatch_spec\((\w+),\s*\n?\s*\[(.*?)\]", text,
                         re.MULTILINE | re.DOTALL):
        op, params_raw = m.group(1), m.group(2)
        params: list[tuple[str, str, bool]] = []
        depth = 0
        item = ""
        items = []
        for ch in params_raw:
            if ch == "," and depth == 0:
                items.append(item)
                item = ""
                continue
            if ch in "([{":
                depth += 1
            elif ch in ")]}":
                depth -= 1
            item += ch
        if item.strip():
            items.append(item)
        for it in items:
            it = it.strip().replace("\n", " ")
            pm = re.match(r"(\w+)\s*-\s*(.+)$", it)
            if not pm:
                continue
            name, typ = pm.group(1), pm.group(2).strip()
            optional = typ.startswith("default(")
            base = typ.split("(")[0] if "(" in typ else typ
            if optional:
                inner = typ[len("default("):]
                base = inner.split(",")[0].split("(")[0].strip()
            params.append((name, base, optional))
        specs[op] = params
    return specs


def walk_json(node, pools: dict[str, set]):
    if isinstance(node, dict):
        for k, v in node.items():
            if k in POOL_KEYS and isinstance(v, str) and v:
                pools[k].add(v)
            walk_json(v, pools)
    elif isinstance(node, list):
        for v in node:
            walk_json(v, pools)
    elif isinstance(node, str) and IM_CODE.match(node):
        pools["code"].add(node)


class CovWorker:
    """One coverage-instrumented worker instance (one segment)."""

    def __init__(self, outdir: Path, segno: int, swipl: str):
        self.segfile = outdir / f"cov_seg_{segno:03d}.dat"
        self.errfile = outdir / f"cov_seg_{segno:03d}.stderr"
        env = dict(os.environ, HERMES_COV_SEGMENT=str(self.segfile))
        self.err_fh = open(self.errfile, "w")
        self.proc = subprocess.Popen(
            [swipl, "-q", "-l", "hermes_worker.pl", "-l", COV_WORKER,
             "-g", "cov_main"],
            cwd=REPO, env=env, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=self.err_fh, text=True, bufsize=1)
        self.items: list[str] = []  # ids completed in this segment

    def request(self, payload: dict, timeout: float):
        line = json.dumps(payload, ensure_ascii=False)
        self.proc.stdin.write(line + "\n")
        self.proc.stdin.flush()
        sel = selectors.DefaultSelector()
        sel.register(self.proc.stdout, selectors.EVENT_READ)
        deadline = time.monotonic() + timeout
        buf = ""
        while time.monotonic() < deadline:
            if sel.select(timeout=min(1.0, deadline - time.monotonic())):
                chunk = self.proc.stdout.readline()
                if chunk == "":
                    raise BrokenPipeError("worker stdout closed")
                buf = chunk
                break
        sel.close()
        if not buf:
            raise TimeoutError()
        return json.loads(buf)

    def stop(self, grace: float = 60.0) -> bool:
        """Close stdin and let the worker save through the clean EOF path
        (the save can take a while on a full runtime). Escalate to TERM,
        then KILL, only if it does not exit on its own. Returns True if the
        segment file exists afterward (coverage preserved)."""
        if self.proc.poll() is None:
            try:
                self.proc.stdin.close()
            except OSError:
                pass
            try:
                self.proc.wait(timeout=grace)
            except subprocess.TimeoutExpired:
                self.proc.send_signal(signal.SIGTERM)
                try:
                    self.proc.wait(timeout=15)
                except subprocess.TimeoutExpired:
                    self.proc.kill()
                    self.proc.wait()
        self.err_fh.close()
        return self.segfile.exists() and self.segfile.stat().st_size > 0


def build_worklist(specs, pools, ops, max_per_op, log):
    items = []
    truncations = []
    for op in sorted(ops):
        items.append({"op": op, "args": {}, "class": "shape_probe"})
        params = specs.get(op)
        if not params:
            continue
        pooled = [(n, t) for n, t, opt in params
                  if not opt and n in pools and pools[n]]
        required = [(n, t, o) for n, t, o in params if not o]
        args_base = {}
        resolvable = True
        for name, typ, opt in params:
            if opt:
                continue
            if name in pools and pools[name]:
                continue
            if typ in TYPE_FIXTURES:
                args_base[name] = TYPE_FIXTURES[typ]
            else:
                resolvable = False
        if not resolvable or not pooled:
            continue
        # Enumerate the FIRST pooled param fully; fix the rest to one sample.
        key_name = pooled[0][0]
        for name, _t in pooled[1:]:
            args_base[name] = sorted(pools[name])[0]
        domain = sorted(pools[key_name])
        if len(domain) > max_per_op:
            truncations.append({"op": op, "param": key_name,
                                "domain": len(domain), "kept": max_per_op})
            domain = domain[:max_per_op]
        for value in domain:
            args = dict(args_base)
            args[key_name] = value
            items.append({"op": op, "args": args, "class": "keyed"})
    for t in truncations:
        log(f"TRUNCATED {t['op']}.{t['param']}: {t['domain']} -> {t['kept']}")
    for it in items:
        digest = hashlib.sha1(
            json.dumps([it["op"], it["args"]], sort_keys=True).encode()
        ).hexdigest()[:12]
        it["id"] = f"{it['op']}:{digest}"
    return items, truncations


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--max-per-op", type=int, default=2000)
    ap.add_argument("--item-timeout", type=float, default=180.0)
    ap.add_argument("--segment-items", type=int, default=4000)
    ap.add_argument("--ops-filter", default=None,
                    help="regex; only ops matching it enter the work list "
                         "(smoke runs, targeted reruns)")
    args = ap.parse_args()

    outdir = Path(args.out)
    outdir.mkdir(parents=True, exist_ok=True)
    swipl = os.environ.get("HERMES_SWIPL", "swipl")

    def log(msg):
        print(f"[sweep] {msg}", flush=True)

    results_path = outdir / "sweep_results.jsonl"
    done: set[str] = set()
    if results_path.exists():
        for line in results_path.open():
            try:
                done.add(json.loads(line)["id"])
            except (json.JSONDecodeError, KeyError):
                continue
        log(f"resume: {len(done)} items already recorded")
    results = results_path.open("a")

    segno = 0
    worker = CovWorker(outdir, segno, swipl)
    log("worker segment 0 spawned; waiting for health")
    health = worker.request({"id": "boot", "op": "health"}, timeout=600)
    ops = health.get("result", {}).get("ops", [])
    log(f"worker reports {len(ops)} ops")

    pools: dict[str, set] = defaultdict(set)
    for hop in HARVEST_OPS:
        if hop not in ops:
            continue
        try:
            reply = worker.request({"id": f"harvest:{hop}", "op": hop},
                                   timeout=max(360, args.item_timeout))
            walk_json(reply, pools)
            log(f"harvest {hop}: pools now " +
                ", ".join(f"{k}={len(v)}" for k, v in sorted(pools.items())))
        except (TimeoutError, BrokenPipeError, json.JSONDecodeError) as e:
            log(f"harvest {hop} failed: {type(e).__name__}")
    for rel in SUPPLEMENT_FILES:
        p = REPO / rel
        if not p.exists():
            log(f"supplement absent: {rel}")
            continue
        try:
            doc = json.loads(p.read_text())
        except (json.JSONDecodeError, OSError) as e:
            log(f"supplement unreadable: {rel} ({type(e).__name__})")
            continue
        if isinstance(doc, dict):
            for key in doc.keys():
                if isinstance(key, str) and IM_CODE.match(key):
                    pools["code"].add(key)
        walk_json(doc, pools)
        log(f"supplement {rel}: code pool now {len(pools['code'])}")
    (outdir / "domains.json").write_text(json.dumps(
        {k: sorted(v) for k, v in pools.items()}, indent=1))

    specs = parse_dispatch_specs()
    log(f"dispatch_spec declares {len(specs)} typed ops")
    worklist_path = outdir / "worklist.jsonl"
    if worklist_path.exists():
        items = [json.loads(l) for l in worklist_path.open()]
        log(f"worklist reused: {len(items)} items")
    else:
        items, truncations = build_worklist(specs, pools, ops,
                                            args.max_per_op, log)
        with worklist_path.open("w") as f:
            for it in items:
                f.write(json.dumps(it, ensure_ascii=False) + "\n")
        (outdir / "truncations.json").write_text(json.dumps(truncations, indent=1))
        log(f"worklist built: {len(items)} items")

    outcomes = Counter()
    requeue: list[dict] = []
    seg_count = 0

    def record(item, outcome, ms, note=""):
        outcomes[outcome] += 1
        results.write(json.dumps({
            "id": item["id"], "op": item["op"], "class": item["class"],
            "outcome": outcome, "ms": round(ms, 1), "note": note[:400],
        }, ensure_ascii=False) + "\n")
        results.flush()

    def rotate(reason):
        nonlocal worker, segno, seg_count
        saved = worker.stop()
        if not saved and worker.items:
            requeue.extend(i for i in pending_lookup(worker.items))
            log(f"segment {segno} lost ({reason}); requeued "
                f"{len(worker.items)} completed items")
        segno += 1
        seg_count = 0
        worker = CovWorker(outdir, segno, swipl)
        worker.request({"id": f"boot{segno}", "op": "health"}, timeout=600)
        log(f"worker segment {segno} spawned ({reason})")

    if args.ops_filter:
        rx = re.compile(args.ops_filter)
        before = len(items)
        items = [it for it in items if rx.search(it["op"])]
        log(f"ops-filter {args.ops_filter!r}: {before} -> {len(items)} items")

    by_id = {it["id"]: it for it in items}

    def pending_lookup(ids):
        return [by_id[i] for i in ids if i in by_id]

    queue = deque(it for it in items if it["id"] not in done)
    total = len(queue)
    log(f"executing {total} items")
    n = 0
    requeued_once: set[str] = set()
    while queue:
        item = queue.popleft()
        n += 1
        timeout = TIMEOUT_OVERRIDES.get(item["op"], args.item_timeout)
        t0 = time.monotonic()
        try:
            reply = worker.request(
                {"id": item["id"], "op": item["op"], **item["args"]}, timeout)
            ms = (time.monotonic() - t0) * 1000
            ok = reply.get("ok")
            if ok is True:
                record(item, "ok", ms)
            else:
                record(item, "refused", ms,
                       note=str(reply.get("error", reply.get("message", ""))))
            worker.items.append(item["id"])
            seg_count += 1
        except TimeoutError:
            ms = (time.monotonic() - t0) * 1000
            record(item, "timeout", ms)
            rotate(f"timeout on {item['op']}")
        except (BrokenPipeError, json.JSONDecodeError, OSError) as e:
            ms = (time.monotonic() - t0) * 1000
            record(item, "worker_died", ms, note=type(e).__name__)
            rotate(f"death on {item['op']}")
        if seg_count >= args.segment_items:
            rotate("segment rotation")
        if n % 500 == 0:
            log(f"{n}/{total} done; outcomes: {dict(outcomes)}")
        if not queue and requeue:
            fresh = [i for i in requeue if i["id"] not in requeued_once]
            for i in fresh:
                requeued_once.add(i["id"])
            queue = deque(fresh)
            requeue = []
            if queue:
                log(f"requeue pass: {len(queue)} items")

    worker.stop()
    results.close()
    (outdir / "sweep_summary.json").write_text(json.dumps({
        "items": total, "outcomes": dict(outcomes), "segments": segno + 1,
        "ops": len(ops), "pools": {k: len(v) for k, v in pools.items()},
    }, indent=1))
    log(f"done; outcomes: {dict(outcomes)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
