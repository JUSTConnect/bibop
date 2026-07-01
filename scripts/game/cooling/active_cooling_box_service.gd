extends RefCounted
class_name ActiveCoolingBoxService

const CODE_VALID := "valid"
const CODE_NOT_ACTIVE_COOLING_BOX := "not_active_cooling_box"
const CODE_OUTPUT_SIDE_MISSING := "cooling_output_side_missing"
const CODE_OUTPUT_SIDE_INVALID := "cooling_output_side_invalid"
const CODE_TARGET_BROKEN := "cooling_target_broken"
const CODE_TARGET_DAMAGED := "cooling_target_damaged"

const VALID_OUTPUT_SIDES: Array[String] = ["NE", "SE", "SW", "NW"]
const ACTIVE_COOLING_TYPES: Array[String] = ["metal_cooling_block", "external_air_cooler", "air_cooler", "cooling_fan", "cooling_box", "active_cooler"]
const LEGACY_OUTPUT_FLAGS: Dictionary = {
	"output_ne": "NE",
	"output_se": "SE",
	"output_sw": "SW",
	"output_nw": "NW",
	"cooling_output_ne": "NE",
	"cooling_output_se": "SE",
	"cooling_output_sw": "SW",
	"cooling_output_nw": "NW"
}

static func normalize_side(value: Variant) -> String:
	var side: String = str(value).strip_edges().to_upper().replace("-", "").replace("_", "").replace(" ", "")
	match side:
		"NORTHEAST", "EASTNORTH", "NE": return "NE"
		"SOUTHEAST", "EASTSOUTH", "SE": return "SE"
		"SOUTHWEST", "WESTSOUTH", "SW": return "SW"
		"NORTHWEST", "WESTNORTH", "NW": return "NW"
	return ""

static func is_active_cooling_box(object_data: Dictionary) -> bool:
	if object_data.is_empty():
		return false
	var tokens: Array[String] = []
	for field_name in ["archetype_id", "map_constructor_prefab_id", "object_type", "cooling_system_type", "cooling_device_type"]:
		var token: String = str(object_data.get(field_name, "")).strip_edges().to_lower()
		if not token.is_empty():
			tokens.append(token)
	for token in tokens:
		if ACTIVE_COOLING_TYPES.has(token):
			return true
	return str(object_data.get("object_group", object_data.get("group", ""))).strip_edges().to_lower() == "cooling" and bool(object_data.get("active_cooling", false))

static func resolve_output_side(object_data: Dictionary) -> String:
	for field_name in ["output_side", "cooling_output_side", "facing_side", "mount_side"]:
		var side: String = normalize_side(object_data.get(field_name, ""))
		if not side.is_empty():
			return side
	var enabled_sides: Array[String] = []
	for flag_name in LEGACY_OUTPUT_FLAGS.keys():
		if bool(object_data.get(str(flag_name), false)):
			enabled_sides.append(str(LEGACY_OUTPUT_FLAGS[flag_name]))
	enabled_sides.sort()
	return str(enabled_sides[0]) if enabled_sides.size() == 1 else ""

static func normalize_box(object_data: Dictionary) -> Dictionary:
	var result: Dictionary = object_data.duplicate(true)
	if not is_active_cooling_box(result):
		return result
	var output_side: String = resolve_output_side(result)
	result["object_group"] = "cooling"
	result["object_type"] = "metal_cooling_block"
	result["active_cooling"] = true
	if output_side.is_empty():
		output_side = "SW"
	result["output_side"] = output_side
	result["cooling_output_side"] = output_side
	for flag_name in LEGACY_OUTPUT_FLAGS.keys():
		result.erase(str(flag_name))
	result.erase("flow_state")
	result.erase("blocked_state")
	result.erase("blocked")
	result.erase("connected_device_ids")
	result.erase("linked_cooling_ids")
	return result

static func validate_box(object_data: Dictionary) -> Dictionary:
	if not is_active_cooling_box(object_data):
		return _result(false, CODE_NOT_ACTIVE_COOLING_BOX, [_issue(CODE_NOT_ACTIVE_COOLING_BOX, "Object is not an active cooling box.")])
	var side: String = resolve_output_side(object_data)
	if side.is_empty():
		return _result(false, CODE_OUTPUT_SIDE_MISSING, [_issue(CODE_OUTPUT_SIDE_MISSING, "Active cooling box requires exactly one output side.")])
	if not VALID_OUTPUT_SIDES.has(side):
		return _result(false, CODE_OUTPUT_SIDE_INVALID, [_issue(CODE_OUTPUT_SIDE_INVALID, "Cooling output side must be NE, SE, SW, or NW.")])
	return _result(true, CODE_VALID, [])

static func preview_cooling(box_data: Dictionary, target_data: Dictionary) -> Dictionary:
	var validation: Dictionary = validate_box(box_data)
	if not bool(validation.get("success", false)):
		return validation
	var target_state: String = str(target_data.get("health_state", target_data.get("state", ""))).strip_edges().to_lower()
	if target_state == "broken" or bool(target_data.get("broken", false)):
		return _result(false, CODE_TARGET_BROKEN, [_issue(CODE_TARGET_BROKEN, "Cooling preview never repairs broken targets.")])
	if target_state == "damaged" or bool(target_data.get("damaged", false)):
		return _result(false, CODE_TARGET_DAMAGED, [_issue(CODE_TARGET_DAMAGED, "Cooling preview never repairs damaged targets.")])
	return {
		"ok": true,
		"success": true,
		"code": CODE_VALID,
		"reason_code": CODE_VALID,
		"output_side": resolve_output_side(box_data),
		"read_only": true,
		"mutates_target": false,
		"issues": []
	}

static func _issue(code: String, message: String) -> Dictionary:
	return {"code": code, "reason_code": code, "message": message}

static func _result(success: bool, code: String, issues: Array[Dictionary]) -> Dictionary:
	return {"ok": success, "success": success, "code": code, "reason_code": code, "issues": issues}
