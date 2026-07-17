#!/usr/bin/env python3
"""Verify the manifest and smoke strict-load gates reject bad Prolog."""

from __future__ import annotations

import importlib.util
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def check_manifest_rejects_load_error() -> None:
    manifest = load_module(
        "strict_check_app_manifest", REPO / "scripts/bundle/app_manifest.py"
    )
    with tempfile.TemporaryDirectory(prefix="hermes-manifest-strict-") as tmp:
        tree = Path(tmp)
        (tree / "hermes_worker.pl").write_text(
            "load_runtime :- consult('deliberate_bad.pl').\n", encoding="utf-8"
        )
        (tree / "deliberate_bad.pl").write_text(
            "deliberately_bad(.\n", encoding="utf-8"
        )
        manifest.REPO = tree
        try:
            manifest.worker_closure()
        except SystemExit as exc:
            message = str(exc)
            assert "deliberate_bad.pl" in message, message
        else:
            raise AssertionError("app_manifest accepted a Prolog syntax error")


def check_smoke_rejects_load_warning() -> None:
    smoke = load_module(
        "strict_check_smoke_bundle", REPO / "scripts/bundle/smoke_bundle.py"
    )
    with tempfile.TemporaryDirectory(prefix="hermes-smoke-strict-") as tmp:
        tree = Path(tmp)
        (tree / "hermes_worker.pl").write_text(
            "p(a).\nq.\np(b).\nload_runtime.\n", encoding="utf-8"
        )
        report = smoke.Report()
        accepted = smoke.strict_prolog_preflight(tree, "swipl", report)
        assert not accepted, "smoke preflight accepted a Prolog warning"
        assert "discontiguous" in report.rows[-1][2], report.rows[-1][2]


if __name__ == "__main__":
    check_manifest_rejects_load_error()
    check_smoke_rejects_load_warning()
    print("PASS manifest rejects load errors and smoke rejects load warnings")
