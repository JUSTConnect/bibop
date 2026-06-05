extends RefCounted
class_name PlatformControlService

const PlatformTypesRef = preload("res://scripts/game/platform/platform_types.gd")
const PlatformMechanismServiceRef = preload("res://scripts/game/platform/platform_mechanism_service.gd")

static func get_control_cell(platform_data: Dictionary) -> Vector2i:
	if platform_data.has("control_cell"):
		return PlatformMechanismServiceRef.normalize_cell(platform_data.get("control_cell"))
	return Vector2i(int(platform_data.get("control_cell_x", platform_data.get("button_cell_x", 0))), int(platform_data.get("control_cell_y", platform_data.get("button_cell_y", 0))))

static func normalize_pending_turns(value: int) -> int:
	return maxi(value, 0)

static func get_available_control_actions(platform_data: Dictionary) -> Array[String]:
	var mode: String = PlatformTypesRef.normalize_platform_mode(str(platform_data.get("platform_mode", "")))
	var current_level: int = int(platform_data.get("platform_level", platform_data.get("current_level", 0)))
	var max_level: int = int(platform_data.get("max_level", 1))
	return PlatformTypesRef.available_actions_for_mode(mode, current_level, max_level)

static func get_action_labels(platform_data: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for action in get_available_control_actions(platform_data):
		result.append({"action": action, "label": PlatformTypesRef.action_label(action)})
	return result

static func get_activation_schedule_metadata(platform_data: Dictionary) -> Dictionary:
	var activation_mode: String = PlatformTypesRef.normalize_activation_mode(str(platform_data.get("activation_mode", "")))
	var delay_turns: int = PlatformTypesRef.normalize_delay_turns(int(platform_data.get("activation_delay_turns", 0)))
	var pending_action: String = PlatformTypesRef.normalize_platform_action(str(platform_data.get("pending_action", "")))
	var pending_turns: int = normalize_pending_turns(int(platform_data.get("pending_activation_turns", 0)))
	return {
		"activation_mode": activation_mode,
		"activation_delay_turns": delay_turns,
		"is_delayed": activation_mode == PlatformTypesRef.ACTIVATION_DELAYED and delay_turns > 0,
		"pending": not pending_action.is_empty() and pending_turns > 0,
		"pending_action": pending_action,
		"pending_activation_turns": pending_turns,
		"label": "Instant" if activation_mode == PlatformTypesRef.ACTIVATION_INSTANT else "Delayed: %s turns" % str(delay_turns)
	}

static func validate_control_config(platform_data: Dictionary, known_controller_ids: Array[String] = []) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var control_type: String = PlatformTypesRef.normalize_control_type(str(platform_data.get("control_type", "")))
	var power_type: String = PlatformTypesRef.normalize_power_type(str(platform_data.get("power_type", "")))
	var activation_mode: String = PlatformTypesRef.normalize_activation_mode(str(platform_data.get("activation_mode", "")))
	var delay_turns: int = PlatformTypesRef.normalize_delay_turns(int(platform_data.get("activation_delay_turns", 0)))
	if control_type == PlatformTypesRef.CONTROL_INTERNAL:
		var control_cell: Vector2i = get_control_cell(platform_data)
		if control_cell == Vector2i.ZERO and not bool(platform_data.get("allow_zero_control_cell", false)):
			warnings.append("Internal platform control has no assigned control cell.")
	else:
		var controller_id: String = str(platform_data.get("external_controller_id", platform_data.get("controller_id", ""))).strip_edges()
		if controller_id.is_empty():
			warnings.append("External platform control has no assigned controller.")
		elif not known_controller_ids.is_empty() and not known_controller_ids.has(controller_id):
			warnings.append("External platform controller id is not present in known controllers: %s" % controller_id)
	if power_type == PlatformTypesRef.POWER_EXTERNAL:
		var power_source_id: String = str(platform_data.get("power_source_id", platform_data.get("external_power_source_id", ""))).strip_edges()
		if power_source_id.is_empty():
			warnings.append("External-powered platform has no assigned power source.")
	if activation_mode == PlatformTypesRef.ACTIVATION_DELAYED and delay_turns <= 0:
		warnings.append("Delayed platform activation has zero delay turns; it will behave like instant activation.")
	return {
		"ok": errors.is_empty(),
		"control_type": control_type,
		"power_type": power_type,
		"activation_mode": activation_mode,
		"activation_delay_turns": delay_turns,
		"errors": errors,
		"warnings": warnings
	}

static func schedule_activation(platform_data: Dictionary, action: String) -> Dictionary:
	var normalized_action: String = PlatformTypesRef.normalize_platform_action(action)
	var activation_mode: String = PlatformTypesRef.normalize_activation_mode(str(platform_data.get("activation_mode", "")))
	var delay_turns: int = PlatformTypesRef.normalize_delay_turns(int(platform_data.get("activation_delay_turns", 0)))
	if normalized_action.is_empty():
		return {"ok": false, "started_immediately": false, "pending": false, "error": "Invalid platform action."}
	if activation_mode == PlatformTypesRef.ACTIVATION_DELAYED and delay_turns > 0:
		return {
			"ok": true,
			"started_immediately": false,
			"pending": true,
			"pending_action": normalized_action,
			"pending_activation_turns": delay_turns,
			"label": "Pending %s: %s turns" % [PlatformTypesRef.action_label(normalized_action), str(delay_turns)]
		}
	return {
		"ok": true,
		"started_immediately": true,
		"pending": false,
		"pending_action": "",
		"pending_activation_turns": 0,
		"action": normalized_action,
		"label": PlatformTypesRef.action_label(normalized_action)
	}

static func tick_pending_activation(platform_data: Dictionary) -> Dictionary:
	var pending_action: String = PlatformTypesRef.normalize_platform_action(str(platform_data.get("pending_action", "")))
	var pending_turns: int = normalize_pending_turns(int(platform_data.get("pending_activation_turns", 0)))
	if pending_action.is_empty() or pending_turns <= 0:
		return {"ok": true, "pending": false, "ready": false, "pending_action": "", "pending_activation_turns": 0}
	pending_turns -= 1
	if pending_turns <= 0:
		return {"ok": true, "pending": false, "ready": true, "action": pending_action, "pending_action": "", "pending_activation_turns": 0}
	return {"ok": true, "pending": true, "ready": false, "pending_action": pending_action, "pending_activation_turns": pending_turns}

static func cancel_pending_activation(platform_data: Dictionary) -> Dictionary:
	var pending_action: String = PlatformTypesRef.normalize_platform_action(str(platform_data.get("pending_action", "")))
	var pending_turns: int = normalize_pending_turns(int(platform_data.get("pending_activation_turns", 0)))
	return {
		"ok": true,
		"cancelled": not pending_action.is_empty() or pending_turns > 0,
		"pending_action": "",
		"pending_activation_turns": 0
	}
