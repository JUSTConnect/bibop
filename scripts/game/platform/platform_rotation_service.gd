extends RefCounted
class_name PlatformRotationService

const PlatformTypesRef = preload("res://scripts/game/platform/platform_types.gd")
const PlatformMechanismServiceRef = preload("res://scripts/game/platform/platform_mechanism_service.gd")

static func get_rotation_center_for_cells(cells: Array[Vector2i]) -> Vector2:
	var bounds: Dictionary = PlatformMechanismServiceRef.get_cell_bounds(cells)
	if not bool(bounds.get("ok", false)):
		return Vector2.ZERO
	var min_x: float = float(bounds.get("min_x", 0))
	var min_y: float = float(bounds.get("min_y", 0))
	var width: float = float(bounds.get("width", 1))
	var height: float = float(bounds.get("height", 1))
	return Vector2(min_x + (width - 1.0) * 0.5, min_y + (height - 1.0) * 0.5)

static func rotate_cell_around_center(cell: Vector2i, center: Vector2, action: String) -> Vector2i:
	var normalized_action: String = PlatformTypesRef.normalize_platform_action(action)
	var relative: Vector2 = Vector2(float(cell.x), float(cell.y)) - center
	var rotated: Vector2 = relative
	if normalized_action == PlatformTypesRef.ACTION_ROTATE_RIGHT:
		rotated = Vector2(-relative.y, relative.x)
	elif normalized_action == PlatformTypesRef.ACTION_ROTATE_LEFT:
		rotated = Vector2(relative.y, -relative.x)
	else:
		return cell
	var target: Vector2 = center + rotated
	return Vector2i(int(round(target.x)), int(round(target.y)))

static func build_rotation_cell_map(cells: Array[Vector2i], action: String) -> Dictionary:
	var center: Vector2 = get_rotation_center_for_cells(cells)
	var result: Dictionary = {}
	for cell in cells:
		result[cell] = rotate_cell_around_center(cell, center, action)
	return result

static func rotate_direction(direction: String, action: String) -> String:
	return PlatformTypesRef.rotate_direction(direction, action)

static func is_valid_rotation_action(action: String) -> bool:
	var normalized_action: String = PlatformTypesRef.normalize_platform_action(action)
	return normalized_action == PlatformTypesRef.ACTION_ROTATE_LEFT or normalized_action == PlatformTypesRef.ACTION_ROTATE_RIGHT

static func validate_rotation_plan(members: Array, action: String, blocked_cells: Array[Vector2i] = []) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var normalized_action: String = PlatformTypesRef.normalize_platform_action(action)
	if not is_valid_rotation_action(normalized_action):
		errors.append("Platform rotation action must be rotate_left or rotate_right.")
	var cells: Array[Vector2i] = PlatformMechanismServiceRef.get_member_cells(members)
	if cells.is_empty():
		errors.append("Cannot rotate platform mechanism without cells.")
	if not PlatformMechanismServiceRef.is_square_footprint(cells, true):
		errors.append("Rotating platform mechanism must be a filled square footprint.")
	var rotation_map: Dictionary = {}
	if errors.is_empty():
		rotation_map = build_rotation_cell_map(cells, normalized_action)
		var member_lookup: Dictionary = {}
		for cell in cells:
			member_lookup["%s:%s" % [cell.x, cell.y]] = true
		var blocked_lookup: Dictionary = {}
		for blocked_cell in blocked_cells:
			blocked_lookup["%s:%s" % [blocked_cell.x, blocked_cell.y]] = true
		for source_cell_variant in rotation_map.keys():
			var target_cell: Vector2i = rotation_map.get(source_cell_variant)
			var target_key: String = "%s:%s" % [target_cell.x, target_cell.y]
			if blocked_lookup.has(target_key) and not member_lookup.has(target_key):
				errors.append("Rotation target cell is blocked: %s" % target_key)
	if cells.size() == 1:
		warnings.append("Single-cell rotator only changes carried object facing unless visual rotation is enabled.")
	return {
		"ok": errors.is_empty(),
		"action": normalized_action,
		"cells": cells,
		"center": get_rotation_center_for_cells(cells),
		"rotation_map": rotation_map,
		"errors": errors,
		"warnings": warnings
	}

static func plan_carried_cell_rotation(carried_entries: Array[Dictionary], center: Vector2, action: String) -> Array[Dictionary]:
	var planned: Array[Dictionary] = []
	for entry in carried_entries:
		var source_cell: Vector2i = PlatformMechanismServiceRef.normalize_cell(entry.get("cell", entry.get("position", {})))
		var target_cell: Vector2i = rotate_cell_around_center(source_cell, center, action)
		var source_direction: String = str(entry.get("direction", entry.get("facing", "")))
		var target_direction: String = source_direction
		if not source_direction.strip_edges().is_empty():
			target_direction = rotate_direction(source_direction, action)
		var planned_entry: Dictionary = entry.duplicate(true)
		planned_entry["source_cell"] = source_cell
		planned_entry["target_cell"] = target_cell
		planned_entry["source_direction"] = source_direction
		planned_entry["target_direction"] = target_direction
		planned.append(planned_entry)
	return planned

static func build_rotation_plan(members: Array, carried_entries: Array[Dictionary], action: String, blocked_cells: Array[Vector2i] = []) -> Dictionary:
	var validation: Dictionary = validate_rotation_plan(members, action, blocked_cells)
	if not bool(validation.get("ok", false)):
		validation["carried_plan"] = []
		return validation
	var center: Vector2 = Vector2(validation.get("center", Vector2.ZERO))
	validation["carried_plan"] = plan_carried_cell_rotation(carried_entries, center, str(validation.get("action", action)))
	return validation
