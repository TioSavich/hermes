#!/usr/bin/env python3
"""Recover fraction operands that PDF-to-Markdown conversion destroyed.

Six lessons carry fraction-comparison, fraction-multiplication, or
fraction-division student tasks whose teacher-guide Markdown lost every
printed fraction glyph in the PDF-to-text pass (a run of bare spaces stands
where the glyph was, e.g. "Jada ran     mile."). The Markdown loss is not
lesson-specific text loss: the same destroyed span in the Docling extraction
under ``hermes/app/runtime/experiments/gemma4_tutor/docling`` confirms the
glyph, not the surrounding words, is what the conversion dropped.

This script reads one or more rendered page images per lesson (the source
PDF pages under the local IM-Curriculum tree, rendered once by a throwaway
helper and cached under ``hermes/app/runtime/experiments/
vision_fraction_recovery/<date>/pages``), asks a vision-capable REALLMS model
to transcribe every printed fraction on the page together with the five to
ten surrounding words, and accepts a reading only when the surrounding words
-- with the fraction's own placeholder removed -- reproduce a line of the
lesson's own Markdown after whitespace normalization. That reproduction is
the receipt: the model supplies what the destroyed glyph was, and the
Markdown itself confirms where it stood. A reading that anchors to no
Markdown line is held, never discarded, with its rejection reason recorded.

Two modes:
  --emit-only   Re-derive ``vision_fraction_recovery.pl`` from the saved
                checkpoint JSONL. Makes no network call. Deterministic.
  (default)     Call REALLMS for any page without a checkpoint yet, then
                emit.

IM-G5-U3-L19 ("Fraction Games") is called like every other page for an
honest record, but its Student Task Statement boxes are blank fill-in
templates -- the lesson's own printed content carries no fraction operand a
learner reads before answering. Rows recovered from its teacher-facing
Launch/Synthesis commentary are written to this store (so nothing found is
hidden) but are marked ``lesson_owned: false`` and are never consumed by
``build_lesson_representation_evidence.py``, preserving the deformation
chart's existing no-host refusal for that lesson.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import importlib.util
import json
import mimetypes
import re
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

RUN_DIR = ROOT / "hermes/app/runtime/experiments/vision_fraction_recovery/2026-08-20"
PAGES_DIR = RUN_DIR / "pages"
CHECKPOINT_PATH = RUN_DIR / "responses.jsonl"
OUTPUT = ROOT / "curriculum/im/generated/vision_fraction_recovery.pl"
LLM_PATH = ROOT / "hermes/app/llm.py"

MODEL = "gemma-4-31B-it"
# The 31B endpoint spends budget on reasoning_content below ~2500 max_tokens
# and returns empty final content with finish_reason=length (memory:
# reallms-two-auth-stacks.md, thinking-model-breaks-benchmark-stops.md).
MAX_TOKENS = 12000
TIMEOUT = 180
RETRIES = 3
RUN_DATE = "2026-08-20"

PLACEHOLDER = "[FRACTION]"

# lesson -> (markdown path, [(page image, pdf page number, lesson-owned?)])
TARGETS: dict[str, tuple[str, list[tuple[str, int, bool]]]] = {
    "IM-G4-U2-L14": (
        "curriculum/im_teacher_guides/grade4/unit2/lesson14.md",
        [("IM-G4-U2-L14_p3.png", 3, True), ("IM-G4-U2-L14_p6.png", 6, True)],
    ),
    "IM-G5-U2-L3": (
        "curriculum/im_teacher_guides/grade5/unit2/lesson3.md",
        [("IM-G5-U2-L3_p3.png", 3, True)],
    ),
    "IM-G5-U3-L5": (
        "curriculum/im_teacher_guides/grade5/unit3/lesson5.md",
        [("IM-G5-U3-L5_p3.png", 3, True)],
    ),
    "IM-G5-U3-L6": (
        "curriculum/im_teacher_guides/grade5/unit3/lesson6.md",
        [("IM-G5-U3-L6_p3.png", 3, True)],
    ),
    "IM-G5-U3-L13": (
        "curriculum/im_teacher_guides/grade5/unit3/lesson13.md",
        [("IM-G5-U3-L13_p3.png", 3, True)],
    ),
    "IM-G5-U3-L19": (
        "curriculum/im_teacher_guides/grade5/unit3/lesson19.md",
        # Activity 1's Student Task boxes are blank digit-fill templates; any
        # fraction a reading finds here comes from teacher-facing commentary,
        # not the lesson's own student-facing content. lesson_owned=False
        # keeps the deformation-chart guard for this lesson intact.
        [("IM-G5-U3-L19_p3.png", 3, False)],
    ),
}

SYSTEM_PROMPT = (
    "You transcribe every printed numeric fraction visible on this curriculum "
    "page image. A fraction is one whole number written over another, shown "
    "as a stacked numerator over a denominator. Reply with raw JSON only, no "
    "code fence or commentary."
)
USER_PROMPT = (
    'Return exactly one JSON object: {"fractions": [{"numerator": <integer>, '
    '"denominator": <integer>, "fragment": "<the printed sentence or list '
    "item containing this fraction, five to ten words, with the fraction "
    'itself replaced by the literal token ' + PLACEHOLDER + '">}]}. '
    "List every distinct printed fraction reading on the page, including a "
    "fraction that appears more than once with different surrounding words "
    "-- report each occurrence separately. Copy the surrounding words "
    "exactly as printed on the page, verbatim, including punctuation and "
    "capitalization and including any spelled-out words such as 'divided "
    "into' -- never substitute a symbol such as ÷ or × for a "
    "spelled-out word, and never paraphrase. The fragment must be plain "
    "text only: no LaTeX, no markdown, no dollar signs, no backslash "
    "commands. Write every OTHER fraction that appears inside the fragment "
    "(any fraction besides the one replaced by " + PLACEHOLDER + ") as "
    "plain digits separated by a forward slash, e.g. 3/4 -- never as a "
    "stacked or LaTeX fraction. Do not report whole numbers, standard "
    "codes such as 5.NF.B.4, page numbers, minute counts, or percentages "
    "as fractions. If the page has no printed fraction, return "
    '{"fractions": []}.'
)


# A second, narrower recovery pass for holes whose surrounding words are
# unique in their lesson's Markdown by construction (a line_needle located
# here, not searched for after the fact) but whose value the broad
# enumeration prompt above misread when asked to transcribe many fractions
# from one page at once. That misreading was caught by cross-checking the
# broad pass's accepted rows against a direct, independent re-inspection of
# the same rendered page images (recorded in the 2026-08-20 handoff, not
# fabricated here) -- rows named here replace only the ones that inspection
# specifically found wrong or unrecovered, never rows the broad pass already
# got right. One call, one fraction, with the model told exactly which words
# flank the missing glyph, the way vision_pass.py's combined text+image
# calls narrow a model's attention to one span instead of a whole page.
#
# A full lesson page image, at this render's resolution, was reliable for
# the "next to it" (1/6) reading below but was NOT reliable for the other
# five: the first targeted pass (full page, same prompt shape) returned a
# wrong value for every one of them, confirmed wrong by direct re-inspection
# of the rendered page (2026-08-20). A tight, several-times-zoomed crop
# around just the flanking words -- still the same source render, cropped
# and upscaled with PIL, never re-typeset -- read all five correctly on the
# very next call. The crop images live beside the full pages in this run's
# ``pages/`` directory and are named ``..._crop_<label>.png``.
TARGETED_ITEMS: list[dict[str, Any]] = [
    {
        "lesson": "IM-G4-U2-L14",
        "image": "IM-G4-U2-L14_p6_crop_jada.png",
        "page_number": 6,
        "needles": ("Jada ran", "mile."),
    },
    {
        "lesson": "IM-G4-U2-L14",
        "image": "IM-G4-U2-L14_p6_crop_kiran.png",
        "page_number": 6,
        "needles": ("Kiran ran", "mile."),
    },
    {
        "lesson": "IM-G4-U2-L14",
        "image": "IM-G4-U2-L14_p6_crop_lin.png",
        "page_number": 6,
        "needles": ("Lin ran", "mile."),
    },
    {
        "lesson": "IM-G5-U2-L3",
        "image": "IM-G5-U2-L3_p3_crop_mai.png",
        "page_number": 3,
        "needles": ("Mai says each dancer gets",),
    },
    {
        "lesson": "IM-G5-U3-L5",
        "image": "IM-G5-U3-L5_p3_crop_firstrow.png",
        "page_number": 3,
        "needles": ("of the first row shaded",),
    },
    {
        "lesson": "IM-G5-U3-L13",
        "image": "IM-G5-U3-L13_p3.png",
        "page_number": 3,
        "needles": ("next to it",),
    },
]

HOLE_RE = re.compile(r"  +")

TARGETED_SYSTEM_PROMPT = (
    "You read one specific printed fraction from the attached curriculum "
    "page image. Reply with raw JSON only, no code fence or commentary."
)
TARGETED_USER_PROMPT_TEMPLATE = (
    "The page has this printed sentence or list item, with one fraction's "
    'glyph blanked out here as an underscore: "{context}". Find that exact '
    "spot on the page image and read the stacked fraction printed there -- "
    "the numerator is the top number, the denominator is the bottom "
    'number. Return exactly one JSON object: {{"numerator": <integer>, '
    '"denominator": <integer>}}.'
)


def normalize_ws(value: str) -> str:
    return " ".join(value.split())


def locate_targeted_hole(md_lines: list[str], needles: tuple[str, ...]) -> tuple[int, str, str]:
    """Find the one line containing every needle, then its first blank-run
    hole after stripping the two-column layout's leading indentation.

    Returns (1-indexed line number, raw stripped line, a human-readable
    context string with the hole rendered as a single underscore) or raises
    if the needles or the hole are not uniquely present.
    """
    matches = [
        index
        for index, line in enumerate(md_lines)
        if all(needle in line for needle in needles)
    ]
    if len(matches) != 1:
        raise ValueError(f"needles {needles!r} matched {len(matches)} lines, expected 1")
    index = matches[0]
    stripped_line = md_lines[index].strip()
    holes = list(HOLE_RE.finditer(stripped_line))
    if not holes:
        raise ValueError(f"stripped line has no blank-run hole: {stripped_line!r}")
    hole = holes[0]
    # Keep only a handful of words on each side: the two-column layout can
    # run a second, unrelated hole's Launch-script text right up against
    # this one once whitespace is normalized, and a shorter, cleaner
    # context is also a better-targeted prompt for the model.
    before = " ".join(normalize_ws(stripped_line[: hole.start()]).split()[-8:])
    after = " ".join(normalize_ws(stripped_line[hole.end() :]).split()[:8])
    context = f"{before} _ {after}".strip()
    return index + 1, stripped_line, context


def image_data_url(path: Path) -> str:
    mime_type = mimetypes.guess_type(path.name)[0] or "image/png"
    encoded = base64.b64encode(path.read_bytes()).decode("ascii")
    return f"data:{mime_type};base64,{encoded}"


def load_llm_module() -> Any:
    spec = importlib.util.spec_from_file_location("hermes_vision_fraction_llm", LLM_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import shared client: {LLM_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def messages_for(image_path: Path) -> list[dict[str, Any]]:
    return [
        {"role": "system", "content": SYSTEM_PROMPT},
        {
            "role": "user",
            "content": [
                {"type": "text", "text": USER_PROMPT},
                {"type": "image_url", "image_url": {"url": image_data_url(image_path)}},
            ],
        },
    ]


def messages_for_targeted(image_path: Path, context: str) -> list[dict[str, Any]]:
    return [
        {"role": "system", "content": TARGETED_SYSTEM_PROMPT},
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": TARGETED_USER_PROMPT_TEMPLATE.format(context=context),
                },
                {"type": "image_url", "image_url": {"url": image_data_url(image_path)}},
            ],
        },
    ]


def targeted_call_id(lesson: str, image_name: str, needles: tuple[str, ...]) -> str:
    stable = "\0".join((lesson, image_name, *needles))
    digest = hashlib.sha256(stable.encode()).hexdigest()[:12]
    return f"targeted::{lesson}::{digest}"


def read_checkpoints() -> dict[str, dict[str, Any]]:
    if not CHECKPOINT_PATH.is_file():
        return {}
    rows: dict[str, dict[str, Any]] = {}
    for line in CHECKPOINT_PATH.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        row = json.loads(line)
        rows[row["call_id"]] = row
    return rows


def write_checkpoints(rows: dict[str, dict[str, Any]]) -> None:
    RUN_DIR.mkdir(parents=True, exist_ok=True)
    text = "".join(
        json.dumps(rows[key], ensure_ascii=False, sort_keys=True) + "\n"
        for key in sorted(rows)
    )
    CHECKPOINT_PATH.write_text(text, encoding="utf-8")


def call_id_for(lesson: str, image_name: str) -> str:
    return f"{lesson}::{image_name}"


def run_calls(limit: int | None) -> dict[str, dict[str, Any]]:
    checkpoints = read_checkpoints()
    llm = load_llm_module()
    llm.load_dotenv(ROOT)
    api_key = llm.load_key(ROOT)
    if api_key is None:
        raise RuntimeError("REALLMS_API_KEY is not configured")
    api_url = llm.resolve_api_url()
    ssl_ctx = llm.build_ssl_context()

    calls = 0
    for lesson, (_, pages) in TARGETS.items():
        for image_name, page_number, lesson_owned in pages:
            call_id = call_id_for(lesson, image_name)
            if call_id in checkpoints:
                continue
            if limit is not None and calls >= limit:
                continue
            image_path = PAGES_DIR / image_name
            if not image_path.is_file():
                raise RuntimeError(f"page image is missing: {image_path}")
            result = llm.call_api_messages_result(
                messages_for(image_path),
                api_key=api_key,
                api_url=api_url,
                model=MODEL,
                ssl_ctx=ssl_ctx,
                retries=RETRIES,
                timeout=TIMEOUT,
                max_tokens=MAX_TOKENS,
            )
            checkpoints[call_id] = {
                "call_id": call_id,
                "lesson": lesson,
                "image": f"hermes/app/runtime/experiments/vision_fraction_recovery/{RUN_DATE}/pages/{image_name}",
                "page_number": page_number,
                "lesson_owned": lesson_owned,
                "model": MODEL,
                "api": "reallms",
                "date": RUN_DATE,
                "response": result.to_dict(),
            }
            calls += 1
            write_checkpoints(checkpoints)
            print(f"called {call_id}: outcome={result.outcome}")

    for item in TARGETED_ITEMS:
        lesson = item["lesson"]
        call_id = targeted_call_id(lesson, item["image"], item["needles"])
        if call_id in checkpoints:
            continue
        if limit is not None and calls >= limit:
            continue
        md_path, _ = TARGETS[lesson]
        md_lines = (ROOT / md_path).read_text(encoding="utf-8").splitlines()
        line_number, raw_line, context = locate_targeted_hole(md_lines, item["needles"])
        image_path = PAGES_DIR / item["image"]
        if not image_path.is_file():
            raise RuntimeError(f"page image is missing: {image_path}")
        result = llm.call_api_messages_result(
            messages_for_targeted(image_path, context),
            api_key=api_key,
            api_url=api_url,
            model=MODEL,
            ssl_ctx=ssl_ctx,
            retries=RETRIES,
            timeout=TIMEOUT,
            max_tokens=MAX_TOKENS,
        )
        checkpoints[call_id] = {
            "call_id": call_id,
            "lesson": lesson,
            "image": f"hermes/app/runtime/experiments/vision_fraction_recovery/{RUN_DATE}/pages/{item['image']}",
            "page_number": item["page_number"],
            "lesson_owned": True,
            "targeted": True,
            "line_number": line_number,
            "markdown_excerpt": raw_line,
            "context": context,
            "model": MODEL,
            "api": "reallms",
            "date": RUN_DATE,
            "response": result.to_dict(),
        }
        calls += 1
        write_checkpoints(checkpoints)
        print(f"called {call_id}: outcome={result.outcome}")
    return checkpoints


FRACTION_KEYS = {"numerator", "denominator", "fragment"}
INVALID_ESCAPE_RE = re.compile(r'\\(?!["\\/bfnrt]|u[0-9a-fA-F]{4})')


def _strip_fence(content: str) -> str:
    stripped = content.strip()
    if not stripped.startswith("```"):
        return stripped
    lines = stripped.splitlines()
    if lines and lines[0].startswith("```"):
        lines = lines[1:]
    if lines and lines[-1].strip() == "```":
        lines = lines[:-1]
    return "\n".join(lines)


def _first_json_object(content: str) -> dict[str, Any] | None:
    """Decode the first balanced {...} object in content, tolerating a code
    fence or surrounding prose the model added despite being told not to."""
    candidate = _strip_fence(content)
    for text in (candidate, INVALID_ESCAPE_RE.sub(r"\\\\", candidate)):
        try:
            value = json.loads(text)
            if isinstance(value, dict):
                return value
        except json.JSONDecodeError:
            pass
    for start, character in enumerate(content):
        if character != "{":
            continue
        depth = 0
        for end in range(start, len(content)):
            token = content[end]
            if token == "{":
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
    return None


def parse_fractions(content: str) -> list[dict[str, Any]] | None:
    candidate = _strip_fence(content)
    value = None
    for text in (candidate, INVALID_ESCAPE_RE.sub(r"\\\\", candidate)):
        try:
            value = json.loads(text)
            break
        except json.JSONDecodeError:
            continue
    if value is None:
        return None
    if not isinstance(value, dict) or set(value) != {"fractions"}:
        return None
    items = value["fractions"]
    if not isinstance(items, list):
        return None
    return items


def find_anchor(md_lines: list[str], fragment_no_frac: str) -> tuple[int, str] | str:
    """Locate the UNIQUE Markdown line whose whitespace-normalized text
    contains the fragment (fraction placeholder already removed).

    The Docling/pdftotext conversion behind this corpus interleaves a
    two-column PDF onto single lines, so several distinct holes (different
    student clues, different strip colors) often share near-identical
    surrounding words once a fraction is blanked out ("greater than ___",
    "pieces that are ___ foot long."). A fragment that matches more than one
    place in the file is not a location claim this receipt can stand behind
    -- it is reported as ambiguous rather than resolved by guessing which
    occurrence the model meant. Tries single-line matches first (the common
    case on this corpus), then a two-line join for a sentence that wraps
    across a line break, each tier requiring a UNIQUE match on its own.
    """
    needle = normalize_ws(fragment_no_frac)
    if len(needle) < 6:
        return "fragment_too_short"
    single = [
        (index + 1, line.strip())
        for index, line in enumerate(md_lines)
        if needle in normalize_ws(line)
    ]
    if single:
        if len({line_number for line_number, _ in single}) > 1:
            return "ambiguous_anchor"
        return single[0]
    windowed = [
        (index + 1, md_lines[index].strip() or md_lines[index + 1].strip())
        for index in range(len(md_lines) - 1)
        if needle in normalize_ws(md_lines[index] + " " + md_lines[index + 1])
    ]
    if not windowed:
        return "no_text_anchor"
    if len({line_number for line_number, _ in windowed}) > 1:
        return "ambiguous_anchor"
    return windowed[0]


def quote_atom(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "\\'") + "'"


def quote_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def _resolve_line_collisions(
    accepted: list[dict[str, Any]], held: list[dict[str, Any]]
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    """When a targeted, single-fraction reading and a broad, many-fraction
    reading anchor to the SAME Markdown line for the same lesson but
    disagree on the value, keep the targeted one and hold the broad one.

    The targeted pass exists BECAUSE the broad pass misread five of six
    holes it was checked against by direct re-inspection of the source page
    (2026-08-20); a broad-pass row that lands on the same hole a targeted
    row already answers, with a different value, is exactly that failure
    mode recurring, not independent evidence."""
    by_line: dict[tuple[str, int], list[dict[str, Any]]] = {}
    for row in accepted:
        by_line.setdefault((row["lesson"], row["line_number"]), []).append(row)
    superseded_ids = set()
    for rows in by_line.values():
        targeted_rows = [row for row in rows if row["targeted"]]
        if not targeted_rows:
            continue
        targeted_values = {(row["numerator"], row["denominator"]) for row in targeted_rows}
        for row in rows:
            if not row["targeted"] and (row["numerator"], row["denominator"]) not in targeted_values:
                superseded_ids.add(id(row))
    resolved_accepted = [row for row in accepted if id(row) not in superseded_ids]
    for row in accepted:
        if id(row) in superseded_ids:
            held.append(
                {
                    "lesson": row["lesson"],
                    "call_id": row["call_id"],
                    "image": row["image"],
                    "page_number": row["page_number"],
                    "lesson_owned": row["lesson_owned"],
                    "model": row["model"],
                    "api": row["api"],
                    "date": row["date"],
                    "reason": "superseded_by_targeted_reading",
                    "numerator": row["numerator"],
                    "denominator": row["denominator"],
                    "fragment": row["fragment"],
                }
            )
    return resolved_accepted, held


def build_rows(checkpoints: dict[str, dict[str, Any]]) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    accepted: list[dict[str, Any]] = []
    held: list[dict[str, Any]] = []
    seen: dict[tuple[str, int, int], bool] = {}
    md_cache: dict[str, list[str]] = {}

    for call_id in sorted(checkpoints):
        row = checkpoints[call_id]
        lesson = row["lesson"]
        md_path, _ = TARGETS[lesson]
        if md_path not in md_cache:
            md_cache[md_path] = (ROOT / md_path).read_text(encoding="utf-8").splitlines()
        md_lines = md_cache[md_path]

        response = row["response"]
        base_held = {
            "lesson": lesson,
            "call_id": call_id,
            "image": row["image"],
            "page_number": row["page_number"],
            "lesson_owned": row["lesson_owned"],
            "model": row["model"],
            "api": row["api"],
            "date": row["date"],
        }
        if response.get("outcome") != "ok":
            held.append({**base_held, "reason": f"outcome_{response.get('outcome')}", "fragment": ""})
            continue

        if row.get("targeted"):
            context = row["context"]
            value = _first_json_object(response.get("content", ""))
            if (
                not isinstance(value, dict)
                or set(value) != {"numerator", "denominator"}
                or not isinstance(value.get("numerator"), int)
                or isinstance(value.get("numerator"), bool)
                or not isinstance(value.get("denominator"), int)
                or isinstance(value.get("denominator"), bool)
                or value["numerator"] <= 0
                or value["denominator"] <= 0
            ):
                held.append({**base_held, "reason": "targeted_malformed", "fragment": context})
                continue
            numerator, denominator = value["numerator"], value["denominator"]
            key = (lesson, numerator, denominator)
            if key in seen:
                continue
            seen[key] = True
            accepted.append(
                {
                    **base_held,
                    "numerator": numerator,
                    "denominator": denominator,
                    "fragment": context,
                    "line_number": row["line_number"],
                    "markdown_excerpt": row["markdown_excerpt"],
                    "markdown_path": md_path,
                    "targeted": True,
                }
            )
            continue

        items = parse_fractions(response.get("content", ""))
        if items is None:
            held.append({**base_held, "reason": "invalid_json", "fragment": response.get("content", "")[:200]})
            continue
        if not items:
            held.append({**base_held, "reason": "no_fractions_reported", "fragment": ""})
            continue

        for item in items:
            if not isinstance(item, dict) or set(item) != FRACTION_KEYS:
                held.append({**base_held, "reason": "malformed_item", "fragment": str(item)[:200]})
                continue
            numerator, denominator, fragment = (
                item["numerator"],
                item["denominator"],
                item["fragment"],
            )
            if (
                not isinstance(numerator, int)
                or isinstance(numerator, bool)
                or not isinstance(denominator, int)
                or isinstance(denominator, bool)
                or numerator <= 0
                or denominator <= 0
                or not isinstance(fragment, str)
            ):
                held.append({**base_held, "reason": "malformed_fraction", "fragment": str(fragment)[:200]})
                continue
            if PLACEHOLDER not in fragment:
                held.append({**base_held, "reason": "no_placeholder", "fragment": fragment})
                continue
            fragment_no_frac = fragment.replace(PLACEHOLDER, " ")
            anchor = find_anchor(md_lines, fragment_no_frac)
            if isinstance(anchor, str):
                held.append(
                    {
                        **base_held,
                        "reason": anchor,
                        "numerator": numerator,
                        "denominator": denominator,
                        "fragment": fragment,
                    }
                )
                continue
            line_number, excerpt = anchor
            key = (lesson, numerator, denominator)
            if key in seen:
                # Already have an accepted anchor for this (lesson, fraction);
                # a repeat reading is not additional evidence.
                continue
            seen[key] = True
            accepted.append(
                {
                    **base_held,
                    "numerator": numerator,
                    "denominator": denominator,
                    "fragment": fragment,
                    "line_number": line_number,
                    "markdown_excerpt": excerpt,
                    "markdown_path": md_path,
                    "targeted": False,
                }
            )
    return _resolve_line_collisions(accepted, held)


def generated_source(accepted: list[dict[str, Any]], held: list[dict[str, Any]]) -> str:
    lesson_owned_accepted = sum(row["lesson_owned"] for row in accepted)
    lessons = sorted({row["lesson"] for row in accepted} | {row["lesson"] for row in held})
    by_reason: dict[str, int] = {}
    for row in held:
        by_reason[row["reason"]] = by_reason.get(row["reason"], 0) + 1

    lines = [
        "/** <module> Vision-recovered fraction operands",
        " *",
        " * Six lessons' teacher-guide Markdown lost every printed fraction glyph in",
        " * the PDF-to-text conversion pass -- a run of bare spaces stands where the",
        " * glyph was. Each accepted row below reads the glyph off the original PDF",
        " * page (rendered to an image, never re-typeset) with a REALLMS vision call,",
        " * then keeps only a reading whose five-to-ten-word surrounding fragment --",
        " * with the fraction's own placeholder removed -- reproduces a line of the",
        " * lesson's own Markdown after whitespace normalization. That reproduction",
        " * is the receipt: the model supplies what the destroyed glyph was: the",
        " * surviving Markdown text confirms where it stood. A reading with no such",
        " * anchor is held, never discarded, with its rejection reason recorded.",
        " *",
        " * lesson_owned is false for a reading recovered from teacher-facing Launch",
        " * or Activity Synthesis commentary rather than the lesson's own",
        " * student-facing text; IM-G5-U3-L19's Student Task Statement is a blank",
        " * digit-fill template with no printed fraction of its own, so its rows (if",
        " * any) carry lesson_owned=false and build_lesson_representation_evidence.py",
        " * excludes them, preserving that lesson's existing no-host chart refusal.",
        " *",
        " * Generated by scripts/curriculum/recover_vision_fractions.py from",
        f" * {CHECKPOINT_PATH.relative_to(ROOT).as_posix()} (checked in as a runtime",
        " * experiment artifact). Do not edit by hand.",
        " */",
        ":- module(vision_fraction_recovery,",
        "          [ recovered_fraction/5,",
        "            held_fraction_reading/4,",
        "            vision_fraction_recovery_summary/1,",
        "            check_vision_fraction_recovery/0",
        "          ]).",
        "",
        ":- dynamic recovered_fraction/5, held_fraction_reading/4.",
        "",
        (
            "vision_fraction_recovery_summary(summary{"
            f"lessons: {len(lessons)}, "
            f"accepted: {len(accepted)}, "
            f"lesson_owned_accepted: {lesson_owned_accepted}, "
            f"held: {len(held)}, "
            f"held_by_reason: {json.dumps(dict(sorted(by_reason.items())))}"
            "})."
        ),
        "",
    ]

    for row in accepted:
        anchor_term = (
            f"anchor(source({quote_atom(row['markdown_path'])}, line({row['line_number']})), "
            f"page({row['page_number']}), fragment({quote_string(row['fragment'])}), "
            f"markdown_excerpt({quote_string(row['markdown_excerpt'])}), "
            f"lesson_owned({'true' if row['lesson_owned'] else 'false'}))"
        )
        testimony_term = (
            f"testimony(model({row['model'].replace('-', '_').replace('.', '_').lower()}), "
            f"api({row['api']}), source_image({quote_atom(row['image'])}), "
            f"date({quote_atom(row['date'])}))"
        )
        receipt_term = "receipt(swipl_test([text_anchor_verified]))"
        lines.append(
            f"recovered_fraction({quote_atom(row['lesson'])}, frac({row['numerator']},{row['denominator']}), "
            f"{anchor_term}, {testimony_term}, {receipt_term})."
        )
    lines.append("")

    for row in held:
        detail_term = quote_string(row.get("fragment", ""))
        lines.append(
            f"held_fraction_reading({quote_atom(row['lesson'])}, {quote_atom(row['reason'])}, "
            f"detail({detail_term}), source_image({quote_atom(row['image'])}))."
        )
    lines.append("")

    lines.extend(
        [
            "%!  check_vision_fraction_recovery is semidet.",
            "%",
            "%   Re-verifies every accepted row's receipt: the cited Markdown file",
            "%   still exists and still contains the cited excerpt verbatim, and the",
            "%   accepted-row count matches the summary. A whole-file substring check",
            "%   (rather than a line-indexed one) sidesteps any disagreement between",
            "%   how different tools split this corpus's Markdown into lines --",
            "%   Python's str.splitlines() (used to derive Line and Excerpt when this",
            "%   store was generated) treats form-feed and other control characters",
            "%   as line breaks that a plain '\\n' split does not, so re-deriving line",
            "%   numbers here independently could disagree with generation-time",
            "%   numbers even when the excerpt genuinely still exists. Throws a",
            "%   specific error naming the failing row rather than silently failing.",
            "check_vision_fraction_recovery :-",
            "    aggregate_all(count, recovered_fraction(_, _, _, _, _), Accepted),",
            "    forall(",
            "        recovered_fraction(Lesson, Frac,",
            "                           anchor(source(Path, line(Line)), _, _,",
            "                                  markdown_excerpt(Excerpt), _), _, _),",
            "        verify_recovered_anchor(Lesson, Frac, Path, Line, Excerpt)),",
            "    vision_fraction_recovery_summary(Summary),",
            "    get_dict(accepted, Summary, Accepted),",
            "    format('PASS vision fraction recovery: ~w accepted rows re-verified~n', [Accepted]).",
            "",
            "verify_recovered_anchor(Lesson, Frac, Path, Line, Excerpt) :-",
            "    (   exists_file(Path)",
            "    ->  true",
            "    ;   throw(error(vision_fraction_recovery_missing_source(Lesson, Frac, Path), _))",
            "    ),",
            "    read_file_to_string(Path, Text, [encoding(utf8)]),",
            "    (   sub_string(Text, _, _, _, Excerpt)",
            "    ->  true",
            "    ;   throw(error(vision_fraction_recovery_anchor_failed(Lesson, Frac, Path, Line), _))",
            "    ).",
            "",
        ]
    )
    return "\n".join(lines).rstrip() + "\n"


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--emit-only", action="store_true", help="skip API calls; re-derive the store")
    parser.add_argument("--limit", type=int, default=None, help="cap new API calls this run")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    if args.emit_only:
        checkpoints = read_checkpoints()
        if not checkpoints:
            raise RuntimeError(f"no checkpoints at {CHECKPOINT_PATH}; run without --emit-only first")
    else:
        checkpoints = run_calls(args.limit)

    accepted, held = build_rows(checkpoints)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(generated_source(accepted, held), encoding="utf-8")
    summary = {
        "output": OUTPUT.relative_to(ROOT).as_posix(),
        "calls": len(checkpoints),
        "accepted": len(accepted),
        "lesson_owned_accepted": sum(row["lesson_owned"] for row in accepted),
        "held": len(held),
        "by_lesson": {
            lesson: sum(1 for row in accepted if row["lesson"] == lesson) for lesson in TARGETS
        },
    }
    print(json.dumps(summary, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
