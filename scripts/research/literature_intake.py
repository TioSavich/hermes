#!/usr/bin/env python3
"""Convert research PDFs to deterministic Markdown and JSON sidecars.

The converter reads both bibliography files and records an honest match result.
Journal batches checkpoint after every PDF. A parent process gives each PDF an
external wall-clock limit, records failures, and continues.

Figure descriptions are deliberately deferred. Each sidecar carries a stable
figure locator and a pending Granite-style description request. The
``--description-manifest`` mode collects those requests without making a model
call.
"""

from __future__ import annotations

import argparse
import difflib
import hashlib
import importlib.metadata
import json
import os
import platform
import re
import subprocess
import sys
import tempfile
import unicodedata
from collections import Counter
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Sequence


REPO_ROOT = Path(__file__).resolve().parents[2]
EXTERNAL_ROOT = Path(
    os.environ.get(
        "UMEDCTA_FORMALIZATION_ROOT",
        REPO_ROOT.parent / "umedcta-formalization",
    )
)
DEFAULT_CORPUS_ROOT = EXTERNAL_ROOT / "research_corpus" / "pdfs"
DEFAULT_CORPUS_BIB = EXTERNAL_ROOT / "research_corpus" / "references.bib"
DEFAULT_REPO_BIB = REPO_ROOT / "data" / "research" / "references.bib"
DEFAULT_OUTPUT_ROOT = REPO_ROOT / "data" / "research" / "literature"

JOURNALS = (
    "ESM",
    "FLM",
    "IJEMST",
    "IJMEST",
    "IJSME",
    "JMB",
    "JMTE",
    "JRME",
    "MERJ",
    "MTL",
    "RME",
    "ZDM",
)

SMOKE_PDFS = (
    ("ESM", DEFAULT_CORPUS_ROOT / "ESM" / "ESM_Goel_1997_Equation.pdf", None),
    (
        "JMTE",
        DEFAULT_CORPUS_ROOT / "JMTE" / "JMTE_Sullivan_2003_Editorial.pdf",
        None,
    ),
    (
        "FLM",
        DEFAULT_CORPUS_ROOT / "FLM" / "FLM_Figueiras_2011_Teachers.pdf",
        None,
    ),
    (
        "BOOKS",
        Path(
            "/Users/tio/Desktop/E343_Cleanup/"
            "Elementary_and_Middle_School_Mathematics.pdf"
        ),
        15,
    ),
)

TOKEN_RE = re.compile(r"[a-z0-9]+")
DOI_RE = re.compile(r"\b10\.\d{4,9}/[-._;()/:a-z0-9]+\b", re.IGNORECASE)


@dataclass(frozen=True)
class BibEntry:
    key: str
    entry_type: str
    fields: dict[str, str]
    sources: tuple[str, ...]


def log(message: str) -> None:
    print(message, flush=True)


def atomic_write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    handle, temporary = tempfile.mkstemp(
        prefix=f".{path.name}.", suffix=".tmp", dir=path.parent
    )
    try:
        with os.fdopen(handle, "w", encoding="utf-8", newline="\n") as stream:
            stream.write(text)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    except BaseException:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
        raise


def atomic_write_json(path: Path, value: Any) -> None:
    atomic_write_text(
        path,
        json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
    )


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def strip_wrapping(value: str) -> str:
    value = value.strip().rstrip(",").strip()
    changed = True
    while changed and len(value) >= 2:
        changed = False
        if value[0] == "{" and value[-1] == "}":
            depth = 0
            balanced = True
            for index, char in enumerate(value):
                if char == "{" and (index == 0 or value[index - 1] != "\\"):
                    depth += 1
                elif char == "}" and (index == 0 or value[index - 1] != "\\"):
                    depth -= 1
                    if depth == 0 and index != len(value) - 1:
                        balanced = False
                        break
            if balanced and depth == 0:
                value = value[1:-1].strip()
                changed = True
        elif value[0] == '"' and value[-1] == '"':
            value = value[1:-1].strip()
            changed = True
    return value


def split_top_level(text: str) -> list[str]:
    parts: list[str] = []
    start = 0
    depth = 0
    quoted = False
    escaped = False
    for index, char in enumerate(text):
        if escaped:
            escaped = False
            continue
        if char == "\\":
            escaped = True
            continue
        if char == '"' and depth == 0:
            quoted = not quoted
        elif not quoted:
            if char == "{":
                depth += 1
            elif char == "}":
                depth -= 1
                if depth < 0:
                    raise ValueError("unbalanced closing brace in BibTeX entry")
            elif char == "," and depth == 0:
                parts.append(text[start:index])
                start = index + 1
    if depth != 0 or quoted:
        raise ValueError("unbalanced BibTeX field value")
    parts.append(text[start:])
    return parts


def parse_bibtex(path: Path, source_name: str) -> list[BibEntry]:
    text = path.read_text(encoding="utf-8")
    entries: list[BibEntry] = []
    cursor = 0
    header = re.compile(r"@([A-Za-z]+)\s*[\{\(]\s*([^,\s]+)\s*,")
    while True:
        match = header.search(text, cursor)
        if match is None:
            break
        opener = text[match.start() : match.end()]
        open_char = "{" if "{" in opener else "("
        close_char = "}" if open_char == "{" else ")"
        depth = 1
        quoted = False
        escaped = False
        index = match.end()
        while index < len(text) and depth:
            char = text[index]
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"' and depth == 1:
                quoted = not quoted
            elif not quoted:
                if char == open_char:
                    depth += 1
                elif char == close_char:
                    depth -= 1
            index += 1
        if depth:
            raise ValueError(f"{path}: unterminated entry {match.group(2)}")
        body = text[match.end() : index - 1]
        fields: dict[str, str] = {}
        for part in split_top_level(body):
            if not part.strip():
                continue
            if "=" not in part:
                raise ValueError(
                    f"{path}: malformed field in {match.group(2)}: {part[:80]!r}"
                )
            name, value = part.split("=", 1)
            fields[name.strip().lower()] = strip_wrapping(value)
        entries.append(
            BibEntry(
                key=match.group(2).strip(),
                entry_type=match.group(1).lower(),
                fields=fields,
                sources=(source_name,),
            )
        )
        cursor = index
    if not entries:
        raise ValueError(f"{path}: no BibTeX entries found")
    return entries


def load_bibliographies(corpus_bib: Path, repo_bib: Path) -> list[BibEntry]:
    combined: dict[str, BibEntry] = {}
    for path, name in ((corpus_bib, "corpus"), (repo_bib, "hermes")):
        for entry in parse_bibtex(path, name):
            previous = combined.get(entry.key)
            if previous is None:
                combined[entry.key] = entry
                continue
            fields = dict(previous.fields)
            for field_name, value in entry.fields.items():
                fields.setdefault(field_name, value)
            combined[entry.key] = BibEntry(
                key=entry.key,
                entry_type=previous.entry_type,
                fields=fields,
                sources=tuple(sorted(set(previous.sources + entry.sources))),
            )
    return [combined[key] for key in sorted(combined)]


def normalized_text(value: str) -> str:
    value = re.sub(r"\\[A-Za-z]+\s*", " ", value)
    value = value.replace("{", " ").replace("}", " ")
    value = unicodedata.normalize("NFKD", value)
    value = "".join(char for char in value if not unicodedata.combining(char))
    return " ".join(TOKEN_RE.findall(value.lower()))


def normalized_doi(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"^(?:https?://)?(?:dx\.)?doi\.org/", "", value)
    return value.rstrip(".,;)")


def extract_pdf_metadata(path: Path, page_limit: int = 3) -> dict[str, Any]:
    try:
        from pypdf import PdfReader
    except ImportError as exc:
        raise RuntimeError(
            "pypdf is required for page counts and bibliography matching"
        ) from exc
    reader = PdfReader(str(path))
    metadata = dict(reader.metadata or {})
    text_parts: list[str] = []
    for page in reader.pages[: min(page_limit, len(reader.pages))]:
        try:
            text_parts.append(page.extract_text() or "")
        except Exception:
            continue
    text = "\n".join(text_parts)
    title = str(metadata.get("/Title", "") or "")
    author = str(metadata.get("/Author", "") or "")
    dois = sorted({normalized_doi(item) for item in DOI_RE.findall(text)})
    return {
        "page_count": len(reader.pages),
        "title": title,
        "author": author,
        "first_pages_text": text[:50000],
        "dois": dois,
    }


def entry_file_basename(entry: BibEntry) -> str:
    return Path(entry.fields.get("file", "").replace("\\", "/")).name.lower()


def score_entry(
    entry: BibEntry, pdf: Path, metadata: dict[str, Any]
) -> tuple[float, str, dict[str, float]]:
    filename = pdf.name.lower()
    stem = normalized_text(pdf.stem)
    key_stem = normalized_text(entry.key)
    entry_doi = normalized_doi(entry.fields.get("doi", ""))
    if entry_file_basename(entry) == filename:
        return 1.0, "file_basename", {"file": 1.0}
    if normalized_text(entry.key) == stem:
        return 0.99, "bib_key_filename", {"key": 1.0}
    if entry_doi and entry_doi in metadata["dois"]:
        return 0.98, "doi", {"doi": 1.0}

    title = normalized_text(entry.fields.get("title", ""))
    author = normalized_text(entry.fields.get("author", ""))
    observed_title = normalized_text(metadata.get("title", ""))
    observed_author = normalized_text(metadata.get("author", ""))
    first_text = normalized_text(metadata.get("first_pages_text", ""))[:12000]

    title_ratio = (
        difflib.SequenceMatcher(None, title, observed_title).ratio()
        if title and observed_title
        else 0.0
    )
    title_in_text = 1.0 if title and len(title) > 12 and title in first_text else 0.0
    author_tokens = set(author.split())
    observed_author_tokens = set((observed_author + " " + first_text[:2500]).split())
    author_overlap = (
        len(author_tokens & observed_author_tokens) / len(author_tokens)
        if author_tokens
        else 0.0
    )
    key_tokens = set(key_stem.split())
    stem_tokens = set(stem.split())
    filename_overlap = (
        len(key_tokens & stem_tokens) / len(key_tokens | stem_tokens)
        if key_tokens and stem_tokens
        else 0.0
    )
    score = max(
        0.72 * title_ratio + 0.18 * author_overlap + 0.10 * filename_overlap,
        0.80 * title_in_text + 0.15 * author_overlap + 0.05 * filename_overlap,
        0.65 * filename_overlap + 0.20 * author_overlap,
    )
    components = {
        "title": round(title_ratio, 4),
        "title_in_text": title_in_text,
        "author": round(author_overlap, 4),
        "filename": round(filename_overlap, 4),
    }
    return score, "title_author_filename", components


def match_bibliography(
    pdf: Path, metadata: dict[str, Any], entries: Sequence[BibEntry]
) -> dict[str, Any]:
    exact_file = [
        entry for entry in entries if entry_file_basename(entry) == pdf.name.lower()
    ]
    exact_key = [
        entry for entry in entries if normalized_text(entry.key) == normalized_text(pdf.stem)
    ]
    candidates = exact_file or exact_key or list(entries)
    scored: list[tuple[float, str, dict[str, float], BibEntry]] = []
    for entry in candidates:
        score, method, components = score_entry(entry, pdf, metadata)
        scored.append((score, method, components, entry))
    scored.sort(key=lambda row: (-row[0], row[3].key))
    best = scored[0] if scored else None
    if best is None or best[0] < 0.72:
        return {
            "status": "unkeyed",
            "key": None,
            "confidence": "none",
            "score": round(best[0], 4) if best else 0.0,
            "method": "no_reliable_match",
            "candidate_key": best[3].key if best else None,
        }
    score, method, components, entry = best
    confidence = "high" if score >= 0.9 else "medium"
    return {
        "status": "matched",
        "key": entry.key,
        "confidence": confidence,
        "score": round(score, 4),
        "method": method,
        "components": components,
        "bibliography_sources": list(entry.sources),
        "entry": {
            field: entry.fields[field]
            for field in ("author", "title", "year", "journal", "doi")
            if entry.fields.get(field)
        },
    }


def safe_slug(value: str) -> str:
    value = unicodedata.normalize("NFKD", value)
    value = "".join(char for char in value if not unicodedata.combining(char))
    value = re.sub(r"[^A-Za-z0-9._'-]+", "_", value).strip("._")
    return value or "document"


def bbox_dict(bbox: Any) -> dict[str, float] | None:
    if bbox is None:
        return None
    if hasattr(bbox, "model_dump"):
        raw = bbox.model_dump(mode="json")
    elif isinstance(bbox, dict):
        raw = bbox
    else:
        raw = {
            name: getattr(bbox, name)
            for name in ("l", "t", "r", "b")
            if hasattr(bbox, name)
        }
    result: dict[str, float] = {}
    for key in ("l", "t", "r", "b"):
        if key in raw:
            result[key] = round(float(raw[key]), 3)
    return result or None


def figure_inventory(document: Any) -> list[dict[str, Any]]:
    figures: list[dict[str, Any]] = []
    for index, picture in enumerate(document.pictures, 1):
        provenance = []
        for item in picture.prov or []:
            provenance.append(
                {
                    "page_no": int(item.page_no),
                    "bbox": bbox_dict(item.bbox),
                    "charspan": list(item.charspan) if item.charspan else None,
                }
            )
        try:
            caption = picture.caption_text(document).strip()
        except Exception:
            caption = ""
        figure_id = f"figure-{index:04d}"
        figures.append(
            {
                "id": figure_id,
                "self_ref": getattr(picture, "self_ref", None),
                "caption": caption or None,
                "provenance": provenance,
                "description": {
                    "status": "pending",
                    "style": "granite_vision",
                    "text": None,
                    "model": None,
                },
            }
        )
    return figures


def source_locator(pdf: Path, corpus_root: Path, journal: str) -> dict[str, Any]:
    try:
        relative = pdf.resolve().relative_to(corpus_root.resolve())
        corpus_relative = f"pdfs/{relative.as_posix()}"
    except ValueError:
        corpus_relative = None
    stat = pdf.stat()
    return {
        "filename": pdf.name,
        "journal_dir": journal,
        "corpus_relative_path": corpus_relative,
        "size_bytes": stat.st_size,
        "mtime_ns": stat.st_mtime_ns,
        "sha256": sha256_file(pdf),
    }


def conversion_paths(output_root: Path, journal: str, pdf: Path) -> tuple[Path, Path, Path]:
    directory = output_root / safe_slug(journal)
    stem = safe_slug(pdf.stem)
    return (
        directory / f"{stem}.md",
        directory / f"{stem}.json",
        directory / f"{stem}.error.json",
    )


def convert_pdf(
    pdf: Path,
    output_root: Path,
    journal: str,
    corpus_root: Path,
    corpus_bib: Path,
    repo_bib: Path,
    page_limit: int | None,
    threads: int,
) -> tuple[Path, Path]:
    if not pdf.is_file():
        raise FileNotFoundError(pdf)
    entries = load_bibliographies(corpus_bib, repo_bib)
    metadata = extract_pdf_metadata(pdf)
    bib_match = match_bibliography(pdf, metadata, entries)

    try:
        from docling.datamodel.accelerator_options import (
            AcceleratorDevice,
            AcceleratorOptions,
        )
        from docling.datamodel.base_models import InputFormat
        from docling.datamodel.pipeline_options import (
            CodeFormulaVlmOptions,
            PdfPipelineOptions,
            RapidOcrOptions,
            TableFormerMode,
        )
        from docling.datamodel.vlm_engine_options import (
            TransformersVlmEngineOptions,
        )
        from docling.document_converter import DocumentConverter, PdfFormatOption
    except (ImportError, OSError) as exc:
        raise RuntimeError(f"docling import failed: {exc}") from exc

    # Transformers probes every installed tensor backend while normalizing
    # processor values. Importing optional MLX initializes Metal even when the
    # selected Docling engine is CPU-only, which aborts in headless macOS
    # sandboxes. Mark that optional backend unavailable for this CPU process.
    if sys.platform == "darwin":
        import transformers.utils.import_utils as transformers_imports

        transformers_imports._mlx_available = False

    options = PdfPipelineOptions()
    options.do_ocr = True
    options.ocr_options = RapidOcrOptions(
        lang=["english"],
        backend="onnxruntime",
    )
    options.do_table_structure = True
    options.table_structure_options.mode = TableFormerMode.ACCURATE
    options.do_formula_enrichment = True
    options.code_formula_options = CodeFormulaVlmOptions.from_preset(
        "codeformulav2",
        engine_options=TransformersVlmEngineOptions(
            device=AcceleratorDevice.CPU,
            load_in_8bit=False,
            torch_dtype="float32",
            compile_model=False,
        ),
    )
    options.generate_page_images = False
    options.generate_picture_images = False
    options.accelerator_options = AcceleratorOptions(
        num_threads=max(1, threads), device=AcceleratorDevice.CPU
    )
    converter = DocumentConverter(
        format_options={
            InputFormat.PDF: PdfFormatOption(pipeline_options=options),
        }
    )
    last_page = min(metadata["page_count"], page_limit or metadata["page_count"])
    result = converter.convert(
        pdf,
        raises_on_error=True,
        page_range=(1, max(1, last_page)),
    )
    document = result.document
    markdown_body = document.export_to_markdown(
        image_placeholder="<!-- figure: description pending -->",
        enable_chart_tables=True,
        compact_tables=False,
    ).strip()
    match_line = (
        f"`{bib_match['key']}` ({bib_match['confidence']}, "
        f"{bib_match['method']})"
        if bib_match["status"] == "matched"
        else "unkeyed"
    )
    markdown = (
        f"# {pdf.stem}\n\n"
        f"- Source: `{pdf.name}`\n"
        f"- Journal directory: `{journal}`\n"
        f"- Bibliography: {match_line}\n"
        f"- Pages converted: 1-{last_page} of {metadata['page_count']}\n\n"
        f"{markdown_body}\n"
    )
    figures = figure_inventory(document)
    source = source_locator(pdf, corpus_root, journal)
    docling_version = importlib.metadata.version("docling")
    sidecar = {
        "schema_version": 1,
        "status": "complete",
        "source": source,
        "bibliography": bib_match,
        "page_count": metadata["page_count"],
        "converted_page_range": [1, last_page],
        "document_counts": {
            "figures": len(figures),
            "tables": len(document.tables),
            "texts": len(document.texts),
        },
        "figures": figures,
        "conversion": {
            "engine": "docling",
            "version": docling_version,
            "options": {
                "ocr": True,
                "ocr_engine": "rapidocr_onnxruntime",
                "table_structure": True,
                "table_structure_mode": "accurate",
                "formula_enrichment": True,
                "formula_engine": "transformers_cpu",
                "figure_description_pass": "deferred",
            },
        },
    }
    markdown_path, sidecar_path, error_path = conversion_paths(
        output_root, journal, pdf
    )
    atomic_write_text(markdown_path, markdown)
    atomic_write_json(sidecar_path, sidecar)
    error_path.unlink(missing_ok=True)
    log(
        f"COMPLETE {journal}/{pdf.name}: pages=1-{last_page} "
        f"bib={bib_match.get('key') or 'unkeyed'} figures={len(figures)} "
        f"tables={len(document.tables)}"
    )
    return markdown_path, sidecar_path


def valid_checkpoint(
    sidecar_path: Path, markdown_path: Path, pdf: Path
) -> bool:
    if not sidecar_path.is_file() or not markdown_path.is_file():
        return False
    try:
        data = json.loads(sidecar_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return False
    source = data.get("source", {})
    stat = pdf.stat()
    return (
        data.get("status") == "complete"
        and source.get("filename") == pdf.name
        and source.get("size_bytes") == stat.st_size
        and source.get("mtime_ns") == stat.st_mtime_ns
    )


def error_record(pdf: Path, journal: str, kind: str, detail: str) -> dict[str, Any]:
    stat = pdf.stat()
    return {
        "schema_version": 1,
        "status": "failed",
        "failure": {"kind": kind, "detail": detail[:4000]},
        "source": {
            "filename": pdf.name,
            "journal_dir": journal,
            "size_bytes": stat.st_size,
            "mtime_ns": stat.st_mtime_ns,
        },
    }


def worker_command(args: argparse.Namespace, pdf: Path, journal: str) -> list[str]:
    python_command = [sys.executable]
    if sys.platform == "darwin" and platform.machine() == "arm64":
        python_command = ["/usr/bin/arch", "-arm64", sys.executable]
    command = python_command + [
        str(Path(__file__).resolve()),
        "--pdf",
        str(pdf),
        "--journal",
        journal,
        "--output-root",
        str(args.output_root),
        "--corpus-root",
        str(args.corpus_root),
        "--corpus-bib",
        str(args.corpus_bib),
        "--repo-bib",
        str(args.repo_bib),
        "--threads",
        str(args.threads),
        "--worker",
    ]
    if args.page_limit:
        command.extend(("--page-limit", str(args.page_limit)))
    return command


def run_pdf_watchdog(
    args: argparse.Namespace,
    pdf: Path,
    journal: str,
    page_limit: int | None = None,
) -> str:
    markdown_path, sidecar_path, error_path = conversion_paths(
        args.output_root, journal, pdf
    )
    if args.resume and valid_checkpoint(sidecar_path, markdown_path, pdf):
        log(f"CHECKPOINT {journal}/{pdf.name}")
        return "checkpoint"
    command = worker_command(args, pdf, journal)
    if page_limit:
        try:
            index = command.index("--page-limit")
            command[index + 1] = str(page_limit)
        except ValueError:
            command.extend(("--page-limit", str(page_limit)))
    try:
        subprocess.run(command, check=True, timeout=args.per_pdf_timeout)
        return "complete"
    except subprocess.TimeoutExpired:
        detail = f"external watchdog exceeded {args.per_pdf_timeout} seconds"
        atomic_write_json(error_path, error_record(pdf, journal, "timeout", detail))
        log(f"TIMEOUT {journal}/{pdf.name}: {detail}")
        return "failed"
    except subprocess.CalledProcessError as exc:
        detail = f"converter exited with status {exc.returncode}"
        atomic_write_json(
            error_path, error_record(pdf, journal, "converter_error", detail)
        )
        log(f"FAILED {journal}/{pdf.name}: {detail}")
        return "failed"


def run_batch(
    args: argparse.Namespace,
    pdfs: Iterable[tuple[str, Path, int | None]],
) -> Counter[str]:
    counts: Counter[str] = Counter()
    for journal, pdf, page_limit in pdfs:
        try:
            outcome = run_pdf_watchdog(args, pdf, journal, page_limit)
        except KeyboardInterrupt:
            log(f"INTERRUPTED before checkpoint for {journal}/{pdf.name}")
            raise
        except Exception as exc:
            _, _, error_path = conversion_paths(args.output_root, journal, pdf)
            atomic_write_json(
                error_path,
                error_record(pdf, journal, type(exc).__name__, str(exc)),
            )
            log(f"FAILED {journal}/{pdf.name}: {type(exc).__name__}: {exc}")
            outcome = "failed"
        counts[outcome] += 1
    log(
        "BATCH_COMPLETE "
        + " ".join(f"{key}={counts[key]}" for key in sorted(counts))
    )
    return counts


def enumerate_corpus(corpus_root: Path) -> dict[str, int]:
    counts = {
        journal: len(list((corpus_root / journal).glob("*.pdf")))
        for journal in JOURNALS
    }
    for journal, count in counts.items():
        log(f"{journal}\t{count}")
    log(f"TOTAL\t{sum(counts.values())}")
    return counts


def write_description_manifest(output_root: Path) -> Path:
    requests = []
    for sidecar_path in sorted(output_root.glob("*/*.json")):
        if sidecar_path.name.endswith(".error.json"):
            continue
        data = json.loads(sidecar_path.read_text(encoding="utf-8"))
        if data.get("status") != "complete":
            continue
        for figure in data.get("figures", []):
            if figure.get("description", {}).get("status") != "pending":
                continue
            requests.append(
                {
                    "request_id": (
                        f"{data['source']['journal_dir']}/"
                        f"{sidecar_path.stem}/{figure['id']}"
                    ),
                    "sidecar": sidecar_path.relative_to(output_root).as_posix(),
                    "source": data["source"],
                    "figure": {
                        "id": figure["id"],
                        "caption": figure.get("caption"),
                        "provenance": figure.get("provenance", []),
                    },
                    "requested_output": {
                        "description": "plain-language account of the figure",
                        "transcribed_math": "formulae and labels in reading order",
                        "representation": "mathematical representation used",
                        "model": "exact Granite model identifier",
                    },
                }
            )
    path = output_root / "figure_description_requests.jsonl"
    atomic_write_text(
        path,
        "".join(
            json.dumps(item, ensure_ascii=False, sort_keys=True) + "\n"
            for item in requests
        ),
    )
    log(f"DESCRIPTION_MANIFEST {path} requests={len(requests)}")
    return path


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    source = parser.add_mutually_exclusive_group()
    source.add_argument("--pdf", type=Path, help="convert one PDF")
    source.add_argument("--journal-dir", type=Path, help="convert one journal directory")
    source.add_argument("--smoke", action="store_true", help="run the bounded smoke set")
    source.add_argument(
        "--enumerate", action="store_true", help="print per-journal PDF counts"
    )
    source.add_argument(
        "--description-manifest",
        action="store_true",
        help="collect pending figure-description requests",
    )
    parser.add_argument("--journal", help="journal label for --pdf")
    parser.add_argument("--output-root", type=Path, default=DEFAULT_OUTPUT_ROOT)
    parser.add_argument("--corpus-root", type=Path, default=DEFAULT_CORPUS_ROOT)
    parser.add_argument("--corpus-bib", type=Path, default=DEFAULT_CORPUS_BIB)
    parser.add_argument("--repo-bib", type=Path, default=DEFAULT_REPO_BIB)
    parser.add_argument("--page-limit", type=int)
    parser.add_argument("--per-pdf-timeout", type=int, default=1800)
    parser.add_argument(
        "--threads", type=int, default=max(1, min(4, os.cpu_count() or 1))
    )
    parser.add_argument("--resume", action="store_true")
    parser.add_argument("--worker", action="store_true", help=argparse.SUPPRESS)
    return parser


def validate_args(parser: argparse.ArgumentParser, args: argparse.Namespace) -> None:
    if not any(
        (
            args.pdf,
            args.journal_dir,
            args.smoke,
            args.enumerate,
            args.description_manifest,
        )
    ):
        parser.error("choose --pdf, --journal-dir, --smoke, --enumerate, or --description-manifest")
    if args.pdf and not args.journal:
        parser.error("--pdf requires --journal")
    if args.page_limit is not None and args.page_limit < 1:
        parser.error("--page-limit must be positive")
    if args.per_pdf_timeout < 1:
        parser.error("--per-pdf-timeout must be positive")


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    validate_args(parser, args)
    args.output_root = args.output_root.resolve()
    args.corpus_root = args.corpus_root.resolve()
    args.corpus_bib = args.corpus_bib.resolve()
    args.repo_bib = args.repo_bib.resolve()

    if args.enumerate:
        enumerate_corpus(args.corpus_root)
        return 0
    if args.description_manifest:
        write_description_manifest(args.output_root)
        return 0
    if args.pdf and args.worker:
        convert_pdf(
            args.pdf.resolve(),
            args.output_root,
            args.journal,
            args.corpus_root,
            args.corpus_bib,
            args.repo_bib,
            args.page_limit,
            args.threads,
        )
        return 0
    if args.pdf:
        counts = run_batch(
            args, ((args.journal, args.pdf.resolve(), args.page_limit),)
        )
        return 1 if counts["failed"] else 0
    if args.journal_dir:
        journal = args.journal or args.journal_dir.name
        pdfs = (
            (journal, path.resolve(), args.page_limit)
            for path in sorted(args.journal_dir.glob("*.pdf"))
        )
        counts = run_batch(args, pdfs)
        return 1 if counts["failed"] else 0
    if args.smoke:
        counts = run_batch(
            args,
            (
                (journal, path.resolve(), page_limit)
                for journal, path, page_limit in SMOKE_PDFS
            ),
        )
        write_description_manifest(args.output_root)
        return 1 if counts["failed"] else 0
    parser.error("unreachable mode")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
