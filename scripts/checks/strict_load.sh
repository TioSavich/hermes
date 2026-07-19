#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$repo_root"

diagnostics=$(mktemp)
trap 'rm -f "$diagnostics"' EXIT

if ! swipl --on-error=status --on-warning=status -q \
    -l hermes_worker.pl -g "load_runtime, halt." >"$diagnostics" 2>&1; then
    cat "$diagnostics" >&2
    exit 1
fi
if rg -n 'ERROR:|Warning:' "$diagnostics"; then
    echo "strict worker load emitted diagnostics" >&2
    exit 1
fi

modules=(
    sar_add_rmb
    sar_add_chunking
    sar_add_counting_on
    sar_add_rounding
    sar_add_cobo
    sar_sub_cbbo_take_away
    sar_sub_cobo_missing_addend
    sar_sub_sliding
    sar_sub_decomposition
    sar_sub_counting_back
    sar_sub_rounding
    sar_sub_chunking_a
    sar_sub_chunking_b
    sar_sub_chunking_c
    smr_mult_c2c
    smr_mult_commutative_reasoning
    smr_mult_dr
    smr_mult_cbo
    smr_div_cbo
    smr_div_dealing_by_ones
    smr_div_ucr
    smr_div_idp
    state_vocabulary
    smr_frac_nl_compare
)

for module in "${modules[@]}"; do
    swipl --on-error=status --on-warning=status -q -l paths.pl \
        -g "use_module(math($module), []), halt."
done

swipl --on-error=status --on-warning=status -q -l paths.pl -g "
    use_module(math(sar_add_rmb), []),
    sar_add_rmb:run_rmb(8, 7, 15, _),
    use_module(math(sar_sub_rounding), []),
    sar_sub_rounding:run_sub_rounding(53, 28, 25, _),
    use_module(math(smr_mult_c2c), []),
    smr_mult_c2c:run_c2c(3, 4, 12, _),
    use_module(math(smr_div_dealing_by_ones), []),
    smr_div_dealing_by_ones:run_dealing_by_ones(12, 3, 4, _),
    halt."

echo "PASS strict worker load, 24 isolated strategy loads, and four execution probes"
