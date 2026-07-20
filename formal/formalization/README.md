# formalization

The formal arithmetic core: grounded arithmetic, the Lakoff & Núñez grounding
metaphors, Robinson Arithmetic Q, and the shared witness constructor.

## What it holds

- `witness_dict.pl` — `witness_dict/4`, the one constructor that adds the shared
  `kind` and `scope` fields to a domain-specific witness dict. The `crosswalk`,
  `geometry`, and `standards` witness families all build through it, so every
  witness shares one shape.
- `grounded_arithmetic.pl`, `grounded_ens_operations.pl`, `grounded_utils.pl` —
  arithmetic carried out without Prolog's built-in operators, grounded in an
  embodied number representation.
- `grounding_metaphors.pl` and `grounding_metaphors_extended.pl` — the Lakoff &
  Núñez grounding metaphors for arithmetic and beyond.
- `robinson_q.pl`, `axioms_robinson.pl` — Robinson Arithmetic Q inside the
  Hermeneutic Calculator.
- `modal_costs.pl`, `axioms_geometry.pl`, `axioms_number_theory.pl` — supporting
  axiom sets.
- `synthesis/` — a LaTeX and Prolog exploration of program synthesis from
  arithmetic primitives (`synth.pl`, the `run_*` drivers, and the `.tex` writeup).

## Consumers and boundary

`crosswalk/families/cw_driver.pl` reaches `grounded_arithmetic` and
`grounding_metaphors`; `strategies/` and `hermes_worker.pl` load the core.
Robinson Q is a deliberately weak arithmetic: the module encodes the mapping
from Q into the calculator to make queryable exactly where Gödel's First
Incompleteness Theorem bites. The limit is a finding to name, not a defect to
hide.
