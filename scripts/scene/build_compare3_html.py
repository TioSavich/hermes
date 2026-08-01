#!/usr/bin/env python3
"""The three-way review page: scan, Gemma's drawing, codex's drawing, side by
side by side, with the codex arm's own account of where the grounding ran out.

A sibling of build_compare_html.py, not a fork: the escaping, the data URIs,
the SVG inlining, and the grounding-row renderer are imported from it, so the
two-arm page keeps working against its run directories unchanged.

Both arms were adjudicated by the same gate chain (gate_scene.py via
regate_scenes.py); nothing here re-judges anything. The page adds what only
the codex arm produced: its per-item note on where the embedded rows were the
limit (verbatim from its report) and the extra Hermes MCP calls it logged.

    python3 build_compare3_html.py \
        --gemma-run out/bigred-7859280 --codex-run out/codex-arm \
        --output out/comparison-3way/compare3.html
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

import build_compare_html as two

EXTRA_CSS = """
.triple{display:grid;grid-template-columns:1fr 1fr 1fr;gap:14px;align-items:stretch}
@media(max-width:980px){.triple{grid-template-columns:1fr}}
.armgate{font-family:ui-monospace,monospace;font-size:12px;margin-bottom:6px}
.armgate .arm{display:inline-block;min-width:130px;color:var(--muted)}
.armgate.ok .v{color:var(--green)} .armgate.bad .v{color:var(--rust)}
.selfsay{font-family:ui-monospace,monospace;font-size:11.5px;color:var(--muted);
  margin:2px 0 12px}
.limit{border:1px solid var(--gold);background:#fdf6e4;border-radius:5px;
  padding:12px 14px;margin:16px 0}
.limit .kicker{color:var(--gold);margin:0 0 5px}
.limit p{margin:0;font-size:13.5px}
pre.mcp{font-size:11.5px;line-height:1.48;background:#fff;
  border:1px solid var(--rule);border-radius:5px;padding:12px 14px;
  overflow-x:auto;margin:0;white-space:pre-wrap;word-break:break-word}
.verdict3{margin-top:18px;border-top:1px solid var(--rule);padding-top:14px}
.verdict3 .row{display:flex;align-items:center;gap:18px;flex-wrap:wrap;
  margin-bottom:8px}
.verdict3 .q{font-family:ui-monospace,monospace;font-size:11px;
  letter-spacing:.08em;text-transform:uppercase;color:var(--muted);
  min-width:170px}
.verdict3 label{display:inline-flex;align-items:center;gap:6px;cursor:pointer;
  font-size:14px}
.verdict3 input[type=radio]{accent-color:var(--blue);width:15px;height:15px}
.verdict3 .note{flex:1 1 320px}
.verdict3 .note input{width:100%;font:14px inherit;padding:6px 9px;
  border:1px solid var(--rule);border-radius:4px;background:#fff;color:var(--ink)}
"""

JS3 = """
(function(){
  var KEY='t228v2-marks3:'+RUN;
  var marks={};
  try{marks=JSON.parse(localStorage.getItem(KEY)||'{}')}catch(e){marks={}}
  function save(){try{localStorage.setItem(KEY,JSON.stringify(marks))}catch(e){}}
  document.querySelectorAll('.item').forEach(function(el){
    var id=el.dataset.item, m=marks[id]||{};
    el.querySelectorAll('input[type=radio]').forEach(function(r){
      var arm=r.dataset.arm;
      if(m[arm]===r.value) r.checked=true;
      r.addEventListener('change',function(){
        marks[id]=marks[id]||{}; marks[id][arm]=r.value; save();
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

esc = two.esc


def load_results(run_dir: Path) -> dict[str, dict]:
    out = {}
    p = run_dir / "results.jsonl"
    if p.exists():
        for line in p.read_text().splitlines():
            if line.strip():
                r = json.loads(line)
                out[r["item_id"]] = r
    return out


def parse_codex_report(path: Path) -> tuple[dict[str, str], dict[str, str]]:
    """Return (self_assessment_by_item, grounding_limit_by_item), verbatim."""
    if not path.exists():
        return {}, {}
    text = path.read_text()
    selfsay = {}
    for m in re.finditer(r"^(\w+): (valid=.*)$", text, re.M):
        selfsay[m.group(1)] = m.group(2).strip()
    limits = {}
    sect = text.split("## Where the grounding was the limit", 1)
    if len(sect) == 2:
        for m in re.finditer(r"^- (\w+): (.*)$", sect[1], re.M):
            limits[m.group(1)] = m.group(2).strip()
    return selfsay, limits


def gate_line(res: dict | None, arm_label: str) -> str:
    if not res:
        return (f'<div class="armgate none"><span class="arm">{esc(arm_label)}'
                f"</span> not run</div>")
    failed = [k for k, c in res["checks"].items() if c["status"] == "fail"]
    unavail = [k for k, c in res["checks"].items()
               if c["status"] == "renderer_unavailable"]
    v = ("gates: VALID" if res["valid"]
         else "gates: INVALID (" + ", ".join(failed) + ")")
    tail = []
    if unavail:
        tail.append("/".join(unavail) + " could not run")
    tail.append(f"{res['seconds']}s" if res.get("seconds") is not None
                else "timing not recorded")
    a = res.get("attempts")
    tail.append(f"{a} attempt(s)" if a is not None else "attempts unrecorded")
    shape = res["checks"].get("shape", {}).get("detail")
    if shape:
        tail.append(shape)
    cls = "ok" if res["valid"] else "bad"
    return (f'<div class="armgate {cls}"><span class="arm">{esc(arm_label)}'
            f'</span> <span class="v">{esc(v)}</span> &middot; '
            + esc("  ·  ".join(tail)) + "</div>")


def pane(title: str, res: dict | None, run_dir: Path) -> str:
    body = None
    missing = "Not yet run."
    if res and res.get("svg_path") and (run_dir / res["svg_path"]).exists():
        body = two.inline_svg((run_dir / res["svg_path"]).read_text())
    elif res:
        missing = ("No scene survived the gates.\n"
                   + (res.get("schema_error") or res.get("error")
                      or "see the raw reply"))
    return (f'<div class="pane"><h3>{esc(title)}</h3><div class="figure">'
            + (body if body else f'<div class="missing">{esc(missing)}</div>')
            + "</div></div>")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--items", default="items/items.jsonl")
    ap.add_argument("--gemma-run", default="out/bigred-7859280")
    ap.add_argument("--codex-run", default="out/codex-arm")
    ap.add_argument("--output", default="out/comparison-3way/compare3.html")
    args = ap.parse_args()

    here = Path(__file__).resolve().parent
    items: dict[str, dict] = {}
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
    selfsay, limits = parse_codex_report(c_dir / "report.md")
    mcp: dict[str, str] = {}
    for p in sorted((c_dir / "mcp_log").glob("*.txt")):
        mcp[p.stem] = p.read_text().strip()

    order = list(items)
    counts: dict[str, int] = {}
    for iid in order:
        counts[items[iid]["band"]] = counts.get(items[iid]["band"], 0) + 1

    g_valid = sum(1 for i in order if g_res.get(i, {}).get("valid"))
    c_valid = sum(1 for i in order if c_res.get(i, {}).get("valid"))
    g_secs = [g_res[i]["seconds"] for i in order
              if i in g_res and g_res[i].get("seconds") is not None]
    g_tries: dict[int, int] = {}
    for i in order:
        a = g_res.get(i, {}).get("attempts")
        if a is not None:
            g_tries[a] = g_tries.get(a, 0) + 1
    c_tries: dict[int, int] = {}
    for i in order:
        a = c_res.get(i, {}).get("attempts")
        if a is not None:
            c_tries[a] = c_tries.get(a, 0) + 1

    run_label = g_meta.get("run_label", "run") + "+codex-arm"

    parts: list[str] = []
    parts.append(f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Hermes scene pilot — three-way — {esc(run_label)}</title>
<style>{two.CSS}{EXTRA_CSS}</style></head><body><main>""")

    parts.append("""
<h1>Two models, one grounding: the scan, then each arm&rsquo;s redrawing</h1>
<div class="lede">
<p>Both arms received the identical 16 prompts: the figure&rsquo;s written
description, the same Hermes rows, the same coordinate-free scene vocabulary.
Each wrote scene JSON; the same deterministic typesetter drew both arms&rsquo;
scenes, and the same four gates judged them. Left is the figure as scanned from
a research article. Middle is what gemma-4-E2B-it&rsquo;s scene typesets to.
Right is what codex gpt-5.6&rsquo;s scene typesets to. Neither model was given
the image.</p>
<p>The arms differ in model scale, reasoning budget, and live MCP access
&mdash; deliberately. Where the larger model succeeds on the same rows, the
fault was the small model; where the larger model itself names the rows as the
limit &mdash; quoted verbatim under each item &mdash; that is the
grounding&rsquo;s ceiling.</p>
<p>The gate lines report <b>validity only</b>: the reply held JSON, the JSON
obeyed the vocabulary, the typesetter drew it, and the drawing has ink on it.
Whether either drawing carries the error, the strategy, or the notational claim
the scan documents is yours to mark &mdash; one verdict per arm at each
item&rsquo;s foot; the marks keep themselves in this browser.</p>
</div>""")

    def dist(d: dict[int, int]) -> str:
        return ", ".join(f"{n} try&times;{d[n]}" if n == 1 else
                         f"{n} tries&times;{d[n]}" for n in sorted(d))

    facts = [
        f"items in this document &nbsp; <b>{len(order)}</b> &nbsp; ("
        + ", ".join(f"{k} {v}" for k, v in sorted(counts.items())) + ")",
        "gates, identical for both arms &nbsp; json_parses &middot; "
        "schema_validates &middot; typesets &middot; renders_non_empty",
        "&nbsp;",
        f"<b>gemma-4-E2B-it</b> (cluster, {esc(g_meta.get('base_url', '?'))}, "
        f"temperature {esc(g_meta.get('temperature', '?'))})",
        f"&nbsp; passed the gates &nbsp; <b>{g_valid} / {len(order)}</b>",
        f"&nbsp; tries &nbsp; {dist(g_tries)}",
        (f"&nbsp; generation &nbsp; {min(g_secs):.1f}&ndash;{max(g_secs):.1f} s "
         f"per item (mean {sum(g_secs)/len(g_secs):.1f})" if g_secs
         else "&nbsp; generation &nbsp; n/a"),
        "&nbsp;",
        "<b>codex gpt-5.6</b> (local, live Hermes MCP)",
        f"&nbsp; passed the gates &nbsp; <b>{c_valid} / {len(order)}</b> "
        "&nbsp; as re-gated here by the same chain; its own report claims "
        "16/16 and the two agree",
        f"&nbsp; tries &nbsp; {dist(c_tries)} &nbsp; "
        "(self-reported in its report; not independently logged)",
        "&nbsp; generation &nbsp; per-item timing was not recorded by the "
        "codex driver, so none is shown",
        f"&nbsp; items with extra Hermes MCP calls logged &nbsp; "
        f"<b>{len(mcp)} / {len(order)}</b> &nbsp; ({', '.join(sorted(mcp))})",
    ]
    parts.append('<div class="facts">' + "<br>".join(facts) + "</div>")

    parts.append("""
<div class="lede">
<p><b>What this page cannot show you.</b> The figure descriptions were produced
by an earlier LLM pass whose generating script is not in the repository; a
success here shows a model can redraw from a description plus Hermes rows, not
that it can read a figure. The codex arm validated its own drafts against the
same gate machinery while writing them, so its 16/16 is a self-check the
re-gate confirmed, not an independent result of restraint.</p>
</div>""")

    for iid in order:
        item = items[iid]
        gr = g_res.get(iid)
        cr = c_res.get(iid)
        d = item["description"]
        scan_uri = two.data_uri(item["png_disk_path"])

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
  {gate_line(gr, 'gemma-4-E2B-it')}
  {gate_line(cr, 'codex gpt-5.6')}"""
                     + (f"""
  <div class="selfsay">codex&rsquo;s own line: {esc(selfsay[iid])}</div>"""
                        if iid in selfsay else "")
                     + f"""
  <div class="triple">
    <div class="pane"><h3>the scan</h3><div class="figure">"""
                     + (f'<img alt="scan of {esc(iid)}" src="{scan_uri}">'
                        if scan_uri else
                        '<div class="missing">PNG not found on disk</div>')
                     + """</div></div>
    """ + pane("gemma-4-E2B-it typesets to", gr, g_dir) + """
    """ + pane("codex gpt-5.6 typesets to", cr, c_dir) + f"""
  </div>
  <div class="kicker">chosen because</div>
  <div class="desc">{esc(item['selected_because'])}</div>
  <div class="kicker">the description both models were given</div>
  <div class="desc">{esc(d.get('student_strategy') or '(not recorded)')}</div>
  <div class="prov">{esc(item.get('description_provenance', ''))}</div>
  <div class="tags">{esc(chr(10).join(extras))}</div>"""
                     + (f"""
  <div class="gap"><div class="kicker">not given to either model</div>
    {esc(gap)}</div>""" if gap else "")
                     + f"""
  <div class="kicker">the hermes rows both models were given</div>
  <pre class="rows">{two.rows_html(item)}</pre>"""
                     + (f"""
  <div class="limit"><div class="kicker">codex on where the grounding was the
    limit (verbatim from its report)</div>
    <p>{esc(limits[iid])}</p></div>""" if iid in limits else "")
                     + (f"""
  <div class="kicker">the extra hermes MCP calls codex logged</div>
  <pre class="mcp">{esc(mcp[iid])}</pre>""" if iid in mcp else "")
                     + f"""
  <div class="verdict3">
    <div class="row"><span class="q">essence caught &mdash; gemma?</span>"""
                     + "".join(
                         f'<label><input type="radio" name="v-gemma-{esc(iid)}" '
                         f'data-arm="gemma" value="{v}">{v}</label>'
                         for v in ("yup", "partly", "nope"))
                     + """</div>
    <div class="row"><span class="q">essence caught &mdash; codex?</span>"""
                     + "".join(
                         f'<label><input type="radio" name="v-codex-{esc(iid)}" '
                         f'data-arm="codex" value="{v}">{v}</label>'
                         for v in ("yup", "partly", "nope"))
                     + """</div>
    <div class="row"><span class="note"><input type="text"
      placeholder="note"></span></div>
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
<script>var RUN={json.dumps(run_label)};{JS3}</script>
</body></html>""")

    html = "\n".join(parts)
    out_html = Path(args.output) if Path(args.output).is_absolute() \
        else here / args.output
    out_html.parent.mkdir(parents=True, exist_ok=True)
    out_html.write_text(html)
    n_g = sum(1 for i in order if g_res.get(i, {}).get("svg_path")
              and (g_dir / g_res[i]["svg_path"]).exists())
    n_c = sum(1 for i in order if c_res.get(i, {}).get("svg_path")
              and (c_dir / c_res[i]["svg_path"]).exists())
    print(f"wrote {out_html}  ({len(html):,} bytes, {len(order)} items, "
          f"{n_g} gemma + {n_c} codex scenes inlined)")

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
        print("  self-contained: nothing is loaded at view time")
    print("  written under the scratch tree, outside the repository")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
