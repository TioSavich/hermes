"""One uploaded artifact -> multimodal message parts for the transcriber.

A discussion can arrive as a photo of written work, a scanned worksheet, a
PDF or DOCX, an audio recording, or plain text. This module turns one such
upload (name, mime, raw bytes) into the content parts of a single Gemma
user message. Images and documents produce a proposed plain `Speaker: text`
transcript. Audio uses a strict timed-segment reply that the Prolog media
alignment boundary normalizes before any discourse analysis runs.

File reading is shared with the homework workflow: PDF page rendering and
DOCX extraction delegate to ``hermes.app.workflow.lib.content`` so the two
surfaces read documents the same way. Audio is new here: it rides as an
OpenAI-style ``input_audio`` part, and ``audio_parts_as_urls`` rewrites the
message for deployments that only accept the ``audio_url`` data-URI form.
"""
from __future__ import annotations

import base64
import json
import tempfile
from pathlib import Path

IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp",
              ".tif", ".tiff", ".heic", ".heif"}
AUDIO_EXTS = {".mp3", ".wav", ".m4a", ".aac", ".ogg", ".oga",
              ".opus", ".flac", ".webm", ".amr"}
TEXT_EXTS = {".txt", ".md", ".text", ".csv", ".tsv", ".vtt", ".srt", ".json"}

# Keep one upload's decoded payload bounded; the HTTP layer has its own cap
# but a hostile Content-Length should not be the only guard.
MAX_UPLOAD_BYTES = 48 * 1024 * 1024
MAX_TEXT_CHARS = 20000


def _suffix(name: str, mime: str) -> str:
    suffix = Path(str(name or "")).suffix.lower()
    if suffix:
        return suffix
    mime = (mime or "").lower()
    if mime.startswith("image/"):
        return "." + mime.split("/", 1)[1].split(";")[0]
    if mime.startswith("audio/"):
        return "." + mime.split("/", 1)[1].split(";")[0]
    if mime == "application/pdf":
        return ".pdf"
    return ""


def _mime(name: str, mime: str) -> str:
    if mime:
        return mime.split(";")[0].strip().lower()
    suffix = Path(str(name or "")).suffix.lower().lstrip(".")
    if suffix in {"jpg", "jpeg"}:
        return "image/jpeg"
    if f".{suffix}" in IMAGE_EXTS:
        return f"image/{suffix}"
    if f".{suffix}" in AUDIO_EXTS:
        return f"audio/{suffix}"
    return "application/octet-stream"


def _image_part(data: bytes, mime: str) -> dict:
    encoded = base64.b64encode(data).decode("ascii")
    return {"type": "image_url", "image_url": {"url": f"data:{mime};base64,{encoded}"}}


def _audio_part(data: bytes, name: str, mime: str) -> dict:
    """OpenAI-style input_audio part. The format tag is the file extension;
    deployments that want the data-URI form instead get it via
    audio_parts_as_urls, which reads the mime stored alongside."""
    suffix = _suffix(name, mime).lstrip(".") or "wav"
    return {
        "type": "input_audio",
        "input_audio": {
            "data": base64.b64encode(data).decode("ascii"),
            "format": suffix,
        },
        # Carried for the audio_url fallback; harmless extra key otherwise.
        "x_mime": _mime(name, mime),
    }


def audio_parts_as_urls(parts: list[dict]) -> list[dict]:
    """Rewrite input_audio parts to the audio_url data-URI form (the shape
    some OpenAI-compatible servers accept instead). Non-audio parts pass
    through unchanged."""
    out = []
    for part in parts:
        if part.get("type") == "input_audio":
            audio = part.get("input_audio") or {}
            mime = part.get("x_mime") or f"audio/{audio.get('format', 'wav')}"
            out.append({
                "type": "audio_url",
                "audio_url": {"url": f"data:{mime};base64,{audio.get('data', '')}"},
            })
        else:
            out.append(part)
    return out


def has_audio(parts: list[dict]) -> bool:
    return any(p.get("type") in ("input_audio", "audio_url") for p in parts)


def timed_segments_from_reply(reply: str) -> list[dict]:
    """Read the strict top-level JSON contract used for audio alignment.

    Segment field validation belongs to Prolog. This parser only removes an
    optional JSON code fence and makes sure no second top-level payload can be
    smuggled past the application boundary.
    """
    text = str(reply or "").strip()
    if text.startswith("```") and text.endswith("```"):
        lines = text.splitlines()
        if len(lines) >= 3:
            text = "\n".join(lines[1:-1]).strip()
    try:
        payload = json.loads(text)
    except json.JSONDecodeError as exc:
        raise ValueError(f"timed transcription was not valid JSON ({exc})") from exc
    if not isinstance(payload, dict) or set(payload) != {"segments"}:
        raise ValueError("timed transcription must contain only a segments array")
    segments = payload["segments"]
    if not isinstance(segments, list):
        raise ValueError("timed transcription segments must be an array")
    return segments


def _text_part(data: bytes, notes: list[str]) -> list[dict]:
    text = data.decode("utf-8", errors="replace").strip()
    if not text:
        return []
    if len(text) > MAX_TEXT_CHARS:
        notes.append(f"text truncated at {MAX_TEXT_CHARS} characters")
        text = text[:MAX_TEXT_CHARS]
    return [{"type": "text", "text": text}]


def _document_parts(data: bytes, suffix: str, notes: list[str]) -> tuple[list[dict], str]:
    """PDF/DOCX via the homework workflow's extractors, which want a path."""
    from hermes.app.workflow.lib import content as contentlib

    parts: list[dict] = []
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=True) as handle:
        handle.write(data)
        handle.flush()
        path = Path(handle.name)
        if suffix == ".pdf":
            pages = contentlib.render_pdf_pages(path, notes)
            if pages:
                for page in pages:
                    parts.append({"type": "text", "text": f"PDF page: {page.label}"})
                    parts.append(_image_part(page.data, page.mime_type))
                return parts, f"pdf:{len(pages)}pages"
            text = contentlib.extract_pdf(path, notes)
            if text:
                notes.append("pdf pages could not be rendered; text layer used")
                return ([{"type": "text", "text": text[:MAX_TEXT_CHARS]}],
                        "pdf:text-only")
            return [], "pdf:unreadable"
        # .docx
        try:
            text = contentlib.extract_docx(path, notes)
        except Exception as exc:  # noqa: BLE001 — a bad zip is a user file, not a crash
            notes.append(f"docx text extraction failed: {exc}")
            text = ""
        try:
            images = contentlib.extract_docx_images(path, notes)
        except Exception as exc:  # noqa: BLE001
            notes.append(f"docx image extraction failed: {exc}")
            images = []
        if text:
            parts.append({"type": "text", "text": f"DOCX text:\n{text[:MAX_TEXT_CHARS]}"})
        for image in images:
            parts.append({"type": "text", "text": f"DOCX embedded image: {image.label}"})
            parts.append(_image_part(image.data, image.mime_type))
        if not parts:
            return [], "docx:unreadable"
        return parts, f"docx:text+{len(images)}img"


def parts_for_upload(name: str, mime: str, data: bytes,
                     notes: list[str]) -> tuple[list[dict], str]:
    """Build the multimodal content parts for one upload.

    Returns (parts, render_label). An empty parts list means the file could
    not be read in any form; the label says which route refused it and
    ``notes`` carries the human-readable reasons.
    """
    if len(data) > MAX_UPLOAD_BYTES:
        notes.append(f"upload exceeds {MAX_UPLOAD_BYTES // (1024 * 1024)} MB")
        return [], "too_large"
    if not data:
        notes.append("upload was empty")
        return [], "empty"

    suffix = _suffix(name, mime)
    resolved_mime = _mime(name, mime)

    if suffix in IMAGE_EXTS or resolved_mime.startswith("image/"):
        return [_image_part(data, resolved_mime)], f"image:{resolved_mime}"

    if suffix in AUDIO_EXTS or resolved_mime.startswith("audio/"):
        return [_audio_part(data, name, mime)], f"audio:{suffix.lstrip('.') or resolved_mime}"

    if suffix == ".pdf" or resolved_mime == "application/pdf":
        return _document_parts(data, ".pdf", notes)

    if suffix == ".docx" or resolved_mime.endswith("wordprocessingml.document"):
        return _document_parts(data, ".docx", notes)

    if suffix in TEXT_EXTS or resolved_mime.startswith("text/"):
        parts = _text_part(data, notes)
        return (parts, "text") if parts else ([], "text:empty")

    # Unknown extension: readable as UTF-8 *text* counts as text; otherwise
    # refuse honestly rather than sending bytes the model cannot interpret.
    # The control-character check matters because plenty of binary formats
    # (zip headers, for one) happen to decode as UTF-8.
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError:
        text = None
    if text is None or any(ch < " " and ch not in "\t\n\r" for ch in text):
        notes.append(f"unrecognized binary format ({suffix or resolved_mime})")
        return [], "unreadable"
    parts = _text_part(data, notes)
    return (parts, f"text:{suffix or 'unknown'}") if parts else ([], "text:empty")
