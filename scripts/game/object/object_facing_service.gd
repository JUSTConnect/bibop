extends RefCounted
class_name ObjectFacingService

const FACING_SIDE_SW := "SW"
const FACING_SIDE_SE := "SE"
const FRONT_SIDE_HINT := "Interact from the front side."
const FRONT_SIDE_REQUIRED_REASON := "wrong_front_side"
const SUPPORTED_FACING_SIDES: Array[String] = [FACING_SIDE_SW, FACING_SIDE_SE]
const FRONT_ACCESS_OBJECT_TYPES: Array[String] = [
	"terminal",
	"fuse_box",
	"power_switcher",
	"light_switcher",
	"light_switch",
	"case",
	"door"
]
const FRONT_ACCESS_OBJECT_GROUPS: Array[String] = ["terminal", "door"]

static func normalize_facing_side(value: Variant, fallback: String = FACING_SIDE_SW) -> String:
	var side: String = str(value).strip_edges().to_upper()
	if side in SUPPORTED_FACING_SIDES:
		return side
	var fallback_side: String = str(fallback).strip_edges().to_upper()
	return fallback_side if fallback_side in SUPPORTED_FACING_SIDES else FACING_SIDE_SW

static func get_facing_side(object_data: Dictionary) -> String:
	if object_data.has("facing_side"):
		return normalize_facing_side(object_data.get("facing_side", FACING_SIDE_SW))
	var legacy_side: String = str(object_data.get("front_side", object_data.get("interaction_side", ""))).strip_edges()
	if not legacy_side.is_empty():
		return normalize_facing_side(legacy_side)
	var legacy_direction: String = str(object_data.get("facing_dir", object_data.get("direction", object_data.get("facing", "")))).strip_edges().to_lower()
	match legacy_direction:
		"se", "southeast", "south_east", "right", "east":
			return FACING_SIDE_SE
		"sw", "southwest", "south_west", "left", "south":
			return FACING_SIDE_SW
	return FACING_SIDE_SW

static func should_require_front_side(object_data: Dictionary) -> bool:
	if object_data.is_empty():
		return false
	if bool(object_data.get("ignore_facing_side_for_interaction", false)):
		return false
	var object_type: String = str(object_data.get("object_type", object_data.get("type", ""))).strip_edges().to_lower()
	var object_group: String = str(object_data.get("object_group", object_data.get("group", ""))).strip_edges().to_lower()
	if object_group in FRONT_ACCESS_OBJECT_GROUPS or object_type in ["terminal", "door"]:
		return true
	var placement_mode: String = str(object_data.get("placement_mode", object_data.get("placement", ""))).strip_edges().to_lower()
	if placement_mode != "wall_mounted":
		return false
	for required_type in FRONT_ACCESS_OBJECT_TYPES:
		if object_type == required_type or object_type.contains(required_type):
			return true
	return false

static func get_front_side_delta(facing_side: String) -> Vector2i:
	match normalize_facing_side(facing_side):
		"SE":
			return Vector2i(1, 0)
		"SW":
			return Vector2i(0, 1)
	return Vector2i(0, 1)

static func get_valid_interaction_cells(object_data: Dictionary, object_cell: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if not should_require_front_side(object_data):
		return cells
	cells.append(object_cell + get_front_side_delta(get_facing_side(object_data)))
	return cells

static func can_actor_interact_from_cell(object_data: Dictionary, object_cell: Vector2i, actor_cell: Vector2i) -> bool:
	if not should_require_front_side(object_data):
		return true
	return get_valid_interaction_cells(object_data, object_cell).has(actor_cell)

static func build_interaction_gate(object_data: Dictionary, object_cell: Vector2i, actor_cell: Vector2i) -> Dictionary:
	if can_actor_interact_from_cell(object_data, object_cell, actor_cell):
		return {"success": true, "reason": "ok", "message": "", "valid_interaction_cells": get_valid_interaction_cells(object_data, object_cell), "facing_side": get_facing_side(object_data)}
	return {"success": false, "reason": FRONT_SIDE_REQUIRED_REASON, "message": FRONT_SIDE_HINT, "valid_interaction_cells": get_valid_interaction_cells(object_data, object_cell), "facing_side": get_facing_side(object_data)}
