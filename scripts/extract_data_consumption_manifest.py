#!/usr/bin/env python3
"""Generate the bounded Hermes data-consumption manifest.

The manifest makes the data tree navigable without treating every file as an
independent corpus.  Its unit is a file except for the two supplied corpora
whose members are not independently addressed by repository code:
``data/asktm/`` and ``data/research_assets/``.  Each is one directory corpus
row with a deterministic tree hash, file count, and byte count.  Every other
regular file below ``data/`` is one artifact.  This accounts for every regular
file in that tree.  The manifest also includes every JSON, JSONL, CSV, DB,
SQLite, or BibTeX artifact below ``scripts/``, ``knowledge/``, and
``curriculum/``.  It deliberately does not classify Prolog source facts,
Markdown, or application assets as data artifacts; their mixed code/data role
requires a different unit and would make this denominator silently unstable.

Readers and writers are static source joins, not runtime tracing.  Python
paths are recovered from literal strings, Path joins rooted at a repository
constant, simple named path constants, and glob bases.  Prolog and shell use
literal path arguments on known read or write calls. A call known to read or
write supplies its direction; path handling alone does not count as use. The
extractor records reader paths
that no longer resolve as missing-path rows.  It cannot see environment-derived
paths, reflection, database access hidden behind another module, shell
variables other than a repository-root prefix, or a path assembled from
nonconstant pieces.

Exact duplication is a byte hash for file artifacts and a sorted member-path
plus member-hash tree hash for directory corpora.  It detects only identical
artifact content.  It does not detect database-table subsets, normalized-text
matches, or duplicate members inside a corpus directory.
"""
from __future__ import annotations

import argparse
import ast
import difflib
import functools
import hashlib
import os
import re
import subprocess
import sys
import tempfile
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "knowledge" / "index" / "data_consumption_manifest.pl"
CORPUS_ROOTS = ("data/asktm", "data/research_assets")
STRUCTURED_SUFFIXES = {".bib", ".csv", ".db", ".json", ".jsonl", ".sqlite"}
SOURCE_SUFFIXES = {".py", ".pl", ".sh", ".js"}
SOURCE_ROOTS = ("scripts", "hermes", "knowledge", "curriculum", "formal")
SKIP_DIRECTORIES = {".git", ".venv", "node_modules", "__pycache__"}
PATH_PREFIX = re.compile(r"(?:data|scripts|knowledge|curriculum)/[A-Za-z0-9_.+@,()'/-]+")
PROLOG_OR_SHELL_PATH = re.compile(
    r"(?:\$\{?(?:ROOT|REPO|REPO_ROOT)\}?/)?"
    r"((?:data|scripts|knowledge|curriculum)/[A-Za-z0-9_.+@,()'/-]+)"
)
MISSING_PREFIXES = ("data/", "scripts/", "knowledge/", "curriculum/")


@dataclass(frozen=True)
class Artifact:
    path: str
    kind: str
    files: int
    bytes: int
    digest: str
    members: tuple[str, ...]


@dataclass(frozen=True)
class Reference:
    path: str
    source: str
    line: int
    direction: str
    method: str


def quote(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def atom(value: str) -> str:
    if re.fullmatch(r"[a-z][A-Za-z0-9_]*", value):
        return value
    return quote(value)


def relative(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def is_data_file(path: Path) -> bool:
    return path.suffix.lower() in STRUCTURED_SUFFIXES


def has_skipped_parent(path: Path) -> bool:
    return any(part in SKIP_DIRECTORIES for part in path.parts)


def digest_file(path: Path) -> tuple[str, int]:
    digest = hashlib.sha256()
    size = 0
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
            size += len(block)
    return digest.hexdigest(), size


@functools.lru_cache(maxsize=1)
def _ignored_paths() -> frozenset[str]:
    """Repo-relative paths git is told not to carry.

    The manifest indexes what this repository ships. Without this filter it also
    indexed process-local files — SQLite's ``-shm`` and ``-wal`` companions
    appear and vanish whenever the database is opened, so the ``--check`` mode
    could not stay green across a run that touched the corpus, and 374 rows
    described gitignored run outputs as though they were unconsumed artifacts.
    A check that cannot hold is worse than no check, and an inflated remainder
    is worse than an honest one.
    """
    result = subprocess.run(
        ["git", "ls-files", "--others", "--ignored", "--exclude-standard", "-z"],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=True,
    )
    return frozenset(name for name in result.stdout.split("\0") if name)


def carried(path: Path) -> bool:
    return relative(path) not in _ignored_paths()


def digest_tree(path: Path) -> tuple[str, int, int, tuple[str, ...]]:
    digest = hashlib.sha256()
    byte_count = 0
    members: list[str] = []
    for member in sorted(item for item in path.rglob("*") if item.is_file() and carried(item)):
        member_digest, member_size = digest_file(member)
        member_name = member.relative_to(path).as_posix()
        digest.update(member_name.encode("utf-8"))
        digest.update(b"\0")
        digest.update(member_digest.encode("ascii"))
        digest.update(b"\n")
        byte_count += member_size
        members.append(relative(member))
    return digest.hexdigest(), len(members), byte_count, tuple(members)


def collect_artifacts() -> tuple[list[Artifact], Counter[str]]:
    """Collect a complete, non-overlapping partition of the stated scope."""
    artifacts: list[Artifact] = []
    accounted: set[str] = set()
    for corpus in CORPUS_ROOTS:
        directory = ROOT / corpus
        if not directory.is_dir():
            raise RuntimeError(f"declared corpus root is absent: {corpus}")
        digest, files, bytes_, members = digest_tree(directory)
        artifacts.append(Artifact(corpus, "directory_corpus", files, bytes_, digest, members))
        accounted.update(members)

    all_data_files = sorted(
        path for path in (ROOT / "data").rglob("*") if path.is_file() and carried(path)
    )
    for path in all_data_files:
        name = relative(path)
        if name in accounted:
            continue
        digest, bytes_ = digest_file(path)
        artifacts.append(Artifact(name, "file", 1, bytes_, digest, (name,)))
        accounted.add(name)
    if accounted != {relative(path) for path in all_data_files}:
        raise RuntimeError("data-tree partition did not account for every regular file")

    for root_name in ("scripts", "knowledge", "curriculum"):
        source_root = ROOT / root_name
        for path in sorted(source_root.rglob("*")):
            if not path.is_file() or has_skipped_parent(path) or not is_data_file(path):
                continue
            if not carried(path):
                continue
            name = relative(path)
            digest, bytes_ = digest_file(path)
            artifacts.append(Artifact(name, "file", 1, bytes_, digest, (name,)))

    artifacts.sort(key=lambda item: item.path)
    if len({item.path for item in artifacts}) != len(artifacts):
        raise RuntimeError("artifact collection produced duplicate paths")
    roots = Counter()
    for artifact in artifacts:
        roots[artifact.path.split("/", 1)[0]] += artifact.files
    return artifacts, roots


def normalize_path(value: str) -> str | None:
    value = value.strip().rstrip(".,;:)]}>'")
    value = value.replace("\\", "/")
    while value.startswith("./"):
        value = value[2:]
    if value in {"data", "scripts", "knowledge", "curriculum"}:
        return value
    marker = re.search(r"(?:^|/)(data|scripts|knowledge|curriculum)/", value)
    if marker:
        value = value[marker.start(1):]
    if not value.startswith(MISSING_PREFIXES):
        return None
    return value


def scope_path(value: str) -> bool:
    """Whether a resolved path can name an artifact in this manifest's scope."""
    if value.startswith("data/"):
        return True
    return Path(value).suffix.lower() in STRUCTURED_SUFFIXES


def static_path(node: ast.AST, names: dict[str, str]) -> str | None:
    """Evaluate the small, intentionally bounded Path-expression language."""
    if isinstance(node, ast.Constant) and isinstance(node.value, str):
        return normalize_path(node.value)
    if isinstance(node, ast.Name):
        return names.get(node.id)
    if isinstance(node, ast.BinOp) and isinstance(node.op, (ast.Div, ast.Add)):
        left = static_path(node.left, names)
        right = static_path(node.right, names)
        if left and right:
            return normalize_path(f"{left}/{right}")
        if left and isinstance(node.right, ast.Constant) and isinstance(node.right.value, str):
            return normalize_path(f"{left}/{node.right.value}")
        if right and isinstance(node.left, ast.Constant) and isinstance(node.left.value, str):
            return normalize_path(f"{node.left.value}/{right}")
        return left or right
    if isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute):
        if node.func.attr in {"joinpath", "with_name"}:
            base = static_path(node.func.value, names)
            pieces = [static_path(argument, names) or getattr(argument, "value", None) for argument in node.args]
            if base and all(isinstance(piece, str) for piece in pieces):
                return normalize_path("/".join((base, *pieces)))
        if node.func.attr in {"glob", "rglob"}:
            return static_path(node.func.value, names)
    if isinstance(node, ast.Call) and isinstance(node.func, ast.Name) and node.func.id in {"Path", "PurePath"}:
        if node.args:
            return static_path(node.args[0], names)
    if isinstance(node, ast.JoinedStr):
        embedded = [
            static_path(item.value, names)
            for item in node.values
            if isinstance(item, ast.FormattedValue)
        ]
        paths = [item for item in embedded if item]
        if len(paths) == 1:
            return paths[0]
    return None


def call_name(node: ast.AST) -> str:
    if isinstance(node, ast.Name):
        return node.id
    if isinstance(node, ast.Attribute):
        return node.attr
    return ""


def literal_paths(value: str) -> set[str]:
    paths = set()
    for match in PATH_PREFIX.finditer(value):
        if normalized := normalize_path(match.group(0)):
            paths.add(normalized)
    return paths


class PythonReferences(ast.NodeVisitor):
    def __init__(self, source: str, path: Path) -> None:
        self.path = path
        self.names: dict[str, str] = {}
        self.references: list[Reference] = []
        self.source = source
        self.has_sql_writer = bool(re.search(r"\b(?:insert\s+into|create\s+table|update\s+\w+|delete\s+from)\b", source, re.I))

    def add(self, value: str | None, node: ast.AST, direction: str, method: str) -> None:
        if value:
            self.references.append(Reference(value, relative(self.path), getattr(node, "lineno", 1), direction, method))

    def visit_Assign(self, node: ast.Assign) -> None:
        value = static_path(node.value, self.names)
        if value:
            for target in node.targets:
                if isinstance(target, ast.Name):
                    self.names[target.id] = value
        self.generic_visit(node)

    def visit_AnnAssign(self, node: ast.AnnAssign) -> None:
        if node.value:
            value = static_path(node.value, self.names)
            if value and isinstance(node.target, ast.Name):
                self.names[node.target.id] = value
        self.generic_visit(node)

    def visit_Call(self, node: ast.Call) -> None:
        name = call_name(node.func).lower()
        receiver = node.func.value if isinstance(node.func, ast.Attribute) else None
        receiver_path = static_path(receiver, self.names) if receiver else None
        argument_paths = [static_path(argument, self.names) for argument in node.args]
        argument_paths = [value for value in argument_paths if value]
        mode = ""
        if name == "open" and len(node.args) > 1 and isinstance(node.args[1], ast.Constant):
            mode = str(node.args[1].value)
        for keyword in node.keywords:
            if keyword.arg == "mode" and isinstance(keyword.value, ast.Constant):
                mode = str(keyword.value.value)
        if name in {"write_text", "write_bytes", "writelines", "dump", "writerow", "writerows"}:
            self.add(receiver_path, node, "writer", name)
        elif name in {"read_text", "read_bytes", "readline", "readlines", "glob", "rglob", "iterdir"}:
            self.add(receiver_path, node, "reader", name)
        elif name == "open":
            direction = "writer" if any(flag in mode for flag in "wax+") else "reader"
            for value in argument_paths or ([receiver_path] if receiver_path else []):
                self.add(value, node, direction, "open")
        elif name == "connect":
            direction = "writer" if self.has_sql_writer else "reader"
            for value in argument_paths or ([receiver_path] if receiver_path else []):
                self.add(value, node, direction, "sqlite_connect")
        elif name in {"exists", "is_file", "is_dir", "resolve", "relative_to", "mkdir", "unlink"}:
            pass
        elif argument_paths and re.search(r"(?:read|load|parse|scan|ingest|consume|check|verify|query)", name):
            for value in argument_paths:
                self.add(value, node, "reader", name)
        self.generic_visit(node)


def scan_python(path: Path) -> list[Reference]:
    source = path.read_text(encoding="utf-8", errors="replace")
    try:
        tree = ast.parse(source, filename=str(path))
    except SyntaxError:
        return []
    visitor = PythonReferences(source, path)
    visitor.visit(tree)
    return visitor.references


def scan_text_source(path: Path) -> list[Reference]:
    """Read direct Prolog and shell path calls; dynamic forms remain unclaimed."""
    references: list[Reference] = []
    suffix = path.suffix.lower()
    for line_number, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
        for match in PROLOG_OR_SHELL_PATH.finditer(line):
            value = normalize_path(match.group(1))
            if not value:
                continue
            lowered = line.lower()
            writer = (
                ">" in line
                or re.search(r"\b(?:write|csv_write|json_write|save|export)\w*", lowered)
            )
            reader = re.search(r"\b(?:read|csv_read|json_read|consult|load|open|cat|sqlite3)\w*", lowered)
            if writer:
                direction, method = "writer", "text_writer_call"
            elif reader:
                direction, method = "reader", "text_reader_call"
            else:
                continue
            references.append(Reference(value, relative(path), line_number, direction, method))
    return references


def collect_references() -> list[Reference]:
    references: list[Reference] = []
    for root_name in SOURCE_ROOTS:
        root = ROOT / root_name
        if not root.is_dir():
            continue
        for path in sorted(root.rglob("*")):
            if (
                not path.is_file()
                or path.suffix.lower() not in SOURCE_SUFFIXES
                or has_skipped_parent(path)
                or path.resolve() == Path(__file__).resolve()
                # Generated index rows name data to report on it. They do not
                # open that data, so treating the indexes as consumers erases
                # the very remainder this manifest is meant to preserve.
                or relative(path).startswith("knowledge/index/")
            ):
                continue
            references.extend(scan_python(path) if path.suffix == ".py" else scan_text_source(path))
    return references


def artifacts_for_reference(path: str, artifacts: list[Artifact]) -> list[Artifact]:
    """Resolve an exact path, corpus prefix, directory, or static glob base."""
    bare = path.split("*", 1)[0].rstrip("/")
    matches = []
    for artifact in artifacts:
        if artifact.path == bare or artifact.path.startswith(bare + "/"):
            matches.append(artifact)
            continue
        if artifact.kind == "directory_corpus" and (bare.startswith(artifact.path + "/") or artifact.path.startswith(bare + "/")):
            matches.append(artifact)
    return matches


def source_term(reference: Reference) -> str:
    return f"reader({quote(reference.source)}, {reference.line}, {atom(reference.method)})"


def writer_term(reference: Reference) -> str:
    return f"writer({quote(reference.source)}, {reference.line}, {atom(reference.method)})"


def classify(artifact: Artifact, readers: list[Reference], writers: list[Reference]) -> tuple[str, str]:
    if readers and writers:
        return "reader_and_writer", "static_reader_and_writer"
    if readers:
        return "live_reader", "static_reader"
    if writers:
        return "writer_without_reader", "static_writer_no_reader"
    if artifact.kind == "directory_corpus":
        return "unconsumed_corpus", "no_static_reader_or_writer"
    return "unconsumed_file", "no_static_reader_or_writer"


def render_registry() -> tuple[str, dict[str, object]]:
    artifacts, root_files = collect_artifacts()
    references = collect_references()
    readers: dict[str, list[Reference]] = defaultdict(list)
    writers: dict[str, list[Reference]] = defaultdict(list)
    missing: set[Reference] = set()
    for reference in references:
        matches = artifacts_for_reference(reference.path, artifacts)
        if matches:
            for artifact in matches:
                (readers if reference.direction == "reader" else writers)[artifact.path].append(reference)
        elif reference.direction == "reader" and scope_path(reference.path):
            missing.add(reference)

    # Keep generated rows compact and deterministic even where two AST visits
    # encounter the same call through a nested expression.
    for collection in (readers, writers):
        for key in collection:
            collection[key] = sorted(set(collection[key]), key=lambda item: (item.source, item.line, item.method))
    rows = []
    statuses: Counter[str] = Counter()
    root_stats: dict[str, list[int]] = defaultdict(lambda: [0, 0, 0])
    for artifact in artifacts:
        artifact_readers = readers[artifact.path]
        artifact_writers = writers[artifact.path]
        status, reason = classify(artifact, artifact_readers, artifact_writers)
        statuses[status] += 1
        root = artifact.path.split("/", 1)[0]
        root_stats[root][0] += 1
        root_stats[root][1] += artifact.files
        root_stats[root][2] += artifact.bytes
        reader_list = "[" + ", ".join(source_term(item) for item in artifact_readers) + "]"
        writer_list = "[" + ", ".join(writer_term(item) for item in artifact_writers) + "]"
        rows.append(
            "data_artifact("
            f"{quote(artifact.path)}, {atom(artifact.kind)}, {artifact.files}, {artifact.bytes}, "
            f"{quote(artifact.digest)}, {atom(status)}, {atom(reason)}, {reader_list}, {writer_list})."
        )

    duplicate_groups: dict[str, list[str]] = defaultdict(list)
    for artifact in artifacts:
        duplicate_groups[artifact.digest].append(artifact.path)
    duplicates = [
        (digest, tuple(sorted(paths)))
        for digest, paths in duplicate_groups.items()
        if len(paths) > 1
    ]
    duplicates.sort(key=lambda item: (item[1], item[0]))

    controls = (
        (
            "learningcommons_coverage_registry",
            "data/learningcommons/derived/im_lesson_evidence.json",
            "scripts/extract_coverage_absence_registry.py",
            False,
        ),
        (
            "learningcommons_coverage_builder_claim",
            "data/learningcommons/derived/im_lesson_evidence.json",
            "scripts/research/build_im_coverage.py",
            False,
        ),
        (
            "learningcommons_lesson_evidence_builder",
            "data/learningcommons/derived/im_lesson_evidence.json",
            "scripts/curriculum/build_lesson_evidence.py",
            True,
        ),
        (
            "research_db_recognition_benchmark",
            "data/research/research_shared.db",
            "scripts/checks/recognition_benchmark.py",
            True,
        ),
        (
            "atlas_landscape_lesson_evidence",
            "scripts/bigred/iteration15/work/atlas/atlas_landscape.jsonl",
            "scripts/curriculum/build_lesson_evidence.py",
            True,
        ),
    )
    control_rows = []
    for name, artifact_path, reader_path, expected in controls:
        found = any(item.source == reader_path for item in readers.get(artifact_path, []))
        status = "resolved" if found else "not_found"
        expectation = "expected_reader" if expected else "declared_reader_not_in_checkout"
        control_rows.append((name, artifact_path, reader_path, status, expectation))
    if any(status != "resolved" for _name, _artifact, _reader, status, expectation in control_rows if expectation == "expected_reader"):
        failed = ", ".join(name for name, _artifact, _reader, status, expectation in control_rows if expectation == "expected_reader" and status != "resolved")
        raise RuntimeError(f"positive control did not resolve: {failed}")

    data_file_count = sum(item.files for item in artifacts if item.path.startswith("data/"))
    if data_file_count != root_files["data"]:
        raise RuntimeError("data-file denominator differs from the data-tree inventory")
    lines = [
        "/** <module> Generated data-consumption manifest",
        " *",
        " * The manifest partitions the current data tree into artifact rows. A row is",
        " * one file except data/asktm and data/research_assets, each one directory",
        " * corpus whose member files are supplied together and not independently",
        " * addressed by repository code. Every regular file in data/ belongs to exactly",
        " * one row. JSON, JSONL, CSV, DB, SQLite, and BibTeX files in scripts/,",
        " * knowledge/, and curriculum/ are also individual rows. Prolog source facts,",
        " * Markdown, and application assets are outside this bounded denominator.",
        " *",
        " * Reader and writer joins come from static Python, Prolog, and shell path",
        " * references. Python resolves literals, Path joins rooted at a repository",
        " * constant, simple named path constants, and glob bases. Prolog and shell",
        " * contribute literal path arguments. A missing reader path remains a row in",
        " * data_missing_reader_path/4; it is not repaired or discarded. Dynamic paths,",
        " * reflection, indirect database access, and nonconstant path assembly are",
        " * outside this instrument, so an unconsumed row means no reader it can see,",
        " * not proof that no runtime consumer exists.",
        " *",
        " * Statuses are derived from the current scan: live_reader; reader_and_writer;",
        " * writer_without_reader; unconsumed_file; and unconsumed_corpus. The latter",
        " * two are analysis markers only, never deletion recommendations.",
        " *",
        " * duplicate_content/2 uses an exact file byte hash or a deterministic corpus",
        " * tree hash. It cannot find table subsets, normalized-text matches, or equal",
        " * members hidden inside one directory corpus.",
        " *",
        " * Generated by scripts/extract_data_consumption_manifest.py.",
        " * Regenerate: python3 scripts/extract_data_consumption_manifest.py",
        " */",
        "",
        ":- module(data_consumption_manifest,",
        "          [ data_artifact/9,",
        "            data_artifact_denominator/2,",
        "            data_root_denominator/4,",
        "            data_status_count/2,",
        "            data_missing_reader_path/4,",
        "            duplicate_content/2,",
        "            data_consumption_control/5,",
        "            unconsumed_data_artifact/3",
        "          ]).",
        "",
    ]
    lines.extend(rows)
    lines.extend(["", f"data_artifact_denominator(data_tree_regular_file, {data_file_count}).", f"data_artifact_denominator(manifest_artifact, {len(artifacts)})."])
    for root in sorted(root_stats):
        artifact_count, files, bytes_ = root_stats[root]
        lines.append(f"data_root_denominator({atom(root)}, {artifact_count}, {files}, {bytes_}).")
    lines.append("")
    for status in ("live_reader", "reader_and_writer", "writer_without_reader", "unconsumed_file", "unconsumed_corpus"):
        lines.append(f"data_status_count({status}, {statuses[status]}).")
    lines.append("")
    for reference in sorted(missing, key=lambda item: (item.path, item.source, item.line, item.method)):
        lines.append(
            f"data_missing_reader_path({quote(reference.path)}, {quote(reference.source)}, "
            f"{reference.line}, {atom(reference.method)})."
        )
    lines.append("")
    for digest, paths in duplicates:
        lines.append("duplicate_content(" + quote(digest) + ", [" + ", ".join(quote(path) for path in paths) + "]).")
    lines.append("")
    for name, artifact_path, reader_path, status, expectation in control_rows:
        lines.append(
            f"data_consumption_control({atom(name)}, {quote(artifact_path)}, {quote(reader_path)}, {atom(status)}, {atom(expectation)})."
        )
    lines.extend([
        "",
        "unconsumed_data_artifact(Path, Kind, Reason) :-",
        "    data_artifact(Path, Kind, _, _, _, Status, Reason, [], []),",
        "    memberchk(Status, [unconsumed_file, unconsumed_corpus]).",
        "",
    ])
    measured = {
        "data_files": data_file_count,
        "artifacts": len(artifacts),
        "statuses": statuses,
        "duplicates": duplicates,
        "missing": missing,
        "controls": control_rows,
        "artifacts_by_path": {item.path: item for item in artifacts},
    }
    return "\n".join(lines), measured


def check_output(expected: str, output: Path) -> int:
    actual = output.read_text(encoding="utf-8") if output.is_file() else ""
    if actual == expected:
        print(f"data consumption manifest is current: {output.relative_to(ROOT)}")
        return 0
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", suffix=".pl", delete=False) as temporary:
        temporary.write(expected)
        temporary_path = Path(temporary.name)
    diff = list(difflib.unified_diff(actual.splitlines(), expected.splitlines(), fromfile=str(output), tofile=str(temporary_path), lineterm=""))
    print("data consumption manifest is stale; run python3 scripts/extract_data_consumption_manifest.py", file=sys.stderr)
    for line in diff[:12]:
        print(line, file=sys.stderr)
    temporary_path.unlink(missing_ok=True)
    return 1


def summary(output: Path, measured: dict[str, object], checked: bool) -> str:
    statuses: Counter[str] = measured["statuses"]  # type: ignore[assignment]
    state = "current" if checked else "written"
    return (
        f"data consumption manifest {state}: {output.relative_to(ROOT)}; "
        f"data_files={measured['data_files']}; artifacts={measured['artifacts']}; "
        + ", ".join(f"{status}={statuses[status]}" for status in sorted(statuses))
        + f"; missing_reader_paths={len(measured['missing'])}; exact_duplicate_groups={len(measured['duplicates'])}"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail if the generated manifest is stale")
    parser.add_argument("--output", type=Path, default=OUTPUT, help=argparse.SUPPRESS)
    arguments = parser.parse_args()
    output = arguments.output if arguments.output.is_absolute() else ROOT / arguments.output
    rendered, measured = render_registry()
    if arguments.check:
        result = check_output(rendered, output)
        if result == 0:
            print(summary(output, measured, True))
        return result
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(rendered, encoding="utf-8")
    print(summary(output, measured, False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
