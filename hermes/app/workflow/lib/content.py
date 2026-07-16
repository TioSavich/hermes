"""Extract and interpret student homework files.

PDF and DOCX submissions are sent directly to Gemma 4 through reallms first,
with the lesson/activity page and monitoring chart attached as context. If a
deployment rejects direct document payloads, the code falls back to local text
extraction and image/PDF-page rendering when those tools are available.

The functions here do NOT match files to students. That is `content.py`'s
job, using the roster.
"""

from __future__ import annotations

import base64
import json
import mimetypes
import os
import re
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
import zipfile
from dataclasses import dataclass
from pathlib import Path

from . import api

WORD_NS = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"
IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp", ".tif", ".tiff"}
DOCUMENT_EXTS = {".pdf", ".docx"}
DEFAULT_MAX_VISION_IMAGES = 12
DEFAULT_MAX_VISION_PAGES = 8
DEFAULT_MAX_CHART_CHARS = 18000
DEFAULT_MAX_ACTIVITY_CHARS = 12000
MONITORING_ALIASES = {
    "1_1_1_folding_polygons": "monitoring/unit1/1-1-1_0-dot-1-1-folding-polygons-from-a-circle.md",
    "1_1_1_0_1_1_folding_polygons_from_a_circle": "monitoring/unit1/1-1-1_0-dot-1-1-folding-polygons-from-a-circle.md",
    "folding_polygons": "monitoring/unit1/1-1-1_0-dot-1-1-folding-polygons-from-a-circle.md",
}
ACTIVITY_ALIASES = {
    "1_1_1_folding_polygons": "activities/1_1_1_folding_polygons.md",
    "1_1_1_0_1_1_folding_polygons_from_a_circle": "activities/1_1_1_folding_polygons.md",
    "folding_polygons": "activities/1_1_1_folding_polygons.md",
}


@dataclass
class ImagePayload:
    label: str
    data: bytes
    mime_type: str


@dataclass
class ExtractionResult:
    text: str
    source_label: str
    profile_note: str = ""
    instructor_note: str = ""
    diagnostics: list[str] | None = None


def _env_int(name: str, default: int) -> int:
    raw = os.environ.get(name, "").strip()
    if not raw:
        return default
    try:
        return max(0, int(raw))
    except ValueError:
        return default


def _mime_for_path(path: Path) -> str:
    guessed, _ = mimetypes.guess_type(path.name)
    return guessed or "application/octet-stream"


def _norm_key(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", value.lower()).strip("_")


def _image_part(image: ImagePayload) -> dict:
    encoded = base64.b64encode(image.data).decode("ascii")
    return {
        "type": "image_url",
        "image_url": {
            "url": f"data:{image.mime_type};base64,{encoded}",
        },
    }


def _document_data_url(path: Path) -> str:
    encoded = base64.b64encode(path.read_bytes()).decode("ascii")
    mime_type = _mime_for_path(path)
    return f"data:{mime_type};base64,{encoded}"


def _document_parts(path: Path) -> list[tuple[str, dict]]:
    data_url = _document_data_url(path)
    variants = [
        (
            "file",
            {
                "type": "file",
                "file": {
                    "filename": path.name,
                    "file_data": data_url,
                },
            },
        ),
        (
            "input_file",
            {
                "type": "input_file",
                "filename": path.name,
                "file_data": data_url,
            },
        ),
        (
            "file_flat",
            {
                "type": "file",
                "filename": path.name,
                "file_data": data_url,
            },
        ),
        (
            "image_url_data_url",
            {
                "type": "image_url",
                "image_url": {
                    "url": data_url,
                },
            },
        ),
    ]
    preferred = os.environ.get("REALLMS_DOCUMENT_PART_TYPE", "").strip()
    if preferred:
        return [(name, part) for name, part in variants if name == preferred or part.get("type") == preferred]
    return variants


def _document_part(path: Path) -> dict:
    """Backward-compatible single document part helper."""
    parts = _document_parts(path)
    return parts[0][1]


def _interpretation_system_prompt(context_instruction: str = "") -> str:
    return (
        "You interpret student geometry homework for instructor monitoring and "
        "profile evidence. Use the lesson/activity and monitoring chart as context. "
        "Read all attached document pages and images directly when available. "
        "Transcribe visible student claims as best you can, describe diagrams, "
        "labels, measurements, equations, and sketches, and name uncertainty. "
        "Do not grade. Do not invent missing work." + context_instruction
    )


def _context_instruction(
    pack_root: Path,
    assignment_id: str | None,
    *,
    activity_context: str = "",
    activity_label: str | None = None,
    text_context: str = "",
) -> str:
    chart_context, chart_label = read_monitoring_context(pack_root, assignment_id)
    context_instruction = ""
    if activity_context:
        context_instruction += (
            "\n\nUse the activity page below to understand what the student was "
            "asked to do. Attend to whether the response addresses the requested "
            "definitions, area investigation, sketches/explanations, and takeaways.\n\n"
            f"ACTIVITY PAGE ({activity_label or 'activity'}):\n{activity_context}"
        )
    if chart_context:
        context_instruction += (
            "\n\nUse the monitoring chart below as interpretive context. Notice "
            "the listed strategies, misconceptions, mathematical purpose, and "
            "where-to-spot cues when they are visible in the student's work. "
            "Do not force a chart category when the file does not support it.\n\n"
            f"MONITORING CHART ({chart_label}):\n{chart_context}"
        )
    if text_context:
        context_instruction += (
            "\n\nText already extracted from this student file is included below. "
            "Use it together with the attached document/images; do not repeat it "
            "verbatim unless it helps preserve a student claim.\n\n"
            f"EXTRACTED STUDENT TEXT:\n{text_context[:12000]}"
        )
    return context_instruction


def _student_work_instructions(path: Path) -> str:
    return (
        f"File: {path.name}\n"
        "Return concise Markdown with these sections:\n"
        "1. Rendered student work: claims, definitions, answers, diagrams, labels, and explanations.\n"
        "2. Profile evidence: what this suggests about the student's geometric understanding and habits of reasoning.\n"
        "3. Instructor monitoring note: non-graded flags about prompt-fit, likely misconceptions, missing work, or productive strategies.\n"
        "Focus on mathematical content: shapes, angle marks, side lengths, formulas, written explanations, sketches, area fractions, and final answers."
    )


def resolve_monitoring_chart(pack_root: Path, assignment_id: str | None) -> Path | None:
    """Find the monitoring chart that should guide visual interpretation."""
    if not assignment_id:
        return None
    key = _norm_key(assignment_id)
    candidates: list[str] = []

    if key in MONITORING_ALIASES:
        candidates.append(MONITORING_ALIASES[key])

    index_path = pack_root / "monitoring" / "INDEX.json"
    if index_path.exists():
        try:
            index = json.loads(index_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            index = {}
        if isinstance(index, dict):
            for raw_key, raw_path in index.items():
                if raw_key.startswith("_") or raw_path is None:
                    continue
                index_key = _norm_key(raw_key)
                if key == index_key or key in index_key or index_key in key:
                    candidates.append(str(raw_path))

    if not candidates:
        monitoring_dir = pack_root / "monitoring"
        if monitoring_dir.exists():
            for chart in sorted(monitoring_dir.glob("**/*.md")):
                chart_key = _norm_key(chart.stem)
                if key in chart_key or chart_key in key:
                    candidates.append(str(chart.relative_to(pack_root)))

    for candidate in candidates:
        chart_path = pack_root / candidate
        if chart_path.exists():
            return chart_path
    return None


def read_monitoring_context(pack_root: Path, assignment_id: str | None) -> tuple[str, str | None]:
    """Return a bounded monitoring-chart excerpt plus the chart path label."""
    chart_path = resolve_monitoring_chart(pack_root, assignment_id)
    if not chart_path:
        return "", None
    try:
        raw = chart_path.read_text(encoding="utf-8", errors="replace").strip()
    except OSError:
        return "", None
    max_chars = _env_int("REALLMS_MAX_CHART_CHARS", DEFAULT_MAX_CHART_CHARS)
    if max_chars <= 0:
        return "", str(chart_path.relative_to(pack_root))
    if len(raw) > max_chars:
        raw = raw[:max_chars].rstrip() + "\n\n[Monitoring chart truncated by REALLMS_MAX_CHART_CHARS.]"
    return raw, str(chart_path.relative_to(pack_root))


def resolve_activity_page(
    pack_root: Path,
    assignment_id: str | None,
    *,
    source_dir: Path | None = None,
    activity_page: Path | None = None,
) -> Path | None:
    """Find the lesson/activity page that should guide interpretation."""
    candidates: list[Path] = []
    if activity_page:
        candidates.append(activity_page if activity_page.is_absolute() else pack_root / activity_page)
    if source_dir:
        for name in ("_activity.md", "activity.md", "_lesson.md", "lesson.md"):
            candidates.append(source_dir / name)
    if assignment_id:
        key = _norm_key(assignment_id)
        if key in ACTIVITY_ALIASES:
            candidates.append(pack_root / ACTIVITY_ALIASES[key])
        candidates.append(pack_root / "activities" / f"{key}.md")
        pages_dir = pack_root / "pages"
        if pages_dir.exists():
            for page in sorted(pages_dir.glob("*.md")):
                page_key = _norm_key(page.stem)
                if key in page_key or page_key in key:
                    candidates.append(page)
    for candidate in candidates:
        if candidate.exists() and candidate.is_file():
            return candidate
    return None


def read_activity_context(
    pack_root: Path,
    assignment_id: str | None,
    *,
    source_dir: Path | None = None,
    activity_page: Path | None = None,
) -> tuple[str, str | None]:
    """Return a bounded lesson/activity excerpt plus its path label."""
    page = resolve_activity_page(pack_root, assignment_id, source_dir=source_dir, activity_page=activity_page)
    if not page:
        return "", None
    try:
        raw = page.read_text(encoding="utf-8", errors="replace").strip()
    except OSError:
        return "", None
    max_chars = _env_int("REALLMS_MAX_ACTIVITY_CHARS", DEFAULT_MAX_ACTIVITY_CHARS)
    if max_chars <= 0:
        return "", str(page)
    if len(raw) > max_chars:
        raw = raw[:max_chars].rstrip() + "\n\n[Activity page truncated by REALLMS_MAX_ACTIVITY_CHARS.]"
    try:
        label = str(page.relative_to(pack_root))
    except ValueError:
        label = str(page)
    return raw, label


def extract_docx(path: Path, diagnostics: list[str] | None = None) -> str:
    """Return the body text of a .docx file. One paragraph per line."""
    paragraphs: list[str] = []
    with zipfile.ZipFile(path) as zf:
        try:
            xml_bytes = zf.read("word/document.xml")
        except KeyError:
            if diagnostics is not None:
                diagnostics.append("docx document.xml missing")
            return ""
    root = ET.fromstring(xml_bytes)
    for para in root.iter(f"{WORD_NS}p"):
        runs: list[str] = []
        for t in para.iter(f"{WORD_NS}t"):
            if t.text:
                runs.append(t.text)
        text = "".join(runs).strip()
        if text:
            paragraphs.append(text)
    text = "\n".join(paragraphs).strip()
    if diagnostics is not None:
        diagnostics.append(f"docx text chars: {len(text)}")
    return text


def extract_docx_images(path: Path, diagnostics: list[str] | None = None) -> list[ImagePayload]:
    """Return embedded image files from a docx, preserving their package names."""
    out: list[ImagePayload] = []
    with zipfile.ZipFile(path) as zf:
        for name in sorted(zf.namelist()):
            media_path = Path(name)
            if not name.startswith("word/media/") or media_path.suffix.lower() not in IMAGE_EXTS:
                continue
            out.append(
                ImagePayload(
                    label=media_path.name,
                    data=zf.read(name),
                    mime_type=_mime_for_path(media_path),
                )
            )
    if diagnostics is not None:
        diagnostics.append(f"docx embedded images: {len(out)}")
    return out


def extract_pdf(path: Path, diagnostics: list[str] | None = None) -> str:
    """Return the text of a .pdf using poppler's pdftotext. Empty on failure."""
    pdftotext = shutil.which("pdftotext")
    if not pdftotext:
        if diagnostics is not None:
            diagnostics.append("pdftotext not found; PDF text extraction skipped")
        return ""
    try:
        result = subprocess.run(
            [pdftotext, "-layout", str(path), "-"],
            capture_output=True,
            text=True,
            timeout=60,
        )
    except (OSError, subprocess.SubprocessError):
        if diagnostics is not None:
            diagnostics.append("pdftotext failed before completion")
        return ""
    if result.returncode != 0:
        if diagnostics is not None:
            diagnostics.append(f"pdftotext exit {result.returncode}: {result.stderr.strip()[:200]}")
        return ""
    text = result.stdout.strip()
    if diagnostics is not None:
        diagnostics.append(f"pdf text chars: {len(text)}")
    return text


def render_pdf_pages(path: Path, diagnostics: list[str] | None = None) -> list[ImagePayload]:
    """Render PDF pages to PNG files via poppler's pdftoppm for visual reading."""
    pdftoppm = shutil.which("pdftoppm")
    if not pdftoppm:
        if diagnostics is not None:
            diagnostics.append("pdftoppm not found; PDF page vision skipped")
        return []
    max_pages = _env_int("REALLMS_MAX_VISION_PAGES", DEFAULT_MAX_VISION_PAGES)
    if max_pages <= 0:
        if diagnostics is not None:
            diagnostics.append("REALLMS_MAX_VISION_PAGES=0; PDF page vision skipped")
        return []
    with tempfile.TemporaryDirectory(prefix="n103_pdf_pages_") as tmp:
        prefix = Path(tmp) / "page"
        cmd = [pdftoppm, "-png", "-r", "150", "-f", "1", "-l", str(max_pages), str(path), str(prefix)]
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        except (OSError, subprocess.SubprocessError):
            if diagnostics is not None:
                diagnostics.append("pdftoppm failed before completion")
            return []
        if result.returncode != 0:
            if diagnostics is not None:
                diagnostics.append(f"pdftoppm exit {result.returncode}: {result.stderr.strip()[:200]}")
            return []
        out: list[ImagePayload] = []
        for rendered in sorted(Path(tmp).glob("page-*.png")):
            out.append(
                ImagePayload(
                    label=rendered.name,
                    data=rendered.read_bytes(),
                    mime_type="image/png",
                )
            )
        if diagnostics is not None:
            diagnostics.append(f"pdf rendered pages for vision: {len(out)}")
        return out


def extract_image_file(path: Path) -> list[ImagePayload]:
    try:
        return [ImagePayload(label=path.name, data=path.read_bytes(), mime_type=_mime_for_path(path))]
    except OSError:
        return []


def interpret_document_direct(
    path: Path,
    pack_root: Path,
    *,
    assignment_id: str | None = None,
    activity_context: str = "",
    activity_label: str | None = None,
    diagnostics: list[str] | None = None,
) -> str:
    """Send a PDF/DOCX directly to Gemma 4 through reallms."""
    api.load_dotenv(pack_root)
    api_key = os.environ.get("REALLMS_API_KEY", "").strip()
    if not api_key or api_key.startswith("sk-PASTE") or api_key in {"YOUR_KEY_HERE", "PASTE_YOUR_KEY_HERE"}:
        if diagnostics is not None:
            diagnostics.append("direct document interpretation skipped: REALLMS_API_KEY missing")
        sys.stderr.write(f"  direct document interpretation skipped for {path.name}: set REALLMS_API_KEY\n")
        return ""
    context_instruction = _context_instruction(
        pack_root,
        assignment_id,
        activity_context=activity_context,
        activity_label=activity_label,
    )
    variants = _document_parts(path)
    if diagnostics is not None:
        diagnostics.append("direct document variants: " + ", ".join(name for name, _ in variants))
    last_error = ""
    for variant_name, document_part in variants:
        messages = [
            {"role": "system", "content": _interpretation_system_prompt(context_instruction)},
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": _student_work_instructions(path)},
                    document_part,
                ],
            },
        ]
        try:
            reply = api.call_api_messages(
                messages,
                api_key=api_key,
                api_url=api.resolve_api_url(),
                model=api.resolve_model(),
                ssl_ctx=api.build_ssl_context(),
                retries=1,
                timeout=900,
                fail_on_error=False,
            ).strip()
        except Exception as exc:
            last_error = str(exc)
            if diagnostics is not None:
                diagnostics.append(f"direct document variant {variant_name} failed: {last_error[:240]}")
            continue
        if diagnostics is not None:
            diagnostics.append(f"direct document variant {variant_name} chars: {len(reply)}")
        if reply:
            return reply
    if last_error:
        if diagnostics is not None:
            diagnostics.append(f"direct document interpretation failed across variants: {last_error[:240]}")
    return ""


def describe_images(
    path: Path,
    images: list[ImagePayload],
    pack_root: Path,
    *,
    assignment_id: str | None = None,
    activity_context: str = "",
    activity_label: str | None = None,
    text_context: str = "",
) -> str:
    """Ask Gemma 4 through reallms to transcribe and describe homework images."""
    if not images:
        return ""
    max_images = _env_int("REALLMS_MAX_VISION_IMAGES", DEFAULT_MAX_VISION_IMAGES)
    if max_images <= 0:
        return ""
    selected = images[:max_images]
    omitted = len(images) - len(selected)

    api.load_dotenv(pack_root)
    api_key = os.environ.get("REALLMS_API_KEY", "").strip()
    if not api_key or api_key.startswith("sk-PASTE") or api_key in {"YOUR_KEY_HERE", "PASTE_YOUR_KEY_HERE"}:
        sys.stderr.write(f"  vision skipped for {path.name}: set REALLMS_API_KEY to read images\n")
        return ""

    api_url = api.resolve_api_url()
    model = api.resolve_model()
    ssl_ctx = api.build_ssl_context()
    context_instruction = _context_instruction(
        pack_root,
        assignment_id,
        activity_context=activity_context,
        activity_label=activity_label,
        text_context=text_context,
    )
    system_prompt = _interpretation_system_prompt(context_instruction)
    text_part = {
        "type": "text",
        "text": _student_work_instructions(path),
    }
    user_parts = [text_part]
    for image in selected:
        user_parts.append({"type": "text", "text": f"Image: {image.label}"})
        user_parts.append(_image_part(image))

    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_parts},
    ]
    try:
        description = api.call_api_messages(
            messages,
            api_key=api_key,
            api_url=api_url,
            model=model,
            ssl_ctx=ssl_ctx,
            retries=2,
            timeout=600,
        ).strip()
    except SystemExit:
        raise
    except Exception as exc:
        sys.stderr.write(f"  vision failed for {path.name}: {exc}\n")
        return ""
    if omitted:
        description += f"\n\n[Vision note: {omitted} additional image(s) omitted by REALLMS_MAX_VISION_IMAGES.]"
    return description


def interpret_text_only(
    path: Path,
    text: str,
    pack_root: Path,
    *,
    assignment_id: str | None = None,
    activity_context: str = "",
    activity_label: str | None = None,
) -> str:
    """Ask Gemma to interpret text-only student work against the activity/chart."""
    if not text.strip():
        return ""
    api.load_dotenv(pack_root)
    api_key = os.environ.get("REALLMS_API_KEY", "").strip()
    if not api_key or api_key.startswith("sk-PASTE") or api_key in {"YOUR_KEY_HERE", "PASTE_YOUR_KEY_HERE"}:
        sys.stderr.write(f"  interpretation skipped for {path.name}: set REALLMS_API_KEY\n")
        return ""
    system_prompt = _interpretation_system_prompt()
    user = [
        f"File: {path.name}",
        "Return concise Markdown with these sections:",
        "1. Rendered student work: preserve the student's claims and answers as best possible.",
        "2. Profile evidence: geometric understanding, reasoning habits, and notable language.",
        "3. Instructor monitoring note: possible misconceptions, nonresponse/off-prompt issues, or productive strategies.",
    ]
    if activity_context:
        user.append(f"\nACTIVITY PAGE ({activity_label or 'activity'}):\n{activity_context}")
    chart_context, chart_label = read_monitoring_context(pack_root, assignment_id)
    if chart_context:
        user.append(f"\nMONITORING CHART ({chart_label}):\n{chart_context}")
    user.append(f"\nSTUDENT TEXT:\n{text[:20000]}")
    try:
        return api.call_api(
            system_prompt,
            "\n".join(user),
            api_key=api_key,
            api_url=api.resolve_api_url(),
            model=api.resolve_model(),
            ssl_ctx=api.build_ssl_context(),
            retries=2,
            timeout=600,
        ).strip()
    except SystemExit:
        raise
    except Exception as exc:
        sys.stderr.write(f"  interpretation failed for {path.name}: {exc}\n")
        return ""


def extract_result(
    path: Path,
    *,
    vision: bool = True,
    interpret: bool = True,
    pack_root: Path | None = None,
    activity_page: Path | None = None,
) -> ExtractionResult:
    """Return structured extracted/interpreted content for one student file."""
    suffix = path.suffix.lower()
    diagnostics: list[str] = []
    text = ""
    images: list[ImagePayload] = []
    source_label = suffix.lstrip(".") or "unknown"
    root = pack_root or path.resolve().parent
    assignment_id = path.parent.name
    activity_context, activity_label = read_activity_context(
        root,
        assignment_id,
        source_dir=path.parent,
        activity_page=activity_page,
    )
    if activity_label:
        diagnostics.append(f"activity context: {activity_label}")
    else:
        diagnostics.append("activity context: none found")
    chart_path = resolve_monitoring_chart(root, assignment_id)
    if chart_path:
        try:
            diagnostics.append(f"monitoring chart: {chart_path.relative_to(root)}")
        except ValueError:
            diagnostics.append(f"monitoring chart: {chart_path}")
    else:
        diagnostics.append("monitoring chart: none found")

    interpreted = ""
    if interpret and suffix in DOCUMENT_EXTS:
        interpreted = interpret_document_direct(
            path,
            root,
            assignment_id=assignment_id,
            activity_context=activity_context,
            activity_label=activity_label,
            diagnostics=diagnostics,
        )
        if interpreted:
            return ExtractionResult(
                "## Gemma 4 direct document interpretation\n\n" + interpreted,
                f"{source_label}+direct-gemma",
                profile_note=interpreted,
                instructor_note=interpreted,
                diagnostics=diagnostics,
            )
        source_label += "+direct-failed"
        diagnostics.append("falling back to local extraction/rendering")

    if suffix == ".docx":
        text = extract_docx(path, diagnostics)
        images = extract_docx_images(path, diagnostics)
        if not source_label.startswith("docx"):
            source_label = "docx"
    elif suffix == ".pdf":
        text = extract_pdf(path, diagnostics)
        images = render_pdf_pages(path, diagnostics)
        if not source_label.startswith("pdf"):
            source_label = "pdf"
    elif suffix in (".txt", ".md"):
        try:
            text = path.read_text(encoding="utf-8", errors="replace").strip()
        except OSError:
            text = ""
    elif suffix in IMAGE_EXTS:
        images = extract_image_file(path)
        diagnostics.append(f"standalone images: {len(images)}")
        source_label = "image"
    else:
        return ExtractionResult("", source_label, diagnostics=diagnostics + ["unsupported file type"])

    if vision and images:
        interpreted = describe_images(
            path,
            images,
            root,
            assignment_id=assignment_id,
            activity_context=activity_context,
            activity_label=activity_label,
            text_context=text,
        )
        diagnostics.append(f"gemma vision chars: {len(interpreted)}")
    elif interpret and text:
        interpreted = interpret_text_only(
            path,
            text,
            root,
            assignment_id=assignment_id,
            activity_context=activity_context,
            activity_label=activity_label,
        )
        diagnostics.append(f"gemma text interpretation chars: {len(interpreted)}")

    pieces = []
    if text:
        pieces.append("## Extracted text\n\n" + text)
    if interpreted:
        pieces.append("## Gemma 4 activity-aware interpretation\n\n" + interpreted)
        source_label += "+gemma"
    elif vision and images:
        source_label += "+vision-skipped"
    elif interpret and text:
        source_label += "+interpretation-skipped"
    return ExtractionResult(
        "\n\n".join(pieces).strip(),
        source_label,
        profile_note=interpreted,
        instructor_note=interpreted,
        diagnostics=diagnostics,
    )


def extract_any(path: Path, *, vision: bool = True, pack_root: Path | None = None) -> tuple[str, str]:
    """Return (text, source_label). Empty text if format unsupported or extraction failed."""
    result = extract_result(path, vision=vision, interpret=True, pack_root=pack_root)
    return result.text, result.source_label
