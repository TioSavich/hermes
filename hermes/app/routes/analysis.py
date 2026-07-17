"""Learner and discourse analysis routes."""
from __future__ import annotations

from typing import Any, Callable

from hermes.app.routes.logic import RouteLogic
from hermes.app.routes.registry import Route


def _post(method: str) -> Callable[[Any], None]:
    def handle(ctx: Any) -> None:
        getattr(RouteLogic(ctx), method)(ctx.payload)
    return handle


def knowledge(ctx: Any) -> None:
    RouteLogic(ctx)._handle_learner_knowledge()


def coordination(ctx: Any) -> None:
    RouteLogic(ctx)._handle_visualize_coordination(ctx.parsed.query)


def reorganize(ctx: Any) -> None:
    RouteLogic(ctx)._handle_learner_reorganize(ctx.parsed.query)


compute = _post("_handle_learner_compute")
learner_reset = _post("_handle_learner_reset")
analyze = _post("_handle_analyze")
event_score = _post("_handle_event_score")
pair_graph = _post("_handle_pair_graph")

ROUTES = (
    Route("GET", "/api/knowledge", knowledge),
    Route("GET", "/api/visualize/coordination", coordination),
    Route("GET", "/api/reorganize", reorganize),
    Route("POST", "/api/compute", compute),
    Route("POST", "/api/learner/reset", learner_reset),
    Route("POST", "/api/analyze", analyze, access="unlocked"),
    Route("POST", "/api/event_score", event_score),
    Route("POST", "/api/pair_graph", pair_graph, access="verified"),
)

