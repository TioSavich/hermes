#!/usr/bin/env python3
"""Sync the Docling IM teacher-guide Markdown into its tracked corpus.

The default mode copies source ``document.md`` files byte-for-byte and writes
the deterministic manifest. ``--check`` always verifies the tracked files
against the manifest and, when the local Docling source exists, verifies the
same bytes there too.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.research.extract_lesson_context import picture_description_lines  # noqa: E402

SOURCE_ROOT = (
    ROOT
    / "hermes/app/runtime/experiments/gemma4_tutor/docling/full-output"
    / "TeacherLessonGuides"
)
TRACKED_ROOT = ROOT / "curriculum/im_teacher_guides_docling"
MANIFEST = TRACKED_ROOT / "manifest.json"
EXPECTED_DOCUMENTS = 1308
SCHEMA = "im_teacher_guides_docling_manifest_v1"


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def source_documents() -> list[Path]:
    return sorted(SOURCE_ROOT.glob("**/document.md"))


def manifest_payload(paths: list[Path]) -> dict[str, object]:
    entries = []
    for source in paths:
        relative = source.relative_to(SOURCE_ROOT)
        data = source.read_bytes()
        lines = data.decode("utf-8", errors="replace").splitlines()
        excluded = picture_description_lines(source, lines)
        if excluded is None:
            raise ValueError(
                f"picture annotations cannot be separated for {source.relative_to(ROOT)}"
            )
        entries.append(
            {
                "bytes": len(data),
                "excluded_picture_description_line_indices": sorted(excluded),
                "sha256": sha256_bytes(data),
                "source_path": source.relative_to(ROOT).as_posix(),
                "tracked_path": (TRACKED_ROOT / relative)
                .relative_to(ROOT)
                .as_posix(),
            }
        )
    return {
        "schema": SCHEMA,
        "source_root": SOURCE_ROOT.relative_to(ROOT).as_posix(),
        "tracked_root": TRACKED_ROOT.relative_to(ROOT).as_posix(),
        "file_count": len(entries),
        "total_bytes": sum(int(entry["bytes"]) for entry in entries),
        "files": entries,
    }


def render_manifest(payload: dict[str, object]) -> bytes:
    return (
        json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    ).encode("utf-8")


def validate_manifest(payload: object) -> list[dict[str, object]]:
    if not isinstance(payload, dict) or payload.get("schema") != SCHEMA:
        raise ValueError(f"manifest schema must be {SCHEMA}")
    if payload.get("source_root") != SOURCE_ROOT.relative_to(ROOT).as_posix():
        raise ValueError("manifest source_root drifted")
    if payload.get("tracked_root") != TRACKED_ROOT.relative_to(ROOT).as_posix():
        raise ValueError("manifest tracked_root drifted")
    entries = payload.get("files")
    if not isinstance(entries, list):
        raise ValueError("manifest files must be a list")
    if payload.get("file_count") != len(entries):
        raise ValueError("manifest file_count does not match files")
    if len(entries) != EXPECTED_DOCUMENTS:
        raise ValueError(
            f"manifest has {len(entries)} documents; expected {EXPECTED_DOCUMENTS}"
        )
    tracked_paths = [entry.get("tracked_path") for entry in entries]
    if len(set(tracked_paths)) != len(tracked_paths):
        raise ValueError("manifest repeats a tracked_path")
    if tracked_paths != sorted(tracked_paths):
        raise ValueError("manifest files are not sorted by tracked_path")
    total_bytes = sum(int(entry.get("bytes", -1)) for entry in entries)
    if payload.get("total_bytes") != total_bytes:
        raise ValueError("manifest total_bytes does not match files")
    return entries


def sync() -> int:
    if not SOURCE_ROOT.is_dir():
        print(
            "SKIP sync IM teacher guides: local Docling source is absent; "
            "tracked corpus left unchanged"
        )
        return 0
    paths = source_documents()
    if len(paths) != EXPECTED_DOCUMENTS:
        raise SystemExit(
            f"source has {len(paths)} documents; expected {EXPECTED_DOCUMENTS}"
        )
    payload = manifest_payload(paths)
    expected_relative = {
        path.relative_to(SOURCE_ROOT) for path in paths
    }
    for stale in sorted(TRACKED_ROOT.glob("**/document.md")):
        if stale.relative_to(TRACKED_ROOT) not in expected_relative:
            stale.unlink()
    for source in paths:
        target = TRACKED_ROOT / source.relative_to(SOURCE_ROOT)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
    MANIFEST.parent.mkdir(parents=True, exist_ok=True)
    MANIFEST.write_bytes(render_manifest(payload))
    print(
        f"synced {payload['file_count']} IM teacher-guide documents "
        f"({payload['total_bytes']} bytes)"
    )
    return 0


def check() -> int:
    failures: list[str] = []
    try:
        payload = json.loads(MANIFEST.read_text(encoding="utf-8"))
        entries = validate_manifest(payload)
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        print(f"FAIL IM teacher-guide corpus: {exc}", file=sys.stderr)
        return 1

    expected_tracked = {
        ROOT / str(entry["tracked_path"])
        for entry in entries
    }
    actual_tracked = set(TRACKED_ROOT.glob("**/document.md"))
    for unexpected in sorted(actual_tracked - expected_tracked):
        failures.append(
            f"unexpected tracked document {unexpected.relative_to(ROOT)}"
        )

    source_present = SOURCE_ROOT.is_dir() and not os.environ.get(
        "HERMES_SHIP_C_FORCE_CLONE"
    )
    for entry in entries:
        tracked = ROOT / str(entry["tracked_path"])
        source = ROOT / str(entry["source_path"])
        expected_size = int(entry["bytes"])
        expected_sha = str(entry["sha256"])
        if not tracked.is_file():
            failures.append(f"missing tracked document {tracked.relative_to(ROOT)}")
            continue
        tracked_bytes = tracked.read_bytes()
        if len(tracked_bytes) != expected_size:
            failures.append(f"byte-count drift {tracked.relative_to(ROOT)}")
        if sha256_bytes(tracked_bytes) != expected_sha:
            failures.append(f"sha256 drift {tracked.relative_to(ROOT)}")
        if source_present:
            if not source.is_file():
                failures.append(f"missing source document {source.relative_to(ROOT)}")
            elif source.read_bytes() != tracked_bytes:
                failures.append(
                    f"source-byte mismatch {source.relative_to(ROOT)}"
                )
            else:
                source_lines = tracked_bytes.decode(
                    "utf-8", errors="replace"
                ).splitlines()
                excluded = picture_description_lines(source, source_lines)
                if excluded is None or sorted(excluded) != entry.get(
                    "excluded_picture_description_line_indices"
                ):
                    failures.append(
                        f"picture-description index drift {source.relative_to(ROOT)}"
                    )

    if failures:
        for failure in failures[:20]:
            print(f"FAIL IM teacher-guide corpus: {failure}", file=sys.stderr)
        if len(failures) > 20:
            print(
                f"FAIL IM teacher-guide corpus: {len(failures) - 20} more failure(s)",
                file=sys.stderr,
            )
        return 1
    source_receipt = " and local source bytes" if source_present else ""
    print(
        f"PASS IM teacher-guide corpus: {len(entries)} manifest shas, "
        f"{payload['total_bytes']} tracked bytes{source_receipt} verified"
    )
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="verify tracked files against the manifest and any local source",
    )
    args = parser.parse_args()
    return check() if args.check else sync()


if __name__ == "__main__":
    raise SystemExit(main())
