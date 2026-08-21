"""Public LLM boundaries; individual model branches retain their key checks."""
from __future__ import annotations

from typing import Any, Callable

from hermes.app.routes.logic import RouteLogic
from hermes.app.routes.registry import Route


def _post(method: str) -> Callable[[Any], None]:
    def handle(ctx: Any) -> None:
        getattr(RouteLogic(ctx), method)(ctx.payload)
    return handle


def get_preflight(ctx: Any) -> None:
    ok, reason = ctx.services.tls.run_preflight()
    ctx._send_json({
        "ok": ok,
        "reason": reason,
        "key_configured": ctx.llm.api_key_configured(ctx.runtime),
    })


def post_preflight(ctx: Any) -> None:
    ok, reason = ctx.services.tls.run_preflight()
    ctx._send_json({"ok": ok, "reason": reason})


def set_key(ctx: Any) -> None:
    RouteLogic(ctx)._handle_set_key(ctx.payload)


chat = _post("_handle_chat")
help_docs = _post("_handle_help")
transcript_report = _post("_handle_transcript_report")
media_transcribe = _post("_handle_media_transcribe")
pml_score = _post("_handle_pml_score")

ROUTES = (
    Route("GET", "/api/preflight", get_preflight),
    Route("POST", "/api/preflight", post_preflight),
    Route("POST", "/api/set_key", set_key),
    Route("POST", "/api/chat", chat),
    Route("POST", "/api/help", help_docs),
    Route("POST", "/api/transcript_report", transcript_report),
    Route("POST", "/api/media_transcribe", media_transcribe),
    Route("POST", "/api/pml_score", pml_score),
)
