# The scene vocabulary

What a figure may say, with no way to say where anything goes.

Round 1 asked gemma-4-E2B-it for SVG. It named the right mathematics and then
put it in the wrong places: labels printed over each other, a filled rectangle
drawn across its own caption, text past the edge of a canvas the model had
declared too small for the content it went on to add. The content was mostly
sound and the page was unreadable.

The split here follows one the render lane already runs on. In
`knowledge/strategies/render/notation_scene.pl` the Prolog computes every glyph
x and the JavaScript drawer does no arithmetic. Here the model supplies content
and `typeset.py` does all the arithmetic. The model never places anything,
because there is nothing in this vocabulary with which to place it.

## The rule

**No field is a coordinate, a size, or a colour.** `x`, `y`, `width`, `height`,
`size`, `fill`, `stroke`, `transform` and their relatives are rejected by name,
at whatever depth they appear.

Indices do appear — "this note attaches to column 2", "this arc runs from tick 0
to tick 3" — and they are references into a list the scene itself declares, not
placements. Everything else is free text or a member of a closed enum.

A scene that says something the vocabulary cannot express is a **refusal at
generation time**, and the refusal names its path:

```
panels[1].blocks[0].rows[2].cells[3].mark: 'cross' is not one of
  ['none', 'strike', 'circle', 'box', 'underline']
```

The typesetter never improvises a rectangle to cover a gap.

## Shape

```
scene  = {title, caption?, panels[1..4]}
panel  = {role, title?, blocks[1..6]}
block  = column_calc | expr_lines | bar | number_line
       | base_ten | table | shape | note
```

Ten node types in all: the scene, the panel, and eight blocks.

`panel.role` is one of `student`, `correct`, `given`, `contrast`. Putting the
student's work and the correct work in separate panels is how a wrong step is
made to look different from a right one; the typesetter frames each panel and
gives it an accent from its role.

## Shared pieces

A **cell** is one glyph slot:

```json
{"text": "4", "role": "error", "mark": "strike",
 "above": "14", "below": "..."}
```

`text` is optional — a cell may carry only a carry digit. Every field but
`text`, `above` and `below` is enumerated.

- **role** — `ink` `error` `annotation` `correct` `muted`
- **mark** — `none` `strike` `circle` `box` `underline`

Roles carry the colour, taken from `hermes/web/render/host.css` rather than
invented: `error` is the deformation rust `#b95238` that already marks a
misconception in the notation drawer, `annotation` the point blue `#4c6b8a`,
`correct` the bar green `#6e8b5d`, ink `#0d0c08` on paper `#f4ead6`.

## The eight blocks

### column_calc
Written arithmetic in columns. Rows are right-aligned into the grid, so a
two-digit subtrahend sits correctly under a three-digit minuend. The horizontal
rule is drawn above the first `result` row unless `rule_after` says otherwise.
`column_notes` attach prose to a named column, drawn below the grid with a
caret under the column it means.

### expr_lines
Lines of written mathematics. A token matching `n/d` is typeset as a stacked
fraction, so the model writes `2/7 + 3/7 = 5/7` and gets a proper vinculum.
Each line may carry a mark and a subordinate note.

### bar
A partitioned bar: fraction bar or area model. **Every bar in one panel is drawn
to the same total length**, so stacking a bar of four parts above a bar of eight
shows one partition against the other without any nesting in the schema.

### number_line
One lane, or several for a double number line. Ticks are evenly spaced and every
lane must have the same number of them, which is what makes the lanes line up.
`points` and `arcs` refer to ticks by index.

### base_ten
`flat` = hundred, `rod` = ten, `cube` = one, arranged in labelled columns so the
same block serves a loose pile and a place-value chart. `marked` is how many of
a group carry the mark; `partial` fills that many of one rod's ten segments.

### table
A small grid of text cells — a place-value chart, a ratio table.

### shape
Named figures only. The model never supplies a vertex; it names a `kind` and
optionally a quarter-turn `rotation`, and the typesetter draws the canonical
figure. A shape outside the list is a refusal rather than an approximation.

`trapezoid parallelogram rectangle square triangle right_triangle pentagon
hexagon circle l_tromino l_tetromino t_tetromino s_tetromino square_tetromino`

### note
A line of prose, at `normal` or `strong` emphasis.

## What the smoke changed

Two rules were relaxed after watching the model meet them, and both times the
vocabulary was needlessly strict rather than the model wrong:

- **`text` became optional on a cell.** The model wrote `{"above": "13"}` for a
  column holding only a carry. That is a reasonable thing to mean, and a retry
  quoting the path back did not change it.
- **Column labels may declare a wider grid than any row fills.** Rows are
  right-aligned, so a row shorter than the labels is correct, not incoherent.
  Only the reverse — a row wider than the grid — is refused.

A third change sits in the gate rather than the schema: a reply that stops
mid-object has its open structures closed so the prefix can be judged, and the
repair is recorded on the item. Losing a whole figure to a missing brace is a
worse answer than closing it and saying so.
