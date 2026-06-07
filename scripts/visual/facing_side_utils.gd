extends RefCounted
class_name FacingSideUtils

# Shared facing-side helpers for isometric object previews.
# Data/helper-only: does not draw, mutate renderer state, or edit world objects directly.

const FLOOR_NW: String = "nw"
const FLOOR_NE: String = "ne"
const FLOOR_SW: String = "sw"
const FLOOR_SE: String = "se"

const WALL_SIDE_NORTH: String = "north"
const WALL_SIDE_EAST: String = "east"
const WALL_SIDE_SOUTH: String = "south"
const WALL_SIDE_WEST: String = "west"
const WALL_SIDE_NW: String = "nw"
const WALL_SIDE_NE: String = "ne"
const WALL_SIDE_SW: String = "sw"
const WALL_SIDE_SE: String = "se"

const MIRROR_NONE: String = "none"
const MIRROR_HORIZONTAL: String = "horizontal"
const MIRROR_VERTICAL: String = "vertical"
const MIRROR_UNSAFE: String = "unsafe"

const FLOOR_FACING_VALUES: Array[String] = [FLOOR_NW, FLOOR_NE, FLOOR_SW, FLOOR_SE]
const WALL_SIDE_VALUES: Array[String] = [
	WALL_SIDE_NORTH,
	WALL_SIDE_EAST,
	WALL_SIDE_SOUTH,
	WALL_SIDE_WEST,
	WALL_SIDE_NW,
	WALL_SIDE_NE,
	WALL_SIDE_SW,
	WALL_SIDE_SE
]

static func normalize_floor_facing(value: String, fallback: String = FLOOR_SE) -> String:
	var normalized: String = str(value).strip_edges().to_lower()
	if FLOOR_FACING_VALUES.has(normalized):
		return normalized
	return fallback if FLOOR_FACING_VALUES.has(fallback) else FLOOR_SE

static func normalize_wall_side(value: String, fallback: String = WALL_SIDE_SW) -> String:
	var normalized: String = str(value).strip_edges().to_lower()
	if WALL_SIDE_VALUES.has(normalized):
		return normalized
	return fallback if WALL_SIDE_VALUES.has(fallback) else WALL_SIDE_SW

static func is_floor_facing(value: String) -> bool:
	return FLOOR_FACING_VALUES.has(str(value).strip_edges().to_lower())

static func is_wall_side(value: String) -> bool:
	return WALL_SIDE_VALUES.has(str(value).strip_edges().to_lower())

static func floor_facing_to_grid_direction(value: String) -> Vector2i:
	match normalize_floor_facing(value):
		FLOOR_NW:
			return Vector2i(0, -1)
		FLOOR_NE:
			return Vector2i(1, 0)
		FLOOR_SW:
			return Vector2i(-1, 0)
		FLOOR_SE:
			return Vector2i(0, 1)
		_:
			return Vector2i(0, 1)

static func grid_direction_to_floor_facing(direction: Vector2i) -> String:
	var abs_x: int = abs(direction.x)
	var abs_y: int = abs(direction.y)
	if abs_x >= abs_y:
		return FLOOR_NE if direction.x >= 0 else FLOOR_SW
	return FLOOR_SE if direction.y >= 0 else FLOOR_NW

static func wall_side_to_interaction_direction(side: String) -> Vector2i:
	match normalize_wall_side(side):
		WALL_SIDE_NORTH, WALL_SIDE_NW:
			return Vector2i(0, -1)
		WALL_SIDE_EAST, WALL_SIDE_NE:
			return Vector2i(1, 0)
		WALL_SIDE_SOUTH, WALL_SIDE_SE:
			return Vector2i(0, 1)
		WALL_SIDE_WEST, WALL_SIDE_SW:
			return Vector2i(-1, 0)
		_:
			return Vector2i(-1, 0)

static func wall_side_to_floor_facing(side: String) -> String:
	return grid_direction_to_floor_facing(wall_side_to_interaction_direction(side))

static func can_interact_from_side(object_wall_side: String, approach_direction: Vector2i) -> bool:
	return wall_side_to_interaction_direction(object_wall_side) == approach_direction

static func get_mirror_plan_for_floor_facing(source_facing: String, target_facing: String) -> Dictionary:
	var source: String = normalize_floor_facing(source_facing)
	var target: String = normalize_floor_facing(target_facing)
	if source == target:
		return {"can_use": true, "mirror": MIRROR_NONE, "reason": "same_facing"}
	# SW <-> SE is usually a safe horizontal mirror for many floor objects in this projection.
	if (source == FLOOR_SW and target == FLOOR_SE) or (source == FLOOR_SE and target == FLOOR_SW):
		return {"can_use": true, "mirror": MIRROR_HORIZONTAL, "reason": "sw_se_horizontal_mirror"}
	# NW <-> NE may be safe only for symmetrical top/back views. Mark as unsafe-by-default.
	if (source == FLOOR_NW and target == FLOOR_NE) or (source == FLOOR_NE and target == FLOOR_NW):
		return {"can_use": false, "mirror": MIRROR_UNSAFE, "reason": "nw_ne_requires_specific_asset_or_manual_approval"}
	return {"can_use": false, "mirror": MIRROR_UNSAFE, "reason": "different_visible_face_requires_asset"}

static func resolve_visual_facing_asset(
	asset_by_facing: Dictionary,
	target_facing: String,
	preferred_source_order: Array[String] = []
) -> Dictionary:
	var target: String = normalize_floor_facing(target_facing)
	if asset_by_facing.has(target):
		return {
			"ok": true,
			"asset": asset_by_facing.get(target),
			"source_facing": target,
			"target_facing": target,
			"mirror": MIRROR_NONE,
			"used_fallback": false
		}
	var source_order: Array[String] = preferred_source_order.duplicate()
	if source_order.is_empty():
		source_order = FLOOR_FACING_VALUES.duplicate()
	for source_variant in source_order:
		var source: String = normalize_floor_facing(source_variant)
		if not asset_by_facing.has(source):
			continue
		var mirror_plan: Dictionary = get_mirror_plan_for_floor_facing(source, target)
		if bool(mirror_plan.get("can_use", false)):
			return {
				"ok": true,
				"asset": asset_by_facing.get(source),
				"source_facing": source,
				"target_facing": target,
				"mirror": str(mirror_plan.get("mirror", MIRROR_NONE)),
				"used_fallback": true,
				"reason": str(mirror_plan.get("reason", ""))
			}
	return {
		"ok": false,
		"asset": null,
		"source_facing": "",
		"target_facing": target,
		"mirror": MIRROR_UNSAFE,
		"used_fallback": true,
		"reason": "missing_asset_and_no_safe_mirror"
	}

static func get_dropdown_options_for_floor_facing() -> Array[Dictionary]:
	return [
		{"id": FLOOR_NW, "label": "NW"},
		{"id": FLOOR_NE, "label": "NE"},
		{"id": FLOOR_SW, "label": "SW"},
		{"id": FLOOR_SE, "label": "SE"}
	]

static func get_dropdown_options_for_wall_side() -> Array[Dictionary]:
	return [
		{"id": WALL_SIDE_NW, "label": "NW wall side"},
		{"id": WALL_SIDE_NE, "label": "NE wall side"},
		{"id": WALL_SIDE_SW, "label": "SW wall side"},
		{"id": WALL_SIDE_SE, "label": "SE wall side"}
	]

static func make_facing_update_result(old_facing: String, new_facing: String, asset_by_facing: Dictionary = {}) -> Dictionary:
	var old_value: String = normalize_floor_facing(old_facing)
	var new_value: String = normalize_floor_facing(new_facing)
	return {
		"old_facing": old_value,
		"new_facing": new_value,
		"changed": old_value != new_value,
		"visual_resolution": resolve_visual_facing_asset(asset_by_facing, new_value) if not asset_by_facing.is_empty() else {}
	}
