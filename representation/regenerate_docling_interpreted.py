#!/usr/bin/env python3
"""Regenerate the interpreted-figure fact base (iteration13 B1).

Joins the per-figure REALLMs classifications
(data/research_assets/research/docling_classifications.json) to the docling figure
crop list (data/research_assets/research/2026-06-18-docling-figures.jsonl) and to the
article-level coding in research_corpus/research.db, then writes a richer
GENERATED Prolog fact base over the same student-work figures the old /5 file
carried.

The article-level join (bibtex_key -> domains, grade_bucket, ...) reuses the
exact helpers in representation/build_asset_manifest.py (_article_meta,
_grade_bucket, _classifications) so the two surfaces stay consistent.

Outputs (both under repo-served paths, never /private/tmp):
  - curriculum/im/docling_figures_interpreted.pl   (the logic surface)
  - curriculum/im/docling_figures_interpreted.json  (the audit/debug surface)

The .pl carries TWO fact shapes from one generation:
  - docling_figure_interpreted/5  (unchanged shape, retained for any consumer
    that already adopts the old contract):
      docling_figure_interpreted(RelPath, RepresentationLanguage,
                                 SpatialElements, TranscribedMath, Description)
  - docling_figure_rich/8  (the new, richer, arity-stable shape that supersedes
    /5 for new consumers; queryable by representation language, hybrid flag,
    grade bucket, and source bibkey):
      docling_figure_rich(RelPath, BibtexKey, GradeBucket,
                          IsHybridizedTransplant, Core, Coding,
                          HybridDetails, Strategy)
    where the compound sub-terms are key-value lists / structured terms:
      Core    = core{ representation_language: Atom,
                      spatial_elements: [Atom,...],
                      transcribed_math: AtomOrNone,
                      description: String }
      Coding  = coding{ domains: [Atom,...],
                        error_topics: [String,...],
                        strategy_topics: [String,...] }
      HybridDetails = none  |  hybrid{ foreign_primitive: Atom,
                                       illicit_host: Atom }
      Strategy = none | String

Run from the repo root:  python3 representation/regenerate_docling_interpreted.py
"""

import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(REPO, "representation"))

# Reuse the article-level join + classification reader from the manifest builder
# so the two enrichment surfaces are byte-for-byte the same join logic.
from build_asset_manifest import (  # noqa: E402
    _article_meta,
    _classifications,
    _grade_bucket,  # noqa: F401  (imported for explicitness / reuse parity)
)

PL_OUT = os.path.join(REPO, "curriculum", "im", "docling_figures_interpreted.pl")
JSON_OUT = os.path.join(REPO, "curriculum", "im", "docling_figures_interpreted.json")

DOCLING_JSONL = os.path.join(
    REPO, "data", "research_assets", "research", "2026-06-18-docling-figures.jsonl"
)
DOCLING_CLASSIFICATIONS = os.path.join(
    REPO, "data", "research_assets", "research", "docling_classifications.json"
)


def _short_key(image_path):
    """Last two path components: 'bibkey/file.png' (the classification key)."""
    return "/".join(image_path.replace("\\", "/").split("/")[-2:])


def _bibtex_key(image_path):
    """The parent directory of the figure crop IS the bibtex_key."""
    return _short_key(image_path).split("/")[0]


def _grade_bucket_from_band(band):
    """Coarse 5-bucket grade band from research.db's grade_band string."""
    # _article_meta already computes grade_bucket per bibtex_key; this is only a
    # fallback for the (unobserved) case of a figure whose bibkey is missing.
    return _grade_bucket(band, None)


def _none_atom(v):
    """Normalize the REALLMs 'none'/''/None sentinel to the atom-or-None split."""
    if v in (None, "none", "", "None"):
        return None
    return v


def collect_rows():
    """Yield one enriched record per retained student-work figure.

    Retained set = figures the REALLMs pass flagged
    has_handwriting_or_student_work == True (this reproduces the old /5 file's
    membership: 1,359 rows as of the 2026-06-18 classification snapshot).
    """
    meta = _article_meta()                # bibtex_key -> article coding
    classes = _classifications()          # 'bibkey/file.png' -> classification

    # per-figure error/strategy topics live in the docling jsonl
    topics = {}
    with open(DOCLING_JSONL, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            r = json.loads(line)
            topics[_short_key(r["image"])] = r

    rows = []
    for ckey, cls in classes.items():
        if not cls.get("has_handwriting_or_student_work"):
            continue
        jrow = topics.get(ckey)
        if jrow is None:
            # No crop-list row -> no canonical RelPath; skip (keeps the path the
            # one the existing surfaces already use).
            continue
        relpath = jrow["image"]
        bk = _bibtex_key(relpath)
        am = meta.get(bk, {})

        rep_lang = cls.get("representation_language") or "none"
        spatial = cls.get("spatial_elements") or []
        transcribed = cls.get("transcribed_equation_or_math") or "none"
        description = cls.get("student_strategy_description") or "none"

        is_hybrid = bool(cls.get("is_hybridized_transplant"))
        hd = cls.get("hybrid_details") if is_hybrid else None
        hybrid_details = None
        if isinstance(hd, dict) and hd:
            hybrid_details = {
                "foreign_primitive": hd.get("foreign_primitive"),
                "illicit_host": hd.get("illicit_host"),
            }

        grade_bucket = (am.get("grade_bucket")
                        or _grade_bucket_from_band(am.get("grade_band"))
                        or "unspecified")

        rows.append({
            "image": relpath,
            "bibtex_key": bk,
            # core (the old /5 payload)
            "representation_language": rep_lang,
            "spatial_elements": spatial,
            "transcribed_math": transcribed,
            "description": description,
            # new enrichment
            "domains": am.get("domains") or [],
            "grade_bucket": grade_bucket,
            "error_topics": jrow.get("error_topics") or [],
            "strategy_topics": jrow.get("strategy_topics") or [],
            "is_hybridized_transplant": is_hybrid,
            "hybrid_details": hybrid_details,
            "student_strategy": _none_atom(cls.get("student_strategy_description")),
        })
    rows.sort(key=lambda r: r["image"])
    return rows


# --------------------------------------------------------------------------
# Prolog emission
# --------------------------------------------------------------------------

def _q(s):
    """Quote a Prolog atom/string body (single-quote escaping)."""
    if s is None:
        s = "none"
    return str(s).replace("\\", "\\\\").replace("'", "''")


def _atom(s):
    """A bare lowercase atom token, quoted if it isn't already safe."""
    if s is None:
        return "none"
    s = str(s)
    if s and s[0].islower() and all(c.isalnum() or c == "_" for c in s):
        return s
    return "'" + _q(s) + "'"


def _atom_list(items):
    return "[" + ", ".join(_atom(x) for x in items) + "]"


def _string_list(items):
    return "[" + ", ".join("'" + _q(x) + "'" for x in items) + "]"


def emit_pl(rows):
    out = []
    out.append("/** <module> docling_figures_interpreted")
    out.append(" *")
    out.append(" * GENERATED FILE -- do not hand-edit. Regenerate with:")
    out.append(" *   python3 representation/regenerate_docling_interpreted.py")
    out.append(" *")
    out.append(" * Source join (iteration13 B1):")
    out.append(" *   data/research_assets/research/docling_classifications.json  (REALLMs per-figure)")
    out.append(" *   data/research_assets/research/2026-06-18-docling-figures.jsonl (crop list + topics)")
    out.append(" *   research_corpus/research.db  (article-level domains, grade_bucket)")
    out.append(" *")
    out.append(" * Membership: figures REALLMs flagged as student work.")
    out.append(" *")
    out.append(" * Two fact shapes, both queryable:")
    out.append(" *   docling_figure_interpreted(RelPath, RepresentationLanguage,")
    out.append(" *       SpatialElements, TranscribedMath, Description)   -- old /5, retained")
    out.append(" *   docling_figure_rich(RelPath, BibtexKey, GradeBucket,")
    out.append(" *       IsHybridizedTransplant, Core, Coding, HybridDetails, Strategy)")
    out.append(" *     Core    = core{representation_language, spatial_elements,")
    out.append(" *                    transcribed_math, description}")
    out.append(" *     Coding  = coding{domains, error_topics, strategy_topics}")
    out.append(" *     HybridDetails = none | hybrid{foreign_primitive, illicit_host}")
    out.append(" *     Strategy = none | <description string>")
    out.append(" */")
    out.append(":- module(docling_figures_interpreted,")
    out.append("          [ docling_figure_interpreted/5,")
    out.append("            docling_figure_rich/8 ]).")
    out.append("")

    # old /5 block
    out.append("% --- docling_figure_interpreted/5 (retained shape) ---")
    for r in rows:
        out.append(
            "docling_figure_interpreted('%s', %s, %s, '%s', '%s')." % (
                _q(r["image"]),
                _atom(r["representation_language"]),
                _atom_list(r["spatial_elements"]),
                _q(r["transcribed_math"]),
                _q(r["description"]),
            )
        )
    out.append("")

    # new /8 block
    out.append("% --- docling_figure_rich/8 (enriched, supersedes /5) ---")
    for r in rows:
        core = ("core{representation_language: %s, spatial_elements: %s, "
                "transcribed_math: %s, description: '%s'}" % (
                    _atom(r["representation_language"]),
                    _atom_list(r["spatial_elements"]),
                    _atom(r["transcribed_math"]),
                    _q(r["description"]),
                ))
        coding = ("coding{domains: %s, error_topics: %s, strategy_topics: %s}" % (
            _atom_list(r["domains"]),
            _string_list(r["error_topics"]),
            _string_list(r["strategy_topics"]),
        ))
        if r["hybrid_details"]:
            hd = ("hybrid{foreign_primitive: %s, illicit_host: %s}" % (
                _atom(r["hybrid_details"]["foreign_primitive"]),
                _atom(r["hybrid_details"]["illicit_host"]),
            ))
        else:
            hd = "none"
        strat = ("'" + _q(r["student_strategy"]) + "'"
                 if r["student_strategy"] else "none")
        out.append(
            "docling_figure_rich('%s', %s, %s, %s, %s, %s, %s, %s)." % (
                _q(r["image"]),
                _atom(r["bibtex_key"]),
                _atom(r["grade_bucket"]),
                "true" if r["is_hybridized_transplant"] else "false",
                core,
                coding,
                hd,
                strat,
            )
        )
    out.append("")
    with open(PL_OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(out))


def emit_json(rows):
    payload = {
        "generator": "representation/regenerate_docling_interpreted.py",
        "note": ("Audit/debug surface mirroring docling_figures_interpreted.pl "
                 "docling_figure_rich/8. Stable public image URL paths."),
        "count": len(rows),
        "rows": rows,
    }
    with open(JSON_OUT, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=1)


def main():
    rows = collect_rows()
    emit_pl(rows)
    emit_json(rows)

    # coverage signal
    n = len(rows)
    def cnt(pred):
        return sum(1 for r in rows if pred(r))
    print("regenerated docling_figures_interpreted.{pl,json}")
    print("  rows                     : %d" % n)
    print("  with bibtex_key          : %d" % cnt(lambda r: r["bibtex_key"]))
    print("  with non-empty domains   : %d" % cnt(lambda r: r["domains"]))
    print("  with error_topics        : %d" % cnt(lambda r: r["error_topics"]))
    print("  with strategy_topics     : %d" % cnt(lambda r: r["strategy_topics"]))
    print("  grade_bucket != unspecified: %d"
          % cnt(lambda r: r["grade_bucket"] != "unspecified"))
    print("  is_hybridized_transplant : %d"
          % cnt(lambda r: r["is_hybridized_transplant"]))
    print("  with hybrid_details      : %d"
          % cnt(lambda r: r["hybrid_details"]))


if __name__ == "__main__":
    main()
