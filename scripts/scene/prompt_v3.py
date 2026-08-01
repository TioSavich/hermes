#!/usr/bin/env python3
"""Prompt v3: ask for a scene, never for a drawing.

The v2 prompt asked for SVG and got the mathematics right and the page wrong.
This one removes the ability to be wrong in that way: there is no coordinate to
supply, so there is no coordinate to get wrong. What is left is the part the
model was already good at -- naming which digit is the error, what the exchange
was, what the note should say.

The essence framing survives from v2 because it was not the problem. What is new
is the vocabulary, stated compactly, and one worked example of the shape the
pilot cares most about: a wrong-vs-right column subtraction pair.

Standard library only.
"""
from __future__ import annotations

import json

ESSENCE = """\
You are helping rebuild a figure of student mathematics that you cannot see.
You get the figure's written description and rows from Hermes, a Prolog engine
that runs the strategies as automata.

Carry the ESSENCE, not the appearance. The essence is the error, the strategy,
or the notational claim the figure documents. If a student took the smaller
digit from the larger one in every column, the essence is the exchange going
missing, and a clean diagram that makes that legible succeeds even though it
resembles the scan not at all. Redraw the mathematics; do not imitate the paper.

Say only what your input supports. If the description does not say a step went
wrong, do not mark one wrong. If the Hermes rows reach a different answer from
the one the student wrote, that difference is worth showing, and inventing an
error the input does not carry is worse than drawing less.

But where your input DOES name an error, the scene has to make it visible.
Reproducing the student's work correctly and saying nothing about it is not a
figure of the error; it is a copy of the page. Put the student's work and the
correct work in separate panels, mark the particular digit or line where the two
diverge, and say in a note what went missing between them. A reader who cannot
tell from the drawing which step failed has not been shown the error."""

FORMAT = """\
Reply with ONE JSON object and nothing else. No markdown fence, no commentary.

You describe WHAT the figure says. A typesetter decides where everything goes,
so the JSON contains no coordinates, sizes, or colours -- any x, y, width,
height, or fill is rejected. Roles carry the meaning: "error" prints rust,
"annotation" blue, "correct" green, "ink" black, "muted" grey."""

SCHEMA = """\
{"title": str, "caption": str (optional), "panels": [1-4 panels]}

panel = {"role": "student"|"correct"|"given"|"contrast",
         "title": str (optional), "blocks": [1-6 blocks]}

Put the student's work and the correct work in SEPARATE panels. That pairing is
how a wrong step is made to look different from a right one.

Each block is one of:

column_calc  columns of digits, for written arithmetic
  {"type":"column_calc",
   "columns": ["hundreds","tens","ones"],        optional labels, left to right
   "rows": [{"kind":"operand"|"result"|"work", "operator":"-" (optional),
             "cells":[cell, ...]}],              right-aligned, one cell per digit
   "column_notes":[{"column": int, "text": str, "role": role}]}
  cell = {"text":"4", "role":role, "mark":"none"|"strike"|"circle"|"box"|
          "underline", "above":"14" (a carry or a replacement digit),
          "below":str}
  The horizontal rule goes above the first "result" row automatically.

expr_lines   written lines of mathematics; "2/7" prints as a stacked fraction
  {"type":"expr_lines","lines":[{"text":"2/7 + 3/7 = 5/7", "role":role,
                                 "mark":mark, "note":str, "note_role":role}]}

bar          a partitioned bar: fraction bar or area model
  {"type":"bar","label":str,"parts":[{"text":"1/7","shaded":true,"role":role,
                                      "mark":mark}]}
  Bars in one panel are drawn the same total length, so stacking two bars with
  different part counts shows one partition against the other.

number_line  one lane, or several for a double number line
  {"type":"number_line",
   "lanes":[{"label":"metres","ticks":[{"text":"0"},{"text":"2.5"}],
             "points":[{"at":1,"text":"here","role":role}]}],
   "arcs":[{"lane":0,"from":0,"to":1,"text":"x2","role":role}]}
  Ticks are evenly spaced. "at", "from", "to" are tick positions counting from
  0. Every lane needs the same number of ticks.

base_ten     blocks: "flat" = hundred, "rod" = ten, "cube" = one
  {"type":"base_ten","columns":[{"label":"tens","groups":[
     {"unit":"rod","count":5,"marked":1,"mark":"strike","partial":4}]}]}
  "marked" is how many of that group carry the mark. "partial" fills that many
  of a single rod's ten segments.

table        a small grid of text, e.g. a place-value chart
  {"type":"table","headers":["tens","ones"],"rows":[[cell, cell]]}

shape        named figures only, never vertices
  {"type":"shape","grid":"none"|"dots","figures":[
     {"kind":kind,"label":str,"rotation":0|90|180|270,"role":role}]}
  kind = trapezoid parallelogram rectangle square triangle right_triangle
         pentagon hexagon circle l_tromino l_tetromino t_tetromino
         s_tetromino square_tetromino

note         a line of prose
  {"type":"note","text":str,"role":role,"emphasis":"normal"|"strong"}

If the figure needs something this vocabulary cannot say, say the nearest thing
it can and put the rest in a note. Do not invent a block type."""

# Deliberately NOT one of the pilot's own figures, and deliberately a different
# error from any of them. The first draft of this prompt used 364 - 236, which
# is item M1, and the smoke showed the model returning the example back with the
# note lightly reworded: the item stopped being a test. 53 - 27 with the tens
# left unreduced is the registry's own worked case and appears in no item.
EXAMPLE = {
    "title": "53 - 27: the ten borrowed twice over",
    "panels": [
        {"role": "student", "title": "what the student wrote",
         "blocks": [
             {"type": "column_calc",
              "columns": ["tens", "ones"],
              "rows": [
                  {"kind": "operand", "cells": [
                      {"text": "5"}, {"text": "3", "above": "13"}]},
                  {"kind": "operand", "operator": "-", "cells": [
                      {"text": "2"}, {"text": "7"}]},
                  {"kind": "result", "cells": [
                      {"text": "3", "role": "error"}, {"text": "6"}]}],
              "column_notes": [
                  {"column": 0, "role": "error",
                   "text": "the ones took a ten and the tens still read 5, so "
                           "the same ten is counted in both columns"}]}]},
        {"role": "correct", "title": "the exchange paid for",
         "blocks": [
             {"type": "column_calc",
              "columns": ["tens", "ones"],
              "rows": [
                  {"kind": "operand", "cells": [
                      {"text": "5", "above": "4", "mark": "strike"},
                      {"text": "3", "above": "13"}]},
                  {"kind": "operand", "operator": "-", "cells": [
                      {"text": "2"}, {"text": "7"}]},
                  {"kind": "result", "cells": [
                      {"text": "2", "role": "correct"}, {"text": "6"}]}],
              "column_notes": [
                  {"column": 0, "role": "correct",
                   "text": "the 5 becomes 4 because the ten was spent"}]}]}],
    "caption": "The exchange was taken in the ones and never paid for in the "
               "tens, so the difference comes out ten too large.",
}


def describe_grounding(grounding: list[dict]) -> str:
    if not grounding:
        return ("No Hermes rows were retrieved for this figure. Work from the "
                "description alone, and draw less rather than inventing more.")
    out: list[str] = []
    for g in grounding:
        out.append(f"[{g['op']}] {json.dumps(g['arguments'])}")
        if g.get("input_provenance"):
            out.append(f"  input: {g['input_provenance']}")
        r = g["result"]
        if not r.get("ok", True) and r.get("refusal"):
            out.append(f"  REFUSED: {r['refusal']}")
            if r.get("diagnosis"):
                out.append(f"  why: {r['diagnosis']}")
        elif "steps" in r:
            out.append(f"  automaton {r.get('strategy')} -> {r.get('result')}")
            for s in r["steps"]:
                line = f"    {s['n']}. {s['label']}"
                if s.get("value"):
                    line += f" -> {s['value']}"
                out.append(line)
        elif "rows" in r:
            if not r["rows"]:
                out.append(f"  no rows matched (count {r.get('count', 0)})")
            for row in r["rows"]:
                out.append(f"    - {row['name']} [{row.get('domain', '?')}]: "
                           f"{row.get('citation', '')}")
        if g.get("figure_answer") and g.get("reproduces_figure") is False:
            out.append(f"  NOTE: the student wrote {g['figure_answer']}; this "
                       f"automaton reaches a different number. Show the "
                       f"student's own answer, and do not relabel it.")
        if g.get("_note"):
            out.append(f"  note: {g['_note']}")
        out.append("")
    return "\n".join(out)


def build_prompt(item: dict) -> str:
    d = item["description"]
    facts: list[str] = []
    if d.get("student_strategy"):
        facts.append(f"What the figure shows: {d['student_strategy']}")
    if d.get("transcribed_math"):
        facts.append(f"Numerals transcribed from the figure: {d['transcribed_math']}")
    if d.get("error_topics"):
        facts.append("Error topics recorded for this paper (they describe the "
                     "article, not necessarily this figure): "
                     + "; ".join(d["error_topics"]))
    if item.get("representation_language") and \
            item["representation_language"] != "none":
        facts.append(f"Representation language: {item['representation_language']}")
    if item.get("spatial_elements"):
        facts.append("Spatial elements: " + ", ".join(item["spatial_elements"]))
    facts.append(f"Grade band: {item['grade_bucket']}")

    return "\n\n".join([
        ESSENCE,
        FORMAT,
        "THE VOCABULARY\n\n" + SCHEMA,
        "A WORKED EXAMPLE -- a wrong-vs-right column subtraction:\n\n"
        + json.dumps(EXAMPLE, indent=1),
        "THE FIGURE\n\n" + "\n".join(facts),
        "HERMES ROWS\n\n" + describe_grounding(item["grounding"]),
        "Now reply with the JSON scene for THIS figure. JSON only.",
    ])
