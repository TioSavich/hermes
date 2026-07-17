"""Resolve the validated Hermes repository root."""

from __future__ import annotations

import os
from pathlib import Path


class HermesRootError(RuntimeError):
    """Raised when a candidate does not contain the Hermes Prolog runtime."""


def resolve_hermes_root(root: Path | str | None = None) -> Path:
    """Return the Hermes root using explicit, environment, then installed paths."""
    if root is not None:
        candidate = Path(root)
    else:
        env_root = os.environ.get("UMEDCTA_ROOT", "").strip()
        candidate = Path(env_root) if env_root else Path(__file__).parents[2]

    candidate = candidate.expanduser().resolve()
    required = ("hermes_worker.pl", "paths.pl")
    missing = [name for name in required if not (candidate / name).is_file()]
    if missing:
        names = ", ".join(missing)
        raise HermesRootError(f"invalid Hermes root {candidate}: missing {names}")
    return candidate
