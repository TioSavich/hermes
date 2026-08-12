#!/usr/bin/env python3
"""Shared acceptance and source-mapping contract for vision statements."""

from __future__ import annotations

import re


def normalized_contiguous_span(statement: str, source: str) -> tuple[int, int] | None:
    """Locate an exact statement after collapsing each whitespace run."""
    words = statement.split()
    if not words:
        return None
    match = re.search(r"\s+".join(re.escape(word) for word in words), source)
    return match.span() if match is not None else None
