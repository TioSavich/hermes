"""Validation and offline SVG rendering for Hermes render documents."""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]
NODE_ADAPTER = REPO_ROOT / "hermes" / "web" / "render" / "node-adapter.js"
SUPPORTED_FORMATS = frozenset(
    {
        "fraction-bars",
        "number-line",
        "area-model",
        "base-ten-columns",
        "place-value-chart",
        "set-grouping",
        "balance-scale",
        "hybridization-model",
        "notation",
        "coordinate-plane",
        "rigid-motion",
        "polyform-tiling",
        "angle-circular",
        "data-display",
        "solid-net",
        "geoboard",
    }
)
NODE_REQUIRED = "Node.js is required to regenerate tracked render galleries"


class RenderDocumentError(ValueError):
    """Raised when a worker result is not a drawable render document."""


class RenderAdapterError(RuntimeError):
    """Raised when the shared Node adapter cannot produce SVG."""


def validate_render_document(document: Any) -> dict[str, Any]:
    """Return *document* after validating its drawable contract shape.

    Scene version 1 remains accepted for the five shipped legacy sources: the
    hybridization, place-value, parametric-deformation, and legacy notation
    compilers, plus the fraction-cliff exporter (export_fraction_cliff.py,
    which emits version-1 fraction-bars scenes from Python). New scene
    compilers use version 2, which is the documented contract. This validator
    still rejects scalars, missing frame arrays, unknown formats, and
    malformed frame metadata. Comparison documents carry frames inside their
    productive/deformation parts; a part validates whenever it is present,
    and top-level frames validate whenever present, so a document is drawable
    when it holds at least one of the two. An error document may carry no
    frames or an annotation-only frame — the area-compare fallback never
    fakes a picture, and a reachable error document still needs to draw.
    """
    if not isinstance(document, dict):
        raise RenderDocumentError("render result must be an object")
    frames = document.get("frames")
    parts = [
        (name, document[name])
        for name in ("productive", "deformation")
        if document.get(name) is not None
    ]
    has_frames = isinstance(frames, list)
    if frames is not None and not has_frames:
        raise RenderDocumentError("render document frames must be an array")
    validated_parts = 0
    for name, part in parts:
        if not isinstance(part, dict):
            # balance_compare and kin carry productive/deformation as plain
            # role-label strings beside top-level frames; only dict parts are
            # nested render document parts.
            continue
        if not isinstance(part.get("frames"), list):
            raise RenderDocumentError(
                f"render document part {name} must hold a frames array")
        _validate_frames(part["frames"], f"{name} ")
        validated_parts += 1
    if not has_frames and not validated_parts:
        raise RenderDocumentError("render document frames must be an array")
    if has_frames:
        _validate_frames(frames, "")
    return document


def _validate_frames(frames: list, where: str) -> None:
    for index, frame in enumerate(frames):
        label = f"{where}frame {index + 1}"
        if not isinstance(frame, dict):
            raise RenderDocumentError(f"{label} must be an object")
        step = frame.get("step")
        if not isinstance(step, int) or isinstance(step, bool) or step < 1:
            raise RenderDocumentError(f"{label} step must be an integer greater than zero")
        verb = frame.get("verb")
        if verb is None:
            verb = frame.get("caption")
        if not isinstance(verb, str):
            raise RenderDocumentError(f"{label} verb must be a string")
        scene = frame.get("scene")
        if not isinstance(scene, dict):
            raise RenderDocumentError(f"{label} scene must be an object")
        scene_format = scene.get("format")
        if scene_format not in SUPPORTED_FORMATS:
            raise RenderDocumentError(f"{label} has unsupported scene format: {scene_format!r}")
        if scene.get("version") not in (1, 2):
            raise RenderDocumentError(f"{label} scene version must be 2")


def _invoke_adapter(payload: dict[str, Any]) -> str:
    node = shutil.which("node")
    if node is None:
        raise RenderAdapterError(NODE_REQUIRED)
    try:
        proc = subprocess.run(
            [node, str(NODE_ADAPTER)],
            input=json.dumps(payload),
            cwd=REPO_ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
    except OSError as exc:
        raise RenderAdapterError(f"{NODE_REQUIRED}: {exc}") from exc
    if proc.returncode != 0:
        detail = proc.stderr.strip() or f"adapter exited with status {proc.returncode}"
        raise RenderAdapterError(f"render adapter failed: {detail}")
    return proc.stdout


def render_svg(
    document: dict[str, Any], mode: str, output_path: str | Path | None = None,
    **options: Any,
) -> str:
    """Render one document through the shared Node adapter.

    ``mode`` is ``frame`` or ``filmstrip``. Layout-only options are forwarded
    to the adapter so exporters keep ownership of captions and filenames.
    """
    validate_render_document(document)
    svg = _invoke_adapter(
        {"document": document, "mode": mode, "options": options, "repoRoot": str(REPO_ROOT)}
    )
    if output_path is not None:
        path = Path(output_path)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(svg, encoding="utf-8")
    return svg


def render_frames(
    document: dict[str, Any], output_dir: str | Path, code: str,
    *, metadata_kind: str | None = None, metadata_payload_kind: str | None = None,
) -> list[Path]:
    validate_render_document(document)
    out_dir = Path(output_dir)
    written = []
    for index, frame in enumerate(document["frames"]):
        options: dict[str, Any] = {
            "index": index,
            "ariaLabel": f"{code} frame {index + 1} {frame.get('verb', '')}".strip(),
        }
        if metadata_kind:
            options["metadataKind"] = metadata_kind
            options["metadata"] = {
                "kind": metadata_payload_kind or metadata_kind,
                "case_code": code,
                "document_kind": document.get("kind", ""),
                "frame_index": index,
                "step": frame.get("step", index + 1),
                "verb": frame.get("verb", ""),
                "caption": frame.get("caption", ""),
                "source": "hybridization_scene_frame",
            }
        path = out_dir / f"{code}-frame-{index + 1}.svg"
        render_svg(document, "frame", path, **options)
        written.append(path)
    return written


def render_monitoring_docs(docs: dict[str, Any], output_dir: str | Path) -> list[Path]:
    payload = {
        "mode": "monitoring",
        "documents": docs,
        "outputDir": str(Path(output_dir)),
        "repoRoot": str(REPO_ROOT),
    }
    return [Path(path) for path in json.loads(_invoke_adapter(payload) or "[]")]


def gallery_output(default: Path) -> Path:
    root = os.environ.get("HERMES_RENDER_CHECK_ROOT", "").strip()
    return Path(root) / default.name if root else default


def normalize_generated(path: Path) -> str | bytes:
    if path.suffix.lower() not in {".svg", ".html", ".htm", ".json", ".txt", ".md"}:
        return path.read_bytes()
    text = path.read_text(encoding="utf-8").replace("\r\n", "\n")
    if path.suffix.lower() == ".svg":
        import xml.etree.ElementTree as ET

        text = text.lstrip("\ufeff")
        if text.startswith("<?xml"):
            text = text.split("?>", 1)[1]
        root = ET.fromstring(text)

        def canonical(element: Any) -> None:
            element.attrib = dict(sorted(element.attrib.items()))
            if element.text is not None and not element.text.strip():
                element.text = None
            if element.tail is not None and not element.tail.strip():
                element.tail = None
            for child in element:
                canonical(child)

        canonical(root)
        return ET.tostring(root, encoding="unicode").strip() + "\n"
    if path.suffix.lower() in {".html", ".htm"}:
        return "\n".join(line.rstrip() for line in text.strip().splitlines()) + "\n"
    return text.rstrip() + "\n"


def check_exporter(exporter: Path, tracked_dir: Path, *, seed_tracked: bool = False) -> int:
    with tempfile.TemporaryDirectory(prefix="hermes-render-check-") as temp:
        fresh = Path(temp) / tracked_dir.name
        if seed_tracked:
            shutil.copytree(tracked_dir, fresh)
        env = os.environ.copy()
        env["HERMES_RENDER_CHECK_ROOT"] = temp
        proc = subprocess.run(
            [sys.executable, str(exporter)], cwd=REPO_ROOT, env=env,
            text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
        )
        if proc.returncode:
            sys.stderr.write(proc.stdout)
            sys.stderr.write(proc.stderr)
            return proc.returncode
        tracked_files = {p.relative_to(tracked_dir) for p in tracked_dir.rglob("*") if p.is_file()}
        fresh_files = {p.relative_to(fresh) for p in fresh.rglob("*") if p.is_file()}
        issues = [f"missing fresh file: {p}" for p in sorted(tracked_files - fresh_files)]
        issues += [f"untracked fresh file: {p}" for p in sorted(fresh_files - tracked_files)]
        for rel in sorted(tracked_files & fresh_files):
            if normalize_generated(tracked_dir / rel) != normalize_generated(fresh / rel):
                issues.append(f"drift: {tracked_dir / rel}")
        if issues:
            for issue in issues:
                print(issue)
            return 1
        print(f"prebaked gallery current: {tracked_dir}")
        return 0
