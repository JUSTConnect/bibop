extends Node

# Target class: MissionRuntime
# Координатор текущей миссии. Не строит UI.

var world_state_repository: RefCounted = null
var active_actor_id: String = ""
var mission_status: String = "not_started"

func start_mission(_mission_id: String) -> Dictionary:
	mission_status = "running"
	return {"ok": true, "message": "Mission started."}

func end_mission(result: String) -> void:
	mission_status = result

func apply_actor_command(_command: Dictionary) -> Dictionary:
	return {"ok": true, "message": "Command accepted."}

func apply_object_action(_action: Dictionary) -> Dictionary:
	return {"ok": true, "message": "Action accepted."}

func end_turn() -> Dictionary:
	return {"ok": true, "message": "Turn ended."}

func get_runtime_snapshot() -> Dictionary:
	return {"mission_status": mission_status, "active_actor_id": active_actor_id}
