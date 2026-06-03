extends RefCounted
class_name BipobTerminalControlExecutionService


const TERMINAL_DOOR_CONTROL_ACTIONS: Array[String] = ["open_door", "close_door", "unlock_door"]


static func execute_terminal_control_action(controller: Variant, terminal: Dictionary, _target_position: Vector2i, action_id: String) -> Dictionary:
	if action_id not in TERMINAL_DOOR_CONTROL_ACTIONS:
		return _build_result(false, false, "Door control unavailable.", false, false, false, "unsupported_action")
	if not controller.can_spend_action(1, 1):
		return _build_result(true, false, "Not enough action/energy.", false, false, true, "insufficient_resources")
	var terminal_result: Dictionary = Dictionary(controller.mission_manager.execute_terminal_control_action(str(terminal.get("id", "")), str(terminal.get("target_door_id", "")), action_id))
	var success: bool = bool(terminal_result.get("success", false))
	if success:
		controller.spend_action(1, 1)
		controller._register_successful_paid_player_action(true)
	return _build_result(true, success, "Door control applied." if success else "Door control unavailable.", success, true, true, "ok" if success else "terminal_control_unavailable")


static func _build_result(handled: bool, success: bool, message: String, spent_action: bool, refresh_action_panel: bool, emit_status: bool, reason: String) -> Dictionary:
	return {
		"handled": handled,
		"success": success,
		"message": message,
		"spent_action": spent_action,
		"refresh_action_panel": refresh_action_panel,
		"emit_status": emit_status,
		"reason": reason
	}
