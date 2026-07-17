"""In-process execution service for the seven Hermes workflow commands."""
from __future__ import annotations

import importlib
import io
import os
import ssl
import sys
import threading
from contextvars import ContextVar, Token
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable

from hermes.app import llm, worker


WorkerRequest = Callable[..., Any]
Emitter = Callable[[str], None]


@dataclass(frozen=True, slots=True)
class WorkflowContext:
    pack_root: Path
    llm_client: Any
    worker_request: WorkerRequest
    emit: Emitter


@dataclass(frozen=True, slots=True)
class WorkflowResult:
    command: str
    returncode: int
    ok: bool
    stdout: str
    stderr: str

    def as_dict(self) -> dict[str, Any]:
        """Return the legacy HTTP response shape and truncation limits."""
        return {
            "command": self.command,
            "returncode": self.returncode,
            "ok": self.ok,
            "stdout": self.stdout[-8000:],
            "stderr": self.stderr[-4000:],
        }


@dataclass(frozen=True, slots=True)
class WorkflowLLMClient:
    """Per-request LLM policy without changing the process environment."""

    module: Any
    insecure: bool

    def __getattr__(self, name: str) -> Any:
        return getattr(self.module, name)

    @staticmethod
    def _settings(pack_root: Path) -> dict[str, str]:
        settings = dict(os.environ)
        candidates = [Path.cwd() / ".env", pack_root / ".env"]
        candidates.extend(parent / ".env" for parent in pack_root.parents)
        for candidate in candidates:
            if not candidate.exists():
                continue
            for raw in candidate.read_text(encoding="utf-8").splitlines():
                line = raw.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, _, value = line.partition("=")
                key = key.strip()
                if key and key not in settings:
                    settings[key] = value.strip().strip('"').strip("'")
            break
        return settings

    def make_client(self, pack_root: Path) -> dict[str, Any]:
        settings = self._settings(Path(pack_root))
        api_key = settings.get("REALLMS_API_KEY", "").strip()
        if not api_key or api_key.startswith("sk-PASTE") or api_key == "YOUR_KEY_HERE":
            self.module.fail(
                "set REALLMS_API_KEY in your environment or in a .env file (see paste.txt)."
            )
        api_url = settings.get("REALLMS_BASE_URL", self.module.DEFAULT_API_URL).strip().rstrip("/")
        if not api_url.endswith("/chat/completions"):
            suffix = "/chat/completions" if api_url.endswith("/v1") else "/v1/chat/completions"
            api_url += suffix
        model = settings.get("REALLMS_MODEL", self.module.DEFAULT_MODEL).strip()
        if self.insecure:
            print(
                "warning: REALLMS_INSECURE is set; TLS verification disabled.",
                file=sys.stderr,
            )
            ssl_ctx = ssl.create_default_context()
            ssl_ctx.check_hostname = False
            ssl_ctx.verify_mode = ssl.CERT_NONE
        else:
            ssl_ctx = self.module.build_secure_ssl_context(warn_on_error=True)
        return {
            "api_key": api_key,
            "api_url": api_url,
            "model": model,
            "ssl_ctx": ssl_ctx,
        }


COMMANDS = ("parse", "content", "profile", "draft", "grade", "score", "metrics")
POSITIONAL = {"parse": "input", "content": "activity", "draft": "unit"}
FLAGS = {
    "force", "list", "graph", "offline", "skip_prompts",
    "no_consolidate", "no_per_file", "include_absent",
}

_ACTIVE_CONTEXT: ContextVar[WorkflowContext | None] = ContextVar(
    "hermes_workflow_context", default=None
)
_WORKFLOW_LOCK = threading.RLock()

_STDOUT_CAPTURE: ContextVar[io.StringIO | None] = ContextVar(
    "hermes_workflow_stdout_capture", default=None
)
_STDERR_CAPTURE: ContextVar[io.StringIO | None] = ContextVar(
    "hermes_workflow_stderr_capture", default=None
)


class _ContextRoutedStream:
    """A process-global stream that routes each write through a ContextVar.

    `redirect_stdout`/`redirect_stderr` swap `sys.stdout`/`sys.stderr`
    themselves, so every thread sees the swap for as long as it lasts — a
    concurrent thread's traceback can land in an unrelated in-flight
    workflow's captured buffer. This proxy is installed once, process-wide,
    and never swapped again; each write instead consults a ContextVar that is
    per-thread by default (contextvars.Context is thread-local unless
    explicitly propagated), so one thread setting a capture buffer leaves
    every other thread's writes passing through to the real stream untouched.
    """

    def __init__(self, capture_var: ContextVar[io.StringIO | None], original: Any) -> None:
        self._capture_var = capture_var
        self._original = original

    def _target(self) -> Any:
        buffer = self._capture_var.get()
        return self._original if buffer is None else buffer

    def write(self, text: str) -> int:
        return self._target().write(text)

    def flush(self) -> None:
        target = self._target()
        flush = getattr(target, "flush", None)
        if flush is not None:
            flush()

    def __getattr__(self, name: str) -> Any:
        # Transparent for everything else (isatty, encoding, buffer, ...) so
        # unrelated code that pokes at sys.stdout/sys.stderr keeps working.
        return getattr(self._original, name)


def _install_capture_routing() -> None:
    """Install the routed-stream proxies on sys.stdout/sys.stderr once.

    Idempotent: re-running (e.g. a stray re-import) will not double-wrap.
    """
    if not isinstance(sys.stdout, _ContextRoutedStream):
        sys.stdout = _ContextRoutedStream(_STDOUT_CAPTURE, sys.stdout)
    if not isinstance(sys.stderr, _ContextRoutedStream):
        sys.stderr = _ContextRoutedStream(_STDERR_CAPTURE, sys.stderr)


_install_capture_routing()


def current_context() -> WorkflowContext:
    context = _ACTIVE_CONTEXT.get()
    if context is None:
        raise RuntimeError("workflow command is not running in a WorkflowContext")
    return context


def _activate(context: WorkflowContext) -> Token[WorkflowContext | None]:
    return _ACTIVE_CONTEXT.set(context)


def _deactivate(token: Token[WorkflowContext | None]) -> None:
    _ACTIVE_CONTEXT.reset(token)


def build_argv(command: str, payload: dict[str, Any]) -> list[str]:
    if command not in COMMANDS:
        raise ValueError(f"unknown workflow command: {command}")
    argv: list[str] = []
    positional = POSITIONAL.get(command)
    if positional and payload.get(positional):
        argv.append(str(payload[positional]))
    for key, value in payload.items():
        if key == positional:
            continue
        flag = "--" + key.replace("_", "-")
        if key in FLAGS:
            if value:
                argv.append(flag)
        elif value not in (None, ""):
            argv.extend([flag, str(value)])
    return argv


def run_command(
    command: str,
    payload: dict[str, Any],
    context: WorkflowContext,
    entrypoint: Callable[[list[str] | None], Any],
) -> WorkflowResult:
    """Run one argparse adapter while containing process-local side effects."""
    stdout = io.StringIO()
    stderr = io.StringIO()
    returncode = 0
    # All current commands write shared runtime outputs. Metrics stays under the
    # same lock until a race-free output proof permits a narrower policy.
    with _WORKFLOW_LOCK:
        context_token = _activate(context)
        stdout_token = _STDOUT_CAPTURE.set(stdout)
        stderr_token = _STDERR_CAPTURE.set(stderr)
        try:
            try:
                value = entrypoint(build_argv(command, payload))
                if isinstance(value, int):
                    returncode = value
            except SystemExit as exc:
                code = exc.code
                if code is None:
                    returncode = 0
                elif isinstance(code, int):
                    returncode = code
                else:
                    returncode = 1
                    print(code, file=stderr)
            except Exception as exc:  # match the subprocess boundary's failure result
                returncode = 1
                print(str(exc), file=stderr)
        finally:
            _STDERR_CAPTURE.reset(stderr_token)
            _STDOUT_CAPTURE.reset(stdout_token)
            _deactivate(context_token)
    out = stdout.getvalue()
    err = stderr.getvalue()
    if out:
        context.emit(out)
    if err:
        context.emit(err)
    return WorkflowResult(command, returncode, returncode == 0, out, err)


class LocalWorker:
    """Lazily create the standalone CLI's worker and close it at exit."""

    def __init__(self) -> None:
        self._worker: worker.PersistentPrologWorker | None = None

    def request(self, op: str, **payload: Any) -> Any:
        if self._worker is None:
            self._worker = worker.PersistentPrologWorker()
        return self._worker.request(op, **payload)

    def close(self) -> None:
        if self._worker is not None:
            self._worker.close()


def cli_context() -> tuple[WorkflowContext, LocalWorker]:
    default_root = Path(__file__).resolve().parents[1]
    pack_root = Path(os.environ.get("HERMES_PACK_ROOT", default_root)).expanduser().resolve()
    local_worker = LocalWorker()
    return WorkflowContext(pack_root, llm, local_worker.request, lambda _text: None), local_worker


def run_cli(
    command: str,
    argv: list[str] | None,
    entrypoint: Callable[[list[str] | None], Any],
) -> int:
    """Run a command directly, with a local worker available on demand."""
    context, local_worker = cli_context()
    token = _activate(context)
    try:
        value = entrypoint(argv)
        return value if isinstance(value, int) else 0
    finally:
        _deactivate(token)
        local_worker.close()


def run(command: str, payload: dict[str, Any], context: WorkflowContext) -> WorkflowResult:
    if command not in COMMANDS:
        raise ValueError(f"unknown workflow command: {command}")
    module = importlib.import_module(f"hermes.app.workflow.{command}")
    return module.run(payload, context)
