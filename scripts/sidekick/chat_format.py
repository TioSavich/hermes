#!/usr/bin/env python3
"""Render Hermes tool conversations in gemma-4's own chat format.

The renderer runs the checkpoint's shipped `chat_template.jinja` against its
shipped `tokenizer.json`, so what this module reports is what the model would
read, not a reconstruction of it. Both files come from the ungated
`google/gemma-4-E2B-it` repository and live outside the tree; the loader
refuses rather than guesses when they are absent.

Two facts about the format govern everything downstream and are asserted here
rather than trusted: the tool markers are single tokens in the base vocabulary,
and a tool response renders INSIDE the model's own turn. The second is why
`supervision.py` exists.
"""
from __future__ import annotations

import json
import os
import random
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Sequence

import jinja2
from tokenizers import Tokenizer

REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_ASSET_DIR = REPO_ROOT / "hermes" / "app" / "runtime" / "experiments" / "sidekick" / "gemma4-e2b-assets"
ASSET_ENV = "SIDEKICK_GEMMA_ASSETS"
ASSET_FILES = ("chat_template.jinja", "tokenizer.json")

# Marker names as the template writes them. Ids are read from the live
# tokenizer at load time; the constants below are what the loader checks
# against, so a checkpoint change fails loudly instead of shifting the mask.
EXPECTED_MARKER_IDS = {
    "<|tool>": 46,
    "<tool|>": 47,
    "<|tool_call>": 48,
    "<tool_call|>": 49,
    "<|tool_response>": 50,
    "<tool_response|>": 51,
    "<|\"|>": 52,
    "<|channel>": 100,
    "<|turn>": 105,
    "<turn|>": 106,
}
BOS = "<bos>"
EOS = "<eos>"


class AssetsMissing(RuntimeError):
    """The checkpoint's own template and vocabulary were not found."""


def asset_dir() -> Path:
    override = os.environ.get(ASSET_ENV)
    return Path(override) if override else DEFAULT_ASSET_DIR


def _load_assets() -> tuple[str, Tokenizer]:
    directory = asset_dir()
    missing = [name for name in ASSET_FILES if not (directory / name).is_file()]
    if missing:
        raise AssetsMissing(
            f"{', '.join(missing)} not found under {directory}. "
            f"Copy them from the google/gemma-4-E2B-it snapshot (ungated, Apache-2.0) "
            f"or point {ASSET_ENV} at a directory that holds them."
        )
    template_text = (directory / "chat_template.jinja").read_text(encoding="utf-8")
    tokenizer = Tokenizer.from_file(str(directory / "tokenizer.json"))
    return template_text, tokenizer


@dataclass(frozen=True)
class Rendered:
    """One conversation as text and as token ids, with its marker positions."""

    text: str
    ids: list[int]

    def spans(self, open_id: int, close_id: int) -> list[tuple[int, int]]:
        """Index pairs for each open/close marker pair, inclusive of both."""
        pairs: list[tuple[int, int]] = []
        open_at: int | None = None
        for index, token in enumerate(self.ids):
            if token == open_id:
                open_at = index
            elif token == close_id and open_at is not None:
                pairs.append((open_at, index))
                open_at = None
        if open_at is not None:
            pairs.append((open_at, len(self.ids) - 1))
        return pairs


class GemmaChatFormat:
    """The checkpoint's template and vocabulary, loaded once."""

    def __init__(self) -> None:
        template_text, tokenizer = _load_assets()
        environment = jinja2.Environment(
            trim_blocks=False, lstrip_blocks=False, keep_trailing_newline=True
        )
        environment.globals["raise_exception"] = _raise
        self._template = environment.from_string(template_text)
        self._tokenizer = tokenizer
        self.marker_ids = {name: self._single_id(name) for name in EXPECTED_MARKER_IDS}
        drifted = {
            name: (self.marker_ids[name], expected)
            for name, expected in EXPECTED_MARKER_IDS.items()
            if self.marker_ids[name] != expected
        }
        if drifted:
            raise AssetsMissing(
                "The loaded vocabulary disagrees with the recorded marker ids "
                f"(name: got, expected) {drifted}. The masking specification is "
                "written against those ids; re-verify before training."
            )

    def _single_id(self, marker: str) -> int:
        encoded = self._tokenizer.encode(marker, add_special_tokens=False).ids
        if len(encoded) != 1:
            raise AssetsMissing(
                f"{marker} encodes to {len(encoded)} tokens in this vocabulary, "
                "so it is not the single marker the format assumes."
            )
        return encoded[0]

    def render(
        self,
        messages: Sequence[dict[str, Any]],
        tools: Sequence[dict[str, Any]] | None = None,
        *,
        add_generation_prompt: bool = False,
    ) -> Rendered:
        text = self._template.render(
            messages=list(messages),
            tools=[wrap_tool(tool) for tool in tools] if tools else None,
            bos_token=BOS,
            add_generation_prompt=add_generation_prompt,
            enable_thinking=False,
            preserve_thinking=False,
        )
        return Rendered(text=text, ids=self.encode(text))

    def encode(self, text: str) -> list[int]:
        return self._tokenizer.encode(text, add_special_tokens=False).ids

    def count(self, text: str) -> int:
        return len(self.encode(text))

    def menu_tokens(self, tools: Sequence[dict[str, Any]]) -> int:
        """Tokens the declared menu costs, over an empty turn."""
        with_menu = self.render([], tools).ids
        without = self.render([], None).ids
        return len(with_menu) - len(without)


def _raise(message: str) -> None:
    raise ValueError(message)


def wrap_tool(tool: dict[str, Any]) -> dict[str, Any]:
    """Present one MCP tool the way the template reads a function declaration."""
    if tool.get("type") == "function" and "function" in tool:
        return tool
    return {
        "type": "function",
        "function": {
            "name": tool["name"],
            "description": tool["description"],
            "parameters": tool.get("inputSchema") or tool.get("parameters") or {},
        },
    }


def openai_tools(tools: Iterable[dict[str, Any]]) -> list[dict[str, Any]]:
    """The same wrapping, for an OpenAI-compatible or Ollama endpoint."""
    return [wrap_tool(tool) for tool in tools]


def sample_menu(
    tools: Sequence[dict[str, Any]],
    required: Sequence[str],
    size: int,
    rng: random.Random,
) -> list[dict[str, Any]]:
    """A menu of `size` declarations holding every required tool.

    Menus vary per example so position cannot be memorized and so a held-out
    tool can appear at evaluation without having been declared in training.
    """
    by_name = {tool["name"]: tool for tool in tools}
    unknown = [name for name in required if name not in by_name]
    if unknown:
        raise KeyError(f"not on the declared surface: {unknown}")
    chosen = [by_name[name] for name in dict.fromkeys(required)]
    if size < len(chosen):
        raise ValueError(f"menu size {size} cannot hold {len(chosen)} required tools")
    remaining = [tool for tool in tools if tool["name"] not in {t["name"] for t in chosen}]
    chosen.extend(rng.sample(remaining, min(size - len(chosen), len(remaining))))
    rng.shuffle(chosen)
    return chosen


def conversation(
    user_turn: str,
    calls: Sequence[dict[str, Any]],
    reply: str,
) -> list[dict[str, Any]]:
    """One row's messages in the OpenAI shape the template consumes.

    Each call carries its own executed response, and the template inlines that
    response inside the model turn. The nesting is the format's, not ours.
    """
    messages: list[dict[str, Any]] = [{"role": "user", "content": user_turn}]
    if calls:
        tool_calls = [
            {
                "id": f"call_{index}",
                "type": "function",
                "function": {"name": call["name"], "arguments": call["arguments"]},
            }
            for index, call in enumerate(calls)
        ]
        messages.append({"role": "assistant", "content": "", "tool_calls": tool_calls})
        for index, call in enumerate(calls):
            messages.append(
                {
                    "role": "tool",
                    "tool_call_id": f"call_{index}",
                    "name": call["name"],
                    "content": json.dumps(call["response"], ensure_ascii=False, sort_keys=True),
                }
            )
    messages.append({"role": "assistant", "content": reply})
    return messages


def main() -> int:
    """Report what the live template and vocabulary do with the core surface."""
    import sys

    sys.path.insert(0, str(REPO_ROOT))
    from hermes.mcp.server import HermesMCPServer

    chat = GemmaChatFormat()
    server = HermesMCPServer("core", REPO_ROOT)
    tools = list(server._public_tools)
    per_tool = sorted(
        ((chat.menu_tokens([tool]), tool["name"]) for tool in tools), reverse=True
    )
    print(f"declared tools: {len(tools)}")
    print(f"empty turn: {len(chat.render([], None).ids)} tokens")
    print(f"full menu: {chat.menu_tokens(tools)} tokens")
    rng = random.Random(0)
    print(f"sampled menu of 8: {chat.menu_tokens(sample_menu(tools, ['strategy_recognize'], 8, rng))} tokens")
    print(f"most costly: {per_tool[0][1]} {per_tool[0][0]}")
    print(f"median: {per_tool[len(per_tool) // 2][1]} {per_tool[len(per_tool) // 2][0]}")
    for count, name in per_tool[:5]:
        print(f"  {count:5d}  {name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
