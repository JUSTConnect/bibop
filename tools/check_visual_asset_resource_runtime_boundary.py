#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUNTIME = ROOT / "scripts/visual/renderer/visual_asset_resource_runtime.gd"
RENDERER = ROOT / "scripts/field/room_visual_renderer.gd"
CONTRACT = ROOT / "tools/ci/check_visual_asset_resource_runtime_contract.gd"
WORKFLOW = ROOT / ".github/workflows/renderer-component-gate.yml"
errors: list[str] = []


def read(path: Path) -> str:
    if not path.exists():
        errors.append(f"missing required file: {path.relative_to(ROOT)}")
        return ""
    return path.read_text(encoding="utf-8")


def function_body(source: str, name: str) -> str:
    match = re.search(rf"(?ms)^func {re.escape(name)}\s*\(.*?(?=^func |\Z)", source)
    return match.group(0) if match else ""


runtime = read(RUNTIME)
renderer = read(RENDERER)
contract = read(CONTRACT)
workflow = read(WORKFLOW)

for token in (
    "extends RefCounted",
    "class_name VisualAssetResourceRuntime",
    'preload("res://scripts/visual/visual_asset_catalog.gd")',
    "func resolve_object_png_path",
    "func resolve_placeholder_path",
    "func get_floor_texture",
    "func get_ground_texture",
    "func resolve_wall_texture",
    "func get_breach_overlay_texture",
    "func get_object_png_texture_for_resolved_path",
    "func get_placeholder_texture",
    "func load_optional_texture",
    "func clear_all_caches",
    "func get_cache_debug_state",
):
    if token not in runtime:
        errors.append(f"VisualAssetResourceRuntime missing contract token: {token}")

for forbidden in (
    "extends Node",
    "extends Node2D",
    "GridManager",
    "MissionManager",
    "get_node(",
    "get_tree(",
    "queue_redraw(",
    "grid_to_iso(",
    "draw_line(",
    "draw_polyline(",
    "draw_colored_polygon(",
    "draw_circle(",
    "draw_rect(",
    "draw_arc(",
    "draw_string(",
    "draw_texture",
    "draw_set_transform",
    "gameplay",
):
    if forbidden in runtime:
        errors.append(f"VisualAssetResourceRuntime contains forbidden scene/Canvas dependency: {forbidden}")

for required_runtime_token in ("ResourceLoader", "Texture2D", "_texture_caches"):
    if required_runtime_token not in runtime:
        errors.append(f"VisualAssetResourceRuntime lost resource ownership token: {required_runtime_token}")

if "const ASSET_PATHS" in runtime or "ISO_OBJECT_ASSET_PACK_DIR" in runtime or "ISO_WALL_ASSET_PACK_DIR" in runtime:
    errors.append("VisualAssetResourceRuntime duplicates VisualAssetCatalog path catalogs")

if 'preload("res://scripts/visual/renderer/visual_asset_resource_runtime.gd")' not in renderer:
    errors.append("RoomVisualRenderer missing VisualAssetResourceRuntime preload")
if "VisualAssetResourceRuntimeRef.new()" not in renderer:
    errors.append("RoomVisualRenderer missing resource runtime instance")

for cache_name in (
    "_iso_placeholder_texture_cache",
    "_iso_object_png_texture_cache",
    "_iso_wall_asset_texture_cache",
    "_iso_wall_breach_overlay_texture_cache",
    "_iso_floor_asset_texture_cache",
    "_iso_ground_asset_texture_cache",
):
    if re.search(rf"(?m)^var {re.escape(cache_name)}\b", renderer):
        errors.append(f"RoomVisualRenderer retained migrated cache field: {cache_name}")
if "ResourceLoader" in renderer:
    errors.append("RoomVisualRenderer retained direct ResourceLoader ownership")

renderer_without_preloads = re.sub(r"preload\([^\n]+\)", "", renderer)
if re.search(r"(?<![A-Za-z_])load\s*\(", renderer_without_preloads):
    errors.append("RoomVisualRenderer retained direct load() resource execution")

resource_delegates = {
    "get_iso_floor_texture_for_asset_key": "_visual_asset_resource_runtime.get_floor_texture",
    "get_iso_ground_texture_for_asset_key": "_visual_asset_resource_runtime.get_ground_texture",
    "get_iso_gray_test_asset_path": "_visual_asset_resource_runtime.resolve_gray_test_asset_path",
    "get_gray_room_visual_test_asset_validation": "_visual_asset_resource_runtime.validate_gray_test_assets",
    "get_iso_wall_texture_for_asset_key": "_visual_asset_resource_runtime.resolve_wall_texture",
    "get_breach_overlay_texture_for_asset_key": "_visual_asset_resource_runtime.get_breach_overlay_texture",
    "get_iso_object_png_asset_path": "_visual_asset_resource_runtime.resolve_object_png_path",
    "is_iso_object_png_asset_key": "_visual_asset_resource_runtime.is_object_png_asset_key",
    "get_iso_object_png_texture_for_resolved_path": "_visual_asset_resource_runtime.get_object_png_texture_for_resolved_path",
    "get_iso_object_png_texture_for_asset_key": "_visual_asset_resource_runtime.get_object_png_texture",
    "get_iso_placeholder_asset_path": "_visual_asset_resource_runtime.resolve_placeholder_path",
    "is_placeholder_object_texture_path": "_visual_asset_resource_runtime.is_placeholder_object_texture_path",
    "is_placeholder_object_texture_asset_key": "_visual_asset_resource_runtime.is_placeholder_object_texture_asset_key",
    "get_iso_placeholder_texture_for_asset_key": "_visual_asset_resource_runtime.get_placeholder_texture",
    "clear_iso_placeholder_texture_cache": "_visual_asset_resource_runtime.clear_all_caches",
    "get_iso_texture_for_asset_key": "_visual_asset_resource_runtime.resolve_texture",
    "get_iso_visual_texture_debug_state": "_visual_asset_resource_runtime.build_texture_debug_state",
    "validate_iso_object_png_assets": "_visual_asset_resource_runtime.validate_object_png_assets",
}
for name, delegate in resource_delegates.items():
    body = function_body(renderer, name)
    if not body:
        errors.append(f"RoomVisualRenderer missing compatibility delegate: {name}")
    elif delegate not in body:
        errors.append(f"RoomVisualRenderer {name} must delegate to VisualAssetResourceRuntime")

for name in ("draw_optional_visual_texture_asset", "can_draw_optional_visual_texture_asset"):
    body = function_body(renderer, name)
    if "_visual_asset_resource_runtime.load_optional_texture" not in body:
        errors.append(f"RoomVisualRenderer {name} retained optional texture loader ownership")

for export_name in (
    "iso_floor_default_texture",
    "iso_wall_default_texture",
    "iso_object_generic_texture",
):
    if f"@export var {export_name}: Texture2D" not in renderer:
        errors.append(f"RoomVisualRenderer lost serialized texture export: {export_name}")

for canvas_token in ("draw_texture_rect(", "draw_texture_rect_region(", "draw_set_transform("):
    if canvas_token not in renderer:
        errors.append(f"RoomVisualRenderer lost retained Canvas execution token: {canvas_token}")
    if canvas_token in runtime:
        errors.append(f"VisualAssetResourceRuntime must not execute Canvas token: {canvas_token}")

if "VisualAssetResourceRuntime contract OK" not in contract:
    errors.append("resource runtime contract missing final success marker")
if "check_visual_asset_resource_runtime_contract.gd" not in workflow:
    errors.append("Renderer Component Gate missing resource runtime contract")
if "check_visual_asset_resource_runtime_boundary.py" not in workflow:
    errors.append("Renderer Component Gate missing resource runtime boundary check")

renderer_lines = len(renderer.splitlines())
RESOURCE_RUNTIME_CAP = 5209
if renderer_lines > RESOURCE_RUNTIME_CAP:
    errors.append(f"RoomVisualRenderer grew beyond resource runtime cap: {renderer_lines} > {RESOURCE_RUNTIME_CAP}")

if errors:
    print("VisualAssetResourceRuntime boundary audit FAILED:")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)

print(f"VisualAssetResourceRuntime boundary audit OK ({renderer_lines} renderer lines)")
