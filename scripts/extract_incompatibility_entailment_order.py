#!/usr/bin/env python3
"""Generate the finite Brandomian incompatibility-entailment register and reader.

The register is deliberately a closed-world instrument.  It indexes the
tracked Big Red discovery cache together with the canonical engine's declared
seed hyperedges, then computes the replacement relation over that finite
collection.  It does not turn lack of an incompatibility record into a
substantive result: vacuous containment is retained as its own class.
"""
from __future__ import annotations

import argparse
import difflib
import json
import subprocess
import sys
import tempfile
import time
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "formal" / "incompatibility" / "incompatibility_entailment_order.pl"
VIEW = ROOT / "hermes" / "web" / "incompatibility-entailment.html"


@dataclass(frozen=True)
class Source:
    source: str
    context: str
    kind: str


@dataclass(frozen=True)
class Hyperedge:
    identifier: int
    terms: frozenset[str]
    sources: tuple[Source, ...]
    minimal: bool


def prolog_term(value: str) -> str:
    """Return a canonical ground term emitted by SWI-Prolog, unchanged."""
    return value


def quoted(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def term_key(value: str) -> tuple[str, str]:
    """A deterministic presentation order for canonical ground terms."""
    return (value.lower(), value)


def set_key(values: frozenset[str]) -> tuple[int, tuple[tuple[str, str], ...]]:
    return (len(values), tuple(sorted((term_key(value) for value in values))) )


def list_term(values: tuple[str, ...] | list[str]) -> str:
    return "[" + ", ".join(prolog_term(value) for value in values) + "]"


PROLOG_INVENTORY = r"""
use_module(incompat(incompatibility_sets), []),
use_module(incompat(brandomian_incompatibility), []),
forall(incompatibility_sets:discovered_set_fact(Context, Set),
       (( incompatibility_sets:discovered_set_kind(Context, Set, Kind)
        -> true
        ;  Kind = unclassified
        ),
        write('discovered\t'),
        write_term(Context, [quoted(true), ignore_ops(true), numbervars(true)]),
        put(9),
        write_term(Kind, [quoted(true), ignore_ops(true), numbervars(true)]),
        put(9),
        write_term(Set, [quoted(true), ignore_ops(true), numbervars(true)]), nl)),
forall(brandomian_incompatibility:incompatible_set(Set),
       (write('seed\tbrandomian_engine\tdeclared_seed\t'),
        write_term(Set, [quoted(true), ignore_ops(true), numbervars(true)]), nl)),
halt
""".replace("\n", " ")


def split_top_level_list(value: str) -> tuple[str, ...]:
    """Split the canonical list form that the inventory emits.

    The source contract says hyperedges are ground lists.  This reader only
    needs their top-level members, so quoted atoms and nested terms remain
    opaque strings and structural identity remains SWI-Prolog's emitted form.
    """
    if not (value.startswith("[") and value.endswith("]")):
        raise RuntimeError(f"inventory returned a non-list hyperedge: {value}")
    body = value[1:-1].strip()
    if not body:
        return ()
    members: list[str] = []
    start = 0
    depth = 0
    quote_open = False
    index = 0
    while index < len(body):
        character = body[index]
        if quote_open:
            if character == "'":
                if index + 1 < len(body) and body[index + 1] == "'":
                    index += 2
                    continue
                quote_open = False
            index += 1
            continue
        if character == "'":
            quote_open = True
        elif character in "([":
            depth += 1
        elif character in ")]":
            depth -= 1
        elif character == "," and depth == 0:
            members.append(body[start:index].strip())
            start = index + 1
        index += 1
    if quote_open or depth != 0:
        raise RuntimeError(f"inventory returned an unbalanced term: {value}")
    members.append(body[start:].strip())
    if any(not member for member in members):
        raise RuntimeError(f"inventory returned an empty hyperedge member: {value}")
    return tuple(members)


def load_inventory() -> tuple[list[tuple[Source, frozenset[str]]], Counter[str], list[tuple[Source, frozenset[str]]]]:
    """Load only the finite cache and canonical seed declarations in one SWI run."""
    started = time.perf_counter()
    result = subprocess.run(
        ["swipl", "-q", "-l", str(ROOT / "paths.pl"), "-g", PROLOG_INVENTORY],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    elapsed = time.perf_counter() - started
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or "SWI-Prolog incompatibility inventory failed")
    if result.stderr.strip():
        raise RuntimeError(result.stderr.strip())
    rows: list[tuple[Source, frozenset[str]]] = []
    excluded: list[tuple[Source, frozenset[str]]] = []
    discovered_kind_counts: Counter[str] = Counter()
    for line in result.stdout.splitlines():
        fields = line.split("\t")
        if len(fields) != 4 or fields[0] not in {"discovered", "seed"}:
            raise RuntimeError(f"unexpected incompatibility inventory row: {line}")
        source, context, kind, set_text = fields
        terms = frozenset(split_top_level_list(set_text))
        row_source = Source(source, context, kind)
        if source == "discovered":
            discovered_kind_counts[kind] += 1
        # A nonterminating discovery candidate has no incompatibility verdict.
        # It remains counted as provenance but cannot become a singleton
        # incompatible hyperedge merely because a bounded classifier timed out.
        if source == "discovered" and kind == "nonterminating":
            excluded.append((row_source, terms))
            continue
        if len(terms) < 2:
            raise RuntimeError(f"incompatibility hyperedge has arity below two: {set_text}")
        rows.append((row_source, terms))
    if not rows:
        raise RuntimeError("incompatibility inventory returned no hyperedges")
    # Keep this measured locally; elapsed time is reported by main rather than
    # becoming a source of nondeterminism in the generated artifacts.
    _ = elapsed
    return rows, discovered_kind_counts, excluded


def build_hyperedges(rows: list[tuple[Source, frozenset[str]]]) -> list[Hyperedge]:
    grouped: dict[frozenset[str], list[Source]] = defaultdict(list)
    for source, terms in rows:
        grouped[terms].append(source)
    ordered_terms = sorted(grouped, key=set_key)
    minimal_terms: list[frozenset[str]] = []
    for terms in ordered_terms:
        if not any(candidate <= terms for candidate in minimal_terms):
            minimal_terms.append(terms)
    minimal_set = set(minimal_terms)
    return [
        Hyperedge(
            identifier=index,
            terms=terms,
            sources=tuple(sorted(grouped[terms], key=lambda item: (item.source, item.context, item.kind))),
            minimal=terms in minimal_set,
        )
        for index, terms in enumerate(ordered_terms, 1)
    ]


def profiles(hyperedges: list[Hyperedge]) -> tuple[tuple[str, ...], dict[str, tuple[int, ...]], dict[str, tuple[tuple[str, ...], ...]], Counter[str]]:
    contents = tuple(sorted({term for edge in hyperedges for term in edge.terms}, key=term_key))
    minimal = [edge for edge in hyperedges if edge.minimal]
    memberships: dict[str, tuple[int, ...]] = {}
    contexts: dict[str, tuple[tuple[str, ...], ...]] = {}
    mentions: Counter[str] = Counter()
    for edge in hyperedges:
        for term in edge.terms:
            mentions[term] += 1
    for content in contents:
        containing = tuple(edge.identifier for edge in minimal if content in edge.terms)
        memberships[content] = containing
        contexts[content] = tuple(
            tuple(sorted(edge.terms - {content}, key=term_key))
            for edge in minimal
            if content in edge.terms
        )
    return contents, memberships, contexts, mentions


def entails(
    replacement: str,
    replaced: str,
    hyperedges: list[Hyperedge],
    membership: dict[str, tuple[int, ...]],
) -> tuple[bool, tuple[tuple[int, int], ...]]:
    """Index the finite replacement test using minimal hyperedges only.

    Every nonminimal declared edge either contains a smaller edge that survives
    replacement unchanged, or has a smaller edge containing the replaced term.
    In the latter case a minimal containing edge supplies the same witness.
    The reduction therefore preserves the finite relation while avoiding the
    repeated backtracking scan of ``minimal_incompatible_set/1``.
    """
    profile = membership[replaced]
    if not profile:
        return True, ()
    by_id = {edge.identifier: edge for edge in hyperedges}
    minimal = [edge for edge in hyperedges if edge.minimal]
    witnesses: list[tuple[int, int]] = []
    for profile_id in profile:
        original = by_id[profile_id]
        candidate = (original.terms - {replaced}) | {replacement}
        witness = next((edge.identifier for edge in minimal if edge.terms <= candidate), None)
        if witness is None:
            return False, ()
        witnesses.append((profile_id, witness))
    return True, tuple(witnesses)


def calculate(hyperedges: list[Hyperedge]) -> dict[str, object]:
    contents, membership, contexts, mentions = profiles(hyperedges)
    relation: dict[tuple[str, str], tuple[bool, tuple[tuple[int, int], ...]]] = {}
    for replacement in contents:
        for replaced in contents:
            relation[(replacement, replaced)] = entails(replacement, replaced, hyperedges, membership)

    earned: dict[tuple[str, str], tuple[tuple[int, int], ...]] = {}
    vacuous: list[tuple[str, str]] = []
    equivalent: list[tuple[str, str]] = []
    mutual_nonidentical: list[tuple[str, str]] = []
    for replacement in contents:
        for replaced in contents:
            if replacement == replaced:
                continue
            holds, witnesses = relation[(replacement, replaced)]
            if not membership[replaced]:
                vacuous.append((replacement, replaced))
                continue
            if not holds:
                continue
            reverse, _ = relation[(replaced, replacement)]
            if not reverse:
                earned[(replacement, replaced)] = witnesses
            elif term_key(replacement) < term_key(replaced):
                if contexts[replacement] == contexts[replaced]:
                    equivalent.append((replacement, replaced))
                else:
                    mutual_nonidentical.append((replacement, replaced))

    density = Counter(mentions[content] for content in contents)
    kind_counts = Counter(
        source.kind for edge in hyperedges for source in edge.sources if source.source == "discovered"
    )
    raw_source_counts = Counter(source.source for edge in hyperedges for source in edge.sources)
    return {
        "contents": contents,
        "membership": membership,
        "contexts": contexts,
        "mentions": mentions,
        "relation": relation,
        "earned": earned,
        "vacuous": tuple(sorted(vacuous, key=lambda pair: (term_key(pair[0]), term_key(pair[1])))),
        "equivalent": tuple(equivalent),
        "mutual_nonidentical": tuple(mutual_nonidentical),
        "density": density,
        "kind_counts": kind_counts,
        "raw_source_counts": raw_source_counts,
    }


def positive_control() -> None:
    """A hand-worked dog/mammal fixture guards the indexed replacement logic."""
    rows = [
        (Source("fixture", "positive_control", "declared"), frozenset({"dog", "feline"})),
        (Source("fixture", "positive_control", "declared"), frozenset({"dog", "cold_blooded"})),
        (Source("fixture", "positive_control", "declared"), frozenset({"mammal", "feline"})),
    ]
    result = calculate(build_hyperedges(rows))
    earned = result["earned"]
    if ("dog", "mammal") not in earned or ("mammal", "dog") in earned:
        raise RuntimeError(
            "positive control failed: dog must earn mammal, while mammal must not earn dog"
        )


REGISTER = r"""/** <module> Generated finite incompatibility-entailment register
 *
 * This register models Brandomian incompatibility-entailment over a bounded,
 * declared corpus.  Its source is exactly the tracked Big Red discovered-set
 * cache plus the five declared seed hyperedges in
 * brandomian_incompatibility.pl.  The cache's one nonterminating candidate is
 * counted by incompatibility_discovered_kind_count/2 but is not a declared
 * incompatible hyperedge: it has no incompatibility verdict.  It does not load optional registry adapters,
 * live discovery, geometry, learner servers, or literature mappings.
 *
 * A hyperedge is incoherent with every superset.  The generator removes
 * nonminimal hyperedges for the replacement test only: that reduction
 * preserves the test because a smaller declared hyperedge either survives the
 * replacement unchanged or supplies a smaller profile containing the replaced
 * content.  input_hyperedge/4 retains every distinct declared input edge and
 * its source/kind provenance.
 *
 * incompatibility_earned_entails(A, B, WitnessCount) is a strict finite
 * entailment: B has a nonempty minimal profile; replacing B by A preserves
 * every profile context; and B does not preserve every profile context for A.
 * It is not classical consequence.  WitnessCount records the number of B's
 * minimal profile edges checked.
 *
 * incompatibility_vacuously_entails/2 records the otherwise-free containment
 * case separately: B has an empty minimal profile.  The content universe is
 * finite and consists only of terms appearing in input_hyperedge/4.  That
 * boundary, and density counts per content, are part of the result: sparse
 * incompatibility data can make the finite order too strong.
 *
 * incompatibility_equivalent/2 records distinct contents with identical
 * minimal partner-context profiles.  mutual_nonidentical_profile/2 is kept
 * apart if replacement is mutual without identical profiles, rather than
 * silently calling it equivalence.
 *
 * Generated by scripts/extract_incompatibility_entailment_order.py.
 * Regenerate: python3 scripts/extract_incompatibility_entailment_order.py
 */

:- module(incompatibility_entailment_order,
          [ input_hyperedge/4,                         % ?Id, ?Terms, ?Sources, ?Minimal
            incompatibility_content/3,                 % ?Content, ?DeclaredMentions, ?MinimalProfileEdges
            incompatibility_profile/2,                 % ?Content, ?MinimalHyperedgeIds
            incompatibility_earned_entails/3,          % ?A, ?B, ?WitnessCount
            incompatibility_vacuously_entails/2,       % ?A, ?B
            incompatibility_equivalent/2,              % ?A, ?B
            mutual_nonidentical_profile/2,             % ?A, ?B
            incompatibility_data_density/2,            % ?DeclaredMentionCount, ?ContentCount
            incompatibility_order_count/2,             % ?Kind, ?Count
            incompatibility_discovered_kind_count/2,   % ?Kind, ?Count
            incompatibility_emergent_hyperedge/1,      % ?Id
            incompatibility_positive_control/2         % ?Case, ?Status
          ]).

% Kept defined when this finite corpus has no such pair; generated facts, when
% present, extend this predicate below.
mutual_nonidentical_profile(_, _) :- fail.
"""


def source_term(source: Source) -> str:
    return f"source({source.source}, {prolog_term(source.context)}, {prolog_term(source.kind)})"


def render_register(hyperedges: list[Hyperedge], result: dict[str, object]) -> str:
    contents: tuple[str, ...] = result["contents"]  # type: ignore[assignment]
    membership: dict[str, tuple[int, ...]] = result["membership"]  # type: ignore[assignment]
    mentions: Counter[str] = result["mentions"]  # type: ignore[assignment]
    earned: dict[tuple[str, str], tuple[tuple[int, int], ...]] = result["earned"]  # type: ignore[assignment]
    vacuous: tuple[tuple[str, str], ...] = result["vacuous"]  # type: ignore[assignment]
    equivalent: tuple[tuple[str, str], ...] = result["equivalent"]  # type: ignore[assignment]
    mutual: tuple[tuple[str, str], ...] = result["mutual_nonidentical"]  # type: ignore[assignment]
    density: Counter[int] = result["density"]  # type: ignore[assignment]
    kind_counts: Counter[str] = result["kind_counts"]  # type: ignore[assignment]
    discovered_kind_counts: Counter[str] = result.get("discovered_kind_counts", kind_counts)  # type: ignore[assignment]
    excluded: list[tuple[Source, frozenset[str]]] = result.get("excluded_candidates", [])  # type: ignore[assignment]
    raw_source_counts: Counter[str] = result["raw_source_counts"]  # type: ignore[assignment]
    lines = [REGISTER.rstrip(), ""]
    for edge in hyperedges:
        terms = tuple(sorted(edge.terms, key=term_key))
        sources = ", ".join(source_term(source) for source in edge.sources)
        lines.append(
            f"input_hyperedge({edge.identifier}, {list_term(terms)}, [{sources}], {str(edge.minimal).lower()})."
        )
    lines.append("")
    for content in contents:
        lines.append(
            f"incompatibility_content({prolog_term(content)}, {mentions[content]}, {len(membership[content])})."
        )
    lines.append("")
    for content in contents:
        lines.append(
            f"incompatibility_profile({prolog_term(content)}, {list(membership[content])})."
        )
    lines.append("")
    for (replacement, replaced), witnesses in sorted(earned.items(), key=lambda item: (term_key(item[0][0]), term_key(item[0][1]))):
        lines.append(
            f"incompatibility_earned_entails({prolog_term(replacement)}, {prolog_term(replaced)}, {len(witnesses)})."
        )
    lines.append("")
    for replacement, replaced in vacuous:
        lines.append(f"incompatibility_vacuously_entails({prolog_term(replacement)}, {prolog_term(replaced)}).")
    lines.append("")
    for left, right in equivalent:
        lines.append(f"incompatibility_equivalent({prolog_term(left)}, {prolog_term(right)}).")
    lines.append("")
    for left, right in mutual:
        lines.append(f"mutual_nonidentical_profile({prolog_term(left)}, {prolog_term(right)}).")
    lines.append("")
    for mentions_count, content_count in sorted(density.items()):
        lines.append(f"incompatibility_data_density({mentions_count}, {content_count}).")
    lines.append("")
    counts = {
        "declared_input_hyperedges": len(hyperedges),
        "minimal_hyperedges": sum(edge.minimal for edge in hyperedges),
        "contents": len(contents),
        "earned_entailments": len(earned),
        "vacuous_entailments": len(vacuous),
        "equivalent_pairs": len(equivalent),
        "mutual_nonidentical_pairs": len(mutual),
        "cache_input_rows": raw_source_counts["discovered"],
        "seed_input_rows": raw_source_counts["seed"],
        "nonterminating_candidates_excluded": len(excluded),
    }
    for kind, count in counts.items():
        lines.append(f"incompatibility_order_count({kind}, {count}).")
    lines.append("")
    for kind, count in sorted(discovered_kind_counts.items(), key=lambda item: item[0]):
        lines.append(f"incompatibility_discovered_kind_count({prolog_term(kind)}, {count}).")
    lines.append("")
    for edge in hyperedges:
        if any(source.source == "discovered" and source.kind == "emergent" for source in edge.sources):
            lines.append(f"incompatibility_emergent_hyperedge({edge.identifier}).")
    lines.append("")
    lines.append("incompatibility_positive_control(dog_entails_mammal, passed).")
    lines.append("")
    return "\n".join(lines)


def display_sources(edge: Hyperedge) -> list[str]:
    return [f"{source.source}: {source.context}, {source.kind}" for source in edge.sources]


def view_payload(hyperedges: list[Hyperedge], result: dict[str, object]) -> dict[str, object]:
    contents: tuple[str, ...] = result["contents"]  # type: ignore[assignment]
    membership: dict[str, tuple[int, ...]] = result["membership"]  # type: ignore[assignment]
    mentions: Counter[str] = result["mentions"]  # type: ignore[assignment]
    earned: dict[tuple[str, str], tuple[tuple[int, int], ...]] = result["earned"]  # type: ignore[assignment]
    vacuous: tuple[tuple[str, str], ...] = result["vacuous"]  # type: ignore[assignment]
    equivalent: tuple[tuple[str, str], ...] = result["equivalent"]  # type: ignore[assignment]
    mutual: tuple[tuple[str, str], ...] = result["mutual_nonidentical"]  # type: ignore[assignment]
    density: Counter[int] = result["density"]  # type: ignore[assignment]
    kind_counts: Counter[str] = result.get("discovered_kind_counts", result["kind_counts"])  # type: ignore[assignment]
    by_content: dict[str, dict[str, object]] = {}
    all_vacuous_targets = {target for _source, target in vacuous}
    for content in contents:
        by_content[content] = {
            "term": content,
            "declaredMentions": mentions[content],
            "minimalProfileEdges": len(membership[content]),
            "profileClass": "vacuous" if content in all_vacuous_targets else "informed",
            "earnedOut": [target for source, target in earned if source == content],
            "earnedIn": [source for source, target in earned if target == content],
            "equivalent": [
                right if left == content else left
                for left, right in equivalent
                if content in {left, right}
            ],
            "mutualNonidentical": [
                right if left == content else left
                for left, right in mutual
                if content in {left, right}
            ],
            "hyperedges": [edge.identifier for edge in hyperedges if content in edge.terms],
        }
    return {
        "summary": {
            "declaredHyperedges": len(hyperedges),
            "minimalHyperedges": sum(edge.minimal for edge in hyperedges),
            "contents": len(contents),
            "earned": len(earned),
            "vacuous": len(vacuous),
            "equivalent": len(equivalent),
            "density": sorted([[count, total] for count, total in density.items()]),
            "discoveredKinds": dict(sorted(kind_counts.items())),
        },
        "contents": by_content,
        "hyperedges": [
            {
                "id": edge.identifier,
                "terms": sorted(edge.terms, key=term_key),
                "minimal": edge.minimal,
                "emergent": any(source.source == "discovered" and source.kind == "emergent" for source in edge.sources),
                "sources": display_sources(edge),
            }
            for edge in hyperedges
        ],
    }


def render_view(hyperedges: list[Hyperedge], result: dict[str, object]) -> str:
    payload = json.dumps(view_payload(hyperedges, result), ensure_ascii=True, sort_keys=True, separators=(",", ":"))
    return f"""<!doctype html>
<html lang=\"en\">
<head>
  <meta charset=\"utf-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
  <title>Finite incompatibility-entailment order</title>
  <style>
    :root {{ --bg:#110f08; --surface:#1a1710; --raised:#242016; --text:#d4cfc0; --muted:#9a927e; --border:#4a4233; --accent:#e8a84c; --danger:#d4634a; --good:#89b77a; --mono:ui-monospace,Menlo,Monaco,Consolas,monospace; }}
    * {{ box-sizing:border-box; }} body {{ margin:0; background:var(--bg); color:var(--text); font:16px/1.5 Georgia,serif; }}
    main {{ max-width:1120px; margin:auto; padding:2rem 1.25rem 4rem; }} h1 {{ margin:0 0:.25rem; font-size:1.85rem; }} h2 {{ font-size:1.1rem; margin:0 0:.6rem; }} p {{ max-width:76ch; }} .lede,.limit {{ color:var(--muted); }}
    .summary,.panel,.edge {{ background:var(--surface); border:1px solid var(--border); border-radius:8px; padding:1rem; }} .summary {{ display:grid; grid-template-columns:repeat(auto-fit,minmax(145px,1fr)); gap:.8rem; margin:1.25rem 0; }}
    .metric b {{ display:block; color:var(--accent); font:1.45rem var(--mono); }} .metric span {{ color:var(--muted); font-size:.8rem; }} .chooser {{ display:flex; gap:.7rem; flex-wrap:wrap; margin:1.25rem 0; }} input,select {{ background:var(--raised); border:1px solid var(--border); border-radius:5px; color:var(--text); font:14px var(--mono); padding:.55rem; max-width:100%; }} input {{ flex:1 1 330px; }} select {{ flex:2 1 400px; }}
    .grid {{ display:grid; grid-template-columns:repeat(auto-fit,minmax(280px,1fr)); gap:1rem; }} .panel {{ min-width:0; }} code,.term {{ font:13px/1.45 var(--mono); overflow-wrap:anywhere; }} .term {{ color:var(--accent); }} ul {{ list-style:none; padding:0; margin:.4rem 0 0; }} li {{ border-top:1px solid var(--border); padding:.45rem 0; }} button.term {{ background:none; border:0; cursor:pointer; padding:0; text-align:left; }} button.term:hover {{ text-decoration:underline; }} .badge {{ border:1px solid var(--border); border-radius:999px; color:var(--muted); font:11px var(--mono); margin-left:.35rem; padding:.1rem .4rem; }} .badge.emergent {{ border-color:var(--danger); color:var(--danger); }} .badge.minimal {{ border-color:var(--good); color:var(--good); }} .edge {{ margin:.7rem 0; }} .edge p {{ margin:.35rem 0 0; }} .empty {{ color:var(--muted); font-style:italic; }} details {{ margin-top:1.3rem; }} summary {{ cursor:pointer; color:var(--accent); }} @media (max-width:600px) {{ main {{ padding:.9rem; }} }}
  </style>
</head>
<body>
<main>
  <h1>Finite incompatibility-entailment order</h1>
  <p class=\"lede\">A navigable register of the declared Big Red cache and canonical seed hyperedges. It encodes Brandomian incompatibility-entailment, not classical consequence.</p>
  <p class=\"limit\">The order is finite and bounded by these declarations. Sparse data can make containment too strong. Vacuous containment remains separate from earned entailment.</p>
  <section id=\"summary\" class=\"summary\"></section>
  <div class=\"chooser\"><input id=\"filter\" type=\"search\" placeholder=\"Filter a content term\" aria-label=\"Filter contents\"><select id=\"content\" aria-label=\"Choose a content\"></select></div>
  <section id=\"detail\"></section>
  <details><summary>Emergent hyperedges</summary><div id=\"emergent\"></div></details>
</main>
<script>
(() => {{
  "use strict";
  const data={payload}; const byId=new Map(data.hyperedges.map(e=>[e.id,e]));
  const $=id=>document.getElementById(id); const node=(tag,text,cls)=>{{const n=document.createElement(tag); if(text!==undefined)n.textContent=text; if(cls)n.className=cls; return n;}};
  function metric(value,label) {{ const box=node("div",undefined,"metric"); box.append(node("b",String(value))); box.append(node("span",label)); return box; }}
  function termButton(value) {{ const b=node("button",value,"term"); b.type="button"; b.addEventListener("click",()=>select(value)); return b; }}
  function list(values, empty) {{ const out=node("ul"); if(!values.length) {{ out.append(node("li",empty,"empty")); return out; }} values.forEach(value=>{{const li=node("li");li.append(termButton(value));out.append(li);}}); return out; }}
  function panel(title, body) {{ const section=node("section",undefined,"panel"); section.append(node("h2",title)); section.append(body); return section; }}
  function select(value) {{ $("content").value=value; render(value); }}
  function populate(filter="") {{ const selected=$("content").value; const match=filter.toLowerCase(); const values=Object.keys(data.contents).filter(v=>v.toLowerCase().includes(match)).sort(); $("content").textContent=""; values.forEach(value=>{{const option=node("option",value);option.value=value;$("content").append(option);}}); if(values.includes(selected)) $("content").value=selected; else if(values.length) $("content").value=values[0]; if(values.length) render($("content").value); else $("detail").textContent="No content matches this filter."; }}
  function edgeCard(edge) {{ const box=node("article",undefined,"edge"); const heading=node("div"); heading.append(node("span","#"+edge.id+" ","term")); edge.terms.forEach((value,index)=>{{if(index) heading.append(document.createTextNode(", "));heading.append(termButton(value));}}); if(edge.minimal) heading.append(node("span","minimal","badge minimal")); if(edge.emergent) heading.append(node("span","emergent","badge emergent")); box.append(heading); box.append(node("p",edge.sources.join("; "),"limit")); return box; }}
  function render(value) {{ const item=data.contents[value]; if(!item) return; const root=$("detail");root.textContent=""; const title=node("h2",value,"term"); const density=node("p","Declared hyperedges mentioning this content: "+item.declaredMentions+". Minimal profile edges: "+item.minimalProfileEdges+".","limit"); root.append(title,density); if(item.profileClass==="vacuous") root.append(node("p","This content has an empty minimal profile. Any containment into it is listed as vacuous, not earned.","limit")); const grid=node("div",undefined,"grid"); grid.append(panel("Earned entailments from this content",list(item.earnedOut,"No strict earned entailments in this finite register."))); grid.append(panel("Contents that earn this content",list(item.earnedIn,"No strict earned entailments into this content in this finite register."))); grid.append(panel("Equivalent profile",list(item.equivalent,"No distinct content has an identical minimal partner-context profile."))); if(item.mutualNonidentical.length) grid.append(panel("Mutual replacement, nonidentical profile",list(item.mutualNonidentical,""))); root.append(grid); const hyper=node("section");hyper.style.marginTop="1rem";hyper.append(node("h2","Declared incompatible hyperedges containing this content")); item.hyperedges.forEach(id=>hyper.append(edgeCard(byId.get(id))));root.append(hyper); }}
  const s=data.summary; $("summary").append(metric(s.declaredHyperedges,"distinct declared hyperedges"),metric(s.minimalHyperedges,"minimal hyperedges"),metric(s.contents,"contents"),metric(s.earned,"earned strict entailments"),metric(s.vacuous,"vacuous ordered pairs"),metric(s.equivalent,"equivalent pairs"));
  const emergent=$("emergent"); data.hyperedges.filter(e=>e.emergent).forEach(edge=>emergent.append(edgeCard(edge)));
  $("filter").addEventListener("input",event=>populate(event.target.value)); $("content").addEventListener("change",event=>render(event.target.value)); populate();
}})();
</script>
</body>
</html>
"""


def compare(expected: str, path: Path) -> int:
    actual = path.read_text(encoding="utf-8") if path.is_file() else ""
    if actual == expected:
        return 0
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False) as temporary:
        temporary.write(expected)
        temporary_path = Path(temporary.name)
    diff = "".join(difflib.unified_diff(actual.splitlines(True), expected.splitlines(True), fromfile=str(path), tofile=str(temporary_path)))
    temporary_path.unlink(missing_ok=True)
    sys.stderr.write(diff)
    return 1


def summary(hyperedges: list[Hyperedge], result: dict[str, object], elapsed: float, checked: bool) -> str:
    earned: dict[tuple[str, str], tuple[tuple[int, int], ...]] = result["earned"]  # type: ignore[assignment]
    vacuous: tuple[tuple[str, str], ...] = result["vacuous"]  # type: ignore[assignment]
    equivalent: tuple[tuple[str, str], ...] = result["equivalent"]  # type: ignore[assignment]
    contents: tuple[str, ...] = result["contents"]  # type: ignore[assignment]
    return (
        f"incompatibility entailment register {'current' if checked else 'written'}: "
        f"hyperedges={len(hyperedges)}; minimal={sum(edge.minimal for edge in hyperedges)}; "
        f"contents={len(contents)}; earned={len(earned)}; vacuous={len(vacuous)}; "
        f"equivalent={len(equivalent)}; wall_seconds={elapsed:.3f}"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail if either generated artifact is stale")
    arguments = parser.parse_args()
    started = time.perf_counter()
    positive_control()
    rows, discovered_kind_counts, excluded = load_inventory()
    hyperedges = build_hyperedges(rows)
    result = calculate(hyperedges)
    result["discovered_kind_counts"] = discovered_kind_counts
    result["excluded_candidates"] = excluded
    register = render_register(hyperedges, result)
    view = render_view(hyperedges, result)
    elapsed = time.perf_counter() - started
    if arguments.check:
        register_status = compare(register, OUTPUT)
        view_status = compare(view, VIEW)
        if register_status or view_status:
            return 1
        print(summary(hyperedges, result, elapsed, True))
        return 0
    OUTPUT.write_text(register, encoding="utf-8")
    VIEW.write_text(view, encoding="utf-8")
    print(summary(hyperedges, result, elapsed, False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
