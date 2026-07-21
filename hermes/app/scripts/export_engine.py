"""Shared process, rendering, and writing machinery for static exporters."""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from contextlib import contextmanager
from collections.abc import Callable, Iterable, Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from hermes.app import rendering


REPO_ROOT = Path(__file__).resolve().parents[3]
RenderAdapterError = rendering.RenderAdapterError


@dataclass(frozen=True)
class SwiplRequest:
    """One document-producing goal within a shared SWI-Prolog process.

    ``goal`` must bind ``Doc`` to a JSON-serializable dict. Request keys are
    returned unchanged and let exporters keep their own ordering and naming.
    """

    key: str
    goal: str


def parse_args(
    description: str | None,
    *,
    default_out: Path | None = None,
    configure: Callable[[argparse.ArgumentParser], None] | None = None,
) -> argparse.Namespace:
    """Parse the common exporter CLI plus exporter-specific registrations."""
    parser = argparse.ArgumentParser(description=description)
    if default_out is not None:
        parser.add_argument(
            "--out",
            type=Path,
            default=default_out,
            help=f"Output directory. Default: {default_out}",
        )
    if configure is not None:
        configure(parser)
    return parser.parse_args()


def gallery_output(default: Path) -> Path:
    return rendering.gallery_output(default)


def check_exporter(exporter: Path, tracked_dir: Path, *, seed_tracked: bool = False) -> int:
    return rendering.check_exporter(exporter, tracked_dir, seed_tracked=seed_tracked)


def _prolog_atom(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "''") + "'"


def run_swipl_batch(
    requests: Sequence[SwiplRequest],
    *,
    prelude: Iterable[str] = (),
    load_paths: bool = True,
) -> dict[str, dict[str, Any]]:
    """Run ordered document goals in one SWI-Prolog process.

    Each successful goal writes one single-line JSON envelope. Chatter from
    consulted sources is ignored; a missing envelope or failed goal aborts the
    whole batch so an exporter cannot silently emit a partial gallery.
    """
    if not requests:
        return {}
    clauses = ["use_module(library(http/json))", *prelude]
    for index, request in enumerate(requests):
        key = _prolog_atom(request.key)
        document_var = f"Document{index}"
        clauses.append(
            "( findall(Doc, once(("
            + request.goal
            + f")), [{document_var}]) -> json_write_dict(user_output, _{{request:"
            + key
            + f", document:{document_var}}}, [width(0)]), nl "
            + "; format(user_error, 'export request failed: ~w~n', ["
            + key
            + "]), halt(2) )"
        )
    clauses.append("halt")
    command = ["swipl", "-q"]
    if load_paths:
        command.extend(["-l", "paths.pl"])
    command.extend(["-g", ", ".join(clauses), "-t", "halt(1)"])
    proc = subprocess.run(
        command,
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    if proc.returncode != 0:
        detail = proc.stderr.strip() or proc.stdout.strip()
        raise RuntimeError(
            f"swipl export batch exited with status {proc.returncode}: {detail}"
        )

    documents: dict[str, dict[str, Any]] = {}
    for line in proc.stdout.splitlines():
        if not line.startswith("{"):
            continue
        try:
            envelope = json.loads(line)
        except json.JSONDecodeError:
            continue
        key = envelope.get("request")
        document = envelope.get("document")
        if isinstance(key, str) and isinstance(document, dict):
            documents[key] = document
    missing = [request.key for request in requests if request.key not in documents]
    if missing:
        detail = proc.stderr.strip() or proc.stdout.strip()
        raise RuntimeError(
            f"swipl export batch produced no document for {', '.join(missing)}: {detail}"
        )
    return documents


@contextmanager
def worker_requester():
    """Yield one persistent Hermes worker request function for a whole export."""
    from hermes.app import server

    try:
        yield server.SERVICES.worker.request
    finally:
        server.SERVICES.worker.close()


def render_svg(
    document: dict[str, Any],
    mode: str,
    output_path: str | Path,
    **options: Any,
) -> Path:
    path = Path(output_path)
    rendering.render_svg(document, mode, path, **options)
    return path


def render_frames(
    document: dict[str, Any], output_dir: str | Path, code: str, **options: Any
) -> list[Path]:
    return rendering.render_frames(document, output_dir, code, **options)


def render_monitoring_docs(
    documents: dict[str, Any], output_dir: str | Path
) -> list[Path]:
    return rendering.render_monitoring_docs(documents, output_dir)


def write_text(path: str | Path, content: str) -> Path:
    target = Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8")
    return target


def write_json(path: str | Path, value: Any) -> Path:
    return write_text(path, json.dumps(value, indent=2))


def write_index(out_dir: str | Path, content: str) -> Path:
    return write_text(Path(out_dir) / "index.html", content)


def exporter_main(
    main: Callable[[], int], output: Path | None = None, *, seed_tracked: bool = False
) -> int:
    """Honor the common drift-check entry point, then run an exporter."""
    if "--check" in sys.argv:
        if output is None:
            raise RuntimeError("--check requires a registered output directory")
        return check_exporter(Path(sys.argv[0]), output, seed_tracked=seed_tracked)
    return main()
