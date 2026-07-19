"""Required UTF-8 system prompt loading."""
from __future__ import annotations

from pathlib import Path

REQUIRED_SYSTEM_PROMPTS = (
    "chat.md",
    "help.md",
    "pml_reader.md",
    "content_consolidate.md",
    "content_per_file.md",
    "draft.md",
    "grade.md",
    "parse.md",
    "profile.md",
    "score.md",
    "transcribe.md",
    "transcribe_timed.md",
)


class RequiredSystemPromptError(RuntimeError):
    """A required prompt file is missing or cannot be decoded as UTF-8."""


def load_required_system_prompts(directory: Path | None = None) -> dict[str, str]:
    root = directory or Path(__file__).resolve().parent
    prompts: dict[str, str] = {}
    for name in REQUIRED_SYSTEM_PROMPTS:
        path = root / name
        try:
            prompts[name] = path.read_text(encoding="utf-8")
        except (OSError, UnicodeError) as exc:
            raise RequiredSystemPromptError(
                f"required system prompt unavailable: {name} ({path}): {exc}"
            ) from exc
    return prompts
