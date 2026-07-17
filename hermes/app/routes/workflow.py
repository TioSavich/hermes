"""Verified workflow subprocess routes."""
from __future__ import annotations

import os
from typing import Any, Callable

from hermes.app import gate, workflow_api
from hermes.app.routes.logic import RouteLogic
from hermes.app.routes.registry import Route

COMMANDS = ("parse", "content", "profile", "draft", "grade", "score", "metrics")


def _workflow(command: str) -> Callable[[Any], None]:
    def handle(ctx: Any) -> None:
        state = ctx.services.gate.state
        os.environ["REALLMS_INSECURE"] = (
            "0" if (state.mode == gate.CAMPUS and state.verified) else "1"
        )
        result = workflow_api.run(command, ctx.payload, ctx.app_dir)
        if not result.get("ok"):
            hint, error_type = RouteLogic(ctx)._friendly_backend_error(
                f"{result.get('stderr') or ''}\n{result.get('stdout') or ''}"
            )
            if hint:
                result["hint"] = hint
                result["error_type"] = error_type
        ctx._send_json(result)
    return handle


ROUTES = tuple(
    Route("POST", f"/api/{command}", _workflow(command), access="verified")
    for command in COMMANDS
)

