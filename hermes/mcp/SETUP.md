# Hermes MCP setup

Hermes can serve its local mathematical tools to an MCP client over standard
input and output. It does not open a network port, install Python packages, or
need a REALLMS key for this use.

## Before you begin

You need:

- Git, to obtain this repository.
- Python 3.10 or later. Hermes uses only the Python standard library for MCP;
  do not run `pip install`.
- SWI-Prolog 9.2.9 or a current stable 9.x release, available as `swipl` on
  your `PATH`. The verified checkout uses 9.2.9, and the worker starts that
  executable directly with no separate Prolog package installation.

Confirm the two runtimes before continuing:

```sh
python3 --version
swipl --version
```

Clone the repository and enter it:

```sh
git clone https://github.com/tiosavich/hermes.git
cd hermes
```

If your colleague gave you a different repository URL, use that URL instead.

## Check the local instrument

From the repository root, run:

```sh
python3 -m hermes.mcp.selfcheck
```

The first call starts the Prolog worker and can take a little while. The check
prints a `PASS` or `FAIL` for a covered monitoring chart, a fraction claim, and
a strategy trace. Each failure includes its next repair step. Do this before
changing your client configuration.

## Register the server

Start with the `core` mode. It is the small, colleague-facing tool set. The
`registry` mode exposes every registered capability and is better suited to
inspection once the core tools are familiar.

For Claude Code, run this from the repository root after replacing the path
with the absolute path to your checkout:

```sh
claude mcp add --transport stdio hermes -- python3 /absolute/path/to/hermes/hermes/mcp/server.py --mode core
```

For a client that reads an `.mcp.json` file, use this shape:

```json
{
  "mcpServers": {
    "hermes": {
      "command": "python3",
      "args": [
        "/absolute/path/to/hermes/hermes/mcp/server.py",
        "--mode",
        "core"
      ]
    }
  }
}
```

Restart or reload your MCP client after registering it. The client starts the
server when it needs a tool; running `server.py` by hand is useful only for
protocol debugging.

## First three calls

Ask the MCP client to make these tool calls. They use checked, covered inputs.

1. `monitoring_chart` with `{"code":"IM-G3-U5-L1"}`.
2. `check_math_claim` with `{"term":"3/4 = 6/8"}`.
3. `strategy_trace` with `{"strategy":"count_on_from_larger","input":{"a":47,"b":28}}`.

For another strategy, use the `strategy_trace` tool schema: it lists the
registered strategy names and an input example for each one.

## Offline artifacts

Core monitoring, claim, and strategy calls use the checked-in symbolic
knowledge base. Two optional offline artifact families support additional MCP
paths:

- `data/research/misconception_embeddings.json` and
  `data/research/misconception_embeddings.npz` support
  `misconception_search_rows` and `resonance_neighbors`. If either is absent
  or invalid, rebuild both with:

  ```sh
  python3 scripts/research/misconception_embedding.py build
  ```

- `hermes/capability_registry.pl` supplies the tool list in `registry` mode.
  If it is absent, rebuild it with:

  ```sh
  python3 scripts/extract_capability_registry.py
  ```

## Limits

The worker starts on the first tool call, so that call has visible boot
latency. Hermes MCP has no network tools. It is for MCP clients that can call
tools; REALLMS-hosted models cannot themselves drive MCP. REALLMS is not
needed for the local symbolic calls described here.
