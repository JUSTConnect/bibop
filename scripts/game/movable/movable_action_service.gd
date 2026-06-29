extends RefCounted
class_name MovableActionService

const ACTOR_SCOUT := "scout"
const ACTOR_ENGINEER := "engineer"
const ACTOR_HEAVY := "heavy"
const ACTOR_TYPES: Array[String] = [ACTOR_SCOUT, ACTOR_ENGINEER, ACTOR_HEAVY]

const MANIPULATOR_NONE := "none"
const MANIPULATOR_ARM := "manipulator_arm"
const MANIPULATOR_HEAVY_CLAW := "heavy_claw"
const MANIPULATOR_TYPES: Array[String] = [MANIPULATOR_NONE, MANIPULATOR_ARM, MANIPULATOR_HEAVY_CLAW]

const MOVEMENT_PUSH := "push"
const MOVEMENT_DRAG := "drag"
const MOVEMENT_DIRECT := "direct"
const MOVEMENT_MODES: Array[String] = [MOVEMENT_PUSH, MOVEMENT_DRAG, MOVEMENT_DIRECT]

const WEIGHT_NORMAL := "normal"
const WEIGHT_HEAVY := "heavy"
const CRATE_WEIGHT_CLASSES: Array[String] = [WEIGHT_NORMAL, WEIGHT_HEAVY]

const CODE_VALID := "valid"
const CODE_OBJECT_MISSING := "object_missing"
const CODE_NOT_MOVABLE := "not_movable"
const CODE_OBJECT_INACTIVE := "object_inactive"
const CODE_ACTOR_COUNT_INVALID := "actor_count_invalid"
const CODE_ACTOR_TYPE_INCOMPATIBLE := "actor_type_incompatible"
const CODE_MANIPULATOR_REQUIRED := "manipulator_required"
const CODE_MANIPULATOR_INACTIVE := "manipulator_inactive"
const CODE_MANIPULATOR_OCCUPIED := "manipulator_occupied"
const CODE_HEAVY_CLAW_REQUIRED := "heavy_claw_required"
const CODE_HEAVY_CLAW_INACTIVE := "heavy_claw_inactive"
const CODE_POWER_CLASS_INSUFFICIENT := "power_class_insufficient"
const CODE_ACTION_UNSUPPORTED := "action_unsupported"
const CODE_TARGET_NOT_ADJACENT := "target_not_adjacent"
const CODE_TARGET_NOT_IN_FRONT := "target_not_in_front"
const CODE_DESTINATION_SAME := "destination_same"
const CODE_DESTINATION_OUT_OF_BOUNDS := "destination_out_of_bounds"
const CODE_DESTINATION_BLOCKED := "destination_blocked"
const CODE_DESTINATION_OCCUPIED := "destination_occupied"
const CODE_SURFACE_LEVEL_MISMATCH := "surface_level_mismatch"
const CODE_INVALID_WEIGHT_CLASS := "invalid_weight_class"
const CODE_INVALID_MOVEMENT_REQUIREMENT := "invalid_movement_requirement"

const RESULT_CODES: Array[String] = [
	CODE_VALID,
	CODE_OBJECT_MISSING,
	CODE_NOT_MOVABLE,
	CODE_OBJECT_INACTIVE,
	CODE_ACTOR_COUNT_INVALID,
	CODE_ACTOR_TYPE_INCOMPATIBLE,
	CODE_MANIPULATOR_REQUIRED,
	CODE_MANIPULATOR_INACTIVE,
	CODE_MANIPULATOR_OCCUPIED,
	CODE_HEAVY_CLAW_REQUIRED,
	CODE_HEAVY_CLAW_INACTIVE,
	CODE_POWER_CLASS_INSUFFICIENT,
	CODE_ACTION_UNSUPPORTED,
	CODE_TARGET_NOT_ADJACENT,
	CODE_TARGET_NOT_IN_FRONT,
	CODE_DESTINATION_SAME,
	CODE_DESTINATION_OUT_OF_BOUNDS,
	CODE_DESTINATION_BLOCKED,
	CODE_DESTINATION_OCCUPIED,
	CODE_SURFACE_LEVEL_MISMATCH,
	CODE_INVALID_WEIGHT_CLASS,
	CODE_INVALID_MOVEMENT_REQUIREMENT
]

const POWER_CLASS_RANK: Dictionary = {
	ACTOR_SCOUT: 1,
	ACTOR_ENGINEER: 2,
	ACTOR_HEAVY: 3
}

static func normalize_actor_type(value: Variant) -> String:
	var token: String = str(value).strip_edges().to_lower().replace("-", "_").replace(" ", "_")
	match token:
		"alpha", "v1", "light", "standard":
			return ACTOR_SCOUT
		"beta", "v2", "technical":
			return ACTOR_ENGINEER
		"juggernaut", "v3", "heavy_bipob", "heavy_robot":
			return ACTOR_HEAVY
		_:
			return token if token in ACTOR_TYPES else ACTOR_SCOUT

static func normalize_power_class(value: Variant) -> String:
	return normalize_actor_type(value)

static func is_crate(object_data: Dictionary) -> bool:
	var object_type: String = _object_type(object_data)
	var archetype_id: String = str(object_data.get("archetype_id", "")).strip_edges().to_lower()
	var legacy_type: String = str(object_data.get("legacy_object_type", object_data.get("map_constructor_prefab_id", ""))).strip_edges().to_lower()
	return object_type == "crate" or archetype_id == "crate" or legacy_type in ["crate", "normal_crate", "heavy_crate", "steel_box"]

static func is_movable_entity(object_data: Dictionary) -> bool:
	if object_data.is_empty():
		return false
	var contract: Variant = object_data.get("entity_contract", {})
	if contract is Dictionary and str(Dictionary(contract).get("entity_type", "")).strip_edges().to_lower() == "movable":
		return true
	return object_data.get("movement_requirement", {}) is Dictionary and not Dictionary(object_data.get("movement_requirement", {})).is_empty()

static func normalize_crate_weight(value: Variant) -> String:
	var token: String = str(value).strip_edges().to_lower()
	if token in ["steel", "steel_box", "heavy_crate"]:
		return WEIGHT_HEAVY
	if token in CRATE_WEIGHT_CLASSES:
		return token
	return ""

static func get_movement_requirement(object_data: Dictionary) -> Dictionary:
	if object_data.is_empty():
		return {}
	if is_crate(object_data):
		var raw_weight: Variant = object_data.get("weight_class", object_data.get("crate_type", object_data.get("variant", WEIGHT_NORMAL)))
		var weight_class: String = normalize_crate_weight(raw_weight)
		if weight_class == WEIGHT_HEAVY:
			return {
				"profile_id": "crate_heavy",
				"required_actor_types": [ACTOR_ENGINEER, ACTOR_HEAVY],
				"required_manipulator": MANIPULATOR_HEAVY_CLAW,
				"required_manipulator_level": 1,
				"required_power_class": ACTOR_ENGINEER,
				"movement_mode": MOVEMENT_DRAG
			}
		if weight_class == WEIGHT_NORMAL:
			return {
				"profile_id": "crate_normal",
				"required_actor_types": ACTOR_TYPES.duplicate(),
				"required_manipulator": MANIPULATOR_ARM,
				"required_manipulator_level": 1,
				"required_power_class": ACTOR_SCOUT,
				"movement_mode": MOVEMENT_PUSH
			}
		return {"invalid_weight_class": str(raw_weight)}

	var explicit: Variant = object_data.get("movement_requirement", {})
	if explicit is Dictionary and not Dictionary(explicit).is_empty():
		return _canonicalize_requirement(Dictionary(explicit))

	# Legacy fields are read only as migration input. Canonical serialization uses movement_requirement.
	if bool(object_data.get("heavy_claw_movable", false)):
		return {
			"profile_id": "legacy_heavy_claw",
			"required_actor_types": [ACTOR_ENGINEER, ACTOR_HEAVY],
			"required_manipulator": MANIPULATOR_HEAVY_CLAW,
			"required_manipulator_level": 1,
			"required_power_class": normalize_power_class(object_data.get("required_bipob_power_class", ACTOR_ENGINEER)),
			"movement_mode": MOVEMENT_DRAG
		}
	if bool(object_data.get("movable", false)):
		return {
			"profile_id": "legacy_movable",
			"required_actor_types": ACTOR_TYPES.duplicate(),
			"required_manipulator": MANIPULATOR_ARM,
			"required_manipulator_level": 1,
			"required_power_class": ACTOR_SCOUT,
			"movement_mode": MOVEMENT_PUSH
		}
	return {}

static func normalize_movable_contract(object_data: Dictionary) -> Dictionary:
	var result: Dictionary = object_data.duplicate(true)
	if not is_movable_entity(result) and not is_crate(result) and not bool(result.get("movable", false)) and not bool(result.get("heavy_claw_movable", false)):
		return result
	var requirement: Dictionary = get_movement_requirement(result)
	if not requirement.is_empty() and not requirement.has("invalid_weight_class"):
		result["movement_requirement"] = requirement
	for legacy_field in ["movable", "immovable", "heavy_claw_movable", "heavy_claw_mode", "required_bipob_power_class", "blocked"]:
		result.erase(legacy_field)
	if is_crate(result):
		var weight_class: String = normalize_crate_weight(result.get("weight_class", result.get("crate_type", result.get("variant", WEIGHT_NORMAL))))
		result["weight_class"] = weight_class if not weight_class.is_empty() else WEIGHT_NORMAL
		result.erase("crate_type")
	else:
		result.erase("weight_class")
	return result

static func validate_requirement(requirement: Dictionary, object_data: Dictionary = {}) -> Dictionary:
	if requirement.is_empty():
		return _result(false, CODE_NOT_MOVABLE, object_data, {}, {})
	if requirement.has("invalid_weight_class"):
		return _result(false, CODE_INVALID_WEIGHT_CLASS, object_data, requirement, {"value": requirement.get("invalid_weight_class", "")})
	var required_actor_types: Array = Array(requirement.get("required_actor_types", []))
	var required_manipulator: String = str(requirement.get("required_manipulator", "")).strip_edges().to_lower()
	var required_power_class: String = normalize_power_class(requirement.get("required_power_class", ACTOR_SCOUT))
	var movement_mode: String = str(requirement.get("movement_mode", "")).strip_edges().to_lower()
	if required_actor_types.is_empty() or required_manipulator not in MANIPULATOR_TYPES or required_power_class not in ACTOR_TYPES or movement_mode not in MOVEMENT_MODES:
		return _result(false, CODE_INVALID_MOVEMENT_REQUIREMENT, object_data, requirement, {
			"required_actor_types": required_actor_types,
			"required_manipulator": required_manipulator,
			"required_power_class": required_power_class,
			"movement_mode": movement_mode
		})
	return _result(true, CODE_VALID, object_data, requirement, {})

static func preview_action(actor: Dictionary, object_data: Dictionary, action_id: String, destination_context: Dictionary = {}) -> Dictionary:
	if object_data.is_empty():
		return _result(false, CODE_OBJECT_MISSING, object_data, {}, {})
	var requirement: Dictionary = get_movement_requirement(object_data)
	var requirement_check: Dictionary = validate_requirement(requirement, object_data)
	if not bool(requirement_check.get("success", false)):
		return requirement_check
	if not is_movable_entity(object_data) and not is_crate(object_data) and not bool(object_data.get("movable", false)) and not bool(object_data.get("heavy_claw_movable", false)):
		return _result(false, CODE_NOT_MOVABLE, object_data, requirement, {})
	if _is_inactive(object_data):
		return _result(false, CODE_OBJECT_INACTIVE, object_data, requirement, {})
	if int(actor.get("actor_count", 1)) != 1:
		return _result(false, CODE_ACTOR_COUNT_INVALID, object_data, requirement, {"actor_count": int(actor.get("actor_count", 1))})

	var actor_type: String = normalize_actor_type(actor.get("actor_type", actor.get("power_class", ACTOR_SCOUT)))
	var required_actor_types: Array = Array(requirement.get("required_actor_types", []))
	if not required_actor_types.has(actor_type):
		return _result(false, CODE_ACTOR_TYPE_INCOMPATIBLE, object_data, requirement, {"actor_type": actor_type})

	var actor_power_class: String = normalize_power_class(actor.get("power_class", actor_type))
	var required_power_class: String = normalize_power_class(requirement.get("required_power_class", ACTOR_SCOUT))
	if _power_rank(actor_power_class) < _power_rank(required_power_class):
		return _result(false, CODE_POWER_CLASS_INSUFFICIENT, object_data, requirement, {
			"power_class": actor_power_class,
			"required_power_class": required_power_class
		})

	var required_manipulator: String = str(requirement.get("required_manipulator", MANIPULATOR_NONE)).strip_edges().to_lower()
	var required_level: int = maxi(1, int(requirement.get("required_manipulator_level", 1)))
	if required_manipulator == MANIPULATOR_ARM:
		if int(actor.get("manipulator_level", 0)) < required_level:
			return _result(false, CODE_MANIPULATOR_REQUIRED, object_data, requirement, {"required_level": required_level})
		if not bool(actor.get("manipulator_active", true)):
			return _result(false, CODE_MANIPULATOR_INACTIVE, object_data, requirement, {})
		if bool(actor.get("manipulator_occupied", false)):
			return _result(false, CODE_MANIPULATOR_OCCUPIED, object_data, requirement, {})
	elif required_manipulator == MANIPULATOR_HEAVY_CLAW:
		if int(actor.get("heavy_claw_level", 0)) < required_level:
			return _result(false, CODE_HEAVY_CLAW_REQUIRED, object_data, requirement, {"required_level": required_level})
		if not bool(actor.get("heavy_claw_active", actor.get("heavy_claw_capability", true))):
			return _result(false, CODE_HEAVY_CLAW_INACTIVE, object_data, requirement, {})
		# A regular manipulator may hold an item while Heavy Claw is used.

	var normalized_action: String = action_id.strip_edges().to_lower()
	var movement_mode: String = str(requirement.get("movement_mode", MOVEMENT_PUSH)).strip_edges().to_lower()
	if not _action_matches_mode(normalized_action, movement_mode):
		return _result(false, CODE_ACTION_UNSUPPORTED, object_data, requirement, {"action_id": normalized_action})

	var object_cell: Vector2i = _to_cell(object_data.get("position", Vector2i(-1, -1)), Vector2i(-1, -1))
	var actor_cell: Vector2i = _to_cell(actor.get("actor_position", Vector2i(-1, -1)), Vector2i(-1, -1))
	if bool(destination_context.get("validate_target_relation", true)) and actor_cell.x >= 0 and object_cell.x >= 0:
		if _manhattan(actor_cell, object_cell) != 1:
			return _result(false, CODE_TARGET_NOT_ADJACENT, object_data, requirement, {"actor_cell": actor_cell, "object_cell": object_cell})
		var facing: Vector2i = _to_cell(actor.get("facing_direction", Vector2i.ZERO), Vector2i.ZERO)
		if facing != Vector2i.ZERO and object_cell != actor_cell + facing:
			return _result(false, CODE_TARGET_NOT_IN_FRONT, object_data, requirement, {"actor_cell": actor_cell, "object_cell": object_cell})

	if bool(destination_context.get("validate_destination", false)):
		var from_cell: Vector2i = _to_cell(destination_context.get("from_cell", object_cell), object_cell)
		var to_cell: Vector2i = _to_cell(destination_context.get("to_cell", from_cell), from_cell)
		if to_cell == from_cell:
			return _result(false, CODE_DESTINATION_SAME, object_data, requirement, {"from_cell": from_cell, "to_cell": to_cell})
		if not bool(destination_context.get("in_bounds", false)):
			return _result(false, CODE_DESTINATION_OUT_OF_BOUNDS, object_data, requirement, {"to_cell": to_cell})
		if not bool(destination_context.get("surface_move_allowed", true)):
			return _result(false, CODE_SURFACE_LEVEL_MISMATCH, object_data, requirement, {"to_cell": to_cell})
		if not bool(destination_context.get("destination_passable", false)):
			return _result(false, CODE_DESTINATION_BLOCKED, object_data, requirement, {"to_cell": to_cell})
		if bool(destination_context.get("destination_occupied", false)):
			return _result(false, CODE_DESTINATION_OCCUPIED, object_data, requirement, {"to_cell": to_cell})

	return _result(true, CODE_VALID, object_data, requirement, {
		"actor_type": actor_type,
		"power_class": actor_power_class,
		"action_id": normalized_action,
		"movement_mode": movement_mode
	})

static func _canonicalize_requirement(requirement: Dictionary) -> Dictionary:
	var result: Dictionary = requirement.duplicate(true)
	var actor_types: Array[String] = []
	for value in Array(result.get("required_actor_types", [])):
		var actor_type: String = normalize_actor_type(value)
		if not actor_types.has(actor_type):
			actor_types.append(actor_type)
	result["required_actor_types"] = actor_types
	result["required_manipulator"] = str(result.get("required_manipulator", MANIPULATOR_NONE)).strip_edges().to_lower()
	result["required_manipulator_level"] = maxi(1, int(result.get("required_manipulator_level", 1)))
	result["required_power_class"] = normalize_power_class(result.get("required_power_class", ACTOR_SCOUT))
	result["movement_mode"] = str(result.get("movement_mode", MOVEMENT_PUSH)).strip_edges().to_lower()
	return result

static func _action_matches_mode(action_id: String, movement_mode: String) -> bool:
	match movement_mode:
		MOVEMENT_DRAG:
			return action_id in ["push", "pull", "attach", "drag", "move"]
		MOVEMENT_DIRECT:
			return action_id in ["push", "pull", "move"]
		MOVEMENT_PUSH:
			return action_id in ["push", "move"]
		_:
			return false

static func _is_inactive(object_data: Dictionary) -> bool:
	var state: String = str(object_data.get("state", object_data.get("status", ""))).strip_edges().to_lower()
	return state in ["damaged", "broken", "destroyed", "disabled"] or bool(object_data.get("damaged", false)) or bool(object_data.get("broken", false)) or bool(object_data.get("destroyed", false))

static func _object_type(object_data: Dictionary) -> String:
	return str(object_data.get("object_type", object_data.get("type", ""))).strip_edges().to_lower()

static func _power_rank(power_class: String) -> int:
	return int(POWER_CLASS_RANK.get(normalize_power_class(power_class), 0))

static func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

static func _to_cell(value: Variant, fallback: Vector2i) -> Vector2i:
	if value is Vector2i:
		return Vector2i(value)
	if value is Vector2:
		return Vector2i(value)
	if value is Array and Array(value).size() >= 2:
		return Vector2i(int(Array(value)[0]), int(Array(value)[1]))
	if value is Dictionary:
		var data: Dictionary = Dictionary(value)
		return Vector2i(int(data.get("x", fallback.x)), int(data.get("y", fallback.y)))
	return fallback

static func _message_for_code(code: String) -> String:
	match code:
		CODE_VALID: return "Movement available."
		CODE_OBJECT_MISSING: return "Object not found."
		CODE_NOT_MOVABLE: return "Object is not movable."
		CODE_OBJECT_INACTIVE: return "Object cannot be moved in its current state."
		CODE_ACTOR_COUNT_INVALID: return "Exactly one Bipob must move this object."
		CODE_ACTOR_TYPE_INCOMPATIBLE: return "This Bipob type cannot move the object."
		CODE_MANIPULATOR_REQUIRED: return "Manipulator required."
		CODE_MANIPULATOR_INACTIVE: return "Manipulator is inactive."
		CODE_MANIPULATOR_OCCUPIED: return "Manipulator must be free."
		CODE_HEAVY_CLAW_REQUIRED: return "Heavy Claw required."
		CODE_HEAVY_CLAW_INACTIVE: return "Heavy Claw is inactive."
		CODE_POWER_CLASS_INSUFFICIENT: return "Bipob power class is insufficient."
		CODE_ACTION_UNSUPPORTED: return "Movement action is unsupported."
		CODE_TARGET_NOT_ADJACENT: return "Target must be adjacent."
		CODE_TARGET_NOT_IN_FRONT: return "Face the object to move it."
		CODE_DESTINATION_SAME: return "Object is already there."
		CODE_DESTINATION_OUT_OF_BOUNDS: return "Destination is outside the map."
		CODE_DESTINATION_BLOCKED: return "Destination is blocked."
		CODE_DESTINATION_OCCUPIED: return "Destination is occupied."
		CODE_SURFACE_LEVEL_MISMATCH: return "Destination surface level is incompatible."
		CODE_INVALID_WEIGHT_CLASS: return "Crate weight class is invalid."
		CODE_INVALID_MOVEMENT_REQUIREMENT: return "Movement requirement profile is invalid."
		_: return "Movement unavailable."

static func _result(success: bool, code: String, object_data: Dictionary, requirement: Dictionary, details: Dictionary) -> Dictionary:
	return {
		"ok": success,
		"success": success,
		"code": code,
		"reason_code": code,
		"message": _message_for_code(code),
		"object_id": str(object_data.get("id", "")),
		"movement_requirement": requirement.duplicate(true),
		"details": details.duplicate(true)
	}
