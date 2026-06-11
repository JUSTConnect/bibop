extends RefCounted
class_name BipobMovementController


static func move_forward(controller: BipobController) -> void:
	if not controller.require_command("move_forward", "Missing module: Wheels V1 required."):
		return
	if not controller.can_spend_action(1, 0):
		return
	
	var target_position := controller.grid_position + get_direction_vector(controller.direction)
	if controller.has_method("is_heavy_claw_drag_active") and bool(controller.call("is_heavy_claw_drag_active")):
		if bool(controller.call("try_move_heavy_claw_drag_to", target_position)):
			controller.spend_action(1, 0)
			controller.register_successful_movement_cells(1, controller.get_surface_id_for_position(target_position), target_position)
			controller.refresh_world_action_panel()
		return
	
	if try_move_to(controller, target_position):
		controller.spend_action(1, 0)
		controller.register_successful_movement_cells(1, controller.get_surface_id_for_position(target_position), target_position)
		controller.refresh_world_action_panel()


static func move_backward(controller: BipobController) -> void:
	if not controller.require_command("move_backward", "Missing module: Wheels V1 required."):
		return
	if not controller.can_spend_action(1, 0):
		return
	
	var target_position := controller.grid_position - get_direction_vector(controller.direction)
	if controller.has_method("is_heavy_claw_drag_active") and bool(controller.call("is_heavy_claw_drag_active")):
		if bool(controller.call("try_move_heavy_claw_drag_to", target_position)):
			controller.spend_action(1, 0)
			controller.register_successful_movement_cells(1, controller.get_surface_id_for_position(target_position), target_position)
			controller.refresh_world_action_panel()
		return
	
	if try_move_to(controller, target_position):
		controller.spend_action(1, 0)
		controller.register_successful_movement_cells(1, controller.get_surface_id_for_position(target_position), target_position)
		controller.refresh_world_action_panel()


static func turn_left(controller: BipobController) -> void:
	if not controller.require_command("turn_left", "Missing module: Wheels V1 required."):
		return
	if not controller.can_spend_action(1, 0):
		return
	
	controller.direction = BipobController.Direction.values()[(int(controller.direction) + 3) % 4]
	update_visual_facing(controller)
	controller.update_vision()
	controller.update_threat_detection_preview()
	controller.spend_action(1, 0)
	controller.refresh_world_action_panel()


static func turn_right(controller: BipobController) -> void:
	if not controller.require_command("turn_right", "Missing module: Wheels V1 required."):
		return
	if not controller.can_spend_action(1, 0):
		return
	
	controller.direction = BipobController.Direction.values()[(int(controller.direction) + 1) % 4]
	update_visual_facing(controller)
	controller.update_vision()
	controller.update_threat_detection_preview()
	controller.spend_action(1, 0)
	controller.refresh_world_action_panel()


static func try_move_to(controller: BipobController, target_position: Vector2i) -> bool:
	if controller.has_power_source() and not controller.has_power_block():
		controller.hint_requested.emit("Power Block broken. Restart mission or evacuate if possible.")
		controller.status_changed.emit()
		return false
	if controller.grid_manager == null:
		push_error("BipobController: grid_manager is null")
		return false
	
	var target_tile := controller.grid_manager.get_tile(target_position)
	var target_surface_id: String = controller.get_surface_id_for_tile(target_tile)
	var active_gear: BipobModule = controller.get_active_gear_module()
	if active_gear == null:
		controller.hint_requested.emit("Missing module: Wheels V1 required.")
		controller.status_changed.emit()
		return false
	if not controller.can_gear_move_on_surface(active_gear, target_surface_id):
		controller.hint_requested.emit("Current gear cannot move on this surface.")
		controller.status_changed.emit()
		return false

	if not controller.is_cell_walkable_for_bipob(target_position):
		var runtime_block_reason: String = controller._get_runtime_cell_block_reason(target_position)
		if target_tile == GridManager.TILE_WALL:
			controller.hint_requested.emit("Blocked by wall.")
		elif target_tile == GridManager.TILE_DOOR:
			if controller.is_runtime_door_cell_passable(target_position):
				pass
			else:
				controller.hint_requested.emit("Door is closed.")
		elif target_tile == GridManager.TILE_DIGITAL_DOOR:
			if controller.is_runtime_door_cell_passable(target_position):
				pass
			else:
				controller.hint_requested.emit("Digital door is closed.")
		elif target_tile == GridManager.TILE_HOT_NODE:
			controller.hint_requested.emit("Hot Node blocks the route. Scan it first.")
		elif target_tile == GridManager.TILE_AIRFLOW_TERMINAL:
			controller.hint_requested.emit("Terminal blocks the route. Scan it first.")
		elif target_tile == GridManager.TILE_FAN_PLATFORM:
			controller.hint_requested.emit("Fan platform blocks the path. Use controls to rotate airflow.")
		elif target_tile == GridManager.TILE_PLATFORM_CONTROL_LEFT:
			controller.hint_requested.emit("Use Interact to rotate fan platform left.")
		elif target_tile == GridManager.TILE_PLATFORM_CONTROL_RIGHT:
			controller.hint_requested.emit("Use Interact to rotate fan platform right.")
		elif target_tile == GridManager.TILE_PLATFORM_CONTROL:
			controller.hint_requested.emit("Use Interact to rotate the fan platform.")
		elif target_tile == GridManager.TILE_FAN_CONTROL:
			controller.hint_requested.emit("Use Interact to change fan speed.")
		elif target_tile == GridManager.TILE_FAN_SPEED_UP_CONTROL:
			controller.hint_requested.emit("Use Interact to increase fan speed.")
		elif target_tile == GridManager.TILE_FAN_SPEED_DOWN_CONTROL:
			controller.hint_requested.emit("Use Interact to decrease fan speed.")
		elif target_tile == GridManager.TILE_POWERED_GATE:
			if controller.is_runtime_door_cell_passable(target_position):
				pass
			else:
				controller.hint_requested.emit("Powered gate is closed.")
		elif target_tile == GridManager.TILE_CABLE_REEL:
			controller.hint_requested.emit("Cable reel. Use Interact to take the cable end.")
		elif target_tile == GridManager.TILE_SOCKET:
			controller.hint_requested.emit("Socket. Bring the cable end here and use Interact.")
		else:
			if runtime_block_reason.is_empty():
				controller.hint_requested.emit("Path is blocked.")
			else:
				controller.hint_requested.emit("Blocked: %s." % runtime_block_reason)

		print("Blocked: ", target_position)
		return false

	if controller.mission_manager != null:
		if controller.mission_manager.has_method("can_move_between_height_levels"):
			var can_move_height_variant: Variant = controller.mission_manager.call("can_move_between_height_levels", controller.grid_position, target_position, controller)
			if not bool(can_move_height_variant):
				controller.hint_requested.emit("Cannot step off platform: height mismatch.")
				return false
		var blocking_obj: Dictionary = Dictionary(controller.mission_manager.get_world_object_at_cell(target_position))
		if not blocking_obj.is_empty() and bool(blocking_obj.get("blocks_movement", false)) and not controller.is_cell_walkable_for_bipob(target_position):
			controller.hint_requested.emit("Blocked by %s." % blocking_obj.get("display_name", "object"))
			return false
	
	controller.grid_position = target_position
	controller.refresh_platform_height_state_after_move()
	controller.clear_selected_world_action_if_invalid({}, target_position)
	update_world_position(controller)
	controller._register_successful_player_action()
	controller.check_mission_complete()
	return true


static func update_world_position(controller: BipobController) -> void:
	if controller.grid_manager == null:
		return

	var height_visual_offset: float = 0.0
	if controller.has_method("get_platform_height_level"):
		height_visual_offset = float(controller.call("get_platform_height_level")) * 18.0

	var use_iso_visual_position: bool = controller.should_use_isometric_visual_position()

	if use_iso_visual_position:
		var iso_position: Vector2 = controller.get_visual_world_position_for_grid_cell(controller.grid_position)
		iso_position.y -= height_visual_offset

		var parent_node: Node = controller.get_parent()
		if parent_node != null and parent_node is Node2D:
			controller.position = iso_position
		else:
			controller.global_position = iso_position

		controller.z_index = controller.grid_position.x + controller.grid_position.y + 10 + int(controller.get_platform_height_level()) * 10
	else:
		var world_position: Vector2 = controller.grid_manager.global_position + controller.get_visual_world_position_for_grid_cell(controller.grid_position)
		world_position.y -= height_visual_offset
		controller.global_position = world_position

	update_visual_facing(controller)
	controller.update_vision()
	controller.update_threat_detection_preview()
	controller.emit_facing_world_object_hint()
	controller.refresh_world_action_panel()
	
static func update_visual_facing(controller: BipobController) -> void:
	if controller.should_use_isometric_visual_position():
		controller.rotation = controller.get_isometric_visual_rotation_for_direction(controller.direction)
		return

	match controller.direction:
		BipobController.Direction.NORTH:
			controller.rotation_degrees = 0
		BipobController.Direction.EAST:
			controller.rotation_degrees = 90
		BipobController.Direction.SOUTH:
			controller.rotation_degrees = 180
		BipobController.Direction.WEST:
			controller.rotation_degrees = 270


static func get_direction_vector(direction: int) -> Vector2i:
	match direction:
		BipobController.Direction.NORTH:
			return Vector2i(0, -1)
		BipobController.Direction.EAST:
			return Vector2i(1, 0)
		BipobController.Direction.SOUTH:
			return Vector2i(0, 1)
		BipobController.Direction.WEST:
			return Vector2i(-1, 0)
	
	return Vector2i.ZERO
