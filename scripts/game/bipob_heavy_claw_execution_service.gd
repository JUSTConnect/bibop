extends RefCounted
class_name BipobHeavyClawExecutionService

const MovableActionServiceRef = preload("res://scripts/game/movable/movable_action_service.gd")
const BipobRuntimeActionActorServiceRef = preload("res://scripts/game/bipob_runtime_action_actor_service.gd")

static func execute_heavy_claw_action(controller: Variant, world_object: Dictionary, target_position: Vector2i, action_id: String) -> Dictionary:
	if action_id != "push":
		return _build_result(false, false, "Movement action is unsupported.", false, false, false, false, true, false, MovableActionServiceRef.CODE_ACTION_UNSUPPORTED)
	var actor: Dictionary = BipobRuntimeActionActorServiceRef.build_runtime_action_actor(controller, world_object, target_position)
	var preview: Dictionary = MovableActionServiceRef.preview_action(actor, world_object, action_id)
	if not bool(preview.get("success", false)):
		return _build_result(true, false, str(preview.get("message", "Movement unavailable.")), false, false, false, false, true, false, str(preview.get("code", MovableActionServiceRef.CODE_NOT_MOVABLE)))
	var requirement: Dictionary = Dictionary(preview.get("movement_requirement", {}))
	var movement_mode: String = str(requirement.get("movement_mode", MovableActionServiceRef.MOVEMENT_PUSH))
	if movement_mode == MovableActionServiceRef.MOVEMENT_DRAG:
		if controller.has_method("start_heavy_claw_drag"):
			var attach_result: Dictionary = Dictionary(controller.call("start_heavy_claw_drag", world_object))
			if bool(attach_result.get("success", false)):
				return _build_result(true, true, str(attach_result.get("message", "Heavy Claw attached.")), false, true, true, true, true, true, MovableActionServiceRef.CODE_VALID)
			return _build_result(true, false, str(attach_result.get("message", "Cannot attach object.")), false, false, false, true, true, false, str(attach_result.get("code", "attach_unavailable")))
		return _build_result(true, false, "Heavy Claw drag unavailable.", false, false, false, false, true, false, "drag_unavailable")
	if controller.mission_manager == null or not controller.mission_manager.has_method("move_world_object_with_requirements"):
		return _build_result(true, false, "Object movement unavailable.", false, false, false, false, true, false, "movement_service_unavailable")
	var direction: Vector2i = controller.get_direction_vector(controller.direction)
	var destination: Vector2i = target_position + direction
	var move_result: Dictionary = Dictionary(controller.mission_manager.call("move_world_object_with_requirements", str(world_object.get("id", "")), destination, actor, action_id))
	if not bool(move_result.get("success", false)):
		return _build_result(true, false, str(move_result.get("message", "Cannot move object there.")), false, false, false, true, true, false, str(move_result.get("code", "movement_failed")))
	return _build_result(true, true, str(move_result.get("message", "Object moved.")), true, true, true, true, true, true, str(move_result.get("code", MovableActionServiceRef.CODE_VALID)), true)

static func _build_result(handled: bool, success: bool, message: String, spent_action: bool, refresh_overlay: bool, refresh_threats: bool, refresh_action_panel: bool, emit_status: bool, emit_facing_hint: bool, reason: String, pending_paid_action: bool = false) -> Dictionary:
	return {"handled": handled, "success": success, "ok": success, "code": reason, "reason_code": reason, "message": message, "spent_action": spent_action, "refresh_overlay": refresh_overlay, "refresh_threats": refresh_threats, "refresh_action_panel": refresh_action_panel, "emit_status": emit_status, "emit_facing_hint": emit_facing_hint, "reason": reason, "pending_paid_action": pending_paid_action}
