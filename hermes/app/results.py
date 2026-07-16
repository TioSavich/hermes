"""List and safely read the workflow outputs under runtime/output/.

Viewing outputs is student data, so the server gates these behind an unlocked
gate. Path reads are confined to runtime/output/ (no traversal).
"""
from __future__ import annotations

from pathlib import Path

# Display order + friendly labels for the Results surface.
SECTIONS = [
    ("profiles", "Profiles"),
    ("scores", "PML scores"),
    ("metrics", "Metrics"),
    ("parsed", "Parsed discussions"),
    ("canvas", "Pairing (Canvas HTML)"),
    ("grades", "Grades"),
    ("content", "Homework reads"),
]

_KIND_BY_EXT = {
    ".md": "markdown", ".csv": "csv", ".json": "json",
    ".jsonl": "jsonl", ".html": "html", ".dot": "text", ".txt": "text",
}


def list_outputs(runtime: Path) -> dict:
    """Return {section: [relpaths]} for everything under runtime/output/."""
    base = runtime / "output"
    index: dict[str, list[str]] = {}
    for sub, _label in SECTIONS:
        d = base / sub
        if not d.is_dir():
            continue
        files = [
            str(p.relative_to(base))
            for p in sorted(d.rglob("*"))
            if p.is_file() and not p.name.startswith(".")
        ]
        if files:
            index[sub] = files
    return {"sections": SECTIONS, "files": index}


def read_output_file(runtime: Path, relpath: str) -> dict:
    """Read a single output file, confined to runtime/output/."""
    base = (runtime / "output").resolve()
    target = (base / relpath).resolve()
    if target != base and base not in target.parents:
        raise ValueError("path escapes the output directory")
    if not target.is_file():
        raise FileNotFoundError(relpath)
    kind = _KIND_BY_EXT.get(target.suffix.lower(), "text")
    return {
        "path": relpath,
        "kind": kind,
        "content": target.read_text(encoding="utf-8", errors="replace"),
    }
