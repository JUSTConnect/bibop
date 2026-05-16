extends Node2D
class_name BipobController

signal status_changed
signal hint_requested(message: String)
signal mission_completed

enum Direction {
	NORTH,
	EAST,
	SOUTH,
	WEST
}

@export var start_grid_position := Vector2i(1, 1)

@export var max_energy: int = 50
@export var vision_range: int = 3
@export var actions_per_turn: int = 5
@export var debug_install_wheels: bool = true
@export var debug_install_manipulator: bool = true
@export var debug_install_interface: bool = true
@export var debug_install_visor: bool = true

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
var max_mission_index: int = 3
var has_key: bool = false
var has_info_key: bool = false
var installed_modules: Array[BipobModule] = []
var box_storage: Array[BipobModule] = []
var found_module: BipobModule = null
var held_module: BipobModule = null
var stored_physical_module: BipobModule = null
var field_modules_by_position: Dictionary = {}
var physical_carry_capacity: int = 2
var digital_storage: Dictionary = {}
var digital_storage_capacity: int = 1
var last_diagnostic_result: DiagnosticResult = null

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
	recalculate_module_stats()

	energy = max_energy
	actions_left = actions_per_turn
	
	if mission_label != null:
		mission_label.text = ""
	
	setup_body()
	
	grid_position = start_grid_position
	update_rotation()
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
		_:
			return "No mission goal available."

func get_current_mission_goal_hint() -> String:
	return get_mission_goal_hint(current_mission_index)

func start_mission(mission_index: int) -> void:
	# Box preparation flow: mission start resets turn actions, but does not spend resources.
	current_mission_index = clampi(mission_index, 1, max_mission_index)
	mission_finished = false
	actions_left = actions_per_turn
	has_key = false
	has_info_key = false
	last_diagnostic_result = null
	grid_position = start_grid_position
	direction = Direction.NORTH
	update_rotation()
	update_world_position()

	if mission_label != null:
		mission_label.text = ""

	status_changed.emit()
	hint_requested.emit(get_current_mission_goal_hint())

func restart_current_mission() -> void:
	if sector_completed and current_mission_index == max_mission_index:
		sector_completed = false

	# Restart flow is state reset, not a field action spend.
	start_mission(current_mission_index)
	last_diagnostic_result = null
	status_changed.emit()

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
		"route_data",
		"Route Data",
		"Temporary route record for future route mission."
	)

func start_next_mission() -> void:
	if sector_completed:
		hint_requested.emit("Sector-01 complete. Playtest build finished.")
		status_changed.emit()
		return

	if current_mission_index < max_mission_index:
		start_mission(current_mission_index + 1)
		return

	sector_completed = true
	hint_requested.emit("Sector-01 complete. Playtest build finished.")
	status_changed.emit()

func create_default_modules() -> void:
	installed_modules.clear()

	if debug_install_wheels:
		var wheels_module := BipobModule.new()
		wheels_module.id = "wheels_v1"
		wheels_module.display_name = "Wheels V1"
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
		manipulator_module.granted_commands = [
			"interact_key",
			"open_physical_door",
		]
		install_module(manipulator_module)

	if debug_install_interface:
		var interface_module := BipobModule.new()
		interface_module.id = "interface_v1"
		interface_module.display_name = "Interface V1"
		interface_module.granted_commands = [
			"read_terminal",
			"open_digital_door",
		]
		install_module(interface_module)

	if debug_install_visor:
		var visor_module := BipobModule.new()
		visor_module.id = "visor_v1"
		visor_module.display_name = "Visor V1"
		visor_module.granted_commands = [
			"vision",
		]
		install_module(visor_module)


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
		return false

	var module_to_install := box_storage[storage_index]
	box_storage.remove_at(storage_index)
	install_module(module_to_install)
	hint_requested.emit("Installed from box: " + get_module_display_name(module_to_install))
	status_changed.emit()
	return true

func return_installed_module_to_box_storage(module: BipobModule) -> void:
	if module == null:
		return

	var installed_index := installed_modules.find(module)
	if installed_index != -1:
		installed_modules.remove_at(installed_index)

	box_storage.append(module)
	# TODO: Replace with dedicated equipment refresh when module removal UI is implemented.
	recalculate_module_stats()
	hint_requested.emit("Returned to box: " + get_module_display_name(module))
	status_changed.emit()

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
	
	if not grid_manager.is_walkable(target_position):
		var target_tile := grid_manager.get_tile(target_position)
	
		if target_tile == GridManager.TILE_WALL:
			hint_requested.emit("Blocked by wall.")
		elif target_tile == GridManager.TILE_DOOR:
			hint_requested.emit("Door is locked. Find a key and press E while facing it.")
		elif target_tile == GridManager.TILE_DIGITAL_DOOR:
			hint_requested.emit("Digital door is locked. Use Scan Device, then Hack Device.")
		else:
			hint_requested.emit("Path is blocked.")
	
		print("Blocked: ", target_position)
		return false
	
	grid_position = target_position
	update_world_position()
	check_mission_complete()
	return true
	
func check_mission_complete() -> void:
	var current_tile := grid_manager.get_tile(grid_position)
	
	if current_tile == GridManager.TILE_EXIT:
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
	else:
		hint_requested.emit("Mission complete. Return to the box.")
	if current_mission_index == max_mission_index:
		sector_completed = true
		hint_requested.emit("Sector-01 complete. Playtest build finished.")
		last_diagnostic_result = null

	if stored_module_this_mission:
		found_module = null
	else:
		create_debug_found_module()
	status_changed.emit()
	mission_completed.emit()
			
func update_world_position() -> void:
	if grid_manager == null:
		return
	
	global_position = grid_manager.global_position + grid_manager.grid_to_world(grid_position)
	update_vision()
	
func update_vision() -> void:
	if not require_command("vision", "Missing module: Visor V1 required."):
		return
	if grid_manager == null:
		return
	
	var direction_vector := get_direction_vector(direction)
	grid_manager.reveal_by_vision(grid_position, direction_vector, vision_range)
	
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
	if not has_info_key and not use_digital_record("info_key"):
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
			store_digital_record("info_key", "Info-Key", "Digital authorization record for opening a digital door.")
			hint_requested.emit("Info-Key downloaded. Now find the digital door, scan it, then hack it.")
			status_changed.emit()
			return
		"open_digital_door":
			if not has_info_key and not use_digital_record("info_key"):
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
		_:
			hint_requested.emit("Unsupported hack action.")
			status_changed.emit()
			return

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
		_:
			print("Nothing to interact with at: ", target_position)
			hint_requested.emit("Nothing to interact with. Face a key, door, or terminal and press E.")

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
	if held_module != null and is_physical_storage_occupied():
		hint_requested.emit("Physical storage full. Drop or deliver an item first.")
		status_changed.emit()
		return

	if not can_spend_action(1, 1):
		return

	var picked_module: BipobModule = field_modules_by_position.get(component_position, null)
	if picked_module == null:
		picked_module = create_debug_field_component()

	field_modules_by_position.erase(component_position)
	grid_manager.set_tile(component_position, GridManager.TILE_FLOOR)

	if held_module == null:
		held_module = picked_module
		hint_requested.emit("Component collected in hand: %s." % get_module_display_name(picked_module))
	else:
		stored_physical_module = picked_module
		hint_requested.emit("Component stored internally: %s." % get_module_display_name(picked_module))

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
	field_modules_by_position[target_position] = module_to_drop
	grid_manager.set_tile(target_position, GridManager.TILE_COMPONENT)
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
			store_digital_record("info_key", "Info-Key", "Digital authorization record for opening a digital door.")
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
