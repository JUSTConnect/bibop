#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
COORDINATOR = ROOT / "scripts/field/room_visual_renderer.gd"
OBJECT = ROOT / "scripts/visual/renderer/object_renderer.gd"
BOUNDARY = ROOT / "tools/check_room_visual_renderer_component_boundary.py"
WORKFLOW = ROOT / ".github/workflows/renderer-component-gate.yml"
DOC = ROOT / "docs/room_visual_renderer_component_map.md"


def function_pattern(name: str) -> re.Pattern[str]:
    return re.compile(rf"(?ms)^func {re.escape(name)}\s*\(.*?(?=^func |\Z)")


def extract_function(source: str, name: str) -> str:
    match = function_pattern(name).search(source)
    if match is None:
        raise RuntimeError(f"missing function {name}")
    return match.group(0).rstrip()


def replace_function(source: str, name: str, replacement: str) -> str:
    result, count = function_pattern(name).subn(replacement.rstrip() + "\n\n", source, count=1)
    if count != 1:
        raise RuntimeError(f"failed to replace {name}")
    return result


coordinator = COORDINATOR.read_text(encoding="utf-8")
object_source = OBJECT.read_text(encoding="utf-8")

resolver = extract_function(coordinator, "get_iso_object_asset_key_for_object_data")
resolver = resolver.replace("func get_iso_object_asset_key_for_object_data", "static func get_asset_key_for_object_data", 1)
resolver = resolver.replace("get_iso_object_asset_key_for_profile", "get_asset_key_for_profile")
resolver = resolver.replace("_get_object_mount_mode", "get_mount_mode")
resolver = resolver.replace("_is_object_state_on", "is_state_on")
resolver = resolver.replace("_is_fuse_present", "is_fuse_present")
resolver = resolver.replace("VisualAssetCatalogScript", "VisualAssetCatalogRef")
if "static func get_asset_key_for_object_data" not in object_source:
    object_source = object_source.rstrip() + "\n\n" + resolver + "\n"
OBJECT.write_text(object_source, encoding="utf-8")

preload_line = 'const ObjectRendererRef = preload("res://scripts/visual/renderer/object_renderer.gd")'
wall_preload = 'const WallRendererRef = preload("res://scripts/visual/renderer/wall_renderer.gd")'
if preload_line not in coordinator:
    coordinator = coordinator.replace(wall_preload, wall_preload + "\n" + preload_line, 1)

delegates = {
    "get_iso_object_asset_key_for_profile": '''func get_iso_object_asset_key_for_profile(profile_key: String) -> String:
\treturn ObjectRendererRef.get_asset_key_for_profile(profile_key)''',
    "get_iso_object_profile_key_for_object_data": '''func get_iso_object_profile_key_for_object_data(object_data: Dictionary, fallback_profile_key: String = "generic_object") -> String:
\treturn ObjectRendererRef.get_profile_key_for_object_data(object_data, fallback_profile_key)''',
    "is_wall_mounted_runtime_object": '''func is_wall_mounted_runtime_object(object_data: Dictionary) -> bool:
\treturn ObjectRendererRef.is_wall_mounted_runtime_object(object_data)''',
    "get_wall_mounted_cardinal_side": '''func get_wall_mounted_cardinal_side(object_data: Dictionary) -> String:
\treturn ObjectRendererRef.get_wall_mounted_cardinal_side(object_data)''',
    "_get_object_mount_mode": '''func _get_object_mount_mode(object_data: Dictionary) -> String:
\treturn ObjectRendererRef.get_mount_mode(object_data)''',
    "_is_object_state_on": '''func _is_object_state_on(object_data: Dictionary) -> bool:
\treturn ObjectRendererRef.is_state_on(object_data)''',
    "_is_fuse_present": '''func _is_fuse_present(object_data: Dictionary) -> bool:
\treturn ObjectRendererRef.is_fuse_present(object_data)''',
    "get_iso_object_asset_key_for_object_data": '''func get_iso_object_asset_key_for_object_data(object_data: Dictionary, fallback_profile_key: String) -> String:
\treturn ObjectRendererRef.get_asset_key_for_object_data(object_data, fallback_profile_key)''',
}
for name, body in delegates.items():
    coordinator = replace_function(coordinator, name, body)
COORDINATOR.write_text(coordinator, encoding="utf-8")

boundary = BOUNDARY.read_text(encoding="utf-8")
if 'OBJECT = ROOT / "scripts/visual/renderer/object_renderer.gd"' not in boundary:
    boundary = boundary.replace('WALL = ROOT / "scripts/visual/renderer/wall_renderer.gd"', 'WALL = ROOT / "scripts/visual/renderer/wall_renderer.gd"\nOBJECT = ROOT / "scripts/visual/renderer/object_renderer.gd"')
    boundary = boundary.replace('wall = read(WALL)', 'wall = read(WALL)\nobject_renderer = read(OBJECT)')
    boundary = boundary.replace('if renderer_lines > 6850:', 'if renderer_lines > 6650:')
    boundary = boundary.replace('6850")', '6650")')
    boundary = boundary.replace('preload("res://scripts/visual/renderer/wall_renderer.gd")\',', 'preload("res://scripts/visual/renderer/wall_renderer.gd")\',\n    \'preload("res://scripts/visual/renderer/object_renderer.gd")\',')
    insertion = '''\nobject_delegates = {
    "get_iso_object_asset_key_for_profile": "ObjectRendererRef.get_asset_key_for_profile",
    "get_iso_object_profile_key_for_object_data": "ObjectRendererRef.get_profile_key_for_object_data",
    "is_wall_mounted_runtime_object": "ObjectRendererRef.is_wall_mounted_runtime_object",
    "get_wall_mounted_cardinal_side": "ObjectRendererRef.get_wall_mounted_cardinal_side",
    "_get_object_mount_mode": "ObjectRendererRef.get_mount_mode",
    "_is_object_state_on": "ObjectRendererRef.is_state_on",
    "_is_fuse_present": "ObjectRendererRef.is_fuse_present",
    "get_iso_object_asset_key_for_object_data": "ObjectRendererRef.get_asset_key_for_object_data",
}
for name, delegate in object_delegates.items():
    if delegate not in function_body(renderer, name):
        errors.append(f"RoomVisualRenderer {name} must delegate to ObjectRenderer")
'''
    boundary = boundary.replace('if "IsoDrawEntryContractRef.less" not in function_body(renderer, "sort_iso_draw_entries"):', insertion + '\nif "IsoDrawEntryContractRef.less" not in function_body(renderer, "sort_iso_draw_entries"):')
    boundary = boundary.replace('for component_name, component_source in (("FloorRenderer", floor), ("WallRenderer", wall)):', 'for component_name, component_source in (("FloorRenderer", floor), ("WallRenderer", wall), ("ObjectRenderer", object_renderer)):')
    contract_anchor = 'if "func draw_iso_floor_cell" not in renderer or "func draw_iso_wall_block" not in renderer:'
    object_contract = '''for token in (
    "class_name ObjectRenderer",
    "static func get_asset_key_for_profile",
    "static func get_profile_key_for_object_data",
    "static func get_asset_key_for_object_data",
):
    if token not in object_renderer:
        errors.append(f"ObjectRenderer missing contract: {token}")

'''
    boundary = boundary.replace(contract_anchor, object_contract + contract_anchor)
BOUNDARY.write_text(boundary, encoding="utf-8")

workflow = WORKFLOW.read_text(encoding="utf-8")
object_step = '      - name: Check ObjectRenderer policy contract\n        run: godot --headless --path . --script res://tools/ci/check_object_renderer_contract.gd\n'
if object_step not in workflow:
    workflow = workflow.rstrip() + "\n" + object_step
WORKFLOW.write_text(workflow, encoding="utf-8")

doc = DOC.read_text(encoding="utf-8")
if "### `ObjectRenderer`" not in doc:
    section = '''### `ObjectRenderer`

Owns pure object classification and asset-selection policy:

- metadata-to-profile classification;
- profile-to-asset resolution;
- wall/floor mount classification;
- switch state and fuse presence normalization;
- object-data-to-asset selection, including visual-state assets.

`ObjectRenderer` has no CanvasItem, ResourceLoader, scene-tree or runtime lookup dependency. Texture loading, descriptors, grounding, draw entries and Canvas drawing remain in `RoomVisualRenderer` for later controlled slices.

'''
    doc = doc.replace("## Remaining extraction clusters", section + "## Remaining extraction clusters")
    doc = doc.replace("| Object renderer | object descriptors, asset resolution, grounding, object markers and entries |", "| Object descriptor/entry renderer | texture resolution, descriptors, grounding, object markers and entries |")
DOC.write_text(doc, encoding="utf-8")

print("ObjectRenderer policy extraction applied")
