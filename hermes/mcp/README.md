# Hermes MCP server

Run the standard-library-only stdio server from the repository root:

```sh
python3 hermes/mcp/server.py --mode core
```

`core` is the default. It offers a small tool surface for bounded Prolog queries, monitoring and deformation charts, fraction-equivalence checks, deontic scorekeeping, commitment matching, strategy traces, misconception lookup, and stored-vector resonance neighbors. `registry` exposes every current capability request in the registry. Its schemas preserve the registry's actual limit: it records parameter names, but not types or required/default status, so parameters are described as strings when their type is unknown.

Call `prolog_query` without `goal` to get its generated predicate listing. Narrow the listing with a predicate-name substring, a knowledge-relative file substring, or an exact arity. Then call it with one module-qualified goal from that listing. The complete goal call graph must pass SWI-Prolog's sandbox; accepted calls return no more than 100 solutions and run for no more than two seconds.

Register it with Claude Code:

```sh
claude mcp add --transport stdio hermes -- python3 /absolute/path/to/hermes/hermes/mcp/server.py --mode core
```

Or add this `.mcp.json` entry:

```json
{
  "mcpServers": {
    "hermes": {
      "command": "python3",
      "args": ["/absolute/path/to/hermes/hermes/mcp/server.py", "--mode", "core"]
    }
  }
}
```

The server has no network tools. Its Prolog worker boots on the first tool call, so that first call has a visible startup delay. `resonance_neighbors` only compares a selected stored misconception vector with other stored rows; it never makes a query-embedding network call. REALLMS-hosted models cannot drive MCP themselves: this server is for tool-capable interpreters, while the embedding form remains the interface for tool-less models.
