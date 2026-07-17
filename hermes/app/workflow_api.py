"""Compatibility wrapper for callers migrating to the workflow service."""
from __future__ import annotations

from pathlib import Path

from hermes.app import llm
from hermes.app.workflow import service

WORKFLOW_DIR = Path(__file__).resolve().parent / "workflow"
COMMANDS = set(service.COMMANDS)


def build_argv(command: str, payload: dict) -> list[str]:
    return [
        str(WORKFLOW_DIR / f"{command}.py"),
        *service.build_argv(command, payload),
    ]


def run(command: str, payload: dict, pack_root: Path) -> dict:
    """Execute in process while preserving the legacy result dictionary.

    Command-specific model/worker timeouts are authoritative; this wrapper
    takes no timeout of its own.
    """
    local_worker = service.LocalWorker()
    context = service.WorkflowContext(
        Path(pack_root).resolve(), llm, local_worker.request, lambda _text: None
    )
    try:
        return service.run(command, payload, context).as_dict()
    finally:
        local_worker.close()
