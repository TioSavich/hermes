# strategies/math

The executable action automata: one per named arithmetic strategy, grouped by
operation.

## The registry

`action_automata_registry.pl` is the bridge. `run_action_automaton/6` runs a
strategy without the caller knowing whether it came from addition, subtraction,
multiplication, division, fractions, decimals, integers, or another domain. It
loads the per-operation action-pair modules: `sar_add_*`/`sar_sub_*` (addition
and subtraction reasoning), `smr_mult_*`/`smr_div_*` (multiplicative reasoning),
and the `fraction_*`, `decimal_*`, `integer_*`, `ratio_*`, `measurement_*`,
`probability_*`, `statistics_*`, `algebraic_*`, and `calculus_limits_*` families.
Each strategy is an automaton of named states and action pairs; `cgi_base.pl`
sets the working base.

## Comparison automata and their labels

Six comparison automata order or compare rationals: `smr_decimal_fraction_compare`,
`smr_frac_area_compare`, `smr_frac_benchmark_compare`,
`smr_frac_common_unit_compare`, `smr_frac_nl_compare`, `smr_frac_set_compare`
(with `smr_frac_equiv_cross_mult` for equivalence). They step through stable
state atoms.

`state_vocabulary.pl` crosswalks those atoms to literature labels. Display prefers
the Steffe/Olive/Hackenberg constructivist line, then Van de Walle, then the atom
itself (`display_default_tradition/2`); every `state_label/4` carries a citation,
and every alternate stays queryable with its provenance. The automata use the
atoms; the display labels are applied by the worker and `hermes/dispatch_spec.pl`,
not imported into the automata.

## Boundary

Automata run on representative operands within a bounded base. The labels record
which tradition names a state; they do not adjudicate which naming is correct.
