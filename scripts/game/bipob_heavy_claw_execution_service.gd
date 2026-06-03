extends RefCounted
class_name BipobHeavyClawExecutionService


const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")


static func execute_heavy_claw_action(controller: Variant, world_object: Dictionary, target_position: Vector2i, action_id: String) -> Dictionary:
	if action_id not in ["push", "pull"] or not WorldObjectCatalogRef.can_world_object_be_moved_by_heavy_claw(world_object):
		return _build_result(false, false, "Cannot move object there.", false, false, false, false, true, false, "unsupported_action")
	if not controller.has_heavy_claw_capability():
		return _build_result(true, false, "Heavy Claw required.", false, false, false, false, true, false, "heavy_claw_required")
	var target_destination: Vector2i = controller.get_heavy_claw_move_destination(target_position, controller.grid_position, action_id)
	if target_destination.x < 0 or target_destination.y < 0:
		return _build_result(true, false, "Heavy Claw move is unavailable for this direction.", false, false, false, false, true, false, "move_direction_unavailable")
	var move_result: Dictionary = Dictionary(controller.mission_manager.move_world_object_by_heavy_claw(str(world_object.get("id", "")), target_destination))
	var success: bool = bool(move_result.get("success", false))
	if success:
		controller.spend_action(1, 1)
		controller._register_successful_paid_player_action(true)
		return _build_result(true, true, str(move_result.get("message", "Moved object.")), true, true, true, true, true, true, "ok")
	return _build_result(true, false, str(move_result.get("message", "Cannot move object there.")), false, false, false, false, true, false, "move_unavailable")


static func _build_result(handled: bool, success: bool, message: String, spent_action: bool, refresh_overlay: bool, refresh_threats: bool, refresh_action_panel: bool, emit_status: bool, emit_facing_hint: bool, reason: String) -> Dictionary:
	return {
		"handled": handled,
		"success": success,
		"message": message,
		"spent_action": spent_action,
		"refresh_overlay": refresh_overlay,
		"refresh_threats": refresh_threats,
		"refresh_action_panel": refresh_action_panel,
		"emit_status": emit_status,
		"emit_facing_hint": emit_facing_hint,
		"reason": reason
	}
