extends RefCounted
class_name BipobTerminalControlExecutionService

const TERMINAL_DOOR_CONTROL_ACTIONS: Array[String] = ["open_door", "close_door", "unlock_door"]
const TERMINAL_PLATFORM_CONTROL_ACTIONS: Array[String] = ["activate_platform", "raise_platform", "lower_platform", "rotate_platform_left", "rotate_platform_right", "raise", "lower", "rotate_left", "rotate_right"]

const InteractionActionCostServiceRef = preload("res://scripts/game/interaction/interaction_action_cost_service.gd")
const PlatformTypesRef = preload("res://scripts/game/platform/platform_types.gd")
const PlatformControlServiceRef = preload("res://scripts/game/platform/platform_control_service.gd")


static func is_terminal_platform_control_action(action_id: String) -> bool:
	return TERMINAL_PLATFORM_CONTROL_ACTIONS.has(action_id.strip_edges().to_lower())


static func execute_terminal_control_action(controller: Variant, terminal: Dictionary, _target_position: Vector2i, action_id: String) -> Dictionary:
	var normalized_action: String = action_id.strip_edges().to_lower()
	if normalized_action in TERMINAL_DOOR_CONTROL_ACTIONS:
		return _execute_door_control_action(controller, terminal, normalized_action)
	if normalized_action in TERMINAL_PLATFORM_CONTROL_ACTIONS:
		return _execute_platform_mechanism_control_action(controller, terminal, normalized_action)
	return _build_result(false, false, "Terminal control unavailable.", false, false, false, "unsupported_action")


static func _execute_door_control_action(controller: Variant, terminal: Dictionary, action_id: String) -> Dictionary:
	if not InteractionActionCostServiceRef.can_commit_gameplay_action(controller):
		return _build_result(true, false, "Not enough action/energy.", false, false, true, "insufficient_resources")
	var terminal_result: Dictionary = Dictionary(controller.mission_manager.execute_terminal_control_action(str(terminal.get("id", "")), str(terminal.get("target_door_id", "")), action_id))
	var success: bool = bool(terminal_result.get("success", false))
	var result: Dictionary = _build_result(true, success, "Door control applied." if success else "Door control unavailable.", false, true, true, "ok" if success else "terminal_control_unavailable")
	if success:
		InteractionActionCostServiceRef.commit_gameplay_action(controller, result)
	return result


static func _execute_platform_mechanism_control_action(controller: Variant, terminal: Dictionary, action_id: String) -> Dictionary:
	if controller == null or controller.mission_manager == null:
		return _build_result(true, false, "Platform control unavailable.", false, false, true, "missing_mission_manager")
	if not InteractionActionCostServiceRef.can_commit_gameplay_action(controller):
		return _build_result(true, false, "Not enough action/energy.", false, false, true, "insufficient_resources")
	var mechanism_id: String = _get_terminal_platform_mechanism_id(terminal)
	if mechanism_id.is_empty():
		return _build_result(true, false, "No platform mechanism linked.", false, true, true, "missing_platform_mechanism")
	var members: Array[Dictionary] = _get_platform_mechanism_members(controller.mission_manager, mechanism_id)
	if members.is_empty():
		return _build_result(true, false, "Platform mechanism not found.", false, true, true, "platform_mechanism_not_found")
	var platform_action: String = _resolve_platform_action(action_id, terminal, members[0])
	if platform_action.is_empty():
		return _build_result(true, false, "No available platform action.", false, true, true, "platform_action_unavailable")
	var updated_count: int = 0
	for member_data in members:
		if _apply_platform_action_to_member(controller.mission_manager, member_data, platform_action):
			updated_count += 1
	if updated_count <= 0:
		return _build_result(true, false, "Platform mechanism update failed.", false, true, true, "platform_update_failed")
	var result: Dictionary = _build_result(true, true, "Platform mechanism controlled: %s (%d platform%s)." % [PlatformTypesRef.action_label(platform_action), updated_count, "" if updated_count == 1 else "s"], false, true, true, "ok")
	result["refresh_overlay"] = true
	result["refresh_threats"] = true
	result["emit_facing_hint"] = true
	InteractionActionCostServiceRef.commit_gameplay_action(controller, result)
	return result


static func _get_terminal_platform_mechanism_id(terminal: Dictionary) -> String:
	for field_name in ["target_platform_mechanism_id", "target_platform_id", "platform_mechanism_id", "controlled_platform_mechanism_id"]:
		var value: String = str(terminal.get(field_name, "")).strip_edges()
		if not value.is_empty():
			return value
	return ""


static func _resolve_platform_action(action_id: String, terminal: Dictionary, first_member: Dictionary) -> String:
	var requested_action: String = action_id.strip_edges().to_lower()
	match requested_action:
		"raise_platform":
			return PlatformTypesRef.ACTION_RAISE
		"lower_platform":
			return PlatformTypesRef.ACTION_LOWER
		"rotate_platform_left":
			return PlatformTypesRef.ACTION_ROTATE_LEFT
		"rotate_platform_right":
			return PlatformTypesRef.ACTION_ROTATE_RIGHT
	var configured_action: String = PlatformTypesRef.normalize_platform_action(str(terminal.get("platform_action", terminal.get("target_platform_action", terminal.get("control_action", "")))))
	if not configured_action.is_empty():
		return configured_action
	var available_actions: Array[String] = PlatformControlServiceRef.get_available_control_actions(first_member)
	return available_actions[0] if not available_actions.is_empty() else ""


static func _get_platform_mechanism_members(mission_manager: Variant, mechanism_id: String) -> Array[Dictionary]:
	var members: Array[Dictionary] = []
	if not mission_manager.has_method("get_map_constructor_placed_object_rows") or not mission_manager.has_method("get_map_constructor_entity_by_id"):
		return members
	for row_variant in Array(mission_manager.call("get_map_constructor_placed_object_rows")):
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = Dictionary(row_variant)
		var object_id: String = str(row.get("id", "")).strip_edges()
		if object_id.is_empty():
			continue
		var entity: Dictionary = Dictionary(mission_manager.call("get_map_constructor_entity_by_id", "world_object", object_id))
		if not bool(entity.get("ok", false)):
			continue
		var data: Dictionary = Dictionary(entity.get("data", {}))
		if not _is_platform_data(data):
			continue
		var member_mechanism_id: String = str(data.get("mechanism_id", "")).strip_edges()
		if member_mechanism_id.is_empty():
			member_mechanism_id = "single:%s" % object_id
		if member_mechanism_id == mechanism_id:
			data["id"] = object_id
			members.append(data)
	return members


static func _is_platform_data(data: Dictionary) -> bool:
	var object_type: String = str(data.get("object_type", "")).strip_edges().to_lower()
	var object_group: String = str(data.get("object_group", data.get("group", ""))).strip_edges().to_lower()
	var archetype_id: String = str(data.get("archetype_id", "")).strip_edges().to_lower()
	return object_type == "platform" or object_group == "platform" or archetype_id == "platform" or data.has("platform_mode")


static func _apply_platform_action_to_member(mission_manager: Variant, platform_data: Dictionary, action: String) -> bool:
	var object_id: String = str(platform_data.get("id", "")).strip_edges()
	if object_id.is_empty() or not mission_manager.has_method("apply_map_constructor_property_update"):
		return false
	var normalized_action: String = PlatformTypesRef.normalize_platform_action(action)
	var schedule: Dictionary = PlatformControlServiceRef.schedule_activation(platform_data, normalized_action)
	if not bool(schedule.get("ok", false)):
		return false
	if bool(schedule.get("pending", false)):
		_update_platform_field(mission_manager, object_id, "pending_action", str(schedule.get("pending_action", normalized_action)))
		_update_platform_field(mission_manager, object_id, "pending_activation_turns", int(schedule.get("pending_activation_turns", 0)))
		return true
	if normalized_action == PlatformTypesRef.ACTION_RAISE or normalized_action == PlatformTypesRef.ACTION_LOWER:
		var current_level: int = int(platform_data.get("platform_level", platform_data.get("current_level", 0)))
		var max_level: int = int(platform_data.get("max_level", 1))
		var next_level: int = current_level + 1 if normalized_action == PlatformTypesRef.ACTION_RAISE else current_level - 1
		next_level = PlatformTypesRef.clamp_platform_level(next_level, max_level)
		_update_platform_field(mission_manager, object_id, "platform_level", next_level)
		_update_platform_field(mission_manager, object_id, "current_level", next_level)
		_update_platform_field(mission_manager, object_id, "motion_state", PlatformTypesRef.MOTION_RAISING if next_level > current_level else PlatformTypesRef.MOTION_LOWERING if next_level < current_level else PlatformTypesRef.MOTION_IDLE)
		_update_platform_field(mission_manager, object_id, "motion_progress", 0.0)
		return true
	if normalized_action == PlatformTypesRef.ACTION_ROTATE_LEFT or normalized_action == PlatformTypesRef.ACTION_ROTATE_RIGHT:
		var current_direction: String = str(platform_data.get("direction", platform_data.get("facing", PlatformTypesRef.DIRECTION_NORTH)))
		_update_platform_field(mission_manager, object_id, "direction", PlatformTypesRef.rotate_direction(current_direction, normalized_action))
		_update_platform_field(mission_manager, object_id, "motion_state", PlatformTypesRef.MOTION_ROTATING_LEFT if normalized_action == PlatformTypesRef.ACTION_ROTATE_LEFT else PlatformTypesRef.MOTION_ROTATING_RIGHT)
		_update_platform_field(mission_manager, object_id, "motion_progress", 0.0)
		return true
	return false


static func _update_platform_field(mission_manager: Variant, object_id: String, field_name: String, value: Variant) -> void:
	mission_manager.call("apply_map_constructor_property_update", "world_object", object_id, field_name, value)


static func _build_result(handled: bool, success: bool, message: String, spent_action: bool, refresh_action_panel: bool, emit_status: bool, reason: String) -> Dictionary:
	return {
		"handled": handled,
		"success": success,
		"message": message,
		"spent_action": spent_action,
		"refresh_action_panel": refresh_action_panel,
		"emit_status": emit_status,
		"reason": reason,
		"refresh_overlay": false,
		"refresh_threats": false,
		"emit_facing_hint": false
	}
