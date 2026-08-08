"""Public monitoring and coverage routes."""
from __future__ import annotations

from typing import Any

from hermes.app import worker
from hermes.app.monitoring import visuals
from hermes.app.routes.registry import Route
from hermes.app.scripts import verify_monitoring_visuals


LESSON_DEMONSTRATION_KEYS = frozenset({
    "lesson", "lesson_code", "task_id", "observed_answer", "work_transcription"
})


def _lesson_code(ctx: Any) -> str:
    return str(ctx.payload.get("lesson_code") or ctx.payload.get("lesson") or "").strip()


def _bounded_monitoring_request(
    ctx: Any, operation: str, lesson_code: str, surface: str
) -> tuple[bool, Any]:
    """Use the isolated chart worker and turn its wall into a route refusal."""
    budget = ctx.services.monitoring_export_worker.timeout
    try:
        return True, ctx.services.monitoring_export_worker.request(
            operation, lesson_code=lesson_code
        )
    except worker.PersistentPrologError as exc:
        if "timed out" not in str(exc).lower():
            raise
        ctx._send_json(
            {
                "ok": False,
                "error": (
                    f"{surface} for {lesson_code} exceeded the {budget:.0f}-second "
                    "budget. The live result remains unavailable for this lesson; try "
                    "another lesson or return after the lesson data has been revised."
                ),
                "error_type": "budget_exceeded",
                "lesson_code": lesson_code,
                "budget_seconds": budget,
            },
            status=503,
        )
        return False, None


def field_context(ctx: Any) -> None:
    lesson_code = _lesson_code(ctx)
    if not lesson_code:
        ctx._send_json({"error": "lesson_code is required"}, status=400)
        return
    cached = ctx.services.field_context_cache.get(lesson_code)
    if cached is not None and "error" not in cached:
        result = dict(cached)
        result["served_from"] = "cache"
        ctx._send_json({"ok": True, "result": result})
        return
    completed, result = _bounded_monitoring_request(
        ctx, "field_context", lesson_code, "Field context"
    )
    if not completed:
        return
    result = dict(result)
    result["served_from"] = "live"
    ctx._send_json({"ok": True, "result": result})


def monitoring_chart_export(ctx: Any) -> None:
    lesson_code = _lesson_code(ctx)
    if not lesson_code:
        ctx._send_json({"error": "lesson_code is required"}, status=400)
        return
    completed, result = _bounded_monitoring_request(
        ctx, "monitoring_chart_export", lesson_code, "Monitoring chart export"
    )
    if not completed:
        return
    ctx._send_json({"ok": True, "result": result})


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
    completed, chart = _bounded_monitoring_request(
        ctx, "monitoring_chart_export", lesson_code, "Monitoring visuals"
    )
    if not completed:
        return
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


def lesson_arithmetic_demonstration(ctx: Any) -> None:
    """Run one request-local IM-G1-U3-L17 arithmetic demonstration."""
    extra = sorted(set(ctx.payload) - LESSON_DEMONSTRATION_KEYS)
    if extra:
        ctx._send_json({
            "ok": False,
            "error": f"unsupported request field: {extra[0]}",
            "error_type": "student_data_field_refused",
        }, status=400)
        return
    if "lesson" in ctx.payload and "lesson_code" in ctx.payload:
        ctx._send_json({
            "ok": False,
            "error": "Use lesson or lesson_code, not both.",
            "error_type": "ambiguous_lesson_field",
        }, status=400)
        return
    lesson_code = _lesson_code(ctx)
    if not lesson_code:
        ctx._send_json({"error": "lesson is required"}, status=400)
        return
    task_id = ctx.payload.get("task_id", "")
    if not isinstance(task_id, str):
        ctx._send_json({"error": "task_id must be text"}, status=400)
        return
    observed_answer = ctx.payload.get("observed_answer", "")
    if observed_answer != "" and (
        not isinstance(observed_answer, int) or isinstance(observed_answer, bool)
    ):
        ctx._send_json({"error": "observed_answer must be a whole number"}, status=400)
        return
    transcription = ctx.payload.get("work_transcription", "")
    if not isinstance(transcription, str):
        ctx._send_json({"error": "work_transcription must be text"}, status=400)
        return
    if len(transcription) > 4000:
        ctx._send_json({"error": "work_transcription is limited to 4000 characters"}, status=400)
        return

    result = ctx.worker_request(
        "lesson_arithmetic_demonstration",
        lesson=lesson_code,
        task_id=task_id,
        observed_answer=observed_answer,
        work_transcription=transcription,
    )
    if not isinstance(result, dict):
        ctx._send_json({"error": "lesson arithmetic demonstration returned a non-object payload"}, status=500)
        return
    response = dict(result)
    if result.get("status") == "complete":
        visual = visuals.lesson_arithmetic_demonstration_visual(
            result, ctx.worker_request, repo_root=ctx.repo_root
        )
        issues = verify_monitoring_visuals.verify_docs({
            lesson_code: {"visuals": [visual] if visual else []}
        })
        if not visual or issues:
            ctx._send_json({
                "ok": False,
                "error": "lesson arithmetic visual proof contract failed",
                "issues": issues or ["selected task returned no visual pair"],
            }, status=500)
            return
        response["visual_pair"] = visual
    ctx._send_json({"ok": True, "result": response})


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
    Route("POST", "/api/lesson_arithmetic_demonstration", lesson_arithmetic_demonstration),
    Route("POST", "/api/field_connectivity_audit", field_connectivity_audit),
    Route("POST", "/api/render_coverage", render_coverage),
)
