extends RefCounted
class_name BipobWorldObjectExecutionService


const InteractionSystemRef = preload("res://scripts/world/interaction_system.gd")
const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
const InteractionActionCostServiceRef = preload("res://scripts/game/interaction/interaction_action_cost_service.gd")
const InformationTerminalServiceRef = preload("res://scripts/game/map_constructor_information_terminal_service.gd")
const KeyDoorLinkServiceRef = preload("res://scripts/game/map_constructor_key_door_link_service.gd")

static func _is_power_cable_object(world_object: Dictionary) -> bool:
	var ids: Array[String] = []
	for field_name in ["object_type", "type", "archetype_id", "map_constructor_prefab_id", "prefab_id", "item_type"]:
		ids.append(str(world_object.get(field_name, "")).strip_edges().to_lower())

	for id_value in ids:
		if id_value in ["power_cable", "cable", "cable_reel", "power_cable_reel"]:
			return true
	return false


static func _apply_power_cable_cut_fields(cable: Dictionary) -> void:
	cable["state"] = "broken"
	cable["cable_health_state"] = "broken"
	cable["health_state"] = "broken"
	cable["broken"] = true
	cable["is_broken"] = true
	cable["damaged"] = true
	cable["cut"] = false
	if cable.has("connected"):
		cable["connected"] = false
	if cable.has("is_connected"):
		cable["is_connected"] = false
	if cable.has("connected_side"):
		cable["connected_side"] = false
	if cable.has("disconnected"):
		cable["disconnected"] = true


static func _apply_power_cable_repair_fields(cable: Dictionary) -> void:
	cable["state"] = "normal"
	cable["cable_health_state"] = "normal"
	cable["health_state"] = "normal"
	cable["broken"] = false
	cable["is_broken"] = false
	cable["damaged"] = false
	cable["cut"] = false


static func _persist_direct_power_cable_update(controller: Variant, updated: Dictionary, target_position: Vector2i) -> Dictionary:
	controller.mission_manager.set_world_object_at_cell(target_position, updated)
	var object_id: String = str(updated.get("id", "")).strip_edges()
	if not object_id.is_empty() and controller.mission_manager.has_method("get_world_object_by_id"):
		var persisted: Dictionary = Dictionary(controller.mission_manager.call("get_world_object_by_id", object_id))
		if not persisted.is_empty():
			return persisted
	return updated


static func _build_power_cable_action_result(success: bool, message: String, updated: Dictionary, target_position: Vector2i, action_result: Dictionary, reason: String) -> Dictionary:
	var result: Dictionary = _build_result(success, message, updated, target_position, action_result, reason)
	if success:
		result["refresh_overlay"] = true
		result["refresh_threats"] = true
		result["refresh_action_panel"] = true
		result["emit_facing_hint"] = true
		result["clear_selected_action"] = true
		result["pending_paid_action"] = true
	return result


static func _get_actor_held_cable_end_metadata(actor: Dictionary) -> Dictionary:
	var held_id: String = str(actor.get("held_item_id", "")).strip_edges()
	var held_data: Dictionary = Dictionary(actor.get("held_item_data", {}))
	var held_type: String = str(actor.get("held_item_type", held_data.get("item_type", held_data.get("object_type", "")))).strip_edges().to_lower()
	var data_type: String = str(held_data.get("item_type", held_data.get("object_type", held_type))).strip_edges().to_lower()
	var reel_id: String = str(held_data.get("reel_id", "")).strip_edges()
	var end_index: int = int(held_data.get("end_index", 0))
	var is_cable_end: bool = held_type in ["cable_reel_end", "cable_end", "wire_end"] or data_type in ["cable_reel_end", "cable_end", "wire_end"]
	if not is_cable_end or reel_id.is_empty() or end_index < 1 or end_index > 2:
		return {"held": false, "reel_id": "", "end_index": 0, "held_id": ""}
	return {"held": true, "reel_id": reel_id, "end_index": end_index, "held_id": held_id}


static func _execute_runtime_plug_in(controller: Variant, world_object: Dictionary, target_position: Vector2i, actor: Dictionary) -> Dictionary:
	if not WorldObjectCatalogRef.object_accepts_runtime_power_plug(world_object):
		return _build_result(false, "Target cannot receive external power.", world_object, target_position, {"success": false}, "target_not_connectable")
	var held_cable: Dictionary = _get_actor_held_cable_end_metadata(actor)
	if not bool(held_cable.get("held", false)):
		return _build_result(false, "No cable end in manipulator. Take a cable end from Cable Reel first.", world_object, target_position, {"success": false}, "cable_reel_end_required")
	if controller == null or controller.mission_manager == null or not controller.mission_manager.has_method("connect_cable_reel_to_target"):
		return _build_result(false, "Runtime world is unavailable.", world_object, target_position, {"success": false}, "runtime_unavailable")
	if not InteractionActionCostServiceRef.can_commit_gameplay_action(controller):
		return _build_result(false, "Not enough action/energy.", world_object, target_position, {"success": false}, "insufficient_resources")
	var target_id: String = str(world_object.get("id", "")).strip_edges()
	var reel_id: String = str(held_cable.get("reel_id", "")).strip_edges()
	var end_index: int = int(held_cable.get("end_index", 0))
	var connect_report: Dictionary = Dictionary(controller.mission_manager.call("connect_cable_reel_to_target", reel_id, target_id, end_index))
	if not bool(connect_report.get("success", false)):
		return _build_result(false, str(connect_report.get("message", "Cable target is not connectable.")), world_object, target_position, connect_report, str(connect_report.get("reason", "connect_failed")))
	var updated: Dictionary = world_object.duplicate(true)
	if controller.mission_manager.has_method("get_world_object_by_id"):
		var persisted: Dictionary = Dictionary(controller.mission_manager.call("get_world_object_by_id", target_id))
		if not persisted.is_empty():
			updated = persisted
	updated["runtime_cable_connection"] = {"connected": true, "reel_id": reel_id, "end_index": end_index, "target_id": target_id}
	if controller.mission_manager.has_method("clear_manipulator"):
		controller.mission_manager.call("clear_manipulator")
	var result: Dictionary = _build_result(true, "%s (%s): Cable plugged in. | Action: plug_in" % [updated.get("display_name", "Object"), updated.get("state", "unknown")], updated, target_position, connect_report, "ok")
	result["refresh_overlay"] = true
	result["refresh_threats"] = true
	result["refresh_action_panel"] = true
	result["emit_facing_hint"] = true
	result["clear_selected_action"] = true
	result["pending_paid_action"] = true
	return result


static func _execute_power_cable_state_action(controller: Variant, world_object: Dictionary, target_position: Vector2i, action_id: String) -> Dictionary:
	if controller == null or controller.mission_manager == null:
		return _build_result(false, "Runtime world is unavailable.", world_object, target_position, {"success": false}, "runtime_unavailable")
	if action_id == "repair" and (not controller.has_method("has_held_world_item") or not bool(controller.call("has_held_world_item", "repair_kit"))):
		return _build_result(false, "Repair kit required.", world_object, target_position, {"success": false}, "repair_kit_required")
	if not InteractionActionCostServiceRef.can_commit_gameplay_action(controller):
		return _build_result(false, "Not enough action/energy.", world_object, target_position, {"success": false}, "insufficient_resources")

	var object_id: String = str(world_object.get("id", "")).strip_edges()
	var updated: Dictionary = world_object.duplicate(true)
	var action_result: Dictionary = {"success": true}

	match action_id:
		"cut":
			if not object_id.is_empty() and controller.mission_manager.has_method("cut_power_cable"):
				action_result = Dictionary(controller.mission_manager.call("cut_power_cable", object_id))
				if bool(action_result.get("success", false)) and controller.mission_manager.has_method("get_world_object_by_id"):
					updated = Dictionary(controller.mission_manager.call("get_world_object_by_id", object_id))
			if updated.is_empty() or not bool(action_result.get("success", false)):
				updated = world_object.duplicate(true)
				_apply_power_cable_cut_fields(updated)
				updated = _persist_direct_power_cable_update(controller, updated, target_position)
				_apply_power_cable_cut_fields(updated)
				action_result = {"success": true, "message": "Cable cut.", "reason": "fallback_direct_cable_cut"}
			else:
				_apply_power_cable_cut_fields(updated)
				updated = _persist_direct_power_cable_update(controller, updated, target_position)
				_apply_power_cable_cut_fields(updated)
			return _build_power_cable_action_result(true, "Cable cut.", updated, target_position, action_result, "ok")

		"repair":
			if not object_id.is_empty() and controller.mission_manager.has_method("repair_power_cable"):
				action_result = Dictionary(controller.mission_manager.call("repair_power_cable", object_id, true))
				if bool(action_result.get("success", false)) and controller.mission_manager.has_method("get_world_object_by_id"):
					updated = Dictionary(controller.mission_manager.call("get_world_object_by_id", object_id))
			if updated.is_empty() or not bool(action_result.get("success", false)):
				updated = world_object.duplicate(true)
				_apply_power_cable_repair_fields(updated)
				updated = _persist_direct_power_cable_update(controller, updated, target_position)
				_apply_power_cable_repair_fields(updated)
				action_result = {"success": true, "message": "Cable repaired.", "reason": "fallback_direct_cable_repair"}
			else:
				_apply_power_cable_repair_fields(updated)
				updated = _persist_direct_power_cable_update(controller, updated, target_position)
				_apply_power_cable_repair_fields(updated)
			if controller.has_method("consume_held_world_item_if_type"):
				controller.call("consume_held_world_item_if_type", "repair_kit")
			return _build_power_cable_action_result(true, "Cable repaired.", updated, target_position, action_result, "ok")

	return _build_result(false, "Unsupported cable action.", world_object, target_position, {"success": false}, "unsupported_cable_action")
	
static func execute_world_object_action(controller: Variant, world_object: Dictionary, target_position: Vector2i, actor: Dictionary, module: Dictionary, action_id: String) -> Dictionary:
	if action_id == "plug_in":
		return _execute_runtime_plug_in(controller, world_object, target_position, actor)

	if str(world_object.get("object_group", "")) == "terminal" and action_id == "download" and InformationTerminalServiceRef.is_information_terminal(world_object):
		return _execute_information_terminal_download(controller, world_object, target_position)

	if str(world_object.get("object_group", "")) == "door" and action_id in ["apply_digital_key", "input_password"]:
		var access_result: Dictionary = _execute_acquired_door_access(controller, world_object, target_position, action_id)
		if bool(access_result.get("handled", false)):
			return access_result

	# Cable-specific state actions.
	# Cut is not a state. Cut action makes the cable broken.
	# Repair action returns the cable to normal.
	if _is_power_cable_object(world_object) and action_id in ["repair", "cut"]:
		return _execute_power_cable_state_action(controller, world_object, target_position, action_id)

	if action_id == "repair" and (controller == null or not controller.has_method("has_held_world_item") or not bool(controller.call("has_held_world_item", "repair_kit"))):
		return _build_result(false, "Repair kit required.", world_object, target_position, {"success": false}, "repair_kit_required")

	if action_id == "insert_fuse" and controller != null and controller.has_method("_trace_runtime_inventory_state"):
		controller.call("_trace_runtime_inventory_state", "insert_fuse_check")

	var working_object: Dictionary = world_object.duplicate(true)
	var action_result: Dictionary = InteractionSystemRef.normalize_action_result(Dictionary(InteractionSystemRef.apply_action(actor, module, working_object, action_id)), working_object, action_id)

	if not bool(action_result.get("success", false)):
		return _build_result(false, str(action_result.get("message", "Action failed.")), world_object, target_position, action_result, "action_failed")

	world_object = working_object

	if action_id != "connect" and not InteractionActionCostServiceRef.can_commit_gameplay_action(controller):
		return _build_result(false, "Not enough action/energy.", world_object, target_position, action_result, "insufficient_resources")

	if action_id == "insert_fuse":
		print("[INSERT_FUSE_EXECUTION_REACHED] before consume")
		var consumed_fuse: bool = false

		if controller != null and controller.has_method("consume_visible_held_item_type"):
			consumed_fuse = bool(controller.call("consume_visible_held_item_type", "fuse"))

		if not consumed_fuse and controller != null and controller.has_method("consume_held_world_item_if_type"):
			consumed_fuse = bool(controller.call("consume_held_world_item_if_type", "fuse"))

		if not consumed_fuse:
			return _build_result(false, "Manipulator does not contain a fuse.", world_object, target_position, action_result, "fuse_not_held")

	if action_id == "remove_fuse" and controller.has_method("can_receive_physical_item") and not bool(Dictionary(controller.call("can_receive_physical_item", {"item_type": "fuse"})).get("success", false)):
		return _build_result(false, "No free pocket or manipulator slot.", world_object, target_position, action_result, "no_free_pocket_or_manipulator_slot")

	if action_id == "repair" and str(module.get("id", "")) == "repair_kit" and controller.has_method("consume_held_world_item_if_type"):
		controller.call("consume_held_world_item_if_type", "repair_kit")

	var moved: bool = bool(controller._apply_world_object_effects(action_result.get("effects", []), world_object, target_position, actor))
	if not moved:
		controller.mission_manager.set_world_object_at_cell(target_position, world_object)

	if action_id == "unlock" and str(world_object.get("object_group", "")) == "door" and WorldObjectCatalogRef.normalize_access_type(world_object.get("access_type", world_object.get("lock_type", ""))) == WorldObjectCatalogRef.ACCESS_TYPE_KEY_CARD and controller.mission_manager.has_method("remove_keycard_if_no_door_references"):
		controller.mission_manager.call("remove_keycard_if_no_door_references", str(world_object.get("required_key_id", "")))

	_apply_explicit_power_event(controller, world_object, action_id, action_result)

	var action_message: String = str(action_result.get("message", "Action complete."))
	if str(world_object.get("object_group", "")) != "door" or action_id not in ["open", "close", "unlock"]:
		action_message = "%s (%s): %s | Action: %s" % [world_object.get("display_name", "Object"), world_object.get("state", "unknown"), action_message, action_id]

	var result: Dictionary = _build_result(true, action_message, world_object, target_position, action_result, "ok")
	result["refresh_overlay"] = true
	result["refresh_threats"] = true
	result["refresh_action_panel"] = true
	result["emit_facing_hint"] = true
	result["clear_selected_action"] = true
	result["pending_paid_action"] = action_id != "connect"

	return result


static func _execute_information_terminal_download(controller: Variant, terminal: Dictionary, target_position: Vector2i) -> Dictionary:
	var stored_type: String = InformationTerminalServiceRef.get_stored_data_type(terminal)
	if stored_type == InformationTerminalServiceRef.DATA_NONE:
		return _build_result(false, "No data stored.", terminal, target_position, {"success": false}, "no_data")
	if stored_type == InformationTerminalServiceRef.DATA_FILE:
		if bool(terminal.get("damaged", false)):
			return _build_result(false, "Data file is damaged.", terminal, target_position, {"success": false}, "damaged_data_file")
		if bool(terminal.get("encrypted", false)):
			return _build_result(false, "Data file is encrypted.", terminal, target_position, {"success": false}, "encrypted_data_file")
	if not InteractionActionCostServiceRef.can_commit_gameplay_action(controller):
		return _build_result(false, "Not enough action/energy.", terminal, target_position, {"success": false}, "insufficient_resources")
	var acquire_result: Dictionary = {"ok": false, "message": "No data stored."}
	if controller == null or controller.mission_manager == null:
		return _build_result(false, "Runtime storage unavailable.", terminal, target_position, {"success": false}, "missing_mission_manager")
	match stored_type:
		InformationTerminalServiceRef.DATA_ACCESS_CODE:
			var code: String = str(terminal.get("access_code_value", terminal.get("stored_access_code", terminal.get("access_code", "")))).strip_edges()
			if controller.mission_manager.has_method("acquire_runtime_access_code"):
				acquire_result = Dictionary(controller.mission_manager.call("acquire_runtime_access_code", code))
		InformationTerminalServiceRef.DATA_DIGITAL_KEY:
			var key_id: String = str(terminal.get("stored_digital_key_id", terminal.get("stored_key_id", terminal.get("stored_item_id", "")))).strip_edges()
			if controller.mission_manager.has_method("acquire_runtime_digital_key"):
				acquire_result = Dictionary(controller.mission_manager.call("acquire_runtime_digital_key", key_id))
		InformationTerminalServiceRef.DATA_FILE:
			var file_id: String = str(terminal.get("stored_data_file_id", terminal.get("payload_id", terminal.get("data_file_id", "")))).strip_edges()
			if controller.mission_manager.has_method("acquire_runtime_data_file"):
				acquire_result = Dictionary(controller.mission_manager.call("acquire_runtime_data_file", file_id))
	if not bool(acquire_result.get("ok", false)):
		return _build_result(false, str(acquire_result.get("message", "No data stored.")), terminal, target_position, {"success": false}, "acquire_failed")
	var result: Dictionary = _build_result(true, str(acquire_result.get("message", "Data acquired.")), terminal, target_position, {"success": true}, "ok")
	result["refresh_action_panel"] = true
	result["clear_selected_action"] = true
	result["pending_paid_action"] = true
	return result

static func _execute_acquired_door_access(controller: Variant, door: Dictionary, target_position: Vector2i, action_id: String) -> Dictionary:
	if controller == null or controller.mission_manager == null:
		return {"handled": false}
	var access_type: String = KeyDoorLinkServiceRef.get_door_access_type(door)
	if action_id == "apply_digital_key":
		if access_type != KeyDoorLinkServiceRef.ACCESS_TYPE_DIGITAL_KEY:
			return {"handled": false}
		var required_key_id: String = str(door.get("required_key_id", door.get("required_digital_key_id", ""))).strip_edges()
		if required_key_id.is_empty() or not controller.mission_manager.has_method("has_acquired_digital_key") or not bool(controller.mission_manager.call("has_acquired_digital_key", required_key_id)):
			return _build_result(false, "Digital key required.", door, target_position, {"success": false}, "digital_key_required")
	elif action_id == "input_password":
		if access_type != KeyDoorLinkServiceRef.ACCESS_TYPE_ACCESS_CODE:
			return {"handled": false}
		var code: String = str(door.get("access_code_value", door.get("access_code", door.get("password", "")))).strip_edges()
		if code.is_empty() or not controller.mission_manager.has_method("has_acquired_access_code") or not bool(controller.mission_manager.call("has_acquired_access_code", code)):
			return _build_result(false, "Access code required.", door, target_position, {"success": false}, "access_code_required")
	if not InteractionActionCostServiceRef.can_commit_gameplay_action(controller):
		return _build_result(false, "Not enough action/energy.", door, target_position, {"success": false}, "insufficient_resources")
	var updated: Dictionary = door.duplicate(true)
	updated["state"] = "closed"
	updated["is_locked"] = false
	updated["locked"] = false
	updated = WorldObjectCatalogRef.normalize_door_state_fields(updated)
	controller.mission_manager.set_world_object_at_cell(target_position, updated)
	var result: Dictionary = _build_result(true, "Door unlocked.", updated, target_position, {"success": true}, "ok")
	result["refresh_overlay"] = true
	result["refresh_threats"] = true
	result["refresh_action_panel"] = true
	result["emit_facing_hint"] = true
	result["clear_selected_action"] = true
	result["pending_paid_action"] = true
	return result

static func finalize_world_object_action(controller: Variant, execution_result: Dictionary) -> void:
	if not bool(execution_result.get("pending_paid_action", false)):
		return
	InteractionActionCostServiceRef.commit_gameplay_action(controller, execution_result)


static func _apply_explicit_power_event(controller: Variant, world_object: Dictionary, action_id: String, action_result: Dictionary) -> void:
	if action_id == "switch":
		var object_type: String = str(world_object.get("object_type", "")).strip_edges().to_lower()
		object_type = object_type.replace(" ", "_").replace("-", "_")
		if object_type == "power_switcher" and WorldObjectCatalogRef.normalize_switcher_type(world_object) == WorldObjectCatalogRef.SWITCHER_TYPE_LIGHT:
			return
		if object_type in ["light_switch", "circuit_switch", "circuit_breaker", "power_switcher"]:
			var reason := "switch_toggled"
			if object_type == "circuit_breaker" or (object_type == "power_switcher" and WorldObjectCatalogRef.normalize_switcher_type(world_object) == WorldObjectCatalogRef.SWITCHER_TYPE_POWER_BREAKER):
				reason = "circuit_breaker_toggled"
			var power_filter := ""
			if controller.mission_manager.has_method("_get_power_event_filter_for_object"):
				power_filter = str(controller.mission_manager.call("_get_power_event_filter_for_object", world_object))
			var apply_report: Dictionary = Dictionary(controller.apply_power_network_after_explicit_power_event(reason, power_filter))
			action_result["power_apply_report"] = apply_report
	elif action_id in ["circuit_1", "circuit_2", "circuit_3"]:
		var line_power_filter := ""
		if controller.mission_manager.has_method("_get_power_event_filter_for_object"):
			line_power_filter = str(controller.mission_manager.call("_get_power_event_filter_for_object", world_object))
		var line_apply_report: Dictionary = Dictionary(controller.apply_power_network_after_explicit_power_event("switcher_line_selected", line_power_filter))
		action_result["power_apply_report"] = line_apply_report
	elif action_id in ["insert_fuse", "remove_fuse"]:
		var fuse_power_filter := ""
		if controller.mission_manager.has_method("_get_power_event_filter_for_object"):
			fuse_power_filter = str(controller.mission_manager.call("_get_power_event_filter_for_object", world_object))
		var power_reason: String = "fuse_inserted" if action_id == "insert_fuse" else "fuse_removed"
		var fuse_apply_report: Dictionary = Dictionary(controller.apply_power_network_after_explicit_power_event(power_reason, fuse_power_filter))
		action_result["power_apply_report"] = fuse_apply_report


static func _build_result(success: bool, message: String, world_object: Dictionary, target_position: Vector2i, action_result: Dictionary, reason: String) -> Dictionary:
	return {
		"handled": true,
		"success": success,
		"message": message,
		"spent_action": false,
		"refresh_overlay": false,
		"refresh_threats": false,
		"refresh_action_panel": false,
		"emit_status": true,
		"emit_facing_hint": false,
		"clear_selected_action": false,
		"world_object": world_object,
		"target_position": target_position,
		"action_result": action_result,
		"pending_paid_action": false,
		"reason": reason
	}
