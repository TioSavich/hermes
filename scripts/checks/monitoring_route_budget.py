#!/usr/bin/env python3
"""Assert that a timed chart export has a bounded, non-500 route reply."""
from __future__ import annotations

import sys
from pathlib import Path
from types import SimpleNamespace


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from hermes.app.routes import monitoring
from hermes.app.worker import PersistentPrologError, REQUEST_TIMEOUT_MESSAGE


class TimedOutExportWorker:
    timeout = 90.0

    def request(self, _op: str, **_payload: object) -> object:
        raise PersistentPrologError(REQUEST_TIMEOUT_MESSAGE)


class RouteProbe:
    payload = {"lesson_code": "IM-G5-U6-L8"}
    services = SimpleNamespace(monitoring_export_worker=TimedOutExportWorker())

    def __init__(self) -> None:
        self.response: dict[str, object] | None = None

    def _send_json(self, payload: dict[str, object], *, status: int = 200) -> None:
        self.response = {"status": status, "payload": payload}


def main() -> int:
    for handler, label in (
        (monitoring.monitoring_chart_export, "Monitoring chart export"),
        (monitoring.field_context, "Field context"),
        (monitoring.monitoring_visuals, "Monitoring visuals"),
    ):
        probe = RouteProbe()
        probe.services.field_context_cache = {"IM-G5-U6-L8": {"error": "stale"}}
        handler(probe)
        assert probe.response is not None
        assert probe.response["status"] == 503
        payload = probe.response["payload"]
        assert isinstance(payload, dict)
        assert payload["ok"] is False
        assert payload["lesson_code"] == "IM-G5-U6-L8"
        assert payload["budget_seconds"] == 90.0
        assert f"{label} for IM-G5-U6-L8 exceeded the 90-second budget" in str(payload["error"])
    print("PASS bounded monitoring routes: export, field context, and visuals return 503 without shared-worker calls")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
