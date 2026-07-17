#!/usr/bin/env python3
"""Executable checks for the canonical Hermes root resolver."""

from __future__ import annotations

import os
import sys
import tempfile
import traceback
from contextlib import contextmanager
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO))

from hermes.app import root as root_module  # noqa: E402
from hermes.app import worker  # noqa: E402
from hermes.app.workflow.lib import monitoring  # noqa: E402


def make_root(parent: Path, name: str) -> Path:
    candidate = parent / name
    candidate.mkdir()
    (candidate / "hermes_worker.pl").touch()
    (candidate / "paths.pl").touch()
    return candidate.resolve()


@contextmanager
def umedcta_root(value: str | None):
    previous = os.environ.get("UMEDCTA_ROOT")
    if value is None:
        os.environ.pop("UMEDCTA_ROOT", None)
    else:
        os.environ["UMEDCTA_ROOT"] = value
    try:
        yield
    finally:
        if previous is None:
            os.environ.pop("UMEDCTA_ROOT", None)
        else:
            os.environ["UMEDCTA_ROOT"] = previous


def check_root_resolution() -> None:
    with tempfile.TemporaryDirectory(prefix="hermes-root-check-") as tmp:
        parent = Path(tmp)
        explicit = make_root(parent, "explicit")
        environment = make_root(parent, "environment")

        with umedcta_root(str(environment)):
            assert root_module.resolve_hermes_root(explicit) == explicit
        print("PASS explicit root precedes UMEDCTA_ROOT")

        with umedcta_root(str(environment)):
            assert root_module.resolve_hermes_root() == environment
        print("PASS UMEDCTA_ROOT precedes the installed default")

        missing_worker = parent / "missing-worker"
        missing_worker.mkdir()
        (missing_worker / "paths.pl").touch()
        missing_paths = parent / "missing-paths"
        missing_paths.mkdir()
        (missing_paths / "hermes_worker.pl").touch()
        for candidate, missing_name in (
            (missing_worker, "hermes_worker.pl"),
            (missing_paths, "paths.pl"),
        ):
            try:
                root_module.resolve_hermes_root(candidate)
            except root_module.HermesRootError as exc:
                message = str(exc)
                assert str(candidate.resolve()) in message
                assert missing_name in message
            else:
                raise AssertionError(f"accepted invalid Hermes root {candidate}")
        print("PASS roots missing hermes_worker.pl or paths.pl are rejected clearly")

        with umedcta_root(str(environment)):
            assert worker.resolve_hermes_root() == monitoring.resolve_hermes_root()
            assert worker.PersistentPrologWorker().umedcta_root == environment
        print("PASS worker and monitoring resolve the same validated root")

    with umedcta_root(None):
        assert root_module.resolve_hermes_root() == REPO
    print("PASS installed hermes.app location resolves the checkout root")


def check_no_legacy_probe() -> None:
    paths = (REPO / "hermes/app/root.py", REPO / "hermes/app/workflow/lib/monitoring.py")
    for path in paths:
        assert "umedcta-formalization" not in path.read_text(encoding="utf-8"), path
    print("PASS root resolution has no legacy repository-name probe")


if __name__ == "__main__":
    try:
        check_root_resolution()
        check_no_legacy_probe()
    except Exception:
        print("FAIL canonical Hermes root resolver checks", file=sys.stderr)
        traceback.print_exc()
        raise SystemExit(1)
