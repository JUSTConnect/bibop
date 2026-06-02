extends RefCounted
class_name BipobLegacyAirflowFlowService

const LEGACY_DIRECTION_EAST := 1


static func setup(controller: Variant) -> void:
	controller.mission8_fan_platform_position = Vector2i(4, 2)
	controller.mission8_platform_control_position = Vector2i(2, 2)
	controller.mission8_platform_left_control_position = Vector2i(2, 2)
	controller.mission8_platform_right_control_position = Vector2i(5, 2)
	controller.mission8_fan_control_position = Vector2i(2, 4)
	controller.mission8_fan_speed_up_control_position = Vector2i(2, 3)
	controller.mission8_fan_speed_down_control_position = Vector2i(2, 4)
	controller.mission8_terminal_position = Vector2i(6, 3)
	controller.mission8_door_position = Vector2i(6, 4)
	controller.mission8_fan_direction = LEGACY_DIRECTION_EAST
	controller.mission8_fan_speed = 0
	controller.mission8_terminal_cooled = false
	controller.mission8_terminal_hacked = false
	controller.mission8_airflow_cells.clear()
	update_airflow(controller)


static func get_airflow_status_text(controller: Variant) -> String:
	if not controller.is_legacy_mission8_airflow_flow_active():
		return ""

	var airflow_range := get_airflow_range_for_speed(controller.mission8_fan_speed)
	return "Airflow: %s | Speed: %d | Range: %d | Terminal: %s" % [
		controller.get_direction_display_name(controller.mission8_fan_direction),
		controller.mission8_fan_speed,
		airflow_range,
		get_terminal_state_text(controller)
	]


static func get_terminal_state_text(controller: Variant) -> String:
	return "cooled" if controller.mission8_terminal_cooled else "hot"


static func rotate_fan_left(controller: Variant) -> void:
	controller.mission8_fan_direction = (int(controller.mission8_fan_direction) + 3) % 4
	update_airflow(controller)
	controller.hint_requested.emit("Fan platform rotated left. Airflow: %s | Terminal: %s" % [controller.get_direction_display_name(controller.mission8_fan_direction), get_terminal_state_text(controller)])
	controller.status_changed.emit()


static func rotate_fan_right(controller: Variant) -> void:
	controller.mission8_fan_direction = (int(controller.mission8_fan_direction) + 1) % 4
	update_airflow(controller)
	controller.hint_requested.emit("Fan platform rotated right. Airflow: %s | Terminal: %s" % [controller.get_direction_display_name(controller.mission8_fan_direction), get_terminal_state_text(controller)])
	controller.status_changed.emit()


static func interact_platform_control_left(controller: Variant) -> void:
	if not controller.is_legacy_mission8_airflow_flow_active():
		controller.hint_requested.emit("Platform control is inactive in this mission.")
		controller.status_changed.emit()
		return
	if not controller.can_spend_action(1, 1):
		return
	controller.spend_action(1, 1)
	rotate_fan_left(controller)


static func interact_platform_control_right(controller: Variant) -> void:
	if not controller.is_legacy_mission8_airflow_flow_active():
		controller.hint_requested.emit("Platform control is inactive in this mission.")
		controller.status_changed.emit()
		return
	if not controller.can_spend_action(1, 1):
		return
	controller.spend_action(1, 1)
	rotate_fan_right(controller)


static func interact_fan_control(controller: Variant) -> void:
	if not controller.is_legacy_mission8_airflow_flow_active():
		controller.hint_requested.emit("Fan control is inactive in this mission.")
		controller.status_changed.emit()
		return
	if not controller.can_spend_action(1, 1):
		return
	controller.mission8_fan_speed = (controller.mission8_fan_speed + 1) % 4
	controller.spend_action(1, 1)
	update_airflow(controller)
	var airflow_range := get_airflow_range_for_speed(controller.mission8_fan_speed)
	controller.hint_requested.emit("Fan speed set to %d. Airflow range: %d | Terminal: %s." % [controller.mission8_fan_speed, airflow_range, get_terminal_state_text(controller)])
	controller.status_changed.emit()


static func change_fan_speed(controller: Variant, delta: int) -> void:
	if not controller.is_legacy_mission8_airflow_flow_active():
		controller.hint_requested.emit("Fan speed controls are inactive in this mission.")
		controller.status_changed.emit()
		return
	if not controller.can_spend_action(1, 1):
		return

	var previous_speed : int =int(controller.mission8_fan_speed)
	controller.mission8_fan_speed = clampi(controller.mission8_fan_speed + delta, 0, 3)
	if controller.mission8_fan_speed == previous_speed:
		if delta > 0:
			controller.hint_requested.emit("Fan speed already at maximum.")
		else:
			controller.hint_requested.emit("Fan speed already at minimum.")
		controller.status_changed.emit()
		return

	update_airflow(controller)
	var airflow_range := get_airflow_range_for_speed(controller.mission8_fan_speed)
	controller.hint_requested.emit(
		"Fan speed set to %d. Airflow range: %d | Terminal: %s" % [
			controller.mission8_fan_speed,
			airflow_range,
			get_terminal_state_text(controller)
		]
	)
	controller.spend_action(1, 1)
	controller.status_changed.emit()


static func increase_fan_speed(controller: Variant) -> void:
	change_fan_speed(controller, 1)


static func decrease_fan_speed(controller: Variant) -> void:
	change_fan_speed(controller, -1)


static func get_airflow_range_for_speed(speed: int) -> int:
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


static func get_airflow_cells(controller: Variant) -> Array[Vector2i]:
	var airflow_cells: Array[Vector2i] = []
	for cell in controller.mission8_airflow_cells:
		airflow_cells.append(cell)
	return airflow_cells


static func update_airflow(controller: Variant) -> void:
	if controller.grid_manager == null:
		return
	for cell in controller.mission8_airflow_cells:
		if not controller.grid_manager.is_in_bounds(cell):
			continue
		if controller.grid_manager.get_tile(cell) == GridManager.TILE_AIRFLOW:
			controller.grid_manager.set_tile(cell, GridManager.TILE_FLOOR)
	controller.mission8_airflow_cells.clear()
	controller.mission8_terminal_cooled = false
	controller.grid_manager.set_fan_platform_marker(
		controller.mission8_fan_platform_position,
		controller.get_direction_vector(controller.mission8_fan_direction)
	)

	if controller.mission8_fan_speed <= 0:
		controller.grid_manager.queue_redraw()
		controller.status_changed.emit()
		return

	var max_range : int= int(get_airflow_range_for_speed(controller.mission8_fan_speed))
	var direction_vector : Vector2i = Vector2i(controller.get_direction_vector(controller.mission8_fan_direction))
	var current_position : Vector2i = Vector2i (controller.mission8_fan_platform_position + direction_vector)

	for _i in range(max_range):
		if not controller.grid_manager.is_in_bounds(current_position):
			break
		if current_position == controller.mission8_terminal_position:
			controller.mission8_terminal_cooled = true
			break
		var tile :int = int(controller.grid_manager.get_tile(current_position))
		if tile == GridManager.TILE_WALL or tile == GridManager.TILE_DIGITAL_DOOR or tile == GridManager.TILE_ROUTE_GATE:
			break
		if tile == GridManager.TILE_AIRFLOW_TERMINAL:
			controller.mission8_terminal_cooled = true
			break
		if tile == GridManager.TILE_FAN_PLATFORM or tile == GridManager.TILE_PLATFORM_CONTROL or tile == GridManager.TILE_PLATFORM_CONTROL_LEFT or tile == GridManager.TILE_PLATFORM_CONTROL_RIGHT or tile == GridManager.TILE_FAN_CONTROL or tile == GridManager.TILE_FAN_SPEED_UP_CONTROL or tile == GridManager.TILE_FAN_SPEED_DOWN_CONTROL:
			break
		if tile == GridManager.TILE_FLOOR or tile == GridManager.TILE_AIRFLOW:
			controller.grid_manager.set_tile(current_position, GridManager.TILE_AIRFLOW)
			controller.mission8_airflow_cells.append(current_position)
		current_position += direction_vector

	controller.grid_manager.queue_redraw()
	controller.status_changed.emit()


static func is_cell_in_airflow(controller: Variant, cell: Vector2i) -> bool:
	return controller.mission8_airflow_cells.has(cell)


static func apply_airflow_effects(controller: Variant) -> void:
	update_airflow(controller)


static func unlock_airflow_terminal_path(controller: Variant) -> void:
	# TODO(legacy_mission_retirement): replace hardcoded Mission 8 terminal/door
	# mutation with runtime world-object contracts before deleting legacy missions.
	controller.mission8_terminal_hacked = true
	if controller.grid_manager != null and controller.grid_manager.is_in_bounds(controller.mission8_door_position):
		controller.grid_manager.set_tile(controller.mission8_door_position, GridManager.TILE_FLOOR)
