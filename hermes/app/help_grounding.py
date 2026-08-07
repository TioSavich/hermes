"""Bounded, page-specific context for the live documentation endpoint."""
from __future__ import annotations

import re
from pathlib import Path

MAX_GROUNDING_BYTES = 6 * 1024

# This mirrors the shell's presentational map so the server does not trust
# client-authored descriptions. Paths join page ids to the generated
# capability registry; theory links give the model an honest route to depth.
PAGE_CONTEXT: dict[str, dict[str, str]] = {
    "console": {"theme": "Norms & curriculum", "lede": "Bring a mathematical discussion, computation, or lesson to the local workbench.", "path": "/hermes/app/web/console.html", "theory": "/more-zeeman/landing.html"},
    "discussions": {"theme": "Norms & curriculum", "lede": "Build a claim-checked account of a discussion and keep the evidence attached.", "path": "/hermes/app/web/discussions.html", "theory": "/more-zeeman/muds.html"},
    "visualizations": {"theme": "Objects", "lede": "Run a representation filmstrip, then change its inputs when a worker is available.", "path": "/more-zeeman/visualizations.html", "theory": "/more-zeeman/strategies.html"},
    "strategy-machine": {"theme": "Objects", "lede": "Invoke one registered automaton runner by family and kind, then read its runtime trace.", "path": "/more-zeeman/strategies/machine.html", "theory": "/more-zeeman/strategies.html"},
    "witnesses": {"theme": "Recollection", "lede": "Query the finite witness families gathered from the loaded knowledge base.", "path": "/more-zeeman/witnesses.html", "theory": "/more-zeeman/landing.html"},
    "monitoring": {"theme": "Norms & curriculum", "lede": "Assemble one lesson's standards, anticipated strategies, and recorded misconceptions.", "path": "/more-zeeman/monitoring_chart.html", "theory": "/more-zeeman/scoreboard.html"},
    "review": {"theme": "Norms & curriculum", "lede": "Judge one generated proposal at a time with its recorded warrant and machine actions.", "path": "/more-zeeman/review.html", "theory": "/more-zeeman/scoreboard.html"},
    "gallery": {"theme": "Objects", "lede": "Browse coded representation samples from the local asset manifest.", "path": "/more-zeeman/gallery.html", "theory": "/more-zeeman/landing.html"},
    "landing": {"theme": "Recollection", "lede": "Choose a door into Hermes or follow the theory journey from its shared entry.", "path": "/more-zeeman/landing.html", "theory": "/more-zeeman/landing.html"},
    "no": {"theme": "Incompatibility", "lede": "Being wrong has structure: a rule, its domain, and the collision beyond that domain.", "path": "/hermes/app/web/no.html", "theory": "/hermes/app/web/no.html"},
    "breaks": {"theme": "Incompatibility", "lede": "Run where metaphor grounding or an incompatibility relation reaches its boundary.", "path": "/hermes/app/web/breaks.html", "theory": "/hermes/app/web/no.html"},
    "incompatibility-entailment": {"theme": "Incompatibility", "lede": "Inspect the finite register of declared incompatibility hyperedges and its earned entailment relation.", "path": "/more-zeeman/incompatibility-entailment.html", "theory": "/hermes/app/web/no.html"},
    "snap": {"theme": "The feeling body", "lede": "Drag the disc until accumulated tension produces a snap into another strategy.", "path": "/more-zeeman/index.html", "theory": "/more-zeeman/index.html"},
    "counting": {"theme": "Objects", "lede": "Counting by ones is correct and, past a point, unaffordable; follow the cost tally by tally.", "path": "/more-zeeman/counting.html", "theory": "/more-zeeman/counting.html"},
    "crisis": {"theme": "The feeling body", "lede": "Work 38 + 55 by counting and mark the point where that method stops paying.", "path": "/more-zeeman/crisis.html", "theory": "/more-zeeman/crisis.html"},
    "strategies": {"theme": "Objects", "lede": "Run counting-on, COBO, and RMB as successively shorter strategic actions.", "path": "/more-zeeman/strategies.html", "theory": "/more-zeeman/strategies.html"},
    "fractal": {"theme": "Objects", "lede": "Run the nested automata and change the conditions that propagate a snap.", "path": "/more-zeeman/fractal.html", "theory": "/more-zeeman/fractal.html"},
    "playground": {"theme": "The feeling body", "lede": "Drag one node and test when enough local snaps produce a new strategy ring.", "path": "/more-zeeman/playground.html", "theory": "/more-zeeman/fractal.html"},
    "boundary": {"theme": "Objects", "lede": "Test what the action model handles at the boundary between counting and fractions.", "path": "/more-zeeman/boundary.html", "theory": "/more-zeeman/boundary.html"},
    "matrix": {"theme": "The feeling body", "lede": "Follow each snap as it grows the memory grid and reorganizes repeated tallies.", "path": "/more-zeeman/matrix.html", "theory": "/more-zeeman/matrix.html"},
    "muds": {"theme": "Recollection", "lede": "Trace the recorded relations between mathematical uses and their vocabularies.", "path": "/more-zeeman/muds.html", "theory": "/more-zeeman/muds.html"},
    "scoreboard": {"theme": "Norms & curriculum", "lede": "Query commitments, entitlements, and inferential-strength records on one scoreboard.", "path": "/more-zeeman/scoreboard.html", "theory": "/more-zeeman/scoreboard.html"},
    "atlas": {"theme": "Recollection", "lede": "Find each capability, the route that reaches it, and the page that calls it.", "path": "/more-zeeman/atlas.html", "theory": "/more-zeeman/landing.html"},
    "bridge": {"theme": "The learner", "lede": "Run the formal bridge from a resource limit through consultation to a revised strategy.", "path": "/more-zeeman/bridge.html", "theory": "/more-zeeman/bridge.html"},
    "coordination": {"theme": "The learner", "lede": "Test how units are composed, repeated, and treated as new units.", "path": "/more-zeeman/coordination.html", "theory": "/more-zeeman/coordination.html"},
    "reorganization": {"theme": "The learner", "lede": "Give the learner a fraction task, then test the strategy it builds after getting stuck.", "path": "/learner/reorg_demo.html", "theory": "/more-zeeman/bridge.html"},
    "unit-echo": {"theme": "Objects", "lede": "Run base regrouping beside fraction iteration at the same arity.", "path": "/more-zeeman/unit-echo/index.html", "theory": "/more-zeeman/coordination.html"},
    "fraction-bars": {"theme": "Objects", "lede": "Draw a fraction operation from its action trace and change the operands.", "path": "/more-zeeman/fraction-bars/calculator.html", "theory": "/more-zeeman/boundary.html"},
    "fraction-compare": {"theme": "Objects", "lede": "Compare a productive fraction action trace with one altered step and locate where their results diverge.", "path": "/more-zeeman/fraction-bars/compare.html", "theory": "/more-zeeman/boundary.html"},
}

PAGE_READMES: dict[str, tuple[str, ...]] = {
    "console": ("hermes/app/README.md",),
    "discussions": ("hermes/app/README.md", "formal/pml/README.md"),
    "visualizations": ("knowledge/strategies/render/README.md",),
    "witnesses": ("knowledge/crosswalk/README.md", "knowledge/standards/README.md", "formal/pml/README.md", "knowledge/geometry/README.md"),
    "monitoring": ("curriculum/im/README.md",),
    "review": ("hermes/README.md",),
    "gallery": ("hermes/representation/README.md",),
    "landing": ("hermes/web/README.md",),
    "no": ("formal/README.md", "formal/pml/README.md"),
    "breaks": ("formal/README.md", "formal/formalization/README.md"),
    "incompatibility-entailment": ("formal/README.md",),
    "snap": ("hermes/web/README.md",),
    "counting": ("knowledge/strategies/README.md",),
    "crisis": ("knowledge/strategies/README.md", "knowledge/misconceptions/README.md"),
    "strategies": ("knowledge/strategies/README.md",),
    "fractal": ("hermes/web/README.md", "knowledge/strategies/README.md"),
    "playground": ("hermes/web/README.md",),
    "boundary": ("formal/formalization/README.md", "knowledge/strategies/README.md"),
    "matrix": ("hermes/web/README.md",),
    "muds": ("formal/pml/README.md",),
    "scoreboard": ("formal/learner/README.md", "formal/pml/README.md"),
    "atlas": ("hermes/README.md",),
    "bridge": ("formal/learner/README.md",),
    "coordination": ("knowledge/strategies/math/README.md",),
    "reorganization": ("formal/learner/README.md",),
    "unit-echo": ("knowledge/strategies/render/README.md",),
    "fraction-bars": ("knowledge/strategies/render/README.md",),
    "fraction-compare": ("knowledge/strategies/render/README.md",),
}

PAGE_BACKING: dict[str, tuple[str, ...]] = {
    "strategy-machine": (
        "MACHINE PAGE",
        "- The Automaton runner page selects one automaton by family and kind, invokes that automaton's registered runner with the edited JSON input, and displays the returned runtime trace.",
        "",
        "GLOSSARY EXCERPT (docs/research/automata-vocabulary.html)",
        "- automaton: One registered state-and-transition structure for one family and kind. Machine is an informal synonym.",
        "- state: One node in one automaton.",
        "- transition: One directed move from a source state to a target state, labeled by a local action.",
        "- local action: The action name authored on one transition.",
        "- canonical action: A normalized action name used to compare local actions across automata.",
        "- kind: The registered subtype within a family. A family and kind together identify one automaton.",
        "- runtime trace: The ordered steps returned by one runner invocation.",
    ),
}

CAPABILITY_RE = re.compile(
    r"^capability\('([^']+)', '([^']+)', '([^']+)', \[(.*?)\], ([a-z_]+)\)\.$",
    re.MULTILINE,
)
CAPABILITY_PAGE_RE = re.compile(
    r"^capability_page\('([^']+)', '([^']+)'\)\.$", re.MULTILINE
)
STATE_LABEL_RE = re.compile(
    r'state_label\(([^,]+),\s*([^,]+),\s*"([^"]+)",\s*"([^"]+)"\)\.',
    re.DOTALL,
)


def _readme_excerpt(path: Path, limit: int = 600) -> str:
    text = path.read_text(encoding="utf-8").strip()
    headings = list(re.finditer(r"(?m)^##\s+", text))
    if len(headings) > 1:
        text = text[:headings[1].start()].rstrip()
    if len(text) > limit:
        text = text[:limit].rsplit(" ", 1)[0].rstrip() + "..."
    return text


def _capability_lines(repo_root: Path, page_path: str) -> list[str]:
    registry = (repo_root / "hermes/capability_registry.pl").read_text(encoding="utf-8")
    capabilities = {
        name: (module, role, inputs, status)
        for name, module, role, inputs, status in CAPABILITY_RE.findall(registry)
    }
    names = sorted(
        name for name, path in CAPABILITY_PAGE_RE.findall(registry) if path == page_path
    )
    lines: list[str] = []
    for name in names[:16]:
        module, role, inputs, status = capabilities.get(
            name, ("unknown", "unknown", "", "unknown")
        )
        fields = ", ".join(re.findall(r"'([^']+)'", inputs)) or "none"
        lines.append(
            f"- {name}: module={module}; role={role}; inputs={fields}; status={status}"
        )
    if len(names) > 16:
        lines.append(f"- {len(names) - 16} additional page capabilities omitted by the context limit.")
    return lines


def _state_label_lines(repo_root: Path) -> list[str]:
    source = (repo_root / "knowledge/strategies/math/state_vocabulary.pl").read_text(encoding="utf-8")
    labels = [
        (" ".join(state.split()), " ".join(tradition.split()), " ".join(label.split()), " ".join(citation.split()))
        for state, tradition, label, citation in STATE_LABEL_RE.findall(source)
    ]
    lines = [
        f'- {state}: "{label}" ({tradition}; {citation})'
        for state, tradition, label, citation in labels[:8]
    ]
    if len(labels) > 8:
        lines.append(f"- {len(labels) - 8} additional labels omitted by the context limit.")
    return lines


def _fit_utf8(text: str, limit: int) -> str:
    data = text.encode("utf-8")
    if len(data) <= limit:
        return text
    suffix = "\n[Context trimmed to the 6 KB help context limit.]"
    room = limit - len(suffix.encode("utf-8"))
    clipped = data[:room].decode("utf-8", errors="ignore").rsplit("\n", 1)[0]
    return clipped + suffix


def assemble_help_context(repo_root: Path, page: str) -> str:
    """Return trusted documentation context for one shell page."""
    info = PAGE_CONTEXT.get(page)
    if info is None:
        raise ValueError(f"unknown Hermes page: {page}")
    blocks = [
        "PAGE",
        f"- id: {page}",
        f"- path: {info['path']}",
        f"- theme: {info['theme']}",
        f"- purpose: {info['lede']}",
        f"- theory page for more depth: {info['theory']}",
        "",
        "CAPABILITIES REGISTERED FOR THIS PAGE",
    ]
    capability_lines = _capability_lines(repo_root, info["path"])
    blocks.extend(capability_lines or ["- No capability_page facts are registered for this page."])
    backing_lines = PAGE_BACKING.get(page, ())
    if backing_lines:
        blocks.extend(["", "PAGE-SPECIFIC BACKING", *backing_lines])
    if page in {"witnesses", "visualizations"}:
        blocks.extend(["", "STATE VOCABULARY LABELS", *_state_label_lines(repo_root)])
    blocks.extend(["", "BACKING MODULE DOCUMENTATION"])
    for relative in PAGE_READMES.get(page, ()):
        path = repo_root / relative
        blocks.extend([f"\nFILE: {relative}", _readme_excerpt(path)])
    return _fit_utf8("\n".join(blocks).strip() + "\n", MAX_GROUNDING_BYTES)
