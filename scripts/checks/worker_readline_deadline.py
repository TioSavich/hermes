#!/usr/bin/env python3
"""Focused deadline and buffering checks for the persistent worker reader."""

from __future__ import annotations

import subprocess
import sys
import threading
import time
import traceback
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from hermes.app.worker import (  # noqa: E402
    REQUEST_TIMEOUT_MESSAGE,
    PersistentPrologError,
    PersistentPrologWorker,
)


READ_TIMEOUT_S = 0.2
# The margin proves the read is deadline-bounded, not fast: the defect this
# check guards against was an unbounded hang. A generous margin keeps the
# assertion meaningful while surviving CPU contention on loaded machines.
DEADLINE_MARGIN_S = 1.0


def spawn_fake(source: str) -> subprocess.Popen[str]:
    return subprocess.Popen(
        [sys.executable, "-c", source],
        cwd=ROOT,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
        bufsize=1,
    )


def stop_fake(proc: subprocess.Popen[str]) -> None:
    if proc.poll() is None:
        proc.terminate()
        try:
            proc.wait(timeout=1.0)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait(timeout=1.0)
    for stream in (proc.stdout, proc.stderr):
        if stream is not None:
            stream.close()


def check_partial_line_deadline(worker: PersistentPrologWorker) -> None:
    proc = spawn_fake(
        "import os, time; os.write(1, b'partial'); time.sleep(2.0)"
    )
    restart_calls = 0
    original_restart = worker.restart

    def record_restart() -> None:
        nonlocal restart_calls
        restart_calls += 1

    worker.restart = record_restart  # type: ignore[method-assign]
    started = time.monotonic()
    try:
        try:
            worker._readline(proc, timeout=READ_TIMEOUT_S)
        except PersistentPrologError as exc:
            assert str(exc) == REQUEST_TIMEOUT_MESSAGE
        else:
            raise AssertionError("partial line did not reach the read deadline")
        elapsed = time.monotonic() - started
        assert elapsed <= READ_TIMEOUT_S + DEADLINE_MARGIN_S, elapsed
        assert restart_calls == 1, restart_calls
    finally:
        worker.restart = original_restart  # type: ignore[method-assign]
        stop_fake(proc)


def check_boot_timeout_contract(worker: PersistentPrologWorker) -> None:
    proc = spawn_fake("import time; time.sleep(2.0)")
    try:
        try:
            worker._readline(
                proc,
                timeout=READ_TIMEOUT_S,
                restart_on_timeout=False,
            )
        except TimeoutError as exc:
            assert str(exc) == "worker boot handshake timed out"
        else:
            raise AssertionError("boot read did not raise TimeoutError")
    finally:
        stop_fake(proc)


def check_two_lines_one_burst(worker: PersistentPrologWorker) -> None:
    proc = spawn_fake(
        "import os, time; os.write(1, b'first\\nsecond\\n'); time.sleep(2.0)"
    )
    try:
        assert worker._readline(proc, timeout=READ_TIMEOUT_S) == "first"
        started = time.monotonic()
        assert worker._readline(proc, timeout=READ_TIMEOUT_S) == "second"
        assert time.monotonic() - started < READ_TIMEOUT_S
    finally:
        stop_fake(proc)


def check_single_utf8_line(worker: PersistentPrologWorker) -> None:
    source = (
        "import os, time; "
        "os.write(1, b'caf\\xc3'); time.sleep(0.05); "
        "os.write(1, b'\\xa9 intact\\n'); time.sleep(2.0)"
    )
    proc = spawn_fake(source)
    try:
        assert worker._readline(proc, timeout=READ_TIMEOUT_S) == "café intact"
    finally:
        stop_fake(proc)


def check_exit_mid_read(worker: PersistentPrologWorker) -> None:
    proc = spawn_fake(
        "import os, sys; os.write(1, b'partial'); "
        "sys.stderr.write('fake worker failed\\n'); sys.stderr.flush(); sys.exit(7)"
    )
    worker._stderr_thread = threading.Thread(
        target=worker._drain_stderr,
        args=(proc,),
        daemon=True,
    )
    worker._stderr_thread.start()
    try:
        try:
            worker._readline(proc, timeout=1.0)
        except PersistentPrologError as exc:
            message = str(exc)
            assert "worker exited with 7" in message, message
            assert "fake worker failed" in message, message
        else:
            raise AssertionError("worker exit did not raise PersistentPrologError")
    finally:
        stop_fake(proc)


def main() -> int:
    worker = PersistentPrologWorker(umedcta_root=ROOT)
    check_partial_line_deadline(worker)
    check_boot_timeout_contract(worker)
    check_two_lines_one_burst(worker)
    check_single_utf8_line(worker)
    check_exit_mid_read(worker)
    print(
        "PASS worker readline deadline, burst buffering, UTF-8 boundary, "
        "newline stripping, and exit status"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception:
        print("FAIL persistent worker readline checks", file=sys.stderr)
        traceback.print_exc()
        raise SystemExit(1)
