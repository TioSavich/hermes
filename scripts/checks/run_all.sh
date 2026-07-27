#!/usr/bin/env bash
# Run every check in scripts/checks/. Each check prints PASS lines and exits
# nonzero on failure; this runner stops at the first failure and names it.
# The suite includes strict SWI-Prolog loads and Node renders; a full run
# takes several minutes. route_behavior.py binds a loopback port.
set -euo pipefail
CHECKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The two Prolog checks need -g main -t halt. Loading a file whose entry point is
# :- initialization(main, main) with -s does not run main: both checks sat in this
# suite contributing exit 0 without asserting anything. Found 2026-07-25 while
# checking whether a change to strategy_recognizer.pl had broken its round trips;
# it had not, and neither had anything else, because the check was not running.
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
run mcp_search_rows.py      python3 "$CHECKS_DIR/mcp_search_rows.py"
run math_claim_language.pl  swipl -q -l "$CHECKS_DIR/../../paths.pl" -s "$CHECKS_DIR/math_claim_language.pl" -g main -t halt
run pedagogical_questions_check.py python3 "$CHECKS_DIR/pedagogical_questions_check.py"
run strategy_recognizer.pl  swipl -q -l "$CHECKS_DIR/../../paths.pl" -s "$CHECKS_DIR/strategy_recognizer.pl" -g main -t halt
run mobius_band_readers.py  python3 "$CHECKS_DIR/mobius_band_readers.py"
run transition_tables.py    python3 "$CHECKS_DIR/transition_tables.py"
run vocabulary_licenses.py  python3 "$CHECKS_DIR/vocabulary_licenses.py"
run action_vocabulary_map.py python3 "$CHECKS_DIR/action_vocabulary_map.py"
run action_grammar.py       python3 "$CHECKS_DIR/action_grammar.py"
run corpus_window.py        python3 "$CHECKS_DIR/corpus_window.py"
run review_surface.py       python3 "$CHECKS_DIR/review_surface.py"
run automaton_input_contracts.py python3 "$CHECKS_DIR/automaton_input_contracts.py"
run relevance_negation.py   python3 "$CHECKS_DIR/relevance_negation.py"
run lesson_topics_cache.py  python3 "$CHECKS_DIR/lesson_topics_cache.py"
run canonical_phrases.py    python3 "$CHECKS_DIR/canonical_phrases.py"
run utterance_layers.py     python3 "$CHECKS_DIR/utterance_layers.py"
run attested_phrases.py     python3 "$CHECKS_DIR/attested_phrases.py"
run recognition_benchmark.py python3 "$CHECKS_DIR/recognition_benchmark.py"
run extract_capability_registry python3 "$CHECKS_DIR/../extract_capability_registry.py" --check
run self_description_census.py python3 "$CHECKS_DIR/self_description_census.py"
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
run math_claim_language_check.py python3 "$CHECKS_DIR/math_claim_language_check.py"
run quantity_claim_check.py python3 "$CHECKS_DIR/quantity_claim_check.py"

echo "all checks passed"
