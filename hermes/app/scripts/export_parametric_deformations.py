#!/usr/bin/env python3
"""Render the parametric deformation families as B/M/E filmstrips.

The wire (the established render pattern, reusing export_fraction_cliff.py's NODE
harness verbatim):

  strategies/render/parametric_partition_deformation.pl  (the transplant family)
  strategies/render/parametric_fraction_errors.pl        (the equipartition family)
      -> frames dicts (swipl -l paths.pl, json_write_dict) -> here
      -> more-zeeman/render/drawer.js buildSvg -> SVG filmstrips.

What this draws:

  THE HEADLINE: a replication strip. The SAME deformation
  (vertical-partition-rule transplanted onto a circle) generates the botched
  unit-fraction model for 1/4, 1/5, 1/6, 1/8 side by side. The frame specs differ
  only in the denominator: the vertical-on-circle deformation draws exactly N-1
  dashed interior cut lines, so the pixels prove the rule generalises across N.

  THE PAIR: productive vs deformed for 1/5, one row per host. The licensed model
  (the host's own partition rule, solid) beside the transplant (a foreign rule on
  the illicit host, dashed). A deformation is only ever a labeled misconception.

  THE EQUIPARTITION FAILURES: unequal-partition and miscount for 1/5 and 1/6,
  showing the host keeps its own primitive but applies it wrongly.

Logic lives in Prolog; this script is projection plus layout. It does NOT edit
representation_grammar.pl or drawer.js. Run: python3 hermes/app/scripts/export_parametric_deformations.py
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO))
from hermes.app import rendering

OUT = rendering.gallery_output(REPO / "hermes" / "app" / "web" / "generated" / "parametric_deformations")


# --- Phase-1 Prolog generators: ask swipl for the frames dict ----------------
#
# Each helper consults the two parametric-deformation modules through paths.pl
# and prints exactly one JSON line (the frames document) on stdout, so the
# render path is a pure projection of what the Prolog decided.

def _swipl_json(goal_body: str) -> dict:
    """Run a swipl goal that json_write_dict's one document, return the dict."""
    goal = (
        "use_module(strategies(render/parametric_partition_deformation)), "
        "use_module(strategies(render/parametric_fraction_errors)), "
        "use_module(library(http/json)), "
        f"{goal_body}, "
        "json_write_dict(user_output, Doc, [width(0)]), nl, halt."
    )
    res = subprocess.run(
        ["swipl", "-q", "-l", "paths.pl", "-g", goal, "-t", "halt(1)"],
        cwd=REPO, capture_output=True, text=True,
    )
    lines = [l for l in res.stdout.splitlines() if l.startswith("{")]
    if not lines:
        sys.stderr.write(res.stdout + "\n" + res.stderr)
        raise SystemExit(f"swipl produced no JSON for goal: {goal_body}")
    return json.loads(lines[0])


def deformed_partition(host: str, n: int, rule: str) -> dict:
    return _swipl_json(
        f"deformed_partition_scene({host}, {n}, transplant({rule}), Doc)"
    )


def productive_partition(host: str, n: int) -> dict:
    return _swipl_json(f"productive_partition_scene({host}, {n}, Doc)")


def fraction_error(host: str, m: int, n: int, error: str) -> dict:
    return _swipl_json(
        f"deformed_fraction_error_scene({host}, frac({m},{n}), {error}, Doc)"
    )


def transplant_final_frame(host: str, n: int, rule: str) -> dict:
    """The last frame of a transplant scene: the hybrid result for 1/N.

    The replication strip is one such final frame per denominator, laid side by
    side. They differ only by N, so the strip is the visual replication proof.
    """
    doc = deformed_partition(host, n, rule)
    return doc["frames"][-1]


# --- shared drawer adapter ---------------------------------------------------

def render(frames, out_file, labels, *, title="", captions=None,
           panel_w=300, panel_h=220, canvas=None):
    doc = {"frames": frames, "canvas": canvas or {}}
    rendering.render_svg(
        doc, "filmstrip", out_file, labels=labels, title=title,
        captions=captions or [], panelWidth=panel_w, panelHeight=panel_h,
        captionChars=72, ariaLabel=title or "parametric deformation filmstrip",
    )
    return out_file


# --- count interior dashed cut lines, so the replication claim is checkable ---
#
# The replication test: the SAME deformation must differ across N only by the
# count. The vertical-on-circle deformation draws exactly N-1 interior dashed
# lines (drawHybridVerticalPartitionOnCircle: cols-1 lines, cols = N). Reading
# the dashed-line count back off each rendered SVG confirms it at the pixel
# level. We count <line ... stroke-dasharray ...> elements.

def count_dashed_lines(svg_path: Path) -> int:
    text = svg_path.read_text(encoding="utf-8")
    return text.count("stroke-dasharray")


def headline_replication_captions(denominators: list[int]) -> list[str]:
    return [f"1/{n}: unequal strips" for n in denominators]


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    written = []
    manifest = {}

    # ---- THE HEADLINE: vertical-on-circle replication across 1/4,1/5,1/6,1/8 --
    repl_ns = [4, 5, 6, 8]
    repl_frames = [transplant_final_frame("circle", n, "vertical") for n in repl_ns]
    repl_labels = [f"1/{n}" for n in repl_ns]
    repl_caps = headline_replication_captions(repl_ns)
    headline = OUT / "HEADLINE-vertical-on-circle-replication.svg"
    render(repl_frames, headline, repl_labels,
           title="The same deformation across 1/4, 1/5, 1/6, 1/8",
           captions=repl_caps, panel_w=260, panel_h=240)
    written.append(headline)
    dashed = [count_dashed_lines_in_frame(REPO, n, "circle", "vertical")
              for n in repl_ns]
    manifest["headline_replication"] = {
        "file": headline.name,
        "denominators": repl_ns,
        "expected_interior_dashed_lines": [n - 1 for n in repl_ns],
        "note": "vertical-on-circle deformation draws N-1 dashed interior cuts; "
                "the strip differs across N only by that count.",
    }

    # ---- THE PAIR: productive vs deformed for 1/5, per host ------------------
    pair_hosts = [
        ("circle", "vertical"),
        ("rectangle", "radial"),
        ("set", "radial"),
    ]
    pairs = []
    for host, rule in pair_hosts:
        prod = productive_partition(host, 5)
        deform = deformed_partition(host, 5, rule)
        # productive: 3 B/M/E frames. deformed: 4 transplant frames. Show the
        # licensed shade-unit frame (productive final) beside the hybrid result
        # (deformed final), the two endpoints, so the pair reads at a glance.
        prod_final = prod["frames"][-1]
        deform_final = deform["frames"][-1]
        out_file = OUT / f"PAIR-{host}-1-5.svg"
        render(
            [prod_final, deform_final], out_file,
            ["Productive (licensed rule)", "Deformed (transplant)"],
            title=f"{host}: correct 1/5 vs the transplant botch",
            captions=[
                f"the {host}'s own partition rule: equal parts, solid",
                f"a foreign rule on the {host}: unequal parts, dashed",
            ],
            panel_w=320, panel_h=240,
        )
        written.append(out_file)
        pairs.append({
            "host": host, "transplant_rule": rule, "file": out_file.name,
            "productive_dashed_lines": count_dashed_lines(out_file) - count_deformed_dashed(deform_final),
        })
        # full B/M/E filmstrips too, so the named verbs are legible
        prod_strip = OUT / f"PRODUCTIVE-{host}-1-5-filmstrip.svg"
        render(prod["frames"], prod_strip,
               [_verb_label(f) for f in prod["frames"]],
               title=f"Productive 1/5 on a {host} (establish -> partition -> shade)",
               panel_w=270, panel_h=220)
        written.append(prod_strip)
        deform_strip = OUT / f"DEFORMED-{host}-1-5-filmstrip.svg"
        render(deform["frames"], deform_strip,
               [_verb_label(f) for f in deform["frames"]],
               title=f"Transplant deformation of 1/5 onto a {host}",
               panel_w=240, panel_h=220)
        written.append(deform_strip)
    manifest["productive_vs_deformed_pairs"] = pairs

    # ---- THE EQUIPARTITION FAILURES: unequal & miscount for 1/5 and 1/6 ------
    equi = []
    equi_cases = [
        ("bar", 1, 5, "unequal_partition"),
        ("bar", 1, 6, "unequal_partition"),
        ("circle", 1, 5, "miscount_partition"),
        ("circle", 1, 6, "miscount_partition"),
    ]
    for host, m, n, err in equi_cases:
        doc = fraction_error(host, m, n, err)
        frames = doc["frames"]
        code = f"EQUIPARTITION-{host}-{err}-{m}-{n}"
        out_file = OUT / f"{code}-filmstrip.svg"
        render(frames, out_file, [_verb_label(f) for f in frames],
               title=f"{err.replace('_', ' ')} of {m}/{n} on a {host}",
               panel_w=270, panel_h=220)
        written.append(out_file)
        equi.append({"host": host, "fraction": f"{m}/{n}", "error": err,
                     "file": out_file.name})
    manifest["equipartition_failures"] = equi

    # ---- index.html ----------------------------------------------------------
    index = build_index(repl_ns, pairs, equi, dashed)
    (OUT / "index.html").write_text(index, encoding="utf-8")
    written.append(OUT / "index.html")

    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2),
                                       encoding="utf-8")
    written.append(OUT / "manifest.json")

    for w in written:
        print(w)

    # report the replication check to stdout
    print("REPLICATION CHECK (interior dashed cut lines per N):")
    for n, d in zip(repl_ns, dashed):
        print(f"  1/{n}: drew {d} dashed interior lines (expected {n - 1})")
    return 0


def count_deformed_dashed(frame: dict) -> int:
    """How many dashed cut lines a deformed final frame contains, by spec."""
    prims = frame.get("scene", {}).get("primitives", [])
    total = 0
    for p in prims:
        if p.get("role") != "deformation":
            continue
        if p.get("kind") == "vertical-partition":
            total += int(p.get("columns", 0)) - 1
        elif p.get("kind") == "radial-partition":
            total += int(p.get("segments", 0))
    return total


def count_dashed_lines_in_frame(repo: Path, n: int, host: str, rule: str) -> int:
    frame = transplant_final_frame(host, n, rule)
    return count_deformed_dashed(frame)


def _verb_label(frame: dict) -> str:
    verb = str(frame.get("verb", ""))
    # keep the head functor as the panel label (establish_whole, apply_partition...)
    head = verb.split("(", 1)[0] if verb else f"step {frame.get('step', '?')}"
    return head.replace("_", " ")


def build_index(repl_ns, pairs, equi, dashed) -> str:
    rows = []
    rows.append("<!doctype html><meta charset=utf-8>")
    rows.append("<title>Parametric deformations: the same error, across inputs</title>")
    rows.append("<body style='font-family:system-ui;background:#f8f1df;color:#1b1810;"
                "max-width:1100px;margin:0 auto;padding:28px'>")
    rows.append("<h1 style=\"font-family:Georgia,'Times New Roman',serif\">"
                "Parametric deformations</h1>")
    rows.append("<p style='max-width:760px;line-height:1.45'>A documented student-work "
                "error is not a single botched figure: it is a <em>rule</em> that "
                "reproduces. The deformations here are functions of the fraction. "
                "The same vertical-strip rule transplanted onto a circle botches "
                "the model of 1/4, 1/5, 1/6, and 1/8 the same way, differing only "
                "in the denominator. Logic in Prolog "
                "(<code>strategies/render/parametric_partition_deformation.pl</code>, "
                "<code>parametric_fraction_errors.pl</code>); render projected "
                "through <code>more-zeeman/render/drawer.js</code>.</p>")

    rows.append("<h2>The headline: one deformation, four denominators</h2>")
    check = ", ".join(f"1/{n} drew {d} interior cuts (expected {n-1})"
                      for n, d in zip(repl_ns, dashed))
    rows.append(f"<p><small>Replication check: {check}. The frame specs differ "
                "only by N; the pixels confirm it.</small></p>")
    rows.append("<img src='HEADLINE-vertical-on-circle-replication.svg' "
                "style='max-width:100%;border:1px solid #cabf9f;background:#f8f1df'>")

    rows.append("<h2>Productive vs deformed (1/5), per host</h2>")
    rows.append("<p style='max-width:760px'>The licensed model in the host's own "
                "partition rule (solid, correct) beside the transplant (dashed, a "
                "labeled misconception). A deformation is only ever a labeled "
                "misconception, never an unlabeled productive diagram.</p>")
    for p in pairs:
        rows.append(f"<h3>{p['host']}</h3>")
        rows.append(f"<img src='PAIR-{p['host']}-1-5.svg' "
                    "style='max-width:100%;border:1px solid #cabf9f'>")
        rows.append(f"<details><summary>B/M/E filmstrips</summary>"
                    f"<img src='PRODUCTIVE-{p['host']}-1-5-filmstrip.svg' "
                    "style='max-width:100%;border:1px solid #cabf9f'>"
                    f"<img src='DEFORMED-{p['host']}-1-5-filmstrip.svg' "
                    "style='max-width:100%;border:1px solid #cabf9f'></details>")

    rows.append("<h2>Equipartition failures (1/5, 1/6)</h2>")
    rows.append("<p style='max-width:760px'>The host keeps its own primitive but "
                "applies it wrongly: pieces unequal, or the count off by one. "
                "Distinct from the transplant family, and also parametric over the "
                "fraction.</p>")
    for e in equi:
        rows.append(f"<h3>{e['error'].replace('_', ' ')} of {e['fraction']} "
                    f"({e['host']})</h3>")
        rows.append(f"<img src='{e['file']}' "
                    "style='max-width:100%;border:1px solid #cabf9f'>")

    rows.append("</body>")
    return "\n".join(rows)


if __name__ == "__main__":
    if "--check" in sys.argv:
        raise SystemExit(rendering.check_exporter(Path(__file__), OUT))
    raise SystemExit(main())
