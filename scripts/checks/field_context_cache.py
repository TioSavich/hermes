#!/usr/bin/env python3
"""Check field-context cache serving and one live value for drift.

One fixed lesson keeps this regular-suite gate near one live field-context
search instead of adding roughly 35 seconds for three equivalent comparisons.
Object key order is immaterial to Python dictionary equality; list values keep
their API ordering and must match exactly.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path
from types import SimpleNamespace
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from hermes.app.routes import monitoring
from hermes.app.worker import PersistentPrologWorker


CACHE_PATH = ROOT / "curriculum/im/generated/field_context_cache.json"
SAMPLE_LESSON = "IM-GK-U1-L1"


class RouteProbe:
    def __init__(self, cache: dict[str, dict[str, Any]]) -> None:
        self.payload = {"lesson_code": SAMPLE_LESSON}
        self.services = SimpleNamespace(field_context_cache=cache)
        self.worker_calls = 0
        self.response: dict[str, Any] | None = None

    def worker_request(self, _op: str, **_payload: Any) -> dict[str, Any]:
        self.worker_calls += 1
        return {"lesson_code": SAMPLE_LESSON}

    def _send_json(self, payload: dict[str, Any], *, status: int = 200) -> None:
        self.response = {"status": status, "payload": payload}


def without_served_from(value: dict[str, Any]) -> dict[str, Any]:
    return {key: item for key, item in value.items() if key != "served_from"}


def main() -> int:
    artifact = json.loads(CACHE_PATH.read_text(encoding="utf-8"))
    if artifact.get("schema") != "hermes_field_context_cache_v1":
        raise SystemExit("field-context cache has the wrong or missing schema")
    contexts = artifact.get("field_contexts")
    if not isinstance(contexts, dict) or len(contexts) != 1317:
        raise SystemExit(
            f"field-context cache expected 1317 entries, found "
            f"{len(contexts) if isinstance(contexts, dict) else 'non-object'}"
        )
    cached = contexts.get(SAMPLE_LESSON)
    if not isinstance(cached, dict) or "error" in cached:
        raise SystemExit(f"field-context cache lacks a usable {SAMPLE_LESSON} entry")

    hit = RouteProbe({SAMPLE_LESSON: cached})
    monitoring.field_context(hit)
    assert hit.worker_calls == 0
    assert hit.response is not None
    assert hit.response["payload"]["result"]["served_from"] == "cache"

    miss = RouteProbe({})
    monitoring.field_context(miss)
    assert miss.worker_calls == 1
    assert miss.response is not None
    assert miss.response["payload"]["result"]["served_from"] == "live"

    worker = PersistentPrologWorker(timeout=120)
    try:
        live = worker.request("field_context", lesson_code=SAMPLE_LESSON)
    finally:
        worker.close()
    if without_served_from(live) != without_served_from(cached):
        raise SystemExit(f"field-context cache drift for {SAMPLE_LESSON}")
    print(
        f"PASS field-context cache: {len(contexts)} entries, route hit/miss provenance, "
        f"live equality for {SAMPLE_LESSON}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
