#!/usr/bin/env python3
"""Generate the checked shell-core-closure census for the machine corpus."""
from __future__ import annotations

import argparse
import collections
import difflib
import re
import sys
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts" / "research"))
import build_corpus_window as corpus_window


OUTPUT = ROOT / "knowledge" / "index" / "machine_block_decomposition.pl"
VOCABULARY_SOURCE = "knowledge/strategies/action_vocabulary_map.pl"
PASS = ("shell", "core", "closure")
ROLE_ORDER = {"shell": 0, "core": 1, "closure": 2}
ZERO_SHAPE_ORDER = (
    "missing_shell",
    "missing_core",
    "missing_closure",
    "outside_register_interrupts",
    "out_of_order_or_unclosed",
)


@dataclass(frozen=True)
class CensusRow:
    family: str
    signature: str
    source: str
    actions: tuple[str, ...]
    registers: tuple[str, ...]
    macro_route: tuple[str, ...]
    passes: int
    shape: str

    @property
    def outside_actions(self) -> tuple[tuple[str, str], ...]:
        return tuple(
            (action, register)
            for action, register in zip(self.actions, self.registers, strict=True)
            if corpus_window.REGISTER_BLOCK_ROLES[register] == "outside"
        )

    @property
    def block_route(self) -> tuple[str, ...]:
        return collapse(
            tuple(
                role
                for role in self.macro_route
                if role != "outside"
            )
        )

    @property
    def block_passes(self) -> tuple[tuple[str, ...], ...]:
        return split_block_passes(self.block_route)[0]

    @property
    def order_breaks(self) -> tuple[tuple[str, str], ...]:
        return split_block_passes(self.block_route)[1]

    @property
    def classification(self) -> str:
        route = self.block_route
        breaks = self.order_breaks
        if not route:
            return "unclassified_no_block_role"
        if not breaks:
            return "single_pass"
        if all(source == "closure" for source, _target in breaks):
            return "restart_after_closure"
        if all(edge == ("core", "shell") for edge in breaks):
            return "work_then_reprepare"
        return "mixed_order"


def atom(value: str) -> str:
    return (
        value
        if re.fullmatch(r"[a-z][A-Za-z0-9_]*", value)
        else "'" + value.replace("'", "''") + "'"
    )


def plist(values: tuple[str, ...]) -> str:
    return "[" + ", ".join(atom(value) for value in values) + "]"


def ppairs(values: tuple[tuple[str, str], ...], functor: str) -> str:
    return (
        "["
        + ", ".join(
            f"{functor}({atom(left)}, {atom(right)})" for left, right in values
        )
        + "]"
    )


def ppasses(values: tuple[tuple[str, ...], ...]) -> str:
    return "[" + ", ".join(f"pass({plist(value)})" for value in values) + "]"


def sources() -> dict[tuple[str, str], str]:
    result: dict[tuple[str, str], str] = {}
    for path in sorted(corpus_window.TABLES.glob("*.pl")) + [corpus_window.DISCOURSE]:
        for family, signature, _start, _accepting in corpus_window.TUPLE_RE.findall(
            path.read_text(encoding="utf-8")
        ):
            key = (family, signature)
            if key in result:
                raise RuntimeError(f"duplicate machine source for {family}/{signature}")
            result[key] = path.relative_to(ROOT).as_posix()
    return result


def collapse(roles: tuple[str, ...]) -> tuple[str, ...]:
    return tuple(role for index, role in enumerate(roles) if not index or role != roles[index - 1])


def split_block_passes(
    route: tuple[str, ...],
) -> tuple[tuple[tuple[str, ...], ...], tuple[tuple[str, str], ...]]:
    passes: list[list[str]] = []
    order_breaks: list[tuple[str, str]] = []
    for role in route:
        if passes and ROLE_ORDER[role] < ROLE_ORDER[passes[-1][-1]]:
            order_breaks.append((passes[-1][-1], role))
            passes.append([])
        elif not passes:
            passes.append([])
        passes[-1].append(role)
    return tuple(tuple(value) for value in passes), tuple(order_breaks)


def complete_passes(macro_route: tuple[str, ...]) -> int:
    """A route qualifies only when it is exactly [shell, core, closure]^N."""
    if not macro_route or len(macro_route) % len(PASS):
        return 0
    if any(macro_route[index : index + len(PASS)] != PASS for index in range(0, len(macro_route), len(PASS))):
        return 0
    return len(macro_route) // len(PASS)


def zero_shape(macro_route: tuple[str, ...]) -> str:
    """Give every zero-pass route one mutually exclusive remainder type."""
    if "outside" in macro_route:
        return "outside_register_interrupts"
    if "shell" not in macro_route:
        return "missing_shell"
    if "core" not in macro_route:
        return "missing_core"
    if "closure" not in macro_route:
        return "missing_closure"
    return "out_of_order_or_unclosed"


def inventory() -> list[CensusRow]:
    vocabulary = corpus_window.VOCABULARY.read_text(encoding="utf-8")
    projection = {(family, signature, local): canonical for family, signature, local, canonical in corpus_window.MAP_RE.findall(vocabulary)}
    register_data = {
        action: (genre, register, stance)
        for action, genre, register, stance in corpus_window.REGISTER_RE.findall(vocabulary)
    }
    live = {register for _genre, register, _stance in register_data.values()}
    if live != set(corpus_window.REGISTER_BLOCK_ROLES):
        raise RuntimeError("register block-role source disagrees with the live vocabulary")
    words = corpus_window.read_machine_words(projection, register_data)
    source_paths = sources()
    if set(words) != set(source_paths):
        raise RuntimeError("machine routes disagree with tuple source paths")
    rows = []
    for (family, signature), actions in sorted(words.items()):
        registers = tuple(register_data[action][1] for action in actions)
        roles = tuple(
            corpus_window.REGISTER_BLOCK_ROLES[register] for register in registers
        )
        macro_route = collapse(roles)
        passes = complete_passes(macro_route)
        rows.append(CensusRow(
            family, signature, source_paths[(family, signature)], actions, registers,
            macro_route, passes,
            f"complete_{passes}_passes" if passes else zero_shape(macro_route)
        ))
    return rows


def pass_band(passes: int) -> str:
    return {0: "zero", 1: "one", 2: "two", 3: "three"}.get(passes, "more_than_three")


def render(
    rows: list[CensusRow],
) -> tuple[
    str,
    collections.Counter[int],
    collections.Counter[str],
    collections.Counter[str],
    collections.Counter[str],
]:
    block_counts = collections.Counter(len(row.block_passes) for row in rows)
    classes = collections.Counter(row.classification for row in rows)
    bands = collections.Counter(pass_band(row.passes) for row in rows)
    zeroes = collections.Counter(row.shape for row in rows if row.passes == 0)
    if sum(zeroes.values()) != bands["zero"] or set(zeroes) - set(ZERO_SHAPE_ORDER):
        raise RuntimeError("zero-pass shapes do not partition the exact zero-pass denominator")
    lines = [
        "/** <module> Checked machine block decomposition",
        " *",
        " * register_block_role/2 exposes the grouping authored in the corpus-window",
        " * builder. The primary census collapses adjacent equal roles and starts a",
        " * new pass whenever the route moves backward in shell, core, closure order.",
        " * A role may be absent within a pass. This definition re-derives the block",
        " * and class counts recorded by this module.",
        " *",
        " * The action-grammar layer names recurring stance shapes such as",
        " * keep_work_keep_work_keep. This module keeps that layer distinct while",
        " * using action-oriented names: restart_after_closure and",
        " * work_then_reprepare. mixed_order retains the remaining order breaks.",
        " *",
        " * The delegation register remains outside the primary grammar. Every row",
        " * retains its outside actions. The exact-complete-pass facts provide a",
        " * separate stricter audit in which all three roles must occur and outside",
        " * registers interrupt a pass; those facts do not replace the primary census.",
        " *",
        " * Generated by scripts/extract_machine_block_decomposition.py.",
        " * Regenerate: python3 scripts/extract_machine_block_decomposition.py",
        " */",
        "",
        ":- module(machine_block_decomposition,",
        "          [ register_block_role/2,",
        "            machine_block_decomposition/6,",
        "            machine_decomposition_denominator/1,",
        "            machine_block_count/2,",
        "            machine_decomposition_class_count/2,",
        "            machine_decomposition_unclassified_count/1,",
        "            machine_exact_complete_pass_band_count/2,",
        "            machine_exact_zero_pass_shape_count/2",
        "          ]).",
        "",
    ]
    lines.extend(
        f"register_block_role({atom(register)}, {atom(role)})."
        for register, role in sorted(corpus_window.REGISTER_BLOCK_ROLES.items())
    )
    lines.extend(["", f"machine_decomposition_denominator({len(rows)})."])
    lines.extend(
        f"machine_block_count({count}, {block_counts[count]})."
        for count in sorted(block_counts)
    )
    lines.extend(
        f"machine_decomposition_class_count({atom(value)}, {classes[value]})."
        for value in sorted(classes)
    )
    unclassified = sum(
        total
        for value, total in classes.items()
        if value.startswith("unclassified_")
    )
    lines.extend(["", f"machine_decomposition_unclassified_count({unclassified}).", ""])
    lines.extend(
        f"machine_exact_complete_pass_band_count({band}, {bands[band]})."
        for band in ("zero", "one", "two", "three", "more_than_three")
    )
    lines.extend(
        f"machine_exact_zero_pass_shape_count({shape}, {zeroes[shape]})."
        for shape in ZERO_SHAPE_ORDER
    )
    lines.append("")
    for row in rows:
        structure = (
            "decomposition("
            f"block_route({plist(row.block_route)}), "
            f"passes({ppasses(row.block_passes)}), "
            f"order_breaks({ppairs(row.order_breaks, 'edge')}), "
            f"outside_actions({ppairs(row.outside_actions, 'action')}), "
            f"exact_route({plist(row.macro_route)}), "
            f"exact_complete_passes({row.passes}))"
        )
        provenance = (
            f"[source_relation({atom(row.source)}, automaton_transition/6), "
            f"source_relation({atom(VOCABULARY_SOURCE)}, action_maps/5), "
            f"source_relation({atom(VOCABULARY_SOURCE)}, action_register/4), "
            f"canonical_route({plist(row.actions)}), "
            f"register_route({plist(row.registers)}), "
            "derived_by(maximal_nondecreasing_block_passes/2)]"
        )
        lines.append(
            f"machine_block_decomposition({atom(row.family)}, "
            f"{atom(row.signature)}, {len(row.block_passes)}, "
            f"{atom(row.classification)}, {structure}, {provenance})."
        )
    rendered = "\n".join(lines) + "\n"
    rendered.encode("ascii")
    return rendered, block_counts, classes, bands, zeroes


def check(expected: str, output: Path) -> int:
    actual = output.read_bytes() if output.is_file() else b""
    if actual == expected.encode("ascii"):
        return 0
    print(
        "machine block decomposition is stale; run python3 "
        "scripts/extract_machine_block_decomposition.py",
        file=sys.stderr,
    )
    for line in list(
        difflib.unified_diff(
            actual.decode("ascii", errors="replace").splitlines(),
            expected.splitlines(),
            fromfile=str(output),
            tofile="freshly-derived",
            lineterm="",
        )
    )[:16]:
        print(line, file=sys.stderr)
    return 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--output", type=Path, default=OUTPUT)
    args = parser.parse_args()
    rows = inventory()
    rendered, block_counts, classes, bands, zeroes = render(rows)
    unclassified = sum(
        total
        for value, total in classes.items()
        if value.startswith("unclassified_")
    )
    summary = (
        f"rows={len(rows)}; block_counts="
        + ",".join(
            f"{count}:{block_counts[count]}" for count in sorted(block_counts)
        )
        + "; class_counts="
        + ",".join(f"{value}:{classes[value]}" for value in sorted(classes))
        + f"; unclassified={unclassified}; exact_complete_pass_bands="
        + ",".join(
            f"{band}:{bands[band]}"
            for band in ("zero", "one", "two", "three", "more_than_three")
        )
        + "; exact_zero_shapes="
        + ",".join(f"{shape}:{zeroes[shape]}" for shape in ZERO_SHAPE_ORDER)
    )
    if args.check:
        result = check(rendered, args.output)
        if result == 0:
            print(f"machine block decomposition current: {args.output}; {summary}")
        return result
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(rendered, encoding="ascii", newline="\n")
    print(f"machine block decomposition wrote: {args.output}; {summary}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
