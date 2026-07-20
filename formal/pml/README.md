# pml

Polarized (Phenomenological) Modal Logic: a material-inference calculus in
Brandom's sense, not a Kripke modal logic.

## The operators

`pml_operators.pl` declares three mode-of-validity wrappers — `s/1`, `o/1`, `n/1`
(Subjective, Objective, Normative) — and four polarized operators: `comp_nec`
(compressive necessity, ↓), `exp_nec` (expansive necessity, ↑), `exp_poss`
(expansive possibility, ↑), `comp_poss` (compressive possibility, ↓). It also
declares `neg/1` and the sequent arrow `=>`. The framework's twelve modal terms
arise by nesting a mode over a polarity, e.g. `s(comp_nec(Payload))`.
Operationally these operators tag and classify their payload; they succeed on a
well-formed term rather than deciding truth over accessibility relations.

## What else it holds

- `axioms_eml.pl`, `semantic_axioms.pl`, `pragmatic_axioms.pl` — the
  dialectical-rhythm material inferences, integrated with the sequent engine.
- `discourse_features.pl`, `discourse_pragmatics.pl` — deterministic transcript
  features and candidate relations.
- `mua_relations.pl`, `mua_conjectures.pl`, `mua_health.pl` — meaning-use
  relations for the action automata and their codebook guard.
- `talkmoves_adapter.pl`, `text_interpreter.pl`, `trace_adjudication.pl`,
  `intersubjective_praxis.pl` — adapters and multi-agent dynamics.
- `Modal_Logic/` — the LaTeX appendix (`AppendixA_Unified_2.tex/.pdf`), no code.

## Loading, consumers, boundary

No aggregate loader; `paths.pl` sets the `pml` alias and consumers
`use_module(pml(<module>))`. `hermes_worker.pl` and `arche-trace/load.pl` load a
broad set; the `strategies/math/*` automata import `pml_operators`. Discourse
markers stand in as proxies for modal posture. The framework has been tested for
consistency in Prolog; whether it admits a model-theoretic semantics is stated,
in the appendix, as an open question. That "not a Kripke logic" commitment lives
in the appendix, not in the code comments.
