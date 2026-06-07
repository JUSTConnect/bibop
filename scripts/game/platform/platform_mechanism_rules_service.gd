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

static func has_control_cell(mechanism: Dictionary) -> bool:
	var normalized: Dictionary = normalize_mechanism(mechanism)
	if str(normalized.get("control_mode", "")) != CONTROL_MODE_CELL:
		return false
	return _read_cell(normalized.get("control_cell", Vector2i(-1, -1))) != Vector2i(-1, -1)

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
		return Vector2i(int(data.get("x", -1)), int(data.get("y", -1)))
	return Vector2i(-1, -1)
