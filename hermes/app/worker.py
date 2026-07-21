"""Persistent SWI-Prolog worker for Hermes.

Keeps one bounded local worker alive and speaks newline-delimited JSON over
stdin/stdout. The worker loads this repo's `hermes_worker.pl`, so the symbolic
layer (event/pair scoring, geometry, misconceptions, lesson monitoring,
inferential strength) reads the live KB — no copied Prolog.
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

    # A generous ceiling for the strict boot handshake: load_runtime pulls in
    # the full symbolic layer before the persistent process reads the probe.
    # A cold filesystem cache earns the same headroom as the former one-shot
    # preflight, without loading the symbolic layer twice.
    _PREFLIGHT_TIMEOUT_S = 120.0

    def _start(self) -> None:
        env = os.environ.copy()
        env["UMEDCTA_ROOT"] = str(self.umedcta_root)
        worker_pl = self.umedcta_root / "hermes_worker.pl"
        self._proc = subprocess.Popen(
            [self.swipl, "--on-error=halt", "--on-warning=halt", "-q",
             "-s", str(worker_pl), "-g",
             "catch(with_output_to(user_error, load_runtime), E, worker_fatal(E)), "
             "set_prolog_flag(on_warning, print), "
             "set_prolog_flag(on_error, print), worker_loop"],
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
        self._boot_handshake(self._proc)

    def _boot_handshake(self, proc: subprocess.Popen[str]) -> None:
        """Prove that the one persistent process completed its strict load.

        SWI's ``halt`` warning/error modes terminate on a diagnostic during
        file loading or ``load_runtime``. Only after that strict region is
        clean do we restore the worker's normal print behavior and enter its
        request loop. A valid health reply therefore doubles as the old
        preflight guarantee and a protocol handshake.
        """
        assert proc.stdin is not None
        try:
            proc.stdin.write('{"id":"__boot__","op":"health"}\n')
            proc.stdin.flush()
            response_line = self._readline(
                proc,
                timeout=self._PREFLIGHT_TIMEOUT_S,
                restart_on_timeout=False,
            )
            response = json.loads(response_line)
            if response.get("id") != "__boot__" or not response.get("ok"):
                raise PersistentPrologError(
                    f"invalid worker boot handshake: {response_line!r}"
                )
        except TimeoutError as exc:
            self.close()
            raise PersistentPrologError(
                "worker preflight timed out after "
                f"{self._PREFLIGHT_TIMEOUT_S:.0f}s loading hermes_worker.pl"
            ) from exc
        except (BrokenPipeError, json.JSONDecodeError, PersistentPrologError) as exc:
            if self._stderr_thread is not None:
                self._stderr_thread.join(timeout=0.5)
            status = proc.poll()
            tail = self._recent_stderr()
            self.close()
            raise PersistentPrologError(
                f"worker preflight failed with status {status}: {tail or exc}"
            ) from exc

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

    def _readline(
        self,
        proc: subprocess.Popen[str],
        *,
        timeout: float | None = None,
        restart_on_timeout: bool = True,
    ) -> str:
        assert proc.stdout is not None
        deadline = time.monotonic() + (self.timeout if timeout is None else timeout)
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
        if not restart_on_timeout:
            raise TimeoutError("worker boot handshake timed out")
        self.restart()
        raise PersistentPrologError("worker request timed out")
