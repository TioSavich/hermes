#!/usr/bin/env python3
"""Check all required prompts, verbatim moved bytes, and named startup failure."""
from __future__ import annotations

import hashlib
import shutil
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from hermes.app.system_prompts import (  # noqa: E402
    REQUIRED_SYSTEM_PROMPTS,
    RequiredSystemPromptError,
    load_required_system_prompts,
)

MOVED_HASHES = {
    "chat.md": "ea0c0ef36632bc774ed5346906839a0f8dda23f17473a1168f4f1ec18ccd3444",
    "help.md": "562821bbc97b693e9f0e820f18349ae7b7e6d682903e157ce62d1abe8e79951d",
    "pml_reader.md": "c2cc958f67702b16bb95b5ebf203637d048636ba36ceaf08c3040831fbcb0152",
}


def main() -> int:
    prompt_dir = ROOT / "hermes/app/system_prompts"
    prompts = load_required_system_prompts(prompt_dir)
    if tuple(prompts) != REQUIRED_SYSTEM_PROMPTS:
        print("required prompt inventory/order mismatch", file=sys.stderr)
        return 1
    for name, expected in MOVED_HASHES.items():
        actual = hashlib.sha256((prompt_dir / name).read_bytes()).hexdigest()
        if actual != expected:
            print(f"{name} is not the verbatim embedded prompt ({actual})", file=sys.stderr)
            return 1
    with tempfile.TemporaryDirectory() as temp:
        copy = Path(temp) / "system_prompts"
        shutil.copytree(prompt_dir, copy)
        (copy / "chat.md").unlink()
        try:
            load_required_system_prompts(copy)
        except RequiredSystemPromptError as exc:
            if "chat.md" not in str(exc):
                print(f"startup error did not name missing prompt: {exc}", file=sys.stderr)
                return 1
        else:
            print("missing required prompt did not fail startup loading", file=sys.stderr)
            return 1
    print(f"required system prompts: {len(prompts)} present; verbatim and missing-file checks: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
