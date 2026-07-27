#!/usr/bin/env python3
"""Check the generated corpus window against its source facts."""
from __future__ import annotations

import collections
import py_compile
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "research"))
from build_corpus_window import REGISTER_BLOCK_ROLES

BUILDER = ROOT / "scripts/research/build_corpus_window.py"
WINDOW = ROOT / "knowledge/index/corpus_window.pl"
WINDOW_TEXT = ROOT / "knowledge/index/corpus_window.txt"
TABLES = ROOT / "knowledge/strategies/transition_tables"
DISCOURSE = ROOT / "knowledge/discourse/commitment_automata.pl"
VOCABULARY = ROOT / "knowledge/strategies/action_vocabulary_map.pl"
GRAMMAR = ROOT / "knowledge/strategies/action_grammar.pl"

TRANSITION_RE = re.compile(
    r"(?m)^automaton_transition\((\w+),\s*(\w+),\s*(\w+),\s*(\w+),\s*(\w+),\s*"
    r"provenance\((.*?)\)\)\."
)
TUPLE_RE = re.compile(
    r"(?m)^automaton_tuple\((\w+),\s*(\w+),\s*states\(\[[^\]]*\]\),\s*"
    r"actions\(\[[^\]]*\]\),\s*start\((\w+)\),\s*accepting\(\[([^\]]*)\]\)\)"
)
MAP_RE = re.compile(r"(?m)^action_maps\((\w+), (\w+), (\w+), (\w+),")
REGISTER_RE = re.compile(
    r"(?m)^action_register\((\w+), genre\((\w+)\), register\((\w+)\), "
    r"stance\((\w+)\)\)"
)
ARC_RE = re.compile(r"(?m)^normative_arc\((\w+),")
GRAMMAR_RE = re.compile(
    r"(?m)^machine_grammar\((\w+), (\w+), (\w+), arc\((\w+)\),"
)
ROW_RE = re.compile(
    r"(?m)^window_row\((\w+), (\w+), (\w+), "
    r"\[([^\]]*)\], \[([^\]]*)\], \[([^\]]*)\], \[([^\]]*)\]\)\."
)
LEGEND_ACTION_RE = re.compile(
    r"(?m)^window_legend_action\((\w+), (\w+), (\w+), (\w+)\)\."
)
LEGEND_ARC_RE = re.compile(r"(?m)^window_legend_arc\((\w+), (\d+)\)\.")
REGISTER_GROUP_RE = re.compile(r"(?m)^window_register_group\((\w+), (\w+)\)\.")
SHELL_REGISTERS = frozenset(
    register for register, role in REGISTER_BLOCK_ROLES.items() if role == "shell"
)
CORE_REGISTERS = frozenset(
    register for register, role in REGISTER_BLOCK_ROLES.items() if role == "core"
)
CLOSURE_REGISTERS = frozenset(
    register for register, role in REGISTER_BLOCK_ROLES.items() if role == "closure"
)


def _items(raw: str) -> tuple[str, ...]:
    return tuple(part.strip() for part in raw.split(",") if part.strip())


def _run_builder(prolog: Path, text: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [
            sys.executable,
            str(BUILDER),
            "--output",
            str(prolog),
            "--output-text",
            str(text),
        ],
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=180,
        check=False,
    )


def _parse_rows() -> tuple[
    list[tuple[str, str, str, tuple[str, ...], tuple[str, ...], tuple[str, ...], tuple[str, ...]]],
    dict[str, tuple[str, str, str]],
    dict[str, int],
    dict[str, str],
]:
    text = WINDOW.read_text(encoding="ascii")
    rows = [
        (family, signature, arc, _items(shell), _items(core), _items(closure), _items(other))
        for family, signature, arc, shell, core, closure, other in ROW_RE.findall(text)
    ]
    actions = {
        action: (genre, register, stance)
        for action, genre, register, stance in LEGEND_ACTION_RE.findall(text)
    }
    arcs = {arc: int(count) for arc, count in LEGEND_ARC_RE.findall(text)}
    groups = {register: role for register, role in REGISTER_GROUP_RE.findall(text)}
    return rows, actions, arcs, groups


def main() -> int:
    errors: list[str] = []
    for path in (BUILDER, WINDOW, WINDOW_TEXT, VOCABULARY, GRAMMAR, DISCOURSE):
        if not path.exists():
            errors.append(f"{path.relative_to(ROOT)} does not exist")
    if errors:
        for error in errors:
            print(f"FAIL: {error}", file=sys.stderr)
        return 1

    for path in (BUILDER, Path(__file__)):
        try:
            py_compile.compile(str(path), doraise=True)
        except py_compile.PyCompileError as exc:
            errors.append(f"{path.name} does not compile: {exc}")

    workdir = Path(tempfile.mkdtemp(prefix="corpus-window-"))
    try:
        first_pl = workdir / "first.pl"
        first_txt = workdir / "first.txt"
        second_pl = workdir / "second.pl"
        second_txt = workdir / "second.txt"
        first = _run_builder(first_pl, first_txt)
        second = _run_builder(second_pl, second_txt)
        for label, result in (("first", first), ("second", second)):
            if result.returncode:
                errors.append(
                    f"{label} builder run failed with exit {result.returncode}: "
                    f"{result.stderr.strip()}"
                )
        if not errors:
            if first_pl.read_bytes() != WINDOW.read_bytes():
                errors.append("generated Prolog differs from knowledge/index/corpus_window.pl")
            if first_txt.read_bytes() != WINDOW_TEXT.read_bytes():
                errors.append("generated text differs from knowledge/index/corpus_window.txt")
            if first_pl.read_bytes() != second_pl.read_bytes():
                errors.append("two Prolog builder runs differ")
            if first_txt.read_bytes() != second_txt.read_bytes():
                errors.append("two text builder runs differ")
    finally:
        shutil.rmtree(workdir, ignore_errors=True)

    try:
        rows, legend_actions, legend_arcs, register_groups = _parse_rows()
    except (OSError, RuntimeError, ValueError) as exc:
        errors.append(str(exc))
        rows, legend_actions, legend_arcs, register_groups = [], {}, {}, {}

    if register_groups != REGISTER_BLOCK_ROLES:
        errors.append("window register grouping differs from the authored block roles")

    transition_text = "".join(
        path.read_text(encoding="utf-8")
        for path in sorted(TABLES.glob("*.pl")) + [DISCOURSE]
    )
    source_machines = {
        (family, signature)
        for family, signature, _source, _action, _target, _provenance
        in TRANSITION_RE.findall(transition_text)
    }
    row_keys = [(row[0], row[1]) for row in rows]
    if len(rows) != len(source_machines):
        errors.append(
            f"window has {len(rows)} rows for {len(source_machines)} source machines"
        )
    if set(row_keys) != source_machines:
        errors.append("window machine keys differ from transition-table machine keys")
    duplicate_keys = [key for key, count in collections.Counter(row_keys).items() if count != 1]
    if duplicate_keys:
        errors.append(f"window has repeated machine keys: {duplicate_keys}")

    vocabulary_text = VOCABULARY.read_text(encoding="utf-8")
    source_registers: dict[str, tuple[str, str, str]] = {}
    for action, genre, register, stance in REGISTER_RE.findall(vocabulary_text):
        if action in source_registers:
            errors.append(f"duplicate action_register/4 row for {action}")
        source_registers[action] = (genre, register, stance)
    if legend_actions != source_registers:
        errors.append("action legend differs from action_register/4")
    for row in rows:
        for action in row[3] + row[4] + row[5] + row[6]:
            if action not in legend_actions:
                errors.append(f"{row[0]}/{row[1]} action {action} is absent from the legend")

    grammar_text = GRAMMAR.read_text(encoding="utf-8")
    declared_arcs = set(ARC_RE.findall(grammar_text))
    source_arcs = {
        (family, signature): arc
        for _genre, family, signature, arc in GRAMMAR_RE.findall(grammar_text)
    }
    for family, signature, arc, *_groups in rows:
        if source_arcs.get((family, signature)) != arc:
            errors.append(f"{family}/{signature} arc does not match machine_grammar/6")
        if arc not in declared_arcs:
            errors.append(f"{family}/{signature} arc {arc} has no normative_arc/3")
    row_arc_counts = collections.Counter(row[2] for row in rows)
    if legend_arcs != dict(sorted(row_arc_counts.items())):
        errors.append("arc legend counts differ from the machine rows")

    starts = {
        (family, signature): start
        for family, signature, start, _accepting in TUPLE_RE.findall(transition_text)
    }
    projection = {
        (family, signature, local): canonical
        for family, signature, local, canonical in MAP_RE.findall(vocabulary_text)
    }
    edges: dict[tuple[str, str], set[tuple[str, str, str]]] = collections.defaultdict(set)
    for family, signature, source, action, target, _provenance in TRANSITION_RE.findall(
        transition_text
    ):
        edges[(family, signature)].add((source, action, target))
    source_words: dict[tuple[str, str], tuple[str, ...]] = {}
    for key in sorted(edges):
        routes: dict[str, list[tuple[str, str]]] = collections.defaultdict(list)
        for source, local, target in sorted(edges[key]):
            canonical = projection.get((key[0], key[1], local), local)
            if canonical not in [action for action, _target in routes[source]]:
                routes[source].append((canonical, target))
        state = starts[key]
        seen = {state}
        word: list[str] = []
        while routes.get(state):
            outgoing = routes[state]
            if len(outgoing) != 1:
                errors.append(
                    f"{key[0]}/{key[1]} has {len(outgoing)} canonical routes from {state}"
                )
                break
            action, target = outgoing[0]
            word.append(action)
            if target in seen:
                break
            seen.add(target)
            state = target
        source_words[key] = tuple(word)

    for family, signature, arc, shell, core, closure, other in rows:
        word = source_words.get((family, signature), ())
        expected_shell = tuple(
            action for action in word if source_registers[action][1] in SHELL_REGISTERS
        )
        expected_core = tuple(
            action for action in word if source_registers[action][1] in CORE_REGISTERS
        )
        expected_closure = tuple(
            action for action in word if source_registers[action][1] in CLOSURE_REGISTERS
        )
        expected_other = tuple(
            action
            for action in word
            if source_registers[action][1]
            not in SHELL_REGISTERS | CORE_REGISTERS | CLOSURE_REGISTERS
        )
        if (shell, core, closure, other) != (
            expected_shell,
            expected_core,
            expected_closure,
            expected_other,
        ):
            errors.append(
                f"{family}/{signature} partition does not reproduce its canonical word"
            )

    text_bytes = WINDOW_TEXT.read_bytes()
    try:
        text_bytes.decode("ascii")
    except UnicodeDecodeError:
        errors.append("corpus_window.txt is not ASCII")
    if b"\r" in text_bytes:
        errors.append("corpus_window.txt does not use LF-only endings")
    if any(line.rstrip() != line for line in text_bytes.decode("ascii", errors="ignore").splitlines()):
        errors.append("corpus_window.txt has trailing whitespace")

    consult = subprocess.run(
        [
            "swipl",
            "-q",
            "--on-warning=status",
            "--on-error=status",
            "-g",
            f"consult('{WINDOW.relative_to(ROOT)}'), "
            f"findall([F,S],window_row(F,S,_,_,_,_),Rows), "
            f"length(Rows,{len(source_machines)}), "
            f"findall([R,G],window_register_group(R,G),Groups), "
            f"length(Groups,{len(REGISTER_BLOCK_ROLES)}), halt.",
        ],
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=180,
        check=False,
    )
    if consult.returncode:
        errors.append(
            f"window_row/6 query failed: {consult.stdout.strip()} {consult.stderr.strip()}"
        )

    if errors:
        print(f"FAIL corpus window: {len(errors)} problem(s)", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    other_actions = [action for row in rows for action in row[6]]
    other_registers = sorted({source_registers[action][1] for action in other_actions})
    other_machines = sum(bool(row[6]) for row in rows)
    estimate = len(text_bytes) / 4

    print("PASS regeneration is byte-identical twice for Prolog and text artifacts")
    print(f"PASS every machine is present: {len(rows)} rows for {len(source_machines)} machines")
    print(
        f"PASS every indexed action resolves to the exact legend metadata "
        f"({len(legend_actions)} actions)"
    )
    print(
        f"PASS every machine arc is assigned by machine_grammar/6 and declared by "
        f"normative_arc/3 ({len(legend_arcs)} arcs)"
    )
    print("PASS every partition reproduces its machine's canonical action word")
    print("PASS every authored register group is queryable from corpus_window.pl")
    print(
        f"PASS token budget report: {len(text_bytes)} bytes; "
        f"bytes/4 estimate {estimate:.1f} tokens"
    )
    print(
        f"PASS Other count: {len(other_actions)} actions in {other_machines} machines; "
        f"registers={other_registers}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
