#!/usr/bin/env python3
"""Export the MUA + grounding-metaphor registry as JSON for the MUD page.

The HTML page at ``more-zeeman/muds.html`` renders Meaning-Use Diagrams from a
pre-extracted JSON file rather than calling Prolog at request time. This script
runs swipl in batch mode, queries the two registries that hold the data
(``formal/pml/mua_relations.pl`` and ``formal/formalization/grounding_metaphors.pl``), and
writes a single JSON object to ``more-zeeman/mua_data.json``.

The JSON schema is documented in the page; the keys correspond one-to-one to
Prolog predicates. The script is idempotent: running it again will produce
byte-for-byte identical output (modulo Prolog's discovery order, which is
sorted in the output for stability).

The shipped ``data/research/research_shared.db`` is a complete copy of the source
database: the export audit found no full-text carrier tables or columns, so
none were dropped. Article abstracts remain as bibliographic metadata; coded
fields, short summaries, and page-anchored quotations are derivative records.
This script opens that database read-only and checks its integrity before
regenerating the Prolog-backed MUA snapshot.

Usage:
  python3 scripts/research/export_mua_for_mud.py
  python3 scripts/research/export_mua_for_mud.py --check

``--check`` does not write; it loads the current JSON, regenerates a fresh
extract, and exits with status 0 only when they match. The harness can use
that to detect drift between code and the static export.
"""
import argparse
import json
import sqlite3
import subprocess
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
OUT_PATH = REPO_ROOT / "more-zeeman" / "mua_data.json"
PATHS_PL = REPO_ROOT / "paths.pl"
RESEARCH_DB = REPO_ROOT / "data" / "research" / "research_shared.db"


# Prolog extractor script content. The Prolog code prints lines of the form
# ``KEY|TERM`` for each fact, terminated by a single line ``__END__``. We parse
# the lines in Python because swipl's JSON library output across module
# boundaries is finicky and the line protocol is trivial and stable.
PROLOG_SCRIPT = r"""
:- use_module(pml(mua_relations)).
:- use_module('{root}/formal/formalization/grounding_metaphors.pl').

emit(Key, Term) :-
    format('~w|~q~n', [Key, Term]).

run :-
    forall(mua_relations:practice(P, D), emit(practice, P-D)),
    forall(mua_relations:vocabulary(V, D), emit(vocabulary, V-D)),
    forall(mua_relations:practice_kind(P, O, K), emit(practice_kind, P-O-K)),
    forall(mua_relations:pv_sufficient(P, V), emit(pv_sufficient, P-V)),
    forall(mua_relations:vp_sufficient(V, P), emit(vp_sufficient, V-P)),
    forall(mua_relations:pp_necessary(B, E), emit(pp_necessary, B-E)),
    forall(mua_relations:pp_sufficient(B, E, M), emit(pp_sufficient, B-E-M)),
    forall(mua_relations:lx_for(VM, VB, Pr), emit(lx_for, VM-VB-Pr)),
    forall(mua_relations:grounding_metaphor(P, M), emit(grounding_metaphor_short, P-M)),
    forall(mua_relations:metaphor_breaks_at(M, I), emit(metaphor_breaks_short, M-I)),
    forall(grounding_metaphors:grounding_metaphor_definition(M, S, T, D),
           emit(metaphor, M-S-T-D)),
    forall(grounding_metaphors:metaphor_source_practice(M, P),
           emit(metaphor_source, M-P)),
    forall(grounding_metaphors:metaphor_target_practice(M, P),
           emit(metaphor_target, M-P)),
    forall(grounding_metaphors:metaphor_mapping(M, S, T, N),
           emit(metaphor_mapping, M-S-T-N)),
    forall(grounding_metaphors:metaphor_breaks_at(M, I, R),
           emit(metaphor_break, M-I-R)),
    forall(grounding_metaphors:metaphor_repair(B, I, R, Mech),
           emit(metaphor_repair, B-I-R-Mech)),
    forall(grounding_metaphors:grounds_inference(M, I, G),
           emit(grounds, M-I-G)),
    forall(grounding_metaphors:metaphor_kind(M, K),
           emit(metaphor_kind, M-K)),
    forall(grounding_metaphors:metaphor_short_name(M, N),
           emit(metaphor_short_name, M-N)),
    format('__END__~n').

:- run, halt.
:- halt(1).
""".strip()


def _strip_quotes(term: str) -> str:
    """Strip surrounding single quotes Prolog uses for atoms that need them."""
    term = term.strip()
    if len(term) >= 2 and term[0] == "'" and term[-1] == "'":
        return term[1:-1].replace("\\'", "'").replace("\\\\", "\\")
    return term


def _parse_string(term: str) -> str:
    """Prolog strings come back as double-quoted: ``"like this"``."""
    term = term.strip()
    if len(term) >= 2 and term[0] == '"' and term[-1] == '"':
        return term[1:-1].replace('\\"', '"').replace("\\\\", "\\")
    return term


def _split_pair(term: str, separator: str = "-") -> list[str]:
    """Split a Prolog ``A-B-C`` tuple into a list of string pieces.

    Respects nested parentheses, single-quoted atoms, and double-quoted
    strings — so ``foo-"a-b"-bar(x-y)`` splits into three parts at the
    top-level dashes.
    """
    parts: list[str] = []
    buf: list[str] = []
    depth = 0
    in_squote = False
    in_dquote = False
    i = 0
    while i < len(term):
        ch = term[i]
        if in_squote:
            buf.append(ch)
            if ch == "\\" and i + 1 < len(term):
                buf.append(term[i + 1])
                i += 2
                continue
            if ch == "'":
                in_squote = False
        elif in_dquote:
            buf.append(ch)
            if ch == "\\" and i + 1 < len(term):
                buf.append(term[i + 1])
                i += 2
                continue
            if ch == '"':
                in_dquote = False
        elif ch == "'":
            in_squote = True
            buf.append(ch)
        elif ch == '"':
            in_dquote = True
            buf.append(ch)
        elif ch == "(":
            depth += 1
            buf.append(ch)
        elif ch == ")":
            depth -= 1
            buf.append(ch)
        elif ch == separator and depth == 0:
            parts.append("".join(buf))
            buf = []
        else:
            buf.append(ch)
        i += 1
    parts.append("".join(buf))
    return parts


def _atom(term: str) -> str:
    return _strip_quotes(term.strip())


def _value(term: str) -> str:
    """Either an atom or a string. Returns the unquoted text."""
    s = term.strip()
    if s.startswith('"'):
        return _parse_string(s)
    return _strip_quotes(s)


def _principle(term: str) -> str:
    """``makes_explicit(foo_bar)`` -> ``foo_bar``."""
    s = term.strip()
    if s.startswith("makes_explicit(") and s.endswith(")"):
        return _atom(s[len("makes_explicit(") : -1])
    return _atom(s)


def run_prolog() -> list[tuple[str, str]]:
    """Run the Prolog extractor and return a list of (key, term) string pairs."""
    script_body = PROLOG_SCRIPT.format(root=str(REPO_ROOT))
    with tempfile.NamedTemporaryFile(
        mode="w",
        suffix=".pl",
        delete=False,
        dir=str(REPO_ROOT),
    ) as fh:
        fh.write(script_body)
        script_path = Path(fh.name)
    try:
        result = subprocess.run(
            ["swipl", "-q", "-l", str(PATHS_PL), "-s", str(script_path)],
            capture_output=True,
            text=True,
            check=False,
        )
    finally:
        try:
            script_path.unlink()
        except OSError:
            pass

    if result.returncode != 0:
        sys.stderr.write(result.stderr)
        sys.stderr.write(result.stdout)
        raise SystemExit(
            f"swipl extraction failed (exit {result.returncode})"
        )

    rows: list[tuple[str, str]] = []
    seen_end = False
    for line in result.stdout.splitlines():
        line = line.rstrip("\n")
        if line == "__END__":
            seen_end = True
            break
        if "|" not in line:
            continue
        key, _, term = line.partition("|")
        rows.append((key, term))
    if not seen_end:
        sys.stderr.write(result.stdout)
        sys.stderr.write(result.stderr)
        raise SystemExit("swipl extraction did not reach __END__ marker")
    return rows


def check_research_db() -> None:
    """Open the shipped derivative database read-only and verify its image."""
    uri = f"file:{RESEARCH_DB}?mode=ro&immutable=1"
    try:
        with sqlite3.connect(uri, uri=True) as db:
            result = db.execute("PRAGMA quick_check").fetchone()
    except sqlite3.Error as exc:
        raise SystemExit(f"cannot read {RESEARCH_DB}: {exc}") from exc
    if result != ("ok",):
        raise SystemExit(f"{RESEARCH_DB} failed PRAGMA quick_check: {result}")


def assemble(rows: list[tuple[str, str]]) -> dict:
    """Turn the raw (key, term) lines into the JSON-shaped dict."""
    practices: dict[str, str] = {}
    vocabularies: dict[str, str] = {}
    practice_kind: list[list[str]] = []
    pv_sufficient: list[list[str]] = []
    vp_sufficient: list[list[str]] = []
    pp_necessary: list[list[str]] = []
    pp_sufficient: list[list[str]] = []
    lx_for: list[list[str]] = []
    grounding_metaphor: list[list[str]] = []
    metaphor_breaks_short: list[list[str]] = []
    metaphors: dict[str, dict] = {}
    metaphor_sources: dict[str, list[str]] = {}
    metaphor_targets: dict[str, list[str]] = {}
    metaphor_mappings: list[dict] = []
    metaphor_breaks: list[dict] = []
    metaphor_repairs: list[dict] = []
    grounds_inference: list[dict] = []
    metaphor_kinds: dict[str, str] = {}
    metaphor_short_names: dict[str, str] = {}

    for key, term in rows:
        parts = _split_pair(term)
        if key == "practice":
            practices[_atom(parts[0])] = _value(parts[1])
        elif key == "vocabulary":
            vocabularies[_atom(parts[0])] = _value(parts[1])
        elif key == "practice_kind":
            practice_kind.append(
                [_atom(parts[0]), _atom(parts[1]), _atom(parts[2])]
            )
        elif key == "pv_sufficient":
            pv_sufficient.append([_atom(parts[0]), _atom(parts[1])])
        elif key == "vp_sufficient":
            vp_sufficient.append([_atom(parts[0]), _atom(parts[1])])
        elif key == "pp_necessary":
            pp_necessary.append([_atom(parts[0]), _atom(parts[1])])
        elif key == "pp_sufficient":
            pp_sufficient.append(
                [_atom(parts[0]), _atom(parts[1]), _atom(parts[2])]
            )
        elif key == "lx_for":
            lx_for.append(
                [_atom(parts[0]), _atom(parts[1]), _principle(parts[2])]
            )
        elif key == "grounding_metaphor_short":
            grounding_metaphor.append([_atom(parts[0]), _atom(parts[1])])
        elif key == "metaphor_breaks_short":
            metaphor_breaks_short.append([_atom(parts[0]), _atom(parts[1])])
        elif key == "metaphor":
            mid = _atom(parts[0])
            metaphors[mid] = {
                "id": mid,
                "source": _atom(parts[1]),
                "target": _atom(parts[2]),
                "description": _value(parts[3]),
            }
        elif key == "metaphor_source":
            metaphor_sources.setdefault(_atom(parts[0]), []).append(
                _atom(parts[1])
            )
        elif key == "metaphor_target":
            metaphor_targets.setdefault(_atom(parts[0]), []).append(
                _atom(parts[1])
            )
        elif key == "metaphor_mapping":
            metaphor_mappings.append(
                {
                    "metaphor": _atom(parts[0]),
                    "source_concept": _atom(parts[1]),
                    "target_concept": _atom(parts[2]),
                    "notes": _value(parts[3]),
                }
            )
        elif key == "metaphor_break":
            metaphor_breaks.append(
                {
                    "metaphor": _atom(parts[0]),
                    "inference": _atom(parts[1]),
                    "reason": _value(parts[2]),
                }
            )
        elif key == "metaphor_repair":
            metaphor_repairs.append(
                {
                    "broken": _atom(parts[0]),
                    "inference": _atom(parts[1]),
                    "repair": _atom(parts[2]),
                    "mechanism": _atom(parts[3]),
                }
            )
        elif key == "grounds":
            grounds_inference.append(
                {
                    "metaphor": _atom(parts[0]),
                    "inference": _atom(parts[1]),
                    "grounding": _atom(parts[2]),
                }
            )
        elif key == "metaphor_kind":
            metaphor_kinds[_atom(parts[0])] = _atom(parts[1])
        elif key == "metaphor_short_name":
            metaphor_short_names[_atom(parts[0])] = _value(parts[1])

    # Attach source/target practice lists + kind + short_name onto each
    # metaphor record. `kind` and `short_name` come from grounding_metaphors:
    # metaphor_kind/2 and metaphor_short_name/2 in Prolog, so adding a new
    # metaphor only requires adding a `grounding_metaphor_definition/4` plus
    # a `metaphor_repair/4` (if it's a repair) and optionally a
    # `metaphor_short_name/2` -- no JavaScript edits needed.
    metaphor_list = []
    for mid in sorted(metaphors):
        rec = dict(metaphors[mid])
        rec["source_practices"] = sorted(metaphor_sources.get(mid, []))
        rec["target_practices"] = sorted(metaphor_targets.get(mid, []))
        rec["kind"] = metaphor_kinds.get(mid, "basic")
        rec["short_name"] = metaphor_short_names.get(
            mid, mid.replace("_", " ")
        )
        metaphor_list.append(rec)

    practice_list = [
        {"id": pid, "description": practices[pid]} for pid in sorted(practices)
    ]
    vocabulary_list = [
        {"id": vid, "description": vocabularies[vid]}
        for vid in sorted(vocabularies)
    ]

    return {
        "practices": practice_list,
        "vocabularies": vocabulary_list,
        "pv_sufficient": sorted(pv_sufficient),
        "vp_sufficient": sorted(vp_sufficient),
        "pp_necessary": sorted(pp_necessary),
        "pp_sufficient": sorted(pp_sufficient),
        "lx_for": sorted(lx_for),
        "practice_kind": sorted(practice_kind),
        "grounding_metaphor": sorted(grounding_metaphor),
        "metaphor_breaks_short": sorted(
            metaphor_breaks_short, key=lambda r: (r[0], r[1])
        ),
        "metaphors": metaphor_list,
        "metaphor_breaks": sorted(
            metaphor_breaks, key=lambda r: (r["metaphor"], r["inference"])
        ),
        "metaphor_repairs": sorted(
            metaphor_repairs,
            key=lambda r: (r["broken"], r["inference"], r["repair"]),
        ),
        "metaphor_mappings": sorted(
            metaphor_mappings,
            key=lambda r: (r["metaphor"], r["source_concept"]),
        ),
        "grounds_inference": sorted(
            grounds_inference,
            key=lambda r: (r["metaphor"], r["inference"]),
        ),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="Verify the existing JSON matches the current Prolog state; "
        "write nothing.",
    )
    args = parser.parse_args()

    check_research_db()
    rows = run_prolog()
    data = assemble(rows)
    rendered = json.dumps(data, indent=2, sort_keys=True) + "\n"

    if args.check:
        if not OUT_PATH.exists():
            sys.stderr.write(f"{OUT_PATH} does not exist; run without --check\n")
            return 1
        existing = OUT_PATH.read_text()
        if existing != rendered:
            sys.stderr.write(
                f"{OUT_PATH} is stale; rerun "
                f"scripts/research/export_mua_for_mud.py to refresh.\n"
            )
            return 1
        print(f"{OUT_PATH} matches the current Prolog registry.")
        return 0

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(rendered)
    print(
        f"Wrote {OUT_PATH} — "
        f"{len(data['practices'])} practices, "
        f"{len(data['vocabularies'])} vocabularies, "
        f"{len(data['lx_for'])} LX edges, "
        f"{len(data['metaphors'])} metaphors."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
