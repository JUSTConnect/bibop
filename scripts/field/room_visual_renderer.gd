extends Node2D
class_name RoomVisualRenderer

# GridManager remains the gameplay grid source.
# RoomVisualRenderer is a future visual projection layer.
# Gameplay cells remain Vector2i in GridManager logic.
# The helpers in this script are visual projection helpers only.
# Future PRs will use them for floor, wall, object, fog, and overlay rendering.
@export var debug_draw_marker: bool = false
@export var debug_draw_iso_helper_preview: bool = false
@export var render_iso_floor_prototype: bool = false
@export var render_iso_wall_prototype: bool = false
@export var render_iso_object_prototype: bool = false
@export var render_iso_fog_overlay: bool = false
@export var iso_wall_cutaway_enabled: bool = true
@export var show_wall_topology_overlay: bool = false
@export var show_wall_mount_zones_overlay: bool = false
@export var show_object_grounding_overlay: bool = false
@export var show_asset_alignment_overlay: bool = false
@export var show_door_opening_overlay: bool = false
@export var show_wall_run_overlay: bool = false
@export var show_floor_join_overlay: bool = false
@export var use_procedural_floor_debug_tiles: bool = false
@export var debug_floor_tile_bounds: bool = false
@export var use_iso_floor_atlas_textures: bool = false
@export var allow_legacy_floor_texture_assets: bool = false
@export var use_iso_visual_preview_preset: bool = false
@export var iso_visual_preview_includes_fog: bool = false
@export var iso_fog_draw_cell_shapes: bool = false
@export var iso_visual_preview_includes_asset_hooks: bool = false
@export var iso_visual_preview_drives_bipob_visual_position: bool = true
@export var debug_draw_iso_fog_outlines: bool = false
@export var iso_fog_unexplored_alpha: float = 0.42
@export var iso_fog_explored_alpha: float = 0.18
@export var iso_fog_visible_alpha: float = 0.0
@export var debug_draw_iso_cell_outlines: bool = false
@export var debug_draw_iso_wall_outlines: bool = false
@export var debug_draw_iso_object_outlines: bool = false
@export var use_iso_tile_asset_hooks: bool = false
@export var use_iso_placeholder_asset_preset: bool = false
@export var iso_placeholder_asset_preset_requires_preview: bool = true
@export var use_iso_concrete_wall_png_smoke_preview: bool = true
@export var iso_floor_atlas_texture: Texture2D = null
@export var iso_floor_default_texture: Texture2D = null
@export var iso_floor_stepped_texture: Texture2D = null
@export var iso_floor_clean_lab_texture: Texture2D = null
@export var iso_floor_dark_service_texture: Texture2D = null
@export var iso_floor_hazard_texture: Texture2D = null
@export var iso_floor_power_texture: Texture2D = null
@export var iso_floor_damaged_texture: Texture2D = null
@export var iso_floor_reinforced_texture: Texture2D = null
@export var iso_floor_diagnostic_texture: Texture2D = null
@export var iso_floor_door_underlay_texture: Texture2D = null
@export var iso_wall_default_texture: Texture2D = null
@export var iso_wall_outer_texture: Texture2D = null
@export var iso_wall_brick_texture: Texture2D = null
@export var iso_wall_concrete_texture: Texture2D = null
@export var iso_wall_grate_texture: Texture2D = null
@export var iso_wall_damaged_texture: Texture2D = null
@export var iso_wall_steel_texture: Texture2D = null
@export var iso_wall_energy_texture: Texture2D = null
@export var iso_object_door_texture: Texture2D = null
@export var iso_object_terminal_texture: Texture2D = null
@export var iso_object_key_texture: Texture2D = null
@export var iso_object_component_texture: Texture2D = null
@export var iso_object_socket_texture: Texture2D = null
@export var iso_object_cable_texture: Texture2D = null
@export var iso_object_generic_texture: Texture2D = null
@export var iso_object_fuse_texture: Texture2D = null
@export var iso_object_repair_kit_texture: Texture2D = null
@export var iso_object_keycard_texture: Texture2D = null
@export var iso_object_access_code_texture: Texture2D = null
@export var iso_object_cable_reel_texture: Texture2D = null
@export var iso_object_button_texture: Texture2D = null
@export var iso_object_switch_texture: Texture2D = null
@export var iso_tile_width: float = 128.0
@export var iso_tile_height: float = 64.0
@export var iso_wall_height: float = 56.0
@export var iso_floor_projection_pitch_correction_degrees: float = 0.0
@export var iso_floor_visual_inset: float = 1.0
@export var iso_wall_visual_inset: float = 8.0
@export var iso_object_marker_height: float = 18.0
@export var iso_origin: Vector2 = Vector2.ZERO

# Dev-only placeholder preset: loads BIP-Visual-011 SVG placeholders as visual fallback textures.
# Explicit exported Texture2D hooks always take priority when assigned.
# Missing/unsupported placeholder resources safely fall back to procedural rendering.
# Visual-only behavior; no gameplay state is changed.
const ISO_PLACEHOLDER_ASSET_PATHS: Dictionary = {
	"floor_default": "res://assets/visual/isometric/placeholders/iso_floor_default.svg",
	"floor_stepped": "res://assets/visual/isometric/placeholders/iso_floor_stepped.svg",
	"floor_clean_lab": "res://assets/visual/isometric/placeholders/iso_floor_clean_lab.svg",
	"floor_dark_service": "res://assets/visual/isometric/placeholders/iso_floor_dark_service.svg",
	"floor_hazard": "res://assets/visual/isometric/placeholders/iso_floor_hazard.svg",
	"floor_power": "res://assets/visual/isometric/placeholders/iso_floor_power.svg",
	"floor_damaged": "res://assets/visual/isometric/placeholders/iso_floor_damaged.svg",
	"floor_reinforced": "res://assets/visual/isometric/placeholders/iso_floor_reinforced.svg",
	"floor_diagnostic": "res://assets/visual/isometric/placeholders/iso_floor_diagnostic.svg",
	"floor_door_underlay": "res://assets/visual/isometric/placeholders/iso_floor_door_underlay.svg",
	"wall_default": "res://assets/visual/isometric/placeholders/iso_wall_default.svg",
	"wall_outer": "res://assets/visual/isometric/placeholders/iso_wall_outer.svg",
	"wall_brick": "res://assets/visual/isometric/placeholders/iso_wall_brick.svg",
	"wall_concrete": "res://assets/visual/isometric/placeholders/iso_wall_concrete.svg",
	"wall_grate": "res://assets/visual/isometric/placeholders/iso_wall_grate.svg",
	"wall_damaged": "res://assets/visual/isometric/placeholders/iso_wall_damaged.svg",
	"wall_steel": "res://assets/visual/isometric/placeholders/iso_wall_steel.svg",
	"wall_energy": "res://assets/visual/isometric/placeholders/iso_wall_energy.svg",
	"object_door": "res://assets/visual/isometric/placeholders/iso_object_door.svg",
	"object_terminal": "res://assets/visual/isometric/placeholders/iso_object_terminal.svg",
	"object_key": "res://assets/visual/isometric/placeholders/iso_object_key.svg",
	"object_component": "res://assets/visual/isometric/placeholders/iso_object_component.svg",
	"object_socket": "res://assets/visual/isometric/placeholders/iso_object_socket.svg",
	"object_cable": "res://assets/visual/isometric/placeholders/iso_object_cable.svg",
	"object_generic": "res://assets/visual/isometric/placeholders/iso_object_generic.svg",
	"object_fuse": "res://assets/visual/isometric/placeholders/iso_object_fuse.svg",
	"object_repair_kit": "res://assets/visual/isometric/placeholders/iso_object_repair_kit.svg",
	"object_keycard": "res://assets/visual/isometric/placeholders/iso_object_keycard.svg",
	"object_access_code": "res://assets/visual/isometric/placeholders/iso_object_access_code.svg",
	"object_cable_reel": "res://assets/visual/isometric/placeholders/iso_object_cable_reel.svg",
	"object_button": "res://assets/visual/isometric/placeholders/iso_object_button.svg",
	"object_switch": "res://assets/visual/isometric/placeholders/iso_object_switch.svg"
}

const ISO_CONCRETE_WALL_SMOKE_TEXTURE_PATH: String = "res://assets/visual/isometric/Concrete/ChatGPT Image Jun 2, 2026, 11_48_05 AM.png"
const ISO_CONCRETE_WALL_SMOKE_TARGET_WIDTH: float = 128.0
const ISO_CONCRETE_WALL_SMOKE_TARGET_HEIGHT: float = 128.0

const ISO_FLOOR_ATLAS_COLUMNS: int = 6
const ISO_FLOOR_ATLAS_ROWS: int = 7
const ISO_FLOOR_ATLAS_BASE_VARIANTS: int = 6
const ISO_FLOOR_ATLAS_HEAVY_METAL_VARIANTS: int = 4
const ISO_FLOOR_ATLAS_SOURCE_EDGE_PADDING: float = 3.0
const ISO_FLOOR_ATLAS_SCREEN_OVERLAP: float = 1.5
const ISO_FLOOR_UNDERLAY_OVERLAP: float = 1.25
const ISO_FLOOR_OVERLAY_INNER_INSET: float = 12.0
const ISO_FLOOR_SEAM_SAFE_BASE_VARIANTS: Dictionary = {
	"grate_base": [1],
	"metal_base": [1],
	"concrete_base": [1],
}
# The source atlas is 7524x8778, giving 1254x1254 frames in a 6x7 grid.
# Each frame is a high-resolution render of one isometric floor cell and is
# intentionally downsampled into the current iso_tile_width x iso_tile_height.
const ISO_FLOOR_ATLAS_LAYOUT: Dictionary = {
	"grate_base": {"row": 1, "variants": 6, "overlay": false},
	"metal_base": {"row": 2, "variants": 6, "overlay": false},
	"metal_light_wear": {"row": 3, "variants": 6, "overlay": true},
	"metal_heavy_damage": {"row": 4, "variants": ISO_FLOOR_ATLAS_HEAVY_METAL_VARIANTS, "overlay": true},
	"concrete_base": {"row": 5, "variants": 6, "overlay": false},
	"concrete_light_wear": {"row": 6, "variants": 6, "overlay": true},
	"concrete_heavy_damage": {"row": 7, "variants": 6, "overlay": true},
}

const ISO_ASSET_ALIGNMENT_RULES: Dictionary = {
	"floor_default": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": Vector2(128, 64), "layer_hint": "floor", "notes": "Default 128x64 floor diamond centered in the grid cell."},
	"floor_stepped": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": Vector2(128, 64), "layer_hint": "floor", "notes": "Stepped 128x64 floor diamond centered in the grid cell."},
	"floor_clean_lab": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": Vector2(128, 64), "layer_hint": "floor", "notes": "Clean lab 128x64 floor diamond centered in the grid cell."},
	"floor_dark_service": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": Vector2(128, 64), "layer_hint": "floor", "notes": "Dark service 128x64 floor diamond centered in the grid cell."},
	"floor_hazard": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": Vector2(128, 64), "layer_hint": "floor", "notes": "Hazard 128x64 floor diamond centered in the grid cell."},
	"floor_power": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": Vector2(128, 64), "layer_hint": "floor", "notes": "Powered 128x64 floor diamond centered in the grid cell."},
	"floor_damaged": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": Vector2(128, 64), "layer_hint": "floor", "notes": "Damaged 128x64 floor diamond centered in the grid cell."},
	"floor_reinforced": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": Vector2(128, 64), "layer_hint": "floor", "notes": "Reinforced 128x64 floor diamond centered in the grid cell."},
	"floor_diagnostic": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": Vector2(128, 64), "layer_hint": "floor", "notes": "Diagnostic 128x64 floor diamond centered in the grid cell."},
	"floor_door_underlay": {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": Vector2(128, 64), "layer_hint": "floor", "notes": "Door underlay remains centered under the wall opening."},
	"wall_default": {"anchor": "wall_cell_base", "scale": 1.0, "offset": Vector2(0, -32), "expected_size": Vector2(128, 120), "layer_hint": "wall", "notes": "Wall canvas bottom-center aligns to the blocked wall cell base."},
	"wall_outer": {"anchor": "wall_cell_base", "scale": 1.0, "offset": Vector2(0, -32), "expected_size": Vector2(128, 120), "layer_hint": "wall", "notes": "Outer wall canvas bottom-center aligns to the blocked wall cell base."},
	"wall_brick": {"anchor": "wall_cell_base", "scale": 1.0, "offset": Vector2(0, -32), "expected_size": Vector2(128, 120), "layer_hint": "wall", "notes": "Brick wall canvas bottom-center aligns to the blocked wall cell base."},
	"wall_concrete": {"anchor": "wall_cell_base", "scale": 1.0, "offset": Vector2(0, -32), "expected_size": Vector2(128, 120), "layer_hint": "wall", "notes": "Concrete wall canvas bottom-center aligns to the blocked wall cell base."},
	"wall_grate": {"anchor": "wall_cell_base", "scale": 1.0, "offset": Vector2(0, -32), "expected_size": Vector2(128, 120), "layer_hint": "wall", "notes": "Grate wall canvas bottom-center aligns to the blocked wall cell base."},
	"wall_damaged": {"anchor": "wall_cell_base", "scale": 1.0, "offset": Vector2(0, -32), "expected_size": Vector2(128, 120), "layer_hint": "wall", "notes": "Damaged wall canvas bottom-center aligns to the blocked wall cell base."},
	"wall_steel": {"anchor": "wall_cell_base", "scale": 1.0, "offset": Vector2(0, -32), "expected_size": Vector2(128, 120), "layer_hint": "wall", "notes": "Steel wall canvas bottom-center aligns to the blocked wall cell base."},
	"wall_energy": {"anchor": "wall_cell_base", "scale": 1.0, "offset": Vector2(0, -32), "expected_size": Vector2(128, 120), "layer_hint": "wall", "notes": "Energy wall canvas bottom-center aligns to the blocked wall cell base."},
	"object_door": {"anchor": "door_insert_center", "scale": 0.9, "offset": Vector2(0, -20), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Door art centers inside the visual wall opening."},
	"object_terminal": {"anchor": "wall_mount_center", "scale": 0.8, "offset": Vector2(0, -18), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Terminal art centers on the wall mount band."},
	"object_key": {"anchor": "bottom_center", "scale": 0.55, "offset": Vector2(0, -6), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Key pickup uses a small bottom-centered floor footprint."},
	"object_component": {"anchor": "bottom_center", "scale": 0.75, "offset": Vector2(0, -8), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Component prop uses a readable bottom-centered floor footprint."},
	"object_socket": {"anchor": "wall_mount_center", "scale": 0.8, "offset": Vector2(0, -18), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Socket art centers on the wall mount band."},
	"object_cable": {"anchor": "bottom_center", "scale": 0.75, "offset": Vector2(0, -8), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Cable-like prop uses a readable bottom-centered floor footprint."},
	"object_generic": {"anchor": "bottom_center", "scale": 0.75, "offset": Vector2(0, -8), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Generic prop uses a readable bottom-centered floor footprint."},
	"object_fuse": {"anchor": "bottom_center", "scale": 0.55, "offset": Vector2(0, -6), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Fuse pickup uses a small bottom-centered floor footprint."},
	"object_repair_kit": {"anchor": "bottom_center", "scale": 0.55, "offset": Vector2(0, -6), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Repair kit pickup uses a small bottom-centered floor footprint."},
	"object_keycard": {"anchor": "bottom_center", "scale": 0.55, "offset": Vector2(0, -6), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Keycard pickup uses a small bottom-centered floor footprint."},
	"object_access_code": {"anchor": "bottom_center", "scale": 0.55, "offset": Vector2(0, -6), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Access-code pickup uses a small bottom-centered floor footprint."},
	"object_cable_reel": {"anchor": "bottom_center", "scale": 0.75, "offset": Vector2(0, -8), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Cable reel prop uses a readable bottom-centered floor footprint."},
	"object_button": {"anchor": "wall_mount_center", "scale": 0.8, "offset": Vector2(0, -18), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Button art centers on the wall mount band."},
	"object_switch": {"anchor": "wall_mount_center", "scale": 0.8, "offset": Vector2(0, -18), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Switch art centers on the wall mount band."}
}

var _iso_placeholder_texture_cache: Dictionary = {}
var _iso_concrete_wall_smoke_texture_cache: Texture2D = null
var _iso_concrete_wall_smoke_texture_checked: bool = false
var _grid_manager: GridManager = null
var _rebuild_requested: bool = false

var selected_iso_cell: Vector2i = Vector2i(-1, -1)
var selected_iso_route_cells: Array[Vector2i] = []
var selected_iso_action_cell: Vector2i = Vector2i(-1, -1)
var map_constructor_preview_cell: Vector2i = Vector2i(-1, -1)
var map_constructor_preview_attached_wall_cell: Vector2i = Vector2i(-1, -1)
var map_constructor_preview_wall_side: String = ""
var map_constructor_preview_is_blocked: bool = false
var selected_wall_mounted_anchor_cell: Vector2i = Vector2i(-1, -1)
var selected_wall_mounted_attached_wall_cell: Vector2i = Vector2i(-1, -1)
var selected_wall_mounted_object_id: String = ""
var map_constructor_link_target_cell: Vector2i = Vector2i(-1, -1)
var map_constructor_link_target_object_id: String = ""
const WALL_SIDE_ORDER: Array[String] = ["north", "east", "south", "west"]
const WALL_MASS_RATIO: float = 0.7
const WALL_MOUNT_BAND_RATIO: float = 0.3

func set_grid_manager(grid: GridManager) -> void:
	_grid_manager = grid
	request_rebuild()

func initialize_from_grid(grid: GridManager) -> void:
	# Atlas floor tiles are downsampled heavily, so nearest sampling avoids
	# bright sub-pixel bleed from neighboring atlas frames and transparent edges.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_grid_manager(grid)

func request_rebuild() -> void:
	_rebuild_requested = true
	rebuild_visuals()
	queue_redraw()

func clear_visuals() -> void:
	_rebuild_requested = false
	queue_redraw()

func rebuild_visuals() -> void:
	if _grid_manager == null:
		_rebuild_requested = false
		return
	# Placeholder only: future PRs will build projected room visuals here.
	_rebuild_requested = false

func is_iso_visual_preview_active() -> bool:
	return use_iso_visual_preview_preset

func is_iso_renderer_active() -> bool:
	return (
		use_iso_visual_preview_preset
		or render_iso_floor_prototype
		or render_iso_wall_prototype
		or render_iso_object_prototype
		or use_iso_placeholder_asset_preset
	)

func should_render_iso_floor_visuals() -> bool:
	return (render_iso_floor_prototype or use_iso_visual_preview_preset)

func should_render_iso_wall_visuals() -> bool:
	return (render_iso_wall_prototype or use_iso_visual_preview_preset)

func should_render_iso_object_visuals() -> bool:
	return (render_iso_object_prototype or use_iso_visual_preview_preset)

func should_suppress_iso_fog_for_constructor() -> bool:
	var mission_manager: Node = get_mission_manager_ref()
	if mission_manager == null:
		return false
	if mission_manager.has_method("_is_task_test_constructor_context"):
		return bool(mission_manager.call("_is_task_test_constructor_context"))
	if mission_manager.has_method("get_current_mission_id"):
		return String(mission_manager.call("get_current_mission_id")) == "mission_10"
	return false

func should_render_iso_fog_visuals() -> bool:
	var fog_requested: bool = render_iso_fog_overlay or (use_iso_visual_preview_preset and iso_visual_preview_includes_fog)
	if should_suppress_iso_fog_for_constructor() and not render_iso_fog_overlay:
		return false
	return fog_requested

func should_draw_iso_fog_cell_shapes() -> bool:
	return should_render_iso_fog_visuals() and iso_fog_draw_cell_shapes

func should_use_iso_placeholder_asset_preset() -> bool:
	if not use_iso_placeholder_asset_preset:
		return false
	if iso_placeholder_asset_preset_requires_preview and not is_iso_visual_preview_active():
		return false
	return true

func should_use_iso_tile_asset_hook_visuals() -> bool:
	return (
		use_iso_tile_asset_hooks
		or (use_iso_visual_preview_preset and iso_visual_preview_includes_asset_hooks)
		or should_use_iso_placeholder_asset_preset()
	)

func is_task_test_visual_preview_context() -> bool:
	var mission_manager: Node = get_mission_manager_ref()
	if mission_manager == null:
		return use_iso_visual_preview_preset
	if mission_manager.has_method("_is_task_test_constructor_context"):
		return bool(mission_manager.call("_is_task_test_constructor_context"))
	if mission_manager.has_method("get_current_mission_id"):
		return String(mission_manager.call("get_current_mission_id")) == "mission_10"
	return use_iso_visual_preview_preset

func should_use_iso_concrete_wall_png_smoke_preview() -> bool:
	return (
		use_iso_concrete_wall_png_smoke_preview
		and is_iso_visual_preview_active()
		and should_use_iso_placeholder_asset_preset()
		and is_task_test_visual_preview_context()
	)

func should_preview_drive_bipob_visual_position() -> bool:
	return (use_iso_visual_preview_preset and iso_visual_preview_drives_bipob_visual_position)

func get_iso_visual_preview_state() -> Dictionary:
	return {
		"preview_active": is_iso_visual_preview_active(),
		"floor": should_render_iso_floor_visuals(),
		"wall": should_render_iso_wall_visuals(),
		"objects": should_render_iso_object_visuals(),
		"fog": should_render_iso_fog_visuals(),
		"fog_cell_shapes": should_draw_iso_fog_cell_shapes(),
		"constructor_fog_suppressed": should_suppress_iso_fog_for_constructor(),
		"asset_hooks": should_use_iso_tile_asset_hook_visuals(),
		"placeholder_assets": should_use_iso_placeholder_asset_preset(),
		"placeholder_requires_preview": iso_placeholder_asset_preset_requires_preview,
		"drives_bipob_visual_position": should_preview_drive_bipob_visual_position()
	}

func get_iso_visual_preview_state_text() -> String:
	var state: Dictionary = get_iso_visual_preview_state()
	return "IsoVisualPreview active=%s floor=%s wall=%s objects=%s fog=%s asset_hooks=%s placeholder_assets=%s drives_bipob=%s" % [
		str(state.get("preview_active", false)),
		str(state.get("floor", false)),
		str(state.get("wall", false)),
		str(state.get("objects", false)),
		str(state.get("fog", false)),
		str(state.get("asset_hooks", false)),
		str(state.get("placeholder_assets", false)),
		str(state.get("drives_bipob_visual_position", false))
	]

func get_iso_tile_half_size() -> Vector2:
	# Visual safety clamp to avoid invalid projection values.
	var safe_width: float = maxf(iso_tile_width, 1.0)
	var safe_height: float = maxf(iso_tile_height, 1.0)
	var half_width: float = safe_width * 0.5
	var half_height: float = safe_height * 0.5
	if absf(iso_floor_projection_pitch_correction_degrees) <= 0.001:
		return Vector2(half_width, half_height)
	# Correct the projection in angle space instead of applying a fixed pixel
	# offset.  This raises the top point and lowers the bottom point by roughly
	# the requested pitch while keeping the horizontal tile width unchanged.
	var base_angle: float = atan2(half_height, half_width)
	var corrected_angle: float = clampf(
		base_angle + deg_to_rad(iso_floor_projection_pitch_correction_degrees),
		deg_to_rad(8.0),
		deg_to_rad(60.0)
	)
	return Vector2(half_width, tan(corrected_angle) * half_width)

func grid_to_iso(cell: Vector2i) -> Vector2:
	# Converts gameplay grid coordinates (Vector2i) into visual isometric space.
	var half_size: Vector2 = get_iso_tile_half_size()
	var iso_x: float = float(cell.x - cell.y) * half_size.x
	var iso_y: float = float(cell.x + cell.y) * half_size.y
	return iso_origin + Vector2(iso_x, iso_y)

func get_object_visual_center(cell: Vector2i, object_data: Dictionary = {}) -> Vector2:
	# Visual-only helper for object overlay markers.
	# Keeps object anchors deterministic and independent of gameplay systems.
	var center: Vector2 = grid_to_iso(cell)
	var object_type: String = String(object_data.get("type", "")).to_lower()
	var object_kind: String = String(object_data.get("kind", "")).to_lower()
	var object_visual_hint: String = String(object_data.get("visual_hint", "")).to_lower()
	var object_id: String = String(object_data.get("id", "")).to_lower()
	var hint_blob: String = "%s %s %s %s" % [object_type, object_kind, object_visual_hint, object_id]
	if hint_blob.contains("wall") or hint_blob.contains("door") or hint_blob.contains("terminal"):
		return center + Vector2(0.0, -6.0)
	return center

func iso_to_grid(iso_position: Vector2) -> Vector2i:
	# Converts visual isometric position back to an approximate gameplay cell.
	# This is intended for future selection/click helpers, not movement logic.
	var half_size: Vector2 = get_iso_tile_half_size()
	var local_iso: Vector2 = iso_position - iso_origin
	var grid_x: float = (local_iso.x / half_size.x + local_iso.y / half_size.y) * 0.5
	var grid_y: float = (local_iso.y / half_size.y - local_iso.x / half_size.x) * 0.5
	return Vector2i(int(round(grid_x)), int(round(grid_y)))

func get_iso_diamond_points(cell: Vector2i) -> PackedVector2Array:
	var center_point: Vector2 = grid_to_iso(cell)
	var half_size: Vector2 = get_iso_tile_half_size()
	var points: PackedVector2Array = PackedVector2Array()
	points.append(center_point + Vector2(0.0, -half_size.y))
	points.append(center_point + Vector2(half_size.x, 0.0))
	points.append(center_point + Vector2(0.0, half_size.y))
	points.append(center_point + Vector2(-half_size.x, 0.0))
	return points

func get_iso_inset_diamond_points(cell: Vector2i, inset: float) -> PackedVector2Array:
	var base_points: PackedVector2Array = get_iso_diamond_points(cell)
	if inset <= 0.0:
		return base_points
	var center_point: Vector2 = grid_to_iso(cell)
	var inset_points: PackedVector2Array = PackedVector2Array()
	for point in base_points:
		var toward_center: Vector2 = center_point - point
		var distance_to_center: float = toward_center.length()
		if distance_to_center <= 0.0001:
			inset_points.append(point)
			continue
		var safe_inset: float = minf(inset, distance_to_center - 0.01)
		if safe_inset <= 0.0:
			inset_points.append(point)
			continue
		inset_points.append(point + toward_center.normalized() * safe_inset)
	return inset_points

func get_iso_wall_base_points(cell: Vector2i) -> PackedVector2Array:
	var topology: Dictionary = get_wall_render_topology(cell)
	return get_iso_wall_connected_base_points(cell, topology)

func get_iso_wall_connected_base_points(cell: Vector2i, topology: Dictionary) -> PackedVector2Array:
	# Visual-only wall footprint. Isolated walls stay tightened inside their cell,
	# while connected edges expand to the true cell edge so adjacent wall cells join
	# into a run without changing passability or GridManager data.
	var full_points: PackedVector2Array = get_iso_diamond_points(cell)
	var safe_inset: float = maxf(iso_wall_visual_inset, 0.0)
	var tight_points: PackedVector2Array = get_iso_inset_diamond_points(cell, safe_inset)
	if full_points.size() < 4 or tight_points.size() < 4:
		return full_points

	var result_points: PackedVector2Array = PackedVector2Array()
	for point in tight_points:
		result_points.append(point)

	var neighbors: Dictionary = Dictionary(topology.get("neighbors", {}))
	if bool(neighbors.get("north", false)):
		result_points[3] = full_points[3]
		result_points[0] = full_points[0]
	if bool(neighbors.get("east", false)):
		result_points[0] = full_points[0]
		result_points[1] = full_points[1]
	if bool(neighbors.get("south", false)):
		result_points[1] = full_points[1]
		result_points[2] = full_points[2]
	if bool(neighbors.get("west", false)):
		result_points[2] = full_points[2]
		result_points[3] = full_points[3]
	return result_points


func is_point_inside_iso_diamond(point: Vector2, diamond_points: PackedVector2Array) -> bool:
	if diamond_points.size() < 3:
		return false
	if Geometry2D.is_point_in_polygon(point, diamond_points):
		return true
	var direction_sign: int = 0
	for idx in range(diamond_points.size()):
		var next_idx: int = (idx + 1) % diamond_points.size()
		var edge: Vector2 = diamond_points[next_idx] - diamond_points[idx]
		var point_delta: Vector2 = point - diamond_points[idx]
		var cross: float = edge.cross(point_delta)
		if is_zero_approx(cross):
			continue
		var current_sign: int = 1 if cross > 0.0 else -1
		if direction_sign == 0:
			direction_sign = current_sign
		elif direction_sign != current_sign:
			return false
	return true

func get_cell_at_iso_visual_position(local_position: Vector2) -> Vector2i:
	if _grid_manager == null:
		return Vector2i(-1, -1)
	var map_width: int = _grid_manager.get_map_width()
	var map_height: int = _grid_manager.get_map_height()
	if map_width <= 0 or map_height <= 0:
		return Vector2i(-1, -1)
	var matched_cells: Array[Vector2i] = []
	for y in range(map_height):
		for x in range(map_width):
			var cell: Vector2i = Vector2i(x, y)
			var diamond_points: PackedVector2Array = get_iso_diamond_points(cell)
			if is_point_inside_iso_diamond(local_position, diamond_points):
				matched_cells.append(cell)
	if matched_cells.is_empty():
		return Vector2i(-1, -1)
	matched_cells.sort_custom(sort_cells_by_iso_depth)
	return matched_cells[matched_cells.size() - 1]

func set_iso_mouse_selection_visuals(selected_cell: Vector2i, route_cells: Array, action_cell: Vector2i = Vector2i(-1, -1)) -> void:
	selected_iso_cell = selected_cell
	selected_iso_route_cells.clear()
	for route_cell_variant in route_cells:
		if route_cell_variant is Vector2i:
			selected_iso_route_cells.append(route_cell_variant)
	selected_iso_action_cell = action_cell
	queue_redraw()

func clear_iso_mouse_selection_visuals() -> void:
	selected_iso_cell = Vector2i(-1, -1)
	selected_iso_route_cells.clear()
	selected_iso_action_cell = Vector2i(-1, -1)
	queue_redraw()

func set_map_constructor_preview_cell(cell: Vector2i) -> void:
	map_constructor_preview_cell = cell
	map_constructor_preview_attached_wall_cell = Vector2i(-1, -1)
	map_constructor_preview_wall_side = ""
	map_constructor_preview_is_blocked = false
	queue_redraw()

func set_map_constructor_wall_mounted_preview(anchor_cell: Vector2i, attached_wall_cell: Vector2i, wall_side: String, is_blocked: bool = false) -> void:
	map_constructor_preview_cell = anchor_cell
	map_constructor_preview_attached_wall_cell = attached_wall_cell
	map_constructor_preview_wall_side = wall_side
	map_constructor_preview_is_blocked = is_blocked
	queue_redraw()

func set_selected_wall_mounted_object(anchor_cell: Vector2i, attached_wall_cell: Vector2i, object_id: String) -> void:
	selected_wall_mounted_anchor_cell = anchor_cell
	selected_wall_mounted_attached_wall_cell = attached_wall_cell
	selected_wall_mounted_object_id = object_id
	queue_redraw()

func clear_selected_wall_mounted_object() -> void:
	selected_wall_mounted_anchor_cell = Vector2i(-1, -1)
	selected_wall_mounted_attached_wall_cell = Vector2i(-1, -1)
	selected_wall_mounted_object_id = ""
	queue_redraw()

func set_map_constructor_link_target(cell: Vector2i, object_id: String) -> void:
	map_constructor_link_target_cell = cell
	map_constructor_link_target_object_id = object_id
	queue_redraw()

func clear_map_constructor_link_target() -> void:
	map_constructor_link_target_cell = Vector2i(-1, -1)
	map_constructor_link_target_object_id = ""
	queue_redraw()

func draw_iso_mouse_selection_overlay() -> void:
	for route_cell in selected_iso_route_cells:
		var route_points: PackedVector2Array = get_iso_inset_diamond_points(route_cell, iso_floor_visual_inset + 10.0)
		if route_points.size() < 4:
			continue
		draw_colored_polygon(route_points, Color(0.29, 0.75, 0.95, 0.14))
		for edge_index in range(route_points.size()):
			var next_index: int = (edge_index + 1) % route_points.size()
			draw_line(route_points[edge_index], route_points[next_index], Color(0.29, 0.75, 0.95, 0.45), 1.6)

	if selected_iso_cell.x >= 0 and selected_iso_cell.y >= 0:
		var selected_points: PackedVector2Array = get_iso_inset_diamond_points(selected_iso_cell, iso_floor_visual_inset + 2.0)
		if selected_points.size() >= 4:
			draw_colored_polygon(selected_points, Color(0.85, 0.93, 1.0, 0.09))
			for edge_index in range(selected_points.size()):
				var next_index: int = (edge_index + 1) % selected_points.size()
				draw_line(selected_points[edge_index], selected_points[next_index], Color(0.8, 0.97, 1.0, 1.0), 2.6)

	if selected_iso_action_cell.x >= 0 and selected_iso_action_cell.y >= 0:
		var action_points: PackedVector2Array = get_iso_inset_diamond_points(selected_iso_action_cell, iso_floor_visual_inset + 6.0)
		if action_points.size() >= 4:
			draw_colored_polygon(action_points, Color(0.98, 0.66, 0.35, 0.24))
			for edge_index in range(action_points.size()):
				var next_index: int = (edge_index + 1) % action_points.size()
				draw_line(action_points[edge_index], action_points[next_index], Color(0.99, 0.75, 0.45, 1.0), 2.8)
	if selected_wall_mounted_anchor_cell.x >= 0 and selected_wall_mounted_anchor_cell.y >= 0:
		var anchor_points: PackedVector2Array = get_iso_inset_diamond_points(selected_wall_mounted_anchor_cell, iso_floor_visual_inset + 4.0)
		if anchor_points.size() >= 4:
			for edge_index in range(anchor_points.size()):
				var next_index: int = (edge_index + 1) % anchor_points.size()
				draw_line(anchor_points[edge_index], anchor_points[next_index], Color(0.35, 0.92, 1.0, 1.0), 2.8)
	if selected_wall_mounted_attached_wall_cell.x >= 0 and selected_wall_mounted_attached_wall_cell.y >= 0:
		var attached_points: PackedVector2Array = get_iso_inset_diamond_points(selected_wall_mounted_attached_wall_cell, iso_floor_visual_inset + 8.0)
		if attached_points.size() >= 4:
			for edge_index in range(attached_points.size()):
				var next_index: int = (edge_index + 1) % attached_points.size()
				draw_line(attached_points[edge_index], attached_points[next_index], Color(1.0, 0.8, 0.35, 1.0), 2.8)
	if not selected_wall_mounted_object_id.is_empty():
		var mission_manager: Node = get_mission_manager_ref()
		var obj: Dictionary = {}
		if mission_manager != null and mission_manager.has_method("get_world_object_at_cell"):
			obj = Dictionary(mission_manager.call("get_world_object_at_cell", selected_wall_mounted_anchor_cell))
		if String(obj.get("id", "")) == selected_wall_mounted_object_id:
			var center: Vector2 = get_object_visual_center(selected_wall_mounted_anchor_cell, obj)
			var r: float = 9.0
			var pts: PackedVector2Array = PackedVector2Array([center + Vector2(0, -r), center + Vector2(r, 0), center + Vector2(0, r), center + Vector2(-r, 0)])
			draw_polyline(pts, Color(1.0, 0.96, 0.3, 1.0), 2.8, true)
	if map_constructor_preview_cell.x >= 0 and map_constructor_preview_cell.y >= 0:
		var preview_points: PackedVector2Array = get_iso_inset_diamond_points(map_constructor_preview_cell, iso_floor_visual_inset + 3.0)
		if preview_points.size() >= 4:
			var floor_fill: Color = Color(0.35, 1.0, 0.45, 0.18)
			var floor_stroke: Color = Color(0.52, 1.0, 0.60, 1.0)
			if map_constructor_preview_is_blocked:
				floor_fill = Color(1.0, 0.35, 0.35, 0.18)
				floor_stroke = Color(1.0, 0.55, 0.55, 1.0)
			draw_colored_polygon(preview_points, floor_fill)
			for edge_index in range(preview_points.size()):
				var next_index: int = (edge_index + 1) % preview_points.size()
				draw_line(preview_points[edge_index], preview_points[next_index], floor_stroke, 2.2)
	if map_constructor_link_target_cell.x >= 0 and map_constructor_link_target_cell.y >= 0:
		var link_points: PackedVector2Array = get_iso_inset_diamond_points(map_constructor_link_target_cell, iso_floor_visual_inset + 11.0)
		if link_points.size() >= 4:
			draw_colored_polygon(link_points, Color(0.82, 0.28, 1.0, 0.12))
			for edge_index in range(link_points.size()):
				var next_index: int = (edge_index + 1) % link_points.size()
				draw_line(link_points[edge_index], link_points[next_index], Color(0.92, 0.46, 1.0, 1.0), 2.6)
		if not map_constructor_link_target_object_id.is_empty():
			var mission_manager_link: Node = get_mission_manager_ref()
			if mission_manager_link != null and mission_manager_link.has_method("get_world_object_at_cell"):
				var target_obj: Dictionary = Dictionary(mission_manager_link.call("get_world_object_at_cell", map_constructor_link_target_cell))
				if String(target_obj.get("id", "")) == map_constructor_link_target_object_id:
					var target_center: Vector2 = get_object_visual_center(map_constructor_link_target_cell, target_obj)
					draw_circle(target_center, 5.5, Color(0.95, 0.6, 1.0, 0.95))
					draw_arc(target_center, 10.0, 0.0, TAU, 20, Color(0.95, 0.6, 1.0, 1.0), 2.0)

	if map_constructor_preview_attached_wall_cell.x >= 0 and map_constructor_preview_attached_wall_cell.y >= 0:
		var wall_points: PackedVector2Array = get_iso_inset_diamond_points(map_constructor_preview_attached_wall_cell, iso_floor_visual_inset + 7.0)
		if wall_points.size() >= 4:
			draw_colored_polygon(wall_points, Color(0.45, 0.72, 1.0, 0.2))
			for edge_index in range(wall_points.size()):
				var next_index: int = (edge_index + 1) % wall_points.size()
				draw_line(wall_points[edge_index], wall_points[next_index], Color(0.62, 0.86, 1.0, 1.0), 2.0)


var map_constructor_overlay_prefs: Dictionary = {
	"show_preview": true,
	"show_validation": true,
	"show_links": true,
	"show_power": true,
	"show_wall_side_arrows": true,
	"show_multi_select": true
}
var map_constructor_overlay_data: Dictionary = {}

func set_map_constructor_overlay_preferences(prefs: Dictionary) -> void:
	for key_variant in prefs.keys():
		var key: String = String(key_variant)
		if map_constructor_overlay_prefs.has(key):
			map_constructor_overlay_prefs[key] = bool(prefs.get(key_variant, map_constructor_overlay_prefs[key]))
	queue_redraw()

func set_map_constructor_overlay_data(data: Dictionary) -> void:
	map_constructor_overlay_data = data.duplicate(true)
	queue_redraw()

func _draw_wall_side_arrow(cell: Vector2i, wall_side: String, color: Color) -> void:
	var center: Vector2 = grid_to_iso(cell)
	var dir: Vector2 = Vector2(0.0, -1.0)
	match wall_side:
		"north":
			dir = Vector2(0.0, -1.0)
		"east":
			dir = Vector2(1.0, 0.0)
		"south":
			dir = Vector2(0.0, 1.0)
		"west":
			dir = Vector2(-1.0, 0.0)
		_:
			dir = Vector2(0.0, -1.0)
	var tip: Vector2 = center + dir * 16.0
	draw_line(center, tip, color, 2.0)
	draw_circle(tip, 3.0, color)

func draw_map_constructor_visual_overlay_passes() -> void:
	var selected: Dictionary = Dictionary(map_constructor_overlay_data.get("selected", {}))
	var hover: Dictionary = Dictionary(map_constructor_overlay_data.get("hover", {}))
	var preview: Dictionary = Dictionary(map_constructor_overlay_data.get("preview", {}))
	var issues: Array = Array(map_constructor_overlay_data.get("validation", []))
	var links: Array = Array(map_constructor_overlay_data.get("links", []))
	var power: Array = Array(map_constructor_overlay_data.get("power", []))
	var multi_select: Array = Array(map_constructor_overlay_data.get("multi_select", []))
	var room_visual_preview: Dictionary = Dictionary(map_constructor_overlay_data.get("room_visual_preview", {}))
	if selected.has("cell"):
		var selected_cell: Vector2i = Vector2i(selected.get("cell", Vector2i(-1, -1)))
		if selected_cell.x >= 0 and selected_cell.y >= 0:
			var selected_poly: PackedVector2Array = get_iso_inset_diamond_points(selected_cell, iso_floor_visual_inset + 1.5)
			if selected_poly.size() >= 4:
				draw_colored_polygon(selected_poly, Color(1.0, 0.92, 0.24, 0.11))
				for selected_edge_index in range(selected_poly.size()):
					var selected_next_index: int = (selected_edge_index + 1) % selected_poly.size()
					draw_line(selected_poly[selected_edge_index], selected_poly[selected_next_index], Color(1.0, 0.92, 0.24, 0.95), 2.4)
	if hover.has("cell"):
		var hover_cell: Vector2i = Vector2i(hover.get("cell", Vector2i(-1, -1)))
		if hover_cell.x >= 0 and hover_cell.y >= 0:
			var hover_poly: PackedVector2Array = get_iso_inset_diamond_points(hover_cell, iso_floor_visual_inset + 6.0)
			for hover_edge_index in range(hover_poly.size()):
				var hover_next_index: int = (hover_edge_index + 1) % hover_poly.size()
				draw_line(hover_poly[hover_edge_index], hover_poly[hover_next_index], Color(0.72, 0.92, 1.0, 0.45), 1.2)
	if bool(map_constructor_overlay_prefs.get("show_preview", true)):
		var destructive: bool = String(preview.get("mode", "")) == "destructive"
		var preview_blocked: bool = map_constructor_preview_is_blocked
		if map_constructor_preview_cell.x >= 0 and map_constructor_preview_cell.y >= 0:
			var p: PackedVector2Array = get_iso_inset_diamond_points(map_constructor_preview_cell, iso_floor_visual_inset + 3.0)
			if p.size() >= 4:
				var c: Color = Color(0.35, 1.0, 0.85, 0.16)
				var s: Color = Color(0.45, 1.0, 0.92, 1.0)
				if preview_blocked:
					c = Color(1.0, 0.35, 0.25, 0.2)
					s = Color(1.0, 0.55, 0.3, 1.0)
				elif destructive:
					c = Color(1.0, 0.62, 0.22, 0.17)
					s = Color(1.0, 0.7, 0.3, 1.0)
				draw_colored_polygon(p, c)
				for edge_index in range(p.size()):
					var next_index: int = (edge_index + 1) % p.size()
					draw_line(p[edge_index], p[next_index], s, 2.2)
	if bool(map_constructor_overlay_prefs.get("show_preview", true)):
		for wall_row_variant in Array(room_visual_preview.get("walls", [])):
			var wall_row: Dictionary = Dictionary(wall_row_variant)
			var wall_cell: Vector2i = Vector2i(wall_row.get("cell", Vector2i(-1, -1)))
			if wall_cell.x < 0 or wall_cell.y < 0:
				continue
			var wall_poly: PackedVector2Array = get_iso_inset_diamond_points(wall_cell, iso_floor_visual_inset + 12.0)
			for wall_edge_index in range(wall_poly.size()):
				var wall_next_index: int = (wall_edge_index + 1) % wall_poly.size()
				draw_line(wall_poly[wall_edge_index], wall_poly[wall_next_index], Color(0.95, 0.74, 0.28, 0.42), 1.5)
			var wall_center: Vector2 = grid_to_iso(wall_cell)
			draw_circle(wall_center + Vector2(0.0, -8.0), 2.1, Color(0.45, 0.9, 1.0, 0.76))
		for door_row_variant in Array(room_visual_preview.get("doors", [])):
			var door_row: Dictionary = Dictionary(door_row_variant)
			var door_cell: Vector2i = Vector2i(door_row.get("cell", Vector2i(-1, -1)))
			if door_cell.x < 0 or door_cell.y < 0:
				continue
			draw_circle(grid_to_iso(door_cell) + Vector2(-5.0, -9.0), 2.8, Color(1.0, 0.76, 0.28, 0.88))
		for terminal_row_variant in Array(room_visual_preview.get("terminals", [])):
			var terminal_row: Dictionary = Dictionary(terminal_row_variant)
			var terminal_cell: Vector2i = Vector2i(terminal_row.get("cell", Vector2i(-1, -1)))
			if terminal_cell.x < 0 or terminal_cell.y < 0:
				continue
			draw_circle(grid_to_iso(terminal_cell) + Vector2(5.0, -9.0), 2.8, Color(0.44, 0.9, 1.0, 0.88))
		for floor_row_variant in Array(room_visual_preview.get("floors", [])):
			var floor_row: Dictionary = Dictionary(floor_row_variant)
			var floor_cell: Vector2i = Vector2i(floor_row.get("cell", Vector2i(-1, -1)))
			if floor_cell.x < 0 or floor_cell.y < 0:
				continue
			var floor_poly: PackedVector2Array = get_iso_inset_diamond_points(floor_cell, iso_floor_visual_inset + 5.0)
			for floor_edge_index in range(floor_poly.size()):
				var floor_next_index: int = (floor_edge_index + 1) % floor_poly.size()
				draw_line(floor_poly[floor_edge_index], floor_poly[floor_next_index], Color(0.56, 0.78, 0.96, 0.48), 1.15)
	if bool(map_constructor_overlay_prefs.get("show_multi_select", true)):
		for row_variant in multi_select:
			var row: Dictionary = Dictionary(row_variant)
			var cell: Vector2i = Vector2i(row.get("cell", Vector2i(-1, -1)))
			if cell.x < 0 or cell.y < 0:
				continue
			var mp: PackedVector2Array = get_iso_inset_diamond_points(cell, iso_floor_visual_inset + 10.0)
			for edge_index in range(mp.size()):
				var next_index: int = (edge_index + 1) % mp.size()
				draw_line(mp[edge_index], mp[next_index], Color(0.75, 0.85, 1.0, 0.8), 1.4)
	if bool(map_constructor_overlay_prefs.get("show_validation", true)):
		for issue_variant in issues:
			var issue: Dictionary = Dictionary(issue_variant)
			var cell: Vector2i = Vector2i(issue.get("cell", Vector2i(-1, -1)))
			if cell.x < 0 or cell.y < 0:
				continue
			var sev: String = String(issue.get("severity", "info"))
			var expected_invalid: bool = bool(issue.get("expected_invalid", false)) or sev.to_lower() == "expected_invalid"
			var mc: Color = Color(0.62, 0.8, 1.0, 0.95)
			if expected_invalid:
				mc = Color(0.74, 0.66, 0.86, 0.95)
			elif sev == "error":
				mc = Color(1.0, 0.3, 0.3, 0.95)
			elif sev == "warning":
				mc = Color(1.0, 0.74, 0.3, 0.95)
			draw_circle(grid_to_iso(cell), 6.0, mc)
	if bool(map_constructor_overlay_prefs.get("show_links", true)):
		for link_variant in links:
			var link: Dictionary = Dictionary(link_variant)
			var from_cell: Vector2i = Vector2i(link.get("from_cell", Vector2i(-1, -1)))
			var to_cell: Vector2i = Vector2i(link.get("to_cell", Vector2i(-1, -1)))
			if from_cell.x < 0 or to_cell.x < 0:
				continue
			var lc: Color = Color(0.9, 0.58, 1.0, 0.85)
			if bool(link.get("broken", false)):
				lc = Color(1.0, 0.3, 0.3, 0.9)
			draw_line(grid_to_iso(from_cell), grid_to_iso(to_cell), lc, 1.8)
	if bool(map_constructor_overlay_prefs.get("show_power", true)):
		for prow_variant in power:
			var prow: Dictionary = Dictionary(prow_variant)
			var f: Vector2i = Vector2i(prow.get("from_cell", Vector2i(-1, -1)))
			var t: Vector2i = Vector2i(prow.get("to_cell", Vector2i(-1, -1)))
			if f.x < 0 or t.x < 0:
				continue
			draw_line(grid_to_iso(f), grid_to_iso(t), Color(0.45, 0.9, 1.0, 0.65), 1.2)
	if bool(map_constructor_overlay_prefs.get("show_wall_side_arrows", true)):
		if String(preview.get("wall_side", "")) != "" and map_constructor_preview_cell.x >= 0:
			_draw_wall_side_arrow(map_constructor_preview_cell, String(preview.get("wall_side", "")), Color(0.82, 0.95, 1.0, 1.0))
		if String(selected.get("wall_side", "")) != "":
			_draw_wall_side_arrow(Vector2i(selected.get("cell", Vector2i(-1, -1))), String(selected.get("wall_side", "")), Color(1.0, 0.88, 0.35, 1.0))
const ISO_LAYER_BIAS_FLOOR: float = 0.0
const ISO_LAYER_BIAS_ITEM: float = 0.1
const ISO_LAYER_BIAS_DOOR: float = 0.2
const ISO_LAYER_BIAS_WALL: float = 0.4
const ISO_LAYER_BIAS_WALL_MOUNTED: float = 0.55
const ISO_LAYER_BIAS_TERMINAL: float = 0.6
const ISO_LAYER_BIAS_ACTOR: float = 0.8
const ISO_LAYER_BIAS_OVERLAY: float = 1.0

func get_iso_depth_key(cell: Vector2i, layer_bias: float = 0.0) -> float:
	return float(cell.x + cell.y) + layer_bias

func sort_iso_draw_entries(a: Dictionary, b: Dictionary) -> bool:
	var cell_a: Vector2i = Vector2i(a.get("cell", Vector2i.ZERO))
	var cell_b: Vector2i = Vector2i(b.get("cell", Vector2i.ZERO))
	var bias_a: float = float(a.get("layer_bias", 0.0))
	var bias_b: float = float(b.get("layer_bias", 0.0))
	var depth_a: float = get_iso_depth_key(cell_a, bias_a)
	var depth_b: float = get_iso_depth_key(cell_b, bias_b)
	if is_equal_approx(depth_a, depth_b):
		if cell_a.y == cell_b.y:
			return cell_a.x < cell_b.x
		return cell_a.y < cell_b.y
	return depth_a < depth_b

func sort_cells_by_iso_depth(a: Vector2i, b: Vector2i) -> bool:
	var depth_a: float = get_iso_depth_key(a)
	var depth_b: float = get_iso_depth_key(b)
	if depth_a == depth_b:
		if a.y == b.y:
			return a.x < b.x
		return a.y < b.y
	return depth_a < depth_b

func is_floor_like_tile(tile_type: int) -> bool:
	return tile_type != GridManager.TILE_WALL

func is_wall_tile(tile_type: int) -> bool:
	return tile_type == GridManager.TILE_WALL

func is_door_like_tile(tile_type: int) -> bool:
	if tile_type == GridManager.TILE_DOOR:
		return true
	if tile_type == GridManager.TILE_DIGITAL_DOOR:
		return true
	if tile_type == GridManager.TILE_POWERED_GATE:
		return true
	return false

func _get_door_opening_polygon(center: Vector2, orientation: String, half_length: float, half_depth: float) -> PackedVector2Array:
	if orientation == "axis_y":
		return PackedVector2Array([
			center + Vector2(-half_depth, -half_length * 0.5),
			center + Vector2(half_length, -half_depth),
			center + Vector2(half_depth, half_length * 0.5),
			center + Vector2(-half_length, half_depth)
		])
	return PackedVector2Array([
		center + Vector2(-half_length, -half_depth),
		center + Vector2(half_depth, -half_length * 0.5),
		center + Vector2(half_length, half_depth),
		center + Vector2(-half_depth, half_length * 0.5)
	])

func get_door_opening_context(cell: Vector2i) -> Dictionary:
	var empty_context: Dictionary = {
		"ok": false,
		"cell": cell,
		"tile_type": -1,
		"orientation": "unknown",
		"adjacent_wall_cells": [],
		"adjacent_floor_cells": [],
		"left_jamb_cell": Vector2i(-1, -1),
		"right_jamb_cell": Vector2i(-1, -1),
		"has_wall_support": false,
		"opening_center": grid_to_iso(cell),
		"door_insert_center": grid_to_iso(cell) + Vector2(0.0, -iso_wall_height * 0.42),
		"door_frame_polygon": PackedVector2Array(),
		"threshold_polygon": PackedVector2Array()
	}
	if _grid_manager == null:
		return empty_context
	if not is_cell_in_bounds(cell):
		return empty_context
	var tile_type: int = _grid_manager.get_tile(cell)
	if not is_door_like_tile(tile_type):
		return empty_context
	var adjacent_wall_cells: Array[Vector2i] = []
	var adjacent_floor_cells: Array[Vector2i] = []
	var east_cell: Vector2i = cell + Vector2i(1, 0)
	var west_cell: Vector2i = cell + Vector2i(-1, 0)
	var north_cell: Vector2i = cell + Vector2i(0, -1)
	var south_cell: Vector2i = cell + Vector2i(0, 1)
	var neighbor_cells: Array[Vector2i] = [east_cell, west_cell, north_cell, south_cell]
	for neighbor_cell in neighbor_cells:
		if not is_cell_in_bounds(neighbor_cell):
			continue
		var neighbor_tile: int = _grid_manager.get_tile(neighbor_cell)
		if is_wall_tile(neighbor_tile):
			adjacent_wall_cells.append(neighbor_cell)
		else:
			adjacent_floor_cells.append(neighbor_cell)
	var has_east_wall: bool = is_cell_in_bounds(east_cell) and is_wall_tile(_grid_manager.get_tile(east_cell))
	var has_west_wall: bool = is_cell_in_bounds(west_cell) and is_wall_tile(_grid_manager.get_tile(west_cell))
	var has_north_wall: bool = is_cell_in_bounds(north_cell) and is_wall_tile(_grid_manager.get_tile(north_cell))
	var has_south_wall: bool = is_cell_in_bounds(south_cell) and is_wall_tile(_grid_manager.get_tile(south_cell))
	var axis_x_support: int = (1 if has_east_wall else 0) + (1 if has_west_wall else 0)
	var axis_y_support: int = (1 if has_north_wall else 0) + (1 if has_south_wall else 0)
	var orientation: String = "unknown"
	if axis_x_support > axis_y_support:
		orientation = "axis_x"
	elif axis_y_support > axis_x_support:
		orientation = "axis_y"
	elif axis_x_support > 0 and axis_y_support > 0:
		orientation = "axis_x"
	elif axis_x_support > 0:
		orientation = "axis_x"
	elif axis_y_support > 0:
		orientation = "axis_y"
	var left_jamb_cell: Vector2i = Vector2i(-1, -1)
	var right_jamb_cell: Vector2i = Vector2i(-1, -1)
	if orientation == "axis_y":
		left_jamb_cell = north_cell
		right_jamb_cell = south_cell
	else:
		left_jamb_cell = west_cell
		right_jamb_cell = east_cell
	var opening_center: Vector2 = grid_to_iso(cell) + Vector2(0.0, -iso_wall_height * 0.28)
	var door_insert_center: Vector2 = grid_to_iso(cell) + Vector2(0.0, -iso_wall_height * 0.46)
	var door_frame_polygon: PackedVector2Array = _get_door_opening_polygon(door_insert_center, orientation, get_iso_tile_half_size().x * 0.34, iso_wall_height * 0.34)
	var threshold_polygon: PackedVector2Array = _get_door_opening_polygon(grid_to_iso(cell) + Vector2(0.0, -2.0), orientation, get_iso_tile_half_size().x * 0.42, get_iso_tile_half_size().y * 0.2)
	return {
		"ok": true,
		"cell": cell,
		"tile_type": tile_type,
		"orientation": orientation,
		"adjacent_wall_cells": adjacent_wall_cells,
		"adjacent_floor_cells": adjacent_floor_cells,
		"left_jamb_cell": left_jamb_cell,
		"right_jamb_cell": right_jamb_cell,
		"has_wall_support": adjacent_wall_cells.size() > 0,
		"opening_center": opening_center,
		"door_insert_center": door_insert_center,
		"door_frame_polygon": door_frame_polygon,
		"threshold_polygon": threshold_polygon
	}

func should_skip_full_wall_for_door_opening(cell: Vector2i) -> bool:
	if _grid_manager == null:
		return false
	if not is_cell_in_bounds(cell):
		return false
	return is_door_like_tile(_grid_manager.get_tile(cell))

func _get_door_kind_for_tile(tile_type: int) -> String:
	if tile_type == GridManager.TILE_DIGITAL_DOOR:
		return "digital_door"
	if tile_type == GridManager.TILE_POWERED_GATE:
		return "powered_gate"
	return "mechanical_door"

func get_iso_door_opening_visual_profile(cell: Vector2i, object_data: Dictionary = {}) -> Dictionary:
	var tile_type: int = GridManager.TILE_DOOR
	if _grid_manager != null and is_cell_in_bounds(cell):
		tile_type = _grid_manager.get_tile(cell)
	var door_kind: String = _get_door_kind_for_tile(tile_type)
	var door_state: String = String(object_data.get("state", object_data.get("visual_state", "closed"))).to_lower().strip_edges()
	var object_id: String = String(object_data.get("id", object_data.get("object_id", ""))).strip_edges()
	var mission_manager: Node = get_mission_manager_ref()
	if not object_id.is_empty() and mission_manager != null and mission_manager.has_method("get_map_constructor_door_visual_state"):
		var resolved_state: Dictionary = Dictionary(mission_manager.call("get_map_constructor_door_visual_state", object_id))
		if bool(resolved_state.get("ok", false)):
			door_state = String(resolved_state.get("state", door_state)).to_lower().strip_edges()
	if bool(object_data.get("is_open", object_data.get("open", false))):
		door_state = "open"
	if bool(object_data.get("is_locked", object_data.get("locked", false))):
		door_state = "locked"
	if bool(object_data.get("damaged", object_data.get("broken", false))):
		door_state = "damaged"
	if door_state == "broken" or door_state == "jammed" or door_state == "destroyed":
		door_state = "damaged"
	if door_state.is_empty() or not (door_state in ["open", "closed", "locked", "powered", "unpowered", "damaged"]):
		door_state = "closed"
	var base_color: Color = Color(0.27, 0.24, 0.22, 0.96)
	var frame_color: Color = Color(0.12, 0.14, 0.16, 0.98)
	var accent_color: Color = Color(0.88, 0.72, 0.36, 0.98)
	var warning_color: Color = Color(1.0, 0.3, 0.22, 0.98)
	var threshold_color: Color = Color(0.16, 0.18, 0.2, 0.82)
	var alpha: float = 0.96
	if door_kind == "digital_door":
		base_color = Color(0.13, 0.2, 0.28, 0.96)
		accent_color = Color(0.38, 0.88, 1.0, 0.98)
	elif door_kind == "powered_gate":
		base_color = Color(0.09, 0.14, 0.2, 0.9)
		accent_color = Color(0.48, 0.96, 1.0, 0.98)
	if door_state == "open":
		alpha = 0.38
		base_color = base_color.darkened(0.18)
		accent_color = Color(0.58, 0.9, 0.98, 0.92)
	elif door_state == "locked":
		accent_color = Color(1.0, 0.72, 0.22, 0.99)
		warning_color = Color(1.0, 0.86, 0.24, 0.99)
	elif door_state == "powered":
		accent_color = Color(0.32, 0.92, 1.0, 0.99)
	elif door_state == "unpowered":
		base_color = Color(0.18, 0.19, 0.21, 0.86)
		accent_color = Color(0.48, 0.54, 0.58, 0.86)
		alpha = 0.72
	elif door_state == "damaged":
		accent_color = Color(1.0, 0.34, 0.22, 0.99)
		warning_color = Color(1.0, 0.18, 0.12, 0.99)
	return {
		"door_state": door_state,
		"door_kind": door_kind,
		"base_color": base_color,
		"frame_color": frame_color,
		"accent_color": accent_color,
		"warning_color": warning_color,
		"threshold_color": threshold_color,
		"alpha": alpha,
		"frame_enabled": true,
		"threshold_enabled": true,
		"state_badge_enabled": door_state != "closed",
		"damage_overlay_enabled": door_state == "damaged"
	}

func get_floor_prototype_color(tile_type: int, cell: Vector2i) -> Color:
	# Procedural prototype floor colors for dark industrial sci-fi paneling.
	# Final assets / TileSet-driven rendering will replace this in future PRs.
	var base_color: Color = Color(0.115, 0.125, 0.145, 0.96)
	var parity: int = (cell.x + cell.y) % 2
	if parity != 0:
		base_color = Color(0.135, 0.145, 0.165, 0.96)

	if tile_type == GridManager.TILE_TERMINAL or tile_type == GridManager.TILE_AIRFLOW_TERMINAL:
		base_color = base_color.lerp(Color(0.16, 0.23, 0.29, 0.98), 0.35)
	elif tile_type == GridManager.TILE_EXIT:
		base_color = base_color.lerp(Color(0.14, 0.24, 0.2, 0.98), 0.4)
	elif tile_type == GridManager.TILE_DIGITAL_DOOR or tile_type == GridManager.TILE_POWERED_GATE:
		base_color = base_color.lerp(Color(0.14, 0.2, 0.27, 0.98), 0.3)
	elif tile_type == GridManager.TILE_DOOR:
		base_color = base_color.lerp(Color(0.2, 0.17, 0.13, 0.98), 0.22)
	elif tile_type == GridManager.TILE_HOT_NODE:
		base_color = base_color.lerp(Color(0.23, 0.16, 0.15, 0.98), 0.25)

	return base_color



func is_walkable_floor_like_for_iso_passage(tile_type: int) -> bool:
	if tile_type == GridManager.TILE_FLOOR or tile_type == GridManager.TILE_STEPPED_FLOOR:
		return true
	return false

func is_cell_in_bounds(cell: Vector2i) -> bool:
	if _grid_manager == null:
		return false
	return _grid_manager.is_in_bounds(cell)

func is_iso_interactive_floor_tile(tile_type: int) -> bool:
	if tile_type == GridManager.TILE_TERMINAL:
		return true
	if tile_type == GridManager.TILE_AIRFLOW_TERMINAL:
		return true
	if tile_type == GridManager.TILE_PLATFORM_CONTROL:
		return true
	if tile_type == GridManager.TILE_PLATFORM_CONTROL_LEFT:
		return true
	if tile_type == GridManager.TILE_PLATFORM_CONTROL_RIGHT:
		return true
	if tile_type == GridManager.TILE_FAN_CONTROL:
		return true
	if tile_type == GridManager.TILE_FAN_SPEED_UP_CONTROL:
		return true
	if tile_type == GridManager.TILE_FAN_SPEED_DOWN_CONTROL:
		return true
	if tile_type == GridManager.TILE_SOCKET:
		return true
	if tile_type == GridManager.TILE_CABLE_REEL:
		return true
	if tile_type == GridManager.TILE_CABLE:
		return true
	return false

func is_iso_passage_floor_cell(cell: Vector2i) -> bool:
	if _grid_manager == null:
		return false
	if not is_cell_in_bounds(cell):
		return false
	var tile_type: int = _grid_manager.get_tile(cell)
	if not is_walkable_floor_like_for_iso_passage(tile_type):
		return false

	var north: Vector2i = cell + Vector2i(0, -1)
	var south: Vector2i = cell + Vector2i(0, 1)
	var west: Vector2i = cell + Vector2i(-1, 0)
	var east: Vector2i = cell + Vector2i(1, 0)
	var neighbor_cells: Array[Vector2i] = [north, south, west, east]
	var wall_neighbor_count: int = 0
	for neighbor_cell in neighbor_cells:
		if not is_cell_in_bounds(neighbor_cell):
			wall_neighbor_count += 1
		elif _grid_manager.get_tile(neighbor_cell) == GridManager.TILE_WALL:
			wall_neighbor_count += 1

	var opposite_walls: bool = false
	if (not is_cell_in_bounds(north) or _grid_manager.get_tile(north) == GridManager.TILE_WALL) and (not is_cell_in_bounds(south) or _grid_manager.get_tile(south) == GridManager.TILE_WALL):
		opposite_walls = true
	if (not is_cell_in_bounds(west) or _grid_manager.get_tile(west) == GridManager.TILE_WALL) and (not is_cell_in_bounds(east) or _grid_manager.get_tile(east) == GridManager.TILE_WALL):
		opposite_walls = true

	return opposite_walls or wall_neighbor_count >= 2

func get_iso_floor_visual_profile_key_for_cell(cell: Vector2i) -> String:
	if _grid_manager == null:
		return "floor_default"
	if not is_cell_in_bounds(cell):
		return "floor_default"
	var tile_type: int = _grid_manager.get_tile(cell)
	if tile_type == GridManager.TILE_WALL:
		return "floor_wall_base"
	if tile_type == GridManager.TILE_DOOR or tile_type == GridManager.TILE_DIGITAL_DOOR or tile_type == GridManager.TILE_POWERED_GATE:
		return "floor_doorway"
	if is_iso_interactive_floor_tile(tile_type):
		return "floor_interactive"
	if tile_type == GridManager.TILE_EXIT:
		return "floor_exit"
	if is_iso_passage_floor_cell(cell):
		return "floor_passage"
	return "floor_default"

func get_iso_floor_material_family_for_cell(cell: Vector2i) -> String:
	if _grid_manager == null or not is_cell_in_bounds(cell):
		return "none"
	var tile_type: int = _grid_manager.get_tile(cell)
	if not is_floor_like_tile(tile_type):
		return "none"
	var profile_key: String = get_iso_floor_visual_profile_key_for_cell(cell)
	if profile_key == "floor_doorway":
		return "doorway"
	if profile_key == "floor_wall_base":
		return "wall_base"
	return "connected_floor"

func should_draw_floor_cell_border(cell: Vector2i) -> bool:
	# Visual-only seam policy. Interior same-family floor cells suppress their
	# strong diamond border so rooms read as one continuous surface. Boundary,
	# wall, and doorway threshold edges retain local definition.
	if _grid_manager == null or not is_cell_in_bounds(cell):
		return false
	var tile_type: int = _grid_manager.get_tile(cell)
	if not is_floor_like_tile(tile_type):
		return false
	var family: String = get_iso_floor_material_family_for_cell(cell)
	for side in WALL_SIDE_ORDER:
		var neighbor: Vector2i = cell + _get_wall_side_delta(side)
		if not is_cell_in_bounds(neighbor):
			return true
		var neighbor_tile: int = _grid_manager.get_tile(neighbor)
		if not is_floor_like_tile(neighbor_tile):
			return true
		var neighbor_family: String = get_iso_floor_material_family_for_cell(neighbor)
		if neighbor_family != family:
			return true
	return false

func should_draw_floor_edge_border(cell: Vector2i, side: String) -> bool:
	if _grid_manager == null or not is_cell_in_bounds(cell):
		return false
	var tile_type: int = _grid_manager.get_tile(cell)
	if not is_floor_like_tile(tile_type):
		return false
	var neighbor: Vector2i = cell + _get_wall_side_delta(side)
	if not is_cell_in_bounds(neighbor):
		return true
	var neighbor_tile: int = _grid_manager.get_tile(neighbor)
	if not is_floor_like_tile(neighbor_tile):
		return true
	var family: String = get_iso_floor_material_family_for_cell(cell)
	var neighbor_family: String = get_iso_floor_material_family_for_cell(neighbor)
	return neighbor_family != family

func get_iso_diamond_edge_points(points: PackedVector2Array, side: String) -> Array[Vector2]:
	var edge_points: Array[Vector2] = []
	if points.size() < 4:
		return edge_points
	match side:
		"north":
			edge_points.append(points[3])
			edge_points.append(points[0])
		"east":
			edge_points.append(points[0])
			edge_points.append(points[1])
		"south":
			edge_points.append(points[1])
			edge_points.append(points[2])
		"west":
			edge_points.append(points[2])
			edge_points.append(points[3])
	return edge_points

func get_iso_floor_visual_profile(profile_key: String) -> Dictionary:
	var profiles: Dictionary = {
		"floor_default": {"fill": Color(0.115, 0.125, 0.145, 0.96), "outline": Color(0.2, 0.28, 0.34, 0.78), "panel": Color(0.16, 0.19, 0.22, 0.4), "seam": Color(0.34, 0.39, 0.44, 0.28)},
		"floor_passage": {"fill": Color(0.125, 0.14, 0.162, 0.97), "outline": Color(0.28, 0.4, 0.47, 0.9), "panel": Color(0.19, 0.24, 0.29, 0.48), "seam": Color(0.58, 0.72, 0.8, 0.45)},
		"floor_doorway": {"fill": Color(0.14, 0.15, 0.165, 0.97), "outline": Color(0.34, 0.35, 0.4, 0.88), "panel": Color(0.22, 0.24, 0.28, 0.52), "seam": Color(0.84, 0.7, 0.42, 0.5)},
		"floor_interactive": {"fill": Color(0.12, 0.145, 0.165, 0.97), "outline": Color(0.26, 0.41, 0.47, 0.88), "panel": Color(0.19, 0.26, 0.3, 0.48), "seam": Color(0.46, 0.82, 0.9, 0.42)},
		"floor_exit": {"fill": Color(0.12, 0.15, 0.14, 0.97), "outline": Color(0.24, 0.44, 0.32, 0.88), "panel": Color(0.17, 0.24, 0.2, 0.5), "seam": Color(0.54, 0.86, 0.62, 0.45)},
		"floor_wall_base": {"fill": Color(0.08, 0.09, 0.11, 0.98), "outline": Color(0.14, 0.17, 0.2, 0.72), "panel": Color(0.1, 0.12, 0.14, 0.35), "seam": Color(0.2, 0.23, 0.27, 0.2)}
	}
	if profiles.has(profile_key):
		return Dictionary(profiles.get(profile_key, {}))
	return Dictionary(profiles.get("floor_default", {}))

func get_iso_door_visual_profile_key_for_tile(tile_type: int) -> String:
	if tile_type == GridManager.TILE_DOOR:
		return "door_mechanical"
	if tile_type == GridManager.TILE_DIGITAL_DOOR:
		return "door_digital"
	if tile_type == GridManager.TILE_POWERED_GATE:
		return "door_powered_gate"
	return ""

func get_iso_floor_asset_key_for_tile(tile_type: int) -> String:
	if tile_type == GridManager.TILE_WALL:
		return ""
	if tile_type == GridManager.TILE_STEPPED_FLOOR:
		return "floor_stepped"
	if tile_type == GridManager.TILE_DOOR or tile_type == GridManager.TILE_DIGITAL_DOOR or tile_type == GridManager.TILE_POWERED_GATE:
		return "floor_door_underlay"
	if tile_type == GridManager.TILE_FLOOR or is_floor_like_tile(tile_type):
		return "floor_default"
	return ""

func get_iso_wall_asset_key_for_profile(profile_key: String) -> String:
	match profile_key:
		"outer_wall":
			return "wall_outer"
		"grate_wall":
			return "wall_grate"
		"brick_wall":
			return "wall_brick"
		"concrete_wall":
			return "wall_concrete"
		"steel_wall", "reinforced_steel_wall", "titanium_wall":
			return "wall_steel"
		"energy_wall":
			return "wall_energy"
		"damaged_wall":
			return "wall_damaged"
		_:
			return "wall_default"

func get_iso_object_asset_key_for_profile(profile_key: String) -> String:
	match profile_key:
		"door", "digital_door", "powered_gate":
			return "object_door"
		"terminal", "airflow_terminal":
			return "object_terminal"
		"key":
			return "object_key"
		"keycard", "digital_key":
			return "object_keycard"
		"fuse", "fuse_box":
			return "object_fuse"
		"repair_kit":
			return "object_repair_kit"
		"access_code", "datafile":
			return "object_access_code"
		"component":
			return "object_component"
		"socket":
			return "object_socket"
		"cable":
			return "object_cable"
		"cable_reel":
			return "object_cable_reel"
		"button", "platform_control", "fan_control", "fan_speed_control":
			return "object_button"
		"switch", "breaker", "circuit_breaker":
			return "object_switch"
		_:
			return "object_generic"

func get_iso_object_profile_key_for_object_data(object_data: Dictionary, fallback_profile_key: String = "generic_object") -> String:
	var type_value: String = String(object_data.get("object_type", object_data.get("item_type", object_data.get("type", "")))).to_lower().strip_edges()
	var prefab_value: String = String(object_data.get("map_constructor_prefab_id", "")).to_lower().strip_edges()
	var key_kind: String = String(object_data.get("key_kind", object_data.get("key_type", ""))).to_lower().strip_edges()
	var blob: String = "%s %s %s" % [type_value, prefab_value, key_kind]
	if blob.contains("digital_key") or blob.contains("keycard"):
		return "keycard"
	if blob.contains("key"):
		return "key"
	if blob.contains("fuse"):
		return "fuse"
	if blob.contains("repair_kit"):
		return "repair_kit"
	if blob.contains("access_code") or blob.contains("code"):
		return "access_code"
	if blob.contains("power_cable") or blob.contains("cable") or blob.contains("wire"):
		return "cable"
	if blob.contains("power_source"):
		return "power_source"
	if blob.contains("circuit_switch") or blob.contains("light_switch") or blob.contains("breaker") or blob.contains("switch"):
		return "switch"
	if blob.contains("door") or blob.contains("powered_gate"):
		return "door"
	if blob.contains("terminal"):
		return "terminal"
	if blob.contains("barrel"):
		return "barrel"
	if blob.contains("crate") or blob.contains("box"):
		return "crate"
	if fallback_profile_key.strip_edges().is_empty():
		return "generic_object"
	return fallback_profile_key

func get_iso_object_asset_key_for_object_data(object_data: Dictionary, fallback_profile_key: String) -> String:
	var fallback_asset_key: String = get_iso_object_asset_key_for_profile(fallback_profile_key)
	var type_value: String = String(object_data.get("object_type", object_data.get("type", ""))).to_lower().strip_edges()
	var group_value: String = String(object_data.get("group", "")).to_lower().strip_edges()
	var name_value: String = String(object_data.get("name", "")).to_lower().strip_edges()
	var id_value: String = String(object_data.get("id", object_data.get("object_id", ""))).to_lower().strip_edges()
	var blob: String = "%s %s %s %s %s" % [fallback_profile_key.to_lower(), type_value, group_value, name_value, id_value]
	if blob.contains("door") or blob.contains("powered_gate"):
		return "object_door"
	if blob.contains("terminal") or blob.contains("console") or blob.contains("control_panel"):
		return "object_terminal"
	if blob.contains("keycard") or blob.contains("digital_key"):
		return "object_keycard"
	if blob.contains("key"):
		return "object_key"
	if blob.contains("fuse"):
		return "object_fuse"
	if blob.contains("repair_kit") or blob.contains("repair kit"):
		return "object_repair_kit"
	if blob.contains("access_code") or blob.contains("access code"):
		return "object_access_code"
	if blob.contains("component"):
		return "object_component"
	if blob.contains("socket"):
		return "object_socket"
	if blob.contains("cable_reel") or blob.contains("cable reel"):
		return "object_cable_reel"
	if blob.contains("cable"):
		return "object_cable"
	if blob.contains("button"):
		return "object_button"
	if blob.contains("switch") or blob.contains("breaker"):
		return "object_switch"
	if fallback_asset_key.is_empty():
		return "object_generic"
	return fallback_asset_key

func get_iso_placeholder_asset_path(asset_key: String) -> String:
	if asset_key == "":
		return ""
	if not ISO_PLACEHOLDER_ASSET_PATHS.has(asset_key):
		return ""
	var placeholder_path: String = str(ISO_PLACEHOLDER_ASSET_PATHS.get(asset_key, ""))
	return placeholder_path

func get_iso_placeholder_texture_for_asset_key(asset_key: String) -> Texture2D:
	if not should_use_iso_placeholder_asset_preset():
		return null
	var placeholder_path: String = get_iso_placeholder_asset_path(asset_key)
	if placeholder_path == "":
		return null

	if _iso_placeholder_texture_cache.has(asset_key):
		var cached_value: Variant = _iso_placeholder_texture_cache.get(asset_key)
		if cached_value is Texture2D:
			return cached_value as Texture2D
		return null

	var loaded_resource: Resource = ResourceLoader.load(placeholder_path)
	if loaded_resource is Texture2D:
		var loaded_texture: Texture2D = loaded_resource as Texture2D
		_iso_placeholder_texture_cache[asset_key] = loaded_texture
		return loaded_texture

	_iso_placeholder_texture_cache[asset_key] = null
	return null

func clear_iso_placeholder_texture_cache() -> void:
	_iso_placeholder_texture_cache.clear()
	_iso_concrete_wall_smoke_texture_cache = null
	_iso_concrete_wall_smoke_texture_checked = false

func get_iso_concrete_wall_smoke_texture() -> Texture2D:
	# Prefer the existing exported texture hook when it is assigned manually.
	# TASK TEST smoke then falls back to the temporary PNG path and finally to
	# normal placeholder/procedural wall rendering if the PNG is missing.
	if iso_wall_concrete_texture != null:
		return iso_wall_concrete_texture
	if not should_use_iso_concrete_wall_png_smoke_preview():
		return null
	if _iso_concrete_wall_smoke_texture_checked:
		return _iso_concrete_wall_smoke_texture_cache
	_iso_concrete_wall_smoke_texture_checked = true
	if not FileAccess.file_exists(ISO_CONCRETE_WALL_SMOKE_TEXTURE_PATH):
		return null
	var loaded_resource: Resource = ResourceLoader.load(ISO_CONCRETE_WALL_SMOKE_TEXTURE_PATH)
	if loaded_resource is Texture2D:
		_iso_concrete_wall_smoke_texture_cache = loaded_resource as Texture2D
	return _iso_concrete_wall_smoke_texture_cache

func get_explicit_iso_texture_for_asset_key(asset_key: String) -> Texture2D:
	match asset_key:
		"floor_default":
			return iso_floor_default_texture
		"floor_stepped":
			return iso_floor_stepped_texture
		"floor_clean_lab":
			return iso_floor_clean_lab_texture
		"floor_dark_service":
			return iso_floor_dark_service_texture
		"floor_hazard":
			return iso_floor_hazard_texture
		"floor_power":
			return iso_floor_power_texture
		"floor_damaged":
			return iso_floor_damaged_texture
		"floor_reinforced":
			return iso_floor_reinforced_texture
		"floor_diagnostic":
			return iso_floor_diagnostic_texture
		"floor_door_underlay":
			return iso_floor_door_underlay_texture
		"wall_default":
			return iso_wall_default_texture
		"wall_outer":
			return iso_wall_outer_texture
		"wall_brick":
			return iso_wall_brick_texture
		"wall_concrete":
			return get_iso_concrete_wall_smoke_texture()
		"wall_grate":
			return iso_wall_grate_texture
		"wall_damaged":
			return iso_wall_damaged_texture
		"wall_steel":
			return iso_wall_steel_texture
		"wall_energy":
			return iso_wall_energy_texture
		"object_door":
			return iso_object_door_texture
		"object_terminal":
			return iso_object_terminal_texture
		"object_key":
			return iso_object_key_texture
		"object_component":
			return iso_object_component_texture
		"object_socket":
			return iso_object_socket_texture
		"object_cable":
			return iso_object_cable_texture
		"object_generic":
			return iso_object_generic_texture
		"object_fuse":
			return iso_object_fuse_texture
		"object_repair_kit":
			return iso_object_repair_kit_texture
		"object_keycard":
			return iso_object_keycard_texture
		"object_access_code":
			return iso_object_access_code_texture
		"object_cable_reel":
			return iso_object_cable_reel_texture
		"object_button":
			return iso_object_button_texture
		"object_switch":
			return iso_object_switch_texture
		_:
			return null

func get_iso_texture_for_asset_key(asset_key: String) -> Texture2D:
	var explicit_texture: Texture2D = get_explicit_iso_texture_for_asset_key(asset_key)
	if explicit_texture == null and not ISO_PLACEHOLDER_ASSET_PATHS.has(asset_key):
		return null

	if explicit_texture != null:
		return explicit_texture

	return get_iso_placeholder_texture_for_asset_key(asset_key)

func has_iso_texture_for_asset_key(asset_key: String) -> bool:
	return get_iso_texture_for_asset_key(asset_key) != null

func get_iso_visual_layer_debug_state() -> Dictionary:
	return {
		"floor_enabled": should_render_iso_floor_visuals(),
		"wall_enabled": should_render_iso_wall_visuals(),
		"object_enabled": should_render_iso_object_visuals(),
		"fog_enabled": should_render_iso_fog_visuals(),
		"fog_overlay_will_draw": should_draw_iso_fog_cell_shapes(),
		"fog_cell_shapes_enabled": iso_fog_draw_cell_shapes,
		"constructor_fog_suppressed": should_suppress_iso_fog_for_constructor(),
		"asset_hooks_enabled": should_use_iso_tile_asset_hook_visuals(),
		"placeholder_assets_enabled": should_use_iso_placeholder_asset_preset(),
		"preview_active": is_iso_visual_preview_active(),
		"debug_marker": debug_draw_marker,
		"helper_preview": debug_draw_iso_helper_preview,
		"fog_outlines": debug_draw_iso_fog_outlines,
		"cell_outlines": debug_draw_iso_cell_outlines,
		"wall_outlines": debug_draw_iso_wall_outlines,
		"object_outlines": debug_draw_iso_object_outlines,
		"asset_alignment_overlay": show_asset_alignment_overlay
	}

func get_iso_visual_texture_debug_state() -> Dictionary:
	var texture_keys: Array[String] = get_iso_visual_texture_debug_keys()
	var placeholder_preset_enabled: bool = should_use_iso_placeholder_asset_preset()
	var debug_state: Dictionary = {}
	for texture_key in texture_keys:
		var explicit_texture: Texture2D = get_explicit_iso_texture_for_asset_key(texture_key)
		var has_explicit_texture: bool = explicit_texture != null
		var placeholder_path: String = get_iso_placeholder_asset_path(texture_key)
		var placeholder_available: bool = false
		if placeholder_preset_enabled and placeholder_path != "":
			placeholder_available = ResourceLoader.exists(placeholder_path)

		var active_texture_source: String = "none"
		if has_explicit_texture:
			active_texture_source = "explicit"
		elif placeholder_preset_enabled and placeholder_available:
			active_texture_source = "placeholder"

		debug_state[texture_key] = {
			"has_explicit_texture": has_explicit_texture,
			"placeholder_path": placeholder_path,
			"placeholder_available": placeholder_available,
			"active_texture_source": active_texture_source
		}
	return debug_state

func get_iso_visual_texture_debug_keys() -> Array[String]:
	return [
		"floor_default", "floor_stepped", "floor_clean_lab", "floor_dark_service", "floor_hazard", "floor_power", "floor_damaged", "floor_reinforced", "floor_diagnostic", "floor_door_underlay",
		"wall_default", "wall_outer", "wall_brick", "wall_concrete", "wall_grate", "wall_damaged", "wall_steel", "wall_energy",
		"object_door", "object_terminal", "object_key", "object_component", "object_socket", "object_cable", "object_generic",
		"object_fuse", "object_repair_kit", "object_keycard", "object_access_code", "object_cable_reel", "object_button", "object_switch"
	]


func get_iso_asset_alignment_diagnostics() -> Dictionary:
	var missing_alignment_rules: Array[String] = []
	var unused_alignment_rules: Array[String] = []
	var scale_overrides: Dictionary = {}
	for asset_key_variant in ISO_PLACEHOLDER_ASSET_PATHS.keys():
		var asset_key: String = String(asset_key_variant)
		if not ISO_ASSET_ALIGNMENT_RULES.has(asset_key):
			missing_alignment_rules.append(asset_key)
	for rule_key_variant in ISO_ASSET_ALIGNMENT_RULES.keys():
		var rule_key: String = String(rule_key_variant)
		var rule: Dictionary = Dictionary(ISO_ASSET_ALIGNMENT_RULES.get(rule_key, {}))
		if not ISO_PLACEHOLDER_ASSET_PATHS.has(rule_key):
			unused_alignment_rules.append(rule_key)
		var scale_value: float = float(rule.get("scale", 1.0))
		if not is_equal_approx(scale_value, 1.0):
			scale_overrides[rule_key] = scale_value
	missing_alignment_rules.sort()
	unused_alignment_rules.sort()
	return {
		"ok": missing_alignment_rules.is_empty(),
		"missing_alignment_rules": missing_alignment_rules,
		"unused_alignment_rules": unused_alignment_rules,
		"asset_count": ISO_PLACEHOLDER_ASSET_PATHS.size(),
		"rule_count": ISO_ASSET_ALIGNMENT_RULES.size(),
		"scale_overrides": scale_overrides
	}

func _increment_iso_debug_count(counts: Dictionary, key: String) -> void:
	if key.is_empty():
		return
	var current_value: int = int(counts.get(key, 0))
	counts[key] = current_value + 1

func get_iso_visual_cell_stats() -> Dictionary:
	var stats: Dictionary = {
		"has_grid_manager": _grid_manager != null,
		"map_width": 0,
		"map_height": 0,
		"total_cells": 0,
		"floor_like_cells": 0,
		"wall_cells": 0,
		"object_cells": 0,
		"fog_overlay_cells": 0,
		"visible_cells": 0,
		"explored_cells": 0,
		"unexplored_cells": 0,
		"tile_type_counts": {},
		"object_profile_counts": {},
		"wall_profile_counts": {},
		"floor_profile_counts": {},
		"asset_key_counts": {}
	}
	if _grid_manager == null:
		return stats

	var map_width: int = _grid_manager.get_map_width()
	var map_height: int = _grid_manager.get_map_height()
	stats["map_width"] = map_width
	stats["map_height"] = map_height
	var total_cells: int = maxi(map_width, 0) * maxi(map_height, 0)
	stats["total_cells"] = total_cells

	var tile_type_counts: Dictionary = Dictionary(stats.get("tile_type_counts", {}))
	var object_profile_counts: Dictionary = Dictionary(stats.get("object_profile_counts", {}))
	var wall_profile_counts: Dictionary = Dictionary(stats.get("wall_profile_counts", {}))
	var floor_profile_counts: Dictionary = Dictionary(stats.get("floor_profile_counts", {}))
	var asset_key_counts: Dictionary = Dictionary(stats.get("asset_key_counts", {}))

	for y in range(map_height):
		for x in range(map_width):
			var cell: Vector2i = Vector2i(x, y)
			var tile_type: int = _grid_manager.get_tile(cell)
			_increment_iso_debug_count(tile_type_counts, str(tile_type))

			if is_floor_like_tile(tile_type):
				stats["floor_like_cells"] = int(stats.get("floor_like_cells", 0)) + 1
				_increment_iso_debug_count(floor_profile_counts, get_iso_floor_visual_profile_key_for_cell(cell))
				_increment_iso_debug_count(asset_key_counts, get_iso_floor_asset_key_for_tile(tile_type))
			if is_wall_tile(tile_type):
				stats["wall_cells"] = int(stats.get("wall_cells", 0)) + 1
				var wall_profile_key: String = get_wall_visual_profile_key_for_cell(cell)
				_increment_iso_debug_count(wall_profile_counts, wall_profile_key)
				_increment_iso_debug_count(asset_key_counts, get_iso_wall_asset_key_for_profile(wall_profile_key))
			if is_iso_object_tile(tile_type):
				stats["object_cells"] = int(stats.get("object_cells", 0)) + 1
				var object_profile_key: String = get_iso_object_profile_key_for_tile(tile_type)
				_increment_iso_debug_count(object_profile_counts, object_profile_key)
				_increment_iso_debug_count(asset_key_counts, get_iso_object_asset_key_for_profile(object_profile_key))
			if should_draw_iso_fog_for_cell(cell):
				stats["fog_overlay_cells"] = int(stats.get("fog_overlay_cells", 0)) + 1

			if _grid_manager.has_method("is_cell_visible") and _grid_manager.is_cell_visible(cell):
				stats["visible_cells"] = int(stats.get("visible_cells", 0)) + 1
			if _grid_manager.has_method("is_explored") and _grid_manager.is_explored(cell):
				stats["explored_cells"] = int(stats.get("explored_cells", 0)) + 1

	stats["unexplored_cells"] = int(stats.get("total_cells", 0)) - int(stats.get("explored_cells", 0))
	stats["tile_type_counts"] = tile_type_counts
	stats["object_profile_counts"] = object_profile_counts
	stats["wall_profile_counts"] = wall_profile_counts
	stats["floor_profile_counts"] = floor_profile_counts
	stats["asset_key_counts"] = asset_key_counts
	return stats

func get_iso_visual_cell_stats_text() -> String:
	var stats: Dictionary = get_iso_visual_cell_stats()
	var lines: Array[String] = []
	var asset_key_counts: Dictionary = Dictionary(stats.get("asset_key_counts", {}))
	lines.append("IsoVisualCellStats:")
	lines.append("Grid:")
	lines.append("- has_grid_manager: %s" % str(stats.get("has_grid_manager", false)))
	lines.append("- map_size: %sx%s" % [str(stats.get("map_width", 0)), str(stats.get("map_height", 0))])
	lines.append("- total_cells: %s" % str(stats.get("total_cells", 0)))
	lines.append("Cells:")
	lines.append("- floor_like: %s" % str(stats.get("floor_like_cells", 0)))
	lines.append("- walls: %s" % str(stats.get("wall_cells", 0)))
	lines.append("- objects: %s" % str(stats.get("object_cells", 0)))
	lines.append("- fog_overlay: %s" % str(stats.get("fog_overlay_cells", 0)))
	lines.append("- visible: %s" % str(stats.get("visible_cells", 0)))
	lines.append("- explored: %s" % str(stats.get("explored_cells", 0)))
	lines.append("- unexplored: %s" % str(stats.get("unexplored_cells", 0)))
	lines.append("Asset keys:")
	for asset_key in asset_key_counts.keys():
		lines.append("- %s: %s" % [str(asset_key), str(asset_key_counts.get(asset_key, 0))])
	return "\n".join(lines)

func validate_iso_visual_cell_stats() -> Array[String]:
	var warnings: Array[String] = []
	var stats: Dictionary = get_iso_visual_cell_stats()
	if not bool(stats.get("has_grid_manager", false)):
		warnings.append("iso_cell_stats_missing_grid_manager")
	if int(stats.get("map_width", 0)) <= 0 or int(stats.get("map_height", 0)) <= 0:
		warnings.append("iso_cell_stats_empty_map")
	if int(stats.get("total_cells", 0)) > 0 and int(stats.get("floor_like_cells", 0)) <= 0:
		warnings.append("iso_cell_stats_no_floor_like_cells")
	if int(stats.get("total_cells", 0)) > 0 and int(stats.get("wall_cells", 0)) <= 0:
		warnings.append("iso_cell_stats_no_wall_cells")
	if int(stats.get("total_cells", 0)) > 0 and int(stats.get("object_cells", 0)) <= 0:
		warnings.append("iso_cell_stats_no_object_cells")
	if is_iso_visual_preview_active() and (
		int(stats.get("floor_like_cells", 0))
		+ int(stats.get("wall_cells", 0))
		+ int(stats.get("object_cells", 0))
	) <= 0:
		warnings.append("iso_cell_stats_preview_enabled_but_no_visual_cells")
	return warnings

func get_iso_visual_cell_stats_validation_text() -> String:
	var warnings: Array[String] = validate_iso_visual_cell_stats()
	if warnings.is_empty():
		return "IsoVisualCellStatsValidation: ok"
	var lines: Array[String] = ["IsoVisualCellStatsValidation:"]
	for warning_key in warnings:
		lines.append("- %s" % warning_key)
	return "\n".join(lines)

func get_iso_visual_debug_report() -> Dictionary:
	var has_grid_manager: bool = _grid_manager != null
	var map_width: int = 0
	var map_height: int = 0
	var legacy_grid_should_draw: bool = false
	if has_grid_manager:
		map_width = _grid_manager.get_map_width()
		map_height = _grid_manager.get_map_height()
		legacy_grid_should_draw = _grid_manager.should_draw_legacy_grid()
	var iso_active: bool = is_iso_renderer_active()
	var floor_enabled: bool = should_render_iso_floor_visuals()
	var wall_enabled: bool = should_render_iso_wall_visuals()
	var object_enabled: bool = should_render_iso_object_visuals()
	var fog_enabled: bool = should_render_iso_fog_visuals()
	var fog_overlay_will_draw: bool = should_draw_iso_fog_cell_shapes()
	var constructor_fog_suppressed: bool = should_suppress_iso_fog_for_constructor()
	var duplicate_overlay_risk: bool = is_iso_visual_preview_active() and (floor_enabled or wall_enabled or object_enabled) and fog_overlay_will_draw
	return {
		"single_render_path": not (legacy_grid_should_draw and iso_active),
		"legacy_grid_should_draw": legacy_grid_should_draw,
		"iso_renderer_active": iso_active,
		"placeholder_assets_enabled": should_use_iso_placeholder_asset_preset(),
		"procedural_wall_under_texture_enabled": false,
		"fog_enabled": fog_enabled,
		"fog_overlay_will_draw": fog_overlay_will_draw,
		"fog_cell_shapes_enabled": iso_fog_draw_cell_shapes,
		"constructor_fog_suppressed": constructor_fog_suppressed,
		"duplicate_overlay_risk": duplicate_overlay_risk,
		"layers": get_iso_visual_layer_debug_state(),
		"preview": get_iso_visual_preview_state(),
		"textures": get_iso_visual_texture_debug_state(),
		"asset_alignment": get_iso_asset_alignment_diagnostics(),
		"cell_stats": get_iso_visual_cell_stats(),
		"iso_settings": {
			"tile_width": iso_tile_width,
			"tile_height": iso_tile_height,
			"wall_height": iso_wall_height,
			"object_marker_height": iso_object_marker_height,
			"origin": iso_origin
		},
		"grid": {
			"has_grid_manager": has_grid_manager,
			"map_width": map_width,
			"map_height": map_height
		}
	}

func get_iso_visual_debug_report_text() -> String:
	var report: Dictionary = get_iso_visual_debug_report()
	var lines: Array[String] = []
	var layers: Dictionary = Dictionary(report.get("layers", {}))
	var preview: Dictionary = Dictionary(report.get("preview", {}))
	var textures: Dictionary = Dictionary(report.get("textures", {}))
	var cell_stats: Dictionary = Dictionary(report.get("cell_stats", {}))
	var asset_alignment: Dictionary = Dictionary(report.get("asset_alignment", {}))
	var grid: Dictionary = Dictionary(report.get("grid", {}))
	var iso_settings: Dictionary = Dictionary(report.get("iso_settings", {}))
	lines.append("IsoVisualDebugReport:")
	lines.append("Single render path:")
	lines.append("- ok: %s" % str(report.get("single_render_path", false)))
	lines.append("- legacy_grid_should_draw: %s" % str(report.get("legacy_grid_should_draw", false)))
	lines.append("- iso_renderer_active: %s" % str(report.get("iso_renderer_active", false)))
	lines.append("- placeholder_assets_enabled: %s" % str(report.get("placeholder_assets_enabled", false)))
	lines.append("- procedural_wall_under_texture_enabled: %s" % str(report.get("procedural_wall_under_texture_enabled", false)))
	lines.append("Fog overlay diagnostics:")
	lines.append("- fog_enabled: %s" % str(report.get("fog_enabled", false)))
	lines.append("- fog_overlay_will_draw: %s" % str(report.get("fog_overlay_will_draw", false)))
	lines.append("- fog_cell_shapes_enabled: %s" % str(report.get("fog_cell_shapes_enabled", false)))
	lines.append("- constructor_fog_suppressed: %s" % str(report.get("constructor_fog_suppressed", false)))
	lines.append("- duplicate_overlay_risk: %s" % str(report.get("duplicate_overlay_risk", false)))
	lines.append("Layers:")
	lines.append("- floor: %s" % str(layers.get("floor_enabled", false)))
	lines.append("- wall: %s" % str(layers.get("wall_enabled", false)))
	lines.append("- objects: %s" % str(layers.get("object_enabled", false)))
	lines.append("- fog: %s" % str(layers.get("fog_enabled", false)))
	lines.append("- asset_hooks: %s" % str(layers.get("asset_hooks_enabled", false)))
	lines.append("- placeholder_assets: %s" % str(layers.get("placeholder_assets_enabled", false)))
	lines.append("- asset_alignment_overlay: %s" % str(layers.get("asset_alignment_overlay", false)))
	lines.append("Preview:")
	lines.append("- active: %s" % str(preview.get("preview_active", false)))
	lines.append("- includes_fog: %s" % str(iso_visual_preview_includes_fog))
	lines.append("- includes_asset_hooks: %s" % str(iso_visual_preview_includes_asset_hooks))
	lines.append("Asset alignment:")
	lines.append("- ok: %s" % str(asset_alignment.get("ok", false)))
	lines.append("- assets/rules: %s/%s" % [str(asset_alignment.get("asset_count", 0)), str(asset_alignment.get("rule_count", 0))])
	lines.append("- missing_rules: %s" % str(asset_alignment.get("missing_alignment_rules", [])))
	lines.append("Textures:")
	for texture_key in get_iso_visual_texture_debug_keys():
		var texture_entry: Dictionary = Dictionary(textures.get(texture_key, {}))
		lines.append("- %s: %s" % [texture_key, str(texture_entry.get("active_texture_source", "none"))])
	lines.append("Grid:")
	lines.append("- has_grid_manager: %s" % str(grid.get("has_grid_manager", false)))
	lines.append("- map_size: %sx%s" % [str(grid.get("map_width", 0)), str(grid.get("map_height", 0))])
	lines.append("Cell stats:")
	lines.append("- floor_like: %s" % str(cell_stats.get("floor_like_cells", 0)))
	lines.append("- walls: %s" % str(cell_stats.get("wall_cells", 0)))
	lines.append("- objects: %s" % str(cell_stats.get("object_cells", 0)))
	lines.append("- fog_overlay: %s" % str(cell_stats.get("fog_overlay_cells", 0)))
	lines.append("Iso:")
	lines.append("- tile: %sx%s" % [str(iso_settings.get("tile_width", 0.0)), str(iso_settings.get("tile_height", 0.0))])
	lines.append("- wall_height: %s" % str(iso_settings.get("wall_height", 0.0)))
	lines.append("- object_marker_height: %s" % str(iso_settings.get("object_marker_height", 0.0)))
	return "\n".join(lines)

func validate_iso_visual_debug_report() -> Array[String]:
	var warnings: Array[String] = []
	if iso_tile_width <= 0.0:
		warnings.append("iso_tile_width_invalid")
	if iso_tile_height <= 0.0:
		warnings.append("iso_tile_height_invalid")
	if iso_wall_height <= 0.0:
		warnings.append("iso_wall_height_invalid")
	if iso_object_marker_height <= 0.0:
		warnings.append("iso_object_marker_height_invalid")
	if use_iso_placeholder_asset_preset and ISO_PLACEHOLDER_ASSET_PATHS.is_empty():
		warnings.append("iso_placeholder_asset_paths_missing")
	var alignment_diagnostics: Dictionary = get_iso_asset_alignment_diagnostics()
	if not bool(alignment_diagnostics.get("ok", false)):
		warnings.append("iso_asset_alignment_rules_missing")
	if use_iso_placeholder_asset_preset and iso_placeholder_asset_preset_requires_preview and not is_iso_visual_preview_active():
		warnings.append("iso_placeholder_preset_waiting_for_preview")
	var debug_report: Dictionary = get_iso_visual_debug_report()
	if not bool(debug_report.get("single_render_path", true)):
		warnings.append("single_render_path_duplicate_risk")
	if use_iso_tile_asset_hooks and not should_use_iso_placeholder_asset_preset():
		var texture_keys: Array[String] = get_iso_visual_texture_debug_keys()
		var has_explicit_texture: bool = false
		for texture_key in texture_keys:
			if get_explicit_iso_texture_for_asset_key(texture_key) != null:
				has_explicit_texture = true
				break
		if not has_explicit_texture:
			warnings.append("iso_asset_hooks_enabled_without_textures")
	return warnings

func get_iso_visual_debug_validation_text() -> String:
	var warnings: Array[String] = validate_iso_visual_debug_report()
	if warnings.is_empty():
		return "IsoVisualDebugValidation: ok"
	var lines: Array[String] = ["IsoVisualDebugValidation:"]
	for warning_key in warnings:
		lines.append("- %s" % warning_key)
	return "\n".join(lines)

func _get_color_from_dict(data: Dictionary, key: String, fallback: Color) -> Color:
	var value: Variant = data.get(key, fallback)
	if value is Color:
		return value
	return fallback

func get_iso_asset_alignment_rule(asset_key: String) -> Dictionary:
	if ISO_ASSET_ALIGNMENT_RULES.has(asset_key):
		return Dictionary(ISO_ASSET_ALIGNMENT_RULES.get(asset_key, {}))
	if asset_key.begins_with("floor_"):
		return {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": Vector2(128, 64), "layer_hint": "floor", "notes": "Fallback floor alignment."}
	if asset_key.begins_with("wall_"):
		return {"anchor": "wall_cell_base", "scale": 1.0, "offset": Vector2(0, -32), "expected_size": Vector2(128, 120), "layer_hint": "wall", "notes": "Fallback wall alignment."}
	if asset_key == "object_door":
		return {"anchor": "door_insert_center", "scale": 0.9, "offset": Vector2(0, -20), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Fallback door alignment."}
	if asset_key.begins_with("object_"):
		return {"anchor": "bottom_center", "scale": 0.75, "offset": Vector2(0, -8), "expected_size": Vector2(96, 96), "layer_hint": "object", "notes": "Fallback object alignment."}
	return {"anchor": "center", "scale": 1.0, "offset": Vector2.ZERO, "expected_size": Vector2(96, 96), "layer_hint": "unknown", "notes": "Fallback generic alignment."}

func get_iso_asset_alignment_scale(asset_key: String) -> float:
	var rule: Dictionary = get_iso_asset_alignment_rule(asset_key)
	var scale_value: float = float(rule.get("scale", 1.0))
	return maxf(scale_value, 0.01)

func get_iso_asset_alignment_expected_size(asset_key: String) -> Vector2:
	var rule: Dictionary = get_iso_asset_alignment_rule(asset_key)
	return Vector2(rule.get("expected_size", Vector2(96, 96)))

func get_iso_asset_alignment_anchor_offset(anchor: String, size: Vector2) -> Vector2:
	match anchor:
		"center", "wall_mount_center", "door_insert_center":
			return Vector2(size.x * 0.5, size.y * 0.5)
		"bottom_center", "wall_cell_base":
			return Vector2(size.x * 0.5, size.y)
		_:
			return Vector2(size.x * 0.5, size.y * 0.5)

func get_iso_texture_draw_position_from_center(center: Vector2, texture: Texture2D) -> Vector2:
	var size: Vector2 = texture.get_size()
	return center - Vector2(size.x * 0.5, size.y * 0.75)

func get_iso_texture_draw_rect_for_asset_key_with_size(asset_key: String, center: Vector2, source_size: Vector2) -> Rect2:
	var rule: Dictionary = get_iso_asset_alignment_rule(asset_key)
	var anchor: String = String(rule.get("anchor", "center"))
	var scale_value: float = get_iso_asset_alignment_scale(asset_key)
	var destination_size: Vector2 = source_size * scale_value
	var offset: Vector2 = Vector2(rule.get("offset", Vector2.ZERO))
	var anchor_offset: Vector2 = get_iso_asset_alignment_anchor_offset(anchor, destination_size)
	var destination_position: Vector2 = center - anchor_offset + offset
	return Rect2(destination_position, destination_size)

func get_iso_texture_draw_rect_for_asset_key(asset_key: String, center: Vector2, texture: Texture2D) -> Rect2:
	return get_iso_texture_draw_rect_for_asset_key_with_size(asset_key, center, texture.get_size())

func get_iso_texture_draw_position_for_asset_key(asset_key: String, center: Vector2, texture: Texture2D) -> Vector2:
	return get_iso_texture_draw_rect_for_asset_key(asset_key, center, texture).position

func get_iso_texture_draw_position(cell: Vector2i, texture: Texture2D) -> Vector2:
	return get_iso_texture_draw_position_from_center(grid_to_iso(cell), texture)

func should_draw_iso_asset_with_rect(asset_key: String) -> bool:
	var rule: Dictionary = get_iso_asset_alignment_rule(asset_key)
	var scale_value: float = get_iso_asset_alignment_scale(asset_key)
	var offset: Vector2 = Vector2(rule.get("offset", Vector2.ZERO))
	var anchor: String = String(rule.get("anchor", "center"))
	if not is_equal_approx(scale_value, 1.0):
		return true
	if offset != Vector2.ZERO:
		return true
	return anchor != "center"

func draw_iso_asset_alignment_overlay(asset_key: String, anchor_position: Vector2, actual_rect: Rect2) -> void:
	if not show_asset_alignment_overlay and not show_object_grounding_overlay:
		return
	var expected_size: Vector2 = get_iso_asset_alignment_expected_size(asset_key) * get_iso_asset_alignment_scale(asset_key)
	var rule: Dictionary = get_iso_asset_alignment_rule(asset_key)
	var expected_anchor_offset: Vector2 = get_iso_asset_alignment_anchor_offset(String(rule.get("anchor", "center")), expected_size)
	var expected_rect: Rect2 = Rect2(anchor_position - expected_anchor_offset + Vector2(rule.get("offset", Vector2.ZERO)), expected_size)
	draw_rect(expected_rect, Color(1.0, 0.78, 0.22, 0.18), true)
	draw_rect(expected_rect, Color(1.0, 0.78, 0.22, 0.95), false, 1.0)
	draw_rect(actual_rect, Color(0.2, 0.9, 1.0, 0.72), false, 1.0)
	draw_line(anchor_position + Vector2(-4.0, 0.0), anchor_position + Vector2(4.0, 0.0), Color(1.0, 0.25, 0.25, 0.95), 1.5)
	draw_line(anchor_position + Vector2(0.0, -4.0), anchor_position + Vector2(0.0, 4.0), Color(1.0, 0.25, 0.25, 0.95), 1.5)
	draw_circle(anchor_position, 2.5, Color(1.0, 0.25, 0.25, 0.95))
	draw_string(ThemeDB.fallback_font, expected_rect.position + Vector2(2.0, -3.0), asset_key, HORIZONTAL_ALIGNMENT_LEFT, maxf(expected_rect.size.x, 40.0), 9, Color(1.0, 0.95, 0.78, 0.95))

func draw_iso_texture_with_alignment(texture: Texture2D, asset_key: String, center: Vector2) -> void:
	var destination_rect: Rect2 = get_iso_texture_draw_rect_for_asset_key(asset_key, center, texture)
	if should_draw_iso_asset_with_rect(asset_key):
		draw_texture_rect(texture, destination_rect, false)
	else:
		draw_texture(texture, destination_rect.position)
	draw_iso_asset_alignment_overlay(asset_key, center, destination_rect)

func draw_iso_texture_asset(cell: Vector2i, asset_key: String, visual_center_override: Vector2 = Vector2.INF) -> bool:
	# Asset hooks are optional. Procedural fallback remains the default path.
	if not should_use_iso_tile_asset_hook_visuals():
		return false
	if asset_key.is_empty():
		return false
	var texture: Texture2D = get_iso_texture_for_asset_key(asset_key)
	if texture == null:
		return false
	var visual_center: Vector2 = grid_to_iso(cell)
	if visual_center_override != Vector2.INF:
		visual_center = visual_center_override
	draw_iso_texture_with_alignment(texture, asset_key, visual_center)
	return true

func draw_optional_visual_texture_asset(asset_id: String, cell: Vector2i, _fallback_callable_name: String = "", options: Dictionary = {}) -> bool:
	var normalized_asset_id: String = asset_id.strip_edges()
	if normalized_asset_id.is_empty():
		return false
	var mission_manager: Node = get_mission_manager_ref()
	if mission_manager == null or not mission_manager.has_method("resolve_visual_texture_asset"):
		return false
	var resolved: Dictionary = Dictionary(mission_manager.call("resolve_visual_texture_asset", normalized_asset_id))
	if not bool(resolved.get("ok", false)):
		push_warning("[VisualAsset] unknown texture_asset_id: %s" % normalized_asset_id)
		return false
	if not bool(resolved.get("has_texture", false)):
		return false
	var texture_path: String = String(resolved.get("texture_path", "")).strip_edges()
	if texture_path.is_empty():
		return false
	var loaded: Resource = load(texture_path)
	if loaded == null or not (loaded is Texture2D):
		return false
	var texture: Texture2D = loaded as Texture2D
	var center: Vector2 = grid_to_iso(cell)
	if options.has("visual_center"):
		center = Vector2(options.get("visual_center", center))
	var alignment_asset_key: String = String(resolved.get("placeholder_asset_key", normalized_asset_id))
	var atlas_region: Rect2i = Rect2i(resolved.get("atlas_region", Rect2i(0, 0, 0, 0)))
	if atlas_region.size.x > 0 and atlas_region.size.y > 0:
		var atlas_size: Vector2 = Vector2(float(atlas_region.size.x), float(atlas_region.size.y))
		var destination_rect: Rect2 = get_iso_texture_draw_rect_for_asset_key_with_size(alignment_asset_key, center, atlas_size)
		draw_texture_rect_region(texture, destination_rect, Rect2(atlas_region.position, atlas_region.size))
		draw_iso_asset_alignment_overlay(alignment_asset_key, center, destination_rect)
		return true
	draw_iso_texture_with_alignment(texture, alignment_asset_key, center)
	return true

func can_draw_optional_visual_texture_asset(asset_id: String) -> bool:
	var normalized_asset_id: String = asset_id.strip_edges()
	if normalized_asset_id.is_empty():
		return false
	var mission_manager: Node = get_mission_manager_ref()
	if mission_manager == null or not mission_manager.has_method("resolve_visual_texture_asset"):
		return false
	var resolved: Dictionary = Dictionary(mission_manager.call("resolve_visual_texture_asset", normalized_asset_id))
	if not bool(resolved.get("ok", false)):
		return false
	if not bool(resolved.get("has_texture", false)):
		return false
	var texture_path: String = String(resolved.get("texture_path", "")).strip_edges()
	if texture_path.is_empty():
		return false
	var loaded: Resource = load(texture_path)
	return loaded != null and (loaded is Texture2D)

func has_drawable_iso_wall_texture(material_override: Dictionary, material_row: Dictionary, wall_profile_key: String) -> bool:
	if bool(material_override.get("ok", false)):
		if can_draw_optional_visual_texture_asset(String(material_row.get("texture_asset_id", ""))):
			return true
	var wall_asset_key: String = get_iso_wall_asset_key_for_profile(wall_profile_key)
	if wall_asset_key.is_empty():
		return false
	if not should_use_iso_tile_asset_hook_visuals():
		return false
	return get_iso_texture_for_asset_key(wall_asset_key) != null

func draw_iso_wall_texture_for_cell(cell: Vector2i, material_override: Dictionary, material_row: Dictionary, wall_profile_key: String) -> bool:
	if bool(material_override.get("ok", false)):
		if draw_optional_visual_texture_asset(String(material_row.get("texture_asset_id", "")), cell, "draw_iso_wall_surface_accent"):
			return true
	return draw_iso_texture_asset(cell, get_iso_wall_asset_key_for_profile(wall_profile_key))

func draw_iso_concrete_wall_smoke_texture_for_cell(cell: Vector2i, wall_profile_key: String) -> bool:
	if wall_profile_key != "concrete_wall":
		return false
	if not should_use_iso_concrete_wall_png_smoke_preview() and iso_wall_concrete_texture == null:
		return false
	if is_wall_adjacent_to_door(cell):
		return false
	var texture: Texture2D = get_iso_concrete_wall_smoke_texture()
	if texture == null:
		return false
	var source_size: Vector2 = texture.get_size()
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		return false
	var target_width: float = maxf(iso_tile_width, ISO_CONCRETE_WALL_SMOKE_TARGET_WIDTH)
	var target_height: float = maxf(iso_tile_width, ISO_CONCRETE_WALL_SMOKE_TARGET_HEIGHT)
	var scale_value: float = minf(target_width / source_size.x, target_height / source_size.y)
	var destination_size: Vector2 = source_size * scale_value
	var base_anchor: Vector2 = grid_to_iso(cell) + Vector2(0.0, get_iso_tile_half_size().y)
	var destination_rect: Rect2 = Rect2(base_anchor - Vector2(destination_size.x * 0.5, destination_size.y), destination_size)
	draw_texture_rect(texture, destination_rect, false)
	draw_iso_asset_alignment_overlay("wall_concrete", base_anchor, destination_rect)
	return true

func get_wall_prototype_colors(cell: Vector2i) -> Dictionary:
	var profile_key: String = get_wall_visual_profile_key_for_cell(cell)
	var profile: Dictionary = get_wall_visual_profile(profile_key)
	var parity: int = (cell.x + cell.y) % 2
	var top_color: Color = _get_color_from_dict(profile, "top", Color.WHITE)
	var left_color: Color = _get_color_from_dict(profile, "left", Color.WHITE)
	var right_color: Color = _get_color_from_dict(profile, "right", Color.WHITE)
	if parity != 0:
		top_color = top_color.lightened(0.06)
		left_color = left_color.lightened(0.05)
		right_color = right_color.lightened(0.045)

	var colors: Dictionary = {
		"top": top_color,
		"left": left_color,
		"right": right_color,
		"outline": _get_color_from_dict(profile, "outline", Color(0.24, 0.31, 0.36, 0.9)),
		"accent": _get_color_from_dict(profile, "accent", Color(0.29, 0.35, 0.4, 0.5))
	}
	var material_override: Dictionary = _get_wall_material_override_for_cell(cell)
	if bool(material_override.get("ok", false)):
		var material_row: Dictionary = Dictionary(material_override.get("material", {}))
		var tint_color: Color = Color(material_row.get("fallback_color", Color(1, 1, 1, 1)))
		var edge_color: Color = Color(material_row.get("edge_color", colors.get("outline", Color.WHITE)))
		colors["top"] = _blend_color(Color(colors.get("top", Color.WHITE)), tint_color, 0.45)
		colors["left"] = _blend_color(Color(colors.get("left", Color.WHITE)), tint_color.darkened(0.05), 0.5)
		colors["right"] = _blend_color(Color(colors.get("right", Color.WHITE)), tint_color.darkened(0.1), 0.5)
		colors["outline"] = _blend_color(Color(colors.get("outline", Color.WHITE)), edge_color, 0.72)
		colors["accent"] = _blend_color(Color(colors.get("accent", Color.WHITE)), edge_color.lightened(0.12), 0.68)
		colors["wall_material_style"] = String(material_row.get("style", "default"))
	return colors

func _blend_color(base_color: Color, tint_color: Color, amount: float) -> Color:
	var safe_amount: float = clampf(amount, 0.0, 1.0)
	return base_color.lerp(tint_color, safe_amount)

func _get_wall_material_override_for_cell(cell: Vector2i) -> Dictionary:
	var mission_manager: Node = get_mission_manager_ref()
	if mission_manager == null:
		return {"ok": false}
	if mission_manager.has_method("get_map_constructor_wall_material_for_wall_cell"):
		var wall_cell_result: Dictionary = Dictionary(mission_manager.call("get_map_constructor_wall_material_for_wall_cell", cell))
		if bool(wall_cell_result.get("ok", false)):
			return wall_cell_result
	if not mission_manager.has_method("get_map_constructor_wall_material"):
		return {"ok": false}
	var side_order: Array[String] = ["north", "east", "south", "west"]
	var chosen_override: Dictionary = {}
	for side_id in side_order:
		var override_result: Dictionary = Dictionary(mission_manager.call("get_map_constructor_wall_material", cell, side_id))
		if bool(override_result.get("ok", false)):
			chosen_override = Dictionary(override_result.get("override", {}))
			break
	if chosen_override.is_empty():
		return {"ok": false}
	var material_id: String = String(chosen_override.get("material_id", "")).to_lower()
	if material_id.is_empty() or not mission_manager.has_method("get_map_constructor_wall_material_catalog"):
		return {"ok": false}
	var catalog: Dictionary = Dictionary(mission_manager.call("get_map_constructor_wall_material_catalog"))
	for material_variant in Array(catalog.get("materials", [])):
		var material_row: Dictionary = Dictionary(material_variant)
		if String(material_row.get("id", "")).to_lower() == material_id:
			return {"ok": true, "override": chosen_override, "material": material_row}
	return {"ok": false}

func get_default_wall_visual_profile_key() -> String:
	return "default_wall"

func normalize_wall_visual_profile_key(profile_key: String) -> String:
	var normalized_key: String = profile_key.strip_edges().to_lower()
	normalized_key = normalized_key.replace(" ", "_")
	normalized_key = normalized_key.replace("-", "_")
	if normalized_key.is_empty():
		return get_default_wall_visual_profile_key()

	var profiles: Dictionary = get_wall_visual_profiles()
	if not profiles.has(normalized_key):
		return get_default_wall_visual_profile_key()
	return normalized_key

func get_wall_visual_profiles() -> Dictionary:
	# Visual-only mapping layer for procedural wall prototype colors.
	# Keys intentionally mirror planned WorldObjectCatalog wall IDs for future metadata wiring.
	return {
		"default_wall": {
			"label": "Default Wall",
			"top": Color(0.205, 0.225, 0.255, 0.98),
			"left": Color(0.125, 0.14, 0.165, 0.98),
			"right": Color(0.1, 0.115, 0.14, 0.98),
			"outline": Color(0.24, 0.31, 0.36, 0.9),
			"accent": Color(0.29, 0.35, 0.4, 0.5)
		},
		"outer_wall": {
			"label": "Outer Wall",
			"top": Color(0.19, 0.2, 0.22, 0.98),
			"left": Color(0.11, 0.12, 0.14, 0.98),
			"right": Color(0.09, 0.1, 0.12, 0.98),
			"outline": Color(0.24, 0.29, 0.34, 0.9),
			"accent": Color(0.26, 0.31, 0.37, 0.45)
		},
		"grate_wall": {
			"label": "Grate Wall",
			"top": Color(0.15, 0.18, 0.2, 0.8),
			"left": Color(0.07, 0.085, 0.1, 0.72),
			"right": Color(0.06, 0.075, 0.09, 0.72),
			"outline": Color(0.18, 0.24, 0.28, 0.88),
			"accent": Color(0.78, 0.86, 0.92, 0.85)
		},
		"damaged_wall": {
			"label": "Damaged Wall",
			"top": Color(0.195, 0.16, 0.16, 0.98),
			"left": Color(0.125, 0.09, 0.09, 0.98),
			"right": Color(0.1, 0.075, 0.075, 0.98),
			"outline": Color(0.33, 0.22, 0.21, 0.9),
			"accent": Color(0.43, 0.2, 0.16, 0.55)
		},
		"brick_wall": {
			"label": "Brick Wall",
			"top": Color(0.37, 0.21, 0.16, 0.98),
			"left": Color(0.28, 0.14, 0.11, 0.98),
			"right": Color(0.24, 0.12, 0.1, 0.98),
			"outline": Color(0.46, 0.24, 0.18, 0.92),
			"accent": Color(0.82, 0.72, 0.58, 0.64)
		},
		"concrete_wall": {
			"label": "Concrete Wall",
			"top": Color(0.33, 0.34, 0.35, 0.98),
			"left": Color(0.23, 0.24, 0.25, 0.98),
			"right": Color(0.2, 0.21, 0.22, 0.98),
			"outline": Color(0.42, 0.44, 0.45, 0.9),
			"accent": Color(0.68, 0.71, 0.73, 0.52)
		},
		"steel_wall": {
			"label": "Steel Wall",
			"top": Color(0.26, 0.31, 0.36, 0.98),
			"left": Color(0.16, 0.2, 0.25, 0.98),
			"right": Color(0.135, 0.175, 0.22, 0.98),
			"outline": Color(0.3, 0.39, 0.47, 0.92),
			"accent": Color(0.66, 0.76, 0.86, 0.65)
		},
		"reinforced_steel_wall": {
			"label": "Reinforced Steel Wall",
			"top": Color(0.165, 0.195, 0.235, 0.98),
			"left": Color(0.1, 0.125, 0.155, 0.98),
			"right": Color(0.085, 0.11, 0.14, 0.98),
			"outline": Color(0.22, 0.3, 0.36, 0.9),
			"accent": Color(0.28, 0.39, 0.48, 0.5)
		},
		"titanium_wall": {
			"label": "Titanium Wall",
			"top": Color(0.245, 0.265, 0.3, 0.98),
			"left": Color(0.17, 0.185, 0.215, 0.98),
			"right": Color(0.14, 0.155, 0.185, 0.98),
			"outline": Color(0.31, 0.38, 0.45, 0.9),
			"accent": Color(0.45, 0.53, 0.62, 0.55)
		},
		"energy_wall": {
			"label": "Energy Wall",
			"top": Color(0.12, 0.165, 0.205, 0.98),
			"left": Color(0.07, 0.11, 0.145, 0.98),
			"right": Color(0.055, 0.09, 0.125, 0.98),
			"outline": Color(0.2, 0.36, 0.47, 0.9),
			"accent": Color(0.28, 0.83, 0.96, 0.72)
		}
	}

func get_wall_visual_profile(profile_key: String) -> Dictionary:
	var profiles: Dictionary = get_wall_visual_profiles()
	var default_key: String = get_default_wall_visual_profile_key()
	var normalized_key: String = normalize_wall_visual_profile_key(profile_key)
	if not profiles.has(normalized_key):
		return Dictionary(profiles.get(default_key, {}))
	return Dictionary(profiles.get(normalized_key, profiles.get(default_key, {})))

func get_wall_visual_profile_key_for_cell(cell: Vector2i) -> String:
	if _grid_manager == null:
		return ""
	var tile_type: int = _grid_manager.get_tile(cell)
	if tile_type != GridManager.TILE_WALL:
		return ""

	var wall_object_type: String = get_wall_object_type_for_cell(cell)
	if not wall_object_type.is_empty():
		return wall_object_type

	if is_outer_border_cell(cell):
		return "outer_wall"

	return "concrete_wall"

func get_wall_metadata_for_cell(cell: Vector2i) -> Dictionary:
	var mission_manager: Node = get_mission_manager_ref()
	if mission_manager == null:
		return {}
	if not mission_manager.has_method("get_world_object_at_cell"):
		return {}
	var metadata_variant: Variant = mission_manager.call("get_world_object_at_cell", cell)
	if metadata_variant is Dictionary:
		return Dictionary(metadata_variant)
	return {}

func _get_iso_world_object_metadata_for_cell(cell: Vector2i) -> Dictionary:
	var fallback: Dictionary = {"ok": false, "object_id": "", "object_type": "", "data": {}}
	var mission_manager: Node = get_mission_manager_ref()
	if mission_manager == null:
		return fallback
	if not mission_manager.has_method("get_world_object_at_cell"):
		return fallback
	var metadata_variant: Variant = mission_manager.call("get_world_object_at_cell", cell, true)
	if not (metadata_variant is Dictionary):
		metadata_variant = mission_manager.call("get_world_object_at_cell", cell)
	if not (metadata_variant is Dictionary):
		return fallback
	var metadata: Dictionary = Dictionary(metadata_variant)
	var nested_data: Dictionary = Dictionary(metadata.get("data", {}))
	var object_id: String = String(metadata.get("object_id", metadata.get("id", ""))).strip_edges()
	if object_id.is_empty():
		object_id = String(nested_data.get("id", nested_data.get("object_id", ""))).strip_edges()
	var object_type: String = String(metadata.get("object_type", metadata.get("type", ""))).strip_edges()
	if object_type.is_empty():
		object_type = String(nested_data.get("object_type", nested_data.get("type", ""))).strip_edges()
	if object_id.is_empty():
		return fallback
	if nested_data.is_empty():
		nested_data = metadata
	return {"ok": true, "object_id": object_id, "object_type": object_type, "data": nested_data}

func get_wall_object_type_for_cell(cell: Vector2i) -> String:
	var metadata: Dictionary = get_wall_metadata_for_cell(cell)
	if metadata.is_empty():
		return ""
	var candidates: Array[String] = [
		String(metadata.get("visual_profile", "")),
		String(metadata.get("wall_type", "")),
		String(metadata.get("object_type", "")),
		String(metadata.get("type", "")),
		String(metadata.get("catalog_id", "")),
		String(metadata.get("id", "")),
		String(metadata.get("material", ""))
	]
	var tag_profile: String = get_wall_profile_from_tags(metadata.get("tags", []))
	if not tag_profile.is_empty():
		return tag_profile
	for candidate in candidates:
		var mapped: String = map_wall_metadata_value_to_profile(candidate)
		if not mapped.is_empty():
			return mapped
	return ""

func get_wall_profile_from_tags(tags_variant: Variant) -> String:
	if not (tags_variant is Array):
		return ""
	for tag_value in Array(tags_variant):
		var mapped: String = map_wall_metadata_value_to_profile(String(tag_value))
		if not mapped.is_empty():
			return mapped
	return ""

func map_wall_metadata_value_to_profile(raw_value: String) -> String:
	var value: String = raw_value.strip_edges().to_lower()
	if value.is_empty():
		return ""
	var direct_map: Dictionary = {
		"outer_wall": "outer_wall",
		"grate_wall": "grate_wall",
		"brick_wall": "brick_wall",
		"concrete_wall": "concrete_wall",
		"steel_wall": "steel_wall",
		"reinforced_steel_wall": "reinforced_steel_wall",
		"titanium_wall": "titanium_wall",
		"energy_wall": "energy_wall",
		"damaged_wall": "damaged_wall",
		"brick": "brick_wall",
		"concrete": "concrete_wall",
		"steel": "steel_wall",
		"reinforced_steel": "reinforced_steel_wall",
		"titanium": "titanium_wall",
		"energy_flow": "energy_wall"
	}
	if direct_map.has(value):
		return String(direct_map.get(value, ""))
	return ""

func get_mission_manager_ref() -> Node:
	var current: Node = self
	while current != null:
		if current.has_node("MissionManager"):
			return current.get_node("MissionManager")
		current = current.get_parent()
	return null

func is_outer_border_cell(cell: Vector2i) -> bool:
	if _grid_manager == null:
		return false
	var max_x: int = _grid_manager.get_map_width() - 1
	var max_y: int = _grid_manager.get_map_height() - 1
	if max_x < 0 or max_y < 0:
		return false
	return cell.x <= 0 or cell.y <= 0 or cell.x >= max_x or cell.y >= max_y

func get_iso_wall_top_points(cell: Vector2i) -> PackedVector2Array:
	var base_points: PackedVector2Array = get_iso_wall_base_points(cell)
	var top_points: PackedVector2Array = PackedVector2Array()
	var safe_wall_height: float = maxf(iso_wall_height, 1.0)
	for point in base_points:
		top_points.append(point + Vector2(0.0, -safe_wall_height))
	return top_points

func _is_wall_cell(cell: Vector2i) -> bool:
	if _grid_manager == null:
		return false
	return _grid_manager.get_tile(cell) == GridManager.TILE_WALL

func _is_wall_in_bounds(cell: Vector2i) -> bool:
	if _grid_manager == null:
		return false
	return cell.x >= 0 and cell.y >= 0 and cell.x < _grid_manager.get_map_width() and cell.y < _grid_manager.get_map_height()

func _get_wall_neighbor_mask(cell: Vector2i) -> Dictionary:
	var mask: Dictionary = {"north": false, "east": false, "south": false, "west": false}
	var deltas: Dictionary = {"north": Vector2i(0, -1), "east": Vector2i(1, 0), "south": Vector2i(0, 1), "west": Vector2i(-1, 0)}
	for key_variant in deltas.keys():
		var side: String = String(key_variant)
		var neighbor: Vector2i = cell + Vector2i(deltas.get(key_variant, Vector2i.ZERO))
		mask[side] = _is_wall_in_bounds(neighbor) and _is_wall_cell(neighbor)
	return mask

func _is_door_like_tile(tile_type: int) -> bool:
	return tile_type == GridManager.TILE_DOOR or tile_type == GridManager.TILE_DIGITAL_DOOR or tile_type == GridManager.TILE_POWERED_GATE

func _is_wall_mount_neighbor_visible(tile_type: int) -> bool:
	return (
		tile_type == GridManager.TILE_FLOOR
		or tile_type == GridManager.TILE_STEPPED_FLOOR
		or tile_type == GridManager.TILE_DOOR
		or tile_type == GridManager.TILE_DIGITAL_DOOR
		or tile_type == GridManager.TILE_POWERED_GATE
	)

func _get_wall_side_delta(side: String) -> Vector2i:
	match side:
		"north":
			return Vector2i(0, -1)
		"east":
			return Vector2i(1, 0)
		"south":
			return Vector2i(0, 1)
		"west":
			return Vector2i(-1, 0)
	return Vector2i.ZERO

func get_visible_wall_sides(cell: Vector2i) -> Array[String]:
	var sides: Array[String] = []
	if _grid_manager == null or not _is_wall_in_bounds(cell):
		return sides
	if _grid_manager.get_tile(cell) != GridManager.TILE_WALL:
		return sides
	for side in WALL_SIDE_ORDER:
		var delta: Vector2i = _get_wall_side_delta(side)
		var neighbor: Vector2i = cell + delta
		if not _is_wall_in_bounds(neighbor):
			sides.append(side)
			continue
		var tile_type: int = _grid_manager.get_tile(neighbor)
		if tile_type == GridManager.TILE_WALL:
			continue
		if _is_wall_mount_neighbor_visible(tile_type):
			sides.append(side)
	return sides

func get_wall_mounted_anchor_zones(cell: Vector2i) -> Array[Dictionary]:
	var zones: Array[Dictionary] = []
	if _grid_manager == null or not _is_wall_in_bounds(cell):
		return zones
	if _grid_manager.get_tile(cell) != GridManager.TILE_WALL:
		return zones
	for side in get_visible_wall_sides(cell):
		var delta: Vector2i = _get_wall_side_delta(side)
		var neighbor: Vector2i = cell + delta
		var mountable: bool = false
		if _is_wall_in_bounds(neighbor):
			var neighbor_tile: int = _grid_manager.get_tile(neighbor)
			mountable = _is_wall_mount_neighbor_visible(neighbor_tile) and not _is_door_like_tile(neighbor_tile)
		var wall_center: Vector2 = grid_to_iso(cell)
		var half_size: Vector2 = get_iso_tile_half_size()
		var axis: Vector2 = Vector2(float(delta.x) * half_size.x * 0.65, float(delta.y) * half_size.y * 0.65)
		var center: Vector2 = wall_center + axis
		var tangent: Vector2 = Vector2(-axis.y, axis.x).normalized() * 7.0
		var normal: Vector2 = axis.normalized() * 5.0
		var polygon: PackedVector2Array = PackedVector2Array([
			center - tangent - normal,
			center + tangent - normal,
			center + tangent + normal,
			center - tangent + normal
		])
		zones.append({
			"attached_wall_cell": cell,
			"anchor_floor_cell": neighbor,
			"wall_side": side,
			"visible": true,
			"mountable": mountable,
			"wall_mass_ratio": WALL_MASS_RATIO,
			"mount_band_ratio": WALL_MOUNT_BAND_RATIO,
			"mount_zone_center": center,
			"mount_zone_polygon": polygon,
			"interaction_cell": neighbor
		})
	return zones

func is_wall_adjacent_to_door(cell: Vector2i) -> bool:
	if _grid_manager == null:
		return false
	for delta in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
		var neighbor: Vector2i = cell + delta
		if not _is_wall_in_bounds(neighbor):
			continue
		if _is_door_like_tile(_grid_manager.get_tile(neighbor)):
			return true
	return false

func get_wall_render_topology(cell: Vector2i) -> Dictionary:
	var neighbors: Dictionary = _get_wall_neighbor_mask(cell)
	var visible_sides: Array[String] = get_visible_wall_sides(cell)
	var cap_sides: Array[String] = []
	var mountable_sides: Array[String] = []
	if not _is_wall_in_bounds(cell) or not _is_wall_cell(cell):
		return {
			"cell": cell,
			"neighbors": neighbors,
			"run_x": false,
			"run_y": false,
			"shape": "unknown",
			"visible_sides": visible_sides,
			"cap_sides": cap_sides,
			"mountable_sides": mountable_sides
		}

	var north: bool = bool(neighbors.get("north", false))
	var east: bool = bool(neighbors.get("east", false))
	var south: bool = bool(neighbors.get("south", false))
	var west: bool = bool(neighbors.get("west", false))
	var count: int = int(north) + int(east) + int(south) + int(west)
	var run_x: bool = east and west
	var run_y: bool = north and south
	var shape: String = "isolated"

	for side in WALL_SIDE_ORDER:
		if not bool(neighbors.get(side, false)):
			cap_sides.append(side)

	for side in visible_sides:
		var neighbor_cell: Vector2i = cell + _get_wall_side_delta(side)
		if not _is_wall_in_bounds(neighbor_cell):
			continue
		var neighbor_tile: int = _grid_manager.get_tile(neighbor_cell)
		if _is_wall_mount_neighbor_visible(neighbor_tile) and not _is_door_like_tile(neighbor_tile):
			mountable_sides.append(side)

	if count <= 0:
		shape = "isolated"
	elif count == 4:
		shape = "cross"
	elif count == 3:
		shape = "t_junction"
	elif count == 1:
		if north:
			shape = "end_cap_south"
		elif east:
			shape = "end_cap_west"
		elif south:
			shape = "end_cap_north"
		else:
			shape = "end_cap_east"
	elif run_x:
		shape = "straight_x"
	elif run_y:
		shape = "straight_y"
	elif north and east:
		if _is_wall_in_bounds(cell + Vector2i(1, -1)) and _is_wall_cell(cell + Vector2i(1, -1)):
			shape = "inner_corner_ne"
		else:
			shape = "outer_corner_ne"
	elif north and west:
		if _is_wall_in_bounds(cell + Vector2i(-1, -1)) and _is_wall_cell(cell + Vector2i(-1, -1)):
			shape = "inner_corner_nw"
		else:
			shape = "outer_corner_nw"
	elif south and east:
		if _is_wall_in_bounds(cell + Vector2i(1, 1)) and _is_wall_cell(cell + Vector2i(1, 1)):
			shape = "inner_corner_se"
		else:
			shape = "outer_corner_se"
	elif south and west:
		if _is_wall_in_bounds(cell + Vector2i(-1, 1)) and _is_wall_cell(cell + Vector2i(-1, 1)):
			shape = "inner_corner_sw"
		else:
			shape = "outer_corner_sw"

	return {
		"cell": cell,
		"neighbors": neighbors,
		"run_x": run_x,
		"run_y": run_y,
		"shape": shape,
		"visible_sides": visible_sides,
		"cap_sides": cap_sides,
		"mountable_sides": mountable_sides
	}

func classify_wall_topology(cell: Vector2i) -> String:
	if not _is_wall_in_bounds(cell) or not _is_wall_cell(cell):
		return "unknown"
	# Border walls must use the same topology-derived geometry as interior walls.
	# Treating every outer-border cell as a special boundary shape made edge
	# segments render with a different profile than matching center-map walls.
	if is_wall_adjacent_to_door(cell):
		return "door_adjacent"
	var topology: Dictionary = get_wall_render_topology(cell)
	return String(topology.get("shape", "isolated"))

func get_iso_architectural_wall_profile(topology: String, visual_material: Dictionary) -> Dictionary:
	var fallback_colors: Dictionary = get_wall_prototype_colors(Vector2i.ZERO)
	var material_id: String = String(visual_material.get("id", visual_material.get("material_id", "default_wall"))).strip_edges()
	var base_color: Color = Color(visual_material.get("fallback_color", fallback_colors.get("top", Color(0.2, 0.2, 0.24, 1.0))))
	var edge_color: Color = Color(visual_material.get("edge_color", fallback_colors.get("outline", Color(0.3, 0.3, 0.35, 1.0))))
	var safe_topology: String = topology if not topology.is_empty() else "isolated"
	var corner: bool = safe_topology.contains("corner_")
	return {
		"base_color": base_color.darkened(0.2),
		"side_color": base_color.darkened(0.33),
		"top_color": base_color.lightened(0.08),
		"edge_color": edge_color,
		"shadow_color": Color(0.03, 0.04, 0.05, 0.36),
		"height_px": maxi(int(iso_wall_height), 18),
		"cap_enabled": true,
		"corner_emphasis": 1.25 if corner else 1.0,
		"damage_overlay_strength": 0.45 if material_id.find("damaged") >= 0 else 0.0,
		"wall_mass_ratio": WALL_MASS_RATIO,
		"mount_band_ratio": WALL_MOUNT_BAND_RATIO,
		"mount_band_color": base_color.lightened(0.12),
		"mount_band_edge_color": edge_color.lightened(0.12),
		"mount_band_enabled": true,
		"material_id": material_id,
		"topology": safe_topology
	}

func draw_iso_wall_block(cell: Vector2i) -> void:
	if should_skip_full_wall_for_door_opening(cell):
		return
	var render_topology: Dictionary = get_wall_render_topology(cell)
	var base_points: PackedVector2Array = get_iso_wall_connected_base_points(cell, render_topology)
	if base_points.size() < 4:
		return
	var top_points: PackedVector2Array = get_iso_wall_top_points(cell)
	if top_points.size() < 4:
		return

	var colors: Dictionary = get_wall_prototype_colors(cell)
	var topology: String = classify_wall_topology(cell)
	var material_override: Dictionary = _get_wall_material_override_for_cell(cell)
	var material_row: Dictionary = Dictionary(material_override.get("material", {}))
	var arch: Dictionary = get_iso_architectural_wall_profile(topology, material_row)
	var wall_profile_key: String = get_wall_visual_profile_key_for_cell(cell)
	var top_face: PackedVector2Array = PackedVector2Array([top_points[0], top_points[1], top_points[2], top_points[3]])
	var left_face: PackedVector2Array = PackedVector2Array([top_points[3], top_points[2], base_points[2], base_points[3]])
	var right_face: PackedVector2Array = PackedVector2Array([top_points[2], top_points[1], base_points[1], base_points[2]])
	var floor_shadow: PackedVector2Array = PackedVector2Array([base_points[2], base_points[3], base_points[3] + Vector2(0.0, 8.0), base_points[2] + Vector2(0.0, 8.0)])
	var accent_color: Color = _get_color_from_dict(colors, "accent", Color.WHITE)

	# Standalone walls normally stay on the same procedural architectural path as
	# connected runs. The TASK TEST smoke hook below is visual-only, concrete-only,
	# and falls through to this procedural path whenever the temporary PNG is not
	# available.
	if draw_iso_concrete_wall_smoke_texture_for_cell(cell, wall_profile_key):
		draw_iso_wall_debug_and_mount_overlays(cell, arch, topology)
		return

	var alpha_mult: float = 1.0
	if iso_wall_cutaway_enabled and is_wall_adjacent_to_door(cell):
		alpha_mult = 0.65

	var left_color: Color = Color(arch.get("base_color", _get_color_from_dict(colors, "left", Color.WHITE)))
	var right_color: Color = Color(arch.get("side_color", _get_color_from_dict(colors, "right", Color.WHITE)))
	var top_color: Color = Color(arch.get("top_color", _get_color_from_dict(colors, "top", Color.WHITE)))
	var outline_color: Color = Color(arch.get("edge_color", _get_color_from_dict(colors, "outline", Color.WHITE)))
	left_color.a *= alpha_mult
	right_color.a *= alpha_mult
	top_color.a *= alpha_mult

	draw_colored_polygon(left_face, left_color)
	draw_colored_polygon(right_face, right_color)
	if bool(arch.get("cap_enabled", true)) or topology.find("corner_") >= 0 or topology.begins_with("straight_") or topology == "t_junction" or topology == "cross":
		draw_colored_polygon(top_face, top_color)
	draw_colored_polygon(floor_shadow, Color(arch.get("shadow_color", Color(0.0, 0.0, 0.0, 0.25))))

	if debug_draw_iso_wall_outlines:
		for top_edge_idx in range(top_face.size()):
			var top_next_idx: int = (top_edge_idx + 1) % top_face.size()
			draw_line(top_face[top_edge_idx], top_face[top_next_idx], outline_color, 1.0)

		for left_edge_idx in range(left_face.size()):
			var left_next_idx: int = (left_edge_idx + 1) % left_face.size()
			draw_line(left_face[left_edge_idx], left_face[left_next_idx], outline_color, 1.0)

		for right_edge_idx in range(right_face.size()):
			var right_next_idx: int = (right_edge_idx + 1) % right_face.size()
			draw_line(right_face[right_edge_idx], right_face[right_next_idx], outline_color, 1.0)

	var accent_start: Vector2 = top_points[3].lerp(top_points[0], 0.4)
	var accent_end: Vector2 = top_points[0].lerp(top_points[1], 0.45)
	draw_line(accent_start, accent_end, accent_color, 1.2)
	draw_iso_wall_surface_accent(left_face, right_face, top_face, wall_profile_key, accent_color)
	draw_iso_wall_debug_and_mount_overlays(cell, arch, topology)

func draw_iso_wall_debug_and_mount_overlays(cell: Vector2i, arch: Dictionary, topology: String) -> void:
	if show_wall_topology_overlay:
		draw_string(ThemeDB.fallback_font, grid_to_iso(cell) + Vector2(-20.0, -float(arch.get("height_px", 24)) - 4.0), topology, HORIZONTAL_ALIGNMENT_LEFT, 56.0, 9, Color(0.95, 0.96, 1.0, 0.9))
	var mount_zones: Array[Dictionary] = get_wall_mounted_anchor_zones(cell)
	if bool(arch.get("mount_band_enabled", true)):
		for zone_variant in mount_zones:
			var zone: Dictionary = Dictionary(zone_variant)
			if not bool(zone.get("mountable", false)):
				continue
			var mount_poly: PackedVector2Array = PackedVector2Array(zone.get("mount_zone_polygon", PackedVector2Array()))
			if mount_poly.size() >= 3:
				draw_colored_polygon(mount_poly, Color(arch.get("mount_band_color", Color(0.6, 0.62, 0.66, 0.35))))
				if debug_draw_iso_wall_outlines:
					draw_polyline(mount_poly, Color(arch.get("mount_band_edge_color", Color.WHITE)), 1.1, true)

func draw_iso_wall_surface_accent(
	left_face: PackedVector2Array,
	right_face: PackedVector2Array,
	top_face: PackedVector2Array,
	profile_key: String,
	accent_color: Color
) -> void:
	var accent_key: String = normalize_wall_visual_profile_key(profile_key)
	match accent_key:
		"brick_wall":
			draw_iso_wall_brick_accent(left_face, right_face, accent_color)
		"concrete_wall":
			draw_iso_wall_concrete_accent(left_face, right_face, top_face, accent_color)
		"steel_wall", "reinforced_steel_wall", "titanium_wall":
			draw_iso_wall_steel_accent(left_face, right_face, top_face, accent_color)
		"grate_wall":
			draw_iso_wall_grate_accent(left_face, right_face, accent_color)

func draw_iso_wall_brick_accent(left_face: PackedVector2Array, right_face: PackedVector2Array, accent_color: Color) -> void:
	var mortar_color: Color = accent_color.lightened(0.05)
	for row in [0.22, 0.45, 0.68, 0.88]:
		draw_line(left_face[0].lerp(left_face[3], row), left_face[1].lerp(left_face[2], row), mortar_color, 1.3)
		draw_line(right_face[0].lerp(right_face[3], row), right_face[1].lerp(right_face[2], row), mortar_color, 1.3)

func draw_iso_wall_concrete_accent(
	left_face: PackedVector2Array,
	right_face: PackedVector2Array,
	_top_face: PackedVector2Array,
	accent_color: Color
) -> void:
	var crack_color: Color = accent_color.darkened(0.28)
	draw_line(left_face[0].lerp(left_face[1], 0.26), left_face[2].lerp(left_face[3], 0.7), crack_color, 1.15)
	draw_line(right_face[0].lerp(right_face[1], 0.64), right_face[2].lerp(right_face[3], 0.22), crack_color, 1.15)
	var panel_color: Color = accent_color.lightened(0.04)
	draw_line(left_face[0].lerp(left_face[3], 0.52), left_face[1].lerp(left_face[2], 0.52), panel_color, 1.0)
	draw_line(right_face[0].lerp(right_face[3], 0.48), right_face[1].lerp(right_face[2], 0.48), panel_color, 1.0)

func draw_iso_wall_steel_accent(
	left_face: PackedVector2Array,
	right_face: PackedVector2Array,
	top_face: PackedVector2Array,
	accent_color: Color
) -> void:
	var seam_color: Color = accent_color.lightened(0.1)
	draw_line(left_face[0].lerp(left_face[1], 0.5), left_face[3].lerp(left_face[2], 0.5), seam_color, 1.25)
	draw_line(right_face[0].lerp(right_face[1], 0.5), right_face[3].lerp(right_face[2], 0.5), seam_color, 1.25)
	draw_line(top_face[3].lerp(top_face[0], 0.5), top_face[2].lerp(top_face[1], 0.5), seam_color, 1.1)
	var rivet_color: Color = accent_color.lightened(0.3)
	for side_point in [left_face[1], left_face[2], right_face[1], right_face[2]]:
		draw_circle(side_point.lerp(top_face[2], 0.08), 1.2, rivet_color)

func draw_iso_wall_grate_accent(left_face: PackedVector2Array, right_face: PackedVector2Array, accent_color: Color) -> void:
	var bar_color: Color = accent_color.lightened(0.2)
	var gap_color: Color = Color(0.02, 0.03, 0.04, 0.95)
	for band in [0.3, 0.7]:
		var left_gap: PackedVector2Array = PackedVector2Array([
			left_face[0].lerp(left_face[1], band - 0.08),
			left_face[0].lerp(left_face[1], band + 0.08),
			left_face[3].lerp(left_face[2], band + 0.08),
			left_face[3].lerp(left_face[2], band - 0.08)
		])
		var right_gap: PackedVector2Array = PackedVector2Array([
			right_face[0].lerp(right_face[1], band - 0.08),
			right_face[0].lerp(right_face[1], band + 0.08),
			right_face[3].lerp(right_face[2], band + 0.08),
			right_face[3].lerp(right_face[2], band - 0.08)
		])
		draw_colored_polygon(left_gap, gap_color)
		draw_colored_polygon(right_gap, gap_color)
	for column in [0.16, 0.5, 0.84]:
		draw_line(left_face[0].lerp(left_face[1], column), left_face[3].lerp(left_face[2], column), bar_color, 1.7)
		draw_line(right_face[0].lerp(right_face[1], column), right_face[3].lerp(right_face[2], column), bar_color, 1.7)

func _safe_variant_dictionary(value: Variant, should_duplicate: bool = false) -> Dictionary:
	if value is Dictionary:
		var dictionary: Dictionary = Dictionary(value)
		return dictionary.duplicate(true) if should_duplicate else dictionary
	return {}

func get_floor_atlas_cell_size() -> Vector2:
	if iso_floor_atlas_texture == null:
		return Vector2.ZERO
	return Vector2(
		float(iso_floor_atlas_texture.get_width()) / float(ISO_FLOOR_ATLAS_COLUMNS),
		float(iso_floor_atlas_texture.get_height()) / float(ISO_FLOOR_ATLAS_ROWS)
	)

func get_floor_atlas_region(row: int, atlas_position: int) -> Rect2:
	var cell_size: Vector2 = get_floor_atlas_cell_size()
	if cell_size.x <= 0.0 or cell_size.y <= 0.0:
		return Rect2()
	var safe_row: int = clampi(row, 1, ISO_FLOOR_ATLAS_ROWS)
	var safe_position: int = clampi(atlas_position, 1, ISO_FLOOR_ATLAS_COLUMNS)
	return Rect2(Vector2(float(safe_position - 1) * cell_size.x, float(safe_row - 1) * cell_size.y), cell_size)

func get_floor_state_for_cell(cell: Vector2i) -> Dictionary:
	var fallback: Dictionary = {"family": "metal", "wear": "none", "base_variant": -1, "overlay_variant": -1, "mirror_h": false, "mirror_v": false}
	if _grid_manager == null or not _grid_manager.has_method("get_floor_visual_state"):
		return fallback
	var state: Dictionary = _safe_variant_dictionary(_grid_manager.call("get_floor_visual_state", cell), true)
	return state if not state.is_empty() else fallback

func get_floor_base_atlas_key(family: String) -> String:
	match family:
		"grate":
			return "grate_base"
		"concrete":
			return "concrete_base"
		_:
			return "metal_base"

func get_floor_overlay_atlas_key(family: String, wear: String) -> String:
	if wear == "light_wear":
		if family == "concrete":
			return "concrete_light_wear"
		if family == "metal":
			return "metal_light_wear"
	elif wear == "heavy_damage":
		if family == "concrete":
			return "concrete_heavy_damage"
		if family == "metal":
			return "metal_heavy_damage"
	return ""

func get_floor_atlas_variant_for_cell(cell: Vector2i, requested_variant: int, max_variants: int, salt: int = 0) -> int:
	if max_variants <= 0:
		return 1
	if requested_variant >= 1:
		return clampi(requested_variant, 1, max_variants)
	return ((cell.x * 17 + cell.y * 31 + salt) % max_variants) + 1

func get_floor_atlas_seam_safe_variant(cell: Vector2i, atlas_key: String, requested_variant: int, max_variants: int, salt: int = 0) -> int:
	# Base rows in the current atlas contain visible perimeter differences between
	# variants.  Keep each floor family on a fixed seam-safe subset so every tile
	# in the family shares the same silhouette, frame thickness, and edge lighting.
	if ISO_FLOOR_SEAM_SAFE_BASE_VARIANTS.has(atlas_key):
		var safe_variants: Array = Array(ISO_FLOOR_SEAM_SAFE_BASE_VARIANTS.get(atlas_key, []))
		if safe_variants.is_empty():
			return 1
		var safe_index: int = 0
		if requested_variant < 1 and safe_variants.size() > 1:
			safe_index = (cell.x * 17 + cell.y * 31 + salt) % safe_variants.size()
		return clampi(int(safe_variants[safe_index]), 1, max_variants)
	return get_floor_atlas_variant_for_cell(cell, requested_variant, max_variants, salt)

func get_floor_atlas_safe_source_rect(source_rect: Rect2) -> Rect2:
	var padding: float = minf(
		ISO_FLOOR_ATLAS_SOURCE_EDGE_PADDING,
		minf(source_rect.size.x, source_rect.size.y) * 0.25
	)
	if padding <= 0.0:
		return source_rect
	return Rect2(source_rect.position + Vector2(padding, padding), source_rect.size - Vector2(padding * 2.0, padding * 2.0))

func get_floor_atlas_destination_rect() -> Rect2:
	var half_size: Vector2 = get_iso_tile_half_size()
	var destination_size: Vector2 = half_size * 2.0 + Vector2(ISO_FLOOR_ATLAS_SCREEN_OVERLAP * 2.0, ISO_FLOOR_ATLAS_SCREEN_OVERLAP * 2.0)
	return Rect2(destination_size * -0.5, destination_size)

func get_iso_diamond_points_with_overlap(cell: Vector2i, overlap: float) -> PackedVector2Array:
	if overlap <= 0.0:
		return get_iso_diamond_points(cell)
	var center_point: Vector2 = grid_to_iso(cell)
	var points: PackedVector2Array = PackedVector2Array()
	for point in get_iso_diamond_points(cell):
		var away_from_center: Vector2 = point - center_point
		if away_from_center.length() <= 0.0001:
			points.append(point)
		else:
			points.append(point + away_from_center.normalized() * overlap)
	return points

func draw_floor_seamless_underlay(cell: Vector2i, fill_color: Color) -> void:
	# Draw a tiny overlapping solid diamond below the atlas art.  This masks
	# transparent atlas margins and sub-pixel rasterization holes while preserving
	# the atlas details drawn above it.
	var underlay_points: PackedVector2Array = get_iso_diamond_points_with_overlap(cell, ISO_FLOOR_UNDERLAY_OVERLAP)
	draw_colored_polygon(underlay_points, fill_color)

func draw_procedural_floor_tile(cell: Vector2i, fill_color: Color, profile: Dictionary, draw_edge_borders: bool) -> void:
	# Standard floor path: one full-size procedural diamond per logical cell.
	# This deliberately avoids PNG/atlas padding, crop boxes, texture anchors, and
	# per-material footprints so adjacent cells cover the whole isometric grid.
	var diamond_points: PackedVector2Array = get_iso_diamond_points(cell)
	if diamond_points.size() < 4:
		return
	var base_color: Color = Color(fill_color.r, fill_color.g, fill_color.b, maxf(fill_color.a, 0.98))
	draw_colored_polygon(diamond_points, base_color)
	var panel_color: Color = _get_color_from_dict(profile, "panel", Color(0.18, 0.2, 0.24, 0.26))
	var seam_color: Color = _get_color_from_dict(profile, "seam", Color(0.36, 0.42, 0.48, 0.24))
	var panel_points: PackedVector2Array = get_iso_inset_diamond_points(cell, iso_floor_visual_inset + 8.0)
	if panel_points.size() >= 4:
		for panel_edge_index in range(panel_points.size()):
			var panel_next_index: int = (panel_edge_index + 1) % panel_points.size()
			draw_line(panel_points[panel_edge_index], panel_points[panel_next_index], panel_color, 0.45)
	var center_point: Vector2 = grid_to_iso(cell)
	draw_line(diamond_points[3].lerp(center_point, 0.2), diamond_points[1].lerp(center_point, 0.2), seam_color, 0.55)
	if draw_edge_borders or debug_draw_iso_cell_outlines:
		var outline_color: Color = _get_color_from_dict(profile, "outline", Color(0.21, 0.33, 0.39, 0.72))
		for side in WALL_SIDE_ORDER:
			var edge_points: Array[Vector2] = get_iso_diamond_edge_points(diamond_points, side)
			if edge_points.size() < 2:
				continue
			if debug_draw_iso_cell_outlines or should_draw_floor_edge_border(cell, side):
				draw_line(edge_points[0], edge_points[1], outline_color, 0.65)
	if debug_floor_tile_bounds:
		draw_floor_tile_bounds_debug(cell)

func draw_procedural_floor_debug_tile(cell: Vector2i, fill_color: Color) -> void:
	# Diagnostic floor renderer: uses only vector geometry with the same
	# grid_to_iso projection as floor placement. If this stitches cleanly while
	# an atlas does not, the issue is source art/sampling rather than placement.
	var profile: Dictionary = {
		"outline": Color(0.0, 1.0, 1.0, 0.95),
		"panel": Color(1.0, 1.0, 0.0, 0.38),
		"seam": Color(1.0, 0.0, 1.0, 0.55)
	}
	draw_procedural_floor_tile(cell, fill_color.lightened(0.1), profile, true)
	if not debug_floor_tile_bounds:
		draw_floor_tile_bounds_debug(cell)

func draw_floor_tile_bounds_debug(cell: Vector2i) -> void:
	var diamond_points: PackedVector2Array = get_iso_diamond_points(cell)
	if diamond_points.size() < 4:
		return
	var center_point: Vector2 = grid_to_iso(cell)
	var half_size: Vector2 = get_iso_tile_half_size()
	var destination_rect: Rect2 = Rect2(center_point - half_size, half_size * 2.0)
	var corner_color: Color = Color(1.0, 0.2, 0.2, 0.95)
	var axis_color: Color = Color(1.0, 0.92, 0.18, 0.82)
	var rect_color: Color = Color(0.2, 1.0, 0.45, 0.5)
	for edge_index in range(diamond_points.size()):
		var next_index: int = (edge_index + 1) % diamond_points.size()
		draw_line(diamond_points[edge_index], diamond_points[next_index], Color(0.0, 0.95, 1.0, 0.95), 1.5)
		draw_circle(diamond_points[edge_index], 2.4, corner_color)
	draw_rect(destination_rect, rect_color, false, 1.0)
	draw_line(center_point + Vector2(-half_size.x, 0.0), center_point + Vector2(half_size.x, 0.0), axis_color, 0.7)
	draw_line(center_point + Vector2(0.0, -half_size.y), center_point + Vector2(0.0, half_size.y), axis_color, 0.7)
	draw_circle(center_point, 2.6, Color(1.0, 1.0, 1.0, 0.95))
	draw_string(ThemeDB.fallback_font, center_point + Vector2(4.0, -4.0), "%d,%d" % [cell.x, cell.y], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(1.0, 1.0, 1.0, 0.9))

func get_floor_atlas_inner_overlay_points() -> PackedVector2Array:
	var destination_rect: Rect2 = get_floor_atlas_destination_rect()
	var inset: float = minf(ISO_FLOOR_OVERLAY_INNER_INSET, minf(destination_rect.size.x, destination_rect.size.y) * 0.35)
	return PackedVector2Array([
		Vector2(destination_rect.position.x + destination_rect.size.x * 0.5, destination_rect.position.y + inset),
		Vector2(destination_rect.end.x - inset, destination_rect.position.y + destination_rect.size.y * 0.5),
		Vector2(destination_rect.position.x + destination_rect.size.x * 0.5, destination_rect.end.y - inset),
		Vector2(destination_rect.position.x + inset, destination_rect.position.y + destination_rect.size.y * 0.5),
	])

func get_floor_atlas_uvs_for_destination_points(points: PackedVector2Array, destination_rect: Rect2, source_rect: Rect2) -> PackedVector2Array:
	var uvs: PackedVector2Array = PackedVector2Array()
	if destination_rect.size.x <= 0.0 or destination_rect.size.y <= 0.0:
		return uvs
	for point in points:
		var normalized_point: Vector2 = Vector2(
			(point.x - destination_rect.position.x) / destination_rect.size.x,
			(point.y - destination_rect.position.y) / destination_rect.size.y
		)
		uvs.append(source_rect.position + Vector2(normalized_point.x * source_rect.size.x, normalized_point.y * source_rect.size.y))
	return uvs

func draw_floor_atlas_overlay_layer(cell: Vector2i, source_rect: Rect2) -> void:
	# Wear/damage rows are detail overlays only.  Clip them to an inset diamond so
	# scratches and damage cannot rewrite the shared perimeter or create edge seams.
	var center: Vector2 = grid_to_iso(cell)
	var safe_source_rect: Rect2 = get_floor_atlas_safe_source_rect(source_rect)
	var destination_rect: Rect2 = get_floor_atlas_destination_rect()
	var overlay_points: PackedVector2Array = get_floor_atlas_inner_overlay_points()
	var overlay_uvs: PackedVector2Array = get_floor_atlas_uvs_for_destination_points(overlay_points, destination_rect, safe_source_rect)
	if overlay_points.size() < 4 or overlay_uvs.size() != overlay_points.size():
		return
	draw_set_transform(center.round(), 0.0, Vector2.ONE)
	draw_polygon(overlay_points, PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]), overlay_uvs, iso_floor_atlas_texture)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func draw_floor_atlas_layer(cell: Vector2i, atlas_key: String, requested_variant: int, mirror_h: bool, mirror_v: bool) -> bool:
	if iso_floor_atlas_texture == null:
		return false
	if not ISO_FLOOR_ATLAS_LAYOUT.has(atlas_key):
		return false
	var layout: Dictionary = _safe_variant_dictionary(ISO_FLOOR_ATLAS_LAYOUT.get(atlas_key, {}))
	if layout.is_empty():
		return false
	var row: int = int(layout.get("row", 1))
	var variant_count: int = int(layout.get("variants", ISO_FLOOR_ATLAS_BASE_VARIANTS))
	var is_overlay: bool = bool(layout.get("overlay", false))
	var variant: int = get_floor_atlas_seam_safe_variant(cell, atlas_key, requested_variant, variant_count, row * 13)
	var source_rect: Rect2 = get_floor_atlas_region(row, variant)
	if source_rect.size.x <= 0.0 or source_rect.size.y <= 0.0:
		return false
	if is_overlay:
		draw_floor_atlas_overlay_layer(cell, source_rect)
		return true
	var center: Vector2 = grid_to_iso(cell)
	# Sample slightly inside each high-resolution atlas frame to avoid bleeding
	# bright pixels from neighboring frames, then overdraw by a pixel on screen to
	# cover fractional-pixel cracks between adjacent projected cells.
	var safe_source_rect: Rect2 = get_floor_atlas_safe_source_rect(source_rect)
	var destination_rect: Rect2 = get_floor_atlas_destination_rect()
	var safe_mirror_h: bool = false if ISO_FLOOR_SEAM_SAFE_BASE_VARIANTS.has(atlas_key) else mirror_h
	var safe_mirror_v: bool = false if ISO_FLOOR_SEAM_SAFE_BASE_VARIANTS.has(atlas_key) else mirror_v
	var visual_scale: Vector2 = Vector2(-1.0 if safe_mirror_h else 1.0, -1.0 if safe_mirror_v else 1.0)
	draw_set_transform(center.round(), 0.0, visual_scale)
	draw_texture_rect_region(iso_floor_atlas_texture, destination_rect, safe_source_rect, Color.WHITE, false, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true

func draw_iso_floor_atlas_for_cell(cell: Vector2i) -> bool:
	if iso_floor_atlas_texture == null:
		return false
	var state: Dictionary = get_floor_state_for_cell(cell)
	var family: String = String(state.get("family", "metal"))
	var wear: String = String(state.get("wear", "none"))
	var mirror_h: bool = bool(state.get("mirror_h", false))
	var mirror_v: bool = bool(state.get("mirror_v", false))
	var base_key: String = get_floor_base_atlas_key(family)
	var base_drawn: bool = draw_floor_atlas_layer(cell, base_key, int(state.get("base_variant", -1)), mirror_h, mirror_v)
	var overlay_key: String = get_floor_overlay_atlas_key(family, wear)
	if not overlay_key.is_empty():
		draw_floor_atlas_layer(cell, overlay_key, int(state.get("overlay_variant", -1)), mirror_h, mirror_v)
	return base_drawn

func draw_iso_floor_prototype() -> void:
	# Procedural prototype floor renderer for early isometric look exploration.
	# Gameplay remains square-grid based in GridManager; this is visual-only.
	if _grid_manager == null:
		return

	var map_width: int = _grid_manager.get_map_width()
	var map_height: int = _grid_manager.get_map_height()
	if map_width <= 0 or map_height <= 0:
		return

	for y in range(map_height):
		for x in range(map_width):
			var cell: Vector2i = Vector2i(x, y)
			var tile_type: int = _grid_manager.get_tile(cell)
			if not is_floor_like_tile(tile_type):
				continue

			var floor_asset_key: String = get_iso_floor_asset_key_for_tile(tile_type)
			var draw_cell_border: bool = should_draw_floor_cell_border(cell)
			var floor_inset: float = 0.0
			if draw_cell_border:
				floor_inset = maxf(iso_floor_visual_inset * 0.35, 0.0)
			var diamond_points: PackedVector2Array = get_iso_inset_diamond_points(cell, floor_inset)
			var profile_key: String = get_iso_floor_visual_profile_key_for_cell(cell)
			var profile: Dictionary = get_iso_floor_visual_profile(profile_key)
			var fill_color: Color = _get_color_from_dict(profile, "fill", get_floor_prototype_color(tile_type, cell))
			var mission_manager: Node = get_mission_manager_ref()
			var floor_texture_asset_id: String = ""
			if mission_manager != null and mission_manager.has_method("get_map_constructor_floor_material_for_cell"):
				var floor_material_result: Dictionary = _safe_variant_dictionary(mission_manager.call("get_map_constructor_floor_material_for_cell", cell))
				if bool(floor_material_result.get("ok", false)):
					var floor_material: Dictionary = _safe_variant_dictionary(floor_material_result.get("material", {}))
					fill_color = Color(floor_material.get("fallback_color", fill_color))
					floor_texture_asset_id = String(floor_material.get("texture_asset_id", "")).strip_edges()
			if use_procedural_floor_debug_tiles:
				draw_procedural_floor_debug_tile(cell, fill_color)
				continue
			# Default to the procedural renderer so every material/coating shares the
			# exact same full-cell footprint and center anchor. The old floor atlas and
			# legacy texture hooks are opt-in only until their padding/footprints are
			# normalized to this geometry.
			if use_iso_floor_atlas_textures:
				draw_floor_seamless_underlay(cell, fill_color)
				if draw_iso_floor_atlas_for_cell(cell):
					if debug_floor_tile_bounds:
						draw_floor_tile_bounds_debug(cell)
					continue
			if allow_legacy_floor_texture_assets:
				if not floor_texture_asset_id.is_empty() and draw_cell_border:
					var floor_asset_drawn: bool = draw_optional_visual_texture_asset(floor_texture_asset_id, cell, "", {"visual_center": grid_to_iso(cell)})
					if floor_asset_drawn:
						if debug_floor_tile_bounds:
							draw_floor_tile_bounds_debug(cell)
						continue
				if draw_cell_border and draw_iso_texture_asset(cell, floor_asset_key):
					if debug_floor_tile_bounds:
						draw_floor_tile_bounds_debug(cell)
					continue
			draw_procedural_floor_tile(cell, fill_color, profile, draw_cell_border)
			if diamond_points.size() >= 4:
				var seam_color: Color = _get_color_from_dict(profile, "seam", Color(0.36, 0.42, 0.48, 0.26))
				if profile_key == "floor_passage":
					draw_line(diamond_points[0].lerp(diamond_points[2], 0.32), diamond_points[0].lerp(diamond_points[2], 0.68), seam_color.lightened(0.03), 0.8)
				elif profile_key == "floor_doorway":
					draw_line(diamond_points[0].lerp(diamond_points[2], 0.42), diamond_points[0].lerp(diamond_points[2], 0.58), seam_color, 1.4)

func draw_iso_wall_prototype() -> void:
	if _grid_manager == null:
		return

	var map_width: int = _grid_manager.get_map_width()
	var map_height: int = _grid_manager.get_map_height()
	if map_width <= 0 or map_height <= 0:
		return

	var wall_cells: Array[Vector2i] = []
	for y in range(map_height):
		for x in range(map_width):
			var cell: Vector2i = Vector2i(x, y)
			var tile_type: int = _grid_manager.get_tile(cell)
			if is_wall_tile(tile_type):
				wall_cells.append(cell)

	wall_cells.sort_custom(sort_cells_by_iso_depth)
	for cell in wall_cells:
		draw_iso_wall_block(cell)

func get_iso_object_visual_profiles() -> Dictionary:
	# Visual-only object profile mapping for BIP-Visual-007.
	# Final asset rendering and gameplay metadata wiring will be added later.
	return {
		"door": {"base": Color(0.33, 0.22, 0.12, 0.96), "accent": Color(0.98, 0.74, 0.26, 0.98), "outline": Color(0.2, 0.13, 0.07, 0.94), "label": "Door", "shape": "door_panel"},
		"digital_door": {"base": Color(0.15, 0.25, 0.33, 0.95), "accent": Color(0.36, 0.73, 0.88, 0.95), "outline": Color(0.08, 0.15, 0.2, 0.92), "label": "Digital Door", "shape": "slab"},
		"powered_gate": {"base": Color(0.17, 0.22, 0.3, 0.95), "accent": Color(0.43, 0.81, 0.94, 0.95), "outline": Color(0.1, 0.15, 0.2, 0.92), "label": "Powered Gate", "shape": "slab"},
		"terminal": {"base": Color(0.14, 0.24, 0.29, 0.96), "accent": Color(0.34, 0.95, 1.0, 0.98), "outline": Color(0.07, 0.14, 0.18, 0.94), "label": "Terminal", "shape": "terminal_console"},
		"airflow_terminal": {"base": Color(0.14, 0.22, 0.28, 0.96), "accent": Color(0.5, 0.88, 0.98, 0.98), "outline": Color(0.07, 0.13, 0.17, 0.94), "label": "Airflow Terminal", "shape": "terminal_console"},
		"door_terminal": {"base": Color(0.15, 0.23, 0.28, 0.97), "accent": Color(0.4, 0.94, 1.0, 0.99), "outline": Color(0.08, 0.14, 0.18, 0.94), "label": "Door Terminal", "shape": "wall_terminal_panel"},
		"platform_terminal": {"base": Color(0.16, 0.27, 0.24, 0.97), "accent": Color(0.48, 0.98, 0.78, 0.99), "outline": Color(0.08, 0.16, 0.14, 0.94), "label": "Platform Terminal", "shape": "wall_terminal_panel"},
		"cooling_terminal": {"base": Color(0.14, 0.21, 0.29, 0.97), "accent": Color(0.58, 0.85, 1.0, 0.99), "outline": Color(0.08, 0.13, 0.18, 0.94), "label": "Cooling Terminal", "shape": "wall_terminal_panel"},
		"firewall": {"base": Color(0.32, 0.16, 0.14, 0.97), "accent": Color(1.0, 0.54, 0.2, 0.99), "outline": Color(0.22, 0.1, 0.08, 0.94), "label": "Firewall", "shape": "wall_firewall_panel"},
		"circuit_breaker": {"base": Color(0.22, 0.23, 0.24, 0.97), "accent": Color(0.95, 0.88, 0.52, 0.99), "outline": Color(0.13, 0.14, 0.15, 0.94), "label": "Circuit Breaker", "shape": "wall_breaker_box"},
		"fuse_box": {"base": Color(0.2, 0.21, 0.24, 0.97), "accent": Color(0.72, 0.82, 0.92, 0.99), "outline": Color(0.12, 0.13, 0.16, 0.94), "label": "Fuse Box", "shape": "wall_fuse_box"},
		"light_switch": {"base": Color(0.26, 0.25, 0.23, 0.97), "accent": Color(0.98, 0.94, 0.75, 0.99), "outline": Color(0.14, 0.13, 0.12, 0.94), "label": "Light Switch", "shape": "wall_light_switch"},
		"power_cable_reel": {"base": Color(0.2, 0.2, 0.22, 0.97), "accent": Color(0.89, 0.76, 0.47, 0.99), "outline": Color(0.11, 0.11, 0.12, 0.94), "label": "Power Cable Reel", "shape": "wall_cable_reel"},
		"exit": {"base": Color(0.14, 0.3, 0.21, 0.95), "accent": Color(0.48, 0.95, 0.69, 0.95), "outline": Color(0.07, 0.16, 0.11, 0.92), "label": "Exit", "shape": "slab"},
		"key": {"base": Color(0.31, 0.26, 0.12, 0.95), "accent": Color(0.95, 0.83, 0.35, 0.95), "outline": Color(0.2, 0.16, 0.08, 0.92), "label": "Key", "shape": "small_marker"},
		"component": {"base": Color(0.25, 0.25, 0.3, 0.95), "accent": Color(0.72, 0.72, 0.85, 0.95), "outline": Color(0.14, 0.14, 0.17, 0.92), "label": "Component", "shape": "pillar"},
		"hidden_route_node": {"base": Color(0.17, 0.18, 0.27, 0.95), "accent": Color(0.6, 0.58, 0.92, 0.95), "outline": Color(0.1, 0.1, 0.18, 0.92), "label": "Hidden Route Node", "shape": "small_marker"},
		"route_gate": {"base": Color(0.2, 0.2, 0.31, 0.95), "accent": Color(0.64, 0.62, 0.95, 0.95), "outline": Color(0.11, 0.11, 0.2, 0.92), "label": "Route Gate", "shape": "slab"},
		"hot_node": {"base": Color(0.35, 0.15, 0.11, 0.95), "accent": Color(0.96, 0.48, 0.2, 0.95), "outline": Color(0.24, 0.1, 0.08, 0.92), "label": "Hot Node", "shape": "heat_marker"},
		"fan_platform": {"base": Color(0.18, 0.24, 0.29, 0.95), "accent": Color(0.58, 0.78, 0.89, 0.95), "outline": Color(0.1, 0.14, 0.18, 0.92), "label": "Fan Platform", "shape": "slab"},
		"platform_control": {"base": Color(0.2, 0.29, 0.29, 0.95), "accent": Color(0.56, 0.92, 0.88, 0.95), "outline": Color(0.1, 0.16, 0.16, 0.92), "label": "Platform Control", "shape": "small_marker"},
		"fan_control": {"base": Color(0.19, 0.25, 0.29, 0.95), "accent": Color(0.57, 0.82, 0.93, 0.95), "outline": Color(0.1, 0.14, 0.17, 0.92), "label": "Fan Control", "shape": "small_marker"},
		"fan_speed_control": {"base": Color(0.23, 0.26, 0.3, 0.95), "accent": Color(0.77, 0.88, 0.95, 0.95), "outline": Color(0.12, 0.14, 0.18, 0.92), "label": "Fan Speed Control", "shape": "small_marker"},
		"airflow": {"base": Color(0.15, 0.21, 0.26, 0.95), "accent": Color(0.67, 0.89, 0.97, 0.95), "outline": Color(0.09, 0.13, 0.17, 0.92), "label": "Airflow", "shape": "line"},
		"cable_reel": {"base": Color(0.2, 0.2, 0.22, 0.95), "accent": Color(0.74, 0.7, 0.62, 0.95), "outline": Color(0.11, 0.11, 0.12, 0.92), "label": "Cable Reel", "shape": "small_marker"},
		"socket": {"base": Color(0.22, 0.22, 0.25, 0.95), "accent": Color(0.78, 0.85, 0.95, 0.95), "outline": Color(0.12, 0.12, 0.15, 0.92), "label": "Socket", "shape": "small_marker"},
		"power_source": {"base": Color(0.25, 0.28, 0.2, 0.97), "accent": Color(0.95, 0.88, 0.34, 0.99), "outline": Color(0.14, 0.16, 0.1, 0.94), "label": "Power Source", "shape": "slab"},
		"crate": {"base": Color(0.35, 0.23, 0.13, 0.97), "accent": Color(0.86, 0.62, 0.3, 0.99), "outline": Color(0.2, 0.12, 0.07, 0.94), "label": "Crate", "shape": "slab"},
		"barrel": {"base": Color(0.2, 0.3, 0.34, 0.97), "accent": Color(0.57, 0.84, 0.92, 0.99), "outline": Color(0.1, 0.16, 0.19, 0.94), "label": "Barrel", "shape": "pillar"},
		"cable": {"base": Color(0.36, 0.04, 0.04, 0.95), "accent": Color(0.98, 0.12, 0.12, 0.99), "outline": Color(0.18, 0.02, 0.02, 0.92), "label": "Cable", "shape": "line"},
		"generic_object": {"base": Color(0.24, 0.24, 0.28, 0.95), "accent": Color(0.78, 0.8, 0.9, 0.95), "outline": Color(0.14, 0.14, 0.17, 0.92), "label": "Generic Object", "shape": "small_marker"}
	}

func get_iso_object_profile_key_for_tile(tile_type: int) -> String:
	match tile_type:
		GridManager.TILE_DOOR:
			return "door"
		GridManager.TILE_DIGITAL_DOOR:
			return "digital_door"
		GridManager.TILE_POWERED_GATE:
			return "powered_gate"
		GridManager.TILE_TERMINAL:
			return "terminal"
		GridManager.TILE_AIRFLOW_TERMINAL:
			return "airflow_terminal"
		GridManager.TILE_EXIT:
			return "exit"
		GridManager.TILE_KEY:
			return "key"
		GridManager.TILE_COMPONENT:
			return "component"
		GridManager.TILE_HIDDEN_ROUTE_NODE:
			return "hidden_route_node"
		GridManager.TILE_ROUTE_GATE:
			return "route_gate"
		GridManager.TILE_HOT_NODE:
			return "hot_node"
		GridManager.TILE_FAN_PLATFORM:
			return "fan_platform"
		GridManager.TILE_PLATFORM_CONTROL, GridManager.TILE_PLATFORM_CONTROL_LEFT, GridManager.TILE_PLATFORM_CONTROL_RIGHT:
			return "platform_control"
		GridManager.TILE_FAN_CONTROL:
			return "fan_control"
		GridManager.TILE_FAN_SPEED_UP_CONTROL, GridManager.TILE_FAN_SPEED_DOWN_CONTROL:
			return "fan_speed_control"
		GridManager.TILE_AIRFLOW:
			return "airflow"
		GridManager.TILE_CABLE_REEL:
			return "cable_reel"
		GridManager.TILE_SOCKET:
			return "socket"
		GridManager.TILE_CABLE:
			return "cable"
		GridManager.TILE_FLOOR, GridManager.TILE_WALL, GridManager.TILE_STEPPED_FLOOR:
			return ""
	return ""

func is_iso_object_tile(tile_type: int) -> bool:
	return not get_iso_object_profile_key_for_tile(tile_type).is_empty()

func get_iso_object_profile(profile_key: String) -> Dictionary:
	var profiles: Dictionary = get_iso_object_visual_profiles()
	var safe_key: String = profile_key.strip_edges().to_lower()
	if safe_key.is_empty() or not profiles.has(safe_key):
		safe_key = "generic_object"
	var profile: Dictionary = Dictionary(profiles.get(safe_key, profiles.get("generic_object", {})))
	return {
		"base": Color(profile.get("base", Color(0.24, 0.24, 0.28, 0.95))),
		"accent": Color(profile.get("accent", Color(0.78, 0.8, 0.9, 0.95))),
		"outline": Color(profile.get("outline", Color(0.14, 0.14, 0.17, 0.92))),
		"label": str(profile.get("label", "Generic Object")),
		"shape": str(profile.get("shape", "small_marker"))
	}


func _try_parse_cell_variant(cell_variant: Variant, fallback: Vector2i = Vector2i(-1, -1)) -> Vector2i:
	if cell_variant is Vector2i:
		return Vector2i(cell_variant)
	if cell_variant is Vector2:
		var cell_vec2: Vector2 = Vector2(cell_variant)
		return Vector2i(int(round(cell_vec2.x)), int(round(cell_vec2.y)))
	if cell_variant is Array:
		var values: Array = Array(cell_variant)
		if values.size() >= 2:
			return Vector2i(int(values[0]), int(values[1]))
	if cell_variant is String:
		var tokens: PackedStringArray = String(cell_variant).strip_edges().split(",", false)
		if tokens.size() == 2:
			return Vector2i(int(tokens[0]), int(tokens[1]))
	return fallback

func get_wall_mounted_visual_offset(metadata: Dictionary) -> Vector2:
	var wall_side: String = String(metadata.get("wall_side", "")).to_lower().strip_edges()
	var half_size: Vector2 = get_iso_tile_half_size()
	var x_offset: float = half_size.x * 0.34
	var y_offset: float = half_size.y * 0.2
	match wall_side:
		"north":
			return Vector2(0.0, -y_offset)
		"south":
			return Vector2(0.0, y_offset)
		"east":
			return Vector2(x_offset, 0.0)
		"west":
			return Vector2(-x_offset, 0.0)
	return Vector2.ZERO

func get_world_object_visual_position(cell: Vector2i) -> Vector2:
	var base_center: Vector2 = grid_to_iso(cell)
	var metadata: Dictionary = get_wall_metadata_for_cell(cell)
	if metadata.is_empty():
		return base_center
	var placement_mode: String = String(metadata.get("placement_mode", "")).to_lower().strip_edges()
	if placement_mode != "wall_mounted":
		return base_center
	var anchor_cell: Vector2i = _try_parse_cell_variant(metadata.get("anchor_floor_cell", cell), cell)
	var attached_wall_cell: Vector2i = _try_parse_cell_variant(metadata.get("attached_wall_cell", Vector2i(-1, -1)), Vector2i(-1, -1))
	var wall_side: String = String(metadata.get("wall_side", "")).to_lower().strip_edges()
	if wall_side.is_empty() or attached_wall_cell.x < 0 or attached_wall_cell.y < 0:
		return base_center
	if anchor_cell != cell:
		return base_center
	var mount_zones: Array[Dictionary] = get_wall_mounted_anchor_zones(attached_wall_cell)
	for zone_variant in mount_zones:
		var zone: Dictionary = Dictionary(zone_variant)
		if String(zone.get("wall_side", "")) != wall_side:
			continue
		if Vector2i(zone.get("anchor_floor_cell", Vector2i(-1, -1))) != anchor_cell:
			continue
		return Vector2(zone.get("mount_zone_center", base_center))
	return base_center + get_wall_mounted_visual_offset(metadata)

func draw_iso_object_slab(cell: Vector2i, profile: Dictionary, visual_center_override: Vector2 = Vector2.INF) -> void:
	var center: Vector2 = grid_to_iso(cell)
	if visual_center_override != Vector2.INF:
		center = visual_center_override
	var diamond: PackedVector2Array = get_iso_diamond_points(cell)
	if diamond.size() < 4:
		return
	var inset: float = 0.38
	var top_offset: float = -8.0
	var slab_points: PackedVector2Array = PackedVector2Array()
	for point in diamond:
		var offset_point: Vector2 = center + (point - center) * inset + Vector2(0.0, top_offset)
		slab_points.append(offset_point)
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	draw_colored_polygon(slab_points, base_color)
	var accent_start: Vector2 = slab_points[3].lerp(slab_points[0], 0.5)
	var accent_end: Vector2 = slab_points[0].lerp(slab_points[1], 0.5)
	draw_line(accent_start, accent_end, accent_color, 2.0)
	if debug_draw_iso_object_outlines:
		for edge_idx in range(slab_points.size()):
			var next_idx: int = (edge_idx + 1) % slab_points.size()
			draw_line(slab_points[edge_idx], slab_points[next_idx], outline_color, 1.0)

func draw_iso_object_pillar(cell: Vector2i, profile: Dictionary, visual_center_override: Vector2 = Vector2.INF) -> void:
	var center: Vector2 = grid_to_iso(cell)
	if visual_center_override != Vector2.INF:
		center = visual_center_override
	var marker_height: float = maxf(iso_object_marker_height, 1.0)
	var half_width: float = maxf(get_iso_tile_half_size().x * 0.12, 3.0)
	var base_bottom: Vector2 = center + Vector2(0.0, -3.0)
	var base_top: Vector2 = base_bottom + Vector2(0.0, -marker_height)
	var left_bottom: Vector2 = base_bottom + Vector2(-half_width, 0.0)
	var right_bottom: Vector2 = base_bottom + Vector2(half_width, 0.0)
	var left_top: Vector2 = base_top + Vector2(-half_width, 0.0)
	var right_top: Vector2 = base_top + Vector2(half_width, 0.0)
	var body_points: PackedVector2Array = PackedVector2Array([left_top, right_top, right_bottom, left_bottom])
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	draw_colored_polygon(body_points, base_color)
	draw_line(left_top, right_top, accent_color, 2.0)
	if debug_draw_iso_object_outlines:
		for edge_idx in range(body_points.size()):
			var next_idx: int = (edge_idx + 1) % body_points.size()
			draw_line(body_points[edge_idx], body_points[next_idx], outline_color, 1.0)

func draw_iso_object_door_panel(cell: Vector2i, profile: Dictionary, visual_center_override: Vector2 = Vector2.INF) -> void:
	var center: Vector2 = grid_to_iso(cell)
	if visual_center_override != Vector2.INF:
		center = visual_center_override
	var marker_height: float = maxf(iso_object_marker_height + 12.0, 18.0)
	var half_width: float = maxf(get_iso_tile_half_size().x * 0.11, 6.0)
	var panel_bottom: Vector2 = center + Vector2(0.0, -5.0)
	var panel_top: Vector2 = panel_bottom + Vector2(0.0, -marker_height)
	var left_bottom: Vector2 = panel_bottom + Vector2(-half_width, 0.0)
	var right_bottom: Vector2 = panel_bottom + Vector2(half_width, 0.0)
	var left_top: Vector2 = panel_top + Vector2(-half_width, 0.0)
	var right_top: Vector2 = panel_top + Vector2(half_width, 0.0)
	var body_points: PackedVector2Array = PackedVector2Array([left_top, right_top, right_bottom, left_bottom])
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	var frame_color: Color = outline_color.lightened(0.2)
	var frame_left_top: Vector2 = panel_top + Vector2(-half_width - 3.0, -1.0)
	var frame_right_top: Vector2 = panel_top + Vector2(half_width + 3.0, -1.0)
	var frame_left_bottom: Vector2 = panel_bottom + Vector2(-half_width - 3.0, 0.0)
	var frame_right_bottom: Vector2 = panel_bottom + Vector2(half_width + 3.0, 0.0)
	var frame_points: PackedVector2Array = PackedVector2Array([frame_left_top, frame_right_top, frame_right_bottom, frame_left_bottom])
	draw_colored_polygon(frame_points, frame_color.darkened(0.15))
	draw_colored_polygon(body_points, base_color)
	draw_line(left_bottom, left_top, accent_color, 2.2)
	draw_line(right_bottom, right_top, accent_color, 2.2)
	draw_line(left_top.lerp(right_top, 0.2), left_bottom.lerp(right_bottom, 0.2), accent_color, 1.2)
	draw_line(left_top.lerp(right_top, 0.8), left_bottom.lerp(right_bottom, 0.8), accent_color, 1.2)
	if debug_draw_iso_object_outlines:
		for edge_idx in range(body_points.size()):
			var next_idx: int = (edge_idx + 1) % body_points.size()
			draw_line(body_points[edge_idx], body_points[next_idx], outline_color, 1.0)

func draw_iso_object_terminal_console(cell: Vector2i, profile: Dictionary, visual_center_override: Vector2 = Vector2.INF) -> void:
	var center: Vector2 = grid_to_iso(cell)
	if visual_center_override != Vector2.INF:
		center = visual_center_override
	var body_height: float = maxf(iso_object_marker_height + 2.0, 12.0)
	var body_half_width: float = maxf(get_iso_tile_half_size().x * 0.11, 5.0)
	var body_bottom: Vector2 = center + Vector2(0.0, -3.0)
	var body_top: Vector2 = body_bottom + Vector2(0.0, -body_height)
	var body: PackedVector2Array = PackedVector2Array([
		body_top + Vector2(-body_half_width, 0.0),
		body_top + Vector2(body_half_width, 0.0),
		body_bottom + Vector2(body_half_width, 0.0),
		body_bottom + Vector2(-body_half_width, 0.0)
	])
	var screen: Rect2 = Rect2(center + Vector2(-body_half_width + 1.0, -body_height + 2.0), Vector2(body_half_width * 2.0 - 2.0, body_height * 0.36))
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	draw_colored_polygon(body, base_color)
	draw_rect(screen, accent_color, true)
	draw_line(screen.position + Vector2(0.0, screen.size.y), screen.position + screen.size, accent_color.lightened(0.25), 1.4)
	if debug_draw_iso_object_outlines:
		for edge_idx in range(body.size()):
			var next_idx: int = (edge_idx + 1) % body.size()
			draw_line(body[edge_idx], body[next_idx], outline_color, 1.0)
		draw_rect(screen, outline_color, false, 1.0)

func draw_iso_object_small_marker(cell: Vector2i, profile: Dictionary, visual_center_override: Vector2 = Vector2.INF) -> void:
	var center: Vector2 = grid_to_iso(cell)
	if visual_center_override != Vector2.INF:
		center = visual_center_override
	center += Vector2(0.0, -6.0)
	var radius: float = maxf(get_iso_tile_half_size().y * 0.16, 3.0)
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	draw_circle(center, radius, base_color)
	draw_circle(center + Vector2(0.0, -radius * 0.3), radius * 0.45, accent_color)
	if debug_draw_iso_object_outlines:
		draw_arc(center, radius, 0.0, PI * 2.0, 24, outline_color, 1.0)

func draw_iso_object_line(cell: Vector2i, profile: Dictionary, visual_center_override: Vector2 = Vector2.INF) -> void:
	var center: Vector2 = grid_to_iso(cell)
	if visual_center_override != Vector2.INF:
		center = visual_center_override
	center += Vector2(0.0, -4.0)
	var half_width: float = maxf(get_iso_tile_half_size().x * 0.26, 8.0)
	var line_start: Vector2 = center + Vector2(-half_width, 0.0)
	var line_end: Vector2 = center + Vector2(half_width, 0.0)
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	draw_line(line_start, line_end, base_color, 3.0)
	draw_line(center + Vector2(-half_width * 0.6, -2.0), center + Vector2(half_width * 0.6, -2.0), accent_color, 1.6)
	if debug_draw_iso_object_outlines:
		draw_line(line_start, line_end, outline_color, 1.0)

func draw_iso_object_heat_marker(cell: Vector2i, profile: Dictionary, visual_center_override: Vector2 = Vector2.INF) -> void:
	var center: Vector2 = grid_to_iso(cell)
	if visual_center_override != Vector2.INF:
		center = visual_center_override
	center += Vector2(0.0, -7.0)
	var radius: float = maxf(get_iso_tile_half_size().y * 0.18, 3.5)
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	draw_circle(center, radius, base_color)
	draw_circle(center, radius * 0.58, accent_color)
	if debug_draw_iso_object_outlines:
		draw_arc(center, radius, 0.0, PI * 2.0, 24, outline_color, 1.0)


func get_wall_mounted_object_profile_key(cell: Vector2i) -> String:
	var metadata: Dictionary = get_wall_metadata_for_cell(cell)
	if metadata.is_empty():
		return ""
	if String(metadata.get("placement_mode", "")).to_lower().strip_edges() != "wall_mounted":
		return ""
	var candidates: Array[String] = [
		String(metadata.get("visual_profile", "")),
		String(metadata.get("object_type", "")),
		String(metadata.get("catalog_id", "")),
		String(metadata.get("type", "")),
		String(metadata.get("id", ""))
	]
	for candidate in candidates:
		var normalized: String = candidate.strip_edges().to_lower()
		match normalized:
			"door_terminal", "platform_terminal", "cooling_terminal", "firewall", "circuit_breaker", "fuse_box", "light_switch", "power_cable_reel":
				return normalized
	return ""

func is_terminal_like_profile(profile_key: String) -> bool:
	match profile_key:
		"terminal", "airflow_terminal", "door_terminal", "platform_terminal", "cooling_terminal":
			return true
	return false

func is_door_like_profile(profile_key: String) -> bool:
	match profile_key:
		"door", "digital_door", "powered_gate":
			return true
	return false

func get_wall_mounted_attached_depth_cell(cell: Vector2i) -> Vector2i:
	var object_metadata: Dictionary = _get_iso_world_object_metadata_for_cell(cell)
	var world_object_data: Dictionary = Dictionary(object_metadata.get("data", {}))
	var attached_wall_cell: Vector2i = _try_parse_cell_variant(world_object_data.get("attached_wall_cell", Vector2i(-1, -1)), Vector2i(-1, -1))
	if attached_wall_cell.x >= 0 and attached_wall_cell.y >= 0:
		return attached_wall_cell
	var wall_metadata: Dictionary = get_wall_metadata_for_cell(cell)
	if wall_metadata.is_empty():
		return cell
	attached_wall_cell = _try_parse_cell_variant(wall_metadata.get("attached_wall_cell", Vector2i(-1, -1)), Vector2i(-1, -1))
	if attached_wall_cell.x >= 0 and attached_wall_cell.y >= 0:
		return attached_wall_cell
	return cell

func draw_iso_wall_terminal_panel(center: Vector2, profile: Dictionary, screen_tint: Color) -> void:
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	var body: Rect2 = Rect2(center + Vector2(-8.0, -18.0), Vector2(16.0, 16.0))
	var screen: Rect2 = Rect2(body.position + Vector2(2.0, 3.0), Vector2(body.size.x - 4.0, 6.0))
	draw_rect(body, base_color, true)
	draw_rect(screen, screen_tint, true)
	draw_line(screen.position + Vector2(0.0, screen.size.y), screen.position + screen.size, accent_color, 1.2)
	if debug_draw_iso_object_outlines:
		draw_rect(body, outline_color, false, 1.0)
		draw_rect(screen, outline_color, false, 1.0)

func draw_iso_wall_door_terminal(center: Vector2, profile: Dictionary) -> void:
	draw_iso_wall_terminal_panel(center, profile, Color(0.36, 0.95, 1.0, 0.98))
	var glow_rect: Rect2 = Rect2(center + Vector2(-5.0, -8.0), Vector2(10.0, 2.0))
	draw_rect(glow_rect, Color(0.62, 1.0, 1.0, 0.94), true)
	if debug_draw_iso_object_outlines:
		draw_rect(glow_rect, _get_color_from_dict(profile, "outline", Color.WHITE), false, 1.0)

func draw_iso_wall_platform_terminal(center: Vector2, profile: Dictionary) -> void:
	draw_iso_wall_terminal_panel(center, profile, Color(1.0, 0.72, 0.24, 0.98))
	var indicator_y: float = center.y - 8.5
	draw_line(center + Vector2(-5.6, indicator_y), center + Vector2(5.6, indicator_y), Color(1.0, 0.86, 0.45, 0.92), 1.5)
	draw_circle(center + Vector2(4.8, -14.0), 1.1, Color(1.0, 0.56, 0.18, 0.95))
	if debug_draw_iso_object_outlines:
		draw_arc(center + Vector2(4.8, -14.0), 1.1, 0.0, PI * 2.0, 12, _get_color_from_dict(profile, "outline", Color.WHITE), 1.0)

func draw_iso_wall_cooling_terminal(center: Vector2, profile: Dictionary) -> void:
	draw_iso_wall_terminal_panel(center, profile, Color(0.54, 0.82, 1.0, 0.98))
	for fin_idx in range(3):
		var fin_x: float = center.x - 4.0 + float(fin_idx) * 3.8
		draw_line(Vector2(fin_x, center.y - 14.8), Vector2(fin_x, center.y - 4.8), Color(0.82, 0.94, 1.0, 0.78), 1.1)

func draw_iso_wall_firewall_panel(center: Vector2, profile: Dictionary) -> void:
	draw_iso_wall_terminal_panel(center, profile, Color(1.0, 0.26, 0.22, 0.99))
	var warning_top: Vector2 = center + Vector2(0.0, -17.0)
	draw_line(warning_top + Vector2(-5.0, 9.0), warning_top + Vector2(0.0, 0.0), Color(1.0, 0.9, 0.34, 0.98), 1.5)
	draw_line(warning_top + Vector2(0.0, 0.0), warning_top + Vector2(5.0, 9.0), Color(1.0, 0.9, 0.34, 0.98), 1.5)
	draw_line(warning_top + Vector2(5.0, 9.0), warning_top + Vector2(-5.0, 9.0), Color(1.0, 0.9, 0.34, 0.98), 1.5)

func draw_iso_wall_breaker_box(center: Vector2, profile: Dictionary) -> void:
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	var box: Rect2 = Rect2(center + Vector2(-7.0, -16.0), Vector2(14.0, 13.0))
	draw_rect(box, base_color, true)
	var lever_pivot: Vector2 = box.position + Vector2(box.size.x * 0.35, box.size.y * 0.45)
	draw_circle(lever_pivot, 1.4, accent_color)
	draw_line(lever_pivot, lever_pivot + Vector2(4.2, -3.4), accent_color, 2.0)
	if debug_draw_iso_object_outlines:
		draw_rect(box, outline_color, false, 1.0)

func draw_iso_wall_fuse_box(center: Vector2, profile: Dictionary) -> void:
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	var box: Rect2 = Rect2(center + Vector2(-8.0, -16.0), Vector2(16.0, 13.0))
	draw_rect(box, base_color, true)
	for slot_idx in range(3):
		var slot_x: float = box.position.x + 3.0 + float(slot_idx) * 4.2
		draw_rect(Rect2(Vector2(slot_x, box.position.y + 3.0), Vector2(2.6, 7.0)), accent_color.darkened(0.2), true)
	if debug_draw_iso_object_outlines:
		draw_rect(box, outline_color, false, 1.0)

func draw_iso_wall_light_switch(center: Vector2, profile: Dictionary) -> void:
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	var plate: Rect2 = Rect2(center + Vector2(-4.0, -12.0), Vector2(8.0, 10.0))
	var switch_rect: Rect2 = Rect2(plate.position + Vector2(2.5, 2.2), Vector2(3.0, 4.6))
	draw_rect(plate, base_color, true)
	draw_rect(switch_rect, accent_color, true)
	if debug_draw_iso_object_outlines:
		draw_rect(plate, outline_color, false, 1.0)

func draw_iso_wall_cable_reel(center: Vector2, profile: Dictionary) -> void:
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	var reel_center: Vector2 = center + Vector2(0.0, -10.0)
	draw_circle(reel_center, 6.0, base_color)
	draw_arc(reel_center, 5.0, 0.0, PI * 1.75, 20, accent_color, 1.8)
	draw_arc(reel_center, 3.0, 0.0, PI * 1.75, 20, accent_color, 1.5)
	draw_circle(reel_center, 1.4, accent_color)
	if debug_draw_iso_object_outlines:
		draw_arc(reel_center, 6.0, 0.0, PI * 2.0, 24, outline_color, 1.0)

func draw_wall_mounted_object_shape(_cell: Vector2i, profile_key: String, profile: Dictionary, visual_center: Vector2) -> bool:
	match profile_key:
		"door_terminal":
			draw_iso_wall_door_terminal(visual_center, profile)
			return true
		"platform_terminal":
			draw_iso_wall_platform_terminal(visual_center, profile)
			return true
		"cooling_terminal":
			draw_iso_wall_cooling_terminal(visual_center, profile)
			return true
		"firewall":
			draw_iso_wall_firewall_panel(visual_center, profile)
			return true
		"circuit_breaker":
			draw_iso_wall_breaker_box(visual_center, profile)
			return true
		"fuse_box":
			draw_iso_wall_fuse_box(visual_center, profile)
			return true
		"light_switch":
			draw_iso_wall_light_switch(visual_center, profile)
			return true
		"power_cable_reel":
			draw_iso_wall_cable_reel(visual_center, profile)
			return true
	return false

func get_iso_object_grounding_profile(object_data: Dictionary, fallback_cell: Vector2i = Vector2i(-1, -1)) -> Dictionary:
	var object_id: String = String(object_data.get("id", "")).strip_edges()
	var object_type: String = String(object_data.get("object_type", object_data.get("type", ""))).to_lower().strip_edges()
	var placement_mode: String = String(object_data.get("placement_mode", "")).to_lower().strip_edges()
	var anchor_cell: Vector2i = _try_parse_cell_variant(object_data.get("anchor_floor_cell", Vector2i(-1, -1)), Vector2i(-1, -1))
	var attached_wall_cell: Vector2i = _try_parse_cell_variant(object_data.get("attached_wall_cell", Vector2i(-1, -1)), Vector2i(-1, -1))
	var wall_side: String = String(object_data.get("wall_side", "")).to_lower().strip_edges()
	if anchor_cell.x < 0 or anchor_cell.y < 0:
		anchor_cell = _try_parse_cell_variant(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
	if anchor_cell.x < 0 or anchor_cell.y < 0:
		anchor_cell = fallback_cell
	if anchor_cell.x < 0 or anchor_cell.y < 0:
		anchor_cell = Vector2i(0, 0)
	var center: Vector2 = grid_to_iso(anchor_cell)
	if placement_mode == "wall_mounted" and attached_wall_cell.x >= 0 and attached_wall_cell.y >= 0 and not wall_side.is_empty():
		for zone_variant in get_wall_mounted_anchor_zones(attached_wall_cell):
			var zone: Dictionary = Dictionary(zone_variant)
			if String(zone.get("wall_side", "")) == wall_side and Vector2i(zone.get("anchor_floor_cell", Vector2i(-1, -1))) == anchor_cell:
				center = Vector2(zone.get("mount_zone_center", center))
				break
	var grounding_type: String = "floor_standing"
	if object_data.is_empty():
		grounding_type = "unknown"
	if placement_mode == "wall_mounted":
		grounding_type = "wall_mounted"
	elif object_type.contains("door") or object_type.contains("gate"):
		grounding_type = "door_insert"
	elif object_type.contains("key") or object_type.contains("kit") or object_type.contains("card") or object_type.contains("code"):
		grounding_type = "floor_pickup"
	elif object_type.contains("cable"):
		grounding_type = "cable_like"
	var diamond: PackedVector2Array = get_iso_inset_diamond_points(anchor_cell, 20.0)
	var footprint: PackedVector2Array = PackedVector2Array()
	for point in diamond:
		footprint.append(center + (point - grid_to_iso(anchor_cell)) * 0.35 + Vector2(0.0, -3.0))
	var shadow: PackedVector2Array = PackedVector2Array()
	for point in footprint:
		shadow.append(point + Vector2(0.0, 3.0))
	var shape_scale: float = 1.0
	if grounding_type == "floor_pickup":
		shape_scale = 0.65
	return {
		"object_id": object_id, "object_type": object_type, "placement_mode": placement_mode, "grounding_type": grounding_type,
		"anchor_cell": anchor_cell, "attached_wall_cell": attached_wall_cell, "wall_side": wall_side,
		"visual_center": center, "footprint_polygon": footprint, "shadow_polygon": shadow,
		"base_color": Color(0.28, 0.31, 0.37, 0.55), "edge_color": Color(0.13, 0.15, 0.19, 0.72), "accent_color": Color(0.56, 0.81, 0.93, 0.95),
		"height_px": 18, "scale": shape_scale, "badge_enabled": true
	}

func _draw_grounding_overlay(profile: Dictionary) -> void:
	var fp: PackedVector2Array = PackedVector2Array(profile.get("footprint_polygon", PackedVector2Array()))
	if fp.size() >= 3:
		draw_colored_polygon(fp, Color(0.28, 0.7, 0.95, 0.08))
		for i in range(fp.size()):
			var n: int = (i + 1) % fp.size()
			draw_line(fp[i], fp[n], Color(0.28, 0.8, 1.0, 0.65), 1.0)
	var center: Vector2 = Vector2(profile.get("visual_center", Vector2.ZERO))
	draw_circle(center, 2.0, Color(0.96, 0.96, 0.2, 0.95))
	var gt: String = String(profile.get("grounding_type", "unknown"))
	var short: String = "UN"
	match gt:
		"floor_standing": short = "FS"
		"wall_mounted": short = "WM"
		"door_insert": short = "DR"
		"floor_pickup": short = "IT"
		"cable_like": short = "CB"
	draw_string(ThemeDB.fallback_font, center + Vector2(4.0, -6.0), short, HORIZONTAL_ALIGNMENT_LEFT, 18.0, 10, Color(0.95, 1.0, 0.98, 0.95))

func _get_door_axis_vectors(orientation: String) -> Dictionary:
	if orientation == "axis_y":
		return {"along": Vector2(0.78, 0.39).normalized(), "up": Vector2(0.0, -1.0)}
	return {"along": Vector2(0.78, -0.39).normalized(), "up": Vector2(0.0, -1.0)}

func draw_iso_door_insert(cell: Vector2i, _tile_type: int, object_data: Dictionary = {}) -> void:
	var context: Dictionary = get_door_opening_context(cell)
	if not bool(context.get("ok", false)):
		return
	var profile: Dictionary = get_iso_door_opening_visual_profile(cell, object_data)
	var orientation: String = String(context.get("orientation", "unknown"))
	var door_insert_center: Vector2 = Vector2(context.get("door_insert_center", grid_to_iso(cell)))
	var threshold_polygon: PackedVector2Array = PackedVector2Array(context.get("threshold_polygon", PackedVector2Array()))
	var frame_polygon: PackedVector2Array = PackedVector2Array(context.get("door_frame_polygon", PackedVector2Array()))
	var base_color: Color = Color(profile.get("base_color", Color(0.25, 0.25, 0.28, 0.96)))
	var frame_color: Color = Color(profile.get("frame_color", Color(0.1, 0.12, 0.14, 0.98)))
	var accent_color: Color = Color(profile.get("accent_color", Color(0.8, 0.8, 0.72, 0.98)))
	var warning_color: Color = Color(profile.get("warning_color", Color(1.0, 0.28, 0.2, 0.98)))
	var threshold_color: Color = Color(profile.get("threshold_color", Color(0.14, 0.16, 0.18, 0.82)))
	var alpha: float = float(profile.get("alpha", 0.96))
	base_color.a *= alpha
	accent_color.a *= maxf(alpha, 0.55)
	if bool(profile.get("threshold_enabled", true)):
		if draw_iso_texture_asset(cell, "floor_door_underlay"):
			pass
		elif threshold_polygon.size() >= 3:
			draw_colored_polygon(threshold_polygon, threshold_color)
			for threshold_index in range(threshold_polygon.size()):
				var threshold_next_index: int = (threshold_index + 1) % threshold_polygon.size()
				draw_line(threshold_polygon[threshold_index], threshold_polygon[threshold_next_index], accent_color.darkened(0.25), 1.0)
	if bool(profile.get("frame_enabled", true)) and frame_polygon.size() >= 4:
		draw_colored_polygon(frame_polygon, Color(frame_color.r, frame_color.g, frame_color.b, 0.72))
		for frame_index in range(frame_polygon.size()):
			var frame_next_index: int = (frame_index + 1) % frame_polygon.size()
			draw_line(frame_polygon[frame_index], frame_polygon[frame_next_index], frame_color.lightened(0.18), 2.0)
		var left_jamb_cell: Vector2i = Vector2i(context.get("left_jamb_cell", Vector2i(-1, -1)))
		var right_jamb_cell: Vector2i = Vector2i(context.get("right_jamb_cell", Vector2i(-1, -1)))
		var jamb_cells: Array[Vector2i] = [left_jamb_cell, right_jamb_cell]
		for jamb_cell in jamb_cells:
			if jamb_cell.x < 0 or jamb_cell.y < 0:
				continue
			if not is_cell_in_bounds(jamb_cell):
				continue
			if not is_wall_tile(_grid_manager.get_tile(jamb_cell)):
				continue
			var jamb_center: Vector2 = grid_to_iso(jamb_cell) + Vector2(0.0, -iso_wall_height * 0.4)
			draw_line(jamb_center + Vector2(0.0, -10.0), jamb_center + Vector2(0.0, 13.0), frame_color.lightened(0.24), 3.0)
	var door_kind: String = String(profile.get("door_kind", "mechanical_door"))
	var door_state: String = String(profile.get("door_state", "closed"))
	var used_texture_asset: bool = draw_iso_texture_asset(cell, "object_door", door_insert_center)
	if not used_texture_asset:
		var axis_data: Dictionary = _get_door_axis_vectors(orientation)
		var along_axis: Vector2 = Vector2(axis_data.get("along", Vector2(1.0, 0.0)))
		var up_axis: Vector2 = Vector2(axis_data.get("up", Vector2(0.0, -1.0)))
		var half_width: float = get_iso_tile_half_size().x * 0.24
		var panel_height: float = iso_wall_height * 0.58
		var panel_bottom: Vector2 = door_insert_center + Vector2(0.0, 12.0)
		var panel_top: Vector2 = panel_bottom + up_axis * panel_height
		var panel_points: PackedVector2Array = PackedVector2Array([
			panel_top - along_axis * half_width,
			panel_top + along_axis * half_width,
			panel_bottom + along_axis * half_width,
			panel_bottom - along_axis * half_width
		])
		if door_state == "open":
			var split_offset: Vector2 = along_axis * half_width * 0.58
			var left_panel: PackedVector2Array = PackedVector2Array([panel_points[0] - split_offset, panel_points[0], panel_points[3], panel_points[3] - split_offset])
			var right_panel: PackedVector2Array = PackedVector2Array([panel_points[1], panel_points[1] + split_offset, panel_points[2] + split_offset, panel_points[2]])
			draw_colored_polygon(left_panel, base_color)
			draw_colored_polygon(right_panel, base_color)
		else:
			draw_colored_polygon(panel_points, base_color)
		if door_kind == "digital_door":
			var strip_start: Vector2 = panel_top + along_axis * half_width * 0.58
			var strip_end: Vector2 = panel_bottom + along_axis * half_width * 0.58
			draw_line(strip_start, strip_end, accent_color, 3.2)
			draw_circle(strip_start.lerp(strip_end, 0.35), 2.8, accent_color.lightened(0.2))
		elif door_kind == "powered_gate":
			for bar_index in range(4):
				var bar_t: float = 0.2 + float(bar_index) * 0.2
				var bar_center: Vector2 = panel_top.lerp(panel_bottom, bar_t)
				draw_line(bar_center - along_axis * half_width * 0.84, bar_center + along_axis * half_width * 0.84, accent_color, 1.8)
				draw_circle(bar_center, 1.6, accent_color.lightened(0.18))
		else:
			draw_line(panel_points[0].lerp(panel_points[3], 0.5), panel_points[1].lerp(panel_points[2], 0.5), accent_color, 1.6)
		if debug_draw_iso_object_outlines:
			for panel_index in range(panel_points.size()):
				var panel_next_index: int = (panel_index + 1) % panel_points.size()
				draw_line(panel_points[panel_index], panel_points[panel_next_index], frame_color.lightened(0.28), 1.0)
	else:
		if door_kind == "digital_door":
			draw_line(door_insert_center + Vector2(10.0, -43.0), door_insert_center + Vector2(10.0, -13.0), accent_color, 2.6)
			draw_circle(door_insert_center + Vector2(10.0, -28.0), 2.4, accent_color.lightened(0.2))
		elif door_kind == "powered_gate":
			for texture_bar_index in range(3):
				var texture_bar_y: float = -38.0 + float(texture_bar_index) * 10.0
				draw_line(door_insert_center + Vector2(-13.0, texture_bar_y), door_insert_center + Vector2(13.0, texture_bar_y), accent_color, 1.8)
		else:
			draw_line(door_insert_center + Vector2(-9.0, -24.0), door_insert_center + Vector2(9.0, -24.0), accent_color, 2.0)
		draw_circle(door_insert_center + Vector2(0.0, -31.0), 2.5, accent_color)
	if bool(profile.get("state_badge_enabled", false)):
		var badge_center: Vector2 = door_insert_center + Vector2(18.0, -22.0)
		var badge_color: Color = accent_color
		if door_state == "locked":
			badge_color = warning_color
		elif door_state == "damaged":
			badge_color = warning_color
		draw_circle(badge_center, 4.2, badge_color)
		if door_state == "locked":
			draw_line(badge_center + Vector2(-2.0, -1.0), badge_center + Vector2(2.0, -1.0), frame_color, 1.2)
		elif door_state == "unpowered":
			draw_line(badge_center + Vector2(-2.8, 2.0), badge_center + Vector2(2.8, -2.0), frame_color, 1.4)
	if bool(profile.get("damage_overlay_enabled", false)):
		draw_line(door_insert_center + Vector2(-12.0, -36.0), door_insert_center + Vector2(-2.0, -23.0), warning_color, 1.8)
		draw_line(door_insert_center + Vector2(-2.0, -23.0), door_insert_center + Vector2(-8.0, -14.0), warning_color, 1.4)
	if show_door_opening_overlay:
		draw_door_opening_overlay_for_context(context)

func draw_door_opening_overlay_for_context(context: Dictionary) -> void:
	var cell: Vector2i = Vector2i(context.get("cell", Vector2i(-1, -1)))
	if cell.x < 0 or cell.y < 0:
		return
	var threshold_polygon: PackedVector2Array = PackedVector2Array(context.get("threshold_polygon", PackedVector2Array()))
	if threshold_polygon.size() >= 3:
		draw_colored_polygon(threshold_polygon, Color(0.2, 0.85, 1.0, 0.16))
		draw_polyline(threshold_polygon, Color(0.35, 0.95, 1.0, 0.92), 1.2, true)
	var insert_center: Vector2 = Vector2(context.get("door_insert_center", grid_to_iso(cell)))
	draw_circle(insert_center, 3.5, Color(1.0, 0.3, 0.9, 0.95))
	for wall_cell_variant in Array(context.get("adjacent_wall_cells", [])):
		var wall_cell: Vector2i = Vector2i(wall_cell_variant)
		draw_circle(grid_to_iso(wall_cell) + Vector2(0.0, -iso_wall_height * 0.35), 3.0, Color(0.95, 0.74, 0.28, 0.95))
	draw_string(ThemeDB.fallback_font, insert_center + Vector2(5.0, -7.0), String(context.get("orientation", "unknown")), HORIZONTAL_ALIGNMENT_LEFT, 64.0, 9, Color(0.95, 1.0, 1.0, 0.95))

func draw_iso_object_marker(cell: Vector2i, tile_type: int, override_object_data: Dictionary = {}) -> void:
	var object_meta: Dictionary = _get_iso_world_object_metadata_for_cell(cell)
	if not override_object_data.is_empty():
		object_meta = {"ok": true, "object_id": String(override_object_data.get("id", "")), "object_type": String(override_object_data.get("object_type", override_object_data.get("item_type", ""))), "data": override_object_data}
	if is_door_like_tile(tile_type) and override_object_data.is_empty():
		draw_iso_door_insert(cell, tile_type, Dictionary(object_meta.get("data", {})))
		return
	var profile_data: Dictionary = get_iso_object_grounding_profile(Dictionary(object_meta.get("data", {})), cell)
	var visual_center: Vector2 = Vector2(profile_data.get("visual_center", get_world_object_visual_position(cell)))
	var shadow_polygon: PackedVector2Array = PackedVector2Array(profile_data.get("shadow_polygon", PackedVector2Array()))
	if shadow_polygon.size() >= 3:
		draw_colored_polygon(shadow_polygon, Color(0.03, 0.05, 0.08, 0.26))
	var footprint_polygon: PackedVector2Array = PackedVector2Array(profile_data.get("footprint_polygon", PackedVector2Array()))
	if footprint_polygon.size() >= 3:
		draw_colored_polygon(footprint_polygon, Color(0.2, 0.24, 0.28, 0.2))
	var object_id: String = String(object_meta.get("object_id", ""))
	var object_data: Dictionary = Dictionary(object_meta.get("data", {}))
	var profile_key: String = get_iso_object_profile_key_for_tile(tile_type)
	if not override_object_data.is_empty() or profile_key.is_empty():
		profile_key = get_iso_object_profile_key_for_object_data(object_data, profile_key)
	var object_asset_key: String = get_iso_object_asset_key_for_object_data(object_data, profile_key)
	var mission_manager: Node = get_mission_manager_ref()
	var has_door_visual: bool = false
	var door_visual: Dictionary = {}
	var has_terminal_visual: bool = false
	var terminal_visual: Dictionary = {}
	if not object_id.is_empty() and mission_manager != null:
		if mission_manager.has_method("get_map_constructor_door_visual_state"):
			door_visual = Dictionary(mission_manager.call("get_map_constructor_door_visual_state", object_id))
			has_door_visual = bool(door_visual.get("ok", false))
		if mission_manager.has_method("get_map_constructor_terminal_visual_state"):
			terminal_visual = Dictionary(mission_manager.call("get_map_constructor_terminal_visual_state", object_id))
			has_terminal_visual = bool(terminal_visual.get("ok", false))
	var wall_mounted_profile_key: String = get_wall_mounted_object_profile_key(cell)
	if not wall_mounted_profile_key.is_empty():
		profile_key = wall_mounted_profile_key
		object_asset_key = get_iso_object_asset_key_for_object_data(object_data, profile_key)
	var profile: Dictionary = get_iso_object_profile(profile_key)
	if has_door_visual:
		profile["base"] = _blend_color(_get_color_from_dict(profile, "base", Color.WHITE), Color(door_visual.get("tint", Color.WHITE)), 0.45)
		profile["accent"] = Color(door_visual.get("accent", _get_color_from_dict(profile, "accent", Color.WHITE)))
	if has_terminal_visual:
		profile["base"] = _blend_color(_get_color_from_dict(profile, "base", Color.WHITE), Color(terminal_visual.get("tint", Color.WHITE)), 0.45)
		profile["accent"] = Color(terminal_visual.get("accent", _get_color_from_dict(profile, "accent", Color.WHITE)))
	var overlay_accent: Color = _get_color_from_dict(profile, "accent", Color(0.72, 0.78, 0.86, 0.95))
	var used_texture_asset: bool = draw_iso_texture_asset(cell, object_asset_key, visual_center)
	if not used_texture_asset and has_door_visual:
		used_texture_asset = draw_optional_visual_texture_asset(String(door_visual.get("texture_asset_id", "")), cell, "draw_iso_object_marker", {"visual_center": visual_center})
	if not used_texture_asset and has_terminal_visual:
		used_texture_asset = draw_optional_visual_texture_asset(String(terminal_visual.get("texture_asset_id", "")), cell, "draw_iso_object_marker", {"visual_center": visual_center})
	if used_texture_asset:
		draw_circle(visual_center + Vector2(0.0, -iso_object_marker_height - 8.0), 2.4, overlay_accent)
		draw_line(
			visual_center + Vector2(-4.0, -iso_object_marker_height - 3.0),
			visual_center + Vector2(4.0, -iso_object_marker_height - 3.0),
			overlay_accent,
			1.5
		)
		return
	if draw_wall_mounted_object_shape(cell, profile_key, profile, visual_center):
		return
	var shape: String = str(profile.get("shape", "small_marker"))
	var door_profile_key: String = get_iso_door_visual_profile_key_for_tile(tile_type)
	if not door_profile_key.is_empty():
		if door_profile_key == "door_mechanical":
			profile["base"] = Color(0.3, 0.21, 0.13, 0.96)
			profile["accent"] = Color(0.96, 0.7, 0.28, 0.98)
			profile["outline"] = Color(0.2, 0.13, 0.08, 0.94)
		elif door_profile_key == "door_digital":
			profile["base"] = Color(0.13, 0.22, 0.31, 0.96)
			profile["accent"] = Color(0.38, 0.83, 0.97, 0.99)
			profile["outline"] = Color(0.08, 0.16, 0.22, 0.94)
		elif door_profile_key == "door_powered_gate":
			profile["base"] = Color(0.12, 0.18, 0.26, 0.96)
			profile["accent"] = Color(0.5, 0.9, 1.0, 0.99)
			profile["outline"] = Color(0.07, 0.14, 0.2, 0.94)
	if shape == "slab":
		draw_iso_object_slab(cell, profile, visual_center)
	elif shape == "door_panel":
		draw_iso_object_door_panel(cell, profile, visual_center)
	elif shape == "pillar":
		draw_iso_object_pillar(cell, profile, visual_center)
	elif shape == "terminal_console":
		draw_iso_object_terminal_console(cell, profile, visual_center)
	elif shape == "line":
		draw_iso_object_line(cell, profile, visual_center)
	elif shape == "heat_marker":
		draw_iso_object_heat_marker(cell, profile, visual_center)
	else:
		draw_iso_object_small_marker(cell, profile, visual_center)
	if show_object_grounding_overlay:
		_draw_grounding_overlay(profile_data)

func build_iso_wall_draw_entries() -> Array[Dictionary]:
	if _grid_manager == null:
		return []
	var map_width: int = _grid_manager.get_map_width()
	var map_height: int = _grid_manager.get_map_height()
	if map_width <= 0 or map_height <= 0:
		return []

	var wall_entries: Array[Dictionary] = []
	for y in range(map_height):
		for x in range(map_width):
			var cell: Vector2i = Vector2i(x, y)
			var tile_type: int = _grid_manager.get_tile(cell)
			if not is_wall_tile(tile_type):
				continue
			wall_entries.append({
				"cell": cell,
				"layer": "wall",
				"layer_bias": ISO_LAYER_BIAS_WALL,
				"kind": "wall",
				"payload": {"tile_type": tile_type}
			})
	return wall_entries

func _get_runtime_items_for_cell(cell: Vector2i) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var mission_manager: Node = get_mission_manager_ref()
	if mission_manager == null or not mission_manager.has_method("get_items_at_cell"):
		return result
	var items_variant: Variant = mission_manager.call("get_items_at_cell", cell)
	if not (items_variant is Array):
		return result
	for item_variant in Array(items_variant):
		if item_variant is Dictionary:
			result.append(Dictionary(item_variant))
	return result

func _is_hidden_cable_visual(object_data: Dictionary) -> bool:
	var object_type: String = String(object_data.get("object_type", "")).to_lower()
	if not object_type.contains("cable") and not object_type.contains("wire"):
		return false
	return bool(object_data.get("hidden_installation", object_data.get("concealed", object_data.get("hidden_cable", object_data.get("hidden", false)))))

func _get_runtime_world_objects_for_iso_render() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var mission_manager: Node = get_mission_manager_ref()
	if mission_manager == null:
		return result
	for object_variant in Array(mission_manager.get("mission_world_objects")):
		if not (object_variant is Dictionary):
			continue
		var object_data: Dictionary = Dictionary(object_variant)
		if _is_hidden_cable_visual(object_data):
			continue
		result.append(object_data)
		if String(object_data.get("object_type", "")).to_lower().contains("cable"):
			for path_cell_variant in Array(object_data.get("cable_path_cells", [])):
				var path_cell: Vector2i = _try_parse_cell_variant(path_cell_variant)
				if path_cell.x < 0 or path_cell.y < 0 or path_cell == _try_parse_cell_variant(object_data.get("position", Vector2i(-1, -1))):
					continue
				var path_segment: Dictionary = object_data.duplicate(true)
				path_segment["position"] = path_cell
				result.append(path_segment)
	return result

func build_iso_object_draw_entries() -> Array[Dictionary]:
	# Runtime objects are rendered from their real dictionaries so visuals and
	# interaction lookup stay aligned even when an object occupies a floor tile.
	if _grid_manager == null:
		return []
	var map_width: int = _grid_manager.get_map_width()
	var map_height: int = _grid_manager.get_map_height()
	if map_width <= 0 or map_height <= 0:
		return []
	var runtime_objects_by_cell: Dictionary = {}
	for object_data in _get_runtime_world_objects_for_iso_render():
		var object_cell: Vector2i = _try_parse_cell_variant(object_data.get("position", Vector2i(-1, -1)))
		if object_cell.x < 0 or object_cell.y < 0:
			continue
		var cell_objects: Array = Array(runtime_objects_by_cell.get(object_cell, []))
		cell_objects.append(object_data)
		runtime_objects_by_cell[object_cell] = cell_objects
	var draw_entries: Array[Dictionary] = []
	for y in range(map_height):
		for x in range(map_width):
			var cell: Vector2i = Vector2i(x, y)
			var tile_type: int = _grid_manager.get_tile(cell)
			var runtime_items: Array[Dictionary] = _get_runtime_items_for_cell(cell)
			for item_index in range(runtime_items.size()):
				var item_data: Dictionary = runtime_items[item_index]
				draw_entries.append({"cell":cell, "layer":"item", "layer_bias":ISO_LAYER_BIAS_ITEM + float(item_index) * 0.01, "kind":"object", "payload":{"object_cell":cell, "tile_type":tile_type, "profile_key":get_iso_object_profile_key_for_object_data(item_data, "key"), "object_data":item_data}})
			var runtime_objects: Array = Array(runtime_objects_by_cell.get(cell, []))
			for object_index in range(runtime_objects.size()):
				var object_data: Dictionary = Dictionary(runtime_objects[object_index])
				var profile_key: String = get_iso_object_profile_key_for_object_data(object_data, "generic_object")
				var layer_name: String = "terminal" if is_terminal_like_profile(profile_key) else "item"
				var layer_bias: float = ISO_LAYER_BIAS_TERMINAL if layer_name == "terminal" else ISO_LAYER_BIAS_ITEM
				draw_entries.append({"cell":cell, "layer":layer_name, "layer_bias":layer_bias + float(object_index) * 0.01, "kind":"object", "payload":{"object_cell":cell, "tile_type":tile_type, "profile_key":profile_key, "object_data":object_data}})
			if not runtime_objects.is_empty() or not is_iso_object_tile(tile_type):
				continue
			var profile_key: String = get_iso_object_profile_key_for_tile(tile_type)
			draw_entries.append({"cell":cell, "layer":"item", "layer_bias":ISO_LAYER_BIAS_ITEM, "kind":"object", "payload":{"object_cell":cell, "tile_type":tile_type, "profile_key":profile_key}})
	return draw_entries

func build_iso_geometry_draw_entries(include_walls: bool, include_objects: bool) -> Array[Dictionary]:
	var draw_entries: Array[Dictionary] = []
	if include_walls:
		draw_entries.append_array(build_iso_wall_draw_entries())
	if include_objects:
		draw_entries.append_array(build_iso_object_draw_entries())
	draw_entries.sort_custom(sort_iso_draw_entries)
	return draw_entries

func draw_iso_draw_entry(entry: Dictionary) -> void:
	var kind: String = String(entry.get("kind", ""))
	if kind == "wall":
		var cell: Vector2i = Vector2i(entry.get("cell", Vector2i(-1, -1)))
		if cell.x < 0 or cell.y < 0:
			return
		draw_iso_wall_block(cell)
		return
	if kind == "object":
		var payload: Dictionary = Dictionary(entry.get("payload", {}))
		var object_cell: Vector2i = Vector2i(payload.get("object_cell", Vector2i(-1, -1)))
		if object_cell.x < 0 or object_cell.y < 0:
			return
		var tile_type: int = int(payload.get("tile_type", _grid_manager.get_tile(object_cell)))
		draw_iso_object_marker(object_cell, tile_type, Dictionary(payload.get("object_data", {})))

func draw_iso_geometry_prototype(include_walls: bool, include_objects: bool) -> void:
	if _grid_manager == null:
		return

	var draw_entries: Array[Dictionary] = build_iso_geometry_draw_entries(include_walls, include_objects)
	for entry in draw_entries:
		draw_iso_draw_entry(entry)


func get_iso_fog_color_for_cell(cell: Vector2i) -> Color:
	# Visual-only fog overlay color sampling.
	# GridManager remains the source of truth for visibility/exploration state.
	# This pass reads fog state and never mutates it.
	if _grid_manager == null:
		return Color.TRANSPARENT

	var visible_alpha: float = clampf(iso_fog_visible_alpha, 0.0, 1.0)
	if _grid_manager.is_cell_visible(cell):
		return Color(0.0, 0.0, 0.0, visible_alpha)

	var explored_alpha: float = clampf(iso_fog_explored_alpha, 0.0, 1.0)
	if _grid_manager.is_explored(cell):
		return Color(0.03, 0.05, 0.08, explored_alpha)

	var unexplored_alpha: float = clampf(iso_fog_unexplored_alpha, 0.0, 1.0)
	return Color(0.01, 0.01, 0.02, unexplored_alpha)

func should_draw_iso_fog_for_cell(cell: Vector2i) -> bool:
	if _grid_manager == null:
		return false
	var fog_color: Color = get_iso_fog_color_for_cell(cell)
	return fog_color.a > 0.0

func draw_iso_fog_cell_overlay(cell: Vector2i) -> void:
	var fog_color: Color = get_iso_fog_color_for_cell(cell)
	if fog_color.a <= 0.0:
		return

	var diamond_points: PackedVector2Array = get_iso_inset_diamond_points(cell, iso_floor_visual_inset)
	if diamond_points.size() < 4:
		return
	draw_colored_polygon(diamond_points, fog_color)

	if debug_draw_iso_fog_outlines:
		for edge_index in range(diamond_points.size()):
			var next_index: int = (edge_index + 1) % diamond_points.size()
			draw_line(diamond_points[edge_index], diamond_points[next_index], Color(0.5, 0.6, 0.75, 0.75), 1.0)

func draw_iso_fog_wall_overlay(cell: Vector2i) -> void:
	var fog_color: Color = get_iso_fog_color_for_cell(cell)
	if fog_color.a <= 0.0:
		return

	var base_points: PackedVector2Array = get_iso_wall_base_points(cell)
	if base_points.size() < 4:
		return
	var top_points: PackedVector2Array = get_iso_wall_top_points(cell)
	if top_points.size() < 4:
		return

	var top_face: PackedVector2Array = PackedVector2Array([top_points[0], top_points[1], top_points[2], top_points[3]])
	var left_face: PackedVector2Array = PackedVector2Array([top_points[3], top_points[2], base_points[2], base_points[3]])
	var right_face: PackedVector2Array = PackedVector2Array([top_points[2], top_points[1], base_points[1], base_points[2]])

	draw_colored_polygon(left_face, fog_color)
	draw_colored_polygon(right_face, fog_color)
	draw_colored_polygon(top_face, fog_color)

	if debug_draw_iso_fog_outlines:
		for edge_index in range(top_face.size()):
			var next_top_index: int = (edge_index + 1) % top_face.size()
			draw_line(top_face[edge_index], top_face[next_top_index], Color(0.5, 0.6, 0.75, 0.75), 1.0)

func draw_iso_fog_overlay() -> void:
	# Visual-only fog overlay pass for isometric prototypes.
	# GridManager visibility helpers are read here; gameplay fog logic is not modified.
	if not iso_fog_draw_cell_shapes:
		return
	if _grid_manager == null:
		return

	var map_width: int = _grid_manager.get_map_width()
	var map_height: int = _grid_manager.get_map_height()
	if map_width <= 0 or map_height <= 0:
		return

	var fog_cells: Array[Vector2i] = []
	for y in range(map_height):
		for x in range(map_width):
			var cell: Vector2i = Vector2i(x, y)
			if should_draw_iso_fog_for_cell(cell):
				fog_cells.append(cell)

	fog_cells.sort_custom(sort_cells_by_iso_depth)
	for cell in fog_cells:
		var tile_type: int = _grid_manager.get_tile(cell)
		if tile_type == GridManager.TILE_WALL and should_render_iso_wall_visuals():
			draw_iso_fog_wall_overlay(cell)
		draw_iso_fog_cell_overlay(cell)

func draw_wall_mount_zones_overlay() -> void:
	if _grid_manager == null:
		return
	for y in range(_grid_manager.get_map_height()):
		for x in range(_grid_manager.get_map_width()):
			var wall_cell: Vector2i = Vector2i(x, y)
			if _grid_manager.get_tile(wall_cell) != GridManager.TILE_WALL:
				continue
			var zones: Array[Dictionary] = get_wall_mounted_anchor_zones(wall_cell)
			for zone_variant in zones:
				var zone: Dictionary = Dictionary(zone_variant)
				if not bool(zone.get("mountable", false)):
					continue
				var center: Vector2 = Vector2(zone.get("mount_zone_center", grid_to_iso(wall_cell)))
				draw_circle(center, 2.8, Color(0.35, 0.98, 0.86, 0.95))
				var side: String = String(zone.get("wall_side", ""))
				var label: String = side.substr(0, 1).to_upper()
				draw_string(ThemeDB.fallback_font, center + Vector2(3.0, -4.0), label, HORIZONTAL_ALIGNMENT_LEFT, 12.0, 10, Color(0.9, 0.98, 1.0, 0.9))

func draw_wall_run_overlay() -> void:
	if _grid_manager == null:
		return
	for y in range(_grid_manager.get_map_height()):
		for x in range(_grid_manager.get_map_width()):
			var cell: Vector2i = Vector2i(x, y)
			if _grid_manager.get_tile(cell) != GridManager.TILE_WALL:
				continue
			var topology: Dictionary = get_wall_render_topology(cell)
			var shape: String = String(topology.get("shape", "unknown"))
			var center: Vector2 = grid_to_iso(cell) + Vector2(-28.0, -iso_wall_height - 10.0)
			var label: String = shape
			if bool(topology.get("run_x", false)):
				label += " RX"
			if bool(topology.get("run_y", false)):
				label += " RY"
			var cap_sides: Array = Array(topology.get("cap_sides", []))
			if cap_sides.size() > 0 and shape.begins_with("end_cap_"):
				label += " cap"
			draw_string(ThemeDB.fallback_font, center, label, HORIZONTAL_ALIGNMENT_LEFT, 96.0, 8, Color(1.0, 0.92, 0.42, 0.95))
			for side in WALL_SIDE_ORDER:
				var edge_points: Array[Vector2] = get_iso_diamond_edge_points(get_iso_wall_connected_base_points(cell, topology), side)
				if edge_points.size() < 2:
					continue
				var neighbors: Dictionary = Dictionary(topology.get("neighbors", {}))
				var edge_color: Color = Color(0.25, 1.0, 0.78, 0.82)
				if not bool(neighbors.get(side, false)):
					edge_color = Color(1.0, 0.55, 0.2, 0.9)
				draw_line(edge_points[0], edge_points[1], edge_color, 1.2)

func draw_floor_join_overlay() -> void:
	if _grid_manager == null:
		return
	for y in range(_grid_manager.get_map_height()):
		for x in range(_grid_manager.get_map_width()):
			var cell: Vector2i = Vector2i(x, y)
			var tile_type: int = _grid_manager.get_tile(cell)
			if not is_floor_like_tile(tile_type):
				continue
			var points: PackedVector2Array = get_iso_diamond_points(cell)
			for side in WALL_SIDE_ORDER:
				var edge_points: Array[Vector2] = get_iso_diamond_edge_points(points, side)
				if edge_points.size() < 2:
					continue
				var shown: bool = should_draw_floor_edge_border(cell, side)
				var edge_color: Color = Color(0.25, 0.9, 1.0, 0.35)
				var edge_width: float = 0.65
				if shown:
					edge_color = Color(1.0, 0.82, 0.25, 0.92)
					edge_width = 1.35
				draw_line(edge_points[0], edge_points[1], edge_color, edge_width)

func _draw() -> void:
	if debug_draw_marker:
		draw_circle(Vector2.ZERO, 3.0, Color(0.8, 0.95, 1.0, 0.75))

	# Isometric render pass order (compatibility-focused):
	# 1) floor/base
	# 2) unified walls+objects queue (depth-sorted with layer bias)
	# 3) constructor/selection overlays
	# 4) fog/final overlay
	if should_render_iso_floor_visuals():
		draw_iso_floor_prototype()

	var include_walls: bool = should_render_iso_wall_visuals()
	var include_objects: bool = should_render_iso_object_visuals()
	if include_walls or include_objects:
		draw_iso_geometry_prototype(include_walls, include_objects)
	if show_wall_mount_zones_overlay and include_walls:
		draw_wall_mount_zones_overlay()
	if show_wall_run_overlay and include_walls:
		draw_wall_run_overlay()
	if show_floor_join_overlay and should_render_iso_floor_visuals():
		draw_floor_join_overlay()

	draw_iso_mouse_selection_overlay()
	draw_map_constructor_visual_overlay_passes()

	if should_render_iso_fog_visuals():
		draw_iso_fog_overlay()

	if not debug_draw_iso_helper_preview:
		return

	var preview_points: PackedVector2Array = get_iso_diamond_points(Vector2i.ZERO)
	draw_colored_polygon(preview_points, Color(0.2, 0.8, 1.0, 0.15))
	for idx in range(preview_points.size()):
		var next_idx: int = (idx + 1) % preview_points.size()
		draw_line(preview_points[idx], preview_points[next_idx], Color(0.2, 0.8, 1.0, 0.9), 1.0)
