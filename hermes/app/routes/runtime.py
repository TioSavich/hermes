"""Runtime input, result, and model metadata routes."""
from __future__ import annotations

from typing import Any

from hermes.app import results
from hermes.app.routes.registry import Route


def models(ctx: Any) -> None:
    ctx._send_json({
        "default_model": ctx.llm.DEFAULT_MODEL,
        "model": ctx.llm.resolve_model(),
        "renderer": "reallms",
        "key_configured": ctx.llm.api_key_configured(ctx.runtime),
    })


def _resolve_input(ctx: Any, key: str):
    key = (key or "").strip()
    if "/" not in key:
        return None
    base_name, name = key.split("/", 1)
    base = ctx.app_dir / "examples" if base_name == "examples" else ctx.runtime / "input" if base_name == "input" else None
    if base is None:
        return None
    target = (base / name).resolve()
    if target.is_file() and (target == base.resolve() or base.resolve() in target.parents):
        return target
    return None


def input_file(ctx: Any) -> None:
    target = _resolve_input(ctx, str(ctx.payload.get("key") or ""))
    if target is None:
        ctx._send_json({"error": "input not found"}, status=404)
        return
    ctx._send_json({"text": target.read_text(encoding="utf-8", errors="replace")})


def results_list(ctx: Any) -> None:
    ctx._send_json(results.list_outputs(ctx.runtime))


def results_get(ctx: Any) -> None:
    try:
        ctx._send_json(results.read_output_file(ctx.runtime, str(ctx.payload.get("path") or "")))
    except (ValueError, FileNotFoundError) as exc:
        ctx._send_json({"error": str(exc)}, status=400)


ROUTES = (
    Route("GET", "/api/models", models),
    Route("POST", "/api/input", input_file, access="unlocked"),
    Route("POST", "/api/results/list", results_list, access="unlocked"),
    Route("POST", "/api/results/get", results_get, access="unlocked"),
)
