"""Public symbolic-worker routes."""
from __future__ import annotations

from typing import Any, Callable

from hermes.app.routes.logic import RouteLogic
from hermes.app.routes.registry import Route
from hermes.app.rendering import RenderDocumentError, validate_render_document


def validate_render_response(result: Any) -> str | None:
    """Return a client-facing validation detail for non-drawable results."""
    try:
        validate_render_document(result)
    except RenderDocumentError as exc:
        return str(exc)
    return None


def _post(method: str) -> Callable[[Any], None]:
    def handle(ctx: Any) -> None:
        getattr(RouteLogic(ctx), method)(ctx.payload)
    return handle


def _post_witness(family: str) -> Callable[[Any], None]:
    def handle(ctx: Any) -> None:
        RouteLogic(ctx)._handle_witness(family, ctx.payload)
    return handle


_HANDLERS = (
    ("/api/render", "_handle_render"),
    ("/api/expressive_power", "_handle_expressive_power"),
    ("/api/strategies", "_handle_strategies"),
    ("/api/strategy_trace", "_handle_strategy_trace"),
    ("/api/deontic_scorecard", "_handle_deontic_scorecard"),
    ("/api/crisis", "_handle_crisis"),
    ("/api/deontic_consequences", "_handle_deontic_consequences"),
    ("/api/deontic_up_level", "_handle_deontic_up_level"),
    ("/api/deontic_requires_entitlement", "_handle_deontic_requires_entitlement"),
    ("/api/sequent_proof", "_handle_sequent_proof"),
    ("/api/misconceptions", "_handle_misconceptions"),
    ("/api/standards", "_handle_standards"),
    ("/api/grounding", "_handle_grounding"),
    ("/api/geometry", "_handle_geometry"),
    ("/api/canonical_contract", "_handle_canonical_contract"),
    ("/api/canonical_check", "_handle_canonical_check"),
    ("/api/diagnose_error", "_handle_diagnose_error"),
    ("/api/query_misconception", "_handle_query_misconception"),
    ("/api/literature", "_handle_literature"),
    ("/api/notation_render", "_handle_notation_render"),
    ("/api/fraction_cgi_addition", "_handle_fraction_cgi_addition"),
    ("/api/lesson_deformation_chart", "_handle_lesson_deformation_chart"),
    ("/api/notation_monitoring_chart", "_handle_notation_monitoring_chart"),
    ("/api/brandom_backstop", "_handle_brandom_backstop"),
    ("/api/brandomian_check", "_handle_brandomian_check"),
    ("/api/hyperedges", "_handle_hyperedges"),
    ("/api/axiom_toggle", "_handle_axiom_toggle"),
    ("/api/carving_strategy_proof", "_handle_carving_strategy_proof"),
    ("/api/carving_operation_summary", "_handle_carving_operation_summary"),
    ("/api/benny_demo", "_handle_benny_demo"),
)

_WITNESS_HANDLERS = (
    ("/api/witness/crosswalk_claim", "crosswalk_claim"),
    ("/api/witness/geometry", "geometry"),
)


def capabilities(ctx: Any) -> None:
    RouteLogic(ctx)._handle_capabilities()


ROUTES = (
    Route("GET", "/api/capabilities", capabilities),
    *(Route("POST", path, _post(method)) for path, method in _HANDLERS),
    *(Route("POST", path, _post_witness(family)) for path, family in _WITNESS_HANDLERS),
)
