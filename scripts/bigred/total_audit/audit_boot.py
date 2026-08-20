#!/usr/bin/env python3
"""audit_boot.py — boot the Hermes server with a file-open audit hook.

Records every file the server process opens under the repo root, with a
timestamp and an open count, to the JSONL file named by HERMES_AUDIT_OPENS.
The ledger splits startup reads from request-time reads by timestamp, which
is what settles whether a tree is a build input or a runtime dependency.

A daemon thread dumps the tally every few seconds, so no shutdown path is
load-bearing (the app's server may own SIGTERM itself; the handler here is
best-effort only).
"""
from __future__ import annotations

import json
import os
import signal
import sys
import threading
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
OUT = Path(os.environ["HERMES_AUDIT_OPENS"])
_opens: dict[str, dict] = {}
_dirty = 0


def _dump() -> None:
    with OUT.open("w") as f:
        for path, rec in sorted(_opens.items()):
            f.write(json.dumps({"path": path, **rec}) + "\n")


def _hook(event: str, args: tuple) -> None:
    global _dirty
    if event != "open" or not args:
        return
    raw = args[0]
    if not isinstance(raw, (str, bytes, os.PathLike)):
        return
    try:
        p = Path(os.fsdecode(raw))
        if not p.is_absolute():
            p = Path.cwd() / p
        rel = str(p.resolve().relative_to(REPO))
    except (ValueError, OSError):
        return
    rec = _opens.get(rel)
    now = round(time.time(), 3)
    if rec is None:
        _opens[rel] = {"first_ts": now, "last_ts": now, "count": 1}
    else:
        rec["count"] += 1
        rec["last_ts"] = now
    _dirty += 1
    if _dirty >= 1000:
        _dirty = 0
        _dump()


def _terminate(_sig, _frame):
    _dump()
    os._exit(0)


def _dump_loop() -> None:
    while True:
        time.sleep(5)
        try:
            _dump()
        except OSError:
            pass


def main() -> None:
    sys.addaudithook(_hook)
    signal.signal(signal.SIGTERM, _terminate)
    threading.Thread(target=_dump_loop, daemon=True).start()
    sys.path.insert(0, str(REPO))
    from hermes.app.server import main as server_main
    try:
        server_main(sys.argv[1:])
    finally:
        _dump()


if __name__ == "__main__":
    main()
