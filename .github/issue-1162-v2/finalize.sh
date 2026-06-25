#!/usr/bin/env bash
set -euo pipefail

exec > >(tee /tmp/issue-1162-finalize.log) 2>&1

python .github/issue-1162-v2/reconstruct.py
cp .github/issue-1162-v2/fix_boundary.py /tmp/issue-1162-fix-boundary.py

git fetch origin main
git reset --hard origin/main
git clean -fdx

EXPECTED_FILES=(
  .github/workflows/renderer-component-gate.yml
  docs/ARCHITECTURE.md
  docs/room_visual_renderer_component_map.md
  scripts/field/room_visual_renderer.gd
  tools/check_cable_canvas_renderer_boundary.py
  tools/check_iso_asset_alignment_policy_boundary.py
  tools/check_room_visual_renderer_component_boundary.py
  tools/check_visual_asset_resource_runtime_boundary.py
  tools/ci/check_room_visual_renderer_smoke_contract.gd
)

for path in "${EXPECTED_FILES[@]}"; do
  test -f "/tmp/issue-1162-extracted/$path"
  mkdir -p "$(dirname "$path")"
  cp "/tmp/issue-1162-extracted/$path" "$path"
done

python /tmp/issue-1162-fix-boundary.py

python tools/check_room_visual_renderer_component_boundary.py
python tools/check_cable_canvas_renderer_boundary.py
python tools/check_iso_asset_alignment_policy_boundary.py
python tools/check_visual_asset_resource_runtime_boundary.py
python tools/check_gdscript_safety_patterns.py

godot --headless --path . --import
godot --headless --path . --script res://tools/ci/parse_all_gd.gd
godot --headless --path . --script res://tools/ci/check_room_visual_renderer_smoke_contract.gd
godot --headless --path . --script res://tools/ci/check_renderer_projection_contract.gd
godot --headless --path . --script res://tools/ci/check_iso_asset_alignment_policy_contract.gd
godot --headless --path . --script res://tools/ci/check_visual_asset_resource_runtime_contract.gd
godot --headless --path . --script res://tools/ci/check_floor_renderer_contract.gd
godot --headless --path . --script res://tools/ci/check_wall_renderer_contract.gd
godot --headless --path . --script res://tools/ci/check_object_renderer_contract.gd
godot --headless --path . --script res://tools/ci/check_object_primitive_renderer_contract.gd
godot --headless --path . --script res://tools/ci/check_object_texture_dispatch_policy_contract.gd
godot --headless --path . --script res://tools/ci/check_door_canvas_renderer_contract.gd
godot --headless --path . --script res://tools/ci/check_route_renderer_contract.gd
godot --headless --path . --script res://tools/ci/check_cable_canvas_renderer_contract.gd
godot --headless --path . --script res://tools/ci/check_overlay_renderer_contract.gd
godot --headless --path . --script res://tools/ci/check_map_constructor_overlay_renderer_contract.gd
godot --headless --path . --script res://tools/ci/check_fog_renderer_contract.gd

git diff --check
test "$(wc -l < scripts/field/room_visual_renderer.gd)" -eq 4288

sha256sum "${EXPECTED_FILES[@]}" > /tmp/issue-1162-final-files.sha256
tar -czf /tmp/issue-1162-final-files.tar.gz "${EXPECTED_FILES[@]}"
sha256sum /tmp/issue-1162-final-files.tar.gz

echo "Issue #1162 final files validated and packaged."
