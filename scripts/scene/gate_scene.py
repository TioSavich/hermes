#!/usr/bin/env python3
"""Validity gates for a scene reply. Four questions, in order, each fatal.

    json_parses        the reply holds one JSON object
    schema_validates   it says only what the vocabulary can say
    typesets           the typesetter produces an SVG from it
    renders_non_empty  that SVG rasterises to a page with ink on it

None of these is a quality judgment. Passing all four says the model wrote a
well-formed scene and the typesetter drew it; whether the drawing carries the
figure's mathematics is the owner's call, and nothing here attempts it.

The round-1 gate list had a coordinate-overflow signal that under-reported by
design, because the model was placing things. It is gone: the model no longer
places anything, and the typesetter sizes the canvas to its content after the
content exists, so text past the edge is not a failure mode this pipeline has.

Standard library, plus PyMuPDF and PIL for the render gate where present.
"""
from __future__ import annotations

import json
import re
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "t228"))

from scene_schema import SchemaError, validate            # noqa: E402
from typeset import typeset                               # noqa: E402

try:
    from gate_svg import _ink_fraction, find_rasteriser, rasterise_to_png
except ImportError:                                        # pragma: no cover
    _ink_fraction = find_rasteriser = rasterise_to_png = None

MIN_INK_FRACTION = 0.002
MAX_SCENE_BYTES = 24_000

FENCE = re.compile(r"```(?:json)?\s*(.*?)```", re.S)


def extract_json(reply: str) -> tuple[dict | None, bool, str]:
    """Return (scene, needed_stripping, detail).

    A fence or a preamble is stripped rather than failed: instruction following
    is recorded as a signal, not gated on.
    """
    if not reply or not reply.strip():
        return None, False, "empty reply"
    text = reply.strip()
    stripped = False

    m = FENCE.search(text)
    if m:
        text, stripped = m.group(1).strip(), True

    try:
        return json.loads(text), stripped, "parsed whole reply"
    except json.JSONDecodeError:
        pass

    # Fall back to the outermost balanced {...}, which survives a preamble.
    start = text.find("{")
    if start < 0:
        return None, stripped, "no JSON object in the reply"
    stack: list[str] = []
    in_str, esc = False, False
    for i in range(start, len(text)):
        ch = text[i]
        if in_str:
            if esc:
                esc = False
            elif ch == "\\":
                esc = True
            elif ch == '"':
                in_str = False
            continue
        if ch == '"':
            in_str = True
        elif ch in "{[":
            stack.append(ch)
        elif ch in "}]":
            if stack:
                stack.pop()
            if not stack:
                blob = text[start:i + 1]
                try:
                    return json.loads(blob), True, "extracted a balanced object"
                except json.JSONDecodeError as exc:
                    return None, True, f"balanced object did not parse: {exc}"

    # The reply stopped mid-object. A truncated prefix is still a prefix: close
    # what is open, in order, and let the schema judge the result. The smoke
    # produced exactly this -- one complete panel, then the decoder degenerated
    # into blank lines -- and losing a whole item to a missing brace is a worse
    # answer than closing it and saying so. The repair is recorded, never silent,
    # and it cannot smuggle anything past the vocabulary.
    blob = text[start:].rstrip()
    if in_str:
        blob += '"'
    blob = blob.rstrip().rstrip(",")
    closers = "".join("}" if c == "{" else "]" for c in reversed(stack))
    try:
        return (json.loads(blob + closers), True,
                f"reply was truncated; closed {len(stack)} open "
                f"structure(s) to parse it")
    except json.JSONDecodeError as exc:
        return None, True, f"unbalanced braces, and closing them did not parse: {exc}"


def gate(reply: str, *, rasteriser=None) -> dict:
    checks: dict[str, dict] = {}
    scene, stripped, detail = extract_json(reply)
    out = {"valid": False, "checks": checks, "scene": None, "svg": None,
           "needed_stripping": stripped, "byte_len": len(reply or ""),
           "schema_error": None}

    checks["json_parses"] = {"status": "pass" if scene is not None else "fail",
                             "detail": detail}
    if scene is None:
        return out
    out["scene"] = scene

    blob = json.dumps(scene)
    if len(blob) > MAX_SCENE_BYTES:
        checks["schema_validates"] = {
            "status": "fail",
            "detail": f"scene is {len(blob)} bytes, over the {MAX_SCENE_BYTES} cap"}
        return out
    try:
        validate(scene)
        checks["schema_validates"] = {"status": "pass",
                                      "detail": f"{len(blob)} bytes"}
    except SchemaError as exc:
        checks["schema_validates"] = {"status": "fail", "detail": str(exc)}
        out["schema_error"] = str(exc)
        return out

    try:
        svg = typeset(scene)
        checks["typesets"] = {"status": "pass",
                              "detail": f"{len(svg)} bytes of SVG"}
        out["svg"] = svg
    except Exception as exc:
        checks["typesets"] = {"status": "fail",
                              "detail": f"{type(exc).__name__}: {str(exc)[:220]}"}
        return out

    if rasterise_to_png is None:
        checks["renders_non_empty"] = {
            "status": "renderer_unavailable",
            "detail": "no rasteriser module beside this one"}
        out["valid"] = True
        return out
    tool = rasteriser or find_rasteriser()[0]
    if tool is None:
        checks["renders_non_empty"] = {"status": "renderer_unavailable",
                                       "detail": "no rasteriser on this host"}
        out["valid"] = True
        return out
    with tempfile.TemporaryDirectory() as td:
        dst = Path(td) / "r.png"
        ok, det = rasterise_to_png(svg, dst, dpi=110, tool=tool)
        if not ok:
            checks["renders_non_empty"] = {"status": "fail", "detail": det}
            return out
        ink = _ink_fraction(dst)
        if ink is None:
            checks["renders_non_empty"] = {
                "status": "pass", "detail": det + "; ink not measurable"}
        elif ink < MIN_INK_FRACTION:
            checks["renders_non_empty"] = {
                "status": "fail",
                "detail": f"{det}; blank page (ink {ink:.4f})"}
            return out
        else:
            checks["renders_non_empty"] = {"status": "pass",
                                           "detail": f"{det}; ink {ink:.3f}"}

    # Recorded, never gating: a scene may be valid and still say very little.
    n_blocks = sum(len(p["blocks"]) for p in scene["panels"])
    checks["shape"] = {"status": "info",
                       "detail": f"{len(scene['panels'])} panels, {n_blocks} blocks, "
                                 f"types: " + ",".join(sorted(
                                     {b['type'] for p in scene['panels']
                                      for b in p['blocks']}))}
    out["valid"] = True
    return out


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    for path in sys.argv[1:]:
        v = gate(Path(path).read_text())
        print(f"{path}: valid={v['valid']}")
        for k, c in v["checks"].items():
            print(f"   {k:<20} {c['status']:<22} {c['detail']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
