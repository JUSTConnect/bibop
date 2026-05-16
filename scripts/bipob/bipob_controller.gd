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
var current_mission_index: int = 1
var max_mission_index: int = 3
var has_key: bool = false
var has_info_key: bool = false
var installed_modules: Array[BipobModule] = []
var found_module: BipobModule = null
var last_diagnostic_result: DiagnosticResult = null

@onready var grid_manager: GridManager = get_node("../Field")
@onready var mission_label: Label = get_node("../UI/MissionLabel")
@onready var body: Polygon2D = $Body

func install_module(module: BipobModule) -> void:
	# MVP behavior: install immediately applies passive bonuses.
	if module == null:
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
			return "Mission 1: pick up the physical key, open the door, reach the exit."
		2:
			return "Mission 2: inspect the silent terminal."
		3:
			return "Mission 3: download the Info-Key, open the digital door, reach the exit."
		_:
			return "No mission goal available."

func get_current_mission_goal_hint() -> String:
	return get_mission_goal_hint(current_mission_index)

func start_mission(mission_index: int) -> void:
	current_mission_index = clampi(mission_index, 1, max_mission_index)
	mission_finished = false
	actions_left = actions_per_turn
	has_key = false
	has_info_key = false
	grid_position = start_grid_position
	update_rotation()
	update_world_position()

	if mission_label != null:
		mission_label.text = ""

	status_changed.emit()
	hint_requested.emit(get_current_mission_goal_hint())

func start_next_mission() -> void:
	if current_mission_index < max_mission_index:
		start_mission(current_mission_index + 1)
		return

	hint_requested.emit("All available Sector-01 missions completed.")

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
	print("Installed module: ", module_to_install.display_name)
	hint_requested.emit("Installed module: " + module_to_install.display_name)
	status_changed.emit()
	return true

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
		hint_requested.emit("Not enough energy.")
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
			hint_requested.emit("Digital door is locked. Get Info-Key from terminal and press E.")
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
	
	if mission_label != null:
		mission_label.text = "MISSION COMPLETE"
	
	print("MISSION COMPLETE")
	print("Bipob reached the exit.")
	hint_requested.emit("Mission complete. Return to the box.")
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
	if not require_command("open_physical_door", "Missing module: Manipulator V1 required."):
		return
	if not has_key:
		print("Door is locked. Physical key required.")
		hint_requested.emit("Door is locked. Physical key required.")
		return
	
	grid_manager.set_tile(door_position, GridManager.TILE_FLOOR)
	spend_action(1, 1)
	print("Door opened.")
	hint_requested.emit("Door opened. Reach the green exit.")
	print_status()
	
func open_digital_door(door_position: Vector2i) -> void:
	if not require_command("open_digital_door", "Missing module: Interface V1 required."):
		return
	if not has_info_key:
		print("Digital door locked. Info-Key required from terminal.")
		hint_requested.emit("Digital door requires Info-Key.")
		return

	if not can_spend_action(1, 1):
		return

	grid_manager.set_tile(door_position, GridManager.TILE_FLOOR)
	spend_action(1, 1)
	print("Digital door opened.")
	hint_requested.emit("Digital door opened.")
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
		hint_requested.emit("No digital device detected.")
		status_changed.emit()
		return

	spend_action(1, 1)
	evaluate_facing_device_capability()
	hint_requested.emit("Scan complete: " + last_diagnostic_result.get_status_text())
	status_changed.emit()

func hack_device() -> void:
	if mission_finished:
		return

	if last_diagnostic_result == null:
		hint_requested.emit("Scan device first.")
		status_changed.emit()
		return

	if not last_diagnostic_result.is_action_allowed():
		hint_requested.emit("Hack blocked: " + last_diagnostic_result.reason)
		status_changed.emit()
		return

	var device := get_facing_device_definition()
	if device == null:
		hint_requested.emit("No digital device detected.")
		status_changed.emit()
		return

	if device.device_type != last_diagnostic_result.device_type \
	or device.supported_action != last_diagnostic_result.supported_action:
		hint_requested.emit("Device changed. Scan again.")
		status_changed.emit()
		return

	match device.supported_action:
		"download_info_key":
			if not can_spend_action(1, 1):
				return
			spend_action(1, 1)
			if current_mission_index == 2:
				hint_requested.emit("Terminal is silent. Interface calibration required.")
				complete_mission()
				return
			has_info_key = true
			hint_requested.emit("Info-Key downloaded. Find the digital door.")
			status_changed.emit()
			return
		"open_digital_door":
			if not has_info_key:
				hint_requested.emit("Digital door requires Info-Key.")
				status_changed.emit()
				return
			if not can_spend_action(1, 1):
				return
			spend_action(1, 1)
			grid_manager.set_tile(get_facing_device_position(), GridManager.TILE_FLOOR)
			hint_requested.emit("Digital door opened.")
			status_changed.emit()
			return
		_:
			hint_requested.emit("Unsupported hack action.")
			status_changed.emit()
			return

func interact() -> void:
	var target_position := get_facing_device_position()
	var target_tile := grid_manager.get_tile(target_position)
	
	match target_tile:
		GridManager.TILE_KEY:
			if not can_spend_action(1, 1):
				return
			pick_up_key(target_position)
		GridManager.TILE_DOOR:
			if not can_spend_action(1, 1):
				return
			open_door(target_position)
		GridManager.TILE_DIGITAL_DOOR:
			open_digital_door(target_position)
		GridManager.TILE_TERMINAL:
			read_terminal(target_position)
		_:
			print("Nothing to interact with at: ", target_position)
			hint_requested.emit("Nothing to interact with. Face a key, door, or terminal and press E.")
			

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
	if not require_command("interact_key", "Missing module: Manipulator V1 required."):
		return
	has_key = true
	grid_manager.set_tile(key_position, GridManager.TILE_FLOOR)
	spend_action(1, 1)
	print("Picked up physical key.")
	hint_requested.emit("Key picked up. Now find the locked door.")
	print_status()
	
func print_status() -> void:
	print(
		"Energy: ", energy, " / ", max_energy,
		" | Actions: ", actions_left, " / ", actions_per_turn,
		" | Has Key: ", has_key,
		" | Has Info Key: ", has_info_key
	)
