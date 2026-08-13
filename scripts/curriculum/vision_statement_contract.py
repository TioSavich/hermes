#!/usr/bin/env python3
"""Shared acceptance and source-mapping contract for vision statements."""

from __future__ import annotations

import hashlib
import json
from pathlib import PurePath
import re
from typing import Any


NARROW_DESCRIPTION_CLASS = "narrow_description_contiguous_v1"
WIDENED_CHECKPOINT_CLASS = "widened_checkpoint_receipt_v1"
WIDENED_METHOD = "printed_math_and_structured_figure_reading"


def normalized_contiguous_span(statement: str, source: str) -> tuple[int, int] | None:
    """Locate an exact statement after collapsing each whitespace run."""
    words = statement.split()
    if not words:
        return None
    match = re.search(r"\s+".join(re.escape(word) for word in words), source)
    return match.span() if match is not None else None


def recovery_provenance_class(recovery: dict[str, Any]) -> str:
    """Classify a vision recovery without changing the narrow contract."""
    explicit = recovery.get("provenance_class")
    if explicit is not None:
        return str(explicit)
    if recovery.get("prompt_version") and isinstance(recovery.get("readings"), list):
        return WIDENED_CHECKPOINT_CLASS
    return NARROW_DESCRIPTION_CLASS


def response_sha256(response: dict[str, Any]) -> str:
    """Hash the stored client response exactly as the widened runner does."""
    return hashlib.sha256(json.dumps(response, sort_keys=True).encode()).hexdigest()


def _format_number(value: float | int) -> str:
    return str(int(value)) if float(value).is_integer() else str(value)


def textualize_figure(reading: dict[str, Any], asset: str) -> str:
    """Render an accepted structured reading as deterministic task text."""
    points = ", ".join(
        f"{point['label']}=({_format_number(point['x'])}, {_format_number(point['y'])})"
        for point in reading["points"]
    )
    shapes = "; ".join(
        f"{shape['label'] or shape['kind']}: vertices " + ", ".join(shape["vertices"])
        for shape in reading["shapes"]
    )
    lines = "; ".join(
        f"{line['label'] or line['kind']}: {line['kind']} through "
        + ", ".join(line["through"])
        for line in reading["lines"]
    )
    parts = [
        f"[Recovered figure from {PurePath(asset).name}]",
        f"Named points: {points}.",
    ]
    if shapes:
        parts.append(f"Shapes: {shapes}.")
    if lines:
        parts.append(f"Lines: {lines}.")
    if reading["printed_text"]:
        parts.append(f"Printed text: {reading['printed_text']}")
    return " ".join(parts)


def compose_widened_statement(checkpoints: list[dict[str, Any]]) -> str:
    """Compose the statement licensed by accepted widened checkpoints."""
    if not checkpoints:
        raise ValueError("widened recovery has no accepted checkpoints")
    originals = {item.get("original_excerpt") for item in checkpoints}
    if len(originals) != 1 or not all(isinstance(item, str) for item in originals):
        raise ValueError("widened checkpoints disagree on the original statement")
    complete = next(
        (
            item
            for item in checkpoints
            if item.get("reading", {}).get("class") == "task_statement"
        ),
        None,
    )
    statement = (
        complete["reading"]["printed_text"]
        if complete is not None
        else checkpoints[0]["original_excerpt"]
    )
    additions = []
    for checkpoint in checkpoints:
        channel = checkpoint.get("accepted_channel")
        reading = checkpoint.get("reading", {})
        if channel == "printed_math":
            additions.append(
                "[Recovered printed mathematics from "
                f"{PurePath(checkpoint['asset']).name}] {reading['printed_text']}"
            )
        elif channel == "figure_reading":
            additions.append(textualize_figure(reading, checkpoint["asset"]))
        elif channel == "task_statement":
            if reading.get("class") != "task_statement":
                raise ValueError("task-statement channel lacks a task statement")
        else:
            raise ValueError(f"unknown widened acceptance channel: {channel}")
    if additions:
        statement = statement.rstrip() + "\n\n" + "\n\n".join(additions)
    return statement


def widened_statement_receipt(
    statement: str,
    recovery: dict[str, Any],
    checkpoints: list[dict[str, Any]],
) -> dict[str, Any]:
    """Validate a statement against raw widened checkpoint receipts."""
    if recovery_provenance_class(recovery) != WIDENED_CHECKPOINT_CLASS:
        raise ValueError("vision recovery is not the widened provenance class")
    prompt_version = recovery.get("prompt_version")
    if not isinstance(prompt_version, str) or not prompt_version:
        raise ValueError("widened recovery lacks a prompt version")
    if recovery.get("method") != WIDENED_METHOD:
        raise ValueError("widened recovery method is not recognized")
    if not checkpoints:
        raise ValueError("widened recovery has no checkpoint receipts")
    readings = recovery.get("readings")
    if not isinstance(readings, list) or len(readings) != len(checkpoints):
        raise ValueError("widened reading and checkpoint counts differ")

    paths = []
    response_hashes = []
    for reading_receipt, checkpoint in zip(readings, checkpoints):
        if not checkpoint.get("accepted"):
            raise ValueError("widened checkpoint is not accepted")
        if checkpoint.get("prompt_version") != prompt_version:
            raise ValueError("widened checkpoint prompt version differs")
        response = checkpoint.get("response")
        if (
            not isinstance(response, dict)
            or response.get("outcome") != "ok"
            or response.get("raw_response") is None
        ):
            raise ValueError("widened checkpoint lacks its ok raw response")
        channel = checkpoint.get("accepted_channel")
        terminal = checkpoint.get("terminal_class")
        if (channel, terminal) not in {
            ("task_statement", "text_recovered"),
            ("printed_math", "text_recovered"),
            ("figure_reading", "figure_recovered"),
        }:
            raise ValueError("widened checkpoint has an invalid acceptance path")
        if channel == "figure_reading" and not checkpoint.get("render_receipt"):
            raise ValueError("figure reading lacks its deterministic render receipt")
        digest = response_sha256(response)
        expected = {
            "call_id": checkpoint.get("call_id"),
            "asset": checkpoint.get("asset"),
            "description_file": checkpoint.get("description_file"),
            "reading": checkpoint.get("reading"),
            "render_receipt": checkpoint.get("render_receipt"),
            "response_sha256": digest,
        }
        if reading_receipt != expected:
            raise ValueError("widened recovery reading differs from its checkpoint")
        paths.append(
            {
                "accepted_channel": channel,
                "terminal_class": terminal,
                "call_id": checkpoint["call_id"],
            }
        )
        response_hashes.append(digest)

    expected_statement = compose_widened_statement(checkpoints)
    if " ".join(statement.split()) != " ".join(expected_statement.split()):
        raise ValueError("widened statement differs from its acceptance receipts")
    if " ".join(str(recovery.get("statement", "")).split()) != " ".join(
        expected_statement.split()
    ):
        raise ValueError("widened provenance statement differs from its receipts")
    if recovery.get("call_id") != checkpoints[0].get("call_id"):
        raise ValueError("widened primary call ID differs from its first receipt")
    if recovery.get("response_sha256") != response_hashes[0]:
        raise ValueError("widened primary response hash differs")
    recorded_paths = recovery.get("acceptance_paths")
    if recorded_paths is not None and recorded_paths != paths:
        raise ValueError("widened recorded acceptance paths differ")
    return {
        "provenance_class": WIDENED_CHECKPOINT_CLASS,
        "prompt_version": prompt_version,
        "acceptance_paths": paths,
        "response_sha256s": response_hashes,
    }
