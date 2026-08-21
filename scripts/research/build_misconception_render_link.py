#!/usr/bin/env python3
"""Join the render layer's 44 deformation ids to the misconception registry.

The render layer draws 44 named deformations -- 22 in
``representation_grammar.pl``'s ``deformation_spec_evidence/4``, 12 fraction
deformations and 7 decimal deformations in the two ``*_action_pairs.pl``
strategy modules, and 4 equipartition-failure kinds in
``parametric_fraction_errors.pl`` (one id, ``cross_multiplication_rule_
without_ground``, is authored twice -- once as a grammar deformation, once as
a fraction-strategy deformation -- and counts once). The 2,448-name
misconception registry (``knowledge/misconceptions/misconception_registry.pl``)
is a disjoint vocabulary: exact name equality joins only 5 of the 44, and the
render side carries no ``standard(...)`` key the registry could join on
either. What both sides DO carry is literature citations -- the registry's
``citation(BibtexKey, Note)`` on every entry, and (for exactly one render
family) ``attested_deformations.pl``'s ``attested_transplant/5`` rows, which
were built FOR the hybridization deformations: they carry the same
``ForeignPrimitive``/``IllicitHost`` fields the grammar's hybridization
clauses put in their ``Evidence`` dict.

This builder re-derives the join from scratch every run:

  1. Recount the 44 ids by parsing the four defining files directly (not by
     trusting a cached number), and record each id's Representation -- a
     genuine ``representation_language/1`` atom for the 22 grammar ids, or one
     of three honestly-named family markers (``fraction_strategy``,
     ``decimal_strategy``, ``equipartition_failure``) for the ids whose
     defining predicate carries no Representation argument at all. These
     markers are NOT representation-grammar vocabulary and the generated file
     says so.

  2. Warrant a citation bibkey for a render id only when the bibkey is either
     (a) a literal bibkey-shaped atom inside that id's own clause text, or
     (b) a structured match: an ``attested_transplant/5`` row whose
     ForeignPrimitive or IllicitHost equals the field of the same name in one
     of the id's own ``deformation_spec_evidence/4`` clauses, or (c) an
     ``attested_representation_error/4`` row whose Pattern literally equals
     the render id (never the ``unspecified_error`` residual bucket, which by
     construction means no named pattern matched). Grepping the four
     defining files for bibkey-shaped atoms directly finds none: the
     citations live in the companion ``attested_*.pl`` files. Only path (b)
     produces anything in this corpus, and only for the hybridization family.

  3. Join a warranted (RenderId, Bibkey) pair to the registry only when a
     registry entry cites that same bibkey AND the entry's own target
     operation passes ``misconception_render_coverage:op_render_family/3``
     for the render id's Representation -- the same compatibility table the
     render-coverage report already uses to keep an op's family from
     colliding with an unrelated representation. ``too_vague`` registry names
     are excluded outright (2026-08 ruling: too_vague is never served as a
     misconception; see memory ``misconception-under-erasure.md``).

  4. Every id with no surviving link is recorded in
     ``misconception_render_unlinked/2`` with the reason the join stopped:
     no bibkey was ever warranted, the warranted bibkey(s) are not in the
     registry at all, or the registry does cite them but no candidate
     survives the family-compatibility filter.

The output licenses one claim only: "this drawing and this literature-
attested misconception cite the same source and share a representation
family." It is never equivalence and never a diagnosis. The ``authored``
lane in the ``via/1`` vocabulary is declared but never populated by this
builder -- it is schema left for a later, human-curated pass.

The output is deterministic and byte-compared by
``scripts/checks/misconception_render_link.py``.
"""

from __future__ import annotations

import argparse
import collections
import json
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
GRAMMAR = ROOT / "knowledge/strategies/render/representation_grammar.pl"
FRACTION_PAIRS = ROOT / "knowledge/strategies/math/fraction_action_pairs.pl"
DECIMAL_PAIRS = ROOT / "knowledge/strategies/math/decimal_action_pairs.pl"
PARAMETRIC_ERRORS = ROOT / "knowledge/strategies/render/parametric_fraction_errors.pl"
ATTESTED_DEFORMATIONS = ROOT / "knowledge/strategies/render/attested_deformations.pl"
COVERAGE = ROOT / "knowledge/strategies/render/misconception_render_coverage.pl"
PATHS_PL = ROOT / "paths.pl"
DEFAULT_OUTPUT = ROOT / "knowledge/strategies/render/misconception_render_link.pl"

GRAMMAR_REL = "knowledge/strategies/render/representation_grammar.pl"
FRACTION_PAIRS_REL = "knowledge/strategies/math/fraction_action_pairs.pl"
DECIMAL_PAIRS_REL = "knowledge/strategies/math/decimal_action_pairs.pl"
PARAMETRIC_ERRORS_REL = "knowledge/strategies/render/parametric_fraction_errors.pl"
ATTESTED_DEFORMATIONS_REL = "knowledge/strategies/render/attested_deformations.pl"

TOO_VAGUE = "too_vague"  # never served as a misconception; see the ruling cited above.

# The one id authored on both the grammar side (a deformation_spec_evidence/4
# clause) and the fraction-strategy side (a productive_fraction_deformation/3
# row). Any other cross-file name collision is a builder bug, not a known fact.
EXPECTED_CROSS_FILE_OVERLAP = "cross_multiplication_rule_without_ground"

EXPECTED_TOTAL = 44

BIBKEY_ATOM_RE = re.compile(
    r"'([A-Za-z]+_[A-Za-z][A-Za-z]*_[0-9]{4}_[A-Za-z][A-Za-z'\-]*)'"
)

# --- representation_grammar.pl: deformation_spec_evidence/4 ---------------
GRAMMAR_CLAUSE_START_RE = re.compile(r"(?m)^deformation_spec_evidence\(")
GRAMMAR_HEAD_RE = re.compile(
    r"^deformation_spec_evidence\(\s*\n?\s*([a-z][a-z0-9_]*)\s*,"
)
MISCONCEPTION_FIELD_RE = re.compile(r"misconception:\s*([a-z][a-z0-9_]*)")
FOREIGN_PRIMITIVE_FIELD_RE = re.compile(r"foreign_primitive:\s*([a-z][a-z0-9_]*)")
ILLICIT_HOST_FIELD_RE = re.compile(r"illicit_host:\s*([a-z][a-z0-9_]*)")

# --- the two *_action_pairs.pl strategy modules -----------------------------
PRODUCTIVE_DEFORMATION_RE_TEMPLATE = (
    r"{name}\(\s*(\w+)\s*,\s*(\w+)\s*,\s*(\w+)\s*\)\s*\."
)

# --- parametric_fraction_errors.pl: fraction_error_type/1 ------------------
FRACTION_ERROR_TYPE_RE = re.compile(
    r"(?m)^fraction_error_type\((\w+)(?:\([^()]*\))?\)\."
)

# --- attested_deformations.pl -----------------------------------------------
ATTESTED_TRANSPLANT_RE = re.compile(
    r"attested_transplant\((\w+), (\w+), (\w+), "
    r"'((?:[^'\\]|\\.)*)', '((?:[^'\\]|\\.)*)'\)\."
)
ATTESTED_ERROR_RE = re.compile(
    r"attested_representation_error\((\w+), (\w+), (\d+), \[(.*?)\]\)\.",
    re.DOTALL,
)
TAG_RE = re.compile(r"tag\('((?:[^'\\]|\\.)*)', '((?:[^'\\]|\\.)*)'\)")

# --- misconception_render_coverage.pl: op_render_family/3 ------------------
OP_RENDER_FAMILY_RE = re.compile(r"(?m)^op_render_family\((\w+),\s*(\w+),")

REGISTRY_DUMP_GOAL = (
    "use_module(library(http/json)), "
    "use_module(misconceptions(misconception_registry), "
    "[misconception_registry_entry/5]), "
    "findall(Name-Op-B, misconception_registry_entry(Name,Op,citation(B,_),_,_), Rows0), "
    "sort(Rows0, Rows), "
    "forall(member(Name-Op-B, Rows), "
    "(json_write_dict(current_output, _{name:Name, op:Op, bibkey:B}, [width(0)]), nl)), "
    "halt."
)


def pl_atom(text: str) -> str:
    """Quote as a Prolog atom, escaping backslashes and single quotes."""
    escaped = text.replace("\\", "\\\\").replace("'", "\\'")
    return f"'{escaped}'"


# =============================================================================
# Parsing the four defining files
# =============================================================================


def parse_grammar_deformations(text: str) -> list[dict]:
    """Every deformation_spec_evidence/4 clause definition (never the one call
    site inside render_spec_preserves_task/3, which is indented and so never
    matches the line-anchored clause-start pattern)."""
    starts = [m.start() for m in GRAMMAR_CLAUSE_START_RE.finditer(text)]
    records = []
    for index, start in enumerate(starts):
        end = starts[index + 1] if index + 1 < len(starts) else len(text)
        chunk = text[start:end]
        head = GRAMMAR_HEAD_RE.match(chunk)
        if not head:
            continue
        misconception = MISCONCEPTION_FIELD_RE.search(chunk)
        if not misconception:
            continue
        foreign = FOREIGN_PRIMITIVE_FIELD_RE.search(chunk)
        host = ILLICIT_HOST_FIELD_RE.search(chunk)
        line = text.count("\n", 0, start) + 1
        records.append(
            {
                "id": misconception.group(1),
                "representation": head.group(1),
                "foreign_primitive": foreign.group(1) if foreign else None,
                "illicit_host": host.group(1) if host else None,
                "line": line,
                "bibkeys_near_definition": sorted(set(BIBKEY_ATOM_RE.findall(chunk))),
            }
        )
    return records


def parse_productive_deformations(text: str, predicate_name: str) -> list[tuple[str, str, str]]:
    """(ProductiveKind, DeformationKind, Family) rows for one *_action_pairs.pl
    module's productive_*_deformation/3 table."""
    pattern = re.compile(PRODUCTIVE_DEFORMATION_RE_TEMPLATE.format(name=predicate_name))
    return pattern.findall(text)


def parse_fraction_error_types(text: str) -> list[str]:
    return FRACTION_ERROR_TYPE_RE.findall(text)


def parse_attested_transplants(text: str) -> list[tuple[str, str, str, str, str]]:
    return ATTESTED_TRANSPLANT_RE.findall(text)


def parse_attested_representation_errors(text: str) -> list[tuple[str, str, int, list[tuple[str, str]]]]:
    rows = []
    for language, pattern, figure_count, examples_text in ATTESTED_ERROR_RE.findall(text):
        examples = TAG_RE.findall(examples_text)
        rows.append((language, pattern, int(figure_count), examples))
    return rows


def parse_op_render_family(text: str) -> dict[str, set[str]]:
    mapping: dict[str, set[str]] = collections.defaultdict(set)
    for op, representation in OP_RENDER_FAMILY_RE.findall(text):
        mapping[op].add(representation)
    return mapping


def bibkeys_near_scope(text: str, scope_name: str) -> list[str]:
    """Whole-file bibkey-shaped-atom scan for a file with no clean per-clause
    boundary. Named per file so a nonzero find is traceable in the summary."""
    found = sorted(set(BIBKEY_ATOM_RE.findall(text)))
    return found


# =============================================================================
# The 44-id census
# =============================================================================


def add_new(census: dict[str, dict], render_id: str, representation: str,
            source_file: str, source_line: int | None) -> None:
    """Add a render id from a strategy-level source (fraction/decimal/
    parametric), which never carries multiple clauses for the same id the way
    a grammar deformation can. The one legitimate cross-file collision
    (cross_multiplication_rule_without_ground, already seated by the grammar
    pass) is skipped rather than merged, since the grammar side's
    representation (area_model) is the one this builder keeps; any OTHER
    collision is a builder bug or an unnoticed source-file rename."""
    if render_id in census:
        if render_id != EXPECTED_CROSS_FILE_OVERLAP:
            raise SystemExit(
                f"unexpected cross-file id collision for {render_id!r}: only "
                f"{EXPECTED_CROSS_FILE_OVERLAP!r} is a known cross-file id"
            )
        census[render_id]["sources"].append((source_file, source_line))
        return
    census[render_id] = {
        "id": render_id,
        "representation": representation,
        "sources": [(source_file, source_line)],
        "foreign_primitive_host_pairs": [],
    }


def build_census(grammar_records: list[dict], fraction_rows: list[tuple[str, str, str]],
                  decimal_rows: list[tuple[str, str, str]], error_types: list[str]
                  ) -> dict[str, dict]:
    census: dict[str, dict] = {}

    grammar_by_id: dict[str, list[dict]] = collections.defaultdict(list)
    for rec in grammar_records:
        grammar_by_id[rec["id"]].append(rec)

    for render_id, recs in sorted(grammar_by_id.items()):
        representations = {rec["representation"] for rec in recs}
        if len(representations) != 1:
            raise SystemExit(
                f"id {render_id!r} has inconsistent representations across "
                f"clauses: {sorted(representations)}"
            )
        representation = next(iter(representations))
        bibkeys_near_definition = sorted(
            {bibkey for rec in recs for bibkey in rec["bibkeys_near_definition"]}
        )
        census[render_id] = {
            "id": render_id,
            "representation": representation,
            "sources": [(GRAMMAR_REL, rec["line"]) for rec in recs],
            "foreign_primitive_host_pairs": sorted(
                {
                    (rec["foreign_primitive"], rec["illicit_host"])
                    for rec in recs
                    if rec["foreign_primitive"] and rec["illicit_host"]
                }
            ),
            "bibkeys_near_definition": bibkeys_near_definition,
        }

    for _productive, deformation, _family in sorted(fraction_rows):
        add_new(census, deformation, "fraction_strategy", FRACTION_PAIRS_REL, None)

    for _productive, deformation, _family in sorted(decimal_rows):
        add_new(census, deformation, "decimal_strategy", DECIMAL_PAIRS_REL, None)

    for error_type in sorted(set(error_types)):
        add_new(census, error_type, "equipartition_failure", PARAMETRIC_ERRORS_REL, None)

    if len(census) != EXPECTED_TOTAL:
        raise SystemExit(
            f"census has {len(census)} distinct render ids, expected {EXPECTED_TOTAL}"
        )
    return census


# =============================================================================
# Citation warrant
# =============================================================================


def compute_citations(census: dict[str, dict], transplants: list[tuple[str, str, str, str, str]],
                       attested_errors: list[tuple[str, str, int, list[tuple[str, str]]]]
                       ) -> list[dict]:
    citations: list[dict] = []

    # (a) bibkey-shaped atoms literally inside an id's own clause text.
    for render_id, record in sorted(census.items()):
        for bibkey in record.get("bibkeys_near_definition", []):
            citations.append(
                {
                    "id": render_id,
                    "bibkey": bibkey,
                    "source_file": GRAMMAR_REL,
                    "evidence": f"header_comment(line({record['sources'][0][1]}))",
                }
            )

    # (b) attested_transplant/5 rows matched on ForeignPrimitive or IllicitHost
    # against any of the render id's own hybridization clauses.
    hybridization_ids = {
        render_id: record["foreign_primitive_host_pairs"]
        for render_id, record in census.items()
        if record["foreign_primitive_host_pairs"]
    }
    for language, foreign, host, bibkey, figure in transplants:
        matched: dict[str, set[str]] = collections.defaultdict(set)
        for render_id, pairs in hybridization_ids.items():
            for clause_foreign, clause_host in pairs:
                fields = set()
                if clause_foreign == foreign:
                    fields.add("foreign_primitive")
                if clause_host == host:
                    fields.add("illicit_host")
                if fields:
                    matched[render_id] |= fields
        for render_id in sorted(matched):
            fields = sorted(matched[render_id])
            evidence = (
                "attested_transplant_row("
                f"{language}, {foreign}, {host}, {pl_atom(figure)}, "
                f"matched_on([{', '.join(fields)}]))"
            )
            citations.append(
                {
                    "id": render_id,
                    "bibkey": bibkey,
                    "source_file": ATTESTED_DEFORMATIONS_REL,
                    "evidence": evidence,
                }
            )

    # (c) attested_representation_error/4 rows whose Pattern literally equals
    # a render id -- never the unspecified_error residual bucket.
    census_ids = set(census)
    for language, pattern, figure_count, examples in attested_errors:
        if pattern == "unspecified_error":
            continue
        if pattern not in census_ids or figure_count <= 0:
            continue
        for bibkey, figure in examples:
            evidence = (
                "attested_representation_error_row("
                f"{language}, {pattern}, {figure_count}, {pl_atom(figure)})"
            )
            citations.append(
                {
                    "id": pattern,
                    "bibkey": bibkey,
                    "source_file": ATTESTED_DEFORMATIONS_REL,
                    "evidence": evidence,
                }
            )

    deduped = {(c["id"], c["bibkey"], c["source_file"], c["evidence"]) for c in citations}
    return [
        {"id": i, "bibkey": b, "source_file": f, "evidence": e}
        for (i, b, f, e) in sorted(deduped)
    ]


# =============================================================================
# Registry join
# =============================================================================


def load_registry_rows() -> list[tuple[str, str, str]]:
    completed = subprocess.run(
        ["swipl", "-q", "-l", str(PATHS_PL), "-g", REGISTRY_DUMP_GOAL],
        cwd=ROOT, capture_output=True, text=True, timeout=300,
    )
    if completed.returncode != 0:
        raise SystemExit(
            f"registry dump failed (exit {completed.returncode}):\n{completed.stderr}"
        )
    rows = []
    for line in completed.stdout.splitlines():
        line = line.strip()
        if not line:
            continue
        row = json.loads(line)
        rows.append((row["name"], row["op"], row["bibkey"]))
    if not rows:
        raise SystemExit("registry dump produced zero rows")
    return sorted(set(rows))


def compute_links_and_unlinked(
    census: dict[str, dict],
    citations: list[dict],
    registry_rows: list[tuple[str, str, str]],
    op_render_family: dict[str, set[str]],
) -> tuple[list[tuple[str, str, str]], list[tuple[str, str, str | None]]]:
    registry_names = {name for name, _op, _bibkey in registry_rows}
    registry_by_bibkey: dict[str, list[tuple[str, str]]] = collections.defaultdict(list)
    for name, op, bibkey in registry_rows:
        registry_by_bibkey[bibkey].append((name, op))

    citations_by_id: dict[str, list[str]] = collections.defaultdict(list)
    for c in citations:
        citations_by_id[c["id"]].append(c["bibkey"])

    links: list[tuple[str, str, str]] = []
    unlinked: list[tuple[str, str, str | None]] = []

    for render_id in sorted(census):
        representation = census[render_id]["representation"]
        row_links: set[tuple[str, str, str]] = set()

        if render_id in registry_names and render_id != TOO_VAGUE:
            row_links.add((render_id, render_id, "name_equality"))

        bibkeys = sorted(set(citations_by_id.get(render_id, [])))
        any_registry_hit = False
        for bibkey in bibkeys:
            candidates = registry_by_bibkey.get(bibkey, [])
            if candidates:
                any_registry_hit = True
            for name, op in candidates:
                if name == TOO_VAGUE:
                    continue
                if representation in op_render_family.get(op, set()):
                    row_links.add((render_id, name, f"bibkey({bibkey})"))

        if row_links:
            links.extend(sorted(row_links))
            continue

        if not bibkeys:
            unlinked.append((render_id, "no_bibkey_in_source", None))
        elif not any_registry_hit:
            unlinked.append((render_id, "bibkey_not_in_registry", bibkeys[0]))
        else:
            informative = [
                bibkey for bibkey in bibkeys
                if any(name != TOO_VAGUE for name, _op in registry_by_bibkey.get(bibkey, []))
            ]
            representative = informative[0] if informative else bibkeys[0]
            unlinked.append((render_id, "prefilter_rejected", representative))

    return links, unlinked


# =============================================================================
# Prolog rendering
# =============================================================================


PROLOG_HEADER = """\
% Generated by scripts/research/build_misconception_render_link.py from
% knowledge/strategies/render/representation_grammar.pl,
% knowledge/strategies/math/fraction_action_pairs.pl,
% knowledge/strategies/math/decimal_action_pairs.pl,
% knowledge/strategies/render/parametric_fraction_errors.pl,
% knowledge/strategies/render/attested_deformations.pl, and a live query
% against knowledge/misconceptions/misconception_registry.pl.
% Do not hand-edit; edit the builder and regenerate.
%
% WHAT THIS JOINS. The render layer's 44 deformation ids and the misconception
% registry's 2,448 names share no key: standards are a dead key (disjoint
% namespaces), and exact name equality joins only 5. Every registry entry
% carries citation(BibtexKey, Note); a handful of the render side's companion
% attested_*.pl files carry the same bibkeys, structured so a render id's own
% fields (foreign_primitive / illicit_host on the hybridization clauses; the
% Pattern a corpus figure was classified under) can be matched against them.
% Where that match is warranted AND the registry name's own target operation
% passes the render-coverage report's own representation-family compatibility
% table (op_render_family/3), the two sides are joined.
%
% WHAT THE LINK LICENSES, AND WHAT IT DOES NOT. A row here says: this drawing
% and this literature-attested misconception cite the same source and share a
% representation family. It is NEVER equivalence, and it is NEVER a diagnosis
% -- the render id is a computed scene, the registry name is a literature
% attestation, and citing the same paper does not make them the same claim.
%
% too_vague NEVER LINKS. A number of registry entries carry the sentinel name
% too_vague (misconception-under-erasure ruling, 2026-08: viability not
% deficit, too_vague never served). Those names are excluded from every join
% here regardless of citation or family match.
%
% THREE REPRESENTATION MARKERS ARE NOT GRAMMAR VOCABULARY. 22 of the 44 ids
% come from representation_grammar.pl's deformation_spec_evidence/4 and carry
% a genuine representation_language/1 atom. The other 22 (12 fraction-strategy
% deformations, 7 decimal-strategy deformations, 4 equipartition-failure
% kinds, minus the one id authored on both the grammar and fraction-strategy
% side) come from predicates with no Representation argument at all --
% productive_fraction_deformation/3, productive_decimal_deformation/3,
% fraction_error_type/1. Those ids carry one of fraction_strategy,
% decimal_strategy, or equipartition_failure instead: honestly-named markers
% for "no representation-grammar atom applies," not entries in
% representation_language/1. op_render_family/3 has no row for any of the
% three, so no bibkey warranted for those ids can ever pass the compatibility
% filter -- which is exactly what happened this pass: they are all
% no_bibkey_in_source besides.
%
% NO authored rows this pass. via(authored) is declared in the vocabulary
% below for a later, human-curated pass; this builder never emits one.
"""


def render_module(citations: list[dict], links: list[tuple[str, str, str]],
                   unlinked: list[tuple[str, str, str | None]], census: dict[str, dict]) -> str:
    lines: list[str] = []
    write = lines.append
    write(PROLOG_HEADER)
    write(":- module(misconception_render_link,")
    write("          [ render_deformation_citation/3,")
    write("            misconception_render_link/3,")
    write("            misconception_render_unlinked/2,")
    write("            misconception_render_link_summary/1,")
    write("            check_misconception_render_link/0")
    write("          ]).")
    write("")
    write(":- use_module(render(representation_grammar)).")
    write(":- use_module(math(fraction_action_pairs), [productive_fraction_deformation/3]).")
    write(":- use_module(math(decimal_action_pairs), [productive_decimal_deformation/3]).")
    write(":- use_module(render(parametric_fraction_errors), [fraction_error_type/1]).")
    write(":- use_module(render(attested_deformations), [attested_transplant/5]).")
    write(":- use_module(render(misconception_render_coverage), [op_render_family/3]).")
    write(":- use_module(misconceptions(misconception_registry),")
    write("              [ misconception_registry_entry/5 ]).")
    write(":- use_module(library(pairs)).")
    write(":- use_module(library(lists)).")
    write(":- use_module(library(aggregate)).")
    write("")

    write("% --- render_deformation_citation(RenderId, Bibkey, source(File, Evidence)) -")
    write("% One row per (render id, bibkey) the render side can WARRANT: the bibkey")
    write("% is a literal atom near the id's own clause, or a structured match against")
    write("% attested_deformations.pl's attested_transplant/5 or")
    write("% attested_representation_error/4 tables (see the module header).")
    for citation in citations:
        write(
            f"render_deformation_citation({citation['id']}, "
            f"{pl_atom(citation['bibkey'])},"
        )
        write(f"    source({pl_atom(citation['source_file'])}, {citation['evidence']})).")
    write("")

    write("% --- misconception_render_link(RenderId, RegistryName, via(V)) -------------")
    write("% V in {name_equality, bibkey(Bibkey), authored}. too_vague never appears as")
    write("% RegistryName. authored is declared and never emitted by this builder.")
    for render_id, name, via in links:
        write(f"misconception_render_link({render_id}, {name}, via({via})).")
    write("")

    write("% --- misconception_render_unlinked(RenderId, reason(R)) --------------------")
    write("% R in {no_bibkey_in_source, bibkey_not_in_registry, prefilter_rejected(K)}.")
    write("% This absence list is itself the finding: the render layer and the")
    write("% registry are, for almost all of the 44, genuinely unjoined vocabularies.")
    for render_id, reason, arg in unlinked:
        if reason == "prefilter_rejected":
            write(f"misconception_render_unlinked({render_id}, reason(prefilter_rejected({pl_atom(arg)}))).")
        elif reason == "bibkey_not_in_registry":
            write(f"misconception_render_unlinked({render_id}, reason(bibkey_not_in_registry)).")
        else:
            write(f"misconception_render_unlinked({render_id}, reason(no_bibkey_in_source)).")
    write("")

    write(CHECK_LOGIC_BLOCK)
    return "\n".join(lines) + "\n"


CHECK_LOGIC_BLOCK = '''\
% =============================================================================
% Independent re-derivation. check_misconception_render_link/0 recomputes the
% 44-id census and the citation/link/unlinked verdicts from the SAME live
% predicates the builder read (never by re-reading this file's own data as if
% it were ground truth), and fails loudly on any disagreement.
% =============================================================================

%!  body_evidence_dict(+Body, +EvidenceVar, -Dict) is semidet.
%
%   Walk a clause body's syntax tree (never execute it) for the top-level
%   ``EvidenceVar = _{...}`` goal every deformation_spec_evidence/4 clause
%   ends with. Several clauses compute their Evidence dict's numeric values
%   (wrong_answer, correct_answer, ...) from Spec-carried operands that are
%   NOT bound when this predicate is read via clause/2 -- calling those
%   clauses instead of reading them throws instantiation errors deep inside
%   their arithmetic (confirmed live: fraction_arith_componentwise's `WrongN
%   is NA + NB` with NA/NB unbound). Reading the clause's own source
%   structure sidesteps that: the dict literal is already a constructed dict
%   term at clause-compile time, whether or not its numeric fields are bound.
body_evidence_dict((A, B), Var, Dict) :-
    !,
    ( body_evidence_dict(A, Var, Dict) -> true ; body_evidence_dict(B, Var, Dict) ).
body_evidence_dict(Var = Dict, Var, Dict) :-
    is_dict(Dict),
    !.

%!  census_grammar_id(-Id, -Representation, -ForeignPrimitive, -IllicitHost)
%!      is nondet.
%
%   A handful of clauses (the four hybridization ones) have a fully-ground
%   Evidence dict -- every field, including the Task-carried ones, is a bare
%   atom with no clause-local variable in it. SWI's clause compiler resolves
%   ``Evidence = GroundDict`` at compile time for those and folds the dict
%   into the HEAD unification itself, leaving Body = true and EvidenceVar
%   already bound when clause/2 returns. Every other clause's Evidence dict
%   carries at least one Spec-derived variable (a wrong_answer, a
%   correct_answer, ...), so its body stays live and EvidenceVar arrives
%   unbound -- handle both.
census_grammar_id(Id, Representation, ForeignPrimitive, IllicitHost) :-
    clause(representation_grammar:deformation_spec_evidence(Representation, _Spec, _Task, EvidenceVar),
           Body),
    ( is_dict(EvidenceVar)
    -> Evidence = EvidenceVar
    ;  body_evidence_dict(Body, EvidenceVar, Evidence)
    ),
    get_dict(misconception, Evidence, Id),
    ( get_dict(foreign_primitive, Evidence, FP) -> ForeignPrimitive = FP ; ForeignPrimitive = none ),
    ( get_dict(illicit_host, Evidence, IH) -> IllicitHost = IH ; IllicitHost = none ).

grammar_ids(Ids) :-
    findall(Id, census_grammar_id(Id, _, _, _), Ids0),
    sort(Ids0, Ids).

grammar_id_representation(Id, Representation) :-
    findall(Rep, census_grammar_id(Id, Rep, _, _), Reps0),
    sort(Reps0, Reps),
    ( Reps = [Representation]
    -> true
    ;  throw(error(inconsistent_representation(Id, Reps), _))
    ).

fraction_strategy_ids(Ids) :-
    findall(Id, fraction_action_pairs:productive_fraction_deformation(_, Id, _), Ids0),
    sort(Ids0, Ids).

decimal_strategy_ids(Ids) :-
    findall(Id, decimal_action_pairs:productive_decimal_deformation(_, Id, _), Ids0),
    sort(Ids0, Ids).

equipartition_ids(Ids) :-
    findall(Id,
            ( parametric_fraction_errors:fraction_error_type(Raw),
              ( compound(Raw) -> functor(Raw, Id, _) ; Id = Raw )
            ),
            Ids0),
    sort(Ids0, Ids).

%!  recomputed_census(-Pairs) is det.
%
%   Pairs is a sorted list of Id-Representation, independently recomputed
%   from the four defining predicates. Never read from this file's own
%   facts.
recomputed_census(Pairs) :-
    grammar_ids(GrammarIds),
    maplist(grammar_id_representation, GrammarIds, GrammarReps),
    pairs_keys_values(GrammarPairs, GrammarIds, GrammarReps),

    fraction_strategy_ids(FractionIds0),
    subtract(FractionIds0, GrammarIds, FractionIdsNew),
    length(FractionIdsNew, FN),
    length(FractionRepsNew, FN),
    maplist(=(fraction_strategy), FractionRepsNew),
    pairs_keys_values(FractionPairs, FractionIdsNew, FractionRepsNew),

    decimal_strategy_ids(DecimalIds0),
    subtract(DecimalIds0, GrammarIds, DecimalIdsNew),
    length(DecimalIdsNew, DN),
    length(DecimalRepsNew, DN),
    maplist(=(decimal_strategy), DecimalRepsNew),
    pairs_keys_values(DecimalPairs, DecimalIdsNew, DecimalRepsNew),

    equipartition_ids(EquipartitionIds0),
    subtract(EquipartitionIds0, GrammarIds, EquipartitionIdsNew),
    length(EquipartitionIdsNew, EN),
    length(EquipartitionRepsNew, EN),
    maplist(=(equipartition_failure), EquipartitionRepsNew),
    pairs_keys_values(EquipartitionPairs, EquipartitionIdsNew, EquipartitionRepsNew),

    append([GrammarPairs, FractionPairs, DecimalPairs, EquipartitionPairs], Pairs0),
    sort(Pairs0, Pairs).

%!  check_citation_warrant(+Id, +Bibkey, +File, +Evidence) is det.
%
%   Throws unless the citation is real: the file is the one companion store
%   this pass ever cites, and a structured attested_transplant_row Evidence
%   term names an actual attested_transplant/5 fact whose matched fields
%   really do equal the fields of one of Id's own grammar clauses.
check_citation_warrant(Id, _Bibkey, File, _Evidence) :-
    File \\== 'knowledge/strategies/render/attested_deformations.pl',
    !,
    throw(error(citation_bad_file(Id, File), _)).
check_citation_warrant(Id, Bibkey,
                       'knowledge/strategies/render/attested_deformations.pl',
                       attested_transplant_row(Language, ForeignPrimitive, IllicitHost,
                                                Figure, matched_on(Fields))) :-
    !,
    ( attested_deformations:attested_transplant(Language, ForeignPrimitive, IllicitHost,
                                                 Bibkey, Figure)
    -> true
    ;  throw(error(citation_transplant_not_a_fact(Id, Bibkey), _))
    ),
    ( Fields == [] -> throw(error(citation_no_matched_fields(Id, Bibkey), _)) ; true ),
    ( forall(member(Field, Fields), memberchk(Field, [foreign_primitive, illicit_host]))
    -> true
    ;  throw(error(citation_bad_matched_field(Id, Bibkey, Fields), _))
    ),
    ( memberchk(foreign_primitive, Fields)
    -> ( census_grammar_id(Id, _, ForeignPrimitive, _) -> true
       ;  throw(error(citation_foreign_primitive_mismatch(Id, Bibkey), _))
       )
    ;  true
    ),
    ( memberchk(illicit_host, Fields)
    -> ( census_grammar_id(Id, _, _, IllicitHost) -> true
       ;  throw(error(citation_illicit_host_mismatch(Id, Bibkey), _))
       )
    ;  true
    ).
check_citation_warrant(Id, Bibkey,
                       'knowledge/strategies/render/attested_deformations.pl',
                       attested_representation_error_row(Language, Pattern, FigureCount, Figure)) :-
    !,
    ( Pattern == Id -> true ; throw(error(citation_pattern_mismatch(Id, Bibkey), _)) ),
    ( Pattern == unspecified_error
    -> throw(error(citation_residual_bucket_used(Id, Bibkey), _))
    ;  true
    ),
    ( attested_deformations:attested_representation_error(Language, Pattern, FigureCount, Examples),
      memberchk(tag(Bibkey, Figure), Examples)
    -> true
    ;  throw(error(citation_error_row_not_a_fact(Id, Bibkey), _))
    ).
check_citation_warrant(Id, Bibkey, _File, Evidence) :-
    throw(error(citation_unrecognized_evidence(Id, Bibkey, Evidence), _)).

%!  check_link_warrant(+Census, +Id, +Name, +Via) is det.
check_link_warrant(_Census, Id, Name, name_equality) :-
    !,
    ( Id == Name -> true ; throw(error(link_name_equality_mismatch(Id, Name), _)) ),
    ( Name == too_vague -> throw(error(link_names_too_vague(Id), _)) ; true ),
    ( misconception_registry:misconception_registry_entry(Name, _, _, _, _)
    -> true
    ;  throw(error(link_name_not_in_registry(Id, Name), _))
    ).
check_link_warrant(Census, Id, Name, bibkey(Bibkey)) :-
    !,
    ( Name == too_vague -> throw(error(link_names_too_vague(Id), _)) ; true ),
    ( render_deformation_citation(Id, Bibkey, _)
    -> true
    ;  throw(error(link_bibkey_not_cited(Id, Bibkey), _))
    ),
    ( misconception_registry:misconception_registry_entry(Name, Op, citation(Bibkey, _), _, _)
    -> true
    ;  throw(error(link_bibkey_registry_mismatch(Id, Name, Bibkey), _))
    ),
    ( memberchk(Id-Representation, Census) -> true
    ; throw(error(link_id_not_in_census(Id), _))
    ),
    ( misconception_render_coverage:op_render_family(Op, Representation, _)
    -> true
    ;  throw(error(link_prefilter_fails(Id, Name, Op, Representation), _))
    ).
check_link_warrant(_Census, Id, Name, authored) :-
    !,
    throw(error(unexpected_authored_link(Id, Name), _)).
check_link_warrant(_Census, Id, Name, Via) :-
    throw(error(link_bad_via(Id, Name, Via), _)).

%!  check_unlinked_warrant(+Census, +Id, +Reason) is det.
check_unlinked_warrant(_Census, Id, no_bibkey_in_source) :-
    !,
    ( \\+ render_deformation_citation(Id, _, _)
    -> true
    ;  throw(error(unlinked_reason_wrong(Id, no_bibkey_in_source), _))
    ).
check_unlinked_warrant(_Census, Id, bibkey_not_in_registry) :-
    !,
    findall(B, render_deformation_citation(Id, B, _), Bibkeys),
    ( Bibkeys == [] -> throw(error(unlinked_reason_wrong(Id, bibkey_not_in_registry), _)) ; true ),
    ( forall(member(B, Bibkeys),
             \\+ misconception_registry:misconception_registry_entry(_, _, citation(B, _), _, _))
    -> true
    ;  throw(error(unlinked_reason_wrong(Id, bibkey_not_in_registry), _))
    ).
check_unlinked_warrant(Census, Id, prefilter_rejected(K)) :-
    !,
    ( render_deformation_citation(Id, K, _)
    -> true
    ;  throw(error(unlinked_prefilter_bibkey_not_cited(Id, K), _))
    ),
    ( memberchk(Id-Representation, Census) -> true
    ; throw(error(unlinked_id_not_in_census(Id), _))
    ),
    findall(B, render_deformation_citation(Id, B, _), Bibkeys),
    findall(Name-Op,
            ( member(B, Bibkeys),
              misconception_registry:misconception_registry_entry(Name, Op, citation(B, _), _, _),
              Name \\== too_vague
            ),
            Candidates),
    ( forall(member(_Name-Op, Candidates),
             \\+ misconception_render_coverage:op_render_family(Op, Representation, _))
    -> true
    ;  throw(error(unlinked_reason_wrong(Id, prefilter_rejected(K)), _))
    ).
check_unlinked_warrant(_Census, Id, Reason) :-
    throw(error(unlinked_bad_reason(Id, Reason), _)).

%!  misconception_render_link_summary(-Summary) is det.
misconception_render_link_summary(Summary) :-
    findall(_, render_deformation_citation(_, _, _), CitationRows),
    length(CitationRows, CitationRowCount),
    findall(Id, render_deformation_citation(Id, _, _), CitedIds0), sort(CitedIds0, CitedIds),
    length(CitedIds, CitedIdCount),

    findall(_, misconception_render_link(_, _, _), LinkRows),
    length(LinkRows, LinkRowCount),
    findall(Id, misconception_render_link(Id, _, _), LinkedIds0), sort(LinkedIds0, LinkedIds),
    length(LinkedIds, LinkedIdCount),
    aggregate_all(count, misconception_render_link(_, _, via(name_equality)), NameEqualityRows),
    aggregate_all(count, misconception_render_link(_, _, via(bibkey(_))), BibkeyRows),
    aggregate_all(count, misconception_render_link(_, _, via(authored)), AuthoredRows),

    findall(Id, misconception_render_unlinked(Id, _), UnlinkedIds0), sort(UnlinkedIds0, UnlinkedIds),
    length(UnlinkedIds, UnlinkedIdCount),
    aggregate_all(count, misconception_render_unlinked(_, reason(no_bibkey_in_source)), NoBibkeyCount),
    aggregate_all(count, misconception_render_unlinked(_, reason(bibkey_not_in_registry)), NotInRegistryCount),
    aggregate_all(count, misconception_render_unlinked(_, reason(prefilter_rejected(_))), PrefilterCount),

    Summary = _{
        total_render_ids: 44,
        citation_rows: CitationRowCount,
        render_ids_with_citations: CitedIdCount,
        link_rows: LinkRowCount,
        linked_render_ids: LinkedIdCount,
        link_rows_by_via: _{ name_equality: NameEqualityRows,
                              bibkey: BibkeyRows,
                              authored: AuthoredRows },
        unlinked_render_ids: UnlinkedIdCount,
        unlinked_by_reason: _{ no_bibkey_in_source: NoBibkeyCount,
                                bibkey_not_in_registry: NotInRegistryCount,
                                prefilter_rejected: PrefilterCount }
    }.

%!  check_misconception_render_link is det.
%
%   Re-derives every claim in this file from the live predicates and throws
%   on the first disagreement. Prints a PASS line and the summary on success.
check_misconception_render_link :-
    recomputed_census(Census),
    length(Census, CensusCount),
    ( CensusCount =:= 44 -> true ; throw(error(census_count_mismatch(CensusCount), _)) ),
    pairs_keys(Census, CensusIds),

    forall(render_deformation_citation(Id, _, _),
           ( memberchk(Id, CensusIds) -> true ; throw(error(citation_unknown_id(Id), _)) )),
    forall(misconception_render_link(Id, _, _),
           ( memberchk(Id, CensusIds) -> true ; throw(error(link_unknown_id(Id), _)) )),
    forall(misconception_render_unlinked(Id, _),
           ( memberchk(Id, CensusIds) -> true ; throw(error(unlinked_unknown_id(Id), _)) )),

    findall(Id, misconception_render_link(Id, _, _), LinkedIds0), sort(LinkedIds0, LinkedIds),
    findall(Id, misconception_render_unlinked(Id, _), UnlinkedIds0), sort(UnlinkedIds0, UnlinkedIds),
    ord_union(LinkedIds, UnlinkedIds, AllCovered),
    ( AllCovered == CensusIds -> true ; throw(error(census_not_partitioned, _)) ),
    ord_intersection(LinkedIds, UnlinkedIds, Overlap),
    ( Overlap == [] -> true ; throw(error(id_both_linked_and_unlinked(Overlap), _)) ),

    forall(render_deformation_citation(Id, Bibkey, source(File, Evidence)),
           check_citation_warrant(Id, Bibkey, File, Evidence)),
    forall(misconception_render_link(Id, Name, via(V)),
           check_link_warrant(Census, Id, Name, V)),
    forall(misconception_render_unlinked(Id, reason(R)),
           check_unlinked_warrant(Census, Id, R)),

    misconception_render_link_summary(Summary),
    get_dict(linked_render_ids, Summary, SummaryLinked),
    get_dict(unlinked_render_ids, Summary, SummaryUnlinked),
    length(LinkedIds, SummaryLinked),
    length(UnlinkedIds, SummaryUnlinked),
    SummaryLinked + SummaryUnlinked =:= 44,

    format("PASS check_misconception_render_link: ~w render ids, ~w linked, ~w unlinked~n",
           [CensusCount, SummaryLinked, SummaryUnlinked]),
    format("  citation rows: ~w over ~w render ids~n",
           [Summary.citation_rows, Summary.render_ids_with_citations]),
    format("  link rows by via: ~q~n", [Summary.link_rows_by_via]),
    format("  unlinked by reason: ~q~n", [Summary.unlinked_by_reason]).
'''


# =============================================================================
# Driver
# =============================================================================


def build(output: pathlib.Path) -> dict:
    for path in (GRAMMAR, FRACTION_PAIRS, DECIMAL_PAIRS, PARAMETRIC_ERRORS,
                 ATTESTED_DEFORMATIONS, COVERAGE):
        if not path.exists():
            raise SystemExit(f"{path} does not exist")

    grammar_text = GRAMMAR.read_text(encoding="utf-8")
    fraction_text = FRACTION_PAIRS.read_text(encoding="utf-8")
    decimal_text = DECIMAL_PAIRS.read_text(encoding="utf-8")
    parametric_text = PARAMETRIC_ERRORS.read_text(encoding="utf-8")
    attested_text = ATTESTED_DEFORMATIONS.read_text(encoding="utf-8")
    coverage_text = COVERAGE.read_text(encoding="utf-8")

    grammar_records = parse_grammar_deformations(grammar_text)
    fraction_rows = parse_productive_deformations(
        fraction_text, "productive_fraction_deformation"
    )
    decimal_rows = parse_productive_deformations(
        decimal_text, "productive_decimal_deformation"
    )
    error_types = parse_fraction_error_types(parametric_text)

    if len(fraction_rows) != 12:
        raise SystemExit(f"expected 12 productive_fraction_deformation/3 rows, found {len(fraction_rows)}")
    if len(decimal_rows) != 7:
        raise SystemExit(f"expected 7 productive_decimal_deformation/3 rows, found {len(decimal_rows)}")
    if len(set(error_types)) != 4:
        raise SystemExit(f"expected 4 fraction_error_type/1 ids, found {len(set(error_types))}")

    census = build_census(grammar_records, fraction_rows, decimal_rows, error_types)

    # Whole-file bibkey scans for the three files with no clean per-clause
    # boundary. (Grammar ids are already scanned per-clause in
    # parse_grammar_deformations; these three are a defensive superset check
    # that never restricts to a single id.)
    stray_bibkeys = {
        FRACTION_PAIRS_REL: bibkeys_near_scope(fraction_text, "fraction_action_pairs"),
        DECIMAL_PAIRS_REL: bibkeys_near_scope(decimal_text, "decimal_action_pairs"),
        PARAMETRIC_ERRORS_REL: bibkeys_near_scope(parametric_text, "parametric_fraction_errors"),
    }

    transplants = parse_attested_transplants(attested_text)
    attested_errors = parse_attested_representation_errors(attested_text)
    op_render_family = parse_op_render_family(coverage_text)

    citations = compute_citations(census, transplants, attested_errors)
    registry_rows = load_registry_rows()
    links, unlinked = compute_links_and_unlinked(census, citations, registry_rows, op_render_family)

    if len(links) + len(unlinked) < len(census):
        raise SystemExit("some render id produced neither a link nor an unlinked row")
    linked_ids = {render_id for render_id, _name, _via in links}
    unlinked_ids = {render_id for render_id, _reason, _arg in unlinked}
    if linked_ids & unlinked_ids:
        raise SystemExit(f"ids both linked and unlinked: {sorted(linked_ids & unlinked_ids)}")
    if (linked_ids | unlinked_ids) != set(census):
        raise SystemExit("linked + unlinked ids do not cover the 44-id census")

    text = render_module(citations, links, unlinked, census)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(text, encoding="utf-8")

    via_counts = collections.Counter(via.split("(")[0] for _id, _name, via in links)
    reason_counts = collections.Counter(reason for _id, reason, _arg in unlinked)
    return {
        "render_ids": len(census),
        "citation_rows": len(citations),
        "render_ids_with_citations": len({c["id"] for c in citations}),
        "link_rows": len(links),
        "linked_render_ids": len(linked_ids),
        "link_rows_by_via": dict(via_counts),
        "unlinked_render_ids": len(unlinked_ids),
        "unlinked_by_reason": dict(reason_counts),
        "stray_bibkeys_found": {k: v for k, v in stray_bibkeys.items() if v},
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=pathlib.Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    summary = build(args.output)
    print(f"wrote {args.output}")
    for key, value in summary.items():
        print(f"  {key:28s} {value}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
