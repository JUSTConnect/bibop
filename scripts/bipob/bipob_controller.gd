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
const INTERNAL_SIZE_X := 5
const INTERNAL_SIZE_Y := 8
const INTERNAL_SIZE_Z := 5
const THERMAL_CRITICAL_HEAT := 5
const MODULE_ICON_DIR: String = "res://assets/ui/module_icons/"

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
var internal_modules_by_cell: Dictionary = {}
var placed_internal_modules: Array[Dictionary] = []
var internal_overlay_paths: Array[Dictionary] = []
var next_internal_overlay_path_id: int = 1
var selected_internal_box_index: int = 0
var selected_internal_origin: Vector3i = Vector3i.ZERO
var selected_internal_rotation: int = 0
var selected_overlay_path_type: String = "liquid"
var selected_overlay_cells: Array[Vector3i] = []
var selected_overlay_path_index: int = 0
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


func get_module_visual_key(module: BipobModule) -> String:
	if module == null:
		return "unknown"

	var module_id: String = module.id

	if module_id.contains("battery"):
		return "battery"
	if module_id.contains("processor"):
		return "processor"
	if module_id.contains("memory"):
		return "memory"
	if module_id.contains("hard_drive") or module_id.contains("hdd") or module_id.contains("ssd"):
		return "storage"
	if module_id.contains("power_block"):
		return "power"
	if module_id.contains("cooler"):
		return "cooler"
	if module_id.contains("radiator"):
		return "radiator"
	if module_id.contains("water_tube"):
		return "water_tube"
	if module_id.contains("air_duct"):
		return "air_duct"
	if module_id.contains("air_intake"):
		return "air_intake"
	if module_id.contains("visor"):
		return "visor"
	if module_id.contains("wheel"):
		return "wheels"
	if module_id.contains("leg"):
		return "legs"
	if module_id.contains("track"):
		return "tracks"
	if module_id.contains("manipulator"):
		return "manipulator"
	if module_id.contains("interface"):
		return "interface"
	if module_id.contains("gpu"):
		return "gpu"

	return "module"



func get_module_icon_path(module: BipobModule) -> String:
	var key: String = get_module_visual_key(module)
	return get_module_icon_path_by_key(key)

func get_module_icon_path_by_key(key: String) -> String:
	if key.is_empty():
		key = "unknown"
	return MODULE_ICON_DIR + key + ".png"

func get_module_visual_short_label(module: BipobModule) -> String:
	if module == null:
		return "?"

	var key: String = get_module_visual_key(module)

	match key:
		"battery":
			return "BAT"
		"processor":
			return "CPU"
		"memory":
			return "MEM"
		"storage":
			return "DRV"
		"power":
			return "PWR"
		"cooler":
			return "FAN"
		"radiator":
			return "RAD"
		"water_tube":
			return "TUBE"
		"air_duct":
			return "DUCT"
		"air_intake":
			return "AIR"
		"visor":
			return "VIS"
		"wheels":
			return "WHL"
		"legs":
			return "LEG"
		"tracks":
			return "TRK"
		"manipulator":
			return "ARM"
		"interface":
			return "I/O"
		"gpu":
			return "GPU"
		_:
			return "MOD"

func get_module_visual_color(module: BipobModule) -> Color:
	if module == null:
		return Color(0.25, 0.28, 0.30, 1.0)

	var key: String = get_module_visual_key(module)

	match key:
		"battery":
			return Color(0.25, 0.55, 0.95, 1.0)
		"processor":
			return Color(0.95, 0.45, 0.18, 1.0)
		"memory":
			return Color(0.55, 0.35, 0.95, 1.0)
		"storage":
			return Color(0.65, 0.70, 0.78, 1.0)
		"power":
			return Color(0.95, 0.78, 0.20, 1.0)
		"cooler":
			return Color(0.20, 0.75, 0.95, 1.0)
		"radiator":
			return Color(0.45, 0.85, 0.95, 1.0)
		"water_tube":
			return Color(0.05, 0.85, 0.95, 1.0)
		"air_duct":
			return Color(0.55, 0.65, 0.70, 1.0)
		"air_intake":
			return Color(0.35, 0.80, 0.85, 1.0)
		"visor":
			return Color(0.25, 0.95, 0.65, 1.0)
		"wheels":
			return Color(0.55, 0.50, 0.42, 1.0)
		"legs":
			return Color(0.60, 0.55, 0.45, 1.0)
		"tracks":
			return Color(0.45, 0.42, 0.36, 1.0)
		"manipulator":
			return Color(0.90, 0.55, 0.25, 1.0)
		"interface":
			return Color(0.20, 0.70, 0.95, 1.0)
		"gpu":
			return Color(0.20, 0.95, 0.85, 1.0)
		_:
			return Color(0.45, 0.50, 0.55, 1.0)

func get_module_visual_border_color(module: BipobModule) -> Color:
	var base: Color = get_module_visual_color(module)
	return Color(
		clampf(base.r + 0.18, 0.0, 1.0),
		clampf(base.g + 0.18, 0.0, 1.0),
		clampf(base.b + 0.18, 0.0, 1.0),
		1.0
	)

func get_module_visual_card_line(module: BipobModule) -> String:
	if module == null:
		return "[?] Unknown"

	var label: String = get_module_visual_short_label(module)
	var name: String = get_module_display_name(module)
	var size_text: String = ""

	if is_internal_module(module):
		var size: Vector3i = get_internal_module_base_size(module)
		size_text = "%dx%dx%d" % [size.x, size.y, size.z]
	elif is_external_module(module):
		var footprint: Vector2i = get_external_module_footprint_size(module)
		size_text = "%dx%d" % [footprint.x, footprint.y]
	elif is_internal_overlay_module(module):
		size_text = "overlay"
	else:
		size_text = "module"

	return "[%s] %s — %s" % [
		label,
		name,
		size_text
	]
func get_external_module_footprint_size(module: BipobModule) -> Vector2i:
	if module == null:
		return Vector2i.ONE

	var module_id: String = module.id

	if module_id.contains("manipulator") or module_id.contains("interface"):
		return Vector2i(2, 2)

	if module_id.contains("wheel") or module_id.contains("leg") or module_id.contains("track"):
		return Vector2i(3, 2)

	if module_id.contains("visor"):
		return Vector2i(3, 1)

	if module_id.contains("air_intake"):
		return Vector2i(1, 1)

	return Vector2i(1, 1)
func get_module_category(module: BipobModule) -> String:
	if module == null:
		return "utility"

	if not module.category.is_empty():
		return module.category

	match module.id:
		"wheels_v1", "legs_v1", "tracks_v1":
			return "locomotion"
		"visor_v1", "visor_v2":
			return "vision"
		"manipulator_v1":
			return "utility"
		"interface_v1":
			return "data"
		"air_intake_v1":
			return "cooling"
		"battery_v1_a", "battery_v1_b":
			return "power"
		"power_block_v1":
			return "power"
		"processor_v1":
			return "data"
		"memory_v1":
			return "data"
		"hard_drive_v1":
			return "storage"
		"int_interface_v1", "ext_interface_internal_v1":
			return "data"
		"cooler_v1", "radiator_v1", "water_tube_v1", "air_duct_v1":
			return "cooling"
		_:
			if module.placement_type == "external":
				return "external"
			if module.placement_type == "internal":
				return "internal"
			return "utility"

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
		{"id": "interface_v1", "display_name": "External Interface Port V1"},
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

func get_constructor_warning_lines() -> Array[String]:
	var warnings: Array[String] = []

	if has_air_cooling_requiring_intake() and not has_external_air_intake():
		warnings.append("Air cooling requires Air Intake Node on external body.")

	if not is_virtual_power_available():
		warnings.append("Virtual power unavailable: Battery and Power Block required.")

	if not is_internal_data_network_available():
		warnings.append("Internal data network unavailable: Internal Interface required.")

	if not is_external_data_network_available():
		warnings.append("External data bridge unavailable: Internal Interface and External Interface required.")

	var critical_count: int = get_critical_internal_preview_count()
	if critical_count > 0:
		warnings.append("Thermal critical preview: %d module(s) at heat 5." % critical_count)

	return warnings

func get_constructor_warning_summary_text() -> String:
	var warnings: Array[String] = get_constructor_warning_lines()
	var lines: Array[String] = []
	lines.append("Constructor warnings:")

	if warnings.is_empty():
		lines.append("none")
		return "\n".join(lines)

	for warning in warnings:
		lines.append("- " + warning)

	return "\n".join(lines)

func get_constructor_metadata_summary_text() -> String:
	var lines: Array[String] = []
	lines.append("Constructor metadata:")

	var all_modules: Array[BipobModule] = []
	for module_variant in box_storage:
		var module: BipobModule = module_variant
		if module != null and not all_modules.has(module):
			all_modules.append(module)
	for module in get_unique_external_modules():
		if module != null and not all_modules.has(module):
			all_modules.append(module)
	for module in get_unique_internal_modules():
		if module != null and not all_modules.has(module):
			all_modules.append(module)

	if all_modules.is_empty():
		lines.append("none")
		return "\n".join(lines)

	for module in all_modules:
		if module == null:
			continue

		lines.append("- %s | id=%s | placement=%s | category=%s | role=%s" % [
			get_module_display_name(module),
			module.id,
			module.placement_type,
			get_module_category(module),
			module.internal_role
		])

	return "\n".join(lines)

func get_constructor_warning_compact_text() -> String:
	var warnings: Array[String] = get_constructor_warning_lines()
	if warnings.is_empty():
		return "Warnings: none"
	return "Warnings: %d" % warnings.size()

func get_constructor_consistency_summary_text() -> String:
	var issues: Array[String] = get_constructor_consistency_issue_lines()
	var lines: Array[String] = []
	lines.append("Constructor consistency:")
	if issues.is_empty():
		lines.append("OK")
		return "\n".join(lines)
	lines.append("%d issue(s)" % issues.size())
	for issue in issues:
		lines.append("- " + issue)
	return "\n".join(lines)

func get_constructor_consistency_compact_text() -> String:
	var issue_count: int = get_constructor_consistency_issue_lines().size()
	if issue_count == 0:
		return "Consistency: OK"
	return "Consistency: %d issue(s)" % issue_count

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

	for cell_position in preferred_positions:
		if grid_manager == null:
			return Vector2i(-1, -1)
		if grid_manager.is_in_bounds(cell_position) and grid_manager.get_tile(cell_position) == GridManager.TILE_FLOOR:
			return cell_position

	return Vector2i(-1, -1)

func place_debug_hidden_route_node() -> void:
	if not debug_place_hidden_route_node:
		return
	if grid_manager == null:
		return

	var hidden_node_position := find_valid_debug_hidden_route_node_position()
	if hidden_node_position == Vector2i(-1, -1):
		hint_requested.emit("Debug hidden route-node was not placed: no valid floor tile.")
		return

	active_hidden_route_node_position = hidden_node_position
	grid_manager.set_tile(hidden_node_position, GridManager.TILE_HIDDEN_ROUTE_NODE)

	if grid_manager.has_method("reset_hidden_discoveries"):
		grid_manager.reset_hidden_discoveries()

	if debug_show_hidden_route_node_logs:
		print("Debug hidden route-node placed at: ", hidden_node_position)
		hint_requested.emit("Debug hidden route-node placed at: " + str(hidden_node_position))

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

func get_internal_volume_size() -> Vector3i:
	return Vector3i(INTERNAL_SIZE_X, INTERNAL_SIZE_Y, INTERNAL_SIZE_Z)

func get_internal_slot_key(cell: Vector3i) -> String:
	return "%d:%d:%d" % [cell.x, cell.y, cell.z]

func is_internal_cell_in_bounds(cell: Vector3i) -> bool:
	var volume_size := get_internal_volume_size()
	return (
		cell.x >= 0 and cell.y >= 0 and cell.z >= 0
	and cell.x < volume_size.x and cell.y < volume_size.y and cell.z < volume_size.z
	)

func is_internal_cell_on_body_edge(cell: Vector3i) -> bool:
	if not is_internal_cell_in_bounds(cell):
		return false

	var volume_size: Vector3i = get_internal_volume_size()

	return (
		cell.x == 0
		or cell.y == 0
		or cell.z == 0
		or cell.x == volume_size.x - 1
		or cell.y == volume_size.y - 1
		or cell.z == volume_size.z - 1
	)

func clamp_selected_overlay_path_index() -> void:
	if internal_overlay_paths.is_empty():
		selected_overlay_path_index = 0
		return

	if selected_overlay_path_index < 0:
		selected_overlay_path_index = internal_overlay_paths.size() - 1
	elif selected_overlay_path_index >= internal_overlay_paths.size():
		selected_overlay_path_index = 0

func get_selected_overlay_path_record() -> Dictionary:
	clamp_selected_overlay_path_index()

	if internal_overlay_paths.is_empty():
		return {}

	return internal_overlay_paths[selected_overlay_path_index]

func get_selected_overlay_path_id() -> String:
	var record: Dictionary = get_selected_overlay_path_record()
	return String(record.get("id", ""))

func select_prev_overlay_path() -> void:
	if internal_overlay_paths.is_empty():
		selected_overlay_path_index = 0
		return

	selected_overlay_path_index -= 1
	clamp_selected_overlay_path_index()

func select_next_overlay_path() -> void:
	if internal_overlay_paths.is_empty():
		selected_overlay_path_index = 0
		return

	selected_overlay_path_index += 1
	clamp_selected_overlay_path_index()

func remove_selected_overlay_path() -> bool:
	var path_id: String = get_selected_overlay_path_id()
	if path_id.is_empty():
		return false

	var removed: bool = remove_internal_overlay_path(path_id)
	clamp_selected_overlay_path_index()
	return removed

func get_selected_overlay_module_id() -> String:
	if selected_overlay_path_type == "duct":
		return "air_duct_v1"
	return "water_tube_v1"

func is_internal_overlay_module(module: BipobModule) -> bool:
	return module != null and module.is_non_volume_cooling_path

func is_valid_internal_overlay_cell(cell: Vector3i) -> bool:
	return is_internal_cell_in_bounds(cell)

func has_selected_overlay_cell(cell: Vector3i) -> bool:
	for selected_cell in selected_overlay_cells:
		if selected_cell == cell:
			return true
	return false

func add_selected_overlay_cell(cell: Vector3i) -> bool:
	if not is_valid_internal_overlay_cell(cell):
		return false
	if has_selected_overlay_cell(cell):
		return false
	selected_overlay_cells.append(cell)
	return true

func remove_selected_overlay_cell(cell: Vector3i) -> bool:
	for i in range(selected_overlay_cells.size()):
		if selected_overlay_cells[i] == cell:
			selected_overlay_cells.remove_at(i)
			return true
	return false

func clear_selected_overlay_cells() -> void:
	selected_overlay_cells.clear()

func toggle_selected_overlay_cell(cell: Vector3i) -> bool:
	if has_selected_overlay_cell(cell):
		return remove_selected_overlay_cell(cell)
	return add_selected_overlay_cell(cell)

func get_last_selected_overlay_cell() -> Vector3i:
	if selected_overlay_cells.is_empty():
		return selected_internal_origin
	return selected_overlay_cells[selected_overlay_cells.size() - 1]

func get_overlay_direction_offset(direction_id: String) -> Vector3i:
	match direction_id:
		"+x":
			return Vector3i(1, 0, 0)
		"-x":
			return Vector3i(-1, 0, 0)
		"+y":
			return Vector3i(0, 1, 0)
		"-y":
			return Vector3i(0, -1, 0)
		"+z":
			return Vector3i(0, 0, 1)
		"-z":
			return Vector3i(0, 0, -1)
		_:
			return Vector3i.ZERO

func start_overlay_path_from_cursor_if_empty() -> void:
	if selected_overlay_cells.is_empty():
		add_selected_overlay_cell(selected_internal_origin)

func extend_selected_overlay_path(direction_id: String) -> bool:
	var offset: Vector3i = get_overlay_direction_offset(direction_id)
	if offset == Vector3i.ZERO:
		return false
	start_overlay_path_from_cursor_if_empty()
	var start_cell: Vector3i = get_last_selected_overlay_cell()
	var next_cell: Vector3i = start_cell + offset
	if not is_internal_cell_in_bounds(next_cell):
		return false
	return add_selected_overlay_cell(next_cell)

func undo_selected_overlay_cell() -> bool:
	if selected_overlay_cells.is_empty():
		return false
	selected_overlay_cells.remove_at(selected_overlay_cells.size() - 1)
	return true

func get_selected_overlay_plan_short_text() -> String:
	var lines: Array[String] = []
	lines.append("Overlay planning:")
	lines.append("- Type: %s" % selected_overlay_path_type)
	lines.append("- Cells: %d" % selected_overlay_cells.size())
	if selected_overlay_cells.is_empty():
		lines.append("- Start: cursor %s" % format_internal_cell(selected_internal_origin))
	else:
		lines.append("- Start: %s" % format_internal_cell(selected_overlay_cells[0]))
		lines.append("- Last: %s" % format_internal_cell(get_last_selected_overlay_cell()))
	lines.append("- Connectivity: %s" % ("connected" if is_selected_overlay_plan_connected() else "disconnected"))
	lines.append("- Components: %d" % get_selected_overlay_plan_component_count())
	if has_method("get_overlay_path_endpoint_count"):
		lines.append("- Endpoints: %d" % get_overlay_path_endpoint_count({
			"id": "planning",
			"module_id": get_selected_overlay_module_id(),
			"path_type": selected_overlay_path_type,
			"cells": selected_overlay_cells
		}))
	return "\n".join(lines)

func commit_selected_overlay_path() -> bool:
	if selected_overlay_cells.is_empty():
		return false

	var module_id: String = get_selected_overlay_module_id()
	var required_module: BipobModule = null
	var raw_index: int = -1
	for i in range(box_storage.size()):
		var module: BipobModule = box_storage[i]
		if module != null and module.id == module_id:
			required_module = module
			raw_index = i
			break
	if required_module == null or raw_index < 0:
		return false

	var copied_cells: Array[Vector3i] = []
	for cell in selected_overlay_cells:
		if is_internal_cell_in_bounds(cell):
			copied_cells.append(cell)
	if copied_cells.is_empty():
		return false

	var path_record: Dictionary = {
		"id": "overlay_%d" % next_internal_overlay_path_id,
		"module_id": module_id,
		"path_type": selected_overlay_path_type,
		"cells": copied_cells
	}
	next_internal_overlay_path_id += 1
	internal_overlay_paths.append(path_record)
	selected_overlay_path_index = internal_overlay_paths.size() - 1
	box_storage.remove_at(raw_index)
	clear_selected_overlay_cells()
	return true

func create_overlay_module_by_id(module_id: String) -> BipobModule:
	match module_id:
		"water_tube_v1":
			return create_internal_module("water_tube_v1", "Water Tube V1", Vector3i(1, 1, 1))
		"air_duct_v1":
			return create_internal_module("air_duct_v1", "Air Duct V1", Vector3i(1, 1, 1))
		_:
			return null

func remove_internal_overlay_path(path_id: String) -> bool:
	for i in range(internal_overlay_paths.size()):
		var record: Dictionary = internal_overlay_paths[i]
		var record_id: String = String(record.get("id", ""))
		if record_id != path_id:
			continue
		var module_id: String = String(record.get("module_id", ""))
		var returned_module: BipobModule = create_overlay_module_by_id(module_id)
		if returned_module != null:
			box_storage.append(returned_module)
		internal_overlay_paths.remove_at(i)
		return true
	return false

func get_internal_overlay_paths_at_cell(cell: Vector3i) -> Array[Dictionary]:
	var paths: Array[Dictionary] = []
	for path_record in internal_overlay_paths:
		var cells: Array = path_record.get("cells", [])
		for item in cells:
			var path_cell: Vector3i = item
			if path_cell == cell:
				paths.append(path_record)
				break
	return paths

func get_overlay_path_cells(path_record: Dictionary) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	var raw_cells: Array = path_record.get("cells", [])
	for item in raw_cells:
		var cell: Vector3i = item
		if is_internal_cell_in_bounds(cell):
			result.append(cell)
	return result

func is_overlay_path_connected(path_record: Dictionary) -> bool:
	var cells: Array[Vector3i] = get_overlay_path_cells(path_record)
	if cells.size() <= 1:
		return true
	var cell_keys: Dictionary = {}
	for cell in cells:
		cell_keys[get_internal_slot_key(cell)] = true
	var visited: Dictionary = {}
	var queue: Array[Vector3i] = []
	queue.append(cells[0])
	visited[get_internal_slot_key(cells[0])] = true
	while not queue.is_empty():
		var current: Vector3i = queue.pop_front()
		for offset in get_internal_neighbor_offsets():
			var neighbor: Vector3i = current + offset
			var neighbor_key: String = get_internal_slot_key(neighbor)
			if not cell_keys.has(neighbor_key):
				continue
			if visited.has(neighbor_key):
				continue
			visited[neighbor_key] = true
			queue.append(neighbor)
	return visited.size() == cell_keys.size()

func get_overlay_path_component_count(path_record: Dictionary) -> int:
	var cells: Array[Vector3i] = get_overlay_path_cells(path_record)
	if cells.is_empty():
		return 0
	var remaining: Dictionary = {}
	for cell in cells:
		remaining[get_internal_slot_key(cell)] = cell
	var component_count: int = 0
	while not remaining.is_empty():
		var keys: Array = remaining.keys()
		var start_key: String = String(keys[0])
		var start_cell: Vector3i = remaining[start_key]
		component_count += 1
		var queue: Array[Vector3i] = []
		queue.append(start_cell)
		remaining.erase(start_key)
		while not queue.is_empty():
			var current: Vector3i = queue.pop_front()
			for offset in get_internal_neighbor_offsets():
				var neighbor: Vector3i = current + offset
				var neighbor_key: String = get_internal_slot_key(neighbor)
				if not remaining.has(neighbor_key):
					continue
				var next_cell: Vector3i = remaining[neighbor_key]
				remaining.erase(neighbor_key)
				queue.append(next_cell)
	return component_count

func get_overlay_path_neighbor_count(path_record: Dictionary, cell: Vector3i) -> int:
	var cells: Array[Vector3i] = get_overlay_path_cells(path_record)
	var cell_keys: Dictionary = {}

	for path_cell in cells:
		cell_keys[get_internal_slot_key(path_cell)] = true

	var count: int = 0
	for offset in get_internal_neighbor_offsets():
		var neighbor: Vector3i = cell + offset
		var neighbor_key: String = get_internal_slot_key(neighbor)
		if cell_keys.has(neighbor_key):
			count += 1

	return count

func get_overlay_path_endpoint_cells(path_record: Dictionary) -> Array[Vector3i]:
	var endpoints: Array[Vector3i] = []
	var cells: Array[Vector3i] = get_overlay_path_cells(path_record)

	if cells.is_empty():
		return endpoints

	if cells.size() == 1:
		endpoints.append(cells[0])
		return endpoints

	for cell in cells:
		var neighbor_count: int = get_overlay_path_neighbor_count(path_record, cell)
		if neighbor_count == 1:
			endpoints.append(cell)

	return endpoints

func get_overlay_path_endpoint_count(path_record: Dictionary) -> int:
	return get_overlay_path_endpoint_cells(path_record).size()

func format_internal_cell(cell: Vector3i) -> String:
	return "%d,%d,%d" % [cell.x, cell.y, cell.z]

func get_overlay_path_endpoints_text(path_record: Dictionary) -> String:
	var endpoints: Array[Vector3i] = get_overlay_path_endpoint_cells(path_record)

	if endpoints.is_empty():
		return "none"

	var parts: Array[String] = []
	for cell in endpoints:
		parts.append(format_internal_cell(cell))

	return ", ".join(parts)

func is_selected_overlay_plan_connected() -> bool:
	if selected_overlay_cells.size() <= 1:
		return true
	var path_record: Dictionary = {
		"id": "planning",
		"module_id": get_selected_overlay_module_id(),
		"path_type": selected_overlay_path_type,
		"cells": selected_overlay_cells
	}
	return is_overlay_path_connected(path_record)

func get_selected_overlay_plan_component_count() -> int:
	var path_record: Dictionary = {
		"id": "planning",
		"module_id": get_selected_overlay_module_id(),
		"path_type": selected_overlay_path_type,
		"cells": selected_overlay_cells
	}
	return get_overlay_path_component_count(path_record)

func get_overlay_path_connectivity_text(path_record: Dictionary) -> String:
	var path_id: String = String(path_record.get("id", ""))
	var path_type: String = String(path_record.get("path_type", ""))
	var cells: Array[Vector3i] = get_overlay_path_cells(path_record)
	var connected: bool = is_overlay_path_connected(path_record)
	var components: int = get_overlay_path_component_count(path_record)
	var status: String = "connected" if connected else "disconnected"
	return "%s %s cells:%d %s components:%d" % [path_id, path_type, cells.size(), status, components]

func get_overlay_connectivity_preview_text() -> String:
	var lines: Array[String] = []
	lines.append("Overlay Check")
	lines.append("Planning:")
	lines.append("- Type: %s" % selected_overlay_path_type)
	lines.append("- Cells: %d" % selected_overlay_cells.size())
	lines.append("- Status: %s" % ("connected" if is_selected_overlay_plan_connected() else "disconnected"))
	lines.append("- Components: %d" % get_selected_overlay_plan_component_count())
	lines.append("")
	lines.append("Committed paths:")
	if internal_overlay_paths.is_empty():
		lines.append("none")
	else:
		for path_record in internal_overlay_paths:
			lines.append("- " + get_overlay_path_connectivity_text(path_record))
	lines.append("")
	lines.append("Rules:")
	lines.append("- Connectivity uses 6-direction orthogonal neighbors.")
	lines.append("- Overlay can pass over occupied modules.")
	lines.append("- Disconnected paths are informational only.")
	return "\n".join(lines)

func get_overlay_connectivity_compact_text() -> String:
	var disconnected_count: int = 0
	for path_record in internal_overlay_paths:
		if not is_overlay_path_connected(path_record):
			disconnected_count += 1
	var planning_status: String = "connected" if is_selected_overlay_plan_connected() else "disconnected"
	return "Overlay connectivity: planning %s / disconnected paths %d" % [planning_status, disconnected_count]

func has_internal_overlay_at_cell(cell: Vector3i, path_type: String = "") -> bool:
	var paths: Array[Dictionary] = get_internal_overlay_paths_at_cell(cell)
	if path_type.is_empty():
		return not paths.is_empty()
	for record in paths:
		if String(record.get("path_type", "")) == path_type:
			return true
	return false

func is_cell_in_selected_overlay_path(cell: Vector3i) -> bool:
	var record: Dictionary = get_selected_overlay_path_record()
	if record.is_empty():
		return false

	var cells: Array = record.get("cells", [])
	for item in cells:
		var path_cell: Vector3i = item
		if path_cell == cell:
			return true

	return false

func get_selected_overlay_path_marker_for_cell(cell: Vector3i) -> String:
	if not is_cell_in_selected_overlay_path(cell):
		return ""

	var record: Dictionary = get_selected_overlay_path_record()
	var path_type: String = String(record.get("path_type", ""))

	if path_type == "liquid":
		return "q"

	if path_type == "duct":
		return "d"

	return "?"

func get_internal_overlay_marker_for_cell(cell: Vector3i) -> String:
	if has_selected_overlay_cell(cell):
		if selected_overlay_path_type == "duct":
			return "A"
		return "L"

	var selected_marker: String = get_selected_overlay_path_marker_for_cell(cell)
	if not selected_marker.is_empty():
		return selected_marker
	if has_internal_overlay_at_cell(cell, "liquid"):
		return "l"
	if has_internal_overlay_at_cell(cell, "duct"):
		return "a"
	return ""

func get_modules_touched_by_overlay_path(path_record: Dictionary) -> Array[BipobModule]:
	var modules: Array[BipobModule] = []
	var cells: Array = path_record.get("cells", [])

	for item in cells:
		var cell: Vector3i = item
		if not is_internal_cell_in_bounds(cell):
			continue

		var module: BipobModule = get_internal_module_at_cell(cell)
		if module != null and not modules.has(module):
			modules.append(module)

	return modules

func get_modules_adjacent_to_overlay_path(path_record: Dictionary) -> Array[BipobModule]:
	var modules: Array[BipobModule] = []
	var cells: Array = path_record.get("cells", [])

	for item in cells:
		var cell: Vector3i = item
		if not is_internal_cell_in_bounds(cell):
			continue

		for offset in get_internal_neighbor_offsets():
			var neighbor_cell: Vector3i = cell + offset
			if not is_internal_cell_in_bounds(neighbor_cell):
				continue

			var module: BipobModule = get_internal_module_at_cell(neighbor_cell)
			if module != null and not modules.has(module):
				modules.append(module)

	return modules

func does_overlay_path_reach_body_edge(path_record: Dictionary) -> bool:
	var cells: Array = path_record.get("cells", [])

	for item in cells:
		var cell: Vector3i = item
		if is_internal_cell_on_body_edge(cell):
			return true

	return false

func does_overlay_path_endpoint_touch_body_edge(path_record: Dictionary) -> bool:
	var endpoints: Array[Vector3i] = get_overlay_path_endpoint_cells(path_record)

	for cell in endpoints:
		if is_internal_cell_on_body_edge(cell):
			return true

	return false

func get_modules_touched_by_overlay_endpoints(path_record: Dictionary) -> Array[BipobModule]:
	var modules: Array[BipobModule] = []
	var endpoints: Array[Vector3i] = get_overlay_path_endpoint_cells(path_record)

	for cell in endpoints:
		var module: BipobModule = get_internal_module_at_cell(cell)
		if module != null and not modules.has(module):
			modules.append(module)

	return modules

func get_modules_adjacent_to_overlay_endpoints(path_record: Dictionary) -> Array[BipobModule]:
	var modules: Array[BipobModule] = []
	var endpoints: Array[Vector3i] = get_overlay_path_endpoint_cells(path_record)

	for cell in endpoints:
		for offset in get_internal_neighbor_offsets():
			var neighbor: Vector3i = cell + offset
			if not is_internal_cell_in_bounds(neighbor):
				continue

			var module: BipobModule = get_internal_module_at_cell(neighbor)
			if module != null and not modules.has(module):
				modules.append(module)

	return modules

func does_overlay_path_touch_cooler(path_record: Dictionary) -> bool:
	var modules: Array[BipobModule] = get_modules_touched_by_overlay_path(path_record)

	for module in modules:
		if is_cooler_module(module):
			return true

	return false

func does_overlay_path_touch_radiator(path_record: Dictionary) -> bool:
	var modules: Array[BipobModule] = get_modules_touched_by_overlay_path(path_record)

	for module in modules:
		if is_radiator_module(module):
			return true

	return false

func does_overlay_path_touch_radiator_next_to_cooler(path_record: Dictionary) -> bool:
	var modules: Array[BipobModule] = get_modules_touched_by_overlay_path(path_record)

	for module in modules:
		if is_radiator_module(module) and is_radiator_next_to_cooler(module):
			return true

	return false

func is_hot_internal_module(module: BipobModule) -> bool:
	if module == null:
		return false

	return get_module_preview_heat(module, false) >= 3

func does_overlay_path_touch_hot_module(path_record: Dictionary) -> bool:
	var modules: Array[BipobModule] = get_modules_touched_by_overlay_path(path_record)

	for module in modules:
		if is_hot_internal_module(module):
			return true

	return false

func does_overlay_path_endpoint_touch_hot_module(path_record: Dictionary) -> bool:
	var modules: Array[BipobModule] = get_modules_touched_by_overlay_endpoints(path_record)

	for module in modules:
		if is_hot_internal_module(module):
			return true

	return false

func get_overlay_path_endpoint_suitability_text(path_record: Dictionary) -> String:
	var path_type: String = String(path_record.get("path_type", ""))
	var connected: bool = is_overlay_path_connected(path_record)
	var reaches_edge_endpoint: bool = does_overlay_path_endpoint_touch_body_edge(path_record)
	var touches_cooler: bool = does_overlay_path_touch_cooler(path_record)
	var touches_radiator: bool = does_overlay_path_touch_radiator(path_record)
	var touches_hot: bool = does_overlay_path_touch_hot_module(path_record)

	if path_type == "liquid":
		var has_cooling_source: bool = touches_cooler or touches_radiator
		var has_target: bool = touches_hot

		if connected and has_cooling_source and has_target:
			return "good: liquid path touches cooling source and hot module"
		if not connected:
			return "notice: liquid path is disconnected"
		if not has_cooling_source:
			return "notice: liquid path does not touch cooler/radiator"
		if not has_target:
			return "notice: liquid path does not touch hot module"
		return "ok"

	if path_type == "duct":
		if connected and reaches_edge_endpoint:
			return "good: duct has endpoint at body edge"
		if not connected:
			return "notice: duct path is disconnected"
		if not reaches_edge_endpoint:
			return "notice: duct endpoint does not reach body edge"
		return "ok"

	return "unknown path type"

func get_overlay_path_endpoint_line(path_record: Dictionary) -> String:
	var path_id: String = String(path_record.get("id", ""))
	var path_type: String = String(path_record.get("path_type", ""))
	var cells: Array[Vector3i] = get_overlay_path_cells(path_record)
	var endpoint_count: int = get_overlay_path_endpoint_count(path_record)
	var endpoint_text: String = get_overlay_path_endpoints_text(path_record)
	var suitability: String = get_overlay_path_endpoint_suitability_text(path_record)

	return "%s %s cells:%d endpoints:%d [%s] %s" % [
		path_id,
		path_type,
		cells.size(),
		endpoint_count,
		endpoint_text,
		suitability
	]

func get_overlay_endpoint_preview_text() -> String:
	var lines: Array[String] = []
	lines.append("Overlay Endpoint Preview")

	var planning_record: Dictionary = {
		"id": "planning",
		"module_id": get_selected_overlay_module_id(),
		"path_type": selected_overlay_path_type,
		"cells": selected_overlay_cells
	}

	lines.append("Planning:")
	lines.append("- " + get_overlay_path_endpoint_line(planning_record))
	lines.append("")
	lines.append("Committed paths:")

	if internal_overlay_paths.is_empty():
		lines.append("none")
	else:
		for path_record in internal_overlay_paths:
			lines.append("- " + get_overlay_path_endpoint_line(path_record))

	lines.append("")
	lines.append("Rules:")
	lines.append("- Endpoint = path cell with exactly 1 path neighbor.")
	lines.append("- Single-cell path has one endpoint.")
	lines.append("- Loop path has zero endpoints.")
	lines.append("- Liquid preview prefers cooling source + hot module.")
	lines.append("- Duct preview prefers endpoint on body edge.")
	lines.append("- Endpoint preview is informational only.")
	return "\n".join(lines)

func get_overlay_endpoint_compact_text() -> String:
	var selected_record: Dictionary = get_selected_overlay_path_record()

	if selected_record.is_empty():
		var planning_record: Dictionary = {
			"id": "planning",
			"module_id": get_selected_overlay_module_id(),
			"path_type": selected_overlay_path_type,
			"cells": selected_overlay_cells
		}
		var planning_endpoints: int = get_overlay_path_endpoint_count(planning_record)
		return "Overlay endpoints: planning %d" % planning_endpoints

	var endpoint_count: int = get_overlay_path_endpoint_count(selected_record)
	var suitability: String = get_overlay_path_endpoint_suitability_text(selected_record)
	return "Overlay endpoints: %d — %s" % [endpoint_count, suitability]

func get_overlay_path_potential_cooling_value(path_record: Dictionary) -> int:
	var path_type: String = String(path_record.get("path_type", ""))

	if path_type == "liquid":
		if does_overlay_path_touch_radiator_next_to_cooler(path_record):
			return 5
		if does_overlay_path_touch_cooler(path_record):
			return 4
		if does_overlay_path_touch_radiator(path_record):
			return 3
		return 2

	if path_type == "duct":
		if does_overlay_path_reach_body_edge(path_record):
			return 1
		return 0

	return 0

func get_liquid_overlay_paths_touching_module(module: BipobModule) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	if module == null:
		return result

	for path_record in internal_overlay_paths:
		var path_type: String = String(path_record.get("path_type", ""))
		if path_type != "liquid":
			continue

		var touched_modules: Array[BipobModule] = get_modules_touched_by_overlay_path(path_record)
		if touched_modules.has(module):
			result.append(path_record)

	return result

func get_edge_duct_overlay_paths() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for path_record in internal_overlay_paths:
		var path_type: String = String(path_record.get("path_type", ""))
		if path_type != "duct":
			continue

		if does_overlay_path_reach_body_edge(path_record):
			result.append(path_record)

	return result

func get_duct_overlay_paths_touching_or_adjacent_to_module(module: BipobModule) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	if module == null:
		return result

	for path_record in internal_overlay_paths:
		var path_type: String = String(path_record.get("path_type", ""))
		if path_type != "duct":
			continue

		var touched_modules: Array[BipobModule] = get_modules_touched_by_overlay_path(path_record)
		var adjacent_modules: Array[BipobModule] = get_modules_adjacent_to_overlay_path(path_record)

		if touched_modules.has(module) or adjacent_modules.has(module):
			result.append(path_record)

	return result

func get_liquid_overlay_potential_cooling_for_module(module: BipobModule) -> int:
	var strongest_value: int = 0

	for path_record in get_liquid_overlay_paths_touching_module(module):
		var value: int = get_overlay_path_potential_cooling_value(path_record)
		strongest_value = maxi(strongest_value, value)

	return strongest_value

func get_air_duct_overlay_potential_cooling_for_module(module: BipobModule) -> int:
	if module == null:
		return 0

	var strongest_value: int = 0

	for path_record in get_duct_overlay_paths_touching_or_adjacent_to_module(module):
		if not does_overlay_path_reach_body_edge(path_record):
			continue

		strongest_value = maxi(strongest_value, 1)

	return strongest_value

func get_overlay_potential_cooling_for_module(module: BipobModule) -> int:
	var liquid_value: int = get_liquid_overlay_potential_cooling_for_module(module)
	var duct_value: int = get_air_duct_overlay_potential_cooling_for_module(module)

	return maxi(liquid_value, duct_value)

func get_hypothetical_heat_after_overlay_for_module(module: BipobModule) -> int:
	if module == null:
		return 0

	var current_preview_heat: int = get_preview_heat_after_cooling_for_internal_module(module)
	var overlay_cooling: int = get_overlay_potential_cooling_for_module(module)

	return clampi(current_preview_heat - overlay_cooling, 0, THERMAL_CRITICAL_HEAT)

func get_overlay_thermal_contribution_line(module: BipobModule) -> String:
	if module == null:
		return ""

	var base_preview_heat: int = get_preview_heat_after_cooling_for_internal_module(module)
	var liquid_value: int = get_liquid_overlay_potential_cooling_for_module(module)
	var duct_value: int = get_air_duct_overlay_potential_cooling_for_module(module)
	var overlay_value: int = get_overlay_potential_cooling_for_module(module)
	var hypothetical_heat: int = get_hypothetical_heat_after_overlay_for_module(module)

	return "%s: base preview %d, overlay liquid -%d, duct -%d, strongest -%d, hypothetical %d" % [
		get_module_display_name(module),
		base_preview_heat,
		liquid_value,
		duct_value,
		overlay_value,
		hypothetical_heat
	]

func get_overlay_thermal_contribution_preview_text() -> String:
	var lines: Array[String] = []
	lines.append("Overlay Thermal Preview")

	var modules: Array[BipobModule] = get_unique_internal_modules()
	if modules.is_empty():
		lines.append("none")
		return "\n".join(lines)

	var any_contribution: bool = false

	for module in modules:
		if module == null:
			continue

		var contribution: int = get_overlay_potential_cooling_for_module(module)
		if contribution <= 0:
			continue

		any_contribution = true
		lines.append("- " + get_overlay_thermal_contribution_line(module))

	if not any_contribution:
		lines.append("none")

	lines.append("")
	lines.append("Rules:")
	lines.append("- Overlay contribution is hypothetical only.")
	lines.append("- Base thermal heat map is not changed.")
	lines.append("- Strongest overlay contribution is used, not stacking.")
	lines.append("- Liquid path must touch module.")
	lines.append("- Duct path must touch/neighbor module and reach body edge.")
	lines.append("- " + get_overlay_thermal_contribution_diff_summary_text())

	return "\n".join(lines)


func get_overlay_thermal_contribution_diff_summary_text() -> String:
	var improved_count: int = 0
	var unchanged_count: int = 0
	var total_delta: int = 0
	var best_delta: int = 0

	for module in get_unique_internal_modules():
		if module == null:
			continue

		var base_preview_heat: int = get_preview_heat_after_cooling_for_internal_module(module)
		var hypothetical_heat: int = get_hypothetical_heat_after_overlay_for_module(module)
		var delta: int = base_preview_heat - hypothetical_heat
		if delta > 0:
			improved_count += 1
			total_delta += delta
			best_delta = maxi(best_delta, delta)
		else:
			unchanged_count += 1

	return "Overlay Diff: changed %d / best -%d" % [
		improved_count,
		best_delta
	]

func get_overlay_thermal_contribution_compact_text() -> String:
	var affected_count: int = 0
	var highest_contribution: int = 0

	for module in get_unique_internal_modules():
		var contribution: int = get_overlay_potential_cooling_for_module(module)
		if contribution > 0:
			affected_count += 1
			highest_contribution = maxi(highest_contribution, contribution)

	return "Overlay Thermal: affected %d / max potential -%d | %s" % [
		affected_count,
		highest_contribution,
		get_overlay_thermal_contribution_diff_summary_text()
	]

func get_thermal_rules_reference_text() -> String:
	var lines: Array[String] = []

	lines.append("Thermal Rules Reference")
	lines.append("")
	lines.append("Heat scale:")
	lines.append("- 1 = low heat")
	lines.append("- 2 = moderate heat")
	lines.append("- 3 = hot")
	lines.append("- 4 = very hot")
	lines.append("- 5 = critical preview")
	lines.append("")
	lines.append("Device heat:")
	lines.append("- Processor: idle 3 / active 5")
	lines.append("- GPU / vision processor: idle 3 / active 5")
	lines.append("- Memory: 1")
	lines.append("- Hard Drive: 1")
	lines.append("- Power Block: idle 3 / active 5")
	lines.append("- Interfaces: 1")
	lines.append("- Batteries: 1")
	lines.append("")
	lines.append("Neighbor heat:")
	lines.append("- Neighbor heat = source heat - 1")
	lines.append("- Final base preview uses strongest heat, not stacking")
	lines.append("")
	lines.append("Direct cooling:")
	lines.append("- Cooler cools adjacent modules by 2")
	lines.append("- Radiator cools adjacent modules by 2")
	lines.append("- Radiator near Cooler cools by 4")
	lines.append("- Radiator against body cools by 3")
	lines.append("")
	lines.append("Overlay paths:")
	lines.append("- Water Tube does not consume internal volume")
	lines.append("- Water Tube base potential cooling: 2")
	lines.append("- Water Tube through Cooler: 4")
	lines.append("- Water Tube through Radiator: 3")
	lines.append("- Water Tube through Radiator near Cooler: 5")
	lines.append("- Air Duct does not consume internal volume")
	lines.append("- Air Duct supports air route/exhaust to body edge")
	lines.append("")
	lines.append("Air intake:")
	lines.append("- Air cooling requires Air Intake Node on external body")
	lines.append("- Liquid cooling does not require Air Intake Node")
	lines.append("")
	lines.append("Current implementation:")
	lines.append("- Base thermal preview is informational")
	lines.append("- Overlay contribution is hypothetical only")
	lines.append("- Thermal+Overlay view does not affect gameplay")
	lines.append("- No device damage or repair is implemented yet")
	lines.append("- No Test Build is implemented yet")

	return "\n".join(lines)

func get_thermal_rules_compact_text() -> String:
	return "Thermal Rules: heat 1-5, critical 5, overlay hypothetical"

func get_overlay_path_effect_line(path_record: Dictionary) -> String:
	var path_id: String = String(path_record.get("id", ""))
	var path_type: String = String(path_record.get("path_type", ""))
	var cells: Array = path_record.get("cells", [])

	var touched: Array[BipobModule] = get_modules_touched_by_overlay_path(path_record)
	var adjacent: Array[BipobModule] = get_modules_adjacent_to_overlay_path(path_record)
	var reaches_edge: bool = does_overlay_path_reach_body_edge(path_record)
	var potential_value: int = get_overlay_path_potential_cooling_value(path_record)

	var touched_names: Array[String] = []
	for module in touched:
		touched_names.append(get_module_display_name(module))

	var adjacent_names: Array[String] = []
	for module in adjacent:
		if not touched.has(module):
			adjacent_names.append(get_module_display_name(module))

	var touched_text: String = "none" if touched_names.is_empty() else ", ".join(touched_names)
	var adjacent_text: String = "none" if adjacent_names.is_empty() else ", ".join(adjacent_names)
	var edge_text: String = "yes" if reaches_edge else "no"

	if path_type == "liquid":
		return "%s liquid cells:%d potential:%d touched:%s adjacent:%s" % [
			path_id,
			cells.size(),
			potential_value,
			touched_text,
			adjacent_text
		]

	if path_type == "duct":
		return "%s duct cells:%d edge:%s support:%d touched:%s adjacent:%s" % [
			path_id,
			cells.size(),
			edge_text,
			potential_value,
			touched_text,
			adjacent_text
		]

	return "%s %s cells:%d touched:%s adjacent:%s" % [
		path_id,
		path_type,
		cells.size(),
		touched_text,
		adjacent_text
	]

func get_overlay_effect_preview_text() -> String:
	var lines: Array[String] = []

	lines.append("Overlay effect preview:")

	if internal_overlay_paths.is_empty():
		lines.append("none")
	else:
		for path_record in internal_overlay_paths:
			lines.append("- " + get_overlay_path_effect_line(path_record))

	lines.append("")
	lines.append("Rules preview:")
	lines.append("- Water Tube base potential cooling: 2")
	lines.append("- Water Tube through Cooler: 4")
	lines.append("- Water Tube through Radiator: 3")
	lines.append("- Water Tube through Radiator near Cooler: 5")
	lines.append("- Air Duct reaching body edge can support air routing")
	lines.append("- Overlay effects are not applied to thermal calculation yet")

	return "\n".join(lines)

func get_overlay_effect_compact_text() -> String:
	var liquid_count: int = 0
	var duct_count: int = 0
	var edge_duct_count: int = 0

	for path_record in internal_overlay_paths:
		var path_type: String = String(path_record.get("path_type", ""))
		if path_type == "liquid":
			liquid_count += 1
		elif path_type == "duct":
			duct_count += 1
			if does_overlay_path_reach_body_edge(path_record):
				edge_duct_count += 1

	return "Overlay effects: liquid %d / duct %d / edge ducts %d" % [
		liquid_count,
		duct_count,
		edge_duct_count
	]

func get_internal_overlay_summary_text() -> String:
	var lines: Array[String] = []
	lines.append("Overlay paths:")
	if internal_overlay_paths.is_empty():
		lines.append("none")
	else:
		for record in internal_overlay_paths:
			var path_id: String = String(record.get("id", ""))
			var module_id: String = String(record.get("module_id", ""))
			var path_type: String = String(record.get("path_type", ""))
			var cells: Array = record.get("cells", [])
			lines.append("- %s %s cells:%d module:%s" % [path_id, path_type, cells.size(), module_id])
	lines.append("")
	lines.append("Planning:")
	lines.append("- Type: %s" % selected_overlay_path_type)
	lines.append("- Selected cells: %d" % selected_overlay_cells.size())
	lines.append("- Uses module: %s" % get_selected_overlay_module_id())
	lines.append("- Connectivity: %s" % ("connected" if is_selected_overlay_plan_connected() else "disconnected"))
	lines.append("- Components: %d" % get_selected_overlay_plan_component_count())
	lines.append("- Overlay can pass over occupied modules.")
	lines.append("- Route cooling is not applied yet.")
	lines.append("- Disconnected paths are informational only.")
	return "\n".join(lines)

func get_selected_overlay_path_details_text() -> String:
	var record: Dictionary = get_selected_overlay_path_record()

	if record.is_empty():
		return "Selected overlay:\nnone"

	var path_id: String = String(record.get("id", ""))
	var module_id: String = String(record.get("module_id", ""))
	var path_type: String = String(record.get("path_type", ""))
	var cells: Array[Vector3i] = get_overlay_path_cells(record)
	var connected: bool = is_overlay_path_connected(record)
	var components: int = get_overlay_path_component_count(record)
	var reaches_edge: bool = does_overlay_path_reach_body_edge(record)
	var potential_value: int = get_overlay_path_potential_cooling_value(record)
	var endpoint_count: int = get_overlay_path_endpoint_count(record)
	var endpoint_text: String = get_overlay_path_endpoints_text(record)
	var suitability: String = get_overlay_path_endpoint_suitability_text(record)

	var edge_text: String = "yes" if reaches_edge else "no"
	var connected_text: String = "yes" if connected else "no"

	var lines: Array[String] = []
	lines.append("Selected overlay:")
	lines.append("- ID: %s" % path_id)
	lines.append("- Type: %s" % path_type)
	lines.append("- Module: %s" % module_id)
	lines.append("- Cells: %d" % cells.size())
	lines.append("- Connected: %s" % connected_text)
	lines.append("- Components: %d" % components)
	lines.append("- Reaches body edge: %s" % edge_text)
	lines.append("- Potential value: %d" % potential_value)
	lines.append("- Endpoints: %d" % endpoint_count)
	lines.append("- Endpoint cells: %s" % endpoint_text)
	lines.append("- Suitability: %s" % suitability)
	lines.append("- Preview only: yes")

	return "\n".join(lines)

func get_internal_module_at_cell(cell: Vector3i) -> BipobModule:
	var key := get_internal_slot_key(cell)
	if internal_modules_by_cell.has(key):
		return internal_modules_by_cell[key]
	return null

func get_internal_module_base_size(module: BipobModule) -> Vector3i:
	if module == null:
		return Vector3i.ONE
	return Vector3i(maxi(module.size_x, 1), maxi(module.size_y, 1), maxi(module.size_z, 1))

func get_rotated_internal_size(module: BipobModule, rotation_index: int) -> Vector3i:
	var base_size := get_internal_module_base_size(module)
	match posmod(rotation_index, 3):
		1:
			return Vector3i(base_size.z, base_size.y, base_size.x)
		2:
			return Vector3i(base_size.x, base_size.z, base_size.y)
		_:
			return base_size

func get_internal_module_covered_cells(module: BipobModule, origin: Vector3i, rotation_index: int = 0) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	var module_size := get_rotated_internal_size(module, rotation_index)
	for z in range(module_size.z):
		for y in range(module_size.y):
			for x in range(module_size.x):
				cells.append(origin + Vector3i(x, y, z))
	return cells

func get_internal_module_placement_error(module: BipobModule, origin: Vector3i, rotation_index: int = 0) -> String:
	if module == null:
		return "No internal module selected."
	if module.placement_type != "internal":
		return "Module is not internal."
	for cell in get_internal_module_covered_cells(module, origin, rotation_index):
		if not is_internal_cell_in_bounds(cell):
			return "Internal module footprint is outside robot volume."
		if get_internal_module_at_cell(cell) != null:
			return "Internal cells are occupied."
	return ""

func can_place_internal_module(module: BipobModule, origin: Vector3i, rotation_index: int = 0) -> bool:
	return get_internal_module_placement_error(module, origin, rotation_index).is_empty()

func place_internal_module(module: BipobModule, origin: Vector3i, rotation_index: int = 0) -> bool:
	if not can_place_internal_module(module, origin, rotation_index):
		hint_requested.emit("Cannot place internal module here.")
		status_changed.emit()
		return false
	var rotated_size := get_rotated_internal_size(module, rotation_index)
	var record := {
		"module": module,
		"origin": origin,
		"size": rotated_size,
		"rotation": posmod(rotation_index, 3),
	}
	placed_internal_modules.append(record)
	for cell in get_internal_module_covered_cells(module, origin, rotation_index):
		internal_modules_by_cell[get_internal_slot_key(cell)] = module
	var storage_index := box_storage.find(module)
	if storage_index != -1:
		box_storage.remove_at(storage_index)
	hint_requested.emit("Internal module installed: %s" % get_module_display_name(module))
	status_changed.emit()
	return true

func find_internal_module_record_at_cell(cell: Vector3i) -> int:
	for index in range(placed_internal_modules.size()):
		var record: Dictionary = placed_internal_modules[index]
		var record_module: BipobModule = record.get("module", null)
		var origin: Vector3i = record.get("origin", Vector3i.ZERO)
		var rotation_index: int = int(record.get("rotation", 0))
		if get_internal_module_covered_cells(record_module, origin, rotation_index).has(cell):
			return index
	return -1

func remove_internal_module(cell: Vector3i) -> bool:
	if not is_internal_cell_in_bounds(cell):
		hint_requested.emit("Internal cell is out of bounds.")
		status_changed.emit()
		return false
	var index := find_internal_module_record_at_cell(cell)
	if index == -1:
		hint_requested.emit("No internal module at selected cell.")
		status_changed.emit()
		return false
	var record: Dictionary = placed_internal_modules[index]
	var module: BipobModule = record.get("module", null)
	var origin: Vector3i = record.get("origin", Vector3i.ZERO)
	var rotation_index: int = int(record.get("rotation", 0))
	for covered_cell in get_internal_module_covered_cells(module, origin, rotation_index):
		internal_modules_by_cell.erase(get_internal_slot_key(covered_cell))
	placed_internal_modules.remove_at(index)
	if module != null and not box_storage.has(module):
		box_storage.append(module)
	hint_requested.emit("Internal module removed to Box: %s" % get_module_display_name(module))
	status_changed.emit()
	return true


func get_cells_for_internal_module(module: BipobModule) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	if module == null:
		return cells

	for record_variant in placed_internal_modules:
		if typeof(record_variant) != TYPE_DICTIONARY:
			continue
		var record: Dictionary = record_variant
		var record_module: BipobModule = record.get("module", null)
		if record_module != module:
			continue
		var origin: Vector3i = record.get("origin", Vector3i.ZERO)
		var rotation_index: int = int(record.get("rotation", 0))
		for covered_cell in get_internal_module_covered_cells(module, origin, rotation_index):
			if not cells.has(covered_cell):
				cells.append(covered_cell)

	if not cells.is_empty():
		return cells

	for key_variant in internal_modules_by_cell.keys():
		var key := String(key_variant)
		var cell_module: BipobModule = internal_modules_by_cell.get(key, null)
		if cell_module != module:
			continue
		var parts := key.split(":")
		if parts.size() != 3:
			continue
		var cell := Vector3i(int(parts[0]), int(parts[1]), int(parts[2]))
		if not cells.has(cell):
			cells.append(cell)

	return cells

func get_internal_neighbor_offsets() -> Array[Vector3i]:
	return [
		Vector3i(1, 0, 0),
		Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0),
		Vector3i(0, -1, 0),
		Vector3i(0, 0, 1),
		Vector3i(0, 0, -1),
	]

func get_module_preview_heat(module: BipobModule, active_mode: bool = false) -> int:
	if module == null:
		return 0
	var heat_value: int = module.heat_active if active_mode else module.heat_idle
	return clampi(heat_value, 0, THERMAL_CRITICAL_HEAT)

func get_neighbor_heat_for_internal_module(module: BipobModule) -> int:
	if module == null:
		return 0
	var strongest_neighbor_heat: int = 0
	var own_cells: Array[Vector3i] = get_cells_for_internal_module(module)
	for cell in own_cells:
		for offset in get_internal_neighbor_offsets():
			var neighbor_cell: Vector3i = cell + offset
			if not is_internal_cell_in_bounds(neighbor_cell):
				continue
			var neighbor_module: BipobModule = get_internal_module_at_cell(neighbor_cell)
			if neighbor_module == null or neighbor_module == module:
				continue
			var neighbor_heat: int = maxi(0, get_module_preview_heat(neighbor_module, false) - 1)
			strongest_neighbor_heat = maxi(strongest_neighbor_heat, neighbor_heat)
	return strongest_neighbor_heat

func get_preview_heat_for_internal_module(module: BipobModule) -> int:
	if module == null:
		return 0
	var base_heat: int = get_module_preview_heat(module, false)
	var neighbor_heat: int = get_neighbor_heat_for_internal_module(module)
	return maxi(base_heat, neighbor_heat)

func is_internal_module_against_body(module: BipobModule) -> bool:
	if module == null:
		return false
	var volume_size: Vector3i = get_internal_volume_size()
	var cells: Array[Vector3i] = get_cells_for_internal_module(module)
	for cell in cells:
		if cell.x == 0 or cell.y == 0 or cell.z == 0:
			return true
		if cell.x == volume_size.x - 1 or cell.y == volume_size.y - 1 or cell.z == volume_size.z - 1:
			return true
	return false

func is_cooler_module(module: BipobModule) -> bool:
	return module != null and module.id == "cooler_v1"

func is_radiator_module(module: BipobModule) -> bool:
	return module != null and module.id == "radiator_v1"

func is_radiator_next_to_cooler(radiator_module: BipobModule) -> bool:
	if not is_radiator_module(radiator_module):
		return false
	var cells: Array[Vector3i] = get_cells_for_internal_module(radiator_module)
	for cell in cells:
		for offset in get_internal_neighbor_offsets():
			var neighbor_cell: Vector3i = cell + offset
			if not is_internal_cell_in_bounds(neighbor_cell):
				continue
			var neighbor_module: BipobModule = get_internal_module_at_cell(neighbor_cell)
			if is_cooler_module(neighbor_module):
				return true
	return false

func get_cooling_power_for_internal_module(cooling_module: BipobModule) -> int:
	if cooling_module == null:
		return 0
	if is_cooler_module(cooling_module):
		return 2
	if is_radiator_module(cooling_module):
		if is_radiator_next_to_cooler(cooling_module):
			return 4
		if is_internal_module_against_body(cooling_module):
			return 3
		return 2
	return max(0, cooling_module.cooling_power)

func get_cooling_received_by_internal_module(module: BipobModule) -> int:
	if module == null:
		return 0
	var strongest_cooling: int = 0
	var own_cells: Array[Vector3i] = get_cells_for_internal_module(module)
	for cell in own_cells:
		for offset in get_internal_neighbor_offsets():
			var neighbor_cell: Vector3i = cell + offset
			if not is_internal_cell_in_bounds(neighbor_cell):
				continue
			var neighbor_module: BipobModule = get_internal_module_at_cell(neighbor_cell)
			if neighbor_module == null or neighbor_module == module:
				continue
			if is_cooling_module(neighbor_module):
				strongest_cooling = maxi(strongest_cooling, get_cooling_power_for_internal_module(neighbor_module))
	return strongest_cooling

func get_preview_heat_after_cooling_for_internal_module(module: BipobModule) -> int:
	var raw_heat: int = get_preview_heat_for_internal_module(module)
	var cooling_received: int = get_cooling_received_by_internal_module(module)
	return clampi(raw_heat - cooling_received, 0, THERMAL_CRITICAL_HEAT)

func get_internal_module_thermal_line(module: BipobModule) -> String:
	if module == null:
		return ""
	var base_heat: int = get_module_preview_heat(module, false)
	var neighbor_heat: int = get_neighbor_heat_for_internal_module(module)
	var cooling_received: int = get_cooling_received_by_internal_module(module)
	var final_heat: int = get_preview_heat_after_cooling_for_internal_module(module)
	return "%s: base %d, neighbor %d, cooling -%d, preview %d" % [
		get_module_display_name(module),
		base_heat,
		neighbor_heat,
		cooling_received,
		final_heat,
	]

func get_internal_thermal_preview_text() -> String:
	var lines: Array[String] = []
	lines.append("Thermal preview:")
	lines.append("Critical heat: %d" % THERMAL_CRITICAL_HEAT)
	var modules: Array[BipobModule] = get_unique_internal_modules()
	if modules.is_empty():
		lines.append("none")
		return "\n".join(lines)
	for module in modules:
		if module == null:
			continue
		lines.append("- " + get_internal_module_thermal_line(module))
	lines.append("")
	lines.append("Rules:")
	lines.append("- neighbor heat = source heat - 1")
	lines.append("- final heat uses strongest heat/cooling only")
	lines.append("- critical heat 5 is informational for now")
	if has_air_cooling_requiring_intake() and not has_external_air_intake():
		lines.append("")
		lines.append("Warning: Air cooling requires Air Intake Node on external body.")
	return "\n".join(lines)

func get_highest_internal_preview_heat() -> int:
	var highest_heat: int = 0
	for module in get_unique_internal_modules():
		highest_heat = maxi(highest_heat, get_preview_heat_after_cooling_for_internal_module(module))
	return highest_heat

func get_critical_internal_preview_count() -> int:
	var count: int = 0
	for module in get_unique_internal_modules():
		if get_preview_heat_after_cooling_for_internal_module(module) >= THERMAL_CRITICAL_HEAT:
			count += 1
	return count

func get_unique_internal_modules() -> Array[BipobModule]:
	var unique_modules: Array[BipobModule] = []
	for record in placed_internal_modules:
		if typeof(record) != TYPE_DICTIONARY:
			continue
		var module: BipobModule = record.get("module", null)
		if module == null:
			continue
		if unique_modules.has(module):
			continue
		unique_modules.append(module)
	return unique_modules

func get_unique_external_modules() -> Array[BipobModule]:
	var unique_modules: Array[BipobModule] = []
	for module_variant in external_modules_by_slot.values():
		if module_variant == null:
			continue
		var module: BipobModule = module_variant
		if unique_modules.has(module):
			continue
		unique_modules.append(module)
	return unique_modules

func get_all_constructor_modules() -> Array[BipobModule]:
	var modules: Array[BipobModule] = []

	for module in box_storage:
		if module != null and not modules.has(module):
			modules.append(module)

	for module in get_unique_external_modules():
		if module != null and not modules.has(module):
			modules.append(module)

	for module in get_unique_internal_modules():
		if module != null and not modules.has(module):
			modules.append(module)

	return modules

func get_allowed_constructor_placement_types() -> Array[String]:
	return ["internal", "external", "none"]

func get_allowed_constructor_categories() -> Array[String]:
	return [
		"external",
		"internal",
		"power",
		"cooling",
		"data",
		"locomotion",
		"vision",
		"storage",
		"utility"
	]

func get_allowed_cooling_types() -> Array[String]:
	return ["none", "air", "passive", "liquid", "duct"]

func get_allowed_repair_categories() -> Array[String]:
	return ["standard", "electronics", "power", "cooling", "mechanical", "interface"]

func get_repair_category_display_name(category_id: String) -> String:
	match category_id:
		"standard":
			return "Standard"
		"electronics":
			return "Electronics"
		"power":
			return "Power"
		"cooling":
			return "Cooling"
		"mechanical":
			return "Mechanical"
		"interface":
			return "Interface"
		_:
			return category_id

func get_module_damage_threshold(module: BipobModule) -> int:
	if module == null:
		return 5
	return clampi(module.damage_threshold_heat, 1, 5)

func get_module_repair_metadata_text(module: BipobModule) -> String:
	if module == null:
		return "Repair: none"
	if not module.can_be_damaged:
		return "Repair: not damageable"
	return "Repair: threshold heat %d / complexity %d / category %s" % [
		get_module_damage_threshold(module),
		module.repair_complexity,
		get_repair_category_display_name(module.repair_category)
	]

func get_module_damage_risk_preview_text(module: BipobModule) -> String:
	if module == null:
		return "Damage risk: none"
	if not module.can_be_damaged:
		return "Damage risk: not damageable"
	var preview_heat: int = get_preview_heat_after_cooling_for_internal_module(module)
	var threshold: int = get_module_damage_threshold(module)
	if preview_heat >= threshold:
		return "Damage risk: critical preview"
	if preview_heat == threshold - 1:
		return "Damage risk: warning preview"
	return "Damage risk: low preview"

func get_module_overlay_damage_risk_preview_text(module: BipobModule) -> String:
	if module == null:
		return "Overlay damage risk: none"
	if not module.can_be_damaged:
		return "Overlay damage risk: not damageable"
	var overlay_heat: int = get_hypothetical_heat_after_overlay_for_module(module)
	var threshold: int = get_module_damage_threshold(module)
	if overlay_heat >= threshold:
		return "Overlay damage risk: critical preview"
	if overlay_heat == threshold - 1:
		return "Overlay damage risk: warning preview"
	return "Overlay damage risk: low preview"

func get_constructor_consistency_issue_lines() -> Array[String]:
	var issues: Array[String] = []
	var modules: Array[BipobModule] = get_all_constructor_modules()

	for module in modules:
		if module == null:
			continue

		var module_label: String = get_module_display_name(module)
		if module_label.is_empty():
			module_label = "<unnamed>"

		var module_id: String = module.id
		if module_id.is_empty():
			issues.append("%s has missing id." % module_label)

		if module.display_name.is_empty():
			issues.append("%s has missing display_name." % module_id)

		if module.placement_type.is_empty():
			issues.append("%s has missing placement_type." % module_label)
		elif not get_allowed_constructor_placement_types().has(module.placement_type):
			issues.append("%s has unknown placement_type: %s." % [module_label, module.placement_type])

		var category: String = get_module_category(module)
		if category.is_empty():
			issues.append("%s has missing category." % module_label)
		elif not get_allowed_constructor_categories().has(category):
			issues.append("%s has unknown category: %s." % [module_label, category])

		if module.placement_type == "internal":
			if module.internal_role.is_empty():
				issues.append("%s is internal but has no internal_role." % module_label)
			elif module.internal_role == "none" and not is_internal_overlay_module(module):
				issues.append("%s is internal but has no internal_role." % module_label)

			var internal_size: Vector3i = get_internal_module_base_size(module)
			if internal_size.x <= 0 or internal_size.y <= 0 or internal_size.z <= 0:
				issues.append("%s has invalid internal size: %s." % [module_label, str(internal_size)])

		if module.placement_type == "external":
			var footprint_size: Vector2i = get_external_module_size(module)
			if footprint_size.x <= 0 or footprint_size.y <= 0:
				issues.append("%s has invalid external footprint: %s." % [module_label, str(footprint_size)])

		if not get_allowed_cooling_types().has(module.cooling_type):
			issues.append("%s has unknown cooling_type: %s." % [module_label, module.cooling_type])

		if module.heat_idle < 0 or module.heat_idle > 5:
			issues.append("%s has heat_idle outside 0..5: %d." % [module_label, module.heat_idle])

		if module.heat_active < 0 or module.heat_active > 5:
			issues.append("%s has heat_active outside 0..5: %d." % [module_label, module.heat_active])

		if module.heat_active < module.heat_idle:
			issues.append("%s has heat_active lower than heat_idle." % module_label)

		if module.internal_role == "cooling":
			if module.id != "air_duct_v1" and module.id != "air_intake_v1":
				if module.cooling_power <= 0:
					issues.append("%s is cooling module but has cooling_power <= 0." % module_label)

		if module.requires_air_intake:
			if module.cooling_type != "air" and module.cooling_type != "duct":
				issues.append("%s requires air intake but cooling_type is %s." % [module_label, module.cooling_type])

		if module.damage_threshold_heat < 1 or module.damage_threshold_heat > 5:
			issues.append("%s has damage_threshold_heat outside 1..5: %d." % [module_label, module.damage_threshold_heat])

		if module.repair_complexity < 0:
			issues.append("%s has repair_complexity < 0: %d." % [module_label, module.repair_complexity])

		if not get_allowed_repair_categories().has(module.repair_category):
			issues.append("%s has unknown repair_category: %s." % [module_label, module.repair_category])

		if module.can_be_damaged and module.damage_threshold_heat <= 0:
			issues.append("%s can be damaged but damage_threshold_heat <= 0." % module_label)

		if module.can_be_damaged and module.repair_complexity <= 0:
			issues.append("%s can be damaged but repair_complexity <= 0." % module_label)

	_append_duplicate_constructor_metadata_issues(issues, modules)
	return issues

func _append_duplicate_constructor_metadata_issues(issues: Array[String], modules: Array[BipobModule]) -> void:
	var first_by_id: Dictionary = {}
	for module in modules:
		if module == null:
			continue
		var module_id: String = module.id
		if module_id.is_empty():
			continue
		if not first_by_id.has(module_id):
			first_by_id[module_id] = module
			continue
		var first_module: BipobModule = first_by_id[module_id]
		_compare_constructor_metadata_field(issues, module_id, "display_name", first_module.display_name, module.display_name)
		_compare_constructor_metadata_field(issues, module_id, "placement_type", first_module.placement_type, module.placement_type)
		_compare_constructor_metadata_field(issues, module_id, "category", get_module_category(first_module), get_module_category(module))
		_compare_constructor_metadata_field(issues, module_id, "internal_role", first_module.internal_role, module.internal_role)
		_compare_constructor_metadata_field(issues, module_id, "heat_idle", str(first_module.heat_idle), str(module.heat_idle))
		_compare_constructor_metadata_field(issues, module_id, "heat_active", str(first_module.heat_active), str(module.heat_active))
		_compare_constructor_metadata_field(issues, module_id, "cooling_type", first_module.cooling_type, module.cooling_type)
		_compare_constructor_metadata_field(issues, module_id, "cooling_power", str(first_module.cooling_power), str(module.cooling_power))
		_compare_constructor_metadata_field(issues, module_id, "requires_air_intake", str(first_module.requires_air_intake), str(module.requires_air_intake))
		_compare_constructor_metadata_field(issues, module_id, "can_be_damaged", str(first_module.can_be_damaged), str(module.can_be_damaged))
		_compare_constructor_metadata_field(issues, module_id, "damage_threshold_heat", str(first_module.damage_threshold_heat), str(module.damage_threshold_heat))
		_compare_constructor_metadata_field(issues, module_id, "repair_complexity", str(first_module.repair_complexity), str(module.repair_complexity))
		_compare_constructor_metadata_field(issues, module_id, "repair_category", first_module.repair_category, module.repair_category)

func _compare_constructor_metadata_field(
	issues: Array[String],
	module_id: String,
	field_name: String,
	first_value: String,
	next_value: String
) -> void:
	if first_value != next_value:
		issues.append("Duplicate metadata mismatch for %s: %s differs (%s vs %s)." % [module_id, field_name, first_value, next_value])

func get_box_module_count_by_id(module_id: String) -> int:
	var count: int = 0
	for module in box_storage:
		if module != null and module.id == module_id:
			count += 1
	return count

func get_external_module_count_by_id(module_id: String) -> int:
	var count: int = 0
	for module in get_unique_external_modules():
		if module != null and module.id == module_id:
			count += 1
	return count

func get_internal_module_count_by_id(module_id: String) -> int:
	var count: int = 0
	for module in get_unique_internal_modules():
		if module != null and module.id == module_id:
			count += 1
	return count

func get_overlay_path_count_by_module_id(module_id: String) -> int:
	var count: int = 0
	for record in internal_overlay_paths:
		var record_module_id: String = String(record.get("module_id", ""))
		if record_module_id == module_id:
			count += 1
	return count

func get_liquid_overlay_path_count() -> int:
	return get_overlay_path_count_by_module_id("water_tube_v1")

func get_duct_overlay_path_count() -> int:
	return get_overlay_path_count_by_module_id("air_duct_v1")

func get_total_module_count_by_id(module_id: String) -> int:
	return get_box_module_count_by_id(module_id) + get_external_module_count_by_id(module_id) + get_internal_module_count_by_id(module_id)

func has_internal_role(role_id: String) -> bool:
	return count_internal_role(role_id) > 0

func count_internal_role(role_id: String) -> int:
	if role_id.is_empty():
		return 0
	var count: int = 0
	for module in get_unique_internal_modules():
		if module != null and module.internal_role == role_id:
			count += 1
	return count

func get_internal_modules_by_role(role_id: String) -> Array[BipobModule]:
	var modules_by_role: Array[BipobModule] = []
	if role_id.is_empty():
		return modules_by_role
	for module in get_unique_internal_modules():
		if module == null:
			continue
		if module.internal_role == role_id:
			modules_by_role.append(module)
	return modules_by_role

func has_power_source() -> bool:
	return has_internal_role("battery")

func has_power_block() -> bool:
	return has_internal_role("power_block")

func has_internal_interface() -> bool:
	return has_internal_role("internal_interface")

func has_external_interface_bridge() -> bool:
	return has_internal_role("external_interface")

func is_virtual_power_available() -> bool:
	return has_power_source() and has_power_block()

func is_internal_data_network_available() -> bool:
	return has_internal_interface()

func is_external_data_network_available() -> bool:
	return has_internal_interface() and has_external_interface_bridge()

func get_status_word(value: bool) -> String:
	return "available" if value else "unavailable"

func get_thermal_status_word() -> String:
	var critical_count: int = get_critical_internal_preview_count()
	if critical_count > 0:
		return "critical preview"
	if get_highest_internal_preview_heat() >= 4:
		return "warning"
	return "ok"

func get_air_intake_readiness_word() -> String:
	if not has_air_cooling_requiring_intake():
		return "not required"
	if has_external_air_intake():
		return "installed"
	return "missing"

func get_warning_count() -> int:
	return get_constructor_warning_lines().size()


func get_installed_external_summary_text() -> String:
	var lines: Array[String] = []
	lines.append("Installed external:")

	var modules: Array[BipobModule] = get_unique_external_modules()
	if modules.is_empty():
		lines.append("none")
		return "\n".join(lines)

	for module in modules:
		if module == null:
			continue
		lines.append("- %s" % get_module_display_name(module))

	return "\n".join(lines)

func get_installed_internal_summary_text() -> String:
	var lines: Array[String] = []
	lines.append("Installed internal:")

	var modules: Array[BipobModule] = get_unique_internal_modules()
	if modules.is_empty():
		lines.append("none")
		return "\n".join(lines)

	for module in modules:
		if module == null:
			continue

		var role_text: String = ""
		if not module.internal_role.is_empty():
			role_text = " (%s)" % module.internal_role

		lines.append("- %s%s" % [
			get_module_display_name(module),
			role_text
		])

	return "\n".join(lines)

func get_storage_overview_text() -> String:
	var lines: Array[String] = []
	lines.append("Storage overview:")
	lines.append("- Box Storage: %d" % box_storage.size())
	lines.append("- External installed: %d" % get_unique_external_modules().size())
	lines.append("- Internal installed: %d" % get_unique_internal_modules().size())
	lines.append("- Overlay paths: %d" % internal_overlay_paths.size())
	lines.append("- Liquid paths: %d" % get_liquid_overlay_path_count())
	lines.append("- Duct paths: %d" % get_duct_overlay_path_count())

	var warnings_count: int = 0
	if has_method("get_warning_count"):
		warnings_count = get_warning_count()
	else:
		warnings_count = get_constructor_warning_lines().size()

	lines.append("- Warnings: %d" % warnings_count)
	return "\n".join(lines)

func get_constructor_dashboard_text() -> String:
	var lines: Array[String] = []

	lines.append("Constructor Dashboard")
	lines.append("")

	lines.append(get_constructor_readiness_summary_text())
	lines.append("")

	lines.append(get_constructor_warning_summary_text())
	lines.append("")

	lines.append(get_storage_overview_text())
	lines.append(get_constructor_planning_checkpoint_compact_text())
	lines.append("")

	var thermal_critical_heat: int = THERMAL_CRITICAL_HEAT
	lines.append("Thermal:")
	lines.append("- Highest heat: %d / %d" % [
		get_highest_internal_preview_heat(),
		thermal_critical_heat
	])
	lines.append("- Critical preview: %d" % get_critical_internal_preview_count())
	lines.append("- Air intake: %s" % get_air_intake_readiness_word())
	lines.append("")

	lines.append(get_installed_external_summary_text())
	lines.append("")

	lines.append(get_installed_internal_summary_text())

	return "\n".join(lines)

func get_constructor_planning_checkpoint_text() -> String:
	var lines: Array[String] = []

	lines.append("Constructor Planning Checkpoint")
	lines.append("")
	lines.append("Systems:")

	var internal_count: int = get_unique_internal_modules().size()
	var external_count: int = get_unique_external_modules().size()
	var overlay_count: int = internal_overlay_paths.size()
	var liquid_count: int = get_liquid_overlay_path_count() if has_method("get_liquid_overlay_path_count") else 0
	var duct_count: int = get_duct_overlay_path_count() if has_method("get_duct_overlay_path_count") else 0

	lines.append("- Box Storage: %d module(s)" % box_storage.size())
	lines.append("- Internal Volume: %d installed module(s)" % internal_count)
	lines.append("- External Slots: %d installed module(s)" % external_count)
	lines.append("- Overlay Paths: %d total / %d liquid / %d duct" % [
		overlay_count,
		liquid_count,
		duct_count
	])

	lines.append("")
	lines.append("Thermal:")
	lines.append("- Highest Thermal Preview: %d / %d" % [
		get_highest_internal_preview_heat(),
		THERMAL_CRITICAL_HEAT
	])
	lines.append("- Critical Thermal Preview: %d" % get_critical_internal_preview_count())

	if has_method("get_overlay_thermal_contribution_compact_text"):
		lines.append("- " + get_overlay_thermal_contribution_compact_text())

	if has_method("get_overlay_heat_diff_compact_text"):
		lines.append("- " + get_overlay_heat_diff_compact_text())

	lines.append("")
	lines.append("Damage / Repair:")
	if has_method("get_damage_planning_compact_text"):
		lines.append("- " + get_damage_planning_compact_text())
	if has_method("get_repair_planning_compact_reference_text"):
		lines.append("- " + get_repair_planning_compact_reference_text())

	lines.append("")
	lines.append("Readiness:")
	if has_method("get_constructor_readiness_summary_text"):
		lines.append(get_constructor_readiness_summary_text())
	else:
		lines.append("- Readiness summary unavailable")

	lines.append("")
	lines.append("Warnings:")
	if has_method("get_warning_count"):
		lines.append("- Warning count: %d" % get_warning_count())
	elif has_method("get_constructor_warning_lines"):
		var warning_lines: Array[String] = get_constructor_warning_lines()
		lines.append("- Warning count: %d" % warning_lines.size())
	else:
		lines.append("- Warning count unavailable")

	lines.append("")
	lines.append("Consistency:")
	if has_method("get_constructor_consistency_issue_lines"):
		var issue_lines: Array[String] = get_constructor_consistency_issue_lines()
		lines.append("- Consistency issues: %d" % issue_lines.size())
	else:
		lines.append("- Consistency check unavailable")

	lines.append("")
	lines.append("Implementation status:")
	lines.append("- Constructor planning is UI/data preview only.")
	lines.append("- Overlay Thermal is hypothetical only.")
	lines.append("- Damage/Repair is metadata only.")
	lines.append("- No Test Build is implemented.")
	lines.append("- No runtime module damage is implemented.")
	lines.append("- Missions are not blocked by constructor planning.")

	return "\n".join(lines)

func get_constructor_planning_checkpoint_compact_text() -> String:
	var internal_count: int = get_unique_internal_modules().size()
	var external_count: int = get_unique_external_modules().size()
	var overlay_count: int = internal_overlay_paths.size()
	var warning_count: int = 0
	var consistency_count: int = 0

	if has_method("get_warning_count"):
		warning_count = get_warning_count()
	elif has_method("get_constructor_warning_lines"):
		var warning_lines: Array[String] = get_constructor_warning_lines()
		warning_count = warning_lines.size()

	if has_method("get_constructor_consistency_issue_lines"):
		var issue_lines: Array[String] = get_constructor_consistency_issue_lines()
		consistency_count = issue_lines.size()

	return "Checkpoint: internal %d / external %d / overlay %d / warnings %d / consistency %d" % [
		internal_count,
		external_count,
		overlay_count,
		warning_count,
		consistency_count
	]
func get_constructor_readiness_summary_text() -> String:
	var lines: Array[String] = []
	lines.append("Constructor readiness:")
	lines.append("- Power: %s" % get_status_word(is_virtual_power_available()))
	lines.append("- Internal data: %s" % get_status_word(is_internal_data_network_available()))
	lines.append("- External data: %s" % get_status_word(is_external_data_network_available()))
	lines.append("- Thermal: %s" % get_thermal_status_word())
	lines.append("- Air intake: %s" % get_air_intake_readiness_word())
	lines.append("- Warnings: %d" % get_warning_count())
	return "\n".join(lines)

func get_constructor_readiness_compact_text() -> String:
	return "Readiness: Power %s | Data %s/%s | Thermal %s | Air %s | Warnings %d" % [
		get_status_word(is_virtual_power_available()),
		get_status_word(is_internal_data_network_available()),
		get_status_word(is_external_data_network_available()),
		get_thermal_status_word(),
		get_air_intake_readiness_word(),
		get_warning_count()
	]

func get_virtual_connection_summary_text() -> String:
	var power_available := is_virtual_power_available()
	var internal_network_available := is_internal_data_network_available()
	var external_network_available := is_external_data_network_available()
	var lines: Array[String] = []
	lines.append("Virtual wiring:")
	lines.append("Power:")
	lines.append("- Battery source: %s" % get_yes_no(has_power_source()))
	lines.append("- Power Block: %s" % get_yes_no(has_power_block()))
	lines.append("- Power distribution: %s" % ("available" if power_available else "unavailable"))
	lines.append("")
	lines.append("Data:")
	lines.append("- Internal Interface: %s" % get_yes_no(has_internal_interface()))
	lines.append("- External Interface bridge: %s" % get_yes_no(has_external_interface_bridge()))
	lines.append("- Internal data network: %s" % ("available" if internal_network_available else "unavailable"))
	lines.append("- External data network: %s" % ("available" if external_network_available else "unavailable"))
	lines.append("")
	lines.append("Rules:")
	lines.append("Battery -> Power Block -> devices")
	lines.append("Internal devices -> Internal Interface")
	lines.append("External devices -> External Interface")
	lines.append("Internal Interface <-> External Interface")
	return "\n".join(lines)

func get_internal_connection_scheme_summary_text() -> String:
	return get_virtual_connection_summary_text()

func get_internal_role_summary_text() -> String:
	var role_order: Array[String] = [
		"battery",
		"power_block",
		"internal_interface",
		"external_interface",
		"processor",
		"memory",
		"storage",
		"cooling",
		"wire",
	]
	var lines: Array[String] = ["Internal roles:"]
	for role_id in role_order:
		var role_count := count_internal_role(role_id)
		if role_count > 0:
			lines.append("- %s: %d" % [role_id, role_count])
	if lines.size() == 1:
		lines.append("none")
	return "\n".join(lines)

func get_yes_no(value: bool) -> String:
	return "yes" if value else "no"

func get_module_idle_heat(module: BipobModule) -> int:
	if module == null:
		return 0
	return clampi(module.heat_idle, 0, 5)

func get_module_active_heat(module: BipobModule) -> int:
	if module == null:
		return 0
	return clampi(module.heat_active, 0, 5)

func get_module_cooling_power(module: BipobModule) -> int:
	if module == null:
		return 0
	return max(0, module.cooling_power)

func is_cooling_module(module: BipobModule) -> bool:
	return module != null and module.internal_role == "cooling"

func is_air_cooling_module(module: BipobModule) -> bool:
	return is_cooling_module(module) and module.cooling_type == "air"

func has_external_air_intake() -> bool:
	for module in get_unique_external_modules():
		if module != null and module.id == "air_intake_v1":
			return true
	return false

func has_air_cooling_requiring_intake() -> bool:
	for module in get_unique_internal_modules():
		if module != null and module.requires_air_intake:
			return true
	return false

func get_air_intake_status_text() -> String:
	if not has_air_cooling_requiring_intake():
		return "not required"
	if has_external_air_intake():
		return "installed"
	return "missing"

func get_air_intake_warning_text() -> String:
	if has_air_cooling_requiring_intake() and not has_external_air_intake():
		return "Warning: Air cooling requires Air Intake Node on external body."
	return ""

func get_air_intake_summary_text() -> String:
	var status: String = get_air_intake_status_text()
	var warning: String = get_air_intake_warning_text()
	if warning.is_empty():
		return "Air intake: " + status
	return "Air intake: " + status + "\n" + warning

func get_thermal_metadata_summary_text() -> String:
	var lines: Array[String] = []
	lines.append("Thermal model:")
	lines.append("Critical heat: 5")
	lines.append("")
	lines.append("Heat sources:")
	for module in get_unique_internal_modules():
		if module == null:
			continue
		var idle_heat := get_module_idle_heat(module)
		var active_heat := get_module_active_heat(module)
		if idle_heat <= 0 and active_heat <= 0:
			continue
		lines.append("- %s: %d / %d" % [get_module_display_name(module), idle_heat, active_heat])
	if lines[lines.size() - 1] == "Heat sources:":
		lines.append("none")
	lines.append("")
	lines.append("Cooling:")
	for module in get_unique_internal_modules():
		if module == null or not is_cooling_module(module):
			continue
		lines.append("- %s: %s cooling %d" % [get_module_display_name(module), module.cooling_type, get_module_cooling_power(module)])
	if lines[lines.size() - 1] == "Cooling:":
		lines.append("none")
	lines.append("")
	var requires_intake := has_air_cooling_requiring_intake()
	var intake_installed := has_external_air_intake()
	lines.append("Air:")
	lines.append("- Air cooling requires intake: %s" % get_yes_no(requires_intake))
	lines.append("- Air Intake Node installed: %s" % get_yes_no(intake_installed))
	if requires_intake and not intake_installed:
		lines.append("- Warning: Air cooling requires Air Intake Node on external body.")
	lines.append("")
	lines.append("Rules:")
	lines.append("- Neighbor heat = source heat - 1")
	lines.append("- Cooler cools adjacent modules by 2")
	lines.append("- Radiator cools adjacent modules by 2")
	lines.append("- Radiator near cooler cools by 4")
	lines.append("- Radiator against body cools by 3")
	lines.append("- Water tube base cooling is 2")
	lines.append("- Water tube through cooler = 4")
	lines.append("- Water tube through radiator = 3")
	lines.append("- Water tube through radiator near cooler = 5")
	return "\n".join(lines)

func get_external_device_summary_text() -> String:
	if external_modules_by_slot.is_empty():
		return "External devices: none"
	var lines: Array[String] = ["External devices:"]
	for side_id in EXTERNAL_SIDE_ORDER:
		var side_size := get_external_side_size(side_id)
		var side_module_names: Array[String] = []
		var side_modules_seen: Array[BipobModule] = []
		for y in range(side_size.y):
			for x in range(side_size.x):
				var module := get_external_module_at(side_id, Vector2i(x, y))
				if module == null or side_modules_seen.has(module):
					continue
				side_modules_seen.append(module)
				side_module_names.append(get_module_display_name(module))
		if not side_module_names.is_empty():
			lines.append("- %s: %s" % [side_id, ", ".join(side_module_names)])
	if lines.size() == 1:
		return "External devices: none"
	return "\n".join(lines)
func get_overlay_heat_delta_for_module(module: BipobModule) -> int:
	if module == null:
		return 0

	var base_heat: int = get_preview_heat_after_cooling_for_internal_module(module)
	var overlay_heat: int = get_hypothetical_heat_after_overlay_for_module(module)

	return overlay_heat - base_heat


func does_overlay_improve_module_heat(module: BipobModule) -> bool:
	return get_overlay_heat_delta_for_module(module) < 0


func get_overlay_heat_diff_line(module: BipobModule) -> String:
	if module == null:
		return ""

	var base_heat: int = get_preview_heat_after_cooling_for_internal_module(module)
	var overlay_heat: int = get_hypothetical_heat_after_overlay_for_module(module)
	var delta: int = overlay_heat - base_heat

	var delta_text: String = "0"
	if delta < 0:
		delta_text = "%d" % delta
	elif delta > 0:
		delta_text = "+%d" % delta

	return "%s: base %d -> overlay %d (%s)" % [
		get_module_display_name(module),
		base_heat,
		overlay_heat,
		delta_text
	]


func get_overlay_heat_diff_summary_text(show_unchanged: bool = false) -> String:
	var lines: Array[String] = []
	lines.append("Overlay Diff")

	var modules: Array[BipobModule] = get_unique_internal_modules()
	if modules.is_empty():
		lines.append("none")
		lines.append("")
		lines.append("Note: Overlay Diff is hypothetical only.")
		lines.append("Base Thermal Preview is unchanged.")
		return "\n".join(lines)

	var changed_count: int = 0

	for module in modules:
		if module == null:
			continue

		var delta: int = get_overlay_heat_delta_for_module(module)

		if delta == 0 and not show_unchanged:
			continue

		if delta != 0:
			changed_count += 1

		lines.append("- " + get_overlay_heat_diff_line(module))

	if lines.size() == 1:
		lines.append("none")

	lines.append("")
	lines.append("Changed modules: %d" % changed_count)
	lines.append("Note: Overlay Diff is hypothetical only.")
	lines.append("Base Thermal Preview is unchanged.")

	return "\n".join(lines)


func get_overlay_heat_diff_compact_text() -> String:
	var changed_count: int = 0
	var best_delta: int = 0

	for module in get_unique_internal_modules():
		if module == null:
			continue

		var delta: int = get_overlay_heat_delta_for_module(module)

		if delta < 0:
			changed_count += 1
			best_delta = mini(best_delta, delta)

	return "Overlay Diff: changed %d / best %d" % [
		changed_count,
		best_delta
	]
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

func is_internal_module(module: BipobModule) -> bool:
	return module != null and module.placement_type == "internal"

func get_internal_modules_in_box_storage() -> Array[BipobModule]:
	var modules: Array[BipobModule] = []
	for module in box_storage:
		if is_internal_module(module):
			modules.append(module)
	return modules

func get_box_storage_index_for_internal_selection(internal_index: int) -> int:
	var current_internal_index := 0
	for i in range(box_storage.size()):
		var module: BipobModule = box_storage[i]
		if not is_internal_module(module):
			continue

		if current_internal_index == internal_index:
			return i

		current_internal_index += 1

	return -1

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
		wheels_module.category = "locomotion"
		wheels_module.internal_role = "none"
		wheels_module.description = "Bottom locomotion module for flat terrain."
		wheels_module.granted_commands = [
			"move_forward",
			"move_backward",
			"turn_left",
			"turn_right",
		]
		apply_thermal_metadata(wheels_module)
		apply_damage_metadata(wheels_module)
		install_module(wheels_module)

	if debug_install_manipulator:
		var manipulator_module := BipobModule.new()
		manipulator_module.id = "manipulator_v1"
		manipulator_module.display_name = "Manipulator V1"
		manipulator_module.placement_type = "external"
		manipulator_module.category = "utility"
		manipulator_module.internal_role = "none"
		manipulator_module.description = "External manipulation module for physical interactions."
		manipulator_module.granted_commands = [
			"interact_key",
			"open_physical_door",
		]
		apply_thermal_metadata(manipulator_module)
		apply_damage_metadata(manipulator_module)
		install_module(manipulator_module)

	if debug_install_interface:
		var interface_module := BipobModule.new()
		interface_module.id = "interface_v1"
		interface_module.display_name = "External Interface Port V1"
		interface_module.placement_type = "external"
		interface_module.category = "data"
		interface_module.internal_role = "none"
		interface_module.description = "External interface port for connecting external devices to the internal bridge."
		interface_module.granted_commands = [
			"read_terminal",
			"open_digital_door",
		]
		apply_thermal_metadata(interface_module)
		apply_damage_metadata(interface_module)
		install_module(interface_module)

	if debug_install_visor:
		var visor_module := BipobModule.new()
		visor_module.id = "visor_v1"
		visor_module.display_name = "Visor V1"
		visor_module.placement_type = "external"
		visor_module.category = "vision"
		visor_module.internal_role = "none"
		visor_module.description = "External vision module."
		visor_module.granted_commands = [
			"vision",
		]
		apply_thermal_metadata(visor_module)
		apply_damage_metadata(visor_module)
		install_module(visor_module)

	var air_intake_module := BipobModule.new()
	air_intake_module.id = "air_intake_v1"
	air_intake_module.display_name = "Air Intake Node V1"
	air_intake_module.placement_type = "external"
	air_intake_module.category = "cooling"
	air_intake_module.internal_role = "none"
	air_intake_module.description = "External air intake required by internal air cooling modules."
	apply_thermal_metadata(air_intake_module)
	apply_damage_metadata(air_intake_module)
	if not has_module_id_anywhere(air_intake_module.id):
		box_storage.append(air_intake_module)

	add_internal_mvp_modules_to_box()

func create_internal_module(module_id: String, module_name: String, module_size: Vector3i) -> BipobModule:
	var module := BipobModule.new()
	module.id = module_id
	module.display_name = module_name
	module.placement_type = "internal"
	module.size_x = module_size.x
	module.size_y = module_size.y
	module.size_z = module_size.z
	module.internal_rotatable = true
	module.internal_role = get_internal_role_for_module_id(module_id)
	module.category = get_module_category(module)
	apply_thermal_metadata(module)
	apply_damage_metadata(module)
	return module

func get_internal_role_for_module_id(module_id: String) -> String:
	match module_id:
		"battery_v1_a", "battery_v1_b":
			return "battery"
		"power_block_v1":
			return "power_block"
		"int_interface_v1":
			return "internal_interface"
		"ext_interface_internal_v1":
			return "external_interface"
		"processor_v1":
			return "processor"
		"memory_v1":
			return "memory"
		"hard_drive_v1":
			return "storage"
		"cooler_v1", "radiator_v1", "water_tube_v1", "air_duct_v1":
			return "cooling"
		_:
			return "none"

func apply_thermal_metadata(module: BipobModule) -> void:
	if module == null:
		return
	module.cooling_type = "none"
	module.cooling_power = 0
	module.requires_air_intake = false
	module.is_non_volume_cooling_path = false
	if module.placement_type == "external":
		module.internal_role = "none"
	match module.id:
		"battery_v1_a", "battery_v1_b":
			module.heat_idle = 1
			module.heat_active = 1
		"processor_v1":
			module.heat_idle = 3
			module.heat_active = 5
		"memory_v1":
			module.heat_idle = 1
			module.heat_active = 1
		"hard_drive_v1":
			module.heat_idle = 1
			module.heat_active = 1
		"power_block_v1":
			module.heat_idle = 3
			module.heat_active = 5
		"int_interface_v1", "ext_interface_internal_v1":
			module.heat_idle = 1
			module.heat_active = 1
		"cooler_v1":
			module.cooling_power = 2
			module.cooling_type = "air"
			module.requires_air_intake = true
		"radiator_v1":
			module.cooling_power = 2
			module.cooling_type = "passive"
		"water_tube_v1":
			module.cooling_power = 2
			module.cooling_type = "liquid"
			module.is_non_volume_cooling_path = true
		"air_duct_v1":
			module.cooling_power = 0
			module.cooling_type = "duct"
			module.requires_air_intake = true
			module.is_non_volume_cooling_path = true
		"air_intake_v1":
			module.cooling_power = 0
			module.cooling_type = "air"

func apply_damage_metadata(module: BipobModule) -> void:
	if module == null:
		return
	module.can_be_damaged = true
	module.damage_threshold_heat = 5
	module.repair_complexity = 1
	module.repair_category = "standard"
	match module.id:
		"processor_v1":
			module.repair_complexity = 3
			module.repair_category = "electronics"
		"memory_v1", "hard_drive_v1", "visor_v1", "visor_v2":
			module.repair_complexity = 2
			module.repair_category = "electronics"
		"power_block_v1":
			module.repair_complexity = 3
			module.repair_category = "power"
		"battery_v1_a", "battery_v1_b":
			module.repair_complexity = 2
			module.repair_category = "power"
		"int_interface_v1", "ext_interface_internal_v1", "interface_v1":
			module.repair_complexity = 2
			module.repair_category = "interface"
		"cooler_v1":
			module.repair_complexity = 2
			module.repair_category = "cooling"
		"radiator_v1", "water_tube_v1", "air_duct_v1", "air_intake_v1":
			module.repair_complexity = 1
			module.repair_category = "cooling"
		"wheels_v1", "legs_v1", "tracks_v1", "manipulator_v1":
			module.repair_complexity = 2
			module.repair_category = "mechanical"

func get_damage_planning_preview_text() -> String:
	var lines: Array[String] = []
	lines.append("Damage Preview")
	var modules: Array[BipobModule] = get_unique_internal_modules()
	if modules.is_empty():
		lines.append("No internal modules placed.")
		lines.append("")
		lines.append("Rules:")
		lines.append("- Heat 5 will later damage devices.")
		lines.append("- Repair is not implemented yet.")
		return "\n".join(lines)
	for module in modules:
		if module == null:
			continue
		var preview_heat: int = get_preview_heat_after_cooling_for_internal_module(module)
		var overlay_heat: int = get_hypothetical_heat_after_overlay_for_module(module)
		var threshold: int = get_module_damage_threshold(module)
		lines.append("- %s: heat %d / overlay %d / threshold %d / %s / repair complexity %d" % [
			get_module_display_name(module),
			preview_heat,
			overlay_heat,
			threshold,
			get_repair_category_display_name(module.repair_category),
			module.repair_complexity
		])
	lines.append("")
	lines.append("Rules:")
	lines.append("- Damage is preview only.")
	lines.append("- No module is broken automatically.")
	lines.append("- Overlay Thermal is hypothetical only.")
	lines.append("- Repair in Box is not implemented yet.")
	return "\n".join(lines)

func get_damage_planning_compact_text() -> String:
	var critical_count: int = 0
	var warning_count: int = 0
	for module in get_unique_internal_modules():
		if module == null:
			continue
		if not module.can_be_damaged:
			continue
		var preview_heat: int = get_preview_heat_after_cooling_for_internal_module(module)
		var threshold: int = get_module_damage_threshold(module)
		if preview_heat >= threshold:
			critical_count += 1
		elif preview_heat == threshold - 1:
			warning_count += 1
	return "Damage Preview: critical %d / warning %d" % [critical_count, warning_count]

func get_repair_planning_reference_text() -> String:
	var lines: Array[String] = []

	lines.append("Repair Planning Reference")
	lines.append("")
	lines.append("Current status:")
	lines.append("- Damage and repair are planning metadata only.")
	lines.append("- Modules do not break automatically.")
	lines.append("- Repair in Box is not implemented yet.")
	lines.append("- Missions are not blocked by damage preview.")
	lines.append("- Test Build is not implemented yet.")
	lines.append("")
	lines.append("Damage threshold:")
	lines.append("- damage_threshold_heat defines when a module would be at damage risk later.")
	lines.append("- Current default threshold is heat 5.")
	lines.append("- Heat 5 is critical preview.")
	lines.append("- Heat 4 is warning preview when threshold is 5.")
	lines.append("")
	lines.append("Damage preview:")
	lines.append("- Damage preview uses base thermal preview.")
	lines.append("- Overlay Thermal is shown only as hypothetical comparison.")
	lines.append("- Overlay does not reduce real warning/readiness counts.")
	lines.append("")
	lines.append("Repair complexity:")
	lines.append("- 1 = simple repair")
	lines.append("- 2 = normal repair")
	lines.append("- 3 = complex repair")
	lines.append("- Higher values may later require more parts, time, or tools.")
	lines.append("")
	lines.append("Repair categories:")
	lines.append("- Standard: fallback/common repair")
	lines.append("- Electronics: processor, memory, storage, vision electronics")
	lines.append("- Power: batteries, power block")
	lines.append("- Cooling: cooler, radiator, water tube, air duct, air intake")
	lines.append("- Mechanical: wheels, legs, tracks, manipulator")
	lines.append("- Interface: internal/external interfaces")
	lines.append("")
	lines.append("Future direction:")
	lines.append("- Critical heat may later create damaged state.")
	lines.append("- Damaged modules may later be disabled or degraded.")
	lines.append("- Box may later get Repair actions.")
	lines.append("- Repair may later consume resources.")
	lines.append("- Repair may later require specific tools or modules.")
	lines.append("")
	lines.append("Not implemented:")
	lines.append("- No damaged state.")
	lines.append("- No repair action.")
	lines.append("- No repair cost.")
	lines.append("- No repair time.")
	lines.append("- No mission failure from damage.")
	lines.append("- No automatic module disabling.")

	return "\n".join(lines)

func get_repair_planning_compact_reference_text() -> String:
	return "Repair Planning: threshold heat 5, complexity 1-3, metadata only"

func get_module_description_for_id(module_id: String) -> String:
	match module_id:
		"wheels_v1":
			return "Bottom locomotion module for flat terrain."
		"legs_v1":
			return "Bottom locomotion module for stepped terrain."
		"tracks_v1":
			return "Bottom locomotion module for rough terrain."
		"visor_v1":
			return "External vision module."
		"visor_v2":
			return "Improved external vision module with wider scan shape."
		"manipulator_v1":
			return "External manipulation module for physical interactions."
		"interface_v1":
			return "External interface port for connecting external devices to the internal bridge."
		"air_intake_v1":
			return "External air intake required by internal air cooling modules."
		"battery_v1_a", "battery_v1_b":
			return "Internal power source."
		"processor_v1":
			return "Internal processing module. Generates more heat under heavy load."
		"memory_v1":
			return "Internal memory module."
		"hard_drive_v1":
			return "Internal storage module."
		"power_block_v1":
			return "Distributes power from batteries to devices. Generates more heat under heavy tool load."
		"int_interface_v1":
			return "Internal data network interface."
		"ext_interface_internal_v1":
			return "Internal bridge for external devices."
		"cooler_v1":
			return "Air cooling module. Requires an external Air Intake Node."
		"radiator_v1":
			return "Passive cooling module. More effective near body or next to a cooler."
		"water_tube_v1":
			return "Liquid cooling path placeholder. Future overlay module."
		"air_duct_v1":
			return "Air duct path placeholder. Future overlay module."
		_:
			return ""

func add_internal_mvp_modules_to_box() -> void:
	var internal_specs: Array[Dictionary] = [
		{"id": "battery_v1_a", "name": "Battery V1 A", "size": Vector3i(2, 2, 1)},
		{"id": "battery_v1_b", "name": "Battery V1 B", "size": Vector3i(2, 2, 1)},
		{"id": "processor_v1", "name": "Processor V1", "size": Vector3i(1, 1, 1)},
		{"id": "ext_interface_internal_v1", "name": "External Interface Bridge V1", "size": Vector3i(2, 2, 1)},
		{"id": "int_interface_v1", "name": "Internal Interface V1", "size": Vector3i(1, 1, 1)},
		{"id": "memory_v1", "name": "Memory V1", "size": Vector3i(1, 1, 2)},
		{"id": "power_block_v1", "name": "Power Block V1", "size": Vector3i(1, 2, 2)},
		{"id": "hard_drive_v1", "name": "Hard Drive V1", "size": Vector3i(2, 2, 1)},
		{"id": "cooler_v1", "name": "Cooler V1", "size": Vector3i(1, 1, 1)},
		{"id": "radiator_v1", "name": "Radiator V1", "size": Vector3i(1, 1, 1)},
		{"id": "water_tube_v1", "name": "Water Tube V1", "size": Vector3i(1, 1, 1)},
		{"id": "air_duct_v1", "name": "Air Duct V1", "size": Vector3i(1, 1, 1)},
	]
	for spec in internal_specs:
		var module_id := String(spec.get("id", ""))
		if has_module_id_anywhere(module_id):
			continue
		var module_name := String(spec.get("name", module_id))
		var module_size: Vector3i = spec.get("size", Vector3i.ONE)
		var module: BipobModule = create_internal_module(module_id, module_name, module_size)
		module.description = get_module_description_for_id(module.id)
		box_storage.append(module)

func create_visor_v2_module() -> BipobModule:
	var module := BipobModule.new()
	module.id = "visor_v2"
	module.display_name = "Visor V2"
	module.placement_type = "external"
	module.category = "vision"
	module.internal_role = "none"
	module.description = "Improved external vision module with wider scan shape."
	module.granted_commands = ["vision"]
	module.vision_bonus = 0
	apply_thermal_metadata(module)
	apply_damage_metadata(module)
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
	module.category = "locomotion"
	module.internal_role = "none"
	module.description = "Bottom locomotion module for stepped terrain."
	module.granted_commands = [
		"move_forward",
		"move_backward",
		"turn_left",
		"turn_right",
		"cross_stepped_floor"
	]
	apply_thermal_metadata(module)
	apply_damage_metadata(module)
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

func get_module_availability_text(module: BipobModule) -> String:
	if module == null:
		return "Availability: none"

	var box_count: int = get_box_module_count_by_id(module.id)
	if module.id == "water_tube_v1" or module.id == "air_duct_v1":
		var overlay_count: int = get_overlay_path_count_by_module_id(module.id)
		var overlay_total_count: int = box_count + overlay_count
		return "Availability: box %d / overlay %d / total %d" % [
			box_count,
			overlay_count,
			overlay_total_count
		]
	var external_count: int = get_external_module_count_by_id(module.id)
	var internal_count: int = get_internal_module_count_by_id(module.id)
	var total_count: int = box_count + external_count + internal_count

	return "Availability: box %d / external %d / internal %d / total %d" % [
		box_count,
		external_count,
		internal_count,
		total_count
	]

func get_module_storage_line(module: BipobModule, selected: bool = false) -> String:
	if module == null:
		return ""

	var prefix: String = "> " if selected else "  "
	var display_name: String = get_module_display_name(module)
	var box_count: int = get_box_module_count_by_id(module.id)
	var external_count: int = get_external_module_count_by_id(module.id)
	var internal_count: int = get_internal_module_count_by_id(module.id)

	return "%s%s  [box:%d ext:%d int:%d]" % [
		prefix,
		display_name,
		box_count,
		external_count,
		internal_count
	]

func get_first_module_by_id(module_id: String) -> BipobModule:
	for module in box_storage:
		if module != null and module.id == module_id:
			return module

	for module in get_unique_external_modules():
		if module != null and module.id == module_id:
			return module

	for module in get_unique_internal_modules():
		if module != null and module.id == module_id:
			return module

	return null

func get_module_availability_line_by_id(module_id: String, selected: bool = false) -> String:
	var module: BipobModule = get_first_module_by_id(module_id)
	if module == null:
		return ""

	var prefix: String = "> " if selected else "  "
	var display_name: String = get_module_display_name(module)
	var box_count: int = get_box_module_count_by_id(module_id)
	if module_id == "water_tube_v1" or module_id == "air_duct_v1":
		var overlay_count: int = get_overlay_path_count_by_module_id(module_id)
		return "%s%s  [box:%d overlay:%d]" % [
			prefix,
			display_name,
			box_count,
			overlay_count
		]
	var external_count: int = get_external_module_count_by_id(module_id)
	var internal_count: int = get_internal_module_count_by_id(module_id)

	return "%s%s  [box:%d ext:%d int:%d]" % [
		prefix,
		display_name,
		box_count,
		external_count,
		internal_count
	]

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

	var airflow_range := get_mission8_airflow_range_for_speed(mission8_fan_speed)
	return "Airflow: %s | Speed: %d | Range: %d | Terminal: %s" % [
		get_direction_display_name(mission8_fan_direction),
		mission8_fan_speed,
		airflow_range,
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
	for cable_position in mission7_cable_path:
		if grid_manager.is_in_bounds(cable_position) and grid_manager.get_tile(cable_position) == GridManager.TILE_CABLE:
			grid_manager.set_tile(cable_position, GridManager.TILE_FLOOR)
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
	var airflow_range := get_mission8_airflow_range_for_speed(mission8_fan_speed)
	hint_requested.emit("Fan speed set to %d. Airflow range: %d | Terminal: %s." % [mission8_fan_speed, airflow_range, get_mission8_terminal_state_text()])
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

func get_position_key(cell_position_arg: Vector2i) -> String:
	return str(cell_position_arg.x) + "," + str(cell_position_arg.y)

func set_field_module(cell_position_arg: Vector2i, module: BipobModule) -> void:
	if grid_manager == null:
		return
	if module == null:
		return
	if not grid_manager.is_in_bounds(cell_position_arg):
		return

	grid_manager.set_tile(cell_position_arg, GridManager.TILE_COMPONENT)
	field_modules_by_position[get_position_key(cell_position_arg)] = module

func get_field_module(cell_position_arg: Vector2i) -> BipobModule:
	var key := get_position_key(cell_position_arg)
	if field_modules_by_position.has(key):
		return field_modules_by_position[key]
	return null

func clear_field_module(cell_position_arg: Vector2i) -> void:
	var key := get_position_key(cell_position_arg)
	if field_modules_by_position.has(key):
		field_modules_by_position.erase(key)

func place_visor_v2_field_module(slot_position: Vector2i) -> void:
	set_field_module(slot_position, create_visor_v2_module())

func place_gpu_v1_field_module(slot_position: Vector2i) -> void:
	set_field_module(slot_position, create_gpu_v1_module())

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

func place_debug_field_module_if_valid(slot_position: Vector2i, module_name: String, place_callback: Callable) -> void:
	if grid_manager == null:
		return
	if not grid_manager.is_in_bounds(slot_position):
		print("Skipping debug field module ", module_name, ": out of bounds at ", slot_position)
		hint_requested.emit("Debug module %s skipped: invalid position %s." % [module_name, str(slot_position)])
		return
	if grid_manager.get_tile(slot_position) != GridManager.TILE_FLOOR:
		print("Skipping debug field module ", module_name, ": blocked tile at ", slot_position)
		hint_requested.emit("Debug module %s skipped: tile blocked at %s." % [module_name, str(slot_position)])
		return
	place_callback.call(slot_position)

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
