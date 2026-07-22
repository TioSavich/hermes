# Big Red scenario suite

This suite runs without network access and writes each completed scenario to
`.bigred-output/` in the scratch checkout. Each runner accepts `--limit N` for
a small local smoke run. A completed scenario has a `COMPLETE` marker and is
not regenerated on a later submission.

`run_hyperedges.sh` re-checks the finite emergent-hyperedge search and records
its textual search report plus a JSON list of the live emergent sets. Runtime:
medium. Inspect `search.md` first, then compare `hyperedges.json` with the
tracked discovery cache before treating a changed result as a finding.

`run_search_traces.sh` walks bounded carving-machine targets. Every JSON and
Markdown trace is an ordered transition list with the predicate facts that
license its steps. Runtime: short at the supplied bounds; it grows with the
path bound. Use the traces as finite algorithm artifacts, not as a claim about
unbounded search.

`run_predicate_carving.sh` materializes the finite inferential-strength report
for every encoded lesson, one row for every registered operation, and ordered
finite containment verdicts over the lesson vocabulary. Runtime: long. The
operation rows say when no carving-machine model exists; that is a coverage
boundary, not an execution result.

`run_representation_html.sh` runs the established deformation and notation
lesson exporters. Runtime: long. Copy the generated trees only after reviewing
their JSON chart data and the HTML/SVG output.

The live registry has 172 action-automaton invocation signatures. It does not
provide a general concrete-input generator for every signature, so an
all-automata modeling grid is not included. That scenario is not batchable
today: it needs a checked input-instantiation contract per signature (or a
separate verified six-comparator runner) before a batch script can honestly
execute it.

Submit with `sbatch scripts/bigred/suite/suite.slurm` after replacing the
account and email placeholders. Run `bash scripts/bigred/suite/collect.sh` on
the local checkout after setting the remote variables to gather one tarball.
