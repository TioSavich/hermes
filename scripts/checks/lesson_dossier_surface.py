#!/usr/bin/env python3
"""Check the lesson dossier's worker, route, page, and MCP wiring."""
from __future__ import annotations

import sys
from pathlib import Path
from types import SimpleNamespace


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from hermes.app.routes import monitoring  # noqa: E402
from hermes.app.routes.registry import build_router  # noqa: E402


class StubWorker:
    timeout = 90.0

    def __init__(self) -> None:
        self.calls: list[tuple[str, dict[str, str]]] = []

    def request(self, operation: str, **payload: str) -> dict[str, str]:
        self.calls.append((operation, payload))
        return {"lesson_code": payload["lesson_code"], "status": "content_found"}


class StubContext:
    def __init__(self) -> None:
        self.payload = {"lesson_code": "IM-G1-U1-L1"}
        self.worker = StubWorker()
        self.services = SimpleNamespace(monitoring_export_worker=self.worker)
        self.responses: list[tuple[dict[str, object], int]] = []

    def _send_json(self, value: dict[str, object], status: int = 200) -> None:
        self.responses.append((value, status))


def require(path: Path, *needles: str) -> None:
    source = path.read_text(encoding="utf-8")
    missing = [needle for needle in needles if needle not in source]
    if missing:
        raise AssertionError(f"{path.relative_to(ROOT)} omits {missing}")


def main() -> int:
    router = build_router()
    if router.lookup("GET", "/lesson") is None:
        raise AssertionError("GET /lesson is not registered")
    if router.lookup("POST", "/api/lesson_dossier") is None:
        raise AssertionError("POST /api/lesson_dossier is not registered")

    context = StubContext()
    monitoring.lesson_dossier(context)
    assert context.worker.calls == [
        ("lesson_dossier", {"lesson_code": "IM-G1-U1-L1"})
    ]
    assert context.responses == [
        ({"ok": True, "result": {
            "lesson_code": "IM-G1-U1-L1", "status": "content_found"
        }}, 200)
    ]

    require(
        ROOT / "hermes" / "dispatch_spec.pl",
        "dispatch_spec(lesson_dossier,",
        "call(user:lesson_dossier_dict, [lesson_code, out(dict)])",
    )
    require(
        ROOT / "hermes" / "app" / "web" / "lesson.html",
        "hermes-shell.js",
        'fetch("/api/lesson_dossier"',
        'params.get("code")',
    )
    require(
        ROOT / "hermes" / "mcp" / "server.py",
        '"lesson_dossier": "lesson_dossier"',
    )
    require(
        ROOT / "hermes" / "mcp" / "selfcheck.py",
        'tool="lesson_dossier"',
    )
    print("PASS lesson dossier worker, route, page, and MCP wiring")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
