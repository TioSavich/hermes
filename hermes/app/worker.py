"""Persistent SWI-Prolog worker for Hermes.

Keeps one bounded local worker alive and speaks newline-delimited JSON over
stdin/stdout. The worker loads this repo's `hermes_worker.pl`, so the symbolic
layer (event/pair scoring, geometry, misconceptions, lesson monitoring,
expressive power) reads the live KB — no copied Prolog.
"""
from __future__ import annotations

import json
import os
import select
import subprocess
import threading
import time
from collections import deque
from typing import Any

from hermes.app.root import resolve_hermes_root


def resolve_swipl(
    swipl: str | None = None,
    *,
    root: os.PathLike[str] | str | None = None,
) -> str:
    return swipl or os.environ.get("HERMES_SWIPL") or "swipl"


class PersistentPrologError(RuntimeError):
    pass


class PersistentPrologWorker:
    def __init__(
        self,
        *,
        umedcta_root: os.PathLike[str] | str | None = None,
        swipl: str | None = None,
        timeout: float = 20.0,
    ) -> None:
        self.umedcta_root = resolve_hermes_root(umedcta_root)
        self.swipl = resolve_swipl(swipl)
        self.timeout = timeout
        self._seq = 0
        self._proc: subprocess.Popen[str] | None = None
        # The worker writes load diagnostics + per-lesson warnings to stderr.
        # If nobody drains that pipe, a stderr-heavy op (e.g. the connectivity
        # audit over ~1300 lessons) fills the 64KB OS buffer and the worker
        # deadlocks writing stderr while we wait for stdout. A daemon drainer
        # thread keeps the pipe empty and retains the tail for crash reports.
        self._stderr_tail: deque[str] = deque(maxlen=400)
        self._stderr_thread: threading.Thread | None = None

    def request(self, op: str, **payload: Any) -> Any:
        request = {"id": self._next_id(), "op": op, **payload}
        response = self.raw_request(request)
        if not response.get("ok"):
            error = response.get("error") or {}
            message = error.get("message") or "unknown worker error"
            raise PersistentPrologError(message)
        return response.get("result")

    def raw_request(self, request: dict[str, Any]) -> dict[str, Any]:
        proc = self._ensure_started()
        assert proc.stdin is not None
        assert proc.stdout is not None
        line = json.dumps(request, ensure_ascii=False)
        try:
            proc.stdin.write(line + "\n")
            proc.stdin.flush()
        except BrokenPipeError:
            stderr_tail = self._recent_stderr()
            self.restart()
            raise PersistentPrologError(
                f"worker pipe closed while sending request: {stderr_tail}"
            )
        response_line = self._readline(proc)
        try:
            return json.loads(response_line)
        except json.JSONDecodeError as exc:
            self.restart()
            raise PersistentPrologError(f"worker returned malformed json: {response_line!r}") from exc

    def close(self) -> None:
        if self._proc is None:
            return
        proc = self._proc
        self._proc = None
        if proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(timeout=2.0)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait(timeout=2.0)

    def restart(self) -> None:
        self.close()
        self._start()

    def _next_id(self) -> str:
        self._seq += 1
        return f"req_{self._seq:04d}"

    def _ensure_started(self) -> subprocess.Popen[str]:
        if self._proc is None or self._proc.poll() is not None:
            self._start()
        assert self._proc is not None
        return self._proc

    # A generous ceiling for the one-shot strict preflight: load_runtime
    # pulls in the full symbolic layer (event scoring through the geometry
    # and standards trees) and normally finishes in a few seconds, but a
    # cold filesystem cache earns the headroom.
    _PREFLIGHT_TIMEOUT_S = 120.0

    def _start(self) -> None:
        env = os.environ.copy()
        env["UMEDCTA_ROOT"] = str(self.umedcta_root)
        worker_pl = self.umedcta_root / "hermes_worker.pl"
        self._preflight(worker_pl, env)
        self._proc = subprocess.Popen(
            [self.swipl, "--on-error=status", "-q", "-s", str(worker_pl),
             "-g", "worker_main"],
            cwd=str(self.umedcta_root),
            env=env,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1,
        )
        self._stderr_tail = deque(maxlen=400)
        self._stderr_thread = threading.Thread(
            target=self._drain_stderr, args=(self._proc,), daemon=True
        )
        self._stderr_thread.start()

    def _preflight(self, worker_pl: Path, env: dict[str, str]) -> None:
        """Load hermes_worker.pl strictly, once, before the long-lived
        worker is spawned.

        --on-error=status on the worker process only changes the exit status
        of an eventual `halt` -- a load error SWI prints without raising
        still lets worker_main fall through into worker_loop, so a defective
        checkout would serve requests silently (malformed use_module
        directives once hid this way). This one-shot run adds --on-warning=status and
        refuses to spawn the worker on any diagnostic; the worker process
        below is only started once this returns.
        """
        try:
            proc = subprocess.run(
                [self.swipl, "--on-error=status", "--on-warning=status", "-q",
                 "-s", str(worker_pl), "-g", "load_runtime, halt."],
                cwd=str(self.umedcta_root),
                env=env,
                capture_output=True,
                text=True,
                timeout=self._PREFLIGHT_TIMEOUT_S,
            )
        except subprocess.TimeoutExpired as exc:
            raise PersistentPrologError(
                "worker preflight timed out after "
                f"{self._PREFLIGHT_TIMEOUT_S:.0f}s loading hermes_worker.pl"
            ) from exc
        if proc.returncode != 0:
            tail = (proc.stderr or "")[-4000:]
            raise PersistentPrologError(
                f"worker preflight failed with status {proc.returncode}: {tail}"
            )

    def _drain_stderr(self, proc: subprocess.Popen[str]) -> None:
        """Continuously empty the worker's stderr so the pipe never fills."""
        stream = proc.stderr
        if stream is None:
            return
        try:
            for line in stream:  # blocks until EOF (process exit)
                self._stderr_tail.append(line.rstrip("\n"))
        except (ValueError, OSError):
            pass

    def _recent_stderr(self) -> str:
        return "\n".join(self._stderr_tail).strip()

    def _readline(self, proc: subprocess.Popen[str]) -> str:
        assert proc.stdout is not None
        deadline = time.monotonic() + self.timeout
        fd = proc.stdout.fileno()
        while time.monotonic() < deadline:
            if proc.poll() is not None:
                # Give the drainer a beat to flush the final stderr lines.
                if self._stderr_thread is not None:
                    self._stderr_thread.join(timeout=0.5)
                raise PersistentPrologError(
                    f"worker exited with {proc.returncode}: {self._recent_stderr()}"
                )
            remaining = max(0.0, deadline - time.monotonic())
            readable, _, _ = select.select([fd], [], [], min(0.1, remaining))
            if not readable:
                continue
            line = proc.stdout.readline()
            if line:
                return line.rstrip("\n")
        self.restart()
        raise PersistentPrologError("worker request timed out")
