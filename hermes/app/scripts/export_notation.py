#!/usr/bin/env python3
"""Export the notation (glyph-level) demos as SVG filmstrips.

Notation is the eighth representation language: a written equation as a row of
single inscribed characters, each at its own (x, y), each carrying an optional
per-glyph deformation transform (spec §3-§4,
docs/proposals/2026-06-25-notation-in-monitoring-charts.md). The Prolog layer
knowledge/strategies/render/notation_scene.pl and
knowledge/strategies/render/parametric_notation_deformation.pl decide WHAT each scene is
(which glyph reverses, which equals sign carries a chain tick, the literal glyph
row) and emit drawer-compatible frame documents. This script is the projection
step: it runs swipl through paths.pl to get the documents, then pipes each frame
through the shared rendering adapter and hermes/web/render/drawer.js (the
'notation' format), writing per-frame SVGs and a small index.

It renders exactly the three bounded demos of spec §8:

  1. Productive baseline 2+3=5 on the real lesson IM-GK-U1-L12 (no marks, no
     flips) — proves the productive lane and glyph layout.
  2. operational_equals_chain 2+3=5+4=9 — one glyph row with chain-equals ticks.
  3. mirror_written_numeral hosted on IM-GK-U1-L12 — a reversed 3 in a small sum,
     the reversed digit chosen in Prolog, not in JS.

Each demo carries an honesty card stating where it is corpus-attested and where
it is literature-only (spec §2, §8). Output lands under
hermes/app/web/generated/notation_demos/.
"""
from __future__ import annotations

import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO_ROOT))
from hermes.app.scripts import export_engine

DEFAULT_OUT = (
    export_engine.gallery_output(REPO_ROOT / "hermes" / "app" / "web" / "generated" / "notation_demos")
)

# The real K lesson the demos host on. IM-GK-U1-L12 ("count all when count on
# available", addition) is verified at curriculum/im/grade_k.pl:18. The IM K/G1
# corpus has no number-writing lesson, so the notation deformations attach to a
# counting/addition lesson as host (spec §1, §8).
HOST_LESSON = "IM-GK-U1-L12"


# --- The three demos, each (code, swipl goal, honesty card) ------------------
#
# Each goal binds D to a drawer-ready document dict and prints it as JSON.
# The honesty card is the literal label that travels onto the demo card in the
# index, stating corpus-attested vs literature-only per spec §2/§8.

DEMOS = [
    {
        "code": "NOTATION-productive-2plus3-IM-GK-U1-L12",
        "title": "Productive baseline 2+3=5 (IM-GK-U1-L12)",
        "goal": (
            "use_module(render(parametric_notation_deformation)),"
            "productive_notation_scene(write_equation(2,'+',3,5), Doc)"
        ),
        "card": (
            "Productive inscription on the real lesson IM-GK-U1-L12 "
            "(grade_k.pl:18). No marks, no flips: a child correctly writes "
            "2 + 3 = 5. Notation is a real productive language; only its "
            "deformations live in the misconception lane."
        ),
    },
    {
        "code": "NOTATION-operational-equals-chain-2plus3plus4",
        "title": "operational_equals_chain 2+3=5+4=9",
        "goal": (
            "use_module(render(notation_scene)),"
            "notation_render_json("
            "operational_equals_chain_full([2-(+)-3, 5-(+)-4], 9), Doc)"
        ),
        "card": (
            "Equals read as makes: the child chains the running total, writing "
            "2+3=5+4=9 with a chain-equals tick under each = whose two sides "
            "denote unequal quantities. Violation family corpus-attested (513 "
            "multi-= docling transcriptions); K/G1 instance literature-only."
        ),
    },
    {
        "code": "NOTATION-mirror-written-numeral-IM-GK-U1-L12",
        "title": "mirror_written_numeral (hosted on IM-GK-U1-L12)",
        "goal": (
            "use_module(render(parametric_notation_deformation)),"
            "deformed_notation_scene(write_equation(2,'+',3,5),"
            " notation_error(mirror_written_numeral), Doc)"
        ),
        "card": (
            "A reversed digit in a small sum; the reversed digit is chosen in "
            "Prolog from the lesson's number range, not in JS. Literature-only; "
            "no number-writing lesson exists in the IM K/G1 corpus, so it is "
            "hosted on an addition lesson; parametric over reversal-prone "
            "digits, not a corpus instance count."
        ),
    },
]


# --- swipl bridge: get a drawer-ready document for one demo goal --------------

def swipl_docs() -> dict[str, dict]:
    return export_engine.run_swipl_batch([
        export_engine.SwiplRequest(demo["code"], demo["goal"])
        for demo in DEMOS
    ])


# --- shared drawer adapter ---------------------------------------------------


def export_frames(out_dir: Path, code: str, doc: dict) -> list[Path]:
    doc_path = out_dir / f"{code}-doc.json"
    export_engine.write_json(doc_path, doc)
    return export_engine.render_frames(doc, out_dir, code)


# --- index.html (honesty cards, the fraction_cliff_demos pattern) ------------


def write_index(out_dir: Path, rendered: list[dict]) -> Path:
    parts = [
        "<!doctype html><meta charset=utf-8>"
        "<title>Notation in monitoring charts</title>",
        "<body style='font-family:system-ui;background:#f8f1df;padding:24px;"
        "max-width:900px'>",
        "<h1>Notation: the symbol-level companion to spatial representations</h1>",
        "<p>Glyph-level filmstrips from "
        "<code>knowledge/strategies/render/notation_scene.pl</code> and "
        "<code>knowledge/strategies/render/parametric_notation_deformation.pl</code> via "
        "<code>hermes/web/render/drawer.js</code> (the <code>notation</code> "
        "format). Notation denotes the symbol string a child wrote, not the "
        "quantity it was meant to mean. Each deformation is born only as a "
        "labeled misconception (one flagged glyph or one appended mark). The "
        "diff between a correct inscription and its deformation is one field.</p>",
        f"<p>Demos 1 and 3 host on the real lesson <code>{HOST_LESSON}</code> "
        "(<code>grade_k.pl:18</code>). The IM K/Grade-1 corpus carries no "
        "number-writing lesson, so a numeral-reversal deformation attaches to a "
        "counting/addition lesson as host. The honesty card under each demo "
        "states where it is corpus-attested and where it is literature-only.</p>",
    ]
    for item in rendered:
        frames_html = "".join(
            f"<img src='{Path(f).name}' "
            "style='max-width:100%;background:#f8f1df;border:1px solid #cabf9f;"
            "margin:2px 0'>"
            for f in item["frames"]
        )
        parts.append(
            f"<section style='margin:28px 0;padding:16px;"
            "border:1px solid #cabf9f;background:#fdfaf0'>"
            f"<h2 style='margin-top:0'>{item['title']}</h2>"
            f"<p style='color:#5a513c;font-size:0.95em'><strong>Honesty card:"
            f"</strong> {item['card']}</p>"
            f"<p><small><code>{item['code']}</code></small></p>"
            f"{frames_html}"
            "</section>"
        )
    return export_engine.write_index(out_dir, "\n".join(parts) + "\n")


def main() -> int:
    args = export_engine.parse_args(__doc__, default_out=DEFAULT_OUT)
    out_dir = args.out.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    written: list[Path] = []
    rendered: list[dict] = []
    manifest: dict = {"host_lesson": HOST_LESSON, "demos": []}
    documents = swipl_docs()

    for demo in DEMOS:
        code = demo["code"]
        doc = documents[code]
        frame_files = export_frames(out_dir, code, doc)
        written.extend(frame_files)
        rendered.append(
            {
                "code": code,
                "title": demo["title"],
                "card": demo["card"],
                "frames": [str(p) for p in frame_files],
            }
        )
        manifest["demos"].append(
            {
                "code": code,
                "title": demo["title"],
                "card": demo["card"],
                "frame_count": len(doc.get("frames", [])),
                "frames": [p.name for p in frame_files],
            }
        )

    index = write_index(out_dir, rendered)
    written.append(index)
    export_engine.write_json(out_dir / "manifest.json", manifest)

    print(f"Wrote {len(written)} files to {out_dir}")
    for path in written:
        print(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(export_engine.exporter_main(main, DEFAULT_OUT))
