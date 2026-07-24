#!/usr/bin/env python3
"""Build deterministic query indexes from collected literature checkpoints."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import tempfile
from collections import Counter
from pathlib import Path
from typing import Any


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


def atomic_write(path: Path, text: str) -> None:
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


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def load_records(root: Path) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    successes = []
    failures = []
    seen = set()
    for path in sorted(root.glob("*/*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        relative = path.relative_to(root).as_posix()
        if path.name.endswith(".error.json"):
            failures.append({"sidecar": relative, **data})
            continue
        if data.get("status") != "complete":
            raise ValueError(f"{relative}: expected status=complete")
        source_id = (
            data["source"]["journal_dir"],
            data["source"]["filename"],
        )
        if source_id in seen:
            raise ValueError(f"duplicate source: {source_id}")
        seen.add(source_id)
        markdown = path.with_suffix(".md")
        if not markdown.is_file():
            raise ValueError(f"{relative}: missing Markdown peer")
        successes.append(
            {
                "sidecar": relative,
                "markdown": markdown.relative_to(root).as_posix(),
                "bib_key": data.get("bibliography", {}).get("key"),
                "bib_status": data.get("bibliography", {}).get("status"),
                "page_count": data.get("page_count"),
                "converted_page_range": data.get("converted_page_range"),
                "source": data.get("source"),
                "document_counts": data.get("document_counts"),
            }
        )
    successes.sort(
        key=lambda row: (
            row["source"]["journal_dir"],
            row["source"]["filename"],
        )
    )
    failures.sort(
        key=lambda row: (
            row.get("source", {}).get("journal_dir", ""),
            row.get("source", {}).get("filename", ""),
        )
    )
    return successes, failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input_root", type=Path)
    parser.add_argument(
        "--output-root",
        type=Path,
        help="defaults to INPUT_ROOT",
    )
    parser.add_argument("--require-all-journals", action="store_true")
    args = parser.parse_args()
    root = args.input_root.resolve()
    output_root = (args.output_root or root).resolve()
    successes, failures = load_records(root)
    journals = Counter(row["source"]["journal_dir"] for row in successes)
    if args.require_all_journals:
        missing = [journal for journal in JOURNALS if journal not in journals]
        if missing:
            raise SystemExit(f"missing journal outputs: {', '.join(missing)}")

    jsonl = "".join(
        json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n"
        for row in successes
    )
    failure_jsonl = "".join(
        json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n"
        for row in failures
    )
    manifest = {
        "schema_version": 1,
        "records": len(successes),
        "failures": len(failures),
        "matched": sum(1 for row in successes if row["bib_status"] == "matched"),
        "unkeyed": sum(1 for row in successes if row["bib_status"] == "unkeyed"),
        "per_journal": dict(sorted(journals.items())),
        "index_sha256": sha256_text(jsonl),
        "failure_index_sha256": sha256_text(failure_jsonl),
    }
    atomic_write(output_root / "corpus_index.jsonl", jsonl)
    atomic_write(output_root / "corpus_failures.jsonl", failure_jsonl)
    atomic_write(
        output_root / "corpus_manifest.json",
        json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
    )
    print(
        f"MERGE_COMPLETE records={len(successes)} failures={len(failures)} "
        f"sha256={manifest['index_sha256']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
