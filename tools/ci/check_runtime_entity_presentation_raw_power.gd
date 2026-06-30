extends SceneTree

const SnapshotService = preload("res://scripts/game/presentation/runtime_presentation_snapshot_service.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	var door := {"id":"door_a", "position":Vector2i(2, 0), "object_type":"door", "power_mode":"external", "power_network_id":"main"}
	var cable := {"id":"cable_a", "position":Vector2i(1, 0), "object_type":"power_cable", "power_network_id":"main", "connected":true}
	var generator := {"id":"generator_a", "position":Vector2i(0, 0), "object_type":"power_source_class_1", "generic_power_role":"power_source", "power_network_id":"main"}
	var context := {"mode":"task_test", "objects":[door, cable, generator], "bindings":[]}
	var snapshot := SnapshotService.build(null, door, Vector2i(2, 0), {"actions":[]}, context)
	var debug_data := Dictionary(snapshot.get("debug", {}))
	var result := Dictionary(debug_data.get("power_result", {}))
	if str(result.get("power_state", "")) == "powered":
		print("runtime entity raw power: OK")
		quit(0)
		return
	quit(1)
