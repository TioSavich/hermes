#!/usr/bin/env python3
"""Decide, per vision-harvest task event, whether its excerpt occurs in the guide it cites.

The two vision harvests in scripts/curriculum/vision_harvest/ carry one
`excerpt` per task event. `ingest_vision.py` turns those excerpts into
executable facts for the Opus-verified G6-7 harvest only; the broader G6-8
harvest extends the same file with 304 further lessons that nothing has
checked but the pass that wrote them. This script scores every excerpt in
both harvests against Illustrative Mathematics' own per-lesson teacher guide
PDFs and records a typed verdict for each event.

The quotation rule is the one `build_lesson_evidence._fragment_present`
already applies to negative receipts: normalize away the wrapping and compare
verbatim. Teacher guides are hard-wrapped and PDF extraction re-wraps them
again, so a rule anchored on a single line refuses true quotations. Here the
normalization goes one step further than the receipt gate: punctuation and
case are folded too, because pypdf drops the space in "students touse" and
re-hyphenates across page breaks. Fabricated text survives none of that; it
is absent from the guide under every normalization.

The verdict vocabulary comes from what the data turned out to contain, and
each class is its own outcome rather than a shared refusal.

The PDF text layer does not carry mathematical expressions. IM renders them
as images, so "There are 542 people in total, because (20 · 25) + 42 = 500 +
42 = 542" reaches pypdf as "There are 542 people in total, because ." An
excerpt whose prose is present and whose equation is not was read correctly
from a page the text layer cannot reproduce.

Many excerpts describe a page rather than quote it. A table's cells come back
as "Total entrance cost for 2 people: $6 vehicle + $4 people", which no guide
contains as a sentence and which uses only that guide's words. Refusing those
as absent would report the reader as inventing what it was in fact reading
off a figure, so a recomposed sentence and a paraphrase each carry their own
verdict, and the artifact records how long the excerpt's longest verbatim run
is and how many of its content words the cited lesson supplies.

Some lessons carry another lesson's content. The harvest's own titles say so
in places ("PDF contains only the Unit 2 practice-problem tail"), and
elsewhere they do not. An excerpt found in a sibling lesson of the same unit
is a misattribution, not an invention.

77 of the 152 grade-6 guides are offloaded to cloud storage (macOS
SF_DATALESS). Their bytes cannot be read here, so their events are recorded
as unscored rather than counted either way.

Read-only against the curriculum tree. Resumable per lesson. The durable
artifact lands in data/research/; checkpoints and extracted text stay in the
gitignored run directory.
"""

from __future__ import annotations

import argparse
import collections
import errno
import hashlib
import json
import os
import re
import sys
import time
import unicodedata
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
HARVEST_DIR = ROOT / "scripts" / "curriculum" / "vision_harvest"
OPUS_HARVEST = HARVEST_DIR / "im_g6g7_vision_harvest.json"
BROAD_HARVEST = HARVEST_DIR / "im_g6_8_vision_harvest.json"
SPINE = ROOT / "data" / "learningcommons" / "derived" / "im_k8_spine.json"
GUIDE_ROOT = Path("/Users/tio/Documents/GitHub/Prolog/IM-Curriculum/TeacherLessonGuides")
DEFAULT_OUTPUT = ROOT / "scripts" / "research" / "vision_excerpt_verification_out"
DEFAULT_ARTIFACT = ROOT / "data" / "research" / "vision_excerpt_verification.json"

LESSON_RE = re.compile(r"IM-G([1-8])-U(\d+)-L(\d+)")
SCORED_GRADES = ("6", "7", "8")

# macOS marks a cloud-offloaded file SF_DATALESS. Reading one blocks on a
# fetch that does not complete here, so the flag is checked before any open.
SF_DATALESS = 0x40000000

# A guide whose extraction yields less than this many normalized characters
# has no usable text layer; scoring against it would refuse every excerpt for
# a reason that says nothing about the excerpt.
TEXT_LAYER_FLOOR = 500

# An anchor shorter than this matches too much of any guide to establish
# anything. Twelve normalized characters is roughly three words.
ANCHOR_MIN_CHARS = 12

# An excerpt whose sentences the guide does not carry, but half of whose
# characters sit in one contiguous run of the guide's text, was rebuilt from
# the page rather than invented. Both bounds have to hold: half of a short
# excerpt is still short enough to match by accident.
RECOMPOSITION_MIN_CHARS = 40
RECOMPOSITION_MIN_RATIO = 0.5

# Words too common to say anything about which page an excerpt came from.
CONTENT_STOPWORDS = frozenset(
    """a an and are as at be been by can could each five for four from how in
    is it its many more most much of on one or our problem response show shows
    solution student students teacher that the their them they this three to
    two was were what which will with would you your activity answer lesson""".split()
)
CONTENT_TOKEN = re.compile(r"[a-z]{4,}")

_PUNCTUATION_FOLD = {
    "‘": "'", "’": "'", "“": '"', "”": '"',
    "′": "'", "″": '"',
    "‐": "-", "‑": "-", "‒": "-", "–": "-",
    "—": "-", "−": "-",
    " ": " ",
}

SENTENCE_BREAK = re.compile(r"(?<=[.!?])\s+")
ELISION = re.compile(r"\.\.\.|…")
# The readers describe a figure in square brackets — "[16 over two segments
# of 8]", "[diagram] 10 cups over four boxes" — which is a note about the
# page rather than a claim about its words.
ANNOTATION = re.compile(r"\[[^\]]{0,80}\]")
SYMBOL_RUN = re.compile(r"[0-9()\[\]{}·×÷+\-*/=<>≤≥%$,.:;\s_¼½¾⁄^']{3,}")
OPERATOR = re.compile(r"[=+·×÷*/^_]|\d\s*[/:]\s*\d")

VERDICT_VOCABULARY = {
    "verified_against_source": (
        "the whole excerpt occurs in the cited lesson's teacher guide once "
        "Unicode, whitespace, case, and punctuation are normalized"
    ),
    "verified_modulo_unextractable_span": (
        "every prose anchor of the excerpt occurs in the cited lesson; the "
        "unmatched remainder is an equation or an elision the PDF text layer "
        "does not carry"
    ),
    "excerpt_partially_present": (
        "at least one prose anchor occurs in the cited lesson and at least "
        "one does not, so the excerpt joins guide text to material the guide "
        "text does not supply"
    ),
    "excerpt_recomposed_from_lesson_text": (
        "no whole sentence of the excerpt occurs in the cited lesson, but at "
        "least forty characters and at least half the excerpt sit in one "
        "contiguous run of that lesson's text: the reader rebuilt the "
        "sentence from the page it cites"
    ),
    "verified_in_sibling_lesson_of_unit": (
        "no anchor occurs in the cited lesson, and every anchor occurs in "
        "another lesson of the same unit: the quotation is real and the "
        "lesson attribution is wrong"
    ),
    "verified_elsewhere_in_corpus": (
        "every anchor occurs in a readable guide outside the cited unit"
    ),
    "excerpt_paraphrases_cited_lesson": (
        "no sentence of the excerpt occurs anywhere in the corpus, and yet "
        "every content word of it occurs in the cited lesson: the reader "
        "described that page in its own words, most often a table or a "
        "diagram whose cells the text layer does not carry"
    ),
    "excerpt_absent_from_corpus": (
        "no anchor occurs in any readable grade 6-8 teacher guide, and the "
        "cited lesson does not even supply the excerpt's content words"
    ),
    "no_prose_anchor_in_excerpt": (
        "the excerpt carries no run of twelve normalized characters outside "
        "its equations, so the text layer cannot test it either way"
    ),
    "excerpt_empty": "the event carries no excerpt",
    "lesson_absent_from_curriculum": (
        "the harvest names a lesson id that is in neither the IM spine nor "
        "the guide tree"
    ),
    "source_pdf_missing": (
        "the lesson is in the spine but no per-lesson teacher guide PDF "
        "exists for it"
    ),
    "source_pdf_dataless": (
        "the guide PDF is offloaded to cloud storage and its bytes are not "
        "readable in this pass"
    ),
    "pdf_text_layer_absent": (
        "the guide PDF extracts to less than the text-layer floor"
    ),
}

SOURCE_VERDICTS = {
    "lesson_absent_from_curriculum",
    "source_pdf_missing",
    "source_pdf_dataless",
    "pdf_text_layer_absent",
}

VERIFIED_IN_CITED_LESSON = {
    "verified_against_source",
    "verified_modulo_unextractable_span",
}

# A weaker standing than verification and a stronger one than refusal: the
# excerpt is tied to the page it cites, by a partial quotation, a recomposed
# sentence, or a description that uses only that page's words.
GROUNDED_IN_CITED_LESSON = VERIFIED_IN_CITED_LESSON | {
    "excerpt_partially_present",
    "excerpt_recomposed_from_lesson_text",
    "excerpt_paraphrases_cited_lesson",
}


def normalize(text: str) -> str:
    """Fold Unicode variants and collapse the wrapping."""
    folded = unicodedata.normalize("NFKC", text)
    for source, target in _PUNCTUATION_FOLD.items():
        folded = folded.replace(source, target)
    return re.sub(r"\s+", " ", folded).strip()


def compare_form(text: str) -> str:
    """The form both sides are compared in: alphanumerics, lowercased.

    Dropping punctuation and case is what lets a quotation survive pypdf's
    lost inter-word spaces and the hyphens it leaves at page breaks. It does
    not let invented text through: the alphanumeric sequence still has to be
    in the guide.
    """
    return re.sub(r"[^a-z0-9]", "", normalize(text).lower())


def is_symbolic(span: str) -> bool:
    """Whether a span is an equation rather than prose."""
    return not re.search(r"[A-Za-z]", span) and bool(OPERATOR.search(span))


def content_word_recall(excerpt: str, document: str) -> float | None:
    """The share of the excerpt's content words the document carries.

    A description is not a quotation, and refusing it as absent would say the
    reader invented the page. Full recall against the lesson an excerpt cites
    is common among excerpts no verbatim test matches, and roughly fourteen
    times rarer against a lesson from another grade, which is what the
    negative_control block of the artifact measures on each run. The measure
    separates a paraphrase of the cited page from text with no relation to
    it.
    """
    tokens = {
        token
        for token in CONTENT_TOKEN.findall(normalize(excerpt).lower())
        if token not in CONTENT_STOPWORDS
    }
    if not tokens:
        return None
    return sum(token in document for token in tokens) / len(tokens)


def longest_run(excerpt: str, document: str) -> int:
    """The longest contiguous piece of the excerpt the document carries.

    The readers recompose: a guide's "c. How much would 1,000 raffle tickets
    cost" comes back as "How much would 1,000 raffle tickets cost at $4 per
    ticket?", with the price carried in from part a's answer. A verdict alone
    would put that with invented text; the length of the longest run says how
    much of the excerpt the page actually supplies.
    """
    folded = compare_form(excerpt)
    best = 0
    for start in range(len(folded)):
        if len(folded) - start <= best:
            break
        low, high = best, len(folded) - start
        while low < high:
            middle = (low + high + 1) // 2
            if folded[start:start + middle] in document:
                low = middle
            else:
                high = middle - 1
        best = max(best, low)
    return best


def prose_anchors(excerpt: str) -> list[str]:
    """The excerpt's testable spans: sentences with their equations removed."""
    spans: list[str] = []
    for chunk in ELISION.split(ANNOTATION.sub(" ", excerpt)):
        for sentence in SENTENCE_BREAK.split(chunk):
            cursor = 0
            pieces: list[str] = []
            for match in SYMBOL_RUN.finditer(sentence):
                if is_symbolic(match.group(0)):
                    pieces.append(sentence[cursor:match.start()])
                    cursor = match.end()
            pieces.append(sentence[cursor:])
            spans.extend(pieces)
    return [
        span.strip()
        for span in spans
        if len(compare_form(span)) >= ANCHOR_MIN_CHARS
    ]


def guide_relative(code: str) -> str | None:
    match = LESSON_RE.fullmatch(code)
    if match is None:
        return None
    grade, unit, lesson = match.groups()
    return f"Grade{grade}/Grade{grade}-{unit}-{lesson}-Lesson-teacher-guide-.pdf"


def guide_path(code: str) -> Path | None:
    relative = guide_relative(code)
    return None if relative is None else GUIDE_ROOT / relative


def source_status(code: str, spine_codes: set[str]) -> str | None:
    """A refusal that belongs to the source rather than to any excerpt."""
    path = guide_path(code)
    if path is None or not path.is_file():
        if code not in spine_codes:
            return "lesson_absent_from_curriculum"
        return "source_pdf_missing"
    if os.stat(path).st_flags & SF_DATALESS:
        return "source_pdf_dataless"
    return None


def extract_guide_text(path: Path) -> str:
    """The guide's text layer, with the file handle released before returning.

    pypdf holds its stream open for lazy page reads, and 352 live readers
    exhaust the process file-descriptor limit partway through a full pass.
    Reading the bytes first keeps exactly one descriptor open at a time.
    """
    import io

    from pypdf import PdfReader

    with open(path, "rb") as handle:
        payload = handle.read()
    reader = PdfReader(io.BytesIO(payload))
    try:
        return "\n".join(page.extract_text() or "" for page in reader.pages)
    finally:
        reader.close()


class GuideCorpus:
    """Every readable grade 6-8 guide, in compare form, cached on disk.

    Extraction takes about 45 seconds cold over 352 guides and about a second
    warm, so a rerun costs nothing and the cache makes the scoring pass
    resumable without re-reading the curriculum tree.
    """

    def __init__(self, cache_dir: Path) -> None:
        self.cache_dir = cache_dir
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.text: dict[str, str] = {}
        self.dataless: list[str] = []
        self.extracted = 0
        self.reused = 0

    def build(self, *, refresh: bool = False) -> None:
        for grade in SCORED_GRADES:
            directory = GUIDE_ROOT / f"Grade{grade}"
            if not directory.is_dir():
                continue
            for name in sorted(os.listdir(directory)):
                if not name.endswith(".pdf"):
                    continue
                relative = f"Grade{grade}/{name}"
                path = directory / name
                if os.stat(path).st_flags & SF_DATALESS:
                    self.dataless.append(relative)
                    continue
                cached = self.cache_dir / f"Grade{grade}" / f"{name}.txt"
                if cached.is_file() and not refresh:
                    self.text[relative] = cached.read_text(encoding="utf-8")
                    self.reused += 1
                    continue
                folded = compare_form(extract_guide_text(path))
                cached.parent.mkdir(parents=True, exist_ok=True)
                cached.write_text(folded, encoding="utf-8")
                self.text[relative] = folded
                self.extracted += 1

    def lesson_text(self, code: str) -> str | None:
        relative = guide_relative(code)
        return None if relative is None else self.text.get(relative)

    def unit_siblings(self, code: str) -> list[str]:
        match = LESSON_RE.fullmatch(code)
        if match is None:
            return []
        grade, unit, _ = match.groups()
        prefix = f"Grade{grade}/Grade{grade}-{unit}-"
        own = guide_relative(code)
        return sorted(
            relative
            for relative in self.text
            if relative.startswith(prefix) and relative != own
        )

    def outside_unit(self, code: str) -> list[str]:
        match = LESSON_RE.fullmatch(code)
        prefix = "" if match is None else f"Grade{match.group(1)}/Grade{match.group(1)}-{match.group(2)}-"
        return sorted(
            relative
            for relative in self.text
            if not prefix or not relative.startswith(prefix)
        )


def first_source_holding_all(
    anchors: list[str], candidates: list[str], corpus: GuideCorpus
) -> str | None:
    folded = [compare_form(anchor) for anchor in anchors]
    for relative in candidates:
        document = corpus.text[relative]
        if all(anchor in document for anchor in folded):
            return relative
    return None


def score_event(
    excerpt: str, code: str, corpus: GuideCorpus
) -> dict[str, Any]:
    """One event's typed verdict, with the scope the excerpt was found in."""
    document = corpus.lesson_text(code)
    if document is None:
        raise RuntimeError(f"no cached guide text for {code}")
    if not excerpt.strip():
        return {"verdict": "excerpt_empty", "anchors": 0, "anchors_present": 0}
    folded = compare_form(excerpt)
    run = longest_run(excerpt, document)
    recall = content_word_recall(excerpt, document)
    measured = {
        "longest_run_chars": run,
        "longest_run_ratio": round(run / len(folded), 3) if folded else 0.0,
        "content_word_recall": None if recall is None else round(recall, 3),
    }
    if folded in document:
        return {
            "verdict": "verified_against_source",
            "scope": "cited_lesson",
            "matched_source": guide_relative(code),
            "anchors": 1,
            "anchors_present": 1,
            **measured,
        }
    anchors = prose_anchors(excerpt)
    if not anchors:
        return {
            "verdict": "no_prose_anchor_in_excerpt",
            "anchors": 0,
            "anchors_present": 0,
            **measured,
        }
    present = [
        anchor for anchor in anchors if compare_form(anchor) in document
    ]
    if len(present) == len(anchors):
        return {
            "verdict": "verified_modulo_unextractable_span",
            "scope": "cited_lesson",
            "matched_source": guide_relative(code),
            "anchors": len(anchors),
            "anchors_present": len(present),
            **measured,
        }
    if present:
        return {
            "verdict": "excerpt_partially_present",
            "scope": "cited_lesson",
            "matched_source": guide_relative(code),
            "anchors": len(anchors),
            "anchors_present": len(present),
            **measured,
        }
    if run >= RECOMPOSITION_MIN_CHARS and run >= RECOMPOSITION_MIN_RATIO * len(folded):
        return {
            "verdict": "excerpt_recomposed_from_lesson_text",
            "scope": "cited_lesson",
            "matched_source": guide_relative(code),
            "anchors": len(anchors),
            "anchors_present": 0,
            **measured,
        }
    sibling = first_source_holding_all(anchors, corpus.unit_siblings(code), corpus)
    if sibling is not None:
        return {
            "verdict": "verified_in_sibling_lesson_of_unit",
            "scope": "sibling_lesson",
            "matched_source": sibling,
            "anchors": len(anchors),
            "anchors_present": 0,
            **measured,
        }
    elsewhere = first_source_holding_all(anchors, corpus.outside_unit(code), corpus)
    if elsewhere is not None:
        return {
            "verdict": "verified_elsewhere_in_corpus",
            "scope": "other_unit",
            "matched_source": elsewhere,
            "anchors": len(anchors),
            "anchors_present": 0,
            **measured,
        }
    if recall is not None and recall >= 1.0:
        return {
            "verdict": "excerpt_paraphrases_cited_lesson",
            "scope": "cited_lesson",
            "matched_source": guide_relative(code),
            "anchors": len(anchors),
            "anchors_present": 0,
            **measured,
        }
    return {
        "verdict": "excerpt_absent_from_corpus",
        "anchors": len(anchors),
        "anchors_present": 0,
        **measured,
    }


def decoy_lesson(code: str, event_index: int, corpus: GuideCorpus) -> str | None:
    """A guide the excerpt does not claim to come from, chosen reproducibly.

    Scoring each excerpt against an unrelated lesson is the control on the
    control: a pass that admits real quotations is only worth reading if it
    refuses the same text against a guide that never carried it.
    """
    match = LESSON_RE.fullmatch(code)
    own_grade = match.group(1) if match else ""
    candidates = sorted(
        relative
        for relative in corpus.text
        if not relative.startswith(f"Grade{own_grade}/")
    )
    if not candidates:
        return None
    digest = hashlib.sha256(f"{code}#{event_index}".encode("utf-8")).hexdigest()
    return candidates[int(digest[:8], 16) % len(candidates)]


def page_span(value: Any) -> tuple[int, int] | None:
    text = str(value or "").strip()
    match = re.fullmatch(r"(\d+)\s*-\s*(\d+)", text)
    if match:
        return int(match.group(1)), int(match.group(2))
    if re.fullmatch(r"\d+", text):
        return int(text), int(text)
    return None


def pages_corroborate(event_pages: Any, lesson_range: Any) -> bool | None:
    event = page_span(event_pages)
    lesson = page_span(lesson_range)
    if event is None or lesson is None:
        return None
    return event[0] <= lesson[1] and lesson[0] <= event[1]


def load_harvests() -> tuple[list[dict], list[dict], set[str]]:
    opus = json.loads(OPUS_HARVEST.read_text(encoding="utf-8"))
    broad = json.loads(BROAD_HARVEST.read_text(encoding="utf-8"))
    opus_codes = {row["code"] for row in opus}
    return opus, broad, opus_codes


def cohort_rows(cohort: str) -> list[dict]:
    opus, broad, opus_codes = load_harvests()
    if cohort == "opus_verified":
        return opus
    return [row for row in broad if row["code"] not in opus_codes]


def atomic_write_json(path: Path, payload: Any) -> None:
    """Write a checkpoint, waiting out a saturated system file table.

    A full pass writes about five hundred small files. When the machine's
    kernel file table is near its ceiling the open fails with ENFILE, which
    is transient and has nothing to do with this run; losing an otherwise
    complete pass to it costs more than a short wait.
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    body = json.dumps(payload, indent=2, ensure_ascii=False) + "\n"
    for attempt in range(6):
        try:
            temporary.write_text(body, encoding="utf-8")
            temporary.replace(path)
            return
        except OSError as exc:
            if exc.errno not in (errno.ENFILE, errno.EMFILE) or attempt == 5:
                raise
            time.sleep(2 ** attempt)


def spine_index() -> dict[str, dict]:
    return {
        row["repo_id"]: row
        for row in json.loads(SPINE.read_text(encoding="utf-8"))
    }


def mapping_census(spine: dict[str, dict]) -> dict[str, Any]:
    """The filename-to-lesson-id mapping, checked rather than assumed."""
    census: dict[str, Any] = {}
    for grade in SCORED_GRADES:
        directory = GUIDE_ROOT / f"Grade{grade}"
        files = (
            {name for name in os.listdir(directory) if name.endswith(".pdf")}
            if directory.is_dir()
            else set()
        )
        codes = [code for code, row in spine.items() if row["grade"] == grade]
        expected = {Path(guide_relative(code)).name for code in codes}
        census[f"grade_{grade}"] = {
            "spine_lessons": len(codes),
            "guide_pdfs": len(files),
            "spine_lessons_with_guide": len(expected & files),
            "guides_without_spine_lesson": sorted(files - expected),
            "dataless_guides": sum(
                bool(os.stat(directory / name).st_flags & SF_DATALESS)
                for name in sorted(files)
            ),
        }
    return census


def lesson_record(
    row: dict,
    cohort: str,
    spine: dict[str, dict],
    corpus: GuideCorpus,
    *,
    negative_control: bool,
) -> dict[str, Any]:
    code = row["code"]
    status = source_status(code, set(spine))
    document = corpus.lesson_text(code)
    if status is None and (document is None or len(document) < TEXT_LAYER_FLOOR):
        status = "pdf_text_layer_absent"
    spine_row = spine.get(code)
    record: dict[str, Any] = {
        "lesson": code,
        "cohort": cohort,
        "grade": str(row.get("grade", "")),
        "unit": row.get("unit"),
        "harvest_title": row.get("title"),
        "spine_name": spine_row["name"] if spine_row else None,
        "title_matches_spine": (
            None
            if spine_row is None
            else compare_form(row.get("title") or "") == compare_form(spine_row["name"])
        ),
        "guide": guide_relative(code),
        "source_status": status,
        "pages_range": row.get("pages_range"),
        "events": [],
    }
    for index, event in enumerate(row.get("task_events", [])):
        excerpt = (event.get("excerpt") or "").strip()
        entry: dict[str, Any] = {
            "index": index,
            "task": event.get("task"),
            "position": event.get("position"),
            "pages": event.get("pages"),
            "figure_bound": bool(event.get("figure_bound")),
            "excerpt_chars": len(excerpt),
            "excerpt": excerpt[:240],
            # ingest_vision.py stores excerpt[:200] on the instance it emits,
            # so this digest joins an applied instance back to its event
            # without depending on row order in a harvest that repeats lesson
            # ids across page spans.
            "excerpt_head_sha256": hashlib.sha256(
                excerpt[:200].encode("utf-8")
            ).hexdigest(),
            "pages_within_lesson_range": pages_corroborate(
                event.get("pages"), row.get("pages_range")
            ),
        }
        if status is not None:
            entry["verdict"] = status
            entry["anchors"] = len(prose_anchors(excerpt))
            entry["anchors_present"] = 0
        else:
            entry.update(score_event(excerpt, code, corpus))
            if negative_control:
                decoy = decoy_lesson(code, index, corpus)
                entry["decoy_guide"] = decoy
                entry["decoy_verdict"] = (
                    None if decoy is None else decoy_verdict(excerpt, decoy, corpus)
                )
        record["events"].append(entry)
    return record


def decoy_verdict(excerpt: str, decoy: str, corpus: GuideCorpus) -> str:
    """The same ladder, run against a guide the excerpt never claimed.

    Only the two corpus-wide scopes are dropped, since a decoy has no unit to
    be a sibling of. Everything an excerpt can earn against the lesson it
    cites, it is offered the chance to earn here.
    """
    document = corpus.text[decoy]
    if not excerpt.strip():
        return "excerpt_empty"
    folded = compare_form(excerpt)
    if folded in document:
        return "verified_against_source"
    anchors = prose_anchors(excerpt)
    if not anchors:
        return "no_prose_anchor_in_excerpt"
    present = [a for a in anchors if compare_form(a) in document]
    if len(present) == len(anchors):
        return "verified_modulo_unextractable_span"
    if present:
        return "excerpt_partially_present"
    run = longest_run(excerpt, document)
    if run >= RECOMPOSITION_MIN_CHARS and run >= RECOMPOSITION_MIN_RATIO * len(folded):
        return "excerpt_recomposed_from_lesson_text"
    recall = content_word_recall(excerpt, document)
    if recall is not None and recall >= 1.0:
        return "excerpt_paraphrases_cited_lesson"
    return "excerpt_absent_from_corpus"


RULES = ROOT / "scripts" / "curriculum" / "action_mapping_rules.json"
UNIT_GUIDE_FILE = re.compile(r"Grade\d+-\d+-Unit-teacher-guide-\.pdf")
INSTANCE_ID = re.compile(r"^im_g\d+_u\d+_l\d+_(add|subtract|multiply|divide)_(\d+)(_x)?$")


def executable_subset(records: list[dict[str, Any]]) -> dict[str, Any]:
    """How the events `ingest_vision.py` already made executable score here.

    This is the control the number needs. The verdicts below cover every
    excerpt in the harvest, most of which no pipeline stage ever admits;
    `ingest_vision.py` admits a narrow slice, the Tier-1 whole-number events
    with a registry-valid kind, and those reached
    `action_mapping_rules.json` as e343_pdf reviewed task instances. Joining
    on that file measures the standard the applied slice already meets. A
    pass that refused most of it would be refusing work the repo has
    accepted, and would be the thing at fault.
    """
    by_key: dict[tuple[str, int, str], dict[str, Any]] = {}
    for record in records:
        if record["cohort"] != "opus_verified":
            continue
        for event in record["events"]:
            key = (record["lesson"], event["index"], event["excerpt_head_sha256"])
            by_key.setdefault(key, event)
    rules = json.loads(RULES.read_text(encoding="utf-8"))
    verdicts: collections.Counter[str] = collections.Counter()
    by_grade: dict[str, collections.Counter[str]] = collections.defaultdict(
        collections.Counter
    )
    unjoined = 0
    for instance in rules.get("reviewed_task_instances", []):
        source = (instance.get("source") or {}).get("e343_pdf") or {}
        if not UNIT_GUIDE_FILE.fullmatch(str(source.get("file", ""))):
            continue
        match = INSTANCE_ID.fullmatch(instance["id"])
        if match is None:
            unjoined += 1
            continue
        index = int(match.group(2))
        code = instance["code"]
        digest = hashlib.sha256(
            (instance.get("excerpt") or "").encode("utf-8")
        ).hexdigest()
        chosen = by_key.get((code, index, digest))
        if chosen is None:
            unjoined += 1
            continue
        verdicts[chosen["verdict"]] += 1
        by_grade[code.split("-")[1]][chosen["verdict"]] += 1
    scored = sum(
        count for verdict, count in verdicts.items() if verdict not in SOURCE_VERDICTS
    )
    verified = sum(
        count for verdict, count in verdicts.items() if verdict in VERIFIED_IN_CITED_LESSON
    )
    grounded = sum(
        count for verdict, count in verdicts.items() if verdict in GROUNDED_IN_CITED_LESSON
    )
    return {
        "definition": (
            "e343_pdf reviewed task instances in action_mapping_rules.json "
            "whose source file is a vision-harvest unit guide"
        ),
        "instances": sum(verdicts.values()),
        "unjoined": unjoined,
        "scored": scored,
        "verified_in_cited_lesson": verified,
        "grounded_in_cited_lesson": grounded,
        "verification_rate": {
            "numerator": verified,
            "denominator": scored,
            "value": verified / scored if scored else 0.0,
        },
        "grounding_rate": {
            "numerator": grounded,
            "denominator": scored,
            "value": grounded / scored if scored else 0.0,
        },
        "verdicts": dict(verdicts.most_common()),
        "by_grade": {
            grade: dict(counter.most_common()) for grade, counter in sorted(by_grade.items())
        },
    }


INGEST = ROOT / "scripts" / "curriculum" / "ingest_vision.py"


def load_ingest_filter():
    """`ingest_vision.tier1_task`, imported rather than restated.

    The comparison below only means something if it uses the same admission
    test the ingest uses. Loading the module by path keeps one definition of
    that test; the module does nothing at import beyond binding constants.
    """
    import importlib.util

    spec = importlib.util.spec_from_file_location("hermes_ingest_vision", INGEST)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot import {INGEST}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.tier1_task


def tier1_subset(records: list[dict[str, Any]], harvest_events) -> dict[str, Any]:
    """How each cohort scores on the events `ingest_vision.py` could admit.

    Its lane 2 keeps a task event when the task parses as whole-number Tier-1
    arithmetic and the excerpt is non-empty. That filter, unlike the harvest
    as a whole, is the population the two cohorts should be compared on: the
    Opus rate over it is the standard the applied facts already meet, and the
    Haiku-only rate over it is what admitting them would add.
    """
    tier1 = load_ingest_filter()
    blocks: dict[str, Any] = {}
    for cohort in sorted({record["cohort"] for record in records}):
        counts: dict[str, collections.Counter[str]] = collections.defaultdict(
            collections.Counter
        )
        for record in records:
            if record["cohort"] != cohort:
                continue
            events = harvest_events(record)
            for entry in record["events"]:
                raw = events[entry["index"]]
                form, _ = tier1(raw.get("task", ""))
                if not form or not (raw.get("excerpt") or "").strip():
                    continue
                counts[record["grade"]][entry["verdict"]] += 1
        grades: dict[str, Any] = {}
        for grade, counter in sorted(counts.items()):
            scored = sum(
                count for verdict, count in counter.items() if verdict not in SOURCE_VERDICTS
            )
            verified = sum(
                count
                for verdict, count in counter.items()
                if verdict in VERIFIED_IN_CITED_LESSON
            )
            grounded = sum(
                count
                for verdict, count in counter.items()
                if verdict in GROUNDED_IN_CITED_LESSON
            )
            grades[grade] = {
                "tier1_events": sum(counter.values()),
                "scored": scored,
                "verified_in_cited_lesson": verified,
                "grounded_in_cited_lesson": grounded,
                "verification_rate": verified / scored if scored else 0.0,
                "grounding_rate": grounded / scored if scored else 0.0,
                "verdicts": dict(counter.most_common()),
            }
        blocks[cohort] = {
            "tier1_events": sum(block["tier1_events"] for block in grades.values()),
            "scored": sum(block["scored"] for block in grades.values()),
            "verified_in_cited_lesson": sum(
                block["verified_in_cited_lesson"] for block in grades.values()
            ),
            "grounded_in_cited_lesson": sum(
                block["grounded_in_cited_lesson"] for block in grades.values()
            ),
            "by_grade": grades,
        }
    return {
        "definition": (
            "task events whose task parses under ingest_vision.tier1_task and "
            "whose excerpt is non-empty, which is lane 2's admission test"
        ),
        "by_cohort_and_grade": blocks,
    }


def summarize(records: list[dict[str, Any]]) -> dict[str, Any]:
    events = [
        (record, event) for record in records for event in record["events"]
    ]
    by_verdict = collections.Counter(event["verdict"] for _, event in events)
    by_cohort_grade: dict[str, dict[str, Any]] = {}
    for cohort in sorted({record["cohort"] for record in records}):
        grades: dict[str, Any] = {}
        for grade in SCORED_GRADES:
            slice_ = [
                (record, event)
                for record, event in events
                if record["cohort"] == cohort and record["grade"] == grade
            ]
            if not slice_:
                continue
            scored = [
                (record, event)
                for record, event in slice_
                if event["verdict"] not in SOURCE_VERDICTS
            ]
            verified = [
                pair for pair in scored if pair[1]["verdict"] in VERIFIED_IN_CITED_LESSON
            ]
            grounded = [
                pair for pair in scored if pair[1]["verdict"] in GROUNDED_IN_CITED_LESSON
            ]
            grades[grade] = {
                "events": len(slice_),
                "unscored": len(slice_) - len(scored),
                "scored": len(scored),
                "verified_in_cited_lesson": len(verified),
                "grounded_in_cited_lesson": len(grounded),
                "grounding_rate": {
                    "numerator": len(grounded),
                    "denominator": len(scored),
                    "value": len(grounded) / len(scored) if scored else 0.0,
                    "denominator_definition": (
                        "events whose cited guide could be read in this pass"
                    ),
                },
                "verification_rate": {
                    "numerator": len(verified),
                    "denominator": len(scored),
                    "value": len(verified) / len(scored) if scored else 0.0,
                    "denominator_definition": (
                        "events whose cited guide could be read in this pass"
                    ),
                },
                "verdicts": dict(
                    collections.Counter(
                        event["verdict"] for _, event in slice_
                    ).most_common()
                ),
                "by_figure_bound": {
                    str(flag): {
                        "scored": len(
                            [p for p in scored if p[1]["figure_bound"] is flag]
                        ),
                        "verified_in_cited_lesson": len(
                            [p for p in verified if p[1]["figure_bound"] is flag]
                        ),
                        "grounded_in_cited_lesson": len(
                            [p for p in grounded if p[1]["figure_bound"] is flag]
                        ),
                    }
                    for flag in (True, False)
                },
            }
        by_cohort_grade[cohort] = grades
    decoys = [
        event for _, event in events if event.get("decoy_verdict") is not None
    ]
    negative = {
        "scored": len(decoys),
        "verdicts": dict(
            collections.Counter(event["decoy_verdict"] for event in decoys).most_common()
        ),
        "verified_against_a_guide_it_does_not_cite": sum(
            event["decoy_verdict"] in VERIFIED_IN_CITED_LESSON for event in decoys
        ),
        "grounded_against_a_guide_it_does_not_cite": sum(
            event["decoy_verdict"] in GROUNDED_IN_CITED_LESSON for event in decoys
        ),
    }
    corroborated = [
        event
        for _, event in events
        if event.get("pages_within_lesson_range") is not None
    ]
    return {
        "events": len(events),
        "lessons": len(records),
        "verdicts": dict(by_verdict.most_common()),
        "by_cohort_and_grade": by_cohort_grade,
        "negative_control": negative,
        "pages_corroboration": {
            "checkable": len(corroborated),
            "event_pages_inside_lesson_page_range": sum(
                event["pages_within_lesson_range"] for event in corroborated
            ),
        },
    }


def print_summary(summary: dict[str, Any]) -> None:
    print(f"Events scored: {summary['events']} across {summary['lessons']} lessons")
    print("Verdicts:")
    for verdict, count in summary["verdicts"].items():
        share = 100 * count / summary["events"]
        print(f"  {count:5d}  {share:5.1f}%  {verdict}")
    for cohort, grades in summary["by_cohort_and_grade"].items():
        print(f"{cohort}:")
        for grade, block in grades.items():
            rate = block["verification_rate"]
            ground = block["grounding_rate"]
            print(
                f"  grade {grade}: {rate['numerator']}/{rate['denominator']} "
                f"({rate['value']:.1%}) verified and "
                f"{ground['numerator']}/{ground['denominator']} "
                f"({ground['value']:.1%}) grounded in the cited lesson; "
                f"{block['unscored']} unscored"
            )
            for flag in ("True", "False"):
                sub = block["by_figure_bound"][flag]
                if sub["scored"]:
                    print(
                        f"    figure_bound={flag}: "
                        f"{sub['verified_in_cited_lesson']}/{sub['scored']} "
                        f"({sub['verified_in_cited_lesson'] / sub['scored']:.1%}) "
                        f"verified, "
                        f"{sub['grounded_in_cited_lesson']}/{sub['scored']} "
                        f"({sub['grounded_in_cited_lesson'] / sub['scored']:.1%}) "
                        f"grounded"
                    )
    negative = summary["negative_control"]
    if negative["scored"]:
        print(
            "Negative control: "
            f"{negative['verified_against_a_guide_it_does_not_cite']}/"
            f"{negative['scored']} excerpts verify, and "
            f"{negative['grounded_against_a_guide_it_does_not_cite']}/"
            f"{negative['scored']} reach any grounding, against a guide they "
            "do not cite"
        )
    pages = summary["pages_corroboration"]
    print(
        "Page corroboration: "
        f"{pages['event_pages_inside_lesson_page_range']}/{pages['checkable']} "
        "event page citations fall inside the lesson's own page range"
    )


def run(args: argparse.Namespace) -> int:
    started = time.time()
    partial = bool(args.limit) or args.cohort != "both"
    if partial and args.artifact == DEFAULT_ARTIFACT:
        # A probe must not overwrite the full artifact with its slice.
        args.artifact = args.output_dir / "partial_run.json"
    spine = spine_index()
    corpus = GuideCorpus(args.output_dir / "guide_text")
    corpus.build(refresh=args.refresh_text_cache)
    print(
        f"Guide corpus: {len(corpus.text)} readable "
        f"({corpus.extracted} extracted, {corpus.reused} reused), "
        f"{len(corpus.dataless)} offloaded"
    )

    cohorts = (
        ["opus_verified", "haiku_only"]
        if args.cohort == "both"
        else [args.cohort]
    )
    records: list[dict[str, Any]] = []
    raw_events: dict[int, list[dict]] = {}
    for cohort in cohorts:
        rows = cohort_rows(cohort)
        selected = rows[: args.limit] if args.limit else rows
        for position, row in enumerate(selected, 1):
            # The Opus harvest holds 191 rows across 134 lesson ids, because a
            # lesson read from two page spans is two rows. The ordinal keeps
            # those rows from overwriting each other's checkpoint.
            checkpoint = (
                args.output_dir
                / "checkpoints"
                / cohort
                / f"{row['code']}#{position:04d}.json"
            )
            if checkpoint.is_file() and not args.refresh_text_cache:
                cached = json.loads(checkpoint.read_text(encoding="utf-8"))
                if cached.get("_harvest_row") == row_digest(row):
                    records.append(cached["record"])
                    raw_events[id(records[-1])] = row.get("task_events", [])
                    continue
            record = lesson_record(
                row,
                cohort,
                spine,
                corpus,
                negative_control=not args.no_negative_control,
            )
            atomic_write_json(
                checkpoint, {"_harvest_row": row_digest(row), "record": record}
            )
            records.append(record)
            raw_events[id(records[-1])] = row.get("task_events", [])
            if position % 50 == 0 or position == len(selected):
                print(f"  {cohort}: {position}/{len(selected)} lessons", flush=True)

    def harvest_events(record: dict[str, Any]) -> list[dict]:
        return raw_events[id(record)]

    summary = summarize(records)
    artifact = {
        "schema": "vision_excerpt_verification_v1",
        "generated_by": "scripts/research/verify_vision_excerpts.py",
        "guide_root": str(GUIDE_ROOT),
        "harvests": {
            "opus_verified": str(OPUS_HARVEST.relative_to(ROOT)),
            "haiku_only": str(BROAD_HARVEST.relative_to(ROOT)),
        },
        "quotation_rule": {
            "normalization": (
                "NFKC, curly quotes and dashes folded, whitespace collapsed, "
                "then case and punctuation dropped"
            ),
            "anchor_minimum_characters": ANCHOR_MIN_CHARS,
            "text_layer_floor_characters": TEXT_LAYER_FLOOR,
            "inherited_from": (
                "scripts/curriculum/build_lesson_evidence.py::_fragment_present"
            ),
        },
        "verdict_vocabulary": VERDICT_VOCABULARY,
        "mapping_census": mapping_census(spine),
        "offloaded_guides": sorted(corpus.dataless),
        "executable_subset": executable_subset(records),
        "tier1_subset": tier1_subset(records, harvest_events),
        "summary": summary,
        "lessons": records,
        "seconds": round(time.time() - started, 1),
    }
    atomic_write_json(args.artifact, artifact)
    print_summary(summary)
    for cohort, block in artifact["tier1_subset"]["by_cohort_and_grade"].items():
        if block["scored"]:
            print(
                f"Tier-1 admissible events in {cohort}: {block['tier1_events']}, "
                f"{block['verified_in_cited_lesson']}/{block['scored']} verified, "
                f"{block['grounded_in_cited_lesson']}/{block['scored']} grounded"
            )
        else:
            print(
                f"Tier-1 admissible events in {cohort}: {block['tier1_events']} — "
                "ingest_vision.py's lane 2 filter admits none of them"
            )
    applied = artifact["executable_subset"]
    rate = applied["verification_rate"]
    print(
        "Executable subset already applied by ingest_vision.py: "
        f"{rate['numerator']}/{rate['denominator']} ({rate['value']:.1%}) "
        f"verified and {applied['grounding_rate']['numerator']}/"
        f"{applied['grounding_rate']['denominator']} "
        f"({applied['grounding_rate']['value']:.1%}) grounded in the cited "
        f"lesson, {applied['instances']} instances, {applied['unjoined']} "
        "unjoined"
    )
    print(f"Artifact: {args.artifact}")
    print(f"Checkpoints: {args.output_dir / 'checkpoints'}")
    print(
        "Limit: a verified excerpt is text the guide carries, which is not "
        "the same as an event whose operation the lesson demands."
    )
    return 0


def row_digest(row: dict) -> str:
    return hashlib.sha256(
        json.dumps(row, sort_keys=True, ensure_ascii=False).encode("utf-8")
    ).hexdigest()


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--cohort",
        choices=["opus_verified", "haiku_only", "both"],
        default="both",
        help="which harvest population to score (default: both)",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=0,
        help="score at most this many lessons per cohort (0 scores all)",
    )
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--artifact", type=Path, default=DEFAULT_ARTIFACT)
    parser.add_argument(
        "--refresh-text-cache",
        action="store_true",
        help="re-extract every guide PDF and rescore every lesson",
    )
    parser.add_argument(
        "--no-negative-control",
        action="store_true",
        help="skip scoring each excerpt against an unrelated guide",
    )
    return parser.parse_args(argv)


if __name__ == "__main__":
    try:
        raise SystemExit(run(parse_args(sys.argv[1:])))
    except (OSError, RuntimeError, ValueError) as exc:
        sys.stderr.write(f"error: {exc}\n")
        raise SystemExit(1)
