extends RefCounted
class_name BipobLegacyTileInteractionService


static func handle_pre_world_object_tile_interaction(
	controller: Variant,
	target_position: Vector2i,
	target_tile: int
) -> Dictionary:
	# Legacy interact must not process digital devices before the modern
	# world-object action path has an explicitly selected action to execute.
	if not String(controller.selected_world_action).is_empty():
		return _unhandled("selected_world_action")

	match target_tile:
		GridManager.TILE_TERMINAL:
			return _handled("Terminal is a digital device. Use Scan Device first, then Hack Device.", "terminal_digital_device")
		GridManager.TILE_DIGITAL_DOOR:
			return _handled("Digital door cannot be opened with Interact. Use Scan Device, then Hack Device.", "digital_door_requires_scan_hack")
		GridManager.TILE_HOT_NODE:
			return _handled("Hot Node is a digital device. Use Scan Device, then Hack Device.", "hot_node_digital_device")
		GridManager.TILE_AIRFLOW_TERMINAL:
			return _handled("Airflow Terminal is a digital device. Use Scan Device, then Hack Device.", "airflow_terminal_digital_device")

	return _unhandled("not_pre_world_object_legacy_tile")


static func apply_result(controller: Variant, result: Dictionary) -> void:
	if not bool(result.get("handled", false)):
		return
	var message: String = String(result.get("message", ""))
	if not message.is_empty():
		controller.hint_requested.emit(message)
	if bool(result.get("clear_selected_action", false)):
		controller.clear_selected_world_action_if_invalid({}, Vector2i(result.get("target_position", Vector2i.ZERO)))
	if bool(result.get("refresh_action_panel", false)):
		controller.refresh_world_action_panel()
	if bool(result.get("emit_status", true)):
		controller.status_changed.emit()


static func _handled(message: String, reason: String) -> Dictionary:
	return {
		"handled": true,
		"message": message,
		"emit_status": true,
		"refresh_action_panel": false,
		"clear_selected_action": false,
		"reason": reason
	}


static func _unhandled(reason: String) -> Dictionary:
	return {
		"handled": false,
		"message": "",
		"emit_status": false,
		"refresh_action_panel": false,
		"clear_selected_action": false,
		"reason": reason
	}
