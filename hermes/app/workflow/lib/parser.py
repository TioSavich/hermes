"""All_Discussions_*.txt parser.

The input is a single concatenated paste with sections separated by lines
beginning `Header:`. Each section contains the prompt (or its title) followed
by the raw Canvas discussion responses for that prompt.

We do two things deterministically:

1. Split on `Header:` lines into per-prompt sections.
2. Normalize each section's prompt name into a stable id (slug).

We do NOT try to parse threads or attribute authors deterministically. That
job is Gemma's, via `system_prompts/parse.md` — one API call per section.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path


@dataclass
class Section:
    raw_header: str            # the original `Header:` value (trimmed)
    prompt_id: str             # slugified id derived from the header
    body: str                  # everything after the header line, up to the next header


HEADER_RE = re.compile(r"(?im)^\s*Header\s*:\s*(.+?)\s*$")


def slugify(text: str) -> str:
    text = text.strip().lower()
    text = re.sub(r"[^a-z0-9]+", "_", text)
    return text.strip("_") or "untitled"


def split_sections(text: str) -> list[Section]:
    matches = list(HEADER_RE.finditer(text))
    if not matches:
        return []
    sections: list[Section] = []
    for i, m in enumerate(matches):
        body_start = m.end()
        body_end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        raw_header = m.group(1).strip()
        sections.append(Section(
            raw_header=raw_header,
            prompt_id=slugify(raw_header),
            body=text[body_start:body_end].strip(),
        ))
    return sections


def read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    out = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            out.append(json.loads(line))
        except json.JSONDecodeError:
            continue
    return out


def append_jsonl(path: Path, record: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(record, ensure_ascii=True) + "\n")


def find_trailing_json_object(text: str) -> dict | None:
    end = text.rfind("}")
    if end == -1:
        return None
    depth = 0
    start = -1
    for i in range(end, -1, -1):
        c = text[i]
        if c == "}":
            depth += 1
        elif c == "{":
            depth -= 1
            if depth == 0:
                start = i
                break
    if start == -1:
        return None
    try:
        return json.loads(text[start:end + 1])
    except json.JSONDecodeError:
        return None


def parse_json_or_die(reply: str, *, what: str) -> dict:
    text = reply.strip()
    fenced = re.findall(r"```(?:json)?\s*(\{.*?\})\s*```", text, flags=re.DOTALL)
    for chunk in reversed(fenced):
        try:
            return json.loads(chunk)
        except json.JSONDecodeError:
            continue
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass
    obj = find_trailing_json_object(text)
    if obj is not None:
        return obj
    head = text[:300].replace("\n", "\\n")
    raise ValueError(f"could not parse JSON from {what}; first 300 chars: {head!r}")


def extract_jsonline_loose(reply: str) -> dict | None:
    for line in reversed(reply.strip().splitlines()):
        line = line.strip()
        if line.startswith("{") and line.endswith("}"):
            try:
                return json.loads(line)
            except json.JSONDecodeError:
                continue
    return None
