# Hermes

A teaching console for K–8 mathematics. A Python server (standard library
only) runs a local web console; a SWI-Prolog worker carries the knowledge
base it reasons with: children's arithmetic strategies encoded as action
automata, a misconception registry compiled from the research literature,
CCSS and Indiana standards, and lesson monitoring charts for the
Illustrative Mathematics curriculum.

Everything runs on your own machine at `http://127.0.0.1:8765`. Nothing is
published anywhere by starting it.

## What it does

- **Check student work.** Paste or drop a work sample and ask the Prolog
  worker whether a strategy or misconception claim holds against the
  knowledge base, with the reasoning trace attached.
- **Monitor a lesson.** For an IM lesson, the chart names the strategies the
  lesson calls for and the student work that would signal each one.
- **Trace strategies.** Run an arithmetic strategy (counting on, chunking,
  make-a-ten, and the rest of the registry) step by step, or draw fraction
  arithmetic as partitioned bars.
- **Read the literature.** Coded student-work samples from published
  research, organized by strategy and misconception.
- **Build discussion reports.** A two-pass workflow turns a class transcript
  into a teacher-facing report of talk moves and mathematical postures.

## Run it

**Locally.** Install [SWI-Prolog](https://www.swi-prolog.org/download/stable)
and Python 3, then:

```sh
bash hermes/app/launch.sh
```

The console opens at `http://127.0.0.1:8765`.
`hermes/app/QUICKSTART_N103.md` walks the setup one step at a time and
assumes no Prolog or Python background.

**With Docker.**

```sh
docker build -t hermes .
docker run --rm -p 8765:8765 hermes
```

**As a folder that runs from a flash drive.**
`scripts/bundle/build_app_bundle.py` assembles a self-contained copy with
vendored SWI-Prolog and Python (Apple Silicon Macs).

## Boundaries, named plainly

- The LLM surfaces (drafting prose, the class workflow, building a new
  discussion report) need an IU REALLMS key, and REALLMS answers only from
  the IU network. Without a key, each of those surfaces says so. Every
  symbolic surface — strategy runs, misconception checks, lesson charts,
  the visualizers, the literature corpus — works offline.
- The PDF homework surface needs `pdftotext` (Poppler); the Docker image
  carries it, a local install may not.
- Student data never enters this repository. Anything you paste or drop
  stays in `hermes/app/runtime/` on your machine, which git ignores. The
  FERPA gate is off by default for loopback launches; launch with
  `HERMES_GATE=on` to restore the lock.

## Verify a checkout

```sh
python3 scripts/bundle/smoke_bundle.py
```

The smoke gate stages the runtime manifest and exercises it the way a
browser will: every static target in the shipped pages must resolve, the
live routes must answer (the LLM-backed ones with a clean no-key message),
and the report chain runs end to end on a toy transcript.

`scripts/bundle/app_manifest.py` names the file set this repository
carries and why (`KEEP_TREES_RATIONALE` in that file, one rationale per
directory); its `--verify` flag proves the set covers the Prolog worker's
real load closure. The full test suites live with the source project.

## Where this comes from

Hermes is the application face of a research program in mathematics
education. This repository carries the runtime: the console, the symbolic
knowledge base, and the distribution tooling. The research instruments and
their history live in the source project and are not part of this
repository.
