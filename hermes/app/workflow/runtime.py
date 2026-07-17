"""Request-local paths used by workflow command modules."""
from __future__ import annotations

import os
from pathlib import Path
from typing import Any

from .service import current_context


class ContextPath(os.PathLike[str]):
    """A Path-like value resolved from the active WorkflowContext on use."""

    __slots__ = ("_base", "_parts")

    def __init__(self, base: str, parts: tuple[str, ...] = ()) -> None:
        self._base = base
        self._parts = parts

    def _path(self) -> Path:
        context = current_context()
        base = context.pack_root if self._base == "pack" else context.pack_root / "runtime"
        return base.joinpath(*self._parts)

    def __fspath__(self) -> str:
        return os.fspath(self._path())

    def __str__(self) -> str:
        return str(self._path())

    def __repr__(self) -> str:
        return f"ContextPath({self._base!r}, {self._parts!r})"

    def __truediv__(self, value: os.PathLike[str] | str) -> "ContextPath":
        return ContextPath(self._base, (*self._parts, os.fspath(value)))

    def __getattr__(self, name: str) -> Any:
        return getattr(self._path(), name)


HERE = ContextPath("pack")
DATA = ContextPath("data")
