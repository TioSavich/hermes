"""Text boundary shared by sidekick dataset builders before tokenization."""
from __future__ import annotations

import re
from typing import Any


DISPLAY_MATH_MARKER_RE = re.compile(
    r"(?<!\\)\$([^$\n]*[+\-−×÷=<>/\\][^$\n]*)\$"
)


def cull_display_math_markers(value: Any) -> Any:
    """Remove display-only math delimiters before a value reaches training."""
    if isinstance(value, str):
        return DISPLAY_MATH_MARKER_RE.sub(lambda match: match.group(1), value)
    if isinstance(value, list):
        return [cull_display_math_markers(item) for item in value]
    if isinstance(value, tuple):
        return tuple(cull_display_math_markers(item) for item in value)
    if isinstance(value, dict):
        return {key: cull_display_math_markers(item) for key, item in value.items()}
    return value
