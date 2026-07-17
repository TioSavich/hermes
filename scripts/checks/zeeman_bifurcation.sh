#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
python_bin="${PYTHON:-python3}"
runner=("$python_bin")

if ! "$python_bin" -c 'import numpy' >/dev/null 2>&1; then
    if [ "$(uname -s)" = Darwin ] && arch -arm64 "$python_bin" -c 'import numpy' >/dev/null 2>&1; then
        runner=(arch -arm64 "$python_bin")
    else
        echo "NumPy is required for the Zeeman bifurcation comparison" >&2
        exit 1
    fi
fi

"${runner[@]}" "$repo/more-zeeman/bifurcation_verify.py" --cross-check --repo "$repo"
