#!/usr/bin/env python3
"""Keep MathTutorBench text out of sidekick training data, mechanically.

Two gates, run before any training job. Provenance is the suspenders: a row
names the Hermes artifact it came from, and no row may name a benchmark
source. The 13-gram index is the belt, because a teacher model can reproduce a
benchmark phrasing it met in pretraining with no provenance link at all.

The index is built from the benchmark's own three sources, read where this
workstation already holds them, plus the run suites whose items the program
reports against. Building it needs those local copies; the builder names what
is missing rather than quietly indexing less.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable, Iterator

import numpy as np

REPO_ROOT = Path(__file__).resolve().parents[2]
EXPERIMENT = REPO_ROOT / "hermes" / "app" / "runtime" / "experiments" / "gemma4_tutor"
RUNTIME = REPO_ROOT / "hermes" / "app" / "runtime" / "experiments" / "sidekick"
INDEX_PATH = RUNTIME / "contamination" / "benchmark_13grams.npy"
MANIFEST_PATH = RUNTIME / "contamination" / "manifest.json"

GRAM = 13
# Probe turns and training turns are single sentences, so the benchmark's
# 13-gram window is longer than most of them and would call two rewordings of
# one item disjoint. Eight words is short enough to catch a paraphrase that
# kept its spine and long enough not to fire on shared ordinary phrasing.
SPLIT_GRAM = 8
REGISTER_MIN_LESSON_DF = 3
REGISTER_LEXICON_VERSION = "wave5-register-8gram-v1"
REGISTER_LEXICON_PATH = RUNTIME / "contamination" / "register_8grams.json"
HF_DATASETS = Path.home() / ".cache" / "huggingface" / "datasets"
FORBIDDEN_PROVENANCE = ("eth-nlped", "gsm8k", "mathdial", "stepverify", "vendor/")
WORD = re.compile(r"[a-z0-9]+")


@dataclass
class Source:
    label: str
    documents: int = 0
    grams: int = 0
    note: str = ""


@dataclass
class Corpus:
    sources: list[Source] = field(default_factory=list)
    missing: list[str] = field(default_factory=list)


def normalize(text: str) -> list[str]:
    return WORD.findall(text.casefold())


def grams(text: str, size: int = GRAM) -> Iterator[str]:
    words = normalize(text)
    for start in range(0, max(0, len(words) - size + 1)):
        yield " ".join(words[start : start + size])


def fingerprint(gram: str) -> int:
    return int.from_bytes(hashlib.blake2b(gram.encode("utf-8"), digest_size=8).digest(), "big")


def _strings(value: object) -> Iterator[str]:
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for item in value.values():
            yield from _strings(item)
    elif isinstance(value, list):
        for item in value:
            yield from _strings(item)


def _arrow_texts(directory: Path) -> Iterator[str]:
    import pyarrow.ipc as ipc

    for arrow in sorted(directory.rglob("*.arrow")):
        with ipc.open_stream(str(arrow)) as reader:
            table = reader.read_all()
        for column in table.column_names:
            for value in table.column(column).to_pylist():
                yield from _strings(value)


def collect(corpus: Corpus) -> Iterator[tuple[Source, str]]:
    """Yield every benchmark text this workstation holds, source by source."""
    for label, directory in (
        ("eth-nlped/stepverify", HF_DATASETS / "eth-nlped___stepverify"),
        ("gsm8k", HF_DATASETS / "gsm8k"),
        ("openai/gsm8k", HF_DATASETS / "openai___gsm8k"),
    ):
        if not directory.is_dir():
            corpus.missing.append(f"{label} ({directory})")
            continue
        source = Source(label=label, note=str(directory))
        corpus.sources.append(source)
        for text in _arrow_texts(directory):
            source.documents += 1
            yield source, text
    for name in ("mathdial_bridge.json", "mathdial_bridge_hard.json"):
        path = EXPERIMENT / "vendor" / "datasets" / name
        if not path.is_file():
            corpus.missing.append(f"{name} ({path})")
            continue
        source = Source(label=f"vendor/datasets/{name}", note=str(path))
        corpus.sources.append(source)
        for text in _strings(json.loads(path.read_text(encoding="utf-8"))):
            source.documents += 1
            yield source, text
    suite = EXPERIMENT / "suite"
    if not suite.is_dir():
        corpus.missing.append(f"run suites ({suite})")
        return
    for results in sorted(suite.rglob("results.jsonl")):
        source = Source(label=f"suite/{results.relative_to(suite).parent}", note=str(results))
        corpus.sources.append(source)
        for line in results.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            row = json.loads(line)
            for key in ("problem", "history", "ground_truth_response", "reference_answer"):
                if key in row:
                    for text in _strings(row[key]):
                        source.documents += 1
                        yield source, text


def build_index(destination: Path = INDEX_PATH) -> dict[str, object]:
    corpus = Corpus()
    fingerprints: set[int] = set()
    for source, text in collect(corpus):
        for gram in grams(text):
            fingerprints.add(fingerprint(gram))
            source.grams += 1
    if not fingerprints:
        raise RuntimeError(
            "No benchmark text was found, so the overlap gate would pass everything. "
            f"Missing: {corpus.missing}"
        )
    array = np.array(sorted(fingerprints), dtype=np.uint64)
    destination.parent.mkdir(parents=True, exist_ok=True)
    np.save(destination, array)
    manifest = {
        "gram": GRAM,
        "distinct_fingerprints": int(array.size),
        "sources": [
            {"label": s.label, "texts": s.documents, "grams": s.grams, "path": s.note}
            for s in corpus.sources
        ],
        "missing": corpus.missing,
        "index": str(destination),
    }
    MANIFEST_PATH.parent.mkdir(parents=True, exist_ok=True)
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return manifest


class OverlapGate:
    """Reject any text sharing a 13-gram with the benchmark corpus."""

    def __init__(self, index_path: Path = INDEX_PATH) -> None:
        if not index_path.is_file():
            raise FileNotFoundError(
                f"No benchmark n-gram index at {index_path}. "
                "Build it with: python3 scripts/sidekick/contamination.py build"
            )
        self.index = np.load(index_path)
        self.index_path = index_path

    def hits(self, text: str) -> list[str]:
        found: list[str] = []
        for gram in grams(text):
            probe = np.uint64(fingerprint(gram))
            position = int(np.searchsorted(self.index, probe))
            if position < self.index.size and self.index[position] == probe:
                found.append(gram)
        return found

    def clean(self, text: str) -> bool:
        return not self.hits(text)


def index_manifest(path: Path = MANIFEST_PATH) -> dict[str, object]:
    """What the overlap gate was built from, so a report can say so."""
    if not path.is_file():
        return {"available": False, "path": str(path)}
    manifest = json.loads(path.read_text(encoding="utf-8"))
    return {
        "available": True,
        "path": str(path),
        "gram": manifest.get("gram"),
        "distinct_fingerprints": manifest.get("distinct_fingerprints"),
        "sources": [source["label"] for source in manifest.get("sources", [])],
        "missing": manifest.get("missing", []),
    }


def split_overlap(
    left: dict[str, str], right: dict[str, str], size: int = SPLIT_GRAM
) -> list[dict[str, str]]:
    """Report every shared n-gram between two labelled sets of turns.

    Held-out means held out. String equality misses a probe item that was
    reworded from a training row and kept its mathematics, which is exactly the
    leak that would flatter a disposition number.
    """
    seen: dict[str, str] = {}
    for identity, text in left.items():
        for gram in grams(text, size):
            seen.setdefault(gram, identity)
    shared: list[dict[str, str]] = []
    for identity, text in right.items():
        for gram in grams(text, size):
            if gram in seen:
                shared.append({"left": seen[gram], "right": identity, "gram": gram})
    return shared


def derive_register_lexicon(
    statements: Iterable[tuple[str, str]],
    *,
    source: str,
    source_sha256: str,
    size: int = SPLIT_GRAM,
    minimum_lesson_df: int = REGISTER_MIN_LESSON_DF,
) -> dict[str, object]:
    """Derive register n-grams by distinct-lesson document frequency.

    Repetition inside one lesson contributes once. The document-frequency
    threshold is the complete selection rule; no phrase list is curated.
    """
    by_lesson: defaultdict[str, set[str]] = defaultdict(set)
    statement_count = 0
    for lesson, statement in statements:
        statement_count += 1
        by_lesson[lesson].update(grams(statement, size))
    lesson_df: Counter[str] = Counter()
    for lesson_grams in by_lesson.values():
        lesson_df.update(lesson_grams)
    entries = [
        {"gram": gram, "lesson_document_frequency": frequency}
        for gram, frequency in sorted(lesson_df.items())
        if frequency >= minimum_lesson_df
    ]
    return {
        "version": REGISTER_LEXICON_VERSION,
        "gram": size,
        "minimum_distinct_lessons": minimum_lesson_df,
        "derivation": "all statement 8-grams occurring in at least 3 distinct lessons",
        "split_unit": "lesson",
        "source": source,
        "source_sha256": source_sha256,
        "statement_rows": statement_count,
        "distinct_lessons": len(by_lesson),
        "distinct_statement_grams": len(lesson_df),
        "register_grams": len(entries),
        "entries": entries,
    }


def register_lexicon_bytes(artifact: dict[str, object]) -> bytes:
    return (json.dumps(artifact, ensure_ascii=False, indent=2, sort_keys=True) + "\n").encode()


def load_register_lexicon(
    path: Path = REGISTER_LEXICON_PATH,
) -> tuple[dict[str, object], set[str]]:
    if not path.is_file():
        raise FileNotFoundError(
            f"No register lexicon at {path}. "
            "Build it with: python3 scripts/sidekick/build_wave5_solution_mint.py"
        )
    artifact = json.loads(path.read_text(encoding="utf-8"))
    if artifact.get("gram") != SPLIT_GRAM:
        raise RuntimeError(f"register lexicon gram changed: {artifact.get('gram')}")
    if artifact.get("minimum_distinct_lessons") != REGISTER_MIN_LESSON_DF:
        raise RuntimeError(
            "register lexicon lesson-frequency threshold changed: "
            f"{artifact.get('minimum_distinct_lessons')}"
        )
    entries = artifact.get("entries")
    if not isinstance(entries, list):
        raise RuntimeError("register lexicon has no entries list")
    lexicon = {entry["gram"] for entry in entries}
    if artifact.get("register_grams") != len(lexicon):
        raise RuntimeError("register lexicon count does not match its entries")
    return artifact, lexicon


def register_aware_split_overlap(
    left: dict[str, str],
    right: dict[str, str],
    register_lexicon: set[str],
    size: int = SPLIT_GRAM,
) -> dict[str, list[dict[str, str]]]:
    """Apply the train-to-held-out gate while exempting register n-grams."""
    strict = split_overlap(left, right, size)
    register = [hit for hit in strict if hit["gram"] in register_lexicon]
    blocking = [hit for hit in strict if hit["gram"] not in register_lexicon]
    return {"strict": strict, "register": register, "blocking": blocking}


def provenance_hits(provenance: object) -> list[str]:
    """Name every forbidden source a provenance record mentions."""
    blob = json.dumps(provenance, ensure_ascii=False).casefold()
    return [name for name in FORBIDDEN_PROVENANCE if name in blob]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("build", "check"))
    parser.add_argument("--text", help="check: one text to test for overlap")
    arguments = parser.parse_args()
    if arguments.action == "build":
        manifest = build_index()
        print(f"distinct 13-gram fingerprints: {manifest['distinct_fingerprints']}")
        for source in manifest["sources"]:
            print(f"  {source['texts']:7d} texts  {source['grams']:9d} grams  {source['label']}")
        if manifest["missing"]:
            print("MISSING (indexed nothing from):")
            for item in manifest["missing"]:
                print(f"  {item}")
        return 0
    gate = OverlapGate()
    if not arguments.text:
        parser.error("check needs --text")
    hits = gate.hits(arguments.text)
    print(f"index: {gate.index.size} fingerprints; hits: {len(hits)}")
    for hit in hits[:5]:
        print(f"  {hit}")
    return 1 if hits else 0


if __name__ == "__main__":
    raise SystemExit(main())
