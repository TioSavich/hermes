#!/usr/bin/env python3
"""Build the representation asset manifest.

Reads two already-coded image corpora and emits one JSON manifest that the
gallery surface (more-zeeman/gallery.html) fetches. This is the first concrete
`asset_for` data for the representation spine described in
docs/proposals/2026-06-18-representation-vision.md. Image paths in the manifest
are repo-root-relative; the gallery resolves them against the repo root.

Two sources today:

  - asktm      : Grade-4 and Grade-5 ASKTM student-work clips. Fine-grained
                 category and reasoning metadata is joined when the source
                 coding Markdown names the clip; otherwise those fields remain
                 null. Ready to display; no cropping needed.
  - literature : full-page PDF-page renders of student-work figures from the
                 research literature, joined to citation + page number + the
                 error/strategy topics on that page. These still need a human to
                 eyeball and crop, so each carries crop_status='unreviewed'.

Run from the repo root:

  python3 representation/build_asset_manifest.py \
    --asktm-metadata-root /path/to/source/ASKTM_Data

The metadata root is optional. The standalone Hermes repository ships the
clipping PNGs, not the source coding documents, so omitted metadata degrades to
honest nulls.
"""

import argparse
import json
import os
import re
import glob

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(REPO, "representation", "asset_manifest.json")
ASKTM_BINDINGS = os.path.join(
    REPO, "representation", "asktm_bindings_draft.json",
)
ASKTM_ROOT = os.path.join(REPO, "ASKTM_Data")
ASKTM_G4_CLIPS = os.path.join(ASKTM_ROOT, "Grade 4student response clippings")
ASKTM_G5_CLIPS = os.path.join(
    ASKTM_ROOT, "Grade 5 Students' responses Clips (q1-q8)",
)


def rel(p):
    """Path relative to the repo root, forward-slashed."""
    return os.path.relpath(p, REPO).replace(os.sep, "/")


# Predicate-shaped concept keys for the gallery. These are conservative joins:
# they do not assert a new Prolog predicate; they give each asset stable terms
# that route back to existing Prolog concept and renderer surfaces.
REPRESENTATION_CONCEPTS = {
    "fraction_bars": [
        "primitive_renders_metaphor('P2', object_construction, primary)",
        "run_fraction_action(unit_fraction_partition)",
    ],
    "area_model": [
        "primitive_renders_metaphor('P3', object_construction, secondary)",
        "run_fraction_action(area_model_part_of_part)",
    ],
    "number_line": [
        "primitive_renders_metaphor('P1', motion_along_path, primary)",
    ],
    "set_grouping": [
        "primitive_renders_metaphor('P5', object_collection, primary)",
    ],
    "base_ten_blocks": [
        "primitive_renders_metaphor('P4', object_construction, primary)",
    ],
    "place_value_chart": [
        "primitive_renders_metaphor('P4', object_construction, primary)",
    ],
    "balance_scale": [
        "primitive_renders_metaphor('PB', balance_preservation_schema, primary)",
    ],
}

TEXT_CONCEPT_PATTERNS = [
    (re.compile(r"\b(area model|area-model|array model|rectangle model)\b", re.I),
     "run_fraction_action(area_model_part_of_part)"),
    (re.compile(r"\b(fraction bar|fraction strip|bar model|strip diagram)\b", re.I),
     "primitive_renders_metaphor('P2', object_construction, primary)"),
    (re.compile(r"\b(number line|timeline|open number line)\b", re.I),
     "primitive_renders_metaphor('P1', motion_along_path, primary)"),
    (re.compile(r"\b(set model|set grouping|tree diagram|combinations)\b", re.I),
     "primitive_renders_metaphor('P5', object_collection, primary)"),
    (re.compile(r"\b(base[- ]?ten|place value|bundl(?:e|ing))\b", re.I),
     "primitive_renders_metaphor('P4', object_construction, primary)"),
    (re.compile(r"\b(balance scale|relational equals|equation balance)\b", re.I),
     "primitive_renders_metaphor('PB', balance_preservation_schema, primary)"),
    (re.compile(r"\b(unit fraction|unit-fraction|iterate|iteration)\b", re.I),
     "run_fraction_action(unit_fraction_iteration)"),
    (re.compile(r"\b(partition|partitioning|equal parts)\b", re.I),
     "run_fraction_action(unit_fraction_partition)"),
    (re.compile(r"\b(cross[- ]?multiplication|multiply across)\b", re.I),
     "run_fraction_action(cross_multiplication_rule_from_pattern)"),
    (re.compile(r"\b(quadrilateral|rectangle|square|rhombus|trapezoid|parallelogram)\b", re.I),
     "geom_concept(quadrilateral_hierarchy)"),
    (re.compile(r"\b(area|perimeter|surface coverage|tiling)\b", re.I),
     "geom_concept(area_as_interior_coverage)"),
    (re.compile(r"\b(ruler|length measurement|measuring)\b", re.I),
     "geom_concept(length_measurement_as_unit_iteration)"),
]


def _prolog_concepts(asset):
    concepts = []
    seen = set()

    def add(concept):
        if concept and concept not in seen:
            concepts.append(concept)
            seen.add(concept)

    for concept in REPRESENTATION_CONCEPTS.get(
            asset.get("representation_language"), []):
        add(concept)

    text_fields = [
        asset.get("category_code"),
        asset.get("category_desc"),
        asset.get("citation"),
        asset.get("title"),
        asset.get("student_strategy"),
        asset.get("transcribed_math"),
        *(asset.get("tags") or []),
        *(asset.get("captions") or []),
        *(asset.get("domains") or []),
        *(asset.get("error_topics") or []),
        *(asset.get("strategy_topics") or []),
        *(asset.get("spatial_elements") or []),
    ]
    text = " ".join(str(v) for v in text_fields if v)
    for pattern, concept in TEXT_CONCEPT_PATTERNS:
        if pattern.search(text):
            add(concept)
    return concepts


def _with_prolog_concepts(asset):
    asset["prolog_concepts"] = _prolog_concepts(asset)
    return asset


# --------------------------------------------------------------------------
# ASKTM (Grade 4 and Grade 5 student work)
# --------------------------------------------------------------------------

# Coded filename, e.g. G5-Q2-A2-04-08.png
#   grade 5, question 2, category A2, student 04, clip 08
ASKTM_FILE = re.compile(r"G(\d)-Q(\d+)-([A-Za-z]+\d*)-(\d+)-(\d+)\.png$", re.I)

# Markdown legend: "# Category A2 – Correct response includes ..."
CAT_HDR = re.compile(
    r"^#\s*(?:\*\*)?(?:Category\s+)?([A-Za-z]+\d*)\s*[–\-—]\s*(.*?)"
    r"(?:\*\*)?\s*$",
)
TAG_LINE = re.compile(r"Tag list:\s*(.*)$")
# Clip ids inside the legend: q2-04-08 / q2_20_08 (question-student-clip)
CLIP_ID = re.compile(r"q(\d+)[-_](\d+)[-_](\d+)", re.I)
# Some Grade-4 legends name the clip without repeating the question number.
BARE_CLIP_ID = re.compile(r"(?<![\w-])(\d+)[-_](\d+)\.(?:png)", re.I)
G4_CLIP_FILE = re.compile(r"(?:q\d+[-_])?(\d+)[-_](\d+)\.png$", re.I)
G4_QUESTION_DIR = re.compile(r"^4-q(\d+)(?:-|$)", re.I)
G5_RAW_FILE = re.compile(r"q(\d+)[-_](\d+)[-_](\d+)\s*\.png$", re.I)


def _norm_tags(raw):
    raw = re.sub(r"[*`]", "", raw)
    parts = re.split(r"[;]", raw)
    return [t.strip() for t in parts if t.strip()]


def parse_asktm_legend(md_path):
    """Return category descriptions and per-clip category/tag metadata."""
    cat_desc, clip_tags, clip_categories = {}, {}, {}
    cur_code = None
    cur_tags = []
    m_q = re.search(r"G(\d)Q(\d+)", os.path.basename(md_path), re.I)
    file_q = m_q.group(2) if m_q else None
    for line in open(md_path, encoding="utf-8", errors="replace"):
        line = line.rstrip("\n")
        h = CAT_HDR.match(line)
        if h:
            cur_code = h.group(1).upper()
            cur_tags = []
            cat_desc[(file_q, cur_code)] = re.sub(r"[*`]", "", h.group(2)).strip()
            continue
        t = TAG_LINE.search(line)
        if t:
            cur_tags = _norm_tags(t.group(1))
            continue
        matches = [cm.groups() for cm in CLIP_ID.finditer(line)]
        if not matches:
            matches = [(file_q, *cm.groups()) for cm in BARE_CLIP_ID.finditer(line)]
        for q, stu, clip in matches:
            stu, clip = stu.zfill(2), clip.zfill(2)
            key = (q, stu, clip)
            clip_tags.setdefault(key, set()).update(cur_tags)
            if cur_code:
                clip_categories.setdefault(key, set()).add(cur_code)
    return cat_desc, clip_tags, clip_categories


def _legend_metadata(metadata_root, grade):
    dirname = ("Grade 4_Fine-Grained Coding_Second Pass" if grade == 4 else
               "Grade5 _Fine-Grained Coding_Second Pass")
    legends_glob = os.path.join(
        metadata_root, dirname, "converted", f"G{grade}Q*.md",
    )
    cat_desc, clip_tags, clip_categories = {}, {}, {}
    for md in sorted(glob.glob(legends_glob)):
        cd, ct, cc = parse_asktm_legend(md)
        cat_desc.update(cd)
        for k, v in ct.items():
            clip_tags.setdefault(k, set()).update(v)
        for k, v in cc.items():
            clip_categories.setdefault(k, set()).update(v)
    return cat_desc, clip_tags, clip_categories


def _asktm_bindings(path=ASKTM_BINDINGS):
    """Return mapped rows, with their review tier, keyed by ASKTM category."""
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, ValueError):
        return {}
    bindings = {}
    for row in data.get("bindings", []):
        concept = row.get("proposed_prolog_concept")
        automaton = row.get("proposed_automaton")
        if not concept or automaton in {
                "awaiting_conversion", "no_defensible_binding"}:
            continue
        verification_status = row.get("verification_status")
        if verification_status == "verified":
            status = "verified"
        elif verification_status == "draft_unverified":
            status = "draft"
        else:
            continue
        key = (int(row["grade"]), str(row["question"]),
               row["category_code"].upper())
        bindings.setdefault(key, []).append((concept, status))
    return bindings


def _asset(grade, q, code, stu, clip, tags, desc, png, tree=None,
           bindings=None):
    code_for_id = code or "uncategorized"
    tree_part = f"-{tree}" if tree else ""
    asset = _with_prolog_concepts({
        "source": "asktm",
        "id": (f"asktm-g{grade}{tree_part}-q{q}-{code_for_id}-"
               f"{stu}-{clip}"),
        "grade": grade,
        "question": int(q),
        "category_code": code,
        "category_desc": desc,
        "student": stu,
        "clip": clip,
        "tags": sorted(tags),
        "image": rel(png),
    })
    if code:
        key = (int(grade), str(q), code.upper())
        for concept, status in (bindings or {}).get(key, []):
            if concept not in asset["prolog_concepts"]:
                asset["prolog_concepts"].append(concept)
            asset.setdefault("prolog_concept_binding_status", {})[concept] = status
    return asset


def build_asktm(metadata_root=None, bindings_path=ASKTM_BINDINGS):
    metadata_root = metadata_root or ASKTM_ROOT
    bindings = _asktm_bindings(bindings_path)
    legends = {grade: _legend_metadata(metadata_root, grade)
               for grade in (4, 5)}

    assets = []
    seen = set()
    # Preserve the existing category-coded Grade-5 first-pass population.
    for png in glob.glob(os.path.join(ASKTM_G5_CLIPS, "Grade 5-*first pass*",
                                      "*.png")):
        m = ASKTM_FILE.search(os.path.basename(png))
        if not m:
            continue
        grade, q, code, stu, clip = m.groups()
        code = code.upper()
        stu, clip = stu.zfill(2), clip.zfill(2)
        key = (q, code, stu, clip)
        if key in seen:
            continue
        seen.add(key)
        cat_desc, clip_tags, _ = legends[5]
        assets.append(_asset(
            5, q, code, stu, clip, clip_tags.get((q, stu, clip), ()),
            cat_desc.get((q, code)) or None, png,
            bindings=bindings,
        ))

    # Grade-5 raw/non-first-pass clippings. Their filenames carry no category;
    # use the fine-grained legend only when it names the exact clip.
    cat_desc, clip_tags, clip_categories = legends[5]
    for png in glob.glob(os.path.join(ASKTM_G5_CLIPS, "5-Q*", "**",
                                      "*.[pP][nN][gG]"), recursive=True):
        m = G5_RAW_FILE.search(os.path.basename(png))
        if not m:
            continue
        q, stu, clip = m.groups()
        stu, clip = stu.zfill(2), clip.zfill(2)
        categories = clip_categories.get((q, stu, clip), set())
        code = next(iter(categories)) if len(categories) == 1 else None
        assets.append(_asset(
            5, q, code, stu, clip, clip_tags.get((q, stu, clip), ()),
            cat_desc.get((q, code)) if code else None, png, tree="raw",
            bindings=bindings,
        ))

    # Grade-4 raw clipping directories encode the question in the directory
    # and student/clip in the filename.
    cat_desc, clip_tags, clip_categories = legends[4]
    for png in glob.glob(os.path.join(ASKTM_G4_CLIPS, "**",
                                      "*.[pP][nN][gG]"), recursive=True):
        qmatch = G4_QUESTION_DIR.match(os.path.relpath(
            png, ASKTM_G4_CLIPS).split(os.sep)[0])
        m = G4_CLIP_FILE.search(os.path.basename(png))
        if not qmatch or not m:
            continue
        q = qmatch.group(1)
        stu, clip = (part.zfill(2) for part in m.groups())
        categories = clip_categories.get((q, stu, clip), set())
        code = next(iter(categories)) if len(categories) == 1 else None
        assets.append(_asset(
            4, q, code, stu, clip, clip_tags.get((q, stu, clip), ()),
            cat_desc.get((q, code)) if code else None, png, tree="raw",
            bindings=bindings,
        ))

    assets.sort(key=lambda a: (a["grade"], a["question"],
                               a["category_code"] or "",
                               a["student"], a["clip"]))
    return assets


# --------------------------------------------------------------------------
# Literature (full-page PDF renders of student-work figures)
# --------------------------------------------------------------------------

LIT_JSON = os.path.join(
    REPO, "docs", "research_assets", "research",
    "2026-05-11-fraction-student-work-figure-candidates.json",
)
# docling figure crops (all domains) — preferred over the full-page fraction set
DOCLING_JSONL = os.path.join(
    REPO, "docs", "research_assets", "research", "2026-06-18-docling-figures.jsonl",
)
# REALLMs per-figure classification (representation language, spatial elements,
# student-work flag, transplant-hybridization flag, transcribed math, strategy).
DOCLING_CLASSIFICATIONS = os.path.join(
    REPO, "docs", "research_assets", "research", "docling_classifications.json",
)


def _classifications():
    """Map 'bibkey/file.png' -> REALLMs classification dict (best-effort)."""
    if not os.path.exists(DOCLING_CLASSIFICATIONS):
        return {}
    try:
        raw = json.load(open(DOCLING_CLASSIFICATIONS, encoding="utf-8"))
    except (OSError, ValueError):
        return {}
    out = {}
    for abspath, cls in raw.items():
        if not isinstance(cls, dict) or "error" in cls:
            continue
        key = "/".join(abspath.replace("\\", "/").split("/")[-2:])
        out[key] = cls
    return out


def _trim(items, n=3, maxlen=240):
    out = []
    for s in (items or [])[:n]:
        s = s.strip()
        out.append(s if len(s) <= maxlen else s[:maxlen].rstrip() + "…")
    return out


# --- per-article metadata join (research.db) for richer gallery filtering ---
# research.db is gitignored but present locally; enrichment is best-effort and
# degrades to empty fields if the DB is absent.

_JOURNAL_ABBREV = [
    ("for the learning of mathematics", "FLM"),
    ("educational studies in mathematics", "ESM"),
    ("journal for research in mathematics education", "JRME"),
    ("journal of mathematical behavior", "JMB"),
    ("international journal of mathematical education", "IJMEST"),
    ("international journal of science and mathematics education", "IJSME"),
    ("international journal of education in mathematics", "IJEMST"),
    ("mathematics education research journal", "MERJ"),
    ("journal of mathematics teacher education", "JMTE"),
    ("research in mathematics education", "RME"),
    ("mathematical thinking and learning", "MTL"),
    ("teacher educ", "JMTE"),          # "J Math Teacher Educ" abbreviated form
    ("zdm", "ZDM"),
]

_ORDINALS = {
    "kindergarten": 0, "first": 1, "second": 2, "third": 3, "fourth": 4,
    "fifth": 5, "sixth": 6, "seventh": 7, "eighth": 8, "ninth": 9,
    "tenth": 10, "eleventh": 11, "twelfth": 12,
}


def _journal_abbrev(journal_full):
    j = (journal_full or "").lower()
    for needle, abbr in _JOURNAL_ABBREV:
        if needle in j:
            return abbr
    return (journal_full or "").strip() or None


def _grade_bucket(grade_text, population):
    """Coarse, best-effort band from the free-text grade + population_type. The
    raw grade_band stays on the asset for ground truth; this is for filtering."""
    pop = (population or "").lower()
    if pop == "pst":
        return "preservice teachers"
    if pop == "in_service":
        return "in-service teachers"
    g = (grade_text or "").lower()
    if not g:
        return {"mixed": "mixed", "other": "other"}.get(pop, "unspecified")
    if re.search(r"pre-?service|prospective|student teacher", g):
        return "preservice teachers"
    if re.search(r"in-?service|practicing teacher", g):
        return "in-service teachers"
    if re.search(r"universit|college|undergrad|tertiary|\badult", g):
        return "tertiary / adult"
    if re.search(r"middle school|junior high", g):
        return "middle (6–8)"
    if re.search(r"high school|secondary|senior high", g):
        return "secondary (9–12)"
    if re.search(r"preschool|elementary|primary", g):
        return "elementary (K–5)"
    nums = [int(n) for n in re.findall(r"\d+", g)]
    word_grades = [v for w, v in _ORDINALS.items() if re.search(r"\b" + w + r"\b", g)]
    is_age = bool(re.search(r"year|age|\byr", g))
    has_grade = bool(re.search(r"grade|grader|kindergarten", g))
    if word_grades and (has_grade or not is_age):
        nums = nums + word_grades
        has_grade = True
    if nums:
        if is_age and not has_grade:
            ages = [n for n in nums if n <= 22] or nums
            avg = sum(ages) / len(ages)
            return ("elementary (K–5)" if avg <= 10 else
                    "middle (6–8)" if avg <= 13 else
                    "secondary (9–12)" if avg <= 18 else "tertiary / adult")
        grades = [n for n in nums if 0 <= n <= 12]
        if grades:
            avg = sum(grades) / len(grades)
            return ("elementary (K–5)" if avg <= 5 else
                    "middle (6–8)" if avg <= 8 else "secondary (9–12)")
    return "unspecified"


def _article_meta():
    """bibtex_key -> dict(domains, population, study_design, grade_band,
    grade_bucket, country, journal_abbrev) from research.db. Empty if no DB."""
    import sqlite3
    db = os.path.join(REPO, "research_corpus", "research.db")
    if not os.path.exists(db):
        return {}
    con = sqlite3.connect(db)
    meta = {}
    for bk, gb, pop, sd, country, jabbr, journal in con.execute(
            """SELECT bibtex_key, grade_band_as_declared, population_type,
                      study_design, country, journal_abbrev, journal
                 FROM articles WHERE bibtex_key IS NOT NULL"""):
        meta[bk] = {
            "domains": set(),
            "population": pop,
            "study_design": sd,
            "grade_band": gb,
            "grade_bucket": _grade_bucket(gb, pop),
            "country": country,
            "journal_abbrev": jabbr or _journal_abbrev(journal),
        }
    for bk, dom in con.execute(
            """SELECT a.bibtex_key, e.mathematical_domain
                 FROM error_instances e JOIN articles a ON e.article_id = a.id
                WHERE a.bibtex_key IS NOT NULL AND e.mathematical_domain IS NOT NULL
               UNION
               SELECT a.bibtex_key, s.mathematical_domain
                 FROM strategy_instances s JOIN articles a ON s.article_id = a.id
                WHERE a.bibtex_key IS NOT NULL AND s.mathematical_domain IS NOT NULL"""):
        if bk in meta:
            meta[bk]["domains"].add(dom)
    con.close()
    for m in meta.values():
        m["domains"] = sorted(m["domains"])
    return meta


def build_literature_docling():
    """Read docling-extracted figure crops (the image IS the figure)."""
    meta = _article_meta()
    classes = _classifications()
    assets = []
    with open(DOCLING_JSONL, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            r = json.loads(line)
            if not os.path.exists(os.path.join(REPO, r["image"])):
                continue
            am = meta.get(r.get("bibtex_key"), {})
            ckey = "/".join(r["image"].replace("\\", "/").split("/")[-2:])
            cls = classes.get(ckey, {})
            assets.append(_with_prolog_concepts({
                "source": "literature",
                "id": r["id"],
                "bibtex_key": r.get("bibtex_key"),
                "citation": r.get("citation"),
                "authors": r.get("authors"),
                "year": r.get("year"),
                "title": r.get("title"),
                "journal": r.get("journal"),
                "journal_abbrev": am.get("journal_abbrev")
                                  or _journal_abbrev(r.get("journal")),
                "page_ref": r.get("page_ref") or (f"pdf {r.get('page_no')}"
                                                  if r.get("page_no") else "?"),
                "figure_page": bool(r.get("on_candidate_page")),
                "image": r["image"],
                # article-level coding (research.db) for filtering + context
                "domains": am.get("domains") or [],
                "population": am.get("population"),
                "study_design": am.get("study_design"),
                "grade_band": am.get("grade_band"),
                "grade_bucket": am.get("grade_bucket") or "unspecified",
                "country": am.get("country"),
                "auto_crops": [],          # the image already is the figure crop
                "captions": [r["caption"]] if r.get("caption") else [],
                "error_topics": r.get("error_topics") or [],
                "strategy_topics": r.get("strategy_topics") or [],
                "error_examples": [],
                "strategy_examples": [],
                "resolution_note": None,
                "crop_status": r.get("crop_status", "docling_auto"),
                # REALLMs per-figure classification (neuro-side reading)
                "representation_language": cls.get("representation_language"),
                "spatial_elements": cls.get("spatial_elements") or [],
                "is_student_work": bool(cls.get("has_handwriting_or_student_work")),
                "is_hybridized_transplant": bool(cls.get("is_hybridized_transplant")),
                "hybrid_details": cls.get("hybrid_details"),
                "transcribed_math": (cls.get("transcribed_equation_or_math")
                                     if cls.get("transcribed_equation_or_math") not in (None, "none", "")
                                     else None),
                "student_strategy": (cls.get("student_strategy_description")
                                     if cls.get("student_strategy_description") not in (None, "none", "")
                                     else None),
            }))
    assets.sort(key=lambda a: (a.get("bibtex_key") or "", a.get("page_ref") or ""))
    return assets


def build_literature():
    # Prefer docling figure crops when available.
    if os.path.exists(DOCLING_JSONL) and os.path.getsize(DOCLING_JSONL) > 0:
        return build_literature_docling()
    if not os.path.exists(LIT_JSON):
        return []
    data = json.load(open(LIT_JSON, encoding="utf-8"))
    assets = []
    for c in data.get("candidates", []):
        page_img = c.get("rendered_page_path")
        if not page_img or not os.path.exists(os.path.join(REPO, page_img)):
            continue
        crops = [p for p in (c.get("crop_paths") or [])
                 if os.path.exists(os.path.join(REPO, p))]
        assets.append(_with_prolog_concepts({
            "source": "literature",
            "id": f"lit-{c.get('article_id')}-p{c.get('page_ref')}",
            "bibtex_key": c.get("bibtex_key"),
            "citation": c.get("citation") or
                        f"{c.get('authors','')} ({c.get('year','')})",
            "authors": c.get("authors"),
            "year": c.get("year"),
            "title": c.get("title"),
            "journal": c.get("journal"),
            "page_ref": c.get("page_ref"),
            "figure_page": bool(c.get("figure_page")),
            "image": page_img,
            "auto_crops": crops,
            "captions": _trim(c.get("captions"), n=5, maxlen=160),
            "error_topics": c.get("error_topics") or [],
            "strategy_topics": c.get("strategy_topics") or [],
            "error_examples": _trim(c.get("error_examples")),
            "strategy_examples": _trim(c.get("strategy_examples")),
            "resolution_note": c.get("resolution_note"),
            # Page refs sometimes point at a figure's first textual mention
            # rather than the figure itself; auto-crops are sloppy. Nothing
            # here is human-verified yet.
            "crop_status": "unreviewed",
        }))
    assets.sort(key=lambda a: (a.get("bibtex_key") or "", a.get("page_ref") or ""))
    return assets


def input_warnings(metadata_root=None, preserving_literature=False):
    """Describe input omissions that would otherwise look like empty results."""
    warnings = []

    def warn(code, path, message):
        warnings.append({
            "code": code,
            "path": rel(path),
            "message": message,
        })

    if not os.path.isdir(ASKTM_ROOT):
        warn(
            "asktm_data_missing",
            ASKTM_ROOT,
            "ASKTM_Data is absent; ASKTM assets will be omitted.",
        )

    metadata_root = metadata_root or ASKTM_ROOT
    if not glob.glob(os.path.join(
            metadata_root, "Grade5 _Fine-Grained Coding_Second Pass",
            "converted", "G5Q*.md")):
        warn(
            "asktm_metadata_missing",
            metadata_root,
            "Fine-grained ASKTM Markdown is absent; category and tag fields degrade to nulls.",
        )

    research_db = os.path.join(REPO, "research_corpus", "research.db")
    if not os.path.exists(research_db) and not preserving_literature:
        warn(
            "research_db_missing",
            research_db,
            "research.db is absent; literature domain and grade buckets degrade.",
        )

    docling_available = (
        os.path.exists(DOCLING_JSONL) and os.path.getsize(DOCLING_JSONL) > 0
    )
    lit_available = os.path.exists(LIT_JSON)
    if not docling_available and not lit_available and preserving_literature:
        warn(
            "literature_inputs_missing_preserving_manifest",
            DOCLING_JSONL,
            "Literature inputs are absent; preserving checked-in literature entries.",
        )
    elif not docling_available and not lit_available:
        warn(
            "literature_inputs_missing",
            DOCLING_JSONL,
            "No docling JSONL or fallback literature JSON exists; literature assets will be omitted.",
        )
    elif not docling_available and lit_available:
        warn(
            "docling_jsonl_missing_using_fraction_fallback",
            DOCLING_JSONL,
            "Docling JSONL is absent; falling back to the older fraction-page candidate JSON.",
        )

    if not os.path.exists(DOCLING_CLASSIFICATIONS):
        warn(
            "docling_classifications_missing",
            DOCLING_CLASSIFICATIONS,
            "Docling classifications are absent; representation-language fields degrade.",
        )

    return warnings


def _existing_manifest():
    try:
        with open(OUT, encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, ValueError):
        return {}
    return data if isinstance(data, dict) else {}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--asktm-metadata-root",
        help="ASKTM_Data directory containing converted fine-grained Markdown",
    )
    args = parser.parse_args()

    existing = _existing_manifest()
    asktm = build_asktm(args.asktm_metadata_root)
    lit = build_literature()
    preserving_literature = False
    if not lit:
        lit = [a for a in existing.get("assets", [])
               if a.get("source") == "literature"]
        preserving_literature = bool(lit)
    manifest = {
        # Preserve the tracked provenance timestamp. The corpus inputs are
        # immutable for a build, so wall-clock time must not spoil determinism.
        "generated_at": existing.get("generated_at"),
        "generator": "representation/build_asset_manifest.py",
        "note": ("Repo-root-relative image paths. Serve the gallery from the "
                 "repo root so '../' resolves to it."),
        "counts": {
            "asktm": len(asktm),
            "literature": len(lit),
            "literature_unreviewed": sum(1 for a in lit
                                         if a["crop_status"] == "unreviewed"),
            "total": len(asktm) + len(lit),
        },
        "input_warnings": input_warnings(
            args.asktm_metadata_root, preserving_literature,
        ),
        "assets": asktm + lit,
    }
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=1)
    print(f"wrote {rel(OUT)}")
    print(f"  asktm      : {len(asktm)}")
    print(f"  literature : {len(lit)} ({manifest['counts']['literature_unreviewed']} unreviewed)")
    # quick coverage signal
    tagged = sum(1 for a in asktm if a["tags"])
    described = sum(1 for a in asktm if a["category_desc"])
    print(f"  asktm tagged: {tagged}/{len(asktm)}  described: {described}/{len(asktm)}")


if __name__ == "__main__":
    main()
