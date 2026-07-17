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
from pathlib import Path
from typing import Any

# hermes/app/worker.py -> repo root is three parents up.
REPO_ROOT = Path(__file__).resolve().parents[2]


def resolve_umedcta_root(_root: Path | str | None = None) -> Path:
    env = os.environ.get("UMEDCTA_ROOT", "").strip()
    return Path(env) if env else REPO_ROOT


def resolve_swipl(swipl: str | None = None, *, root: Path | str | None = None) -> str:
    return swipl or os.environ.get("HERMES_SWIPL") or "swipl"


# The dispatch table `hermes_worker.pl` lives at the REPO ROOT (sibling of
# paths.pl), not under hermes/app/; resolve_umedcta_root() returns that root.
WORKER_PL = resolve_umedcta_root() / "hermes_worker.pl"
ROOT = REPO_ROOT


class PersistentPrologError(RuntimeError):
    pass


class PersistentPrologWorker:
    def __init__(
        self,
        *,
        umedcta_root: Path | str | None = None,
        swipl: str | None = None,
        timeout: float = 20.0,
    ) -> None:
        self.umedcta_root = Path(umedcta_root) if umedcta_root is not None else resolve_umedcta_root()
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
            self.restart()
            raise PersistentPrologError("worker pipe closed while sending request")
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

    def _start(self) -> None:
        env = os.environ.copy()
        env["UMEDCTA_ROOT"] = str(self.umedcta_root)
        worker_pl = self.umedcta_root / "hermes_worker.pl"
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
