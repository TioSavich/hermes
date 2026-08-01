#!/usr/bin/env python3
"""The review PDF: the scan left, the typeset scene right, the reasons beneath.

Rebuilt from the round-1 layout, which pinned the verdict box to the foot of a
fixed page and left a dead half-page above it on every short item. Here nothing
is pinned. Text is measured with the font's real metrics, wrapped, and drawn
line by line, so a block occupies exactly the height it needs and the next block
starts there. The checkbox strip follows the last block directly, and the page
is cut to the content rather than the content stretched to the page.

The two image panes share one height, chosen so both fit the row at their own
aspect ratios. A tall narrow scan and a wide short drawing no longer produce one
full box and one mostly-empty one.

Built entirely offline by PyMuPDF. No network, no browser, no HTML anywhere.

    python3 build_compare_pdf.py --run out/smoke-local
"""
from __future__ import annotations

import argparse
import json
import sys
import tempfile
from pathlib import Path

try:
    import fitz  # PyMuPDF
except ImportError:
    sys.exit("PyMuPDF is required: pip install pymupdf")

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "t228"))
from gate_svg import find_rasteriser, rasterise_to_png    # noqa: E402

PW = 900.0
M = 40.0
COL = PW - 2 * M

INK = (0.05, 0.05, 0.03)
MUTED = (0.45, 0.42, 0.40)
LINE = (0.80, 0.77, 0.72)
PAPER = (0.957, 0.918, 0.839)
RUST = (0.725, 0.322, 0.220)
BLUE = (0.298, 0.420, 0.541)
GREEN = (0.431, 0.545, 0.365)
GOLD = (0.66, 0.49, 0.14)
BAND = {"misconception": RUST, "strategy": GREEN, "notation": GOLD,
        "thin": MUTED}

SERIF, MONO, BOLD = "helv", "cour", "hebo"
MAX_PANE_H = 430.0
MIN_PANE_H = 150.0


def wrap(text: str, width: float, size: float, font: str) -> list[str]:
    """Greedy wrap using the font's real advance widths."""
    out: list[str] = []
    for para in (text or "").split("\n"):
        if not para.strip():
            out.append("")
            continue
        line = ""
        for word in para.split(" "):
            trial = f"{line} {word}".strip()
            if line and fitz.get_text_length(trial, font, size) > width:
                out.append(line)
                line = word
            else:
                line = trial
        # A single word wider than the column still has to break somewhere.
        while fitz.get_text_length(line, font, size) > width and len(line) > 1:
            cut = len(line)
            while cut > 1 and fitz.get_text_length(line[:cut], font, size) > width:
                cut -= 1
            out.append(line[:cut])
            line = line[cut:]
        out.append(line)
    return out


def flow(page, x: float, y: float, width: float, text: str, *, size=9.5,
         font=SERIF, color=INK, lead=1.34) -> float:
    """Draw wrapped text line by line. Returns the y below the last line."""
    lines = wrap(text, width, size, font)
    for ln in lines:
        y += size * lead
        if ln:
            page.insert_text((x, y), ln, fontsize=size, fontname=font,
                             color=color)
    return y


def flow_h(text: str, width: float, *, size=9.5, font=SERIF, lead=1.34) -> float:
    return len(wrap(text, width, size, font)) * size * lead


def kicker(page, x, y, label, color=MUTED) -> float:
    y += 8.5
    page.insert_text((x, y), label.upper(), fontsize=7.2, fontname=MONO,
                     color=color)
    return y + 3


def grounding_lines(item: dict) -> list[tuple[str, tuple]]:
    """The Hermes rows as the tool returned them, as (text, colour) lines."""
    if not item["grounding"]:
        return [("No Hermes rows were retrieved for this figure. The model was "
                 "given the description alone.", MUTED)]
    out: list[tuple[str, tuple]] = []
    for g in item["grounding"]:
        out.append((f"[{g['op']}] {json.dumps(g['arguments'])}", INK))
        if g.get("input_provenance"):
            for ln in wrap("input: " + g["input_provenance"], COL - 16, 7.2, MONO):
                out.append(("  " + ln, MUTED))
        r = g["result"]
        if not r.get("ok", True) and r.get("refusal"):
            out.append((f"  REFUSED: {r['refusal']}", RUST))
            for ln in wrap("why: " + r.get("diagnosis", ""), COL - 24, 7.2, MONO):
                out.append(("    " + ln, RUST))
        elif "steps" in r:
            out.append((f"  automaton {r.get('strategy')}  ->  {r.get('result')}",
                        INK))
            for s in r["steps"]:
                t = f"    {s['n']}. {s['label']}"
                if s.get("value"):
                    t += f"  ->  {s['value']}"
                out.append((t[:126], INK))
        elif "rows" in r:
            if not r["rows"]:
                out.append((f"  no rows matched (count {r.get('count', 0)})", MUTED))
            for row in r["rows"]:
                out.append((f"  - {row['name']} [{row.get('domain', '?')}] "
                            f"{row.get('db_row', '')}", INK))
                for ln in wrap(row.get("citation", ""), COL - 32, 7.2, MONO):
                    out.append(("      " + ln, MUTED))
        if g.get("reproduces_figure") is False:
            for ln in wrap(f"this automaton does not reach the figure's own "
                           f"answer ({g.get('figure_answer')})", COL - 24, 7.2,
                           MONO):
                out.append(("  ! " + ln, RUST))
        out.append(("", INK))
    return out


def pane_geometry(scan: Path | None, drawn: Path | None) -> tuple[float, float, float]:
    """One height for both panes; each width follows its own aspect ratio."""
    def ar(p):
        if not p or not Path(p).exists():
            return 1.4
        try:
            px = fitz.Pixmap(str(p))
            return max(px.width / px.height, 0.15)
        except Exception:
            return 1.4
    al, ard = ar(scan), ar(drawn)
    gap = 16.0
    h = (COL - gap) / (al + ard)
    h = max(MIN_PANE_H, min(MAX_PANE_H, h))
    wl, wr = h * al, h * ard
    if wl + wr + gap > COL:                 # the cap can overshoot; rescale
        k = (COL - gap) / (wl + wr)
        wl, wr, h = wl * k, wr * k, h * k
    return wl, wr, h


def draw_pane(page, x, y, w, h, title, img, note):
    page.insert_text((x, y - 4), title.upper(), fontsize=7.2, fontname=MONO,
                     color=MUTED)
    rect = fitz.Rect(x, y, x + w, y + h)
    page.draw_rect(rect, color=LINE, width=0.7, fill=(1, 1, 1))
    if img and Path(img).exists():
        try:
            page.insert_image(rect + (3, 3, -3, -3), filename=str(img),
                              keep_proportion=True)
            return
        except Exception as exc:
            note = f"could not place image: {type(exc).__name__}"
    flow(page, x + 10, y + h / 2 - 20, w - 20, note, size=9, color=MUTED)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--items", default="items/items.jsonl")
    ap.add_argument("--run", required=True)
    ap.add_argument("--output", default="")
    ap.add_argument("--dpi", type=int, default=150)
    args = ap.parse_args()

    here = Path(__file__).resolve().parent
    items = {}
    for line in (here / args.items).read_text().splitlines():
        if line.strip():
            r = json.loads(line)
            items[r["item_id"]] = r
    run_dir = Path(args.run) if Path(args.run).is_absolute() else here / args.run
    out_pdf = Path(args.output) if args.output else run_dir / "compare.pdf"

    results = {}
    rp = run_dir / "results.jsonl"
    if rp.exists():
        for line in rp.read_text().splitlines():
            if line.strip():
                r = json.loads(line)
                results[r["item_id"]] = r
    meta = {}
    if (run_dir / "run_meta.json").exists():
        meta = json.loads((run_dir / "run_meta.json").read_text())

    _, ras_label = find_rasteriser()
    order = [i for i in items if i in results] or list(items)
    doc = fitz.open()
    tmp = tempfile.TemporaryDirectory()
    tmpdir = Path(tmp.name)

    # ---- cover ------------------------------------------------------------
    cover = doc.new_page(width=PW, height=1080)
    cover.draw_rect(fitz.Rect(0, 0, PW, 1080), color=None, fill=PAPER)
    y = M
    y = flow(cover, M, y, COL,
             "Can the model redraw the mathematics it cannot see?",
             size=19, font=BOLD) + 10
    y = flow(cover, M, y, COL,
             "Round 2. The model no longer draws.", size=12, font=BOLD,
             color=RUST) + 6
    y = flow(cover, M, y, COL,
             "Round 1 asked gemma-4-E2B-it for SVG. It named the right "
             "mathematics and then destroyed it with coordinates: labels "
             "printed over each other, a filled rectangle drawn across its own "
             "caption, text past the edge of the canvas. The content was mostly "
             "sound and unreadable.\n\n"
             "So the job is split. The model writes a scene -- what the panels "
             "are, which digit carries a strike or a carry, what the note says "
             "-- in a small vocabulary with no way to express a coordinate. A "
             "deterministic typesetter turns that into the figure on the right, "
             "measuring every column and sizing the canvas to the content after "
             "the content exists. Overlap and overflow are not failure modes "
             "this pipeline has.\n\n"
             "Left on each page is the figure as it was scanned out of a "
             "research article. Right is what the model's scene typesets to, "
             "having never seen the image. The question is not whether the two "
             "look alike. It is whether the drawing carries the error, the "
             "strategy, or the notational claim the scan documents.\n\n"
             "The gate line reports VALIDITY ONLY: the reply held JSON, the JSON "
             "obeyed the vocabulary, the typesetter drew it, and the drawing has "
             "ink on it. No machine here judges whether the essence was caught. "
             "That is yours; mark the box under each page.",
             size=10.5) + 16

    counts: dict[str, int] = {}
    for iid in order:
        counts[items[iid]["band"]] = counts.get(items[iid]["band"], 0) + 1
    valid_n = sum(1 for i in order if results.get(i, {}).get("valid"))
    secs = [results[i]["seconds"] for i in order if i in results]
    facts = [
        f"items in this document   {len(order)}"
        f"   ({', '.join(f'{k} {v}' for k, v in sorted(counts.items()))})",
        f"passed the validity gates   {valid_n} / {len(order)}",
        f"model   {meta.get('model', '?')}",
        f"endpoint   {meta.get('base_url', '?')}",
        f"temperature   {meta.get('temperature', '?')}   "
        f"attempts per item   {meta.get('attempts', '?')}",
        f"rasteriser   {ras_label}",
        f"run label   {meta.get('run_label', '?')}",
        (f"generation time   {min(secs):.1f}-{max(secs):.1f} s per item"
         if secs else "generation time   n/a"),
    ]
    y = flow(cover, M, y, COL, "\n".join(facts), size=9, font=MONO,
             color=MUTED) + 14
    y = flow(cover, M, y, COL,
             "Two things this document cannot show you.\n\n"
             "The figure descriptions were produced by an earlier LLM pass whose "
             "generating script is not in the repository: no model, prompt, or "
             "timestamp was recorded. A success here shows the model can redraw "
             "from a description plus Hermes rows, not that it can read a "
             "figure.\n\n"
             "Where an automaton does not reach the number the student actually "
             "wrote, the grounding block says so in rust. Round 1 had no such "
             "check, and one item (M4) was grounded on an automaton that "
             "contradicted its own figure. M4 and M4B are the same scan: M4 with "
             "the pipeline's description, M4B with the task stem restored by "
             "hand. M4B is the only hand-written description in the set.",
             size=9.5, color=INK)

    # ---- one page per item, cut to its content ----------------------------
    for iid in order:
        item = items[iid]
        res = results.get(iid)

        scan = item["png_disk_path"]
        drawn = None
        note = "Not yet run."
        if res and res.get("svg_path") and (run_dir / res["svg_path"]).exists():
            svg_txt = (run_dir / res["svg_path"]).read_text()
            cand = tmpdir / f"{iid}.png"
            ok, detail = rasterise_to_png(svg_txt, cand, dpi=args.dpi)
            if ok:
                drawn = cand
            else:
                note = f"the SVG would not rasterise:\n{detail}"
        elif res:
            note = ("No scene survived the gates.\n"
                    + (res.get("schema_error") or res.get("error")
                       or "see the raw reply"))
        wl, wr, ph = pane_geometry(scan, drawn)

        d = item["description"]
        extras = []
        if d.get("transcribed_math"):
            extras.append("transcribed:  " + d["transcribed_math"].replace("\n", "  /  "))
        if d.get("error_topics"):
            extras.append("error topics:  " + "; ".join(d["error_topics"]))
        tags = [item["grade_bucket"]] + list(item["domains"])
        if item.get("representation_language") not in (None, "none"):
            tags.append(item["representation_language"])
        tags += list(item["spatial_elements"])
        extras.append("tags:  " + " / ".join(str(t) for t in tags if t))
        extras_txt = "\n".join(extras)

        glines = grounding_lines(item)
        gap = item.get("known_gap_not_given_to_the_model")

        # Measure first, then make a page exactly that tall.
        h = M + 20 + 14
        h += 12 + ph + 16
        h += 12 + flow_h(item["selected_because"], COL, size=9.5) + 8
        h += 12 + flow_h(d.get("student_strategy") or "(not recorded)", COL,
                         size=10) + 4
        h += flow_h(item.get("description_provenance", ""), COL, size=8,
                    font=MONO) + 6
        h += flow_h(extras_txt, COL, size=8, font=MONO) + 10
        if gap:
            h += 12 + flow_h(gap, COL - 16, size=8.6) + 14
        h += 12 + len(glines) * 7.2 * 1.30 + 12
        h += 14 + 50 + M
        page = doc.new_page(width=PW, height=max(h, 420))
        page.draw_rect(fitz.Rect(0, 0, PW, max(h, 420)), color=None, fill=PAPER)

        y = M
        band_col = BAND.get(item["band"], MUTED)
        page.insert_text((M, y + 12), iid, fontsize=15, fontname=BOLD, color=INK)
        page.insert_text((M + 52, y + 11), item["band"].upper(), fontsize=8,
                         fontname=MONO, color=band_col)
        cite = (f"{item['citation'] or ''}  ·  p.{item['page_ref']}  ·  "
                f"{item['grade_bucket']}")
        cl = wrap(cite, COL - 170, 8, SERIF)
        page.insert_text((M + 168, y + 11), cl[0], fontsize=8, fontname=SERIF,
                         color=MUTED)
        y += 20

        if res:
            failed = [k for k, c in res["checks"].items() if c["status"] == "fail"]
            unavail = [k for k, c in res["checks"].items()
                       if c["status"] == "renderer_unavailable"]
            g = ("gates: VALID" if res["valid"]
                 else "gates: INVALID (" + ", ".join(failed) + ")")
            if unavail:
                g += "  ·  " + "/".join(unavail) + " could not run"
            g += f"  ·  {res['seconds']}s  ·  {res.get('attempts', 1)} attempt(s)"
            shape = res["checks"].get("shape", {}).get("detail")
            if shape:
                g += f"  ·  {shape}"
            gcol = GREEN if res["valid"] else RUST
        else:
            g, gcol = "not run", MUTED
        page.insert_text((M, y + 9), g[:150], fontsize=8, fontname=MONO,
                         color=gcol)
        y += 14 + 12

        draw_pane(page, M, y, wl, ph, "the scan", scan, "PNG not found on disk")
        draw_pane(page, M + wl + 16, y, wr, ph, "what the model's scene typesets to",
                  drawn, note)
        y += ph + 16

        y = kicker(page, M, y, "chosen because")
        y = flow(page, M, y, COL, item["selected_because"], size=9.5) + 8

        y = kicker(page, M, y, "the description the model was given")
        y = flow(page, M, y, COL, d.get("student_strategy") or "(not recorded)",
                 size=10) + 4
        y = flow(page, M, y, COL, item.get("description_provenance", ""),
                 size=8, font=MONO, color=MUTED) + 6
        y = flow(page, M, y, COL, extras_txt, size=8, font=MONO, color=MUTED) + 10

        if gap:
            gh = flow_h(gap, COL - 16, size=8.6) + 20
            page.draw_rect(fitz.Rect(M, y, PW - M, y + gh), color=GOLD,
                           width=0.8, fill=(0.988, 0.965, 0.898))
            page.insert_text((M + 8, y + 12), "NOT GIVEN TO THE MODEL",
                             fontsize=7.2, fontname=MONO, color=GOLD)
            flow(page, M + 8, y + 14, COL - 16, gap, size=8.6, color=INK)
            y += gh + 14

        y = kicker(page, M, y, "the hermes rows the model was given")
        gy = y
        gh = len(glines) * 7.2 * 1.30 + 10
        page.draw_rect(fitz.Rect(M, gy, PW - M, gy + gh), color=LINE, width=0.6)
        ty = gy + 4
        for txt, col in glines:
            ty += 7.2 * 1.30
            if txt:
                page.insert_text((M + 6, ty), txt, fontsize=7.2, fontname=MONO,
                                 color=col)
        y = gy + gh + 14

        page.draw_rect(fitz.Rect(M, y, PW - M, y + 50), color=LINE, width=0.7,
                       fill=(0.988, 0.980, 0.965))
        page.insert_text((M + 10, y + 18), "ESSENCE CAUGHT?", fontsize=8,
                         fontname=MONO, color=MUTED)
        bx = M + 150
        for lbl, col in (("yup", GREEN), ("partly", GOLD), ("nope", RUST)):
            page.draw_rect(fitz.Rect(bx, y + 8, bx + 13, y + 21), color=col,
                           width=1.0)
            page.insert_text((bx + 19, y + 19), lbl, fontsize=9, fontname=SERIF,
                             color=col)
            bx += 92
        page.insert_text((M + 10, y + 40), "note:  " + "_" * 108, fontsize=8,
                         fontname=SERIF, color=MUTED)

    doc.set_metadata({
        "title": "Hermes scene-from-description pilot — side by side",
        "subject": "Internal review document. Validity gates only; "
                   "whether the essence was caught is the reader's call.",
        "creator": "t228v2 build_compare_pdf.py",
    })
    doc.save(str(out_pdf), garbage=4, deflate=True)
    heights = [round(p.rect.height) for p in doc]
    doc.close()
    tmp.cleanup()
    print(f"wrote {out_pdf}  ({out_pdf.stat().st_size:,} bytes, "
          f"{len(order)} items + cover, rasteriser {ras_label})")
    print(f"  page heights: {heights}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
