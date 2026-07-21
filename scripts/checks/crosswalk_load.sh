#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$repo_root"

swipl --on-error=status --on-warning=status -q -l paths.pl -g "
    use_module(crosswalk(canonical_all), []),
    canonical_all:crosswalk_family_count(38),
    canonical_all:validate_crosswalk_families,
    current_module(cw_deontic_incoherence),
    current_module(cw_strategy_action_kind),
    current_module(cw_stress_map),
    halt."

staged_crosswalk=$(mktemp -d)
diagnostics=$(mktemp)
trap 'rm -rf "$staged_crosswalk"; rm -f "$diagnostics"' EXIT
mkdir -p "$staged_crosswalk/families"
cp knowledge/crosswalk/canonical_all.pl knowledge/crosswalk/canonical_vocabulary.pl "$staged_crosswalk/"
for family in knowledge/crosswalk/families/cw_*.pl; do
    if [[ $(basename "$family") != cw_stress_map.pl ]]; then
        ln -s "$repo_root/$family" "$staged_crosswalk/families/$(basename "$family")"
    fi
done

if CROSSWALK_CHECK_ROOT="$staged_crosswalk" \
    swipl --on-error=status --on-warning=status -q -l paths.pl -g "
        getenv('CROSSWALK_CHECK_ROOT', RootString),
        atom_string(Root, RootString),
        retractall(user:file_search_path(crosswalk, _)),
        asserta(user:file_search_path(crosswalk, Root)),
        use_module(crosswalk(canonical_all), []),
        halt." >"$diagnostics" 2>&1; then
    echo "canonical_all unexpectedly loaded with cw_stress_map absent" >&2
    exit 1
fi
if ! rg -q 'cw_stress_map' "$diagnostics"; then
    cat "$diagnostics" >&2
    echo "missing-family diagnostic did not name cw_stress_map" >&2
    exit 1
fi

echo "PASS canonical_all loads 38 families and names a missing family"
