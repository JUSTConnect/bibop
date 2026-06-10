extends RefCounted
class_name PlatformMechanismRulesService

# Platform mechanism helper rules.
# Foundation only: no scene mutation, no animation, no UI/action-panel integration.

const CONTROL_MODE_CELL: String = "cell"
const CONTROL_MODE_EXTERNAL: String = "external"
const CONTROL_MODE_NONE: String = "none"

const POWER_MODE_INTERNAL: String = "internal"
const POWER_MODE_EXTERNAL: String = "external"

const PLATFORM_OPERATION_RAISE: String = "raise"
const PLATFORM_OPERATION_LOWER: String = "lower"
const PLATFORM_OPERATION_ROTATE: String = "rotate"
const PLATFORM_OPERATION_TOGGLE: String = "toggle"
const PLATFORM_OPERATION_NONE: String = "none"

const PLATFORM_STATE_IDLE: String = "idle"
const PLATFORM_STATE_RAISED: String = "raised"
const PLATFORM_STATE_LOWERED: String = "lowered"
const PLATFORM_STATE_ROTATED: String = "rotated"
const PLATFORM_STATE_DISABLED: String = "disabled"

static func normalize_control_mode(value: String) -> String:
	var normalized: String = str(value).strip_edges().to_lower()
	if normalized in [CONTROL_MODE_CELL, CONTROL_MODE_EXTERNAL, CONTROL_MODE_NONE]:
		return normalized
	return CONTROL_MODE_CELL

static func normalize_power_mode(value: String) -> String:
	var normalized: String = str(value).strip_edges().to_lower()
	if normalized in [POWER_MODE_INTERNAL, POWER_MODE_EXTERNAL]:
		return normalized
	return POWER_MODE_INTERNAL

static func normalize_operation(value: String) -> String:
	var normalized: String = str(value).strip_edges().to_lower()
	if normalized in [PLATFORM_OPERATION_RAISE, PLATFORM_OPERATION_LOWER, PLATFORM_OPERATION_ROTATE, PLATFORM_OPERATION_TOGGLE, PLATFORM_OPERATION_NONE]:
		return normalized
	if normalized in ["rotate_left", "rotate_right", "left", "right", "turn_left", "turn_right"]:
		return PLATFORM_OPERATION_ROTATE
	return PLATFORM_OPERATION_TOGGLE

static func normalize_platform_state(value: String) -> String:
	var normalized: String = str(value).strip_edges().to_lower()
	if normalized in [PLATFORM_STATE_IDLE, PLATFORM_STATE_RAISED, PLATFORM_STATE_LOWERED, PLATFORM_STATE_ROTATED, PLATFORM_STATE_DISABLED]:
		return normalized
	return PLATFORM_STATE_IDLE

static func normalize_mechanism(mechanism: Dictionary) -> Dictionary:
	var result: Dictionary = mechanism.duplicate(true)
	result["control_mode"] = normalize_control_mode(str(result.get("control_mode", CONTROL_MODE_CELL)))
	result["power_mode"] = normalize_power_mode(str(result.get("power_mode", POWER_MODE_INTERNAL)))
	result["operation"] = normalize_operation(str(result.get("operation", PLATFORM_OPERATION_TOGGLE)))
	result["state"] = normalize_platform_state(str(result.get("state", PLATFORM_STATE_IDLE)))
	if not result.has("platform_ids") or not (result.get("platform_ids") is Array):
		result["platform_ids"] = []
	result["platform_ids"] = _normalize_string_array(result.get("platform_ids", []))
	if not result.has("control_cell"):
		result["control_cell"] = Vector2i(-1, -1)
	if not result.has("external_controller_id"):
		result["external_controller_id"] = ""
	return result

static func build_mechanism_from_platform(platform_data: Dictionary, platform_ids: Array[String] = []) -> Dictionary:
	var normalized_platform: Dictionary = Dictionary(platform_data).duplicate(true)
	var mechanism: Dictionary = {}
	for field_name in ["mechanism_id", "platform_mechanism_id", "mechanism_role", "platform_mode", "state", "platform_level", "current_level", "max_level", "min_level", "min_height_level", "max_height_level", "control_mode", "control_type", "power_mode", "power_type", "operation", "platform_action", "local_switch_cell", "local_switch_facing_dir", "control_cell", "control_cell_x", "control_cell_y", "button_cell_x", "button_cell_y", "external_controller_id", "linked_terminal_id"]:
		if normalized_platform.has(field_name):
			mechanism[field_name] = normalized_platform.get(field_name)
	var control_mode_source: String = str(normalized_platform.get("control_mode", normalized_platform.get("control_type", CONTROL_MODE_CELL))).strip_edges().to_lower()
	var normalized_control_mode: String = CONTROL_MODE_CELL
	if control_mode_source in [CONTROL_MODE_CELL, CONTROL_MODE_EXTERNAL, CONTROL_MODE_NONE]:
		normalized_control_mode = control_mode_source
	elif control_mode_source in ["internal", "self", "local", "cell", "switch"]:
		normalized_control_mode = CONTROL_MODE_CELL
	elif control_mode_source in ["external", "terminal", "remote"]:
		normalized_control_mode = CONTROL_MODE_EXTERNAL
	mechanism["control_mode"] = normalized_control_mode
	var power_mode_source: String = str(normalized_platform.get("power_mode", normalized_platform.get("power_type", POWER_MODE_INTERNAL))).strip_edges().to_lower()
	mechanism["power_mode"] = POWER_MODE_EXTERNAL if power_mode_source in [POWER_MODE_EXTERNAL, "external_power", "external power"] else POWER_MODE_INTERNAL
	var operation_source: String = str(normalized_platform.get("mechanism_operation", normalized_platform.get("operation", normalized_platform.get("platform_action", PLATFORM_OPERATION_TOGGLE))))
	mechanism["operation"] = normalize_operation(operation_source)
	var mechanism_state: String = str(normalized_platform.get("mechanism_state", normalized_platform.get("state", PLATFORM_STATE_IDLE)))
	mechanism["state"] = normalize_platform_state(mechanism_state)
	var platform_id: String = _get_platform_id(normalized_platform)
	if platform_ids.is_empty():
		var collected_ids: Array[String] = _normalize_string_array(normalized_platform.get("platform_ids", []))
		if collected_ids.is_empty() and not platform_id.is_empty():
			collected_ids.append(platform_id)
		mechanism["platform_ids"] = collected_ids
	else:
		mechanism["platform_ids"] = _normalize_string_array(platform_ids)
	var control_cell := _resolve_control_cell(normalized_platform)
	if control_cell != Vector2i(-1, -1):
		mechanism["control_cell"] = control_cell
	elif mechanism["control_mode"] == CONTROL_MODE_CELL:
		mechanism["control_cell"] = _get_platform_cell(normalized_platform)
	else:
		mechanism["control_cell"] = Vector2i(-1, -1)
	mechanism["external_controller_id"] = str(normalized_platform.get("external_controller_id", normalized_platform.get("linked_terminal_id", ""))).strip_edges()
	return normalize_mechanism(mechanism)

static func has_control_cell(mechanism: Dictionary) -> bool:
	var normalized: Dictionary = normalize_mechanism(mechanism)
	if str(normalized.get("control_mode", "")) != CONTROL_MODE_CELL:
		return false
	return _read_cell(normalized.get("control_cell", Vector2i(-1, -1))) != Vector2i(-1, -1)

static func _get_platform_id(platform_data: Dictionary) -> String:
	return str(platform_data.get("platform_id", platform_data.get("id", platform_data.get("object_id", "")))).strip_edges()


static func _get_platform_cell(platform_data: Dictionary) -> Vector2i:
	if platform_data.has("cell"):
		return _read_cell(platform_data.get("cell", Vector2i(-1, -1)))
	if platform_data.has("position"):
		return _read_cell(platform_data.get("position", Vector2i(-1, -1)))
	return Vector2i(int(platform_data.get("x", platform_data.get("cell_x", -1))), int(platform_data.get("y", platform_data.get("cell_y", -1))))


static func _resolve_control_cell(platform_data: Dictionary) -> Vector2i:
	for field_name in ["control_cell", "local_switch_cell", "button_cell", "button_cell_position"]:
		if platform_data.has(field_name):
			var cell := _read_cell(platform_data.get(field_name, Vector2i(-1, -1)))
			if cell != Vector2i(-1, -1):
				return cell
	for prefix in ["control_cell", "button_cell"]:
		var x_field := "%s_x" % prefix
		var y_field := "%s_y" % prefix
		if platform_data.has(x_field) and platform_data.has(y_field):
			var x_value: int = int(platform_data.get(x_field, -1))
			var y_value: int = int(platform_data.get(y_field, -1))
			if x_value >= 0 and y_value >= 0:
				return Vector2i(x_value, y_value)
	return Vector2i(-1, -1)


static func can_use_action_from_cell(mechanism: Dictionary, bipob_cell: Vector2i, is_powered: bool = true) -> Dictionary:
	var normalized: Dictionary = normalize_mechanism(mechanism)
	if str(normalized.get("state", "")) == PLATFORM_STATE_DISABLED:
		return {"ok": false, "message": "Platform mechanism is disabled.", "mechanism": normalized}
	if str(normalized.get("control_mode", "")) != CONTROL_MODE_CELL:
		return {"ok": false, "message": "Platform mechanism is externally controlled.", "mechanism": normalized}
	if not has_control_cell(normalized):
		return {"ok": false, "message": "Platform mechanism has no control cell.", "mechanism": normalized}
	if _read_cell(normalized.get("control_cell", Vector2i(-1, -1))) != bipob_cell:
		return {"ok": false, "message": "Bipob is not standing on the control cell.", "mechanism": normalized}
	if not is_mechanism_powered(normalized, is_powered):
		return {"ok": false, "message": "Platform mechanism has no power.", "mechanism": normalized}
	return {"ok": true, "message": "Platform Action available.", "mechanism": normalized}

static func can_use_external_controller(mechanism: Dictionary, controller_id: String, is_powered: bool = true) -> Dictionary:
	var normalized: Dictionary = normalize_mechanism(mechanism)
	if str(normalized.get("state", "")) == PLATFORM_STATE_DISABLED:
		return {"ok": false, "message": "Platform mechanism is disabled.", "mechanism": normalized}
	if str(normalized.get("control_mode", "")) != CONTROL_MODE_EXTERNAL:
		return {"ok": false, "message": "Platform mechanism is not externally controlled.", "mechanism": normalized}
	if str(normalized.get("external_controller_id", "")) != str(controller_id):
		return {"ok": false, "message": "Wrong external controller.", "mechanism": normalized}
	if not is_mechanism_powered(normalized, is_powered):
		return {"ok": false, "message": "Platform mechanism has no power.", "mechanism": normalized}
	return {"ok": true, "message": "External platform control available.", "mechanism": normalized}

static func is_mechanism_powered(mechanism: Dictionary, external_power_available: bool = true) -> bool:
	var normalized: Dictionary = normalize_mechanism(mechanism)
	if str(normalized.get("power_mode", "")) == POWER_MODE_INTERNAL:
		return true
	return external_power_available

static func apply_operation(mechanism: Dictionary, operation_override: String = "") -> Dictionary:
	var normalized: Dictionary = normalize_mechanism(mechanism)
	var operation: String = normalize_operation(operation_override if not operation_override.is_empty() else str(normalized.get("operation", PLATFORM_OPERATION_TOGGLE)))
	var next_mechanism: Dictionary = normalized.duplicate(true)
	var current_state: String = str(normalized.get("state", PLATFORM_STATE_IDLE))
	match operation:
		PLATFORM_OPERATION_RAISE:
			next_mechanism["state"] = PLATFORM_STATE_RAISED
		PLATFORM_OPERATION_LOWER:
			next_mechanism["state"] = PLATFORM_STATE_LOWERED
		PLATFORM_OPERATION_ROTATE:
			next_mechanism["state"] = PLATFORM_STATE_ROTATED
		PLATFORM_OPERATION_TOGGLE:
			next_mechanism["state"] = PLATFORM_STATE_LOWERED if current_state == PLATFORM_STATE_RAISED else PLATFORM_STATE_RAISED
		_:
			next_mechanism["state"] = current_state
	next_mechanism["last_operation"] = operation
	next_mechanism["needs_visual_refresh"] = true
	return {
		"ok": operation != PLATFORM_OPERATION_NONE,
		"message": "Platform operation applied." if operation != PLATFORM_OPERATION_NONE else "No platform operation configured.",
		"mechanism": next_mechanism,
		"operation": operation,
		"affected_platform_ids": Array(next_mechanism.get("platform_ids", [])).duplicate(),
		"move_occupants_with_platform": true,
		"requires_visual_refresh": true
	}

static func build_action_payload(mechanism: Dictionary, bipob_cell: Vector2i, external_power_available: bool = true) -> Dictionary:
	var check: Dictionary = can_use_action_from_cell(mechanism, bipob_cell, external_power_available)
	var normalized: Dictionary = normalize_mechanism(mechanism)
	return {
		"show_action": bool(check.get("ok", false)),
		"message": str(check.get("message", "")),
		"control_mode": str(normalized.get("control_mode", CONTROL_MODE_CELL)),
		"power_mode": str(normalized.get("power_mode", POWER_MODE_INTERNAL)),
		"operation": str(normalized.get("operation", PLATFORM_OPERATION_TOGGLE)),
		"control_cell": _read_cell(normalized.get("control_cell", Vector2i(-1, -1))),
		"platform_ids": Array(normalized.get("platform_ids", [])).duplicate(),
		"move_occupants_with_platform": true
	}

static func build_external_control_payload(mechanism: Dictionary, controller_id: String, external_power_available: bool = true) -> Dictionary:
	var check: Dictionary = can_use_external_controller(mechanism, controller_id, external_power_available)
	var normalized: Dictionary = normalize_mechanism(mechanism)
	return {
		"can_control": bool(check.get("ok", false)),
		"message": str(check.get("message", "")),
		"control_mode": str(normalized.get("control_mode", CONTROL_MODE_EXTERNAL)),
		"external_controller_id": str(normalized.get("external_controller_id", "")),
		"operation": str(normalized.get("operation", PLATFORM_OPERATION_TOGGLE)),
		"platform_ids": Array(normalized.get("platform_ids", [])).duplicate(),
		"move_occupants_with_platform": true
	}

static func build_occupant_move_payload(platform_id: String, occupant_ids: Array[String], operation: String) -> Dictionary:
	return {
		"platform_id": platform_id,
		"occupant_ids": occupant_ids.duplicate(),
		"operation": normalize_operation(operation),
		"move_with_platform": true
	}

static func _normalize_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in Array(value):
			var text: String = str(item).strip_edges()
			if not text.is_empty() and not result.has(text):
				result.append(text)
	return result

static func _read_cell(value: Variant) -> Vector2i:
	if value is Vector2i:
		return Vector2i(value)
	if value is Vector2:
		var vector_value: Vector2 = Vector2(value)
		return Vector2i(int(vector_value.x), int(vector_value.y))
	if value is Dictionary:
		var data: Dictionary = Dictionary(value)
		return Vector2i(int(data.get("x", data.get("cell_x", -1))), int(data.get("y", data.get("cell_y", -1))))
	if value is Array:
		var array_value: Array = Array(value)
		if array_value.size() >= 2:
			return Vector2i(int(array_value[0]), int(array_value[1]))
	return Vector2i(-1, -1)
