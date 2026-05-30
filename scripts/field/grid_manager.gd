extends Node2D
class_name GridManager

const TILE_FLOOR := 0
const TILE_WALL := 1
const TILE_DOOR := 2
const TILE_KEY := 3
const TILE_EXIT := 4
const TILE_TERMINAL := 5
const TILE_DIGITAL_DOOR := 6
const TILE_COMPONENT := 7
const TILE_HIDDEN_ROUTE_NODE := 8
const TILE_ROUTE_GATE := 9
const TILE_HOT_NODE := 10
const TILE_AIRFLOW_TERMINAL := 11
const TILE_FAN_PLATFORM := 12
const TILE_PLATFORM_CONTROL := 13
const TILE_FAN_CONTROL := 14
const TILE_AIRFLOW := 15
const TILE_PLATFORM_CONTROL_LEFT := 16
const TILE_PLATFORM_CONTROL_RIGHT := 17
const TILE_FAN_SPEED_UP_CONTROL := 18
const TILE_FAN_SPEED_DOWN_CONTROL := 19
const TILE_CABLE_REEL := 20
const TILE_SOCKET := 21
const TILE_POWERED_GATE := 22
const TILE_CABLE := 23
const TILE_STEPPED_FLOOR := 24

const FLOOR_FAMILY_GRATE := "grate"
const FLOOR_FAMILY_METAL := "metal"
const FLOOR_FAMILY_CONCRETE := "concrete"
const FLOOR_WEAR_NONE := "none"
const FLOOR_WEAR_LIGHT := "light_wear"
const FLOOR_WEAR_HEAVY := "heavy_damage"
const FLOOR_HEAVY_DAMAGE_WHEELED_MOVE_MODIFIER := -1

@export var cell_size: int = 64
@export var fog_enabled: bool = true
@export var reveal_radius: int = 1
@export var debug_draw_legacy_grid: bool = false

var debug_draw_undiscovered_hidden_nodes: bool = false
var fan_platform_marker_position: Vector2i = Vector2i(-1, -1)
var fan_platform_marker_direction: Vector2i = Vector2i.RIGHT

var visible_cells: Array = []
var explored_cells: Array = []
var discovered_hidden_route_nodes: Dictionary = {}
var world_overlay_markers: Dictionary = {}
var floor_visual_states: Dictionary = {}

var map_data: Array = [
	[1, 1, 1, 1, 1, 1, 1, 1],
	[1, 0, 0, 0, 0, 0, 2, 1],
	[1, 0, 1, 1, 0, 5, 6, 1],
	[1, 0, 0, 0, 0, 1, 0, 1],
	[1, 0, 0, 3, 0, 1, 7, 1],
	[1, 0, 1, 1, 0, 0, 0, 1],
	[1, 0, 0, 0, 0, 4, 0, 1],
	[1, 1, 1, 1, 1, 1, 1, 1],
]


var mission_initial_map_data: Array = []
@onready var room_visual_renderer: RoomVisualRenderer = get_node_or_null("RoomVisualRenderer")

var tile_colors := {
	TILE_FLOOR: Color(0.16, 0.16, 0.18),
	TILE_WALL: Color(0.05, 0.05, 0.06),
	TILE_DOOR: Color(0.45, 0.25, 0.08),
	TILE_KEY: Color(0.95, 0.75, 0.15),
	TILE_EXIT: Color(0.15, 0.65, 0.35),
	TILE_TERMINAL: Color(0.6, 0.25, 0.75),
	TILE_DIGITAL_DOOR: Color(0.1, 0.4, 0.85),
	TILE_COMPONENT: Color(0.9, 0.45, 0.15),
	TILE_HIDDEN_ROUTE_NODE: Color(0.16, 0.16, 0.18),
	TILE_ROUTE_GATE: Color(0.12, 0.56, 0.7),
	TILE_HOT_NODE: Color(1.0, 0.25, 0.1),
	TILE_AIRFLOW_TERMINAL: Color(0.75, 0.2, 0.85),
	TILE_FAN_PLATFORM: Color(0.45, 0.47, 0.52),
	TILE_PLATFORM_CONTROL: Color(0.95, 0.8, 0.22),
	TILE_FAN_CONTROL: Color(0.2, 0.8, 1.0),
	TILE_AIRFLOW: Color(0.45, 0.85, 1.0, 0.65),
	TILE_PLATFORM_CONTROL_LEFT: Color(0.95, 0.68, 0.2),
	TILE_PLATFORM_CONTROL_RIGHT: Color(0.8, 0.9, 0.24),
	TILE_FAN_SPEED_UP_CONTROL: Color(0.2, 0.82, 1.0),
	TILE_FAN_SPEED_DOWN_CONTROL: Color(0.33, 0.24, 0.72),
	TILE_CABLE_REEL: Color(0.95, 0.62, 0.2),
	TILE_SOCKET: Color(0.2, 0.55, 0.95),
	TILE_POWERED_GATE: Color(0.92, 0.38, 0.2),
	TILE_CABLE: Color(0.22, 0.88, 0.72),
	TILE_STEPPED_FLOOR: Color(0.46, 0.42, 0.36),
}

func _ready() -> void:
	cache_initial_mission_layout()
	setup_fog_arrays()
	# GridManager remains gameplay truth; RoomVisualRenderer is visual-only.
	if room_visual_renderer != null:
		room_visual_renderer.initialize_from_grid(self)
	request_visual_refresh()


func duplicate_map_layout(layout: Array) -> Array:
	var duplicated_layout: Array = []
	for row_variant in layout:
		var row: Array = row_variant
		duplicated_layout.append(row.duplicate())
	return duplicated_layout

func cache_initial_mission_layout() -> void:
	mission_initial_map_data = duplicate_map_layout(map_data)

func get_mission4_layout() -> Array:
	return [
		[1, 1, 1, 1, 1, 1, 1, 1],
		[1, 0, 0, 0, 7, 0, 0, 1],
		[1, 0, 1, 1, 1, 1, 0, 1],
		[1, 0, 0, 0, 0, 1, 0, 1],
		[1, 1, 1, 1, 0, 1, 0, 1],
		[1, 0, 0, 0, 0, 0, 0, 1],
		[1, 0, 7, 0, 8, 0, 4, 1],
		[1, 1, 1, 1, 1, 1, 1, 1],
	]

func get_mission6_layout() -> Array:
	return [
		[1, 1, 1, 1, 1, 1, 1, 1],
		[1, 0, 0, 0, 0, 0, 0, 1],
		[1, 0, 1, 1, 1, 1, 0, 1],
		[1, 0, 0, 0, TILE_HOT_NODE, 6, 0, 1],
		[1, 1, 1, 0, 1, 1, 0, 1],
		[1, 0, 0, 0, 0, 0, 0, 1],
		[1, 0, 1, 1, 1, 1, 4, 1],
		[1, 1, 1, 1, 1, 1, 1, 1],
	]


func get_mission8_layout() -> Array:
	return [
		[1, 1, 1, 1, 1, 1, 1, 1],
		[1, 0, 0, 0, 0, 0, 0, 1],
		[1, 0, TILE_PLATFORM_CONTROL_LEFT, 0, TILE_FAN_PLATFORM, TILE_PLATFORM_CONTROL_RIGHT, 0, 1],
		[1, 0, TILE_FAN_SPEED_UP_CONTROL, 0, 0, 0, TILE_AIRFLOW_TERMINAL, 1],
		[1, 0, TILE_FAN_SPEED_DOWN_CONTROL, 0, 0, 0, TILE_DIGITAL_DOOR, 1],
		[1, 0, 0, 0, 0, 0, 0, 1],
		[1, 0, 1, 1, 1, 1, 4, 1],
		[1, 1, 1, 1, 1, 1, 1, 1],
	]


func get_mission9_layout() -> Array:
	return [
		[1, 1, 1, 1, 1, 1, 1, 1],
		[1, 0, 0, 7, 0, 0, 0, 1],
		[1, 0, 1, 1, 1, 1, 0, 1],
		[1, 0, 0, TILE_STEPPED_FLOOR, TILE_STEPPED_FLOOR, TILE_STEPPED_FLOOR, 0, 1],
		[1, 1, 1, 1, 1, TILE_STEPPED_FLOOR, 1, 1],
		[1, 0, 0, 0, 0, TILE_STEPPED_FLOOR, 0, 1],
		[1, 0, 1, 1, 0, 0, 4, 1],
		[1, 1, 1, 1, 1, 1, 1, 1],
	]
func get_mission7_layout() -> Array:
	return [
		[1, 1, 1, 1, 1, 1, 1, 1],
		[1, 0, TILE_CABLE_REEL, 0, 0, 0, 0, 1],
		[1, 0, 1, 1, 1, 1, 0, 1],
		[1, 0, 0, 0, 0, TILE_SOCKET, 0, 1],
		[1, 1, 1, 0, 1, 1, TILE_POWERED_GATE, 1],
		[1, 0, 0, 0, 0, 0, 0, 1],
		[1, 0, 1, 1, 1, 1, 4, 1],
		[1, 1, 1, 1, 1, 1, 1, 1],
	]

func get_mission10_layout() -> Array:
	# TASK TEST universal systems testbed layout (16x10)
	return [
		[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
		[1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
		[1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1],
		[1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
		[1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1],
		[1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
		[1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1],
		[1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 1],
		[1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
		[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
	]

func reset_mission_layout(mission_index: int) -> void:
	if mission_initial_map_data.is_empty():
		cache_initial_mission_layout()

	if mission_index == 4:
		map_data = duplicate_map_layout(get_mission4_layout())
	elif mission_index == 6:
		map_data = duplicate_map_layout(get_mission6_layout())
	elif mission_index == 7:
		map_data = duplicate_map_layout(get_mission7_layout())
	elif mission_index == 8:
		map_data = duplicate_map_layout(get_mission8_layout())
	elif mission_index == 9:
		map_data = duplicate_map_layout(get_mission9_layout())
	elif mission_index == 10:
		map_data = duplicate_map_layout(get_mission10_layout())
	else:
		map_data = duplicate_map_layout(mission_initial_map_data)
	reset_hidden_discoveries()
	request_visual_refresh()

func apply_mission_layout(layout: Array) -> bool:
	if layout.is_empty():
		return false
	var expected_row_width: int = -1
	for row_variant in layout:
		if not (row_variant is Array):
			return false
		var row: Array = Array(row_variant)
		if row.is_empty():
			return false
		if expected_row_width == -1:
			expected_row_width = row.size()
		elif row.size() != expected_row_width:
			return false
	if expected_row_width <= 0:
		return false
	map_data = duplicate_map_layout(layout)
	reset_hidden_discoveries()
	request_visual_refresh()
	return true

func reset_fog_of_war() -> void:
	setup_fog_arrays()
	request_visual_refresh()

func should_draw_legacy_grid() -> bool:
	if not debug_draw_legacy_grid:
		return false
	var renderer: RoomVisualRenderer = get_room_visual_renderer_for_visual_mode()
	if renderer != null and renderer.is_iso_renderer_active():
		return false
	return true

func get_room_visual_renderer_for_visual_mode() -> RoomVisualRenderer:
	var renderer_node: Node = room_visual_renderer
	if renderer_node == null:
		renderer_node = get_node_or_null("RoomVisualRenderer")
	if renderer_node != null and renderer_node is RoomVisualRenderer:
		return renderer_node as RoomVisualRenderer
	return null

func get_visual_render_mode_summary() -> Dictionary:
	var renderer: RoomVisualRenderer = get_room_visual_renderer_for_visual_mode()
	var renderer_found: bool = renderer != null
	var renderer_active: bool = false
	if renderer_found:
		renderer_active = renderer.is_iso_renderer_active()
	var legacy_will_draw: bool = should_draw_legacy_grid()
	return {
		"legacy_grid_debug_enabled": debug_draw_legacy_grid,
		"legacy_grid_will_draw": legacy_will_draw,
		"room_visual_renderer_found": renderer_found,
		"iso_renderer_active": renderer_active,
		"single_render_path_ok": not (legacy_will_draw and renderer_active)
	}

func _draw() -> void:
	if not should_draw_legacy_grid():
		return
	for y in range(map_data.size()):
		for x in range(map_data[y].size()):
			var grid_position: Vector2i = Vector2i(x, y)
			var tile_type: int = map_data[y][x]
			var cell_position: Vector2 = Vector2(x * cell_size, y * cell_size)
			var rect: Rect2 = Rect2(cell_position, Vector2(cell_size, cell_size))
			
			var color: Color = tile_colors.get(tile_type, Color.MAGENTA)
			if tile_type == TILE_HIDDEN_ROUTE_NODE and not is_hidden_route_node_discovered(grid_position):
				color = tile_colors.get(TILE_FLOOR, Color(0.16, 0.16, 0.18))
			
			draw_rect(rect, color, true)
			if tile_type == TILE_AIRFLOW:
				var floor_color: Color = tile_colors.get(TILE_FLOOR, Color(0.16, 0.16, 0.18))
				draw_rect(rect, floor_color, true)
				var strip_size: Vector2 = Vector2(cell_size * 0.52, cell_size * 0.12)
				var strip_rect: Rect2 = Rect2(rect.get_center() - strip_size * 0.5, strip_size)
				draw_rect(strip_rect, Color(0.56, 0.88, 1.0, 0.72), true)
				draw_circle(rect.get_center(), cell_size * 0.12, Color(0.78, 0.95, 1.0, 0.85))
			if tile_type == TILE_CABLE:
				var cable_floor_color: Color = tile_colors.get(TILE_FLOOR, Color(0.16, 0.16, 0.18))
				draw_rect(rect, cable_floor_color, true)
				var cable_strip_size: Vector2 = Vector2(cell_size * 0.46, cell_size * 0.1)
				var cable_strip_rect: Rect2 = Rect2(rect.get_center() - cable_strip_size * 0.5, cable_strip_size)
				draw_rect(cable_strip_rect, Color(0.22, 0.88, 0.72, 0.92), true)
				draw_circle(rect.get_center(), cell_size * 0.09, Color(0.38, 0.97, 0.84, 0.96))
			draw_rect(rect, Color(0.35, 0.35, 0.38), false, 2.0)

			if grid_position == fan_platform_marker_position:
				draw_fan_platform_marker(rect)
			if tile_type == TILE_HIDDEN_ROUTE_NODE:
				if is_hidden_route_node_discovered(grid_position):
					var discovered_marker_radius: float = cell_size * 0.15
					draw_circle(rect.get_center(), discovered_marker_radius, Color(0.45, 0.95, 1.0))
				elif debug_draw_undiscovered_hidden_nodes:
					var marker_size: float = cell_size * 0.14
					var marker_rect: Rect2 = Rect2(rect.get_center() - Vector2(marker_size * 0.5, marker_size * 0.5), Vector2(marker_size, marker_size))
					draw_rect(marker_rect, Color(0.24, 0.08, 0.32, 0.95), false, 2.0)
			
			if fog_enabled:
				draw_fog_for_cell(grid_position, rect)
			if world_overlay_markers.has(grid_position) and is_cell_visible(grid_position):
				_draw_world_overlay_marker(rect, String(world_overlay_markers[grid_position]))

func _draw_world_overlay_marker(rect: Rect2, marker: String) -> void:
	if marker.is_empty():
		return
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return
	var font_size: int = 14
	var text_size: Vector2 = font.get_string_size(marker, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var pos: Vector2 = rect.get_center() - text_size * 0.5 + Vector2(0, text_size.y * 0.35)
	draw_string(font, pos, marker, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 0.95, 0.4))

func set_world_overlay_markers(markers: Dictionary) -> void:
	world_overlay_markers = markers.duplicate()
	request_visual_refresh()
				
func draw_fog_for_cell(grid_position: Vector2i, rect: Rect2) -> void:
	if is_cell_visible(grid_position):
		return
	
	if is_explored(grid_position):
		draw_rect(rect, Color(0.0, 0.0, 0.0, 0.55), true)
	else:
		draw_rect(rect, Color(0.02, 0.02, 0.025, 1.0), true)
		
func get_map_width() -> int:
	if map_data.is_empty():
		return 0
	
	return map_data[0].size()

func get_map_height() -> int:
	return map_data.size()

func get_width() -> int:
	return get_map_width()

func get_height() -> int:
	return get_map_height()

func is_in_bounds(grid_position: Vector2i) -> bool:
	return (
		grid_position.x >= 0
		and grid_position.y >= 0
		and grid_position.x < get_map_width()
		and grid_position.y < get_map_height()
	)

func get_tile(grid_position: Vector2i) -> int:
	if not is_in_bounds(grid_position):
		return TILE_WALL
	
	return map_data[grid_position.y][grid_position.x]

func _get_floor_state_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]

func make_floor_visual_state(family: String, wear: String = FLOOR_WEAR_NONE, base_variant: int = -1, overlay_variant: int = -1, mirror_h: bool = false, mirror_v: bool = false) -> Dictionary:
	return {
		"family": normalize_floor_family(family),
		"wear": normalize_floor_wear(wear),
		"base_variant": base_variant,
		"overlay_variant": overlay_variant,
		"mirror_h": mirror_h,
		"mirror_v": mirror_v,
	}

func normalize_floor_family(family: String) -> String:
	var normalized_family: String = family.strip_edges().to_lower()
	if normalized_family == FLOOR_FAMILY_GRATE:
		return FLOOR_FAMILY_GRATE
	if normalized_family == FLOOR_FAMILY_CONCRETE:
		return FLOOR_FAMILY_CONCRETE
	return FLOOR_FAMILY_METAL

func normalize_floor_wear(wear: String) -> String:
	var normalized_wear: String = wear.strip_edges().to_lower()
	if normalized_wear == FLOOR_WEAR_LIGHT:
		return FLOOR_WEAR_LIGHT
	if normalized_wear == FLOOR_WEAR_HEAVY:
		return FLOOR_WEAR_HEAVY
	return FLOOR_WEAR_NONE

func get_default_floor_visual_state(cell: Vector2i = Vector2i(-1, -1)) -> Dictionary:
	var base_variant: int = -1
	if is_in_bounds(cell):
		base_variant = ((cell.x * 3 + cell.y * 5) % 6) + 1
	return make_floor_visual_state(FLOOR_FAMILY_METAL, FLOOR_WEAR_NONE, base_variant)

func set_floor_visual_state(cell: Vector2i, state: Dictionary) -> void:
	if not is_in_bounds(cell):
		push_error("GridManager: cannot set floor state outside map bounds: " + str(cell))
		return
	floor_visual_states[_get_floor_state_key(cell)] = make_floor_visual_state(
		String(state.get("family", FLOOR_FAMILY_METAL)),
		String(state.get("wear", FLOOR_WEAR_NONE)),
		int(state.get("base_variant", -1)),
		int(state.get("overlay_variant", -1)),
		bool(state.get("mirror_h", false)),
		bool(state.get("mirror_v", false))
	)
	request_visual_refresh()

func clear_floor_visual_state(cell: Vector2i) -> void:
	floor_visual_states.erase(_get_floor_state_key(cell))
	request_visual_refresh()

func get_floor_visual_state(cell: Vector2i) -> Dictionary:
	if not is_in_bounds(cell):
		return make_floor_visual_state(FLOOR_FAMILY_METAL)
	var key: String = _get_floor_state_key(cell)
	if floor_visual_states.has(key):
		return Dictionary(floor_visual_states.get(key, {}))
	return get_default_floor_visual_state(cell)

func get_floor_family_for_cell(cell: Vector2i) -> String:
	return String(get_floor_visual_state(cell).get("family", FLOOR_FAMILY_METAL))

func get_floor_wear_for_cell(cell: Vector2i) -> String:
	return String(get_floor_visual_state(cell).get("wear", FLOOR_WEAR_NONE))

func is_wheeled_gear_module(gear: BipobModule) -> bool:
	if gear == null:
		return false
	var identifiers: Array = [gear.id, gear.module_id, gear.display_name, gear.get_display_name()]
	for identifier in identifiers:
		if String(identifier).to_lower().contains("wheel"):
			return true
	return false

func get_floor_movement_modifier_for_gear(cell: Vector2i, gear: BipobModule) -> int:
	if get_floor_wear_for_cell(cell) != FLOOR_WEAR_HEAVY:
		return 0
	var family: String = get_floor_family_for_cell(cell)
	if family != FLOOR_FAMILY_METAL and family != FLOOR_FAMILY_CONCRETE:
		return 0
	if not is_wheeled_gear_module(gear):
		return 0
	return FLOOR_HEAVY_DAMAGE_WHEELED_MOVE_MODIFIER

func is_walkable(grid_position: Vector2i) -> bool:
	var tile_type := get_tile(grid_position)
	
	if tile_type == TILE_WALL:
		return false
	
	if tile_type == TILE_DOOR:
		return false
	
	if tile_type == TILE_DIGITAL_DOOR:
		return false

	if tile_type == TILE_HOT_NODE:
		return false

	if tile_type == TILE_AIRFLOW_TERMINAL:
		return false

	if tile_type == TILE_FAN_PLATFORM:
		return false

	if tile_type == TILE_PLATFORM_CONTROL:
		return false

	if tile_type == TILE_PLATFORM_CONTROL_LEFT:
		return false

	if tile_type == TILE_PLATFORM_CONTROL_RIGHT:
		return false

	if tile_type == TILE_FAN_CONTROL:
		return false

	if tile_type == TILE_FAN_SPEED_UP_CONTROL:
		return false

	if tile_type == TILE_FAN_SPEED_DOWN_CONTROL:
		return false
	if tile_type == TILE_CABLE_REEL:
		return false
	if tile_type == TILE_SOCKET:
		return false
	if tile_type == TILE_POWERED_GATE:
		return false

	return true

func grid_to_world(grid_position: Vector2i) -> Vector2:
	return Vector2(
		grid_position.x * cell_size + cell_size / 2.0,
		grid_position.y * cell_size + cell_size / 2.0
	)

func world_to_grid(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_position.x / cell_size),
		floori(world_position.y / cell_size)
	)
func set_tile(grid_position: Vector2i, tile_type: int) -> void:
	if not is_in_bounds(grid_position):
		push_error("GridManager: cannot set tile outside map bounds: " + str(grid_position))
		return
	if is_boundary_cell(grid_position):
		tile_type = TILE_WALL
	
	map_data[grid_position.y][grid_position.x] = tile_type
	request_visual_refresh()

func is_boundary_cell(cell: Vector2i) -> bool:
	if not is_in_bounds(cell):
		return false
	var width: int = get_map_width()
	var height: int = get_map_height()
	return cell.x == 0 or cell.y == 0 or cell.x == width - 1 or cell.y == height - 1

func build_constructor_map(width: int, height: int) -> Dictionary:
	var safe_width: int = maxi(6, width)
	var safe_height: int = maxi(6, height)
	map_data.clear()
	for y in range(safe_height):
		var row: Array = []
		for x in range(safe_width):
			if x == 0 or y == 0 or x == safe_width - 1 or y == safe_height - 1:
				row.append(TILE_WALL)
			else:
				row.append(TILE_FLOOR)
		map_data.append(row)
	reset_hidden_discoveries()
	setup_fog_arrays()
	request_visual_refresh()
	queue_redraw()
	return {"ok": true, "message": "Constructor map created.", "width": safe_width, "height": safe_height}

func enforce_boundary_walls() -> void:
	for y in range(get_map_height()):
		for x in range(get_map_width()):
			var cell: Vector2i = Vector2i(x, y)
			if not is_boundary_cell(cell):
				continue
			map_data[y][x] = TILE_WALL
	request_visual_refresh()


func set_fan_platform_marker(marker_position: Vector2i, direction_vector: Vector2i) -> void:
	fan_platform_marker_position = marker_position
	fan_platform_marker_direction = direction_vector
	request_visual_refresh()

func clear_fan_platform_marker() -> void:
	fan_platform_marker_position = Vector2i(-1, -1)
	fan_platform_marker_direction = Vector2i.RIGHT
	request_visual_refresh()

func draw_fan_platform_marker(rect: Rect2) -> void:
	var direction := Vector2(fan_platform_marker_direction.x, fan_platform_marker_direction.y)
	if direction.length_squared() <= 0.0:
		direction = Vector2.RIGHT
	direction = direction.normalized()
	var perpendicular := Vector2(-direction.y, direction.x)
	var center := rect.get_center()
	var tip := center + direction * cell_size * 0.28
	var base := center - direction * cell_size * 0.08
	var left := base + perpendicular * cell_size * 0.16
	var right := base - perpendicular * cell_size * 0.16
	draw_colored_polygon(PackedVector2Array([tip, left, right]), Color(0.97, 0.97, 1.0, 0.96))
	draw_line(base, tip, Color(0.18, 0.28, 0.45, 0.9), 2.0)

func setup_fog_arrays() -> void:
	visible_cells.clear()
	explored_cells.clear()
	
	for y in range(get_map_height()):
		var visible_row: Array = []
		var explored_row: Array = []
		
		for x in range(get_map_width()):
			visible_row.append(false)
			explored_row.append(false)
		
		visible_cells.append(visible_row)
		explored_cells.append(explored_row)

func clear_visible_cells() -> void:
	for y in range(get_map_height()):
		for x in range(get_map_width()):
			visible_cells[y][x] = false

func reveal_cell(grid_position: Vector2i) -> void:
	if not is_in_bounds(grid_position):
		return
	
	visible_cells[grid_position.y][grid_position.x] = true
	explored_cells[grid_position.y][grid_position.x] = true

func reveal_current_cell_only(origin_position: Vector2i) -> void:
	clear_visible_cells()
	reveal_cell(origin_position)
	request_visual_refresh()

func reveal_around(center_position: Vector2i) -> void:
	clear_visible_cells()
	
	for y_offset in range(-reveal_radius, reveal_radius + 1):
		for x_offset in range(-reveal_radius, reveal_radius + 1):
			var target_position := center_position + Vector2i(x_offset, y_offset)
			reveal_cell(target_position)
	
	request_visual_refresh()

func is_vision_blocking_tile(tile_type: int) -> bool:
	return tile_type == TILE_WALL

func has_line_of_sight(origin_position: Vector2i, target_position: Vector2i) -> bool:
	if origin_position == target_position:
		return true

	var delta := target_position - origin_position
	var steps := maxi(abs(delta.x), abs(delta.y))
	if steps <= 0:
		return true

	var step_vector := Vector2(float(delta.x) / float(steps), float(delta.y) / float(steps))

	for step in range(1, steps + 1):
		var sample_position := Vector2(origin_position) + step_vector * step
		var check_position := Vector2i(roundi(sample_position.x), roundi(sample_position.y))

		if not is_in_bounds(check_position):
			return false

		if check_position == target_position:
			return true

		if is_vision_blocking_tile(get_tile(check_position)):
			return false

	return false

func reveal_visible_target(origin_position: Vector2i, target_position: Vector2i) -> void:
	if not is_in_bounds(target_position):
		return

	if has_line_of_sight(origin_position, target_position):
		reveal_cell(target_position)

func reveal_by_vision(origin_position: Vector2i, direction_vector: Vector2i, vision_range: int, side_width: int = 0) -> void:
	clear_visible_cells()
	reveal_cell(origin_position)

	var side_vector := Vector2i(-direction_vector.y, direction_vector.x)
	for distance in range(1, vision_range + 1):
		var center_position := origin_position + direction_vector * distance
		reveal_visible_target(origin_position, center_position)

		for offset in range(1, side_width + 1):
			reveal_visible_target(origin_position, center_position + side_vector * offset)
			reveal_visible_target(origin_position, center_position - side_vector * offset)

	request_visual_refresh()

func get_visible_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(get_map_height()):
		for x in range(get_map_width()):
			if visible_cells[y][x]:
				cells.append(Vector2i(x, y))
	return cells

func get_position_key(cell_position_arg: Vector2i) -> String:
	return str(cell_position_arg.x) + "," + str(cell_position_arg.y)

func is_hidden_route_node_discovered(cell_position_arg: Vector2i) -> bool:
	return discovered_hidden_route_nodes.has(get_position_key(cell_position_arg))

func discover_hidden_route_node(cell_position_arg: Vector2i) -> void:
	if get_tile(cell_position_arg) != TILE_HIDDEN_ROUTE_NODE:
		return
	discovered_hidden_route_nodes[get_position_key(cell_position_arg)] = true
	request_visual_refresh()

func reset_hidden_discoveries() -> void:
	discovered_hidden_route_nodes.clear()
	request_visual_refresh()

func place_debug_hidden_route_node(cell_position_arg: Vector2i) -> void:
	if not is_in_bounds(cell_position_arg):
		return
	set_tile(cell_position_arg, TILE_HIDDEN_ROUTE_NODE)
	discovered_hidden_route_nodes.erase(get_position_key(cell_position_arg))
	request_visual_refresh()

func request_visual_refresh() -> void:
	queue_redraw()
	if room_visual_renderer != null:
		room_visual_renderer.request_rebuild()
	
func is_cell_visible(grid_position: Vector2i) -> bool:
	if not is_in_bounds(grid_position):
		return false
	
	return visible_cells[grid_position.y][grid_position.x]

func is_explored(grid_position: Vector2i) -> bool:
	if not is_in_bounds(grid_position):
		return false
	
	return explored_cells[grid_position.y][grid_position.x]	
