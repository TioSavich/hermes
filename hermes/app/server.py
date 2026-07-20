"""Hermes local teaching console HTTP transport.

The server owns mutable gate, worker, and cache state. Endpoint behavior lives
behind an immutable declarative registry and receives a per-request context.
"""
from __future__ import annotations

import argparse
import importlib.util
import json
import mimetypes
import os
import sys
import threading
import urllib.parse
from dataclasses import dataclass, field
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from types import ModuleType
from types import MappingProxyType
from typing import Any

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from hermes.app import gate, llm, worker
from hermes.app.field_context_cache import load_field_context_cache
from hermes.app.routes.logic import RouteLogic
from hermes.app.routes.registry import Router, build_router
from hermes.app.system_prompts import load_required_system_prompts

APP_DIR = Path(__file__).resolve().parent
WEB_ROOT = APP_DIR / "web"
RUNTIME = APP_DIR / "runtime"
REPO_ROOT = APP_DIR.parents[1]
STATIC_MOUNTS = {
    "more-zeeman": REPO_ROOT / "more-zeeman",
    "learner": REPO_ROOT / "formal" / "learner",
    "representation": REPO_ROOT / "representation",
    "ASKTM_Data": REPO_ROOT / "ASKTM_Data",
    "docs": REPO_ROOT / "docs",
}

OVERRIDE_ALLOWED = os.environ.get("HERMES_GATE_OVERRIDE", "").strip().lower() in ("1", "true", "yes")
INITIAL_GATE_ENABLED = gate.gate_enabled_for_launch(
    os.environ.get("HERMES_HOST", "127.0.0.1"), os.environ.get("HERMES_GATE")
)

_WORKER_TRANSPORT_MARKERS = ("pipe closed", "malformed json", "worker exited")
_WORKER_TIMEOUT = 120.0


@dataclass(slots=True)
class WorkerService:
    """One serialized, restartable Prolog worker owned by the server."""

    timeout: float = _WORKER_TIMEOUT
    _lock: threading.Lock = field(default_factory=threading.Lock)
    _worker: worker.PersistentPrologWorker | None = None

    def _shared_worker(self) -> worker.PersistentPrologWorker:
        if self._worker is None:
            self._worker = worker.PersistentPrologWorker(timeout=self.timeout)
        return self._worker

    def request(self, op: str, **payload: Any) -> Any:
        with self._lock:
            active = self._shared_worker()
            try:
                return active.request(op, **payload)
            except worker.PersistentPrologError as exc:
                if any(marker in str(exc).lower() for marker in _WORKER_TRANSPORT_MARKERS):
                    active.restart()
                    return active.request(op, **payload)
                raise
            except OSError:
                try:
                    active.close()
                except Exception:
                    pass
                self._worker = None
                raise

    def close(self) -> None:
        if self._worker is not None:
            self._worker.close()


@dataclass(slots=True)
class GateService:
    """Mutable launch gate state and its unchanged preflight policy."""

    runtime: Path
    enabled: bool = INITIAL_GATE_ENABLED
    override_allowed: bool = OVERRIDE_ALLOWED
    state: gate.GateState = field(default_factory=lambda: gate.GateState(override=OVERRIDE_ALLOWED))

    def mode_payload(self) -> dict[str, Any]:
        return {
            "mode": self.state.mode,
            "verified": self.state.verified,
            "override": self.state.override,
            "override_allowed": self.override_allowed,
            "gate_enabled": self.enabled,
        }

    def run_preflight(self) -> tuple[bool, str]:
        key = llm.load_key(self.runtime)
        if key is None:
            return False, "no REALLMS_API_KEY configured (set it in the app or runtime/.env)"
        return llm.secure_preflight(api_key=key, api_url=llm.resolve_api_url())


@dataclass(slots=True)
class AppServices:
    """All mutable process state retained by the transport shell."""

    worker: WorkerService
    gate: GateService
    field_context_cache: dict[str, dict[str, Any]] = field(default_factory=dict)
    field_audit_cache: Any | None = None
    _two_pass_cache: ModuleType | None = None
    _two_pass_lock: threading.Lock = field(default_factory=threading.Lock)

    def two_pass_module(self) -> ModuleType:
        with self._two_pass_lock:
            if self._two_pass_cache is not None:
                return self._two_pass_cache
            path = REPO_ROOT / "scripts" / "talkmoves_two_pass.py"
            spec = importlib.util.spec_from_file_location("hermes_talkmoves_two_pass", path)
            if spec is None or spec.loader is None:
                raise RuntimeError(f"cannot load two-pass reporter: {path}")
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
            self._two_pass_cache = module
            return module


# Prompt loading is a startup invariant, before a socket is opened.
SYSTEM_PROMPTS = MappingProxyType(load_required_system_prompts())
SERVICES = AppServices(
    WorkerService(),
    GateService(RUNTIME),
    field_context_cache=load_field_context_cache(REPO_ROOT),
)
ROUTER = build_router()


@dataclass(slots=True)
class RequestContext:
    handler: "HermesHandler"
    services: AppServices
    router: Router
    method: str
    raw_path: str
    parsed: urllib.parse.SplitResult
    payload: Any = None
    app_dir: Path = APP_DIR
    web_root: Path = WEB_ROOT
    runtime: Path = RUNTIME
    repo_root: Path = REPO_ROOT
    static_mounts: dict[str, Path] = field(default_factory=lambda: STATIC_MOUNTS)
    prompts: dict[str, str] = field(default_factory=lambda: SYSTEM_PROMPTS)
    llm: Any = llm

    @property
    def route_path(self) -> str:
        # These routes historically dispatched through urlsplit().path because
        # they consume query parameters (or, for root/knowledge, shared that
        # branch). All other exact routes compared the raw request target.
        parsed_routes = {
            "/", "/api/knowledge", "/api/visualize/coordination",
            "/api/reorganize", "/api/fraction/render", "/api/fraction/compare",
            "/api/unit_coordination.svg",
        }
        if self.method == "GET" and self.parsed.path in parsed_routes:
            return self.parsed.path
        return self.raw_path

    def worker_request(self, op: str, **payload: Any) -> Any:
        return self.services.worker.request(op, **payload)

    def prompt(self, name: str) -> str:
        return self.prompts[name]

    def _gate_or_423(self, op_name: str) -> bool:
        service = self.services.gate
        if not service.enabled:
            return True
        allowed, reason = gate.check_op_allowed(op_name, service.state)
        if not allowed:
            self._send_json({"error": reason, "error_type": "locked"}, status=423)
            return False
        return True

    def _require_unlocked(self) -> bool:
        service = self.services.gate
        if not service.enabled or gate.student_data_unlocked(service.state):
            return True
        self._send_json(
            {"error": "results are student data — unlock the gate (campus + verified, or testing override)",
             "error_type": "locked"},
            status=423,
        )
        return False

    def _send_file(self, path: Path) -> None:
        self.handler._send_file(path)

    def _send_utf8(self, payload: str, content_type: str, *, status: int = 200) -> None:
        self.handler._send_utf8(payload, content_type, status=status)

    def _send_json(self, payload: Any, *, status: int = 200) -> None:
        self.handler._send_json(payload, status=status)


class HermesHandler(BaseHTTPRequestHandler):
    server_version = "HermesConsole/0.2"
    MAX_BODY_BYTES = 64 * 1024 * 1024
    services = SERVICES
    router = ROUTER

    def _context(self, method: str, payload: Any = None) -> RequestContext:
        return RequestContext(
            handler=self,
            services=self.services,
            router=self.router,
            method=method,
            raw_path=self.path,
            parsed=urllib.parse.urlsplit(self.path),
            payload=payload,
        )

    def do_OPTIONS(self) -> None:
        self.send_response(204)
        self._send_cors_headers()
        self.send_header("Content-Length", "0")
        self.end_headers()

    def do_GET(self) -> None:
        self._dispatch_guarded(self._context("GET"))

    def do_POST(self) -> None:
        context = self._context("POST")
        try:
            context.payload = self._read_json()
        except Exception as exc:
            self._send_backend_error(context, exc)
            return
        self._dispatch_guarded(context)

    def _dispatch_guarded(self, context: RequestContext) -> None:
        """Dispatch a route, turning an uncaught exception into a JSON 500.

        Without this, BaseHTTPRequestHandler's default handle_error() prints
        the traceback to whatever sys.stderr currently resolves to — under
        the workflow capture proxy, that can be another thread's in-flight
        capture buffer — and drops the connection instead of answering it.
        """
        try:
            self.router.dispatch(context)
        except Exception as exc:
            self._send_backend_error(context, exc)

    def _send_backend_error(self, context: RequestContext, exc: Exception) -> None:
        message, error_type = RouteLogic(context)._friendly_backend_error(str(exc))
        if message:
            self._send_json(
                {"error": message, "error_type": error_type, "detail": str(exc)},
                status=500,
            )
        else:
            self._send_json({"error": str(exc)}, status=500)

    def log_message(self, fmt: str, *args: Any) -> None:
        return

    def _read_json(self) -> Any:
        length = int(self.headers.get("Content-Length", "0"))
        if length > self.MAX_BODY_BYTES:
            raise ValueError(
                f"request body is {length} bytes; this server accepts up to "
                f"{self.MAX_BODY_BYTES // (1024 * 1024)} MB"
            )
        raw = self.rfile.read(length).decode("utf-8")
        return json.loads(raw or "{}")

    def _send_file(self, path: Path) -> None:
        data = path.read_bytes()
        content_type = mimetypes.guess_type(str(path))[0] or "text/html; charset=utf-8"
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _send_utf8(self, payload: str, content_type: str, *, status: int = 200) -> None:
        data = payload.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self._send_cors_headers()
        self.send_header("Cache-Control", "no-store, max-age=0")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _send_cors_headers(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")

    def _send_json(self, payload: Any, *, status: int = 200) -> None:
        data = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self._send_cors_headers()
        self.send_header("Cache-Control", "no-store, max-age=0")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Run the local Hermes console.")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8765)
    args = parser.parse_args(argv)

    SERVICES.gate.enabled = gate.gate_enabled_for_launch(args.host, os.environ.get("HERMES_GATE"))
    httpd = ThreadingHTTPServer((args.host, args.port), HermesHandler)

    def warm_field_audit_cache() -> None:
        try:
            result = SERVICES.worker.request("field_connectivity_audit")
            if SERVICES.field_audit_cache is None:
                SERVICES.field_audit_cache = result
        except Exception:
            pass

    threading.Thread(target=warm_field_audit_cache, daemon=True).start()
    state = SERVICES.gate.state
    print(f"Hermes console: http://{args.host}:{args.port}")
    print(f"Mode: {state.mode}  (student data {'unlocked' if gate.student_data_unlocked(state) else 'locked'})")
    if SERVICES.gate.override_allowed:
        print("*** TESTING OVERRIDE ON (HERMES_GATE_OVERRIDE) — gate open; use synthetic/public data only ***")
    print(f"Default model: {llm.DEFAULT_MODEL}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        httpd.server_close()
        SERVICES.worker.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
