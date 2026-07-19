"""Public static files and exact GET utility routes."""
from __future__ import annotations

import urllib.parse
from pathlib import Path
from typing import Any, Callable

from hermes.app.routes.logic import RouteLogic
from hermes.app.routes.registry import Route


def _logic(method: str, argument: Callable[[Any], Any]) -> Callable[[Any], None]:
    def handle(ctx: Any) -> None:
        getattr(RouteLogic(ctx), method)(argument(ctx))
    return handle


def root(ctx: Any) -> None:
    ctx._send_file(ctx.web_root / "console.html")


def quickstart(ctx: Any) -> None:
    doc = ctx.app_dir / "QUICKSTART.md"
    if doc.is_file():
        ctx._send_json({"content": doc.read_text(encoding="utf-8")})
    else:
        ctx._send_json({"error": "quickstart not found"}, status=404)


def sample(ctx: Any) -> None:
    path = ctx.app_dir / "examples" / "All_Discussions.txt"
    if path.is_file():
        ctx._send_json({"name": "All_Discussions.txt (synthetic geometry)",
                        "text": path.read_text(encoding="utf-8")})
    else:
        ctx._send_json({"error": "sample not found"}, status=404)


def inputs(ctx: Any) -> None:
    files = []
    for tag, base, prefix in (("sample", ctx.app_dir / "examples", "examples"),
                              ("runtime", ctx.runtime / "input", "input")):
        if base.is_dir():
            for path in sorted(base.iterdir()):
                if path.is_file() and path.suffix.lower() in (".txt", ".md", ".csv") and not path.name.startswith("."):
                    files.append({"label": f"{path.name} ({tag})", "key": f"{prefix}/{path.name}"})
    ctx._send_json({"files": files})


fraction_render = _logic("_handle_fraction_frames", lambda ctx: ctx.raw_path)
fraction_compare = _logic("_handle_fraction_frames", lambda ctx: ctx.raw_path)


def _resolve_mount(ctx: Any, url_path: str) -> Path | None:
    # Pre-split semantics, preserved exactly: unquote before selecting the
    # mount, require a non-empty tail, and serve files only (no directory
    # index fallback — the web root resolver has none either).
    parts = urllib.parse.unquote(url_path.lstrip("/")).split("/", 1)
    if len(parts) < 2 or not parts[1]:
        return None
    base = ctx.static_mounts.get(parts[0])
    if base is None:
        return None
    target = (base / parts[1]).resolve()
    base_resolved = base.resolve()
    if not target.is_file():
        return None
    if target != base_resolved and base_resolved not in target.parents:
        return None
    return target


def _resolve_web(ctx: Any, url_path: str) -> Path | None:
    target = ctx.web_root / url_path.lstrip("/")
    if target.is_file() and target.resolve().is_relative_to(ctx.web_root.resolve()):
        return target
    return None


def resolve_static_file(ctx: Any, url_path: str) -> Path | None:
    """Resolve only the web root or a whitelisted mount, never their parents."""
    return _resolve_web(ctx, url_path) or _resolve_mount(ctx, url_path)


def static_fallback(ctx: Any) -> None:
    target = resolve_static_file(ctx, ctx.parsed.path)
    if target is not None:
        ctx._send_file(target)
        return
    ctx._send_json({"error": "not found"}, status=404)


ROUTES = (
    Route("GET", "/", root),
    Route("GET", "/api/quickstart", quickstart),
    Route("GET", "/api/sample", sample),
    Route("GET", "/api/inputs", inputs),
    Route("GET", "/api/fraction/render", fraction_render),
    Route("GET", "/api/fraction/compare", fraction_compare),
)
