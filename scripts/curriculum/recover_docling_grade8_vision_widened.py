#!/usr/bin/env python3
"""Recover Grade 8 printed mathematics and gridded figure referents by vision.

Each prompt-versioned asset call carries the partial task statement, its
activity from the legible Markdown store, and the existing picture description.
Printed mathematics follows the expression-level recovery contract. Structured
figure readings must pass deterministic schema, coordinate, label, description,
and JSON-to-SVG rendering checks before their referents enter a task statement.
All other results enter a named uncertain residue; this lane has no human queue.

``--dry-run`` and ``--self-check`` do not load the model client or use network.
The campaign counter retains every prior prompt version's provider attempts.
"""

from __future__ import annotations

import argparse
from collections import Counter
from difflib import SequenceMatcher
from functools import lru_cache
import hashlib
import json
import math
from pathlib import Path
import re
import struct
import subprocess
import sys
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.curriculum import extract_docling_grade as extraction  # noqa: E402
from scripts.curriculum import recover_docling_grade8 as recovery  # noqa: E402
from scripts.curriculum import recover_docling_grade8_vision as narrow  # noqa: E402
from scripts.curriculum import vision_pass  # noqa: E402
from scripts.curriculum import vision_statement_contract  # noqa: E402


MODEL = narrow.MODEL
MAX_TOKENS = narrow.MAX_TOKENS
HARD_CALL_BUDGET = narrow.HARD_CALL_BUDGET
DEFAULT_OUTPUT = recovery.DEFAULT_RECOVERY_DIR / "vision_widened"
DEFAULT_LIMIT = 10
NARROW_RECOVERED_ROW = ("IM-G8-U2-L12", "student_task_statement(1)")
LEGIBLE_STORE = Path("/Users/tio/Documents/GitHub/Prolog/IM-Curriculum/Markdown")
GRAPHER = ROOT / "hermes/web/coordinate-plane/grapher.js"
PROMPT_VERSION = "g8_widened_context_figure_reading_v4"
RESULT_CLASSES = {
    "task_statement",
    "printed_math",
    "figure_reading",
    "not_gridded",
}
EXPRESSION_BLOCKERS = {
    "expression_missing_from_markdown",
    "expression_missing_without_visual",
}
MATH_TOKEN_RE = re.compile(
    r"(?<!\d)-?\d+(?:[.,]\d+)*(?!\d)|"
    r"(?<![A-Za-z])[A-Zb-hj-z](?![A-Za-z])"
)
POINT_LABEL_RE = re.compile(
    r"\b(?i:point|vertex|center)\s+([A-Z](?:['′])?)\b|"
    r"\b(?i:triangle|quadrilateral)\s+([A-Z]{3,4})\b"
)
COORDINATE_RE = re.compile(
    r"\b([A-Z](?:['′])?)\s*(?:is|at|=|:)?\s*"
    r"\(\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\)"
)
ACTIVITY_START_RE = re.compile(r"^#{1,6} Activity Narrative\s*$")
ACTIVITY_END_RE = re.compile(
    r"^#{1,6} (?:Activity Synthesis|Lesson Synthesis|Lesson \d+ Summary)\s*$"
)
MAX_ACTIVITY_CHARS = 12_000
MAX_COORDINATE = 1000
GRID_DENOMINATOR = 4
FURNITURE_LESSON_THRESHOLD = 5
MIN_IMAGE_WIDTH = 32
MIN_IMAGE_HEIGHT = 32
SYSTEM_PROMPT = (
    "Read the attached curriculum figure using only the image and supplied "
    "lesson context. Return raw JSON only. Copy printed task text and "
    "mathematics verbatim. For a readable coordinate or regular grid, record "
    "the figure's named points, shapes, and lines with numeric grid "
    "coordinates. Do not infer missing coordinates."
)
USER_PROMPT_TEMPLATE = """Return exactly one JSON object with these keys:
{{"class":"task_statement | printed_math | figure_reading | not_gridded",
"certainty":"certain | uncertain",
"printed_text":"verbatim printed task text or mathematics, or empty",
"points":[{{"label":"A","x":0,"y":0}}],
"shapes":[{{"label":"triangle ABC","kind":"triangle | quadrilateral | polygon","vertices":["A","B","C"],"parameters":{{}}}}],
"lines":[{{"label":"line l","kind":"line | segment | ray | axis","through":["A","B"]}}]}}

Use task_statement only for a complete printed student task statement.
Use printed_math for task-bearing printed expressions or equations.
Use figure_reading when a grid supplies numeric coordinates sufficient to
redraw the figure. Include every readable named point and connect shapes and
lines only through listed point labels. When separate panels repeat a point
label, qualify it as "Figure 1:A", "Figure 2:A", and so on. Diagram labels
alone belong in the structured arrays, not printed_text.
Use not_gridded when the figure has no readable coordinate structure. Empty
arrays are required for not_gridded. When any reading is uncertain, report
certainty uncertain rather than filling a gap.

Partial task statement:
<partial_statement>{partial_statement}</partial_statement>

Surrounding activity from the legible Markdown store:
<activity source="{activity_source}">{activity_text}</activity>

Existing picture description (machine-generated, corroborative only):
<picture_description>{description}</picture_description>
"""
PROMPT_SHA256 = hashlib.sha256(
    (SYSTEM_PROMPT + "\0" + USER_PROMPT_TEMPLATE).encode()
).hexdigest()


def _normalize(value: str) -> str:
    return " ".join(value.split())


def _sha256_text(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()


def _row_id(lesson: str, position: str) -> str:
    return f"{lesson}:{position}"


def _call_id(lesson: str, position: str, asset: str) -> str:
    stable = "\0".join([lesson, position, asset, MODEL, PROMPT_VERSION])
    return "g8vw_" + hashlib.sha256(stable.encode()).hexdigest()[:20]


def _asset_digest(asset: str) -> str:
    match = re.search(r"_([0-9a-f]{64})\.[A-Za-z0-9]+$", asset)
    if match is None:
        raise ValueError(f"image asset has no digest: {asset}")
    return match.group(1)


def _png_dimensions(path: Path) -> tuple[int, int]:
    header = path.read_bytes()[:24]
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"image is not a readable PNG: {path}")
    return struct.unpack(">II", header[16:24])


def _furniture_reasons(width: int, height: int, lesson_count: int) -> list[str]:
    reasons = []
    if lesson_count >= FURNITURE_LESSON_THRESHOLD:
        reasons.append(f"digest_recurs_across_{lesson_count}_lessons")
    if width < MIN_IMAGE_WIDTH or height < MIN_IMAGE_HEIGHT:
        reasons.append(f"below_{MIN_IMAGE_WIDTH}x{MIN_IMAGE_HEIGHT}_size_floor")
    return reasons


def _lesson_key(lesson: str) -> tuple[int, int, int]:
    match = re.fullmatch(r"IM-G8-U(\d+)-L(\d+)", lesson)
    if match is None:
        raise ValueError(f"invalid Grade 8 lesson id: {lesson}")
    return 8, int(match.group(1)), int(match.group(2))


@lru_cache(maxsize=None)
def _legible_guide(lesson: str) -> tuple[Path, tuple[str, ...], frozenset[int]]:
    grade, unit, number = _lesson_key(lesson)
    path = LEGIBLE_STORE / f"Grade{grade}" / f"U{unit}-L{number}" / "guide.md"
    captions = path.with_name("captions.md")
    if not path.is_file() or not captions.is_file():
        raise ValueError(f"legible Markdown guide or captions are absent: {path}")
    lines = path.read_text(encoding="utf-8").splitlines()
    excluded = {
        index for index, line in enumerate(lines) if line.startswith("![Image](")
    }
    for match in vision_pass.PICTURE_DESCRIPTION_RE.finditer(
        captions.read_text(encoding="utf-8")
    ):
        description_lines = match.group(2).splitlines()
        found = next(
            (
                index
                for index in range(len(lines) - len(description_lines) + 1)
                if not any(
                    candidate in excluded
                    for candidate in range(index, index + len(description_lines))
                )
                and lines[index : index + len(description_lines)] == description_lines
            ),
            None,
        )
        if found is None:
            raise ValueError(f"picture description does not resolve in {path}")
        excluded.update(range(found, found + len(description_lines)))
    return path, tuple(lines), frozenset(excluded)


def _activity_context(lesson: str, line_start: int) -> dict[str, Any]:
    path, stored_lines, excluded = _legible_guide(lesson)
    lines = list(stored_lines)
    anchor = min(max(line_start - 1, 0), len(lines) - 1)
    start = next(
        (
            index
            for index in range(anchor, -1, -1)
            if ACTIVITY_START_RE.fullmatch(lines[index])
        ),
        max(0, anchor - 80),
    )
    end = next(
        (
            index
            for index in range(anchor + 1, len(lines))
            if ACTIVITY_END_RE.fullmatch(lines[index])
        ),
        min(len(lines), anchor + 120),
    )
    text = "\n".join(
        line
        for index, line in enumerate(lines[start:end], start)
        if index not in excluded
    ).strip()
    if len(text) > MAX_ACTIVITY_CHARS:
        text = text[:MAX_ACTIVITY_CHARS] + "\n[activity context truncated]"
    return {
        "path": str(path),
        "line_start": start + 1,
        "line_end": end,
        "sha256": _sha256_text(text),
        "text": text,
    }


def _messages(
    asset: Path, row: dict[str, Any], visual: dict[str, Any]
) -> list[dict[str, Any]]:
    context = row["activity_context"]
    prompt = USER_PROMPT_TEMPLATE.format(
        partial_statement=row["original_excerpt"],
        activity_source=f"{context['path']}:{context['line_start']}",
        activity_text=context["text"],
        description=visual["description"],
    )
    return [
        {"role": "system", "content": SYSTEM_PROMPT},
        {
            "role": "user",
            "content": [
                {"type": "text", "text": prompt},
                {
                    "type": "image_url",
                    "image_url": {"url": vision_pass.image_data_url(asset)},
                },
            ],
        },
    ]


def _assert_current_messages(messages: list[dict[str, Any]]) -> None:
    if (
        len(messages) != 2
        or messages[0] != {"role": "system", "content": SYSTEM_PROMPT}
        or messages[1].get("role") != "user"
        or not isinstance(messages[1].get("content"), list)
    ):
        raise ValueError("widened call does not carry the active combined prompt")
    text_parts = [
        part.get("text")
        for part in messages[1]["content"]
        if isinstance(part, dict) and part.get("type") == "text"
    ]
    if len(text_parts) != 1 or not all(
        marker in text_parts[0]
        for marker in (
            "Partial task statement:",
            "Surrounding activity from the legible Markdown store:",
            "Existing picture description",
            "figure_reading | not_gridded",
        )
    ):
        raise ValueError("widened call is missing v4 context or figure schema")


def _payloads() -> list[dict[str, Any]]:
    return narrow._payloads()


def _worklist(payloads: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Build deterministic gridded-first rows with furniture classified."""
    digest_lessons: dict[str, set[str]] = {}
    for payload in payloads:
        for task in payload["tasks"]:
            key = (payload["lesson"], task["position"])
            if (
                task["blocker"] == "none"
                or not task["visual_provenance"]
                or key == NARROW_RECOVERED_ROW
            ):
                continue
            for visual in task["visual_provenance"]:
                digest_lessons.setdefault(_asset_digest(visual["asset"]), set()).add(
                    payload["lesson"]
                )
    rows: list[dict[str, Any]] = []
    for payload in payloads:
        for task in payload["tasks"]:
            key = (payload["lesson"], task["position"])
            if (
                task["blocker"] == "none"
                or not task["visual_provenance"]
                or key == NARROW_RECOVERED_ROW
            ):
                continue
            assets = []
            for visual in task["visual_provenance"]:
                description = narrow._description(visual)
                digest = _asset_digest(visual["asset"])
                width, height = _png_dimensions(ROOT / visual["asset"])
                lesson_count = len(digest_lessons[digest])
                furniture_reasons = _furniture_reasons(width, height, lesson_count)
                furniture = bool(furniture_reasons)
                assets.append(
                    {
                        "asset": visual["asset"],
                        "asset_digest": digest,
                        "width": width,
                        "height": height,
                        "digest_lesson_count": lesson_count,
                        "furniture": furniture,
                        "furniture_reasons": furniture_reasons,
                        "description_file": visual["description"],
                        "description": description,
                        "grid_preference": not furniture
                        and bool(
                            re.search(
                                r"\b(?:coordinate|grid|graph|axis|axes)\b",
                                description,
                                re.I,
                            )
                        ),
                        "prompt_version": PROMPT_VERSION,
                        "prompt_sha256": PROMPT_SHA256,
                        "call_id": _call_id(
                            payload["lesson"], task["position"], visual["asset"]
                        ),
                    }
                )
            row = {
                "row_id": _row_id(payload["lesson"], task["position"]),
                "lesson": payload["lesson"],
                "position": task["position"],
                "original_blocker": task["blocker"],
                "original_excerpt": task["excerpt"],
                "activity_context": _activity_context(
                    payload["lesson"], int(task["line_start"])
                ),
                "assets": assets,
            }
            row["grid_preference"] = any(asset["grid_preference"] for asset in assets)
            row["furniture_assets"] = sum(asset["furniture"] for asset in assets)
            row["callable_assets"] = sum(not asset["furniture"] for asset in assets)
            rows.append(row)
    return sorted(
        rows,
        key=lambda row: (
            not row["grid_preference"],
            _lesson_key(row["lesson"]),
            tuple(map(int, re.findall(r"\d+", row["position"]))),
        ),
    )


def _math_tokens(value: str) -> list[str]:
    return [match.group(0) for match in MATH_TOKEN_RE.finditer(value)]


def _contains_tokens(needle: list[str], haystack: list[str]) -> bool:
    if not needle:
        return False
    width = len(needle)
    return any(
        haystack[start : start + width] == needle
        for start in range(len(haystack) - width + 1)
    )


def _weak_description_consistency(text: str, description: str) -> tuple[bool, str]:
    if (
        vision_statement_contract.normalized_contiguous_span(text, description)
        is not None
    ):
        return True, "full_text_agreement"
    described = _math_tokens(description)
    transcribed = _math_tokens(text)
    if not described or not transcribed:
        return True, "description_silent"
    if _contains_tokens(transcribed, described) or _contains_tokens(
        described, transcribed
    ):
        return True, "described_tokens_agree"
    overlap = SequenceMatcher(
        None, transcribed, described, autojunk=False
    ).find_longest_match()
    return (
        (True, "description_silent")
        if overlap.size < 2
        else (False, "description_contradiction")
    )


def _named_point_labels(text: str) -> set[str]:
    labels: set[str] = set()
    for match in POINT_LABEL_RE.finditer(text):
        if match.group(1):
            labels.add(match.group(1).replace("′", "'"))
        elif match.group(2):
            labels.update(match.group(2).upper())
    return labels


def _number(value: Any) -> bool:
    return (
        isinstance(value, (int, float))
        and not isinstance(value, bool)
        and math.isfinite(value)
    )


def _grid_plausible(value: float) -> bool:
    return abs(value) <= MAX_COORDINATE and math.isclose(
        value * GRID_DENOMINATOR, round(value * GRID_DENOMINATOR), abs_tol=1e-8
    )


def _required_label_present(required: str, labels: set[str]) -> bool:
    return any(
        label == required
        or label.endswith(f":{required}")
        or label.endswith(f".{required}")
        for label in labels
    )


def _figure_schema(reading: dict[str, Any], row: dict[str, Any]) -> list[str]:
    reasons: list[str] = []
    points = reading["points"]
    if not points:
        reasons.append("no_points")
    labels: list[str] = []
    coordinates: dict[str, tuple[float, float]] = {}
    for index, point in enumerate(points):
        if not isinstance(point, dict) or set(point) != {"label", "x", "y"}:
            reasons.append(f"point_{index}_schema")
            continue
        label = point["label"]
        if not isinstance(label, str) or not label.strip():
            reasons.append(f"point_{index}_label")
            continue
        label = label.strip().replace("′", "'")
        if label in labels:
            reasons.append(f"duplicate_point_{label}")
        labels.append(label)
        if not _number(point["x"]) or not _number(point["y"]):
            reasons.append(f"point_{label}_nonnumeric")
        elif not _grid_plausible(float(point["x"])) or not _grid_plausible(
            float(point["y"])
        ):
            reasons.append(f"point_{label}_not_grid_plausible")
        else:
            coordinates[label] = (float(point["x"]), float(point["y"]))
    label_set = set(labels)
    required = _named_point_labels(
        row["original_excerpt"] + "\n" + row["activity_context"]["text"]
    )
    missing = sorted(
        label for label in required if not _required_label_present(label, label_set)
    )
    if missing:
        reasons.append("missing_lesson_points_" + "_".join(missing))

    for index, shape in enumerate(reading["shapes"]):
        if not isinstance(shape, dict) or set(shape) != {
            "label",
            "kind",
            "vertices",
            "parameters",
        }:
            reasons.append(f"shape_{index}_schema")
            continue
        if shape["kind"] not in {"triangle", "quadrilateral", "polygon"}:
            reasons.append(f"shape_{index}_kind")
        vertices = shape["vertices"]
        if not isinstance(vertices, list) or len(vertices) < 3:
            reasons.append(f"shape_{index}_vertices")
        elif any(vertex not in label_set for vertex in vertices):
            reasons.append(f"shape_{index}_unknown_vertex")
        if not isinstance(shape["label"], str) or not isinstance(
            shape["parameters"], dict
        ):
            reasons.append(f"shape_{index}_metadata")
        if shape.get("parameters"):
            reasons.append(f"shape_{index}_parameters_not_renderable")

    for index, line in enumerate(reading["lines"]):
        if not isinstance(line, dict) or set(line) != {"label", "kind", "through"}:
            reasons.append(f"line_{index}_schema")
            continue
        if line["kind"] not in {"line", "segment", "axis", "ray"}:
            reasons.append(f"line_{index}_kind")
        through = line["through"]
        if not isinstance(through, list) or len(through) != 2:
            reasons.append(f"line_{index}_through")
        elif any(label not in label_set for label in through):
            reasons.append(f"line_{index}_unknown_point")
        if line["kind"] == "ray":
            reasons.append(f"line_{index}_ray_not_renderable")
        if not isinstance(line["label"], str):
            reasons.append(f"line_{index}_label")
    return reasons


def _weak_reading_consistency(
    reading: dict[str, Any], description: str
) -> tuple[bool, str]:
    conflicts = []
    by_label = {
        point["label"].replace("′", "'"): (float(point["x"]), float(point["y"]))
        for point in reading["points"]
        if isinstance(point, dict)
        and isinstance(point.get("label"), str)
        and _number(point.get("x"))
        and _number(point.get("y"))
    }
    compared = 0
    for match in COORDINATE_RE.finditer(description):
        label = match.group(1).replace("′", "'")
        if label not in by_label:
            continue
        compared += 1
        described = (float(match.group(2)), float(match.group(3)))
        if by_label[label] != described:
            conflicts.append(label)
    printed = reading["printed_text"]
    if printed:
        agrees, reason = _weak_description_consistency(printed, description)
        if not agrees:
            conflicts.append(reason)
    if conflicts:
        return False, "description_contradiction_" + "_".join(conflicts)
    return True, "described_coordinates_agree" if compared else "description_silent"


def _gap_closed(row: dict[str, Any], text: str, result_class: str) -> bool:
    if row["original_blocker"] in EXPRESSION_BLOCKERS:
        return bool(_math_tokens(text)) and not (
            extraction._missing_expression(text) or recovery._still_has_plain_gap(text)
        )
    if result_class != "task_statement":
        return False
    task = {"blocker": row["original_blocker"], "excerpt": row["original_excerpt"]}
    return recovery._materially_new(task, [], text)


def _uncertain(reason: str, **fields: Any) -> dict[str, Any]:
    return {
        "accepted": False,
        "terminal_class": "uncertain_residue",
        "failure": reason,
        **fields,
    }


def _first_json_object(content: Any) -> dict[str, Any] | None:
    """Decode the first balanced JSON object, ignoring prose and fences."""
    if not isinstance(content, str):
        return None
    for start, character in enumerate(content):
        if character != "{":
            continue
        depth = 0
        quoted = False
        escaped = False
        for end in range(start, len(content)):
            token = content[end]
            if quoted:
                if escaped:
                    escaped = False
                elif token == "\\":
                    escaped = True
                elif token == '"':
                    quoted = False
                continue
            if token == '"':
                quoted = True
            elif token == "{":
                depth += 1
            elif token == "}":
                depth -= 1
                if depth == 0:
                    try:
                        value = json.loads(content[start : end + 1])
                    except json.JSONDecodeError:
                        break
                    if isinstance(value, dict):
                        return value
                    break
                if depth < 0:
                    break
    return None


def _parse_ok(result: Any, row: dict[str, Any], description: str) -> dict[str, Any]:
    outcome = getattr(result, "outcome", "unknown")
    if outcome != "ok":
        return _uncertain(f"outcome_{outcome}", reading=None)
    content = getattr(result, "content", "")
    value = _first_json_object(content)
    if value is None:
        return _uncertain("invalid_json", reading=None)
    required = {"class", "certainty", "printed_text", "points", "shapes", "lines"}
    if not isinstance(value, dict) or set(value) != required:
        return _uncertain("schema", reading=value if isinstance(value, dict) else None)
    result_class = value["class"]
    certainty = value["certainty"]
    if (
        result_class not in RESULT_CLASSES
        or certainty not in {"certain", "uncertain"}
        or not isinstance(value["printed_text"], str)
        or not all(
            isinstance(value[key], list) for key in ("points", "shapes", "lines")
        )
    ):
        return _uncertain("schema", reading=value)
    value["printed_text"] = _normalize(value["printed_text"])
    if certainty != "certain":
        return _uncertain("uncertain_reading", reading=value)
    if result_class == "not_gridded":
        if value["points"] or value["shapes"] or value["lines"]:
            return _uncertain("not_gridded_with_geometry", reading=value)
        if value["printed_text"]:
            consistent, consistency = _weak_description_consistency(
                value["printed_text"], description
            )
            if consistent and _gap_closed(row, value["printed_text"], "printed_math"):
                return {
                    "accepted": True,
                    "terminal_class": "text_recovered",
                    "accepted_channel": "printed_math",
                    "failure": None,
                    "figure_reason": "not_gridded",
                    "reading": value,
                    "consistency": consistency,
                }
            if not consistent:
                return _uncertain(
                    "printed_text_inconsistent",
                    reading=value,
                    consistency=consistency,
                )
        return _uncertain("not_gridded", reading=value)
    if result_class in {"task_statement", "printed_math"}:
        if value["points"] or value["shapes"] or value["lines"]:
            return _uncertain("text_class_with_geometry", reading=value)
        text = value["printed_text"]
        if not text:
            return _uncertain("empty_printed_text", reading=value)
        consistent, consistency = _weak_description_consistency(text, description)
        closes = _gap_closed(row, text, result_class)
        if not consistent:
            return _uncertain(
                "description_inconsistent", reading=value, consistency=consistency
            )
        if not closes:
            return _uncertain("named_gap_open", reading=value, consistency=consistency)
        return {
            "accepted": True,
            "terminal_class": "text_recovered",
            "accepted_channel": result_class,
            "failure": None,
            "reading": value,
            "consistency": consistency,
        }
    printed_accept = False
    printed_consistency = "not_present"
    if value["printed_text"]:
        text_consistent, printed_consistency = _weak_description_consistency(
            value["printed_text"], description
        )
        if not text_consistent:
            return _uncertain(
                "printed_text_inconsistent",
                reading=value,
                consistency=printed_consistency,
            )
        printed_accept = _gap_closed(row, value["printed_text"], "printed_math")
    schema_reasons = _figure_schema(value, row)
    if schema_reasons:
        if printed_accept:
            return {
                "accepted": True,
                "terminal_class": "text_recovered",
                "accepted_channel": "printed_math",
                "failure": None,
                "figure_reasons": schema_reasons,
                "reading": value,
                "consistency": printed_consistency,
            }
        return _uncertain("figure_schema", reading=value, reasons=schema_reasons)
    consistent, consistency = _weak_reading_consistency(value, description)
    if not consistent:
        return _uncertain(
            "description_inconsistent", reading=value, consistency=consistency
        )
    return {
        "accepted": False,
        "terminal_class": "figure_render_pending",
        "accepted_channel": "figure_reading",
        "failure": None,
        "reading": value,
        "consistency": consistency,
    }


def _point_map(reading: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        point["label"]: {"x": point["x"], "y": point["y"]}
        for point in reading["points"]
    }


def _grapher_spec(reading: dict[str, Any], call_id: str, row_id: str) -> dict[str, Any]:
    points = [
        {"label": point["label"], "x": point["x"], "y": point["y"]}
        for point in reading["points"]
    ]
    by_label = _point_map(reading)
    lines: list[dict[str, Any]] = []
    seen: set[tuple[Any, ...]] = set()

    def add_segment(left: str, right: str, label: str = "") -> None:
        key = ("segment", left, right)
        reverse = ("segment", right, left)
        if key in seen or reverse in seen:
            return
        seen.add(key)
        item: dict[str, Any] = {
            "type": "segment",
            "from": by_label[left],
            "to": by_label[right],
        }
        if label:
            item["label"] = label
        lines.append(item)

    for shape in reading["shapes"]:
        vertices = shape["vertices"]
        for index, left in enumerate(vertices):
            add_segment(left, vertices[(index + 1) % len(vertices)])
    for line in reading["lines"]:
        left, right = line["through"]
        if line["kind"] == "segment":
            add_segment(left, right, line["label"])
        else:
            item = {
                "type": "through-points",
                "points": [by_label[left], by_label[right]],
            }
            if line["label"]:
                item["label"] = line["label"]
            lines.append(item)
    return {
        "version": 1,
        "id": call_id,
        "kind": "coordinate-plane",
        "title": f"Recovered figure for {row_id}",
        "description": "Deterministic rendering of an accepted structured vision reading.",
        "points": points,
        "lines": lines,
    }


def _render_svg(spec: dict[str, Any]) -> str:
    program = """
const grapher = require(process.argv[1]);
const spec = JSON.parse(process.argv[2]);
grapher.validateSpec(spec);
const first = grapher.renderSpec(spec);
const second = grapher.renderSpec(spec);
if (first !== second) throw new Error('nondeterministic SVG');
process.stdout.write(first);
"""
    completed = subprocess.run(
        ["node", "-e", program, str(GRAPHER), json.dumps(spec, separators=(",", ":"))],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if completed.returncode:
        raise ValueError("coordinate-plane render failed: " + completed.stderr.strip())
    if 'data-hermes-renderer="grapher-v1"' not in completed.stdout:
        raise ValueError("coordinate-plane render lacks grapher receipt marker")
    return completed.stdout


def _receipt_paths(asset: str, call_id: str) -> tuple[Path, Path]:
    image = ROOT / asset
    return (
        image.with_name(f"{image.stem}.{call_id}.figure-reading.svg"),
        image.with_name(f"{image.stem}.{call_id}.figure-reading.json"),
    )


def _render_receipt(checkpoint: dict[str, Any]) -> dict[str, Any]:
    spec = _grapher_spec(
        checkpoint["reading"], checkpoint["call_id"], checkpoint["row_id"]
    )
    svg = _render_svg(spec)
    svg_path, receipt_path = _receipt_paths(checkpoint["asset"], checkpoint["call_id"])
    recovery.atomic_write(svg_path, svg)
    receipt = {
        "renderer": "hermes/web/coordinate-plane/grapher.js",
        "renderer_sha256": recovery.sha256_file(GRAPHER),
        "prompt_version": PROMPT_VERSION,
        "call_id": checkpoint["call_id"],
        "source_asset": checkpoint["asset"],
        "source_asset_sha256": recovery.sha256_file(ROOT / checkpoint["asset"]),
        "spec": spec,
        "svg": svg_path.relative_to(ROOT).as_posix(),
        "svg_sha256": _sha256_text(svg),
    }
    recovery.atomic_write_json(receipt_path, receipt)
    return {
        "path": receipt_path.relative_to(ROOT).as_posix(),
        "svg": svg_path.relative_to(ROOT).as_posix(),
        "sha256": receipt["svg_sha256"],
        "renderer": receipt["renderer"],
        "renderer_sha256": receipt["renderer_sha256"],
    }


def _textualize_figure(reading: dict[str, Any], asset: str) -> str:
    return vision_statement_contract.textualize_figure(reading, asset)


def _checkpoint_path(output: Path, call_id: str) -> Path:
    return output / "checkpoints" / f"{call_id}.json"


def _read_json(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"JSON object required: {path}")
    return value


def _campaign_calls(output: Path) -> int:
    recorded = 0
    campaign_path = output / "campaign.json"
    if campaign_path.is_file():
        recorded = int(_read_json(campaign_path).get("provider_calls", 0))
    checkpoint_calls = sum(
        max(1, int(_read_json(path).get("attempts", 1)))
        for path in sorted((output / "checkpoints").glob("*.json"))
    )
    return max(recorded, checkpoint_calls)


def _write_campaign(output: Path, calls: int) -> None:
    recovery.atomic_write_json(
        output / "campaign.json",
        {
            "model": MODEL,
            "max_tokens": MAX_TOKENS,
            "active_prompt_version": PROMPT_VERSION,
            "hard_call_budget": HARD_CALL_BUDGET,
            "provider_calls": calls,
            "remaining_calls": HARD_CALL_BUDGET - calls,
        },
    )


def _write_results(rows: list[dict[str, Any]], output: Path) -> dict[str, int]:
    assets_out = []
    residue = []
    counts: Counter[str] = Counter()
    for row in rows:
        for asset in row["assets"]:
            path = _checkpoint_path(output, asset["call_id"])
            if asset["furniture"]:
                terminal = "page_furniture"
                checkpoint = None
            elif not path.is_file():
                terminal = "pending"
                checkpoint = None
            else:
                checkpoint = _read_json(path)
                terminal = checkpoint.get("terminal_class") or "uncertain_residue"
            counts[terminal] += 1
            assets_out.append(
                {
                    "row_id": row["row_id"],
                    "asset": asset["asset"],
                    "call_id": asset["call_id"],
                    "terminal_class": terminal,
                    "reason": (
                        asset["furniture_reasons"]
                        if asset["furniture"]
                        else None
                        if checkpoint is None
                        else checkpoint.get("failure")
                    ),
                    "receipt": None
                    if checkpoint is None
                    else checkpoint.get("render_receipt"),
                }
            )
            if terminal == "uncertain_residue" and checkpoint is not None:
                residue.append(
                    {
                        "row_id": row["row_id"],
                        "asset": asset["asset"],
                        "call_id": asset["call_id"],
                        "terminal_class": terminal,
                        "reason": checkpoint.get("failure"),
                        "reasons": checkpoint.get("reasons", []),
                    }
                )
    recovery.atomic_write_json(
        output / "row_results.json",
        {
            "prompt_version": PROMPT_VERSION,
            "asset_class_counts": dict(sorted(counts.items())),
            "assets": assets_out,
        },
    )
    text = "".join(json.dumps(item, ensure_ascii=False) + "\n" for item in residue)
    recovery.atomic_write(output / "uncertain_residue.jsonl", text)
    return {
        "figure_readings_accepted": counts["figure_recovered"],
        "text_assets_accepted": counts["text_recovered"],
        "furniture_assets_skipped": counts["page_furniture"],
        "uncertain_residue": counts["uncertain_residue"],
    }


def _apply_checkpoints(
    payloads: list[dict[str, Any]], rows: list[dict[str, Any]], output: Path
) -> int:
    payload_by_lesson = {payload["lesson"]: payload for payload in payloads}
    accepted_rows = 0
    for row in rows:
        accepted = []
        for asset in row["assets"]:
            path = _checkpoint_path(output, asset["call_id"])
            if path.is_file():
                checkpoint = _read_json(path)
                if checkpoint.get("accepted"):
                    accepted.append(checkpoint)
        if not accepted:
            continue
        task = next(
            item
            for item in payload_by_lesson[row["lesson"]]["tasks"]
            if item["position"] == row["position"]
        )
        statement = vision_statement_contract.compose_widened_statement(accepted)
        task["excerpt"] = statement
        task["extraction_status"] = "recovered"
        task["blocker"] = "none"
        vision_recovery = {
            "provenance_class": vision_statement_contract.WIDENED_CHECKPOINT_CLASS,
            "model": MODEL,
            "prompt_version": PROMPT_VERSION,
            "method": vision_statement_contract.WIDENED_METHOD,
            "call_id": accepted[0]["call_id"],
            "asset": accepted[0]["asset"],
            "description_file": accepted[0]["description_file"],
            "response_sha256": vision_statement_contract.response_sha256(
                accepted[0]["response"]
            ),
            "statement": statement,
            "activity_context": row["activity_context"],
            "readings": [
                {
                    "call_id": item["call_id"],
                    "asset": item["asset"],
                    "description_file": item["description_file"],
                    "reading": item["reading"],
                    "render_receipt": item.get("render_receipt"),
                    "response_sha256": vision_statement_contract.response_sha256(
                        item["response"]
                    ),
                }
                for item in accepted
            ],
        }
        receipt = vision_statement_contract.widened_statement_receipt(
            statement, vision_recovery, accepted
        )
        vision_recovery["acceptance_paths"] = receipt["acceptance_paths"]
        task["vision_recovery"] = vision_recovery
        accepted_rows += 1
    return accepted_rows


def _write_recovery_outputs(payloads: list[dict[str, Any]]) -> None:
    for payload in payloads:
        recovery.atomic_write_json(
            recovery.recovery_checkpoint_path(
                recovery.DEFAULT_RECOVERY_DIR, payload["lesson"]
            ),
            payload,
        )
    recovery.atomic_write(
        recovery.DEFAULT_TASK_OUTPUT, extraction.render_tasks(8, payloads)
    )
    recovery.atomic_write_json(
        recovery.DEFAULT_RECOVERY_DIR / "summary.json",
        recovery.build_summary(payloads, resumed=len(payloads), wall=0.0),
    )


def _dry_run(rows: list[dict[str, Any]]) -> int:
    print(
        json.dumps(
            {
                "eligible_rows": len(rows),
                "prompt_version": PROMPT_VERSION,
                "gridded_first_rows": sum(row["grid_preference"] for row in rows),
                "furniture_assets": sum(
                    asset["furniture"] for row in rows for asset in row["assets"]
                ),
                "callable_assets": sum(
                    not asset["furniture"] for row in rows for asset in row["assets"]
                ),
                "dry_run": True,
            }
        )
    )
    for row in rows[:5]:
        print(
            json.dumps(
                {
                    "row_id": row["row_id"],
                    "blocker": row["original_blocker"],
                    "grid_preference": row["grid_preference"],
                    "activity_source": row["activity_context"]["path"],
                    "activity_readable": Path(
                        row["activity_context"]["path"]
                    ).is_file(),
                    "assets": [
                        {
                            "path": str((ROOT / asset["asset"]).resolve()),
                            "readable": (ROOT / asset["asset"]).is_file(),
                            "furniture": asset["furniture"],
                            "furniture_reasons": asset["furniture_reasons"],
                        }
                        for asset in row["assets"]
                    ],
                }
            )
        )
    if any(
        not (ROOT / asset["asset"]).is_file() for row in rows for asset in row["assets"]
    ):
        raise ValueError("worklist contains an unreadable image asset")
    return 0


def _self_check() -> int:
    class FixtureResult:
        outcome = "ok"

        def __init__(self, payload: dict[str, Any], *, fenced: bool = False) -> None:
            encoded = json.dumps(payload)
            self.content = (
                f"Result follows.\n```json\n{encoded}\n```\nDone."
                if fenced
                else encoded
            )

    row = {
        "row_id": "fixture:student_task_statement(1)",
        "original_blocker": "expression_missing_from_markdown",
        "original_excerpt": "Triangle ABC has equation .",
        "activity_context": {"text": "Point A, point B, and point C are vertices."},
    }
    reading = {
        "class": "figure_reading",
        "certainty": "certain",
        "printed_text": "",
        "points": [
            {"label": "A", "x": 0, "y": 0},
            {"label": "B", "x": 3, "y": 0},
            {"label": "C", "x": 0, "y": 2},
        ],
        "shapes": [
            {
                "label": "triangle ABC",
                "kind": "triangle",
                "vertices": ["A", "B", "C"],
                "parameters": {},
            }
        ],
        "lines": [],
    }
    verdict = _parse_ok(
        FixtureResult(reading, fenced=True),
        row,
        "A triangle has vertices A, B, and C on a grid.",
    )
    assert verdict["terminal_class"] == "figure_render_pending", verdict
    checkpoint = {
        "reading": reading,
        "call_id": "g8vw_fixture",
        "row_id": row["row_id"],
        "asset": "fixture.png",
    }
    spec = _grapher_spec(reading, checkpoint["call_id"], checkpoint["row_id"])
    first = _render_svg(spec)
    second = _render_svg(spec)
    assert first == second and 'data-hermes-renderer="grapher-v1"' in first
    assert "A=(0, 0)" in _textualize_figure(reading, checkpoint["asset"])
    checkpoint.update(
        {
            "accepted": True,
            "accepted_channel": "figure_reading",
            "terminal_class": "figure_recovered",
            "prompt_version": PROMPT_VERSION,
            "description_file": "fixture-descriptions.md",
            "original_excerpt": row["original_excerpt"],
            "render_receipt": {"path": "fixture-receipt.json"},
            "response": {
                "outcome": "ok",
                "content": json.dumps(reading),
                "raw_response": {"fixture": True},
            },
        }
    )
    statement = vision_statement_contract.compose_widened_statement([checkpoint])
    vision_recovery = {
        "provenance_class": vision_statement_contract.WIDENED_CHECKPOINT_CLASS,
        "prompt_version": PROMPT_VERSION,
        "method": vision_statement_contract.WIDENED_METHOD,
        "call_id": checkpoint["call_id"],
        "response_sha256": vision_statement_contract.response_sha256(
            checkpoint["response"]
        ),
        "statement": statement,
        "readings": [
            {
                "call_id": checkpoint["call_id"],
                "asset": checkpoint["asset"],
                "description_file": checkpoint["description_file"],
                "reading": reading,
                "render_receipt": checkpoint["render_receipt"],
                "response_sha256": vision_statement_contract.response_sha256(
                    checkpoint["response"]
                ),
            }
        ],
    }
    receipt = vision_statement_contract.widened_statement_receipt(
        statement, vision_recovery, [checkpoint]
    )
    assert receipt["provenance_class"] == (
        vision_statement_contract.WIDENED_CHECKPOINT_CLASS
    )

    bad = json.loads(json.dumps(reading))
    bad["points"] = bad["points"][:2]
    residue = _parse_ok(FixtureResult(bad), row, "A triangle has vertices A, B, and C.")
    assert residue["terminal_class"] == "uncertain_residue", residue
    not_gridded = dict(reading)
    not_gridded.update(
        {"class": "not_gridded", "points": [], "shapes": [], "lines": []}
    )
    honest = _parse_ok(FixtureResult(not_gridded), row, "A geometric diagram.")
    assert honest["failure"] == "not_gridded", honest
    assert _first_json_object(
        'prefix {"note":"brace } in string","ok":true} suffix'
    ) == {
        "note": "brace } in string",
        "ok": True,
    }
    active_prompt = USER_PROMPT_TEMPLATE.format(
        partial_statement="partial",
        activity_source="guide.md:1",
        activity_text="activity",
        description="description",
    )
    _assert_current_messages(
        [
            {"role": "system", "content": SYSTEM_PROMPT},
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": active_prompt},
                    {
                        "type": "image_url",
                        "image_url": {"url": "data:image/png;base64,"},
                    },
                ],
            },
        ]
    )
    try:
        _assert_current_messages(
            [
                {"role": "system", "content": "Transcribe the task statement."},
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "Transcribe the image."},
                        {
                            "type": "image_url",
                            "image_url": {"url": "data:image/png;base64,"},
                        },
                    ],
                },
            ]
        )
    except ValueError:
        pass
    else:
        raise AssertionError("retired statement-only prompt passed the v4 guard")
    assert _furniture_reasons(98, 75, 46) == ["digest_recurs_across_46_lessons"]
    assert _furniture_reasons(20, 20, 1) == ["below_32x32_size_floor"]
    assert _furniture_reasons(640, 480, 1) == []
    print(
        "PASS vision v4: fenced JSON extraction, active combined prompt, "
        "furniture prefilter, coordinate checks, deterministic grapher, "
        "textualization, widened receipt contract"
    )
    return 0


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--limit", type=int, default=DEFAULT_LIMIT)
    parser.add_argument("--timeout", type=int, default=600)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--self-check", action="store_true")
    args = parser.parse_args(argv)
    if args.limit < 0:
        parser.error("--limit must be nonnegative")
    return args


def run(args: argparse.Namespace) -> int:
    if args.self_check:
        return _self_check()
    payloads = _payloads()
    rows = _worklist(payloads)
    counts = Counter(row["original_blocker"] for row in rows)
    if args.dry_run:
        return _dry_run(rows)

    recovery.atomic_write_json(
        args.out / "worklist.json",
        {
            "model": MODEL,
            "max_tokens": MAX_TOKENS,
            "prompt_version": PROMPT_VERSION,
            "hard_call_budget": HARD_CALL_BUDGET,
            "eligible_rows": len(rows),
            "furniture_assets": sum(
                asset["furniture"] for row in rows for asset in row["assets"]
            ),
            "callable_assets": sum(
                not asset["furniture"] for row in rows for asset in row["assets"]
            ),
            "blockers": dict(sorted(counts.items())),
            "rows": rows,
        },
    )
    selected = rows[: args.limit]
    calls = _campaign_calls(args.out)
    if calls > HARD_CALL_BUDGET:
        raise ValueError(f"stored campaign count {calls} exceeds {HARD_CALL_BUDGET}")
    _write_campaign(args.out, calls)

    llm = None
    api_key = api_url = ssl_ctx = None
    new_checkpoints = 0
    for row in selected:
        for asset in row["assets"]:
            if asset["furniture"]:
                continue
            checkpoint_path = _checkpoint_path(args.out, asset["call_id"])
            if checkpoint_path.is_file():
                continue
            remaining = HARD_CALL_BUDGET - calls
            if remaining <= 0:
                continue
            if llm is None:
                llm = vision_pass.load_llm_module()
                llm.load_dotenv(ROOT)
                api_key = llm.load_key(ROOT)
                if api_key is None:
                    raise RuntimeError("REALLMS_API_KEY is not configured")
                api_url = llm.resolve_api_url()
                ssl_ctx = llm.build_ssl_context()
            messages = _messages(ROOT / asset["asset"], row, asset)
            _assert_current_messages(messages)
            if (
                asset["prompt_version"] != PROMPT_VERSION
                or asset["prompt_sha256"] != PROMPT_SHA256
            ):
                raise ValueError("asset does not carry the active prompt identity")
            result = llm.call_api_messages_result(
                messages,
                api_key=api_key,
                api_url=api_url,
                model=MODEL,
                ssl_ctx=ssl_ctx,
                retries=min(3, remaining),
                timeout=args.timeout,
                max_tokens=MAX_TOKENS,
            )
            attempts = max(1, int(getattr(result, "attempts", 1)))
            calls += attempts
            if calls > HARD_CALL_BUDGET:
                raise RuntimeError("widened vision call budget exceeded")
            _write_campaign(args.out, calls)
            verdict = _parse_ok(result, row, asset["description"])
            checkpoint = {
                "row_id": row["row_id"],
                "lesson": row["lesson"],
                "position": row["position"],
                "original_blocker": row["original_blocker"],
                "original_excerpt": row["original_excerpt"],
                "activity_context": row["activity_context"],
                **asset,
                "model": MODEL,
                "max_tokens": MAX_TOKENS,
                "attempts": attempts,
                "outcome": getattr(result, "outcome", "unknown"),
                "retryable": bool(getattr(result, "retryable", False)),
                **verdict,
                "response": result.to_dict(),
            }
            if checkpoint["terminal_class"] == "figure_render_pending":
                try:
                    checkpoint["render_receipt"] = _render_receipt(checkpoint)
                except (OSError, ValueError, subprocess.SubprocessError) as exc:
                    checkpoint.update(
                        accepted=False,
                        terminal_class="uncertain_residue",
                        failure="render_failed",
                        reasons=[str(exc)],
                    )
                else:
                    checkpoint.update(
                        accepted=True,
                        terminal_class="figure_recovered",
                        failure=None,
                    )
            recovery.atomic_write_json(checkpoint_path, checkpoint)
            new_checkpoints += 1

    accepted_rows = _apply_checkpoints(payloads, selected, args.out)
    _write_recovery_outputs(payloads)
    terminal_counts = _write_results(rows, args.out)
    completed_assets = sum(
        _checkpoint_path(args.out, asset["call_id"]).is_file()
        for row in selected
        for asset in row["assets"]
    )
    print(
        json.dumps(
            {
                "eligible_rows": len(rows),
                "blockers": dict(sorted(counts.items())),
                "selected_rows": len(selected),
                "selected_assets": sum(len(row["assets"]) for row in selected),
                "selected_furniture_assets": sum(
                    asset["furniture"] for row in selected for asset in row["assets"]
                ),
                "selected_callable_assets": sum(
                    not asset["furniture"]
                    for row in selected
                    for asset in row["assets"]
                ),
                "completed_assets": completed_assets,
                "new_checkpoints": new_checkpoints,
                "campaign_provider_calls": calls,
                "remaining_budget": HARD_CALL_BUDGET - calls,
                "accepted_rows": accepted_rows,
                **terminal_counts,
            },
            sort_keys=True,
        )
    )
    return 0


def main(argv: list[str] | None = None) -> int:
    try:
        return run(parse_args(argv))
    except (OSError, RuntimeError, ValueError, json.JSONDecodeError) as exc:
        sys.stderr.write(f"error: {exc}\n")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
