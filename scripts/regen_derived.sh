#!/usr/bin/env bash
# Regenerate every derived register, in dependency order.
#
# Change an automaton and several generated files go stale at once. Each has
# its own --check gate, and each gate fails one at a time. A run of the gate
# chain then costs one full pass per stale register. This script does the
# catch-up in a single pass instead.
#
# The order is a dependency order, not an alphabetical one:
#
#   transition_tables                   reads the automata source
#   machine_typology, SVGs, compendium  read the transition tables in sequence
#   action_grammar                      reads the tables and vocabulary map
#   corpus_window                       reads the tables, grammar, and vocabulary
#   capability_registry                 reads the module headers
#   the remaining builders              read whatever is above them
#
# Run this after any change to an automaton, to the vocabulary map, or to a
# dispatch spec. Then run scripts/checks/run_all.sh.
#
# This script does not decide whether a diff is correct. Read the diff.

set -u
cd "$(dirname "$0")/.." || exit 2

# The automata lane, in verified dependency order. An automaton change makes
# every one of these stale, and each has its own gate.
#
# The curriculum lane is NOT here. It has its own order, recorded in the
# 2026-07-31 handoff: compile, then the lesson evidence ledger, then the
# census, then the triage check. Running it out of order understated the
# census by 17 rows once already. Do not fold it in until that order is
# verified against a live run.
BUILDERS=(
    # source-derived: read the automata and the module headers
    "scripts/research/build_transition_tables.py"
    "scripts/research/build_machine_typology.py"
    "scripts/research/render_automaton_svg.py"
    "scripts/research/build_automata_compendium.py"
    "scripts/extract_capability_registry.py"
    "scripts/extract_machine_block_decomposition.py"
    # grammar and index: read the tables and the vocabulary map
    "scripts/research/build_action_grammar.py"
    "scripts/research/build_corpus_window.py"
    # single-source registries
    "scripts/extract_a_fortiori_context_closure.py"
    "scripts/extract_coverage_absence_registry.py"
    "scripts/extract_error_rule_incompatibility.py"
    "scripts/extract_im_lesson_identity.py"
    "scripts/extract_incompatibility_entailment_order.py"
    "scripts/extract_research_corpus_misconceptions.py"
    "scripts/extract_task_span_absence_registry.py"
    "scripts/extract_vision_lesson_digest_audit.py"
    # last: these read whatever is above them
    "scripts/research/build_attested_phrases.py"
    "scripts/research/build_recognition_benchmark.py"
    "scripts/research/build_relevance_negation.py"
    "scripts/research/build_self_description_census.py"
    # after the census, which rewrites the self-description document that this
    # registry cites. Running it earlier leaves it citing the previous counts.
    "scripts/extract_research_measurement_registry.py"
    # the one curriculum builder an automata change makes stale: it records
    # which automata exercise the registry, so a new action lands here.
    # Verified in this position on 2026-08-01. The rest of the curriculum lane
    # is still out; see the note above.
    "scripts/curriculum/build_im_action_seam_recut.py"
    # dead last: it hashes every derived data artifact above, so any builder
    # that rewrites a file makes this manifest stale. Verified 2026-08-01.
    "scripts/extract_data_consumption_manifest.py"
)

failed=()
skipped=()

for builder in "${BUILDERS[@]}"; do
    if [[ ! -f "$builder" ]]; then
        skipped+=("$builder")
        printf '  SKIP  %s (absent)\n' "$builder"
        continue
    fi
    printf '  RUN   %s ... ' "$builder"
    if out=$(python3 "$builder" 2>&1); then
        printf 'ok\n'
    else
        printf 'FAILED\n'
        printf '%s\n' "$out" | tail -20 | sed 's/^/          /'
        failed+=("$builder")
    fi
done

echo
if [[ ${#skipped[@]} -gt 0 ]]; then
    printf 'skipped %d builder(s): %s\n' "${#skipped[@]}" "${skipped[*]}"
fi
if [[ ${#failed[@]} -gt 0 ]]; then
    printf 'REGEN FAILED for %d builder(s): %s\n' "${#failed[@]}" "${failed[*]}"
    exit 1
fi

echo "regen complete. Changed files:"
git status --porcelain -- . ':!.superpowers' | sed 's/^/  /'
echo
echo "Read the diff before you stage it."
