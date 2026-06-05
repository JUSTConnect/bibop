extends RefCounted
class_name HeavyClawDragService

const BipobMovementControllerRef = preload("res://scripts/bipob/bipob_movement_controller.gd")
const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")

# Cancel only exits drag mode and does not move the object, so it is intentionally free.
const CANCEL_ACTION_COST := 0
const CANCEL_ENERGY_COST := 0


static func is_drag_active(controller: Variant) -> bool:
	return bool(controller.heavy_claw_active) and not str(controller.heavy_claw_drag_object_id).strip_edges().is_empty()


static func start_drag(controller: Variant, object_data: Dictionary) -> Dictionary:
	var object_id: String = str(object_data.get("id", "")).strip_edges()
	if object_id.is_empty():
		return {"success": false, "message": "Object not found."}
	if not WorldObjectCatalogRef.can_world_object_be_moved_by_heavy_claw(object_data):
		return {"success": false, "message": "Object is too heavy."}
	var object_cell: Vector2i = Vector2i(object_data.get("position", Vector2i(-1, -1)))
	var anchor_direction: Vector2i = controller.get_direction_vector(controller.direction)
	if object_cell != controller.grid_position + anchor_direction:
		return {"success": false, "message": "Heavy Claw target must stay directly in front."}
	controller.heavy_claw_active = true
	controller.heavy_claw_drag_object_id = object_id
	controller.heavy_claw_attached_object_cell = object_cell
	controller.heavy_claw_anchor_direction = anchor_direction
	controller.heavy_claw_drag_direction = controller.direction
	controller.refresh_world_action_panel()
	controller.status_changed.emit()
	return {"success": true, "message": "Heavy Claw attached. Use Forward or Back to drag; Cancel releases for free."}


static func cancel_drag(controller: Variant) -> Dictionary:
	if not is_drag_active(controller):
		return {"success": false, "message": "No dragged object.", "action_cost": CANCEL_ACTION_COST, "energy_cost": CANCEL_ENERGY_COST}
	_clear_drag_state(controller)
	controller.refresh_world_action_panel()
	controller.status_changed.emit()
	return {"success": true, "message": "Heavy Claw detached.", "action_cost": CANCEL_ACTION_COST, "energy_cost": CANCEL_ENERGY_COST}


static func get_drag_object(controller: Variant) -> Dictionary:
	if controller.mission_manager == null or not is_drag_active(controller):
		return {}
	if controller.mission_manager.has_method("get_world_object_by_id"):
		return Dictionary(controller.mission_manager.call("get_world_object_by_id", controller.heavy_claw_drag_object_id))
	return {}


static func is_drag_object_synchronized(controller: Variant) -> bool:
	var object_data: Dictionary = get_drag_object(controller)
	if object_data.is_empty():
		return false
	var expected_cell: Vector2i = controller.grid_position + controller.heavy_claw_anchor_direction
	var object_cell: Vector2i = Vector2i(object_data.get("position", Vector2i(-1, -1)))
	return object_cell == expected_cell


static func get_drag_context(controller: Variant) -> Dictionary:
	var object_data: Dictionary = get_drag_object(controller)
	return {
		"active": is_drag_active(controller),
		"object_id": str(controller.heavy_claw_drag_object_id),
		"object_name": str(object_data.get("display_name", object_data.get("name", "Object"))),
		"cancel_action_cost": CANCEL_ACTION_COST,
		"cancel_energy_cost": CANCEL_ENERGY_COST
	}


static func try_move_to(controller: Variant, target_position: Vector2i) -> bool:
	if not is_drag_active(controller):
		return false
	if controller.direction != controller.heavy_claw_drag_direction:
		_emit_blocked(controller, "Cannot turn while dragging object. Cancel first.")
		return false
	var anchor_direction: Vector2i = controller.heavy_claw_anchor_direction
	var movement_delta: Vector2i = target_position - controller.grid_position
	if movement_delta != anchor_direction and movement_delta != -anchor_direction:
		_emit_blocked(controller, "Heavy Claw dragging only supports Forward or Back. Cancel before turning.")
		return false

	var object_data: Dictionary = get_drag_object(controller)
	if object_data.is_empty():
		_clear_drag_state(controller)
		_emit_blocked(controller, "Dragged object missing.")
		return false
	var object_cell: Vector2i = Vector2i(object_data.get("position", Vector2i(-1, -1)))
	var expected_object_cell: Vector2i = controller.grid_position + anchor_direction
	if object_cell != expected_object_cell:
		_clear_drag_state(controller)
		controller.refresh_world_action_panel()
		_emit_blocked(controller, "Dragged object detached.")
		return false

	var moving_forward: bool = movement_delta == anchor_direction
	var object_destination: Vector2i = object_cell + movement_delta if moving_forward else controller.grid_position
	if not _can_bipob_move_during_drag(controller, target_position, object_cell):
		_emit_blocked(controller, "Bipob movement blocked.")
		return false
	if controller.mission_manager == null or not controller.mission_manager.has_method("move_world_object_by_heavy_claw"):
		_emit_blocked(controller, "Object movement blocked.")
		return false

	var move_result: Dictionary = Dictionary(controller.mission_manager.call("move_world_object_by_heavy_claw", controller.heavy_claw_drag_object_id, object_destination))
	if not bool(move_result.get("success", false)):
		var message: String = str(move_result.get("message", "Object movement blocked."))
		if message.is_empty():
			message = "Object movement blocked."
		_emit_blocked(controller, message)
		return false

	controller.heavy_claw_attached_object_cell = object_destination
	controller.refresh_world_object_overlay()
	controller.grid_position = target_position
	controller.refresh_platform_height_state_after_move()
	controller.clear_selected_world_action_if_invalid({}, target_position)
	BipobMovementControllerRef.update_world_position(controller)
	controller._register_successful_player_action()
	controller.check_mission_complete()
	return true


static func _can_bipob_move_during_drag(controller: Variant, target_position: Vector2i, current_object_cell: Vector2i) -> bool:
	if target_position != current_object_cell:
		return bool(controller.is_cell_walkable_for_bipob(target_position))
	if controller.grid_manager == null or not controller.grid_manager.is_in_bounds(target_position):
		return false
	if controller.mission_manager != null and controller.mission_manager.has_method("can_move_between_height_levels"):
		return bool(controller.mission_manager.call("can_move_between_height_levels", controller.grid_position, target_position, controller))
	return true


static func _clear_drag_state(controller: Variant) -> void:
	controller.heavy_claw_active = false
	controller.heavy_claw_drag_object_id = ""
	controller.heavy_claw_attached_object_cell = Vector2i(-1, -1)
	controller.heavy_claw_anchor_direction = Vector2i.ZERO
	controller.heavy_claw_drag_direction = controller.direction


static func _emit_blocked(controller: Variant, message: String) -> void:
	controller.hint_requested.emit(message)
	controller.status_changed.emit()
