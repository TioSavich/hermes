"""Load the generated lesson field-context cache once per server process."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any


def load_field_context_cache(repo_root: Path) -> dict[str, dict[str, Any]]:
    path = repo_root / "curriculum/im/generated/field_context_cache.json"
    try:
        artifact = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    contexts = artifact.get("field_contexts") if isinstance(artifact, dict) else None
    if not isinstance(contexts, dict):
        return {}
    return {
        code: context
        for code, context in contexts.items()
        if isinstance(code, str) and isinstance(context, dict)
    }
