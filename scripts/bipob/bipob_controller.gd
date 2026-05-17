extends Node2D
class_name BipobController

signal status_changed
signal hint_requested(message: String)
signal mission_completed
signal returned_to_box

enum Direction {
	NORTH,
	EAST,
	SOUTH,
	WEST
}

const EXTERNAL_SIDE_TOP := "top"
const EXTERNAL_SIDE_BOTTOM := "bottom"
const EXTERNAL_SIDE_LEFT := "left"
const EXTERNAL_SIDE_RIGHT := "right"
const EXTERNAL_SIDE_FRONT := "front"
const EXTERNAL_SIDE_BACK := "back"

const EXTERNAL_SIDE_ORDER := [
	EXTERNAL_SIDE_TOP,
	EXTERNAL_SIDE_FRONT,
	EXTERNAL_SIDE_LEFT,
	EXTERNAL_SIDE_RIGHT,
	EXTERNAL_SIDE_BACK,
	EXTERNAL_SIDE_BOTTOM
]

@export var start_grid_position := Vector2i(1, 1)

@export var max_energy: int = 50
@export var vision_range: int = 3
@export var actions_per_turn: int = 5
@export var debug_install_wheels: bool = true
@export var debug_install_manipulator: bool = true
@export var debug_install_interface: bool = true
@export var debug_install_visor: bool = true

@export var debug_add_mission4_modules_to_box: bool = false
@export var debug_place_mission4_field_modules: bool = false
@export var debug_place_hidden_route_node: bool = false
@export var debug_hidden_route_node_position: Vector2i = Vector2i(3, 1)
@export var debug_show_hidden_route_node_logs: bool = false

# MVP module model: modules can grant small passive bonuses and command flags.
# No inventory/equipment UI yet; this only stores and applies data programmatically.
var base_max_energy: int = 0
var base_vision_range: int = 0
var base_actions_per_turn: int = 0

var grid_position := Vector2i.ZERO
var direction: Direction = Direction.NORTH

var energy: int = 0
var actions_left: int = 0
var mission_finished: bool = false
var sector_completed: bool = false
var current_mission_index: int = 1
var max_mission_index: int = 9
var mission4_hidden_route_node_discovered: bool = false
var has_key: bool = false
var has_info_key: bool = false
var installed_modules: Array[BipobModule] = []
var box_storage: Array[BipobModule] = []
var external_modules_by_slot: Dictionary = {}
var found_module: BipobModule = null
var held_module: BipobModule = null
var stored_physical_module: BipobModule = null
var field_modules_by_position: Dictionary = {}
var physical_carry_capacity: int = 2
var digital_storage: Dictionary = {}
var digital_storage_capacity: int = 2
const DIGITAL_RECORD_ROUTE_DATA := "route_data"
const DIGITAL_RECORD_INFO_KEY := "info_key"
var last_diagnostic_result: DiagnosticResult = null
var mission_start_energy: int = 0
var mission_start_actions_left: int = 0
var mission_start_has_key: bool = false
var mission_start_has_info_key: bool = false
var mission_start_held_module: BipobModule = null
var mission_start_stored_physical_module: BipobModule = null
var missing_visor_hint_shown: bool = false
var active_hidden_route_node_position: Vector2i = Vector2i(-1, -1)
var mission8_fan_direction: Direction = Direction.EAST
var mission8_fan_speed: int = 0
var mission8_terminal_cooled: bool = false
var mission8_terminal_hacked: bool = false
var mission8_fan_platform_position: Vector2i = Vector2i(-1, -1)
var mission8_platform_control_position: Vector2i = Vector2i(-1, -1)
var mission8_platform_left_control_position: Vector2i = Vector2i(-1, -1)
var mission8_platform_right_control_position: Vector2i = Vector2i(-1, -1)
var mission8_fan_control_position: Vector2i = Vector2i(-1, -1)
var mission8_fan_speed_up_control_position: Vector2i = Vector2i(-1, -1)
var mission8_fan_speed_down_control_position: Vector2i = Vector2i(-1, -1)
var mission8_terminal_position: Vector2i = Vector2i(-1, -1)
var mission8_door_position: Vector2i = Vector2i(-1, -1)
var mission8_airflow_cells: Array[Vector2i] = []
var mission7_is_dragging_cable: bool = false
var mission7_cable_connected: bool = false
var mission7_cable_reel_position: Vector2i = Vector2i(-1, -1)
var mission7_socket_position: Vector2i = Vector2i(-1, -1)
var mission7_powered_gate_position: Vector2i = Vector2i(-1, -1)
var mission7_cable_path: Array[Vector2i] = []
var mission7_cable_max_length: int = 12

@onready var grid_manager: GridManager = get_node("../Field")
@onready var mission_label: Label = get_node("../UI/MissionLabel")
@onready var body: Polygon2D = $Body

func install_module(module: BipobModule) -> void:
	# MVP behavior: install immediately applies passive bonuses.
	if module == null:
		return

	# Keep module state consistent across storage and installed lists.
	var storage_index := box_storage.find(module)
	if storage_index != -1:
		box_storage.remove_at(storage_index)

	if installed_modules.has(module):
		return

	installed_modules.append(module)
	recalculate_module_stats()
	status_changed.emit()

func has_command(command_id: String) -> bool:
	for module in installed_modules:
		if module == null:
			continue
		if command_id in module.granted_commands:
			return true

	return false

func get_installed_module_by_id(module_id: String) -> BipobModule:
	for module in installed_modules:
		if module == null:
			continue
		if module.id == module_id:
			return module
	return null

func has_module_id(module_id: String) -> bool:
	return get_installed_module_by_id(module_id) != null

func has_module_id_in_box(module_id: String) -> bool:
	for module in box_storage:
		if module == null:
			continue
		if module.id == module_id:
			return true
	return false

func has_module_id_in_physical_carry(module_id: String) -> bool:
	if held_module != null and held_module.id == module_id:
		return true
	if stored_physical_module != null and stored_physical_module.id == module_id:
		return true
	return false

func has_module_id_anywhere(module_id: String) -> bool:
	if has_module_id(module_id) or has_module_id_in_box(module_id) or has_module_id_in_physical_carry(module_id):
		return true

	for module_position in field_modules_by_position.keys():
		var field_module_variant: Variant = field_modules_by_position[module_position]
		if field_module_variant == null:
			continue
		var field_module: BipobModule = field_module_variant
		if field_module.id == module_id:
			return true

	return false

func get_effective_visor_level() -> int:
	if has_module_id("visor_v2"):
		return 2
	if has_module_id("visor_v1"):
		return 1
	return 0

func get_effective_gpu_level() -> int:
	if has_module_id("gpu_v1"):
		return 1
	return 0

func get_effective_vision_range() -> int:
	var effective_range: int = vision_range
	if get_effective_gpu_level() >= 1:
		effective_range += 1
	return maxi(effective_range, 0)

func get_effective_vision_side_width() -> int:
	match get_effective_visor_level():
		2:
			return 1
		1:
			return 0
		_:
			return 0

func can_detect_hidden_nodes() -> bool:
	return get_effective_visor_level() >= 2 and get_effective_gpu_level() >= 1

func get_missing_critical_modules() -> Array[String]:
	var critical_modules := [
		{"id": "wheels_v1", "display_name": "Wheels V1"},
		{"id": "manipulator_v1", "display_name": "Manipulator V1"},
		{"id": "interface_v1", "display_name": "Interface V1"},
		{"id": "visor_v1", "display_name": "Visor V1"},
	]
	var missing_modules: Array[String] = []
	for critical_module in critical_modules:
		var required_module_id := String(critical_module.get("id", ""))
		if has_module_id(required_module_id):
			continue
		missing_modules.append(String(critical_module.get("display_name", required_module_id)))
	return missing_modules

func get_pre_mission_warnings() -> Array[String]:
	var warnings: Array[String] = []
	var missing_modules := get_missing_critical_modules()
	if not missing_modules.is_empty():
		warnings.append("Missing critical modules: %s" % ", ".join(missing_modules))

	if energy <= 0:
		warnings.append("Battery depleted. Charge before starting mission.")
	else:
		if energy < 5:
			warnings.append("Battery critically low: %d / %d" % [energy, max_energy])
		if energy < max_energy:
			warnings.append("Battery is not fully charged: %d / %d" % [energy, max_energy])

	return warnings

func can_start_mission_from_box() -> bool:
	return energy > 0

func get_pre_mission_warning_text() -> String:
	var warnings := get_pre_mission_warnings()
	if warnings.is_empty():
		return ""

	return "Warnings before mission:\n- %s" % "\n- ".join(warnings)

func recalculate_module_stats() -> void:
	# MVP module model: aggregate passive stats from installed modules.
	var energy_bonus_total := 0
	var actions_bonus_total := 0
	var vision_bonus_total := 0

	for module in installed_modules:
		if module == null:
			continue
		energy_bonus_total += module.energy_bonus
		actions_bonus_total += module.actions_bonus
		vision_bonus_total += module.vision_bonus

	max_energy = base_max_energy + energy_bonus_total
	actions_per_turn = base_actions_per_turn + actions_bonus_total
	vision_range = base_vision_range + vision_bonus_total

	energy = clampi(energy, 0, max_energy)
	actions_left = clampi(actions_left, 0, actions_per_turn)

func _ready() -> void:
	base_max_energy = max_energy
	base_vision_range = vision_range
	base_actions_per_turn = actions_per_turn
	create_default_modules()
	if debug_add_mission4_modules_to_box:
		add_debug_mission4_modules_to_box()
	recalculate_module_stats()

	energy = max_energy
	actions_left = actions_per_turn
	
	if mission_label != null:
		mission_label.text = ""
	
	setup_body()
	
	grid_position = start_grid_position
	update_rotation()
	if debug_place_hidden_route_node:
		place_debug_hidden_route_node()
	update_world_position()
	hint_requested.emit(get_current_mission_goal_hint())
	print_status()
	status_changed.emit()

func get_mission_name(mission_index: int) -> String:
	match mission_index:
		1:
			return "Mission 1 — First Key"
		2:
			return "Mission 2 — Silent Terminal"
		3:
			return "Mission 3 — Info-Key"
		4:
			return "Mission 4 — Blind Sector"
		5:
			return "Mission 5 — Route Gate"
		6:
			return "Mission 6 — Hot Node"
		7:
			return "Mission 7 — Cable Route"
		8:
			return "Mission 8 — Airflow Terminal"
		9:
			return "Mission 9 — Terrain Passage"
		_:
			return "Unknown Mission"

func get_mission_goal_hint(mission_index: int) -> String:
	match mission_index:
		1:
			return "Mission 1: pick up the physical key with Interact, open the door, then reach the exit."
		2:
			return "Mission 2: face the terminal, use Scan Device, then use Hack Device."
		3:
			return "Mission 3: Scan and Hack the terminal to get the Info-Key, then Scan and Hack the digital door."
		4:
			return get_mission4_context_hint()
		5:
			return "Mission 5: use Route Data to unlock the Route Gate and reach the exit."
		6:
			return "Mission 6: scan the hot node, manage the risk, then hack it to open the path."
		7:
			return "Mission 7: take the cable end from the reel, drag it to the socket, then reach the exit."
		8:
			return "Mission 8: cool the terminal with directed airflow, then hack it and reach the exit."
		9:
			return get_mission9_context_hint()
		_:
			return "No mission goal available."

func get_mission4_context_hint() -> String:
	var has_visor_anywhere := has_module_id_anywhere("visor_v2")
	var has_visor_installed := has_module_id("visor_v2")
	var has_gpu_anywhere := has_module_id_anywhere("gpu_v1")
	var has_gpu_installed := has_module_id("gpu_v1")

	if mission4_hidden_route_node_discovered:
		return "Hidden route-node found. Route Data stored. Reach the exit."
	if has_visor_installed and has_gpu_installed:
		return "Vision system ready. Find the hidden route-node."
	if has_visor_installed and not has_gpu_anywhere:
		return "Visor V2 widens vision, but hidden route data needs processing. Search for GPU V1."
	if has_visor_installed and has_gpu_anywhere and not has_gpu_installed:
		return "GPU V1 recovered. Return to the box and install it."
	if has_visor_anywhere and not has_visor_installed:
		return "Visor V2 recovered. Return to the box and install it."
	return "Mission 4: base vision is too narrow. Search the blind sector for a wider visor."


func get_mission9_context_hint() -> String:
	if has_module_id("legs_v1"):
		return "Legs V1 installed. Cross the stepped passage."
	if has_module_id_anywhere("legs_v1"):
		return "Legs V1 recovered. Return to the box and install it."
	return "Mission 9: wheels work on flat floor. Stepped terrain requires Legs V1."

func has_wheels() -> bool:
	return has_module_id("wheels_v1")

func has_legs() -> bool:
	return has_module_id("legs_v1")

func has_tracks() -> bool:
	return has_module_id("tracks_v1")

func can_cross_stepped_floor() -> bool:
	return has_legs() or has_tracks()
func get_current_mission_goal_hint() -> String:
	return get_mission_goal_hint(current_mission_index)

func start_mission(mission_index: int, save_snapshot: bool = true) -> void:
	# Box preparation flow: mission start resets turn actions, but does not spend resources.
	current_mission_index = clampi(mission_index, 1, max_mission_index)
	mission_finished = false
	actions_left = actions_per_turn
	has_key = false
	has_info_key = false
	last_diagnostic_result = null
	mission4_hidden_route_node_discovered = false
	held_module = null
	stored_physical_module = null
	field_modules_by_position.clear()
	mission7_is_dragging_cable = false
	mission7_cable_connected = false
	mission7_cable_reel_position = Vector2i(-1, -1)
	mission7_socket_position = Vector2i(-1, -1)
	mission7_powered_gate_position = Vector2i(-1, -1)
	mission7_cable_path.clear()
	if grid_manager != null:
		grid_manager.reset_mission_layout(current_mission_index)
		if current_mission_index == 4:
			setup_mission4_field_modules()
		elif debug_place_mission4_field_modules:
			place_debug_mission4_field_modules()
		if current_mission_index == 8:
			setup_mission8()
		elif current_mission_index == 7:
			setup_mission7()
		elif current_mission_index == 9:
			setup_mission9()
		elif grid_manager.has_method("clear_fan_platform_marker"):
			grid_manager.clear_fan_platform_marker()
		grid_manager.reset_fog_of_war()
		if current_mission_index != 4 and debug_place_hidden_route_node:
			place_debug_hidden_route_node()
	grid_position = start_grid_position
	direction = Direction.NORTH
	update_rotation()
	update_world_position()

	if save_snapshot:
		mission_start_energy = energy
		mission_start_actions_left = actions_left
		mission_start_has_key = has_key
		mission_start_has_info_key = has_info_key
		mission_start_held_module = held_module
		mission_start_stored_physical_module = stored_physical_module

	if mission_label != null:
		mission_label.text = ""

	status_changed.emit()
	hint_requested.emit(get_current_mission_goal_hint())

func find_valid_debug_hidden_route_node_position() -> Vector2i:
	var preferred_positions: Array[Vector2i] = [
		debug_hidden_route_node_position,
		Vector2i(3, 1),
		Vector2i(2, 1),
		Vector2i(3, 2),
		Vector2i(4, 1)
	]

	for position in preferred_positions:
		if grid_manager == null:
			return Vector2i(-1, -1)
		if grid_manager.is_in_bounds(position) and grid_manager.get_tile(position) == GridManager.TILE_FLOOR:
			return position

	return Vector2i(-1, -1)

func place_debug_hidden_route_node() -> void:
	if not debug_place_hidden_route_node:
		return
	if grid_manager == null:
		return

	var position := find_valid_debug_hidden_route_node_position()
	if position == Vector2i(-1, -1):
		hint_requested.emit("Debug hidden route-node was not placed: no valid floor tile.")
		return

	active_hidden_route_node_position = position
	grid_manager.set_tile(position, GridManager.TILE_HIDDEN_ROUTE_NODE)

	if grid_manager.has_method("reset_hidden_discoveries"):
		grid_manager.reset_hidden_discoveries()

	if debug_show_hidden_route_node_logs:
		print("Debug hidden route-node placed at: ", position)
		hint_requested.emit("Debug hidden route-node placed at: " + str(position))

func restart_current_mission() -> void:
	if sector_completed and current_mission_index == max_mission_index:
		sector_completed = false

	# Restart flow is state reset, not a field action spend.
	start_mission(current_mission_index, false)
	mission_finished = false
	energy = mission_start_energy
	actions_left = mission_start_actions_left
	has_key = mission_start_has_key
	has_info_key = mission_start_has_info_key
	held_module = mission_start_held_module
	stored_physical_module = mission_start_stored_physical_module
	last_diagnostic_result = null
	grid_position = start_grid_position
	direction = Direction.NORTH
	update_rotation()
	update_world_position()
	status_changed.emit()
	hint_requested.emit(get_current_mission_goal_hint())

func return_to_box() -> void:
	if mission_finished:
		returned_to_box.emit()
		return

	mission_finished = true
	last_diagnostic_result = null
	if current_mission_index == 7 and mission7_is_dragging_cable:
		release_mission7_cable_end()

	if held_module != null:
		add_module_to_box_storage(held_module)
		held_module = null

	if stored_physical_module != null:
		add_module_to_box_storage(stored_physical_module)
		stored_physical_module = null

	if current_mission_index == 4 and (has_module_id_anywhere("visor_v2") or has_module_id_anywhere("gpu_v1")):
		hint_requested.emit(get_mission4_context_hint())
	elif current_mission_index == 9 and has_module_id_anywhere("legs_v1"):
		hint_requested.emit(get_mission9_context_hint())
	else:
		hint_requested.emit("Returned to box. Mission attempt aborted.")
	status_changed.emit()
	returned_to_box.emit()

func store_digital_record(record_id: String, display_name: String, description: String = "") -> void:
	if record_id.is_empty():
		return

	if digital_storage_capacity <= 0:
		digital_storage.clear()
		status_changed.emit()
		return

	var record := {
		"id": record_id,
		"display_name": display_name,
		"description": description,
	}

	if digital_storage.has(record_id):
		digital_storage[record_id] = record
		hint_requested.emit("Digital record updated: " + get_digital_record_display_name(record_id))
		status_changed.emit()
		return

	if digital_storage.size() < digital_storage_capacity:
		digital_storage[record_id] = record
		hint_requested.emit("Digital record stored: " + display_name)
		status_changed.emit()
		return

	if digital_storage.size() >= digital_storage_capacity:
		var existing_record_id := String(digital_storage.keys()[0])
		var old_display_name := get_digital_record_display_name(existing_record_id)
		digital_storage.erase(existing_record_id)
		digital_storage[record_id] = record
		hint_requested.emit("Digital storage overwritten: " + old_display_name + " -> " + display_name)
		status_changed.emit()
		return

func get_first_digital_record_display_name() -> String:
	if digital_storage.is_empty():
		return "empty"

	var first_record_id := String(digital_storage.keys()[0])
	return get_digital_record_display_name(first_record_id)

func has_digital_record(record_id: String) -> bool:
	return digital_storage.has(record_id)

func use_digital_record(record_id: String) -> bool:
	return has_digital_record(record_id)

func get_digital_record_display_name(record_id: String) -> String:
	if not digital_storage.has(record_id):
		return record_id

	var record_data: Variant = digital_storage.get(record_id, {})
	if typeof(record_data) != TYPE_DICTIONARY:
		return record_id

	var record_dict: Dictionary = record_data
	if record_dict.has("display_name"):
		var resolved_display_name := String(record_dict.get("display_name", ""))
		if not resolved_display_name.is_empty():
			return resolved_display_name

	return record_id

func get_digital_storage_text() -> String:
	if digital_storage.is_empty():
		return "Digital storage: empty"

	var lines := ["Digital storage:"]
	for record_id in digital_storage.keys():
		lines.append("- " + get_digital_record_display_name(String(record_id)))
	return "\n".join(lines)

func debug_store_route_data() -> void:
	store_digital_record(
		DIGITAL_RECORD_ROUTE_DATA,
		"Route Data",
		"Temporary route record for future route mission."
	)

func start_next_mission() -> void:
	if sector_completed:
		hint_requested.emit("Sector-01 complete. All systems cleared.")
		status_changed.emit()
		return

	if current_mission_index < max_mission_index:
		start_mission(current_mission_index + 1)
		return

	sector_completed = true
	hint_requested.emit("Sector-01 complete. All systems cleared.")
	status_changed.emit()

func get_external_side_size(side_id: String) -> Vector2i:
	match side_id:
		EXTERNAL_SIDE_TOP:
			return Vector2i(3, 3)
		EXTERNAL_SIDE_BOTTOM:
			return Vector2i(3, 3)
		EXTERNAL_SIDE_LEFT:
			return Vector2i(3, 4)
		EXTERNAL_SIDE_RIGHT:
			return Vector2i(3, 4)
		EXTERNAL_SIDE_FRONT:
			return Vector2i(3, 4)
		EXTERNAL_SIDE_BACK:
			return Vector2i(3, 4)
		_:
			return Vector2i.ZERO

func get_external_slot_key(side_id: String, slot_position: Vector2i) -> String:
	return "%s:%d,%d" % [side_id, slot_position.x, slot_position.y]

func is_external_side_valid(side_id: String) -> bool:
	return side_id in EXTERNAL_SIDE_ORDER

func is_external_slot_in_bounds(side_id: String, slot_position: Vector2i) -> bool:
	if not is_external_side_valid(side_id):
		return false
	var side_size := get_external_side_size(side_id)
	return (
		slot_position.x >= 0
		and slot_position.y >= 0
		and slot_position.x < side_size.x
		and slot_position.y < side_size.y
	)

func get_external_module_at(side_id: String, slot_position: Vector2i) -> BipobModule:
	var key := get_external_slot_key(side_id, slot_position)
	if external_modules_by_slot.has(key):
		return external_modules_by_slot[key]
	return null

func is_external_slot_empty(side_id: String, slot_position: Vector2i) -> bool:
	return get_external_module_at(side_id, slot_position) == null


func get_external_module_size(module: BipobModule) -> Vector2i:
	if module == null:
		return Vector2i.ONE

	match module.id:
		"manipulator_v1":
			return Vector2i(2, 2)
		"interface_v1":
			return Vector2i(2, 2)
		"wheels_v1":
			return Vector2i(3, 2)
		"legs_v1":
			return Vector2i(3, 2)
		"tracks_v1":
			return Vector2i(3, 2)
		"visor_v1":
			return Vector2i(3, 1)
		"visor_v2":
			return Vector2i(3, 1)
		_:
			return Vector2i(1, 1)

func get_external_module_footprint_cells(module: BipobModule, origin: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var module_size: Vector2i = get_external_module_size(module)
	for y in range(module_size.y):
		for x in range(module_size.x):
			cells.append(origin + Vector2i(x, y))
	return cells

func get_external_module_safe_area_cells(module: BipobModule, origin: Vector2i) -> Array[Vector2i]:
	var safe_cells: Array[Vector2i] = []
	var module_size: Vector2i = get_external_module_size(module)
	var footprint_map: Dictionary = {}
	for footprint_cell in get_external_module_footprint_cells(module, origin):
		footprint_map[footprint_cell] = true

	for y in range(origin.y - 1, origin.y + module_size.y + 1):
		for x in range(origin.x - 1, origin.x + module_size.x + 1):
			var cell := Vector2i(x, y)
			if footprint_map.has(cell):
				continue
			if safe_cells.has(cell):
				continue
			safe_cells.append(cell)
	return safe_cells

func is_external_cell_occupied(side_id: String, cell_position: Vector2i) -> bool:
	return get_external_module_at(side_id, cell_position) != null

func can_place_external_module_at(module: BipobModule, side_id: String, origin: Vector2i) -> bool:
	return get_external_module_placement_error(module, side_id, origin).is_empty()

func get_external_module_placement_error(module: BipobModule, side_id: String, origin: Vector2i) -> String:
	if module == null:
		return "No module selected."
	if not is_external_module(module):
		return "Module cannot be installed outside: %s" % get_module_display_name(module)
	if not is_external_side_valid(side_id):
		return "Invalid external side: %s." % side_id
	if not can_place_external_module_on_side(module, side_id):
		return "Cannot install %s on %s. Allowed side: %s." % [
			get_module_display_name(module),
			get_external_side_display_name(side_id),
			get_allowed_external_sides_text(module)
		]

	for cell in get_external_module_footprint_cells(module, origin):
		if not is_external_slot_in_bounds(side_id, cell):
			return "Module footprint is outside the %s side." % get_external_side_display_name(side_id)
		if is_external_cell_occupied(side_id, cell):
			return "External slot is occupied."

	for safe_cell in get_external_module_safe_area_cells(module, origin):
		if not is_external_slot_in_bounds(side_id, safe_cell):
			continue
		if is_external_cell_occupied(side_id, safe_cell):
			return "External safe area is blocked."

	return ""

func _remove_external_module_instance_cells(side_id: String, module: BipobModule) -> void:
	if module == null:
		return
	var keys_to_remove: Array[String] = []
	for slot_key_variant in external_modules_by_slot.keys():
		var slot_key := String(slot_key_variant)
		if not slot_key.begins_with(side_id + ":"):
			continue
		var stored_module: BipobModule = external_modules_by_slot[slot_key]
		if stored_module == module:
			keys_to_remove.append(slot_key)
	for slot_key in keys_to_remove:
		external_modules_by_slot.erase(slot_key)

func is_external_module(module: BipobModule) -> bool:
	if module == null:
		return false

	if module.placement_type == "external" or module.placement_type == "any":
		return true

	var external_ids := [
		"wheels_v1",
		"legs_v1",
		"tracks_v1",
		"manipulator_v1",
		"interface_v1",
		"visor_v1",
		"visor_v2"
	]
	return module.id in external_ids

func get_allowed_external_sides_for_module(module: BipobModule) -> Array[String]:
	if module == null:
		return []

	match module.id:
		"wheels_v1":
			return [EXTERNAL_SIDE_BOTTOM]
		"legs_v1":
			return [EXTERNAL_SIDE_BOTTOM]
		"tracks_v1":
			return [EXTERNAL_SIDE_BOTTOM]
		"visor_v1":
			return [EXTERNAL_SIDE_TOP]
		"visor_v2":
			return [EXTERNAL_SIDE_TOP]
		_:
			var allowed_sides: Array[String] = []
			for external_side_id in EXTERNAL_SIDE_ORDER:
				allowed_sides.append(String(external_side_id))
			return allowed_sides

func can_place_external_module_on_side(module: BipobModule, side_id: String) -> bool:
	if module == null:
		return false
	var allowed_sides := get_allowed_external_sides_for_module(module)
	return side_id in allowed_sides

func get_external_side_display_name(side_id: String) -> String:
	return side_id.capitalize()

func get_allowed_external_sides_text(module: BipobModule) -> String:
	var allowed := get_allowed_external_sides_for_module(module)
	if allowed.is_empty():
		return "none"
	var names: Array[String] = []
	for side_id in allowed:
		names.append(get_external_side_display_name(side_id))
	return ", ".join(names)

func place_external_module(module: BipobModule, side_id: String, slot_position: Vector2i) -> bool:
	var placement_error := get_external_module_placement_error(module, side_id, slot_position)
	if not placement_error.is_empty():
		hint_requested.emit(placement_error)
		status_changed.emit()
		return false

	for cell in get_external_module_footprint_cells(module, slot_position):
		external_modules_by_slot[get_external_slot_key(side_id, cell)] = module
	hint_requested.emit("External module placed: %s (%dx%d)" % [
		get_module_display_name(module),
		get_external_module_size(module).x,
		get_external_module_size(module).y
	])
	status_changed.emit()
	return true

func place_external_module_from_box_storage(storage_index: int, side_id: String, slot_position: Vector2i) -> bool:
	if storage_index < 0 or storage_index >= box_storage.size():
		hint_requested.emit("No module in that Box slot.")
		status_changed.emit()
		return false

	var module: BipobModule = box_storage[storage_index]
	if module == null:
		box_storage.remove_at(storage_index)
		hint_requested.emit("Removed empty module from Box Storage.")
		status_changed.emit()
		return false

	var placement_error := get_external_module_placement_error(module, side_id, slot_position)
	if not placement_error.is_empty():
		hint_requested.emit(placement_error)
		status_changed.emit()
		return false

	box_storage.remove_at(storage_index)
	for cell in get_external_module_footprint_cells(module, slot_position):
		external_modules_by_slot[get_external_slot_key(side_id, cell)] = module

	hint_requested.emit("External module installed: %s (%dx%d)" % [
		get_module_display_name(module),
		get_external_module_size(module).x,
		get_external_module_size(module).y
	])
	status_changed.emit()
	return true

func remove_external_module(side_id: String, slot_position: Vector2i) -> BipobModule:
	if not is_external_slot_in_bounds(side_id, slot_position):
		hint_requested.emit("External slot is out of bounds.")
		status_changed.emit()
		return null

	var module: BipobModule = get_external_module_at(side_id, slot_position)
	if module == null:
		hint_requested.emit("External slot is empty.")
		status_changed.emit()
		return null

	_remove_external_module_instance_cells(side_id, module)
	hint_requested.emit("External module removed: " + get_module_display_name(module))
	status_changed.emit()
	return module

func remove_external_module_to_box_storage(side_id: String, slot_position: Vector2i) -> bool:
	if not is_external_slot_in_bounds(side_id, slot_position):
		hint_requested.emit("External slot is out of bounds.")
		status_changed.emit()
		return false

	var module: BipobModule = get_external_module_at(side_id, slot_position)
	if module == null:
		hint_requested.emit("External slot is empty.")
		status_changed.emit()
		return false

	_remove_external_module_instance_cells(side_id, module)
	if module != null and not box_storage.has(module):
		box_storage.append(module)

	hint_requested.emit("External module removed to Box: " + get_module_display_name(module))
	status_changed.emit()
	return true

func get_external_build_summary_text() -> String:
	if external_modules_by_slot.is_empty():
		return "External build: empty"

	var lines: Array[String] = ["External build:"]
	for side_id in EXTERNAL_SIDE_ORDER:
		var side_size := get_external_side_size(side_id)
		var seen_modules: Array[BipobModule] = []
		for y in range(side_size.y):
			for x in range(side_size.x):
				var module: BipobModule = get_external_module_at(side_id, Vector2i(x, y))
				if module == null or seen_modules.has(module):
					continue
				seen_modules.append(module)
		if not seen_modules.is_empty():
			lines.append("- %s: %d module(s)" % [side_id, seen_modules.size()])

	return "\n".join(lines)

func debug_place_first_installed_external_module() -> void:
	if installed_modules.is_empty():
		hint_requested.emit("No installed modules to place externally.")
		status_changed.emit()
		return

	for module in installed_modules:
		if is_external_module(module):
			place_external_module(module, EXTERNAL_SIDE_FRONT, Vector2i(1, 1))
			return

	hint_requested.emit("No external installed module found.")
	status_changed.emit()

func create_default_modules() -> void:
	installed_modules.clear()

	if debug_install_wheels:
		var wheels_module := BipobModule.new()
		wheels_module.id = "wheels_v1"
		wheels_module.display_name = "Wheels V1"
		wheels_module.placement_type = "external"
		wheels_module.granted_commands = [
			"move_forward",
			"move_backward",
			"turn_left",
			"turn_right",
		]
		install_module(wheels_module)

	if debug_install_manipulator:
		var manipulator_module := BipobModule.new()
		manipulator_module.id = "manipulator_v1"
		manipulator_module.display_name = "Manipulator V1"
		manipulator_module.placement_type = "external"
		manipulator_module.granted_commands = [
			"interact_key",
			"open_physical_door",
		]
		install_module(manipulator_module)

	if debug_install_interface:
		var interface_module := BipobModule.new()
		interface_module.id = "interface_v1"
		interface_module.display_name = "Interface V1"
		interface_module.placement_type = "external"
		interface_module.granted_commands = [
			"read_terminal",
			"open_digital_door",
		]
		install_module(interface_module)

	if debug_install_visor:
		var visor_module := BipobModule.new()
		visor_module.id = "visor_v1"
		visor_module.display_name = "Visor V1"
		visor_module.placement_type = "external"
		visor_module.granted_commands = [
			"vision",
		]
		install_module(visor_module)

func create_visor_v2_module() -> BipobModule:
	var module := BipobModule.new()
	module.id = "visor_v2"
	module.display_name = "Visor V2"
	module.placement_type = "external"
	module.description = "Wide-angle visor. Expands vision width."
	module.granted_commands = ["vision"]
	module.vision_bonus = 0
	return module

func create_gpu_v1_module() -> BipobModule:
	var module := BipobModule.new()
	module.id = "gpu_v1"
	module.display_name = "GPU V1"
	module.description = "Internal processing module. Increases vision range and supports hidden node detection."
	module.granted_commands = ["hidden_detection_support"]
	module.vision_bonus = 0
	return module

func create_legs_v1_module() -> BipobModule:
	var module := BipobModule.new()
	module.id = "legs_v1"
	module.display_name = "Legs V1"
	module.placement_type = "external"
	module.description = "Locomotion module. Allows crossing stepped terrain."
	module.granted_commands = [
		"move_forward",
		"move_backward",
		"turn_left",
		"turn_right",
		"cross_stepped_floor"
	]
	return module

func add_debug_mission4_modules_to_box() -> void:
	var visor_v2_module := create_visor_v2_module()
	if not has_module_id_anywhere(visor_v2_module.id):
		box_storage.append(visor_v2_module)

	var gpu_v1_module := create_gpu_v1_module()
	if not has_module_id_anywhere(gpu_v1_module.id):
		box_storage.append(gpu_v1_module)

	hint_requested.emit("Debug modules added to Box: Visor V2, GPU V1")
	status_changed.emit()


func get_module_display_name(module: BipobModule) -> String:
	if module == null:
		return "Unknown module"

	if not module.display_name.is_empty():
		return module.display_name

	if not module.id.is_empty():
		return module.id

	return "Unnamed module"

func add_module_to_box_storage(module: BipobModule) -> void:
	if module == null:
		return

	if installed_modules.has(module):
		return

	if box_storage.has(module):
		return

	box_storage.append(module)
	hint_requested.emit("Stored in box: " + get_module_display_name(module))
	status_changed.emit()

func install_module_from_box_storage(storage_index: int) -> bool:
	if storage_index < 0 or storage_index >= box_storage.size():
		hint_requested.emit("No module in that storage slot.")
		status_changed.emit()
		return false

	var module_to_install: BipobModule = box_storage[storage_index]
	if module_to_install == null:
		box_storage.remove_at(storage_index)
		hint_requested.emit("Removed empty module from box storage.")
		status_changed.emit()
		return false

	box_storage.remove_at(storage_index)

	if installed_modules.has(module_to_install):
		hint_requested.emit("Module already installed: " + get_module_display_name(module_to_install))
		status_changed.emit()
		return false

	install_module(module_to_install)
	hint_requested.emit("Installed from box: " + get_module_display_name(module_to_install))
	status_changed.emit()
	return true

func return_installed_module_to_box_storage(module: BipobModule) -> void:
	if module == null:
		return

	var installed_index := installed_modules.find(module)
	if installed_index == -1:
		return

	installed_modules.remove_at(installed_index)

	if not box_storage.has(module):
		box_storage.append(module)

	recalculate_module_stats()
	status_changed.emit()

func remove_last_installed_module_to_box() -> bool:
	if installed_modules.is_empty():
		hint_requested.emit("No installed modules to remove.")
		status_changed.emit()
		return false

	var module_to_remove: BipobModule = installed_modules[installed_modules.size() - 1]
	if module_to_remove == null:
		installed_modules.remove_at(installed_modules.size() - 1)
		hint_requested.emit("Removed empty module slot.")
		status_changed.emit()
		return false

	installed_modules.remove_at(installed_modules.size() - 1)

	if not box_storage.has(module_to_remove):
		box_storage.append(module_to_remove)

	recalculate_module_stats()

	hint_requested.emit("Removed module to box: " + get_module_display_name(module_to_remove))
	status_changed.emit()
	return true

func remove_installed_module_to_box_by_index(module_index: int) -> bool:
	if module_index < 0 or module_index >= installed_modules.size():
		hint_requested.emit("No installed module in that slot.")
		status_changed.emit()
		return false

	var module_to_remove: BipobModule = installed_modules[module_index]
	if module_to_remove == null:
		installed_modules.remove_at(module_index)
		hint_requested.emit("Removed empty module slot.")
		status_changed.emit()
		return false

	installed_modules.remove_at(module_index)

	if not box_storage.has(module_to_remove):
		box_storage.append(module_to_remove)

	recalculate_module_stats()

	hint_requested.emit("Removed module to box: " + get_module_display_name(module_to_remove))
	status_changed.emit()
	return true

func set_found_module(module: BipobModule) -> void:
	found_module = module
	status_changed.emit()

func create_debug_found_module() -> void:
	var module := BipobModule.new()
	module.id = "battery_v1"
	module.display_name = "Battery V1"
	module.description = "Increases max energy by 10."
	module.energy_bonus = 10
	module.granted_commands = []
	found_module = module
	hint_requested.emit("Found module: " + module.display_name)
	status_changed.emit()

func install_found_module() -> bool:
	if found_module == null:
		print("No module to install.")
		hint_requested.emit("No module to install.")
		return false

	var module_to_install := found_module
	install_module(module_to_install)
	found_module = null
	print("Installed module: ", get_module_display_name(module_to_install))
	hint_requested.emit("Installed module: " + get_module_display_name(module_to_install))
	status_changed.emit()
	return true

func install_available_module() -> bool:
	if not box_storage.is_empty():
		return install_module_from_box_storage(0)

	if found_module != null:
		return install_found_module()

	hint_requested.emit("No module to install.")
	status_changed.emit()
	return false

func require_command(command_id: String, missing_message: String) -> bool:
	if has_command(command_id):
		return true

	print("Missing command: ", command_id, " | ", missing_message)
	hint_requested.emit(missing_message)
	return false

func setup_body() -> void:
	if body == null:
		return
	
	body.polygon = PackedVector2Array([
		Vector2(0, -22),
		Vector2(18, 18),
		Vector2(0, 10),
		Vector2(-18, 18),
	])
	body.color = Color(0.1, 0.8, 0.9)

func _unhandled_input(event: InputEvent) -> void:
	if mission_finished:
		return
	
	if event.is_action_pressed("move_forward"):
		move_forward()
	elif event.is_action_pressed("move_backward"):
		move_backward()
	elif event.is_action_pressed("turn_left"):
		turn_left()
	elif event.is_action_pressed("turn_right"):
		turn_right()
	elif event.is_action_pressed("end_turn"):
		end_turn()
	elif event.is_action_pressed("interact"):
		interact()

func move_forward() -> void:
	if not require_command("move_forward", "Missing module: Wheels V1 required."):
		return
	if not can_spend_action(1, 1):
		return
	
	var target_position := grid_position + get_direction_vector(direction)
	
	if try_move_to(target_position):
		spend_action(1, 1)

func move_backward() -> void:
	if not require_command("move_backward", "Missing module: Wheels V1 required."):
		return
	if not can_spend_action(1, 1):
		return
	
	var target_position := grid_position - get_direction_vector(direction)
	
	if try_move_to(target_position):
		spend_action(1, 1)

func turn_left() -> void:
	if not require_command("turn_left", "Missing module: Wheels V1 required."):
		return
	if not can_spend_action(1, 1):
		return
	
	direction = Direction.values()[(int(direction) + 3) % 4]
	update_rotation()
	update_vision()
	spend_action(1, 1)

func turn_right() -> void:
	if not require_command("turn_right", "Missing module: Wheels V1 required."):
		return
	if not can_spend_action(1, 1):
		return
	
	direction = Direction.values()[(int(direction) + 1) % 4]
	update_rotation()
	update_vision()
	spend_action(1, 1)

func end_turn() -> void:
	actions_left = actions_per_turn
	print("End Turn. Actions restored.")
	print_status()
	status_changed.emit()

func can_spend_action(action_cost: int, energy_cost: int) -> bool:
	if actions_left < action_cost:
		print("Not enough actions. Press Space to end turn.")
		hint_requested.emit("No actions left. Press Space to end turn.")
		return false
	
	if energy < energy_cost:
		print("Not enough energy.")
		hint_requested.emit("Not enough energy. Return to the box and use Charge.")
		return false
	
	return true


func spend_action(action_cost: int, energy_cost: int) -> void:
	actions_left -= action_cost
	energy -= energy_cost
	
	print_status()
	status_changed.emit()
	
	if energy <= 0:
		print("Energy depleted. Mission failed.")

func try_move_to(target_position: Vector2i) -> bool:
	if grid_manager == null:
		push_error("BipobController: grid_manager is null")
		return false
	
	var target_tile := grid_manager.get_tile(target_position)
	if target_tile == GridManager.TILE_STEPPED_FLOOR and not can_cross_stepped_floor():
		hint_requested.emit("Stepped terrain blocks wheels. Install Legs V1 or Tracks V1.")
		status_changed.emit()
		return false

	if not grid_manager.is_walkable(target_position):
		if target_tile == GridManager.TILE_WALL:
			hint_requested.emit("Blocked by wall.")
		elif target_tile == GridManager.TILE_DOOR:
			hint_requested.emit("Door is locked. Find a key and press E while facing it.")
		elif target_tile == GridManager.TILE_DIGITAL_DOOR:
			hint_requested.emit("Digital door is locked. Use Scan Device, then Hack Device.")
		elif target_tile == GridManager.TILE_HOT_NODE:
			hint_requested.emit("Hot Node blocks the route. Scan it first.")
		elif target_tile == GridManager.TILE_AIRFLOW_TERMINAL:
			hint_requested.emit("Terminal blocks the route. Scan it first.")
		elif target_tile == GridManager.TILE_FAN_PLATFORM:
			hint_requested.emit("Fan platform blocks the path. Use controls to rotate airflow.")
		elif target_tile == GridManager.TILE_PLATFORM_CONTROL_LEFT:
			hint_requested.emit("Use Interact to rotate fan platform left.")
		elif target_tile == GridManager.TILE_PLATFORM_CONTROL_RIGHT:
			hint_requested.emit("Use Interact to rotate fan platform right.")
		elif target_tile == GridManager.TILE_PLATFORM_CONTROL:
			hint_requested.emit("Use Interact to rotate the fan platform.")
		elif target_tile == GridManager.TILE_FAN_CONTROL:
			hint_requested.emit("Use Interact to change fan speed.")
		elif target_tile == GridManager.TILE_FAN_SPEED_UP_CONTROL:
			hint_requested.emit("Use Interact to increase fan speed.")
		elif target_tile == GridManager.TILE_FAN_SPEED_DOWN_CONTROL:
			hint_requested.emit("Use Interact to decrease fan speed.")
		elif target_tile == GridManager.TILE_POWERED_GATE:
			hint_requested.emit("Powered gate is closed. Connect the cable to the socket.")
		elif target_tile == GridManager.TILE_CABLE_REEL:
			hint_requested.emit("Cable reel. Use Interact to take the cable end.")
		elif target_tile == GridManager.TILE_SOCKET:
			hint_requested.emit("Socket. Bring the cable end here and use Interact.")
		else:
			hint_requested.emit("Path is blocked.")

		print("Blocked: ", target_position)
		return false
	
	grid_position = target_position
	update_world_position()
	if current_mission_index == 7 and mission7_is_dragging_cable:
		add_current_cell_to_mission7_cable_path()
	check_mission_complete()
	return true
	
func check_mission_complete() -> void:
	var current_tile := grid_manager.get_tile(grid_position)
	
	if current_tile == GridManager.TILE_EXIT:
		if current_mission_index == 4 and not mission4_hidden_route_node_discovered:
			hint_requested.emit("Exit route is incomplete. Find the hidden route-node first.")
			status_changed.emit()
			return
		complete_mission()

func complete_mission() -> void:
	if mission_finished:
		return
	
	mission_finished = true
	var stored_module_this_mission := false
	if held_module != null:
		add_module_to_box_storage(held_module)
		held_module = null
		stored_module_this_mission = true
	if stored_physical_module != null:
		add_module_to_box_storage(stored_physical_module)
		stored_physical_module = null
		stored_module_this_mission = true
	
	if mission_label != null:
		mission_label.text = "MISSION COMPLETE"
	
	print("MISSION COMPLETE")
	print("Bipob reached the exit.")
	if current_mission_index == 1:
		hint_requested.emit("Mission 1 complete. Return to the box, then start Mission 2.")
	elif current_mission_index == 2:
		hint_requested.emit("Mission 2 complete. Return to the box, then start Mission 3.")
	elif current_mission_index == 3:
		hint_requested.emit("Mission 3 complete. Return to the box, then start Mission 4.")
	elif current_mission_index == 4:
		hint_requested.emit("Mission 4 complete. Return to the box, then start Mission 5.")
	elif current_mission_index == 5:
		hint_requested.emit("Mission 5 complete. Return to the box, then start Mission 6.")
	elif current_mission_index == 6:
		hint_requested.emit("Mission 6 complete. Return to the box, then start Mission 7.")
	elif current_mission_index == 7:
		hint_requested.emit("Mission 7 complete. Return to the box, then start Mission 8.")
	elif current_mission_index == 8:
		hint_requested.emit("Mission 8 complete. Return to the box, then start Mission 9.")
	elif current_mission_index == 9:
		hint_requested.emit("Mission 9 complete. Return to the box. Sector-01 complete. Terrain passage cleared.")
	else:
		hint_requested.emit("Mission complete. Return to the box.")
	if current_mission_index == max_mission_index:
		sector_completed = true
		last_diagnostic_result = null

	if stored_module_this_mission:
		found_module = null
	else:
		create_debug_found_module()
	status_changed.emit()
	mission_completed.emit()
			

func setup_mission9() -> void:
	if grid_manager == null:
		return

	var module_position := Vector2i(3, 1)
	if not grid_manager.is_in_bounds(module_position):
		return

	if has_module_id_anywhere("legs_v1"):
		grid_manager.set_tile(module_position, GridManager.TILE_FLOOR)
		field_modules_by_position.erase(module_position)
		return

	grid_manager.set_tile(module_position, GridManager.TILE_COMPONENT)
	set_field_module(module_position, create_legs_v1_module())
func update_world_position() -> void:
	if grid_manager == null:
		return
	
	global_position = grid_manager.global_position + grid_manager.grid_to_world(grid_position)
	update_vision()
	
func update_vision() -> void:
	if grid_manager == null:
		return

	if get_effective_visor_level() <= 0:
		if not missing_visor_hint_shown:
			hint_requested.emit("Missing module: Visor V1 required.")
			missing_visor_hint_shown = true
		grid_manager.reveal_current_cell_only(grid_position)
		return

	missing_visor_hint_shown = false
	var direction_vector := get_direction_vector(direction)
	var effective_range: int = get_effective_vision_range()
	var side_width: int = get_effective_vision_side_width()
	grid_manager.reveal_by_vision(grid_position, direction_vector, effective_range, side_width)
	if debug_show_hidden_route_node_logs:
		print("Vision update | visor: ", get_effective_visor_level(), " | gpu: ", get_effective_gpu_level(), " | can_detect_hidden_nodes: ", can_detect_hidden_nodes())
	if can_detect_hidden_nodes():
		detect_hidden_route_nodes_in_vision()

func detect_hidden_route_nodes_in_vision() -> void:
	if grid_manager == null:
		return

	var can_detect := can_detect_hidden_nodes()

	if debug_show_hidden_route_node_logs:
		print("Hidden detection check | can_detect: ", can_detect, " | visor: ", get_effective_visor_level(), " | gpu: ", get_effective_gpu_level())

	if not can_detect:
		return

	var visible_cells: Array[Vector2i] = grid_manager.get_visible_cells()

	if debug_show_hidden_route_node_logs:
		print("Visible cells count: ", visible_cells.size())
		print("Active hidden route-node position: ", active_hidden_route_node_position)

	for cell in visible_cells:
		if grid_manager.get_tile(cell) == GridManager.TILE_HIDDEN_ROUTE_NODE:
			if not grid_manager.is_hidden_route_node_discovered(cell):
				grid_manager.discover_hidden_route_node(cell)
				store_digital_record(
					DIGITAL_RECORD_ROUTE_DATA,
					"Route Data",
					"Recovered hidden route information."
				)
				if current_mission_index == 4:
					mission4_hidden_route_node_discovered = true
					hint_requested.emit("Hidden route-node found. Route Data stored. Reach the exit.")
				else:
					hint_requested.emit("Hidden route-node detected. Route Data stored.")
				status_changed.emit()
				return
	
func charge_to_full() -> void:
	# Box preparation action: refill battery without spending field actions/energy.
	energy = max_energy
	print("Bipob fully charged.")
	hint_requested.emit("Bipob fully charged.")
	status_changed.emit()
		
func update_rotation() -> void:
	match direction:
		Direction.NORTH:
			rotation_degrees = 0
		Direction.EAST:
			rotation_degrees = 90
		Direction.SOUTH:
			rotation_degrees = 180
		Direction.WEST:
			rotation_degrees = 270

func get_direction_vector(current_direction: Direction) -> Vector2i:
	match current_direction:
		Direction.NORTH:
			return Vector2i(0, -1)
		Direction.EAST:
			return Vector2i(1, 0)
		Direction.SOUTH:
			return Vector2i(0, 1)
		Direction.WEST:
			return Vector2i(-1, 0)
	
	return Vector2i.ZERO

func get_facing_device_position() -> Vector2i:
	return grid_position + get_direction_vector(direction)

func get_device_definition_for_tile(tile_type: int) -> DeviceDefinition:
	var definition := DeviceDefinition.new()

	match tile_type:
		GridManager.TILE_TERMINAL:
			definition.device_type = "terminal"
			definition.display_name = "Terminal"
			definition.required_interface = "interface_v1"
			definition.difficulty_level = 1
			definition.supported_action = "download_info_key"
			return definition
		GridManager.TILE_DIGITAL_DOOR:
			definition.device_type = "digital_door"
			definition.display_name = "Digital Door"
			definition.required_interface = "interface_v1"
			definition.difficulty_level = 1
			definition.supported_action = "open_digital_door"
			return definition
		GridManager.TILE_HOT_NODE:
			definition.device_type = "hot_node"
			definition.display_name = "Hot Node"
			definition.required_interface = "interface_v1"
			definition.difficulty_level = 2
			definition.supported_action = "stabilize_hot_node"
			return definition
		GridManager.TILE_AIRFLOW_TERMINAL:
			definition.device_type = "airflow_terminal"
			definition.display_name = "Airflow Terminal"
			definition.required_interface = "interface_v1"
			definition.difficulty_level = 2
			definition.supported_action = "unlock_airflow_terminal"
			return definition
		_:
			return null

func get_facing_device_definition() -> DeviceDefinition:
	if grid_manager == null:
		return null

	var facing_position := get_facing_device_position()
	var tile_type := grid_manager.get_tile(facing_position)
	return get_device_definition_for_tile(tile_type)

func has_required_interface(required_interface: String) -> bool:
	if required_interface.is_empty():
		return true

	for module in installed_modules:
		if module == null:
			continue
		if module.id == required_interface:
			return true
		if required_interface in module.granted_commands:
			return true
		if "interface" in module.granted_commands:
			return true

	return false

func has_cooling_support() -> bool:
	return has_module_id("cooling_v1")

func evaluate_device_capability(device: DeviceDefinition) -> DiagnosticResult:
	var result := DiagnosticResult.new()

	if device == null:
		result.status = DiagnosticResult.STATUS_BLOCKED
		result.device_type = ""
		result.device_name = "Unknown"
		result.supported_action = ""
		result.reason = "No device detected."
		result.recommendation = "Face a digital device and scan again."
		result.estimated_risk = "none"
		return result

	if not has_required_interface(device.required_interface):
		result.status = DiagnosticResult.STATUS_BLOCKED
		result.device_type = device.device_type
		result.device_name = device.display_name
		result.supported_action = device.supported_action
		result.reason = "Missing required interface: " + device.required_interface
		result.recommendation = "Install Interface V1 or compatible module."
		result.estimated_risk = "low"
		return result

	if device.device_type == "airflow_terminal":
		result.device_type = device.device_type
		result.device_name = device.display_name
		result.supported_action = device.supported_action
		if not mission8_terminal_cooled:
			result.status = DiagnosticResult.STATUS_BLOCKED
			result.reason = "Terminal heat is too high without airflow."
			result.recommendation = "Rotate the fan platform and increase fan speed until airflow reaches the terminal."
			result.estimated_risk = "high"
			return result
		result.status = DiagnosticResult.STATUS_READY
		result.reason = "Terminal cooled by directed airflow."
		result.recommendation = "Proceed with Hack Device."
		result.estimated_risk = "low"
		return result

	if device.device_type == "hot_node":
		result.device_type = device.device_type
		result.device_name = device.display_name
		result.supported_action = device.supported_action
		if has_cooling_support():
			result.status = DiagnosticResult.STATUS_READY
			result.reason = "Cooling support detected."
			result.recommendation = "Hack Device can stabilize the node safely."
			result.estimated_risk = "low"
			return result
		result.status = DiagnosticResult.STATUS_RISKY
		result.reason = "No cooling support installed."
		result.recommendation = "Install Cooling V1 or proceed with extra energy cost."
		result.estimated_risk = "medium"
		return result

	result.status = DiagnosticResult.STATUS_READY
	result.device_type = device.device_type
	result.device_name = device.display_name
	result.supported_action = device.supported_action
	result.reason = "Current build can interact with this device."
	result.recommendation = "Proceed with Hack Device."
	result.estimated_risk = "low"
	return result

func evaluate_facing_device_capability() -> DiagnosticResult:
	var device := get_facing_device_definition()
	last_diagnostic_result = evaluate_device_capability(device)
	print(
		"Capability check | Status: ",
		last_diagnostic_result.status,
		" | Device: ",
		last_diagnostic_result.device_name,
		" | Action: ",
		last_diagnostic_result.supported_action
	)
	return last_diagnostic_result
	
func open_door(door_position: Vector2i) -> void:
	if not can_use_physical_hand():
		hint_requested.emit("Hand occupied. Return to the box before using physical interact.")
		status_changed.emit()
		return
	if not require_command("open_physical_door", "Missing module: Manipulator V1 required."):
		return
	if not has_key:
		print("Door is locked. Physical key required.")
		hint_requested.emit("Physical door locked. Find the physical key first.")
		return
	
	grid_manager.set_tile(door_position, GridManager.TILE_FLOOR)
	spend_action(1, 1)
	print("Door opened.")
	hint_requested.emit("Physical door opened. Reach the exit.")
	print_status()
	
func open_digital_door(door_position: Vector2i) -> void:
	if not require_command("open_digital_door", "Missing module: Interface V1 required."):
		return
	if not has_info_key and not use_digital_record(DIGITAL_RECORD_INFO_KEY):
		print("Digital door locked. Info-Key required from terminal.")
		hint_requested.emit("Digital door requires Info-Key. Hack the terminal first.")
		return

	if not can_spend_action(1, 1):
		return

	grid_manager.set_tile(door_position, GridManager.TILE_FLOOR)
	spend_action(1, 1)
	print("Digital door opened.")
	hint_requested.emit("Digital door opened. Info-Key remains stored.")
	status_changed.emit()


func scan_device() -> void:
	if mission_finished:
		return

	if not can_spend_action(1, 1):
		return

	var device := get_facing_device_definition()
	if device == null:
		var blocked_result := DiagnosticResult.new()
		blocked_result.status = DiagnosticResult.STATUS_BLOCKED
		blocked_result.device_name = "Unknown"
		blocked_result.reason = "No digital device detected."
		blocked_result.recommendation = "Face a terminal or digital door and scan again."
		blocked_result.estimated_risk = "none"
		last_diagnostic_result = blocked_result
		hint_requested.emit("No digital device detected. Face a terminal or digital door, then scan.")
		status_changed.emit()
		return

	spend_action(1, 1)
	evaluate_facing_device_capability()
	if last_diagnostic_result.status == DiagnosticResult.STATUS_BLOCKED:
		hint_requested.emit("Scan complete: BLOCKED. Check Diagnostic panel for missing requirements.")
	else:
		hint_requested.emit("Scan complete: " + last_diagnostic_result.get_status_text() + ". Check Diagnostic panel, then use Hack Device if READY.")
	status_changed.emit()

func hack_device() -> void:
	if mission_finished:
		return

	if last_diagnostic_result == null:
		hint_requested.emit("Scan device first.")
		status_changed.emit()
		return

	if not last_diagnostic_result.is_action_allowed():
		hint_requested.emit("Hack blocked. Check Diagnostic panel.")
		status_changed.emit()
		return

	var device := get_facing_device_definition()
	if device == null:
		hint_requested.emit("No digital device detected. Face a terminal or digital door, then scan.")
		status_changed.emit()
		return

	if device.device_type != last_diagnostic_result.device_type \
	or device.supported_action != last_diagnostic_result.supported_action:
		hint_requested.emit("Device changed. Scan this device again.")
		status_changed.emit()
		return

	match device.supported_action:
		"download_info_key":
			if not can_spend_action(1, 1):
				return
			spend_action(1, 1)
			if current_mission_index == 2:
				hint_requested.emit("Terminal is silent. Interface calibration required. Return to the box.")
				complete_mission()
				return
			has_info_key = true
			store_digital_record(DIGITAL_RECORD_INFO_KEY, "Info-Key", "Digital authorization record for opening a digital door.")
			hint_requested.emit("Info-Key downloaded. Now find the digital door, scan it, then hack it.")
			status_changed.emit()
			return
		"open_digital_door":
			if not has_info_key and not use_digital_record(DIGITAL_RECORD_INFO_KEY):
				hint_requested.emit("Digital door requires Info-Key. Hack the terminal first.")
				status_changed.emit()
				return
			if not can_spend_action(1, 1):
				return
			spend_action(1, 1)
			grid_manager.set_tile(get_facing_device_position(), GridManager.TILE_FLOOR)
			hint_requested.emit("Digital door opened. Info-Key remains stored.")
			status_changed.emit()
			return
		"unlock_airflow_terminal":
			if not can_spend_action(1, 1):
				return
			spend_action(1, 1)
			mission8_terminal_hacked = true
			if grid_manager != null and grid_manager.is_in_bounds(mission8_door_position):
				grid_manager.set_tile(mission8_door_position, GridManager.TILE_FLOOR)
			hint_requested.emit("Airflow Terminal hacked. Path opened.")
			status_changed.emit()
			return
		"stabilize_hot_node":
			var energy_cost := 1
			if last_diagnostic_result.status == DiagnosticResult.STATUS_RISKY:
				energy_cost = 3
			if not can_spend_action(1, energy_cost):
				return
			spend_action(1, energy_cost)
			var hot_node_position := get_facing_device_position()
			grid_manager.set_tile(hot_node_position, GridManager.TILE_FLOOR)
			var adjacent_offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
			for offset in adjacent_offsets:
				var adjacent_position := hot_node_position + offset
				if grid_manager.get_tile(adjacent_position) == GridManager.TILE_DIGITAL_DOOR:
					grid_manager.set_tile(adjacent_position, GridManager.TILE_FLOOR)
			if last_diagnostic_result.status == DiagnosticResult.STATUS_RISKY:
				hint_requested.emit("Risky hack succeeded, but Bipob spent extra energy.")
			else:
				hint_requested.emit("Hot Node stabilized.")
			status_changed.emit()
			return
		_:
			hint_requested.emit("Unsupported hack action.")
			status_changed.emit()
			return

func open_route_gate(gate_position: Vector2i) -> void:
	if not has_digital_record(DIGITAL_RECORD_ROUTE_DATA):
		hint_requested.emit("Route Gate locked. Route Data required.")
		status_changed.emit()
		return

	if not can_spend_action(1, 1):
		return

	grid_manager.set_tile(gate_position, GridManager.TILE_FLOOR)
	spend_action(1, 1)
	hint_requested.emit("Route Gate opened using Route Data.")
	status_changed.emit()

func interact() -> void:
	var target_position := get_facing_device_position()
	var target_tile := grid_manager.get_tile(target_position)

	# Legacy interact must not process digital devices.
	if target_tile == GridManager.TILE_TERMINAL:
		hint_requested.emit("Terminal is a digital device. Use Scan Device first, then Hack Device.")
		status_changed.emit()
		return

	if target_tile == GridManager.TILE_DIGITAL_DOOR:
		hint_requested.emit("Digital door cannot be opened with Interact. Use Scan Device, then Hack Device.")
		status_changed.emit()
		return
	if target_tile == GridManager.TILE_HOT_NODE:
		hint_requested.emit("Hot Node is a digital device. Use Scan Device, then Hack Device.")
		status_changed.emit()
		return
	if target_tile == GridManager.TILE_AIRFLOW_TERMINAL:
		hint_requested.emit("Airflow Terminal is a digital device. Use Scan Device, then Hack Device.")
		status_changed.emit()
		return
	if target_tile == GridManager.TILE_PLATFORM_CONTROL:
		hint_requested.emit("Use left/right platform controls.")
		status_changed.emit()
		return
	if target_tile == GridManager.TILE_PLATFORM_CONTROL_LEFT:
		interact_mission8_platform_control_left()
		return
	if target_tile == GridManager.TILE_PLATFORM_CONTROL_RIGHT:
		interact_mission8_platform_control_right()
		return
	if target_tile == GridManager.TILE_FAN_CONTROL:
		hint_requested.emit("Use fan speed up/down controls.")
		status_changed.emit()
		return
	if target_tile == GridManager.TILE_FAN_SPEED_UP_CONTROL:
		increase_mission8_fan_speed()
		return
	if target_tile == GridManager.TILE_FAN_SPEED_DOWN_CONTROL:
		decrease_mission8_fan_speed()
		return
	if target_tile == GridManager.TILE_CABLE_REEL:
		interact_mission7_cable_reel()
		return
	if target_tile == GridManager.TILE_SOCKET:
		interact_mission7_socket()
		return
	if target_tile == GridManager.TILE_POWERED_GATE:
		hint_requested.emit("Powered gate is closed. Connect the cable to the socket.")
		status_changed.emit()
		return
	if current_mission_index == 7 and mission7_is_dragging_cable and (target_tile == GridManager.TILE_COMPONENT or target_tile == GridManager.TILE_KEY or target_tile == GridManager.TILE_DOOR):
		hint_requested.emit("Cable in hand. Connect it to the socket or drop it first.")
		status_changed.emit()
		return
	
	match target_tile:
		GridManager.TILE_COMPONENT:
			pick_up_component(target_position)
			return
		GridManager.TILE_KEY:
			if not can_use_physical_hand():
				hint_requested.emit("Hand occupied. Return to the box before using physical interact.")
				status_changed.emit()
				return
			if not can_spend_action(1, 1):
				return
			pick_up_key(target_position)
		GridManager.TILE_DOOR:
			if not can_use_physical_hand():
				hint_requested.emit("Hand occupied. Return to the box before using physical interact.")
				status_changed.emit()
				return
			if not can_spend_action(1, 1):
				return
			open_door(target_position)
		GridManager.TILE_ROUTE_GATE:
			open_route_gate(target_position)
		_:
			print("Nothing to interact with at: ", target_position)
			hint_requested.emit("Nothing to interact with. Face a key, door, or terminal and press E.")

func setup_mission8() -> void:
	mission8_fan_platform_position = Vector2i(4, 2)
	mission8_platform_control_position = Vector2i(2, 2)
	mission8_platform_left_control_position = Vector2i(2, 2)
	mission8_platform_right_control_position = Vector2i(5, 2)
	mission8_fan_control_position = Vector2i(2, 4)
	mission8_fan_speed_up_control_position = Vector2i(2, 3)
	mission8_fan_speed_down_control_position = Vector2i(2, 4)
	mission8_terminal_position = Vector2i(6, 3)
	mission8_door_position = Vector2i(6, 4)
	mission8_fan_direction = Direction.EAST
	mission8_fan_speed = 0
	mission8_terminal_cooled = false
	mission8_terminal_hacked = false
	mission8_airflow_cells.clear()
	update_mission8_airflow()

func get_direction_display_name(direction_value: Direction) -> String:
	match direction_value:
		Direction.NORTH:
			return "NORTH"
		Direction.EAST:
			return "EAST"
		Direction.SOUTH:
			return "SOUTH"
		Direction.WEST:
			return "WEST"
	return "UNKNOWN"

func get_direction_name(value: Direction) -> String:
	match value:
		Direction.NORTH:
			return "NORTH"
		Direction.EAST:
			return "EAST"
		Direction.SOUTH:
			return "SOUTH"
		Direction.WEST:
			return "WEST"
		_:
			return "UNKNOWN"

func get_mission8_airflow_status_text() -> String:
	if current_mission_index != 8:
		return ""

	var range := get_mission8_airflow_range_for_speed(mission8_fan_speed)
	return "Airflow: %s | Speed: %d | Range: %d | Terminal: %s" % [
		get_direction_display_name(mission8_fan_direction),
		mission8_fan_speed,
		range,
		get_mission8_terminal_state_text()
	]

func get_mission7_cable_status_text() -> String:
	if current_mission_index != 7:
		return ""
	if mission7_cable_connected:
		return "Cable: connected"
	if mission7_is_dragging_cable:
		return "Cable: dragging"
	return "Cable: idle"

func setup_mission7() -> void:
	mission7_is_dragging_cable = false
	mission7_cable_connected = false
	mission7_cable_reel_position = Vector2i(2, 1)
	mission7_socket_position = Vector2i(5, 3)
	mission7_powered_gate_position = Vector2i(6, 4)
	mission7_cable_path.clear()
	# TODO(BIB-360): cable max-length behavior is intentionally not enforced in MVP.

func interact_mission7_cable_reel() -> void:
	if mission7_cable_connected:
		hint_requested.emit("Cable is already connected.")
		return
	if mission7_is_dragging_cable:
		hint_requested.emit("Cable already in hand. Drag it to the socket.")
		return
	if held_module != null:
		hint_requested.emit("Hand occupied. Drop or store the item before taking the cable.")
		return
	if not can_spend_action(1, 1):
		return
	mission7_is_dragging_cable = true
	mission7_cable_path.clear()
	mission7_cable_path.append(grid_position)
	hint_requested.emit("Cable end taken. Drag it to the socket.")
	spend_action(1, 1)
	status_changed.emit()

func interact_mission7_socket() -> void:
	if not mission7_is_dragging_cable:
		hint_requested.emit("Take the cable end from the reel first.")
		return
	if mission7_cable_connected:
		hint_requested.emit("Socket already connected.")
		return
	if not can_spend_action(1, 1):
		return
	mission7_is_dragging_cable = false
	mission7_cable_connected = true
	if grid_manager.get_tile(mission7_powered_gate_position) == GridManager.TILE_POWERED_GATE:
		grid_manager.set_tile(mission7_powered_gate_position, GridManager.TILE_FLOOR)
	hint_requested.emit("Cable connected. Powered gate opened.")
	spend_action(1, 1)
	status_changed.emit()

func add_current_cell_to_mission7_cable_path() -> void:
	if grid_manager == null or mission7_cable_connected or not mission7_is_dragging_cable:
		return
	if not mission7_cable_path.has(grid_position):
		mission7_cable_path.append(grid_position)
	var tile := grid_manager.get_tile(grid_position)
	if tile == GridManager.TILE_FLOOR:
		grid_manager.set_tile(grid_position, GridManager.TILE_CABLE)

func clear_mission7_cable_tiles() -> void:
	if grid_manager == null:
		mission7_cable_path.clear()
		return
	for position in mission7_cable_path:
		if grid_manager.is_in_bounds(position) and grid_manager.get_tile(position) == GridManager.TILE_CABLE:
			grid_manager.set_tile(position, GridManager.TILE_FLOOR)
	mission7_cable_path.clear()

func release_mission7_cable_end() -> void:
	if not mission7_is_dragging_cable:
		hint_requested.emit("No cable in hand.")
		return
	mission7_is_dragging_cable = false
	clear_mission7_cable_tiles()
	hint_requested.emit("Cable released. Return to the reel to take it again.")
	status_changed.emit()

func get_mission8_terminal_state_text() -> String:
	return "cooled" if mission8_terminal_cooled else "hot"

func rotate_mission8_fan_left() -> void:
	mission8_fan_direction = Direction.values()[(int(mission8_fan_direction) + 3) % 4]
	update_mission8_airflow()
	hint_requested.emit("Fan platform rotated left. Airflow: %s | Terminal: %s" % [get_direction_display_name(mission8_fan_direction), get_mission8_terminal_state_text()])
	status_changed.emit()

func rotate_mission8_fan_right() -> void:
	mission8_fan_direction = Direction.values()[(int(mission8_fan_direction) + 1) % 4]
	update_mission8_airflow()
	hint_requested.emit("Fan platform rotated right. Airflow: %s | Terminal: %s" % [get_direction_display_name(mission8_fan_direction), get_mission8_terminal_state_text()])
	status_changed.emit()

func interact_mission8_platform_control_left() -> void:
	if current_mission_index != 8:
		hint_requested.emit("Platform control is inactive in this mission.")
		status_changed.emit()
		return
	if not can_spend_action(1, 1):
		return
	spend_action(1, 1)
	rotate_mission8_fan_left()

func interact_mission8_platform_control_right() -> void:
	if current_mission_index != 8:
		hint_requested.emit("Platform control is inactive in this mission.")
		status_changed.emit()
		return
	if not can_spend_action(1, 1):
		return
	spend_action(1, 1)
	rotate_mission8_fan_right()

func interact_mission8_fan_control() -> void:
	if current_mission_index != 8:
		hint_requested.emit("Fan control is inactive in this mission.")
		status_changed.emit()
		return
	if not can_spend_action(1, 1):
		return
	mission8_fan_speed = (mission8_fan_speed + 1) % 4
	spend_action(1, 1)
	update_mission8_airflow()
	var range := get_mission8_airflow_range_for_speed(mission8_fan_speed)
	hint_requested.emit("Fan speed set to %d. Airflow range: %d | Terminal: %s." % [mission8_fan_speed, range, get_mission8_terminal_state_text()])
	status_changed.emit()

func change_mission8_fan_speed(delta: int) -> void:
	if current_mission_index != 8:
		hint_requested.emit("Fan speed controls are inactive in this mission.")
		status_changed.emit()
		return
	if not can_spend_action(1, 1):
		return

	var previous_speed := mission8_fan_speed
	mission8_fan_speed = clampi(mission8_fan_speed + delta, 0, 3)
	if mission8_fan_speed == previous_speed:
		if delta > 0:
			hint_requested.emit("Fan speed already at maximum.")
		else:
			hint_requested.emit("Fan speed already at minimum.")
		status_changed.emit()
		return

	update_mission8_airflow()
	var airflow_range := get_mission8_airflow_range_for_speed(mission8_fan_speed)
	hint_requested.emit(
		"Fan speed set to %d. Airflow range: %d | Terminal: %s" % [
			mission8_fan_speed,
			airflow_range,
			get_mission8_terminal_state_text()
		]
	)
	spend_action(1, 1)
	status_changed.emit()

func increase_mission8_fan_speed() -> void:
	change_mission8_fan_speed(1)

func decrease_mission8_fan_speed() -> void:
	change_mission8_fan_speed(-1)

func get_mission8_airflow_range_for_speed(speed: int) -> int:
	match speed:
		0:
			return 0
		1:
			return 2
		2:
			return 4
		3:
			return 6
		_:
			return 0

func update_mission8_airflow() -> void:
	if grid_manager == null:
		return
	for cell in mission8_airflow_cells:
		if not grid_manager.is_in_bounds(cell):
			continue
		if grid_manager.get_tile(cell) == GridManager.TILE_AIRFLOW:
			grid_manager.set_tile(cell, GridManager.TILE_FLOOR)
	mission8_airflow_cells.clear()
	mission8_terminal_cooled = false
	grid_manager.set_fan_platform_marker(
		mission8_fan_platform_position,
		get_direction_vector(mission8_fan_direction)
	)

	if mission8_fan_speed <= 0:
		grid_manager.queue_redraw()
		status_changed.emit()
		return

	var max_range := get_mission8_airflow_range_for_speed(mission8_fan_speed)
	var direction_vector := get_direction_vector(mission8_fan_direction)
	var current_position := mission8_fan_platform_position + direction_vector

	for _i in range(max_range):
		if not grid_manager.is_in_bounds(current_position):
			break
		if current_position == mission8_terminal_position:
			mission8_terminal_cooled = true
			break
		var tile := grid_manager.get_tile(current_position)
		if tile == GridManager.TILE_WALL or tile == GridManager.TILE_DIGITAL_DOOR or tile == GridManager.TILE_ROUTE_GATE:
			break
		if tile == GridManager.TILE_AIRFLOW_TERMINAL:
			mission8_terminal_cooled = true
			break
		if tile == GridManager.TILE_FAN_PLATFORM or tile == GridManager.TILE_PLATFORM_CONTROL or tile == GridManager.TILE_PLATFORM_CONTROL_LEFT or tile == GridManager.TILE_PLATFORM_CONTROL_RIGHT or tile == GridManager.TILE_FAN_CONTROL or tile == GridManager.TILE_FAN_SPEED_UP_CONTROL or tile == GridManager.TILE_FAN_SPEED_DOWN_CONTROL:
			break
		if tile == GridManager.TILE_FLOOR or tile == GridManager.TILE_AIRFLOW:
			grid_manager.set_tile(current_position, GridManager.TILE_AIRFLOW)
			mission8_airflow_cells.append(current_position)
		current_position += direction_vector

	grid_manager.queue_redraw()
	status_changed.emit()

func create_debug_field_component() -> BipobModule:
	var module := BipobModule.new()
	module.id = "cooling_v1"
	module.display_name = "Cooling V1"
	module.description = "Basic cooling component for future internal builds."
	module.energy_bonus = 0
	module.actions_bonus = 0
	module.vision_bonus = 0
	module.granted_commands = []
	return module

func get_position_key(position: Vector2i) -> String:
	return str(position.x) + "," + str(position.y)

func set_field_module(position: Vector2i, module: BipobModule) -> void:
	if grid_manager == null:
		return
	if module == null:
		return
	if not grid_manager.is_in_bounds(position):
		return

	grid_manager.set_tile(position, GridManager.TILE_COMPONENT)
	field_modules_by_position[get_position_key(position)] = module

func get_field_module(position: Vector2i) -> BipobModule:
	var key := get_position_key(position)
	if field_modules_by_position.has(key):
		return field_modules_by_position[key]
	return null

func clear_field_module(position: Vector2i) -> void:
	var key := get_position_key(position)
	if field_modules_by_position.has(key):
		field_modules_by_position.erase(key)

func place_visor_v2_field_module(position: Vector2i) -> void:
	set_field_module(position, create_visor_v2_module())

func place_gpu_v1_field_module(position: Vector2i) -> void:
	set_field_module(position, create_gpu_v1_module())

func setup_mission4_field_modules() -> void:
	if grid_manager == null:
		return

	var visor_position := Vector2i(4, 1)
	var gpu_position := Vector2i(2, 6)
	var hidden_node_position := Vector2i(4, 6)

	if not has_module_id_anywhere("visor_v2"):
		place_visor_v2_field_module(visor_position)
	else:
		grid_manager.set_tile(visor_position, GridManager.TILE_FLOOR)

	if not has_module_id_anywhere("gpu_v1"):
		place_gpu_v1_field_module(gpu_position)
	else:
		grid_manager.set_tile(gpu_position, GridManager.TILE_FLOOR)

	active_hidden_route_node_position = Vector2i(-1, -1)
	if grid_manager.is_in_bounds(hidden_node_position):
		grid_manager.set_tile(hidden_node_position, GridManager.TILE_HIDDEN_ROUTE_NODE)
		active_hidden_route_node_position = hidden_node_position

func place_debug_field_module_if_valid(position: Vector2i, module_name: String, place_callback: Callable) -> void:
	if grid_manager == null:
		return
	if not grid_manager.is_in_bounds(position):
		print("Skipping debug field module ", module_name, ": out of bounds at ", position)
		hint_requested.emit("Debug module %s skipped: invalid position %s." % [module_name, str(position)])
		return
	if grid_manager.get_tile(position) != GridManager.TILE_FLOOR:
		print("Skipping debug field module ", module_name, ": blocked tile at ", position)
		hint_requested.emit("Debug module %s skipped: tile blocked at %s." % [module_name, str(position)])
		return
	place_callback.call(position)

func place_debug_mission4_field_modules() -> void:
	place_debug_field_module_if_valid(Vector2i(4, 1), "Visor V2", Callable(self, "place_visor_v2_field_module"))
	place_debug_field_module_if_valid(Vector2i(4, 3), "GPU V1", Callable(self, "place_gpu_v1_field_module"))

func get_carried_physical_count() -> int:
	var count := 0
	if held_module != null:
		count += 1
	if stored_physical_module != null:
		count += 1
	return count

func is_hand_occupied() -> bool:
	return held_module != null

func can_use_physical_hand() -> bool:
	return not is_hand_occupied()

func is_physical_storage_occupied() -> bool:
	return stored_physical_module != null

func has_free_physical_storage() -> bool:
	return stored_physical_module == null

func has_any_physical_item() -> bool:
	return held_module != null or stored_physical_module != null

func can_pick_up_physical_item() -> bool:
	return get_carried_physical_count() < physical_carry_capacity

func pick_up_component(component_position: Vector2i) -> void:
	if grid_manager == null:
		return
	if grid_manager.get_tile(component_position) != GridManager.TILE_COMPONENT:
		hint_requested.emit("No component to pick up here.")
		status_changed.emit()
		return
	if held_module != null and is_physical_storage_occupied():
		hint_requested.emit("Physical storage full. Drop or deliver an item first.")
		status_changed.emit()
		return

	if not can_spend_action(1, 1):
		return

	var picked_module := get_field_module(component_position)
	if picked_module == null:
		picked_module = create_debug_field_component()

	clear_field_module(component_position)
	grid_manager.set_tile(component_position, GridManager.TILE_FLOOR)

	if held_module == null:
		held_module = picked_module
		hint_requested.emit("Component collected in hand: %s." % get_module_display_name(picked_module))
	else:
		stored_physical_module = picked_module
		hint_requested.emit("Component stored internally: %s." % get_module_display_name(picked_module))

	if current_mission_index == 4:
		if picked_module.id == "visor_v2":
			hint_requested.emit("Visor V2 recovered. Return to the box and install it.")
		elif picked_module.id == "gpu_v1":
			hint_requested.emit("GPU V1 recovered. Return to the box and install it.")

	spend_action(1, 1)
	status_changed.emit()


func rotate_physical_storage() -> void:
	if mission_finished:
		return

	if not has_any_physical_item():
		hint_requested.emit("No physical items to rotate.")
		status_changed.emit()
		return

	if not can_spend_action(1, 0):
		return

	var hand_module := held_module
	held_module = stored_physical_module
	stored_physical_module = hand_module
	spend_action(1, 0)
	hint_requested.emit("Rotated physical storage.")
	status_changed.emit()

func drop_held_item() -> void:
	if mission_finished:
		return
	if current_mission_index == 7 and mission7_is_dragging_cable:
		release_mission7_cable_end()
		return

	if held_module == null:
		hint_requested.emit("Hand is empty. Nothing to drop.")
		status_changed.emit()
		return

	var target_position := grid_position + get_direction_vector(direction)
	if not grid_manager.is_in_bounds(target_position) or grid_manager.get_tile(target_position) != GridManager.TILE_FLOOR:
		hint_requested.emit("Cannot drop item here. Face an empty floor cell.")
		status_changed.emit()
		return

	if not can_spend_action(1, 1):
		return

	var module_to_drop := held_module
	set_field_module(target_position, module_to_drop)
	spend_action(1, 1)
	hint_requested.emit("Dropped: %s." % get_module_display_name(module_to_drop))
	held_module = null
	status_changed.emit()


func read_terminal(target_position: Vector2i) -> void:
	if not require_command("read_terminal", "Missing module: Interface V1 required."):
		return
	match current_mission_index:
		2:
			if not can_spend_action(1, 1):
				return
			spend_action(1, 1)
			print("Terminal is silent. Interface calibration required.")
			hint_requested.emit("Terminal is silent. Interface calibration required.")
			complete_mission()
			return
		3:
			if not can_spend_action(1, 1):
				return
			has_info_key = true
			store_digital_record(DIGITAL_RECORD_INFO_KEY, "Info-Key", "Digital authorization record for opening a digital door.")
			spend_action(1, 1)
			print("Terminal accessed at ", target_position, ". Info-Key downloaded.")
			hint_requested.emit("Info-Key downloaded. Find the digital door.")
			status_changed.emit()
			print_status()
			return
		_:
			print("Terminal is inactive in this mission.")
			hint_requested.emit("Terminal is inactive in this mission.")

func pick_up_key(key_position: Vector2i) -> void:
	if not can_use_physical_hand():
		hint_requested.emit("Hand occupied. Return to the box before using physical interact.")
		status_changed.emit()
		return
	if not require_command("interact_key", "Missing module: Manipulator V1 required."):
		return
	has_key = true
	grid_manager.set_tile(key_position, GridManager.TILE_FLOOR)
	spend_action(1, 1)
	print("Picked up physical key.")
	hint_requested.emit("Physical key collected. Use Interact on the physical door.")
	print_status()
	
func print_status() -> void:
	print(
		"Energy: ", energy, " / ", max_energy,
		" | Actions: ", actions_left, " / ", actions_per_turn,
		" | Has Key: ", has_key,
		" | Has Info Key: ", has_info_key,
		" | Hand: ", get_module_display_name(held_module) if held_module != null else "empty",
		" | Storage: ", get_module_display_name(stored_physical_module) if stored_physical_module != null else "empty",
		" | Carry: ", get_carried_physical_count(), " / ", physical_carry_capacity
	)
