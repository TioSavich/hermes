#!/usr/bin/env python3
"""Assemble best_IM.html from the lesson-enactment rows.

The arithmetic rungs of the lesson census report what Hermes can compute. This
page reports something else: what Hermes does with a lesson that asks for a
doing no automaton computes. Each card carries the structural form the lesson
takes, the printed span that licensed reading it that way, the inputs and where
they came from, the steps the machine ran, the artifact it produced, and one
sentence naming what the artifact does not claim.

Every lane writes one JSONL file into
``data/learningcommons/derived/lesson_enactments/``. A new lane joins this page
by writing its file; nothing here is keyed to a lane by name, and a subclass
with no title below gets its identifier spelled out rather than being skipped.

Scenes are drawn through ``hermes/app/rendering.py``, the adapter the rest of
the repository already uses. This builder owns no drawing code.

Run from the repository root:
    python3 scripts/enactment/build_best_im.py
"""

from __future__ import annotations

import html
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from hermes.app.rendering import render_svg  # noqa: E402

ROWS_DIR = ROOT / "data/learningcommons/derived/lesson_enactments"
RECUT = ROOT / "data/learningcommons/derived/im_action_seam_recut.json"
PAGE = ROOT / "hermes/app/web/generated/best_IM.html"
SCENES = ROOT / "hermes/app/web/generated/best_IM_scenes"

PAPER = "#f8f1df"
INK = "#1b1810"
RULE = "#cabf9f"
PRODUCTIVE = "#365f6b"
WITHHELD = "#8b1e16"
QUIET = "#6b6152"
MID = "#4a4235"
CARD = "#fdf8ec"

SUBCLASS_TITLES = {
    "geometry_construction_or_measure": "Construction and measure",
    "measurement_task": "Measurement",
    "data_representation_or_question": "Data, representation, and question",
    "counting_place_value_or_comparison": "Counting, place value, and comparison",
    "fraction_model_reasoning": "Fraction models",
}

PROVENANCE_TEXT = {
    "curriculum": ("the lesson prints these values", PRODUCTIVE),
    "curriculum_sample": (
        "the lesson prints these values as one worked sample of an open task",
        PRODUCTIVE,
    ),
    "machine_supplied": (
        "the lesson leaves these values to the classroom and the machine chose them",
        WITHHELD,
    ),
}


def esc(value) -> str:
    return html.escape(str(value), quote=True)


def load_rows() -> list[dict]:
    rows = []
    for path in sorted(ROWS_DIR.glob("*.jsonl")):
        for number, line in enumerate(
            path.read_text(encoding="utf-8").splitlines(), 1
        ):
            line = line.strip()
            if not line:
                continue
            try:
                rows.append(json.loads(line))
            except json.JSONDecodeError as error:
                raise SystemExit(
                    f"{path.name}:{number} is not one JSON object: {error}"
                )
    return rows


def population() -> Counter:
    payload = json.loads(RECUT.read_text(encoding="utf-8"))
    return Counter(lesson["task_209_subclass"] for lesson in payload["lessons"])


def scene_documents(artifact: dict) -> list[dict]:
    """Every render document inside one artifact, in the order a reader meets them.

    An artifact is a scene, a printed record, or a list of both. The geometry
    lane usually draws a figure and prints the adjudication beside it, so a
    reader that looked only at the top-level kind would drop most of the figures
    on this page.
    """
    kind = artifact.get("kind")
    if kind == "scene":
        return [artifact["scene"]]
    if kind == "scene_and_record":
        found: list[dict] = []
        for part in artifact.get("parts", []):
            found.extend(scene_documents(part))
        return found
    return []


def printed_records(artifact: dict) -> list[str]:
    kind = artifact.get("kind")
    if kind == "printed":
        return [artifact.get("record", "")]
    if kind == "scene_and_record":
        found: list[str] = []
        for part in artifact.get("parts", []):
            found.extend(printed_records(part))
        return found
    return []


def draw(row: dict) -> list[str]:
    """Scene filenames for this row, drawn through hermes/app/rendering.py."""
    written: list[str] = []
    documents = scene_documents(row.get("artifact", {}))
    for index, document in enumerate(documents, 1):
        suffix = "" if len(documents) == 1 else f"-{index}"
        name = f"{row['lesson']}-{row['form']}{suffix}.svg"
        try:
            render_svg(document, "filmstrip", SCENES / name)
        except Exception as error:  # a refusal to draw is reported, never hidden
            print(f"  scene refused for {row['lesson']} {row['form']}: {error}")
            continue
        written.append(name)
    return written


def verdict_mark(verdict: str) -> str:
    colour = PRODUCTIVE if verdict.startswith("well_formed") else WITHHELD
    return (
        f"<span style='font-size:12px;font-weight:700;color:{colour};"
        f"border:1px solid {colour};border-radius:3px;padding:1px 6px'>"
        f"{esc(verdict)}</span>"
    )


def provenance_mark(provenance: str) -> str:
    text, colour = PROVENANCE_TEXT.get(
        provenance, (f"provenance {provenance}", WITHHELD)
    )
    return (
        f"<span style='font-size:12px;color:{colour};border:1px dashed {colour};"
        f"border-radius:3px;padding:1px 6px'>{esc(text)}</span>"
    )


def inputs_html(row: dict) -> str:
    entries = row.get("inputs", [])
    if not isinstance(entries, list) or not entries:
        return ""
    parts = []
    for entry in entries:
        if not isinstance(entry, dict):
            continue
        if "key" in entry:
            label = entry["key"]
            value = entry.get("value", "")
            note = entry.get("provenance", "")
        elif "pass" in entry:
            label = entry["pass"]
            bindings = entry.get("bindings", [])
            value = ", ".join(
                f"{b.get('key')}={b.get('value')}"
                for b in bindings
                if isinstance(b, dict)
            )
            note = ""
        else:
            label = entry.get("index", "")
            value = entry.get("operand", "")
            note = ""
        tail = (
            f" <span style='color:{QUIET}'>{esc(note)}</span>" if note else ""
        )
        parts.append(
            f"<li style='margin:0 0 2px'><code>{esc(label)}</code> "
            f"<code style='color:{MID}'>{esc(value)}</code>{tail}</li>"
        )
    if not parts:
        return ""
    return (
        f"<p style='margin:0 0 4px;font-size:13px'><strong>Inputs</strong></p>"
        f"<ul style='margin:0 0 12px;padding-left:18px;font-size:13px;"
        f"list-style:none'>{''.join(parts)}</ul>"
    )


def warrant_html(row: dict) -> str:
    warrant = row.get("warrant") or {}
    form_warrant = row.get("form_warrant") or {}
    text = warrant.get("text", "")
    source = warrant.get("source", "")
    line = warrant.get("line", "")
    cite = f"{esc(source)}:{esc(line)}" if source else ""
    block = (
        f"<blockquote style='margin:0 0 10px;border-left:3px solid {RULE};"
        f"padding:2px 0 2px 12px;color:{MID}'>{esc(text)}"
        f"<br><span style='font-size:12px;color:{QUIET}'>{cite}</span>"
    )
    # The form's own warrant is often a different span in a different lesson: a
    # shape is named once, where it shows most plainly, and recognized many
    # times after. Printing both keeps the naming checkable without attaching
    # this lesson to a page that is not its own.
    read_from = form_warrant.get("read_from_lesson", "")
    if read_from and read_from != row.get("lesson"):
        block += (
            f"<br><span style='font-size:12px;color:{QUIET}'>The form was named "
            f"from {esc(read_from)}, {esc(form_warrant.get('source', ''))}:"
            f"{esc(form_warrant.get('line', ''))}</span>"
        )
    return block + "</blockquote>"


def card(row: dict, scenes: list[str]) -> str:
    steps = "".join(
        "<tr>"
        f"<td style='padding:3px 10px 3px 0;color:{QUIET};vertical-align:top'>"
        f"{esc(step.get('index'))}</td>"
        f"<td style='padding:3px 10px 3px 0;vertical-align:top'>"
        f"<code>{esc(step.get('verb'))}</code></td>"
        f"<td style='padding:3px 10px 3px 0;color:{MID};vertical-align:top'>"
        f"<code>{esc(step.get('operand'))}</code></td>"
        f"<td style='padding:3px 0;vertical-align:top'>"
        f"<code>{esc(step.get('result'))}</code></td>"
        "</tr>"
        for step in row.get("steps", [])
    )

    pieces = []
    for name in scenes:
        pieces.append(
            f"<figure style='margin:0'><img src='best_IM_scenes/{esc(name)}' "
            f"alt='scene for {esc(row['lesson'])}' style='max-width:100%;"
            f"border:1px solid {RULE};background:{PAPER}'></figure>"
        )
    for record in printed_records(row.get("artifact", {})):
        pieces.append(
            f"<pre style='margin:0;padding:10px;background:#f2e7ce;"
            f"border:1px solid {RULE};overflow-x:auto;font-size:13px;"
            f"white-space:pre-wrap;word-break:break-word'>{esc(record)}</pre>"
        )
    artifact = (
        "<div style='display:flex;flex-direction:column;gap:10px'>"
        + "".join(pieces)
        + "</div>"
    )

    return f"""
<article style='border:1px solid {RULE};background:{CARD};padding:16px 18px;margin:16px 0'>
  <h3 style="font-family:Georgia,'Times New Roman',serif;margin:0 0 2px">
    {esc(row['lesson'])} &middot; grade {esc(row['grade'])} &middot; <em>{esc(row['form'])}</em>
  </h3>
  <p style='margin:0 0 10px;color:{MID}'>{esc(row.get('form_gloss', ''))}</p>
  <p style='margin:0 0 10px'>{verdict_mark(row.get('verdict', ''))}
     &nbsp; {provenance_mark(row.get('input_provenance', ''))}</p>
  {warrant_html(row)}
  {inputs_html(row)}
  <table style='border-collapse:collapse;font-size:13px;margin:0 0 12px'>{steps}</table>
  {artifact}
  <p style='margin:10px 0 0;font-size:13px;color:{WITHHELD}'>
    <strong>What this does not claim:</strong> {esc(row.get('what_it_does_not_claim', ''))}</p>
</article>"""


def main() -> int:
    if not ROWS_DIR.is_dir():
        raise SystemExit(f"no enactment rows at {ROWS_DIR.relative_to(ROOT)}")
    rows = load_rows()
    if not rows:
        raise SystemExit("no enactment rows to assemble")
    missing = [
        row.get("lesson", "?")
        for row in rows
        if not str(row.get("what_it_does_not_claim", "")).strip()
    ]
    if missing:
        raise SystemExit(
            "these rows carry no sentence about what they do not claim, and "
            f"the page will not print a card without one: {sorted(set(missing))}"
        )
    SCENES.mkdir(parents=True, exist_ok=True)
    for stale in SCENES.glob("*.svg"):
        stale.unlink()

    counts = population()
    grouped = defaultdict(list)
    for row in rows:
        grouped[row["subclass"]].append(row)

    drawn = 0
    body = []
    for subclass in sorted(grouped, key=lambda key: -len(grouped[key])):
        lane = sorted(
            grouped[subclass],
            key=lambda r: (str(r["grade"]), r["lesson"], r["form"]),
        )
        lessons = len({row["lesson"] for row in lane})
        total = counts.get(subclass, 0)
        title = SUBCLASS_TITLES.get(subclass, subclass.replace("_", " "))
        body.append(
            "<h2 style=\"font-family:Georgia,'Times New Roman',serif;"
            f'margin:34px 0 4px">{esc(title)}</h2>'
            f"<p style='margin:0 0 4px;color:{MID}'>{lessons} of {total} lessons "
            f"in this class, {len(lane)} enactments.</p>"
        )
        for row in lane:
            scenes = draw(row)
            drawn += 1 if scenes else 0
            body.append(card(row, scenes))

    lessons_total = len({row["lesson"] for row in rows})
    well_formed = sum(
        1 for row in rows if str(row.get("verdict", "")).startswith("well_formed")
    )
    machine_inputs = sum(
        1 for row in rows if row.get("input_provenance") == "machine_supplied"
    )
    samples = sum(
        1 for row in rows if row.get("input_provenance") == "curriculum_sample"
    )
    forms = len({row["form"] for row in rows})
    denominator = sum(counts.values())

    head = f"""<!doctype html><meta charset=utf-8>
<title>best_IM - what Hermes does with a lesson it cannot compute</title>
<body style='font-family:system-ui;background:{PAPER};color:{INK};max-width:1100px;margin:0 auto;padding:28px'>
<h1 style="font-family:Georgia,'Times New Roman',serif">What Hermes does with a lesson it cannot compute</h1>
<p style='max-width:820px;line-height:1.5'>
Most of the lesson census asks whether an automaton computes a lesson's arithmetic.
These {lessons_total} lessons of {denominator} ask for something else, and until this
build they were counted only as an absence. Each card below carries a machine reading
the lesson's structural form, running that form on inputs, and printing what it
produced. {forms} forms are in use across five lanes. {well_formed} of {len(rows)}
enactments are well formed; the rest print the reason they stopped short.
{machine_inputs} ran on values the machine supplied because the lesson asks a class to
bring its own, and {samples} ran on values the guide prints as one worked sample of an
open task. Every one of those says so on its own card.</p>
<p style='max-width:820px;line-height:1.5;border-left:4px solid {WITHHELD};background:#f7ece9;
padding:12px 16px;margin:18px 0'>
Read the last line of every card. A machine that sorts shapes has not watched a child
sort shapes, and a machine that lists what a data display answers has not held a
discussion. The forms are read from the curriculum and the steps are executed; the
classroom is not. Nothing here is a coverage number for the arithmetic rungs, which are
counted separately and are unaffected by anything on this page.</p>
<p style='font-size:13px;color:{QUIET}'>Built by <code>scripts/enactment/build_best_im.py</code>
from <code>data/learningcommons/derived/lesson_enactments/</code>, which the enactors
write by running. Scenes drawn through <code>hermes/app/rendering.py</code>; this page
owns no drawing code. {drawn} of {len(rows)} enactments produced a drawing; the others
printed a record.</p>
"""
    PAGE.parent.mkdir(parents=True, exist_ok=True)
    PAGE.write_text(head + "\n".join(body) + "\n", encoding="utf-8")
    print(
        f"best_IM {lessons_total} lessons {len(rows)} enactments {forms} forms "
        f"{well_formed} well_formed {machine_inputs} machine_supplied "
        f"{samples} curriculum_sample {drawn} drawn -> "
        f"{PAGE.relative_to(ROOT)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
