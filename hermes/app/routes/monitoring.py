"""Public monitoring and coverage routes."""
from __future__ import annotations

from typing import Any

from hermes.app.monitoring import visuals
from hermes.app.routes.registry import Route
from hermes.app.scripts import verify_monitoring_visuals


def _lesson_code(ctx: Any) -> str:
    return str(ctx.payload.get("lesson_code") or ctx.payload.get("lesson") or "").strip()


def field_context(ctx: Any) -> None:
    lesson_code = _lesson_code(ctx)
    if not lesson_code:
        ctx._send_json({"error": "lesson_code is required"}, status=400)
        return
    ctx._send_json({"ok": True, "result": ctx.worker_request("field_context", lesson_code=lesson_code)})


def monitoring_chart_export(ctx: Any) -> None:
    lesson_code = _lesson_code(ctx)
    if not lesson_code:
        ctx._send_json({"error": "lesson_code is required"}, status=400)
        return
    ctx._send_json({"ok": True, "result": ctx.worker_request("monitoring_chart_export", lesson_code=lesson_code)})


def ranked_figures(ctx: Any) -> None:
    lesson_code = _lesson_code(ctx)
    if not lesson_code:
        ctx._send_json({"error": "lesson_code is required"}, status=400)
        return
    ctx._send_json({"ok": True, "result": ctx.worker_request("ranked_figures", lesson_code=lesson_code)})


def monitoring_visuals(ctx: Any) -> None:
    lesson_code = _lesson_code(ctx)
    if not lesson_code:
        ctx._send_json({"error": "lesson_code is required"}, status=400)
        return
    chart = ctx.worker_request("monitoring_chart_export", lesson_code=lesson_code)
    if not isinstance(chart, dict):
        ctx._send_json({"error": "monitoring_chart_export returned a non-object payload"}, status=500)
        return
    result = visuals.monitoring_visuals_for_chart(
        lesson_code, chart, ctx.worker_request, repo_root=ctx.repo_root
    )
    issues = verify_monitoring_visuals.verify_docs({lesson_code: result})
    if issues:
        ctx._send_json({
            "ok": False,
            "error": "monitoring visual proof contract failed",
            "issues": issues,
        }, status=500)
        return
    ctx._send_json({"ok": True, "result": result})


def field_connectivity_audit(ctx: Any) -> None:
    if ctx.services.field_audit_cache is None:
        ctx.services.field_audit_cache = ctx.worker_request("field_connectivity_audit")
    ctx._send_json({"ok": True, "result": ctx.services.field_audit_cache})


def render_coverage(ctx: Any) -> None:
    ctx._send_json({"ok": True, "result": ctx.worker_request("render_coverage")})

ROUTES = (
    Route("POST", "/api/field_context", field_context),
    Route("POST", "/api/monitoring_chart_export", monitoring_chart_export),
    Route("POST", "/api/ranked_figures", ranked_figures),
    Route("POST", "/api/monitoring_visuals", monitoring_visuals),
    Route("POST", "/api/field_connectivity_audit", field_connectivity_audit),
    Route("POST", "/api/render_coverage", render_coverage),
)
