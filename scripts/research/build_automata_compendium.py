#!/usr/bin/env python3
"""Build the typeset automata compendium from generated and authored data."""
from __future__ import annotations

import argparse
import html
import json
import re
import subprocess
import sys
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path

from build_machine_typology import ROOT, Machine, Transition, parse_transition_tables, structure
from build_transition_tables import derived_example
from render_automaton_context_svg import composite_records, scene_records
from render_automaton_svg import palette, render_all as render_radial


OUTPUT = ROOT / "docs/research/2026-08-03-automata-compendium.html"
FAMILY_OUTPUT_DIR = ROOT / "docs/research/automata-compendium"
PRINT_OUTPUT = ROOT / "build/automata-compendium/2026-08-03-automata-compendium-print.html"
CONTRACTS = ROOT / "knowledge/strategies/automaton_input_contracts.pl"
VOCABULARY = ROOT / "knowledge/strategies/math/state_vocabulary.pl"
ATTESTATIONS = ROOT / "knowledge/strategies/machine_class_attestations.pl"
COINCIDENCE = ROOT / "knowledge/strategies/deformation_coincidence.pl"
ATOM = r"[a-z][a-z0-9_]*"
CONTRACT = re.compile(
    rf"automaton_input_contract\(\s*({ATOM})\s*,\s*({ATOM})\s*,\s*"
    r"'((?:\\.|[^'])*)'\s*,\s*'((?:\\.|[^'])*)'\s*,\s*verified\(([^)]*)\)\)\.",
    re.MULTILINE,
)
STATE_LABEL = re.compile(
    rf"state_label\(\s*({ATOM})\s*,\s*({ATOM})\s*,\s*"
    r'"((?:\\.|[^"\\])*)"\s*,\s*"((?:\\.|[^"\\])*)"\s*\)\s*\.',
    re.MULTILINE,
)
ATTESTATION = re.compile(
    rf"machine_class_attestation\(\s*({ATOM})\s*,\s*({ATOM})\s*,\s*"
    rf"({ATOM})\s*,\s*source\('([^']+)'\)\s*\)\s*\.",
    re.MULTILINE,
)


@dataclass(frozen=True)
class AtlasRow:
    family: str
    kind: str
    validity: str
    condition: str
    ran: int
    coincide: int
    rate: int
    sample_coincide: str
    sample_separate: str


@dataclass(frozen=True)
class InputContract:
    schema: dict[str, object]
    example: dict[str, object]
    verification: str


CLASS_GLOSSES = {
    "linear_trace": "no recorded branch or loop; the table records one accepting run",
    "branching": "one or more recorded states have multiple outgoing transitions; no loop edge is recorded",
    "looping": "one or more recorded edges return to an earlier state; no branch state is recorded",
    "branching_looping": "the recorded graph contains both a branch state and a loop edge",
}


def esc(value: object) -> str:
    return html.escape(str(value), quote=True)


def image_attributes(svg: str, *, eager: bool = False) -> str:
    match = re.search(r'<svg\b[^>]*\bwidth="(\d+)"[^>]*\bheight="(\d+)"', svg)
    if match is None:
        raise ValueError("generated SVG lacks intrinsic integer width and height")
    width, height = match.groups()
    loading = ' loading="eager"' if eager else ' loading="lazy"'
    return f'width="{width}" height="{height}"{loading} decoding="async"'


def decode_prolog_string(value: str) -> str:
    return value.replace(r'\"', '"')


def read_contracts() -> dict[tuple[str, str], InputContract]:
    found: dict[tuple[str, str], InputContract] = {}
    for family, kind, schema, example, verification in CONTRACT.findall(
        CONTRACTS.read_text(encoding="utf-8")
    ):
        found[(family, kind)] = InputContract(
            schema=json.loads(schema.replace(r'\"', '"')),
            example=json.loads(example.replace(r'\"', '"')),
            verification=verification,
        )
    return found


def read_state_labels() -> dict[str, list[tuple[str, str, str]]]:
    labels: dict[str, list[tuple[str, str, str]]] = defaultdict(list)
    for state, tradition, label, citation in STATE_LABEL.findall(
        VOCABULARY.read_text(encoding="utf-8")
    ):
        labels[state].append(
            (tradition, decode_prolog_string(label), decode_prolog_string(citation))
        )
    priority = {"constructivist": 0, "van_de_walle": 1}
    for state in labels:
        labels[state].sort(key=lambda row: (priority.get(row[0], 2), row[0], row[1], row[2]))
    return labels


def read_attestations() -> dict[tuple[str, str], list[tuple[str, str]]]:
    rows: dict[tuple[str, str], list[tuple[str, str]]] = defaultdict(list)
    for family, kind, claim, source in ATTESTATION.findall(
        ATTESTATIONS.read_text(encoding="utf-8")
    ):
        rows[(family, kind)].append((claim, source))
    return rows


def read_atlas_rows() -> list[AtlasRow]:
    """Read profile rows and ask their shipped sample for its recorded validity.

    The finite sweep is not repeated.  One already-recorded coinciding sample is
    run for each row that has one so conditional and accidental labels remain
    the labels emitted by the action module rather than an inference from rate.
    """
    goal = r"""
forall(
  deformation_coincidence:coincidence_profile(
    Op, K, deformation, ran(Ran), coincide(Co), rate_pct(Rate), _,
    sample_coincide(CoincideSample), sample_separate(SeparateSample), _),
  ( ( CoincideSample = some(A, B)
    -> action_automata_registry:run_action_automaton(
         Op, K, A, B, action_outcome(_, Fields), _),
       once(sub_term(validity(Validity), Fields)),
       ( Validity == contextually_correct,
         once(sub_term(condition(Condition0), Fields))
       -> Condition = Condition0
       ;  Condition = none
       )
    ;  Validity = incorrect,
       Condition = none
    ),
    format('ROW\t~q\t~q\t~q\t~q\t~w\t~w\t~w\t~q\t~q~n',
           [Op, K, Validity, Condition, Ran, Co, Rate,
            CoincideSample, SeparateSample])
  )),
halt
""".strip()
    result = subprocess.run(
        [
            "swipl",
            "-q",
            "-l",
            str(ROOT / "paths.pl"),
            "-l",
            str(ROOT / "knowledge/strategies/math/action_automata_registry.pl"),
            "-l",
            str(COINCIDENCE),
            "-g",
            goal,
        ],
        cwd=ROOT,
        text=True,
        capture_output=True,
        timeout=25,
        check=False,
    )
    if result.returncode:
        raise RuntimeError(
            f"validity sample query failed ({result.returncode}): {result.stderr.strip()}"
        )
    rows = []
    for line in result.stdout.splitlines():
        if not line.startswith("ROW\t"):
            continue
        fields = line.split("\t")
        if len(fields) != 10:
            raise ValueError(f"unexpected validity sample row: {line!r}")
        (
            _, family, kind, validity, condition, ran, coincide, rate,
            sample_coincide, sample_separate,
        ) = fields
        rows.append(
            AtlasRow(
                family, kind, validity, condition, int(ran), int(coincide),
                int(rate), sample_coincide, sample_separate,
            )
        )
    profile_count = len(re.findall(r"^coincidence_profile\([^\n]+, deformation,", COINCIDENCE.read_text(encoding="utf-8"), re.MULTILINE))
    if len(rows) != profile_count:
        raise ValueError(f"validity query returned {len(rows)} of {profile_count} deformation profiles")
    return sorted(rows, key=lambda row: (row.family, row.kind))


def formal_aliases(machine: Machine) -> dict[str, int]:
    ordered = [machine.start, *(state for state in machine.states if state != machine.start)]
    return {state: index for index, state in enumerate(ordered)}


def formal_state(index: int) -> str:
    return f"<i>q</i><sub>{index}</sub>"


def state_mapping_table(machine: Machine, labels: dict[str, list[tuple[str, str, str]]]) -> str:
    aliases = formal_aliases(machine)
    rows = []
    for state in aliases:
        literature = labels.get(state, [])
        if literature:
            rendered = "<br>".join(
                f'<span class="literature-label">{esc(label)}</span> '
                f'<span class="citation">({esc(tradition)}; {esc(citation)})</span>'
                for tradition, label, citation in literature
            )
        else:
            rendered = '<span class="none">none recorded</span>'
        rows.append(
            f"<tr><td>{formal_state(aliases[state])}</td><td><code>{esc(state)}</code></td><td>{rendered}</td></tr>"
        )
    return (
        '<table class="state-map"><thead><tr><th>Formal state</th><th>ASCII atom</th>'
        f'<th>Literature label and citation</th></tr></thead><tbody>{"".join(rows)}</tbody></table>'
    )


def alphabet(machine: Machine) -> str:
    actions = list(machine.actions)
    if len(actions) <= 12:
        body = ", ".join(f"<code>{esc(action)}</code>" for action in actions)
        return f'{body} ({len(actions)}<span class="typeset-space"> </span>distinct)'
    sample = ", ".join(f"<code>{esc(action)}</code>" for action in actions[:12])
    return f"{len(actions)} distinct actions; alphabetical sample: {sample}"


def static_source(provenance: str) -> str:
    match = re.fullmatch(r"static\('((?:[^']|'')*)'\)", provenance)
    if not match:
        raise ValueError(f"unexpected static provenance: {provenance}")
    return match.group(1).replace("''", "'")


def provenance_item(
    edge: Transition,
    contract: InputContract | None,
) -> str:
    if edge.provenance_kind == "static":
        source = static_source(edge.provenance)
        leaf = source.rsplit("/", 1)[-1]
        return f'<code title="{esc(source)}">{esc(leaf)}</code>'
    if contract is None:
        raise ValueError(
            f"observed transition lacks an input contract: {edge.provenance}"
        )
    example = contract.example
    suffix = ""
    if edge.provenance == "observed(derived_template)":
        example = derived_example(example)
        suffix = ' (derived<span class="typeset-space"> </span>template)'
    elif edge.provenance != "observed(contract_example)":
        raise ValueError(f"unexpected observed provenance: {edge.provenance}")
    rendered = json.dumps(example, sort_keys=True)
    return f'observed on <code>{esc(rendered)}</code>{suffix}'


def transition_table(machine: Machine, contract: InputContract | None) -> str:
    grouped: dict[tuple[str, str, str], list[Transition]] = {}
    for edge in machine.transitions:
        key = (edge.before, edge.action, edge.after)
        grouped.setdefault(key, []).append(edge)
    rows = []
    for (before, action, after), edges in grouped.items():
        provenance = "<br>".join(
            provenance_item(edge, contract)
            for edge in dict.fromkeys(edges)
        )
        provenance_kinds = " ".join(dict.fromkeys(edge.provenance_kind for edge in edges))
        rows.append(
            f'<tr><td><code>{esc(before)}</code></td><td><code>{esc(action)}</code></td>'
            f'<td><code>{esc(after)}</code></td><td class="provenance {provenance_kinds}">'
            f'{provenance}</td></tr>'
        )
    return (
        '<div class="table-scroll transitions-scroll"><table class="transitions">'
        '<thead><tr><th>From</th><th>Action</th><th>To</th>'
        f'<th>Provenance</th></tr></thead><tbody>{"".join(rows)}</tbody></table></div>'
    )


def tuple_block(machine: Machine, labels: dict[str, list[tuple[str, str, str]]]) -> str:
    aliases = formal_aliases(machine)
    q_values = ", ".join(formal_state(aliases[state]) for state in aliases)
    accepting = ", ".join(formal_state(aliases[state]) for state in machine.accepting)
    return f"""
<div class="tuple-grid">
  <div class="tuple-formal">
    <p class="machine-tuple"><i>M</i> = (<i>Q</i>, <i>Σ</i>, <i>δ</i>, <i>q</i><sub>0</sub>, <i>F</i>)</p>
    <dl>
      <dt><i>Q</i></dt><dd>{{{q_values}}}</dd>
      <dt><i>Σ</i></dt><dd>{alphabet(machine)}</dd>
      <dt><i>q</i><sub>0</sub></dt><dd>{formal_state(aliases[machine.start])} = <code>{esc(machine.start)}</code></dd>
      <dt><i>F</i></dt><dd>{{{accepting}}}</dd>
    </dl>
  </div>
  <div>{state_mapping_table(machine, labels)}</div>
</div>"""


def contract_line(contract: InputContract | None) -> str:
    if contract is None:
        return '<p class="input-contract"><span class="term">Input contract:</span> <span class="none">none recorded</span>.</p>'
    schema = json.dumps(contract.schema, sort_keys=True)
    example = json.dumps(contract.example, sort_keys=True)
    return (
        '<p class="input-contract"><span class="term">Input contract:</span> '
        f'<code>{esc(schema)}</code>; example <code>{esc(example)}</code>; '
        f'<code>verified({esc(contract.verification)})</code>.</p>'
    )


def typology_line(machine: Machine) -> str:
    row = structure(machine)
    gloss = CLASS_GLOSSES[row.structural_class]
    counts = (
        f"{len(machine.states)} states, {len(machine.actions)} distinct actions, "
        f"{len(row.branching_states)} branching states, {len(row.loop_edges)} loop edges; "
        f"{row.static_rows} static rows and {row.observed_rows} observed rows"
    )
    return (
        f'<p class="typology"><span class="term">Computed structure:</span> '
        f'<code>{row.structural_class}</code>. {esc(gloss)}. {esc(counts)}.</p>'
    )


def attestation_line(machine: Machine, attestations: dict[tuple[str, str], list[tuple[str, str]]]) -> str:
    rows = attestations.get((machine.family, machine.kind))
    if not rows:
        return ""
    claims = "; ".join(
        f'<code>{esc(claim)}</code>, attested at <code>{esc(source)}</code>'
        for claim, source in rows
    )
    return f'<p class="attestation"><span class="term">Authored class:</span> {claims}. This claim comes from module prose, not from the table graph.</p>'


def machine_section(
    machine: Machine,
    entry_number: int,
    labels: dict[str, list[tuple[str, str, str]]],
    contracts: dict[tuple[str, str], InputContract],
    attestations: dict[tuple[str, str], list[tuple[str, str]]],
    scenes,
    radials,
    asset_prefix: str,
    *,
    print_mode: bool = False,
) -> str:
    key = (machine.family, machine.kind)
    scene = scenes[key]
    if scene.svg is not None:
        scene_caption = esc(scene.caption).replace(
            " trace steps",
            '<span class="typeset-space"> </span>trace'
            '<span class="typeset-space"> </span>steps',
        )
        scene_html = (
            f'<figure class="diagram domain-scene"><img src="{asset_prefix}/{esc(machine.family)}/'
            f'{esc(machine.kind)}-scene.svg" {image_attributes(scene.svg, eager=print_mode)} '
            f'alt="Executed domain scene for {esc(machine.family)} '
            f'{esc(machine.kind)}"><figcaption>{scene_caption}</figcaption></figure>'
        )
    else:
        scene_html = f'<p class="scene-limit">{esc(scene.reach_limit)}</p>'
    radial_svg = radials[Path(machine.family) / f"{machine.kind}.svg"]
    return f"""
<article class="machine" id="{esc(machine.family)}-{esc(machine.kind)}">
<h3><span class="entry-number">{entry_number}.</span> <code>{esc(machine.kind)}</code></h3>
{scene_html}
<figure class="diagram transition-diagram"><img src="{asset_prefix}/{esc(machine.family)}/{esc(machine.kind)}.svg" {image_attributes(radial_svg, eager=print_mode)} alt="Radial transition diagram for {esc(machine.family)} {esc(machine.kind)}"><figcaption>Recorded transition graph; local action names remain on the edges.</figcaption></figure>
{tuple_block(machine, labels)}
{contract_line(contracts.get(key))}
<h4><i>δ</i>: recorded transitions</h4>
{transition_table(machine, contracts.get(key))}
{typology_line(machine)}
{attestation_line(machine, attestations)}
</article>"""


def family_composite(
    family: str,
    svg: str,
    unaligned: tuple[str, ...],
    asset_prefix: str,
    *,
    print_mode: bool = False,
) -> str:
    limit = " For graphs with loops, the construction uses simple accepting paths and does not unfold repeated traversals."
    if unaligned:
        kinds = ", ".join(f"<code>{esc(kind)}</code>" for kind in unaligned)
        limit += f" The following kinds have no simple accepting path and remain unmerged: {kinds}."
    return (
        f'<figure class="diagram family-composite"><img src="{asset_prefix}/{esc(family)}/_composite.svg" '
        f'{image_attributes(svg, eager=print_mode)} alt="Canonical-action composite for the {esc(family)} family"><figcaption>'
        "Construction: canonical action sequences merge by common prefix and structurally identical suffix. "
        "Branch labels name the kinds taking each branch. This models shared doing under canonical action names; "
        f"the automata do not literally share states.{limit}</figcaption></figure>"
    )


def plain_negation(condition: str) -> str:
    exact = {
        "given_dividend_at_least_given_divisor": "the given dividend is less than the given divisor",
        "no_leftover_after_making_base": "a leftover remains after making the base",
        "selected_addend_requires_no_rounding_adjustment": "the selected addend requires a rounding adjustment",
        "selected_addend_already_at_target_base": "the selected addend is not already at the target base",
        "decomposed_addend_has_no_ones_chunk": "the decomposed addend has a ones chunk",
    }
    if condition in exact:
        return exact[condition]
    replacements = (
        ("_coincides_with_", " does not coincide with "),
        ("_agrees_with_", " does not agree with "),
        ("_equals_", " does not equal "),
        ("_preserves_", " does not preserve "),
        ("_completes_", " does not complete "),
        ("_at_least_", " is less than "),
    )
    for marker, phrase in replacements:
        if marker in condition:
            left, right = condition.split(marker, 1)
            return f"{left.replace('_', ' ')}{phrase}{right.replace('_', ' ')}"
    return f"the recorded condition {condition.replace('_', ' ')} does not hold"


def sample_text(sample: str) -> str:
    if sample == "none":
        return '<span class="none">none recorded</span>'
    if sample.startswith("some(") and sample.endswith(")"):
        sample = sample[5:-1]
    return f"<code>{esc(sample)}</code>"


def atlas_separation(row: AtlasRow) -> str:
    if row.coincide == row.ran:
        return "Nothing: answer-agreement is total; only the trace separates it."
    if row.condition != "none":
        return f"It separates where {esc(plain_negation(row.condition))}."
    if row.coincide == 0:
        return "It separates on every input that ran in this measured grid."
    return "The outcome records no condition atom; separation is the complement of the measured coincidence set."


def atlas_section(rows: list[AtlasRow]) -> str:
    body = []
    for row in rows:
        validity = f"<code>{esc(row.validity)}</code>"
        if row.validity == "contextually_correct" and row.condition != "none":
            validity += f" with <code>condition({esc(row.condition)})</code>"
        body.append(
            f"<tr><td><code>{esc(row.family)}/{esc(row.kind)}</code></td><td>{validity}</td>"
            f'<td class="numeric">{row.coincide} / {row.ran} ({row.rate}%)</td>'
            f"<td>{sample_text(row.sample_coincide)}</td>"
            f"<td>{sample_text(row.sample_separate)}</td>"
            f"<td>{atlas_separation(row)}</td></tr>"
        )
    return f"""
<section id="coincidence-atlas">
<h2>Coincidence atlas</h2>
<p>A deformation pair <em>(f, g)</em> coincides on the equalizer of the pair, the inputs where <em>f(x) = g(x)</em>. These profiles measure samples of those sets on finite grids; they are not proofs over every input.</p>
<p>A recognizer may charge a misconception only on inputs where the deformation separates. A problem set teaches against a misconception only on inputs where it separates.</p>
<div class="table-scroll"><table class="atlas"><thead><tr><th>Kind</th><th>Validity label</th><th>Measured coincidence</th><th>Sample coinciding input</th><th>Sample separating input</th><th>Separation</th></tr></thead><tbody>{"".join(body)}</tbody></table></div>
</section>"""


def contents(grouped: dict[str, list[Machine]]) -> str:
    families = []
    for family in sorted(grouped):
        kinds = "".join(
            f'<li><a href="automata-compendium/{esc(machine.family)}.html#{esc(machine.family)}-{esc(machine.kind)}"><code>{esc(machine.kind)}</code></a></li>'
            for machine in sorted(grouped[family], key=lambda row: row.kind)
        )
        families.append(
            f'<section class="contents-family"><h3><a href="automata-compendium/{esc(family)}.html#family-{esc(family)}">{esc(family)}</a></h3>'
            f'<ol>{kinds}</ol></section>'
        )
    return (
        '<nav class="contents" aria-labelledby="contents-heading">'
        '<h2 id="contents-heading">Contents</h2>'
        f'<div class="contents-grid">{"".join(families)}</div></nav>'
    )


def print_contents(grouped: dict[str, list[Machine]]) -> str:
    """Render the same contents list with links into the single print document."""
    families = []
    for family in sorted(grouped):
        kinds = "".join(
            f'<li><a href="#{esc(machine.family)}-{esc(machine.kind)}"><code>{esc(machine.kind)}</code></a></li>'
            for machine in sorted(grouped[family], key=lambda row: row.kind)
        )
        families.append(
            f'<section class="contents-family"><h3><a href="#family-{esc(family)}">{esc(family)}</a></h3>'
            f'<ol>{kinds}</ol></section>'
        )
    return (
        '<nav class="contents" aria-labelledby="contents-heading">'
        '<h2 id="contents-heading">Contents</h2>'
        f'<div class="contents-grid">{"".join(families)}</div></nav>'
    )


def root_palette() -> str:
    properties = palette()
    colors = ";".join(f"--{name}:{value}" for name, value in properties.items())
    return (
        f":root{{{colors};--line:color-mix(in srgb,var(--ink) 20%,transparent);"
        "--mono:ui-monospace,Menlo,Monaco,Consolas,monospace;--prose:76ch}"
    )


def shared_style() -> str:
    """Return the one generated stylesheet shared by every compendium page."""
    return f"""{root_palette()}
*{{box-sizing:border-box}} body{{margin:0;background:var(--paper);color:var(--ink);font:16px/1.55 Georgia,serif}} main{{max-width:1180px;margin:auto;padding:2.4rem 1.25rem 4rem}} p{{max-width:var(--prose)}} .page-header{{margin-bottom:2rem}} .page-header h1{{font-size:2.35rem;line-height:1.08;font-weight:normal;margin:0 0 .65rem}} .lede{{font-size:1.08rem;margin:.3rem 0;color:var(--muted)}} h2{{font-size:1.7rem;line-height:1.2;font-weight:normal;margin:3rem 0 1rem;border-bottom:1px solid var(--line);padding-bottom:.4rem}} h3{{font-size:1.38rem;line-height:1.25;margin:0 0 1rem}} h4{{font-size:1rem;font-weight:normal;color:var(--muted);margin:1.4rem 0 .4rem}} code{{font:.82em var(--mono);overflow-wrap:anywhere}} a{{color:var(--gold-deep);text-underline-offset:.14em}} .back-link{{margin:0 0 1rem}} .contents{{margin:2rem 0 3.5rem}} .contents-grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(245px,1fr));gap:1rem}} .contents-family{{background:var(--surface);border:1px solid var(--line);border-radius:7px;padding:.8rem 1rem}} .contents-family h3{{font-size:1.05rem;margin:0 0 .35rem}} .contents-family ol{{margin:.2rem 0;padding-left:2.1rem}} .contents-family li{{padding:.08rem 0}} article.machine{{background:var(--surface);border:1px solid var(--line);border-radius:9px;padding:1.2rem;margin:1.1rem 0 2rem;content-visibility:auto;contain-intrinsic-size:auto 2400px}} .machine h3{{font-size:1.38rem}} .entry-number{{color:var(--gold-deep);font-weight:normal}} .tuple-grid{{display:grid;grid-template-columns:minmax(240px,.72fr) minmax(460px,1.28fr);gap:1.25rem;align-items:start}} .machine-tuple{{font-size:1.12rem}} .typeset-space{{display:inline-block;width:.28em;white-space:pre}} dl{{display:grid;grid-template-columns:2rem 1fr;gap:.45rem .7rem}} dt{{color:var(--gold-deep)}} dd{{margin:0}} table{{border-collapse:collapse;width:100%;font-size:.88rem}} .table-scroll{{width:100%;overflow:auto}} .transitions-scroll{{max-height:28rem}} th,td{{border:1px solid var(--line);padding:.38rem .52rem;text-align:left;vertical-align:top}} th{{background:var(--paper-warm);color:var(--muted);font-weight:normal}} .transitions thead th{{position:sticky;top:0;z-index:1;background:var(--paper-warm)}} .state-map td:first-child{{white-space:nowrap}} .citation,.none{{color:var(--muted);font-size:.9em}} .literature-label{{font-style:italic}} .provenance.observed{{color:var(--gold-deep)}} .input-contract{{background:var(--paper-cool);padding:.7rem .85rem;border-radius:5px}} .diagram{{margin:1.2rem 0;overflow:auto;border:1px solid var(--line);border-radius:7px;background:var(--paper);padding:.6rem}} .diagram img{{display:block;margin:auto;max-width:100%;height:auto}} figcaption{{max-width:var(--prose);margin:.55rem auto 0;color:var(--muted);font-size:.9rem}} .domain-scene img{{max-height:34rem}} .transition-diagram img{{max-height:46rem}} .family-composite img{{max-width:none;min-width:100%}} .family-composite{{max-height:72rem}} .scene-limit{{background:var(--paper-cool);border-left:3px solid var(--muted);padding:.65rem .8rem}} .typology,.attestation{{background:var(--paper-cool);padding:.7rem .85rem;border-radius:5px}} .term{{color:var(--gold-deep)}} .attestation{{border-left:3px solid var(--gold)}} .atlas{{font-size:.84rem;min-width:860px}} .numeric{{white-space:nowrap;text-align:right}} .legend-list{{display:grid;grid-template-columns:max-content minmax(0,var(--prose));gap:.45rem 1rem}} .legend-list dt{{font-family:var(--mono)}} .swatch{{display:inline-block;width:1.4rem;height:.18rem;vertical-align:middle;margin-right:.35rem;background:currentColor}} .swatch.conserving{{color:var(--ink)}} .swatch.deforming{{color:var(--rust)}} .swatch.neutral{{color:var(--muted)}} footer{{margin-top:3rem;border-top:1px solid var(--line);padding-top:1rem;color:var(--muted);font-size:.88rem}} @media(max-width:850px){{.tuple-grid{{grid-template-columns:1fr}}main{{padding:.9rem}}article.machine{{padding:.75rem}}}}"""


def print_style() -> str:
    """Return the shared design with flow-safe print rules."""
    screen = shared_style()
    for browser_only in (
        "content-visibility:auto;contain-intrinsic-size:auto 2400px",
        "overflow:auto",
        ".transitions-scroll{max-height:28rem}",
        ".domain-scene img{max-height:34rem}",
        ".transition-diagram img{max-height:46rem}",
        ".family-composite{max-height:72rem}",
    ):
        screen = screen.replace(browser_only, "")
    return screen + """
@page{size:A4 portrait;margin:14mm 12mm 16mm}
@media print{
  html,body{background:#fff}
  main{max-width:none;margin:0;padding:0}
  section.family{break-before:page;page-break-before:always}
  article.machine{contain:none}
  figure,tr{break-inside:avoid;page-break-inside:avoid}
  thead{display:table-header-group}
  tfoot{display:table-footer-group}
  .table-scroll,.transitions-scroll,.diagram,.family-composite{overflow:visible}
  .diagram img,.family-composite img{display:block;width:auto;min-width:0;max-width:100%;height:auto}
  .transitions thead th{position:static}
  .atlas{min-width:0;font-size:.72rem}
  a{color:inherit;text-decoration:none}
}
""".strip()


def page_document(title: str, body: str, *, stylesheet: str | None = None) -> str:
    if stylesheet is None:
        stylesheet = shared_style()
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{esc(title)}</title>
<style>
{stylesheet}
</style>
</head>
<body><main>
{body}
</main></body></html>
"""


def legend_section() -> str:
    return f"""<section id="legend"><h2>Legend</h2>
<p>Each entry writes <i>M</i> = (<i>Q</i>, <i>Σ</i>, <i>δ</i>, <i>q</i><sub>0</sub>, <i>F</i>): states, action alphabet, transition relation, start state, and accepting states. ASCII atoms remain beside the indexed state notation. In transition diagrams, <span class="swatch conserving"></span>dark edges are conserving actions, <span class="swatch deforming"></span>rust edges are deforming actions, and <span class="swatch neutral"></span>muted edges are neutral actions. Dashed edges are observed-only rows. The gold arrow and state ring mark <i>q</i><sub>0</sub>; accepting states have two rings. Domain scenes use rust for an executed deformation and gold or dark marks for the admitted representation roles.</p>
<dl class="legend-list"><dt>linear_trace</dt><dd>{CLASS_GLOSSES["linear_trace"]}.</dd><dt>branching</dt><dd>{CLASS_GLOSSES["branching"]}.</dd><dt>looping</dt><dd>{CLASS_GLOSSES["looping"]}.</dd><dt>branching_looping</dt><dd>{CLASS_GLOSSES["branching_looping"]}.</dd></dl>
<p>Computed structure reports only the table graph. An authored class appears on a separate line only when module prose names it and supplies a source location.</p>
</section>"""


def typology_section(machines: list[Machine]) -> str:
    counts = {name: 0 for name in CLASS_GLOSSES}
    for machine in machines:
        counts[structure(machine).structural_class] += 1
    rows = "".join(
        f'<tr><td><code>{esc(name)}</code></td><td class="numeric">{counts[name]}</td>'
        f'<td>{esc(CLASS_GLOSSES[name])}</td></tr>'
        for name in CLASS_GLOSSES
    )
    return f"""<section id="computed-typology"><h2>Computed typology</h2>
<p>These classes summarize the graphs recorded by all {len(machines)} transition tables. They do not add claims about unrecorded runs or memory.</p>
<div class="table-scroll"><table><thead><tr><th>Structural class</th><th>Machines</th><th>Recorded shape</th></tr></thead><tbody>{rows}</tbody></table></div>
</section>"""


def attestations_section(
    attestations: dict[tuple[str, str], list[tuple[str, str]]],
    *,
    print_mode: bool = False,
) -> str:
    rows = []
    for (family, kind), claims in sorted(attestations.items()):
        for claim, source in claims:
            href = (
                f"#{family}-{kind}"
                if print_mode
                else f"automata-compendium/{family}.html#{family}-{kind}"
            )
            rows.append(
                f'<tr><td><a href="{esc(href)}">'
                f'<code>{esc(family)}/{esc(kind)}</code></a></td><td><code>{esc(claim)}</code></td>'
                f'<td><code>{esc(source)}</code></td></tr>'
            )
    return f"""<section id="authored-attestations"><h2>Authored class attestations</h2>
<p>These class names come from module prose and remain separate from the computed table-graph typology.</p>
<div class="table-scroll"><table><thead><tr><th>Machine</th><th>Authored class</th><th>Source</th></tr></thead><tbody>{"".join(rows)}</tbody></table></div>
</section>"""


def footer() -> str:
    return """<footer><p>Artifacts and regeneration: <code>knowledge/strategies/transition_tables/*.pl</code>, <code>python3 scripts/research/build_transition_tables.py</code>; <code>knowledge/strategies/machine_typology.pl</code>, <code>python3 scripts/research/build_machine_typology.py</code>; radial assets <code>docs/research/assets/automata/&lt;family&gt;/&lt;kind&gt;.svg</code>, <code>python3 scripts/research/render_automaton_svg.py</code>; scene and composite assets, <code>python3 scripts/research/render_automaton_context_svg.py</code>; the hub <code>docs/research/2026-08-03-automata-compendium.html</code> and family pages under <code>docs/research/automata-compendium/</code>, <code>python3 scripts/research/build_automata_compendium.py</code>. Authored input: <code>knowledge/strategies/machine_class_attestations.pl</code>. Parsed inputs: <code>knowledge/strategies/automaton_input_contracts.pl</code>, <code>knowledge/strategies/math/state_vocabulary.pl</code>, and <code>knowledge/strategies/deformation_coincidence.pl</code>; the coincidence file records its sweep generator and finite grids in its header.</p></footer>"""


def generate_compendium_pages() -> dict[Path, str]:
    machines = parse_transition_tables()
    contracts = read_contracts()
    labels = read_state_labels()
    attestations = read_attestations()
    atlas = read_atlas_rows()
    scenes = scene_records()
    composites = composite_records()
    radials = render_radial()
    grouped: dict[str, list[Machine]] = defaultdict(list)
    for machine in machines:
        grouped[machine.family].append(machine)
    command = (
        "python3 scripts/research/build_machine_typology.py &amp;&amp; "
        "python3 scripts/research/render_automaton_svg.py &amp;&amp; "
        "python3 scripts/research/render_automaton_context_svg.py &amp;&amp; "
        "python3 scripts/research/build_automata_compendium.py"
    )
    hub_body = f"""<header class="page-header"><h1>Hermes automata compendium</h1>
<p class="lede">This compendium records the finite transition-table corpus as executed domain scenes, radial transition diagrams, five-tuples, and tables. A table can witness its recorded graph; it cannot by itself witness a stack or establish a richer computational class. The rows come from <code>knowledge/strategies/transition_tables/</code>, with authored class attestations kept separate. Regenerate it with <code>{command}</code>.</p>
<p>The corpus is split by family so each page stays within what a browser can paint.</p>
</header>
{contents(grouped)}
{legend_section()}
{typology_section(machines)}
{attestations_section(attestations)}
{atlas_section(atlas)}
<section id="limits"><h2>Limits</h2><p>The structural classes summarize generated table rows, including observed-only states named by those rows. They do not establish determinism, language coverage, or memory bounds beyond the recorded graph. Coincidence rates describe the finite grids named by their generator and do not generalize beyond those grids without further proof.</p></section>
{footer()}"""
    pages = {OUTPUT: page_document("Hermes automata compendium", hub_body)}
    for family in sorted(grouped):
        articles = "\n".join(
            machine_section(
                machine,
                index,
                labels,
                contracts,
                attestations,
                scenes,
                radials,
                "../assets/automata",
            )
            for index, machine in enumerate(
                sorted(grouped[family], key=lambda row: row.kind), start=1
            )
        )
        family_body = f"""<header class="page-header">
<p class="back-link"><a href="../2026-08-03-automata-compendium.html">Back to the automata compendium</a></p>
<h1>{esc(family)}</h1>
</header>
<section class="family" id="family-{esc(family)}">
{family_composite(family, *composites[family], "../assets/automata")}
{articles}
</section>
{footer()}"""
        pages[FAMILY_OUTPUT_DIR / f"{family}.html"] = page_document(
            f"{family} | Hermes automata compendium", family_body
        )
    return pages


def generate_print_compendium() -> str:
    """Return the complete corpus as one print-oriented HTML document."""
    machines = parse_transition_tables()
    contracts = read_contracts()
    labels = read_state_labels()
    attestations = read_attestations()
    atlas = read_atlas_rows()
    scenes = scene_records()
    composites = composite_records()
    radials = render_radial()
    grouped: dict[str, list[Machine]] = defaultdict(list)
    for machine in machines:
        grouped[machine.family].append(machine)
    command = (
        "python3 scripts/research/build_machine_typology.py &amp;&amp; "
        "python3 scripts/research/render_automaton_svg.py &amp;&amp; "
        "python3 scripts/research/render_automaton_context_svg.py &amp;&amp; "
        "python3 scripts/research/build_automata_compendium.py"
    )
    front_matter = f"""<header class="page-header"><h1>Hermes automata compendium</h1>
<p class="lede">This compendium records the finite transition-table corpus as executed domain scenes, radial transition diagrams, five-tuples, and tables. A table can witness its recorded graph; it cannot by itself witness a stack or establish a richer computational class. The rows come from <code>knowledge/strategies/transition_tables/</code>, with authored class attestations kept separate. Regenerate it with <code>{command}</code>.</p>
</header>
{print_contents(grouped)}
{legend_section()}
{typology_section(machines)}
{attestations_section(attestations, print_mode=True)}
{atlas_section(atlas)}
<section id="limits"><h2>Limits</h2><p>The structural classes summarize generated table rows, including observed-only states named by those rows. They do not establish determinism, language coverage, or memory bounds beyond the recorded graph. Coincidence rates describe the finite grids named by their generator and do not generalize beyond those grids without further proof.</p></section>"""
    family_sections = []
    for family in sorted(grouped):
        articles = "\n".join(
            machine_section(
                machine,
                index,
                labels,
                contracts,
                attestations,
                scenes,
                radials,
                "../../docs/research/assets/automata",
                print_mode=True,
            )
            for index, machine in enumerate(
                sorted(grouped[family], key=lambda row: row.kind), start=1
            )
        )
        family_sections.append(
            f"""<section class="family" id="family-{esc(family)}">
<h2>{esc(family)}</h2>
{family_composite(family, *composites[family], "../../docs/research/assets/automata", print_mode=True)}
{articles}
</section>"""
        )
    body = "\n".join([front_matter, *family_sections, footer()])
    return page_document(
        "Hermes automata compendium",
        body,
        stylesheet=print_style(),
    )


def generate_compendium() -> str:
    """Return the hub for callers retained from the former single-page build."""
    return generate_compendium_pages()[OUTPUT]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--check", action="store_true")
    mode.add_argument(
        "--print",
        action="store_true",
        dest="print_mode",
        help=f"write the single print document to {PRINT_OUTPUT.relative_to(ROOT)}",
    )
    args = parser.parse_args()
    if args.print_mode:
        PRINT_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        PRINT_OUTPUT.write_text(generate_print_compendium(), encoding="utf-8")
        print(f"automata compendium print HTML: {PRINT_OUTPUT.relative_to(ROOT)}")
        return 0
    pages = generate_compendium_pages()
    if args.check:
        stale = [
            path
            for path, expected in pages.items()
            if not path.exists() or path.read_text(encoding="utf-8") != expected
        ]
        if stale:
            for path in stale:
                print(f"stale generated compendium: {path}", file=sys.stderr)
            return 1
    else:
        for path, content in pages.items():
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")
    profile_count = len(
        re.findall(
            r"^coincidence_profile\([^\n]+, deformation,",
            COINCIDENCE.read_text(encoding="utf-8"),
            re.MULTILINE,
        )
    )
    print(
        f"automata compendium: {len(parse_transition_tables())} machines, "
        f"{profile_count} deformation profiles, {len(pages)} pages"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
