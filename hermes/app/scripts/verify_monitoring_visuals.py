#!/usr/bin/env python3
"""Verify generated monitoring visual artifacts before SVG export."""
from __future__ import annotations

import argparse
import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any


EXPECTED_PROOF_SOURCE = "representation_grammar_and_render_contract"
SVG_NS = "{http://www.w3.org/2000/svg}"
REPRESENTATION_SCENE_FORMATS = {
    "area_model": {"area-model"},
    "balance_scale": {"balance-scale"},
    "base_ten_blocks": {"base-ten-columns"},
    "fraction_bars": {"fraction-bars"},
    "hybridization": {"hybridization-model"},
    "number_line": {"number-line"},
    "notation": {"notation"},
    "place_value_chart": {"place-value-chart"},
    "set_grouping": {"set-grouping"},
}
RENDER_OP_REPRESENTATION = {
    "area_compare": "area_model",
    "area_render": "area_model",
    "balance_compare": "balance_scale",
    "balance_render": "balance_scale",
    "base_ten_compare": "base_ten_blocks",
    "base_ten_render": "base_ten_blocks",
    "fraction_render": "fraction_bars",
    "hybridization_render": "hybridization",
    "number_line_render": "number_line",
    "notation_render": "notation",
    "place_value_chart_render": "place_value_chart",
    "set_grouping_render": "set_grouping",
}


def _frame_sequence(frames: list[Any]) -> list[dict[str, Any]]:
    sequence: list[dict[str, Any]] = []
    for frame in frames:
        if not isinstance(frame, dict):
            continue
        sequence.append(
            {
                "step": frame.get("step"),
                "verb": str(frame.get("verb") or ""),
                "caption": str(frame.get("caption") or ""),
            }
        )
    return sequence


def _frames_for(visual: dict[str, Any], side: str, path: str, issues: list[str]) -> list[Any]:
    side_payload = visual.get(side)
    if not isinstance(side_payload, dict):
        issues.append(f"{path}.{side}: missing side payload")
        return []
    doc = side_payload.get("doc")
    if not isinstance(doc, dict):
        issues.append(f"{path}.{side}: missing doc")
        return []
    frames = doc.get("frames", [])
    if not isinstance(frames, list):
        issues.append(f"{path}.{side}: doc.frames must be a list")
        return []
    return frames


def _check_residue(proof: dict[str, Any], path: str, issues: list[str]) -> None:
    residue = proof.get("interpretive_residue")
    if not isinstance(residue, dict):
        issues.append(f"{path}: missing interpretive residue")
        return
    if residue.get("status") != "human_endorsement_required":
        issues.append(f"{path}: interpretive residue must require human endorsement")
    claim = str(residue.get("claim") or "")
    if "does not certify" not in claim:
        issues.append(f"{path}: interpretive residue must state does not certify")


def _side_representation(grammar: Any) -> str:
    if not isinstance(grammar, dict):
        return ""
    representation = str(grammar.get("representation") or "")
    if representation:
        return representation
    deformation = grammar.get("deformation")
    if isinstance(deformation, dict):
        return str(deformation.get("representation") or "")
    return ""


def _check_scene_formats(
    frames: list[Any],
    representation: str,
    path: str,
    issues: list[str],
) -> None:
    if not representation:
        issues.append(f"{path}: proof grammar must name representation")
        return
    allowed = REPRESENTATION_SCENE_FORMATS.get(representation)
    if not allowed:
        issues.append(f"{path}: no scene-format contract for representation {representation}")
        return
    for index, frame in enumerate(frames):
        scene = frame.get("scene") if isinstance(frame, dict) else {}
        scene = scene if isinstance(scene, dict) else {}
        scene_format = str(scene.get("format") or "")
        if not scene_format:
            issues.append(f"{path}: frame {index + 1} missing scene format")
        elif scene_format not in allowed:
            issues.append(
                f"{path}: scene format {scene_format} is not licensed by "
                f"representation {representation}"
            )


def _check_render_proof_request(
    visual: dict[str, Any],
    side_proof: dict[str, Any],
    side: str,
    path: str,
    issues: list[str],
) -> None:
    side_payload = visual.get(side)
    side_payload = side_payload if isinstance(side_payload, dict) else {}
    render_request = side_payload.get("request")
    proof_request = side_proof.get("request")
    if not isinstance(render_request, dict):
        issues.append(f"{path}.{side}: missing render request")
        return
    if not isinstance(proof_request, dict):
        issues.append(f"{path}.{side}: missing proof request")
        return
    if proof_request.get("op") != "representation_spec_check":
        issues.append(f"{path}.{side}: proof request must use representation_spec_check")

    render_op = str(render_request.get("op") or "")
    expected_representation = RENDER_OP_REPRESENTATION.get(render_op)
    if not expected_representation:
        issues.append(f"{path}.{side}: no proof mapping for render request {render_op}")
    elif proof_request.get("representation") != expected_representation:
        issues.append(
            f"{path}.{side}: render request {render_op} expects proof representation "
            f"{expected_representation}"
        )

    for key, render_value in render_request.items():
        if key == "op":
            continue
        if key in proof_request and proof_request.get(key) != render_value:
            issues.append(
                f"{path}.{side}: proof request {key} does not match render request"
            )


def _check_proof_request_grammar(
    side_proof: dict[str, Any],
    grammar: Any,
    side: str,
    path: str,
    issues: list[str],
) -> None:
    proof_request = side_proof.get("request")
    if not isinstance(proof_request, dict):
        return
    request_representation = str(proof_request.get("representation") or "")
    grammar_representation = _side_representation(grammar)
    if (
        request_representation
        and grammar_representation
        and grammar_representation != request_representation
    ):
        issues.append(
            f"{path}.{side}: grammar representation {grammar_representation} "
            f"does not match proof request representation {request_representation}"
        )


def _check_refusal_request(
    visual: dict[str, Any],
    side_proof: dict[str, Any],
    side: str,
    path: str,
    issues: list[str],
) -> None:
    side_payload = visual.get(side)
    side_payload = side_payload if isinstance(side_payload, dict) else {}
    render_request = side_payload.get("request")
    if not isinstance(render_request, dict):
        issues.append(f"{path}.{side}: missing refusal request")
        return
    if render_request.get("op") != "representation_check":
        issues.append(f"{path}.{side}: refused visual must use representation_check request")
    if render_request.get("mode") != "productive":
        issues.append(f"{path}.{side}: refused visual must check productive mode")
    if not render_request.get("representation"):
        issues.append(f"{path}.{side}: refusal request must name representation")

    grammar = side_proof.get("grammar")
    if not isinstance(grammar, dict):
        issues.append(f"{path}.{side}: refused proof must include grammar")
        return
    if grammar.get("allowed") is not False:
        issues.append(f"{path}.{side}: refusal grammar must have allowed false")
    refusal = str(side_proof.get("refusal") or "")
    grammar_refusal = str(grammar.get("refusal") or "")
    if not grammar_refusal:
        issues.append(f"{path}.{side}: refusal grammar must include refusal")
    elif grammar_refusal != refusal:
        issues.append(f"{path}.{side}: refusal does not match grammar refusal")

    refusals = grammar.get("refusals")
    representation = str(render_request.get("representation") or "")
    if isinstance(refusals, list) and representation:
        representations = {
            str(item.get("representation") or "")
            for item in refusals
            if isinstance(item, dict)
        }
        if representation not in representations:
            issues.append(
                f"{path}.{side}: refusal request representation {representation} "
                "is not listed in grammar refusals"
            )


def _check_side(
    visual: dict[str, Any],
    proof: dict[str, Any],
    side: str,
    path: str,
    issues: list[str],
) -> None:
    frames = _frames_for(visual, side, path, issues)
    side_proof = proof.get(side)
    if not isinstance(side_proof, dict):
        issues.append(f"{path}.{side}: missing proof")
        return

    status = str(side_proof.get("status") or "")
    frame_count = side_proof.get("frame_count")
    temporal = side_proof.get("temporal")
    sequence = side_proof.get("frame_sequence")
    expected_sequence = _frame_sequence(frames)

    if side == "correct" and status != "productive_preserves_denoted_task":
        issues.append(f"{path}.{side}: correct proof must be productive_preserves_denoted_task")

    if status == "refused_by_representation_grammar":
        if frames:
            issues.append(f"{path}.{side}: refused visual has frames")
        if frame_count != 0:
            issues.append(f"{path}.{side}: refused frame_count must be 0")
        if temporal is not False:
            issues.append(f"{path}.{side}: refused temporal must be false")
        if sequence != []:
            issues.append(f"{path}.{side}: refused frame_sequence must be empty")
        if not side_proof.get("refusal"):
            issues.append(f"{path}.{side}: refused proof must include refusal")
        _check_refusal_request(visual, side_proof, side, path, issues)
        return

    if not frames:
        issues.append(f"{path}.{side}: non-refused visual has no frames")
    if frame_count != len(frames):
        issues.append(
            f"{path}.{side}: frame_count {frame_count!r} does not match {len(frames)} frame(s)"
        )
    if temporal is not (len(frames) > 1):
        issues.append(f"{path}.{side}: temporal does not match frame count")
    if sequence != expected_sequence:
        issues.append(f"{path}.{side}: {side} frame_sequence mismatch")
    if frames and not sequence:
        issues.append(f"{path}.{side}: frame_sequence is required when frames are present")

    grammar = side_proof.get("grammar")
    _check_render_proof_request(visual, side_proof, side, path, issues)
    grammar_representation = _side_representation(grammar)
    _check_proof_request_grammar(side_proof, grammar, side, path, issues)
    _check_scene_formats(frames, grammar_representation, f"{path}.{side}", issues)
    if side == "correct" and status == "productive_preserves_denoted_task":
        if not isinstance(grammar, dict) or grammar.get("preserves") is not True:
            issues.append(f"{path}.{side}: productive proof must preserve the task")
    if side == "incorrect" and status != "misconception_deformation":
        issues.append(
            f"{path}.{side}: incorrect proof must be misconception_deformation "
            "or refused_by_representation_grammar"
        )
    if side == "incorrect" and status == "misconception_deformation":
        if not isinstance(grammar, dict) or grammar.get("preserves") is not False:
            issues.append(f"{path}.{side}: misconception proof must not preserve the task")
        elif "deformation" not in grammar:
            issues.append(f"{path}.{side}: misconception proof must include deformation evidence")


def verify_docs(docs: Any) -> list[str]:
    """Return artifact-contract issues for a monitoring visuals docs payload."""
    issues: list[str] = []
    if not isinstance(docs, dict):
        return ["docs: root must be an object"]

    for lesson_code, payload in sorted(docs.items()):
        path = str(lesson_code)
        if not isinstance(payload, dict):
            issues.append(f"{path}: lesson payload must be an object")
            continue
        visuals = payload.get("visuals")
        if not isinstance(visuals, list):
            issues.append(f"{path}: visuals must be a list")
            continue
        for index, visual in enumerate(visuals):
            visual_path = f"{path}.visuals[{index}]"
            if not isinstance(visual, dict):
                issues.append(f"{visual_path}: visual must be an object")
                continue
            proof = visual.get("proof")
            if not isinstance(proof, dict):
                issues.append(f"{visual_path}: missing proof")
                continue
            if proof.get("source") != EXPECTED_PROOF_SOURCE:
                issues.append(f"{visual_path}: proof source must be {EXPECTED_PROOF_SOURCE}")
            _check_residue(proof, visual_path, issues)
            _check_side(visual, proof, "correct", visual_path, issues)
            _check_side(visual, proof, "incorrect", visual_path, issues)

    return issues


def _svg_name(code: str, total: int, index: int, side: str) -> str:
    if total == 1:
        return f"{code}-{side}.svg"
    return f"{code}-{index + 1}-{side}.svg"


def _filmstrip_svg_name(code: str, total: int, index: int, side: str) -> str:
    if total == 1:
        return f"{code}-{side}-filmstrip.svg"
    return f"{code}-{index + 1}-{side}-filmstrip.svg"


def _metadata_element(root: ET.Element) -> ET.Element | None:
    metadata = root.find(f"{SVG_NS}metadata")
    if metadata is not None:
        return metadata
    return root.find("metadata")


def _load_svg(path: Path, issue_path: str, issues: list[str]) -> ET.Element | None:
    try:
        return ET.fromstring(path.read_text(encoding="utf-8"))
    except OSError as exc:
        issues.append(f"{issue_path}: {exc}")
        return None
    except ET.ParseError as exc:
        issues.append(f"{issue_path}: invalid SVG XML: {exc}")
        return None


def _load_svg_metadata(root: ET.Element, issue_path: str, issues: list[str]) -> dict[str, Any] | None:
    metadata = _metadata_element(root)
    if metadata is None or not (metadata.text or "").strip():
        issues.append(f"{issue_path}: missing SVG metadata")
        return None
    try:
        payload = json.loads(metadata.text or "{}")
    except json.JSONDecodeError as exc:
        issues.append(f"{issue_path}: invalid SVG metadata JSON: {exc}")
        return None
    if not isinstance(payload, dict):
        issues.append(f"{issue_path}: SVG metadata must be an object")
        return None
    return payload


def _frame_panel_count(root: ET.Element) -> int:
    return sum(1 for element in root.iter() if "data-frame-index" in element.attrib)


def _check_svg_metadata(
    metadata: dict[str, Any],
    visual: dict[str, Any],
    proof: dict[str, Any],
    code: str,
    index: int,
    side: str,
    expected_kind: str,
    issue_path: str,
    issues: list[str],
) -> None:
    side_proof = proof.get(side) if isinstance(proof.get(side), dict) else {}
    side_proof = side_proof if isinstance(side_proof, dict) else {}
    residue = proof.get("interpretive_residue")

    expected = {
        "kind": expected_kind,
        "lesson_code": code,
        "visual_index": index,
        "side": side,
        "expression": str(visual.get("expression") or ""),
    }
    for key, value in expected.items():
        if metadata.get(key) != value:
            issues.append(f"{issue_path}: SVG metadata {key} mismatch")

    metadata_proof = metadata.get("proof")
    if not isinstance(metadata_proof, dict):
        issues.append(f"{issue_path}: SVG metadata missing proof object")
        return
    proof_expectations = {
        "source": proof.get("source"),
        "status": side_proof.get("status"),
        "frame_count": side_proof.get("frame_count"),
        "temporal": side_proof.get("temporal"),
        "frame_sequence": side_proof.get("frame_sequence"),
    }
    for key, value in proof_expectations.items():
        if metadata_proof.get(key) != value:
            issues.append(f"{issue_path}: SVG metadata proof.{key} mismatch")

    metadata_residue = metadata.get("interpretive_residue")
    if metadata_residue != residue:
        issues.append(f"{issue_path}: SVG metadata interpretive_residue mismatch")


def verify_svg_files(docs: Any, svg_dir: Path) -> list[str]:
    """Return issues for exported SVG files and their embedded proof metadata."""
    issues: list[str] = []
    if not isinstance(docs, dict):
        return ["docs: root must be an object"]

    for lesson_code, payload in sorted(docs.items()):
        if not isinstance(payload, dict):
            continue
        visuals = payload.get("visuals")
        if not isinstance(visuals, list):
            continue
        for index, visual in enumerate(visuals):
            if not isinstance(visual, dict):
                continue
            proof = visual.get("proof")
            if not isinstance(proof, dict):
                continue
            for side in ("correct", "incorrect"):
                side_proof = proof.get(side) if isinstance(proof.get(side), dict) else {}
                side_proof = side_proof if isinstance(side_proof, dict) else {}
                frames = _frames_for(
                    visual,
                    side,
                    f"{lesson_code}.visuals[{index}]",
                    issues,
                )
                if not frames:
                    continue
                name = _svg_name(str(lesson_code), len(visuals), index, side)
                path = svg_dir / name
                issue_path = f"{lesson_code}.visuals[{index}].{side}.{name}"
                if not path.is_file():
                    issues.append(f"{issue_path}: missing SVG file")
                    continue
                root = _load_svg(path, issue_path, issues)
                if root is None:
                    continue
                metadata = _load_svg_metadata(root, issue_path, issues)
                if metadata is None:
                    continue
                _check_svg_metadata(
                    metadata,
                    visual,
                    proof,
                    str(lesson_code),
                    index,
                    side,
                    "hermes_monitoring_visual_proof",
                    issue_path,
                    issues,
                )
                if side_proof.get("temporal") is True:
                    filmstrip_name = _filmstrip_svg_name(str(lesson_code), len(visuals), index, side)
                    filmstrip_path = svg_dir / filmstrip_name
                    filmstrip_issue_path = (
                        f"{lesson_code}.visuals[{index}].{side}.{filmstrip_name}"
                    )
                    if not filmstrip_path.is_file():
                        issues.append(f"{filmstrip_issue_path}: missing temporal filmstrip SVG file")
                        continue
                    filmstrip_root = _load_svg(
                        filmstrip_path,
                        filmstrip_issue_path,
                        issues,
                    )
                    if filmstrip_root is None:
                        continue
                    filmstrip_metadata = _load_svg_metadata(
                        filmstrip_root,
                        filmstrip_issue_path,
                        issues,
                    )
                    if filmstrip_metadata is None:
                        continue
                    _check_svg_metadata(
                        filmstrip_metadata,
                        visual,
                        proof,
                        str(lesson_code),
                        index,
                        side,
                        "hermes_monitoring_visual_filmstrip_proof",
                        filmstrip_issue_path,
                        issues,
                    )
                    panel_count = _frame_panel_count(filmstrip_root)
                    expected_count = side_proof.get("frame_count")
                    if panel_count != expected_count:
                        issues.append(
                            f"{filmstrip_issue_path}: filmstrip frame panel count "
                            f"{panel_count} does not match proof frame_count {expected_count}"
                        )

    return issues


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("docs", type=Path, help="Path to generated monitoring visuals docs.json")
    parser.add_argument(
        "--svg-dir",
        type=Path,
        help="Optional directory of generated SVG files to check for embedded proof metadata.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        docs = json.loads(args.docs.read_text(encoding="utf-8"))
    except OSError as exc:
        sys.stderr.write(f"{args.docs}: {exc}\n")
        return 2
    except json.JSONDecodeError as exc:
        sys.stderr.write(f"{args.docs}: invalid JSON: {exc}\n")
        return 2

    issues = verify_docs(docs)
    if args.svg_dir is not None:
        issues.extend(verify_svg_files(docs, args.svg_dir))
    if issues:
        for issue in issues:
            sys.stderr.write(issue + "\n")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
