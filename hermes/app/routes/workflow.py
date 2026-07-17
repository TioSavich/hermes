"""Verified in-process workflow routes."""
from __future__ import annotations

from typing import Any, Callable

from hermes.app import gate, llm
from hermes.app.routes.logic import RouteLogic
from hermes.app.routes.registry import Route
from hermes.app.workflow import service

COMMANDS = ("parse", "content", "profile", "draft", "grade", "score", "metrics")


def _workflow(command: str) -> Callable[[Any], None]:
    def handle(ctx: Any) -> None:
        state = ctx.services.gate.state
        workflow_context = service.WorkflowContext(
            pack_root=ctx.app_dir,
            llm_client=service.WorkflowLLMClient(
                llm, insecure=not (state.mode == gate.CAMPUS and state.verified)
            ),
            worker_request=ctx.services.worker.request,
            emit=lambda _text: None,
        )
        result = service.run(command, ctx.payload, workflow_context).as_dict()
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
