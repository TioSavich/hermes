"""Immutable route records and exact-method dispatch."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Callable, Literal, TYPE_CHECKING

if TYPE_CHECKING:
    from hermes.app.server import RequestContext

Access = Literal["public", "unlocked", "verified"]
Handler = Callable[["RequestContext"], None]


@dataclass(frozen=True, slots=True)
class Route:
    method: str
    path: str
    handler: Handler
    access: Access = "public"

    @property
    def module(self) -> str:
        return self.handler.__module__.removeprefix("hermes.app.routes.")


class DuplicateRouteError(ValueError):
    """Raised when two handlers claim the same method and exact path."""


class Router:
    def __init__(self, routes: tuple[Route, ...], static_fallback: Handler) -> None:
        table: dict[tuple[str, str], Route] = {}
        for route in routes:
            key = (route.method, route.path)
            if key in table:
                raise DuplicateRouteError(
                    f"duplicate route: {route.method} {route.path} "
                    f"({table[key].module}, {route.module})"
                )
            table[key] = route
        self._routes = tuple(routes)
        self._table = table
        self._static_fallback = static_fallback

    @property
    def routes(self) -> tuple[Route, ...]:
        return self._routes

    def lookup(self, method: str, path: str) -> Route | None:
        return self._table.get((method, path))

    def dispatch(self, context: "RequestContext") -> None:
        route = self.lookup(context.method, context.route_path)
        if route is None:
            if context.method == "GET":
                self._static_fallback(context)
            else:
                context._send_json({"error": "not found"}, status=404)
            return
        if route.access == "unlocked" and not context._require_unlocked():
            return
        if route.access == "verified" and not context._gate_or_423(route.path.rsplit("/", 1)[-1]):
            return
        route.handler(context)


def build_router() -> Router:
    from hermes.app.routes import analysis, gate, llm, monitoring, runtime, static, worker, workflow

    routes = (
        *static.ROUTES,
        *gate.ROUTES,
        *runtime.ROUTES,
        *analysis.ROUTES,
        *llm.ROUTES,
        *monitoring.ROUTES,
        *worker.ROUTES,
        *workflow.ROUTES,
    )
    return Router(routes, static.static_fallback)
