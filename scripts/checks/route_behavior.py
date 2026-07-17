#!/usr/bin/env python3
"""CONTROLLER-RUN: compare representative HTTP status and JSON fixtures.

This check starts Hermes on a reserved loopback port. It is intentionally not
SANDBOX-SAFE because the implementation sandbox forbids socket binding.
"""
from __future__ import annotations

import json
import os
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def free_port() -> int:
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


def request(base: str, method: str, path: str, payload: object | None = None,
            timeout: float = 10, raw: bool = False) -> tuple[int, object]:
    data = None if payload is None else json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        base + path, data=data, method=method,
        headers={"Content-Type": "application/json"} if data is not None else {},
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            body = response.read()
            return response.status, (body if raw else json.loads(body))
    except urllib.error.HTTPError as exc:
        body = exc.read()
        return exc.code, (body if raw else json.loads(body))


def main() -> int:
    port = free_port()
    base = f"http://127.0.0.1:{port}"
    env = os.environ.copy()
    env.update({"HERMES_GATE": "1", "HERMES_GATE_OVERRIDE": "0", "REALLMS_API_KEY": ""})
    process = subprocess.Popen(
        [sys.executable, "-m", "hermes.app.server", "--host", "127.0.0.1", "--port", str(port)],
        cwd=ROOT, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
    )
    try:
        deadline = time.monotonic() + 20
        while True:
            try:
                request(base, "GET", "/api/mode")
                break
            except OSError:
                if process.poll() is not None:
                    stdout, stderr = process.communicate()
                    raise RuntimeError(f"server exited during startup\nstdout:\n{stdout}\nstderr:\n{stderr}")
                if time.monotonic() >= deadline:
                    raise RuntimeError("server did not answer within 20 seconds")
                time.sleep(0.1)

        fixtures = [
            ("success", "GET", "/api/mode", None, 200, {
                "mode": "home", "verified": False, "override": False,
                "override_allowed": False, "gate_enabled": True,
            }),
            ("validation", "POST", "/api/compute", {}, 400, {
                "error": "operation must be add, subtract, multiply, or divide",
            }),
            ("gate_locked", "POST", "/api/input", {"key": "examples/All_Discussions.txt"}, 423, {
                "error": "results are student data — unlock the gate (campus + verified, or testing override)",
                "error_type": "locked",
            }),
            ("pair_candidate_gate_locked", "POST", "/api/pair_candidate", {
                "event_a": {}, "event_b": {},
            }, 423, {
                "error": "student data is locked in home mode; switch to campus mode on the IU network",
                "error_type": "locked",
            }),
            ("no_key", "POST", "/api/pml_score", {"text": "A square is a rectangle."}, 503, {
                "error": "No REALLMS API key is set. Click “Set key” (top-right) and paste your key, or add it to hermes/app/runtime/.env. See QUICKSTART_N103.md, step 2.",
                "error_type": "no_key",
            }),
            ("not_found", "POST", "/api/not-a-route", {}, 404, {"error": "not found"}),
        ]
        failures = []
        for name, method, path, payload, expected_status, expected_json in fixtures:
            actual = request(base, method, path, payload)
            expected = (expected_status, expected_json)
            if actual != expected:
                failures.append((name, expected, actual))

        # Query-stringed GETs: the split once crashed on exactly these, so
        # they are checked by shape (the bodies are computed, not constant).
        # First learner call starts the Prolog worker; allow it time.
        status, body = request(
            base, "GET",
            "/api/reorganize?domain=fraction_splitting&a=3&b=8&c=4&d=5",
            timeout=300)
        if status != 200 or not (isinstance(body, dict)
                                 and "question" in body and "result" in body):
            failures.append(("reorganize_query", (200, "dict with question+result"),
                             (status, str(body)[:120])))
        status, body = request(
            base, "GET",
            "/api/visualize/coordination?base=10&val_up=5&val_down=7%2F5",
            timeout=300, raw=True)
        if status != 200 or not body.lstrip().startswith(b"<svg"):
            failures.append(("coordination_query", (200, "raw <svg"),
                             (status, str(body[:80]))))

        if failures:
            for name, expected, actual in failures:
                print(f"{name}: expected {expected!r}, got {actual!r}", file=sys.stderr)
            return 1
        print(f"route behavior: {len(fixtures)} status+JSON fixtures "
              "+ 2 query-GET shape fixtures PASS")
        return 0
    finally:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=5)


if __name__ == "__main__":
    raise SystemExit(main())
