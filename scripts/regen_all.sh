#!/usr/bin/env bash
# Regenerate derived artifacts in dependency order. Every lane ends with the
# shared single-source registries and the four-layer self-description tail.
# This script keeps going after failures so one run reports the whole cascade.

set -uo pipefail
cd "$(dirname "$0")/.." || exit 2

usage() {
    cat <<'EOF'
usage: scripts/regen_all.sh [--lane automata|curriculum|loops|all] [--dry-run]

The default lane is all. Every lane also runs the shared registries and the
four-layer tail in dependency order.
EOF
}

lane=all
dry_run=0
while (( $# )); do
    case $1 in
        --lane)
            if (( $# < 2 )); then
                echo "--lane requires automata, curriculum, loops, or all" >&2
                exit 2
            fi
            lane=$2
            shift 2
            ;;
        --dry-run)
            dry_run=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage >&2
            exit 2
            ;;
    esac
done

case $lane in
    automata|curriculum|loops|all) ;;
    *)
        echo "unknown lane: $lane" >&2
        usage >&2
        exit 2
        ;;
esac

labels=()
commands=()

add_python() {
    labels+=("$1")
    commands+=("python3 $1")
}

add_enactment_driver() {
    labels+=("scripts/curriculum/run_lesson_enactments.pl")
    commands+=("env HERMES_ENACTMENT_STAMP=2026-08-01 swipl -q -l paths.pl -s scripts/curriculum/run_lesson_enactments.pl -g \"main('data/learningcommons/derived/lesson_enactments')\" -t halt")
}

add_automata_lane() {
    add_python scripts/research/build_transition_tables.py
    add_python scripts/research/build_machine_typology.py
    add_python scripts/research/render_automaton_svg.py
    add_python scripts/research/render_automaton_context_svg.py
    add_python scripts/research/build_automata_compendium.py
    add_python scripts/research/build_full_graph_json.py
    add_python scripts/research/build_graph_quotients.py
    add_python scripts/extract_machine_block_decomposition.py
    add_python scripts/research/build_action_grammar.py
    add_python scripts/research/build_corpus_window.py
}

add_curriculum_lane() {
    add_python scripts/curriculum/compile_action_mappings.py
    add_python scripts/curriculum/build_im_defragged_task_instances.py
    add_python scripts/curriculum/build_lesson_evidence.py
    add_python scripts/curriculum/pusu_pass.py
    add_python scripts/curriculum/build_sidecar_equation_census.py
    add_python scripts/curriculum/build_equation_verifications.py
    add_python scripts/curriculum/compile_receipt_routes.py
    add_python scripts/curriculum/build_standards_progression_overlay.py
    add_python scripts/curriculum/build_im_lesson_capability_census.py
    add_python scripts/curriculum/build_im_zero_candidate_triage.py
    add_python scripts/curriculum/build_im_action_seam_recut.py
    # The row-to-machine maps read the defragged pool built above. The pool map
    # comes first: the grade 8 map joins its rows to the pilot receipts.
    add_python scripts/sidekick/build_wave5_row_map.py
    add_python scripts/curriculum/build_g8_row_machine_map.py
    add_enactment_driver
    add_python scripts/curriculum/build_im_lesson_enactment_census.py
    add_python scripts/curriculum/build_counting_place_value_diagnosis.py
}

add_loops_lane() {
    add_python scripts/bigred/loops/build_admitted_edges.py
    add_python scripts/bigred/loops/build_kernel_dependency_overlay.py
    add_python scripts/bigred/loops/recompute_r2_kernel_lens.py
    add_python scripts/bigred/loops/elaboration_queries.py
}

add_registry_lane() {
    add_python scripts/extract_a_fortiori_context_closure.py
    add_python scripts/extract_coverage_absence_registry.py
    add_python scripts/extract_error_rule_incompatibility.py
    add_python scripts/extract_im_lesson_identity.py
    add_python scripts/extract_incompatibility_entailment_order.py
    add_python scripts/extract_research_corpus_misconceptions.py
    add_python scripts/extract_task_span_absence_registry.py
    add_python scripts/extract_vision_lesson_digest_audit.py
    add_python scripts/research/build_attested_phrases.py
    add_python scripts/research/build_recognition_benchmark.py
    add_python scripts/research/build_relevance_negation.py
}

add_tail() {
    add_python scripts/extract_capability_registry.py
    add_python scripts/research/build_self_description_census.py
    add_python scripts/extract_research_measurement_registry.py
    add_python scripts/extract_data_consumption_manifest.py
}

case $lane in
    automata)
        add_automata_lane
        ;;
    curriculum)
        add_curriculum_lane
        ;;
    loops)
        add_loops_lane
        ;;
    all)
        add_automata_lane
        add_curriculum_lane
        add_loops_lane
        ;;
esac

add_registry_lane

# The seam re-cut reads both curriculum triage and the automata registry. A
# curriculum run already regenerated it; an automata-only run must do so here.
if [[ $lane == automata ]]; then
    add_python scripts/curriculum/build_im_action_seam_recut.py
fi

add_tail

if (( dry_run )); then
    printf '%s\n' "${commands[@]}"
    exit 0
fi

failed=()
for index in "${!commands[@]}"; do
    label=${labels[$index]}
    command=${commands[$index]}
    printf '  RUN   %s ... ' "$label"
    if output=$(bash -c "$command" 2>&1); then
        printf 'ok\n'
    else
        status=$?
        printf 'FAILED\n'
        printf '%s\n' "$output" | tail -20 | sed 's/^/          /'
        failed+=("$label (exit $status)")
    fi
done

echo
if (( ${#failed[@]} )); then
    printf 'REGEN FAILED for %d builder(s):\n' "${#failed[@]}"
    for index in "${!failed[@]}"; do
        printf '  %d. %s\n' "$((index + 1))" "${failed[$index]}"
    done
    exit 1
fi

echo "regen complete."
echo "Read the diff before you stage it."
