#!/usr/bin/env bash
# Run only full-chain checks whose classified inputs intersect the current diff.
set -uo pipefail

checks_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$checks_dir/../.." && pwd)
map_file="$checks_dir/run_fast.map.tsv"

usage() {
    cat <<'EOF'
usage: bash scripts/checks/run_fast.sh [--paths PATH ...]

Without --paths, paths come from the working-tree, index, and untracked files.
--paths supplies a simulated repository-relative change set for selection tests.
EOF
}

if [[ ! -r "$map_file" ]]; then
    echo "fast-lane selection map is missing: $map_file" >&2
    exit 2
fi

explicit_paths=0
case ${1-} in
    --paths)
        explicit_paths=1
        shift
        ;;
    -h|--help)
        usage
        exit 0
        ;;
    '')
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac

if (( explicit_paths )) && (( $# == 0 )); then
    echo "--paths requires at least one repository-relative path" >&2
    exit 2
fi

scratch_dir=$(mktemp -d "${TMPDIR:-/tmp}/hermes-fast.XXXXXX")
trap 'rm -rf "$scratch_dir"' EXIT
paths_file="$scratch_dir/paths"
selected_file="$scratch_dir/selected"
skipped_file="$scratch_dir/skipped"
unknown_file="$scratch_dir/unknown"
control_file="$scratch_dir/control"
: >"$paths_file"
: >"$selected_file"
: >"$skipped_file"
: >"$unknown_file"
: >"$control_file"

normalize_path() {
    local path=$1
    while [[ $path == ./* ]]; do
        path=${path#./}
    done
    printf '%s\n' "$path"
}

if (( explicit_paths )); then
    for supplied in "$@"; do
        normalize_path "$supplied" >>"$paths_file"
    done
else
    cd "$repo_root"
    {
        git diff --name-only --diff-filter=ACMR HEAD
        git diff --cached --name-only --diff-filter=ACMR
        git ls-files --others --exclude-standard
    } | while IFS= read -r changed; do
        [[ -n $changed ]] && normalize_path "$changed"
    done >>"$paths_file"
fi
LC_ALL=C sort -u "$paths_file" -o "$paths_file"

while IFS= read -r changed; do
    case $changed in
        ''|/*|../*|*/../*)
            echo "invalid path: $changed" >>"$unknown_file"
            ;;
        scripts/checks/run_fast.sh|scripts/checks/run_fast.map.tsv)
            echo "$changed" >>"$control_file"
            ;;
    esac
done <"$paths_file"

matches_globs() {
    local path=$1
    local globs=$2
    local pattern
    [[ $globs != - ]] || return 1
    while IFS= read -r pattern; do
        [[ -n $pattern ]] || continue
        if [[ $path == $pattern ]]; then
            return 0
        fi
    done < <(printf '%s\n' "$globs" | tr ';' '\n')
    return 1
}

path_matches_row() {
    local path=$1
    local tracked=$2
    local generated=$3
    local runtime=$4
    local fixtures=$5
    matches_globs "$path" "$tracked" ||
        matches_globs "$path" "$generated" ||
        matches_globs "$path" "$runtime" ||
        matches_globs "$path" "$fixtures"
}

while IFS=$'\t' read -r name always command tracked generated runtime fixtures; do
    [[ -n $name && ${name:0:1} != '#' ]] || continue
    matched_paths=""
    while IFS= read -r changed; do
        [[ -n $changed ]] || continue
        case $changed in
            scripts/checks/run_fast.sh|scripts/checks/run_fast.map.tsv) continue ;;
        esac
        if path_matches_row "$changed" "$tracked" "$generated" "$runtime" "$fixtures"; then
            if [[ -n $matched_paths ]]; then
                matched_paths="$matched_paths, $changed"
            else
                matched_paths=$changed
            fi
        fi
    done <"$paths_file"
    if [[ $always == yes ]]; then
        printf '%s\t%s\t%s\n' "$name" "$command" "always-run global input inventory" >>"$selected_file"
    elif [[ -n $matched_paths ]]; then
        printf '%s\t%s\tmatched: %s\n' "$name" "$command" "$matched_paths" >>"$selected_file"
    else
        printf '%s\tno changed path matched its classified inputs\n' "$name" >>"$skipped_file"
    fi
done <"$map_file"

while IFS= read -r changed; do
    [[ -n $changed ]] || continue
    case $changed in
        scripts/checks/run_fast.sh|scripts/checks/run_fast.map.tsv) continue ;;
    esac
    known=0
    while IFS=$'\t' read -r name always command tracked generated runtime fixtures; do
        [[ -n $name && ${name:0:1} != '#' ]] || continue
        if path_matches_row "$changed" "$tracked" "$generated" "$runtime" "$fixtures"; then
            known=1
            break
        fi
    done <"$map_file"
    if (( ! known )); then
        echo "$changed" >>"$unknown_file"
    fi
done <"$paths_file"

if [[ -s $unknown_file ]]; then
    echo "FAST LANE REFUSED: changed paths outside the classification:" >&2
    while IFS= read -r changed; do
        printf '  %s\n' "$changed" >&2
    done <"$unknown_file"
    echo "Run the full chain; no checks were run." >&2
    exit 2
fi

echo "CHANGED PATHS"
if [[ -s $paths_file ]]; then
    while IFS= read -r changed; do
        printf '  %s\n' "$changed"
    done <"$paths_file"
else
    echo "  (none)"
fi
if [[ -s $control_file ]]; then
    echo "CONTROL PATHS"
    while IFS= read -r changed; do
        printf '  %s — fast-lane metadata; no full-chain check consumes it\n' "$changed"
    done <"$control_file"
fi

echo "SELECTED"
while IFS=$'\t' read -r name command reason; do
    printf '  %s — %s\n' "$name" "$reason"
done <"$selected_file"

echo "SKIPPED"
while IFS=$'\t' read -r name reason; do
    printf '  %s — %s\n' "$name" "$reason"
done <"$skipped_file"

cd "$repo_root"
run_count=0
failure=0
while IFS=$'\t' read -r name command reason; do
    echo "== $name"
    if bash -c "$command"; then
        run_count=$((run_count + 1))
    else
        status=$?
        echo "FAST LANE FAILED: $name exited $status" >&2
        failure=$status
        break
    fi
done <"$selected_file"

skip_count=$(wc -l <"$skipped_file" | tr -d ' ')
if (( failure != 0 )); then
    exit "$failure"
fi
echo "FAST LANE: $run_count run, $skip_count skipped — full chain remains the commit gate."
