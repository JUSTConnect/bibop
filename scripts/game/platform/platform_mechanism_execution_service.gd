extends RefCounted
class_name PlatformMechanismExecutionService

const PlatformTypesRef = preload("res://scripts/game/platform/platform_types.gd")
const PlatformMechanismServiceRef = preload("res://scripts/game/platform/platform_mechanism_service.gd")
const PlatformMotionServiceRef = preload("res://scripts/game/platform/platform_motion_service.gd")
const PlatformRotationServiceRef = preload("res://scripts/game/platform/platform_rotation_service.gd")

static func execute_terminal_platform_mechanism_action(controller: Variant, terminal: Dictionary, action_id: String) -> Dictionary:
	var mechanism_id: String = str(terminal.get("target_platform_id", terminal.get("target_platform_mechanism_id", ""))).strip_edges()
	if mechanism_id.is_empty():
		return _result(false, "Terminal has no linked platform mechanism.", false, false, "missing_platform_mechanism")
	var mission_manager: Variant = controller.mission_manager if controller != null else null
	if mission_manager == null:
		return _result(false, "Platform mechanism control unavailable.", false, false, "mission_manager_missing")
	var world_objects: Array = Array(mission_manager.mission_world_objects) if "mission_world_objects" in mission_manager else []
	var members: Array[Dictionary] = PlatformMechanismServiceRef.get_mechanism_members(mechanism_id, world_objects)
	if members.is_empty():
		return _result(false, "Platform mechanism not found: %s" % mechanism_id, false, false, "mechanism_not_found")
	var normalized_action: String = _resolve_platform_action(action_id, members[0])
	if normalized_action.is_empty():
		return _result(false, "No platform action available.", false, false, "action_unavailable")
	var updated_members: Dictionary = _build_updated_members(members, normalized_action)
	if updated_members.is_empty():
		return _result(false, "Platform action unavailable.", false, false, "action_unavailable")
	var updated_count: int = _apply_member_updates(mission_manager, updated_members)
	if updated_count <= 0:
		return _result(false, "Platform mechanism update failed.", false, false, "update_failed")
	return _result(true, "Platform mechanism %s applied: %s" % [mechanism_id, PlatformTypesRef.action_label(normalized_action)], true, true, "ok")

static func _resolve_platform_action(action_id: String, representative: Dictionary) -> String:
	var normalized_action: String = PlatformTypesRef.normalize_platform_action(action_id)
	if not normalized_action.is_empty() and normalized_action != PlatformTypesRef.ACTION_CANCEL_PENDING:
		return normalized_action
	var actions: Array[String] = PlatformTypesRef.available_actions_for_mode(str(representative.get("platform_mode", "elevator")), int(representative.get("platform_level", representative.get("current_level", 0))), int(representative.get("max_level", 1)))
	return actions[0] if not actions.is_empty() else ""

static func _build_updated_members(members: Array[Dictionary], action: String) -> Dictionary:
	var result: Dictionary = {}
	if members.is_empty():
		return result
	var normalized_action: String = PlatformTypesRef.normalize_platform_action(action)
	var representative: Dictionary = PlatformTypesRef.normalize_platform_config(members[0])
	if normalized_action in [PlatformTypesRef.ACTION_RAISE, PlatformTypesRef.ACTION_LOWER]:
		var preview: Dictionary = PlatformMotionServiceRef.preview_level_after_action(representative, normalized_action)
		if not bool(preview.get("ok", false)) or not bool(preview.get("will_change", false)):
			return result
		var target_level: int = int(preview.get("target_level", representative.get("platform_level", 0)))
		for member in members:
			var updated: Dictionary = member.duplicate(true)
			updated["platform_level"] = target_level
			updated["current_level"] = target_level
			updated["target_level"] = target_level
			updated["motion_state"] = PlatformTypesRef.MOTION_IDLE
			updated["motion_progress"] = 0.0
			result[PlatformMechanismServiceRef.get_platform_id(updated)] = updated
		return result
	if normalized_action in [PlatformTypesRef.ACTION_ROTATE_LEFT, PlatformTypesRef.ACTION_ROTATE_RIGHT]:
		for member in members:
			var updated_rot: Dictionary = member.duplicate(true)
			updated_rot["direction"] = PlatformRotationServiceRef.rotate_direction(str(updated_rot.get("direction", updated_rot.get("facing", PlatformTypesRef.DIRECTION_NORTH))), normalized_action)
			updated_rot["facing"] = updated_rot["direction"]
			updated_rot["motion_state"] = PlatformTypesRef.MOTION_IDLE
			updated_rot["last_rotation_action"] = normalized_action
			result[PlatformMechanismServiceRef.get_platform_id(updated_rot)] = updated_rot
	return result

static func _apply_member_updates(mission_manager: Variant, updated_members: Dictionary) -> int:
	var updated_count: int = 0
	if mission_manager == null or not ("mission_world_objects" in mission_manager):
		return 0
	for index in range(mission_manager.mission_world_objects.size()):
		var object_data: Dictionary = Dictionary(mission_manager.mission_world_objects[index])
		var object_id: String = str(object_data.get("id", object_data.get("object_id", ""))).strip_edges()
		if object_id.is_empty() or not updated_members.has(object_id):
			continue
		mission_manager.mission_world_objects[index] = Dictionary(updated_members.get(object_id, {}))
		updated_count += 1
	return updated_count

static func _result(success: bool, message: String, refresh_overlay: bool, refresh_action_panel: bool, reason: String) -> Dictionary:
	return {
		"handled": true,
		"success": success,
		"message": message,
		"spent_action": false,
		"refresh_overlay": refresh_overlay,
		"refresh_threats": refresh_overlay,
		"refresh_action_panel": refresh_action_panel,
		"emit_status": true,
		"emit_facing_hint": refresh_overlay,
		"reason": reason
	}
