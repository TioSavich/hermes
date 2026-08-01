#!/usr/bin/env python3
"""The three-way review PDF: scan, Gemma's drawing, codex's drawing, one row.

A sibling of build_compare_pdf.py that imports its layout machinery -- the
metric wrapping, the flowed text, the grounding renderer, the pane drawing --
and adds the third pane plus the two blocks only the codex arm produced: its
verbatim note on where the grounding was the limit, and the extra Hermes MCP
calls it logged. Pages are measured first and cut to their content, as before.

    python3 build_compare3_pdf.py --output out/comparison-3way/compare3.pdf
"""
from __future__ import annotations

import argparse
import json
import tempfile
from pathlib import Path

import fitz

from build_compare_pdf import (BAND, BOLD, COL, GOLD, GREEN, INK, LINE, M,
                               MAX_PANE_H, MIN_PANE_H, MONO, MUTED, PAPER, PW,
                               RUST, SERIF, draw_pane, flow, flow_h,
                               grounding_lines, kicker, wrap)
from build_compare3_html import load_results, parse_codex_report
from gate_svg import find_rasteriser, rasterise_to_png


def pane_geometry3(*paths) -> tuple[list[float], float]:
    """One height for all three panes; each width follows its aspect ratio."""
    def ar(p):
        if not p or not Path(p).exists():
            return 1.4
        try:
            px = fitz.Pixmap(str(p))
            return max(px.width / px.height, 0.15)
        except Exception:
            return 1.4
    ratios = [ar(p) for p in paths]
    gap = 14.0
    total_gap = gap * (len(ratios) - 1)
    h = (COL - total_gap) / sum(ratios)
    h = max(MIN_PANE_H, min(MAX_PANE_H, h))
    ws = [h * a for a in ratios]
    if sum(ws) + total_gap > COL:
        k = (COL - total_gap) / sum(ws)
        ws = [w * k for w in ws]
        h *= k
    return ws, h


def gate_text(res: dict | None, label: str) -> tuple[str, tuple]:
    if not res:
        return f"{label}:  not run", MUTED
    failed = [k for k, c in res["checks"].items() if c["status"] == "fail"]
    g = ("gates: VALID" if res["valid"]
         else "gates: INVALID (" + ", ".join(failed) + ")")
    g += ("  ·  " + (f"{res['seconds']}s" if res.get("seconds") is not None
                     else "timing not recorded"))
    a = res.get("attempts")
    g += f"  ·  {a} attempt(s)" if a is not None else "  ·  attempts unrecorded"
    shape = res["checks"].get("shape", {}).get("detail")
    if shape:
        g += f"  ·  {shape}"
    return (f"{label}:  {g}", GREEN if res["valid"] else RUST)


def rasterised(res: dict | None, run_dir: Path, tmpdir: Path, iid: str,
               tag: str, dpi: int) -> tuple[Path | None, str]:
    note = "Not yet run."
    if res and res.get("svg_path") and (run_dir / res["svg_path"]).exists():
        svg_txt = (run_dir / res["svg_path"]).read_text()
        cand = tmpdir / f"{iid}-{tag}.png"
        ok, detail = rasterise_to_png(svg_txt, cand, dpi=dpi)
        if ok:
            return cand, ""
        note = f"the SVG would not rasterise:\n{detail}"
    elif res:
        note = ("No scene survived the gates.\n"
                + (res.get("schema_error") or res.get("error")
                   or "see the raw reply"))
    return None, note


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--items", default="items/items.jsonl")
    ap.add_argument("--gemma-run", default="out/bigred-7859280")
    ap.add_argument("--codex-run", default="out/codex-arm")
    ap.add_argument("--output", default="out/comparison-3way/compare3.pdf")
    ap.add_argument("--dpi", type=int, default=150)
    args = ap.parse_args()

    here = Path(__file__).resolve().parent
    items = {}
    for line in (here / args.items).read_text().splitlines():
        if line.strip():
            r = json.loads(line)
            items[r["item_id"]] = r
    g_dir = here / args.gemma_run
    c_dir = here / args.codex_run
    g_res = load_results(g_dir)
    c_res = load_results(c_dir)
    g_meta = {}
    if (g_dir / "run_meta.json").exists():
        g_meta = json.loads((g_dir / "run_meta.json").read_text())
    _, limits = parse_codex_report(c_dir / "report.md")
    mcp = {p.stem: p.read_text().strip()
           for p in sorted((c_dir / "mcp_log").glob("*.txt"))}

    out_pdf = Path(args.output) if Path(args.output).is_absolute() \
        else here / args.output
    out_pdf.parent.mkdir(parents=True, exist_ok=True)

    _, ras_label = find_rasteriser()
    order = list(items)
    doc = fitz.open()
    tmp = tempfile.TemporaryDirectory()
    tmpdir = Path(tmp.name)

    # ---- cover ------------------------------------------------------------
    g_valid = sum(1 for i in order if g_res.get(i, {}).get("valid"))
    c_valid = sum(1 for i in order if c_res.get(i, {}).get("valid"))
    g_secs = [g_res[i]["seconds"] for i in order
              if i in g_res and g_res[i].get("seconds") is not None]
    g_tries: dict[int, int] = {}
    for i in order:
        a = g_res.get(i, {}).get("attempts")
        if a is not None:
            g_tries[a] = g_tries.get(a, 0) + 1
    counts: dict[str, int] = {}
    for iid in order:
        counts[items[iid]["band"]] = counts.get(items[iid]["band"], 0) + 1

    cover = doc.new_page(width=PW, height=980)
    cover.draw_rect(fitz.Rect(0, 0, PW, 980), color=None, fill=PAPER)
    y = M
    y = flow(cover, M, y, COL,
             "Two models, one grounding: the scan, then each arm's redrawing",
             size=19, font=BOLD) + 10
    y = flow(cover, M, y, COL,
             "Both arms received the identical 16 prompts: the figure's "
             "written description, the same Hermes rows, the same "
             "coordinate-free scene vocabulary. Each wrote scene JSON; the "
             "same deterministic typesetter drew both arms' scenes, and the "
             "same four gates judged them (json_parses, schema_validates, "
             "typesets, renders_non_empty). Neither model was given the "
             "image.\n\n"
             "The arms differ in model scale, reasoning budget, and live MCP "
             "access -- deliberately. Where the larger model succeeds on the "
             "same rows, the fault was the small model; where the larger "
             "model itself names the rows as the limit -- quoted verbatim "
             "under each item -- that is the grounding's ceiling.",
             size=10.5) + 16
    tries_txt = ", ".join(
        (f"{n} try x{g_tries[n]}" if n == 1 else f"{n} tries x{g_tries[n]}")
        for n in sorted(g_tries))
    facts = [
        f"items in this document   {len(order)}"
        f"   ({', '.join(f'{k} {v}' for k, v in sorted(counts.items()))})",
        "",
        f"gemma-4-E2B-it (cluster, temperature {g_meta.get('temperature', '?')})",
        f"  passed the gates   {g_valid} / {len(order)}",
        f"  tries   {tries_txt}",
        (f"  generation   {min(g_secs):.1f}-{max(g_secs):.1f} s per item "
         f"(mean {sum(g_secs) / len(g_secs):.1f})" if g_secs
         else "  generation   n/a"),
        "",
        "codex gpt-5.6 (local, live Hermes MCP)",
        f"  passed the gates   {c_valid} / {len(order)}   as re-gated here by "
        "the same chain; its report claims 16/16 and the two agree",
        "  tries   1 try x16 (self-reported in its report; not independently "
        "logged)",
        "  generation   per-item timing was not recorded by the codex driver",
        f"  items with extra Hermes MCP calls logged   {len(mcp)} / {len(order)}"
        f"   ({', '.join(sorted(mcp))})",
        "",
        f"rasteriser   {ras_label}",
    ]
    y = flow(cover, M, y, COL, "\n".join(facts), size=9, font=MONO,
             color=MUTED) + 14
    y = flow(cover, M, y, COL,
             "What this document cannot show you.\n\n"
             "The figure descriptions were produced by an earlier LLM pass "
             "whose generating script is not in the repository; a success "
             "here shows a model can redraw from a description plus Hermes "
             "rows, not that it can read a figure. The codex arm validated "
             "its own drafts against the same gate machinery while writing "
             "them, so its 16/16 is a self-check the re-gate confirmed, not "
             "an independent result of restraint.", size=9.5, color=INK)
    cover.set_cropbox(fitz.Rect(0, 0, PW, min(980, y + M)))

    # ---- one page per item ------------------------------------------------
    for iid in order:
        item = items[iid]
        gr = g_res.get(iid)
        cr = c_res.get(iid)

        scan = item["png_disk_path"]
        g_png, g_note = rasterised(gr, g_dir, tmpdir, iid, "g", args.dpi)
        c_png, c_note = rasterised(cr, c_dir, tmpdir, iid, "c", args.dpi)
        ws, ph = pane_geometry3(scan, g_png, c_png)

        d = item["description"]
        extras = []
        if d.get("transcribed_math"):
            extras.append("transcribed:  "
                          + d["transcribed_math"].replace("\n", "  /  "))
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
        limit = limits.get(iid)
        mcp_txt = mcp.get(iid)
        mcp_lines: list[str] = []
        if mcp_txt:
            for para in mcp_txt.split("\n"):
                mcp_lines.extend(wrap(para, COL - 16, 7.2, MONO) or [""])

        # Measure first, then make a page exactly that tall.
        h = M + 20 + 2 * 14 + 12
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
        if limit:
            h += 12 + flow_h(limit, COL - 16, size=8.6) + 20 + 14
        if mcp_lines:
            h += 12 + len(mcp_lines) * 7.2 * 1.30 + 10 + 14
        h += 14 + 78 + M
        page = doc.new_page(width=PW, height=max(h, 460))
        page.draw_rect(fitz.Rect(0, 0, PW, max(h, 460)), color=None,
                       fill=PAPER)

        y = M
        band_col = BAND.get(item["band"], MUTED)
        page.insert_text((M, y + 12), iid, fontsize=15, fontname=BOLD,
                         color=INK)
        page.insert_text((M + 52, y + 11), item["band"].upper(), fontsize=8,
                         fontname=MONO, color=band_col)
        cite = (f"{item['citation'] or ''}  ·  p.{item['page_ref']}  ·  "
                f"{item['grade_bucket']}")
        cl = wrap(cite, COL - 170, 8, SERIF)
        page.insert_text((M + 168, y + 11), cl[0], fontsize=8, fontname=SERIF,
                         color=MUTED)
        y += 20

        for res, label in ((gr, "gemma-4-E2B-it"), (cr, "codex gpt-5.6")):
            txt, col = gate_text(res, label)
            page.insert_text((M, y + 9), txt[:170], fontsize=8, fontname=MONO,
                             color=col)
            y += 14
        y += 12

        x = M
        titles = ("the scan", "gemma-4-E2B-it typesets to",
                  "codex gpt-5.6 typesets to")
        imgs = (scan, g_png, c_png)
        notes = ("PNG not found on disk", g_note or "n/a", c_note or "n/a")
        for w, title, img, note in zip(ws, titles, imgs, notes):
            draw_pane(page, x, y, w, ph, title, img, note)
            x += w + 14
        y += ph + 16

        y = kicker(page, M, y, "chosen because")
        y = flow(page, M, y, COL, item["selected_because"], size=9.5) + 8

        y = kicker(page, M, y, "the description both models were given")
        y = flow(page, M, y, COL, d.get("student_strategy") or "(not recorded)",
                 size=10) + 4
        y = flow(page, M, y, COL, item.get("description_provenance", ""),
                 size=8, font=MONO, color=MUTED) + 6
        y = flow(page, M, y, COL, extras_txt, size=8, font=MONO,
                 color=MUTED) + 10

        if gap:
            gh = flow_h(gap, COL - 16, size=8.6) + 20
            page.draw_rect(fitz.Rect(M, y, PW - M, y + gh), color=GOLD,
                           width=0.8, fill=(0.988, 0.965, 0.898))
            page.insert_text((M + 8, y + 12), "NOT GIVEN TO EITHER MODEL",
                             fontsize=7.2, fontname=MONO, color=GOLD)
            flow(page, M + 8, y + 14, COL - 16, gap, size=8.6, color=INK)
            y += gh + 14

        y = kicker(page, M, y, "the hermes rows both models were given")
        gy = y
        gh = len(glines) * 7.2 * 1.30 + 10
        page.draw_rect(fitz.Rect(M, gy, PW - M, gy + gh), color=LINE,
                       width=0.6)
        ty = gy + 4
        for txt, col in glines:
            ty += 7.2 * 1.30
            if txt:
                page.insert_text((M + 6, ty), txt, fontsize=7.2, fontname=MONO,
                                 color=col)
        y = gy + gh + 14

        if limit:
            lh = flow_h(limit, COL - 16, size=8.6) + 26
            page.draw_rect(fitz.Rect(M, y, PW - M, y + lh), color=GOLD,
                           width=0.8, fill=(0.988, 0.965, 0.898))
            page.insert_text((M + 8, y + 12),
                             "CODEX ON WHERE THE GROUNDING WAS THE LIMIT "
                             "(VERBATIM FROM ITS REPORT)",
                             fontsize=7.2, fontname=MONO, color=GOLD)
            flow(page, M + 8, y + 16, COL - 16, limit, size=8.6, color=INK)
            y += lh + 14

        if mcp_lines:
            y = kicker(page, M, y, "the extra hermes MCP calls codex logged")
            mh = len(mcp_lines) * 7.2 * 1.30 + 10
            page.draw_rect(fitz.Rect(M, y, PW - M, y + mh), color=LINE,
                           width=0.6)
            ty = y + 4
            for ln in mcp_lines:
                ty += 7.2 * 1.30
                if ln:
                    page.insert_text((M + 6, ty), ln, fontsize=7.2,
                                     fontname=MONO, color=INK)
            y += mh + 14

        page.draw_rect(fitz.Rect(M, y, PW - M, y + 78), color=LINE, width=0.7,
                       fill=(0.988, 0.980, 0.965))
        for row, arm in enumerate(("GEMMA", "CODEX")):
            ry = y + 8 + row * 24
            page.insert_text((M + 10, ry + 11),
                             f"ESSENCE CAUGHT, {arm}?", fontsize=8,
                             fontname=MONO, color=MUTED)
            bx = M + 190
            for lbl, col in (("yup", GREEN), ("partly", GOLD), ("nope", RUST)):
                page.draw_rect(fitz.Rect(bx, ry, bx + 13, ry + 13), color=col,
                               width=1.0)
                page.insert_text((bx + 19, ry + 11), lbl, fontsize=9,
                                 fontname=SERIF, color=col)
                bx += 92
        page.insert_text((M + 10, y + 68), "note:  " + "_" * 108, fontsize=8,
                         fontname=SERIF, color=MUTED)

    doc.set_metadata({
        "title": "Hermes scene pilot — scan, Gemma, codex, side by side by side",
        "subject": "Internal review document. Validity gates only; whether "
                   "either drawing caught the essence is the reader's call.",
        "creator": "t228v2 build_compare3_pdf.py",
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
