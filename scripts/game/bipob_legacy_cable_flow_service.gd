extends RefCounted
class_name BipobLegacyCableFlowService

const LEGACY_CABLE_OBJECT_ID := "cable_a"
const CableTopologyServiceRef = preload("res://scripts/game/cable_topology_service.gd")


static func reset_legacy_state(controller: Variant) -> void:
	controller.mission7_is_dragging_cable = false
	controller.mission7_cable_connected = false
	controller.mission7_cable_reel_position = Vector2i(-1, -1)
	controller.mission7_socket_position = Vector2i(-1, -1)
	controller.mission7_powered_gate_position = Vector2i(-1, -1)
	controller.mission7_cable_path.clear()


static func setup(controller: Variant) -> void:
	controller.mission7_is_dragging_cable = false
	controller.mission7_cable_connected = false
	controller.mission7_cable_reel_position = Vector2i(2, 1)
	controller.mission7_socket_position = Vector2i(5, 3)
	controller.mission7_powered_gate_position = Vector2i(6, 4)
	controller.mission7_cable_path.clear()
	# TODO(BIB-360): cable max-length behavior is intentionally not enforced in MVP.


static func interact_cable_reel(controller: Variant) -> void:
	if controller.mission7_cable_connected:
		controller.hint_requested.emit("Cable is already connected.")
		return
	if controller.mission7_is_dragging_cable:
		controller.hint_requested.emit("Cable already in hand. Drag it to the socket.")
		return
	if controller.held_module != null:
		controller.hint_requested.emit("Hand occupied. Drop or store the item before taking the cable.")
		return
	if not controller.can_spend_action(1, 1):
		return
	controller.mission7_is_dragging_cable = true
	controller.mission7_cable_path.clear()
	controller.mission7_cable_path.append(controller.grid_position)
	controller.hint_requested.emit("Cable end taken. Drag it to the socket.")
	controller.spend_action(1, 1)
	controller.status_changed.emit()


static func interact_socket(controller: Variant) -> void:
	if not controller.mission7_is_dragging_cable:
		controller.hint_requested.emit("Take the cable end from the reel first.")
		return
	if controller.mission7_cable_connected:
		controller.hint_requested.emit("Socket already connected.")
		return
	if not controller.can_spend_action(1, 1):
		return
	var path_preview: Array = controller.mission7_cable_path.duplicate(true)
	if not path_preview.has(controller.grid_position):
		path_preview.append(controller.grid_position)
	var topology_validation: Dictionary = _validate_legacy_path(controller, path_preview)
	if not bool(topology_validation.get("ok", true)):
		controller.hint_requested.emit(str(topology_validation.get("message", CableTopologyServiceRef.ERROR_MESSAGE_JUNCTION_REQUIRES_SWITCH)))
		return
	controller.mission7_is_dragging_cable = false
	controller.mission7_cable_connected = true
	controller.mission7_cable_path.clear()
	for path_cell_variant in path_preview:
		if path_cell_variant is Vector2i:
			controller.mission7_cable_path.append(path_cell_variant)
	if controller.mission_manager != null:
		var mission7_cable_object: Dictionary = Dictionary(controller.mission_manager.get_world_object_by_id(LEGACY_CABLE_OBJECT_ID))
		if not mission7_cable_object.is_empty():
			mission7_cable_object["state"] = "connected"
			mission7_cable_object["connected"] = true
			mission7_cable_object["cable_path_cells"] = path_preview.duplicate(true)
			mission7_cable_object["cable_length"] = path_preview.size()
			var power_filter := ""
			if controller.mission_manager.has_method("_get_power_event_filter_for_object"):
				power_filter = str(controller.mission_manager.call("_get_power_event_filter_for_object", mission7_cable_object))
			controller.apply_power_network_after_explicit_power_event("cable_connected", power_filter)
	if controller.grid_manager.get_tile(controller.mission7_powered_gate_position) == GridManager.TILE_POWERED_GATE:
		controller.grid_manager.set_tile(controller.mission7_powered_gate_position, GridManager.TILE_FLOOR)
	controller.hint_requested.emit("Cable connected. Powered gate opened.")
	controller.spend_action(1, 1)
	controller.status_changed.emit()


static func add_current_cell_to_path(controller: Variant) -> void:
	if controller.grid_manager == null or controller.mission7_cable_connected or not controller.mission7_is_dragging_cable:
		return
	if not controller.mission7_cable_path.has(controller.grid_position):
		var path_preview: Array = controller.mission7_cable_path.duplicate(true)
		path_preview.append(controller.grid_position)
		var topology_validation: Dictionary = _validate_legacy_path(controller, path_preview)
		if not bool(topology_validation.get("ok", true)):
			controller.hint_requested.emit(str(topology_validation.get("message", CableTopologyServiceRef.ERROR_MESSAGE_JUNCTION_REQUIRES_SWITCH)))
			return
		controller.mission7_cable_path.append(controller.grid_position)
	var tile: int = int(controller.grid_manager.get_tile(controller.grid_position))
	if tile == GridManager.TILE_FLOOR:
		controller.grid_manager.set_tile(controller.grid_position, GridManager.TILE_CABLE)


static func clear_path_tiles(controller: Variant) -> void:
	if controller.grid_manager == null:
		controller.mission7_cable_path.clear()
		return
	for cable_position in controller.mission7_cable_path:
		if controller.grid_manager.is_in_bounds(cable_position) and controller.grid_manager.get_tile(cable_position) == GridManager.TILE_CABLE:
			controller.grid_manager.set_tile(cable_position, GridManager.TILE_FLOOR)
	controller.mission7_cable_path.clear()


static func release_cable_end(controller: Variant) -> void:
	if not controller.mission7_is_dragging_cable:
		controller.hint_requested.emit("No cable in hand.")
		return
	controller.mission7_is_dragging_cable = false
	clear_path_tiles(controller)
	controller.hint_requested.emit("Cable released. Return to the reel to take it again.")
	controller.status_changed.emit()


static func _validate_legacy_path(controller: Variant, path_cells: Array) -> Dictionary:
	if controller == null or controller.mission_manager == null:
		return {"ok": true, "message": "OK"}
	var world_objects: Array = Array(controller.mission_manager.get("mission_world_objects"))
	var cable_preview: Dictionary = Dictionary(controller.mission_manager.get_world_object_by_id(LEGACY_CABLE_OBJECT_ID))
	if cable_preview.is_empty():
		cable_preview = {"id": LEGACY_CABLE_OBJECT_ID, "object_type": "power_cable"}
	cable_preview["position"] = controller.mission7_cable_reel_position
	cable_preview["cable_path_cells"] = path_cells.duplicate(true)
	cable_preview["cable_length"] = path_cells.size()
	return CableTopologyServiceRef.validate_cable_object(world_objects, cable_preview)


static func get_status_text(controller: Variant) -> String:
	if not controller.is_legacy_mission7_cable_flow_active():
		return ""
	if controller.mission7_cable_connected:
		return "Cable: connected"
	if controller.mission7_is_dragging_cable:
		return "Cable: dragging"
	return "Cable: idle"


static func handle_interact_tile(controller: Variant, _target_position: Vector2i, target_tile: int) -> Dictionary:
	if target_tile == GridManager.TILE_CABLE_REEL:
		interact_cable_reel(controller)
		return {"handled": true, "message": "", "emit_status": false, "reason": "legacy_mission7_cable_reel"}
	if target_tile == GridManager.TILE_SOCKET:
		interact_socket(controller)
		return {"handled": true, "message": "", "emit_status": false, "reason": "legacy_mission7_socket"}
	if target_tile == GridManager.TILE_POWERED_GATE:
		return {
			"handled": true,
			"message": "Powered gate is closed. Connect the cable to the socket.",
			"emit_status": true,
			"reason": "legacy_mission7_powered_gate",
		}
	if controller.is_legacy_mission7_cable_drag_active() and (target_tile == GridManager.TILE_COMPONENT or target_tile == GridManager.TILE_KEY or target_tile == GridManager.TILE_DOOR):
		return {
			"handled": true,
			"message": "Cable in hand. Connect it to the socket or drop it first.",
			"emit_status": true,
			"reason": "legacy_mission7_cable_drag_block",
		}
	return {"handled": false, "message": "", "emit_status": false, "reason": ""}


static func apply_interact_result(controller: Variant, result: Dictionary) -> void:
	var message := str(result.get("message", ""))
	if not message.is_empty():
		controller.hint_requested.emit(message)
	if bool(result.get("emit_status", false)):
		controller.status_changed.emit()
