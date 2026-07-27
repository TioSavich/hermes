#!/usr/bin/env python3
"""Restore the expressions the teacher-guide markdown conversion dropped.

The IM teacher guides do not typeset their expressions as text. Each character
is a filled outline drawn inside a ``q``/``cm``/path/``f``/``Q`` block, and each
inline expression sits inside its own clipping rectangle. ``pdftotext`` reads
text and draws nothing, so the conversion kept the frame of an item list and
carried nothing inside it: a prompt reading "Find the value of each expression
mentally" arrived followed by four empty bullets.

Two facts make the loss recoverable rather than permanent. Identical characters
carry identical path text in font units, so a path is a character's identity and
a table of a hundred labelled paths reads the corpus. And every checked-in guide
block is ``pdftotext -layout`` output byte for byte, so the same tool run over
the same PDF with the recovered characters written back in as text reproduces
the file it produced before, plus the expressions.

That second fact is what keeps the line numbers. Receipts in
``scripts/curriculum/lesson_negative_receipts.json`` and reviewed provenance in
the action-mapping compiler cite these files by physical line, so a rewrite that
moved lines would strand every citation into the file. This one does not move
them: each guide is refused unless its re-extraction has the same number of
lines and every line still contains its former characters in order.

Sources: the per-lesson PDFs live outside this checkout. Point ``--sources`` (or
``IM_TEACHER_GUIDE_PDFS``) at the directory holding the ``Kindergarten/``
through ``Grade5/`` bands. Without them the guides stay as they are and this
script says so rather than failing.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
import time
from collections import Counter
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GUIDE_ROOT = ROOT / "curriculum" / "im_teacher_guides"
GLYPH_TABLE = Path(__file__).with_name("guide_math_glyphs.json")
DEFAULT_SOURCES = Path(
    os.environ.get(
        "IM_TEACHER_GUIDE_PDFS",
        "/Users/tio/Documents/GitHub/Prolog/IM-Curriculum/TeacherLessonGuides",
    )
)

BANDS = {
    "kindergarten": "Kindergarten",
    "grade1": "Grade1",
    "grade2": "Grade2",
    "grade3": "Grade3",
    "grade4": "Grade4",
    "grade5": "Grade5",
}
GRADE_TOKEN = {"kindergarten": "K", "grade1": "1", "grade2": "2",
               "grade3": "3", "grade4": "4", "grade5": "5"}

FENCE = re.compile(r"(## Full Teacher Guide \(raw extract\)\n\n```\n)(.*?)(\n```)", re.S)

# Guides held back, and why. Restoring an expression adds quantities to the
# prompt that carries it, and a parser counting the quantities in a prompt can
# stop matching once they arrive. Recovery is meant to add evidence, never to
# cost a lesson the evidence it already had, so a guide whose recovery takes an
# instance away stays as it is until the parser reading it can carry the
# restored text.
HELD_BACK = {
    "IM-G1-U2-L18":
        "the prompt prints 8 - 3 = beside its story, and the story parser "
        "matches only a prompt carrying exactly two whole numbers "
        "(story_compare_difference_unknown, productive-subtract(8, 3))",
}


# ---------------------------------------------------------------- content stream

TOKEN = re.compile(rb"<[^>]*>|\([^)]*\)|/[^\s/\[\]<>()]+|[^\s\[\]]+|\[|\]")
NUMBER = re.compile(r"-?\d*\.?\d+")
PATH_OPS = {"m", "l", "c", "v", "y", "h", "re"}
FILL_OPS = {"f", "f*", "F", "B", "B*", "b", "b*"}
IDENTITY = (1.0, 0.0, 0.0, 1.0, 0.0, 0.0)


def _path_bounds(path: str):
    xs: list[float] = []
    ys: list[float] = []
    for piece in re.findall(r"[^a-z*]*(?:re|[mlcvyh])\*?", path):
        values = [float(v) for v in NUMBER.findall(piece)]
        if piece.rstrip().endswith("re") and len(values) >= 4:
            x, y, width, height = values[-4:]
            xs += [x, x + width]
            ys += [y, y + height]
            continue
        xs += values[0::2]
        ys += values[1::2]
    return (min(xs), min(ys), max(xs), max(ys)) if xs else None


class Glyph:
    """One filled outline, in page coordinates, with the clip box around it."""

    __slots__ = ("key", "x", "y", "scale", "width", "clip")

    def __init__(self, key, x, y, scale, bounds, clip):
        self.key, self.x, self.y, self.scale, self.clip = key, x, y, scale, clip
        self.width = (bounds[2] - bounds[0]) * scale


def page_glyphs(content: bytes) -> list[Glyph]:
    tokens = [t.decode("latin-1") for t in TOKEN.findall(content)]
    stack: list[tuple] = []
    ctm = IDENTITY
    clip = None
    operands: list[str] = []
    path: list[str] = []
    pending: str | None = None
    found: list[Glyph] = []
    for token in tokens:
        if NUMBER.fullmatch(token):
            operands.append(token)
            continue
        if token == "q":
            stack.append((ctm, clip))
            operands = []
            continue
        if token == "Q":
            ctm, clip = stack.pop() if stack else (IDENTITY, None)
            operands, path, pending = [], [], None
            continue
        if token == "cm" and len(operands) >= 6:
            a, b, c, d, e, f = (float(v) for v in operands[-6:])
            pa, pb, pc, pd, pe, pf = ctm
            ctm = (a * pa + b * pc, a * pb + b * pd,
                   c * pa + d * pc, c * pb + d * pd,
                   e * pa + f * pc + pe, e * pb + f * pd + pf)
            operands, path = [], []
            continue
        if token in PATH_OPS:
            path.append(" ".join(operands) + " " + token)
            operands = []
            continue
        if token in ("W", "W*"):
            pending = " ".join(path)
            operands = []
            continue
        if token == "n":
            bounds = _path_bounds(pending) if pending is not None else None
            if bounds is not None:
                a, b, c, d, e, f = ctm
                if b == 0 and c == 0:
                    clip = (bounds[0] * a + e, bounds[1] * d + f,
                            bounds[2] * a + e, bounds[3] * d + f)
            operands, path, pending = [], [], None
            continue
        if token in FILL_OPS:
            if path:
                a, b, c, d, e, f = ctm
                bounds = _path_bounds(" ".join(path))
                # A character is drawn in font units under a small scale. A path
                # in page units at scale near one is figure artwork and spells
                # nothing.
                if (bounds is not None and b == 0 and c == 0
                        and 0.0005 < a < 0.25 and 0.0005 < d < 0.25
                        and 10 < max(abs(v) for v in bounds) < 4000):
                    key = hashlib.sha1(" ".join(path).encode()).hexdigest()[:12]
                    found.append(Glyph(key, e, f, a, bounds, clip))
            operands, path, pending = [], [], None
            continue
        operands, path, pending = [], [], None
    return found


SHOW_OPS = {"Tj", "TJ", "'", '"'}


def text_baselines(content: bytes) -> list[float]:
    """The vertical positions at which this page shows text.

    The layout engine builds one output row per baseline it finds. Writing a
    recovered expression at the baseline of the row it belongs to keeps that
    row; writing it a few points off makes a row of its own and moves every
    line below it, which is what the citations into these files cannot survive.
    """
    tokens = [t.decode("latin-1") for t in TOKEN.findall(content)]
    operands: list[str] = []
    y = leading = 0.0
    line_y = 0.0
    found: set[float] = set()
    for token in tokens:
        if NUMBER.fullmatch(token):
            operands.append(token)
            continue
        if token == "BT":
            y = line_y = 0.0
        elif token == "TL" and operands:
            leading = float(operands[-1])
        elif token in ("Td", "TD") and len(operands) >= 2:
            line_y += float(operands[-1])
            y = line_y
            if token == "TD":
                leading = -float(operands[-1])
        elif token == "Tm" and len(operands) >= 6:
            line_y = float(operands[-1])
            y = line_y
        elif token == "T*":
            line_y -= leading
            y = line_y
        elif token in SHOW_OPS:
            found.add(round(y, 2))
        operands = []
    return sorted(found)


# How far a run's own baseline may sit from the text row it belongs to. Measured
# over 4,112 runs in four bands: 53% of runs sit exactly on a text baseline, and
# a second cluster sits 4.0 to 4.5 points above one, which is a fraction whose
# highest glyph is its numerator. Past 5.5 points the run is on a row of its
# own, and pulling it onto a neighbour's row would state the expression beside a
# prompt that does not carry it.
SNAP = 5.5


def snap(run, baselines: list[float]) -> float:
    """The baseline of the text row this expression reads on.

    A run whose glyphs include one sitting on a text baseline reads on that row,
    whatever else the run stacks above or below it. Otherwise the row is the
    nearest baseline within reach of the run's highest glyph, and a run out of
    reach keeps its own position.
    """
    highest = max(glyph.y for glyph in run)
    if not baselines:
        return highest
    for candidate in {round(glyph.y, 2) for glyph in run}:
        nearest = min(baselines, key=lambda base: abs(base - candidate))
        if abs(nearest - candidate) <= 1.0:
            return nearest
    nearest = min(baselines, key=lambda base: abs(base - highest))
    return nearest if abs(nearest - highest) <= SNAP else highest


def clip_runs(glyphs: list[Glyph]) -> list[list[Glyph]]:
    """One run per clip box. Every expression the guides typeset carries its
    own clip box, so an unclipped outline belongs to a figure, not to a prompt."""
    runs: dict[tuple, list[Glyph]] = {}
    for glyph in glyphs:
        if glyph.clip is not None:
            runs.setdefault(tuple(round(v, 2) for v in glyph.clip), []).append(glyph)
    return list(runs.values())


# ---------------------------------------------------------------------- decoding

TABLE = json.loads(GLYPH_TABLE.read_text(encoding="utf-8"))
BINARY = set("+-×÷=<>")
TIGHT = set(",.")


def _kind(glyph: Glyph) -> str | None:
    entry = TABLE.get(glyph.key)
    return entry["kind"] if entry else None


def _place(glyphs: list[Glyph]) -> list[tuple] | None:
    """Characters and fill-in blanks as placeable items.

    A blank is drawn as three copies of one rule segment with the middle one
    stretched, so consecutive segments collapse into a single mark.
    """
    items: list[tuple] = []
    for glyph in sorted(glyphs, key=lambda g: g.x):
        entry = TABLE.get(glyph.key)
        if entry is None or entry["kind"] == "rule":
            return None
        if entry["kind"] == "blank":
            if items and items[-1][2] == "___":
                start = items[-1][0]
                items[-1] = (start, glyph.x + glyph.width - start, "___", False)
                continue
            items.append((glyph.x, glyph.width, "___", False))
            continue
        items.append((glyph.x, glyph.width, entry["character"],
                      entry["character"] in BINARY))
    return items


# The layout engine maps a run of text onto character columns, and a single
# space set at the size that fits an expression into its box measures less than
# one column, so "8 - 3 =" arrives as "8-3=". Two spaces measure one column and
# come back as the one space the guide prints.
GAP = "  "


def _line(items: list[tuple], scale: float) -> str:
    out: list[str] = []
    previous = None
    for x, width, text, operator in sorted(items):
        if operator and out:
            out.append(GAP)
        elif (previous is not None and out and not out[-1].isspace()
              and text[:1] not in TIGHT and x - previous > 0.30 * scale * 1000):
            out.append(GAP)
        out.append(text)
        if operator:
            out.append(GAP)
        previous = x + width
    return "".join(out).strip()


def decode_run(run: list[Glyph]) -> list[tuple] | None:
    """The run's expression as placed tokens, or nothing when a glyph is unread.

    Each token keeps the position and width the page gave it. Writing the whole
    run as one string at one size would let the layout engine work out the
    spacing from that size instead of from the page, and a small size collapses
    "8 - 3 =" into "8-3=". Tokens written where the page put them get the
    spacing the page had.

    A run is read whole or refused whole. Half an expression would stand a
    quantity next to an operand the source never wrote there, which is a worse
    reading than the blank the conversion left.
    """
    if not run or any(_kind(glyph) is None for glyph in run):
        return None
    scale = run[0].scale
    consumed: set[int] = set()
    items: list[tuple] = []
    for rule in [g for g in run if _kind(g) == "rule"]:
        consumed.add(id(rule))
        above, below = [], []
        for glyph in run:
            if _kind(glyph) == "rule":
                continue
            centre = glyph.x + glyph.width / 2
            if not (rule.x - 0.6 <= centre <= rule.x + rule.width + 0.6):
                continue
            if glyph.y > rule.y + 0.6:
                above.append(glyph)
            elif glyph.y < rule.y - 0.6:
                below.append(glyph)
            else:
                continue
            consumed.add(id(glyph))
        if not above or not below:
            return None
        numerator = _place(above)
        denominator = _place(below)
        if numerator is None or denominator is None:
            return None
        top = _line(numerator, scale)
        bottom = _line(denominator, scale)
        if not top or not bottom:
            return None
        top = f"({top})" if " " in top else top
        bottom = f"({bottom})" if " " in bottom else bottom
        items.append((rule.x, rule.width, f"{top}/{bottom}", False))

    rest = [glyph for glyph in run if id(glyph) not in consumed]
    if len({round(glyph.y, 1) for glyph in rest if _kind(glyph) == "char"}) > 1:
        # Two rows of plain characters under one clip box are two prompts the
        # conversion happened to bound together. Reading them as one line would
        # state an expression neither row carries.
        return None
    placed = _place(rest)
    if placed is None:
        return None
    items += placed
    items.sort()
    if not items:
        return None
    # A gap wider than a quad inside one expression is something the guide drew
    # and this reader did not read: an empty answer box, a shape, a picture of a
    # quantity. Writing what stands either side of it would state "3 + = 8" for
    # a prompt that says "3 + ☐ = 8".
    for (x, width, _text, _op), (next_x, *_rest) in zip(items, items[1:]):
        if next_x - (x + width) > 0.9 * run[0].scale * 1000:
            return None
    return items


def run_text(items: list[tuple], scale: float) -> str:
    """The run as one string, for reading and for checking a decode."""
    return _line(items, scale)


# --------------------------------------------------------------------- re-extract

# Helvetica advance widths in thousandths of an em. The overlay is written in a
# base-14 font so the PDF stays self-contained; a character outside this table
# refuses its run rather than being written at a guessed width.
WIDTH = {" ": 278, "(": 333, ")": 333, "+": 584, ",": 278, "-": 333, ".": 278,
         "/": 278, ":": 278, "<": 584, "=": 584, ">": 584, "?": 556, "_": 556,
         "×": 584, "÷": 584, "¢": 556}
WIDTH.update({digit: 556 for digit in "0123456789"})
WIDTH.update(zip("abcdefghijklmnopqrstuvwxyz",
                 (556, 556, 500, 556, 556, 278, 556, 556, 222, 222, 500, 222,
                  833, 556, 556, 556, 556, 333, 500, 278, 556, 500, 722, 500,
                  500, 500)))
WIDTH.update(zip("ABCDEFGHIJKLMNOPQRSTUVWXYZ",
                 (667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556,
                  833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667,
                  667, 611)))

# The recovered text is read by people and by the action-mapping parsers, so a
# typographic minus is written as the hyphen-minus those parsers match.
SUBSTITUTE = {"−": "-", "‐": "-", "–": "-", "—": "-"}


def emit_text(text: str) -> str | None:
    written = "".join(SUBSTITUTE.get(character, character) for character in text)
    return written if all(character in WIDTH for character in written) else None


def _escape(text: str) -> bytes:
    return (text.encode("cp1252")
            .replace(b"\\", b"\\\\").replace(b"(", b"\\(").replace(b")", b"\\)"))


def extract_with_math(source: Path) -> tuple[str, int]:
    """``pdftotext -layout`` over a copy of the guide carrying its expressions
    as invisible text. The copy is temporary; the source directory is read-only.
    """
    import io

    import pypdf
    from pypdf.generic import (ArrayObject, DecodedStreamObject,
                               DictionaryObject, NameObject)

    reader = pypdf.PdfReader(io.BytesIO(source.read_bytes()))
    writer = pypdf.PdfWriter()
    recovered = 0
    for page in reader.pages:
        writer.add_page(page)
        try:
            content = page.get_contents().get_data()
        except Exception:  # noqa: BLE001 - a page with no content stream
            continue
        operations = [b"q BT 3 Tr"]
        baselines = text_baselines(content)
        for run in clip_runs(page_glyphs(content)):
            items = decode_run(run)
            if not items:
                continue
            text = emit_text(run_text(items, run[0].scale))
            if text is None:
                continue
            x0, _y0, x1, _y1 = run[0].clip
            span = max(sum(WIDTH[c] for c in text), 1) / 1000.0
            # The recovered expression claims no more width than the one it
            # replaces, so two of them cannot collide and nothing beside them is
            # pushed along. The ceiling keeps a short expression in a wide box
            # from growing tall enough to overlap the rows above and below it,
            # which makes the layout engine merge them into one.
            size = min((x1 - x0) / span, 9.0)
            operations.append(
                b"/HZM %.2f Tf 1 0 0 1 %.3f %.3f Tm (%s) Tj"
                % (size, x0, snap(run, baselines), _escape(text))
            )
            recovered += 1
        if len(operations) == 1:
            continue
        operations.append(b"ET Q")
        overlay = DecodedStreamObject()
        overlay.set_data(b"\n".join(operations))
        written = writer.pages[-1]
        contents = written.raw_get(NameObject("/Contents"))
        if not isinstance(contents, ArrayObject):
            contents = ArrayObject([contents])
        contents.append(writer._add_object(overlay))
        written[NameObject("/Contents")] = contents
        resources = written[NameObject("/Resources")].get_object()
        if "/Font" not in resources:
            resources[NameObject("/Font")] = DictionaryObject()
        font = DictionaryObject()
        font[NameObject("/Type")] = NameObject("/Font")
        font[NameObject("/Subtype")] = NameObject("/Type1")
        font[NameObject("/BaseFont")] = NameObject("/Helvetica")
        font[NameObject("/Encoding")] = NameObject("/WinAnsiEncoding")
        resources[NameObject("/Font")].get_object()[NameObject("/HZM")] = (
            writer._add_object(font)
        )

    with tempfile.TemporaryDirectory() as directory:
        patched = Path(directory) / "with-math.pdf"
        with patched.open("wb") as handle:
            writer.write(handle)
        body = subprocess.run(["pdftotext", "-layout", str(patched), "-"],
                              check=True, capture_output=True).stdout
    return body.decode("utf-8", errors="replace").rstrip("\n\f"), recovered


# ------------------------------------------------------------------- rewrite pass

def _keeps_every_character(before: str, after: str) -> bool:
    """Whether ``after`` still carries ``before``'s characters, in order.

    Whitespace is ignored because the layout engine re-columns a line once it
    carries more text. Anything else missing means the line lost content, and a
    line that lost content can strand a citation that quotes it.
    """
    wanted = "".join(before.split())
    have = iter("".join(after.split()))
    return all(character in have for character in wanted)


def compare(previous: str, fresh: str) -> tuple[str, list[int], str]:
    old = previous.split("\n")
    new = fresh.split("\n")
    if len(old) != len(new):
        return "line_count_changed", [], f"{len(old)} lines became {len(new)}"
    changed = []
    for index, (before, after) in enumerate(zip(old, new), 1):
        if before == after:
            continue
        if not _keeps_every_character(before, after):
            return "line_lost_characters", [index], f"line {index}: {before.strip()!r}"
        changed.append(index)
    return ("unchanged" if not changed else "recovered"), changed, ""


def lesson_jobs(sources: Path) -> list[tuple[str, str, str]]:
    jobs = []
    for band, directory in BANDS.items():
        for path in sorted((GUIDE_ROOT / band).glob("unit*/lesson*.md")):
            if not re.fullmatch(r"lesson\d+", path.stem):
                continue
            unit = int(path.parent.name.removeprefix("unit"))
            lesson = int(path.stem.removeprefix("lesson"))
            pdf = sources / directory / f"{directory}-{unit}-{lesson}-Lesson-teacher-guide-.pdf"
            code = f"IM-G{GRADE_TOKEN[band]}-U{unit}-L{lesson}"
            jobs.append((code, str(path), str(pdf)))
    return jobs


def run_one(job: tuple[str, str, str]) -> dict:
    """Read one guide. Reading runs pdftotext over a temporary copy, so a
    machine short of file descriptors fails a lesson that would otherwise read.
    Retry, then report the lesson as unread rather than losing the pass to it;
    the rewrite is idempotent, so a later run picks the unread ones up.
    """
    code, markdown, pdf = job
    if code in HELD_BACK:
        return {"lesson": code, "status": "held_back", "detail": HELD_BACK[code]}
    for attempt in range(4):
        try:
            text = Path(markdown).read_text(encoding="utf-8")
            match = FENCE.search(text)
            if match is None:
                return {"lesson": code, "status": "no_raw_extract"}
            if not Path(pdf).is_file():
                return {"lesson": code, "status": "source_absent"}
            fresh, recovered = extract_with_math(Path(pdf))
            status, changed, detail = compare(match.group(2), fresh)
            return {"lesson": code, "path": markdown, "status": status,
                    "runs_recovered": recovered, "lines_changed": len(changed),
                    "detail": detail,
                    "body": fresh if status == "recovered" else None}
        except Exception as failure:  # noqa: BLE001
            if attempt == 3:
                return {"lesson": code, "status": "extract_failed",
                        "detail": f"{type(failure).__name__}: {failure}"[:140]}
            time.sleep(2.0 * (attempt + 1))
    return {"lesson": code, "status": "extract_failed", "detail": "unreached"}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sources", type=Path, default=DEFAULT_SOURCES,
                        help="directory holding the per-lesson teacher-guide PDFs")
    parser.add_argument("--check", action="store_true",
                        help="report what would change and write nothing")
    parser.add_argument("--only", help="a single lesson code, for example IM-G1-U7-L6")
    parser.add_argument("--workers", type=int, default=4)
    parser.add_argument("--report", type=Path,
                        help="write a per-lesson JSON receipt of this pass")
    arguments = parser.parse_args()

    if not arguments.sources.is_dir():
        print(f"teacher-guide PDFs absent at {arguments.sources}; guides left as they are",
              file=sys.stderr)
        return 0

    jobs = lesson_jobs(arguments.sources)
    if arguments.only:
        jobs = [job for job in jobs if job[0] == arguments.only]
        if not jobs:
            print(f"no guide for {arguments.only}", file=sys.stderr)
            return 1

    with ProcessPoolExecutor(arguments.workers) as pool:
        results = list(pool.map(run_one, jobs, chunksize=4))

    counts = Counter(result["status"] for result in results)
    written = 0
    for result in results:
        if result["status"] != "recovered" or arguments.check:
            continue
        path = Path(result["path"])
        text = path.read_text(encoding="utf-8")
        match = FENCE.search(text)
        path.write_text(
            text[:match.start()] + match.group(1) + result["body"] + match.group(3)
            + text[match.end():],
            encoding="utf-8",
        )
        written += 1

    refused = [r["lesson"] for r in results
               if r["status"] in ("line_count_changed", "line_lost_characters")]
    print(
        f"teacher guides read: {len(results)}; "
        f"expressions restored in {counts['recovered']} guides "
        f"({sum(r['lines_changed'] for r in results if r['status'] == 'recovered')} lines, "
        f"{sum(r.get('runs_recovered', 0) for r in results)} runs); "
        f"already current: {counts['unchanged']}; "
        f"held back: {counts['held_back']}; "
        f"refused: {len(refused)}; "
        f"unread: {counts['extract_failed']}; "
        f"sources absent: {counts['source_absent']}"
        + ("" if arguments.check else f"; written: {written}")
    )
    if arguments.report:
        arguments.report.write_text(
            json.dumps([{k: v for k, v in r.items() if k != "body"}
                        for r in results], indent=1) + "\n", encoding="utf-8")
    for result in results:
        if result["status"] in ("line_count_changed", "line_lost_characters"):
            print(f"  refused, re-extraction was not additive: {result['lesson']}"
                  f" ({result['status']}; {result.get('detail', '')})", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
