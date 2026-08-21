#!/usr/bin/env python3
"""Build indexes for generated monitoring and lesson-scene visuals."""
from __future__ import annotations

import argparse
import html
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GENERATED = ROOT / "hermes" / "app" / "web" / "generated"
MONITORING_INDEX = GENERATED / "monitoring_visual_index.json"
BEST_SCENES_INDEX = GENERATED / "best_IM_scenes" / "index.html"


def asset_name(code: str, total: int, index: int, side: str, temporal: bool) -> str:
    suffix = "-filmstrip.svg" if temporal else ".svg"
    stem = f"{code}-{side}" if total == 1 else f"{code}-{index + 1}-{side}"
    return stem + suffix


def monitoring_index() -> dict[str, object]:
    lessons: dict[str, list[dict[str, object]]] = {}
    sources: list[str] = []
    for directory in sorted(GENERATED.glob("monitoring_visuals*")):
        docs_path = directory / "docs.json"
        if not docs_path.is_file():
            continue
        sources.append(str(docs_path.relative_to(ROOT)))
        docs = json.loads(docs_path.read_text(encoding="utf-8"))
        for code, payload in docs.items():
            visuals = payload.get("visuals", []) if isinstance(payload, dict) else []
            for index, visual in enumerate(visuals):
                if not isinstance(visual, dict):
                    continue
                row: dict[str, object] = {
                    "expression": str(visual.get("expression") or "generated visual"),
                    "source": directory.name,
                }
                for side in ("correct", "incorrect"):
                    side_payload = visual.get(side)
                    side_payload = side_payload if isinstance(side_payload, dict) else {}
                    doc = side_payload.get("doc")
                    frames = doc.get("frames", []) if isinstance(doc, dict) else []
                    name = asset_name(str(code), len(visuals), index, side, len(frames) > 1)
                    path = directory / name
                    row[side] = f"/generated/{directory.name}/{name}" if path.is_file() else None
                    row[f"{side}_label"] = str(
                        side_payload.get("description")
                        or (doc.get("error") if isinstance(doc, dict) else "")
                        or "No generated drawing is available for this side."
                    )
                lessons.setdefault(str(code), []).append(row)
    return {"generated_from": sources, "lessons": dict(sorted(lessons.items()))}


def best_scenes_index() -> str:
    directory = BEST_SCENES_INDEX.parent
    cards = []
    for path in sorted(directory.glob("*.svg")):
        label = path.stem.replace("_", " ").replace("-", " ")
        cards.append(
            '<figure><figcaption>{}</figcaption><img src="{}" alt="{}"></figure>'.format(
                html.escape(label), html.escape(path.name), html.escape(label)
            )
        )
    body = "\n".join(cards) or "<p>No lesson scenes were generated.</p>"
    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Generated lesson scenes</title><style>
body{{margin:24px;background:#f8f1df;color:#1b1810;font:16px system-ui,sans-serif}}h1{{font-family:Georgia,serif}}
main{{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:16px}}figure{{margin:0;padding:12px;border:1px solid #cabf9f;background:#fffaf0}}
figcaption{{margin-bottom:8px;font-size:.9rem}}img{{width:100%;height:260px;object-fit:contain;background:#f8f1df}}
</style></head><body><h1>Generated lesson scenes</h1><p>Each card names the lesson and mathematical action carried by the generated scene.</p><main>{body}</main></body></html>
"""


def expected_outputs() -> dict[Path, str]:
    return {
        MONITORING_INDEX: json.dumps(monitoring_index(), indent=2, sort_keys=True) + "\n",
        BEST_SCENES_INDEX: best_scenes_index(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    failures: list[str] = []
    for path, content in expected_outputs().items():
        if args.check:
            actual = path.read_text(encoding="utf-8") if path.is_file() else ""
            if actual != content:
                failures.append(str(path.relative_to(ROOT)))
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")
            print(path.relative_to(ROOT))
    if failures:
        for path in failures:
            print(f"STALE {path}")
        return 1
    if args.check:
        print("PASS generated visual surface indexes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
