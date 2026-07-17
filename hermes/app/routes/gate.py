"""FERPA gate and key-configuration routes."""
from __future__ import annotations

from typing import Any

from hermes.app import gate
from hermes.app.routes.logic import RouteLogic
from hermes.app.routes.registry import Route


def get_mode(ctx: Any) -> None:
    ctx._send_json(ctx.services.gate.mode_payload())


def get_preflight(ctx: Any) -> None:
    ok, reason = ctx.services.gate.run_preflight()
    ctx._send_json({"on_campus": ok, "reason": reason,
                    "key_configured": ctx.llm.api_key_configured(ctx.runtime)})


def post_mode(ctx: Any) -> None:
    target = str(ctx.payload.get("mode") or gate.HOME)
    ctx.services.gate.state = gate.set_mode(
        ctx.services.gate.state, target, preflight=ctx.services.gate.run_preflight
    )
    ctx._send_json(ctx.services.gate.mode_payload())


def override(ctx: Any) -> None:
    service = ctx.services.gate
    if not service.override_allowed:
        ctx._send_json({"error": "override not allowed; launch with HERMES_GATE_OVERRIDE=1"}, status=403)
        return
    service.state = gate.set_override(service.state, bool(ctx.payload.get("on")))
    ctx._send_json(service.mode_payload())


def post_preflight(ctx: Any) -> None:
    ok, reason = ctx.services.gate.run_preflight()
    ctx._send_json({"on_campus": ok, "reason": reason})


def reset(ctx: Any) -> None:
    ctx.services.gate.state = gate.GateState(override=ctx.services.gate.override_allowed)
    ctx._send_json({"ok": True, "mode": ctx.services.gate.state.mode})


def set_key(ctx: Any) -> None:
    RouteLogic(ctx)._handle_set_key(ctx.payload)


ROUTES = (
    Route("GET", "/api/mode", get_mode),
    Route("GET", "/api/preflight", get_preflight),
    Route("POST", "/api/mode", post_mode),
    Route("POST", "/api/override", override),
    Route("POST", "/api/preflight", post_preflight),
    Route("POST", "/api/reset", reset),
    Route("POST", "/api/set_key", set_key),
)

