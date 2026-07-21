#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$repo_root"

scratch_dir=$(mktemp -d)
trap 'status=$?; rm -rf "$scratch_dir"; if (( status != 0 )); then echo "FAIL geometry loader checks" >&2; fi' EXIT

generated_manifest="$scratch_dir/generated-manifest.txt"
checked_manifest="$scratch_dir/checked-manifest.txt"

emit_geometry_files() {
    local directory=$1
    while IFS= read -r file; do
        printf ":- ensure_loaded('%s').\n" "${file#knowledge/geometry/}"
    done < <(find "$directory" -maxdepth 1 -type f -name '*.pl' | LC_ALL=C sort)
}

emit_repository_files() {
    local directory=$1
    while IFS= read -r file; do
        printf ":- ensure_loaded('../%s').\n" "${file#knowledge/}"
    done < <(find "$directory" -maxdepth 1 -type f -name '*.pl' | LC_ALL=C sort)
}

{
    emit_geometry_files knowledge/geometry/concepts
    emit_geometry_files knowledge/geometry/metaphors
    emit_geometry_files knowledge/geometry/van_hiele
    emit_geometry_files knowledge/geometry/bootstrap
    emit_repository_files knowledge/standards/ccss
    printf ":- ensure_loaded('../standards/indiana/geometry.pl').\n"
    emit_repository_files knowledge/standards/im
    emit_geometry_files knowledge/geometry/pck
    printf ":- ensure_loaded('query.pl').\n"
} >"$generated_manifest"

awk '
    /BEGIN CANONICAL GEOMETRY LOAD MANIFEST/ { inside = 1; next }
    /END CANONICAL GEOMETRY LOAD MANIFEST/ { inside = 0 }
    inside && /^:- ensure_loaded/ { print }
' knowledge/geometry/schema.pl >"$checked_manifest"

if ! diff -u "$generated_manifest" "$checked_manifest"; then
    echo "FAIL canonical geometry manifest differs from the ordered directory inventory" >&2
    exit 1
fi
echo "PASS canonical geometry manifest matches the ordered directory inventory"

source_goal="findall(F,(source_file(F),\\+sub_atom(F,_,_,_,'/knowledge/geometry/geometry_bridge.pl'),(sub_atom(F,_,_,_,'/knowledge/geometry/');sub_atom(F,_,_,_,'/knowledge/standards/ccss/');sub_atom(F,_,_,_,'/knowledge/standards/im/');sub_atom(F,_,_,_,'/knowledge/standards/indiana/geometry.pl'))),Fs),sort(Fs,Sorted),forall(member(File,Sorted),writeln(File))"

swipl --on-error=status --on-warning=status -q -l hermes_worker.pl \
    -g "working_directory(Root,Root),load_geometry_runtime(Root),$source_goal,halt." \
    | sed "s|$repo_root/||" >"$scratch_dir/worker-sources.txt"
swipl --on-error=status --on-warning=status -q -l paths.pl \
    -l knowledge/geometry/geometry_bridge.pl -g "$source_goal,halt." \
    | sed "s|$repo_root/||" >"$scratch_dir/bridge-sources.txt"

if ! diff -u "$scratch_dir/worker-sources.txt" "$scratch_dir/bridge-sources.txt"; then
    echo "FAIL worker and bridge geometry load closures differ" >&2
    exit 1
fi
echo "PASS worker and bridge geometry load closures are equivalent"

count_goal="aggregate_all(count,geom_concept(_,_,_,_),A),aggregate_all(count,geom_misconception(_,_,_,_,_,_),B),aggregate_all(count,standard_anchor(_,_,_,_),C),aggregate_all(count,pck_synthesis(_,_,_,_,_),D),aggregate_all(count,developmental_marker(_,_,_,_),E),format('~w ~w ~w ~w ~w~n',[A,B,C,D,E])"
swipl --on-error=status --on-warning=status -q -l hermes_worker.pl \
    -g "working_directory(Root,Root),load_geometry_runtime(Root),$count_goal,halt." \
    >"$scratch_dir/worker-counts.txt"
swipl --on-error=status --on-warning=status -q -l paths.pl \
    -l knowledge/geometry/geometry_bridge.pl -g "$count_goal,halt." \
    >"$scratch_dir/bridge-counts.txt"

if ! diff -u "$scratch_dir/worker-counts.txt" "$scratch_dir/bridge-counts.txt"; then
    echo "FAIL worker and bridge geometry predicate counts differ" >&2
    exit 1
fi
echo "PASS worker and bridge geometry predicate counts are equivalent ($(tr '\n' ' ' <"$scratch_dir/worker-counts.txt"))"

swipl --on-error=status --on-warning=status -q -l paths.pl -g "
    consult('knowledge/geometry/schema.pl'),
    forall(
        ( source_file(File),
          ( sub_atom(File,_,_,_,'/knowledge/geometry/')
          ; sub_atom(File,_,_,_,'/knowledge/standards/ccss/')
          ; sub_atom(File,_,_,_,'/knowledge/standards/im/')
          ; sub_atom(File,_,_,_,'/knowledge/standards/indiana/geometry.pl')
          )
        ),
        source_file_property(File,load_count(1))
    ),
    halt."
echo "PASS every geometry-chain source is consulted once"

swipl --on-error=status --on-warning=status -q -l paths.pl -g "
    consult('knowledge/geometry/schema.pl'),
    ccss_geometry_standard_witness(shape_recognition_2d_3d,\"K.G.A.1\",_),
    indiana_geometry_standard_witness(triangles_circles_radius_diameter,\"5.G.1\",_),
    im_grade5_standard_anchor_witness(im_grade5_u1_l1,ccss,\"5.MD.C.3\",_),
    im_grade6_lesson_standard_witness(area_compose_decompose_polygons,\"IM-G6-U1-L1\",_),
    im_grade7_lesson_standard_witness(scale_drawings,\"IM-G7-U1-L1\",_),
    im_grade8_lesson_standard_witness(rigid_motion_properties,\"IM-G8-U1-L1\",_),
    halt."
echo "PASS CCSS, Indiana, and IM grade 5-8 witness probes"
