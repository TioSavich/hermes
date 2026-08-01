#!/usr/bin/env python3
"""The review page: one self-contained HTML file, no fetch of any kind.

The scene SVGs are written into the document as SVG elements, not referenced;
the scans are base64 data URIs. Nothing is loaded at view time, from anywhere,
so opening the file over file:// has no request to be refused and the CORS
surface is not narrowed but absent.

It is written into the run directory under the scratch tree, which sits outside
the repository altogether and cannot be committed. If it is ever promoted it
belongs under the gitignored hermes/app/runtime/experiments/ subtree, never a
tracked path.

Marks are per item -- yup / partly / nope plus a note -- and are kept in the
browser's localStorage against the run label, so closing the tab does not lose
them. The button at the foot gathers them into JSON to paste back.

    python3 build_compare_html.py --run out/smoke-local
"""
from __future__ import annotations

import argparse
import base64
import json
import re
from pathlib import Path

CSS = """
:root{
  --paper:#f4ead6; --paper-2:#ede4cf; --ink:#0d0c08; --label:#1b1810;
  --muted:#8a6f4c; --rule:#cabf9f; --rust:#b95238; --blue:#4c6b8a;
  --green:#6e8b5d; --gold:#a97c24;
}
*{box-sizing:border-box}
body{margin:0;background:var(--paper);color:var(--ink);
  font:15px/1.55 -apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif}
main{max-width:1180px;margin:0 auto;padding:32px 24px 80px}
h1{font-size:27px;line-height:1.2;margin:0 0 6px}
h2{font-size:19px;margin:0}
p{margin:0 0 12px}
code,pre{font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace}
.lede{max-width:70ch}
.lede p{margin-bottom:14px}
.facts{font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;
  font-size:12.5px;color:var(--muted);background:var(--paper-2);
  border:1px solid var(--rule);border-radius:5px;padding:14px 16px;margin:18px 0}
.facts b{color:var(--ink);font-weight:600}
.item{border:1px solid var(--rule);border-radius:7px;background:var(--paper-2);
  margin:30px 0;padding:20px 22px;overflow:hidden}
.head{display:flex;align-items:baseline;gap:12px;flex-wrap:wrap;
  border-bottom:1px solid var(--rule);padding-bottom:10px;margin-bottom:14px}
.id{font-size:22px;font-weight:700}
.band{font-family:ui-monospace,monospace;font-size:11px;letter-spacing:.09em;
  text-transform:uppercase;padding:2px 8px;border-radius:3px;
  border:1px solid currentColor}
.band.misconception{color:var(--rust)} .band.strategy{color:var(--green)}
.band.notation{color:var(--gold)} .band.thin{color:var(--muted)}
.cite{color:var(--muted);font-size:12.5px;flex:1 1 260px}
.gate{font-family:ui-monospace,monospace;font-size:12px;margin-bottom:14px}
.gate.ok{color:var(--green)} .gate.bad{color:var(--rust)}
.gate.none{color:var(--muted)}
.pair{display:grid;grid-template-columns:1fr 1fr;gap:16px;align-items:stretch}
@media(max-width:820px){.pair{grid-template-columns:1fr}}
.pane{border:1px solid var(--rule);border-radius:5px;background:#fff;
  padding:10px;display:flex;flex-direction:column;min-width:0}
.pane h3{font-family:ui-monospace,monospace;font-size:10.5px;
  letter-spacing:.08em;text-transform:uppercase;color:var(--muted);
  margin:0 0 8px;font-weight:400}
.figure{flex:1;display:flex;align-items:center;justify-content:center;
  overflow-x:auto;min-height:0}
.figure img{max-width:100%;height:auto;display:block}
.figure svg{max-width:100%;height:auto;display:block}
.missing{color:var(--muted);font-size:13px;text-align:center;padding:34px 8px;
  white-space:pre-wrap}
.kicker{font-family:ui-monospace,monospace;font-size:10.5px;
  letter-spacing:.08em;text-transform:uppercase;color:var(--muted);
  margin:20px 0 5px}
.desc{max-width:78ch}
.prov{font-family:ui-monospace,monospace;font-size:11.5px;color:var(--muted);
  margin-top:5px}
.tags{font-family:ui-monospace,monospace;font-size:11.5px;color:var(--muted);
  margin-top:7px;white-space:pre-wrap;word-break:break-word}
.gap{border:1px solid var(--gold);background:#fdf6e4;border-radius:5px;
  padding:12px 14px;margin:16px 0}
.gap .kicker{color:var(--gold);margin:0 0 5px}
pre.rows{font-size:11.5px;line-height:1.48;background:#fff;
  border:1px solid var(--rule);border-radius:5px;padding:12px 14px;
  overflow-x:auto;margin:0;white-space:pre}
pre.rows .warn{color:var(--rust)} pre.rows .dim{color:var(--muted)}
.verdict{margin-top:18px;border-top:1px solid var(--rule);padding-top:14px;
  display:flex;align-items:center;gap:18px;flex-wrap:wrap}
.verdict .q{font-family:ui-monospace,monospace;font-size:11px;
  letter-spacing:.08em;text-transform:uppercase;color:var(--muted)}
.verdict label{display:inline-flex;align-items:center;gap:6px;cursor:pointer;
  font-size:14px}
.verdict input[type=radio]{accent-color:var(--blue);width:15px;height:15px}
.verdict .note{flex:1 1 320px}
.verdict .note input{width:100%;font:14px inherit;padding:6px 9px;
  border:1px solid var(--rule);border-radius:4px;background:#fff;color:var(--ink)}
.foot{margin-top:40px;border-top:1px solid var(--rule);padding-top:18px}
button{font:14px inherit;padding:8px 15px;border:1px solid var(--rule);
  border-radius:4px;background:var(--paper-2);color:var(--ink);cursor:pointer}
button:hover{background:#fff}
#dump{width:100%;min-height:130px;margin-top:12px;font-family:ui-monospace,
  monospace;font-size:12px;padding:10px;border:1px solid var(--rule);
  border-radius:4px;background:#fff;color:var(--ink);display:none}
"""

JS = """
(function(){
  var KEY='t228v2-marks:'+RUN;
  var marks={};
  try{marks=JSON.parse(localStorage.getItem(KEY)||'{}')}catch(e){marks={}}
  function save(){try{localStorage.setItem(KEY,JSON.stringify(marks))}catch(e){}}
  document.querySelectorAll('.item').forEach(function(el){
    var id=el.dataset.item, m=marks[id]||{};
    el.querySelectorAll('input[type=radio]').forEach(function(r){
      if(m.verdict===r.value) r.checked=true;
      r.addEventListener('change',function(){
        marks[id]=marks[id]||{}; marks[id].verdict=r.value; save();
      });
    });
    var n=el.querySelector('input[type=text]');
    if(n){ n.value=m.note||'';
      n.addEventListener('input',function(){
        marks[id]=marks[id]||{}; marks[id].note=n.value; save();
      });
    }
  });
  var btn=document.getElementById('gather'), out=document.getElementById('dump');
  btn.addEventListener('click',function(){
    out.style.display='block';
    out.value=JSON.stringify({run:RUN,marks:marks},null,2);
    out.select();
  });
})();
"""


def esc(s) -> str:
    return (str(s if s is not None else "").replace("&", "&amp;")
            .replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;"))


def data_uri(path) -> str | None:
    p = Path(path)
    if not p.exists():
        return None
    ext = p.suffix.lower().lstrip(".")
    mime = {"png": "image/png", "jpg": "image/jpeg", "jpeg": "image/jpeg",
            "gif": "image/gif", "webp": "image/webp"}.get(ext, "image/png")
    return f"data:{mime};base64," + base64.b64encode(p.read_bytes()).decode()


def inline_svg(svg: str) -> str:
    """Drop any XML prolog and let the element scale inside its pane."""
    svg = re.sub(r"<\?xml[^>]*\?>", "", svg).strip()
    return re.sub(r"<svg ", '<svg style="max-width:100%;height:auto" ', svg, count=1)


def rows_html(item: dict) -> str:
    if not item["grounding"]:
        return ('<span class="dim">No Hermes rows were retrieved for this '
                'figure. The model was given the description alone.</span>')
    out: list[str] = []
    for g in item["grounding"]:
        out.append(esc(f"[{g['op']}] {json.dumps(g['arguments'])}"))
        if g.get("input_provenance"):
            out.append(f'<span class="dim">  input: '
                       f'{esc(g["input_provenance"])}</span>')
        r = g["result"]
        if not r.get("ok", True) and r.get("refusal"):
            out.append(f'<span class="warn">  REFUSED: {esc(r["refusal"])}</span>')
            if r.get("diagnosis"):
                out.append(f'<span class="warn">  why: {esc(r["diagnosis"])}</span>')
        elif "steps" in r:
            out.append(esc(f"  automaton {r.get('strategy')}  ->  {r.get('result')}"))
            for s in r["steps"]:
                t = f"    {s['n']}. {s['label']}"
                if s.get("value"):
                    t += f"  ->  {s['value']}"
                out.append(esc(t))
        elif "rows" in r:
            if not r["rows"]:
                out.append(f'<span class="dim">  no rows matched '
                           f'(count {r.get("count", 0)})</span>')
            for row in r["rows"]:
                out.append(esc(f"  - {row['name']} [{row.get('domain', '?')}] "
                               f"{row.get('db_row', '')}"))
                out.append(f'<span class="dim">      '
                           f'{esc(row.get("citation", ""))}</span>')
        if g.get("reproduces_figure") is False:
            out.append(f'<span class="warn">  ! this automaton does not reach '
                       f'the figure\'s own answer '
                       f'({esc(g.get("figure_answer"))})</span>')
        if g.get("_note"):
            out.append(f'<span class="dim">  note: {esc(g["_note"])}</span>')
        out.append("")
    return "\n".join(out)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--items", default="items/items.jsonl")
    ap.add_argument("--run", required=True)
    ap.add_argument("--output", default="")
    args = ap.parse_args()

    here = Path(__file__).resolve().parent
    items = {}
    for line in (here / args.items).read_text().splitlines():
        if line.strip():
            r = json.loads(line)
            items[r["item_id"]] = r
    run_dir = Path(args.run) if Path(args.run).is_absolute() else here / args.run
    out_html = Path(args.output) if args.output else run_dir / "compare.html"

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

    order = [i for i in items if i in results] or list(items)
    counts: dict[str, int] = {}
    for iid in order:
        counts[items[iid]["band"]] = counts.get(items[iid]["band"], 0) + 1
    valid_n = sum(1 for i in order if results.get(i, {}).get("valid"))
    secs = [results[i]["seconds"] for i in order if i in results]

    parts: list[str] = []
    parts.append(f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Hermes scene pilot — {esc(meta.get('run_label', 'run'))}</title>
<style>{CSS}</style></head><body><main>""")

    parts.append("""
<h1>Can the model redraw the mathematics it cannot see?</h1>
<p style="color:var(--rust);font-weight:600;font-size:16px;margin-top:2px">
Round 2. The model no longer draws.</p>
<div class="lede">
<p>Round 1 asked gemma-4-E2B-it for SVG. It named the right mathematics and then
destroyed it with coordinates: labels printed over each other, a filled
rectangle drawn across its own caption, text past the edge of the canvas. The
content was mostly sound and unreadable.</p>
<p>So the job is split. The model writes a <em>scene</em> &mdash; what the panels
are, which digit carries a strike or a carry, what the note says &mdash; in a
small vocabulary with no way to express a coordinate. A deterministic typesetter
turns that into the figure on the right, measuring every column and sizing the
canvas to the content after the content exists. Overlap and overflow are not
failure modes this pipeline has.</p>
<p>Left on each item is the figure as it was scanned out of a research article.
Right is what the model's scene typesets to, having never seen the image. The
question is not whether the two look alike. It is whether the drawing carries
the error, the strategy, or the notational claim the scan documents.</p>
<p>The gate line reports <b>validity only</b>: the reply held JSON, the JSON
obeyed the vocabulary, the typesetter drew it, and the drawing has ink on it. No
machine here judges whether the essence was caught. That is yours &mdash; mark
each item at its foot, and the marks keep themselves in this browser.</p>
</div>""")

    parts.append('<div class="facts">'
                 + "<br>".join([
                     f"items in this document &nbsp; <b>{len(order)}</b> &nbsp; ("
                     + ", ".join(f"{k} {v}" for k, v in sorted(counts.items())) + ")",
                     f"passed the validity gates &nbsp; <b>{valid_n} / {len(order)}</b>",
                     f"model &nbsp; <b>{esc(meta.get('model', '?'))}</b>",
                     f"endpoint &nbsp; {esc(meta.get('base_url', '?'))}",
                     f"temperature &nbsp; {esc(meta.get('temperature', '?'))}"
                     f" &nbsp;&nbsp; attempts per item &nbsp; "
                     f"{esc(meta.get('attempts', '?'))}",
                     f"run label &nbsp; {esc(meta.get('run_label', '?'))}",
                     (f"generation time &nbsp; {min(secs):.1f}–{max(secs):.1f} s "
                      f"per item" if secs else "generation time &nbsp; n/a"),
                 ]) + "</div>")

    parts.append("""
<div class="lede">
<p><b>Two things this page cannot show you.</b> The figure descriptions were
produced by an earlier LLM pass whose generating script is not in the
repository: no model, prompt, or timestamp was recorded. A success here shows
the model can redraw from a description plus Hermes rows, not that it can read a
figure.</p>
<p>Where an automaton does not reach the number the student actually wrote, the
grounding block says so in rust. Round 1 had no such check, and one item was
grounded on an automaton that contradicted its own figure. <b>M4</b> and
<b>M4B</b> are the same scan: M4 with the pipeline's description, M4B with the
task stem restored by hand. M4B is the only hand-written description in the
set.</p>
</div>""")

    for iid in order:
        item = items[iid]
        res = results.get(iid)
        d = item["description"]

        svg_txt = None
        missing = "Not yet run."
        if res and res.get("svg_path") and (run_dir / res["svg_path"]).exists():
            svg_txt = (run_dir / res["svg_path"]).read_text()
        elif res:
            missing = ("No scene survived the gates.\n"
                       + (res.get("schema_error") or res.get("error")
                          or "see the raw reply"))
        scan_uri = data_uri(item["png_disk_path"])

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
            gcls = "ok" if res["valid"] else "bad"
        else:
            g, gcls = "not run", "none"

        extras = []
        if d.get("transcribed_math"):
            extras.append("transcribed:  " + d["transcribed_math"])
        if d.get("error_topics"):
            extras.append("error topics:  " + "; ".join(d["error_topics"]))
        tags = [item["grade_bucket"]] + list(item["domains"])
        if item.get("representation_language") not in (None, "none"):
            tags.append(item["representation_language"])
        tags += list(item["spatial_elements"])
        extras.append("tags:  " + " / ".join(str(t) for t in tags if t))

        gap = item.get("known_gap_not_given_to_the_model")
        parts.append(f"""
<section class="item" data-item="{esc(iid)}">
  <div class="head">
    <span class="id">{esc(iid)}</span>
    <span class="band {esc(item['band'])}">{esc(item['band'])}</span>
    <span class="cite">{esc(item['citation'])} &middot; p.{esc(item['page_ref'])}
      &middot; {esc(item['grade_bucket'])}</span>
  </div>
  <div class="gate {gcls}">{esc(g)}</div>
  <div class="pair">
    <div class="pane"><h3>the scan</h3><div class="figure">"""
                     + (f'<img alt="scan of {esc(iid)}" src="{scan_uri}">'
                        if scan_uri else
                        '<div class="missing">PNG not found on disk</div>')
                     + """</div></div>
    <div class="pane"><h3>what the model&rsquo;s scene typesets to</h3>
      <div class="figure">"""
                     + (inline_svg(svg_txt) if svg_txt else
                        f'<div class="missing">{esc(missing)}</div>')
                     + f"""</div></div>
  </div>
  <div class="kicker">chosen because</div>
  <div class="desc">{esc(item['selected_because'])}</div>
  <div class="kicker">the description the model was given</div>
  <div class="desc">{esc(d.get('student_strategy') or '(not recorded)')}</div>
  <div class="prov">{esc(item.get('description_provenance', ''))}</div>
  <div class="tags">{esc(chr(10).join(extras))}</div>"""
                     + (f"""
  <div class="gap"><div class="kicker">not given to the model</div>
    {esc(gap)}</div>""" if gap else "")
                     + f"""
  <div class="kicker">the hermes rows the model was given</div>
  <pre class="rows">{rows_html(item)}</pre>
  <div class="verdict">
    <span class="q">essence caught?</span>"""
                     + "".join(
                         f'<label><input type="radio" name="v-{esc(iid)}" '
                         f'value="{v}">{v}</label>'
                         for v in ("yup", "partly", "nope"))
                     + """
    <span class="note"><input type="text" placeholder="note"></span>
  </div>
</section>""")

    parts.append(f"""
<div class="foot">
  <button id="gather">Gather the marks as JSON</button>
  <textarea id="dump" readonly></textarea>
  <p style="color:var(--muted);font-size:12.5px;margin-top:14px">
  Self-contained: every figure is embedded in this file, nothing is fetched at
  view time. Written under the scratch tree, which sits outside the repository
  and cannot be committed.</p>
</div>
</main>
<script>var RUN={json.dumps(meta.get('run_label', 'run'))};{JS}</script>
</body></html>""")

    html = "\n".join(parts)
    out_html.write_text(html)
    n_svg = sum(1 for i in order
                if results.get(i, {}).get("svg_path")
                and (run_dir / results[i]["svg_path"]).exists())
    print(f"wrote {out_html}  ({len(html):,} bytes, {len(order)} items, "
          f"{n_svg} inlined scenes)")

    # Self-containment is the claim, so check the things that actually load
    # something. An `http://` substring is not one of them: the SVG namespace is
    # an identifier the browser never dereferences, and the endpoint is printed
    # as text. Look for loading constructs instead.
    loaders = {
        "<script src": "external script",
        "<link ": "stylesheet or preload link",
        "<iframe": "embedded frame",
        "fetch(": "runtime fetch",
        "XMLHttpRequest": "runtime request",
        "@import": "CSS import",
        "url(": "CSS url reference",
    }
    found = [why for tok, why in loaders.items() if tok in html]
    for tag in re.findall(r'<img[^>]*src="([^"]{0,12})', html):
        if not tag.startswith("data:"):
            found.append("an <img> that is not a data URI")
    if found:
        for why in sorted(set(found)):
            print(f"  WARNING: {why} present; the page is not self-contained")
    else:
        print("  self-contained: nothing is loaded at view time. The only "
              "absolute URLs are the SVG namespace, which is an identifier "
              "rather than a request, and the endpoint printed as text.")
    print("  written under the scratch tree, outside the repository")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
