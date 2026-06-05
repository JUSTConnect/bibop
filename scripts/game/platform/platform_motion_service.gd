extends RefCounted
class_name PlatformMotionService

const PlatformTypesRef = preload("res://scripts/game/platform/platform_types.gd")
const PlatformMechanismServiceRef = preload("res://scripts/game/platform/platform_mechanism_service.gd")

static func get_surface_level_for_platform(platform_data: Dictionary) -> int:
	return PlatformTypesRef.clamp_platform_level(int(platform_data.get("platform_level", platform_data.get("current_level", 0))), int(platform_data.get("max_level", 1)))

static func get_surface_level_for_cell(cell: Vector2i, platform_lookup: Dictionary = {}, ground_level_lookup: Dictionary = {}) -> int:
	var key: String = "%s:%s" % [cell.x, cell.y]
	if platform_lookup.has(key):
		var platform_data: Dictionary = Dictionary(platform_lookup.get(key, {}))
		return get_surface_level_for_platform(platform_data)
	if ground_level_lookup.has(key):
		return maxi(int(ground_level_lookup.get(key, 0)), 0)
	return 0

static func can_move_between_surface_levels(from_level: int, to_level: int) -> bool:
	return from_level == to_level

static func validate_no_fall_move(from_cell: Vector2i, to_cell: Vector2i, platform_lookup: Dictionary = {}, ground_level_lookup: Dictionary = {}) -> Dictionary:
	var from_level: int = get_surface_level_for_cell(from_cell, platform_lookup, ground_level_lookup)
	var to_level: int = get_surface_level_for_cell(to_cell, platform_lookup, ground_level_lookup)
	if not can_move_between_surface_levels(from_level, to_level):
		return {
			"ok": false,
			"blocked": true,
			"reason": "surface_level_mismatch",
			"message": "Movement blocked: target surface is not at the same height.",
			"from_level": from_level,
			"to_level": to_level
		}
	return {"ok": true, "blocked": false, "from_level": from_level, "to_level": to_level}

static func collect_carried_entries_for_cells(cells: Array[Vector2i], entity_entries: Array[Dictionary]) -> Array[Dictionary]:
	var cell_lookup: Dictionary = {}
	for cell in cells:
		cell_lookup["%s:%s" % [cell.x, cell.y]] = true
	var carried: Array[Dictionary] = []
	for entry in entity_entries:
		var cell: Vector2i = PlatformMechanismServiceRef.normalize_cell(entry.get("cell", entry.get("position", {})))
		if cell_lookup.has("%s:%s" % [cell.x, cell.y]):
			carried.append(entry.duplicate(true))
	return carried

static func build_elevator_motion_plan(members: Array, entity_entries: Array[Dictionary], action: String, current_level: int, max_level: int) -> Dictionary:
	var normalized_action: String = PlatformTypesRef.normalize_platform_action(action)
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var target_level: int = current_level
	if normalized_action == PlatformTypesRef.ACTION_RAISE:
		target_level = mini(current_level + 1, max_level)
	elif normalized_action == PlatformTypesRef.ACTION_LOWER:
		target_level = maxi(current_level - 1, 0)
	else:
		errors.append("Elevator motion requires raise or lower action.")
	if target_level == current_level and errors.is_empty():
		warnings.append("Platform is already at requested level boundary.")
	var member_cells: Array[Vector2i] = PlatformMechanismServiceRef.get_member_cells(members)
	var carried_entries: Array[Dictionary] = collect_carried_entries_for_cells(member_cells, entity_entries)
	return {
		"ok": errors.is_empty(),
		"action": normalized_action,
		"current_level": current_level,
		"target_level": target_level,
		"motion_state": PlatformTypesRef.MOTION_RAISING if target_level > current_level else PlatformTypesRef.MOTION_LOWERING if target_level < current_level else PlatformTypesRef.MOTION_IDLE,
		"member_cells": member_cells,
		"carried_entries": carried_entries,
		"errors": errors,
		"warnings": warnings
	}

static func preview_level_after_action(platform_data: Dictionary, action: String) -> Dictionary:
	var normalized_action: String = PlatformTypesRef.normalize_platform_action(action)
	var current_level: int = get_surface_level_for_platform(platform_data)
	var max_level: int = maxi(int(platform_data.get("max_level", 1)), 0)
	var target_level: int = current_level
	if normalized_action == PlatformTypesRef.ACTION_RAISE:
		target_level = mini(current_level + 1, max_level)
	elif normalized_action == PlatformTypesRef.ACTION_LOWER:
		target_level = maxi(current_level - 1, 0)
	return {
		"ok": not normalized_action.is_empty(),
		"action": normalized_action,
		"current_level": current_level,
		"target_level": target_level,
		"will_change": target_level != current_level,
		"message": "OK" if target_level != current_level else "Platform level will not change."
	}

static func advance_motion_progress(current_progress: float, step: float) -> Dictionary:
	var next_progress: float = clampf(current_progress + maxf(step, 0.0), 0.0, 1.0)
	return {"progress": next_progress, "complete": next_progress >= 1.0}

static func complete_elevator_motion(platform_data: Dictionary) -> Dictionary:
	var result: Dictionary = platform_data.duplicate(true)
	var target_level: int = int(result.get("target_level", result.get("platform_level", 0)))
	result["platform_level"] = target_level
	result["current_level"] = target_level
	result["motion_state"] = PlatformTypesRef.MOTION_IDLE
	result["motion_progress"] = 0.0
	return result
