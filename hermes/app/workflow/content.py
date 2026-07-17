#!/usr/bin/env python3
"""Read messy Canvas student-submission folders and produce per-student profile
evidence with Gemma 4 doing the classification and interpretation work.

Two passes per activity:

  1. Per-file pass. Walk `input/content/<activity_id>/`. For every file (any
     extension), render it as a multimodal payload (images as image_url, PDFs
     rendered to one image per page, DOCX as extracted text plus embedded
     images, TXT/MD as text), and ask Gemma in ONE call to identify the
     student AND write 100-200 words of structured notes on what the file
     shows. Output: `output/content/<activity_id>/_per_file/<file_id>.json`.

  2. Per-student consolidation. After per-file notes exist, group by
     identified student and ask Gemma in ONE call per student for a single
     warm 250-400 word consolidated assessment. Output:
     `output/content/<activity_id>/<student_slug>.md`.

Python does not filter, classify, or decide what counts. Python orchestrates,
encodes files, and saves outputs. Gemma reads the mess.

Usage:

    python3 content.py 1_1_1_folding_polygons
    python3 content.py 1_1_1_folding_polygons --force        # re-run every file + consolidation
    python3 content.py 1_1_1_folding_polygons --only Doe_Jane  # consolidate one student
    python3 content.py 1_1_1_folding_polygons --no-consolidate # only per-file pass

Outputs:

    output/content/<activity>/_per_file/<file_id>.json   per-file Gemma notes
    output/content/<activity>/<student_slug>.md          consolidated assessment
    output/content/<activity>/_unmatched/<file_id>.json  low-confidence reads
    output/content/<activity>/log.jsonl                  per-file run log
    output/content/<activity>/mapping.csv                file -> student summary
"""

from __future__ import annotations

import argparse
import base64
import csv
import hashlib
import json
import mimetypes
import os
import re
import shutil
import subprocess
import sys
import tempfile
from collections import defaultdict
from pathlib import Path

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[3]))

from hermes.app.workflow import service  # noqa: E402
from hermes.app.workflow.lib import api, roster as rosterlib  # noqa: E402
from hermes.app.workflow.lib import content as contentlib  # noqa: E402
from hermes.app.workflow.runtime import DATA, HERE  # noqa: E402

CONTENT_INPUT = DATA / "input" / "content"
CONTENT_OUTPUT = DATA / "output" / "content"

SKIP_NAMES = {".ds_store", "thumbs.db", "_activity.md", "activity.md", "_lesson.md", "lesson.md", "_config.json"}
SKIP_PARTS = {"__MACOSX", ".git", "__pycache__"}

IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp", ".tif", ".tiff", ".heic", ".heif"}
TEXT_EXTS = {".txt", ".md", ".csv"}

DEFAULT_MAX_PAGES_PER_PDF = 8
DEFAULT_MAX_VISION_IMAGES = 12
DEFAULT_MAX_ACTIVITY_CHARS = 14000
DEFAULT_MAX_CHART_CHARS = 18000
DEFAULT_MAX_TEXT_FILE_CHARS = 12000


def env_int(name: str, default: int) -> int:
    raw = os.environ.get(name, "").strip()
    if not raw:
        return default
    try:
        return max(0, int(raw))
    except ValueError:
        return default


def mime_for(path: Path) -> str:
    guessed, _ = mimetypes.guess_type(path.name)
    if guessed:
        return guessed
    suffix = path.suffix.lower()
    if suffix == ".docx":
        return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    if suffix == ".pdf":
        return "application/pdf"
    if suffix in {".heic", ".heif"}:
        return "image/heic"
    return "application/octet-stream"


def should_skip(path: Path) -> bool:
    if path.name.lower() in SKIP_NAMES:
        return True
    return any(part in SKIP_PARTS or part.startswith(".") for part in path.parts)


def slug_for_file(rel_path: Path) -> str:
    s = rel_path.as_posix().lower()
    s = re.sub(r"[^a-z0-9]+", "_", s).strip("_")
    return s[:120] or "file"


def file_hash(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()[:16]


def bounded_text(text: str, max_chars: int) -> str:
    if max_chars <= 0 or len(text) <= max_chars:
        return text
    return text[:max_chars].rstrip() + f"\n\n[Truncated at {max_chars} characters.]"


def data_url(data: bytes, mime: str) -> str:
    return f"data:{mime};base64,{base64.b64encode(data).decode('ascii')}"


def image_part_from_bytes(data: bytes, mime: str) -> dict:
    return {"type": "image_url", "image_url": {"url": data_url(data, mime)}}


def render_pdf_to_images(path: Path, log: list[str]) -> list[tuple[str, bytes, str]]:
    """Render PDF pages to PNGs via pdftoppm. Returns [(label, bytes, mime), ...]."""
    pdftoppm = shutil.which("pdftoppm")
    if not pdftoppm:
        log.append("pdftoppm not found; install poppler to read PDF pages as images")
        return []
    max_pages = env_int("REALLMS_MAX_PAGES_PER_PDF", DEFAULT_MAX_PAGES_PER_PDF)
    if max_pages == 0:
        return []
    out: list[tuple[str, bytes, str]] = []
    with tempfile.TemporaryDirectory(prefix="n103_pdf_") as tmp:
        prefix = Path(tmp) / "page"
        cmd = [pdftoppm, "-png", "-r", "150", "-l", str(max_pages), str(path), str(prefix)]
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
        except (OSError, subprocess.SubprocessError) as e:
            log.append(f"pdftoppm crashed: {e}")
            return []
        if result.returncode != 0:
            log.append(f"pdftoppm exit {result.returncode}: {result.stderr.strip()[:240]}")
            return []
        for page_png in sorted(Path(tmp).glob("page-*.png")):
            out.append((page_png.name, page_png.read_bytes(), "image/png"))
    log.append(f"pdf pages rendered: {len(out)}")
    return out


def parts_for_file(path: Path, log: list[str]) -> tuple[list[dict], str]:
    """Build multimodal user-content parts for a single file. Returns (parts, render_label)."""
    suffix = path.suffix.lower()
    parts: list[dict] = []

    if suffix in IMAGE_EXTS:
        mime = mime_for(path)
        try:
            parts.append(image_part_from_bytes(path.read_bytes(), mime))
            return parts, f"image:{mime}"
        except OSError as e:
            log.append(f"could not read image: {e}")
            return [], "unreadable"

    if suffix == ".pdf":
        images = render_pdf_to_images(path, log)
        if images:
            for label, data, mime in images:
                parts.append({"type": "text", "text": f"PDF page: {label}"})
                parts.append(image_part_from_bytes(data, mime))
            return parts, f"pdf:{len(images)}pages"
        text = contentlib.extract_pdf(path) if hasattr(contentlib, "extract_pdf") else ""
        if text:
            parts.append({"type": "text", "text": "PDF text (rendering unavailable):\n" + bounded_text(text, env_int("REALLMS_MAX_TEXT_FILE_CHARS", DEFAULT_MAX_TEXT_FILE_CHARS))})
            return parts, "pdf:text-only"
        log.append("pdf had no extractable images or text")
        return [], "pdf:unreadable"

    if suffix == ".docx":
        try:
            text = contentlib.extract_docx(path)
        except Exception as e:
            text = ""
            log.append(f"docx text extraction failed: {e}")
        try:
            images = contentlib.extract_docx_images(path) if hasattr(contentlib, "extract_docx_images") else []
        except Exception as e:
            images = []
            log.append(f"docx image extraction failed: {e}")
        if text:
            parts.append({"type": "text", "text": "DOCX text:\n" + bounded_text(text, env_int("REALLMS_MAX_TEXT_FILE_CHARS", DEFAULT_MAX_TEXT_FILE_CHARS))})
        for img in images:
            parts.append({"type": "text", "text": f"DOCX embedded image: {img.label}"})
            parts.append(image_part_from_bytes(img.data, img.mime_type))
        if not parts:
            log.append("docx had no extractable text or images")
            return [], "docx:unreadable"
        return parts, f"docx:text+{len(images)}img"

    if suffix in TEXT_EXTS:
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError as e:
            log.append(f"text read failed: {e}")
            return [], "text:unreadable"
        parts.append({"type": "text", "text": bounded_text(text, env_int("REALLMS_MAX_TEXT_FILE_CHARS", DEFAULT_MAX_TEXT_FILE_CHARS))})
        return parts, "text"

    try:
        text = path.read_text(encoding="utf-8")
        parts.append({"type": "text", "text": bounded_text(text, env_int("REALLMS_MAX_TEXT_FILE_CHARS", DEFAULT_MAX_TEXT_FILE_CHARS))})
        return parts, f"unknown:text({suffix})"
    except (OSError, UnicodeDecodeError):
        pass
    try:
        parts.append(image_part_from_bytes(path.read_bytes(), "application/octet-stream"))
        return parts, f"unknown:bytes({suffix})"
    except OSError as e:
        log.append(f"unknown-extension read failed: {e}")
        return [], "unknown:unreadable"


def find_activity_md(activity_dir: Path, activity_id: str) -> tuple[str, str]:
    """Resolve the activity description for this activity_id.

    Tries in order:
      1. `_activity.md` or `activity.md` inside the submission folder.
      2. `activities/<activity_id>.md` (exact match).
      3. Prefix-scan: `activities/*.md` whose D.A.S prefix matches.
    """
    for name in ("_activity.md", "activity.md"):
        p = activity_dir / name
        if p.exists():
            try:
                text = p.read_text(encoding="utf-8", errors="replace").strip()
            except OSError:
                continue
            return bounded_text(text, env_int("REALLMS_MAX_ACTIVITY_CHARS", DEFAULT_MAX_ACTIVITY_CHARS)), str(p.relative_to(HERE))

    activities_dir = HERE / "activities"
    exact = activities_dir / f"{activity_id}.md"
    if exact.exists():
        try:
            text = exact.read_text(encoding="utf-8", errors="replace").strip()
        except OSError:
            text = ""
        if text:
            return bounded_text(text, env_int("REALLMS_MAX_ACTIVITY_CHARS", DEFAULT_MAX_ACTIVITY_CHARS)), str(exact.relative_to(HERE))

    if activities_dir.exists():
        m = re.match(r"^(\d+(?:_\d+)*)", activity_id)
        prefix = m.group(1) if m else ""
        if prefix:
            candidates = sorted(
                activities_dir.glob(f"{prefix}_*.md"),
                key=lambda p: (len(p.name), p.name),
            )
            if candidates:
                p = candidates[0]
                try:
                    text = p.read_text(encoding="utf-8", errors="replace").strip()
                except OSError:
                    return "", ""
                return bounded_text(text, env_int("REALLMS_MAX_ACTIVITY_CHARS", DEFAULT_MAX_ACTIVITY_CHARS)), str(p.relative_to(HERE))

    return "", ""


def _activity_number_prefix(activity_id: str) -> str:
    """Extract the leading number-and-underscore prefix from an activity id.
    '1_1_1_folding_polygons' -> '1_1_1'; '2_2_5_read_and_discuss' -> '2_2_5'."""
    m = re.match(r"^(\d+(?:_\d+)*)", activity_id)
    return m.group(1) if m else ""


def _read_chart(p: Path) -> tuple[str, str]:
    try:
        text = p.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return "", ""
    return bounded_text(text, env_int("REALLMS_MAX_CHART_CHARS", DEFAULT_MAX_CHART_CHARS)), str(p.relative_to(HERE))


def find_monitoring_chart(activity_id: str) -> tuple[str, str]:
    """Resolve a monitoring chart for an activity_id.

    Tries three strategies in order:
      1. Exact / fuzzy match against monitoring/INDEX.json keys.
      2. Activity-number prefix scan of monitoring/unit*/*.md
         (e.g., '1_1_1_folding_polygons' -> 'monitoring/unit*/1-1-1_*.md').
      3. Best-effort substring match against any monitoring/**.md stem.
    """
    monitoring_root = HERE / "monitoring"

    # Strategy 1: INDEX.json fuzzy match
    idx_path = monitoring_root / "INDEX.json"
    if idx_path.exists():
        try:
            idx = json.loads(idx_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            idx = {}
        key_norm = re.sub(r"[^a-z0-9]+", "_", activity_id.lower()).strip("_")
        for k, v in idx.items():
            if k.startswith("_") or not v:
                continue
            k_norm = re.sub(r"[^a-z0-9]+", "_", k.lower()).strip("_")
            if key_norm == k_norm or key_norm in k_norm or k_norm in key_norm:
                p = HERE / v
                if p.exists():
                    return _read_chart(p)

    # Strategy 2: activity-number prefix scan
    prefix = _activity_number_prefix(activity_id)
    if prefix and monitoring_root.exists():
        dash_prefix = prefix.replace("_", "-")
        for unit_dir in sorted(monitoring_root.glob("unit*")):
            charts = sorted(unit_dir.glob(f"{dash_prefix}_*.md"), key=lambda p: (len(p.name), p.name))
            for chart in charts:
                return _read_chart(chart)
        # Try unit-overviews/ when prefix is a single digit (e.g., '3' for unit 3 overview)
        if "_" not in prefix:
            overview = monitoring_root / "unit-overviews" / f"unit{prefix}.md"
            if overview.exists():
                return _read_chart(overview)

    # Strategy 3: substring match against any chart stem (last resort)
    if monitoring_root.exists():
        key_norm = re.sub(r"[^a-z0-9]+", "_", activity_id.lower()).strip("_")
        best: Path | None = None
        best_score = 0
        for chart in monitoring_root.glob("**/*.md"):
            stem_norm = re.sub(r"[^a-z0-9]+", "_", chart.stem.lower()).strip("_")
            # Score = length of longest shared prefix piece
            shared = 0
            for a, b in zip(key_norm.split("_"), stem_norm.split("_")):
                if a == b:
                    shared += len(a)
                else:
                    break
            if shared > best_score:
                best, best_score = chart, shared
        if best and best_score >= 3:
            return _read_chart(best)

    return "", ""


def roster_block(students: list[rosterlib.Student]) -> str:
    return "\n".join(f"- student_id={s.student_id} | name={s.display()} | login={s.user_login}" for s in students)


def per_file_call(
    *,
    rel_label: str,
    parts: list[dict],
    students: list[rosterlib.Student],
    activity_text: str,
    activity_label: str,
    chart_text: str,
    chart_label: str,
    client: dict,
) -> tuple[dict, str]:
    system = (HERE / "system_prompts" / "content_per_file.md").read_text(encoding="utf-8")
    intro = (
        f"FILE_LABEL: {rel_label}\n\n"
        f"ROSTER:\n{roster_block(students)}\n"
    )
    if activity_text:
        intro += f"\nACTIVITY ({activity_label}):\n{activity_text}\n"
    if chart_text:
        intro += f"\nMONITORING_CHART ({chart_label}):\n{chart_text}\n"
    context_parts: list[dict] = [{"type": "text", "text": intro}]
    context_parts.extend(parts)
    messages = [
        {"role": "system", "content": system},
        {"role": "user", "content": context_parts},
    ]
    reply = api.call_api_messages(messages, **client, retries=2, timeout=900).strip()
    obj = _safe_json(reply)
    return obj, reply


def _safe_json(reply: str) -> dict:
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
    end = text.rfind("}")
    if end != -1:
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
        if start != -1:
            try:
                return json.loads(text[start:end + 1])
            except json.JSONDecodeError:
                pass
    return {"_parse_error": True, "_raw": text[:1200]}


def consolidate_call(
    *,
    student: rosterlib.Student,
    activity_id: str,
    activity_text: str,
    activity_label: str,
    chart_text: str,
    chart_label: str,
    per_file_objs: list[dict],
    client: dict,
) -> str:
    system = (HERE / "system_prompts" / "content_consolidate.md").read_text(encoding="utf-8")
    body = [
        f"STUDENT: name={student.display()}, student_id={student.student_id}",
        f"ACTIVITY: {activity_id}",
    ]
    if activity_text:
        body.append(f"\nACTIVITY ({activity_label}):\n{activity_text}")
    if chart_text:
        body.append(f"\nMONITORING_CHART ({chart_label}):\n{chart_text}")
    body.append("\nPER_FILE_NOTES (JSON):\n" + json.dumps(per_file_objs, indent=2, ensure_ascii=False))
    user = "\n".join(body)
    return api.call_api(system, user, **client, retries=2, timeout=600).strip()


def walk_files(activity_dir: Path) -> list[Path]:
    out: list[Path] = []
    for path in sorted(activity_dir.rglob("*")):
        if not path.is_file() or should_skip(path):
            continue
        try:
            if path.stat().st_size == 0:
                continue
        except OSError:
            continue
        out.append(path)
    return out


def _main(argv: list[str] | None = None) -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("activity", help="Activity id (matches folder name in input/content/).")
    ap.add_argument("--force", action="store_true", help="Re-run files that already have per-file JSON; re-consolidate every student.")
    ap.add_argument("--only", help="Consolidate only this student (file_slug or id substring).")
    ap.add_argument("--no-consolidate", action="store_true", help="Per-file pass only.")
    ap.add_argument("--no-per-file", action="store_true", help="Skip per-file pass; consolidate from existing JSON.")
    args = ap.parse_args(argv)

    activity_id = args.activity.strip().strip("/")
    activity_dir = CONTENT_INPUT / activity_id
    if not activity_dir.is_dir():
        api.fail(f"missing activity directory: {activity_dir.relative_to(HERE)}")

    students = rosterlib.read_roster(DATA / "roster.csv")
    if not students:
        api.fail("roster.csv is empty or missing.")
    by_sid = {s.student_id: s for s in students}

    out_dir = CONTENT_OUTPUT / activity_id
    per_file_dir = out_dir / "_per_file"
    unmatched_dir = out_dir / "_unmatched"
    per_file_dir.mkdir(parents=True, exist_ok=True)
    log_path = out_dir / "log.jsonl"

    activity_text, activity_label = find_activity_md(activity_dir, activity_id)
    chart_text, chart_label = find_monitoring_chart(activity_id)
    if not activity_text:
        sys.stderr.write(f"warning: no activity description found; add {activity_dir.relative_to(HERE)}/_activity.md or activities/{activity_id}.md\n")
    if not chart_text:
        sys.stderr.write(f"warning: no monitoring chart matched for {activity_id}; continuing without chart context\n")

    client = api.make_client(DATA)

    files = walk_files(activity_dir)
    print(f"activity: {activity_id}")
    print(f"input files: {len(files)}")
    print(f"activity description: {activity_label or 'none'}")
    print(f"monitoring chart: {chart_label or 'none'}")

    log_records: list[dict] = []
    parsed_objs: dict[str, dict] = {}

    if not args.no_per_file:
        for i, fpath in enumerate(files, start=1):
            rel = fpath.relative_to(activity_dir)
            file_id = slug_for_file(rel)
            cached = per_file_dir / f"{file_id}.json"
            if cached.exists() and not args.force:
                try:
                    parsed_objs[file_id] = json.loads(cached.read_text(encoding="utf-8"))
                    print(f"  {i}/{len(files)} {rel.as_posix()}: cached")
                    continue
                except json.JSONDecodeError:
                    pass

            file_log: list[str] = []
            parts, render_label = parts_for_file(fpath, file_log)
            if not parts:
                rec = {
                    "file": rel.as_posix(),
                    "file_id": file_id,
                    "status": "no_parts",
                    "render": render_label,
                    "log": file_log,
                }
                log_records.append(rec)
                cached.write_text(json.dumps({"file_id": file_id, "file": rel.as_posix(), "render": render_label, "log": file_log, "skipped": True}, indent=2), encoding="utf-8")
                print(f"  {i}/{len(files)} {rel.as_posix()}: no parts ({render_label})")
                continue

            print(f"  {i}/{len(files)} {rel.as_posix()}: per-file Gemma ({render_label})...", flush=True)
            try:
                obj, raw = per_file_call(
                    rel_label=rel.as_posix(),
                    parts=parts,
                    students=students,
                    activity_text=activity_text,
                    activity_label=activity_label,
                    chart_text=chart_text,
                    chart_label=chart_label,
                    client=client,
                )
            except SystemExit:
                raise
            except Exception as e:
                file_log.append(f"per-file call failed: {e}")
                obj = {"_call_error": True, "_raw": file_log}
                raw = ""

            obj.setdefault("file", rel.as_posix())
            obj["file_id"] = file_id
            obj.setdefault("render", render_label)
            obj.setdefault("log", file_log)
            obj.setdefault("file_hash", file_hash(fpath))
            cached.write_text(json.dumps(obj, indent=2, ensure_ascii=False), encoding="utf-8")
            parsed_objs[file_id] = obj
            log_records.append({
                "file": rel.as_posix(),
                "file_id": file_id,
                "status": "ok" if not obj.get("_parse_error") and not obj.get("_call_error") else "error",
                "render": render_label,
                "student_id": obj.get("student_id"),
                "confidence": obj.get("confidence"),
                "log": file_log,
            })

            sid = obj.get("student_id")
            conf = (obj.get("confidence") or "").lower()
            if not sid or conf == "low":
                unmatched_dir.mkdir(parents=True, exist_ok=True)
                (unmatched_dir / f"{file_id}.json").write_text(json.dumps(obj, indent=2, ensure_ascii=False), encoding="utf-8")
    else:
        for cached in sorted(per_file_dir.glob("*.json")):
            try:
                parsed_objs[cached.stem] = json.loads(cached.read_text(encoding="utf-8"))
            except json.JSONDecodeError:
                continue
        print(f"loaded {len(parsed_objs)} cached per-file note(s)")

    if not args.no_consolidate:
        per_student: dict[str, list[dict]] = defaultdict(list)
        for obj in parsed_objs.values():
            sid = obj.get("student_id")
            conf = (obj.get("confidence") or "").lower()
            if not sid or sid not in by_sid or conf == "low":
                continue
            per_student[sid].append(obj)

        if args.only:
            needle = args.only.lower()
            keep = {sid for sid in per_student if any(needle in (by_sid[sid].file_slug().lower(), sid.lower(), by_sid[sid].display().lower()))}
            per_student = {sid: per_student[sid] for sid in keep}
            if not per_student:
                sys.stderr.write(f"  no per-file notes matched --only {args.only}\n")

        print(f"\nconsolidating {len(per_student)} student(s) with per-file notes...")
        for sid, objs in sorted(per_student.items(), key=lambda kv: by_sid[kv[0]].file_slug()):
            student = by_sid[sid]
            out_path = out_dir / f"{student.file_slug()}.md"
            if out_path.exists() and not args.force and not args.only:
                try:
                    out_mtime = out_path.stat().st_mtime
                    fresh = any((per_file_dir / f"{o['file_id']}.json").stat().st_mtime > out_mtime for o in objs)
                except OSError:
                    fresh = True
                if not fresh:
                    print(f"  {student.file_slug()}: cached, skipping")
                    continue

            print(f"  {student.file_slug()}: consolidating {len(objs)} per-file note(s)...", flush=True)
            try:
                md = consolidate_call(
                    student=student,
                    activity_id=activity_id,
                    activity_text=activity_text,
                    activity_label=activity_label,
                    chart_text=chart_text,
                    chart_label=chart_label,
                    per_file_objs=objs,
                    client=client,
                )
            except SystemExit:
                raise
            except Exception as e:
                md = f"# {student.display()} — {activity_id}\n\n*Consolidation failed: {e}*\n"
            out_path.write_text(md.strip() + "\n", encoding="utf-8")

    if log_records:
        with log_path.open("a", encoding="utf-8") as f:
            for r in log_records:
                f.write(json.dumps(r, ensure_ascii=False) + "\n")

    mapping_rows: list[dict] = []
    for obj in parsed_objs.values():
        mapping_rows.append({
            "file": obj.get("file", ""),
            "file_id": obj.get("file_id", ""),
            "student_id": obj.get("student_id") or "",
            "student_name": by_sid[obj["student_id"]].display() if obj.get("student_id") in by_sid else "",
            "confidence": obj.get("confidence") or "",
            "reason": (obj.get("reason") or "")[:240],
            "render": obj.get("render") or "",
        })
    if mapping_rows:
        with (out_dir / "mapping.csv").open("w", encoding="utf-8", newline="") as f:
            w = csv.DictWriter(f, fieldnames=["file", "file_id", "student_id", "student_name", "confidence", "reason", "render"])
            w.writeheader()
            w.writerows(mapping_rows)

    matched = sum(1 for r in mapping_rows if r["student_id"])
    print(f"\ndone. output/content/{activity_id}/")
    print(f"  per-file notes: {len(parsed_objs)}  matched: {matched}  unmatched: {len(parsed_objs) - matched}")


def run(payload: dict, context: service.WorkflowContext) -> service.WorkflowResult:
    return service.run_command("content", payload, context, _main)


def main(argv: list[str] | None = None) -> int:
    return service.run_cli("content", argv, _main)


if __name__ == "__main__":
    raise SystemExit(main())
