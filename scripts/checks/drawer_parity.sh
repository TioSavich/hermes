#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
node_bin=$(command -v node || true)
if [ -z "$node_bin" ]; then
  echo "Node.js is required to regenerate tracked render galleries" >&2
  exit 1
fi

python3 - "$repo" "$node_bin" <<'PY'
import json
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

repo = Path(sys.argv[1])
node = sys.argv[2]
adapter = repo / "more-zeeman" / "render" / "node-adapter.js"

def invoke(payload):
    proc = subprocess.run(
        [node, str(adapter)], input=json.dumps(payload), cwd=repo,
        text=True, capture_output=True, check=True,
    )
    return proc.stdout

formats = json.loads(invoke({"mode": "dispatch-formats", "repoRoot": str(repo)}))

goal = """
use_module(render(fraction_bars_scene)),use_module(render(number_line_scene)),
use_module(render(area_model_scene)),use_module(render(base_ten_scene)),
use_module(render(place_value_chart_scene)),use_module(render(set_grouping_scene)),
use_module(render(balance_scale_scene)),use_module(render(hybridization_scene)),
use_module(render(notation_scene)),use_module(render(coordinate_plane_scene)),
use_module(render(rigid_motion_scene)),use_module(render(polyform_tiling_scene)),
use_module(render(angle_circular_scene)),use_module(render(data_display_scene)),
use_module(render(solid_net_scene)),use_module(render(geoboard_scene)),
fraction_bars_scene:fraction_render_json(unit_fraction_iteration,1,4,D1),
number_line_scene:number_line_render_json(fraction_iteration(1,4),D2),
area_model_scene:area_render_json(array_multiplication(3,4),D3),
base_ten_scene:base_ten_render_json(add_with_carry(27,15,10),D4),
place_value_chart_scene:place_value_chart_render_json(add_with_carry(28,34,10),D5),
set_grouping_scene:set_grouping_render_json(make_ten(8,5),D6),
balance_scale_scene:balance_render_json(solve_linear(2,3,11),D7),
hybridization_scene:hybridization_render_json(circle_partition_on_rectangle,D8),
notation_scene:notation_render_json(write_equation(2,'+',3,5),D9),
coordinate_plane_scene:coordinate_plane_render_json(plot_points([1-2]),D10),
rigid_motion_scene:rigid_motion_render_json(translate([0-0,2-0,1-1],1,2),D11),
polyform_tiling_scene:polyform_tiling_render_json(tile_area(cols(2),rows(2)),D12),
angle_circular_scene:angle_circular_render_json(angle(60),D13),
data_display_scene:data_display_render_json(bar_chart([a-2,b-3]),D14),
solid_net_scene:solid_net_render_json(net_of(cube),D15),
geoboard_scene:geoboard_render_json(stretch_polygon([0-0,2-0,2-2,0-2]),D16),
use_module(library(http/json)),
json_write_dict(user_output,_{docs:[D1,D2,D3,D4,D5,D6,D7,D8,D9,D10,D11,D12,D13,D14,D15,D16]},[width(0)]),halt.
""".replace("\n", "")
worker = subprocess.run(
    ["swipl", "-q", "-l", "paths.pl", "-g", goal], cwd=repo,
    text=True, capture_output=True, check=True,
)
worker_docs = json.loads(worker.stdout)["docs"]
fixtures = {doc["frames"][0]["scene"]["format"]: doc for doc in worker_docs}
if set(fixtures) != set(formats):
    raise SystemExit(
        "worker parity fixtures do not cover drawer dispatch: "
        f"missing={sorted(set(formats)-set(fixtures))} extra={sorted(set(fixtures)-set(formats))}"
    )

def normalize(svg):
    root = ET.fromstring(svg)
    def visit(element):
        element.attrib = dict(sorted(element.attrib.items()))
        for child in element:
            visit(child)
    visit(root)
    return ET.tostring(root, encoding="unicode")

for scene_format in formats:
    document = fixtures[scene_format]
    base = {"repoRoot": str(repo), "document": document, "options": {"ariaLabel": scene_format}}
    node_svg = invoke({**base, "mode": "frame"})
    browser_svg = invoke({**base, "mode": "browser-frame"})
    if normalize(node_svg) != normalize(browser_svg):
        raise SystemExit(f"parity mismatch: {scene_format}")
    print(f"parity ok: {scene_format}")
print(f"test_drawer_browser_node_parity: {len(formats)} formats")
PY
