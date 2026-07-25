#!/usr/bin/env python3
"""Embed the converted literature corpus, one journal at a time, checkpointed.

The corpus is 2,183 markdown documents on scratch, converted from PDF by the
docling pipeline and organised by journal.  Two pieces of work downstream need
passage-level retrieval over it and neither can have it today:

  * 1,170 `too_vague` rows in `curriculum/im/generated/lesson_resonance.pl` each
    carry an author, a year and a database row, and no passage.  Naming those
    misconceptions from case models rather than renaming them mechanically needs
    the passage the citation points at.
  * `docs/research/2026-07-25-the-window-was-asked.md` names an embedding
    retriever over the same material as the comparison its keyword baseline could
    not stand in for.

Written against `transformers` directly rather than `sentence_transformers`,
because the Big Red `umedcta` env has the former and not the latter, and adding a
dependency to a networkless compute node is a way to lose a job at hour three.
Mean pooling over the last hidden state with an attention mask is what the
`bge-small` family expects; the query prefix convention is left to the consumer,
since these are passages and not queries.

Checkpoint discipline: one output pair per journal, written atomically, and a
rerun skips journals already complete.  Nothing here finishes in under thirty
minutes, so it must survive being killed.

Usage on the login node, which has network and warms the cache for the compute
nodes that do not:

    python embed_corpus.py --corpus DIR --out DIR --journals FLM --limit 1

Then as an array, one journal per task:

    python embed_corpus.py --corpus DIR --out DIR --journal-index $SLURM_ARRAY_TASK_ID
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import tempfile
from pathlib import Path

MODEL = "BAAI/bge-small-en-v1.5"
CHUNK_CHARS = 1400
CHUNK_OVERLAP = 200
BATCH = 32


def log(message: str) -> None:
    print(message, flush=True)          # unbuffered: a killed job keeps its record


def chunks_of(text: str) -> list[tuple[int, str]]:
    """Character windows with overlap, split on paragraph edges where possible."""
    out: list[tuple[int, str]] = []
    start = 0
    length = len(text)
    while start < length:
        end = min(start + CHUNK_CHARS, length)
        if end < length:
            edge = text.rfind("\n\n", start + CHUNK_CHARS // 2, end)
            if edge > start:
                end = edge
        piece = text[start:end].strip()
        if len(piece) >= 120:
            out.append((start, piece))
        if end >= length:
            break
        start = max(end - CHUNK_OVERLAP, start + 1)
    return out


def journal_dirs(corpus: Path) -> list[Path]:
    return sorted(p for p in corpus.iterdir() if p.is_dir())


def write_atomic(path: Path, write) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(dir=path.parent, prefix=f".{path.name}.")
    os.close(descriptor)
    try:
        write(Path(temporary))
        Path(temporary).replace(path)
    except BaseException:
        Path(temporary).unlink(missing_ok=True)
        raise


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--corpus", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--journals", nargs="*", default=None)
    parser.add_argument("--journal-index", type=int, default=None,
                        help="0-based index into the sorted journal list (array mode)")
    parser.add_argument("--limit", type=int, default=0,
                        help="documents per journal; 0 = all. Use 1 for the "
                             "login-node warm-up that caches the model")
    parser.add_argument("--model", default=MODEL)
    args = parser.parse_args()

    if not args.corpus.is_dir():
        log(f"FAIL corpus not a directory: {args.corpus}")
        return 1

    every = journal_dirs(args.corpus)
    if args.journal_index is not None:
        if args.journal_index >= len(every):
            log(f"nothing to do: index {args.journal_index} of {len(every)} journals")
            return 0
        selected = [every[args.journal_index]]
    elif args.journals:
        wanted = set(args.journals)
        selected = [d for d in every if d.name in wanted]
    else:
        selected = every
    log(f"journals available {len(every)}, selected {[d.name for d in selected]}")

    import torch                                    # noqa: PLC0415
    from transformers import AutoModel, AutoTokenizer   # noqa: PLC0415

    device = "cuda" if torch.cuda.is_available() else "cpu"
    log(f"device {device}, model {args.model}")
    tokenizer = AutoTokenizer.from_pretrained(args.model)
    model = AutoModel.from_pretrained(args.model).to(device).eval()

    for journal in selected:
        vectors_path = args.out / f"{journal.name}.npy"
        meta_path = args.out / f"{journal.name}.jsonl"
        if vectors_path.exists() and meta_path.exists() and not args.limit:
            log(f"SKIP {journal.name}: already complete")
            continue

        documents = sorted(journal.glob("*.md"))
        if args.limit:
            documents = documents[:args.limit]
        if not documents:
            log(f"SKIP {journal.name}: no markdown")
            continue

        passages: list[str] = []
        records: list[dict] = []
        for document in documents:
            try:
                text = document.read_text(encoding="utf-8", errors="replace")
            except OSError as exc:
                log(f"  READ FAIL {document.name}: {exc}")
                continue
            for offset, piece in chunks_of(text):
                records.append({
                    "bibtex_key": document.stem,
                    "journal": journal.name,
                    "char_offset": offset,
                    "chars": len(piece),
                    "sha1": hashlib.sha1(piece.encode("utf-8")).hexdigest()[:16],
                    "text": piece,
                })
                passages.append(piece)
        if not passages:
            log(f"SKIP {journal.name}: no passages")
            continue
        log(f"  {journal.name}: {len(documents)} documents, {len(passages)} passages")

        import numpy                                 # noqa: PLC0415
        embedded = []
        with torch.no_grad():
            for index in range(0, len(passages), BATCH):
                batch = passages[index:index + BATCH]
                encoded = tokenizer(batch, padding=True, truncation=True,
                                    max_length=512, return_tensors="pt").to(device)
                output = model(**encoded).last_hidden_state
                mask = encoded["attention_mask"].unsqueeze(-1).float()
                pooled = (output * mask).sum(1) / mask.sum(1).clamp(min=1e-9)
                pooled = torch.nn.functional.normalize(pooled, p=2, dim=1)
                embedded.append(pooled.cpu().numpy().astype("float32"))
                if index % (BATCH * 20) == 0:
                    log(f"    {index}/{len(passages)}")
        matrix = numpy.vstack(embedded)
        log(f"  {journal.name}: matrix {matrix.shape}")

        if args.limit:
            log(f"WARM-UP ONLY for {journal.name}; not written")
            continue

        write_atomic(vectors_path, lambda p: numpy.save(p, matrix))
        write_atomic(meta_path, lambda p: p.write_text(
            "\n".join(json.dumps(r, sort_keys=True) for r in records) + "\n",
            encoding="utf-8"))
        log(f"WROTE {vectors_path.name} {meta_path.name}")

    log("done")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
