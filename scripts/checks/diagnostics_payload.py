#!/usr/bin/env python3
"""Keep public worker diagnostics limited to counts, without opening a socket."""
from __future__ import annotations

import sys
from collections import deque
from pathlib import Path
from types import SimpleNamespace


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from hermes.app import server, worker  # noqa: E402


EXPECTED_KEYS = {"running", "stderr_lines"}


def assert_diagnostics_payload(payload: object, layer: str) -> None:
    assert isinstance(payload, dict), f"{layer} diagnostics must be a dict: {payload!r}"
    assert set(payload) == EXPECTED_KEYS, (
        f"{layer} diagnostics keys must be exactly {EXPECTED_KEYS}: {payload!r}"
    )
    assert type(payload["running"]) is bool, (
        f"{layer} diagnostics running must be bool: {payload!r}"
    )
    assert type(payload["stderr_lines"]) is int, (
        f"{layer} diagnostics stderr_lines must be int: {payload!r}"
    )


def worker_payload() -> None:
    instance = worker.PersistentPrologWorker(umedcta_root=ROOT)
    instance._proc = SimpleNamespace(poll=lambda: None)
    instance._stderr_tail = deque(["first", "second"], maxlen=400)
    payload = instance.diagnostics()
    assert_diagnostics_payload(payload, "worker")
    assert payload == {"running": True, "stderr_lines": 2}, payload
    print("PASS worker diagnostics exposes only running and stderr_lines")


def service_payload() -> None:
    service = server.WorkerService()
    assert_diagnostics_payload(service.diagnostics(), "service without worker")
    service._worker = SimpleNamespace(
        diagnostics=lambda: {"running": True, "stderr_lines": 7}
    )
    payload = service.diagnostics()
    assert_diagnostics_payload(payload, "service")
    assert payload == {"running": True, "stderr_lines": 7}, payload
    print("PASS service diagnostics preserves the exact counts-only contract")


def synthetic_reversion_bites() -> None:
    leaky_worker = SimpleNamespace(
        diagnostics=lambda: {"running": True, "stderr_lines": 1, "stderr_tail": ["secret"]}
    )
    try:
        assert_diagnostics_payload(leaky_worker.diagnostics(), "synthetic reversion")
    except AssertionError as exc:
        assert "keys must be exactly" in str(exc), exc
    else:
        raise AssertionError("synthetic stderr_tail reversion unexpectedly passed")
    print("PASS synthetic stderr_tail reversion fails the diagnostics contract")


def main() -> int:
    worker_payload()
    service_payload()
    synthetic_reversion_bites()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
