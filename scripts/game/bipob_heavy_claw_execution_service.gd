extends RefCounted
class_name BipobHeavyClawExecutionService


const WorldObjectCatalogRef = preload("res://scripts/world/world_object_catalog.gd")
const InteractionActionCostServiceRef = preload("res://scripts/game/interaction/interaction_action_cost_service.gd")


static func execute_heavy_claw_action(controller: Variant, world_object: Dictionary, target_position: Vector2i, action_id: String) -> Dictionary:
	if action_id not in ["push", "pull"] or not WorldObjectCatalogRef.can_world_object_be_moved_by_heavy_claw(world_object):
		return _build_result(false, false, "Cannot move object there.", false, false, false, false, true, false, "unsupported_action")
	if not controller.has_heavy_claw_capability():
		return _build_result(true, false, "Heavy Claw required.", false, false, false, false, true, false, "heavy_claw_required")
	if action_id != "push":
		return _build_result(true, false, "Heavy Claw move is unavailable for this direction.", false, false, false, false, true, false, "move_direction_unavailable")
	var expected_target: Vector2i = controller.grid_position + controller.get_direction_vector(controller.direction)
	if target_position != expected_target:
		return _build_result(true, false, "Heavy Claw target must be directly in front.", false, false, false, false, true, false, "target_not_in_front")
	if controller.has_method("start_heavy_claw_drag"):
		var attach_result: Dictionary = Dictionary(controller.call("start_heavy_claw_drag", world_object))
		if bool(attach_result.get("success", false)):
			return _build_result(true, true, str(attach_result.get("message", "Heavy Claw attached.")), false, true, true, true, true, true, "ok")
		return _build_result(true, false, str(attach_result.get("message", "Cannot attach object.")), false, false, false, true, true, false, "attach_unavailable")
	return _build_result(true, false, "Heavy Claw drag unavailable.", false, false, false, false, true, false, "drag_unavailable")


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
		"reason": reason,
		"pending_paid_action": false
	}
