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
@export var use_iso_visual_preview_preset: bool = false
@export var iso_visual_preview_includes_fog: bool = true
@export var iso_visual_preview_includes_asset_hooks: bool = false
@export var iso_visual_preview_drives_bipob_visual_position: bool = true
@export var debug_draw_iso_fog_outlines: bool = false
@export var iso_fog_unexplored_alpha: float = 0.82
@export var iso_fog_explored_alpha: float = 0.42
@export var iso_fog_visible_alpha: float = 0.0
@export var debug_draw_iso_cell_outlines: bool = true
@export var debug_draw_iso_wall_outlines: bool = true
@export var debug_draw_iso_object_outlines: bool = true
@export var use_iso_tile_asset_hooks: bool = false
@export var use_iso_placeholder_asset_preset: bool = false
@export var iso_placeholder_asset_preset_requires_preview: bool = true
@export var iso_floor_default_texture: Texture2D = null
@export var iso_floor_stepped_texture: Texture2D = null
@export var iso_floor_door_underlay_texture: Texture2D = null
@export var iso_wall_default_texture: Texture2D = null
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
@export var iso_tile_width: float = 128.0
@export var iso_tile_height: float = 64.0
@export var iso_wall_height: float = 56.0
@export var iso_object_marker_height: float = 18.0
@export var iso_origin: Vector2 = Vector2.ZERO

# Dev-only placeholder preset: loads BIP-Visual-011 SVG placeholders as visual fallback textures.
# Explicit exported Texture2D hooks always take priority when assigned.
# Missing/unsupported placeholder resources safely fall back to procedural rendering.
# Visual-only behavior; no gameplay state is changed.
const ISO_PLACEHOLDER_ASSET_PATHS: Dictionary = {
	"floor_default": "res://assets/visual/isometric/placeholders/iso_floor_default.svg",
	"floor_stepped": "res://assets/visual/isometric/placeholders/iso_floor_stepped.svg",
	"floor_door_underlay": "res://assets/visual/isometric/placeholders/iso_floor_door_underlay.svg",
	"wall_default": "res://assets/visual/isometric/placeholders/iso_wall_default.svg",
	"wall_damaged": "res://assets/visual/isometric/placeholders/iso_wall_damaged.svg",
	"wall_steel": "res://assets/visual/isometric/placeholders/iso_wall_steel.svg",
	"wall_energy": "res://assets/visual/isometric/placeholders/iso_wall_energy.svg",
	"object_door": "res://assets/visual/isometric/placeholders/iso_object_door.svg",
	"object_terminal": "res://assets/visual/isometric/placeholders/iso_object_terminal.svg",
	"object_key": "res://assets/visual/isometric/placeholders/iso_object_key.svg",
	"object_component": "res://assets/visual/isometric/placeholders/iso_object_component.svg",
	"object_socket": "res://assets/visual/isometric/placeholders/iso_object_socket.svg",
	"object_cable": "res://assets/visual/isometric/placeholders/iso_object_cable.svg",
	"object_generic": "res://assets/visual/isometric/placeholders/iso_object_generic.svg"
}

var _iso_placeholder_texture_cache: Dictionary = {}
var _grid_manager: GridManager = null
var _rebuild_requested: bool = false

func set_grid_manager(grid: GridManager) -> void:
	_grid_manager = grid
	request_rebuild()

func initialize_from_grid(grid: GridManager) -> void:
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

func should_render_iso_floor_visuals() -> bool:
	return (render_iso_floor_prototype or use_iso_visual_preview_preset)

func should_render_iso_wall_visuals() -> bool:
	return (render_iso_wall_prototype or use_iso_visual_preview_preset)

func should_render_iso_object_visuals() -> bool:
	return (render_iso_object_prototype or use_iso_visual_preview_preset)

func should_render_iso_fog_visuals() -> bool:
	return (render_iso_fog_overlay or (use_iso_visual_preview_preset and iso_visual_preview_includes_fog))

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

func should_preview_drive_bipob_visual_position() -> bool:
	return (use_iso_visual_preview_preset and iso_visual_preview_drives_bipob_visual_position)

func get_iso_visual_preview_state() -> Dictionary:
	return {
		"preview_active": is_iso_visual_preview_active(),
		"floor": should_render_iso_floor_visuals(),
		"wall": should_render_iso_wall_visuals(),
		"objects": should_render_iso_object_visuals(),
		"fog": should_render_iso_fog_visuals(),
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
	return Vector2(safe_width * 0.5, safe_height * 0.5)

func grid_to_iso(cell: Vector2i) -> Vector2:
	# Converts gameplay grid coordinates (Vector2i) into visual isometric space.
	var half_size: Vector2 = get_iso_tile_half_size()
	var iso_x: float = float(cell.x - cell.y) * half_size.x
	var iso_y: float = float(cell.x + cell.y) * half_size.y
	return iso_origin + Vector2(iso_x, iso_y)

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

func get_iso_depth_key(cell: Vector2i) -> int:
	return cell.x + cell.y

func sort_cells_by_iso_depth(a: Vector2i, b: Vector2i) -> bool:
	var depth_a: int = get_iso_depth_key(a)
	var depth_b: int = get_iso_depth_key(b)
	if depth_a == depth_b:
		if a.y == b.y:
			return a.x < b.x
		return a.y < b.y
	return depth_a < depth_b

func is_floor_like_tile(tile_type: int) -> bool:
	return tile_type != GridManager.TILE_WALL

func is_wall_tile(tile_type: int) -> bool:
	return tile_type == GridManager.TILE_WALL

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
		"damaged_wall":
			return "wall_damaged"
		"steel_wall", "reinforced_steel_wall", "titanium_wall":
			return "wall_steel"
		"energy_wall":
			return "wall_energy"
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
		"component":
			return "object_component"
		"socket":
			return "object_socket"
		"cable", "cable_reel":
			return "object_cable"
		_:
			return "object_generic"

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

func get_explicit_iso_texture_for_asset_key(asset_key: String) -> Texture2D:
	match asset_key:
		"floor_default":
			return iso_floor_default_texture
		"floor_stepped":
			return iso_floor_stepped_texture
		"floor_door_underlay":
			return iso_floor_door_underlay_texture
		"wall_default":
			return iso_wall_default_texture
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
		"asset_hooks_enabled": should_use_iso_tile_asset_hook_visuals(),
		"placeholder_assets_enabled": should_use_iso_placeholder_asset_preset(),
		"preview_active": is_iso_visual_preview_active(),
		"debug_marker": debug_draw_marker,
		"helper_preview": debug_draw_iso_helper_preview,
		"fog_outlines": debug_draw_iso_fog_outlines,
		"cell_outlines": debug_draw_iso_cell_outlines,
		"wall_outlines": debug_draw_iso_wall_outlines,
		"object_outlines": debug_draw_iso_object_outlines
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
		"floor_default", "floor_stepped", "floor_door_underlay",
		"wall_default", "wall_damaged", "wall_steel", "wall_energy",
		"object_door", "object_terminal", "object_key", "object_component",
		"object_socket", "object_cable", "object_generic"
	]

func get_iso_visual_debug_report() -> Dictionary:
	var has_grid_manager: bool = _grid_manager != null
	var map_width: int = 0
	var map_height: int = 0
	if has_grid_manager:
		map_width = _grid_manager.get_map_width()
		map_height = _grid_manager.get_map_height()
	return {
		"layers": get_iso_visual_layer_debug_state(),
		"preview": get_iso_visual_preview_state(),
		"textures": get_iso_visual_texture_debug_state(),
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
	var grid: Dictionary = Dictionary(report.get("grid", {}))
	var iso_settings: Dictionary = Dictionary(report.get("iso_settings", {}))
	lines.append("IsoVisualDebugReport:")
	lines.append("Layers:")
	lines.append("- floor: %s" % str(layers.get("floor_enabled", false)))
	lines.append("- wall: %s" % str(layers.get("wall_enabled", false)))
	lines.append("- objects: %s" % str(layers.get("object_enabled", false)))
	lines.append("- fog: %s" % str(layers.get("fog_enabled", false)))
	lines.append("- asset_hooks: %s" % str(layers.get("asset_hooks_enabled", false)))
	lines.append("- placeholder_assets: %s" % str(layers.get("placeholder_assets_enabled", false)))
	lines.append("Preview:")
	lines.append("- active: %s" % str(preview.get("preview_active", false)))
	lines.append("- includes_fog: %s" % str(iso_visual_preview_includes_fog))
	lines.append("- includes_asset_hooks: %s" % str(iso_visual_preview_includes_asset_hooks))
	lines.append("Textures:")
	for texture_key in get_iso_visual_texture_debug_keys():
		var texture_entry: Dictionary = Dictionary(textures.get(texture_key, {}))
		lines.append("- %s: %s" % [texture_key, str(texture_entry.get("active_texture_source", "none"))])
	lines.append("Grid:")
	lines.append("- has_grid_manager: %s" % str(grid.get("has_grid_manager", false)))
	lines.append("- map_size: %sx%s" % [str(grid.get("map_width", 0)), str(grid.get("map_height", 0))])
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
	if use_iso_placeholder_asset_preset and iso_placeholder_asset_preset_requires_preview and not is_iso_visual_preview_active():
		warnings.append("iso_placeholder_preset_waiting_for_preview")
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

func get_iso_texture_draw_position(cell: Vector2i, texture: Texture2D) -> Vector2:
	# Future asset hook: this is a provisional bottom-center-ish alignment.
	# Final art pivot and per-asset offset tuning will be handled in follow-up PRs.
	var center: Vector2 = grid_to_iso(cell)
	var size: Vector2 = texture.get_size()
	return center - Vector2(size.x * 0.5, size.y * 0.75)

func draw_iso_texture_asset(cell: Vector2i, asset_key: String) -> bool:
	# Asset hooks are optional. Procedural fallback remains the default path.
	if not should_use_iso_tile_asset_hook_visuals():
		return false
	if asset_key.is_empty():
		return false
	var texture: Texture2D = get_iso_texture_for_asset_key(asset_key)
	if texture == null:
		return false
	var draw_position: Vector2 = get_iso_texture_draw_position(cell, texture)
	draw_texture(texture, draw_position)
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

	return {
		"top": top_color,
		"left": left_color,
		"right": right_color,
		"outline": _get_color_from_dict(profile, "outline", Color(0.24, 0.31, 0.36, 0.9)),
		"accent": _get_color_from_dict(profile, "accent", Color(0.29, 0.35, 0.4, 0.5))
	}

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
			"top": Color(0.17, 0.205, 0.235, 0.98),
			"left": Color(0.095, 0.125, 0.15, 0.98),
			"right": Color(0.08, 0.11, 0.135, 0.98),
			"outline": Color(0.23, 0.31, 0.37, 0.9),
			"accent": Color(0.31, 0.41, 0.48, 0.52)
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
			"top": Color(0.215, 0.165, 0.145, 0.98),
			"left": Color(0.14, 0.105, 0.09, 0.98),
			"right": Color(0.12, 0.09, 0.08, 0.98),
			"outline": Color(0.34, 0.25, 0.22, 0.9),
			"accent": Color(0.41, 0.28, 0.2, 0.48)
		},
		"concrete_wall": {
			"label": "Concrete Wall",
			"top": Color(0.23, 0.24, 0.25, 0.98),
			"left": Color(0.155, 0.16, 0.17, 0.98),
			"right": Color(0.13, 0.135, 0.145, 0.98),
			"outline": Color(0.3, 0.33, 0.35, 0.9),
			"accent": Color(0.35, 0.39, 0.42, 0.45)
		},
		"steel_wall": {
			"label": "Steel Wall",
			"top": Color(0.195, 0.23, 0.27, 0.98),
			"left": Color(0.12, 0.15, 0.185, 0.98),
			"right": Color(0.1, 0.13, 0.165, 0.98),
			"outline": Color(0.25, 0.34, 0.4, 0.9),
			"accent": Color(0.34, 0.45, 0.53, 0.52)
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
	# Visual-only behavior for BIP-Visual-006:
	# all gameplay wall cells currently share the default visual wall profile.
	# Future PRs may map this key from mission/world metadata (for example via WorldObjectCatalog IDs).
	return get_default_wall_visual_profile_key()

func get_iso_wall_top_points(cell: Vector2i) -> PackedVector2Array:
	var bottom_points: PackedVector2Array = get_iso_diamond_points(cell)
	var top_points: PackedVector2Array = PackedVector2Array()
	var safe_wall_height: float = maxf(iso_wall_height, 1.0)
	var wall_offset: Vector2 = Vector2(0.0, -safe_wall_height)
	for point in bottom_points:
		top_points.append(point + wall_offset)
	return top_points

func draw_iso_wall_block(cell: Vector2i) -> void:
	var wall_profile_key: String = get_wall_visual_profile_key_for_cell(cell)
	var wall_asset_key: String = get_iso_wall_asset_key_for_profile(wall_profile_key)
	if draw_iso_texture_asset(cell, wall_asset_key):
		return

	var bottom_points: PackedVector2Array = get_iso_diamond_points(cell)
	if bottom_points.size() < 4:
		return
	var top_points: PackedVector2Array = get_iso_wall_top_points(cell)
	if top_points.size() < 4:
		return

	var colors: Dictionary = get_wall_prototype_colors(cell)
	var top_face: PackedVector2Array = PackedVector2Array([top_points[0], top_points[1], top_points[2], top_points[3]])
	var left_face: PackedVector2Array = PackedVector2Array([top_points[3], top_points[2], bottom_points[2], bottom_points[3]])
	var right_face: PackedVector2Array = PackedVector2Array([top_points[2], top_points[1], bottom_points[1], bottom_points[2]])

	var left_color: Color = _get_color_from_dict(colors, "left", Color.WHITE)
	var right_color: Color = _get_color_from_dict(colors, "right", Color.WHITE)
	var top_color: Color = _get_color_from_dict(colors, "top", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(colors, "outline", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(colors, "accent", Color.WHITE)

	draw_colored_polygon(left_face, left_color)
	draw_colored_polygon(right_face, right_color)
	draw_colored_polygon(top_face, top_color)

	if debug_draw_iso_wall_outlines:
		for edge_idx in range(top_face.size()):
			var top_next_idx: int = (edge_idx + 1) % top_face.size()
			draw_line(top_face[edge_idx], top_face[top_next_idx], outline_color, 1.0)

		for edge_idx in range(left_face.size()):
			var left_next_idx: int = (edge_idx + 1) % left_face.size()
			draw_line(left_face[edge_idx], left_face[left_next_idx], outline_color, 1.0)

		for edge_idx in range(right_face.size()):
			var right_next_idx: int = (edge_idx + 1) % right_face.size()
			draw_line(right_face[edge_idx], right_face[right_next_idx], outline_color, 1.0)

	var accent_start: Vector2 = top_points[3].lerp(top_points[0], 0.4)
	var accent_end: Vector2 = top_points[0].lerp(top_points[1], 0.45)
	draw_line(accent_start, accent_end, accent_color, 1.2)

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
			if draw_iso_texture_asset(cell, floor_asset_key):
				continue

			var diamond_points: PackedVector2Array = get_iso_diamond_points(cell)
			var fill_color: Color = get_floor_prototype_color(tile_type, cell)
			draw_colored_polygon(diamond_points, fill_color)
			if debug_draw_iso_cell_outlines:
				for edge_index in range(diamond_points.size()):
					var next_index: int = (edge_index + 1) % diamond_points.size()
					draw_line(diamond_points[edge_index], diamond_points[next_index], Color(0.21, 0.33, 0.39, 0.85), 1.0)

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
		"door": {"base": Color(0.3, 0.21, 0.15, 0.95), "accent": Color(0.58, 0.41, 0.22, 0.95), "outline": Color(0.16, 0.11, 0.08, 0.92), "label": "Door", "shape": "slab"},
		"digital_door": {"base": Color(0.15, 0.25, 0.33, 0.95), "accent": Color(0.36, 0.73, 0.88, 0.95), "outline": Color(0.08, 0.15, 0.2, 0.92), "label": "Digital Door", "shape": "slab"},
		"powered_gate": {"base": Color(0.17, 0.22, 0.3, 0.95), "accent": Color(0.43, 0.81, 0.94, 0.95), "outline": Color(0.1, 0.15, 0.2, 0.92), "label": "Powered Gate", "shape": "slab"},
		"terminal": {"base": Color(0.16, 0.3, 0.36, 0.95), "accent": Color(0.48, 0.9, 0.84, 0.95), "outline": Color(0.08, 0.16, 0.19, 0.92), "label": "Terminal", "shape": "pillar"},
		"airflow_terminal": {"base": Color(0.16, 0.25, 0.31, 0.95), "accent": Color(0.54, 0.82, 0.93, 0.95), "outline": Color(0.08, 0.14, 0.18, 0.92), "label": "Airflow Terminal", "shape": "pillar"},
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
		"cable": {"base": Color(0.16, 0.17, 0.19, 0.95), "accent": Color(0.89, 0.87, 0.73, 0.95), "outline": Color(0.09, 0.1, 0.12, 0.92), "label": "Cable", "shape": "line"},
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

func draw_iso_object_slab(cell: Vector2i, profile: Dictionary) -> void:
	var center: Vector2 = grid_to_iso(cell)
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

func draw_iso_object_pillar(cell: Vector2i, profile: Dictionary) -> void:
	var center: Vector2 = grid_to_iso(cell)
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

func draw_iso_object_small_marker(cell: Vector2i, profile: Dictionary) -> void:
	var center: Vector2 = grid_to_iso(cell) + Vector2(0.0, -6.0)
	var radius: float = maxf(get_iso_tile_half_size().y * 0.16, 3.0)
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	draw_circle(center, radius, base_color)
	draw_circle(center + Vector2(0.0, -radius * 0.3), radius * 0.45, accent_color)
	if debug_draw_iso_object_outlines:
		draw_arc(center, radius, 0.0, PI * 2.0, 24, outline_color, 1.0)

func draw_iso_object_line(cell: Vector2i, profile: Dictionary) -> void:
	var center: Vector2 = grid_to_iso(cell) + Vector2(0.0, -4.0)
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

func draw_iso_object_heat_marker(cell: Vector2i, profile: Dictionary) -> void:
	var center: Vector2 = grid_to_iso(cell) + Vector2(0.0, -7.0)
	var radius: float = maxf(get_iso_tile_half_size().y * 0.18, 3.5)
	var base_color: Color = _get_color_from_dict(profile, "base", Color.WHITE)
	var accent_color: Color = _get_color_from_dict(profile, "accent", Color.WHITE)
	var outline_color: Color = _get_color_from_dict(profile, "outline", Color.WHITE)
	draw_circle(center, radius, base_color)
	draw_circle(center, radius * 0.58, accent_color)
	if debug_draw_iso_object_outlines:
		draw_arc(center, radius, 0.0, PI * 2.0, 24, outline_color, 1.0)

func draw_iso_object_marker(cell: Vector2i, tile_type: int) -> void:
	var profile_key: String = get_iso_object_profile_key_for_tile(tile_type)
	var object_asset_key: String = get_iso_object_asset_key_for_profile(profile_key)
	if draw_iso_texture_asset(cell, object_asset_key):
		return
	var profile: Dictionary = get_iso_object_profile(profile_key)
	var shape: String = str(profile.get("shape", "small_marker"))
	if shape == "slab":
		draw_iso_object_slab(cell, profile)
	elif shape == "pillar":
		draw_iso_object_pillar(cell, profile)
	elif shape == "line":
		draw_iso_object_line(cell, profile)
	elif shape == "heat_marker":
		draw_iso_object_heat_marker(cell, profile)
	else:
		draw_iso_object_small_marker(cell, profile)

func draw_iso_object_prototype() -> void:
	# Visual-only procedural object prototype pass for interactive tile markers.
	# Final object assets and real metadata-driven mapping will be implemented later.
	if _grid_manager == null:
		return
	var map_width: int = _grid_manager.get_map_width()
	var map_height: int = _grid_manager.get_map_height()
	if map_width <= 0 or map_height <= 0:
		return

	var object_cells: Array[Vector2i] = []
	for y in range(map_height):
		for x in range(map_width):
			var cell: Vector2i = Vector2i(x, y)
			var tile_type: int = _grid_manager.get_tile(cell)
			if is_iso_object_tile(tile_type):
				object_cells.append(cell)

	object_cells.sort_custom(sort_cells_by_iso_depth)
	for cell in object_cells:
		var tile_type: int = _grid_manager.get_tile(cell)
		draw_iso_object_marker(cell, tile_type)


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

	var diamond_points: PackedVector2Array = get_iso_diamond_points(cell)
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

	var bottom_points: PackedVector2Array = get_iso_diamond_points(cell)
	if bottom_points.size() < 4:
		return
	var top_points: PackedVector2Array = get_iso_wall_top_points(cell)
	if top_points.size() < 4:
		return

	var top_face: PackedVector2Array = PackedVector2Array([top_points[0], top_points[1], top_points[2], top_points[3]])
	var left_face: PackedVector2Array = PackedVector2Array([top_points[3], top_points[2], bottom_points[2], bottom_points[3]])
	var right_face: PackedVector2Array = PackedVector2Array([top_points[2], top_points[1], bottom_points[1], bottom_points[2]])

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

func _draw() -> void:
	if debug_draw_marker:
		draw_circle(Vector2.ZERO, 3.0, Color(0.8, 0.95, 1.0, 0.75))

	if should_render_iso_floor_visuals():
		draw_iso_floor_prototype()

	if should_render_iso_wall_visuals():
		draw_iso_wall_prototype()

	if should_render_iso_object_visuals():
		draw_iso_object_prototype()

	if should_render_iso_fog_visuals():
		draw_iso_fog_overlay()

	if not debug_draw_iso_helper_preview:
		return

	var preview_points: PackedVector2Array = get_iso_diamond_points(Vector2i.ZERO)
	draw_colored_polygon(preview_points, Color(0.2, 0.8, 1.0, 0.15))
	for idx in range(preview_points.size()):
		var next_idx: int = (idx + 1) % preview_points.size()
		draw_line(preview_points[idx], preview_points[next_idx], Color(0.2, 0.8, 1.0, 0.9), 1.0)
