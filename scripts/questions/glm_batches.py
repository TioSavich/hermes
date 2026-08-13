#!/usr/bin/env python3
"""Batch builder and response contract for the glm-5.2 linking pass.

The pipeline decides everything structural. The model does one job: given a
question and a menu carved from Hermes structure, select links. It never
invents a pattern id, a machine name, or a move vocabulary, because a generic
choice set carries no signal — the fact-extraction pilot measured what that
costs. Move type and effect are asked for separately so the design's
asymmetry conjecture can fail against the corpus rather than by construction.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

SYSTEM_PROMPT = (
    "You link teacher questions from a mathematics curriculum to task regions and "
    "machines. You choose only from the menus given to you. You never invent a "
    "pattern id, a machine name, a move type, or an effect. You answer with one "
    "JSON object and nothing else."
)

CONTRACT = """Return one JSON object, no prose around it:

{"links": [
  {"id": "<the question id exactly as given>",
   "pattern_ids": ["<a pattern id from this question's lesson, or omit the key>"],
   "machine": "<a machine name from this lesson's menu, or null>",
   "context": "productive" | "misconception" | "none",
   "move_type": "assessing" | "advancing" | "general",
   "effect": "narrows" | "raises" | "articulates" | "none",
   "effect_target": "<a machine name, a pattern id, or null>",
   "slot_map": {"<numeral in the question>": "<parameter name>"},
   "rationale": "<one clause>"}
]}

Rules you must follow:
- One object per question given, in the order given, using the id verbatim.
- move_type is "general" when the question would be licensed at almost any
  task in the lesson and carries no signal about this region. Say so; a
  general move is a real move, not a failure.
- effect names what the question does: "narrows" cuts down which machine the
  student is running, "raises" moves the student to a harder region or a new
  representation demand, "articulates" makes the region's constraint said
  aloud by comparing settled approaches. Judge the effect on its own; do not
  derive it from move_type.
- pattern_ids and machine must come from this question's own lesson block.
- slot_map binds only numerals that appear in the question text.
"""


def pattern_line(pattern_id: str, entry: dict) -> str:
    # Guards that only restate a digit count are dropped from the display; the
    # stored row keeps them. Reasoning cost here is paid per decision, so the
    # menu says what separates the regions and nothing more.
    guards = ", ".join(
        guard for guard in entry["constraints"] if not guard.startswith("digit(")
    )
    witness = ", ".join(str(value) for value in entry["witness"])
    return (
        f"    - {pattern_id}: {entry['family']}({', '.join(entry['parameters'])}), "
        f"guards [{guards}], example {entry['family']}({witness}), "
        f"machine {entry['witness_machine']}"
    )


def lesson_block(lesson: str, patterns: dict, menu: dict, statements: list[str],
                 registry_family_of) -> str:
    entries = [item["pattern_id"] for item in patterns["lesson_patterns"].get(lesson, [])]
    lines = [f"LESSON {lesson}"]
    if statements:
        lines.append("  curriculum task statements:")
        for statement in statements[:2]:
            lines.append(f"    - {statement[:200]}")
    lines.append("  task patterns computed for this lesson:")
    for pattern_id in entries:
        lines.append(pattern_line(pattern_id, patterns["patterns"][pattern_id]))
    families = sorted({
        registry_family_of(patterns["patterns"][pattern_id]["witness_machine"], menu)
        for pattern_id in entries
    })
    for family in families:
        kinds = menu.get(family, [])
        productive = [item["kind"] for item in kinds if item["polarity"] == "productive"][:8]
        deformation = [item["kind"] for item in kinds if item["polarity"] == "deformation"][:8]
        lines.append(f"  machines in family {family}:")
        lines.append(f"    productive: {', '.join(productive) or 'none published'}")
        lines.append(f"    misconception: {', '.join(deformation) or 'none published'}")
    return "\n".join(lines)


def build_batch(sentences: list, patterns: dict, menu: dict, statements_by_lesson: dict,
                registry_family_of) -> list[dict]:
    lessons = sorted({sentence.lesson for sentence in sentences})
    blocks = [
        lesson_block(lesson, patterns, menu, statements_by_lesson.get(lesson, []), registry_family_of)
        for lesson in lessons
    ]
    question_lines = ["QUESTIONS"]
    for sentence in sentences:
        location = sentence.activity_location
        question_lines.append(
            f'  {sentence.identity} [lesson {sentence.lesson}] [moment: {location}] "{sentence.text}"'
        )
    user = "\n\n".join(blocks + ["\n".join(question_lines), CONTRACT])
    return [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": user},
    ]


JSON_OBJECT = re.compile(r"\{.*\}", re.S)


def parse_reply(content: str) -> list[dict] | None:
    """Strict-JSON reading of a reply the transport already called ok."""
    text = content.strip()
    if text.startswith("```"):
        text = re.sub(r"^```[a-z]*\n?", "", text)
        text = re.sub(r"\n?```$", "", text.strip())
    match = JSON_OBJECT.search(text)
    if not match:
        return None
    try:
        payload = json.loads(match.group(0))
    except json.JSONDecodeError:
        return None
    links = payload.get("links")
    if not isinstance(links, list):
        return None
    return [item for item in links if isinstance(item, dict) and item.get("id")]
