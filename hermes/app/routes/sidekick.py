"""Sidekick chat transport: one status GET and one chat POST.

The sidekick lane owns its own in-process HermesMCPServer, which owns its own
Prolog worker (timeout 120 s). It never touches the console's shared
SERVICES.worker: a multi-round chat turn on that lock would block every page.
Chat turns serialize on this module's own lock instead.
"""
from __future__ import annotations

import glob
import json
import os
import threading
import time
from pathlib import Path
from typing import Any

from hermes.app.routes.registry import Route
from hermes.app.sidekick_llm import SidekickClient, endpoint_base
from hermes.app.sidekick_turn import MENU_TOOLS, run_turn

_FLOORS_DIR = "runtime/experiments/sidekick/floors"
_DEFAULT_GGUF = "runtime/experiments/sidekick/models/sidekick-Q4_K_M.gguf"
_LOCK_WAIT_S = 5.0


class SidekickService:
    """Module-level singleton state for the sidekick lane."""

    def __init__(self) -> None:
        self.mcp: Any = None
        self.lock = threading.Lock()
        self.state_lock = threading.Lock()
        self.warm_state = "cold"
        self.strategy_names: frozenset[str] = frozenset()
        self._warm_thread: threading.Thread | None = None

    def gguf_path(self, app_dir: Path) -> Path:
        override = os.environ.get("HERMES_SIDEKICK_GGUF", "").strip()
        return Path(override) if override else app_dir / _DEFAULT_GGUF

    def ensure_mcp(self, repo_root: Path) -> Any:
        """Build the lane's MCP server on first need. Caller holds no lock."""
        with self.state_lock:
            if self.mcp is None:
                from hermes.mcp.server import HermesMCPServer

                self.mcp = HermesMCPServer("core", repo_root)
            return self.mcp

    def warm_up(self, repo_root: Path) -> None:
        """Boot Prolog and collect the strategy-name list, once, off-thread."""
        with self.state_lock:
            if self._warm_thread is not None:
                return
            self.warm_state = "warming"
            thread = threading.Thread(
                target=self._warm_body, args=(repo_root,), daemon=True
            )
            self._warm_thread = thread
        thread.start()

    def _warm_body(self, repo_root: Path) -> None:
        try:
            mcp = self.ensure_mcp(repo_root)
            names: list[str] = []
            offset = 0
            while True:
                page = mcp.call("list_strategies", {"limit": 100, "offset": offset})
                rows = page.get("strategies") or page.get("rows") or []
                if not isinstance(rows, list):
                    break
                names.extend(str(row.get("name")) for row in rows
                             if isinstance(row, dict) and row.get("name"))
                offset += 100
                if offset >= int(page.get("matched", 0)) or not rows:
                    break
            with self.state_lock:
                self.strategy_names = frozenset(names)
                self.warm_state = "warm"
        except Exception as exc:  # The state names the reason; the page renders it.
            with self.state_lock:
                self.warm_state = f"failed: {type(exc).__name__}: {str(exc)[:160]}"


SERVICE = SidekickService()


def _newest_floors(app_dir: Path) -> dict[str, Any] | None:
    """The newest floors-*.json arm summaries, read, never recomputed."""
    try:
        pattern = str(app_dir / _FLOORS_DIR / "floors-*.json")
        files = sorted(glob.glob(pattern), key=os.path.getmtime)
        if not files:
            return None
        path = Path(files[-1])
        data = json.loads(path.read_text(encoding="utf-8"))
        arms_out = []
        for arm in data.get("arms") or []:
            if not isinstance(arm, dict):
                continue
            cuts_out = {}
            for cut_name, cut in (arm.get("cuts") or {}).items():
                if not isinstance(cut, dict) or not cut.get("items"):
                    continue
                entry = {}
                for metric in ("call_when_needed", "spurious_call",
                               "formulation_hit", "refusal_relay"):
                    value = cut.get(metric)
                    entry[metric] = value.get("rate") if isinstance(value, dict) else None
                entry["evidence_yield"] = cut.get("evidence_yield")
                entry["items"] = cut.get("items")
                cuts_out[cut_name] = entry
            arms_out.append({"arm": arm.get("arm"), "cuts": cuts_out})
        return {"artifact": path.name, "model": data.get("model"), "arms": arms_out}
    except Exception:
        return None


def status(ctx: Any) -> None:
    SERVICE.warm_up(ctx.repo_root)
    client = SidekickClient()
    online = client.probe()
    gguf = SERVICE.gguf_path(ctx.app_dir)
    busy = not SERVICE.lock.acquire(blocking=False)
    if not busy:
        SERVICE.lock.release()
    with SERVICE.state_lock:
        warm_state = SERVICE.warm_state
    ctx._send_json({
        "model": {
            "online": online,
            "endpoint": endpoint_base(),
            "gguf_present": gguf.exists(),
            "gguf_path": str(gguf),
        },
        "worker": warm_state,
        "busy": busy,
        "mode_default": "routed",
        "menu": list(MENU_TOOLS),
        "measured": _newest_floors(ctx.app_dir),
    })


def chat(ctx: Any) -> None:
    payload = ctx.payload if isinstance(ctx.payload, dict) else {}
    message = str(payload.get("message") or "").strip()
    mode = str(payload.get("mode") or "routed")
    if not message:
        ctx._send_json({"error": "message is required"}, status=400)
        return
    if len(message) > 4000:
        ctx._send_json({"error": "message is over the 4000-character bound"}, status=400)
        return
    if not SERVICE.lock.acquire(timeout=_LOCK_WAIT_S):
        ctx._send_json({
            "busy": True,
            "reply": ("Another turn is running on the sidekick lane. "
                      "Send this message again when it finishes."),
        })
        return
    try:
        mcp = SERVICE.ensure_mcp(ctx.repo_root)
        with SERVICE.state_lock:
            names = SERVICE.strategy_names
        client = SidekickClient()
        started = time.time()
        result = run_turn(message, mode, client.complete, mcp, ctx.prompts, names)
        body = result.to_dict()
        body["elapsed_ms"] = int((time.time() - started) * 1000)
        ctx._send_json(body)
    finally:
        SERVICE.lock.release()


ROUTES = (
    Route("GET", "/api/sidekick/status", status),
    Route("POST", "/api/sidekick_chat", chat),
)
