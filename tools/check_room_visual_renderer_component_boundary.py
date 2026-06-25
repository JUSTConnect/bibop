#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RENDERER = ROOT / "scripts/field/room_visual_renderer.gd"
RENDERER_DIR = ROOT / "scripts/visual/renderer"
SMOKE = ROOT / "tools/ci/check_room_visual_renderer_smoke_contract.gd"
WORKFLOW = ROOT / ".github/workflows/renderer-component-gate.yml"
COMPONENT_MAP = ROOT / "docs/room_visual_renderer_component_map.md"
errors: list[str] = []


def read(path: Path) -> str:
    if not path.exists():
        errors.append(f"missing required file: {path.relative_to(ROOT)}")
        return ""
    return path.read_text(encoding="utf-8")


def function_body(source: str, name: str) -> str:
    match = re.search(rf"(?ms)^func {re.escape(name)}\s*\(.*?(?=^func |\Z)", source)
    return match.group(0) if match else ""


def expect_tokens(source: str, label: str, tokens: tuple[str, ...]) -> None:
    for token in tokens:
        if token not in source:
            errors.append(f"{label} missing required token: {token}")


renderer = read(RENDERER)
workflow = read(WORKFLOW)
smoke = read(SMOKE)
component_map = read(COMPONENT_MAP)

component_contracts = {
    "iso_projection_service.gd": ("class_name IsoProjectionService", "static func grid_to_iso", "static func iso_to_grid", "static func get_depth_key"),
    "iso_draw_entry_contract.gd": ("class_name IsoDrawEntryContract", "static func make_entry", "static func less", "static func validate_entry"),
    "floor_renderer.gd": ("class_name FloorRenderer", "static func build_draw_entries", "static func get_visual_profile_key_for_cell"),
    "wall_renderer.gd": ("class_name WallRenderer", "static func get_render_topology", "static func get_mounted_anchor_zones", "static func build_draw_entries"),
    "object_renderer.gd": ("static func make_draw_entry", "static func build_object_descriptor", "static func get_wall_mounted_render_layer"),
    "object_primitive_renderer.gd": ("static func build_floor_base_commands", "static func build_wall_mounted_commands", "static func build_shape_commands"),
    "object_texture_dispatch_policy.gd": ("static func build_attempt_plan", "static func get_descriptor_route", "static func should_emit_success_accent"),
    "door_canvas_renderer.gd": ("class_name DoorCanvasRenderer", "static func build_threshold_commands", "static func build_frame_commands", "static func build_body_commands", "static func build_state_overlay_commands"),
    "route_renderer.gd": ("class_name RouteRenderer", "static func build_wall_route_segment", "static func build_floor_topology_plan", "static func build_procedural_route_commands"),
    "cable_canvas_renderer.gd": ("class_name CableCanvasRenderer", "static func build_floor_cable_commands", "static func build_bridge_commands"),
    "overlay_renderer.gd": ("class_name OverlayRenderer", "static func build_mouse_selection_commands", "static func build_interaction_target_commands"),
    "map_constructor_overlay_renderer.gd": ("class_name MapConstructorOverlayRenderer", "static func build_commands"),
    "runtime_debug_overlay_renderer.gd": ("class_name RuntimeDebugOverlayRenderer", "static func build_helper_preview_commands", "static func build_wall_debug_commands"),
    "fog_renderer.gd": ("class_name FogRenderer", "static func get_fog_color", "static func build_cell_overlay_commands", "static func build_wall_overlay_commands"),
    "iso_asset_alignment_policy.gd": ("class_name IsoAssetAlignmentPolicy", "const ALIGNMENT_RULES: Dictionary", "static func normalize_runtime_rule"),
    "visual_asset_resource_runtime.gd": ("class_name VisualAssetResourceRuntime", "func resolve_texture", "func clear_all_caches"),
}
components: dict[str, str] = {}
for filename, tokens in component_contracts.items():
    source = read(RENDERER_DIR / filename)
    components[filename] = source
    expect_tokens(source, filename, tokens)

renderer_lines = len(renderer.splitlines())
ROOM_VISUAL_RENDERER_FINAL_CAP = 4288
if renderer_lines > ROOM_VISUAL_RENDERER_FINAL_CAP:
    errors.append(f"RoomVisualRenderer grew beyond final coordinator cap: {renderer_lines} > {ROOM_VISUAL_RENDERER_FINAL_CAP}")

expect_tokens(renderer, "RoomVisualRenderer", (
    'preload("res://scripts/visual/renderer/iso_projection_service.gd")',
    'preload("res://scripts/visual/renderer/iso_draw_entry_contract.gd")',
    'preload("res://scripts/visual/renderer/iso_asset_alignment_policy.gd")',
    'preload("res://scripts/visual/renderer/visual_asset_resource_runtime.gd")',
    'preload("res://scripts/visual/renderer/floor_renderer.gd")',
    'preload("res://scripts/visual/renderer/wall_renderer.gd")',
    'preload("res://scripts/visual/renderer/object_renderer.gd")',
    'preload("res://scripts/visual/renderer/object_primitive_renderer.gd")',
    'preload("res://scripts/visual/renderer/object_texture_dispatch_policy.gd")',
    'preload("res://scripts/visual/renderer/door_canvas_renderer.gd")',
    'preload("res://scripts/visual/renderer/route_renderer.gd")',
    'preload("res://scripts/visual/renderer/cable_canvas_renderer.gd")',
    'preload("res://scripts/visual/renderer/overlay_renderer.gd")',
    'preload("res://scripts/visual/renderer/map_constructor_overlay_renderer.gd")',
    'preload("res://scripts/visual/renderer/runtime_debug_overlay_renderer.gd")',
    'preload("res://scripts/visual/renderer/fog_renderer.gd")',
    "var _visual_asset_resource_runtime = VisualAssetResourceRuntimeRef.new()",
))

# The final coordinator keeps serialized scene inputs and actual Canvas execution.
for token in (
    "@export var iso_floor_default_texture: Texture2D",
    "@export var iso_wall_default_texture: Texture2D",
    "@export var iso_object_generic_texture: Texture2D",
    "func _enter_tree()", "func _ready()", "func _exit_tree()", "func _process(", "func _draw()",
    "draw_texture_rect(", "draw_texture_rect_region(", "draw_set_transform(",
):
    if token not in renderer:
        errors.append(f"RoomVisualRenderer lost retained scene/Canvas responsibility: {token}")

# Public methods actually used by UI/controller/runtime integrations must remain.
for public_api in (
    "should_preview_drive_bipob_visual_position",
    "get_iso_tile_half_size", "grid_to_iso", "iso_to_grid", "get_object_visual_center",
    "get_cell_at_iso_visual_position", "set_iso_mouse_selection_visuals", "clear_iso_mouse_selection_visuals",
    "set_map_constructor_preview_cell", "set_map_constructor_wall_mounted_preview",
    "set_selected_wall_mounted_object", "clear_selected_wall_mounted_object",
    "set_map_constructor_link_target", "clear_map_constructor_link_target",
    "set_map_constructor_overlay_preferences", "set_map_constructor_overlay_data",
    "set_map_constructor_editor_render_active", "set_selected_interaction_target",
    "is_grid_visual_invalidation_connected",
):
    if not function_body(renderer, public_api):
        errors.append(f"RoomVisualRenderer lost externally used compatibility API: {public_api}")

# Repository-wide audit proved these coordinator-only compatibility/debug APIs have no caller.
removed_functions = (
    "initialize_from_grid", "clear_visuals", "is_task_test_visual_preview_context",
    "get_iso_visual_preview_state", "get_iso_visual_preview_state_text",
    "get_iso_exported_tile_size_matches_active_mode", "get_iso_projection_diagnostic_text",
    "is_walkable_floor_like_for_iso_passage", "is_iso_interactive_floor_tile", "is_iso_passage_floor_cell",
    "get_iso_floor_asset_key_for_visual_height", "get_iso_floor_asset_key_for_visual_state",
    "get_platform_data_for_floor_cell", "_get_platform_occupants_for_cell",
    "get_iso_wall_asset_key_for_profile", "get_iso_gray_test_asset_path",
    "normalize_wall_height_level", "get_wall_asset_key_for_material_and_height",
    "_is_object_state_on", "_is_fuse_present", "get_iso_placeholder_texture_for_asset_key",
    "clear_iso_placeholder_texture_cache", "has_iso_texture_for_asset_key",
    "get_iso_visual_layer_debug_state", "get_iso_visual_texture_debug_state",
    "validate_iso_object_png_assets", "get_iso_asset_alignment_diagnostics",
    "get_iso_visual_cell_stats", "get_iso_visual_debug_report", "validate_iso_visual_debug_report",
    "draw_wall_procedural_cable", "draw_cooling_wall_canvas_asset",
    "can_draw_optional_visual_texture_asset", "draw_iso_wall_texture_for_cell",
    "draw_iso_floor_prototype", "draw_iso_wall_prototype", "get_iso_object_sub_order",
)
for name in removed_functions:
    if function_body(renderer, name):
        errors.append(f"RoomVisualRenderer retained audited dead/compatibility function: {name}")

# Resource/cache and policy ownership must not return to the coordinator.
for cache_name in (
    "_iso_placeholder_texture_cache", "_iso_object_png_texture_cache", "_iso_wall_asset_texture_cache",
    "_iso_wall_breach_overlay_texture_cache", "_iso_floor_asset_texture_cache", "_iso_ground_asset_texture_cache",
):
    if re.search(rf"(?m)^var {re.escape(cache_name)}\b", renderer):
        errors.append(f"RoomVisualRenderer retained migrated cache: {cache_name}")
renderer_without_preloads = re.sub(r"preload\([^\n]+\)", "", renderer)
if "ResourceLoader" in renderer or re.search(r"(?<![A-Za-z_])load\s*\(", renderer_without_preloads):
    errors.append("RoomVisualRenderer retained direct resource loading")
for forbidden_constant in (
    "ISO_ASSET_ALIGNMENT_RULES", "ISO_OBJECT_CANONICAL_VISUAL_IDS", "ISO_FLOOR_ASSET_CATALOG",
    "ISO_WALL_ASSET_CATALOG", "ISO_GROUND_ASSET_CATALOG", "ISO_FLOOR_ATLAS_LAYOUT",
):
    if re.search(rf"(?m)^const {forbidden_constant}\b", renderer):
        errors.append(f"RoomVisualRenderer retained migrated policy/catalog constant: {forbidden_constant}")

# One canonical, policy-free Canvas command executor replaces overlay/route/object duplicates.
for old_dispatcher in ("_draw_overlay_commands", "_draw_route_commands", "_draw_object_primitive_commands"):
    if function_body(renderer, old_dispatcher) or f"{old_dispatcher}(" in renderer:
        errors.append(f"RoomVisualRenderer retained duplicate command executor: {old_dispatcher}")
dispatcher = function_body(renderer, "_draw_canvas_commands")
point_adapter = function_body(renderer, "_as_canvas_point_array")
for token in ('"polygon"', '"polyline"', '"line"', '"circle"', '"rect"', '"arc"', '"text"', '"wall_cable_segment"'):
    if token not in dispatcher:
        errors.append(f"canonical Canvas dispatcher missing command kind: {token}")
for token in ("draw_colored_polygon(", "draw_polyline(", "draw_line(", "draw_circle(", "draw_rect(", "draw_arc(", "draw_string(", "draw_iso_cable_wall_segment("):
    if token not in dispatcher:
        errors.append(f"canonical Canvas dispatcher missing execution token: {token}")
for forbidden in ("FloorRendererRef", "WallRendererRef", "ObjectRendererRef", "DoorCanvasRendererRef", "RouteRendererRef", "FogRendererRef", "GridManager", "MissionManager"):
    if forbidden in dispatcher:
        errors.append(f"canonical Canvas dispatcher contains policy/runtime branching: {forbidden}")
if "PackedVector2Array" not in point_adapter or "Vector2i" not in point_adapter:
    errors.append("canonical Canvas point adapter lost packed/array compatibility")

for delegate_name in (
    "draw_iso_mouse_selection_overlay", "draw_map_constructor_visual_overlay_passes",
    "draw_iso_object_slab", "draw_iso_object_pillar", "draw_iso_object_door_panel",
    "draw_iso_object_terminal_console", "draw_iso_object_small_marker", "draw_iso_object_line",
    "draw_iso_object_heat_marker", "draw_wall_mounted_object_shape", "draw_iso_door_insert",
    "draw_iso_fog_cell_overlay", "draw_iso_fog_wall_overlay",
):
    body = function_body(renderer, delegate_name)
    if "_draw_canvas_commands" not in body:
        errors.append(f"RoomVisualRenderer {delegate_name} must use canonical Canvas command execution")

# Unified geometry queue and frame passes remain explicit and deterministic.
queue_body = function_body(renderer, "build_iso_geometry_draw_entries")
for token in (
    "build_iso_floor_draw_entries", "build_iso_platform_surface_draw_entries", "build_iso_wall_draw_entries",
    "build_iso_cable_object_bridge_draw_entries", "build_iso_object_draw_entries", "sort_custom(sort_iso_draw_entries)",
):
    if token not in queue_body:
        errors.append(f"unified geometry queue lost composition token: {token}")
entry_dispatch = function_body(renderer, "draw_iso_draw_entry")
for kind in ('"floor"', '"ground"', '"platform_surface"', '"wall_body"', '"cable_bridge"', '"wall_mounted"'):
    if kind not in entry_dispatch:
        errors.append(f"draw-entry dispatcher lost representative kind: {kind}")
frame_body = function_body(renderer, "_draw")
frame_order = (
    "draw_iso_geometry_prototype", "draw_wall_mount_zones_overlay", "draw_wall_run_overlay",
    "draw_floor_join_overlay", "draw_cable_reel_drag_trail", "draw_iso_mouse_selection_overlay",
    "draw_map_constructor_visual_overlay_passes", "draw_selected_interaction_target_overlay",
    "draw_world_overlay_markers", "draw_fan_platform_marker", "draw_iso_fog_overlay",
)
position = 0
for token in frame_order:
    found = frame_body.find(token, position)
    if found < 0:
        errors.append(f"frame pass order missing/out-of-order token: {token}")
    else:
        position = found + len(token)

# Deterministic representative smoke coverage is permanent.
for token in (
    "TASK TEST renderer smoke contract OK", "_check_floor_and_connected_walls",
    "_check_wall_mount_and_door_ordering", "_check_door_route_and_bridge_commands",
    "_check_selection_constructor_debug_and_fog", "_check_asset_fallback_and_alignment",
):
    if token not in smoke:
        errors.append(f"renderer smoke contract missing coverage token: {token}")
for token in (
    "Check RoomVisualRenderer smoke contract",
    "res://tools/ci/check_room_visual_renderer_smoke_contract.gd",
):
    if token not in workflow:
        errors.append(f"Renderer Component Gate missing final smoke validation: {token}")
for token in ("4,288 lines", "_draw_canvas_commands", "VisualAssetResourceRuntime", "IsoAssetAlignmentPolicy"):
    if token not in component_map:
        errors.append(f"component map missing final ownership token: {token}")

if errors:
    print("RoomVisualRenderer final coordinator boundary FAILED:")
    for error in errors:
        print(" -", error)
    raise SystemExit(1)

print(f"RoomVisualRenderer final coordinator boundary OK ({renderer_lines} lines)")
