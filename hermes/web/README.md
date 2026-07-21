# hermes/web

The browser surfaces: the public Hermes pages and the render pipeline they share.
These are static files, served by the app under `/more-zeeman/`.

## What it holds

- Pages: `index.html` and `landing.html` (entry), `strategies.html`,
  `visualizations.html`, `witnesses.html`, `scoreboard.html`,
  `monitoring_chart.html`, `atlas.html`, `gallery.html`, and the crisis,
  boundary, coordination, bridge, fractal, matrix, muds, and playground pages.
- Per-representation host directories (`base-ten/`, `fraction-bars/`,
  `number-line/`, `area-model/`, `balance-scale/`, `place-value-chart/`,
  `notation/`, `set-grouping/`, `unit-echo/`, `hybridization/`, `strategies/`).
- `render/` — the shared browser-side render pipeline. See `render/README.md`.
- Shared assets: `hermes-tokens.css` and `hermes-tokens-dark.css` (the `--fig-<role>`
  variables the drawer resolves), `shared.js`, `spine.js`, `metaphor-art.js`,
  `more-machine.js`, `mud-render.js`, `muds-main.js`.
- `prolog/` — the Zeeman catastrophe machine (`zeeman_machine`,
  `zeeman_bifurcation`, `zeeman_tape`, `zeeman_pml_bridge`).
- `data/` — sample JSON for the pages.

## Boundary and attribution

The pages fetch from the local worker; the symbolic visualizers work offline,
while the gallery needs the prebaked asset manifest. Third-party content shown on
a page carries its attribution: `gallery.html` and `witnesses.html` reproduce the
ASKTM NSF Grant No. 1561453 acknowledgement (`NOTICE.md`), and IM material
follows the terms in `NOTICE.md`.
