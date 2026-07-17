"""Public LLM boundaries; individual model branches retain their key checks."""
from __future__ import annotations

from typing import Any, Callable

from hermes.app.routes.logic import RouteLogic
from hermes.app.routes.registry import Route


def _post(method: str) -> Callable[[Any], None]:
    def handle(ctx: Any) -> None:
        getattr(RouteLogic(ctx), method)(ctx.payload)
    return handle


chat = _post("_handle_chat")
transcript_report = _post("_handle_transcript_report")
media_transcribe = _post("_handle_media_transcribe")
pml_score = _post("_handle_pml_score")

ROUTES = (
    Route("POST", "/api/chat", chat),
    Route("POST", "/api/transcript_report", transcript_report),
    Route("POST", "/api/media_transcribe", media_transcribe),
    Route("POST", "/api/pml_score", pml_score),
)

