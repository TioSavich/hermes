# hermes/app

The local teaching console: a Python standard-library HTTP server that fronts the
SWI-Prolog worker and serves the console and visualizer pages. `launch.sh` starts
it at `http://127.0.0.1:8765`; `QUICKSTART.md` walks the setup with no assumed
Prolog or Python background.

## The server

`server.py` owns the mutable server state for TLS preflight, workers, and caches behind an immutable
route registry and hands each request a per-request context. `routes/registry.py`
holds the `Route` record and `build_router`, which aggregates the `ROUTES` tuples
from `static`, `runtime`, `analysis`, `llm`, `monitoring`, `worker`, and
`workflow`. `routes/logic.py` carries the request handling.

- `worker.py` — keeps one SWI-Prolog worker alive and speaks newline-delimited
  JSON to `hermes_worker.pl`, so the symbolic layer reads the live KB.
- `llm.py` — the REALLMS client and secure preflight; `root.py` — resolves
  and validates the repository root.
- `workflow/` — the two-pass discussion report (`parse`, `draft`, `grade`,
  `profile`, `content`, `metrics`).
- `analysis/` — discourse, N103, ingest, media, and pipeline handlers.
- `monitoring/`, `system_prompts/`, `web/` (`console.html`, `discussions.html`),
  and `scripts/` (the `export_*` prebake tools).

## Boundary

The LLM surfaces need an IU REALLMS key and answer only from the IU network;
without a key each says so. Student data stays in `app/runtime/`, which git
ignores.
