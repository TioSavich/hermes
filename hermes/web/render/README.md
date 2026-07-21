# hermes/web/render

The one browser-side render pipeline every Hermes scene page shares. It is
render-only: it draws a `{frames:[...]}` document forward and never computes a
result or edits a scene.

## What it holds

- `drawer.js` — the unified filmstrip drawer. It dispatches on `scene.format` per
  `docs/render-contract-v2.md` and resolves each fill's role atom to a CSS
  variable `var(--fig-<role>)` defined once in `hermes/web/hermes-tokens.css`.
- `compare.js` — the two-stage host for the compare pages, drawing a
  productive/deformation pair as two filmstrips on one shared step index; it
  reuses the drawer's internals rather than owning geometry.
- `node-adapter.js` — runs the same drawer offline in Node, the path the prebake
  and gallery-drift checks use.
- `request.js` — the timeout-bounded client for the local worker.
- `hermes-shell.js` — the persistent app shell dropped into each page head.
- `host.css`, `shell.css` — the shared page chrome and the one navigation bar.

## Boundary

The scene compilers that produce these documents live in `knowledge/strategies/render/`;
this directory only draws them. The Node adapter renders in Node and Python on
one machine, so it cannot catch a browser/Node divergence; the drawing contract
is `docs/render-contract-v2.md`.
