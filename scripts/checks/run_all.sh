#!/usr/bin/env bash
# Run every check in scripts/checks/. Each check prints PASS lines and exits
# nonzero on failure; this runner stops at the first failure and names it.
# The suite includes strict SWI-Prolog loads and Node renders; a full run
# takes several minutes. route_behavior.py binds a loopback port.
set -euo pipefail
CHECKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run() {
    echo "== $1"
    "${@:2}"
}

run root_resolver.py        python3 "$CHECKS_DIR/root_resolver.py"
run route_registry.py       python3 "$CHECKS_DIR/route_registry.py"
run witness_registry.py     python3 "$CHECKS_DIR/witness_registry.py"
run witness_defaults.py     python3 "$CHECKS_DIR/witness_defaults.py"
run static_route_containment.py python3 "$CHECKS_DIR/static_route_containment.py"
run required_system_prompts.py python3 "$CHECKS_DIR/required_system_prompts.py"
run extract_capability_registry python3 "$CHECKS_DIR/../extract_capability_registry.py" --check
run render_contract.py      python3 "$CHECKS_DIR/render_contract.py"
run strict_load.sh          bash "$CHECKS_DIR/strict_load.sh"
run field_context_cache.py  python3 "$CHECKS_DIR/field_context_cache.py"
run crosswalk_load.sh       bash "$CHECKS_DIR/crosswalk_load.sh"
run geometry_load.sh        bash "$CHECKS_DIR/geometry_load.sh"
run strict_gate_failures.py python3 "$CHECKS_DIR/strict_gate_failures.py"
run workflow_service.py     python3 "$CHECKS_DIR/workflow_service.py"
run drawer_parity.sh        bash "$CHECKS_DIR/drawer_parity.sh"
run zeeman_bifurcation.sh   bash "$CHECKS_DIR/zeeman_bifurcation.sh"
run route_behavior.py       python3 "$CHECKS_DIR/route_behavior.py"

echo "all checks passed"
