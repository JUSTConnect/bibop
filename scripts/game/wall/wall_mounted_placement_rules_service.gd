extends RefCounted
class_name WallMountedPlacementRulesService

# Wall-mounted placement and interaction helper rules.
# Foundation only: no Map Constructor UI, no scene mutation, no renderer integration.

const FacingSideUtilsRef = preload("res://scripts/visual/facing_side_utils.gd")

const PLACEMENT_WALL_MOUNTED: String = "wall_mounted"
const PLACEMENT_FLOOR: String = "floor"
const PLACEMENT_WALL: String = "wall"

const DEVICE_LIGHT: String = "light"
const DEVICE_POWER_SOCKET: String = "power_socket"
const DEVICE_FUSE_BOX: String = "fuse_box"
const DEVICE_POWER_SWITCHER: String = "power_switcher"
const DEVICE_CHAIN_SWITCHER: String = "chain_switcher"
const DEVICE_LIGHT_SWITCH: String = "light_switch"
const DEVICE_TERMINAL: String = "terminal"

const HEIGHT_LOW: String = "low"
const HEIGHT_MID: String = "mid"
const HEIGHT_HIGH: String = "high"
const HEIGHT_UNSPECIFIED: String = "unspecified"

const DEFAULT_MAX_OBJECTS_PER_WALL_SIDE: int = 99

static func is_wall_mounted_object(object_data: Dictionary) -> bool:
	if str(object_data.get("placement", "")) == PLACEMENT_WALL_MOUNTED:
		return true
	if str(object_data.get("placement_mode", "")) == PLACEMENT_WALL_MOUNTED:
		return true
	if bool(object_data.get("is_wall_mounted", false)):
		return true
	var kind: String = str(object_data.get("device_kind", object_data.get("kind", ""))).strip_edges().to_lower()
	return kind in get_default_wall_mounted_kinds()

static func get_default_wall_mounted_kinds() -> Array[String]:
	return [
		DEVICE_LIGHT,
		DEVICE_POWER_SOCKET,
		DEVICE_FUSE_BOX,
		DEVICE_POWER_SWITCHER,
		DEVICE_CHAIN_SWITCHER,
		DEVICE_LIGHT_SWITCH,
		DEVICE_TERMINAL
	]

static func can_place_in_wall_cell(object_data: Dictionary, wall_cell_data: Dictionary) -> Dictionary:
	if not is_wall_mounted_object(object_data):
		return {"ok": false, "message": "Object is not wall-mounted."}
	if not bool(wall_cell_data.get("has_wall", wall_cell_data.get("is_wall", false))):
		return {"ok": false, "message": "Target cell has no wall."}
	return {"ok": true, "message": "Wall-mounted object can be placed in wall cell."}

static func normalize_wall_mounted_object(object_data: Dictionary, wall_side: String = "") -> Dictionary:
	var result: Dictionary = object_data.duplicate(true)
	result["placement"] = PLACEMENT_WALL_MOUNTED
	result["is_wall_mounted"] = true
	result["does_not_block_movement"] = true
	result["blocks_movement"] = false
	result["changes_passability"] = false
	if not wall_side.is_empty():
		result["wall_side"] = FacingSideUtilsRef.normalize_wall_side(wall_side)
	elif result.has("wall_side"):
		result["wall_side"] = FacingSideUtilsRef.normalize_wall_side(str(result.get("wall_side", "")))
	elif result.has("facing"):
		result["wall_side"] = FacingSideUtilsRef.normalize_wall_side(str(result.get("facing", "")))
	else:
		result["wall_side"] = FacingSideUtilsRef.WALL_SIDE_SW
	result["interaction_side"] = result["wall_side"]
	if not result.has("mount_height"):
		result["mount_height"] = infer_default_mount_height(result)
	return result

static func infer_default_mount_height(object_data: Dictionary) -> String:
	var kind: String = str(object_data.get("device_kind", object_data.get("kind", ""))).strip_edges().to_lower()
	match kind:
		DEVICE_LIGHT:
			return HEIGHT_HIGH
		DEVICE_POWER_SOCKET:
			return HEIGHT_LOW
		DEVICE_FUSE_BOX, DEVICE_POWER_SWITCHER, DEVICE_CHAIN_SWITCHER, DEVICE_LIGHT_SWITCH, DEVICE_TERMINAL:
			return HEIGHT_MID
		_:
			return HEIGHT_UNSPECIFIED

static func normalize_direct_wall_cell_mount_object(object_data: Dictionary, wall_side: String, selected_wall_cell: Vector2i, anchor_floor_cell: Vector2i = Vector2i(-1, -1)) -> Dictionary:
	var result: Dictionary = normalize_wall_mounted_object(object_data, wall_side)
	result["placement_mode"] = PLACEMENT_WALL_MOUNTED
	result["direct_wall_cell_mount"] = true
	result["attached_wall_cell"] = selected_wall_cell
	result["anchor_floor_cell"] = anchor_floor_cell
	result["position"] = selected_wall_cell
	result["is_wall_mounted"] = true
	result["does_not_block_movement"] = true
	result["blocks_movement"] = false
	result["changes_passability"] = false
	result["interaction_side"] = result["wall_side"]
	return result

static func can_share_wall_side(existing_objects: Array[Dictionary], new_object: Dictionary, wall_side: String, max_objects: int = DEFAULT_MAX_OBJECTS_PER_WALL_SIDE) -> Dictionary:
	var normalized_side: String = FacingSideUtilsRef.normalize_wall_side(wall_side)
	var count_on_side: int = 0
	for existing in existing_objects:
		if not is_wall_mounted_object(existing):
			continue
		var existing_side: String = FacingSideUtilsRef.normalize_wall_side(str(existing.get("wall_side", existing.get("interaction_side", ""))))
		if existing_side == normalized_side:
			count_on_side += 1
	if count_on_side >= max_objects:
		return {"ok": false, "message": "Wall side is full.", "count_on_side": count_on_side, "max_objects": max_objects}
	return {"ok": true, "message": "Wall side can be shared.", "count_on_side": count_on_side, "max_objects": max_objects}

static func can_interact_from_cell_side(object_data: Dictionary, approach_direction: Vector2i) -> bool:
	var normalized: Dictionary = normalize_wall_mounted_object(object_data)
	var side: String = str(normalized.get("interaction_side", normalized.get("wall_side", "")))
	return FacingSideUtilsRef.can_interact_from_side(side, approach_direction)

static func get_required_interaction_direction(object_data: Dictionary) -> Vector2i:
	var normalized: Dictionary = normalize_wall_mounted_object(object_data)
	return FacingSideUtilsRef.wall_side_to_interaction_direction(str(normalized.get("interaction_side", normalized.get("wall_side", ""))))

static func does_change_passability(object_data: Dictionary) -> bool:
	if is_wall_mounted_object(object_data):
		return false
	return bool(object_data.get("changes_passability", object_data.get("blocks_movement", false)))

static func build_placement_payload(object_data: Dictionary, wall_cell_data: Dictionary, wall_side: String, existing_objects: Array[Dictionary] = []) -> Dictionary:
	var normalized_object: Dictionary = normalize_wall_mounted_object(object_data, wall_side)
	var placement_check: Dictionary = can_place_in_wall_cell(normalized_object, wall_cell_data)
	var sharing_check: Dictionary = can_share_wall_side(existing_objects, normalized_object, str(normalized_object.get("wall_side", wall_side)))
	var ok: bool = bool(placement_check.get("ok", false)) and bool(sharing_check.get("ok", false))
	return {
		"ok": ok,
		"message": "Wall-mounted placement valid." if ok else str(placement_check.get("message", sharing_check.get("message", "Invalid placement."))),
		"object_data": normalized_object,
		"wall_side": str(normalized_object.get("wall_side", wall_side)),
		"interaction_side": str(normalized_object.get("interaction_side", wall_side)),
		"required_interaction_direction": get_required_interaction_direction(normalized_object),
		"changes_passability": false,
		"placement_check": placement_check,
		"sharing_check": sharing_check
	}

static func build_interaction_payload(object_data: Dictionary, approach_direction: Vector2i) -> Dictionary:
	var normalized_object: Dictionary = normalize_wall_mounted_object(object_data)
	var can_interact: bool = can_interact_from_cell_side(normalized_object, approach_direction)
	return {
		"can_interact": can_interact,
		"message": "Interaction available." if can_interact else "Object can be used only from its mounted side.",
		"wall_side": str(normalized_object.get("wall_side", "")),
		"interaction_side": str(normalized_object.get("interaction_side", "")),
		"required_interaction_direction": get_required_interaction_direction(normalized_object),
		"approach_direction": approach_direction
	}

static func get_wall_mounted_dropdown_options() -> Array[Dictionary]:
	return [
		{"id": DEVICE_LIGHT, "label": "Light"},
		{"id": DEVICE_POWER_SOCKET, "label": "Power Socket"},
		{"id": DEVICE_FUSE_BOX, "label": "Fuse Box"},
		{"id": DEVICE_POWER_SWITCHER, "label": "Power Switcher"},
		{"id": DEVICE_CHAIN_SWITCHER, "label": "Chain Switcher"},
		{"id": DEVICE_LIGHT_SWITCH, "label": "Light Switch"},
		{"id": DEVICE_TERMINAL, "label": "Terminal"}
	]
