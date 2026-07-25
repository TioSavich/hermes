#!/usr/bin/env python3
"""Propose corpus-to-automaton bindings for the signatures that have none.

``data/research/research_shared.db`` holds 936 rows in
``automaton_instance_bindings`` mapping corpus rows to automaton signatures, and
those rows carry a review status: 601 ``auto_tentative``, 333 ``auto_high``, and
2 ``human_rejected``.  They were written by something labelled
``strategy_row_mapper`` and ``error_row_mapper`` that is not in this repository.
They reach 68 signatures.  The registry now declares 215.

So this rebuilds the mapping for what the earlier pass could not have seen, and
it writes a PROPOSAL FILE rather than the database.  Two reasons, and the second
is the real one:

  Those rows are reviewed.  Two are human-rejected, which means the owner reads
  them.  Adding several hundred ``auto_tentative`` rows to a table someone reviews
  is an imposition, and undoing it cleanly afterwards is not trivial.

  A proposal can be read before it is believed.  Every proposed row carries its
  score, the vocabulary terms that earned it, the article it comes from, and the
  runner-up signature it beat.  That is what makes it reviewable at all.

**How a row is scored.**  A signature's vocabulary is three things joined: the
``vocabulary([...])`` list its action-pair outcome declares, the content words of
its own action labels, and its ``invariant/1`` if it has one.  A corpus row's text
is its description, example, key-moves summary and student rule.  The score is the
number of distinct signature vocabulary terms the row's text contains, weighted so
that a multi-word term counts for more than a single word -- a row matching
"counted addend" says more than a row matching "count".

**What it deliberately does not do.**  It does not rescore the 68 signatures that
already have bindings, so nothing here can contradict a reviewed row.  It proposes
only for signatures with no binding at all, and it reports the ones it could not
reach rather than lowering the bar until everything matches.
"""

from __future__ import annotations

import argparse
import collections
import json
import pathlib
import re
import sqlite3
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
DB = ROOT / "data/research/research_shared.db"
REGISTRY = ROOT / "knowledge/strategies/math/action_automata_registry.pl"
PAIR_DIR = ROOT / "knowledge/strategies/math"
TABLES = ROOT / "knowledge/strategies/transition_tables"
DEFAULT_OUTPUT = ROOT / "data/research/corpus_binding_proposals.json"

SIGNATURE_RE = re.compile(
    r"action_automaton_signature\(\s*([a-z_]+),\s*([a-z_0-9]+)\s*,", re.S)
OUTCOME_RE = re.compile(r"action_outcome\(\s*([a-z][a-z0-9_]*)\s*,\s*\[")
VOCAB_RE = re.compile(r"vocabulary\(\[([^\]]*)\]\)")
INVARIANT_RE = re.compile(r"invariant\(([a-z][a-z0-9_]*)\)")
CLASSIFICATION_RE = re.compile(r"classification\((\w+)\)")
TRANS_RE = re.compile(
    r"(?m)^automaton_transition\((\w+), (\w+), (\w+), (\w+), (\w+),")

STOPWORDS = frozenset(
    "the a an of to in as by and or for with on at from into is it that this "
    "their its be was were all not no".split())

# The corpus records a mathematical_domain per row; the tables record a family
# per signature. Requiring the two to agree removes a whole class of confusion --
# a fraction-comparison row scored 7.0 against integer/inequality_solution_set_
# representation on "greater than", "less than" and "number line", which is
# vocabulary the two genuinely share and a match they do not. Disagreeing rows are
# kept in a separate bucket rather than dropped, because the domain field is itself
# an analyst's judgment and a handful of cross-domain bindings are real.
DOMAIN_FAMILIES = {
    "fraction": {"fraction"},
    "rational": {"fraction", "decimal", "ratio"},
    "decimal": {"decimal"},
    "whole_number": {"addition", "subtraction", "multiplication", "division",
                     "counting"},
    "algebraic": {"algebraic"},
    "proportional": {"ratio", "multiplication", "division"},
    "geometric": {"geometry", "measurement"},
    "measurement": {"measurement", "geometry"},
    "statistics": {"statistics"},
    "integer": {"integer"},
    "probability": {"probability"},
    "calculus": {"calculus"},
}


def domain_agrees(domain: str, family: str) -> bool:
    """Unknown or unmapped domains agree with everything: the field is optional in
    the corpus and an absent domain is not evidence against a binding."""
    families = DOMAIN_FAMILIES.get((domain or "").strip().lower())
    return families is None or family in families


MIN_SCORE = 3.0
MAX_PROPOSALS_PER_SIGNATURE = 6


def content_words(text: str) -> set[str]:
    return {w for w in re.findall(r"[a-z]+", (text or "").lower())
            if w not in STOPWORDS and len(w) > 2}


def signature_vocabulary() -> dict[tuple[str, str], tuple[set[str], set[str], str]]:
    """Per signature: single-word terms, multi-word terms, and its role."""
    registered = {(op, kind) for op, kind in SIGNATURE_RE.findall(
        REGISTRY.read_text(encoding="utf-8"))}
    labels: dict[str, set[str]] = collections.defaultdict(set)
    families: dict[str, str] = {}
    for path in sorted(TABLES.glob("*.pl")):
        for family, signature, _, action, _ in TRANS_RE.findall(
                path.read_text(encoding="utf-8")):
            labels[signature].add(action)
            families[signature] = family
    per_signature: dict[str, tuple[set[str], set[str], str]] = {}
    for path in sorted(PAIR_DIR.glob("*action_pairs*.pl")):
        text = path.read_text(encoding="utf-8")
        for match in OUTCOME_RE.finditer(text):
            signature = match.group(1)
            index, depth = match.end(), 1
            while index < len(text) and depth:
                if text[index] == "[":
                    depth += 1
                elif text[index] == "]":
                    depth -= 1
                index += 1
            body = text[match.end():index - 1]
            singles: set[str] = set()
            multis: set[str] = set()
            for group in VOCAB_RE.findall(body):
                for term in (t.strip() for t in group.split(",")):
                    if not term:
                        continue
                    words = [w for w in term.split("_") if w not in STOPWORDS]
                    if len(words) > 1:
                        multis.add(" ".join(words))
                    singles.update(w for w in words if len(w) > 2)
            for invariant in INVARIANT_RE.findall(body):
                words = [w for w in invariant.split("_") if w not in STOPWORDS]
                if len(words) > 1:
                    multis.add(" ".join(words))
                singles.update(w for w in words if len(w) > 2)
            classification = (CLASSIFICATION_RE.search(body) or [None, "unknown"])[1] \
                if CLASSIFICATION_RE.search(body) else "unknown"
            for action in labels.get(signature, ()):
                words = [w for w in action.split("_") if w not in STOPWORDS]
                if len(words) > 1:
                    multis.add(" ".join(words))
                singles.update(w for w in words if len(w) > 2)
            previous = per_signature.get(signature)
            if previous:
                singles |= previous[0]
                multis |= previous[1]
            per_signature[signature] = (singles, multis, classification)
    return {(families.get(sig, "unknown"), sig): value
            for sig, value in per_signature.items()
            if any(op_kind[1] == sig for op_kind in registered)}


def corpus_rows(connection: sqlite3.Connection) -> list[dict]:
    rows = []
    for row in connection.execute(
            "select s.id, s.article_id, s.strategy_description, s.example, "
            "s.key_moves_summary, s.mathematical_domain, a.bibtex_key "
            "from strategy_instances s left join articles a on a.id = s.article_id"):
        rows.append({
            "row_type": "strategy", "row_id": row[0], "article_id": row[1],
            "text": " ".join(str(x) for x in row[2:5] if x),
            "domain": row[5] or "", "bibtex_key": row[6] or "unattributed",
            "role": "productive_strategy"})
    for row in connection.execute(
            "select e.id, e.article_id, e.error_description, e.example, "
            "e.student_rule, e.mathematical_domain, a.bibtex_key "
            "from error_instances e left join articles a on a.id = e.article_id"):
        rows.append({
            "row_type": "misconception", "row_id": row[0], "article_id": row[1],
            "text": " ".join(str(x) for x in row[2:5] if x),
            "domain": row[5] or "", "bibtex_key": row[6] or "unattributed",
            "role": "deformation_misconception"})
    return rows


def score(row_text: str, singles: set[str], multis: set[str]) -> tuple[float, list[str]]:
    lowered = " " + " ".join(re.findall(r"[a-z]+", row_text.lower())) + " "
    words = content_words(row_text)
    matched: list[str] = []
    total = 0.0
    for term in sorted(multis):
        if f" {term} " in lowered:
            matched.append(term)
            total += 1.0 + 0.5 * (len(term.split()) - 1)
    hit_singles = sorted(singles & words)
    matched.extend(hit_singles)
    total += 0.5 * len(hit_singles)
    return total, matched


def build(output: pathlib.Path) -> dict:
    if not DB.exists():
        raise SystemExit(f"{DB} does not exist")
    connection = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
    try:
        already = {(op, kind) for op, kind in connection.execute(
            "select distinct operation, kind from automaton_instance_bindings")}
        rows = corpus_rows(connection)
    finally:
        connection.close()

    vocabulary = signature_vocabulary()
    unbound = {key: value for key, value in vocabulary.items()
               if (key[0], key[1]) not in already}

    proposals: list[dict] = []
    cross_domain: list[dict] = []
    unreached: list[str] = []
    for (family, signature), (singles, multis, classification) in sorted(unbound.items()):
        role = ("deformation_misconception" if classification == "deformation"
                else "productive_strategy")
        scored, crossed = [], []
        for row in rows:
            if row["role"] != role:
                continue
            value, matched = score(row["text"], singles, multis)
            if value < MIN_SCORE:
                continue
            if domain_agrees(row["domain"], family):
                scored.append((value, matched, row))
            else:
                crossed.append((value, matched, row, family, signature))
        for value, matched, row, fam, sig in sorted(
                crossed, key=lambda item: -item[0])[:2]:
            cross_domain.append({
                "family": fam, "signature": sig, "role": role,
                "row_type": row["row_type"], "row_id": row["row_id"],
                "score": round(value, 2), "row_domain": row["domain"],
                "evidence": matched[:8], "bibtex_key": row["bibtex_key"],
                "review_status": "proposed_domain_mismatch",
                "excerpt": row["text"][:200]})
        if not scored:
            unreached.append(f"{family}/{signature}")
            continue
        scored.sort(key=lambda item: (-item[0], item[2]["row_id"]))
        runner_up = scored[1][0] if len(scored) > 1 else 0.0
        for value, matched, row in scored[:MAX_PROPOSALS_PER_SIGNATURE]:
            proposals.append({
                "family": family, "signature": signature,
                "operation": family, "kind": signature, "role": role,
                "row_type": row["row_type"], "row_id": row["row_id"],
                "score": round(value, 2),
                "runner_up_score": round(runner_up, 2),
                "confidence": "high" if value >= 8 else "tentative",
                "evidence": matched[:12],
                "bibtex_key": row["bibtex_key"],
                "domain": row["domain"],
                "review_status": "proposed_unreviewed",
                "excerpt": row["text"][:240],
            })

    payload = {
        "schema_version": 1,
        "note": ("Proposals only. Nothing here is written to "
                 "automaton_instance_bindings, whose rows are reviewed and two of "
                 "which are human_rejected. Every row carries its score, the "
                 "vocabulary terms that earned it, the runner-up score for the "
                 "same signature, and an excerpt, so it can be read before it is "
                 "believed."),
        "signatures_already_bound": len(already),
        "signatures_registered_with_vocabulary": len(vocabulary),
        "signatures_proposed_for": len({(p["family"], p["signature"]) for p in proposals}),
        "signatures_unreached": unreached,
        "min_score": MIN_SCORE,
        "proposals": proposals,
        "cross_domain_candidates": cross_domain,
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, indent=1, sort_keys=True) + "\n",
                      encoding="utf-8")
    return {
        "proposals": len(proposals),
        "signatures_reached": payload["signatures_proposed_for"],
        "signatures_unreached": len(unreached),
        "already_bound": len(already),
        "registered_with_vocabulary": len(vocabulary),
        "high_confidence": sum(1 for p in proposals if p["confidence"] == "high"),
        "distinct_papers": len({p["bibtex_key"] for p in proposals}),
        "cross_domain_held_back": len(cross_domain),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=pathlib.Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    summary = build(args.output)
    print(f"wrote {args.output}")
    for key, value in summary.items():
        print(f"  {key:34s} {value}")
    print()
    print("Nothing was written to automaton_instance_bindings. Those rows are")
    print("reviewed; promoting these proposals into that table is a separate step.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
